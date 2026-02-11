import { generateClient } from 'aws-amplify/api'
import { GET_PRESIGNED_UPLOAD_URL } from '@/lib/graphql/operations'

const client = generateClient()

export async function uploadFile(file: File, taskId: string) {
  const result = await client.graphql({
    query: GET_PRESIGNED_UPLOAD_URL,
    variables: {
      fileName: file.name,
      fileType: file.type,
      taskId,
    },
  })

  if ('data' in result && result.data) {
    const { url } = result.data.getPresignedUploadUrl

    await fetch(url, {
      method: 'PUT',
      body: file,
      headers: {
        'Content-Type': file.type,
      },
    })

    return { success: true, fileName: file.name }
  }

  throw new Error('Failed to get upload URL')
}
