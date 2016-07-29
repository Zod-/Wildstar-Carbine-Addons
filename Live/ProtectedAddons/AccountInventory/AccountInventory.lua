-----------------------------------------------------------------------------------------------
-- Client Lua Script for AccountInventory
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "AccountItemLib"
require "CREDDExchangeLib"
require "FriendshipLib"
require "Item"

local AccountInventory = {}

local knBoomBoxItemId = 44359
local keCreddType = -1 * AccountItemLib.CodeEnumAccountCurrency.CREDD -- Negative to avoid collision with ID 1
local knMinGiftDays = 2
local ktResultErrorCodeStrings =
{
	[CREDDExchangeLib.CodeEnumAccountOperationResult.GenericFail] = "MarketplaceCredd_Error_GenericFail",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.DBError] = "MarketplaceCredd_Error_GenericFail",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidOffer] = "MarketplaceCredd_Error_InvalidOffer",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidPrice] = "MarketplaceCredd_Error_InvalidPrice",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NotEnoughCurrency] = "GenericError_Vendor_NotEnoughCash",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NeedTransaction] = "MarketplaceCredd_Error_GenericFail",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidAccountItem] = "MarketplaceAuction_InvalidItem",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidPendingItem] = "MarketplaceAuction_InvalidItem",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidInventoryItem] = "MarketplaceAuction_InvalidItem",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NoConnection] = "MarketplaceCredd_Error_Connection",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NoCharacter] = "MarketplaceCredd_Error_GenericFail",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.AlreadyClaimed] = "MarketplaceCredd_Error_AlreadyClaimed",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.MaxEntitlementCount] = "MarketplaceCredd_Error_MaxEntitlement",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NoRegift] = "MarketplaceCredd_Error_CantGift",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NoGifting] = "MarketplaceCredd_Error_CantGift",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidFriend] = "MarketplaceCredd_Error_InvalidFriend",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidCoupon] = "MarketplaceCredd_Error_InvalidCoupon",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.CannotReturn] = "MarketplaceCredd_Error_CantReturn",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.Prereq] = "MarketplaceCredd_Error_Prereq",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.CREDDExchangeNotLoaded] = "MarketplaceCredd_Error_Busy",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NoCREDD] = "MarketplaceCredd_Error_NoCredd",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.NoMatchingOrder] = "MarketplaceCredd_Error_NoMatch",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.InvalidCREDDOrder] = "MarketplaceCredd_Error_GenericFail",
	[CREDDExchangeLib.CodeEnumAccountOperationResult.AlreadyClaimedMultiRedeem] = "AccountInventory_Error_AlreadyClaimedMultiRedeem",
}

local ktCurrencies =
{
	[AccountItemLib.CodeEnumAccountCurrency.CREDD] =
	{
		strTooltip = "AccountInventory_CreddTooltip",
		bShowInList = true,
	},
	[AccountItemLib.CodeEnumAccountCurrency.NameChange] =
	{
		strTooltip = "AccountInventory_NameChangeTooltip",
		bShowInList = true,
	},
	[AccountItemLib.CodeEnumAccountCurrency.RealmTransfer] =
	{
		strTooltip = "AccountInventory_RealmTransferTooltip",
		bShowInList = true,
	},
}

local nBuffer = 165 -- Buffer for resizing popup containers
local nAlertBuffer = 192 -- Buffer for resizing popup alerts
local nMaxHeight = 500 -- Max height for container resizing

function AccountInventory:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.tWndRefs = {}
	o.arAccountItems = {}
	o.arPendingAccountItems = {}

    return o
end

function AccountInventory:Init()
    Apollo.RegisterAddon(self)
end

function AccountInventory:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("AccountInventory.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function AccountInventory:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("AccountOperationResults", 				"OnAccountOperationResults", self) -- TODO
	Apollo.RegisterEventHandler("ShowDialog", 							"OnShowDialog", self)
	Apollo.RegisterEventHandler("CloseDialog", 							"OnCloseDialog", self)
	Apollo.RegisterEventHandler("FriendshipRemove", 					"OnFriendshipRemove", self)

	Apollo.RegisterEventHandler("AccountPendingItemsUpdate", 			"OnAccountPendingItemsUpdate", self)
	Apollo.RegisterEventHandler("AccountInventoryUpdate", 				"OnAccountInventoryUpdate", self)
	Apollo.RegisterEventHandler("AccountCurrencyChanged",				"RefreshInventory", self)
	
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate", 			"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate", 			"OnEntitlementUpdate", self)

	Apollo.RegisterTimerHandler("AccountInventory_RefreshInventory",	"OnAccountInventory_RefreshInventory", self)
	Apollo.CreateTimer("AccountInventory_RefreshInventory", 5, false)
	Apollo.StopTimer("AccountInventory_RefreshInventory")

	self.bRefreshInventoryThrottle = false

	for idx, eAccountCurrencyType in pairs(AccountItemLib.CodeEnumAccountCurrency) do
		if ktCurrencies[eAccountCurrencyType] == nil then
			ktCurrencies[eAccountCurrencyType] = {}
		end

		ktCurrencies[eAccountCurrencyType].eType = eAccountCurrencyType

		local monObj = Money.new()
		monObj:SetAccountCurrencyType(eAccountCurrencyType)
		local denomInfo = monObj:GetDenomInfo()[1]
		ktCurrencies[eAccountCurrencyType].strIcon = denomInfo.strSprite
	end
	
	self.arAccountItems = AccountItemLib.GetAccountItems()
	self.arPendingAccountItems = AccountItemLib.GetPendingAccountItemGroups()
end

function AccountInventory:OnAccountPendingItemsUpdate()
	self.arPendingAccountItems = AccountItemLib.GetPendingAccountItemGroups()
	
	if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() and self.tWndRefs.wndMain:IsShown() then
		self:RefreshInventory()
	end
end

function AccountInventory:OnAccountInventoryUpdate()
	self.arAccountItems = AccountItemLib.GetAccountItems()
	
	if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() and self.tWndRefs.wndMain:IsShown() then
		self:RefreshInventory()
	end
end

function AccountInventory:OnAccountInventoryCancelSignal()
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
		AccountItemLib.MarkAllInventoryItemsAsSeen()
		AccountItemLib.MarkAllPendingItemsAsSeen()
		self.tWndRefs.wndMain:Show(false)
		self.tWndRefs.wndParent:Show(false)
		Event_FireGenericEvent("CloseDialog")
	end
end

function AccountInventory:OnCloseDialog()
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain:Show(false)
	end
end

function AccountInventory:OnShowDialog(strDialogName, wndParent)
	if strDialogName ~= "AccountInventory" then
		if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
			self.tWndRefs.wndMain:Show(false)
		end
		return
	end
	
	self:OnOpenAccountInventoryDialog(wndParent)
end

function AccountInventory:OnOpenAccountInventoryDialog(wndParent)
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndParent = wndParent
		self:SetupMainWindow(wndParent)
	else
		self.unitPlayer = GameLib.GetPlayerUnit()

		self.bHasFraudCheck = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.FraudCheck) ~= 0
		
		self:ResetFilters()
		self:RefreshInventory()	
	end
	
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryGift:Show(false, true)
	
	self.tWndRefs.wndMain:Show(true)
end

function AccountInventory:OnAccountOperationResults(eOperationType, eResult)
	local bSuccess = eResult == CREDDExchangeLib.CodeEnumAccountOperationResult.Ok
	local strMessage = ""
	if bSuccess then
		strMessage = Apollo.GetString("MarketplaceCredd_TransactionSuccess")
	elseif ktResultErrorCodeStrings[eResult] then
		strMessage = Apollo.GetString(ktResultErrorCodeStrings[eResult])
	else
		strMessage = Apollo.GetString("MarketplaceCredd_Error_GenericFail")
	end
	Event_FireGenericEvent("GenericEvent_SystemChannelMessage", strMessage)

	-- Immediately close if you redeemed CREDD, so we can see the spell effect
	if bSuccess and eOperationType == CREDDExchangeLib.CodeEnumAccountOperation.CREDDRedeem then
		if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
			self.tWndRefs.wndMain:Close()
		end
		return
	end
	
	if eOperationType == AccountItemLib.CodeEnumAccountOperation.TakeItem and bSuccess then
		local this = self
		Promise.NewFromGameEvent("UpdateInventory", self):Then(function()
			this:RefreshInventory()
		end)
	end
end

-----------------------------------------------------------------------------------------------
-- Main
-----------------------------------------------------------------------------------------------

function AccountInventory:SetupMainWindow(wndParent)
	self.tWndRefs.wndMain = Apollo.LoadForm(self.xmlDoc, "AccountInventoryForm", wndParent, self)
	self.tWndRefs.wndMain:Invoke()
	
	--Containers
	self.tWndRefs.wndInventory = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory")
	self.tWndRefs.wndInventoryGift = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryGift")
	self.tWndRefs.wndInventoryRedeemCreddConfirm = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryRedeemCreddConfirm")

	--Inventory
	self.tWndRefs.wndInventoryContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container")
	self.tWndRefs.wndInventoryValidationNotification = self.tWndRefs.wndMain:FindChild("ValidationNotification")
	self.tWndRefs.wndInventoryGridContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:InventoryGridContainer")
	self.tWndRefs.wndInventoryGiftBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:GiftBtn")
	self.tWndRefs.wndInventoryGiftTwoFactorNotice = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:GiftTwoFactorNotice")
	self.tWndRefs.wndInventoryGiftHoldNotice = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:GiftHoldNotice")
	self.tWndRefs.wndInventoryTakeBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:TakeBtn")
	self.tWndRefs.wndInventoryRedeemCreddBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:RedeemBtn")
	self.tWndRefs.wndInventoryReturnBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:ReturnGiftBtn")
	
	self.tWndRefs.wndInventoryFilterLockedBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:InventoryFilterLockedBtn")
	self.tWndRefs.wndInventoryFilterBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:FilterBtn")
	self.tWndRefs.wndInventoryRefreshAnimation = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:RefreshAnimation")
	self.tWndRefs.wndInventoryFilterClearBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:ClearFilterBtn")
	self.tWndRefs.wndInventoryFilterDropDown = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:FilterBtn:FilterDropDown")
	self.tWndRefs.wndInventoryFilterBtnContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:FilterBtn:FilterDropDown:FilterBtnContainer")
	self.tWndRefs.wndInventoryFilterMountsBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:FilterBtn:FilterDropDown:FilterBtnContainer:InventoryFilterMountsBtn")
	self.tWndRefs.wndInventoryFilterPetsBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:FilterBtn:FilterDropDown:FilterBtnContainer:InventoryFilterPetsBtn")
	self.tWndRefs.wndInventoryFilterHousingBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:FilterBtn:FilterDropDown:FilterBtnContainer:InventoryFilterHousingBtn")
	self.tWndRefs.wndInventoryFilterCostumeBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:FilterBtn:FilterDropDown:FilterBtnContainer:InventoryFilterCostumeBtn")
	self.tWndRefs.wndInventoryFilterDyeBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:FilterBtn:FilterDropDown:FilterBtnContainer:InventoryFilterDyeBtn")
	self.tWndRefs.wndInventoryFilterConsumableBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:FilterBtn:FilterDropDown:FilterBtnContainer:InventoryFilterConsumableBtn")
	self.tWndRefs.wndInventoryFilterLootBagBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:FilterBtn:FilterDropDown:FilterBtnContainer:InventoryFilterLootBagBtn")
	self.tWndRefs.wndInventoryFilterToyBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:Inventory:Container:FilterBtn:FilterDropDown:FilterBtnContainer:InventoryFilterToyBtn")
	
	
	self.tWndRefs.wndInventoryFilterBtn:AttachWindow(self.tWndRefs.wndInventoryFilterDropDown)

	--Inventory Confirm
	self.tWndRefs.wndPendingClaimContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryClaimConfirm:Container:PendingClaimContainer")
	self.tWndRefs.wndInventoryTakeConfirmContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryTakeConfirm:Container:TakeContainer")
	self.tWndRefs.wndInventoryCreddRedeemConfirmContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryRedeemCreddConfirm:Container:RedeemContainer")

	--Inventory Gift
	self.tWndRefs.wndInventoryGiftFriendContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryGift:Container:FriendContainer")
	self.tWndRefs.wndInventoryGiftFriendSelectBtn = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryGift:Container:GiftBtn")
	self.tWndRefs.wndInventoryGiftConfirmItemContainer = self.tWndRefs.wndMain:FindChild("ContentContainer:InventoryGiftConfirm:Container:InventoryGiftConfirmItemContainer")

	self.unitPlayer = GameLib.GetPlayerUnit()

	self.bHasFraudCheck = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.FraudCheck) ~= 0
	
	self:ResetFilters()
	self:RefreshInventory()
end

function AccountInventory:OnInventoryCheck(wndHandler, wndControl, eMouseButton)
	self:OnInventoryUncheck()
	self.tWndRefs.wndInventory:Show(true)
end

function AccountInventory:OnInventoryUncheck(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventory:Show(false)
	self.tWndRefs.wndInventoryGift:Show(false)
	self.tWndRefs.wndInventoryRedeemCreddConfirm:Show(false)
end

--[[
Inventory
]]--

function AccountInventory:HelperAddPendingSingleToContainer(wndParent, tPendingAccountItem)
	local strName = ""
	local strIcon = ""
	local strTooltip = ""
	local tPrereqInfo = self.unitPlayer and self.unitPlayer:GetPrereqInfo(tPendingAccountItem.prereqId) or nil
	local bShowLock = tPrereqInfo and not tPrereqInfo.bIsMet

	if tPendingAccountItem.item then
		strName = tPendingAccountItem.item:GetName()
		strIcon = tPendingAccountItem.item:GetIcon()
		-- No strTooltip Needed
	elseif tPendingAccountItem.entitlement and Apollo.StringLength(tPendingAccountItem.entitlement.name) > 0 then
		strName = String_GetWeaselString(Apollo.GetString("AccountInventory_EntitlementPrefix"), tPendingAccountItem.entitlement.name)
		if tPendingAccountItem.entitlement.maxCount > 1 then
			strName = String_GetWeaselString(Apollo.GetString("CRB_EntitlementCount"), strName, tPendingAccountItem.entitlement.count)
		end
		strIcon = tPendingAccountItem.entitlement.icon or strIcon
		strTooltip = tPendingAccountItem.entitlement.description
	elseif tPendingAccountItem.accountCurrency then
		strName = tPendingAccountItem.accountCurrency.monCurrency:GetMoneyString(false)
		strIcon = tPendingAccountItem.icon
		strTooltip = Apollo.GetString(ktCurrencies[tPendingAccountItem.accountCurrency.accountCurrencyEnum].strTooltip or "")
	else -- Error Case
		return
	end

	local wndGroup = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupForm", wndParent, self)
	wndGroup:SetData({bIsGroup = false, tData = tPendingAccountItem})
	wndGroup:FindChild("ItemButton"):SetText(String_GetWeaselString("$1n", strName))
	wndGroup:FindChild("ItemIconGiftable"):Show(tPendingAccountItem.canGift)
	wndGroup:FindChild("NewItemRunner"):Show(tPendingAccountItem.bIsNew)
	local wndGroupContainer = wndGroup:FindChild("ItemContainer")
	local wndObject = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupItemForm", wndGroupContainer, self)
	wndObject:SetData(tPendingAccountItem)
	wndObject:FindChild("Name"):SetText("") -- Done at ItemButton if single, Only used by Groups
	wndObject:FindChild("Icon"):SetSprite(bShowLock and "CRB_AMPs:spr_AMPs_LockStretch_Blue" or strIcon)

	-- Icons for the number of redempetions / cooldowns
	if tPendingAccountItem.multiRedeem then -- Should be only multiRedeem
		local bShowCooldown = tPendingAccountItem.cooldown and tPendingAccountItem.cooldown > 0
		wndGroup:FindChild("ItemIconText"):Show(bShowCooldown)
		wndGroup:FindChild("ItemIconText"):SetText(bShowCooldown and self:HelperCooldown(tPendingAccountItem.cooldown) or "")
	end
	wndGroup:FindChild("ItemIconMultiClaim"):Show(tPendingAccountItem.multiRedeem)
	wndGroup:FindChild("ItemIconArrangeVert"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)

	-- Tooltip
	if bShowLock and tPrereqInfo.strText then
		wndObject:SetTooltip(tPrereqInfo.strText)
	elseif tPendingAccountItem.item then
		Tooltip.GetItemTooltipForm(self, wndObject, tPendingAccountItem.item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	else
		wndObject:SetTooltip(strTooltip or "")
	end

	local nHeightBuffer = wndGroup:GetHeight() - wndGroupContainer:GetHeight()
	local nHeight = wndGroup:FindChild("ItemContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nLeft, nTop, nRight, nBottom = wndGroup:GetAnchorOffsets()
	wndGroup:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + nHeightBuffer)
	wndParent:RecalculateContentExtents()
end

function AccountInventory:HelperAddPendingGroupToContainer(wndParent, tPendingAccountItemGroup)
	local wndGroup = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupForm", wndParent, self)
	wndGroup:SetData({bIsGroup = true, tData = tPendingAccountItemGroup})
	wndGroup:FindChild("ItemButton"):SetText("")

	local bIsNew = false
	local bIsMultiRedeem = false
	
	local wndGroupContainer = wndGroup:FindChild("ItemContainer")
	for idx, tPendingAccountItem in pairs(tPendingAccountItemGroup.items) do
		local wndObject = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupItemForm", wndGroupContainer, self)
		wndObject:SetData(tPendingAccountItem)

		local strName = ""
		local strIcon = ""
		local strTooltip = ""
		local tPrereqInfo = self.unitPlayer and self.unitPlayer:GetPrereqInfo(tPendingAccountItem.prereqId) or nil
		local bShowLock = tPrereqInfo and not tPrereqInfo.bIsMet

		if tPendingAccountItem.item then
			strName = tPendingAccountItem.item:GetName()
			strIcon = tPendingAccountItem.item:GetIcon()
			-- No strTooltip Needed
		elseif tPendingAccountItem.staticItem then
			strName = tPendingAccountItem.staticItem.name
			strIcon = tPendingAccountItem.staticItem.icon
			-- No strTooltip Needed
		elseif tPendingAccountItem.entitlement and Apollo.StringLength(tPendingAccountItem.entitlement.name) > 0 then
			strName = tPendingAccountItem.entitlement.name
			if tPendingAccountItem.entitlement.maxCount > 1 then
				strName = String_GetWeaselString(Apollo.GetString("CRB_EntitlementCount"), strName, tPendingAccountItem.entitlement.count)
			end
			strIcon = tPendingAccountItem.entitlement.icon
			strTooltip = tPendingAccountItem.entitlement.description
		elseif tPendingAccountItem.accountCurrency then
			strName = tPendingAccountItem.accountCurrency.monCurrency:GetMoneyString(false)
			strIcon = ktCurrencies[tPendingAccountItem.accountCurrency.accountCurrencyEnum].strIcon or ""
			strTooltip = Apollo.GetString(ktCurrencies[tPendingAccountItem.accountCurrency.accountCurrencyEnum].strTooltip or "")
		else -- Error Case
			strName = Apollo.GetString("CRB_ModuleStatus_Invalid")
			strIcon = "BK3:UI_BK3_StoryPanelAlert_Icon"
		end
		wndObject:FindChild("Name"):SetText(String_GetWeaselString("$1n", strName))
		wndObject:FindChild("Icon"):SetSprite(bShowLock and "CRB_AMPs:spr_AMPs_LockStretch_Blue" or strIcon)
		bIsNew = bIsNew or tPendingAccountItem.bIsNew
		bIsMultiRedeem = bIsMultiRedeem or tPendingAccountItem.multiRedeem

		if tPendingAccountItemGroup.giftReturnTimeRemaining ~= nil and tPendingAccountItemGroup.giftReturnTimeRemaining > 0 then--Seconds
			local wndItemIconWasGifted = wndGroup:FindChild("ItemIconWasGifted")
			wndItemIconWasGifted:Show(true)

			local nSecs = tPendingAccountItemGroup.giftReturnTimeRemaining
			local nDays = math.floor(nSecs/ 86400)
			nSecs = nSecs - (nDays * 86400)

			local nHours = math.floor(nSecs/ 3600)
			nSecs = nSecs - (nHours * 3600)

			local nMins = math.floor(nSecs/ 60)
			nSecs = nSecs - (nMins * 60)

			local strTime = ""
			local strTimeColor = ""
			local strIcon = ""
			if nDays > 0 or nHours > 0 then
				strTime = String_GetWeaselString(Apollo.GetString("AccountInventory_TimeDayHour"), nDays, nHours)
				if nDays < knMinGiftDays or nDays == knMinGiftDays and nHours == 0 then
					strTimeColor = "UI_WindowTextRed"
					strIcon = "BK3:UI_BK3_AccountInv_GiftRed"
				else
					strTimeColor = "UI_WindowTitleYellow"
					strIcon = "BK3:UI_BK3_AccountInv_GiftYellow"
				end
			elseif nMins > 0 then
				strTime = String_GetWeaselString(Apollo.GetString("AccountInventory_TimeMin"), nMins)
				strIcon = "BK3:UI_BK3_AccountInv_GiftRed"
				strTimeColor = "UI_WindowTextRed"
			else
				strTime = String_GetWeaselString(Apollo.GetString("AccountInventory_TimeSec"), nSecs)
				strIcon = "BK3:UI_BK3_AccountInv_GiftRed"
				strTimeColor = "UI_WindowTextRed"
			end

			local wndTimer = wndItemIconWasGifted:FindChild("Timer")
			if wndTimer ~= nil then
				wndTimer:SetText(strTime)
				wndTimer:SetTextColor(strTimeColor)
			end
			wndItemIconWasGifted:FindChild("Icon"):SetSprite(strIcon)
		end

		-- Tooltip
		if bShowLock then
			wndObject:SetTooltip(tPrereqInfo.strText)
		elseif tPendingAccountItem.item then
			Tooltip.GetItemTooltipForm(self, wndObject, tPendingAccountItem.item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
		else
			wndObject:SetTooltip(strTooltip)
		end
	end
	
	wndGroup:FindChild("ItemIconGiftable"):Show(tPendingAccountItemGroup.canGift)
	wndGroup:FindChild("NewItemRunner"):Show(bIsNew)
	wndGroup:FindChild("ItemIconMultiClaim"):Show(bIsMultiRedeem)
	wndGroup:FindChild("ItemIconArrangeVert"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)

	if #wndGroupContainer:GetChildren() == 0 then -- Error Case
		wndGroup:Destroy()
		return
	end

	local nHeightBuffer = wndGroup:GetHeight() - wndGroupContainer:GetHeight()
	local nHeight = wndGroupContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nLeft, nTop, nRight, nBottom = wndGroup:GetAnchorOffsets()
	wndGroup:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + nHeightBuffer)
	
	wndParent:RecalculateContentExtents()
end

function AccountInventory:OnAccountInventory_RefreshInventory()
	Apollo.StopTimer("AccountInventory_RefreshInventory")
	self.bRefreshInventoryThrottle = false
end

function AccountInventory:ResetFilters()
	self.tWndRefs.wndInventoryFilterMountsBtn:SetCheck(false)
	self.tWndRefs.wndInventoryFilterPetsBtn:SetCheck(false)
	self.tWndRefs.wndInventoryFilterHousingBtn:SetCheck(false)
	self.tWndRefs.wndInventoryFilterCostumeBtn:SetCheck(false)
	self.tWndRefs.wndInventoryFilterDyeBtn:SetCheck(false)
	self.tWndRefs.wndInventoryFilterConsumableBtn:SetCheck(false)
	self.tWndRefs.wndInventoryFilterLootBagBtn:SetCheck(false)
	self.tWndRefs.wndInventoryFilterToyBtn:SetCheck(false)
	
	self.tWndRefs.wndInventoryFilterClearBtn:Show(false)
end

function AccountInventory:RefreshInventory()
	if not self.bRefreshInventoryThrottle then
		self.bRefreshInventoryThrottle = true
		Apollo.StartTimer("AccountInventory_RefreshInventory")
	end

	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	local nInventoryGridScrollPos = self.tWndRefs.wndInventoryGridContainer:GetVScrollPos()
	self.tWndRefs.wndInventoryGridContainer:DestroyChildren()

	-- Filter settings
	local tInventoryFilters = self.tWndRefs.wndInventoryFilterBtnContainer:GetChildren()
	local bShowAll = true
	
	for idx, wndFilter in pairs(tInventoryFilters) do
		if wndFilter:IsChecked() then
			bShowAll = false
		end
	end
	
	self.tWndRefs.wndInventoryFilterClearBtn:Show(not bShowAll)
	
	local bHideLocked = self.tWndRefs.wndInventoryFilterLockedBtn:IsChecked()
	local bShowMounts = self.tWndRefs.wndInventoryFilterMountsBtn:IsChecked()
	local bShowPets = self.tWndRefs.wndInventoryFilterPetsBtn:IsChecked()
	local bShowHousing = self.tWndRefs.wndInventoryFilterHousingBtn:IsChecked()
	local bShowCostume = self.tWndRefs.wndInventoryFilterCostumeBtn:IsChecked()
	local bShowDye = self.tWndRefs.wndInventoryFilterDyeBtn:IsChecked()		
	local bShowConsumable = self.tWndRefs.wndInventoryFilterConsumableBtn:IsChecked()		
	local bShowLootBag = self.tWndRefs.wndInventoryFilterLootBagBtn:IsChecked()		
	local bShowToy = self.tWndRefs.wndInventoryFilterToyBtn:IsChecked()
	
	-- Currencies
	for idx, tCurrData in pairs(ktCurrencies) do
		local monCurrency = AccountItemLib.GetAccountCurrency(tCurrData.eType)
		if not monCurrency:IsZero() and tCurrData.bShowInList then
			local wndGroup = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupForm", self.tWndRefs.wndInventoryGridContainer, self)
			wndGroup:SetData(-1 * tCurrData.eType) -- Don't need to care about bIsGroup or anything
			wndGroup:FindChild("ItemButton"):SetText(monCurrency:GetMoneyString(false))

			local wndObject = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupItemForm", wndGroup:FindChild("ItemContainer"), self)
			wndObject:SetData(-1 * tCurrData.eType) -- To avoid collision with ID 1,2,3
			wndObject:FindChild("Name"):SetText("")
			wndObject:FindChild("Icon"):SetSprite(tCurrData.strIcon)
			wndObject:SetTooltip(Apollo.GetString(tCurrData.strTooltip or ""))
		end
	end

	-- Boom Boxes (Account Bound only, not Escrow)
	local nBoomBoxCount = 0
	local tBoomBoxData = nil
	local arAccountItems = self.arAccountItems
	for idx, tAccountItem in ipairs(arAccountItems) do
		if tAccountItem.item and tAccountItem.item:GetItemId() == knBoomBoxItemId then
			tBoomBoxData = tAccountItem
			nBoomBoxCount = nBoomBoxCount + 1
		end
	end

	if nBoomBoxCount > 0 then
		local wndGroup = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupForm", self.tWndRefs.wndInventoryGridContainer, self)
		wndGroup:SetData({bIsGroup = false, tData = tBoomBoxData})
		wndGroup:FindChild("ItemButton"):SetText(String_GetWeaselString(Apollo.GetString("MarketplaceCommodity_MultiItem"), nBoomBoxCount, tBoomBoxData.item:GetName()))
		wndGroup:FindChild("ItemIconText"):Show(tBoomBoxData.cooldown and tBoomBoxData.cooldown > 0)
		wndGroup:FindChild("ItemIconText"):SetText(tBoomBoxData.cooldown and self:HelperCooldown(tBoomBoxData.cooldown) or "")
		wndGroup:FindChild("ItemIconArrangeVert"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)

		local wndObject = Apollo.LoadForm(self.xmlDoc, "InventoryPendingGroupItemForm", wndGroup:FindChild("ItemContainer"), self)
		wndObject:SetData(tBoomBoxData)
		wndObject:FindChild("Name"):SetText("")
		wndObject:FindChild("Icon"):SetSprite(tBoomBoxData.item:GetIcon())
	end

	-- Separator if we added at least one
	if next(self.tWndRefs.wndInventoryGridContainer:GetChildren()) ~= nil then
		Apollo.LoadForm(self.xmlDoc, "InventoryHorizSeparator", self.tWndRefs.wndInventoryGridContainer, self)
	end

	-- Account Bound Inventory
	table.sort(arAccountItems, function(a,b) return a.index > b.index end)
	for idx, tAccountItem in ipairs(arAccountItems) do
		if not tAccountItem.item or tAccountItem.item:GetItemId() ~= knBoomBoxItemId then
			local tPrereqInfo = self.unitPlayer and self.unitPlayer:GetPrereqInfo(tAccountItem.prereqId) or nil	
			local eItemType = 0
			local eItemFamily = 0
			local bHideEntry =  bHideLocked and tPrereqInfo ~= nil and not tPrereqInfo.bIsMet
			if tAccountItem.item ~= nil then
				eItemType = tAccountItem.item:GetItemType()
				eItemFamily = tAccountItem.item:GetItemFamily()
				eItemCategory = tAccountItem.item:GetItemCategory()
			end
			
			if not bShowAll then
				bHideEntry = (not bShowPets and tAccountItem.bIsPetUnlock)
				or (bHideLocked and tPrereqInfo ~= nil and not tPrereqInfo.bIsMet)
				or (not bShowMounts and tAccountItem.bIsMountUnlock)
				or (not bShowHousing and (eItemType == Item.CodeEnumItemType.Decor or eItemType == Item.CodeEnumItemType.HousingSky or eItemType == Item.CodeEnumItemType.HousingMusic  or eItemType == Item.CodeEnumItemType.HousingChest or eItemType == Item.CodeEnumItemType.HousingPlug))
				or (not bShowCostume and eItemFamily == Item.CodeEnumItem2Family.Costume)
				or (not bShowConsumable and (eItemFamily == Item.CodeEnumItem2Family.Consumable and eItemType == Item.CodeEnumItemType.OtherConsumable and eItemCategory == Item.CodeEnumItem2Category.OtherConsumable))
				or (not bShowLootBag and (eItemType == Item.CodeEnumItemType.GenericLootBag and eItemCategory == Item.CodeEnumItem2Category.LootBag))
				or (not bShowDye and (eItemType == Item.CodeEnumItemType.Dye or eItemType == Item.CodeEnumItemType.DyeCollection or eItemType == Item.CodeEnumItemType.DyeBag))
				or (not bShowToy and eItemType == Item.CodeEnumItemType.Toy) 
			end
							
			if not bHideEntry then
				self:HelperAddPendingSingleToContainer(self.tWndRefs.wndInventoryGridContainer, tAccountItem)
			end
		end
	end
	
	-- Escrow Groups
	local bWasGifted = false
	local arAccountItemGroups = self.arPendingAccountItems
	table.sort(arAccountItemGroups, 
		function(a,b) 
			if a.giftReturnTimeRemaining ~= nil and b.giftReturnTimeRemaining ~= nil then
				return a.index > b.index 
			elseif a.giftReturnTimeRemaining ~= nil then
				return true
			elseif b.giftReturnTimeRemaining ~= nil then
				return false
			end
			return a.index > b.index 
		end
		)
	for idx, tPendingAccountItemGroup in pairs(arAccountItemGroups) do
		if not bWasGifted and tPendingAccountItemGroup.giftReturnTimeRemaining ~= nil then
			bWasGifted = true
		elseif bWasGifted and tPendingAccountItemGroup.giftReturnTimeRemaining == nil then
			bWasGifted = false
			Apollo.LoadForm(self.xmlDoc, "InventoryHorizSeparator", self.tWndRefs.wndInventoryGridContainer, self)
		end
		
		local bHideEntry = true
		
		for idx, tAccountItem in pairs(tPendingAccountItemGroup.items) do
			local tPrereqInfo = self.unitPlayer and self.unitPlayer:GetPrereqInfo(tAccountItem.prereqId) or nil	
			local eItemType = 0
			local eItemFamily = 0
			if tAccountItem.item ~= nil then
				eItemType = tAccountItem.item:GetItemType()
				eItemFamily = tAccountItem.item:GetItemFamily()
			end
			
			if bShowAll then
				bHideEntry = bHideLocked and tPrereqInfo ~= nil and not tPrereqInfo.bIsMet
			else
				bHideEntry = bHideEntry and (not bShowPets and tAccountItem.bIsPetUnlock)
				or (bHideLocked and tPrereqInfo ~= nil and not tPrereqInfo.bIsMet)
				or (not bShowMounts and tAccountItem.bIsMountUnlock)
				or (not bShowHousing and (eItemType == Item.CodeEnumItemType.Decor or eItemType == Item.CodeEnumItemType.HousingSky or eItemType == Item.CodeEnumItemType.HousingMusic  or eItemType == Item.CodeEnumItemType.HousingChest or eItemType == Item.CodeEnumItemType.HousingPlug))
				or (not bShowCostume and eItemFamily == Item.CodeEnumItem2Family.Costume)
				or (not bShowConsumable and (eItemFamily == Item.CodeEnumItem2Family.Consumable and eItemType == Item.CodeEnumItemType.OtherConsumable and eItemCategory == Item.CodeEnumItem2Category.OtherConsumable))
				or (not bShowLootBag and (eItemType == Item.CodeEnumItemType.GenericLootBag and eItemCategory == Item.CodeEnumItem2Category.LootBag))
				or (not bShowDye and (eItemType == Item.CodeEnumItemType.Dye or eItemType == Item.CodeEnumItemType.DyeCollection or eItemType == Item.CodeEnumItemType.DyeBag))
				or (not bShowToy and eItemType == Item.CodeEnumItemType.Toy) 
			end
		end 

		tPendingAccountItemGroup.bIsPending = true
		
		if not bHideEntry then
			self:HelperAddPendingGroupToContainer(self.tWndRefs.wndInventoryGridContainer, tPendingAccountItemGroup)
		end
	end
	
	
	self.tWndRefs.wndInventoryGridContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.tWndRefs.wndInventoryGridContainer:RecalculateContentExtents()
	self.tWndRefs.wndInventoryGridContainer:SetVScrollPos(math.min(nInventoryGridScrollPos, self.tWndRefs.wndInventoryGridContainer:GetVScrollRange()))
	self.tWndRefs.wndInventoryRefreshAnimation:SetSprite("BK3:UI_BK3_Holo_RefreshReflectionSquare_anim")
	self:UpdateValidationNotifications()
end

function AccountInventory:RefreshInventoryActions()
	local wndSelectedPendingItem

	local wndSelectedItem
	for idx, wndItem in pairs(self.tWndRefs.wndInventoryGridContainer:GetChildren()) do
		if wndItem:FindChild("ItemButton") and wndItem:FindChild("ItemButton"):IsChecked() then -- Could be a divider
			wndSelectedItem = wndItem
			break
		end
	end

	local bPendingNeedsTwoFactorToGift = GameLib.GetGameMode() ~= GameLib.CodeEnumGameMode.China and AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.TwoStepVerification) <= 0
	local tSelectedPendingData = wndSelectedPendingItem ~= nil and wndSelectedPendingItem:GetData() or nil
	local tSelectedData = wndSelectedItem ~= nil and wndSelectedItem:GetData() or nil
	if tSelectedData and type(tSelectedData) == "table" and tSelectedData.tData and tSelectedData.tData.bIsPending then
		tSelectedPendingData = tSelectedData
		tSelectedData = nil
	end
	
	local bPendingCanClaim = tSelectedPendingData ~= nil and tSelectedPendingData.tData.canClaim
	local bPendingCanGift = tSelectedPendingData ~= nil and tSelectedPendingData.tData.canGift
	local bPendingCanReturn = tSelectedPendingData ~= nil and tSelectedPendingData.tData.canReturn

	if tSelectedPendingData ~= nil and not bPendingCanClaim then
		if self.bHasFraudCheck then
			self.tWndRefs.wndInventoryTakeBtn:SetTooltip(Apollo.GetString("AccountInventory_UnableToClaimPaidOrGiftAnyItemsP"))
		else
			self.tWndRefs.wndInventoryTakeBtn:SetTooltip(Apollo.GetString("AccountInventory_CantClaimTooltip"))
		end
	else
		self.tWndRefs.wndInventoryTakeBtn:SetTooltip("")
	end
	
	if bPendingCanGift and bPendingNeedsTwoFactorToGift then
		self.tWndRefs.wndInventoryGiftBtn:Enable(false)
		self.tWndRefs.wndInventoryGiftBtn:SetTooltip(Apollo.GetString("Storefront_GiftingTwoFactorRequired"))	
	else
		self.tWndRefs.wndInventoryGiftBtn:Enable(true)
		self.tWndRefs.wndInventoryGiftBtn:SetTooltip("")	
	end
	
	self.tWndRefs.wndInventoryGiftBtn:Enable(bPendingCanGift and not bPendingNeedsTwoFactorToGift)
	self.tWndRefs.wndInventoryGiftBtn:SetData(tSelectedPendingData)
	self.tWndRefs.wndInventoryGiftBtn:Show(not bPendingCanReturn and #self.arPendingAccountItems > 0)
	self.tWndRefs.wndInventoryGiftTwoFactorNotice:Show(bPendingCanGift and bPendingNeedsTwoFactorToGift and not self.bHasFraudCheck)
	self.tWndRefs.wndInventoryGiftHoldNotice:Show(self.bHasFraudCheck)

	self.tWndRefs.wndInventoryReturnBtn:Enable(bPendingCanReturn)
	self.tWndRefs.wndInventoryReturnBtn:SetData(tSelectedPendingData)
	self.tWndRefs.wndInventoryReturnBtn:Show(bPendingCanReturn and #self.arPendingAccountItems > 0)
	
	-- Check if currency
	local bCanBeClaimed = true
	if tSelectedData and type(tSelectedData) == "table" and tSelectedData.tData and tSelectedData.tData.item and tSelectedData.tData.item:GetItemId() == knBoomBoxItemId then -- If BoomBox
		bCanBeClaimed = tSelectedData.tData.cooldown == 0
	elseif tSelectedData and type(tSelectedData) == "table" and tSelectedData.tData and type(tSelectedData.tData) == "number" then -- If Credd/NameChange/RealmTransfer
		bCanBeClaimed = tSelectedData.tData >= 0
	elseif tSelectedData and type(tSelectedData) == "table" and tSelectedData.tData then
		bCanBeClaimed = true
	elseif tSelectedData and type(tSelectedData) == "number" then -- Redundant check if Credd/NameChange/RealmTransfer
		bCanBeClaimed = tSelectedData >= 0
	end

	-- It's an item, check pre-reqs
	if bCanBeClaimed and tSelectedData and type(tSelectedData) == "table" and tSelectedData.tData and tSelectedData.tData.prereqId ~= nil and tSelectedData.tData.prereqId > 0 then
		local tPrereqInfo = GameLib.GetPlayerUnit():GetPrereqInfo(tSelectedData.tData.prereqId)
		bCanBeClaimed = tPrereqInfo and tPrereqInfo.bIsMet and tSelectedData.tData.canClaim
	end

	self.tWndRefs.wndInventoryTakeBtn:Enable((tSelectedData ~= nil and bCanBeClaimed) or (tSelectedPendingData ~= nil and bPendingCanClaim))
	if (tSelectedPendingData ~= nil and bPendingCanClaim) then
		self.tWndRefs.wndInventoryTakeBtn:SetData(tSelectedPendingData)
	else
		self.tWndRefs.wndInventoryTakeBtn:SetData(tSelectedData)
	end
	self.tWndRefs.wndInventoryTakeBtn:Show(tSelectedData ~= keCreddType or tSelectedPendingData ~= nil)
	self.tWndRefs.wndInventoryRedeemCreddBtn:Show(tSelectedPendingData == nil and tSelectedData == keCreddType and not AccountItemLib.IsRedeemCREDDInProgress())
end

function AccountInventory:OnPendingInventoryItemCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	local wndParent = wndControl:GetParent()
	local tAccountItemData = wndParent:GetData()
	if tAccountItemData and type(tAccountItemData) == "table" and tAccountItemData.tData.bIsNew then 
		wndParent:FindChild("NewItemRunner"):Show(false)
	end

	self:RefreshInventoryActions()
end

function AccountInventory:OnPendingInventoryItemUncheck(wndHandler, wndControl, eMouseButton)
	self:RefreshInventoryActions()
end

function AccountInventory:OnInventoryFilterToggle(wndHandler, wndControl)
	self.tWndRefs.wndInventoryGridContainer:SetVScrollPos(0)
	self.tWndRefs.wndInventoryGridContainer:SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")
	self:RefreshInventory()
end

function AccountInventory:OnPendingGiftBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventoryGift:SetData(wndControl:GetData())
	self:RefreshInventoryGift()

	self.tWndRefs.wndInventory:Show(false)
	self.tWndRefs.wndInventoryGift:Show(true)
end

function AccountInventory:OnInventoryTakeBtn(wndHandler, wndControl, eMouseButton)
	local tTakeData = wndHandler:GetData()
	
	if tTakeData.tData.bIsPending then
		AccountItemLib.ClaimPendingItemGroup(tTakeData.tData.index)
	else
		AccountItemLib.TakeAccountItem(tTakeData.tData.index)
	end
end

function AccountInventory:OnInventoryRedeemCreddBtn(wndHandler, wndControl, eMouseButton)
	local tCurrData = ktCurrencies[AccountItemLib.CodeEnumAccountCurrency.CREDD]
	
	AccountItemLib.RedeemCREDD()
	self:RefreshInventoryActions()
end

function AccountInventory:OnPendingReturnBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventoryGiftReturnConfirm:SetData(wndControl:GetData())
	self:RefreshInventoryGiftReturnConfirm()

	self.tWndRefs.wndInventory:Show(false)
	self.tWndRefs.wndInventoryGiftReturnConfirm:Show(true)
end

--[[
Inventory Claim Confirm
]]--

function AccountInventory:RefreshPendingConfirm()
	local tSelectedPendingData = self.tWndRefs.wndInventoryClaimConfirm:GetData()
	self.tWndRefs.wndPendingClaimContainer:DestroyChildren()

	local nIndex = tSelectedPendingData.tData.index
	local bIsGroup = tSelectedPendingData.bIsGroup

	self.tWndRefs.wndInventoryClaimConfirm:FindChild("ConfirmBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.AccountClaimItem, nIndex, bIsGroup)

	if tSelectedPendingData.bIsGroup then
		self:HelperAddPendingGroupToContainer(self.tWndRefs.wndPendingClaimContainer, tSelectedPendingData.tData)
	else
		self:HelperAddPendingSingleToContainer(self.tWndRefs.wndPendingClaimContainer, tSelectedPendingData.tData)
	end
	
	local nHeight = 0
	for idx, wndCurr in pairs(self.tWndRefs.wndPendingClaimContainer:GetChildren()) do
		wndCurr:Enable(false)
		if wndCurr:FindChild("ItemButton") then
			wndCurr:FindChild("ItemButton"):ChangeArt("BK3:btnHolo_ListView_SimpleDisabled")
		end
		nHeight = nHeight + wndCurr:FindChild("ItemButton"):GetHeight()
	end
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndInventoryClaimConfirm:FindChild("Container"):GetAnchorOffsets()
	self.tWndRefs.wndInventoryClaimConfirm:FindChild("Container"):SetAnchorOffsets(nLeft, -((nHeight + nBuffer)/2), nRight, (nHeight + nBuffer)/2)
	if self.tWndRefs.wndInventoryClaimConfirm:FindChild("Container"):GetHeight() > nMaxHeight then
		self.tWndRefs.wndInventoryClaimConfirm:FindChild("Container"):SetAnchorOffsets(self.tWndRefs.wndInventoryClaimConfirm:FindChild("Container"):GetOriginalLocation():GetOffsets())
	end
end

function AccountInventory:OnAccountPendingItemsClaimed(wndHandler, wndControl)
	self:RefreshInventory()
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryClaimConfirm:Show(false)
end

function AccountInventory:OnPendingConfirmCancelBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryClaimConfirm:Show(false)
end

--[[
Inventory Take Confirm
]]--

function AccountInventory:OnAccountPendingItemTook(wndHandler, wndControl)
	self:RefreshInventory()
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryTakeConfirm:Show(false)
end

function AccountInventory:OnInventoryTakeConfirmCancelBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryTakeConfirm:Show(false)
end

--[[
Inventory Credd Redeem Confirm
]]--

function AccountInventory:OnAccountCREDDRedeemed(wndHandler, wndControl)
	self:RefreshInventory()
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryRedeemCreddConfirm:Show(false)
end

function AccountInventory:OnInventoryCreddRedeemConfirmCancelBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryRedeemCreddConfirm:Show(false)
end

--[[
Inventory Gift
]]--


function AccountInventory:OnFriendshipRemove()
	if not self.tWndRefs.wndInventoryGift or not self.tWndRefs.wndInventoryGift:IsValid() then
		return
	end
	self.tWndRefs.wndInventoryGift:Show(false)
end

function AccountInventory:RefreshInventoryGift()
	local tSelectedPendingData = self.tWndRefs.wndInventoryGift:GetData()

	self.tWndRefs.wndInventoryGiftFriendContainer:DestroyChildren()
	for idx, tFriend in pairs(FriendshipLib.GetAccountList()) do
		local wndFriend = Apollo.LoadForm(self.xmlDoc, "FriendForm", self.tWndRefs.wndInventoryGiftFriendContainer, self)
		wndFriend:SetData(tFriend)
		wndFriend:FindChild("FriendNote"):SetTooltip(tFriend.strPrivateNote or "")
		wndFriend:FindChild("FriendNote"):Show(Apollo.StringLength(tFriend.strPrivateNote or "") > 0)
		wndFriend:FindChild("FriendButton"):SetText(String_GetWeaselString(Apollo.GetString("AccountInventory_AccountFriendPrefix"), tFriend.strCharacterName))
	end
	for idx, tFriend in pairs(FriendshipLib.GetList()) do
		if tFriend.bFriend then -- Not Ignore or Rival
			local wndFriend = Apollo.LoadForm(self.xmlDoc, "FriendForm", self.tWndRefs.wndInventoryGiftFriendContainer, self)
			wndFriend:SetData(tFriend)
			wndFriend:FindChild("FriendNote"):SetTooltip(tFriend.strNote or "")
			wndFriend:FindChild("FriendNote"):Show(Apollo.StringLength(tFriend.strNote or "") > 0)
			wndFriend:FindChild("FriendButton"):SetText(tFriend.strCharacterName)
		end
	end

	local wndInventoryGiftContainer = self.tWndRefs.wndInventoryGift:FindChild("Container")
	wndInventoryGiftContainer:FindChild("Title"):SetText(next(self.tWndRefs.wndInventoryGiftFriendContainer:GetChildren()) and Apollo.GetString("AccountInventory_ChooseFriendToGift") or Apollo.GetString("AccountInventory_NoFriendsToGiftTo"))
	local nHeightChange = self.tWndRefs.wndInventoryGiftFriendContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop) - self.tWndRefs.wndInventoryGiftFriendContainer:GetHeight()
	
	local nHeight = wndInventoryGiftContainer:GetHeight()
	local nLeft, nTop, nRight, nBottom = wndInventoryGiftContainer:GetAnchorOffsets()
	wndInventoryGiftContainer:SetAnchorOffsets(nLeft, -((nHeight + nHeightChange)/2), nRight, (nHeight + nHeightChange)/2)
	
	if wndInventoryGiftContainer:GetHeight() > nMaxHeight then
		wndInventoryGiftContainer:SetAnchorOffsets(wndInventoryGiftContainer:GetOriginalLocation():GetOffsets())
	end
	self:RefreshInventoryGiftActions()
end

function AccountInventory:RefreshInventoryGiftActions()
	local wndSelectedFriend

	for idx, wndFriend in pairs(self.tWndRefs.wndInventoryGiftFriendContainer:GetChildren()) do
		if wndFriend:FindChild("FriendButton"):IsChecked() then
			wndSelectedFriend = wndFriend
			break
		end
	end

	self.tWndRefs.wndInventoryGiftFriendSelectBtn:Enable(wndSelectedFriend ~= nil)
end

function AccountInventory:OnFriendCheck(wndHandler, wndControl, eMouseButton)
	self:RefreshInventoryGiftActions()
end

function AccountInventory:OnFriendUncheck(wndHandler, wndControl, eMouseButton)
	self:RefreshInventoryGiftActions()
end

function AccountInventory:OnPendingSelectFriendGiftBtn(wndHandler, wndControl, eMouseButton)
	local tSelectedPendingData = self.tWndRefs.wndInventoryGift:GetData()

	local wndSelectedFriend
	for idx, wndFriend in pairs(self.tWndRefs.wndInventoryGiftFriendContainer:GetChildren()) do
		if wndFriend:FindChild("FriendButton"):IsChecked() then
			wndSelectedFriend = wndFriend
			break
		end
	end

	local tFriend = wndSelectedFriend:GetData()
	
	local nIndex = tSelectedPendingData.tData.index
	local bIsGroup = tSelectedPendingData.bIsGroup

	if tFriend.bFriend then
		AccountItemLib.GiftPendingItemGroupToCharacter(nIndex, tFriend.nId)
	else
		AccountItemLib.GiftPendingItemGroupToAccount(nIndex, tFriend.nId)
	end
	
	self:RefreshInventory()
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryGift:Show(false)
end

function AccountInventory:OnPendingGiftCancelBtn(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndInventory:Show(true)
	self.tWndRefs.wndInventoryGift:Show(false)
end

-----------------------------------------------------------------------------------------------
-- Entitlement Updates
-----------------------------------------------------------------------------------------------

function AccountInventory:OnEntitlementUpdate(tEntitlementInfo)
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() or tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.FraudCheck then
		return
	end
	
	self.bHasFraudCheck = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.FraudCheck) ~= 0
	self:UpdateValidationNotifications()
end

function AccountInventory:UpdateValidationNotifications()
	local wndInventoryContainer = self.tWndRefs.wndInventoryContainer
	local wndInventoryValidationNotification = self.tWndRefs.wndInventoryValidationNotification
	local nLeft, nTop, nRight, nBottom = wndInventoryContainer:GetOriginalLocation():GetOffsets()
	
	if not self.bHasFraudCheck and wndInventoryValidationNotification:IsShown() then
		wndInventoryValidationNotification:Show(false)		
	elseif self.bHasFraudCheck and not wndInventoryValidationNotification:IsShown() then
		wndInventoryValidationNotification:Show(true)
	end
	
	self:RefreshInventoryActions()
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function AccountInventory:HelperCooldown(nRawTime)
	local strResult = Apollo.GetString("CRB_LessThan1M")
	local nSeconds = math.floor(nRawTime / 1000)
	local nMinutes = math.floor(nSeconds / 60)
	local nHours = math.floor(nSeconds / 3600)
	local nDays = math.floor(nSeconds / 86400)

	if nDays > 1 then
		strResult = String_GetWeaselString(Apollo.GetString("CRB_Days"), nDays)
	elseif nHours > 1 then
		strResult = String_GetWeaselString(Apollo.GetString("CRB_Hours"), nHours)
	elseif nMinutes > 1 then
		strResult = String_GetWeaselString(Apollo.GetString("CRB_Minutes"), nMinutes)
	end

	return strResult
end

function AccountInventory:OnFilterCheck(wndHandler, wndControl, eMouseButton)
	self:RefreshInventory()
end

function AccountInventory:OnFilterUncheck(wndHandler, wndControl, eMouseButton)
	self:RefreshInventory()
end

function AccountInventory:OnFilterResetSignal(wndHandler, wndControl, eMouseButton)
	self:ResetFilters()
	self:RefreshInventory()
end

function AccountInventory:OnFilterLegacyCheck(wndHandler, wndControl, eMouseButton)
	self:RefreshInventory()
	self.tWndRefs.wndInventoryGridContainer:SetVScrollPos(0)
end

function AccountInventory:OnFilterLegacyUncheck(wndHandler, wndControl, eMouseButton)
	self:RefreshInventory()
	self.tWndRefs.wndInventoryGridContainer:SetVScrollPos(0)
end

local AccountInventoryInst = AccountInventory:new()
AccountInventoryInst:Init()