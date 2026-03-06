import {
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  GoogleAuthProvider,
  signInWithPopup
} from 'firebase/auth'
import type { User } from 'firebase/auth'

export function useAuth() {
  const { $firebaseAuth } = useNuxtApp()

  const user = useState<User | null>('auth:user')
  const token = useState<string | null>('auth:token')

  const signIn = async (email: string, password: string) => {
    await signInWithEmailAndPassword($firebaseAuth, email, password)
  }

  const signInWithGoogle = async () => {
    const provider = new GoogleAuthProvider()
    await signInWithPopup($firebaseAuth, provider)
  }

  const signOut = async () => {
    await firebaseSignOut($firebaseAuth)
    await navigateTo('/login')
  }

  return { user, token, signIn, signInWithGoogle, signOut }
}
