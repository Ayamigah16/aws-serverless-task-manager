'use client'

import { Bell, Search, Moon, Sun, LogOut } from 'lucide-react'
import { useTheme } from 'next-themes'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useAuthStore } from '@/lib/stores/auth-store'
import { useUIStore } from '@/lib/stores/ui-store'
import { cn } from '@/lib/utils'

export function Header() {
  const { theme, setTheme } = useTheme()
  const { user, logout } = useAuthStore()
  const { sidebarCollapsed } = useUIStore()

  return (
    <header
      className={cn(
        'fixed top-0 right-0 z-30 h-16 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 transition-all duration-300',
        sidebarCollapsed ? 'left-16' : 'left-64'
      )}
      role="banner"
    >
      <div className="flex h-full items-center justify-between px-6">
        <div className="flex items-center flex-1 max-w-xl">
          <div className="relative w-full">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" aria-hidden="true" />
            <Input
              placeholder="Search tasks... (Cmd+K)"
              className="pl-10 w-full"
              aria-label="Search tasks"
            />
          </div>
        </div>

        <div className="flex items-center gap-2">
          <Button variant="ghost" size="icon" aria-label="Notifications">
            <Bell className="h-5 w-5" />
          </Button>

          <Button
            variant="ghost"
            size="icon"
            onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
            aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
          >
            <Sun className="h-5 w-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
            <Moon className="absolute h-5 w-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
          </Button>

          <div className="flex items-center gap-2 ml-2 pl-2 border-l">
            <div className="flex items-center gap-2">
              <div className="h-8 w-8 rounded-full bg-primary flex items-center justify-center text-primary-foreground text-sm font-medium" aria-label={`User: ${user?.email}`}>
                {user?.email?.[0].toUpperCase()}
              </div>
              <div className="hidden md:block text-sm">
                <div className="font-medium">{user?.email}</div>
                <div className="text-xs text-muted-foreground">
                  {user?.isAdmin ? 'Admin' : 'Member'}
                </div>
              </div>
            </div>
            <Button variant="ghost" size="icon" onClick={logout} title="Logout" aria-label="Logout">
              <LogOut className="h-5 w-5" />
            </Button>
          </div>
        </div>
      </div>
    </header>
  )
}
