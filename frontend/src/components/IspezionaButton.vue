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

const openDialog = () => {
  console.log("Ispeziona: Apertura modale per lotto", props.lotto.id);
  dialogVisible.value = true;
};

const closeDialog = () => {
  dialogVisible.value = false;
};

/**
 * COMPUTED: lottoPulito
 * Crea una copia del lotto filtrando i messaggi tecnici (PROBLEMA, Riabilitato)
 * dall'array dei luoghi per mantenere la timeline pulita nella modale.
 */
const lottoPulito = computed(() => {
  if (!props.lotto) return null;

  // Filtriamo i luoghi rimuovendo le note tecniche
  const luoghiFiltrati = props.lotto.luoghi.filter(l => 
    !l.includes("PROBLEMA:") && !l.includes("Riabilitato")
  );

  // Estraiamo la motivazione se il lotto è in revisione (per LottoCard)
  const notaProblema = props.lotto.luoghi
    .findLast(l => l.includes("PROBLEMA:"))
    ?.replace("PROBLEMA: ", "");

  // Restituiamo una copia del lotto con i dati corretti
  return {
    ...props.lotto,
    luoghi: luoghiFiltrati,
    motivazione: props.lotto.stato === 'revisione' ? notaProblema : null
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
  z-index: 2000; /* Aumentato per stare sopra a tutto */
}

.dialog-content {
  background: white;
  padding: 20px;
  border-radius: 12px;
  max-width: 90%;      
  max-height: 90vh;    
  width: 750px;
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
  overflow-x: hidden;
}

/* Scrollbar personalizzata per la modale */
.dialog-scroll::-webkit-scrollbar {
  width: 6px;
}

.dialog-scroll::-webkit-scrollbar-thumb {
  background: #ddd;
  border-radius: 10px;
}
</style>