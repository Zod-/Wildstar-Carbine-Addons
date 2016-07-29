-----------------------------------------------------------------------------------------------
-- Client Lua Script for AdventureWhitevale
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- AdventureWhitevale Module Definition
-----------------------------------------------------------------------------------------------
local AdventureWhitevale = {} 

local knSaveVersion = 2

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function AdventureWhitevale:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    o.tWndRefs = {}
	o.tSons = {}
	o.tRollers = {}
	o.tGrinders = {}
	o.tAdventureInfo = {}

    return o
end

function AdventureWhitevale:Init()
    Apollo.RegisterAddon(self)
end

function AdventureWhitevale:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	
	local tSaveData = self.tAdventureInfo
	tSaveData.nSaveVersion = knSaveVersion
		
	return tSaveData
end

function AdventureWhitevale:OnRestore(eType, tSavedData)
	if not tSavedData or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end
	
	local bIsWhitevaleAdventure = false
	local tActiveEvents = PublicEvent.GetActiveEvents()

	for idx, peEvent in pairs(tActiveEvents) do
		if peEvent:GetEventType() == PublicEvent.PublicEventType_Adventure_Whitevale then
			bIsWhitevaleAdventure = true
		end
	end
	
	self.tAdventureInfo = {}
	
	if bIsWhitevaleAdventure then
		self.bShow = tSavedData.bIsShown
		self.tAdventureInfo.nRep = tSavedData.nRep or 0
		self.tAdventureInfo.nSons = tSavedData.nSons or 0
		self.tAdventureInfo.nRollers = tSavedData.nRollers or 0
		self.tAdventureInfo.nGrinders = tSavedData.nGrinders or 0
	end
end 

-----------------------------------------------------------------------------------------------
-- AdventureWhitevale OnLoad
-----------------------------------------------------------------------------------------------
function AdventureWhitevale:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("WhitevaleAdventure.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function AdventureWhitevale:OnDocumentReady()
    Apollo.RegisterEventHandler("WindowManagementReady", 	"OnWindowManagementReady", self)
	self:OnWindowManagementReady()
	
    Apollo.RegisterEventHandler("WhitevaleAdvResource", "OnUpdateResource", self)
	Apollo.RegisterEventHandler("WhitevaleAdvShow", "OnShow", self)
	Apollo.RegisterEventHandler("ChangeWorld", "OnHide", self)
end

function AdventureWhitevale:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("CRB_AdventureWhitevale"), nSaveVersion=3})
end

function AdventureWhitevale:Initialize()
	if self.tWndRefs.wnd ~= nil and self.tWndRefs.wnd:IsValid() then
		return
	end

	self.tWndRefs.wnd = Apollo.LoadForm(self.xmlDoc, "WhitevaleAdventureForm", nil, self)
	self.tWndRefs.wndMain = self.tWndRefs.wnd:FindChild("Main")
	self.tWndRefs.wndRepBar = self.tWndRefs.wndMain:FindChild("Rep")
	self.tWndRefs.wndSonsLoyalty = self.tWndRefs.wndMain:FindChild("SonsLoyalty")
	self.tWndRefs.wndRollersLoyalty = self.tWndRefs.wndMain:FindChild("RollersLoyalty")
	self.tWndRefs.wndGrindersLoyalty = self.tWndRefs.wndMain:FindChild("GrindersLoyalty")
	
	self.tWndRefs.wndSonsLoyalty:FindChild("TitleSons"):SetText(Apollo.GetString("WhitevaleAdv_SonsOfRavok"))
	self.tWndRefs.wndRollersLoyalty:FindChild("TitleRollers"):SetText(Apollo.GetString("WhitevaleAdv_RocktownRollers"))
	self.tWndRefs.wndGrindersLoyalty:FindChild("TitleGrinders"):SetText(Apollo.GetString("WhitevaleAdv_Geargrinders"))
	self.tWndRefs.wndSonsLoyalty:Show(false)
	self.tWndRefs.wndRollersLoyalty:Show(false)
	self.tWndRefs.wndGrindersLoyalty:Show(false)
	
	for i = 1, 3 do 
		self.tSons[i] = self.tWndRefs.wndSonsLoyalty:FindChild("Sons" .. i)
		self.tRollers[i] = self.tWndRefs.wndRollersLoyalty:FindChild("Rollers" .. i)
		self.tGrinders[i] = self.tWndRefs.wndGrindersLoyalty:FindChild("Grinders" .. i)
	end
	
	self.tWndRefs.wndRepBar:SetMax(100)
	self.tWndRefs.wndRepBar:SetFloor(0)
	self.tWndRefs.wndRepBar:SetProgress(0)
	self.tWndRefs.wndRepBar:Show(false)
	--self.tWndRefs.wndRepBar:SetText(Apollo.GetString("WhitevaleAdv_Notoriety"))
    self.tWndRefs.wnd:Invoke()
    
	if not self.tAdventureInfo then 
		self.tAdventureInfo = {}
	elseif self.bShow then 
		self:OnUpdateResource(self.tAdventureInfo.nRep, self.tAdventureInfo.nSons, self.tAdventureInfo.nRollers, self.tAdventureInfo.nGrinders )
	end
	
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wnd, strName = Apollo.GetString("CRB_AdventureWhitevale"), nSaveVersion=3})
end

-----------------------------------------------------------------------------------------------
-- AdventureWhitevale Functions
-----------------------------------------------------------------------------------------------

function AdventureWhitevale:OnUpdateResource(iRep, iSons, iRollers, iGrinders)
	self:Initialize()
	self.tWndRefs.wndRepBar:Show(true)
	self.tWndRefs.wndRepBar:SetProgress(iRep)
	
	self.tAdventureInfo.bIsShown = true
	
	self.tWndRefs.wndSonsLoyalty:Show(true)
	self.tWndRefs.wndRollersLoyalty:Show(true)
	self.tWndRefs.wndGrindersLoyalty:Show(true)
	self:HideAll()
	
	if iSons > 0 then
		for i = 1, iSons do
			self.tSons[i]:Show(true)
		end
	end
	
	if iRollers > 0 then
		for i = 1, iRollers do
			self.tRollers[i]:Show(true)
		end
	end
	
	if iGrinders > 0 then
		for i = 1, iGrinders do
			self.tGrinders[i]:Show(true)
		end
	end
	
	self.tAdventureInfo.nRep = iRep
	self.tAdventureInfo.nSons = iSons
	self.tAdventureInfo.nRollers = iRollers
	self.tAdventureInfo.nGrinders = iGrinders
end


function AdventureWhitevale:HideAll()
	for i = 1, 3 do
		self.tSons[i]:Show(false)
		self.tRollers[i]:Show(false)
		self.tGrinders[i]:Show(false)
	end
	
	self.tAdventureInfo.nSons = 0
	self.tAdventureInfo.nRollers = 0
	self.tAdventureInfo.nGrinders = 0
end

function AdventureWhitevale:OnShow(bShow)
	if bShow == true then
		self:Initialize()
	elseif bShow == false then
		self:OnHide()
	end
end

function AdventureWhitevale:OnHide()
	if self.tWndRefs.wnd ~= nil and self.tWndRefs.wnd:IsValid() then
		self.tWndRefs.wnd:Close()
	end
	self.tAdventureInfo.bIsShown = false
end
-----------------------------------------------------------------------------------------------
-- WhitevaleAdventureForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function AdventureWhitevale:OnOK()
	self:OnHide()
end

-- when the Cancel button is clicked
function AdventureWhitevale:OnCancel()
	self:OnHide()
end

function AdventureWhitevale:OnWindowClosed(wndHandler, wndControl)
	if self.tWndRefs.wnd ~= nil and self.tWndRefs.wnd:IsValid() then
		self.tWndRefs.wnd:Close()
		self.tWndRefs.wnd:Destroy()
		self.tWndRefs = {}
		
		self.tSons = {}
		self.tRollers = {}
		self.tGrinders = {}
		
		Event_FireGenericEvent("WindowManagementRemove", {strName = Apollo.GetString("CRB_AdventureWhitevale"), nSaveVersion=3})
	end
end

-----------------------------------------------------------------------------------------------
-- AdventureWhitevale Instance
-----------------------------------------------------------------------------------------------
local AdventureWhitevaleInst = AdventureWhitevale:new()
AdventureWhitevaleInst:Init()
