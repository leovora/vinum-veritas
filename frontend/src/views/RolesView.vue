<template>
  <div class="producer-page-wrapper">
    <main class="dashboard-main">

      <section class="card">
        <div class="card-title">
          <h2>Gestione ruoli utenti</h2>
        </div>

        <p class="subtitle">
          Inserisci un address Ethereum e assegna il ruolo corrispondente.
        </p>

        <RolesForm
          :available-roles="availableRoles"
          @assign="gestisciAssegnazioneRuolo"
        />
      </section>

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

// L'indirizzo di chi sta usando il sito (deve essere ADMIN per funzionare)
const adminAddress = computed(() => userStore.account);
const adminRole = computed(() => userStore.role);

/* =========================
   RUOLI DISPONIBILI
   (Devono coincidere ESATTAMENTE con quelli in Solidity isRuoloValido)
========================= */
const availableRoles = [
  { value: "ADMIN", label: "Amministratore" },
  { value: "AGRICOLTORE", label: "Produttore/Agricoltore" },
  { value: "SUPERVISORE", label: "Supervisore" },
  { value: "CANTINIERE", label: "Cantiniere" },
  { value: "CORRIERE", label: "Corriere" },
  { value: "DISTRIBUTORE", label: "Distributore" },
];

/* =========================
   UTENTI (Stato locale)
========================= */
const users = ref([]);

/* =========================
   ASSEGNAZIONE RUOLO (Blockchain)
========================= */
const gestisciAssegnazioneRuolo = async ({ address, role, name }) => {
  
  // 1. Controllo preliminare Frontend (opzionale, il contract lo fa già)
  if (adminRole.value !== "ADMIN") {
    alert("ERRORE: Solo l'ADMIN può assegnare ruoli sulla Blockchain.");
    return;
  }

  try {
    console.log(`Assegnazione in corso: ${address} -> ${role}`);

    // 2. CHIAMATA AL CONTATTO (La parte corretta)
    // Usiamo 'impostaRuolo' invece di 'assignRole'
    await contractInstance.value.methods
      .impostaRuolo(address, role) 
      .send({ from: adminAddress.value });

    // 3. Aggiornamento UI locale (solo se la transazione va a buon fine)
    const existing = users.value.find(u => u.address === address);
    
    if (existing) {
      existing.role = role;
      existing.name = name; // Aggiorniamo anche il nome "finto" locale
    } else {
      users.value.push({ address, role, name });
    }

    alert(`Successo! Ruolo ${role} assegnato a ${name || address}`);
    
  } catch (err) {
    console.error("Errore Blockchain:", err);
    // Se l'utente rifiuta su MetaMask o c'è un errore
    alert("Errore durante l'assegnazione. Controlla la console e assicurati di essere ADMIN.");
  }
};

/* =========================
   RIMOZIONE UTENTE (Solo UI per ora)
========================= */
const removeUser = (address) => {
  // Nota: Questo rimuove solo dalla tabella visiva. 
  // Per rimuovere dalla blockchain dovremmo chiamare impostaRuolo con un ruolo nullo o gestire la logica di ban.
  users.value = users.value.filter((u) => u.address !== address);
};

/* =========================
   INIT
========================= */
onMounted(async () => {
  // MOCK DATA (Dati finti per vedere se la tabella funziona)
  // In futuro qui potresti leggere gli eventi 'RuoloAssegnato' dal contratto
  users.value = [
    {
      address: "0xFA55b1f74E6548B0a44822d7f589f3BA51015388",
      role: "AGRICOLTORE",
      name: "Giorgione (Mock)"
    },
    {
      address: "0x832e2D1C32baFB201842B24Ea12e7B03e2Ca1965",
      role: "CORRIERE",
      name: "Bartolini (Mock)"
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