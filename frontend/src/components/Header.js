import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const Header = () => {
  const { user, signOut } = useAuth();

  return (
    <div className="header">
      <div className="container" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1>Task Manager</h1>
          <p>{user?.email} {user?.isAdmin && '(Admin)'}</p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          <Link to="/" className="btn btn-primary">Dashboard</Link>
          <Link to="/tasks" className="btn btn-primary">Tasks</Link>
          {user?.isAdmin && (
            <Link to="/tasks/new" className="btn btn-success">Create Task</Link>
          )}
          <button onClick={signOut} className="btn btn-danger">Sign Out</button>
        </div>
      </div>
    </div>
  );
};

export default Header;
