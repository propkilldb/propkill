local challonge_apikey = CreateConVar("pk_challonge_apikey", "", {FCVAR_PROTECTED, FCVAR_ARCHIVE})
local challonge_id = CreateConVar("pk_challonge_id", "", {FCVAR_REPLICATED, FCVAR_ARCHIVE})
local urlformat = "https://api.challonge.com/v1/tournaments/%s/%s.json?api_key=%s"

function ChallongeAPIGet(section, callback)
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

function ChallongeAPIPost(section, data, callback)
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
			playermap[v.participant.id] = v.participant.name
		end

		ChallongeAPIGet("matches", function(matches)
			for k, v in next, matches do
				matchmap[v.match.id] = {
					state = v.match.state,
					round = v.match.round,
					player1 = playermap[v.match.player1_id],
					player2 = playermap[v.match.player2_id],
				}
			end

			if isfunction(callback) then
				callback(matchmap, playermap)
			end
		end)
	end)
end
