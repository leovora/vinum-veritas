<template>
  <div id="app">
    <SplashScreen v-if="loading" />

    <div v-else class="container">
      <h1>SimpleStorage Test</h1>

      <p>Valore attuale: {{ currentValue }}</p>

      <input type="number" v-model="newValue" placeholder="Nuovo valore" />
      <button @click="setValue">Aggiorna valore</button>

      <p v-if="txHash">Ultima transazione: {{ txHash }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import Web3 from 'web3';
import SimpleStorageABI from './abis/SimpleStorage.json';
// Importa il componente SplashScreen
import SplashScreen from './components/SplashScreen.vue';

const loading = ref(true); // Stato iniziale: caricamento in corso
const currentValue = ref(0);
const newValue = ref(0);
const txHash = ref('');

let web3;
let accounts;
let contract;

onMounted(async () => {
  console.log("Inizializzazione Vinum Veritas...");

  // CONTROLLO EVENTI REAL-TIME
  if (window.ethereum) {
    // Se l'utente cambia account, ricarichiamo la pagina per resettare lo stato
    window.ethereum.on('accountsChanged', (accounts) => {
      console.log("Account cambiato!");
      window.location.reload();
    });

    // Se l'utente cambia rete (es. da Mainnet a Ganache), ricarichiamo
    window.ethereum.on('chainChanged', (chainId) => {
      console.log("Rete cambiata!");
      window.location.reload();
    });
  }

  try {
    if (!window.ethereum) {
      alert('MetaMask non rilevato!');
      return;
    }

    web3 = new Web3(window.ethereum);
    
    // Richiesta connessione
    const accountsDetected = await window.ethereum.request({ method: 'eth_requestAccounts' });
    
    if (accountsDetected && accountsDetected.length > 0) {
      accounts = accountsDetected;

      const networkId = await web3.eth.net.getId();
      const deployedNetwork = SimpleStorageABI.networks[networkId];

      if (!deployedNetwork) {
        // Se la rete è sbagliata, non impostiamo loading a false
        // così lo splashscreen rimane attivo e l'utente sa che deve cambiare rete
        console.error("Contratto non trovato su questa rete!");
        alert(`Cambia rete su MetaMask! Il contratto non è attivo sulla rete ${networkId}`);
        return; 
      }

      contract = new web3.eth.Contract(
        SimpleStorageABI.abi,
        deployedNetwork.address
      );

      currentValue.value = await contract.methods.getValue().call();

      // Transizione: Spegniamo lo splash screen
      loading.value = false; 
    }

  } catch (error) {
    console.error("Errore connessione:", error);
    // In caso di errore (es. utente chiude il popup), ricarichiamo dopo un po'
    // o mostriamo un messaggio chiaro
  }
});

async function setValue() {
  try {
    const receipt = await contract.methods
      .setValue(newValue.value)
      .send({ from: accounts[0] });

    txHash.value = receipt.transactionHash;

    const val = await contract.methods.getValue().call();
    currentValue.value = val;
  } catch (error) {
    console.error("Errore nell'invio della transazione:", error);
  }
}
</script>

<style>
/* Stili per evitare scroll durante il caricamento */
#app {
  font-family: Arial, sans-serif;
}
.container { max-width: 400px; margin: 50px auto; text-align: center; }
input { margin: 10px 0; padding: 5px; width: 100px; }
button { padding: 5px 10px; cursor: pointer; }
</style>