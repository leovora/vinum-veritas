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
            placeholder="Inserisci l'ID del Lotto (es. 3)"
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

// ===================== HANDLE SEARCH =====================
const handleSearch = async () => {
  const targetId = searchId.value.toString().trim();

  if (!targetId || Number(targetId) < 1) {
    showToast("Inserisci un ID valido", "error");
    return;
  }

  loading.value = true;
  lottoDettaglio.value = null;

  try {
    const lottoData = await contractInstance.value.methods
      .getLotto(targetId)
      .call();

    const storico = await contractInstance.value.methods
      .getStorico(targetId)
      .call();

    const statoFilieraRaw = Number(lottoData.stato);
    const statoControlloRaw = Number(lottoData.statoControllo);

    lottoDettaglio.value = {
      id: lottoData.id.toString(),
      tipo: lottoData.tipo,
      statoRaw: statoFilieraRaw,
      inRevisione: statoControlloRaw === 1,
      motivazione: lottoData.motivoRevisione,
      timestamps: storico.slice(1).map(e => Number(e.timestamp)),
      luoghi: storico.slice(1).map(e => e.luogo),
      actors: {
          agricoltore: lottoData.agricoltore,
          supervisore: lottoData.supervisore,
          cantiniere: lottoData.cantiniere,
          corriere: lottoData.corriere,
          distributore: lottoData.distributore,
        }
    };

  } catch (err) {
    showToast("Lotto inesistente", "error");
  } finally {
    loading.value = false;
  }
};

</script>

<style scoped>
.search-page-wrapper {
  background: #fdfdfd;
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

.card {
  border: 1px solid #eee;
  background: #fff;
  padding: 30px;
  border-radius: 12px;
  margin-bottom: 25px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.03);
}

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

.btn-primary {
  background: #c0392b;
  color: white;
  border: none;
  padding: 0 25px;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-primary:hover:not(:disabled) {
  background: #a93226;
}

.btn-primary:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.error-box {
  text-align: center;
  color: #c0392b;
  padding: 40px;
}

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