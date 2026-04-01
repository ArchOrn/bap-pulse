import { initializeApp, getApps } from 'firebase/app'
import { getAuth, onAuthStateChanged } from 'firebase/auth'
import type { User } from 'firebase/auth'

export default defineNuxtPlugin(async () => {
  const config = useRuntimeConfig()
  const apiBaseUrl = config.public.apiBaseUrl as string

  const firebaseApp = getApps().length === 0
    ? initializeApp({
        apiKey: config.public.firebaseApiKey as string,
        authDomain: config.public.firebaseAuthDomain as string,
        projectId: config.public.firebaseProjectId as string,
        storageBucket: config.public.firebaseStorageBucket as string,
        messagingSenderId: config.public.firebaseMessagingSenderId as string,
        appId: config.public.firebaseAppId as string
      })
    : getApps()[0]

  const auth = getAuth(firebaseApp)

  const user = useState<User | null>('auth:user', () => null)
  const token = useState<string | null>('auth:token', () => null)
  const isAdmin = useState<boolean>('auth:isAdmin', () => false)

  // After Firebase auth, syncs the user profile from the API to read the DB role.
  // This is the single source of truth for the admin flag — no Firebase custom claims needed.
  const syncUser = async (firebaseUser: User | null) => {
    if (firebaseUser) {
      const idToken = await firebaseUser.getIdToken()
      token.value = idToken
      user.value = firebaseUser

      try {
        // /auth/sync creates the profile on first login, or returns the existing one.
        // The response includes the DB `role` field ('player' | 'admin').
        const displayName = firebaseUser.displayName ?? ''
        const [firstName, ...rest] = displayName.split(' ')
        const dbUser = await $fetch<ApiUser>(`${apiBaseUrl}/auth/sync`, {
          method: 'POST',
          headers: { Authorization: `Bearer ${idToken}` },
          body: { first_name: firstName, last_name: rest.join(' ') }
        })
        if (dbUser.role !== 'admin') {
          // Non-admin users have no access to the back-office — sign them out immediately.
          await auth.signOut()
          user.value = null
          token.value = null
          isAdmin.value = false
          return
        }
        isAdmin.value = true
      } catch {
        // API unreachable — sign out to avoid an inconsistent state.
        await auth.signOut()
        user.value = null
        token.value = null
        isAdmin.value = false
      }
    } else {
      user.value = null
      token.value = null
      isAdmin.value = false
    }
  }

  // Wait for initial auth state before allowing navigation.
  await new Promise<void>((resolve) => {
    let resolved = false
    onAuthStateChanged(auth, async (firebaseUser) => {
      await syncUser(firebaseUser)
      if (!resolved) {
        resolved = true
        resolve()
      }
    })
  })

  // Ongoing listener: keeps state fresh on sign-in / sign-out / token refresh.
  onAuthStateChanged(auth, syncUser)

  return {
    provide: { firebaseAuth: auth }
  }
})
