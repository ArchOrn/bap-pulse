package services

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"
)

// FFBadPlayer is a normalized club member parsed from the FFBAD API.
type FFBadPlayer struct {
	PerID        string
	License      string
	FirstName    string
	LastName     string
	Gender       string // MALE | FEMALE | "" (unknown)
	RankSingles  string // N3, R4, ... or "" when unknown/invalid
	RankDoubles  string
	RankMixed    string
	CoteSingles  int
	CoteDoubles  int
	CoteMixed    int
	IsDataPublic bool
	IsActive     bool
}

// ffbadRawPlayer mirrors the (all-string) JSON shape returned by the FFBAD API.
// Only the fields we consume are mapped.
type ffbadRawPlayer struct {
	PerID        string `json:"PER_ID"`
	License      string `json:"PER_LICENCE"`
	Nom          string `json:"PER_NOM"`
	Prenom       string `json:"PER_PRENOM"`
	PesID        string `json:"PER_PES_ID"`
	SimpleNom    string  `json:"SIMPLE_NOM"`
	DoubleNom    string  `json:"DOUBLE_NOM"`
	MixteNom     string  `json:"MIXTE_NOM"`
	SimpleCote   flexInt `json:"SIMPLE_COTE_FFBAD"`
	DoubleCote   flexInt `json:"DOUBLE_COTE_FFBAD"`
	MixteCote    flexInt `json:"MIXTE_COTE_FFBAD"`
	IsDataPublic string  `json:"PER_IS_DATA_PUBLIC"`
	IsActif      string  `json:"IS_ACTIF"`
}

// flexInt decodes a JSON value that the FFBAD API returns inconsistently as a
// quoted string ("2427"), a bare number (2427), or null — all into an int.
type flexInt int

func (f *flexInt) UnmarshalJSON(b []byte) error {
	s := strings.TrimSpace(string(b))
	if s == "" || s == "null" {
		*f = 0
		return nil
	}
	s = strings.Trim(s, `"`)
	*f = flexInt(atoiSafe(s))
	return nil
}

// FFBadClient talks to the official FFBAD API to fetch a club's roster.
type FFBadClient struct {
	baseURL string
	token   string
	http    *http.Client
}

// NewFFBadClient builds a client. An empty token disables it (Enabled() == false).
func NewFFBadClient(baseURL, token string) *FFBadClient {
	return &FFBadClient{
		baseURL: strings.TrimRight(baseURL, "/"),
		token:   token,
		http:    &http.Client{Timeout: 30 * time.Second},
	}
}

// Enabled reports whether a club token is configured.
func (c *FFBadClient) Enabled() bool { return c != nil && c.token != "" }

// FetchClubRoster retrieves the full club roster from the FFBAD API.
// The endpoint returns every member of the club (scoped by the club token),
// so a licence present here is necessarily a club member.
func (c *FFBadClient) FetchClubRoster(ctx context.Context) ([]FFBadPlayer, error) {
	if !c.Enabled() {
		return nil, fmt.Errorf("FFBAD club token not configured")
	}

	endpoint := fmt.Sprintf("%s/club/?TokenClub=%s", c.baseURL, url.QueryEscape(c.token))
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, err
	}

	resp, err := c.http.Do(req)
	if err != nil {
		return nil, fmt.Errorf("FFBAD request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		snippet, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return nil, fmt.Errorf("FFBAD API returned %d: %s", resp.StatusCode, strings.TrimSpace(string(snippet)))
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	return parseRoster(body)
}

// parseRoster decodes the {"Retour": {...}} envelope. "Retour" is documented as
// an object keyed by numeric strings ("0","1",...) but degrades to [] / null /
// false when the club is empty or the call yields nothing — all treated as an
// empty roster rather than an error.
func parseRoster(body []byte) ([]FFBadPlayer, error) {
	var envelope struct {
		Retour json.RawMessage `json:"Retour"`
	}
	if err := json.Unmarshal(body, &envelope); err != nil {
		return nil, fmt.Errorf("decode FFBAD response: %w", err)
	}

	raw := bytes.TrimSpace(envelope.Retour)
	if len(raw) == 0 || string(raw) == "null" || string(raw) == "false" || string(raw) == "[]" {
		return nil, nil
	}

	var rawPlayers []ffbadRawPlayer

	// Preferred shape: object with numeric string keys.
	asMap := map[string]ffbadRawPlayer{}
	if err := json.Unmarshal(raw, &asMap); err == nil {
		keys := make([]string, 0, len(asMap))
		for k := range asMap {
			keys = append(keys, k)
		}
		sort.Slice(keys, func(i, j int) bool {
			return atoiSafe(keys[i]) < atoiSafe(keys[j])
		})
		for _, k := range keys {
			rawPlayers = append(rawPlayers, asMap[k])
		}
	} else if err := json.Unmarshal(raw, &rawPlayers); err != nil {
		return nil, fmt.Errorf("decode FFBAD Retour: %w", err)
	}

	out := make([]FFBadPlayer, 0, len(rawPlayers))
	for _, p := range rawPlayers {
		if strings.TrimSpace(p.License) == "" {
			continue
		}
		out = append(out, normalizePlayer(p))
	}
	return out, nil
}

func normalizePlayer(p ffbadRawPlayer) FFBadPlayer {
	return FFBadPlayer{
		PerID:        strings.TrimSpace(p.PerID),
		License:      strings.TrimSpace(p.License),
		FirstName:    strings.TrimSpace(p.Prenom),
		LastName:     strings.TrimSpace(p.Nom),
		Gender:       genderFromPES(p.PesID),
		RankSingles:  normalizeRank(p.SimpleNom),
		RankDoubles:  normalizeRank(p.DoubleNom),
		RankMixed:    normalizeRank(p.MixteNom),
		CoteSingles:  int(p.SimpleCote),
		CoteDoubles:  int(p.DoubleCote),
		CoteMixed:    int(p.MixteCote),
		IsDataPublic: p.IsDataPublic == "1",
		IsActive:     p.IsActif == "1",
	}
}

// genderFromPES maps the FFBAD sex id (PER_PES_ID): 1 = male, 2 = female.
func genderFromPES(pesID string) string {
	switch strings.TrimSpace(pesID) {
	case "1":
		return GenderMale
	case "2":
		return GenderFemale
	default:
		return ""
	}
}

// normalizeRank keeps only ranks recognized by the schema CHECK constraint,
// returning "" otherwise (stored as NULL).
func normalizeRank(rank string) string {
	r := strings.ToUpper(strings.TrimSpace(rank))
	if _, ok := InitialEloFromFFBAD[r]; ok {
		return r
	}
	return ""
}

func atoiSafe(s string) int {
	n, err := strconv.Atoi(strings.TrimSpace(s))
	if err != nil {
		return 0
	}
	return n
}

// EloFromCote seeds a tableau's starting ELO from the FFBAD cote when available,
// falling back to the rank/gender-based heuristic for players without a cote.
func EloFromCote(cote int, rank, gender string) int {
	if cote > 0 {
		return cote
	}
	return InitialEloFor(rank, gender)
}
