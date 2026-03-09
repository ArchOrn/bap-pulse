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
    <div class="min-h-screen flex">
      <!-- Left panel: dark, badminton-themed -->
      <div class="hidden lg:flex lg:w-1/2 bg-zinc-950 court-pattern flex-col items-center justify-center p-12 relative">
        <!-- Subtle radial glow behind logo -->
        <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
          <div class="w-96 h-96 rounded-full bg-green-400/5 blur-3xl" />
        </div>

        <div class="relative z-10 text-center space-y-6 max-w-xs">
          <!-- Icon -->
          <div class="w-20 h-20 mx-auto rounded-2xl bg-green-400/10 border border-green-400/20 flex items-center justify-center text-4xl">
            🏸
          </div>

          <!-- Title -->
          <div class="space-y-2">
            <h1 class="text-3xl font-bold text-white tracking-tight">BAP Pulse</h1>
            <p class="text-zinc-400 text-sm">Bad A Paname — Back-office</p>
          </div>

          <!-- Tagline -->
          <p class="text-zinc-500 text-sm leading-relaxed">
            Gère les joueurs, les matchs et le classement du club de badminton.
          </p>

          <!-- Decoration: court lines indicator -->
          <div class="flex items-center justify-center gap-1.5 pt-4">
            <div class="h-px w-8 bg-green-400/30" />
            <div class="w-1.5 h-1.5 rounded-full bg-green-400/50" />
            <div class="h-px w-8 bg-green-400/30" />
          </div>
        </div>
      </div>

      <!-- Right panel: login form -->
      <div class="flex-1 flex flex-col items-center justify-center p-8 bg-default">
        <!-- Mobile logo (visible only on small screens) -->
        <div class="lg:hidden text-center mb-8 space-y-1">
          <p class="text-2xl font-bold tracking-tight">🏸 BAP Pulse</p>
          <p class="text-sm text-muted">Back-office — Bad A Paname</p>
        </div>

        <div class="w-full max-w-sm space-y-6">
          <div class="space-y-1">
            <h2 class="text-xl font-bold">Connexion</h2>
            <p class="text-sm text-muted">Accès réservé aux administrateurs</p>
          </div>

          <UAlert
            v-if="error"
            icon="i-lucide-circle-alert"
            color="error"
            variant="subtle"
            :description="error"
          />

          <form class="space-y-4" @submit.prevent="handleSubmit">
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
      </div>
    </div>
  </UApp>
</template>
