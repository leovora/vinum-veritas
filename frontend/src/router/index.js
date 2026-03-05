/**
 * router.js
 *
 * Configurazione dei percorsi per il router
 */

import { createWebHistory, createRouter } from 'vue-router'
import { useUserStore } from '../stores/user'

import SplashView from '../views/SplashView.vue'
import ProducerView from '../views/ProducerView.vue'
import RolesView from '../views/RolesView.vue'
import SearchView from '../views/SearchView.vue'
import SupervisorView from '../views/UpdateProcessView.vue'
import HistoryView from '../views/HistoryView.vue'

const routes = [
  {
    path: '/',
    name: 'Splash',
    component: SplashView
  },
  {
    path: '/producer',
    name: 'Producer',
    component: ProducerView,
    meta: { roles: ['ADMIN'] } 
  },
  {
    path: '/update',
    name: 'Update',
    component: SupervisorView,
    meta: { roles: ['AGRICOLTORE', 'SUPERVISORE', 'CANTINIERE', 'CORRIERE', 'DISTRIBUTORE'] } 
  },
  {
    path: '/history',
    name: 'History',
    component: HistoryView,
    meta: { roles: ['ADMIN', 'AGRICOLTORE', 'SUPERVISORE', 'CANTINIERE', 'CORRIERE', 'DISTRIBUTORE'] } 
  },
  {
    path: '/search',
    name: 'Search',
    component: SearchView,
    meta: { roles: ['ADMIN', 'AGRICOLTORE', 'SUPERVISORE', 'CANTINIERE', 'CORRIERE', 'DISTRIBUTORE', 'VISITATORE'] } 
  },
  {
    path: '/roles',
    name: 'Roles',
    component: RolesView,
    meta: { roles: ['ADMIN'] }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('../views/NotFound.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

/**
   * Controlla se il percorso richiede permessi
   * - to.meta.roles contiene i ruoli autorizzati
   * - Se l’utente non ha il ruolo, redirect a pagina "not-authorized"
   */
router.beforeEach((to) => {
  const userStore = useUserStore()
  if (to.meta?.roles && !to.meta.roles.includes(userStore.role)) {
    return '/not-authorized'
  }
})

export default router
