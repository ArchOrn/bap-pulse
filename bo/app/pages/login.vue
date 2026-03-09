<script setup lang="ts">

definePageMeta({ layout: false })
useHead({ title: 'Connexion — BAP Pulse' })

const { signIn, signInWithGoogle } = useAuth()

const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref<string | null>(null)

const handleSubmit = async () => {
  error.value = null
  loading.value = true
  try {
    await signIn(email.value, password.value)
    await navigateTo('/')
  }
  catch (e: unknown) {
    const code = (e as { code?: string })?.code
    if (code === 'auth/not-admin') {
      error.value = 'Accès refusé. Ce back-office est réservé aux administrateurs.'
    }
    else if (code === 'auth/invalid-credential' || code === 'auth/wrong-password' || code === 'auth/user-not-found') {
      error.value = 'Email ou mot de passe incorrect.'
    }
    else if (code === 'auth/too-many-requests') {
      error.value = 'Trop de tentatives. Réessaie dans quelques minutes.'
    }
    else {
      error.value = 'Une erreur est survenue. Réessaie.'
    }
  }
  finally {
    loading.value = false
  }
}

const handleGoogle = async () => {
  error.value = null
  loading.value = true
  try {
    await signInWithGoogle()
    await navigateTo('/')
  }
  catch (e: unknown) {
    const code = (e as { code?: string })?.code
    if (code === 'auth/not-admin') {
      error.value = 'Accès refusé. Ce back-office est réservé aux administrateurs.'
    }
    else {
      error.value = 'Connexion Google annulée ou échouée.'
    }
  }
  finally {
    loading.value = false
  }
}
</script>

<template>
  <UApp>
    <div class="min-h-screen flex items-center justify-center bg-default p-4">
      <div class="w-full max-w-sm space-y-6">
        <!-- Logo -->
        <div class="text-center space-y-1">
          <p class="text-2xl font-bold tracking-tight">BAP Pulse</p>
          <p class="text-sm text-muted">Back-office — Bad A Paname</p>
        </div>

        <UCard>
          <div class="space-y-4">
            <div class="space-y-1">
              <p class="text-base font-semibold">Connexion</p>
              <p class="text-xs text-muted">Connecte-toi avec ton compte Firebase</p>
            </div>

            <UAlert
              v-if="error"
              icon="i-lucide-circle-alert"
              color="error"
              variant="subtle"
              :description="error"
            />

            <form class="space-y-3" @submit.prevent="handleSubmit">
              <UFormField label="Email">
                <UInput
                  v-model="email"
                  type="email"
                  placeholder="toi@example.com"
                  autocomplete="email"
                  required
                  class="w-full"
                />
              </UFormField>

              <UFormField label="Mot de passe">
                <UInput
                  v-model="password"
                  type="password"
                  placeholder="••••••••"
                  autocomplete="current-password"
                  required
                  class="w-full"
                />
              </UFormField>

              <UButton
                type="submit"
                color="primary"
                class="w-full justify-center"
                :loading="loading"
              >
                Se connecter
              </UButton>
            </form>

            <div class="relative flex items-center gap-3">
              <div class="flex-1 border-t border-default" />
              <span class="text-xs text-muted">ou</span>
              <div class="flex-1 border-t border-default" />
            </div>

            <UButton
              variant="outline"
              color="neutral"
              class="w-full justify-center gap-2"
              :loading="loading"
              @click="handleGoogle"
            >
              <UIcon name="i-simple-icons-google" class="size-4" />
              Continuer avec Google
            </UButton>
          </div>
        </UCard>
      </div>
    </div>
  </UApp>
</template>
