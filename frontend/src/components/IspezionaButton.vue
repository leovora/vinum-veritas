<!--
  IspezionaButton.vue

  Componente che permette l'apertura di un dialog di dettaglio
  per visualizzare le informazioni complete di un lotto.
-->

<template>
  <div>
    <button @click="openDialog" class="btn-ispeziona">
      🔍 Ispeziona
    </button>

    <div v-if="dialogVisible" class="dialog-overlay" @click.self="closeDialog">
      <div class="dialog-content show">
        <div class="dialog-scroll">
          <LottoCard v-if="lottoPulito" :lotto="lottoPulito" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import LottoCard from './LottoCard.vue';


//Il componente riceve un lotto già recuperato dallo smart contract
const props = defineProps({
  lotto: { type: Object, required: true }
});

const dialogVisible = ref(false);
const openDialog = () => { dialogVisible.value = true; };
const closeDialog = () => { dialogVisible.value = false; };

/**
 * lottoPulito:
 * 
 * Computed che costruisce una versione derivata del lotto,
 * evitando di mutare direttamente props.lotto.
 */
const lottoPulito = computed(() => {
  if (!props.lotto) return null;

  const inRevisione = !!props.lotto.inRevisione;
  const eliminato = !!props.lotto.eliminato;
  
  //Rimozione evento iniziale di creazione
  const luoghi = props.lotto.luoghi?.filter(l => !l.includes("Creazione lotto")) || [];
  const timestampsPuliti = props.lotto.timestamps?.slice(luoghi.length === props.lotto.luoghi.length ? 0 : 1) || [];

  return {
    ...props.lotto,
    luoghi: luoghi,
    timestamps: timestampsPuliti,
    eliminato,
    inRevisione,
    motivazione: props.lotto.motivazione || null
  };
});
</script>

<style scoped>
.btn-ispeziona {
  background: #1a1a1a;
  color: white;
  border: none;
  padding: 8px 12px;
  border-radius: 6px;
  cursor: pointer;
  transition: 0.2s;
  font-weight: 600;
}
.btn-ispeziona:hover { background: #c0392b; }

.dialog-overlay {
  position: fixed;
  top: 0; left: 0;
  width: 100%; height: 100%;
  background: rgba(0,0,0,0.6);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 2000;
}

.dialog-content {
  max-width: 95%;
  max-height: 90vh;
  width: 850px;
  display: flex;
  flex-direction: column;
  opacity: 0;
  transform: translateY(-20px);
  transition: opacity 0.3s ease, transform 0.3s ease;
}

.dialog-content.show {
  opacity: 1;
  transform: translateY(0);
}

.dialog-scroll {
  overflow-y: auto;
  overflow-x: auto;
  padding: 5px;
}

.dialog-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.dialog-scroll::-webkit-scrollbar-thumb { background: #ddd; border-radius: 10px; }
</style>