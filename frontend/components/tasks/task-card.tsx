'use client'

import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Calendar, User, GitBranch } from 'lucide-react'
import Link from 'next/link'

interface Task {
  taskId: string
  title: string
  status: string
  priority: string
  assignees?: { email: string }[]
  dueDate?: string
  estimatedPoints?: number
  gitBranch?: string
}

interface TaskCardProps {
  task: Task
}

const priorityVariant = {
  LOW: 'low',
  MEDIUM: 'medium',
  HIGH: 'high',
  CRITICAL: 'critical',
} as const

const statusColors = {
  OPEN: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-100',
  IN_PROGRESS: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-100',
  IN_REVIEW: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-100',
  COMPLETED: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-100',
  BLOCKED: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-100',
}

export function TaskCard({ task }: TaskCardProps) {
  return (
    <Link href={`/tasks/${task.taskId}`} aria-label={`View task: ${task.title}`}>
      <Card className="hover:shadow-md transition-shadow cursor-pointer" role="article">
        <CardHeader className="pb-3">
          <div className="flex items-start justify-between gap-2">
            <h3 className="font-semibold text-base line-clamp-2">{task.title}</h3>
            <Badge variant={priorityVariant[task.priority as keyof typeof priorityVariant]} aria-label={`Priority: ${task.priority}`}>
              {task.priority}
            </Badge>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex items-center gap-2">
            <Badge className={statusColors[task.status as keyof typeof statusColors]} aria-label={`Status: ${task.status}`}>
              {task.status.replace('_', ' ')}
            </Badge>
            {task.estimatedPoints && (
              <span className="text-xs text-muted-foreground" aria-label={`Estimated points: ${task.estimatedPoints}`}>{task.estimatedPoints} pts</span>
            )}
          </div>

          <div className="flex items-center justify-between text-xs text-muted-foreground">
            {task.dueDate && (
              <div className="flex items-center gap-1" aria-label={`Due date: ${task.dueDate}`}>
                <Calendar className="h-3 w-3" aria-hidden="true" />
                <span>{new Date(task.dueDate).toLocaleDateString()}</span>
              </div>
            )}
            {task.assignees && task.assignees.length > 0 && (
              <div className="flex items-center gap-1" aria-label={`Assigned to: ${task.assignees[0].email.split('@')[0]}`}>
                <User className="h-3 w-3" aria-hidden="true" />
                <span>{task.assignees[0].email.split('@')[0]}</span>
              </div>
            )}
          </div>

          {task.gitBranch && (
            <div className="flex items-center gap-1 text-xs text-muted-foreground" aria-label={`Git branch: ${task.gitBranch}`}>
              <GitBranch className="h-3 w-3" aria-hidden="true" />
              <span className="truncate">{task.gitBranch}</span>
            </div>
          )}
        </CardContent>
      </Card>
    </Link>
  )
}
