<template>
  <div class="producer-page-wrapper">
    <main class="dashboard-main">

      <!-- SEZIONE CREAZIONE RUOLO -->
      <section class="card">
        <div class="card-title">
          <h2>Gestione ruoli utenti</h2>
        </div>

        <p class="subtitle">
          Inserisci un address Ethereum e assegna il ruolo corrispondente.
        </p>

        <RolesForm
          :available-roles="availableRoles"
          @assign="assignRole"
        />
      </section>

      <!-- SEZIONE LISTA UTENTI -->
      <section class="card" v-if="users.length">
        <div class="card-title">
          <h2>Utenti Registrati</h2>
        </div>

        <UsersTable
          :users="users"
          :available-roles="availableRoles"
          @remove="removeUser"
        />
      </section>

    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";
import RolesForm from "../components/RolesForm.vue";
import UsersTable from "../components/UsersTable.vue";

const availableRoles = [
  { value: "admin", label: "Amministratore" },
  { value: "producer", label: "Produttore" },
  { value: "supervisor", label: "Supervisore" },
  { value: "winery", label: "Cantina" },
  { value: "carrier", label: "Corriere" },
  { value: "distributor", label: "Distributore" },
];

const users = ref([]);

onMounted(async () => {
  // MOCK: dati già presenti
  users.value = [
    { address: '0xFA55b1f74E6548B0a44822d7f589f3BA51015388', role: 'producer' },
    { address: '0x832e2D1C32baFB201842B24Ea12e7B03e2Ca1965', role: 'supervisor' }
  ];

  // TODO: quando smart contract pronto
  // users.value = await contract.methods.getUsers().call();
});


const assignRole = (user) => {
  // MOCK — sostituibile con smart contract
  users.value.push(user);
};

const removeUser = (address) => {
  // MOCK — sostituibile con smart contract
  users.value = users.value.filter(
    (u) => u.address !== address
  );
};

</script>

<style scoped>
.producer-page-wrapper {
  width: 100%;
  background-color: var(--color-bg);
}

.dashboard-main {
  max-width: 1200px;
  margin: -40px auto 0;
  padding: 0 20px 100px;
  position: relative;
}

/* titolo sezione */
.card-title {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 15px;
  margin-bottom: 25px;
  border-bottom: 2px solid var(--color-grigio-chiaro);
  padding-bottom: 15px;
}

.card-title h2 {
  margin: 0;
  text-align: center;
  font-size: 1.8rem;
  color: var(--color-text-dark);
}

.subtitle {
  text-align: center;
  color: var(--color-text-dark);
  margin-bottom: 30px;
}
</style>
