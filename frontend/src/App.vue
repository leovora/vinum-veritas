<template>
  <div id="app">
    <transition name="fade">
      <SplashScreen v-if="loading" />
    </transition>

    <div v-if="!loading" class="app-content">
      <main class="container">
        <ProducerDashboard 
          :user-address="account" 
          :contract-instance="contract"
        />
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import Web3 from 'web3';
import WineProductionJSON from './abis/WineProduction.json';
import SplashScreen from './components/SplashScreen.vue';
import ProducerDashboard from './components/ProducerDashboard.vue';

const loading = ref(true);
const account = ref('');
const contract = ref(null);
let web3;

onMounted(async () => {
  console.log("Inizializzazione Vinum Veritas...");

  if (window.ethereum) {
    window.ethereum.on('accountsChanged', (accounts) => {
      if (accounts.length > 0) account.value = accounts[0];
      else window.location.reload();
    });
    window.ethereum.on('chainChanged', () => window.location.reload());
  }

  try {
    if (!window.ethereum) {
      alert('MetaMask non rilevato!');
      return; 
    }

    web3 = new Web3(window.ethereum);
    
    // 1. Richiedi account
    const accountsDetected = await window.ethereum.request({ method: 'eth_requestAccounts' });
    
    // 2. Solo SE abbiamo un account procediamo
    if (accountsDetected && accountsDetected.length > 0) {
      account.value = accountsDetected[0];

      // 3. Inizializzazione Contratto
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = WineProductionJSON.networks[networkId];

      if (deployedNetwork) {
        contract.value = new web3.eth.Contract(
          WineProductionJSON.abi, 
          deployedNetwork.address
        );
        
        // 4. SOLO ORA, a connessione e contratto pronti, togliamo lo splash
        setTimeout(() => {
          loading.value = false;
        }, 1200);

      } else {
        alert("Contratto non trovato. Fai il deploy sulla rete corretta.");
        // Opzionale: loading.value resta true o rimandi a una pagina di errore
      }
    } else {
      // Se l'utente chiude MetaMask senza scegliere un account
      alert("Autenticazione necessaria per procedere.");
    }

  } catch (error) {
    console.error("Errore connessione:", error);
    alert("Devi autorizzare MetaMask per accedere.");
    // In caso di errore (es. utente rifiuta connessione), loading resta true 
    // impedendo l'accesso alla dashboard.
  }
});
</script>

<style>
/* Reset e stili base */
body {
  margin: 0;
  font-family: 'Inter', sans-serif;
  background-color: #fcfafb;
  color: #2c3e50;
  overflow-x: hidden;
}

.container { 
  max-width: 1200px; /* Allargato per ospitare meglio il dashboard */
  margin: 0 auto;
}

.fade-leave-active { transition: opacity 0.6s ease-out; }
.fade-leave-to { opacity: 0; }
</style>