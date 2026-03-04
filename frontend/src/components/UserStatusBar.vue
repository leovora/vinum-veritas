<!--
  UserStatusBar.vue

  Componente per mostrare il ruolo dell’utente loggato.
-->

<template>
  <div class="user-status-bar" v-if="role">
    Loggato come: <strong>{{ role }}</strong>
  </div>
</template>
<script setup>
defineProps({
  role: {
    type: String,
    required: true,
  },
});
</script>
<style scoped>
.user-status-bar {
  background: #333;
  color: #fff;
  padding: 10px 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  text-align: center;
  font-size: 0.9rem;
  margin-right: -10px;
  margin-left: -10px;
}
</style>
