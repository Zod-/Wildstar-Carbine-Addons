-----------------------------------------------------------------------------------------------
-- Client Lua Script for SupplySatchel
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local SupplySatchel = {}

local knItemWndWidth 			= 50
local knItemWndHeight 			= 50
local knCategoryScrollbarWidth 	= 21
local kclrWhite = ApolloColor.new("white")
local kclrGray 	= ApolloColor.new("ff555555")
local kclrRed 	= ApolloColor.new("ItemQuantityFull")
local kclrOrange 	= ApolloColor.new("ItemQuantityNearFull")
local knUnloadWaitTime = 300 -- unload from memory if unused for 5 minutes
local knEmptyThreshold = 0
local knMediumThresholdScalar = .90

function SupplySatchel:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function SupplySatchel:Init()
	Apollo.RegisterAddon(self, false, "", {"Util"})
end

function SupplySatchel:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("SupplySatchel.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function SupplySatchel:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("UpdateInventory", 					"OnUpdateInventory", self)
	Apollo.RegisterEventHandler("ToggleTradeSkillsInventory", 		"OnToggleVisibility", self)
	Apollo.RegisterEventHandler("ToggleTradeskillInventoryFromBag", "OnToggleVisibility", self)
	Apollo.RegisterEventHandler("PlayerEnteredWorld", 				"OnPlayerEnteredWorld", self)
	Apollo.RegisterEventHandler("PremiumTierChanged",				"OnPremiumTierChanged", self)
	Apollo.RegisterEventHandler("StoreLinksRefresh",				"RefreshStoreLink", self)

	Apollo.RegisterTimerHandler("InitializeSatchelPart2", "OnInitializeSatchelPart2", self)
	Apollo.RegisterTimerHandler("UnloadSatchel", "OnUnloadSatchel", self)
	Apollo.RegisterEventHandler("LootStackItemSentToTradeskillBag", "OnLootstackItemSentToTradeskillBag", self)
	self.tNewlyAddedItems = {}
	self.tNewlyAddedItemsWindows = {}
end

function SupplySatchel:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("SupplySatchel_Title")})
end

-----------------------------------------------------------------------------------------------
-- SupplySatchelForm Functions
-----------------------------------------------------------------------------------------------
function SupplySatchel:OnLootstackItemSentToTradeskillBag(tItem)
	if tItem then
		self.tNewlyAddedItems[tItem.itemInstance:GetItemId()] = tItem
		if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsShown() then
			self:PopulateSatchel(false)
		end
	end
end

function SupplySatchel:OnPlayerEnteredWorld()
	if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsShown() then
		self:PopulateSatchel(false)
	end
end

function SupplySatchel:OnToggleVisibility(wndHandler, wndControl, eMouseButton)
	if not self.wndMain or not self.wndMain:IsValid() then
		self:InitializeSatchel()
	end

	self.wndMain:Show(not self.wndMain:IsShown())
	if self.wndMain:IsShown() then
		self.wndMain:ToFront()
		self:PopulateSatchel(false)
		Apollo.StopTimer( "UnloadSatchel" )
		Event_FireGenericEvent("SupplySatchelOpen")
	else
		for idx, wnd in pairs(self.tNewlyAddedItemsWindows) do
			wnd:FindChild("NewSatchelItemRunner"):Show(false)
		end
		self.tNewlyAddedItems = {}
		self.tNewlyAddedItemsWindows = {}
		Apollo.CreateTimer("UnloadSatchel", knUnloadWaitTime, false)
		Event_FireGenericEvent("SupplySatchelClosed")
	end
end

function SupplySatchel:InitializeSatchel()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Destroy()
	end

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "SupplySatchelForm", nil, self)
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("SupplySatchel_Title")})

	self.wndCategoryList = self.wndMain:FindChild("CategoryList")

	-- Variables
	self.tItemCache = {}
	self.wndClickedItem = nil
	self.nLastWidth = self.wndMain:GetWidth()
	self.wndMain:SetSizingMinimum(284, 250)
	Apollo.CreateTimer("InitializeSatchelPart2", 0.1, false)
end

function SupplySatchel:OnInitializeSatchelPart2()
	local bShow = self.wndMain:FindChild("ShowAllBtn"):IsChecked()
	for strCategory, arItems in pairs(GameLib.GetPlayerUnit():GetSupplySatchelItems(0)) do
		local wndCat = Apollo.LoadForm(self.xmlDoc, "Category", self.wndCategoryList, self)
		wndCat:FindChild("CategoryText"):SetText(strCategory)

		self.tItemCache[strCategory] = {}

		local tCacheCategory = self.tItemCache[strCategory]
		tCacheCategory.wndCat = wndCat
		tCacheCategory.arItems = arItems
		tCacheCategory.nVisibleItems = 0

		for idx, tCurrItem in ipairs(tCacheCategory.arItems) do
			local wndItem = Apollo.LoadForm(self.xmlDoc, "Item", wndCat:FindChild("ItemList"), self)
			local wndIcon = wndItem:FindChild("Icon")
			local wndCount = wndItem:FindChild("Count")
			local wndHighCountWarnFrame = wndItem:FindChild("HighCountWarnFrame")
			
			wndItem:Show(bShow)
			wndItem:SetData(tCurrItem)
			wndIcon:SetSprite(tCurrItem.itemMaterial:GetIcon())
			wndIcon:GetWindowSubclass():SetItem(tCurrItem.itemMaterial)
			wndIcon:SetData(tCurrItem)
			if tCurrItem.nCount == tCurrItem.nMaxStackCount then
				wndHighCountWarnFrame:Show(true)
				wndCount:SetText(tostring(tCurrItem.nCount).."\n/"..tCurrItem.nMaxStackCount)
				wndCount:SetTextColor(kclrRed)
			elseif tCurrItem.nCount >= tCurrItem.nMaxStackCount * knMediumThresholdScalar then
				wndHighCountWarnFrame:Show(true)
				wndCount:SetText(tostring(tCurrItem.nCount).."\n/"..tCurrItem.nMaxStackCount)
				wndCount:SetTextColor(kclrOrange)
			elseif tCurrItem.nCount > knEmptyThreshold then
				wndCount:SetText(tostring(tCurrItem.nCount))
				wndCount:SetTextColor(kclrWhite)
			else
				wndIcon:SetBGColor(kclrGray)
			end

			if bShow then
				tCacheCategory.nVisibleItems = tCacheCategory.nVisibleItems + 1
			end

			tCurrItem.wndItem = wndItem
			tCurrItem.wndIcon = wndIcon
			tCurrItem.wndCount = wndCount
			tCurrItem.wndHighCountWarnFrame = wndHighCountWarnFrame
		end
	end

	self:OnResize()
	self:PopulateSatchel(false)
	self.nPremiumTier = AccountItemLib.GetPremiumTier()
	self:RefreshStoreLink()
end

function SupplySatchel:OnUnloadSatchel()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Destroy()
		self.wndMain = nil
	end
end

function SupplySatchel:OnUpdateInventory()
	if self.wndMain and self.wndMain:IsShown() then
		self:PopulateSatchel(false)
	end
end

function SupplySatchel:OnToggleTradeskillInventoryFromBag(tAnchors)
	if not self.wndMain or not self.wndMain:IsValid() then
		self:InitializeSatchel()
	end
end

function SupplySatchel:OnShowAll( wndHandler, wndControl, eMouseButton )
	self:PopulateSatchel(true)
end

function SupplySatchel:OnResize()
	for key, tCacheCategory in pairs(self.tItemCache) do
		if tCacheCategory.nVisibleItems > 0 then
			tCacheCategory.wndCat:Show(true)
			self:ResizeCategory(tCacheCategory)
		else
			tCacheCategory.wndCat:Show(false)
		end
	end
	
	self.wndCategoryList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function SupplySatchel:ResizeCategory(tCat)
	local wndItemList = tCat.wndCat:FindChild("ItemList")

	local nCols = math.floor(wndItemList:GetWidth() / knItemWndWidth)
	local nRows = math.ceil(tCat.nVisibleItems / nCols)
	local nLeft, nTop, nRight, nBottom = tCat.wndCat:GetAnchorOffsets()
	local nNewHeight = 51 + nRows * knItemWndHeight
	tCat.wndCat:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nNewHeight)

	wndItemList:ArrangeChildrenTiles(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function SupplySatchel:OnResizeTimer()
	if self.wndMain:GetWidth() ~= self.nLastWidth then
		self:OnResize()
		self.nLastWidth = self.wndMain:GetWidth()
	end
end

function SupplySatchel:OnMainWindowMouseResized( wndHandler, wndControl, eMouseButton)
	if self.timerResize then
		self.timerResize:Stop()
	end
	self.timerResize = ApolloTimer.Create(0.02, false, "OnResizeTimer", self)
end

function SupplySatchel:OnQueryDragDrop( wndHandler, wndControl, nX, nY, wndSource, strType, nData, eResult )
	if strType == "DDBagItem" then
		local itemCurrent = wndSource:GetItem(nData)
		if itemCurrent and itemCurrent:CanMoveToSupplySatchel() then
			return Apollo.DragDropQueryResult.Accept
		end
	end
	return Apollo.DragDropQueryResult.Invalid
end

function SupplySatchel:OnDragDrop( wndHandler, wndControl, nX, nY, wndSource, strType, nData, bDragDropHasBeenReset )
	if strType == "DDBagItem" then
		local itemCurrent = wndSource:GetItem(nData)
		if itemCurrent and itemCurrent:CanMoveToSupplySatchel() then
			itemCurrent:MoveToSupplySatchel()
		end
	end
	return
end

function SupplySatchel:OnMainWindowClosed( wndHandler, wndControl )
	Apollo.CreateTimer("UnloadSatchel", knUnloadWaitTime, false)
end

-----------------------------------------------------------------------------------------------
-- ItemList Functions
-----------------------------------------------------------------------------------------------

function SupplySatchel:OnSearchBoxChanged(wndHandler, wndControl)
	self:PopulateSatchel(true)
end

function SupplySatchel:OnSearchClearBtn(wndHandler, wndControl)
	self.wndMain:FindChild("SearchBox"):SetText("")
	self:PopulateSatchel(true)
	wndHandler:SetFocus() -- Focus on close button to steal focus from input
end

function SupplySatchel:PopulateSatchel(bRescroll)
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil and unitPlayer:IsValid() then
		return
	end
	
	local nVScrollPos = self.wndCategoryList:GetVScrollPos()
	if bRescroll then
		nVScrollPos = 0
	end

	local nMinCount = 1
	if self.wndMain:FindChild("ShowAllBtn"):IsChecked() then
		nMinCount = 0
	end

	local strSearchString = self.wndMain:FindChild("SearchBox"):GetText()
	local bSearchString = Apollo.StringLength(strSearchString) > 0
	self.wndMain:FindChild("SearchClearBtn"):Show(bSearchString)

	local bNeedResize = false
	
	for strCategory, arItems in pairs(unitPlayer:GetSupplySatchelItems(0)) do
		local tCacheCategory = self.tItemCache[strCategory]
		if tCacheCategory then
			tCacheCategory.nVisibleItems = 0
			for idx, tCurrItem in ipairs(arItems) do
				local tCacheItem = tCacheCategory.arItems[idx]

				local strFindName = tCacheItem.itemMaterial:GetName()
				if self.tNewlyAddedItems[tCacheItem.itemMaterial:GetItemId()] ~= nil then
					tCacheItem.wndItem:FindChild("NewSatchelItemRunner"):Show(true)
					table.insert(self.tNewlyAddedItemsWindows , tCacheItem.wndItem)
				end

				if tCacheItem.nCount ~= tCurrItem.nCount or tCacheItem.nMaxStackCount ~= tCurrItem.nMaxStackCount then
					tCacheItem.nCount = tCurrItem.nCount
					tCacheItem.wndItem:SetData(tCurrItem)
					tCacheItem.wndIcon:SetTooltipDoc(nil)
					tCacheItem.wndHighCountWarnFrame:Show(tCurrItem.nCount > tCurrItem.nMaxStackCount)
					if tCurrItem.nCount == tCurrItem.nMaxStackCount then
						tCacheItem.wndCount:SetText(tostring(tCurrItem.nCount).."\n/"..tCurrItem.nMaxStackCount)
						tCacheItem.wndCount:SetTextColor(kclrRed)
						tCacheItem.wndIcon:SetBGColor(kclrWhite)
					elseif tCurrItem.nCount >= tCurrItem.nMaxStackCount * knMediumThresholdScalar then
						tCacheItem.wndCount:SetText(tostring(tCurrItem.nCount).."\n/"..tCurrItem.nMaxStackCount)
						tCacheItem.wndCount:SetTextColor(kclrOrange)
						tCacheItem.wndIcon:SetBGColor(kclrWhite)
					elseif tCurrItem.nCount > knEmptyThreshold then
						tCacheItem.wndCount:SetText(tostring(tCurrItem.nCount))
						tCacheItem.wndCount:SetTextColor(kclrWhite)
						tCacheItem.wndIcon:SetBGColor(kclrWhite)
					else
						tCacheItem.wndCount:SetText("")
						tCacheItem.wndCount:SetTextColor(kclrWhite)
						tCacheItem.wndIcon:SetBGColor(kclrGray)
					end
				end
				if tCurrItem.nCount >= nMinCount and (not bSearchString or self:HelperSearchNameMatch(tCurrItem.itemMaterial:GetName(), strSearchString)) then
					if not tCacheItem.wndItem:IsShown() then
						bNeedResize = true
					end
					
					tCacheItem.wndItem:Show(true)
					tCacheCategory.nVisibleItems = tCacheCategory.nVisibleItems + 1
				else
					if tCacheItem.wndItem:IsShown() then
						bNeedResize = true
					end
					
					tCacheItem.wndItem:Show(false)
				end
			end
		end
	end

	if bNeedResize then
		self:OnResize()
	end
	self.wndCategoryList:SetVScrollPos(nVScrollPos)
end

-- the player clicked an item
function SupplySatchel:OnItemMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	if (eMouseButton == GameLib.CodeEnumInputMouse.Left and bDoubleClick) or eMouseButton == GameLib.CodeEnumInputMouse.Right then
		wndControl:GetData().itemMaterial:TakeFromSupplySatchel(wndControl:GetData().nCount)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Left then
		-- Store the clicked window, waiting for a drag or mouse button up
		self.wndClickedItem = wndControl
	end
end

function SupplySatchel:OnItemMouseMove( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler ~= wndControl then return end
	if self.wndClickedItem and self.wndClickedItem == wndControl then
		-- Clicked and dragged
		Apollo.BeginDragDrop(wndControl, "DDSupplySatchelItem", wndControl:FindChild("Icon"):GetSprite(), wndControl:GetData().idLocation)
		self.wndClickedItem = nil
	end
end

function SupplySatchel:OnItemMouseButtonUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler ~= wndControl then return end
	if self.wndClickedItem and eMouseButton == GameLib.CodeEnumInputMouse.Left then
		if self.wndClickedItem == wndControl then
			-- Clicked and released
			-- Apollo.BeginClickStick(wndControl, "DDSupplySatchelItem", wndControl:FindChild("Icon"):GetSprite(), wndControl:GetData().id)
			self.wndClickedItem = nil
		end
	end
end

function SupplySatchel:HelperSearchNameMatch(strBase, strInput)
	-- Find the first character of a word or an exact match from the start
	strBase = strBase:lower() -- Not case sensitive
	strInput = strInput:lower()
	return strBase:find(strInput, 1, true)
end

function SupplySatchel:OnGenerateTooltip(wndHandler, wndControl, tType, eType, arg1, arg2)
	if Tooltip ~= nil and Tooltip.GetItemTooltipForm ~= nil then
		local tCurrItem = wndControl:GetData()
		Tooltip.GetItemTooltipForm(self, wndControl, tCurrItem.itemMaterial, {bSelling = false, nStackCount = tCurrItem.nCount})
	end
end

-----------------------------------------------------------------------------------------------
-- Premium System Updates
-----------------------------------------------------------------------------------------------

function SupplySatchel:OnPremiumTierChanged(ePremiumSystem, nTier)
	if ePremiumSystem ~= AccountItemLib.CodeEnumPremiumSystem.VIP then
		return
	end
	
	self.nPremiumTier = nTier
	if self.wndMain ~= nil and self.wndMain:IsValid() then
		self:UpdatePremium()
		self:PopulateSatchel(false)
	end
end

function SupplySatchel:UpdatePremium()
	if self.wndMain == nil or not self.wndMain:IsValid() or AccountItemLib.GetPremiumSystem() ~= AccountItemLib.CodeEnumPremiumSystem.VIP then
		return
	end
	
	local wndVipMtxStackIncrease = self.wndMain:FindChild("VIP_MTX_StackIncrease")
	local wndMainGridContainer = self.wndMain:FindChild("MainGridContainer")
	local nLeft, nTop, nRight, nBottom = wndMainGridContainer:GetOriginalLocation():GetOffsets()
	if self.bStoreLinkValid and self.nPremiumTier == 0 then
		nTop = nTop + wndVipMtxStackIncrease:GetHeight()
	end
	wndMainGridContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	
	wndVipMtxStackIncrease:Show(self.bStoreLinkValid and self.nPremiumTier == 0)
end

-----------------------------------------------------------------------------------------------
-- Store Updates
-----------------------------------------------------------------------------------------------

function SupplySatchel:RefreshStoreLink()
	self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.Signature)
	
	self:UpdatePremium()
end

function SupplySatchel:OnBecomePremium()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

-----------------------------------------------------------------------------------------------
-- SupplySatchel Instance
-----------------------------------------------------------------------------------------------
local SupplySatchelInst = SupplySatchel:new()
SupplySatchelInst:Init()
