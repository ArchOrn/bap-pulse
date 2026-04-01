<template>
  <UDashboardGroup>
    <AppSidebar />
    <UDashboardPanel>
      <div class="px-4 pt-14 pb-4 md:p-10 w-full overflow-auto">
        <slot />
      </div>
    </UDashboardPanel>
  </UDashboardGroup>
</template>
