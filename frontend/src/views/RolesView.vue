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
import { ref, onMounted, inject } from "vue"; // Aggiunto inject
import RolesForm from "../components/RolesForm.vue";
import UsersTable from "../components/UsersTable.vue";

// Recuperiamo l'istanza del contratto e l'indirizzo per rendere l'operazione REALE
const userAddress = inject("userAddress");
const contractInstance = inject("contractInstance");

const availableRoles = [
  { value: "ADMIN", label: "Amministratore" },
  { value: "AGRICOLTORE", label: "Produttore (Agricoltore)" }, // Cambiato da producer
  { value: "SUPERVISORE", label: "Supervisore" },
  { value: "CANTINIERE", label: "Cantina" }, // Cambiato da winery
  { value: "CORRIERE", label: "Corriere" }, // Cambiato da carrier
  { value: "DISTRIBUTORE", label: "Distributore" },
];

const users = ref([]);

// Funzione REALE per assegnare il ruolo sulla Blockchain
const assignRole = async (userData) => {
  try {
    // contractInstance deve essere caricato correttamente da App.vue
    await contractInstance.value.methods
      .assignRole(userData.address, userData.role) 
      .send({ from: userAddress.value }); // userAddress deve essere l'Admin

    alert("Assegnato!");
  } catch (error) {
    console.error("Dettaglio Errore:", error);
    alert("Errore Blockchain: controlla la console (F12)");
  }
};

const removeUser = (address) => {
  users.value = users.value.filter((u) => u.address !== address);
};

onMounted(() => {
  // Mock iniziale (opzionale, meglio caricarli dal contratto se possibile)
  users.value = [
    { address: '0xFA55b1f74E6548B0a44822d7f589f3BA51015388', role: 'AGRICOLTORE' },
    { address: '0x832e2D1C32baFB201842B24Ea12e7B03e2Ca1965', role: 'SUPERVISORE' }
  ];
});

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
