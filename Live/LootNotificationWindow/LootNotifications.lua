-----------------------------------------------------------------------------------------------
-- Client Lua Script for LootNotifications
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Sound"
require "GameLib"

local LootNotifications = {}

local knMaxEntryData = 3
local kfMaxItemTime = 7	-- item display time (seconds)
local kfTimeBetweenItems = 0.5 -- delay between items being added to window
local knType_Item = 1

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

function LootNotifications:new(o)
	Print("test")
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	o.arEntries = {}
	o.tEntryData = {}
	o.tQueuedEntryData = {}
	o.fLastTimeAdded = 0
    return o
end

function LootNotifications:Init()
    Apollo.RegisterAddon(self)
end

function LootNotifications:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("LootNotifications.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function LootNotifications:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("ChannelUpdate_Loot",	"OnChannelUpdate_Loot", self)
	
	self.timerUpdate = ApolloTimer.Create(0.1, true, "OnLootNotificationsUpdate", self)

	self.wndLootNotifications = Apollo.LoadForm(self.xmlDoc, "LootNotificationsForm", "FixedHudStratumHigh", self)

	self:UpdateDisplay()

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()
end

function LootNotifications:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {wnd = self.wndLootNotifications, strName = Apollo.GetString("UI_GroupLootNotifications"), nSaveVersion=1})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndLootNotifications, strName = Apollo.GetString("UI_GroupLootNotifications"), nSaveVersion=1})
end

function LootNotifications:OnGenerateTooltip(wndHandler, wndControl)
	if not wndControl or not wndControl:IsValid() or not wndControl:GetData() then
		return
	end
	
	if wndControl ~= wndHandler then
		return
	end
	
	local itemCurr = wndHandler:GetData()
	
	if itemCurr ~= nil then
		Tooltip.GetItemTooltipForm(self, wndControl, itemCurr, {bPrimary = true, bSelling = false, itemCompare = itemCurr:GetEquippedItemForItemType()})
	end
end

function LootNotifications:OnMouseEnter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self.bPause = true
	self.timerUpdate:Stop()
end

function LootNotifications:OnMouseExit(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.bPause = false
	self.timerUpdate:Start()
end

-----------------------------------------------------------------------------------------------
-- Channel Update
-----------------------------------------------------------------------------------------------

function LootNotifications:OnChannelUpdate_Loot(eType, tEventArgs)
	if eType == GameLib.ChannelUpdateLootType.Item and tEventArgs.itemNew then
		if not tEventArgs.unitLooter then
			return
		end
		
		local tNewEntry =
		{
			strLooter = tEventArgs.unitLooter:GetName(),
			eType = knType_Item,
			itemInstance = tEventArgs.itemNew,
			nCount = tEventArgs.nCount,
			money = nil,
			fTimeAdded = GameLib.GetGameTime()
		}
		table.insert(self.tQueuedEntryData, tNewEntry)
		
		if not self.bPause then
			self.timerUpdate:Start()
		end
		
	end
end

-----------------------------------------------------------------------------------------------
-- ITEM FUNCTIONS
-----------------------------------------------------------------------------------------------

function LootNotifications:OnLootNotificationsUpdate(strVar, nValue)
	if self.wndLootNotifications == nil then
		return
	end
	
	local fCurrTime = GameLib.GetGameTime()

	-- remove any old items
	for idx, tEntryData in ipairs(self.tEntryData) do
		if fCurrTime - tEntryData.fTimeAdded >= kfMaxItemTime then
			self:RemoveItem(idx)
		end
	end

	-- add a new item if its time
	if #self.tQueuedEntryData > 0 and #self.tEntryData < knMaxEntryData then
		if fCurrTime - self.fLastTimeAdded >= kfTimeBetweenItems then
			self:AddQueuedItem()
		end
	end

	-- update all the items
	self:UpdateDisplay()
	
	if #self.tEntryData == 0 and #self.tQueuedEntryData == 0 then
		self.timerUpdate:Stop()
	end
end

function LootNotifications:AddQueuedItem()
	-- gather our entryData we need
	local tQueuedData = self.tQueuedEntryData[1]
	table.remove(self.tQueuedEntryData, 1)
	if tQueuedData == nil then
		return
	end

	if tQueuedData.eType == knType_Item and tQueuedData.nCount == 0 then
		return
	end

	-- ensure there's room
	while #self.tEntryData >= knMaxEntryData do
		if not self:RemoveItem(1) then
			break
		end
	end

	-- push this item on the end of the table
	local fCurrTime = GameLib.GetGameTime()
	local nBtnIdx = #self.tEntryData + 1
	self.tEntryData[nBtnIdx] = tQueuedData
	self.tEntryData[nBtnIdx].fTimeAdded = fCurrTime -- adds a delay for vaccuum looting by switching logged to "shown" time

	self.fLastTimeAdded = fCurrTime
end

function LootNotifications:RemoveItem(idx)
	-- validate our inputs
	if idx < 1 or idx > #self.tEntryData then
		return false
	end

	table.remove(self.tEntryData, idx)
	return true
end

function LootNotifications:UpdateDisplay()
	local wndEntryList = self.wndLootNotifications:FindChild("LootEntries")
	-- iterate over our entry data updating all the buttons
	for idx, tCurrentEntry in ipairs(self.tEntryData) do
		local wndEntry = self.arEntries[idx]
		if not wndEntry then
			wndEntry = Apollo.LoadForm(self.xmlDoc, "LootEntry", wndEntryList)
			self.arEntries[idx] = wndEntry
		end
		
		if tCurrentEntry and tCurrentEntry.itemInstance and wndEntry ~= tCurrentEntry.wndEntry then
			local eItemQuality = tCurrentEntry.itemInstance and tCurrentEntry.itemInstance:GetItemQuality() or 1
			local strLooter = String_GetWeaselString(Apollo.GetString("UI_LootNotification_Received"), string.format("<T TextColor=\"UI_TextHoloTitle\" Font=\"CRB_InterfaceSmall\">%s</T>", tCurrentEntry.strLooter))
			wndEntry:SetData(tCurrentEntry.itemInstance)
			wndEntry:SetTooltipDoc(nil)
			wndEntry:FindChild("ItemText"):SetTextColor(karEvalColors[eItemQuality])
			wndEntry:FindChild("LootIcon"):GetWindowSubclass():SetItem(tCurrentEntry.itemInstance)
			wndEntry:FindChild("ItemText"):SetText(tCurrentEntry.itemInstance:GetName())
			wndEntry:FindChild("LooterText"):SetAML(string.format("<T TextColor=\"xkcdBlueyGreen\" Font=\"CRB_InterfaceSmall\">%s</T>", strLooter))
			tCurrentEntry.wndEntry = wndEntry
			wndEntry:Show(true)
		end
	end
	
	for nIdx = #self.tEntryData+1, #self.arEntries do
		self.arEntries[nIdx]:Show(false)
	end
	
	wndEntryList:ArrangeChildrenVert()
	self.wndLootNotifications:Show(#self.tEntryData > 0)
end

local LootNotificationsInst = LootNotifications:new()
LootNotificationsInst:Init()
