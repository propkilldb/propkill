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


local function setupsocket(ip, port)
	if clientsock and clientsock.Cancel then onDisconnect(clientsock) end
	clientsock = GLSock(GLSOCK_TYPE_TCP)

	clientsock:Connect(ip, port, function(sock, err)
		if err != GLSOCK_ERROR_SUCCESS then
			print("socket connect error", err)
			onDisconnect(sock)
			return
		end

		print("Connected to server:", sock, err, ip, port)

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

	// yes
	hook.Add("Think", "GLSockPolling2", hook.GetTable()["Think"]["GLSockPolling"])
	hook.Add("Think", "GLSockPolling3", hook.GetTable()["Think"]["GLSockPolling"])
	hook.Add("Think", "GLSockPolling4", hook.GetTable()["Think"]["GLSockPolling"])
	hook.Add("Think", "GLSockPolling5", hook.GetTable()["Think"]["GLSockPolling"])

end

function readHeader(sock)
	sock:Read(4, onHeader)
end

function onHeader(sock, buffer, err)
	if err != GLSOCK_ERROR_SUCCESS then return end
	if buffer == nil then 
		readHeader()
		return
	end

	sock:Read(buffer:ReadInt(), onRead)
end

function onRead(sock, buffer, err)
	if err != GLSOCK_ERROR_SUCCESS then
		print("socket read error", err)
		onDisconnect(sock)
		return
	end

	local data = buffer:Read(buffer:Size())
	//print(data)

	readHeader(sock)
	
	processSync(util.JSONToTable(data))
	pps = pps + 1
end

function onSend(sock, bytes, err)
	if err != GLSOCK_ERROR_SUCCESS then
		print("socket send error", err)
		onDisconnect(sock)
		return
	end
end

function onDisconnect(sock)
	if not clientsock or not clientsock.Cancel then return end
	print("goodbye sync")
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
			v = nil
		end
	end
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
	onDisconnect(clientsock)
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
