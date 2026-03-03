<template>
  <div class="lotto-card card animate-fade-in">
    <div
      v-if="lotto.inRevisione || lotto.eliminato"
      class="alert-revisione"
    >
      <div class="alert-icon">⚠️</div>
      <div class="alert-content">
        <p class="alert-title">
          {{ lotto.inRevisione ? "Lotto in revisione" : "Lotto bloccato" }}
        </p>
        <p class="alert-desc">
          <p v-if="lotto.inRevisione">Il lotto è in attesa di revisione dall'admin</p>
          <p v-if="lotto.eliminato">Il lotto è stato bloccato dall'admin</p>
        </br>
          <strong>Motivazione:</strong>
          {{ lotto.motivazione || "Analisi tecnica in corso" }}
        </p>
      </div>
    </div>

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
              {{
                lotto.actors[phase.role] || "In attesa..." 
              }}
            </td>

            <td class="col-validation">
              <span
                v-if="lotto.timestamps && lotto.timestamps[index]"
                class="check-valid"
              >
                ✅ Fatto
              </span>
              <span v-else class="check-pending"> ❌ Da fare </span>
            </td>

            <td class="col-timestamp">
              {{
                lotto.timestamps && lotto.timestamps[index]
                  ? new Date(lotto.timestamps[index] * 1000).toLocaleString(
                      "it-IT",
                    )
                  : "-"
              }}
            </td>

            <td class="col-luogo">
              {{
                lotto.luoghi && lotto.luoghi[index] ? lotto.luoghi[index] : "-"
              }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  lotto: {
    type: Object,
    required: true,
  },
});

const PHASES = [
  { name: "Vendemmia", role: "agricoltore" },
  { name: "Fermentazione", role: "supervisore" },
  { name: "Affinamento", role: "supervisore" },
  { name: "Imbottigliamento", role: "cantiniere" },
  { name: "Spedizione", role: "corriere" },
  { name: "Ricezione", role: "distributore" },
];
</script>

<style scoped>

.card {
  border: 1px solid #eee;
  background: #fff;
  padding: 30px;
  border-radius: 12px;
  margin-bottom: 25px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.03);
}
.alert-revisione {
  background: #fff5f5;
  border: 1px solid #feb2b2;
  padding: 20px;
  margin-bottom: 25px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  gap: 10px;
}
.alert-icon {
  font-size: 1.8rem;
  margin-bottom: 5px;
}
.alert-title {
  font-weight: 800;
  color: #c53030;
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 1px;
}
.alert-desc {
  color: #742a2a;
  margin: 0;
  font-size: 1rem;
  line-height: 1.5;
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
.status-0 {
  background: #fff3e0;
  color: #e67e22;
}
.status-5 {
  background: #e8f5e9;
  color: #27ae60;
}
.revisione,
.status-revisione {
  background: #c53030;
  color: white;
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
</style>
