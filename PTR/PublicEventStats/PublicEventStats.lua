-----------------------------------------------------------------------------------------------
-- Client Lua Script for PublicEventStats
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "PublicEvent"
require "MatchingGameLib"

local PublicEventStats = {}

function PublicEventStats:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function PublicEventStats:Init()
    Apollo.RegisterAddon(self)
end

local kstrClassToMLIcon =
{
	[GameLib.CodeEnumClass.Warrior] 		= "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Warrior\"></T> ",
	[GameLib.CodeEnumClass.Engineer] 		= "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Engineer\"></T> ",
	[GameLib.CodeEnumClass.Esper] 			= "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Esper\"></T> ",
	[GameLib.CodeEnumClass.Medic] 			= "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Medic\"></T> ",
	[GameLib.CodeEnumClass.Stalker] 		= "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Stalker\"></T> ",
	[GameLib.CodeEnumClass.Spellslinger] 	= "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Spellslinger\"></T> ",
}

local ktPvPEvents =
{
	[PublicEvent.PublicEventType_PVP_Arena] 					= true,
	[PublicEvent.PublicEventType_PVP_Warplot] 					= true,
	[PublicEvent.PublicEventType_PVP_Battleground_Vortex] 		= true,
	[PublicEvent.PublicEventType_PVP_Battleground_Cannon] 		= true,
	[PublicEvent.PublicEventType_PVP_Battleground_Sabotage]		= true,
	[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine] 	= true,
}

local ktPvEInstancedEvents =
{
	[PublicEvent.PublicEventType_Adventure_Astrovoid] 		= true,
	[PublicEvent.PublicEventType_Adventure_Farside] 		= true,
	[PublicEvent.PublicEventType_Adventure_Galeras] 		= true,
	[PublicEvent.PublicEventType_Adventure_Hycrest]			= true,
	[PublicEvent.PublicEventType_Adventure_LevianBay] 		= true,
	[PublicEvent.PublicEventType_Adventure_Malgrave] 		= true,
	[PublicEvent.PublicEventType_Adventure_NorthernWilds] 	= true,
	[PublicEvent.PublicEventType_Adventure_Skywatch] 		= true,
	[PublicEvent.PublicEventType_Adventure_Whitevale] 		= true,
	[PublicEvent.PublicEventType_Dungeon] 					= true,
	[PublicEvent.PublicEventType_Shiphand]					= true,
}

local knColWidthForName = 300
local knColWidthOffSet 	= 30

local ktAttributeToColumn =
{
	["nAssists"] 				= Apollo.GetString("PublicEventStats_Assists"),
	["nContributions"] 			= Apollo.GetString("PublicEventStats_Contribution"),
	["nDamage"] 				= Apollo.GetString("PublicEventStats_DamageDone"),
	["nDamageReceived"] 		= Apollo.GetString("PublicEventStats_DamageTaken"),
	["nDeaths"] 				= Apollo.GetString("PublicEventStats_Deaths"),
	["nHaters"] 				= Apollo.GetString("PublicEventStats_Haters"),
	["nHealed"] 				= Apollo.GetString("PublicEventStats_HealingDone"),
	["nHealingReceived"] 		= Apollo.GetString("PublicEventStats_HealingTaken"),
	["nHits"] 					= Apollo.GetString("PublicEventStats_Hits"),
	["nKills"] 					= Apollo.GetString("PublicEventStats_Kills"),
	["nKillStreak"] 			= Apollo.GetString("PublicEventStats_KillStreak"),
	["nLongestImpulse"] 		= Apollo.GetString("PublicEventStats_LongestImpulse"),
	["nLongestLife"] 			= Apollo.GetString("PublicEventStats_LongestLife"),
	["nMaxMultiKills"] 			= Apollo.GetString("PublicEventStats_MaxMultiKills"),
	["nMedalPoints"] 			= Apollo.GetString("PublicEventStats_MedalPoints"),
	["strName"] 				= Apollo.GetString("PublicEventStats_Name"),
	["strTeamName"] 			= Apollo.GetString("PublicEventStats_TeamName"),
	["nOverhealed"] 			= Apollo.GetString("PublicEventStats_Overhealed"),
	["nOverhealingReceived"]	= Apollo.GetString("PublicEventStats_OverhealingReceived"),
	["nSaves"] 					= Apollo.GetString("PublicEventStats_Saves"),
}

local ktAdventureListStrIndexToIconSprite =  -- Default: ClientSprites:Icon_SkillMind_UI_espr_moverb
{
	["nKills"] 		= "IconSprites:Icon_BuffDebuff_Assault_Power_Buff",
	["nDeaths"] 	= "IconSprites:Icon_BuffWarplots_deployable",
	["nDamage"] 	= "IconSprites:Icon_BuffWarplots_strikethrough",
	["nHealed"] 	= "IconSprites:Icon_BuffDebuff_Support_Power_Buff",
}

local ktRewardTierInfo =
{
	[PublicEvent.PublicEventRewardTier_None] 	= {strText = Apollo.GetString("PublicEventStats_NoMedal"), 		strSprite = "CRB_ChallengeTrackerSprites:sprChallengeTierRed"},
	[PublicEvent.PublicEventRewardTier_Bronze] 	= {strText = Apollo.GetString("PublicEventStats_BronzeMedal"), 	strSprite = "CRB_ChallengeTrackerSprites:sprChallengeTierBronze"},
	[PublicEvent.PublicEventRewardTier_Silver] 	= {strText = Apollo.GetString("PublicEventStats_SilverMedal"), 	strSprite = "CRB_ChallengeTrackerSprites:sprChallengeTierSilver"},
	[PublicEvent.PublicEventRewardTier_Gold] 	= {strText = Apollo.GetString("PublicEventStats_GoldMedal"), 	strSprite = "CRB_ChallengeTrackerSprites:sprChallengeTierGold"},
}

local karRandomFailStrings =
{
	"PublicEventStats_RandomNoPassFlavor_1",
	"PublicEventStats_RandomNoPassFlavor_2",
	"PublicEventStats_RandomNoPassFlavor_3",
}

local karRandomPassStrings =
{
	"PublicEventStats_RandomNoFailFlavor_1",
	"PublicEventStats_RandomNoFailFlavor_2",
	"PublicEventStats_RandomNoFailFlavor_3",
}

local knXCursorOffset = 10
local knYCursorOffset = 25
local kstrDungeonGoldIcon = "<T Image=\"sprChallengeTierGold\"></T><T TextColor=\"0\">.</T>"
local kstrDungeonBronzeIcon = "<T Image=\"sprChallengeTierBronze\"></T><T TextColor=\"0\">.</T>"

function PublicEventStats:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("PublicEventStats.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function PublicEventStats:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	math.randomseed(os.time())

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()

    Apollo.RegisterEventHandler("GenericEvent_OpenEventStats", 			"OnToggleEventStats", self)
    Apollo.RegisterEventHandler("GenericEvent_OpenEventStatsZombie", 	"InitializeZombie", self)
	Apollo.RegisterEventHandler("ResolutionChanged", 					"OnResolutionChanged", self)
	Apollo.RegisterEventHandler("WarPartyMatchResults", 				"OnWarPartyMatchResults", self)
	Apollo.RegisterEventHandler("PVPMatchFinished", 					"OnPVPMatchFinished", self)
	Apollo.RegisterEventHandler("PublicEventStart",						"OnPublicEventStart", self)
	Apollo.RegisterEventHandler("PublicEventEnd", 						"OnPublicEventEnd", self)
	Apollo.RegisterEventHandler("PublicEventLeave", 					"OnPublicEventLeave", self)
	Apollo.RegisterEventHandler("ChangeWorld", 							"OnChangeWorld", self)
	Apollo.RegisterEventHandler("GuildWarCoinsChanged",					"OnGuildWarCoinsChanged", self)
	Apollo.RegisterEventHandler("PublicEventLiveStatsUpdate",			"OnLiveStatsUpdate", self)

	self.wndScoreboard = nil
	self.wndAdventure = nil
	self.wndDungeonMedalsForm = nil
	self.wndPvPContextMenu = nil
	
	self.tTrackedStats = nil
	self.tZombieStats = nil
	self.peActiveEvent = nil
	self.arTeamNames = {}
	self.tWarplotResults  = {}
	
	self.timerRedrawInfo = ApolloTimer.Create(1.0, true, "UpdateGrid", self)
	self.timerRedrawInfo:Stop()

	local tActiveEvents = PublicEvent.GetActiveEvents()
	for idx, peEvent in pairs(tActiveEvents) do
		self:OnPublicEventStart(peEvent)
	end
end

function PublicEventStats:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("Tutorials_PublicEvents"), nSaveVersion = 2})
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("MatchMaker_Adventures")})
end

------------------------------------------------------------------------------------
-----    Live Stat Scoreboards
------------------------------------------------------------------------------------
function PublicEventStats:OnToggleEventStats(peEvent, tMyStats, arTeamStats, arParticipantStats)
	if self.wndScoreboard and self.wndScoreboard:IsShown() then
		self.timerRedrawInfo:Stop()
		self.wndScoreboard:Close()
	else
		self.tTrackedStats = peEvent:GetLiveStats()
		
		if not self.wndScoreboard then
			self:InitializeScoreboard(peEvent)
		end
		self.timerRedrawInfo:Start()
		
		-- Allow the PublicEventLiveStatsUpdate to fire
		peEvent:RequestScoreboard(true)
		self:UpdateGrid()
		self.wndScoreboard:Invoke()
	end
end

function PublicEventStats:OnPublicEventStart(peEvent)
	-- Clear any stats we were holding onto
	self.tZombieStats = nil
	
	-- If it doesn't have live stats (PvE instances), we don't need to track it in real time
	if peEvent:HasLiveStats() then
		self.tTrackedStats = peEvent:GetLiveStats()
		self.peActiveEvent = peEvent
		
		peEvent:RequestScoreboard(true)
		if not self.wndScoreboard then
			self:InitializeScoreboard(peEvent)
		end
	end
end

function PublicEventStats:DrawCustomEvents(tStats, peEvent)
	local tPersonalStats = peEvent:GetMyStats()
	local tScore = {}
	local tIcons = {}
	-- Add Custom to score tracker
	for idx, tStat in pairs(tPersonalStats.arCustomStats) do
		if tStat.nValue and tStat.nValue > 0 then
			tScore[tStat.strName] = 0
			tIcons[tStat.strName] = tStat.strIcon
			tPersonalStats[tStat.strName] = tStat.nValue
		end
	end

	-- Count times beaten by other participants
	for key, tCurr in pairs(tStats.arParticipantStats) do
		tScore = self:HelperCompareScores(tPersonalStats, tCurr, tScore)
	end

	-- Convert to an interim table for sorting
	local bHaveCustomStats = false
	local wndRight = self.wndScoreboard:FindChild("Right")
	local wndCustomStatContainer = wndRight:FindChild("Container")

	local tSortedTable = self:HelperSortTableForSummary(tScore)
	for key, tData in pairs(tSortedTable) do
		local strIndex = tData.strKey
		local nValue = tData.nValue
		local nValueForString = math.abs(0 - nValue) + 1
		if nValueForString > 0 and tPersonalStats[strIndex] ~= nil and tPersonalStats[strIndex] > 0 then
			local strLabelText = String_GetWeaselString(Apollo.GetString("PublicEventStats_AwardOther"), nValueForString, strIndex)
			local wndListItem = Apollo.LoadForm(self.xmlDoc , "CustomStatListItem", wndCustomStatContainer, self)
			wndListItem:FindChild("Icon"):SetSprite(tIcons[strIndex])
			wndListItem:FindChild("Title"):SetText(strLabelText)
			bHaveCustomStats = true
		end
	end

	if bHaveCustomStats then
		wndCustomStatContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	end
	wndRight:FindChild("CustomStatsBtn"):Show(bHaveCustomStats)
	wndRight:Show(bHaveCustomStats)
end

function PublicEventStats:InitializeScoreboard(peEvent)
	local tStats = self.tTrackedStats or self.tZombieStats or peEvent:GetLiveStats()
	
	-- We won't get far without stats to draw
	if not tStats or not tStats.arParticipantStats or #tStats.arParticipantStats == 0 then
		return
	end
	
	if not self.wndScoreboard or not self.wndScoreboard:IsValid() then
		self.wndScoreboard = Apollo.LoadForm(self.xmlDoc , "PublicEventStatsForm", nil, self)
		Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndScoreboard, strName = Apollo.GetString("Tutorials_PublicEvents")})
	end

	local eEventType = peEvent:GetEventType()
	if eEventType == PublicEvent.PublicEventType_NonCombatEvent then
		self:DrawCustomEvents(tStats, peEvent)
	end

	self.wndScoreboard:FindChild("CustomStatsBtn"):AttachWindow(self.wndScoreboard:FindChild("CustomStats"))
	
	-- Primarily for when the timer is fired
	if not peEvent and self.peActiveEvent then
		peEvent = self.tZombieStats and self.tZombieStats.peEvent or self.peActiveEvent
	else
		self.peActiveEvent = peEvent
	end

	local wndParent	= nil
	local wndGrid = nil
	if not ktPvPEvents[eEventType] then
		wndParent = self.wndScoreboard:FindChild("NonCombatContainer")
		wndGrid = wndParent:FindChild("DynGrid")
		self:InitializeGrid(wndGrid)
	else
		wndParent = self.wndScoreboard:FindChild("PvPArenaContainer")
		local wndGridTop = wndParent:FindChild("PvPTeamGridTop")
		local wndPvPTeamGridBot = wndParent:FindChild("PvPTeamGridBot")
		local wndHeaderTop 	= wndParent:FindChild("PvPTeamHeaderTop")
		local wndHeaderBot 	= wndParent:FindChild("PvPTeamHeaderBot")

		--Need a grid reference for measuring later.
		wndGrid = wndGridTop

		self:InitializeGrid(wndGridTop)
		self:InitializeGrid(wndPvPTeamGridBot)
		
		local tMatchState = MatchingGameLib.GetPvpMatchState()

		for key, tCurr in pairs(tStats.arTeamStats) do
			local wndHeader = nil
			if not wndHeaderTop:GetData() or tCurr.strTeamName == wndHeaderTop:GetData() then
				wndHeaderTop:SetData(tCurr.strTeamName)
				wndHeader = wndHeaderTop
			elseif not wndHeaderBot:GetData() or tCurr.strTeamName == wndHeaderBot:GetData() then
				wndHeaderBot:SetData(tCurr.strTeamName)
				wndHeader = wndHeaderBot
			end
			
			if wndHeader then
				self:CheckTeamName(key, wndHeader, tStats, tMatchState)
			end
		end
	end

	local nMaxScoreboardWidth = self.wndScoreboard:GetWidth() - wndGrid:GetWidth() + 15 -- Magic number for the width of the scroll bar
	for idx = 1, wndGrid:GetColumnCount() do
		nMaxScoreboardWidth = nMaxScoreboardWidth + wndGrid:GetColumnWidth(idx)
	end

	self.wndScoreboard:SetSizingMinimum(640, 500)
	self.wndScoreboard:SetSizingMaximum(nMaxScoreboardWidth, 800)

	self.strMyName = GameLib.GetPlayerUnit():GetName()
	
	if tStats.eRewardTier and ktRewardTierInfo[tStats.eRewardTier] and tStats.eRewardType and not ktPvPEvents[eEventType] then
		self.wndScoreboard:FindChild("BGRewardTierIcon"):SetSprite(ktRewardTierInfo[tStats.eRewardTier].strSprite)
		self.wndScoreboard:FindChild("BGRewardTierFrame"):SetText(ktRewardTierInfo[tStats.eRewardTier].strText)
	else
		self.wndScoreboard:FindChild("BGRewardTierIcon"):SetSprite("")
		self.wndScoreboard:FindChild("BGRewardTierFrame"):SetText("")
	end

	self.wndScoreboard:Show(false)
end

function PublicEventStats:InitializeGrid(wndGrid)
	if not wndGrid then
		return
	end

	wndGrid:DeleteAllRowsAndColumns()
	local tColumnNames = self:HelperGetColumnNames()
	for idx, strColumn in pairs(tColumnNames) do
		local nColWidth = 0
		if idx == 1 then--This is the name column.
			nColWidth = knColWidthForName
		else
			nColWidth = Apollo.GetTextWidth("CRB_InterfaceSmall", strColumn) + knColWidthOffSet
		end

		wndGrid:AddCol(strColumn, nil, nColWidth, "UI_TextHoloBody")
	end
end

function PublicEventStats:HelperGetAttributes()
	local tAttributes = {"strName"}--GetStatsToDisplay does NOT have names because ALL should begin with name.

	if not self.peActiveEvent then
		return tAttributes
	end

	local eEventType = self.peActiveEvent:GetEventType()
	if ktPvPEvents[eEventType] then
		table.insert(tAttributes, "strTeamName")
	end


	local tDisplay = self.peActiveEvent:GetStatsToDisplay()
	if not tDisplay then
		return tAttributes
	end

	for idx, strAttribute in pairs(tDisplay) do
		table.insert(tAttributes, strAttribute)
	end

	local tParticipant = self.peActiveEvent:GetMyStats()
	if not tParticipant then
		return tAttributes
	end

	--Adding Custom Stats
	for idx, tCustomTable in pairs(tParticipant.arCustomStats) do
		table.insert(tAttributes, tCustomTable.strName)
	end

	return tAttributes
end

function PublicEventStats:HelperGetColumnNames()
	local tColumnNames = {}
	local tAttributes = self:HelperGetAttributes()
	for idx, strAttribute in pairs(tAttributes) do
		local strColumnName = ktAttributeToColumn[strAttribute]
		if strColumnName then
			table.insert(tColumnNames, strColumnName)
		else--Custom Stats, and are already Localized.
			table.insert(tColumnNames, strAttribute)
		end
	end
	
	return tColumnNames
end

-- Fires from the quest tracker's PublicEvent Tracker
function PublicEventStats:InitializeZombie(tZombieEvent)
	self.tZombieStats = tZombieEvent.tStats
	self:InitializeScoreboard(tZombieEvent.peEvent)
	self:UpdateGrid()
	self.wndScoreboard:Invoke()
end

function PublicEventStats:UpdateGrid() -- self.wndScoreboard guaranteed valid and visible
	if self.wndScoreboard then
		for key, wndCurr in pairs(self.wndScoreboard:FindChild("MainGridContainer"):GetChildren()) do
			wndCurr:Show(false)
		end

		local wndParent	= nil
		local wndNonCombatContainer = self.wndScoreboard:FindChild("NonCombatContainer")
		local wndPvPArenaContainer = self.wndScoreboard:FindChild("PvPArenaContainer")
		local eEventType = self.peActiveEvent:GetEventType()
		local bCombatEvent = ktPvPEvents[eEventType]
		if bCombatEvent then
			self:HelperBuildPvPSharedGrids(wndPvPArenaContainer, eEventType)
		else
			self:BuildPublicEventGrid(wndNonCombatContainer)
		end

		-- Title Text (including timer)
		local strTitleText = ""
		if self.peActiveEvent:IsActive() and self.peActiveEvent:GetElapsedTime() then
			strTitleText = String_GetWeaselString(Apollo.GetString("PublicEventStats_TimerHeader"), self.peActiveEvent:GetName(), self:HelperConvertTimeToString(self.peActiveEvent:GetElapsedTime()))
		elseif self.tZombieStats and self.tZombieStats.nElapsedTime then
			strTitleText = String_GetWeaselString(Apollo.GetString("PublicEventStats_FinishTime"), self.peActiveEvent:GetName(), self:HelperConvertTimeToString(self.tZombieStats.nElapsedTime))
		end
		self.wndScoreboard:FindChild("EventTitleText"):SetText(strTitleText)

		wndNonCombatContainer:Show(not bCombatEvent)
		wndPvPArenaContainer:Show(bCombatEvent)
	end
end

function PublicEventStats:OnLiveStatsUpdate(peEvent)
	if peEvent and peEvent:IsActive() then
		self.tTrackedStats = peEvent:GetLiveStats()
	end
	
	-- Changing the resolution
	if self.bResolutionChanged and self.wndScoreboard then
		self.bResolutionChanged = false
		local nLeft, nTop, nRight, nBottom = self.wndScoreboard:GetAnchorOffsets()
		if Apollo.GetDisplaySize().nWidth <= 1400 then
			self.wndScoreboard:SetAnchorOffsets(nLeft, nTop, nLeft + 650, nBottom)
		else
			self.wndScoreboard:SetAnchorOffsets(nLeft, nTop, nLeft + 800, nBottom)
		end
	end
end

------------------------------------------------------------------------------------
-----    PvP Specific Functions
------------------------------------------------------------------------------------

function PublicEventStats:CheckTeamName(eMatchTeam, wndHeader, tLiveStats, tMatchState)
	local crTitleColor = ApolloColor.new("ff7fffb9")
	local strTeamName = (tMatchState and tMatchState.arTeams and tMatchState.arTeams[eMatchTeam] and tMatchState.arTeams[eMatchTeam].strName) or (tLiveStats and tLiveStats.arTeamStats and tLiveStats.arTeamStats[eMatchTeam] and tLiveStats.arTeamStats[eMatchTeam].strTeamName) or ""
	self.arTeamNames[eMatchTeam] = strTeamName
	
	wndHeader:FindChild("PvPHeaderTitle"):SetTextColor(crTitleColor)
	wndHeader:FindChild("PvPHeaderTitle"):SetText(strTeamName)
end

function PublicEventStats:HelperBuildPvPSharedGrids(wndParent, eEventType)
	-- If we're storing stats, use those instead
	if self.tZombieStats then
		self.tTrackedStats = self.tZombieStats
	end
	
	-- If we don't have any tracked stats or invalid tracked stats, bail.
	if not self.tTrackedStats or not self.tTrackedStats.arTeamStats or not self.tTrackedStats.arParticipantStats then
		return
	end

	-- Get some windows.
	local wndGridTop 	= wndParent:FindChild("PvPTeamGridTop")
	local wndGridBot 	= wndParent:FindChild("PvPTeamGridBot")
	local wndHeaderTop 	= wndParent:FindChild("PvPTeamHeaderTop")
	local wndHeaderBot 	= wndParent:FindChild("PvPTeamHeaderBot")

	-- Get some variables
	local nVScrollPosTop 	= wndGridTop:GetVScrollPos()
	local nVScrollPosBot 	= wndGridBot:GetVScrollPos()
	local nSortedColumnTop 	= wndGridTop:GetSortColumn() or 1
	local nSortedColumnBot 	= wndGridBot:GetSortColumn() or 1
	local bAscendingTop 	= wndGridTop:IsSortAscending()
	local bAscendingBot 	= wndGridBot:IsSortAscending()

	-- Clear the grids to redraw them
	wndGridTop:DeleteAll()
	wndGridBot:DeleteAll()

	-- Get the info for the match
	local tMatchState = MatchingGameLib.GetPvpMatchState()
	local wndHeader = nil
	
	for idx, tCurr in pairs(self.tTrackedStats.arTeamStats) do
		if tCurr.strTeamName == wndHeaderTop:GetData() then
			wndHeader = wndHeaderTop
		elseif tCurr.strTeamName == wndHeaderBot:GetData() then
			wndHeader = wndHeaderBot
		end
		
		if wndHeader then
			-- ... and set up the header.
			local strHeaderText = self.arTeamNames[key] or ""
			local strDamage	= String_GetWeaselString(Apollo.GetString("PublicEventStats_Damage"), Apollo.FormatNumber(tCurr.nDamage, 0, true))
			local strHealed	= String_GetWeaselString(Apollo.GetString("PublicEventStats_Healing"), Apollo.FormatNumber(tCurr.nHealed, 0, true))
			
			if tCurr.bIsMyTeam then
				self.strMyPublicEventTeam = tCurr.strTeamName
			end

			-- Setting up the team names / headers
			if eEventType == PublicEvent.PublicEventType_PVP_Battleground_Vortex or eEventType == PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine or eEventType == PublicEvent.PublicEventType_PVP_Battleground_Sabotage then
				local strKDA = String_GetWeaselString(Apollo.GetString("PublicEventStats_KDA"), tCurr.nKills, tCurr.nDeaths, tCurr.nAssists)
				strHeaderText = String_GetWeaselString(Apollo.GetString("PublicEventStats_PvPHeader"), strKDA, strDamage, strHealed)
			elseif eEventType == PublicEvent.PublicEventType_PVP_Arena then
				strHeaderText = String_GetWeaselString(Apollo.GetString("PublicEventStats_ArenaHeader"), strDamage, strHealed) -- TODO, Rating Change when support is added
			elseif eEventType == PublicEvent.PublicEventType_PVP_Warplot then
				if self.tWarplotResults and self.tWarplotResults[key] then
					strHeaderText = String_GetWeaselString(Apollo.GetString("PEStats_WarPartyTeamStats"), self.tWarplotResults[key].nRating, self.tWarplotResults[key].nDestroyedPlugs, self.tWarplotResults[key].nRepairCost, self.tWarplotResults[key].nWarCoinsEarned)
				else
					strHeaderText = ""
				end
			end

			wndHeader:FindChild("PvPHeaderText"):SetText(strHeaderText)
		end
	end

	local tAttributes = self:HelperGetAttributes()
	-- For each player ...
	for key, tParticipant in pairs(self.tTrackedStats.arParticipantStats) do
		
		--Special Adding Of Custom Stats.
		local tCurCustomStats = {}
		for idx, tCustomTable in pairs(tParticipant.arCustomStats) do
			tCurCustomStats[tCustomTable.strName] = tCustomTable.nValue or 0
		end

		-- ... figure out which window their team is on, ...
		local wndGrid = nil
		if tParticipant.strTeamName == wndHeaderTop:GetData() then
			wndGrid = wndGridTop
		elseif tParticipant.strTeamName == wndHeaderBot:GetData() then
			wndGrid = wndGridBot
		end

		-- Custom Stats
		if wndGrid then
			-- ... set up Player Reporting, ...
			local rptInfraction = tParticipant.rptParticipant
			if not rptInfraction then
				rptInfraction = self.peActiveEvent:PrepareInfractionReport(key)
			end

			local nCurrRow = self:HelperGridFactoryProduce(wndGrid, tParticipant.strName) -- GOTCHA: This is an integer
			for idx, strAttribute in pairs(tAttributes) do
				local oValue = tParticipant[strAttribute]
				if not oValue then--Check for custom stats!
					oValue = tCurCustomStats[strAttribute]
				end

				if oValue ~= nil then--Make sure it was set, either standard or custom stat.
					local strAppend = ""

					local strClassIcon = ""
					if idx == 1 and kstrClassToMLIcon[tParticipant.eClass] then
						strClassIcon = kstrClassToMLIcon[tParticipant.eClass]
					end

					local strFont = ""
					if type(oValue) == "number" then
						wndGrid:SetCellSortText(nCurrRow, idx, string.format("%8d", oValue))
						strAppend = Apollo.FormatNumber(oValue)
						strFont = "CRB_Header10"
					elseif type(oValue) == "string" then
						wndGrid:SetCellSortText(nCurrRow, idx, oValue or "")
						strAppend = oValue
						strFont = "CRB_InterfaceSmall"
					end
					wndGrid:SetCellDoc(nCurrRow, idx, string.format("<T Font='%s'>%s%s</T>", strFont, strClassIcon, strAppend))
				end
			end
		end
	end

	-- Reset scroll and sort info
	wndGridTop:SetVScrollPos(nVScrollPosTop)
	wndGridBot:SetVScrollPos(nVScrollPosBot)
	wndGridTop:SetSortColumn(nSortedColumnTop, bAscendingTop)
	wndGridBot:SetSortColumn(nSortedColumnBot, bAscendingBot)
	self.wndScoreboard:FindChild("PvPLeaveMatchBtn"):Show(self.tZombieStats or (tMatchState and tMatchState.eState == MatchingGameLib.PVPGameState.Finished))
	self.wndScoreboard:FindChild("PvPSurrenderMatchBtn"):Show(not self.tZombieStats and eEventType == "WarPlot")
end

function PublicEventStats:OnPvPGridClick(wndHandler, wndControl, iRow, iCol, eMouseButton)
	local strName = wndHandler:GetCellData(iRow, 1)
	local rptParticipant = wndHandler:GetCellData(iRow, 2)
	
	-- If you right click on another player ... 
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and strName and strName ~= self.strMyName then
		-- ... close any existing context menu, ...
		self:OnContextMenuPlayerClosed()

		-- ... open a new context menu, ...
		self.wndPvPContextMenu = Apollo.LoadForm(self.xmlDoc, "ContextMenuPlayerForm", "TooltipStratum", self)
		self.wndPvPContextMenu:FindChild("BtnReportPlayer"):Show(false)
		self.wndPvPContextMenu:FindChild("BtnAddRival"):SetData(strName)
		self.wndPvPContextMenu:Invoke()

		-- ... and move it into place.
		local nHeight = self.wndPvPContextMenu:FindChild("ButtonList"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		local nLeft, nTop, nRight, nBottom = self.wndPvPContextMenu:GetAnchorOffsets()
		self.wndPvPContextMenu:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + 60)

		local tCursor = Apollo.GetMouse()
		self.wndPvPContextMenu:Move(tCursor.x - knXCursorOffset, tCursor.y - knYCursorOffset, self.wndPvPContextMenu:GetWidth(), self.wndPvPContextMenu:GetHeight())
	end
end

-----------------------------------------------------------------------------------------------
-----    Context Menu Functions
-----------------------------------------------------------------------------------------------

-- Why does this even have its own special edge case context menu?
function PublicEventStats:OnContextMenuAddRival(wndHandler, wndControl)
	local strTarget = wndHandler:GetData()
	FriendshipLib.AddByName(FriendshipLib.CharacterFriendshipType_Rival, strTarget)
	Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("Social_AddedToRivals"), strTarget))
	self:OnContextMenuPlayerClosed()
end

function PublicEventStats:OnContextMenuReportPlayer(wndHandler, wndControl)
	local rptParticipant = wndHandler:GetData()
	Event_FireGenericEvent("GenericEvent_ReportPlayerPvP", rptParticipant)
	self:OnContextMenuPlayerClosed()
end

function PublicEventStats:OnContextMenuPlayerClosed(wndHandler, wndControl)
	if self.wndPvPContextMenu and self.wndPvPContextMenu:IsValid() then
		self.wndPvPContextMenu:Destroy()
		self.wndPvPContextMenu = nil
	end
end

-----------------------------------------------------------------------------------------------
-----    Public Event Specific Functions
-----------------------------------------------------------------------------------------------

function PublicEventStats:BuildPublicEventGrid(wndParent)
	-- Save scroll info
	local wndGrid = wndParent:FindChild("DynGrid")
	local nVScrollPos = wndGrid:GetVScrollPos()
	local nSortedColumn = wndGrid:GetSortColumn() or 1
	local bAscending = wndGrid:IsSortAscending()
	local tStats = self.tTrackedStats or self.tZombieStats
	 -- TODO remove this for better performance eventually
	wndGrid:DeleteAll()
	
	-- If we don't have stats, close the window.
	if not tStats then
		self.wndScoreboard:Close()
	end

	local tAttributes = self:HelperGetAttributes()
	for strKey, tParticipant in pairs(tStats.arParticipantStats) do
		--Special Adding Of Custom Stats.
		local tCurCustomStats = {}
		for idx, tCustomTable in pairs(tParticipant.arCustomStats) do
			tCurCustomStats[tCustomTable.strName] = tCustomTable.nValue or 0
		end

		local nCurrRow = self:HelperGridFactoryProduce(wndGrid, tParticipant.strName) -- GOTCHA: This is an integer
		-- index is the column that the value will be applied to
		for idx, strAttribute in pairs(tAttributes) do
			local oValue = tParticipant[strAttribute]
			if not oValue then--Check for custom stats!
				oValue = tCurCustomStats[strAttribute]
			end

			if oValue ~= nil then--Make sure it was set, either standard or custom stat.
				local strFont = ""
				if type(oValue) == "number" then
					wndGrid:SetCellSortText(nCurrRow, idx, string.format("%8d", oValue))
					strAppend = Apollo.FormatNumber(oValue)
					strFont = "CRB_Header10"
				elseif type(oValue) == "string" then
					wndGrid:SetCellSortText(nCurrRow, idx, oValue or "")
					strAppend = oValue
					strFont = "CRB_InterfaceSmall"
				end
				wndGrid:SetCellDoc(nCurrRow, idx, string.format("<T Font='%s'>%s</T>", strFont, strAppend))
			end
		end
	end

	-- Reset the scroll and sort info
	wndGrid:SetVScrollPos(nVScrollPos)
	wndGrid:SetSortColumn(nSortedColumn, bAscending)
	self.wndScoreboard:FindChild("PvPLeaveMatchBtn"):Show(false)
	self.wndScoreboard:FindChild("PvPSurrenderMatchBtn"):Show(false)
end

-----------------------------------------------------------------------------------------------
-----    End of Match Functions
-----------------------------------------------------------------------------------------------

-- If you leave the match, stop showing who won so we can reset it for the next match.
function PublicEventStats:OnPublicEventLeave(peEnding, eReason)
	if self.wndScoreboard and self.wndScoreboard:IsValid() then
		self.wndScoreboard:FindChild("BGPvPWinnerTopBar"):Show(false)
	end
end

-- Notably not fired for warplots
function PublicEventStats:OnPVPMatchFinished(eWinner, eReason, nDeltaTeam1, nDeltaTeam2)
	-- If the window is already shown, bail.
	if not self.wndScoreboard or not self.wndScoreboard:IsValid() or not self.wndScoreboard:IsShown() then
		return
	end

	-- For every PvP event type other than warplots...
	local eEventType = self.peActiveEvent:GetEventType()
	if not ktPvPEvents[eEventType] or eEventType == PublicEvent.PublicEventType_PVP_Warplot then
		return
	end
	
	local strMessage = Apollo.GetString("PublicEventStats_MatchEnd")
	local strColor = ApolloColor.new("ff7fffb9")
	local tMatchState = MatchingGameLib.GetPvpMatchState()
	local eMyTeam = nil
	if tMatchState then
		eMyTeam = tMatchState.eMyTeam
	end

	if eWinner == MatchingGameLib.Winner.Draw then
		strMessage = Apollo.GetString("PublicEventStats_Draw")
	elseif eMyTeam == eWinner then
		strMessage = Apollo.GetString("PublicEventStats_ArenaVictory")
	else
		strMessage = Apollo.GetString("PublicEventStats_ArenaDefeat")
	end

	-- Display rating changes for Rated BGs(?), Warplots(?), and Arena Teams
	local arRatingDelta = nil
	if nDeltaTeam1 and nDeltaTeam2 then
		arRatingDelta =
		{
			nDeltaTeam1,
			nDeltaTeam2
		}
	end
	
	-- Special header formatting for arena teams
	if tMatchState and eEventType == PublicEvent.PublicEventType_PVP_Arena and tMatchState.arTeams then
		local strMyArenaTeamName = ""
		local strOtherArenaTeamName = ""
		local wndHeaderTop 	= self.wndScoreboard:FindChild("Left:MainGridContainer:PvPArenaContainer:PvPTeamHeaderTop")
		local wndHeaderBot 	= self.wndScoreboard:FindChild("Left:MainGridContainer:PvPArenaContainer:PvPTeamHeaderBot")
		for idx, tCurr in pairs(tMatchState.arTeams) do
			local strDelta = ""
			if arRatingDelta then
				if tCurr.nDelta < 0 then
					strDelta = String_GetWeaselString(Apollo.GetString("PublicEventStats_NegDelta"), math.abs(arRatingDelta[idx]))
				elseif tCurr.nDelta > 0 then
					strDelta = String_GetWeaselString(Apollo.GetString("PublicEventStats_PosDelta"), math.abs(arRatingDelta[idx]))
				end
			end
			
			local strTeamName = String_GetWeaselString(Apollo.GetString("PublicEventStats_RatingChange"), tCurr.strName or self.tLiveStats.arTeamStats[tCurr.nTeam].strTeamName, tCurr.nRating + arRatingDelta[idx], strDelta)

			if eMyTeam == tCurr.nTeam then
				strMyArenaTeamName = strTeamName
			else
				strOtherArenaTeamName = strTeamName
			end
		end

		if wndHeaderTop:GetData() == self.strMyPublicEventTeam then
			wndHeaderTop:FindChild("PvPHeaderTitle"):SetText(strMyArenaTeamName)
			wndHeaderBot:FindChild("PvPHeaderTitle"):SetText(strOtherArenaTeamName)
		else
			wndHeaderTop:FindChild("PvPHeaderTitle"):SetText(strOtherArenaTeamName)
			wndHeaderBot:FindChild("PvPHeaderTitle"):SetText(strMyArenaTeamName)
		end
	end

	-- Show the result bar
	self.wndScoreboard:FindChild("BGPvPWinnerTopBar"):Show(true) -- Hidden when wndScoreboard is destroyed from OnClose
	self.wndScoreboard:FindChild("BGPvPWinnerTopBarArtText"):SetText(strMessage)
	self.wndScoreboard:FindChild("BGPvPWinnerTopBarArtText"):SetTextColor(strColor)
end

-- Only fired for warplots
function PublicEventStats:OnWarPartyMatchResults(tWarplotResults)
	-- The event gives us all the info we need to create a decent header
	if self.wndScoreboard and self.wndScoreboard:IsValid() then
		self.tWarplotResults = tWarplotResults
		for idx, tTeamStats in pairs(tWarplotResults or {}) do
			local strStats = String_GetWeaselString(Apollo.GetString("PEStats_WarPartyTeamStats"), tTeamStats.nRating, tTeamStats.nDestroyedPlugs, tTeamStats.nRepairCost, tTeamStats.nWarCoinsEarned)
			local wndHeader = self.wndScoreboard:FindChild("Left:MainGridContainer:PvPArenaContainer:PvPTeamHeaderBot:PvPHeaderText")
			if idx == 1 then
				wndHeader = self.wndScoreboard:FindChild("Left:MainGridContainer:PvPArenaContainer:PvPTeamHeaderTop:PvPHeaderText")
			end
			
			wndHeader:SetData(strStats)
		end
		self.wndScoreboard:FindChild("PvPSurrenderMatchBtn"):Show(false)
	end
end

-- Post a chat message whenever War Coins change
function PublicEventStats:OnGuildWarCoinsChanged(guildOwner, nAmountGained)
	if nAmountGained > 0 then
		local strResult = String_GetWeaselString(Apollo.GetString("PEStats_WarcoinsGained"), nAmountGained)
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Loot, strResult, "")
	end
end

------------------------------------------------------------------------------------
-----  General Use Functions
------------------------------------------------------------------------------------

function PublicEventStats:OnResolutionChanged()
	self.bResolutionChanged = true -- Delay so we can get the new oValue
end

-- When the public event ends, show the appropriate screen
function PublicEventStats:OnPublicEventEnd(peEnding, eReason, tStats)
	local eEventType = peEnding:GetEventType()
	self.peActiveEvent = peEnding
	self.tZombieStats = tStats

	if ktPvPEvents[eEventType] or eEventType == PublicEvent.PublicEventType_NonCombatEvent then
		if not self.wndScoreboard then
			self:InitializeScoreboard(peEnding)
		end
		self:UpdateGrid()
		self.wndScoreboard:Invoke()
	elseif ktPvEInstancedEvents[eEventType] then
		self:BuildAdventuresSummary()
		self.wndAdventure:Invoke()
	end
end

-- When we change zones, destroy the window and clear the info
function PublicEventStats:OnChangeWorld()
	self.timerRedrawInfo:Stop()
	self.tZombieStats = nil
	self.tTrackedStats = nil
	self:OnClose()
end

function PublicEventStats:OnClose(wndHandler, wndControl) -- Also AdventureCloseBtn
	if self.wndScoreboard then
		local peCurrent = self.wndScoreboard:GetData() and self.wndScoreboard:GetData().peEvent
		if peCurrent then
			peCurrent:RequestScoreboard(false)
		end

		self.wndScoreboard:FindChild("BGPvPWinnerTopBarArtText"):SetText("")
		self.wndScoreboard:Destroy()
		self.wndScoreboard = nil
	end
	if self.wndAdventure then
		self.wndAdventure:Destroy()
		self.wndAdventure = nil
	end
	if self.wndDungeonMedalsForm and self.wndDungeonMedalsForm:IsValid() then
		self.wndDungeonMedalsForm:Destroy()
		self.wndDungeonMedalsForm = nil
	end
	self.timerRedrawInfo:Stop()
end

-----------------------------------------------------------------------------------------------
-----    Match Ending and Closing methods
-----------------------------------------------------------------------------------------------
function PublicEventStats:OnPvPLeaveMatchBtn(wndHandler, wndControl)
	if MatchingGameLib.IsInGameInstance() then
		if self.wndScoreboard then
			self.wndScoreboard:FindChild("BGPvPWinnerTopBar"):Show(false)
			self.wndScoreboard:Close()
		end
		MatchingGameLib.LeaveGame()
	end
end

function PublicEventStats:OnPvPSurrenderMatchBtn( wndHandler, wndControl, eMouseButton )
	if not MatchingGameLib.IsVoteSurrenderActive() then
		MatchingGameLib.InitiateVoteToSurrender()
	end
end

-----------------------------------------------------------------------------------------------
-----    Adventures Summary
-----------------------------------------------------------------------------------------------

function PublicEventStats:BuildAdventuresSummary() -- Also Dungeons
	if not self.tZombieStats or not self.peActiveEvent then
		return
	end
	
	self.wndAdventure = Apollo.LoadForm(self.xmlDoc , "AdventureEventStatsForm", nil, self)
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndAdventure, strName = Apollo.GetString("MatchMaker_Adventures")})

	local tPersonalStats = self.peActiveEvent:GetMyStats()
	local tScore = {["nDamage"] = 0, ["nHealed"] = 0, ["nDeaths"] = 0}

	-- Add Custom to score tracker
	for idx, tStat in pairs(tPersonalStats.arCustomStats) do
		if tStat.nValue and tStat.nValue > 0 then
			tScore[tStat.strName] = 0
			tPersonalStats[tStat.strName] = tStat.nValue
		end
	end

	-- Count times beaten by other participants
	for key, tCurr in pairs(self.tZombieStats.arParticipantStats) do
		tScore = self:HelperCompareScores(tPersonalStats, tCurr, tScore)
	end

	-- Convert to an interim table for sorting
	local tSortedTable = self:HelperSortTableForSummary(tScore)
	self.wndAdventure:FindChild("AwardsContainer"):DestroyChildren()
	for key, tData in pairs(tSortedTable) do
		local strIndex = tData.strKey
		local nValue = tData.nValue
		if #self.wndAdventure:FindChild("AwardsContainer"):GetChildren() < 3 then
			local nValueForString = math.abs(0 - nValue) + 1
			local strDisplayText = ""
			local strLabelText = nil
			if strIndex == "nDeaths" then
				strLabelText = String_GetWeaselString(Apollo.GetString("PublicEventStats_AwardLiving"), nValueForString)
				strDisplayText = Apollo.GetString("PublicEventStats_Deaths")
			elseif strIndex == "nHealed" and tPersonalStats.nHealed > 0 then
				strLabelText = String_GetWeaselString(Apollo.GetString("PublicEventStats_AwardOther"), nValueForString, Apollo.GetString("PublicEventStats_Heals"))
				strDisplayText = Apollo.GetString("PublicEventStats_Heals")
			elseif strIndex == "nDamage" and tPersonalStats.nDamage > 0 then
				strLabelText = String_GetWeaselString(Apollo.GetString("PublicEventStats_AwardOther"), nValueForString, Apollo.GetString("CRB_Damage"))
				strDisplayText = Apollo.GetString("CRB_Damage")
			elseif nValue > 0 and tPersonalStats[strIndex] and tPersonalStats[strIndex] > 0 then
				strLabelText = String_GetWeaselString(Apollo.GetString("PublicEventStats_AwardOther"), nValueForString, strIndex)
			end
			if strLabelText then
				local wndListItem = Apollo.LoadForm(self.xmlDoc , "AdventureListItem", self.wndAdventure:FindChild("AwardsContainer"), self)
				wndListItem:FindChild("AdventureListTitle"):SetText(strLabelText)
				wndListItem:FindChild("AdventureListDetails"):SetText((tPersonalStats[strIndex] or 0) .. " " .. strDisplayText)
				wndListItem:FindChild("AdventureListIcon"):SetSprite(ktAdventureListStrIndexToIconSprite[strIndex] or "Icon_SkillMind_UI_espr_moverb") -- TODO hardcoded formatting
			end
		end
	end

	self.wndAdventure:FindChild("AwardsContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	-- Reward Tier
	if self.tZombieStats and self.tZombieStats.eRewardTier and self.tZombieStats.eRewardType ~= 0 then -- TODO: ENUM!!
		self.wndAdventure:FindChild("RewardTierMessage"):SetText(ktRewardTierInfo[self.tZombieStats.eRewardTier].strText)
		self.wndAdventure:FindChild("RewardTierIcon"):SetSprite(ktRewardTierInfo[self.tZombieStats.eRewardTier].strSprite)
		
	else
		local wndMedalContainer = self.wndAdventure:FindChild("BGBottom")
		wndMedalContainer:FindChild("RewardTierIcon"):Show(false)
		wndMedalContainer:FindChild("OpenDungeonMedalsBtn"):Show(false)
		wndMedalContainer:FindChild("RewardTierMessage"):SetText(Apollo.GetString("PublicEventStats_NoDungeonMedals"))
	end

	-- Time in title
	if self.tZombieStats then
		local strTime = self:HelperConvertTimeToString(self.tZombieStats.nElapsedTime)
		local strTitle = String_GetWeaselString(Apollo.GetString("PublicEventStats_PlayerStats"), self.peActiveEvent:GetName())
		self.wndAdventure:FindChild("AdventureTitle"):SetText(String_GetWeaselString(Apollo.GetString("PublicEventStats_TimerHeader"), strTitle, strTime))
	else
		self.wndAdventure:FindChild("AdventureTitle"):SetText(String_GetWeaselString(Apollo.GetString("PublicEventStats_PlayerStats"), self.peActiveEvent:GetName()))
	end

	self.wndAdventure:FindChild("OpenDungeonMedalsBtn"):SetData(self.peActiveEvent)
	self.wndAdventure:FindChild("OpenDungeonMedalsBtn"):Show(self.peActiveEvent:GetEventType() == PublicEvent.PublicEventType_Dungeon)
end

function PublicEventStats:HelperCompareScores(tPersonalStats, tComparisonStats, tScore)
	--If we don't care about the stat to compare, we will not include it in the tPersonalStats.
	if tScore.nDeaths ~= nil and tComparisonStats.nDeaths ~= nil and tPersonalStats.nDeaths ~= nil and tComparisonStats.nDeaths < tPersonalStats.nDeaths then
		tScore.nDeaths = tScore.nDeaths + 1
	end
	if tScore.nDamage ~= nil and tComparisonStats.nDamage ~= nil and tPersonalStats.nDamage ~= nil and tComparisonStats.nDamage > tPersonalStats.nDamage then
		tScore.nDamage = tScore.nDamage + 1
	end
	if tScore.nHealed ~= nil and tComparisonStats.nHealed ~= nil and tPersonalStats.nHealed ~= nil and tComparisonStats.nHealed > tPersonalStats.nHealed then
		tScore.nHealed = tScore.nHealed + 1
	end

	for idx, tCompareStat in pairs(tComparisonStats.arCustomStats) do
		local tPersonalStat = tPersonalStats.arCustomStats[idx]
		if tPersonalStat and tCompareStat.nValue > tPersonalStat.nValue then
			if tScore[tCompareStat.strName] then
				tScore[tCompareStat.strName] = tScore[tCompareStat.strName] + 1
			else
				tScore[tCompareStat.strName] = 1
			end
		end
	end

	return tScore
end

-----------------------------------------------------------------------------------------------
-----    Dungeon Medals
-----------------------------------------------------------------------------------------------

function PublicEventStats:OnOpenDungeonMedalsBtn(wndHandler, wndControl)
	if self.wndDungeonMedalsForm and self.wndDungeonMedalsForm:IsValid() then
		self.wndDungeonMedalsForm:Destroy()
		self.wndDungeonMedalsForm = nil
	else
		self:BuildDungeonMedalScreen(wndHandler:GetData())
	end
end

function PublicEventStats:OnDungeonMedalsClose(wndHandler, wndControl)
	if self.wndDungeonMedalsForm and self.wndDungeonMedalsForm:IsValid() then
		self.wndDungeonMedalsForm:Destroy()
		self.wndDungeonMedalsForm = nil
	end
end

function PublicEventStats:BuildDungeonMedalScreen(peDungeon)
	if not self.tZombieStats or not self.tZombieStats.arObjectives then
		return
	end

	local nPass = 0
	local nTotal = 0
	self.wndDungeonMedalsForm = Apollo.LoadForm(self.xmlDoc	, "DungeonMedalsForm", nil, self)
	local wndPassContainer = self.wndDungeonMedalsForm:FindChild("DungeonMedalsPassScroll:Container")
	local wndFailContainer = self.wndDungeonMedalsForm:FindChild("DungeonMedalsFailScroll:Container")

	for idx, tData in pairs(self.tZombieStats.arObjectives) do -- GOTCHA: Zombie Stats is needed as the event won't have :GetObjectives() when finished
		local peoObjective = tData.peoObjective
		
		if not peoObjective:IsHidden() then
			local eCategory = peoObjective:GetCategory()
			if eCategory == PublicEventObjective.PublicEventObjectiveCategory_Challenge or eCategory == PublicEventObjective.PublicEventObjectiveCategory_Optional  then

				local bPass = tData.eStatus == PublicEventObjective.PublicEventStatus_Succeeded -- Other states include Succeeded, Active, Inactive and Failed
				local wndDungeonMedal = Apollo.LoadForm(self.xmlDoc	, "DungeonMedal", bPass and wndPassContainer or wndFailContainer, self)
				wndDungeonMedal:SetTooltip(peoObjective:GetDescription())
				
				local strObjective = peoObjective:GetDescription()--By Default
				if Apollo.StringLength(peoObjective:GetShortDescription()) > 0 then
					strObjective = peoObjective:GetShortDescription()
				end
				
				wndDungeonMedal:FindChild("RewardTierMessage"):SetAML(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"UI_TextHoloTitle\">%s</P>", strObjective))
				
				local nLeftBefore, nTopBefore, nRightBefore, nBottomBefore = wndDungeonMedal:FindChild("RewardTierMessage"):GetAnchorOffsets()
				wndDungeonMedal:FindChild("RewardTierMessage"):SetHeightToContentHeight()
				local nLeftAfter, nTopAfter, nRightAfter, nBottomAfter = wndDungeonMedal:FindChild("RewardTierMessage"):GetAnchorOffsets()
				local heightChange = nBottomAfter - nBottomBefore
				
				wndDungeonMedal:FindChild("RewardTierIcon"):SetSprite(PublicEventObjective.PublicEventObjectiveCategory_Challenge and "CRB_ChallengeTrackerSprites:sprChallengeTierGold" or "CRB_ChallengeTrackerSprites:sprChallengeTierBronze")
				
				local nLeft, nTop, nRight, nBottom = wndDungeonMedal:GetAnchorOffsets()
				wndDungeonMedal:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + heightChange)
				
				nTotal = nTotal + 1
				nPass = nPass + (bPass and 1 or 0)
			end
		end
	end

	-- Build and Resize Forms
	self.wndDungeonMedalsForm:FindChild("DungeonMedalsPassTitle"):SetText(String_GetWeaselString(Apollo.GetString("PublicEventStats_DungeonPassTitle"), tostring(nPass), tostring(nTotal)))
	wndPassContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	self.wndDungeonMedalsForm:FindChild("DungeonMedalsNoPassMessage"):Show(nPass == 0)
	self.wndDungeonMedalsForm:FindChild("DungeonMedalsNoPassMessage"):SetText(Apollo.GetString(karRandomFailStrings[math.random(1, #karRandomFailStrings)]) or "")

	self.wndDungeonMedalsForm:FindChild("DungeonMedalsFailTitle"):SetText(String_GetWeaselString(Apollo.GetString("PublicEventStats_DungeonFailTitle"), tostring(nTotal - nPass), tostring(nTotal)))
	wndFailContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.wndDungeonMedalsForm:FindChild("DungeonMedalsNoFailMessage"):Show(nPass == nTotal)
	self.wndDungeonMedalsForm:FindChild("DungeonMedalsNoFailMessage"):SetText(Apollo.GetString(karRandomPassStrings[math.random(1, #karRandomPassStrings)]) or "")
end

-----------------------------------------------------------------------------------------------
-----    Helpers
-----------------------------------------------------------------------------------------------
function PublicEventStats:HelperSortTableForSummary(tScore)
	local tNewTable = {}
	for key, nValue in pairs(tScore) do
		table.insert(tNewTable, {strKey = key, nValue = nValue or 0})
	end
	table.sort(tNewTable, function(a,b) return a.nValue < b.nValue end)
	return tNewTable
end

function PublicEventStats:HelperConvertTimeToString(fTime)
	fTime = math.floor(fTime / 1000) -- TODO convert to full seconds

	return string.format("%d:%02d", math.floor(fTime / 60), math.floor(fTime % 60))
end

function PublicEventStats:HelperGridFactoryProduce(wndGrid, tTargetComparison)
	for nRow = 1, wndGrid:GetRowCount() do
		if wndGrid:GetCellLuaData(nRow, 1) == tTargetComparison then -- GetCellLuaData args are row, col
			return nRow
		end
	end
	return wndGrid:AddRow("") -- GOTCHA: This is a row number
end

local PublicEventStatsInst = PublicEventStats:new()
PublicEventStatsInst:Init()