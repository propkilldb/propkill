local spectateFOV = CreateClientConVar("spectate_fov", 100, true, false, "Sets your FOV while spectating another player", 10, 170)

// lower their interpolation to 20ms, 100ms is too high for propkill
local interp = GetConVar("cl_interp")
if interp:GetFloat() > 0.07 then
	RunConsoleCommand("cl_interp_ratio", 1)
	RunConsoleCommand("cl_interp", 0.020)
end

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

/*hook.Add("PostDraw2DSkyBox", "removeSkybox", function()
	render.Clear(50, 50, 50, 255)
	return true
end)

hook.Add("PreDrawSkyBox", "removeSkybox", function()
	render.Clear(50, 50, 50, 255)
	return true
end)*/

hook.Add("ChatText", "disable joinleave messages", function(pid, name, text, type)
	if type == "joinleave" then
		return true
	end
end)

hook.Add("Think", "pk_spectatefov", function()
	if not IsValid(LocalPlayer()) then return end

	local obstarget = LocalPlayer():GetObserverTarget()
	if not IsValid(obstarget) then return end

	if obstarget:GetFOV() != spectateFOV:GetInt() then
		obstarget:SetFOV(spectateFOV:GetInt())
	end
end)
