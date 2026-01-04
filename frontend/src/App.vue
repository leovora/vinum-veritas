<template>
  <div id="app">
    <transition name="fade">
      <SplashScreen v-if="loading" />
    </transition>

    <div v-if="!loading" class="app-content">
      <AppHeader />
      <ToastContainer />
      <main class="container">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, provide } from "vue";
import { useRouter } from "vue-router";
import Web3 from "web3";

import AppHeader from "./components/AppHeader.vue";
import SplashScreen from "./views/SplashView.vue";
import WineProductionJSON from "./abis/WineProduction.json";
import { useUserStore } from "./stores/user";
import ToastContainer from './components/ToastContainer.vue';

const router = useRouter();
const userStore = useUserStore();

const loading = ref(true);
const contract = ref(null);

// STATO DEGLI UTENTI REGISTRATI
const registeredUsers = ref([]);

/**
 * Funzione per caricare la rubrica nomi/indirizzi dalla blockchain
 */
const loadUsers = async () => {
  if (!contract.value) {
    console.warn("LoadUsers: Contratto non ancora inizializzato");
    return;
  }
  
  try {
    console.log("Chiamata a getAllUserAddresses...");
    const addresses = await contract.value.methods.getAllUserAddresses().call();
    
    const usersData = [];
    for (let addr of addresses) {
      const info = await contract.value.methods.users(addr).call();
      usersData.push({
        address: addr,
        name: info.name,
        role: info.role 
      });
    }
    
    registeredUsers.value = usersData;
    console.log("Rubrica utenti caricata con successo:", registeredUsers.value);
  } catch (err) {
    console.error("Errore critico nel caricamento della rubrica:", err);
  }
};

/**
 * Recupera il ruolo reale dell'utente dal contratto
 */
const getUserRole = async (address) => {
  if (!contract.value) return "VISITATORE";
  try {
    const roleHash = await contract.value.methods.roles(address).call();
    
    if (!roleHash || roleHash === "0x0000000000000000000000000000000000000000000000000000000000000000") {
      return "VISITATORE";
    }

    const web3 = new Web3(window.ethereum);
    const rolesMap = {
      [web3.utils.keccak256("ADMIN")]: "ADMIN",
      [web3.utils.keccak256("AGRICOLTORE")]: "AGRICOLTORE",
      [web3.utils.keccak256("SUPERVISORE")]: "SUPERVISORE",
      [web3.utils.keccak256("CANTINIERE")]: "CANTINIERE",
      [web3.utils.keccak256("CORRIERE")]: "CORRIERE",
      [web3.utils.keccak256("DISTRIBUTORE")]: "DISTRIBUTORE",
    };

    return rolesMap[roleHash] || "VISITATORE";
  } catch (err) {
    console.error("Errore lettura ruolo:", err);
    return "VISITATORE";
  }
};

/**
 * Funzione centralizzata per segnalare un problema.
 * Deve essere fornita via provide() per essere usata da chiunque nella dApp.
 */
const onSegnalaProblema = async ({ lotto, motivazione }) => {
  if (!contract.value) return;

  try {
    const accounts = await window.ethereum.request({ method: "eth_accounts" });
    const allLotti = await contract.value.methods.getLotti().call();
    const index = allLotti.findIndex(l => l.id.toString() === lotto.id.toString());

    if (index === -1) return;

    // --- MODIFICA QUI ---
    // Salviamo lo stato attuale nel localStorage prima di inviare la transazione
    // Usiamo l'ID del lotto come chiave per non confonderli
    const statoDaSalvare = allLotti[index].stato;
    localStorage.setItem(`lastState_lotto_${lotto.id}`, statoDaSalvare);
    console.log(`Stato ${statoDaSalvare} salvato localmente per il lotto ${lotto.id}`);

    await contract.value.methods.segnalaProblema(index, motivazione)
      .send({ from: accounts[0] });
    
    window.location.reload(); 
  } catch (error) {
    console.error("Errore segnalazione:", error);
  }
};

/**
 * LOGICA RIABILITAZIONE (Sblocco Lotto Admin)
 */
/**
 * Riabilita il lotto portandolo automaticamente all'ultimo stato valido 
 * prima che venisse segnalato il problema.
 */
const onRiabilitaLotto = async (lotto) => {
  if (!contract.value) return;
  
  console.log("APP.VUE: Avvio riabilitazione automatica per lotto:", lotto.id);

  try {
    const accounts = await window.ethereum.request({ method: "eth_accounts" });
    
    const allLotti = await contract.value.methods.getLotti().call();
    const index = allLotti.findIndex(l => l.id.toString() === lotto.id.toString());

    if (index === -1) return;

    // --- RECUPERO STATO SALVATO ---
    // Leggiamo lo stato che avevamo salvato nel localStorage
    const statoSalvato = localStorage.getItem(`lastState_lotto_${lotto.id}`);
    
    // Se per qualche motivo il localStorage è vuoto, usiamo il calcolo di emergenza
    let statoDestinazione;
    if (statoSalvato !== null) {
      statoDestinazione = parseInt(statoSalvato);
      console.log(`APP.VUE: Recuperato stato salvato: ${statoDestinazione}`);
    } else {
      // Calcolo di emergenza (se l'utente ha pulito la cache)
      const lottoDati = allLotti[index];
      statoDestinazione = Math.max(0, lottoDati.luoghi.length - 3); 
      console.warn("APP.VUE: Stato non trovato in cache, uso calcolo di emergenza.");
    }

    // 2. Invio transazione al contratto
    await contract.value.methods.riabilitaLotto(index, statoDestinazione)
      .send({ from: accounts[0] });
    
    // Puliamo il localStorage dopo il ripristino
    localStorage.removeItem(`lastState_lotto_${lotto.id}`);
    
    console.log("APP.VUE: Lotto riabilitato con successo allo stato", statoDestinazione);
    window.location.reload();

  } catch (e) {
    console.error("Errore riabilitazione:", e);
    alert("Errore durante lo sblocco del lotto.");
  }
};

// Forniamo le funzioni aggiornate
provide("contractInstance", contract);
provide("registeredUsers", registeredUsers);
provide("refreshUsers", loadUsers);
provide("onSegnalaProblema", onSegnalaProblema);
provide("onRiabilitaLotto", onRiabilitaLotto);

onMounted(async () => {
  console.log("Vinum Veritas — Avvio dApp");

  if (!window.ethereum) {
    alert("MetaMask non rilevato. Per favore installa l'estensione.");
    loading.value = false;
    return;
  }

  window.ethereum.on("accountsChanged", () => window.location.reload());
  window.ethereum.on("chainChanged", () => window.location.reload());

  try {
    const web3 = new Web3(window.ethereum);
    const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
    if (!accounts.length) return;

    const account = accounts[0];
    const networkId = await web3.eth.net.getId();
    const deployed = WineProductionJSON.networks[networkId];

    if (!deployed) {
      throw new Error("Contratto non trovato (hai fatto truffle migrate?)");
    }

    contract.value = new web3.eth.Contract(WineProductionJSON.abi, deployed.address);

    await loadUsers();
    const role = await getUserRole(account);
    userStore.setUser(account, role);

    setTimeout(() => {
      loading.value = false;
      if (userStore.isAdmin) {
        router.replace("/producer");
      } else if (role === "VISITATORE") {
        router.replace("/search");
      } else {
        router.replace("/update");
      }
    }, 1200);

  } catch (err) {
    console.error("Errore inizializzazione:", err);
    loading.value = false;
    alert("Connessione Blockchain fallita: " + err.message);
  }
});
</script>

<style>
@import "./assets/styles/vinum.css";

.fade-enter-active, .fade-leave-active {
  transition: opacity 0.5s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>