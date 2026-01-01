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

const userStore = useUserStore();
const contractInstance = inject("contractInstance");

const lotti = ref([]);
const loading = ref(false);

/* =========================
   RUOLO E ACCOUNT
========================= */
const userRole = computed(() => userStore.role);
const userAddress = computed(() => userStore.account);

/* =========================
   UI HELPERS
========================= */
const getStatusLabel = (stato) =>
  ({
    creato: "In attesa di vendemmia",
    vendemmiato: "Vendemmiato",
    fermentato: "Fermentato",
    affinato: "Affinato",
    imbottigliato: "Imbottigliato",
    spedito: "Spedito",
    distribuito: "Ricezione confermata",
  }[stato] || "Sconosciuto");

/* =========================
   LOAD LOTTI COMPLETI
========================= */
const loadLotti = async () => {
  if (!contractInstance.value) return;
  loading.value = true;
  try {
    const data = await contractInstance.value.methods.getLotti().call();

    lotti.value = data.map((l, index) => {
      const statoStr = [
        "creato",
        "vendemmiato",
        "fermentato",
        "affinato",
        "imbottigliato",
        "spedito",
        "distribuito",
      ][Number(l.stato)];

      return {
        blockchainIndex: index,
        id: l.id.toString(),
        tipo: l.tipo,
        stato: statoStr,
        statoRaw: Number(l.stato),
        statusLabel: getStatusLabel(statoStr),
        statusClass: `status-${l.stato}`,
        actors: {
          Agricoltore: l.agricoltore,
          Supervisore: l.supervisore,
          Cantiniere: l.cantiniere,
          Corriere: l.corriere,
          Distributore: l.distributore,
        },
      };
    });
  } catch (err) {
    console.error("Errore caricamento lotti:", err);
  } finally {
    loading.value = false;
  }
};

/* =========================
   FILTRI LOTTI PER RUOLO
========================= */
const filteredLotti = computed(() => {
  return lotti.value.filter((lotto) => {
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
        return true; // VISITATORE o altri ruoli vedono tutto
    }
  });
});

/* =========================
   AVANZAMENTO STATO LOTTO
========================= */
const avanzaStato = async (lotto) => {
  if (!contractInstance.value) return;
  loading.value = true;
  try {
    await contractInstance.value.methods
      .avanzaStato(lotto.blockchainIndex)
      .send({ from: userAddress.value });
    await loadLotti();
  } catch {
    alert("Azione non permessa");
  } finally {
    loading.value = false;
  }
};

/* =========================
   INIT
========================= */
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
