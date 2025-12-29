<template>
  <div class="notfound-container">
    <div class="notfound-content">
      <h1>404</h1>
      <h2>Pagina non trovata</h2>
      <p>La pagina che stai cercando non esiste o il link è errato.</p>
      <button @click="goHome">Torna alla Home</button>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router';

const router = useRouter();

const goHome = () => {
  router.push('/');
};
</script>

<style scoped>
.notfound-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 50vh;
  background-color: var(--color-bg);
  color: var(--color-text-dark);
  text-align: center;
  padding: 20px;
}

.notfound-content h1 {
  font-size: 6rem;
  font-weight: var(--font-weight-bold);
  color: var(--color-bordeaux);
  margin-bottom: 10px;
}

.notfound-content h2 {
  font-size: 2rem;
  margin-bottom: 15px;
}

.notfound-content p {
  font-size: 1rem;
  margin-bottom: 25px;
}

.notfound-content button {
  background-color: var(--color-bordeaux);
  color: var(--color-bianco);
  padding: var(--btn-padding);
  border-radius: var(--btn-radius);
  font-weight: var(--font-weight-bold);
  border: none;
  cursor: pointer;
  transition: background 0.3s;
}

.notfound-content button:hover {
  background-color: var(--color-rosso);
}
</style>
