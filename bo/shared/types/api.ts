export interface User {
  id: string
  first_name: string
  last_name: string
  email: string
  elo: number
  role: 'player' | 'admin'
  created_at: string
}

export interface Match {
  id: string
  match_type: 'SINGLES' | 'DOUBLES' | 'MIXED'
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

export interface UserRanking {
  Rank: number
  User: User
}

// Alias to avoid conflicts with firebase/auth's `User` type in plugins/composables.
export type ApiUser = User
