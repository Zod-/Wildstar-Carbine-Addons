-----------------------------------------------------------------------------------------------
-- Client Lua Script for PlugPreview
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "HousingLib"
 
-----------------------------------------------------------------------------------------------
-- PlugPreview Module Definition
-----------------------------------------------------------------------------------------------
local PlugPreview = {} 
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PlugPreview:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.tWndRefs = {}
	o.plugItem = nil
	o.numScreenshots = 0
	o.currScreen = 0
	
    return o
end

function PlugPreview:Init()
    Apollo.RegisterAddon(self)
end
 

-----------------------------------------------------------------------------------------------
-- PlugPreview OnLoad
-----------------------------------------------------------------------------------------------
function PlugPreview:OnLoad()
    -- Register events
	Apollo.RegisterEventHandler("PlugPreviewOpen", "OnOpenPreviewPlug", self)
	Apollo.RegisterEventHandler("PlugPreviewClose", "OnClosePlugPreviewWindow", self)
end

-----------------------------------------------------------------------------------------------
-- PlugPreview Functions
-----------------------------------------------------------------------------------------------

function PlugPreview:OnOpenPreviewPlug(plugItemId)
	if self.tWndRefs.winPlugPreview == nil or not self.tWndRefs.winPlugPreview:IsValid() then
		local winPlugPreview = Apollo.LoadForm("PlugPreview.xml", "PlugPreviewWindow", nil, self)
	    self.tWndRefs.winPlugPreview = winPlugPreview
	    self.tWndRefs.winScreen = winPlugPreview:FindChild("Screenshot01")
	    self.tWndRefs.btnPrevious = winPlugPreview:FindChild("PreviousButton")
	    self.tWndRefs.btnNext = winPlugPreview:FindChild("NextButton")
	end

    local itemList = HousingLib.GetPlugItem(plugItemId)
    local ix, item
    for ix = 1, #itemList do
        item = itemList[ix]
        if item["id"] == plugItemId then
          self.plugItem = item
        end
    end

    self:ShowPlugPreviewWindow()
    self.tWndRefs.winPlugPreview:Invoke()
end

---------------------------------------------------------------------------------------------------
function PlugPreview:ShowPlugPreviewWindow()
    -- don't do any of this if the Housing List isn't visible
	if self.tWndRefs.winPlugPreview:IsVisible() then
		self.numScreenshots = #self.plugItem["screenshots"]
	    self.currScreen = 1

        if self.numScreenshots > 1 then
            self.tWndRefs.btnPrevious:Enable(true)
            self.tWndRefs.btnNext:Enable(true)
        else
            self.tWndRefs.btnPrevious:Enable(false)
            self.tWndRefs.btnNext:Enable(false)
        end
	    
	    self:DrawScreenshot()
		return
	end
	
end

---------------------------------------------------------------------------------------------------
function PlugPreview:OnWindowClosed()
	-- called after the window is closed by:
	--	self.winMasterCustomizeFrame:Close() or 
	--  hitting ESC or
	--  C++ calling Event_ClosePlugPreviewWindow()
	
	if self.tWndRefs.winPlugPreview ~= nil and self.tWndRefs.winPlugPreview:IsValid() then
		self.tWndRefs.winPlugPreview:Destroy()
		self.tWndRefs = {}
		Sound.Play(Sound.PlayUIWindowClose)
	end
end

---------------------------------------------------------------------------------------------------
function PlugPreview:OnClosePlugPreviewWindow()
	-- close the window which will trigger OnWindowClosed
	self.tWndRefs.winPlugPreview:Close()
end

---------------------------------------------------------------------------------------------------
function PlugPreview:OnNextButton()
    self.currScreen = self.currScreen + 1
    if self.currScreen > self.numScreenshots then
        self.currScreen = 1
    end
    
    self:DrawScreenshot()
end

---------------------------------------------------------------------------------------------------
function PlugPreview:OnPreviousButton()
    self.currScreen = self.currScreen - 1
    if self.currScreen < 1 then
        self.currScreen = self.numScreenshots
    end
    
    self:DrawScreenshot()
end

---------------------------------------------------------------------------------------------------
function PlugPreview:DrawScreenshot()
    if self.numScreenshots > 0 and self.plugItem ~= nil then
        local spriteList = self.plugItem["screenshots"]
        local sprite = spriteList[self.currScreen].sprite
        self.tWndRefs.winScreen:SetSprite("ClientSprites:"..sprite)
    else
        self.tWndRefs.winScreen:SetSprite("")
    end
end

---------------------------------------------------------------------------------------------------
function PlugPreview:GetItem(id, itemlist)
  local ix, item
  for ix = 1, #itemlist do
    item = itemlist[ix]
    if item["id"] == id then
      return item
    end
  end
  return nil
end

-----------------------------------------------------------------------------------------------
-- PlugPreview Instance
-----------------------------------------------------------------------------------------------
local PlugPreviewInst = PlugPreview:new()
PlugPreviewInst:Init()
