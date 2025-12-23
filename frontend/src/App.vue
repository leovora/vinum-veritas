<!-- src/App.vue -->
<template>
  <AppHeader />
  <transition name="fade">
    <router-view />
  </transition>
</template>

<script setup>
import { ref, onMounted, provide } from "vue";
import { useRouter } from "vue-router";
import AppHeader from "./components/AppHeader.vue";
import Web3 from "web3";
import WineProduction from "./abis/WineProduction.json";
import { useUserStore } from './stores/user'


const router = useRouter();

const account = ref("");
const role = ref("");
const contract = ref(null);
let web3;

const userStore = useUserStore()

provide("userAddress", account);
provide("userRole", role);
provide("contractInstance", contract);

//TODO: fare chiamata a contratto per ottenere ruolo reale
const getUserRole = async () => {
  return "admin";
};

onMounted(async () => {
  try {
    const web3 = new Web3(window.ethereum);

    const accounts = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    account.value = accounts[0];

    const networkId = await web3.eth.net.getId();
    const deployed = WineProduction.networks[networkId];

    contract.value = new web3.eth.Contract(
      WineProduction.abi,
      deployed.address
    );

    role.value = await getUserRole();

    userStore.account = account.value
    userStore.role = role.value

    setTimeout(() => {
      if (role.value === "admin") {
        router.replace("/producer");
      } else {
        router.replace("/update");
      }
    }, 1000);
  } catch (err) {
    console.error("Errore durante inizializzazione:", err);
    alert("Errore inizializzazione applicazione");
  }
});
</script>

<style>
@import "./assets/styles/vinum.css";
</style>
