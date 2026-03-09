<script setup lang="ts">

definePageMeta({ layout: false })
useHead({ title: 'Accès refusé — BAP Pulse' })

const { user, signOut } = useAuth()
</script>

<template>
  <UApp>
    <div class="min-h-screen flex items-center justify-center bg-default p-4">
      <UCard class="w-full max-w-sm text-center">
        <div class="space-y-4 py-4">
          <UIcon name="i-lucide-shield-x" class="size-12 text-error mx-auto" />

          <div class="space-y-1">
            <p class="text-xl font-bold">Accès refusé</p>
            <p class="text-sm text-muted">
              Le compte <span class="font-medium">{{ user?.email }}</span>
              n'a pas les droits d'accès au back-office.
            </p>
          </div>

          <p class="text-xs text-muted">
            Contacte un administrateur pour obtenir les droits nécessaires.
          </p>

          <UButton
            variant="outline"
            color="neutral"
            icon="i-lucide-log-out"
            class="w-full justify-center"
            @click="signOut"
          >
            Se déconnecter
          </UButton>
        </div>
      </UCard>
    </div>
  </UApp>
</template>
