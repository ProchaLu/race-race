## Fictional names by nationality, for generated people (market, staff,
## youth). Names are combined randomly, so they are not meant to match
## real people.
class_name NameGenerator
extends RefCounted

## Language group per nationality.
const GROUP := {
	"GB": "english", "US": "english", "CA": "english", "AU": "english", "NZ": "english",
	"DE": "german", "AT": "german", "CH": "german", "IT": "italian", "ES": "spanish",
	"AR": "spanish", "MX": "spanish", "BR": "portuguese", "FR": "french", "BE": "french",
	"MC": "french", "NL": "dutch", "SE": "nordic", "NO": "nordic", "DK": "nordic",
	"FI": "finnish", "JP": "japanese", "CN": "chinese", "IN": "indian",
}
const MALE := {
	"english": ["Oliver", "Harry", "Jack", "Charlie", "Thomas", "Ryan", "Liam", "Nathan", "Ethan", "Callum", "Max", "Dylan", "Owen", "Lewis"],
	"german": ["Lukas", "Felix", "Jonas", "Leon", "Tobias", "Niklas", "Moritz", "Paul", "Fabian", "Jan", "Simon", "Florian"],
	"italian": ["Luca", "Marco", "Matteo", "Andrea", "Lorenzo", "Davide", "Giorgio", "Simone", "Alessio", "Federico", "Pietro"],
	"spanish": ["Pablo", "Diego", "Javier", "Sergio", "Mateo", "Alvaro", "Carlos", "Nicolas", "Santiago", "Tomas", "Manuel"],
	"portuguese": ["Gabriel", "Rafael", "Lucas", "Mateus", "Thiago", "Felipe", "Bruno", "Caio", "Enzo", "Vinicius"],
	"french": ["Louis", "Hugo", "Theo", "Arthur", "Jules", "Adrien", "Mathis", "Antoine", "Romain", "Victor"],
	"dutch": ["Daan", "Sem", "Milan", "Ruben", "Bram", "Thijs", "Lars", "Jesse", "Niels"],
	"nordic": ["Elias", "Oscar", "William", "Emil", "Axel", "Isak", "Magnus", "Henrik", "Viktor", "Anders"],
	"finnish": ["Aleksi", "Eetu", "Joonas", "Kalle", "Lauri", "Mikko", "Onni", "Valtteri", "Juho"],
	"japanese": ["Haruto", "Ren", "Sota", "Yuto", "Kaito", "Riku", "Takumi", "Daiki", "Kenta"],
	"chinese": ["Wei", "Hao", "Jun", "Yi", "Zhen", "Tao", "Ming", "Chen", "Bo"],
	"indian": ["Arjun", "Rohan", "Vikram", "Aditya", "Karan", "Nikhil", "Rahul", "Dev", "Ishaan"],
}
const FEMALE := {
	"english": ["Emma", "Sophie", "Grace", "Olivia", "Lucy", "Hannah", "Chloe", "Megan", "Jessica"],
	"german": ["Anna", "Lena", "Laura", "Julia", "Hannah", "Sarah", "Katharina", "Miriam", "Paula"],
	"italian": ["Giulia", "Chiara", "Sofia", "Francesca", "Elena", "Martina", "Alessia"],
	"spanish": ["Lucia", "Carmen", "Sofia", "Paula", "Elena", "Valentina", "Marta"],
	"portuguese": ["Ana", "Beatriz", "Mariana", "Julia", "Larissa", "Camila"],
	"french": ["Camille", "Chloe", "Manon", "Lea", "Claire", "Juliette", "Elise"],
	"dutch": ["Sanne", "Fleur", "Lotte", "Eva", "Anouk", "Iris"],
	"nordic": ["Astrid", "Freja", "Ingrid", "Maja", "Saga", "Ebba", "Linnea"],
	"finnish": ["Aino", "Emilia", "Helmi", "Venla", "Sanni", "Iida"],
	"japanese": ["Yui", "Aoi", "Hana", "Sakura", "Mei", "Rina"],
	"chinese": ["Li", "Xin", "Ying", "Mei", "Jing", "Lan"],
	"indian": ["Priya", "Ananya", "Kavya", "Meera", "Isha", "Diya"],
}
const LAST := {
	"english": ["Carter", "Whitfield", "Hayes", "Bennett", "Holloway", "Marsh", "Ashford", "Doyle", "Prescott", "Rowe", "Hartley", "Fenwick", "Sutton", "Barlow", "Kendrick", "Lockwood"],
	"german": ["Hartmann", "Brenner", "Vogt", "Kessler", "Lindner", "Albrecht", "Seidel", "Kraus", "Engel", "Roth", "Haller", "Winter", "Sommer"],
	"italian": ["Rinaldi", "Galli", "Moretti", "Fabbri", "Conti", "Bellini", "Marchetti", "Ferri", "Serra", "Benetti", "Lombardi", "Caruso"],
	"spanish": ["Navarro", "Ortega", "Herrera", "Molina", "Delgado", "Castillo", "Ramos", "Iglesias", "Vega", "Rubio", "Morales"],
	"portuguese": ["Oliveira", "Costa", "Ribeiro", "Almeida", "Carvalho", "Teixeira", "Moura", "Barbosa", "Pinto", "Freitas"],
	"french": ["Laurent", "Dubois", "Moreau", "Girard", "Faure", "Blanchard", "Mercier", "Chevalier", "Rousseau", "Lemoine"],
	"dutch": ["de Vries", "Bakker", "Visser", "Smit", "Mulder", "van Dijk", "Bos", "Vermeer", "de Graaf"],
	"nordic": ["Lindgren", "Berg", "Holm", "Dahl", "Nystrom", "Strand", "Sandberg", "Eriksen", "Lund", "Hedlund"],
	"finnish": ["Virtanen", "Laine", "Heikkila", "Salonen", "Lehtonen", "Koivisto", "Niemi", "Rantala"],
	"japanese": ["Saito", "Kimura", "Hayashi", "Mori", "Ishikawa", "Ogawa", "Fujita", "Matsuda"],
	"chinese": ["Zhang", "Liu", "Zhao", "Huang", "Lin", "Xu", "Sun", "Guo"],
	"indian": ["Sharma", "Nair", "Iyer", "Reddy", "Kapoor", "Menon", "Rao", "Pillai"],
}
## Nationalities for generated people, weighted towards motorsport countries.
const NATIONALITY_POOL := ["GB", "GB", "GB", "DE", "DE", "IT", "IT", "FR", "FR", "ES", "NL", "BE",
	"AT", "CH", "SE", "NO", "DK", "FI", "US", "US", "CA", "AU", "NZ", "BR", "BR", "AR", "MX", "JP", "CN", "IN"]


static func random_nationality(r: RandomNumberGenerator) -> String:
	return NATIONALITY_POOL[r.randi() % NATIONALITY_POOL.size()]


## Returns [first name, last name].
static func full_name(r: RandomNumberGenerator, nationality: String, female: bool) -> Array:
	var group: String = GROUP.get(nationality, "english")
	var firsts: Array = (FEMALE if female else MALE)[group]
	var lasts: Array = LAST[group]
	return [firsts[r.randi() % firsts.size()], lasts[r.randi() % lasts.size()]]
