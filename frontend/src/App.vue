<template>
  <div class="container">
    <h1>SimpleStorage Test</h1>

    <p>Valore attuale: {{ currentValue }}</p>

    <input type="number" v-model="newValue" placeholder="Nuovo valore" />
    <button @click="setValue">Aggiorna valore</button>

    <p v-if="txHash">Ultima transazione: {{ txHash }}</p>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import Web3 from 'web3';
import SimpleStorageABI from './abis/SimpleStorage.json';

const currentValue = ref(0);
const newValue = ref(0);
const txHash = ref('');

let web3;
let accounts;
let contract;

onMounted(async () => {
  if (!window.ethereum) {
    alert('MetaMask non rilevato!');
    return;
  }

  web3 = new Web3(window.ethereum);
  await window.ethereum.request({ method: 'eth_requestAccounts' });
  accounts = await web3.eth.getAccounts();

  const networkId = await web3.eth.net.getId();
  const deployedNetwork = SimpleStorageABI.networks[networkId];

  if (!deployedNetwork) {
    alert('Contratto non deployato su questa rete');
    return;
  }

  contract = new web3.eth.Contract(
    SimpleStorageABI.abi,
    deployedNetwork.address
  );

  currentValue.value = await contract.methods.getValue().call();
});


async function setValue() {
  const receipt = await contract.methods
    .setValue(newValue.value)
    .send({ from: accounts[0] });

  txHash.value = receipt.transactionHash;

  const val = await contract.methods.getValue().call();
  currentValue.value = val;
}
</script>

<style>
.container { max-width: 400px; margin: 50px auto; text-align: center; }
input { margin: 10px 0; padding: 5px; width: 100px; }
button { padding: 5px 10px; }
</style>
