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

const STATUS_LABELS = [
  "creato", "vendemmiato", "fermentato", "affinato", 
  "imbottigliato", "spedito", "distribuito", "completato", "revisione" 
];

// ===================== HANDLE SEARCH =====================
const handleSearch = async () => {
  if (isConnecting.value) return;

  const targetId = searchId.value.toString();
  if (!targetId || Number(targetId) < 1) {
    showToast("Inserisci un ID valido", "error");
    return;
  }

  loading.value = true;
  hasSearched.value = true;
  lottoDettaglio.value = null;

  try {
    // Recuperiamo tutti i lotti per trovare l'ID corretto indipendentemente dall'indice
    const allLotti = await contractInstance.value.methods.getLotti().call();
    const res = allLotti.find(l => l.id.toString() === targetId);

    if (res && res.id.toString() !== "0") {
      const rawStato = Number(res.stato);
      const tsArray = res.timestamps.map(t => Number(t));
      const luoghiArray = res.luoghi;

      // 1. FILTRAGGIO SINCRONIZZATO (Luoghi vs Timestamps)
      const indiciValidi = [];
      const luoghiPuliti = luoghiArray.filter((l, idx) => {
        const isTecnico = l.includes("PROBLEMA:") || l.includes("Riabilitato");
        if (!isTecnico) {
          indiciValidi.push(idx);
          return true;
        }
        return false;
      });

      const timestampsPuliti = tsArray.filter((_, idx) => indiciValidi.includes(idx));

      // 2. CALCOLO STATO APPARENTE 
      // Evita che la barra progresso mostri tutto verde se lo stato è 8 (revisione)
      const statoApparente = rawStato === 8 
        ? Math.max(0, luoghiPuliti.length - 1) 
        : rawStato;

      const notaProblema = res.luoghi
        .findLast(l => l.includes("PROBLEMA:"))
        ?.replace("PROBLEMA: ", "");

      lottoDettaglio.value = {
        id: res.id.toString(),
        tipo: res.tipo,
        statoRaw: statoApparente,
        statusLabel: rawStato === 8 ? "IN REVISIONE" : STATUS_LABELS[rawStato],
        statusClass: rawStato === 8 ? "revisione" : `status-${res.stato}`,
        actors: {
          Agricoltore: res.agricoltore,
          Supervisore: res.supervisore,
          Cantiniere: res.cantiniere,
          Corriere: res.corriere,
          Distributore: res.distributore,
        },
        timestamps: timestampsPuliti.slice(1),
        luoghi: luoghiPuliti.slice(1),
        motivazione: rawStato === 8 ? notaProblema : null
      };
    } else {
      showToast("Lotto non trovato sul registro", "warning");
    }
  } catch (err) {
    console.error("Errore ricerca lotto:", err);
    showToast("Errore durante la comunicazione con la Blockchain", "error");
    lottoDettaglio.value = null;
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