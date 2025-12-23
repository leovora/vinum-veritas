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
import { ref, onMounted, computed } from 'vue';
import Web3 from 'web3';
// Importiamo il nuovo contratto WineProduction
import WineProductionJSON from './abis/WineProduction.json';
import SplashScreen from './views/SplashView.vue';
import ProducerDashboard from './views/ProducerView.vue';

// STATI REATTIVI
const loading = ref(true);
const account = ref('');
const contract = ref(null);
let web3;

onMounted(async () => {
  console.log("Inizializzazione Vinum Veritas - Connessione Blockchain...");

  // Gestione cambi account o rete
  if (window.ethereum) {
    window.ethereum.on('accountsChanged', (accounts) => {
      if (accounts.length > 0) account.value = accounts[0];
      else window.location.reload();
    });
    window.ethereum.on('chainChanged', () => window.location.reload());
  }

  try {
    if (!window.ethereum) {
      alert('MetaMask non rilevato! Installa l\'estensione.');
      return;
    }

    web3 = new Web3(window.ethereum);
    
    // Richiesta accesso
    const accountsDetected = await window.ethereum.request({ method: 'eth_requestAccounts' });
    
    if (accountsDetected && accountsDetected.length > 0) {
      account.value = accountsDetected[0];

      // Inizializzazione Contratto WineProduction
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = WineProductionJSON.networks[networkId];

      if (deployedNetwork) {
        // Creiamo l'istanza del contratto reale
        contract.value = new web3.eth.Contract(
          WineProductionJSON.abi, 
          deployedNetwork.address
        );
        console.log("Smart Contract WineProduction collegato a:", deployedNetwork.address);
      } else {
        alert("Smart Contract non trovato sulla rete attuale. Assicurati di aver fatto 'truffle migrate'.");
      }

      // Spegnimento SplashScreen
      setTimeout(() => {
        loading.value = false;
      }, 1200);
    }

  } catch (error) {
    console.error("Errore connessione:", error);
    alert("Devi autorizzare MetaMask per accedere.");
  }
});
</script>

