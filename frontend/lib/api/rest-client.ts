import { get, post, put, del } from 'aws-amplify/api'
import type {
  CreateTaskInput,
  Priority,
  RestAssignTaskResponse,
  RestTaskListResponse,
  RestUsersResponse,
  Task,
  TaskStatus,
  UpdateTaskInput,
  User,
} from '@/lib/types'

const API_NAME = 'TaskAPI'

interface RestErrorPayload {
  message?: string
  error?: string
  details?: unknown
}

type RawTask = Partial<{
  TaskId: string
  taskId: string
  Title: string
  title: string
  Description: string
  description: string
  Priority: Priority
  priority: Priority
  Status: TaskStatus
  status: TaskStatus
  CreatedBy: string
  createdBy: string
  CreatedAt: number | string
  createdAt: number | string
  UpdatedAt: number | string
  updatedAt: number | string
  UpdatedBy: string
  updatedBy: string
  ClosedBy: string
  closedBy: string
  ClosedAt: number | string
  closedAt: number | string
}>

interface RawTasksResponse {
  tasks?: RawTask[]
  count?: number
}

class RestApiError extends Error {
  statusCode?: number
  details?: unknown

  constructor(message: string, statusCode?: number, details?: unknown) {
    super(message)
    this.name = 'RestApiError'
    this.statusCode = statusCode
    this.details = details
  }
}

function toIsoDate(value?: number | string): string {
  if (typeof value === 'number') {
    return new Date(value).toISOString()
  }

  if (typeof value === 'string' && value.length > 0) {
    return /^\d+$/.test(value) ? new Date(Number(value)).toISOString() : value
  }

  return new Date(0).toISOString()
}

function normalizeTask(raw: RawTask): Task {
  return {
    taskId: raw.taskId ?? raw.TaskId ?? '',
    title: raw.title ?? raw.Title ?? 'Untitled task',
    description: raw.description ?? raw.Description ?? '',
    status: raw.status ?? raw.Status ?? 'OPEN',
    priority: raw.priority ?? raw.Priority ?? 'MEDIUM',
    createdBy: raw.createdBy ?? raw.CreatedBy ?? '',
    createdAt: toIsoDate(raw.createdAt ?? raw.CreatedAt),
    updatedAt: toIsoDate(raw.updatedAt ?? raw.UpdatedAt ?? raw.createdAt ?? raw.CreatedAt),
    updatedBy: raw.updatedBy ?? raw.UpdatedBy,
    closedBy: raw.closedBy ?? raw.ClosedBy,
    closedAt: raw.closedAt ?? raw.ClosedAt ? toIsoDate(raw.closedAt ?? raw.ClosedAt) : undefined,
  }
}

function normalizeUser(user: Partial<User>): User {
  return {
    userId: user.userId ?? '',
    email: user.email ?? '',
    groups: user.groups ?? [],
    isAdmin: Boolean(user.isAdmin),
  }
}

async function parseRestError(error: unknown, fallbackMessage: string): Promise<RestApiError> {
  let message = fallbackMessage
  let statusCode: number | undefined
  let details: unknown

  if (error && typeof error === 'object') {
    const apiError = error as {
      response?: {
        statusCode?: number
        body?: { json: () => Promise<RestErrorPayload> }
      }
      message?: string
    }

    statusCode = apiError.response?.statusCode

    if (apiError.response?.body) {
      try {
        const payload = await apiError.response.body.json()
        details = payload.details
        message = payload.message ?? payload.error ?? fallbackMessage
      } catch {
        message = apiError.message ?? fallbackMessage
      }
    } else {
      message = apiError.message ?? fallbackMessage
    }
  }

  return new RestApiError(message, statusCode, details)
}

async function requestJson<T>(
  request: () => Promise<{ body: { json: () => Promise<unknown> } }>,
  fallbackErrorMessage: string
): Promise<T> {
  try {
    const response = await request()
    return (await response.body.json()) as T
  } catch (error) {
    throw await parseRestError(error, fallbackErrorMessage)
  }
}

export const restApi = {
  async listTasks(params?: { status?: TaskStatus }): Promise<RestTaskListResponse> {
    const payload = await requestJson<RawTasksResponse>(
      () =>
        get({
          apiName: API_NAME,
          path: '/tasks',
          options: { queryParams: params },
        }).response,
      'Failed to fetch tasks'
    )

    const tasks = (payload.tasks ?? []).map(normalizeTask).filter((task) => task.taskId.length > 0)
    return { tasks, count: payload.count ?? tasks.length }
  },

  async getTask(taskId: string): Promise<Task> {
    const payload = await requestJson<RawTask>(
      () =>
        get({
          apiName: API_NAME,
          path: `/tasks/${taskId}`,
        }).response,
      'Failed to fetch task'
    )

    const task = normalizeTask(payload)
    if (!task.taskId) {
      throw new RestApiError('Task payload is invalid', 500, payload)
    }
    return task
  },

  async createTask(data: CreateTaskInput): Promise<Task> {
    const payload = await requestJson<RawTask>(
      () =>
        post({
          apiName: API_NAME,
          path: '/tasks',
          options: { body: data as any },
        }).response,
      'Failed to create task'
    )
    return normalizeTask(payload)
  },

  async updateTask(taskId: string, data: Partial<UpdateTaskInput>): Promise<Task> {
    const payload = await requestJson<RawTask>(
      () =>
        put({
          apiName: API_NAME,
          path: `/tasks/${taskId}`,
          options: { body: data as any },
        }).response,
      'Failed to update task'
    )
    return normalizeTask(payload)
  },

  async updateTaskStatus(taskId: string, status: TaskStatus): Promise<Task> {
    const payload = await requestJson<RawTask>(
      () =>
        put({
          apiName: API_NAME,
          path: `/tasks/${taskId}/status`,
          options: { body: { status } },
        }).response,
      'Failed to update task status'
    )
    return normalizeTask(payload)
  },

  async assignTask(taskId: string, assignedTo: string): Promise<RestAssignTaskResponse> {
    const payload = await requestJson<{
      message?: string
      assignment?: {
        TaskId?: string
        taskId?: string
        UserId?: string
        userId?: string
        AssignedBy?: string
        assignedBy?: string
        AssignedAt?: number | string
        assignedAt?: number | string
      }
    }>(
      () =>
        post({
          apiName: API_NAME,
          path: `/tasks/${taskId}/assign`,
          options: { body: { assignedTo } },
        }).response,
      'Failed to assign task'
    )

    const assignment = payload.assignment
    if (!assignment) {
      throw new RestApiError('Assignment payload is invalid')
    }

    return {
      message: payload.message ?? 'Task assigned successfully',
      assignment: {
        taskId: assignment.taskId ?? assignment.TaskId ?? taskId,
        userId: assignment.userId ?? assignment.UserId ?? assignedTo,
        assignedBy: assignment.assignedBy ?? assignment.AssignedBy ?? '',
        assignedAt: toIsoDate(assignment.assignedAt ?? assignment.AssignedAt),
      },
    }
  },

  async closeTask(taskId: string): Promise<Task> {
    const payload = await requestJson<RawTask>(
      () =>
        post({
          apiName: API_NAME,
          path: `/tasks/${taskId}/close`,
        }).response,
      'Failed to close task'
    )
    return normalizeTask(payload)
  },

  async deleteTask(taskId: string): Promise<{ message: string }> {
    const payload = await requestJson<{ message?: string }>(
      () =>
        del({
          apiName: API_NAME,
          path: `/tasks/${taskId}`,
        }).response,
      'Failed to delete task'
    )
    return { message: payload.message ?? 'Task deleted successfully' }
  },

  async listUsers(): Promise<RestUsersResponse> {
    const payload = await requestJson<RestUsersResponse>(
      () =>
        get({
          apiName: API_NAME,
          path: '/users',
        }).response,
      'Failed to fetch users'
    )
    return {
      users: (payload.users ?? []).map(normalizeUser).filter((user) => user.userId.length > 0),
    }
  },
}

export { RestApiError }
