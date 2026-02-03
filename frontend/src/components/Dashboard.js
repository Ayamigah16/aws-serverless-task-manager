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

  if (loading) return <div className="container"><div className="loading">Loading...</div></div>;
  if (error) return <div className="container"><div className="error">{error}</div></div>;

  const openTasks = tasks.filter(t => t.Status === 'OPEN').length;
  const inProgressTasks = tasks.filter(t => t.Status === 'IN_PROGRESS').length;
  const completedTasks = tasks.filter(t => t.Status === 'COMPLETED').length;

  return (
    <div className="container">
      <h2>Dashboard</h2>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px', marginTop: '20px' }}>
        <div className="card">
          <h3>Open Tasks</h3>
          <p style={{ fontSize: '32px', fontWeight: 'bold', color: '#007bff' }}>{openTasks}</p>
        </div>
        <div className="card">
          <h3>In Progress</h3>
          <p style={{ fontSize: '32px', fontWeight: 'bold', color: '#ffc107' }}>{inProgressTasks}</p>
        </div>
        <div className="card">
          <h3>Completed</h3>
          <p style={{ fontSize: '32px', fontWeight: 'bold', color: '#28a745' }}>{completedTasks}</p>
        </div>
        <div className="card">
          <h3>Total Tasks</h3>
          <p style={{ fontSize: '32px', fontWeight: 'bold' }}>{tasks.length}</p>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
