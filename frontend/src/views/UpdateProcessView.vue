<!--
  SupervisorView.vue

  Vista principale per supervisori e operatori della filiera.
  Mostra i processi attivi dei lotti e permette di avanzare
  lo stato dei lotti, segnalare problemi e riabilitare lotti
  bloccati.
-->

<template>
  <div class="producer-page-wrapper">
    <UserStatusBar :role="userRole" />

    <main class="dashboard-main">
      <section class="card processes-section">
        <div class="card-title">
          <h2>Processi attivi</h2>
        </div>

        <div v-if="loading" class="loading-overlay">
          Comunicazione con Blockchain in corso... Conferma su MetaMask.
        </div>

        <ProcessTable
          v-else
          :lotti="filteredLotti"
          :userRole="userRole"
          :avanza="avanzaStato"
          @fallimento="handleFallimentoEvent"
          @riabilita="handleRiabilitaEvent"
        />
      </section>
    </main>
  </div>
</template>

<script setup>
import { ref, watch, computed, inject } from "vue";
import { useUserStore } from "../stores/user";
import ProcessTable from "../components/ProcessTable.vue";
import UserStatusBar from "../components/UserStatusBar.vue";
import { getSimulatedLocation } from "../components/utils/locationSimulator.js";
import { useToast } from "../components/utils/useToast.js";

// Inizializzazione store
const { showToast } = useToast();
const userStore = useUserStore();

// Iniezione dipendenze da App.vue
const contractInstance = inject("contractInstance");
const onSegnalaProblema = inject("onSegnalaProblema");
const onRiabilitaLotto = inject("onRiabilitaLotto");

// Stato locale
const lotti = ref([]);
const loading = ref(false);

const userRole = computed(() => userStore.role);
const userAddress = computed(() => userStore.account);

// Caricamento lotti da smart contract
const loadLotti = async () => {
  if (!contractInstance.value) return;
  loading.value = true;

  try {
    const ids = await contractInstance.value.methods
      .getAllLottoIds()
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

    const lottiCaricati = [];

    for (const id of ids) {
      const lottoData = await contractInstance.value.methods
        .getLotto(id)
        .call();

      const storico = await contractInstance.value.methods
        .getStorico(id)
        .call();

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
    showToast("Impossibile caricare i dati dalla blockchain", "error");
  } finally {
    loading.value = false;
  }
};


// Gestione evento di segnalazione problema
const handleFallimentoEvent = (data) => {
  console.log("VIEW: Ricevuto @fallimento, chiamo onSegnalaProblema");
  if (onSegnalaProblema) onSegnalaProblema(data, loadLotti);
};

// Gestione evento di riabilitazione lotto
const handleRiabilitaEvent = (lotto) => {
  if (onRiabilitaLotto) onRiabilitaLotto(lotto, loadLotti);
};

// Avanzamento dello stato del processo
const avanzaStato = async (lotto) => {
  if (!contractInstance.value) return;

  if (lotto.inRevisione) {
    showToast("Lotto in revisione. Impossibile avanzare.", "error");
    return;
  }

  const luogo = getSimulatedLocation(userRole.value);
  loading.value = true;

  try {
    await contractInstance.value.methods.avanzaStato(lotto.id, luogo)
      .send({ from: userAddress.value });

    await loadLotti();
    showToast("Stato aggiornato con successo!", "success");
  } catch (err) {
    console.error(err);
    showToast("Azione non permessa o annullata", "error");
  } finally {
    loading.value = false;
  }
};

// Filtro dei lotti basato su ruolo utente e stato "inRevisione"
const filteredLotti = computed(() => {
  return lotti.value.filter((lotto) => {
    if (lotto.inRevisione) {
      return userRole.value === 'ADMIN';
    }

    switch (userRole.value) {
      case "AGRICOLTORE": return lotto.stato === "creato";
      case "SUPERVISORE": return ["vendemmiato","fermentato"].includes(lotto.stato);
      case "CANTINIERE": return lotto.stato === "affinato";
      case "CORRIERE": return lotto.stato === "imbottigliato";
      case "DISTRIBUTORE": return lotto.stato === "spedito";
      default: return true;
    }
  });
});

// Watcher per istanza contratto
watch(
  () => contractInstance.value,
  async (val) => {
    if (val) await loadLotti();
  },
  { immediate: true }
);
</script>

<style scoped>
.user-status-bar {
  background: #333;
  color: #fff;
  padding: 10px 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  text-align: center;
  font-size: 0.9rem;
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
}
</style>