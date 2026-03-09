<script setup lang="ts">
useHead({
  meta: [{ name: 'viewport', content: 'width=device-width, initial-scale=1' }],
  link: [{ rel: 'icon', href: '/favicon.ico' }],
  htmlAttrs: { lang: 'fr' }
})

useSeoMeta({ title: 'BAP Pulse — Back-office' })

const route = useRoute()
const PUBLIC_PATHS = ['/login', '/unauthorized']
const isLoginPage = computed(() => PUBLIC_PATHS.includes(route.path))

const { user, signOut } = useAuth()

const navItems = [[
  { label: 'Dashboard', icon: 'i-lucide-layout-dashboard', to: '/' },
  { label: 'Joueurs', icon: 'i-lucide-users', to: '/users' },
  { label: 'Matchs', icon: 'i-lucide-swords', to: '/matches' },
  { label: 'Classement', icon: 'i-lucide-trophy', to: '/rankings' }
]]

const displayName = computed(() =>
  user.value?.displayName || user.value?.email || ''
)
const initials = computed(() => {
  const name = user.value?.displayName
  if (name) {
    return name.split(' ').map((n: string) => n[0]).slice(0, 2).join('').toUpperCase()
  }
  return user.value?.email?.[0]?.toUpperCase() ?? '?'
})
</script>

<template>
  <UApp>
    <!-- Login page: no sidebar -->
    <NuxtPage v-if="isLoginPage" />

    <!-- App shell -->
    <div v-else class="flex h-screen overflow-hidden">
      <!-- Sidebar -->
      <aside class="w-56 shrink-0 border-r border-default flex flex-col">
        <div class="px-4 py-5 border-b border-default">
          <p class="font-bold text-sm">BAP Pulse</p>
          <p class="text-xs text-muted">Back-office</p>
        </div>

        <UNavigationMenu
          orientation="vertical"
          :items="navItems"
          class="flex-1 p-2"
        />

        <div class="p-3 border-t border-default space-y-2">
          <!-- User info -->
          <div v-if="user" class="flex items-center gap-2 min-w-0">
            <UAvatar :alt="initials" size="xs" class="shrink-0" />
            <span class="text-xs text-muted truncate">{{ displayName }}</span>
          </div>

          <div class="flex items-center justify-between">
            <UButton
              variant="ghost"
              color="neutral"
              size="xs"
              icon="i-lucide-log-out"
              :padded="false"
              title="Se déconnecter"
              @click="signOut"
            />
            <UColorModeButton size="xs" />
          </div>
        </div>
      </aside>

      <!-- Content -->
      <div class="flex-1 flex flex-col min-w-0 overflow-auto">
        <NuxtPage />
      </div>
    </div>
  </UApp>
</template>
