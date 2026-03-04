<template>
  <div class="process-table-container">
    <table class="process-table">
      <thead>
        <tr>
          <th>ID Lotto</th>
          <th>Tipologia e progresso</th>
          <th>Stato</th>
          <th></th>
        </tr>
      </thead>

      <tbody>
        <tr v-if="visibleLotti.length === 0">
          <td colspan="4" class="empty-msg">Nessun lotto presente.</td>
        </tr>

        <template v-for="lotto in visibleLotti" :key="lotto.id">
          <tr :class="{ 'row-revisione': lotto.inRevisione }">
            <td class="id-cell">#{{ lotto.id }}</td>

            <td>
              <div class="type-progress-col">
                <span :class="['badge', badgeClass(lotto.tipo)]">
                  {{ lotto.tipo }}
                </span>

                <div class="progress-container">
                  <div
                    class="progress-bar"
                    :style="{ width: getProgressWidth(lotto.stato) }"
                  ></div>
                </div>
              </div>
            </td>

            <td>
              <div class="status-flex-container">
                <span :class="['status-pill', lotto.stato]">
                  {{ lotto.inRevisione ? 'Bloccato' : STATUS_LABELS[lotto.stato] }}
                </span>
                <div v-if="lotto.inRevisione" class="postit-container">
                  <div class="postit-circle-icon">?</div>
                  <div class="postit-tooltip">
                    <p class="tooltip-title">Nota di segnalazione:</p>
                    <p class="tooltip-text">{{ getMotivazioneCompleta(lotto) }}</p>
                  </div>
                </div>
              </div>
            </td>

            <td class="actions-cell">
              <div class="btn-group">
                
                <!-- Pulsanti sequenziali -->
                <template v-if="!lotto.inRevisione">
                  <button
                    v-for="step in STEPS"
                    :key="step.label"
                    class="btn-step"
                    :disabled="!canAdvance(step, lotto)"
                    @click="handleAdvance(lotto)"
                  >
                    {{ step.icon }} {{ step.label }}
                  </button>

                  <!-- Segnala solo se utente non Admin -->
                  <button
                    v-if="userRole !== 'ADMIN'"
                    class="btn-fail"
                    @click="handleFail(lotto)"
                  >
                    ⚠️ Segnala
                  </button>
                </template>

                <!-- Pulsanti Admin su lotto bloccato -->
                <template v-else-if="userRole === 'ADMIN'">
                  <button class="btn-approve" @click="handleRiabilita(lotto)">
                    ✅ Sblocca
                  </button>
                  <button class="btn-delete" @click="$emit('elimina', lotto)">
                    🗑️ Elimina
                  </button>
                </template>

                <!-- Messaggio blocco per altri ruoli -->
                <span v-else class="lock-msg">
                  🔒 In revisione
                </span>

                <IspezionaButton :lotto="lotto" />
              </div>
            </td>          
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>

<script setup>
import { computed } from "vue";
import IspezionaButton from "./IspezionaButton.vue";
import { useUserStore } from "../stores/user";

const emit = defineEmits(["elimina", "fallimento", "riabilita"]);

const userStore = useUserStore();
const userRole = computed(() => userStore.role?.toUpperCase());
const userAddress = computed(() => userStore.account);

const props = defineProps({
  lotti: { type: Array, required: true },
  userRole: { type: String, required: true },
  avanza: { type: Function, default: null },
});

const STATUS_LABELS = {
  creato: "In attesa",
  vendemmiato: "Vendemmiato",
  fermentato: "Fermentato",
  affinato: "Affinato",
  imbottigliato: "Imbottigliato",
  spedito: "Spedito",
  distribuito: "Ricevuto",
  revisione: "In Revisione",
};

const PROGRESS = {
  creato: "14%",
  vendemmiato: "28%",
  fermentato: "42%",
  affinato: "56%",
  imbottigliato: "70%",
  spedito: "85%",
  distribuito: "100%",
  revisione: "100%",
};

const STEPS = [
  { stato: "creato", role: "AGRICOLTORE", label: "Vendemmia", icon: "🍇" },
  { stato: "vendemmiato", role: "SUPERVISORE", label: "Fermentazione", icon: "🧪" },
  { stato: "fermentato", role: "SUPERVISORE", label: "Affinamento", icon: "🏺" },
  { stato: "affinato", role: "CANTINIERE", label: "Imbottigliamento", icon: "🍾" },
  { stato: "imbottigliato", role: "CORRIERE", label: "Spedizione", icon: "🚚" },
  { stato: "spedito", role: "DISTRIBUTORE", label: "Ricezione", icon: "🏢" },
];

const getMotivazioneCompleta = (lotto) => {
  if (lotto.motivazione) return lotto.motivazione;
  return "Nessun dettaglio fornito.";
};

const getProgressWidth = (stato) => PROGRESS[stato] || "0%";

const badgeClass = (tipo) =>
  tipo.includes("Rosso") ? "b-rosso" : tipo.includes("Bianco") ? "b-bianco" : "b-rosa";

const canAdvance = (step, lotto) => {
  if (lotto.inRevisione) return false;
  return lotto.stato === step.stato && props.userRole === step.role;
};

const handleAdvance = (lotto) => {
  if (props.avanza) props.avanza(lotto);
};

const handleFail = (lotto) => {
  const motivazione = prompt("Descrivi il problema per il lotto #" + lotto.id + ":");
  if (motivazione && motivazione.trim() !== "") {
    emit('fallimento', { lotto, motivazione }); 
  }
};

const handleRiabilita = (lotto) => {
  emit('riabilita', lotto);
};

const visibleLotti = computed(() => {
  return props.lotti.filter(lotto => {

    if (lotto.statoControllo === "eliminato") return false;
    if (lotto.statoRaw === 6) return false;
    if (lotto.inRevisione) {
      return userRole.value === "ADMIN" || userAddress.value === lotto.segnalatore;
    }

    return true;
  });
});

</script>

<style scoped>

.process-table-container {
  overflow-x: auto;
  padding: 10px;
}

.process-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0 10px;
}

.process-table th {
  text-align: center;
  padding: 15px;
  color: #666;
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.process-table td {
  padding: 15px;
  background: white;
  border-top: 1px solid #eee;
  border-bottom: 1px solid #eee;
  text-align: center;
  vertical-align: middle;
}

.process-table td:first-child {
  border-left: 1px solid #eee;
  border-radius: 10px 0 0 10px;
}

.process-table td:last-child {
  border-right: 1px solid #eee;
  border-radius: 0 10px 10px 0;
}

.row-revisione td {
  background-color: #fff5f5 !important;
}

.badge {
  padding: 5px 12px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: bold;
  color: white;
  text-transform: uppercase;
  display: inline-block;
}

.b-rosso  { background: #b22222; }
.b-bianco { background: #f4d03f; color: #2d3436; }
.b-rosa   { background: #db7093; }


.type-progress-col {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.progress-container {
  width: 100px;
  height: 6px;
  background: #eee;
  border-radius: 10px;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background: #800020;
  transition: width 0.4s ease;
}

.status-pill {
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 0.8rem;
  font-weight: bold;
  display: inline-block;
  min-width: 110px;
}

.creato       { background: #f8f9fa; color: #6c757d;  border: 1px solid #dee2e6; }
.vendemmiato  { background: #e6fffa; color: #2d3748;  border: 1px solid #b2f5ea; }
.fermentato   { background: #ebf8ff; color: #2b6cb0;  border: 1px solid #bee3f8; }
.affinato     { background: #fffaf0; color: #9c4221;  border: 1px solid #feebc8; }
.imbottigliato{ background: #f7fafc; color: #2d3748;  border: 1px solid #edf2f7; }
.spedito      { background: #faf5ff; color: #5a4687;  border: 1px solid #e2c8ff; }
.distribuito  { background: #faf5ff; color: #6b46c1;  border: 1px solid #e9d8fd; }

.revisione {
  background: #d63031;
  color: white;
  border-radius: 20px;
  text-transform: uppercase;
  font-size: 0.75rem;
  font-weight: 800;
}

.status-flex-container {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
}

.postit-container {
  position: relative;
  display: flex;
  align-items: center;
}

.postit-circle-icon {
  width: 22px;
  height: 22px;
  background-color: #800020;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: bold;
  cursor: help;
}

.postit-tooltip {
  visibility: hidden;
  opacity: 0;
  position: absolute;
  bottom: 140%;
  left: 50%;
  transform: translateX(-50%);
  background-color: #2d3436;
  color: #fff;
  text-align: left;
  padding: 12px;
  border-radius: 8px;
  width: 240px;
  z-index: 100;
  box-shadow: 0 8px 15px rgba(0, 0, 0, 0.3);
  transition: opacity 0.3s, visibility 0.3s;
  pointer-events: none;
}

.postit-tooltip::after {
  content: "";
  position: absolute;
  top: 100%;
  left: 50%;
  margin-left: -6px;
  border-width: 6px;
  border-style: solid;
  border-color: #2d3436 transparent transparent transparent;
}

.postit-container:hover .postit-tooltip {
  visibility: visible;
  opacity: 1;
}

.tooltip-title {
  font-size: 0.7rem;
  font-weight: bold;
  text-transform: uppercase;
  color: #fab1a0;
  margin-bottom: 6px;
  letter-spacing: 0.5px;
}

.tooltip-text {
  font-size: 0.85rem;
  line-height: 1.4;
  margin: 0;
  word-wrap: break-word;
}

.btn-group {
  display: flex;
  justify-content: center;
  gap: 8px;
  flex-wrap: wrap;
  align-items: center;
}

.btn-step {
  display: flex;
  align-items: center;
  gap: 5px;
  background: white;
  border: 1.5px solid #800020;
  color: #800020;
  padding: 8px 12px;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  font-size: 0.85rem;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.btn-step:disabled {
  display: none;
}

.btn-step:hover:not(:disabled) {
  background: #800020;
  color: white;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.btn-delete {
  background: #ff4757;
  color: white;
  border: none;
  padding: 8px 12px;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  font-size: 0.85rem;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  gap: 5px;
}

.btn-delete:hover {
  background: #ff6b81;
  transform: translateY(-1px);
}

.btn-fail {
  background: none;
  border: 1.5px solid #e17055;
  color: #e17055;
  padding: 8px 12px;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  font-size: 0.85rem;
  transition: all 0.2s ease;
}

.btn-fail:hover {
  background: #e17055;
  color: white;
}

.btn-approve {
  background: #00b894;
  color: white;
  border: none;
  padding: 8px 12px;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  font-size: 0.85rem;
  transition: all 0.2s ease;
}

.btn-approve:hover {
  background: #55efc4;
  color: #2d3436;
}

.lock-msg {
  background: #2d3436;
  color: white;
  padding: 8px 12px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: bold;
}

.empty-msg {
  text-align: center;
  padding: 30px;
  color: #888;
  font-style: italic;
}
</style>