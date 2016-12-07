-----------------------------------------------------------------------------------------------
-- Client Lua Script for HousingList
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "HousingLib"
require "Residence"
require "Decor"
 
-----------------------------------------------------------------------------------------------
-- HousingList Module Definition
-----------------------------------------------------------------------------------------------
local HousingList = {} 

-----------------------------------------------------------------------------------------------
-- global
-----------------------------------------------------------------------------------------------
local gidZone = 0
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function HousingList:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.tWndRefs			= {}
	o.wndCrateUnderPopup = nil
	o.wndDecorList 		= nil
	o.wndListView 		= nil
	o.wndRecallButton 	= nil
	o.wndDeleteButton 	= nil
	o.tCategoryItems 	= {}

    return o
end

function HousingList:Init()
    Apollo.RegisterAddon(self)
end
 

-----------------------------------------------------------------------------------------------
-- HousingList OnLoad
-----------------------------------------------------------------------------------------------
function HousingList:OnLoad()
	Apollo.RegisterEventHandler("WindowManagementReady", 	"OnWindowManagementReady", self)
	self:OnWindowManagementReady()
	
	Apollo.RegisterEventHandler("HousingButtonList", 				"OnHousingButtonList", self)
	Apollo.RegisterEventHandler("HousingButtonRemodel", 			"OnHousingButtonRemodel", self)
	Apollo.RegisterEventHandler("HousingButtonLandscape", 			"OnHousingButtonLandscape", self)
	Apollo.RegisterEventHandler("HousingButtonCrate", 				"OnHousingButtonCrate", self)
	Apollo.RegisterEventHandler("HousingButtonVendor", 				"OnHousingButtonCrate", self)
	Apollo.RegisterEventHandler("HousingPanelControlOpen", 			"OnOpenPanelControl", self)
	Apollo.RegisterEventHandler("HousingPanelControlClose", 		"OnClosePanelControl", self)
	Apollo.RegisterEventHandler("HousingMyResidenceDecorChanged", 	"OnMyResidenceDecorChanged", self)
	Apollo.RegisterEventHandler("HousingFreePlaceControlClose", 	"OnCloseFreePlaceControl", self)
	Apollo.RegisterEventHandler("HousingDestroyDecorControlOpen", 	"OnOpenDestroyDecorControl", self)
	Apollo.RegisterEventHandler("HousingExitEditMode", 				"OnExitEditMode", self)
	Apollo.RegisterEventHandler("HousingBuildStarted", 				"OnBuildStarted", self)
    
    self.xmlDoc = XmlDoc.CreateFromFile("HousingList.xml")
	
	HousingLib.RefreshUI()
end

function HousingList:OnWindowManagementReady()
	local strName = String_GetWeaselString(Apollo.GetString("Tooltips_ItemSpellEffect"), Apollo.GetString("CRB_Housing"), Apollo.GetString("HousingList_Header"))

	Event_FireGenericEvent("WindowManagementRegister", {strName = strName})
end

-----------------------------------------------------------------------------------------------
-- HousingList Functions
-----------------------------------------------------------------------------------------------

function HousingList:BuildList()
	local wndDecorList				= Apollo.LoadForm(self.xmlDoc, "HousingListWindow", nil, self)
    self.tWndRefs.wndDecorList		= wndDecorList
	self.tWndRefs.wndListView		= wndDecorList:FindChild("StructureList")
	self.tWndRefs.wndRecallButton	= wndDecorList:FindChild("RecallBtn")
	self.tWndRefs.wndDeleteButton	= wndDecorList:FindChild("DeleteBtn")
	
	self.tWndRefs.wndRecallButton:Enable(false)
	self.tWndRefs.wndDeleteButton:Enable(false)
	
	local strName = string.format("%s: %s", Apollo.GetString("CRB_Housing"), Apollo.GetString("HousingList_Header"))
	Event_FireGenericEvent("WindowManagementAdd", {wnd = wndDecorList, strName = strName})
end

function HousingList:OnHousingButtonList()
    if self.tWndRefs.wndDecorList == nil or not self.tWndRefs.wndDecorList:IsValid() then
		self:BuildList()
        self.tWndRefs.wndDecorList:Invoke()
        self:ShowHousingListWindow()
        
		Event_FireGenericEvent("HousingEnterEditMode")
		HousingLib.SetEditMode(true)		
	else
	    self:OnCloseHousingListWindow()
	end
end	

---------------------------------------------------------------------------------------------------
function HousingList:OnHousingButtonCrate()
	if (self.tWndRefs.wndDecorList ~= nil and self.tWndRefs.wndDecorList:IsVisible()) or (self.wndCrateUnderPopup ~= nil and self.wndCrateUnderPopup:IsVisible()) then
		self:OnCloseHousingListWindow()
	end
end	

---------------------------------------------------------------------------------------------------
function HousingList:OnHousingButtonRemodel()
	if (self.tWndRefs.wndDecorList ~= nil and self.tWndRefs.wndDecorList:IsVisible()) or (self.wndCrateUnderPopup ~= nil and self.wndCrateUnderPopup:IsVisible()) then
		self:OnCloseHousingListWindow()
	end
end	

---------------------------------------------------------------------------------------------------
function HousingList:OnHousingButtonLandscape()
	if (self.tWndRefs.wndDecorList ~= nil and self.tWndRefs.wndDecorList:IsVisible()) or (self.wndCrateUnderPopup ~= nil and self.wndCrateUnderPopup:IsVisible()) then
		self:OnCloseHousingListWindow()
	end
end	

---------------------------------------------------------------------------------------------------
function HousingList:OnExitEditMode()
	if self.tWndRefs.wndDecorList ~= nil and self.tWndRefs.wndDecorList:IsVisible() then
		self:OnCloseHousingListWindow()
	end
end

---------------------------------------------------------------------------------------------------
function HousingList:OnBuildStarted(plotIndex)
	if plotIndex == 1 and self.tWndRefs.wndDecorList ~= nil and self.tWndRefs.wndDecorList:IsVisible() then
		self:OnCloseHousingListWindow()
	end
end

---------------------------------------------------------------------------------------------------
function HousingList:OnOpenPanelControl(idPropertyInfo, idZone, bPlayerIsInside)
	if self.bPlayerIsInside ~= bPlayerIsInside and HousingLib.IsHousingWorld() then
		self:OnCloseHousingListWindow()
	end	

	gidZone = idZone
	self.idPropertyInfo = idPropertyInfo
	self.bPlayerIsInside = bPlayerIsInside == true --make sure we get true/false
	self.bIsWarplot = HousingLib.GetResidence() and HousingLib.GetResidence():IsWarplotResidence()
end

---------------------------------------------------------------------------------------------------
function HousingList:ResetPopups()
    if self.wndCrateUnderPopup ~= nil then
	    self.wndCrateUnderPopup:Destroy()
	    self.wndCrateUnderPopup = nil
	end    
end

---------------------------------------------------------------------------------------------------
function HousingList:OnConfirmCrateAll(wndControl, wndHandler)
    Sound.Play(Sound.PlayUIHousingCrateItem)
	HousingLib.CrateAllDecor()
    self:CancelPreviewDecor(true)
    Event_FireGenericEvent("HousingDeactivateDecorIcon", self.decorSelection)
    Event_FireGenericEvent("HousingFreePlaceControlClose", self.decorSelection)

	self:BuildList()
    self.tWndRefs.wndDecorList:Invoke()
    self:ResetPopups()
end

---------------------------------------------------------------------------------------------------
function HousingList:OnCancelCrateAll(wndControl, wndHandler)
	self:BuildList()
    self.tWndRefs.wndDecorList:Invoke()
    self:ResetPopups()
end

---------------------------------------------------------------------------------------------------
function HousingList:OnDecoratePreview(wndControl, wndHandler)
	local nRow = self.tWndRefs.wndListView:GetCurrentRow() 
	local decorPreview = self.tWndRefs.wndListView:GetCellData(nRow, 1)
	
	-- remove any existing preview decor
	if self.decorSelection ~= nil then
	    self.decorSelection:CancelTransform()
	end

	self:CancelPreviewDecor(false)
	
	if decorPreview ~= nil then
		decorPreview:Select()
	    if not self.bIsWarplot then
	        Event_FireGenericEvent("HousingActivateDecorIcon", decorPreview)
	    end
		Sound.Play(Sound.PlayUIHousingHardwareAddition)
		self.decorSelection = decorPreview
		self.tWndRefs.wndRecallButton:Enable(true)
		self.tWndRefs.wndDeleteButton:Enable(HousingLib:IsOnMyResidence())
	end
end

---------------------------------------------------------------------------------------------------
function HousingList:CancelPreviewDecor(bRemoveFromWorld)
	if bRemoveFromWorld and self.decorSelection ~= nil then
		self.decorSelection:CancelTransform()
	end
	
	self.decorSelection = nil
	
	if self.tWndRefs.wndRecallButton ~= nil then
		self.tWndRefs.wndRecallButton:Enable(false)
	end
	
	if self.tWndRefs.wndDeleteButton ~= nil then
		self.tWndRefs.wndDeleteButton:Enable(false)
	end
end

---------------------------------------------------------------------------------------------------
function HousingList:OnRecallBtn(wndControl, wndHandler)
    if self.decorSelection ~= nil then
        self.decorSelection:Crate()
        self:CancelPreviewDecor(true)
        Event_FireGenericEvent("HousingDeactivateDecorIcon", self.decorSelection)
        Event_FireGenericEvent("HousingFreePlaceControlClose", self.decorSelection)
        self:ShowHousingListWindow()
	end
end

---------------------------------------------------------------------------------------------------
function HousingList:OnRecallAllBtn(wndControl, wndHandler)
    self:ResetPopups()
    self.wndCrateUnderPopup = Apollo.LoadForm(self.xmlDoc, "PopupCrateUnder", nil, self)
    self.wndCrateUnderPopup:Invoke()
    self.tWndRefs.wndDecorList:Close()
end

---------------------------------------------------------------------------------------------------
function HousingList:OnPlaceBtn(wndControl, wndHandler)

	if self.decorSelection ~= nil then
		self.decorSelection:Place()
	Sound.Play(Sound.PlayUIHousingHardwareFinalized)
	Sound.Play(Sound.PlayUI16BuyVirtual)
	end
	self:CancelPreviewDecor(false)
end

---------------------------------------------------------------------------------------------------
function HousingList:OnDeleteBtn(wndControl, wndHandler)
	if self.decorSelection ~= nil then
	    Event_FireGenericEvent("HousingDestroyDecorControlOpen2", self.decorSelection, false)
	end
end

---------------------------------------------------------------------------------------------------
function HousingList:OnWindowClosed()
	-- called after the window is closed by:
	--	self.winMasterCustomizeFrame:Close() or 
	--  hitting ESC or
	--  C++ calling Event_CloseHousingListWindow()
	
	-- any preview decorItems reset
	self:CancelPreviewDecor(false)
	self.arDecorList = nil
	
	if self.tWndRefs.wndDecorList ~= nil and self.tWndRefs.wndDecorList:IsValid() then
		self.tWndRefs.wndDecorList:Destroy()
		self.tWndRefs = {}
		Sound.Play(Sound.PlayUIWindowClose)
	end
end

---------------------------------------------------------------------------------------------------
function HousingList:OnCloseHousingListWindow()
	-- close the window which will trigger OnWindowClosed
	if self.tWndRefs.wndDecorList ~= nil and self.tWndRefs.wndDecorList:IsValid() then
	self:ResetPopups()
		self.tWndRefs.wndDecorList:Destroy()
	end
end

---------------------------------------------------------------------------------------------------
function HousingList:ShowHousingListWindow()
    -- don't do any of this if the Housing List isn't visible
	if self.tWndRefs.wndDecorList == nil or not self.tWndRefs.wndDecorList:IsVisible() then
		return
	end
	
    -- Find a list of all placed decor items
    self.arDecorList = HousingLib.GetResidence() and HousingLib.GetResidence():GetPlacedDecorList() or {}
    self:ShowItems(self.tWndRefs.wndListView, self.arDecorList, 0)
	
	-- remove any existing preview decor
	self:CancelPreviewDecor(false)
end
	
---------------------------------------------------------------------------------------------------
function HousingList:CrateDecorItem(decorSelected)
	if decorSelected ~= nil then
		Sound.Play(Sound.PlayUIHousingCrateItem)
		decorSelected:Crate()
	end
end

---------------------------------------------------------------------------------------------------
function HousingList:OnMyResidenceDecorChanged(eDecorType)
	if self.tWndRefs.wndDecorList == nil or not self.tWndRefs.wndDecorList:IsVisible() then
		return
	end
	
	-- we don't need to do anything on decorations (and since they are numerous messages, bail!)
	if eDecorType == kDecorType_HookDecor then
		return
	end

	-- refresh the UI
	self:ShowHousingListWindow()

	-- remove any existing preview decor
	self:CancelPreviewDecor(false)
 end
 

---------------------------------------------------------------------------------------------------
-- DecorateItemList Functions
---------------------------------------------------------------------------------------------------
function HousingList:OnDecorateListItemChange(wndControl, wndHandler, nX, nY)
	-- Preview the selected item
	local nRow = wndControl:GetCurrentRow()
	if nRow ~= nil then
		self:OnDecoratePreview(wndControl, wndHandler)
	end
end

---------------------------------------------------------------------------------------------------
function HousingList:ShowItems(wndListControl, arDecorList, idPrune)
	if wndListControl ~= nil then
		wndListControl:DeleteAll()
	end

	if arDecorList ~= nil then

	    -- Here we have an example of a nameless function being declared within another function's parameter list!
		table.sort(arDecorList, function(a,b)	return (a:GetName() < b:GetName())	end)

		-- populate the buttons with the item data
		for idx = 1, #arDecorList do
	
			local decor = arDecorList[idx]
			--if self:SelectionMatches(item["type"]) then
			
				-- AddRow implicitly works on column one.  Every column can have it's own hidden data associated with it!
				local strName = decor:GetName()
				if decor:GetDecorColor() ~= 0 then
					local nColorShift = decor:GetDecorColor()
					local tColorInfo = HousingLib.GetDecorColorInfo(nColorShift)
					strName = String_GetWeaselString(Apollo.GetString("HousingDecorList_NameWithColor"), strName, tColorInfo.strName)
				end
				
				local idx = wndListControl:AddRow("  " .. strName, "", decor)
				local bPruned = false

				-- this pruneId means we've want to disallow this item (let's show it as a disabled row) 
				if idPrune == decor:GetDecorInfoId() --[[or gidZone ~= item["zoneId"]--]] then
					--Print("pruneId: " .. pruneId)
					bPruned = true
					wndListControl:EnableRow(idx, false)
				end
				
				--listControl:SetCellData(i, 2, item["zoneId"], "", item["zoneId"])
				
			--end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- HousingList Instance
-----------------------------------------------------------------------------------------------
local HousingListInst = HousingList:new()
HousingListInst:Init()
