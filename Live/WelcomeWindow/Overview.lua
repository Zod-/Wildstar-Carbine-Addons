-----------------------------------------------------------------------------------------------
-- Client Lua Script for WelcomeWindow/Overview
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
local Overview = {} 
 
function Overview:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.kstrTitle = Apollo.GetString("Overview_Title")
	o.knSortOrder = 1
    return o
end

function Overview:Init()
    Apollo.RegisterAddon(self, false, self.kstrTitle)
end
 
function Overview:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Overview.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Overview:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	--WelcomeWindow Events
	Apollo.RegisterEventHandler("WelcomeWindow_Loaded", 		"OnWelcomeWindowLoaded", self)
	Apollo.RegisterEventHandler("WelcomeWindow_TabSelected",	"OnWelcomeWindowTabSelected", self)
	Apollo.RegisterEventHandler("WelcomeWindow_Closed",			"OnClose", self)

	Event_FireGenericEvent("WelcomeWindow_RequestParent")
end

function Overview:OnWelcomeWindowLoaded(wndParent)
	if not wndParent or not wndParent:IsValid() then
		return
	end

	Apollo.RemoveEventHandler("WelcomeWindow_Loaded", self)

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "Overview", wndParent, self)
	Event_FireGenericEvent("WelcomeWindow_TabContent", self.kstrTitle, self.wndMain, self.knSortOrder)

	Apollo.RegisterEventHandler("OverView_RequestParent", 	"OnOverViewRequestParent", self)
	self:OnOverViewRequestParent()
end

function Overview:OnOverViewRequestParent()
	--Sends a reference to the title string, so that other windows can tell when the Overview Window is shown.
	Event_FireGenericEvent("OverView_Loaded", self.kstrTitle, self.wndMain)
end

function Overview:OnWelcomeWindowTabSelected(strSelectedTab)

end


function Overview:OnClose()
	self.wndMain:Close() 
end


-----------------------------------------------------------------------------------------------
-- Overview Instance
-----------------------------------------------------------------------------------------------
local OverviewInst = Overview:new()
OverviewInst:Init()
