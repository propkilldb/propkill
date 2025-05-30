
CreateClientConVar("pk_grabfix", "1", true, true, "fixes prop grabbing at high velocity")
CreateClientConVar("pk_spawnfix", "1", true, true, "changes how props spawn for more reliable grabbing")
CreateClientConVar("pk_spawndist", "2048", true, true, "changes the maximum spawn distance of props, only updates on spawn", 0, 2048)
CreateClientConVar("pk_redundancy", "1", true, true, "the amount of redundant packets sent to the server in case of packet loss or delays", 0, 4)

redundnet = redundnet or {}

function redundnet.Send(name, data)
	local seq = (redundnet.sequence or 0) + 1
	redundnet.sequence = seq

	net.Start("redundnet", true) -- unreliable channel
		net.WriteUInt(seq, 16)
		net.WriteString(name)
		net.WriteTable(data or {})
	net.SendToServer()

	net.Start("redundnet", false) -- reliable channel
		net.WriteUInt(seq, 16)
		net.WriteString(name)
		net.WriteTable(data or {})
	net.SendToServer()

	local redundancy = LocalPlayer():GetInfoNum("pk_redundancy", 1)
	if redundancy > 0 then
		timer.Create(string.format("redundnet_%s_%d", name, seq), 0, redundancy, function()
			net.Start("redundnet", true) -- unreliable channel
				net.WriteUInt(seq, 16)
				net.WriteString(name)
				net.WriteTable(data or {})
			net.SendToServer()
		end)
	end
end

if CLIENT then -- override servers commands with client commands
	concommand.Add("gm_spawn", function(ply, cmd, args)
		redundnet.Send("spawn", args)
	end)

	local function UndoLast(ply, cmd, args)
		redundnet.Send("undo", args)
	end
	concommand.Add("undo", UndoLast, nil, "", { FCVAR_DONTRECORD })
	concommand.Add("gmod_undo", UndoLast, nil, "", { FCVAR_DONTRECORD })
end

if CLIENT then return end

util.AddNetworkString("redundnet")

function redundnet.Receive(name, callback)
	redundnet.callbacks = redundnet.callbacks or {}
	redundnet.callbacks[name] = callback
end

net.Receive("redundnet", function(len, ply)
	local seq = net.ReadUInt(16)
	local name = net.ReadString()
	local data = net.ReadTable()

	ply.redundnetseq = ply.redundnetseq or 0
	if ply.redundnetseq - seq > 4 then ply.redundnetseq = seq end

	if seq <= ply.redundnetseq then return end
	ply.redundnetseq = seq

	if not isfunction(redundnet.callbacks[name]) then return end
	redundnet.callbacks[name](ply, unpack(data))
end)

redundnet.Receive("undo", function(ply, ...)
	concommand.GetTable()["gmod_undo"](ply, ...)
end)

hook.Add("PlayerSpawn", "apply pk spawndist", function(ply)
	ply.pkspawndist = ply:GetInfoNum("pk_spawndist", 2048)
end)

local function isInfront(ply, pos)
	local diff = pos - (ply:GetShootPos() + ply:GetAimVector() * 40)
	return ply:GetAimVector():Dot(diff) / diff:Length() > 0
end

local function fixupProp2( ply, ent, hitpos, mins, maxs )
	local entPos = ent:GetPos()
	local endposD = ent:LocalToWorld( mins )
	local tr_down = util.TraceLine( {
		start = entPos,
		endpos = endposD,
		filter = { ent, ply }
	} )

	local endposU = ent:LocalToWorld( maxs )
	local tr_up = util.TraceLine( {
		start = entPos,
		endpos = endposU,
		filter = { ent, ply }
	} )

	-- Both traces hit meaning we are probably inside a wall on both sides, do nothing
	if ( tr_up.Hit && tr_down.Hit ) then return end

	if ( tr_down.Hit ) then ent:SetPos( entPos + ( tr_down.HitPos - endposD ) ) end
	if ( tr_up.Hit ) then ent:SetPos( entPos + ( tr_up.HitPos - endposU ) ) end
end

function spawnfix()
	function DoPlayerEntitySpawn( ply, entity_name, model, iSkin, strBody, mv )

		local vStart = ply:GetShootPos()
		local vForward = ply:GetAimVector()

		if mv then
			local origin = mv:GetOrigin()
			local eyeheight = ply:GetShootPos().z - ply:GetPos().z
			origin.z = origin.z + eyeheight
			vStart = origin + mv:GetVelocity() / (1 / engine.TickInterval())
			vForward = mv:GetAngles():Forward()
		end

		local trace = {}
		trace.start = vStart
		trace.endpos = vStart + ( vForward * (ply.pkspawndist or 2048) )
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
		
		local tryfix = false

		if ply:GetInfo("pk_spawnfix") == "1" then
			// move it 98% of the way there then slightly towards the player for better grab reliability if its not on the ground
			local flatGround = tr.HitNormal.z > 0.9
			vFlushPoint = tr.HitPos + (vFlushPoint * (flatGround and 1 or 0.98))
			vFlushPoint = vFlushPoint - (ply:GetAimVector() * (flatGround and 0 or 10))
			
			local absz = math.abs(tr.HitNormal.z)

			// resort to old spawn method if its on flat ground or very close to the player
			if absz != 1 and (absz > 0.9 or tr.Fraction > 0.03) then
				local mins, maxs = ent:GetRotatedAABB(ent:OBBMins(), ent:OBBMaxs())
				// BoundingRadius gets from origin to furthest point, so double it to get the maximum possible width of the prop (i hope)
				local propsize = ent:BoundingRadius() * 2
				// if tr didnt hit then the prop could have spawned in the roof so we trace it back a little
				local offset = propsize
				// offset the props origin to the bottom so it's less likely to get stuck in the ground on slopes
				local originfix = Vector(0,0,math.abs(mins.z)-propsize/99)

				// NOTE: this can still fuck up if the whole traceback is colliding, i.e. if you spawn on a slope looking over an edge.
				// it's only really an issue if ur using the locker prop, since its tiny legs get stuck under the map
				local hulltr = util.TraceHull({
					start = (tr.HitPos + originfix) - ply:EyeAngles():Forward() * offset,
					endpos = tr.HitPos + originfix,
					mins = mins,
					maxs = maxs,
					mask = MASK_SHOT_HULL,
					filter = table.Add({ent}, player.GetAll())
				})

				// bigger props can get traced back behind the player so just use old method for that
				if isInfront(ply, hulltr.HitPos) then
					vFlushPoint = hulltr.HitPos
				end

				if hulltr.AllSolid then
					tryfix = true
				end
			end

		else
			vFlushPoint = tr.HitPos + vFlushPoint
		end
		
		if ( entity_name != "prop_ragdoll" ) then

			-- Set new position
			ent:SetPos( vFlushPoint )
			if tryfix then
				fixupProp2( ply, ent, tr.HitPos, Vector( 0, 0, ent:OBBMins().z ), Vector( 0, 0, ent:OBBMaxs().z ) )
			end

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
		timer.Simple(0, function()
			local tr = util.TraceHull({
				start = ply:GetPos()+Vector(0,0,20),
				endpos = ply:GetPos(),
				maxs = ply:OBBMaxs(),
				mins = ply:OBBMins(),
				filter = ply
			})

			if tr.Entity == e and not tr.AllSolid then
				ply:SetPos(tr.HitPos)
			end
		end)

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
		local strBody = arguments[ 3 ] or ""

		if ( util.IsValidProp( arguments[ 1 ] ) ) then

			if ply:GetInfo("pk_grabfix") == "1" and string.lower(string.sub(game.GetMap(), 1, 9)) != "gm_infmap" then

				if not ply.spawnQueue then ply.spawnQueue = {} end		
		
				table.insert(ply.spawnQueue, { arguments[ 1 ], iSkin, strBody })
		
				return
				
			end

			GMODSpawnProp( ply, arguments[ 1 ], iSkin, strBody )
			
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

	redundnet.Receive("spawn", function(ply, ...)
		CCSpawn(ply, "gm_spawn", {...})
	end)
end
hook.Add("PostGamemodeLoaded", "spawnfix", spawnfix)
hook.Add("OnReloaded", "spawnfix", spawnfix)
spawnfix()

hook.Add("SetupMove", "spawnprops", function(ply, mv, cmd)
	if not ply.spawnQueue then return end

	local success, err
	for k,v in pairs(ply.spawnQueue) do
		success, err = pcall(GMODSpawnProp, ply, v[1], v[2], v[3], mv)
		if not success then
			ErrorNoHaltWithStack(err)
		end
	end

	ply.spawnQueue = {}
end)
