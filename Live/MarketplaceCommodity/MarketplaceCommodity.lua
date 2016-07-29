-----------------------------------------------------------------------------------------------
-- Client Lua Script for MarketplaceCommodity
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "Money"
require "MarketplaceLib"
require "CommodityOrder"
require "StorefrontLib"
require "AccountItemLib"

local MarketplaceCommodity = {}

local ktOrderAverages =
{
	Top1 	= 1,
	Top10 	= 2,
	Top50	= 3,
}

local knMinLevel = 1
local knMaxLevel = 300

local kCommodityAuctionRake = MarketplaceLib.kCommodityAuctionRake
local kAuctionSearchMaxResults = MarketplaceLib.kAuctionSearchMaxResults
local knButtonTextPadding = 10

local karEvalStrings =
{
	[Item.CodeEnumItemQuality.Inferior] 		= Apollo.GetString("CRB_Inferior"),
	[Item.CodeEnumItemQuality.Average] 			= Apollo.GetString("CRB_Average"),
	[Item.CodeEnumItemQuality.Good] 			= Apollo.GetString("CRB_Good"),
	[Item.CodeEnumItemQuality.Excellent] 		= Apollo.GetString("CRB_Excellent"),
	[Item.CodeEnumItemQuality.Superb] 			= Apollo.GetString("CRB_Superb"),
	[Item.CodeEnumItemQuality.Legendary] 		= Apollo.GetString("CRB_Legendary"),
	[Item.CodeEnumItemQuality.Artifact] 		= Apollo.GetString("CRB_Artifact"),
}

local karEvalColors =
{
	[Item.CodeEnumItemQuality.Inferior] 		= "ItemQuality_Inferior",
	[Item.CodeEnumItemQuality.Average] 			= "ItemQuality_Average",
	[Item.CodeEnumItemQuality.Good] 			= "ItemQuality_Good",
	[Item.CodeEnumItemQuality.Excellent] 		= "ItemQuality_Excellent",
	[Item.CodeEnumItemQuality.Superb] 			= "ItemQuality_Superb",
	[Item.CodeEnumItemQuality.Legendary] 		= "ItemQuality_Legendary",
	[Item.CodeEnumItemQuality.Artifact]		 	= "ItemQuality_Artifact",
}

function MarketplaceCommodity:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function MarketplaceCommodity:Init()
    Apollo.RegisterAddon(self)
end

function MarketplaceCommodity:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("MarketplaceCommodity.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function MarketplaceCommodity:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("WindowManagementReady", 			"OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("ToggleMarketplaceWindow", 			"Initialize", self)
	Apollo.RegisterEventHandler("PostCommodityOrderResult", 		"OnPostCommodityOrderResult", self)
	Apollo.RegisterEventHandler("CommodityAuctionRemoved", 			"OnCommodityAuctionRemoved", self)
	Apollo.RegisterEventHandler("CommodityInfoResults", 			"OnCommodityInfoResults", self)
	Apollo.RegisterEventHandler("OwnedCommodityOrders", 			"OnCommodityDataReceived", self)
	Apollo.RegisterEventHandler("MarketplaceWindowClose", 			"OnWindowClose", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate",			"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("PremiumSystemUpdate",				"OnPremiumSystemUpdate", self)
	Apollo.RegisterEventHandler("StoreLinksRefresh",				"RequestOrderUpdate", self)
	
	Apollo.RegisterTimerHandler("PostResultTimer", 					"OnPostResultTimer", self)

	self.tOrdersCount =
	{
		nBuy = 0,
		nSell = 0,
	}
	
	self.tWndRefs = {}
end

function MarketplaceCommodity:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("MarketplaceCommodity_CommoditiesExchange")})
end

function MarketplaceCommodity:OnWindowClose()
	if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() then
		self:OnSearchClearBtn()
		self.tWndRefs.wndMain:Destroy()
		self.tWndRefs = {}
	end
	Event_CancelCommodities()
end

function MarketplaceCommodity:OnCloseBtnSignal()
	if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain:Close()
	end
end

function MarketplaceCommodity:Initialize()
	if AccountItemLib.CodeEnumEntitlement.EconomyParticipation and AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.EconomyParticipation) == 0 then
		Event_FireGenericEvent("GenericEvent_SystemChannelMessage", Apollo.GetString("CRB_FeatureDisabledForGuests"))
		return
	end

	if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain:Destroy()
	end

	self.tWndRefs.wndMain = Apollo.LoadForm(self.xmlDoc, "MarketplaceCommodityForm", nil, self)
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndMain, strName = Apollo.GetString("MarketplaceCommodity_CommoditiesExchange")})

	self.tWndRefs.wndMain:SetSizingMinimum(790, 600)
	self.tWndRefs.wndMain:SetSizingMaximum(790, 1600)

	self.tWndRefs.wndMain:FindChild("FilterOptionsBtn"):AttachWindow(self.tWndRefs.wndMain:FindChild("FilterOptionsContainer"))
	local wndMaxContainer = self.tWndRefs.wndMain:FindChild("FilterOptionsLevelMaxContainer")
	wndMaxContainer:FindChild("FilterOptionsLevelUpBtn"):SetData(self.tWndRefs.wndMain:FindChild("FilterOptionsLevelMaxContainer"))
	wndMaxContainer:FindChild("FilterOptionsLevelDownBtn"):SetData(self.tWndRefs.wndMain:FindChild("FilterOptionsLevelMaxContainer"))
	wndMaxContainer:FindChild("FilterOptionsLevelEditBox"):SetText(knMaxLevel)
	wndMaxContainer:FindChild("FilterOptionsLevelUpBtn"):Enable(false)

	local wndMinContainer = self.tWndRefs.wndMain:FindChild("FilterOptionsLevelMinContainer")
	wndMinContainer:FindChild("FilterOptionsLevelUpBtn"):SetData(self.tWndRefs.wndMain:FindChild("FilterOptionsLevelMinContainer"))
	wndMinContainer:FindChild("FilterOptionsLevelDownBtn"):SetData(self.tWndRefs.wndMain:FindChild("FilterOptionsLevelMinContainer"))
	wndMinContainer:FindChild("FilterOptionsLevelEditBox"):SetText(knMinLevel)
	wndMinContainer:FindChild("FilterOptionsLevelDownBtn"):Enable(false)

	self.tWndRefs.wndMain:FindChild("PostResultNotification"):Show(false, true)
	self.tWndRefs.wndMain:FindChild("WaitingScreen"):Show(false, true)
	
	self.tWndRefs.wndBuyNowHeader 		= self.tWndRefs.wndMain:FindChild("HeaderBuyNowBtn")
	self.tWndRefs.wndBuyOrderHeader 	= self.tWndRefs.wndMain:FindChild("HeaderBuyOrderBtn")
	self.tWndRefs.wndSellNowHeader 		= self.tWndRefs.wndMain:FindChild("HeaderSellNowBtn")
	self.tWndRefs.wndSellOrderHeader 	= self.tWndRefs.wndMain:FindChild("HeaderSellOrderBtn")
	
	self.tWndRefs.wndBuyNowHeader:SetCheck(true)

	-- Item Filtering (Rarity)
	self.tFilteredRarity =
	{
		[Item.CodeEnumItemQuality.Inferior] 	= true,
		[Item.CodeEnumItemQuality.Average] 		= true,
		[Item.CodeEnumItemQuality.Good] 		= true,
		[Item.CodeEnumItemQuality.Excellent]	= true,
		[Item.CodeEnumItemQuality.Superb] 		= true,
		[Item.CodeEnumItemQuality.Legendary]	= true,
		[Item.CodeEnumItemQuality.Artifact]		= true,
	}

	local tItemQualities = {}
	for strKey, nQuality in pairs(Item.CodeEnumItemQuality) do
		table.insert(tItemQualities, {strKey = strKey, nQuality = nQuality})
	end
	table.sort(tItemQualities, function(a,b) return a.nQuality < b.nQuality end)

	local wndFilterParent = self.tWndRefs.wndMain:FindChild("FilterContainer"):FindChild("FilterOptionsRarityList")
	for idx, tQuality in ipairs(tItemQualities) do
		local wndFilter = Apollo.LoadForm(self.xmlDoc, "FilterOptionsRarityItem", wndFilterParent, self)
		wndFilter:FindChild("FilterOptionsRarityItemBtn"):SetCheck(true)
		wndFilter:FindChild("FilterOptionsRarityItemBtn"):SetData(tQuality.nQuality)
		wndFilter:FindChild("FilterOptionsRarityItemBtn"):SetText(karEvalStrings[tQuality.nQuality])
		wndFilter:FindChild("FilterOptionsRarityItemBtn"):SetTooltip(karEvalStrings[tQuality.nQuality])
		wndFilter:FindChild("FilterOptionsRarityItemColor"):SetBGColor(karEvalColors[tQuality.nQuality])
	end
	wndFilterParent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	self.ePremiumSystem = AccountItemLib.GetPremiumSystem()
	self.nPremiumTier = AccountItemLib.GetPremiumTier()

	self:InitializeCategories()
	self:OnResizeCategories()
	self:OnHeaderBtnToggle()
	MarketplaceLib.RequestOwnedCommodityOrders()
	
	self.tWndRefs.wndMain:Invoke()

	Sound.Play(Sound.PlayUIWindowCommoditiesExchangeOpen)
end

function MarketplaceCommodity:InitializeCategories()
	-- GOTCHA: Code uses three category levels. UI uses two levels artificially. "TopItem" UI will use data from MidCategory.
	local tFlattenedList = {}
	for idx, tTopCategory in ipairs(MarketplaceLib.GetCommodityFamilies()) do
		for idx2, tMidCategory in ipairs(MarketplaceLib.GetCommodityCategories(tTopCategory.nId)) do
			table.insert(tFlattenedList, { tTopCategory = tTopCategory, tMidCategory = tMidCategory })
		end
	end
	table.sort(tFlattenedList, function(a,b) return a.tMidCategory.strName < b.tMidCategory.strName end)

	for idx, tData in pairs(tFlattenedList) do
		local tTopCategory = tData.tTopCategory
		local tMidCategory = tData.tMidCategory
		local wndTop = self:LoadByName("CategoryTopItem", self.tWndRefs.wndMain:FindChild("MainCategoryContainer"), tMidCategory.strName)
		wndTop:FindChild("CategoryTopBtn"):SetText(tMidCategory.strName)
		wndTop:FindChild("CategoryTopBtn"):SetData(wndTop)

		-- Add an "All" button
		local wndAllBtn = Apollo.LoadForm(self.xmlDoc, "CategoryMidItem", wndTop:FindChild("CategoryTopList"), self)
		wndAllBtn:FindChild("CategoryMidBtn"):SetData({ nTopCategory = tTopCategory.nId, nMidCategory = tMidCategory.nId, nBotCategory = 0 })
		wndAllBtn:FindChild("CategoryMidBtn"):SetText(Apollo.GetString("CRB_All"))
		wndAllBtn:SetName("CategoryMidItem_All")

		-- Add the rest of the middle buttons
		for idx3, tBotCategory in pairs(MarketplaceLib.GetCommodityTypes(tMidCategory.nId)) do
			local wndMid = Apollo.LoadForm(self.xmlDoc, "CategoryMidItem", wndTop:FindChild("CategoryTopList"), self)
			wndMid:FindChild("CategoryMidBtn"):SetData({ nTopCategory = tTopCategory.nId, nMidCategory = tMidCategory.nId, nBotCategory = tBotCategory.nId })
			wndMid:FindChild("CategoryMidBtn"):SetText(tBotCategory.strName)
		end
	end

	self.tWndRefs.wndMain:FindChild("MainCategoryContainer"):SetData({ nTopCategory = 0, nMidCategory = 0, nBotCategory = 0 })
end

function MarketplaceCommodity:OnResizeCategories() -- Can come from XML
	for idx, wndTop in pairs(self.tWndRefs.wndMain:FindChild("MainCategoryContainer"):GetChildren()) do
		local nListHeight = wndTop:FindChild("CategoryTopBtn"):IsChecked() and (wndTop:FindChild("CategoryTopList"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop) + 12) or 0
		local nLeft, nTop, nRight, nBottom = wndTop:GetAnchorOffsets()
		wndTop:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nListHeight + 44)
	end
	self.tWndRefs.wndMain:FindChild("MainCategoryContainer"):RecalculateContentExtents()
	self.tWndRefs.wndMain:FindChild("MainCategoryContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

-----------------------------------------------------------------------------------------------
-- Main Set Up
-----------------------------------------------------------------------------------------------

function MarketplaceCommodity:OnHeaderBtnToggle()
	-- Filters
	local wndFilter = self.tWndRefs.wndMain:FindChild("FilterContainer")
	local bFilterActive = wndFilter:FindChild("FilterClearBtn"):GetData() or false
	wndFilter:FindChild("FilterOptionsContainer"):Show(false)
	wndFilter:FindChild("FilterClearBtn"):Show(bFilterActive) -- GOTCHA: Visibility update is delayed until a manual reset

	-- Main Build
	self.tWndRefs.wndMain:FindChild("MainScrollContainer"):DestroyChildren() -- TODO refactor
	if self.tWndRefs.wndSellNowHeader:IsChecked() or self.tWndRefs.wndSellOrderHeader:IsChecked() then
		self:InitializeSell()
	elseif self.tWndRefs.wndBuyNowHeader:IsChecked() or self.tWndRefs.wndBuyOrderHeader:IsChecked() then
		self:InitializeBuy()
	end

	-- Empty message (if applicable)
	local strMessage = ""
	local bNoResults = #self.tWndRefs.wndMain:FindChild("MainScrollContainer"):GetChildren() == 0
	if bNoResults and Apollo.StringLength(self.tWndRefs.wndMain:FindChild("SearchEditBox"):GetText()) > 0 then
		strMessage = Apollo.GetString("MarketplaceCommodity_NoResults")
	elseif bNoResults then -- If it's a buy tab, and they haven't clicked a category, do a custom message
		local bAnyCategoryChecked = false
		if self.tWndRefs.wndSellNowHeader:IsChecked() or self.tWndRefs.wndSellOrderHeader:IsChecked() then
			bAnyCategoryChecked = true
		else
			for idx, wndCurr in pairs(self.tWndRefs.wndMain:FindChild("MainCategoryContainer"):GetChildren()) do
				if wndCurr:FindChild("CategoryTopBtn") and wndCurr:FindChild("CategoryTopBtn"):IsChecked() then
					bAnyCategoryChecked = true
					break
				end
			end
		end
		strMessage = bAnyCategoryChecked and Apollo.GetString("MarketplaceCommodity_NoResults") or Apollo.GetString("MarketplaceCommodity_PickACategory")
	end
	self.tWndRefs.wndMain:FindChild("MainScrollContainer"):SetText(strMessage)
	self.tWndRefs.wndMain:FindChild("MainScrollContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.tWndRefs.wndMain:FindChild("MainScrollContainer"):SetVScrollPos(0)
	self:OnResizeCategories()
end

function MarketplaceCommodity:InitializeSell()
	local tBothItemTables = {}
	local tAllCategoryNames = {}
	local unitPlayer = GameLib.GetPlayerUnit()

	-- Helper method
	local tCategoryFilterDataIds = self.tWndRefs.wndMain:FindChild("MainCategoryContainer"):GetData() or { nTopCategory = 0, nMidCategory = 0, nBotCategory = 0 }
	local function HelperValidateCategory(tCategoryFilterDataIds, itemCurr)
		if tCategoryFilterDataIds.nBotCategory ~= 0 then
			return tCategoryFilterDataIds.nBotCategory == itemCurr:GetItemType()
		elseif tCategoryFilterDataIds.nMidCategory ~= 0 or tCategoryFilterDataIds.nTopCategory ~= 0 then -- Mid and top get merged
			return tCategoryFilterDataIds.nMidCategory == itemCurr:GetItemFamily() or tCategoryFilterDataIds.nMidCategory == itemCurr:GetItemCategory()
		else
			return true -- No filter set
		end
	end

	-- Build Table
	for key, tCurrData in pairs(unitPlayer:GetInventoryItems()) do
		if HelperValidateCategory(tCategoryFilterDataIds, tCurrData.itemInBag) then
			table.insert(tBothItemTables, { tCurrItem = tCurrData.itemInBag, strName = tCurrData.itemInBag:GetName() })
		end
		
		if not tCurrData.itemInBag:IsSoulbound() then
			tAllCategoryNames[tCurrData.itemInBag:GetItemCategoryName()] = true
		end
	end
	for key, tSatchelItemCategory in pairs(unitPlayer:GetSupplySatchelItems(1)) do
		for key2, tCurrData in pairs(tSatchelItemCategory) do
			if HelperValidateCategory(tCategoryFilterDataIds, tCurrData.itemMaterial) then
				table.insert(tBothItemTables, { tCurrItem = tCurrData.itemMaterial, strName = tCurrData.itemMaterial:GetName() })
			end
			tAllCategoryNames[tCurrData.itemMaterial:GetItemCategoryName()] = true
		end
	end
	table.sort(tBothItemTables, function(a,b) return a.strName < b.strName end)

	-- Show only the relevant categories
	self.tWndRefs.wndMain:FindChild("FilterContainer"):Show(false)
	for idx, wndCurr in pairs(self.tWndRefs.wndMain:FindChild("MainCategoryContainer"):GetChildren()) do
		wndCurr:Show(tAllCategoryNames[wndCurr:GetName()]) -- Compare name against window name
	end

	-- Now build the window and do another layer of filtering
	local strSearchFilter = Apollo.StringToLower(self.tWndRefs.wndMain:FindChild("SearchEditBox"):GetText() or "")
	local bSkipSearchFilter = Apollo.StringLength(strSearchFilter) == 0
	
	for key, tCurrData in pairs(tBothItemTables) do
		local tCurrItem = tCurrData.tCurrItem
		if tCurrItem and tCurrItem:IsCommodity() and (bSkipSearchFilter or string.find(Apollo.StringToLower(tCurrData.strName), strSearchFilter)) then
			local bSellNow = self.tWndRefs.wndSellNowHeader:IsChecked()
			local strWindow = bSellNow and "SimpleListItem" or "AdvancedListItem"
			local strButtonText = bSellNow and Apollo.GetString("MarketplaceCommodity_SellNow") or Apollo.GetString("MarketplaceCommodity_CreateSellOrder")
			self:BuildListItem(tCurrItem, strWindow, strButtonText)

			MarketplaceLib.RequestCommodityInfo(tCurrItem:GetItemId()) -- Leads to OnCommodityInfoResults
		end
	end
	MarketplaceLib.RequestOwnedCommodityOrders() -- Leads to OwnedCommodityOrders
end

function MarketplaceCommodity:InitializeBuy()
	-- Category showing / hiding
	local bAnyCategoryChecked = false
	self.tWndRefs.wndMain:FindChild("FilterContainer"):Show(true)
	for idx, wndCurr in pairs(self.tWndRefs.wndMain:FindChild("MainCategoryContainer"):GetChildren()) do
		wndCurr:Show(true) -- Sell may hide the irrelevant categories
		if not bAnyCategoryChecked and wndCurr:FindChild("CategoryTopBtn") and wndCurr:FindChild("CategoryTopBtn"):IsChecked() then
			bAnyCategoryChecked = true
		end
	end

	MarketplaceLib.RequestOwnedCommodityOrders() -- Leads to OwnedCommodityOrders
	-- Early exit if no search or category (completely blank UI)
	local strSearchFilter = self.tWndRefs.wndMain:FindChild("SearchEditBox"):GetText()
	if not bAnyCategoryChecked and Apollo.StringLength(strSearchFilter) == 0 then
		return
	end

	local bBuyNow = self.tWndRefs.wndBuyNowHeader:IsChecked()
	local strWindow = bBuyNow and "SimpleListItem" or "AdvancedListItem"
	local strBtnText = bBuyNow and Apollo.GetString("MarketplaceCommodity_BuyNow") or Apollo.GetString("MarketplaceCommodity_CreateBuyOrder")

	-- Level Filtering
	local wndFilter = self.tWndRefs.wndMain:FindChild("FilterContainer")
	local nLevelMin = tonumber(wndFilter:FindChild("FilterOptionsLevelMinContainer"):FindChild("FilterOptionsLevelEditBox"):GetText()) or knMinLevel
	local nLevelMax = tonumber(wndFilter:FindChild("FilterOptionsLevelMaxContainer"):FindChild("FilterOptionsLevelEditBox"):GetText()) or knMaxLevel
	if nLevelMin == knMinLevel then
		wndFilter:FindChild("FilterOptionsLevelMinContainer"):FindChild("FilterOptionsLevelDownBtn"):Enable(false)
		wndFilter:FindChild("FilterOptionsLevelMinContainer"):FindChild("FilterOptionsLevelEditBox"):SetText(nLevelMin)
	end
	if nLevelMax == knMaxLevel then
		wndFilter:FindChild("FilterOptionsLevelMaxContainer"):FindChild("FilterOptionsLevelUpBtn"):Enable(false)
		wndFilter:FindChild("FilterOptionsLevelMaxContainer"):FindChild("FilterOptionsLevelEditBox"):SetText(nLevelMax)
	end

	local bExtraFilter = nLevelMin ~= knMinLevel or nLevelMax ~= knMaxLevel
	for nItemQuality, bAllowed in pairs(self.tFilteredRarity) do
		if not bAllowed then
			bExtraFilter = true
			break
		end
	end

	local fnFilter = nil
	if bExtraFilter then
		fnFilter = function (tFilterItem)
			local nItemPowerLevel = tFilterItem:GetPowerLevel()
			return self.tFilteredRarity[tFilterItem:GetItemQuality()] and nItemPowerLevel >= nLevelMin and nItemPowerLevel <= nLevelMax
		end
	end

	local tCategoryFilter = self.tWndRefs.wndMain:FindChild("MainCategoryContainer"):GetData() or { nTopCategory = 0, nMidCategory = 0, nBotCategory = 0 }
	local tSearchResults, bHitMax = MarketplaceLib.SearchCommodityItems(strSearchFilter, tCategoryFilter.nTopCategory, tCategoryFilter.nMidCategory, tCategoryFilter.nBotCategory, fnFilter)

	-- Draw results then request info for each result
	for idx, tCurrData in pairs(tSearchResults) do
		self:BuildListItem(Item.GetDataFromId(tCurrData.nId), strWindow, strBtnText)
		MarketplaceLib.RequestCommodityInfo(tCurrData.nId) -- Leads to OnCommodityInfoResults
		-- TODO: Count the number of request and load spinner until they all come back
	end

	-- If too many results, show a message
	if bHitMax then
		local wndSearchFail = self:LoadByName("TooManySearchResultsText", self.tWndRefs.wndMain:FindChild("MainScrollContainer"), "TooManySearchResultsText")
		local strFilterOrNot = ""
		if wndFilter:FindChild("FilterClearBtn"):GetData() then
			strFilterOrNot = "MarketplaceCommodity_TooManyResultsFilter"
		else
			strFilterOrNot = "MarketplaceCommodity_TooManyResults"
		end
		wndSearchFail:SetText(String_GetWeaselString(Apollo.GetString(strFilterOrNot), tonumber(kAuctionSearchMaxResults)))
	end
end

function MarketplaceCommodity:OnSearchEditBoxChanged(wndHandler, wndControl) -- SearchEditBox
	self.tWndRefs.wndMain:FindChild("SearchClearBtn"):Show(Apollo.StringLength(wndHandler:GetText() or "") > 0)
end

function MarketplaceCommodity:OnSearchClearBtn(wndHandler, wndControl)
	self.tWndRefs.wndMain:FindChild("SearchEditBox"):SetText("")
	self.tWndRefs.wndMain:FindChild("SearchClearBtn"):Show(false)
	self:OnSearchCommitBtn()
end

function MarketplaceCommodity:OnSearchCommitBtn(wndHandler, wndControl) -- ALso SearchEditBox's WindowKeyReturn
	self.tWndRefs.wndMain:FindChild("SearchClearBtn"):SetFocus()
	self.tWndRefs.wndMain:FindChild("RefreshAnimation"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")
	self:OnHeaderBtnToggle()
end

function MarketplaceCommodity:OnRefreshBtn(wndHandler, wndControl) -- Also from lua and multiple XML buttons
	self.tWndRefs.wndMain:FindChild("RefreshAnimation"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")
	self:OnHeaderBtnToggle()
end

-----------------------------------------------------------------------------------------------
-- Main Draw
-----------------------------------------------------------------------------------------------

function MarketplaceCommodity:BuildListItem(tCurrItem, strWindowName, strBtnText)
	local nItemId = tCurrItem:GetItemId()
	local bSellNowOrSellOrder = self.tWndRefs.wndSellNowHeader:IsChecked() or self.tWndRefs.wndSellOrderHeader:IsChecked()
	local nIconBackpackCount = bSellNowOrSellOrder and tCurrItem:GetBackpackCount() or ""
	local wndCurr = self:LoadByName(strWindowName, self.tWndRefs.wndMain:FindChild("MainScrollContainer"), nItemId)
	
	local wndSubmitBtn = wndCurr:FindChild("ListSubmitBtn")
	local wndListIcon = wndCurr:FindChild("ListIcon")
	local luaSubClass = wndListIcon:GetWindowSubclass()
	luaSubClass:SetItem(tCurrItem)
		
	wndCurr:FindChild("ListInputPrice"):SetData(wndCurr)
	wndSubmitBtn:SetData({tCurrItem, wndCurr})
	wndSubmitBtn:Enable(false)
	wndSubmitBtn:SetText(strBtnText)
	wndCurr:FindChild("ListName"):SetText(tCurrItem:GetName())
	wndListIcon:SetData(tCurrItem)
	wndCurr:FindChild("ListCount"):SetData(nIconBackpackCount)
	wndCurr:FindChild("ListCount"):SetText(nIconBackpackCount)
	wndCurr:FindChild("ListInputNumberUpBtn"):SetData(wndCurr)
	wndCurr:FindChild("ListInputNumberDownBtn"):SetData(wndCurr)
	wndCurr:FindChild("ListInputNumberUpBtn"):Enable(nIconBackpackCount ~= 1)
	wndCurr:FindChild("ListInputNumberDownBtn"):Enable(false)
	wndCurr:FindChild("ListInputNumber"):SetData(wndCurr)
	wndCurr:Show(false) -- Invisible until OnCommodityInfoResults fills in the remaining data (so it doesn't flash if invalid)
end

function MarketplaceCommodity:OnListInputNumberChanged(wndHandler, wndControl, strText)
	local wndParent = wndHandler:GetData()
	local nCount = tonumber(strText)
	if nCount then
		if nCount > MarketplaceLib.kMaxCommodityOrder then
			wndParent:FindChild("ListInputNumber"):SetText(MarketplaceLib.kMaxCommodityOrder)
		elseif nCount < 1 then
			wndParent:FindChild("ListInputNumber"):SetText(1)
		end
	else
		nCount = 1
		wndParent:FindChild("ListInputNumber"):SetText(1)
	end
	self:OnListInputNumberHelper(wndParent, nCount)
end

function MarketplaceCommodity:OnListInputNumberUpBtn(wndHandler, wndControl)
	local wndParent = wndHandler:GetData()
	local nNewValue = math.min(MarketplaceLib.kMaxCommodityOrder, tonumber(wndParent:FindChild("ListInputNumber"):GetText() + 1) or 1)
	wndParent:FindChild("ListInputNumber"):SetText(nNewValue)
	self:OnListInputNumberHelper(wndParent, nNewValue)

	wndHandler:SetFocus()
end

function MarketplaceCommodity:OnListInputNumberDownBtn(wndHandler, wndControl)
	local wndParent = wndHandler:GetData()
	local nNewValue = math.max(1, tonumber(wndParent:FindChild("ListInputNumber"):GetText() - 1) or 1)
	wndParent:FindChild("ListInputNumber"):SetText(nNewValue)
	self:OnListInputNumberHelper(wndParent, nNewValue)

	wndHandler:SetFocus()
end

function MarketplaceCommodity:OnListInputNumberHelper(wndParent, nNewValue)
	local nMax = MarketplaceLib.kMaxCommodityOrder
	if self.tWndRefs.wndSellNowHeader:IsChecked() or self.tWndRefs.wndSellOrderHeader:IsChecked() then
		nMax = math.min(nMax, tonumber(wndParent:FindChild("ListCount"):GetData()))
	end
	
	if self.tWndRefs.wndSellNowHeader:IsChecked() or self.tWndRefs.wndBuyNowHeader:IsChecked() then
		self:UpdateDisplayedAverage(wndParent, nNewValue)
	end

	wndParent:FindChild("ListInputNumberUpBtn"):Enable(nNewValue < nMax)
	wndParent:FindChild("ListInputNumberDownBtn"):Enable(nNewValue > 1)
	self:HelperValidateListInputForSubmit(wndParent)
end

function MarketplaceCommodity:OnListInputPriceAmountChanged(wndHandler, wndControl) -- ListInputPrice, data is parent
	-- Allow order posting
	local wndParent = wndHandler:GetData()
	self:HelperValidateListInputForSubmit(wndParent)
end

function MarketplaceCommodity:OnListInputPriceMouseDown(wndHandler, wndControl)
	self:HelperValidateListInputForSubmit(wndHandler:GetData())
end

function MarketplaceCommodity:OnListInputPriceLoseFocus(wndHandler, wndControl)
	self:HelperValidateListInputForSubmit(wndHandler:GetData())
end

function MarketplaceCommodity:HelperValidateListInputForSubmit(wndParent)
	local nAvailable = 0
	local nQuantity = 0
	local nPrice = 0

	local wndCount = wndParent:FindChild("ListCount")
	if wndCount then
		-- If tonumber() fails then this is the Create Buy Order tab
		--    and we want to be able to perform the action so assume '1'.
		nAvailable = tonumber(wndCount:GetData()) or 1
	end

	local wndListInputPrice = wndParent:FindChild("ListInputPrice")
	if wndListInputPrice and wndParent:FindChild("ListInputNumber") and wndParent:FindChild("ListInputNumber"):IsValid() then
		nPrice = math.max(0, tonumber(wndListInputPrice:GetAmount():GetAmount() or 0)) * tonumber(wndParent:FindChild("ListInputNumber"):GetText())
		nPrice = nPrice + math.max(nPrice * MarketplaceLib.kfCommodityBuyOrderTaxMultiplier, MarketplaceLib.knCommodityBuyOrderTaxMinimum)
	end

	local bCanAfford = true
	if self.tWndRefs.wndBuyNowHeader:IsChecked() or self.tWndRefs.wndBuyOrderHeader:IsChecked() then
		bCanAfford = GameLib.GetPlayerCurrency():GetAmount() > nPrice
	end

	if wndListInputPrice then
		wndListInputPrice:SetTextColor(bCanAfford and "white" or "Reddish")
	end

	local wndQuantity = wndParent:FindChild("ListInputNumber")
	if wndQuantity then
		local strListInputNumber = tonumber(wndQuantity:GetText() or "")
		if strListInputNumber then
			nQuantity = strListInputNumber
		end
	end

	local wndListSubmitBtn = wndParent:FindChild("ListSubmitBtn")
	if wndListSubmitBtn then
		local tAuctionAccess = AccountItemLib.GetPlayerRewardProperty(AccountItemLib.CodeEnumRewardProperty.CommodityAccess)
		local bHasAccess = tAuctionAccess and tAuctionAccess.nValue ~= 0
		local bEnable = nPrice > 0 and nQuantity > 0 and nQuantity <= MarketplaceLib.kMaxCommodityOrder and nAvailable > 0 and bCanAfford and bHasAccess
		wndListSubmitBtn:Enable(bEnable)
		if bEnable then
			local tCurrItem = wndListSubmitBtn:GetData()[1]
			local wndParent = wndListSubmitBtn:GetData()[2]
			local monPricePerUnit = wndParent:FindChild("ListInputPrice"):GetAmount() -- not an integer
			local nOrderCount = tonumber(wndParent:FindChild("ListInputNumber"):GetText())
			local bBuyTab = self.tWndRefs.wndBuyNowHeader:IsChecked() or self.tWndRefs.wndBuyOrderHeader:IsChecked()

			if wndParent:FindChild("ListLowerThanVendor") then
				local nItemPrice = 0
			
				if tCurrItem:GetSellPrice() ~= nil then
					nItemPrice = tCurrItem:GetSellPrice():GetAmount()
				end
			
				local nVendorPriceAfterFees = nItemPrice * (1 + (kCommodityAuctionRake / 100))
				wndParent:FindChild("ListLowerThanVendor"):Show(monPricePerUnit:GetAmount() > 0 and nVendorPriceAfterFees > monPricePerUnit:GetAmount())
			end

			local orderNew = bBuyTab and CommodityOrder.newBuyOrder(tCurrItem:GetItemId()) or CommodityOrder.newSellOrder(tCurrItem:GetItemId())
			if nOrderCount and monPricePerUnit:GetAmount() > 0 then
				orderNew:SetCount(nOrderCount)
				orderNew:SetPrices(monPricePerUnit)
				orderNew:SetForceImmediate(self.tWndRefs.wndBuyNowHeader:IsChecked() or self.tWndRefs.wndSellNowHeader:IsChecked())
			end

			if not nOrderCount or not monPricePerUnit or monPricePerUnit:GetAmount() < 1 or not orderNew:CanPost() then
				wndListSubmitBtn:Enable(false)
			else
				wndListSubmitBtn:SetActionData(GameLib.CodeEnumConfirmButtonType.MarketplaceCommoditiesSubmit, orderNew)
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Filtering
-----------------------------------------------------------------------------------------------

function MarketplaceCommodity:OnFilterOptionsLevelUpBtn(wndHandler, wndControl)
	local wndEditBox = wndHandler:GetParent():FindChild("FilterOptionsLevelEditBox")
	local nOldValue = tonumber(wndEditBox:GetText())
	local nNewValue = nOldValue and nOldValue + 1
	wndEditBox:SetText(nNewValue)
	self:HelperCheckValidLevelValues(wndEditBox)
	self.tWndRefs.wndMain:FindChild("FilterContainer:FilterClearBtn"):SetData(true)
end

function MarketplaceCommodity:OnFilterOptionsLevelDownBtn(wndHandler, wndControl)
	local wndEditBox = wndHandler:GetParent():FindChild("FilterOptionsLevelEditBox")
	local nOldValue = tonumber(wndEditBox:GetText())
	local nNewValue = nOldValue and nOldValue - 1
	wndEditBox:SetText(nNewValue)
	self:HelperCheckValidLevelValues(wndEditBox)
	self.tWndRefs.wndMain:FindChild("FilterContainer:FilterClearBtn"):SetData(true)
end

function MarketplaceCommodity:OnFilterEditBoxChanged(wndHandler, wndControl)
	local wndEditBox = wndHandler:GetParent():FindChild("FilterOptionsLevelEditBox")
	self:HelperCheckValidLevelValues(wndEditBox)
	self.tWndRefs.wndMain:FindChild("FilterContainer:FilterClearBtn"):SetData(true) -- GOTCHA: It will flag as dirty bit when the Refresh event gets called
end

function MarketplaceCommodity:OnFilterOptionsRarityItemToggle(wndHandler, wndControl) -- FilterOptionsRarityItemBtn
	self.tFilteredRarity[wndHandler:GetData()] = wndHandler:IsChecked()
	wndHandler:FindChild("FilterOptionsRarityItemCheck"):SetSprite(wndHandler:IsChecked() and "sprCharC_NameCheckYes" or "sprRaid_RedXClose_Centered")
	self.tWndRefs.wndMain:FindChild("FilterContainer"):FindChild("FilterClearBtn"):SetData(true)
end

function MarketplaceCommodity:OnResetFilterBtn(wndHandler, wndControl)
	local wndFilter = self.tWndRefs.wndMain:FindChild("FilterContainer")
	for idx, wndCurr in pairs(wndFilter:FindChild("FilterOptionsRarityList"):GetChildren()) do
		local wndCurrBtn = wndCurr:FindChild("FilterOptionsRarityItemBtn")
		if wndCurrBtn then
			self.tFilteredRarity[wndCurrBtn:GetData()] = true
			wndCurrBtn:SetCheck(true)
			wndCurrBtn:FindChild("FilterOptionsRarityItemCheck"):SetSprite("sprCharC_NameCheckYes")
		end
	end

	wndFilter:FindChild("FilterClearBtn"):SetData(false)
	wndFilter:FindChild("FilterOptionsLevelMinContainer"):FindChild("FilterOptionsLevelEditBox"):SetText(knMinLevel)
	wndFilter:FindChild("FilterOptionsLevelMaxContainer"):FindChild("FilterOptionsLevelEditBox"):SetText(knMaxLevel)
	self:OnRefreshBtn()
end

function MarketplaceCommodity:OnFilterOptionsWindowClosed(wndHandler, wndControl)
	if wndHandler == wndControl and self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() and self.tWndRefs.wndMain:FindChild("FilterClearBtn"):GetData() then
		self:OnRefreshBtn()
	end
end

function MarketplaceCommodity:HelperCheckValidLevelValues(wndChanged)
	local wndFilterOptions = self.tWndRefs.wndMain:FindChild("FilterContainer:FilterOptionsContainer")
	local wndMinLevelFilter = wndFilterOptions:FindChild("FilterOptionsLevelMinContainer:FilterOptionsLevelEditBox")
	local wndMaxLevelFilter = wndFilterOptions:FindChild("FilterOptionsLevelMaxContainer:FilterOptionsLevelEditBox")
	local nMinLevelValue = tonumber(wndMinLevelFilter:GetText()) or knMinLevel
	local nMaxLevelValue = tonumber(wndMaxLevelFilter:GetText()) or knMaxLevel
	local bMinChanged = false
	local bMaxChanged = false

	if wndChanged == wndMinLevelFilter then
		if nMinLevelValue < knMinLevel then
			nMinLevelValue = knMinLevel
			bMinChanged = true
		elseif nMinLevelValue > knMaxLevel then
			nMinLevelValue = knMaxLevel
			bMinChanged = true
		end

		if nMinLevelValue > nMaxLevelValue then
			nMinLevelValue = nMaxLevelValue
			bMinChanged = true
		end
	end

	if wndChanged == wndMaxLevelFilter then
		if nMaxLevelValue < knMinLevel then
			nMaxLevelValue = knMinLevel
			bMaxChanged = true
		elseif nMaxLevelValue > knMaxLevel then
			nMaxLevelValue = knMaxLevel
			bMaxChanged = true
		end

		if nMinLevelValue > nMaxLevelValue and nMinLevelValue > 10 and nMaxLevelValue > 10 then
			nMaxLevelValue = nMinLevelValue
			bMaxChanged = true
		end
	end

	-- In case the Max value is single digit and Min value isn't
	if nMaxLevelValue < nMinLevelValue then
		wndFilterOptions:FindChild("FilterOptionsRefreshBtn"):Enable(false)
	else
		wndFilterOptions:FindChild("FilterOptionsRefreshBtn"):Enable(true)
	end


	if bMinChanged then
		wndMinLevelFilter:SetText(nMinLevelValue)
	end
	if bMaxChanged then
		wndMaxLevelFilter:SetText(nMaxLevelValue)
	end

	wndFilterOptions:FindChild("FilterOptionsLevelMinContainer:FilterOptionsLevelUpBtn"):Enable(nMinLevelValue < knMaxLevel and nMinLevelValue < nMaxLevelValue)
	wndFilterOptions:FindChild("FilterOptionsLevelMinContainer:FilterOptionsLevelDownBtn"):Enable(nMinLevelValue > knMinLevel)
	wndFilterOptions:FindChild("FilterOptionsLevelMaxContainer:FilterOptionsLevelUpBtn"):Enable(nMaxLevelValue < knMaxLevel)
	wndFilterOptions:FindChild("FilterOptionsLevelMaxContainer:FilterOptionsLevelDownBtn"):Enable(nMaxLevelValue > knMinLevel and nMaxLevelValue > nMinLevelValue)
end

-----------------------------------------------------------------------------------------------
-- Category Btns
-----------------------------------------------------------------------------------------------

function MarketplaceCommodity:OnCategoryTopBtnToggle(wndHandler, wndControl)
	local wndParent = wndHandler:GetData()
	self.tWndRefs.wndMain:SetGlobalRadioSel("MarketplaceCommodity_CategoryMidBtn_GlobalRadioGroup", -1)

	local tSearchData = { nTopCategory = 0, nMidCategory = 0, nBotCategory = 0 }
	if wndHandler:IsChecked() then
		local wndAllBtn = wndParent:FindChild("CategoryTopList") and wndParent:FindChild("CategoryTopList"):FindChild("CategoryMidItem_All") or nil
		if wndAllBtn then
			wndAllBtn:FindChild("CategoryMidBtn"):SetCheck(true)
			tSearchData = wndAllBtn:FindChild("CategoryMidBtn"):GetData()
		end
	end

	self.tWndRefs.wndMain:FindChild("MainCategoryContainer"):SetData(tSearchData)
	self:OnRefreshBtn()
	self:OnResizeCategories()
end

function MarketplaceCommodity:OnCategoryMidBtnCheck(wndHandler, wndControl)
	self.tWndRefs.wndMain:FindChild("MainCategoryContainer"):SetData(wndHandler:GetData()) -- { nTopCategory, nMidCategory, nBotCategory }
	self:OnRefreshBtn()
end

-----------------------------------------------------------------------------------------------
-- Custom Tooltips
-----------------------------------------------------------------------------------------------

function MarketplaceCommodity:OnGenerateSimpleConfirmTooltip(wndHandler, wndControl, eType, nX, nY) -- wndHandler is ListSubmitBtn, data is { tCurrItem and window "SimpleListItem" }
	local tCurrItem = wndHandler:GetData()[1]
	local wndParent = wndHandler:GetData()[2]
	local monPricePerUnit = wndParent:FindChild("ListInputPrice"):GetAmount() -- not an integer
	local nOrderCount = tonumber(wndParent:FindChild("ListInputNumber"):GetText()) or -1
	if nOrderCount == -1 then
		return
	end

	-- TODO TEMP: This may be deleted soon
	-- TODO: This doesn't update as it's a tooltipform. But this is temp and may be deleted soon.
	local bBuyNow = self.tWndRefs.wndBuyNowHeader:IsChecked()
	local wndTooltip = wndHandler:LoadTooltipForm("MarketplaceCommodity.xml", "SimpleConfirmTooltip", self)
	wndTooltip:FindChild("SimpleConfirmTooltipPrice"):SetAmount(nOrderCount * monPricePerUnit:GetAmount())
	wndTooltip:FindChild("SimpleConfirmTooltipText"):SetText(String_GetWeaselString(Apollo.GetString("MarketplaceCommodity_MultiItem"), nOrderCount, tCurrItem:GetName()))
	wndTooltip:FindChild("SimpleConfirmTooltipTitle"):SetText(Apollo.GetString(bBuyNow and "MarketplaceCommodity_ClickToBuyNow" or "MarketplaceCommodity_ClickToSellNow"))
	-- TODO: Resize to fit text width
end

function MarketplaceCommodity:OnGenerateAdvancedConfirmTooltip(wndHandler, wndControl, eType, nX, nY)
	-- wndHandler is ListSubmitBtn, data is { tCurrItem and window "SimpleListItem" }
	local tCurrItem = wndHandler:GetData()[1]
	local wndParent = wndHandler:GetData()[2]
	local monPricePerUnit = wndParent:FindChild("ListInputPrice"):GetAmount() -- not an integer
	local nOrderCount = tonumber(wndParent:FindChild("ListInputNumber"):GetText()) or -1
	if nOrderCount == -1 then
		return
	end

	local bBuyOrder = self.tWndRefs.wndBuyOrderHeader:IsChecked()
	local nSellCutMultipler = bBuyOrder and 1 or (1 - (kCommodityAuctionRake / 100))
	local strSellTextCut = bBuyOrder and "" or String_GetWeaselString(Apollo.GetString("MarketplaceCommodity_AuctionhouseTax"), (kCommodityAuctionRake * -1))
	local strTitle = bBuyOrder and Apollo.GetString("MarketplaceCommodity_ClickToBuyOrder") or Apollo.GetString("MarketplaceCommodity_ClickToSellOrder")
	local strMainBox = String_GetWeaselString(Apollo.GetString("MarketplaceCommodity_MultiItem"), nOrderCount, tCurrItem:GetName())
	local strDuration = String_GetWeaselString(Apollo.GetString("MarketplaceCommodity_DurationDays"), tostring(MarketplaceLib.kCommodityOrderListTimeDays))

	local wndTooltip = wndHandler:LoadTooltipForm("MarketplaceCommodity.xml", "AdvancedConfirmTooltip", self)
	wndTooltip:FindChild("AdvancedConfirmSellFeeContainer"):Show(not bBuyOrder)
	wndTooltip:FindChild("SimpleConfirmTooltipText"):SetText(strMainBox)
	wndTooltip:FindChild("SimpleConfirmTooltipTitle"):SetText(strTitle)
	wndTooltip:FindChild("AdvancedConfirmDurationText"):SetText(strDuration)
	wndTooltip:FindChild("AdvancedConfirmSellFeeText"):SetText(String_GetWeaselString(Apollo.GetString("Market_ListingFeePercent"), (kCommodityAuctionRake * -1)))
	wndTooltip:FindChild("SimpleConfirmTooltipPrice"):SetAmount(nOrderCount * monPricePerUnit:GetAmount() * nSellCutMultipler)
	-- TODO: Resize to fit text width
end

function MarketplaceCommodity:OnGenerateTooltipFullStats(wndHandler, wndControl, eType, nX, nY) -- GOTCHA: wndHandler is ListSubtitle
	local tStats = wndHandler:GetData()
	if not tStats then
		return
	end

	local nLastCount = 0
	local wndFullStats = wndHandler:LoadTooltipForm("MarketplaceCommodity.xml", "FullStatsFrame", self)
	for nRowIdx = 1, 3 do
		local strBuy = ""
		local nBuyPrice = tStats.arBuyOrderPrices[nRowIdx].monPrice:GetAmount()
		if nBuyPrice > 0 then
			strBuy = wndFullStats:FindChild("HiddenCashWindow"):GetAMLDocForAmount(nBuyPrice, true, "ff2f94ac", "CRB_InterfaceSmall", 0) -- 2nd is skip zeroes, 5th is align left
		else
			strBuy = "<P Font=\"CRB_InterfaceSmall\" TextColor=\"ff2f94ac\">" .. Apollo.GetString("CRB_NoData") .. "</P>"
		end

		local strSell = ""
		local nSellPrice = tStats.arSellOrderPrices[nRowIdx].monPrice:GetAmount()
		if nSellPrice > 0 then
			strSell = wndFullStats:FindChild("HiddenCashWindow"):GetAMLDocForAmount(nSellPrice, true, "ff2f94ac", "CRB_InterfaceSmall", 0) -- 2nd is skip zeroes, 5th is align left
		else
			strSell = "<P Font=\"CRB_InterfaceSmall\" TextColor=\"ff2f94ac\">" .. Apollo.GetString("CRB_NoData") .. "</P>"
		end

		local wndRow = wndFullStats:FindChild("FullStatsGrid"):AddRow("")
		local strCount = String_GetWeaselString(Apollo.GetString("MarketplaceCommodity_Top"), tStats.arBuyOrderPrices[nRowIdx].nCount)
		wndFullStats:FindChild("FullStatsGrid"):SetCellDoc(wndRow, 1, "<P Font=\"CRB_InterfaceSmall\" TextColor=\"ff2f94ac\">" .. strCount .. "</P>")
		wndFullStats:FindChild("FullStatsGrid"):SetCellDoc(wndRow, 2, strBuy)
		wndFullStats:FindChild("FullStatsGrid"):SetCellDoc(wndRow, 3, strSell)
	end
end

function MarketplaceCommodity:OnGenerateTooltipListIcon(wndHandler, wndControl, eType, nX, nY)
	local tCurrItem = wndHandler:GetData()
	Tooltip.GetItemTooltipForm(self, wndHandler, tCurrItem, {itemCompare = tCurrItem:GetEquippedItemForItemType()})
end

-----------------------------------------------------------------------------------------------
-- Messages
-----------------------------------------------------------------------------------------------

function MarketplaceCommodity:OnCommodityInfoResults(nItemId, tStats, tOrders)
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	local wndMatch = self.tWndRefs.wndMain:FindChild("MainScrollContainer"):FindChild(nItemId)
	if not wndMatch or not wndMatch:IsValid() then
		return
	end

	wndMatch:Show(true)
	wndMatch:FindChild("ListItemStatsBubble"):SetData(tStats) -- For OnGenerateTooltipFullStats
	wndMatch:FindChild("ListItemStatsBubble"):Show(tStats.nSellOrderCount and tStats.nSellOrderCount > 0)

	-- Fill in the second cash window with the first found
	local nValueForInput = 0
	local nValueForLeftPrice = 0
	local strNoData = Apollo.GetString("MarketplaceCommodity_AveragePriceNoData")

	if self.tWndRefs.wndBuyNowHeader:IsChecked() then
		wndMatch:FindChild("ListCount"):SetData(tStats.nSellOrderCount)
		wndMatch:FindChild("ListCount"):SetText(tStats.nSellOrderCount)
		nValueForInput = tStats.arSellOrderPrices[ktOrderAverages.Top1].monPrice:GetAmount()
		nValueForLeftPrice = tStats.arSellOrderPrices[ktOrderAverages.Top1].monPrice:GetAmount()
		wndMatch:FindChild("ListSubtitleLeft"):SetText(tStats.arSellOrderPrices[ktOrderAverages.Top50] and Apollo.GetString("MarketplaceCommodity_AverageBuyPrice") or strNoData)
	elseif self.tWndRefs.wndSellNowHeader:IsChecked() then
		nValueForInput = tStats.arBuyOrderPrices[ktOrderAverages.Top1].monPrice:GetAmount()
		nValueForLeftPrice = tStats.arBuyOrderPrices[ktOrderAverages.Top1].monPrice:GetAmount()
		wndMatch:FindChild("ListSubtitleLeft"):SetText(tStats.arBuyOrderPrices[ktOrderAverages.Top50] and Apollo.GetString("MarketplaceCommodity_AverageSellPrice") or strNoData)
	else
		nValueForLeftPrice = tStats.arBuyOrderPrices[ktOrderAverages.Top1].monPrice:GetAmount()
		wndMatch:FindChild("ListSubtitlePriceRight"):Show(tStats.arSellOrderPrices[ktOrderAverages.Top1])
		wndMatch:FindChild("ListSubtitlePriceRight"):SetAmount(tStats.arSellOrderPrices[ktOrderAverages.Top1].monPrice)

		if self.tWndRefs.wndBuyOrderHeader:IsChecked() then
			nValueForInput = tStats.arBuyOrderPrices[ktOrderAverages.Top1].monPrice:GetAmount()
			wndMatch:FindChild("ListSubtitleLeft"):SetText(Apollo.GetString("MarketplaceCommodity_HighestOfferLabel") .. "\n" .. (tStats.arBuyOrderPrices[ktOrderAverages.Top1].monPrice:GetAmount() and "" or strNoData))
			wndMatch:FindChild("ListSubtitleRight"):SetText(Apollo.GetString("MarketplaceCommodity_BuyNowLabel") .. "\n" .. (tStats.arSellOrderPrices[ktOrderAverages.Top1].monPrice:GetAmount() and "" or strNoData))
		elseif self.tWndRefs.wndSellOrderHeader:IsChecked() then
			nValueForInput = tStats.arSellOrderPrices[ktOrderAverages.Top1].monPrice:GetAmount()
			wndMatch:FindChild("ListSubtitleLeft"):SetText(Apollo.GetString("MarketplaceCommodity_SellNowLabel") .. "\n" .. (tStats.arBuyOrderPrices[ktOrderAverages.Top1].monPrice:GetAmount() and "" or strNoData))
			wndMatch:FindChild("ListSubtitleRight"):SetText(Apollo.GetString("MarketplaceCommodity_LowestOfferLabel") .. "\n" .. (tStats.arSellOrderPrices[ktOrderAverages.Top1].monPrice:GetAmount() and "" or strNoData))
		end
	end

	local bCanAfford = true
	if self.tWndRefs.wndBuyNowHeader:IsChecked() or self.tWndRefs.wndBuyOrderHeader:IsChecked() then
		local nPrice = math.max(0, (nValueForInput or 0))
		nPrice = nPrice + math.max(nPrice * MarketplaceLib.kfCommodityBuyOrderTaxMultiplier, MarketplaceLib.knCommodityBuyOrderTaxMinimum)
		bCanAfford = GameLib.GetPlayerCurrency():GetAmount() >= nPrice
	end

	local wndListSubmitBtn = wndMatch:FindChild("ListSubmitBtn")
	local bEnable = nValueForInput
	wndListSubmitBtn:Enable(bEnable)
	if bEnable then
		local tCurrItem = wndListSubmitBtn:GetData()[1]
		local wndParent = wndListSubmitBtn:GetData()[2]
		local monPricePerUnit = wndParent:FindChild("ListInputPrice"):GetAmount() -- not an integer
		local nOrderCount = tonumber(wndParent:FindChild("ListInputNumber"):GetText())
		local bBuyTab = self.tWndRefs.wndBuyNowHeader:IsChecked() or self.tWndRefs.wndBuyOrderHeader:IsChecked()

		local orderNew = bBuyTab and CommodityOrder.newBuyOrder(tCurrItem:GetItemId()) or CommodityOrder.newSellOrder(tCurrItem:GetItemId())
		if nOrderCount and monPricePerUnit:GetAmount() > 0 then
			orderNew:SetCount(nOrderCount)
			orderNew:SetPrices(monPricePerUnit)
			orderNew:SetForceImmediate(self.tWndRefs.wndBuyNowHeader:IsChecked() or self.tWndRefs.wndSellNowHeader:IsChecked())
		end

		if not nOrderCount or not monPricePerUnit or monPricePerUnit:GetAmount() < 1 or not orderNew:CanPost() then
			wndListSubmitBtn:Enable(false)
		else
			wndListSubmitBtn:SetActionData(GameLib.CodeEnumConfirmButtonType.MarketplaceCommoditiesSubmit, orderNew)
		end
	end
	wndMatch:FindChild("ListInputPrice"):SetAmount(nValueForInput or 0)
	wndMatch:FindChild("ListInputPrice"):SetTextColor("white")
	wndMatch:FindChild("ListSubtitlePriceLeft"):Show(nValueForLeftPrice)
	wndMatch:FindChild("ListSubtitlePriceLeft"):SetAmount(nValueForLeftPrice or 0)

	self.tWndRefs.wndMain:FindChild("MainScrollContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function MarketplaceCommodity:OnPostCommodityOrderResult(eAuctionPostResult, orderSource, nActualCost)
	local strOkStringFormat = orderSource:IsBuy() and Apollo.GetString("MarketplaceCommodities_BuyOk") or Apollo.GetString("MarketplaceCommodities_SellOk")
	local tAuctionPostResultToString =
	{
		[MarketplaceLib.AuctionPostResult.Ok] 						= String_GetWeaselString(strOkStringFormat, orderSource:GetCount(), orderSource:GetItem():GetName()),
		[MarketplaceLib.AuctionPostResult.DbFailure] 				= Apollo.GetString("MarketplaceAuction_TechnicalDifficulties"),
		[MarketplaceLib.AuctionPostResult.Item_BadId] 				= Apollo.GetString("MarketplaceAuction_CantPostInvalidItem"),
		[MarketplaceLib.AuctionPostResult.NotEnoughToFillQuantity]	= Apollo.GetString("GenericError_Vendor_NotEnoughToFillQuantity"),
		[MarketplaceLib.AuctionPostResult.NotEnoughCash]			= Apollo.GetString("GenericError_Vendor_NotEnoughCash"),
		[MarketplaceLib.AuctionPostResult.NotReady] 				= Apollo.GetString("MarketplaceAuction_TechnicalDifficulties"),
		[MarketplaceLib.AuctionPostResult.CannotFillOrder]		 	= Apollo.GetString("MarketplaceCommodities_NoOrdersFound"),
		[MarketplaceLib.AuctionPostResult.TooManyOrders] 			= Apollo.GetString("MarketplaceAuction_MaxOrders"),
		[MarketplaceLib.AuctionPostResult.OrderTooBig] 				= Apollo.GetString("MarketplaceAuction_OrderTooBig"),
	}

	local strResult = tAuctionPostResultToString[eAuctionPostResult]
	if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() then

		if self.tWndRefs.wndMain and self.tWndRefs.wndBuyNowHeader:IsChecked() and eAuctionPostResult == MarketplaceLib.AuctionPostResult.CannotFillOrder then
			strResult = Apollo.GetString("MarketplaceCommodity_CannotFillBuyOrder")
		elseif self.tWndRefs.wndSellNowHeader:IsChecked() and eAuctionPostResult == MarketplaceLib.AuctionPostResult.CannotFillOrder then
			strResult = Apollo.GetString("MarketplaceCommodity_CannotFillSellOrder")
		end

		local bResultOK = eAuctionPostResult == MarketplaceLib.AuctionPostResult.Ok
		if bResultOK then
			self:OnRefreshBtn()
		end

		self:OnPostCustomMessage(strResult, bResultOK, 4)

		-- Request up to date info (in case the price/amount has since been updated)
		local itemOrder = orderSource:GetItem()
		if itemOrder then
			MarketplaceLib.RequestCommodityInfo(itemOrder:GetItemId())
		end

		if orderSource:IsPosted() then
			if orderSource:IsBuy() then
				self:UpdateOrderLimit(self.tOrdersCount.nBuy + 1, self.tOrdersCount.nSell)
			else
				self:UpdateOrderLimit(self.tOrdersCount.nBuy, self.tOrdersCount.nSell + 1)
			end
		end
	end
end

function MarketplaceCommodity:OnPostCustomMessage(strMessage, bResultOK, nDuration)
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	local strTitle = bResultOK and Apollo.GetString("CRB_Success") or Apollo.GetString("MarketplaceAuction_ErrorLabel")
	self.tWndRefs.wndMain:FindChild("PostResultNotification"):Show(true)
	self.tWndRefs.wndMain:FindChild("PostResultNotification"):SetTooltip(strTitle)
	self.tWndRefs.wndMain:FindChild("PostResultNotificationSubText"):SetText(strMessage)
	self.tWndRefs.wndMain:FindChild("PostResultNotificationLabel"):SetTextColor(bResultOK and ApolloColor.new("UI_TextHoloTitle") or ApolloColor.new("Reddish"))
	self.tWndRefs.wndMain:FindChild("PostResultNotificationLabel"):SetText(strTitle)
	Apollo.CreateTimer("PostResultTimer", nDuration, false)
end

function MarketplaceCommodity:OnClosePostResultNotification()
	self.tWndRefs.wndMain:FindChild("PostResultNotification"):Show(false)
end

function MarketplaceCommodity:OnCommodityAuctionRemoved(eAuctionEventType, orderRemoved)
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	if orderRemoved:IsBuy() then
		self:UpdateOrderLimit(self.tOrdersCount.nBuy - 1, self.tOrdersCount.nSell)
	else
		self:UpdateOrderLimit(self.tOrdersCount.nBuy, self.tOrdersCount.nSell - 1)
	end
end

function MarketplaceCommodity:OnEntitlementUpdate(tEntitlementInfo)
	if not self.wndMain or (tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.ExtraCommodityOrders and tEntitlementInfo.nEntitlementId ~= AccountItemLib.CodeEnumEntitlement.LoyaltyExtraCommodityOrders) then
		return
	end
	
	self:UpdateSlotNotification()
end

function MarketplaceCommodity:OnPremiumSystemUpdate(ePremiumSystem, nTier)
	self.ePremiumSystem = ePremiumSystem
	self.nPremiumTier = nTier
	
	self:UpdateSlotNotification()
end

function MarketplaceCommodity:UpdateSlotNotification()
	if not self.tWndRefs.wndMain then
		return
	end
	
	self:RefreshStoreLink()
	
	-- Getting Limits
	local nCurrentCount = self.tOrdersCount.nBuy
	local strLimitText = "Marketplace_CommodityLimitBuyBegin"
	local wndSelectedHeader = self.tWndRefs.wndMain:GetRadioSelButton("MarketplaceC_HeaderRadioGroup")
	if wndSelectedHeader == self.tWndRefs.wndSellNowHeader or wndSelectedHeader == self.tWndRefs.wndSellOrderHeader then
		nCurrentCount = self.tOrdersCount.nSell
		strLimitText = "Marketplace_CommodityLimitBegin"
	end
	
	local nCurrentMax = AccountItemLib.GetPlayerRewardProperty(AccountItemLib.CodeEnumRewardProperty.CommodityOrders).nValue
	local nBaseLimit = AccountItemLib.GetStaticRewardPropertyForTier(0, AccountItemLib.CodeEnumRewardProperty.CommodityOrders, nil, true).nValue
	local nMaxFromPremium = nCurrentMax - nBaseLimit
		
	local tAuctionAccess = AccountItemLib.GetPlayerRewardProperty(AccountItemLib.CodeEnumRewardProperty.CommodityAccess)
	local bHasAccess = tAuctionAccess and tAuctionAccess.nValue ~= 0
	local bIsHybrid = self.ePremiumSystem == AccountItemLib.CodeEnumPremiumSystem.Hybrid
	local bIsVIP = self.ePremiumSystem == AccountItemLib.CodeEnumPremiumSystem.VIP
	
	if not bHasAccess then
		nCurrentMax = 0
	end
	
	--Setting up window references
	local wndOpenMarketListingsBtn = self.tWndRefs.wndMain:FindChild("OpenMarketListingsBtn")
	local wndIconMTX = wndOpenMarketListingsBtn:FindChild("IconMTX")
	
	-- Set up the text on "My Listings"
	local strLabel = ""
	if nBaseLimit < nCurrentMax and bIsHybrid then	
		strLabel = string.format("<T TextColor=\"UI_WindowYellow\">" .. nCurrentMax .. "</T>")
		wndIconMTX:SetTooltip(String_GetWeaselString(Apollo.GetString("MarketplaceAuction_AdditionalSlots"), nBaseLimit, nMaxFromPremium))
		wndIconMTX:Show(true)
	else
		strLabel = tostring(nCurrentMax)
		wndIconMTX:Show(false)
	end
	wndOpenMarketListingsBtn:FindChild("Text"):SetAML(string.format("<T Font=\"CRB_Button\" TextColor=\"UI_BtnTextGoldListNormal\">".. String_GetWeaselString(Apollo.GetString(strLimitText), nCurrentCount, strLabel) .. "</T>"))
	
	-- Load the MTX Upsell window
	if not self.tWndRefs.wndMTXSlotNotify then
		self.tWndRefs.wndMTXSlotNotify = Apollo.LoadForm(self.xmlDoc, "MTX_SlotWarning", self.tWndRefs.wndMain:FindChild("RightSide"), self)
		local nFilterLeft, nFilterTop, nFilterRight, nFilterBottom = self.tWndRefs.wndMain:FindChild("RightSide:MetalHeader"):GetAnchorOffsets()		
		
		local nInitialLeft, nInitialTop, nInitialRight, nInitialBottom = self.tWndRefs.wndMTXSlotNotify:GetAnchorOffsets()
		self.tWndRefs.wndMTXSlotNotify:SetAnchorOffsets(nInitialLeft, nInitialTop + nFilterBottom, nInitialRight, nInitialBottom + nFilterBottom)
	end
	
	local nMaxTier = AccountItemLib.GetPremiumTierMax()
	local bCanUpgradeTier = self.nPremiumTier < nMaxTier
	local nCurrentEntitlementCount = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.ExtraCommodityOrders)
	local bCanPurchaseUpgrades = nCurrentEntitlementCount and nCurrentEntitlementCount < AccountItemLib.GetMaxEntitlementCount(AccountItemLib.CodeEnumEntitlement.ExtraCommodityOrders) and self.bStoreLinkValidExtras

	local bDisplayUpsell = nCurrentMax ~= AccountItemLib.GetStaticRewardPropertyForTier(nMaxTier, AccountItemLib.CodeEnumRewardProperty.CommodityOrders).nValue and (not bHasAccess or (nCurrentCount == nCurrentMax and (bCanUpgradeTier or bCanPurchaseUpgrades))) and self.bStoreLinkValid 
	if bDisplayUpsell == self.tWndRefs.wndMTXSlotNotify:IsShown() then
		return
	end
	
	-- If it isn't displayed, we don't need to update it.
	local nUpsellHeight = 0
	if bDisplayUpsell then
		-- More window references
		local wndMTXContainer = self.tWndRefs.wndMTXSlotNotify:FindChild("ContentContainer")
		local wndMTXContent = self.tWndRefs.wndMTXSlotNotify:FindChild("UpsellContainer")
		
		-- Hide the icon if it isn't VIP and shift everything over
		wndMTXContainer:FindChild("VIPIcon"):Show(bIsVIP)
		wndMTXContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
		
		-- We do like our window references
		local wndSigPlayerBtn = wndMTXContent:FindChild("SigPlayerBtn")
		local wndMTXSlotNotifyBody = wndMTXContent:FindChild("Body")
		
		-- Set the correct text for each premium system (Signature is default)
		local strSignatureText = "MarketplaceAuction_BecomeSignature"
		if bIsVIP then
			strSignatureText = "CRB_CN_BecomeVIPMember"
		end
		
		-- You can upgrade the tier if you aren't at the max
		wndSigPlayerBtn:SetText(Apollo.GetString(strSignatureText))
		wndSigPlayerBtn:Show(bCanUpgradeTier)
		wndSigPlayerBtn:FindChild("MTCCallout"):Show(bIsHybrid)
		
		-- Hide the button to buy slots if you already have all the slots and shift everything over
		local wndSlotsBtn = wndMTXContent:FindChild("UnlockSlotsBtn")
		wndSlotsBtn:Show(bCanPurchaseUpgrades)
		wndSlotsBtn:FindChild("MTCCallout"):Show(bIsHybrid)
		self.tWndRefs.wndMTXSlotNotify:FindChild("UpsellBtnContainer"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
		
		-- Using an ML string to set the height accurately later
		local strMLString = ""
		if bIsHybrid then
			if bCanUpgradeTier then
				local nCurrentTierMin = AccountItemLib.GetStaticRewardPropertyForTier(self.nPremiumTier, AccountItemLib.CodeEnumRewardProperty.CommodityOrders, nil, true).nValue
				local nNextTierMin = AccountItemLib.GetStaticRewardPropertyForTier(self.nPremiumTier + 1, AccountItemLib.CodeEnumRewardProperty.CommodityOrders, nil, true).nValue
				strMLString = String_GetWeaselString(Apollo.GetString("MarketplaceAuction_BecomeSignatureOrUnlock"), tostring(nNextTierMin - nCurrentTierMin))
			elseif bCanPurchaseUpgrades then
				strMLString = Apollo.GetString("MarketplaceAuction_UnlockAdditionalSlotsGroups")
			end
		elseif bIsVIP then
			if bCanUpgradeTier then
				strMLString = Apollo.GetString("Marketplace_VIPAccess")				
			end
		end
		wndMTXSlotNotifyBody:SetAML(string.format("<P Font=\"CRB_InterfaceMedium\" Align=\"Left\" TextColor=\"UI_TextHoloBody\">%s</P>", strMLString))
		
		-- Resizing the Upsell windows
		local nOldHeight = wndMTXSlotNotifyBody:GetHeight()
		local nNewWidth, nNewHeight = wndMTXSlotNotifyBody:SetHeightToContentHeight()
		local nDiff = nNewHeight - nOldHeight

		if nDiff < 0 then
			nDiff = 0
		end
		
		local nContentLeft, nContentTop, nContentRight, nContentBottom = wndMTXContent:GetAnchorOffsets()
		wndMTXContent:SetAnchorOffsets(nContentLeft, nContentTop, nContentRight, nContentBottom + nDiff)
		
		local nNotifyLeft, nNotifyTop, nNotifyRight, nNotifyBottom = self.tWndRefs.wndMTXSlotNotify:GetAnchorOffsets()
		self.tWndRefs.wndMTXSlotNotify:SetAnchorOffsets(nNotifyLeft, nNotifyTop, nNotifyRight, nNotifyBottom + nDiff)
		
		nUpsellHeight = self.tWndRefs.wndMTXSlotNotify:GetHeight()
	end
	
	self.tWndRefs.wndMTXSlotNotify:Show(bDisplayUpsell)
	
	local wndResultsContainer = self.tWndRefs.wndMain:FindChild("MainScrollContainer")
	local nOriginalLeft, nOriginalTop, nOriginalRight, nOriginalBottom = wndResultsContainer:GetOriginalLocation():GetOffsets()
	wndResultsContainer:SetAnchorOffsets(nOriginalLeft, nOriginalTop + nUpsellHeight, nOriginalRight, nOriginalBottom)
end

function MarketplaceCommodity:RefreshStoreLink()
	local nMaxSlots = MarketplaceLib.GetMaxCommodityOrders()
	self.bCommodityOrdersFull = ((nMaxSlots - self.tOrdersCount.nBuy) <= 0) or ((nMaxSlots - self.tOrdersCount.nSell) <= 0)
	
	self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.Signature) 
	if self.bCommodityOrdersFull then
		self.bStoreLinkValidExtras = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.ExtraCommodityOrders) 
	end
end

function MarketplaceCommodity:OnUnlockMoreSlots()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.ExtraCommodityOrders)
end

function MarketplaceCommodity:OnBecomeSignature()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

function MarketplaceCommodity:OnGenerateSignatureTooltip(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	Tooltip.GetSignatureTooltipForm(self, wndControl, Apollo.GetString("Signature_CommodityTooltip"))
end

function MarketplaceCommodity:OnPostResultTimer()
	if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() then
		Apollo.StopTimer("PostResultTimer")
		self:OnClosePostResultNotification()
	end
end

-----------------------------------------------------------------------------------------------
-- Order List
-----------------------------------------------------------------------------------------------

function MarketplaceCommodity:RequestOrderUpdate()
	MarketplaceLib.RequestOwnedCommodityOrders() -- Leads to OwnedCommodityOrders
end

function MarketplaceCommodity:OnCommodityDataReceived(tOrders) -- From MarketplaceLib.RequestOwnedCommodityOrders()
	local nBuyCount = 0
	local nSellCount = 0
	for nIdx, tCurrOrder in pairs(tOrders) do
		if tCurrOrder:IsBuy() then
			nBuyCount = nBuyCount + 1
		else
			nSellCount = nSellCount + 1
		end
	end
	self:UpdateOrderLimit(nBuyCount, nSellCount)
end

function MarketplaceCommodity:UpdateOrderLimit(nBuyCount, nSellCount)
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	if nBuyCount < 0 then
		self.tOrdersCount.nBuy = 0
	else
		self.tOrdersCount.nBuy = nBuyCount
	end

	if nSellCount < 0 then
		self.tOrdersCount.nSell = 0
	else
		self.tOrdersCount.nSell = nSellCount
	end

	self:UpdateSlotNotification()
end

function MarketplaceCommodity:OnOpenMarketListingsBtn(wndHandler, wndControl)
	Event_FireGenericEvent("InterfaceMenu_ToggleMarketplaceListings")
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function MarketplaceCommodity:OnListIconMouseUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and wndHandler:GetData() then
		Event_FireGenericEvent("GenericEvent_ContextMenuItem", wndHandler:GetData())
	end
end

function MarketplaceCommodity:OnPostResultNotificationClick(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:Show(false)
	end
end

function MarketplaceCommodity:LoadByName(strForm, wndParent, strCustomName)
	local wndNew = wndParent:FindChild(strCustomName)
	if not wndNew then
		wndNew = Apollo.LoadForm(self.xmlDoc, strForm, wndParent, self)
		wndNew:SetName(strCustomName)
	end
	return wndNew
end

function MarketplaceCommodity:UpdateDisplayedAverage(wndAuction, nCount)
	local tInfo = wndAuction:FindChild("ListItemStatsBubble"):GetData()
	
	if not tInfo then
		return
	end
	
	local eCategory = ktOrderAverages.Top50
	local monAmount = nil
	local strLabel = "MarketplaceCommodity_AveragePrice"
	
	if nCount <= 1 then
		eCategory = ktOrderAverages.Top1
		
		if self.tWndRefs.wndSellNowHeader:IsChecked() then
			strLabel = "MarketplaceCommodity_AverageSellPrice"
		elseif self.tWndRefs.wndBuyNowHeader:IsChecked() then
			strLabel = "MarketplaceCommodity_AverageBuyPrice"
		end
	elseif nCount <= 10 then
		eCategory = ktOrderAverages.Top10
	end
	
	if self.tWndRefs.wndSellNowHeader:IsChecked() then
		monAmount = tInfo.arBuyOrderPrices[eCategory].monPrice
	else
		monAmount = tInfo.arSellOrderPrices[eCategory].monPrice
	end
	
	wndAuction:FindChild("ListSubtitleLeft"):SetText(Apollo.GetString(strLabel))
	wndAuction:FindChild("ListSubtitlePriceLeft"):SetAmount(monAmount)
	wndAuction:FindChild("ListInputPriceBG:ListInputPrice"):SetAmount(monAmount)
end

local MarketplaceCommodityInst = MarketplaceCommodity:new()
MarketplaceCommodityInst:Init()
