<!--
  LottoCard.vue

  Componente di presentazione che visualizza lo stato completo
  di un lotto.

  Mostra:
  - Stato amministrativo (revisione / eliminazione)
  - Tipo di vino
  - Avanzamento della filiera
  - Timestamp e luoghi registrati on-chain
-->

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
    </div>

    <div class="lotto-info-single">
      <div class="tipo-wrapper">
        <span class="tipo-pill" :class="tipoClass">
          {{ lotto.tipo }}
        </span>
      </div>
    </div>

    <div class="table-section table-wrapper">
      <h3 class="section-title">Stato avanzamento</h3>
      <table class="process-table-custom">
        <thead>
          <tr>
            <th>Fase</th>
            <th>Indirizzo responsabile</th>
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
import { computed } from "vue";

const props = defineProps({
  lotto: {
    type: Object,
    required: true,
  },
});

//Mappatura delle fasi della filiera
const PHASES = [
  { name: "Vendemmia", role: "agricoltore" },
  { name: "Fermentazione", role: "supervisore" },
  { name: "Affinamento", role: "supervisore" },
  { name: "Imbottigliamento", role: "cantiniere" },
  { name: "Spedizione", role: "corriere" },
  { name: "Ricezione", role: "distributore" },
];

//Computed che assegna una classe CSS in base al tipo di vino
const tipoClass = computed(() => {
  if (!props.lotto.tipo) return "";

  const tipo = props.lotto.tipo.toLowerCase();

  if (tipo.includes("rosso")) return "tipo-rosso";
  if (tipo.includes("bianco")) return "tipo-bianco";
  if (tipo.includes("ros")) return "tipo-rose";

  return "";
});

</script>

<style scoped>

/* ================= CARD ================= */

.card {
  border: 1px solid #eee;
  background: #fff;
  padding: 35px 40px;
  border-radius: 14px;
  margin-bottom: 25px;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.04);
}

/* ================= ALERT BLOCCO / REVISIONE ================= */

.alert-revisione {
  background: #fff5f5;
  border: 1px solid #feb2b2;
  padding: 22px;
  margin-bottom: 30px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  border-radius: 10px;
  gap: 8px;
}

.alert-icon {
  font-size: 1.8rem;
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
  font-size: 0.95rem;
  line-height: 1.5;
}

/* ================= HEADER ================= */

.lotto-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 15px;
  border-bottom: 1px solid #f0f0f0;
  margin-bottom: 30px;
}

.lotto-number {
  font-size: 2.4rem;
  font-weight: 800;
  margin: 0;
  letter-spacing: 1px;
}

/* ================= TIPO PRODOTTO ================= */

.lotto-info-single {
  display: flex;
  justify-content: center;
  margin-bottom: 20px;
}

.tipo-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
}

.tipo-pill {
  padding: 10px 26px;
  border-radius: 999px;
  font-size: 0.9rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: white;
  box-shadow: 0 3px 12px rgba(0,0,0,0.06);
}

/* Varianti colore */
.tipo-rosso {
  background: linear-gradient(135deg, #8b0000, #c0392b);
}

.tipo-bianco {
  background: linear-gradient(135deg, #f4d03f, #f7dc6f);
  color: #5a4b00;
}

.tipo-rose {
  background: linear-gradient(135deg, #f78fb3, #f8a5c2);
  color: #7a1e3a;
}

/* ================= SEZIONE TABELLA ================= */

.section-title {
  text-align: center;
  font-size: 1.1rem;
  font-weight: 700;
  margin-bottom: 20px;
  letter-spacing: 0.5px;
}

/* Wrapper anti-overflow */
.table-wrapper {
  width: 100%;
  overflow-x: auto;
}

/* Tabella */
.process-table-custom {
  width: 100%;
  border-collapse: collapse;
  table-layout: fixed;
  word-wrap: break-word;
}

/* Header */
.process-table-custom th {
  text-align: center;
  padding: 12px;
  background: #fafafa;
  font-size: 0.75rem;
  color: #888;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  word-break: break-word;
}

/* Celle */
.process-table-custom td {
  padding: 14px 12px;
  border-bottom: 1px solid #f1f1f1;
  font-size: 0.85rem;
  text-align: center;
  vertical-align: middle;
  word-break: break-word;
}

/* Colonna indirizzi */
.address-cell {
  font-size: 0.75rem;
  word-break: break-all;
}

/* Validazione */
.check-valid {
  color: #27ae60;
  font-weight: bold;
}

.check-pending {
  color: #c0392b;
  font-weight: bold;
}

/* Larghezze colonne */
.col-validation {
  width: 90px;
}

.col-timestamp {
  width: 100px;
}

.col-luogo {
  width: 150px;
}
</style>
