<template>
  <div class="producer-page-wrapper">
    <div class="user-status-bar" v-if="userRole">
        Loggato come: <strong>{{ userRole }}</strong>
      </div>
    <main class="dashboard-main">
      
      <section v-if="userRole === 'ADMIN'" class="card creation-section">
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
        <div class="card-title">
          <h2>{{ userRole === 'ADMIN' ? 'Tutti i Processi Blockchain' : 'Le Mie Attività' }}</h2>
        </div>
        
        <div v-if="loading" class="loading-overlay">
           Comunicazione con Blockchain in corso... Conferma su MetaMask.
        </div>
        
        <ProcessTable
          :lotti="filteredLotti"
          :userRole="userRole"
          :getStatusLabel="getStatusLabel"
          :getProgressWidth="getProgressWidth"
          :avanza="avanzaStato"
          @elimina="handleEliminaLotto"
        />
      </section>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, inject, computed } from "vue";
import Web3 from "web3";
import CreationCard from "../components/CreationCard.vue";
import ProcessTable from "../components/ProcessTable.vue";

const userAddress = inject("userAddress");
const contractInstance = inject("contractInstance");
const isReady = ref(false)
const lotti = ref([]);
const loading = ref(false);
const userRole = ref("");

const filteredLotti = computed(() => {
  if (userRole.value === 'ADMIN') return lotti.value;
  return lotti.value.filter(lotto => {
    if (userRole.value === 'AGRICOLTORE') return lotto.stato === 'creato';
    if (userRole.value === 'SUPERVISORE') return lotto.stato === 'vendemmiato' || lotto.stato === 'fermentato';
    if (userRole.value === 'CANTINIERE') return lotto.stato === 'affinato';
    if (userRole.value === 'CORRIERE') return lotto.stato === 'imbottigliato';
    if (userRole.value === 'DISTRIBUTORE') return lotto.stato === 'distribuito';
    return false;
  });
});

const getStatusLabel = (stato) => {
  const labels = {
    creato: "In Attesa", vendemmiato: "Vendemmiato", fermentato: "Fermentato",
    affinato: "Affinamento", imbottigliato: "Imbottigliato", distribuito: "Distribuito"
  };
  return labels[stato] || "Sconosciuto";
};

const getProgressWidth = (stato) => {
  const widths = { 
    creato: "16%", vendemmiato: "32%", fermentato: "48%", 
    affinato: "64%", imbottigliato: "80%", distribuito: "100%" 
  };
  return widths[stato] || "0%";
};

const checkRole = async () => {
  if (contractInstance.value && userAddress.value) {
    try {
      const roleHash = await contractInstance.value.methods.roles(userAddress.value).call();
      if (roleHash === "0x0000000000000000000000000000000000000000000000000000000000000000") {
        userRole.value = "VISITATORE";
        return;
      }
      const rolesMap = {
        [Web3.utils.keccak256("ADMIN")]: "ADMIN",
        [Web3.utils.keccak256("AGRICOLTORE")]: "AGRICOLTORE",
        [Web3.utils.keccak256("SUPERVISORE")]: "SUPERVISORE",
        [Web3.utils.keccak256("CANTINIERE")]: "CANTINIERE",
        [Web3.utils.keccak256("CORRIERE")]: "CORRIERE",
        [Web3.utils.keccak256("DISTRIBUTORE")]: "DISTRIBUTORE"
      };
      userRole.value = rolesMap[roleHash] || "VISITATORE";
    } catch (err) { console.error(err); }
  }
};

const loadLotti = async () => {
  if (!contractInstance.value) return;
  try {
    const data = await contractInstance.value.methods.getLotti().call();
    lotti.value = data.map((l, index) => ({
      blockchainIndex: index,
      id: l.id.toString(),
      tipo: l.tipo,
      stato: ["creato", "vendemmiato", "fermentato", "affinato", "imbottigliato", "distribuito"][parseInt(l.stato)],
    }));
  } catch (err) { console.error(err); }
};

const handleEliminaLotto = async (lotto) => {
  if (!contractInstance.value || userRole.value !== 'ADMIN') return;
  if (!confirm("Sei sicuro di voler eliminare definitivamente questo lotto?")) return;
  loading.value = true;
  try {
    await contractInstance.value.methods
      .eliminaLotto(lotto.blockchainIndex)
      .send({ from: userAddress.value });
    
    // Attesa per permettere a Ganache di aggiornare lo stato
    setTimeout(async () => { await loadLotti(); }, 500);
  } catch (err) {
    console.error(err);
    alert("Errore eliminazione.");
  } finally { loading.value = false; }
};

const creaLotti = async (tipo, quantita) => {
  if (!contractInstance.value || !userAddress.value) return;
  loading.value = true;
  try {
    for (let i = 0; i < quantita; i++) {
      await contractInstance.value.methods.creaLotto(tipo).send({ from: userAddress.value });
    }
    setTimeout(async () => { await loadLotti(); }, 500);
  } catch (err) { console.error(err); } finally { loading.value = false; }
};

const avanzaStato = async (lotto) => {
  if (!contractInstance.value || !userAddress.value) return;
  loading.value = true;
  try {
    await contractInstance.value.methods.avanzaStato(lotto.blockchainIndex).send({ from: userAddress.value });
    setTimeout(async () => { await loadLotti(); }, 500);
  } catch (err) { alert("Azione non permessa."); } finally { loading.value = false; }
};

const initDashboard = async () => {
  if (!contractInstance.value || !userAddress.value) return;
  
  try {
    isReady.value = false;
    // 1. Aspettiamo il ruolo (fondamentale per il filtro)
    await checkRole();
    // 2. Aspettiamo il caricamento dati
    await loadLotti();
    // 3. Ora la dashboard è pronta
    isReady.value = true;
  } catch (err) {
    console.error("Errore inizializzazione:", err);
  }
};

// Usa il watcher per reagire ai cambi di account o contratto
watch(
  [() => contractInstance.value, () => userAddress.value],
  async ([newContract, newAddr]) => {
    if (newContract && newAddr) {
      await initDashboard();
    }
  },
  { immediate: true }
);
</script>
<style scoped>
:global(html), :global(body) { margin: 0; padding: 0; overflow-y: auto !important; height: auto !important; }  
.user-status-bar { background: #333; color: #fff; padding: 10px 20px; border-radius: 8px; margin-bottom: 20px; text-align: center; font-size: 0.9rem; margin-right:-10px; margin-left:-10px; }
.producer-page-wrapper { width: 100%; background-color: var(--color-bg); }
.dashboard-main { max-width: 1200px; margin: 5px auto 0; padding: 0 20px 100px; position: relative; }
.creation-grid { display: flex; gap: 25px; flex-wrap: wrap; }
.card-title { display: flex; align-items: center; justify-content: center; gap: 15px; margin-bottom: 25px; border-bottom: 2px solid var(--color-grigio-chiaro); padding-bottom: 15px; }
.card-title h2 { margin: 0; text-align: center; font-size: 1.8rem; color: var(--color-text-dark); }
.loading-overlay { text-align: center; padding: 12px; background: #fff3cd; color: #856404; border: 1px solid #ffeeba; border-radius: 8px; margin-bottom: 20px; font-weight: bold; animation: pulse 2s infinite; }
@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.7; } 100% { opacity: 1; } }
</style>