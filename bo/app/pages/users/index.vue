<script setup lang="ts">
useHead({ title: 'Joueurs — BAP Pulse' })

const { baseURL, authHeaders } = useApi()
const { statusBadge } = useUserOptions()

const { data: users, status, error, refresh } = await useFetch<User[]>(`${baseURL}/users`, {
  headers: authHeaders()
})

const fullName = (u: User) => [u.first_name, u.last_name].filter(Boolean).join(' ')

const pendingCount = computed(() =>
  (users.value ?? []).filter(u => u.status === 'pending').length
)

// ---- Table columns ----
const columns = [
  { accessorKey: 'name', header: 'Nom' },
  { accessorKey: 'email', header: 'Email' },
  { accessorKey: 'ffbad_rank', header: 'FFBAD' },
  { accessorKey: 'elo_singles', header: 'ELO S' },
  { accessorKey: 'elo_doubles', header: 'ELO D' },
  { accessorKey: 'elo_mixed', header: 'ELO M' },
  { accessorKey: 'status', header: 'Statut' },
  { accessorKey: 'role', header: 'Rôle' },
  { accessorKey: 'created_at', header: 'Inscrit le' },
  { accessorKey: 'actions', header: '' }
]

const rows = computed(() =>
  (users.value ?? []).map(u => ({
    ...u,
    name: fullName(u),
    ffbad_rank: u.ffbad_rank ?? '—',
    created_at: new Date(u.created_at).toLocaleDateString('fr-FR')
  }))
)

// ---- Invite modal ----
const showInvite = ref(false)
const inviteForm = reactive({ first_name: '', last_name: '', email: '' })
const inviteLoading = ref(false)
const inviteResult = ref<{ user: User, temp_password: string } | null>(null)
const inviteError = ref<string | null>(null)

const openInvite = () => {
  inviteForm.first_name = ''
  inviteForm.last_name = ''
  inviteForm.email = ''
  inviteError.value = null
  inviteResult.value = null
  showInvite.value = true
}

const handleInvite = async () => {
  inviteError.value = null
  inviteLoading.value = true
  try {
    const res = await $fetch<{ user: User, temp_password: string }>(`${baseURL}/admin/invite`, {
      method: 'POST',
      headers: authHeaders(),
      body: inviteForm
    })
    inviteResult.value = res
    await refresh()
  } catch (e: unknown) {
    const msg = (e as { data?: { error?: string } })?.data?.error
    inviteError.value = msg ?? 'Une erreur est survenue.'
  } finally {
    inviteLoading.value = false
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold">
          Joueurs
        </h1>
        <p class="text-sm text-muted mt-1">
          {{ rows.length }} joueur{{ rows.length !== 1 ? 's' : '' }} inscrits
        </p>
      </div>

      <div class="flex items-center gap-2">
        <UButton
          icon="i-lucide-user-check"
          color="neutral"
          variant="outline"
          to="/users/pending"
        >
          Validations
          <UBadge
            v-if="pendingCount > 0"
            :label="String(pendingCount)"
            color="warning"
            variant="solid"
            size="sm"
          />
        </UButton>
        <UButton
          icon="i-lucide-refresh-cw"
          color="neutral"
          variant="outline"
          to="/users/roster"
        >
          Roster FFBAD
        </UButton>
        <UButton
          icon="i-lucide-user-plus"
          @click="openInvite"
        >
          Inviter un joueur
        </UButton>
      </div>
    </div>

    <AppCard>
      <div
        v-if="status === 'pending'"
        class="space-y-2 p-4"
      >
        <USkeleton
          v-for="i in 8"
          :key="i"
          class="h-8 w-full"
        />
      </div>

      <UAlert
        v-else-if="error"
        icon="i-lucide-triangle-alert"
        color="error"
        title="Impossible de charger les joueurs"
        :description="error.message"
      />

      <UTable
        v-else
        :data="rows"
        :columns="columns"
      >
        <template #status-cell="{ row }">
          <UBadge
            :label="statusBadge(row.original.status).label"
            :color="statusBadge(row.original.status).color"
            variant="subtle"
          />
        </template>

        <template #role-cell="{ row }">
          <UBadge
            :label="row.original.role === 'admin' ? 'Admin' : 'Joueur'"
            :color="row.original.role === 'admin' ? 'primary' : 'neutral'"
            variant="subtle"
          />
        </template>

        <template #actions-cell="{ row }">
          <UButton
            icon="i-lucide-eye"
            color="neutral"
            variant="ghost"
            size="xs"
            title="Voir le profil"
            :to="`/users/${row.original.id}`"
          />
        </template>
      </UTable>
    </AppCard>

    <!-- Invite modal -->
    <UModal
      v-model:open="showInvite"
      title="Inviter un joueur"
    >
      <template #body>
        <div
          v-if="inviteResult"
          class="space-y-4"
        >
          <UAlert
            icon="i-lucide-check-circle"
            color="success"
            title="Joueur invité !"
            :description="`${fullName(inviteResult.user)} a été créé avec succès.`"
          />
          <div class="rounded-lg bg-elevated p-4 space-y-1">
            <p class="text-xs text-muted font-medium uppercase tracking-wide">
              Mot de passe temporaire
            </p>
            <p class="font-mono text-sm select-all">
              {{ inviteResult.temp_password }}
            </p>
            <p class="text-xs text-muted mt-1">
              Partage ce mot de passe de façon sécurisée. L'utilisateur pourra le changer après connexion.
            </p>
          </div>
        </div>

        <form
          v-else
          class="space-y-4"
          @submit.prevent="handleInvite"
        >
          <UAlert
            v-if="inviteError"
            icon="i-lucide-circle-alert"
            color="error"
            variant="subtle"
            :description="inviteError"
          />

          <div class="grid grid-cols-2 gap-3">
            <UFormField label="Prénom">
              <UInput
                v-model="inviteForm.first_name"
                placeholder="Prénom"
                required
                class="w-full"
              />
            </UFormField>

            <UFormField label="Nom">
              <UInput
                v-model="inviteForm.last_name"
                placeholder="Nom"
                class="w-full"
              />
            </UFormField>
          </div>

          <UFormField label="Email">
            <UInput
              v-model="inviteForm.email"
              type="email"
              placeholder="joueur@example.com"
              required
              class="w-full"
            />
          </UFormField>
        </form>
      </template>

      <template #footer>
        <div class="flex justify-end gap-2">
          <UButton
            variant="ghost"
            color="neutral"
            @click="showInvite = false"
          >
            {{ inviteResult ? 'Fermer' : 'Annuler' }}
          </UButton>
          <UButton
            v-if="!inviteResult"
            icon="i-lucide-send"
            :loading="inviteLoading"
            @click="handleInvite"
          >
            Créer et inviter
          </UButton>
        </div>
      </template>
    </UModal>
  </div>
</template>
