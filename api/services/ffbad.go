package services

const (
	// FemaleOffset is added to the FFBAD-derived initial ELO for female players.
	FemaleOffset = -200

	// DefaultInitialElo is used when no FFBAD rank is provided.
	DefaultInitialElo = 1000

	// GenderMale and GenderFemale are the canonical gender values stored in DB.
	GenderMale   = "MALE"
	GenderFemale = "FEMALE"
)

// InitialEloFromFFBAD maps an FFBAD rank to a starting ELO. Anchors provided:
// P12=1000, P11=1100, D7=1500, R6=1600, N3=1950. Intermediate values
// interpolated; tweak here if the federation publishes different conversions.
var InitialEloFromFFBAD = map[string]int{
	"NC":  1000,
	"P12": 1000,
	"P11": 1100,
	"P10": 1200,
	"D9":  1300,
	"D8":  1400,
	"D7":  1500,
	"R6":  1600,
	"R5":  1700,
	"R4":  1800,
	"N3":  1950,
	"N2":  2100,
	"N1":  2300,
}

// InitialEloFor returns the starting ELO for a freshly-created user.
// Unknown ranks fall back to DefaultInitialElo. FEMALE applies FemaleOffset.
func InitialEloFor(ffbadRank, gender string) int {
	base, ok := InitialEloFromFFBAD[ffbadRank]
	if !ok {
		base = DefaultInitialElo
	}
	if gender == GenderFemale {
		base += FemaleOffset
	}
	return base
}
