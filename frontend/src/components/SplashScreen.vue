
<template>
  <div class="splash-container">
    <div class="content">
      <h1 class="title">VINUM VERITAS</h1>
      <p class="subtitle">Connessione alla Blockchain in corso...</p>
      <div class="loader"></div>
    </div>
  </div>
</template>

<style>
/* Reset globale per rimuovere margini bianchi e scrollbar indesiderate */
html, body {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
  overflow: hidden; /* Impedisce lo scroll durante il caricamento */
}
</style>

<style scoped>
.splash-container {
  /* Position fixed assicura che il div rimanga sopra ogni cosa e parta dall'angolo 0,0 */
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  
  display: flex;
  justify-content: center;
  align-items: center;
  
  background-color: #4b0c51; /* Il tuo bordeaux elegante */
  color: #ecf0f1;
  text-align: center;
  z-index: 9999; /* Sta sopra a tutto il resto */
}

.title {
  font-size: 4rem;
  letter-spacing: 8px; /* Leggermente aumentato per eleganza */
  margin: 0;
  font-family: 'Times New Roman', serif;
  font-weight: bold;
  text-transform: uppercase;
}

.subtitle {
  font-family: 'Arial', sans-serif;
  font-size: 1.1rem;
  opacity: 0.8;
  margin-top: 10px;
}

.loader {
  border: 4px solid rgba(255, 255, 255, 0.1);
  border-radius: 50%;
  border-top: 4px solid #e74c3c;
  width: 50px;
  height: 50px;
  animation: spin 1s linear infinite;
  margin: 30px auto;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

@media (max-width: 600px) {
  .title {
    font-size: 2.5rem;
    letter-spacing: 3px;
  }
}
</style>