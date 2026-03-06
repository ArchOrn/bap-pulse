<script setup lang="ts">

useHead({ title: 'Matchs — BAP Pulse' })

const { baseURL, authHeaders } = useApi()

const { data: matches, status, error } = await useFetch<Match[]>(`${baseURL}/matches`, {
  headers: authHeaders()
})

const matchTypeBadge: Record<string, { label: string, color: 'primary' | 'secondary' | 'neutral' }> = {
  SINGLES: { label: 'Simple', color: 'primary' },
  DOUBLES: { label: 'Double', color: 'secondary' },
  MIXED: { label: 'Mixte', color: 'neutral' }
}

const columns = [
  { accessorKey: 'type', header: 'Type' },
  { accessorKey: 'teams', header: 'Équipes' },
  { accessorKey: 'score', header: 'Score' },
  { accessorKey: 'played_at', header: 'Date' },
  { accessorKey: 'validated', header: 'Validé' }
]

const rows = computed(() =>
  (matches.value ?? []).map(m => ({
    type: m.match_type,
    teams: m.match_type === 'SINGLES'
      ? `${m.team1_player1_id.slice(0, 6)}… vs ${m.team2_player1_id.slice(0, 6)}…`
      : `${m.team1_player1_id.slice(0, 4)}…+${(m.team1_player2_id ?? '').slice(0, 4)}… vs ${m.team2_player1_id.slice(0, 4)}…+${(m.team2_player2_id ?? '').slice(0, 4)}…`,
    score: `${m.score_team1} — ${m.score_team2}`,
    played_at: new Date(m.played_at).toLocaleDateString('fr-FR'),
    validated: m.validated
  }))
)
</script>

<template>
  <div class="p-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-bold">Matchs</h1>
        <p class="text-sm text-muted mt-1">{{ rows.length }} match{{ rows.length !== 1 ? 's' : '' }} enregistré{{ rows.length !== 1 ? 's' : '' }}</p>
      </div>
    </div>

    <UCard>
      <div v-if="status === 'pending'" class="space-y-2">
        <USkeleton v-for="i in 8" :key="i" class="h-8 w-full" />
      </div>

      <UAlert
        v-else-if="error"
        icon="i-lucide-triangle-alert"
        color="error"
        title="Impossible de charger les matchs"
        :description="error.message"
      />

      <UTable v-else :data="rows" :columns="columns">
        <template #type-cell="{ row }">
          <UBadge
            :label="matchTypeBadge[row.original.type]?.label ?? row.original.type"
            :color="matchTypeBadge[row.original.type]?.color ?? 'neutral'"
            variant="subtle"
            size="sm"
          />
        </template>

        <template #validated-cell="{ row }">
          <UIcon
            :name="row.original.validated ? 'i-lucide-check-circle' : 'i-lucide-clock'"
            :class="row.original.validated ? 'text-success' : 'text-muted'"
            class="size-4"
          />
        </template>
      </UTable>
    </UCard>
  </div>
</template>
