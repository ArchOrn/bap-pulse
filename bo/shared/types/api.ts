export type Tableau = 'SINGLES' | 'DOUBLES' | 'MIXED'

export type Gender = 'MALE' | 'FEMALE'

export type FfbadRank
  = | 'NC'
    | 'P12' | 'P11' | 'P10'
    | 'D9' | 'D8' | 'D7'
    | 'R6' | 'R5' | 'R4'
    | 'N3' | 'N2' | 'N1'

export const FFBAD_RANKS: FfbadRank[] = [
  'NC',
  'P12', 'P11', 'P10',
  'D9', 'D8', 'D7',
  'R6', 'R5', 'R4',
  'N3', 'N2', 'N1'
]

export type UserStatus = 'pending' | 'approved' | 'rejected'

export interface User {
  id: string
  first_name: string
  last_name: string
  email: string
  elo_singles: number
  elo_doubles: number
  elo_mixed: number
  gender: Gender | null
  ffbad_rank: FfbadRank | null
  role: 'player' | 'admin'
  status: UserStatus
  license_number: string | null
  created_at: string
}

// ---------- Club roster (FFBAD sync) ----------

export interface ClubRosterEntry {
  license_number: string
  per_id: string | null
  first_name: string
  last_name: string
  gender: Gender | null
  rank_singles: FfbadRank | null
  rank_doubles: FfbadRank | null
  rank_mixed: FfbadRank | null
  cote_singles: number | null
  cote_doubles: number | null
  cote_mixed: number | null
  is_data_public: boolean
  matched_user_id: string | null
  synced_at: string
}

export interface RosterResponse {
  entries: ClubRosterEntry[]
  last_synced_at: string | null
}

export interface RosterSyncResult {
  fetched: number
  upserted: number
  auto_approved: number
  skipped_anonymous: number
  errors: string[]
}

export interface Match {
  id: string
  match_type: Tableau
  team1_player1_id: string
  team1_player2_id: string | null
  team2_player1_id: string
  team2_player2_id: string | null
  set1_team1: number
  set1_team2: number
  set2_team1: number
  set2_team2: number
  set3_team1: number | null
  set3_team2: number | null
  played_at: string
  validated: boolean
}

// Alias to avoid conflicts with firebase/auth's `User` type in plugins/composables.
export type ApiUser = User

// ---------- News ----------

export type NewsSource = 'MANUAL' | 'AUTO_MATCH'

export interface News {
  id: string
  emoji: string
  title: string // Markdown
  body: string | null // Markdown (multi-line)
  source: NewsSource
  match_id: string | null
  created_by: string | null
  created_at: string
}

// ---------- Rankings ----------
//
// All ranking entries share `rank` + `user`. The other fields are specific to
// each ranking type returned by the API.

export interface EloRanking {
  rank: number
  user: ApiUser
  elo: number
  tableau: Tableau
}

export interface PerformanceRanking {
  rank: number
  user: ApiUser
  points: number
}

export interface LeagueRanking {
  rank: number
  user: ApiUser
  wins: number
  losses: number
  sets_won: number
  sets_lost: number
  sets_diff: number
}

export interface MatchesPlayedRanking {
  rank: number
  user: ApiUser
  matches_played: number
}

export interface GiantKillerRanking {
  rank: number
  user: ApiUser
  upset_wins: number
}

// Helper: pick the ELO field for a given tableau.
export function eloFor(user: ApiUser, tableau: Tableau): number {
  switch (tableau) {
    case 'DOUBLES': return user.elo_doubles
    case 'MIXED': return user.elo_mixed
    default: return user.elo_singles
  }
}
