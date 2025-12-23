<template>
  <div class="creation-card" :class="linea">
    <h3>Linea {{ lineaText }}</h3>
    <div class="creation-controls">
      <div class="input-group">
        <label>N. Lotti</label>
        <input v-model="quantita" type="number" min="1" max="10">
      </div>
      <button @click="creaLotti(lineaText, quantita)" :class="['btn', btnClass]">
        Crea Lotti {{ lineaText }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';

const props = defineProps({
  lineaText: String,
  linea: String,
  btnClass: String,
  onCreate: Function
})

const quantita = ref(1)

const creaLotti = (tipo, quantita) => {
  props.onCreate(tipo, quantita)
}
</script>

<style scoped>
.creation-card {
  flex: 1;
  padding: 25px;
  border-radius: 12px;
  color: var(--color-text-dark);
}

.rosso { 
  background: var( --color-overlay-rosso); 
  border: 1px solid var(--color-rosso); 
}

.bianco { 
  background: var(--color-overlay-giallo); 
  border: 1px solid var(--color-giallo); 
}
.rose {
  background: var( --color-overlay-rosa); 
  border: 1px solid var(--color-rosa); 
}

.creation-card h3,
.creation-card label {
  color: var(--color-text-dark);
}

.creation-controls { 
  display: flex; 
  align-items: flex-end; 
  gap: 15px; 
  margin-top: 15px; 
}

.input-group input {
  margin-left: 10px;
  padding: 10px;
  width: 40px;
  border-radius: 8px;
  border: 1px solid var(--color-grigio-chiaro);
  text-align: center;
  background-color: var(--color-bianco);
  color: var(--color-text-dark); 
}

.btn { 
  flex: 1; 
  padding: 12px; 
  border: none; 
  border-radius: 8px; 
  font-weight: bold; 
  cursor: pointer; 
}

.btn-rosso { 
  background-color: var(--color-rosso); 
  color: var(--color-bianco); 
}

.btn-bianco { 
  background-color: var(--color-giallo); 
  color: var(--color-text-dark); 
}
.btn-rose { 
  background-color:var(--color-rosa); 
  color: black;
}
</style>
