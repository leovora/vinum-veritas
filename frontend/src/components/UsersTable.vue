<template>
  <table class="users-table">
    <thead class="table-header">
      <tr>
        <th>Address</th>
        <th>Nome</th>
        <th>Ruolo</th>
        <th class="actions" />
      </tr>
    </thead>
    <tbody>
      <tr v-for="user in users" :key="user.address">
        <td class="mono">{{ user.address }}</td>
        <td>{{ user.name || "-" }}</td>
        <td>
          <span class="role-badge">
            {{ getRoleLabel(user.role) }}
          </span>
        </td>
        <td class="actions">
          <button class="btn-delete" @click="remove(user.address)">
            Rimuovi
          </button>
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script setup>
const props = defineProps({
  users: {
    type: Array,
    required: true,
  },
  availableRoles: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(["remove"]);

const getRoleLabel = (role) =>
  props.availableRoles.find((r) => r.value === role)?.label || role;

const remove = (address) => {
  if (confirm("Vuoi davvero rimuovere questo utente?")) {
    emit("remove", address);
  }
};
</script>

<style scoped>
.users-table {
  width: 100%;
  border-collapse: collapse;
}

.users-table th {
  text-align: left;
  padding: 15px;
  background: var(--color-grigio-chiaro);
  font-size: 0.75rem;
  text-transform: uppercase;
  color: var(--color-grigio-scuro);
}

.users-table td {
  padding: 18px 15px;
  border-bottom: 1px solid var(--color-grigio-chiaro);
}

.actions {
  text-align: left;
}

.mono {
  font-family: monospace;
}

.role-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: bold;
  background: var(--badge-bianco);
  color: var(--color-text-dark);
}

/* bottone elimina */
.btn-delete {
  background: transparent;
  border: 1px solid var(--color-rosso);
  color: var(--color-rosso);
  padding: 6px 12px;
  border-radius: var(--btn-radius);
  font-size: 0.75rem;
  cursor: pointer;
}

.btn-delete:hover {
  background: var(--color-rosso);
  color: var(--color-bianco);
}
</style>
