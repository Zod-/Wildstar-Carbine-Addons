-----------------------------------------------------------------------------------------------
-- Client Lua Script for WelcomeWindow/DailyRewards
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "AccountItemLib"
 
local DailyRewards = {} 
 
function DailyRewards:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    o.kstrTitle = Apollo.GetString("DailyRewards_Title")
    o.knSortOrder = 2
    o.knItemsPerRowMain 	= 7
    return o
end

function DailyRewards:Init()
    Apollo.RegisterAddon(self, false, self.kstrTitle)
end
 
function DailyRewards:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("DailyRewards.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function DailyRewards:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	--WelcomeWindow Events
	Apollo.RegisterEventHandler("WelcomeWindow_Loaded", 		"OnWelcomeWindowLoaded", self)
	Apollo.RegisterEventHandler("WelcomeWindow_TabSelected",	"OnWelcomeWindowTabSelected", self)
	Apollo.RegisterEventHandler("WelcomeWindow_Closed",			"OnClose", self)
	Event_FireGenericEvent("WelcomeWindow_RequestParent")

	--DailyReward Events
	Apollo.RegisterEventHandler("DailyLoginUpdate",				"OnDailyLoginUpdate", self)
	Apollo.RegisterEventHandler("AccountInventoryUpdate",		"OnAccountInventoryUpdate", self)

	--Premium Updates
	Apollo.RegisterEventHandler("PremiumTierChanged",			"UpdateSignatureControls", self)

	--ExitWindow
	Apollo.RegisterEventHandler("ExitWindow_RequestContent",	"OnExitWindowRequestContent", self)
	Event_FireGenericEvent("ExitWindow_RequestParent")
end

function DailyRewards:OnWelcomeWindowLoaded(wndParent)
	if not wndParent or not wndParent:IsValid() then
		return
	end

	Apollo.RemoveEventHandler("WelcomeWindow_Loaded", self)

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "DailyRewardsBig", wndParent, self)
	Event_FireGenericEvent("WelcomeWindow_TabContent", self.kstrTitle, self.wndMain, self.knSortOrder)

	Apollo.RegisterEventHandler("OverView_Loaded", 	"OnOverViewLoaded", self)
	Event_FireGenericEvent("OverView_RequestParent")
end

function DailyRewards:OnOverViewLoaded(strOverViewTitle, wndParent)
	if not wndParent or not wndParent:IsValid() then
		return
	end

	Apollo.RemoveEventHandler("OverView_Loaded", self)

	self.strOverViewTitle = strOverViewTitle--Used to determine if the Overview Tab is selected.
	self.wndDailyRewardsOverview = Apollo.LoadForm(self.xmlDoc, "DailyRewardsOverview", wndParent:FindChild("DailyRewards"), self)

	self:InitializeContent()
	self:Redraw()
end

function DailyRewards:InitializeContent()
	self.arDailyLoginRewardsAvailable = AccountItemLib.GetDailyLoginRewardsAvailable()
	self.arAllDailyLoginRewards = AccountItemLib.GetDailyLoginRewards()
	self.tLockBoxKeyInfo = AccountItemLib.GetPremiumLockboxKeyInfo()
	self.ePremiumKeyStatus = self.tLockBoxKeyInfo.ePremiumKeyStatus
	self.bHaveRewards = #self.arDailyLoginRewardsAvailable > 0
	self.nLoginDays = AccountItemLib.GetLoginDays()
end

function DailyRewards:OnWelcomeWindowTabSelected(strSelectedTab)
	if self.timerUpdateText then
		self.timerUpdateText:Stop()
	end

	self.bOverViewShowing = strSelectedTab == self.strOverViewTitle
	if self.bOverViewShowing then
		self:RedrawOverViewSection()
	elseif strSelectedTab == self.kstrTitle then
		self:RedrawMainSection()
	end
end

function DailyRewards:OnAccountInventoryUpdate()
	if not self.wndDailyRewardsOverview or not self.wndDailyRewardsOverview:IsValid() or not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	self:InitializeContent()
	self:Redraw()
end

function DailyRewards:OnDailyLoginUpdate(tLoginUpdate)
	if not tLoginUpdate then
		return
	end

	if self.timerUpdateText then
		self.timerUpdateText:Stop()
	end

	self.arDailyLoginRewardsAvailable = AccountItemLib.GetDailyLoginRewardsAvailable()
	self.arAllDailyLoginRewards = AccountItemLib.GetDailyLoginRewards()
	self.ePremiumKeyStatus = tLoginUpdate.ePremiumKeyStatus
	self.bHaveRewards = tLoginUpdate.nRewardsAvailable > 0
	self.nLoginDays = tLoginUpdate.nLoginDaysTotal

	if self.wndDailyRewardsOverview and self.wndDailyRewardsOverview:IsValid() and self.wndMain and self.wndMain:IsValid() then
		local wndAnimations = self.wndDailyRewardsOverview:FindChild("Animations")
		wndAnimations:FindChild("Refresh"):SetSprite("BK3:UI_BK3_Holo_RefreshReflectionSquare_anim")
		wndAnimations:FindChild("Explode"):SetSprite("sprLoginIncentives_Burst")
		wndAnimations:FindChild("SmallerExplode"):SetSprite("sprLoginIncentives_Burst")

		wndAnimations = self.wndMain:FindChild("Animations")
		wndAnimations:FindChild("Refresh"):SetSprite("BK3:UI_BK3_Holo_RefreshReflectionSquare_anim")
		wndAnimations:FindChild("Explode"):SetSprite("sprLoginIncentives_Burst")
		wndAnimations:FindChild("SmallerExplode"):SetSprite("sprLoginIncentives_Burst")

		self:Redraw()
	end
end

function DailyRewards:UpdateSignatureControls()
	if not self.wndDailyRewardsOverview or not self.wndDailyRewardsOverview:IsValid() or not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	self:InitializeContent()
	self:Redraw()
end
	
function DailyRewards:RedrawOverViewSection()
	self:DrawCommonSection(self.wndDailyRewardsOverview:FindChild("ClaimReward"))
end

function DailyRewards:RedrawMainSection()
	self:DrawCommonSection(self.wndMain:FindChild("ClaimReward"))
	self:DrawItemContainer()
end

--Responsible for Drawing both the overview section and the main section.
function DailyRewards:Redraw()
	--Overview Section
	self:RedrawOverViewSection()

	--Big Section
	self:RedrawMainSection()
end

function DailyRewards:DrawCommonSection(wndClaimReward)
	local wndAlreadyClaimed = wndClaimReward:FindChild("AlreadyClaimed")
	local wndReadyToClaim = wndClaimReward:FindChild("ReadyToClaim")

	local bCanClaimRewardOrKey = self.bHaveRewards or self.ePremiumKeyStatus == AccountItemLib.CodeEnumPremiumLockboxKeyStatus.Available
	wndAlreadyClaimed:Show(not bCanClaimRewardOrKey)
	wndReadyToClaim:Show(bCanClaimRewardOrKey)

	local wndShownSection = nil
	if bCanClaimRewardOrKey then
		wndShownSection = wndReadyToClaim
	else
		wndShownSection = wndAlreadyClaimed
	end

	--Draw Dialy Login Reward
	local wndItemContainer = wndShownSection:FindChild("ItemContainer")
	wndItemContainer:DestroyChildren()

	local strRewards = ""
	local tLoginRewardData = nil
	if bCanClaimRewardOrKey and self.arAllDailyLoginRewards[self.nLoginDays] then
		tLoginRewardData = self.arAllDailyLoginRewards[self.nLoginDays]--Get the latest reward first.
		
		if tLoginRewardData and not tLoginRewardData.bRewarded then
			strRewards = tLoginRewardData.tReward.item:GetName()
		end
	elseif self.arAllDailyLoginRewards[self.nLoginDays + 1] then
		tLoginRewardData = self.arAllDailyLoginRewards[self.nLoginDays + 1]
	end

	if tLoginRewardData and tLoginRewardData.tReward and tLoginRewardData.tReward.item then
		self:HelperDrawSimpleItem(tLoginRewardData, wndItemContainer)
	else
		wndShownSection:FindChild("ItemBackground"):Show(false)
		wndShownSection:FindChild("ItemContainer"):Show(false)
		wndShownSection:FindChild("PlusIcon"):Show(false)
	end

	--Lockbox Key
	local wndLockBoxKey = wndShownSection:FindChild("LockBoxKey")
	if not wndLockBoxKey then--First time we draw a lock box key for this shown window.
		wndLockBoxKey = Apollo.LoadForm(self.xmlDoc, "LockBoxKey", wndShownSection:FindChild("KeyContainer"), self)
	end
	self:HelperDrawLockboxItem(wndLockBoxKey)

	if self.ePremiumKeyStatus == AccountItemLib.CodeEnumPremiumLockboxKeyStatus.Available then
		if self.bHaveRewards then
			strRewards = String_GetWeaselString(Apollo.GetString("CoordCrafting_AxisCombine"), strRewards, Apollo.GetString("CRB_LockboxKey"))
		else--The daily reward item was already claimed, but key isn't.
			strRewards = Apollo.GetString("CRB_LockboxKey")
		end
	elseif self.ePremiumKeyStatus == AccountItemLib.CodeEnumPremiumLockboxKeyStatus.OnCooldown then
		self:UpdateLockBoxTime()
		self.timerUpdateText = ApolloTimer.Create(1, true, "UpdateLockBoxTime", self)
	end
	wndReadyToClaim:FindChild("CurrentRewards"):SetText(strRewards)
	wndReadyToClaim:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("WelcomeWindow_DailyRewardTitleDay"), self.nLoginDays))

end

function DailyRewards:DrawItemContainer()
	local wndScrollingItems = self.wndMain:FindChild("ScrollingItems")
	wndScrollingItems:DestroyChildren()
	for idx, tDailyRewardData in pairs(self.arAllDailyLoginRewards) do
		self:HelperDrawRewardItem(tDailyRewardData, wndScrollingItems)
	end

	wndScrollingItems:ArrangeChildrenTiles(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self:HelperShowCurrentItem(wndScrollingItems, self.knItemsPerRowMain)
end

function DailyRewards:HelperShowCurrentItem(wndContainer, nItemsPerRow)
	local nOffset = self.nLoginDays % nItemsPerRow ~= 0 and self.nItemHeight* 2 or self.nItemHeight * 3
	local nPos = (self.nItemHeight  * (math.floor(self.nLoginDays / nItemsPerRow))) - nOffset
	wndContainer:SetVScrollPos(nPos)
end

function DailyRewards:HelperDrawSimpleItem(tLoginRewardData, wndContainer)
	local wndSimpleItem = Apollo.LoadForm(self.xmlDoc, "SimpleItem", wndContainer, self)
	local wndItemIcon = wndSimpleItem:FindChild("ItemIcon")
	wndItemIcon:GetWindowSubclass():SetItem(tLoginRewardData.tReward.item)
	wndItemIcon:SetTooltipForm(nil)

	wndSimpleItem:FindChild("ItemClaimed"):Show(tLoginRewardData.bRewarded)
end

function DailyRewards:HelperDrawRewardItem(tRewardAvailable, wndContainer)
	local wndDailyLoginItem = Apollo.LoadForm(self.xmlDoc, "DailyLoginItem", wndContainer, self)
	if not self.nItemHeight then
		self.nItemHeight = wndDailyLoginItem:GetHeight()
	end

	if tRewardAvailable.bRewarded then--Already claimed
		wndDailyLoginItem:FindChild("Day"):SetTextColor("UI_TextHoloBody")
		wndDailyLoginItem:FindChild("AlreadyClaimed"):Show(true)
	elseif tRewardAvailable.nLoginDay <= self.nLoginDays then--Not rewarded, and less then current day, means havent claimed for these rewards for a few days.
		wndDailyLoginItem:FindChild("ClaimIcon"):Show(true)
		wndDailyLoginItem:FindChild("Day"):SetTextColor("white")
	elseif tRewardAvailable.eDailyLoginRewardTier == AccountItemLib.CodeEnumDailyLoginRewardTier.Milestone then
		wndDailyLoginItem:FindChild("MileStoneIcon"):Show(true)
		wndDailyLoginItem:FindChild("Day"):SetOpacity(0.75)
		wndDailyLoginItem:FindChild("ItemIcon"):SetOpacity(0.75)
		wndDailyLoginItem:SetData(true)
	else
		wndDailyLoginItem:FindChild("Day"):SetTextColor("UI_TextHoloTitle")
		wndDailyLoginItem:FindChild("ItemIcon"):SetOpacity(0.25)
		wndDailyLoginItem:FindChild("Day"):SetOpacity(0.25)
		wndDailyLoginItem:FindChild("FramingBottom"):SetOpacity(0.25)
	end
	
	wndDailyLoginItem:FindChild("Day"):SetText(String_GetWeaselString(Apollo.GetString("LoginIncentives_Day"), tRewardAvailable.nLoginDay))
	
	local wndItemIcon = wndDailyLoginItem:FindChild("ItemIcon")
	if tRewardAvailable.tReward.item then
		wndItemIcon:GetWindowSubclass():SetItem(tRewardAvailable.tReward.item)
	end
	wndItemIcon:SetData(tRewardAvailable.tReward.item)	
	return wndDailyLoginItem
end

function DailyRewards:HelperDrawLockboxItem(wndLockBoxKey)
	if self.tLockBoxKeyInfo and self.tLockBoxKeyInfo.itemKey then
		local wndKeyIcon = wndLockBoxKey:FindChild("KeyIcon")
		wndKeyIcon:GetWindowSubclass():SetItem(self.tLockBoxKeyInfo.itemKey)
		wndKeyIcon:SetTooltipForm(nil)
	end

	wndLockBoxKey:FindChild("KeyCooldown"):Show(self.ePremiumKeyStatus == AccountItemLib.CodeEnumPremiumLockboxKeyStatus.OnCooldown)
	wndLockBoxKey:FindChild("PremiumPlayerBlocker"):Show(self.ePremiumKeyStatus == AccountItemLib.CodeEnumPremiumLockboxKeyStatus.PremiumRequired)
	wndLockBoxKey:FindChild("InAccountInventory"):Show(self.ePremiumKeyStatus == AccountItemLib.CodeEnumPremiumLockboxKeyStatus.InAccountInventory)
	if self.ePremiumKeyStatus == AccountItemLib.CodeEnumPremiumLockboxKeyStatus.PremiumRequired then
		local bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.Signature)
		local wndPremiumPlayerBtn = wndLockBoxKey:FindChild("PremiumPlayerBtn")
		wndPremiumPlayerBtn:Enable(bStoreLinkValid)
	end
end

function DailyRewards:UpdateLockBoxTime(nTime)
	local bCanClaimRewardOrKey = self.bHaveRewards or self.ePremiumKeyStatus == AccountItemLib.CodeEnumPremiumLockboxKeyStatus.Available
	local wndLockBoxKeyParent = nil

	if self.bOverViewShowing then
		if bCanClaimRewardOrKey then
			wndLockBoxKeyParent = self.wndDailyRewardsOverview:FindChild("ReadyToClaim")
		else
			wndLockBoxKeyParent = self.wndDailyRewardsOverview:FindChild("AlreadyClaimed")
		end
	else
		if bCanClaimRewardOrKey then
			wndLockBoxKeyParent = self.wndMain:FindChild("ReadyToClaim")
		else
			wndLockBoxKeyParent = self.wndMain:FindChild("AlreadyClaimed")
		end
	end

	local wndLockBoxKey = wndLockBoxKeyParent:FindChild("LockBoxKey")
	if not wndLockBoxKey then
		return
	end
	
	local wndKeyCooldown = wndLockBoxKey:FindChild("KeyCooldown")
	self.tLockBoxKeyInfo = AccountItemLib.GetPremiumLockboxKeyInfo()
	wndKeyCooldown:Show(self.tLockBoxKeyInfo and self.tLockBoxKeyInfo.fSecondsUntilNextKey > 0 and self.ePremiumKeyStatus == AccountItemLib.CodeEnumPremiumLockboxKeyStatus.OnCooldown)

	if self.tLockBoxKeyInfo and self.tLockBoxKeyInfo.fSecondsUntilNextKey > 0 then
		wndKeyCooldown:FindChild("CooldownTime"):SetText(self:HelperGetLargestTimeUnit(self.tLockBoxKeyInfo.fSecondsUntilNextKey))
		local nMsUntilNextKey = self.tLockBoxKeyInfo.fSecondsUntilNextKey * 1000
		wndKeyCooldown:SetTooltip(String_GetWeaselString(Apollo.GetString("LoginIncentives_LockboxKeyTooltip"), nMsUntilNextKey))
	end
end

function DailyRewards:HelperGetTimeUnits(fSeconds)
	local nSecs = math.floor(fSeconds)
	local nDays = math.floor(nSecs/ 86400)
	nSecs = nSecs - (nDays * 86400)

	local nHours = math.floor(nSecs/ 3600)
	nSecs = nSecs - (nHours * 3600)

	local nMins = math.floor(nSecs/ 60)
	nSecs = nSecs - (nMins * 60)

	return nDays, nHours, nMins, nSecs
end

function DailyRewards:HelperGetLargestTimeUnit(fSeconds)
	local nDays, nHours, nMins, nSecs = self:HelperGetTimeUnits(fSeconds)

	local strUnit = ""
	local nTimeUnit = 0
	if nDays ~= 0 then
		if nHours >= 12 then--Round up days.
			nDays = nDays + 1
		end
		strUnit = "CRB_Days_Abbreviated"
		nTimeUnit = nDays
	elseif nHours ~= 0 then
		strUnit = "CRB_Hours_Abbreviated"
		nTimeUnit = nHours
	elseif nMins ~= 0 then
		strUnit = "CRB_Minutes_Abbreviated"
		nTimeUnit = nMins
	elseif nSecs ~= 0 then
		strUnit = "CRB_Seconds_Abbreviated"
		nTimeUnit = nSecs
	end

	return String_GetWeaselString(Apollo.GetString(strUnit), nTimeUnit)
end
function DailyRewards:OnExitWindowRequestContent(wndParent)
	if not wndParent or not wndParent:IsValid() then
		return
	end

	if not self.nLoginDays then
		self:InitializeContent()
	end

	local nTomorrowLoginDay = self.nLoginDays + 1
	if self.arAllDailyLoginRewards[nTomorrowLoginDay] then
		self.wndDailyRewardsExitWindow = Apollo.LoadForm(self.xmlDoc, "DailyRewardsExitWindow", wndParent:FindChild("DailyLoginContainer"), self)
	
		self.wndDailyRewardsExitWindow:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("LoginIncentives_ExitTitle"), nTomorrowLoginDay))

		local wndItemContainer = self.wndDailyRewardsExitWindow:FindChild("ItemContainer")
		wndItemContainer:DestroyChildren()
		local tLoginRewardData = self.arAllDailyLoginRewards[nTomorrowLoginDay]
		if tLoginRewardData.tReward.item then
			self:HelperDrawSimpleItem(tLoginRewardData , wndItemContainer)
			self.wndDailyRewardsExitWindow:FindChild("CurrentRewards"):SetText(tLoginRewardData.tReward.item:GetName())
		end
	end
end

function DailyRewards:OnInventoryOpen()
	Event_FireGenericEvent("ShowInventory")
end

function DailyRewards:OnPremiumPlayerBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

function DailyRewards:OnClaimBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	-- if the daily rewards have been claimed but only the lockbox key has not, only request the lockbox key
	if not self.bHaveRewards and self.ePremiumKeyStatus == AccountItemLib.CodeEnumPremiumLockboxKeyStatus.Available then
		AccountItemLib.RequestPremiumLockboxKey()
	else
		AccountItemLib.RequestDailyLoginRewards()--Will get DailyLoginUpdate event once the rewards have been claimed.
	end
end

function DailyRewards:OnDailyLoginItemMouseEnter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local bMilestone = wndHandler:GetData()
	if bMilestone then
		Sound.Play(Sound.PlayUILoginRewardsPurpleHover)
	end
end

function DailyRewards:OnGenerateRewardItemTooltip(wndHandler, wndControl, eToolTipType, x, y)
	local itemReward = wndControl:GetData()
	if itemReward then--Some rewards don't have items
		local tPrimaryTooltipOpts =
		{
			bPrimary = true,
			itemCompare = itemReward:GetEquippedItemForItemType()
		}
		
		if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
			Tooltip.GetItemTooltipForm(self, wndControl, itemReward, tPrimaryTooltipOpts)
		end
	end
end

function DailyRewards:OnClose()
	self.wndMain:Close() 
	if self.timerUpdateText then
		self.timerUpdateText:Stop()
	end
end


-----------------------------------------------------------------------------------------------
-- DailyRewards Instance
-----------------------------------------------------------------------------------------------
local DailyRewardsInst = DailyRewards:new()
DailyRewardsInst:Init()
