<script setup lang="ts">

useHead({ title: 'Joueurs — BAP Pulse' })

const { baseURL, authHeaders } = useApi()

const { data: users, status, error, refresh } = await useFetch<User[]>(`${baseURL}/users`, {
  headers: authHeaders()
})

const fullName = (u: User) => [u.first_name, u.last_name].filter(Boolean).join(' ')

// ---- Table columns ----
const columns = [
  { accessorKey: 'name', header: 'Nom' },
  { accessorKey: 'email', header: 'Email' },
  { accessorKey: 'elo', header: 'ELO' },
  { accessorKey: 'role', header: 'Rôle' },
  { accessorKey: 'created_at', header: 'Inscrit le' },
  { accessorKey: 'actions', header: '' }
]

const rows = computed(() =>
  (users.value ?? []).map(u => ({
    ...u,
    name: fullName(u),
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
  }
  catch (e: unknown) {
    const msg = (e as { data?: { error?: string } })?.data?.error
    inviteError.value = msg ?? 'Une erreur est survenue.'
  }
  finally {
    inviteLoading.value = false
  }
}

// ---- Edit modal ----
const showEdit = ref(false)
const editTarget = ref<User | null>(null)
const editForm = reactive({ first_name: '', last_name: '', email: '' })
const editLoading = ref(false)
const editError = ref<string | null>(null)

const openEdit = (user: User) => {
  editTarget.value = user
  editForm.first_name = user.first_name
  editForm.last_name = user.last_name
  editForm.email = user.email
  editError.value = null
  showEdit.value = true
}

const handleEdit = async () => {
  if (!editTarget.value) return
  editError.value = null
  editLoading.value = true
  try {
    await $fetch(`${baseURL}/users/${editTarget.value.id}`, {
      method: 'PUT',
      headers: authHeaders(),
      body: editForm
    })
    await refresh()
    showEdit.value = false
  }
  catch (e: unknown) {
    const msg = (e as { data?: { error?: string } })?.data?.error
    editError.value = msg ?? 'Une erreur est survenue.'
  }
  finally {
    editLoading.value = false
  }
}

// ---- Promote / demote ----
// Tracks admin UIDs locally based on current DB role + actions taken this session
const adminUIDs = ref<Set<string>>(new Set(
  (users.value ?? []).filter(u => u.role === 'admin').map(u => u.id)
))
const roleLoading = ref<string | null>(null)

const isUserAdmin = (uid: string) => adminUIDs.value.has(uid)

const toggleRole = async (uid: string) => {
  roleLoading.value = uid
  const makeAdmin = !isUserAdmin(uid)
  try {
    await $fetch(`${baseURL}/admin/users/${uid}/role`, {
      method: 'POST',
      headers: authHeaders(),
      body: { admin: makeAdmin }
    })
    if (makeAdmin) adminUIDs.value.add(uid)
    else adminUIDs.value.delete(uid)
  }
  catch (e: unknown) {
    const msg = (e as { data?: { error?: string } })?.data?.error
    alert(msg ?? 'Erreur lors du changement de rôle.')
  }
  finally {
    roleLoading.value = null
  }
}
</script>

<template>
  <div class="p-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-bold">Joueurs</h1>
        <p class="text-sm text-muted mt-1">{{ rows.length }} joueur{{ rows.length !== 1 ? 's' : '' }} inscrits</p>
      </div>

      <UButton icon="i-lucide-user-plus" @click="openInvite">
        Inviter un joueur
      </UButton>
    </div>

    <UCard>
      <div v-if="status === 'pending'" class="space-y-2">
        <USkeleton v-for="i in 8" :key="i" class="h-8 w-full" />
      </div>

      <UAlert
        v-else-if="error"
        icon="i-lucide-triangle-alert"
        color="error"
        title="Impossible de charger les joueurs"
        :description="error.message"
      />

      <UTable v-else :data="rows" :columns="columns">
        <template #role-cell="{ row }">
          <UBadge
            :label="row.original.role === 'admin' ? 'Admin' : 'Joueur'"
            :color="row.original.role === 'admin' ? 'primary' : 'neutral'"
            variant="subtle"
          />
        </template>

        <template #actions-cell="{ row }">
          <div class="flex items-center gap-1">
            <UButton
              icon="i-lucide-pencil"
              color="neutral"
              variant="ghost"
              size="xs"
              title="Modifier le profil"
              @click="openEdit(row.original)"
            />
            <UButton
              :icon="isUserAdmin(row.original.id) ? 'i-lucide-shield-minus' : 'i-lucide-shield-plus'"
              :color="isUserAdmin(row.original.id) ? 'error' : 'neutral'"
              variant="ghost"
              size="xs"
              :loading="roleLoading === row.original.id"
              :title="isUserAdmin(row.original.id) ? 'Révoquer admin' : 'Promouvoir admin'"
              @click="toggleRole(row.original.id)"
            />
          </div>
        </template>
      </UTable>
    </UCard>

    <!-- Invite modal -->
    <UModal v-model:open="showInvite" title="Inviter un joueur">
      <template #body>
        <div v-if="inviteResult" class="space-y-4">
          <UAlert
            icon="i-lucide-check-circle"
            color="success"
            title="Joueur invité !"
            :description="`${fullName(inviteResult.user)} a été créé avec succès.`"
          />
          <div class="rounded-lg bg-elevated p-4 space-y-1">
            <p class="text-xs text-muted font-medium uppercase tracking-wide">Mot de passe temporaire</p>
            <p class="font-mono text-sm select-all">{{ inviteResult.temp_password }}</p>
            <p class="text-xs text-muted mt-1">Partage ce mot de passe de façon sécurisée. L'utilisateur pourra le changer après connexion.</p>
          </div>
        </div>

        <form v-else class="space-y-4" @submit.prevent="handleInvite">
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
          <UButton variant="ghost" color="neutral" @click="showInvite = false">
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

    <!-- Edit modal -->
    <UModal v-model:open="showEdit" :title="`Modifier — ${editTarget ? fullName(editTarget) || editTarget.email : ''}`">
      <template #body>
        <form class="space-y-4" @submit.prevent="handleEdit">
          <UAlert
            v-if="editError"
            icon="i-lucide-circle-alert"
            color="error"
            variant="subtle"
            :description="editError"
          />

          <div class="grid grid-cols-2 gap-3">
            <UFormField label="Prénom">
              <UInput
                v-model="editForm.first_name"
                placeholder="Prénom"
                class="w-full"
              />
            </UFormField>

            <UFormField label="Nom">
              <UInput
                v-model="editForm.last_name"
                placeholder="Nom"
                class="w-full"
              />
            </UFormField>
          </div>

          <UFormField label="Email">
            <UInput
              v-model="editForm.email"
              type="email"
              placeholder="joueur@example.com"
              class="w-full"
            />
          </UFormField>
        </form>
      </template>

      <template #footer>
        <div class="flex justify-end gap-2">
          <UButton variant="ghost" color="neutral" @click="showEdit = false">
            Annuler
          </UButton>
          <UButton
            icon="i-lucide-check"
            :loading="editLoading"
            @click="handleEdit"
          >
            Enregistrer
          </UButton>
        </div>
      </template>
    </UModal>
  </div>
</template>
