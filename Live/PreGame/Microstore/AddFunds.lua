-----------------------------------------------------------------------------------------------
-- Client Lua Script for Storefront/AddFunds.lua
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "StorefrontLib"
require "AccountItemLib"
require "Money"
require "WindowLocation"
require "Sound"

local AddFunds = {} 

function AddFunds:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.tDialogWndRefs = {}
	o.tFundsWndRefs = {}
	
	o.ktErrorMessages =
	{
		[StorefrontLib.CodeEnumStoreError.CatalogUnavailable] = Apollo.GetString("Storefront_ErrorCatalogUnavailable"),
		[StorefrontLib.CodeEnumStoreError.StoreDisabled] = Apollo.GetString("Storefront_ErrorStoreDisabled"),
		[StorefrontLib.CodeEnumStoreError.InvalidOffer] = Apollo.GetString("Storefront_ErrorInvalidOffer"),
		[StorefrontLib.CodeEnumStoreError.InvalidPrice] = Apollo.GetString("Storefront_ErrorInvalidPrice"),
		[StorefrontLib.CodeEnumStoreError.GenericFail] = Apollo.GetString("Storefront_ErrorGenericFail"),
		[StorefrontLib.CodeEnumStoreError.PurchasePending] = Apollo.GetString("Storefront_ErrorPurchasePending"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CartFraudFailure] = Apollo.GetString("Storefront_ErrorTransactionFailureContract"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CartPaymentFailure] = Apollo.GetString("Storefront_ErrorTransactionFailure"),
		[StorefrontLib.CodeEnumStoreError.PgWs_InvalidCCExpirationDate] = Apollo.GetString("Storefront_ErrorCardExpired"),
		[StorefrontLib.CodeEnumStoreError.PgWs_InvalidCreditCardNumber] = Apollo.GetString("Storefront_ErrorInvalidCard"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CreditCardExpired] = Apollo.GetString("Storefront_ErrorCardDeclinedExpired"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CreditCardDeclined] = Apollo.GetString("Storefront_ErrorCardDeclined"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CreditFloorExceeded] = Apollo.GetString("Storefront_ErrorCardLimits"),
		[StorefrontLib.CodeEnumStoreError.PgWs_InventoryStatusFailure] = Apollo.GetString("Storefront_ErrorTransactionFailure"),
		[StorefrontLib.CodeEnumStoreError.PgWs_PaymentPostAuthFailure] = Apollo.GetString("Storefront_ErrorTransactionFailure"),
		[StorefrontLib.CodeEnumStoreError.PgWs_SubmitCartFailed] = Apollo.GetString("Storefront_ErrorTransactionFailure"),
		[StorefrontLib.CodeEnumStoreError.PurchaseVelocityLimit] = Apollo.GetString("Storefront_ErrorVelocityFailure"),
	}
	
    return o
end

function AddFunds:Init()
    Apollo.RegisterAddon(self)
end

function AddFunds:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("AddFunds.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function AddFunds:OnDocumentReady()
	Apollo.RegisterEventHandler("StoreCatalogReady", "OnStoreCatalogReady", self)
	
	-- Store UI Events
	Apollo.RegisterEventHandler("ShowDialog", "OnShowDialog", self)
	Apollo.RegisterEventHandler("CloseDialog", "OnCloseDialog", self)
	Apollo.RegisterEventHandler("ShowNeedsFunds", "OnShowNeedsFunds", self)
	Apollo.RegisterEventHandler("CloseNeedsFunds", "OnCloseNeedsFunds", self)
end

function AddFunds:OnStoreCatalogReady()
	if self.tDialogWndRefs.wndMain ~= nil and self.tDialogWndRefs.wndMain:IsValid() and self.tDialogWndRefs.wndMain:IsShown() then
		self:BuildFundsPackages()
		self.tDialogWndRefs.wndContainer:SetVScrollPos(0)
	end
end

function AddFunds:ShowHelper(wndToShow)
	self.tDialogWndRefs.wndAddFunds:Show(self.tDialogWndRefs.wndAddFunds == wndToShow)
	self.tDialogWndRefs.wndConfirmed:Show(self.tDialogWndRefs.wndConfirmed == wndToShow)
end

-----------------------------------------------------------------------------------------------
-- Dialog
-----------------------------------------------------------------------------------------------

function AddFunds:OnCloseDialog()
	if self.tDialogWndRefs.wndMain ~= nil and self.tDialogWndRefs.wndMain:IsValid() then
		self.tDialogWndRefs.wndMain:Show(false)
	end
end

function AddFunds:OnShowDialog(strDialogName, wndParent)
	if strDialogName ~= "Funds" then
		if self.tDialogWndRefs.wndMain ~= nil and self.tDialogWndRefs.wndMain:IsValid() then
			self.tDialogWndRefs.wndMain:Show(false)
		end
		return
	end
	
	if self.tDialogWndRefs.wndMain == nil or not self.tDialogWndRefs.wndMain:IsValid() then
		local wndMain = Apollo.LoadForm(self.xmlDoc, "AddFundsDialog", wndParent, self)
		self.tDialogWndRefs.wndMain = wndMain
		self.tDialogWndRefs.wndParent = wndParent
		
		self.tDialogWndRefs.wndFraming = wndMain:FindChild("Framing")
		
		-- Choice
		self.tDialogWndRefs.wndChoice = wndMain:FindChild("Choice")
		
		-- Add
		self.tDialogWndRefs.wndAddFunds = wndMain:FindChild("Choice:AddFunds")
		self.tDialogWndRefs.wndCCOnFile = wndMain:FindChild("Choice:AddFunds:CCOnFile")
		self.tDialogWndRefs.wndContainer = wndMain:FindChild("Choice:AddFunds:CCOnFile:CurrencyChoiceContainer")
		self.tDialogWndRefs.wndFinalizeBtn = wndMain:FindChild("Choice:AddFunds:CCOnFile:FinalizeBtn")
		self.tDialogWndRefs.wndNoCCOnFile = wndMain:FindChild("Choice:AddFunds:NoCCOnFile")
		
		-- Confirmed
		self.tDialogWndRefs.wndConfirmed = wndMain:FindChild("Choice:Confirmed")
		self.tDialogWndRefs.wndConfirmedAnimation = wndMain:FindChild("Choice:Confirmed:PurchaseConfirmAnimation")
		self.tDialogWndRefs.wndConfirmedAnimationInner = wndMain:FindChild("Choice:Confirmed:PurchaseConfirmAnimation:PurchaseConfirmAnimationInner")
	end
	
	if strDialogName == "Funds" then
		self:AddFundsDialog()
	end
	self.tDialogWndRefs.wndMain:Show(true)
end

function AddFunds:ChoiceFundsDialog()
	self.tDialogWndRefs.wndFraming:SetSprite("MTX:UI_BK3_MTX_BG_PopupBlue")
	
	local eExternalCurrency = AccountItemLib.GetExternalCurrency()
	local monExternal = AccountItemLib.GetAccountCurrency(eExternalCurrency)
	local arProtobuckOffers = StorefrontLib.GetProtobucksOffers()
	
	if arProtobuckOffers == nil or #arProtobuckOffers == 0 or monExternal:GetAmount() == 0 then
		self:AddFundsDialog()
	end
end

function AddFunds:OnChoicePurchase(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:AddFundsDialog()
	self:ShowHelper(self.tDialogWndRefs.wndAddFunds)
end

function AddFunds:OnAddFundsCancelSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	self.tDialogWndRefs.wndMain:Show(false)
	self.tDialogWndRefs.wndParent:Show(false)
	
	PreGameLib.Event_FireGenericEvent("CloseDialog")
end

---------------------------------------------------------------------------------------------------
-- Add Funds
---------------------------------------------------------------------------------------------------

function AddFunds:AddFundsDialog()
	self:BuildFundsPackages()
	
	self:ShowHelper(self.tDialogWndRefs.wndAddFunds)
	self.tDialogWndRefs.wndMain:Show(true)
end

function AddFunds:BuildFundsPackages()
	self.tDialogWndRefs.wndFraming:SetSprite("MTX:UI_BK3_MTX_BG_PopupBlue")

	self.tDialogWndRefs.wndContainer:DestroyChildren()
	local tFundPackages = StorefrontLib.GetVirtualCurrencyPackages()
	for idx, tFundPackage in pairs(tFundPackages) do
		local wndFundPackage = Apollo.LoadForm(self.xmlDoc, "AddFundsEntry", self.tDialogWndRefs.wndContainer, self)
		
		local strCurrencyName = self:GetRealCurrencyNameFromEnum(tFundPackage.eRealCurrency)
		
		wndFundPackage:FindChild("Name"):SetText(tFundPackage.strPackageName)
		wndFundPackage:FindChild("Cost"):SetText(PreGameLib.String_GetWeaselString("$1n$2c", strCurrencyName, tFundPackage.nPrice))
		wndFundPackage:FindChild("Btn"):SetData(tFundPackage)
	end
	self.tDialogWndRefs.wndContainer:ArrangeChildrenTiles()
	
	self.tDialogWndRefs.wndFinalizeBtn:Enable(false)
	
	self.tDialogWndRefs.wndCCOnFile:Show(#tFundPackages ~= 0)
	self.tDialogWndRefs.wndNoCCOnFile:Show(#tFundPackages == 0)
	self.tDialogWndRefs.wndNoCCOnFile:FindChild("CurrencyChoiceNoneAvailable"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Storefront_NoCCOnFileHelperProtoBucks")))
end

function AddFunds:OnAddFundsConfirmedSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self:ChoiceFundsDialog()
end

function AddFunds:OnAddFundsFinalize(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local this = self
	
	Promise.NewFromGameEvent("StorePurchaseVirtualCurrencyPackageResult", self)
	:Then(function(bSuccess, eError)
		if bSuccess then
			PreGameLib.Event_FireGenericEvent("HideFullDialog")
			self:ShowHelper(this.tDialogWndRefs.wndConfirmed)
			
			this.tDialogWndRefs.wndFraming:SetSprite("MTX:UI_BK3_MTX_BG_PopupGreen")
			this.tDialogWndRefs.wndConfirmedAnimation:SetSprite("BK3:UI_BK3_OutlineShimmer_anim_nocycle")
			this.tDialogWndRefs.wndConfirmedAnimationInner:SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthLargeTemp")
		else
			local strMessage
			if this.ktErrorMessages[eError] ~= nil then
				strMessage = this.ktErrorMessages[eError]
			else
				strMessage = Apollo.GetString("Storefront_PurchaseProblemGeneral")
			end
			
			PreGameLib.Event_FireGenericEvent("RequestFullDialogPrompt", Apollo.GetString("Storefront_PurchaseFailedNCoin"), strMessage)
		end
	end)
	
	PreGameLib.Event_FireGenericEvent("RequestFullDialogSpinner", Apollo.GetString("Storefront_PurchaseInProgressThanks"))
	StorefrontLib.PurchaseVirtualCurrencyPackage(tData.nPackageId, tData.nPrice)
end

function AddFunds:OnAddFundsWebSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	StorefrontLib.RedirectToAccountSettings()
end

function AddFunds:OnAddFundsFundPackageCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	self.tDialogWndRefs.wndFinalizeBtn:SetData(tData)
	self.tDialogWndRefs.wndFinalizeBtn:Enable(true)
end

---------------------------------------------------------------------------------------------------
-- Purchase Needs Funds
---------------------------------------------------------------------------------------------------

function AddFunds:OnCloseNeedsFunds()
	if self.tFundsWndRefs.wndNeedsFunds ~= nil and self.tFundsWndRefs.wndNeedsFunds:IsValid() then
		self.tFundsWndRefs.wndNeedsFunds:Show(false)
	end
end

function AddFunds:OnShowNeedsFunds(wndParent, tData)
	if self.tFundsWndRefs.wndNeedsFunds == nil or not self.tFundsWndRefs.wndNeedsFunds:IsValid() then
		self.tFundsWndRefs.wndParent = wndParent
		
		local wndNeedsFunds = Apollo.LoadForm(self.xmlDoc, "PurchaseNeedsFundsGoToTopup", wndParent, self)
		self.tFundsWndRefs.wndNeedsFunds = wndNeedsFunds
		self.tFundsWndRefs.wndNeedsFundsNoneAvailableTitle = wndNeedsFunds:FindChild("SectionStack:FundsSection:NoneAvailableTitle")
	end
	
	local tOffer = tData.tOffer
	local tOfferInfo = tData.tOfferInfo
	local tPrice = tData.tPrice

	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	local monAfter = Money.new()
	monAfter:SetAccountCurrencyType(tData.tPrice.eCurrencyType)
	monAfter:SetAmount(tData.tPrice.monPrice:GetAmount() - monBalance:GetAmount())
	
	self.tFundsWndRefs.wndNeedsFundsNoneAvailableTitle:SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Storefront_AdditionalProtoBucksRequiredExact"), monAfter:GetAmount()))
	
	self.tFundsWndRefs.wndNeedsFunds:Show(true)
end

function AddFunds:OnPurchaseNeedsFundsTopUpBtnSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	PreGameLib.Event_FireGenericEvent("RequestContinueOffer")
	PreGameLib.Event_FireGenericEvent("RequestTopupDialog")
end

---------------------------------------------------------------------------------------------------
-- Shared
---------------------------------------------------------------------------------------------------

function AddFunds:GetRealCurrencyNameFromEnum(eRealCurrency)
	if eRealCurrency == StorefrontLib.CodeEnumRealCurrency.USD then
		return Apollo.GetString("Storefront_ExternalCurrency_USD")
	elseif eRealCurrency == StorefrontLib.CodeEnumRealCurrency.GBP then
		return  Apollo.GetString("Storefront_ExternalCurrency_GBP")
	elseif eRealCurrency == StorefrontLib.CodeEnumRealCurrency.EUR then
		return  Apollo.GetString("Storefront_ExternalCurrency_EUR")
	end
	
	return "?"
end

function AddFunds:GetCurrencyNameFromEnum(eCurrencyType)
	if eCurrencyType == AccountItemLib.CodeEnumAccountCurrency.NCoins then
		if StorefrontLib.GetIsPTR() then
			return "PTR NCoin"
		end
	end

	local monTemp = Money.new()
	monTemp:SetAccountCurrencyType(eCurrencyType)
	return PreGameLib.String_GetWeaselString(monTemp:GetDenomInfo()[1].strName)
end


local AddFundsInst = AddFunds:new()
AddFundsInst:Init()
