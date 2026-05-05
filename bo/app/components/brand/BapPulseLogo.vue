<script setup lang="ts">
// Tintable BAP Pulse mark.
//
// Renders the SVG silhouette through CSS mask-image (see assets/css/main.css)
// so the icon inherits its color from `text-*` utilities — same trick as the
// Flutter app's PulseLogo with its ColorFilter tint.
//
// Square aspect ratio (viewBox is roughly 1:1).

withDefaults(defineProps<{
  size?: number | string
  /** Tailwind text-color utility, e.g. "text-sage-500". */
  color?: string
}>(), {
  size: 32,
  color: 'text-sage-500'
})
</script>

<template>
  <span
    class="bap-pulse-mark inline-block shrink-0"
    :class="color"
    :style="{ width: typeof size === 'number' ? `${size}px` : size, height: typeof size === 'number' ? `${size}px` : size }"
    aria-hidden="true"
  />
</template>
