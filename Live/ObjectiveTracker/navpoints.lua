require "GameLib"

local knXCursorOffset = 10
local knYCursorOffset = 25

local Navpoints = {}
local NavpointsRegistrarInst = {}

local kstrObjectiveType		 						= Apollo.GetString("Navpoint")
local kstrNavpointsContainer 						= "001NavpointsContainer"

function Navpoints:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
end

function Navpoints:Init()
	Apollo.RegisterAddon(self)
end

function Navpoints:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Navpoints.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Navpoints:OnDocumentReady()
	if not self.xmlDoc or not self.xmlDoc:IsLoaded() then
		return
	end
	
	--ObjectiveTracker
	Event_FireGenericEvent("ObjectiveTracker_RequestParent")
	Apollo.RegisterEventHandler("ObjectiveTrackerLoaded",		"OnObjectiveTrackerLoaded", self)

	--Navpoint
	Apollo.RegisterEventHandler("NavPointCleared",						"OnNavPointCleared", self)
	Apollo.RegisterEventHandler("NavPointSet",								"OnNavPointSet", self)
end

-----------------------------------------------------------------------------------------------
--ObjectiveTracker Events
-----------------------------------------------------------------------------------------------
function Navpoints:OnObjectiveTrackerLoaded(wndForm)
	if self.bLoaded or not wndForm or not wndForm:IsValid() then
		return
	end

	self.bLoaded = true

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "Container", wndForm, self)
	self.wndMain:Show(false)
	self.wndMain:SetData(kstrNavpointsContainer)
	nLeft, nTop, nRight, self.nOriginalBottom = self.wndMain:GetAnchorOffsets()

	local tData = {
		["strAddon"]	= kstrObjectiveType,
		["bChecked"]	= true,
		["strDefaultSort"]	= kstrNavpointsContainer,
		["bNoBtn"] = true,
	}
	Event_FireGenericEvent("ObjectiveTracker_NewAddOn", tData)

	if GameLib.IsNavPointSet() then
		local tPoint = GameLib.GetNavPoint()
		self:OnNavPointSet(tPoint and tPoint.tPosition or nil)
	end
end

function Navpoints:HelperUpdateObjectiveTracker(bExpand)
	local tData = {
		["strAddon"]	= kstrObjectiveType,
		["bChecked"]	= bExpand,
	}
	Event_FireGenericEvent("ObjectiveTracker_UpdateAddOn", tData)
end

-----------------------------------------------------------------------------------------------
--Navpoints Events
-----------------------------------------------------------------------------------------------
function Navpoints:OnNavPointSet(tLoc)
	if not self.wndMain or not self.wndMain:IsValid() or not tLoc then
		return
	end

	local tPoint = GameLib.GetNavPoint()
	if not tPoint then
		return
	end

	self.wndMain:Show(true)
	if not self.wndListItem or not self.wndListItem:IsValid() then
		self.wndListItem = Apollo.LoadForm(self.xmlDoc, "ListItem", self.wndMain:FindChild("Content"), self)
		self:HelperResize(true)
	end

	local strText = String_GetWeaselString(Apollo.GetString("ZoneMap_LocationXZ"), tLoc.x, tLoc.z)
	if tPoint.strZoneName ~= "" then
		strText = string.format("%s (%s)", strText, tPoint.strZoneName)
	end
	
	self.wndListItem:FindChild("ListItemName"):SetText(strText)
	self.wndListItem:FindChild("ListItemBigBtn"):SetData(tLoc)
	self.wndListItem:Show(true)
end

function Navpoints:OnNavPointCleared()
	if not self.wndMain or not self.wndMain:IsValid() or not self.wndListItem or not self.wndListItem:IsValid() then
		return
	end

	self.wndMain:Show(false)
	self.wndListItem:Show(false)
	self.wndListItem:Destroy()
	self.wndListItem = nil
	self:HelperResize(false)
end

-----------------------------------------------------------------------------------------------
--UI Events
-----------------------------------------------------------------------------------------------
function Navpoints:OnListItemClicked(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		self:DrawContextMenu()
	else
		local tLoc  = wndHandler:GetData()
		GameLib.SetInteractHintArrowObject(tLoc)
		GameLib.ShowNavPointHintArrow()
	end
end

function Navpoints:CloseContextMenu()
	if self.wndContextMenu and self.wndContextMenu:IsValid() then
		self.wndContextMenu:Destroy()
		self.wndContextMenu = nil
		
		return true
	end
	
	return false
end

function Navpoints:DrawContextMenu()
	if self:CloseContextMenu() then
		return
	end

	self.wndContextMenu = Apollo.LoadForm(self.xmlDoc, "ContextMenu", nil, self)
	local tCursor = Apollo.GetMouse()
	local nWidth = self.wndContextMenu:GetWidth()
	self.wndContextMenu:Move(tCursor.x - nWidth + knXCursorOffset, tCursor.y - knYCursorOffset, nWidth, self.wndContextMenu:GetHeight())
end

function Navpoints:OnClearNavpointBtn()
	GameLib.ClearNavPoint()
	self:CloseContextMenu()
	self:HelperUpdateObjectiveTracker(false)
end

function Navpoints:OnControlBackerMouseEnter(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:FindChild("MinimizeBtn"):Show(true)
	end
end

function Navpoints:OnControlBackerMouseExit(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:FindChild("MinimizeBtn"):Show(false)
	end
end

function Navpoints:OnMinimizedBtnChecked(wndHandler, wndControl, eMouseButton)
	local bExpand = not wndHandler:IsChecked()
	self.wndMain:FindChild("Content"):Show(bExpand)
	self:HelperResize(bExpand)
end

function Navpoints:HelperResize(bExpand)
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetOriginalLocation():GetOffsets()
	local nContentHeight = 0
	if bExpand then
		nContentHeight = self.wndListItem:GetHeight()
	end
	self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nContentHeight )
	self:HelperUpdateObjectiveTracker(bExpand)
end

local NavpointsInst = Navpoints:new()
NavpointsInst:Init()