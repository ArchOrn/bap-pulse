export function useApi() {
  const config = useRuntimeConfig()
  const token = useState<string | null>('auth:token')

  const baseURL = config.public.apiBaseUrl as string

  // Returns current headers at call time — middleware guarantees token exists on protected pages
  const authHeaders = (): Record<string, string> =>
    token.value ? { Authorization: `Bearer ${token.value}` } : {}

  return { baseURL, authHeaders }
}
