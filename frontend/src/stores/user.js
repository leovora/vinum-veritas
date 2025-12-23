import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useUserStore = defineStore('user', () => {
  const account = ref('')
  const role = ref('') // admin, supervisor, ecc.
  return { account, role }
})
