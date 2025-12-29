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

import AppHeader from "./components/AppHeader.vue";
import SplashScreen from "./views/SplashView.vue";
import WineProductionJSON from "./abis/WineProduction.json";
import { useUserStore } from "./stores/user";

const router = useRouter();
const userStore = useUserStore();

const loading = ref(true);
const contract = ref(null);

provide("contractInstance", contract);

/**
 * Recupera il ruolo dell'utente dal contratto
 * Se non è assegnato ritorna "VISITATORE"
 */
const getUserRole = async (address) => {
  if (!contract.value) return "VISITATORE";

  try {
    const roleHash = await contract.value.methods.roles(address).call();

    if (
      roleHash ===
      "0x0000000000000000000000000000000000000000000000000000000000000000"
    ) {
      return "VISITATORE";
    }

    const rolesMap = {
      [Web3.utils.keccak256("ADMIN")]: "ADMIN",
      [Web3.utils.keccak256("AGRICOLTORE")]: "AGRICOLTORE",
      [Web3.utils.keccak256("SUPERVISORE")]: "SUPERVISORE",
      [Web3.utils.keccak256("CANTINIERE")]: "CANTINIERE",
      [Web3.utils.keccak256("CORRIERE")]: "CORRIERE",
      [Web3.utils.keccak256("DISTRIBUTORE")]: "DISTRIBUTORE",
    };

    return rolesMap[roleHash] || "VISITATORE";
  } catch (err) {
    console.error("Errore lettura ruolo:", err);
    return "VISITATORE";
  }
};

/**
 * MOCK — in futuro verrà sostituita con chiamata on-chain
 */
const getUserRole_MOCK = async (address) => {
  // TODO:
  // const roleHash = await contract.value.methods.roles(address).call();
  // return decodeRole(roleHash);
  return "ADMIN";
}

onMounted(async () => {
  console.log("Vinum Veritas — Avvio dApp");

  if (!window.ethereum) {
    alert("MetaMask non rilevato. Installa l'estensione.");
    return;
  }

  window.ethereum.on("accountsChanged", () => window.location.reload());
  window.ethereum.on("chainChanged", () => window.location.reload());

  try {
    const web3 = new Web3(window.ethereum);
    const accounts = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    if (!accounts.length) return;

    const account = accounts[0];

    const networkId = await web3.eth.net.getId();
    const deployed = WineProductionJSON.networks[networkId];
    if (!deployed) throw new Error("Contratto non trovato sulla rete corrente");

    contract.value = new web3.eth.Contract(
      WineProductionJSON.abi,
      deployed.address
    );

    // Recupero ruolo reale dal contratto
    const role = await getUserRole_MOCK(account);
    userStore.setUser(account, role);

    setTimeout(() => {
      loading.value = false;

      if (userStore.isAdmin) router.replace("/producer");
      else if (userStore.isVisitatore) router.replace("/search");
      else router.replace("/update");
    }, 1200);
  } catch (err) {
    console.error("Errore inizializzazione:", err);
    alert("Errore di connessione alla Blockchain");
  }
});
</script>

<style>
@import "./assets/styles/vinum.css";
</style>
