
PK.events = PK.events or {}

local eventmeta = {}
eventmeta.__index = eventmeta

function newEvent(id, name, options)
	if not id then return end
	//if PK.events[id] then return PK.events[id] end

	local newevent = {}
	setmetatable(newevent, eventmeta)

	newevent.id = id
	newevent.name = name
	newevent.options = { -- defaults
		minplayers = options.minplayers or 2,
		startfreezetime = options.startfreezetime or 3,
		endfreezetime = options.endfreezetime or 2,
		joinable = options.joinable != false,
		freezeplayers = options.freezeplayers != false,
		-- todo: option to make it not manually startable, e.g., 1v1s
	}
	newevent.hooks = {}
	newevent.players = {}

	PK.events[id] = newevent

	return newevent
end

function eventmeta:Hook(eventName, hookName, func)
	if not eventName or not hookName or not func then return end

	local hookData = {
		eventName = eventName,
		hookName = hookName,
		func = func,
	}

	self.hooks[eventName .. hookName] = hookData
end

function eventmeta:OnSetup(func)
	self.setupFunc = func
end

function eventmeta:RunSetup(...)
	if self.setupFunc then
		self.setupFunc(...)
	end
end

function eventmeta:OnGameStart(func)
	self.gameStartFunc = func
end

function eventmeta:RunGameStart(...)
	if self.gameStartFunc then
		self.gameStartFunc(...)
	end
end

function eventmeta:OnGameEnd(func)
	self.gameEndFunc = func
end

function eventmeta:RunGameEnd(...)
	if self.gameEndFunc then
		self.gameEndFunc(...)
	end
end

function eventmeta:OnCleanup(func)
	self.cleanupFunc = func
end

function eventmeta:RunCleanup(...)
	if self.cleanupFunc then
		self.cleanupFunc(...)
	end
end

function eventmeta:Start(...)
	if PK.currentEvent then return end

	-- setup player table first, and then let setupFunc modify it
	self.players = {}

	for _, ply in next, player.GetAll() do
		if ply:IsSpectating() then
			ply.wasSpectating = true
		else
			table.insert(self.players, ply)
		end
	end

	if #self.players < self.options.minplayers then
		return false, "not enough players"
	end

	local success, err = self:RunSetup(...)
	if success == false then
		self:RunCleanup()
		return success, err
	end

	PK.currentEvent = self
	ResetKillstreak()
	game.CleanUpMap()

	-- this could be optimised but it only runs once, so it really doesnt matter
	for _, ply in next, player.GetAll() do
		if table.HasValue(self.players, ply) then
			ply.inEvent = true
			ply:Spawn()
			ply:SetFrags(0)
			ply:SetDeaths(0)
			if self.options.freezeplayers then
				ply:PKFreeze(true)
			end
		else
			ply.inEvent = false
			ply:SetSpectating(table.Random(self.players), true)
		end
	end

	for k, v in next, self.hooks do
		hook.Add(v.eventName, v.hookName, v.func)
	end

	timer.Simple(self.options.startfreezetime, function()
		if self.options.freezeplayers then
			for _, ply in next, self.players do
				ply:PKFreeze(false)
			end
		end

		self:RunGameStart()
	end)

	return true
end

function eventmeta:End(...)
	self:RunGameEnd(...)

	for k, v in next, self.hooks do
		hook.Remove(v.eventName, v.hookName)
	end

	-- i set this to nil early so that when players get respawned in the cleanup funciton,
	-- they dont instantly get set back to spectator by the hook checking the joinable option
	PK.currentEvent = nil

	timer.Simple(self.options.endfreezetime, function()
		self:RunCleanup()

		for _, ply in next, player.GetAll() do
			if not ply.wasSpectating then
				ply:StopSpectating(true)
			end

			if not ply:IsSpectating() then
				ply:CleanUp()
				ply:Spawn()
			end

			ply.wasSpectating = false
			ply.inEvent = false
		end

		ResetKillstreak()
	end)
end

function eventmeta:IsValid()
	return true
end

hook.Add("PK_CanSpectate", "pk event system spectate tracking", function()
	local event = PK.currentEvent
	if not event then return end
	if not event.options.joinable then return false end
end)

hook.Add("PK_CanStopSpectating", "pk event system spectate tracking", function()
	local event = PK.currentEvent
	if not event then return end
	if not event.options.joinable then return false end
end)

hook.Add("PlayerSpawn", "pk event system add player", function(ply)
	local event = PK.currentEvent
	if not event then return end
	if ply.inEvent then return end

	if not event.options.joinable then
		ply:SetSpectating(nil, true)
	else
		ply.inEvent = true
		table.insert(event.players, ply)
		hook.Run("PlayerJoinedEvent", ply)
	end
end)

hook.Add("PlayerDisconnected", "pk event system remove player", function(ply)
	local event = PK.currentEvent
	if not event then return end

	if ply.inEvent then
		table.RemoveByValue(event.players, ply)
		local handled = hook.Run("PlayerLeftEvent", ply)
		if handled then return end -- ending handled by event
	end
	
	if #event.players < event.options.minplayers then
		event:End(ply)
	end
end)

hook.Add("PlayerRequestStopSpectating", "pk event system add to event", function(ply)
	local event = PK.currentEvent
	if not event then return end
	
	if event.options.joinable and not ply.inEvent then
		ply.inEvent = true
		table.insert(event.players, ply)
		hook.Run("PlayerJoinedEvent", ply)
	end
end)

hook.Add("PlayerRequestStartSpectating", "pk event system remove from event", function(ply)
	local event = PK.currentEvent
	if not event then return end

	if event.options.joinable and ply.inEvent then
		ply.inEvent = false
		table.RemoveByValue(event.players, ply)
		local handled = hook.Run("PlayerLeftEvent", ply)
		if handled then return end -- ending handled by event
	end

	if #event.players < event.options.minplayers then
		event:End(ply)
	end
end)

hook.Add("PlayerJoinedEvent", "join message", function(ply)
	local event = PK.currentEvent
	if not event then return end

	ply:ChatPrint("You have joined the " .. event.name .. " event")
end)

hook.Add("PlayerLeftEvent", "join message", function(ply)
	local event = PK.currentEvent
	if not event then return end

	ply:ChatPrint("You have left the " .. event.name .. " event")
end)

util.AddNetworkString("PK_EventKick")

net.Receive("PK_EventKick", function(_, ply)
	local event = PK.currentEvent
	if not event then return end
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local plytokick = net.ReadEntity()
	if not IsValid(plytokick) or not plytokick:IsPlayer() then return end

	if plytokick.inEvent then
		table.RemoveByValue(event.players, plytokick)
		plytokick:SetSpectating(nil, true)

		local handled = hook.Run("PlayerLeftEvent", plytokick)
		if handled then return end -- ending handled by event
	end
	
	if #event.players < event.options.minplayers then
		event:End(plytokick)
	end
end)

concommand.Add("pk_endevent", function(ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	PK.currentEvent:End()
end)
