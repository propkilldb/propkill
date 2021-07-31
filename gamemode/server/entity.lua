hook.Add("PlayerSpawnedProp", "pk_setpropowner", function(ply, model, ent)
	ent.Owner = ply
	ent:SetNW2Entity("Owner", ply)
end)

function GM:OnPhysgunReload() return false end
function GM:PlayerSpawnSENT(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerSpawnSWEP(ply) Notify(ply, "You can only spawn props!") return false end
//function GM:PlayerGiveSWEP(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerSpawnEffect(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerSpawnVehicle(ply) Notify(ply, "You can only spawn props!") return true end
function GM:PlayerSpawnNPC(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerSpawnRagdoll(ply) Notify(ply, "You can only spawn props!") return false end

hook.Add("PlayerSpawnProp", "pk_canspawnprop", function(ply, model)
	if not ply:Alive() then
		return false
	end

	if ply:Team() == TEAM_SPECTATOR then
		return false
	end
end)

function GM:InitPostEntity()
	physenv.SetPerformanceSettings({
		LookAheadTimeObjectsVsObject = 2,
		LookAheadTimeObjectsVsWorld = 21,
		MaxAngularVelocity = 3636,
		MaxCollisionChecksPerTimestep = 50,
		MaxCollisionsPerObjectPerTimestep = 48,
		MaxFrictionMass = 1,
		MaxVelocity = 2200,
		MinFrictionMass = 99999,
	})

	game.ConsoleCommand("physgun_DampingFactor 1\n")
	game.ConsoleCommand("physgun_timeToArrive 0.016\n")
	game.ConsoleCommand("sv_sticktoground 0\n")
	game.ConsoleCommand("sv_airaccelerate 2000\n")
end

hook.Add("CanProperty", "block_remover_property", function(ply, property, ent)
	return ply:IsAdmin()
end)
