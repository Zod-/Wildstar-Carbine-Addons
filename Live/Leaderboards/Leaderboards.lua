-----------------------------------------------------------------------------------------------
-- Client Lua Script for Leaderboards
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "LeaderboardLib"
require "GameLib"
 
-----------------------------------------------------------------------------------------------
-- Leaderboards Module Definition
-----------------------------------------------------------------------------------------------
local Leaderboards = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local ktClassIcons =
{
	[GameLib.CodeEnumClass.Warrior] 			= "HUD_ClassIcons:spr_Icon_HUD_Class_Warrior",
	[GameLib.CodeEnumClass.Engineer] 			= "HUD_ClassIcons:spr_Icon_HUD_Class_Engineer",
	[GameLib.CodeEnumClass.Esper]				= "HUD_ClassIcons:spr_Icon_HUD_Class_Esper",
	[GameLib.CodeEnumClass.Medic]				= "HUD_ClassIcons:spr_Icon_HUD_Class_Medic",
	[GameLib.CodeEnumClass.Stalker] 			= "HUD_ClassIcons:spr_Icon_HUD_Class_Stalker",
	[GameLib.CodeEnumClass.Spellslinger]	 	= "HUD_ClassIcons:spr_Icon_HUD_Class_Spellslinger"
}

local ktClassTooltips =
{
	[GameLib.CodeEnumClass.Esper] 			= "CRB_Esper",
	[GameLib.CodeEnumClass.Medic] 			= "CRB_Medic",
	[GameLib.CodeEnumClass.Stalker] 		= "ClassStalker",
	[GameLib.CodeEnumClass.Warrior] 		= "CRB_Warrior",
	[GameLib.CodeEnumClass.Engineer] 		= "CRB_Engineer",
	[GameLib.CodeEnumClass.Spellslinger] 	= "CRB_Spellslinger",
}

-- TODO: These are placeholder icons!
local kstrTrendSpriteUp = "BK3:UI_Leaderboards_Arrows_UpTrend"
local kstrTrendSpriteDown = "BK3:UI_Leaderboards_Arrows_DownTrend"
local kstrTrendSpriteEqual = ""

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Leaderboards:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.fTimeRemaining	= 0

    return o
end

function Leaderboards:Init()
    Apollo.RegisterAddon(self)
end
 

-----------------------------------------------------------------------------------------------
-- Leaderboards OnLoad
-----------------------------------------------------------------------------------------------
function Leaderboards:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Leaderboards.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

-----------------------------------------------------------------------------------------------
-- Leaderboards OnDocumentReady
-----------------------------------------------------------------------------------------------
function Leaderboards:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded",	"OnInterfaceMenuListHasLoaded", self)
	self:OnInterfaceMenuListHasLoaded()
	Apollo.RegisterEventHandler("WindowManagementReady",		"OnWindowManagementReady", self)
	self:OnWindowManagementReady()
	
	Apollo.RegisterEventHandler("ToggleLeaderboardsWindow",		"OnToggleLeaderboards", self)
	Apollo.RegisterEventHandler("LeaderboardUpdate",			"OnLeaderboardUpdate", self)	
	
	self.timerRefresh = ApolloTimer.Create(1.0, true, "OnRefreshTimer", self)
	self.timerRefresh:Stop()
	
	self.eLeaderboardSelected = LeaderboardLib.CodeEnumLeaderboardType.Arena3v3
end

-----------------------------------------------------------------------------------------------
-- Leaderboards Functions
-----------------------------------------------------------------------------------------------
function Leaderboards:HelperGetTrendSprite(nRank, nLastRank)
	-- If the entry is unranked, show no trend icon
	if nRank == 0 then
		return ""
	end
	
	if nRank < nLastRank then
		return kstrTrendSpriteUp
	elseif nRank > nLastRank then
		return kstrTrendSpriteDown
	else -- nRank == nLastRank
		return kstrTrendSpriteEqual
	end
end

function Leaderboards:OnLeaderboardUpdate(eLeaderboardType)
	self:BuildLeaderboard(eLeaderboardType)
end

function Leaderboards:OnInterfaceMenuListHasLoaded()
	-- TODO: Placeholder icon!
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("Leaderboards_Title"), {"ToggleLeaderboardsWindow", "Leaderboards", "Icon_Windows32_UI_CRB_InterfaceMenu_Leaderboards"})
end

function Leaderboards:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("Leaderboards_Title"), nSaveVersion = 1})
end

function Leaderboards:OnToggleLeaderboards()
	if self.wndMain then
		self.wndMain:Close()
	else
		self:OnLeaderboardsOn()
	end
end

function Leaderboards:OnLeaderboardsOn()
	if not self.wndMain then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "LeaderboardsForm", nil, self)
		self.wndMain:Invoke()
		local wndNav = self.wndMain:FindChild("LeftFrame:Navigation")
		wndNav:FindChild("ArenaContainer:3v3Rated"):SetData(LeaderboardLib.CodeEnumLeaderboardType.Arena3v3)
		wndNav:FindChild("BattlegroundContainer:EngineerBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.BattlegroundEngineer)
		wndNav:FindChild("BattlegroundContainer:EsperBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.BattlegroundEsper)
		wndNav:FindChild("BattlegroundContainer:MedicBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.BattlegroundMedic)
		wndNav:FindChild("BattlegroundContainer:SpellslingerBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.BattlegroundSpellslinger)
		wndNav:FindChild("BattlegroundContainer:StalkerBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.BattlegroundStalker)
		wndNav:FindChild("BattlegroundContainer:WarriorBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.BattlegroundWarrior)		
	end

	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("Leaderboards_Title")})
	
	local nSeason = MatchMakingLib.GetPvpSeason(MatchMakingLib.MatchType.Arena)
	local strLabel = Apollo.GetString("CRB_PVP")
	
	if nSeason > 0 then
		strLabel = String_GetWeaselString(Apollo.GetString("Leaderboards_PvpSeason"), nSeason)
	end
	
	self.wndMain:FindChild("LeftFrame:Description:Text:Season"):SetText(strLabel)
	
	local wndTypeBtn = self.wndMain:FindChild("LeftFrame:Navigation"):FindChildByUserData(self.eLeaderboardSelected)
	if wndTypeBtn then
		wndTypeBtn:SetCheck(true)
	end
	
	self:BuildLeaderboard(self.eLeaderboardSelected)
end

function Leaderboards:OnRefreshTimer()
	if not self.wndMain then
		return
	end
	
	self.wndMain:FindChild("UpdateTimer"):SetText(LeaderboardLib.GetNextUpdate(self.eLeaderboardSelected))
end

function Leaderboards:BuildTeamEntry(tEntry, tOwnEntry)
	local wndEntry = Apollo.LoadForm(self.xmlDoc, "TeamEntry", self.wndMain:FindChild("RightFrame:ScrollContainer:Content"), self)
	local wndEntryBtn = wndEntry:FindChild("TeamEntryBtn")
	wndEntryBtn:SetText(tEntry.strName)
	
	wndEntryBtn:FindChild("Rating"):SetText(tEntry.nRating)
	wndEntryBtn:FindChild("RankInfo:Ranking"):SetData(tEntry.nRank) -- for sort
	wndEntryBtn:FindChild("RankInfo:Ranking"):SetText(tEntry.nRank)
	wndEntryBtn:FindChild("RankInfo:TrendIcon"):SetSprite(self:HelperGetTrendSprite(tEntry.nRank, tEntry.nLastRank))
	wndEntryBtn:SetData(#tEntry.tTeamMembers)
	
	if tOwnEntry.strName == tEntry.strName then
		wndEntryBtn:SetNormalTextColor("UI_BtnTextGreenNormal")
		wndEntryBtn:SetDisabledTextColor("UI_BtnTextGreenNormal")
		self.wndOwnListEntry = wndEntry
	end
	
	if #tEntry.tTeamMembers > 0 then
		local wndTeamMembers = wndEntry:FindChild("TeamMembers")
		for idx, tMember in pairs(tEntry.tTeamMembers) do
			local wndMember = Apollo.LoadForm(self.xmlDoc, "TeamMemberEntry", wndTeamMembers, self)
			
			wndMember:FindChild("ClassIcon"):SetSprite(ktClassIcons[tMember.eClass])
			wndMember:FindChild("ClassIcon"):SetTooltip(Apollo.GetString(ktClassTooltips[tMember.eClass]))
			local wndMemberName = wndMember:FindChild("MemberName")
			wndMemberName:SetText(tMember.strName)
			
			local nParentLeft, nParentTop, nParentRight, nParentBottom = wndMember:GetAnchorOffsets()
			local nLeft, nTop, nRight, nBottom = wndMemberName:GetAnchorOffsets()
			local nTextWidth = Apollo.GetTextWidth(wndMemberName:GetFont(), wndMemberName:GetText()) + 1

			wndMember:SetAnchorOffsets(nParentLeft, nParentTop, nLeft + nTextWidth, nParentBottom)
		end
	end
	
	wndEntryBtn:Enable(#tEntry.tTeamMembers > 0)	
end

function Leaderboards:BuildLeaderboard(eLeaderboardType)
	if not self.wndMain then
		return
	end
	
	self.eLeaderboardSelected = eLeaderboardType
	
	local tLeaderboard = LeaderboardLib.GetLeaderboard(self.eLeaderboardSelected)
	if not tLeaderboard then
		return
	end
	
	self:OnRefreshTimer()
	
	self.timerRefresh:Set(1.0, true)
	self.timerRefresh:Start()
	
	if not tLeaderboard.bReady then
		return
	end
	
	self.wndOwnListEntry = nil

	local wndContainer = self.wndMain:FindChild("RightFrame:ScrollContainer:Content")
	wndContainer:DestroyChildren()
	
	for idx, tEntry in pairs(tLeaderboard.tEntries) do
		self:BuildTeamEntry(tEntry, tLeaderboard.tOwnEntry)
	end

	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
		return wndLeft:FindChild("TeamEntryBtn:RankInfo:Ranking"):GetData() < wndRight:FindChild("TeamEntryBtn:RankInfo:Ranking"):GetData()
	end)

	self.wndMain:FindChild("TeamName"):SetText(self.eLeaderboardSelected == LeaderboardLib.CodeEnumLeaderboardType.Arena3v3 and Apollo.GetString("PublicEventStats_TeamName") or Apollo.GetString("CRB_Player_Name"))	

	local wndOwnEntry = self.wndMain:FindChild("RightFrame:OwnTeam")
	wndOwnEntry:FindChild("OwnRating"):SetText(tLeaderboard.tOwnEntry.nRating)
	wndOwnEntry:FindChild("OwnName"):SetText(tLeaderboard.tOwnEntry.strName)
	
	local strRank = Apollo.GetString("ErrorDialog_EmptySearch")
	if tLeaderboard.tOwnEntry.nRank > 0 then
		strRank = tLeaderboard.tOwnEntry.nRank
	end
	wndOwnEntry:FindChild("OwnRank"):Enable(tLeaderboard.tOwnEntry.nRank > 0)
	wndOwnEntry:FindChild("OwnRank"):SetTooltip(tLeaderboard.tOwnEntry.nRank > 0 and Apollo.GetString("Leaderboards_GoToOwn") or Apollo.GetString("Leaderboards_YouAreUnranked"))
	wndOwnEntry:FindChild("OwnRank"):SetText(strRank)
	wndOwnEntry:FindChild("OwnRank:TrendIcon"):SetSprite(self:HelperGetTrendSprite(tLeaderboard.tOwnEntry.nRank, tLeaderboard.tOwnEntry.nLastRank))
end

-----------------------------------------------------------------------------------------------
-- LeaderboardsForm Functions
-----------------------------------------------------------------------------------------------
function Leaderboards:OnClose()
	if self.wndMain then
		self.wndMain:Destroy()
		self.wndMain = nil
		self.timerRefresh:Stop()
		Event_FireGenericEvent("WindowManagementRemove", {strName = Apollo.GetString("Leaderboards_Title")})
	end
end


function Leaderboards:OnLeaderboardSelected(wndHandler, wndControl)
	self:BuildLeaderboard(wndHandler:GetData())
end

function Leaderboards:ToggleTeamMembers( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then
		return
	end

	-- if there are no team members, do not expand
	if wndHandler:GetData() == 0 then
		wndHandler:SetCheck(false)
		return
	end
	
	local wndParent = wndHandler:GetParent()
	local wndTeamMembers = wndParent:FindChild("TeamMembers")
	
	local nOldHeight = wndTeamMembers:GetHeight()
	local nNewHeight = wndTeamMembers:ArrangeChildrenTiles()
	local nParentLeft, nParentTop, nParentRight, nParentBottom = wndParent:GetOriginalLocation():GetOffsets()
	
	local nNewBottom = nParentBottom + (nNewHeight - nOldHeight)
	if not wndHandler:IsChecked() then
		nNewBottom = nParentBottom
	end
	
	wndParent:SetAnchorOffsets(nParentLeft, nParentTop, nParentRight, nNewBottom)
	wndParent:GetParent():ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function Leaderboards:OnShowOwnRank( wndHandler, wndControl, eMouseButton )
	if self.wndOwnListEntry then
		local wndContainer = self.wndMain:FindChild("RightFrame:ScrollContainer:Content")
		wndContainer:EnsureChildVisible(self.wndOwnListEntry)
	end
end

-----------------------------------------------------------------------------------------------
-- Leaderboards Instance
-----------------------------------------------------------------------------------------------
local LeaderboardsInst = Leaderboards:new()
LeaderboardsInst:Init()
