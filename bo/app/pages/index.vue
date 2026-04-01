<script setup lang="ts">
const { baseURL } = useApi()

const { data: rankings, status } = await useFetch<UserRanking[]>(`${baseURL}/rankings`)

const fullName = (u: ApiUser) => [u.first_name, u.last_name].filter(Boolean).join(' ')

const stats = computed(() => [
  {
    label: 'Joueurs inscrits',
    value: rankings.value?.length ?? 0,
    icon: 'i-lucide-users'
  },
  {
    label: 'Meilleur ELO',
    value: rankings.value?.[0]?.User.elo ?? '—',
    icon: 'i-lucide-trophy'
  },
  {
    label: 'Leader',
    value: rankings.value?.[0] ? fullName(rankings.value[0].User) : '—',
    icon: 'i-lucide-crown'
  }
])

const topColumns = [
  { accessorKey: 'rank', header: '#' },
  { accessorKey: 'name', header: 'Joueur' },
  { accessorKey: 'elo', header: 'ELO' }
]

const topRows = computed(() =>
  (rankings.value ?? []).slice(0, 5).map(r => ({
    rank: r.Rank,
    name: fullName(r.User),
    elo: r.User.elo
  }))
)
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold">
        Dashboard
      </h1>
      <p class="text-sm text-muted mt-1">
        Vue d'ensemble du club Bad A Paname
      </p>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-3 gap-4">
      <AppCard
        v-for="stat in stats"
        :key="stat.label"
      >
        <div class="flex items-center gap-3 p-4">
          <UIcon
            :name="stat.icon"
            class="size-5 text-primary shrink-0"
          />
          <div>
            <p class="text-xs text-muted">
              {{ stat.label }}
            </p>
            <p class="text-lg font-bold">
              {{ stat.value }}
            </p>
          </div>
        </div>
      </AppCard>
    </div>

    <!-- Top 5 -->
    <AppCard>
      <template #header>
        <p class="font-semibold text-sm">
          Top 5 joueurs
        </p>
      </template>

      <div
        v-if="status === 'pending'"
        class="space-y-2 p-4"
      >
        <USkeleton
          v-for="i in 5"
          :key="i"
          class="h-8 w-full"
        />
      </div>
      <UTable
        v-else
        :data="topRows"
        :columns="topColumns"
      />
    </AppCard>
  </div>
</template>
