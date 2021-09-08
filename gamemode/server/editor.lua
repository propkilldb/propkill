local editor = {}
editor.__index = editor

PK.editor = editor
// Class: Global

/*
	Function: PK.EditArena()
	*Server* Loads the editor for the arena

	Parameters:
		arenaid: string - The table index of the arena to edit
	
	Returns:
		editor: <Editor> - The editor instance
*/
function PK.EditArena(arenaid)
	local arena = (isstring(arenaid) and PK.arenas[arenaid] or arenaid)
	if not IsValid(arena) then
		print("PK.EditArena: arena not valid")
		return
	end

	arena.editing = true

	local editdata = {
		spawneditor = false,
		objeditor = false,
		arena = arena,
		positions = table.Copy(arena.positions)
	}
		
	return setmetatable(editdata, PK.editor)
end

/*
	Class: Editor
	Used for editing arena data and positions
*/
/*
	Function: Editor:CreatePosEnt()
	Creates a position entity to be used by gamemodes for spawn/flag/capture point positions
	Mostly used internally in <Editor:AddSpawn> and <Editor:AddObjective>

	Parameters:
		pos: Vector - Position of the entity
		ang: Angle - Angle of the entity
		color: Color - Color of the entity
		spawn: bool - Should this position be used as a player spawn
	
	Returns:
		ent: Entity - Entity that was created at the position
*/
function editor:CreatePosEnt(pos, ang, color, spawn)
	if spawn == true then
		local ent = ents.Create("ent_pos")
		ent:SetModel("models/editor/playerstart.mdl")
		ent:SetColor(color or Color(255,0,255))
		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:Spawn()

		return ent
	else
		local ent = ents.Create("ent_pos")
		ent:SetModel("models/props_c17/oildrum001.mdl")
		ent:SetColor(color or Color(255,0,255))
		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:Spawn()

		return ent
	end
end

/*
	Function: Editor:EditSpawns()
	Spawns all the spawn position entities to be moved/deleted
*/
function editor:EditSpawns()
	if self:IsEditingSpawns() then
		print("editor.EditSpawns: already editing spawns")
		return
	end

	self.spawneditor = true

	for gamemode, v in pairs(self.positions.spawns) do
		for team, v2 in pairs(v) do
			for k3, spawn in pairs(v2) do
				local ent = self:CreatePosEnt(spawn.pos, spawn.ang, self.arena.gamemode.teams[team].color, true)
				spawn.ent = ent
			end
		end
	end

end

/*
	Function: Editor:EditObjectives()
	Spawns all the objective position entities to be moved/deleted
*/
function editor:EditObjectives()
	if self:IsEditingObjectives() then
		print("editor.EditObjectives: already editing objectives")
		return
	end

	self.objeditor = true

	for gamemode, v in pairs(self.positions.objectives) do
		for k2, obj in pairs(v) do
			local ent = self:CreatePosEnt(obj.pos, obj.ang, Color(255,255,255), false)
			obj.ent = ent
		end
	end

end

/*
	Function: Editor:SaveSpawns()
	Saves all the spawn positions to the arena
*/
function editor:SaveSpawns()
	if not self:IsEditingSpawns() then
		print("editor.SaveSpawns: not editing spawns")
		return
	end

	local newspawns = {}
	
	for gamemode, v in pairs(self.positions.spawns) do
		if newspawns[gamemode] == nil then newspawns[gamemode] = {} end
		for team, v2 in pairs(v) do
			if newspawns[gamemode][team] == nil then newspawns[gamemode][team] = {} end
			for k3, spawn in pairs(v2) do
				if IsValid(spawn.ent) then
					table.insert(newspawns[gamemode][team], {pos = spawn.ent:GetPos(), ang = spawn.ent:GetAngles()})
					spawn.ent:Remove()
				end
			end
		end
	end

	self.arena.positions.spawns = newspawns
	self.spawneditor = false
end

/*
	Function: Editor:SaveObjectives()
	Saves all the objective positions to the arena
*/
function editor:SaveObjectives()
	if not self:IsEditingObjectives() then
		print("editor.SaveObjectives: not editing objectives")
		return
	end

	local newobjectives = {}

	for gamemode, v in pairs(self.positions.objectives) do
		if newobjectives[gamemode] == nil then newobjectives[gamemode] = {} end
		for k2, obj in pairs(v) do
			if IsValid(obj.ent) then
				table.insert(newobjectives[gamemode], {pos = obj.ent:GetPos(), ang = obj.ent.GetAngles(), data = obj.data})
				obj.ent:Remove()
			end
		end
	end


	self.arena.positions.objectives = newobjectives
	self.objeditor = false
end

/*
	Function: Editor:Finish()
	Removes all the editor from the arena ans saves any data that was modified to file
*/
function editor:Finish()
	if self.arena.editing == false then
		print("editor.Finish: not editing")
		return
	end

	for gamemode, v in pairs(self.positions.spawns) do
		for team, v2 in pairs(v) do
			for k3, spawn in pairs(v2) do
				if IsValid(spawn.ent) then spawn.ent:Remove() end
			end
		end
	end

	for gamemode, v in pairs(self.positions.objectives) do
		for k2, obj in pairs(v) do
			if IsValid(obj.ent) then obj.ent:Remove() end
		end
	end

	PK.SaveArena(self.arena)

	self.arena.editor = nil
	self.arena.editing = false
end

/*
	Function: Editor:AddSpawn()
	Adds a spawn point to the arena

	Parameters:
		pos: Vector - Position of the spawn point
		ang: Angle - Angle of the spawn point
		team: string - Name of the team that can spawn here
*/
function editor:AddSpawn(pos, ang, team)
	if not self:IsEditingSpawns() then
		print("editor.AddSpawn: not editing")
		return
	end

	local ent = self:CreatePosEnt(pos, ang, self.arena.gamemode.teams[team].color, true)

	if not IsValid(ent) then
		print("editor.AddSpawn: entity not valid")
		return
	end

	local gmabbr = self.arena.gamemode.abbr

	if self.positions.spawns[gmabbr] == nil then self.positions.spawns[gmabbr] = {} end
	if self.positions.spawns[gmabbr][team] == nil then self.positions.spawns[gmabbr][team] = {} end

	table.insert(self.positions.spawns[gmabbr][team], {pos = pos, ang = ang, ent = ent})
end

/*
	Function: Editor:RemoveSpawn()
	Removes a spawn point to the arena

	*incomplete* - You can remove the spawn point using context menu for now

	Parameters:
		id - ??
*/
function editor:RemoveSpawn(id)
	if not self:IsEditingSpawns() then return end

end

/*
	Function: Editor:AddObjective()
	Adds a spawn point to the arena

	Parameters:
		pos: Vector - Position of the spawn point
		ang: Angle - Angle of the spawn point
		data: table - Data that may be needed in the gamemode such as radius, team or color
*/
function editor:AddObjective(pos, ang, data)
	if not self:IsEditingObjectives() then return end

	local ent = self:CreatePosEnt(pos, ang, Color(255,255,255), false)

	if not IsValid(ent) then
		print("editor.AddObjective: entity not valid")
		return
	end

	local gmabbr = self.arena.gamemode.abbr

	if self.positions.objectives[gmabbr] == nil then self.positions.objectives[gmabbr] = {} end

	table.insert(self.positions.objectives[gmabbr], {pos = pos, ang = ang, data = data, ent = ent})
end

/*
	Function: Editor:RemoveObjective()
	Removes a spawn point to the arena

	*incomplete* - You can remove the spawn point using context menu for now

	Parameters:
		id - ??
*/
function editor:RemoveObjective(id)
	if not self:IsEditingObjectives() then return end

end

/*
	Function: Editor:IsEditingSpawns()
	Are we currently editing spawn points?
	
	Returns:
		editing: bool - true if we are editing
*/
function editor:IsEditingSpawns()
	return self.spawneditor or false
end

/*
	Function: Editor:IsEditingObjectives()
	Are we currently editing objective positions?
	
	Returns:
		editing: bool - true if we are editing
*/
function editor:IsEditingObjectives()
	return self.objeditor or false
end

/*
	Function: Editor:IsValid()
	Are we currently editing spawn points?
	
	Returns:
		editing: bool - true if the editor is valid
*/
function editor:IsValid()
	return true
end

concommand.Add("pk_editarena", function(ply, cmd, args)
	if not ply:IsAdmin() then return end

	if not IsValid(ply.arena) then
		ply:ChatPrint("you aren't in an arena")
		return
	end

	if ply.arena.editing == true then
		ply:ChatPrint("arena is alread being edited")
		return
	end

	ply.arena.editor = PK.EditArena(ply.arena)
	ply:ChatPrint("editing arena " .. ply.arena.name)
end)

concommand.Add("pk_editor_editspawns", function(ply, cmd, args)
	if not ply:IsAdmin() then return end
	if not IsValid(ply.arena) then print("pk_editor_editspawns: invalid arena") end
	if not IsValid(ply.arena.editor) then print("pk_editor_editspawns: invalid arena editor") return end

	ply.arena.editor:EditSpawns()
	ply:ChatPrint("editing spawns in " .. ply.arena.name)
end)

concommand.Add("pk_editor_editobjectives", function(ply, cmd, args)
	if not ply:IsAdmin() then return end
	if not IsValid(ply.arena) then print("pk_editor_editobjectives: invalid arena") end
	if not IsValid(ply.arena.editor) then print("pk_editor_editobjectives: invalid arena editor") return end

	ply.arena.editor:EditObjectives()
	ply:ChatPrint("editing objective in " .. ply.arena.name)
end)

concommand.Add("pk_editor_addobjective", function(ply, cmd, args)
	if not ply:IsAdmin() then return end
	if not IsValid(ply.arena) then print("pk_editor_addobjective: invalid arena") end
	if not IsValid(ply.arena.editor) then print("pk_editor_addobjective: invalid arena editor") return end

	ply.arena.editor:AddObjective(ply:GetPos(), ply:GetAngles(), {hello = true})
	ply:ChatPrint("added objective in " .. ply.arena.name)
end)

concommand.Add("pk_editor_addspawn", function(ply, cmd, args)
	if not ply:IsAdmin() then return end
	if not IsValid(ply.arena) then print("pk_editor_addspawn: invalid arena") end
	if not IsValid(ply.arena.editor) then print("pk_editor_addspawn: invalid arena editor") return end

	local team = args[1] or ply.team.name

	ply.arena.editor:AddSpawn(ply:GetPos(), ply:GetAngles(), team)
	ply:ChatPrint("added spawn in " .. ply.arena.name .. " for team " .. team)
end)

concommand.Add("pk_editor_savespawns", function(ply, cmd, args)
	if not ply:IsAdmin() then return end
	if not IsValid(ply.arena) then print("pk_editor_savespawns: invalid arena") end
	if not IsValid(ply.arena.editor) then print("pk_editor_savespawns: invalid arena editor") return end

	ply.arena.editor:SaveSpawns()
	ply:ChatPrint("saved spawns in " .. ply.arena.name)
end)

concommand.Add("pk_editor_saveobjectives", function(ply, cmd, args)
	if not ply:IsAdmin() then return end
	if not IsValid(ply.arena) then print("pk_editor_saveobjectives: invalid arena") end
	if not IsValid(ply.arena.editor) then print("pk_editor_saveobjectives: invalid arena editor") return end

	ply.arena.editor:SaveObjectives()
	ply:ChatPrint("saved objective in " .. ply.arena.name)
end)

concommand.Add("pk_editor_finish", function(ply, cmd, args)
	if not ply:IsAdmin() then return end
	if not IsValid(ply.arena) then print("pk_editor_finish: invalid arena") end
	if not IsValid(ply.arena.editor) then print("pk_editor_finish: invalid arena editor") return end

	ply.arena.editor:Finish()
	ply:ChatPrint("finished editing " .. ply.arena.name)
end)