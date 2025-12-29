import { defineStore } from "pinia";

export const useUserStore = defineStore("user", {
  // =========================
  // STATE
  // =========================
  state: () => ({
    account: null,       
    role: null,          
    initialized: false,  
  }),

  // =========================
  // GETTERS
  // =========================
  getters: {
    isLogged: (state) => !!state.account,

    isAdmin: (state) => state.role === "ADMIN",
    isAgricoltore: (state) => state.role === "AGRICOLTORE",
    isSupervisore: (state) => state.role === "SUPERVISORE",
    isCantiniere: (state) => state.role === "CANTINIERE",
    isCorriere: (state) => state.role === "CORRIERE",
    isDistributore: (state) => state.role === "DISTRIBUTORE",
    isVisitatore: (state) => state.role === "VISITATORE",

    hasRole: (state) => (roles = []) =>
      roles.includes(state.role),
  },

  // =========================
  // ACTIONS
  // =========================
  actions: {
    setUser(account, role) {
      this.account = account;
      this.role = role;
      this.initialized = true;
    },

    setRole(role) {
      this.role = role;
    },

    reset() {
      this.account = null;
      this.role = null;
      this.initialized = false;
    },
  },
});
