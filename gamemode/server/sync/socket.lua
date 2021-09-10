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
	voicedata = 16,
	dueling = false,
	connected = false,
	duel = {},
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
		
	end)

	// reads per tick
	for i=1, 8 do
		hook.Add("Think", "GLSockPolling" .. i, hook.GetTable()["Think"]["GLSockPolling"])
	end
end

function readHeader(sock)
	readUntil(4, onHeader)
end

function onHeader(buffer)
	local headsize = buffer:ReadInt()

	readUntil(headsize, onRead)
end

function onRead(buffer)
	local data = buffer:Read(buffer:Size())

	readHeader(sock)

	processSync(util.JSONToTable(data))
end

function readUntil(bytes, callback)
	local finalbuffer = GLSockBuffer()
	local finalsize = 0

	local function readData(sock, buffer, err)
		if err != GLSOCK_ERROR_SUCCESS then
			print("socket read error", err)
			onDisconnect(sock, true)
			return
		end

		pps = pps + 1
		
		local data = buffer:Read(bytes)
		finalsize = finalsize + buffer:Size()

		finalbuffer:Write(data)

		//print(#data, finalbuffer:Size(), finalsize, bytes)
		if finalsize != bytes then
			//print("reading more", bytes, finalsize)
			clientsock:Read(bytes - finalsize, readData)
			return
		end

		finalbuffer:Seek(0, GLSOCKBUFFER_SEEK_SET)
		callback(finalbuffer)
	end

	clientsock:Read(bytes, readData)
end

function onSend(sock, bytes, err)
	if err != GLSOCK_ERROR_SUCCESS then
		print("socket send error", err)
		onDisconnect(sock, true)
		return
	end
end

function onDisconnect(sock, retry)
	if not sock then sock = clientsock end
	if not clientsock or not clientsock.Cancel then return end

	if retry and sync.connected then
		timer.Create("syncretry", 1, 0, function()
			connectSync(sync.ip, sync.port)
		end)

		ErrorNoHaltWithStack("sync error")
	end

	hook.Remove("Think", "sync_sendpacket")

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
