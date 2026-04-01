<script setup lang="ts">
const route = useRoute()
const userId = route.params.id as string

useHead({ title: 'Modifier un joueur — BAP Pulse' })

const { baseURL, authHeaders } = useApi()

const { data: user, status } = await useFetch<User>(`${baseURL}/users/${userId}`, {
  headers: authHeaders()
})

const fullName = (u: User) => [u.first_name, u.last_name].filter(Boolean).join(' ')

const form = reactive({ first_name: '', last_name: '', email: '' })
const loading = ref(false)
const error = ref<string | null>(null)
const success = ref(false)

watch(user, (u) => {
  if (u) {
    form.first_name = u.first_name
    form.last_name = u.last_name
    form.email = u.email
  }
}, { immediate: true })

const handleSubmit = async () => {
  error.value = null
  success.value = false
  loading.value = true
  try {
    await $fetch(`${baseURL}/users/${userId}`, {
      method: 'PUT',
      headers: authHeaders(),
      body: form
    })
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
