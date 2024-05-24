
CreateClientConVar("pk_autoundo", "1", true, true, "enable or disable autoundo")
CreateClientConVar("pk_autoundo_coaster", "1", true, true, "enable or disable autoundo on coaster props")
CreateClientConVar("pk_autoundo_defense", "1", true, true, "enable or disable autoundo on defense props")
CreateClientConVar("pk_autoundo_attack", "1", true, true, "enable or disable autoundo on attack props")
CreateClientConVar("pk_autoundo_surf", "1", true, true, "enable or disable autoundo on surf props")
CreateClientConVar("pk_autoundo_untouched", "1", true, true, "enable or disable autoundo on props you havent physgunned")

if CLIENT then return end

local coastertime = CreateConVar("pk_autoundo_time_coaster", 1, FCVAR_REPLICATED)
local defencetime = CreateConVar("pk_autoundo_time_defence", 10, FCVAR_REPLICATED)
local attacktime = CreateConVar("pk_autoundo_time_attack", 4, FCVAR_REPLICATED)
local untouchedtime = CreateConVar("pk_autoundo_time_untouched", 4, FCVAR_REPLICATED)


hook.Add("PlayerSpawnedProp", "autoremove", function(ply, model, ent)
	if ply:GetInfoNum("pk_autoundo", 1) == 0 then return end
	
	ent.shouldremove = false
	ent.surfprop = false
	ent.physgunned = false
 
	ent:AddCallback("PhysicsCollide", function(ent, data)
		if not data.HitObject:IsMotionEnabled() then return end
		
		if data.HitEntity == ply then
			ent.surfprop = true
		end

		if ent.shouldremove and ent:GetVelocity():Length() < 100 and ply:GetInfoNum("pk_autoundo_attack", 1) == 1 then
			ent:Remove()
		end
	end)
	
	-- if the prop isn't physgunned in 1 second then they probably missed and we should remove it quickly
	timer.Create("undo" .. ent:EntIndex(), 1, untouchedtime:GetInt(), function()
		if not IsValid(ent) then return end
		if ply:GetInfoNum("pk_autoundo_untouched", 1) == 0 then return end

		if not ent.physgunned then
			ent:Remove()
			return
		end

		local phys = ent:GetPhysicsObject()

		if phys:IsAsleep() and phys:IsMotionEnabled() then
			ent:Remove()
		end
	end)
end)

hook.Add("PhysgunPickup", "autoremove", function(ply, ent)
	if ply:GetInfoNum("pk_autoundo", 1) == 0 then return end

	ent.physgunned = true
end)
 
hook.Add("PhysgunDrop", "autoremove", function(ply, ent)
	if ply:GetInfoNum("pk_autoundo", 1) == 0 then return end
	
	ent.shouldremove = true
	local phys = ent:GetPhysicsObject()

	timer.Create("undo" .. ent:EntIndex(), attacktime:GetInt(), 1, function()
		if IsValid(ent) and ply:GetInfoNum("pk_autoundo_attack", 1) == 1 then
			ent:Remove()
		end
	end)
	
	-- if the players velocity is above 800 the prop is probably a coaster, if its below 800 it's probably defence
	if ply:GetVelocity():Length() > 800 and not phys:IsMotionEnabled() then
		ent.shouldremove = false
		
		timer.Create("undo" .. ent:EntIndex(), coastertime:GetInt(), 1, function()
			if IsValid(ent) and ply:GetInfoNum("pk_autoundo_coaster", 1) == 1  then
				ent:Remove()
			end
		end)
	elseif ply:GetVelocity():Length() < 800 and not phys:IsMotionEnabled() then
		ent.shouldremove = false
		
		timer.Create("undo" .. ent:EntIndex(), defencetime:GetInt(), 1, function()
			if IsValid(ent) and ply:GetInfoNum("pk_autoundo_defense", 1) == 1  then
				ent:Remove()
			end
		end)
	end
 
	if ent.surfprop and ply:GetInfoNum("pk_autoundo_surf", 1) == 1 then
		ent:Remove()
		return
	end
end)

hook.Add("PlayerCheckLimit", "autoremove", function(ply, name, cur, limit)
	if ply:GetInfoNum("pk_autoundo", 1) == 0 then return end

	-- this will probably break on anything other than propkill
	if cur == limit then
		for k,v in pairs(undo.GetTable()[ply:UniqueID()]) do
			if IsValid(v.Entities[1]) then
				v.Entities[1]:Remove()
				break
			end
		end
	end
	
	return true
end)
