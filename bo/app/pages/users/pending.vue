<script setup lang="ts">
import type { Gender, FfbadRank, User } from '~~/shared/types/api'

useHead({ title: 'Validations — BAP Pulse' })

const { baseURL, authHeaders } = useApi()
const { genderOptions, ffbadOptions } = useUserOptions()

const { data: users, status, error, refresh } = await useFetch<User[]>(`${baseURL}/admin/users/pending`, {
  headers: authHeaders()
})

const fullName = (u: User) => [u.first_name, u.last_name].filter(Boolean).join(' ')

const columns = [
  { accessorKey: 'name', header: 'Nom' },
  { accessorKey: 'email', header: 'Email' },
  { accessorKey: 'license_number', header: 'Licence' },
  { accessorKey: 'created_at', header: 'Inscrit le' },
  { accessorKey: 'actions', header: '' }
]

const rows = computed(() =>
  (users.value ?? []).map(u => ({
    ...u,
    name: fullName(u),
    license_number: u.license_number ?? '—',
    created_at: new Date(u.created_at).toLocaleDateString('fr-FR')
  }))
)

// ---- Approve dialog ----
const showApprove = ref(false)
const target = ref<User | null>(null)
const approveForm = reactive<{ gender: Gender | '', ffbad_rank: FfbadRank | '' }>({
  gender: '',
  ffbad_rank: ''
})
const actionLoading = ref(false)
const actionError = ref<string | null>(null)

const openApprove = (u: User) => {
  target.value = u
  approveForm.gender = u.gender ?? ''
  approveForm.ffbad_rank = u.ffbad_rank ?? ''
  actionError.value = null
  showApprove.value = true
}

const confirmApprove = async () => {
  if (!target.value) return
  actionError.value = null
  actionLoading.value = true
  try {
    await $fetch(`${baseURL}/admin/users/${target.value.id}/approve`, {
      method: 'POST',
      headers: authHeaders(),
      body: { gender: approveForm.gender, ffbad_rank: approveForm.ffbad_rank }
    })
    showApprove.value = false
    await refresh()
  } catch (e: unknown) {
    const msg = (e as { data?: { error?: string } })?.data?.error
    actionError.value = msg ?? 'Une erreur est survenue.'
  } finally {
    actionLoading.value = false
  }
}

const rejectingId = ref<string | null>(null)

const reject = async (u: User) => {
  rejectingId.value = u.id
  try {
    await $fetch(`${baseURL}/admin/users/${u.id}/reject`, {
      method: 'POST',
      headers: authHeaders()
    })
    await refresh()
  } catch {
    // Surfaced via refresh; keep it simple.
  } finally {
    rejectingId.value = null
  }
}

const breadcrumbs = [
  { label: 'Joueurs', to: '/users', icon: 'i-lucide-users' },
  { label: 'Validations' }
]
</script>

<template>
  <div class="space-y-6">
    <UBreadcrumb :items="breadcrumbs" />

    <div>
      <h1 class="text-2xl font-bold">
        Comptes en attente
      </h1>
      <p class="text-sm text-muted mt-1">
        Licences non reconnues automatiquement parmi les membres du club.
      </p>
    </div>

    <AppCard>
      <div
        v-if="status === 'pending'"
        class="space-y-2 p-4"
      >
        <USkeleton
          v-for="i in 4"
          :key="i"
          class="h-8 w-full"
        />
      </div>

      <UAlert
        v-else-if="error"
        icon="i-lucide-triangle-alert"
        color="error"
        title="Impossible de charger les comptes en attente"
        :description="error.message"
      />

      <div
        v-else-if="rows.length === 0"
        class="p-8 text-center text-muted"
      >
        <UIcon
          name="i-lucide-check-check"
          class="size-8 mx-auto mb-2 text-success"
        />
        Aucun compte en attente de validation.
      </div>

      <UTable
        v-else
        :data="rows"
        :columns="columns"
      >
        <template #actions-cell="{ row }">
          <div class="flex justify-end gap-2">
            <UButton
              icon="i-lucide-check"
              color="success"
              variant="soft"
              size="xs"
              @click="openApprove(row.original)"
            >
              Valider
            </UButton>
            <UButton
              icon="i-lucide-x"
              color="error"
              variant="soft"
              size="xs"
              :loading="rejectingId === row.original.id"
              @click="reject(row.original)"
            >
              Refuser
            </UButton>
          </div>
        </template>
      </UTable>
    </AppCard>

    <!-- Approve dialog -->
    <UModal
      v-model:open="showApprove"
      title="Valider le compte"
    >
      <template #body>
        <div class="space-y-4">
          <p class="text-sm text-muted">
            Confirme l'accès de
            <span class="font-semibold text-default">{{ target ? fullName(target) || target.email : '' }}</span>.
            Ajuste le profil sportif si besoin (les données FFBAD peuvent être absentes ou périmées).
          </p>

          <UAlert
            v-if="actionError"
            icon="i-lucide-circle-alert"
            color="error"
            variant="subtle"
            :description="actionError"
          />

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <UFormField label="Genre">
              <USelect
                v-model="approveForm.gender"
                :items="genderOptions"
                value-key="value"
                class="w-full"
              />
            </UFormField>

            <UFormField label="Classement FFBAD">
              <USelect
                v-model="approveForm.ffbad_rank"
                :items="ffbadOptions"
                value-key="value"
                class="w-full"
              />
            </UFormField>
          </div>
        </div>
      </template>

      <template #footer>
        <div class="flex justify-end gap-2">
          <UButton
            variant="ghost"
            color="neutral"
            @click="showApprove = false"
          >
            Annuler
          </UButton>
          <UButton
            icon="i-lucide-check"
            color="success"
            :loading="actionLoading"
            @click="confirmApprove"
          >
            Valider l'accès
          </UButton>
        </div>
      </template>
    </UModal>
  </div>
</template>
