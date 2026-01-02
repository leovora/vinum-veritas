<template>
  <div :class="['toast', type]">
    <div class="icon">
      <span v-if="type === 'success'">✅</span>
      <span v-else-if="type === 'error'">❌</span>
      <span v-else-if="type === 'info'">ℹ️</span>
    </div>
    <div class="message">{{ message }}</div>
  </div>
</template>

<script setup>
defineProps({
  message: { type: String, required: true },
  type: { type: String, default: 'success' }
});
</script>

<style scoped>
.toast {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 20px;
  border-radius: 14px;
  margin-bottom: 10px;
  color: white;
  font-weight: 600;
  font-size: 0.95rem;
  box-shadow: 0 8px 20px rgba(0,0,0,0.15);
  backdrop-filter: blur(4px);
  transform: translateX(120%);
  opacity: 0;
  animation: slideInOut 3s ease forwards;
}

.toast.success { background: linear-gradient(135deg,#27ae60,#2ecc71); }
.toast.error   { background: linear-gradient(135deg,#c0392b,#e74c3c); }
.toast.info    { background: linear-gradient(135deg,#2980b9,#3498db); }

.icon {
  font-size: 1.2rem;
  display: flex;
  align-items: center;
}

@keyframes slideInOut {
  0%   { transform: translateX(120%); opacity: 0; }  
  5%  { transform: translateX(0); opacity: 1; }     
  95%  { transform: translateX(0); opacity: 1; }     
  100% { transform: translateX(120%); opacity: 0; }  
}
</style>
