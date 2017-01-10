-----------------------------------------------------------------------------------------------
-- Client Lua Script for Trading
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Unit"
require "GameLib"
require "P2PTrading"
require "Apollo"
require "AccountItemLib"

local Trading = {}

local kstrValidItemIcon		= "UI_BK3_ItemDrag_DestinationNoGlow"
local kstrInvalidItemIcon	= "UI_BK3_ItemDrag_DestinationDeniedNoGlow"

local knSaveVersion = 1
local knMaxTradeItems = 8
local knMaxCopperTrade = 2147483648

function Trading:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.unitTradePartner = nil
	o.tPendingItems = {}
	o.bInitiator = false
	o.bTradeIsActive = false

	return o
end

function Trading:Init()
	Apollo.RegisterAddon(self)
end

function Trading:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	local tSaved =
	{
		bInviteShown = self.wndTradeInvite:IsShown(),
		bInitiator = self.bInitiator,
		bInviteAccepted = self.bTradeIsActive,
		idPartner = self.unitTradePartner and self.unitTradePartner:GetId() or nil,
		nSaveVersion = knSaveVersion,
	}

	return tSaved
end

function Trading:OnRestore(eType, tSavedData)
	if not tSavedData or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end

	if tSavedData.idPartner then
		self.unitPartner = GameLib.GetUnitById(tSavedData.idPartner)
	end

	self.bInviteAccepted = tSavedData.bInviteAccepted
	self.bInitiator = tSavedData.bInitiator
end

function Trading:OnLoad()
    self.xmlDoc = XmlDoc.CreateFromFile("TradingForms.xml")
    self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Trading:OnDocumentReady()
    if self.xmlDoc == nil then
        return
    end

	Apollo.RegisterEventHandler("P2PTradeInvite", 					"OnP2PTradeInvite", self)
	Apollo.RegisterEventHandler("P2PTradeResult", 					"OnP2PTradeResult", self)
	Apollo.RegisterEventHandler("P2PTradeChange", 					"OnP2PTradeChange", self)
	Apollo.RegisterEventHandler("P2PTradeWithTarget", 				"OnP2PTradeWithTarget", self)
	Apollo.RegisterEventHandler("P2PCancelTrade", 					"OnP2PCancelTrade", self)
	Apollo.RegisterEventHandler("P2PTradeCommit", 					"OnP2PTradeCommit", self)

	Apollo.RegisterEventHandler("GenericEvent_StartCircuitCraft",				"OnCraftingCloseWindow", self)
	Apollo.RegisterEventHandler("GenericEvent_StartCraftingGrid",				"OnCraftingCloseWindow", self)
	Apollo.RegisterEventHandler("GenericEvent_CraftingResume_OpenEngraving",	"OnCraftingCloseWindow", self)

	Apollo.RegisterEventHandler("PremiumTierChanged", 				"OnPremiumTierChanged", self)
	Apollo.RegisterEventHandler("MoneyTradeLimitChanged",			"OnMoneyTradeLimitChanged", self)

	self.wndTradeInvite 	= Apollo.LoadForm(self.xmlDoc, "TradeInvite", nil, self)
	self.wndDeclineNotice 	= Apollo.LoadForm(self.xmlDoc, "DeclineNotice", nil, self)
	self.wndTradeForm 		= Apollo.LoadForm(self.xmlDoc, "SecureTrade", nil, self)
	self.wndErrorNotice 	= Apollo.LoadForm(self.xmlDoc, "ErrorNotice", nil, self)
	self.wndConfirmBlocker 	= self.wndTradeForm:FindChild("ConfirmBlocker")
	self.wndBlockerText 	= self.wndTradeForm:FindChild("BlockerText")

	self.wndTradeInvite:Show(false, true)
	self.wndTradeForm:Show(false, true)
	self.wndDeclineNotice:Show(false, true)
	self.wndErrorNotice:Show(false, true)
	self.wndConfirmBlocker:Show(false, true)

	self.xmlDoc = nil

	self.wndTradeForm:FindChild("AcceptBtn"):Enable(false)

	local wndYourOfferContainer = nil
	if AccountItemLib.GetPremiumSystem() == AccountItemLib.CodeEnumPremiumSystem.VIP then
		self.wndTradeForm:FindChild("YouOfferContainer"):Show(false)
		wndYourOfferContainer = self.wndTradeForm:FindChild("YouOfferLimitedContainer")
		self.wndYourCashTradeLimit = wndYourOfferContainer:FindChild("YourCashTradeLimit")
	else
		self.wndTradeForm:FindChild("YouOfferLimitedContainer"):Show(false)
		wndYourOfferContainer = self.wndTradeForm:FindChild("YouOfferContainer")
	end
	wndYourOfferContainer:Show(true)
	self.wndYourCash = wndYourOfferContainer:FindChild("YourCash")
	self.wndYourCash:SetData(0)
	self.wndYourCash:SetAmountLimit(knMaxCopperTrade)

    self.tYourItem = {}
	self.tPartnerItem = {}

	for idx = 1, knMaxTradeItems do
		self.tYourItem[idx] = wndYourOfferContainer:FindChild("YourItem" .. tostring(idx))
		self.tPartnerItem[idx] = self.wndTradeForm:FindChild("PartnerItem" .. tostring(idx))
	end

	self.bIsTrading = P2PTrading.CanInitiateTrade(GameLib.GetPlayerUnit()) == P2PTrading.P2PTradeError_AlreadyTrading

	if self.unitPartner == nil then
		P2PTrading.CancelTrade()
		return
	end

	if self.bIsTrading then
		if not self.bInitiator and not self.bInviteAccepted then
			self:OnP2PTradeInvite(self.unitPartner)
		else
			self.wndTradeForm:Show(true)
			self:OnMoneyTradeLimitChanged()
			self.unitTradePartner = self.unitPartner
			if P2PTrading.GetMyTradeMoney() ~= nil then
				self.wndYourCash:SetAmount(P2PTrading.GetMyTradeMoney():GetAmount())
			end
			if self.bInviteAccepted then
				self:OnP2PTradeResult(P2PTrading.P2PTradeResultCode_PlayerAcceptedInvite)
			else
				self.wndTradeForm:FindChild("HeaderBGText"):SetText(String_GetWeaselString(Apollo.GetString("Trading_TradingWith"), self.unitTradePartner:GetName()))
				self:OnUpdate()
				self:UpdateTrade()
			end
		end
	end

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()
end

function Trading:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {wnd = self.wndTradeForm, strName = Apollo.GetString("CRB_PlayerToPlayerTrade")})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndTradeForm, strName = Apollo.GetString("CRB_PlayerToPlayerTrade")})
end

function Trading:OnUpdate()
	if self.wndTradeForm:IsVisible() then
		self.wndTradeForm:FindChild("CommitIndicator"):Show(P2PTrading.IsPartnerCommitted())
		self.wndConfirmBlocker:Show(P2PTrading.AmICommitted() or not self.bTradeIsActive)

		local strPartner = Apollo.GetString("Trading_Partner")
		if self.unitTradePartner ~= nil and self.unitTradePartner:GetName() ~= nil then
			strPartner = self.unitTradePartner:GetName()
		end

		if P2PTrading.AmICommitted() then
			self.wndBlockerText:SetText(String_GetWeaselString(Apollo.GetString("Trading_WaitingForApproval"), strPartner))
		else
			self.wndBlockerText:SetText(String_GetWeaselString(Apollo.GetString("Trading_WaitingForPartner"), strPartner))
		end

		if P2PTrading.IsPartnerCommitted() then
			self.wndTradeForm:FindChild("AcceptBtn"):SetText(Apollo.GetString("CRB_Accept"))
		else
			self.wndTradeForm:FindChild("AcceptBtn"):SetText(Apollo.GetString("CRB_Commit"))
		end
	end
end

-------------------------------------------------------------------------------------
-- Handlers for Trading
-------------------------------------------------------------------------------------

function Trading:UpdateTrade()
	if not P2PTrading.IsTrading() then
		self:HelperResetTrade()
		return
	end

	self:HelperResetItems()

	local nMyOffers = 0
	local nPartnerOffers = 0
	local tItems = P2PTrading.GetTradeItems()
	if tItems == nil then
		return
	end

	local nPartnerCashOffer = P2PTrading.GetPartnerTradeMoney():GetAmount()

	local wndItem = nil
	for idx, tCurrItemData in ipairs(tItems) do
		if tCurrItemData.bIsMine and nMyOffers < knMaxTradeItems then
			nMyOffers = nMyOffers + 1
			wndItem = self.tYourItem[nMyOffers]
		elseif not tCurrItemData.bIsMine and nPartnerOffers < knMaxTradeItems then
			nPartnerOffers = nPartnerOffers + 1
			wndItem = self.tPartnerItem[nPartnerOffers]
		end

		wndItem:Show(true)
		local wndItemIcon = wndItem:FindChild("Icon")
		wndItemIcon:SetSprite(tCurrItemData.strIcon)
		wndItemIcon:GetWindowSubclass():SetItem(tCurrItemData.itemTrading)
		wndItem:SetData(tCurrItemData)
		if tCurrItemData.nQuantity > 1 then
			wndItemIcon:SetText(tostring(tCurrItemData.nQuantity))
		else
			wndItemIcon:SetText("")
		end

		self:HelperBuildItemTooltip(wndItem, tCurrItemData)
	end
	if nMyOffers + 1 <= knMaxTradeItems then
		self.nNextEmptySlot = nMyOffers + 1
	else
		self.nNextEmptySlot = nil
	end
	
	self.wndTradeForm:FindChild("PartnerCash"):SetAmount(nPartnerCashOffer)

	local wndAcceptBtn = self.wndTradeForm:FindChild("AcceptBtn")
	wndAcceptBtn:Enable(true)
	wndAcceptBtn:SetActionData(GameLib.CodeEnumConfirmButtonType.CommitTrade)
end

function Trading:OnItemMouseButtonDown(wndHandler, wndControl, eButton, nX, nY, bDouble)
	if wndHandler ~= wndControl then
		return
	end

	local tItem = wndControl:GetData()
	if tItem == nil then
		return
	end

	P2PTrading.RemoveItem(tItem.nId)
	if self.nNextEmptySlot == nil then
		self.nNextEmptySlot = knMaxTradeItems
	end
	self.tYourItem[self.nNextEmptySlot]:FindChild("Icon"):SetSprite("")
	self.nNextEmptySlot = self.nNextEmptySlot - 1
end

function Trading:OnP2PTradeChange()
	self:OnUpdate()
	self:UpdateTrade()
end

-------------------------------------------------------------------------------------
-- Handlers for Invites
-------------------------------------------------------------------------------------

function Trading:OnP2PTradeInvite(unitInviter)
	self.wndTradeInvite:Invoke()
	self.unitTradePartner = unitInviter
	self.bInitiator = false
	self.bTradeIsActive = false

	local strInviteMsg = String_GetWeaselString(Apollo.GetString("Trading_TradeRequestText"), unitInviter:GetName())
	self.wndTradeInvite:FindChild("TradeText"):SetText(strInviteMsg)

	if self.wndDeclineNotice:IsVisible() then
		self.wndDeclineNotice:Show(false)
	end
end

function Trading:OnP2PTradeResult(eResult)
	if eResult == P2PTrading.P2PTradeResultCode_PlayerDeclinedInvite then
		self:OnP2PDeclineNotice()
	end

	if eResult == P2PTrading.P2PTradeResultCode_PlayerAcceptedInvite then
		self.bTradeIsActive = true
		if self.bInitiator and self.tPendingItems ~= nil then
			for idx = 1, #self.tPendingItems do
				P2PTrading.AddItem(self.tPendingItems[idx])
			end
		end
		self.tPendingItems = {}
		self:UpdateTrade()
		self.wndTradeForm:FindChild("HeaderBGText"):SetText(String_GetWeaselString(Apollo.GetString("Trading_TradingWith"), self.unitTradePartner:GetName()))
		self.wndYourCash:Enable(true)
		self:OnUpdate()
	end

	if eResult == P2PTrading.P2PTradeResultCode_InitiatorCommitted or eResult == P2PTrading.P2PTradeResultCode_TargetCommitted then
		self.wndTradeForm:FindChild("CommitIndicator"):Show(P2PTrading.IsPartnerCommitted())
		self:OnUpdate()
	end
end

function Trading:OnP2PCancelTrade(eResult)
	self:HelperResetItems()
	self:HelperResetTrade()

	if eResult == P2PTrading.P2PTradeResultCode_ErrorInitiating then
		self.wndErrorNotice:Show(true)
	elseif eResult == P2PTrading.P2PTradeResultCode_TargetNotAllowedToTrade then
		self.wndDeclineNotice:FindChild("DeclineText"):SetText(Apollo.GetString("Trading_DisabledForThatPlayer"))
		self.wndDeclineNotice:Show(true)
	end
end

function Trading:OnAcceptTradeBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	self.wndTradeInvite:Show(false)
	P2PTrading.AcceptInvite()
	self.wndTradeForm:Show(true)
	self:OnMoneyTradeLimitChanged()
	self:UpdateTrade()
end

-------------------------------------------------------------------------------------
-- Handlers for SecureTrade dialogs
-------------------------------------------------------------------------------------

function Trading:OnP2PTradeWithTarget(unitTarget, strType, itemData)
	if not unitTarget then
		unitTarget = GameLib.GetTargetUnit()
		if not unitTarget then
			return
		end
	end

	if AccountItemLib.CodeEnumEntitlement.EconomyParticipation and AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.EconomyParticipation) == 0 then
		Event_FireGenericEvent("GenericEvent_SystemChannelMessage", Apollo.GetString("CRB_FeatureDisabledForGuests"))
		return
	end

	local eResult = P2PTrading.InitiateTrade(unitTarget)
	if eResult == P2PTrading.P2PTradeError_Ok then
		self.wndTradeForm:Show(true)
		self:OnMoneyTradeLimitChanged()
		self.bInitiator = true
		self.bTradeIsActive = false
		self.unitTradePartner = unitTarget
		self.wndTradeForm:FindChild("HeaderBGText"):SetText(String_GetWeaselString(Apollo.GetString("Trading_TradingWith"), self.unitTradePartner:GetName()))
		self.tPendingItems = {}
		self.wndConfirmBlocker:Show(not self.bTradeIsActive)
		if strType and strType == "DDBagItem" then
			self.tPendingItems[1] = itemData
		end
		self.wndYourCash:Enable(false)
	end

	if self.wndDeclineNotice:IsVisible() then
		self.wndDeclineNotice:Show(false)
	end
end

function Trading:OnP2PTradeQueryDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, nValue)
	if wndHandler ~= wndControl then
		return Apollo.DragDropQueryResult.PassOn
	end
	if self.unitTradePartner == nil then
		return Apollo.DragDropQueryResult.Invalid
	end
	if strType == "DDBagItem" then
		local itemSource = Item.GetItemFromInventoryLoc(nValue)
		if itemSource:IsAlwaysTradeable() or itemSource:IsTradeableTo(self.unitTradePartner) then
			if self.nNextEmptySlot ~= nil then
				self.tYourItem[self.nNextEmptySlot]:FindChild("Icon"):SetSprite(kstrValidItemIcon)
			end
		return Apollo.DragDropQueryResult.Accept
		else
			if self.nNextEmptySlot ~= nil then
				self.tYourItem[self.nNextEmptySlot]:FindChild("Icon"):SetSprite(kstrInvalidItemIcon)
			end
			return Apollo.DragDropQueryResult.Ignore
		end
	end
	return Apollo.DragDropQueryResult.Invalid
end

function Trading:OnP2PTradeDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, nValue)
	if wndHandler ~= wndControl then
		return false
	end

	if self.unitTradePartner == nil then
		return false
	end

	if strType == "DDBagItem" then
		if self.unitTradePartner ~= nil then
			local nMyCount = 0
			local tItems = P2PTrading.GetTradeItems()
			for idx, tItemData in pairs(tItems) do
				if tItemData.bIsMine then
					nMyCount = nMyCount + 1
				end
			end
			if nMyCount + #self.tPendingItems >= knMaxTradeItems then
				return false
			end
			if self.bTradeIsActive then
				if not P2PTrading.AddItem(nValue) then
					ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, Apollo.GetString("MarketplaceAuction_InvalidItem"), "")
				end
			elseif self.bInitiator then
				local bDupe = false
				for idx = 1, #self.tPendingItems do
					if self.tPendingItems[idx] == nValue then
						bDupe = true
						break
					end
				end
				if not bDupe then
					table.insert(self.tPendingItems, nValue)
				end
			end
		end
	end
	return false
end

function Trading:OnP2PTradeMouseExit(wndHandler, wndControl, nX, nY)
	if wndHandler ~= wndControl or self.wndTradeForm ~= wndControl then
		return
	end
	
	if self.nNextEmptySlot ~= nil then
		self.tYourItem[self.nNextEmptySlot]:FindChild("Icon"):SetSprite("")
	end
end

function Trading:OnCommitCancel()
	if P2PTrading.AmICommitted() then
		if self.wndTradeForm and self.wndTradeForm:IsValid() then
			P2PTrading.SetMoney(0)
			self.wndYourCash:SetData(0)
		end
		P2PTrading.UnCommit()
		self:OnCancelBtn() -- TODO TEMP!!!!!! Until uncommit is fixed
	else
		self:OnCancelBtn()
	end
end

function Trading:OnCashAmountChanged(wndHandler, wndControl, monNewAmount, monOldAmount)
	local nOldAmount = self.wndYourCash:GetData()
	local nNewAmount = monNewAmount:GetAmount()

	-- Limit to current cash
	local nPlayerCash = GameLib.GetPlayerCurrency():GetAmount()
	if nNewAmount > nPlayerCash then
		nNewAmount = nPlayerCash
		self.wndYourCash:SetAmount(nNewAmount)
	end

	if nNewAmount ~= nOldAmount then
		P2PTrading.SetMoney(nNewAmount)
	end

	self.wndYourCash:SetData(nNewAmount)
end

function Trading:OnP2PTradeCommit()
	self.wndTradeForm:SetFocus()
end

function Trading:OnCancelBtn()
	self:HelperResetItems()
	P2PTrading.CancelTrade()
end

function Trading:OnCraftingCloseWindow()
	self:HelperResetItems()
	self.wndTradeInvite:Show(false)
	P2PTrading.CancelTrade()
	P2PTrading.DeclineInvite()
end

function Trading:OnMoneyTradeLimitChanged()
	if self.wndYourCashTradeLimit then
		local monMaxCashTrade = GameLib.GetMoneyTradeLimit()
		if monMaxCashTrade == nil then
			return
		end
		
		self.wndYourCashTradeLimit:SetAmount(monMaxCashTrade)
		self.wndYourCash:SetAmountLimit(monMaxCashTrade)
	end
end

-------------------------------------------------------------------------------------
-- Handlers for Declines
-------------------------------------------------------------------------------------

function Trading:OnReportTradeInviteSpamBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	Event_FireGenericEvent("GenericEvent_ReportPlayerTrade") -- Order is important
	self.wndTradeInvite:Show(false)
--	P2PTrading.DeclineInvite()
end

function Trading:OnDeclineTradeBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	self.wndTradeInvite:Show(false)
	P2PTrading.DeclineInvite()
end

function Trading:OnP2PDeclineNotice(unitDecliner)
	if self.unitTradePartner then -- TODO refactor
		self.wndDeclineNotice:FindChild("DeclineText"):SetText(Apollo.GetString("Trading_Declined"))
		self.wndDeclineNotice:Show(true)
	end
	self:HelperResetTrade()
end

function Trading:OnDeclineAcknowledgeBtn(wndHandler, wndControl)
	self.wndTradeForm:Show(false)
	self.wndDeclineNotice:Show(false)
end

-------------------------------------------------------------------------------------
-- Handlers for Errors
-------------------------------------------------------------------------------------

function Trading:OnErrorAcknowledgeBtn( wndHandler, wndControl, eMouseButton )
	self.wndTradeForm:Show(false)
	self.wndErrorNotice:Show(false)
end

-------------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------------

function Trading:HelperResetTrade()
	self.unitTradePartner = nil
	self.bTradeIsActive = false
	self.bInitiator = false
	self.tPendingItems = {}

	self.wndTradeForm:FindChild("AcceptBtn"):Enable(false)
	self.wndYourCash:SetData(0)
	self.wndTradeForm:FindChild("CommitIndicator"):Show(false)
	self.wndTradeInvite:Show(false)
	self.wndTradeForm:Show(false)
	self.wndConfirmBlocker:Show(false)
	self.wndYourCash:SetAmount(0)
end

function Trading:HelperResetItems()
	for idx = 1, knMaxTradeItems do
		local wndItemIcon = self.tYourItem[idx]:FindChild("Icon")
		wndItemIcon:GetWindowSubclass():SetItem(nil)
		wndItemIcon:SetText("")
		wndItemIcon:SetSprite("")
		self.tYourItem[idx]:SetData(nil)
		self.tYourItem[idx]:SetTooltipDoc(nil)
		wndItemIcon = self.tPartnerItem[idx]:FindChild("Icon")
		wndItemIcon:GetWindowSubclass():SetItem(nil)
		wndItemIcon:SetText("")
		wndItemIcon:SetSprite("")
		self.tPartnerItem[idx]:SetData(nil)
		self.tPartnerItem[idx]:SetTooltipDoc(nil)
	end
	self.wndTradeForm:FindChild("PartnerCash"):SetAmount(0)
end

function Trading:HelperBuildItemTooltip(wndArg, tItemData)
	wndArg:SetTooltipDoc(nil)
	Tooltip.GetItemTooltipForm(self, wndArg, tItemData.itemTrading, {bPrimary = true, bSelling = false, itemModData = tItemData.itemModData, nStackCount = tItemData.nStackCount})
	local itemEquipped = tItemData.itemTrading:GetEquippedItemForItemType()
end

---------------------------------------------------------------------------------------------------
-- Premium Updates
---------------------------------------------------------------------------------------------------

function Trading:OnPremiumTierChanged(ePremiumSystem, nTier)
	if self.wndTradeForm == nil or not self.wndTradeForm:IsValid() or ePremiumSystem ~= AccountItemLib.CodeEnumPremiumSystem.VIP then
		return
	end
	
	if AccountItemLib.GetPlayerRewardProperty(AccountItemLib.CodeEnumRewardProperty.Trading).nValue == 0 then
		self:OnCancelBtn()
	end
end

---------------------------------------------------------------------------------------------------
-- SecureTrade Functions
---------------------------------------------------------------------------------------------------

local TradingInstance = Trading:new()
Trading:Init()
