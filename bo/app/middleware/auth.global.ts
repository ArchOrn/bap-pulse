export default defineNuxtRouteMiddleware((to) => {
  // Firebase is client-side only
  if (import.meta.server) return

  const user = useState('auth:user')

  if (!user.value && to.path !== '/login') {
    return navigateTo('/login')
  }

  if (user.value && to.path === '/login') {
    return navigateTo('/')
  }
})
