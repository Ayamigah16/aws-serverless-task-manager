import { useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { generateClient } from 'aws-amplify/api'
import { restApi, RestApiError } from '@/lib/api/rest-client'
import { ON_TASK_UPDATED } from '@/lib/graphql/operations'
import type { CreateTaskInput, RestTaskListResponse, RestUsersResponse, Task, TaskStatus } from '@/lib/types'

const graphqlClient = generateClient()

const restTaskKeys = {
  all: ['rest-tasks'] as const,
  list: (status?: TaskStatus) => ['rest-tasks', { status: status ?? 'ALL' }] as const,
  detail: (taskId: string) => ['rest-task', taskId] as const,
  users: ['rest-users'] as const,
}

type TasksSnapshot = RestTaskListResponse | undefined

function optimisticTaskUpdate(
  current: TasksSnapshot,
  taskId: string,
  updater: (task: Task) => Task
): TasksSnapshot {
  if (!current) return current
  return {
    ...current,
    tasks: current.tasks.map((task) => (task.taskId === taskId ? updater(task) : task)),
  }
}

function toErrorMessage(error: unknown, fallback: string): string {
  if (error instanceof RestApiError) {
    return error.message
  }
  if (error instanceof Error) {
    return error.message
  }
  return fallback
}

export function useRestTasks(status?: TaskStatus) {
  return useQuery({
    queryKey: restTaskKeys.list(status),
    queryFn: () => restApi.listTasks({ status }),
    refetchOnWindowFocus: true,
    refetchInterval: 15000,
    refetchIntervalInBackground: false,
    retry: 1,
    staleTime: 10000,
  })
}

export function useRestTask(taskId: string) {
  return useQuery({
    queryKey: restTaskKeys.detail(taskId),
    queryFn: () => restApi.getTask(taskId),
    enabled: !!taskId,
  })
}

export function useRestCreateTask() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateTaskInput) => restApi.createTask(input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: restTaskKeys.all })
    },
  })
}

export function useRestUpdateTaskStatus() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ taskId, status }: { taskId: string; status: TaskStatus }) =>
      restApi.updateTaskStatus(taskId, status),
    onMutate: async ({ taskId, status }) => {
      await queryClient.cancelQueries({ queryKey: restTaskKeys.all })

      const snapshots = queryClient.getQueriesData<RestTaskListResponse>({ queryKey: restTaskKeys.all })
      snapshots.forEach(([queryKey, current]) => {
        queryClient.setQueryData<RestTaskListResponse>(
          queryKey,
          optimisticTaskUpdate(current, taskId, (task) => ({
            ...task,
            status,
            updatedAt: new Date().toISOString(),
          }))
        )
      })

      return { snapshots }
    },
    onError: (_error, _variables, context) => {
      context?.snapshots?.forEach(([queryKey, snapshot]) => {
        queryClient.setQueryData(queryKey, snapshot)
      })
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: restTaskKeys.all })
    },
  })
}

export function useRestAssignTask() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ taskId, assignedTo }: { taskId: string; assignedTo: string }) =>
      restApi.assignTask(taskId, assignedTo),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: restTaskKeys.all })
    },
  })
}

export function useRestCloseTask() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: restApi.closeTask,
    onMutate: async (taskId) => {
      await queryClient.cancelQueries({ queryKey: restTaskKeys.all })

      const snapshots = queryClient.getQueriesData<RestTaskListResponse>({ queryKey: restTaskKeys.all })
      snapshots.forEach(([queryKey, current]) => {
        queryClient.setQueryData<RestTaskListResponse>(
          queryKey,
          optimisticTaskUpdate(current, taskId, (task) => ({
            ...task,
            status: 'CLOSED',
            updatedAt: new Date().toISOString(),
          }))
        )
      })

      return { snapshots }
    },
    onError: (_error, _taskId, context) => {
      context?.snapshots?.forEach(([queryKey, snapshot]) => {
        queryClient.setQueryData(queryKey, snapshot)
      })
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: restTaskKeys.all })
    },
  })
}

export function useRestUsers() {
  return useQuery({
    queryKey: restTaskKeys.users,
    queryFn: () => restApi.listUsers(),
    staleTime: 60000,
    retry: 1,
  })
}

export function useRestRealtimeSync(enabled = true) {
  const queryClient = useQueryClient()

  useEffect(() => {
    if (!enabled) return
    if (!process.env.NEXT_PUBLIC_APPSYNC_ENDPOINT) return

    let stream: ReturnType<typeof graphqlClient.graphql>
    try {
      stream = graphqlClient.graphql({ query: ON_TASK_UPDATED })
    } catch (error) {
      console.error('Failed to initialize task subscription:', error)
      return
    }

    if (!('subscribe' in stream)) return

    const subscription = (stream as { subscribe: Function }).subscribe({
      next: () => {
        queryClient.invalidateQueries({ queryKey: restTaskKeys.all })
      },
      error: (error: unknown) => {
        console.error('Task subscription error:', error)
      },
    })

    return () => {
      subscription.unsubscribe()
    }
  }, [enabled, queryClient])
}

export { restTaskKeys, toErrorMessage }
