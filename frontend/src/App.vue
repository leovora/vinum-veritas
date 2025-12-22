<template>
  <transition name="fade">
    <SplashScreen v-if="loading" />
  </transition>
  <ProducerView v-if="!loading" :user-address="account" :contract-instance="contract" />
</template>

<script setup>
import { ref, onMounted } from 'vue';
import Web3 from 'web3';
import WineProduction from './abis/WineProduction.json';
import SplashScreen from './views/SplashView.vue';
import ProducerView from './views/ProducerView.vue';

const loading = ref(true);
const account = ref('');
const contract = ref(null);

onMounted(async () => {
  const web3 = new Web3(window.ethereum);
  const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
  account.value = accounts[0];

  const networkId = await web3.eth.net.getId();
  const deployed = WineProduction.networks[networkId];

  contract.value = new web3.eth.Contract(WineProduction.abi, deployed.address);

  setTimeout(() => loading.value = false, 1000);
});
</script>

<style>
@import './assets/styles/vinum.css';
</style>
