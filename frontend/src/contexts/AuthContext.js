import React, { createContext, useContext, useState, useEffect } from 'react';
import { Auth } from 'aws-amplify';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkUser();
  }, []);

  const checkUser = async () => {
    try {
      const currentUser = await Auth.currentAuthenticatedUser();
      const groups = currentUser.signInUserSession.accessToken.payload['cognito:groups'] || [];
      setUser({
        ...currentUser.attributes,
        groups,
        isAdmin: groups.includes('Admins')
      });
    } catch (error) {
      setUser(null);
    } finally {
      setLoading(false);
    }
  };

  const signOut = async () => {
    try {
      await Auth.signOut({ global: true });
      setUser(null);
      window.location.href = '/login';
    } catch (error) {
      console.error('Error signing out:', error);
      window.location.href = '/login';
    }
  };

  return (
    <AuthContext.Provider value={{ user, loading, checkUser, signOut }}>
      {children}
    </AuthContext.Provider>
  );
};
