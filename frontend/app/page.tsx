'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuthStore } from '@/lib/stores/auth-store'

export default function HomePage() {
  const router = useRouter()
  const { isAuthenticated, isLoading, fetchUser } = useAuthStore()

  useEffect(() => {
    fetchUser()
  }, [fetchUser])

  useEffect(() => {
    if (!isLoading) {
      if (isAuthenticated) {
        router.push('/dashboard')
      } else {
        router.push('/login')
      }
    }
  }, [isAuthenticated, isLoading, router])

  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
    </div>
  )
}
