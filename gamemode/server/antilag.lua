
-- this was just ripped out of my sandbox server, to prevent people crashing the server with colliding props. imperfect but works well enough for now.

antilag = antilag or {}

antilag.vertexcache = antilag.vertexcache or {}
antilag.groups = antilag.groups or {}
antilag.tickrate = 0
antilag.config = {
	timestep = 1,
	whitelist = {
		//["sent_ball"] = true,
		//["hahaball"] = true,
		["infmap_clone"] = true,
		["infmap_terrain_collider"] = true,
		["infmap_terrain_render"] = true,
		["player"] = true,
		["physgun_beam"] = true,
		["env_explosion"] = true,
		["entityflame"] = true,
		["prop_dynamic"] = true,
		["keyframe_rope"] = true,
		["player_pickup"] = true,
		["manipulate_flex"] = true,
		["env_projectedtexture"] = true,
		["predicted_viewmodel"] = true,
		["hl2mp_ragdoll"] = true,
		["gmod_hands"] = true,
		["env_spritetrail"] = true,
		["point_tesla"] = true,
		["phys_keepupright"] = true,
		["light_dynamic"] = true,
		["func_reflective_glass"] = true,
		["phys_spring"] = true,
		["gmod_winch_controller"] = true,
		["phys_torque"] = true,
		["env_soundscape"] = true,
		["npc_heli_avoidsphere"] = true,
		["manipulate_bone"] = true,
		["soundent"] = true,
		["player_manager"] = true,
		["gmod_gamerules"] = true,
		["bodyque"] = true,
		["network"] = true,
		["scene_manager"] = true,
		["point_spotlight"] = true,
		["func_useableladder"] = true,
		["light"] = true,
		["lua_run"] = true,
		["info_player_start"] = true,
		["water_lod_control"] = true,
		["info_ladder_dismount"] = true,
		["func_illusionary"] = true,
		["shadow_control"] = true,
		["env_skypaint"] = true,
		["env_sun"] = true,
		["env_fog_controller"] = true,
		["env_tonemap_controller"] = true,
		["logic_auto"] = true,
		["spotlight_end"] = true,
		["beam"] = true,
		["instanced_scripted_scene"] = true,
		["env_sprite"] = true,
		["env_laserdot"] = true,
		["widget_axis_arrow"] = true,
		["widget_bonemanip_move"] = true,
		["widget_bones"] = true,
		["widget_bone"] = true,
		["floorturret_tipcontroller"] = true,
		["env_shake"] = true,
		["env_ar2explosion"] = true,
		["ar2explosion"] = true,
		["env_smoketrail"] = true,
		["env_sporeexplosion"] = true,
		["env_smokestack"] = true,
		["spark_shower"] = true,
		["env_fire_trail"] = true,
		["env_rockettrail"] = true,
		["point_antlion_repellant"] = true,
		["info_particle_system"] = true,
		["info_null"] = true,
		["spraycan"] = true,
		["env_entity_dissolver"] = true,
		["trigger_soundscape"] = true,
		["trigger_multiple"] = true,
		["raggib"] = true,
		["env_physexplosion"] = true,
		["trigger_teleport"] = true,
		["info_target"] = true,
		["info_teleport_destination"] = true,
		["func_areaportalwindow"] = true,
		["trigger_look"] = true,
		["move_rope"] = true,
		["path_corner"] = true,
		["func_smokevolume"] = true,
		["func_rotating"] = true,
		["env_spark"] = true,
		["game_ui"] = true,
		["env_texturetoggle"] = true,
		["point_clientcommand"] = true,
		["ambient_generic"] = true,
		["env_soundscape_triggerable"] = true,
		["entity_blocker"] = true,
		["trigger_once"] = true,
		["trigger_weapon_strip"] = true,
		["trigger_push"] = true,
		["trigger_physics_trap"] = true,
		["func_precipitation"] = true,
		["env_fire"] = true,
		["_firesmoke"] = true,
		["trigger_hurt"] = true,
		["trigger_brush"] = true,
		["info_player_deathmatch"] = true,
		["env_laser"] = true,
		["widget_axis_disc"] = true,
		["widget_bonemanip_rotate"] = true,
		["widget_bonemanip_scale"] = true,
	}
}

antilag.group = {}
antilag.group.__index = antilag.group

function antilag.CreateGroup(...)
	local group = setmetatable({}, antilag.group)

	group:SetupGroup()
	group:AddEntities(...)

	return group
end

function antilag.ValidEntity(ent, checkPhys)
	if not IsValid(ent) then return false, "notvalid" end
	if ent.alvalid then return true end
	if antilag.config.whitelist[ent:GetClass()] then return false, "whitelisted" end
	if checkPhys == nil then checkPhys = true end
	if not IsValid(ent:GetPhysicsObject()) and checkPhys then return false, "invalid physobj" end
	//if ent:IsWorld() then return false, "isworld" end
	if ent:IsNPC() then return false, "isnpc" end
	if ent:IsPlayer() then return false, "isplayer" end

	ent.alvalid = checkPhys

	return true
end

function antilag.GetOrCreateGroup(tbl)
	for k,v in next, tbl do
		if v.algroup then
			v.algroup:AddEntities(unpack(tbl))
			return v.algroup
		end
	end
	
	return antilag.CreateGroup(unpack(tbl))
end

function antilag.FreezeEntity(ent)
	local phys

	for i=0, ent:GetPhysicsObjectCount() - 1 do
		phys = ent:GetPhysicsObjectNum(i)

		phys:EnableMotion(false)
	end
end

function antilag.IsLagging()
	return physenv.GetLastSimulationTime() > engine.TickInterval()
end

function antilag.group:SetupGroup()
	self.id = bit.tohex(math.random(0, 2^32-1))
	self.count = 0
	self.ents = {}
	self.complexity = 0
	self.colliding = 0
	self.penetrating = 0
	self.owner = NULL

	timer.Create("antilag_groupcheck_" .. self.id, antilag.config.timestep, 0, function() self:UpdateCounts() end)

	antilag.groups[self.id] = self
end

function antilag.FindCloseEnts(ent, range)
	range = range or 0.80
	return ents.FindInBox(ent:LocalToWorld(ent:OBBMins() * range), ent:LocalToWorld(ent:OBBMaxs() * range))
end

function antilag.group:Merge(group)
	self:AddCount(group.count)
	self:AddComplexity(group.complexity)
	self:AddColliding(group.colliding)
	self:AddPenetrating(group.penetrating)

	for k,v in next, group.ents do
		if not IsValid(v) then continue end

		v.algroup = self
		self.ents[k] = v
	end

	group:Remove()
end

function antilag.group:AddEntity(ent)
	if not antilag.ValidEntity(ent) then return false end
	if ent.algroup == self then return true end

	if ent.algroup then
		self:Merge(ent.algroup)
		return true
	end
	
	self:AddCount()
	self:AddComplexity(ent:GetVertexCount())

	self.ents[ent:EntIndex()] = ent
	ent.algroup = self
	ent.alcollide = RealTime()

	if self:IsFrozen() then
		antilag.FreezeEntity(ent)
	end

	ent:CallOnRemove("antilag_remove", function(ent)
		if not IsValid(ent) then return end
		if not IsValid(ent.algroup) then return end

		ent.algroup:RemoveEntity(ent)
	end)

	return true
end

function antilag.group:AddEntities(...)
	local tbl = {...}
	for k,v in next, tbl do
		self:AddEntity(v)
	end

	local k, v = next(tbl)
	self:SetOwner(v and v.Owner or NULL)
end

function antilag.group:RemoveEntity(ent)
	if not IsValid(ent) then return end
	local index = ent:EntIndex()

	self:AddCount(-1)
	self:AddComplexity(-ent:GetVertexCount())

	self.ents[index] = nil
	ent.algroup = nil

	if self:Count() == 0 then
		self:Remove()
	end
end

function antilag.group:RemoveEntityID(index)
	self:AddCount(-1)
	self.ents[index] = nil

	if self:Count() == 0 then
		self:Remove()
	end
end

function antilag.group:FreezeAll()
	for k,v in next, self.ents do
		antilag.FreezeEntity(v)
	end

	self.lastFrozen = RealTime()
end

function antilag.group:RemoveAll()
	for k,v in next, self.ents do
		v:Remove()
	end

	self:Remove()
end

function antilag.group:UpdateCounts()
	self.colliding = 0
	self.penetrating = 0

	local lastcollide

	for k,v in next, self.ents do
		if not IsValid(v) or not IsValid(v:GetPhysicsObject()) then
			self:RemoveEntityID(k)
			continue
		end

		lastcollide = RealTime() - v.alcollide

		if lastcollide > antilag.config.timestep * 4 then
			self:RemoveEntity(v)
			continue
		end

		self:AddColliding(1 and 1 or 0)
		self:AddPenetrating(v:GetPhysicsObject():IsPenetrating() and 1 or 0)

		v.alpenetrating = false
	end
end

function antilag.group:CheckLag()
	if not antilag.IsLagging() then return end
	local complexityScore = self:Complexity() / (self:Count() * 0.05)
	//500
	if self:Count() > 1 and complexityScore > 400 and self:Penetrating() > 1 then
		self:Debug("high complexity low count", "score:", complexityScore)
		self:FreezeAll()
		return
	end
	//8 8
	if self:Count() > 6 and complexityScore > 100 and self:Penetrating() > 6 then
		self:Debug("med complexity med count", "score:", complexityScore)
		self:FreezeAll()
		return
	end
	// 30
	if complexityScore > 30 and self:Penetrating() > 15 then
		self:Debug("low complexity high penetrating", "score:", complexityScore)
		self:FreezeAll()
		return
	end
	
	if complexityScore > 30 and self:Penetrating() > 10 and self:Count() > 100 then
		self:Debug("low complexity med penetrating high count", "score:", complexityScore)
		self:FreezeAll()
		return
	end

	if self:Colliding() > 25 then
		self:Debug("high collding", "score:", complexityScore)
		self:FreezeAll()
		return
	end

end

function antilag.group:Remove()
	timer.Remove("antilag_groupcheck_" .. self.id)
	antilag.groups[self.id] = nil
end

function antilag.group:AddCount(num)
	self.count = self.count + (num or 1)
end

function antilag.group:AddComplexity(num)
	self.complexity = self.complexity + (num or 1)
end

function antilag.group:AddColliding(num)
	self.colliding = self.colliding + (num or 1)
end

function antilag.group:AddPenetrating(num)
	self.penetrating = self.penetrating + (num or 1)
end

function antilag.group:SetOwner(ply)
	self.owner = ply or NULL
end

function antilag.group:IsFrozen()
	return RealTime() - (self.lastFrozen or 0) < antilag.config.timestep
end

function antilag.group:Count()
	return self.count
end

function antilag.group:Complexity()
	return self.complexity
end

function antilag.group:Colliding()
	return self.colliding
end

function antilag.group:Penetrating()
	return self.penetrating
end

function antilag.group:Owner()
	return self.owner or NULL
end

function antilag.group:Debug(...)
	print(self.id, "compl:", self:Complexity(), "cunt:", self:Count(), "penet:", self:Penetrating(), "coll:", self:Colliding(), "tick:", math.Round(1/engine.AbsoluteFrameTime(), 2), "simtime:", math.Round(physenv.GetLastSimulationTime() * 1000, 2), "owner:", self:Owner(), ...)
end

function antilag.group:IsValid()
	return true
end

local entmeta = FindMetaTable("Entity")

function entmeta:GetVertexCount()
	if not IsValid(self) then return 0 end

	if self.vertexCount then
		return self.vertexCount
	end

	local model = self:GetModel()
	if model == nil then return 0 end

	if antilag.vertexcache[model] then
		self.vertexCount = antilag.vertexcache[model]
		return self.vertexCount
	end

	if self:GetPhysicsObjectCount() == 0 and self.CreationTick == engine.TickCount() then
		return 1
	end

	local vertexCount = 0
	local phys

	for i=0, self:GetPhysicsObjectCount() - 1 do
		phys = self:GetPhysicsObjectNum(i)
		vertexCount = vertexCount + #(phys:GetMeshConvexes() or {})
	end

	antilag.vertexcache[model] = vertexCount
	self.vertexCount = vertexCount

	return vertexCount
end

function entmeta:AddAntilagCallback()
	-- check if it already has callback because it might be added from Spawn and OnEntityCreated
	if self.alHasCallback then return end

	self:AddCallback("PhysicsCollide", function(entity1, data)
		if not antilag.ValidEntity(data.HitEntity) then return end

		local entity2 = data.HitEntity
		local group = entity1.algroup or entity2.algroup or antilag.CreateGroup()

		group:AddEntities(entity1, entity2)

		entity1.alcollide = RealTime()
		entity2.alcollide = RealTime()

		if not entity1.alpenetrating and entity1:GetPhysicsObject():IsPenetrating() then
			entity1.alpenetrating = true
			group:AddPenetrating()
		end

		if not entity2.alpenetrating and entity2:GetPhysicsObject():IsPenetrating() then
			entity2.alpenetrating = true
			group:AddPenetrating()
		end

		group:CheckLag()
	end)

	self.alHasCallback = true
end

antilag._Spawn = antilag._Spawn or entmeta.Spawn

function entmeta:Spawn()
	hook.Run("antilag.PreEntitySpawned", self)
	antilag._Spawn(self)
	hook.Run("antilag.PostEntitySpawned", self)
end

hook.Add("antilag.PostEntitySpawned", "antilag add collision callback", function(ent)
	if not antilag.ValidEntity(ent) then return end

	ent:AddAntilagCallback()
	local closeents = antilag.FindCloseEnts(ent)
	local group = #closeents > 4 and antilag.GetOrCreateGroup(closeents) or nil
	
	if group then
		group:UpdateCounts()

		//if #closeents > 40 then
		if #closeents > 40 then
			group:FreezeAll()
			group:Debug("OnEntityCreated closeents > 40")
		end
	end
end)

hook.Add("OnEntityCreated", "antilag add collision callback", function(ent)
	timer.Simple(0, function()
		if not antilag.ValidEntity(ent) then return end

		ent:AddAntilagCallback()
	end)
end)

hook.Add("OnPhysgunPickup", "antilag group close ents on pickup", function(ply, ent)
	local closeents = antilag.FindCloseEnts(ent)

	if #closeents > 4 then
		local group = antilag.GetOrCreateGroup(closeents)
		group:AddEntities(unpack(closeents))
		group:UpdateCounts()
	end
end)

hook.Add("OnEntityCreated", "antilag entity creation tick", function(ent)
	ent.CreationTick = engine.TickCount()
end)

local function spamWarn(ply)
	if (ply.spamLastMessage or 0) + 1 < CurTime() then
		ply.spamLastMessage = CurTime()

		ply:ChatPrint(Color(0,255,0), "[antispam] ", Color(255,255,255), "chill")
		print("[antispam]", ply, "tried to spam")
	end
end

hook.Add("PlayerSpawnProp", "propspam warning", function(ply, prop)
	ply.spamSpawnCount = (ply.spamSpawnCount or 0) + 1

	if CurTime() - (ply.lastSpam or 0) < 2 then
		return false
	end

	if ply.spamSpawnCount > 3 and ply.spamLastTick == engine.TickCount() then
		spamWarn(ply)
		ply.lastSpam = CurTime()
		return false
	end

	if ply.spamLastTick != engine.TickCount() then
		ply.spamLastTick = engine.TickCount()
		ply.spamSpawnCount = 0
	end
end)
