<!--
  RolesView.vue

  Pagina per la gestione dei ruoli utenti (visibile solo ad ADMIN).

  Funzionalità principali:
  - Registrazione di nuovi utenti nella blockchain tramite RolesForm
  - Visualizzazione utenti registrati in tabella con UsersTable
  - Possibilità di rimuovere utenti, con gestione errori se coinvolti in lotti attivi
-->

<template>
  <div class="producer-page-wrapper">
    <main class="dashboard-main">

      <section class="card">
        <div class="card-title">
          <h2>Gestione ruoli utenti</h2>
        </div>

        <p class="subtitle">
          Inserisci un address Ethereum, il nome e assegna il ruolo corrispondente.
        </p>

        <RolesForm
          :available-roles="availableRoles"
          @assign="handleRegisterUser"
        />
      </section>

      <section class="card">
        <div class="card-title">
          <h2>Utenti Registrati</h2>
        </div>
        
        <UsersTable
          v-if="displayUsers.length > 0"
          :users="displayUsers"
          :available-roles="availableRoles"
          @remove="removeUser"
        />
        <p v-else class="empty-msg">Nessun utente registrato nella rubrica blockchain.</p>
      </section>

    </main>
  </div>
</template>

<script setup>
import { inject, computed, ref, onMounted } from "vue";
import { useUserStore } from "../stores/user";
import RolesForm from "../components/RolesForm.vue";
import UsersTable from "../components/UsersTable.vue";
import { useToast } from '../components/utils/useToast.js';

const { showToast } = useToast();

const userStore = useUserStore();
const contractInstance = inject("contractInstance");
const registeredUsers = inject("registeredUsers", ref([])); 
const refreshUsers = inject("refreshUsers"); 

// Stato locale
const localUsers = ref([]);
const adminAddress = computed(() => userStore.account);

// Ruoli per form
const availableRoles = [
  { value: "ADMIN", label: "Amministratore" },
  { value: "AGRICOLTORE", label: "Produttore" },
  { value: "SUPERVISORE", label: "Supervisore" },
  { value: "CANTINIERE", label: "Cantina" },
  { value: "CORRIERE", label: "Corriere" },
  { value: "DISTRIBUTORE", label: "Distributore" },
];

// Uniamo i dati della blockchain con quelli appena aggiunti localmente
const displayUsers = computed(() => {
  return registeredUsers.value.length > 0 ? registeredUsers.value : localUsers.value;
});

// Salvataggio nuovo utente
const handleRegisterUser = async ({ address, role, name }) => {

  try {
    console.log(`Registrazione di: ${name}...`);

    // Salvataggio blockchain
    await contractInstance.value.methods
      .addUser(address, name, role)
      .send({ from: adminAddress.value });

    // Aggiornamento locale
    const newUser = { address, name, role };
    localUsers.value.push(newUser);

    // Aggiornamento globale
    if (refreshUsers) await refreshUsers();

    showToast(`Utente ${name} registrato con successo!`, "success");
  } catch (err) {
    console.error("Errore registrazione:", err);
    showToast("Errore di transazione su Blockchain", "error");
  }
};


// Rimozione utente
const removeUser = async (address) => {

  try {
    await contractInstance.value.methods
      .eliminaUtente(address)
      .send({ from: adminAddress.value });

    localUsers.value = localUsers.value.filter(u => u.address !== address);

    if (refreshUsers) await refreshUsers();

    showToast("Utente rimosso con successo", "success");
  } catch (err) {
    console.error("Errore rimozione utente:", err);

    const reason = err?.data?.message || err?.message || "";
    const isActiveLotti = reason.includes("lotti attivi");

    showToast(
      isActiveLotti
        ? "Impossibile rimuovere: utente coinvolto in lotti attivi o in revisione"
        : "Errore transazione blockchain",
      "error"
    );
  }
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
.empty-msg {
  text-align: center;
  color: #999;
  font-style: italic;
  padding: 20px;
}
</style>