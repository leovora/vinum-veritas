<template>
  <div class="toast-container">
    <Toast v-for="t in toasts" :key="t.id" :message="t.message" :type="t.type" />
  </div>
</template>

<script setup>
import Toast from './Toast.vue';
import { useToast } from './utils/useToast.js';

const { toasts } = useToast();
</script>

<style scoped>
.toast-container {
  position: fixed;
  top: 20px;
  right: 20px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  z-index: 2000;
}
</style>
