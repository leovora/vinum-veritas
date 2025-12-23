<template>
  <div class="producer-page-wrapper">
    <main class="dashboard-main">
      <section class="card creation-section">
        <div class="card-title"><h2>Configurazione Nuova Produzione</h2></div>
        <div class="creation-grid">
          <CreationCard
            lineaText="Rosso"
            linea="rosso"
            btnClass="btn-rosso"
            :onCreate="creaLotti"
          />
          <CreationCard
            lineaText="Bianco"
            linea="bianco"
            btnClass="btn-bianco"
            :onCreate="creaLotti"
          />
          <CreationCard
            lineaText="Rosè"
            linea="rose"
            btnClass="btn-rose"
            :onCreate="creaLotti"
          />
        </div>
      </section>

      <section class="card processes-section">
        <div class="card-title"><h2>Processi Attivi in Blockchain</h2></div>
        
        <div v-if="loading" class="loading-overlay">
          🚀 Comunicazione con Blockchain in corso... Conferma su MetaMask.
        </div>
        
        <ProcessTable
          :lotti="lotti"
          :getStatusLabel="getStatusLabel"
          :getProgressWidth="getProgressWidth"
          :avanza="avanzaStato"
        />
      </section>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, inject } from "vue";
import CreationCard from "../components/CreationCard.vue";
import ProcessTable from "../components/ProcessTable.vue";

// Iniezione dati globali da App.vue
const userAddress = inject("userAddress");
const contractInstance = inject("contractInstance");

const lotti = ref([]);
const loading = ref(false);

// 1. Etichette aggiornate per il flusso completo
const getStatusLabel = (stato) => {
  const labels = {
    creato: "In Attesa",
    vendemmiato: "Vendemmiato",
    fermentato: "Fermentato",
    affinato: "Affinamento",
    imbottigliato: "Imbottigliato",
    distribuito: "Distribuito"
  };
  return labels[stato] || "Sconosciuto";
};

// 2. Barra di progresso ricalibrata su 6 stati
const getProgressWidth = (stato) => {
  const widths = { 
    creato: "16%", 
    vendemmiato: "32%", 
    fermentato: "48%", 
    affinato: "64%", 
    imbottigliato: "80%", 
    distribuito: "100%" 
  };
  return widths[stato] || "0%";
};

// CARICAMENTO LOTTI
const loadLotti = async () => {
  if (!contractInstance.value) return;
  try {
    const data = await contractInstance.value.methods.getLotti().call();
    lotti.value = data.map((l, index) => ({
      blockchainIndex: index,
      id: l.id.toString(),
      tipo: l.tipo,
      // DEVE ESSERE ESATTAMENTE QUESTO ORDINE DI 6 ELEMENTI:
      stato: ["creato", "vendemmiato", "fermentato", "affinato", "imbottigliato", "distribuito"][parseInt(l.stato)],
    }));
  } catch (err) {
    console.error("Errore caricamento lotti:", err);
  }
};

// CREAZIONE LOTTI
const creaLotti = async (tipo, quantita) => {
  if (!contractInstance.value || !userAddress.value) {
    alert("Errore: Connessione al contratto non riuscita.");
    return;
  }
  
  loading.value = true;
  try {
    for (let i = 0; i < quantita; i++) {
      await contractInstance.value.methods
        .creaLotto(tipo)
        .send({ from: userAddress.value });
    }
    await loadLotti();
  } catch (err) {
    console.error("Errore creazione:", err);
    alert("Transazione annullata.");
  } finally {
    loading.value = false;
  }
};

// AVANZAMENTO STATO (Funzione generica che fa avanzare l'Enum)
const avanzaStato = async (lotto) => {
  if (!contractInstance.value || !userAddress.value) return;
  
  loading.value = true;
  try {
    await contractInstance.value.methods
      .avanzaStato(lotto.blockchainIndex)
      .send({ from: userAddress.value });
    await loadLotti();
  } catch (err) {
    console.error("Errore avanzamento:", err);
    alert("Errore durante l'aggiornamento dello stato.");
  } finally {
    loading.value = false;
  }
};

// Monitoraggio istanza contratto
watch(
  () => contractInstance.value,
  (newVal) => {
    if (newVal) loadLotti();
  },
  { immediate: true }
);

onMounted(() => {
  if (contractInstance.value) loadLotti();
});
</script>

<style scoped>
:global(html), :global(body) {
  margin: 0;
  padding: 0;
  overflow-y: auto !important;
  height: auto !important;
}

.producer-page-wrapper {
  width: 100%;
  background-color: var(--color-bg);
}

.dashboard-main {
  max-width: 1200px;
  margin: 5px auto 0;
  padding: 0 20px 100px;
  position: relative;
}

.creation-grid {
  display: flex;
  gap: 25px;
  flex-wrap: wrap;
}

.card-title {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 15px;
  margin-bottom: 25px;
  border-bottom: 2px solid var(--color-grigio-chiaro);
  padding-bottom: 15px;
}

.card-title h2 {
  margin: 0;
  text-align: center;
  font-size: 1.8rem;
  color: var(--color-text-dark);
}

.loading-overlay {
  text-align: center;
  padding: 12px;
  background: var(--color-overlay-giallo, #fff3cd);
  color: #856404;
  border: 1px solid #ffeeba;
  border-radius: 8px;
  margin-bottom: 20px;
  font-weight: bold;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% { opacity: 1; }
  50% { opacity: 0.7; }
  100% { opacity: 1; }
}
</style>