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
            <button
              @click="avanza(lotto, 'vendemmiato')"
              :disabled="lotto.stato !== 'creato'"
              class="btn-step"
            >
              🍇 Vendemmia
            </button>
            <button
              @click="avanza(lotto, 'fermentato')"
              :disabled="lotto.stato !== 'vendemmiato'"
              class="btn-step"
            >
              🧪 Fermentazione
            </button>
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
}

.process-table {
  width: 100%;
  border-collapse: collapse;
}

.process-table th {
  text-align: center;
  padding: 15px;
  background: var(--color-grigio-chiaro);
  color: var(--color-grigio-scuro);
  font-size: 0.75rem;
  text-transform: uppercase;
}

.process-table td {
  padding: 18px 15px;
  border-bottom: 1px solid var(--color-grigio-chiaro);
  text-align: center;
}

.badge {
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 0.7rem;
  font-weight: bold;
  color: var(--color-bianco);
}

.b-rosso { background: var(--color-rosso); }
.b-bianco { background: var(--color-giallo); }
.b-rosa {background: var(--color-rosa);}

.type-progress-col {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.progress-container {
  width: 100%;
  height: 6px;
  background: var(--progress-bg);
  border-radius: 10px;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background: var(--color-bordeaux);
  transition: width 0.4s ease;
}

.status-pill {
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 0.8rem;
  font-weight: bold;
}

.creato {
  background: var(--color-grigio-chiaro);
  color: var(--color-grigio-scuro);
}

.vendemmiato {
  background: var(--status-vendemmiato-bg);
  color: var(--color-verde);
}

.fermentato {
  background: var(--status-fermentato-bg);
  color: var(--color-blu);
}

.btn-step {
  background: var(--color-bianco);
  border: 2px solid var(--color-bordeaux);
  color: var(--color-bordeaux);
  padding: 6px 14px;
  border-radius: 6px;
  cursor: pointer;
  margin-right: 8px;
  font-weight: 600;
}

.btn-step:disabled {
  border-color: var(--btn-step-disabled);
  color: var(--btn-step-disabled);
  cursor: not-allowed;
}

.btn-step:hover:not(:disabled) {
  background: var(--color-bordeaux);
  color: var(--color-bianco);
}

</style>
