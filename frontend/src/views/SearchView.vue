<template>
  <div class="search-page-wrapper">
    <div class="search-lotti-container">
      <header class="page-header-central">
        <h1 class="main-title">Monitoraggio Globale Lotti</h1>
        <div class="title-divider"></div>
        <p class="subtitle">Analisi tecnica e tracciabilità del registro distribuito</p>
      </header>

      <div class="filter-section card">
        <div class="search-bar">
          <input 
            v-model="searchId" 
            type="number" 
            placeholder="Inserisci l'ID del Lotto (es. 1)"
            @keyup.enter="handleSearch"
          />
          <button @click="handleSearch" class="btn-primary" :disabled="loading || isConnecting">
            <span v-if="isConnecting">Inizializzazione...</span>
            <span v-else-if="loading">Ricerca in corso...</span>
            <span v-else>Esegui Ricerca</span>
          </button>
        </div>
      </div>

      <div v-if="lottoDettaglio" class="result-section animate-fade-in">
        <div class="lotto-card card">
          <div class="lotto-header">
            <div class="lotto-id-centered">
              <h2 class="lotto-number">Lotto #{{ lottoDettaglio.id }}</h2>
            </div>
            <div :class="['status-pill', lottoDettaglio.statusClass]">
              {{ lottoDettaglio.statusLabel }}
            </div>
          </div>

          <div class="lotto-info-single">
            <div class="info-item">
              <label>Tipologia Prodotto</label>
              <p class="data-value">{{ lottoDettaglio.tipo }}</p>
            </div>
          </div>

          <div class="table-section">
            <h3 class="section-title">Stato Avanzamento Processo</h3>
            <table class="process-table-custom">
              <thead>
                <tr>
                  <th>Fase</th>
                  <th>Indirizzo Certificato</th>
                  <th>Validazione</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(address, role, index) in lottoDettaglio.actors" :key="role">
                  <td class="role-cell">{{ role }}</td>
                  <td class="address-cell">
                    {{ address !== '0x0000000000000000000000000000000000000000' ? address : 'In attesa...' }}
                  </td>
                  <td>
                    <span v-if="index < Number(lottoDettaglio.statoRaw)" class="check-valid">✅ Fatto</span>
                    <span v-else class="check-pending">❌ Da fare</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div v-else-if="hasSearched && !loading" class="error-box card animate-fade-in">
        <p>Nessun record trovato per l'ID <strong>{{ searchId }}</strong>. Assicurati che il lotto sia stato creato.</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, inject, computed } from 'vue';

const contractInstance = inject('contractInstance');

const searchId = ref('');
const loading = ref(false);
const hasSearched = ref(false);
const lottoDettaglio = ref(null);

const isConnecting = computed(() => !contractInstance || !contractInstance.value);
const STATUS_LABELS = ["creato", "vendemmiato", "fermentato", "affinato", "imbottigliato", "distribuito"];

const handleSearch = async () => {
  if (isConnecting.value) return;
  
  const visualId = Number(searchId.value);
  if (!visualId || visualId < 1) {
    alert("Inserisci un ID valido (partendo da 1)");
    return;
  }

  loading.value = true;
  hasSearched.value = true;
  lottoDettaglio.value = null;

  try {
    const searchIndex = visualId - 1;
    const res = await contractInstance.value.methods.lotti(searchIndex).call();
    
    if (res && res.id.toString() !== "0") {
      lottoDettaglio.value = {
        id: res.id.toString(),
        tipo: res.tipo,
        statoRaw: res.stato,
        statusLabel: STATUS_LABELS[Number(res.stato)] || "Sconosciuto",
        statusClass: `status-${res.stato}`,
        actors: {
          "Agricoltore": res.agricoltore,
          "Supervisore": res.supervisore,
          "Cantiniere": res.cantiniere,
          "Corriere": res.corriere,
          "Distributore": res.distributore
        }
      };
    }
  } catch (error) {
    console.error("Errore chiamata blockchain:", error);
    lottoDettaglio.value = null;
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.search-page-wrapper { background: #fff; min-height: 100vh; }
.search-lotti-container { max-width: 900px; margin: 0 auto; padding: 60px 20px; }
.page-header-central { text-align: center; margin-bottom: 40px; }
.main-title { font-size: 2.6rem; font-weight: 800; color: #1a1a1a; margin-bottom: 10px; }
.title-divider { width: 50px; height: 4px; background: #c0392b; margin: 0 auto 20px; }
.subtitle { color: #666; font-size: 1.1rem; }

.card { border: 1px solid #eee; background: #fff; padding: 30px; border-radius: 12px; margin-bottom: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.03); }
.search-bar { display: flex; gap: 12px; }
.search-bar input { flex: 1; padding: 14px; border: 2px solid #f0f0f0; border-radius: 8px; font-size: 1rem; transition: border 0.3s;background-color: #4b0c1e; }
.search-bar input:focus { border-color: #c0392b; outline: none; }

.lotto-header { display: flex; flex-direction: column; align-items: center; border-bottom: 1px solid #f5f5f5; padding-bottom: 20px; margin-bottom: 25px; }
.lotto-number { font-size: 2.2rem; margin: 0; color: #1a1a1a; font-weight: 800; }
.status-pill { padding: 8px 20px; border-radius: 50px; font-size: 0.9rem; font-weight: 700; text-transform: uppercase; margin-top: 10px; }

.status-0 { background: #fff3e0; color: #e67e22; }
.status-5 { background: #e8f5e9; color: #27ae60; }
.status-pill:not(.status-0):not(.status-5) { background: #f4f4f4; color: #666; }

.lotto-info-single { text-align: center; margin-bottom: 35px; }
.info-item label { display: block; font-size: 0.8rem; text-transform: uppercase; color: #999; font-weight: bold; margin-bottom: 5px; }
.data-value { font-size: 1.3rem; color: #2c3e50; font-weight: 600; margin: 0; }

.process-table-custom { width: 100%; border-collapse: collapse; margin-top: 10px; }
.process-table-custom th { text-align: left; padding: 12px; background: #fafafa; font-size: 0.8rem; color: #888; text-transform: uppercase; }
.process-table-custom td { padding: 14px 12px; border-bottom: 1px solid #f1f1f1; font-size: 0.9rem; }
.role-cell { font-weight: bold; }
.address-cell { font-family: monospace; color: #666; font-size: 0.85rem; }

.check-valid { color: #27ae60; font-weight: bold; }
.check-pending { color: #c0392b; font-weight: bold; }

.error-box { text-align: center; color: #c0392b; padding: 40px; }
.animate-fade-in { animation: fadeIn 0.4s ease-out; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; } }
</style>