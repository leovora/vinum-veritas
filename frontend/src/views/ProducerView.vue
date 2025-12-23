<template>
  <div class="producer-page-wrapper">
    <AppHeader />

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
import { ref, onMounted, watch } from "vue";
import AppHeader from "../components/AppHeader.vue";
import CreationCard from "../components/CreationCard.vue";
import ProcessTable from "../components/ProcessTable.vue";


const props = defineProps({
  userAddress: String,
  contractInstance: Object,
});

const lotti = ref([]);
const loading = ref(false);

const getStatusLabel = (stato) => {
  const labels = {
    creato: "In Attesa",
    vendemmiato: "Vendemmiato",
    fermentato: "Fermentato",
  };
  return labels[stato] || "Sconosciuto";
};

const getProgressWidth = (stato) => {
  const widths = { creato: "33%", vendemmiato: "66%", fermentato: "100%" };
  return widths[stato] || "0%";
};

const loadLotti = async () => {
  if (!props.contractInstance) return;
  try {
    const data = await props.contractInstance.methods.getLotti().call();
    lotti.value = data.map((l, index) => ({
      blockchainIndex: index,
      id: l.id.toString(),
      tipo: l.tipo,
      stato: ["creato", "vendemmiato", "fermentato"][parseInt(l.stato)],
    }));
  } catch (err) {
    console.error(err);
  }
};

const creaLotti = async (tipo, quantita) => {
  if (!props.contractInstance || !props.userAddress) return;
  loading.value = true;
  try {
    for (let i = 0; i < quantita; i++) {
      await props.contractInstance.methods
        .creaLotto(tipo)
        .send({ from: props.userAddress });
    }
  } catch (err) {
    console.error(err);
    alert("Errore creazione");
  } finally {
    loading.value = false;
    await loadLotti();
  }
};

const avanzaStato = async (lotto) => {
  if (!props.contractInstance) return;
  loading.value = true;
  try {
    await props.contractInstance.methods
      .avanzaStato(lotto.blockchainIndex)
      .send({ from: props.userAddress });
  } catch (err) {
    console.error(err);
    alert("Errore avanzamento");
  } finally {
    loading.value = false;
    await loadLotti();
  }
};

watch(
  () => props.contractInstance,
  (newVal) => {
    if (newVal) loadLotti();
  },
  { immediate: true }
);
onMounted(() => {
  if (props.contractInstance) loadLotti();
});
</script>

<style scoped>

:global(html), :global(body) {
  margin: 0;
  padding: 0;
  overflow-y: auto !important; /* Forza lo scroll verticale */
  height: auto !important;
}

.producer-page-wrapper {
  width: 100%;
  background-color: var(--color-bg);
}

.dashboard-main {
  max-width: 1200px;
  margin: -40px auto 0;
  padding: 0 20px 100px;
  position: relative;
}

.creation-grid {
  display: flex;
  gap: 25px;
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

</style>
