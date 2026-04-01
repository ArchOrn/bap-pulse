<template>
  <UDashboardSidebar
    v-model:collapsed="collapsed"
    collapsible
    resizable
    class="max-w-96 border-r border-neutral-200 dark:border-neutral-800"
  >
    <template #header>
      <div
        class="flex items-center gap-2 min-w-0 px-2"
        :class="collapsed ? 'justify-center w-full' : 'w-full'"
      >
        <img
          src="/logo.svg"
          alt="BAP Pulse"
          class="w-6 h-6 shrink-0 dark:invert"
        >
        <div
          v-if="!collapsed"
          class="min-w-0"
        >
          <p class="font-semibold text-sm leading-tight truncate">
            BAP Pulse
          </p>
          <p class="text-xs text-neutral-500 leading-tight">
            Bad A Paname
          </p>
        </div>
      </div>
    </template>

    <USeparator class="my-1" />

    <UNavigationMenu
      :items="navigationItems"
      orientation="vertical"
      class="w-full"
      :collapsed="collapsed"
    />

    <template #footer>
      <div class="flex flex-col gap-1 w-full">
        <!-- User info -->
        <div
          v-if="user && !collapsed"
          class="flex items-center gap-2.5 px-2 mb-1 min-w-0"
        >
          <UAvatar
            :alt="initials"
            size="xs"
            class="shrink-0 ring-1 ring-neutral-300 dark:ring-neutral-700"
          />
          <div class="min-w-0 flex-1">
            <p class="text-xs font-medium truncate">
              {{ displayName }}
            </p>
            <p class="text-xs text-neutral-500">
              Administrateur
            </p>
          </div>
        </div>

        <!-- Color mode -->
        <UTooltip
          v-if="collapsed"
          text="Thème"
          :delay-duration="0"
          side="right"
        >
          <UColorModeButton
            variant="ghost"
            size="md"
            color="neutral"
            class="w-full justify-center"
          />
        </UTooltip>
        <UColorModeButton
          v-else
          variant="ghost"
          size="md"
          color="neutral"
          class="w-full justify-start"
          label="Thème"
        />

        <!-- Collapse toggle -->
        <UButton
          :icon="collapsed ? 'i-lucide-panel-left-open' : 'i-lucide-panel-left-close'"
          color="neutral"
          variant="ghost"
          size="md"
          :class="collapsed ? 'justify-center' : 'justify-start'"
          @click="collapsed = !collapsed"
        >
          <span v-if="!collapsed">Réduire</span>
        </UButton>

        <USeparator class="my-1" />

        <!-- Logout -->
        <UTooltip
          v-if="collapsed"
          text="Se déconnecter"
          :delay-duration="0"
          side="right"
        >
          <UButton
            color="neutral"
            variant="ghost"
            size="md"
            icon="i-lucide-log-out"
            class="cursor-pointer w-full justify-center"
            @click="handleLogout"
          />
        </UTooltip>
        <UButton
          v-else
          color="neutral"
          variant="ghost"
          size="md"
          leading-icon="i-lucide-log-out"
          class="cursor-pointer w-full"
          @click="handleLogout"
        >
          Se déconnecter
        </UButton>
      </div>
    </template>
  </UDashboardSidebar>
</template>

<script setup lang="ts">
const { user, signOut } = useAuth()

const collapsed = useLocalStorage('sidebar-collapsed', false)

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

async function handleLogout() {
  await signOut()
  navigateTo('/login')
}

const navigationItems = computed(() => [
  {
    label: 'Dashboard',
    to: '/',
    icon: 'i-lucide-layout-dashboard'
  },
  {
    label: 'Joueurs',
    to: '/users',
    icon: 'i-lucide-users'
  },
  {
    label: 'Matchs',
    to: '/matches',
    icon: 'i-lucide-swords'
  },
  {
    label: 'Classement',
    to: '/rankings',
    icon: 'i-lucide-trophy'
  }
])
</script>
