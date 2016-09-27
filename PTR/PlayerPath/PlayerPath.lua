-----------------------------------------------------------------------------------------------
-- Client Lua Script for ChallengeLog
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "Tooltip"
require "XmlDoc"
require "PlayerPathLib"
require "PathMission"
require "GameLib"

-- TODO Hardcoded Colors for Items
local karEvalColors =
{
	[Item.CodeEnumItemQuality.Inferior] 		= ApolloColor.new("ItemQuality_Inferior"),
	[Item.CodeEnumItemQuality.Average] 			= ApolloColor.new("ItemQuality_Average"),
	[Item.CodeEnumItemQuality.Good] 			= ApolloColor.new("ItemQuality_Good"),
	[Item.CodeEnumItemQuality.Excellent] 		= ApolloColor.new("ItemQuality_Excellent"),
	[Item.CodeEnumItemQuality.Superb] 			= ApolloColor.new("ItemQuality_Superb"),
	[Item.CodeEnumItemQuality.Legendary] 		= ApolloColor.new("ItemQuality_Legendary"),
	[Item.CodeEnumItemQuality.Artifact]		 	= ApolloColor.new("ItemQuality_Artifact"),
}

local ktPathTypes =
{
	[PlayerPathLib.PlayerPathType_Explorer] =
	{
		icon = "charactercreate:sprCharC_Finalize_PathExplorer",
		title = "CRB_Explorer",
		description = "PathLog_Blurb_Explorer",
		landingSprite = "PathLog:sprLanding_Explorer",
	},
	[PlayerPathLib.PlayerPathType_Scientist] =
	{
		icon = "charactercreate:sprCharC_Finalize_PathScientist",
		title = "CRB_Scientist",
		description = "PathLog_Blurb_Scientist",
		landingSprite = "PathLog:sprLanding_Scientist",
	},
	[PlayerPathLib.PlayerPathType_Settler] =
	{
		icon = "charactercreate:sprCharC_Finalize_PathSettler",
		title = "CRB_Settler",
		description = "PathLog_Blurb_Settler",
		landingSprite = "PathLog:sprLanding_Settler",
	},
	[PlayerPathLib.PlayerPathType_Soldier] =
	{
		icon = "charactercreate:sprCharC_Finalize_PathSoldier",
		title = "CRB_Soldier",
		description = "PathLog_Blurb_Soldier",
		landingSprite = "PathLog:sprLanding_Soldier",
	},
}

local ktPathMissionTypes = {
	[PlayerPathLib.PlayerPathType_Scientist] = {
		[PathMission.PathMissionType_Scientist_FieldStudy] = { 
			sprIcon = "Icon_Mission_Scientist_FieldStudy",
			strTitle = "ScientistMission_FieldStudy",
			strTooltip = "ScientistMission_FieldStudy_Tooltip"
		},
		[PathMission.PathMissionType_Scientist_DatacubeDiscovery] = { 
			sprIcon = "Icon_Mission_Scientist_DatachronDiscovery",
			strTitle = "ScientistMission_Datacube",
			strTooltip = "ScientistMission_Datacube_Tooltip"
		},
		[PathMission.PathMissionType_Scientist_SpecimenSurvey] = { 
			sprIcon = "Icon_Mission_Scientist_SpecimenSurvey",
			strTitle = "ScientistMission_SpecimenSurvey",
			strTooltip = "ScientistMission_SpecimenSurvey_Tooltip"
		},
		[PathMission.PathMissionType_Scientist_Experimentation] = { 
			sprIcon = "Icon_Mission_Scientist_ReverseEngineering",
			strTitle = "ScientistMission_Experimentation",
			strTooltip = "ScientistMission_Experimentation_Tooltip"
		},
	},
	[PlayerPathLib.PlayerPathType_Settler] = {
		[PathMission.PathMissionType_Settler_Scout] = { 
			sprIcon = "Icon_Mission_Settler_Scout",
			strTitle = "SettlerMission_Expansion",
			strTooltip = "SettlerMission_Expansion_Tooltip"
		},
		[PathMission.PathMissionType_Settler_Sheriff] = { 
			sprIcon = "Icon_Mission_Settler_Posse",
			strTitle = "SettlerMission_PublicSafety",
			strTooltip = "SettlerMission_PublicSafety_Tooltip"
		},
		[PathMission.PathMissionType_Settler_Mayor] = { 
			sprIcon = "Icon_Mission_Settler_Mayoral",
			strTitle = "SettlerMission_CivilService",
			strTooltip = "SettlerMission_CivilService_Tooltip"
		},
		[PathMission.PathMissionType_Settler_Hub] = { 
			sprIcon = "Icon_Mission_Settler_DepotImprovements",
			strTitle = "SettlerMission_CivilService",
			strTooltip = "SettlerMission_CivilService_Tooltip"
		},
		[PathMission.PathMissionType_Settler_Infrastructure] = { 
			sprIcon = "Icon_Mission_Settler_DepotImprovements",
			strTitle = "SettlerMission_Project",
			strTooltip = "SettlerMission_Project_Tooltip"
		},		
	},
	[PlayerPathLib.PlayerPathType_Soldier] = {
		[PathMission.PathMissionType_Soldier_SWAT] = { 
			sprIcon = "Icon_Mission_Soldier_Swat",
			strTitle = "SoldierMission_Swat",
			strTooltip = "SoldierMission_SWAT_Tooltip"
		},
		[PathMission.PathMissionType_Soldier_Rescue] = { 
			sprIcon = "Icon_Mission_Soldier_Rescue",
			strTitle = "SoldierMission_RescueOps",
			strTooltip = "SoldierMission_Rescue_Tooltip"
		},
		[PathMission.PathMissionType_Soldier_Demolition] = { 
			sprIcon = "Icon_Mission_Soldier_Demolition",
			strTitle = "SoldierMission_Demolition",
			strTooltip = "SoldierMission_Demolition_Tooltip"
		},
		[PathMission.PathMissionType_Soldier_Assassinate] = { 
			sprIcon = "Icon_Mission_Soldier_Assassinate",
			strTitle = "SoldierMission_Assassination",
			strTooltip = "SoldierMission_Assassination_Tooltip"
		},
		[PathMission.PathMissionType_Soldier_Holdout] = { 
			sprIcon = "Icon_Mission_Soldier_HoldoutConquer",
			strTitle = "SoldierMission_Holdout",
			strTooltip = "SoldierMission_Holdout_Tooltip"
		},			
	},
	[PlayerPathLib.PlayerPathType_Explorer] = {
		[PathMission.PathMissionType_Explorer_Vista] = { 
			sprIcon = "Icon_Mission_Explorer_Vista",
			strTitle = "ExplorerMission_Vista",
			strTooltip = "ExplorerMission_Vista_Tooltip"
		},
		[PathMission.PathMissionType_Explorer_PowerMap] = { 
			sprIcon = "Icon_Mission_Explorer_PowerMap",
			strTitle = "ExplorerMission_Tracking",
			strTooltip = "ExplorerMission_Tracking_Tooltip"
		},
		[PathMission.PathMissionType_Explorer_Area] = { 
			sprIcon = "Icon_Mission_Explorer_ClaimTerritory",
			strTitle = "ExplorerMission_StakingClaim",
			strTooltip = "ExplorerMission_StakingClaim_Tooltip"
		},
		[PathMission.PathMissionType_Explorer_Door] = { 
			sprIcon = "Icon_Mission_Explorer_ActivateChecklist",
			strTitle = "ExplorerMission_Exploration",
			strTooltip = "ExplorerMission_Exploration_Tooltip"
		},
		[PathMission.PathMissionType_Explorer_ExploreZone] = { 
			sprIcon = "Icon_Mission_Explorer_ExploreZone",
			strTitle = "ExplorerMission_Cartography",
			strTooltip = "ExplorerMission_Cartography_Tooltip"
		},
		[PathMission.PathMissionType_Explorer_ScavengerHunt] = { 
			sprIcon = "Icon_Mission_Explorer_ScavengerHunt",
			strTitle = "ExplorerMission_ScavengerHunt",
			strTooltip = "ExplorerMission_ScavengerHunt_Tooltip"
		},
		[PathMission.PathMissionType_Explorer_ActivateChecklist] = { 
			sprIcon = "Icon_Mission_Explorer_ExploreZone",
			strTitle = "ExplorerMission_Operations",
			strTooltip = "ExplorerMission_Operations_Tooltip"
		},
	}			
}

local ktPathMissionTypeDefaultSprites = {
	[PlayerPathLib.PlayerPathType_Explorer] = "Icon_Mission_Explorer_ExploreZone",
	[PlayerPathLib.PlayerPathType_Soldier] = "Icon_Mission_Soldier_Swat",
	[PlayerPathLib.PlayerPathType_Settler] = "Icon_Mission_Settler_DepotImprovements",
	[PlayerPathLib.PlayerPathType_Scientist] = "Icon_Mission_Scientist_ScanMineral",
}

local ktPathMissionSubtypeSprites =
{
	[PlayerPathLib.PlayerPathType_Scientist] =
	{
		[PathMission.ScientistCreatureType_Tech] 					= "Icon_Mission_Scientist_ScanTech",
		[PathMission.ScientistCreatureType_Flora] 					= "Icon_Mission_Scientist_ScanPlant",
		[PathMission.ScientistCreatureType_Fauna] 					= "Icon_Mission_Scientist_ScanCreature",
		[PathMission.ScientistCreatureType_Mineral] 				= "Icon_Mission_Scientist_ScanMineral",
		[PathMission.ScientistCreatureType_Magic] 					= "Icon_Mission_Scientist_ScanMagic",
		[PathMission.ScientistCreatureType_History] 				= "Icon_Mission_Scientist_ScanHistory",
		[PathMission.ScientistCreatureType_Elemental] 				= "Icon_Mission_Scientist_ScanElemental",
	},

	[PlayerPathLib.PlayerPathType_Soldier] =
	{
		[PathMission.PathSoldierEventType_Holdout] 					= "Icon_Mission_Soldier_HoldoutConquer",
		[PathMission.PathSoldierEventType_TowerDefense] 			= "Icon_Mission_Soldier_HoldoutFortify",
		[PathMission.PathSoldierEventType_Defend] 					= "Icon_Mission_Soldier_HoldoutProtect",
		[PathMission.PathSoldierEventType_Timed] 					= "Icon_Mission_Soldier_HoldoutTimed",
		[PathMission.PathSoldierEventType_TimedDefend] 				= "Icon_Mission_Soldier_HoldoutProtect",
		[PathMission.PathSoldierEventType_WhackAMole] 				= "Icon_Mission_Soldier_HoldoutRushDown",
		[PathMission.PathSoldierEventType_WhackAMoleTimed] 			= "Icon_Mission_Soldier_HoldoutRushDown",
		[PathMission.PathSoldierEventType_StopTheThieves] 			= "Icon_Mission_Soldier_HoldoutSecurity",
		[PathMission.PathSoldierEventType_StopTheThievesTimed] 		= "Icon_Mission_Soldier_HoldoutSecurity",
	},
}

local ktPathChangeResults =
{
	[GameLib.CodeEnumGenericError.PathChange_NotUnlocked] = "PlayerPath_ActivateFail_Locked",
	[GameLib.CodeEnumGenericError.PathChange_InsufficientFunds] = "PlayerPath_ActivateFail_Funds",
	[GameLib.CodeEnumGenericError.PathChange_OnCooldown] = "PlayerPath_ActivateFail_Cooldown",
}

local PlayerPath 					= {}
local knMaxLevel 					= 30 -- TODO: Replace this with a non hardcoded value
local kcrNormalTextColor 			= CColor.new(192/255, 192/255, 192/255, 1.0)
local kcrHighlightTextColor 		= CColor.new(1.0, 128/255, 0, 1.0)
local kstrMissionDescriptionText 	= "ffffeca0"
local knAutoScrollPadding			= 30

function PlayerPath:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function PlayerPath:Init()
	Apollo.RegisterAddon(self)
end

function PlayerPath:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("PlayerPath.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function PlayerPath:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 			"OnInterfaceMenuListHasLoaded", self)
	self:OnInterfaceMenuListHasLoaded()
	
	Apollo.RegisterEventHandler("PL_TogglePlayerPath", 					"OnPathShowFromPL", self)
	Apollo.RegisterEventHandler("SetPlayerPath", 						"UpdateUIFromEvent", self)
	Apollo.RegisterEventHandler("PathLevelUp", 							"OnRedrawLevels", self)
	Apollo.RegisterEventHandler("PlayerPathMissionUpdate", 				"UpdateUIFromEvent", self) -- specific mission update, send the mission
	Apollo.RegisterEventHandler("PlayerPathRefresh", 					"UpdateUIFromEvent", self) -- generic update for things like episode change; no info sent
	Apollo.RegisterEventHandler("UpdatePathXp", 						"UpdateUIFromEvent", self)
	Apollo.RegisterEventHandler("PathUnlockResult",						"UpdateUIFromEvent", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 					"OnUnitEnteredCombat", self)
	Apollo.RegisterEventHandler("DatachronPanel_PlayerPathShow", 		"OnShowFromDatachron", self)
	Apollo.RegisterTimerHandler("MissionHighlightTimer", 				"OnMissionHighlightTimer", self)
	Apollo.RegisterEventHandler("ServiceTokenClosed_PlayerPath",		"OnServiceTokenDialogClosed", self)
	Apollo.RegisterEventHandler("PathChangeResult",						"OnPathChangeResult", self)
end

function PlayerPath:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_PathLog"), {"PlayerPathShow", "Path", "Icon_Windows32_UI_CRB_InterfaceMenu_Path"})
end

function PlayerPath:OnPathShowFromPL(pepEpisode)
	if not self.wndMissionLog then
		self:Initialize()
	end
	
	local ePlayerPathOld = self.ePlayerPath

	if not PathEpisode.is(pepEpisode) then
		self.ePlayerPath = PlayerPathLib.GetPlayerPathType()
		self:PathRefresh(nil, true)
	else
		self.ePlayerPath = pepEpisode:GetPathType()
		self:PathRefresh(pepEpisode, false)
	end

	if ePlayerPathOld ~= self.ePlayerPath then
		self.tPathTypeBtns[ePlayerPathOld]:SetCheck(false)
		self:UpdatePathButtons()
		self:OnRedrawLevels(nil)
	end
end

function PlayerPath:OnShowFromDatachron(pmMission) -- used to open to a specific mission
	if not self.wndMissionLog then
		self:Initialize()
	end

	if pmMission and (not self.pmHighlightedMission or self.pmHighlightedMission ~= pmMission) then
		self.pmHighlightedMission = pmMission
		Apollo.StopTimer("MissionHighlightTimer")
		Apollo.CreateTimer("MissionHighlightTimer", 8.5, false)
	end
	self:HelperCheckTheFirstCategory()
	--full redraw because the path log may be showing paths from a different zone
	self:PathRefresh(nil, true)

	Event_FireGenericEvent("PlayerPathShow_NoHide") -- if PLog is visible, jump to that tab. If not, open it, then jump to that tab. This will have to go into Codex code
end

function PlayerPath:Initialize()
	self.wndMissionLog = Apollo.LoadForm(self.xmlDoc, "MissionLog", g_wndProgressLog:FindChild("ContentWnd_2"), self)
	self.wndMissionLog:Show(true)
	
	self.tPathTypeBtns = {
		[PlayerPathLib.PlayerPathType_Explorer] = self.wndMissionLog:FindChild("Explorer"),
		[PlayerPathLib.PlayerPathType_Scientist] = self.wndMissionLog:FindChild("Scientist"),
		[PlayerPathLib.PlayerPathType_Settler] = self.wndMissionLog:FindChild("Settler"),
		[PlayerPathLib.PlayerPathType_Soldier] = self.wndMissionLog:FindChild("Soldier")
	}

	self.ePlayerPath = PlayerPathLib.GetPlayerPathType() -- NOTE: This will require a player to reloadui when swapping paths
	self.pmHighlightedMission = nil

	self:UpdatePathButtons()
	self:PathRefresh(nil, true)
	self:OnRedrawLevels(nil)
end

----------------------------------------------------------------------------------------------------------
-- Simple Event Handlers
----------------------------------------------------------------------------------------------------------

function PlayerPath:UpdateUIFromEvent() -- Arguments for this can vary
	self:UpdatePathButtons()
	self:OnRedrawLevels()
	self:PathRefresh(nil, true)
end

function PlayerPath:OnUnitEnteredCombat(unit)
	if unit ~= GameLib.GetPlayerUnit() or not self.wndMissionLog then
		return
	end
	
	local bIsInCombat = unit:IsInCombat()
	local strError = Apollo.GetString("SpellFailure_Caster_CannotBeInCombatPVE")
	
	self.wndMissionLog:FindChild("UnlockPath"):Enable(not bIsInCombat)
	self.wndMissionLog:FindChild("SelectPath"):Enable(not bIsInCombat)
	self.wndMissionLog:FindChild("SelectPathCooldown"):Enable(not bIsInCombat)
	self.wndMissionLog:FindChild("UnlockPath"):SetTooltip(bIsInCombat and strError or "")
	self.wndMissionLog:FindChild("SelectPath"):SetTooltip(bIsInCombat and strError or "")
	self.wndMissionLog:FindChild("SelectPathCooldown"):SetTooltip(bIsInCombat and strError or "")
end

function PlayerPath:OnBigZoneBtnPress(wndHandler, wndControl)
	if not wndControl or not wndControl:GetData() then
		return 
	end
	self:HelperCheckTheFirstCategory(wndControl)
	self:DrawMissions(self.tLastZoneBtnPress, true)
	self.pmHighlightedMission = nil
	self.wndMissionLog:FindChild("MissionList"):SetVScrollPos(0)
	self.wndMissionLog:FindChild("MissionList"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
end

function PlayerPath:HelperCheckTheFirstCategory(wndControl)--optional parameter
	if not wndControl then
		--came from the datachron, which has the missions from the current zone, which is
		--what is displayed when setting self.tLastZoneBtnPress to nil
		local tMissionListChildren = self.wndMissionLog:FindChild("MissionList"):GetChildren()
		if tMissionListChildren and tMissionListChildren[1] then
			local wndHeaderBtn = tMissionListChildren[1]:FindChild("HeaderBtn")
			if not wndHeaderBtn:IsChecked() then
				tMissionListChildren[1]:FindChild("HeaderBtn"):SetCheck(true)
			end
			self.tLastZoneBtnPress = nil
		end
	else
		--came from big zone button press
		self.tLastZoneBtnPress = wndControl:GetData()
	end
end

function PlayerPath:OnExpandCategories(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	--handles resizing
	self.strLastExpanded = wndControl:FindChild("HeaderBtn"):GetText()

	self:PathRefresh(self.tLastZoneBtnPress, false)
end

function PlayerPath:OnCollapseCategories(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local wndParent = wndControl:GetParent()
	local wndContainer = wndParent:FindChild("HeaderContainer")

	local nHeight = 0
	for idx, wndMission in pairs(wndContainer:GetChildren()) do
		nHeight = nHeight + wndMission:GetHeight()
	end
	
	local nLeft, nTop, nRight, nBottom = wndParent:GetAnchorOffsets()
	wndParent:SetAnchorOffsets(nLeft, nTop, nRight, nBottom - nHeight)
	wndContainer:DestroyChildren()
	self.wndMissionLog:FindChild("MissionList"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function PlayerPath:OnLootEpisodeRewards(wndHandler, wndControl)
	local pepEpisode = wndControl:GetData()

	if pepEpisode ~= nil then
		--episode:AcceptRewards()
		Event_FireGenericEvent("ToggleCodex")
		Event_FireGenericEvent("PlayerPath_EpisodeRewardsLootedLog")
	end
end

function PlayerPath:OnMissionHighlightTimer()
	if not self.pmHighlightedMission then
		return
	end

	local wnd = self.wndMissionLog:FindChild("MissionList"):FindChildByUserData(self.pmHighlightedMission)
	if wnd ~= nil then
		wnd:FindChild("MissionItemHighlightRunner"):Show(false)
	end
	self.pmHighlightedMission = nil
end

function PlayerPath:OnMissionHighlightMouseDown(wndHandler, wndControl)
	wndHandler:Show(false) -- wndHandler is "MissionItemHighlightRunner"
	self.pmHighlightedMission = nil
end

----------------------------------------------------------------------------------------------------------
-- Main Draw and Update Methods
----------------------------------------------------------------------------------------------------------

function PlayerPath:UpdatePathButtons()
	local tPathStatus = PlayerPathLib.GetPathStatuses()
	if not tPathStatus or not self.tPathTypeBtns then
		return
	end
	
	for ePathType, tPathInfo in pairs(tPathStatus.tPaths) do
		local wndButton = self.tPathTypeBtns[ePathType]

		local strTitle = String_GetWeaselString(Apollo.GetString(ktPathTypes[ePathType].title))
		local strText = nil
		if not tPathInfo.bUnlocked then
			strText = String_GetWeaselString(Apollo.GetString("PlayerPath_Log_ButtonFormatLocked"), strTitle)
		else
			strText = String_GetWeaselString(Apollo.GetString("PlayerPath_Log_ButtonFormat"), strTitle, tPathInfo.nLevel)
		end
		
		wndButton:FindChild("LockedIcon"):Show(not tPathInfo.bUnlocked)
		wndButton:FindChild("CurrentPathIndicator"):Show(tPathInfo.bUnlocked)
		wndButton:FindChild("CurrentPathIndicator:ActiveIndicator"):Show(tPathInfo.bActive)

		wndButton:SetText(strText)
	end
	
	self.tPathTypeBtns[self.ePlayerPath]:SetCheck(true)
end

function PlayerPath:PathRefresh(pepEpisode, bFullRedraw) -- A lot of events route here, with the first argument not necessarily valid
	-- TODO Hardcoded formatting
	if not self.wndMissionLog then
		return
	end
	
	if not PlayerPathLib.IsPathUnlocked(self.ePlayerPath) then
		self:DrawLanding(true)
		return
	else
		self:DrawLanding(false)
	end

	-- Use the passed in episode if possible, else just use the current
	local pepSelectedEpisode = pepEpisode
	if not pepSelectedEpisode then
		if self.pmHighlightedMission then
			pepSelectedEpisode = self.pmHighlightedMission:GetEpisode()
		else
			pepSelectedEpisode = PlayerPathLib.GetCurrentEpisode()
		end
	end
	
	if not pepSelectedEpisode or pepSelectedEpisode:GetPathType() ~= self.ePlayerPath then
		pepSelectedEpisode = PlayerPathLib.GetPathEpisodeForZone(self.ePlayerPath)
	end
	
	-- Populate Dropdown
	local tEpisodeList = PlayerPathLib.GetEpisodes(self.ePlayerPath)
	if not tEpisodeList then
		return
	end

	local nPercent = 0
	local bMatchingZone = false
	local strWorldZone = ""
	local wndZoneList = self.wndMissionLog:FindChild("ZoneList")

	wndZoneList:DestroyChildren()
	for key, pepCurrEpisode in pairs(tEpisodeList) do
		local wndBigZone = Apollo.LoadForm(self.xmlDoc, "BigZoneItem", self.wndMissionLog:FindChild("ZoneList"), self)
		strWorldZone = pepCurrEpisode:GetWorldZone() if not strWorldZone or strWorldZone == "" then strWorldZone = Apollo.GetString("PlayerPath_UntitledZone") end

		local tMissions = pepCurrEpisode:GetMissions()
		if #tMissions > 0 then nPercent = math.floor(100 * pepCurrEpisode:GetNumCompleted() / #tMissions) end
		wndBigZone:FindChild("BigZoneBtn"):SetText(strWorldZone .. " - " .. nPercent .. "%")
		wndBigZone:FindChild("BigZoneBtn"):SetData(pepCurrEpisode)
		wndBigZone:FindChild("ZoneProgress"):SetProgress(nPercent / 100)

		-- Selected Episode specific formatting
		if self.pmHighlightedMission and self.pmHighlightedMission:GetEpisode():GetWorldZone() == pepCurrEpisode:GetWorldZone() then
			wndBigZone:FindChild("BigZoneBtn"):SetCheck(true)
			bMatchingZone = true
		elseif pepSelectedEpisode and pepSelectedEpisode:GetWorldZone() == pepCurrEpisode:GetWorldZone() then
			wndBigZone:FindChild("BigZoneBtn"):SetCheck(true)
			bMatchingZone = true
		end
	end
	wndZoneList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	if #wndZoneList:GetChildren() > 0 and not bMatchingZone then
		local wndDefaultEpisode = wndZoneList:GetChildren()[1]
		wndDefaultEpisode:FindChild("BigZoneBtn"):SetCheck(true)
		pepSelectedEpisode = wndDefaultEpisode:FindChild("BigZoneBtn"):GetData()
	end
	
	if #tEpisodeList == 0 then
		self:DrawLanding(true)		
	end
	 
	if not pepSelectedEpisode then
		return
	end

	self:DrawMissions(pepSelectedEpisode, bFullRedraw)
end

function PlayerPath:DrawLanding(bShow)
	local wndLanding = self.wndMissionLog:FindChild("PathLanding")

	if not bShow then
		wndLanding:Show(false)
		return
	end
	
	local wndOverview = wndLanding:FindChild("OverviewBody")
	local wndMissions = wndLanding:FindChild("MissionTypesBody")
	
	wndOverview:SetText(String_GetWeaselString(Apollo.GetString(ktPathTypes[self.ePlayerPath].description)))
	wndOverview:SetHeightToContentHeight()
	wndLanding:FindChild("Text"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	wndLanding:FindChild("PathLandingBG"):SetSprite(ktPathTypes[self.ePlayerPath].landingSprite)

	
	if ktPathMissionTypes[self.ePlayerPath] then
		wndMissions:DestroyChildren()
		
		for eMissionType, strIcon in pairs(ktPathMissionTypes[self.ePlayerPath]) do
			local wndMissionTypeItem = Apollo.LoadForm(self.xmlDoc, "MissionTypeItem", wndMissions, self)
			wndMissionTypeItem:FindChild("Icon"):SetSprite(ktPathMissionTypes[self.ePlayerPath][eMissionType].sprIcon)
			wndMissionTypeItem:FindChild("Text"):SetText(Apollo.GetString(ktPathMissionTypes[self.ePlayerPath][eMissionType].strTitle))
			wndMissionTypeItem:SetTooltip(Apollo.GetString(ktPathMissionTypes[self.ePlayerPath][eMissionType].strTooltip))
		end
		wndMissions:ArrangeChildrenTiles(Window.CodeEnumArrangeOrigin.LeftOrTop)
	end
	wndLanding:Show(bShow)
	self.wndMissionLog:FindChild("LeftSide"):Show(not bShow)
	self.wndMissionLog:FindChild("RightSide"):Show(not bShow)
	self.wndMissionLog:FindChild("Divider"):Show(not bShow)
end

----------------------------------------------------------------------------------------------------------
-- Rank Levels
----------------------------------------------------------------------------------------------------------

function PlayerPath:OnTopRightResetBtn(wndHandler, wndControl)
	self.wndMissionLog:FindChild("ResetSprite"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")
	self:OnRedrawLevels(nil)
end

function PlayerPath:OnTopRightUpOrDownClick(wndHandler, wndControl)
	self:OnRedrawLevels(wndHandler:GetData())
end

function PlayerPath:OnCooldownTimer(nTime)
	local fTimeRemaining = PlayerPathLib.GetPathChangeCooldown()
	
	if fTimeRemaining > 0 then
		local wndCooldown = self.wndMissionLog:FindChild("SelectPathCooldown")
		wndCooldown:FindChild("Cooldown"):SetText(String_GetWeaselString(Apollo.GetString("PlayerPath_ActivateCooldown"), PlayerPathLib.GetPathChangeCooldown() * 1000))
	else
		self.timerCooldownUpdate:Stop()
		self.wndMissionLog:FindChild("SelectPathCooldown"):Show(false)
		self.wndMissionLog:FindChild("SelectPath"):Show(true)
	end
end

function PlayerPath:OnRedrawLevels(nArgPreviewLevel)
	if not self.wndMissionLog then
		return
	end
	
	local tPathConstants = ktPathTypes[self.ePlayerPath]
	
	self.wndMissionLog:FindChild("UnlockPath"):Show(false)
	self.wndMissionLog:FindChild("SelectPath"):Show(false)
	self.wndMissionLog:FindChild("ActivePath"):Show(false)
	self.wndMissionLog:FindChild("SelectPathCooldown"):Show(false)

	local tPathStatus = PlayerPathLib.GetPathStatuses()
	if tPathStatus.tPaths[self.ePlayerPath].bUnlocked then
		if not tPathStatus.tPaths[self.ePlayerPath].bActive then
			if tPathStatus.fCooldownRemaining > 0 then
				local wndCooldown = self.wndMissionLog:FindChild("SelectPathCooldown")
				wndCooldown:FindChild("Cooldown"):SetText(String_GetWeaselString(Apollo.GetString("PlayerPath_ActivateCooldown"), tPathStatus.fCooldownRemaining * 1000))
				wndCooldown:FindChild("BypassCost"):SetAmount(PlayerPathLib.GetPathChangeCooldownBypassCost())
				wndCooldown:FindChild("ActivateNow"):SetText(String_GetWeaselString(Apollo.GetString("CRB_Colon"), Apollo.GetString("PlayerPath_Activate")))
				wndCooldown:Show(true)
				self.timerCooldownUpdate = ApolloTimer.Create(1, true, "OnCooldownTimer", self)
			else
				local wndSelect = self.wndMissionLog:FindChild("SelectPath")
				wndSelect:SetText(String_GetWeaselString(Apollo.GetString("PlayerPath_ActivatePath"), String_GetWeaselString(Apollo.GetString(tPathConstants.title))))
				wndSelect:Show(true)
			end
		else
			self.wndMissionLog:FindChild("ActivePath"):Show(true)
		end
	else
		local wndUnlock = self.wndMissionLog:FindChild("UnlockPath")
		wndUnlock:SetText(String_GetWeaselString(Apollo.GetString("PlayerPath_Unlock"), String_GetWeaselString(Apollo.GetString(tPathConstants.title))))
		wndUnlock:Show(true)
	end
	
	local nCurrentLevel = PlayerPathLib.GetPathLevel(self.ePlayerPath)
	local nDisplayLevel = nCurrentLevel

	if nArgPreviewLevel then
		nDisplayLevel = nArgPreviewLevel
	end
	
	local nLastLevelXP = PlayerPathLib.GetPathXPAtLevel(nDisplayLevel, self.ePlayerPath)
	local nCurrentXP =  PlayerPathLib.GetPathXP(self.ePlayerPath) - nLastLevelXP
	local nNeededXP = PlayerPathLib.GetPathXPAtLevel(math.min(nDisplayLevel + 1, knMaxLevel), self.ePlayerPath) - nLastLevelXP
		
	local nUpBtn = nDisplayLevel + 1
	if nUpBtn == (knMaxLevel + 1) then
		nUpBtn = 1
	end -- These loop around

	local nDownBtn = nDisplayLevel - 1
	if nDownBtn == 0 then
		nDownBtn = knMaxLevel
	end
	
	local wndPathLabel = self.wndMissionLog:FindChild("PathLabel")
		
	wndPathLabel:SetText(String_GetWeaselString(Apollo.GetString(tPathConstants.title)))
	self.wndMissionLog:FindChild("PathIcon"):SetSprite(tPathConstants.icon)
	self.wndMissionLog:FindChild("NextBtn"):SetData(nUpBtn)
	self.wndMissionLog:FindChild("PreviousBtn"):SetData(nDownBtn)
	self.wndMissionLog:FindChild("ResetBtn"):Show(nDisplayLevel ~= nCurrentLevel)
	
	local strRank = String_GetWeaselString(Apollo.GetString("Inspect_Rank"), nDisplayLevel)
	local strHoloBlueColor = "UI_BtnTextBlueNormal"
	local strGrayColor = "Gray"
	local strRedColor = "Reddish"
	local strGreenColor = "Green"
	local wndXPBar = self.wndMissionLog:FindChild("TopXPArt")
	local wndDisplayRank = self.wndMissionLog:FindChild("DisplayRank")
	local nDisplayXP = 0
		
	if tPathStatus.tPaths[self.ePlayerPath].bActive then
		wndPathLabel:FindChild("PathStatusLabel"):SetText(Apollo.GetString("PlayerPath_CurrentPath"))
		wndPathLabel:FindChild("PathStatusLabel"):SetTextColor(strGreenColor)
	elseif not tPathStatus.tPaths[self.ePlayerPath].bUnlocked then
		wndPathLabel:FindChild("PathStatusLabel"):SetText(Apollo.GetString("PlayerPath_LockedPath"))
		wndPathLabel:FindChild("PathStatusLabel"):SetTextColor(strRedColor)
	elseif tPathStatus.tPaths[self.ePlayerPath].bUnlocked and not tPathStatus.tPaths[self.ePlayerPath].bActive then
		wndPathLabel:FindChild("PathStatusLabel"):SetText(Apollo.GetString("PlayerPath_InactivePath"))
		wndPathLabel:FindChild("PathStatusLabel"):SetTextColor(strGrayColor)
	end
	
	wndDisplayRank:SetText(strRank)
	wndXPBar:FindChild("TopXPProgressBar"):SetMax(nNeededXP)
	
	if nDisplayLevel > nCurrentLevel then
		strRankColor = strRedColor
		nDisplayXP = 0
	elseif nDisplayLevel == nCurrentLevel then
		strRankColor = strHoloBlueColor
		nDisplayXP = nCurrentXP
	elseif nDisplayLevel < nCurrentLevel then
		strRankColor = strGrayColor
		nDisplayXP = nNeededXP
	end
	
	wndDisplayRank:SetTextColor(strRankColor)
	wndXPBar:FindChild("TopXPProgressBar"):SetProgress(nDisplayXP)
	
	-- Max level display changes
	self.wndMissionLog:FindChild("MaxLevelInfo"):Show(nDisplayLevel == knMaxLevel)
	wndXPBar:FindChild("PathComplete"):Show(nDisplayLevel == knMaxLevel)
	wndXPBar:FindChild("TopXPProgressBar"):Show(nDisplayLevel ~= knMaxLevel)
	
	-- Rewards
	local wndRewards = self.wndMissionLog:FindChild("RewardsContainer")
	wndRewards:Show(nDisplayLevel ~= knMaxLevel)
	wndRewards:DestroyChildren()
	
	tPathData = PlayerPathLib.GetPathLevelData(nDisplayLevel + 1, self.ePlayerPath)
	if tPathData then
		for idx, tCurrReward in pairs(tPathData.tRewards) do
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "TopRewardItem", wndRewards, nil)
			self:DrawRewardItem(idx, wndCurr, tCurrReward)
			wndCurr:FindChild("RewardLootedIcon"):Show(nDisplayLevel < nCurrentLevel) -- exists, but looted
		end
	end

	wndRewards:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

----------------------------------------------------------------------------------------------------------
-- Missions
----------------------------------------------------------------------------------------------------------

function PlayerPath:DrawMissions(tSelectedEpisode, bFullRedraw)
	if bFullRedraw then
		if self.wndAvailable and self.wndAvailable:IsValid() then
			self.wndAvailable:Destroy()
		end
		
		self.wndMissionLog:FindChild("PathLanding"):Show(false)
		self.wndMissionLog:FindChild("LeftSide"):Show(true)
		self.wndMissionLog:FindChild("RightSide"):Show(true)
		self.wndMissionLog:FindChild("Divider"):Show(true)
					
		self.wndAvailable = self:FactoryProduce(self.wndMissionLog:FindChild("MissionList"), "MissionContainerForm", Apollo.GetString("CRB_CallbackAvailable"))
		self.wndAvailable:FindChild("HeaderBtn"):SetCheck(true)
		
		if self.wndCompleted and self.wndCompleted:IsValid() then
			self.wndCompleted:Destroy()
		end
		
		self.wndCompleted = self:FactoryProduce(self.wndMissionLog:FindChild("MissionList"), "MissionContainerForm", Apollo.GetString("QuestCompleted"))
		
		self:HelperDrawCategoryMissions(self.wndAvailable, tSelectedEpisode)
		self:HelperDrawCategoryMissions(self.wndCompleted, tSelectedEpisode)

		-- Zone Rewards
		local bFoundAReward = false
		self.wndMissionLog:FindChild("EpisodeRewardList"):DestroyChildren()

	    for idx, tReward in ipairs(tSelectedEpisode:GetRewards()) do
			bFoundAReward = true
	        local wndReward = Apollo.LoadForm(self.xmlDoc, "RewardItem", self.wndMissionLog:FindChild("EpisodeRewardList"), self)
			self:DrawRewardItem(idx, wndReward, tReward)
			wndReward:FindChild("RewardLootedIcon"):Show(tSelectedEpisode:IsComplete()) -- exists, but looted
	    end	
	
		self.wndMissionLog:FindChild("EpisodeSummary"):SetText(tSelectedEpisode:GetWorldZone())
		self.wndMissionLog:FindChild("RewardContainer"):Show(bFoundAReward)
		self.wndMissionLog:FindChild("EpisodeRewardList"):ArrangeChildrenVert()
	else
		--REDRAW Some category
		local tMissionListChildren = self.wndMissionLog:FindChild("MissionList"):GetChildren()
		local wndRedraw = nil
		if self.strLastExpanded then
			local bAvailableContainer = self.strLastExpanded == Apollo.GetString("CRB_CallbackAvailable") 
			wndRedraw = bAvailableContainer and tMissionListChildren[1]  or tMissionListChildren[2]
		end
		
		if wndRedraw then
			self:HelperDrawCategoryMissions(wndRedraw, tSelectedEpisode)
			self.strLastExpanded = nil
		end
	end

	self:ResizeItems()
end

function PlayerPath:HelperDrawCategoryMissions(wndRedraw, tSelectedEpisode)
	if not wndRedraw then
		return
	end

	local strCategory = wndRedraw:FindChild("HeaderBtn"):GetText()
	local bIsAvailableContainer = strCategory == Apollo.GetString("CRB_CallbackAvailable")
	local nComplete = 0
	local nToUnlock = 0
	local nAlreadyFound = 0

	local wndNewContainer = self:FactoryProduce(self.wndMissionLog:FindChild("MissionList"), "MissionContainerForm", strCategory)
	wndRedraw:FindChild("HeaderContainer"):DestroyChildren()

	local bSelectedFound = false
	local nAutoScrollHeight = -1 * (wndNewContainer:FindChild("HeaderBtn"):GetHeight() + knAutoScrollPadding)--initial padding
	for key, pmMission in ipairs(tSelectedEpisode:GetMissions()) do
		if pmMission:GetMissionState() == PathMission.PathMissionState_NoMission then
			nToUnlock = nToUnlock + 1
		else
			nAlreadyFound = nAlreadyFound + 1
			local bIsComplete = pmMission:IsComplete()
			if bIsComplete then
				nComplete = nComplete + 1
			end

			if (bIsComplete and not bIsAvailableContainer) or (not bIsComplete and bIsAvailableContainer) then
				local wndCurr = Apollo.LoadForm(self.xmlDoc, "MissionListItem", wndNewContainer:FindChild("HeaderContainer"), self)
				self:DrawMissionItem(wndCurr, pmMission)
				if not bSelectedFound then
					nAutoScrollHeight = nAutoScrollHeight + wndCurr:GetHeight()
				end
				if wndCurr:FindChild("MissionItemHighlightRunner"):IsShown() then
					bSelectedFound = true
				end	
			end
		end
	end
	
	--The scroll position should be set after the container has finished creating and resizing the categories.
	if bSelectedFound then
		self.nSetScrollPos = nAutoScrollHeight
	end

	if bIsAvailableContainer then
		wndNewContainer:Show(nAlreadyFound - nComplete > 0)
	else
		wndNewContainer:Show(nComplete > 0)
	end
	
	if bIsAvailableContainer then
		wndNewContainer:FindChild("HeaderBtn"):SetCheck(true)
	end
	
	local strComplete = String_GetWeaselString(Apollo.GetString("CRB_Fraction"), nComplete, nAlreadyFound)
	self.wndMissionLog:FindChild("EmptyLabel"):Show(nAlreadyFound == 0)
	self.wndMissionLog:FindChild("EpisodeCompletedValue"):SetText(String_GetWeaselString(Apollo.GetString("Contracts_CompletedTooltip"), strComplete))
	self.wndMissionLog:FindChild("EpisodeUndiscoveredValue"):SetText(String_GetWeaselString(Apollo.GetString("PlayerPath_UndiscoveredCount"), nToUnlock))
end

function PlayerPath:ResizeItems()
	if self.wndAvailable:FindChild("HeaderBtn"):IsChecked() then
		local nHeight = 0
		for idx, wndCurr in pairs(self.wndAvailable:FindChild("HeaderContainer"):GetChildren()) do
			local nLeft, nTop, nRight, nBottom = wndCurr:GetAnchorOffsets()
			nHeight = nHeight + (nBottom - nTop)
		end
		local nLeft, nTop, nRight, nBottom = self.wndAvailable:GetAnchorOffsets()
		self.wndAvailable:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + 65)
		self.wndAvailable:FindChild("HeaderContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		self.wndAvailable:FindChild("HeaderContainer"):Show(true)
	else
		self.wndAvailable:FindChild("HeaderContainer"):Show(false)
	end

	if self.wndCompleted:FindChild("HeaderBtn"):IsChecked() then
		nHeight = 0
		for idx, wndCurr in pairs(self.wndCompleted:FindChild("HeaderContainer"):GetChildren()) do
			local nLeft, nTop, nRight, nBottom = wndCurr:GetAnchorOffsets()
			nHeight = nHeight + (nBottom - nTop)
		end
		nLeft, nTop, nRight, nBottom = self.wndCompleted:GetAnchorOffsets()
		self.wndCompleted:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + 65)
		self.wndCompleted:FindChild("HeaderContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		self.wndCompleted:FindChild("HeaderContainer"):Show(true)
	else
		self.wndCompleted:FindChild("HeaderContainer"):Show(false)
	end

	local nWindowHeight = self.wndMissionLog:FindChild("MissionList"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nListLeft, nListTop, nListRight, nListBottom = self.wndMissionLog:FindChild("MissionList"):GetOriginalLocation():GetOffsets()
	
	self.wndMissionLog:FindChild("MissionList"):SetAnchorOffsets(nListLeft, nListTop, nListRight,  nListBottom + nWindowHeight)
	
	if self.nSetScrollPos then
		self.wndMissionLog:FindChild("MissionList"):SetVScrollPos(self.nSetScrollPos)
		self.nSetScrollPos = nil
	end
	
	self.wndMissionLog:FindChild("RightSide"):RecalculateContentExtents()
end

function PlayerPath:DrawMissionItem(wnd, pmMission)
	local bComplete = pmMission:IsComplete()

	local strSummary = "???"
	local strExtraText = ""
	if bComplete and pmMission:GetCompletedString() ~= "" then
		strSummary = pmMission:GetCompletedString()
	elseif not bComplete and pmMission:GetSummary() ~= "" then
		strSummary = pmMission:GetSummary()
		strExtraText = pmMission:GetUnlockString()
	end
	
	local tSettlerReward = pmMission:GetSettlerMayorInfo()
	local tSettlerRewardSheriff = pmMission:GetSettlerSheriffInfo()	
	
	if tSettlerReward ~= nil and tSettlerReward.titleReward ~= nil  then
		wnd:FindChild("PathRewardIcon"):Show(true)
		wnd:FindChild("PathRewardIcon"):SetTooltip(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffffffff\">%s</P>", String_GetWeaselString(Apollo.GetString("Achievements_RewardTitle"), tSettlerReward.titleReward:GetTitle())))
	end
	
	if tSettlerRewardSheriff ~= nil and tSettlerRewardSheriff .arTitles ~= nil  then
		wnd:FindChild("PathRewardIcon"):Show(true)
		wnd:FindChild("PathRewardIcon"):SetTooltip(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffffffff\">%s</P>", String_GetWeaselString(Apollo.GetString("Achievements_RewardTitle"), tSettlerRewardSheriff .arTitles:GetTitle())))
	end
	
	if pmMission:IsComplete() then
		wnd:FindChild("MissionItemIcon"):SetSprite("MissionLog_TEMP:spr_TEMP_MLog_CheckMark") -- todo hardcoded formatting
	else
		wnd:FindChild("MissionItemIcon"):SetSprite(self:HelperComputeIconPath(pmMission))
	end
	
	wnd:SetData(pmMission)
	wnd:FindChild("MissionItemName"):SetText(pmMission:GetName())
				
	wnd:FindChild("MissionItemProgress"):Show(not bComplete)
	wnd:FindChild("MissionItemProgress"):SetTextColor(kcrNormalTextColor)
	wnd:FindChild("MissionItemProgress"):SetText(self:HelperComputeMissionProgress(pmMission))
	wnd:FindChild("MissionItemHighlightRunner"):Show(pmMission == self.pmHighlightedMission)
	wnd:FindChild("MissionItemSummary"):SetText(string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBody\">%s</P>", strSummary))
	wnd:FindChild("MissionItemExtraText"):SetText(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"UI_TextHoloBodyCyan\">%s</P>", strExtraText))

	-- Resize
	local nTextWidth1, nTextHeight1 = wnd:FindChild("MissionItemSummary"):SetHeightToContentHeight()
	local nTextWidth2, nTextHeight2 = wnd:FindChild("MissionItemExtraText"):SetHeightToContentHeight()
	local nLeft, nTop, nRight, nBottom = wnd:GetAnchorOffsets()
	wnd:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTextHeight1 + nTextHeight2 + 50)

	-- Shift Mission Extra Text below ItemSummary
	local nBottomOfItemSummary = nTextHeight1 + 40
	nLeft, nTop, nRight, nBottom = wnd:FindChild("MissionItemExtraText"):GetAnchorOffsets()
	wnd:FindChild("MissionItemExtraText"):SetAnchorOffsets(nLeft, nBottomOfItemSummary, nRight, nBottomOfItemSummary + nTextHeight2)

	return nHeight
end

---------------------------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------------------------

function PlayerPath:OnGenerateTooltip(wndHandler, wndControl, eType, arg1, arg2)
	local xml = nil
	if eType == Tooltip.TooltipGenerateType_ItemData and arg1 then
		Tooltip.GetItemTooltipForm(self, wndControl, arg1, {bPrimary = true, bSelling = self.bVendorOpen, itemCompare = arg1:GetEquippedItemForItemType()}, arg2)
	elseif eType == Tooltip.TooltipGenerateType_Reputation then
		xml = XmlDoc.new()
		xml:StartTooltip(Tooltip.TooltipWidth)
		xml:AddLine(arg1)
	elseif eType == Tooltip.TooltipGenerateType_Money then
		xml = XmlDoc.new()
		xml:StartTooltip(Tooltip.TooltipWidth)
		xml:AddLine(arg1:GetMoneyString(), CColor.new(1, 1, 1, 1), "CRB_InterfaceMedium")
	elseif eType == Tooltip.TooltipGenerateType_Spell then
		Tooltip.GetSpellTooltipForm(self, wndControl, arg1)
	end

    if xml then
        wndControl:SetTooltipDoc(xml)
    end
end

function PlayerPath:HelperComputeMissionProgress(pmMission)
	local strResult = ""
	local eMissionType = pmMission:GetType()
	local nNumNeeded = pmMission:GetNumNeeded()
	local nNumCompleted = pmMission:GetNumCompleted()

	if self.ePlayerPath == PlayerPathLib.PlayerPathType_Soldier then
		if eMissionType == PathMission.PathMissionType_Soldier_Holdout and pmMission:GetSoldierHoldout() then
			local seEvent = pmMission:GetSoldierHoldout()
			local eType = seEvent:GetType()
			if eType == PathMission.PathSoldierEventType_Holdout 
				or eType == PathMission.PathSoldierEventType_Defend 
				or eType == PathMission.PathSoldierEventType_TowerDefense
				or eType == PathMission.PathSoldierEventType_StopTheThieves then
				strResult = String_GetWeaselString(Apollo.GetString("ChallengeReward_Multiplier"), seEvent:GetWaveCount())
			elseif eType == PathMission.PathSoldierEventType_Timed 
				or eType == PathMission.PathSoldierEventType_TimedDefend 
				or eType == PathMission.PathSoldierEventType_WhackAMoleTimed
				or eType == PathMission.PathSoldierEventType_StopTheThievesTimed then
				strResult = self:HelperCalcTime(seEvent:GetMaxTime()/1000)
			end
		elseif nNumNeeded > 0 then
			strResult = nNumCompleted .. "/" .. nNumNeeded
		end

	elseif self.ePlayerPath == PlayerPathLib.PlayerPathType_Explorer then

		if eMissionType == PathMission.PathMissionType_Explorer_ExploreZone then
			if pmMission:IsComplete() then
				strResult = String_GetWeaselString(Apollo.GetString("CRB_Percent"), 100)
			else
				strResult = String_GetWeaselString(Apollo.GetString("CRB_Percent"), pmMission:GetNumCompleted())
			end
		elseif nNumNeeded > 0 then
			strResult = nNumCompleted .. "/" .. nNumNeeded
		end

	elseif self.ePlayerPath == PlayerPathLib.PlayerPathType_Settler then

		if eMissionType == PathMission.PathMissionType_Settler_Hub or PathMission.PathMissionType_Settler_Infrastructure then
			strResult = nNumCompleted .. "/" .. nNumNeeded
		end
	end

	return strResult
end

function PlayerPath:HelperComputeIconPath(pmMission)
	local eType = pmMission:GetType()
	local eSubType = pmMission:GetSubType()

	if ktPathMissionTypes[self.ePlayerPath][eType] then
		return ktPathMissionTypes[self.ePlayerPath][eType].sprIcon
	elseif ktPathMissionSubtypeSprites[self.ePlayerPath] then
		return ktPathMissionSubtypeSprites[self.ePlayerPath][eSubType]
	else 
		return ktPathMissionTypeDefaultSprites[self.ePlayerPath]
	end
end

function PlayerPath:DrawRewardItem(idx, wndReward, tReward) -- TODO: This is for zone completion, remove it when possible
	if not wndReward or not tReward then return end

	if tReward.eType == PlayerPathLib.PathRewardType_Item then
		wndReward:FindChild("RewardItemName"):SetTextColor(karEvalColors[tReward.itemReward:GetItemQuality()])
		wndReward:FindChild("RewardItemName"):SetText(tReward.itemReward:GetName())
		wndReward:FindChild("RewardItemIcon"):SetItemInfo(tReward.itemReward, tReward.nCount)
	elseif tReward.eType == PlayerPathLib.PathRewardType_Spell then
		wndReward:FindChild("RewardItemName"):SetText(tReward.splReward:GetName())
		wndReward:FindChild("RewardItemIcon"):SetSpellInfo(tReward.splReward)
		wndReward:FindChild("RewardItemIcon"):SetTooltip("<P Font=\"CRB_InterfaceSmall\" TextColor=\"ff9d9d9d\">"..tReward.splReward:GetName().."</P>")
	elseif tReward.eType == PlayerPathLib.PathRewardType_Quest then
		wndReward:FindChild("RewardItemName"):SetText(tReward.queReward:GetTitle())
		wndReward:FindChild("RewardItemIcon"):SetSprite("ClientSprites:UI_Temp_Quest")
		wndReward:FindChild("RewardItemIcon"):SetTooltip("<P Font=\"CRB_InterfaceSmall\" TextColor=\"ff9d9d9d\">"..tReward.queReward:GetTitle().."</P>")
	elseif tReward.eType == PlayerPathLib.PathRewardType_Title then
		wndReward:FindChild("RewardItemName"):SetText(String_GetWeaselString(Apollo.GetString("PlayerPath_Title"), tReward.strTitleName))
		wndReward:FindChild("RewardItemIcon"):SetSprite("ClientSprites:Icon_ItemMisc_letter_0001")
		wndReward:FindChild("RewardItemIcon"):SetTooltip(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"ff9d9d9d\">%s</P>", String_GetWeaselString(Apollo.GetString("PlayerPath_Title"), tReward.strTitleName)))
	elseif tReward.eType == PlayerPathLib.PathRewardType_ScanBot then
		wndReward:FindChild("RewardItemName"):SetText(String_GetWeaselString(Apollo.GetString("PlayerPath_Scanbot"), tReward.sbpReward:GetName()))
		wndReward:FindChild("RewardItemIcon"):SetSprite("ClientSprites:Icon_ItemMisc_letter_0001")
		wndReward:FindChild("RewardItemIcon"):SetTooltip(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"ff9d9d9d\">%s</P>", String_GetWeaselString(Apollo.GetString("PlayerPath_Title"), tReward.sbpReward:GetName())))
	end
end

function PlayerPath:HelperCalcTime(fSeconds)
	if fSeconds <= 0 then return "" end
	local nSecs = math.floor(fSeconds % 60)
	local nMins = math.floor(fSeconds / 60)
	return string.format("%d:%02d", nMins, nSecs)
end

function PlayerPath:FactoryProduce(wndParent, strFormName, strCategoryName)
	local wndNew = wndParent:FindChildByUserData(strCategoryName)
	if not wndNew then
		wndNew = Apollo.LoadForm(self.xmlDoc, strFormName, wndParent, self)
		wndNew:SetData(strCategoryName)
		wndNew:FindChild("HeaderBtn"):SetText(strCategoryName)
	end
	
	return wndNew
end

---------------------------------------------------------------------------------------------------
-- MissionLog Functions
---------------------------------------------------------------------------------------------------

function PlayerPath:PathLogTypeSelectionChanged( wndHandler, wndControl, eMouseButton )
	if not wndControl:IsChecked() then
		return
	end
	
	for ePathType, wndButton in pairs(self.tPathTypeBtns) do
		if wndButton == wndControl then
			self.ePlayerPath = ePathType
			break
		end
	end
	
	self:OnRedrawLevels(nil)	
	self:PathRefresh(nil, true)
end

function PlayerPath:OnUnlockPath( wndHandler, wndControl, eMouseButton )
	local wndConfirmationOverlay = self.wndMissionLog:FindChild("ConfirmationOverlay")
	local tConfirmationData =
	{
		monCost = PlayerPathLib.GetPathUnlockCost(),
		wndParent = wndConfirmationOverlay,
		strConfirmation = String_GetWeaselString(Apollo.GetString("PlayerPath_ConfirmUnlock"), Apollo.GetString(ktPathTypes[self.ePlayerPath].title)),
		tActionData = { GameLib.CodeEnumConfirmButtonType.UnlockPath, self.ePlayerPath },
		strEventName = "ServiceTokenClosed_PlayerPath",
	}
	wndConfirmationOverlay:FindChild("ConfirmActivate"):Show(false)
	wndConfirmationOverlay:Show(true)
	Event_FireGenericEvent("GenericEvent_ServiceTokenPrompt", tConfirmationData)
end

function PlayerPath:OnSelectPath( wndHandler, wndControl, eMouseButton )
	local wndConfirmationOverlay = self.wndMissionLog:FindChild("ConfirmationOverlay")
	local wndConfirmDialog = wndConfirmationOverlay:FindChild("ConfirmActivate")
	
	wndConfirmationOverlay:FindChild("ActivateError"):Show(false)

	if PlayerPathLib.GetPathChangeCooldown() > 0 then
		local tConfirmationData =
		{
			monCost = PlayerPathLib.GetPathChangeCooldownBypassCost(),
			wndParent = wndConfirmationOverlay,
			strConfirmation = String_GetWeaselString(Apollo.GetString("PlayerPath_ConfirmActivateCooldown")),
			tActionData = { GameLib.CodeEnumConfirmButtonType.ChangePath, self.ePlayerPath },
			strEventName = "ServiceTokenClosed_PlayerPath",
		}
		wndConfirmDialog:Show(false)
		wndConfirmationOverlay:Show(true)
		Event_FireGenericEvent("GenericEvent_ServiceTokenPrompt", tConfirmationData)
	else
		wndConfirmDialog:FindChild("ActionConfirmButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.ChangePath, self.ePlayerPath)
		wndConfirmDialog:Show(true)
		wndConfirmationOverlay:Show(true)
	end
end

function PlayerPath:OnServiceTokenDialogClosed(strParent)
	if not self.wndMissionLog then
		return
	end
	
	local wndParent = self.wndMissionLog:FindChild(strParent)
	if wndParent then
		wndParent:Show(false)
	end
end

function PlayerPath:CancelActivation( wndHandler, wndControl, eMouseButton )
	local wndConfirmationOverlay = self.wndMissionLog:FindChild("ConfirmationOverlay")
	wndConfirmationOverlay:Show(false)
end

function PlayerPath:OnPathChangeResult( nResult )
	local wndConfirmationOverlay = self.wndMissionLog:FindChild("ConfirmationOverlay")
	if not wndConfirmationOverlay:IsShown() then
		return
	end

	if nResult == GameLib.CodeEnumGenericError.Ok then
		wndConfirmationOverlay:Show(false)
	elseif nResult ~= GameLib.CodeEnumGenericError.PathChange_Requested then
		wndConfirmationOverlay:FindChild("ConfirmActivate"):Show(false)
		local wndError = wndConfirmationOverlay:FindChild("ActivateError")
		local strError = ktPathChangeResults[nResult]
		
		if not strError then
			strError = Apollo.GetString("UnknownError")
		end

		wndError:FindChild("Message"):SetText(strError)
		wndError:Show(true)
	end
end

function PlayerPath:CloseErrorWindow( wndHandler, wndControl, eMouseButton )
	local wndConfirmationOverlay = self.wndMissionLog:FindChild("ConfirmationOverlay")
	wndConfirmationOverlay:FindChild("ActivateError"):Show(false)
	wndConfirmationOverlay:Show(false)
end

----------------------------------------------------------------------------------------------------------
-- Global
----------------------------------------------------------------------------------------------------------
local PlayerPathInstance = PlayerPath:new()
PlayerPathInstance:Init()
