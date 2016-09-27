-----------------------------------------------------------------------------------------------
-- Client Lua Script for WelcomeWindow/LiveEvents
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
require "StorefrontLib"
 
local LiveEvents = {} 
local knObjectivePadding = 5
 
function LiveEvents:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.kstrTitle = Apollo.GetString("LiveEvents_Title")
	o.knSortOrder = 3

	o.knRotationTime = 5
	o.kbRotationContinous = true

	o.keDirection = {Next = 0, Previous = 1}
	o.kstrMLIcon = "<T Image=\"CRB_MegamapSprites:sprMap_PlayerDot\"></T>"
	
	-- Assume that Overview pane is displayed by default
	o.bOverViewShowing = true

    return o
end

function LiveEvents:Init()
    Apollo.RegisterAddon(self, false, self.kstrTitle)
end
 
function LiveEvents:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("LiveEvents.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function LiveEvents:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	self.bTimerRunning = false
	self.timerRotation = ApolloTimer.Create(self.knRotationTime, self.kbRotationContinous, "OnTimerRotation", self)
	self.timerRotation:Stop()

	--WelcomeWindow Events
	Apollo.RegisterEventHandler("WelcomeWindow_Loaded", 		"OnWelcomeWindowLoaded", self)
	Apollo.RegisterEventHandler("WelcomeWindow_TabSelected",	"OnWelcomeWindowTabSelected", self)
	Apollo.RegisterEventHandler("WelcomeWindow_Closed",			"OnClose", self)

	--LiveEvent Events
	Apollo.RegisterEventHandler("BonusEventsChanged",			"OnBonusEventsChanged", self)

	--General Updates
	Apollo.RegisterEventHandler("PlayerCurrencyChanged",		"OnPlayerCurrencyChanged", self)

	Event_FireGenericEvent("WelcomeWindow_RequestParent")

end

function LiveEvents:OnWelcomeWindowLoaded(wndParent)
	if not wndParent or not wndParent:IsValid() then
		return
	end

	Apollo.RemoveEventHandler("WelcomeWindow_Loaded", self)

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "LiveEventsBig", wndParent, self)
	Event_FireGenericEvent("WelcomeWindow_TabContent", self.kstrTitle, self.wndMain, self.knSortOrder)

	Apollo.RegisterEventHandler("OverView_Loaded", 	"OnOverViewLoaded", self)
	Event_FireGenericEvent("OverView_RequestParent")

	local wndMeasureTitle = self.wndMain:FindChild("TitleBlock")
	local wndMeasureItems = self.wndMain:FindChild("ItemsBlock")

	local nTLeft, nTTop, nTRight, nTBottom = wndMeasureTitle:GetAnchorOffsets()
	local nILeft, nITop, nIRight, nIBottom = wndMeasureItems:GetAnchorOffsets()

	self.knRightPadding = nITop - nTBottom
end

function LiveEvents:OnOverViewLoaded(strOverViewTitle, wndParent)
	if not wndParent or not wndParent:IsValid() then
		return
	end

	Apollo.RemoveEventHandler("OverView_Loaded", self)

	self.strOverViewTitle = strOverViewTitle--Used to determine if the Overview Tab is selected.
	self.wndLiveEventsOverview = Apollo.LoadForm(self.xmlDoc, "LiveEventsOverview", wndParent:FindChild("LiveEvents"), self)

	self:InitializeContent()
end

function LiveEvents:InitializeContent()
	local arBonusLiveEvents = LiveEventsLib.GetBonusLiveEventList()
	if not arBonusLiveEvents then
		return
	end

	self.wndMain:FindChild("NextBtn"):SetData(self.keDirection.Next)
	self.wndMain:FindChild("PreviousBtn"):SetData(self.keDirection.Previous)
	self.wndLiveEventsOverview:FindChild("NextBtn"):SetData(self.keDirection.Next)
	self.wndLiveEventsOverview:FindChild("PreviousBtn"):SetData(self.keDirection.Previous)


	local wndContent = self.wndLiveEventsOverview:FindChild("Content")
	local wndSequenceBtnContainer = wndContent:FindChild("SequenceBtnContainer")
	wndSequenceBtnContainer:DestroyChildren()

	local wndEventBtnContainer = self.wndMain:FindChild("EventBtnContainer")
	wndEventBtnContainer:DestroyChildren()

	self.tEventBtns = {}
	self.nNumEvents = 0
	self.nCurrEventIndex = 0

	--Create small btns
	for idx, tEventData in pairs(arBonusLiveEvents) do
		self.nNumEvents = self.nNumEvents + 1

		local wndSequenceBtn = Apollo.LoadForm(self.xmlDoc, "SequenceBtn", wndSequenceBtnContainer, self)
		local wndEventBtn = Apollo.LoadForm(self.xmlDoc, "EventBtn", wndEventBtnContainer, self)
		wndEventBtn:FindChild("Icon"):SetSprite(tEventData:GetIcon())

		local tEventDetails = {tEventData = tEventData, nEventIndex = self.nNumEvents}
		wndSequenceBtn:SetData(tEventDetails)
		wndEventBtn:SetData(tEventDetails)
		self.tEventBtns[self.nNumEvents] = {wndSequenceBtn = wndSequenceBtn, wndEventBtn = wndEventBtn}

	end
	
	wndSequenceBtnContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
	wndEventBtnContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)

	local bHaveEvents = self.nNumEvents > 0
	wndContent:FindChild("NoEventBlocker"):Show(not bHaveEvents)
	wndContent:FindChild("EventContainer"):Show(bHaveEvents)

	if bHaveEvents then
		self.nCurrEventIndex = 1--Check the first button.
		local tEventBtns = self.tEventBtns[self.nCurrEventIndex]
		tEventBtns.wndSequenceBtn:SetCheck(true)
		tEventBtns.wndEventBtn:SetCheck(true)
	end
	
	local bHaveMultipleEvents = self.nNumEvents > 1
	if bHaveMultipleEvents then
		wndEventBtnContainer:Show(true)
		wndSequenceBtnContainer:Show(true)
		self.wndMain:FindChild("NextBtn"):Show(true)
		self.wndMain:FindChild("PreviousBtn"):Show(true)
		self.wndLiveEventsOverview:FindChild("NextBtn"):Show(true)
		self.wndLiveEventsOverview:FindChild("PreviousBtn"):Show(true)
	end
	
	local wndEventContainer = self.wndMain:FindChild("EventContainer")
	local wndEventUpcoming = self.wndMain:FindChild("EventUpcoming")

	local nLeft, nTop, nRight, nBottom = wndEventContainer:GetOriginalLocation():GetOffsets()
	local nNewBottom = nBottom

	--Handle Upcoming Events Section
	local bHaveUpcomingEvents = false
	if not bHaveUpcomingEvents then
		nNewBottom = 0--Move the container's bottom down
	else
		local wndEventList = wndEventUpcoming:FindChild("EventList")
		local tUpcoming = {
			[1] = {strTitle = "Space Chase", strBody = "Nice Bod", strIcon = "LoginIncentives:sprLoginIncentives_AdventureChase", strDescription = "Go on an awesome adventure through space."},
			[2] = {strTitle = "Enemy Aproaches", strBody = "Scary", strIcon = "LoginIncentives:sprLoginIncentives_Enemy", strDescription = "Go on the hunt, befor the enemy successfully hunts you!"},
			[3] = {strTitle = "Royalty", strBody = "Gimme My Money", strIcon = "LoginIncentives:sprLoginIncentives_Crown", strDescription = "Go grab that crown!"},
			[4] = {strTitle = "Get Some Learning", strBody = "Brain Power", strIcon = "LoginIncentives:sprLoginIncentives_DoubleXP1", strDescription = "Kill everything and everyone."},
		}
		local nChildren = #tUpcoming
		local nWidth = 1 / nChildren
		for idx, tEventData in pairs(tUpcoming) do
			local wndUpcomingEvent = Apollo.LoadForm(self.xmlDoc, "UpcomingEvent", wndEventList, self)
			wndUpcomingEvent:FindChild("Title"):SetText(tEventData.strTitle)
			wndUpcomingEvent:FindChild("Date"):SetText(tEventData.strBody)
			wndUpcomingEvent:FindChild("Icon"):SetSprite(tEventData.strIcon)
			wndUpcomingEvent:SetAnchorPoints(nWidth * (idx - 1), 0, nWidth * idx, 1)
			wndUpcomingEvent:SetTooltip(tEventData.strDescription)
		end
	end

	wndEventContainer:SetAnchorOffsets(nLeft, nTop, nRight, nNewBottom)
	wndEventUpcoming:Show(bHaveUpcomingEvents)

	local strTooltip = ""
	if not bHaveEvents then
		strTooltip = Apollo.GetString("LoginIncentives_NoEvents")
	end
	Event_FireGenericEvent("WelcomeWindow_EnableTab", self.kstrTitle, bHaveEvents, strTooltip)
end

function LiveEvents:OnWelcomeWindowTabSelected(strSelectedTab)
	self.tCurrentEventShown = nil
	self.bTimerRunning = false
	self.timerRotation:Stop()
	self.bOverViewShowing = strSelectedTab == self.strOverViewTitle
	if self.bOverViewShowing then
		if self.nNumEvents > 0 then
			self.bTimerRunning = true
			self.timerRotation:Start()
		end
		self:RedrawOverViewSection()
	elseif strSelectedTab == self.kstrTitle then
		self:RedrawMainSection()
	end
end

function LiveEvents:RedrawOverViewSection()
	self:DrawCommonSection(self.wndLiveEventsOverview)
end

function LiveEvents:RedrawMainSection()
	self:DrawCommonSection(self.wndMain)

	local tEventBtns = self.tEventBtns[self.nCurrEventIndex]
	if not tEventBtns then
		return
	end

	local tEventDetails = tEventBtns.wndSequenceBtn:GetData()
	local tLiveEvent = tEventDetails.tEventData

	local wndRight = self.wndMain:FindChild("Right")
	local wndTitleBlock = wndRight:FindChild("TitleBlock")
	local wndItemsBlock = wndRight:FindChild("ItemsBlock")
	local wndObjectives = wndRight:FindChild("Objectives")

	local tDisplayItems = tEventDetails.tEventData:GetDisplayItems()

	--Build Reward List
	local wndRewardist = wndItemsBlock:FindChild("Rewards:ItemList")
	wndRewardist:DestroyChildren()
	for idx, itemReward in pairs(tDisplayItems.tItems) do
		local wndItemIcon = Apollo.LoadForm(self.xmlDoc, "ItemIcon", wndRewardist, self)
		local wndItem = wndItemIcon:FindChild("Item")
		wndItem:GetWindowSubclass():SetItem(itemReward)
		wndItem:SetTooltipForm(nil)
	end
	local bHaveRewards = #wndRewardist:GetChildren() > 0
	if bHaveRewards then
		wndRewardist:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
	end

	--Build Store Item List
	local wndStoreList = wndItemsBlock:FindChild("Store:ItemList")
	wndStoreList:DestroyChildren()

	for idx, tLink in pairs(tDisplayItems.tStoreLinks) do
		if StorefrontLib.IsLinkValid(tLink.nStoreLinkId) then
			local wndItemIcon = Apollo.LoadForm(self.xmlDoc, "ItemIcon", wndStoreList, self)
			local wndItem = wndItemIcon:FindChild("Item")
			local wndStoreLinkBtn = wndItemIcon:FindChild("StoreLinkBtn")
			wndStoreLinkBtn:SetData(tLink.nStoreLinkId)
			wndStoreLinkBtn:Show(true)

			if tLink.tAccountItem.item then
				wndItem:GetWindowSubclass():SetItem(tLink.tAccountItem.item)
				wndItem:SetTooltipForm(nil)
			elseif tLink.tAccountItem.monCurrency then
				local tDenomInfo = tLink.tAccountItem.monCurrency:GetDenomInfo()[1]
				if tDenomInfo then
					wndItem:SetSprite(tDenomInfo.strSprite)
					wndItem:SetTooltip(tDenomInfo.strName)
				end
			end
		end
	end
	local bHaveStoreItems = #wndStoreList:GetChildren() > 0
	if bHaveStoreItems then
		wndStoreList:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
	end

	--Hide Item Block and resize if the there are not rewards or store items
	wndItemsBlock:Show(bHaveRewards or bHaveStoreItems)

	local nTLeft, nTTop, nTRight, nTBottom = wndTitleBlock:GetOriginalLocation():GetOffsets()
	local nOLeft, nOTop, nORight, nOBottom = wndObjectives:GetOriginalLocation():GetOffsets()
	if not bHaveRewards and not bHaveStoreItems then
		local nHalfHeight = wndItemsBlock:GetHeight() / 2
		nTBottom = nTBottom + nHalfHeight + (self.knRightPadding / 2 )
		nOTop = nOTop - nHalfHeight - (self.knRightPadding / 2 )
	end
	wndTitleBlock:SetAnchorOffsets(nTLeft, nTTop, nTRight, nTBottom)
	wndObjectives:SetAnchorOffsets(nOLeft, nOTop, nORight, nOBottom)

	local tPublicEvent = tLiveEvent:GetActivePublicEvent()
	if tPublicEvent then
		--Build Objectives
		local tObjectives = tPublicEvent:GetObjectives()
		if tObjectives then
			local wndObjectiveContainer = wndObjectives:FindChild("ObjectiveContainer")
			wndObjectiveContainer:DestroyChildren()
			for idx, tObjectiveData in pairs(tObjectives) do
				if tObjectiveData:GetStatus() == PublicEventObjective.PublicEventStatus_Active and not tObjectiveData:IsHidden() then
					local wndQuestItem = Apollo.LoadForm(self.xmlDoc, "QuestItem", wndObjectiveContainer, self)
					local wndObjective = wndQuestItem:FindChild("Objective")
					wndObjective:SetAML(string.format("<P TextColor=\"UI_TextHoloBody\" Font=\"CRB_InterfaceMedium\">%s</P>", tObjectiveData:GetShortDescription()))
					local nWidth, nHeight = wndObjective:SetHeightToContentHeight()
					local nLeft, nTop, nRight, nBottom = wndQuestItem:GetAnchorOffsets()
					wndQuestItem:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + knObjectivePadding)
				end
			end
			wndObjectiveContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
			wndObjectiveContainer:SetVScrollPos(0)
		end
	end

	--Navpoint/Rapid Transport
	local tStartLocation = tLiveEvent:GetStartLocation()
	local wndbtnNavpoint = wndObjectives:FindChild("btnNavpoint")
	local wndbtnRapidTransport = wndObjectives:FindChild("btnRapidTransport")
	if tStartLocation ~= nil then
		wndbtnNavpoint:SetData(tStartLocation)
		wndbtnRapidTransport:SetData(tStartLocation)
	end
	wndbtnNavpoint:Enable(tStartLocation ~= nil)
	wndbtnRapidTransport:Enable(tStartLocation ~= nil)
	if tStartLocation ~= nil then
		wndbtnNavpoint:SetTooltip(Apollo.GetString("LiveEvents_DisabledNavPoint"))
		wndbtnRapidTransport:SetTooltip(Apollo.GetString("LiveEvents_DisabledRapidTransport"))
	else
		wndbtnNavpoint:SetTooltip("")
		wndbtnRapidTransport:SetTooltip("")
	end
	wndRight:SetVScrollPos(0)
end

--Responsible for Drawing both the overview section and the main section.
function LiveEvents:Redraw()
	--Overview Section
	self:RedrawOverViewSection()

	--Big Section
	self:RedrawMainSection()
end

function LiveEvents:DrawCommonSection(wndEvent)
	local tEventBtns = self.tEventBtns[self.nCurrEventIndex]
	if not tEventBtns then
		return
	end

	local tEventDetails = tEventBtns.wndSequenceBtn:GetData()
	local tEventData = tEventDetails.tEventData
	self.tCurrentEventShown = tEventData

	wndEvent:FindChild("BackgroundImage"):SetSprite(tEventData:GetBackgroundSprite())

	local wndEventContainer = wndEvent:FindChild("EventContainer")
	local wndDescription = wndEventContainer:FindChild("Description")
	wndDescription:SetAML("<P TextColor=\"UI_TextHoloBody\" Font=\"CRB_InterfaceMedium\">" .. tEventData:GetSummary() .. "</P>")
	wndDescription:SetHeightToContentHeight()
	wndEventContainer:FindChild("DescriptionContainer"):RecalculateContentExtents()
	wndEventContainer:FindChild("Title"):SetText(tEventData:GetName())
	wndEventContainer:FindChild("Icon"):SetSprite(tEventData:GetIcon())

	self:HelperDrawCashWindow(wndEvent)
end

function LiveEvents:HelperDrawCashWindow(wndEvent)
	if not self.tCurrentEventShown then
		return
	end

	local eCurrency = self.tCurrentEventShown:GetEarnedCurrencyType()
	local wndLiveEventCashWindow = wndEvent:FindChild("LiveEventCashWindow")
	local bHaveLiveEventCurrency = eCurrency ~= 0
	wndLiveEventCashWindow:Show(bHaveLiveEventCurrency)
	if bHaveLiveEventCurrency then
		local monPlayer = GameLib.GetPlayerCurrency(eCurrency)
		wndLiveEventCashWindow:SetMoneySystem(eCurrency)
		wndLiveEventCashWindow:SetAmount(monPlayer)
		wndLiveEventCashWindow:SetTooltip(Apollo.GetString(self.tCurrentEventShown:GetEarnedCurrencyTooltip()))
	end
end

function LiveEvents:OnBonusEventsChanged()
	if self.wndLiveEventsOverview and self.wndLiveEventsOverview:IsValid() and self.wndMain and self.wndMain:IsValid() then
		self:InitializeContent()
		self:RedrawOverViewSection()
	end
end

function LiveEvents:OnPlayerCurrencyChanged()
	if not self.tCurrentEventShown or self.tCurrentEventShown:GetEarnedCurrencyType() == 0 then
		return
	end

	if self.wndLiveEventsOverview:IsShown() then
		self:HelperDrawCashWindow(self.wndLiveEventsOverview)
	elseif self.wndMain:IsShown() then
		self:HelperDrawCashWindow(self.wndMain)
	end
end

function LiveEvents:OnEventDetailsBtn(wndHandler, wndControl)
	self.bTimerRunning = false
	self.timerRotation:Stop()
	Event_FireGenericEvent("WelcomeWindow_RequestTabChange", self.kstrTitle)
end

--When Selecting a sequence btn, you are on the Overview page, so only redraw overview section.
function LiveEvents:OnSequenceBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	if self.bTimerRunning then
		self.timerRotation:Set(self.knRotationTime, self.kbRotationContinous)
	end

	local tEventDetails = wndControl:GetData()
	if tEventDetails then
		self:HelperSelectEventBtns(tEventDetails)

		local wndEventContainer = self.wndLiveEventsOverview:FindChild("EventContainer")
		wndEventContainer:FindChild("EventDetailsBtn"):SetData(tEventDetails.tEventData)
	end

	self:RedrawOverViewSection()
end

--When Selecting an event btn, you are on the Main page, so only redraw Main section.
function LiveEvents:OnEventBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local tEventDetails = wndControl:GetData()
	if tEventDetails then
		self:HelperSelectEventBtns(tEventDetails)
	end

	self:RedrawMainSection()
end

function LiveEvents:HelperSelectEventBtns(tEventDetails)
	self.nCurrEventIndex = tEventDetails.nEventIndex

	local tEventBtns = self.tEventBtns[self.nCurrEventIndex]
	if tEventBtns and tEventBtns.wndSequenceBtn and tEventBtns.wndEventBtn then
		self.wndLiveEventsOverview:FindChild("SequenceBtnContainer"):SetRadioSelButton("LiveEventsSequenceBtn", tEventBtns.wndSequenceBtn)
		self.wndMain:FindChild("EventBtnContainer"):SetRadioSelButton("LiveEventsEventBtn", tEventBtns.wndEventBtn)
	end
end

function LiveEvents:HelperIncrementCurrentIndex()
	--Because LUA is 1 based, all results get + 1 to avoid an index of zero.
	self.nCurrEventIndex = (self.nCurrEventIndex % self.nNumEvents) + 1
end

function LiveEvents:HelperDecrementCurrentIndex()
	--[[Because LUA is 1 based, all results get + 1 to avoid an index of zero.
		This messes up modulo logic, so we have to accomedate for that face.
		Subtract 2 because: 1 for decrementing, 1 to accomedate for adding 1 at the end of every result.]]--
	self.nCurrEventIndex = ((self.nCurrEventIndex + self.nNumEvents - 2) % self.nNumEvents) + 1
end

function LiveEvents:OnDirectionalArrow(wndHandler, wndControl)
	local eDirection = wndHandler:GetData()
	if eDirection == self.keDirection.Next then
		self:HelperIncrementCurrentIndex()
	elseif eDirection == self.keDirection.Previous then
		self:HelperDecrementCurrentIndex()
	end

	local tEventBtns = self.tEventBtns[self.nCurrEventIndex]
	if tEventBtns then
		if self.bOverViewShowing and tEventBtns.wndSequenceBtn then
			self:OnSequenceBtn(tEventBtns.wndSequenceBtn, tEventBtns.wndSequenceBtn)
		elseif tEventBtns.wndEventBtn then
			self:OnEventBtn(tEventBtns.wndEventBtn, tEventBtns.wndEventBtn)
		end
	end
end

function LiveEvents:OnSetNavpointBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local tStartLocation = 	wndControl:GetData()
	if tStartLocation then
		GameLib.SetNavPoint(tStartLocation.tPosition, tStartLocation.nMapZoneId)
		Event_FireGenericEvent("ToggleZoneMap")--The public events have to be in the players current world, so just opening the zonemap will open on current world.
	end
end

function LiveEvents:OnOpenRapidTransport(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local tStartLocation = 	wndControl:GetData()
	if tStartLocation then
		Event_FireGenericEvent("ShowNearestRapidTransportNode", tStartLocation)--The public events have to be in the players current world, so just opening the zonemap will open on current world.
	end
end

function LiveEvents:OnStoreLinkBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local nStoreLinkId = wndControl:GetData()
	if nStoreLinkId ~= nil then
		StorefrontLib.OpenLink(nStoreLinkId)	
	end
end

function LiveEvents:OnTimerRotation()
	self:HelperIncrementCurrentIndex()
	local tEventBtns = self.tEventBtns[self.nCurrEventIndex]
	if tEventBtns and tEventBtns.wndSequenceBtn then
		self:OnSequenceBtn(tEventBtns.wndSequenceBtn, tEventBtns.wndSequenceBtn)
	end
end

function LiveEvents:OnGenerateItemTooltip(wndHandler, wndControl, eToolTipType, x, y)
	if wndHandler ~= wndControl then
		return
	end

	local itemReward = wndControl:GetData()
	if itemReward then--Some rewards don't have items
		local tPrimaryTooltipOpts =
		{
			bPrimary = true,
			itemCompare = itemReward:GetEquippedItemForItemType()
		}
		
		if Tooltip ~= nil and Tooltip.GetItemTooltipForm ~= nil then
			Tooltip.GetItemTooltipForm(self, wndControl, itemReward, tPrimaryTooltipOpts)
		end
	end
end

function LiveEvents:OnClose()
	self.wndMain:Close() 
	self.bTimerRunning = false
	self.timerRotation:Stop()
	self.tCurrentEventShown = nil
end


-----------------------------------------------------------------------------------------------
-- LiveEvents Instance
-----------------------------------------------------------------------------------------------
local LiveEventsInst = LiveEvents:new()
LiveEventsInst:Init()
