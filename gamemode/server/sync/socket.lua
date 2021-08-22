sync = sync or {
	addplayers = 1,
	playerspawn = 2,
	playerdisconnect = 3,
	playerupdate = 4,
	playerkill = 5,
	spawnprops = 6,
	propupdate = 7,
	removeprops = 8,
	chatmessage = 9,
	playerteam = 10,
	duelinvite = 11,
	duelresponse = 12,
	duelstart = 13,
	duelupdate = 14,
	duelend = 15,
	dueling = false,
	connected = false,
	duel = {},
	ip = "la.lol.tf",
	port = 27058,
}

local socket = require("socket.core") or socket
include("sync.lua")
include("functions.lua")
include("processing.lua")
include("hooks.lua")
include("duel.lua")

local pps = 0
local ppslast = 0

local function setupsocket(ip, port)
	if clientsock then
		onDisconnect()
	end

	clientsock, err = socket.connect(ip, port)

	if err then
		onDisconnect()
		ErrorNoHalt("sync failed to connect")
		return
	end

	clientsock:setoption("tcp-nodelay", true)
	clientsock:settimeout(5, "t")
	clientsock:settimeout(0, "b")

	timer.Remove("syncretry")
	sync.connected = true
	sync.ip = ip
	sync.port = port
	sync.sendqueue = {}
	print("sync connected")

	local packet = generateInitialPacket()
	clientsock:send(packet .. "\r\n")

	hook.Add("Think", "sync_think", function()
		if not clientsock then return end
		if not sync.connected then return end

		local packet = util.TableToJSON(sync.sendqueue)
		local len, err = clientsock:send(packet .. "\r\n")
		if err == "closed" then
			onDisconnect(true)
		end
		
		sync.sendqueue = {}

		for i=1, 3 do
			local packet = getPacket()
			if packet then
				processSync(util.JSONToTable(packet))
			end
		end

	end)
end

function getPacket()
	local packet, err, part = clientsock:receive("*l")

	if err == "closed" then onDisconnect(true) end
	if err == "timeout" and #part > 0 then
		print("part1", part)
		local packet2, err2, part2 = clientsock:receive("*l")
		print("part2", packet2, part2)
	end
	if packet == nil then return nil end

	pps = pps + 1

	return packet
end

function onDisconnect(retry)
	if not clientsock then return end
	if not retry then retry = false end

	if retry and sync.connected then
		timer.Create("syncretry", 1, 0, function()
			connectSync(sync.ip, sync.port)
		end)

		ErrorNoHaltWithStack("sync error")
	end

	hook.Remove("Think", "sync_think")

	sync.connected = false
	clientsock:close()
	
	for k,v in pairs(player.GetBots()) do
		if v.SyncedPlayer then
			v:Kick()
		end
	end

	for k,v in pairs(sync.syncedprops) do
		if IsValid(v) then
			v:Remove()
			sync.syncedprops[k] = nil
		end
	end

	for k,v in pairs(sync.duel) do
		if IsValid(v.player1) and v.player1.dueling then
			v.player1.dueling = nil
			v.player1:SetNWString("arena", "0")
			v.player1:Spawn()
		end

		if IsValid(v.player2) and v.player2.dueling then
			v.player2.dueling = nil
			v.player2:SetNWString("arena", "0")
			v.player2:Spawn()
		end
	end
	print("goodbye sync")
end

function connectSync(ip, port)
	if not ip then error("no ip given") end
	setupsocket(ip, tonumber(port) or 27058)
end

timer.Create("pps", 1, 0, function()
	ppslast = pps
	if pps > 1 then
		//print("pps", pps)
	end
	pps = 0
end)

concommand.Add("pk_pps", function(ply)
	ply:PrintMessage(HUD_PRINTCONSOLE, ppslast)
end)

concommand.Add("pk_sync", function(ply, cmd, args)
	if not args[1] and IsValid(ply) then
		ply:PrintMessage(HUD_PRINTCONSOLE, "No IP given")
		ply:PrintMessage(HUD_PRINTCONSOLE, "Usage: pk_sync ip:port")
		return
	end

	connectSync(args[1], args[2] or nil)
end)

concommand.Add("pk_unsync", function()
	onDisconnect(false)
end)

/*
sync = sync or {
	addplayers = 1,
	playerspawn = 2,
	playerdisconnect = 3,
	playerupdate = 4,
	playerkill = 5,
	spawnprops = 6,
	propupdate = 7,
	removeprops = 8,
	chatmessage = 9,
	playerteam = 10,
	duelinvite = 11,
	duelresponse = 12,
	duelstart = 13,
	duelupdate = 14,
	duelend = 15,
	dueling = false,
	connected = false,
	ip = "la.lol.tf",
	port = 27058,
}

require("glsock")
include("sync.lua")
include("functions.lua")
include("processing.lua")
include("hooks.lua")
include("duel.lua")

local pps = 0
local ppslast = 0
local lastdata = ""
local lasthead = 0

local function setupsocket(ip, port)
	if clientsock and clientsock.Cancel then
		onDisconnect(clientsock, false)
	end
	clientsock = GLSock(GLSOCK_TYPE_TCP)

	clientsock:Connect(ip, port, function(sock, err)
		if err != GLSOCK_ERROR_SUCCESS then
			print("socket connect error", err)
			return
		end

		print("Connected to server:", sock, err, ip, port)
		
		timer.Remove("syncretry")

		sync.ip = ip
		sync.port = port
		sync.connected = true
		sync.sendqueue = {}

		local initialpacket = generateInitialPacket()
		local buffer = GLSockBuffer()
		buffer:WriteInt(#initialpacket)
		buffer:Write(initialpacket)
		sock:Send(buffer, onSend)

		readHeader(sock)
		
	end)

	// reads per tick
	for i=1, 6 do
		hook.Add("Think", "GLSockPolling" .. i, hook.GetTable()["Think"]["GLSockPolling"])
	end
end

function readHeader(sock)
	sock:Read(4, onHeader)
end

function onReadMore(sock, buffer, err)
	if err != GLSOCK_ERROR_SUCCESS then
		onDisconnect(sock, true)
		return
	end

	local data = buffer:Read(buffer:Size())

	//print("lastdata", lastdata)
	//print("moredata", data)
	print(#lastdata, #data)

	lastdata = lastdata .. data

	if #data != lasthead then
		//print("bytes read not equal to buffer size")
		lasthead = lasthead - #data
		sock:Read(lasthead, onReadMore)
		return
	end

	readHeader(sock)
	
	processSync(util.JSONToTable(lastdata))
	pps = pps + 1
end

function onHeader(sock, buffer, err)
	if err != GLSOCK_ERROR_SUCCESS then
		onDisconnect(sock, true)
		return
	end

	local headsize = buffer:ReadInt()

	if not isnumber(headsize) then
		print("buff size", buffer:Size())
		readHeader(sock)
		return
	end

	if headsize > 65535 then
		print("buffer size error", headsize)
		print(lastdata)
		print(lasthead)
		readHeader(sock)
	end
	lasthead = tonumber(headsize)

	sock:Read(headsize, onRead)
end

function onRead(sock, buffer, err)
	if err != GLSOCK_ERROR_SUCCESS then
		print("socket read error", err)
		onDisconnect(sock, true)
		return
	end

	local data = buffer:Read(buffer:Size())
	lastdata = data
	//print(data)

	if #data != lasthead then
		//print("bytes read less than requested")
		lasthead = lasthead - #data
		sock:Read(lasthead, onReadMore)
		return
	end

	readHeader(sock)

	processSync(util.JSONToTable(data))
	pps = pps + 1
end

function onSend(sock, bytes, err)
	if err != GLSOCK_ERROR_SUCCESS then
		print("socket send error", err)
		onDisconnect(sock, true)
		return
	end
end

function onDisconnect(sock, retry)
	if not clientsock or not clientsock.Cancel then return end

	if retry and sync.connected then
		ErrorNoHaltWithStack("sync error")
		/*timer.Create("syncretry", 1, 0, function()
			connectSync(sync.ip, sync.port)
		end)* /
	end

	sync.connected = false
	sock:Cancel()
	sock:Close()
	
	for k,v in pairs(player.GetBots()) do
		if v.SyncedPlayer then
			v:Kick()
		end
	end
	for k,v in pairs(sync.syncedprops) do
		if IsValid(v) then
			v:Remove()
			sync.syncedprops[k] = nil
		end
	end

	print("goodbye sync")
end

function connectSync(ip, port)
	setupsocket(ip, tonumber(port) or 27058)
end

timer.Create("pps", 1, 0, function()
	ppslast = pps
	if pps > 1 then
		//print("pps", pps)
	end
	pps = 0
end)

concommand.Add("pk_pps", function(ply)
	ply:PrintMessage(HUD_PRINTCONSOLE, ppslast)
end)

concommand.Add("pk_sync", function(ply, cmd, args)
	if not args[1] and IsValid(ply) then
		ply:PrintMessage(HUD_PRINTCONSOLE, "No IP given")
		ply:PrintMessage(HUD_PRINTCONSOLE, "Usage: pk_sync ip:port")
		return
	end

	connectSync(args[1], args[2] or nil)
end)

concommand.Add("pk_unsync", function()
	onDisconnect(clientsock, false)
end)

hook.Add("Think", "sync_sendpacket", function()
	if not clientsock then return end
	if not sync.connected then return end

	local buffer = GLSockBuffer()
	local packet = util.TableToJSON(sync.sendqueue)
	buffer:WriteInt(#packet)
	buffer:Write(packet)
	clientsock:Send(buffer, onSend)
	
	sync.sendqueue = {}
end)

*/