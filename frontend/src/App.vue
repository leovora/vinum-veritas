<template>
  <div id="app">
    <transition name="fade">
      <SplashScreen v-if="loading" />
    </transition>

    <div v-if="!loading" class="app-content">
      <AppHeader /> 
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

// Importazione Asset e Componenti
import AppHeader from "./components/AppHeader.vue";
import SplashScreen from "./views/SplashView.vue";
import WineProductionJSON from "./abis/WineProduction.json";
import { useUserStore } from './stores/user';

const router = useRouter();
const userStore = useUserStore();

// STATI REATTIVI
const loading = ref(true);
const account = ref("");
const role = ref("");
const contract = ref(null);

// Forniamo i dati a tutti i componenti figli (Injection)
provide("userAddress", account);
provide("userRole", role);
provide("contractInstance", contract);

/**
 * Logica per recuperare il ruolo dell'utente dal contratto
 * Per ora impostato come mock "admin"
 */
const getUserRole = async (userAddr) => {
  // TODO: implementare chiamata reale: return await contract.value.methods.roles(userAddr).call();
  return "admin"; 
};

onMounted(async () => {
  console.log("Vinum Veritas: Avvio sessione Blockchain...");

  // Gestione dinamica cambio account MetaMask
  if (window.ethereum) {
    window.ethereum.on('accountsChanged', () => window.location.reload());
    window.ethereum.on('chainChanged', () => window.location.reload());
  }

  try {
    if (!window.ethereum) {
      alert("MetaMask non rilevato! Installa l'estensione per proseguire.");
      return;
    }

    const web3 = new Web3(window.ethereum);
    
    // Richiesta di connessione a MetaMask (Bloccante)
    const accounts = await window.ethereum.request({ 
      method: "eth_requestAccounts" 
    });
    
    if (accounts.length > 0) {
      account.value = accounts[0];

      // Inizializzazione del Contratto tramite l'ABI aggiornato
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = WineProductionJSON.networks[networkId];

      if (deployedNetwork) {
        contract.value = new web3.eth.Contract(
          WineProductionJSON.abi,
          deployedNetwork.address
        );
        console.log("Smart Contract agganciato all'indirizzo:", deployedNetwork.address);
      } else {
        // Se arrivi qui, il promemoria dell'ABI è la soluzione!
        throw new Error("Contratto non trovato sulla rete attuale. Controlla Ganache e il file JSON.");
      }

      // Definizione ruolo e salvataggio nello Store (Pinia)
      role.value = await getUserRole(account.value);
      userStore.account = account.value;
      userStore.role = role.value;

      // Fine caricamento e reindirizzamento
      setTimeout(() => {
        loading.value = false;
        if (role.value === "admin") {
          router.replace("/producer");
        } else {
          router.replace("/update");
        }
      }, 1500);
    }
  } catch (err) {
    console.error("Errore inizializzazione dApp:", err);
    alert("Accesso negato. Connetti MetaMask e assicurati che il contratto sia migrato correttamente.");
  }
});
</script>

<style>
/* Caricamento stili globali */
@import "./assets/styles/vinum.css";
</style>