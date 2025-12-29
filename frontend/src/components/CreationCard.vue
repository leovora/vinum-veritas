<template>
  <div class="creation-card" :class="linea">
    <div class="card-header">
      <h3 class="linea-title">Linea {{ lineaText }}</h3>
      <span class="step-indicator">Step {{ currentStep + 1 }} di {{ totalSteps }}</span>
    </div>
    
    <div class="creation-content">
      <transition name="step-fade" mode="out-in">
        
        <div v-if="currentStep < rolesChain.length" :key="currentRole" class="step-container">
          <label class="step-label">Assegna {{ formatLabel(currentRole) }}</label>
          
          <select v-model="selections[currentRole]" class="select-input-large">
            <option value="" disabled>Scegli dalla rubrica...</option>
            <option v-for="user in getUsersByRole(currentRole)" :key="user.address" :value="user.address">
              {{ user.name }}
            </option>
          </select>

          <div class="step-actions">
            <button @click="prevStep" :disabled="currentStep === 0" class="btn-outline">Indietro</button>
            <button @click="nextStep" :disabled="!selections[currentRole]" :class="['btn-next', btnClass]">Avanti</button>
          </div>
        </div>

        <div v-else key="final" class="step-container final-confirmation">
          <label class="step-label">Configurazione Finale</label>
          
          <div class="quantity-selector">
            <input v-model="quantita" type="number" min="1" max="10" class="input-qta">
            <span class="lotti-text">Lotti da creare</span>
          </div>

          <div class="summary-box">
            <p><strong>Verifica Filiera Completa:</strong></p>
            <ul class="summary-list">
              <li v-for="role in rolesChain" :key="role">
                <span class="role-name">{{ formatLabel(role) }}:</span>
                <span class="role-status">{{ selections[role] ? '✅' : '❌' }}</span>
              </li>
            </ul>
          </div>

          <div class="step-actions">
            <button @click="prevStep" class="btn-outline">Modifica</button>
            <button @click="handleCreate" :class="['btn-confirm', btnClass]">Crea Produzione {{ lineaText }}</button>
          </div>
        </div>

      </transition>
    </div>
  </div>
</template>

<script setup>
import { ref, inject, computed } from 'vue';

const props = defineProps({
  lineaText: String,
  linea: String,
  btnClass: String,
  onCreate: Function 
});

const registeredUsers = inject("registeredUsers", ref([]));
const currentStep = ref(0);
const quantita = ref(1);

// TUTTI I RUOLI DEL CONTRATTO
const rolesChain = [
  "AGRICOLTORE", 
  "SUPERVISORE", 
  "CANTINIERE", 
  "CORRIERE", 
  "DISTRIBUTORE"
];

// Inizializzazione dinamica delle selezioni basata sulla lista ruoli
const selections = ref(
  rolesChain.reduce((acc, role) => {
    acc[role] = "";
    return acc;
  }, {})
);

const totalSteps = computed(() => rolesChain.length + 1);
const currentRole = computed(() => rolesChain[currentStep.value]);

const getUsersByRole = (role) => {
  return registeredUsers.value.filter(u => u.role === role);
};

const formatLabel = (role) => {
  // Converte "AGRICOLTORE" in "Agricoltore"
  return role.charAt(0) + role.slice(1).toLowerCase();
};

const nextStep = () => { if (currentStep.value < totalSteps.value - 1) currentStep.value++; };
const prevStep = () => { if (currentStep.value > 0) currentStep.value--; };

const handleCreate = () => {
  // Passiamo a ProducerView l'intero oggetto delle selezioni
  props.onCreate(props.lineaText, quantita.value, selections.value);
  
  // Reset completo
  currentStep.value = 0;
  quantita.value = 1;
  rolesChain.forEach(role => selections.value[role] = "");
};
</script>

<style scoped>
/* Il CSS rimane coerente con le tue specifiche di colori e layout bianco/nero */
.creation-card {
  flex: 1;
  background: white;
  padding: 25px;
  border-radius: 16px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.08);
  min-height: 350px; /* Aumentato leggermente per accomodare la lista riepilogo */
  display: flex;
  flex-direction: column;
  color: #000;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.linea-title { margin: 0; font-weight: 700; color: #000; }

.step-indicator {
  font-size: 0.75rem;
  background: #f0f0f0;
  padding: 4px 12px;
  border-radius: 20px;
  color: #666;
  font-weight: bold;
}

.step-label {
  display: block;
  font-weight: 600;
  font-size: 1.1rem;
  color: #000;
  margin-bottom: 5px;
}

.select-input-large {
  width: 100%;
  padding: 12px;
  border-radius: 10px;
  border: 1px solid var(--color-grigio-chiaro);
  background: white;
  color: #000;
  font-size: 1rem;
  margin-bottom: 10px;
}

.step-actions {
  display: flex;
  gap: 10px;
  margin-top: 15px;
}

.btn-next, .btn-confirm {
  flex: 2;
  padding: 12px;
  border: none;
  border-radius: 10px;
  font-weight: bold;
  cursor: pointer;
  transition: transform 0.2s, opacity 0.2s;
}

.btn-next:disabled { opacity: 0.5; cursor: not-allowed; }

.btn-outline {
  flex: 1;
  background: white;
  color: #000;
  border: 1px solid var(--color-grigio-chiaro);
  border-radius: 10px;
  font-weight: bold;
  cursor: pointer;
}

.quantity-selector {
  display: flex;
  align-items: center;
  gap: 15px;
  margin-top: 5px;
}

.input-qta {
  width: 70px;
  padding: 10px;
  text-align: center;
  border-radius: 10px;
  border: 1px solid var(--color-grigio-chiaro);
  font-weight: bold;
}

.lotti-text { font-weight: 600; color: #000; }

.summary-box {
  background: rgba(255,255,255,0.4);
  padding: 12px;
  border-radius: 10px;
  border: 1px solid #f0f0f0;
  font-size: 0.85rem;
  margin-top: 15px;
}

.summary-list {
  list-style: none;
  padding: 0;
  margin: 8px 0 0 0;
}

.summary-list li {
  display: flex;
  justify-content: space-between;
  padding: 2px 0;
  border-bottom: 1px solid rgba(0,0,0,0.03);
}

.role-name { color: #555; }

/* COLORI DINAMICI */
.rosso { border: 2px solid var(--color-rosso); background-color: var(--color-overlay-rosso); }
.rosso .btn-next, .rosso .btn-confirm { background-color: var(--color-rosso); color: white; }

.bianco { border: 2px solid var(--color-giallo); background-color: var(--color-overlay-giallo); }
.bianco .btn-next, .bianco .btn-confirm { background-color: var(--color-giallo); color: #000; }

.rose { border: 2px solid var(--color-rosa); background-color: var(--color-overlay-rosa); }
.rose .btn-next, .rose .btn-confirm { background-color: var(--color-rosa); color: #000; }

.step-fade-enter-active, .step-fade-leave-active { transition: all 0.3s ease; }
.step-fade-enter-from { opacity: 0; transform: translateX(15px); }
.step-fade-leave-to { opacity: 0; transform: translateX(-15px); }
</style>