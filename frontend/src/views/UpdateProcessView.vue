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

// --- Inizializzazione Store e Servizi ---
const { showToast } = useToast();
const userStore = useUserStore();

// --- Iniezione dipendenze da App.vue ---
const contractInstance = inject("contractInstance");
const onSegnalaProblema = inject("onSegnalaProblema");
const onRiabilitaLotto = inject("onRiabilitaLotto");

// --- Stato Reattivo ---
const lotti = ref([]);
const loading = ref(false);

// --- Proprietà Computate ---
const userRole = computed(() => userStore.role);
const userAddress = computed(() => userStore.account);

/**
 * Mappatura stringa leggibile per lo stato del lotto
 */
const getStatusLabel = (stato) =>
  ({
    creato: "In attesa di vendemmia",
    vendemmiato: "Vendemmiato",
    fermentato: "Fermentato",
    affinato: "Affinato",
    imbottigliato: "Imbottigliato",
    spedito: "Spedito",
    distribuito: "Ricezione confermata",
    revisione: "⚠️ In Revisione",
  }[stato] || "Sconosciuto");

/**
 * Caricamento lotti dal contratto intelligente
 * Logica sincronizzata con HistoryView per evitare sfasamenti tra Fasi e Timestamp
 */
const loadLotti = async () => {
  if (!contractInstance.value) return;
  loading.value = true;
  try {
    const data = await contractInstance.value.methods.getLotti().call();

    lotti.value = data.map((l, index) => {
      const statiMappa = [
        "creato",
        "vendemmiato",
        "fermentato",
        "affinato",
        "imbottigliato",
        "spedito",
        "distribuito",
        "completato",
        "revisione",
      ];

      const rawStato = Number(l.stato);
      const statoStr = statiMappa[rawStato] || "finito";
      const tsArray = l.timestamps?.map((t) => Number(t)) || [];
      const luoghiArray = l.luoghi || [];

      // --- LOGICA DI FILTRAGGIO IDENTICA ALLA HISTORY ---
      const faseTimestamps = [];
      const faseLuoghi = [];

      // Partiamo dall'indice 1 per saltare la creazione tecnica
      // e filtriamo i messaggi tecnici (PROBLEMA / Riabilitato)
      for (let i = 1; i < luoghiArray.length; i++) {
        const luogo = luoghiArray[i];
        
        if (!luogo.includes("PROBLEMA:") && !luogo.includes("Riabilitato")) {
          faseLuoghi.push(luogo);
          faseTimestamps.push(tsArray[i]);
        }
      }

      // IMPORTANTE: statoRaw deve corrispondere al numero di fasi reali salvate
      // se il lotto è completato o in revisione, altrimenti usiamo lo stato numerico
      const statoApparente = rawStato === 8 || rawStato === 7 
        ? faseLuoghi.length 
        : rawStato;

      return {
        blockchainIndex: index,
        id: l.id.toString(),
        tipo: l.tipo,
        stato: statoStr,
        statoRaw: statoApparente, 
        statusLabel: getStatusLabel(statoStr),
        statusClass: `status-${l.stato}`,
        actors: {
          Agricoltore: l.agricoltore,
          Supervisore: l.supervisore,
          Cantiniere: l.cantiniere,
          Corriere: l.corriere,
          Distributore: l.distributore,
        },
        // Inviando gli array filtrati, la LottoCard non avrà più buchi o sfasamenti
        timestamps: faseTimestamps,
        luoghi: faseLuoghi,
        // Dati aggiuntivi per la LottoCard (alert rosso se bloccato)
        statoRawVero: rawStato,
        motivazione: rawStato === 8 ? luoghiArray.findLast(x => x.includes("PROBLEMA:"))?.replace("PROBLEMA: ", "") : null
      };
    });
  } catch (err) {
    console.error("Errore caricamento lotti:", err);
    showToast("Impossibile caricare i dati dalla blockchain", "error");
  } finally {
    loading.value = false;
  }
};

/**
 * Filtro dei lotti in base al ruolo dell'utente loggato
 */
const filteredLotti = computed(() => {
  return lotti.value.filter((lotto) => {
    // Se il lotto è in revisione, è visibile a tutti per trasparenza/blocco
    if (lotto.stato === "revisione") {
      return true;
    }

    switch (userRole.value) {
      case "AGRICOLTORE":
        return lotto.stato === "creato";
      case "SUPERVISORE":
        return ["vendemmiato", "fermentato"].includes(lotto.stato);
      case "CANTINIERE":
        return lotto.stato === "affinato";
      case "CORRIERE":
        return lotto.stato === "imbottigliato";
      case "DISTRIBUTORE":
        return lotto.stato === "spedito";
      default:
        return true;
    }
  });
});

/**
 * Gestione evento di segnalazione problema (da Tabella)
 */
const handleFallimentoEvent = (data) => {
  console.log("VIEW: Ricevuto @fallimento, chiamo onSegnalaProblema");
  if (onSegnalaProblema) onSegnalaProblema(data);
};

/**
 * Gestione evento di riabilitazione lotto (da Tabella)
 */
const handleRiabilitaEvent = (lotto) => {
  if (onRiabilitaLotto) onRiabilitaLotto(lotto);
};

/**
 * Avanzamento dello stato del processo sulla blockchain
 */
const avanzaStato = async (lotto) => {
  if (!contractInstance.value) return;

  const luogo = getSimulatedLocation(userRole.value);
  loading.value = true;

  try {
    await contractInstance.value.methods
      .avanzaStato(lotto.blockchainIndex, luogo)
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

// --- Watcher per istanza contratto ---
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