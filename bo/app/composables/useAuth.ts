import {
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  GoogleAuthProvider,
  signInWithPopup
} from 'firebase/auth'
import type { User, UserCredential } from 'firebase/auth'

export function useAuth() {
  const { $firebaseAuth } = useNuxtApp()
  const config = useRuntimeConfig()
  const apiBaseUrl = config.public.apiBaseUrl as string

  const user = useState<User | null>('auth:user')
  const token = useState<string | null>('auth:token')
  const isAdmin = useState<boolean>('auth:isAdmin')

  // Syncs the user profile from the API after a successful Firebase sign-in.
  // Throws 'auth/not-admin' if the DB role is not 'admin' — sign-out is handled here.
  const syncAfterLogin = async (cred: UserCredential) => {
    const idToken = await cred.user.getIdToken()
    token.value = idToken
    user.value = cred.user
    try {
      const displayName = cred.user.displayName ?? ''
      const [firstName, ...rest] = displayName.split(' ')
      const dbUser = await $fetch<ApiUser>(`${apiBaseUrl}/auth/sync`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${idToken}` },
        body: { first_name: firstName, last_name: rest.join(' ') }
      })
      if (dbUser.role !== 'admin') {
        throw Object.assign(new Error('Accès réservé aux administrateurs.'), { code: 'auth/not-admin' })
      }
      isAdmin.value = true
    } catch (e) {
      // Sign out and clear state on any error (not-admin or API failure).
      await firebaseSignOut($firebaseAuth)
      user.value = null
      token.value = null
      isAdmin.value = false
      throw e
    }
  }

  const signIn = async (email: string, password: string) => {
    const cred = await signInWithEmailAndPassword($firebaseAuth, email, password)
    await syncAfterLogin(cred)
  }

  const signInWithGoogle = async () => {
    const provider = new GoogleAuthProvider()
    const cred = await signInWithPopup($firebaseAuth, provider)
    await syncAfterLogin(cred)
  }

  const signOut = async () => {
    await firebaseSignOut($firebaseAuth)
    await navigateTo('/login')
  }

  return { user, token, isAdmin, signIn, signInWithGoogle, signOut }
}
