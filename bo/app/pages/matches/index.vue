<script setup lang="ts">
useHead({ title: 'Matchs — BAP Pulse' })

const { baseURL, authHeaders } = useApi()

const { data: matches, status, error, refresh } = await useFetch<Match[]>(`${baseURL}/matches`, {
  headers: authHeaders()
})

const { data: users } = await useFetch<User[]>(`${baseURL}/users`, {
  headers: authHeaders()
})

const fullName = (u: User) => [u.first_name, u.last_name].filter(Boolean).join(' ')

const userMap = computed(() => {
  const map = new Map<string, User>()
  for (const u of users.value ?? []) map.set(u.id, u)
  return map
})

const playerName = (id: string | null) => {
  if (!id) return '—'
  const u = userMap.value.get(id)
  return u ? fullName(u) : id.slice(0, 8) + '…'
}

const matchTypeBadge: Record<string, { label: string, color: 'primary' | 'secondary' | 'neutral' }> = {
  SINGLES: { label: 'Simple', color: 'primary' },
  DOUBLES: { label: 'Double', color: 'secondary' },
  MIXED: { label: 'Mixte', color: 'neutral' }
}

const formatSets = (m: Match) => {
  const sets = [`${m.set1_team1}-${m.set1_team2}`, `${m.set2_team1}-${m.set2_team2}`]
  if (m.set3_team1 != null && m.set3_team2 != null) {
    sets.push(`${m.set3_team1}-${m.set3_team2}`)
  }
  return sets.join(' / ')
}

const setsWon = (m: Match): [number, number] => {
  let t1 = 0
  let t2 = 0
  if (m.set1_team1 > m.set1_team2) t1++
  else if (m.set1_team2 > m.set1_team1) t2++
  if (m.set2_team1 > m.set2_team2) t1++
  else if (m.set2_team2 > m.set2_team1) t2++
  if (m.set3_team1 != null && m.set3_team2 != null) {
    if (m.set3_team1 > m.set3_team2) t1++
    else if (m.set3_team2 > m.set3_team1) t2++
  }
  return [t1, t2]
}

const columns = [
  { accessorKey: 'type', header: 'Type' },
  { accessorKey: 'teams', header: 'Équipes' },
  { accessorKey: 'score', header: 'Score (sets)' },
  { accessorKey: 'sets_detail', header: 'Détail sets' },
  { accessorKey: 'played_at', header: 'Date' },
  { accessorKey: 'validated', header: 'Validé' }
]

const rows = computed(() =>
  (matches.value ?? []).map((m) => {
    const [w1, w2] = setsWon(m)
    return {
      ...m,
      type: m.match_type,
      teams: m.match_type === 'SINGLES'
        ? `${playerName(m.team1_player1_id)} vs ${playerName(m.team2_player1_id)}`
        : `${playerName(m.team1_player1_id)} + ${playerName(m.team1_player2_id)} vs ${playerName(m.team2_player1_id)} + ${playerName(m.team2_player2_id)}`,
      score: `${w1} — ${w2}`,
      sets_detail: formatSets(m),
      played_at_fmt: new Date(m.played_at).toLocaleDateString('fr-FR'),
      validated: m.validated
    }
  })
)

// ---- Create match modal ----
const showCreate = ref(false)
const createLoading = ref(false)
const createError = ref<string | null>(null)

const matchTypes = [
  { label: 'Simple (1v1)', value: 'SINGLES' },
  { label: 'Double (2v2)', value: 'DOUBLES' },
  { label: 'Mixte (2v2)', value: 'MIXED' }
]

const createForm = reactive({
  match_type: 'SINGLES' as 'SINGLES' | 'DOUBLES' | 'MIXED',
  team1_player1_id: '',
  team1_player2_id: '',
  team2_player1_id: '',
  team2_player2_id: '',
  sets: [
    { team1: 0, team2: 0 },
    { team1: 0, team2: 0 }
  ] as { team1: number, team2: number }[]
})

const isDoubles = computed(() => createForm.match_type === 'DOUBLES' || createForm.match_type === 'MIXED')

const needsSet3 = computed(() => {
  const a = createForm.sets[0]
  const b = createForm.sets[1]
  if (!a || !b) return false
  const w1 = (a.team1 > a.team2 ? 1 : 0) + (b.team1 > b.team2 ? 1 : 0)
  const w2 = (a.team2 > a.team1 ? 1 : 0) + (b.team2 > b.team1 ? 1 : 0)
  return w1 === 1 && w2 === 1
})

watch(needsSet3, (needs) => {
  if (needs && createForm.sets.length === 2) {
    createForm.sets.push({ team1: 0, team2: 0 })
  } else if (!needs && createForm.sets.length === 3) {
    createForm.sets.splice(2, 1)
  }
})

// Show the ELO that matters for the selected match type, so the user picks
// roughly-balanced players for the right tableau.
const eloForMatch = (u: User) => {
  switch (createForm.match_type) {
    case 'DOUBLES': return u.elo_doubles
    case 'MIXED': return u.elo_mixed
    default: return u.elo_singles
  }
}

const playerOptions = computed(() =>
  (users.value ?? []).map(u => ({
    label: `${fullName(u)} (${eloForMatch(u)})`,
    value: u.id
  }))
)

const hasDuplicatePlayers = computed(() => {
  const ids = [createForm.team1_player1_id, createForm.team2_player1_id]
  if (isDoubles.value) {
    ids.push(createForm.team1_player2_id, createForm.team2_player2_id)
  }
  const filled = ids.filter(Boolean)
  return new Set(filled).size !== filled.length
})

const openCreate = () => {
  createForm.match_type = 'SINGLES'
  createForm.team1_player1_id = ''
  createForm.team1_player2_id = ''
  createForm.team2_player1_id = ''
  createForm.team2_player2_id = ''
  createForm.sets = [
    { team1: 0, team2: 0 },
    { team1: 0, team2: 0 }
  ]
  createError.value = null
  showCreate.value = true
}

const handleCreate = async () => {
  createError.value = null
  createLoading.value = true
  try {
    const body: Record<string, unknown> = {
      match_type: createForm.match_type,
      team1_player1_id: createForm.team1_player1_id,
      team2_player1_id: createForm.team2_player1_id,
      sets: createForm.sets
    }
    if (isDoubles.value) {
      body.team1_player2_id = createForm.team1_player2_id
      body.team2_player2_id = createForm.team2_player2_id
    }
    await $fetch(`${baseURL}/matches/record`, {
      method: 'POST',
      headers: authHeaders(),
      body
    })
    await refresh()
    showCreate.value = false
  } catch (e: unknown) {
    const msg = (e as { data?: { error?: string } })?.data?.error
    createError.value = msg ?? 'Une erreur est survenue.'
  } finally {
    createLoading.value = false
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold">
          Matchs
        </h1>
        <p class="text-sm text-muted mt-1">
          {{ rows.length }} match{{ rows.length !== 1 ? 's' : '' }} enregistré{{ rows.length !== 1 ? 's' : '' }}
        </p>
      </div>

      <UButton
        icon="i-lucide-plus"
        @click="openCreate"
      >
        Ajouter un match
      </UButton>
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
        title="Impossible de charger les matchs"
        :description="error.message"
      />

      <UTable
        v-else
        :data="rows"
        :columns="columns"
      >
        <template #type-cell="{ row }">
          <UBadge
            :label="matchTypeBadge[row.original.type]?.label ?? row.original.type"
            :color="matchTypeBadge[row.original.type]?.color ?? 'neutral'"
            variant="subtle"
            size="sm"
          />
        </template>

        <template #played_at-cell="{ row }">
          {{ row.original.played_at_fmt }}
        </template>

        <template #validated-cell="{ row }">
          <UIcon
            :name="row.original.validated ? 'i-lucide-check-circle' : 'i-lucide-clock'"
            :class="row.original.validated ? 'text-success' : 'text-muted'"
            class="size-4"
          />
        </template>
      </UTable>
    </AppCard>

    <!-- Create match modal -->
    <UModal
      v-model:open="showCreate"
      title="Ajouter un match"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="handleCreate"
        >
          <UAlert
            v-if="createError"
            icon="i-lucide-circle-alert"
            color="error"
            variant="subtle"
            :description="createError"
          />

          <!-- Match type -->
          <UFormField label="Type de match">
            <USelect
              v-model="createForm.match_type"
              :items="matchTypes"
              value-key="value"
              class="w-full"
            />
          </UFormField>

          <!-- Players -->
          <div class="grid grid-cols-2 gap-4">
            <!-- Team 1 -->
            <fieldset class="space-y-3">
              <legend class="text-sm font-semibold">
                Équipe 1
              </legend>
              <UFormField label="Joueur 1">
                <USelect
                  v-model="createForm.team1_player1_id"
                  :items="playerOptions"
                  value-key="value"
                  placeholder="Sélectionner"
                  class="w-full"
                />
              </UFormField>
              <UFormField
                v-if="isDoubles"
                label="Joueur 2"
              >
                <USelect
                  v-model="createForm.team1_player2_id"
                  :items="playerOptions"
                  value-key="value"
                  placeholder="Sélectionner"
                  class="w-full"
                />
              </UFormField>
            </fieldset>

            <!-- Team 2 -->
            <fieldset class="space-y-3">
              <legend class="text-sm font-semibold">
                Équipe 2
              </legend>
              <UFormField label="Joueur 1">
                <USelect
                  v-model="createForm.team2_player1_id"
                  :items="playerOptions"
                  value-key="value"
                  placeholder="Sélectionner"
                  class="w-full"
                />
              </UFormField>
              <UFormField
                v-if="isDoubles"
                label="Joueur 2"
              >
                <USelect
                  v-model="createForm.team2_player2_id"
                  :items="playerOptions"
                  value-key="value"
                  placeholder="Sélectionner"
                  class="w-full"
                />
              </UFormField>
            </fieldset>
          </div>

          <UAlert
            v-if="hasDuplicatePlayers"
            icon="i-lucide-circle-alert"
            color="warning"
            variant="subtle"
            description="Un joueur ne peut pas apparaître plusieurs fois dans un match."
          />

          <!-- Sets -->
          <fieldset class="space-y-3">
            <legend class="text-sm font-semibold">
              Sets (30 points max)
            </legend>
            <div
              v-for="(s, i) in createForm.sets"
              :key="i"
              class="flex items-center gap-3"
            >
              <span class="text-sm text-muted w-12 shrink-0">Set {{ i + 1 }}</span>
              <UInput
                v-model.number="s.team1"
                type="number"
                :min="0"
                :max="30"
                placeholder="Éq. 1"
                class="w-full"
              />
              <span class="text-muted">—</span>
              <UInput
                v-model.number="s.team2"
                type="number"
                :min="0"
                :max="30"
                placeholder="Éq. 2"
                class="w-full"
              />
            </div>
            <p
              v-if="createForm.sets.length === 2 && !needsSet3"
              class="text-xs text-muted"
            >
              Le set 3 apparaitra automatiquement si chaque équipe gagne un set.
            </p>
          </fieldset>
        </form>
      </template>

      <template #footer>
        <div class="flex justify-end gap-2">
          <UButton
            variant="ghost"
            color="neutral"
            @click="showCreate = false"
          >
            Annuler
          </UButton>
          <UButton
            icon="i-lucide-check"
            :loading="createLoading"
            :disabled="hasDuplicatePlayers"
            @click="handleCreate"
          >
            Créer le match
          </UButton>
        </div>
      </template>
    </UModal>
  </div>
</template>
