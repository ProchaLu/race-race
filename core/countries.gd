## Country codes used in the game world and their display names.
class_name Countries
extends RefCounted

const NAMES := {
	"AE": "UAE", "AR": "Argentina", "AT": "Austria", "AU": "Australia", "AZ": "Azerbaijan",
	"BE": "Belgium", "BR": "Brazil", "CA": "Canada", "CH": "Switzerland", "CN": "China",
	"DE": "Germany", "DK": "Denmark", "ES": "Spain", "FI": "Finland", "FR": "France",
	"GB": "United Kingdom", "HU": "Hungary", "IN": "India", "IT": "Italy", "JP": "Japan",
	"MC": "Monaco", "MX": "Mexico", "NL": "Netherlands", "NO": "Norway", "NZ": "New Zealand",
	"QA": "Qatar", "SA": "Saudi Arabia", "SE": "Sweden", "SG": "Singapore", "US": "United States",
}


static func name_of(code: String) -> String:
	return Loc.t(NAMES.get(code, code))
