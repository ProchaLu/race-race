extends Node

func _ready() -> void:
	TestWorld.build()
	var team := GameState.player_team()
	print("Start: race %d reserve %d" % [team.driver_ids.size(), team.reserve_driver_ids.size()])
	var free := GameState.free_drivers()
	var a: DriverData = free[0]
	var b: DriverData = free[1]
	var c: DriverData = free[2]
	var opts := ContractLogic.room_options(team, a, ContractData.DriverRole.EQUAL)
	print("Options for race seat: ", opts.map(func(o): return "%s %s" % [GameState.find_person(o.id).last_name, o.action]))
	# 1) release a race driver
	var r := ContractLogic.sign(a, team, {"salary": 1000000, "years": 2, "role": ContractData.DriverRole.EQUAL, "make_room": opts.filter(func(o): return o.action == "release")[0]})
	print("1) %s %s -> race %d reserve %d" % [r.person.last_name, r.action, team.driver_ids.size(), team.reserve_driver_ids.size()])
	# 2) move a race driver to reserve
	opts = ContractLogic.room_options(team, b, ContractData.DriverRole.EQUAL)
	var res := opts.filter(func(o): return o.action == "reserve")
	r = ContractLogic.sign(b, team, {"salary": 1000000, "years": 2, "role": ContractData.DriverRole.EQUAL, "make_room": res[0] if not res.is_empty() else {}})
	print("2) %s %s -> race %d reserve %d" % [r.person.last_name, r.action, team.driver_ids.size(), team.reserve_driver_ids.size()])
	# 3) no choice (AI style)
	r = ContractLogic.sign(c, team, {"salary": 1000000, "years": 2, "role": ContractData.DriverRole.EQUAL})
	print("3) %s %s -> race %d reserve %d" % [r.person.last_name, r.action, team.driver_ids.size(), team.reserve_driver_ids.size()])
	# 4) staff: strategist and race engineer
	for role in [StaffData.Role.STRATEGY_CHIEF, StaffData.Role.RACE_ENGINEER]:
		var hire: StaffData = null
		for s in GameState.free_staff():
			if s.role == role:
				hire = s
				break
		var before := GameState.staff_of_team(team.id).filter(func(s): return s.role == role).size()
		r = ContractLogic.sign(hire, team, {"salary": 500000, "years": 2})
		var after := GameState.staff_of_team(team.id).filter(func(s): return s.role == role).size()
		print("4) %s: %d -> %d, released %s" % [StaffRoles.name_of(role), before, after, r.person.last_name if r else "-"])
	# 5) rival full: hijack sign
	var rival: TeamData = GameState.teams[&"aurum"]
	var d: DriverData = GameState.free_drivers()[0]
	r = ContractLogic.sign(d, rival, {"salary": 1000000, "years": 2})
	print("5) rival race %d reserve %d, released %s" % [rival.driver_ids.size(), rival.reserve_driver_ids.size(), r.person.last_name if r else "-"])
	# All teams within limits?
	var bad := 0
	for t in GameState.teams.values():
		if t.driver_ids.size() > 2 or t.reserve_driver_ids.size() > 1:
			bad += 1
			print("  over limit: %s %d/%d" % [t.short_name, t.driver_ids.size(), t.reserve_driver_ids.size()])
	print("Teams over limit: %d" % bad)
	get_tree().quit()
