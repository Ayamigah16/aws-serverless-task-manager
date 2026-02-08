import React, { useState, useEffect } from 'react';
import { taskService } from '../services/taskService';
import { useAuth } from '../contexts/AuthContext';

const TaskList = () => {
  const { user } = useAuth();
  const [tasks, setTasks] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [assigningTask, setAssigningTask] = useState(null);

  useEffect(() => {
    loadTasks();
    if (user?.isAdmin) {
      loadUsers();
    }
  }, [user]);

  const loadTasks = async () => {
    try {
      setLoading(true);
      const response = await taskService.getTasks();
      setTasks(response.tasks || []);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const loadUsers = async () => {
    try {
      const response = await taskService.getUsers();
      setUsers(response.users || []);
    } catch (err) {
      console.error('Error loading users:', err);
    }
  };

  const handleStatusUpdate = async (taskId, newStatus) => {
    try {
      await taskService.updateTaskStatus(taskId, newStatus);
      loadTasks();
    } catch (err) {
      alert('Error updating status: ' + err.message);
    }
  };

  const handleCloseTask = async (taskId) => {
    if (!window.confirm('Are you sure you want to close this task?')) return;
    try {
      await taskService.closeTask(taskId);
      loadTasks();
    } catch (err) {
      alert('Error closing task: ' + err.message);
    }
  };

  const handleAssignTask = async (taskId) => {
    setAssigningTask(taskId);
  };

  const confirmAssignment = async (taskId, userId) => {
    if (!userId) {
      setAssigningTask(null);
      return;
    }
    try {
      await taskService.assignTask(taskId, userId);
      alert('Task assigned successfully!');
      setAssigningTask(null);
      loadTasks();
    } catch (err) {
      alert('Error assigning task: ' + err.message);
    }
  };

  if (loading) return <div className="container"><div className="loading">Loading...</div></div>;
  if (error) return <div className="container"><div className="error">{error}</div></div>;

  return (
    <div className="container">
      <h2>Tasks</h2>
      <div className="task-list">
        {tasks.length === 0 ? (
          <p>No tasks found.</p>
        ) : (
          tasks.map(task => (
            <div key={task.TaskId} className={`task-item ${task.Priority?.toLowerCase()}`}>
              <h3>{task.Title}</h3>
              <p>{task.Description}</p>
              <div style={{ marginTop: '10px', display: 'flex', gap: '10px', alignItems: 'center' }}>
                <span style={{ padding: '4px 8px', background: '#f0f0f0', borderRadius: '4px', fontSize: '12px' }}>
                  {task.Status}
                </span>
                <span style={{ padding: '4px 8px', background: '#f0f0f0', borderRadius: '4px', fontSize: '12px' }}>
                  {task.Priority}
                </span>
                {task.Status !== 'CLOSED' && (
                  <>
                    <select 
                      value={task.Status} 
                      onChange={(e) => handleStatusUpdate(task.TaskId, e.target.value)}
                      style={{ padding: '4px 8px', fontSize: '12px' }}
                    >
                      <option value="OPEN">Open</option>
                      <option value="IN_PROGRESS">In Progress</option>
                      <option value="COMPLETED">Completed</option>
                    </select>
                    {user?.isAdmin && (
                      <>
                        {assigningTask === task.TaskId ? (
                          <>
                            <select 
                              onChange={(e) => confirmAssignment(task.TaskId, e.target.value)}
                              style={{ padding: '4px 8px', fontSize: '12px' }}
                              defaultValue=""
                            >
                              <option value="">Select user...</option>
                              {users.map(u => (
                                <option key={u.userId} value={u.userId}>
                                  {u.email} {u.isAdmin ? '(Admin)' : ''}
                                </option>
                              ))}
                            </select>
                            <button 
                              onClick={() => setAssigningTask(null)}
                              className="btn"
                              style={{ padding: '4px 12px', fontSize: '12px' }}
                            >
                              Cancel
                            </button>
                          </>
                        ) : (
                          <button 
                            onClick={() => handleAssignTask(task.TaskId)}
                            className="btn btn-primary"
                            style={{ padding: '4px 12px', fontSize: '12px' }}
                          >
                            Assign
                          </button>
                        )}
                        <button 
                          onClick={() => handleCloseTask(task.TaskId)}
                          className="btn btn-danger"
                          style={{ padding: '4px 12px', fontSize: '12px' }}
                        >
                          Close Task
                        </button>
                      </>
                    )}
                  </>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default TaskList;
