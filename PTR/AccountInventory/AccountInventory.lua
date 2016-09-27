-----------------------------------------------------------------------------------------------
-- Client Lua Script for AccountInventory
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "AccountItemLib"
require "CREDDExchangeLib"
require "FriendshipLib"

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
	[CREDDExchangeLib.CodeEnumAccountOperationResult.AlreadyClaimed] = "AccountInventory_Error_AlreadyClaimed",
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

    return o
end

function AccountInventory:Init()
    Apollo.RegisterAddon(self)
end

function AccountInventory:OnLoad()
	
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
	self:OnInterfaceMenuListHasLoaded()
	
	Apollo.RegisterEventHandler("AccountOperationResults", "OnAccountOperationResults", self)
	Apollo.RegisterEventHandler("AccountPendingItemsUpdate", "OnRefreshInterfaceMenuAlert", self)
	Apollo.RegisterEventHandler("AccountInventoryUpdate", "OnRefreshInterfaceMenuAlert", self)
	Apollo.RegisterEventHandler("UpdateInventory", "OnRefreshInterfaceMenuAlert", self)
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate", "OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate", "OnEntitlementUpdate", self)
	
	Apollo.RegisterEventHandler("AccountInventoryWindowShow", "OnAccountInventoryWindowShow", self)
	Apollo.RegisterEventHandler("ToggleAccountInventoryWindow", "OnAccountInventoryWindowShow", self)
	Apollo.RegisterEventHandler("GenericEvent_ToggleAccountInventory", "OnAccountInventoryWindowShow", self)

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
end

function AccountInventory:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	local nLastAccountBoundCount = self.nLastAccountBoundCount
	local tSave =
	{
		nLastAccountBoundCount = nLastAccountBoundCount,
	}
	return tSave
end

function AccountInventory:OnRestore(eType, tSavedData)
	if tSavedData then
		if tSavedData.tLocation then
			self.nLastAccountBoundCount = tSavedData.nLastAccountBoundCount
		end
	end
end

function AccountInventory:OnInterfaceMenuListHasLoaded()
	local strIcon = "Icon_Windows32_UI_CRB_InterfaceMenu_InventoryAccount"
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_AccountInventory"), {"GenericEvent_ToggleAccountInventory", "", strIcon})
	self:OnRefreshInterfaceMenuAlert()
end

function AccountInventory:OnRefreshInterfaceMenuAlert()
	local bShowHighlight = false
	local nAlertCount = 0 -- Escrow Only, Doesn't consider UI restrictions (e.g. no name)
	for idx, tPendingAccountItemGroup in pairs(AccountItemLib.GetPendingAccountItemGroups()) do
		nAlertCount = nAlertCount + #tPendingAccountItemGroup.items
	end

	for idx, tAccountItem in pairs(AccountItemLib.GetAccountItems()) do
		if tAccountItem.item and tAccountItem.item:GetItemId() == knBoomBoxItemId then
			nAlertCount = nAlertCount + 1
			if tAccountItem.cooldown and tAccountItem.cooldown == 0 then
				bShowHighlight = true -- Always highlight if a boom box is ready to go
			end
		end
	end

	if not bShowHighlight and self.nLastAccountBoundCount then
		bShowHighlight = self.nLastAccountBoundCount ~= nAlertCount
	end

	if nAlertCount == 0 then
		Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", Apollo.GetString("InterfaceMenu_AccountInventory"), {false, "", 0})
	else
		Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", Apollo.GetString("InterfaceMenu_AccountInventory"), {bShowHighlight, "", nAlertCount})
	end
	self.nLastAccountBoundCount = nAlertCount
end

function AccountInventory:OnAccountOperationResults(eOperationType, eResult)
	if eResult == CREDDExchangeLib.CodeEnumAccountOperationResult.Ok then
		return
	end
	
	local strMessage = ""
	
	if ktResultErrorCodeStrings[eResult] then
		strMessage = Apollo.GetString(ktResultErrorCodeStrings[eResult])
	else
		strMessage = Apollo.GetString("MarketplaceCredd_Error_GenericFail")
	end
	
	if strMessage ~= nil and strMessage ~= "" then
		Event_FireGenericEvent("GenericEvent_SystemChannelMessage", strMessage)
	end
end

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
		wndInventoryContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
		
	elseif self.bHasFraudCheck and not wndInventoryValidationNotification:IsShown() then
		local nHeight = wndInventoryValidationNotification:GetHeight()
		wndInventoryContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom - nHeight)
		wndInventoryValidationNotification:Show(true)
	end
	
	self:RefreshInventoryActions()
end

function AccountInventory:OnAccountInventoryWindowShow()
	GameLib.OpenAccountInventory()
end

local AccountInventoryInst = AccountInventory:new()
AccountInventoryInst:Init()