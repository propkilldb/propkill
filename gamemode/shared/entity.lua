function GM:PhysgunPickup(ply, ent)
	ent.Owner = ent:GetNWEntity("Owner", NULL)
	if ent.Owner == nil then
		ent.Owner = ply
	end
	if ent:IsPlayer() or ent.Owner ~= ply then return false end
	return true
end
