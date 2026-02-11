'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import { useUIStore } from '@/lib/stores/ui-store'
import { 
  LayoutDashboard, 
  CheckSquare, 
  Calendar, 
  FolderKanban, 
  Users, 
  BarChart3,
  Settings,
  ChevronLeft,
  ChevronRight
} from 'lucide-react'
import { Button } from '@/components/ui/button'

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
  { name: 'Tasks', href: '/tasks', icon: CheckSquare },
  { name: 'Sprints', href: '/sprints', icon: Calendar },
  { name: 'Projects', href: '/projects', icon: FolderKanban },
  { name: 'Team', href: '/team', icon: Users },
  { name: 'Analytics', href: '/analytics', icon: BarChart3 },
  { name: 'Settings', href: '/settings', icon: Settings },
]

export function Sidebar() {
  const pathname = usePathname()
  const { sidebarCollapsed, toggleSidebar } = useUIStore()

  return (
    <aside
      className={cn(
        'fixed left-0 top-0 z-40 h-screen border-r bg-card transition-all duration-300',
        sidebarCollapsed ? 'w-16' : 'w-64'
      )}
      aria-label="Main navigation"
    >
      <div className="flex h-16 items-center justify-between px-4 border-b">
        {!sidebarCollapsed && (
          <Link href="/dashboard" className="flex items-center space-x-2" aria-label="TaskFlow home">
            <CheckSquare className="h-6 w-6 text-primary" aria-hidden="true" />
            <span className="font-bold text-lg">TaskFlow</span>
          </Link>
        )}
        <Button
          variant="ghost"
          size="icon"
          onClick={toggleSidebar}
          className={cn('ml-auto', sidebarCollapsed && 'mx-auto')}
          aria-label={sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          aria-expanded={!sidebarCollapsed}
        >
          {sidebarCollapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
        </Button>
      </div>

      <nav className="space-y-1 p-2" aria-label="Main menu">
        {navigation.map((item) => {
          const isActive = pathname === item.href
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                isActive
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
              )}
              aria-label={item.name}
              aria-current={isActive ? 'page' : undefined}
            >
              <item.icon className="h-5 w-5 flex-shrink-0" aria-hidden="true" />
              {!sidebarCollapsed && <span>{item.name}</span>}
            </Link>
          )
        })}
      </nav>
    </aside>
  )
}
