package services

import "testing"

// Mirrors the real FFBAD API shape: {"Retour": {"0": {...}}, "Code", "Statut"}.
const ffbadSample = `{
  "Code": 200,
  "Statut": "OK",
  "Retour": {
    "0": {
      "PER_ID": "724632",
      "PER_LICENCE": "06835632",
      "PER_NOM": "OMBROUCK",
      "PER_PRENOM": "Matthieu",
      "PER_PES_ID": "1",
      "SIMPLE_NOM": "N3",
      "SIMPLE_COTE_FFBAD": "2427",
      "DOUBLE_NOM": "R4",
      "DOUBLE_COTE_FFBAD": "2043",
      "MIXTE_NOM": "R4",
      "MIXTE_COTE_FFBAD": "2100",
      "PER_IS_DATA_PUBLIC": "1",
      "IS_ACTIF": "1"
    },
    "1": {
      "PER_LICENCE": "12345678",
      "PER_NOM": "MARTIN",
      "PER_PRENOM": "Claire",
      "PER_PES_ID": "2",
      "SIMPLE_NOM": "-",
      "SIMPLE_COTE_FFBAD": "",
      "DOUBLE_NOM": "D9",
      "DOUBLE_COTE_FFBAD": 1280,
      "MIXTE_NOM": "-",
      "MIXTE_COTE_FFBAD": "",
      "PER_IS_DATA_PUBLIC": "0",
      "IS_ACTIF": "1"
    }
  }
}`

func TestParseRoster(t *testing.T) {
	players, err := parseRoster([]byte(ffbadSample))
	if err != nil {
		t.Fatalf("parseRoster: %v", err)
	}
	if len(players) != 2 {
		t.Fatalf("expected 2 players, got %d", len(players))
	}

	p0 := players[0]
	if p0.License != "06835632" || p0.LastName != "OMBROUCK" || p0.FirstName != "Matthieu" {
		t.Errorf("p0 identity wrong: %+v", p0)
	}
	if p0.Gender != GenderMale {
		t.Errorf("p0 gender = %q, want MALE", p0.Gender)
	}
	if p0.RankSingles != "N3" || p0.CoteSingles != 2427 {
		t.Errorf("p0 singles = %q/%d, want N3/2427", p0.RankSingles, p0.CoteSingles)
	}

	p1 := players[1]
	if p1.Gender != GenderFemale {
		t.Errorf("p1 gender = %q, want FEMALE", p1.Gender)
	}
	// "-" is not a valid rank → normalized to "".
	if p1.RankSingles != "" {
		t.Errorf("p1 rankSingles = %q, want empty", p1.RankSingles)
	}
	if p1.RankDoubles != "D9" || p1.CoteDoubles != 1280 {
		t.Errorf("p1 doubles = %q/%d, want D9/1280", p1.RankDoubles, p1.CoteDoubles)
	}
	if p1.IsDataPublic {
		t.Errorf("p1 should not be data-public")
	}
}

func TestParseRosterEmpty(t *testing.T) {
	for _, body := range []string{`{"Retour": []}`, `{"Retour": null}`, `{"Retour": false}`, `{}`} {
		players, err := parseRoster([]byte(body))
		if err != nil {
			t.Errorf("parseRoster(%s): unexpected error %v", body, err)
		}
		if len(players) != 0 {
			t.Errorf("parseRoster(%s): expected empty, got %d", body, len(players))
		}
	}
}

func TestEloFromCote(t *testing.T) {
	if got := EloFromCote(2427, "N3", GenderMale); got != 2427 {
		t.Errorf("with cote: got %d, want 2427", got)
	}
	// No cote → falls back to rank/gender heuristic.
	if got := EloFromCote(0, "N3", GenderMale); got != InitialEloFor("N3", GenderMale) {
		t.Errorf("no cote fallback: got %d", got)
	}
}
