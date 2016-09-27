-----------------------------------------------------------------------------------------------
-- Client Lua Script for WelcomeWindow
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "AccountItemLib"
require "GameLib"
 
local WelcomeWindow = {} 
 
function WelcomeWindow:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    o.kstrTitle = Apollo.GetString("WelcomeWindow_Title")

    o.kstrTabLeft	= "BK3:btnMetal_TabMainLeft"
    o.kstrTabMid	= "BK3:btnMetal_TabMainMid"
    o.kstrTabRight	= "BK3:btnMetal_TabMainRight"
    return o
end

function WelcomeWindow:Init()
    Apollo.RegisterAddon(self, false, self.kstrTitle)
end
 
function WelcomeWindow:OnLoad()
	Apollo.RegisterEventHandler("CharacterCreated", 				"OnCharacterCreated", self)

	self.xmlDoc = XmlDoc.CreateFromFile("WelcomeWindow.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function WelcomeWindow:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	--WindowManagement
	Apollo.RegisterEventHandler("WindowManagementReady", 	"OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	--InterfaceMenuList
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 		"OnInterfaceMenuListHasLoaded", self)

	Apollo.RegisterEventHandler("WelcomeWindow_TabContent",			"OnWelcomeWindowTabContent", self)
	Apollo.RegisterEventHandler("WelcomeWindow_RequestParent",		"OnRequestWelcomeWindowParent", self)
	Apollo.RegisterEventHandler("WelcomeWindow_RequestTabChange",	"OnWelcomeWindowRequestTabChange", self)
	Apollo.RegisterEventHandler("WelcomeWindow_EnableTab",			"OnWelcomeWindowEnableTab", self)

	--Open Welcome Window from code
	Apollo.RegisterEventHandler("ToggleWelcomeWindow",				"OnToggle", self)

	--Open Welcome Window from Other Addons
	Apollo.RegisterEventHandler("WelcomeWindow_Open", 	"OnOpen", self)
	Apollo.RegisterEventHandler("WelcomeWindow_Toggle", "OnToggle", self)

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "WelcomeContainer", nil, self)
	self.wndContentContainer = self.wndMain:FindChild("ContentContainer")
	self.wndNavigation = self.wndMain:FindChild("Navigation")

	self.arSortedTabs = {}
	self:OnRequestWelcomeWindowParent()
	self:OnInterfaceMenuListHasLoaded()
end

function WelcomeWindow:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = self.kstrTitle, nSaveVersion = 1})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = self.kstrTitle})
end

function WelcomeWindow:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", self.kstrTitle, { "WelcomeWindow_Toggle", "", "IconSprites:Icon_Windows32_UI_CRB_InterfaceMenu_WelcomeWindow2"})
end

function WelcomeWindow:OnWelcomeWindowTabContent(strContentName, wndContent, nSortOrder)
	if not strContentName or not wndContent then
		return
	end

	local wndTab = Apollo.LoadForm(self.xmlDoc, "TabBtn", self.wndNavigation, self)
	wndTab:AttachWindow(wndContent)
	wndTab:SetText(strContentName)

	local tContent = {}
	tContent.wndContent = wndContent
	tContent.wndTab = wndTab
	tContent.strContentName = strContentName 
	self.arSortedTabs[nSortOrder] = tContent
	wndTab:SetData(tContent)

	local nChildren = 0
	for idx, tTabContent in ipairs(self.arSortedTabs) do
		nChildren = nChildren + 1
	end

	if nChildren > 1 then
		local nTabWidth = 1 / nChildren
		for idx, tTabContent in ipairs(self.arSortedTabs) do
			local wndCurTab = tTabContent.wndTab
			wndCurTab:SetAnchorPoints(nTabWidth * (idx - 1), 0, nTabWidth * idx, 0)

			if idx == 1 then
				wndCurTab:ChangeArt(self.kstrTabLeft)
			elseif idx == nChildren then
				wndCurTab:ChangeArt(self.kstrTabRight)
			else
				wndCurTab:ChangeArt(self.kstrTabMid)
			end
		end

		if self.bRequestOpen then
			self:OnCharacterCreated()
		end
	end
end

function WelcomeWindow:OnRequestWelcomeWindowParent()
	Event_FireGenericEvent("WelcomeWindow_Loaded", self.wndContentContainer)
end

function WelcomeWindow:OnWelcomeWindowRequestTabChange(strContentName)
	if not strContentName then
		return
	end

	for idx, tContent in pairs(self.arSortedTabs) do
		if tContent.strContentName == strContentName then
			self:SetTab(tContent.wndTab)
			break
		end
	end
end

function WelcomeWindow:OnWelcomeWindowEnableTab(strContentName, bEnable, strTooltip)
	if not strContentName then
		return
	end

	for idx, tContent in pairs(self.arSortedTabs) do
		if tContent.strContentName == strContentName then
			tContent.wndTab:Enable(bEnable)
			tContent.wndTab:SetTooltip(strTooltip)
			break
		end
	end
end

function WelcomeWindow:HelperIsPlayerInTuroialZone()
	local tZone = GameLib.GetCurrentZoneMap()
	if tZone == nil then
		return false
	end
	return GameLib.IsTutorialZone(tZone.id)
end

function WelcomeWindow:OnCharacterCreated()
	if not self.wndMain then
		self.bRequestOpen = true
		return
	end

	if self.wndMain:IsShown() or self:HelperIsPlayerInTuroialZone() then
		return
	end

	self:OnOpen()
end

function WelcomeWindow:OnToggle()
	if self.wndMain and self.wndMain:IsShown() then
		self:OnCancel()
		return
	end

	self:OnOpen()
end

function WelcomeWindow:OnOpen()
	local tContent = self.arSortedTabs[1]
	if not tContent then
		return
	end

	if tContent.wndTab then
		self:SetTab(tContent.wndTab)
		self.wndMain:Invoke()
		self.bRequestOpen = false
	end
end

function WelcomeWindow:SetTab(wndTab)
	self.wndNavigation:SetRadioSelButton("WelcomeWindowNav", wndTab)
	self:OnTabBtn(wndTab, wndTab)
end

function WelcomeWindow:OnTabBtn(wndHandler, wndControl)
	local tContent = wndControl:GetData()
	if not tContent then
		return
	end

	Event_FireGenericEvent("WelcomeWindow_TabSelected", tContent.strContentName)
end

function WelcomeWindow:OnCancel()
	Event_FireGenericEvent("WelcomeWindow_Closed")
	self.wndMain:Close() 
end

-----------------------------------------------------------------------------------------------
-- WelcomeWindow Instance
-----------------------------------------------------------------------------------------------
local WelcomeWindowInst = WelcomeWindow:new()
WelcomeWindowInst:Init()