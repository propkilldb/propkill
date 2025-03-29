
hook.Add("ShouldCollide", "onesurf collision check", function(ent1, ent2)
	if not PK.GetNWVar("onesurfmode", false) then return end

	local ply = ent1:IsPlayer() and ent1 or ent2
	local ent = ent2:IsPlayer() and ent1 or ent2

	if not ply:IsPlayer() then return end
	if not ent:GetClass() == "prop_physics" then return end

	if ent:GetNW2Entity("Owner", NULL) != ply then return end

	if ply:GetNW2Int("PKSurfs", 0) < 1 and ply:GetNW2Entity("PKGrabEnt", NULL) == ent then
		return false
	end
end)

if CLIENT then return end

local function ruleschanged(ent)
	timer.Simple(0, function()
		if not IsValid(ent) then return end
		ent:CollisionRulesChanged()
	end)
end

hook.Add("PlayerDeath", "surf counter", function(ply, inflictor, attacker)
	if not PK.GetNWVar("onesurfmode", false) then return end

	attacker = inflictor.Owner
	if not IsValid(attacker) or not attacker:IsPlayer() then return end

	attacker:SetNW2Int("PKSurfs", attacker:GetNW2Int("PKSurfs", 0) + math.max(ply:GetNW2Int("PKSurfs", 0), 1))
end)

hook.Add("PlayerSpawn", "default surf count", function(ply)
	ply:SetNW2Int("PKSurfs", 1)
end)

hook.Add("OnEntityCreated", "add collide callback", function(ent)
	if not PK.GetNWVar("onesurfmode", false) then return end
	
	if ent:GetClass() != "prop_physics" then return end
	ent.PKSpawnTick = engine.TickCount()

	ent:AddCallback("PhysicsCollide", function(ent1, data)
		local ent2 = data.HitEntity
		local ply = ent1:IsPlayer() and ent1 or ent2
		local ent = ent2:IsPlayer() and ent1 or ent2

		if not ply:IsPlayer() then return end
		if not ent:GetClass() == "prop_physics" then return end

		if ply:GetNW2Entity("PKGrabEnt", NULL) != ent then return end
		if ent.Owner != ply then return end

		ent.PKSurfProp = true
	end)
end)

hook.Add("OnPhysgunPickup", "track grab ent", function(ply, ent)
	ply:SetNW2Entity("PKGrabEnt", ent)
end)

hook.Add("PhysgunDrop", "track grab ent", function(ply, ent)
	ply:SetNW2Entity("PKGrabEnt", NULL)

	if not ent.PKSurfProp then return end
	ent.PKSurfProp = false

	ply:SetNW2Int("PKSurfs", ply:GetNW2Int("PKSurfs", 0) - 1)

	if ply:GetNW2Int("PKSurfs", 0) < 0 then
		ruleschanged(ent)
		ruleschanged(ply)
		ply:SetNW2Int("PKSurfs", 0)
	end
end)

concommand.Add("onesurf", function(ply, cmd, args, str)
	if not ply:IsAdmin() then return end

	PK.SetNWVar("onesurfmode", not PK.GetNWVar("onesurfmode", false))

	ChatMsg({
		Color(0,120,255), "OneSurf",
		Color(255,255,255), " mode ",
		Color(255,255,255), (PK.GetNWVar("onesurfmode", false) and "enabled" or "disabled"),
	})

	for k,v in next, player.GetAll() do 
		v:SetNW2Int("PKSurfs", 1)
	end
end)
