<script setup lang="ts">
// Tintable "BAP" wordmark (the club brand).
// ~1.64:1 aspect ratio (viewBox 564 × 344). We size by height and let width
// follow.

withDefaults(defineProps<{
  height?: number | string
  /** Tailwind text-color utility, e.g. "text-white". */
  color?: string
}>(), {
  height: 28,
  color: 'text-current'
})
</script>

<template>
  <span
    class="bap-wordmark inline-block shrink-0"
    :class="color"
    :style="{
      height: typeof height === 'number' ? `${height}px` : height,
      width: typeof height === 'number' ? `${height * 1.64}px` : `calc(${height} * 1.64)`
    }"
    aria-hidden="true"
  />
</template>
