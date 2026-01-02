<template>
  <div class="history-page-wrapper">
    <div class="history-container">
      <header class="page-header-central">
        <h1 class="main-title">Registro Storico Filiera</h1>
        <div class="title-divider"></div>
        <p class="subtitle">
          Archivio completo dei lotti
        </p>
      </header>

      <div v-if="loading" class="loading-state card">
        <div class="spinner"></div>
        <p>Interrogazione del registro distribuito in corso...</p>
      </div>

      <div v-else-if="lotti.length > 0" class="history-content animate-fade-in">
        <div class="stats-overview">
          <div class="stat-card">
            <span class="stat-label">Totale Lotti</span>
            <span class="stat-value">{{ lotti.length }}</span>
          </div>
          <div class="stat-card">
            <span class="stat-label">Stato Sistema</span>
            <span class="stat-value status-online">Operativo</span>
          </div>
        </div>

        <div class="table-container card">
          <table class="history-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Tipologia</th>
                <th>Stato Attuale</th>
                <th>Data</th>
                <th class="text-right">Azioni</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="lotto in lotti" :key="lotto.id">
                <td class="id-cell">#{{ lotto.id }}</td>
                <td class="tipo-cell">
                  <strong>{{ lotto.tipo }}</strong>
                </td>
                <td>
                  <span :class="['status-pill', lotto.statusClass]">
                    {{ lotto.statusLabel }}
                  </span>
                </td>
                <td class="date-cell">{{ lotto.data }}</td>
                <td class="text-right">
                  <IspezionaButton :lotto="lotto" />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div v-else class="empty-state card">
        <p>
          Nessun lotto registrato nello storico. Avvia una produzione per
          visualizzare i dati.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, inject, onMounted } from "vue";
import IspezionaButton from "../components/IspezionaButton.vue";

const contractInstance = inject("contractInstance");

const lotti = ref([]);
const loading = ref(true);

const STATUS_LABELS = [
  "creato",
  "vendemmiato",
  "fermentato",
  "affinato",
  "imbottigliato",
  "spedito",
  "distribuito",
];

const loadHistory = async () => {
  if (!contractInstance?.value) return;

  loading.value = true;
  try {
    const data = await contractInstance.value.methods.getLotti().call();

    lotti.value = data.map((l) => {
      const tsArray = l.timestamps?.map((t) => Number(t)) || [];
      const luoghiArray = l.luoghi || [];

      const faseTimestamps = tsArray.slice(1);
      const faseLuoghi = luoghiArray.slice(1);

      return {
        id: l.id.toString(),
        tipo: l.tipo,
        statoRaw: Number(l.stato),
        statusLabel: STATUS_LABELS[Number(l.stato)] || "Finito",
        statusClass: `status-${l.stato}`,
        data:
          tsArray.length > 0
            ? new Date(tsArray[tsArray.length - 1] * 1000).toLocaleDateString("it-IT")
            : "In attesa...",
        actors: {
          Agricoltore: l.agricoltore,
          Supervisore: l.supervisore,
          Cantiniere: l.cantiniere,
          Corriere: l.corriere,
          Distributore: l.distributore,
        },
        timestamps: faseTimestamps,
        luoghi: faseLuoghi,
      };
    });

  } catch (err) {
    console.error("Errore caricamento storico:", err);
  } finally {
    loading.value = false;
  }
};

onMounted(loadHistory);
</script>

<style scoped>
.history-page-wrapper {
  background: #fff;
  min-height: 100vh;
  padding: 60px 20px;
}
.history-container {
  max-width: 1000px;
  margin: 0 auto;
}

.page-header-central {
  text-align: center;
  margin-bottom: 50px;
}
.main-title {
  font-size: 2.8rem;
  font-weight: 800;
  color: #1a1a1a;
  margin: 0;
}
.title-divider {
  width: 60px;
  height: 4px;
  background: #c0392b;
  margin: 15px auto;
}
.subtitle {
  color: #666;
  font-size: 1.1rem;
}

.card {
  border: 1px solid #eee;
  background: #fff;
  padding: 25px;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03);
}

.stats-overview {
  display: flex;
  gap: 20px;
  margin-bottom: 25px;
}
.stat-card {
  background: #f8f9fa;
  padding: 15px 25px;
  border-radius: 10px;
  flex: 1;
  border-left: 4px solid #c0392b;
}
.stat-label {
  display: block;
  font-size: 0.8rem;
  text-transform: uppercase;
  color: #888;
  font-weight: bold;
}
.stat-value {
  font-size: 1.5rem;
  font-weight: 800;
  color: #333;
}
.status-online {
  color: #27ae60;
}

.history-table {
  width: 100%;
  border-collapse: collapse;
}
.history-table th {
  text-align: center;
  padding: 15px;
  border-bottom: 2px solid #f0f0f0;
  color: #999;
  font-size: 0.85rem;
  text-transform: uppercase;
}
.history-table td {
  padding: 18px 15px;
  border-bottom: 1px solid #f8f9fa;
  text-align: center;
}

.id-cell {
  font-weight: bold;
  color: #c0392b;
}
.tipo-cell {
  font-size: 1rem;
}
.date-cell {
  color: #888;
  font-size: 0.9rem;
}

.status-pill {
  padding: 5px 12px;
  border-radius: 50px;
  font-size: 0.75rem;
  font-weight: bold;
  text-transform: uppercase;
}
.status-0 {
  background: #fff3e0;
  color: #e67e22;
}
.status-5 {
  background: #e8f5e9;
  color: #27ae60;
}
.status-pill:not(.status-0):not(.status-5) {
  background: #f0f0f0;
  color: #777;
}

.btn-action {
  background: #1a1a1a;
  color: white;
  border: none;
  padding: 8px 15px;
  border-radius: 6px;
  cursor: pointer;
  transition: 0.2s;
}
.btn-action:hover {
  background: #c0392b;
}

.text-right {
  text-align: right;
}
.animate-fade-in {
  animation: fadeIn 0.5s ease-out;
}
@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}
</style>
