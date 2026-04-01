<script setup lang="ts">
const route = useRoute()
const userId = route.params.id as string

const { baseURL, authHeaders } = useApi()

const { data: user, status } = await useFetch<User>(`${baseURL}/users/${userId}`, {
  headers: authHeaders()
})

const fullName = (u: User) => [u.first_name, u.last_name].filter(Boolean).join(' ')

useHead({ title: computed(() => user.value ? `${fullName(user.value)} — BAP Pulse` : 'Joueur — BAP Pulse') })

const isAdmin = computed(() => user.value?.role === 'admin')
const roleLoading = ref(false)
const roleError = ref<string | null>(null)

const toggleRole = async () => {
  if (!user.value) return
  roleError.value = null
  roleLoading.value = true
  try {
    await $fetch(`${baseURL}/admin/users/${userId}/role`, {
      method: 'POST',
      headers: authHeaders(),
      body: { admin: !isAdmin.value }
    })
    user.value = { ...user.value, role: isAdmin.value ? 'player' : 'admin' }
  } catch (e: unknown) {
    const msg = (e as { data?: { error?: string } })?.data?.error
    roleError.value = msg ?? 'Erreur lors du changement de rôle.'
  } finally {
    roleLoading.value = false
  }
}

const breadcrumbs = computed(() => [
  { label: 'Joueurs', to: '/users', icon: 'i-lucide-users' },
  { label: user.value ? fullName(user.value) || user.value.email : '…' }
])

const infoItems = computed(() => {
  if (!user.value) return []
  return [
    { label: 'Email', value: user.value.email, icon: 'i-lucide-mail' },
    { label: 'ELO', value: String(user.value.elo), icon: 'i-lucide-trophy' },
    { label: 'Rôle', value: isAdmin.value ? 'Administrateur' : 'Joueur', icon: 'i-lucide-shield' },
    { label: 'Inscrit le', value: new Date(user.value.created_at).toLocaleDateString('fr-FR'), icon: 'i-lucide-calendar' }
  ]
})
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
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-4">
          <UAvatar
            :alt="fullName(user)?.[0]?.toUpperCase() ?? '?'"
            size="lg"
            class="ring-1 ring-neutral-200 dark:ring-neutral-700"
          />
          <div>
            <h1 class="text-2xl font-bold">
              {{ fullName(user) || user.email }}
            </h1>
            <p class="text-sm text-muted mt-0.5">
              {{ user.email }}
            </p>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <UButton
            icon="i-lucide-pencil"
            variant="outline"
            color="neutral"
            size="sm"
            :to="`/users/${userId}/edit`"
          >
            Modifier
          </UButton>
          <UButton
            :icon="isAdmin ? 'i-lucide-shield-minus' : 'i-lucide-shield-plus'"
            :color="isAdmin ? 'error' : 'neutral'"
            variant="outline"
            size="sm"
            :loading="roleLoading"
            @click="toggleRole"
          >
            {{ isAdmin ? 'Révoquer admin' : 'Promouvoir admin' }}
          </UButton>
        </div>
      </div>

      <UAlert
        v-if="roleError"
        icon="i-lucide-circle-alert"
        color="error"
        variant="subtle"
        :description="roleError"
      />

      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <AppCard
          v-for="item in infoItems"
          :key="item.label"
        >
          <div class="flex items-center gap-3 p-4">
            <UIcon
              :name="item.icon"
              class="size-5 text-neutral-400 shrink-0"
            />
            <div>
              <p class="text-xs text-muted">
                {{ item.label }}
              </p>
              <p class="text-sm font-semibold">
                {{ item.value }}
              </p>
            </div>
          </div>
        </AppCard>
      </div>

      <AppCard>
        <div class="p-6">
          <p class="text-sm font-semibold text-neutral-500 dark:text-neutral-400 uppercase tracking-wide mb-4">
            Rôle & permissions
          </p>
          <div class="flex items-center gap-3">
            <UBadge
              :label="isAdmin ? 'Admin' : 'Joueur'"
              :color="isAdmin ? 'primary' : 'neutral'"
              variant="subtle"
            />
            <p class="text-sm text-muted">
              {{ isAdmin ? 'Accès complet au back-office' : 'Accès joueur uniquement' }}
            </p>
          </div>
        </div>
      </AppCard>
    </template>
  </div>
</template>
