-----------------------------------------------------------------------------------------------
-- Client Lua Script for Crafting
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "CraftingLib"

local Crafting = {}

local ktTutorialText =
{
	[1] = "Crafting_TutorialAmps",
	[2] = "Crafting_TutorialResult",
	[3] = "Crafting_TutorialPowerSwitch",
	[4] = "Crafting_TutorialChargeMeter",
	[5] = "Crafting_TutorialFailChargeMeter",
}

local karEvalStrings =
{
	[Item.CodeEnumItemQuality.Inferior] 		= Apollo.GetString("CRB_Inferior"),
	[Item.CodeEnumItemQuality.Average] 			= Apollo.GetString("CRB_Average"),
	[Item.CodeEnumItemQuality.Good] 			= Apollo.GetString("CRB_Good"),
	[Item.CodeEnumItemQuality.Excellent] 		= Apollo.GetString("CRB_Excellent"),
	[Item.CodeEnumItemQuality.Superb] 			= Apollo.GetString("CRB_Superb"),
	[Item.CodeEnumItemQuality.Legendary] 		= Apollo.GetString("CRB_Legendary"),
	[Item.CodeEnumItemQuality.Artifact] 		= Apollo.GetString("CRB_Artifact"),
}

local ktPowerCoreColors =
{
	[Item.CodeEnumItemQuality.Average] 			= "btnCircuit_PowerCore_White",
	[Item.CodeEnumItemQuality.Good] 			= "btnCircuit_PowerCore_Green",
	[Item.CodeEnumItemQuality.Excellent] 		= "btnCircuit_PowerCore_Blue",
	[Item.CodeEnumItemQuality.Superb] 			= "btnCircuit_PowerCore_Purple",
	[Item.CodeEnumItemQuality.Legendary] 		= "btnCircuit_PowerCore_Orange",
	[Item.CodeEnumItemQuality.Artifact]		 	= "btnCircuit_PowerCore_Pink",
}

local ktElementToSpriteColor =
{
	[CraftingLib.CodeEnumItemCraftingGroupFlag.Air] 	= "White",
	[CraftingLib.CodeEnumItemCraftingGroupFlag.Water] 	= "Blue",
	[CraftingLib.CodeEnumItemCraftingGroupFlag.Earth] 	= "Brown",
	[CraftingLib.CodeEnumItemCraftingGroupFlag.Fire] 	= "Red",
	[CraftingLib.CodeEnumItemCraftingGroupFlag.Logic] 	= "YellowGreen",
	[CraftingLib.CodeEnumItemCraftingGroupFlag.Life] 	= "Green",
}

local karPropertyIcons =
{
	[Unit.CodeEnumProperties.RatingFocusRecovery] 			= "IconSprites:Icon_CraftingIcon_Air_Recovery_CircuitBoard_Crafting_Icon",
	[Unit.CodeEnumProperties.Rating_AvoidReduce] 			= "IconSprites:Icon_CraftingIcon_Air_Strikethrough_CircuitBoard_Crafting_Icon",
	[Unit.CodeEnumProperties.Rating_AvoidIncrease] 			= "IconSprites:Icon_CraftingIcon_Air_Deflect_CircuitBoard_Crafting_Icon",
	[Unit.CodeEnumProperties.RatingMultiHitChance] 			= "IconSprites:Icon_CraftingIcon_Water_CircuitBoard_Crafting_Multihit_Icon",
	[Unit.CodeEnumProperties.RatingGlanceChance] 			= "IconSprites:Icon_CraftingIcon_Water_CircuitBoard_Crafting_Glance_Icon",
	[Unit.CodeEnumProperties.RatingCritSeverityIncrease] 	= "IconSprites:Icon_CraftingIcon_Earth_CriticalHitSeverity_CircuitBoard_Crafting_Icon",
	[Unit.CodeEnumProperties.RatingCCResilience] 			= "IconSprites:Icon_CraftingIcon_CircuitBoard_Crafting_Resilience_Icon",
	[Unit.CodeEnumProperties.Rating_CritChanceIncrease] 	= "IconSprites:Icon_CraftingIcon_Fire_CriticalHit_CircuitBoard_Crafting_Icon",
	[Unit.CodeEnumProperties.RatingDamageReflectChance] 	= "IconSprites:Icon_CraftingIcon_Fire_Reflect_CircuitBoard_Crafting_Icon",
	[Unit.CodeEnumProperties.RatingCriticalMitigation] 		= "IconSprites:Icon_CraftingIcon_Logic_CriticalMitigation_CircuitBoard_Crafting_Icon",
	[Unit.CodeEnumProperties.RatingIntensity] 				= "IconSprites:Icon_CraftingIcon_Logic_Iintensity_CircuitBoard_Crafting_Icon",
	[Unit.CodeEnumProperties.RatingVigor] 					= "IconSprites:Icon_CraftingIcon_Logic_Vigor_CircuitBoard_Crafting_Icon",
	[Unit.CodeEnumProperties.BaseFocusPool] 				= "IconSprites:Icon_CraftingIcon_Life_Focusl_CircuitBoard_Crafting_Icon",
	[Unit.CodeEnumProperties.RatingLifesteal] 				= "IconSprites:Icon_CraftingIcon_Life_Lifesteal_CircuitBoard_Crafting_Icon",
	[Unit.CodeEnumProperties.Rating_CritChanceIncrease] 	= "IconSprites:Icon_CraftingIcon_Fire_CriticalHit_CircuitBoard_Crafting_Icon",
}

local kfBaseRotation = -math.pi/2

function Crafting:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Crafting:Init()
	Apollo.RegisterAddon(self)
end

function Crafting:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Crafting.xml") -- QuestLog will always be kept in memory, so save parsing it over and over
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Crafting:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("WindowManagementReady", 								"OnWindowManagementReady", self) -- Temporarily disabled

	Apollo.RegisterEventHandler("GenericEvent_CraftingSummaryIsFinished", 				"OnCloseBtn", self)
	Apollo.RegisterEventHandler("GenericEvent_CraftingResume_CloseCraftingWindows",		"DestroyWindow", self)
	Apollo.RegisterEventHandler("GenericEvent_BotchCraft", 								"DestroyWindow", self)
	Apollo.RegisterEventHandler("GenericEvent_StopCircuitCraft",						"DestroyWindow", self)
	Apollo.RegisterEventHandler("GenericEvent_StartCircuitCraft",						"OnGenericEvent_StartCircuitCraft", self)
	Apollo.RegisterEventHandler("CraftingInterrupted",									"OnCraftingInterrupted", self)
	Apollo.RegisterEventHandler("CraftingStationClose",									"OnOutOfRange", self)

	Apollo.RegisterEventHandler("P2PTradeInvite", 										"OnP2PTradeExitAndReset", self)
	Apollo.RegisterEventHandler("P2PTradeWithTarget", 									"OnP2PTradeExitAndReset", self)
	
	Apollo.RegisterEventHandler("GenericEvent_CraftingSummary_Closed",					"OnSummaryClosed", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 							"OnTutorial_RequestUIAnchor", self)
end

function Crafting:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("CBCrafting_Title"), nSaveVersion = 2})
end

function Crafting:OnGenericEvent_StartCircuitCraft(idSchematic)
	Apollo.RegisterEventHandler("CraftingUpdateCurrent", 		"InitCraftAttempt", self)
	Apollo.RegisterEventHandler("UpdateInventory", 				"CheckMaterials", self)
	Apollo.RegisterEventHandler("PlayerCurrencyChanged",		"CheckMaterials", self)
	
	CraftingLib.ShowTradeskillTutorial()

	-- Check if it's a subschematic, if so use the parent instead.
	self.tSchematicInfo = CraftingLib.GetSchematicInfo(idSchematic)
	if self.tSchematicInfo and self.tSchematicInfo.nParentSchematicId and self.tSchematicInfo.nParentSchematicId ~= 0 then
		idSchematic = self.tSchematicInfo.nParentSchematicId
		self.tSchematicInfo = CraftingLib.GetSchematicInfo(idSchematic)
	end
	
	if not self.tSchematicInfo then
		return
	end
	
	if not self.wndMain then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "CraftingForm", nil, self)
		self.wndMain:Invoke()
		self.ePremiumSystem = AccountItemLib.GetPremiumSystem()
	end
	
	self.wndMain:FindChild("PreviewStartCraftBtn"):SetData(idSchematic)
	self.wndMain:FindChild("CraftButton"):SetData(idSchematic)
	
	self.wndMain:FindChild("ApSpScale"):Show(false)
	
	self.tSocketInfo = 
	{
		nApSpSplitDelta = 0,
		itemPowerCore = nil,
		arStats = {},
	}
	
	self.arBaseCraftingGroups = {}
	
	self.wndSelection = nil
	
	if #self.wndMain:FindChild("ConnectorLayer"):GetChildren() <= 0 then
		self:CreateSockets()
	end
	self:CheckMaterials()
	
	if CraftingLib.GetCurrentCraft() then
		self:InitCraftAttempt()
	end
	
	self:UpdatePreview()
	Event_ShowTutorial(GameLib.CodeEnumTutorial.Crafting_UI_Tutorial)

	Sound.Play(Sound.PlayUIWindowCraftingOpen)
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("CBCrafting_Title")})
end

function Crafting:CreateSockets()
	local nSocketRadius = 150
	local nNubRadius = 100
	local nStartingAngle = kfBaseRotation
	local wndSocketLayer = self.wndMain:FindChild("SocketLayer")
	local wndConnectorLayer = self.wndMain:FindChild("ConnectorLayer")
	local wndPowerCore = wndSocketLayer:FindChild("PowerCore")
	local nLeft, nTop, nRight, nBottom = wndPowerCore:GetAnchorOffsets()
	local nCenterX = wndSocketLayer:GetWidth() / 2
	local nCenterY = wndSocketLayer:GetHeight() / 2
	
	self.arPowerLines = {}
	
	local arPropertyData = CraftingLib.GetAvailableProperties(self.tSchematicInfo.nSchematicId)
	if not self.tSchematicInfo.arStats or #self.tSchematicInfo.arStats == 0 then
		return
	end
	
	if #self.tSchematicInfo.arStats == 2 then
		nStartingAngle = 0
	end
	
	local nDegreeIncrements = 2 * math.pi / #self.tSchematicInfo.arStats
	
	for idx = 1, #self.tSchematicInfo.arStats do
		-- Creating Sockets
		local wndSocket = Apollo.LoadForm(self.xmlDoc, "CircuitSocketItem", wndSocketLayer:FindChild("SocketContainer"), self)
		local wndButton = wndSocket:FindChild("CircuitPickerBtn")

		local nBtnLeft, nBtnTop, nBtnRight, nBtnBottom = wndButton:GetAnchorOffsets()
		local nXOffset = wndSocket:GetWidth() / 2
		local nYOffsetTop = nBtnTop + wndButton:GetHeight() / 2
		local nYOffsetBottom = wndSocket:GetHeight() - nYOffsetTop
		
		local fRotation = (nDegreeIncrements * idx) + nStartingAngle
		
		local nTranslatedCenterX = nSocketRadius * math.cos(fRotation) + nCenterX
		local nTranslatedCenterY = nSocketRadius * math.sin(fRotation) + nCenterY
		
		wndSocket:SetAnchorOffsets(nTranslatedCenterX - nXOffset, nTranslatedCenterY - nYOffsetTop, nTranslatedCenterX + nXOffset, nTranslatedCenterY + nYOffsetBottom)
		wndSocket:SetData(idx)
		wndButton:SetData(idx)
		
		local wndChargeDecrease = wndSocket:FindChild("CircuitSocketChargeText:CircuitPickerSmallLeft")
		local wndChargeIncrease = wndSocket:FindChild("CircuitSocketChargeText:CircuitPickerSmallRight")
		wndChargeIncrease:SetData(idx)
		wndChargeIncrease:Enable(false)
		
		wndChargeDecrease:SetData(idx)
		wndChargeDecrease:Enable(false)
		
		local nXDistanceFromEdge = nTranslatedCenterX > nCenterX and wndSocketLayer:GetWidth() - nTranslatedCenterX or nTranslatedCenterX
		local nYDistanceFromEdge = nTranslatedCenterY > nCenterY and wndSocketLayer:GetHeight() - nTranslatedCenterY or nTranslatedCenterY
		
		-- Drawing Socket to Edge connectors
		local wndEdge = Apollo.LoadForm(self.xmlDoc, "ConnectorBar", wndConnectorLayer, self)
		
		local fAngleToNearestEdge = 0;
		local nDistanceToEdge = 0;
		if nXDistanceFromEdge <= nYDistanceFromEdge then
			if nTranslatedCenterX > nCenterX then
				fAngleToNearestEdge = math.pi / 2
				nDistanceToEdge = wndSocketLayer:GetWidth() - nTranslatedCenterX
			else
				fAngleToNearestEdge = -math.pi / 2
				nDistanceToEdge = nTranslatedCenterX
			end
		else
			if nTranslatedCenterY > nCenterY then
				fAngleToNearestEdge = math.pi
				nDistanceToEdge = wndSocketLayer:GetHeight() - nTranslatedCenterY
			else
				nDistanceToEdge = nTranslatedCenterY
			end
		end
		
		nXOffset = nDistanceToEdge / 2
		local nYOffset = nDistanceToEdge / 2
		
		local nEdgeConnectorX = (nDistanceToEdge / 2) * math.cos(fAngleToNearestEdge + kfBaseRotation) + nTranslatedCenterX
		local nEdgeConnectorY = (nDistanceToEdge / 2) * math.sin(fAngleToNearestEdge + kfBaseRotation) + nTranslatedCenterY
		
		wndEdge:SetAnchorOffsets(nEdgeConnectorX - nXOffset, nEdgeConnectorY - nYOffset, nEdgeConnectorX + nXOffset, nEdgeConnectorY + nYOffset)

		local tPixieInfo = wndEdge:GetPixieInfo(1)
		tPixieInfo.fRotation = fAngleToNearestEdge
		wndEdge:UpdatePixie(1, tPixieInfo)
		
		local wndConnectorOn = wndEdge:FindChild("ConnectorBarFilled")
		tPixieInfo = wndConnectorOn:GetPixieInfo(1)
		tPixieInfo.fRotation = fAngleToNearestEdge
		wndConnectorOn:UpdatePixie(1, tPixieInfo)
		
		-- Setting up the end points for each socket's connector
		local wndEndPoint = Apollo.LoadForm(self.xmlDoc, "EdgeConnectorEnd", wndConnectorLayer, self)
		local nEndPointWidth = wndEndPoint:GetWidth() / 2
		local nEndPointHeight = wndEndPoint:GetHeight() / 2
		
		local nEndCenterX = 0
		local nEndCenterY = 0
		
		if fAngleToNearestEdge == 0 then
			nEndCenterX = nEdgeConnectorX
			nEndCenterY = nEndPointHeight / 2
		elseif fAngleToNearestEdge == math.pi / 2 then
			nEndCenterX = wndSocketLayer:GetWidth() - (nEndPointWidth / 2)
			nEndCenterY = nEdgeConnectorY
		elseif fAngleToNearestEdge == math.pi then
			nEndCenterX = nEdgeConnectorX
			nEndCenterY = wndSocketLayer:GetHeight() - (nEndPointHeight / 2)
		elseif fAngleToNearestEdge == -math.pi / 2 then
			nEndCenterX = nEndPointWidth / 2
			nEndCenterY = nEdgeConnectorY
		end
		
		wndEndPoint:SetAnchorOffsets(nEndCenterX - nEndPointWidth, nEndCenterY - nEndPointHeight, nEndCenterX + nEndPointWidth, nEndCenterY + nEndPointHeight)
		
		-- Drawing Core to Socket connectors
		local wndConnector = Apollo.LoadForm(self.xmlDoc, "ConnectorBar", wndConnectorLayer, self)
		
		nXOffset = wndConnector:GetWidth() / 2
		nYOffset = wndConnector:GetHeight() / 2
		
		nTranslatedCenterX = (nSocketRadius / 2) * math.cos(fRotation) + nCenterX
		nTranslatedCenterY = (nSocketRadius / 2) * math.sin(fRotation) + nCenterY
		
		wndConnector:SetAnchorOffsets(nTranslatedCenterX - nXOffset, nTranslatedCenterY - nYOffset, nTranslatedCenterX + nXOffset, nTranslatedCenterY + nYOffset)
		
		local fPixieRotation = math.atan((nTranslatedCenterY - nCenterY) / (nTranslatedCenterX - nCenterX)) + kfBaseRotation
		
		tPixieInfo = wndConnector:GetPixieInfo(1)
		tPixieInfo.fRotation = fPixieRotation
		wndConnector:UpdatePixie(1, tPixieInfo)	
		
		wndConnectorOn = wndConnector:FindChild("ConnectorBarFilled")
		tPixieInfo = wndConnectorOn:GetPixieInfo(1)
		tPixieInfo.fRotation = fPixieRotation
		wndConnectorOn:UpdatePixie(1, tPixieInfo)	
		
		-- Drawing Power Core nubs
		local wndNub = Apollo.LoadForm(self.xmlDoc, "ConnectorNub", wndSocketLayer, self)
		
		nTranslatedCenterX = (nNubRadius / 2) * math.cos(fRotation) + nCenterX
		nTranslatedCenterY = (nNubRadius / 2) * math.sin(fRotation) + nCenterY
		
		nXOffset = wndNub:GetWidth() / 2
		nYOffset = wndNub:GetHeight() / 2
		
		wndNub:SetAnchorOffsets(nTranslatedCenterX - nXOffset, nTranslatedCenterY - nYOffset, nTranslatedCenterX + nXOffset, nTranslatedCenterY + nYOffset)
		
		tPixieInfo = wndNub:GetPixieInfo(1)
		tPixieInfo.fRotation = fRotation - kfBaseRotation
		wndNub:UpdatePixie(1, tPixieInfo)
		
		self.arPowerLines[idx] =
		{
			arConnectors = 
			{
				wndEdge,
				wndConnector,
			},
			wndEnd = wndEndPoint,
			strColor = ""
		}
	end
end

function Crafting:CheckMaterials()
	local bHaveBagSpace = self.wndMain:FindChild("HiddenBagWindow"):GetTotalEmptyBagSlots() > 0	
	-- Verify materials if a craft hasn't been started yet
	if not self.wndMain then
		return
	end

	local wndBlockerNoStation = self.wndMain:FindChild("BlockerLayer:NoStationBlocker")
	-- universal schematics can also be crafted at a master craftsman.
	
	local bHasMaterials = true
	
	local tCurrentCraft = CraftingLib.GetCurrentCraft(self.tSocketInfo)
	
	-- if there isn't a crafting attempt already in progress...
	local bCurrentCraftStarted = tCurrentCraft and tCurrentCraft.nSchematicId == self.tSchematicInfo.nSchematicId

	if not bCurrentCraftStarted then
		-- Materials
		local wndBlockerMaterialsList = self.wndMain:FindChild("BlockerLayer:NoMaterialsBlocker:NoMaterialsList")
		wndBlockerMaterialsList:DestroyChildren()
		for idx, tData in pairs(self.tSchematicInfo.arMaterials) do
			if tData.nNeeded > tData.nOwned then
				bHasMaterials = false
			end

			local wndCurr = Apollo.LoadForm(self.xmlDoc, "RawMaterialsItem", wndBlockerMaterialsList, self)
			wndCurr:FindChild("RawMaterialsIcon"):SetSprite(tData.itemMaterial:GetIcon())
			wndCurr:FindChild("RawMaterialsIcon"):SetText(String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), tData.nOwned, tData.nNeeded))
			wndCurr:FindChild("RawMaterialsNotEnough"):Show(tData.nNeeded > tData.nOwned)
			Tooltip.GetItemTooltipForm(self, wndCurr, tData.itemMaterial, {bSelling = false})
		end

		-- PowerCores
		local tAvailableCores = CraftingLib.GetAvailablePowerCores(self.tSchematicInfo.nSchematicId)
		if tAvailableCores and not self.tSchematicInfo.bIsUniversal then -- Some crafts won't have power cores
			local nOwnedCount = 0
			for idx, itemCore in pairs(tAvailableCores) do
				nOwnedCount = nOwnedCount + itemCore:GetStackCount()
			end

			if nOwnedCount < 1 then
				bHasMaterials = false
			end

			local wndCurr = Apollo.LoadForm(self.xmlDoc, "RawMaterialsItem", wndBlockerMaterialsList, self)
			wndCurr:FindChild("RawMaterialsIcon"):SetSprite("Icon_CraftingIcon_powerCore_IconSprites_White_Icon")
			wndCurr:FindChild("RawMaterialsIcon"):SetText(String_GetWeaselString(Apollo.GetString("CRB_OutOfOne"), nOwnedCount))
			wndCurr:FindChild("RawMaterialsNotEnough"):Show(nOwnedCount < 1)

			wndCurr:SetTooltip(Apollo.GetString("CBCrafting_PowerCore"))
		end
		wndBlockerMaterialsList:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
	end
	
	local wndCraftButton = self.wndMain:FindChild("CraftButton")
	local wndCraftCost = wndCraftButton:FindChild("CashWindow")
	if not self.tSchematicInfo.bIsKnown and not self.tSchematicInfo.bIsOneUse then
		self.wndMain:FindChild("NotKnownBlocker"):Show(true)
		wndCraftButton:Show(false)
		self.wndMain:FindChild("TopRightText"):SetText(Apollo.GetString("CRB_Locked"))
	elseif not bHasMaterials and not self.wndMain:FindChild("PostCraftBlocker"):IsShown() then
		self.wndMain:FindChild("NoMaterialsBlocker"):Show(true)
		wndCraftButton:Show(false)
		self.wndMain:FindChild("TopRightText"):SetText(Apollo.GetString("CRB_Preview"))
	elseif not bCurrentCraftStarted then
		local wndPreviewBlocker = self.wndMain:FindChild("PreviewOnlyBlocker")
		local wndStartCraftBtn = wndPreviewBlocker:FindChild("PreviewStartCraftBtn")
		wndPreviewBlocker:Show(true)
		
		if self.tSchematicInfo.monMaxCraftingCost then
			wndStartCraftBtn:FindChild("CashWindow"):Show(true)
			wndStartCraftBtn:FindChild("CashWindow"):SetAmount(self.tSchematicInfo.monMaxCraftingCost, true)
			
			if GameLib.GetPlayerCurrency():GetAmount() < self.tSchematicInfo.monMaxCraftingCost:GetAmount() then
				wndStartCraftBtn:FindChild("CashWindow"):SetTextColor("Reddish")
				wndCraftButton:Show(false)
				wndStartCraftBtn:Enable(false)
				wndStartCraftBtn:SetText(Apollo.GetString("GenericError_Mail_InsufficientFunds"))
			else
				wndStartCraftBtn:FindChild("CashWindow"):SetTextColor("white")
				wndStartCraftBtn:Enable(true)
				wndStartCraftBtn:SetText(Apollo.GetString("Crafting_BeginCrafting"))

			end
		else
			wndStartCraftBtn:FindChild("CashWindow"):Show(false)
			wndStartCraftBtn:Enable(true)
		end
		
		wndCraftButton:Enable(false)
		self.wndMain:FindChild("TopRightText"):SetText(Apollo.GetString("CRB_Preview"))
	elseif GameLib.GetPlayerCurrency():GetAmount() < wndCraftCost:GetAmount() then
		wndCraftCost:SetTextColor("UI_WindowTextRed")
		wndCraftButton:Enable(false)
	elseif not self.tSchematicInfo.bIsUniversal and not self.tSocketInfo.itemPowerCore or not tCurrentCraft.tResult.bIsValidCraft then
		wndCraftButton:Enable(false)
		wndCraftButton:SetText(bHaveBagSpace and Apollo.GetString("Tradeskills_Craft") or Apollo.GetString("Crafting_NoInventorySpace"))
	else
		wndCraftCost:SetTextColor("white")
		wndCraftButton:Show(true)
		wndCraftButton:SetText(bHaveBagSpace and Apollo.GetString("Tradeskills_Craft") or Apollo.GetString("Crafting_NoInventorySpace"))
		wndCraftButton:Enable(bHaveBagSpace)
		self.wndMain:FindChild("TopRightText"):SetText(Apollo.GetString("CRB_Craft"))
	end
	
	if not CraftingLib.IsAtCraftingStation() and not (self.tSchematicInfo.bIsUniversal and CraftingLib.IsAtMasterCraftsman()) then
		wndBlockerNoStation:Show(true)
		self.wndMain:FindChild("BlockerLayer:PreviewOnlyBlocker"):Show(false)
		self.wndMain:FindChild("BlockerLayer:NoMaterialsBlocker"):Show(false)
		self.wndMain:FindChild("BlockerLayer:NotKnownBlocker"):Show(false)
		wndCraftButton:Show(false)
	end
	
	local wndPowerCore = self.wndMain:FindChild("SocketLayer:PowerCore")
	if self.tSchematicInfo.bIsUniversal then
		wndPowerCore:SetTooltip(Apollo.GetString("CBCrafting_DoesNotRequirePowerCore"))
	else
		wndPowerCore:SetTooltip("")
	end
	wndPowerCore:FindChild("PowerCorePickerBtn"):Enable(not self.tSchematicInfo.bIsUniversal)
end

function Crafting:OnStartCraftBtn(wndHandler, wndControl) -- PreviewStartCraftBtn, data is idSchematic
	idSchematic = wndHandler:GetData()
	local tCurrentCraft = CraftingLib.GetCurrentCraft()
	if not tCurrentCraft or tCurrentCraft.nSchematicId == 0 then -- Starts the crafting attempt if it isn't already started
		CraftingLib.CraftItem(idSchematic)
	end
	
	self.wndMain:FindChild("CraftButton"):Show(true)
end

function Crafting:InitCraftAttempt()
	if not self.wndMain or not self.wndMain:IsValid() or not self.wndMain:IsVisible() then
		return
	end

	local tCraftingInfo = CraftingLib.GetCurrentCraft(self.tSocketInfo)

	local wndSlider = self.wndMain:FindChild("ApSpScale:Slider")
	wndSlider:Show(tCraftingInfo ~= nil)
	if not tCraftingInfo then
		return
	end
	
	-- Draw Sockets
	local arSockets = self.wndMain:FindChild("SocketContainer"):GetChildren()

	for idx = 1, #tCraftingInfo.arStats do
		self:SetProperty(arSockets[idx], tCraftingInfo.arStats[idx], idx)
		
		self.arBaseCraftingGroups[idx] = tCraftingInfo.arStats[idx].eCraftingGroup
		arSockets[idx]:FindChild("ElementBorder"):SetSprite("sprCircuit_Ring_" .. ktElementToSpriteColor[tCraftingInfo.arStats[idx].eCraftingGroup])
	end

	-- Init Overcharge bars
	local wndOverchargeBar = self.wndMain:FindChild("OverchargeBar")
	wndOverchargeBar:SetFloor(0)
	wndOverchargeBar:SetMax(tCraftingInfo.tResult.nBudget)
	
	local wndFailBar = self.wndMain:FindChild("FailChargeFrame:FailChargeBar")
	wndFailBar:SetFloor(0)
	wndFailBar:SetMax(tCraftingInfo.tResult.nFailCap)
	
	-- Set up the AP/SP slider
	
	-- this works best as whole number increments, so we're starting at 0 and getting the 
	wndSlider:SetMinMax(0, tCraftingInfo.tSettings.nApSpSplitMaxDelta, 1)
	wndSlider:SetValue(0)
	
	self.tSocketInfo.nApSpSplitDelta = 0
	
	-- Draw the power core
	local bIsUniversal = CraftingLib.GetSchematicInfo(tCraftingInfo.nSchematicId).bIsUniversal
	if bIsUniversal then
		self:PowerCoreSelected(tCraftingInfo.itemPowerCore)
	end
	
	local wndCraftButton = self.wndMain:FindChild("CraftButton")
	if tCraftingInfo.itemPowerCore or bIsUniversal then
		wndCraftButton:Enable(true)
		self:UpdateStats()
	else
		wndCraftButton:Enable(false)
	end
	
	local wndCostWindow = wndCraftButton:FindChild("CashWindow")
	if tCraftingInfo.tResult.monCraftingCost then
		wndCostWindow:Show(true)
		wndCostWindow:SetAmount(tCraftingInfo.tResult.monCraftingCost, true)
	else
		wndCostWindow:Show(false)
	end
	
	self.wndMain:FindChild("PreviewOnlyBlocker"):Show(false)
	
	self:UpdatePreview()
	
	Event_ShowTutorial(GameLib.CodeEnumTutorial.CraftingSlotColor)
	Event_ShowTutorial(GameLib.CodeEnumTutorial.CraftingPowerCore)
end

--------------------------------------------------------------------------------------------
-- List Item Selection
--------------------------------------------------------------------------------------------
function Crafting:OnSocketListItem(wndHandler, wndControl)
	local oData = wndHandler:GetData()
	
	if Item.isData(oData) then
		self:PowerCoreSelected(oData)
	else
		self:PropertySelected(oData)
	end
end

--------------------------------------------------------------------------------------------
-- Power Core Selection and Filters
--------------------------------------------------------------------------------------------
function Crafting:BuildPowerCoreSelection(wndHandler, wndControl)
	self.wndSelection = Apollo.LoadForm(self.xmlDoc, "SelectionWindow", self.wndMain, self)
	local wndContainer = self.wndSelection:FindChild("Container")
	local wndPropertyFilter = self.wndSelection:FindChild("PropertyFilter")
	local wndCoreFilter = self.wndSelection:FindChild("CoreFilter")
	
	self.wndSelection:SetData(wndHandler:GetParent())
	
	wndPropertyFilter:Show(false)
	wndCoreFilter:Show(true)
	
	local tDisplayedCores = {}
	local arCores = CraftingLib.GetAvailablePowerCores(self.tSchematicInfo.nSchematicId)
	for idx = 1, #arCores do
		if not tDisplayedCores[arCores[idx]:GetItemId()] then
			local wndCore = Apollo.LoadForm(self.xmlDoc, "SocketListItem", wndContainer, self)
			local luaSubclass = wndCore:FindChild("ListItemIcon"):GetWindowSubclass()
				
			luaSubclass:SetItem(arCores[idx])
			wndCore:SetText(arCores[idx]:GetName() .. "\n" .. String_GetWeaselString(Apollo.GetString("CBCrafting_PowerCoreLevel"), arCores[idx]:GetRequiredLevel(), arCores[idx]:GetPowerLevel()))
			wndCore:SetData(arCores[idx])
			
			tDisplayedCores[arCores[idx]:GetItemId()] = true
		end
	end
	
	local nContainerLeft, nContainerTop, nContainerRight, nContainerBottom = wndContainer:GetAnchorOffsets()
	wndContainer:SetAnchorOffsets(nContainerLeft, nContainerTop, nContainerRight, nContainerBottom + (wndPropertyFilter:GetHeight() - wndCoreFilter:GetHeight()))
	
	local nLeft, nTop, nRight, nBottom = wndHandler:GetParent():GetAnchorOffsets()
	local nPickerLeft, nPickerTop, nPickerRight, nPickerBottom = self.wndSelection:GetAnchorOffsets()
	local nLayerLeft = self.wndMain:FindChild("SocketLayer"):GetAnchorOffsets()
	self.wndSelection:SetAnchorOffsets(nRight + nLayerLeft, nPickerTop, nRight + self.wndSelection:GetWidth() + nLayerLeft, nPickerBottom)
	
	self:SortPowerCores(wndContainer)
end

function Crafting:OnCoreStringSearch(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndContainer = wndHandler:GetParent():GetParent():FindChild("Container")
	local strFilter = wndHandler:GetText()

	for idx, wndCore in pairs(#wndContainer:GetChildren()) do
		wndCore:Show(string.find(string.lower(strFilter), string.lower(wndCore:GetText())))
	end
	
	self:SortPowerCores(wndContainer)
end

function Crafting:SortPowerCores(wndContainer)
	if #wndContainer:GetChildren() > 1 then
		wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:GetData():GetRequiredLevel() < b:GetData():GetRequiredLevel() end)
	end
end

function Crafting:PowerCoreSelected(itemPowerCore)
	local wndPowerCore = self.wndMain:FindChild("SocketLayer:PowerCore")
	local wndButton = wndPowerCore:FindChild("PowerCorePickerBtn")

	if itemPowerCore then
		wndButton:SetCheck(false)
		wndButton:ChangeArt(ktPowerCoreColors[itemPowerCore:GetItemQuality()])
	
		local wndIcon = wndPowerCore:FindChild("PowerCoreIcon")
		wndIcon:SetTooltipDoc(nil)
		wndIcon:SetSprite(itemPowerCore:GetIcon())
		Tooltip.GetItemTooltipForm(self.wndMain, wndIcon, itemPowerCore, {})

		self.tSocketInfo.itemPowerCore = itemPowerCore
	end
	if self.wndSelection then
		self.wndSelection:Destroy()
		self.wndSelection = nil
	end
	
	self.wndMain:FindChild("ApSpScale"):Show(true)
	for idx = 1, #self.arPowerLines do
		for nConnectorIdx = 1, #self.arPowerLines[idx].arConnectors do
			self.arPowerLines[idx].arConnectors[nConnectorIdx]:FindChild("ConnectorBarFilled"):Show(true)
		end
		
		local tPixieInfo = self.arPowerLines[idx].wndEnd:GetPixieInfo(2)
		tPixieInfo.strSprite = "sprCircuit_Terminal_" .. self.arPowerLines[idx].strColor
		self.arPowerLines[idx].wndEnd:UpdatePixie(2, tPixieInfo)
	end
	
	local arSockets = self.wndMain:FindChild("SocketContainer"):GetChildren()
	for idx, wndSocket in pairs(arSockets) do
		wndSocket:FindChild("CircuitPickerSmallLeft"):Enable(true)
		wndSocket:FindChild("CircuitPickerSmallRight"):Enable(true)
	end
	
	self:UpdateStats()
	self:CheckMaterials()
	
	Event_ShowTutorial(GameLib.CodeEnumTutorial.CraftingSlotCharge)
	Event_ShowTutorial(GameLib.CodeEnumTutorial.CraftingApSp)
	Event_FireGenericEvent("Tutorial_HideCallout", GameLib.CodeEnumTutorialAnchor.CraftingSlotColor)
	Event_FireGenericEvent("Tutorial_HideCallout", GameLib.CodeEnumTutorialAnchor.CraftingPowerCore)
end

--------------------------------------------------------------------------------------------
-- Stat Selection and Filters
--------------------------------------------------------------------------------------------
function Crafting:BuildPropertySelection(wndHandler, wndControl)
	self.wndSelection = Apollo.LoadForm(self.xmlDoc, "SelectionWindow", self.wndMain, self)
	local wndContainer = self.wndSelection:FindChild("Container")
	local nSocketNumber = wndHandler:GetData()
	
	-- Pass on the socket's parent so we know where to set the property
	self.wndSelection:SetData(wndHandler:GetParent():GetParent())
	
	self.wndSelection:FindChild("PropertyFilter"):Show(true)
	self.wndSelection:FindChild("CoreFilter"):Show(false)
	local bIsFusionSlot = self.arBaseCraftingGroups[nSocketNumber] == CraftingLib.CodeEnumItemCraftingGroupFlag.Fusion
	local arPropertyInfo = CraftingLib.GetAvailableProperties(self.tSchematicInfo.nSchematicId)
	for idx = 1, #arPropertyInfo do
		for nPropertyCount = 1, #arPropertyInfo[idx].arProperties do
			if bIsFusionSlot == (arPropertyInfo[idx].eCraftingGroup == CraftingLib.CodeEnumItemCraftingGroupFlag.Fusion) then
				local wndProperty = Apollo.LoadForm(self.xmlDoc, "SocketListItem", wndContainer, self)
				
				local tPropertyInfo =
				{
					eCraftingGroup = arPropertyInfo[idx].eCraftingGroup,
					eProperty = arPropertyInfo[idx].arProperties[nPropertyCount]
				}
				
				-- temp until we get sprites for properties
				wndProperty:FindChild("ListItemIcon"):SetSprite(karPropertyIcons[tPropertyInfo.eProperty])
				
				wndProperty:SetText(Item.GetPropertyName(tPropertyInfo.eProperty))
				wndProperty:SetData(tPropertyInfo)
				
				local bSelected = false
				
				-- 5 at most
				for nSocket, tPropertyData in pairs(self.tSocketInfo.arStats) do
					if tPropertyInfo.eProperty == self.tSocketInfo.arStats[nSocket].eProperty then
						bSelected = true
						break
					end
				end
				
				wndProperty:Enable(not bSelected)
			end
		end		
	end

	self:SortProperties()
	
	local nLeft, nTop, nRight, nBottom = wndHandler:GetParent():GetParent():GetAnchorOffsets()
	local nPickerLeft, nPickerTop, nPickerRight, nPickerBottom = self.wndSelection:GetAnchorOffsets()
	local nLayerLeft = self.wndMain:FindChild("SocketLayer"):GetAnchorOffsets()
	self.wndSelection:SetAnchorOffsets(nRight + nLayerLeft, nPickerTop, nRight + self.wndSelection:GetWidth() + nLayerLeft, nPickerBottom)
end

function Crafting:OnPropertyStringSearch(wndHandler, wndControl)
	for idx, wndProperty in pairs(self.wndSelection:FindChild("Container"):GetChildren()) do
		wndProperty:Show(string.find(string.lower(wndProperty:GetText()), string.lower(self.wndSelection:FindChild("PropertyFilter:EditBox"):GetText())))
	end
	
	self:SortProperties()
end

function Crafting:SortProperties()
	local wndContainer = self.wndSelection:FindChild("Container")
	local nSocketNumber = self.wndSelection:GetData():GetData()

	if #wndContainer:GetChildren() > 1 then
		function fnSortProperties(a,b)
			local tAData = a:GetData()
			local tBData = b:GetData()
			-- Sort alphabetically if the crafting groups match
			if tAData.eCraftingGroup == tBData.eCraftingGroup then
				return Item.GetPropertyName(tAData.eProperty) < Item.GetPropertyName(tBData.eProperty)
			-- Show matching sockets on top
			elseif tAData.eCraftingGroup == self.arBaseCraftingGroups[nSocketNumber] then
				return true
			elseif tBData.eCraftingGroup == self.arBaseCraftingGroups[nSocketNumber] then
				return false
			-- Sort by crafting group if all else fails.
			else
				return tAData.eCraftingGroup < tBData.eCraftingGroup
			end
		end
		
		wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, fnSortProperties)
	end
end

function Crafting:PropertySelected(tPropertyInfo)
	local wndSocket = self.wndSelection:GetData()
	local wndBtn = wndSocket:FindChild("CircuitPickerBtn")
	
	self.tSocketInfo.arStats[wndBtn:GetData()] = {nChargeDelta = 0, eProperty = tPropertyInfo.eProperty, eCraftingGroup = tPropertyInfo.eCraftingGroup}
	
	self:SetProperty(wndSocket, tPropertyInfo, wndBtn:GetData())
	
	wndBtn:SetCheck(false)
	
	self.wndSelection:Destroy()
	self.wndSelection = nil	
	self:UpdateStats()
end

function Crafting:SetProperty(wndSocket, tPropertyInfo, nIndex)
	self.tSocketInfo.arStats[nIndex] = {nChargeDelta = 0, eProperty = tPropertyInfo.eProperty, eCraftingGroup = tPropertyInfo.eCraftingGroup}
	
	wndSocket:FindChild("PropertyIcon"):SetSprite(karPropertyIcons[tPropertyInfo.eProperty])
	self.arPowerLines[nIndex].strColor = ktElementToSpriteColor[tPropertyInfo.eCraftingGroup]

	wndSocket:FindChild("CircuitPickerBtn"):ChangeArt("btnCircuit_Socket_" .. self.arPowerLines[nIndex].strColor)
	
	for idx = 1, #self.arPowerLines[nIndex].arConnectors do
		local wndFilledBar = self.arPowerLines[nIndex].arConnectors[idx]:FindChild("ConnectorBarFilled")
		local tPixieInfo = wndFilledBar:GetPixieInfo(1)
		
		tPixieInfo.strSprite = "sprCircuit_Laser_Vertical_" .. self.arPowerLines[nIndex].strColor
		wndFilledBar:UpdatePixie(1, tPixieInfo)
	end
	
	local tPixieInfo = self.arPowerLines[nIndex].wndEnd:GetPixieInfo(2)
	local strTerminalType = "Off"
	if self.tSocketInfo.itemPowerCore then
		strTerminalType = self.arPowerLines[nIndex].strColor
	end
	
	tPixieInfo.strSprite = "sprCircuit_Terminal_" .. strTerminalType
	self.arPowerLines[nIndex].wndEnd:UpdatePixie(2, tPixieInfo)

	self:UpdateStats()
end

--------------------------------------------------------------------------------------------
-- Charge Update
--------------------------------------------------------------------------------------------
function Crafting:OnSocketChargeUp(wndHandler, wndControl)
	local nSlotIdx = wndHandler:GetData()
	self.tSocketInfo.arStats[nSlotIdx].nChargeDelta = self.tSocketInfo.arStats[nSlotIdx].nChargeDelta + 1
	self:UpdateStats()
	Event_ShowTutorial(GameLib.CodeEnumTutorial.CraftingFailChance)
	Event_FireGenericEvent("Tutorial_HideCallout", GameLib.CodeEnumTutorialAnchor.CraftingSlotCharge)
end

function Crafting:OnSocketChargeDown(wndHandler, wndControl)
	local nSlotIdx = wndHandler:GetData()
	self.tSocketInfo.arStats[nSlotIdx].nChargeDelta = self.tSocketInfo.arStats[nSlotIdx].nChargeDelta - 1
	self:UpdateStats()
	Event_ShowTutorial(GameLib.CodeEnumTutorial.CraftingFailChance)
	Event_FireGenericEvent("Tutorial_HideCallout", GameLib.CodeEnumTutorialAnchor.CraftingSlotCharge)
end

--------------------------------------------------------------------------------------------
-- Update Functions
--------------------------------------------------------------------------------------------
function Crafting:UpdateStats()
	local tCraftingInfo = CraftingLib.GetCurrentCraft(self.tSocketInfo)
	
	if not tCraftingInfo or not (self.tSocketInfo.itemPowerCore or CraftingLib.GetSchematicInfo(tCraftingInfo.nSchematicId).bIsUniversal) then
		return
	end

	local arSockets = self.wndMain:FindChild("SocketContainer"):GetChildren()
	for idx = 1, #tCraftingInfo.arStats do
		if self.tSocketInfo.arStats[idx] then
			local wndChargeText = arSockets[idx]:FindChild("CircuitSocketChargeText")
			wndChargeText:SetText(math.floor((self.tSocketInfo.arStats[idx].nChargeDelta / tCraftingInfo.tSettings.nChargeMaxDelta) * 100) .. "%")
			wndChargeText:FindChild("CircuitPickerSmallLeft"):Enable(self.tSocketInfo.arStats[idx].nChargeDelta > -tCraftingInfo.tSettings.nChargeMaxDelta)
			wndChargeText:FindChild("CircuitPickerSmallRight"):Enable(self.tSocketInfo.arStats[idx].nChargeDelta < tCraftingInfo.tSettings.nChargeMaxDelta)
		end
	end
	
	self:UpdateOverchargeInfo()
	self:UpdatePreview()
end

function Crafting:UpdateOverchargeInfo()
	if not (self.tSocketInfo.itemPowerCore or CraftingLib.GetSchematicInfo(CraftingLib.GetCurrentCraft(self.tSocketInfo).nSchematicId).bIsUniversal) then
		return
	end
	
	local tCraftInfo = CraftingLib.GetCurrentCraft(self.tSocketInfo)
	local bOverFailCap = tCraftInfo.tResult.nFailChance >= tCraftInfo.tResult.nFailCap
	
	local wndOvercharge = self.wndMain:FindChild("OverchargeBar")
	wndOvercharge:SetMax(tCraftInfo.tResult.nBudget)
	wndOvercharge:SetProgress(tCraftInfo.tResult.fCraftedBudget)
	self.wndMain:FindChild("FailChargeBar"):SetProgress(tCraftInfo.tResult.nFailChance)
	self.wndMain:FindChild("FailChargeFrameFlair"):SetSprite(bOverFailCap and "sprCircuit_HandStopIcon" or "sprCircuit_CheckIcon")
	if bOverFailCap then
		strFailCap = String_GetWeaselString(Apollo.GetString("CBCrafting_ChanceToFailOver"), tCraftInfo.tResult.nFailCap)
		self.wndMain:FindChild("FailPercentText"):SetText(strFailCap)
		self.wndMain:FindChild("FailPercentText"):SetTextColor(ApolloColor.new("Reddish"))
	else 
		strFailChance = String_GetWeaselString(Apollo.GetString("CBCrafting_ChanceToFail"), tCraftInfo.tResult.nFailChance)
		self.wndMain:FindChild("FailPercentText"):SetText(strFailChance)
		self.wndMain:FindChild("FailPercentText"):SetTextColor(ApolloColor.new("DullYellow"))

	end
	
	local wndCraftBtn = self.wndMain:FindChild("CraftButton")
	local bHaveBagSpace = self.wndMain:FindChild("HiddenBagWindow"):GetTotalEmptyBagSlots() > 0	
	wndCraftBtn:Enable(tCraftInfo.tResult.bIsValidCraft and bHaveBagSpace)
	
	local strTooltip = ""
	if self.ePremiumSystem == AccountItemLib.CodeEnumPremiumSystem.Hybrid then
		strTooltip = String_GetWeaselString(Apollo.GetString("CBCrafting_PercentOverchargeRiskReduction"), tostring(tCraftInfo.tResult.nUnbuffedFailCap), tostring(tCraftInfo.tResult.nFailChanceBuff), tostring(tCraftInfo.tResult.nFailCap))
	end
	self.wndMain:FindChild("FailChargeFrame"):SetTooltip(bOverFailCap and Apollo.GetString("CBCrafting_TooMuchChargeError") or strTooltip)
end

function Crafting:UpdatePreview()
	local itemPreview = CraftingLib.GetPreviewInfo(self.tSchematicInfo.nSchematicId, self.tSocketInfo) or self.tSchematicInfo.itemOutput

	if itemPreview then
		self:HelperBuildTooltip(self.wndMain, self.wndMain:FindChild("TooltipHolder"), itemPreview)
	end
end

--------------------------------------------------------------------------------------------
-- Ap/Sp Slider
--------------------------------------------------------------------------------------------
function Crafting:OnApSpSliderChanged(wndHandler, wndControl)
	self.tSocketInfo.nApSpSplitDelta = wndHandler:GetValue()
	self:UpdateStats()
	Event_FireGenericEvent("Tutorial_HideCallout", GameLib.CodeEnumTutorialAnchor.CraftingApSp)
end

--------------------------------------------------------------------------------------------
-- Craft
--------------------------------------------------------------------------------------------
function Crafting:OnCraftBtnClicked(wndHandler, wndControl)
	local tCurrentCraft = CraftingLib.GetCurrentCraft()	
	local tCraftInfo = CraftingLib.GetPreviewInfo(self.tSchematicInfo.nSchematicId, self.tSocketInfo)

	-- Order is important, must clear first
	Event_FireGenericEvent("GenericEvent_ClearCraftSummary")

	-- Build summary screen list
	local strSummaryMsg = Apollo.GetString("CoordCrafting_LastCraftTooltip")
	for idx, tData in pairs(self.tSchematicInfo.arMaterials) do
		local itemCurr = tData.itemMaterial
		local tPluralName =
		{
			["name"] = itemCurr:GetName(),
			["count"] = tData.nNeeded
		}
		strSummaryMsg = strSummaryMsg .. "\n" .. String_GetWeaselString(Apollo.GetString("CoordCrafting_SummaryCount"), tPluralName)
	end
	Event_FireGenericEvent("GenericEvent_CraftSummaryMsg", strSummaryMsg)

	-- Craft
	CraftingLib.CompleteCraft(self.tSocketInfo)

	-- Post Craft Effects
	Event_FireGenericEvent("GenericEvent_StartCraftCastBar", self.wndMain:FindChild("BlockerLayer:PostCraftBlocker:CraftingSummaryContainer"), tCraftInfo.itemPreview)
	self.wndMain:FindChild("PostCraftBlocker"):Show(true)

	self.wndMain:FindChild("ApSpScale"):Show(false)
end

--------------------------------------------------------------------------------------------
-- Misc
--------------------------------------------------------------------------------------------
function Crafting:DestroySelectionWindow(wndHandler, wndControl)
	if not self.wndSelection then
		return
	end

	local wndBtn = self.wndSelection:GetData():FindChild("CircuitPickerBtn") or self.wndSelection:GetData():FindChild("PowerCorePickerBtn")
	
	if not wndBtn:ContainsMouse() then
		wndBtn:SetCheck(false)
	end
	
	self.wndSelection:Destroy()
	self.wndSelection = nil
end

function Crafting:OnCraftingInterrupted()
	if not self.wndMain then
		return
	end
	
	self.wndMain:FindChild("PostCraftBlocker"):Show(false)
	self.wndMain:FindChild("PostCraftBlocker"):FindChild("MouseBlocker"):Show(false)
end

function Crafting:OnOutOfRange()
	Event_CancelCrafting()
	Event_CancelMasterCraftsman()

	self:OnCloseBtn()
end

function Crafting:OnCloseBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	if self.wndMain and self.wndMain:IsValid() then
		local tCurrentCraft = CraftingLib.GetCurrentCraft()
		if tCurrentCraft and tCurrentCraft.nSchematicId ~= 0 then
			Event_FireGenericEvent("GenericEvent_LootChannelMessage", Apollo.GetString("CoordCrafting_CraftingInterrupted"))
		end
		Event_CancelMasterCraftsman()
		
		Event_FireGenericEvent("AlwaysShowTradeskills")
	end

	self:DestroyWindow()
end

function Crafting:DestroyWindow() -- Botch Craft calls this directly
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Close()
		self.wndMain = nil
		
		Apollo.RemoveEventHandler("CraftingUpdateCurrent", self)
		Apollo.RemoveEventHandler("UpdateInventory", self)
		Apollo.RemoveEventHandler("PlayerCurrencyChanged", self)
	end
end

function Crafting:OnP2PTradeExitAndReset()
	local tCurrentCraft = CraftingLib.GetCurrentCraft()
	if tCurrentCraft and tCurrentCraft.nSchematicId ~= 0 and self.wndMain and self.wndMain:IsValid() then
		self:DestroyWindow()
	end
end

-----------------------------------------------------------------------------------------------
-- Main Draw Method
-----------------------------------------------------------------------------------------------

function Crafting:OnThresholdRotateBtnCheck(wndHandler, wndControl)
	local nSocketValue = wndHandler:FindChild("RotateBall"):GetData()
	local nLayoutLoc = wndHandler:FindChild("RotateTestBtn"):GetData()
	self.nTEMPThresholdSelected[nLayoutLoc] = nSocketValue
end

function Crafting:OnSummaryClosed()
	if not self.wndMain then
		return
	end

	self.wndMain:FindChild("PostCraftBlocker"):Show(false)
	self:ResetCraft()
	
	if self.tSchematicInfo then
		self:OnGenericEvent_StartCircuitCraft(self.tSchematicInfo.nSchematicId)
	end
end

function Crafting:ResetCraft()
	if not self.wndMain then
		return
	end

	self.tSocketInfo = 
	{
		nApSpSplitDelta = 0,
		itemPowerCore = nil,
		arStats = {},
	}
	
	self.arBaseCraftingGroups = {}

	local arSockets = self.wndMain:FindChild("SocketLayer:SocketContainer"):GetChildren()
	for idx = 1, #arSockets do
		arSockets[idx]:FindChild("PropertyIcon"):SetSprite("")
		arSockets[idx]:FindChild("PropertyIcon"):SetText("")
	end
	
	for idx = 1, #self.arPowerLines do
		for nConnectorIndex = 1, #self.arPowerLines[idx].arConnectors do
			self.arPowerLines[idx].arConnectors[nConnectorIndex]:FindChild("ConnectorBarFilled"):Show(false)
		end
	end
	
	self.wndMain:FindChild("SocketLayer:PowerCore:PowerCoreIcon"):SetSprite("")
	self.wndMain:FindChild("SocketLayer:PowerCore:PowerCorePickerBtn"):ChangeArt("Crafting_CircuitSprites:btnCircuit_PowerCore_Empty")
end

-----------------------------------------------------------------------------------------------
-- Helper Functions
-----------------------------------------------------------------------------------------------
function Crafting:HelperBuildTooltip(wndOwner, wndParent, itemCurr )
	wndParent:DestroyChildren()

	-- Set up Flags. Unique flags are bInvisibleFrame and tModData.
	local tFlags = { bInvisibleFrame = true, bPermanent = true, wndParent = wndParent, bNotEquipped = true, bPrimary = true }

	local tResult = Tooltip.GetItemTooltipForm(wndOwner, wndParent, itemCurr, tFlags)
	local wndTooltip = nil
	if tResult then
		if type(tResult) == 'table' then
			wndTooltip = tResult[0]
		elseif type(tResult) == 'userdata' then
			wndTooltip = tResult
		end
	end

	if wndTooltip then
		local nLeft, nTop, nRight, nBottom = wndParent:GetAnchorOffsets()
		wndParent:SetAnchorOffsets(nLeft, nTop, nRight + wndTooltip:GetWidth(), nTop + wndTooltip:GetHeight())
	end
end

function Crafting:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors = 
	{
		[GameLib.CodeEnumTutorialAnchor.CraftingSlotColor] 	= true,
		[GameLib.CodeEnumTutorialAnchor.CraftingSlotCharge] = true,
		[GameLib.CodeEnumTutorialAnchor.CraftingPowerCore] 	= true,
		[GameLib.CodeEnumTutorialAnchor.CraftingFailChance] = true,
		[GameLib.CodeEnumTutorialAnchor.CraftingApSp] 		= true,
	}
	
	if not tAnchors[eAnchor] or not self.wndMain then 
		return
	end
	
	local tAnchorMapping =
	{
		[GameLib.CodeEnumTutorialAnchor.CraftingSlotColor] 	= self.wndMain:FindChild("SocketLayer:SocketContainer"):GetChildren()[1]:FindChild("CircuitContainer:PropertyIcon"),
		[GameLib.CodeEnumTutorialAnchor.CraftingSlotCharge] = self.wndMain:FindChild("SocketLayer:SocketContainer"):GetChildren()[1]:FindChild("CircuitSocketChargeText"),
		[GameLib.CodeEnumTutorialAnchor.CraftingPowerCore] 	= self.wndMain:FindChild("SocketLayer:PowerCore:PowerCoreIcon"),
		[GameLib.CodeEnumTutorialAnchor.CraftingFailChance] = self.wndMain:FindChild("FailChargeFrame:FailChargeBar"),
		[GameLib.CodeEnumTutorialAnchor.CraftingApSp] 		= self.wndMain:FindChild("ApSpScale:Background"),
	}
	
	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

local CraftingInst = Crafting:new()
CraftingInst:Init()