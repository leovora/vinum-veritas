<template>
  <div class="producer-page-wrapper">
    <UserStatusBar :role="userRole" />

    <main class="dashboard-main">

      <section v-if="userRole === 'ADMIN'" class="card creation-section">
        <div class="card-title">
          <h2>Configurazione Nuova Produzione</h2>
        </div>
        <div class="creation-grid">
          <CreationCard lineaText="Rosso" linea="rosso" btnClass="btn-rosso" :onCreate="creaLotti" />
          <CreationCard lineaText="Bianco" linea="bianco" btnClass="btn-bianco" :onCreate="creaLotti" />
          <CreationCard lineaText="Rosè" linea="rose" btnClass="btn-rose" :onCreate="creaLotti" />
        </div>
      </section>

      <section class="card processes-section">
        <div class="card-title">
          <h2>{{ userRole === 'ADMIN' ? 'Gestione Processi Blockchain' : 'Stato Globale Filiera' }}</h2>
        </div>

        <div v-if="loading" class="loading-overlay">
          Comunicazione con Blockchain in corso...
        </div>

        <ProcessTable
            v-else
            :lotti="activeLotti"
            :userRole="userRole" 
            :avanza="avanzaStato"
            @elimina="handleEliminaLotto"
            @fallimento="handleFallimentoEvent"
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

const { showToast } = useToast();
const userStore = useUserStore();

// INIEZIONE FUNZIONI DA APP.VUE
const contractInstance = inject("contractInstance");
const onSegnalaProblema = inject("onSegnalaProblema");
const onRiabilitaLotto = inject("onRiabilitaLotto");

const lotti = ref([]);
const loading = ref(false);

const userRole = computed(() => userStore.role?.toUpperCase());
const userAddress = computed(() => userStore.account);


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
        "distribuito",
        "completato"
      ];

      const statoControlloMap = [
        "attivo",
        "revisione"
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

const activeLotti = computed(() => lotti.value.filter(l => l.stato !== "finito"));

/* =========================
   PONTE EVENTI (Tabella -> App.vue)
========================= */
const handleFallimentoEvent = (data) => {
  console.log("ProducerView: Ricevuto segnale di blocco", data);
  if (onSegnalaProblema) onSegnalaProblema(data, loadLotti);
};

const handleRiabilitaEvent = (lotto) => {
  if (onRiabilitaLotto) onRiabilitaLotto(lotto, loadLotti);
};

/* =========================
   AZIONI ADMIN
========================= */
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

// --- Elimina lotto: usa l'ID reale, non blockchainIndex ---
const handleEliminaLotto = async (lotto) => {
  if (userRole.value !== "ADMIN") return;
  if (!confirm("Eliminare definitivamente?")) return;
  loading.value = true;
  try {
    await contractInstance.value.methods.eliminaLotto(lotto.id).send({ from: userAddress.value });
    await loadLotti();
  } finally { loading.value = false; }
};

// --- Avanza stato: usa ID reale e blocco revisione ---
const avanzaStato = async (lotto) => {
  if (userRole.value !== 'ADMIN') return;
  if (lotto.inRevisione) {
    showToast("Lotto in revisione. Impossibile avanzare.", "error");
    return;
  }

  loading.value = true;
  try {
    await contractInstance.value.methods.avanzaStato(lotto.id, "Aggiornamento Admin")
      .send({ from: userAddress.value });
    await loadLotti();
  } catch { showToast("Errore avanzamento", "error"); }
  finally { loading.value = false; }
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