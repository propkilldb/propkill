local spectateFOV = CreateClientConVar("spectate_fov", 100, true, false, "Sets your FOV while spectating another player", 10, 170)

net.Receive("pk_chatmsg", function(len) 
	chat.AddText(unpack(net.ReadTable()))
end)

net.Receive("pk_notify", function()
	local msg = net.ReadString()
	notification.AddLegacy(msg, NOTIFY_GENERIC, 3)
	surface.PlaySound("buttons/button2.wav")
end)

net.Receive("pk_gamenotify", function()
	hudmsg = net.ReadString()
	local time = net.ReadInt(16)
	timer.Create("hudmsg", time, 1, function() end)
end)

hook.Add("OnPlayerChat", "chattick", function()
	chat.PlaySound()
end)

hook.Add("PostDraw2DSkyBox", "removeSkybox", function()
	render.Clear(50, 50, 50, 255)
	return true
end)

hook.Add("PreDrawSkyBox", "removeSkybox", function()
	render.Clear(50, 50, 50, 255)
	return true
end)

hook.Add("ChatText", "disable joinleave messages", function(pid, name, text, type)
	if type == "joinleave" then
		return true
	end
end)

//disable screen wobble on landing
hook.Add("CalcView", "CalcVyoo", function(ply, pos, ang, fov)
	// if there is more than 1 calcview hook, we should just remove ourself, so we dont override whatever they're doing
	local thishook = hook.GetTable()["CalcView"]["CalcVyoo"]
	if next(hook.GetTable()["CalcView"], "CalcVyoo") != thishook then
		hook.Remove("CalcView", "CalcVyoo")
	end

	local target = LocalPlayer():GetObserverTarget()
	local targetFOV = spectateFOV:GetInt()
	
	if IsValid(target) and target:GetFOV() != targetFOV then
		target:SetFOV(targetFOV)
	end

	if GetViewEntity() != LocalPlayer() or LocalPlayer():InVehicle() then return end

	local LEA = LocalPlayer():EyeAngles()
	local view = { origin = pos, angles = LEA }

	return view
end)
