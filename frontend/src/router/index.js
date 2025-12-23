import { createWebHistory, createRouter } from 'vue-router'
import { useUserStore } from '../stores/user'

import SplashView from '../views/SplashView.vue'
import ProducerView from '../views/ProducerView.vue'
import RolesView from '../views/RolesView.vue'
import SearchView from '../views/SearchView.vue'
import SupervisorView from '../views/SupervisorView.vue'
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
    meta: { roles: ['admin'] } 
  },
  {
    path: '/update',
    name: 'Update',
    component: SupervisorView,
    meta: { roles: ['supervisor', 'admin'] }
  },
  {
    path: '/history',
    name: 'History',
    component: HistoryView,
    meta: { roles: ['admin', 'supervisor'] }
  },
  {
    path: '/search',
    name: 'Search',
    component: SearchView,
    meta: { roles: ['admin', 'supervisor'] }
  },
  {
    path: '/roles',
    name: 'Roles',
    component: RolesView,
    meta: { roles: ['admin'] }
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

router.beforeEach((to) => {
  const userStore = useUserStore()
  if (to.meta?.roles && !to.meta.roles.includes(userStore.role)) {
    return '/not-authorized'
  }
})

export default router
