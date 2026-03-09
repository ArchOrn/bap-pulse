const PUBLIC_PATHS = ['/login', '/unauthorized']

export default defineNuxtRouteMiddleware((to) => {
  // Firebase is client-side only
  if (import.meta.server) return

  const user = useState('auth:user')
  const isAdmin = useState('auth:isAdmin')

  // Not logged in → login page
  if (!user.value && !PUBLIC_PATHS.includes(to.path)) {
    return navigateTo('/login')
  }

  // Logged in but not admin → 403 page
  if (user.value && !isAdmin.value && !PUBLIC_PATHS.includes(to.path)) {
    return navigateTo('/unauthorized')
  }

  // Already authenticated as admin → skip public pages
  if (user.value && isAdmin.value && PUBLIC_PATHS.includes(to.path)) {
    return navigateTo('/')
  }
})
