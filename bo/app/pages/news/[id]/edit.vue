<script setup lang="ts">
const route = useRoute()
const router = useRouter()
const newsId = route.params.id as string

useHead({ title: 'Modifier une news — BAP Pulse' })

const { baseURL, authHeaders } = useApi()

const { data: news, status } = await useFetch<News>(`${baseURL}/news/${newsId}`, {
  headers: authHeaders()
})

const form = reactive({
  emoji: '',
  title: '',
  body: ''
})

watch(news, (n) => {
  if (n) {
    form.emoji = n.emoji
    form.title = n.title
    form.body = n.body ?? ''
  }
}, { immediate: true })

const loading = ref(false)
const error = ref<string | null>(null)
const success = ref(false)

const handleSubmit = async () => {
  error.value = null
  success.value = false
  loading.value = true
  try {
    const updated = await $fetch<News>(`${baseURL}/news/${newsId}`, {
      method: 'PUT',
      headers: authHeaders(),
      body: {
        emoji: form.emoji.trim(),
        title: form.title.trim(),
        body: form.body
      }
    })
    news.value = updated
    success.value = true
  } catch (e: unknown) {
    const msg = (e as { data?: { error?: string } })?.data?.error
    error.value = msg ?? 'Une erreur est survenue.'
  } finally {
    loading.value = false
  }
}

const handleDelete = async () => {
  if (!confirm('Supprimer cette news ?')) return
  try {
    await $fetch(`${baseURL}/news/${newsId}`, {
      method: 'DELETE',
      headers: authHeaders()
    })
    router.push('/news')
  } catch (e) {
    console.error(e)
    alert('Suppression impossible.')
  }
}

const breadcrumbs = computed(() => [
  { label: 'News', to: '/news', icon: 'i-lucide-newspaper' },
  { label: 'Modifier' }
])

const sourceLabel = computed(() => {
  if (!news.value) return ''
  return news.value.source === 'AUTO_MATCH' ? 'Générée automatiquement (match)' : 'Rédigée manuellement'
})
</script>

<template>
  <div class="space-y-6">
    <UBreadcrumb :items="breadcrumbs" />

    <div
      v-if="status === 'pending'"
      class="space-y-4"
    >
      <USkeleton class="h-8 w-48" />
      <USkeleton class="h-96 w-full" />
    </div>

    <template v-else-if="news">
      <div class="flex items-start justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold">
            Modifier la news
          </h1>
          <p class="text-sm text-muted mt-1">
            {{ sourceLabel }} · publiée le
            {{ new Date(news.created_at).toLocaleDateString('fr-FR', {
              day: '2-digit',
              month: 'long',
              year: 'numeric',
              hour: '2-digit',
              minute: '2-digit'
            }) }}
          </p>
        </div>

        <UButton
          icon="i-lucide-trash-2"
          variant="ghost"
          color="error"
          @click="handleDelete"
        >
          Supprimer
        </UButton>
      </div>

      <UAlert
        v-if="success"
        icon="i-lucide-check-circle"
        color="success"
        variant="subtle"
        title="News mise à jour"
      />

      <UAlert
        v-if="error"
        icon="i-lucide-circle-alert"
        color="error"
        variant="subtle"
        :description="error"
      />

      <AppCard>
        <form
          class="p-6 space-y-5"
          @submit.prevent="handleSubmit"
        >
          <NewsForm
            v-model:model-emoji="form.emoji"
            v-model:model-title="form.title"
            v-model:model-body="form.body"
          />

          <div class="flex items-center gap-3 pt-2">
            <UButton
              type="submit"
              icon="i-lucide-check"
              :loading="loading"
            >
              Enregistrer
            </UButton>
            <UButton
              variant="ghost"
              color="neutral"
              to="/news"
            >
              Annuler
            </UButton>
          </div>
        </form>
      </AppCard>
    </template>
  </div>
</template>
