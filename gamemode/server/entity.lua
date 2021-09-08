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

function DoPlayerEntitySpawn( ply, entity_name, model, iSkin, strBody, mv )

	local origin = mv:GetOrigin()
	origin.z = ply:GetShootPos().z // cbf doing height checks
	local vStart = origin + mv:GetVelocity()/66.6
	local vForward = mv:GetAngles():Forward()

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

	if tr.HitNormal.z != 1 then
		local hulltr = util.TraceHull({
			start = ply:GetShootPos(),
			endpos = tr.HitPos,
			maxs = ent:OBBMaxs(),
			mins = ent:OBBMins(),
			filter = ply
		})

		vFlushPoint = hulltr.HitPos
	end

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

function GMODSpawnProp( ply, model, iSkin, strBody, mv )

	if ( IsValid( ply ) && !gamemode.Call( "PlayerSpawnProp", ply, model ) ) then return end

	local e = DoPlayerEntitySpawn( ply, "prop_physics", model, iSkin, strBody, mv )
	if ( !IsValid( e ) ) then return end

	if ( IsValid( ply ) ) then
		gamemode.Call( "PlayerSpawnedProp", ply, model, e )
	end

	-- This didn't work out - todo: Find a better way.
	--timer.Simple( 0.01, CheckPropSolid, e, COLLISION_GROUP_NONE, COLLISION_GROUP_WORLD )

	FixInvalidPhysicsObject( e )

	DoPropSpawnedEffect( e )

	// move player above prop
	local tr = util.TraceHull({
		start = mv:GetOrigin()+Vector(0,0,10),
		endpos = mv:GetOrigin(),
		maxs = ply:OBBMaxs(),
		mins = ply:OBBMins(),
		filter = ply
	})

	if tr.Entity == e then
		mv:SetOrigin(tr.HitPos)
	end

	undo.Create( "Prop" )
		undo.SetPlayer( ply )
		undo.AddEntity( e )
	undo.Finish( "Prop (" .. tostring( model ) .. ")" )

	ply:AddCleanup( "props", e )

end

function CCSpawn( ply, command, arguments )

	-- We don't support this command from dedicated server console
	if ( !IsValid( ply ) ) then return end

	if ( arguments[ 1 ] == nil ) then return end
	if ( arguments[ 1 ]:find( "%.[/\\]" ) ) then return end

	-- Clean up the path from attempted blacklist bypasses
	arguments[ 1 ] = arguments[ 1 ]:gsub( "\\\\+", "/" )
	arguments[ 1 ] = arguments[ 1 ]:gsub( "//+", "/" )
	arguments[ 1 ] = arguments[ 1 ]:gsub( "\\/+", "/" )
	arguments[ 1 ] = arguments[ 1 ]:gsub( "/\\+", "/" )

	if ( !gamemode.Call( "PlayerSpawnObject", ply, arguments[ 1 ], arguments[ 2 ] ) ) then return end
	if ( !util.IsValidModel( arguments[ 1 ] ) ) then return end

	local iSkin = tonumber( arguments[ 2 ] ) or 0
	local strBody = arguments[ 3 ] or nil

	if ( util.IsValidProp( arguments[ 1 ] ) ) then

		//GMODSpawnProp( ply, arguments[ 1 ], iSkin, strBody )

		if not ply.spawnQueue then ply.spawnQueue = {} end		

		table.insert(ply.spawnQueue, { arguments[ 1 ], iSkin, strBody })

		return

	end

	if ( util.IsValidRagdoll( arguments[ 1 ] ) ) then

		GMODSpawnRagdoll( ply, arguments[ 1 ], iSkin, strBody )
		return

	end

	-- Not a ragdoll or prop.. must be an 'effect' - spawn it as one
	GMODSpawnEffect( ply, arguments[ 1 ], iSkin, strBody )

end
concommand.Add( "gm_spawn", CCSpawn, nil, "Spawns props/ragdolls" )

hook.Add("SetupMove", "spawnprops", function(ply, mv, cmd)
	if not ply.spawnQueue then return end

	for k,v in pairs(ply.spawnQueue) do
		GMODSpawnProp(ply, v[1], v[2], v[3], mv)
	end

	ply.spawnQueue = {}
end)

