'use client'

import { useState } from 'react'
import { DashboardLayout } from '@/components/layout/dashboard-layout'
import { useTask, useUpdateTask, useAssignTask, useAddComment, useTaskComments } from '@/lib/hooks/use-tasks'
import { useUsers } from '@/lib/hooks/use-users'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { ArrowLeft, UserPlus, MessageSquare } from 'lucide-react'
import { useRouter } from 'next/navigation'
import { toast } from 'sonner'
import type { TaskStatus } from '@/lib/types'

export default function TaskDetailPage({ params }: { params: { taskId: string } }) {
  const router = useRouter()
  const { data: task, isLoading } = useTask(params.taskId)
  const { data: comments = [] } = useTaskComments(params.taskId)
  const { data: users } = useUsers()
  const updateTask = useUpdateTask()
  const assignTask = useAssignTask()
  const addComment = useAddComment()
  const [selectedUserId, setSelectedUserId] = useState('')
  const [comment, setComment] = useState('')

  const handleStatusChange = async (status: TaskStatus) => {
    try {
      await updateTask.mutateAsync({ taskId: params.taskId, status })
      toast.success('Status updated')
    } catch (error: any) {
      toast.error(error?.errors?.[0]?.message || 'Failed to update status')
    }
  }

  const handleAssign = async () => {
    if (!selectedUserId) return
    try {
      await assignTask.mutateAsync({ taskId: params.taskId, userId: selectedUserId })
      toast.success('User assigned')
      setSelectedUserId('')
    } catch (error: any) {
      toast.error(error?.errors?.[0]?.message || 'Failed to assign user')
    }
  }

  const handleAddComment = async () => {
    if (!comment.trim()) return
    try {
      await addComment.mutateAsync({ taskId: params.taskId, content: comment })
      toast.success('Comment added')
      setComment('')
    } catch (error: any) {
      toast.error(error?.errors?.[0]?.message || 'Failed to add comment')
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

  if (!task) {
    return (
      <DashboardLayout>
        <div className="text-center py-12">
          <h2 className="text-2xl font-bold mb-4">Task not found</h2>
          <Button onClick={() => router.push('/tasks')}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Tasks
          </Button>
        </div>
      </DashboardLayout>
    )
  }

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" onClick={() => router.back()} aria-label="Go back">
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <h1 className="text-3xl font-bold">{task.title}</h1>
        </div>

        <div className="grid gap-6 lg:grid-cols-3">
          <div className="lg:col-span-2 space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Task Details</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <label className="text-sm font-medium text-muted-foreground">Status</label>
                  <Select value={task.status} onValueChange={handleStatusChange}>
                    <SelectTrigger className="w-48 mt-1">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="OPEN">Open</SelectItem>
                      <SelectItem value="IN_PROGRESS">In Progress</SelectItem>
                      <SelectItem value="COMPLETED">Completed</SelectItem>
                      <SelectItem value="CLOSED">Closed</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <label className="text-sm font-medium text-muted-foreground">Priority</label>
                  <div className="mt-1">
                    <Badge>{task.priority}</Badge>
                  </div>
                </div>

                {task.description && (
                  <div>
                    <label className="text-sm font-medium text-muted-foreground">Description</label>
                    <p className="mt-1 text-sm">{task.description}</p>
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <MessageSquare className="h-5 w-5" />
                  Comments
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Textarea
                    placeholder="Add a comment..."
                    value={comment}
                    onChange={(e) => setComment(e.target.value)}
                    rows={3}
                  />
                  <Button onClick={handleAddComment} disabled={!comment.trim() || addComment.isPending}>
                    {addComment.isPending ? 'Adding...' : 'Add Comment'}
                  </Button>
                </div>
                <div className="space-y-4">
                  {comments.length > 0 ? (
                    comments.map((c: any) => (
                      <div key={c.commentId} className="border-l-2 pl-4 py-2">
                        <p className="text-sm">{c.content}</p>
                        <p className="text-xs text-muted-foreground mt-1">
                          {new Date(c.createdAt).toLocaleString()}
                        </p>
                      </div>
                    ))
                  ) : (
                    <div className="text-sm text-muted-foreground">No comments yet</div>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>

          <div>
            <Card>
              <CardHeader>
                <CardTitle>Assign User</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <Select value={selectedUserId} onValueChange={setSelectedUserId}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select user" />
                  </SelectTrigger>
                  <SelectContent>
                    {users?.map((user: any) => (
                      <SelectItem key={user.userId} value={user.userId}>
                        {user.email}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <Button onClick={handleAssign} disabled={!selectedUserId || assignTask.isPending} className="w-full">
                  <UserPlus className="h-4 w-4 mr-2" />
                  Assign
                </Button>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </DashboardLayout>
  )
}
