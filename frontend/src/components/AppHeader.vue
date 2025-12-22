<template>
  <header class="vinum-header">
    <div class="nav-wrapper">
      <button @click="toggleMenu" class="hamburger-btn" aria-label="Menu">
        <div :class="['bar', { open: isMenuOpen }]"></div>
        <div :class="['bar', { open: isMenuOpen }]"></div>
        <div :class="['bar', { open: isMenuOpen }]"></div>
      </button>

      <transition name="slide">
        <div v-if="isMenuOpen">
          <nav class="dropdown-menu">
            <ul>
              <li @click="closeMenu">Processi</li>
              <li @click="closeMenu">Ricerca</li>
              <li @click="closeMenu">Storico</li>
              <li @click="closeMenu">Assegna Ruoli</li>
              <li class="divider"></li>
              <li @click="closeMenu" class="logout">🚪 Logout</li>
            </ul>
          </nav>
        </div>
      </transition>
    </div>

    <div class="header-inner">
      <h1>CENTRO DI PRODUZIONE</h1>
      <p class="subtitle">
        Gestione Lotti Vinicoli & Tracciabilità Smart Contract
      </p>
    </div>
  </header>
</template>

<script setup>
import { ref } from "vue";
const isMenuOpen = ref(false);
const toggleMenu = () => (isMenuOpen.value = !isMenuOpen.value);
const closeMenu = () => (isMenuOpen.value = false);
</script>

<style scoped>
.vinum-header {
  background-color: var(--color-bordeaux);
  color: var(--color-bianco);
  padding: var(--header-padding);
  text-align: center;
  box-shadow: var(--header-box-shadow);
  width: 100vw;
  position: relative;
}
.header-inner h1 {
  font-family: var(--font-header);
  font-weight: var(--font-weight-bold);
  text-transform: uppercase;
  font-size: 3rem;
  letter-spacing: 5px;
}
.nav-wrapper {
  position: absolute;
  top: 30px;
  left: 5vw;
  z-index: 100;
}
.hamburger-btn {
  background: none;
  border: none;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  gap: 5px;
  margin-top: 50px;
}
.bar {
  width: 30px;
  height: 3px;
  background-color: var(--color-bianco);
  transition: 0.3s;
}
.bar.open:nth-child(1) {
  transform: translateY(8px) rotate(45deg);
}
.bar.open:nth-child(2) {
  opacity: 0;
}
.bar.open:nth-child(3) {
  transform: translateY(-8px) rotate(-45deg);
}
.dropdown-menu {
  position: absolute;
  top: var(--dropdown-top);
  background: var(--color-bianco);
  min-width: var(--dropdown-width);
  border-radius: var(--card-radius);
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
  padding: var(--dropdown-padding);
  text-align: left;
}
.overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  z-index: 50;
  background: var(--color-overlay);
}
.dropdown-menu ul {
  list-style: none;
  margin: 0;
  padding: 0;
}
.dropdown-menu li {
  padding: 15px 25px;
  color: #333;
  cursor: pointer;
  font-weight: var(--font-weight-normal);
}
.dropdown-menu li:hover {
  background: #f0f0f0;
  color: var(--color-bordeaux);
}
.divider {
  height: 1px;
  background: #eee;
  margin: 5px 0;
  padding: 0;
}
.logout {
  color: var(--color-bordeaux);
}
</style>
