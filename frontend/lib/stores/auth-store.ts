import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { fetchAuthSession, getCurrentUser, signOut } from 'aws-amplify/auth'

interface User {
  userId: string
  email: string
  groups: string[]
  isAdmin: boolean
}

interface AuthStore {
  user: User | null
  isLoading: boolean
  isAuthenticated: boolean
  fetchUser: () => Promise<void>
  logout: () => Promise<void>
}

export const useAuthStore = create<AuthStore>()(persist(
  (set) => ({
    user: null,
    isLoading: true,
    isAuthenticated: false,

    fetchUser: async () => {
      try {
        const currentUser = await getCurrentUser()
        const session = await fetchAuthSession()
        const groups = session.tokens?.accessToken.payload['cognito:groups'] as string[] || []

        set({
          user: {
            userId: currentUser.userId,
            email: currentUser.signInDetails?.loginId || '',
            groups,
            isAdmin: groups.includes('Admins'),
          },
          isAuthenticated: true,
          isLoading: false,
        })
      } catch {
        set({ user: null, isAuthenticated: false, isLoading: false })
      }
    },

    logout: async () => {
      await signOut()
      set({ user: null, isAuthenticated: false })
      window.location.href = '/login'
    },
  }),
  {
    name: 'auth-storage',
    partialize: (state) => ({ user: state.user, isAuthenticated: state.isAuthenticated }),
  }
))
