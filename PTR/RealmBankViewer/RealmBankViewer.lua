-----------------------------------------------------------------------------------------------
-- Client Lua Script for RealmBankViewer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Apollo"
require "Window"
require "Money"
require "AccountItemLib"
require "StorefrontLib"

local RealmBankViewer = {}
local knBagBoxSize = 50
local knSaveVersion = 1

local fnSortItemsByName = function(itemLeft, itemRight)
	if itemLeft == itemRight then
		return 0
	end
	if itemLeft and itemRight == nil then
		return -1
	end
	if itemLeft == nil and itemRight then
		return 1
	end

	local strLeftName = itemLeft:GetName()
	local strRightName = itemRight:GetName()
	if strLeftName < strRightName then
		return -1
	end
	if strLeftName > strRightName then
		return 1
	end

	return 0
end

local fnSortItemsByCategory = function(itemLeft, itemRight)
	if itemLeft == itemRight then
		return 0
	end
	if itemLeft and itemRight == nil then
		return -1
	end
	if itemLeft == nil and itemRight then
		return 1
	end

	local strLeftName = itemLeft:GetItemCategoryName()
	local strRightName = itemRight:GetItemCategoryName()
	if strLeftName < strRightName then
		return -1
	end
	if strLeftName > strRightName then
		return 1
	end

	local strLeftName = itemLeft:GetName()
	local strRightName = itemRight:GetName()
	if strLeftName < strRightName then
		return -1
	end
	if strLeftName > strRightName then
		return 1
	end

	return 0
end

local fnSortItemsByQuality = function(itemLeft, itemRight)
	if itemLeft == itemRight then
		return 0
	end
	if itemLeft and itemRight == nil then
		return -1
	end
	if itemLeft == nil and itemRight then
		return 1
	end

	local eLeftQuality = itemLeft:GetItemQuality()
	local eRightQuality = itemRight:GetItemQuality()
	if eLeftQuality > eRightQuality then
		return -1
	end
	if eLeftQuality < eRightQuality then
		return 1
	end

	local strLeftName = itemLeft:GetName()
	local strRightName = itemRight:GetName()
	if strLeftName < strRightName then
		return -1
	end
	if strLeftName > strRightName then
		return 1
	end

	return 0
end

local ktSortFunctions = {fnSortItemsByName, fnSortItemsByCategory, fnSortItemsByQuality}


function RealmBankViewer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.bShouldSortItems = false
	o.nSortItemType = 1

    return o
end

function RealmBankViewer:Init()
    Apollo.RegisterAddon(self)
end

function RealmBankViewer:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("RealmBankViewer.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function RealmBankViewer:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("HideRealmBank", "HideRealmBank", self)
	Apollo.RegisterEventHandler("ShowRealmBank", "Initialize", self)
    Apollo.RegisterEventHandler("ToggleRealmBank", "Initialize", self)
	Apollo.RegisterEventHandler("CloseVendorWindow", "OnCloseVendorWindow", self)
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate", "OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate", "OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("StoreLinksRefresh", "OnStoreLinksRefresh", self)
end

function RealmBankViewer:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("RealmBank_Header")})
end

function RealmBankViewer:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return nil
	end
	
	return
	{
		nSaveVersion = knSaveVersion,
		bShouldSortItems = self.bShouldSortItems,
		nSortItemType = self.nSortItemType,
	}
end

function RealmBankViewer:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return nil
	end
	
	if not tSavedData or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end
	
	if tSavedData.bShouldSortItems ~= nil then
		self.bShouldSortItems = tSavedData.bShouldSortItems
	end
	
	if tSavedData.nSortItemType ~= nil then
		self.nSortItemType = tSavedData.nSortItemType
	end

	self:BuildSortOptions()
end

function RealmBankViewer:Initialize()
	if self.wndMain ~= nil and self.wndMain:IsValid() then
		self.wndMain:Close()
		self.wndMain:Destroy()
		self.wndMain = nil
	end

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "BankViewerForm", nil, self)
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetOriginalLocation():GetOffsets()
	self.nFirstEverWidth = nRight - nLeft
	self.wndMain:SetSizingMinimum(self.nFirstEverWidth, 280)
	
	self.wndMain:FindChild("OptionsBtn"):AttachWindow(self.wndMain:FindChild("OptionsContainer"))
	self.wndMainBagWindow = self.wndMain:FindChild("MainBagWindow")
	
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("RealmBank_Header"), nSaveVersion = 2})

	self:BuildSortOptions()
	self:OnStoreLinksRefresh() -- Check store link and build the display accordingly
end

function RealmBankViewer:Build()
	local nNumBagSlots = GameLib.GetNumBankBagSlots()

	self.wndMain:FindChild("LockedBlocker"):Show(AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.SharedRealmBankUnlock) <= 0)
	self.wndMain:FindChild("LockedBlocker:Button"):Show(StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.UnlockRealmBank))
	
	local tEntitlementInfo = AccountItemLib.GetEntitlementInfo(AccountItemLib.CodeEnumEntitlement.SharedRealmBankSlots)
	
	local nGridLeft, nGridTop, nGridRight, nGridBottom = self.wndMain:FindChild("BankGridArt"):GetAnchorOffsets()
	
	if not StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.RealmBankSlots)
		or AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.SharedRealmBankSlots) >= tEntitlementInfo.nMaxCount then
		
		local nLeft, nTop, nRight, nBottom = self.wndMain:FindChild("BankBagArt"):GetAnchorOffsets()
		self.wndMain:FindChild("BankGridArt"):SetAnchorOffsets(nGridLeft, nGridTop, nGridRight, nBottom)
		
		self.wndMain:FindChild("BankBagArt"):Show(false)
	else
		local nLeft, nTop, nRight, nBottom = self.wndMain:FindChild("BankBagArt"):GetAnchorOffsets()
		self.wndMain:FindChild("BankGridArt"):SetAnchorOffsets(nGridLeft, nGridTop, nGridRight, nTop - 5)
		
		self.wndMain:FindChild("BankBagArt"):Show(true)
	end

	-- Resize
	self:ResizeBankSlots()
end

function RealmBankViewer:BuildSortOptions()
	if not self.wndMain or not self.wndMain:IsValid() or not self.wndMain:IsShown() then
		return
	end
	
	local wndSortFrame = self.wndMain:FindChild("BankViewerFrame:OptionsContainer:OptionsContainerFrame:ItemSort")
	
	self.wndMainBagWindow:SetSort(self.bShouldSortItems)
	self.wndMainBagWindow:SetItemSortComparer(ktSortFunctions[self.nSortItemType])
	wndSortFrame:FindChild("IconBtnSortOff"):SetCheck(not self.bShouldSortItems)
	wndSortFrame:FindChild("IconBtnSortAlpha"):SetCheck(self.bShouldSortItems and self.nSortItemType == 1)
	wndSortFrame:FindChild("IconBtnSortCategory"):SetCheck(self.bShouldSortItems and self.nSortItemType == 2)
	wndSortFrame:FindChild("IconBtnSortQuality"):SetCheck(self.bShouldSortItems and self.nSortItemType == 3)
end

-----------------------------------------------------------------------------------------------
-- Item Sorting
-----------------------------------------------------------------------------------------------

function RealmBankViewer:OnOptionsSortItemsOff(wndHandler, wndControl)
	self.bShouldSortItems = false
	self.wndMainBagWindow:SetSort(self.bShouldSortItems)
	self.wndMain:FindChild("OptionsBtn"):SetCheck(false)
end

function RealmBankViewer:OnOptionsSortItemsName(wndHandler, wndControl)
	self.bShouldSortItems = true
	self.nSortItemType = 1
	self.wndMainBagWindow:SetSort(self.bShouldSortItems)
	self.wndMainBagWindow:SetItemSortComparer(ktSortFunctions[self.nSortItemType])
	self.wndMain:FindChild("OptionsBtn"):SetCheck(false)
end

function RealmBankViewer:OnOptionsSortItemsByCategory(wndHandler, wndControl)
	self.bShouldSortItems = true
	self.nSortItemType = 2
	self.wndMainBagWindow:SetSort(self.bShouldSortItems)
	self.wndMainBagWindow:SetItemSortComparer(ktSortFunctions[self.nSortItemType])
	self.wndMain:FindChild("OptionsBtn"):SetCheck(false)
end

function RealmBankViewer:OnOptionsSortItemsByQuality(wndHandler, wndControl)
	self.bShouldSortItems = true
	self.nSortItemType = 3
	self.wndMainBagWindow:SetSort(self.bShouldSortItems)
	self.wndMainBagWindow:SetItemSortComparer(ktSortFunctions[self.nSortItemType])
	self.wndMain:FindChild("OptionsBtn"):SetCheck(false)
end


function RealmBankViewer:OnWindowClosed()
	Event_CancelRealmBanking()
	
	self:HideRealmBank()
end

function RealmBankViewer:OnCloseVendorWindow()
	self:HideRealmBank()
end

function RealmBankViewer:HideRealmBank()
	if self.wndMain and self.wndMain:IsValid() then
		local wndMain = self.wndMain
		self.wndMain = nil
		wndMain:Close()
		wndMain:Destroy()
	end
end

function RealmBankViewer:ResizeBankSlots()
	if not self.wndMain or not self.wndMain:IsValid() or not self.wndMain:IsShown() then
		return
	end

	local nNumberOfBoxesPerRow = math.floor(self.wndMain:FindChild("MainBagWindow"):GetWidth() / knBagBoxSize)
	self.wndMain:FindChild("MainBagWindow"):SetBoxesPerRow(nNumberOfBoxesPerRow)
end

function RealmBankViewer:OnBankViewerCloseBtn()
	self:HideRealmBank()
end

function RealmBankViewer:OnEntitlementUpdate(tEntitlement)
	if self.wndMain == nil or not self.wndMain:IsValid() then
		return
	end

	if tEntitlement.nEntitlementId == AccountItemLib.CodeEnumEntitlement.SharedRealmBankUnlock
		or tEntitlement.nEntitlementId == AccountItemLib.CodeEnumEntitlement.SharedRealmBankSlots then
		
		self:Build()
	end
end

function RealmBankViewer:OnStoreLinksRefresh()
	if self.wndMain ~= nil and self.wndMain:IsValid() then
		self:Build()
	end
end

function RealmBankViewer:UnlockRealmBank(wndControl, wndHandler)
	if not StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.UnlockRealmBank) then
		return
	end

	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.UnlockRealmBank)
end

function RealmBankViewer:UnlockMoreBankSlots(wndControl, wndHandler)
	if not StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.RealmBankSlots) then
		return
	end

	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.RealmBankSlots)
end

function RealmBankViewer:OnGenerateTooltip(wndControl, wndHandler, tType, item)
	if wndControl ~= wndHandler then return end
	wndControl:SetTooltipDoc(nil)
	if item ~= nil then
		local itemEquipped = item:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	end
end

local RealmBankViewerInst = RealmBankViewer:new()
RealmBankViewerInst:Init()
