<template>
  <div class="search-page-wrapper">
    <div class="search-lotti-container">
      <header class="page-header-central">
        <h1 class="main-title">Monitoraggio Globale Lotti</h1>
        <div class="title-divider"></div>
        <p class="subtitle">
          Analisi tecnica e tracciabilità del registro distribuito
        </p>
      </header>

      <div class="filter-section card">
        <div class="search-bar">
          <input
            v-model="searchId"
            type="number"
            placeholder="Inserisci l'ID del Lotto (es. 1)"
            @keyup.enter="handleSearch"
          />
          <button
            class="btn-primary"
            @click="handleSearch"
            :disabled="loading || isConnecting"
          >
            <span v-if="isConnecting">Inizializzazione...</span>
            <span v-else-if="loading">Ricerca in corso...</span>
            <span v-else>Esegui Ricerca</span>
          </button>
        </div>
      </div>

      <LottoCard
        v-if="lottoDettaglio"
        :lotto="lottoDettaglio"
      />

      <div
        v-else-if="hasSearched && !loading"
        class="error-box card animate-fade-in"
      >
        <p>
          Nessun record trovato per l'ID
          <strong>{{ searchId }}</strong>
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, inject, computed } from "vue";
import LottoCard from "../components/LottoCard.vue";
import { useToast } from '../components/utils/useToast.js';

const { showToast } = useToast();

const contractInstance = inject("contractInstance");

const searchId = ref("");
const loading = ref(false);
const hasSearched = ref(false);
const lottoDettaglio = ref(null);

const isConnecting = computed(
  () => !contractInstance || !contractInstance.value
);

const STATUS_LABELS = [
  "creato",
  "vendemmiato",
  "fermentato",
  "affinato",
  "imbottigliato",
  "spedito",
  "distribuito",
];

// ===================== HANDLE SEARCH =====================
const handleSearch = async () => {
  if (isConnecting.value) return;

  const visualId = Number(searchId.value);
  if (!visualId || visualId < 1) {
    showToast("Inserisci un ID valido (partendo da 1)", "error");
    return;
  }

  loading.value = true;
  hasSearched.value = true;
  lottoDettaglio.value = null;

  try {
    const index = visualId - 1;
    const res = await contractInstance.value.methods.getLotto(index).call();

    if (res && res.id.toString() !== "0") {
      const tsArray = res.timestamps.map(t => Number(t));
      const luoghiArray = res.luoghi;

      lottoDettaglio.value = {
        id: res.id.toString(),
        tipo: res.tipo,
        statoRaw: Number(res.stato),
        statusLabel: STATUS_LABELS[Number(res.stato)],
        statusClass: `status-${res.stato}`,
        actors: {
          Agricoltore: res.agricoltore,
          Supervisore: res.supervisore,
          Cantiniere: res.cantiniere,
          Corriere: res.corriere,
          Distributore: res.distributore,
        },
        timestamps: tsArray.slice(1),
        luoghi: luoghiArray.slice(1),
      };
    }
  } catch (err) {
    console.error("Errore ricerca lotto:", err);
    lottoDettaglio.value = null;
  } finally {
    loading.value = false;
  }
};
</script>


<style scoped>
.search-page-wrapper {
  background: #fff;
  min-height: 100vh;
}

.search-lotti-container {
  max-width: 900px;
  margin: 0 auto;
  padding: 60px 20px;
}

.page-header-central {
  text-align: center;
  margin-bottom: 40px;
}

.main-title {
  font-size: 2.6rem;
  font-weight: 800;
  color: #1a1a1a;
  margin-bottom: 10px;
}

.title-divider {
  width: 50px;
  height: 4px;
  background: #c0392b;
  margin: 0 auto 20px;
}

.subtitle {
  color: #666;
  font-size: 1.1rem;
}

/* CARD GENERICHE DI PAGINA */
.card {
  border: 1px solid #eee;
  background: #fff;
  padding: 30px;
  border-radius: 12px;
  margin-bottom: 25px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.03);
}

.filter-section {
  margin-bottom: 30px;
}

/* SEARCH BAR */
.search-bar {
  display: flex;
  gap: 12px;
}

.search-bar input {
  flex: 1;
  padding: 14px;
  border: 2px solid #f0f0f0;
  border-radius: 8px;
  font-size: 1rem;
  transition: border 0.3s;
}

.search-bar input:focus {
  border-color: #c0392b;
  outline: none;
}

/* ERROR */
.error-box {
  text-align: center;
  color: #c0392b;
  padding: 40px;
}

/* ANIMAZIONE */
.animate-fade-in {
  animation: fadeIn 0.4s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

</style>
