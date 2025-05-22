local PANEL = {}
PANEL.Base = "DHTML"
local challonge_id = CreateConVar("pk_challonge_id", "", {FCVAR_REPLICATED, FCVAR_ARCHIVE})

function PANEL:Init()
	self:UpdateChallongeID()
end

function PANEL:UpdateChallongeID()
	local bracketid = challonge_id:GetString()
	if bracketid == "" then return end

	self.bracketid = bracketid
	self:OpenURL("https://challonge.com/" .. bracketid .. "/module")
	self:AddFunction("console", "log", function() end) -- stfu
	self:AddFunction("console", "info", function() end) -- stfu
	self:AddFunction("console", "warn", function() end) -- stfu
end

function PANEL:RefreshData()
	if challonge_id:GetString() != self.bracketid then
		self:UpdateChallongeID()
	end
end

function PANEL:Paint(w, h)

end

return PANEL
