-----------------------------------------------------------------------------------------------
-- Client Lua Script for QuestTracker
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "QuestLib"
require "Quest"
require "Episode"

local QuestTracker = {}

local kstrQuestAddon = "003QuestAddon"

--
local knRaidWarningSection = 10
local knContentFinderNotifySection = 15
local knQuestSection = 20

-- Episode group markers
local kstrPinnedQuestMarker = "Pinned"
local kstrWorldStoryQuestMarker = "World"
local kstrZoneStoryQuestMarker = "Zone"
local kstrRegionalStoryQuestMarker = "Regional"
local kstrImbuementQuestMarker = "Imbuement"
local kstrTaskQuestMarker = "Task"

local knXCursorOffset = 10
local knYCursorOffset = 25

local ktConToColor =
{
	[0] 												= "ffffffff",
	[Unit.CodeEnumLevelDifferentialAttribute.Grey] 		= "ff9aaea3",
	[Unit.CodeEnumLevelDifferentialAttribute.Green] 	= "ff37ff00",
	[Unit.CodeEnumLevelDifferentialAttribute.Cyan] 		= "ff46ffff",
	[Unit.CodeEnumLevelDifferentialAttribute.Blue] 		= "ff309afc",
	[Unit.CodeEnumLevelDifferentialAttribute.White] 	= "ffffffff",
	[Unit.CodeEnumLevelDifferentialAttribute.Yellow] 	= "ffffd400", -- Yellow
	[Unit.CodeEnumLevelDifferentialAttribute.Orange] 	= "ffff6a00", -- Orange
	[Unit.CodeEnumLevelDifferentialAttribute.Red] 		= "ffff0000", -- Red
	[Unit.CodeEnumLevelDifferentialAttribute.Magenta] 	= "fffb00ff", -- Purp
}

local ktConToString =
{
	[0] 												= Apollo.GetString("Unknown_Unit"),
	[Unit.CodeEnumLevelDifferentialAttribute.Grey] 		= Apollo.GetString("QuestLog_Trivial"),
	[Unit.CodeEnumLevelDifferentialAttribute.Green] 	= Apollo.GetString("QuestLog_Easy"),
	[Unit.CodeEnumLevelDifferentialAttribute.Cyan] 		= Apollo.GetString("QuestLog_Simple"),
	[Unit.CodeEnumLevelDifferentialAttribute.Blue] 		= Apollo.GetString("QuestLog_Standard"),
	[Unit.CodeEnumLevelDifferentialAttribute.White] 	= Apollo.GetString("QuestLog_Average"),
	[Unit.CodeEnumLevelDifferentialAttribute.Yellow] 	= Apollo.GetString("QuestLog_Moderate"),
	[Unit.CodeEnumLevelDifferentialAttribute.Orange] 	= Apollo.GetString("QuestLog_Tough"),
	[Unit.CodeEnumLevelDifferentialAttribute.Red] 		= Apollo.GetString("QuestLog_Hard"),
	[Unit.CodeEnumLevelDifferentialAttribute.Magenta] 	= Apollo.GetString("QuestLog_Impossible")
}

local ktGroupInfo =
{
	[kstrPinnedQuestMarker] = { nOrder = 10, strTitle = Apollo.GetString("QuestTracker_Pinned"), sprIcon = "spr_ObjectiveTracker_IconPinned" },
	[kstrWorldStoryQuestMarker] = { nOrder = 20, strTitle = Apollo.GetString("QuestTracker_WorldStory"), sprIcon = "spr_ObjectiveTracker_IconWorld" },
	[kstrZoneStoryQuestMarker] = { nOrder = 30, strTitle = Apollo.GetString("QuestTracker_ZoneStory"), sprIcon = "spr_ObjectiveTracker_IconZone" },
	[kstrRegionalStoryQuestMarker] = { nOrder = 40, strTitle = Apollo.GetString("QuestTracker_RegionalStory"), sprIcon = "spr_ObjectiveTracker_IconWorld" },
	[kstrImbuementQuestMarker] = { nOrder = 50, strTitle = Apollo.GetString("QuestTracker_Imbuement"), sprIcon = "spr_ObjectiveTracker_IconImbument" },
	[kstrTaskQuestMarker] = { nOrder = 60, strTitle = Apollo.GetString("QuestTracker_Tasks"), sprIcon = "spr_ObjectiveTracker_IconTask" },
}

local kstrRed 		= "ffff4c4c"
local kstrGreen 	= "ff2fdc02"
local kstrYellow 	= "fffffc00"
local kstrLightGrey = "ffb4b4b4"
local kstrHighlight = "ffffe153"

function QuestTracker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	
	-- Window Management
	o.tGroupWndCache = {}
	o.tEpisodeWndCache = {}
	o.tQuestWndCache = {}
	o.tObjectiveWndCache = {}

	-- Data
	o.tCurentQuestsOrdered = {}
	o.nCurentQuestsOrderedCount = 0
	o.tTimedQuests = {}
	o.tTimedObjectives = {}
	o.nTrackerCounting = -1 -- Start at -1 so that loading up with 0 quests will still trigger a resize
	o.nFlashThisQuest = nil
	o.bPlayerIsDead = false
	o.tActiveProgBarQuests = {}
	o.tClickBlinkingQuest = nil
	o.tHoverBlinkingQuest = nil
	o.bRedrawQueued = false
	o.bQuestsInitialized = false
	o.tQuestsQueuedForDestroy = {}
	o.tQueuedCommMessages = {}
	
	-- Saved data
	o.bFilterDistance = false
	o.nMaxMissionDistance = 999
	o.bShowQuests = true
	o.tMinimized =
	{
		bRoot = false,
		tQuests = {},
		tEpisode = {},
		tEpisodeGroup = {},
	}
	o.tPinned =
	{
		tQuests = {}
	}
	o.tHiddenImbu = {}

    return o
end

function QuestTracker:Init()
    Apollo.RegisterAddon(self)
end

function QuestTracker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("QuestTracker.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	self.timerResizeDelay = ApolloTimer.Create(0.1, false, "OnResizeDelayTimer", self)
	self.timerResizeDelay:Stop()
	
	self.timerRealTimeUpdate = ApolloTimer.Create(1.0, true, "OnRealTimeUpdateTimer", self)
	self.timerRealTimeUpdate:Stop()
	
	self.timerArrowBlinker = ApolloTimer.Create(4.0, true, "OnArrowBlinkerTimer", self)
	self.timerArrowBlinker:Stop()
end

function QuestTracker:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	return
	{
		tHiddenImbu = self.tHiddenImbu,
		tMinimized = self.tMinimized,
		tPinned = self.tPinned,
		bShowQuests = self.bShowQuests,
		nMaxMissionDistance = self.nMaxMissionDistance,
		bFilterDistance = self.bFilterDistance,
	}
end

function QuestTracker:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	if tSavedData.tMinimized ~= nil then
		self.tMinimized = tSavedData.tMinimized
	end
	
	if tSavedData.tPinned ~= nil then
		self.tPinned = tSavedData.tPinned
	end
	
	if tSavedData.tHiddenImbu ~= nil then
		self.tHiddenImbu = tSavedData.tHiddenImbu
	end
	
	if tSavedData.bShowQuests ~= nil then
		self.bShowQuests = tSavedData.bShowQuests
	end
	
	if tSavedData.nMaxMissionDistance ~= nil then
		self.nMaxMissionDistance = tSavedData.nMaxMissionDistance
	end
	
	if tSavedData.bFilterDistance ~= nil then
		self.bFilterDistance = tSavedData.bFilterDistance
	end
end

function QuestTracker:OnDocumentReady()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
		Apollo.AddAddonErrorText(self, "Could not load the main window document for some reason.")
		return
	end
	
	Apollo.RegisterEventHandler("ObjectiveTrackerLoaded", "OnObjectiveTrackerLoaded", self)
	
	self.bQuestTrackerByDistance = g_InterfaceOptions and g_InterfaceOptions.Carbine.bQuestTrackerByDistance or true
	self.bQuestTrackerAlignBottom = g_InterfaceOptions and g_InterfaceOptions.Carbine.bQuestTrackerAlignBottom or true
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer ~= nil then
		self.bPlayerIsDead = unitPlayer:IsDead()
	end
	
	self:InitializeWindowMeasuring()
	
	Event_FireGenericEvent("ObjectiveTracker_RequestParent")
end

function QuestTracker:InitializeWindowMeasuring() -- Try not to run these OnLoad as they may be expensive
	local wndMeasure = Apollo.LoadForm(self.xmlDoc, "EpisodeGroupItem", nil, self)
	self.knInitialEpisodeGroupHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()

	wndMeasure = Apollo.LoadForm(self.xmlDoc, "EpisodeItem", nil, self)
	self.knInitialEpisodeHeight = wndMeasure:GetHeight()
	self.kcrEpisodeTitle = wndMeasure:FindChild("EpisodeTitle"):GetTextColor()
	wndMeasure:Destroy()

	wndMeasure = Apollo.LoadForm(self.xmlDoc, "QuestItem", nil, self)
	self.knMinHeighQuestItem = wndMeasure:GetHeight()
	self.knInitialQuestControlBackerHeight = wndMeasure:FindChild("ControlBackerBtn"):GetHeight()
	self.kcrQuestNumber = wndMeasure:FindChild("QuestNumber"):GetTextColor()
	self.kcrQuestNumberBackerArt = wndMeasure:FindChild("QuestNumberBackerArt"):GetBGColor()
	wndMeasure:Destroy()

	wndMeasure = Apollo.LoadForm(self.xmlDoc, "QuestObjectiveItem", nil, self)
	self.knInitialQuestObjectiveHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()

	wndMeasure = Apollo.LoadForm(self.xmlDoc, "SpellItem", nil, self)
	self.knInitialSpellItemHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()
end

function QuestTracker:OnObjectiveTrackerLoaded(wndForm)
	if not wndForm or not wndForm:IsValid() then
		return
	end
	
	Apollo.RemoveEventHandler("ObjectiveTrackerLoaded", self)
	
	Apollo.RegisterEventHandler("ToggleShowQuests",							"OnToggleShowQuests", self)
	Apollo.RegisterEventHandler("ToggleQuestOptions",						"OnToggleQuestOptions", self)
	
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor",					"OnTutorial_RequestUIAnchor", self)
	Apollo.RegisterEventHandler("EpisodeStateChanged",						"OnEpisodeStateChanged", self)
	Apollo.RegisterEventHandler("QuestStateChanged",						"OnQuestStateChanged", self)
	Apollo.RegisterEventHandler("QuestTrackedChanged",						"OnQuestTrackedChanged", self)
	Apollo.RegisterEventHandler("QuestObjectiveUpdated",					"OnQuestObjectiveUpdated", self)
	Apollo.RegisterEventHandler("QuestInit",								"OnQuestInit", self)
	Apollo.RegisterEventHandler("Communicator_ShowQuestMsg",				"OnShowCommMsg", self)
	Apollo.RegisterEventHandler("Group_Join",								"UpdateGroup", self)
	Apollo.RegisterEventHandler("Group_Left",								"UpdateGroup", self)
	Apollo.RegisterEventHandler("Group_FlagsChanged",						"UpdateGroup", self)
	Apollo.RegisterEventHandler("SubZoneChanged",							"OnSubZoneChanged", self)
	Apollo.RegisterEventHandler("ChangeWorld",								"OnChangeWorld", self)
	Apollo.RegisterEventHandler("KeyBindingKeyChanged",						"OnKeyBindingKeyChanged", self)
	Apollo.RegisterEventHandler("PlayerResurrected",						"OnPlayerResurrected", self)
	Apollo.RegisterEventHandler("ShowResurrectDialog",						"OnShowResurrectDialog", self)
	Apollo.RegisterEventHandler("GenericEvent_QuestLog_TrackBtnClicked",	"OnGenericEvent_QuestLog_TrackBtnClicked", self) -- This is an event from QuestLog
	Apollo.RegisterEventHandler("QuestLog_ToggleLongQuestText",				"OnToggleLongQuestText", self) -- Formatting event
	Apollo.RegisterEventHandler("PlayerLevelChange",						"OnPlayerLevelChange", self)
	Apollo.RegisterEventHandler("OptionsUpdated_QuestTracker",				"OnOptionsUpdated", self)
	
	
	Apollo.RegisterTimerHandler("QuestTracker_EarliestProgBarTimer", 		"OnQuestTracker_EarliestProgBarTimer", self)
	
	
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "QuestTrackerForm", wndForm, self)
	
	self.wndQuestContainer = Apollo.LoadForm(self.xmlDoc, "ContentGroupItem", self.wndMain, self)
	self.wndQuestContainer:SetData(knQuestSection)
	self.wndQuestContainerContent = self.wndQuestContainer:FindChild("EpisodeGroupContainer")
	
	self:DrawGroup(kstrPinnedQuestMarker)
	self:DrawGroup(kstrWorldStoryQuestMarker)
	self:DrawGroup(kstrZoneStoryQuestMarker)
	self:DrawGroup(kstrRegionalStoryQuestMarker)
	self:DrawGroup(kstrImbuementQuestMarker)
	self:DrawGroup(kstrTaskQuestMarker)
	
	self:OnOptionsUpdated()
	
	local tQuestData =
	{
		["strAddon"] = Apollo.GetString("CRB_Quests"),
		["strEventMouseLeft"] = "ToggleShowQuests", 
		["strEventMouseRight"] = "ToggleQuestOptions", 
		["strIcon"] = "spr_ObjectiveTracker_IconQuest",
		["strDefaultSort"] = kstrQuestAddon,
	}
	Event_FireGenericEvent("ObjectiveTracker_NewAddOn", tQuestData)
	
	self:UpdateTutorialZoneState()
	
	if QuestLib.IsInitialized() then
		self:OnQuestInit()
	end
	
	if self.tRequestedTutorialAnchor then
		self:OnTutorial_RequestUIAnchor(unpack(self.tRequestedTutorialAnchor))
		self.tRequestedTutorialAnchor = nil
	end
end

function QuestTracker:OnToggleShowQuests()
	self.bShowQuests = not self.bShowQuests
	
	self:HelperDrawContextMenuSubOptions()
	
	self:ResizeAll()
end

function QuestTracker:OnToggleQuestOptions()
	self:DrawContextMenu()
end

---------------------------------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------------------------------

function QuestTracker:OnRealTimeUpdateTimer(nTime)
	for index, tQuestInfo in pairs(self.tTimedQuests) do
		if tQuestInfo.wndTitleFrame ~= nil then
			local strTitle = self:HelperBuildTimedQuestTitle(tQuestInfo.queQuest)
			tQuestInfo.wndTitleFrame:SetAML(strTitle)
		else
			self.tTimedQuests[index] = nil
		end
	end

	for index, tObjectiveInfo in pairs(self.tTimedObjectives) do
		local wndCurrObjective = tObjectiveInfo.wndObjective
		if wndCurrObjective ~= nil and wndCurrObjective:FindChild("QuestObjectiveBtn") ~= nil then
			wndCurrObjective:FindChild("QuestObjectiveText"):SetAML(self:BuildObjectiveTitleString(tObjectiveInfo.queQuest, tObjectiveInfo.tObjective))
		else
			self.tTimedObjectives[index] = nil
		end
	end

	if self.bFilterDistance or self.bQuestTrackerByDistance then
		self:ResizeAll()
	end
	
	if (next(self.tTimedQuests) == nil and next(self.tTimedObjectives) == nil and not self.bFilterDistance and not self.bQuestTrackerByDistance)
		or (not self.bShowQuests) then
		self.timerRealTimeUpdate:Stop()
	end
end

function QuestTracker:OnResizeDelayTimer(nTime)
	self:ResizeAll()
end

function QuestTracker:BuildAll()
	if not self.bQuestsInitialized then
		return
	end

	for idx, epiEpisode in pairs(QuestLib.GetTrackedEpisodes(self.bQuestTrackerByDistance)) do
		if epiEpisode:IsWorldStory() then
			self:DrawEpisode(kstrWorldStoryQuestMarker, epiEpisode)
		elseif epiEpisode:IsZoneStory() then
			self:DrawEpisode(kstrZoneStoryQuestMarker, epiEpisode)
		elseif epiEpisode:IsRegionalStory() then
			self:DrawEpisode(kstrRegionalStoryQuestMarker, epiEpisode)
		else -- Task
			for nIdx, queQuest in pairs(epiEpisode:GetTrackedQuests(0, self.bQuestTrackerByDistance)) do
				self:DrawQuest(queQuest)
			end
		end
	end
	self:BuildContentFinderNotification()
	self:ResizeContentFinderNotification()
end

function QuestTracker:BuildContentFinderNotification()
	if self.wndContentFinderNotification == nil then
		self.wndContentFinderNotification = Apollo.LoadForm(self.xmlDoc, "ContentFinderNotification", self.wndMain, self)
		self.wndContentFinderNotification:SetData(knContentFinderNotifySection)
	end
end

function QuestTracker:ResizeContentFinderNotification()
	local wndContentFinderNotificationText = self.wndContentFinderNotification:FindChild("Text")
	local strText = ""
	local strData = wndContentFinderNotificationText:GetData()
	local strKeyBinding = GameLib.GetKeyBinding("GroupFinder")
	if  strData == nil or strData ~= strKeyBinding then
		if strKeyBinding ~= "Unbound" then
			strText = String_GetWeaselString(Apollo.GetString("QuestTracker_OpenContentFinderKeybinding"), strKeyBinding)
		else
			strText = Apollo.GetString("QuestTracker_OpenContentFinder")
		end
		
		wndContentFinderNotificationText:SetData(strKeyBinding)
		wndContentFinderNotificationText:SetAML("<P TextColor=\"UI_WindowTextCraftingRedCapacitor\" Font=\"CRB_Header10\">" .. strText .. "</P>")
		
		local nWidth, nHeight = wndContentFinderNotificationText:SetHeightToContentHeight()
	
		local nTextLeft, nTextTop, nTextRight, nTextBottom = wndContentFinderNotificationText:GetOriginalLocation():GetOffsets()
		local nOriginalTextHeight = nTextBottom - nTextTop
		
		local nDiff = 0
		if nHeight > nOriginalTextHeight then
			-- Expand
			nDiff = nHeight - nOriginalTextHeight
		else
			-- Contract
			local nHalfDiff = (nOriginalTextHeight - nHeight) / 2
			wndContentFinderNotificationText:SetAnchorOffsets(nTextLeft, nTextTop + nHalfDiff, nTextRight, nTextBottom + nHalfDiff) -- Center window vertically
		end
		
		local nLeft, nTop, nRight, nBottom = self.wndContentFinderNotification:GetOriginalLocation():GetOffsets()	
		local nOriginalHeight = nBottom - nTop
		self.wndContentFinderNotification:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nOriginalHeight + nDiff)
	end
end

function QuestTracker:RenumberAll()
	local nQuestCounting = 0
	for idx, epiEpisode in pairs(QuestLib.GetTrackedEpisodes(self.bQuestTrackerByDistance)) do
		for nIdx, queQuest in pairs(epiEpisode:GetTrackedQuests(0, self.bQuestTrackerByDistance)) do
			nQuestCounting = nQuestCounting + 1
			
			local tQuest = self.tQuestWndCache[queQuest:GetId()]
			if tQuest ~= nil and tQuest.wndQuest ~= nil and tQuest.wndQuest:IsValid() then
				local tQuestData = tQuest.wndQuest:GetData()
				tQuestData.nSort = nQuestCounting
				tQuest.wndQuest:SetData(tQuestData)
				tQuest.wndQuest:FindChild("QuestNumber"):SetText(nQuestCounting)
			end
		end
	
		local tEpisode = self.tEpisodeWndCache[epiEpisode:GetId()]
		if tEpisode ~= nil and tEpisode.wndEpisode ~= nil and tEpisode.wndEpisode:IsValid() then
			local tEpisodeData = tEpisode.wndEpisode:GetData()
			tEpisodeData.nSort = idx
			tEpisode.wndEpisode:SetData(tEpisodeData)
		end
	end
	
	return nQuestCounting
end

function QuestTracker:ResizeAll()
	self.timerResizeDelay:Stop()

	local nStartingHeight = self.wndMain:GetHeight()
	local bStartingShown = self.wndMain:IsShown()

	local nQuestCounting = self:RenumberAll()

	if self.bShowQuests then
		if self.tMinimized.bRoot then
			self.wndQuestContainerContent:Show(false)
			
			local nLeft, nTop, nRight, nBottom = self.wndQuestContainer:GetOriginalLocation():GetOffsets()
			self.wndQuestContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
		else
			-- Resize quests
			for idx, wndEpisodeGroup in pairs(self.wndQuestContainerContent:GetChildren()) do
				self:ResizeGroup(wndEpisodeGroup)
			end
			
			local nChildHeight = self.wndQuestContainerContent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
				return wndLeft:GetData().nSort < wndRight:GetData().nSort
			end)
			
			if nChildHeight == 0 then
				nQuestCounting = 0
			end
			
			local nHeightChange = nChildHeight - self.wndQuestContainerContent:GetHeight()
			self.wndQuestContainerContent:Show(true)
			
			local nLeft, nTop, nRight, nBottom = self.wndQuestContainer:GetAnchorOffsets()
			self.wndQuestContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeightChange)
		end
		
		if self.wndContentFinderNotification and self.wndContentFinderNotification:IsValid() then
			self.wndContentFinderNotification:Show(nQuestCounting <= 0)
			self.wndMain:FindChild("ContentGroupItem"):Show(nQuestCounting > 0)
		end
		
		-- Resize quest and raid notice
		local nMainHeightChange = self.wndMain:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
			return wndLeft:GetData() < wndRight:GetData()
		end) - self.wndMain:GetHeight()
		
		local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
		self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nMainHeightChange)
	end
	local bShowMain = (not self.bIsTutorialZone and self.bShowQuests)
		or (self.bIsTutorialZone and nQuestCounting > 0  and self.bShowQuests)
	self.wndMain:Show(bShowMain)
	
	if nStartingHeight ~= self.wndMain:GetHeight() or self.nTrackerCounting ~= nQuestCounting or bShowMain ~= bStartingShown then
		local tData =
		{
			["strAddon"] = Apollo.GetString("CRB_Quests"),
			["strText"] = nQuestCounting,
			["bChecked"] = self.bShowQuests,
		}
	
		Event_FireGenericEvent("ObjectiveTracker_UpdateAddOn", tData)
	end
	
	if nQuestCounting > 0 and (self.bFilterDistance or self.bQuestTrackerByDistance) then
		self.timerRealTimeUpdate:Start()
	end
	
	self.nTrackerCounting = nQuestCounting
end

function QuestTracker:DrawGroup(strEpisodeGroupMarker)
	local wndGroup = self.tGroupWndCache[strEpisodeGroupMarker]
	if wndGroup == nil or not wndGroup:IsValid() then
		wndGroup = Apollo.LoadForm(self.xmlDoc, "EpisodeGroupItem", self.wndQuestContainerContent, self)
		self.tGroupWndCache[strEpisodeGroupMarker] = wndGroup
	end
	
	local tGroup = ktGroupInfo[strEpisodeGroupMarker]
	
	wndGroup:SetData({ strGroupMarker = strEpisodeGroupMarker, nSort = tGroup.nOrder })

	local wndGroupMinimizeBtn = wndGroup:FindChild("EpisodeGroupMinimizeBtn")
	if self.tMinimized.tEpisodeGroup[strEpisodeGroupMarker] then
		wndGroupMinimizeBtn:SetCheck(true)
	end
	wndGroupMinimizeBtn:SetData(strEpisodeGroupMarker)
	wndGroupMinimizeBtn:Show(wndGroupMinimizeBtn:IsChecked())
	
	wndGroup:FindChild("EpisodeGroupTitle"):SetText(tGroup.strTitle)
	wndGroup:FindChild("EpisodeGroupIcon"):SetSprite(tGroup.sprIcon)
end

function QuestTracker:ResizeGroup(wndEpisodeGroup)
	local nOngoingGroupCount = self.knInitialEpisodeGroupHeight
	
	local wndEpisodeGroupContainer = wndEpisodeGroup:FindChild("EpisodeGroupContainer")
	local arChildren = wndEpisodeGroupContainer:GetChildren()
	if #arChildren == 0 then
		wndEpisodeGroup:Show(false)
		return
	end
	wndEpisodeGroup:Show(true)
	
	local bEpisodeGroupMinimizeBtnChecked = wndEpisodeGroup:FindChild("EpisodeGroupMinimizeBtn"):IsChecked()
	
	if not bEpisodeGroupMinimizeBtnChecked then
		for idx, wndEpisode in pairs(arChildren) do
			local strWindowName = wndEpisode:GetName()
			
			if strWindowName == "EpisodeItem" then
				self:ResizeEpisode(wndEpisode)
			elseif strWindowName == "QuestItem" then
				self:ResizeQuest(wndEpisode)
			end
		end
		
		local nChildHeight = wndEpisodeGroupContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
			return wndLeft:GetData().nSort < wndRight:GetData().nSort
		end)
		
		nOngoingGroupCount = nOngoingGroupCount + nChildHeight
		wndEpisodeGroup:Show(nChildHeight > 0)
	else
		wndEpisodeGroup:Show(true)
	end
	wndEpisodeGroupContainer:Show(not bEpisodeGroupMinimizeBtnChecked)

	local nLeft, nTop, nRight, nBottom = wndEpisodeGroup:GetAnchorOffsets()
	wndEpisodeGroup:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nOngoingGroupCount)
end

function QuestTracker:DestroyEpisode(epiEpisode)
	local tEpisode = self.tEpisodeWndCache[epiEpisode:GetId()]
	if tEpisode ~= nil then
		local wndEpisode = tEpisode.wndEpisode
		if wndEpisode ~= nil and wndEpisode:IsValid() then
			wndEpisode:Destroy()
		end
	end
	self.tEpisodeWndCache[epiEpisode:GetId()] = nil
	
	for index, tQuest in pairs(self.tQuestWndCache) do
		if tQuest.epiEpisode == epiEpisode then
			if tQuest.wndQuest ~= nil and tQuest.wndQuest:IsValid() then
				tQuest.wndQuest:Destroy()
			end
		
			self.tQuestWndCache[index] = nil
			self.tQueuedCommMessages[tQuest.queQuest:GetId()] = nil
			
			if self.tClickBlinkingQuest ~= nil and self.tClickBlinkingQuest == queQuest then
				self.tClickBlinkingQuest = nil
				self.timerArrowBlinker:Stop()
			end
		end
	end
	
	for index, tObjective in pairs(self.tObjectiveWndCache) do
		if tObjective.epiEpisode == epiEpisode then
			if tObjective.wndObjective ~= nil and tObjective.wndObjective:IsValid() then
				tObjective.wndObjective:Destroy()
			end
			if tObjective.wndObjectiveProg ~= nil and tObjective.wndObjectiveProg:IsValid() then
				tObjective.wndObjectiveProg:Destroy()
			end
			if tObjective.wndSpellBtn ~= nil and tObjective.wndSpellBtn:IsValid() then
				tObjective.wndSpellBtn:Destroy()
			end
			
			self.tObjectiveWndCache[index] = nil
		end 
	end
end

function QuestTracker:DrawEpisode(strEpisodeGroupMarker, epiEpisode)
	local tEpisode = self.tEpisodeWndCache[epiEpisode:GetId()]
	local wndEpisode = nil
	if tEpisode ~= nil then
		wndEpisode = tEpisode.wndEpisode
	end
	if wndEpisode == nil or not wndEpisode:IsValid() then
		local wndGroup = self.tGroupWndCache[strEpisodeGroupMarker]
		if wndGroup == nil or not wndGroup:IsValid() then
			return
		end
		
		wndEpisode = Apollo.LoadForm(self.xmlDoc, "EpisodeItem", wndGroup:FindChild("EpisodeGroupContainer"), self)
		wndEpisode:SetData({ epiEpisode = epiEpisode, nSort = 99 })
		self.tEpisodeWndCache[epiEpisode:GetId()] = { wndEpisode = wndEpisode, epiEpisode = epiEpisode }
	end
	
	local strTitle = epiEpisode:GetTitle()
	local arTrackedQuests = epiEpisode:GetTrackedQuests()
	if arTrackedQuests ~= nil then
		local nTrackedQuests = #arTrackedQuests
		if nTrackedQuests > 1 then
			strTitle = string.format("%s [%d]", strTitle, nTrackedQuests)
		end
	end
	wndEpisode:FindChild("EpisodeTitle"):SetText(strTitle)
	
	local wndEpisodeMinimizeBtn = wndEpisode:FindChild("EpisodeMinimizeBtn")
	wndEpisodeMinimizeBtn:SetData(epiEpisode)
	
	if self.tMinimized.tEpisode[epiEpisode:GetId()] then
		wndEpisodeMinimizeBtn:SetCheck(true)
	end
	
	for nIdx, queQuest in pairs(epiEpisode:GetTrackedQuests(0, self.bQuestTrackerByDistance)) do
		self:DrawQuest(queQuest)
	end
end

function QuestTracker:ResizeEpisode(wndEpisode)
	local nOngoingTopCount = self.knInitialEpisodeHeight
	local wndEpisodeQuestContainer = wndEpisode:FindChild("EpisodeQuestContainer")
	local bEpisodeMinimizeBtnChecked = wndEpisode:FindChild("EpisodeMinimizeBtn"):IsChecked()

	if not bEpisodeMinimizeBtnChecked then
		for idx1, wndQuest in pairs(wndEpisodeQuestContainer:GetChildren()) do
			self:ResizeQuest(wndQuest)
		end
		
		local nChildHeight = wndEpisodeQuestContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
			return wndLeft:GetData().nSort < wndRight:GetData().nSort
		end)
		
		nOngoingTopCount = nOngoingTopCount + nChildHeight
		wndEpisode:Show(nChildHeight > 0)
	else
		wndEpisode:Show(true)
	end
	
	local nLeft, nTop, nRight, nBottom = wndEpisode:GetAnchorOffsets()
	wndEpisode:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nOngoingTopCount)
	wndEpisodeQuestContainer:Show(not bEpisodeMinimizeBtnChecked)
	
end

function QuestTracker:DestroyQuest(queQuest)
	local tQuest = self.tQuestWndCache[queQuest:GetId()]
	if tQuest ~= nil then
		local wndQuest = tQuest.wndQuest
		if wndQuest ~= nil and wndQuest:IsValid() then
			wndQuest:Destroy()
		end
	end
	self.tQuestWndCache[queQuest:GetId()] = nil
	
	for index, tObjective in pairs(self.tObjectiveWndCache) do
		if tObjective.queQuest == queQuest then
			if tObjective.wndObjective ~= nil and tObjective.wndObjective:IsValid() then
				tObjective.wndObjective:Destroy()
			end
			if tObjective.wndObjectiveProg ~= nil and tObjective.wndObjectiveProg:IsValid() then
				tObjective.wndObjectiveProg:Destroy()
			end
			if tObjective.wndSpellBtn ~= nil and tObjective.wndSpellBtn:IsValid() then
				tObjective.wndSpellBtn:Destroy()
			end
			
			self.tObjectiveWndCache[index] = nil
		end
	end
	
	self.tQueuedCommMessages[queQuest:GetId()] = nil
	
	if self.tClickBlinkingQuest ~= nil and self.tClickBlinkingQuest == queQuest then
		self.tClickBlinkingQuest = nil
		self.timerArrowBlinker:Stop()
	end
end

function QuestTracker:DrawQuest(queQuest)
	if not queQuest:IsTracked() then
		self:DestroyQuest(queQuest)
		return
	end
	
	local tQuest = self.tQuestWndCache[queQuest:GetId()]
	local wndQuest = nil
	if tQuest ~= nil then
		wndQuest = tQuest.wndQuest
	end
	if wndQuest == nil or not wndQuest:IsValid() then
		local epiEpisode = queQuest:GetEpisode()
		if epiEpisode == nil then
			return
		end
		local wndContainer = nil
	
		if self.tPinned.tQuests[queQuest:GetId()] then
			local wndGroup = self.tGroupWndCache[kstrPinnedQuestMarker]
			if wndGroup == nil or not wndGroup:IsValid() then
				return
			end
			wndContainer = wndGroup:FindChild("EpisodeGroupContainer")
		elseif queQuest:IsImbuementQuest() then
			local wndGroup = self.tGroupWndCache[kstrImbuementQuestMarker]
			if wndGroup == nil or not wndGroup:IsValid() then
				return
			end
			wndContainer = wndGroup:FindChild("EpisodeGroupContainer")
		elseif not epiEpisode:IsWorldStory() and not epiEpisode:IsZoneStory() and not epiEpisode:IsRegionalStory() then
			local wndGroup = self.tGroupWndCache[kstrTaskQuestMarker]
			if wndGroup == nil or not wndGroup:IsValid() then
				return
			end
			wndContainer = wndGroup:FindChild("EpisodeGroupContainer")
		else
			local tEpisode = self.tEpisodeWndCache[epiEpisode:GetId()]
			local wndEpisode = nil
			if tEpisode ~= nil then
				wndEpisode = tEpisode.wndEpisode
			end
			if wndEpisode == nil or not wndEpisode:IsValid() then
				return
			end
			
			wndContainer = wndEpisode:FindChild("EpisodeQuestContainer")
		end
		
		wndQuest = Apollo.LoadForm(self.xmlDoc, "QuestItem", wndContainer, self)
		wndQuest:SetData({ queQuest = queQuest, nSort = 99 })
		self.tQuestWndCache[queQuest:GetId()] = { wndQuest = wndQuest, queQuest = queQuest, epiEpisode = epiEpisode }
	end
	
	-- Quest Title
	local strTitle = queQuest:IsBreadcrumb() and Apollo.GetString("QuestTracker_Intro") .. queQuest:GetTitle() or queQuest:GetTitle()
	local eQuestState = queQuest:GetState()
	if eQuestState == Quest.QuestState_Botched then
		strTitle = string.format("<T Font=\"CRB_Interface10\" TextColor=\"%s\">%s</T>", kstrRed, String_GetWeaselString(Apollo.GetString("QuestTracker_Failed"), strTitle))
	elseif eQuestState == Quest.QuestState_Achieved then
		strTitle = string.format("<T Font=\"CRB_Interface10\" TextColor=\"%s\">%s</T>", kstrGreen,String_GetWeaselString(Apollo.GetString("QuestTracker_Complete"), strTitle))
	elseif (eQuestState == Quest.QuestState_Accepted or eQuestState == Quest.QuestState_Achieved) and queQuest:IsQuestTimed() then
		strTitle = self:HelperBuildTimedQuestTitle(queQuest)
		self.tTimedQuests[queQuest:GetId()] = { queQuest = queQuest, wndTitleFrame = wndQuest:FindChild("TitleText") }
		self.timerRealTimeUpdate:Start()
	else
		local strColor = self.tActiveProgBarQuests[queQuest:GetId()] and "ffffffff" or kstrLightGrey
		local crLevelConDiff = ktConToColor[queQuest:GetColoredDifficulty() or 0]
		strTitle = string.format("<T Font=\"CRB_Interface10\" TextColor=\"%s\">%s </T><T Font=\"CRB_Interface10\" TextColor=\"%s\">(%s)</T>", strColor, strTitle, crLevelConDiff, queQuest:GetConLevel())
	end
	
	wndQuest:FindChild("TitleText"):SetAML(strTitle)
	wndQuest:FindChild("TitleText"):SetHeightToContentHeight()

	wndQuest:FindChild("QuestOpenMapBtn"):SetData(queQuest)
	wndQuest:FindChild("QuestCallbackBtn"):SetData(queQuest)
	wndQuest:FindChild("QuestGearBtn"):SetData(queQuest)
	wndQuest:FindChild("ControlBackerBtn"):SetData({ queQuest = queQuest, wndQuest =  wndQuest })
	wndQuest:FindChild("ControlBackerBtn"):SetText(GameLib.GetKeyBinding("Interact").." >")
	
	self:HelperSelectInteractHintArrowObject(queQuest, wndQuest:FindChild("ControlBackerBtn"))
	
	local bMinimized = self.tMinimized.tQuests[queQuest:GetId()]
	local wndQuestNumber = wndQuest:FindChild("QuestNumber")
	local wndQuestNumberBackerArt = wndQuest:FindChild("QuestNumberBackerArt")
	local wndObjectiveContainer = wndQuest:FindChild("ObjectiveContainer")

	-- Conditional drawing
	wndQuest:FindChild("QuestNumberUpdateHighlight"):Show(self.tActiveProgBarQuests[queQuest:GetId()] ~= nil)
	wndQuestNumber:SetText(nIdx)
	wndQuestNumber:SetTextColor(ApolloColor.new("ff31fcf6"))
	wndQuest:FindChild("QuestCompletedBacker"):Show(false)
	wndQuestNumberBackerArt:SetBGColor(CColor.new(1,1,1,1))
	wndQuestNumberBackerArt:SetSprite("sprQT_NumBackerNormal")
	
	-- State depending drawing
	if eQuestState == Quest.QuestState_Botched then
		self:HelperShowQuestCallbackBtn(wndQuest, queQuest, "sprQT_NumBackerFailed", "CRB_QuestTrackerSprites:btnQT_QuestFailed")

	elseif eQuestState == Quest.QuestState_Achieved then
		self:HelperShowQuestCallbackBtn(wndQuest, queQuest, "sprQT_NumBackerCompleted", "CRB_QuestTrackerSprites:btnQT_QuestRedeem")

		for idx, tObjective in pairs(queQuest:GetVisibleObjectiveData()) do
			if tObjective.nCompleted >= tObjective.nNeeded then
				self:DestroyObjective(queQuest, tObjective.nIndex)
			end
		end
		self:DrawQuestSpell(queQuest, wndQuest)

		local wndObjective = wndObjectiveContainer:FindChild("ObjectiveCompleted")
		if wndObjective == nil or not wndObjective:IsValid() then
			wndObjective = Apollo.LoadForm(self.xmlDoc, "QuestObjectiveItem", wndQuest:FindChild("ObjectiveContainer"), self)
			wndObjective:SetName("ObjectiveCompleted")
		end
		
		wndObjective:FindChild("QuestObjectiveBtn"):SetData({["queOwner"] = queQuest, ["nObjectiveIdx"] = nil})
		wndObjective:FindChild("QuestObjectiveText"):SetAML(self:BuildObjectiveTitleString(queQuest))

	else
		self:DrawQuestSpell(queQuest, wndQuest)
		
		for idx, tObjective in pairs(queQuest:GetVisibleObjectiveData()) do
			if tObjective.nCompleted < tObjective.nNeeded then
				self:DrawObjective(queQuest, tObjective.nIndex)
			else
				self:DestroyObjective(queQuest, tObjective.nIndex)
			end
		end
	end
end

function QuestTracker:ResizeQuest(wndQuest)
	local queQuest = wndQuest:GetData().queQuest

	local bFilterQuest = self.bFilterDistance and self.nMaxMissionDistance > 0 and queQuest:GetDistance() > self.nMaxMissionDistance and not queQuest:IsImbuementQuest() and not queQuest:IgnoreProximityFilter()
	wndQuest:Show(not bFilterQuest)
	if bFilterQuest then
		return
	end

	local nQuestTextWidth, nQuestTextHeight = wndQuest:FindChild("TitleText"):SetHeightToContentHeight()
	local nResult = math.max(self.knInitialQuestControlBackerHeight, nQuestTextHeight + 2) -- for lower g height

	local wndControlBackerBtn = wndQuest:FindChild("ControlBackerBtn")
	if wndControlBackerBtn then
		local nLeft, nTop, nRight, nBottom = wndControlBackerBtn:GetAnchorOffsets()
		wndControlBackerBtn:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nResult)
	end

	-- If expanded and valid, make it bigger
	local nHeaderHeight = nResult
	local wndObjectiveContainer = wndQuest:FindChild("ObjectiveContainer")
	if wndObjectiveContainer then
		
		local bMinimized = self.tMinimized.tQuests[queQuest:GetId()]
		
		local wndQuestNumber = wndQuest:FindChild("QuestNumber")
		local wndQuestNumberBackerArt = wndQuest:FindChild("QuestNumberBackerArt")
		local wndObjectiveContainer = wndQuest:FindChild("ObjectiveContainer")
		
		if bMinimized then
			wndQuestNumber:SetTextColor(CColor.new(.5, .5, .5, .8))
			wndQuestNumberBackerArt:SetBGColor(CColor.new(.5, .5, .5, .8))
		
		elseif eQuestState == Quest.QuestState_Botched then
			self:HelperShowQuestCallbackBtn(wndQuest, queQuest, "sprQT_NumBackerFailed", "CRB_QuestTrackerSprites:btnQT_QuestFailed")
			wndQuestNumber:SetTextColor(ApolloColor.new(kstrRed))
		
		elseif eQuestState == Quest.QuestState_Achieved then
			self:HelperShowQuestCallbackBtn(wndQuest, queQuest, "sprQT_NumBackerCompleted", "CRB_QuestTrackerSprites:btnQT_QuestRedeem")
			wndQuestNumber:SetTextColor(ApolloColor.new("ff7fffb9"))
		else
			wndQuestNumber:SetTextColor(self.kcrQuestNumber)
			wndQuestNumberBackerArt:SetBGColor(self.kcrQuestNumberBackerArt)
		end
		
		if not bMinimized then
			for idx, wndObj in pairs(wndObjectiveContainer:GetChildren()) do
				self:ResizeObjective(wndObj)
			end
			
			local nChildrenHeight = wndObjectiveContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
			local nLeft, nTop, nRight, nBottom = wndObjectiveContainer:GetAnchorOffsets()
			wndObjectiveContainer:SetAnchorOffsets(nLeft, nHeaderHeight, nRight, nHeaderHeight + nChildrenHeight)
			nResult = nHeaderHeight + nChildrenHeight
		end
		
		wndObjectiveContainer:Show(not bMinimized)
	end

	local nLeft, nTop, nRight, nBottom = wndQuest:GetAnchorOffsets()
	nResult = math.max(nResult, self.knMinHeighQuestItem)
	wndQuest:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nResult  + 8) -- Bottom padding per quest
end

function QuestTracker:DrawQuestSpell(queQuest, wndQuest)
	if queQuest:GetSpell() then
		local wndSpellItem = wndQuest:FindChild("ObjectiveContainer"):FindChild("SpellItem")
		if wndSpellItem == nil or not wndSpellItem:IsValid() then
			wndSpellItem = Apollo.LoadForm(self.xmlDoc, "SpellItem", wndQuest:FindChild("ObjectiveContainer"), self)
		end
		
		wndSpellItem:FindChild("SpellItemBtn"):Show(true)
		wndSpellItem:FindChild("SpellItemBtn"):SetContentId(queQuest)
		wndSpellItem:FindChild("SpellItemText"):SetText(String_GetWeaselString(Apollo.GetString("QuestTracker_UseQuestAbility"), GameLib.GetKeyBinding("CastObjectiveAbility")))
	end
end

function QuestTracker:DestroyObjective(queQuest, nIndex)
	local strWindowCacheKey = tostring(queQuest:GetId()).."O"..nIndex
	local tObjective = self.tObjectiveWndCache[strWindowCacheKey]
	if tObjective ~= nil then
		local wndObjective = tObjective.wndObjective
		if wndObjective ~= nil and wndObjective:IsValid() then
			wndObjective:Destroy()
		end
	end
	self.tObjectiveWndCache[strWindowCacheKey] = nil
	
	local strProgressWindowCacheKey = strWindowCacheKey.."QuestProgressItem"
	local tObjectiveProg = self.tObjectiveWndCache[strProgressWindowCacheKey]
	if tObjectiveProg ~= nil then
		local wndObjectiveProg = tObjectiveProg.wndObjectiveProg
		if wndObjectiveProg ~= nil and wndObjectiveProg:IsValid() then
			wndObjectiveProg:Destroy()
		end
	end
	self.tObjectiveWndCache[strProgressWindowCacheKey] = nil
	
	local strSpellWindowCacheKey = strWindowCacheKey.."SpellItemObjectiveBtn"
	local tSpellBtn = self.tObjectiveWndCache[strSpellWindowCacheKey]
	if tSpellBtn ~= nil then
		local wndSpellBtn = tSpellBtn.wndSpellBtn
		if wndSpellBtn ~= nil and wndSpellBtn:IsValid() then
			wndSpellBtn:Destroy()
		end
	end
	self.tObjectiveWndCache[strSpellWindowCacheKey] = nil
end

function QuestTracker:DrawObjective(queQuest, nIndex)
	local strWindowCacheKey = tostring(queQuest:GetId()).."O"..nIndex
	local tWndObjective = self.tObjectiveWndCache[strWindowCacheKey]
	local wndQuest = nil
	local wndObjective = nil
	if tWndObjective ~= nil then
		wndObjective = tWndObjective.wndObjective
	end
	local tQuest = self.tQuestWndCache[queQuest:GetId()]
	if tQuest ~= nil then
		wndQuest = tQuest.wndQuest
	end
	if wndQuest == nil or not wndQuest:IsValid() then
		return
	end
	if wndObjective == nil or not wndObjective:IsValid() then
		wndObjective = Apollo.LoadForm(self.xmlDoc, "QuestObjectiveItem", wndQuest:FindChild("ObjectiveContainer"), self)
		self.tObjectiveWndCache[strWindowCacheKey] = { wndObjective = wndObjective, nIndex = nIndex, queQuest = queQuest, epiEpisode = epiEpisode }
	end
	
	local tObjective = nil
	for idx, tObjectiveToFind in pairs(queQuest:GetVisibleObjectiveData()) do
		if tObjectiveToFind.nIndex == nIndex then
			tObjective = tObjectiveToFind
			break
		end
	end
	
	if queQuest:IsObjectiveTimed(tObjective.nIndex) then
		self.tTimedObjectives[strWindowCacheKey] = { queQuest = queQuest, tObjective = tObjective, wndObjective = wndObjective }
		self.timerRealTimeUpdate:Start()
	end
	
	local wndQuestObjectiveBtn = wndObjective:FindChild("QuestObjectiveBtn")
	wndQuestObjectiveBtn:SetData({["queOwner"] = queQuest, ["nObjectiveIdx"] = tObjective.nIndex})
	wndObjective:FindChild("QuestObjectiveText"):SetAML(self:BuildObjectiveTitleString(queQuest, tObjective))

	-- Progress
	local strProgressWindowCacheKey = strWindowCacheKey.."QuestProgressItem"
	local tObjectiveProg = self.tObjectiveWndCache[strProgressWindowCacheKey]
	if self.tActiveProgBarQuests[queQuest:GetId()] and queQuest:DisplayObjectiveProgressBar(tObjective.nIndex) then
		local wndObjectiveProg = nil
		if tObjectiveProg ~= nil then
			wndObjectiveProg = tObjectiveProg.wndObjectiveProg
		end
		if wndObjectiveProg ~= nil and wndObjectiveProg:IsValid() then
			wndObjectiveProg = Apollo.LoadForm(self.xmlDoc, "QuestProgressItem", wndQuest:FindChild("ObjectiveContainer"), self)
			self.tObjectiveWndCache[strProgressWindowCacheKey] = { wndObjectiveProg = wndObjectiveProg, nIndex = nIndex, queQuest = queQuest, epiEpisode = epiEpisode }
		end
		
		local nCompleted = tObjective.nCompleted
		local nNeeded = tObjective.nNeeded

		local wndQuestProgressBar = wndObjectiveProg:FindChild("QuestProgressBar")
		wndQuestProgressBar:SetMax(nNeeded)
		wndQuestProgressBar:SetProgress(nCompleted)
		wndQuestProgressBar:EnableGlow(nCompleted > 0 and nCompleted ~= nNeeded)
	elseif tObjectiveProg ~= nil then
		local wndObjectiveProg = tObjectiveProg.wndObjectiveProg
		if wndObjectiveProg ~= nil and wndObjectiveProg:IsValid() then
			wndObjectiveProg:Destroy()
		end
		self.tObjectiveWndCache[strProgressWindowCacheKey] = nil
	end

	-- Objective Spell Item
	if queQuest:GetSpell(tObjective.nIndex) then
		local strSpellWindowCacheKey = strWindowCacheKey.."SpellItemObjectiveBtn"
		local tSpellBtn = self.tObjectiveWndCache[strSpellWindowCacheKey]
		local wndSpellBtn = nil
		if tSpellBtn ~= nil then
			wndSpellBtn = tSpellBtn.wndSpellBtn
		end
		if wndSpellBtn == nil or not wndSpellBtn:IsValid() then
			wndSpellBtn = Apollo.LoadForm(self.xmlDoc, "SpellItemObjectiveBtn", wndQuest:FindChild("QuestObjectiveBtn"), self)
			self.tObjectiveWndCache[strSpellWindowCacheKey] = { wndSpellBtn = wndSpellBtn, nIndex = nIndex, queQuest = queQuest, epiEpisode = epiEpisode }
		end
		
		wndSpellBtn:SetContentId(queQuest, tObjective.nIndex)
		wndSpellBtn:SetText(String_GetWeaselString(GameLib.GetKeyBinding("CastObjectiveAbility")))
	end
end

function QuestTracker:ResizeObjective(wndObj)
	local nObjTextHeight = self.knInitialQuestObjectiveHeight

	-- If there's the spell icon is bigger, use that instead
	if wndObj:FindChild("SpellItemObjectiveBtn") or wndObj:GetName() == "SpellItem" then
		nObjTextHeight = math.max(nObjTextHeight, self.knInitialSpellItemHeight)
	end

	-- If the text is bigger, use that instead
	local wndQuestObjectiveText = wndObj:FindChild("QuestObjectiveText")
	if wndQuestObjectiveText then
		local nLocalWidth, nLocalHeight = wndQuestObjectiveText:SetHeightToContentHeight()
		nObjTextHeight = math.max(nObjTextHeight, nLocalHeight + 2) -- for lower g height

		-- Fake V-Align to match the button if it's just one line of text
		if wndObj:FindChild("SpellItemObjectiveBtn") and nLocalHeight < 20 then
			local nLeft, nTop, nRight, nBottom = wndQuestObjectiveText:GetAnchorOffsets()
			wndQuestObjectiveText:SetAnchorOffsets(nLeft, 9, nRight, nBottom)
		end
	end

	-- Also add extra height for Progress Bars
	if wndObj:FindChild("QuestProgressItem") then
		nObjTextHeight = nObjTextHeight + wndObj:FindChild("QuestProgressItem"):GetHeight()
	end

	local nLeft, nTop, nRight, nBottom = wndObj:GetAnchorOffsets()
	wndObj:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nObjTextHeight)
end

function QuestTracker:BuildObjectiveTitleString(queQuest, tObjective, bIsTooltip)
	local strResult = ""

	-- Early exit for completed
	if queQuest:GetState() == Quest.QuestState_Achieved then
		strResult = queQuest:GetCompletionObjectiveShortText()
		if bIsTooltip or self.bShowLongQuestText or not strResult or Apollo.StringLength(strResult) <= 0 then
			strResult = queQuest:GetCompletionObjectiveText()
		end
		return string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", strResult)
	end

	-- Use short form or reward text if possible
	local strShortText = queQuest:GetObjectiveShortDescription(tObjective.nIndex)
	if self.bShowLongQuestText or bIsTooltip then
		strResult = string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", tObjective.strDescription)
	elseif strShortText and Apollo.StringLength(strShortText) > 0 then
		strResult = string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", strShortText)
	end
	
	-- Prefix Optional or Progress if it hasn't been finished yet
	if tObjective.nCompleted < tObjective.nNeeded then
		local strPrefix = ""
		if tObjective and not tObjective.bIsRequired then
			strPrefix = string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", Apollo.GetString("QuestLog_Optional"))
			strResult = String_GetWeaselString(Apollo.GetString("QuestTracker_BuildText"), strPrefix, strResult)
		end

		-- Use Percent if Progress Bar
		if tObjective.nNeeded > 1 and queQuest:DisplayObjectiveProgressBar(tObjective.nIndex) then
			local strColor = self.tActiveProgBarQuests[queQuest:GetId()] and kstrHighlight or "ffffffff"
			local strPercentComplete = String_GetWeaselString(Apollo.GetString("QuestTracker_PercentComplete"), tObjective.nCompleted)
			strPrefix = string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strColor, strPercentComplete)
			strResult = String_GetWeaselString(Apollo.GetString("QuestTracker_BuildText"), strPrefix, strResult)
		elseif tObjective.nNeeded > 1 then
			strPrefix = string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", String_GetWeaselString(Apollo.GetString("QuestTracker_ValueComplete"), Apollo.FormatNumber(tObjective.nCompleted, 0, true), Apollo.FormatNumber(tObjective.nNeeded, 0, true)))
			strResult = String_GetWeaselString(Apollo.GetString("QuestTracker_BuildText"), strPrefix, strResult)
		end
	end

	-- Prefix time for timed objectives
	if queQuest:IsObjectiveTimed(tObjective.nIndex) then
		strResult = self:HelperPrefixTimeString(math.max(0, math.floor(queQuest:GetObjectiveTimeRemaining(tObjective.nIndex) / 1000)), strResult)
	end
	
	return strResult
end

function QuestTracker:UpdateTutorialZoneState()
	local tZone = GameLib.GetCurrentZoneMap()
	local nZoneId = 0
	if tZone ~= nil then
		nZoneId = tZone.id
	end
	self.bIsTutorialZone = GameLib.IsTutorialZone(nZoneId)
end

---------------------------------------------------------------------------------------------------
-- Game Events
---------------------------------------------------------------------------------------------------

function QuestTracker:OnEpisodeStateChanged(idEpisode, eOldState, eNewState)
	local epiEpisode = QuestLib.GetEpisode(idEpisode)
	if epiEpisode == nil or not self.bQuestsInitialized then
		return
	end

	if eNewState == Episode.EpisodeState_Active then
		if epiEpisode:IsWorldStory() then
			self:DrawEpisode(kstrWorldStoryQuestMarker, epiEpisode)
		elseif epiEpisode:IsZoneStory() then
			self:DrawEpisode(kstrZoneStoryQuestMarker, epiEpisode)
		elseif epiEpisode:IsRegionalStory() then
			self:DrawEpisode(kstrRegionalStoryQuestMarker, epiEpisode)
		end
	else
		self:DestroyEpisode(epiEpisode)
	end
	
	self.timerResizeDelay:Start()
end

function QuestTracker:OnQuestInit()
	if self.wndMain == nil or not self.wndMain:IsValid() then
		return
	end
	
	self.bQuestsInitialized = true
	
	self:BuildAll()
	self:ResizeAll()
end

function QuestTracker:OnQuestStateChanged(queQuest, eState)
	if eState == Quest.QuestState_Accepted
		or eState == Quest.QuestState_Achieved
		or eState == Quest.QuestState_Botched then
		
		self:DrawQuest(queQuest)
		
		
		local strUpdateAniamtion
		if eState == Quest.QuestState_Accepted then
			--Add new quests to saved hint arrow.
			GameLib.SetInteractHintArrowObject(queQuest)
			
			strUpdateAniamtion = "spr_ObjectiveTracker_UpdateAnimBlue"
		elseif eState == Quest.QuestState_Achieved then
			strUpdateAniamtion = "spr_ObjectiveTracker_UpdateAnimGreen"
		elseif eState == Quest.QuestState_Botched then
			strUpdateAniamtion = "spr_ObjectiveTracker_UpdateAnimRed"
		end
		
		if strUpdateAniamtion ~= nil then
			local tQuest = self.tQuestWndCache[queQuest:GetId()]
			if tQuest ~= nil and tQuest.wndQuest ~= nil then
				tQuest.wndQuest:SetSprite(strUpdateAniamtion)
			end
		end
		
	else
		self:DestroyQuest(queQuest)
		
		--Remove completed quests from saved hint arrow.
		local oInteractObject = GameLib.GetInteractHintArrowObject()
		if not oInteractObject or (oInteractObject and oInteractObject.eHintArrowType == GameLib.CodeEnumHintType.Quest and oInteractObject.objTarget:GetId() == queQuest:GetId()) then
			GameLib.SetInteractHintArrowObject(nil)
		end
	end
	
	self.timerResizeDelay:Start()
end

function QuestTracker:OnQuestTrackedChanged(queQuest, bTracked)
	if bTracked then
		self:DrawQuest(queQuest)
	else
		self:DestroyQuest(queQuest)
	end
	
	self.timerResizeDelay:Start()
end

function QuestTracker:OnQuestObjectiveUpdated(queQuest, nIndex)
	local eState = queQuest:GetState()
	if eState == Quest.QuestState_Completed
		or eState == Quest.QuestState_Abandoned
		or eState == Quest.QuestState_Unknown
		or eState == Quest.QuestState_Mentioned then
		
		self:DestroyQuest(queQuest)
	else
		self:DrawQuest(queQuest)
		
		if eState == Quest.QuestState_Accepted then
			local tQuest = self.tQuestWndCache[queQuest:GetId()]
			if tQuest ~= nil and tQuest.wndQuest ~= nil then
				tQuest.wndQuest:SetSprite("spr_ObjectiveTracker_UpdateAnimBlue")
			end
		end
	end
	
	self.timerResizeDelay:Start()
end

function QuestTracker:OnShowCommMsg(idMsg, idCaller, queUpdated, strText)
	local tCommInfo = self.tQueuedCommMessages[queUpdated:GetId()]
	if tCommInfo ~= nil then
		self:HelperShowQuestCallbackBtn(tCommInfo.wndQuest, tCommInfo.queQuest, tCommInfo.strNumberBackerArt, tCommInfo.strCallbackBtnArt)
	end
end

function QuestTracker:UpdateGroup()
	local bInRaid = GroupLib.InRaid()
	if bInRaid and self.wndRaidWarning == nil then
		self.wndRaidWarning = Apollo.LoadForm(self.xmlDoc, "QuestTrackerRaidWarning", self.wndMain, self)
		self.wndRaidWarning:SetData(knRaidWarningSection)
		
		self.timerResizeDelay:Start()
	elseif not bInRaid and self.wndRaidWarning and self.wndRaidWarning:IsValid() then
		self.wndRaidWarning:Destroy()
		self.wndRaidWarning = nil
		
		self.timerResizeDelay:Start()
	end
end

function QuestTracker:OnSubZoneChanged()
	self.timerResizeDelay:Start()
	
	self:UpdateTutorialZoneState()
end

function QuestTracker:OnChangeWorld()
	self.timerResizeDelay:Start()
end

function QuestTracker:OnKeyBindingKeyChanged(strKeyBindingName)
	self:ResizeContentFinderNotification()
end

function QuestTracker:OnShowResurrectDialog()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer then
		self.bPlayerIsDead = unitPlayer:IsDead()
	end
	
	for idx, tQuest in pairs(self.tQuestWndCache) do
		local wndQuest = tQuest.wndQuest
		if wndQuest ~= nil and wndQuest:IsValid() then
			local wndQuestCallbackBtn = wndQuest:FindChild("QuestCallbackBtn")
			if wndQuestCallbackBtn ~= nil and wndQuestCallbackBtn:IsValid() then
				wndQuestCallbackBtn:Enable(not self.bPlayerIsDead)
			end
		end
	end
end

function QuestTracker:OnPlayerResurrected()
	self.bPlayerIsDead = false
	
	for idx, tQuest in pairs(self.tQuestWndCache) do
		local wndQuest = tQuest.wndQuest
		if wndQuest ~= nil and wndQuest:IsValid() then
			local wndQuestCallbackBtn = wndQuest:FindChild("QuestCallbackBtn")
			if wndQuestCallbackBtn ~= nil and wndQuestCallbackBtn:IsValid() then
				wndQuestCallbackBtn:Enable(not self.bPlayerIsDead)
			end
		end
	end
end

function QuestTracker:OnGenericEvent_QuestLog_TrackBtnClicked(queSelected)
	local nQuestId = queSelected:GetId()
	if queSelected:IsImbuementQuest() then
		if self.tHiddenImbu[nQuestId] ~= nil and queSelected:IsTracked() then
			self.tHiddenImbu[nQuestId] = nil
			self:DrawQuest(queSelected)
		else
			self.tHiddenImbu[nQuestId] = true
			self:DestroyQuest(queSelected)
		end
		
		self.timerResizeDelay:Start()
	end
end

function QuestTracker:OnToggleLongQuestText()
	self:BuildAll()
	self.timerResizeDelay:Start()
end

function QuestTracker:OnPlayerLevelChange()
	self:BuildAll()
	self.timerResizeDelay:Start()
end

function QuestTracker:OnOptionsUpdated()
	if g_InterfaceOptions and g_InterfaceOptions.Carbine.bQuestTrackerByDistance ~= nil then
		self.bQuestTrackerByDistance = g_InterfaceOptions.Carbine.bQuestTrackerByDistance
	else
		self.bQuestTrackerByDistance = true
	end

	self.timerRealTimeUpdate:Start()
	self.timerResizeDelay:Start()
end

---------------------------------------------------------------------------------------------------
-- Controls Events
---------------------------------------------------------------------------------------------------

function QuestTracker:OnQuestNumberBackerMouseEnter(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:FindChild("QuestNumberBackerGlow"):Show(true)
	end
end

function QuestTracker:OnQuestNumberBackerMouseExit(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:FindChild("QuestNumberBackerGlow"):Show(false)
	end
end

function QuestTracker:OnControlBackerMouseEnter(wndHandler, wndControl)
	if wndHandler == wndControl and wndHandler:FindChild("QuestGearBtn") then
		wndHandler:FindChild("QuestGearBtn"):Show(true)
	end
end

function QuestTracker:OnControlBackerMouseExit(wndHandler, wndControl)
	if wndHandler == wndControl and wndHandler:FindChild("QuestGearBtn") then
		wndHandler:FindChild("QuestGearBtn"):Show(false)
	end
end

function QuestTracker:OnEpisodeControlBackerMouseEnter(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:FindChild("EpisodeMinimizeBtn"):Show(true)
	end
end

function QuestTracker:OnEpisodeControlBackerMouseExit(wndHandler, wndControl)
	if wndHandler == wndControl then
		local wndBtn = wndHandler:FindChild("EpisodeMinimizeBtn")
		wndBtn:Show(wndBtn:IsChecked())
	end
end

function QuestTracker:OnEpisodeGroupControlBackerMouseEnter(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:FindChild("EpisodeGroupMinimizeBtn"):Show(true)
	end
end

function QuestTracker:OnEpisodeGroupControlBackerMouseExit(wndHandler, wndControl)
	if wndHandler == wndControl then
		local wndBtn = wndHandler:FindChild("EpisodeGroupMinimizeBtn")
		wndBtn:Show(wndBtn:IsChecked())
	end
end

function QuestTracker:OnEpisodeMinimizedBtnChecked(wndHandler, wndControl, eMouseButton)
	self.tMinimized.tEpisode[wndHandler:GetData()] = true
	self:ResizeAll()
end

function QuestTracker:OnEpisodeMinimizedBtnUnChecked(wndHandler, wndControl, eMouseButton)
	self.tMinimized.tEpisode[wndHandler:GetData()] = nil
	self:ResizeAll()
end

function QuestTracker:OnEpisodeGroupMinimizedBtnChecked(wndHandler, wndControl, eMouseButton)
	self.tMinimized.tEpisodeGroup[wndHandler:GetData()] = true
	self:ResizeAll()
end

function QuestTracker:OnEpisodeGroupMinimizedBtnUnChecked(wndHandler, wndControl, eMouseButton)
	self.tMinimized.tEpisodeGroup[wndHandler:GetData()] = nil
	self:ResizeAll()
end

function QuestTracker:OnContentGroupMinimizedBtnChecked(wndHandler, wndControl, eMouseButton)
	self.tMinimized.bRoot = true
	self:ResizeAll()
end

function QuestTracker:OnContentGroupMinimizedBtnUnChecked(wndHandler, wndControl, eMouseButton)
	self.tMinimized.bRoot = false
	self:ResizeAll()
end

function QuestTracker:OnQuestHintArrow(wndHandler, wndControl, eMouseButton)
	local tQuest = wndHandler:GetData()
	local wndQuest = tQuest.wndQuest
	local queCur = tQuest.queQuest
	
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and Apollo.IsShiftKeyDown() then
		Event_FireGenericEvent("GenericEvent_QuestLink", queCur)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Right or (wndQuest:FindChild("QuestGearBtn") and wndQuest:FindChild("QuestGearBtn"):ContainsMouse()) then
		self:ShowQuestRightClick(queCur)
	else
		queCur:ShowHintArrow()
		GameLib.SetInteractHintArrowObject(queCur) 
		if self.tClickBlinkingQuest then
			self.timerArrowBlinker:Stop()
			self.tClickBlinkingQuest:SetActiveQuest(false)
		elseif self.tHoverBlinkingQuest then
			self.tHoverBlinkingQuest:SetActiveQuest(false)
		end

		if Quest.is(wndQuest:GetData()) then
			self.tClickBlinkingQuest = queCur
			self.tClickBlinkingQuest:ToggleActiveQuest()
			self.timerArrowBlinker:Start()
		end
	end
end

function QuestTracker:OnQuestObjectiveHintArrow(wndHandler, wndControl, eMouseButton) -- "QuestObjectiveBtn" (can be from EventItem), data is { tQuest, tObjective.index }
	local tData = wndHandler:GetData()
	if tData and tData.queOwner then
		tData.queOwner:ShowHintArrow(tData.nObjectiveIdx)
		GameLib.SetInteractHintArrowObject(tData.queOwner, tData.nObjectiveIdx)
		if self.tClickBlinkingQuest then
			self.timerArrowBlinker:Stop()
			self.tClickBlinkingQuest:SetActiveQuest(false)
		elseif self.tHoverBlinkingQuest then
			self.tHoverBlinkingQuest:SetActiveQuest(false)
		end

		if Quest.is(tData.queOwner) then
			self.tClickBlinkingQuest = tData.queOwner
			self.tClickBlinkingQuest:ToggleActiveQuest()
			self.timerArrowBlinker:Start()
		end
	end

	return true -- Stop Propagation so the Quest Hint Arrow won't eat this call
end

function QuestTracker:OnArrowBlinkerTimer()
	if self.tClickBlinkingQuest ~= nil then
		self.tClickBlinkingQuest:SetActiveQuest(false)
		self.tClickBlinkingQuest = nil
	end

	if self.tHoverBlinkingQuest then
		self.tHoverBlinkingQuest:ToggleActiveQuest()
	end
end

function QuestTracker:OnQuestGearBtn(wndHandler, wndControl)
	self:ShowQuestRightClick(wndHandler:GetData())
end

function QuestTracker:ShowQuestRightClick(queQuest)
	self:OnQuestTrackerRightClickClose()

	self.wndQuestRightClick = Apollo.LoadForm(self.xmlDoc, "QuestTrackerRightClick", nil, self)
	self.wndQuestRightClick:FindChild("RightClickOpenLogBtn"):SetData(queQuest)
	self.wndQuestRightClick:FindChild("RightClickShareQuestBtn"):SetData(queQuest)
	self.wndQuestRightClick:FindChild("RightClickLinkToChatBtn"):SetData(queQuest)
	self.wndQuestRightClick:FindChild("RightClickMaxMinBtn"):SetData(queQuest)
	self.wndQuestRightClick:FindChild("RightClickPinUnpinBtn"):SetData(queQuest)
	self.wndQuestRightClick:FindChild("RightClickHideBtn"):SetData(queQuest)
	self.wndQuestRightClick:FindChild("RightClickAbandonConfirmBtn"):SetData(queQuest)
	self.wndQuestRightClick:FindChild("RightClickShareQuestBtn"):Enable(queQuest:CanShare())
	self.wndQuestRightClick:FindChild("RightClickAbandonBtn"):Enable(queQuest:CanAbandon())
	self.wndQuestRightClick:FindChild("RightClickOpenLogBtn"):Enable(not queQuest:ShouldHideFromQuestLog())

	local nQuestId = queQuest:GetId()
	local bAlreadyMinimized = nQuestId and self.tMinimized.tQuests[nQuestId]
	self.wndQuestRightClick:FindChild("RightClickMaxMinBtn"):SetText(bAlreadyMinimized and Apollo.GetString("QuestTracker_Expand") or Apollo.GetString("QuestTracker_Minimize"))
	self.wndQuestRightClick:FindChild("RightClickMaxMinBtn"):Enable(queQuest and queQuest:GetState() ~= Quest.QuestState_Botched)

	local bAlreadyPinned = nQuestId and self.tPinned.tQuests[nQuestId]
	self.wndQuestRightClick:FindChild("RightClickPinUnpinBtn"):SetText(bAlreadyPinned and Apollo.GetString("QuestTracker_Unpin") or Apollo.GetString("QuestTracker_Pin"))

	local tCursor = Apollo.GetMouse()
	local nWidth = self.wndQuestRightClick:GetWidth()
	self.wndQuestRightClick:Move(tCursor.x - nWidth + knXCursorOffset, tCursor.y - knYCursorOffset, nWidth, self.wndQuestRightClick:GetHeight())
end

function QuestTracker:OnQuestTrackerRightClickClose()
	if self.wndQuestRightClick ~= nil and self.wndQuestRightClick:IsValid() then
		self.wndQuestRightClick:Destroy()
		self.wndQuestRightClick = nil
	end
end

function QuestTracker:OnRightClickOpenLogBtn(wndHandler, wndControl, eMouseButton)
	Event_FireGenericEvent("ShowQuestLog", wndHandler:GetData())
	Event_FireGenericEvent("GenericEvent_ShowQuestLog", wndHandler:GetData())
	self:OnQuestTrackerRightClickClose()
end

function QuestTracker:OnRightClickShareQuestBtn(wndHandler, wndControl)
	wndHandler:GetData():Share()
	self:OnQuestTrackerRightClickClose()
end

function QuestTracker:OnRightClickLinkToChatBtn(wndHandler, wndControl)
	Event_FireGenericEvent("GenericEvent_QuestLink", wndHandler:GetData())
	self:OnQuestTrackerRightClickClose()
end

function QuestTracker:OnRightClickMaxMinBtn(wndHandler, wndControl)
	local queQuest = wndHandler:GetData()
	if self.tMinimized.tQuests[queQuest:GetId()] then
		self.tMinimized.tQuests[queQuest:GetId()] = nil
	else
		self.tMinimized.tQuests[queQuest:GetId()] = true
	end
	self.timerResizeDelay:Start()
	self:OnQuestTrackerRightClickClose()
end

function QuestTracker:OnRightClickPinUnpinBtn(wndHandler, wndControl)
	local queQuest = wndHandler:GetData()
	if self.tPinned.tQuests[queQuest:GetId()] then
		self.tPinned.tQuests[queQuest:GetId()] = nil
	else
		self.tPinned.tQuests[queQuest:GetId()] = true
	end

	self:DestroyQuest(queQuest)
	self:DrawQuest(queQuest)
	
	self.timerResizeDelay:Start()
	self:OnQuestTrackerRightClickClose()
end

function QuestTracker:OnRightClickHideBtn(wndHandler, wndControl)
	local queQuest = wndHandler:GetData()
	queQuest:SetActiveQuest(false)

	if queQuest:GetState() == Quest.QuestState_Botched then
		queQuest:Abandon()
	else
		queQuest:ToggleTracked()
		if queQuest:IsImbuementQuest() then
			self.tHiddenImbu[queQuest:GetId()] = true
		end
	end

	self:DestroyQuest(queQuest)
	
	self.timerResizeDelay:Start()
	self:OnQuestTrackerRightClickClose()
end

function QuestTracker:OnQuestAbandonPopoutOpen(wndHandler, wndControl)
	self.wndQuestRightClick:FindChild("AbandonConfirmWindow"):Show(true)
end

function QuestTracker:OnQuestAbandonPopoutClose(wndHandler, wndControl) -- QuestAbandonPopoutClose
	self.wndQuestRightClick:FindChild("AbandonConfirmWindow"):Show(false)
	self:OnQuestTrackerRightClickClose()	
end

function QuestTracker:OnRightClickAbandonBtn(wndHandler, wndControl)
	local queQuest = wndControl:GetData()

	if queQuest:CanAbandon() then
		queQuest:Abandon()
		self:DestroyQuest(queQuest)		
	end
	
	self:OnQuestTrackerRightClickClose()
end

function QuestTracker:OnQuestCallbackBtn(wndHandler, wndControl)
	CommunicatorLib.CallContact(wndHandler:GetData())
end

function QuestTracker:OnQuestOpenMapBtn(wndHandler, wndControl) -- wndHandler should be "QuestOpenMapBtn" and its data is tQuest
	Event_FireGenericEvent("ZoneMap_OpenMapToQuest", wndHandler:GetData())
	self:OnQuestTrackerRightClickClose()
end

function QuestTracker:OnGenerateTooltip(wndControl, wndHandler, eType, arg1, arg2)
	local xml = nil
	if eType == Tooltip.TooltipGenerateType_ItemInstance then -- Doesn't need to compare to item equipped
		if Tooltip ~= nil and Tooltip.GetItemTooltipForm~= nil then
			Tooltip.GetItemTooltipForm(self, wndControl, arg1, {})
		end
	elseif eType == Tooltip.TooltipGenerateType_ItemData then -- Doesn't need to compare to item equipped
		if Tooltip ~= nil and Tooltip.GetItemTooltipForm~= nil then
			Tooltip.GetItemTooltipForm(self, wndControl, arg1, {})
		end
	elseif eType == Tooltip.TooltipGenerateType_GameCommand then
		xml = XmlDoc.new()
		xml:AddLine(arg2)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Macro then
		xml = XmlDoc.new()
		xml:AddLine(arg1)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Spell then
		if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
			Tooltip.GetSpellTooltipForm(self, wndControl, arg1)
		end
	elseif eType == Tooltip.TooltipGenerateType_PetCommand then
		xml = XmlDoc.new()
		xml:AddLine(arg2)
		wndControl:SetTooltipDoc(xml)
	end
end

-----------------------------------------------------------------------------------------------
-- Right Click
-----------------------------------------------------------------------------------------------
function QuestTracker:CloseContextMenu() -- From a variety of source
	if self.wndContextMenu and self.wndContextMenu:IsValid() then
		self.wndContextMenu:Destroy()
		self.wndContextMenu = nil
		
		return true
	end
	
	return false
end

function QuestTracker:DrawContextMenu()
	local nXCursorOffset = -36
	local nYCursorOffset = 5

	if self:CloseContextMenu() then
		return
	end

	self.wndContextMenu = Apollo.LoadForm(self.xmlDoc, "ContextMenu", nil, self)
	self.wndContextMenu:FindChild("MissionDistanceEditBox"):SetText(self.nMaxMissionDistance)
	
	self:HelperDrawContextMenuSubOptions()
	
	local nWidth = self.wndContextMenu:GetWidth()
	local nHeight = self.wndContextMenu:GetHeight()
		
	local tCursor = Apollo.GetMouse()
	self.wndContextMenu:Move(
		tCursor.x - nWidth - nXCursorOffset,
		tCursor.y - nHeight - nYCursorOffset,
		nWidth,
		nHeight
	)
end

function QuestTracker:HelperDrawContextMenuSubOptions(wndIgnore)
	if self.wndContextMenu and self.wndContextMenu:IsValid() then
		self.wndContextMenu:FindChild("ToggleOnQuests"):SetCheck(self.bShowQuests)
		self.wndContextMenu:FindChild("QuestArrowUnlocked"):SetCheck(Apollo.GetConsoleVariable("ui.showHintArrowOnUnlock"))
		self.wndContextMenu:FindChild("QuestArrowComplete"):SetCheck(Apollo.GetConsoleVariable("ui.showHintArrowOnComplete"))
		self.wndContextMenu:FindChild("QuestArrowObjectiveUpdate"):SetCheck(Apollo.GetConsoleVariable("ui.showHintArrowOnObjectiveUpdate"))

		local wndToggleFilterDistance = self.wndContextMenu:FindChild("ToggleFilterDistance")
		wndToggleFilterDistance:SetCheck(self.bFilterDistance)
		
		if not wndIgnore or wndIgnore and wndIgnore ~= wndMissionDistanceEditBox then
			self.wndContextMenu:FindChild("MissionDistanceEditBox"):SetText(self.bFilterDistance and self.nMaxMissionDistance or 0)
		end
	end
end

function QuestTracker:OnToggleUnlockArrow(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	Apollo.SetConsoleVariable("ui.showHintArrowOnUnlock", wndControl:IsChecked())
end

function QuestTracker:OnToggleUpdateArrow(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	Apollo.SetConsoleVariable("ui.showHintArrowOnObjectiveUpdate", wndControl:IsChecked())
end

function QuestTracker:OnToggleCompleteArrow(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	Apollo.SetConsoleVariable("ui.showHintArrowOnComplete", wndControl:IsChecked())
end

function QuestTracker:OnToggleFilterDistance()
	self.bFilterDistance = not self.bFilterDistance
	
	self:HelperDrawContextMenuSubOptions()
	
	if self.bFilterDistance then
		self.timerRealTimeUpdate:Start()
	end
	self:ResizeAll()
end

function QuestTracker:OnMissionDistanceEditBoxChanged(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	
	self.nMaxMissionDistance = tonumber(wndControl:GetText()) or 0
	if self.nMaxMissionDistance > 0 then
		self.timerRealTimeUpdate:Start()
	end
end

---------------------------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------------------------
function QuestTracker:HelperSelectInteractHintArrowObject(oCur, wndBtn)
	local oInteractObject = GameLib.GetInteractHintArrowObject()
	if not oInteractObject or (oInteractObject and oInteractObject.eHintArrowType == GameLib.CodeEnumHintType.None) then
		return
	end

	local bIsInteractHintArrowObject = oInteractObject.objTarget and oInteractObject.objTarget == oCur
	if bIsInteractHintArrowObject and not wndBtn:IsChecked() then
		wndBtn:SetCheck(true)
	end
end

function QuestTracker:HelperShowQuestCallbackBtn(wndQuest, queQuest, strNumberBackerArt, strCallbackBtnArt)
	wndQuest:FindChild("QuestNumberBackerArt"):SetSprite(strNumberBackerArt)

	local tContactInfo = queQuest:GetContactInfo()

	if not queQuest:IsCommunicatorReceived() or queQuest:IsCommunicatorReceivedFromRec() then
		if not tContactInfo then
			self.tQueuedCommMessages[queQuest:GetId()] = {wndQuest = wndQuest, queQuest = queQuest, strNumberBackerArt = strNumberBackerArt, strCallbackBtnArt = strCallbackBtnArt}
			return
		else
			self.tQueuedCommMessages[queQuest:GetId()] = nil
		end
	end

	if not tContactInfo or not tContactInfo.strName or Apollo.StringLength(tContactInfo.strName) <= 0 then
		return
	end

	local strName = String_GetWeaselString(Apollo.GetString("QuestTracker_ContactName"), tContactInfo.strName)
	wndQuest:FindChild("QuestCompletedBacker"):Show(true)
	wndQuest:FindChild("QuestCallbackBtn"):ChangeArt(strCallbackBtnArt)
	wndQuest:FindChild("QuestCallbackBtn"):Enable(not self.bPlayerIsDead)
	wndQuest:FindChild("QuestCallbackBtn"):SetTooltip(string.format("<P Font=\"CRB_InterfaceMedium\">%s</P>", strName))
end

function QuestTracker:HelperBuildTimedQuestTitle(queQuest)
	local strTitle = queQuest:GetTitle()
	strTitle = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</T>", kstrLightGrey, strTitle)
	strTitle = self:HelperPrefixTimeString(math.max(0, math.floor(queQuest:GetQuestTimeRemaining() / 1000)), strTitle)
	return strTitle
end

function QuestTracker:HelperPrefixTimeString(fTime, strAppend, strColorOverride)
	local fSeconds = fTime % 60
	local fMinutes = fTime / 60
	local strColor = kstrYellow
	if strColorOverride then
		strColor = strColorOverride
	elseif fMinutes < 1 and fSeconds <= 30 then
		strColor = kstrRed
	end
	local strPrefix = string.format("<T Font=\"CRB_InterfaceMedium_B\" TextColor=\"%s\">(%d:%.02d) </T>", strColor, fMinutes, fSeconds)
	return String_GetWeaselString(Apollo.GetString("QuestTracker_BuildText"), strPrefix, strAppend)
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------
function QuestTracker:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors = 
	{
		[GameLib.CodeEnumTutorialAnchor.QuestTracker] 	= true,
	}
	
	if not tAnchors[eAnchor] then
		return
	end
	
	local tAnchorMapping = 
	{
		[GameLib.CodeEnumTutorialAnchor.QuestTracker] = self.wndMain,
	}
	
	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end


local QuestTrackerInst = QuestTracker:new()
QuestTrackerInst:Init()
