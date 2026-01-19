<template>
  <div>
    <button @click="openDialog" class="btn-ispeziona">
      🔍 Ispeziona
    </button>

    <div v-if="dialogVisible" class="dialog-overlay" @click.self="closeDialog">
      <div class="dialog-content show">
        <div class="dialog-scroll">
          <LottoCard :lotto="lottoPulito" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import LottoCard from './LottoCard.vue';

const props = defineProps({
  lotto: { type: Object, required: true }
});

const dialogVisible = ref(false);
const openDialog = () => { dialogVisible.value = true; };
const closeDialog = () => { dialogVisible.value = false; };

/**
 * COMPUTED: lottoPulito
 * Filtra i dati tecnici per mostrare solo la cronologia reale nella modale.
 */
const lottoPulito = computed(() => {
  if (!props.lotto) return null;

  const rawStato = Number(props.lotto.statoRawVero || props.lotto.statoRaw);
  const isRevisione = rawStato === 8;

  const luoghiReali = props.lotto.luoghi.filter(l => 
    !l.includes("Creazione lotto") && 
    !l.includes("PROBLEMA:") && 
    !l.includes("Riabilitato")
  );

  const numeroFasiEffettive = isRevisione 
    ? luoghiReali.length 
    : (rawStato > 7 ? 7 : rawStato);

  const timestampsPuliti = props.lotto.timestamps
    .map(t => Number(t))
    .slice(1, numeroFasiEffettive + 1);

  const statoGrafico = isRevisione ? numeroFasiEffettive : rawStato;

  const notaProblema = props.lotto.luoghi
    .findLast(l => l.includes("PROBLEMA:"))
    ?.replace("PROBLEMA: ", "");

  return {
    ...props.lotto,
    statoRaw: statoGrafico, 
    luoghi: luoghiReali,
    timestamps: timestampsPuliti,
    motivazione: isRevisione ? notaProblema : null,
    inRevisione: isRevisione
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
}
.btn-ispeziona:hover { background: #c0392b; }

.dialog-overlay {
  position: fixed;
  top: 0; left: 0;
  width: 100%; height: 100%;
  background: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 2000;
}

.dialog-content {
  background: white;
  padding: 20px;
  border-radius: 12px;
  max-width: 95%;      
  max-height: 90vh;    
  width: 850px; 
  display: flex;
  flex-direction: column;
  box-shadow: 0 10px 30px rgba(0,0,0,0.3);
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

/* Personalizzazione barre di scorrimento */
.dialog-scroll::-webkit-scrollbar {
  width: 6px;
  height: 6px; 
}
.dialog-scroll::-webkit-scrollbar-thumb {
  background: #ddd;
  border-radius: 10px;
}
.dialog-scroll::-webkit-scrollbar-thumb:hover {
  background: #ccc;
}
</style>