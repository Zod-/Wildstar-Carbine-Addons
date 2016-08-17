require "Window"
require "Unit"
require "GameLib"
require "Apollo"
require "PathMission"
require "P2PTrading"

local UnitFrames = {}
local TargetFrame = {}
local ClusterFrame = {}

local knMaxLevel					= 50
local knFrameWidthMax				= 358
local knFrameWidthShield			= 331
local knFrameWidthMin				= 297
local knCastBarPolyOffsetX1			= 50
local knCastBarPolyOffsetX2			= 80
local knCastBarPolyAngleDeltaX		= 142
local knClusterFrameWidth			= 60 -- MUST MATCH XML
local knClusterFrameHeight			= 62 -- MUST MATCH XML
local knHealthRed					= 0.3
local knHealthYellow				= 0.5

local kstrScalingHex				= "ffffbf80"
local kcrScalingCColor				= CColor.new(1.0, 191/255, 128/255, 0.7)

local karDispositionColors =
{
	[Unit.CodeEnumDisposition.Neutral]  = ApolloColor.new("DispositionNeutral"),
	[Unit.CodeEnumDisposition.Hostile]  = ApolloColor.new("DispositionHostile"),
	[Unit.CodeEnumDisposition.Friendly] = ApolloColor.new("DispositionFriendly"),
}

local ktDispositionToTTooltip =
{
	[Unit.CodeEnumDisposition.Neutral]  = Apollo.GetString("TargetFrame_NeutralTooltip"),
	[Unit.CodeEnumDisposition.Hostile]  = Apollo.GetString("TargetFrame_HostileTooltip"),
	[Unit.CodeEnumDisposition.Friendly] = Apollo.GetString("TargetFrame_FriendlyTooltip"),
}

local kstrRaidMarkerToSprite =
{
	"Icon_Windows_UI_CRB_Marker_Bomb",
	"Icon_Windows_UI_CRB_Marker_Ghost",
	"Icon_Windows_UI_CRB_Marker_Mask",
	"Icon_Windows_UI_CRB_Marker_Octopus",
	"Icon_Windows_UI_CRB_Marker_Pig",
	"Icon_Windows_UI_CRB_Marker_Chicken",
	"Icon_Windows_UI_CRB_Marker_Toaster",
	"Icon_Windows_UI_CRB_Marker_UFO",
}

local karFactionToString = --Used for the Attachment Frame Sprites
{
	[Unit.CodeEnumFaction.ExilesPlayer]		= "Exile",
	[171]									= "Exile", --Exile NPC's
	
	[Unit.CodeEnumFaction.DominionPlayer]	= "Dominion",
	[170]									= "Dominion", --Dominion NPC's
}

-- Todo: break these out onto options
local kcrGroupTextColor					= ApolloColor.new("BubbleTextShout")
local kcrFlaggedFriendlyTextColor 		= karDispositionColors[Unit.CodeEnumDisposition.Friendly]
local kcrDefaultGuildmemberTextColor 	= karDispositionColors[Unit.CodeEnumDisposition.Friendly]
local kcrHostileEnemyTextColor 			= karDispositionColors[Unit.CodeEnumDisposition.Hostile]
local kcrAggressiveEnemyTextColor 		= karDispositionColors[Unit.CodeEnumDisposition.Neutral]
local kcrNeutralEnemyTextColor 			= ApolloColor.new("UI_TextHoloBody")
local kcrDefaultUnflaggedAllyTextColor 	= karDispositionColors[Unit.CodeEnumDisposition.Friendly]

-- differential value, color, title, description, title color (for tooltip)
local karConInfo =
{
	{-4, ApolloColor.new("ConTrivial"), 	Apollo.GetString("TargetFrame_Trivial"), 	Apollo.GetString("TargetFrame_NoXP"), 				"ff7d7d7d"},
	{-3, ApolloColor.new("ConInferior"), 	Apollo.GetString("TargetFrame_Inferior"), 	Apollo.GetString("TargetFrame_VeryReducedXP"), 		"ff01ff07"},
	{-2, ApolloColor.new("ConMinor"), 		Apollo.GetString("TargetFrame_Minor"), 		Apollo.GetString("TargetFrame_ReducedXP"), 			"ff01fcff"},
	{-1, ApolloColor.new("ConEasy"), 		Apollo.GetString("TargetFrame_Easy"), 		Apollo.GetString("TargetFrame_SlightlyReducedXP"), 	"ff597cff"},
	{ 0, ApolloColor.new("ConAverage"), 	Apollo.GetString("TargetFrame_Average"), 	Apollo.GetString("TargetFrame_StandardXP"), 		"ffffffff"},
	{ 1, ApolloColor.new("ConModerate"), 	Apollo.GetString("TargetFrame_Moderate"), 	Apollo.GetString("TargetFrame_SlightlyMoreXP"), 		"ffffff00"},
	{ 2, ApolloColor.new("ConTough"), 		Apollo.GetString("TargetFrame_Tough"), 		Apollo.GetString("TargetFrame_IncreasedXP"), 		"ffff8000"},
	{ 3, ApolloColor.new("ConHard"), 		Apollo.GetString("TargetFrame_Hard"), 		Apollo.GetString("TargetFrame_HighlyIncreasedXP"), 	"ffff0000"},
	{ 4, ApolloColor.new("ConImpossible"), 	Apollo.GetString("TargetFrame_Impossible"), Apollo.GetString("TargetFrame_GreatlyIncreasedXP"),	"ffff00ff"}
}

local ktRankDescriptions =
{
	[Unit.CodeEnumRank.Fodder] 		= 	{Apollo.GetString("TargetFrame_Fodder"), 		Apollo.GetString("TargetFrame_VeryWeak")},
	[Unit.CodeEnumRank.Minion] 		= 	{Apollo.GetString("TargetFrame_Minion"), 		Apollo.GetString("TargetFrame_Weak")},
	[Unit.CodeEnumRank.Standard]	= 	{Apollo.GetString("TargetFrame_Grunt"), 		Apollo.GetString("TargetFrame_EasyAppend")},
	[Unit.CodeEnumRank.Champion] 	=	{Apollo.GetString("TargetFrame_Challenger"), 	Apollo.GetString("TargetFrame_AlmostEqual")},
	[Unit.CodeEnumRank.Superior] 	=  	{Apollo.GetString("TargetFrame_Superior"), 		Apollo.GetString("TargetFrame_Strong")},
	[Unit.CodeEnumRank.Elite] 		= 	{Apollo.GetString("TargetFrame_Prime"), 		Apollo.GetString("TargetFrame_VeryStrong")},
}

local karClassToIcon =
{
	[GameLib.CodeEnumClass.Warrior] 		= "IconSprites:Icon_Windows_UI_CRB_Warrior",
	[GameLib.CodeEnumClass.Engineer] 		= "IconSprites:Icon_Windows_UI_CRB_Engineer",
	[GameLib.CodeEnumClass.Esper] 			= "IconSprites:Icon_Windows_UI_CRB_Esper",
	[GameLib.CodeEnumClass.Medic] 			= "IconSprites:Icon_Windows_UI_CRB_Medic",
	[GameLib.CodeEnumClass.Stalker] 		= "IconSprites:Icon_Windows_UI_CRB_Stalker",
	[GameLib.CodeEnumClass.Spellslinger] 	= "IconSprites:Icon_Windows_UI_CRB_Spellslinger",
}

local kstrTooltipBodyColor 	= "ffc0c0c0"
local kstrTooltipTitleColor = "ffdadada"

local kstrFriendSprite 			= "ClientSprites:Icon_Windows_UI_CRB_Friend"
local kstrAccountFriendSprite 	= "ClientSprites:Icon_Windows_UI_CRB_Friend"
local kstrRivalSprite 			= "ClientSprites:Icon_Windows_UI_CRB_Rival"

local arRewardUpdateEvents =
{
	"QuestObjectiveUpdated", "QuestStateChanged", "ChallengeAbandon", "ChallengeLeftArea",
	"ChallengeFailTime", "ChallengeFailArea", "ChallengeActivate", "ChallengeCompleted",
	"ChallengeFailGeneric", "PublicEventObjectiveUpdate", "PublicEventUnitUpdate",
	"PlayerPathMissionUpdate", "FriendshipAdd", "FriendshipPostRemove", "FriendshipUpdate",
	"PlayerPathRefresh", "ContractObjectiveUpdated", "ContractStateChanged"
}

-- Variables shared between UnitFrames/TargetFrame/ClusterFrame
local kunitPlayer = nil
local kbUpdateRewardIcons = false

function UnitFrames:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	return o
end

function UnitFrames:Init()
	Apollo.RegisterAddon(self)
end

function UnitFrames:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("TargetFrame.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function UnitFrames:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterSlashCommand("focus", "OnFocusSlashCommand", self)
	
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", "OnTutorial_RequestUIAnchor", self)
	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterLoaded", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("AlternateTargetUnitChanged", "OnAlternateTargetUnitChanged", self)
	Apollo.RegisterEventHandler("NextFrame", "OnFrame", self)
	Apollo.RegisterEventHandler("OptionsUpdated_UnitFramesUpdated", "OnUnitFrameOptionsUpdated", self)
	
	self.timerFade = ApolloTimer.Create(0.5, true, "OnSlowUpdate", self)
	
	self:OnUnitFrameOptionsUpdated()
	
	for i, str in pairs(arRewardUpdateEvents) do
		Apollo.RegisterEventHandler(str, "RequestUpdateAllNameplateRewards", self)
	end

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()
end

function UnitFrames:OnUnitFrameOptionsUpdated()
	if self.luaUnitFrame and self.luaUnitFrame.wndMainClusterFrame then
		self.luaUnitFrame.wndMainClusterFrame:Destroy()
	end
	
	if self.luaTargetFrame and self.luaTargetFrame.wndMainClusterFrame then
		self.luaTargetFrame.wndMainClusterFrame:Destroy()
	end
	
	if self.luaFocusFrame and self.luaFocusFrame.wndMainClusterFrame then
		self.luaFocusFrame.wndMainClusterFrame:Destroy()
	end

	self.luaUnitFrame = TargetFrame:new()
	self.luaTargetFrame = TargetFrame:new()
	self.luaFocusFrame = TargetFrame:new()
	
	local bMyUnitFrameFlipped = true 
	local bTargetFrameFlipped = false
	local bFocusFrameFlipped = false
	
	if g_InterfaceOptions ~= nil and g_InterfaceOptions.Carbine.bMyUnitFrameFlipped ~= nil then
		bMyUnitFrameFlipped = g_InterfaceOptions.Carbine.bMyUnitFrameFlipped
	end
	
	if g_InterfaceOptions ~= nil and g_InterfaceOptions.Carbine.bTargetFrameFlipped ~= nil then
		bTargetFrameFlipped = g_InterfaceOptions.Carbine.bTargetFrameFlipped
	end
	
	if g_InterfaceOptions ~= nil and g_InterfaceOptions.Carbine.bFocusFrameFlipped ~= nil then
		bFocusFrameFlipped = g_InterfaceOptions.Carbine.bFocusFrameFlipped
	end
	
	self.luaFocusFrame:Init(self.xmlDoc, 	{fScale=1.0, bFlipped=bFocusFrameFlipped, nConsoleVar="hud.focusTargetFrameDisplay", bDrawClusters=false})
	self.luaTargetFrame:Init(self.xmlDoc, {fScale=1.0, bFlipped=bTargetFrameFlipped, bFlipClusters=true})
	self.luaUnitFrame:Init(self.xmlDoc, 	{fScale=1.0, bFlipped=bMyUnitFrameFlipped, nConsoleVar="hud.myUnitFrameDisplay", bDrawToT=false})
	
	-- setup default positions
	self.luaUnitFrame.locDefaultPosition = WindowLocation.new({fPoints = {0.24, 1, 0.24, 1}, nOffsets = {0,-324,358,-220}})
	self.luaTargetFrame.locDefaultPosition = WindowLocation.new({fPoints = {0.76, 1, 0.76, 1}, nOffsets = {-358,-324,0,-220}})
	self.luaFocusFrame.locDefaultPosition = WindowLocation.new({fPoints = {0, 0.5, 0, 0.5}, nOffsets = {30,-22,388,82}})	
	
	self.luaUnitFrame:SetPosition(self.luaUnitFrame.locDefaultPosition)
	self.luaTargetFrame:SetPosition(self.luaTargetFrame.locDefaultPosition)
	self.luaFocusFrame:SetPosition(self.luaFocusFrame.locDefaultPosition)
	
	self:OnWindowManagementReady()
end

function UnitFrames:RequestUpdateAllNameplateRewards()
	kbUpdateRewardIcons = true
end

function UnitFrames:OnFrame()
	kunitPlayer = GameLib.GetPlayerUnit()
	
	if kunitPlayer ~= nil then
		self.unitTarget = kunitPlayer:GetTarget()
		self.altPlayerTarget = kunitPlayer:GetAlternateTarget()
	end
	
	if kunitPlayer ~= self.luaUnitFrame.unitTarget then
		self.luaUnitFrame:SetTarget(kunitPlayer)
	end
	
	if self.unitTarget ~= self.luaTargetFrame.unitTarget then
		self.luaTargetFrame:SetTarget(self.unitTarget)
	end
	
	if self.altPlayerTarget ~= self.luaFocusFrame.unitTarget then
		self.luaFocusFrame:SetTarget(self.altPlayerTarget)
	end
	
	self.luaUnitFrame:OnFrame()
	self.luaTargetFrame:OnFrame()
	self.luaFocusFrame:OnFrame()
end

function UnitFrames:OnSlowUpdate()
	self.luaUnitFrame:OnSlowUpdate()
	self.luaTargetFrame:OnSlowUpdate()
	self.luaFocusFrame:OnSlowUpdate()
end

function UnitFrames:OnCharacterLoaded()
	kunitPlayer = GameLib.GetPlayerUnit()
	
	if kunitPlayer ~= nil then
		local unitTarget = kunitPlayer:GetTarget()
		local altPlayerTarget = kunitPlayer:GetAlternateTarget()
	
		self.luaUnitFrame:SetTarget(kunitPlayer)
		self.luaTargetFrame:SetTarget(unitTarget)
		self.luaFocusFrame:SetTarget(altPlayerTarget)
	end
end

function UnitFrames:OnTargetUnitChanged(unitTarget)
	--self.luaTargetFrame:SetTarget(unitTarget)
end

function UnitFrames:OnAlternateTargetUnitChanged(unitTarget)
	--self.luaFocusFrame:SetTarget(unitTarget)
end

function UnitFrames:OnFocusSlashCommand()
	kunitPlayer:SetAlternateTarget(GameLib.GetTargetUnit())
end

function UnitFrames:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("OptionsHUD_MyUnitFrameLabel"), nSaveVersion=2})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.luaUnitFrame.wndMainClusterFrame,	strName = Apollo.GetString("OptionsHUD_MyUnitFrameLabel"), nSaveVersion=2})
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("OptionsHUD_TargetFrameLabel"), nSaveVersion=2})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.luaTargetFrame.wndMainClusterFrame, strName = Apollo.GetString("OptionsHUD_TargetFrameLabel"), nSaveVersion=2})
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("OptionsHUD_FocusTargetLabel"), nSaveVersion=2})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.luaFocusFrame.wndMainClusterFrame, strName = Apollo.GetString("OptionsHUD_FocusTargetLabel"), nSaveVersion=2})
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------
function UnitFrames:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)

	local tAnchors = 
	{
		[GameLib.CodeEnumTutorialAnchor.HealthBar] 		= true,
	    [GameLib.CodeEnumTutorialAnchor.InterruptArmor] = true,
		[GameLib.CodeEnumTutorialAnchor.BuffFrame] 		= true,
		[GameLib.CodeEnumTutorialAnchor.ShieldBar]		= true,
	}
	
	if not tAnchors[eAnchor] then
		return
	end
	
	local tAnchorMapping = 
	{
		[GameLib.CodeEnumTutorialAnchor.HealthBar] 		= self.luaUnitFrame.wndLargeFrame:FindChild("LargeBarContainer:MaxHealth"),
		[GameLib.CodeEnumTutorialAnchor.InterruptArmor] = self.luaTargetFrame.wndCCArmor,
		[GameLib.CodeEnumTutorialAnchor.BuffFrame] 		= self.luaUnitFrame.wndLargeFrame:FindChild("BuffTutorialAnchor"),
		[GameLib.CodeEnumTutorialAnchor.ShieldBar]		= self.luaUnitFrame.wndMaxShield
	}

	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

function TargetFrame:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function TargetFrame:Init(xmlDoc, tParams)		
	Apollo.RegisterEventHandler("KeyBindingKeyChanged", 			"OnKeyBindingUpdated", self)
	
	self.tParams = {
		fScale 			= tParams.fScale or 1,
		nConsoleVar		= tParams.nConsoleVar,
		bDrawClusters 	= tParams.bDrawClusters == nil and true or tParams.bDrawClusters,
		bDrawToT 		= tParams.bDrawToT == nil and true or tParams.bDrawToT,
		bFlipped		= tParams.bFlipped == nil and false or tParams.bFlipped,
		bFlipClusters 	= tParams.bFlipClusters == nil and false or tParams.bFlipClusters,
	}
	
	local strFlipped = self.tParams.bFlipped and "Flipped" or ""
	self.sprHealthFillVulernable = "spr_TargetFrame_HealthFillVulernable" .. strFlipped
	self.sprHealthFillRed = "spr_TargetFrame_HealthFillRed" .. strFlipped
	self.sprHealthFillYellow = "spr_TargetFrame_HealthFillYellow" .. strFlipped
	self.sprHealthFillGreen = "spr_TargetFrame_HealthFillGreen" .. strFlipped
	
	self.wndMainClusterFrame = Apollo.LoadForm(xmlDoc, tParams.bFlipped and "ClusterTargetFlipped" or "ClusterTarget", "FixedHudStratumLow", self)
	self.arClusterFrames =
	{
		ClusterFrame:new(),
		ClusterFrame:new(),
		ClusterFrame:new(),
		ClusterFrame:new()
	}
	
	for idx = 1, #self.arClusterFrames do
		self.arClusterFrames[idx]:Init(xmlDoc, self.wndMainClusterFrame:FindChild("Clusters"))
	end
	
	self.wndMainClusterFrame:SetScale(self.tParams.fScale)
	self.wndLargeFrame = self.wndMainClusterFrame:FindChild("LargeFrame")
	
	-- Get main references
	self.wndHealthText = self.wndLargeFrame:FindChild("HealthText")
	self.wndMaxShield = self.wndLargeFrame:FindChild("MaxShield")
	self.wndMaxAbsorb = self.wndLargeFrame:FindChild("MaxAbsorb")
	self.wndHealthSplit = self.wndLargeFrame:FindChild("HealthSplit")
	self.wndHealthCapacityTint = self.wndLargeFrame:FindChild("HealthCapacityTint")
	self.wndHealingAbsorbCapacityTint = self.wndLargeFrame:FindChild("HealingAbsorbCapacityTint")
	self.wndHealthClampMin = self.wndLargeFrame:FindChild("HealthClampMin")
	self.wndHealthClampMax = self.wndLargeFrame:FindChild("HealthClampMax")
	self.wndShieldCapacityTint = self.wndLargeFrame:FindChild("ShieldCapacityTint")
	self.wndAbsorbCapacityTint = self.wndLargeFrame:FindChild("AbsorbCapacityTint")
	self.wndTargetModel = self.wndLargeFrame:FindChild("TargetModel")
	self.wndTargetLevel = self.wndLargeFrame:FindChild("TargetLevel")
	self.wndTargetScalingMark = self.wndLargeFrame:FindChild("TargetScalingMark")
	self.wndGroupSizeIcon = self.wndLargeFrame:FindChild("GroupSizeIcon")
	self.wndGroupSizeMark = self.wndLargeFrame:FindChild("GroupSizeMark")
	self.wndTargetGoalPanel = self.wndLargeFrame:FindChild("TargetGoalPanel")
	self.wndRaidMarker = self.wndLargeFrame:FindChild("RaidMarker")
	self.wndTargetName = self.wndLargeFrame:FindChild("TargetName")
	self.wndRare = self.wndLargeFrame:FindChild("Rare")
	self.wndElite = self.wndLargeFrame:FindChild("Elite")
	self.wndCCArmor = self.wndLargeFrame:FindChild("CCArmor")
	self.wndBeneBuffBar = self.wndLargeFrame:FindChild("BeneBuffBar")
	self.wndHarmBuffBar = self.wndLargeFrame:FindChild("HarmBuffBar")
	self.wndPlayerIconShadow = self.wndLargeFrame:FindChild("PlayerIconShadow")
	self.wndPlayerClassIcon = self.wndLargeFrame:FindChild("PlayerClassIcon")
	self.wndCertainDeathIcon = self.wndLargeFrame:FindChild("CertainDeathIcon")
	self.wndAttachment = self.wndLargeFrame:FindChild("Attachment")
	self.wndBacker = self.wndLargeFrame:FindChild("Backer")
	self.wndClusters = self.wndLargeFrame:FindChild("Clusters")
	self.wndCastingBar = self.wndLargeFrame:FindChild("CastingBar")
	self.wndCastingFrame = self.wndLargeFrame:FindChild("CastingFrame")
	self.wndCastingName = self.wndLargeFrame:FindChild("CastingName")
	self.wndCastingIcon = self.wndLargeFrame:FindChild("CastingIcon")
	self.wndCastingBase = self.wndLargeFrame:FindChild("CastingBase")
	self.wndPVPIcon = self.wndLargeFrame:FindChild("PVPIcon")
	
	-- Get target of target references
	self.wndToTFrame = self.wndMainClusterFrame:FindChild("TotFrame")
	self.wndToTBacker = self.wndToTFrame:FindChild("Backer")
	self.wndToTDispositionFrame = self.wndToTFrame:FindChild("DispositionFrame")
	self.wndToTFrame:Show(false)
	
	self:ArrangeClusterMembers()
	self.wndMainClusterFrame:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)

	self.wndSimpleFrame = Apollo.LoadForm(xmlDoc, "SimpleTargetFrame", "FixedHudStratum", self)
	self.wndSimpleFrame:Show(false)

	self.nLFrameLeft, self.nLFrameTop, self.nLFrameRight, self.nLFrameBottom = self.wndLargeFrame:GetAnchorOffsets()
	self.arShieldPos = self.wndMaxShield:GetLocation()
	self.arAbsorbPos = self.wndMaxAbsorb:GetLocation()

	-- We apparently resize bars rather than set progress
	self:SetBarValue(self.wndShieldCapacityTint, 0, 100, 100)

	self.strPathActionKeybind = GameLib.GetKeyBinding("PathAction")
	self.bPathActionUsesIcon = false
	if self.strPathActionKeybind == "Unbound" or #self.strPathActionKeybind > 1 then -- Don't show interact
		self.bPathActionUsesIcon = true
	end

	self.strQuestActionKeybind = GameLib.GetKeyBinding("CastObjectiveAbility")
	self.bQuestActionUsesIcon = false
	if self.strQuestActionKeybind == "Unbound" or #self.strQuestActionKeybind > 1 then -- Don't show interact
		self.bQuestActionUsesIcon = true
	end

	self.nRaidMarkerLeft, self.nRaidMarkerTop, self.nRaidMarkerRight, self.nRaidMarkerBottom = self.wndRaidMarker:GetAnchorOffsets()

	self.nLastCCArmorValue = 0
	self.unitLastTarget = nil
	self.bTargetDead = false
end

function TargetFrame:OnFrame()
	self:OnUpdate()
end

function TargetFrame:OnUpdate()
	local bTargetChanged = false
	local unitTarget = self.unitTarget
	local unitPlayer = kunitPlayer
	local bShowWindow = true
	local tCluster = nil
	
	if self.unitLastTarget ~= nil and not self.unitLastTarget:IsValid() then
		self.unitLastTarget = nil
	end
	if self.unitLastTarget == nil then
		if unitTarget == nil then
			self.wndMainClusterFrame:Show(false)
			return
		end
		bTargetChanged = true
		self:HelperResetTooltips() -- these get redrawn with the unitToT info
	end

	if unitTarget ~= nil and self.unitLastTarget ~= unitTarget then
		self.unitLastTarget = unitTarget
		bTargetChanged = true
		self:HelperResetTooltips() -- these get redrawn with the unitToT info
	end
	
	if unitTarget ~= nil then
		if self.tParams.bDrawClusters ~= true then
			-- Cluster info
			tCluster = unitTarget:GetClusterUnits()
			
			if unitTarget == unitPlayer then
				--Treat Mount as a Cluster Target
				if unitPlayer:IsMounted() then
					table.insert(tCluster, unitPlayer:GetUnitMount())
				end
				
				--Treat Scanbot as a Cluster Target
				if PlayerPathLib.ScientistHasScanBot() then
					table.insert(tCluster, PlayerPathLib.ScientistGetScanBotUnit())
				end
			end
			
			--Make the unit a cluster of a vehicle if they're in one.
			if unitTarget:IsInVehicle() then
				local uPlayer = unitTarget
				unitTarget = uPlayer:GetVehicle()
				
				table.insert(tCluster, uPlayer)
			end
			
			-- Treat Pets as Cluster Targets
			if unitTarget == unitPlayer then
				local tPlayerPets = GameLib.GetPlayerPets()	
				for k,v in ipairs(tPlayerPets) do
					if k < 3 and v:GetHealth() == 0 then
						table.insert(tCluster, v)
					end
				end
			end
			
			if tCluster == nil or #tCluster < 1 then
				tCluster = nil
			end
		end

		-- Primary frame
		if unitTarget:GetHealth() ~= nil and unitTarget:GetMaxHealth() > 0 then
			self:UpdatePrimaryFrame(unitTarget, bTargetChanged)
		elseif Apollo.StringLength(unitTarget:GetName()) > 0 then
			bShowWindow = false
		end
	else
		bShowWindow = false
		self.wndSimpleFrame:Show(false)
		self.wndMainClusterFrame:Show(false)
		self:HideClusterFrames()
		return
	end
	
	if bShowWindow and self.tParams.nConsoleVar ~= nil then
		--Toggle Visibility based on ui preference
		local nVisibility = Apollo.GetConsoleVariable(self.tParams.nConsoleVar)
		
		local nCurrEffHP = unitTarget:GetHealth() + unitTarget:GetShieldCapacity()
		local nMaxEffHP = unitTarget:GetMaxHealth() + unitTarget:GetShieldCapacityMax()
		
		if nVisibility == 2 then --always off
			bShowWindow = false
		elseif nVisibility == 3 then --on in combat
			bShowWindow = unitPlayer:IsInCombat() or nCurrEffHP < nMaxEffHP
		elseif nVisibility == 4 then --on out of combat
			bShowWindow = not unitPlayer:IsInCombat()
		elseif nVisibility == 5 then --on with a target (unit frame symmetry)
			bShowWindow = unitPlayer:GetTarget()  and unitPlayer:GetTarget():GetHealth() ~= nil or nCurrEffHP < nMaxEffHP
		else
			bShowWindow = true
		end
	end
	
	if bShowWindow and tCluster ~= nil and #tCluster > 0 then
		self:UpdateClusterFrame(tCluster)
	else
		self:HideClusterFrames()
	end
	
	if bShowWindow ~= self.wndMainClusterFrame:IsShown() then
		self.wndMainClusterFrame:Show(bShowWindow)
	end
end

function TargetFrame:OnSlowUpdate()
	if self.unitTarget == nil or not self.unitTarget:IsValid() then
		return
	end
	
	
	local tDispositionSpriteLabel =
	{
		[Unit.CodeEnumDisposition.Unknown] = "Hostile",
		[Unit.CodeEnumDisposition.Hostile] = "Hostile",
		[Unit.CodeEnumDisposition.Neutral] = "Neutral",
		[Unit.CodeEnumDisposition.Friendly] = "Friendly",
	}

	local unitTarget = self.unitTarget
	
	local strFlipped = self.tParams.bFlipped and "Flipped" or ""
	
	
	local strTooltipRank = ""
	if unitTarget:GetType() == "Player" then
		strTooltipRank = Apollo.GetString("TargetFrame_IsPC")
	elseif ktRankDescriptions[unitTarget:GetRank()] ~= nil then
		strTooltipRank = String_GetWeaselString(Apollo.GetString("TargetFrame_CreatureRank"), ktRankDescriptions[unitTarget:GetRank()][1])
	end

	self.wndTargetModel:SetTooltip(unitTarget == kunitPlayer and "" or strTooltipRank)
	
	--Disposition/flags
	local eDisposition = unitTarget:GetDispositionTo(kunitPlayer) or Unit.CodeEnumDisposition.Hostile
	local strDisposition = tDispositionSpriteLabel[eDisposition]

	if eDisposition ~= self.eDisposition then
		self.wndTargetName:SetTextColor(karDispositionColors[eDisposition])
		
		--Rare and Elite NPCs
		if unitTarget:IsRare() then
			self.wndRare:SetSprite("spr_TargetFrame_Frame"..strDisposition.."Rare"..strFlipped)
		end
		if unitTarget:IsElite() then
			self.wndElite:SetSprite("spr_TargetFrame_Frame"..strDisposition.."Elite"..strFlipped)
		end
	end
	
	--Unit in Vehicle
	local strAttachment = ""
	if self.unitTarget:IsInVehicle() then
		strAttachment = "Vehicle"
	end
	
	--Iconic and Max Level Players
	local idArchetype = unitTarget:GetArchetype() and unitTarget:GetArchetype().idArchetype or 0
	local strFaction = karFactionToString[unitTarget:GetBaseFaction()] or ""
	local bPetClone =  unitTarget:GetUnitOwner() and unitTarget:GetType() == "Pet" and unitTarget:GetName() == unitTarget:GetUnitOwner():GetName() or false
	
	if not unitTarget:IsDead() and (idArchetype == Unit.CodeEnumArchetype.Iconic or ((unitTarget:GetType() == "Player" or bPetClone))) then
		if  unitTarget:GetLevel() == knMaxLevel then
			strAttachment = eDisposition == Unit.CodeEnumDisposition.Friendly and "FriendlyIconic" or "HostileIconic"
		else 
			strAttachment = eDisposition == Unit.CodeEnumDisposition.Friendly and "Friendly" or "Hostile"
		end
		strAttachment = strAttachment .. strFaction
	end
	
	self.wndAttachment:SetSprite("spr_TargetFrame_Frame"..strAttachment..strFlipped)
	self.wndHealthSplit:SetSprite("spr_TargetFrame_HealthSplit"..strDisposition..strFlipped)
	
	if (unitTarget:IsDead() or (unitTarget:IsTagged() and not unitTarget:IsTaggedByMe() and not unitTarget:IsSoftKill())) then
		self.wndBacker:SetSprite("spr_TargetFrame_FrameTapped"..strFlipped)
	else
		self.wndBacker:SetSprite("spr_TargetFrame_Frame"..strDisposition..strFlipped)
	end
	
	-- Name
	local strName = unitTarget:GetName()
	if unitTarget:IsPvpFlagged() then -- PvP
		strName = String_GetWeaselString(Apollo.GetString("BaseBar_PvPAppend"), strName)
	end
	self.wndTargetName:SetText(strName)

	if unitTarget:IsPvpFlagged() then
		local strSprite = "IconSprites:Icon_Windows16_UI_Player_PvPIndicator"
		if eDisposition == Unit.CodeEnumDisposition.Hostile  then
			strSprite = "IconSprites:Icon_Windows16_UI_Enemy_PvPIndicator"
		end
		self.wndPVPIcon:SetSprite(strSprite)

		if self.unitTarget == GameLib.GetPlayerUnit() then
			local nOpacity = 1.0
			local tPvPInfo = GameLib.GetPvpFlagInfo()
			if tPvPInfo.nCooldown > 0 then
				nOpacity = 0.5
			end
			self.wndPVPIcon:SetOpacity(nOpacity)
		end
		self.wndPVPIcon:Show(true)
	else
		self.wndPVPIcon:Show(false)
	end

	-- Level / Diff
	local nLevel = unitTarget:GetLevel()
	if nLevel == nil then
		if nLevel ~= self.nLevel then
			self.wndTargetLevel:SetText("")
			self.wndTargetLevel:SetTextColor(karConInfo[1][2])
			self.wndTargetLevel:SetTooltip("")
			self.nLevel = nLevel
		end
	else
		if nLevel ~= self.nLevel then
			self.wndTargetLevel:SetText(nLevel)
		end
		if unitTarget:IsScaled() then
			if not self.wndTargetScalingMark:IsShown() then
				self.wndTargetScalingMark:Show(true)
			end
			self.wndTargetLevel:SetTextColor(kcrScalingCColor)
			
			if unitTarget ~= kunitPlayer then
				if nLevel ~= self.nLevel then
					local strRewardFormatted = String_GetWeaselString(Apollo.GetString("TargetFrame_CreatureScales"), nLevel)
					local strLevelTooltip = self:HelperBuildTooltip(strRewardFormatted, Apollo.GetString("Adaptive"), kcrScalingHex)
					self.wndTargetLevel:SetTooltip(strLevelTooltip)
				end
			end
		else
			if self.wndTargetScalingMark:IsShown() then
				self.wndTargetScalingMark:Show(false)
			end
			local nCon = self:HelperCalculateConValue(unitTarget)
			self.wndTargetLevel:SetTextColor(karConInfo[nCon][2])
			
			if unitTarget ~= kunitPlayer then
				local strRewardFormatted = String_GetWeaselString(Apollo.GetString("TargetFrame_TargetXPReward"), karConInfo[nCon][4])
				local strLevelTooltip = self:HelperBuildTooltip(strRewardFormatted, karConInfo[nCon][3], karConInfo[nCon][5])
				self.wndTargetLevel:SetTooltip(strLevelTooltip)
			end
		end
		
		self.nLevel = nLevel
	end

	-- Color
	local strUnitType = self.strUnitType
	if strUnitType == "Player" or strUnitType == "Pet" or strUnitType == "Esper Pet" then
		local crColorToUse = karDispositionColors[eDisposition]
		local unitPlayer = unitTarget:GetUnitOwner() or unitTarget
		if eDisposition == Unit.CodeEnumDisposition.Friendly or unitPlayer:IsThePlayer() then
			if unitPlayer:IsPvpFlagged() then
				crColorToUse = kcrFlaggedFriendlyTextColor
			elseif unitPlayer:IsInYourGroup() then
				crColorToUse = kcrGroupTextColor
			else
				crColorToUse = kcrDefaultUnflaggedAllyTextColor
			end
		else
			local bIsUnitFlagged = unitPlayer:IsPvpFlagged()
			local bAmIFlagged = GameLib.IsPvpFlagged()
			if not bAmIFlagged and not bIsUnitFlagged then
				crColorToUse = kcrNeutralEnemyTextColor
			elseif (bAmIFlagged and not bIsUnitFlagged) or (not bAmIFlagged and bIsUnitFlagged) then
				crColorToUse = kcrAggressiveEnemyTextColor
			end
		end
		self.wndGroupSizeIcon:Show(false)
		self.wndGroupSizeMark:Show(false)
		self.nGroupValue = 0
		self.wndTargetName:SetTextColor(crColorToUse)

	else -- NPC
		local nGroupValue = unitTarget:GetGroupValue()
		if nGroupValue ~= self.nGroupValue then
			if (nGroupValue > 0) ~= self.wndGroupSizeMark:IsShown() then
				self.wndGroupSizeIcon:Show(nGroupValue > 0)
				self.wndGroupSizeMark:Show(nGroupValue > 0)
			else	
				self.wndGroupSizeIcon:Show(false)
				self.wndGroupSizeMark:Show(false)
			end
			self.wndGroupSizeMark:SetText(nGroupValue)

			local strGroupTooltip = self:HelperBuildTooltip(String_GetWeaselString(Apollo.GetString("TargetFrame_GroupSize"), nGroupValue), String_GetWeaselString(Apollo.GetString("TargetFrame_Man"), nGroupValue))
			self.wndGroupSizeMark:SetTooltip(strGroupTooltip)
			self.wndGroupSizeIcon:SetTooltip(strGroupTooltip)
			
			self.nGroupValue = nGroupValue
		end

		self.wndTargetName:SetTextColor(karDispositionColors[eDisposition])
	end
end

function TargetFrame:OnPVPIconGenerateTooltip(wndHandler, wndControl)
	if self.unitTarget == nil or not self.unitTarget:IsValid() or not self.unitTarget:IsPvpFlagged() or wndHandler ~= wndControl then
		return
	end

	local strTooltip = ""
	if self.unitTarget == GameLib.GetPlayerUnit() then
		local tPvPInfo = GameLib.GetPvpFlagInfo()
		strTooltip = string.format("<T TextColor=\"UI_WindowTextDefault\">%s</T>", Apollo.GetString("TargetFrame_PvPBonus"))
		if tPvPInfo.nCooldown > 0 then
			strTooltip = strTooltip .. "<P></P>" .. string.format("<T TextColor=\"UI_WindowTextDefault\">%s</T>", String_GetWeaselString(Apollo.GetString("TargetFrame_PvPCooldown"), ConvertSecondsToTimer(tPvPInfo.nCooldown, 0)))
		elseif not tPvPInfo.bIsForced then
			strTooltip = strTooltip .. "<P></P>" .. string.format("<T TextColor=\"Disabled\">%s</T>", Apollo.GetString("TargetFrame_PvPOff"))
		else
			strTooltip = strTooltip .. "<P></P>" .. string.format("<T TextColor=\"Disabled\">%s</T>", Apollo.GetString("TargetFrame_PvPForced"))
		end
	else
		strTooltip = Apollo.GetString("TargetFrame_PvPMarked")
	end
	wndControl:SetTooltip(strTooltip)
end

function TargetFrame:GetPosition()
	return self.wndMainClusterFrame:GetLocation()
end

function TargetFrame:SetPosition(locNewLocation)
	if locNewLocation == nil then
		return
	end
	
	self.wndMainClusterFrame:MoveToLocation(locNewLocation)
end

function TargetFrame:SetTarget(unitTarget)
	self.unitTarget = unitTarget	
	
	if unitTarget == nil or not unitTarget:IsValid() then
		if self.wndMainClusterFrame:IsShown() then
			self.wndMainClusterFrame:Show(false)
		end
		return
	end
	
	-- Misc
	self.strUnitType = unitTarget:GetType()
	
	-- Buff & debuff bars
	self.wndBeneBuffBar:SetUnit(unitTarget)
	self.wndHarmBuffBar:SetUnit(unitTarget)
	
	-- Rank & class
	local eRank = unitTarget:GetRank()
	local strPlayerIconSprite = ""
	
	-- Display Certain Death Icon
	local bShowCertainDeath = unitTarget:IsCertainDeath() 
		and not unitTarget:IsDead() 
		and unitTarget:GetHealth() 
		and unitTarget:GetDispositionTo(kunitPlayer) ~= Unit.CodeEnumDisposition.Friendly
	self.wndCertainDeathIcon:Show(bShowCertainDeath)
	
	-- Class Icon is based on player class or NPC rank
	if self.strUnitType == "Player" then
		self.wndPlayerIconShadow:Show(true)
		self.wndPlayerClassIcon:Show(true)
		self.wndPlayerClassIcon:SetSprite(karClassToIcon[unitTarget:GetClassId()])
	else
		self.wndPlayerIconShadow:Show(false)
		self.wndPlayerClassIcon:Show(false)
	end
	
	-- Rare and Elite NPCs
	local bRare = unitTarget:IsRare()
	if bRare ~= self.wndRare:IsShown() then
		self.wndRare:Show(bRare)
	end
	local bElite = unitTarget:IsElite()
	if bElite ~= self.wndElite:IsShown() then
		self.wndElite:Show(bElite)
	end
	
	self.wndTargetModel:SetCostume(unitTarget)
	self.wndTargetModel:SetData(unitTarget)
	self.wndLargeFrame:SetData(unitTarget)
end

-- todo: remove this, move functionality to draw or previous function, look about unhooking for movement
function TargetFrame:UpdatePrimaryFrame(unitTarget, bTargetChanged) --called from the onFrame; eliteness is frame, diff is rank
	self.wndSimpleFrame:Show(false)
	if unitTarget == nil then
		return
	end

	self:SetTargetForFrame(self.wndLargeFrame, bTargetChanged)

	self:UpdateCastingBar(self.wndLargeFrame)
	self:UpdateInterruptArmor()
	
	-- ToT
	local unitToT = unitTarget:GetTarget()
	local bValidToT = unitToT ~= nil and unitToT:GetHealth() ~= nil and unitToT:GetMaxHealth() > 0
	self.wndToTFrame:Show(self.tParams.bDrawToT and bValidToT)

	if self.wndToTFrame:IsShown() then
		self:UpdateToTFrame(unitToT)
	end
	
	if kbUpdateRewardIcons and RewardIcons ~= nil and RewardIcons.GetUnitRewardIconsForm ~= nil then
		RewardIcons.GetUnitRewardIconsForm(self.wndTargetGoalPanel, unitTarget, {bVert = false})
	end
	
	-- Raid Marker
	local wndRaidMarker = self.wndRaidMarker
	if wndRaidMarker then
		wndRaidMarker:SetSprite("")
		local nMarkerId = unitTarget and unitTarget:GetTargetMarker() or 0
		if unitTarget and nMarkerId ~= 0 then
			wndRaidMarker:SetSprite(kstrRaidMarkerToSprite[nMarkerId])
		end
	end
end

function TargetFrame:UpdateToTFrame(unitToT) -- called on frame
	if unitToT == nil then
		return
	end
	
	--Toggle Visibility based on ui preference
	local unitPlayer = kunitPlayer
	local nVisibility = Apollo.GetConsoleVariable("hud.TargetOfTargetFrameDisplay")
	
	local bShowToTFrame = false
	if nVisibility == 2 then --always off
		bShowToTFrame = false
	elseif nVisibility == 3 then --on in combat
		bShowToTFrame = unitPlayer:IsInCombat()	
	elseif nVisibility == 4 then --on out of combat
		bShowToTFrame = not unitPlayer:IsInCombat()
	else
		bShowToTFrame = true
	end
	
	if bShowToTFrame ~= self.wndToTFrame:IsShown() then
		self.wndToTFrame:Show(bShowToTFrame)
	end
	
	if not bShowToTFrame then
		-- no point in updating something our ui preferences told us not to display...
		return
	end

	self.wndToTFrame:SetData(unitToT)
	self.wndToTFrame:FindChild("TargetModel"):SetCostume(unitToT)
end

function TargetFrame:UpdateClusterFrame(tCluster) -- called on frame
	if self.unitTarget:IsDead() then
		self:HideClusterFrames()
		return
	end
	
	self:ArrangeClusterMembers()

	for idx = 1, #self.arClusterFrames do
		self.arClusterFrames[idx]:SetTarget(tCluster[idx])
		self.arClusterFrames[idx]:OnFrame()
	end
end

function TargetFrame:HideClusterFrames()
	for idx = 1, #self.arClusterFrames do
		self.arClusterFrames[idx]:SetTarget(nil)
	end
end

function TargetFrame:SetTargetForFrame(wndFrame, bTargetChanged)
	local unitTarget = self.unitTarget
	if unitTarget:IsInVehicle() then
		unitTarget = unitTarget:GetVehicle()
	end
	
	self:SetTargetHealthAndShields(wndFrame, unitTarget)
	
	if unitTarget then
		self:UpdateToT()
		
		
		-- Must be last as several sections above use eDisposition
		self.eDisposition = unitTarget:GetDispositionTo(kunitPlayer)
	end

	
end

function TargetFrame:UpdateToT()
	local unitToT = self.unitTarget:GetTarget()
	if unitToT ~= nil and unitToT:IsValid() then
		local eToTDisposition = unitToT:GetDispositionTo(kunitPlayer)
		
		if eToTDisposition ~= self.eToTDisposition then
			if eToTDisposition == Unit.CodeEnumDisposition.Hostile then
				self.wndToTBacker:SetSprite("spr_TargetFrame_ToTHostile")
				self.wndToTDispositionFrame:SetBGColor(ApolloColor.new("ffff6d66"))
			elseif eToTDisposition == Unit.CodeEnumDisposition.Neutral then
				self.wndToTBacker:SetSprite("spr_TargetFrame_ToTNeutral")
				self.wndToTDispositionFrame:SetBGColor(ApolloColor.new("fffaff66"))
			else
				self.wndToTBacker:SetSprite("spr_TargetFrame_ToTFriendly")
				self.wndToTDispositionFrame:SetBGColor(ApolloColor.new("ff00f7de"))
			end
			
			self.wndToTDispositionFrame:SetTooltip(ktDispositionToTTooltip[eToTDisposition])
		end
		self.eToTDisposition = eToTDisposition
	end
end

function TargetFrame:UpdateInterruptArmor()
	local nVulnerable = self.unitTarget:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability) or 0
	local nCCArmorValue = self.unitTarget:GetInterruptArmorValue()
	local nCCArmorMax = self.unitTarget:GetInterruptArmorMax()
	local wndCCArmor = self.wndCCArmor

	local bShow = false
	
	if nVulnerable > 0 then
		bShow = true
		
		if nVulnerable ~= self.nVulnerable then
			wndCCArmor:SetText("")
			wndCCArmor:SetSprite("spr_TargetFrame_InterruptArmor_MoO")
		end
		
		nCCArmorValue = -1
		nCCArmorMax = 0
	elseif nCCArmorMax == -1 then -- impervious
		bShow = true
		
		if nCCArmorMax ~= self.nCCArmorMax then
			wndCCArmor:SetText("")
			wndCCArmor:SetSprite("spr_TargetFrame_InterruptArmor_Infinite")
		end
		
		nCCArmorValue = -1
	elseif nCCArmorMax > 0 then -- has armor, has value
		bShow = nCCArmorValue > 0
		
		if nCCArmorValue ~= self.nCCArmorValue then
			wndCCArmor:SetText(nCCArmorValue)
		end
		
		if nCCArmorMax ~= self.nCCArmorMax then
			wndCCArmor:SetSprite("spr_TargetFrame_InterruptArmor_Value")
		end
	end
	
	if bShow ~= wndCCArmor:IsShown() then
		wndCCArmor:Show(bShow)
	end
	
	self.nVulnerable = nVulnerable
	self.nCCArmorMax = nCCArmorMax
	self.nCCArmorValue = nCCArmorValue
end

function TargetFrame:UpdateCastingBar(wndFrame)
	local unitCaster = self.unitTarget
	if unitCaster:IsInVehicle() then
		unitCaster = unitCaster:GetVehicle()
	end

	-- Casting Bar Update

	local bShowCasting = false
	local bEnableGlow = false
	local nZone = 0
	local nMaxZone = 0
	local nDuration = 0
	local nElapsed = 0
	local strSpellName = ""
	local nElapsed = 0
	local eType = Unit.CodeEnumCastBarType.None
	local strIcon = ""
	local strFillSprite = ""
	local strBaseSprite = ""
	local strGlowSprite = ""
	local strColor = ""
	local strFlipped = self.tParams.bFlipped and "Flipped" or ""
	
	local wndCastFrame = self.wndCastingFrame
	local wndCastProgress = self.wndCastingBar
	local wndCastName = self.wndCastingName
	local wndCastIcon = self.wndCastingIcon
	local wndCastBase = self.wndCastingBase
	
	local nVulnerable = unitCaster:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability) or 0
	if nVulnerable > 0 then
		nMaxZone = 1
		bShowCasting = true
		nElapsed = nVulnerable * 1000
		nDuration = 4000
		strSpellName = Apollo.GetString("Vulnerable")
		strColor = "magenta"
		strFillSprite = "spr_TargetFrame_FrameCastBarFillVulnerable"..strFlipped
		strBaseSprite = "spr_TargetFrame_FrameCastBarVulnerable"..strFlipped
		
		if wndCastProgress and wndCastProgress:IsValid() then
			-- add a countdown timer if nDuration is > 0.999 seconds.
			local strDuration = nDuration > 0999 and " (" .. string.format("%00.01f", nVulnerable)..")" or ""
			
			wndCastProgress:SetMax(nDuration)
			if math.abs(nElapsed - wndCastProgress:GetProgress()) > 100 then
				wndCastProgress:SetProgress(nElapsed) -- Bar is behind or reset and needs to be adjusted
			end
			
			wndCastProgress:SetProgress(0, 1000)
			wndCastProgress:EnableGlow(bEnableGlow)
			wndCastName:SetTextColor(strColor)
			wndCastName:SetText(strSpellName .. strDuration)
		end
		
	elseif unitCaster:ShouldShowCastBar() then
		-- results for GetCastBarType can be:
		-- Unit.CodeEnumCastBarType.None
		-- Unit.CodeEnumCastBarType.Normal
		-- Unit.CodeEnumCastBarType.Telegraph_Backlash
		-- Unit.CodeEnumCastBarType.Telegraph_Evade
		eType = unitCaster:GetCastBarType()

		if eType == Unit.CodeEnumCastBarType.Telegraph_Evade then
			strIcon = "CRB_TargetFrameSprites:sprTF_CastIconEvade"
		elseif eType == Unit.CodeEnumCastBarType.Telegraph_Backlash then
			strIcon = "CRB_TargetFrameSprites:sprTF_CastIconInterrupt"
		else
			strIcon = ""
		end

		if eType ~= Unit.CodeEnumCastBarType.None then
			local bInfiniteInteruptArmor =  unitCaster:GetInterruptArmorMax() == -1
			strColor = bInfiniteInteruptArmor and "CoolGrey" or "PastelOrange"
			strFillSprite = bInfiniteInteruptArmor and "spr_TargetFrame_FrameCastBarFillLocked"..strFlipped or "spr_TargetFrame_FrameCastBarFill"..strFlipped
			strBaseSprite = bInfiniteInteruptArmor and "spr_TargetFrame_FrameCastBarLocked"..strFlipped or "spr_TargetFrame_FrameCastBar"..strFlipped
			
			bShowCasting = true
			bEnableGlow = true
			nZone = 0
			nMaxZone = 1
			nDuration 		= unitCaster:GetCastDuration()
			nElapsed 		= unitCaster:GetCastElapsed()
			strSpellName 	= unitCaster:GetCastName()
			
			
			if wndCastProgress and wndCastProgress:IsValid() then
				-- add a countdown timer if nDuration is > 0.999 seconds.
				local strDuration = nDuration > 0999 and " (" .. string.format("%00.01f", (nDuration - nElapsed) / 1000)..")" or ""
				
				wndCastProgress:SetMax(nDuration)
				if math.abs(nElapsed - wndCastProgress:GetProgress()) > 100 then
					wndCastProgress:SetProgress(nElapsed) -- Bar is behind or reset and needs to be adjusted
				end
				
				wndCastProgress:SetProgress(nDuration, 1000)
				wndCastProgress:EnableGlow(bEnableGlow)
				wndCastName:SetTextColor(strColor)
				wndCastName:SetText(strSpellName .. strDuration)
			end
		end
	end

	wndCastFrame:Show(bShowCasting)
	if wndCastProgress and wndCastProgress:IsValid() then
		wndCastProgress:Show(bShowCasting)
		wndCastName:Show(bShowCasting)
	end

	if bShowCasting and nDuration > 0 and nMaxZone > 0 then
		wndCastIcon:SetSprite(strIcon)
		
		if wndCastProgress and wndCastProgress:IsValid() then		
			if self.strFillSprite ~= strFillSprite then
				wndCastProgress:SetFullSprite(strFillSprite)
			end
			
			if self.strBaseSprite ~= strBaseSprite then
				wndCastBase:SetSprite(strBaseSprite)
			end
			
			self.strFillSprite 	= strFillSprite
			self.strBaseSprite = strBaseSprite
			
			wndCastProgress:Show(true)
		end
	else
		if wndCastProgress and wndCastProgress:IsValid() then
			wndCastProgress:SetProgress(0)
		end
	end
end

-------------------------------------------------------------------------------
function TargetFrame:ArrangeClusterMembers()
	self.wndClusters:ArrangeChildrenHorz(self.tParams.bFlipClusters and Window.CodeEnumArrangeOrigin.RightOrBottom or Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function TargetFrame:HelperBuildTooltip(strBody, strTitle, crTitleColor)
	if strBody == nil then return end
	local strTooltip = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</T>", kstrTooltipBodyColor, strBody)
	if strTitle ~= nil then -- if a title has been passed, add it (optional)
		strTooltip = string.format("<P>%s</P>", strTooltip)
		local strTitle = string.format("<P Font=\"CRB_InterfaceMedium_B\" TextColor=\"%s\">%s</P>", crTitleColor or kstrTooltipTitleColor, strTitle)
		strTooltip = strTitle .. strTooltip
	end
	return strTooltip
end

function TargetFrame:HelperCalculateConValue(unitTarget)
	local nCon = 1 --default setting
	if not kunitPlayer:IsValid() then
		return nCon
	end
	
	local nUnitCon = kunitPlayer:GetLevelDifferential(unitTarget)
	if nUnitCon == nil then
		return nCon
	end

	if nUnitCon <= karConInfo[1][1] then -- lower bound
		nCon = 1
	elseif nUnitCon >= karConInfo[#karConInfo][1] then -- upper bound
		nCon = #karConInfo
	else
		for idx = 2, (#karConInfo-1) do -- everything in between
			if nUnitCon == karConInfo[idx][1] then
				nCon = idx
			end
		end
	end

	return nCon
end

function TargetFrame:HelperResetTooltips()
	self.wndTargetModel:SetTooltip("")
	self.wndTargetLevel:SetTooltip("")
	self.wndGroupSizeMark:SetTooltip("")
	self.wndGroupSizeIcon:SetTooltip("")
end

function TargetFrame:SetTargetHealthAndShields(wndTargetFrame, unitTarget)
	if not unitTarget or unitTarget:GetHealth() == nil then
		return
	end
	
	if unitTarget:GetType() == "Simple" then -- String Comparison, should replace with an enum
		self.wndHealthText:SetText("")
		self.wndMaxShield:Show(false)
		self.wndMaxAbsorb:Show(false)
		return
	end
	

	local nHealthCurr = unitTarget:GetHealth()
	local nHealthMax = unitTarget:GetMaxHealth()
	local nHealingAbsorbCurr = unitTarget:GetHealingAbsorptionValue()
	local nShieldCurr = unitTarget:GetShieldCapacity()
	local nShieldMax = unitTarget:GetShieldCapacityMax()
	local nAbsorbCurr = 0
	local nAbsorbMax = unitTarget:GetAbsorptionMax()
	if nAbsorbMax > 0 then
		nAbsorbCurr = unitTarget:GetAbsorptionValue() -- Since it doesn't clear when the buff drops off
	end
	local nHealthClampMin = unitTarget:GetHealthFloor()
	local nHealthClampMax = unitTarget:GetHealthCeiling()
	
	local nHealthTintType = 0
	
	if nHealthCurr / nHealthMax <= knHealthRed then
		nHealthTintType = 2
	elseif nHealthCurr / nHealthMax <= knHealthYellow then
		nHealthTintType = 1
	end
	
	if nHealthTintType ~= self.nHealthTintType then
		if nHealthTintType == 2 then
			self.wndHealthCapacityTint:SetFullSprite(self.sprHealthFillRed)
		elseif nHealthTintType == 1 then
			self.wndHealthCapacityTint:SetFullSprite(self.sprHealthFillYellow)
		else
			self.wndHealthCapacityTint:SetFullSprite(self.sprHealthFillGreen)
		end
		
		self.nHealthTintType = nHealthTintType
	end
	
	self.wndHealthCapacityTint:SetStyleEx("EdgeGlow", nHealthCurr > 0 and nHealthCurr / nHealthMax < 0.96)

	-- Bars
	self.wndHealthCapacityTint:SetMax(nHealthMax + nHealingAbsorbCurr)
	self.wndHealthCapacityTint:SetProgress(nHealthCurr)
	
	self.wndHealingAbsorbCapacityTint:SetMax(nHealthMax + nHealingAbsorbCurr)
	self.wndHealingAbsorbCapacityTint:SetProgress(nHealthCurr + nHealingAbsorbCurr)
	
	self.wndHealthClampMin:SetMax(nHealthMax + nHealingAbsorbCurr)
	self.wndHealthClampMin:SetProgress(nHealthClampMin)
	
	self.wndHealthClampMax:SetMax(nHealthMax + nHealingAbsorbCurr)
	self.wndHealthClampMax:SetProgress(nHealthClampMax)
	
	self.wndShieldCapacityTint:SetMax(nShieldMax)
	self.wndShieldCapacityTint:SetProgress(nShieldCurr)
	
	self.wndAbsorbCapacityTint:SetMax(nAbsorbMax)
	self.wndAbsorbCapacityTint:SetProgress(nAbsorbCurr)
	
	local bShowMaxShield = nShieldCurr > 0 and nShieldMax > 0
	if bShowMaxShield ~= self.wndMaxShield:IsShown() then
		self.wndMaxShield:Show(bShowMaxShield)
	end
	
	local bShowMaxAbsorb = nAbsorbCurr > 0 and nAbsorbMax > 0
	if bShowMaxAbsorb ~= self.wndMaxAbsorb:IsShown() then
		self.wndMaxAbsorb:Show(bShowMaxAbsorb)
	end
	
	local bShowHealthClampMax = nHealthClampMax ~= nHealthMax
	if bShowHealthClampMax ~= self.wndHealthClampMax:IsShown() then
		self.wndHealthClampMax:Show(bShowHealthClampMax)
	end
	
	local bShowHealthClampMin = nHealthClampMin > 0
	if bShowHealthClampMin ~= self.wndHealthClampMin:IsShown() then
		self.wndHealthClampMin:Show(bShowHealthClampMin)
	end
	
	if bShowMaxShield ~= self.bShowMaxShield then
		self.wndMaxAbsorb:MoveToLocation(bShowMaxShield and self.arAbsorbPos or self.arShieldPos)
	end
	
	local bUpdateCastingBarPolys = false
	if not bShowMaxShield and not bShowMaxAbsorb then
		-- reduce by 2
		if bShowMaxShield ~= self.bShowMaxShield or bShowMaxAbsorb ~= self.bShowMaxAbsorb then
			bUpdateCastingBarPolys = true 
			
			if self.tParams.bFlipped then
				self.wndLargeFrame:SetAnchorOffsets(self.nLFrameRight-knFrameWidthMin, self.nLFrameTop, self.nLFrameRight, self.nLFrameBottom)
			else
				self.wndLargeFrame:SetAnchorOffsets(self.nLFrameLeft, self.nLFrameTop, self.nLFrameLeft+knFrameWidthMin, self.nLFrameBottom)
			end
		end
		
		if self.wndHealthSplit:IsShown() then
			self.wndHealthSplit:Show(false)
		end
	elseif not bShowMaxShield or not bShowMaxAbsorb then
		-- reduce by 1
		if bShowMaxShield ~= self.bShowMaxShield or bShowMaxAbsorb ~= self.bShowMaxAbsorb then
			bUpdateCastingBarPolys = true 
			
			if self.tParams.bFlipped then
				self.wndLargeFrame:SetAnchorOffsets(self.nLFrameRight-knFrameWidthShield, self.nLFrameTop, self.nLFrameRight, self.nLFrameBottom)
			else
				self.wndLargeFrame:SetAnchorOffsets(self.nLFrameLeft, self.nLFrameTop, self.nLFrameLeft+knFrameWidthShield, self.nLFrameBottom)
			end
		end
		
		if not self.wndHealthSplit:IsShown() then
			self.wndHealthSplit:Show(true)
		end
	else
		if bShowMaxShield ~= self.bShowMaxShield or bShowMaxAbsorb ~= self.bShowMaxAbsorb then
			bUpdateCastingBarPolys = true 
			
			if self.tParams.bFlipped then
				self.wndLargeFrame:SetAnchorOffsets(self.nLFrameRight-knFrameWidthMax, self.nLFrameTop, self.nLFrameRight, self.nLFrameBottom)
			else
				self.wndLargeFrame:SetAnchorOffsets(self.nLFrameLeft, self.nLFrameTop, self.nLFrameLeft+knFrameWidthMax, self.nLFrameBottom)
			end
		end
		
		if not self.wndHealthSplit:IsShown() then
			self.wndHealthSplit:Show(true)
		end
	end
	
	if bUpdateCastingBarPolys then
		--The polygonal clipping values aren't relative. 
		--We need to make adjustments since we re-sized the unit frame.
		
		if self.tParams.bFlipped then
			self.wndCastingBar:SetClipPoints(
				{nY = 0,											nX = -knCastBarPolyOffsetX1},
				{nY = self.wndCastingBar:GetHeight(),	nX = -knCastBarPolyOffsetX1 + knCastBarPolyAngleDeltaX},
				{nY = self.wndCastingBar:GetHeight(),	nX = self.wndCastingBar:GetWidth() + knCastBarPolyOffsetX2},
				{nY = 0,											nX = self.wndCastingBar:GetWidth() + knCastBarPolyOffsetX2 - knCastBarPolyAngleDeltaX}
			)
		else
			self.wndCastingBar:SetClipPoints(
				{nY = 0,											nX = -knCastBarPolyOffsetX2 + knCastBarPolyAngleDeltaX},
				{nY = self.wndCastingBar:GetHeight(),	nX = -knCastBarPolyOffsetX2},
				{nY = self.wndCastingBar:GetHeight(),	nX = self.wndCastingBar:GetWidth() + knCastBarPolyOffsetX1 - knCastBarPolyAngleDeltaX},
				{nY = 0,											nX = self.wndCastingBar:GetWidth() + knCastBarPolyOffsetX1}
			)
		end
	end
	
	-- String
	local strHealthMax = self.strHealthMax
	if nHealthMax ~= self.nHealthMax then
		strHealthMax = nHealthMax > 0 and self:HelperFormatBigNumber(nHealthMax) or "0"
		self.strHealthMax = strHealthMax
	end
	
	local strHealthCurr = self.strHealthCurr
	if nHealthCurr ~= self.nHealthCurr then
		strHealthCurr = nHealthCurr > 0 and self:HelperFormatBigNumber(nHealthCurr) or "0"
		self.strHealthCurr = strHealthCurr
	end
	
	local strShieldCurr = self.strShieldCurr
	if nShieldCurr ~= self.nShieldCurr then
		strShieldCurr = nShieldCurr > 0 and self:HelperFormatBigNumber(nShieldCurr) or "0"
		self.strShieldCurr = strShieldCurr
	end
	
	local strShieldMax = self.strShieldMax
	if nShieldMax ~= self.nShieldMax then
		strShieldMax = nShieldMax > 0 and self:HelperFormatBigNumber(nShieldMax) or "0"
		self.strShieldMax = strShieldMax
	end
	
	local strAbsorbCurr = self.strAbsorbCurr
	if nAbsorbCurr ~= self.nAbsorbCurr then
		strAbsorbCurr = nAbsorbCurr > 0 and self:HelperFormatBigNumber(nAbsorbCurr) or "0"
		self.strAbsorbCurr = strAbsorbCurr
	end
	
	local strAbsorbMax = self.strAbsorbMax
	if nAbsorbMax ~= self.nAbsorbMax then
		strAbsorbMax = nAbsorbMax > 0 and self:HelperFormatBigNumber(nAbsorbMax) or "0"
		self.strAbsorbMax = strAbsorbMax
	end
	
	local strHealingAbsorb = self.strHealingAbsorb
	if nHealingAbsorbCurr ~= self.nHealingAbsorbCurr then
		strHealingAbsorb = nHealingAbsorbCurr > 0 and self:HelperFormatBigNumber(nHealingAbsorbCurr) or "0"
		self.strHealingAbsorb = strHealingAbsorb
	end
	
	
	local nVisibility = Apollo.GetConsoleVariable("hud.healthTextDisplay")
	
	local tTooltipParts = {}
	
	if nHealthMax ~= self.nHealthMax or nHealthCurr ~= self.nHealthCurr then
		self.strHealthTooltip = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthFormat"), Apollo.GetString("Innate_Health"), strHealthCurr, strHealthMax, String_GetWeaselString(Apollo.GetString("CRB_Percent"), nHealthCurr/nHealthMax*100))
	end
	tTooltipParts[#tTooltipParts + 1] = self.strHealthTooltip
	
	if nShieldMax > 0 and nShieldCurr > 0 then	
		if nShieldCurr ~= self.nShieldCurr or nShieldMax ~= self.nShieldMax then
			self.strShieldTooltip = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthFormat"), Apollo.GetString("Character_ShieldLabel"), strShieldCurr, strShieldMax, String_GetWeaselString(Apollo.GetString("CRB_Percent"), nShieldCurr/nShieldMax*100))
		end
		tTooltipParts[#tTooltipParts + 1] = self.strShieldTooltip
	end
	
	if nAbsorbMax > 0 and nAbsorbCurr > 0 then
		if nAbsorbCurr ~= self.nAbsorbCurr or nAbsorbMax ~= self.nAbsorbMax then
			self.strAbsorbTooltip = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthFormat"), Apollo.GetString("FloatText_AbsorbTester"), strAbsorbCurr, strAbsorbMax, String_GetWeaselString(Apollo.GetString("CRB_Percent"), nAbsorbCurr/nAbsorbMax*100))
		end
		tTooltipParts[#tTooltipParts + 1] = self.strAbsorbTooltip
	end
	
	if nHealingAbsorbCurr > 0 then
		if nHealingAbsorbCurr ~= self.nHealingAbsorbCurr then
			self.strHealingAbsorbTooltip = String_GetWeaselString(Apollo.GetString("TargetFrame_HealingAbsorbFormat"), Apollo.GetString("Character_HealingAbsorbLabel"), strHealingAbsorb)
		end
		tTooltipParts[#tTooltipParts + 1] = self.strHealingAbsorbTooltip
	end
	
	--Toggle Visibility based on ui preference
	if nVisibility == 2 then -- show x/y
		local strTextXY = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthText"), strHealthCurr, strHealthMax)
		if nShieldMax > 0 and nShieldCurr > 0 then
			strTextXY = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthShieldText"), strTextXY, strShieldCurr)
		end
	
		self.wndHealthText:SetText(strTextXY)
	elseif nVisibility == 3 then --show %
		local strTextPCT = String_GetWeaselString(Apollo.GetString("CRB_Percent"), nHealthCurr/nHealthMax*100)
		if nShieldMax > 0 and nShieldCurr > 0 and nShieldCurr/nShieldMax ~= nHealthCurr/nHealthMax  then
			strTextPCT = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthShieldText"), strTextPCT, String_GetWeaselString(Apollo.GetString("CRB_Percent"), nShieldCurr/nShieldMax*100))
		end
	
		self.wndHealthText:SetText(strTextPCT)
	else --on mouseover
		self.wndHealthText:SetText("")
	end
	
	if nHealthMax ~= self.nHealthMax 
		or nHealthCurr ~= self.nHealthCurr
		or nShieldCurr ~= self.nShieldCurr
		or nShieldMax ~= self.nShieldMax
		or nAbsorbCurr ~= self.nAbsorbCurr
		or nAbsorbMax ~= self.nAbsorbMax
		or nHealingAbsorbCurr ~= self.nHealingAbsorbCurr then
		
		self.wndHealthText:SetTooltip(table.concat(tTooltipParts,"\n"))
	end
	
	self.bShowMaxShield = bShowMaxShield
	self.bShowMaxAbsorb = bShowMaxAbsorb
	self.nHealthMax = nHealthMax
	self.nHealthCurr = nHealthCurr
	self.nShieldMax = nShieldMax
	self.nShieldCurr = nShieldCurr
	self.nAbsorbMax = nAbsorbMax
	self.nAbsorbCurr = nAbsorbCurr
	self.nHealingAbsorbCurr = nHealingAbsorbCurr
end


function TargetFrame:HelperFormatBigNumber(nArg)
	local strResult
	if nArg < 1000 then
		strResult = tostring(nArg)
	elseif nArg < 1000000 then
		if math.floor(nArg%1000/100) == 0 then
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_ShortNumberWhole"), math.floor(nArg / 1000))
		else
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_ShortNumberFloat"), nArg / 1000)
		end
	elseif nArg < 1000000000 then
		if math.floor(nArg%1000000/100000) == 0 then
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_MillionsNumberWhole"), math.floor(nArg / 1000000))
		else
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_MillionsNumberFloat"), nArg / 1000000)
		end
	elseif nArg < 1000000000000 then
		if math.floor(nArg%1000000/100000) == 0 then
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_BillionsNumberWhole"), math.floor(nArg / 1000000))
		else
			strResult = String_GetWeaselString(Apollo.GetString("TargetFrame_BillionsNumberFloat"), nArg / 1000000)
		end
	else
		strResult = tostring(nArg)
	end
	return strResult
end

function TargetFrame:SetBarValue(wndBar, fMin, fValue, fMax)
	wndBar:SetMax(fMax)
	wndBar:SetFloor(fMin)
	wndBar:SetProgress(fValue)
end

function TargetFrame:OnGenerateBuffTooltip(wndHandler, wndControl, eType, splBuff)
	if wndHandler == wndControl or eType ~= Tooltip.TooltipGenerateType_Spell then
		return
	end
	Tooltip.GetBuffTooltipForm(self, wndControl, splBuff, {bFutureSpell = false})
end

function TargetFrame:OnMouseButtonDown(wndHandler, wndControl, eMouseButton, x, y)
	local unitToT = wndHandler:GetData()
	if eMouseButton == GameLib.CodeEnumInputMouse.Left and unitToT ~= nil then
		GameLib.SetTargetUnit(unitToT)
		return false
	end
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and unitToT ~= nil then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", nil, unitToT:GetName(), unitToT)
		return true
	end

	if IsDemo() then
		return true
	end

	return false
end

function TargetFrame:OnPVPIconMouseBtnDown(wndHandler, wndControl, eMouseButton, x, y)
	if wndHandler ~= wndControl then
		return
	end

	local unitToT = wndHandler:GetParent():FindChild("TargetModel"):GetData()
	if eMouseButton == GameLib.CodeEnumInputMouse.Left and unitToT ~= nil then
		GameLib.SetTargetUnit(unitToT)
		return false
	end
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and unitToT ~= nil then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", nil, unitToT:GetName(), unitToT)
		return true
	end

	if IsDemo() then
		return true
	end

	return false
end

function TargetFrame:OnQueryDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, nValue)
	if wndHandler ~= wndControl then
		return Apollo.DragDropQueryResult.PassOn
	end

	local unitToT = GameLib.GetTargetUnit()
	if unitToT == nil then
		return Apollo.DragDropQueryResult.Invalid
	end
	if unitToT:IsACharacter() and not unitToT:IsThePlayer() and strType == "DDBagItem" then
		return Apollo.DragDropQueryResult.Accept
	end
	return Apollo.DragDropQueryResult.Invalid
end

function TargetFrame:OnDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, nValue)
	if wndHandler ~= wndControl then
		return false
	end

	local unitToT = GameLib.GetTargetUnit()
	if unitToT == nil then
		return false
	end
	if unitToT:IsACharacter() and not unitToT:IsThePlayer() and strType == "DDBagItem" then
		Event_FireGenericEvent("ItemDropOnTarget", unit, strType, nValue)
		return false
	end
end

function TargetFrame:OnKeyBindingUpdated(strKeybind)
	if strKeybind ~= "Path Action" and strKeybind ~= "Cast Objective Ability" then
		return
	end

	self.strPathActionKeybind = GameLib.GetKeyBinding("PathAction")
	self.bPathActionUsesIcon = false
	if self.strPathActionKeybind == "Unbound" or #self.strPathActionKeybind > 1 then -- Don't show interact
		self.bPathActionUsesIcon = true
	end

	self.strQuestActionKeybind = GameLib.GetKeyBinding("CastObjectiveAbility")
	self.bQuestActionUsesIcon = false
	if self.strQuestActionKeybind == "Unbound" or #self.strQuestActionKeybind > 1 then -- Don't show interact
		self.bQuestActionUsesIcon = true
	end
end

function ClusterFrame:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function ClusterFrame:Init(xmlDoc, wndParent)	
	self.wndCluster = Apollo.LoadForm(xmlDoc, "ClusterTargetMini", wndParent, self)
	self.wndTargetModel = self.wndCluster:FindChild("TargetModel")
	self.wndTargetGoalPanel = self.wndCluster:FindChild("TargetGoalPanel")
	self.wndTargetLevel = self.wndCluster:FindChild("TargetLevel")
	self.wndTargetScalingMark = self.wndCluster:FindChild("TargetScalingMark")
	self.wndCertainDeathIcon = self.wndCluster:FindChild("CertainDeathIcon")
	self.wndCover = self.wndCluster:FindChild("Cover")
	self.wndHealthTint = self.wndCluster:FindChild("HealthTint")
	self.wndHealthShieldTint = self.wndCluster:FindChild("HealthShieldTint")
	self.wndShieldCapacityTint = self.wndCluster:FindChild("ShieldCapacityTint")
	self.wndCastingFrame = self.wndCluster:FindChild("CastingFrame")
	self.wndCastingIcon = self.wndCluster:FindChild("CastingIcon")
end

function ClusterFrame:SetTarget(unitTarget)
	if unitTarget ~= nil and unitTarget == self.unitTarget then
		return
	end
	
	if unitTarget ~= self.unitTarget then
		self.wndCluster:SetData(unitTarget)
	end

	self.unitTarget = unitTarget
	
	if unitTarget == nil or not unitTarget:IsValid() then
		if self.wndCluster:IsShown() then
			self.wndCluster:Show(false)
		end
	
		return
	end
end

function ClusterFrame:OnFrame()
	local unitTarget = self.unitTarget
	
	if unitTarget == nil or not unitTarget:IsValid() or unitTarget:IsDead() then
		if self.wndCluster:IsShown() then
			self.wndCluster:Show(false)
		end
		
		return
	end
	
	if not self.wndCluster:IsShown() then
		self.wndCluster:Show(true, true)
	end
	
	self:UpdateCastingBar()
	self.wndTargetModel:SetCostume(unitTarget)

	if kbUpdateRewardIcons and RewardIcons ~= nil and RewardIcons.GetUnitRewardIconsForm ~= nil then
		RewardIcons.GetUnitRewardIconsForm(self.wndTargetGoalPanel, unitTarget, {bVert = false})
	end
	
	local idUnit		= unitTarget:GetId()
	local nHealth		= unitTarget:GetHealth()
	local nMaxHealth	= unitTarget:GetMaxHealth()
	local nShield		= unitTarget:GetShieldCapacity()
	local nMaxShield	= unitTarget:GetShieldCapacityMax()
	local nLevel 		= unitTarget:GetLevel()
	
	if nHealth ~= nil then
		local wndHealthBar = self.wndHealthTint
		local wndHealthShieldBar = self.wndHealthShieldTint
		local wndShieldBar = self.wndShieldCapacityTint
		
		local wndHealth = nMaxShield > 0 and wndHealthShieldBar or wndHealthBar
		if nMaxShield ~= self.nMaxShield then
			wndHealthBar:Show(nMaxShield == 0)
		end
		if nMaxShield ~= self.nMaxShield then
			wndHealthShieldBar:Show(nMaxShield > 0)
		end
		if nMaxShield ~= self.nMaxShield then
			wndShieldBar:Show(nMaxShield > 0)
		end
		if nMaxShield ~= self.nMaxShield then
			self.wndCover:SetSprite(nMaxShield > 0 and "spr_TargetFrame_ClusterCoverShield" or "spr_TargetFrame_ClusterCover")
		end
		
		wndHealth:SetMax(nMaxHealth)
		wndHealth:SetProgress(nHealth)
		
		wndShieldBar:SetMax(nMaxShield)
		wndShieldBar:SetProgress(nShield)
		
		if nHealth ~= self.nHealth or nMaxHealth ~= self.nMaxHealth then
			if unitTarget:IsInCCState(Unit.CodeEnumCCState.Vulnerability) then
				wndHealth:SetFullSprite("spr_TargetFrame_ClusterHealthRed")
			elseif (nHealth / nMaxHealth) <= knHealthRed then
				wndHealth:SetFullSprite("spr_TargetFrame_ClusterHealthRed")
			elseif (nHealth / nMaxHealth) <= knHealthYellow then
				wndHealth:SetFullSprite("spr_TargetFrame_ClusterHealthYellow")
			else
				wndHealth:SetFullSprite("spr_TargetFrame_ClusterHealthGreen")
			end
		end
		
		if nHealth ~= self.nHealth
			or nMaxHealth ~= self.nMaxHealth
			or nShield ~= self.nShield
			or nMaxShield ~= self.nMaxShield
			or idUnit ~= self.idUnit then
			
			if nHealth ~= self.nHealth or nMaxHealth ~= self.nMaxHealth then
				local strHealthCurr = nHealth > 0 and TargetFrame.HelperFormatBigNumber(self, nHealth) or "0"
				local strHealthMax = nMaxHealth > 0 and TargetFrame.HelperFormatBigNumber(self, nMaxHealth) or "0"
				
				self.strHealthTooltip = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthFormat"), Apollo.GetString("Innate_Health"), strHealthCurr, strHealthMax, String_GetWeaselString(Apollo.GetString("CRB_Percent"), nHealth/nMaxHealth*100))
			end
			
			if unitTarget:GetShieldCapacityMax() ~= 0 then
				if nShield ~= self.nShield or nMaxShield ~= self.nMaxShield then
					local strShieldCurr = nShield > 0 and TargetFrame.HelperFormatBigNumber(self, nShield) or "0"
					local strShieldMax = nMaxShield > 0 and TargetFrame.HelperFormatBigNumber(self, nMaxShield) or "0"
					self.strShieldTooltip = String_GetWeaselString(Apollo.GetString("TargetFrame_HealthFormat"), Apollo.GetString("Character_ShieldLabel"), strShieldCurr, strShieldMax, String_GetWeaselString(Apollo.GetString("CRB_Percent"), nShield/nMaxShield*100))
				end
			else
				self.strShieldTooltip = ""
			end
			
			self.wndCluster:SetTooltip(string.format("%s\n%s\n%s", unitTarget:GetName(), self.strHealthTooltip, self.strShieldTooltip))
		end
	end
	
	if nLevel == nil then
		if nLevel ~= self.nLevel then
			self.wndTargetLevel:SetText("")
			self.wndTargetLevel:SetTextColor(karConInfo[1][2])
			self.wndTargetLevel:SetTooltip("")
		end
	else
		local nCon = TargetFrame.HelperCalculateConValue(self, unitTarget)
		
		if nLevel ~= self.nLevel then
			self.wndTargetLevel:SetText(nLevel)
		end
		
		if unitTarget:IsScaled() then
			if not self.wndTargetScalingMark:IsShown() then
				self.wndTargetScalingMark:Show(true)
				self.wndTargetLevel:SetTextColor(kcrScalingCColor)
			end
			
			if nLevel ~= self.nLevel then
				if unitTarget ~= kunitPlayer then
					local strRewardFormatted = String_GetWeaselString(Apollo.GetString("TargetFrame_CreatureScales"), nLevel)
					local strLevelTooltip = TargetFrame.HelperBuildTooltip(self, strRewardFormatted, Apollo.GetString("Adaptive"), kstrScalingHex)
					self.wndTargetLevel:SetTooltip(strLevelTooltip)
				end
			end
		else
			if self.wndTargetScalingMark:IsShown() then
				self.wndTargetScalingMark:Show(false)
				self.wndTargetLevel:SetTextColor(karConInfo[nCon][2])
			end
			
			if nCon ~= self.nCon then
				self.wndTargetLevel:SetTextColor(karConInfo[nCon][2])
				
				if unitTarget ~= kunitPlayer then
					local strRewardFormatted = String_GetWeaselString(Apollo.GetString("TargetFrame_TargetXPReward"), karConInfo[nCon][4])
					local strLevelTooltip = TargetFrame.HelperBuildTooltip(self, strRewardFormatted, karConInfo[nCon][3], karConInfo[nCon][5])
					self.wndTargetLevel:SetTooltip(strLevelTooltip)
				end
			end
		end
		
		self.nCon = nCon
	end
	
	self.idUnit = idUnit
	self.nHealth = nHealth
	self.nMaxHealth = nMaxHealth
	self.nShield = nShield
	self.nMaxShield = nMaxShield
	self.nLevel = nLevel
end

function ClusterFrame:UpdateCastingBar()
	local bShowCasting = false
	local nMaxZone = 0
	local nDuration = 0
	local eType = Unit.CodeEnumCastBarType.None
	local strIcon

	if self.unitTarget:ShouldShowCastBar() then
		eType = self.unitTarget:GetCastBarType()

		if eType == Unit.CodeEnumCastBarType.Telegraph_Evade then
			strIcon = "CRB_TargetFrameSprites:sprTF_CastIconEvade"
		elseif eType == Unit.CodeEnumCastBarType.Telegraph_Backlash then
			strIcon = "CRB_TargetFrameSprites:sprTF_CastIconInterrupt"
		else
			strIcon = ""
		end

		if eType ~= Unit.CodeEnumCastBarType.None then
			bShowCasting = true
			nMaxZone = 1
			nDuration = self.unitTarget:GetCastDuration()

			strSpellName = self.unitTarget:GetCastName()
		end
	end

	if bShowCasting ~= self.wndCastingFrame:IsShown() then
		self.wndCastingFrame:Show(bShowCasting)
	end

	if bShowCasting and nDuration > 0 and nMaxZone > 0 then
		if strIcon ~= self.strIcon then
			self.wndCastingIcon:SetSprite(strIcon)
			
			self.strIcon = strIcon
		end
	end
end

function ClusterFrame:OnMouseButtonDown(wndHandler, wndControl, eMouseButton, x, y)
	local unitToT = wndHandler:GetData()
	if eMouseButton == GameLib.CodeEnumInputMouse.Left and unitToT ~= nil then
		GameLib.SetTargetUnit(unitToT)
		return false
	end
	
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and unitToT ~= nil then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", nil, unitToT:GetName(), unitToT)
		return true
	end

	if IsDemo() then
		return true
	end

	return false
end

local UnitFramesInstance = UnitFrames:new()
UnitFrames:Init()