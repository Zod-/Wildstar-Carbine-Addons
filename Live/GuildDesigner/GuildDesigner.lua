-----------------------------------------------------------------------------------------------
-- Client Lua Script for GuildDesigner
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Money"
require "ChallengesLib"
require "Unit"
require "GameLib"
require "Apollo"
require "PathMission"
require "Quest"
require "Episode"
require "math"
require "string"
require "DialogSys"
require "PublicEvent"
require "PublicEventObjective"
require "CommunicatorLib"
require "Tooltip"
require "GroupLib"
require "PlayerPathLib"
 
-----------------------------------------------------------------------------------------------
-- GuildDesigner Module Definition
-----------------------------------------------------------------------------------------------
local GuildDesigner = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local kstrNoPermissions = Apollo.GetString("GuildDesigner_NotEnoughPermissions")
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function GuildDesigner:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    o.tWndRefs = {}

    return o
end

function GuildDesigner:Init()
    Apollo.RegisterAddon(self)
end
 
-----------------------------------------------------------------------------------------------
-- GuildDesigner OnLoad
-----------------------------------------------------------------------------------------------
function GuildDesigner:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("GuildDesigner.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function GuildDesigner:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()
    
	Apollo.RegisterEventHandler("Event_GuildDesignerOn", "OnGuildDesignerOn", self)
	Apollo.RegisterEventHandler("GuildResultInterceptResponse", "OnGuildResultInterceptResponse", self)
	Apollo.RegisterEventHandler("GuildStandard", "OnGuildDesignUpdated", self)
	Apollo.RegisterEventHandler("GuildInfluenceAndMoney", "OnGuildInfluenceAndMoney", self)
	Apollo.RegisterEventHandler("GuildRegistrarClose", "OnCloseVendorWindow", self) 
end

function GuildDesigner:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("GuildDesigner_GuildDesigner")})
end

-----------------------------------------------------------------------------------------------
-- GuildDesigner Functions
-----------------------------------------------------------------------------------------------
function GuildDesigner:Initialize()
	local wndMain = Apollo.LoadForm(self.xmlDoc, "GuildDesignerForm", nil, self)
    self.tWndRefs.wndMain = wndMain
   	self.tWndRefs.wndGuildName = wndMain:FindChild("GuildNameString")
	self.tWndRefs.wndRegisterBtn = wndMain:FindChild("RegisterBtn")
	self.tWndRefs.wndAlert = wndMain:FindChild("AlertMessage")
	self.tWndRefs.wndHolomark = wndMain:FindChild("HolomarkContent")
	self.tWndRefs.wndHolomarkCostume = wndMain:FindChild("HolomarkCostume")
	
	self.tCurrent 			= {}
	self.tNewOptions		= {}
	self.bShowingResult 	= false
	
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndMain, strName = Apollo.GetString("GuildDesigner_GuildDesigner")})
end

function GuildDesigner:OnGuildDesignerOn()
	self:Initialize()
	self:SetDefaults()
	self:ResetOptions()
	self.tWndRefs.wndMain:Invoke()
end

---------------------------------------------------------------------------------------------------
function GuildDesigner:OnWindowClosed(wndHandler, wndControl)
	-- called after the window is closed by:
	--	self.winMasterCustomizeFrame:Close() or 
	--  hitting ESC
	
	if wndControl ~= wndHandler then
	    return
	end
	
	if self.timerModifyError then
		self.timerModifyError:Stop()
	end
	if self.timerModifySuccess then
		self.timerModifySuccess:Stop()
	end

	self.tWndRefs = {}
	
	Event_CancelGuildRegistration()
	
	Sound.Play(Sound.PlayUIWindowClose)
	Event_FireGenericEvent("WindowManagementRemove", {strName = Apollo.GetString("GuildDesigner_GuildDesigner")})
end

function GuildDesigner:OnCloseVendorWindow()
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain:Close() -- just close the window which will trigger OnWindowClosed
	end
end

function GuildDesigner:SetDefaults()
	local guildLoaded = nil
	
	self.bShowingResult = false
	
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr:GetType() == GuildLib.GuildType_Guild then
			guildLoaded = guildCurr
		end
	end

	if guildLoaded == nil then
		self:FormatNoGuild()
		return
	end
	
	self.tWndRefs.wndRegisterBtn:SetData(guildLoaded)
	
	self.tWndRefs.wndMain:FindChild("GuildRevertBtn"):Enable(false)
	self.tWndRefs.wndMain:FindChild("CostAmount"):SetText(0)
	self.tWndRefs.wndMain:FindChild("InfluenceAmount"):SetText(guildLoaded:GetInfluence())
	
	self.tCurrent.strName = guildLoaded:GetName()
	self.tWndRefs.wndGuildName:SetText(self.tCurrent.strName)
	self.tWndRefs.wndGuildName:Enable(false)
	
	self:SetDefaultHolomark()
	
	if guildLoaded:GetMyRank() ~= 1 then -- not a leader. TODO: enum not hardcoded
		self.tWndRefs.wndMain:FindChild("GuildPermissionsAlert"):SetText(kstrNoPermissions)
	else
		self.tWndRefs.wndMain:FindChild("GuildPermissionsAlert"):SetText("")
	end	
end

function GuildDesigner:FormatNoGuild()
	self.tWndRefs.wndGuildName:Enable(true)
	self.tWndRefs.wndRegisterBtn:Enable(false)
	self.tWndRefs.wndAlert:Show(true)
	self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("GuildDesigner_NoGuild"))
	self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetTextColor(ApolloColor.new("LightOrange"))
	self.tWndRefs.wndAlert:FindChild("MessageBodyText"):SetText(Apollo.GetString("GuildDesginer_MustBeInGuild"))

end

function GuildDesigner:ResetOptions()
	if self.tCurrent.strName ~= nil then
		self.tWndRefs.wndGuildName:SetText(self.tCurrent.strName)
	else
		self.tWndRefs.wndGuildName:SetText("")
	end
	
	self.tWndRefs.wndAlert:Show(false)
	self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetText("")
	self.tWndRefs.wndAlert:FindChild("MessageBodyText"):SetText("")

	self:UpdateOptions()
end

function GuildDesigner:UpdateOptions()
	local guildOwner = self.tWndRefs.wndRegisterBtn:GetData()
	if guildOwner == nil then
		return
	end
	
	local tRanks = guildOwner:GetRanks()
	if tRanks == nil then
		return
	end

	local bHasGuildPermissions = tRanks[guildOwner:GetMyRank()].bEmblemAndStandard
	
	self.tWndRefs.wndMain:FindChild("GuildPermissionsAlert"):SetText(bHasGuildPermissions and kstrNoPermissions or "")

	local bChangeDetected = self:IsHolomarkChanged()
	
	self.tWndRefs.wndMain:FindChild("ResetAllBtn"):Enable(bChangeDetected)
	self.tWndRefs.wndRegisterBtn:Enable(bChangeDetected and bHasGuildPermissions)

	self:UpdateCost()
end

function GuildDesigner:UpdateCost()
	
	local nCost = 0

	if self:IsHolomarkChanged() then
		nCost = nCost + GuildLib.GetHolomarkModifyCost()
	end
	
	self.tWndRefs.wndMain:FindChild("CostAmount"):SetText(nCost)

end

-----------------------------------------------------------------------------------------------
-- Holomark Functions
-----------------------------------------------------------------------------------------------
function GuildDesigner:SetDefaultHolomark()

	self:InitializeHolomarkParts()
	
	local guildOwner = self.tWndRefs.wndRegisterBtn:GetData()
	if guildOwner == nil then
		return
	end
	
	self.tCurrent.tHolomark = guildOwner:GetStandard()
	self.tNewOptions.tHolomark = guildOwner:GetStandard()
	
	local tHolomarkPartNames = { "tBackgroundIcon", "tForegroundIcon", "tScanLines" }
	
	for idx, tPartList in ipairs(self.tHolomarkParts) do
		for key, tPart in ipairs(tPartList) do
			if tPart.idBannerPart == self.tCurrent.tHolomark[tHolomarkPartNames[idx]].idPart then
				self.tWndRefs.wndMain:FindChild("HolomarkOption."..idx):SetText(tPart.strName)
			end
		end
	end

	--[[
	self.tCurrent.tHolomark = 
	{
		tBackgroundIcon = 
		{
			nPartId = self.tHolomarkParts[1][1]["id"],
			nColorId1 = 2,
			nColorId2 = 2,
			nColorId3 = 2,
		},
		
		tForegroundIcon = 
		{
			nPartId = self.tHolomarkParts[2][1]["id"],
			nColorId1 = 2,
			nColorId2 = 2,
			nColorId3 = 2,
		},
		
		tScanLines = 
		{
			nPartId = self.tHolomarkParts[3][1]["id"],
			nColorId1 = 2,
			nColorId2 = 2,
			nColorId3 = 2,
		},
	}
	
	self.tNewOptions.tHolomark = self.tCurrent.tHolomark
	--]]

	
	self.tWndRefs.wndHolomarkCostume:SetCostumeToGuildStandard(self.tCurrent.tHolomark)
end

function GuildDesigner:InitializeHolomarkParts()

	self.tHolomarkPartListItems = {}
	self.tWndRefs.wndHolomarkOption = nil
	self.tWndRefs.wndHolomarkOptionList = nil
	
	self.tHolomarkParts = {}
	self.tHolomarkParts[1] = GuildLib.GetBannerBackgroundIcons()
	self.tHolomarkParts[2] = GuildLib.GetBannerForegroundIcons()
	self.tHolomarkParts[3] = GuildLib.GetBannerScanLines()
end

function GuildDesigner:OnHolomarkPartCheck1( wndHandler, wndControl, eMouseButton )
	self:FillHolomarkPartList(1)
	self.tWndRefs.wndHolomarkOption = self.tWndRefs.wndMain:FindChild("HolomarkOption.1")
	self.tWndRefs.wndHolomarkOptionList = self.tWndRefs.wndMain:FindChild("HolomarkPartWindow.1")
	self.tWndRefs.wndHolomarkOptionList:SetData(1)
	self.tWndRefs.wndHolomarkOptionList:Show(true)
end

function GuildDesigner:OnHolomarkPartUncheck1( wndHandler, wndControl, eMouseButton )
	self.tWndRefs.wndMain:FindChild("HolomarkPartWindow.1"):Show(false)
end

function GuildDesigner:OnHolomarkPartCheck2( wndHandler, wndControl, eMouseButton )
	self:FillHolomarkPartList(2)
	self.tWndRefs.wndHolomarkOption = self.tWndRefs.wndMain:FindChild("HolomarkOption.2")
	self.tWndRefs.wndHolomarkOptionList = self.tWndRefs.wndMain:FindChild("HolomarkPartWindow.2")
	self.tWndRefs.wndHolomarkOptionList:SetData(2)
	self.tWndRefs.wndHolomarkOptionList:Show(true)
end

function GuildDesigner:OnHolomarkPartUncheck2( wndHandler, wndControl, eMouseButton )
	self.tWndRefs.wndMain:FindChild("HolomarkPartWindow.2"):Show(false)
end

function GuildDesigner:OnHolomarkPartCheck3( wndHandler, wndControl, eMouseButton )
	self:FillHolomarkPartList(3)
	self.tWndRefs.wndHolomarkOption = self.tWndRefs.wndMain:FindChild("HolomarkOption.3")
	self.tWndRefs.wndHolomarkOptionList = self.tWndRefs.wndMain:FindChild("HolomarkPartWindow.3")
	self.tWndRefs.wndHolomarkOptionList:SetData(3)
	self.tWndRefs.wndHolomarkOptionList:Show(true)
end

function GuildDesigner:OnHolomarkPartUncheck3( wndHandler, wndControl, eMouseButton )
	self.tWndRefs.wndMain:FindChild("HolomarkPartWindow.3"):Show(false)
end

function GuildDesigner:FillHolomarkPartList( ePartType )
	local wndList = self.tWndRefs.wndMain:FindChild("HolomarkPartList."..(ePartType))
	wndList:DestroyChildren()
	
	local tPartList = self.tHolomarkParts[ePartType]
	if tPartList == nil then
		return
	end
	
	for idx = 1, #tPartList do
		self:AddHolomarkPartItem(wndList, idx, tPartList[idx])
	end
end

function GuildDesigner:AddHolomarkPartItem(wndList, index, tPart)
	-- load the window item for the list item
	local wnd = Apollo.LoadForm(self.xmlDoc, "HolomarkPartListItem", wndList, self)
	
	self.tHolomarkPartListItems[index] = wnd
	
	local wndItemBtn = wnd:FindChild("HolomarkPartBtn")
	if wndItemBtn then -- make sure the text wnd exist
	    local strName = tPart.strName
		wndItemBtn:SetText(strName)
		wndItemBtn:SetData(tPart)
	end
	wndList:ArrangeChildrenVert()
end

function GuildDesigner:OnHolomarkPartSelectionClosed( wndHandler, wndControl )
	-- destroy all the wnd inside the list
	for idx,wnd in ipairs(self.tHolomarkPartListItems) do
		wnd:Destroy()
	end
	
	if self.tWndRefs.wndHolomarkOptionList:IsVisible() then
        self.tWndRefs.wndHolomarkOptionList:Show(false)
	end
	self.tWndRefs.wndHolomarkOption:SetCheck(false)

	-- clear the list item array
	self.tHolomarkPartListItems = {}
end

function GuildDesigner:OnHolomarkPartItemSelected(wndHandler, wndControl)
	if not wndControl then 
        return 
    end

	local tPart = wndControl:GetData()
    if tPart ~= nil and self.tWndRefs.wndHolomarkOption ~= nil then
		self.tWndRefs.wndHolomarkOption:SetText(tPart.strName)
		
		local eType = self.tWndRefs.wndHolomarkOptionList:GetData()
		if eType == 1 then
			self.tNewOptions.tHolomark.tBackgroundIcon.idPart = tPart.idBannerPart
		elseif eType == 2 then
			self.tNewOptions.tHolomark.tForegroundIcon.idPart = tPart.idBannerPart
		elseif eType == 3 then
			self.tNewOptions.tHolomark.tScanLines.idPart = tPart.idBannerPart
		end

		self.tWndRefs.wndHolomarkCostume:SetCostumeToGuildStandard(self.tNewOptions.tHolomark)
	end
	
	self:UpdateOptions()
	
	self:OnHolomarkPartSelectionClosed(wndHandler, wndControl)
end

function GuildDesigner:IsHolomarkChanged()
	local bChanged = false
	if self.tCurrent.tHolomark.tBackgroundIcon.idPart ~= self.tNewOptions.tHolomark.tBackgroundIcon.idPart or 
	   self.tCurrent.tHolomark.tForegroundIcon.idPart ~= self.tNewOptions.tHolomark.tForegroundIcon.idPart or 
	   self.tCurrent.tHolomark.tScanLines.idPart ~= self.tNewOptions.tHolomark.tScanLines.idPart then
		bChanged = true
	end

	return bChanged
end

-----------------------------------------------------------------------------------------------
-- GuildDesignerForm Functions
-----------------------------------------------------------------------------------------------

-- when the OK button is clicked
function GuildDesigner:OnCommitBtn(wndHandler, wndControl)  -- TODO!!!
	local t = self.tNewOptions
	
	guildCommitted = wndControl:GetData()
	
	if guildCommitted ~= nil then
		
		local arGuildResultsExpected = { GuildLib.GuildResult_VendorOutOfRange, GuildLib.GuildResult_InvalidStandard, GuildLib.GuildResult_CanOnlyModifyRanksBelowYours, 
										 GuildLib.GuildResult_UnableToProcess, GuildLib.GuildResult_InvalidRank, GuildLib.GuildResult_InvalidRankName, 
										 GuildLib.GuildResult_InvalidGuildName, GuildLib.GuildResult_RankLacksSufficientPermissions, GuildLib.GuildResult_InsufficientInfluence, 
										 GuildLib.GuildResult_GuildNameUnavailable }

		Event_FireGenericEvent("GuildResultInterceptRequest", GuildLib.GuildType_Guild, self.tWndRefs.wndMain, arGuildResultsExpected )

		guildCommitted:Modify(self.tNewOptions.tHolomark)

		self.tWndRefs.wndRegisterBtn:Enable(false)
		self.tWndRefs.wndMain:FindChild("ResetAllBtn"):Enable(false)
	end
	
	--NOTE: Requires a server response to progress
end

-- when the Cancel button is clicked
function GuildDesigner:OnCancel(wndHandler, wndControl)
	self:ResetOptions()	
	self.tWndRefs.wndMain:Close()
end

function GuildDesigner:OnResetAllBtn(wndHandler, wndControl)
	self:SetDefaults()
	self.tWndRefs.wndRegisterBtn:Enable(false)
end

-- FAILURE ONLY
function GuildDesigner:OnGuildResultInterceptResponse( guildCurr, eGuildType, eResult, wndRegistration, strAlertMessage )
	if eGuildType ~= GuildLib.GuildType_Guild or wndRegistration ~= self.tWndRefs.wndMain then
		return
	end

	-- NOTE: success is processed with a different message.

	if not self.tWndRefs.wndAlert or not self.tWndRefs.wndAlert:IsValid() then
		return
	end

	self.bShowingResult = true
	
	self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("GuildDesigner_Whoops"))
	self.timerModifyError = ApolloTimer.Create(3.00, false, "OnGuildDesigner_ModifyErrorTimer", self)

	self.tWndRefs.wndAlert:FindChild("MessageBodyText"):SetText(strAlertMessage)
	self.tWndRefs.wndAlert:Show(true)
end

-- SUCCESS ONLY
function GuildDesigner:OnGuildDesignUpdated(guildUpdated) 
	if self.tWndRefs.wndRegisterBtn == nil or guildUpdated ~= self.tWndRefs.wndRegisterBtn:GetData() then 
		return
	end
	
	self.bShowingResult = true
	
	self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("GuildDesigner_Success"))
	self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
	self.timerModifySuccess = ApolloTimer.Create(3.00, false, "OnGuildDesigner_ModifySuccessfulTimer", self)

	self.tWndRefs.wndAlert:FindChild("MessageBodyText"):SetText(Apollo.GetString("GuildDesigner_Updated"))
	self.tWndRefs.wndAlert:Show(true)
end

function GuildDesigner:OnGuildDesigner_ModifySuccessfulTimer()
	self.bShowingResult = false
	self.tWndRefs.wndAlert:Show(false)
	self:SetDefaults()
end

function GuildDesigner:OnGuildDesigner_ModifyErrorTimer()
	self.bShowingResult = false
	self.tWndRefs.wndAlert:Show(false)
	self.tWndRefs.wndMain:FindChild("ResetAllBtn"):Enable(true) -- something had to have been changed
	self.tWndRefs.wndRegisterBtn:Enable(true) -- safe to assume since it was clicked once
end

function GuildDesigner:OnGuildInfluenceAndMoney(guildCurr, monInfluence, monCash)
	if guildCurr:GetType() == GuildLib.GuildType_Guild and self.tWndRefs.wndMain ~= nil then
		self.tWndRefs.wndMain:FindChild("InfluenceAmount"):SetText(guildCurr:GetInfluence())
	end
end

function GuildDesigner:OnNameChanged(wndHandler, wndControl, strName)
	self:UpdateOptions()
end

-----------------------------------------------------------------------------------------------
-- GuildDesigner Instance
-----------------------------------------------------------------------------------------------
local GuildDesignerInst = GuildDesigner:new()
GuildDesignerInst:Init()


