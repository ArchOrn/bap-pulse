<template>
  <UCard :ui="{ body: `p-0 sm:p-0 h-full ${backgroundClass} shadow-sm rounded-xl` }">
    <slot />
  </UCard>
</template>

<script setup lang="ts">
// AppCard: BAP Pulse-flavored surface.
//
// Default → bg-bap-card in dark, white in light. Secondary → bg-bap-elevated
// (one step up the elevation ladder). The colors come from CSS vars in
// assets/css/main.css and mirror the Flutter app's bgCard / bgCardElevated.
const props = defineProps<{
  secondary?: boolean
}>()

const backgroundClass = computed(() => {
  return props.secondary
    ? 'bg-zinc-100 dark:bg-[var(--color-bap-elevated)] ring-1 ring-white/5'
    : 'bg-white dark:bg-[var(--color-bap-card)] ring-1 ring-zinc-200/60 dark:ring-white/5 shadow-zinc-200 dark:shadow-black/40'
})
</script>
