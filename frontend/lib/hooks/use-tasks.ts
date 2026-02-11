import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { generateClient } from 'aws-amplify/api'
import { LIST_TASKS, CREATE_TASK, UPDATE_TASK, GET_TASK, ASSIGN_TASK, ADD_COMMENT, GET_TASK_COMMENTS } from '@/lib/graphql/operations'
import type { CreateTaskInput, UpdateTaskInput, TaskStatus } from '@/lib/types'

const client = generateClient()

export function useTasks(status?: TaskStatus) {
  return useQuery({
    queryKey: ['tasks', status],
    queryFn: async () => {
      try {
        const result = await client.graphql({
          query: LIST_TASKS,
          variables: { status, limit: 50 },
        })
        return 'data' in result && result.data ? result.data.listTasks : { items: [], total: 0, nextToken: null }
      } catch (error) {
        console.error('GraphQL error:', error)
        return { items: [], total: 0, nextToken: null }
      }
    },
    retry: false,
    staleTime: 30000,
  })
}

export function useTask(taskId: string) {
  return useQuery({
    queryKey: ['task', taskId],
    queryFn: async () => {
      const result = await client.graphql({
        query: GET_TASK,
        variables: { taskId },
      })
      return 'data' in result && result.data ? result.data.getTask : null
    },
    enabled: !!taskId,
  })
}

export function useCreateTask() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (input: CreateTaskInput) => {
      const result = await client.graphql({
        query: CREATE_TASK,
        variables: { input },
      })
      return 'data' in result && result.data ? result.data.createTask : null
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks'] })
    },
  })
}

export function useUpdateTask() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (input: UpdateTaskInput) => {
      const result = await client.graphql({
        query: UPDATE_TASK,
        variables: { input },
      })
      return 'data' in result && result.data ? result.data.updateTask : null
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['tasks'] })
      if (data) queryClient.invalidateQueries({ queryKey: ['task', data.taskId] })
    },
  })
}

export function useAssignTask() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ taskId, userId }: { taskId: string; userId: string }) => {
      const result = await client.graphql({
        query: ASSIGN_TASK,
        variables: { input: { taskId, userId } },
      })
      return 'data' in result && result.data ? result.data.assignTask : null
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['tasks'] })
    },
  })
}

export function useAddComment() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({ taskId, content }: { taskId: string; content: string }) => {
      const result = await client.graphql({
        query: ADD_COMMENT,
        variables: { input: { taskId, content } },
      })
      return 'data' in result && result.data ? result.data.addComment : null
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['comments', variables.taskId] })
    },
  })
}


export function useTaskComments(taskId: string) {
  return useQuery({
    queryKey: ['comments', taskId],
    queryFn: async () => {
      try {
        const result = await client.graphql({
          query: GET_TASK_COMMENTS,
          variables: { taskId },
        })
        return 'data' in result && result.data ? result.data.getTaskComments : []
      } catch (error) {
        console.error('GraphQL error:', error)
        return []
      }
    },
    enabled: !!taskId,
  })
}
