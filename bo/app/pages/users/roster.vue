<script setup lang="ts">
import type { ClubRosterEntry, RosterResponse, RosterSyncResult } from '~~/shared/types/api'

useHead({ title: 'Roster FFBAD — BAP Pulse' })

const { baseURL, authHeaders } = useApi()

const { data: roster, status, error, refresh } = await useFetch<RosterResponse>(`${baseURL}/admin/roster`, {
  headers: authHeaders()
})

const fullName = (e: ClubRosterEntry) => [e.first_name, e.last_name].filter(Boolean).join(' ')

const lastSynced = computed(() => {
  const ts = roster.value?.last_synced_at
  return ts ? new Date(ts).toLocaleString('fr-FR') : 'jamais'
})

const columns = [
  { accessorKey: 'name', header: 'Nom' },
  { accessorKey: 'license_number', header: 'Licence' },
  { accessorKey: 'gender', header: 'Genre' },
  { accessorKey: 'rank_singles', header: 'Simple' },
  { accessorKey: 'rank_doubles', header: 'Double' },
  { accessorKey: 'rank_mixed', header: 'Mixte' },
  { accessorKey: 'matched', header: 'Compte' }
]

const rows = computed(() =>
  (roster.value?.entries ?? []).map(e => ({
    ...e,
    name: fullName(e),
    gender: e.gender === 'FEMALE' ? 'F' : e.gender === 'MALE' ? 'H' : '—',
    rank_singles: e.rank_singles ?? '—',
    rank_doubles: e.rank_doubles ?? '—',
    rank_mixed: e.rank_mixed ?? '—',
    matched: e.matched_user_id != null
  }))
)

// ---- Sync ----
const syncLoading = ref(false)
const syncResult = ref<RosterSyncResult | null>(null)
const syncError = ref<string | null>(null)

const runSync = async () => {
  syncError.value = null
  syncResult.value = null
  syncLoading.value = true
  try {
    syncResult.value = await $fetch<RosterSyncResult>(`${baseURL}/admin/roster/sync`, {
      method: 'POST',
      headers: authHeaders()
    })
    await refresh()
  } catch (e: unknown) {
    const msg = (e as { data?: { error?: string } })?.data?.error
    syncError.value = msg ?? 'Une erreur est survenue.'
  } finally {
    syncLoading.value = false
  }
}

const breadcrumbs = [
  { label: 'Joueurs', to: '/users', icon: 'i-lucide-users' },
  { label: 'Roster FFBAD' }
]
</script>

<template>
  <div class="space-y-6">
    <UBreadcrumb :items="breadcrumbs" />

    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold">
          Roster FFBAD
        </h1>
        <p class="text-sm text-muted mt-1">
          {{ rows.length }} membre{{ rows.length !== 1 ? 's' : '' }} · dernière synchro : {{ lastSynced }}
        </p>
      </div>

      <UButton
        icon="i-lucide-refresh-cw"
        :loading="syncLoading"
        @click="runSync"
      >
        Synchroniser FFBAD
      </UButton>
    </div>

    <UAlert
      v-if="syncResult"
      icon="i-lucide-check-circle"
      color="success"
      :title="`Synchronisation terminée — ${syncResult.upserted} membres mis à jour`"
      :description="`${syncResult.fetched} récupérés · ${syncResult.auto_approved} compte(s) auto-validé(s) · ${syncResult.skipped_anonymous} non-public(s) ignoré(s)${syncResult.errors.length ? ` · ${syncResult.errors.length} erreur(s)` : ''}`"
    />

    <UAlert
      v-if="syncError"
      icon="i-lucide-circle-alert"
      color="error"
      variant="subtle"
      :description="syncError"
    />

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
        title="Impossible de charger le roster"
        :description="error.message"
      />

      <div
        v-else-if="rows.length === 0"
        class="p-8 text-center text-muted"
      >
        <UIcon
          name="i-lucide-inbox"
          class="size-8 mx-auto mb-2"
        />
        Aucun membre synchronisé. Lance une synchronisation FFBAD.
      </div>

      <UTable
        v-else
        :data="rows"
        :columns="columns"
      >
        <template #matched-cell="{ row }">
          <UBadge
            :label="row.original.matched ? 'Lié' : '—'"
            :color="row.original.matched ? 'success' : 'neutral'"
            variant="subtle"
          />
        </template>
      </UTable>
    </AppCard>
  </div>
</template>
