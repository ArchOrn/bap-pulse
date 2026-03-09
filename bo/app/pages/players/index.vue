<script setup lang="ts">
// Redirect legacy /players route to /users.
await navigateTo('/users', { replace: true })
</script>

<template>
  <div />
</template>
