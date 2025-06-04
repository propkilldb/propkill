local PANEL = {}
PANEL.Base = "DHTML"
local challonge_id = CreateConVar("pk_challonge_id", "", {FCVAR_REPLICATED, FCVAR_ARCHIVE})

function PANEL:Init()
	function self:OnBeginLoadingDocument()
		self:AddFunction("console", "log", function() end) -- stfu
		self:AddFunction("console", "info", function() end) -- stfu
		self:AddFunction("console", "warn", function() end) -- stfu
	end

	if BRANCH == "unknown" then -- unknown = default branch
		self:SetHTML([[
			<br>
			<center style="color: #fff">
				<h2>Please change your Garry's Mod to the x86-64 beta branch to see the bracket</h2>
				<img src="https://images.steamusercontent.com/ugc/1898857260618639534/16524E2140288CD70902A5D845289D29C1450B94/">
			</center>
		]])
	end

	self.joinbutton = vgui.Create("DButton", self)
	self.joinbutton:SetText("Join")
	self.joinbutton:SetFont("pk_tournamentjoin")
	self.joinbutton:SetTextColor(Color(255,255,255))
	self.joinbutton:SetSize(120,35)
	function self.joinbutton:Paint(w, h)
		surface.SetDrawColor(Color(0,200,0))
		if self:IsDown() then
			surface.SetDrawColor(Color(0,120,0))
		elseif self:IsHovered() then
			surface.SetDrawColor(Color(0,150,0))
		end
		surface.DrawRect(0, 0, w, h)
	end
	function self.joinbutton:DoClick()
		net.Start("pk_tournamentenroll")
		net.SendToServer()
		LocalPlayer():SetPData("tournamentinvitedismissed", (PK.tournamentinfo.date or os.time()) - 172800)
	end
end

function PANEL:PerformLayout(w, h)
	self.joinbutton:SetPos(0, h - self.joinbutton:GetTall())
end

function PANEL:UpdateChallongeID()
	local bracketid = challonge_id:GetString()
	if bracketid == "" then return end
	if BRANCH == "unknown" then return end

	self.bracketid = bracketid
	self:OpenURL("https://challonge.com/" .. bracketid .. "/module")
end

function PANEL:RefreshData()
	if challonge_id:GetString() != self.bracketid then
		self:UpdateChallongeID()
	end
end

function PANEL:Paint(w, h)

end

return PANEL
