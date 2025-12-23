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
          <td colspan="4" class="empty-msg">
            Nessun lotto creato. Usa il pannello sopra per iniziare.
          </td>
        </tr>
        <tr v-for="lotto in lotti" :key="lotto.id">
          <td class="id-cell">#{{ lotto.id }}</td>
          <td>
            <div class="type-progress-col">
              <span
                :class="[
                  'badge',
                  lotto.tipo.includes('Rosso') ? 'b-rosso' : 
                  lotto.tipo.includes('Bianco') ? 'b-bianco' : 'b-rosa'
                ]"
              >
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
            <span :class="['status-pill', lotto.stato]">{{
              getStatusLabel(lotto.stato)
            }}</span>
          </td>
          <td class="actions-cell">
            <div class="btn-group">
              <button
                @click="avanza(lotto)"
                :disabled="lotto.stato !== 'creato'"
                class="btn-step"
              >
                🍇 Vendemmia
              </button>

              <button
                @click="avanza(lotto)"
                :disabled="lotto.stato !== 'vendemmiato'"
                class="btn-step"
              >
                🧪 Fermentazione
              </button>

              <button
                @click="avanza(lotto)"
                :disabled="lotto.stato !== 'fermentato'"
                class="btn-step"
              >
                🏺 Affinamento
              </button>

              <button
              @click="avanza(lotto)"
              :disabled="lotto.stato !== 'affinato'" 
              class="btn-step"
            >
              🍾 Imbottigliamento
            </button>

              <button
                @click="avanza(lotto)"
                :disabled="lotto.stato !== 'imbottigliato'"
                class="btn-step"
              >
                🚚 Distribuzione
              </button>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
const props = defineProps({
  lotti: Array,
  getStatusLabel: Function,
  getProgressWidth: Function,
  avanza: Function,
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
  border-spacing: 0 10px; /* Crea un effetto "card" per ogni riga */
}

.process-table th {
  text-align: center;
  padding: 15px;
  color: var(--color-grigio-scuro);
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

/* Arrotondamento bordi per effetto card */
.process-table td:first-child { border-left: 1px solid #eee; border-radius: 10px 0 0 10px; }
.process-table td:last-child { border-right: 1px solid #eee; border-radius: 0 10px 10px 0; }

.badge {
  padding: 5px 12px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: bold;
  color: white;
}

.b-rosso { background: var(--color-rosso); }
.b-bianco { background: var(--color-giallo); }
.b-rosa { background: #db7093; }

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
  background: var(--color-bordeaux);
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

/* Colori stati */
.creato { background: #f8f9fa; color: #6c757d; border: 1px solid #dee2e6; }
.vendemmiato { background: #e6fffa; color: #2d3748; border: 1px solid #b2f5ea; }
.fermentato { background: #ebf8ff; color: #2b6cb0; border: 1px solid #bee3f8; }
.affinato { background: #fffaf0; color: #9c4221; border: 1px solid #feebc8; }
.imbottigliato { background: #f7fafc; color: #2d3748; border: 1px solid #edf2f7; }
.distribuito { background: #faf5ff; color: #6b46c1; border: 1px solid #e9d8fd; }

.btn-group {
  display: flex;
  justify-content: center;
  gap: 8px;
  flex-wrap: wrap; /* Importante: se lo spazio finisce, i bottoni vanno a capo */
}

.btn-step {
  display: flex;
  align-items: center;
  gap: 5px;
  background: white;
  border: 1.5px solid var(--color-bordeaux);
  color: var(--color-bordeaux);
  padding: 8px 12px;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  font-size: 0.85rem;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.btn-step:disabled {
  display: none; /* Nascondiamo i bottoni non pertinenti per pulizia visiva */
}

.btn-step:hover:not(:disabled) {
  background: var(--color-bordeaux);
  color: white;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}
</style>