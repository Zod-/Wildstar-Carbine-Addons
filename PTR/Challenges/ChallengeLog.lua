-----------------------------------------------------------------------------------------------
-- Client Lua Script for ChallengeLog
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "ChallengesLib"
require "RewardTrackLib"
require "AccountItemLib"

local ChallengeLog = {}
local kIdAllZoneBtn = -1
local knProgressBarScale = 30
local keRewardTrack = 
{
	Bronze = 0,
	Silver = 1,
	Gold = 2,
}
function ChallengeLog:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.tFailMessagesList 		= {}
	o.nSelectedBigZone 		= nil
	o.wndShowAllBigZone 		= nil
	o.nSelectedListItem 		= nil

	o.wndMain = nil
	o.wndChallengeShare = nil
	o.nAlertCount = 0

    return o
end

function ChallengeLog:Init()
    Apollo.RegisterAddon(self)
end

-----------------------------------------------------------------------------------------------
-- ChallengeLog OnLoad
-----------------------------------------------------------------------------------------------

function ChallengeLog:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ChallengeLog.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function ChallengeLog:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 	"OnInterfaceMenuListHasLoaded", self)
	self:OnInterfaceMenuListHasLoaded()

	Apollo.RegisterEventHandler("PL_ToggleChallengesWindow", 	"ToggleWindow", self)
	Apollo.RegisterEventHandler("PL_TabChanged", 				"OnCloseChallengeLogTab", self)
	Apollo.RegisterEventHandler("CodexWindowHasBeenClosed", 	"OnCloseChallengeLogTab", self)
	
	Apollo.RegisterEventHandler("ChallengeShared", 				"OnChallengeShared", self)

	Apollo.RegisterEventHandler("RewardTrackUpdated",			"UpdateRewardTracker", self)
	Apollo.RegisterEventHandler("RewardTrackActive",			"UpdateRewardTracker", self)
	
	Apollo.RegisterEventHandler("PremiumTierChanged",			"OnPremiumTierChanged", self)
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate",	"UpdateSignatureControls", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate",		"UpdateSignatureControls", self)

	Apollo.RegisterEventHandler("StoreLinksRefresh",			"RefreshStoreLink", self)

	self.tTimerAreaRestriction =
	{
		[ChallengesLib.ChallengeType_Combat] 				= ApolloTimer.Create(1.0, false, "OnAreaRestrictionTimer", self),
		[ChallengesLib.ChallengeType_Ability] 				= ApolloTimer.Create(1.0, false, "OnAreaRestrictionTimer", self),
		[ChallengesLib.ChallengeType_General] 				= ApolloTimer.Create(1.0, false, "OnAreaRestrictionTimer", self),
		[ChallengesLib.ChallengeType_Item] 					= ApolloTimer.Create(1.0, false, "OnAreaRestrictionTimer", self),
		[ChallengesLib.ChallengeType_ChecklistActivate] 	= ApolloTimer.Create(1.0, false, "OnAreaRestrictionTimer", self)
	}

	for idx, timerCur in pairs(self.tTimerAreaRestriction) do
		timerCur:Stop()
	end

	--Check to update the timer string less than half the interval of rate of change for the timer (1 second), so we don't miss an update and strings get far out of sync.
	self.timerChallengeLogUpdateInfo = ApolloTimer.Create(1.0, true, "OnUpdateChallengeTimeString", self)
	self.timerChallengeLogUpdateInfo:Stop()
	
	--Timer to check and see if the player is at the start selection for the currently selected challenge.
	self.timerPlayerAtStartLocationCheck = ApolloTimer.Create(1.0, true, "OnTimerPlayerAtStartLocationCheck", self)
	self.timerPlayerAtStartLocationCheck:Stop()

	local wndOriginalListItem = Apollo.LoadForm(self.xmlDoc, "ListItem", nil, self)
	local wndOriginalListItemBtn = wndOriginalListItem:FindChild("ListItemBtn")
	local wndOriginalListItemDescription = wndOriginalListItem:FindChild("ListItemDescription")
	self.knListItemDescriptionOriginalHeight = wndOriginalListItemDescription:GetHeight()
	self.knListItemDescriptionOriginalHeightPadding = wndOriginalListItem:GetHeight() - wndOriginalListItemBtn:GetHeight()
	wndOriginalListItem:Destroy()
	
	local wndTEMP2 = Apollo.LoadForm(self.xmlDoc, "HeaderItem", nil, self)
	local nLeft, nTop, nRight, nBottom = wndTEMP2:GetAnchorOffsets()
    local nLeft2, nTop2, nRight2, nBottom2 = wndTEMP2:FindChild("HeaderContainer"):GetAnchorOffsets()

	self.knHeaderTopHeight = nBottom - nTop - (nBottom2 - nTop2) - 20
	wndTEMP2:Destroy()
end

function ChallengeLog:OnInterfaceMenuListHasLoaded()
	local tData = { "ToggleChallengesWindow", "Challenges", "Icon_Windows32_UI_CRB_InterfaceMenu_ChallengeLog" }
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_ChallengeLog"), tData)
	
	self:UpdateInterfaceMenuAlerts()
end

function ChallengeLog:UpdateInterfaceMenuAlerts()
	local tActiveClgRewardTracks = RewardTrackLib.GetActiveRewardTracks()
	if tActiveClgRewardTracks then
		for idx, rtRewardTrack in pairs(tActiveClgRewardTracks) do
			if rtRewardTrack:GetType() == RewardTrackLib.CodeEnumRewardTrackType.Challenge then
				for idx, tReward in pairs(rtRewardTrack:GetAllRewards()) do
					if  tReward.bCanClaim and not tReward.bIsClaimed then
						self.nAlertCount = self.nAlertCount + 1
					end
				end
			end
		end
	end
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", Apollo.GetString("InterfaceMenu_ChallengeLog"), {self.nAlertCount ~= 0, "", self.nAlertCount})
end

function ChallengeLog:HelperHandleLocationTimer()
	if not self.timerPlayerAtStartLocationCheck then
		return
	end
	--Don't need to check if player is at location because the Challenge Log isn't shown or player doesn't have a challenge selected.
	 if not self.wndMain or not self.wndMain:IsShown() or not self.nSelectedListItem or not self.nSelectedListItem or not self.tCurrentlyDisplayedChallenges then
		self.timerPlayerAtStartLocationCheck:Stop()
		return
	end

	local clgCurrent = self.tCurrentlyDisplayedChallenges[self.nSelectedListItem]
	if clgCurrent then --if the currently selected challenge needs to update its controls, allow it
		local bIsStartable = not clgCurrent:IsActivated() and not clgCurrent:IsInCooldown() and self:IsStartable(clgCurrent)
		local bIsInZone = self:HelperIsInZone(clgCurrent:GetZoneRestrictionInfo())
		
		if not bIsInZone or not bIsStartable then
			self.timerPlayerAtStartLocationCheck:Stop()
		else
			self.timerPlayerAtStartLocationCheck:Start()
		end
	end
end

function ChallengeLog:ToggleWindow(clgDetails)--Optional clgDetails coming from Objective tracker details.
	if not self.wndMain then
		self:Initialize()
	end

	local wndCurZoneBtn = self.wndShowAllBigZone:FindChild("BigZoneBtn")
	local nCurrentZoneId = GameLib.GetCurrentZoneId()
	if nCurrentZoneId ~= nil then
		local tChildren = self.wndMain:FindChild("LeftSide:BigZoneListContainer"):GetChildren()
		for idx, wndZoneItem in pairs(tChildren) do
			local wndBtn = wndZoneItem:FindChild("BigZoneBtn")
			local nBthZoneId = wndBtn:GetData()
			if nBthZoneId == nCurrentZoneId or GameLib.IsZoneInZone(nCurrentZoneId, nBthZoneId) then
				wndCurZoneBtn = wndBtn
				break
			end
		end
	end

	wndCurZoneBtn:SetCheck(true)
	self:OnBigZoneBtnPress(wndCurZoneBtn, wndCurZoneBtn)
	
	--In case challenges have updated or been aquired while window was not shown.
	self.wndMain:Show(true)
	self:Redraw()
	self.timerChallengeLogUpdateInfo:Start()
	
	--Should Deselect if there is already a previously selected List ItemList.
	if self.nSelectedListItem then
		self:HelperDeselectCurrentListItem()
	end
	--If we got a challenge, should Select the challenge that was passed in through toggle.
	if clgDetails then
		self:HelperSelectDetailChallenge(clgDetails)
	end
	
	--Want to immediately update challenge controls when toggled if a challenge is selected.
	if self.nSelectedListItem and self.tCurrentlyDisplayedChallenges then
		local clgCurrent = self.tCurrentlyDisplayedChallenges[self.nSelectedListItem]
		if clgCurrent then --if the currently selected challenge needs to update its controls, allow it
			self:HelperUpdateControlsForChallenge(clgCurrent)
		end
	end

	self:HelperHandleLocationTimer()
end

function ChallengeLog:HelperDeselectCurrentListItem()
	if not self.wndMain then
		return
	end

	local tListItemInfo = self:HelperGetChallengeListItemInfoById(self.nSelectedListItem)
	if tListItemInfo and tListItemInfo.wndChallengeListItem then
		self.nSelectedListItem = nil
		tListItemInfo.wndChallengeListItem:FindChild("ListItemBtn"):SetCheck(false)
	end
end

function ChallengeLog:HelperSelectDetailChallenge(clgDetails)
	if not self.wndMain then
		return
	end

	--Select the right BigZoneBtn.
	local tZoneInfo = clgDetails:GetZoneInfo()
	local wndBigZone = self.wndMain:FindChild("LeftSide:BigZoneListContainer"):FindChildByUserData(tZoneInfo.idZone)
	if wndBigZone then
		self:OnBigZoneBtnPress(wndBigZone:FindChild("BigZoneBtn"), wndBigZone:FindChild("BigZoneBtn"))
	end

	--Select this challenges List Item and set scroll to view it.
	local idSelected= clgDetails:GetId()
	local tListItemInfo = self:HelperGetChallengeListItemInfoById(idSelected)
	if tListItemInfo and tListItemInfo.wndChallengeListItem then
		self.nSelectedListItem = idSelected
		tListItemInfo.wndChallengeListItem:FindChild("ListItemBtn"):SetCheck(true)
		self.wndTopLevel:SetVScrollPos(tListItemInfo.nPos or 0)
	end
end

function ChallengeLog:Initialize()
	Apollo.RegisterEventHandler("ChallengeCompleted", 		"OnChallengeCompleted", self)
	Apollo.RegisterEventHandler("ChallengeFailArea", 			"OnChallengeFail", self)
    Apollo.RegisterEventHandler("ChallengeFailTime", 			"OnChallengeFail", self)
	Apollo.RegisterEventHandler("ChallengeActivate", 			"OnChallengeActivate", self) -- This fires every time a challenge starts
	Apollo.RegisterEventHandler("ChallengeUpdated",			"OnChallengeUpdated", self)
	Apollo.RegisterEventHandler("ChallengeAreaRestriction", 	"OnChallengeAreaRestriction", self)
	Apollo.RegisterEventHandler("ChallengeUnlocked", 			"OnChallengeUnlocked", self)

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "ChallengeLogForm", g_wndProgressLog:FindChild("ContentWnd_3"), self)
    self.wndTopLevel = self.wndMain:FindChild("RightSide:ChallengeControls:ItemList")

	self.wndMain:FindChild("SortByDropdownBtn"):AttachWindow(self.wndMain:FindChild("SortByDropdownContainer"))

	local wndTopHeader = self.wndMain:FindChild("TopHeader")
	local wndSortByDropdownContainer = self.wndMain:FindChild("SortByDropdownContainer")

    wndSortByDropdownContainer:FindChild("btnToggleType"):SetCheck(true)
    wndTopHeader:FindChild("ToggleShowAllBtn"):SetCheck(true)

	local wndEditBox = wndTopHeader:FindChild("HeaderSearchBox")
    wndTopHeader:FindChild("ClearSearchBtn"):Show(wndEditBox:GetText() ~="")
	
	--Creating references to challenge control buttons so the timer calls for seeing if player is in challenge start location are not expensive.
	local wndInteractArea = self.wndMain:FindChild("RightSide:BGRightFooter:InteractArea")
	self.wndStartChallengeBtn = wndInteractArea:FindChild("StartChallengeBtn")
	self.wndAbandonChallengeBtn = wndInteractArea:FindChild("AbandonChallengeBtn")
	self.wndLocateChallengeBtn = wndInteractArea:FindChild("LocateChallengeBtn")

	self:HelperResetWarningTextsAndChallengeButtonControls()
	self:AddShowAllToBigZoneList()

	--Want to recognize which challenges are already activated and running.
	self.tChallengesToUpdate = {}
	self.tChallengesByZoneId = {}
	self.tCurrentlyDisplayedChallenges = ChallengesLib.GetActiveChallengeList() or {}
	for idx, clgCurrent in pairs(self.tCurrentlyDisplayedChallenges) do
		local idChallenge = clgCurrent:GetId()
		if clgCurrent:IsActivated() or clgCurrent:IsInCooldown() then
			self.tChallengesToUpdate[idChallenge] = clgCurrent
		end

		--Want to create a table representing zoneId to a list of challenges in that zone [zoneId -> [challenges]]
		self:HelperAddToChallengesByZoneId(clgCurrent)
	end

	self.wndRewardList = self.wndMain:FindChild("RewardList")
	self.wndRewardListOpenBtn = self.wndMain:FindChild("RewardListOpenBtn")
	self.wndRewardListCloseBtn = self.wndMain:FindChild("RewardListCloseBtn")
	
	self:RefreshStoreLink()
	self:Redraw()
end

function ChallengeLog:HelperAddToChallengesByZoneId(clgAdd)
	local tZoneInfo = clgAdd:GetZoneInfo()
	if tZoneInfo then
		if not self.tChallengesByZoneId[tZoneInfo.idZone] then--new zone to add to the table!
			self.tChallengesByZoneId[tZoneInfo.idZone] = {}--New table for this zones id.
		end

		local tCurrZoneEntry = self.tChallengesByZoneId[tZoneInfo.idZone]
		tCurrZoneEntry[clgAdd:GetId()] = clgAdd --Adding this challenges by the challenge id to this new table.
		self:HandleBigZoneList(tZoneInfo)--Making sure that there is a BigZoneBtn for this zone. If there is already, this function will not create another.
	end
end

function ChallengeLog:OnCloseChallengeLogTab()
	if self.wndMain then
		self.wndMain:Show(false)
	end
	self.timerChallengeLogUpdateInfo:Stop()
	self.timerPlayerAtStartLocationCheck:Stop()
end

function ChallengeLog:HelperGetCurrentChallengesForZone()
	local tZoneChallenges = {}
	if self.nSelectedBigZone == kIdAllZoneBtn then --give back all challenges for all zones
		tZoneChallenges = ChallengesLib.GetActiveChallengeList()
	else--give back challenges for currently selected zone
		tZoneChallenges = self.tChallengesByZoneId[self.nSelectedBigZone]
	end

	return tZoneChallenges
end

function ChallengeLog:OnEditBoxChanged(wndHandler, wndControl, strText)
	if wndHandler ~= wndControl then
		return
	end

	local wndTopHeader = self.wndMain:FindChild("TopHeader")
	if not wndTopHeader then
		return
	end

	local tChallengesByZoneId = self:HelperGetCurrentChallengesForZone()
	local tFilteredChallengesByName = {}

	local strSearchString = strText:lower()
	wndTopHeader:FindChild("ClearSearchBtn"):Show(strSearchString ~= "")

	if strSearchString ~= "" then
		for idx, clgCurrent in pairs(tChallengesByZoneId) do
			local strChallengeName = clgCurrent:GetName():lower()
			if strChallengeName:find(" "..strSearchString, 1, true) or string.sub(strChallengeName, 0, Apollo.StringLength(strSearchString)) == strSearchString then --Possibly clean up
				tFilteredChallengesByName[idx] = clgCurrent
			end
        end
		self.tCurrentlyDisplayedChallenges = tFilteredChallengesByName
	else
		--No string to filter challenges for, allow all results to possibly be shown. Redraw will filter based on zone and toggle button.
		self.tCurrentlyDisplayedChallenges = tChallengesByZoneId
	end

	--removes link to the last checked challenge
	self:DestroyHeaderWindows()
	self:Redraw()
end

--Just Updating the challenges whose string need changing.
function ChallengeLog:OnUpdateChallengeTimeString()
	--find the challenges to update
	for idChallenge, clgCurrent in pairs(self.tChallengesToUpdate) do
		self:RedrawChallengeListItemsString(clgCurrent, idChallenge)
	end
end

function ChallengeLog:OnTimerPlayerAtStartLocationCheck()
	if not self.nSelectedListItem or not self.tCurrentlyDisplayedChallenges then
		return
	end

	local clgCurrent = self.tCurrentlyDisplayedChallenges[self.nSelectedListItem]
	if clgCurrent then --if the currently selected challenge needs to update its controls, allow it
		self:HelperUpdateControlsForChallenge(clgCurrent)
	end
end


-----------------------------------------------------------------------------------------------
-- ChallengeLog Main Redraw Method
-----------------------------------------------------------------------------------------------
function ChallengeLog:RedrawChallengeListItem(idChallenge)
	if not idChallenge then
		return
	end

	local tListItemInfo = self:HelperGetChallengeListItemInfoById(idChallenge)
	if tListItemInfo and tListItemInfo.wndChallengeListItem then
		if not self:HelperShouldListItemBeDestroyed(tListItemInfo.wndChallengeListItem:GetData()) then
			self:DrawPanelContents(tListItemInfo.wndChallengeListItem)
		else--This item should no longer be shown in this tab. Redraw because if it was removed, the ShowAllChallenges button maybe needed to be shown.
			self:Redraw()
		end
		
		--Want to arrange the challenges in this challenges header so no overlap.
		local wndCurrHeader = tListItemInfo.wndChallengeListItem:GetParent()
		if wndCurrHeader and wndCurrHeader:IsValid() then
			wndCurrHeader:FindChild("HeaderContainer"):ArrangeChildrenVert()
		end
	end
end

function ChallengeLog:HelperShouldListItemBeDestroyed(clgBeingDrawn)
	if not clgBeingDrawn then
		return
	end 

	--If showing rewards but this challenge doesn't have a reward, or showing cooldown but this challenge isnt't in cooldown,
	--or showing the challenges that are ready but this one is in cooldown.
	if  self.wndMain:FindChild("ToggleCooldownBtn"):IsChecked() 	and not clgBeingDrawn:IsInCooldown() 				or
		self.wndMain:FindChild("ToggleReadyBtn"):IsChecked() 		and  	 clgBeingDrawn:IsInCooldown()				then
		return true
	end
	return false
end

function ChallengeLog:RedrawChallengeListItemsString(clgUpdate, idChallenge)
	if not clgUpdate or not idChallenge then
		return
	end

	local tListItemInfo = self:HelperGetChallengeListItemInfoById(idChallenge)
	if tListItemInfo and tListItemInfo.wndChallengeListItem then
		local wndListItemTimerText= tListItemInfo.wndChallengeListItem:FindChild("ListItemTimerText")
		if wndListItemTimerText then
			local strConvertedTime = self:HelperConvertToTime(clgUpdate:GetTimer())
			wndListItemTimerText:SetText(strConvertedTime)
			
			--This challenge that was updating its string doesn't need to be updated any more if string is empty, so remove from table.
			--Currently there is no event stating when a challenge that was on cool down has gone off.
			--When the "time" string is returned as empty, it may mean the the challenge has gone off cool down.
			--In that case, start timer to updated controls for that challenge.
			if strConvertedTime == "" then
				self.tChallengesToUpdate[idChallenge] = nil
				self:HelperHandleLocationTimer()
			end
		end
	end
end

function ChallengeLog:HelperGetChallengeListItemInfoById(idChallenge)
	--Looking through the headers children. They will contain the currently selected zone's challenges. Find the list item for this idChallenge
	
	local tListItemInfo = {
		wndChallengeListItem = nil,
		nPos = nil,
	}

	local nPos = 0
	for idx, wndCurrHeader in pairs(self.wndTopLevel:GetChildren()) do
		local wndChallengeListItem = wndCurrHeader:FindChild("HeaderContainer"):FindChild(idChallenge)--the listitem for the challenge
		if wndChallengeListItem then --found list item for challenge
			tListItemInfo.wndChallengeListItem = wndChallengeListItem
			--Found the listItem, want to know how far in the container it is.
			tListItemInfo.nPos = nPos + self:HelperGetListItemDistanceInHeaderContainer(wndCurrHeader, wndChallengeListItem)
			break
		end
		nPos = nPos + wndCurrHeader:GetHeight()
	end
	return tListItemInfo
end

function ChallengeLog:HelperGetListItemDistanceInHeaderContainer(wndHeader, wndChallengeListItem)
	if not wndHeader or not wndChallengeListItem then
		return
	end

	local nPos = 0
	for idx, wndListItem in pairs(wndHeader:FindChild("HeaderContainer"):GetChildren()) do
		if wndListItem == wndChallengeListItem then
			return nPos
		end
		nPos = nPos + wndListItem:GetHeight()
	end
	return 0
end

--Filters based on Top header options, and zone
function ChallengeLog:HelperGetFilteredChallenges()
	-- Build Challenge List filtered by active vs cooldown vs completed
	local tFilteredChallenges = {}

	local wndTopHeader = self.wndMain:FindChild("TopHeader")
	local bShowAll = wndTopHeader:FindChild("ToggleShowAllBtn"):IsChecked()
	local bShowCooldown = wndTopHeader:FindChild("ToggleCooldownBtn"):IsChecked()
	local bShowReady = wndTopHeader:FindChild("ToggleReadyBtn"):IsChecked()


	--By this point, self.tCurrentlyDisplayedChallenges will be the appropriate challenges by zone and search string if any
	for idx, clgCurrent in pairs(self.tCurrentlyDisplayedChallenges) do
		local tZoneInfo = clgCurrent:GetZoneInfo()
		if bShowAll or bShowCooldown and clgCurrent:IsInCooldown()  then
				tFilteredChallenges[idx] = clgCurrent

		elseif bShowReady and not clgCurrent:IsInCooldown() then
			-- Show activated or challenges with rewards or show challenges that can be started. Filter out challenges that are on cooldown
			if  clgCurrent:IsActivated() or self:IsStartable(clgCurrent) and self:HelperIsInZone(clgCurrent:GetZoneRestrictionInfo()) then
				tFilteredChallenges[idx] = clgCurrent
			end
		end
		self:HandleBigZoneList(tZoneInfo)
	end

	return tFilteredChallenges
end


-- Clicking a Header button and the timer also routes here
function ChallengeLog:Redraw()
    if not self.wndMain:IsShown() then
		return
	end

	local tFilteredChallenges = self:HelperGetFilteredChallenges()
	self:DrawLeftPanelUI(self.tCurrentlyDisplayedChallenges)
	self:DrawRightPanelUI(tFilteredChallenges)

	--Draw RewardTacker
	self:UpdateRewardTracker()
	
	-- Just exit if we have 0 challenges, we've already drawn the empty messages
    if not tFilteredChallenges or self:GetTableSize(tFilteredChallenges) == 0 then
		self:DestroyHeaderWindows()
	else
		self:BuildChallengeList(tFilteredChallenges)
	end
end

-----------------------------------------------------------------------------------------------------------
--Reward Tracker Functions
-----------------------------------------------------------------------------------------------------------


function ChallengeLog:UpdateRewardTracker()
	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	self:HideRewardList()

	local wndRewardTracker = self.wndMain:FindChild("RewardTracker")
	local wndChallengControls = self.wndMain:FindChild("ChallengeControls")

	local arRewards = self.rtRewardTrack and self.rtRewardTrack:GetAllRewards()
	local bShowRewardTracker = arRewards ~= nil
	if bShowRewardTracker then
		local wndContainer = wndRewardTracker:FindChild("Container")
		wndContainer:DestroyChildren()
		for idx, tReward in pairs(arRewards) do
			if idx ~= #arRewards then
				local wndRewardPoint = Apollo.LoadForm(self.xmlDoc, "RewardPoint", wndContainer, self)
				self:DrawRewardPoint(wndRewardPoint, arRewards, tReward, true)
			else
				self:DrawRewardPoint(wndRewardTracker:FindChild("FinalRewardPoint"), arRewards, tReward, false)
			end
		end
		
		local nRewardProgress = self.rtRewardTrack:GetRewardPointsEarned()
		if nRewardProgress == nil then
			nRewardProgress = 0
		end
		local nRewardMax = arRewards[#arRewards].nCost
		local wndRewardTrackTitleContainer = wndRewardTracker:FindChild("RewardTrackTitleContainer")
		local wndRewardTrackTitle = wndRewardTrackTitleContainer:FindChild("RewardTrackTitle")
		local strTitle = string.format('<P Font="CRB_HeaderTiny" ><T TextColor="UI_TextMetalBodyHighlight">%s </T><T TextColor="UI_TextMetalGoldHighlight">%s</T></P>', self.rtRewardTrack:GetName(), String_GetWeaselString(Apollo.GetString("ChallengeLog_PointsReadout"), nRewardProgress))

		wndRewardTrackTitle:SetAML(strTitle)
		
		local nWidth, nHeight = wndRewardTrackTitle:SetHeightToContentHeight()
		local nLeft, nTop, nRight, nBottom = wndRewardTrackTitleContainer:GetAnchorOffsets()
		local nHeightDifference = wndRewardTrackTitleContainer:GetHeight() - nHeight
		wndRewardTrackTitleContainer:SetAnchorOffsets(nLeft, nTop + nHeightDifference / 2, nRight, nBottom - nHeightDifference / 2)

		local wndRewardProgressBar = wndRewardTracker:FindChild("ProgressBar")
		wndRewardProgressBar:SetMax(nRewardMax)
		wndRewardProgressBar:SetProgress(nRewardProgress, wndRewardProgressBar:GetHeight() * knProgressBarScale)
		wndRewardProgressBar:SetData(nRewardProgress)
		wndRewardProgressBar:SetTooltip(String_GetWeaselString(Apollo.GetString("Contracts_RewardBarProgressTooltip"), nRewardProgress, Apollo.FormatNumber(nRewardMax)))
	
		local wndRewardListContainer = wndRewardTracker:FindChild("RewardList:Container")
		local nScrollPos = wndRewardListContainer:GetVScrollPos()
		wndRewardListContainer:DestroyChildren()
		for idx, tReward in pairs(arRewards) do
			local wndEntry = Apollo.LoadForm(self.xmlDoc, "RewardListEntry", wndRewardListContainer, self)
			self:DrawRewardListEntry(wndEntry, tReward)
		end

		wndRewardListContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		wndRewardListContainer:SetVScrollPos(nScrollPos)
	end
	
	wndRewardTracker:Show(bShowRewardTracker)
	self.wndMain:FindChild("GradientShadow"):Show(bShowRewardTracker)

	local nLeft, nTop, nRight, nBottom = wndChallengControls:GetAnchorOffsets()
	wndChallengControls:SetAnchorOffsets(nLeft, bShowRewardTracker and wndRewardTracker:GetHeight() or 0, nRight, nBottom)	
end

function ChallengeLog:DrawRewardPoint(wndRewardPoint, arRewards, tReward, bMoveIntoPlace)
	local nRewardMax = arRewards[#arRewards].nCost
	local wndContainer = self.wndMain:FindChild("Container")
	
	if bMoveIntoPlace then
		local nLeftSection = wndContainer:GetWidth() * (tReward.nCost / nRewardMax)
		local nWidth = wndRewardPoint:GetWidth()
		
		local wndHalfTrackerHeight = wndContainer:GetHeight() / 2.0
		local nHalfPointHeight = wndRewardPoint:GetHeight() / 2.0
		
		
		local nLeft, nTop, nRight, nBottom = wndRewardPoint:GetAnchorOffsets()
		wndRewardPoint:SetAnchorOffsets(nLeftSection - nWidth / 2, wndHalfTrackerHeight - nHalfPointHeight, nLeftSection + nWidth / 2, wndHalfTrackerHeight + nHalfPointHeight)
	end

	local strRewardLabel = nil
	local strHeader = nil
	local strClickAction = nil
	local crRewardLabel = nil
	local nDisplayRewardIdx = tReward.nRewardIdx + 1

	local wndTooltip = wndRewardPoint:FindChild("RewardPointTooltip")
	local wndClickAction = wndTooltip:FindChild("ClickAction")
	local wndRewardLabel = wndTooltip:FindChild("RewardLabel")
	local wndItemHeader = wndTooltip:FindChild("ItemHeader")
	local wndActionBtn = wndRewardPoint:FindChild("ActionBtn")
	local wndAchievedBG = wndRewardPoint:FindChild("AchievedBG")
	local wndHighlightBG = wndRewardPoint:FindChild("HighlightBG")

	if tReward.bIsClaimed then
		strClickAction = Apollo.GetString("Contracts_ClickToExpand")
		strRewardLabel = String_GetWeaselString(Apollo.GetString("Contracts_RewardAlreadyClaimed"), nDisplayRewardIdx)
		crRewardLabel = ApolloColor.new("UI_TextHoloBody")
		strHeader = Apollo.GetString("Contracts_RewardChosenFrom")
		wndAchievedBG:Show(true)

	elseif tReward.bCanClaim then
		strClickAction = Apollo.GetString("Contracts_ClickToChooseReward")
		strRewardLabel = String_GetWeaselString(Apollo.GetString("Contracts_RewardsReadyToClaim"), nDisplayRewardIdx)
		crRewardLabel = ApolloColor.new("UI_BtnTextGreenNormal")
		strHeader = Apollo.GetString("Contracts_RewardChoices")

	else
		strClickAction = Apollo.GetString("Contracts_ClickForDetails")
		local nPointsRequired = self.rtRewardTrack:GetRewardPointsEarned()
		if nPointsRequired == nil then
			nPointsRequired = 0
		else
			nPointsRequired = tReward.nCost - nPointsRequired
		end
		strRewardLabel = String_GetWeaselString(Apollo.GetString("Contracts_RewardRequiresMorePoints"), nDisplayRewardIdx, Apollo.FormatNumber(nPointsRequired))
		crRewardLabel = ApolloColor.new("white")
		strHeader = Apollo.GetString("Contracts_RewardChoices")
	end

	wndClickAction:SetText(strClickAction)
	wndRewardLabel:SetText(strRewardLabel)
	wndRewardLabel:SetTextColor(crRewardLabel)
	wndItemHeader:SetText(strHeader)

	-- tooltip Cash
	wndTooltip:FindChild("CashReward"):Show(tReward.monReward and tReward.monReward:GetAmount() > 0 or false)
	wndTooltip:FindChild("CashReward"):SetAmount(tReward.monReward, true)
	
	-- Tooltip items
	local wndItemContainer = wndTooltip:FindChild("ItemRewards")
	wndItemContainer:DestroyChildren()
	for idx, tItemChoice in pairs(tReward.tRewardChoices or {}) do
		if tItemChoice.eRewardType == RewardTrack.RewardTrackRewardType.Item then
			local wndItem = Apollo.LoadForm(self.xmlDoc, "RewardPointTooltipItem", wndItemContainer, self)
			
			wndItem:FindChild("ItemCantUse"):Show(tItemChoice.itemReward:IsEquippable() and not tItemChoice.itemReward:CanEquip())
			wndItem:FindChild("ItemIcon"):GetWindowSubclass():SetItem(tItemChoice.itemReward)
		end
	end
	wndItemContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	wndActionBtn:SetData({ ["tReward"] = tReward, ["wndTooltip"] = wndTooltip })
end

function ChallengeLog:DrawRewardListEntry(wndEntry, tReward)
	local nDisplayRewardIdx = tReward.nRewardIdx + 1
	wndEntry:SetData({ ["tReward"] = tReward})
	
	local wndEntryContainer = wndEntry:FindChild("Container")
	local wndRewardListClaimBtn = wndEntryContainer:FindChild("RewardListClaimBtn")
	wndRewardListClaimBtn:SetData({ ["tReward"] = tReward})
	
	wndRewardListClaimBtn:Show(tReward.bCanClaim and not tReward.bIsClaimed)
	wndRewardListClaimBtn:Enable(tReward.tRewardChoices and #tReward.tRewardChoices == 0 or false)
	
	local strRewardLabel = nil
	local crRewardLabel = nil
	local strHeader = nil

	local wndRewardLabel = wndEntryContainer:FindChild("RewardLabel")
	local wndItemHeader = wndEntryContainer:FindChild("ItemHeader")
	
	if tReward.bIsClaimed then
		strRewardLabel = String_GetWeaselString(Apollo.GetString("Contracts_RewardAlreadyClaimed"), nDisplayRewardIdx)
		strHeader = Apollo.GetString("Contracts_RewardChosenFrom")
		crRewardLabel = ApolloColor.new("UI_TextHoloBody")
	elseif tReward.bCanClaim then
		strRewardLabel = String_GetWeaselString(Apollo.GetString("Contracts_RewardsReadyToClaim"), nDisplayRewardIdx)
		strHeader = Apollo.GetString("Contracts_PleaseChooseReward")
		crRewardLabel = ApolloColor.new("UI_BtnTextGreenNormal")
	else
		local nPointsRequired = self.rtRewardTrack:GetRewardPointsEarned()
		if nPointsRequired == nil then
			nPointsRequired = 0
		else
			nPointsRequired = tReward.nCost - nPointsRequired
		end
		strRewardLabel = String_GetWeaselString(Apollo.GetString("Contracts_RewardRequiresMorePoints"), nDisplayRewardIdx, Apollo.FormatNumber(nPointsRequired))
		strHeader = Apollo.GetString("Contracts_RewardChoices")
		crRewardLabel = ApolloColor.new("white")
	end
	
	wndRewardLabel:SetText(strRewardLabel)
	wndRewardLabel:SetTextColor(crRewardLabel)
	wndItemHeader:SetText(strHeader)
	
	-- Cash
	wndEntryContainer:FindChild("CashReward"):Show(tReward.monReward:GetAmount() > 0)
	wndEntryContainer:FindChild("CashReward"):SetAmount(tReward.monReward, true)
	
	-- Items
	local wndItemRewardContainer = wndEntryContainer:FindChild("ItemRewardContainer")
	local wndItemContainer = wndItemRewardContainer:FindChild("ItemRewards")
	wndItemContainer:DestroyChildren()
	for idx, tItemChoice in pairs(tReward.tRewardChoices or {}) do
		if tItemChoice.eRewardType == RewardTrack.RewardTrackRewardType.Item then
			local wndItem = Apollo.LoadForm(self.xmlDoc, "RewardSelectionItem", wndItemContainer, self)
			
			wndItem:FindChild("ItemCantUse"):Show(tItemChoice.itemReward:IsEquippable() and not tItemChoice.itemReward:CanEquip())
			local wndItemIcon = wndItem:FindChild("ItemIcon")
			wndItemIcon:GetWindowSubclass():SetItem(tItemChoice.itemReward)
			wndItemIcon:AddEventHandler("GenerateTooltip", "OnGenerateRewardItemTooltip")
			wndItemIcon:SetData(tItemChoice)
			local wndSelectionBtn = wndItem:FindChild("SelectionBtn")
			wndSelectionBtn:SetData({ ["tItemChoice"] = tItemChoice, ["wndRewardListClaimBtn"] = wndRewardListClaimBtn })
			wndSelectionBtn:Enable(tReward.bCanClaim and not tReward.bIsClaimed)
			wndItem:FindChild("ItemStackCount"):SetText(tItemChoice.nRewardCount)
		end
	end
	wndItemContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
	wndItemRewardContainer:Show(tReward.tRewardChoices and #tReward.tRewardChoices > 0 or false)
	
	local nHeight = wndEntryContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nLeft, nTop, nRight, nBottom = wndEntry:GetAnchorOffsets()
	wndEntry:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
end

function ChallengeLog:OnRewardPointMouseEnter(wndHandler, wndControl, x, y)
	if wndHandler ~= wndControl then
		return
	end

	wndControl:GetParent():FindChild("RewardPointTooltip"):Show(not self.wndRewardList:IsShown())
end

function ChallengeLog:OnRewardPointMouseExit(wndHandler, wndControl, x, y)
	if wndHandler ~= wndControl then
		return
	end

	wndControl:GetParent():FindChild("RewardPointTooltip"):Show(false)
end

function ChallengeLog:ShowRewardList()
	if not self.wndRewardList:IsShown() then
		self.wndRewardList:Show(true)
		self.wndRewardListOpenBtn:SetCheck(true)
		Sound.Play(Sound.PlayUIButtonMetalLarge)
	end

end

function ChallengeLog:HideRewardList()
	if self.wndRewardList:IsShown() then
		self.wndRewardList:Show(false)
		self.wndRewardListOpenBtn:SetCheck(false)
		Sound.Play(Sound.PlayUIButtonMetalLarge)
	end
end

function ChallengeLog:OnRewardPointBtnSignal(wndHandler, wndControl)
	self:ShowRewardList()
	local tData = wndControl:GetData()
	tData.wndTooltip:Show(false)
	Sound.Play(Sound.PlayUIButtonHoloSmall)
	local wndContainer = self.wndRewardList:FindChild("Container")
	for idx, wndRewardEntry in pairs(wndContainer:GetChildren()) do
		if tData.tReward.idReward == wndRewardEntry:GetData().tReward.idReward then
			wndRewardEntry:FindChild("SelectedHighlight"):Show(true)
			wndRewardEntry:FindChild("Flasher"):SetSprite("BK3:UI_BK3_Holo_RefreshReflectionSquare_anim")
			wndContainer:EnsureChildVisible(wndRewardEntry)
		else
			wndRewardEntry:FindChild("SelectedHighlight"):Show(false)
		end
	end
end

function ChallengeLog:HelperGetListOfLists(tFilteredChallenges)
	local tChallengeListOfList = nil
	local wndSortByDropdownContainer = self.wndMain:FindChild("RightSide:Reward:Tracker:ChallengeControls:SortByDropdownContainer")
	if wndSortByDropdownContainer:FindChild("btnToggleZone"):IsChecked() then
		tChallengeListOfList = self:SetUpZoneList(tFilteredChallenges)
	elseif wndSortByDropdownContainer:FindChild("btnToggleType"):IsChecked() then
		tChallengeListOfList = self:SetUpTypeList(tFilteredChallenges)
    end
	return tChallengeListOfList
end

function ChallengeLog:OnGenerateRewardItemTooltip(wndHandler, wndControl, eToolTipType, x, y)
	if wndHandler ~= wndControl or Tooltip == nil then
		return
	end

	local tData = wndControl:GetData()
	
	local tPrimaryTooltipOpts =
	{
		bPrimary = true,
		itemCompare = tData.itemReward:GetEquippedItemForItemType()
	}

	Tooltip.GetItemTooltipForm(self, wndControl, tData.itemReward, tPrimaryTooltipOpts)
end

function ChallengeLog:OnGenerateCashRewardTooltip(wndHandler, wndControl, eToolTipType, monA, monB)
	if wndHandler ~= wndControl or Tooltip == nil then
		return
	end

	if eToolTipType == Tooltip.TooltipGenerateType_Money then
		local xml = nil
		
		if monA:GetAmount() > 0 then
			if xml == nil then
				xml = XmlDoc.new()
			end
			xml:AddLine("<P>".. monA:GetMoneyString() .."</P>")
		end
		
		if monB:GetAmount() > 0 then
			if xml == nil then
				xml = XmlDoc.new()
			end
			xml:AddLine("<P>".. monB:GetMoneyString() .."</P>")
		end
		
		wndControl:SetTooltipDoc(xml)
	end
end

function ChallengeLog:OnRewardConfirmTakeBtnSignal(wndHandler, wndControl, eMouseButton)
	local tData = wndControl:GetData()
	if not tData then
		return
	end

	local nRewardIdx = tData.tReward.nRewardIdx
	local nRewardItemChoiceIdx = tData.nChoiceIdx
	
	Sound.Play(nRewardIdx == self.rtRewardTrack:GetNumRewards() - 1 and Sound.PlayUIContractGoldMilestoneTurnIn or Sound.PlayUIContractMilestoneTurnIn)
	self.rtRewardTrack:ClaimRewardPoint(nRewardIdx, nRewardItemChoiceIdx)
	self:UpdateInterfaceMenuAlerts()
end

function ChallengeLog:OnRewardItemSelectionBtnCheck(wndHandler, wndControl, eMouseButton)
	local tData = wndControl:GetData()
	if not tData then
		return
	end

	local tClaimData = tData.wndRewardListClaimBtn:GetData()
	local tReward = tClaimData.tReward
	
	tClaimData.nChoiceIdx = tData.tItemChoice.nChoiceIdx
	tData.wndRewardListClaimBtn:SetData(tClaimData)
	tData.wndRewardListClaimBtn:Enable(tReward.bCanClaim and not tReward.bIsClaimed)
end

function ChallengeLog:OnRewardItemSelectionBtnUncheck(wndHandler, wndControl, eMouseButton)
	local tData = wndControl:GetData()
	if not tData then
		return
	end

	tData.wndRewardListClaimBtn:Enable(false)
end

-----------------------------------------------------------------------------------------------------------

function ChallengeLog:BuildChallengeList(tFilteredChallenges)
	-- This is essentially step 2 of the Redraw() method, if we do have valid data to show
    local tChallengeListOfList = self:HelperGetListOfLists(tFilteredChallenges)
    if not tChallengeListOfList or self:GetTableSize(tChallengeListOfList) == 0 then
		return
	end

	-- Draw headers in challenge list
    for strCurrId, value in pairs(tChallengeListOfList) do
		self:DrawHeader(strCurrId, tChallengeListOfList)
    end

    local nVScrollPos = self.wndTopLevel:GetVScrollPos()

	-- Draw items in headers
    for key, wndCurrHeader in pairs(self.wndTopLevel:GetChildren()) do
		local nHeight = 0
		local bDrawItemsInHeader = wndCurrHeader:FindChild("HeaderBtn"):IsChecked() and tChallengeListOfList[wndCurrHeader:GetData()]
		if bDrawItemsInHeader then
			nHeight = self:InsertHeaderChildren(wndCurrHeader:GetData(), wndCurrHeader, tChallengeListOfList)
        end
		wndCurrHeader:FindChild("HeaderContainer"):Show(bDrawItemsInHeader)
		self:SetHeaderSize(wndCurrHeader, nHeight, true)
    end
	
    self.wndTopLevel:ArrangeChildrenVert()
    self.wndTopLevel:SetVScrollPos(nVScrollPos)
end

function ChallengeLog:InsertHeaderChildren(nCurrTypeOrZoneId, wndCurrHeader, tList)
    local nTotalChildHeight = 0
	for key, clgCurrent in pairs(tList[nCurrTypeOrZoneId]) do
        if self:ShouldDraw(clgCurrent, nCurrTypeOrZoneId, wndCurrHeader) then
            local wndPanel = self:FetchPanel(clgCurrent, wndCurrHeader)
            if wndPanel == nil then
                wndPanel = self:NewPanel(wndCurrHeader:FindChild("HeaderContainer"), clgCurrent)
            end

            -- Draw contents, now that panel is found or created if nil
            nTotalChildHeight = nTotalChildHeight + self:DrawPanelContents(wndPanel)
        end
    end

	-- now all the header children are added, call ArrangeChildrenVert to list out the list items vertically
    self:SetHeaderSize(wndCurrHeader:FindChild("HeaderContainer"), nTotalChildHeight, false)
    wndCurrHeader:FindChild("HeaderContainer"):ArrangeChildrenVert()

    return nTotalChildHeight
end

function ChallengeLog:OnClearSearchBtn(wndHandler, wndControl)
	local wndTopHeader = self.wndMain:FindChild("TopHeader")
	wndTopHeader:FindChild("ClearSearchBtn"):Show(false)
	local wndEditBox = wndTopHeader:FindChild("HeaderSearchBox")
	if wndEditBox then
		wndEditBox:SetText("")
		wndEditBox:ClearFocus()
		self:OnEditBoxChanged(wndEditBox, wndEditBox, "")--so that the cleared text will take effect for the filtered challenges
	end
end

-----------------------------------------------------------------------------------------------
-- Our big main draw function for panel contents
-----------------------------------------------------------------------------------------------

-- Static
function ChallengeLog:DrawPanelContents(wndParent)
	local clgBeingDrawn = wndParent:GetData()
	if not clgBeingDrawn then
		return
	end

	local idChallenge = clgBeingDrawn:GetId()
	local eChallengeType = clgBeingDrawn:GetType()
	local bActivated = clgBeingDrawn:IsActivated()
	local bIsInCooldown = clgBeingDrawn:IsInCooldown()
	local nCompletionCount = clgBeingDrawn:GetCompletionCount()
	local tZoneRestrictionInfo = clgBeingDrawn:GetZoneRestrictionInfo()

	local wndListItemBtn = wndParent:FindChild("ListItemBtn")
	local wndListItemLocation = wndListItemBtn:FindChild("ListItemLocation")
	local wndListItemTitle = wndListItemBtn:FindChild("ListItemTitle")
	wndListItemBtn:SetData(clgBeingDrawn)
	wndListItemLocation:SetText("")
	wndListItemTitle:SetText(clgBeingDrawn:GetName())
	wndListItemBtn:FindChild("ListItemTimerText"):SetText(self:HelperConvertToTime(clgBeingDrawn:GetTimer()))
	wndListItemBtn:FindChild("ListItemTypeIcon"):SetSprite(self:CalculateIconPath(eChallengeType))

	-- Draw location if possible
	local wndSortByDropdownContainer = self.wndMain:FindChild("RightSide:Reward:Tracker:ChallengeControls:SortByDropdownContainer")
	if tZoneRestrictionInfo.strSubZoneName and tZoneRestrictionInfo.strSubZoneName ~= "" and wndSortByDropdownContainer:FindChild("btnToggleType"):IsChecked()then
		if tZoneRestrictionInfo.strLocationName and tZoneRestrictionInfo.strLocationName ~= "" then
			wndListItemLocation:SetText(tZoneRestrictionInfo.strSubZoneName .. " : " .. tZoneRestrictionInfo.strLocationName)
		else
			wndListItemLocation:SetText(tZoneRestrictionInfo.strSubZoneName)
		end
	end

	-- Change color if activated
	if self.tFailMessagesList and self.tFailMessagesList[idChallenge] then
		wndListItemTitle:SetTextColor(ApolloColor.new("ConHard"))
		wndListItemTitle:SetText(self.tFailMessagesList[idChallenge])
	elseif bActivated then
        wndListItemTitle:SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
	else
		wndListItemTitle:SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
    end

	self:DrawTierInfo(wndParent, clgBeingDrawn)
	self:DrawWarningWindow(clgBeingDrawn, idChallenge, eChallengeType, bActivated, tZoneRestrictionInfo)

	-- Should be redundant
	if self.nSelectedListItem and self.nSelectedListItem == idChallenge then
		wndListItemBtn:SetCheck(true)
	end

    -- Completed Challenges are disabled, unless lootable
    if not self:IsStartable(clgBeingDrawn) then
        wndListItemBtn:Enable(false)
    end

	-- Determine Status Icon
	-- Priority: In Progress -> Failed -> Complete -> New
	local strStatusIconSprite = "kitIcon_New"
	if bActivated then
		strStatusIconSprite = "kitIcon_InProgress"
	elseif self.tFailMessagesList and self.tFailMessagesList[idChallenge] then
		strStatusIconSprite = "kitIcon_NewDisabled"
	elseif nCompletionCount > 0 then
		strStatusIconSprite = "kitIcon_Complete"
	elseif bIsInCooldown then
		strStatusIconSprite = "kitIcon_NewDisabled" -- Repeated icon
	end
	wndListItemBtn:FindChild("ListItemStatusIconFrame:ListItemStatusPicture"):SetSprite(strStatusIconSprite)

    -- Return the height. We sum this as we build.
    local nLeft, nTop, nRight, nBottom = wndParent:GetAnchorOffsets()
	local nHeight = nBottom - nTop
    return nHeight
end

-- Draw tier info for the main panel
function ChallengeLog:DrawTierInfo(wndContainer, clgBeingDrawn)
	local strFontPathToUse = "<P Font=\"CRB_InterfaceSmall\" TextColor=\"UI_TextHoloBody\">"
	local strFontPathToUseRight = "<P Font=\"CRB_InterfaceSmall\" TextColor=\"UI_TextHoloBody\" Align=\"Right\">"
	local wndListItemDescription = wndContainer:FindChild("ListItemBtn:ListItemDescription")
	local wndDescriptionTieredObjective = wndContainer:FindChild("TierContainer:DescriptionTieredObjective")
	wndListItemDescription:SetAML(strFontPathToUse..clgBeingDrawn:GetDescription().."</P>")

	local tTierInfo = clgBeingDrawn:GetAllTierCounts()
	local nCurrentTier = clgBeingDrawn:GetDisplayTier()
	local nCurrentCount = clgBeingDrawn:GetCurrentCount()
	local nTotalCount = clgBeingDrawn:GetTotalCount()
	local bIsTimeTiered = clgBeingDrawn:IsTimeTiered()

	if tTierInfo == 0 or self:GetTableSize(tTierInfo) <= 1 then -- Not Tiered
		local strCurrentCount = nCurrentCount
		if clgBeingDrawn:GetCompletionCount() > 0 and not bActivated then
			strCurrentCount = nTotalCount
		end
		if nTotalCount == 100 then
			wndDescriptionTieredObjective:SetAML(string.format("%s0%%", strFontPathToUseRight))
		else
			wndDescriptionTieredObjective:SetAML(string.format("%s[%s/%s]", strFontPathToUseRight, strCurrentCount, nTotalCount))
		end

		-- Resize
		local nContentX, nContentY = wndListItemDescription:GetContentSize()
		local nOffsetY = 0
		if nContentY > self.knListItemDescriptionOriginalHeight then
			nOffsetY = nContentY - self.knListItemDescriptionOriginalHeight + self.knListItemDescriptionOriginalHeightPadding
		end
		local nLeft, nTop, nRight, nBottom = wndContainer:GetOriginalLocation():GetOffsets()
        wndContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nOffsetY)

		-- Move Objectives to where TierIcons would've been
		wndDescriptionTieredObjective:SetAnchorOffsets(-85, 34, -8, 0) -- TODO TEMP HACK: Super hardcoded formatting, replace with arrangehorz

	elseif self:GetTableSize(tTierInfo) > 1 then -- Tiered
        local strAppend = ""
		local nNumOfTiers = 0
        local nNumCompletedTiers = 0
		local bIsActivated = clgBeingDrawn:IsActivated()

		local wndTierIcons = wndContainer:FindChild("TierContainer:TierIcons")
		local wndBronzeIcon = wndTierIcons:FindChild("BronzeIcon")
		local wndSilverIcon = wndTierIcons:FindChild("SilverIcon")
		local wndGoldIcon = wndTierIcons:FindChild("GoldIcon")

		local nLastSize = 0
        for idx, tCurrTier in pairs(tTierInfo) do
            nNumOfTiers = nNumOfTiers + 1
			if nCurrentTier >= nNumOfTiers then
				nNumCompletedTiers = nNumCompletedTiers + 1
			end

			local nTierGoal = tCurrTier.nGoalCount
			if bIsTimeTiered then
				local nTierTime = clgBeingDrawn:GetDuration() - tCurrTier.nGoalCount
				strNewLine = self:HelperConvertToTime(nTierTime)
			elseif nTierGoal == 100 and idx == nNumCompletedTiers and not bIsActivated then
				strNewLine = String_GetWeaselString(Apollo.GetString("CRB_Percent"), nTierGoal)
			elseif nTierGoal == 100 and (idx - 1) == nNumCompletedTiers and bIsActivated then
				strNewLine = String_GetWeaselString(Apollo.GetString("CRB_Percent"), math.min(nCurrentCount, nTierGoal))
			elseif nTierGoal == 100 then
				strNewLine = "<T TextColor=\"0\">.</T>"
			else
				strNewLine = String_GetWeaselString(Apollo.GetString("CRB_ProgressSimple"), math.min(nCurrentCount, nTierGoal), nTierGoal)
			end
			--each is a new line, so no need for string weasel
			strAppend = strAppend..strFontPathToUseRight..strNewLine.."</P>"
			wndDescriptionTieredObjective:SetAML(strAppend)

			-- Resize for medals -- TODO Refactor, can just load these as forms instead of moving them around
			local nTextWidth, nTextHeight = wndDescriptionTieredObjective:SetHeightToContentHeight()
			if idx == 1 then -- Bronze, we don't need to move
				nLastSize = nTextHeight -- don't need to subtract nLastSize here if it's lined up in xml
			elseif idx == 2 then -- Silver, go down 14 from the top from the bottom of the bronze
				local nBottomOfBronze = nLastSize
				wndSilverIcon:SetAnchorOffsets(0, nBottomOfBronze, 14, nBottomOfBronze + 14) -- TODO: Hardcode Medal Size at 14px
				nLastSize = nTextHeight - nLastSize
			elseif idx == 3 then -- Gold, go down 14 from the top from the bottom of the silver
				local nBottomOfSilver = nTextHeight - nLastSize
				wndGoldIcon:SetAnchorOffsets(0, nBottomOfSilver, 14, nBottomOfSilver + 14)
			end
        end

        wndBronzeIcon:Show(nNumOfTiers >= 1)
        wndSilverIcon:Show(nNumOfTiers >= 2)
        wndGoldIcon:Show(nNumOfTiers >= 3)
        wndBronzeIcon:FindChild("TierIconCheckmark"):Show(nNumCompletedTiers >= 1)
        wndSilverIcon:FindChild("TierIconCheckmark"):Show(nNumCompletedTiers >= 2)
        wndGoldIcon:FindChild("TierIconCheckmark"):Show(nNumCompletedTiers >= 3)

		local nBronzeReward = ChallengesLib.GetRewardTrackPoints(keRewardTrack.Bronze)
		local nSilverReward = ChallengesLib.GetRewardTrackPoints(keRewardTrack.Silver)
		local nGoldReward = ChallengesLib.GetRewardTrackPoints(keRewardTrack.Gold)

		wndBronzeIcon:SetTooltip(String_GetWeaselString(Apollo.GetString("ChallengeLog_RewardTrack_Toolip"), nBronzeReward))
		wndSilverIcon:SetTooltip(String_GetWeaselString(Apollo.GetString("ChallengeLog_RewardTrack_Toolip"), nBronzeReward + nSilverReward))
		wndGoldIcon:SetTooltip(String_GetWeaselString(Apollo.GetString("ChallengeLog_RewardTrack_Toolip"), nBronzeReward + nSilverReward + nGoldReward))
		
		-- Resize
		local nContentX, nContentY = wndDescriptionTieredObjective:GetContentSize()
		local nOffsetY = 0
		if nContentY > self.knListItemDescriptionOriginalHeight then
			nOffsetY = nContentY - self.knListItemDescriptionOriginalHeight + self.knListItemDescriptionOriginalHeightPadding
		end
		local nListItemDescContentX, nListItemDescContentY = wndListItemDescription:GetContentSize()
		if nListItemDescContentY > self.knListItemDescriptionOriginalHeight and nListItemDescContentY > nContentY then
			nOffsetY = nListItemDescContentY - self.knListItemDescriptionOriginalHeight + self.knListItemDescriptionOriginalHeightPadding
		end
		local nLeft, nTop, nRight, nBottom = wndContainer:GetOriginalLocation():GetOffsets()
        wndContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nOffsetY)
    end
end

function ChallengeLog:DrawWarningWindow(clgCurrent, idChallenge, eChallengeType, bActivated, tZoneRestrictionInfo)
	local wndWarningWindow = self.wndMain:FindChild("RightSide:ChallengeControls:WarningWindow")
    if self.nSelectedListItem and self.nSelectedListItem == idChallenge then
		local wndInteractArea = self.wndMain:FindChild("RightSide:ChallengeControls:BGRightFooter:InteractArea")
		-- Highest Priority is warning event text, don't overwride this until it fades naturally
		if not wndWarningWindow:FindChild("WarningEventText"):IsShown() then
			local bInZone = self:HelperIsInZone(tZoneRestrictionInfo)
			wndWarningWindow:FindChild("WarningZoneText"):Show(not bInZone)
			wndWarningWindow:FindChild("WarningTypeText"):Show(bInZone and self:HelperCurrentTypeAlreadyActive(eChallengeType, idChallenge))
		end
    end
	wndWarningWindow:Show(wndWarningWindow:FindChild("WarningTypeText"):IsShown()
												or wndWarningWindow:FindChild("WarningZoneText"):IsShown() or wndWarningWindow:FindChild("WarningEventText"):IsShown())
end

-----------------------------------------------------------------------------------------------
-- ChallengeLog List Drawing Functions
-----------------------------------------------------------------------------------------------

function ChallengeLog:DrawLeftPanelUI(tChallengeList)
	-- Show count of lootable challenges for the selected big zone, even if we have 0 challenges
	local nLootCount = 0
	self.wndMain:FindChild("LeftSide:BigZoneListContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function ChallengeLog:DrawRightPanelUI(tFilteredChallenges)
	local strEmptyListNotification = ""
	local bShowEmptyListWarning = tFilteredChallenges == nil or self:GetTableSize(tFilteredChallenges) == 0 and self.nSelectedBigZone ~= nil
	local wndTopHeader = self.wndMain:FindChild("TopHeader")
	local wndRightSide = self.wndMain:FindChild("RightSide")

	if bShowEmptyListWarning then
		if wndTopHeader:FindChild("ToggleShowAllBtn"):IsChecked() or wndTopHeader:FindChild("ToggleReadyBtn"):IsChecked() then
			strEmptyListNotification = Apollo.GetString("Challenges_FindNewChallenges")
		elseif wndTopHeader:FindChild("ToggleCooldownBtn"):IsChecked() and self.nSelectedBigZone == kIdAllZoneBtn then
			strEmptyListNotification = Apollo.GetString("Challenges_NoCooldown")
		elseif wndTopHeader:FindChild("ToggleCooldownBtn"):IsChecked() then
			strEmptyListNotification = String_GetWeaselString(Apollo.GetString("Challenges_NoCDZone"), wndRightSide:FindChild("ItemListZoneName"):GetText())
		end
	end

	local wndEmptyListNotification = wndRightSide:FindChild("EmptyListNotification")
	wndEmptyListNotification:SetText(strEmptyListNotification)
	wndEmptyListNotification:FindChild("EmptyListNotificationBtn"):Show(bShowEmptyListWarning and not wndTopHeader:FindChild("ToggleShowAllBtn"):IsChecked())
	--wndRightSide:FindChild("ItemListZoneName"):Show(not bShowEmptyListWarning) -- Removed for now
end

-- Static
function ChallengeLog:DrawHeader(strCurrId, tChallengeListOfList)
	local wndResult = self.wndTopLevel:FindChildByUserData(strCurrId)
	if not wndResult then
		wndResult = Apollo.LoadForm(self.xmlDoc, "HeaderItem", self.wndTopLevel, self)
		wndResult:FindChild("HeaderBtn"):SetCheck(true)
	end
	wndResult:SetData(strCurrId)

	local strDesc = ""
	local wndSortByDropdownContainer = self.wndMain:FindChild("RightSide:Reward:Tracker:ChallengeControls:SortByDropdownContainer")
	for key, clgCurrent in pairs(tChallengeListOfList[strCurrId]) do
        if wndSortByDropdownContainer:FindChild("btnToggleZone"):IsChecked() then
			local strLocalHeader = clgCurrent:GetZoneRestrictionInfo().strSubZoneName
            if strLocalHeader == "" then
                strDesc = Apollo.GetString("Challenges_UnspecifiedArea")
            else
                strDesc = strLocalHeader
            end
            break
        else

			local tInfo =
			{
				["name"] = "",
				["count"] = 2  --Want "Combat Challenges", not "Combat Challenge"
			}

			local eChallengeType = clgCurrent:GetType()
            if eChallengeType == ChallengesLib.ChallengeType_Combat then
				tInfo["name"] = Apollo.GetString("Challenges_CombatChallengePlural")
            elseif eChallengeType == ChallengesLib.ChallengeType_Ability then
				tInfo["name"] = Apollo.GetString("Challenges_AbilityChallengePlural")
            elseif eChallengeType == ChallengesLib.ChallengeType_General then
				tInfo["name"] = Apollo.GetString("Challenges_GeneralChallengePlural")
            elseif eChallengeType == ChallengesLib.ChallengeType_Item then
				tInfo["name"] = Apollo.GetString("Challenges_ItemChallengePlural")
			elseif eChallengeType == ChallengesLib.ChallengeType_ChecklistActivate then
				tInfo["name"] = Apollo.GetString("Challenges_ActivateChallengePlural")
			end
			if tInfo["name"] ~= "" then
				strDesc = String_GetWeaselString(Apollo.GetString("CRB_MultipleNoNumber"), tInfo)
			end
			break
        end
    end
	wndResult:FindChild("HeaderBtnText"):SetText(strDesc)
end

-----------------------------------------------------------------------------------------------
-- ChallengeLog Simple UI Interaction
-----------------------------------------------------------------------------------------------

function ChallengeLog:OnBigZoneBtnPress(wndHandler, wndControl)
	if wndHandler ~= wndControl or not wndHandler then
		return
	end
	if wndHandler:GetData() ~= nil then
		self.nSelectedBigZone = wndHandler:GetData()
		self:DestroyHeaderWindows()
	end

	self:HelperPickBigZone(wndHandler)
	self.rtRewardTrack = nil

	if self.nSelectedBigZone ~= kIdAllZoneBtn then
		self.rtRewardTrack = ChallengesLib.GetRewardTrackByZone(self.nSelectedBigZone)--Redraw will handle updating the reward tracker.
	end

	--Want to make sure that current string in the search bar is accounted for. This has to happen after the HelperPickBigZone has been called
	local strText = self.wndMain:FindChild("HeaderSearchBox"):GetText()
	if strText ~= "" then
		self:OnEditBoxChanged(wndEditBox, wndEditBox, strText)--so that the cleared text will take effect for the filtered challenges
	end
	self:Redraw() --changing zones should clear all the currently displayed challenges
end

--Clicking on an challenge entry should handle showing/enabling buttons regarding it, not waiting for the Redraw method to fire up to 1 second later.
function ChallengeLog:OnListItemClick(wndHandler, wndControl)
    if wndHandler ~= wndControl or not wndHandler:GetData() then
		return
	end

	local clgClicked = wndHandler:GetData()
	self.nSelectedListItem = clgClicked:GetId()
	self:HelperUpdateControlsForChallenge(clgClicked)
	
	--When clicking on challenge, player may be in subzone, so need to recognize if they move into area to start.
	self:HelperHandleLocationTimer()
	
	local rtClickedRewardTrack = clgClicked:GetRewardTrack()

	--In case challenge reward track doesn't match the zone. This can be removed when it is guaranteed that all challenges in a zone point to same reward track.
	if rtClickedRewardTrack ~= self.rtRewardTrack then
		self.rtRewardTrack = rtClickedRewardTrack
		self:UpdateRewardTracker()
	end
end

function ChallengeLog:OnAbandonChallengeBtn(wndHandler, wndControl)
	if not self.nSelectedListItem then
		return
	end

	ChallengesLib.AbandonChallenge(self.nSelectedListItem)
end

function ChallengeLog:OnStartChallengeBtn(wndHandler, wndControl)
	if not self.nSelectedListItem then
		return
	end

	ChallengesLib.ShowHintArrow(self.nSelectedListItem)
	ChallengesLib.ActivateChallenge(self.nSelectedListItem)
	Event_FireGenericEvent("ChallengeLogStartBtn", self.nSelectedListItem)

	wndHandler:Enable(false)
	self.wndAbandonChallengeBtn:Enable(true)
	self.timerPlayerAtStartLocationCheck:Stop()
end

function ChallengeLog:OnLocateChallengeBtn()
	if not self.nSelectedListItem then
		return
	end

	ChallengesLib.ShowHintArrow(self.nSelectedListItem)
end

function ChallengeLog:OnRewardChallengeBtn() -- We need a generic event to get the tracker to close a loot window
	if not self.nSelectedListItem then
		return
	end

	-- Hackish. Loading from log in screen has the logic+ui slightly out of sync in terms of events, so simulate the events.
	self:OnChallengeCompleted(self.nSelectedListItem, nil, nil, nil)
end

function ChallengeLog:OnEmptyListNotificationBtn()
	local wndTopHeader = self.wndMain:FindChild("TopHeader")
	wndTopHeader:FindChild("ToggleShowAllBtn"):SetCheck(true)
	wndTopHeader:FindChild("ToggleCooldownBtn"):SetCheck(false)
	wndTopHeader:FindChild("ToggleReadyBtn"):SetCheck(false)


	-- Pick "Show All"
	self.nSelectedBigZone = kIdAllZoneBtn
	self:HelperPickBigZone(self.wndShowAllBigZone:FindChild("BigZoneBtn"))
	self:Redraw()
end

-----------------------------------------------------------------------------------------------
-- Events From Code
-----------------------------------------------------------------------------------------------

function ChallengeLog:OnChallengeUpdated(idChallenge)
	self:RedrawChallengeListItem(idChallenge)
	local clgUpdated = self.tChallengesToUpdate[idChallenge]
	if not clgUpdated then --When starting a challenge there was no record so this could be nil
		return
	end

	if idChallenge == self.nSelectedListItem then
		self:HelperUpdateControlsForChallenge(clgUpdated)
	end

	--If one of the challenges in the stored table is no longer active, remove it and stop redrawing its list entry
	if clgUpdated and not clgUpdated:IsActivated() and not clgUpdated:IsInCooldown() then
		self.tChallengesToUpdate[idChallenge] = nil
	end

	self:DrawLeftPanelUI(self.tCurrentlyDisplayedChallenges)
end

function ChallengeLog:OnChallengeUnlocked(clgChallenge)
	self.tCurrentlyDisplayedChallenges = self:HelperGetCurrentChallengesForZone()--update the challenges for the zone to be for the currently selected zone button.
	self:HelperAddToChallengesByZoneId(clgChallenge)
	self:Redraw()--could require adding new header item, must redraw
end

function ChallengeLog:OnChallengeActivate(clgChallenge)
	local idChallenge = clgChallenge:GetId()
    if self.tFailMessagesList ~= nil and self.tFailMessagesList[idChallenge] ~= nil then
		self.tFailMessagesList[idChallenge] = nil -- Remove from red fail text list
    end
	self.tTimerAreaRestriction[clgChallenge:GetType()]:Stop()
	--add new challenges to this list so that there timer strings if shown can be updated
	local strTime = self:HelperConvertToTime(clgChallenge:GetTimer())
	if strTime then
		self.tChallengesToUpdate[idChallenge] = clgChallenge
	end

	--Could start a challenge while viewing cooldown for example, so must make sure that the currently viewed section reflects changes.
	self:Redraw()
end

function ChallengeLog:OnChallengeFail(clgFailed, strHeader, strDesc)
	local idChallenge = clgFailed:GetId()

	-- If the challenge completed with at least 1 tier complete, don't consider it a failure
	if clgFailed:GetDisplayTier() > 0 then
		return
	end

	if self.tFailMessagesList == nil then
		self.tFailMessagesList = {}
	end

	self.tFailMessagesList[idChallenge] = strHeader

	--remove challenges that are failed so timer strings aren't updated
	self.tChallengesToUpdate[idChallenge] = nil --Don't need to check to see if it is in table. If this id wasn't in the table, there is no effect.

	self:RedrawChallengeListItem(idChallenge)
	self:DrawLeftPanelUI(self.tCurrentlyDisplayedChallenges)
end

function ChallengeLog:OnChallengeCompleted(idChallenge, strHeader, strDescription, fDuration)
	-- Destroy a victory (we don't want to redraw all headers as we'll lose scroll position, but self:Redraw() doesn't seem to work)
	for key, wndCurrHeader in pairs(self.wndTopLevel:GetChildren()) do
		if wndCurrHeader ~= nil then
			local wndPanel = wndCurrHeader:FindChild("HeaderContainer"):FindChild(idChallenge)
			if wndPanel ~= nil then
				wndPanel:Destroy()
			end
		end
	end

	--want to update the number of rewards shown on the toggle button
	self:Redraw()
end

function ChallengeLog:OnChallengeAreaRestriction(idChallenge, strHeader, strDescription, fDuration)
	local wndWarningText = self.wndMain:FindChild("RightSide:ChallengeControls:WarningWindow:WarningEventText")
	wndWarningText:Show(true)
	wndWarningText:SetText(strDescription)
	for idx, clgCurrent in pairs(ChallengesLib.GetActiveChallengeList()) do
		if clgCurrent:GetId() == idChallenge then
			--can only have one active challenge per type
			local eType = clgCurrent:GetType()
			self.tTimerAreaRestriction[eType]:Set(fDuration, false)
			self.tTimerAreaRestriction[eType]:Start()
		end
	end

	self:RedrawChallengeListItem(idChallenge)
end

function ChallengeLog:OnAreaRestrictionTimer()
	self.wndMain:FindChild("RightSide:ChallengeControls:WarningWindow:WarningEventText"):Show(false)
end

-- Selecting challenge types to show lead here.
function ChallengeLog:DestroyAndRedraw()
	self:DestroyHeaderWindows()
	self:Redraw()
end

-----------------------------------------------------------------------------------------------
-- Challenge Sharing
-----------------------------------------------------------------------------------------------

function ChallengeLog:OnChallengeShared(idChallenge)
	-- This event will not happen if auto accept is on (instead it'll just auto start a challenge)
	if self.wndChallengeShare and self.wndChallengeShare:IsValid() then
		return
	end

	self.wndChallengeShare =  Apollo.LoadForm(self.xmlDoc, "ShareChallengeNotice", nil, self)
	self.wndChallengeShare:SetData(idChallenge)
	self.wndChallengeShare:Invoke()
end

function ChallengeLog:OnShareChallengeAccept(wndHandler, wndControl)
	ChallengesLib.AcceptSharedChallenge(self.wndChallengeShare:GetData())
	if self.wndChallengeShare:FindChild("AlwaysRejectCheck"):IsChecked() then
		Event_FireGenericEvent("ChallengeLog_UpdateShareChallengePreference", GameLib.SharedChallengePreference.AutoReject)
	end
	self.wndChallengeShare:Destroy()
	self.wndChallengeShare = nil
end

function ChallengeLog:OnShareChallengeClose() -- Can come from a variety of places
	if self.wndChallengeShare and self.wndChallengeShare:IsValid() then
		ChallengesLib.RejectSharedChallenge(self.wndChallengeShare:GetData())
		if self.wndChallengeShare:FindChild("AlwaysRejectCheck"):IsChecked() then
			Event_FireGenericEvent("ChallengeLog_UpdateShareChallengePreference", GameLib.SharedChallengePreference.AutoReject)
		end
		self.wndChallengeShare:Destroy()
		self.wndChallengeShare = nil
	end
end

-----------------------------------------------------------------------------------------------
-- ChallengeLog List Building Functions
-----------------------------------------------------------------------------------------------

function ChallengeLog:SetUpZoneList(tChalList)
    local tNewZoneList = {}
    for idx, clgCurrent in pairs(tChalList) do
		local tZoneRestrictionInfo = clgCurrent:GetZoneRestrictionInfo()
		if tZoneRestrictionInfo then
			if tNewZoneList[tZoneRestrictionInfo.idSubZone] == nil then
				-- Build the Deep Table
				local tNewTable = {}
				tNewTable[idx] = clgCurrent

				-- Insert the Table into the Top Table
				tNewZoneList[tZoneRestrictionInfo.idSubZone] = tNewTable
			else
				-- Open the Table within the Table, and set the deep value to Challenge
				local tOldTable = tNewZoneList[tZoneRestrictionInfo.idSubZone]
				tOldTable[idx] = clgCurrent
			end
		end
    end

    return tNewZoneList
end

-- Top List [Key: TypeId , Value: A Table]
-- Deep List [Key: ChallengeId , Value: A Challenge ]

function ChallengeLog:SetUpTypeList(tChallengeList)
    local tNewTypeList = {}
    for idx, clgCurrent in pairs(tChallengeList) do
		local eCurrentType = clgCurrent:GetType()
		if eCurrentType then
			if tNewTypeList[eCurrentType] == nil then
				-- Build the Deep Table
				local tNewTable = {}
				tNewTable[idx] = clgCurrent

				-- Insert the Table into the Top Table
				tNewTypeList[eCurrentType] = tNewTable
			else
				-- Open the Table within the Table, and set the deep value to Challenge
				local tOldTable = tNewTypeList[eCurrentType]
				tOldTable[idx] = clgCurrent
			end
		end
    end

    return tNewTypeList
end

-- Not Static, does logical manipulations that rely on UI states
function ChallengeLog:ShouldDraw(clgCurrent, nCurrTypeOrZoneId, wndCurrHeader)
    if not clgCurrent or not wndCurrHeader:FindChild("HeaderBtn"):IsChecked() then
		return false
	end

	local bResult = false
	local wndSortByDropdownContainer = self.wndMain:FindChild("RightSide:Reward:Tracker:ChallengeControls:SortByDropdownContainer")
    if nCurrTypeOrZoneId == clgCurrent:GetType() and wndSortByDropdownContainer:FindChild("btnToggleType"):IsChecked() then
        bResult = true
    elseif nCurrTypeOrZoneId == clgCurrent:GetZoneRestrictionInfo().idSubZone and wndSortByDropdownContainer:FindChild("btnToggleZone"):IsChecked() then
        bResult = true
    end
    return bResult
end

function ChallengeLog:AddShowAllToBigZoneList()
	if not self.wndShowAllBigZone then
		self.wndShowAllBigZone = Apollo.LoadForm(self.xmlDoc, "BigZoneItem", self.wndMain:FindChild("LeftSide:BigZoneListContainer"), self)

		local wndBigZoneBtn = self.wndShowAllBigZone:FindChild("BigZoneBtn")
		wndBigZoneBtn:SetData(kIdAllZoneBtn)
		wndBigZoneBtn:SetText(Apollo.GetString("Challenges_AllZones"))
	end
end

-- This is called for every challenge in a loop, so exit asap
function ChallengeLog:HandleBigZoneList(tChallengeZoneInfo)
	if not tChallengeZoneInfo then
		return
	end

	local wndContainer = self.wndMain:FindChild("LeftSide:BigZoneListContainer")
	local wndNew = wndContainer:FindChildByUserData(tChallengeZoneInfo.idZone)
	if not wndNew then
		wndNew = Apollo.LoadForm(self.xmlDoc, "BigZoneItem", wndContainer, self)
	end

	-- Draw window
	wndNew:SetData(tChallengeZoneInfo.idZone)
	wndNew:SetName(tChallengeZoneInfo.idZone) -- We set the Name of Parent to ID, but the Data of the button to ID (for button click)

	local wndBigZoneBtn = wndNew:FindChild("BigZoneBtn")
	wndBigZoneBtn:SetData(tChallengeZoneInfo.idZone)
	wndBigZoneBtn:SetText(tChallengeZoneInfo.strZoneName)
end

-----------------------------------------------------------------------------------------------
-- ChallengeLogForm Helper Methods
-----------------------------------------------------------------------------------------------

function ChallengeLog:FetchPanel(clgCurrent, wndCurrHeader)
    local wndPanel = wndCurrHeader:FindChild("HeaderContainer"):FindChild(clgCurrent:GetId())
    return wndPanel
end

function ChallengeLog:HelperIsInZone(tZoneRestrictionInfo)
	return tZoneRestrictionInfo == nil or tZoneRestrictionInfo.idSubZone == 0 or GameLib.IsInWorldZone(tZoneRestrictionInfo.idSubZone)
end

function ChallengeLog:HelperIsInLocation(idLocation)
	return idLocation == 0 or GameLib.IsInLocation(idLocation)
end

function ChallengeLog:IsStartable(clgCurrent)
    return clgCurrent:GetCompletionCount() < clgCurrent:GetCompletionTotal() or clgCurrent:GetCompletionTotal() == -1
end

-- This method is only allowed to destroy header windows for a redraw (e.g. tab swap)
function ChallengeLog:DestroyHeaderWindows()
	if self.wndTopLevel ~= nil then
		self.wndTopLevel:DestroyChildren()
		self.wndTopLevel:RecalculateContentExtents()
	end

	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:FindChild("SortByDropdownContainer"):Show(false)
	end

	self.timerPlayerAtStartLocationCheck:Stop()
	self:HelperResetWarningTextsAndChallengeButtonControls()
end

function ChallengeLog:HelperUpdateControlsForChallenge(clgUpdate)
	if not clgUpdate then
		return
	end

	local idStartLocationRestriction = clgUpdate:GetStartLocationRestrictionId()
	local bActivated = clgUpdate:IsActivated()
	local tZoneRestrictionInfo = clgUpdate:GetZoneRestrictionInfo()

	local bIsStartable = not bActivated and not clgUpdate:IsInCooldown()  and self:IsStartable(clgUpdate)
	local bIsInLocation = self:HelperIsInZone(tZoneRestrictionInfo) and self:HelperIsInLocation(idStartLocationRestriction)
	
    self.wndStartChallengeBtn:Enable(bIsStartable and bIsInLocation)
	self.wndAbandonChallengeBtn:Enable(bActivated)
	self.wndLocateChallengeBtn:Show(bIsStartable and not bIsInLocation)
end

function ChallengeLog:HelperResetWarningTextsAndChallengeButtonControls()
	self.nSelectedListItem = nil
	local wndWarningWindow = self.wndMain:FindChild("RightSide:ChallengeControls:WarningWindow")
	wndWarningWindow:Show(false)
	wndWarningWindow:FindChild("WarningTypeText"):Show(false)
	wndWarningWindow:FindChild("WarningZoneText"):Show(false)
	wndWarningWindow:FindChild("WarningEventText"):Show(false)
	self.wndLocateChallengeBtn:Show(false)
	self.wndStartChallengeBtn:Enable(false)
	self.wndAbandonChallengeBtn:Enable(false)
end

-- This method is only allowed to do a loadform
function ChallengeLog:NewPanel(wndNew, clgCurrent)
    local wndParent = wndNew
    if wndParent == nil then
		wndParent = self.wndTopLevel
	end

    local wndResult = Apollo.LoadForm(self.xmlDoc, "ListItem", wndParent, self)
    wndResult:SetName(clgCurrent:GetId()) -- Hackish to help find challenge windows later
    wndResult:SetData(clgCurrent)
    return wndResult
end

-- This method is only allowed to set the height of a header with its children
function ChallengeLog:SetHeaderSize(wndHeader, nChildrenSize, bFactorHeaderTopHeight)
    -- nChildrenSize can be 0
    if self.knHeaderTopHeight == nil or nChildrenSize == nil then
		return
	end

    local nLeft, nTop, nRight, nBottom = wndHeader:GetAnchorOffsets()
    local nTopOfContainer = nTop
    if bFactorHeaderTopHeight == true then
        nTopOfContainer = nTopOfContainer + self.knHeaderTopHeight
    end
    local nBottomOfContainer = nTopOfContainer + nChildrenSize

    wndHeader:SetAnchorOffsets(nLeft, nTop, nRight, nBottomOfContainer)
    self.wndTopLevel:ArrangeChildrenVert()

    return nBottomOfContainer -- optional to use this
end

function ChallengeLog:GetTableSize(tArg)
    local nCounter = 0
    if tArg ~= nil then
        for key, value in pairs(tArg) do
            nCounter = nCounter + 1
        end
    end
    return nCounter
end

function ChallengeLog:CalculateIconPath(eType)
    local strIconPath = "CRB_GuildSprites:sprChallengeTypeGenericLarge"
	if eType == ChallengesLib.ChallengeType_Combat then     -- Combat
		strIconPath = "CRB_ChallengeTrackerSprites:sprChallengeTypeKillLarge"
	elseif eType == ChallengesLib.ChallengeType_Ability then -- Ability
		strIconPath = "CRB_ChallengeTrackerSprites:sprChallengeTypeSkillLarge"
	elseif eType == ChallengesLib.ChallengeType_General then -- General
		strIconPath = "CRB_ChallengeTrackerSprites:sprChallengeTypeGenericLarge"
	elseif eType == ChallengesLib.ChallengeType_Item then -- Items
		strIconPath = "CRB_ChallengeTrackerSprites:sprChallengeTypeLootLarge"
	end
    return strIconPath
end

function ChallengeLog:HelperConvertToTime(nInSeconds, bReturnZero)
	if not bReturnZero and (nInSeconds == nil or nInSeconds == 0) then
		return ""
	end
	
	local strResult = ""
	local nHours = math.floor(nInSeconds / 3600)
	local nMins = math.floor(nInSeconds / 60 - (nHours * 60))
	local nSecs = string.format("%02.f", math.floor(nInSeconds - (nHours * 3600) - (nMins * 60)))

	if nHours ~= 0 then
		strResult = nHours .. ":" .. nMins .. ":" .. nSecs
	else
		strResult = nMins .. ":" .. nSecs
	end

	return strResult
end

function ChallengeLog:BigZoneFilter(tArg)
	return (tArg and tArg.idZone == self.nSelectedBigZone) or self.nSelectedBigZone == kIdAllZoneBtn
end

function ChallengeLog:HelperPickBigZone(wndArg) -- wndArg is a "BigZoneBtn"
	for key, wndCurr in pairs(self.wndMain:FindChild("LeftSide:BigZoneListContainer"):GetChildren()) do
		wndCurr:FindChild("BigZoneBtn"):SetCheck(false)
	end
	wndArg:SetCheck(true)
	self.wndMain:FindChild("RightSide:ChallengeControls:ItemListZoneName"):SetText(wndArg:GetText())

	self.tCurrentlyDisplayedChallenges = self:HelperGetCurrentChallengesForZone()--update the challenges for the zone to be for the currently selected zone button.
end

function ChallengeLog:HelperCurrentTypeAlreadyActive(eChallengeType, idChallenge)
	local tChallengeList = {}
	local tFilteredChallenges = self:HelperGetFilteredChallenges()
	if tFilteredChallenges then
		tChallengeList = self:HelperGetListOfLists(tFilteredChallenges)
	end


	for key, value in pairs(tChallengeList) do -- TODO Quick Hack. Expensive?
		for key2, clgCurrent in pairs(tChallengeList[key]) do
			if clgCurrent:IsActivated() and clgCurrent:GetType() == eChallengeType and clgCurrent:GetId() ~= idChallenge then
				return true
			end
		end
	end
end

function ChallengeLog:UpdateSignatureControls()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer then
		self:OnPremiumTierChanged(AccountItemLib.GetPremiumSystem(), unitPlayer:GetPremiumTier())
	end
end

function ChallengeLog:OnPremiumTierChanged(ePremiumSystem, nTier)
	if not self.wndMain or ePremiumSystem ~= AccountItemLib.CodeEnumPremiumSystem.Hybrid then
		return
	end

	local bSignature = nTier > 0
	local bLoyaltyBonus = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.LoyaltyChallengeBonus) > 0
	
	local wndRewardTracker = self.wndMain:FindChild("RewardTracker")
	local wndBonusesContainer = wndRewardTracker:FindChild("BonusesContainer")
	local wndIconMTXFormatContainer = wndBonusesContainer:FindChild("IconMTXFormatContainer")
	local wndProgressContainer = wndRewardTracker:FindChild("ProgressContainer")
	local wndProgressBar = wndProgressContainer:FindChild("ProgressBar")
	
	-- Show/Hide MTX Icon
	wndIconMTXFormatContainer:Show(bSignature or bLoyaltyBonus)

	if bSignature or bLoyaltyBonus then
		wndProgressBar:SetFullSprite("challenges:sprChallenges_RewardsProgressFGSig")
		
		-- Set tooltip
		local tRewardTrackInfo = ChallengesLib.GetRewardTrackInfo()
		local nTotalBonus = 0
		local nSigBonus = 0
		local nLoyBonus = 0
		if tRewardTrackInfo.tBonuses ~= nil then
			if tRewardTrackInfo.tBonuses.fSignature ~= nil then
				nSigBonus = tRewardTrackInfo.tBonuses.fSignature
				nTotalBonus = nTotalBonus + nSigBonus
			end
			if tRewardTrackInfo.tBonuses.fLoyalty ~= nil then
				nLoyBonus = tRewardTrackInfo.tBonuses.fLoyalty
				nTotalBonus = nTotalBonus + nLoyBonus
			end
		end

		self.wndMain:FindChild("IconMTX"):SetTooltip(String_GetWeaselString(Apollo.GetString("Challenges_PercentBonus"), nTotalBonus * 100, nSigBonus * 100, nLoyBonus * 100))
	else
		wndProgressBar:SetFullSprite("challenges:sprChallenges_RewardsProgressFG")
	end
	

	-- Show/Hide upsell button
	local wndSigPlayerBtn = wndRewardTracker:FindChild("SigPlayerBtn")
	local wndRewardTrackTitleContainer = wndRewardTracker:FindChild("RewardTrackTitleContainer")
	local nLeft, nTop, nRight, nBottom = wndRewardTrackTitleContainer:GetOriginalLocation():GetOffsets()
	if not bSignature then
		wndSigPlayerBtn:Show(self.bStoreLinkValid)
	else
		wndSigPlayerBtn:Show(false)
	end

	local nChidrenWidth = wndBonusesContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)
	nRight = nRight - nChidrenWidth
	wndRewardTrackTitleContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
end

function ChallengeLog:RefreshStoreLink()
	self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.Signature)
	self:UpdateSignatureControls()
end

function ChallengeLog:OnBecomeSignature(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

function ChallengeLog:OnGenerateSignatureTooltip(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	Tooltip.GetSignatureTooltipForm(self, wndControl, Apollo.GetString("Signature_RewardTrackTooltip"))
end

local ChallengeLogInst = ChallengeLog:new()
ChallengeLogInst:Init()
