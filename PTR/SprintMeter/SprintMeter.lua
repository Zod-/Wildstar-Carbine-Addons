-----------------------------------------------------------------------------------------------
-- Client Lua Script for SprintMeter
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "GameLib"
require "Apollo"
require "ApolloTimer"

local SprintMeter = {}

function SprintMeter:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function SprintMeter:Init()
	Apollo.RegisterAddon(self)
end

function SprintMeter:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("SprintMeter.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function SprintMeter:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("CharacterCreated",				"OnCharacterCreated", self)
	Apollo.RegisterEventHandler("WindowManagementReady",		"OnWindowManagementReady", self)
	Apollo.RegisterEventHandler("WindowManagementUpdate", 		"OnWindowManagementUpdate", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat",			"OnUnitEnteredCombat", self)
	Apollo.RegisterEventHandler("PlayerMovementSpeedUpdate",	"OnPlayerMovementSpeedUpdate", self)
	Apollo.RegisterEventHandler("SprintStateUpdated",			"OnSprintStateUpdated", self)
	Apollo.RegisterEventHandler("DashEnergyUpdated",			"OnDashEnergyUpdated", self)
	Apollo.RegisterEventHandler("SprintEnergyUpdated",			"OnSprintEnergyUpdated", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 	"OnTutorial_RequestUIAnchor", self)
	
	self.timerDashMeterGracePeriod = ApolloTimer.Create(0.4, false, "OnDashMeterGracePeriod", self)
	self.timerSprintMeterGracePeriod = ApolloTimer.Create(0.4, false, "OnSprintMeterGracePeriod", self)
	self.timerIndicatorIconFade = ApolloTimer.Create(2, false, "OnIndicatorIconFade", self)
	
	self.timerDashMeterGracePeriod:Stop()
	self.timerSprintMeterGracePeriod:Stop()
	self.timerIndicatorIconFade:Stop()
	
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "SprintMeterFormVert", "InWorldHudStratum", self)
	self.xmlDoc = nil
	
	self.tWindowMap =
	{
		["Backer"]			= 	self.wndMain:FindChild("Backer"),
		["IndicatorIcon"]	=	self.wndMain:FindChild("IndicatorIcon"),
		["SprintBG"]		=	self.wndMain:FindChild("SprintBG"),
		["SprintProgBar"]	=	self.wndMain:FindChild("SprintBG"):FindChild("ProgBar"),
		["SprintProgFlash"]	=	self.wndMain:FindChild("SprintBG"):FindChild("ProgFlash"),
		["DashBG"]			=	self.wndMain:FindChild("DashBG"),
		["DashProg1"]		=	self.wndMain:FindChild("DashBG"):FindChild("DashProg1"),
		["DashProg2"]		=	self.wndMain:FindChild("DashBG"):FindChild("DashProg2"),
		["DashProgFlash1"]	=	self.wndMain:FindChild("DashBG"):FindChild("DashProgFlash1"),
		["DashProgFlash2"]	=	self.wndMain:FindChild("DashBG"):FindChild("DashProgFlash2"),
	}
	
	self.eMoveSpeed = nil
	self.bPlayerInCombat = nil
	self.bIsMoveable = nil
	self.bJustFilledDash = false
	self.bJustFilledSprint = false
	self.nLastDashValue = 0
	self.nLastSprintValue = 0
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer and unitPlayer:IsValid() then
		self.eMoveSpeed = unitPlayer:GetPlayerMovementSpeed()
		self.bPlayerInCombat = unitPlayer:IsInCombat()
		
		self:OnPlayerMovementSpeedUpdate(self.eMoveSpeed)
		self:OnSprintEnergyUpdated(unitPlayer:GetResource(Unit.CodeEnumEUnitStatType.Resources0), unitPlayer:GetMaxResource(Unit.CodeEnumEUnitStatType.Resources0))
		self:OnDashEnergyUpdated(unitPlayer:GetResource(Unit.CodeEnumEUnitStatType.Resources6), unitPlayer:GetMaxResource(Unit.CodeEnumEUnitStatType.Resources6))
	end
	
	self:OnWindowManagementReady()
end

function SprintMeter:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer and unitPlayer:IsValid() then
		self.eMoveSpeed = unitPlayer:GetPlayerMovementSpeed()
		self.bPlayerInCombat = unitPlayer:IsInCombat()
	end
end

function SprintMeter:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", { strName = Apollo.GetString("SprintMeter_SprintMeter"), nSaveVersion = 3 })
	Event_FireGenericEvent("WindowManagementAdd", { wnd = self.wndMain, strName = Apollo.GetString("SprintMeter_SprintMeter") })
end

function SprintMeter:OnWindowManagementUpdate(tSettings)
	if not tSettings or not tSettings.wnd or tSettings.wnd ~= self.wndMain then
		return
	end
	
	self.bIsMoveable = self.wndMain:IsStyleOn("Moveable")
	self.wndMain:SetStyle("IgnoreMouse", not self.bIsMoveable)
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer and unitPlayer:IsValid() then
		self:OnPlayerMovementSpeedUpdate(self.eMoveSpeed)
		self:OnSprintEnergyUpdated(unitPlayer:GetResource(Unit.CodeEnumEUnitStatType.Resources0), unitPlayer:GetMaxResource(Unit.CodeEnumEUnitStatType.Resources0))
		self:OnDashEnergyUpdated(unitPlayer:GetResource(Unit.CodeEnumEUnitStatType.Resources7), unitPlayer:GetMaxResource(Unit.CodeEnumEUnitStatType.Resources7))
	end
end

function SprintMeter:OnUnitEnteredCombat(unit, bIsInCombat)
	if unit ~= GameLib.GetPlayerUnit() then
		return
	end
	
	self.bPlayerInCombat = bIsInCombat
	
	if bIsInCombat and self.eMoveSpeed == GameLib.CodeEnumMoveSpeed.Sprint then
		self.tWindowMap["IndicatorIcon"]:SetSprite("SprintMeter:sprRun")
	elseif not bIsInCombat then
		self.tWindowMap["IndicatorIcon"]:Show(self.bIsMoveable)
		if self.eMoveSpeed == GameLib.CodeEnumMoveSpeed.Sprint then
			self.tWindowMap["IndicatorIcon"]:SetSprite("SprintMeter:sprSprint")
		elseif self.eMoveSpeed == GameLib.CodeEnumMoveSpeed.Walk then
			self.tWindowMap["IndicatorIcon"]:SetSprite("SprintMeter:sprWalk")
		end
	end
end

function SprintMeter:OnPlayerMovementSpeedUpdate(eMoveSpeed)
	self.eMoveSpeed = eMoveSpeed
	self.tWindowMap["IndicatorIcon"]:Show(true)
	
	if eMoveSpeed == GameLib.CodeEnumMoveSpeed.Walk then
		self.tWindowMap["IndicatorIcon"]:SetSprite("SprintMeter:sprWalk")
	elseif eMoveSpeed == GameLib.CodeEnumMoveSpeed.Run then
		self.tWindowMap["IndicatorIcon"]:SetSprite("SprintMeter:sprRun")
	elseif eMoveSpeed == GameLib.CodeEnumMoveSpeed.Sprint then
		self.tWindowMap["IndicatorIcon"]:SetSprite("SprintMeter:sprSprint")
	end
	
	self.timerIndicatorIconFade:Stop()
	self.timerIndicatorIconFade:Start()
end

function SprintMeter:OnSprintStateUpdated(bEnabled)
	if bEnabled then
		self.tWindowMap["IndicatorIcon"]:Show(true)
		self.tWindowMap["IndicatorIcon"]:SetSprite("SprintMeter:sprSprint")
		self.timerIndicatorIconFade:Stop()
	elseif self.bPlayerInCombat and self.eMoveSpeed == GameLib.CodeEnumMoveSpeed.Walk then
		self.tWindowMap["IndicatorIcon"]:Show(self.bIsMoveable)
		self.tWindowMap["IndicatorIcon"]:SetSprite("SprintMeter:sprWalk")
	elseif self.bPlayerInCombat or self.eMoveSpeed == GameLib.CodeEnumMoveSpeed.Run then
		self.tWindowMap["IndicatorIcon"]:Show(self.bIsMoveable)
		self.tWindowMap["IndicatorIcon"]:SetSprite("SprintMeter:sprRun")
		self.timerIndicatorIconFade:Stop()
	end
end

function SprintMeter:OnIndicatorIconFade()
	self.tWindowMap["IndicatorIcon"]:Show(self.bIsMoveable)
end

function SprintMeter:OnDashEnergyUpdated(nDashCurr, nDashMax)
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer or not unitPlayer:IsValid() then
		return
	end
	
	local bAtMaxDash = nDashCurr == nDashMax or unitPlayer:GetHealth() == 0
	
	if self.nLastDashValue ~= nDashCurr or self.bIsMoveable then
		local nHalfDash = nDashMax / 2
		self.tWindowMap["DashProg1"]:SetMax(nHalfDash)
		self.tWindowMap["DashProg1"]:SetProgress(nDashCurr)
		self.tWindowMap["DashProg2"]:SetMax(nHalfDash)
		self.tWindowMap["DashProg2"]:SetProgress(nDashCurr - nHalfDash)
		if nDashCurr >= nHalfDash and self.nLastDashValue < nHalfDash then
			self.tWindowMap["DashProgFlash1"]:SetSprite("SprintMeter:sprDashBot_Flash")
		end
		self.nLastDashValue = nDashCurr
	end
	
	if bAtMaxDash and not self.bJustFilledDash and self.tWindowMap["DashBG"]:IsVisible() then
		self.bJustFilledDash = true
		self.timerDashMeterGracePeriod:Stop()
		self.timerDashMeterGracePeriod:Start()
		self.tWindowMap["DashProgFlash2"]:SetSprite("SprintMeter:sprDashTop_Flash")
	elseif not bAtMaxDash then
		self.bJustFilledDash = false
		self.timerDashMeterGracePeriod:Stop()
	end
	
	self.tWindowMap["DashBG"]:Show(self.bIsMoveable or not bAtMaxDash or self.bJustFilledDash, not bAtMaxDash)
end

function SprintMeter:OnSprintEnergyUpdated(nRunCurr, nRunMax)
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer or not unitPlayer:IsValid() then
		return
	end
	
	local bAtMaxSprint = nRunCurr == nRunMax or unitPlayer:GetHealth() == 0
	
	if self.nLastSprintValue ~= nRunCurr then
		self.tWindowMap["SprintProgBar"]:SetMax(nRunMax)
		self.tWindowMap["SprintProgBar"]:SetProgress(nRunCurr, self.tWindowMap["SprintBG"]:IsVisible() and nRunMax or 0)
		self.nLastSprintValue = nRunCurr
	end
	
	if bAtMaxSprint and not self.bJustFilledSprint and self.tWindowMap["SprintBG"]:IsVisible() then
		self.bJustFilledSprint = true
		self.timerSprintMeterGracePeriod:Stop()
		self.timerSprintMeterGracePeriod:Start()
		self.tWindowMap["SprintProgFlash"]:SetSprite("SprintMeter:sprVerticalBar_Flash")
	elseif not bAtMaxSprint then
		self.bJustFilledSprint = false
		self.timerSprintMeterGracePeriod:Stop()
	end
	
	self.tWindowMap["SprintBG"]:Show(self.bIsMoveable or not bAtMaxSprint or self.bJustFilledSprint, not bAtMaxSprint)
end

function SprintMeter:OnSprintMeterGracePeriod()
	self.bJustFilledSprint = false
	self.tWindowMap["SprintBG"]:Show(self.bIsMoveable)
end

function SprintMeter:OnDashMeterGracePeriod()
	self.bJustFilledDash = false
	self.tWindowMap["DashBG"]:Show(self.bIsMoveable)
end

function SprintMeter:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors = 
	{
		[GameLib.CodeEnumTutorialAnchor.SprintMeter] = true,
	}
	if not tAnchors[eAnchor] then
		return
	end
	
	local tAnchorMapping = 
	{
		[GameLib.CodeEnumTutorialAnchor.SprintMeter] = self.wndMain,
	}
	
	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

local SprintMeterInst = SprintMeter:new()
SprintMeterInst:Init()