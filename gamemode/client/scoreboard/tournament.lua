local PANEL = {}
PANEL.Base = "DHTML"
local challonge_id = CreateConVar("pk_challonge_id", "", {FCVAR_REPLICATED, FCVAR_ARCHIVE})

function PANEL:Init()
	self.joinbutton = vgui.Create("DButton", self)
	self.joinbutton:SetText("Join")
	self.joinbutton:SetFont("pk_tournamentjoin")
	self.joinbutton:SetTextColor(Color(255,255,255))
	self.joinbutton:SetSize(120,35)
	self.joinbutton:SetVisible(false)
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
	if not self.joinbutton then return end

	self.joinbutton:SetPos(0, h - self.joinbutton:GetTall())
end

function PANEL:UpdateChallongeID()
	local bracketid = challonge_id:GetString()
	if bracketid == "" then return end
	
	self.bracketid = bracketid
	if BRANCH == "unknown" then
		self:OpenURL("https://challonge.com/" .. bracketid .. ".svg")
		self.lastRefresh = os.time()
	else
		self:OpenURL("https://challonge.com/" .. bracketid .. "/module")
	end
end

function PANEL:RefreshData()
	if PK.tournamentinfo.state == "pending" then
		self.joinbutton:SetVisible(true)
	else
		self.joinbutton:SetVisible(false)
	end

	if challonge_id:GetString() != self.bracketid then
		self:UpdateChallongeID()
	end

	if BRANCH == "unknown" and os.time() - self.lastRefresh > 5 then
		self.lastRefresh = os.time()
		self:Refresh()
	end
end

function PANEL:OnBeginLoadingDocument()
	self:AddFunction("console", "log", function() end) -- stfu
	self:AddFunction("console", "info", function() end) -- stfu
	self:AddFunction("console", "warn", function() end) -- stfu
	self:AddFunction("console", "error", function() end) -- stfu
end

function PANEL:OnDocumentReady()
	if BRANCH != "unknown" then return end

	-- hacky fix to remove the giant logo and tournament name
	self:QueueJavascript([[
		var svgs = document.getElementsByTagName("svg");
		var txts = document.getElementsByTagName("text");
		var root = svgs[0];
		var logo = svgs[1];
		var title = txts[0];
		var bracket = svgs[2];

		root.removeChild(logo);
		root.removeChild(title);

		var reduceamount = Number(bracket.getAttribute("y"));
		bracket.setAttribute("y", "0");

		root.setAttribute("height", String(Number(root.getAttribute("height")) - reduceamount));
		root.removeAttribute("viewBox");
	]])
end

function PANEL:Paint(w, h)
	draw.RoundedBox(0, 0, 0, w, h, Color(255,255,255))
end

return PANEL
