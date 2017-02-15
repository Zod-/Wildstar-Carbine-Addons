-----------------------------------------------------------------------------------------------
-- Client Lua Script for ChallengeLog
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "Apollo"
require "DialogSys"
require "Quest"
require "MailSystemLib"
require "Sound"
require "GameLib"
require "Tooltip"
require "XmlDoc"
require "PlayerPathLib"
require "AbilityBook"
require "PathMission"

local PathTracker = {}
local kstrLightGrey = "ffb4b4b4"
local kstrPathQuesttMarker = "90PathContent"
local knNewMissionRunnerTimeout = 1 --the number of pulses of the above timer before the "New" runner clears by itself
local knRate = 1

local ktPathType =
{
	[PlayerPathLib.PlayerPathType_Scientist] = { strNameEnum = "CRB_Scientist", strIcon = "spr_ObjectiveTracker_IconPathScientist" },
	[PlayerPathLib.PlayerPathType_Soldier] = { strNameEnum = "CRB_Soldier", strIcon = "spr_ObjectiveTracker_IconPathSoldier" },
	[PlayerPathLib.PlayerPathType_Settler] = { strNameEnum = "CRB_Settler", strIcon = "spr_ObjectiveTracker_IconPathSettler" },
	[PlayerPathLib.PlayerPathType_Explorer] = { strNameEnum = "CRB_Explorer", strIcon = "spr_ObjectiveTracker_IconPathExplorer" },
}

local ktMissionTypeIcons =
{
	[PathMission.PathMissionType_Explorer_Vista] = "Icon_Mission_Explorer_Vista",
	[PathMission.PathMissionType_Explorer_PowerMap] = "Icon_Mission_Explorer_PowerMap",
	[PathMission.PathMissionType_Explorer_Area] = "Icon_Mission_Explorer_ClaimTerritory",
	[PathMission.PathMissionType_Explorer_Door] = "Icon_Mission_Explorer_ActivateChecklist",
	[PathMission.PathMissionType_Explorer_ExploreZone] = "Icon_Mission_Explorer_ExploreZone",
	[PathMission.PathMissionType_Explorer_ScavengerHunt] = "Icon_Mission_Explorer_ScavengerHunt",
	[PathMission.PathMissionType_Explorer_ActivateChecklist] = "Icon_Mission_Explorer_ActivateChecklist",
	
	[PathMission.PathMissionType_Settler_Hub] = "Icon_Mission_Settler_DepotImprovements",
	[PathMission.PathMissionType_Settler_Infrastructure] = "Icon_Mission_Settler_InfastructureImprovements",
	[PathMission.PathMissionType_Settler_Mayor] = "Icon_Mission_Settler_Mayoral",
	[PathMission.PathMissionType_Settler_Sheriff] = "Icon_Mission_Settler_Posse",
	[PathMission.PathMissionType_Settler_Scout] = "Icon_Mission_Settler_Scout",
	
	[PathMission.PathMissionType_Scientist_FieldStudy] = "Icon_Mission_Scientist_FieldStudy",
	[PathMission.PathMissionType_Scientist_DatacubeDiscovery] = "Icon_Mission_Scientist_DatachronDiscovery",
	[PathMission.PathMissionType_Scientist_SpecimenSurvey] = "Icon_Mission_Scientist_SpecimenSurvey",
	[PathMission.PathMissionType_Scientist_Experimentation] = "Icon_Mission_Scientist_ReverseEngineering",
	
	[PathMission.PathMissionType_Soldier_SWAT] = "Icon_Mission_Soldier_Swat",
	[PathMission.PathMissionType_Soldier_Rescue] = "Icon_Mission_Soldier_Rescue",
	[PathMission.PathMissionType_Soldier_Demolition] = "Icon_Mission_Soldier_Demolition",
	[PathMission.PathMissionType_Soldier_Assassinate] = "Icon_Mission_Soldier_Assassinate",
}

local ktMissionSubTypeIcons =
{
	[PathMission.ScientistCreatureType_Tech] = "Icon_Mission_Scientist_ScanTech",
	[PathMission.ScientistCreatureType_Flora] = "Icon_Mission_Scientist_ScanPlant",
	[PathMission.ScientistCreatureType_Fauna] = "Icon_Mission_Scientist_ScanCreature",
	[PathMission.ScientistCreatureType_Mineral] = "Icon_Mission_Scientist_ScanMineral",
	[PathMission.ScientistCreatureType_Magic] = "Icon_Mission_Scientist_ScanMagic",
	[PathMission.ScientistCreatureType_History] = "Icon_Mission_Scientist_ScanHistory",
	[PathMission.ScientistCreatureType_Elemental] = "Icon_Mission_Scientist_ScanElemental",
	
	[PathMission.ScientistCreatureType_Tech] = "Icon_Mission_Scientist_ScanTech",
	[PathMission.ScientistCreatureType_Flora] = "Icon_Mission_Scientist_ScanPlant",
	[PathMission.ScientistCreatureType_Fauna] = "Icon_Mission_Scientist_ScanCreature",
	[PathMission.ScientistCreatureType_Mineral] = "Icon_Mission_Scientist_ScanMineral",
	[PathMission.ScientistCreatureType_Magic] = "Icon_Mission_Scientist_ScanMagic",
	[PathMission.ScientistCreatureType_History] = "Icon_Mission_Scientist_ScanHistory",
	[PathMission.ScientistCreatureType_Elemental] = "Icon_Mission_Scientist_ScanElemental",
}

local ktDisplayTypes =
{
	[PathMission.PathMissionDisplayType.Explorer_Cartography] = Apollo.GetString("ExplorerMission_Cartography"),
	[PathMission.PathMissionDisplayType.Explorer_Exploration] = Apollo.GetString("ExplorerMission_Exploration"),
	[PathMission.PathMissionDisplayType.Explorer_Operations] = Apollo.GetString("ExplorerMission_Operations"),
	[PathMission.PathMissionDisplayType.Explorer_ScavengerHunt] = Apollo.GetString("ExplorerMission_ScavengerHunt"),
	[PathMission.PathMissionDisplayType.Explorer_StakingClaim] = Apollo.GetString("ExplorerMission_StakingClaim"),
	[PathMission.PathMissionDisplayType.Explorer_Surveillance] = Apollo.GetString("ExplorerMission_Surveillance"),
	[PathMission.PathMissionDisplayType.Explorer_Tracking] = Apollo.GetString("ExplorerMission_Tracking"),
	[PathMission.PathMissionDisplayType.Explorer_Vista] = Apollo.GetString("ExplorerMission_Vista"),
	
	[PathMission.PathMissionDisplayType.Settler_Cache] = Apollo.GetString("SettlerMission_Cache"),
	[PathMission.PathMissionDisplayType.Settler_CivilService] = Apollo.GetString("SettlerMission_CivilService"),
	[PathMission.PathMissionDisplayType.Settler_Expansion] = Apollo.GetString("SettlerMission_Expansion"),
	[PathMission.PathMissionDisplayType.Settler_Project] = Apollo.GetString("SettlerMission_Project"),
	[PathMission.PathMissionDisplayType.Settler_PublicSafety] = Apollo.GetString("SettlerMission_PublicSafety"),
	
	[PathMission.PathMissionDisplayType.Scientist_Analysis] = Apollo.GetString("ScientistMission_Analysis"),
	[PathMission.PathMissionDisplayType.Scientist_Archaeology] = Apollo.GetString("ScientistMission_Archaeology"),
	[PathMission.PathMissionDisplayType.Scientist_Biology] = Apollo.GetString("ScientistMission_Biology"),
	[PathMission.PathMissionDisplayType.Scientist_Botany] = Apollo.GetString("ScientistMission_Botany"),
	[PathMission.PathMissionDisplayType.Scientist_Chemistry] = Apollo.GetString("ScientistMission_Chemistry"),
	[PathMission.PathMissionDisplayType.Scientist_DatacubeDecryption] = Apollo.GetString("ScientistMission_Datacube"),
	[PathMission.PathMissionDisplayType.Scientist_Diagnostics] = Apollo.GetString("ScientistMission_Diagnostics"),
	[PathMission.PathMissionDisplayType.Scientist_Experimentation] = Apollo.GetString("ScientistMission_Experimentation"),
	[PathMission.PathMissionDisplayType.Scientist_FieldStudy] = Apollo.GetString("ScientistMission_FieldStudy"),
	[PathMission.PathMissionDisplayType.Scientist_SpecimenSurvey] = Apollo.GetString("ScientistMission_SpecimenSurvey"),
	
	[PathMission.PathMissionDisplayType.Soldier_Assassination] = Apollo.GetString("SoldierMission_Assassination"),
	[PathMission.PathMissionDisplayType.Soldier_Defend] = Apollo.GetString("SoldierMission_Defend"),
	[PathMission.PathMissionDisplayType.Soldier_Demolition] = Apollo.GetString("SoldierMission_Demolition"),
	[PathMission.PathMissionDisplayType.Soldier_FirstStrike] = Apollo.GetString("SoldierMission_FirstStrike"),
	[PathMission.PathMissionDisplayType.Soldier_Holdout] = Apollo.GetString("SoldierMission_Holdout"),
	[PathMission.PathMissionDisplayType.Soldier_RescueOp] = Apollo.GetString("SoldierMission_RescueOps"),
	[PathMission.PathMissionDisplayType.Soldier_Security] = Apollo.GetString("SoldierMission_Security"),
	[PathMission.PathMissionDisplayType.Soldier_Swat] = Apollo.GetString("SoldierMission_Swat"),
}

local ktFieldStudySubType =
{
	[PathMission.Behavior_Sleep] = "ClientSprites:Icon_Windows_UI_CRB_FieldStudy_Sleeping",
	[PathMission.Behavior_Love] = "ClientSprites:Icon_Windows_UI_CRB_FieldStudy_Love",
	[PathMission.Behavior_Working] = "ClientSprites:Icon_Windows_UI_CRB_FieldStudy_Working",
	[PathMission.Behavior_Hunting] = "ClientSprites:Icon_Windows_UI_CRB_FieldStudy_Hunting",
	[PathMission.Behavior_Scared] = "ClientSprites:Icon_Windows_UI_CRB_FieldStudy_Scared",
	[PathMission.Behavior_Aggressive] = "ClientSprites:Icon_Windows_UI_CRB_FieldStudy_Aggressive",
	[PathMission.Behavior_Food] = "ClientSprites:Icon_Windows_UI_CRB_FieldStudy_Hungry",
	[PathMission.Behavior_Happy] = "ClientSprites:Icon_Windows_UI_CRB_FieldStudy_Playful",
	[PathMission.Behavior_Singing] = "ClientSprites:Icon_Windows_UI_CRB_FieldStudy_Singing",
	[PathMission.Behavior_Injured] = "ClientSprites:Icon_Windows_UI_CRB_FieldStudy_Injured",
	[PathMission.Behavior_Guarding] = "ClientSprites:Icon_Windows_UI_CRB_FieldStudy_Guarding",
	[PathMission.Behavior_Socializing] = "ClientSprites:Icon_Windows_UI_CRB_FieldStudy_Social",
}

local ktSoldierEventTypeToVictoryMessage =
{
	[PathMission.PathSoldierEventType_StopTheThieves] = "wavedefense",
	[PathMission.PathSoldierEventType_TowerDefense] = "wavedefense",
	[PathMission.PathSoldierEventType_WhackAMole] = "wavedefense",
	[PathMission.PathSoldierEventType_Defend] = "wavedefense",
	[PathMission.PathSoldierEventType_StopTheThievesTimed] = "timed",
	[PathMission.PathSoldierEventType_WhackAMoleTimed] = "timed",
	[PathMission.PathSoldierEventType_TimedDefend] = "timed",
	[PathMission.PathSoldierEventType_Timed] = "timed",
}

local ktSoliderFailReasonStrings  =
{
	[PathMission.PlayerPathSoldierResult_ScriptCancel] = "CRB_Whoops_Cancelled_by_script",
	[PathMission.PlayerPathSoldierResult_FailUnknown] = "CRB_Whoops_Somethings_gone_wrong_here",
	[PathMission.PlayerPathSoldierResult_FailDeath] = "CRB_Your_defenses_werent_enough_this_tim",
	[PathMission.PlayerPathSoldierResult_FailTimeOut] = "CRB_Time_has_expired_Remember_haste_make",
	[PathMission.PlayerPathSoldierResult_FailLeaveArea] = "CRB_The_Holdouts_initiator_fled_in_terro",
	[PathMission.PlayerPathSoldierResult_FailDefenceDeath] = "CRB_Your_defenses_werent_enough_this_tim",
	[PathMission.PlayerPathSoldierResult_FailLostResources] = "CRB_Your_defenses_werent_enough_this_tim",
	[PathMission.PlayerPathSoldierResult_FailNoParticipants] = "CRB_The_Holdouts_initiator_fled_in_terro",
	[PathMission.PlayerPathSoldierResult_FailParticipation] = "CRB_Holdout_Failed",
}

function PathTracker:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	-- Window Management
	o.wndMain = nil
	o.tMissionWndCache = {}
	o.tChecklistWndCache = {}
	o.tRapidDistanceChecks = {}
	
	-- Data
	o.tNewMissions = {}
	o.nMissionCount = 0
	o.tScannedItems = {}
	o.tDistanceCache = {}
	
	-- Saved Data
	o.bMinimized = false
	o.bMinimizedActive = false
	o.bMinimizedAvailable = false
	o.bMinimizedOnGoing = false -- Settler
	o.bMinimizedScanBot = false -- Scientist
	o.bShowOutOfZone = false
	o.bFilterLimit = true
	o.bFilterDistance = false
	o.bShowPathMissions = true
	o.nMaxMissionDistance = 800
	o.nMaxMissionLimit = 3
	o.bToggleOnGoingProjects = true
	
	return o
end

function PathTracker:Init()
	Apollo.RegisterAddon(self)
end

function PathTracker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("PathTracker.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)

	self.timerResizeDelay = ApolloTimer.Create(0.1, false, "OnResizeDelayTimer", self)
	self.timerResizeDelay:Set(0.1, false, false)
	self.timerResizeDelay:Stop()
	
	self.timerRealTimeUpdate = ApolloTimer.Create(1.0, true, "OnRealTimeUpdateTimer", self)
	self.timerRealTimeUpdate:Set(1.0, true, false)
	
	self.timerScanbotCooldown = ApolloTimer.Create(1.0, false, "OnScanbotTimer", self)
	self.timerScanbotCooldown:Stop()
	
	self.timeSoldierResultTimeout = ApolloTimer.Create(5.0, false, "OnSoldierResultTimeoutTimer", self)
	self.timeSoldierResultTimeout:Stop()
	
	self.timerRapidDistanceCheck = ApolloTimer.Create(0.2, true, "OnRapidDistanceCheckTimer", self)
	self.timerRapidDistanceCheck:Set(0.2, true, false)
	self.timerRapidDistanceCheck:Stop()
end

function PathTracker:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	local tSave =
	{
		bMinimized = self.bMinimized,
		bMinimizedActive = self.bMinimizedActive,
		bMinimizedAvailable = self.bMinimizedAvailable,
		bMinimizedOnGoing = self.bMinimizedOnGoing,
		bMinimizedScanBot = self.bMinimizedScanBot,
		
		bShowPathMissions = self.bShowPathMissions,
		nMaxMissionDistance = self.nMaxMissionDistance,
		nMaxMissionLimit = self.nMaxMissionLimit,
		bShowOutOfZone = self.bShowOutOfZone,
		bFilterLimit = self.bFilterLimit,
		bFilterDistance = self.bFilterDistance,
		bToggleOnGoingProjects = self.bToggleOnGoingProjects,
	}

	return tSave
end

function PathTracker:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character or tSavedData == nil then
		return
	end
		
	if tSavedData.bMinimized ~= nil then
		self.bMinimized = tSavedData.bMinimized
	end
	
	if tSavedData.bMinimizedActive ~= nil then
		self.bMinimizedActive = tSavedData.bMinimizedActive
	end
	
	if tSavedData.bMinimizedAvailable ~= nil then
		self.bMinimizedAvailable = tSavedData.bMinimizedAvailable
	end
	
	if tSavedData.bMinimizedOnGoing ~= nil then
		self.bMinimizedOnGoing = tSavedData.bMinimizedOnGoing
	end
	
	if tSavedData.bMinimizedScanBot ~= nil then
		self.bMinimizedScanBot = tSavedData.bMinimizedScanBot
	end
	
	if tSavedData.bShowPathMissions ~= nil then
		self.bShowPathMissions = tSavedData.bShowPathMissions
	end
	
	if tSavedData.nMaxMissionDistance ~= nil then
		self.nMaxMissionDistance = tSavedData.nMaxMissionDistance
	end
	
	if tSavedData.nMaxMissionLimit ~= nil then
		self.nMaxMissionLimit = tSavedData.nMaxMissionLimit
	end
	
	if tSavedData.bShowOutOfZone ~= nil then
		self.bShowOutOfZone = tSavedData.bShowOutOfZone
	end
	
	if tSavedData.bFilterLimit ~= nil then
		self.bFilterLimit = tSavedData.bFilterLimit
	end
	
	if tSavedData.bFilterDistance ~= nil then
		self.bFilterDistance = tSavedData.bFilterDistance
		
		if self.bFilterDistance and self.wndMain ~= nil then
			self.timerRealTimeUpdate:Start()
		end
	end
	
	if tSavedData.bToggleOnGoingProjects ~= nil then
		self.bToggleOnGoingProjects = tSavedData.bToggleOnGoingProjects
	end
end

function PathTracker:OnDocumentReady()
	if self.xmlDoc == nil then return end
	
	self:InitializeWindowMeasuring()
	
	Apollo.RegisterEventHandler("ObjectiveTrackerLoaded", "OnObjectiveTrackerLoaded", self)
	Event_FireGenericEvent("ObjectiveTracker_RequestParent")
end

function PathTracker:InitializeWindowMeasuring() -- Try not to run these OnLoad as they may be expensive
	local wndMeasure = Apollo.LoadForm(self.xmlDoc, "Container", nil, self)
	self.knInitialContainerHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()
	
	wndMeasure = Apollo.LoadForm(self.xmlDoc, "Category", nil, self)
	self.knInitialCategoryHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()
	
	wndMeasure = Apollo.LoadForm(self.xmlDoc, "ListItem", nil, self)
	self.knInitialListItemHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()
end

function PathTracker:OnObjectiveTrackerLoaded(wndForm)
	if wndForm == nil or not wndForm:IsValid() then
		return
	end
	
	Apollo.RemoveEventHandler("ObjectiveTrackerLoaded", self)

	Apollo.RegisterEventHandler("ToggleShowPathMissions", 					"OnToggleShowPathMissions", self)
	Apollo.RegisterEventHandler("ToggleShowPathOptions", 					"DrawContextMenu", self)
	
	Apollo.RegisterEventHandler("SetPlayerPath", 							"OnSetPlayerPath", self)
	Apollo.RegisterEventHandler("PlayerPathRefresh", 						"OnPlayerPathRefresh", self)
	Apollo.RegisterEventHandler("PlayerPathMissionActivate", 				"OnPlayerPathMissionActivate", self)
	Apollo.RegisterEventHandler("PlayerPathMissionAdvanced", 				"OnPlayerPathMissionAdvanced", self)
	Apollo.RegisterEventHandler("PlayerPathMissionComplete", 				"OnPlayerPathMissionComplete", self)
	Apollo.RegisterEventHandler("PlayerPathMissionDeactivate", 				"OnPlayerPathMissionDeactivate", self)
	Apollo.RegisterEventHandler("PlayerPathMissionUnlocked", 				"OnPlayerPathMissionUnlocked", self)
	Apollo.RegisterEventHandler("PlayerPathMissionUpdate", 					"OnPlayerPathMissionUpdate", self)
	Apollo.RegisterEventHandler("PlayerPathExplorerPowerMapEntered", 		"OnPlayerPathExplorerPowerMapEntered", self)
	Apollo.RegisterEventHandler("PlayerPathExplorerPowerMapExited", 		"OnPlayerPathExplorerPowerMapExited", self)
	Apollo.RegisterEventHandler("PlayerPathExplorerPowerMapFailed", 		"OnPlayerPathExplorerPowerMapFailed", self)
	Apollo.RegisterEventHandler("PlayerPathExplorerPowerMapStarted", 		"OnPlayerPathExplorerPowerMapStarted", self)
	Apollo.RegisterEventHandler("PlayerPathExplorerPowerMapWaiting", 		"OnPlayerPathExplorerPowerMapWaiting", self)
	Apollo.RegisterEventHandler("PlayerPathExplorerScavengerHuntStarted", 	"OnPlayerPathExplorerScavengerHuntStarted", self)
	Apollo.RegisterEventHandler("PlayerPathScientistScanData", 				"OnScientistScanData", self)
	Apollo.RegisterEventHandler("PlayerPathScientistScanBotCooldown", 		"OnPlayerPathScientistScanBotCooldown", self)
	Apollo.RegisterEventHandler("Mount", 									"OnMount", self)
	Apollo.RegisterEventHandler("PlayerPathScientistScanBotDeployed", 		"OnPlayerPathScientistScanBotDeployed", self)
	Apollo.RegisterEventHandler("PlayerPathScientistScanBotDespawned", 		"OnPlayerPathScientistScanBotDespawned", self)
	Apollo.RegisterEventHandler("KeyBindingUpdated", 						"OnKeyBindingUpdated", self)
	Apollo.RegisterEventHandler("SubZoneChanged", 							"OnSubZoneChanged", self)
	Apollo.RegisterEventHandler("ChangeWorld", 								"OnChangeWorld", self)
	Apollo.RegisterEventHandler("SoldierHoldoutEnd", 						"OnSoldierHoldoutEnd", self)
	Apollo.RegisterEventHandler("SoldierHoldoutStatus", 					"OnSoldierHoldoutStatus", self)
	Apollo.RegisterEventHandler("SoldierHoldoutNextWave", 					"OnSoldierHoldoutNextWave", self)
	Apollo.RegisterTimerHandler("SoldierResultTimeout", 					"OnSoldierResultTimeout", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor",					"OnTutorial_RequestUIAnchor", self)
	
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "MissionList", wndForm, self)
	self:PathTrackerSetup()
end

function PathTracker:PathTrackerSetup()
	local ePathType = PlayerPathLib.GetPlayerPathType()
	if ePathType == nil then
		return
	end
	if self.ePathType ~= nil and self.ePathType ~= ePathType then
		local tData =
		{
			["strAddon"] = Apollo.GetString(ktPathType[self.ePathType].strNameEnum),
		}
		Event_FireGenericEvent("ObjectiveTracker_RemoveAddOn", tData)
	end
	
	self.wndMain:DestroyChildren()

	self.wndContainer = Apollo.LoadForm(self.xmlDoc, "Container", self.wndMain, self)
	local wndContent = self.wndContainer:FindChild("Content")
	self.wndActiveHeader = Apollo.LoadForm(self.xmlDoc, "Category", wndContent, self)
	self.wndActiveContent = self.wndActiveHeader:FindChild("Content")
	self.wndAvailableHeader = Apollo.LoadForm(self.xmlDoc, "Category", wndContent, self)
	self.wndAvailableContent = self.wndAvailableHeader:FindChild("Content")
	
	-- Settler
	self.wndOnGoingHeader = Apollo.LoadForm(self.xmlDoc, "Category", wndContent, self)
	self.wndOnGoingContent = self.wndOnGoingHeader:FindChild("Content")
	
	-- Scientist
	self.wndScanbotHeader = Apollo.LoadForm(self.xmlDoc, "Category", wndContent, self)
	self.wndScanbotContent = Apollo.LoadForm(self.xmlDoc, "ScanbotContent", self.wndScanbotHeader:FindChild("Content"), self)
	local nLeft, nTop, nRight, nBottom = self.wndScanbotHeader:GetAnchorOffsets()
	self.wndScanbotHeader:SetAnchorOffsets(nLeft, nTop, nRight, nTop + self.knInitialCategoryHeight + self.wndScanbotContent:GetHeight())
	self.wndCheckList = Apollo.LoadForm(self.xmlDoc, "ScientistChecklistContainer", nil, self)
	
	-- Solider
	self.wndHoldoutResult = Apollo.LoadForm(self.xmlDoc, "HoldoutResult", "FixedHudStratum", self)
	
	local tData =
	{
		["strAddon"] = Apollo.GetString(ktPathType[ePathType].strNameEnum),
		["strEventMouseLeft"] = "ToggleShowPathMissions", 
		["strEventMouseRight"] = "ToggleShowPathOptions",
		["strIcon"] = ktPathType[ePathType].strIcon,
		["strDefaultSort"] = kstrPathQuesttMarker,
	}
	
	self.wndContainer:FindChild("ControlBacker:Title"):SetText(String_GetWeaselString(Apollo.GetString("PathTracker_PathTypeTitle"), Apollo.GetString(ktPathType[ePathType].strNameEnum)))
	
	Event_FireGenericEvent("ObjectiveTracker_NewAddOn", tData)
	
	self:BuildAll()
	self:ResizeAll()
	
	if self.bFilterDistance then
		self.timerRealTimeUpdate:Start()
	end
	
	local pepEpisode = PlayerPathLib.GetCurrentEpisode()
	if pepEpisode then
		local tFullMissionList = pepEpisode:GetMissions()
		for idx, pmCurrMission in pairs(tFullMissionList) do
			if pmCurrMission:GetMissionState() == PathMission.PathMissionState_Started then
				local seHoldout = pmCurrMission:GetSoldierHoldout()
				if seHoldout then
					Event_FireGenericEvent("LoadSoldierMission", seHoldout)
				end
			end
		end
	end
	
	self.ePathType = ePathType
end

---------------------------------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------------------------------

function PathTracker:OnRapidDistanceCheckTimer(nTime)
	for idMission, tRapidDistanceCheck in pairs(self.tRapidDistanceChecks) do
		local eType = tRapidDistanceCheck.eType
		local pmMission = tRapidDistanceCheck.pmMission
	
		if eType == PathMission.PathMissionType_Explorer_ExploreZone then
			local wndMission = self.tMissionWndCache[pmMission:GetId()]
			local strPercent = self:HelperComputeProgressText(eType, pmMission) or ""
			local strMissionType = ktDisplayTypes[pmMission:GetDisplayType()]
			
			if string.len(strPercent) > 0 then
				strMissionType = String_GetWeaselString(Apollo.GetString("ExplorerMissions_PercentSubtitle"),  strPercent, strMissionType)
			end
			
			local wndListItemSubtitle = wndMission:FindChild("ListItemSubtitle")
			if wndListItemSubtitle then
				wndListItemSubtitle:SetAML(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffffffff\">%s</P>", strMissionType))
			end
		else
			local nProgressBar = 0
			local wndListItemMeterBG = tRapidDistanceCheck.wndListItemMeterBG
			local wndListItemMeter = tRapidDistanceCheck.wndListItemMeter
			local wndListItemCompleteBtn = tRapidDistanceCheck.wndListItemCompleteBtn
			
			wndListItemMeterBG:Show(nProgressBar > 0)
			wndListItemMeter:SetProgress(nProgressBar)
			wndListItemMeter:EnableGlow(nProgressBar > 0)
			wndListItemCompleteBtn:Show(nProgressBar >= 1)

			if eType == PathMission.PathMissionType_Explorer_PowerMap
				or eType == PathMission.PathMissionType_Explorer_Area
				or eType == PathMission.PathMissionType_Explorer_Vista
				or eType == PathMission.PathMissionType_Explorer_ScavengerHunt then

				local tExplorerNodeInfo = pmMission:GetExplorerNodeInfo()
				if tExplorerNodeInfo ~= nil then
					nProgressBar = tExplorerNodeInfo.fRatio
				end
			elseif eType == PathMission.PathMissionType_Settler_Scout then

				local tInfo = pmMission:GetSettlerScoutInfo()
				if tInfo ~= nil then
					nProgressBar = tInfo.fRatio
				end
			end
		end
	end
	
	if next(self.tRapidDistanceChecks) == nil then
		self.timerRapidDistanceCheck:Stop()
	end
end

function PathTracker:OnRealTimeUpdateTimer(nTime)
	if self.wndMain == nil or not self.wndMain:IsValid() or self.ePathType == nil then
		return
	end

	if self.ePathType == PlayerPathLib.PlayerPathType_Explorer or self.ePathType == PlayerPathLib.PlayerPathType_Settler then
		for idMission, wndMission in pairs(self.tMissionWndCache) do
			local pmMission = wndMission:GetData()
			local wndParent = nil

			if pmMission then
				if self.wndOnGoingHeader ~= nil and self.wndOnGoingHeader:IsValid()
					and self.bToggleOnGoingProjects
					and pmMission:GetType() == PathMission.PathMissionType_Settler_Infrastructure and pmMission:IsComplete() then
					
					wndParent = self.wndOnGoingContent
				elseif self:HelperMissionHasPriority(pmMission) then
					wndParent = self.wndActiveContent
				else
					wndParent = self.wndAvailableContent
				end
				
				if wndMission ~= nil and wndMission:IsValid() and wndMission:GetParent() ~= wndParent then
					self:BuildMission(pmMission)
					self.timerResizeDelay:Start()
				end
			end
		end
	end
	
	if not self.bFilterDistance then
		-- Runners
		for idx, v in pairs(self.tNewMissions) do -- run our "new pmMission" table
			v.nCount = v.nCount + 1 -- iterate the nCount on all
		
			if v.nCount >= knNewMissionRunnerTimeout then -- if beyond max pulse nCount, remove.
				local wnd = self.wndMain:FindChildByUserData(v.pmMission)
				if wnd ~= nil then
					wnd:FindChild("ListItemNewRunner"):Show(false) -- redundant hiding to ensure it's gone
				end
				table.remove(self.tNewMissions, idx)
			else -- show runner
				local wnd = self.wndMain:FindChildByUserData(v.pmMission)
				if wnd ~= nil then
					wnd:FindChild("ListItemNewRunner"):Show(true)
				end
			end
		end
		
		-- Resize
		if self.wndMain ~= nil and self.wndMain:IsValid() then
			self:ResizeAll()
		end
	end
end

function PathTracker:OnResizeDelayTimer(nTime)
	if self.wndMain ~= nil and self.wndMain:IsValid() then
		self:ResizeAll()
	end
end

function PathTracker:BuildAll()
	for idx, pepEpisode in ipairs(PlayerPathLib.GetEpisodes()) do
		for idx, pmMission in ipairs(pepEpisode:GetMissions()) do
			if not pmMission:IsComplete() or pmMission:GetType() == PathMission.PathMissionType_Settler_Infrastructure then
				self:BuildMission(pmMission)
			end
		end
	end

	self:BuildScanbot()
end

function PathTracker:GetDistance(pmMission)
	local nDistance = self.tDistanceCache[pmMission:GetId()]
	if nDistance == nil then
		nDistance = pmMission:GetDistance()
		self.tDistanceCache[pmMission:GetId()] = nDistance
	end
	
	return nDistance
end

function PathTracker:ResizeAll()
	self.timerResizeDelay:Stop()
	self.tDistanceCache = {}
	
	local ePathType = PlayerPathLib.GetPlayerPathType()
	
	local nStartingHeight = self.wndMain:GetHeight()
	
	-- Inline sort method
	local function SortMissionItems(pmData1, pmData2)
		local bQuestTrackerByDistance = g_InterfaceOptions and g_InterfaceOptions.Carbine.bQuestTrackerByDistance
		
		if self:HelperMissionHasPriority(pmData1) and self:HelperMissionHasPriority(pmData2) then
			if bQuestTrackerByDistance then
				return self:GetDistance(pmData1) < self:GetDistance(pmData2)
			else
				return pmData1:GetName() < pmData2:GetName() 
			end
		elseif self:HelperMissionHasPriority(pmData1) then
			return true
		elseif self:HelperMissionHasPriority(pmData2) then
			return false
		elseif bQuestTrackerByDistance then
			return self:GetDistance(pmData1) < self:GetDistance(pmData2)
		else
			return pmData1:GetName() < pmData2:GetName()
		end
	end
	
	local arMissions = {}
	
	local pepCurrentEpisode = PlayerPathLib.GetCurrentEpisode()
	for idx, pepEpisode in ipairs(PlayerPathLib.GetEpisodes()) do
		local bInZone = pepCurrentEpisode == pepEpisode
		
		if self.bShowOutOfZone or pepCurrentEpisode == pepEpisode then
			for idx, pmMission in ipairs(pepEpisode:GetMissions()) do
				table.insert(arMissions, pmMission)
			end
		end
	end
	
	table.sort(arMissions, SortMissionItems)
	
	-- Counting and filtering
	local tDisplayedMissions = {}
	local nFilteredMissions = 0
	local nActiveMissionCount = 0
	local nRemainingMissions = 0
	local nAvailableMissionCount = 0
	local nCompleteMissionsCount = 0
	
	for idx, pmMission in pairs(arMissions) do
		if pmMission:GetMissionState() == PathMission.PathMissionState_NoMission then
			nRemainingMissions = nRemainingMissions + 1
			
		elseif pmMission:GetType() == PathMission.PathMissionType_Settler_Infrastructure and pmMission:IsComplete() then
			nCompleteMissionsCount = nCompleteMissionsCount + 1
			tDisplayedMissions[pmMission:GetId()] = self.bToggleOnGoingProjects
			
		elseif not pmMission:IsComplete() then
			if (not self.bFilterLimit or nFilteredMissions < self.nMaxMissionLimit) and (not self.bFilterDistance or self:GetDistance(pmMission) < self.nMaxMissionDistance or pmMission:GetType() == PathMission.PathMissionType_Explorer_ExploreZone) then
				nFilteredMissions = nFilteredMissions + 1
				
				if self:HelperMissionHasPriority(pmMission) then
					nActiveMissionCount = nActiveMissionCount + 1
				else
					nAvailableMissionCount = nAvailableMissionCount + 1
				end
				
				tDisplayedMissions[pmMission:GetId()] = true
			end
			
		end
	end
	
	for idMission, wndMission in pairs(self.tMissionWndCache) do
		wndMission:Show(tDisplayedMissions[idMission])
	end
	
	local bShouldShow = self.bShowPathMissions and (next(tDisplayedMissions) ~= nil or ePathType == PlayerPathLib.PlayerPathType_Scientist)
	local bHideAllChanging = bShouldShow ~= self.wndMain:IsShown()
	if bShouldShow then
		local nContainerHeight = 0
	
		if not self.bMinimized then
			local wndActiveMinimizeBtn = self.wndActiveHeader:FindChild("MinimizeBtn")
			wndActiveMinimizeBtn:SetCheck(self.bMinimizedActive)
			wndActiveMinimizeBtn:Show(self.bMinimizedActive or wndActiveMinimizeBtn:ContainsMouse())
			self.wndActiveHeader:Show(nActiveMissionCount > 0)
			self:ResizeCategory(self.wndActiveHeader)
			
			local wndAvailableMinimizeBtn = self.wndAvailableHeader:FindChild("MinimizeBtn")
			wndAvailableMinimizeBtn:SetCheck(self.bMinimizedAvailable)
			wndAvailableMinimizeBtn:Show(self.bMinimizedAvailable or wndAvailableMinimizeBtn:ContainsMouse())
			self.wndAvailableHeader:Show(nAvailableMissionCount > 0)
			self:ResizeCategory(self.wndAvailableHeader)
			
			if self.wndOnGoingHeader ~= nil and self.wndOnGoingHeader:IsValid() then
				local wndOnGoingMinimizeBtn = self.wndOnGoingHeader:FindChild("MinimizeBtn")
				wndOnGoingMinimizeBtn:SetCheck(self.bMinimizedOnGoing)
				wndOnGoingMinimizeBtn:Show(self.bMinimizedOnGoing or wndOnGoingMinimizeBtn:ContainsMouse())
				local bShowOnGoing = ePathType == PlayerPathLib.PlayerPathType_Settler and nCompleteMissionsCount > 0
				self.wndOnGoingHeader:Show(bShowOnGoing)
				if bShowOnGoing then
					self:ResizeCategory(self.wndOnGoingHeader)
				end
			end
			
			if self.wndScanbotHeader ~= nil and self.wndScanbotHeader:IsValid() then
				local wndScanbotMinimizeBtn = self.wndScanbotHeader:FindChild("MinimizeBtn")
				wndScanbotMinimizeBtn:SetCheck(self.bMinimizedScanBot)
				wndScanbotMinimizeBtn:Show(self.bMinimizedScanBot or wndScanbotMinimizeBtn:ContainsMouse())
				local bShowScanbot = ePathType == PlayerPathLib.PlayerPathType_Scientist
				self.wndScanbotHeader:Show(bShowScanbot)
				if bShowScanbot then
					self:ResizeScanbotCategory(self.wndScanbotHeader)
				end
			end
			
			nContainerHeight = self.wndContainer:FindChild("Content"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		end
		
		
		local nNewHeight = nContainerHeight + self.knInitialContainerHeight
		if nNewHeight ~= self.wndMain:GetHeight() then
			local nLeft, nTop, nRight, nBottom = self.wndContainer:GetAnchorOffsets()
			self.wndContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nNewHeight)
			
			local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
			self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nNewHeight)
		end
		
		self.wndMain:Show(true)
	else
		self.wndMain:Show(false)
	end
	
	local nNewMissionCount = nActiveMissionCount + nAvailableMissionCount + nCompleteMissionsCount
	if bHideAllChanging or nStartingHeight ~= self.wndMain:GetHeight() or self.nMissionCount ~= nNewMissionCount then
		if not self.bMinimized then
			-- Count labeling
			local strActiveTitle = nil
			if nActiveMissionCount ~= 1 then
				 strActiveTitle = string.format("%s [%s]", Apollo.GetString("ExplorerMissions_ActiveMissions"), nActiveMissionCount)
			else
				strActiveTitle = Apollo.GetString("ExplorerMissions_ActiveMissions")
			end
			self.wndActiveHeader:FindChild("Title"):SetText(strActiveTitle)
			
			local strAvailableTitle = nil
			if nAvailableMissionCount ~= 1 then
				strAvailableTitle = string.format("%s [%s]", Apollo.GetString("ExplorerMissions_AvailableMissions"), nAvailableMissionCount)
			else
				strAvailableTitle = Apollo.GetString("ExplorerMissions_AvailableMissions")
			end
			self.wndAvailableHeader:FindChild("Title"):SetText(strAvailableTitle)
			
			if self.wndOnGoingHeader ~= nil and self.wndOnGoingHeader:IsValid() then
				local strOnGoingTitle = nil
				if nCompleteMissionsCount ~= 1 then
					strOnGoingTitle = string.format("%s [%s]", Apollo.GetString("SettlerMission_OnGoing"), nCompleteMissionsCount)
				else
					strOnGoingTitle = Apollo.GetString("SettlerMission_OnGoing")
				end
				self.wndOnGoingHeader:FindChild("Title"):SetText(strOnGoingTitle)
			end
		end
		
		
		local tData =
		{
			["strAddon"] = Apollo.GetString(ktPathType[ePathType].strNameEnum),
			["strText"] = nNewMissionCount,
			["bChecked"] = self.bShowPathMissions,
		}
	
		Event_FireGenericEvent("ObjectiveTracker_UpdateAddOn", tData)
	end
	self.nMissionCount = nNewMissionCount
end

function PathTracker:ResizeCategory(wndContainer)
	local wndContent = wndContainer:FindChild("Content")
	local wndMinimize = wndContainer:FindChild("MinimizeBtn")
	
	local nContentHeight = 0
	if wndMinimize and not wndMinimize:IsChecked() then
		for idx, wndMission in pairs(wndContent:GetChildren()) do
			if wndMission:IsShown() then
				self:ResizeMission(wndMission)
			end
		end
		
		nContentHeight = wndContent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		wndContent:Show(true)
	else
		wndContent:Show(false)
	end
	
	local nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	local nNewHeight = nContentHeight + self.knInitialCategoryHeight
	if nNewHeight ~= wndContainer:GetHeight() then
		wndContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nNewHeight)
	end
end

function PathTracker:ResizeScanbotCategory(wndContainer)
	local wndContent = wndContainer:FindChild("Content")
	local wndMinimize = wndContainer:FindChild("MinimizeBtn")
	
	local nContentHeight = 0
	if wndMinimize and not wndMinimize:IsChecked() then		
		nContentHeight = wndContent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		wndContent:Show(true)
	else
		wndContent:Show(false)
	end
	
	local nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	local nNewHeight = nContentHeight + self.knInitialCategoryHeight
	if nNewHeight ~= wndContainer:GetHeight() then
		wndContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nNewHeight)
	end
end

function PathTracker:DestroyMission(pmMission)
	local wndMission = self.tMissionWndCache[pmMission:GetId()]
	if wndMission ~= nil and wndMission:IsValid() then
		wndMission:Destroy()
	end
	
	self.tMissionWndCache[pmMission:GetId()] = nil
	self.tRapidDistanceChecks[pmMission:GetId()] = nil
end

function PathTracker:BuildMission(pmMission)
	local wndParent = nil

	if self.wndOnGoingHeader ~= nil and self.wndOnGoingHeader:IsValid()
		and self.bToggleOnGoingProjects
		and pmMission:GetType() == PathMission.PathMissionType_Settler_Infrastructure and pmMission:IsComplete() then
		
		wndParent = self.wndOnGoingContent
	elseif self:HelperMissionHasPriority(pmMission) then
		wndParent = self.wndActiveContent
	else
		wndParent = self.wndAvailableContent
	end

	local wndMission = self.tMissionWndCache[pmMission:GetId()]
	if wndMission ~= nil and wndMission:IsValid() and wndMission:GetParent() ~= wndParent then
		wndMission:Destroy()
	end
	if wndMission == nil or not wndMission:IsValid() then
		wndMission = Apollo.LoadForm(self.xmlDoc, "ListItem", wndParent, self)
		self.tMissionWndCache[pmMission:GetId()] = wndMission
	end
	
	wndMission:SetData(pmMission)
	wndMission:FindChild("ListItemMeter"):SetMax(1)
	wndMission:FindChild("ListItemCompleteBtn"):SetData(pmMission)
	
	self:HelperSelectInteractHintArrowObject(pmMission, wndMission:FindChild("ListItemBigBtn"))
	wndMission:FindChild("ListItemCodexBtn"):SetData(pmMission)
	wndMission:FindChild("ListItemSubscreenBtn"):SetData(pmMission)
	wndMission:FindChild("ListItemMouseCatcher"):SetData(pmMission)

	local strMissionName = pmMission:GetName()
	local eMissionType = pmMission:GetType()
	local strMissionType = ktDisplayTypes[pmMission:GetDisplayType()]
	if strMissionType == nil then
		strMissionType = ""
	end
	
	local wndListItemBigBtn = wndMission:FindChild("ListItemBigBtn")
	wndListItemBigBtn:SetData(pmMission)
	wndListItemBigBtn:SetText(GameLib.GetKeyBinding("Interact").." >")
	wndListItemBigBtn:SetTooltip(pmMission:GetSummary() or "")
	
	
	wndMission:FindChild("ListItemIcon"):SetSprite(ktMissionTypeIcons[eMissionType])
	wndMission:FindChild("ListItemName"):SetAML("<P Font=\"CRB_InterfaceMedium_B\" TextColor=\""..kstrLightGrey.."\">"..strMissionName.."</P>")
	wndMission:FindChild("ListItemName"):SetHeightToContentHeight()

	-- Has Mouse
	local bHasMouse = wndMission:FindChild("ListItemMouseCatcher"):ContainsMouse()
	wndMission:FindChild("ListItemCodexBtn"):Show(bHasMouse)
	wndMission:FindChild("ListItemHintArrowArt"):Show(bHasMouse)
	wndMission:FindChild("ListItemIcon"):SetBGColor(bHasMouse and "44ffffff" or "ffffffff")

	-- Mission specific formatting
	local nProgressBar = 0
	local bShowSubscreenBtn = false
	local eType = pmMission:GetType()
	local strIcon = ""

	local wndListItemMeterBG = wndMission:FindChild("ListItemMeterBG")
	local wndListItemMeter = wndMission:FindChild("ListItemMeter")
	local wndListItemCompleteBtn = wndMission:FindChild("ListItemCompleteBtn")
	
	if eType == PathMission.PathMissionType_Explorer_PowerMap then
		bShowSubscreenBtn = self:HelperMissionHasPriority(pmMission)
		
		if pmMission:GetExplorerNodeInfo() ~= nil then
			nProgressBar = pmMission:GetExplorerNodeInfo().fRatio
		end
		
		wndListItemMeterBG:Show(nProgressBar > 0)
		wndListItemMeter:SetProgress(nProgressBar)
		wndListItemMeter:EnableGlow(nProgressBar > 0)
		wndListItemCompleteBtn:Show(nProgressBar >= 1)
		strIcon = ktMissionTypeIcons[eType]
		
		if wndParent == self.wndActiveContent then
			self.tRapidDistanceChecks[pmMission:GetId()] = 
			{
				eType = eType,
				pmMission = pmMission,
				wndListItemMeterBG = wndListItemMeterBG,
				wndListItemMeter = wndListItemMeter,
				wndListItemCompleteBtn = wndListItemCompleteBtn,
			}
			self.timerRapidDistanceCheck:Start()
		else
			self.tRapidDistanceChecks[pmMission:GetId()] = nil
		end
		
	elseif eType == PathMission.PathMissionType_Explorer_Area
		or eType == PathMission.PathMissionType_Explorer_Vista then
		bShowSubscreenBtn = true
		
		if pmMission:GetExplorerNodeInfo() ~= nil then
			nProgressBar = pmMission:GetExplorerNodeInfo().fRatio
		end
		
		wndListItemMeterBG:Show(nProgressBar > 0)
		wndListItemMeter:SetProgress(nProgressBar)
		wndListItemMeter:EnableGlow(nProgressBar > 0)
		wndListItemCompleteBtn:Show(nProgressBar >= 1)
		strIcon = ktMissionTypeIcons[eType]
		
		if wndParent == self.wndActiveContent then
			self.tRapidDistanceChecks[pmMission:GetId()] = 
			{
				eType = eType,
				pmMission = pmMission,
				wndListItemMeterBG = wndListItemMeterBG,
				wndListItemMeter = wndListItemMeter,
				wndListItemCompleteBtn = wndListItemCompleteBtn,
			}
			self.timerRapidDistanceCheck:Start()
		else
			self.tRapidDistanceChecks[pmMission:GetId()] = nil
		end
		
	elseif eType == PathMission.PathMissionType_Explorer_ScavengerHunt then
		bShowSubscreenBtn = pmMission:IsStarted()
		
		if bShowSubscreenBtn then
			for idx = 0, pmMission:GetNumNeeded() - 1 do
				if pmMission:GetExplorerClueRatio(idx) > nProgressBar then
					nProgressBar = pmMission:GetExplorerClueRatio(idx)
				end
			end
		end
		
		if pmMission:GetExplorerNodeInfo() ~= nil then
			nProgressBar = pmMission:GetExplorerNodeInfo().fRatio
		end
		
		wndListItemMeterBG:Show(nProgressBar > 0)
		wndListItemMeter:SetProgress(nProgressBar)
		wndListItemMeter:EnableGlow(nProgressBar > 0)
		wndListItemCompleteBtn:Show(nProgressBar >= 1)
		strIcon = ktMissionTypeIcons[eType]
		
		if wndParent == self.wndActiveContent then
			self.tRapidDistanceChecks[pmMission:GetId()] = 
			{
				eType = eType,
				pmMission = pmMission,
				wndListItemMeterBG = wndListItemMeterBG,
				wndListItemMeter = wndListItemMeter,
				wndListItemCompleteBtn = wndListItemCompleteBtn,
			}
			self.timerRapidDistanceCheck:Start()
		else
			self.tRapidDistanceChecks[pmMission:GetId()] = nil
		end
		
	elseif eType == PathMission.PathMissionType_Explorer_ExploreZone then
		strIcon = ktMissionTypeIcons[eType]
		self.tRapidDistanceChecks[pmMission:GetId()] = 
		{
			eType = eType,
			pmMission = pmMission,
			wndListItemMeterBG = wndListItemMeterBG,
			wndListItemMeter = wndListItemMeter,
			wndListItemCompleteBtn = wndListItemCompleteBtn,
		}
	elseif eType == PathMission.PathMissionType_Settler_Scout then
		local tInfo = pmMission:GetSettlerScoutInfo()
		if tInfo then
			local bProgressShown = tInfo.fRatio > 0
			wndListItemMeterBG:Show(bProgressShown)
			wndListItemMeter:SetMax(1)
			wndListItemMeter:SetProgress(tInfo.fRatio, knRate)
			wndListItemMeter:EnableGlow(tInfo.fRatio > 0)
			wndListItemCompleteBtn:Show(tInfo.fRatio >= 1)
			strIcon = ktMissionTypeIcons[eType]
		else
			wndListItemMeterBG:Show(false)
			wndListItemMeter:SetProgress(0)
			wndListItemMeter:EnableGlow(false)
			wndListItemCompleteBtn:Show(false)
		end

		if wndParent == self.wndActiveContent then
			self.tRapidDistanceChecks[pmMission:GetId()] = 
			{
				eType = eType,
				pmMission = pmMission,
				wndListItemMeterBG = wndListItemMeterBG,
				wndListItemMeter = wndListItemMeter,
				wndListItemCompleteBtn = wndListItemCompleteBtn,
			}
			self.timerRapidDistanceCheck:Start()
		else
			self.tRapidDistanceChecks[pmMission:GetId()] = nil
		end
		
	elseif eType == PathMission.PathMissionType_Settler_Infrastructure then
		local tInfrastructure = PlayerPathLib.GetInfrastructureStatusForMission(pmMission)
		local nCurrent = tInfrastructure.nRemainingTime > 0 and tInfrastructure.nRemainingTime or tInfrastructure.nPercent
		local nMax 	= tInfrastructure.nRemainingTime > 0 and tInfrastructure.nMaxTime or 100
		
		local bProgressShown = tInfrastructure.nPercent > 0 and tInfrastructure.nPercent < 100
		wndMission:FindChild("ListItemProgressBG"):Show(bProgressShown)
		wndMission:FindChild("ListItemProgress"):SetMax(nMax)
		wndMission:FindChild("ListItemProgress"):SetProgress(nCurrent)
		strIcon = ktMissionTypeIcons[eType]
		
	elseif eType == PathMission.PathMissionType_Settler_Mayor
		or eType == PathMission.PathMissionType_Settler_Sheriff then
		
		strIcon = ktMissionTypeIcons[eType]
		
	elseif eType == PathMission.PathMissionType_Scientist_FieldStudy
		or eType == PathMission.PathMissionType_Scientist_SpecimenSurvey
		or eType == PathMission.PathMissionType_Scientist_DatacubeDiscovery then
		
		local nNumCompleted = pmMission:GetNumCompleted()
		
		wndMission:FindChild("ListItemSubscreenBtn"):SetData(pmMission)
		wndMission:FindChild("ListItemMeter"):SetMax(pmMission:GetNumNeeded())
		wndMission:FindChild("ListItemMeter"):SetProgress(nNumCompleted)
		wndMission:FindChild("ListItemSubtitle"):SetAML(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffffffff\">(%s) %s</P>", String_GetWeaselString(Apollo.GetString("CRB_ProgressSimple"), nNumCompleted, pmMission:GetNumNeeded()), strMissionType))
		strIcon = ktMissionTypeIcons[eType]
		if strIcon == nil then
			strIcon = pmMission:GetScientistIcon()
		end
		
		self:PopulateChecklistContainer(self.wndCheckList:GetData())
	elseif eType == PathMission.PathMissionType_Scientist_Scan
		or eType == PathMission.PathMissionType_Scientist_ScanChecklist then
		
		local nNumCompleted = pmMission:GetNumCompleted()
		
		wndMission:FindChild("ListItemMeter"):SetMax(pmMission:GetNumNeeded())
		wndMission:FindChild("ListItemMeter"):SetProgress(nNumCompleted)
		wndMission:FindChild("ListItemSubtitle"):SetAML(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffffffff\">(%.0f%%) %s</P>", nNumCompleted, strMissionType))

		local eSubType = pmMission:GetSubType()
		strIcon = ktMissionSubTypeIcons[eSubType]
	
	elseif eType == PathMission.PathMissionType_Scientist_Script
		or eType == PathMission.PathMissionType_Scientist_Experimentation then
		
		local nNumCompleted = pmMission:GetNumCompleted()
		
		wndMission:FindChild("ListItemMeter"):SetMax(pmMission:GetNumNeeded())
		wndMission:FindChild("ListItemMeter"):SetProgress(nNumCompleted)
		wndMission:FindChild("ListItemSubtitle"):SetAML(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffffffff\">(%.0f%%) %s</P>", nNumCompleted, strMissionType))
		strIcon = ktMissionTypeIcons[eType]
		if strIcon == nil then
			strIcon = pmMission:GetScientistIcon()
		end
	
	elseif eType == PathMission.PathMissionType_Soldier_Demolition
		or eType == PathMission.PathMissionType_Soldier_Assassinate
		or eType == PathMission.PathMissionType_Soldier_Rescue
		or eType == PathMission.PathMissionType_Soldier_SWAT
		or eType == PathMission.PathMissionType_Soldier_Script
		or eType == PathMission.PathMissionType_Soldier_Holdout then
		
		local splSpell = pmMission:GetSpell()
		if splSpell ~= nil then
			local wndListItemSpell = wndMission:FindChild("ListItemSpell")
			wndListItemSpell:Show(true)
			wndListItemSpell:SetContentId(pmMission)
		end
		
		strIcon = ktMissionTypeIcons[eType]
		if strIcon == nil then
			local eSubType = pmMission:GetSubType()
			strIcon = ktMissionSubTypeIcons[eSubType]
		end
		
	end
	
	-- Icon
	wndMission:FindChild("ListItemIcon"):SetSprite(strIcon)
	
	-- Subtitle
	local strPercent = self:HelperComputeProgressText(eType, pmMission) or ""
	if Apollo.StringLength(strPercent) > 0 then
		strMissionType = String_GetWeaselString(Apollo.GetString("ExplorerMissions_PercentSubtitle"),  strPercent, strMissionType)
	end
	
	local wndListItemSubtitle = wndMission:FindChild("ListItemSubtitle")
	wndListItemSubtitle:SetAML(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffffffff\">%s</P>", strMissionType))
	wndListItemSubtitle:SetHeightToContentHeight()
end

function PathTracker:ResizeMission(wndMission)
	local wndHeightStack = wndMission:FindChild("HeightStack")
	
	local wndBars = wndHeightStack:FindChild("Bars")
	wndBars:Show(wndBars:FindChild("ListItemMeterBG"):IsShown() or wndBars:FindChild("ListItemProgressBG"):IsShown())
	
	local nHeight = wndHeightStack:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	nHeight = math.max(self.knInitialListItemHeight, nHeight)
	
	-- Combine
	if nHeight ~= wndMission:GetHeight() then
		local nLeft, nTop, nRight, nBottom = wndMission:GetAnchorOffsets()
		wndMission:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
	end
end

function PathTracker:BuildScanbot()
	if self.wndScanbotContent == nil or not self.wndScanbotContent:IsValid() then
		return
	end
	
	local bHasBot = PlayerPathLib.ScientistHasScanBot()
	local bIsMounted = true
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer ~= nil and unitPlayer:IsValid() then
		bIsMounted = unitPlayer:IsMounted()
	end
	
	local strKeybind = GameLib.GetKeyBinding("PathAction")
	local strScanBinding = strKeybind == "<Unbound>" and "" or "("..strKeybind..")" or ""
	local strAction = nil
	if bHasBot then
		strAction = String_GetWeaselString(Apollo.GetString("ScientistMission_ScanBtn"), strScanBinding)
	else
		strAction = string.format("%s %s", Apollo.GetString("ScientistMission_Summon"), strScanBinding)
	end

	local strTitle = string.format("%s: %s", Apollo.GetString("ScientistMission_ScanBot"), strAction)
	self.wndScanbotHeader:FindChild("Title"):SetText(strTitle)
	
	self.wndScanbotContent:FindChild("SciScanBtn"):Show(bHasBot)
	self.wndScanbotContent:FindChild("SciProfileSummonBtn"):Enable(not bIsMounted and not self.wndScanbotContent:FindChild("BotCooldownBar"):IsShown())

	self.wndScanbotContent:FindChild("SciLocateBtn"):Show(bHasBot)
	self.wndScanbotContent:FindChild("SciConfigureBtn"):Show(bHasBot)
end

function PathTracker:OnSummonBotMouseEnter(wndHandler, wndControl)
	if PlayerPathLib.ScientistHasScanBot() then
		self.wndScanbotContent:FindChild("SciProfileSummonBtn"):SetTooltip(Apollo.GetString("ScientistMission_Dismiss"))
	else
		self.wndScanbotContent:FindChild("SciProfileSummonBtn"):SetTooltip(Apollo.GetString("ScientistMission_Summon"))
	end
end

function PathTracker:OnSummonBotMouseExit(wndHandler, wndControl)
	wndHandler:SetText("")
end

function PathTracker:OnScanBtn()
	if self.ePathType == PlayerPathLib.PlayerPathType_Scientist then
		PlayerPathLib.PathAction()
	end
end

function PathTracker:OnLocateBtn()
	local unitScanbot = PlayerPathLib:ScientistGetScanBotUnit()
	if unitScanbot ~= nil and unitScanbot:IsValid() then
		unitScanbot:ShowHintArrow()
	end
end

function PathTracker:OnOpenConfigureScreenBtn()
	Event_FireGenericEvent("GenericEvent_ToggleScanBotCustomize")
end

function PathTracker:OnSummonBotBtn(wndHandler, wndControl)
	if PlayerPathLib.ScientistHasScanBot() then
		self.wndScanbotContent:FindChild("SciProfileSummonBtn"):SetTooltip(Apollo.GetString("ScientistMission_Summon"))
	else
		self.wndScanbotContent:FindChild("SciProfileSummonBtn"):SetTooltip(Apollo.GetString("ScientistMission_Dismiss"))
	end

	PlayerPathLib.ScientistToggleScanBot()
end

---------------------------------------------------------------------------------------------------
-- Field Study
---------------------------------------------------------------------------------------------------

function PathTracker:PopulateChecklistContainer(pmStudy)
	if not pmStudy then
		return
	end

	local tTableToUse = nil -- The two tables are set up the exact same
	local eMissionType = pmStudy:GetType()
	if eMissionType == PathMission.PathMissionType_Scientist_FieldStudy then
		tTableToUse = pmStudy:GetScientistFieldStudy()
	elseif eMissionType == PathMission.PathMissionType_Scientist_SpecimenSurvey then
		tTableToUse = pmStudy:GetScientistSpecimenSurvey()
	else
		return
	end
	
	local wndChecklistItemContainer = self.wndCheckList:FindChild("ChecklistItemContainer")

	local bAllItemsCompleted = true
	for idx, tDataTable in pairs(tTableToUse) do
		if tDataTable then
			local wndCurr = self.tChecklistWndCache[tDataTable.strName]
			if wndCurr == nil or not wndCurr:IsValid() then
				wndCurr = Apollo.LoadForm(self.xmlDoc, "ScientistChecklistItem", wndChecklistItemContainer, self)
				self.tChecklistWndCache[tDataTable.strName] = wndCurr
			end
			
			if tDataTable.strName then
				wndCurr:FindChild("ChecklistItemName"):SetText(tDataTable.strName)
			end

			if tDataTable.bIsCompleted then
				wndCurr:FindChild("ChecklistCompleteCheck"):SetSprite("kitIcon_Complete")
			elseif eMissionType == PathMission.PathMissionType_Scientist_FieldStudy then
				wndCurr:FindChild("ScientistChecklistItemBtn"):Show(true)
				wndCurr:FindChild("ScientistChecklistItemBtn"):SetData({ pmStudy, idx })
				local strSprite = ktFieldStudySubType[tDataTable.eBehavior]
				if strSprite == nil then
					strSprite = "kitIcon_InProgress"
				end
				wndCurr:FindChild("ChecklistCompleteCheck"):SetSprite(strSprite)
				bAllItemsCompleted = false
			elseif eMissionType == PathMission.PathMissionType_Scientist_SpecimenSurvey then
				wndCurr:FindChild("ScientistChecklistItemBtn"):Show(true)
				wndCurr:FindChild("ScientistChecklistItemBtn"):SetData({ pmStudy, idx })
				wndCurr:FindChild("ChecklistCompleteCheck"):SetSprite("kitIcon_InProgress")
				bAllItemsCompleted = false
			end
		end
	end

	self.wndCheckList:SetData(pmStudy)
	self.wndCheckList:FindChild("ChecklistTitle"):SetText(pmStudy:GetName())
	wndChecklistItemContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	if bAllItemsCompleted then
		self:OnCollapseChecklistClick()
	end
end

function PathTracker:OnScientistChecklistItemBtn(wndHandler, wndControl)
	local tMissionData = wndHandler:GetData()
	if tMissionData == nil then
		return
	end
	
	local pmMission = tMissionData[1]
	local nIndex = tMissionData[2]

	pmMission:ShowPathChecklistHintArrow(nIndex)
end

function PathTracker:OnCollapseChecklistClick()
	self.wndCheckList:FindChild("ChecklistItemContainer"):DestroyChildren()
	self.tChecklistWndCache = {}
	self.wndCheckList:Close()
end

---------------------------------------------------------------------------------------------------
-- Game Events
---------------------------------------------------------------------------------------------------

function PathTracker:OnSetPlayerPath()
	local ePathType = PlayerPathLib.GetPlayerPathType()
	if ePathType ~= self.ePathType then
		self:PathTrackerSetup()
	else
		self:BuildAll()
		self.timerResizeDelay:Start()
	end
end

function PathTracker:OnPlayerPathRefresh()
	local ePathType = PlayerPathLib.GetPlayerPathType()
	if ePathType ~= self.ePathType then
		self:PathTrackerSetup()
	else
		self:BuildAll()
		self.timerResizeDelay:Start()
	end
end

function PathTracker:OnPlayerPathMissionActivate(pmMission)
	self:BuildMission(pmMission)
	self.timerResizeDelay:Start()
end

function PathTracker:OnPlayerPathMissionAdvanced(pmMission)
	self:BuildMission(pmMission)
	self.timerResizeDelay:Start()
end

function PathTracker:OnPlayerPathMissionComplete(pmMission)
	self:BuildMission(pmMission)
	self.timerResizeDelay:Start()
end

function PathTracker:OnPlayerPathMissionDeactivate(pmMission)
	self:BuildMission(pmMission)
	self.timerResizeDelay:Start()
end

function PathTracker:OnPlayerPathMissionUnlocked(pmMission)
	self:BuildMission(pmMission)
	self.timerResizeDelay:Start()
end

function PathTracker:OnPlayerPathMissionUpdate(pmMission)
	self:BuildMission(pmMission)
	self.timerResizeDelay:Start()
end

function PathTracker:OnPlayerPathExplorerPowerMapEntered(pmMission)
	self:BuildMission(pmMission)
	self.timerResizeDelay:Start()
end

function PathTracker:OnPlayerPathExplorerPowerMapExited(pmMission)
	self:BuildMission(pmMission)
	self.timerResizeDelay:Start()
end

function PathTracker:OnPlayerPathExplorerPowerMapFailed(pmMission)
	self:BuildMission(pmMission)
	self.timerResizeDelay:Start()
end

function PathTracker:OnPlayerPathExplorerPowerMapStarted(pmMission, unit)
	self:BuildMission(pmMission)
	self.timerResizeDelay:Start()
end

function PathTracker:OnPlayerPathExplorerPowerMapWaiting(pmMission, nDelay)
	self:BuildMission(pmMission)
	self.timerResizeDelay:Start()
end

function PathTracker:OnPlayerPathExplorerScavengerHuntStarted(pmMission)
	self:BuildMission(pmMission)
	self.timerResizeDelay:Start()
end

function PathTracker:OnScientistScanData(tScannedUnits)
	if not tScannedUnits then
		return
	end
	if PlayerPathLib.GetPlayerPathType() ~= PlayerPathLib.PlayerPathType_Scientist then
		return
	end

    for idx, tScanInfo in ipairs(tScannedUnits) do
        tScanInfo.nDisplayCount = 0
        
		table.insert(self.tScannedItems, tScanInfo)
    end
end

function PathTracker:OnPlayerPathScientistScanBotCooldown(nTime)
	local wndBotCooldownBar = self.wndScanbotContent:FindChild("BotCooldownBar")
	wndBotCooldownBar:Show(true)
	wndBotCooldownBar:SetMax(nTime)
	wndBotCooldownBar:SetProgress(nTime)
	wndBotCooldownBar:SetProgress(0, 1)
	
	local wndSciProfileSummonBtn = self.wndScanbotContent:FindChild("SciProfileSummonBtn")
	wndSciProfileSummonBtn:Enable(false)
	wndSciProfileSummonBtn:SetTooltip(Apollo.GetString("ScientistMission_Summon"))
	
	self.timerScanbotCooldown:Set(nTime, false, false)
	self.timerScanbotCooldown:Start()
end

function PathTracker:OnScanbotTimer(nTime)
	self.wndScanbotContent:FindChild("BotCooldownBar"):Show(false)
	self.wndScanbotContent:FindChild("SciProfileSummonBtn"):Enable(true)
	
	self:BuildScanbot()
end

function PathTracker:OnMount()
	self:BuildScanbot()
end

function PathTracker:OnPlayerPathScientistScanBotDeployed()
	self:BuildScanbot()
end

function PathTracker:OnPlayerPathScientistScanBotDespawned()
	self:BuildScanbot()
end

function PathTracker:OnKeyBindingUpdated()
	self:BuildScanbot()
end

function PathTracker:OnChangeWorld()
	self.timerResizeDelay:Start()
	
	if self.wndHoldoutResult ~= nil and self.wndHoldoutResult:IsValid() then
		self.wndHoldoutResult:Show(false)
	end
end

function PathTracker:OnSubZoneChanged()
	self.timerResizeDelay:Start()
end

function PathTracker:OnSoldierHoldoutEnd(seArgEvent, eReason)
	local strReason = ""
	local strResult = ""
	local strResultColor = ""
	
	if eReason == PathMission.PlayerPathSoldierResult_Success then	
		Sound.Play(Sound.PlayUISoldierHoldoutAchieved)
		strResult =  Apollo.GetString("CRB_VICTORY")
		strResultColor = CColor.new(132/255, 1, 0, 1)
		
		local tWaveInfo = { ["count"] = seArgEvent:GetWaveCount(), ["name"] = Apollo.GetString("CRB_Wave") }

		local eType = seArgEvent:GetType()
		if eType == PathMission.PathSoldierEventType_Holdout then
			strReason = String_GetWeaselString(Apollo.GetString("CRB_Youve_taken_the_control_of_the_Holdout"), tWaveInfo)

		elseif ktSoldierEventTypeToVictoryMessage[eType] == "wavedefense" then
			strReason = String_GetWeaselString(Apollo.GetString("CRB_You_maintained_a_successful_defense_"), tWaveInfo)

		elseif ktSoldierEventTypeToVictoryMessage[eType] == "timed" then
			strReason = String_GetWeaselString(Apollo.GetString("CRB_You_defended_yourself_for_"), ConvertSecondsToTimer(seArgEvent:GetMaxTime() / 1000))
		end
	else
		Sound.Play(Sound.PlayUISoldierHoldoutFailed)
		strResult =  Apollo.GetString("CRB_Holdout_Failed")
		strResultColor = CColor.new(209/255, 0, 0, 1)
		strReason = Apollo.GetString(ktSoliderFailReasonStrings[eReason])
	end

	self.wndHoldoutResult:Show(true)
	self.wndHoldoutResult:FindChild("ResultText"):SetTextColor(strResultColor)
	self.wndHoldoutResult:FindChild("ResultText"):SetText(strResult)
	self.wndHoldoutResult:FindChild("ReasonText"):SetText(strReason)

	self.timeSoldierResultTimeout:Start()
end

function PathTracker:OnSoldierResultTimeoutTimer(nTime)
	if self.wndHoldoutResult ~= nil and self.wndHoldoutResult:IsValid() then
		self.wndHoldoutResult:Show(false)
	end
end

function PathTracker:OnSoldierHoldoutStatus()
	if self.wndHoldoutResult ~= nil and self.wndHoldoutResult:IsValid() then
		self.wndHoldoutResult:Show(false)
	end
end

function PathTracker:OnSoldierHoldoutNextWave()
	if self.wndHoldoutResult ~= nil and self.wndHoldoutResult:IsValid() then
		self.wndHoldoutResult:Show(false)
	end
end

function PathTracker:OnSoldierResultTimeout()
	if self.wndHoldoutResult ~= nil and self.wndHoldoutResult:IsValid() then
		self.wndHoldoutResult:Show(false)
	end
end

---------------------------------------------------------------------------------------------------
-- Control Events
---------------------------------------------------------------------------------------------------

function PathTracker:OnListItemMouseEnter(wndHandler, wndControl)
	-- Has Mouse
	local bHasMouse = wndControl:GetParent():FindChild("ListItemMouseCatcher"):ContainsMouse()
	wndControl:GetParent():FindChild("ListItemCodexBtn"):Show(bHasMouse)
	wndControl:GetParent():FindChild("ListItemHintArrowArt"):Show(bHasMouse)
	
	local pmCurrMission = wndControl:GetData()
	local eType = pmCurrMission:GetType()
	local bShowSubscreenBtn =
			(eType == PathMission.PathMissionType_Explorer_PowerMap and self:HelperMissionHasPriority(pmCurrMission))
		or (eType == PathMission.PathMissionType_Explorer_Area and pmCurrMission:GetExplorerNodeInfo())
		or (eType == PathMission.PathMissionType_Explorer_Vista and pmCurrMission:GetExplorerNodeInfo())
		or (eType == PathMission.PathMissionType_Explorer_ScavengerHunt and pmCurrMission:IsStarted())
		or (eType == PathMission.PathMissionType_Settler_Scout and pmCurrMission:GetSettlerScoutInfo().fRatio >= 1)
		or eType == PathMission.PathMissionType_Scientist_FieldStudy
		or eType == PathMission.PathMissionType_Scientist_SpecimenSurvey
	
	wndControl:GetParent():FindChild("ListItemSubscreenBtn"):Show(
		bHasMouse 
		and bShowSubscreenBtn 
		and not wndControl:GetParent():FindChild("ListItemCompleteBtn"):IsShown()
	) -- Hide if complete is shown
end

function PathTracker:OnListItemMouseExit(wndHandler, wndControl)
	-- Has Mouse
	local bHasMouse = wndControl:GetParent():FindChild("ListItemMouseCatcher"):ContainsMouse()
	wndControl:GetParent():FindChild("ListItemCodexBtn"):Show(bHasMouse)
	wndControl:GetParent():FindChild("ListItemHintArrowArt"):Show(bHasMouse)
	
	local pmCurrMission = wndControl:GetData()
	local eType = pmCurrMission:GetType()
	local bShowSubscreenBtn =
			(eType == PathMission.PathMissionType_Explorer_PowerMap and self:HelperMissionHasPriority(pmCurrMission))
		or (eType == PathMission.PathMissionType_Explorer_Area and pmCurrMission:GetExplorerNodeInfo())
		or (eType == PathMission.PathMissionType_Explorer_Vista and pmCurrMission:GetExplorerNodeInfo())
		or (eType == PathMission.PathMissionType_Explorer_ScavengerHunt and pmCurrMission:IsStarted())
		or (eType == PathMission.PathMissionType_Settler_Scout and pmCurrMission:GetSettlerScoutInfo().fRatio >= 1)
		or eType == PathMission.PathMissionType_Scientist_FieldStudy
		or eType == PathMission.PathMissionType_Scientist_SpecimenSurvey
	
	wndControl:GetParent():FindChild("ListItemSubscreenBtn"):Show(
		bHasMouse 
		and bShowSubscreenBtn 
		and not wndControl:GetParent():FindChild("ListItemCompleteBtn"):IsShown()
	) -- Hide if complete is shown
end

function PathTracker:OnGenerateSpellTooltip(wndControl, wndHandler, eType, arg1, arg2)
	local xml = nil
	if eType == Tooltip.TooltipGenerateType_Spell then
		Tooltip.GetSpellTooltipForm(self, wndControl, arg1)
	elseif eType == Tooltip.TooltipGenerateType_PetCommand then
		xml = XmlDoc.new()
		xml:AddLine(arg2)
		wndControl:SetTooltipDoc(xml)
	end
end

---------------------------------------------------------------------------------------------------
-- UI Interactions
---------------------------------------------------------------------------------------------------

function PathTracker:OnListItemSubscreenBtn(wndHandler, wndControl) -- wndHandler is "RightSubscreenBtn" and its data is the mission object
	if wndHandler ~= wndControl or not wndHandler:GetData() then
		return
	end
	
	local pmMission = wndHandler:GetData()
	local eType = pmMission:GetType()
	if eType == PathMission.PathMissionType_Explorer_Area
		or eType == PathMission.PathMissionType_Explorer_Script
		or eType == PathMission.PathMissionType_Explorer_Door
		or eType == PathMission.PathMissionType_Explorer_ScavengerHunt
		or eType == PathMission.PathMissionType_Explorer_Vista
		or eType == PathMission.PathMissionType_Explorer_ExploreZone
		or eType == PathMission.PathMissionType_Explorer_ActivateChecklist
		or eType == PathMission.PathMissionType_Explorer_PowerMap then
		Event_FireGenericEvent("LoadExplorerMission", pmMission)
	elseif eType == PathMission.PathMissionType_Settler_Hub
		or eType == PathMission.PathMissionType_Settler_Script
		or eType == PathMission.PathMissionType_Settler_Infrastructure
		or eType == PathMission.PathMissionType_Settler_Mayor
		or eType == PathMission.PathMissionType_Settler_Sheriff
		or eType == PathMission.PathMissionType_Settler_Scout then
		Event_FireGenericEvent("LoadSettlerMission", pmMission)
	elseif eType == PathMission.PathMissionType_Scientist_FieldStudy
		or eType == PathMission.PathMissionType_Scientist_SpecimenSurvey then
		self.wndCheckList:Invoke()
		self:PopulateChecklistContainer(pmMission)
	elseif eType == PathMission.PathMissionType_Soldier_Holdout
		or eType == PathMission.PathMissionType_Soldier_Assassinate
		or eType == PathMission.PathMissionType_Soldier_Demolition
		or eType == PathMission.PathMissionType_Soldier_Rescue
		or eType == PathMission.PathMissionType_Soldier_SWAT
		or eType == PathMission.PathMissionType_Soldier_Script then
		if pmMission:IsStarted() then
			local seEvent = pmMission:GetSoldierHoldout()
			if seEvent ~= nil then
				Event_FireGenericEvent("LoadSoldierMission", seEvent)
			end
		end
	
	end
	
end

function PathTracker:OnListItemHintArrow(wndControl, wndHandler)
	if not wndHandler or not wndHandler:GetData() or wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	local pmMission = wndHandler:GetData()
	if wndHandler:FindChild("ListItemNewRunner") and wndHandler:FindChild("ListItemNewRunner"):IsShown() then -- "new" runner is visible
		wndHandler:FindChild("ListItemNewRunner"):Show(false)

		for idx, tMissionInfo in pairs(self.tNewMissions) do
			if pmMission == tMissionInfo.pmMission then
				table.remove(self.tNewMissions, idx)
			end
		end
	end

	-- What a list item click should do
	local eType = pmMission:GetType()
	if eType == PathMission.PathMissionType_Explorer_Vista and pmMission:GetExplorerNodeInfo() and pmMission:GetExplorerNodeInfo().fRatio > 1 then
		PlayerPathLib.PathAction()
	elseif eType == PathMission.PathMissionType_Explorer_Area and pmMission:GetExplorerNodeInfo() and pmMission:GetExplorerNodeInfo().fRatio > 1 then
		Event_FireGenericEvent("PlayerPath_NotificationSent", 3, pmMission:GetName()) -- Send a completed mission event
		PlayerPathLib.PathAction()
	elseif eType == PathMission.PathMissionType_Explorer_PowerMap and self:HelperMissionHasPriority(pmMission) then
		Event_FireGenericEvent("LoadExplorerMission", pmMission)
	elseif pmMission:GetType() == PathMission.PathMissionType_Settler_Scout and pmMission:GetSettlerScoutInfo() and pmMission:GetSettlerScoutInfo().fRatio >= 1 then
		Event_FireGenericEvent("PlayerPath_NotificationSent", 3, pmMission:GetName()) -- Send an objective completed event
		PlayerPathLib.PathAction()
	else
		pmMission:ShowHintArrow()
		GameLib.SetInteractHintArrowObject(pmMission)
	end
end

function PathTracker:HelperSelectInteractHintArrowObject(oCur, wndBtn)
	local oInteractObject = GameLib.GetInteractHintArrowObject()
	if not oInteractObject or oInteractObject and (oInteractObject.eHintArrowType == GameLib.CodeEnumHintType.None) then
		return
	end

	local bIsInteractHintArrowObject = oInteractObject.objTarget and oInteractObject.objTarget == oCur
	if bIsInteractHintArrowObject and not wndBtn:IsChecked() then
		wndBtn:SetCheck(true)
	end
end

function PathTracker:OnMouseEnter(wndHandler, wndControl)
	if not wndHandler or not wndHandler:GetData() then
		return
	end
	if ZoneMapLibrary and ZoneMapLibrary.wndZoneMap then
		ZoneMapLibrary.wndZoneMap:HighlightRegionsByUserData(wndHandler:GetData())
	end
end

function PathTracker:OnMouseExit(wndHandler, wndControl)
	if not wndHandler or not wndHandler:GetData() then
		return
	end
	if ZoneMapLibrary and ZoneMapLibrary.wndZoneMap then
		ZoneMapLibrary.wndZoneMap:UnhighlightRegionsByUserData(wndHandler:GetData())
	end
end

function PathTracker:OnListItemOpenCodex(wndHandler, wndControl) -- ListItemCodexBtn
	if not wndHandler or not wndHandler:GetData() or wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	Event_FireGenericEvent("DatachronPanel_PlayerPathShow", wndHandler:GetData())
end

function PathTracker:OnControlBackerMouseEnter(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:FindChild("MinimizeBtn"):Show(true)
	end
end

function PathTracker:OnControlBackerMouseExit(wndHandler, wndControl)
	if wndHandler == wndControl then
		local wndBtn = wndHandler:FindChild("MinimizeBtn")
		wndBtn:Show(wndBtn:IsChecked())
	end
end

function PathTracker:OnMinimizedBtnChecked(wndHandler, wndControl, eMouseButton)
	self.bMinimized = self.wndContainer:FindChild("MinimizeBtn"):IsChecked()
	self.bMinimizedActive = self.wndActiveHeader:FindChild("MinimizeBtn"):IsChecked()
	self.bMinimizedAvailable = self.wndAvailableHeader:FindChild("MinimizeBtn"):IsChecked()
	
	if self.wndOnGoingHeader ~= nil and self.wndOnGoingHeader:IsValid() then
		self.bMinimizedOnGoing = self.wndOnGoingHeader:FindChild("MinimizeBtn"):IsChecked()
	end
	
	if self.wndScanbotHeader ~= nil and self.wndScanbotHeader:IsValid() then
		self.bMinimizedScanBot = self.wndScanbotHeader:FindChild("MinimizeBtn"):IsChecked()
	end
	
	self:ResizeAll()
end

---------------------------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------------------------
function PathTracker:HelperMissionHasPriority(pmMission)
	if not pmMission then
		return
	end

	local eType = pmMission:GetType()
	if eType == PathMission.PathMissionType_Explorer_PowerMap then
		return pmMission:IsExplorerPowerMapActive() or pmMission:IsExplorerPowerMapReady()

	elseif eType == PathMission.PathMissionType_Explorer_Vista and pmMission:IsStarted() then
		return pmMission:GetExplorerNodeInfo() and pmMission:GetExplorerNodeInfo().nMaxStates ~= 0

	elseif eType == PathMission.PathMissionType_Explorer_Area then
		return pmMission:GetExplorerNodeInfo() and pmMission:GetExplorerNodeInfo().fRatio > 0.1

	elseif pmMission:GetType() == PathMission.PathMissionType_Explorer_ScavengerHunt then
		if pmMission:IsInArea() and not pmMission:IsStarted() then
			return true
		end

		for idx = 1, pmMission:GetNumNeeded() do
			if pmMission:GetExplorerClueRatio(idx) > 0 then
				return true
			end
		end
	elseif eType == PathMission.PathMissionType_Settler_Scout then
		local tInfo = pmMission:GetSettlerScoutInfo()
		return tInfo ~= nil and tInfo.fRatio > 0
	end

	return false
end

function PathTracker:HelperComputeProgressText(eType, pmMission)
	local strResult = ""
	if eType == PathMission.PathMissionType_Explorer_ExploreZone
		or eType == PathMission.PathMissionType_Scientist_Scan
		or eType == PathMission.PathMissionType_Scientist_ScanChecklist
		or eType == PathMission.PathMissionType_Scientist_Script
		or eType == PathMission.PathMissionType_Scientist_Experimentation then
		
		strResult = String_GetWeaselString(Apollo.GetString("CRB_Percent"), pmMission:GetNumCompleted())
	
	elseif eType == PathMission.PathMissionType_Explorer_PowerMap then
		
		strResult = String_GetWeaselString(Apollo.GetString("ChallengeReward_Multiplier"), math.max(1, pmMission:GetNumNeeded()))
	
	elseif eType == PathMission.PathMissionType_Explorer_Area or eType == PathMission.PathMissionType_Explorer_ScavengerHunt or eType == PathMission.PathMissionType_Explorer_ActivateChecklist then
		
		strResult = String_GetWeaselString(Apollo.GetString("Achievements_ProgressBarProgress"), pmMission:GetNumCompleted(), pmMission:GetNumNeeded())
	
	elseif eType == PathMission.PathMissionType_Settler_Infrastructure then
		
		if pmMission:IsComplete() then
			local tInfrastructure = PlayerPathLib.GetInfrastructureStatusForMission(pmMission)
			
			local nCurrent = tInfrastructure.nRemainingTime > 0 and tInfrastructure.nRemainingTime or tInfrastructure.nCurrentCount
			local nMax 	= tInfrastructure.nRemainingTime > 0 and tInfrastructure.nMaxTime or tInfrastructure.nMaxCount
			
			if tInfrastructure.nRemainingTime > 0 then
				strResult = string.format("%s%s", Apollo.GetString("CRB_Time_Remaining_2"), ConvertSecondsToTimer(nCurrent / 1000))
			elseif tInfrastructure.nCurrentCount == 0 and tInfrastructure.nMaxCount == 0 then
				strResult = Apollo.GetString("SettlerMission_Inactive")
			else
				strResult = String_GetWeaselString(Apollo.GetString("CRB_ProgressSimple"), nCurrent, nMax)
			end
		else
			strResult = String_GetWeaselString(Apollo.GetString("CRB_ProgressSimple"), pmMission:GetNumCompleted(), pmMission:GetNumNeeded())
		end
	
	elseif eType == PathMission.PathMissionType_Settler_Hub
		or eType == PathMission.PathMissionType_Settler_Scout
		or eType == PathMission.PathMissionType_Scientist_FieldStudy
		or eType == PathMission.PathMissionType_Scientist_SpecimenSurvey
		or eType == PathMission.PathMissionType_Scientist_DatacubeDiscovery
		or eType == PathMission.PathMissionType_Soldier_Demolition
		or eType == PathMission.PathMissionType_Soldier_Assassinate
		or eType == PathMission.PathMissionType_Soldier_Rescue
		or eType == PathMission.PathMissionType_Soldier_SWAT
		or eType == PathMission.PathMissionType_Soldier_Script then
		
		if pmMission:IsComplete() then
			strResult = Apollo.GetString("CRB_Complete")
		else
			strResult = String_GetWeaselString(Apollo.GetString("CRB_ProgressSimple"), pmMission:GetNumCompleted(), pmMission:GetNumNeeded())
		end
	
	elseif eType == PathMission.PathMissionType_Settler_Mayor
		or eType == PathMission.PathMissionType_Settler_Sheriff then
		
		if pmMission:IsComplete() then
			strResult = Apollo.GetString("CRB_Complete")
		else
			local nTotal = 0
			local nCompleted = 0
			local tInfo = nil
			if eType == PathMission.PathMissionType_Settler_Mayor then
				tInfo = pmMission:GetSettlerMayorInfo()
			else
				tInfo = pmMission:GetSettlerSheriffInfo()
			end
			
			if tInfo then
				for strKey, tCurrInfo in pairs(tInfo) do
					if tCurrInfo.strDescription and Apollo.StringLength(tCurrInfo.strDescription) > 0 then -- Since we get all 8 (including nil) entries and this is how we filter
						nTotal = nTotal + 1
						if tCurrInfo.bIsComplete then
							nCompleted = nCompleted + 1
						end
					end
				end
			end
		
			strResult = String_GetWeaselString(Apollo.GetString("CRB_ProgressSimple"), nCompleted, nTotal)
		end
	
	elseif eType == PathMission.PathMissionType_Soldier_Holdout then
		
		local seEvent = pmMission:GetSoldierHoldout()
		if seEvent ~= nil then
			local eEventState = seEvent:GetState()
			local eEventType = seEvent:GetType()
			if eEventType == PathMission.PathSoldierEventType_Timed 
				or eEventType == PathMission.PathSoldierEventType_TimedDefend
				or eEventType == PathMission.PathSoldierEventType_WhackAMoleTimed
				or eEventType == PathMission.PathSoldierEventType_StopTheThievesTimed then
				if eEventState == PathMission.PlayerPathSoldierEventMode_Active then
					strResult = ConvertSecondsToTimer((seEvent:GetMaxTime() - seEvent:GetElapsedTime()) / 1000)
				else
					strResult = ConvertSecondsToTimer(seEvent:GetMaxTime() / 1000)
				end
		
			elseif eEventType == PathMission.PathSoldierEventType_Holdout 
				or eEventType == PathMission.PathSoldierEventType_Defend 
				or eEventType == PathMission.PathSoldierEventType_TowerDefense 
				or eEventType == PathMission.PathSoldierEventType_StopTheThieves 
				or eEventType == PathMission.PathSoldierEventType_WhackAMole then
				if eEventState == PathMission.PlayerPathSoldierEventMode_Active then
					strResult = (seEvent:GetWaveCount() - seEvent:GetWavesReleased()) .. "x"
				else
					strResult = seEvent:GetWaveCount() .. "x"
				end
			end
		end
		
	end
	return strResult
end

-----------------------------------------------------------------------------------------------
-- Right Click
-----------------------------------------------------------------------------------------------
function PathTracker:CloseContextMenu() -- From a variety of source
	if self.wndContextMenu and self.wndContextMenu:IsValid() then
		self.wndContextMenu:Destroy()
		self.wndContextMenu = nil
		
		return true
	end
	
	return false
end

function PathTracker:DrawContextMenu()
	local nXCursorOffset = -36
	local nYCursorOffset = 5

	if self:CloseContextMenu() then
		return
	end

	self.wndContextMenu = Apollo.LoadForm(self.xmlDoc, "ContextMenu", nil, self)
	self:DrawContextMenuSubOptions()
			
	local tCursor = Apollo.GetMouse()
	local nWidth = self.wndContextMenu:GetWidth()
	local nHeight = self.wndContextMenu:GetHeight()
	
	self.wndContextMenu:Move(
		tCursor.x - nWidth - nXCursorOffset,
		tCursor.y - nHeight - nYCursorOffset,
		nWidth,
		nHeight
	)
end

function PathTracker:DrawContextMenuSubOptions(wndIgnore)
	if not self.wndContextMenu or not self.wndContextMenu:IsValid() then
		return
	end
	
	self.wndContextMenu:FindChild("ToggleOnPathMissions"):SetCheck(self.bShowPathMissions)
	self.wndContextMenu:FindChild("ToggleOnGoingProjects"):SetCheck(self.bShowPathMissions and self.bToggleOnGoingProjects)
	self.wndContextMenu:FindChild("ToggleOnGoingProjects"):Show(PlayerPathLib.GetPlayerPathType() == PlayerPathLib.PlayerPathType_Settler)
	self.wndContextMenu:FindChild("ToggleFilterZone"):SetCheck(self.bShowOutOfZone)
	self.wndContextMenu:FindChild("ToggleFilterLimit"):SetCheck(self.bFilterLimit)
	self.wndContextMenu:FindChild("ToggleFilterDistance"):SetCheck(self.bFilterDistance)
	
	local wndMissionLimitEditBox = self.wndContextMenu:FindChild("MissionLimitEditBox")
	local wndMissionDistanceEditBox = self.wndContextMenu:FindChild("MissionDistanceEditBox")
	
	if not wndIgnore or wndIgnore and wndIgnore ~= wndMissionLimitEditBox then
		wndMissionLimitEditBox:SetText(self.bFilterLimit and self.nMaxMissionLimit or 0)
	end
	
	if not wndIgnore or wndIgnore and wndIgnore ~= wndMissionDistanceEditBox then
		wndMissionDistanceEditBox:SetText(self.bFilterDistance and self.nMaxMissionDistance or 0)
	end
	
	local wndStackContainer = self.wndContextMenu:FindChild("StackContainer")
	local nHeight = wndStackContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nStartHeight = wndStackContainer:GetHeight()
	local nLeft, nTop, nRight, nBottom = self.wndContextMenu:GetAnchorOffsets()
	self.wndContextMenu:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + (nHeight - nStartHeight))
	
	if self.bFilterDistance then
		self.timerRealTimeUpdate:Start()
	end
end

function PathTracker:OnToggleShowPathMissions()
	self.bShowPathMissions = not self.bShowPathMissions
	
	if self.wndContextMenu and self.wndContextMenu:IsValid() then
		self.wndContextMenu:FindChild("ToggleOnPathMissions"):SetCheck(self.bShowPathMissions)
		self.wndContextMenu:FindChild("ToggleOnGoingProjects"):SetCheck(self.bShowPathMissions and self.bToggleOnGoingProjects)
		self.wndContextMenu:FindChild("ToggleOnGoingProjects"):Enable(self.bShowPathMissions)
		self.wndContextMenu:FindChild("ToggleOnGoingProjects"):Show(PlayerPathLib.GetPlayerPathType() == PlayerPathLib.PlayerPathType_Settler)
		
		local wndStackContainer = self.wndContextMenu:FindChild("StackContainer")
		local nHeight = wndStackContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		local nStartHeight = wndStackContainer:GetHeight()
		local nLeft, nTop, nRight, nBottom = self.wndContextMenu:GetAnchorOffsets()
		self.wndContextMenu:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + (nHeight - nStartHeight))
	end
	
	self:ResizeAll()
end

function PathTracker:OnToggleOnGoingProjects(wndHandler, wndControl)	
	self.bToggleOnGoingProjects = not self.bToggleOnGoingProjects
	self:ResizeAll()
end

function PathTracker:OnToggleFilterZone()
	self.bShowOutOfZone = not self.bShowOutOfZone
	
	self:DrawContextMenuSubOptions()
	self:ResizeAll()
end

function PathTracker:OnToggleFilterLimit()
	self.bFilterLimit = not self.bFilterLimit
	
	self:DrawContextMenuSubOptions()
	self:ResizeAll()
end

function PathTracker:OnToggleFilterDistance()
	self.bFilterDistance = not self.bFilterDistance
	
	self:DrawContextMenuSubOptions()
	self:ResizeAll()
end

function PathTracker:OnMissionLimitEditBoxChanged(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	
	self.nMaxMissionLimit = tonumber(wndControl:GetText()) or 0
	self.bFilterLimit = self.nMaxMissionLimit > 0
	
	self:DrawContextMenuSubOptions(wndControl)
	if self.bFilterDistance then
		self.timerResizeDelay:Start()
	end
end

function PathTracker:OnMissionDistanceEditBoxChanged(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	
	self.nMaxMissionDistance = tonumber(wndControl:GetText()) or 0
	self.bFilterDistance = self.nMaxMissionDistance > 0
	
	self:DrawContextMenuSubOptions(wndControl)
	if self.bFilterDistance then
		self.timerResizeDelay:Start()
	end
end

function PathTracker:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors = 
	{
		[GameLib.CodeEnumTutorialAnchor.PathTracker] 	= true,
	}
	
	if not tAnchors[eAnchor] then
		return
	end
	
	local tAnchorMapping = 
	{
		[GameLib.CodeEnumTutorialAnchor.PathTracker] = self.wndMain,
	}
	
	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

---------------------------------------------------------------------------------------------------
-- Path Explorer instance
---------------------------------------------------------------------------------------------------
local PathTrackerInst = PathTracker:new()
PathTrackerInst:Init()
