import { useQuery } from '@tanstack/react-query'
import { generateClient } from 'aws-amplify/api'
import { LIST_USERS } from '@/lib/graphql/operations'

const client = generateClient()

export function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: async () => {
      try {
        const result = await client.graphql({
          query: LIST_USERS,
        })
        return 'data' in result && result.data ? result.data.listUsers : []
      } catch (error) {
        console.error('GraphQL error:', error)
        return []
      }
    },
    staleTime: 60000,
  })
}
