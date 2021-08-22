cwhite = Color(255,255,255)
cgrey = Color(200,200,200)

util.AddNetworkString("pk_chatmsg")
util.AddNetworkString("pk_notify")
util.AddNetworkString("pk_gamenotify")

function ChatMsg(message)
	net.Start("pk_chatmsg")
		net.WriteTable(message)
	net.Broadcast() 
end

function NotifyAll(message)
	for k,v in pairs(player.GetAll()) do
		net.Start("pk_notify")
			net.WriteString(message)
		net.Send(v)
	end
end

function GameNotify(message, time)
	net.Start("pk_gamenotify")
		net.WriteString(message)
		net.WriteInt(time or 3, 16)
	net.Broadcast()
end

function TeamNotify(t, message, time)
	for k,v in pairs(team.GetPlayers(t)) do
		net.Start("pk_gamenotify")
			net.WriteString(message)
			net.WriteInt(time or 3, 16)
		net.Send(v)
	end
end

function LogPrint(message)
	MsgC(cwhite, "[Propkill]: ", cgrey, message .. "\n")
end

function dprint(...)
	if PK.debug then
		print(...)
	end
end

function Notify(ply, message)
	net.Start("pk_notify")
		net.WriteString(message)
	net.Send(ply)
end

function shuffle(table)
	local num = #table
	for i = 1, num do
		local randnum = math.random(1, num)
		table[randnum], table[i] = table[i], table[randnum]
	end
	return table
end

hook.Add("SetupPlayerVisibility", "addallplayers", function(ply)
	-- Adds any view entity
	for k,v in pairs(ents.GetAll()) do
		if v:GetClass() == "prop_physics" or v:IsPlayer() then
			AddOriginToPVS(v:GetPos())
		end
	end
end)
