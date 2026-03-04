/**
 * useUserStore.js
 *
 * Store Pinia per la gestione dell’utente.
 */

import { defineStore } from "pinia";

export const useUserStore = defineStore("user", {

  state: () => ({
    account: null,       
    role: null, 
    initialized: false,  
  }),

  getters: {
    //Verifica se l’utente è loggato
    isLogged: (state) => !!state.account,

    //Controlli per ogni ruolo
    isAdmin: (state) => state.role === "ADMIN",
    isAgricoltore: (state) => state.role === "AGRICOLTORE",
    isSupervisore: (state) => state.role === "SUPERVISORE",
    isCantiniere: (state) => state.role === "CANTINIERE",
    isCorriere: (state) => state.role === "CORRIERE",
    isDistributore: (state) => state.role === "DISTRIBUTORE",
    isVisitatore: (state) => state.role === "VISITATORE",

    //Controllo generico per array di ruoli
    hasRole: (state) => (roles = []) =>
      roles.includes(state.role),
  },

  actions: {
    //Imposta account e ruolo
    setUser(account, role) {
      this.account = account;
      this.role = role || "VISITATORE";
      this.initialized = true;
    },

    //Aggiorna solo il ruolo
    setRole(role) {
      this.role = role;
    },

    //Logout utente
    logout() {
      this.account = null;
      this.role = "VISITATORE";
      this.initialized = false;
      
      console.log("Store resettato: Logout effettuato.");
    },
    reset() {
      this.logout();
    }
  },
});