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

net.Receive("KilledByProp", function()
	local ply       = net.ReadEntity()
	local inflictor = net.ReadString()
	local attacker  = net.ReadEntity()

	if not attacker:IsPlayer() then
		GAMEMODE:AddDeathNotice(nil, 0, "suicide", ply:Name(), ply:Team())
		return
	end

	GAMEMODE:AddDeathNotice(attacker:Name(), attacker:Team(), inflictor, ply:Name(), ply:Team())
end)

/*
--TimedSin replacement which works how it should've worked to begin with
local function EternalSin( Freak, Trough, Peak )
	local Diff = ( Peak -Trough )
	local ActualTrough = ( Trough +Peak ) /2
	local ActualPeak = ActualTrough +Diff

	return TimedSin( Freak, ActualTrough, ActualPeak, 0 )
end
*/

hook.Add("PreDrawSkyBox", "removeSkybox", function()
	//local col = HSVToColor(EternalSin(0.1, 0, 360), 1, 1)
	//render.Clear(col.r, col.g, col.b, 255)
	render.Clear(50, 50, 50, 255)
	return true
end)

//disable screen wobble on landing
hook.Add("CalcView", "CalcVyoo",function(ply, pos, ang, fov)
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
