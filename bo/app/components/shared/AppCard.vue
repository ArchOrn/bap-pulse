<template>
  <UCard :ui="{ body: `p-0 sm:p-0 h-full ${backgroundClass} shadow-sm rounded-md` }">
    <slot />
  </UCard>
</template>

<script setup lang="ts">
const props = defineProps<{
  secondary?: boolean
}>()

const backgroundClass = computed(() => {
  return props.secondary ? 'bg-zinc-100 dark:bg-zinc-900' : 'dark:bg-zinc-800 shadow-zinc-200 dark:shadow-zinc-950'
})
</script>
