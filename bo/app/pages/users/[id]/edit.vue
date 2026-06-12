<script setup lang="ts">
import type { Gender, FfbadRank } from '~~/shared/types/api'

const route = useRoute()
const userId = route.params.id as string

useHead({ title: 'Modifier un joueur — BAP Pulse' })

const { baseURL, authHeaders } = useApi()
const { genderOptions, ffbadOptions } = useUserOptions()

const { data: user, status } = await useFetch<User>(`${baseURL}/users/${userId}`, {
  headers: authHeaders()
})

const fullName = (u: User) => [u.first_name, u.last_name].filter(Boolean).join(' ')

interface FormState {
  first_name: string
  last_name: string
  email: string
  gender: Gender | ''
  ffbad_rank: FfbadRank | ''
}

const form = reactive<FormState>({
  first_name: '',
  last_name: '',
  email: '',
  gender: '',
  ffbad_rank: ''
})

const hasPlayedMatch = computed(() => {
  if (!user.value) return true
  return user.value.elo_singles !== user.value.elo_doubles
    || user.value.elo_singles !== user.value.elo_mixed
})

const loading = ref(false)
const error = ref<string | null>(null)
const success = ref(false)

watch(user, (u) => {
  if (u) {
    form.first_name = u.first_name
    form.last_name = u.last_name
    form.email = u.email
    form.gender = u.gender ?? ''
    form.ffbad_rank = u.ffbad_rank ?? ''
  }
}, { immediate: true })

const handleSubmit = async () => {
  error.value = null
  success.value = false
  loading.value = true
  try {
    const updated = await $fetch<User>(`${baseURL}/users/${userId}`, {
      method: 'PUT',
      headers: authHeaders(),
      body: form
    })
    user.value = updated
    success.value = true
  } catch (e: unknown) {
    const msg = (e as { data?: { error?: string } })?.data?.error
    error.value = msg ?? 'Une erreur est survenue.'
  } finally {
    loading.value = false
  }
}

const breadcrumbs = computed(() => [
  { label: 'Joueurs', to: '/users', icon: 'i-lucide-users' },
  { label: user.value ? fullName(user.value) || user.value.email : '…', to: `/users/${userId}` },
  { label: 'Modifier' }
])
</script>

<template>
  <div class="space-y-6">
    <UBreadcrumb :items="breadcrumbs" />

    <div
      v-if="status === 'pending'"
      class="space-y-4"
    >
      <USkeleton class="h-8 w-48" />
      <USkeleton class="h-64 w-full" />
    </div>

    <template v-else-if="user">
      <h1 class="text-2xl font-bold">
        Modifier {{ fullName(user) || user.email }}
      </h1>

      <UAlert
        v-if="success"
        icon="i-lucide-check-circle"
        color="success"
        variant="subtle"
        title="Modifications enregistrées"
      />

      <UAlert
        v-if="error"
        icon="i-lucide-circle-alert"
        color="error"
        variant="subtle"
        :description="error"
      />

      <AppCard>
        <form
          class="p-6 space-y-5"
          @submit.prevent="handleSubmit"
        >
          <p class="text-sm font-semibold text-neutral-500 dark:text-neutral-400 uppercase tracking-wide">
            Informations
          </p>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <UFormField label="Prénom">
              <UInput
                v-model="form.first_name"
                placeholder="Prénom"
                size="xl"
                class="w-full"
              />
            </UFormField>

            <UFormField label="Nom">
              <UInput
                v-model="form.last_name"
                placeholder="Nom"
                size="xl"
                class="w-full"
              />
            </UFormField>
          </div>

          <UFormField label="Email">
            <UInput
              v-model="form.email"
              type="email"
              placeholder="joueur@example.com"
              size="xl"
              class="w-full"
            />
          </UFormField>

          <p class="text-sm font-semibold text-neutral-500 dark:text-neutral-400 uppercase tracking-wide pt-2">
            Profil sportif
          </p>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <UFormField label="Genre">
              <USelect
                v-model="form.gender"
                :items="genderOptions"
                value-key="value"
                size="xl"
                class="w-full"
              />
            </UFormField>

            <UFormField
              label="Classement FFBAD"
              :hint="hasPlayedMatch ? 'Modifiable mais n\'affecte plus l\'ELO (matchs déjà joués)' : 'Ré-initialise les ELO si modifié avant le 1er match'"
            >
              <USelect
                v-model="form.ffbad_rank"
                :items="ffbadOptions"
                value-key="value"
                size="xl"
                class="w-full"
              />
            </UFormField>
          </div>

          <div class="flex items-center gap-3 pt-2">
            <UButton
              type="submit"
              icon="i-lucide-check"
              :loading="loading"
            >
              Enregistrer
            </UButton>
            <UButton
              variant="ghost"
              color="neutral"
              :to="`/users/${userId}`"
            >
              Annuler
            </UButton>
          </div>
        </form>
      </AppCard>
    </template>
  </div>
</template>
