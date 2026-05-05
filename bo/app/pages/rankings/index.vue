<script setup lang="ts">
import type {
  ApiUser, Tableau,
  EloRanking, PerformanceRanking, LeagueRanking,
  MatchesPlayedRanking, GiantKillerRanking
} from '~~/shared/types/api'

useHead({ title: 'Classement — BAP Pulse' })

const { baseURL } = useApi()

type RankingType = 'performance' | 'elo' | 'league' | 'matches-played' | 'giant-killer'

const rankingTypes: { value: RankingType, label: string, icon: string, hint: string }[] = [
  { value: 'performance', label: 'Performance', icon: 'i-lucide-trophy', hint: 'Maillot jaune — points cumulés sur le mois' },
  { value: 'elo', label: 'ELO', icon: 'i-lucide-bar-chart-3', hint: 'Classement absolu par tableau' },
  { value: 'league', label: 'Ligue', icon: 'i-lucide-swords', hint: 'Victoires, défaites, sets sur le mois' },
  { value: 'matches-played', label: 'Matchs joués', icon: 'i-lucide-activity', hint: 'Volume de matchs sur le mois' },
  { value: 'giant-killer', label: 'Giant Killer', icon: 'i-lucide-target', hint: 'Victoires contre plus fort (écart ELO ≥ 100)' }
]

const tableaux: { value: Tableau, label: string }[] = [
  { value: 'SINGLES', label: 'Simple' },
  { value: 'DOUBLES', label: 'Double' },
  { value: 'MIXED', label: 'Mixte' }
]

const selectedType = ref<RankingType>('performance')
const selectedTableau = ref<Tableau>('SINGLES')

// Period in YYYY-MM. Defaults to current month (server-side default if blank).
const now = new Date()
const currentPeriod = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
const selectedPeriod = ref<string>(currentPeriod)

// `period` is irrelevant for ELO ranking — hide the picker for that mode.
const showPeriodPicker = computed(() => selectedType.value !== 'elo')

const periodOptions = computed(() => {
  // Last 12 months, newest first.
  const opts: { value: string, label: string }[] = []
  const monthsFr = ['janv', 'févr', 'mars', 'avril', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc']
  for (let i = 0; i < 12; i++) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
    const value = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
    opts.push({ value, label: `${monthsFr[d.getMonth()]} ${d.getFullYear()}` })
  }
  return opts
})

type AnyRanking
  = | EloRanking | PerformanceRanking | LeagueRanking
    | MatchesPlayedRanking | GiantKillerRanking

const rankingURL = computed(() => {
  const t = selectedType.value
  const params = new URLSearchParams({ tableau: selectedTableau.value })
  if (t !== 'elo' && selectedPeriod.value) {
    params.set('period', selectedPeriod.value)
  }
  return `${baseURL}/rankings/${t}?${params.toString()}`
})

const { data: rankings, status, refresh } = await useFetch<AnyRanking[]>(
  rankingURL,
  { watch: [rankingURL] }
)

const fullName = (u: ApiUser) => [u.first_name, u.last_name].filter(Boolean).join(' ')

// Column sets per ranking type.
const columns = computed(() => {
  const base = [
    { accessorKey: 'rank', header: '#' },
    { accessorKey: 'name', header: 'Joueur' }
  ]
  switch (selectedType.value) {
    case 'performance':
      return [...base, { accessorKey: 'points', header: 'Points' }, { accessorKey: 'elo', header: 'ELO' }]
    case 'elo':
      return [...base, { accessorKey: 'elo', header: 'ELO' }, { accessorKey: 'rankFFBAD', header: 'FFBAD' }]
    case 'league':
      return [
        ...base,
        { accessorKey: 'wins', header: 'V' },
        { accessorKey: 'losses', header: 'D' },
        { accessorKey: 'sets', header: 'Sets' },
        { accessorKey: 'setsDiff', header: '+/-' }
      ]
    case 'matches-played':
      return [...base, { accessorKey: 'matchesPlayed', header: 'Matchs' }]
    case 'giant-killer':
      return [...base, { accessorKey: 'upsetWins', header: 'Upsets' }]
  }
  return base
})

interface Row {
  rank: number
  name: string
  elo?: number
  points?: number
  rankFFBAD?: string
  wins?: number
  losses?: number
  sets?: string
  setsDiff?: number
  matchesPlayed?: number
  upsetWins?: number
}

const rows = computed<Row[]>(() => {
  const list = rankings.value ?? []
  switch (selectedType.value) {
    case 'performance':
      return (list as PerformanceRanking[]).map<Row>(r => ({
        rank: r.rank,
        name: fullName(r.user),
        points: r.points,
        elo: eloFor(r.user, selectedTableau.value)
      }))
    case 'elo':
      return (list as EloRanking[]).map<Row>(r => ({
        rank: r.rank,
        name: fullName(r.user),
        elo: r.elo,
        rankFFBAD: r.user.ffbad_rank ?? '—'
      }))
    case 'league':
      return (list as LeagueRanking[]).map<Row>(r => ({
        rank: r.rank,
        name: fullName(r.user),
        wins: r.wins,
        losses: r.losses,
        sets: `${r.sets_won}-${r.sets_lost}`,
        setsDiff: r.sets_diff
      }))
    case 'matches-played':
      return (list as MatchesPlayedRanking[]).map<Row>(r => ({
        rank: r.rank,
        name: fullName(r.user),
        matchesPlayed: r.matches_played
      }))
    case 'giant-killer':
      return (list as GiantKillerRanking[]).map<Row>(r => ({
        rank: r.rank,
        name: fullName(r.user),
        upsetWins: r.upset_wins
      }))
  }
  return []
})

const currentTypeMeta = computed(() =>
  rankingTypes.find(t => t.value === selectedType.value)!
)

function eloFor(u: ApiUser, t: Tableau): number {
  switch (t) {
    case 'DOUBLES': return u.elo_doubles
    case 'MIXED': return u.elo_mixed
    default: return u.elo_singles
  }
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold">
        Classements
      </h1>
      <p class="text-sm text-muted mt-1">
        {{ currentTypeMeta.hint }}
      </p>
    </div>

    <div class="flex flex-wrap gap-2">
      <UButton
        v-for="t in rankingTypes"
        :key="t.value"
        :icon="t.icon"
        :color="selectedType === t.value ? 'primary' : 'neutral'"
        :variant="selectedType === t.value ? 'solid' : 'subtle'"
        size="sm"
        @click="selectedType = t.value"
      >
        {{ t.label }}
      </UButton>
    </div>

    <div class="flex flex-wrap items-center gap-3">
      <UFormField
        label="Tableau"
        class="min-w-40"
      >
        <USelect
          v-model="selectedTableau"
          :items="tableaux"
          value-key="value"
        />
      </UFormField>

      <UFormField
        v-if="showPeriodPicker"
        label="Mois"
        class="min-w-44"
      >
        <USelect
          v-model="selectedPeriod"
          :items="periodOptions"
          value-key="value"
        />
      </UFormField>

      <UButton
        icon="i-lucide-refresh-cw"
        variant="ghost"
        size="sm"
        :loading="status === 'pending'"
        @click="refresh()"
      />
    </div>

    <AppCard>
      <div
        v-if="status === 'pending'"
        class="space-y-2 p-4"
      >
        <USkeleton
          v-for="i in 10"
          :key="i"
          class="h-8 w-full"
        />
      </div>

      <UAlert
        v-else-if="status === 'error'"
        icon="i-lucide-triangle-alert"
        color="error"
        title="Impossible de charger le classement"
        description="Une erreur est survenue lors de la récupération des données."
      />

      <UTable
        v-else
        :data="rows"
        :columns="columns"
      >
        <template #rank-cell="{ row }">
          <div class="flex items-center gap-2">
            <UIcon
              v-if="row.original.rank <= 3"
              :name="selectedType === 'performance' ? 'i-lucide-shirt' : 'i-lucide-medal'"
              :class="{
                'text-yellow-500': row.original.rank === 1,
                'text-slate-400': row.original.rank === 2,
                'text-orange-400': row.original.rank === 3
              }"
              class="size-4"
            />
            <span :class="row.original.rank <= 3 ? 'font-bold' : 'text-muted'">
              {{ row.original.rank }}
            </span>
          </div>
        </template>

        <template #elo-cell="{ row }">
          <UBadge
            :label="String(row.original.elo)"
            color="primary"
            variant="subtle"
          />
        </template>

        <template #points-cell="{ row }">
          <UBadge
            :label="String(row.original.points)"
            color="warning"
            variant="subtle"
          />
        </template>

        <template #setsDiff-cell="{ row }">
          <span :class="(row.original.setsDiff ?? 0) > 0 ? 'text-success' : (row.original.setsDiff ?? 0) < 0 ? 'text-error' : 'text-muted'">
            {{ (row.original.setsDiff ?? 0) > 0 ? '+' : '' }}{{ row.original.setsDiff ?? 0 }}
          </span>
        </template>
      </UTable>
    </AppCard>
  </div>
</template>
