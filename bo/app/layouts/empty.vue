<template>
  <div class="w-full h-screen relative">
    <UColorModeButton
      class="absolute top-4 right-4"
      variant="ghost"
      size="sm"
      color="primary"
    />
    <slot />
  </div>
</template>
