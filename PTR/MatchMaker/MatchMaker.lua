-----------------------------------------------------------------------------------------------
-- Client Lua Script for MatchMaker
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "MatchMakingLib"
require "MatchingGameLib"
require "GameLib"
require "Unit"
require "GuildLib"
require "GuildTypeLib"
require "GroupLib"
require "Episode"
require "Achievement"
require "AchievementsLib"
require "QuestLib"
require "QuestHub"
require "ContentFinderLib"
require "MatchMakingEntry"

-----------------------------------------------------------------------------------------------
-- MatchMaker Module Definition
-----------------------------------------------------------------------------------------------
local MatchMaker = {}

local knRandomMatchIndex = 0
local knQuestTabId = -1
local knFilterAll = -1
local knSaveVersion = 1
local crQueueTimeNormal = ApolloColor.new("UI_TextHoloTitle")
local crQueueTimePenalty = ApolloColor.new("UI_WindowTextRed")

local ktItemQualityColors =
{
	[Item.CodeEnumItemQuality.Inferior] 		= "ItemQuality_Inferior",
	[Item.CodeEnumItemQuality.Average] 			= "ItemQuality_Average",
	[Item.CodeEnumItemQuality.Good] 			= "ItemQuality_Good",
	[Item.CodeEnumItemQuality.Excellent] 		= "ItemQuality_Excellent",
	[Item.CodeEnumItemQuality.Superb] 			= "ItemQuality_Superb",
	[Item.CodeEnumItemQuality.Legendary] 		= "ItemQuality_Legendary",
	[Item.CodeEnumItemQuality.Artifact]		 	= "ItemQuality_Artifact",
}

local ktTypeNames = 
{
	[knQuestTabId]								= Apollo.GetString("CRB_Quests"),
	[MatchMakingLib.MatchType.Shiphand] 		= Apollo.GetString("MatchMaker_Shiphands"),
	[MatchMakingLib.MatchType.Adventure] 		= Apollo.GetString("MatchMaker_Adventures"),
	[MatchMakingLib.MatchType.Dungeon] 			= Apollo.GetString("CRB_Dungeons"),
	[MatchMakingLib.MatchType.Battleground]		= Apollo.GetString("MatchMaker_Battlegrounds"),
	[MatchMakingLib.MatchType.RatedBattleground]= Apollo.GetString("MatchMaker_Battlegrounds"),
	[MatchMakingLib.MatchType.Warplot] 			= Apollo.GetString("MatchMaker_Warplots"),
	[MatchMakingLib.MatchType.OpenArena] 		= Apollo.GetString("MatchMaker_Arenas"),
	[MatchMakingLib.MatchType.Arena] 			= Apollo.GetString("MatchMaker_Arenas"),
	[MatchMakingLib.MatchType.WorldStory]		= Apollo.GetString("QuestLog_WorldStory"),
	[MatchMakingLib.MatchType.PrimeLevelDungeon] = Apollo.GetString("MatchMaker_PrimeLevelDungeon"),
	[MatchMakingLib.MatchType.PrimeLevelExpedition] = Apollo.GetString("MatchMaker_PrimeLevelExpedition"),
	[MatchMakingLib.MatchType.PrimeLevelAdventure] = Apollo.GetString("MatchMaker_PrimeLevelAdventure"),
	[MatchMakingLib.MatchType.ScaledPrimeLevelDungeon] = Apollo.GetString("MatchMaker_PrimeLevelDungeon"),
	[MatchMakingLib.MatchType.ScaledPrimeLevelExpedition] = Apollo.GetString("MatchMaker_PrimeLevelExpedition"),
	[MatchMakingLib.MatchType.ScaledPrimeLevelAdventure] = Apollo.GetString("MatchMaker_PrimeLevelAdventure"),
}

-- Match Types need to correspond to ktPvPTypes and ktPvETypes (excluding quests)
local ktTypeIntros = 
{
	[MatchMakingLib.MatchType.Shiphand] 		= { 
		strBackground = "matchmaker:Matchmaker_BG_Expeditions",
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_Expeditions_GroupSize")), 
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_Expeditions_Desc1"), 
			Apollo.GetString("MatchMaker_Expeditions_Desc2"), 
		},
	},
	[MatchMakingLib.MatchType.Adventure] 		= { 
		strBackground = "matchmaker:Matchmaker_BG_Adventures",	
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_Adventures_GroupSize")), 
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_AvgDuration"), Apollo.GetString("MatchMaker_Adventures_AvgDuration")),
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_RecVetILevel"), Apollo.GetString("MatchMaker_Adventures_RecVetILevel")),
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_Adventures_Desc1"), 
			Apollo.GetString("MatchMaker_Adventures_Desc2"), 
		},
	},
	[MatchMakingLib.MatchType.Dungeon] 		= { 
		strBackground = "matchmaker:Matchmaker_BG_Dungeons",	
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_Dungeons_GroupSize")), 
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_Dungeons_Desc1"), 
			Apollo.GetString("MatchMaker_Dungeons_Desc2"), 
		},
	},
	[MatchMakingLib.MatchType.WorldStory]		 = { 
		strBackground = "matchmaker:Matchmaker_BG_WorldStory",
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_WorldStory_GroupSize")), 
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_AvgDuration"), Apollo.GetString("MatchMaker_WorldStory_AvgDuration")),
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_WorldStory_Desc1"), 
			Apollo.GetString("MatchMaker_WorldStory_Desc2"), 
		},
	},
	[MatchMakingLib.MatchType.Battleground] 	 = { 
		strBackground = "matchmaker:Matchmaker_BG_Battlegrounds",
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_Battlegrounds_GroupSize")), 
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_Battlegrounds_Desc1"), 
			Apollo.GetString("MatchMaker_Battlegrounds_Desc2"), 
		},
	},
	[MatchMakingLib.MatchType.Warplot] 		 = { 
		strBackground = "matchmaker:Matchmaker_BG_Warplots",
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_Warplots_GroupSize")), 
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_Warplots_Desc1"), 
			Apollo.GetString("MatchMaker_Warplots_Desc2"), 
		},
	},
	[MatchMakingLib.MatchType.OpenArena]  	= { 
		strBackground = "matchmaker:Matchmaker_BG_Arenas",	
		arStats = {
			String_GetWeaselString(Apollo.GetString("MatchMaker_Label_GroupSize"), Apollo.GetString("MatchMaker_Arenas_GroupSize")), 
		}, 
		arDescription = {
			Apollo.GetString("MatchMaker_Arenas_Desc1"), 
			Apollo.GetString("MatchMaker_Arenas_Desc2"), 
		},
	},	
}


-- Numbers indicate sort order for tabs.  1 is quest
local ktPvETypes =
{
	[knQuestTabId]								= 1,
	[MatchMakingLib.MatchType.Shiphand] 		= 2,
	[MatchMakingLib.MatchType.Adventure] 		= 3,
	[MatchMakingLib.MatchType.Dungeon] 			= 4,
	[MatchMakingLib.MatchType.WorldStory]		= 5,
}

local ktPvEPrimeLevelTypes =
{
	[MatchMakingLib.MatchType.PrimeLevelDungeon] = MatchMakingLib.MatchType.Dungeon,
	[MatchMakingLib.MatchType.PrimeLevelExpedition] = MatchMakingLib.MatchType.Shiphand,
	[MatchMakingLib.MatchType.PrimeLevelAdventure] = MatchMakingLib.MatchType.Adventure,
}

local ktPvEPrimeLevelScaledTypes =
{
	[MatchMakingLib.MatchType.PrimeLevelDungeon] = MatchMakingLib.MatchType.ScaledPrimeLevelDungeon,
	[MatchMakingLib.MatchType.PrimeLevelExpedition] = MatchMakingLib.MatchType.ScaledPrimeLevelExpedition,
	[MatchMakingLib.MatchType.PrimeLevelAdventure] = MatchMakingLib.MatchType.ScaledPrimeLevelAdventure,
}

-- Numbers indicate sort order for tabs
local ktPvPTypes = 
{
	[MatchMakingLib.MatchType.Battleground]		= 1,
	[MatchMakingLib.MatchType.Warplot] 			= 2,
	[MatchMakingLib.MatchType.OpenArena] 		= 3,
}

local ktRatedPvPTypes =
{
	[MatchMakingLib.MatchType.RatedBattleground] 	= true,
	[MatchMakingLib.MatchType.Warplot] 				= true,
	[MatchMakingLib.MatchType.Arena] 				= true,
}

local ktRatedToNormal =
{
	[MatchMakingLib.MatchType.RatedBattleground] 	= MatchMakingLib.MatchType.Battleground,
	[MatchMakingLib.MatchType.Arena]				= MatchMakingLib.MatchType.OpenArena,
}

local ktNormalToRated =
{
	[MatchMakingLib.MatchType.Battleground]			= MatchMakingLib.MatchType.RatedBattleground,
	[MatchMakingLib.MatchType.OpenArena]			= MatchMakingLib.MatchType.Arena,
}

local ktPvPGuildRequired =
{
	[MatchMakingLib.MatchType.Arena] 			= true,
	[MatchMakingLib.MatchType.Warplot] 			= true,
}

local ktPvPGuildToTeamSize =
{
	[2]		= GuildLib.GuildType_ArenaTeam_2v2,
	[3] 	= GuildLib.GuildType_ArenaTeam_3v3,
	[5] 	= GuildLib.GuildType_ArenaTeam_5v5,
	[30] 	= GuildLib.GuildType_WarParty,
}

local ktEpisodeStateColors = 
{
	[Episode.EpisodeState_Unknown] 		= "UI_TextHoloBodyCyan",
	[Episode.EpisodeState_Mentioned] 	= "UI_TextHoloBody",
	[Episode.EpisodeState_Active] 		= "UI_TextHoloBody",
	[Episode.EpisodeState_Complete] 	= "UI_BtnTextGreenNormal",
}

local ktPvPRatingTypes =
{
	[MatchMakingLib.MatchType.Arena] =
	{
		[2] = MatchMakingLib.RatingType.Arena2v2,
		[3] = MatchMakingLib.RatingType.Arena3v3,
		[5] = MatchMakingLib.RatingType.Arena5v5,
	},
	
	[MatchMakingLib.MatchType.RatedBattleground] 	= MatchMakingLib.RatingType.RatedBattleground,
	[MatchMakingLib.MatchType.Warplot] 				= MatchMakingLib.RatingType.Warplot,
}

local ktLevelUpUnlockToMatchTypes =
{
	[GameLib.LevelUpUnlockType.Dungeon_New] 		= MatchMakingLib.MatchType.Dungeon,
	[GameLib.LevelUpUnlockType.Adventure_New] 		= MatchMakingLib.MatchType.Adventure,
	[GameLib.LevelUpUnlockType.Shiphand_New] 		= MatchMakingLib.MatchType.Shiphand,
	[GameLib.LevelUpUnlockType.PvP_Battleground] 	= MatchMakingLib.MatchType.RatedBattleground,
}

local ktRalliedContentTypes =
{
	[MatchMakingLib.MatchType.Dungeon] = true,
}

local ktContentTypeIcons =
{
	[GameLib.CodeEnumRewardRotationContentType.Dungeon] = "matchmaker:ContentType_Dungeon",
	[GameLib.CodeEnumRewardRotationContentType.PeriodicQuest] = "matchmaker:ContentType_Quest",
	[GameLib.CodeEnumRewardRotationContentType.Expedition] = "matchmaker:ContentType_Expedition",
	[GameLib.CodeEnumRewardRotationContentType.WorldBoss] = "matchmaker:ContentType_WorldBoss",
	[GameLib.CodeEnumRewardRotationContentType.PvP] = "matchmaker:ContentType_PvP",
	[GameLib.CodeEnumRewardRotationContentType.DungeonNormal] = "matchmaker:ContentType_Dungeon",
}

local ktContentTypeString =
{
	[GameLib.CodeEnumRewardRotationContentType.Dungeon] = Apollo.GetString("ZoneStateDungeon"),
	[GameLib.CodeEnumRewardRotationContentType.PeriodicQuest] = Apollo.GetString("MatchMaker_DailyQuestZone"),
	[GameLib.CodeEnumRewardRotationContentType.Expedition] = Apollo.GetString("ExplorerMission_Expedition"),
	[GameLib.CodeEnumRewardRotationContentType.WorldBoss] = Apollo.GetString("CRB_WorldBoss"),
	[GameLib.CodeEnumRewardRotationContentType.PvP] = Apollo.GetString("CRB_Pvp"),
	[GameLib.CodeEnumRewardRotationContentType.DungeonNormal] = Apollo.GetString("MatchMaker_RandomQueue"),
}

local ktContentTypeFilterString =
{
	[knFilterAll] = Apollo.GetString("MatchMaker_ContentFilterAll"),
	[GameLib.CodeEnumRewardRotationContentType.Dungeon] = Apollo.GetString("CRB_Dungeons"),
	[GameLib.CodeEnumRewardRotationContentType.PeriodicQuest] = Apollo.GetString("MatchMaker_ContentFilterPeriodicQuest"),
	[GameLib.CodeEnumRewardRotationContentType.Expedition] = Apollo.GetString("MatchMaker_Shiphands"),
	[GameLib.CodeEnumRewardRotationContentType.WorldBoss] = Apollo.GetString("MatchMaker_ContentFilterWorldBoss"),
	[GameLib.CodeEnumRewardRotationContentType.PvP] = Apollo.GetString("CRB_Pvp"),
	[GameLib.CodeEnumRewardRotationContentType.DungeonNormal] = Apollo.GetString("MatchMaker_ContentFilterRandomQueues"),
}

local keMasterTabs =
{
	["PvE"]			= 1,
	["PvP"]			= 2,
}

local keFeaturedSort =
{
	["ContentType"]		= 1,
	["TimeRemaining"]	= 2,
}


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function MatchMaker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here
	o.fTimeRemaining 	= 0
	o.fTimeInQueue 		= 0
	o.fCooldownTime 	= 0
	o.fDuelCountdown	= 0
	o.fDuelWarning		= 0

    return o
end

function MatchMaker:Init()
    Apollo.RegisterAddon(self)
end

function MatchMaker:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	
	local tSaved = 
	{
		nSaveVersion = knSaveVersion,
		tQueueOptions = self.tQueueOptions,
	}
	
	return tSaved
end

function MatchMaker:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	if not tSavedData or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end

	self.tQueueOptions = tSavedData.tQueueOptions
end

function MatchMaker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("MatchMaker.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function MatchMaker:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end

	-- Startup/Init
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 			"OnInterfaceMenuListHasLoaded", self)
	self:OnInterfaceMenuListHasLoaded()
	Apollo.RegisterEventHandler("ToggleGroupFinder", 					"OnToggleMatchMaker", self)
	Apollo.RegisterEventHandler("WindowManagementReady", 				"OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	-- Match Queue
	Apollo.RegisterEventHandler("MatchingJoinQueue", 					"OnJoinQueue", self)
	Apollo.RegisterEventHandler("MatchingLeaveQueue", 					"OnLeaveQueue", self)
	Apollo.RegisterEventHandler("MatchingGameReady", 					"OnGameReady", self)
	Apollo.RegisterEventHandler("MatchingGamePendingUpdate", 			"OnGamePendingUpdate", self)
	Apollo.RegisterEventHandler("MatchingCancelPendingGame",			"PendingGameCanceled", self)
	Apollo.RegisterEventHandler("MatchEntered", 						"OnMatchEntered", self)
	Apollo.RegisterEventHandler("MatchExited", 							"CleanUpAll", self)
	Apollo.RegisterEventHandler("MatchingEligibilityChanged", 			"RecalculateContents", self)
	Apollo.RegisterEventHandler("MatchLookingForReplacements",			"OnLookingForReplacements", self)
	Apollo.RegisterEventHandler("MatchStoppedLookingForReplacements", 	"OnStoppedLookingForReplacements", self)
	Apollo.RegisterEventHandler("MatchLeft", 							"UpdateInMatchControls", self)
	Apollo.RegisterEventHandler("UnitLevelChanged",						"OnUnitLevelChanged", self)
	Apollo.RegisterEventHandler("MatchingPenaltyUpdated",				"CheckQueuePenalties", self)
	
	self.timerQueue = ApolloTimer.Create(1.0, true, "OnQueueTimer", self)
	self.timerQueue:Stop()
	
	-- Role Check
	Apollo.RegisterEventHandler("MatchingRoleCheckStarted", 			"OnRoleCheck", self)
	Apollo.RegisterEventHandler("MatchingRoleCheckCanceled", 			"OnRoleCheckCanceled", self)
	
	-- Voting
	Apollo.RegisterEventHandler("MatchVoteKickBegin", 					"OnVoteKickBegin", self)
	Apollo.RegisterEventHandler("MatchVoteKickEnd", 					"OnVoteKickEnd", self)
	Apollo.RegisterEventHandler("MatchVoteSurrenderBegin", 				"OnVoteSurrenderBegin", self)
	Apollo.RegisterEventHandler("MatchVoteSurrenderEnd", 				"OnVoteSurrenderEnd", self)
	
	-- Updating
	Apollo.RegisterEventHandler("GuildChange",							"OnUpdateGuilds", self)
	Apollo.RegisterEventHandler("CharacterCreated",						"OnCharacterCreated", self)
	Apollo.RegisterEventHandler("Group_Join",							"OnUpdateGroup", self)
	Apollo.RegisterEventHandler("Group_Left",							"OnUpdateGroup", self)
	Apollo.RegisterEventHandler("Group_Add",							"OnUpdateGroup", self)
	Apollo.RegisterEventHandler("Group_Remove",							"OnUpdateGroup", self)
	Apollo.RegisterEventHandler("ChangeWorld",							"OnClose", self)
	Apollo.RegisterEventHandler("AchievementGranted",					"UpdateAchievements", self)
	Apollo.RegisterEventHandler("PlayerLevelChange",					"OnPlayerLevelChange", self)
	
	-- Dueling
	Apollo.RegisterEventHandler("DuelStateChanged",						"OnDuelStateChanged", self)
	Apollo.RegisterEventHandler("DuelAccepted",							"OnDuelAccepted", self)
	Apollo.RegisterEventHandler("DuelLeftArea",							"OnDuelLeftArea", self)
	Apollo.RegisterEventHandler("DuelCancelWarning",					"OnDuelCancelWarning", self)

	--PremiumTierUpdates
	Apollo.RegisterEventHandler("PremiumTierChanged",					"UpdateTeamInfo", self)

	--StoreLinks
	Apollo.RegisterEventHandler("StoreLinksRefresh",					"RefreshStoreLink", self)

	-- Tutorial Anchor
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 			"OnTutorial_RequestUIAnchor", self)
	
	-- Events from other addons
	Apollo.RegisterEventHandler("OpenContentFinderToUnlock",			"OnOpenContentFinderToUnlock", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_GroupFinder_General",	"OnShowContentFinder", self)
	Apollo.RegisterEventHandler("SuggestedContent_ShowMatch",			"OnSuggestedContentShowMatch", self)
	Apollo.RegisterEventHandler("OpenQueueWindow",						"OnShowQueueStatus", self)

	self.timerDuelCountdown = ApolloTimer.Create(1.0, true, "OnDuelCountdownTimer", self)
	self.timerDuelCountdown:Stop()

	self.timerDuelRangeWarning = ApolloTimer.Create(1.0, true, "OnDuelWarningTimer", self)
	self.timerDuelRangeWarning:Stop()
	
	self.timerNavPointNotification = ApolloTimer.Create(3.0, false, "HideNavPointNotification", self)
	self.timerNavPointNotification:Stop()
	
	self.tWndRefs = {}
	self.ePvETabSelected = nil
	self.ePvPTabSelected = nil
	self.matchDisplayed = nil
	self.eSelectedMasterType = keMasterTabs.PvE
	self.tHubList = {}
	self.tMatchList = {}
	self.arMatchesToQueue = {}
	self.tQueueTypes = {}

	self.tHasGuild = {}
	
	if not self.tQueueOptions then
		self.tQueueOptions =
		{ 
			[keMasterTabs.PvE] = 
			{
				bVeteran = false,
				bFindOthers = true,
				arRoles = {},
			}, 
			[keMasterTabs.PvP] = 
			{
				bAsMercenary = true,
				arRoles = {},
			},
		}
	end
	
	self:RefreshStoreLink()
	
	if MatchMakingLib.IsQueuedForMatching() or MatchingGameLib.IsPendingGame() then
		self:OnJoinQueue()
	end
	
	for idx, nContentType in pairs(GameLib.CodeEnumRewardRotationContentType) do
		GameLib.RequestRewardUpdate(nContentType)
	end
end

function MatchMaker:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("CRB_ContentFinder"), nSaveVersion = 2})
end

function MatchMaker:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("CRB_ContentFinder"), {"ToggleGroupFinder", "GroupFinder", "Icon_Windows32_UI_CRB_InterfaceMenu_GroupFinder"})
end

function MatchMaker:OnToggleMatchMaker()
	if self.tWndRefs.wndMain then
		self:OnClose()
		Event_FireGenericEvent("LFGWindowHasBeenClosed")
	else
		self:OnMatchMakerOn()
	end
end

function MatchMaker:OnMatchMakerOn()
	if not self.tWndRefs.wndMain then
		self.tWndRefs.wndMain = Apollo.LoadForm(self.xmlDoc, "MatchMakerForm", nil, self)
		self.tWndRefs.wndMain:Invoke()
		self.tWndRefs.wndTeamBtn = self.tWndRefs.wndMain:FindChild("TeamBtn")
	end
	
	self:OnUpdateGuilds()
	self:BuildHubInfo()
	self:BuildMatchTable()
	
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndMain, strName = Apollo.GetString("CRB_ContentFinder")})
	
	local wndPvEList = self.tWndRefs.wndMain:FindChild("PvETab")	
	self:BuildTabs(wndPvEList, ktPvETypes)
	
	local wndPvPList = self.tWndRefs.wndMain:FindChild("PvPTab")
	self:BuildTabs(wndPvPList, ktPvPTypes)
	
	local wndHeaderBtns = self.tWndRefs.wndMain:FindChild("HeaderButtons")
	local wndPvEBtn = wndHeaderBtns:FindChild("PvEBtn")
	local wndPvPBtn = wndHeaderBtns:FindChild("PvPBtn")
	local wndFeaturedBtn = wndHeaderBtns:FindChild("FeaturedBtn")
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer and unitPlayer:IsHeroismUnlocked() then
		wndFeaturedBtn:Enable(true)
	else
		wndFeaturedBtn:Enable(false)
		wndFeaturedBtn:SetTooltip(Apollo.GetString("MatchMaker_FeaturedContentDisabledTooltip"))
	end
	
	wndPvEBtn:SetData(keMasterTabs.PvE)
	wndPvPBtn:SetData(keMasterTabs.PvP)
	
	local nSeason = MatchMakingLib.GetPvpSeason(MatchMakingLib.MatchType.Arena)
	local strLabel = Apollo.GetString("CRB_PVP")
	
	if nSeason > 0 then
		strLabel = String_GetWeaselString(Apollo.GetString("MatchMaker_PvPSeasonTitle"), nSeason)
	end
	
	wndPvPBtn:SetText(strLabel)
	
	local wndFeaturedTab = self.tWndRefs.wndMain:FindChild("FeaturedTab")
	self.tWndRefs.wndRewardFilter = wndFeaturedTab:FindChild("RewardFilter")
	self.tWndRefs.wndContentFilter = wndFeaturedTab:FindChild("ContentFilter")
	self.tWndRefs.wndContentFilter:SetData(knFilterAll)
	self.tWndRefs.wndFeaturedSort = wndFeaturedTab:FindChild("FeaturedSort")
	self.tWndRefs.wndFeaturedSort:SetData(keFeaturedSort.ContentType)
	self:HelperCreateContentFilter()
	self:HelperCreateFeaturedSort()

	self.tWndRefs.wndContentFilter:AttachWindow(self.tWndRefs.wndContentFilter:FindChild("FeaturedFilterDropdown"))
	self.tWndRefs.wndFeaturedSort:AttachWindow(self.tWndRefs.wndFeaturedSort:FindChild("FeaturedFilterDropdown"))
	
	if self.eSelectedMasterType == keMasterTabs.PvE then
		wndPvEBtn:SetCheck(true)
		self:OnPvETabSelected(wndPvEBtn, wndPvEBtn)
	elseif self.eSelectedMasterType == keMasterTabs.PvP then
		wndPvPBtn:SetCheck(true)
		self:OnPvPTabSelected(wndPvPBtn, wndPvPBtn)
	else
		wndFeaturedBtn:SetCheck(true)
		self:OnFeaturedTabSelected(wndFeaturedBtn, wndFeaturedBtn)
	end
	
	self.tWndRefs.wndPrimeLevelBtn = self.tWndRefs.wndMain:FindChild("PrimeLevelBtn")
	self.tWndRefs.wndPrimeLevelList = self.tWndRefs.wndMain:FindChild("PrimeLevelList")
	self.tWndRefs.wndPrimeLevelsUnavailable = self.tWndRefs.wndMain:FindChild("PrimeLevelsUnavailable")
	self.tWndRefs.wndPrimeLevelBtn:AttachWindow(self.tWndRefs.wndPrimeLevelList)
end

function MatchMaker:BuildTabs(wndParent, tMatchTypes)
	local nTableSize = 0
	for eMatchType, nSortOrder in pairs(tMatchTypes) do
		nTableSize = nTableSize + 1
	end
	
	local fRightAnchor = 1/nTableSize
	for eMatchType, nSortOrder in pairs(tMatchTypes) do
		local wndCurrTab = Apollo.LoadForm(self.xmlDoc, "MatchTypeButton", wndParent, self)
		wndCurrTab:SetText(ktTypeNames[eMatchType])
		wndCurrTab:SetData(eMatchType)
		wndCurrTab:SetAnchorPoints(fRightAnchor * (tMatchTypes[eMatchType] - 1), 0, fRightAnchor * tMatchTypes[eMatchType], 1)
		
		if nSortOrder == 1 then
			wndCurrTab:ChangeArt("BK3:btnMetal_TabSub_Left")
		elseif nSortOrder == nTableSize then
			wndCurrTab:ChangeArt("BK3:btnMetal_TabSub_Right")
		end
	end
end

function MatchMaker:BuildHubInfo()
	self.tHubList = {}

	local unitPlayer = GameLib.GetPlayerUnit()
	local nZoneCount = 0
	for idx, epiKnown in pairs(QuestLib.GetAllEpisodes(true, true)) do
		local hubCurrent = epiKnown:GetHub()

		if hubCurrent then
			local strZone = hubCurrent:GetWorldZoneName()
			local strHub = hubCurrent:GetSubZoneName()
			local nLevel = epiKnown:GetConLevel()
			local eConColor = epiKnown:GetColoredDifficulty()
	
			if strZone and strZone ~= "" then
				if not self.tHubList[strZone] then
					self.tHubList[strZone] = 
					{
						nTotal = 0,
						nCompleted = 0,
						nMinLevel = nLevel,
						nMaxLevel = nLevel,
						eDifficulty = eConColor,
						strZoneName = strZone,
						tHubInfo = {},
					}
				end

				if not self.tHubList[strZone].tHubInfo[strHub] then
					self.tHubList[strZone].tHubInfo[strHub] = 
					{
						nTotal = 0,
						nCompleted = 0,
						nMinLevel = nLevel,
						nMaxLevel = nLevel,
						eDifficulty = eConColor,
						arEpisodes = {},
					}
				end

				if self.tHubList[strZone].nMinLevel > nLevel then
					self.tHubList[strZone].nMinLevel = nLevel
				end

				if self.tHubList[strZone].nMaxLevel < nLevel then
					self.tHubList[strZone].nMaxLevel = nLevel
				end
				
				if self.tHubList[strZone].eDifficulty > eConColor then
					self.tHubList[strZone].eDifficulty = eConColor
				end

				if self.tHubList[strZone].tHubInfo[strHub].nMinLevel > nLevel then
					self.tHubList[strZone].tHubInfo[strHub].nMinLevel = nLevel
				end

				if self.tHubList[strZone].tHubInfo[strHub].nMaxLevel < nLevel then
					self.tHubList[strZone].tHubInfo[strHub].nMaxLevel = nLevel
				end
				
				if self.tHubList[strZone].tHubInfo[strHub].eDifficulty > eConColor then
					self.tHubList[strZone].tHubInfo[strHub].eDifficulty = eConColor
				end

				local eState = epiKnown:GetState()
				if eState == Episode.EpisodeState_Complete then
					self.tHubList[strZone].nCompleted = self.tHubList[strZone].nCompleted + 1
					self.tHubList[strZone].tHubInfo[strHub].nCompleted = self.tHubList[strZone].tHubInfo[strHub].nCompleted + 1
				end

				self.tHubList[strZone].nTotal = self.tHubList[strZone].nTotal + 1
				self.tHubList[strZone].tHubInfo[strHub].nTotal = self.tHubList[strZone].tHubInfo[strHub].nTotal + 1
				
				table.insert(self.tHubList[strZone].tHubInfo[strHub].arEpisodes, epiKnown)
			end
		end
	end
end

function MatchMaker:BuildMatchTable()
	self.tMatchList = {}
	self.tPrimeLevelMatchTypes = {}

	for strIndex, eMatchType in pairs(MatchMakingLib.MatchType) do
		local eTypeIndex = eMatchType
		if ktRatedToNormal[eMatchType] then
			eTypeIndex = ktRatedToNormal[eMatchType]
		end
		
		if not self.tMatchList[eTypeIndex] then
			self.tMatchList[eTypeIndex] = {}
		end
		
		local bUseTeamSize = eMatchType == MatchMakingLib.MatchType.OpenArena or eMatchType == MatchMakingLib.MatchType.Arena or eMatchType == MatchMakingLib.MatchType.Warplot
		local nPlayerLevel = GameLib.GetPlayerLevel(true)

		for idx, matchGame in pairs(MatchMakingLib.GetMatchMakingEntries(eMatchType, false, true)) do			
			if not ktRatedPvPTypes[eMatchType] and not matchGame:IsVeteran() then
				-- Arenas all use the same map, so we need to index them by team size
				local tMatchInfo = matchGame:GetInfo()
				local nIndex = tMatchInfo.nGameId
				if bUseTeamSize then
					nIndex = tMatchInfo.nTeamSize
				end
				
				local nLevelDiff = nPlayerLevel - tMatchInfo.nMinLevel
						
				if tMatchInfo.nMaxLevel == 0 or nPlayerLevel <= tMatchInfo.nMaxLevel then
					if not self.tMatchList[eTypeIndex][nIndex] then
						self.tMatchList[eTypeIndex][nIndex] = {}
					end
					
					if not self.tMatchList[eTypeIndex][nIndex].matchNormal then
						self.tMatchList[eTypeIndex][nIndex].matchNormal = matchGame
					elseif nLevelDiff >= 0 and nLevelDiff < nPlayerLevel - self.tMatchList[eTypeIndex][nIndex].matchNormal:GetInfo().nMinLevel then
						self.tMatchList[eTypeIndex][nIndex].matchNormal = matchGame
					end
				end
			end
		end

		local arVeteranGames = MatchMakingLib.GetMatchMakingEntries(eMatchType, not ktRatedPvPTypes[eMatchType], true)
		for idx, matchVet in pairs(arVeteranGames) do
			local tVetInfo = matchVet:GetInfo()
			local nIndex = tVetInfo.nGameId
			if bUseTeamSize then
				nIndex = tVetInfo.nTeamSize
			end
				
			local tMatchInfo = self.tMatchList[eTypeIndex][nIndex]
			if tMatchInfo then
				tMatchInfo.matchVet = matchVet
			else
				self.tMatchList[eTypeIndex][nIndex] = {matchVet = matchVet}

				if tVetInfo.nMaxPrimeLevel > 0 and ktPvEPrimeLevelTypes[eMatchType] then
					self.tPrimeLevelMatchTypes[ktPvEPrimeLevelTypes[eMatchType]] = true
				end
				
				if GroupLib.InGroup() then
					self.tMatchList[eTypeIndex][nIndex].nPrimeLevel = GroupLib.GetPrimeLevelAchieved(tVetInfo.nGameId)
				else
					self.tMatchList[eTypeIndex][nIndex].nPrimeLevel = GameLib.GetPrimeLevelAchieved(tVetInfo.nGameId)
				end
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Tab Selection
-----------------------------------------------------------------------------------------------

function MatchMaker:OnFeaturedTabSelected(wndHandler, wndControl)
	local wndFeaturedTab = self.tWndRefs.wndMain:FindChild("FeaturedTab")
	self.eSelectedMasterType = wndHandler:GetData()
	
	wndFeaturedTab:Show(true)
	
	self.tWndRefs.wndMain:FindChild("PvPTab"):Show(false)
	self.tWndRefs.wndMain:FindChild("PvETab"):Show(false)
	
	self.tWndRefs.wndMain:FindChild("BGArt"):SetWindowTemplate("Metal_Primary_Nav_SubNav")
		
	self:BuildFeaturedList()
end

function MatchMaker:OnPvETabSelected(wndHandler, wndControl)
	local wndPvETab = self.tWndRefs.wndMain:FindChild("PvETab")
	
	self.eSelectedMasterType = wndHandler:GetData()
	
	wndPvETab:Show(true)
	self.tWndRefs.wndMain:FindChild("PvPTab"):Show(false)
	self.tWndRefs.wndMain:FindChild("FeaturedTab"):Show(false)
	local wndRewardContent = self.tWndRefs.wndMain:FindChild("TabContent:RewardContent")
	wndRewardContent:DestroyChildren()
	wndRewardContent:Show(false)

	self.tWndRefs.wndMain:FindChild("TabContent"):Show(true)

	self.tWndRefs.wndMain:FindChild("BGArt"):SetWindowTemplate("Metal_Primary_Nav_SubNav")

	if self.ePvETabSelected and self.ePvETabSelected ~= knQuestTabId then
		local wndSelectedTab = wndPvETab:FindChildByUserData(self.ePvETabSelected)
		wndPvETab:SetRadioSelButton("MatchMakerPvETabGroup", wndSelectedTab)
		wndSelectedTab:SetCheck(true)
		
		self:BuildMatchList(wndSelectedTab, wndSelectedTab)
	else
		local wndQuestTab = wndPvETab:FindChildByUserData(knQuestTabId)
		wndPvETab:SetRadioSelButton("MatchMakerPvETabGroup", wndQuestTab)
		wndQuestTab:SetCheck(true)
		
		self:BuildQuestList()
	end
end

function MatchMaker:OnPvPTabSelected(wndHandler, wndControl)
	local wndPvPTab = self.tWndRefs.wndMain:FindChild("PvPTab")

	self.eSelectedMasterType = wndHandler:GetData()
	
	wndPvPTab:Show(true)
	self.tWndRefs.wndMain:FindChild("PvETab"):Show(false)
	self.tWndRefs.wndMain:FindChild("FeaturedTab"):Show(false)
	local wndRewardContent = self.tWndRefs.wndMain:FindChild("TabContent:RewardContent")
	wndRewardContent:DestroyChildren()
	wndRewardContent:Show(false)
	
	self.tWndRefs.wndMain:FindChild("TabContent"):Show(true)
	self.tWndRefs.wndMain:FindChild("BGArt"):SetWindowTemplate("Metal_Primary_Nav_SubNav")
	
	local eSelectedTab = MatchMakingLib.MatchType.Battleground
	
	if self.ePvPTabSelected then
		eSelectedTab = self.ePvPTabSelected
	end
	
	local wndSelectedTab = wndPvPTab:FindChildByUserData(eSelectedTab)
	wndPvPTab:SetRadioSelButton("MatchMakerPvETabGroup", wndSelectedTab)
	wndSelectedTab:SetCheck(true)
	
	self:BuildMatchList(wndSelectedTab, wndSelectedTab)
end

function MatchMaker:UpdateInMatchControls()
	if not self.tWndRefs.wndMain then
		return
	end
	local wndMatchContent = self.tWndRefs.wndMain:FindChild("MatchContent")
	local wndOptions = wndMatchContent:FindChild("InstanceOptions")
	local wndInfoText = wndMatchContent:FindChild("MatchTypeInfo:TextContainer")
	local nTextLeft, nTextTop, nTextRight, nTextBottom = wndInfoText:GetOriginalLocation():GetOffsets()
	
	local matchInstance = MatchingGameLib.GetQueueEntry()
	if matchInstance then
		wndOptions:Show(true)
		wndOptions:FindChild("InstanceTitle"):SetText(matchInstance:GetInfo().strName)
		
		wndOptions:FindChild("VoteDisband"):Enable(MatchingGameLib.CanVoteSurrender())
		wndOptions:FindChild("FindReplacements"):Enable(MatchingGameLib.CanLookForReplacements())
		wndOptions:FindChild("CancelReplacements"):Enable(GroupLib.AmILeader())
		wndOptions:FindChild("TeleportToInstance"):Enable(not MatchingGameLib.IsInGameInstance())
		
		local bIsLookingForReplacements = MatchingGameLib.IsLookingForReplacements()
		wndOptions:FindChild("FindReplacements"):Show(not bIsLookingForReplacements)
		wndOptions:FindChild("CancelReplacements"):Show(bIsLookingForReplacements)
		
		local tRewards = matchInstance:GetRotationRewards()
		local wndLockedRewards = wndOptions:FindChild("LockedRewards")
		local wndRewardIconContainer = wndLockedRewards:FindChild("RewardIconContainer")
	
		local bFound = false
		if tRewards ~= nil and tRewards.bRewardsLocked then
			for idx, tReward in pairs(tRewards.arRewards) do
				if tReward.nRewardType == GameLib.CodeEnumRewardRotationRewardType.Essence then
					bFound = true
				
					self:BuildRewardContainer(wndRewardIconContainer, tReward)
					
					local wndRewardIconEntry = wndLockedRewards:FindChild("RewardIconEntry")
					wndRewardIconEntry:RemoveEventHandler("GenerateTooltip")
					wndRewardIconEntry:SetTooltip("")
					wndRewardIconEntry:SetStyle("IgnoreMouse", true)
					wndRewardIconEntry:SetAnchorPoints(1,0,1,0)
					wndRewardIconEntry:SetAnchorOffsets(-wndLockedRewards:GetWidth(),0,0,wndLockedRewards:GetHeight())
					
					local wndRewardIcon = wndRewardIconEntry:FindChild("RewardIcon")
					wndRewardIcon:SetTooltip("")
					wndRewardIcon:SetAnchorPoints(0,0,1,1)
					wndRewardIcon:SetAnchorOffsets(2,2,-1,-1)
					
					local wndRewardIconMultiplier = wndRewardIconEntry:FindChild("RewardMultiplier")
					wndRewardIconMultiplier:SetTooltip("")
					wndRewardIconMultiplier:SetSprite("")
					wndRewardIconMultiplier:SetAnchorPoints(0,1,1,1)
					wndRewardIconMultiplier:SetAnchorOffsets(0,-15,0,-1)
				end
			end
			
			wndRewardIconContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)
		end
		
		wndLockedRewards:Show(tRewards ~= nil and tRewards.bRewardsLocked and bFound)
		
		local nOptionsHeight = wndOptions:GetHeight()
		wndInfoText:SetAnchorOffsets(nTextLeft, nOptionsHeight, nTextRight, nTextBottom)
	else
		wndOptions:Show(false)
		wndInfoText:SetAnchorOffsets(nTextLeft, nTextTop, nTextRight, nTextBottom)
	end
end

function MatchMaker:OnLookingForReplacements()
	self:UpdateInMatchControls()
	self:OnRoleCheckCanceled()
end

function MatchMaker:OnStoppedLookingForReplacements()
	self:UpdateInMatchControls()
	self:OnRoleCheckCanceled()
	self:DisplayPendingInfo(false)
end

function MatchMaker:BuildRoleOptions(eMatchType)
	local wndControls = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls")
	local wndSettings = wndControls:FindChild("PvESettings")
	local nLeft, nTop, nRight, nBottom = wndSettings:GetOriginalLocation():GetOffsets()
	local nNewTop = nTop
	
	local wndContainer = wndControls:FindChild("MasterList")
	local nListLeft, nListTop, nListRight, nListBottom = wndContainer:GetOriginalLocation():GetOffsets()
	local nNewListBottom = nListBottom
	
	if wndControls:FindChild("PvEScalingSettings"):IsShown() then
		nListTop = wndControls:FindChild("PvEScalingSettings"):GetHeight()
	else
		nListTop = 0
	end
	
	local tValidRoles = {}

	local wndRoles = wndSettings:FindChild("CombatRole")
	for idx, eRole in pairs(MatchMakingLib.GetEligibleRoles()) do
		tValidRoles[eRole] = true
	end

	local wndRoleDPSBlock = wndRoles:FindChild("DPSBlock")
	local wndRoleDPS = wndRoles:FindChild("DPSBlock:DPS")
	local wndRoleHealerBlock = wndRoles:FindChild("HealerBlock")
	local wndRoleHealer = wndRoles:FindChild("HealerBlock:Healer")
	local wndRoleTankBlock = wndRoles:FindChild("TankBlock")
	local wndRoleTank = wndRoles:FindChild("TankBlock:Tank")
	
	if tValidRoles[MatchMakingLib.Roles.DPS] then
		wndRoleDPS:Enable(true)
	else
		wndRoleDPS:Enable(false)
		wndRoleDPS:SetTooltip(Apollo.GetString("MatchMaker_RoleClassReq"))
		wndRoleDPSBlock:FindChild("RoleIcon"):SetBGColor("UI_AlphaPercent30")
		wndRoleDPSBlock:FindChild("RoleLabel"):SetTextColor("UI_BtnTextGrayDisabled")
	end
	
	if tValidRoles[MatchMakingLib.Roles.Tank] then
		wndRoleTank:Enable(true)
	else
		wndRoleTank:Enable(false)
		wndRoleTank:SetTooltip(Apollo.GetString("MatchMaker_RoleClassReq"))
		wndRoleTankBlock:FindChild("RoleIcon"):SetBGColor("UI_AlphaPercent30")
		wndRoleTankBlock:FindChild("RoleLabel"):SetTextColor("UI_BtnTextGrayDisabled")
	end
	
	if tValidRoles[MatchMakingLib.Roles.Healer] then
		wndRoleHealer:Enable(true)
	else
		wndRoleHealer:Enable(false)
		wndRoleHealer:SetTooltip(Apollo.GetString("MatchMaker_RoleClassReq"))
		wndRoleHealerBlock:FindChild("RoleIcon"):SetBGColor("UI_AlphaPercent30")
		wndRoleHealerBlock:FindChild("RoleLabel"):SetTextColor("UI_BtnTextGrayDisabled")
	end

	local eMasterTab = ktPvETypes[eMatchType] and keMasterTabs.PvE or keMasterTabs.PvP
	local tSelectedRoles = {}
	if self.tQueueOptions[eMasterTab].arRoles then
		for idx, eRole in pairs(self.tQueueOptions[eMasterTab].arRoles) do
			tSelectedRoles[eRole] = true
		end
	end

	wndRoleDPS:SetCheck(tValidRoles[MatchMakingLib.Roles.DPS] and tSelectedRoles[MatchMakingLib.Roles.DPS])
	wndRoleTank:SetCheck(tValidRoles[MatchMakingLib.Roles.Tank] and tSelectedRoles[MatchMakingLib.Roles.Tank])
	wndRoleHealer:SetCheck(tValidRoles[MatchMakingLib.Roles.Healer] and tSelectedRoles[MatchMakingLib.Roles.Healer])

	wndRoleDPS:SetData(MatchMakingLib.Roles.DPS)
	wndRoleTank:SetData(MatchMakingLib.Roles.Tank)
	wndRoleHealer:SetData(MatchMakingLib.Roles.Healer)
	
	local wndShiphandOptions = wndSettings:FindChild("ShiphandOptions")
	if eMatchType == MatchMakingLib.MatchType.Shiphand or eMatchType == MatchMakingLib.MatchType.WorldStory or eMatchType == MatchMakingLib.MatchType.PrimeLevelExpedition then
		wndShiphandOptions:Show(true)

		local bForceDoNotFindOthers = false
		if eMatchType == MatchMakingLib.MatchType.PrimeLevelExpedition then
			for idx = 1, #self.arMatchesToQueue do
				if not self.arMatchesToQueue[idx]:IsRandom() then
					bForceDoNotFindOthers = true
					break
				end
			end
		end
		
		if bForceDoNotFindOthers then
			wndShiphandOptions:FindChild("DontFindOthers"):SetCheck(true)
			wndSettings:FindChild("DontFindOthersBlocker"):Show(true)
		else
			wndShiphandOptions:FindChild("DontFindOthers"):SetCheck(not self.tQueueOptions[keMasterTabs.PvE].bFindOthers)
			wndSettings:FindChild("DontFindOthersBlocker"):Show(false)
		end
	else
		local nShiphandHeight = wndShiphandOptions:GetHeight()
		nNewTop = nTop + nShiphandHeight
		nNewListBottom = nListBottom + nShiphandHeight	
	end
	
	wndSettings:Show(true)

	wndSettings:SetAnchorOffsets(nLeft, nNewTop, nRight, nBottom)
	wndContainer:SetAnchorOffsets(nListLeft, nListTop , nListRight, nNewListBottom)
end

function MatchMaker:HideRoleOptions()
	local wndControls = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls")
	local wndSettings = wndControls:FindChild("PvESettings")
	local nLeft, nTop, nRight, nBottom = wndSettings:GetOriginalLocation():GetOffsets()
	local nNewTop = nTop
	
	local wndContainer = wndControls:FindChild("MasterList")
	local nListLeft, nListTop, nListRight, nListBottom = wndContainer:GetOriginalLocation():GetOffsets()
	local nNewListBottom = nListBottom
	
	if wndControls:FindChild("PvEScalingSettings"):IsShown() then
		nListTop = wndControls:FindChild("PvEScalingSettings"):GetHeight()
	else
		nListTop = 0
	end
	
	wndContainer:SetAnchorOffsets(nListLeft, nListTop, nListRight, nListBottom + (nBottom - nTop))
	wndSettings:Show(false)
end

-----------------------------------------------------------------------------------------------
-- Setting up Arena Controls
-----------------------------------------------------------------------------------------------
function MatchMaker:BuildArenaControls()
	self.tWndRefs.wndMain:FindChild("TabContent:QuestContent"):Show(false)
	self.tWndRefs.wndMain:FindChild("TabContent:MatchContent"):Show(true)
	
	self.ePvPTabSelected = MatchMakingLib.MatchType.OpenArena
	
	local wndContent = self.tWndRefs.wndMain:FindChild("MatchContent")
	local wndControls = wndContent:FindChild("Controls")
	local wndContainer = wndControls:FindChild("MasterList")
	wndContainer:DestroyChildren()
	
	self:BuildRoleOptions(MatchMakingLib.MatchType.OpenArena)
	
	local wndArenaList = Apollo.LoadForm(self.xmlDoc, "ArenaEntry", wndContainer, self)
	
	-- Set up Open Arenas
	local wndOpenArenas = wndArenaList:FindChild("OpenArenas")
	local tOpenArenaWindows =
	{
		[2] = wndOpenArenas:FindChild("2v2"),
		[3] = wndOpenArenas:FindChild("3v3"),
		[5] = wndOpenArenas:FindChild("5v5"),
	}
	
	local nPlayerLevel = GameLib.GetPlayerLevel(true)
	for nTeamSize, wndArena in pairs(tOpenArenaWindows) do	
		if self.tMatchList[MatchMakingLib.MatchType.OpenArena][nTeamSize].matchNormal then
			wndArena:SetData(self.tMatchList[MatchMakingLib.MatchType.OpenArena][nTeamSize].matchNormal)
			wndArena:FindChild("MatchSelection"):SetData(self.tMatchList[MatchMakingLib.MatchType.OpenArena][nTeamSize].matchNormal)
			wndArena:FindChild("MatchSelection"):Enable(self.tMatchList[MatchMakingLib.MatchType.OpenArena][nTeamSize].matchNormal:GetInfo().nMinLevel <= nPlayerLevel)
		else
			wndArena:FindChild("MatchSelection"):Enable(false)
		end
	end
	
	-- Set up Rated Arenas
	local wndRatedArenas = wndArenaList:FindChild("RatedArenas")
	local tRatedArenas =
	{
		[2] = wndRatedArenas:FindChild("2v2"),
		[3] = wndRatedArenas:FindChild("3v3"),
		[5] = wndRatedArenas:FindChild("5v5"),
	}
	
	for nTeamSize, wndRated in pairs(tRatedArenas) do
		if self.tMatchList[MatchMakingLib.MatchType.OpenArena][nTeamSize].matchVet then
			wndRated:SetData(self.tMatchList[MatchMakingLib.MatchType.OpenArena][nTeamSize].matchVet)
			wndRated:FindChild("MatchSelection"):SetData(self.tMatchList[MatchMakingLib.MatchType.OpenArena][nTeamSize].matchVet)
	
			local guildArenaTeam = self.tHasGuild[ktPvPGuildToTeamSize[nTeamSize]]
			if guildArenaTeam then
				wndRated:FindChild("MatchSelection"):Enable(true)
				wndRated:FindChild("MatchSelection"):SetTooltip("")
				wndRated:FindChild("TeamName"):Show(true)
				wndRated:FindChild("TeamName"):SetTextRaw(String_GetWeaselString(Apollo.GetString("Nameplates_GuildDisplay"), guildArenaTeam:GetName()))
				wndRated:FindChild("Rating"):Show(true)
				wndRated:FindChild("Rating"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_Rating"), guildArenaTeam:GetPvpRatings().nRating))
			else
				wndRated:FindChild("MatchSelection"):Enable(false)
				wndRated:FindChild("MatchSelection"):SetTooltip(Apollo.GetString("MatchMaker_RatedArenaTeamReq"))
				wndRated:FindChild("TeamName"):Show(false)
				wndRated:FindChild("Rating"):Show(false)
			end
		end
	end
	
	local nIndex = nil
	
	for idx, tMatchInfo in pairs(tRatedArenas) do
		if not nIndex or nIndex > idx then
			nIndex = idx
		end
	end
	
	local matchDisplayed = self.tMatchList[MatchMakingLib.MatchType.OpenArena][nIndex].matchNormal
	
	if self.matchDisplayed then
		local eMatchType = self.matchDisplayed:GetInfo().eMatchType
	
		if eMatchType == MatchMakingLib.MatchType.OpenArena or eMatchType == MatchMakingLib.MatchType.Arena then
			matchDisplayed = self.matchDisplayed
		end
	end
	
	wndControls:FindChild("MasterList"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	self:ResizeBlocker()
	self:ValidateQueueButtons()
end

-----------------------------------------------------------------------------------------------
-- Setting up Warplot Controls
-----------------------------------------------------------------------------------------------
function MatchMaker:BuildWarplotControls()
	self.tWndRefs.wndMain:FindChild("TabContent:QuestContent"):Show(false)
	self.tWndRefs.wndMain:FindChild("TabContent:MatchContent"):Show(true)
	
	local wndContent = self.tWndRefs.wndMain:FindChild("MatchContent")
	local wndControls = wndContent:FindChild("Controls")
	local matchWarplot = nil
	local nTeamSize = 0
	
	self.ePvPTabSelected = MatchMakingLib.MatchType.Warplot
	
	-- There should only be one
	for idx, tMatchInfo in pairs (self.tMatchList[MatchMakingLib.MatchType.Warplot]) do
		matchWarplot = tMatchInfo.matchVet
		nTeamSize = idx
	end
	
	self.arMatchesToQueue = {matchWarplot}
	
	local wndContainer = wndControls:FindChild("MasterList")
	wndContainer:DestroyChildren()
	
	self:BuildRoleOptions(MatchMakingLib.MatchType.Warplot)
	
	local bCanQueue = GameLib.GetPlayerLevel() >= matchWarplot:GetInfo().nMinLevel
	
	local wndWarplotSettings = Apollo.LoadForm(self.xmlDoc, "WarplotEntry", wndContainer, self)
	wndWarplotSettings:FindChild("Mercenary"):SetCheck(self.tQueueOptions[keMasterTabs.PvP].bAsMercenary or false)
	wndWarplotSettings:FindChild("MercenaryContainer"):SetData(matchWarplot)

	if bCanQueue then
		wndWarplotSettings:FindChild("Mercenary"):Enable(true)
		wndWarplotSettings:FindChild("Mercenary"):SetTooltip("")
	else
		wndWarplotSettings:FindChild("Mercenary"):Enable(false)
		wndWarplotSettings:FindChild("Mercenary"):SetTooltip(String_GetWeaselString(Apollo.GetString("CRB_LevelReqParticipation"), matchWarplot:GetInfo().nMinLevel, Apollo.GetString("MatchMaker_Warplots")))
	end
	
	local guildWarparty = self.tHasGuild[ktPvPGuildToTeamSize[nTeamSize]]
	local bCanQueueWarparty = bCanQueue and guildWarparty and guildWarparty:GetRanks()[guildWarparty:GetMyRank()].bCanQueueTheWarparty
	
	wndWarplotSettings:FindChild("Warparty"):Enable(bCanQueueWarparty)
	wndWarplotSettings:FindChild("Warparty"):SetCheck(bCanQueueWarparty and not self.tQueueOptions[keMasterTabs.PvP].bAsMercenary)
	wndWarplotSettings:FindChild("WarpartyContainer"):SetData(matchWarplot)
	
	self.matchDisplayed = matchWarplot

	self:ResizeBlocker()
	self:ValidateQueueButtons()
end

-----------------------------------------------------------------------------------------------
-- Featured Tab (Reward Rotations)
-----------------------------------------------------------------------------------------------
function MatchMaker:BuildFeaturedList(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:OnCloseMatchInfo()
	self.tWndRefs.wndMain:FindChild("TabContent:QuestContent"):Show(false)
	self.tWndRefs.wndMain:FindChild("TabContent:MatchContent"):Show(false)
	
	self.tWndRefs.wndMain:FindChild("PvETab"):Show(false)
	self.tWndRefs.wndMain:FindChild("PvPTab"):Show(false)
	
	local wndRewardContent = self.tWndRefs.wndMain:FindChild("TabContent:RewardContent")
	wndRewardContent:Show(true)
	
	self.tWndRefs.wndMain:FindChild("FeaturedTab"):Show(true)
	wndRewardContent:DestroyChildren()
	
	for idx, nContentType in pairs(GameLib.CodeEnumRewardRotationContentType) do
		GameLib.RequestRewardUpdate(nContentType)
	end
	
	local arRewardRotations = GameLib.GetRewardRotations()	
		
	local arRewardList = {}
	local nContentFilterType = self.tWndRefs.wndContentFilter:GetData()
	
	for idx, tRewardRotation in pairs(arRewardRotations) do
		if nContentFilterType == knFilterAll or tRewardRotation.nContentType == nContentFilterType then
			local tTempRewardList = self:BuildRewardsList(tRewardRotation)
			for idx, tRewardEntry in pairs(tTempRewardList) do
				table.insert(arRewardList, tRewardEntry)
			end
		end
	end
	
	--sort
	arRewardList = self:GetSortedRewardList(arRewardList)
	
	for idx, tRewardListEntry in pairs(arRewardList) do
		self:BuildFeaturedControl(wndRewardContent, tRewardListEntry)
	end
	
	wndRewardContent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function MatchMaker:GetSortedRewardList(arRewardList)
	if self.tWndRefs.wndFeaturedSort:GetData() == keFeaturedSort.ContentType then
		local function fnRewardEntrySortContent(tInfoA, tInfoB)
			return tInfoA.nContentType < tInfoB.nContentType
		end
		table.sort(arRewardList, fnRewardEntrySortContent)
	else
		local function fnRewardEntrySortTimeRemaining(tInfoA, tInfoB)
			return tInfoA.nSecondsRemaining < tInfoB.nSecondsRemaining
		end
		table.sort(arRewardList, fnRewardEntrySortTimeRemaining)
	end

	return arRewardList
end

function MatchMaker:BuildRewardsList(tRewardRotation)
	local arRewardList = {}	
	for idx, tReward in pairs(tRewardRotation.arRewards) do
		if not ( tReward.nRewardType == GameLib.CodeEnumRewardRotationRewardType.Essence and tReward.nMultiplier < 2 ) then
			local strName = ""
			local peRewardEvent = nil
			if tRewardRotation.nContentType == GameLib.CodeEnumRewardRotationContentType.Dungeon or tRewardRotation.nContentType == GameLib.CodeEnumRewardRotationContentType.Expedition or tRewardRotation.nContentType == GameLib.CodeEnumRewardRotationContentType.PvP or tRewardRotation.nContentType == GameLib.CodeEnumRewardRotationContentType.DungeonNormal then
				if tRewardRotation.strWorld ~= nil then		
					strName = tRewardRotation.strWorld
				else
					strName = ktTypeNames[tRewardRotation.eMatchType]
				end
			elseif tRewardRotation.nContentType == GameLib.CodeEnumRewardRotationContentType.PeriodicQuest then
				strName = tRewardRotation.strZoneName
			elseif tRewardRotation.nContentType == GameLib.CodeEnumRewardRotationContentType.WorldBoss and tRewardRotation.peWorldBoss then
				strName = tRewardRotation.peWorldBoss:GetName()
				peRewardEvent = tRewardRotation.peWorldBoss
			end
			
			local tRewardEntry = 
			{
				nContentType = tRewardRotation.nContentType,
				nMatchType = tRewardRotation.nMatchType,
				bIsVeteran = tRewardRotation.bIsVeteran,
				strContentName = strName,
				nSecondsRemaining = tReward.nSecondsRemaining,
				tRewardInfo = tReward,
				peEvent = peRewardEvent,
			}
		   
			table.insert(arRewardList, tRewardEntry)
		end
	end	
	return arRewardList
end

function MatchMaker:BuildFeaturedControl(wndParent, tRewardListEntry)
	local wndRewardPickContainer = Apollo.LoadForm(self.xmlDoc, "RewardPick", wndParent, self)
	
	wndRewardPickContainer:FindChild("InfoButton"):SetData(tRewardListEntry)
	local strButtonText = ""
	if tRewardListEntry.nContentType == GameLib.CodeEnumRewardRotationContentType.PeriodicQuest then
		strButtonText = Apollo.GetString("MatchMaker_ViewInfo")
	elseif tRewardListEntry.nContentType == GameLib.CodeEnumRewardRotationContentType.Dungeon or tRewardListEntry.nContentType == GameLib.CodeEnumRewardRotationContentType.Expedition or tRewardListEntry.nContentType == GameLib.CodeEnumRewardRotationContentType.DungeonNormal then
		strButtonText = Apollo.GetString("MatchMaker_ViewQueue")
	elseif tRewardListEntry.nContentType == GameLib.CodeEnumRewardRotationContentType.WorldBoss then
		strButtonText = Apollo.GetString("MatchMaker_ViewMap")
	elseif tRewardListEntry.nContentType == GameLib.CodeEnumRewardRotationContentType.PvP then
		strButtonText = Apollo.GetString("MatchMaker_ViewQueue")
	else
		strButtonText = Apollo.GetString("MatchMaker_ViewInfo")
	end
	
	wndRewardPickContainer:FindChild("InfoButton"):SetText(strButtonText)
	wndRewardPickContainer:FindChild("ContentName"):SetText(String_GetWeaselString(Apollo.GetString("CRB_ColonLabelValue"), ktContentTypeString[tRewardListEntry.nContentType], tRewardListEntry.strContentName))

	local wndTimeRemaining = wndRewardPickContainer:FindChild("TimeRemaining")
	if tRewardListEntry.nSecondsRemaining == nil or tRewardListEntry.nSecondsRemaining < 900 then
		wndTimeRemaining:SetTextColor("UI_WindowTextOrange")
	else
		wndTimeRemaining:SetTextColor("UI_TextHoloBodyCyan")
	end
	
	wndTimeRemaining:SetText(self:HelperConvertToTimeTilExpired(tRewardListEntry.nSecondsRemaining))
	
	wndRewardPickContainer:FindChild("TypeIcon"):SetSprite(ktContentTypeIcons[tRewardListEntry.nContentType])
	wndRewardPickContainer:FindChild("TypeIcon"):SetTooltip(ktContentTypeString[tRewardListEntry.nContentType])
	
	local wndRewardIconContainer = wndRewardPickContainer:FindChild("RewardIconContainer")
	self:BuildRewardContainer(wndRewardIconContainer, tRewardListEntry.tRewardInfo)
	wndRewardIconContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)
	wndRewardPickContainer:Show(true)
end

function MatchMaker:HelperConvertToTimeTilExpired(nSeconds)
	local tTimeData =
	{
		["name"]	= "",
		["count"]	= nil,
	}
	
	strTime = ""
	if nSeconds == nil or nSeconds == 0 then
		tTimeData["name"] = Apollo.GetString("CRB_Min")
		tTimeData["count"] = 0
		strTime = strTime.." "..String_GetWeaselString(Apollo.GetString("MatchMaker_Count"), tTimeData)
		return String_GetWeaselString(Apollo.GetString("MatchMaker_ExpiresIn"), strTime)
	end
	
	local nYears = math.floor(nSeconds / 60 / 60 / 24 / 365)
	if nYears > 0 then
		tTimeData["name"] = Apollo.GetString("CRB_Year")
		tTimeData["count"] = nYears
		strTime = strTime.." "..String_GetWeaselString(Apollo.GetString("MatchMaker_Count"), tTimeData)
		nSeconds = nSeconds - (nYears * 365 * 24 * 60 * 60)
	end
		
	local nMonths = math.floor(nSeconds / 60 / 60 / 24 / 30)
	if nMonths > 0 then
		tTimeData["name"] = Apollo.GetString("CRB_Month")
		tTimeData["count"] = nMonths
		strTime = strTime.." "..String_GetWeaselString(Apollo.GetString("MatchMaker_Count"), tTimeData)
		nSeconds = nSeconds - (nMonths * 30 * 24 * 60 * 60)		
	end
	
	local continueFidelity = true
	if nYears > 0 then
		continueFidelity = false
	end
	
	local nWeeks = math.floor(nSeconds / 60 / 60 / 24 / 7)
	if nWeeks > 0 and continueFidelity then
		tTimeData["name"] = Apollo.GetString("CRB_Week")
		tTimeData["count"] = nWeeks
		strTime = strTime.." "..String_GetWeaselString(Apollo.GetString("MatchMaker_Count"), tTimeData)
		nSeconds = nSeconds - (nWeeks * 7 * 24 * 60 * 60)
	end
	
	if nMonths > 0 then
		continueFidelity = false
	end
	
	local nDaysRounded = math.floor(nSeconds / 60 / 60 / 24)
	if nDaysRounded > 0 and continueFidelity then
		tTimeData["name"] = Apollo.GetString("CRB_Day")
		tTimeData["count"] = nDaysRounded
		strTime = strTime.." "..String_GetWeaselString(Apollo.GetString("MatchMaker_Count"), tTimeData)
		nSeconds = nSeconds - (nDaysRounded * 24 * 60 * 60)
	end	
		
	if nDaysRounded > 1 or nWeeks > 0 then
		continueFidelity = false
	end
		
	local nHoursRounded = math.floor(nSeconds / 60 / 60)
	if nHoursRounded > 0 and continueFidelity then
		tTimeData["name"] = Apollo.GetString("CRB_Hour")
		tTimeData["count"] = nHoursRounded
		strTime = strTime.." "..String_GetWeaselString(Apollo.GetString("MatchMaker_Count"), tTimeData)
		nSeconds = nSeconds - (nHoursRounded * 60 * 60)
	end
	
	if nHoursRounded > 1 or nDaysRounded > 0 then
		continueFidelity = false
	end
	
	local nMinutes = math.floor(nSeconds / 60)
	if nMinutes > 0 and continueFidelity then
		tTimeData["name"] = Apollo.GetString("CRB_Min")
		tTimeData["count"] = nMinutes
		strTime = strTime.." "..String_GetWeaselString(Apollo.GetString("MatchMaker_Count"), tTimeData)
		nSeconds = nSeconds - (nMinutes * 60)
	end
	
	if nMinutes >= 1 or nHoursRounded > 0 then
		continueFidelity = false
	end
	
	if nSeconds > 0 and continueFidelity then
		strTime = Apollo.GetString("MatchMaker_LessThanMinute")
	end
	
	return String_GetWeaselString(Apollo.GetString("MatchMaker_ExpiresIn"), strTime)
end


function MatchMaker:BuildRewardContainer(wndParent, tRewardInfo, bUseLabel)
	if tRewardInfo == nil then
		return
	end

	local wndRewardIconEntry
	if bUseLabel then
		wndRewardIconEntry = Apollo.LoadForm(self.xmlDoc, "RewardIconTextEntry", wndParent, self)
	else
		wndRewardIconEntry = Apollo.LoadForm(self.xmlDoc, "RewardIconEntry", wndParent, self)
	end
	
	local strRewardSprite = "CRB_Basekit:kitIcon_White_QuestionMark"
	wndRewardIconEntry:SetData(tRewardInfo)
	
	if tRewardInfo.strIcon and tRewardInfo.strIcon ~= "" then
		strRewardSprite = tRewardInfo.strIcon
	end
	
	if tRewardInfo.itemReward then
		local luaSubclass = wndRewardIconEntry:FindChild("RewardIcon"):GetWindowSubclass()
		luaSubclass:SetItem(tRewardInfo.itemReward)
	end	
	
	wndRewardIconEntry:FindChild("RewardIcon"):SetSprite(strRewardSprite)
	local wndRewardMultiplier = wndRewardIconEntry:FindChild("RewardMultiplier")
	if tRewardInfo.nMultiplier and tRewardInfo.nMultiplier > 1 then
		wndRewardMultiplier:SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_RewardMultiplierValue"), tRewardInfo.nMultiplier))
		wndRewardMultiplier:SetTooltip(String_GetWeaselString(Apollo.GetString("RewardRotation_MultiplierTooltip"), tRewardInfo.monReward:GetTypeString(), tRewardInfo.nMultiplier))
		wndRewardMultiplier:Show(true)
	elseif tRewardInfo.nRewardType == GameLib.CodeEnumRewardRotationRewardType.Modifier then
		wndRewardMultiplier:SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_RewardMultiplierValue"), tRewardInfo.nValue))
		wndRewardMultiplier:Show(true)		
	else
		wndRewardMultiplier:Show(false)
	end
	
	if bUseLabel then
		local wndLabel = wndRewardIconEntry:FindChild("Label")
		local strLabel = ""
		
		if tRewardInfo.nRewardType == GameLib.CodeEnumRewardRotationRewardType.Item and tRewardInfo.itemReward then
			strLabel = tRewardInfo.itemReward:GetName()
		elseif tRewardInfo.monReward ~= nil then
			strLabel = tRewardInfo.monReward:GetMoneyString()
			if tRewardInfo.nMultiplier then
				strLabel = tRewardInfo.monReward:GetTypeString()
			end
		end

		wndLabel:SetText(strLabel)
	end
	
	return wndRewardIconEntry
end

-----------------------------------------------------------------------------------------------
-- Non-Arenas, Warplots, or Quests (aka "the simple stuff")
-----------------------------------------------------------------------------------------------
function MatchMaker:BuildMatchList(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:OnCloseMatchInfo()
	self.tWndRefs.wndMain:FindChild("TabContent:QuestContent"):Show(false)
	self.tWndRefs.wndMain:FindChild("TabContent:MatchContent"):Show(true)
	
	self.arMatchesToQueue = {}
	
	local eMatchType = wndHandler:GetData()
	
	local wndScalingOptions = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls:PvEScalingSettings")
	local wndMasterList = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls:MasterList")
	local wndPrimeLevelsBtn = wndScalingOptions:FindChild("PrimeLevels:PrimeLevelsBtn")

	if self.tPrimeLevelMatchTypes[eMatchType] and not wndScalingOptions:IsShown() then
		wndScalingOptions:Show(true)
		local nScalingOptionsHeight = wndScalingOptions:GetHeight()
		
		local nLeft, nTop, nRight, nBottom = wndMasterList:GetOriginalLocation():GetOffsets()
		wndMasterList:SetAnchorOffsets(nLeft, nScalingOptionsHeight, nRight, nBottom)
		
		local wndFixedLevelsBtn = wndScalingOptions:FindChild("FixedLevels:FixedLevelsBtn")
		if not wndFixedLevelsBtn:IsChecked() and not wndPrimeLevelsBtn:IsChecked() then
			wndFixedLevelsBtn:SetCheck(true)
		end
	elseif not self.tPrimeLevelMatchTypes[eMatchType] then
		self.tWndRefs.wndMain:FindChild("PrimeLevelsBtn"):SetCheck(false)
		self.tWndRefs.wndMain:FindChild("FixedLevelsBtn"):SetCheck(true)
		
		if wndScalingOptions:IsShown() then
			wndScalingOptions:Show(false)
			local nLeft, nTop, nRight, nBottom = wndMasterList:GetOriginalLocation():GetOffsets()
			wndMasterList:SetAnchorOffsets(nLeft, 0, nRight, nBottom)
		end
	end

	if ktPvETypes[eMatchType] then
		self.ePvETabSelected = eMatchType
	else
		self.ePvPTabSelected = eMatchType
	end
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer and unitPlayer:GetLevel() == GameLib.GetLevelCap() then
		wndPrimeLevelsBtn:Enable(true)
		wndPrimeLevelsBtn:SetTooltip("")
	else
		wndPrimeLevelsBtn:Enable(false)
		wndPrimeLevelsBtn:SetTooltip(Apollo.GetString("MatchMaker_FeaturedContentDisabledTooltip"))
	end
	
	if eMatchType == knQuestTabId then
		self:BuildQuestList()
	elseif eMatchType == MatchMakingLib.MatchType.Warplot then
		self:BuildWarplotControls()
	elseif eMatchType == MatchMakingLib.MatchType.OpenArena or eMatchType == MatchMakingLib.MatchType.Arena then
		self:BuildArenaControls()
	elseif wndPrimeLevelsBtn:IsChecked() then
		self:BuildPrimeLevelMatchControls(eMatchType)
	else
		self:BuildMatchControls(eMatchType)
	end
	
	if eMatchType ~= knQuestTabId then
		self:BuildMatchIntro(eMatchType)
		self:CheckQueuePenalties()
		self:UpdateInMatchControls()
	end
end

function MatchMaker:BuildMatchIntro(eMatchType)
	if not ktTypeIntros[eMatchType] then
		return
	end
	
	local bIsPrime = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls:PvEScalingSettings:PrimeLevels:PrimeLevelsBtn"):IsChecked() and true or false
	
	local wndParent = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchTypeInfo")
	local wndTextContainer = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchTypeInfo:TextContainer")
	local strSprite = ktTypeIntros[eMatchType].strBackground
	
	wndParent:SetSprite(strSprite)
	wndTextContainer:FindChild("Title"):SetText(ktTypeNames[eMatchType])
	wndTextContainer:FindChild("ScalingLabel"):SetText(bIsPrime and Apollo.GetString("Matching_PrimeLevels") or Apollo.GetString("Matching_NormalVet"))
	local strStats = ""
	local strDesc = ""
	if #ktTypeIntros[eMatchType].arStats > 0 then
		for idx, strStat in ipairs(ktTypeIntros[eMatchType].arStats) do
			strStats = string.format("%s <P Font=\"CRB_Header10\" TextColor=\"UI_TextHoloTitle\">%s</P>", strStats, strStat)
		end
	end
	
	wndTextContainer:FindChild("Stats"):SetAML(strStats)
	wndTextContainer:FindChild("Stats"):SetHeightToContentHeight()
	
	if bIsPrime then
		wndTextContainer:FindChild("ScalingLabel"):SetText(Apollo.GetString("Matching_PrimeLevels"))
		for ePrimeMatchType, eNormalMatchType in pairs(ktPvEPrimeLevelTypes) do
			if eNormalMatchType == eMatchType then
				eMatchType = ePrimeMatchType
				break
			end
		end

		self:BuildPrimeProgress(eMatchType)
	else 
		wndTextContainer:FindChild("ScalingLabel"):SetText("")
		
		if #ktTypeIntros[eMatchType].arDescription > 0 then
			for idx, strParagraph in ipairs(ktTypeIntros[eMatchType].arDescription) do	
				strDesc = string.format("%s%s\n\n", strDesc, strParagraph)
			end
		end
		
		wndTextContainer:FindChild("Description"):DestroyChildren()
		wndTextContainer:FindChild("Description"):SetText(strDesc)	
	end	
	
	wndTextContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function MatchMaker:BuildPrimeProgress(eMatchType)
	local wndTextContainer = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchTypeInfo:TextContainer")
	local wndDescription = wndTextContainer:FindChild("Description")
	local arMatchOrder = self:GetSortedMatches(eMatchType)
	local nContentHeight = 0
	
	wndDescription:SetText("")
	wndDescription:DestroyChildren()

	for idx = 1, #arMatchOrder do
		local wndInstance = Apollo.LoadForm(self.xmlDoc, "PrimeProgressEntry", wndDescription, self)
		local matchInfo = arMatchOrder[idx].matchVet
		local tblMatchInfo = matchInfo:GetInfo()
		local nMaxUnlocked= GameLib.GetPrimeLevelAchieved(tblMatchInfo.nGameId)
		wndInstance:FindChild("InstanceName"):SetText(tblMatchInfo.strName)
		wndInstance:FindChild("MaxUnlocked"):SetText(nMaxUnlocked)
		wndInstance:FindChild("MaxUnlocked"):SetTooltip(String_GetWeaselString(Apollo.GetString("MatchMaker_PrimeMaxLevel"), tblMatchInfo.strName, nMaxUnlocked))
		nContentHeight = nContentHeight + wndInstance:GetHeight()
	end
	
	local nDescriptionLeft, nDescriptionTop, nDescriptionRight, nDescriptionBottom = wndDescription:GetAnchorOffsets()
	wndDescription:SetAnchorOffsets(nDescriptionLeft, nDescriptionTop, nDescriptionRight, nDescriptionTop + nContentHeight )
	wndDescription:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		
end

function MatchMaker:OnCloseMatchInfo()
	local wndInfo = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchInfo")
	
	if wndInfo:IsVisible() then
		local matchInfo = wndInfo:GetData()
		local wndMasterList = self.tWndRefs.wndMain:FindChild("MasterList")
		local matchSelected
		
		if matchInfo:IsRandom() then
			matchSelected = wndMasterList:FindChild("RightColumn"):FindChildByUserData(matchInfo)
		else
			matchSelected = wndMasterList:FindChildByUserData(matchInfo)
		end
		if matchSelected ~= nil then
			matchSelected:SetCheck(false)
		end
		wndInfo:Show(false)
	end 
end

function MatchMaker:GetSortedMatches(eMatchType)
	local arMatchOrder = {}
	if ktRatedToNormal[eMatchType] then
		eMatchType = ktRatedToNormal[eMatchType]
	end

	for idGame, tMatchInfo in pairs(self.tMatchList[eMatchType]) do
		if idGame ~= knRandomMatchIndex then
			table.insert(arMatchOrder, tMatchInfo)
		end
	end
	
	-- Sort the arrays for draw order
	local function fnMatchSort(tInfoA, tInfoB)
		local matchA = tInfoA.matchNormal
		local matchB = tInfoB.matchNormal
		
		if not matchA and not matchB then
			matchA = tInfoA.matchVet
			matchB = tInfoB.matchVet
		end
		
		-- If it's veteran only, then we want it after the list of normal / veteran combinations.  Otherwise, we want it sorted by min level.
		if matchB == nil then
			return true
		elseif matchA and matchB then
			if matchA:GetInfo().nMinLevel == matchB:GetInfo().nMinLevel then
				if matchA:GetInfo().nPrimeTier and matchB:GetInfo().nPrimeTier then
					return matchA:GetInfo().nPrimeTier < matchB:GetInfo().nPrimeTier
				end
				return false
			else
				return matchA:GetInfo().nMinLevel < matchB:GetInfo().nMinLevel
			end
		else
			return false
		end
		
		return matchB == nil or (matchA and matchB and matchA:GetInfo().nMinLevel < matchB:GetInfo().nMinLevel) or false
	end

	table.sort(arMatchOrder, fnMatchSort)
	return arMatchOrder
end

function MatchMaker:BuildMatchControls(eMatchType)
	-- Build the arrays of matches for the given type
	local arMatchOrder = self:GetSortedMatches(eMatchType)

	-- Check if the match type is rallied
	local bIsRallied = ktRalliedContentTypes[eMatchType] or false

	-- Clear the existing windows
	local wndControls = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls")
	local wndContainer = wndControls:FindChild("MasterList")
	wndContainer:DestroyChildren()
	
	-- Set up check for presence of any available instances
	local wndContainerBlocker = wndControls:FindChild("NoInstanceBlocker")
	local bHaveMatches = #arMatchOrder > 0
	
	local wndRandomHeader = self:BuildRandomHeader(eMatchType, wndContainer, arMatchOrder)
	if wndRandomHeader then
		bHaveMatches = true
	end
	
	if bHaveMatches then
		local wndMatchTypeContainer = self:BuildMatchTypeContainer(eMatchType, wndContainer, arMatchOrder)
		wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		wndMatchTypeContainer:FindChild("RallyIndicator"):Show(bIsRallied)	

		local wndDropdown = wndMatchTypeContainer:FindChild("ListDropdown")
		self:ToggleMatchHeader(wndDropdown, wndDropdown)
		
		self:BuildRoleOptions(eMatchType)
	
		self:ResizeBlocker()
		self:ValidateQueueButtons()
		wndContainerBlocker:Show(false)
	else
		wndContainerBlocker:Show(true)
	end
end

function MatchMaker:BuildPrimeLevelMatchControls(eMatchType)
	-- convert match type to a prime level match type
	for ePrimeMatchType, eNormalMatchType in pairs(ktPvEPrimeLevelTypes) do
		if eNormalMatchType == eMatchType then
			eMatchType = ePrimeMatchType
			break
		end
	end

	-- Build the arrays of matches for the given type
	local arMatchOrder = self:GetSortedMatches(eMatchType)

	-- Clear the existing windows
	local wndControls = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls")
	local wndContainer = wndControls:FindChild("MasterList")
	wndContainer:DestroyChildren()
	
	-- Set up check for presence of any available instances
	local wndContainerBlocker = wndControls:FindChild("NoInstanceBlocker")
	local bHaveMatches = #arMatchOrder > 0
	
	local wndRandomHeader = self:BuildRandomHeader(ktPvEPrimeLevelScaledTypes[eMatchType], wndContainer, arMatchOrder)
	if wndRandomHeader then
		local wndDropdown = wndRandomHeader:FindChild("ListDropdown")
		bHaveMatches = true
	end
	
	if bHaveMatches then
		local wndMatchTypeContainer = self:BuildPrimeLevelMatchTypeContainer(eMatchType, wndContainer, arMatchOrder)
		wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		
		local wndDropdown = wndMatchTypeContainer:FindChild("ListDropdown")
		self:ToggleMatchHeader(wndDropdown, wndDropdown)
	
		self:BuildRoleOptions(eMatchType)
		self:ResizeBlocker()
		self:ValidateQueueButtons()
		wndContainerBlocker:Show(false)
	else
		wndContainerBlocker:Show(true)
	end
end

function MatchMaker:BuildPrimeLevelMatchTypeContainer(eMatchType, wndParent, arMatchOrder)
	local wndMatchTypeContainer = Apollo.LoadForm(self.xmlDoc, "MatchTypeContainer", wndParent, self)
	local wndSubTypeContainer = wndMatchTypeContainer:FindChild("MatchEntries")
	
	for idx = 1, #arMatchOrder do
		self:BuildPrimeLevelMatchButton(arMatchOrder[idx], eMatchType, wndSubTypeContainer)
	end	

	wndSubTypeContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	return wndMatchTypeContainer
end

function MatchMaker:BuildMatchTypeContainer(eMatchType, wndParent, arMatchOrder)
	local bHasNormal = false
	local bHasVet = false
	
	for idGame, tMatchInfo in pairs(self.tMatchList[eMatchType]) do		
		if tMatchInfo.matchNormal then
			bHasNormal = true
		end
		
		if tMatchInfo.matchVet then
			bHasVet = true
		end
	end

	local wndMatchTypeContainer = Apollo.LoadForm(self.xmlDoc, "MatchTypeContainer", wndParent, self)
	local wndSubTypeContainer = wndMatchTypeContainer:FindChild("MatchEntries")
	
	if GameLib.GetPlayerLevel(true) == GameLib.GetLevelCap() and bHasVet then
		self:BuildMatchTypeList(eMatchType, wndSubTypeContainer, arMatchOrder, true)
	end

	if bHasNormal then
		self:BuildMatchTypeList(eMatchType, wndSubTypeContainer, arMatchOrder, false)
	end
	
	wndSubTypeContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	return wndMatchTypeContainer
end

function MatchMaker:BuildMatchTypeList(eMatchType, wndParent, arMatchOrder, bIsVeteran)
	if eMatchType ~= MatchMakingLib.MatchType.Adventure then
		for idx = 1, #arMatchOrder do
			self:BuildMatchButton(arMatchOrder[idx], eType, bIsVeteran, wndParent)
		end
		
	else
	local wndHeader = Apollo.LoadForm(self.xmlDoc, "MatchSelectionParent", wndParent, self)
	local wndChildContainer = wndHeader:FindChild("MatchEntries")
	
	for idx = 1, #arMatchOrder do
		self:BuildMatchButton(arMatchOrder[idx], eType, bIsVeteran, wndChildContainer)
		end
	
	wndChildContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	local nLeft, nTop, nRight, nBottom = wndChildContainer:GetOriginalLocation():GetOffsets()
	local nParentLeft, nParentTop, nParentRight, nParentBottom = wndHeader:GetOriginalLocation():GetOffsets()	
	local nHeightOffset = 0
	
	local arMatchWindows = wndChildContainer:GetChildren()
	nHeightOffset = #arMatchWindows * arMatchWindows[1]:GetHeight()
	
	wndHeader:SetAnchorOffsets(nParentLeft, nParentTop, nParentRight, nParentBottom + nHeightOffset + nTop)
	wndChildContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeightOffset)
	
	local wndTitle = wndHeader:FindChild("MatchBtn")
	
	if ktPvETypes[eMatchType] then
		local strBase = Apollo.GetString("MatchMaker_InstanceNormal")
		if bIsVeteran then
			strBase = Apollo.GetString("MatchMaker_Veteran")
		end
	
		wndTitle:SetText(String_GetWeaselString(strBase, ktTypeNames[eMatchType]))
	else
		wndTitle:SetText(ktTypeNames[eMatchType])
	end
	end
end

function MatchMaker:BuildRandomHeader(eMatchType, wndParent)
	local match = nil
	
	if self.tMatchList[eMatchType][knRandomMatchIndex] and self.tMatchList[eMatchType][knRandomMatchIndex].matchVet then
		match = self.tMatchList[eMatchType][knRandomMatchIndex].matchVet
	elseif self.tMatchList[eMatchType][knRandomMatchIndex] and self.tMatchList[eMatchType][knRandomMatchIndex].matchNormal then
		match = self.tMatchList[eMatchType][knRandomMatchIndex].matchNormal
	end
	
	if match == nil then
		return
	end
	
	
	local wndRandomEntry = Apollo.LoadForm(self.xmlDoc, "RandomSelection", wndParent, self)
	local wndSelection = wndRandomEntry:FindChild("MatchSelection")
	local wndTypeLabel = wndRandomEntry:FindChild("TypeLabel")
		
	wndSelection:SetData(match)
	wndTypeLabel:SetData(match)
	
	local tRotationRewards = match:GetRotationRewards()
	local wndRewardIconContainer = wndRandomEntry:FindChild("RewardIconContainer")
	local wndMultipleRewardsIcon = wndRandomEntry:FindChild("MultipleRewardsIcon")
	wndMultipleRewardsIcon:Show(false)
	wndRewardIconContainer:Show(false)
	if tRotationRewards and tRotationRewards.arRewards then
		local nRewardCount = 0
		for idx, tReward in pairs(tRotationRewards.arRewards) do
			if not tReward.bAlreadyGranted then
				wndRewardIconContainer:Show(true)
				self:BuildRewardContainer(wndRewardIconContainer, tReward)
				local wndRewardIconEntry = wndRewardIconContainer:FindChild("RewardIconEntry")
				wndRewardIconEntry:SetAnchorPoints(1,0,1,0)
				wndRewardIconEntry:SetAnchorOffsets(-wndRewardIconContainer:GetWidth(),0,0,wndRewardIconContainer:GetHeight())
				
				local wndRewardIcon = wndRewardIconEntry:FindChild("RewardIcon")
				wndRewardIcon:SetAnchorPoints(0,0,1,1)
				wndRewardIcon:SetAnchorOffsets(0,0,0,0)
				
				local wndRewardIconMultiplier = wndRewardIconEntry:FindChild("RewardMultiplier")
				wndRewardIconMultiplier:SetSprite("")
				wndRewardIconMultiplier:SetAnchorPoints(0,1,1,1)
				wndRewardIconMultiplier:SetAnchorOffsets(0,-15,0,-1)

				nRewardCount = nRewardCount + 1
				if nRewardCount > 1 then
					wndMultipleRewardsIcon:Show(true)
				end
			end
		end
		
		wndRewardIconContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)
	end
	
	local tRewardInfo = match:GetReward()
	if tRewardInfo then
		local wndLabel = wndRandomEntry:FindChild("RewardLabel")
		local wndReward = wndRandomEntry:FindChild("RewardList")
		wndLabel:Show(true)
		wndReward:Show(true)

		if tRewardInfo.itemReward then
			local wndRewardItem = wndReward:FindChild("RewardItem")
			wndRewardItem:GetWindowSubclass():SetItem(tRewardInfo.itemReward)
			Tooltip.GetItemTooltipForm(self, wndRewardItem, tRewardInfo.itemReward, {})
			wndRewardItem:Show(true)
		end

		if tRewardInfo.nXpEarned and tRewardInfo.nXpEarned ~= 0 then
			local wndXPReward = wndReward:FindChild("XpReward")
			wndXPReward:SetTooltip(String_GetWeaselString(Apollo.GetString("CRB_XPAmount"), Apollo.FormatNumber(tRewardInfo.nXpEarned, 0, true)))
			wndXPReward:Show(true)
		end

		if tRewardInfo.monReward then
			local wndCashWindow = wndReward:FindChild("CashWindow")
			wndCashWindow:SetMoneySystem(tRewardInfo.monReward:GetMoneyType())
			wndCashWindow:SetAmount(tRewardInfo.monReward:GetAmount(), true)
			wndCashWindow:Show(true)
		end
	end
	
	wndTypeLabel:SetText(match:GetInfo().strName)
	
	wndRandomEntry:SetData(knRandomMatchIndex)
	return wndRandomEntry
end

function MatchMaker:BuildMatchButton(tblMatch, eMatchType, bIsVeteran, wndParent)
	if not tblMatch then
		return
	end
	
	local matchGame
	if bIsVeteran then
		matchGame = tblMatch.matchVet
	else
		matchGame = tblMatch.matchNormal
	end
	
	if not matchGame then
		return
	end

	local wndOption = Apollo.LoadForm(self.xmlDoc, "MatchSelection", wndParent, self)
	local tblMatchInfo = matchGame:GetInfo()
	local strText = tblMatchInfo.strName
	local nMinLevel = tblMatchInfo.nMinLevel
	local nMaxLevel = tblMatchInfo.nMaxLevel

	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer and unitPlayer:IsHeroismUnlocked() then
		local arRewards = GameLib.GetRewardRotation(tblMatchInfo.nRewardRotationContentId, matchGame:IsVeteran())
		local wndRewardIconContainer = wndOption:FindChild("RewardIconContainer")
		local wndMultipleRewardsIcon = wndOption:FindChild("MultipleRewardsIcon")
		wndMultipleRewardsIcon:Show(false)
		wndRewardIconContainer:Show(false)
		if arRewards then
			for idx, tReward in pairs(arRewards) do
				if tReward.nRewardType == GameLib.CodeEnumRewardRotationRewardType.Essence then
					wndRewardIconContainer:Show(true)
					self:BuildRewardContainer(wndRewardIconContainer, tReward)	
					local wndRewardIconEntry = wndRewardIconContainer:FindChild("RewardIconEntry")
					wndRewardIconEntry:SetAnchorPoints(1,0,1,0)
					wndRewardIconEntry:SetAnchorOffsets(-wndRewardIconContainer:GetWidth(),0,0,wndRewardIconContainer:GetHeight())
					
					local wndRewardIcon = wndRewardIconEntry:FindChild("RewardIcon")
					wndRewardIcon:SetAnchorPoints(0,0,1,1)
					wndRewardIcon:SetAnchorOffsets(2,2,-1,-1)
					
					local wndRewardIconMultiplier = wndRewardIconEntry:FindChild("RewardMultiplier")
					wndRewardIconMultiplier:SetSprite("")
					wndRewardIconMultiplier:SetAnchorPoints(0,1,1,1)
					wndRewardIconMultiplier:SetAnchorOffsets(0,-15,0,-1)
				end
				if idx > 1 then
					wndMultipleRewardsIcon:Show(true)
				end
			end
			
			wndRewardIconContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)
		end
	end
	
	if nMinLevel > 0 then
		if nMinLevel == nMaxLevel or nMaxLevel == GameLib.GetLevelCap() then
			strText = strText .. " (" .. nMinLevel .. ")"
		else
			strText = strText .. " (" .. String_GetWeaselString(Apollo.GetString("MatchMaker_LevelRange"), nMinLevel, nMaxLevel) .. ")"
		end
	end

	local wndInfoButton = wndOption:FindChild("MatchBtn")
	local wndSelection = wndOption:FindChild("SelectMatch")
	if GameLib.GetPlayerUnit():GetLevel() < nMinLevel then
		wndSelection:Enable(false)
		wndInfoButton:Enable(false)
		wndSelection:SetTooltip(Apollo.GetString("PrerequisiteComp_Level"))
	end

	wndInfoButton:SetText(strText)
	wndInfoButton:SetData(matchGame)
	wndSelection:SetData(matchGame)
end

function MatchMaker:BuildPrimeLevelMatchButton(tblMatch, eMatchType, wndParent)
	if not tblMatch then
		return
	end
	
	local matchGame = tblMatch.matchVet
	
	if not matchGame then
		return
	end

	local wndOption = Apollo.LoadForm(self.xmlDoc, "PrimeLevelMatchSelection", wndParent, self)
	local wndInfoButton = wndOption:FindChild("MatchBtn")
	local wndSelection = wndOption:FindChild("SelectMatch")
	local wndLocked = wndOption:FindChild("Locked")

	local tblMatchInfo = matchGame:GetInfo()
	local strText = tblMatchInfo.strName

	local wndRewardIconContainer = wndOption:FindChild("RewardIconContainer")
	local bFound = false	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer and unitPlayer:IsHeroismUnlocked() then
		local arRewards = GameLib.GetRewardRotation(tblMatchInfo.nRewardRotationContentId, true)
		local wndMultipleRewardsIcon = wndOption:FindChild("MultipleRewardsIcon")
		wndMultipleRewardsIcon:Show(false)
		if arRewards then
			for idx, tReward in pairs(arRewards) do
				if tReward.nRewardType == GameLib.CodeEnumRewardRotationRewardType.Essence then
					bFound = true
					self:BuildRewardContainer(wndRewardIconContainer, tReward)	
					local wndRewardIconEntry = wndRewardIconContainer:FindChild("RewardIconEntry")
					wndRewardIconEntry:SetAnchorPoints(1,0,1,0)
					wndRewardIconEntry:SetAnchorOffsets(-wndRewardIconContainer:GetWidth(),0,0,wndRewardIconContainer:GetHeight())
					
					local wndRewardIcon = wndRewardIconEntry:FindChild("RewardIcon")
					wndRewardIcon:SetAnchorPoints(0,0,1,1)
					wndRewardIcon:SetAnchorOffsets(2,2,-1,-1)
					
					local wndRewardIconMultiplier = wndRewardIconEntry:FindChild("RewardMultiplier")
					wndRewardIconMultiplier:SetSprite("")
					wndRewardIconMultiplier:SetAnchorPoints(0,1,1,1)
					wndRewardIconMultiplier:SetAnchorOffsets(0,-15,0,-1)
				end
				if idx > 1 then
					wndMultipleRewardsIcon:Show(true)
				end
			end
			
			wndRewardIconContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)
		end
	end
	wndRewardIconContainer:Show(bFound)	
	
	if tblMatch.nPrimeLevel > 0 then
		strText = strText .. " (" .. String_GetWeaselString(Apollo.GetString("MatchMaker_PrimeLevel"), tblMatch.nPrimeLevel) .. ")"
		wndSelection:Show(true)
		wndSelection:Enable(true)
		wndInfoButton:Enable(true)
		wndLocked:Show(false)
	else
		wndSelection:Show(true)
		wndSelection:Enable(true)
		wndInfoButton:Enable(true)
		wndLocked:Show(false)
	end

	wndInfoButton:SetText(strText)
	wndInfoButton:SetData(matchGame)
	wndSelection:SetData(matchGame)
end

function MatchMaker:ToggleMatchHeader(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndParent = wndHandler:GetParent()
	local wndContainer = wndParent:FindChild("MatchEntries")
	
	local nLeft, nTop, nRight, nBottom = wndContainer:GetOriginalLocation():GetOffsets()
	local nParentLeft, nParentTop, nParentRight, nParentBottom = wndParent:GetOriginalLocation():GetOffsets()
	
	local nHeightOffset = 0
	local arMatchGroupWindows = wndContainer:GetChildren()
	for idx = 1, #arMatchGroupWindows do
		nHeightOffset = nHeightOffset + arMatchGroupWindows[idx]:GetHeight()
	end
	
	wndParent:SetAnchorOffsets(nParentLeft, nParentTop, nParentRight, nParentBottom + nHeightOffset)
	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	wndParent:GetParent():ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	wndContainer:Show(true)
end

function MatchMaker:UpdateAchievements()
	if not self.tWndRefs.wndMain or not self.matchDisplayed then
		return
	end

	local tCategoryInfo = AchievementsLib.GetCategoryForMatchingGame(self.matchDisplayed)
	
	if not tCategoryInfo then
		return
	end
	
	local arAchievements = AchievementsLib.GetAchievementsForCategory(tCategoryInfo.nCategoryId, true)
	
	local wndAchievementContainer = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchInfo:Content:AchievementContainer")
	
	wndAchievementContainer:FindChild("CategoryName"):SetText(tCategoryInfo.strCategoryName)
	
	local wndProgress = wndAchievementContainer:FindChild("ProgressBG:AchievementProgress")
	wndProgress:SetMax(#arAchievements)
	
	local nCompleted = 0
	for idx = 1, #arAchievements do
		if arAchievements[idx]:IsComplete() then
			nCompleted = nCompleted + 1
		end
	end

	wndProgress:SetProgress(nCompleted)
end

function MatchMaker:OnPlayerLevelChange()
	if self.tWndRefs.wndMain then
		self:BuildMatchTable()
		self:RecalculateContents()
		self:UpdateTeamInfo()
	end
end

function MatchMaker:RecalculateContents()
	if not self.tWndRefs.wndMain then
		return
	end
	
	if self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchInfo"):IsShown() then
		self:SetMatchDetails(self.matchDisplayed)
	end
end

-----------------------------------------------------------------------------------------------
-- Match List button functionality
-----------------------------------------------------------------------------------------------
function MatchMaker:OnMatchChecked(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local matchShown = wndHandler:GetData()

	self:SetMatchDetails(matchShown)
end

function MatchMaker:SetMatchDetails(matchSelected)
	local wndInfo = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchInfo")
	
	if not matchSelected then
		wndInfo:Show(false)
		return
	end
	
	self.matchDisplayed = matchSelected
	wndInfo:SetData(matchSelected)
	
	local tMatchInfo = matchSelected:GetInfo()
	local eMatchType = tMatchInfo.eMatchType
	
	if tMatchInfo.nMaxPrimeLevel > 0 then
		self.tWndRefs.wndPrimeLevelBtn:Show(true)
		self.tWndRefs.wndPrimeLevelsUnavailable:Show(false)
		self.tWndRefs.wndPrimeLevelList:DestroyChildren()
		
		local nMyLevel = GameLib.GetPrimeLevelAchieved(tMatchInfo.nGameId)
		local nMaxAvailableLevel = nMyLevel
		if GroupLib.InGroup() then
			nMaxAvailableLevel = GroupLib.GetPrimeLevelAchieved(tMatchInfo.nGameId)
		end
		
		self.tWndRefs.wndPrimeLevelBtn:SetText(Apollo.GetString("MatchMaker_PrimeLevelLabel"))
		
		for nPrimeLevel=0, tMatchInfo.nMaxPrimeLevel do
			local wndPrimeLevel = Apollo.LoadForm(self.xmlDoc, "PrimeLevelEntry", self.tWndRefs.wndPrimeLevelList, self)
			local wndPrimeLevelBtn = wndPrimeLevel:FindChild("Button")
			wndPrimeLevel:SetData(nPrimeLevel)
			
			local label = String_GetWeaselString(Apollo.GetString("MatchMaker_PrimeLevel"), nPrimeLevel)
			if nMaxAvailableLevel < nPrimeLevel then
				wndPrimeLevelBtn:Enable(false)
			end
			
			if nPrimeLevel == self.tMatchList[eMatchType][tMatchInfo.nGameId].nPrimeLevel then
				wndPrimeLevelBtn:SetCheck(true)
				self.tWndRefs.wndPrimeLevelBtn:SetText(label)
			end

			wndPrimeLevelBtn:SetText(label)
		end
		
		self.tWndRefs.wndPrimeLevelList:ArrangeChildrenVert()
	elseif ktPvEPrimeLevelScaledTypes[eMatchType] and matchSelected ~= knRandomMatchIndex then
		self.tWndRefs.wndPrimeLevelBtn:Show(false)
		self.tWndRefs.wndPrimeLevelsUnavailable:Show(true)
	else
		self.tWndRefs.wndPrimeLevelBtn:Show(false)
		self.tWndRefs.wndPrimeLevelsUnavailable:Show(false)
	end
	
	local wndDetails = wndInfo:FindChild("Details")
	
	local strDetails = tMatchInfo.strDescription
	local nRecommendedItemLevel = tMatchInfo.nRecommendedItemLevel
	
	if matchSelected:IsRandom() and self.tMatchList ~= nil then
		local nMaxItemLevel = 0
		local bIsVet = matchSelected:IsVeteran() or ktRatedPvPTypes[eMatchType]
		local tSelectedMatches = {}
		if self.tMatchList[eMatchType] ~= nil then
			tSelectedMatches = self.tMatchList[eMatchType]
		end
		for idx, tMatches in pairs(tSelectedMatches) do
			local matchCurrent = tMatches.matchVet
			if not bIsVet and tMatches.matchNormal ~= nil then
				matchCurrent = tMatches.matchNormal
			end
			
			if matchCurrent ~= nil then
				local nCurrentRecommendedLevel = matchCurrent:GetInfo().nRecommendedItemLevel
				if nCurrentRecommendedLevel and nCurrentRecommendedLevel > nMaxItemLevel then
					nMaxItemLevel = nCurrentRecommendedLevel
				end
			end
		end
		
		nRecommendedItemLevel = nMaxItemLevel
	end
	
	local nRecommendedHeroism = 0
	if matchSelected:IsVeteran() and tMatchInfo.tPrimeLevels ~= nil then
		local tMatch = self.tMatchList[tMatchInfo.eMatchType][tMatchInfo.nGameId]		
		for idx, tPrimeLevel in pairs(tMatchInfo.tPrimeLevels) do
			if tPrimeLevel.nPrimeLevel == tMatch.nPrimeLevel then
				nRecommendedHeroism = tPrimeLevel.nRecommendedHeroism
			end
		end
	end
	
	if nRecommendedHeroism ~= nil and nRecommendedHeroism > 0 then
		local strTextColor = "UI_TextHoloBody"
		local nPlayerHeroism = GameLib.GetPlayerUnit():GetHeroism()
		
		if nPlayerHeroism and nRecommendedHeroism > nPlayerHeroism then
			strTextColor = "UI_WindowTextRed"
		end

		local strItemLevel = String_GetWeaselString(Apollo.GetString("MatchMaker_RecommendedHeroism"), string.format("<T TextColor=\"%s\">%d</T>", strTextColor, nRecommendedHeroism))		
		strDetails = strDetails .. "\n" .. strItemLevel
	elseif nRecommendedItemLevel ~= nil and nRecommendedItemLevel > 0 then
		local strTextColor = "UI_TextHoloBody"
		local nPlayerItemLevel = GameLib.GetPlayerUnit():GetEffectiveItemLevel()
		
		if nPlayerItemLevel and nRecommendedItemLevel > nPlayerItemLevel then
			strTextColor = "UI_WindowTextRed"
		end
		
		local strItemLevel = String_GetWeaselString(Apollo.GetString("MatchMaker_RecommendedItemLevel"), string.format("<T TextColor=\"%s\">%d</T>", strTextColor, nRecommendedItemLevel))		
		strDetails = strDetails .. "\n" .. strItemLevel
	end
	
	strDetails = string.format("<T Font=\"CRB_Interface10\" TextColor=\"UI_TextHoloBody\">%s</T>", strDetails)

	wndDetails:FindChild("Title"):SetText(tMatchInfo.strName)
	wndDetails:FindChild("QueueLabel"):Show(matchSelected:IsQueued())
	
	local wndDescriptionContainer = wndDetails:FindChild("DescriptionContainer")
	local nOldHeight = wndDescriptionContainer:GetHeight()

	local wndDescriptionText = wndDetails:FindChild("Description")
	wndDescriptionText:SetAML(strDetails)
	
	local nNewWidth, nNewHeight = wndDescriptionText:SetHeightToContentHeight()	
	local nDescLeft, nDescTop, nDescRight, nDescBottom = wndDescriptionContainer:GetAnchorOffsets()
	if self.tWndRefs.wndPrimeLevelBtn:IsShown() then
		nDescBottom = nDescTop + self.tWndRefs.wndPrimeLevelBtn:GetHeight() + nNewHeight + 6
		
		wndDescriptionText:SetAnchorOffsets(0, self.tWndRefs.wndPrimeLevelBtn:GetHeight() + 6, 0, 0)
		wndDescriptionContainer:SetAnchorOffsets(nDescLeft, nDescTop, nDescRight, nDescBottom)
	elseif self.tWndRefs.wndPrimeLevelsUnavailable:IsShown() then
		nDescBottom = nDescTop + self.tWndRefs.wndPrimeLevelsUnavailable:GetHeight() + nNewHeight + 2
		
		wndDescriptionText:SetAnchorOffsets(0, self.tWndRefs.wndPrimeLevelBtn:GetHeight() + 2, 0, 0)
		wndDescriptionContainer:SetAnchorOffsets(nDescLeft, nDescTop, nDescRight, nDescBottom)
	else
		nDescBottom = nDescTop + nNewHeight
		wndDescriptionText:SetAnchorOffsets(wndDescriptionText:GetOriginalLocation():GetOffsets())
		wndDescriptionContainer:SetAnchorOffsets(nDescLeft, nDescTop, nDescRight, nDescBottom)
	end
	
	local nLeft, nTop, nRight, nBottom = wndDetails:GetAnchorOffsets()
	wndDetails:SetAnchorOffsets(nLeft, nTop, nRight, nDescBottom)
	
	local wndRating = wndInfo:FindChild("PersonalRatingContainer")
	local eRatingType = ktPvPRatingTypes[eMatchType]
	if eMatchType == MatchMakingLib.MatchType.Arena then
		eRatingType = ktPvPRatingTypes[eMatchType][tMatchInfo.nTeamSize]
	end
	
	if eRatingType then
		local tRatingInfo = MatchMakingLib.GetPvpRatingByType(eRatingType)
		
		if tRatingInfo then
			wndRating:SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_PersonalRating"), tRatingInfo.nRating))
			wndRating:Show(true)
		else
			wndRating:Show(false)
		end
	else
		wndRating:Show(false)
	end
	
	-- Set up rewards for random matches
	local tRewardInfo = matchSelected:GetReward()
	local wndRewardContainer = wndInfo:FindChild("RewardsContainer")
	local wndRotationRewardContainer = wndInfo:FindChild("RotationRewardsContainer")

	if tRewardInfo then
		local wndRewardList = wndRewardContainer:FindChild("RewardList")
		local nLeft, nTop, nRight, nBottom = wndRewardList:GetAnchorOffsets()
		local nNewHeight = 0
		
		local wndRewardItem = wndRewardList:FindChild("RewardItem")
		
		if tRewardInfo.itemReward then
			local wndIcon = wndRewardItem:FindChild("Icon")
			wndIcon:GetWindowSubclass():SetItem(tRewardInfo.itemReward)
			Tooltip.GetItemTooltipForm(self, wndIcon, tRewardInfo.itemReward, {})
			
			local wndLabel = wndRewardItem:FindChild("Label")
			wndLabel:SetText(tRewardInfo.itemReward:GetName())
			wndLabel:SetTextColor(ktItemQualityColors[tRewardInfo.itemReward:GetItemQuality()])
			
			wndRewardItem:Show(true)
			nNewHeight = nNewHeight + wndRewardItem:GetHeight()
		else
			wndRewardItem:Show(false)
		end
		
		local wndXP = wndRewardContainer:FindChild("XPReward")
		if tRewardInfo.nXpEarned and tRewardInfo.nXpEarned > 0 then
			wndXP:FindChild("Label"):SetText(String_GetWeaselString(Apollo.GetString("CRB_XPAmount"), Apollo.FormatNumber(tRewardInfo.nXpEarned, 0, true)))
			wndXP:Show(true)
			nNewHeight = nNewHeight + wndXP:GetHeight()
		else
			wndXP:Show(false)
		end
		
		local wndMoney = wndRewardContainer:FindChild("CashWindow")
		if tRewardInfo.monReward then
			wndMoney:SetAmount(tRewardInfo.monReward, true)
			wndMoney:Show(true)
			nNewHeight = nNewHeight + wndMoney:GetHeight()
		else
			wndMoney:Show(false)
		end
		
		local tRotationRewardInfo = matchSelected:GetRotationRewards()
		local wndRotationRewards = wndRewardContainer:FindChild("RotationRewards")
		wndRotationRewards:DestroyChildren()
		if tRotationRewardInfo and tRotationRewardInfo.arRewards then
			local nRotationRewardsHeight = 0
			for idx, tReward in pairs(tRotationRewardInfo.arRewards) do
				if not tReward.bAlreadyGranted then
					local wndEntry = self:BuildRewardContainer(wndRotationRewards, tReward, true)
					nRotationRewardsHeight = nRotationRewardsHeight + wndEntry:GetHeight()
				end
			end
			
			wndRotationRewards:Show(true)
			local nRewardsLeft, nRewardsTop, nRewardsRight, nRewardsBottom = wndRotationRewards:GetAnchorOffsets()
			wndRotationRewards:SetAnchorOffsets(nRewardsLeft, nRewardsTop, nRewardsRight, nRewardsTop + nRotationRewardsHeight)
			wndRotationRewards:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
			nNewHeight = nNewHeight + nRotationRewardsHeight
		else
			wndRotationRewards:Show(false)
		end
		
		wndRotationRewardContainer:Show(false)
		wndRewardContainer:Show(true)
		wndRewardList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		wndRewardList:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nNewHeight)
		
		local nContainerLeft, nContainerTop, nContainerRight, nContainerBottom = wndRewardContainer:GetAnchorOffsets()
		wndRewardContainer:SetAnchorOffsets(nContainerLeft, nContainerTop, nContainerRight, nContainerTop + nTop + nNewHeight)
	else
		-- Set up rewards for Reward Rotations
		local unitPlayer = GameLib.GetPlayerUnit()
		local bFound = false
		if unitPlayer and unitPlayer:IsHeroismUnlocked() then
			local arRotationRewardInfo = GameLib.GetRewardRotation(matchSelected:GetInfo().nRewardRotationContentId, matchSelected:IsVeteran())
			local wndRewardIconContainer = wndRotationRewardContainer:FindChild("RewardIconContainer")
			wndRewardIconContainer:DestroyChildren()
			if arRotationRewardInfo then
				for idx, tReward in pairs(arRotationRewardInfo) do
					self:BuildRewardContainer(wndRewardIconContainer, tReward)
					bFound = true
				end
				wndRewardIconContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
			end
		end

		wndRotationRewardContainer:Show(bFound)
		wndRewardContainer:Show(false)
	end
	
	-- Set up team info for Arenas and Warplots	
	self:UpdateTeamInfo()
	-- Update the achievements UI
	self:UpdateAchievements()
	
	wndInfo:FindChild("Content"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	wndInfo:Show(true)
end

function MatchMaker:UpdateTeamInfo()
	if not self.matchDisplayed or not self.tWndRefs.wndMain then
		return
	end
	
	local wndInfo = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchInfo")
	local wndTeam = wndInfo:FindChild("TeamContainer")
	local eMatchType = self.matchDisplayed:GetInfo().eMatchType
	
	if ktPvPGuildRequired[eMatchType] then
		local wndTeam = wndInfo:FindChild("TeamContainer")
		local wndUpsellPlayerBtn = wndTeam:FindChild("UpsellPlayer")
		local wndCreateTeamBtn = wndTeam:FindChild("CreateTeam")
		local wndExistingTeam = wndTeam:FindChild("ExistingTeam")
		local wndTeamName = wndTeam:FindChild("TeamName")

		local eGuildType = ktPvPGuildToTeamSize[self.matchDisplayed:GetInfo().nTeamSize]
		local bCanCreate = GuildLib.CanCreate(eGuildType)
		local bHybridSystem = AccountItemLib.GetPremiumSystem() == AccountItemLib.CodeEnumPremiumSystem.Hybrid

		local guildShown = self.tHasGuild[eGuildType]
		if guildShown then
			wndExistingTeam:Show(true)
			wndCreateTeamBtn:Show(false)
			wndUpsellPlayerBtn:Show(false)

			local tMyRatingInfo = guildShown:GetMyPvpRatings()
			local tTeamRatingInfo = guildShown:GetPvpRatings()			
			local nTeamMatchesPlayed = tTeamRatingInfo.nWins + tTeamRatingInfo.nLosses + tTeamRatingInfo.nDraws
			local nMyGames = tMyRatingInfo.nWins + tMyRatingInfo.nLosses + tMyRatingInfo.nDraws
			local strPercent = String_GetWeaselString(Apollo.GetString("CRB_Percent"), math.floor(tMyRatingInfo.fParticipation * 100))
			
			wndTeamName:SetText(guildShown:GetName())
			wndTeam:FindChild("Rating"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_Rating"), tTeamRatingInfo.nRating))
			wndTeam:FindChild("TeamPlayed"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_GamesPlayed"), nTeamMatchesPlayed))
			wndTeam:FindChild("PersonalPlayed"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_TeamParticipation"), nMyGames, strPercent))
			
			local wndRosterButton = wndTeam:FindChild("RosterButton")
			wndRosterButton:Show(true)
			wndRosterButton:SetData(guildShown:GetType())
			wndRosterButton:FindChild("SignatureValid"):Show(bHybridSystem and bCanCreate)
		else
			wndExistingTeam:Show(false)
	
			local strLabel = "Guild_GuildTypeWarparty"
			if eMatchType == MatchMakingLib.MatchType.Arena then
				strLabel = "Guild_GuildTypeArena"
			end
			wndTeamName:SetText(Apollo.GetString(strLabel))

			local strUpsellText = "Storefront_NavVip"
			if bHybridSystem then
				strUpsellText = "Storefront_NavSignature"
			end

			local bShowUpsell = not bCanCreate and GameLib.GetPlayerLevel(true) >= self.matchDisplayed:GetInfo().nMinLevel
			wndCreateTeamBtn:Show(not bShowUpsell)
			wndCreateTeamBtn:FindChild("SignaturePlayerValid"):Show(bHybridSystem)
			wndCreateTeamBtn:SetData(eGuildType)
			wndCreateTeamBtn:Enable(bCanCreate)

			wndUpsellPlayerBtn:Show(bShowUpsell)
			wndUpsellPlayerBtn:FindChild("SignatureBanner"):Show(bHybridSystem)
			wndUpsellPlayerBtn:SetText(String_GetWeaselString(Apollo.GetString("Matchmaker_PlayerTeamCreation"), Apollo.GetString(strUpsellText)))
			wndUpsellPlayerBtn:SetData(eGuildType)
			wndUpsellPlayerBtn:Enable(not bCanCreate and self.bStoreLinkValid)
		end
		
		wndTeam:Show(true)
	else
		wndTeam:Show(false)
	end
end

function MatchMaker:ToggleArenaQueueStatus(wndHandler, wndControl)
	self.arMatchesToQueue = {}
	self:UpdateQueueList(wndControl:GetData(), wndControl:IsChecked())
end

function MatchMaker:ToggleParentStatus(wndControl, wndHandler)
	if wndHandler ~= wndControl then
		return
	end
	
	local arMatchList = wndControl:GetParent():FindChild("MatchEntries"):GetChildren()
	local bIsSelected = wndControl:IsChecked()
	
	for idx, matchEntry in pairs(arMatchList) do
		local wndSelection = matchEntry:FindChild("SelectMatch")
		if wndSelection:IsEnabled() then
			wndSelection:SetCheck(bIsSelected)
			
			self:UpdateQueueList(wndSelection:GetData(), bIsSelected)
		end
	end
	
	if bIsSelected then
		self:ForceUncheckRandomQueue()
	end
end

function MatchMaker:ToggleRandomQueueStatus(wndControl, wndHandler)
	local matchSelected = wndControl:GetData()
	
	self.arMatchesToQueue = {}
	self:UpdateQueueList(matchSelected, wndControl:IsChecked())
	
	local wndMasterList = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls:MasterList")
	
	if wndControl:IsChecked() then
		for idx, wndHeader in pairs(wndMasterList:GetChildren()) do
			if wndHeader:GetData() ~= knRandomMatchIndex then
				for idx, wndParent in pairs(wndHeader:FindChild("MatchEntries"):GetChildren()) do
					local wndParentSelect = wndParent:FindChild("MatchSelection")
					if wndParentSelect then
						if wndParentSelect:GetParent():GetName() == "MatchSelectionParent" then
					wndParentSelect:SetCheck(false)
					self:ToggleParentStatus(wndParentSelect, wndParentSelect)
						elseif wndParentSelect:GetParent():GetName() == "MatchEntries" then
							local wndSelectMatch = wndParentSelect:FindChild("SelectMatch")
							if wndSelectMatch and wndSelectMatch:IsChecked() then
								wndSelectMatch:SetCheck(false)
								self:ToggleMatchQueueStatus(wndSelectMatch, wndSelectMatch)
							end
						end
					else
						if wndParent:GetName() == "PrimeLevelMatchSelection" then
							local wndSelectMatch = wndParent:FindChild("SelectMatch")
							if wndSelectMatch and wndSelectMatch:IsChecked() then
								wndSelectMatch:SetCheck(false)
								self:OnPrimeMatchUnchecked(wndSelectMatch, wndSelectMatch)
							end
						end
					end
				end
			end
		end
	end
end

function MatchMaker:ToggleMatchQueueStatus(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local matchSelected = wndControl:GetData()
	self:UpdateQueueList(matchSelected, wndControl:IsChecked())
	
	if wndControl:IsChecked() then
		self:ForceUncheckRandomQueue()
	end
end

function MatchMaker:ForceUncheckRandomQueue()
	local wndMasterList = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls:MasterList")
	for idx, wndHeader in pairs(wndMasterList:GetChildren()) do
		if wndHeader:GetData() == knRandomMatchIndex then
			local wndRandomSelect = wndHeader:FindChild("MatchSelection")
				wndRandomSelect:SetCheck(false)
				self:UpdateQueueList(wndRandomSelect:GetData(), false)
			end
		end
end

function MatchMaker:UpdateQueueList(matchUpdated, bShouldAdd)
	if bShouldAdd then
		table.insert(self.arMatchesToQueue, matchUpdated)
	elseif #self.arMatchesToQueue > 0 then
		for idx = 1, #self.arMatchesToQueue do
			if self.arMatchesToQueue[idx] == matchUpdated then
				table.remove(self.arMatchesToQueue, idx)
			end
		end
	end
	
	self:CheckQueueEligibility()
end

function MatchMaker:HelperToggleRole(eRole, eMasterTab, bShouldAdd)
	if bShouldAdd then
		table.insert(self.tQueueOptions[eMasterTab].arRoles, eRole)
	elseif self.tQueueOptions[eMasterTab].arRoles and #self.tQueueOptions[eMasterTab].arRoles > 0 then
		for idx = 1, #self.tQueueOptions[eMasterTab].arRoles do
			if self.tQueueOptions[eMasterTab].arRoles[idx] == eRole then
				table.remove(self.tQueueOptions[eMasterTab].arRoles, idx)
			end
		end
	end
end

function MatchMaker:OnToggleCombatRole(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:HelperToggleRole(wndHandler:GetData(), self.eSelectedMasterType, wndHandler:IsChecked())
	self:ValidateQueueButtons()
end

function MatchMaker:OnShiphandOptionToggle(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tQueueOptions[keMasterTabs.PvE].bFindOthers = not wndHandler:IsChecked()
end

function MatchMaker:ToggleMercenaryQueue(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tQueueOptions[keMasterTabs.PvP].bAsMercenary = wndHandler:IsChecked()
	
	self:CheckQueueEligibility()
end

function MatchMaker:ToggleWarpartyQueue(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self.tQueueOptions[keMasterTabs.PvP].bAsMercenary = not wndHandler:IsChecked()
	
	self:CheckQueueEligibility()
end

-----------------------------------------------------------------------------------------------
-- Queue button functionality
-----------------------------------------------------------------------------------------------
function MatchMaker:CheckQueueEligibility()
	local eType = nil
	if self.tWndRefs.wndMain:FindChild("HeaderButtons:PvPBtn"):IsChecked() then
		eType = self.ePvPTabSelected
	elseif self.tWndRefs.wndMain:FindChild("HeaderButtons:PvEBtn"):IsChecked() then
		local wndScalingOptions = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls:PvEScalingSettings")
		local wndPrimeLevelsBtn = wndScalingOptions:FindChild("PrimeLevels:PrimeLevelsBtn")
		if wndPrimeLevelsBtn:IsChecked() and #self.arMatchesToQueue > 0 then
			eType = self.arMatchesToQueue[1]:GetInfo().eMatchType
		else
		eType = self.ePvETabSelected
		end
	else
		return
	end
	
	local wndControls = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls")
	local wndDefault = wndControls:FindChild("QueueControls:DefaultControls")
	
	if eType == MatchMakingLib.MatchType.OpenArena then
		if #self.arMatchesToQueue > 0 then
			eType = self.arMatchesToQueue[1]:GetInfo().eMatchType
		end
	end
	
	local bSoloOnly = true
	for idx, matchSelected in pairs(self.arMatchesToQueue) do
		if matchSelected:GetInfo().nTeamSize > 1 or matchSelected:IsRandom() then
			bSoloOnly = false
			break
		end
	end
	
	local eMasterTab
	if ktPvETypes[eType]
		or eType == MatchMakingLib.MatchType.PrimeLevelDungeon
		or eType == MatchMakingLib.MatchType.PrimeLevelExpedition
		or eType == MatchMakingLib.MatchType.PrimeLevelAdventure
		or eType == MatchMakingLib.MatchType.ScaledPrimeLevelAdventure
		or eType == MatchMakingLib.MatchType.ScaledPrimeLevelDungeon
		or eType == MatchMakingLib.MatchType.ScaledPrimeLevelExpedition then
		eMasterTab = keMasterTabs.PvE
	else
		eMasterTab = keMasterTabs.PvP
	end
	
	local bValidRoleSelection = true
	if not bSoloOnly and eType ~= MatchMakingLib.MatchType.Arena then
		bValidRoleSelection = self.tQueueOptions[eMasterTab].arRoles and #self.tQueueOptions[eMasterTab].arRoles > 0
	end
	
	local nWarpartyTeamSize = 0
	for idx, tMatchInfo in pairs(self.tMatchList[MatchMakingLib.MatchType.Warplot]) do
		matchWarplot = tMatchInfo.matchVet
		nWarpartyTeamSize = idx
	end

	local guildWarparty = self.tHasGuild[ktPvPGuildToTeamSize[nWarpartyTeamSize]]
	local bCanQueueAsWarparty = eType == MatchMakingLib.MatchType.Warplot and guildWarparty and guildWarparty:GetRanks()[guildWarparty:GetMyRank()].bCanQueueTheWarparty
	local bCanSoloQueue = (not ktPvPGuildRequired[eType] 
			or (bCanQueueAsWarparty and not self.tQueueOptions[keMasterTabs.PvP].bAsMercenary) 
			or (eType == MatchMakingLib.MatchType.Warplot and self.tQueueOptions[keMasterTabs.PvP].bAsMercenary))
		and bValidRoleSelection and #self.arMatchesToQueue > 0
		
	local bCanJoinAsGroup = MatchMakingLib.CanQueueAsGroup() and not bSoloOnly
	local eQueueResultSolo = MatchMakingLib.MatchQueueResult.Success
	local eQueueResultGroup = MatchMakingLib.MatchQueueResult.Success
	
	if eType ~= MatchMakingLib.MatchType.Warplot then
		for idx, match in ipairs(self.arMatchesToQueue) do
			if bCanSoloQueue then
				eQueueResultSolo = match:CanQueue()
				if eQueueResultSolo ~= MatchMakingLib.MatchQueueResult.Success then
					bCanSoloQueue = false
				end
			end
			
			if bCanJoinAsGroup then
				eQueueResultGroup = match:CanQueueAsGroup()
				if eQueueResultGroup ~= MatchMakingLib.MatchQueueResult.Success then
					bCanJoinAsGroup = false
				end
			end
		end
	else
		bCanSoloQueue = self.tQueueOptions[keMasterTabs.PvP].bAsMercenary

		if not bCanJoinAsGroup then
			bCanJoinAsGroup = bCanQueueAsWarparty and not self.tQueueOptions[keMasterTabs.PvP].bAsMercenary
		end
	end
	
	wndDefault:FindChild("SoloQueue"):Enable(bCanSoloQueue)

	local wndGroupJoin = wndDefault:FindChild("GroupJoin")
	wndGroupJoin:Enable(bCanJoinAsGroup)
	
	local strButtonText = "MatchMaker_JoinAsGroup"
	
	if not bCanJoinAsGroup then
		strButtonText = "Matchmaker_GroupNotEligible"
	end

	if not MatchingGameLib.GetQueueEntry() then
		wndControls:FindChild("MasterListSelectBlocker"):Show(#self.arMatchesToQueue == 0)
		--wndControls:FindChild("QueueControls:RoleSelectBlocker"):Show(not bValidRoleSelection)
		wndControls:FindChild("PvESettings:NoRoleBlocker"):Show(bSoloOnly or eType == MatchMakingLib.MatchType.Arena)
	end
	
	-- If you're in an instance, disable queue buttons
	if MatchingGameLib.GetQueueEntry() and not MatchingGameLib.IsFinished() then
		wndDefault:FindChild("GroupJoin"):Enable(false)
		wndDefault:FindChild("GroupJoin"):SetTooltip(Apollo.GetString("MatchMaker_CantQueueInInstance"))
		wndDefault:FindChild("SoloQueue"):Enable(false)
		wndDefault:FindChild("SoloQueue"):SetTooltip(Apollo.GetString("MatchMaker_CantQueueInInstance"))
	elseif MatchingGameLib.GetQueueEntry() and MatchMakingLib.CanQueueAsGroup() and not bCanJoinAsGroup then
		-- requeue disallowed by match type (MatchingGameLib.IsFinished() is implied)
		wndGroupJoin:SetTooltip(Apollo.GetString("MatchingFailure_InvalidRequeueType"))
	elseif MatchMakingLib.IsQueuedAsGroupForMatching() then -- if you're queued as group, disable solo queue
		wndDefault:FindChild("GroupJoin"):SetTooltip("")
		wndDefault:FindChild("SoloQueue"):Enable(false)
		wndDefault:FindChild("SoloQueue"):SetTooltip(Apollo.GetString("MatchMaker_CantSoloQueueWhileGrouped"))
	else
		if not bCanQueueSolo then
			wndDefault:FindChild("SoloQueue"):SetTooltip(MatchMakingLib.GetMatchQueueResultString(eQueueResultSolo))
		else
			wndDefault:FindChild("SoloQueue"):SetTooltip("")
		end

		if not bCanJoinAsGroup then
			wndGroupJoin:SetTooltip(MatchMakingLib.GetMatchQueueResultString(eQueueResultGroup))
		else
			wndDefault:FindChild("GroupJoin"):SetTooltip("")
		end
	end
	
	wndGroupJoin:SetText(Apollo.GetString(strButtonText))
end

function MatchMaker:ResizeBlocker()
	local wndControls = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:Controls")
	local wndBlocker = wndControls:FindChild("MasterListSelectBlocker")
	
	local nListLeft, nListTop, nListRight, nListBottom = wndControls:FindChild("MasterList"):GetAnchorOffsets()
	local nBlockerLeft, nBlockerTop, nBlockerRight, nBlockerBottom = wndBlocker:GetAnchorOffsets()
	local nNewBlockerTop = nBlockerTop

	wndBlocker:SetAnchorOffsets(nBlockerLeft, nListBottom, nBlockerRight, nBlockerBottom)
end

function MatchMaker:ValidateQueueButtons()
	if not self.tWndRefs.wndMain then
		return
	end
	
	local eMatchType = MatchMakingLib.MatchType.Shiphand
	if self.eSelectedMasterType == keMasterTabs.PvE then
		eMatchType = self.ePvETabSelected
	else
		eMatchType = self.ePvPTabSelected
	end
		
	local tMatchesQueued = MatchMakingLib.GetQueuedEntries(eMatchType)
	if ktNormalToRated[eMatchType] and (not tMatchesQueued or not tMatchesQueued[1]) then
		tMatchesQueued = MatchMakingLib.GetQueuedEntries(ktNormalToRated[eMatchType])
	end
	
	if MatchingGameLib.GetQueueEntry() and not MatchingGameLib.IsFinished() then
		self:EnterStateInMatchingGame()
	elseif tMatchesQueued and tMatchesQueued[1] and tMatchesQueued[1]:IsQueued() then
		self:EnterStateInQueue(eMatchType)
	else
		self:EnterStateDefault()
	end
end

function MatchMaker:EnterStateDefault()
	local wndQueueBlocker = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:QueueBlocker")	
	wndQueueBlocker:Show(false)
	
	self:CheckQueueEligibility()
end

function MatchMaker:EnterStateInQueue(eMatchType)
	if not MatchMakingLib.IsQueuedForMatching() then
		return
	end
	
	local wndQueueBlocker = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:QueueBlocker")
	wndQueueBlocker:Show(true)
	wndQueueBlocker:FindChild("QueueActive:Text"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_QueueActive"), ktTypeNames[eMatchType]))
	wndQueueBlocker:FindChild("QueueActive"):Show(true)
	wndQueueBlocker:FindChild("QueuePending"):Show(false)
end

function MatchMaker:EnterStateInMatchingGame()
	if not MatchingGameLib.GetQueueEntry() then
		return
	end

	local wndQueueBlocker = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:QueueBlocker")
	wndQueueBlocker:Show(false)
end

function MatchMaker:OnUpdateGroup()
	if self.tWndRefs.wndMain then
		self:UpdateInMatchControls()
		self:ValidateQueueButtons()
		self:CheckQueuePenalties()
	end
end

function MatchMaker:OnUnitLevelChanged(unitPlayer, nUnitID)
	if self.tWndRefs.wndMain and unitPlayer:IsInYourGroup() then
		self:ValidateQueueButtons()
	end
end

-----------------------------------------------------------------------------------------------
-- Setting up Quests
-----------------------------------------------------------------------------------------------
function MatchMaker:BuildQuestList(wndHandler, wndControl)
	local wndQuestContent = self.tWndRefs.wndMain:FindChild("TabContent:QuestContent")
	wndQuestContent:Show(true)
	self.tWndRefs.wndMain:FindChild("TabContent:MatchContent"):Show(false)
	
	self.ePvETabSelected = knQuestTabId
	
	local wndContainer = wndQuestContent:FindChild("ZoneList")
	local nPlayerLevel = GameLib.GetPlayerUnit():GetLevel()
	
	wndContainer:DestroyChildren()

	for strZone, tZoneInfo in pairs(self.tHubList) do
		local wndOption = Apollo.LoadForm(self.xmlDoc, "ModeEntry", wndContainer, self)
		local wndButton = wndOption:FindChild("ModeBtn")
	
		if tZoneInfo.nMinLevel == tZoneInfo.nMaxLevel then
			strText = strZone .. "\n(" .. tZoneInfo.nMinLevel .. ")"
		else
			strText = strZone .. "\n(" .. String_GetWeaselString(Apollo.GetString("MatchMaker_LevelRange"), tZoneInfo.nMinLevel, tZoneInfo.nMaxLevel) .. ")"
		end
		
		local strIconBGColor = "white"
		local strButtonTextColorBase = "Gold"
		if tZoneInfo.eDifficulty >= Unit.CodeEnumLevelDifferentialAttribute.Red then
			strIconBGColor = "UI_AlphaPercent40"
			strButtonTextColorBase = "Gray"
		end
		
		wndOption:FindChild("Icon"):SetBGColor(strIconBGColor)
		wndButton:SetNormalTextColor("UI_BtnText" .. strButtonTextColorBase .. "ListNormal")
		wndButton:SetPressedTextColor("UI_BtnText" .. strButtonTextColorBase .. "ListPressed")
		wndButton:SetFlybyTextColor("UI_BtnText" .. strButtonTextColorBase .. "ListFlyby")
		wndButton:SetPressedFlybyTextColor("UI_BtnText" .. strButtonTextColorBase .. "ListPressedFlyby")
		wndButton:SetDisabledTextColor("UI_BtnText" .. strButtonTextColorBase .. "ListDisabled")
		
		
		wndButton:SetText(strText)
		wndButton:SetData(tZoneInfo)

		wndOption:FindChild("CompletionPct"):SetText(math.floor((tZoneInfo.nCompleted / tZoneInfo.nTotal) * 100) .. "%")
		wndOption:FindChild("CompletionPct"):Show(true)
	end

	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:FindChild("ModeBtn"):GetData().nMinLevel < b:FindChild("ModeBtn"):GetData().nMinLevel end)
end

-----------------------------------------------------------------------------------------------
-- Quest Tab
-----------------------------------------------------------------------------------------------
function MatchMaker:OnQuestSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:SetQuestTabContent(wndHandler:GetData())
end

function MatchMaker:SetQuestTabContent(tHubs)
	if not tHubs then
		return
	end

	local wndQuestContent = self.tWndRefs.wndMain:FindChild("TabContent:QuestContent")
	local wndContent =  wndQuestContent:FindChild("QuestContainer:Content")
	wndContent:DestroyChildren()

	for strHubName, tHubInfo in pairs(tHubs.tHubInfo) do
		local wndContainer = Apollo.LoadForm(self.xmlDoc, "QuestHubEntry", wndContent, self)

		if tHubInfo.nMinLevel == tHubInfo.nMaxLevel then
			strHubName = strHubName .. " (" .. tHubInfo.nMinLevel .. ")"
		else
			strHubName = strHubName .. " (" .. String_GetWeaselString(Apollo.GetString("MatchMaker_LevelRange"), tHubInfo.nMinLevel, tHubInfo.nMaxLevel) .. ")"
		end

		wndContainer:FindChild("HeaderBtnText"):SetText(strHubName)

		local nPercent = (tHubInfo.nCompleted / tHubInfo.nTotal) * 100
		wndContainer:FindChild("CompletionPercent"):SetText(nPercent .. "%")

		wndContainer:FindChild("HeaderBtn"):SetData(tHubInfo)
	end

	wndContent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:FindChild("HeaderBtn"):GetData().nMinLevel < b:FindChild("HeaderBtn"):GetData().nMinLevel end)
	wndQuestContent:FindChild("Title"):SetText(tHubs.strZoneName)
	wndQuestContent:Show(true)
	self.tWndRefs.wndMain:FindChild("TabContent:MatchContent"):Show(false)
	
	local wndAchievement = wndQuestContent:FindChild("ContentFooter:AchievementContainer")
	local wndProgress = wndAchievement:FindChild("ProgressBG:AchievementProgress")
	wndProgress:SetMax(tHubs.nTotal)
	wndProgress:SetProgress(tHubs.nCompleted)
	
	wndAchievement:FindChild("ProgressCount"):SetText(String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), tHubs.nCompleted, tHubs.nTotal))
end

function MatchMaker:ExpandHub(wndHandler, wndControl)
	local wndParent = wndHandler:GetParent()
	local wndContainer = wndParent:FindChild("HeaderContainer")
	local tHubInfo = wndHandler:GetData()
	local nHubHeight = 0

	for idx, epiCurrent in pairs(tHubInfo.arEpisodes) do
		local wndEpisode = Apollo.LoadForm(self.xmlDoc, "EpisodeEntry", wndContainer, self)

		local eState = epiCurrent:GetState() 
		if eState == Episode.EpisodeState_Complete then
			wndEpisode:FindChild("CheckContainer"):SetSprite("CRB_DialogSprites:sprDialog_Icon_Check")
		end

		local wndTitle = wndEpisode:FindChild("Title")
		wndTitle:SetTextColor(ktEpisodeStateColors[eState])
		wndTitle:SetText(epiCurrent:GetTitle() .. " (" .. epiCurrent:GetConLevel() .. ")")
		
		local wndSummary = wndEpisode:FindChild("Summary")
		local strSummary = eState == Episode.EpisodeState_Complete and epiCurrent:GetSummary() or epiCurrent:GetDesc()
		wndSummary:SetAML("<T TextColor=\"UI_TextHoloBody\" Font=\"CRB_InterfaceMedium\">" .. strSummary .. "</T>")

		wndSummary:SetHeightToContentHeight()

		wndEpisode:FindChild("EpisodeSelection"):SetData(wndParent)
		wndEpisode:SetData(epiCurrent)

		if nHubHeight == 0 then
			nHubHeight = wndEpisode:GetHeight()
		end
	end

	self:ResizeExpandedHub(wndParent)
end

function MatchMaker:CollapseHub(wndHandler, wndControl)
	local wndParent = wndHandler:GetParent()
	local wndContainer = wndParent:FindChild("HeaderContainer")
	wndContainer:DestroyChildren()

	local nLeft, nTop, nRight, nBottom = wndContainer:GetOriginalLocation():GetOffsets()
	wndContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)

	nLeft, nTop, nRight, nBottom = wndParent:GetOriginalLocation():GetOffsets()
	wndParent:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)

	local wndContent = wndParent:GetParent()
	wndContent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	if wndContent:GetVScrollRange() == 0 then
		wndContent:SetVScrollPos(0)
	end
end

function MatchMaker:ResizeExpandedHub(wndHub)
	local wndContainer = wndHub:FindChild("HeaderContainer")
	
	local arEpisodes = wndContainer:GetChildren()
	local nHeight = arEpisodes[1]:GetHeight()

	if #arEpisodes > 1 then
		nHeight = wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:GetData():GetConLevel() < b:GetData():GetConLevel() end)
	end
	
	local nLeft, nTop, nRight, nBottom = wndContainer:GetOriginalLocation():GetOffsets()
	wndContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeight)
	
	local nParentLeft, nParentTop, nParentRight, nParentBottom = wndHub:GetOriginalLocation():GetOffsets()
	local nBuffer = (nParentBottom - nParentTop) - nBottom

	wndHub:SetAnchorOffsets(nParentLeft, nParentTop, nParentRight, nParentBottom + wndContainer:GetHeight() + nBuffer)
	
	wndHub:GetParent():ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function MatchMaker:ExpandEpisode(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	if self.wndSelectedEpisodeBtn then
		self:CollapseEpisode(self.wndSelectedEpisodeBtn, self.wndSelectedEpisodeBtn)
	end
	
	self.wndSelectedEpisode = wndHandler
	
	local wndEpisode = wndHandler:GetParent()
	local wndSummary = wndEpisode:FindChild("Summary")
	local nBuffer = wndEpisode:GetHeight() - wndEpisode:FindChild("Background"):GetHeight() + 8
	
	local nLeft, nTop, nRight, nBottom = wndEpisode:GetAnchorOffsets()
	wndEpisode:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + wndSummary:GetHeight() + nBuffer)
	
	wndSummary:Show(true)

	self:ResizeExpandedHub(wndHandler:GetData())
end

function MatchMaker:CollapseEpisode(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.wndSelectedEpisodeBtn = nil
	
	local wndEpisode = wndHandler:GetParent()
	
	local nLeft, nTop, nRight, nBottom = wndEpisode:GetOriginalLocation():GetOffsets()
	wndEpisode:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	
	wndEpisode:FindChild("Summary"):Show(false)
	
	self:ResizeExpandedHub(wndHandler:GetData())
	
	local wndContent = self.tWndRefs.wndMain:FindChild("TabContent:QuestContent:QuestContainer:Content")
	
	if wndContent:GetVScrollRange() == 0 then
		wndContent:SetVScrollPos(0)
	end
end

function MatchMaker:OnEpisodeNavPoint(wndHandler, wndControl)
	local hubArea = wndHandler:GetParent():GetData():GetHub()
	
	if hubArea then
		local tLocation = hubArea:GetLocation()
		if tLocation then
			local tNavPoint = GameLib.GetNavPoint()
			if tNavPoint and tNavPoint.tPosition.x ~= tLocation.x and tNavPoint.tPosition.y ~= tLocation.y and tNavPoint.tPosition.z ~= tLocation.z then
				self:ShowNavPointNotification(tLocation, hubArea)
			else
				self:ConfirmNavPointChange(tLocation, hubArea)
			end
		end
	end
end

function MatchMaker:ShowNavPointNotification(tLocation, hubSelected)
	local wndBlocker = self.tWndRefs.wndMain:FindChild("NavPointBlocker")
	wndBlocker:Show(true)
	wndBlocker:FindChild("PointSetMessage"):Show(false)
	
	local wndConfirm = wndBlocker:FindChild("PointChangeConfirm")
	wndConfirm:Show(true)
	wndConfirm:FindChild("MessageText"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_NavPointUpdate"), hubSelected:GetName()))

	wndConfirm:FindChild("SetPointConfirm"):SetData({tLocation = tLocation, hubSelected = hubSelected})
end

function MatchMaker:ConfirmNavPointChange(tLocation, hubShown)
	
	GameLib.SetNavPoint(tLocation, hubShown:GetSubZoneId())
	GameLib.ShowNavPointHintArrow()
	
	local wndNavUpdateText = self.tWndRefs.wndMain:FindChild("TabContent:QuestContent:QuestContainer:NavUpdateMessageText")
	wndNavUpdateText:Show(true)
	wndNavUpdateText:SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_NavPointSet"), hubShown:GetName()))
	self.tWndRefs.wndMain:FindChild("NavPointBlocker"):Show(false)
	self.timerNavPointNotification:Start()
	
	local tNavPoint = GameLib.GetNavPoint()
	if tNavPoint then
		Event_FireGenericEvent("ContentFinder_OpenMapToNavPoint", tNavPoint.nMapZoneId)
	end
end

function MatchMaker:OnNavPointConfirm(wndHandler, wndControl)
	local tInfo = wndHandler:GetData()
	self:ConfirmNavPointChange(tInfo.tLocation, tInfo.hubSelected)
end

function MatchMaker:HideNavPointNotification(wndHandler, wndControl)
	self.tWndRefs.wndMain:FindChild("TabContent:QuestContent:QuestContainer:NavUpdateMessageText"):Show(false)
	self.tWndRefs.wndMain:FindChild("NavPointBlocker"):Show(false)
end

-----------------------------------------------------------------------------------------------
-- Queue Info
-----------------------------------------------------------------------------------------------
function MatchMaker:OnSoloQueue()
	if #self.arMatchesToQueue > 0 then
		MatchMakingLib.Queue(self.arMatchesToQueue, self.tQueueOptions[self.eSelectedMasterType])
	end
end

function MatchMaker:OnGroupQueue()
	if #self.arMatchesToQueue > 0 then
		MatchMakingLib.QueueAsGroup(self.arMatchesToQueue, self.tQueueOptions[self.eSelectedMasterType])
	end
end

function MatchMaker:OnJoinQueue(eMatchType)
	local arMatchesQueued 
	if eMatchType == nil or not self.tWndRefs.wndQueueStatus or not self.tQueueTypes then
		arMatchesQueued = MatchMakingLib.GetQueuedEntries()
	else
		arMatchesQueued = MatchMakingLib.GetQueuedEntries(eMatchType)
	end
	if not arMatchesQueued or 0 == #arMatchesQueued then
		return
	end
	
	Sound.Play(Sound.PlayUIAlertPopUpTitleReceived)

	if not self.tWndRefs.wndQueueStatus or not self.tQueueTypes then
		self.tWndRefs.wndQueueStatus = Apollo.LoadForm(self.xmlDoc, "QueueWindow", nil, self)
		Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndQueueStatus, strName = Apollo.GetString("MatchMaker_QueueInformation")})
		self.tWndRefs.wndQueueStatus:FindChild("LeaveButton"):AttachWindow(self.tWndRefs.wndQueueStatus:FindChild("LeaveAllConfirmPopup"))	
		self.tWndRefs.wndQueueStatus:SetSizingMinimum(280, 270)
		self.tWndRefs.wndQueueStatus:SetSizingMaximum(600, 700)
		self.tQueueTypes = {}
	end
	
	local wndQueueType = nil
	local bHasGroupQueue = false
	for idx = 1, #arMatchesQueued do
		local matchQueued = arMatchesQueued[idx]
		eMatchType = matchQueued:GetInfo().eMatchType
		
		wndQueueType = self.tQueueTypes[eMatchType] and self.tQueueTypes[eMatchType].wndRef
		if not wndQueueType then
			wndQueueType = Apollo.LoadForm(self.xmlDoc, "QueueType", self.tWndRefs.wndQueueStatus:FindChild("Inset:QueueContainer"), self)
			local wndLeaveQueueBtn = wndQueueType:FindChild("LeaveQueueType")
			wndLeaveQueueBtn:SetData(eMatchType)
			wndLeaveQueueBtn:SetTooltip(String_GetWeaselString(Apollo.GetString("MatchMaking_LeaveSingleQueue"), ktTypeNames[eMatchType]))
			if not matchQueued:IsQueuedAsGroup() or MatchMakingLib.CanLeaveQueueAsGroup(eMatchType) then
				wndLeaveQueueBtn:Enable(true)
			else
				wndLeaveQueueBtn:Enable(false)
				wndLeaveQueueBtn:SetTooltip(Apollo.GetString("MatchMaker_LeaveQueuePermissions"))
			end
			self.tQueueTypes[eMatchType] = {
				wndRef = wndQueueType,
				tMatches = {},
			}
		end
		
		local nMatchHash = matchQueued:GetMatchHash()
		local wndMatch = self.tQueueTypes[eMatchType].tMatches[nMatchHash]
		if not wndMatch then
			wndMatch = Apollo.LoadForm(self.xmlDoc, "QueuedMatchEntry", wndQueueType:FindChild("InQueue:MatchList"), self)
			self.tQueueTypes[eMatchType].tMatches[nMatchHash] = wndMatch
			wndMatch:SetData(matchQueued)
			local wndMatchName = wndMatch:FindChild("MatchName")
			
			wndMatchName:SetText(matchQueued:GetInfo().strName)
			nNameWidth, nNameHeight = wndMatchName:SetHeightToContentHeight()
			nLeft, nTop, nRight, nBottom = wndMatch:GetAnchorOffsets()
			wndMatch:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nNameHeight)
		end
		
		if matchQueued:IsQueuedAsGroup() then
			bHasGroupQueue = true
		end
	end
	
	if bHasGroupQueue then
		self:OnUpdateGroupQueueStatus()
		self.tWndRefs.wndQueueStatus:FindChild("LeaveButton"):SetText(Apollo.GetString("MatchMaker_LeaveGroupQueue"))
	end
	
	local wndTypeExpand = wndQueueType:FindChild("ExpandButton")
	wndQueueType:FindChild("ExpandButton"):SetCheck(false)
	self:ToggleQueuedMatchList(wndTypeExpand, wndTypeExpand)
	
	self:OnQueueTimer()
	
	self.timerQueue:Set(1.0, true)
	self.timerQueue:Start()
	
	if self.tWndRefs.wndMain then
		self:ValidateQueueButtons()
		self:CheckQueuePenalties()
	end
end

function MatchMaker:OnUpdateGroupQueueStatus()
	if not self.tWndRefs.wndQueueStatus then
		return
	end
	
	self.tWndRefs.wndQueueStatus:FindChild("LeaveButton"):Enable(GroupLib.AmILeader())
end

function MatchMaker:OnLeaveQueueBtn(wndHandler, wndControl)
	MatchMakingLib.LeaveAllQueues()
end

function MatchMaker:OnLeaveSingleQueueBtn( wndHandler, wndControl )
	local eMatchType = wndHandler:GetData()
	local tQueuedEntries = MatchMakingLib.GetQueuedEntries(eMatchType)
	if not tQueuedEntries or not tQueuedEntries[1] then
		return
	end
	
	if tQueuedEntries[1]:IsQueuedAsGroup() then
		tQueuedEntries[1]:LeaveQueueAsGroup()
	else
		tQueuedEntries[1]:LeaveQueue()
	end
end


function MatchMaker:OnLeaveQueue(tQueuesLeft)
	if tQueuesLeft then
		for idx, eMatchType in pairs(tQueuesLeft) do
			if self.tQueueTypes[eMatchType] and self.tQueueTypes[eMatchType].wndRef then
				self.tQueueTypes[eMatchType].wndRef:Destroy()
				self.tQueueTypes[eMatchType] = nil
			end
		end
	end
	
	Sound.Play(Sound.PlayUI55ErrorVirtual)
	
	if self.tWndRefs.wndMain then
		self:ValidateQueueButtons()
		self:CheckQueuePenalties()
	end

	-- If we're still queued for at least one match type, don't destroy everything, but do resize if necessary
	if MatchMakingLib.IsQueuedForMatching() then
		if self.tWndRefs.wndQueueStatus then
			self.tWndRefs.wndQueueStatus:FindChild("Inset:QueueContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		end
		return
	end

	if self.tWndRefs.wndQueueStatus then
		self.tWndRefs.wndQueueStatus:Destroy()
		self.tWndRefs.wndQueueStatus = nil
		self.tQueueTypes = {}
		Event_FireGenericEvent("WindowManagementRemove", {strName = Apollo.GetString("MatchMaker_QueueInformation")})
	end
	
	self.timerQueue:Stop()
	
	if self.tWndRefs.wndJoinGame then
		self.tWndRefs.wndJoinGame:Close()
	end
	
	if self.tWndRefs.wndConfirmRole then
		self.tWndRefs.wndConfirmRole:Close()
	end
end

function MatchMaker:OnCloseConfirmLeavePopup(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	wndControl:GetParent("LeaveAllConfirmPopup"):Show(false)
end

function MatchMaker:ToggleQueuedMatchList(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndParent = wndHandler:GetParent()
	local wndQueueType = wndParent:GetParent()
	local wndQueueContainer = wndParent:FindChild("MatchList")
	
	local nOldHeight = wndQueueContainer:GetHeight()
	local nNewHeight = wndQueueContainer:ArrangeChildrenVert()	
	local nParentLeft, nParentTop, nParentRight, nParentBottom = wndQueueType:GetOriginalLocation():GetOffsets()
	
	local nNewBottom = nParentBottom + (nNewHeight - nOldHeight)
	if not wndHandler:IsChecked() then
		nNewBottom = nParentBottom
	end
	
	wndQueueType:SetAnchorOffsets(nParentLeft, nParentTop, nParentRight, nNewBottom)
	
	wndQueueType:GetParent():ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function MatchMaker:OnQueueTimer()
	if not self.tWndRefs.wndQueueStatus then
		return
	end
	
	for eMatchType, tQueueType in pairs(self.tQueueTypes) do
		local wndQueueType = tQueueType.wndRef
		local fTimeInQueue = 0
		local fEstimatedWait = 0
		
		local matchIdx = next(tQueueType.tMatches)
		if tQueueType.tMatches[matchIdx] then
			local matchQueued = tQueueType.tMatches[matchIdx]:GetData()
			fTimeInQueue = matchQueued:GetTimeInQueue()
			fEstimatedWait = matchQueued:GetAverageWaitTime()
			local strTimer = String_GetWeaselString(Apollo.GetString("CRB_Parenthese"), ConvertSecondsToTimer(fTimeInQueue))
			local wndTitle = wndQueueType:FindChild("Title")
			wndTitle:SetText(string.format("%s %s", ktTypeNames[eMatchType], strTimer))
			local tPenaltyInfo = MatchMakingLib.GetPenalizedPartyMembers(eMatchType)
			
			if tPenaltyInfo and tPenaltyInfo.fPenaltyDuration > 0 and tPenaltyInfo.fPenaltyDuration > fTimeInQueue and (tPenaltyInfo.bSelfPenalized or matchQueued:IsQueuedAsGroup()) then
				local nPenaltyMins = tPenaltyInfo.fPenaltyDuration / 60 + 0.5 -- force rounding
				local strPenaltyNotice = String_GetWeaselString(Apollo.GetString("MatchMaker_QueuePenaltyTooltip"), {name=Apollo.GetString("CRB_Minute"), count=nPenaltyMins})
	
				wndTitle:SetTooltip(strPenaltyNotice)
				wndTitle:SetTextColor(crQueueTimePenalty)
			else
				wndTitle:SetTooltip("")
				wndTitle:SetTextColor(crQueueTimeNormal)
			end
		end
		
		local strEstimatedWait = String_GetWeaselString(Apollo.GetString("MatchMaker_WaitTimeLabel"), self:FormatWaitTime(fEstimatedWait))
		wndQueueType:FindChild("InQueue:QueueTimeLabel"):SetText(strEstimatedWait)
	end
end

function MatchMaker:OnShowQueueStatus()
	if self.tWndRefs.wndQueueStatus then
		self.tWndRefs.wndQueueStatus:Invoke()
	else
		self:OnJoinQueue()
	end
end

function MatchMaker:OnCloseQueueStatus()
	if self.tWndRefs.wndQueueStatus then
		self.tWndRefs.wndQueueStatus:Close()
	end
end

function MatchMaker:FormatWaitTime(nSeconds)
	if nSeconds == nil then
		return 
	end
		
	if nSeconds > 3600 then
		local strHours = String_GetWeaselString(Apollo.GetString("CRB_Hours_AbbreviatedNoSpace"), math.floor(nSeconds / 3600))
		local strMinutes = String_GetWeaselString(Apollo.GetString("CRB_Minutes_AbbreviatedNoSpace"), math.floor(math.mod(nSeconds, 3600) / 60))
		local strTime = string.format("%s %s", strHours, strMinutes)
		
		return strTime
	else 
		local strMinutes = String_GetWeaselString(Apollo.GetString("CRB_Minutes_AbbreviatedNoSpace"), math.floor(nSeconds / 60))
		local strSeconds = String_GetWeaselString(Apollo.GetString("CRB_Seconds_AbbreviatedNoSpace"), math.floor(math.mod(nSeconds, 60)))
		local strTime = string.format("%s %s", strMinutes, strSeconds)
		
		return strTime
	end
end

function MatchMaker:CheckQueuePenalties()
	if not self.tWndRefs.wndMain then
		return
	end
	
	local eMatchType = MatchMakingLib.MatchType.Shiphand
	if self.eSelectedMasterType == keMasterTabs.PvE then
		eMatchType = self.ePvETabSelected
	else
		eMatchType = self.ePvPTabSelected
	end
	
	local wndPenaltyInfo = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:MatchTypeInfo:PenaltyInfo")
	wndPenaltyInfo:Show(false)
	
	local tPenaltyInfo = MatchMakingLib.GetPenalizedPartyMembers(eMatchType)
	if ktNormalToRated[eMatchType] and (not tPenaltyInfo or tPenaltyInfo.fPenaltyDuration == 0) then
		tPenaltyInfo = MatchMakingLib.GetPenalizedPartyMembers(ktNormalToRated[eMatchType])
	end
	
	if tPenaltyInfo then
		local fPenaltyDuration = tPenaltyInfo.fPenaltyDuration
		if fPenaltyDuration > 0 then
			local tPenalizedPlayers = tPenaltyInfo.arPenalized
			if #tPenalizedPlayers == 0 then
				table.insert(tPenalizedPlayers, Apollo.GetString("CRB_Unknown"))
			end
			
			local nPenaltyMins = fPenaltyDuration / 60 + 0.5 -- force rounding
			local strPenaltyNotice = String_GetWeaselString(Apollo.GetString("MatchMaker_PenaltyNotice"), {name=Apollo.GetString("CRB_Minute"), count=nPenaltyMins}, table.concat(tPenalizedPlayers, Apollo.GetString("CRB_ListSeparator")))

			wndPenaltyInfo:SetText(strPenaltyNotice)
			wndPenaltyInfo:Show(true)
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Match Ready
-----------------------------------------------------------------------------------------------
function MatchMaker:OnGameReady(bInProgress)
	if self.tWndRefs.wndJoinGame then
		return
	end
	
	self.tWndRefs.wndJoinGame = Apollo.LoadForm(self.xmlDoc, "JoinGame", nil, self)
	local strMessage = Apollo.GetString("MatchMaker_Group")	

	self.tWndRefs.wndJoinGame:FindChild("YesButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.MatchingGameRespondToPending, true)
	self.tWndRefs.wndJoinGame:FindChild("NoButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.MatchingGameRespondToPending, false)
	
	local arMatchesQueued = nil
	
	local tPendingInfo = MatchingGameLib.GetPendingInfo()
	local eType = tPendingInfo and tPendingInfo.eMatchType
	if eType ~= nil then
		arMatchesQueued = MatchMakingLib.GetQueuedEntries(eType)
	else
		arMatchesQueued = MatchMakingLib.GetQueuedEntries()
		eType = arMatchesQueued and arMatchesQueued[1] and arMatchesQueued[1]:GetInfo().eMatchType
	end

	if eType == MatchMakingLib.MatchType.Adventure then
		Sound.Play(Sound.PlayUIQueuePopsAdventure)
		strMessage = Apollo.GetString("MatchMaker_Group")
	elseif eType == MatchMakingLib.MatchType.Dungeon or eType == MatchMakingLib.MatchType.Shiphand or 
		   eType == MatchMakingLib.MatchType.PrimeLevelDungeon or eType == MatchMakingLib.MatchType.PrimeLevelExpedition or 
		   eType == MatchMakingLib.MatchType.ScaledPrimeLevelDungeon or eType == MatchMakingLib.MatchType.ScaledPrimeLevelExpedition then
		Sound.Play(Sound.PlayUIQueuePopsDungeon)
		strMessage = Apollo.GetString("MatchMaker_Group")
	else
		Sound.Play(Sound.PlayUIQueuePopsPvP)
		strMessage = Apollo.GetString("MatchMaker_Match")
	end
	
	if arMatchesQueued and #arMatchesQueued == 1 then
		strMessage = String_GetWeaselString(Apollo.GetString("MatchMaker_FoundSpecific"), arMatchesQueued[1]:GetInfo().strName, strMessage)
	else
		strMessage = String_GetWeaselString(Apollo.GetString("MatchMaker_Found"), strMessage, ktTypeNames[eType])
	end

	if bInProgress then
		strMessage = String_GetWeaselString(Apollo.GetString("MatchMaker_InProgress"), strMessage)
	end

	self.tWndRefs.wndJoinGame:FindChild("Title"):SetText(strMessage)
	
	local nJoinLeft, nJoinTop, nJoinRight, nJoinBottom = self.tWndRefs.wndJoinGame:GetAnchorOffsets()
	local nWarningHeight = self.tWndRefs.wndJoinGame:FindChild("RatedWarning"):GetHeight()
	nWarningHeight = nJoinTop > 0 and nWarningHeight or nWarningHeight * - 1
	self.tWndRefs.wndJoinGame:SetAnchorOffsets(nJoinLeft, ktRatedPvPTypes[eType] and nJoinTop or nJoinTop - nWarningHeight, nJoinRight, nJoinBottom)
	
	self.tWndRefs.wndJoinGame:Invoke()
end

-----------------------------------------------------------------------------------------------
-- Clean Up
-----------------------------------------------------------------------------------------------

function MatchMaker:OnClose(wndHandler, wndControl)
	if wndControl == self.tWndRefs.wndPrimeLevelList then
		return
	end
	
	Event_FireGenericEvent("LFGWindowHasBeenClosed")
	
	self.timerNavPointNotification:Stop()
	
	self.arMatchesToQueue = {}
	if self.tWndRefs.wndMain then
		self.tWndRefs.wndMain:Destroy()
		self.tWndRefs.wndMain = nil
		Event_FireGenericEvent("WindowManagementRemove", {strName = Apollo.GetString("CRB_ContentFinder")})
	end
end

function MatchMaker:CleanUpAll()
	self.timerQueue:Stop()
	self.timerNavPointNotification:Stop()
	for strIndex, wndStored in pairs(self.tWndRefs) do
		wndStored:Destroy()
		self.tWndRefs[strIndex] = nil
	end
end

-----------------------------------------------------------------------------------------------
-- Join Game
-----------------------------------------------------------------------------------------------
function MatchMaker:OnJoinGameClosed(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	if self.tWndRefs.wndJoinGame then
		self.tWndRefs.wndJoinGame:Destroy()
		self.tWndRefs.wndJoinGame = nil
	end
end

function MatchMaker:OnGamePendingUpdate(bCompleted)
	self:DisplayPendingInfo(not bCompleted)
end

function MatchMaker:DisplayPendingInfo(bShow)
	if self.tWndRefs.wndJoinGame then
		return
	end

	local tPendingInfo = MatchingGameLib.GetPendingInfo()

	if bShow and tPendingInfo.nTotalEnemies and tPendingInfo.nTotalEnemies > 0 then
		if not self.tWndRefs.wndAllyEnemyConfirm then
			self.tWndRefs.wndAllyEnemyConfirm = Apollo.LoadForm(self.xmlDoc, "WaitingOnAlliesAndEnemies", nil, self)
		end

		self.tWndRefs.wndAllyEnemyConfirm:FindChild("AllyCount"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), tPendingInfo.nAcceptedAllies, tPendingInfo.nTotalAllies))
		self.tWndRefs.wndAllyEnemyConfirm:FindChild("EnemyCount"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), tPendingInfo.nAcceptedEnemies, tPendingInfo.nTotalEnemies))
		self.tWndRefs.wndAllyEnemyConfirm:Invoke()
	elseif bShow and tPendingInfo.nTotalAllies and tPendingInfo.nTotalAllies > 0 then
		if not self.tWndRefs.wndAllyConfirm then
			self.tWndRefs.wndAllyConfirm = Apollo.LoadForm(self.xmlDoc, "WaitingOnAllies", nil, self)
		end

		self.tWndRefs.wndAllyConfirm:FindChild("AllyCount"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), tPendingInfo.nAcceptedAllies, tPendingInfo.nTotalAllies))
		self.tWndRefs.wndAllyConfirm:Invoke()
	else
		if self.tWndRefs.wndAllyEnemyConfirm then
			self.tWndRefs.wndAllyEnemyConfirm:Destroy()
			self.tWndRefs.wndAllyEnemyConfirm = nil
		end

		if self.tWndRefs.wndAllyConfirm then
			self.tWndRefs.wndAllyConfirm:Destroy()
			self.tWndRefs.wndAllyConfirm = nil
		end
	end
end

function MatchMaker:PendingGameCanceled()
	if self.tWndRefs.wndJoinGame then
		self.tWndRefs.wndJoinGame:Close()
	end
	
	if self.tWndRefs.wndAllyEnemyConfirm then
		self.tWndRefs.wndAllyEnemyConfirm:Destroy()
		self.tWndRefs.wndAllyEnemyConfirm = nil
	end

	if self.tWndRefs.wndAllyConfirm then
		self.tWndRefs.wndAllyConfirm:Destroy()
		self.tWndRefs.wndAllyConfirm = nil
	end
	
	if MatchMakingLib.IsQueuedForMatching() then
		self:OnJoinQueue()
	end
end

function MatchMaker:OnMatchEntered()
	local matchInstance = MatchingGameLib.GetQueueEntry()
	if matchInstance then
		local eMatchType = matchInstance:GetInfo().eMatchType
		--Force to the right tab
		if ktPvETypes[eMatchType] then
			self.eSelectedMasterType = keMasterTabs.PvE
		else
			self.eSelectedMasterType = keMasterTabs.PvP
		end
	end
	
	self:CleanUpAll()
end

-----------------------------------------------------------------------------------------------
-- Role Check
-----------------------------------------------------------------------------------------------
function MatchMaker:OnRoleCheck(bRolesRequired)
	self.tWndRefs.wndConfirmRole = Apollo.LoadForm(self.xmlDoc, "RoleConfirm", nil, self)
	local wndConfirmRoleButtons = self.tWndRefs.wndConfirmRole:FindChild("InsetFrame")
	
	local arSelectedRoles = self.tQueueOptions[self.eSelectedMasterType].arRoles
	
	if bRolesRequired then
		local tRoleCheckButtons =
		{
			[MatchMakingLib.Roles.Tank] = wndConfirmRoleButtons:FindChild("TankBtn"),
			[MatchMakingLib.Roles.Healer] = wndConfirmRoleButtons:FindChild("HealerBtn"),
			[MatchMakingLib.Roles.DPS] = wndConfirmRoleButtons:FindChild("DPSBtn"),
		}
	
		for eRole, wndButton in pairs(tRoleCheckButtons) do
			wndButton:Enable(false)
			wndButton:SetData(eRole)
		end
	
		for idx, eRole in pairs(MatchMakingLib.GetEligibleRoles()) do
			tRoleCheckButtons[eRole]:Enable(true)
		end
	
		if arSelectedRoles then
			for idx, eRole in pairs(arSelectedRoles) do
				tRoleCheckButtons[eRole]:SetCheck(true)
			end
		end
		
		if self.tWndRefs.wndMain then
			local wndQueueBlocker = self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:QueueBlocker")
			wndQueueBlocker:Show(true)
			local eMatchType = MatchMakingLib.MatchType.Shiphand
			if self.eSelectedMasterType == keMasterTabs.PvE then
				eMatchType = self.ePvETabSelected
			else
				eMatchType = self.ePvPTabSelected
			end
			
			if GroupLib.InGroup() then
				wndQueueBlocker:FindChild("QueuePending:Text"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_QueuePending"), ktTypeNames[eMatchType]))
				wndQueueBlocker:FindChild("QueuePending"):Show(true)
				wndQueueBlocker:FindChild("QueueActive"):Show(false)
			end
		end

	else
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndConfirmRole:GetAnchorOffsets()
		self.tWndRefs.wndConfirmRole:SetAnchorOffsets(nLeft, nTop, nRight, nBottom - wndConfirmRoleButtons:GetHeight())
		wndConfirmRoleButtons:Show(false)
		self.tWndRefs.wndConfirmRole:FindChild("Header"):SetText(Apollo.GetString("MatchMaker_QueueConfirmTitle"))
	end
	
	self.tWndRefs.wndConfirmRole:FindChild("AcceptButton"):Enable(not bRolesRequired or (arSelectedRoles and #arSelectedRoles > 0))
end

function MatchMaker:OnRoleCheckCanceled()
	if self.tWndRefs.wndMain then
		self.tWndRefs.wndMain:FindChild("TabContent:MatchContent:QueueBlocker"):Show(false)
	end
	
	if self.tWndRefs.wndConfirmRole == nil then
		return
	end

	self.tWndRefs.wndConfirmRole:Close()
end

function MatchMaker:OnRoleCheckClosed()
	self.tWndRefs.wndConfirmRole:Destroy()
	self.tWndRefs.wndConfirmRole = nil
end

function MatchMaker:OnAcceptRole()
	if not self.tQueueOptions[self.eSelectedMasterType].arRoles then
		return
	end

	MatchingGameLib.ConfirmRole(self.tQueueOptions[self.eSelectedMasterType].arRoles)
	self.tWndRefs.wndConfirmRole:Close()
end

function MatchMaker:OnCancelRole()
	MatchingGameLib.DeclineRoleCheck()
	self.tWndRefs.wndConfirmRole:Close()
end

function MatchMaker:OnToggleRoleCheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:HelperToggleRole(wndHandler:GetData(), self.eSelectedMasterType, wndHandler:IsChecked())

	self.tWndRefs.wndConfirmRole:FindChild("AcceptButton"):Enable(self.tQueueOptions[self.eSelectedMasterType].arRoles and #self.tQueueOptions[self.eSelectedMasterType].arRoles > 0)
end

-----------------------------------------------------------------------------------------------
-- In Match Functionality
-----------------------------------------------------------------------------------------------

function MatchMaker:OnLeaveGroupBtn(wndHandler, wndControl)
	MatchingGameLib.LeaveGame()
end

function MatchMaker:OnTeleportIntoMatchBtn(wndHandler, wndControl)
	if not MatchingGameLib.IsInGameInstance() then
		MatchingGameLib.TransferIntoMatch()
	end
end

function MatchMaker:OnFindReplacementsBtn(wndHandler, wndControl)
	MatchingGameLib.LookForReplacements()
end

function MatchMaker:OnCancelReplacementsBtn(wndHandler, wndControl)
	MatchingGameLib.StopLookingForReplacements()
end

-----------------------------------------------------------------------------------------------
-- Voting
-----------------------------------------------------------------------------------------------
function MatchMaker:OnVoteDisbandBtn( wndHandler, wndControl, eMouseButton )
	MatchingGameLib.InitiateVoteToSurrender()
	self:UpdateInMatchControls()
end

function MatchMaker:OnVoteSurrenderBegin()
	if not self.tWndRefs.wndVoteSurrender or not self.tWndRefs.wndVoteSurrender:IsValid() then
		self.tWndRefs.wndVoteSurrender = Apollo.LoadForm(self.xmlDoc, "VoteSurrender", nil, self)
	end
	self.tWndRefs.wndVoteSurrender:Invoke()
	
	if MatchingGameLib.IsInPvpGame() then
		self.tWndRefs.wndVoteSurrender:FindChild("Title"):SetText(Apollo.GetString("MatchMaker_VoteSurrender"))
	else
		self.tWndRefs.wndVoteSurrender:FindChild("Title"):SetText(Apollo.GetString("MatchMaker_VoteDisband"))
	end
	
	self:UpdateInMatchControls()
end

function MatchMaker:OnVoteSurrenderEnd()
	if self.tWndRefs.wndVoteSurrender then
		self.tWndRefs.wndVoteSurrender:Close()
	end
	
	self:UpdateInMatchControls()
end

function MatchMaker:OnVoteSurrenderYes(wndHandler, wndControl)
	MatchingGameLib.CastVoteSurrender(true)
	self.tWndRefs.wndVoteSurrender:Close()
end

function MatchMaker:OnVoteSurrenderNo(wndHandler, wndControl)
	MatchingGameLib.CastVoteSurrender(false)
	self.tWndRefs.wndVoteSurrender:Close()
end

function MatchMaker:OnVoteSurrenderClosed(wndHandler, wndControl)
	self.tWndRefs.wndVoteSurrender:Destroy()
	self.tWndRefs.wndVoteSurrender = nil
end

function MatchMaker:OnVoteKickBegin(tPlayerInfo)
	if not self.tWndRefs.wndVoteKick or not self.tWndRefs.wndVoteKick:IsValid() then
		self.tWndRefs.wndVoteKick = Apollo.LoadForm(self.xmlDoc, "VoteKick", nil, self)
	end
	self.tWndRefs.wndVoteKick:Invoke()
	
	self.tWndRefs.wndVoteKick:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_VoteKick"), tPlayerInfo.strCharacterName))
end

function MatchMaker:OnVoteKickEnd()
	if self.tWndRefs.wndVoteKick then
		self.tWndRefs.wndVoteKick:Close()
	end
end

function MatchMaker:OnVoteKickYes(wndHandler, wndControl)
	MatchingGameLib.CastVoteKick(true)
	self.tWndRefs.wndVoteKick:Close()
end

function MatchMaker:OnVoteKickNo(wndHandler, wndControl)
	MatchingGameLib.CastVoteKick(false)
	self.tWndRefs.wndVoteKick:Close()
end

function MatchMaker:OnVoteKickClosed(wndHandler, wndControl)
	self.tWndRefs.wndVoteKick:Destroy()
	self.tWndRefs.wndVoteKick = nil
end

-----------------------------------------------------------------------------------------------
-- PvP Teams
-----------------------------------------------------------------------------------------------
function MatchMaker:OnUpdateGuilds()
	if not GameLib.GetPlayerUnit() then
		return
	end

	local arGuilds = GuildLib.GetGuilds()
	self.tHasGuild = {}
	
	for idx, guildCurr in pairs(arGuilds) do
		self.tHasGuild[guildCurr:GetType()] = guildCurr
	end
	
	self:UpdateTeamInfo()
	if self.tWndRefs.wndMain and self.matchDisplayed then
		local eMatchType = self.matchDisplayed:GetInfo().eMatchType
		if eMatchType == MatchMakingLib.MatchType.Arena then
			self:BuildArenaControls()
		elseif eMatchType == MatchMakingLib.MatchType.Warplot then
			self:BuildWarplotControls()
		end
	end
end

function MatchMaker:OnTeamInfoBtn(wndHandler, wndControl)
	local eGuildType = wndControl:GetData()

	if eGuildType ~= nil then
		-- Position
		local tScreen = Apollo.GetDisplaySize()
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndMain:GetAnchorOffsets()
		local nMidpoint = (nRight - nLeft) / 2

		local tPos =
		{
			nX 			= nRight,
			nY 			= nTop,
			bDrawOnLeft = false
		}

		if nMidpoint + nLeft > (tScreen.nWidth / 2) then
			tPos.nX = nLeft
			tPos.bDrawOnLeft = true
		end

		if eGuildType == GuildLib.GuildType_WarParty then
			if self.tHasGuild[eGuildType] then
				Event_FireGenericEvent("Event_ShowWarpartyInfo", tPos)
			else
				Event_FireGenericEvent("GenericEvent_RegisterWarparty", tPos)
			end
		else
			if self.tHasGuild[eGuildType] then
				Event_FireGenericEvent("Event_ShowArenaInfo", eGuildType, tPos)
			else
				Event_FireGenericEvent("GenericEvent_RegisterArenaTeam", eGuildType, tPos)
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- MatchMakerForm Functions
-----------------------------------------------------------------------------------------------

function MatchMaker:OnPendingGameResponded(wndHandler, wndControl, bResponse)
	if self.tWndRefs.wndJoinGame then
		self.tWndRefs.wndJoinGame:Close()
	end
	
	if self.tWndRefs.wndMain then
		self:OnClose()
	end
end

function MatchMaker:OnFixedLevels( wndHandler, wndControl, eMouseButton )
	self.tWndRefs.wndMain:FindChild("PrimeLevelsBtn"):SetCheck(false)
	
	local wndPvETab = self.tWndRefs.wndMain:FindChild("PvETab")
	local wndSelectedTab = wndPvETab:FindChildByUserData(self.ePvETabSelected)
	self:BuildMatchList(wndSelectedTab, wndSelectedTab)
end

function MatchMaker:OnPrimeLevels( wndHandler, wndControl, eMouseButton )
	self.tWndRefs.wndMain:FindChild("FixedLevelsBtn"):SetCheck(false)
	
	local wndPvETab = self.tWndRefs.wndMain:FindChild("PvETab")
	local wndSelectedTab = wndPvETab:FindChildByUserData(self.ePvETabSelected)
	local eMatchType = wndSelectedTab:GetData()

	self:BuildMatchList(wndSelectedTab, wndSelectedTab)
end

function MatchMaker:HelperCreateContentFilter()
	local wndParent = self.tWndRefs.wndContentFilter
	local wndFilterDropdown = Apollo.LoadForm(self.xmlDoc, "FeaturedFilterDropdown", wndParent, self)
	local wndFilterContainer = wndFilterDropdown:FindChild("Container")
	
	local wndFilterAll = Apollo.LoadForm(self.xmlDoc, "FeaturedContentFilterBtn", wndFilterContainer, self)
	wndFilterAll:SetData(knFilterAll)
	wndFilterAll:SetText(ktContentTypeFilterString[knFilterAll])
	local nLeft, nTop, nRight, nBottom = wndFilterAll:GetOriginalLocation():GetOffsets()
	
	if wndParent:GetData() == knFilterAll then
		wndFilterAll:SetCheck(true)
	end
	
	local nSelectedFilterType = wndParent:GetData()
	for idx, nContentType in pairs(GameLib.CodeEnumRewardRotationContentType) do
		if nContentType == GameLib.CodeEnumRewardRotationContentType.None then
			break
		end

		local wndFilter = Apollo.LoadForm(self.xmlDoc, "FeaturedContentFilterBtn", wndFilterContainer, self)
		wndFilter:SetData(nContentType)
		wndFilter:SetText(ktContentTypeFilterString[nContentType])
				
		if nSelectedFilterType == nContentType then
			wndFilter:SetCheck(true)
		end
	end
	
	local nLeft, nTop, nRight, nBottom = wndFilterDropdown:GetOriginalLocation():GetOffsets()
	wndFilterDropdown:SetAnchorOffsets(nLeft, nTop, nRight, nTop + (#wndFilterContainer:GetChildren() * wndFilterAll:GetHeight()) + 11 )
	wndFilterContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function MatchMaker:HelperCreateFeaturedSort()
	local wndParent = self.tWndRefs.wndFeaturedSort
	local wndFilterDropdown = Apollo.LoadForm(self.xmlDoc, "FeaturedFilterDropdown", wndParent, self)
	local wndFilterContainer = wndFilterDropdown:FindChild("Container")
	
	local wndSortContentType = Apollo.LoadForm(self.xmlDoc, "FeaturedContentFilterBtn", wndFilterContainer, self)
	wndSortContentType:SetData(keFeaturedSort.ContentType)
	wndSortContentType:SetText(Apollo.GetString("MatchMaker_FeaturedSortContent"))
	local nLeft, nTop, nRight, nBottom = wndSortContentType:GetOriginalLocation():GetOffsets()
	
	if wndParent:GetData() == keFeaturedSort.ContentType then
		wndSortContentType:SetCheck(true)
	end
	
	local wndSortTimeRemaining = Apollo.LoadForm(self.xmlDoc, "FeaturedContentFilterBtn", wndFilterContainer, self)
	wndSortTimeRemaining:SetData(keFeaturedSort.TimeRemaining)
	wndSortTimeRemaining:SetText(Apollo.GetString("CRB_Time_Remaining"))
	wndSortTimeRemaining:SetAnchorOffsets(nLeft, nTop + wndSortContentType:GetHeight(), nRight, nBottom + wndSortContentType:GetHeight())
	
	if wndParent:GetData() == keFeaturedSort.TimeRemaining then
		wndSortTimeRemaining:SetCheck(true)
	end
	
	local nLeft, nTop, nRight, nBottom = wndFilterDropdown:GetOriginalLocation():GetOffsets()
	wndFilterDropdown:SetAnchorOffsets(nLeft, nTop, nRight, nTop + (#wndFilterContainer:GetChildren() * wndSortContentType:GetHeight()) + 11 )
	wndFilterContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function MatchMaker:SetContentFilterSelection(wndHandler, wndControl)
	wndControl:GetParent():GetParent():GetParent():SetData(wndControl:GetData())
	wndControl:GetParent():GetParent():GetParent():SetText(wndControl:GetText())
	
	self.tWndRefs.wndContentFilter:SetCheck(false)
	self.tWndRefs.wndFeaturedSort:SetCheck(false)
	
	self:BuildFeaturedList()
end

-----------------------------------------------------------------------------------------------
-- Dueling
-----------------------------------------------------------------------------------------------

function MatchMaker:OnAcceptDuel(wndHandler, wndControl)
	GameLib.AcceptDuel()
	if self.tWndRefs.wndDuelRequest then
		self.tWndRefs.wndDuelRequest:Destroy()
		self.tWndRefs.wndDuelRequest = nil
	end
end

function MatchMaker:OnDeclineDuel(wndHandler, wndControl)
	GameLib.DeclineDuel()
	if self.tWndRefs.wndDuelRequest then
		self.tWndRefs.wndDuelRequest:Destroy()
		self.tWndRefs.wndDuelRequest = nil
	end
end

function MatchMaker:OnDuelStateChanged(eNewState, unitOpponent)
	
	if self.tWndRefs.wndDuelWarning then
		self.tWndRefs.wndDuelWarning:Destroy()
		self.tWndRefs.wndDuelWarning = nil
	end
	
	if eNewState == GameLib.CodeEnumDuelState.WaitingToAccept then
		if not self.tWndRefs.wndDuelRequest then
			self.tWndRefs["wndDuelRequest"] = Apollo.LoadForm(self.xmlDoc, "DuelRequest", nil, self)
		end
		self.tWndRefs.wndDuelRequest:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_DuelPrompt"), unitOpponent:GetName()))
		self.tWndRefs.wndDuelRequest:Show(true)
		self.tWndRefs.wndDuelRequest:ToFront()
	else
		if self.tWndRefs.wndDuelRequest then
			self.tWndRefs.wndDuelRequest:Destroy()
			self.tWndRefs.wndDuelRequest = nil
		end
	end
	
end

function MatchMaker:OnDuelAccepted(fCountdownTime)
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_ZonePvP, String_GetWeaselString(Apollo.GetString("MatchMaker_DuelStartingTimer"), fCountdownTime), "")
	self.fDuelCountdown = fCountdownTime - 1

	self.timerDuelCountdown:Start()
end

function MatchMaker:OnDuelCountdownTimer()
	if self.fDuelCountdown <= 0 then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_ZonePvP, Apollo.GetString("Matchmaker_DuelBegin"), "")
		self.timerDuelCountdown:Stop()
	else
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_ZonePvP, self.fDuelCountdown .. "...", "")
		self.fDuelCountdown = self.fDuelCountdown - 1
	end
end

function MatchMaker:OnDuelLeftArea(fTimeRemaining)
	if not self.tWndRefs.wndDuelWarning then
		self.tWndRefs["wndDuelWarning"] = Apollo.LoadForm(self.xmlDoc, "DuelWarning", nil, self)
	end
	self.tWndRefs.wndDuelWarning:FindChild("Timer"):SetText(fTimeRemaining)
	self.tWndRefs.wndDuelWarning:Show(true)
	self.tWndRefs.wndDuelWarning:ToFront()
	self.fDuelWarning = fTimeRemaining -1
	
	self.timerDuelRangeWarning:Start()
end

function MatchMaker:OnDuelWarningTimer()
	if self.fDuelWarning <= 0 then
		if self.tWndRefs.wndDuelWarning then
			self.tWndRefs.wndDuelWarning:Destroy()
			self.tWndRefs.wndDuelWarning = nil
			self.timerDuelRangeWarning:Stop()
		end
	else
		if not self.tWndRefs.wndDuelWarning then
			self.tWndRefs["wndDuelWarning"] = Apollo.LoadForm(self.xmlDoc, "DuelWarning", nil, self)
		end
		self.tWndRefs.wndDuelWarning:FindChild("Timer"):SetText(self.fDuelWarning)
		self.fDuelWarning = self.fDuelWarning - 1
	end
end

function MatchMaker:OnDuelCancelWarning()
	if self.tWndRefs.wndDuelWarning then
		self.tWndRefs.wndDuelWarning:Destroy()
		self.tWndRefs.wndDuelWarning = nil
	end
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------

function MatchMaker:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors =
	{
		[GameLib.CodeEnumTutorialAnchor.GroupFinder] = true,
	}
	
	if not tAnchors[eAnchor] then
		return
	end
	
	local tAnchorMapping = 
	{
		[GameLib.CodeEnumTutorialAnchor.GroupFinder] = self.tWndRefs.wndMain,
	}

	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

---------------------------------------------------------------------------------------------------
--Store Updates
---------------------------------------------------------------------------------------------------
function MatchMaker:RefreshStoreLink()
	self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.Signature)
	self:UpdateTeamInfo()
end

function MatchMaker:OnUnlockBtn()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

function MatchMaker:OnGenerateSignatureTooltip(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	Tooltip.GetSignatureTooltipForm(self, wndControl, Apollo.GetString("MatchMaker_CreateATeam"))
end

-----------------------------------------------------------------------------------------------
-- Handlers for events from other addons
-----------------------------------------------------------------------------------------------
function MatchMaker:OnOpenContentFinderToUnlock(eLevelUpUnlockType, eLevelUpUnlock, nObjectId)
	if not self.tWndRefs.wndMain then
		self:OnMatchMakerOn()
	end
	
	local eMatchType = ktLevelUpUnlockToMatchTypes[eLevelUpUnlockType]
	local tMatchData = nil
	
	if ktRatedToNormal[eMatchType] then
		eMatchType = ktRatedToNormal[eMatchType]
	end
	
	-- find match data
	if self.tMatchList[eMatchType] then
		for idx, tMatch in pairs(self.tMatchList[eMatchType]) do
			if tMatch.matchNormal and tMatch.matchNormal:GetInfo().nGameId == nObjectId then
				self.matchDisplayed = tMatch.matchNormal
				self.ePvETabSelected = eType
				tMatchData = tMatch
				break
			elseif tMatch.matchVet and tMatch.matchVet:GetInfo().nGameId == nObjectId then
				self.matchDisplayed = tMatch.matchVet
				self.ePvPTabSelected = eType
				tMatchData = tMatch
				break
			end
		end
	end
	
	local wndPvEBtn = self.tWndRefs.wndMain:FindChild("PvEBtn")
	local wndPvPBtn = self.tWndRefs.wndMain:FindChild("PvPBtn")
	wndPvEBtn:SetCheck(ktPvETypes[eMatchType])
	wndPvPBtn:SetCheck(not ktPvETypes[eMatchType])
		
	if ktPvETypes[eMatchType] then
		self:OnPvETabSelected(wndPvEBtn, wndPvEBtn)
	else
		self:OnPvPTabSelected(wndPvPBtn, wndPvPBtn)
	end
end

function MatchMaker:OnSuggestedContentShowMatch(matchShown)
	if not self.tWndRefs.wndMain then
		self:OnMatchMakerOn()
	end

	local eType = matchShown:GetInfo().eMatchType
	if ktPvETypes[eType] then
		local wndPvEBtn = self.tWndRefs.wndMain:FindChild("PvEBtn")
		self.tWndRefs.wndMain:FindChild("HeaderButtons"):SetRadioSelButton("MatchMakerTabGroup", wndPvEBtn)
		self.ePvETabSelected = eType
		self:OnPvETabSelected(wndPvEBtn, wndPvEBtn)
	elseif ktPvPTypes[eType] or ktRatedPvPTypes[eType] then
		local wndPvPBtn = self.tWndRefs.wndMain:FindChild("PvPBtn")
		self.tWndRefs.wndMain:FindChild("HeaderButtons"):SetRadioSelButton("MatchMakerTabGroup", wndPvPBtn)
		
		if ktRatedToNormal[eType] then
			eType = ktRatedToNormal[eType]
		end
		
		self.ePvPTabSelected = eType
		self:OnPvPTabSelected(wndPvPBtn, wndPvPBtn)
	end
		
	self:SetMatchDetails(matchShown)
end

function MatchMaker:OnShowContentFinder()
	if not self.tWndRefs.wndMain then
		self:OnMatchMakerOn()
	end
end

function MatchMaker:LinkToStore()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

---------------------------------------------------------------------------------------------------
-- PrimeLevelEntry Functions
---------------------------------------------------------------------------------------------------

function MatchMaker:OnPrimeLevelSelected( wndHandler, wndControl, eMouseButton )
	if not self.matchDisplayed then
		return
	end
	
	local tMatchInfo = self.matchDisplayed:GetInfo()
	local tMatch = self.tMatchList[tMatchInfo.eMatchType][tMatchInfo.nGameId]
	
	tMatch.nPrimeLevel = wndControl:GetParent():GetData()
	self.tQueueOptions[self.eSelectedMasterType].nPrimeLevel = tMatch.nPrimeLevel
	self:UpdateMatchButton(tMatch, self.matchDisplayed)
	
	local strText = String_GetWeaselString(Apollo.GetString("MatchMaker_PrimeLevel"), tMatch.nPrimeLevel)
	self.tWndRefs.wndPrimeLevelBtn:SetText(strText)
	self.tWndRefs.wndPrimeLevelBtn:SetCheck(false)
	
	self:SetMatchDetails(self.matchDisplayed)
end

function MatchMaker:UpdateMatchButton( tblMatch, match )
	local wndHeader = self.tWndRefs.wndMain:FindChild("MatchTypeContainer")
	local wndChildContainer = wndHeader and wndHeader:FindChild("MatchEntries") or self.tWndRefs.wndMain:FindChild("PrimeMatchTypeContainer")
	local wndMatchButton = wndChildContainer:FindChildByUserData(match)

	if not wndMatchButton then
		return
	end
	
	local wndOption = wndMatchButton:GetParent()
	local tblMatchInfo = match:GetInfo()

	local strText = tblMatchInfo.strName
	local nMinLevel = tblMatchInfo.nMinLevel
	local nMaxLevel = tblMatchInfo.nMaxLevel

	if tblMatchInfo.nMaxPrimeLevel > 0 then
		strText = strText .. " (" .. String_GetWeaselString(Apollo.GetString("MatchMaker_PrimeLevel"), tblMatch.nPrimeLevel) .. ")"
	elseif nMinLevel > 0 then
		if nMinLevel == nMaxLevel or nMaxLevel == GameLib.GetLevelCap() then
			strText = strText .. " (" .. nMinLevel .. ")"
		else
			strText = strText .. " (" .. String_GetWeaselString(Apollo.GetString("MatchMaker_LevelRange"), nMinLevel, nMaxLevel) .. ")"
		end
	end
	
	local wndInfoButton = wndOption:FindChild("MatchBtn")
	local wndSelection = wndOption:FindChild("SelectMatch")
	if GameLib.GetPlayerUnit():GetLevel() < nMinLevel then
		wndSelection:Enable(false)
		wndInfoButton:Enable(false)
		wndSelection:SetTooltip(Apollo.GetString("PrerequisiteComp_Level"))
	end

	wndInfoButton:SetText(strText)
end

---------------------------------------------------------------------------------------------------
-- PrimeLevelMatchSelection Functions
---------------------------------------------------------------------------------------------------

function MatchMaker:SelectPrimeMatch( wndMatchSelection )
	local wndSelectMatch = wndMatchSelection:FindChild("SelectMatch")
	local wndMatchBtn = wndMatchSelection:FindChild("MatchBtn")
	
	if not wndSelectMatch:IsChecked() then
		wndSelectMatch:SetCheck(true)
	end
	
	if not wndMatchBtn:IsChecked() then
		wndMatchBtn:SetCheck(true)
	end

	-- uncheck other entries
	local wndMatchList = wndMatchSelection:GetParent()
	for idx, wndSelection in pairs(wndMatchList:GetChildren()) do
		if wndSelection ~= wndMatchSelection then
			local wndOtherSelect = wndSelection:FindChild("SelectMatch")
			local wndOtherMatch = wndSelection:FindChild("MatchBtn")
			if wndOtherSelect:IsChecked() then
				wndOtherSelect:SetCheck(false)
				wndOtherMatch:SetCheck(false)
				self:UpdateQueueList(wndOtherMatch:GetData(), false)
			end
		end
	end
	
	local matchSelected = wndMatchBtn:GetData()

	self:UpdateQueueList(matchSelected, true)
	self:SetMatchDetails(matchSelected)
	
	local tMatchInfo = matchSelected:GetInfo()
	local tMatch = self.tMatchList[tMatchInfo.eMatchType][tMatchInfo.nGameId]
	self.tQueueOptions[self.eSelectedMasterType].nPrimeLevel = tMatch.nPrimeLevel
	
	self:ForceUncheckRandomQueue()
	self:BuildRoleOptions(tMatchInfo.eMatchType)
end

function MatchMaker:UnselectPrimeMatch( wndMatchSelection )
	local wndSelectMatch = wndMatchSelection:FindChild("SelectMatch")
	local wndMatchBtn = wndMatchSelection:FindChild("MatchBtn")
	
	wndSelectMatch:SetCheck(false)
	wndMatchBtn:SetCheck(false)
	
	local matchSelected = wndMatchBtn:GetData()

	self:UpdateQueueList(matchSelected, false)
	if matchSelected then
		self:BuildRoleOptions(matchSelected:GetInfo().eMatchType)
	end
end

function MatchMaker:OnPrimeMatchSelected( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then
		return
	end
	
	local wndMatchSelection = wndControl:GetParent()
	self:SelectPrimeMatch(wndMatchSelection)
end

function MatchMaker:OnPrimeMatchChecked( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then
		return
	end

	local wndMatchSelection = wndControl:GetParent()
	self:SelectPrimeMatch(wndMatchSelection)
end

function MatchMaker:OnPrimeMatchUnchecked( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then
		return
	end

	local wndMatchSelection = wndControl:GetParent()
	self:UnselectPrimeMatch(wndMatchSelection)
end

---------------------------------------------------------------------------------------------------
-- RewardPick Functions
---------------------------------------------------------------------------------------------------

function MatchMaker:OnRewardPickInfoBtn( wndHandler, wndControl, eMouseButton )
	local wndHeaderBtns = self.tWndRefs.wndMain:FindChild("HeaderButtons")
	local wndPvEBtn = wndHeaderBtns:FindChild("PvEBtn")
	local wndPvPBtn = wndHeaderBtns:FindChild("PvPBtn")
	local wndFeaturedBtn = wndHeaderBtns:FindChild("FeaturedBtn")
	
	local tRewardEntry = wndControl:GetData()
		
	if tRewardEntry.nContentType == GameLib.CodeEnumRewardRotationContentType.Dungeon or tRewardEntry.nContentType == GameLib.CodeEnumRewardRotationContentType.DungeonNormal then
		if tRewardEntry.nMatchType == MatchMakingLib.MatchType.Shiphand or tRewardEntry.nMatchType == MatchMakingLib.MatchType.Adventure or tRewardEntry.nMatchType == MatchMakingLib.MatchType.Dungeon then
			wndPvEBtn:SetCheck(true)
			wndFeaturedBtn:SetCheck(false)
			self.tWndRefs.wndMain:FindChild("PvETab"):FindChildByUserData(self.ePvETabSelected):SetCheck(false)
			self.ePvETabSelected = tRewardEntry.nMatchType
			self:OnPvETabSelected(wndPvEBtn, wndPvEBtn)
		elseif tRewardEntry.nMatchType == MatchMakingLib.MatchType.Battleground or tRewardEntry.nMatchType == MatchMakingLib.MatchType.RatedBattleground or tRewardEntry.nMatchType == MatchMakingLib.MatchType.Warplot or tRewardEntry.nMatchType == MatchMakingLib.MatchType.OpenArena or tRewardEntry.nMatchType == MatchMakingLib.MatchType.Arena then
			wndPvPBtn:SetCheck(true)
			wndFeaturedBtn:SetCheck(false)
			self.tWndRefs.wndMain:FindChild("PvPTab"):FindChildByUserData(self.ePvPTabSelected):SetCheck(false)
			self.ePvPTabSelected = tRewardEntry.nMatchType
			self:OnPvPTabSelected(wndPvPBtn, wndPvPBtn)
		else
			wndPvEBtn:SetCheck(true)
			wndFeaturedBtn:SetCheck(false)
			self.tWndRefs.wndMain:FindChild("PvETab"):FindChildByUserData(self.ePvETabSelected):SetCheck(false)
			self.ePvETabSelected = MatchMakingLib.MatchType.Dungeon
			self:OnPvETabSelected(wndPvEBtn, wndPvEBtn)
		end		
	elseif tRewardEntry.nContentType == GameLib.CodeEnumRewardRotationContentType.PeriodicQuest then
		local wndRewards = wndControl:FindChild("Rewards")
		wndRewards:FindChild("Header"):SetText(tRewardEntry.strContentName)
		wndRewards:FindChild("MessageBody"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_InfoDirections"), tRewardEntry.strContentName))
		wndRewards:Show(true)
	elseif tRewardEntry.nContentType == GameLib.CodeEnumRewardRotationContentType.Expedition then
		wndPvEBtn:SetCheck(true)
		wndFeaturedBtn:SetCheck(false)
		self.tWndRefs.wndMain:FindChild("PvETab"):FindChildByUserData(self.ePvETabSelected):SetCheck(false)
		self.ePvETabSelected = MatchMakingLib.MatchType.Shiphand
		self:OnPvETabSelected(wndPvEBtn, wndPvEBtn)
	elseif tRewardEntry.nContentType == GameLib.CodeEnumRewardRotationContentType.WorldBoss then
		if tRewardEntry.peEvent then
			Event_FireGenericEvent("ZoneMap_OpenMapToPublicEvent", tRewardEntry.peEvent)
			wndControl:SetCheck(false)
		end
	elseif tRewardEntry.nContentType == GameLib.CodeEnumRewardRotationContentType.PvP then
		wndPvPBtn:SetCheck(true)
		wndFeaturedBtn:SetCheck(false)
		self.ePvPTabSelected = MatchMakingLib.MatchType.Battleground
		self:OnPvPTabSelected(wndPvPBtn, wndPvPBtn)
	end
end

function MatchMaker:OnRewardPickRewardsWindowClosed( wndHandler, wndControl )
	wndControl:Show(false)
end

---------------------------------------------------------------------------------------------------
-- RewardIconEntry Functions
---------------------------------------------------------------------------------------------------

function MatchMaker:OnRewardEntryGenerateTooltip( wndHandler, wndControl, eToolTipType, x, y )
	if wndHandler ~= wndControl then
		return
	end

	local tRewardInfo = wndControl:GetData()
	
	if tRewardInfo.nRewardType == GameLib.CodeEnumRewardRotationRewardType.Item and tRewardInfo.itemReward then
		if Tooltip ~= nil and Tooltip.GetItemTooltipForm ~= nil then
			Tooltip.GetItemTooltipForm(self, wndControl, tRewardInfo.itemReward, {bPrimary = true, bSelling = false, itemCompare = tRewardInfo.itemReward:GetEquippedItemForItemType()})
		end
	elseif tRewardInfo.monReward ~= nil then
		local xml = nil
		xml = XmlDoc.new()
		xml:StartTooltip(Tooltip.TooltipWidth)
		local strDisplay = tRewardInfo.monReward:GetMoneyString()
		if tRewardInfo.nMultiplier then
			strDisplay = tRewardInfo.monReward:GetTypeString()
		end
		xml:AddLine(strDisplay, kcrDefaultColor, "CRB_InterfaceMedium")
		wndControl:SetTooltipDoc(xml)
	end
end

-----------------------------------------------------------------------------------------------
-- MatchMaker Instance
-----------------------------------------------------------------------------------------------
local MatchMakerInst = MatchMaker:new()
MatchMakerInst:Init()
