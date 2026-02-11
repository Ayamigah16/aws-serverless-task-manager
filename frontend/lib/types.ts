export type TaskStatus = 'OPEN' | 'IN_PROGRESS' | 'IN_REVIEW' | 'COMPLETED' | 'CLOSED' | 'BLOCKED'
export type Priority = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL'

export interface Task {
  taskId: string
  title: string
  description?: string
  status: TaskStatus
  priority: Priority
  projectId?: string
  sprintId?: string
  dueDate?: string
  estimatedPoints?: number
  labels?: string[]
  gitBranch?: string
  prUrl?: string
  createdBy: string
  createdAt: string
  updatedAt: string
  updatedBy?: string
  closedBy?: string
  closedAt?: string
}

export interface CreateTaskInput {
  title: string
  description?: string
  priority: Priority
  projectId?: string
  sprintId?: string
  dueDate?: string
  estimatedPoints?: number
  labels?: string[]
}

export interface UpdateTaskInput {
  taskId: string
  title?: string
  description?: string
  priority?: Priority
  status?: TaskStatus
  dueDate?: string
  estimatedPoints?: number
  labels?: string[]
  gitBranch?: string
  prUrl?: string
}

export interface Comment {
  commentId: string
  taskId: string
  authorId: string
  content: string
  mentions?: string[]
  createdAt: string
}

export interface User {
  userId: string
  email: string
  groups: string[]
  isAdmin: boolean
}

export interface TaskListResponse {
  items: Task[]
  total: number
  nextToken?: string
}

export interface RestTaskListResponse {
  tasks: Task[]
  count: number
}

export interface RestAssignment {
  taskId: string
  userId: string
  assignedBy: string
  assignedAt: string
}

export interface RestAssignTaskResponse {
  message: string
  assignment: RestAssignment
}

export interface RestUsersResponse {
  users: User[]
}
