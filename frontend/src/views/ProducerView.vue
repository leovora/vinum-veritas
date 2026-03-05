<!--
  ProducerView.vue

  Dashboard principale per la gestione della produzione vinicola.

  Funzionalità principali:
  - Sezione per creare nuovi lotti (Rosso, Bianco, Rosè)
  - Visualizza lotti attivi e relativi stati
  - Permette riabilitazione ed eliminazione
-->

<template>
  <div class="producer-page-wrapper">
    <UserStatusBar :role="userRole" />

    <main class="dashboard-main">
      
      <!-- Sezione creazione lotti: visibile solo ad ADMIN -->
      <section v-if="userRole === 'ADMIN'" class="card creation-section">
        <div class="card-title">
          <h2>Configurazione nuova produzione</h2>
        </div>
        <div class="creation-grid">
          <CreationCard lineaText="Rosso" linea="rosso" btnClass="btn-rosso" :onCreate="creaLotti" />
          <CreationCard lineaText="Bianco" linea="bianco" btnClass="btn-bianco" :onCreate="creaLotti" />
          <CreationCard lineaText="Rosè" linea="rose" btnClass="btn-rose" :onCreate="creaLotti" />
        </div>
      </section>

      <!-- Sezione gestione processi -->
      <section class="card processes-section">
        <div class="card-title">
          <h2>Gestione processi</h2>
        </div>

        <!-- Stato di caricamento durante interazioni con blockchain -->
        <div v-if="loading" class="loading-overlay">
          Comunicazione con Blockchain in corso...
        </div>

         <!-- Tabella dei processi attivi -->
        <ProcessTable
            v-else
            :lotti="activeLotti"
            :userRole="userRole" 
            @elimina="handleEliminaLotto"
            @riabilita="handleRiabilitaEvent"
          />
      </section>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, watch, inject } from "vue";
import { useUserStore } from "../stores/user";
import CreationCard from "../components/CreationCard.vue";
import ProcessTable from "../components/ProcessTable.vue";
import UserStatusBar from "../components/UserStatusBar.vue";
import { useToast } from '../components/utils/useToast.js';

// Store utente e toast
const { showToast } = useToast();
const userStore = useUserStore();

// Iniezione funzioni 
const contractInstance = inject("contractInstance");
const onRiabilitaLotto = inject("onRiabilitaLotto");

// Stati locali
const lotti = ref([]);
const loading = ref(false);

const userRole = computed(() => userStore.role?.toUpperCase());
const userAddress = computed(() => userStore.account);

// Caricamento lotti
const loadLotti = async () => {
  if (!contractInstance.value) return;

  loading.value = true;

  try {
    const ids = await contractInstance.value.methods
      .getAllLottoIds()
      .call();

    const lottiCaricati = [];

    for (const id of ids) {
      const lottoData = await contractInstance.value.methods
        .getLotto(id)
        .call();
      
      console.log("STATO:" + lottoData.stato)

      const storico = await contractInstance.value.methods
        .getStorico(id)
        .call();

      const statoFilieraMap = [
        "creato",
        "vendemmiato",
        "fermentato",
        "affinato",
        "imbottigliato",
        "spedito",
        "distribuito"
      ];

      const statoControlloMap = [
        "attivo",
        "revisione",
        "eliminato"
      ];

      const statoFilieraRaw = Number(lottoData.stato);
      const statoControlloRaw = Number(lottoData.statoControllo);

      lottiCaricati.push({
        id: lottoData.id.toString(),
        tipo: lottoData.tipo,

        stato: statoFilieraMap[statoFilieraRaw],
        statoRaw: statoFilieraRaw,

        statoControllo: statoControlloMap[statoControlloRaw],
        inRevisione: statoControlloRaw === 1,

        motivazione: lottoData.motivoRevisione || null,

        timestamps: storico.map(e => Number(e.timestamp)),
        luoghi: storico.map(e => e.luogo),

        actors: {
          agricoltore: lottoData.agricoltore,
          supervisore: lottoData.supervisore,
          cantiniere: lottoData.cantiniere,
          corriere: lottoData.corriere,
          distributore: lottoData.distributore,
        }
      });
    }

    lotti.value = lottiCaricati;

  } catch (err) {
    console.error("Errore caricamento lotti:", err);
    showToast("Errore sincronizzazione blockchain", "error");
  } finally {
    loading.value = false;
  }
};

// Filtra solo lotti non completati/eliminati
const activeLotti = computed(() => lotti.value.filter(l => l.statoRaw !== 6));

// Emette funzione per riabiliatare lotto
const handleRiabilitaEvent = (lotto) => {
  if (onRiabilitaLotto) onRiabilitaLotto(lotto, loadLotti);
};

// Chiama funzione smart contract per eliminare lotto
const handleEliminaLotto = async (lotto) => {
  try {
    await contractInstance.value.methods
      .eliminaLotto(lotto.id)
      .send({ from: userStore.account });

    showToast("Lotto eliminato con successo", "success");

    // Aggiorna i lotti locali per nascondere quello eliminato
    lotti.value = lotti.value.filter(l => l.id !== lotto.id);
  } catch (err) {
    showToast("Errore eliminazione lotto", "error");
  }
};

// Chiama funzione smart contract per creare nuovo lotto
const creaLotti = async (tipo, quantita, selections) => {
  if (userRole.value !== 'ADMIN') return;
  loading.value = true;
  try {
    for (let i = 0; i < quantita; i++) {
      await contractInstance.value.methods
        .creaLotto(tipo, selections.AGRICOLTORE, selections.SUPERVISORE, selections.CANTINIERE, selections.CORRIERE, selections.DISTRIBUTORE)
        .send({ from: userAddress.value });
    }
    await loadLotti();
    showToast("Lotti creati con successo", "success");
  } catch (err) {
    showToast("Errore creazione", "error");
  } finally { loading.value = false; }
};



watch(() => contractInstance.value, async (val) => {
  if (val) await loadLotti();
}, { immediate: true });
</script>

<style scoped>
:global(html),
:global(body) {
  margin: 0;
  padding: 0;
  overflow-y: auto !important;
  height: auto !important;
}
.user-status-bar {
  background: #333;
  color: #fff;
  padding: 10px 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  text-align: center;
  font-size: 0.9rem;
  margin-right: -10px;
  margin-left: -10px;
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
  align-items: flex-start;
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
  background: #fff3cd;
  color: #856404;
  border: 1px solid #ffeeba;
  border-radius: 8px;
  margin-bottom: 20px;
  font-weight: bold;
  animation: pulse 2s infinite;
}
</style>