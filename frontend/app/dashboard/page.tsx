'use client'

import { DashboardLayout } from '@/components/layout/dashboard-layout'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { CheckSquare, Clock, AlertCircle, TrendingUp } from 'lucide-react'
import { useTasks } from '@/lib/hooks/use-tasks'
import { TaskCard } from '@/components/tasks/task-card'

export default function DashboardPage() {
  const { data: allTasks } = useTasks()
  const { data: inProgressTasks } = useTasks('IN_PROGRESS')
  const { data: completedTasks } = useTasks('COMPLETED')

  const totalTasks = allTasks?.total || 0
  const inProgress = inProgressTasks?.total || 0
  const completed = completedTasks?.total || 0
  const recentTasks = allTasks?.items?.slice(0, 5) || []

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-muted-foreground">Welcome back! Here's your task overview.</p>
        </div>

        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Total Tasks</CardTitle>
              <CheckSquare className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{totalTasks}</div>
              <p className="text-xs text-muted-foreground">All tasks</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">In Progress</CardTitle>
              <Clock className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{inProgress}</div>
              <p className="text-xs text-muted-foreground">Active tasks</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Open</CardTitle>
              <AlertCircle className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{totalTasks - inProgress - completed}</div>
              <p className="text-xs text-muted-foreground">Not started</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">Completed</CardTitle>
              <TrendingUp className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{completed}</div>
              <p className="text-xs text-muted-foreground">Done</p>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Recent Tasks</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              {recentTasks.map((task: any) => (
                <TaskCard key={task.taskId} task={task} />
              ))}
            </div>
            {recentTasks.length === 0 && (
              <p className="text-sm text-muted-foreground text-center py-8">No tasks yet</p>
            )}
          </CardContent>
        </Card>
      </div>
    </DashboardLayout>
  )
}
