<script setup lang="ts">
import { stripMarkdown } from '~/utils/markdown'

useHead({ title: 'News — BAP Pulse' })

const { baseURL, authHeaders } = useApi()

const { data: news, status, error, refresh } = await useFetch<News[]>(`${baseURL}/news`, {
  headers: authHeaders(),
  query: { limit: 100 }
})

const { data: users } = await useFetch<User[]>(`${baseURL}/users`, {
  headers: authHeaders()
})

const userMap = computed(() => {
  const map = new Map<string, User>()
  for (const u of users.value ?? []) map.set(u.id, u)
  return map
})

const fullName = (u: User) => [u.first_name, u.last_name].filter(Boolean).join(' ')

const authorLabel = (id: string | null) => {
  if (!id) return 'Auto'
  const u = userMap.value.get(id)
  return u ? fullName(u) : id.slice(0, 8) + '…'
}

const sourceBadge: Record<NewsSource, { label: string, color: 'primary' | 'neutral' }> = {
  MANUAL: { label: 'Manuel', color: 'primary' },
  AUTO_MATCH: { label: 'Auto · Match', color: 'neutral' }
}

const columns = [
  { accessorKey: 'emoji', header: '' },
  { accessorKey: 'titlePlain', header: 'Titre' },
  { accessorKey: 'source', header: 'Source' },
  { accessorKey: 'author', header: 'Auteur' },
  { accessorKey: 'createdAt', header: 'Date' },
  { accessorKey: 'actions', header: '' }
]

const rows = computed(() =>
  (news.value ?? []).map(n => ({
    ...n,
    titlePlain: stripMarkdown(n.title),
    author: authorLabel(n.created_by),
    createdAt: new Date(n.created_at).toLocaleDateString('fr-FR', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    })
  }))
)

// ---- Create modal ----
const showCreate = ref(false)
const createLoading = ref(false)
const createError = ref<string | null>(null)

const createForm = reactive({
  emoji: '',
  title: '',
  body: ''
})

const openCreate = () => {
  createForm.emoji = ''
  createForm.title = ''
  createForm.body = ''
  createError.value = null
  showCreate.value = true
}

const handleCreate = async () => {
  createError.value = null
  if (!createForm.emoji.trim() || !createForm.title.trim()) {
    createError.value = 'L\'emoji et le titre sont obligatoires.'
    return
  }
  createLoading.value = true
  try {
    await $fetch(`${baseURL}/news`, {
      method: 'POST',
      headers: authHeaders(),
      body: {
        emoji: createForm.emoji.trim(),
        title: createForm.title.trim(),
        body: createForm.body
      }
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

// ---- Delete ----
const handleDelete = async (id: string) => {
  if (!confirm('Supprimer cette news ?')) return
  try {
    await $fetch(`${baseURL}/news/${id}`, {
      method: 'DELETE',
      headers: authHeaders()
    })
    await refresh()
  } catch (e) {
    console.error(e)
    alert('Suppression impossible.')
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold">
          News
        </h1>
        <p class="text-sm text-muted mt-1">
          {{ rows.length }} entrée{{ rows.length !== 1 ? 's' : '' }} ·
          alimente la section « Pouls du club » de l'app
        </p>
      </div>

      <UButton
        icon="i-lucide-plus"
        @click="openCreate"
      >
        Nouvelle news
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
        title="Impossible de charger les news"
        :description="error.message"
      />

      <UTable
        v-else
        :data="rows"
        :columns="columns"
      >
        <template #emoji-cell="{ row }">
          <span class="text-xl">{{ row.original.emoji }}</span>
        </template>

        <template #source-cell="{ row }">
          <UBadge
            :label="sourceBadge[row.original.source as NewsSource]?.label"
            :color="sourceBadge[row.original.source as NewsSource]?.color"
            variant="subtle"
            size="sm"
          />
        </template>

        <template #actions-cell="{ row }">
          <div class="flex items-center justify-end gap-1">
            <UButton
              icon="i-lucide-pencil"
              size="xs"
              variant="ghost"
              color="neutral"
              :to="`/news/${row.original.id}/edit`"
            />
            <UButton
              icon="i-lucide-trash-2"
              size="xs"
              variant="ghost"
              color="error"
              @click="handleDelete(row.original.id)"
            />
          </div>
        </template>
      </UTable>
    </AppCard>

    <UModal
      v-model:open="showCreate"
      title="Nouvelle news"
      :ui="{ content: 'sm:max-w-3xl' }"
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

          <NewsForm
            v-model:model-emoji="createForm.emoji"
            v-model:model-title="createForm.title"
            v-model:model-body="createForm.body"
          />
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
            @click="handleCreate"
          >
            Publier
          </UButton>
        </div>
      </template>
    </UModal>
  </div>
</template>
