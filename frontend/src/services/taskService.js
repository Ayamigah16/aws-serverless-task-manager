import { API } from 'aws-amplify';

const API_NAME = 'TaskAPI';

export const taskService = {
  async getTasks() {
    return await API.get(API_NAME, '/tasks');
  },

  async getTask(taskId) {
    return await API.get(API_NAME, `/tasks/${taskId}`);
  },

  async createTask(taskData) {
    return await API.post(API_NAME, '/tasks', { body: taskData });
  },

  async updateTask(taskId, taskData) {
    return await API.put(API_NAME, `/tasks/${taskId}`, { body: taskData });
  },

  async assignTask(taskId, userId) {
    return await API.post(API_NAME, `/tasks/${taskId}/assign`, { body: { assignedTo: userId } });
  },

  async updateTaskStatus(taskId, status) {
    return await API.put(API_NAME, `/tasks/${taskId}/status`, { body: { status } });
  },

  async closeTask(taskId) {
    return await API.post(API_NAME, `/tasks/${taskId}/close`, { body: {} });
  },

  async deleteTask(taskId) {
    return await API.del(API_NAME, `/tasks/${taskId}`);
  }
};
