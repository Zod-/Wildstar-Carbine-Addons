-----------------------------------------------------------------------------------------------
-- Client Lua Script for MasterCraftsman
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Apollo"
require "ApolloCursor"
require "CraftingLib"
require "GameLib"
require "Item"
-----------------------------------------------------------------------------------------------
-- MasterCraftsman Module Definition
-----------------------------------------------------------------------------------------------
local MasterCraftsman = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
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

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function MasterCraftsman:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function MasterCraftsman:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- MasterCraftsman OnLoad
-----------------------------------------------------------------------------------------------
function MasterCraftsman:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("MasterCraftsman.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- MasterCraftsman OnDocLoaded
-----------------------------------------------------------------------------------------------
function MasterCraftsman:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "MasterCraftsmanForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)

		Apollo.RegisterEventHandler("MasterCraftsmanOpen", "OnMasterCraftsmanOpen", self)
		Apollo.RegisterEventHandler("MasterCraftsmanClose", "OnMasterCraftsmanClose", self)
		Apollo.RegisterEventHandler("CraftingUpdateCurrent", "OnCraftingUpdateCurrent", self)
	end
end

-----------------------------------------------------------------------------------------------
-- MasterCraftsman Apollo Events
-----------------------------------------------------------------------------------------------
function MasterCraftsman:OnMasterCraftsmanOpen()
	if not self:HelperResumeCraft() then
		self.arItemList = CraftingLib.GetUniversalSchematicsOwned()
		self.nItemIndex = 1
		self:RedrawAll()
	end
end

function MasterCraftsman:OnMasterCraftsmanClose()
	self.wndMain:Close()
end

function MasterCraftsman:OnCraftingUpdateCurrent()
	if self.wndMain:IsShown() and self:IsCrafting() then
		Event_FireGenericEvent("GenericEvent_StartCircuitCraft", CraftingLib.GetCurrentCraft().nSchematicId)
		self.wndMain:Close()
	end
end

-----------------------------------------------------------------------------------------------
-- MasterCraftsmanForm Functions
-----------------------------------------------------------------------------------------------

function MasterCraftsman:RedrawAll()
	local itemCurr = self.arItemList and self.arItemList[self.nItemIndex]
	local wndParent = self.wndMain:FindChild("MainScroll")
	local nScrollPos = wndParent:GetVScrollPos()
	wndParent:DestroyChildren()
	if itemCurr ~= nil then
		self.wndMain:FindChild("Blocker"):Show(false)
		self.wndMain:FindChild("CraftBtn"):Enable(true)
		
		-- Inline Sort Method
		local function SortByQuality(tItem1, tItem2) -- GOTCHA: This needs to be declared before it's used
			if tItem1:GetItemQuality() == tItem2:GetItemQuality() then
				return tItem1:GetName() < tItem2:GetName()
			else
				return tItem1:GetItemQuality() < tItem2:GetItemQuality()
			end
		end
		table.sort(self.arItemList, SortByQuality)
		
		for idx, tItem in ipairs(self.arItemList) do

			local wndCurr = Apollo.LoadForm(self.xmlDoc, "SchematicListItem", wndParent, self)
			wndCurr:FindChild("SchematicListItemBtn"):SetData({nIdx = idx, tItem=tItem})
			wndCurr:FindChild("SchematicListItemBtn"):SetCheck(idx == self.nItemIndex)
			
			wndCurr:FindChild("SchematicListItemTitle"):SetTextColor(karEvalColors[tItem:GetItemQuality()])
			wndCurr:FindChild("SchematicListItemTitle"):SetText(tItem:GetName())
			
			local bTextColorRed = self:HelperPrereqFailed(tItem)
			wndCurr:FindChild("SchematicListItemType"):SetTextColor(bTextColorRed and "Reddish" or "UI_TextHoloBodyCyan")
			wndCurr:FindChild("SchematicListItemType"):SetText(tItem:GetItemTypeName())
			
			wndCurr:FindChild("SchematicListItemCantUse"):Show(bTextColorRed)
			wndCurr:FindChild("SchematicListItemIcon"):GetWindowSubclass():SetItem(tItem)
		end
		
		wndParent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		wndParent:SetVScrollPos(nScrollPos)
	
		self.wndMain:SetData(itemCurr)
	else
		self.wndMain:FindChild("Blocker"):Show(true)
		self.wndMain:FindChild("CraftBtn"):Enable(false)
	end
	self.wndMain:Show(true)
	self.wndMain:ToFront()
end

function MasterCraftsman:HelperPrereqFailed(tCurrItem)
	return tCurrItem and tCurrItem:IsEquippable() and not tCurrItem:CanEquip()
end

function MasterCraftsman:HelperResumeCraft()
	local tCurrentCraft = CraftingLib.GetCurrentCraft()
	if self:IsCrafting(tCurrentCraft) then
		Event_FireGenericEvent("GenericEvent_CraftFromPL", tCurrentCraft.nSchematicId)
		return true
	end
	return false
end

function MasterCraftsman:IsCrafting(tCurrentCraft)
	if not tCurrentCraft then
		tCurrentCraft = CraftingLib.GetCurrentCraft()
	end
	return tCurrentCraft and tCurrentCraft.nSchematicId ~= 0
end

-----------------------------------------------------------------------------------------------
-- MasterCraftsmanForm Button events
-----------------------------------------------------------------------------------------------
function MasterCraftsman:OnWindowClosed( wndHandler, wndControl )
	self.arItemList = {}
	self.wndMain:SetData(nil)
	local tCurrentCraft = CraftingLib.GetCurrentCraft()
	if not tCurrentCraft or tCurrentCraft.nSchematicId == 0 or not CraftingLib.GetSchematicInfo(tCurrentCraft.nSchematicId).bIsUniversal then
		Event_CancelMasterCraftsman()
	end
end

function MasterCraftsman:OnCloseBtn()
	self.wndMain:Close()
end

function MasterCraftsman:OnCraftBtn()
	if nil ~= self.wndMain:GetData() then
		CraftingLib.CraftItem( self.wndMain:GetData() )
	end
end

---------------------------------------------------------------------------------------------------
-- SchematicListItem Button events
---------------------------------------------------------------------------------------------------

function MasterCraftsman:OnSchematicListItemGenerateTooltip( wndHandler, wndControl, eToolTipType, x, y )
	if wndHandler ~= wndControl then
		return
	end

	wndControl:SetTooltipDoc(nil)

	local tListItem = wndHandler:GetData().tItem
	local tPrimaryTooltipOpts = {}

	tPrimaryTooltipOpts.bPrimary = true
	tPrimaryTooltipOpts.itemCompare = tListItem:GetEquippedItemForItemType()

	if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
		Tooltip.GetItemTooltipForm(self, wndControl, tListItem, tPrimaryTooltipOpts)
	end
end

function MasterCraftsman:OnSchematicListItemCheck( wndHandler, wndControl, eMouseButton )
	if not wndHandler or not wndHandler:GetData() then
		return
	end
	
	self.nItemIndex = wndHandler:GetData().nIdx
	
	local itemCurr = self.arItemList[self.nItemIndex]
	self.wndMain:SetData(itemCurr)
end

-----------------------------------------------------------------------------------------------
-- MasterCraftsman Instance
-----------------------------------------------------------------------------------------------
local MasterCraftsmanInst = MasterCraftsman:new()
MasterCraftsmanInst:Init()
