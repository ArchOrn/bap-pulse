import { initializeApp, getApps } from 'firebase/app'
import { getAuth, onAuthStateChanged } from 'firebase/auth'
import type { User } from 'firebase/auth'

export default defineNuxtPlugin(async () => {
  const config = useRuntimeConfig()

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

  // Wait for initial auth state before allowing navigation
  await new Promise<void>((resolve) => {
    let resolved = false
    onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        user.value = firebaseUser
        token.value = await firebaseUser.getIdToken()
      }
      else {
        user.value = null
        token.value = null
      }
      if (!resolved) {
        resolved = true
        resolve()
      }
    })
  })

  // Ongoing listener: keeps token fresh on sign-in/sign-out/refresh
  onAuthStateChanged(auth, async (firebaseUser) => {
    if (firebaseUser) {
      user.value = firebaseUser
      token.value = await firebaseUser.getIdToken()
    }
    else {
      user.value = null
      token.value = null
    }
  })

  return {
    provide: { firebaseAuth: auth }
  }
})
