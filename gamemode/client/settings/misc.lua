-- Use Lerp Command

/*function PK.Client.UseLerpCommand()
	if PK.Client.Config:Get("UseLerpCommand").Value then
		RunConsoleCommand("cl_updaterate", "1000")
		RunConsoleCommand("cl_interp", "0")
		RunConsoleCommand("rate", "1048576")
	else
		RunConsoleCommand("cl_updaterate", "30")
		RunConsoleCommand("cl_interp", "0.1")
		RunConsoleCommand("rate", "30000")
	end
end

function PK.Client.WeaponSelectEnabled()
	if istable(BlockedHUDElements) then
		BlockedHUDElements["CHudWeaponSelection"] = !PK.Client.Config:Get("WeaponSelectEnabled").Value
	end
end*/
