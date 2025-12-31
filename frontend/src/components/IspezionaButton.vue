<template>
  <div>
    <button @click="openDialog" class="btn-ispeziona">
      🔍 Ispeziona
    </button>

    <div v-if="dialogVisible" class="dialog-overlay" @click.self="closeDialog">
      <div class="dialog-content show">
        <LottoCard :lotto="lotto" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import LottoCard from './LottoCard.vue';

const props = defineProps({
  lotto: { type: Object, required: true }
});

const dialogVisible = ref(false);

const openDialog = () => dialogVisible.value = true;
const closeDialog = () => dialogVisible.value = false;
</script>

<style scoped>
.btn-ispeziona {
  background: #1a1a1a;
  color: white;
  border: none;
  padding: 8px 12px;
  border-radius: 6px;
  cursor: pointer;
  transition: 0.2s;
}
.btn-ispeziona:hover { background: #c0392b; }

.dialog-overlay {
  position: fixed;
  top:0; left:0;
  width:100%; height:100%;
  background: rgba(0,0,0,0.5);
  display:flex;
  justify-content:center;
  align-items:center;
  z-index:1000;
}
.dialog-content {
  opacity: 0;
  transform: translateY(-10px);
  transition: opacity 0.3s ease, transform 0.3s ease;
  padding:20px;
  border-radius:12px;
  max-width:700px;
  width:90%;
}
.dialog-content.show {
  opacity: 1;
  transform: translateY(0);
}
</style>
