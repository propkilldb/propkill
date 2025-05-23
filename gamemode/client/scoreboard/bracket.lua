local PANEL = {}
PANEL.Base = "DHTML"
local challonge_id = CreateConVar("pk_challonge_id", "", {FCVAR_REPLICATED, FCVAR_ARCHIVE})

function PANEL:Init()
	if BRANCH == "unknown" then -- unknown = default branch
		self:SetHTML([[
			<br>
			<center style="color: #fff">
				<h2>Please change your Garry's Mod to the x86-64 beta branch to see the bracket</h2>
				<img src="https://images.steamusercontent.com/ugc/1898857260618639534/16524E2140288CD70902A5D845289D29C1450B94/">
			</center>
		]])
		return
	end
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
	if BRANCH == "unknown" then return end

	if challonge_id:GetString() != self.bracketid then
		self:UpdateChallongeID()
	end
end

function PANEL:Paint(w, h)

end

return PANEL
