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
  const [selectedUser, setSelectedUser] = useState('');

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

  const handleAssignTask = (taskId) => {
    setAssigningTask(taskId);
    setSelectedUser('');
  };

  const confirmAssignment = async (taskId) => {
    if (!selectedUser) return;
    try {
      await taskService.assignTask(taskId, selectedUser);
      setAssigningTask(null);
      setSelectedUser('');
      loadTasks();
    } catch (err) {
      alert('Error: ' + err.message);
    }
  };

  const cancelAssignment = () => {
    setAssigningTask(null);
    setSelectedUser('');
  };

  if (loading) return <div className="container"><div className="loading"><div className="spinner"></div>Loading...</div></div>;
  if (error) return <div className="container"><div className="error">{error}</div></div>;

  return (
    <div className="container">
      <h2>Tasks</h2>
      <div className="task-list">
        {tasks.length === 0 ? (
          <p>No tasks found.</p>
        ) : (
          tasks.map(task => (
            <div key={task.TaskId} className="task-item">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '10px' }}>
                <div style={{ flex: 1 }}>
                  <h3 style={{ marginBottom: '8px' }}>{task.Title}</h3>
                  <p style={{ color: '#666', marginBottom: '12px' }}>{task.Description}</p>
                  <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                    <span className={`badge badge-${task.Status?.toLowerCase() || 'open'}`}>{task.Status?.replace('_', ' ') || 'Open'}</span>
                    <span className={`badge badge-priority-${task.Priority?.toLowerCase() || 'medium'}`}>{task.Priority || 'Medium'}</span>
                  </div>
                </div>
              </div>
              
              {task.Status !== 'CLOSED' && (
                <div style={{ marginTop: '15px', paddingTop: '15px', borderTop: '1px solid #eee' }}>
                  {assigningTask === task.TaskId ? (
                    <div style={{ display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap' }}>
                      <select 
                        value={selectedUser}
                        onChange={(e) => setSelectedUser(e.target.value)}
                        style={{ flex: '1', minWidth: '200px', padding: '8px', border: '1px solid #ddd', borderRadius: '4px' }}
                      >
                        <option value="">Select user...</option>
                        {users.map(u => (
                          <option key={u.userId} value={u.userId}>
                            {u.email} {u.isAdmin ? '(Admin)' : ''}
                          </option>
                        ))}
                      </select>
                      <button 
                        onClick={() => confirmAssignment(task.TaskId)}
                        disabled={!selectedUser}
                        className="btn btn-success"
                        style={{ padding: '8px 16px' }}
                      >
                        Confirm
                      </button>
                      <button 
                        onClick={cancelAssignment}
                        className="btn btn-secondary"
                        style={{ padding: '8px 16px' }}
                      >
                        Cancel
                      </button>
                    </div>
                  ) : (
                    <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                      <select 
                        value={task.Status} 
                        onChange={(e) => handleStatusUpdate(task.TaskId, e.target.value)}
                        className="select-status"
                      >
                        <option value="OPEN">Open</option>
                        <option value="IN_PROGRESS">In Progress</option>
                        <option value="COMPLETED">Completed</option>
                      </select>
                      {user?.isAdmin && (
                        <>
                          <button 
                            onClick={() => handleAssignTask(task.TaskId)}
                            className="btn btn-primary"
                          >
                            Assign User
                          </button>
                          <button 
                            onClick={() => handleCloseTask(task.TaskId)}
                            className="btn btn-danger"
                          >
                            Close
                          </button>
                        </>
                      )}
                    </div>
                  )}
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default TaskList;
