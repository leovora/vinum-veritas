<template>
  <div class="lotto-card card animate-fade-in">
    <div class="lotto-header">
      <div class="lotto-id-centered">
        <h2 class="lotto-number">Lotto #{{ lotto.id }}</h2>
      </div>
      <div :class="['status-pill', lotto.statusClass]">
        {{ lotto.statusLabel }}
      </div>
    </div>

    <div class="lotto-info-single">
      <div class="info-item">
        <label>Tipologia Prodotto</label>
        <p class="data-value">{{ lotto.tipo }}</p>
      </div>
    </div>

    <div class="table-section">
      <h3 class="section-title">Stato Avanzamento Processo</h3>
      <table class="process-table-custom">
        <thead>
          <tr>
            <th>Fase</th>
            <th>Indirizzo Certificato</th>
            <th class="col-validation">Validazione</th>
            <th class="col-timestamp">Timestamp</th>
            <th class="col-luogo">Luogo</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(phase, index) in PHASES" :key="phase.name">
            <td class="role-cell">{{ phase.name }}</td>
            <td class="address-cell">
              {{ lotto.actors[phase.role] && lotto.actors[phase.role] !== ZERO_ADDRESS
                ? lotto.actors[phase.role]
                : "In attesa..." }}
            </td>
            <td class="col-validation">
              <span v-if="index < Number(lotto.statoRaw)" class="check-valid">✅ Fatto</span>
              <span v-else class="check-pending">❌ Da fare</span>
            </td>
            <td class="col-timestamp">
              {{ lotto.timestamps && lotto.timestamps[index]
                ? new Date(lotto.timestamps[index] * 1000).toLocaleString()
                : "-" }}
            </td>
            <td class="col-luogo">
              {{ lotto.luoghi && lotto.luoghi[index] ? lotto.luoghi[index] : "-" }}
            </td>
          </tr>
        </tbody>

      </table>
    </div>
  </div>
</template>

<script setup>
defineProps({
  lotto: {
    type: Object,
    required: true,
  },
});

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

// Definizione fasi ordinate correttamente
const PHASES = [
  { name: "Vendemmia", role: "Agricoltore" },
  { name: "Fermentazione", role: "Supervisore" },
  { name: "Affinamento", role: "Supervisore" },
  { name: "Imbottigliamento", role: "Cantiniere" },
  { name: "Spedizione", role: "Corriere" },
  { name: "Ricezione", role: "Distributore" },
];
</script>

<style scoped>
.card {
  border: 1px solid #eee;
  background: #fff;
  padding: 30px;
  border-radius: 12px;
  margin-bottom: 25px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.03);
}

.lotto-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  border-bottom: 1px solid #f5f5f5;
  padding-bottom: 20px;
  margin-bottom: 25px;
}

.lotto-number {
  font-size: 2.2rem;
  font-weight: 800;
  margin: 0;
}

.status-pill {
  padding: 8px 20px;
  border-radius: 50px;
  font-size: 0.9rem;
  font-weight: 700;
  text-transform: uppercase;
  margin-top: 10px;
}

.status-0 { background: #fff3e0; color: #e67e22; }
.status-5 { background: #e8f5e9; color: #27ae60; }
.status-pill:not(.status-0):not(.status-5) {
  background: #f4f4f4;
  color: #666;
}

.lotto-info-single {
  text-align: center;
  margin-bottom: 35px;
}

.info-item label {
  font-size: 0.8rem;
  text-transform: uppercase;
  color: #999;
  font-weight: bold;
}

.data-value {
  font-size: 1.3rem;
  color: #2c3e50;
  font-weight: 600;
}

.process-table-custom {
  width: 100%;
  border-collapse: collapse;
  margin-top: 10px;
}

.process-table-custom th {
  text-align: left;
  padding: 12px;
  background: #fafafa;
  font-size: 0.8rem;
  color: #888;
  text-transform: uppercase;
}

.process-table-custom td {
  padding: 14px 12px;
  border-bottom: 1px solid #f1f1f1;
  font-size: 0.9rem;
}

.role-cell {
  font-weight: bold;
}

.address-cell {
  font-family: monospace;
  color: #666;
  font-size: 0.85rem;
}

.check-valid {
  color: #27ae60;
  font-weight: bold;
}

.check-pending {
  color: #c0392b;
  font-weight: bold;
}

.col-validation {
  width: 120px;
  text-align: center;
}

.col-timestamp {
  width: 180px;
}

.col-luogo {
  width: 180px;
}

</style>
