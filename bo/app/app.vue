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

const navItems = [
  { label: 'Dashboard', icon: 'i-lucide-layout-dashboard', to: '/' },
  { label: 'Joueurs', icon: 'i-lucide-users', to: '/users' },
  { label: 'Matchs', icon: 'i-lucide-swords', to: '/matches' },
  { label: 'Classement', icon: 'i-lucide-trophy', to: '/rankings' }
]

const isActive = (path: string) => {
  if (path === '/') return route.path === '/'
  return route.path.startsWith(path)
}

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
    <!-- Login / public pages: no sidebar -->
    <NuxtPage v-if="isLoginPage" />

    <!-- App shell -->
    <div v-else class="flex h-screen overflow-hidden">
      <!-- Sidebar: always dark regardless of color mode -->
      <aside class="w-60 shrink-0 bg-zinc-950 flex flex-col">
        <!-- Logo -->
        <div class="px-4 py-4 border-b border-zinc-800 flex items-center gap-3">
          <div class="w-9 h-9 rounded-lg bg-green-400/10 border border-green-400/20 flex items-center justify-center text-base shrink-0">
            🏸
          </div>
          <div class="min-w-0">
            <p class="font-bold text-white text-sm leading-tight">BAP Pulse</p>
            <p class="text-xs text-zinc-500 leading-tight">Bad A Paname</p>
          </div>
        </div>

        <!-- Nav -->
        <nav class="flex-1 p-2 space-y-0.5">
          <NuxtLink
            v-for="item in navItems"
            :key="item.to"
            :to="item.to"
            class="relative flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors"
            :class="isActive(item.to)
              ? 'nav-active bg-zinc-800 text-white'
              : 'text-zinc-400 hover:bg-zinc-900 hover:text-zinc-200'"
          >
            <UIcon
              :name="item.icon"
              class="size-4 shrink-0 transition-colors"
              :class="isActive(item.to) ? 'text-green-400' : ''"
            />
            {{ item.label }}
          </NuxtLink>
        </nav>

        <!-- User footer -->
        <div class="p-3 border-t border-zinc-800">
          <div v-if="user" class="flex items-center gap-2.5 px-1 mb-2 min-w-0">
            <UAvatar :alt="initials" size="xs" class="shrink-0 ring-1 ring-zinc-700" />
            <div class="min-w-0 flex-1">
              <p class="text-xs text-zinc-100 font-medium truncate">{{ displayName }}</p>
              <p class="text-xs text-zinc-500">Administrateur</p>
            </div>
          </div>
          <div class="flex items-center gap-1">
            <UButton
              variant="ghost"
              color="neutral"
              size="xs"
              icon="i-lucide-log-out"
              title="Se déconnecter"
              class="text-zinc-400 hover:text-white hover:bg-zinc-800"
              @click="signOut"
            />
            <UColorModeButton size="xs" class="text-zinc-400 hover:text-white hover:bg-zinc-800" />
          </div>
        </div>
      </aside>

      <!-- Main content -->
      <div class="flex-1 flex flex-col min-w-0 overflow-auto">
        <NuxtPage />
      </div>
    </div>
  </UApp>
</template>
