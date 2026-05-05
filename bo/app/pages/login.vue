<script setup lang="ts">
definePageMeta({ layout: 'empty' })
useHead({ title: 'Connexion — BAP Pulse' })

const { signIn } = useAuth()

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
  } catch (e: unknown) {
    const code = (e as { code?: string })?.code
    if (code === 'auth/not-admin') {
      error.value = 'Accès refusé. Ce back-office est réservé aux administrateurs.'
    } else if (code === 'auth/invalid-credential' || code === 'auth/wrong-password' || code === 'auth/user-not-found') {
      error.value = 'Email ou mot de passe incorrect.'
    } else if (code === 'auth/too-many-requests') {
      error.value = 'Trop de tentatives. Réessaie dans quelques minutes.'
    } else {
      error.value = 'Une erreur est survenue. Réessaie.'
    }
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen flex">
    <!-- Left panel: BAP Pulse hero with logo watermark + sage gradient.
         Mirrors the Flutter auth screen vibe (dark green → near-black gradient,
         giant faded PulseLogo as a watermark in the corner). -->
    <div class="hidden lg:flex lg:w-1/2 flex-col items-center justify-center p-12 relative overflow-hidden bg-[#0b0f14]">
      <!-- Diagonal gradient (top-right → bottom-left) -->
      <div class="absolute inset-0 bg-gradient-to-bl from-[#13201a] via-[#0b0f14] to-[#06090c] pointer-events-none" />

      <!-- Off-canvas watermark logo, sage tinted at 5% opacity -->
      <BapPulseLogo
        :size="540"
        color="text-sage-500"
        class="absolute -top-32 -right-24 opacity-[0.06] pointer-events-none"
      />

      <!-- Subtle radial glow behind the foreground content -->
      <div class="absolute inset-0 flex items-center justify-center pointer-events-none">
        <div class="w-96 h-96 rounded-full bg-sage-500/10 blur-3xl" />
      </div>

      <div class="relative z-10 text-center space-y-6 max-w-xs">
        <BapPulseLogo
          :size="72"
          color="text-sage-500"
          class="mx-auto"
        />

        <div class="space-y-2">
          <h1 class="font-display text-4xl font-bold tracking-tight text-white">
            BAP Pulse
          </h1>
          <p class="text-sage-500/80 text-sm font-medium tracking-wide uppercase">
            Bad A Paname — Back-office
          </p>
        </div>

        <p class="text-white/55 text-sm leading-relaxed">
          Gère les joueurs, les matchs et le classement du club de badminton.
        </p>

        <!-- Decoration: court lines indicator, sage tinted -->
        <div class="flex items-center justify-center gap-1.5 pt-4">
          <div class="h-px w-8 bg-sage-500/30" />
          <div class="w-1.5 h-1.5 rounded-full bg-sage-500/70" />
          <div class="h-px w-8 bg-sage-500/30" />
        </div>
      </div>
    </div>

    <!-- Right panel: login form -->
    <div class="flex-1 flex flex-col items-center justify-center p-8 bg-default">
      <!-- Mobile logo (visible only on small screens) -->
      <div class="lg:hidden text-center mb-8 space-y-2">
        <BapPulseLogo
          :size="56"
          color="text-sage-500"
          class="mx-auto"
        />
        <p class="font-display text-2xl font-bold tracking-tight">
          BAP Pulse
        </p>
        <p class="text-sm text-muted">
          Back-office — Bad A Paname
        </p>
      </div>

      <div class="w-full max-w-sm space-y-6">
        <div class="space-y-1">
          <h2 class="font-display text-2xl font-bold tracking-tight">
            Connexion
          </h2>
          <p class="text-sm text-muted">
            Accès réservé aux administrateurs
          </p>
        </div>

        <UAlert
          v-if="error"
          icon="i-lucide-circle-alert"
          color="error"
          variant="subtle"
          :description="error"
        />

        <form
          class="space-y-4"
          @submit.prevent="handleSubmit"
        >
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
      </div>
    </div>
  </div>
</template>
