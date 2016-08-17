-----------------------------------------------------------------------------------------------
-- Client Lua Script for QuestTracker
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "ApolloTimer"
require "GameLib"
require "QuestLib"

local PublicEventTracker 					= {}

local knMaxZombieEventCount = 7
local kstrPublicEventContainer = "001EventContainer"

local knXCursorOffset = 10
local knYCursorOffset = 25

local ktNumbersToLetters =
{
	Apollo.GetString("QuestTracker_ObjectiveA"),
	Apollo.GetString("QuestTracker_ObjectiveB"),
	Apollo.GetString("QuestTracker_ObjectiveC"),
	Apollo.GetString("QuestTracker_ObjectiveD"),
	Apollo.GetString("QuestTracker_ObjectiveE"),
	Apollo.GetString("QuestTracker_ObjectiveF"),
	Apollo.GetString("QuestTracker_ObjectiveG"),
	Apollo.GetString("QuestTracker_ObjectiveH"),
	Apollo.GetString("QuestTracker_ObjectiveI"),
	Apollo.GetString("QuestTracker_ObjectiveJ"),
	Apollo.GetString("QuestTracker_ObjectiveK"),
	Apollo.GetString("QuestTracker_ObjectiveL")
}
local knNumberToLettersMax = #ktNumbersToLetters

local karPathToString =
{
	[PlayerPathLib.PlayerPathType_Soldier] 		= Apollo.GetString("CRB_Soldier"),
	[PlayerPathLib.PlayerPathType_Settler] 		= Apollo.GetString("CRB_Settler"),
	[PlayerPathLib.PlayerPathType_Scientist] 	= Apollo.GetString("CRB_Scientist"),
	[PlayerPathLib.PlayerPathType_Explorer] 	= Apollo.GetString("CRB_Explorer")
}

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

local ktPvPEventTypes =
{
	[PublicEvent.PublicEventType_PVP_Arena] 					= true,
	[PublicEvent.PublicEventType_PVP_Warplot] 					= true,
	[PublicEvent.PublicEventType_PVP_Battleground_Cannon] 		= true,
	[PublicEvent.PublicEventType_PVP_Battleground_Vortex] 		= true,
	[PublicEvent.PublicEventType_PVP_Battleground_Sabotage] 	= true,
	[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine] 	= true,
}

local knDynamicBossMaxPoints = 20

local kstrRed 		= "ffff4c4c"
local kstrGreen 	= "ff2fdc02"
local kstrYellow 	= "fffffc00"
local kstrLightGrey = "ffb4b4b4"
local kstrHighlight = "ffffe153"
local kstrDungeonGoldIcon = "<T Image=\"sprQT_GoldIcon\"></T><T TextColor=\"0\">.</T>"
local kstrDungeonBronzeIcon = "<T Image=\"sprQT_BronzeIcon\"></T><T TextColor=\"0\">.</T>"

function PublicEventTracker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	
	-- Window Management
	o.tEventWndCache = {}
	o.tObjectiveWndCache = {}
	o.tZombieEventWndCache = {}
	
	-- Data
	o.nEventCount = -1 -- Start at -1 so that loading up with 0 public events will still trigger a resize
	o.strPlayerPath = ""
	o.tZombiePublicEvents = {}
	o.tTimedEvents = {}
	o.tTimedEventObjectives = {}
	
	-- Saved Data
	o.bShowEvents = true
	o.tMinimized =
	{
		bRoot = false,
		tEvent = {},
	}
	
    return o
end

function PublicEventTracker:Init()
    Apollo.RegisterAddon(self)
end

function PublicEventTracker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("PublicEventTracker.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	self.timerResizeDelay = ApolloTimer.Create(0.1, false, "OnResizeDelayTimer", self)
	self.timerResizeDelay:Stop()
	
	self.timerRealTimeUpdate = ApolloTimer.Create(1.0, true, "OnRealTimeUpdateTimer", self)
	self.timerRealTimeUpdate:Stop()
end

function PublicEventTracker:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	return
	{
		bShowEvents = self.bShowEvents,
		tMinimized = self.tMinimized,
	}
end

function PublicEventTracker:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	
	if tSavedData.bShowEvents ~= nil then
		self.bShowEvents = tSavedData.bShowEvents
	end
	
	if tSavedData.tMinimized ~= nil then
		self.tMinimized = tSavedData.tMinimized
	end
end

function PublicEventTracker:OnDocumentReady()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
		Apollo.AddAddonErrorText(self, "Could not load the main window document for some reason.")
		return
	end
	
	Apollo.RegisterEventHandler("ObjectiveTrackerLoaded", "OnObjectiveTrackerLoaded", self)

	self:InitializeWindowMeasuring()
	
	Event_FireGenericEvent("ObjectiveTracker_RequestParent")
end

function PublicEventTracker:InitializeWindowMeasuring()
	local wndMeasure

	wndMeasure = Apollo.LoadForm(self.xmlDoc, "ContentGroupItem", nil, self)
	self.knInitialGroupHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()
	
	wndMeasure = Apollo.LoadForm(self.xmlDoc, "EventItem", nil, self)
	self.knMinHeightEventItem = wndMeasure:GetHeight()
	self.kcrEventLetter = wndMeasure:FindChild("EventLetter"):GetTextColor()
	self.kcrEventLetterBacker = wndMeasure:FindChild("EventLetterBacker"):GetBGColor()
	wndMeasure:Destroy()
	
	wndMeasure = Apollo.LoadForm(self.xmlDoc, "EventObjectiveItem", nil, self)
	self.knInitialEventObjectiveHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()

	wndMeasure = Apollo.LoadForm(self.xmlDoc, "DynamicBosses", nil, self)
	self.knInitialDynamicBossHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()

	if self.strPlayerPath == "" then
		local ePlayPathType = PlayerPathLib.GetPlayerPathType()
		if ePlayPathType then
			self.strPlayerPath = karPathToString[ePlayerPathType]
		end
	end
end

function PublicEventTracker:OnObjectiveTrackerLoaded(wndForm)
	if not wndForm or not wndForm:IsValid() then
		return
	end
	
	Apollo.RemoveEventHandler("ObjectiveTrackerLoaded", self)
	
	Apollo.RegisterEventHandler("ToggleShowPublicEvents", "OnToggleShowEvents", self)
	
	Apollo.RegisterEventHandler("PublicEventStart", "OnPublicEventStart", self)
	Apollo.RegisterEventHandler("PublicEventEnd", "OnPublicEventEnd", self)
	Apollo.RegisterEventHandler("PublicEventLeave", "OnPublicEventEnd", self)
	Apollo.RegisterEventHandler("PublicEventUpdate", "OnPublicEventUpdate", self)
	Apollo.RegisterEventHandler("AddSpellShortcut", "OnAddSpellShortcut", self)
	Apollo.RegisterEventHandler("PublicEventLiveStatsUpdate", "OnPublicEventUpdate", self)
	Apollo.RegisterEventHandler("PublicEventObjectiveUpdate", "OnPublicEventObjectiveUpdate", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", "OnTutorial_RequestUIAnchor", self)
	
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "ContentGroupItem", wndForm, self)
	self.wndEventContainer = self.wndMain
	self.wndEventContainerContent = self.wndEventContainer:FindChild("GroupContainer")
	
	local tData =
	{
		["strAddon"] = Apollo.GetString("PublicEventTracker_PublicEvents"),
		["strEventMouseLeft"] = "ToggleShowPublicEvents",
		["strEventMouseRight"] = "",
		["strIcon"] = "spr_ObjectiveTracker_IconPathEvent",
		["strDefaultSort"] = kstrPublicEventContainer,
	}
	
	Event_FireGenericEvent("ObjectiveTracker_NewAddOn", tData)
	
	-- Try and build everything
	self:BuildAll()
	self:ResizeAll()
end

function PublicEventTracker:OnToggleShowEvents()
	self.bShowEvents = not self.bShowEvents
	self:ResizeAll()
end

-- Drawing

function PublicEventTracker:OnRealTimeUpdateTimer(nTime)
	for index, tEventInfo in pairs(self.tTimedEvents) do
		if tEventInfo.peEvent:IsActive() and tEventInfo.wndTitleFrame and tEventInfo.wndTitleFrame:IsValid() then
			local strTitle = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</T>", kstrLightGrey, tEventInfo.peEvent:GetName())
			strTitle = self:HelperPrefixTimeString(math.max(0, math.floor((tEventInfo.peEvent:GetTotalTime() - tEventInfo.peEvent:GetElapsedTime()) / 1000)), strTitle)
			tEventInfo.wndTitleFrame:SetAML(strTitle)
		else
			self.tTimedEvents[index] = nil
		end
	end

	for index, tEventObjectiveInfo in pairs(self.tTimedEventObjectives) do
		local wndCurrObjective = tEventObjectiveInfo.wndObjective
		if tEventObjectiveInfo.peEvent:IsActive() and wndCurrObjective and wndCurrObjective:IsValid() then
			if wndCurrObjective:FindChild("ObjectiveBtn") ~= nil then
				wndCurrObjective:FindChild("ObjectiveBtn"):SetTooltip(self:BuildEventObjectiveTitleString(tEventObjectiveInfo.peEvent, tEventObjectiveInfo.peoObjective, true))
				wndCurrObjective:FindChild("ObjectiveText"):SetAML(self:BuildEventObjectiveTitleString(tEventObjectiveInfo.peEvent, tEventObjectiveInfo.peoObjective))
			elseif wndCurrObjective:FindChild("ProgressContainer") ~= nil then
				self:UpdateDynamicBoss(wndCurrObjective, tEventObjectiveInfo.peoObjective:GetEvent(), tEventObjectiveInfo.peoObjective)--Have to make sure we get the right time and update description based on the objective type
			end
		else
			self.tTimedEventObjectives[index] = nil
		end
	end
	
	if next(self.tTimedEvents) == nil and next(self.tTimedEventObjectives) == nil then
		self.timerRealTimeUpdate:Stop()
	end
end

function PublicEventTracker:OnResizeDelayTimer(nTime)
	self:ResizeAll()
end

function PublicEventTracker:BuildAll()
	local bShowPublicEvents = false
	local arPublicEvents = PublicEvent.GetActiveEvents()
	for idx, peEvent in pairs(arPublicEvents) do
		if peEvent and peEvent:GetEventType() ~= PublicEvent.PublicEventType_LiveEvent then
			bShowPublicEvents = true
			break
		end
	end

	if #self.tZombiePublicEvents == 0 and not bShowPublicEvents then
		return
	end

	if #arPublicEvents > 1 then
		table.sort(arPublicEvents, function(a, b) return a:IsPriorityDisplay() end)
	end

	-- Events
	for key, peEvent in pairs(arPublicEvents) do
		if peEvent:IsActive() and peEvent:GetEventType() ~= PublicEvent.PublicEventType_LiveEvent then -- Done in the LiveEvents addon
			self:DrawEvent(peEvent)
		end
	end
	
	-- Trim zombies to max size
	local nZombiePublicEventCount = #self.tZombiePublicEvents - knMaxZombieEventCount
	if nZombiePublicEventCount > 0 then
		for idx = 1, nZombiePublicEventCount do
			table.remove(self.tZombiePublicEvents, 1)
		end
	end

	-- Now Draw Completed Events
	for key, tZombieEvent in pairs(self.tZombiePublicEvents) do
		self:DrawZombieEvent(self.wndEventContainerContent, tZombieEvent)
	end
end

function PublicEventTracker:ResizeAll()
	self.timerResizeDelay:Stop()
	local nStartingHeight = self.wndMain:GetHeight()
	local bStartingShown = self.wndMain:IsShown()
	
	local nOngoingGroupCount = self.knInitialGroupHeight
	
	local arPublicEvents = PublicEvent.GetActiveEvents()

	-- Events
	local nAlphabetNumber = 0
	for key, peEvent in pairs(arPublicEvents) do
		if peEvent:GetEventType() ~= PublicEvent.PublicEventType_LiveEvent then -- Done in the LiveEvents addon
			local wndEvent = self.tEventWndCache[peEvent:GetName()]
			if wndEvent ~= nil and wndEvent:IsValid() then
				nAlphabetNumber	= math.min(knNumberToLettersMax, nAlphabetNumber + 1)
			
				local wndEventLetter = wndEvent:FindChild("EventLetterBacker:EventLetter")
				wndEventLetter:SetText(ktNumbersToLetters[nAlphabetNumber])
				wndEventLetter:SetTextColor(self.kcrEventLetter)
				wndEvent:SetData(nAlphabetNumber)
			end
		end
	end
	
	-- Trim zombies to max size
	local nZombiePublicEventCount = #self.tZombiePublicEvents - knMaxZombieEventCount
	if nZombiePublicEventCount > 0 then
		for idx = 1, nZombiePublicEventCount do
			self:DestroyZombieEvent(self.tZombiePublicEvents[1])
			table.remove(self.tZombiePublicEvents, 1)
		end
	end

	-- Now Draw Completed Events
	for key, tZombieEvent in pairs(self.tZombiePublicEvents) do
		local wndEvent = self.tZombieEventWndCache[tZombieEvent]
		if wndEvent ~= nil and wndEvent:IsValid() then
			nAlphabetNumber	= math.min(knNumberToLettersMax, nAlphabetNumber + 1)
			wndEvent:FindChild("EventLetter"):SetText(ktNumbersToLetters[nAlphabetNumber])
			wndEvent:SetData(nAlphabetNumber)
		end
	end
	
	local wndGroupMinimizeBtn = self.wndEventContainer:FindChild("GroupMinimizeBtn")
	if self.tMinimized.bRoot then
		wndGroupMinimizeBtn:SetCheck(true)
	end
	
	if wndGroupMinimizeBtn:IsChecked() then
		self.wndEventContainerContent:Show(false)
	else
		self.wndEventContainerContent:Show(true)
		
		for idx, wndEvent in pairs(self.wndEventContainerContent:GetChildren()) do
			if wndEvent:GetName() == "EventItem" then
				self:ResizeEvent(wndEvent)
			end
		end
		
		nOngoingGroupCount = nOngoingGroupCount + self.wndEventContainerContent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
			return wndLeft:GetData() < wndRight:GetData()
		end)
	end
	
	local nEventCount = #arPublicEvents + #self.tZombiePublicEvents
	
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nOngoingGroupCount)
	self.wndMain:Show(self.bShowEvents and nEventCount > 0)
	
	if nStartingHeight ~= self.wndMain:GetHeight() or self.nEventCount ~= nEventCount or bStartingShown ~= self.wndMain:IsShown() then
		local tData =
		{
			["strAddon"] = Apollo.GetString("PublicEventTracker_PublicEvents"),
			["strText"] = nEventCount,
			["bChecked"] = self.bShowEvents,
		}
	
		Event_FireGenericEvent("ObjectiveTracker_UpdateAddOn", tData)
	end
	
	self.nEventCount = nEventCount
end

function PublicEventTracker:DestroyEvent(peEvent)
	local wndEvent = self.tEventWndCache[peEvent:GetName()]
	if wndEvent ~= nil and wndEvent:IsValid() then
		wndEvent:Destroy()
	end
	
	self.tEventWndCache[peEvent:GetName()] = nil
	
	for idObjective, tObjective in pairs(self.tObjectiveWndCache) do
		if tObjective.peEvent == peEvent then
			self.tObjectiveWndCache[idObjective] = nil
		end
	end
	
	self.tTimedEvents[peEvent:GetName()] = nil
	for idObjective, tEventObjectiveInfo in pairs(self.tTimedEventObjectives) do
		if tEventObjectiveInfo.peEvent == peEvent then
			self.tTimedEventObjectives[idObjective] = nil
		end
	end
end

function PublicEventTracker:DrawEvent(peEvent)
	local wndEvent = self.tEventWndCache[peEvent:GetName()]
	if wndEvent == nil or not wndEvent:IsValid() then
		wndEvent = Apollo.LoadForm(self.xmlDoc, "EventItem", self.wndEventContainerContent, self)
		wndEvent:SetData(0)
		self.tEventWndCache[peEvent:GetName()] = wndEvent
	end

	self:HelperSelectInteractHintArrowObject(peEvent, wndEvent:FindChild("ControlBackerBtn"))
	
	local wndTitleText = wndEvent:FindChild("TitleText")
	
	local wndEventStatsBacker = wndEvent:FindChild("EventStatsBacker")
	wndEventStatsBacker:FindChild("ShowEventStatsBtn"):SetData(peEvent)

	wndEvent:FindChild("ControlBackerBtn"):SetData(peEvent)
	wndEventStatsBacker:SetData(peEvent)

	-- Event Title
	local strTitle = string.format('<T Font="CRB_InterfaceMedium" TextColor="%s">%s</T>', kstrLightGrey, peEvent:GetName())
	if peEvent:GetTotalTime() > 0 and peEvent:IsActive() then
		strTitle = self:HelperPrefixTimeString(math.max(0, math.floor((peEvent:GetTotalTime() - peEvent:GetElapsedTime()) / 1000)), strTitle)
		self.tTimedEvents[peEvent:GetName()] = { peEvent = peEvent, wndTitleFrame = wndEvent:FindChild("TitleText") }
		self.timerRealTimeUpdate:Start()
	end
	wndTitleText:SetAML(strTitle)
	wndTitleText:SetHeightToContentHeight()

	-- Conditional Drawing
	wndEventStatsBacker:Show(peEvent:HasLiveStats())
	wndEventStatsBacker:SetBGColor(self.kcrEventLetterBacker)

	local function SortObjectivesByDisplayOrder(a, b)
		if a and not b then
			return true
		elseif not a and b then
			return false
		elseif not a and not b then
			return true
		end

		local nDisplayA = a:GetDisplayOrder()
		local nDisplayB = b:GetDisplayOrder()

		if nDisplayA == nDisplayB then
			return a:GetObjectiveId() < b:GetObjectiveId()
		elseif nDisplayA == 0 then
			return false
		elseif nDisplayB == 0 then
			return true
		else
			return nDisplayA < nDisplayB
		end
	end

	local arObjectives = peEvent:GetObjectives()
	if #arObjectives > 1 then
		table.sort(arObjectives, SortObjectivesByDisplayOrder)
	end

	-- Draw the Objective, or delete if it's still around
	for idx, peoObjective in pairs(arObjectives) do
		if not peoObjective:IsHidden() then
			if peoObjective:GetStatus() == PublicEventObjective.PublicEventStatus_Active then
				self:DrawEventObjective(peoObjective)
			else
				self:DestroyEventObjective(peoObjective)
			end
		end
	end
end

function PublicEventTracker:ResizeEvent(wndEvent)
	local nStartingHeight = wndEvent:GetHeight()
	
	local nTextWidth, nTextHeight = wndEvent:FindChild("TitleText"):SetHeightToContentHeight()
	local nHeight = math.max(self.knMinHeightEventItem, nTextHeight + 4) -- for lower g height
	
	local wndEventMinimizeBtn = wndEvent:FindChild("EventMinimizeBtn")
	if wndEventMinimizeBtn then
		local wndObjectiveContainer = wndEvent:FindChild("ObjectiveContainer")
		if wndEventMinimizeBtn:IsChecked() then
			wndObjectiveContainer:Show(false)
		else
			wndObjectiveContainer:Show(true)
			
			for idx, wndObjective in pairs(wndObjectiveContainer:GetChildren()) do
				self:ResizeEventObjective(wndObjective)
			end
			
			local nObjectiveHeight = wndObjectiveContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
				if not Window.is(wndLeft) or not Window.is(wndRight) or not wndLeft:IsValid() or not wndRight:IsValid() or not wndLeft:GetData() or not wndRight:GetData() then
					return false
				end
				return wndLeft:GetData():GetCategory() < wndRight:GetData():GetCategory()
			end)
			
			local nLeft, nTop, nRight, nBottom = wndObjectiveContainer:GetAnchorOffsets()
			wndObjectiveContainer:SetAnchorOffsets(nLeft, nHeight, nRight, nHeight + nObjectiveHeight)
			nHeight = nHeight + nObjectiveHeight
		end
	end
	
	nHeight = math.max(nHeight, self.knMinHeightEventItem)
	local nLeft, nTop, nRight, nBottom = wndEvent:GetAnchorOffsets()
	wndEvent:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + 8)
	
	return nStartingHeight == wndEvent:GetHeight()
end

function PublicEventTracker:DestroyEventObjective(peoObjective)
	local wndObjective
	local tObjective = self.tObjectiveWndCache[peoObjective:GetObjectiveId()]
	if tObjective ~= nil and tObjective.wndObjective ~= nil then--Now multiple objectives can point to the same window with Dynamic Boss.
		tObjective.wndObjective:Destroy()
	end
	
	self.tObjectiveWndCache[peoObjective:GetObjectiveId()] = nil
end

function PublicEventTracker:DrawEventObjective(peoObjective)
	local wndObjective
	local tObjective = self.tObjectiveWndCache[peoObjective:GetObjectiveId()]
	if tObjective ~= nil then
		wndObjective = tObjective.wndObjective
	end

	local peEvent = peoObjective:GetEvent()
	if peEvent:ShouldUseCustomTracker() then--Dynamic Bosses
		wndObjective = self:HelperDrawDynamicBosses(peEvent)--Has to collect all objectives information and redraw based on how dynamic bosses public event is currently set up.
	else--Normal Public Events
		wndObjective = self:HelperDrawStandardObjective(peEvent, peoObjective)
	end

	tObjective = { wndObjective = wndObjective, peEvent = peEvent }
	self.tObjectiveWndCache[peoObjective:GetObjectiveId()] = tObjective
	
end

function PublicEventTracker:HelperDrawStandardObjective(peEvent, peoObjective)
	local wndEvent = self.tEventWndCache[peEvent:GetName()]
	if wndEvent == nil or not wndEvent:IsValid() then
		return
	end

	local wndObjective = nil
	if self.tObjectiveWndCache[peoObjective:GetObjectiveId()] then
		wndObjective = self.tObjectiveWndCache[peoObjective:GetObjectiveId()].wndObjective
	else
		wndObjective = Apollo.LoadForm(self.xmlDoc, "EventObjectiveItem", wndEvent:FindChild("ObjectiveContainer"), self)
		wndEvent:SetData(0)
	end

	local wndQuestObjectiveBtn = wndObjective:FindChild("ObjectiveBtn")
	wndQuestObjectiveBtn:SetData({ peoObjective = peoObjective })
	wndQuestObjectiveBtn:SetTooltip(self:BuildEventObjectiveTitleString(peEvent, peoObjective, true))
	wndObjective:FindChild("ObjectiveText"):SetAML(self:BuildEventObjectiveTitleString(peEvent, peoObjective, false))

	if peoObjective:GetObjectiveType() == PublicEventObjective.PublicEventObjectiveType_HardMode then
		wndObjective:FindChild("ObjectiveText"):SetSprite("IconSprites:Icon_Windows16_UI_CRB_PVPHardMode")
		wndObjective:FindChild("ObjectiveText"):SetTooltip(Apollo.GetString("PublicEventTracker_HardModeObjective"))
	end
	
	if peoObjective:GetTotalTime() > 0 then
		self.tTimedEventObjectives[peoObjective:GetObjectiveId()] = { peEvent = peEvent, peoObjective = peoObjective, wndObjective = wndObjective }
		self.timerRealTimeUpdate:Start()
	end

	-- Progress Bar
	if peoObjective:GetObjectiveType() == PublicEventObjective.PublicEventObjectiveType_ContestedArea then
		local nPercent = peoObjective:GetContestedAreaRatio()
		if peoObjective:GetContestedAreaOwningTeam() == 0 then
			nPercent = (nPercent + 100.0) * 0.5
		end

		local wndObjectiveProg = wndObjective:FindChild("PublicProgressItem")
		if wndObjectiveProg == nil or not wndObjectiveProg:IsValid() then
			wndObjectiveProg = Apollo.LoadForm(self.xmlDoc, "PublicProgressItem", wndObjective, self)
		end
		
		local wndPublicProgressBar = wndObjectiveProg:FindChild("PublicProgressBar")
		wndPublicProgressBar:SetMax(100)
		wndPublicProgressBar:SetProgress(nPercent)
		wndPublicProgressBar:EnableGlow(false)
		wndObjectiveProg:FindChild("PublicProgressText"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Percent"), math.floor(nPercent)))

	elseif peoObjective:ShowPercent() or peoObjective:ShowHealthBar() then
		local wndObjectiveProg = wndObjective:FindChild("PublicProgressItem")
		if wndObjectiveProg == nil or not wndObjectiveProg:IsValid() then
			wndObjectiveProg = Apollo.LoadForm(self.xmlDoc, "PublicProgressItem", wndObjective, self)
		end
	
		local nCompleted = peoObjective:GetCount()
		local nNeeded = peoObjective:GetRequiredCount()
		
		local wndPublicProgressBar = wndObjectiveProg:FindChild("PublicProgressBar")
		wndPublicProgressBar:SetMax(nNeeded)
		wndPublicProgressBar:SetProgress(nCompleted)
		wndPublicProgressBar:EnableGlow(nCompleted > 0 and nCompleted ~= nNeeded)
		wndObjectiveProg:FindChild("PublicProgressText"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Percent"), math.floor(nCompleted / nNeeded * 100)))
	end

	-- Objective Spell Item
	if peoObjective:GetSpell() then
		local wndSpellBtn = wndObjective:FindChild("SpellItemObjectiveBtn")
		if wndSpellBtn == nil or not wndSpellBtn:IsValid() then
			wndSpellBtn = Apollo.LoadForm(self.xmlDoc, "SpellItemObjectiveBtn", wndObjective, self)
		end
		wndSpellBtn:SetContentId(peoObjective)
	end

	return wndObjective
end

function PublicEventTracker:HelperDrawDynamicBosses(peEvent)
	local wndEvent = self.tEventWndCache[peEvent:GetName()]
	if wndEvent == nil or not wndEvent:IsValid() then
		return
	end

	local arObjectives = peEvent:GetObjectives()
	if arObjectives and #arObjectives > 0 then
		for idx, peoObjective in pairs(arObjectives) do
			local wndObjective = wndEvent:FindChild("DynamicBosses")
			if not wndObjective or not wndObjective:IsValid() then
				wndObjective = Apollo.LoadForm(self.xmlDoc, "DynamicBosses", wndEvent:FindChild("ObjectiveContainer"), self)
				local wndProgressBar = wndObjective:FindChild("ProgressBar")
				wndProgressBar:SetFloor(0)
				wndProgressBar:SetMax(knDynamicBossMaxPoints)
				wndEvent:SetData(0)
			end
			self:UpdateDynamicBoss(wndObjective, peoObjective:GetEvent(), peoObjective)
		end
	end

	return wndObjective
end

function PublicEventTracker:UpdateDynamicBoss(wndObjective, peEvent, peoObjective)
	local wndDynamicBossText = wndObjective:FindChild("DynamicBossText")
	wndDynamicBossText:SetText(peoObjective:GetShortDescription())

	local eObjectiveType = peoObjective:GetObjectiveType()
	if eObjectiveType == PublicEventObjective.PublicEventObjectiveType_TimedWin then
		local nTime = math.floor((peoObjective:GetTotalTime() - peoObjective:GetElapsedTime())/1000)
		local wndTimer = wndObjective:FindChild("Timer")
		wndTimer:SetText(ConvertSecondsToTimer(nTime, 2))

		local nOnjectiveId = peoObjective:GetObjectiveId()
		local strTimeColor = "UI_WindowTextTextPureGreen"
		if nTime <= 0 then
			strTimeColor = "UI_TextMetalBody"
			self.tTimedEventObjectives[nOnjectiveId] = nil
		elseif not self.tTimedEventObjectives[nOnjectiveId] then
			self.tTimedEventObjectives[nOnjectiveId] = { peEvent = peEvent, peoObjective = peoObjective, wndObjective = wndObjective }
			self.timerRealTimeUpdate:Start()
		end
		wndTimer:SetTextColor(strTimeColor)
	elseif eObjectiveType == PublicEventObjective.PublicEventObjectiveType_ResourcePool then
		local nPoints = peoObjective:GetCount()
		local wndProgressBar = wndObjective:FindChild("ProgressBar")
		wndProgressBar:SetProgress(nPoints)
		wndProgressBar:SetTooltip(String_GetWeaselString(Apollo.GetString("PublicEventTracker_ObjectiveProgress"), nPoints))
	end
end

function PublicEventTracker:ResizeEventObjective(wndObjective)
	local nStartingHeight = wndObjective:GetHeight()
	
	local nObjTextHeight = self.knInitialEventObjectiveHeight

	-- If there's the spell icon is bigger, use that instead
	local wndSpellItemObjectiveBtn = wndObjective:FindChild("SpellItemObjectiveBtn")
	if wndSpellItemObjectiveBtn ~= nil and wndSpellItemObjectiveBtn:IsValid() then
		nObjTextHeight = math.max(nObjTextHeight, wndSpellItemObjectiveBtn:GetHeight())
	end
	
	-- If the text is bigger, use that instead
	local wndQuestObjectiveText = wndObjective:FindChild("ObjectiveText")
	if wndQuestObjectiveText ~= nil and wndQuestObjectiveText:IsValid() then
		local nLocalWidth, nLocalHeight = wndQuestObjectiveText:SetHeightToContentHeight()
		nObjTextHeight = math.max(nObjTextHeight, nLocalHeight + 4) -- for lower g height

		-- Fake V-Align to match the button if it's just one line of text
		if wndSpellItemObjectiveBtn ~= nil and wndSpellItemObjectiveBtn:IsValid() and nLocalHeight < 20 then
			local nLeft, nTop, nRight, nBottom = wndQuestObjectiveText:GetAnchorOffsets()
			wndQuestObjectiveText:SetAnchorOffsets(nLeft, 9, nRight, nBottom)
		end
	end
	
	-- Also add extra height for Progress Bars
	local wndPublicProgressItem = wndObjective:FindChild("PublicProgressItem")
	if wndPublicProgressItem ~= nil and wndPublicProgressItem:IsValid() then
		nObjTextHeight = nObjTextHeight + wndPublicProgressItem:GetHeight()
	end

	--Add Dynamic Boss Height.
	local wndProgressContainer = wndObjective:FindChild("ProgressContainer")
	if wndProgressContainer ~= nil and wndProgressContainer:IsValid() then
		nObjTextHeight = nObjTextHeight + self.knInitialDynamicBossHeight
	end
	
	local nLeft, nTop, nRight, nBottom = wndObjective:GetAnchorOffsets()
	wndObjective:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nObjTextHeight)
	
	return nStartingHeight == wndObjective:GetHeight()
end

function PublicEventTracker:BuildEventObjectiveTitleString(peEvent, peoObjective, bIsTooltip)
	-- Use short form or reward text if possible
	local strResult = ""
	local strShortText = peoObjective:GetShortDescription()
	if strShortText and Apollo.StringLength(strShortText) > 0 and not bIsTooltip then
		strResult = string.format('<T Font="CRB_InterfaceMedium">%s</T>', strShortText)
	else
		strResult = string.format('<T Font="CRB_InterfaceMedium">%s</T>', peoObjective:GetDescription())
	end

	-- Progress Brackets and Time if Active
	if peoObjective:GetStatus() == PublicEventObjective.PublicEventStatus_Active then
		local nCompleted = peoObjective:GetCount()
		local eCategory = peoObjective:GetCategory()
		local eType = peoObjective:GetObjectiveType()
		local nNeeded = peoObjective:GetRequiredCount()

		-- Prefix Brackets
		local strPrefix = ""
		if nNeeded == 0 and (eType == PublicEventObjective.PublicEventObjectiveType_Exterminate or eType == PublicEventObjective.PublicEventObjectiveType_DefendObjectiveUnits) then
			strPrefix = string.format('<T Font="CRB_InterfaceMedium_B">%s</T>', String_GetWeaselString(Apollo.GetString("QuestTracker_Remaining"), Apollo.FormatNumber(nCompleted, 0, true)))
		elseif eType == PublicEventObjective.PublicEventObjectiveType_DefendObjectiveUnits and not peoObjective:ShowPercent() and not peoObjective:ShowHealthBar() then
			strPrefix = string.format('<T Font="CRB_InterfaceMedium_B">%s</T>', String_GetWeaselString(Apollo.GetString("QuestTracker_Remaining"), Apollo.FormatNumber(nCompleted - nNeeded + 1, 0, true)))
		elseif eType == PublicEventObjective.PublicEventObjectiveType_Turnstile then
			strPrefix = string.format('<T Font="CRB_InterfaceMedium_B">%s</T>', String_GetWeaselString(Apollo.GetString("QuestTracker_WaitingForMore"), Apollo.FormatNumber(math.abs(nCompleted - nNeeded), 0, true)))
		elseif eType == PublicEventObjective.PublicEventObjectiveType_ParticipantsInTriggerVolume then
			strPrefix = string.format('<T Font="CRB_InterfaceMedium_B">%s</T>', String_GetWeaselString(Apollo.GetString("QuestTracker_WaitingForMore"), Apollo.FormatNumber(math.abs(nCompleted - nNeeded), 0, true)))
		elseif eType == PublicEventObjective.PublicEventObjectiveType_TimedWin then
			-- Do Nothing
		elseif nNeeded > 1 and not peoObjective:ShowPercent() and not peoObjective:ShowHealthBar() then
			strPrefix = string.format('<T Font="CRB_InterfaceMedium_B">%s</T>', String_GetWeaselString(Apollo.GetString("QuestTracker_ValueComplete"), Apollo.FormatNumber(nCompleted, 0, true), Apollo.FormatNumber(nNeeded, 0, true)))
		end

		if strPrefix ~= "" then
			strResult = String_GetWeaselString(Apollo.GetString("QuestTracker_BuildText"), strPrefix, strResult)
			strPrefix = ""
		end

		-- Prefix Time
		if peoObjective:IsBusy() then
			strPrefix = string.format('<T Font="CRB_InterfaceMedium_B" TextColor="%s">%s </T>', kstrYellow, Apollo.GetString("QuestTracker_Paused"))
			strResult = String_GetWeaselString(Apollo.GetString("QuestTracker_BuildText"), strPrefix, strResult)
			strPrefix = ""
		elseif peoObjective:GetTotalTime() > 0 then
			local strColorOverride = peoObjective:GetObjectiveType() == PublicEventObjective.PublicEventObjectiveType_TimedWin and kstrGreen or nil
			local nTime = math.max(0, math.floor((peoObjective:GetTotalTime() - peoObjective:GetElapsedTime()) / 1000))
			strResult = self:HelperPrefixTimeString(nTime, strResult, strColorOverride)
		end

		-- Extra formatting
		local bDungeon = peEvent:GetEventType() == PublicEvent.PublicEventType_Dungeon
		if eCategory == PublicEventObjective.PublicEventObjectiveCategory_PlayerPath then
			strPrefix = string.format('<T Font="CRB_InterfaceMedium_B">%s </T>', String_GetWeaselString(Apollo.GetString("CRB_ProgressSimple"), self.strPlayerPath or Apollo.GetString("CRB_Path")))
		elseif eCategory == PublicEventObjective.PublicEventObjectiveCategory_Optional then
			strPrefix = string.format('<T Font="CRB_InterfaceMedium_B">%s </T>', bDungeon and kstrDungeonBronzeIcon or Apollo.GetString("QuestTracker_OptionalTag"))
		elseif eCategory == PublicEventObjective.PublicEventObjectiveCategory_Challenge then
			strPrefix = string.format('<T Font="CRB_InterfaceMedium_B">%s </T>', bDungeon and kstrDungeonGoldIcon or Apollo.GetString("QuestTracker_ChallengeTag"))
		end

		if strPrefix ~= "" then
			strResult = String_GetWeaselString(Apollo.GetString("QuestTracker_BuildText"), strPrefix, strResult)
		end
	end
	
	return strResult
end

function PublicEventTracker:DestroyZombieEvent(tZombieEvent)
	local wndEvent = self.tZombieEventWndCache[tZombieEvent]
	if wndEvent ~= nil and wndEvent:IsValid() then
		wndEvent:Destroy()
	end
	
	self.tZombieEventWndCache[tZombieEvent] = nil
end

function PublicEventTracker:DrawZombieEvent(tZombieEvent)
	local wndEvent = self.tZombieEventWndCache[tZombieEvent]
	if wndEvent == nil or not wndEvent:IsValid() then
		wndEvent = Apollo.LoadForm(self.xmlDoc, "ZombieEventItem", self.wndEventContainerContent, self)
		self.tZombieEventWndCache[tZombieEvent] = wndEvent
	end

	local wndCallbackBtn = wndEvent:FindChild("CompletedBacker:CallbackBtn")
	wndCallbackBtn:SetData(tZombieEvent.peEvent)

	-- Win or Loss formatting here
	local strTitle = string.format("<T Font=\"CRB_InterfaceMedium_B\">%s</T>", tZombieEvent.strName)
	if tZombieEvent.eReason == PublicEvent.PublicEventParticipantRemoveReason_CompleteFailure then
		local strFailed = String_GetWeaselString(Apollo.GetString("QuestTracker_Failed"), strTitle)
		wndEvent:FindChild("EventLetter"):SetTextColor(ApolloColor.new(kstrRed))
		wndEvent:FindChild("EventLetterBacker"):SetSprite("sprQT_NumBackerFailedPE")
		wndCallbackBtn:ChangeArt("CRB_QuestTrackerSprites:btnQT_QuestFailed")
		wndEvent:FindChild("TitleText"):SetAML(string.format("<T Font=\"CRB_InterfaceMedium_B\" TextColor=\"%s\">%s</T>", kstrRed, strFailed))

	elseif tZombieEvent.eReason == PublicEvent.PublicEventParticipantRemoveReason_CompleteSuccess then
		local strComplete = String_GetWeaselString(Apollo.GetString("QuestTracker_Complete"), strTitle)
		wndEvent:FindChild("EventLetter"):SetTextColor(ApolloColor.new(kstrGreen))
		wndEvent:FindChild("EventLetterBacker"):SetSprite("sprQT_NumBackerCompletedPE")
		wndCallbackBtn:ChangeArt("CRB_QuestTrackerSprites:btnQT_QuestRedeem")
		wndEvent:FindChild("TitleText"):SetAML(string.format("<T Font=\"CRB_InterfaceMedium_B\" TextColor=\"%s\">%s</T>", kstrGreen, strComplete))
	end
	
	self:ResizeEvent(wndEvent)
end

-- Game Events

function PublicEventTracker:OnPublicEventStart(peEvent)
	-- Remove from zombie list if we're restarting it
	for idx, tZombieEvent in pairs(self.tZombiePublicEvents) do
		if tZombieEvent.peEvent == peEvent then
			self:DestroyZombieEvent(tZombieEvent)
			table.remove(self.tZombiePublicEvents, idx)
			break
		end
	end
	
	if peEvent:IsActive() and peEvent:GetEventType() ~= PublicEvent.PublicEventType_LiveEvent then
		self:DrawEvent(peEvent)
		self.timerResizeDelay:Start()
	end
end

function PublicEventTracker:OnPublicEventEnd(peEvent, eReason, tStats)
	local tZombieEvent = nil

	-- Add to list, or delete if we left the area
	if (eReason == PublicEvent.PublicEventParticipantRemoveReason_CompleteSuccess or eReason == PublicEvent.PublicEventParticipantRemoveReason_CompleteFailure)
		and peEvent:GetEventType() ~= PublicEvent.PublicEventType_SubEvent then
		
		local tZombieEvent = {peEvent = peEvent, eReason = eReason, tStats = tStats, strName = peEvent:GetName()}
		table.insert(self.tZombiePublicEvents, tZombieEvent)
		
		self:DrawZombieEvent(tZombieEvent)
	end
	
	self:DestroyEvent(peEvent)
	
	self.timerResizeDelay:Start()
end

function PublicEventTracker:OnPublicEventUpdate(peEvent)
	self:DrawEvent(peEvent)
	
	self.timerResizeDelay:Start()
end

function PublicEventTracker:OnPublicEventObjectiveUpdate(peoObjective)
	if peoObjective:GetStatus() == PublicEventObjective.PublicEventStatus_Active and not peoObjective:IsHidden() then
		self:DrawEventObjective(peoObjective)
	else
		self:DestroyEventObjective(peoObjective)
	end
	
	self.timerResizeDelay:Start()
end

function PublicEventTracker:OnAddSpellShortcut(tSpellData, eReason, nObjectiveId)
	local tObjectiveData = self.tObjectiveWndCache[nObjectiveId]
	if not tObjectiveData then
		return
	end

	for idx, peoObjective in pairs(tObjectiveData.peEvent:GetObjectives()) do
		if peoObjective:GetObjectiveId() == nObjectiveId then
			self:OnPublicEventObjectiveUpdate(peoObjective)
			return
		end
	end
end

-- Control Events

function PublicEventTracker:OnEpisodeGroupControlBackerMouseEnter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	wndControl:FindChild("GroupMinimizeBtn"):Show(true)
end

function PublicEventTracker:OnEpisodeGroupControlBackerMouseExit(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndBtn = wndControl:FindChild("GroupMinimizeBtn")
	wndBtn:Show(wndBtn:IsChecked())
end

function PublicEventTracker:OnEpisodeGroupMinimizedBtnChecked(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	self.tMinimized.bRoot = true
	self:ResizeAll()
end

function PublicEventTracker:OnEpisodeGroupMinimizedBtnUnChecked(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	self.tMinimized.bRoot = false
	self:ResizeAll()
end

function PublicEventTracker:OnEpisodeHintArrow(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local oSelected = wndControl:GetData()
	oSelected:ShowHintArrow()
	GameLib.SetInteractHintArrowObject(oSelected)
end

function PublicEventTracker:OnShowEventStatsBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local peEvent = wndControl:GetData()
	if peEvent and peEvent:HasLiveStats() then
		local tLiveStats = peEvent:GetLiveStats()
		Event_FireGenericEvent("GenericEvent_OpenEventStats", peEvent, peEvent:GetMyStats(), tLiveStats.arTeamStats, tLiveStats.arParticipantStats)
	end
end

function PublicEventTracker:OnEventCallbackBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local peEvent = wndHandler:GetData()
	for idx, tZombieEvent in pairs(self.tZombiePublicEvents) do
		if tZombieEvent.peEvent and tZombieEvent.peEvent == peEvent then
			if tZombieEvent.peEvent:GetEventType() == PublicEvent.PublicEventType_WorldEvent then
				Event_FireGenericEvent("GenericEvent_OpenEventStatsZombie", tZombieEvent)
			end
			
			self:DestroyZombieEvent(tZombieEvent)
			table.remove(self.tZombiePublicEvents, idx)
			self.timerResizeDelay:Start()
			return
		end
	end
end

function PublicEventTracker:OnEventObjectiveHintArrow(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	local tData = wndHandler:GetData()
	if tData and tData.peoObjective then
		tData.peoObjective:ShowHintArrow() -- Objectives do NOT default to parent if it fails
		GameLib.SetInteractHintArrowObject(tData.peoObjective)
	end

	return true -- Stop Propagation so the Quest Hint Arrow won't eat this call
end

function PublicEventTracker:OnGenerateTooltip(wndControl, wndHandler, eType, arg1, arg2)
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

function PublicEventTracker:CloseContextMenu()
	if self.wndContextMenu and self.wndContextMenu:IsValid() then
		self.wndContextMenu:Destroy()
		self.wndContextMenu = nil
		
		return true
	end
	
	return false
end

-- Helpers

function PublicEventTracker:HelperPrefixTimeString(fTime, strAppend, strColorOverride)
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

function PublicEventTracker:HelperSelectInteractHintArrowObject(oCur, wndBtn)
	local oInteractObject = GameLib.GetInteractHintArrowObject()
	if not oInteractObject or (oInteractObject and oInteractObject.eHintArrowType == GameLib.CodeEnumHintType.None) then
		return
	end

	local bIsInteractHintArrowObject = oInteractObject.objTarget and oInteractObject.objTarget == oCur
	if bIsInteractHintArrowObject and not wndBtn:IsChecked() then
		wndBtn:SetCheck(true)
	end
end

function PublicEventTracker:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors = 
	{
		[GameLib.CodeEnumTutorialAnchor.PublicEventTracker] 	= true,
	}
	
	if not tAnchors[eAnchor] then
		return
	end
	
	local tAnchorMapping = 
	{
		[GameLib.CodeEnumTutorialAnchor.PublicEventTracker] = self.wndMain,
	}
	
	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

local PublicEventTrackerInst = PublicEventTracker:new()
PublicEventTrackerInst:Init()
