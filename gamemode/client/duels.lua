
PK.invitequeue = PK.invitequeue or {}

net.Receive("pk_duelinvite", function(len)
	local fighter = net.ReadEntity()
	local kills = net.ReadInt(8)
	local time = net.ReadInt(8)

	QueueDuelInvite(fighter, kills, time)
end)

function QueueDuelInvite(fighter, kills, time)
	if not IsValid(fighter) or not fighter:IsPlayer() then return end

	local fightdata = {
		fighter = fighter,
		kills = kills or 15,
		time = time or 10,
	}
	table.insert(PK.invitequeue, fightdata)
	
	DisplayDuelInvite()
end

function DisplayDuelInvite()
	if ispanel(DuelInvite) then return end -- theres already an invite being shown
	if #PK.invitequeue == 0 then return end -- no invites to display

	local fightdata = table.remove(PK.invitequeue, 1)
	if fightdata == nil then return end -- this shouldnt happen, but just in case
	if not IsValid(fightdata.fighter) or not fightdata.fighter:IsPlayer() then return end

	DuelInvite = vgui.Create("pk_duelinvite")
	DuelInvite:SetDuelist(fightdata.fighter)
	DuelInvite:SetInfo(fightdata.kills, fightdata.time)
	function DuelInvite:DoAccept()
		net.Start("pk_duelaccept")
			net.WriteEntity(fightdata.fighter)
			net.WriteBool(true)
		net.SendToServer()
		
		DuelInvite:Remove()
		DuelInvite = nil
	end
	function DuelInvite:DoDecline()
		DuelInvite:Remove()
		DuelInvite = nil

		DisplayDuelInvite()
	end
end
