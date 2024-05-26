
PK.events = PK.events or {}

local eventmeta = {}
eventmeta.__index = eventmeta

function newEvent(name)
	if not name then return end
	if PK.events[name] then return PK.events[name] end

	local eventthing = {}
	setmetatable(eventthing, eventmeta)

	eventthing.name = name
	eventthing.hooks = {}

	PK.events[name] = eventthing

	return eventthing
end

function eventmeta:Hook(eventName, hookName, func)
	if not eventName or not hookName or not func then return end

	local hookData = {
		eventName = eventName,
		hookName = hookName,
		func = func,
	}

	table.insert(self.hooks, hookData)
end

function eventmeta:StartFunc(func)
	self.onStartFunc = func
end

function eventmeta:EndFunc(func)
	self.onEndFunc = func
end

function eventmeta:Start(...)
	if PK.currentEvent then return end
	PK.currentEvent = self

	if self.onStartFunc then
		self.onStartFunc(...)
	end

	for k, v in next, self.hooks do
		hook.Add(v.eventName, v.hookName, v.func)
	end
end

function eventmeta:End(...)
	PK.currentEvent = nil

	if self.onEndFunc then
		self.onEndFunc(...)
	end

	for k, v in next, self.hooks do
		hook.Remove(v.eventName, v.hookName)
	end
end

function eventmeta:IsValid()
	return true
end
