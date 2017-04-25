-----------------------------------------------------------------------------------------------
-- Client Lua Script for Leaderboards
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "LeaderboardLib"
require "GameLib"
require "MatchMakingLib"
require "MatchMakingEntry"
require "PublicEvent"
 
-----------------------------------------------------------------------------------------------
-- Leaderboards Module Definition
-----------------------------------------------------------------------------------------------
local Leaderboards = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local ktClassIcons =
{
	[GameLib.CodeEnumClass.Warrior] = "BK3:UI_Icon_CharacterCreate_Class_Warrior",
	[GameLib.CodeEnumClass.Engineer] = "BK3:UI_Icon_CharacterCreate_Class_Engineer",
	[GameLib.CodeEnumClass.Esper] = "BK3:UI_Icon_CharacterCreate_Class_Esper",
	[GameLib.CodeEnumClass.Medic] = "BK3:UI_Icon_CharacterCreate_Class_Medic",
	[GameLib.CodeEnumClass.Stalker] = "BK3:UI_Icon_CharacterCreate_Class_Stalker",
	[GameLib.CodeEnumClass.Spellslinger] = "BK3:UI_Icon_CharacterCreate_Class_Spellslinger"
}

local ktClassColors =
{
	[GameLib.CodeEnumClass.Warrior] = "ClassWarrior",
	[GameLib.CodeEnumClass.Engineer] = "ClassEngineer",
	[GameLib.CodeEnumClass.Esper] = "ClassEsper",
	[GameLib.CodeEnumClass.Medic] = "ClassMedic",
	[GameLib.CodeEnumClass.Stalker] = "ClassStalker",
	[GameLib.CodeEnumClass.Spellslinger] = "ClassSpellslinger"
}

local ktClassTooltips =
{
	[GameLib.CodeEnumClass.Esper] = "CRB_Esper",
	[GameLib.CodeEnumClass.Medic] = "CRB_Medic",
	[GameLib.CodeEnumClass.Stalker] = "ClassStalker",
	[GameLib.CodeEnumClass.Warrior] = "CRB_Warrior",
	[GameLib.CodeEnumClass.Engineer] = "CRB_Engineer",
	[GameLib.CodeEnumClass.Spellslinger] = "CRB_Spellslinger",
}

local kstrTrendSpriteUp = "BK3:UI_Leaderboards_Arrows_UpTrend"
local kstrTrendSpriteDown = "BK3:UI_Leaderboards_Arrows_DownTrend"
local kstrTrendSpriteEqual = ""

local kPvE =
{
	[LeaderboardLib.CodeEnumLeaderboardType.PveDungeon] = true,
	[LeaderboardLib.CodeEnumLeaderboardType.PveExpeditionGroup] = true,
	[LeaderboardLib.CodeEnumLeaderboardType.PveExpeditionSolo] = true,
}

local kPvP =
{
	[LeaderboardLib.CodeEnumLeaderboardType.Arena3v3] = true,
	[LeaderboardLib.CodeEnumLeaderboardType.BattlegroundEngineer] = true,
	[LeaderboardLib.CodeEnumLeaderboardType.BattlegroundEsper] = true,
	[LeaderboardLib.CodeEnumLeaderboardType.BattlegroundMedic] = true,
	[LeaderboardLib.CodeEnumLeaderboardType.BattlegroundSpellslinger] = true,
	[LeaderboardLib.CodeEnumLeaderboardType.BattlegroundStalker] = true,
	[LeaderboardLib.CodeEnumLeaderboardType.BattlegroundWarrior] = true,
}

local kRewardTierToMedalIcon =
{
	[PublicEvent.PublicEventRewardTier_Gold] = "CRB_ChallengeTrackerSprites:sprChallengeTierGold",
	[PublicEvent.PublicEventRewardTier_Silver] = "CRB_ChallengeTrackerSprites:sprChallengeTierSilver",
	[PublicEvent.PublicEventRewardTier_Bronze] = "CRB_ChallengeTrackerSprites:sprChallengeTierBronze",
}


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Leaderboards:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.fTimeRemaining = 0

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
	
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
	self:OnInterfaceMenuListHasLoaded()
	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()
	
	Apollo.RegisterEventHandler("ToggleLeaderboardsWindow", "OnToggleLeaderboards", self)
	Apollo.RegisterEventHandler("LeaderboardUpdate", "OnLeaderboardUpdate", self)	
	
	self.timerRefresh = ApolloTimer.Create(1.0, true, "OnRefreshTimer", self)
	self.timerRefresh:Stop()
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

function Leaderboards:HelperGetMedalSprite(nRewardTier)
	-- If the entry is unranked, show no medal icon
	if nRewardTier == 0 then
		return ""
	end
	
	if kRewardTierToMedalIcon[nRewardTier] == nil then
		return ""
	end
	
	return kRewardTierToMedalIcon[nRewardTier]
end

function Leaderboards:OnLeaderboardUpdate(eLeaderboardType)
	if kPvP[eLeaderboardType] then
		self:BuildPvPLeaderboard(eLeaderboardType)
	end
	
	if kPvE[eLeaderboardType] then
		self:BuildPvELeaderboard(eLeaderboardType, self.eMatchingMap, self.nPrimeLevel, self.eMedal)
	end
end

function Leaderboards:OnInterfaceMenuListHasLoaded()
	-- TODO: Placeholder icon!
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("Leaderboards_Title"), {"ToggleLeaderboardsWindow", "Leaderboards", "Icon_Windows32_UI_CRB_InterfaceMenu_Leaderboards"})
end

function Leaderboards:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("Leaderboards_Title"), nSaveVersion = 2})
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
		
		self.wndMain:FindChild("HeaderButtons:PvEBtn"):AttachWindow(self.wndMain:FindChild("Frame:PvEFrame"))
		self.wndMain:FindChild("HeaderButtons:PvPBtn"):AttachWindow(self.wndMain:FindChild("Frame:PvPFrame"))
		
		self.wndMain:FindChild("Frame:PvPFrame:SubHeader:InstanceFilter"):AttachWindow(self.wndMain:FindChild("Frame:PvPFrame:SubHeader:InstanceFilter:Dropdown"))
		self.wndMain:FindChild("Frame:PvPFrame:SubHeader:InstanceFilter:Dropdown:Container:Arena3v3RatedFilterBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.Arena3v3)
		self.wndMain:FindChild("Frame:PvPFrame:SubHeader:InstanceFilter:Dropdown:Container:BattlegroundsFilterBtn"):AttachWindow(self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter"))
		
		self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter"):AttachWindow(self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter:Dropdown"))
		self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter:Dropdown:Container:EngineerFilterBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.BattlegroundEngineer)
		self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter:Dropdown:Container:EsperFilterBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.BattlegroundEsper)
		self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter:Dropdown:Container:MedicFilterBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.BattlegroundMedic)
		self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter:Dropdown:Container:SpellslingerFilterBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.BattlegroundSpellslinger)
		self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter:Dropdown:Container:StalkerFilterBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.BattlegroundStalker)
		self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter:Dropdown:Container:WarriorFilterBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.BattlegroundWarrior)
		
		
		self.wndMain:FindChild("Frame:PvEFrame:SubHeader:ContentFilter"):AttachWindow(self.wndMain:FindChild("Frame:PvEFrame:SubHeader:ContentFilter:Dropdown"))
		self.wndMain:FindChild("Frame:PvEFrame:SubHeader:ContentFilter:Dropdown:Container:DungeonsContentFilterBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.PveDungeon)
		self.wndMain:FindChild("Frame:PvEFrame:SubHeader:ContentFilter:Dropdown:Container:GroupExpeditionsContentFilterBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.PveExpeditionGroup)
		self.wndMain:FindChild("Frame:PvEFrame:SubHeader:ContentFilter:Dropdown:Container:SoloExpeditionsContentFilterBtn"):SetData(LeaderboardLib.CodeEnumLeaderboardType.PveExpeditionSolo)
		
		self.wndMain:FindChild("Frame:PvEFrame:SubHeader:InstanceFilter"):AttachWindow(self.wndMain:FindChild("Frame:PvEFrame:SubHeader:InstanceFilter:Dropdown"))
		
		self.wndMain:FindChild("Frame:PvEFrame:SubHeader:PrimeFilter"):AttachWindow(self.wndMain:FindChild("Frame:PvEFrame:SubHeader:PrimeFilter:Dropdown"))
		
		self.wndMain:FindChild("Frame:PvEFrame:SubHeader:MedalsFilter"):AttachWindow(self.wndMain:FindChild("Frame:PvEFrame:SubHeader:MedalsFilter:Dropdown"))
		self.wndMain:FindChild("Frame:PvEFrame:SubHeader:MedalsFilter:Dropdown:Container:AllMedalsContentFilterBtn"):SetData(PublicEvent.PublicEventRewardTier_None)
		self.wndMain:FindChild("Frame:PvEFrame:SubHeader:MedalsFilter:Dropdown:Container:GoldContentFilterBtn"):SetData(PublicEvent.PublicEventRewardTier_Gold)
		self.wndMain:FindChild("Frame:PvEFrame:SubHeader:MedalsFilter:Dropdown:Container:SilverContentFilterBtn"):SetData(PublicEvent.PublicEventRewardTier_Silver)
		self.wndMain:FindChild("Frame:PvEFrame:SubHeader:MedalsFilter:Dropdown:Container:BronzeContentFilterBtn"):SetData(PublicEvent.PublicEventRewardTier_Bronze)
	end

	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("Leaderboards_Title")})
	
	local nSeason = MatchMakingLib.GetPvpSeason(MatchMakingLib.MatchType.Arena)
	local strLabel = Apollo.GetString("CRB_PVP")
	
	if nSeason > 0 then
		strLabel = String_GetWeaselString(Apollo.GetString("Leaderboards_PvpSeason"), nSeason)
	end
	
	self.wndMain:FindChild("Frame:PvPFrame:SubHeader:SeasonLabel"):SetText(strLabel)
		
	self:PvEResetContent()
	self:PvEPopulateInstances(self.eLeaderboardSelected)
	self:PvEPopulatePrime(self.eMatchingMap)
	self:PvEResetMedals()
	
	self.wndMain:FindChild("Frame:PvPFrame:SubHeader:InstanceFilter"):SetText(Apollo.GetString("Leaderboards_Rated3v3"))
	self.wndMain:FindChild("Frame:PvPFrame:SubHeader:InstanceFilter:Dropdown:Container"):SetRadioSel("Leaderboard_ContentFilter", 1)
	self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter"):SetText(Apollo.GetString("ClassEngineer"))
	self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter:Dropdown:Container"):SetRadioSel("Leaderboard_ContentFilter", 1)
	
	self.wndMain:FindChild("HeaderButtons:PvEBtn"):SetCheck(false)
	self.wndMain:FindChild("HeaderButtons:PvPBtn"):SetCheck(true)
	self.eLeaderboardSelected = LeaderboardLib.CodeEnumLeaderboardType.Arena3v3
	self:BuildPvPLeaderboard(self.eLeaderboardSelected)
end

function Leaderboards:OnRefreshTimer()
	if self.wndMain ~= nil and not self.wndMain:IsValid() then
		return
	end
	
	self.wndMain:FindChild("UpdateTimer"):SetText(LeaderboardLib.GetNextUpdate(self.eLeaderboardSelected, self.eMatchingMap, self.nPrimeLevel, self.eMedal))
end

-----------------------------------------------------------------------------------------------
-- PvP
-----------------------------------------------------------------------------------------------

function Leaderboards:BuildPvPTeamEntry(tEntry, tOwnEntry)
	local wndEntry = Apollo.LoadForm(self.xmlDoc, "PvPTeamEntry", self.wndMain:FindChild("Frame:PvPFrame:ScrollContainer:Content"), self)
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
	
	if next(tEntry.tTeamMembers) ~= nil then
		local wndTeamMembers = wndEntry:FindChild("TeamMembers")
		for idx, tMember in pairs(tEntry.tTeamMembers) do
			local wndMember = Apollo.LoadForm(self.xmlDoc, "PvPTeamMemberEntry", wndTeamMembers, self)
			
			wndMember:FindChild("ClassIcon"):SetSprite(ktClassIcons[tMember.eClass])
			wndMember:FindChild("ClassIcon"):SetTooltip(Apollo.GetString(ktClassTooltips[tMember.eClass]))
			local wndMemberName = wndMember:FindChild("MemberName")
			wndMemberName:SetText(tMember.strName)
			wndMemberName:SetTextColor(ktClassColors[tMember.eClass])
			
			local nParentLeft, nParentTop, nParentRight, nParentBottom = wndMember:GetAnchorOffsets()
			local nLeft, nTop, nRight, nBottom = wndMemberName:GetAnchorOffsets()
			local nTextWidth = Apollo.GetTextWidth(wndMemberName:GetFont(), wndMemberName:GetText()) + 1

			wndMember:SetAnchorOffsets(nParentLeft, nParentTop, nLeft + nTextWidth, nParentBottom)
		end
	end
	
	wndEntryBtn:Enable(#tEntry.tTeamMembers > 0)	
end

function Leaderboards:BuildPvPLeaderboard(eLeaderboardType)
	if self.wndMain == nil or not self.wndMain:IsValid() then
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
	
	self.wndMain:FindChild("Frame:PvPFrame:LoadingBlocker"):Show(not tLeaderboard.bReady)
	if not tLeaderboard.bReady then
		return
	end
	
	self.wndOwnListEntry = nil

	local wndContainer = self.wndMain:FindChild("Frame:PvPFrame:ScrollContainer:Content")
	wndContainer:DestroyChildren()
	
	for idx, tEntry in pairs(tLeaderboard.tEntries) do
		self:BuildPvPTeamEntry(tEntry, tLeaderboard.tOwnEntry)
	end

	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
		return wndLeft:FindChild("TeamEntryBtn:RankInfo:Ranking"):GetData() < wndRight:FindChild("TeamEntryBtn:RankInfo:Ranking"):GetData()
	end)

	self.wndMain:FindChild("TeamName"):SetText(self.eLeaderboardSelected == LeaderboardLib.CodeEnumLeaderboardType.Arena3v3 and Apollo.GetString("PublicEventStats_TeamName") or Apollo.GetString("CRB_Player_Name"))	

	local wndOwnEntry = self.wndMain:FindChild("Frame:PvPFrame:OwnTeam")
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

function Leaderboards:OnPvPTabSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.eLeaderboardSelected = self.wndMain:FindChild("Frame:PvEFrame:SubHeader:ContentFilter:Dropdown:Container"):GetRadioSelButton("Leaderboard_ContentFilter"):GetData()
	if self.eLeaderboardSelected == nil then
		self.eLeaderboardSelected = self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter:Dropdown:Container"):GetRadioSelButton("Leaderboard_ContentFilter"):GetData()
	end
	self:BuildPvPLeaderboard(self.eLeaderboardSelected)
end

function Leaderboards:OnPvPLeaderboardBattlegroundsSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:BuildPvPLeaderboard(self.wndMain:FindChild("Frame:PvPFrame:SubHeader:ClassFilter:Dropdown:Container"):GetRadioSelButton("Leaderboard_ContentFilter"):GetData())
end

function Leaderboards:OnPvPLeaderboardSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:BuildPvPLeaderboard(wndHandler:GetData())
end

function Leaderboards:ToggleTeamMembers(wndHandler, wndControl, eMouseButton)
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

function Leaderboards:OnShowOwnRank(wndHandler, wndControl, eMouseButton)
	if self.wndOwnListEntry then
		local wndContainer = self.wndMain:FindChild("RightFrame:ScrollContainer:Content")
		wndContainer:EnsureChildVisible(self.wndOwnListEntry)
	end
end

-----------------------------------------------------------------------------------------------
-- PvE
-----------------------------------------------------------------------------------------------

function Leaderboards:BuildPvETeamEntry(tEntry, tOwnEntry)
	local wndEntry = Apollo.LoadForm(self.xmlDoc, "PvETeamEntry", self.wndMain:FindChild("Frame:PvEFrame:ScrollContainer:Content"), self)
	local wndEntryBtn = wndEntry:FindChild("TeamEntryBtn")
	
	wndEntryBtn:FindChild("RankInfo:Ranking"):SetData(tEntry.nRank) -- for sort
	wndEntryBtn:FindChild("RankInfo:Ranking"):SetText(tEntry.nRank)
	wndEntryBtn:FindChild("RankInfo:TrendIcon"):SetSprite(self:HelperGetTrendSprite(tEntry.nRank, tEntry.nLastRank))
	wndEntryBtn:FindChild("Prime"):SetText(tostring(tEntry.nPrimeLevel))
	wndEntryBtn:FindChild("Record"):SetText(String_GetWeaselString("$1t", tEntry.nCompletionTimeMS))
	wndEntryBtn:FindChild("Medal:MedalIcon"):SetSprite(self:HelperGetMedalSprite(tEntry.nRewardedTier))
	
	wndEntryBtn:SetData(#tEntry.tTeamMembers)
	
	if tOwnEntry.strName == tEntry.strName then
		wndEntryBtn:SetNormalTextColor("UI_BtnTextGreenNormal")
		wndEntryBtn:SetDisabledTextColor("UI_BtnTextGreenNormal")
		self.wndOwnListEntry = wndEntry
	end
	
	if next(tEntry.tTeamMembers) ~= nil then
		local wndTeamMembers = wndEntry:FindChild("Group")
		for idx, tMember in ipairs(tEntry.tTeamMembers) do
			local wndMember = Apollo.LoadForm(self.xmlDoc, "PvETeamMemberEntry", wndTeamMembers, self)
			
			local wndClassIcon = wndMember:FindChild("ClassIcon")
			wndClassIcon:SetSprite(ktClassIcons[tMember.eClass])
			wndClassIcon:SetTooltip(Apollo.GetString(ktClassTooltips[tMember.eClass]))
			
			local nLeft, nTop, nRight, nBottom = wndMember:GetAnchorPoints()
			
			if idx == 1 then
				nLeft = 0
			else
				nLeft = (idx-1) / #tEntry.tTeamMembers
			end
			
			if idx == #tEntry.tTeamMembers then
				nRight = 1
			else
				nRight = idx / #tEntry.tTeamMembers
			end
			
			wndMember:SetAnchorPoints(nLeft, nTop, nRight, nBottom)
			
			
			local wndMemberName = wndMember:FindChild("MemberName")
			wndMemberName:SetTextColor(ktClassColors[tMember.eClass])
			
			local nTextWidth = Apollo.GetTextWidth(wndMemberName:GetFont(), tMember.strName) + 1
			if nTextWidth < wndMemberName:GetWidth() then
				wndMemberName:SetText(tMember.strName)
			else
				wndMemberName:SetText(string.sub(tMember.strName, 1, -4) .. "...")
				wndMemberName:SetTooltip(tMember.strName)
			end
			
		end
	end
end

function Leaderboards:BuildPvELeaderboard(eLeaderboardType, eMatchingMap, nPrimeLevel, eMedal)
	if self.wndMain == nil or not self.wndMain:IsValid() then
		return
	end
	
	self.eLeaderboardSelected = eLeaderboardType
	self.eMatchingMap = eMatchingMap
	self.nPrimeLevel = nPrimeLevel
	self.eMedal = eMedal
	
	local tLeaderboard = LeaderboardLib.GetLeaderboard(self.eLeaderboardSelected, self.eMatchingMap, self.nPrimeLevel, self.eMedal)
	if not tLeaderboard then
		return
	end
	
	self:OnRefreshTimer()
	
	self.timerRefresh:Set(1.0, true)
	self.timerRefresh:Start()
	
	self.wndMain:FindChild("Frame:PvEFrame:LoadingBlocker"):Show(not tLeaderboard.bReady)
	if not tLeaderboard.bReady then
		return
	end
	
	local wndContainer = self.wndMain:FindChild("Frame:PvEFrame:ScrollContainer:Content")
	wndContainer:DestroyChildren()
	
	for idx, tEntry in pairs(tLeaderboard.tEntries) do
		self:BuildPvETeamEntry(tEntry, tLeaderboard.tOwnEntry)
	end
	
	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
		return wndLeft:FindChild("TeamEntryBtn:RankInfo:Ranking"):GetData() < wndRight:FindChild("TeamEntryBtn:RankInfo:Ranking"):GetData()
	end)
	
	local wndOwnEntry = self.wndMain:FindChild("Frame:PvEFrame:OwnTeam")
	wndOwnEntry:FindChild("Group"):DestroyChildren()
	
	if tLeaderboard.tOwnEntry.nRank > 0 then
		wndOwnEntry:FindChild("OwnRank"):Enable(true)
		wndOwnEntry:FindChild("OwnRank:RankInfo:TrendIcon"):SetSprite(self:HelperGetTrendSprite(tLeaderboard.tOwnEntry.nRank, tLeaderboard.tOwnEntry.nLastRank))
		wndOwnEntry:FindChild("OwnRank:RankInfo:Ranking"):SetText(tLeaderboard.tOwnEntry.nRank)
		wndOwnEntry:FindChild("OwnRank:Prime"):SetText(tostring(tLeaderboard.tOwnEntry.nPrimeLevel))
		wndOwnEntry:FindChild("OwnRank:Record"):SetText(String_GetWeaselString("$1t", tLeaderboard.tOwnEntry.nCompletionTimeMS))
		wndOwnEntry:FindChild("OwnRank:Medal:MedalIcon"):SetSprite(self:HelperGetMedalSprite(tLeaderboard.tOwnEntry.nRewardedTier))
	else
		wndOwnEntry:FindChild("OwnRank"):Enable(false)
		wndOwnEntry:FindChild("OwnRank:RankInfo:TrendIcon"):SetSprite(self:HelperGetTrendSprite(0, 0))
		wndOwnEntry:FindChild("OwnRank:RankInfo:Ranking"):SetText(Apollo.GetString("ErrorDialog_EmptySearch"))
		wndOwnEntry:FindChild("OwnRank:Prime"):SetText(Apollo.GetString("ErrorDialog_EmptySearch"))
		wndOwnEntry:FindChild("OwnRank:Record"):SetText(Apollo.GetString("ErrorDialog_EmptySearch"))
		wndOwnEntry:FindChild("OwnRank:Medal:MedalIcon"):SetSprite(self:HelperGetMedalSprite(0))
	end
end

function Leaderboards:OnPvETabSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.eLeaderboardSelected = self.wndMain:FindChild("Frame:PvEFrame:SubHeader:ContentFilter:Dropdown:Container"):GetRadioSelButton("Leaderboard_ContentFilter"):GetData()
	self:BuildPvELeaderboard(self.eLeaderboardSelected, self.eMatchingMap, self.nPrimeLevel, self.eMedal)
end

function Leaderboards:PvEResetContent()
	self.wndMain:FindChild("Frame:PvEFrame:SubHeader:ContentFilter"):SetText(Apollo.GetString("CRB_Dungeons"))
	self.wndMain:FindChild("Frame:PvEFrame:SubHeader:ContentFilter:Dropdown:Container"):SetRadioSel("Leaderboard_ContentFilter", 1)
	self.eLeaderboardSelected = LeaderboardLib.CodeEnumLeaderboardType.PveDungeon
end

function Leaderboards:PvEPopulateInstances(eLeaderboardSelected)
	local arMatches = {}
	if eLeaderboardSelected == LeaderboardLib.CodeEnumLeaderboardType.PveDungeon then
		arMatches = MatchMakingLib.GetMatchMakingEntries(MatchMakingLib.MatchType.PrimeLevelDungeon, true, false)
	else
		arMatches = MatchMakingLib.GetMatchMakingEntries(MatchMakingLib.MatchType.PrimeLevelExpedition, true, false)
	end

	self.wndMain:FindChild("Frame:PvEFrame:SubHeader:InstanceFilter:Dropdown:Container"):DestroyChildren()
	
	local matchFirst = nil
	for idx, matchGame in pairs(arMatches) do
		local wndEntry = Apollo.LoadForm(self.xmlDoc, "FilterBtn", self.wndMain:FindChild("Frame:PvEFrame:SubHeader:InstanceFilter:Dropdown:Container"), self)
		wndEntry:SetText(matchGame:GetInfo().strName)
		wndEntry:SetData(matchGame)
		wndEntry:SetCheck(matchFirst == nil)
		wndEntry:AddEventHandler("ButtonCheck", "OnPvELeaderboardInstanceSelected")
		
		if matchFirst == nil then
			matchFirst = matchGame
		end
	end
	
	self.eMatchingMap = matchFirst
	self.wndMain:FindChild("Frame:PvEFrame:SubHeader:InstanceFilter"):SetText(matchFirst:GetInfo().strName)
	
	local nHeightDiff = self.wndMain:FindChild("Frame:PvEFrame:SubHeader:InstanceFilter:Dropdown:Container"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop) - self.wndMain:FindChild("Frame:PvEFrame:SubHeader:InstanceFilter:Dropdown:Container"):GetHeight()
	
	local nLeft, nTop, nRight, nBottom = self.wndMain:FindChild("Frame:PvEFrame:SubHeader:InstanceFilter:Dropdown"):GetAnchorOffsets()
	self.wndMain:FindChild("Frame:PvEFrame:SubHeader:InstanceFilter:Dropdown"):SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeightDiff)
end

function Leaderboards:PvEPopulatePrime(matchGame)
	self.wndMain:FindChild("Frame:PvEFrame:SubHeader:PrimeFilter:Dropdown:Container"):DestroyChildren()
	
	local wndEntry = Apollo.LoadForm(self.xmlDoc, "FilterBtn", self.wndMain:FindChild("Frame:PvEFrame:SubHeader:PrimeFilter:Dropdown:Container"), self)
	wndEntry:SetText(Apollo.GetString("Leaderboards_PrimeAllLevels"))
	wndEntry:SetData(-1)
	wndEntry:AddEventHandler("ButtonCheck", "OnPvELeaderboardPrimeSelected")
	
	for idx = 0, matchGame:GetInfo().nMaxPrimeLevel do
		local wndEntry = Apollo.LoadForm(self.xmlDoc, "FilterBtn", self.wndMain:FindChild("Frame:PvEFrame:SubHeader:PrimeFilter:Dropdown:Container"), self)
		wndEntry:SetText(String_GetWeaselString(Apollo.GetString("Leaderboards_PrimeLevel"), idx))
		wndEntry:SetData(idx)
		wndEntry:AddEventHandler("ButtonCheck", "OnPvELeaderboardPrimeSelected")
	end
	
	self.nPrimeLevel = -1
	self.wndMain:FindChild("Frame:PvEFrame:SubHeader:PrimeFilter"):SetText(Apollo.GetString("Leaderboards_PrimeAllLevels"))
	wndEntry:SetCheck(true)
	
	local nOldHeight = self.wndMain:FindChild("Frame:PvEFrame:SubHeader:PrimeFilter:Dropdown:Container"):GetHeight()
	local nHeight = self.wndMain:FindChild("Frame:PvEFrame:SubHeader:PrimeFilter:Dropdown:Container"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nHeightDiff = math.min(nHeight, self.wndMain:FindChild("Frame:PvEFrame:ScrollContainer"):GetHeight()) - nOldHeight
	
	local nLeft, nTop, nRight, nBottom = self.wndMain:FindChild("Frame:PvEFrame:SubHeader:PrimeFilter:Dropdown"):GetAnchorOffsets()
	self.wndMain:FindChild("Frame:PvEFrame:SubHeader:PrimeFilter:Dropdown"):SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeightDiff)
end

function Leaderboards:PvEResetMedals()
	self.wndMain:FindChild("Frame:PvEFrame:SubHeader:MedalsFilter"):SetText(Apollo.GetString("Leaderboards_AllMedals"))
	self.wndMain:FindChild("Frame:PvEFrame:SubHeader:MedalsFilter:Dropdown:Container"):SetRadioSel("Leaderboard_ContentFilter", 1)
	self.eMedal = 0
end

function Leaderboards:OnPvELeaderboardTypeSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local eLeaderboardSelected = wndHandler:GetData()
	
	local arMatches = {}
	if eLeaderboardSelected == LeaderboardLib.CodeEnumLeaderboardType.PveDungeon then
		arMatches = MatchMakingLib.GetMatchMakingEntries(MatchMakingLib.MatchType.PrimeLevelDungeon, true, true)
	else
		arMatches = MatchMakingLib.GetMatchMakingEntries(MatchMakingLib.MatchType.PrimeLevelExpedition, true, true)
	end
	
	self:PvEPopulateInstances(eLeaderboardSelected)
	self:PvEPopulatePrime(arMatches[1])
	self:PvEResetMedals()
	
	self:BuildPvELeaderboard(eLeaderboardSelected, arMatches[1], -1, PublicEvent.PublicEventRewardTier_None)
end

function Leaderboards:OnPvELeaderboardInstanceSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local matchGame = wndHandler:GetData()

	self:PvEPopulatePrime(matchGame)
	self:PvEResetMedals()

	self:BuildPvELeaderboard(self.eLeaderboardSelected, matchGame, -1, PublicEvent.PublicEventRewardTier_None)
end

function Leaderboards:OnPvELeaderboardPrimeSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:BuildPvELeaderboard(self.eLeaderboardSelected, self.eMatchingMap, wndHandler:GetData(), self.eMedal)
end

function Leaderboards:OnPvELeaderboardMedalSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:BuildPvELeaderboard(self.eLeaderboardSelected, self.eMatchingMap, self.nPrimeLevel, wndHandler:GetData())
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

function Leaderboards:OnFilterSelection(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndFilter = wndControl:GetParent():GetParent():GetParent()
	wndFilter:SetText(wndControl:GetText())
	wndFilter:SetCheck(false)
end

function Leaderboards:OnCloseFlyout(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	return true
end

-----------------------------------------------------------------------------------------------
-- Leaderboards Instance
-----------------------------------------------------------------------------------------------
local LeaderboardsInst = Leaderboards:new()
LeaderboardsInst:Init()
