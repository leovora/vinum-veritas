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

        <template v-for="lotto in lotti" :key="lotto.id">
          <tr 
            v-if="lotto.stato !== 'revisione' || userRole === 'ADMIN'"
            :class="{ 'row-revisione': lotto.stato === 'revisione' }"
          >
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
                  {{ lotto.stato === 'revisione' ? 'Bloccato' : STATUS_LABELS[lotto.stato] }}
                </span>

                <div v-if="lotto.stato === 'revisione'" class="postit-container">
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
                
                <template v-if="lotto.stato !== 'revisione'">
                  <button
                    v-for="step in STEPS"
                    :key="step.label"
                    class="btn-step"
                    :disabled="!canAdvance(step, lotto)"
                    @click="handleAdvance(lotto)"
                  >
                    {{ step.icon }} {{ step.label }}
                  </button>

                  <template v-for="step in STEPS" :key="'fail-' + step.label">
                    <button
                      v-if="userRole !== 'ADMIN' && canAdvance(step, lotto)"
                      class="btn-fail"
                      @click="handleFail(lotto)"
                    >
                      ⚠️ Segnala
                    </button>
                  </template>
                </template>

                <template v-else-if="userRole === 'ADMIN'">
                  <button class="btn-approve" @click="handleRiabilita(lotto)">
                    ✅ Sblocca
                  </button>
                  <button class="btn-delete" @click="$emit('elimina', lotto)">
                    🗑️ Elimina
                  </button>
                </template>

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
import { onMounted } from "vue";
import IspezionaButton from "./IspezionaButton.vue";

const emit = defineEmits(["elimina", "fallimento", "riabilita"]);

const props = defineProps({
  lotti: { type: Array, required: true },
  userRole: { type: String, required: true },
  avanza: { type: Function, default: null },
});

onMounted(() => {
  console.log("Tabella Processi: Filtro di sicurezza ADMIN attivato");
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

// In ProcessTable.vue
const getMotivazioneCompleta = (lotto) => {
  // Se abbiamo già estratto la motivazione nel mapping, usiamo quella
  if (lotto.motivazione) return lotto.motivazione;
  
  // Altrimenti cerchiamo nell'array originale (se presente)
  const arrayRicerca = lotto.luoghiOriginali || lotto.luoghi;
  const entry = arrayRicerca.findLast(l => l.includes("PROBLEMA:"));
  return entry ? entry.replace("PROBLEMA: ", "") : "Nessun dettaglio fornito.";
};

const getProgressWidth = (stato) => PROGRESS[stato] || "0%";

const badgeClass = (tipo) =>
  tipo.includes("Rosso") ? "b-rosso" : tipo.includes("Bianco") ? "b-bianco" : "b-rosa";

const canAdvance = (step, lotto) => {
  return lotto.stato !== 'revisione' && 
         lotto.stato === step.stato && 
         props.userRole === step.role;
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
</script>

<style scoped>
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
  background-color: black; 
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
  box-shadow: 0 8px 15px rgba(0,0,0,0.3);
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

.row-revisione td {
  background-color: #fff5f5 !important;
}

.status-pill {
  padding: 6px 14px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 800;
  text-transform: uppercase;
}

.revisione {
  background: #d63031;
  color: white;
}

.btn-fail {
  background: none;
  border: 1px solid #e17055;
  color: #e17055;
  padding: 6px 12px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 700;
  font-size: 0.75rem;
}

.btn-fail:hover {
  background: #e17055;
  color: white;
}

.btn-approve {
  background: #00b894;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 700;
}
.btn-approve:hover { color: black; background: #55efc4; }

.btn-delete {
  background: #d63031;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 700;
}
.btn-delete:hover { background: #ff7675; }

.btn-group { display: flex; justify-content: center; gap: 10px; flex-wrap: wrap; align-items: center; }

.btn-step {
  display: flex;
  align-items: center;
  gap: 6px;
  background: white;
  border: 1.5px solid #800020;
  color: #800020;
  padding: 8px 14px;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 700;
  font-size: 0.85rem;
}

.lock-msg {
  background: #2d3436;
  color: white;
  padding: 8px 12px;
  border-radius: 6px;
  font-size: 0.8rem;
  font-weight: bold;
}

.btn-step:disabled { display: none; }
.btn-step:hover { background: #800020; color: white; }

.process-table { width: 100%; border-collapse: separate; border-spacing: 0 10px; }
.process-table td { padding: 14px; background: white; border-top: 1px solid #eee; border-bottom: 1px solid #eee; text-align: center; vertical-align: middle; }

.empty-msg { padding: 40px !important; color: #999; font-style: italic; }

/* Badge colors */
.badge { padding: 4px 8px; border-radius: 4px; font-size: 0.7rem; font-weight: bold; text-transform: uppercase; margin-bottom: 8px; display: inline-block; }
.b-rosso { background: #ff7675; color: white; }
.b-bianco { background: #dfe6e9; color: #2d3436; border: 1px solid #b2bec3; }
.b-rosa { background: #fd79a8; color: white; }

.type-progress-col { display: flex; flex-direction: column; align-items: center; }
.progress-container { width: 100px; height: 6px; background: #eee; border-radius: 10px; overflow: hidden; }
.progress-bar { height: 100%; background: #00b894; transition: width 0.3s ease; }
</style>