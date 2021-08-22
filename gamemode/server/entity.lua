hook.Add("PlayerSpawnedProp", "pk_setpropowner", function(ply, model, ent)
	ent.Owner = ply
	ent:SetNWEntity("Owner", ply)
	ent:SetNW2Entity("Owner", ply)
end)

function GM:OnPhysgunReload() return false end
function GM:PlayerSpawnSENT(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerSpawnSWEP(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerGiveSWEP(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerSpawnEffect(ply) Notify(ply, "You can only spawn props!") return false end
function GM:PlayerSpawnVehicle(ply) Notify(ply, "You can only spawn props!") return false end
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
	game.ConsoleCommand("physgun_timeToArrive 0.025\n")
	game.ConsoleCommand("sv_sticktoground 0\n")
	game.ConsoleCommand("sv_airaccelerate 2000\n")
end

hook.Add("CanProperty", "block_remover_property", function(ply, property, ent)
	return ply:IsAdmin()
end)

function DoPlayerEntitySpawn( ply, entity_name, model, iSkin, strBody )

	local vStart = ply:GetShootPos()
	local vForward = ply:GetAimVector()

	local trace = {}
	trace.start = vStart
	trace.endpos = vStart + ( vForward * 2048 )
	trace.filter = ply

	local tr = util.TraceLine( trace )

	local ent = ents.Create( entity_name )
	if ( !IsValid( ent ) ) then return end

	local ang = ply:EyeAngles()
	ang.yaw = ang.yaw + 180 -- Rotate it 180 degrees in my favour
	ang.roll = 0
	ang.pitch = 0

	if ( entity_name == "prop_ragdoll" ) then
		ang.pitch = -90
		tr.HitPos = tr.HitPos
	end

	ent:SetModel( model )
	ent:SetSkin( iSkin )
	ent:SetAngles( ang )
	ent:SetBodyGroups( strBody )
	ent:SetPos( tr.HitPos )
	ent:Spawn()
	ent:Activate()

	-- Special case for effects
	if ( entity_name == "prop_effect" && IsValid( ent.AttachedEntity ) ) then
		ent.AttachedEntity:SetBodyGroups( strBody )
	end

	-- Attempt to move the object so it sits flush
	-- We could do a TraceEntity instead of doing all
	-- of this - but it feels off after the old way
	local vFlushPoint = tr.HitPos - ( tr.HitNormal * 512 )	-- Find a point that is definitely out of the object in the direction of the floor
	vFlushPoint = ent:NearestPoint( vFlushPoint )			-- Find the nearest point inside the object to that point
	vFlushPoint = ent:GetPos() - vFlushPoint				-- Get the difference
	vFlushPoint = tr.HitPos + vFlushPoint					-- Add it to our target pos

	if ( entity_name != "prop_ragdoll" ) then

		-- Set new position
		ent:SetPos( vFlushPoint )
		ply:SendLua( "achievements.SpawnedProp()" )

	else

		-- With ragdolls we need to move each physobject
		local VecOffset = vFlushPoint - ent:GetPos()
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local phys = ent:GetPhysicsObjectNum( i )
			phys:SetPos( phys:GetPos() + VecOffset )
		end

		ply:SendLua( "achievements.SpawnedRagdoll()" )

	end

	return ent

end
