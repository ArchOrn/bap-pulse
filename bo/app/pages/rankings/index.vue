<script setup lang="ts">
useHead({ title: 'Classement — BAP Pulse' })

const { baseURL } = useApi()

const { data: rankings, status } = await useFetch<UserRanking[]>(`${baseURL}/rankings`)

const fullName = (u: ApiUser) => [u.first_name, u.last_name].filter(Boolean).join(' ')

const columns = [
  { accessorKey: 'rank', header: '#' },
  { accessorKey: 'name', header: 'Joueur' },
  { accessorKey: 'elo', header: 'ELO' },
  { accessorKey: 'email', header: 'Email' }
]

const rows = computed(() =>
  (rankings.value ?? []).map(r => ({
    rank: r.Rank,
    name: fullName(r.User),
    elo: r.User.elo,
    email: r.User.email
  }))
)
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-2xl font-bold">
        Classement ELO
      </h1>
      <p class="text-sm text-muted mt-1">
        Joueurs triés par score ELO décroissant
      </p>
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
              name="i-lucide-medal"
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
      </UTable>
    </AppCard>
  </div>
</template>
