import { useEffect, useState } from 'react'
import { generateClient } from 'aws-amplify/api'
import { ON_TASK_UPDATED } from '@/lib/graphql/operations'
import type { Task } from '@/lib/types'

const client = generateClient()

export function useTaskSubscription(taskId?: string) {
  const [task, setTask] = useState<Task | null>(null)

  useEffect(() => {
    if (!taskId) return

    try {
      const sub = client.graphql({
        query: ON_TASK_UPDATED,
        variables: { taskId },
      })

      if ('subscribe' in sub) {
        const subscription = sub.subscribe({
          next: ({ data }: any) => {
            setTask(data.onTaskUpdated)
          },
          error: (error) => console.error('Subscription error:', error),
        })

        return () => subscription.unsubscribe()
      }
    } catch (error) {
      console.error('Failed to setup subscription:', error)
    }
  }, [taskId])

  return task
}
