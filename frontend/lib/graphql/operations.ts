export const LIST_TASKS = `
  query ListTasks($status: TaskStatus, $sprintId: ID, $limit: Int) {
    listTasks(status: $status, sprintId: $sprintId, limit: $limit) {
      items {
        taskId
        title
        description
        status
        priority
        dueDate
        estimatedPoints
        labels
        gitBranch
        prUrl
        createdAt
        updatedAt
      }
      total
    }
  }
`

export const GET_TASK = `
  query GetTask($taskId: ID!) {
    getTask(taskId: $taskId) {
      taskId
      title
      description
      status
      priority
      dueDate
      estimatedPoints
      labels
      gitBranch
      prUrl
      createdAt
      updatedAt
    }
  }
`

export const CREATE_TASK = `
  mutation CreateTask($input: CreateTaskInput!) {
    createTask(input: $input) {
      taskId
      title
      status
      priority
      createdAt
    }
  }
`

export const UPDATE_TASK = `
  mutation UpdateTask($input: UpdateTaskInput!) {
    updateTask(input: $input) {
      taskId
      title
      status
      priority
      updatedAt
    }
  }
`

export const ASSIGN_TASK = `
  mutation AssignTask($input: AssignTaskInput!) {
    assignTask(input: $input) {
      taskId
      title
    }
  }
`

export const ADD_COMMENT = `
  mutation AddComment($input: AddCommentInput!) {
    addComment(input: $input) {
      commentId
      taskId
      content
      createdAt
    }
  }
`

export const SEARCH_TASKS = `
  query SearchTasks($input: SearchTasksInput!) {
    searchTasks(input: $input) {
      tasks {
        taskId
        title
        description
        status
        priority
      }
      total
    }
  }
`

export const GET_PRESIGNED_UPLOAD_URL = `
  query GetPresignedUploadUrl($fileName: String!, $fileType: String!, $taskId: ID!) {
    getPresignedUploadUrl(fileName: $fileName, fileType: $fileType, taskId: $taskId) {
      url
      expiresIn
    }
  }
`

export const ON_TASK_UPDATED = `
  subscription OnTaskUpdated($taskId: ID) {
    onTaskUpdated(taskId: $taskId) {
      taskId
      title
      status
      priority
      updatedAt
    }
  }
`

export const LIST_USERS = `
  query ListUsers {
    listUsers {
      userId
      email
      groups
      isAdmin
    }
  }
`

export const GET_TASK_COMMENTS = `
  query GetTaskComments($taskId: ID!) {
    getTaskComments(taskId: $taskId) {
      commentId
      content
      createdAt
    }
  }
`
