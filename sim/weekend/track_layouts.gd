## Placeholder layouts for the 24 calendar tracks, only for the weekend
## simulation until the real tracks are built. Each one is modelled on the
## character of a real circuit (noted per entry).
##
## lap: reference lap of an average car (s); the speed profile is scaled to it.
## layout: numbers are straights (relative length, scaled so the lap has
## `length` metres), [km/h, metres] are corners (apex speed, length).
## overtake: track-specific factor on top of the straight lengths
## (street circuits and narrow tracks < 1). sc: safety car risk.
class_name TrackLayouts
extends RefCounted

const LAYOUTS := {
	# Bahrain: long straights, heavy braking, rough surface.
	&"port_aurel": {"lap": 92.0, "length": 5412, "pit": 23.0, "wear": 1.35, "overtake": 1.15, "drs": 3, "temp": [25, 40], "rain": 0.02, "sc": 1.0,
		"layout": [1000, [75, 90], 180, [110, 110], 120, [160, 150], 500, [65, 80], 250, [190, 300], 120, [115, 120], 150, [95, 90], 200, [165, 220], 650, [70, 90], 220, [180, 180], 200, [130, 140], 280, [100, 100], 600]},
	# Jeddah: very fast street circuit, walls everywhere.
	&"sandhaven": {"lap": 89.0, "length": 6174, "pit": 20.0, "wear": 0.85, "overtake": 1.6, "drs": 3, "temp": [28, 35], "rain": 0.02, "sc": 1.8,
		"layout": [700, [80, 90], 200, [240, 300], 100, [230, 250], 150, [250, 300], 100, [220, 260], 150, [260, 300], 200, [90, 100], 600, [240, 300], 200, [260, 350], 300, [70, 90], 800, [230, 300], 400, [95, 100], 900]},
	# Melbourne: fast park circuit, safety cars likely.
	&"kingsbridge": {"lap": 80.0, "length": 5278, "pit": 19.0, "wear": 0.9, "overtake": 1.3, "drs": 3, "temp": [20, 35], "rain": 0.2, "sc": 1.5,
		"layout": [650, [95, 100], 150, [130, 110], 400, [170, 150], 150, [240, 250], 300, [110, 100], 350, [230, 220], 150, [200, 180], 500, [90, 100], 250, [250, 250], 600, [120, 120], 250, [85, 90], 500]},
	# Suzuka: flowing high-speed esses, hard to pass, tyre-heavy.
	&"kaigan": {"lap": 92.0, "length": 5807, "pit": 22.0, "wear": 1.3, "overtake": 0.6, "drs": 1, "temp": [22, 40], "rain": 0.3, "sc": 1.0,
		"layout": [850, [230, 250], 100, [200, 450], 100, [150, 200], 150, [250, 300], 100, [110, 110], 150, [90, 100], 300, [200, 250], 250, [270, 350], 350, [60, 80], 600, [310, 300], 400, [85, 90], 500]},
	# Shanghai: very long back straight, long front-left corners.
	&"linhai": {"lap": 95.0, "length": 5451, "pit": 23.0, "wear": 1.2, "overtake": 0.6, "drs": 2, "temp": [20, 40], "rain": 0.25, "sc": 1.0,
		"layout": [700, [85, 350], 200, [120, 100], 300, [100, 110], 200, [170, 200], 250, [110, 250], 250, [230, 250], 200, [150, 200], 300, [60, 120], 1200, [80, 90], 400]},
	# Miami: hot semi-street circuit, slow chicane section.
	&"coral_coast": {"lap": 90.0, "length": 5412, "pit": 20.0, "wear": 1.0, "overtake": 0.9, "drs": 3, "temp": [40, 55], "rain": 0.3, "sc": 1.4,
		"layout": [800, [110, 100], 100, [180, 200], 150, [230, 300], 300, [95, 90], 500, [150, 150], 200, [70, 150], 300, [80, 90], 1000, [90, 100], 300, [150, 150], 500]},
	# Barcelona: aero test track, high tyre load, hard to follow.
	&"sierra_alta": {"lap": 77.0, "length": 4657, "pit": 22.0, "wear": 1.3, "overtake": 0.6, "drs": 2, "temp": [30, 50], "rain": 0.1, "sc": 0.8,
		"layout": [950, [120, 150], 100, [210, 250], 250, [100, 120], 250, [150, 160], 200, [95, 100], 350, [240, 300], 150, [120, 150], 300, [160, 180], 250, [200, 250], 100, [110, 120], 400]},
	# Monaco: slow, narrow, almost no overtaking, qualifying is everything.
	&"port_monique": {"lap": 74.0, "length": 3337, "laps": 78, "pit": 19.0, "wear": 0.6, "overtake": 0.12, "drs": 1, "temp": [30, 50], "rain": 0.15, "sc": 1.5,
		"layout": [400, [110, 100], 300, [140, 150], 150, [60, 80], 100, [70, 60], 200, [50, 60], 100, [100, 100], 500, [260, 300], 150, [70, 80], 150, [130, 120], 100, [60, 90], 100, [90, 80], 200]},
	# Imola: old-school, narrow, long pit lane.
	&"valdera": {"lap": 78.0, "length": 4909, "pit": 27.0, "wear": 1.0, "overtake": 0.5, "drs": 1, "temp": [25, 45], "rain": 0.3, "sc": 1.3,
		"layout": [700, [200, 250], 100, [90, 100], 400, [240, 250], 250, [100, 120], 250, [150, 150], 350, [60, 90], 400, [190, 200], 200, [80, 100], 400, [150, 200], 300]},
	# Spa: very long lap, long full-throttle sections, weather lottery.
	&"kessling": {"lap": 107.0, "length": 7004, "pit": 19.0, "wear": 1.1, "overtake": 1.4, "drs": 2, "temp": [15, 35], "rain": 0.45, "sc": 1.2,
		"layout": [300, [65, 90], 200, [260, 300], 1500, [80, 100], 200, [200, 200], 300, [110, 150], 200, [180, 200], 300, [150, 300], 400, [250, 300], 300, [300, 300], 600, [80, 100], 400]},
	# Monza: temple of speed, low downforce, slipstream battles.
	&"sorrento": {"lap": 83.0, "length": 5793, "pit": 25.0, "wear": 0.8, "overtake": 1.15, "drs": 2, "temp": [25, 45], "rain": 0.15, "sc": 1.0,
		"layout": [1100, [75, 120], 300, [260, 300], 400, [110, 150], 450, [150, 200], 700, [100, 120], 300, [200, 300], 900, [220, 350], 600]},
	# Silverstone: high-speed sweepers, rain possible any time.
	&"harrow_park": {"lap": 89.0, "length": 5891, "pit": 20.0, "wear": 1.3, "overtake": 1.5, "drs": 2, "temp": [18, 40], "rain": 0.35, "sc": 1.0,
		"layout": [500, [240, 250], 200, [200, 200], 150, [100, 100], 350, [85, 90], 550, [90, 100], 400, [290, 300], 50, [230, 250], 50, [260, 250], 300, [130, 150], 700, [100, 110], 200, [250, 300], 300, [110, 150], 300]},
	# Las Vegas: cold night street circuit, huge straight, tyres hard to warm.
	&"oakmere": {"lap": 95.0, "length": 6201, "pit": 21.0, "wear": 0.7, "overtake": 1.2, "drs": 2, "temp": [10, 20], "rain": 0.02, "sc": 1.4,
		"layout": [600, [70, 90], 400, [150, 150], 300, [80, 90], 400, [110, 120], 1900, [80, 100], 400, [150, 180], 200, [85, 90], 300, [110, 120], 600]},
	# Mexico: thin air, long run to turn 1, stadium section.
	&"monteverde": {"lap": 80.0, "length": 4304, "pit": 22.0, "wear": 0.9, "overtake": 0.6, "drs": 3, "temp": [30, 50], "rain": 0.15, "sc": 1.1,
		"layout": [1200, [90, 100], 100, [130, 120], 300, [160, 150], 400, [85, 90], 200, [130, 150], 300, [200, 300], 250, [60, 200], 200, [110, 120], 300]},
	# Red Bull Ring: short lap, uphill straights, three DRS zones.
	&"alpenring": {"lap": 67.0, "length": 4318, "pit": 20.0, "wear": 1.05, "overtake": 1.6, "drs": 3, "temp": [20, 45], "rain": 0.3, "sc": 0.9,
		"layout": [550, [110, 150], 700, [70, 90], 600, [90, 110], 300, [230, 250], 200, [150, 200], 150, [200, 200], 300, [230, 250], 350, [160, 180], 400]},
	# Zandvoort: narrow, banked, hard to pass.
	&"duinen": {"lap": 73.0, "length": 4259, "pit": 21.0, "wear": 1.15, "overtake": 0.4, "drs": 2, "temp": [18, 35], "rain": 0.3, "sc": 1.2,
		"layout": [650, [90, 120], 150, [210, 250], 200, [120, 150], 150, [160, 180], 200, [230, 250], 200, [100, 120], 300, [180, 200], 200, [220, 250], 150, [250, 300], 300]},
	# Hungaroring: twisty, hot, "Monaco without walls".
	&"pusztavar": {"lap": 80.0, "length": 4381, "pit": 20.0, "wear": 1.05, "overtake": 0.45, "drs": 2, "temp": [30, 55], "rain": 0.15, "sc": 0.9,
		"layout": [750, [85, 100], 300, [110, 150], 350, [90, 110], 250, [200, 200], 150, [130, 150], 150, [120, 150], 200, [90, 100], 150, [200, 200], 150, [140, 150], 250, [110, 150], 300]},
	# Montreal: stop-and-go, walls close, frequent safety cars.
	&"lakeshore": {"lap": 75.0, "length": 4361, "pit": 18.0, "wear": 0.85, "overtake": 1.0, "drs": 3, "temp": [20, 45], "rain": 0.25, "sc": 1.6,
		"layout": [500, [130, 120], 100, [70, 100], 400, [110, 100], 350, [130, 150], 500, [100, 100], 300, [60, 90], 1000, [110, 120], 400]},
	# Singapore: many slow corners, very long pit loss, safety car almost certain.
	&"marina_kota": {"lap": 96.0, "length": 4940, "laps": 62, "pit": 28.0, "wear": 1.0, "overtake": 0.4, "drs": 3, "temp": [28, 35], "rain": 0.3, "sc": 2.0,
		"layout": [600, [110, 100], 150, [90, 90], 600, [80, 90], 150, [110, 100], 150, [90, 90], 250, [80, 90], 150, [120, 100], 200, [80, 90], 250, [100, 90], 150, [90, 90], 250, [110, 100], 200, [70, 90], 300]},
	# Baku: tight old town plus a 2 km flat-out run.
	&"caspian": {"lap": 104.0, "length": 6003, "pit": 20.0, "wear": 0.75, "overtake": 1.15, "drs": 2, "temp": [25, 45], "rain": 0.05, "sc": 1.8,
		"layout": [300, [85, 100], 250, [95, 100], 300, [90, 100], 250, [80, 100], 200, [100, 100], 250, [60, 110], 300, [110, 120], 200, [80, 90], 1800, [95, 100], 400]},
	# Austin: uphill turn 1, esses, long back straight.
	&"lone_star": {"lap": 97.0, "length": 5513, "pit": 21.0, "wear": 1.2, "overtake": 0.7, "drs": 2, "temp": [25, 45], "rain": 0.15, "sc": 1.0,
		"layout": [400, [70, 90], 150, [220, 250], 150, [180, 200], 100, [160, 200], 200, [110, 120], 300, [75, 90], 1100, [70, 90], 300, [120, 150], 150, [90, 100], 200, [150, 200], 400]},
	# Interlagos: short lap, anti-clockwise, rain and chaos.
	&"rio_celeste": {"lap": 72.0, "length": 4309, "laps": 71, "pit": 20.0, "wear": 1.05, "overtake": 1.8, "drs": 2, "temp": [20, 50], "rain": 0.4, "sc": 1.4,
		"layout": [550, [90, 120], 200, [230, 250], 600, [110, 120], 250, [150, 150], 150, [90, 100], 200, [170, 180], 250, [100, 120], 250, [240, 300], 600]},
	# Qatar: fast sweepers, brutal on tyres.
	&"desert_mirage": {"lap": 85.0, "length": 5419, "pit": 25.0, "wear": 1.5, "overtake": 0.8, "drs": 1, "temp": [25, 35], "rain": 0.01, "sc": 0.8,
		"layout": [1000, [110, 120], 300, [230, 300], 150, [200, 250], 150, [260, 300], 100, [240, 250], 250, [90, 100], 200, [250, 300], 200, [210, 250], 300, [180, 250], 400]},
	# Abu Dhabi: twilight finale, two long straights, slow last sector.
	&"al_noor": {"lap": 87.0, "length": 5281, "pit": 22.0, "wear": 0.9, "overtake": 0.6, "drs": 2, "temp": [25, 35], "rain": 0.01, "sc": 0.9,
		"layout": [600, [110, 120], 200, [230, 250], 300, [70, 90], 1100, [80, 90], 800, [90, 100], 200, [110, 100], 150, [100, 100], 200, [150, 200], 400]},
}


static func has_layout(track_id: StringName) -> bool:
	return LAYOUTS.has(track_id)


static func get_layout(track_id: StringName) -> Dictionary:
	return LAYOUTS[track_id]
