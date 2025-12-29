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
import { ref, onMounted, inject, computed } from "vue";
import { useUserStore } from "../stores/user";

import RolesForm from "../components/RolesForm.vue";
import UsersTable from "../components/UsersTable.vue";

/* =========================
   STORE & CONTRACT
========================= */
const userStore = useUserStore();
const contractInstance = inject("contractInstance");

const adminAddress = computed(() => userStore.account);
const adminRole = computed(() => userStore.role);

/* =========================
   RUOLI DISPONIBILI
========================= */
const availableRoles = [
  { value: "ADMIN", label: "Amministratore" },
  { value: "AGRICOLTORE", label: "Produttore" },
  { value: "SUPERVISORE", label: "Supervisore" },
  { value: "CANTINIERE", label: "Cantina" },
  { value: "CORRIERE", label: "Corriere" },
  { value: "DISTRIBUTORE", label: "Distributore" },
];

/* =========================
   UTENTI
========================= */
const users = ref([]);

/* =========================
   ASSIGN ROLE (ON-CHAIN)
========================= */
const assignRole = async ({ address, role, name }) => {
  if (adminRole.value !== "ADMIN") {
    alert("Solo un ADMIN può assegnare ruoli");
    return;
  }

  try {
    await contractInstance.value.methods
      .assignRole(address, role)
      .send({ from: adminAddress.value });

    const existing = users.value.find(u => u.address === address);
    if (existing) {
      existing.role = role;
      existing.name = name;
    } else {
      users.value.push({ address, role, name });
    }

    alert("Ruolo assegnato correttamente");
  } catch (err) {
    console.error("Errore assignRole:", err);
    alert("Errore blockchain (vedi console)");
  }
};

/* =========================
   REMOVE USER (UI ONLY)
========================= */
const removeUser = (address) => {
  users.value = users.value.filter((u) => u.address !== address);
};

/* =========================
   INIT
========================= */
onMounted(() => {
  // MOCK TEMPORANEO
  // ideale: caricarli dal contratto (eventi RoleAssigned)
  users.value = [
    {
      address: "0xFA55b1f74E6548B0a44822d7f589f3BA51015388",
      role: "AGRICOLTORE",
      name: "Giorgione"
    },
    {
      address: "0x832e2D1C32baFB201842B24Ea12e7B03e2Ca1965",
      role: "CORRIERE",
      name: "Bartolini"
    },
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
