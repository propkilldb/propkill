local challonge_apikey = CreateConVar("pk_challonge_apikey", "", {FCVAR_PROTECTED, FCVAR_ARCHIVE})
local challonge_id = CreateConVar("pk_challonge_id", "", {FCVAR_REPLICATED, FCVAR_ARCHIVE})
local urlformat = "https://api.challonge.com/v1/tournaments/%s/%s.json?api_key=%s"

PK.tournamentinfo = PK.tournamentinfo or {
	name = "no tournament",
	state = "closed",
	time = 0
}

local function shouldApiRequest()
	return not (challonge_apikey:GetString() == "" or challonge_id:GetString() == "")
end

function ChallongeAPIGet(section, callback)
	if not shouldApiRequest() then return end
	
	http.Fetch(string.format(urlformat, challonge_id:GetString(), section, challonge_apikey:GetString()),
		function(body, size, headers, code)
			if code != 200 then
				print("ChallongeAPIGet failed", code, body)
				return
			end
			callback(util.JSONToTable(body))
		end,
		function(err)
			print("ChallongeAPIGet failed", section, err)
		end
	)
end

function ChallongeAPIGetTournament(callback)
	if not shouldApiRequest() then return end
	
	http.Fetch(string.format("https://api.challonge.com/v1/tournaments/%s.json?api_key=%s", challonge_id:GetString(), challonge_apikey:GetString()),
		function(body, size, headers, code)
			if code != 200 then
				print("ChallongeAPIGetTournament failed", code, body)
				return
			end
			callback(util.JSONToTable(body))
		end,
		function(err)
			print("ChallongeAPIGetTournament failed", section, err)
		end
	)
end

function ChallongeAPIPost(section, data, callback)
	if not shouldApiRequest() then return end
	
	data = data or {}
	data.api_key = challonge_apikey:GetString()
	http.Post(string.format(urlformat, challonge_id:GetString(), section, challonge_apikey:GetString()), data,
		function(body, size, headers, code)
			if code != 200 then
				print("ChallongeAPIPost failed", code, body)
				return
			end

			if isfunction(callback) then
				callback(util.JSONToTable(body))
			end
		end,
		function(err)
			print("ChallongeAPIPost failed", section, err)
		end
	)
end


function ChallongeAPIPut(section, body, callback)
	if not shouldApiRequest() then return end
	
	HTTP({
		url = string.format(urlformat, challonge_id:GetString(), section, challonge_apikey:GetString()),
		method = "PUT",
		body = util.TableToJSON(body),
		type = "application/json",
		success = function(code, body, headers)
			if code != 200 then
				print("ChallongeAPIPut failed", code, body)
				return
			end

			if isfunction(callback) then
				callback(util.JSONToTable(body))
			end
		end,
		failed = function(err)
			print("ChallongeAPIPut failed", section, err)
		end,
	})
end

function ChallongeGetMatchData(callback)
	local playermap = {}
	local matchmap = {}

	ChallongeAPIGet("participants", function(participants)
		for k, v in next, participants do
			playermap[v.participant.id] = {
				name = v.participant.name,
				steamid = v.participant.misc
			}
		end

		ChallongeAPIGet("matches", function(matches)
			for k, v in next, matches do
				local player1 = isnumber(v.match.player1_id) and playermap[v.match.player1_id] or {}
				local player2 = isnumber(v.match.player2_id) and playermap[v.match.player2_id] or {}

				matchmap[v.match.id] = {
					matchid = v.match.id,
					state = v.match.state,
					round = v.match.round,
					num = v.match.suggested_play_order,
					player1 = player1.name,
					player2 = player2.name,
					player1steamid = player1.steamid,
					player2steamid = player2.steamid,
				}
			end

			if isfunction(callback) then
				callback(matchmap, playermap)
			end
		end)
	end)
end

function ChallongeRegisterPlayer(ply, callback)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if not callback then callback = (function() end) end
	//if ply:Ping() > 140 then callback(false, "ping limit exceeded") return end

	ChallongeAPIGet("participants", function(participants)
		if not IsValid(ply) or not ply:IsPlayer() then return end
		
		for k, v in next, participants do
			if ply:SteamID64() == v.participant.misc then
				callback(false, "already registered")
				return
			end

			if string.lower(ply:Nick()) == string.lower(v.participant.name) then
				callback(false, "name taken")
				return
			end
		end

		ChallongeAPIPost("participants", {
			["participant[name]"] = ply:Nick(),
			["participant[misc]"] = ply:SteamID64()
		}, function()
			callback(true)
		end)
	end)
end

util.AddNetworkString("pk_tournamentenroll")

net.Receive("pk_tournamentenroll", function(_, ply)
	if ply.PK_TournamentEnrolled then return end
	if ply.PK_TournamentEnroll and ply.PK_TournamentEnroll > os.time() then return end
	ply.PK_TournamentEnroll = os.time() + 15
	
	ChallongeRegisterPlayer(ply, function(success, reason)
		if not IsValid(ply) then return end

		if not success then
			ply:ChatPrint("Failed to join tournament: " .. reason)
			return
		end

		ply.PK_TournamentEnrolled = true
		ply:ChatPrint("Successfully joined the " .. PK.tournamentinfo.name)
	end)
end)

function ParseISODateTimestamp(str)
	local year, month, day, hour, min, sec, tz_sign, tz_hour, tz_min = str:match("(%d%d%d%d)-?(%d%d)-?(%d%d)T(%d%d):?(%d%d):?(%d%d)[%.?%d]*([Z%+%-]?)(%d?%d?):?(%d?%d?)")

	year, month, day = tonumber(year), tonumber(month), tonumber(day)
	hour, min, sec = tonumber(hour), tonumber(min), tonumber(sec)

	local tz_offset = 0
	if tz_sign == "Z" then
		tz_offset = 0
	elseif tz_sign == "+" or tz_sign == "-" then
		tz_hour = tonumber(tz_hour) or 0
		tz_min = tonumber(tz_min) or 0
		tz_offset = tz_hour * 60 + tz_min
		if tz_sign == "-" then
			tz_offset = -tz_offset
		end
	end

	local t = os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec, isdst = false})
	return t - tz_offset * 60 + os.difftime(os.time(), os.time(os.date("!*t")))
end

function ChallongeUpdateTournamentInfo()
	ChallongeAPIGetTournament(function(data)
		local tournament = data["tournament"]

		PK.tournamentinfo = {
			name = tournament.name,
			state = tournament.state,
			time = tournament.start_at and ParseISODateTimestamp(tournament.start_at) or 0
		}
	end)
end

hook.Add("Initialize", "load tournament info", ChallongeUpdateTournamentInfo)
cvars.AddChangeCallback("pk_challonge_apikey", ChallongeUpdateTournamentInfo)
cvars.AddChangeCallback("pk_challonge_id", ChallongeUpdateTournamentInfo)

util.AddNetworkString("pk_tournementnotify")

net.Receive("pk_tournementnotify", function(_, ply)
	if ply.PK_TournamentNotified then return end
	ply.PK_TournamentNotified = true
	
	net.Start("pk_tournementnotify")
		net.WriteString(PK.tournamentinfo.name)
		net.WriteString(PK.tournamentinfo.state)
		net.WriteInt(PK.tournamentinfo.time, 32)
	net.Send(ply)
end)
