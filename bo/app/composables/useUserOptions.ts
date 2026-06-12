import type { UserStatus } from '~~/shared/types/api'
import { FFBAD_RANKS } from '~~/shared/types/api'

// Shared gender / FFBAD rank option lists (used by edit + pending approval) and
// the user-status badge mapping (used by the users list + detail).
export function useUserOptions() {
  const genderOptions = [
    { value: '', label: 'Non renseigné' },
    { value: 'MALE', label: 'Homme' },
    { value: 'FEMALE', label: 'Femme' }
  ]

  const ffbadOptions = [
    { value: '', label: 'Non renseigné' },
    ...FFBAD_RANKS.map(r => ({ value: r, label: r }))
  ]

  const statusBadge = (status: UserStatus): { label: string, color: 'warning' | 'success' | 'error' | 'neutral' } => {
    switch (status) {
      case 'approved': return { label: 'Validé', color: 'success' }
      case 'rejected': return { label: 'Refusé', color: 'error' }
      case 'pending': return { label: 'En attente', color: 'warning' }
      default: return { label: status, color: 'neutral' }
    }
  }

  return { genderOptions, ffbadOptions, statusBadge }
}
