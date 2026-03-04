<!--
  RolesForm.vue

  Componente per l’assegnazione dei ruoli agli utenti.

  Funzionalità:
  - Inserimento address Ethereum, nome e ruolo
  - Emissione evento "assign" verso il parent
-->

<template>
  <div class="role-form">
    <div class="form-row">
      <label>Address Ethereum</label>
      <input v-model="newUser.address" type="text" placeholder="0x..." />
    </div>

    <div class="form-row">
      <label>Nome</label>
      <input v-model="newUser.name" type="text" placeholder="Nome utente" />
    </div>

    <div class="form-row">
      <label>Ruolo</label>
      <select v-model="newUser.role">
        <option disabled value="">Seleziona ruolo</option>
        <option
          v-for="role in availableRoles"
          :key="role.value"
          :value="role.value"
        >
          {{ role.label }}
        </option>
      </select>
    </div>

    <button class="btn-primary" @click="submit">Assegna ruolo</button>
  </div>
</template>

<script setup>
import { reactive } from "vue";
import { useToast } from '../components/utils/useToast.js';

//Toast per messaggi di errore / successo
const { showToast } = useToast();

const props = defineProps({
  availableRoles: { //array di ruoli selezionabili
    type: Array,
    required: true,
  },
});

//evento emesso verso il parent che chiama lo smart contract
const emit = defineEmits(["assign"]);

const newUser = reactive({
  address: "",
  role: "",
  name: "",
});

/**
 * - Controlla che tutti i campi siano compilati
 * - Mostra toast in caso di errore
 * - Emette evento assign verso il parent
 * - Reset dei campi dopo invio
 */
const submit = () => {
  if (!newUser.address || !newUser.role || !newUser.name) {
    showToast("Inserisci address, nome e ruolo", "error");
    return;
  }

  emit("assign", {
    address: newUser.address,
    role: newUser.role,
    name: newUser.name,
  });

  newUser.address = "";
  newUser.role = "";
  newUser.name = "";
};
</script>

<style scoped>
.role-form {
  max-width: 600px;
  margin: 0 auto;
}

.form-row {
  display: flex;
  flex-direction: column;
  margin-bottom: 20px;
}

.form-row label {
  font-weight: var(--font-weight-normal);
  margin-bottom: 6px;
  color: var(--color-text-dark);
}

.form-row input,
.form-row select {
  padding: var(--btn-padding);
  border-radius: var(--btn-radius);
  border: 1px solid var(--color-grigio-chiaro);
  background: var(--color-bianco);
  color: var(--color-text-dark);
}

.form-row input:focus,
.form-row select:focus {
  outline: none;
  border-color: var(--color-bordeaux);
}

.btn-primary {
  background-color: var(--color-bordeaux);
  color: var(--color-bianco);
  padding: var(--btn-padding);
  border-radius: var(--btn-radius);
  font-weight: var(--font-weight-bold);
  border: none;
  width: 100%;
}

.btn-primary:hover {
  background-color: var(--color-rosso);
}
</style>
