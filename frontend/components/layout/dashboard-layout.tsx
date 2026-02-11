'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuthStore } from '@/lib/stores/auth-store'
import { useUIStore } from '@/lib/stores/ui-store'
import { Sidebar } from './sidebar'
import { Header } from './header'
import { cn } from '@/lib/utils'

export function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter()
  const { isAuthenticated, isLoading, fetchUser } = useAuthStore()
  const { sidebarCollapsed } = useUIStore()

  useEffect(() => {
    fetchUser()
  }, [fetchUser])

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push('/login')
    }
  }, [isAuthenticated, isLoading, router])

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    )
  }

  if (!isAuthenticated) {
    return null
  }

  return (
    <div className="min-h-screen bg-background">
      <Sidebar />
      <Header />
      <main
        className={cn(
          'pt-16 transition-all duration-300',
          sidebarCollapsed ? 'ml-16' : 'ml-64'
        )}
        role="main"
        id="main-content"
      >
        <div className="container mx-auto p-6">{children}</div>
      </main>
    </div>
  )
}
