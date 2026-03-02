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
 * Risolve lo sfasamento dei dati e la sparizione dei timestamp
 */
const lottoPulito = computed(() => {
  if (!props.lotto) return null;

  // Se i dati hanno già rimosso "Creazione lotto" (controllando il primo luogo), 
  // allora non facciamo più alcuno slice.
  const giaFiltrato = props.lotto.luoghi.length > 0 && 
                      !props.lotto.luoghi[0].includes("Creazione lotto");

  if (giaFiltrato) {
    return {
      ...props.lotto,
      inRevisione: props.lotto.statoRawVero === 8
    };
  }

  // Se per qualche motivo arrivassero dati "sporchi" (grezzi dalla blockchain)
  // allora applichiamo il filtro di emergenza
  const luoghiReali = props.lotto.luoghi.filter(l => 
    !l.includes("Creazione lotto") && !l.includes("PROBLEMA:") && !l.includes("Riabilitato")
  );

  return {
    ...props.lotto,
    luoghi: luoghiReali,
    timestamps: props.lotto.timestamps.slice(1), // Solo qui facciamo lo slice se necessario
    inRevisione: props.lotto.statoRawVero === 8
  };
});
</script>

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

.dialog-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
.dialog-scroll::-webkit-scrollbar-thumb { background: #ddd; border-radius: 10px; }
</style>