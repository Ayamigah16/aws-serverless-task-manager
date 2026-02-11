import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface UIStore {
  sidebarCollapsed: boolean
  viewMode: 'list' | 'board' | 'calendar' | 'timeline'
  toggleSidebar: () => void
  setViewMode: (mode: 'list' | 'board' | 'calendar' | 'timeline') => void
}

export const useUIStore = create<UIStore>()(
  persist(
    (set) => ({
      sidebarCollapsed: false,
      viewMode: 'list',
      toggleSidebar: () => set((state) => ({ sidebarCollapsed: !state.sidebarCollapsed })),
      setViewMode: (mode) => set({ viewMode: mode }),
    }),
    {
      name: 'ui-storage',
    }
  )
)
