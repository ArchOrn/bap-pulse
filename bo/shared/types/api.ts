export interface Player {
  id: string
  name: string
  email: string
  elo: number
  created_at: string
}

export interface Match {
  id: string
  match_type: 'SINGLES' | 'DOUBLES' | 'MIXED'
  team1_player1_id: string
  team1_player2_id: string | null
  team2_player1_id: string
  team2_player2_id: string | null
  score_team1: number
  score_team2: number
  played_at: string
  validated: boolean
}

export interface PlayerRanking {
  Rank: number
  Player: Player
}
