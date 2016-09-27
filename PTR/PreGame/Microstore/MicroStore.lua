-----------------------------------------------------------------------------------------------
-- Client Lua Script for MicroStore
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "StorefrontLib"
require "AccountItemLib"

local MicroStore = {} 

function MicroStore:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function MicroStore:Init()
    Apollo.RegisterAddon(self)
end

function MicroStore:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("MicroStore.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function MicroStore:OnDocLoaded()
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "MicroStoreForm", "AccountServices", self)
	
	Apollo.RegisterEventHandler("OpenStoreLinkSingle", "OnOpenStoreLinkSingle", self)
	Apollo.RegisterEventHandler("CloseStore", "OnCloseStore", self)
	
	Apollo.RegisterEventHandler("RequestFullDialogPrompt", "OnRequestFullDialogPrompt", self)
	Apollo.RegisterEventHandler("RequestFullDialogSpinner", "OnRequestFullDialogSpinner", self)
	Apollo.RegisterEventHandler("HideFullDialog", "OnHideFullDialog", self)
	Apollo.RegisterEventHandler("RequestTopupDialog", "OnAddFundsSignal", self)	
	
	Apollo.RegisterEventHandler("AccountCurrencyChanged", "UpdateCurrency", self)
	
	
	local wndMain = self.wndMain
	self.tWndRefs = {}
	
	-- Header
	self.tWndRefs.wndWalletAlternative = wndMain:FindChild("Framing:Header:Wallet:Currency:Alternative")
	self.tWndRefs.wndWalletPremium = wndMain:FindChild("Framing:Header:Wallet:Currency:Premium")
	self.tWndRefs.wndWallet = wndMain:FindChild("Framing:Header:Wallet")
	self.tWndRefs.wndWalletTopUp = wndMain:FindChild("Framing:Header:Wallet:CurrencyContainer:TopUp")
	self.tWndRefs.wndWalletConvert = wndMain:FindChild("Framing:Header:Wallet:CurrencyContainer:Convert")
	self.wndTopUpReminder = wndMain:FindChild("Framing:Header:Wallet:CurrencyContainer:TopUp:TopUpBtn:TopUpReminder")
	
	-- Purchase
	self.tWndRefs.wndCenterPurchase = wndMain:FindChild("PurchaseDialog")
	self.tWndRefs.wndCenterPurchaseScrollContent = wndMain:FindChild("PurchaseDialog:ScrollContent")
	self.tWndRefs.wndCenterPurchaseRight = wndMain:FindChild("PurchaseDialog:ScrollContent:Right")
	
	-- Purchase Confirm
	self.tWndRefs.wndCenterPurchaseConfirm = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm")
	self.tWndRefs.wndCenterPurchaseConfirmItemName = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:ItemName")
	self.tWndRefs.wndCenterPurchaseConfirmBannerSection = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:BannerSection")
	self.tWndRefs.wndCenterPurchaseConfirmBannerContainer = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:BannerSection:Container")
	self.tWndRefs.wndCenterPurchaseConfirmDescription = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:Description")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency1Container = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency1")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency1 = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency1:CurrencyBtn:Price")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency1:CurrencyBtn")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency1DisabledTooltip = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency1:DisabledTooltip")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency2Container = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency2")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency2 = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency2:CurrencyBtn:Price")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency2Btn = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency2:CurrencyBtn")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency2DisabledTooltip = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency2:DisabledTooltip")
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterLabel = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer:FundsAfterLabel")
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer:FundsAfterValueNegative")
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer:FundsAfterValue")
	self.tWndRefs.wndCenterPurchaseConfirmNotEnoughAlternativeCurrency = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:NotEnoughAlternativeCurrency")
	self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn = wndMain:FindChild("PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer:FinalizeBtn")
	self.tWndRefs.wndCenterPurchaseConfirmDisclaimer = wndMain:FindChild("PurchaseDialog:Disclaimer")
	
	-- Purchase Confirmed
	self.tWndRefs.wndCenterPurchaseConfirmed = wndMain:FindChild("PurchaseDialog:PurchaseConfirmed")
	self.tWndRefs.wndCenterPurchaseConfirmedFramingContainer = wndMain:FindChild("PurchaseDialog:PurchaseConfirmed:FramingContainer")
	self.tWndRefs.wndCenterPurchaseConfirmedItemName = wndMain:FindChild("PurchaseDialog:PurchaseConfirmed:FramingContainer:ItemName")
	self.tWndRefs.wndCenterPurchaseConfirmedCostLabel = wndMain:FindChild("PurchaseDialog:PurchaseConfirmed:FramingContainer:CostContainer:CostLabel")
	self.tWndRefs.wndCenterPurchaseConfirmedCostValue = wndMain:FindChild("PurchaseDialog:PurchaseConfirmed:FramingContainer:CostContainer:CostValue")
	self.tWndRefs.wndCenterPurchaseConfirmedFundsAfterLabel = wndMain:FindChild("PurchaseDialog:PurchaseConfirmed:FramingContainer:CostContainer:FundsAfterLabel")
	self.tWndRefs.wndCenterPurchaseConfirmedFundsAfterValue = wndMain:FindChild("PurchaseDialog:PurchaseConfirmed:FramingContainer:CostContainer:FundsAfterValue")
	self.tWndRefs.wndCenterPurchaseConfirmedClaimBtnContainerContinueShopping = wndMain:FindChild("PurchaseDialog:PurchaseConfirmed:FramingContainer:BtnContainerContinueShopping")
	self.tWndRefs.wndCenterPurchaseConfirmedClaimBtnContainer = wndMain:FindChild("PurchaseDialog:PurchaseConfirmed:FramingContainer:BtnContainer")
	self.tWndRefs.wndCenterPurchaseConfirmedClaimBtn = wndMain:FindChild("PurchaseDialog:PurchaseConfirmed:FramingContainer:BtnContainer:ClaimBtn")
	
	-- Purchase Confirmed Animation
	self.tWndRefs.wndCenterPurchaseConfirmedAnimation = wndMain:FindChild("PurchaseDialog:PurchaseConfirmed:PurchaseConfirmAnimation")
	self.tWndRefs.wndCenterPurchaseConfirmedAnimationInner = wndMain:FindChild("PurchaseDialog:PurchaseConfirmed:PurchaseConfirmAnimation:PurchaseConfirmAnimationInner")
	
	-- Dialog
	self.tWndRefs.wndModelDialog = wndMain:FindChild("ModelDialog")
	self.tWndRefs.wndModelDialogBlocker = wndMain:FindChild("ModelDialog:Blocker")	
	
	-- Full Blocker
	self.tWndRefs.wndFullBlocker = wndMain:FindChild("ModelDialog_FullScreen")
	self.tWndRefs.wndFullBlockerPrompt = wndMain:FindChild("ModelDialog_FullScreen:Prompt")
	self.tWndRefs.wndFullBlockerPromptHeader = wndMain:FindChild("ModelDialog_FullScreen:Prompt:Header")
	self.tWndRefs.wndFullBlockerPromptBody = wndMain:FindChild("ModelDialog_FullScreen:Prompt:Body")
	self.tWndRefs.wndFullBlockerPromptConfimBtn = wndMain:FindChild("ModelDialog_FullScreen:Prompt:ConfimBtn")
	self.tWndRefs.wndFullBlockerDelaySpinner = wndMain:FindChild("ModelDialog_FullScreen:DelaySpinner")
	self.tWndRefs.wndFullBlockerDelaySpinnerMessage = wndMain:FindChild("ModelDialog_FullScreen:DelaySpinner:BG:DelayMessage")
	
	-- Setup
	local arCurrencyActors =
	{
		{ key = "PremiumCurrency", name = self:GetCurrencyNameFromEnum(AccountItemLib.GetPremiumCurrency()) },
		{ key = "AlternativeCurrency", name = self:GetCurrencyNameFromEnum(AccountItemLib.GetAlternativeCurrency()) }
	}
	
	
	if StorefrontLib.GetIsPTR() then
		self.tWndRefs.wndWalletPremium:SetTooltip(Apollo.GetString("Storefront_NCoinsCurrencyToolipPTR"))
		self.tWndRefs.wndWalletAlternative:SetTooltip(Apollo.GetString("Storefront_OmnibitsCurrencyToolipPTR"))
	else
		self.tWndRefs.wndWalletPremium:SetTooltip(PreGameLib.String_GetWeaselString(Apollo.GetString("Storefront_PremiumCurrencyToolip"), unpack(arCurrencyActors)))
		self.tWndRefs.wndWalletAlternative:SetTooltip(PreGameLib.String_GetWeaselString(Apollo.GetString("Storefront_AlternativeCurrencyToolip"), unpack(arCurrencyActors)))
	end
	
	self.tWndRefs.wndCenterPurchaseConfirmNotEnoughAlternativeCurrency:SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Storefront_PurchaseNotEnoughAlternativeCurrency"), unpack(arCurrencyActors)))
	
	self:UpdateCurrency()
end

function MicroStore:PremiumCurrencyShowHelper(wndToShow)
	self.tWndRefs.wndChoice:Show(self.tWndRefs.wndChoice == wndToShow)
	self.tWndRefs.wndConfirmed:Show(self.tWndRefs.wndConfirmed == wndToShow)
end

-----------------------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------------------

function MicroStore:GetCurrencyNameFromEnum(eCurrencyType)
	if eCurrencyType == AccountItemLib.CodeEnumAccountCurrency.NCoins then
		if StorefrontLib.GetIsPTR() then
			return "PTR NCoin"
		end
	end
	
	local monTemp = Money.new()
	monTemp:SetAccountCurrencyType(eCurrencyType)
	return PreGameLib.String_GetWeaselString(monTemp:GetDenomInfo()[1].strName)
end

function MicroStore:UpdateCurrency()
	local monPremium = StorefrontLib.GetBalance(AccountItemLib.GetPremiumCurrency())
	self.tWndRefs.wndWalletPremium:SetAmount(monPremium, true)
	self.tWndRefs.wndWalletAlternative:SetAmount(StorefrontLib.GetBalance(AccountItemLib.GetAlternativeCurrency()), true)
	self.wndTopUpReminder:Show(monPremium:GetAmount() == 0)
	
	local arProtobuckOffers = StorefrontLib.GetProtobucksOffers()	
	local monExternal = AccountItemLib.GetAccountCurrency(AccountItemLib.GetExternalCurrency())
	self.tWndRefs.wndWalletConvert:Show(monExternal:GetAmount() > 0 and arProtobuckOffers ~= nil and #arProtobuckOffers > 0)
	
	local nNewWidth = self.tWndRefs.wndWallet:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	local nLeft, nTop, nRight, nButtom = self.tWndRefs.wndWallet:GetAnchorOffsets()
	self.tWndRefs.wndWallet:SetAnchorOffsets(-nNewWidth, nTop, nRight, nButtom)
end

function MicroStore:SetupPreviewWindow(wndContainer, tDisplayInfo, tItems)
	local wndPreviewFrame = wndContainer:FindChild("PreviewFrame")
	local wndDecorFrame = wndContainer:FindChild("DecorFrame")
	if tDisplayInfo ~= nil then	
		if tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin then
			local tMannequins = StorefrontLib.GetMannequins()
			tDisplayInfo.idCreature = tMannequins.nMaleMannequinCreatureId
		end
		
		if tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Creature
			or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin then
			wndPreviewFrame:SetCamera(tDisplayInfo.strModelCamera)
			wndPreviewFrame:SetCostumeToCreatureId(tDisplayInfo.idCreature)
			wndPreviewFrame:ResetSpin()
			wndPreviewFrame:SetSpin(30)
			
			for _, tAccountItem in pairs(tItems) do
				if tAccountItem.nStoreDisplayInfoId == tDisplayInfo.nId and tAccountItem.item ~= nil then
					wndPreviewFrame:SetItem(tAccountItem.item)
					
					if tAccountItem.item:GetItemFamily() == Item.CodeEnumItem2Family.Tool then
						wndPreviewFrame:SetToolEquipped(true)
					end
				end
			end
			
			if tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin then
				--self.tWndRefs.wndCenterPurchasePreview:SetModelSequence(self.ktClassAnimation[unitPlayer:GetClassId()].eStand)
			end
		end
	end
	
	local bShowPreview = wndPreviewFrame ~= nil and wndPreviewFrame:IsValid() and tDisplayInfo ~= nil
		and (tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Creature
			or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin
			or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mount)
	wndPreviewFrame:Show(bShowPreview)
	wndDecorFrame:Show(wndDecorFrame ~= nil and wndDecorFrame:IsValid() and tDisplayInfo ~= nil and tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Decor)
end

function MicroStore:SetupOffer(tOffer, nVariant, nCategoryId)
	self.tWndRefs.wndCenterPurchase:Show(true)
	self:PurchaseShowHelper(self.tWndRefs.wndCenterPurchaseConfirm)
	self:PurchaseDialogShowHelper(nil)
	
	self.tWndRefs.wndCenterPurchaseConfirm:SetData({tOffer = tOffer, nVariant = nVariant, nCategoryId = nCategoryId})
	
	local tOfferInfo = StorefrontLib.GetOfferInfo(tOffer.nId, nVariant)
	
	local tOfferCache = {}
	tOfferCache[nVariant] = tOfferInfo
	
	local nVariantQuantityCount = 0
	if #tOfferInfo.tItems > 0 then
		nVariantQuantityCount = tOfferInfo.tItems[1].nCount
	end
	
	-- Name
	self.tWndRefs.wndCenterPurchaseConfirmItemName:SetText(tOfferInfo.strVariantName)
	
	-- Description
	local nLargestDescriptionHeight = 0
	for idx=1, tOffer.nNumVariants do
		local tVariantOfferInfo = tOfferCache[idx]
		if tVariantOfferInfo == nil then
			tVariantOfferInfo = StorefrontLib.GetOfferInfo(tOffer.nId, idx)
			tOfferCache[idx] = tVariantOfferInfo
		end
		
		self.tWndRefs.wndCenterPurchaseConfirmDescription:SetAML("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBody\">"..tVariantOfferInfo.strVariantDescription.."</P>")
		local nWidth, nHeight = self.tWndRefs.wndCenterPurchaseConfirmDescription:SetHeightToContentHeight()
		nLargestDescriptionHeight = math.max(nLargestDescriptionHeight, nHeight)
	end
	self.tWndRefs.wndCenterPurchaseConfirmDescription:SetAML("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBody\">"..tOfferInfo.strVariantDescription.."</P>")
	local nDescriptionWidth, nDescriptionHeight = self.tWndRefs.wndCenterPurchaseConfirmDescription:SetHeightToContentHeight()
	
	if nDescriptionHeight < nLargestDescriptionHeight then
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseConfirmDescription:GetAnchorOffsets()
		self.tWndRefs.wndCenterPurchaseConfirmDescription:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nLargestDescriptionHeight)
	end
	
	self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:SetText(Apollo.GetString("Storefront_Purchase"))
	self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:Enable(false)
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterLabel:Show(false)
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:Show(false)
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative:Show(false)
	self.tWndRefs.wndCenterPurchaseConfirmNotEnoughAlternativeCurrency:Show(false)
	
	-- Price Alternative
	if tOfferInfo.tPrices.tAlternative ~= nil then
		self.tWndRefs.wndCenterPurchaseConfirmCurrency2:SetAmount(tOfferInfo.tPrices.tAlternative.monPrice, true)
		self.tWndRefs.wndCenterPurchaseConfirmCurrency2Btn:SetCheck(false)
		self.tWndRefs.wndCenterPurchaseConfirmCurrency2Btn:SetData({ tOffer = tOffer, tOfferInfo = tOfferInfo, tPrice = tOfferInfo.tPrices.tAlternative, nVariant = nVariant, nCategoryId = nCategoryId })
		self.tWndRefs.wndCenterPurchaseConfirmCurrency2Btn:Enable(not bCantClaimAccount and not bCantClaimAccountPending and not tOfferInfo.bAlreadyOwnBoundMultiRedeem)
	end
	self.tWndRefs.wndCenterPurchaseConfirmCurrency2Container:Show(tOfferInfo.tPrices.tAlternative ~= nil)
	self.tWndRefs.wndCenterPurchaseConfirmCurrency2DisabledTooltip:Show(bCantClaimAccount or bCantClaimAccountPending or tOfferInfo.bAlreadyOwnBoundMultiRedeem)
	
	-- Price Premium
	if tOfferInfo.tPrices.tPremium ~= nil then
		self.tWndRefs.wndCenterPurchaseConfirmCurrency1:SetAmount(tOfferInfo.tPrices.tPremium.monPrice, true)
		self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn:SetCheck(true)
		self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn:SetData({ tOffer = tOffer, tOfferInfo = tOfferInfo, tPrice = tOfferInfo.tPrices.tPremium, nVariant = nVariant, nCategoryId = nCategoryId })
		self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn:Enable(not bCantClaimAccount and not bCantClaimAccountPending)
		self:OnPurchaseWithCheck(self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn, self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn)
	end
	self.tWndRefs.wndCenterPurchaseConfirmCurrency1Container:Show(tOfferInfo.tPrices.tPremium ~= nil)
	self.tWndRefs.wndCenterPurchaseConfirmCurrency1DisabledTooltip:Show(bCantClaimAccount or bCantClaimAccountPending)
	
	local nHeight = self.tWndRefs.wndCenterPurchaseConfirm:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Top)
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseRight:GetAnchorOffsets()
	self.tWndRefs.wndCenterPurchaseRight:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)	
end

function MicroStore:PurchaseConfirmed(tData)
	self:PurchaseDialogShowHelper(self.tWndRefs.wndCenterPurchaseConfirmed)
	Sound.Play(Sound.PlayUIMTXStorePurchaseConfirmation)
	
	local tOffer = tData.tOffer
	local tOfferInfo = tData.tOfferInfo
	local tPrice = tData.tPrice
	
	local strPurchaseSuccessHeader = PreGameLib.String_GetWeaselString(Apollo.GetString("Storefront_PurchaseSuccessItemname"), tOfferInfo.strVariantName)
	self.tWndRefs.wndCenterPurchaseConfirmedItemName:SetAML(string.format('<P Align="Center" Font="CRB_Header14" TextColor="UI_BtnTextGreenNormal">%s</P>', strPurchaseSuccessHeader))
	self.tWndRefs.wndCenterPurchaseConfirmedItemName:SetHeightToContentHeight()
	
	local nHeight = self.tWndRefs.wndCenterPurchaseConfirmedFramingContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseConfirmedFramingContainer:GetAnchorOffsets()
	self.tWndRefs.wndCenterPurchaseConfirmedFramingContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
	self.tWndRefs.wndCenterPurchaseConfirmedAnimation:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
	
	local strCurrencyName = self:GetCurrencyNameFromEnum(tData.tPrice.eCurrencyType)
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	
	self.tWndRefs.wndCenterPurchaseConfirmedCostLabel:SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Storefront_TotalCost"), strCurrencyName))
	self.tWndRefs.wndCenterPurchaseConfirmedCostValue:SetAmount(tData.tPrice.monPrice)
	self.tWndRefs.wndCenterPurchaseConfirmedFundsAfterLabel:SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Storefront_Remaining"), strCurrencyName))
	self.tWndRefs.wndCenterPurchaseConfirmedFundsAfterValue:SetAmount(monBalance)
	self.tWndRefs.wndCenterPurchaseConfirmedAnimation:SetSprite("BK3:UI_BK3_OutlineShimmer_anim_nocycle")
	self.tWndRefs.wndCenterPurchaseConfirmedAnimationInner:SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthLargeTemp")
end

-----------------------------------------------------------------------------------------------
-- Events
-----------------------------------------------------------------------------------------------

function MicroStore:OnCloseStore()
	self.wndMain:Close()
	g_eState = self.ePreStoreState
end

function MicroStore:OnOpenStoreLinkSingle(nOfferGroupId, nVariant)
	self.ePreStoreState = g_eState
	g_eState = LuaEnumState.Buy

	self:UpdateCurrency()
	self.wndMain:Invoke()

	local tOffer = StorefrontLib.GetOfferGroupInfo(nOfferGroupId)
	self:SetupOffer(tOffer, nVariant, 0)
end

-----------------------------------------------------------------------------------------------
-- Control Events
-----------------------------------------------------------------------------------------------

function MicroStore:OnDialogCancelSignal(wndHandler, wndControl, eMouseButton)
	self:OnCloseStore()
end

function MicroStore:OnPurchaseWithCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	local tData = wndControl:GetData()
	
	local strCurrencyName = self:GetCurrencyNameFromEnum(tData.tPrice.eCurrencyType)	
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterLabel:SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Storefront_CurrencyAfterPurchase"), strCurrencyName))
	if monBalance:GetAmount() - tData.tPrice.monPrice:GetAmount() >= 0 then
		local monAfter = Money.new()
		monAfter:SetAccountCurrencyType(tData.tPrice.eCurrencyType)
		monAfter:SetAmount(monBalance:GetAmount() - tData.tPrice.monPrice:GetAmount())
		
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:SetAmount(monAfter, true)
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:SetTextColor(ApolloColor.new("white"))
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterLabel:SetTextColor("ff56b381")
		
		self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:Enable(true)
		self.tWndRefs.wndCenterPurchaseConfirmNotEnoughAlternativeCurrency:Show(false)
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative:Show(false)
	else
		local monAfter = Money.new()
		monAfter:SetAccountCurrencyType(tData.tPrice.eCurrencyType)
		monAfter:SetAmount(tData.tPrice.monPrice:GetAmount() - monBalance:GetAmount())

		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:SetAmount(monAfter, true)
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:SetTextColor(ApolloColor.new("Reddish"))
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterLabel:SetTextColor(ApolloColor.new("Reddish"))
		
		self.tWndRefs.wndCenterPurchaseConfirmNotEnoughAlternativeCurrency:Show(tData.tPrice.eCurrencyType == AccountItemLib.GetAlternativeCurrency())
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative:Show(true)
		self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:Enable(tData.tPrice.eCurrencyType == AccountItemLib.GetPremiumCurrency())
		
		local nWidth = self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:GetDisplayWidth()
		local nFundsValueRight = math.abs(({self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:GetAnchorOffsets()})[3]) --3 is the right offset
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative:GetAnchorOffsets()
		
		nRight = -nWidth - nFundsValueRight
		nLeft = nRight - self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative:GetWidth()
		
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	end
	if tData.tPrice.eCurrencyType == AccountItemLib.CodeEnumAccountCurrency.Omnibits then
		self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Storefront_PurchaseWithOmnibits")))
		self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:SetTooltip(PreGameLib.String_GetWeaselString(Apollo.GetString("Storefront_PurchaseWithOmnibitsTooltip")))
	else
		self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Storefront_PurchaseWithCurrency"), strCurrencyName))
		self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:SetTooltip("")
	end

	self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:SetData(tData)
	
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterLabel:Show(true)
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:Show(true)
	local nHeight = self.tWndRefs.wndCenterPurchaseConfirm:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Top)
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseRight:GetAnchorOffsets()
	self.tWndRefs.wndCenterPurchaseRight:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
	self.tWndRefs.wndCenterPurchaseScrollContent:RecalculateContentExtents()	
end

function MicroStore:OnPurchaseConfirmSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	
	if monBalance:GetAmount() < tData.tPrice.monPrice:GetAmount() then
		if tData.tPrice.eCurrencyType == AccountItemLib.GetPremiumCurrency() then
			self:PurchaseShowHelper(nil)
			PreGameLib.Event_FireGenericEvent("ShowNeedsFunds", self.tWndRefs.wndCenterPurchaseRight, tData)
			self.tWndRefs.wndCenterPurchaseScrollContent:RecalculateContentExtents()
			self.tWndRefs.wndCenterPurchaseScrollContent:SetVScrollPos(0)
			Sound.Play(Sound.PlayUIMTXStorePurchaseFailed)
		end
	else
	
		local promisePurchaseResult = Promise.New()
		Promise.NewFromGameEvent("StorePurchaseOfferResult", self):Then(function(bSuccess, eResult)
			if bSuccess then
				promisePurchaseResult:Resolve()
			else
				promisePurchaseResult:Reject(eResult)
			end
		end)
		
		local this = self
		
		Promise.WhenAll(promisePurchaseResult, Promise.NewFromGameEvent("AccountCurrencyChanged", self))
		:Then(function()
			PreGameLib.Event_FireGenericEvent("HideFullDialog")
			this:PurchaseConfirmed(tData)
		end)
		:Catch(function()
			PreGameLib.Event_FireGenericEvent("RequestFullDialogPrompt", Apollo.GetString("Storefront_PurchaseFailedDialogHeader"), Apollo.GetString("Storefront_PurchaseFailedDialogBody"))
		end)
		
		PreGameLib.Event_FireGenericEvent("RequestFullDialogSpinner", Apollo.GetString("Storefront_PurchaseInProgressThanks"))
		StorefrontLib.PurchaseOffer(tData.tOfferInfo.nId, tData.tPrice.monPrice, 0)
	end
end

function MicroStore:OnAddFundsSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	if StorefrontLib.IsSteam() then
		StorefrontLib.RedirectToSteamNCoinPurchase()
	else
		self.tWndRefs.wndModelDialog:Show(true)
		PreGameLib.Event_FireGenericEvent("ShowDialog", "Funds", self.tWndRefs.wndModelDialog)
	end
end

function MicroStore:OnConvertFundsSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndModelDialog:Show(true)
	PreGameLib.Event_FireGenericEvent("ShowDialog", "ConvertFunds", self.tWndRefs.wndModelDialog)
end

function MicroStore:GetCurrencyNameFromEnum(eCurrencyType)
	if eCurrencyType == AccountItemLib.CodeEnumAccountCurrency.NCoins then
		if StorefrontLib.GetIsPTR() then
			return "PTR NCoin"
		end
	end
	
	local monTemp = Money.new()
	monTemp:SetAccountCurrencyType(eCurrencyType)
	return PreGameLib.String_GetWeaselString(monTemp:GetDenomInfo()[1].strName)
end

function MicroStore:PurchaseDialogShowHelper(wndToShow)
	self.tWndRefs.wndCenterPurchaseConfirmed:Show(self.tWndRefs.wndCenterPurchaseConfirmed == wndToShow)
end

function MicroStore:PurchaseShowHelper(wndToShow)
	self.tWndRefs.wndCenterPurchaseConfirm:Show(self.tWndRefs.wndCenterPurchaseConfirm == wndToShow)
	PreGameLib.Event_FireGenericEvent("CloseNeedsFunds")
end

function MicroStore:OnPurchaseConfirmedSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self:OnCloseStore()
end

-----------------------------------------------------------------------------------------------
-- Full Screen Dialog
-----------------------------------------------------------------------------------------------

function MicroStore:FullBlockerHelper(wndToShow)
	self.tWndRefs.wndFullBlockerPrompt:Show(self.tWndRefs.wndFullBlockerPrompt == wndToShow, true)
	self.tWndRefs.wndFullBlockerDelaySpinner:Show(self.tWndRefs.wndFullBlockerDelaySpinner == wndToShow, true)
end

function MicroStore:OnRequestFullDialogPrompt(strTitle, strMessage, fnCallback)
	self.tWndRefs.wndFullBlocker:Show(true, false, 0.15)
	self:FullBlockerHelper(self.tWndRefs.wndFullBlockerPrompt)
	
	self.tWndRefs.wndFullBlockerPromptHeader:SetText(strTitle)
	self.tWndRefs.wndFullBlockerPromptBody:SetText(strMessage)
	self.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = fnCallback })
end
	
function MicroStore:OnRequestFullDialogSpinner(strMessage)
	self.tWndRefs.wndFullBlocker:Show(true, false, 0.15)
	self:FullBlockerHelper(self.tWndRefs.wndFullBlockerDelaySpinner)
	self.tWndRefs.wndFullBlockerDelaySpinnerMessage:SetText(strMessage)
end

function MicroStore:OnHideFullDialog()
	self.tWndRefs.wndFullBlocker:Show(false, false, 0.15)
end

function MicroStore:OnFullDialogPromptConfirmSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndFullBlocker:Show(false, false, 0.15)
	
	local tData = wndControl:GetData()
	if tData.fnCallback ~= nil then
		tData.fnCallback(self)
	end
end

-----------------------------------------------------------------------------------------------
-- Instance
-----------------------------------------------------------------------------------------------

local MicroStoreInst = MicroStore:new()
MicroStoreInst:Init()
