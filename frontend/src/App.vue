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


const onSegnalaProblema = async ({ lotto, motivazione }, reloadLotti) => {
  const accounts = await window.ethereum.request({ method: "eth_accounts" });
  await contract.value.methods.segnalaProblema(lotto.id, motivazione)
    .send({ from: accounts[0] });      
  await reloadLotti()       
};

const onRiabilitaLotto = async (lotto, reloadLotti) => {
  const accounts = await window.ethereum.request({ method: "eth_accounts" });

  await contract.value.methods
    .riabilitaLotto(lotto.id)
    .send({ from: accounts[0] });
  await reloadLotti()
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