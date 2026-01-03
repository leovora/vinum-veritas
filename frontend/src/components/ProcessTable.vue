<template>
  <div class="process-table-container">
    <table class="process-table">
      <thead>
        <tr>
          <th>ID Lotto</th>
          <th>Tipologia / Progresso</th>
          <th>Stato Attuale</th>
          <th>Azioni Sequenziali</th>
        </tr>
      </thead>

      <tbody>
        <tr v-if="lotti.length === 0">
          <td colspan="4" class="empty-msg">Nessun lotto presente.</td>
        </tr>

        <tr v-for="lotto in lotti" :key="lotto.id">
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
            <span :class="['status-pill', lotto.stato]">
              {{ getStatusLabel(lotto.stato) }}
            </span>
          </td>

          <td class="actions-cell">
            <div class="btn-group">
              <button
                v-for="step in STEPS"
                :key="step.label"
                class="btn-step"
                :disabled="!canAdvance(step, lotto)"
                @click="handleAdvance(lotto)"
              >
                {{ step.icon }} {{ step.label }}
              </button>

              <button
                v-if="userRole === 'ADMIN'"
                class="btn-delete"
                @click="$emit('elimina', lotto)"
              >
                🗑️ Elimina
              </button>

              <IspezionaButton :lotto="lotto" />
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
import IspezionaButton from "./IspezionaButton.vue";

defineEmits(["elimina"]);

const props = defineProps({
  lotti: { type: Array, required: true },
  userRole: { type: String, required: true },
  avanza: { type: Function, default: null },
});

/* =========================
   STATO → LABEL UI
========================= */
const STATUS_LABELS = {
  creato: "In attesa di vendemmia",
  vendemmiato: "Vendemmiato",
  fermentato: "Fermentato",
  affinato: "Affinato",
  imbottigliato: "Imbottigliato",
  spedito: "Spedito",
  distribuito: "Ricezione confermata",
};

/* =========================
   PROGRESS
========================= */
const PROGRESS = {
  creato: "14%",
  vendemmiato: "28%",
  fermentato: "42%",
  affinato: "56%",
  imbottigliato: "70%",
  spedito: "85%",
  distribuito: "100%",
};

/* =========================
   STEP OPERATIVI
========================= */
const STEPS = [
  { stato: "creato", role: "AGRICOLTORE", label: "Vendemmia", icon: "🍇" },
  { stato: "vendemmiato", role: "SUPERVISORE", label: "Fermentazione", icon: "🧪" },
  { stato: "fermentato", role: "SUPERVISORE", label: "Affinamento", icon: "🏺" },
  { stato: "affinato", role: "CANTINIERE", label: "Imbottigliamento", icon: "🍾" },
  { stato: "imbottigliato", role: "CORRIERE", label: "Spedizione", icon: "🚚" },
  { stato: "spedito", role: "DISTRIBUTORE", label: "Conferma ricezione", icon: "🏢" },
];

/* =========================
   UI HELPERS
========================= */
const getStatusLabel = (stato) => STATUS_LABELS[stato] || "Sconosciuto";
const getProgressWidth = (stato) => PROGRESS[stato] || "0%";

const badgeClass = (tipo) =>
  tipo.includes("Rosso")
    ? "b-rosso"
    : tipo.includes("Bianco")
    ? "b-bianco"
    : "b-rosa";

/* =========================
   ABILITAZIONE AZIONI
========================= */
const canAdvance = (step, lotto) =>
  !!props.avanza &&
  lotto.stato === step.stato &&
  props.userRole === step.role;

const handleAdvance = (lotto) => {
  if (props.avanza) props.avanza(lotto);
};
</script>

<style scoped>

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

.empty-msg {
  text-align: center;
  padding: 30px;
  color: #888;
  font-style: italic;
}

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
}
.process-table td:first-child {
  border-left: 1px solid #eee;
  border-radius: 10px 0 0 10px;
}
.process-table td:last-child {
  border-right: 1px solid #eee;
  border-radius: 0 10px 10px 0;
}
.badge {
  padding: 5px 12px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: bold;
  color: white;
}
.b-rosso {
  background: #b22222;
}
.b-bianco {
  background: #f4d03f;
}
.b-rosa {
  background: #db7093;
}
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
.creato { background: #f8f9fa; color: #6c757d; border: 1px solid #dee2e6; }
.vendemmiato { background: #e6fffa; color: #2d3748; border: 1px solid #b2f5ea; }
.fermentato { background: #ebf8ff; color: #2b6cb0; border: 1px solid #bee3f8; }
.affinato { background: #fffaf0; color: #9c4221; border: 1px solid #feebc8; }
.imbottigliato { background: #f7fafc; color: #2d3748; border: 1px solid #edf2f7; }
.distribuito { background: #faf5ff; color: #6b46c1; border: 1px solid #e9d8fd; }
.spedito { background: #faf5ff; color: #5a4687; border: 1px solid #e2c8ff; }
.btn-group {
  display: flex;
  justify-content: center;
  gap: 8px;
  flex-wrap: wrap;
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
</style>
