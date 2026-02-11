'use client'

import { useState } from 'react'
import { DashboardLayout } from '@/components/layout/dashboard-layout'
import { TaskCard } from '@/components/tasks/task-card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Plus, LayoutList, LayoutGrid, Calendar as CalendarIcon } from 'lucide-react'
import { useTasks, useCreateTask } from '@/lib/hooks/use-tasks'
import { useUIStore } from '@/lib/stores/ui-store'
import { toast } from 'sonner'
import type { Priority } from '@/lib/types'

export default function TasksPage() {
  const { data, isLoading } = useTasks()
  const { viewMode, setViewMode } = useUIStore()
  const createTask = useCreateTask()
  const [showCreateDialog, setShowCreateDialog] = useState(false)
  const [newTask, setNewTask] = useState({
    title: '',
    description: '',
    priority: 'MEDIUM' as Priority,
  })

  const handleCreateTask = async () => {
    if (!newTask.title.trim()) {
      toast.error('Task title is required')
      return
    }

    try {
      console.log('Creating task with:', newTask)
      const result = await createTask.mutateAsync(newTask)
      console.log('Task created:', result)
      toast.success('Task created successfully')
      setShowCreateDialog(false)
      setNewTask({ title: '', description: '', priority: 'MEDIUM' })
    } catch (error: any) {
      console.error('Create task error:', error)
      console.error('Error details:', JSON.stringify(error, null, 2))
      const errorMessage = error?.errors?.[0]?.message || error.message || 'Failed to create task'
      toast.error(errorMessage)
    }
  }

  if (isLoading) {
    return (
      <DashboardLayout>
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
        </div>
      </DashboardLayout>
    )
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">Tasks</h1>
            <p className="text-muted-foreground">
              {data?.total || 0} tasks found
            </p>
          </div>

          <div className="flex items-center gap-2">
            <div className="flex items-center border rounded-lg">
              <Button
                variant={viewMode === 'list' ? 'secondary' : 'ghost'}
                size="sm"
                onClick={() => setViewMode('list')}
                aria-label="List view"
              >
                <LayoutList className="h-4 w-4" />
              </Button>
              <Button
                variant={viewMode === 'board' ? 'secondary' : 'ghost'}
                size="sm"
                onClick={() => setViewMode('board')}
                aria-label="Board view"
              >
                <LayoutGrid className="h-4 w-4" />
              </Button>
              <Button
                variant={viewMode === 'calendar' ? 'secondary' : 'ghost'}
                size="sm"
                onClick={() => setViewMode('calendar')}
                aria-label="Calendar view"
              >
                <CalendarIcon className="h-4 w-4" />
              </Button>
            </div>

            <Button onClick={() => setShowCreateDialog(true)}>
              <Plus className="h-4 w-4 mr-2" />
              New Task
            </Button>
          </div>
        </div>

        {showCreateDialog && (
          <Card>
            <CardHeader>
              <CardTitle>Create New Task</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-sm font-medium">Title</label>
                <Input
                  placeholder="Task title"
                  value={newTask.title}
                  onChange={(e) => setNewTask({ ...newTask, title: e.target.value })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Description</label>
                <Input
                  placeholder="Task description (optional)"
                  value={newTask.description}
                  onChange={(e) => setNewTask({ ...newTask, description: e.target.value })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Priority</label>
                <select
                  value={newTask.priority}
                  onChange={(e) => setNewTask({ ...newTask, priority: e.target.value as Priority })}
                  className="w-full px-3 py-2 border rounded-md"
                >
                  <option value="LOW">Low</option>
                  <option value="MEDIUM">Medium</option>
                  <option value="HIGH">High</option>
                  <option value="CRITICAL">Critical</option>
                </select>
              </div>
              <div className="flex gap-2">
                <Button onClick={handleCreateTask} disabled={createTask.isPending}>
                  {createTask.isPending ? 'Creating...' : 'Create Task'}
                </Button>
                <Button variant="outline" onClick={() => setShowCreateDialog(false)}>
                  Cancel
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {data?.items?.map((task: any) => (
            <TaskCard key={task.taskId} task={task} />
          ))}
        </div>

        {(!data?.items || data.items.length === 0) && (
          <div className="text-center py-12">
            <p className="text-muted-foreground">No tasks found. Create one to get started!</p>
          </div>
        )}
      </div>
    </DashboardLayout>
  )
}
