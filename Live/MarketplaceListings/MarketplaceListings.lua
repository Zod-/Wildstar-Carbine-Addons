-----------------------------------------------------------------------------------------------
-- Client Lua Script for MarketplaceListings
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Money"
require "MarketplaceLib"
require "CommodityOrder"
require "StorefrontLib"
require "AccountItemLib"

local MarketplaceListings = {}
local knMTXUnlockBtnPadding = 12
local knAuctionItemTopContentPadding = 14
local knCommodityItemBottomContentSpacing = 50
local knAuctionItemBottomContentSpacing = 90

local ktTimeRemaining =
{
	[ItemAuction.CodeEnumAuctionRemaining.Expiring]		= Apollo.GetString("MarketplaceAuction_Expiring"),
	[ItemAuction.CodeEnumAuctionRemaining.LessThanHour]	= Apollo.GetString("MarketplaceAuction_LessThanHour"),
	[ItemAuction.CodeEnumAuctionRemaining.Short]		= Apollo.GetString("MarketplaceAuction_Short"),
	[ItemAuction.CodeEnumAuctionRemaining.Long]			= Apollo.GetString("MarketplaceAuction_Long"),
	[ItemAuction.CodeEnumAuctionRemaining.Very_Long]	= Apollo.GetString("MarketplaceAuction_VeryLong")
}

function MarketplaceListings:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.tCurMaxSlots = { nOrderCount = 0, nAuctionCount = 0 }
	o.tPrevOrderCount = { nSell = 0, nBuy = 0 }
	o.tOrderCount = { nSell = 0, nBuy = 0 }
	o.arOrders = nil
	o.tPrevAuctionsCount = { nSell = 0, nBuy = 0 }
	o.tAuctionsCount = { nSell = 0, nBuy = 0 }
	o.arAuctions = nil
	o.nCreddListCount = 0
	o.arCreddList = nil

    return o
end

function MarketplaceListings:Init()
    Apollo.RegisterAddon(self)
end

function MarketplaceListings:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("MarketplaceListings.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function MarketplaceListings:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("WindowManagementReady",					"OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded",				"OnInterfaceMenuListHasLoaded", self)
	self:OnInterfaceMenuListHasLoaded()

	Apollo.RegisterEventHandler("InterfaceMenu_ToggleMarketplaceListings", 	"OnToggleFromAuctionHouse", self)
	Apollo.RegisterEventHandler("ToggleListingsFromAuctionHouse", 			"OnToggleFromAuctionHouse", self)
	Apollo.RegisterEventHandler("ToggleListingsFromCommodities", 			"OnToggleFromCommodities", self)
	Apollo.RegisterEventHandler("ToggleListingsFromCREDD", 					"OnToggleFromCREDD", self)

	Apollo.RegisterEventHandler("OwnedItemAuctions", 						"OnOwnedItemAuctions", self)
	Apollo.RegisterEventHandler("OwnedCommodityOrders", 					"OnOwnedCommodityOrders", self)
	Apollo.RegisterEventHandler("CREDDExchangeInfoResults", 				"OnCREDDExchangeInfoResults", self)

	Apollo.RegisterEventHandler("CommodityAuctionRemoved", 					"OnCommodityAuctionRemoved", self)
	Apollo.RegisterEventHandler("CommodityAuctionFilledPartial", 			"OnCommodityAuctionUpdated", self)
	Apollo.RegisterEventHandler("PostCommodityOrderResult", 				"OnPostCommodityOrderResult", self)

	Apollo.RegisterEventHandler("ItemAuctionWon", 							"OnItemAuctionRemoved", self)
	Apollo.RegisterEventHandler("ItemAuctionOutbid", 						"OnItemAuctionRemoved", self)
	Apollo.RegisterEventHandler("ItemAuctionExpired", 						"OnItemAuctionRemoved", self)
	Apollo.RegisterEventHandler("ItemCancelResult", 						"OnItemCancelResult", self)
	Apollo.RegisterEventHandler("ItemAuctionBidPosted", 					"OnItemAuctionUpdated", self)
	Apollo.RegisterEventHandler("PostItemAuctionResult", 					"OnItemAuctionResult", self)
	Apollo.RegisterEventHandler("ItemAuctionBidResult", 					"OnItemAuctionResult", self)
	
	Apollo.RegisterEventHandler("AccountEntitlementUpdate",					"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("PremiumSystemUpdate",						"OnPremiumSystemUpdate", self)

	Apollo.CreateTimer("MarketplaceUpdateTimer", 60, true)
	Apollo.StopTimer("MarketplaceUpdateTimer")
	
	self:RequestData()
end

function MarketplaceListings:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("InterfaceMenu_AuctionListings"), nSaveVersion = 4})
end

function MarketplaceListings:OnInterfaceMenuListHasLoaded()
	local tData = { "InterfaceMenu_ToggleMarketplaceListings", "", "Icon_Windows32_UI_CRB_InterfaceMenu_MarketplaceListings" }
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_AuctionListings"), tData)
	
	self:UpdateInterfaceMenuAlerts()
end

function MarketplaceListings:UpdateInterfaceMenuAlerts()
	local nTotal = self.tOrderCount.nBuy + self.tOrderCount.nSell + self.tAuctionsCount.nSell + self.tAuctionsCount.nBuy + self.nCreddListCount
	if nTotal <= 0 then
		Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", Apollo.GetString("InterfaceMenu_AuctionListings"), {false, "", 0})
	else
		Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", Apollo.GetString("InterfaceMenu_AuctionListings"), {true, "", nTotal})
	end
end

function MarketplaceListings:OnToggle()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Close()
	else
		self:BuildWindows()
	end
end

function MarketplaceListings:BuildWindows()
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "MarketplaceListingsForm", nil, self)
	
	self.wndConfirmDelete = self.wndMain:FindChild("ConfirmBlocker")
	local nMainWidth = self.wndMain:GetWidth()
	self.wndMain:SetSizingMinimum(nMainWidth, 300)
	self.wndMain:SetSizingMaximum(nMainWidth, 1000)
	
	local wndNavigation 		= self.wndMain:FindChild("Navigation")
	self.wndBtnAuctionListing 	= wndNavigation:FindChild("btnAuctionHouseNav")
	self.wndBtnCommodityListing = wndNavigation:FindChild("btnCommodityNav")
	self.wndBtnCREDDListing 	= wndNavigation:FindChild("btnCREDDNav")

	self.wndContentAuctionList = self.wndMain:FindChild("AuctionScroll")
	self.wndContentCommodityList = self.wndMain:FindChild("CommodityScroll")
	self.wndContentCREDDList = self.wndMain:FindChild("CREDDScroll")
	
	self.wndCreddHeader = Apollo.LoadForm(self.xmlDoc, "HeaderItem", self.wndContentCREDDList, self)
	self.wndCreddHeader:FindChild("HeaderItemBtn"):SetCheck(true)

	self.wndAuctionBuyHeader = Apollo.LoadForm(self.xmlDoc, "HeaderItem", self.wndContentAuctionList, self)
	self.wndAuctionBuyHeader:FindChild("HeaderItemBtn"):SetCheck(true)

	self.wndAuctionSellHeader = Apollo.LoadForm(self.xmlDoc, "HeaderItem", self.wndContentAuctionList, self)
	self.wndAuctionSellHeader:FindChild("HeaderItemBtn"):SetCheck(true)

	self.wndCommodityBuyHeader = Apollo.LoadForm(self.xmlDoc, "HeaderItem", self.wndContentCommodityList, self)
	self.wndCommodityBuyHeader:FindChild("HeaderItemBtn"):SetCheck(true)

	self.wndCommoditySellHeader = Apollo.LoadForm(self.xmlDoc, "HeaderItem", self.wndContentCommodityList, self)
	self.wndCommoditySellHeader:FindChild("HeaderItemBtn"):SetCheck(true)

	self:ManangeWndAndRequestData()

	Apollo.StartTimer("MarketplaceUpdateTimer")
	Event_FireGenericEvent("WindowManagementAdd", { wnd = self.wndMain, strName = Apollo.GetString("InterfaceMenu_AuctionListings"), nSaveVersion = 5 })
end

function MarketplaceListings:OnToggleFromAuctionHouse() 
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Close()
	else
		self:BuildWindows()
		self.wndBtnAuctionListing:SetCheck(true)
		self:OnAuctionListToggle()
	end
end

function MarketplaceListings:OnToggleFromCommodities() 
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Close()
	else
		self:BuildWindows()
		self.wndBtnCommodityListing:SetCheck(true)
		self:OnCommodityListToggle()
	end
end

function MarketplaceListings:OnToggleFromCREDD() 
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Close()
	else
		self:BuildWindows()
		self.wndBtnCREDDListing:SetCheck(true)
		self:OnCREDDListToggle()
	end
end

function MarketplaceListings:OnDestroy()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Destroy()
		self.wndMain = nil
		Apollo.StopTimer("MarketplaceUpdateTimer")
	end
end

function MarketplaceListings:ManangeWndAndRequestData()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:FindChild("AuctionScroll"):Show(false)
		self.wndMain:FindChild("CommodityScroll"):Show(false)
		self.wndMain:FindChild("CREDDScroll"):Show(false)
		self.wndMain:FindChild("WaitScreen"):Show(true)
		for idx, wndCurr in pairs({ self.wndCreddHeader, self.wndAuctionBuyHeader, self.wndAuctionSellHeader, self.wndCommodityBuyHeader, self.wndCommoditySellHeader }) do
			wndCurr:FindChild("HeaderItemList"):DestroyChildren()
		end
	end

	self:RequestData()
	self.bRequestData = nil
end

function MarketplaceListings:RequestData()
	self.bRequestData = true
	MarketplaceLib.RequestOwnedCommodityOrders() -- Leads to OwnedCommodityOrders
	MarketplaceLib.RequestOwnedItemAuctions() -- Leads to OwnedItemAuctions
	CREDDExchangeLib.RequestExchangeInfo() -- Leads to OnCREDDExchangeInfoResults
end

function MarketplaceListings:RedrawData()
	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	self.wndMain:FindChild("AuctionScroll"):Show(false)
	self.wndMain:FindChild("CommodityScroll"):Show(false)
	self.wndMain:FindChild("CREDDScroll"):Show(false)
	self.wndMain:FindChild("WaitScreen"):Show(true)
	for idx, wndCurr in pairs({ self.wndCreddHeader, self.wndAuctionBuyHeader, self.wndAuctionSellHeader, self.wndCommodityBuyHeader, self.wndCommoditySellHeader }) do
		wndCurr:FindChild("HeaderItemList"):DestroyChildren()
	end

	if self.arOrders ~= nil then
		self:OnOwnedCommodityOrders(self.arOrders)
	end
	if self.arAuctions ~= nil then
		self:OnOwnedItemAuctions(self.arAuctions)
	end
	if self.arCreddList ~= nil then
		self:OnCREDDExchangeInfoResults({}, self.arCreddList)
	end
end

function MarketplaceListings:OnOwnedItemAuctions(arAuctions)
	local nNewAuctions = 0
	local nNewBids = 0
	if arAuctions then
		for nIdx, aucCurrent in pairs(arAuctions) do
			if not aucCurrent:IsOwned() then
				nNewBids = nNewBids + 1
			else
				nNewAuctions = nNewAuctions + 1
			end
		end
	end
	self.tAuctionsCount = { nSell = nNewAuctions, nBuy = nNewBids}
	self.arAuctions = arAuctions
	if not self.bRequestData and not (self.wndMain and self.wndMain:IsValid()) then
		return
	end

	
	for nIdx, aucCurrent in pairs(arAuctions) do
		if aucCurrent and ItemAuction.is(aucCurrent) then
			if self.wndMain and self.wndMain:IsValid() then
				self:BuildAuctionOrder(nIdx, aucCurrent, aucCurrent:IsOwned() and self.wndAuctionSellHeader:FindChild("HeaderItemList") or self.wndAuctionBuyHeader:FindChild("HeaderItemList"))
			end
		end
	end
	
	if self.wndMain and self.wndMain:IsValid() then
		self:SharedDrawMain()
	end
end

function MarketplaceListings:OnOwnedCommodityOrders(arOrders)
	self.tPrevOrderCount = self.tOrderCount
	self.tOrderCount.nBuy = 0
	self.tOrderCount.nSell = 0
	local bWindowOpen = self.wndMain and self.wndMain:IsValid()
	if arOrders then
		for idx = 1, #arOrders do
			if arOrders[idx]:IsBuy() then
				self.tOrderCount.nBuy = self.tOrderCount.nBuy + 1
				if bWindowOpen then
					self:BuildCommodityOrder(nIdx, arOrders[idx], self.wndCommodityBuyHeader:FindChild("HeaderItemList"))
				end
			else
				self.tOrderCount.nSell = self.tOrderCount.nSell + 1
				if bWindowOpen then
					self:BuildCommodityOrder(nIdx, arOrders[idx], self.wndCommoditySellHeader:FindChild("HeaderItemList"))
				end
			end
		end
	end
	
	self.arOrders = arOrders
	if bWindowOpen then
		self:SharedDrawMain()
	end
end

function MarketplaceListings:OnCREDDExchangeInfoResults(arMarketStats, arOrders)
	self.nCreddListCount = 0
	if arOrders then
		self.nCreddListCount = #arOrders
	end
	self.arCreddList = arOrders
	if not self.bRequestData and not (self.wndMain and self.wndMain:IsValid()) then
		return
	end

	for nIdx, tCurrOrder in pairs(self.arCreddList) do
		if self.wndMain and self.wndMain:IsValid() then
			self:BuildCreddOrder(nIdx, tCurrOrder, self.wndCreddHeader:FindChild("HeaderItemList"))
		end
	end

	if self.wndMain and self.wndMain:IsValid() then
		self:SharedDrawMain()
	end
end

function MarketplaceListings:SharedDrawMain()
	self.wndMain:Invoke()
	self.wndContentAuctionList:Show(self.wndBtnAuctionListing:IsChecked())
	self.wndContentCommodityList:Show(self.wndBtnCommodityListing:IsChecked())
	self.wndContentCREDDList:Show(self.wndBtnCREDDListing:IsChecked())
	self.wndMain:FindChild("WaitScreen"):Show(false)

	-- Resizing and coloring
	local tHeaders =
	{
		{ strTitle = "Marketplace_CreddLimit",				wnd = self.wndCreddHeader, 			eRewardProperty = 0 }, -- No limit for CREDD
		{ strTitle = "Marketplace_AuctionLimitBuyBegin",	wnd = self.wndAuctionBuyHeader, 	eRewardProperty = AccountItemLib.CodeEnumRewardProperty.AuctionBids },
		{ strTitle = "Marketplace_AuctionLimitBegin",		wnd = self.wndAuctionSellHeader,	eRewardProperty = AccountItemLib.CodeEnumRewardProperty.AuctionListings },
		{ strTitle = "Marketplace_CommodityLimitBuyBegin",	wnd = self.wndCommodityBuyHeader, 	eRewardProperty = AccountItemLib.CodeEnumRewardProperty.CommodityOrders },
		{ strTitle = "Marketplace_CommodityLimitBegin",		wnd = self.wndCommoditySellHeader, 	eRewardProperty = AccountItemLib.CodeEnumRewardProperty.CommodityOrders },
	}
	
	local nTotalActiveAuctions = #self.wndAuctionBuyHeader:FindChild("HeaderItemList"):GetChildren() + #self.wndAuctionSellHeader:FindChild("HeaderItemList"):GetChildren()
	local nTotalActiveCommodity = #self.wndCommodityBuyHeader:FindChild("HeaderItemList"):GetChildren() + #self.wndCommoditySellHeader:FindChild("HeaderItemList"):GetChildren()
	local nTotalActiveCREDD = #self.wndCreddHeader:FindChild("HeaderItemList"):GetChildren()
	
	for idx, tHeaderData in pairs(tHeaders) do
		local wndCurr = tHeaderData.wnd
		local wndItemList = wndCurr:FindChild("HeaderItemList")
		local nChildrenCount = #wndItemList:GetChildren()
		if nChildrenCount == 0 then
			wndCurr:Show(false)
		else
			local wndHeaderBtn = wndCurr:FindChild("HeaderItemBtn")
			local bIsChecked = wndHeaderBtn:IsChecked()
			local nLeft, nTop, nRight, nBottom = wndCurr:GetOriginalLocation():GetOffsets()
			local nBuffer = nBottom - nTop
			
			if bIsChecked then
				nBuffer = wndItemList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop) + wndHeaderBtn:GetHeight()
			end
			
			wndCurr:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nBuffer)
			wndItemList:Show(bIsChecked)
			wndCurr:Show(true)
			
			local wndHeaderItemTitle = wndCurr:FindChild("HeaderItemTitle")
			
			local nBaseMaxCount = AccountItemLib.GetStaticRewardPropertyForTier(0, tHeaderData.eRewardProperty, nil, true).nValue
			local nCurrentMaxCount = AccountItemLib.GetPlayerRewardProperty(tHeaderData.eRewardProperty).nValue
			local strMaxCount = ""
			local strColor = "UI_WindowTextDefault"
			if nCurrentMaxCount and nBaseMaxCount then
				strMaxCount = tostring(nCurrentMaxCount)
				if nCurrentMaxCount > nBaseMaxCount then
					strColor = "UI_WindowYellow"
				end
			end

			local strLimitText = string.format('<T Font="CRB_HeaderTiny" TextColor="%s">%s</T>', strColor, strMaxCount)
			local strText =  String_GetWeaselString(Apollo.GetString(tHeaderData.strTitle), nChildrenCount, strLimitText)
			wndHeaderItemTitle:SetAML(string.format('<T Font="CRB_HeaderTiny" TextColor="UI_WindowTextDefault">%s</T>', strText))
		end		
	end
	
	local wndCREDDScroll = self.wndMain:FindChild("CREDDScroll")
	local wndAuctionScroll = self.wndMain:FindChild("AuctionScroll")
	local wndCommodityScroll = self.wndMain:FindChild("CommodityScroll")
		
	local strCREDDNoListings = ""
	if nTotalActiveCREDD == 0 then
		strCREDDNoListings = Apollo.GetString("MarketplaceListings_NoActiveListings")
	end
	wndCREDDScroll:SetText(strCREDDNoListings)
	wndCREDDScroll:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	local strAuctionNoListings = ""
	if nTotalActiveAuctions == 0 then
		strAuctionNoListings = Apollo.GetString("MarketplaceListings_NoActiveListings")
	end
	wndAuctionScroll:SetText(strAuctionNoListings)
	wndAuctionScroll:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	local strCommodityNoListings = ""
	if nTotalActiveCommodity == 0 then
		strCommodityNoListings = Apollo.GetString("MarketplaceListings_NoActiveListings")
	end
	wndCommodityScroll:SetText(strCommodityNoListings)
	wndCommodityScroll:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function MarketplaceListings:OnHeaderItemToggle(wndHandler, wndControl)
	self:SharedDrawMain()
end

function MarketplaceListings:OnAuctionListToggle() 
	if self.wndBtnAuctionListing:IsChecked() then 
		self.wndContentAuctionList:Show(true)
		self.wndContentCommodityList:Show(false)
		self.wndContentCREDDList:Show(false)
	else 
		return
	end
end

function MarketplaceListings:OnCommodityListToggle() 
	if self.wndBtnCommodityListing:IsChecked() then 
		self.wndContentAuctionList:Show(false)
		self.wndContentCommodityList:Show(true)
		self.wndContentCREDDList:Show(false)
	else 
		return
	end
end

function MarketplaceListings:OnCREDDListToggle() 
	if self.wndBtnCREDDListing:IsChecked() then 
		self.wndContentAuctionList:Show(false)
		self.wndContentCommodityList:Show(false)
		self.wndContentCREDDList:Show(true)
	else 
		return
	end
end

-----------------------------------------------------------------------------------------------
-- Item Drawing
-----------------------------------------------------------------------------------------------

function MarketplaceListings:BuildAuctionOrder(nIdx, aucCurrent, wndParent)
	local tItem = aucCurrent:GetItem()
	local wndCurr = self:FactoryProduce(wndParent, "AuctionItem", aucCurrent)

	local bIsOwnAuction = aucCurrent:IsOwned()
	local nCount = aucCurrent:GetCount()
	local nBidAmount = aucCurrent:GetCurrentBid():GetAmount()
	local nMinBidAmount = aucCurrent:GetMinBid():GetAmount()
	local nBuyoutAmount = aucCurrent:GetBuyoutPrice():GetAmount()
	local strPrefix = bIsOwnAuction and Apollo.GetString("MarketplaceListings_AuctionPrefix") or Apollo.GetString("MarketplaceListings_BiddingPrefix")
	local eTimeRemaining = MarketplaceLib.kCommodityOrderListTimeDays

	if bIsOwnAuction then
		wndCurr:FindChild("AuctionTimeLeftText"):SetText(self:HelperFormatTimeString(aucCurrent:GetExpirationTime()))
		wndCurr:FindChild("ListExpiresIconRed"):Show(false)
		wndCurr:FindChild("ListExpiresIconGreen"):Show(true)
		wndCurr:FindChild("AuctionTimeLeftText"):SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
	elseif eTimeRemaining == ItemAuction.CodeEnumAuctionRemaining.Very_Long then
		wndCurr:FindChild("AuctionTimeLeftText"):SetTextRaw(String_GetWeaselString(Apollo.GetString("MarketplaceAuction_VeryLong"), kstrAuctionOrderDuration))
		wndCurr:FindChild("AuctionTimeLeftText"):SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
		wndCurr:FindChild("ListExpiresIconRed"):Show(false)
		wndCurr:FindChild("ListExpiresIconGreen"):Show(true)
	else
		wndCurr:FindChild("AuctionTimeLeftText"):SetTextRaw(ktTimeRemaining[eTimeRemaining])
		wndCurr:FindChild("AuctionTimeLeftText"):SetTextColor(ApolloColor.new("Reddish"))
		wndCurr:FindChild("ListExpiresIconRed"):Show(true)
		wndCurr:FindChild("ListExpiresIconGreen"):Show(false)
	end

	wndCurr:FindChild("AuctionCancelBtn"):SetData(aucCurrent)
	wndCurr:FindChild("AuctionCancelBtn"):Enable(nBidAmount == 0)
	wndCurr:FindChild("AuctionCancelBtn"):Show(bIsOwnAuction)
	wndCurr:FindChild("AuctionCancelBtnTooltipHack"):Show(bIsOwnAuction and nBidAmount ~= 0)
	wndCurr:FindChild("AuctionPrice"):SetAmount(nBidAmount, true) -- 2nd arg is bInstant
	wndCurr:FindChild("BuyoutPrice"):SetAmount(nBuyoutAmount, true) -- 2nd arg is bInstant
	wndCurr:FindChild("MinimumPrice"):SetAmount(nMinBidAmount, true) -- 2nd arg is bInstant
	wndCurr:FindChild("AuctionBigIcon"):SetSprite(tItem:GetIcon())
	wndCurr:FindChild("AuctionIconAmountText"):SetText(nCount == 1 and "" or nCount)
	wndCurr:FindChild("AuctionItemName"):SetText(String_GetWeaselString(strPrefix, tItem:GetName()))
	Tooltip.GetItemTooltipForm(self, wndCurr:FindChild("AuctionBigIcon"), tItem, {bPrimary = true, bSelling = false, itemCompare = tItem:GetEquippedItemForItemType()})

	wndCurr:FindChild("AuctionItemName"):SetHeightToContentHeight()
	local nAuctionItemNameHeight = wndCurr:FindChild("AuctionItemName"):GetHeight()
	local wndAucItemNameContain = wndCurr:FindChild("AuctionItemNameContainer")
	local nContainLeft, nContainTop, nContainRight, nContainBottom = wndAucItemNameContain:GetAnchorOffsets()
	wndAucItemNameContain:SetAnchorOffsets(nContainLeft, nContainTop, nContainRight, nContainTop + nAuctionItemNameHeight + knAuctionItemTopContentPadding)
	local nLeft, nTop, nRight, nBottom = wndCurr:GetAnchorOffsets()
	wndCurr:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nAuctionItemNameHeight + knAuctionItemBottomContentSpacing)
end

function MarketplaceListings:BuildCommodityOrder(nIdx, aucCurrent, wndParent)	
	local tItem = aucCurrent:GetItem()
	local wndCurr = self:FactoryProduce(wndParent, "CommodityItem", aucCurrent)

	-- Tint a different color if Buy
	local nCount = aucCurrent:GetCount()
	local strPrefix = aucCurrent:IsBuy() and Apollo.GetString("CRB_Buy") or Apollo.GetString("CRB_Sell")
	wndCurr:FindChild("CommodityCancelBtn"):SetData(aucCurrent)
	wndCurr:FindChild("CommodityBuyBG"):Show(aucCurrent:IsBuy())
	wndCurr:FindChild("CommoditySellBG"):Show(not aucCurrent:IsBuy())
	wndCurr:FindChild("CommodityBigIcon"):SetSprite(tItem:GetIcon())
	wndCurr:FindChild("CommodityIconAmountText"):SetText(nCount == 1 and "" or nCount)
	wndCurr:FindChild("CommodityItemName"):SetText(String_GetWeaselString(Apollo.GetString("MarketplaceListings_AuctionLabel"), strPrefix, tItem:GetName()))
	wndCurr:FindChild("CommodityPrice"):SetAmount(aucCurrent:GetPricePerUnit():GetAmount(), true) -- 2nd arg is bInstant
	wndCurr:FindChild("CommodityTimeLeftText"):SetText(self:HelperFormatTimeString(aucCurrent:GetExpirationTime()))
	Tooltip.GetItemTooltipForm(self, wndCurr:FindChild("CommodityBigIcon"), tItem, {bPrimary = true, bSelling = false, itemCompare = tItem:GetEquippedItemForItemType()})

	wndCurr:FindChild("CommodityItemName"):SetHeightToContentHeight()
	local CommodityItemNameHeight = wndCurr:FindChild("CommodityItemName"):GetHeight()
	local nLeft, nTop, nRight, nBottom = wndCurr:GetAnchorOffsets()
	if wndCurr:FindChild("CommodityItemName"):GetHeight() > 25 then
		local wndComItemNameContain = wndCurr:FindChild("CommodityItemNameContainer")
		local nContainLeft, nContainTop, nContainRight, nContainBottom = wndComItemNameContain:GetAnchorOffsets()
		wndComItemNameContain:SetAnchorOffsets(nContainLeft, nContainTop, nContainRight, nContainTop + CommodityItemNameHeight)
		wndCurr:SetAnchorOffsets(nLeft, nTop, nRight, nTop + CommodityItemNameHeight + knCommodityItemBottomContentSpacing)
	end
end

function MarketplaceListings:BuildCreddOrder(nIdx, aucCurrent, wndParent)
	local wndCurr = self:FactoryProduce(wndParent, "CreddItem", aucCurrent)
	wndCurr:FindChild("CreddCancelBtn"):SetData(aucCurrent)
	wndCurr:FindChild("CreddLabel"):SetText(aucCurrent:IsBuy() and Apollo.GetString("MarketplaceCredd_BuyLabel") or Apollo.GetString("MarketplaceCredd_SellLabel"))
	wndCurr:FindChild("CreddPrice"):SetAmount(aucCurrent:GetPrice(), true) -- 2nd arg is bInstant
	wndCurr:FindChild("CreddTimeLeftText"):SetText(self:HelperFormatTimeString(aucCurrent:GetExpirationTime()))
end

-----------------------------------------------------------------------------------------------
-- UI Interaction (mostly to cancel order)
-----------------------------------------------------------------------------------------------

function MarketplaceListings:OnCancelBtn(wndHandler, wndControl)
	local aucCurrent = wndHandler:GetData()

	self.wndConfirmDelete:Show(true)
	self.wndConfirmDelete:FindChild("CancelCommodityConfirmBtn"):Show(wndHandler:GetName() == "CommodityCancelBtn")
	self.wndConfirmDelete:FindChild("CancelAuctionConfirmBtn"):Show(wndHandler:GetName() == "AuctionCancelBtn")
	self.wndConfirmDelete:FindChild("CancelCREDDListingBtn"):Show(wndHandler:GetName() == "CreddCancelBtn")

	if wndHandler:GetName() == "CommodityCancelBtn" then
		self.wndConfirmDelete:FindChild("CancelCommodityConfirmBtn"):SetData(aucCurrent)
		self.wndConfirmDelete:FindChild("Title"):SetText(Apollo.GetString("MarketplaceListings_CancelCommodityConfirm"))

	elseif wndHandler:GetName() == "AuctionCancelBtn" then
		self.wndConfirmDelete:FindChild("CancelAuctionConfirmBtn"):SetData(aucCurrent)
		self.wndConfirmDelete:FindChild("Title"):SetText(Apollo.GetString("MarketplaceListings_CancelAuctionConfirm"))

	else
		self.wndConfirmDelete:FindChild("CancelCREDDListingBtn"):SetData(aucCurrent)
		self.wndConfirmDelete:FindChild("Title"):SetText(Apollo.GetString("MarketplaceListings_CancelCREDDConfirm"))
	end
end

function MarketplaceListings:OnAuctionCancelConfirmBtn(wndHandler, wndControl)
	local aucCurrent = wndHandler:GetData()
	if not aucCurrent then
		return
	end
	aucCurrent:Cancel()
	self.wndMain:FindChild("RefreshBlocker"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthLargeTemp")
	self.wndConfirmDelete:Show(false)
end

function MarketplaceListings:OnCommodityCancelConfirmBtn(wndHandler, wndControl)
	local aucCurrent = wndHandler:GetData()
	if not aucCurrent or not aucCurrent:IsPosted() then
		return
	end
	aucCurrent:Cancel()
	self.wndMain:FindChild("RefreshBlocker"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthLargeTemp")
	self.wndConfirmDelete:Show(false)
end

function MarketplaceListings:OnCreddCancelConfirmBtn(wndHandler, wndControl)
	local aucCurrent = wndHandler:GetData()
	if not aucCurrent or not aucCurrent:IsPosted() then
		return
	end
	CREDDExchangeLib.CancelOrder(aucCurrent)
	self:ManangeWndAndRequestData()
	self.wndMain:FindChild("RefreshBlocker"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthLargeTemp")
	self.wndConfirmDelete:Show(false)
end

function MarketplaceListings:OnCommodityItemSmallMouseEnter(wndHandler, wndControl)
	if wndHandler == wndControl and wndHandler:FindChild("CommodityCancelBtn") then
		wndHandler:FindChild("CommodityCancelBtn"):Show(true)
	end
end

function MarketplaceListings:OnCommodityItemSmallMouseExit(wndHandler, wndControl)
	if wndHandler == wndControl and wndHandler:FindChild("CommodityCancelBtn") then
		wndHandler:FindChild("CommodityCancelBtn"):Show(false)
	end
end

-----------------------------------------------------------------------------------------------
-- Auction/Commodity update events
-----------------------------------------------------------------------------------------------

function MarketplaceListings:OnCommodityAuctionRemoved(eAuctionEventType, oRemoved)
	if self.arOrders ~= nil then
		for nIdx, tCurrOrder in ipairs(self.arOrders) do
			if tCurrOrder == oRemoved then
				table.remove(self.arOrders, nIdx)
				break
			end
		end
		self:RedrawData()
	else
		self:ManangeWndAndRequestData()
	end
end

function MarketplaceListings:OnCommodityAuctionUpdated(oUpdated)
	if self.arOrders ~= nil then
		local bFound = false
		for nIdx, tCurrOrder in ipairs(self.arOrders) do
			if tCurrOrder == oUpdated then
				self.arOrders[nIdx] = oUpdated
				bFound = true
			end
		end
		if not bFound then
			table.insert(self.arOrders, oUpdated)
		end

		self:RedrawData()
	else
		self:ManangeWndAndRequestData()
	end
end

function MarketplaceListings:OnPostCommodityOrderResult(eAuctionResult, oAdded)
	if eAuctionResult ~= MarketplaceLib.AuctionPostResult.Ok or not oAdded:IsPosted() then
		return
	end

	if self.arOrders == nil then
		self.arOrders = {}
	end

	self:OnCommodityAuctionUpdated(oAdded)
end

function MarketplaceListings:OnItemAuctionRemoved(aucRemoved)
	if self.arAuctions ~= nil then
		for nIdx, aucCurrent in ipairs(self.arAuctions) do
			if aucCurrent == aucRemoved then
				table.remove(self.arAuctions, nIdx)
				break
			end
		end
		self:RedrawData()
	else
		self:ManangeWndAndRequestData()
	end
end

function MarketplaceListings:OnItemCancelResult(eAuctionResult, aucRemoved)
	if eAuctionResult == MarketplaceLib.AuctionPostResult.AlreadyHasBid then
		Event_FireGenericEvent("GenericEvent_LootChannelMessage", Apollo.GetString("MarketplaceListings_CantCancelHasBid"))
	end

	if eAuctionResult ~= MarketplaceLib.AuctionPostResult.Ok then
		return
	end

	self:OnItemAuctionRemoved(aucRemoved)
end

function MarketplaceListings:OnItemAuctionUpdated(aucUpdated)
	if self.arAuctions ~= nil then
		local bFound = false
		for nIdx, aucCurrent in ipairs(self.arAuctions) do
			if aucCurrent == aucUpdated then
				self.arAuctions[nIdx] = aucUpdated
				bFound = true
			end
		end
		if not bFound then
			table.insert(self.arAuctions, aucUpdated)
		end

		self:RedrawData()
	else
		self:ManangeWndAndRequestData()
	end
end

function MarketplaceListings:OnItemAuctionResult(eAuctionResult, aucAdded)
	if eAuctionResult ~= MarketplaceLib.AuctionPostResult.Ok then
		return
	end

	if self.arAuctions == nil then
		self.arAuctions = {}
	end

	self:OnItemAuctionUpdated(aucAdded)
end

function MarketplaceListings:OnItemListingClose(wndHandler, wndControl)
	self.wndConfirmDelete:Show(false)
end

-----------------------------------------------------------------------------------------------
-- Entitlement Updates
-----------------------------------------------------------------------------------------------
function MarketplaceListings:OnEntitlementUpdate(tEntitlementInfo)
	local bNotExtras = tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.ExtraAuctions and tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.ExtraCommodityOrders
	local bNotLoyalty = tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.LoyaltyExtraAuctions and tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.LoyaltyExtraCommodityOrders
	if not self.wndMain or not self.wndMain:IsValid() or (bNotLoyalty and bNotExtras) then
		return
	end
	
	self:SharedDrawMain()
end

function MarketplaceListings:OnPremiumSystemUpdate()
	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end
	
	self:SharedDrawMain()
end


-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function MarketplaceListings:HelperFormatTimeString(oExpirationTime)
	local strResult = ""
	local nInSeconds = math.floor(math.abs(Time.SecondsElapsed(oExpirationTime))) -- CLuaTime object
	local nHours = math.floor(nInSeconds / 3600)
	local nMins = math.floor(nInSeconds / 60 - (nHours * 60))

	if nHours > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("MarketplaceListings_Hours"), nHours)
	elseif nMins > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("MarketplaceListings_Minutes"), nMins)
	else
		strResult = Apollo.GetString("MarketplaceListings_LessThan1m")
	end
	return strResult
end

function MarketplaceListings:FactoryProduce(wndParent, strFormName, tObject) -- Using AuctionObjects
	local wnd = wndParent:FindChildByUserData(tObject)
	if not wnd then
		wnd = Apollo.LoadForm(self.xmlDoc, strFormName, wndParent, self)
		wnd:SetData(tObject)
	end
	return wnd
end

local MarketplaceListingsInst = MarketplaceListings:new()
MarketplaceListingsInst:Init()