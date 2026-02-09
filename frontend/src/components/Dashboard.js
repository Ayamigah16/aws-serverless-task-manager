import React, { useState, useEffect } from 'react';
import { taskService } from '../services/taskService';

const Dashboard = () => {
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadTasks();
  }, []);

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

  if (loading) return <div className="container"><div className="loading"><div className="spinner"></div>Loading...</div></div>;
  if (error) return <div className="container"><div className="error">{error}</div></div>;

  const openTasks = tasks.filter(t => t.Status === 'OPEN').length;
  const inProgressTasks = tasks.filter(t => t.Status === 'IN_PROGRESS').length;
  const completedTasks = tasks.filter(t => t.Status === 'COMPLETED').length;

  return (
    <div className="container">
      <h2 style={{ color: '#1E293B', marginBottom: '24px', fontSize: '28px', fontWeight: 700 }}>Dashboard</h2>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px', marginBottom: '40px' }}>
        <div className="card metric-card-open">
          <div className="metric-label">Open Tasks</div>
          <div className="metric-value">{openTasks}</div>
        </div>
        <div className="card metric-card-progress">
          <div className="metric-label">In Progress</div>
          <div className="metric-value">{inProgressTasks}</div>
        </div>
        <div className="card metric-card-completed">
          <div className="metric-label">Completed</div>
          <div className="metric-value">{completedTasks}</div>
        </div>
        <div className="card metric-card-total">
          <div className="metric-label">Total Tasks</div>
          <div className="metric-value">{tasks.length}</div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
