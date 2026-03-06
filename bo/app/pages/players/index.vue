<script setup lang="ts">

useHead({ title: 'Joueurs — BAP Pulse' })

const { baseURL, authHeaders } = useApi()

const { data: players, status, error } = await useFetch<Player[]>(`${baseURL}/players`, {
  headers: authHeaders()
})

const columns = [
  { accessorKey: 'name', header: 'Nom' },
  { accessorKey: 'email', header: 'Email' },
  { accessorKey: 'elo', header: 'ELO' },
  { accessorKey: 'created_at', header: 'Inscrit le' }
]

const rows = computed(() =>
  (players.value ?? []).map(p => ({
    ...p,
    created_at: new Date(p.created_at).toLocaleDateString('fr-FR')
  }))
)
</script>

<template>
  <div class="p-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-bold">Joueurs</h1>
        <p class="text-sm text-muted mt-1">{{ rows.length }} joueur{{ rows.length !== 1 ? 's' : '' }} inscrits</p>
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
        title="Impossible de charger les joueurs"
        :description="error.message"
      />

      <UTable v-else :data="rows" :columns="columns" />
    </UCard>
  </div>
</template>
