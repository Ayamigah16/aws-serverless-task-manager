import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const Header = () => {
  const { user, signOut } = useAuth();

  return (
    <div className="header">
      <div className="container" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: 0, paddingBottom: 0 }}>
        <nav style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
          <Link to="/" className="btn btn-ghost">Dashboard</Link>
          <Link to="/tasks" className="btn btn-ghost">Tasks</Link>
        </nav>
        <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
          {user?.isAdmin && (
            <Link to="/tasks/new" className="btn btn-success">+ Create Task</Link>
          )}
          <span style={{ color: '#64748B', fontSize: '14px' }}>{user?.email}</span>
          <button onClick={signOut} className="btn btn-ghost" style={{ color: '#64748B', border: '1px solid #E2E8F0' }}>Sign Out</button>
        </div>
      </div>
    </div>
  );
};

export default Header;
