-----------------------------------------------------------------------------------------------
-- Client Lua Script for ChallengeTracker
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "ChallengesLib"
require "Challenges"

local kstrChallengeQuesttMarker = "000ChallengeContent"
local kstrLightGrey = "ffb4b4b4"

local knUXHideIfTooMany = 3 --By default lets minimize optional categories if there's more than 2 children so it's not overwhelming.
local knXCursorOffset = 10
local knYCursorOffset = 25

local kstrObjectiveType =  Apollo.GetString("Challenges")

local karTypeToFormattedString =
{
	[ChallengesLib.ChallengeType_Combat] 				= "Challenges_CombatChallenge",
	[ChallengesLib.ChallengeType_Ability] 				= "Challenges_AbilityChallenge",
	[ChallengesLib.ChallengeType_General] 				= "Challenges_GeneralChallenge",
	[ChallengesLib.ChallengeType_Item] 					= "Challenges_ItemChallenge",
	[ChallengesLib.ChallengeType_ChecklistActivate] 	= "Challenges_ActivateChallenge",
}

local karTierIdxToWindowName =
{
	[0] = "",
	[1] = "Bronze",
	[2] = "Silver",
	[3] = "Gold",
}

local karTierIdxToTextColor =
{
	[0] = "UI_WindowTextDefault",
	[1] = "Bronze",
	[2] = "Silver",
	[3] = "PaleGold",
}

local karTierIdxToStarSprite =
{
	[0] = "Challenges:sprChallenges_starBlack",
	[1] = "Challenges:sprChallenges_starBronze",
	[2] = "Challenges:sprChallenges_starSilver",
	[3] = "Challenges:sprChallenges_starGold",
}

local karTierIdxToMedalSprite =
{
	[0] = "",
	[1] = "CRB_ChallengeTrackerSprites:sprChallengeTierBronze32",
	[2] = "CRB_ChallengeTrackerSprites:sprChallengeTierSilver32",
	[3] = "CRB_ChallengeTrackerSprites:sprChallengeTierGold32",
}

local ChallengeTracker = {}
function ChallengeTracker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	
	-- Window Management
	o.tChallengeWndCache = {}
	o.tCategories = {}
	
	-- Data
	o.tNeedsRealTimeUpdate = {}
	o.tChallengeCompare = {}
	o.tLootChallenges = {}
	o.tDistanceCache = {}
	
	-- Saved Data
	o.tHidden = {}
	o.tMinimized = {}
	o.bShowChallenges = true
	o.bFilterLimit = true
	o.bFilterDistance = true
	o.nMaxMissionLimit = 3
	o.nMaxMissionDistance = 300
	
    return o
end

function ChallengeTracker:Init()
    Apollo.RegisterAddon(self)
end

function ChallengeTracker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ChallengeTracker.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	self.timerResizeDelay = ApolloTimer.Create(0.1, false, "OnResizeDelayTimer", self)
	self.timerResizeDelay:Stop()
	
	self.timerRealTimeUpdate = ApolloTimer.Create(1.0, true, "OnRealTimeUpdateTimer", self)
	self.timerRealTimeUpdate:Stop()
end

function ChallengeTracker:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	return
	{
		tMinimized = self.tMinimized,
		tHidden = self.tHidden,
		bShowChallenges = self.bShowChallenges,
		nMaxMissionLimit = self.nMaxMissionLimit,
		nMaxMissionDistance = self.nMaxMissionDistance,
		bFilterLimit = self.bFilterLimit,
		bFilterDistance = self.bFilterDistance,
	}
end

function ChallengeTracker:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	if tSavedData.tMinimized ~= nil then
		self.tMinimized = tSavedData.tMinimized
	end
	
	if tSavedData.tHidden ~= nil then
		self.tHidden = tSavedData.tHidden
	end
	
	if tSavedData.bShowChallenges ~= nil then
		self.bShowChallenges = tSavedData.bShowChallenges
	end
	
	if tSavedData.nMaxMissionLimit ~= nil then
		self.nMaxMissionLimit = tSavedData.nMaxMissionLimit
	end
	
	if tSavedData.nMaxMissionDistance ~= nil then
		self.nMaxMissionDistance = tSavedData.nMaxMissionDistance
	end
	
	if tSavedData.bFilterLimit ~= nil then
		self.bFilterLimit = tSavedData.bFilterLimit
	end
	
	if tSavedData.bFilterDistance ~= nil then
		self.bFilterDistance = tSavedData.bFilterDistance
	end
end

function ChallengeTracker:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("ObjectiveTrackerLoaded", "OnObjectiveTrackerLoaded", self)
	Event_FireGenericEvent("ObjectiveTracker_RequestParent")
end

function ChallengeTracker:OnObjectiveTrackerLoaded(wndForm)
	if not wndForm or not wndForm:IsValid() then
		return
	end

	Apollo.RemoveEventHandler("ObjectiveTrackerLoaded", self)
	
	Apollo.RegisterEventHandler("ToggleShowChallenges", "OnToggleShowChallenges", self)
	Apollo.RegisterEventHandler("ToggleChallengeOptions", "OnToggleChallengeOptions", self)
	
	Apollo.RegisterEventHandler("SubZoneChanged", "OnSubZoneChanged", self)
	Apollo.RegisterEventHandler("ChallengeAbandon", "OnChallengeAbandon", self)
	Apollo.RegisterEventHandler("ChallengeActivate", "OnChallengeActivate", self)
	Apollo.RegisterEventHandler("ChallengeAreaRestriction", "OnChallengeAreaRestriction", self)
	Apollo.RegisterEventHandler("ChallengeCompleted", "OnChallengeCompleted", self)
	Apollo.RegisterEventHandler("ChallengeCooldownActive", "OnChallengeCooldownActive", self)
	Apollo.RegisterEventHandler("ChallengeFailArea", "OnChallengeFailArea", self)
	Apollo.RegisterEventHandler("ChallengeFailGeneric", "OnChallengeFailGeneric", self)
	Apollo.RegisterEventHandler("ChallengeFailTime", "OnChallengeFailTime", self)
	Apollo.RegisterEventHandler("ChallengeLeftArea", "OnChallengeLeftArea", self)
	Apollo.RegisterEventHandler("ChallengeRewardListReady", "OnChallengeRewardListReady", self)
	Apollo.RegisterEventHandler("ChallengeRewardReady", "OnChallengeRewardReady", self)
	Apollo.RegisterEventHandler("ChallengeTierAchieved", "OnChallengeTierAchieved", self)
	Apollo.RegisterEventHandler("ChallengeTimeUpdated", "OnChallengeTimeUpdated", self)
	Apollo.RegisterEventHandler("ChallengeUnlocked", "OnChallengeUnlocked", self)
	Apollo.RegisterEventHandler("ChallengeUpdated", "OnChallengeUpdated", self)
	
	self.wndTracker = Apollo.LoadForm(self.xmlDoc, "Container", wndForm, self)
	
	local strKey = self.wndTracker:FindChild("Title"):GetText()
	self.wndTracker:FindChild("MinimizeBtn"):SetData(strKey)
	self.wndTracker:FindChild("MinimizeBtn"):SetCheck(self.tMinimized[strKey])
	self.wndTracker:FindChild("MinimizeBtn"):Show(self.tMinimized[strKey])
	self.wndTracker:SetData(kstrChallengeQuesttMarker)
	self.wndTrackerContent = self.wndTracker:FindChild("Content")
	self.knInitialEpisodeGroupHeight = self.wndTracker:GetHeight()
	
	self.wndTrackerActive = Apollo.LoadForm(self.xmlDoc, "Category", self.wndTrackerContent, self)
	self.wndTrackerActive:SetData({strKey = Apollo.GetString("QuestLog_Active"), bCanHide = false})
	self.wndTrackerActiveContent = self.wndTrackerActive:FindChild("Content")
	
	self.wndTrackerLoot = Apollo.LoadForm(self.xmlDoc, "Category", self.wndTrackerContent, self)
	self.wndTrackerLoot:SetData({strKey = Apollo.GetString("Challenges_LootRewards"), bCanHide = false})
	self.wndTrackerLootContent = self.wndTrackerLoot:FindChild("Content")
	
	self.wndTrackerAvailable = Apollo.LoadForm(self.xmlDoc, "Category", self.wndTrackerContent, self)
	self.wndTrackerAvailable:SetData({strKey = Apollo.GetString("ChallengeUnlockedHeader"), bCanHide = true})
	self.wndTrackerAvailableContent = self.wndTrackerAvailable:FindChild("Content")
	
	self.wndTrackerRepeat = Apollo.LoadForm(self.xmlDoc, "Category", self.wndTrackerContent, self)
	self.wndTrackerRepeat:SetData({strKey = Apollo.GetString("Challenges_Repeatable"), bCanHide = true})
	self.wndTrackerRepeatContent = self.wndTrackerRepeat:FindChild("Content")
	
	local tData =
	{
		["strAddon"] = kstrObjectiveType,
		["strEventMouseLeft"] = "ToggleShowChallenges", 
		["strEventMouseRight"] = "ToggleChallengeOptions", 
		["strIcon"] = "spr_ObjectiveTracker_IconChallenge",
		["strDefaultSort"] = kstrChallengeQuesttMarker,
	}
	Event_FireGenericEvent("ObjectiveTracker_NewAddOn", tData)
	
	self:BuildAll()
	self:ResizeAll()
end

---------------------------------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------------------------------

function ChallengeTracker:OnRealTimeUpdateTimer(nTime)
	for idChallenge, clgChallenge in pairs(self.tNeedsRealTimeUpdate) do
		self:BuildChallenge(clgChallenge)
	end
	
	if self.bFilterDistance then
		self:ResizeAll()
	end
	
	if next(self.tNeedsRealTimeUpdate) == nil and not self.bFilterDistance then
		self.timerRealTimeUpdate:Stop()
	end
end

function ChallengeTracker:OnResizeDelayTimer(nTime)
	self:ResizeAll()
end

function ChallengeTracker:BuildAll()
	local idCurrentZone = GameLib.GetCurrentZoneId()

	local tChallenges = {}
	for _, clgCurrent in pairs(ChallengesLib.GetActiveChallengeList()) do
		local tZoneInfo = clgCurrent:GetZoneInfo()
		if clgCurrent:IsActivated() or clgCurrent:GetTimer() or (tZoneInfo ~= nil and tZoneInfo.idZone == idCurrentZone) then
			tChallenges[clgCurrent:GetId()] = true
			self:BuildChallenge(clgCurrent)
		end
	end
	
	for idChallenge, wndChallenge in pairs(self.tChallengeWndCache) do
		if tChallenges[idChallenge] == nil then
			wndChallenge:Destroy()
			self.tChallengeWndCache[idChallenge] = nil
		end
	end
end

function ChallengeTracker:GetDistance(clgChallenge)
	local nDistance = self.tDistanceCache[clgChallenge:GetId()]
	if nDistance == nil then
		nDistance = clgChallenge:GetDistance()
		self.tDistanceCache[clgChallenge:GetId()] = nDistance
	end
	
	return nDistance
end

function ChallengeTracker:ResizeAll()
	self.timerResizeDelay:Stop()
	local nStartingHeight = self.wndTracker:GetHeight()
	local bStartingShown = self.wndTracker:IsShown()
	
	self.tDistanceCache = {}

	-- Inline Sort Method
	local function SortChallenges(clgA, clgB)
		if clgA:GetTimer() == 0 and clgB:GetTimer() == 0 then
			return self:GetDistance(clgA) < self:GetDistance(clgB)
		else
			return clgA:GetTimer() < clgB:GetTimer()
		end
	end
	
	local arChallenges = {}
	
	for _, clgCurrent in pairs(ChallengesLib.GetActiveChallengeList()) do
		if clgCurrent:GetTimer() then
			table.insert(arChallenges, clgCurrent)
		end
	end
	
	table.sort(arChallenges, SortChallenges)
	
	local tDisplayedChallenges = {}
	local nChallengesShown = 0
	local nChallengesFiltered = 0
	
	for idx, clgCurrent in ipairs(arChallenges) do
		if clgCurrent:IsActivated() then
			tDisplayedChallenges[clgCurrent:GetId()] = true
			nChallengesShown = nChallengesShown + 1
		else
			if (not self.bFilterLimit or nChallengesFiltered < self.nMaxMissionLimit) and (not self.bFilterDistance or self:GetDistance(clgCurrent) < self.nMaxMissionDistance) then				
				tDisplayedChallenges[clgCurrent:GetId()] = true
				nChallengesShown = nChallengesShown + 1
				nChallengesFiltered = nChallengesFiltered + 1
			end
		end
	end
	
	for idChallenge, wndChallenge in pairs(self.tChallengeWndCache) do
		wndChallenge:Show(tDisplayedChallenges[idChallenge] ~= nil)
	end
	
	self.wndTracker:Show(nChallengesShown > 0 and self.bShowChallenges)
	if self.wndTracker:IsShown() then
		local strKey = self.wndTracker:FindChild("Title"):GetText()
		local bMinimized = self.tMinimized[strKey]
		self.wndTracker:FindChild("MinimizeBtn"):SetCheck(bMinimized)
	
		local nContentHeight = 0
		if not bMinimized then
			self:ResizeCategory(self.wndTrackerActive)
			self:ResizeCategory(self.wndTrackerLoot)
			self:ResizeCategory(self.wndTrackerAvailable)
			self:ResizeCategory(self.wndTrackerRepeat)
			
			nContentHeight = self.wndTracker:FindChild("Content"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		end
		self.wndTracker:FindChild("Content"):Show(not bMinimized)
		
		local nContentHeightChange = nContentHeight - self.wndTracker:FindChild("Content"):GetHeight()
		local nLeft, nTop, nRight, nBottom = self.wndTracker:GetAnchorOffsets()
		self.wndTracker:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nContentHeightChange)
	end
	
	if self.wndTracker:GetHeight() ~= nStartingHeight
		or self.nChallengesShown ~= nChallengesShown
		or self.wndTracker:IsShown() ~= bStartingShown then
		
		local tData =
		{
			["strAddon"] = kstrObjectiveType,
			["strText"] = nChallengesShown,
			["bChecked"] = self.bShowChallenges,
		}
		Event_FireGenericEvent("ObjectiveTracker_UpdateAddOn", tData)
	end
	self.nChallengesShown = nChallengesShown
end

function ChallengeTracker:ResizeCategory(wndContainer)
	local wndContent = wndContainer:FindChild("Content")
	local wndMinimize = wndContainer:FindChild("MinimizeBtn")

	local tData = wndContainer:GetData()
	local strKey = tData.strKey
	
	local nChallengesShown = #wndContainer:FindChild("Content"):GetChildren()
	local strTitle = nChallengesShown ~= 1 and string.format("%s", strKey) or strKey
	local bMinimize = false
	
	if self.tMinimized[strKey] == nil then
		bMinimize = tData.bCanHide and #wndContainer:FindChild("Content"):GetChildren() > knUXHideIfTooMany
	else
		bMinimize = self.tMinimized[strKey]
	end

	local bHidden = false
	if self.tHidden and self.tHidden[strKey] ~= nil then
		bHidden = self.tHidden[strKey]
	end
	
	self.tCategories[strKey] = {strKey = tData.strKey, bCanHide=tData.bCanHide, strTitle = strTitle}
	wndContainer:FindChild("Title"):SetText(strTitle)
	wndMinimize:SetData(strKey)
	wndMinimize:SetCheck(bMinimize)
	wndMinimize:Show(bMinimize or wndMinimize:ContainsMouse())
	wndContainer:Show(nChallengesShown > 0 and not bHidden)
	
	if wndMinimize ~= nil and not wndMinimize:IsChecked() then
		for idx, wndChild in pairs(wndContent:GetChildren()) do
			if wndChild:IsShown() then
				self:ResizeChallenge(wndChild)
			end
		end
	end
	
	local nContentHeight = 0
	if not bMinimize then
		nContentHeight = wndContent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	end
	local nContentHeightChange = nContentHeight - wndContent:GetHeight()
	
	local nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	wndContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nContentHeightChange)
end

function ChallengeTracker:BuildChallenge(clgChallenge)
	local wndParent = nil
	if clgChallenge:IsActivated() then
		wndParent = self.wndTrackerActiveContent
	elseif clgChallenge:GetCompletionCount() > 0 then
		wndParent = self.wndTrackerRepeatContent
	else
		wndParent = self.wndTrackerAvailableContent
	end

	local wndChallenge = self.tChallengeWndCache[clgChallenge:GetId()]
	if wndChallenge ~= nil and wndChallenge:IsValid() and wndChallenge:GetParent() ~= wndParent then
		wndChallenge:Destroy()
	end
	
	if wndChallenge == nil or not wndChallenge:IsValid() then
		wndChallenge = Apollo.LoadForm(self.xmlDoc, "ListItem", wndParent, self)
		self.tChallengeWndCache[clgChallenge:GetId()] = wndChallenge
	end
	
	if clgChallenge:IsActivated() then
		self.tNeedsRealTimeUpdate[clgChallenge:GetId()] = clgChallenge
		self.timerRealTimeUpdate:Start()
	end

	wndChallenge:SetData(clgChallenge)
	wndChallenge:FindChild("ListItemGearBtn"):SetData(clgChallenge)
	
	local wndBtn = wndChallenge:FindChild("ListItemBigBtn")
	wndBtn:SetData(clgChallenge)
	wndBtn:SetText(GameLib.GetKeyBinding("Interact").." >")
	
	
	local strChallengeType = Apollo.GetString(karTypeToFormattedString[clgChallenge:GetType()])
	local strTime = ""
	if clgChallenge:GetTimer() ~= nil and clgChallenge:GetTimer() > 0 then
		strTime = "("..self:HelperConvertToTime(clgChallenge:GetTimer())..") "
	end
	local strTooltip = string.format(
		"<P Font=\"CRB_InterfaceSmall\" TextColor=\"UI_TextHoloTitle\">%s%s</P>"..
		"<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffffffff\">%s</P>",
		strChallengeType, 
		Apollo.GetString("Chat_ColonBreak"), 
		clgChallenge:GetDescription()
	)
	
	
	local strSubTitle = ""
	if wndParent == self.wndTrackerActiveContent then
		strSubTitle = strTooltip
	end
	wndBtn:SetTooltip(strTooltip)
	wndChallenge:FindChild("ListItemName"):SetAML("<P Font=\"CRB_InterfaceMedium_B\" TextColor=\""..kstrLightGrey.."\">"..strTime..clgChallenge:GetName().."</P>")
	wndChallenge:FindChild("ListItemSubtitle"):SetAML(strSubTitle)
	wndChallenge:FindChild("ListItemIcon"):SetSprite(self:CalculateIconPath(clgChallenge:GetType()))
	wndChallenge:FindChild("ListItemHasLoot"):Show(false)

	self:HelperSelectInteractHintArrowObject(clgChallenge, wndBtn)
	
	local wndChallengeSpell = wndChallenge:FindChild("ListItemSpell")
	wndChallengeSpell:Show(clgChallenge:GetType() == ChallengesLib.ChallengeType_Ability)
	if clgChallenge:GetType() == ChallengesLib.ChallengeType_Ability then
		wndChallengeSpell:SetContentId(clgChallenge)
	end
end

function ChallengeTracker:ResizeChallenge(wndChallenge)
	local nNameWidth, nNameHeight = wndChallenge:FindChild("ListItemName"):SetHeightToContentHeight()
	local nTitleWidth, nTitleHeight = wndChallenge:FindChild("ListItemSubtitle"):SetHeightToContentHeight()
	local nLeft, nTop, nRight, nBottom = wndChallenge:GetAnchorOffsets()
	wndChallenge:SetAnchorOffsets(nLeft, nTop, nRight, math.max(nTop, nTop + nNameHeight + nNameHeight/3 + nTitleHeight))
end

function ChallengeTracker:CalculateIconPath(eType)
	if eType == ChallengesLib.ChallengeType_Combat then     -- Combat
		return "CRB_ChallengeTrackerSprites:sprChallengeTypeKillTiny"
	elseif eType == ChallengesLib.ChallengeType_Ability then -- Ability
		return "CRB_ChallengeTrackerSprites:sprChallengeTypeSkillTiny"
	elseif eType == ChallengesLib.ChallengeType_General then -- General
		return "CRB_ChallengeTrackerSprites:sprChallengeTypeGenericTiny"
	elseif eType == ChallengesLib.ChallengeType_Item then -- Items
		return "CRB_ChallengeTrackerSprites:sprChallengeTypeLootTiny"
	end
    
	return "CRB_GuildSprites:sprChallengeTypeGenericTiny"
end

function ChallengeTracker:HelperConvertToTime(nInSeconds, bReturnZero)
	if not bReturnZero and nInSeconds == 0 then
		return ""
	end
	
	local strResult = ""
	local nHours = math.floor(nInSeconds / 3600)
	local nMins = math.floor(nInSeconds / 60 - (nHours * 60))
	local nSecs = string.format("%02.f", math.floor(nInSeconds - (nHours * 3600) - (nMins * 60)))

	if nHours ~= 0 then
		strResult = nHours .. ":" .. nMins .. ":" .. nSecs
	else
		strResult = nMins .. ":" .. nSecs
	end

	return strResult
end

-----------------------------------------------------------------------------------------------
-- Game Events
-----------------------------------------------------------------------------------------------

function ChallengeTracker:OnSubZoneChanged(idZone, strZoneName)
	self:BuildAll()
	self:ResizeAll()
end

function ChallengeTracker:OnChallengeAbandon(idChallenge, strDescription)
	local wndChallenge = self.tChallengeWndCache[idChallenge]
	if wndChallenge ~= nil and wndChallenge:IsValid() then
		local clgChallenge = wndChallenge:GetData()
		self:BuildChallenge(clgChallenge)
		self.timerResizeDelay:Start()
	end
end

function ChallengeTracker:OnChallengeActivate(clgChallenge)
	self:BuildChallenge(clgChallenge)
	self.timerResizeDelay:Start()
end

function ChallengeTracker:ChallengeAreaRestriction(idChallenge, strHeader, strDescription, nTime)
	local wndChallenge = self.tChallengeWndCache[idChallenge]
	if wndChallenge ~= nil and wndChallenge:IsValid() then
		local clgChallenge = wndChallenge:GetData()
		self:BuildChallenge(clgChallenge)
		self.timerResizeDelay:Start()
	end
end

function ChallengeTracker:OnChallengeCompleted(idChallenge, strHeader, strDescription, nDuration)
	local wndChallenge = self.tChallengeWndCache[idChallenge]
	if wndChallenge ~= nil and wndChallenge:IsValid() then
		local clgChallenge = wndChallenge:GetData()
		self:BuildChallenge(clgChallenge)
		self.timerResizeDelay:Start()
	end
end

function ChallengeTracker:OnChallengeCooldownActive(idChallenge, strHeader, strDescription, nDuration)
	local wndChallenge = self.tChallengeWndCache[idChallenge]
	if wndChallenge ~= nil and wndChallenge:IsValid() then
		local clgChallenge = wndChallenge:GetData()
		self:BuildChallenge(clgChallenge)
		self.timerResizeDelay:Start()
	end
end

function ChallengeTracker:OnChallengeFailArea(clgChallenge, strHeader, strDescription, nDuration)
	self:BuildChallenge(clgChallenge)
	self.timerResizeDelay:Start()
end

function ChallengeTracker:OnChallengeFailGeneric(clgChallenge, strHeader, strDescription, nDuration)
	self:BuildChallenge(clgChallenge)
	self.timerResizeDelay:Start()
end

function ChallengeTracker:OnChallengeFailTime(clgChallenge, strHeader, strDescription, nDuration)
	self:BuildChallenge(clgChallenge)
	self.timerResizeDelay:Start()
end

function ChallengeTracker:OnChallengeLeftArea(idChallenge, strHeader, strDescription, nDuration)
	local wndChallenge = self.tChallengeWndCache[idChallenge]
	if wndChallenge ~= nil and wndChallenge:IsValid() then
		local clgChallenge = wndChallenge:GetData()
		self:BuildChallenge(clgChallenge)
		self.timerResizeDelay:Start()
	end
end

function ChallengeTracker:OnChallengeRewardListReady(idChallenge, nTier)
	local wndChallenge = self.tChallengeWndCache[idChallenge]
	if wndChallenge ~= nil and wndChallenge:IsValid() then
		local clgChallenge = wndChallenge:GetData()
		self:BuildChallenge(clgChallenge)
		self.timerResizeDelay:Start()
	end
end

function ChallengeTracker:OnChallengeTierAchieved(idChallenge, nTier)
	local wndChallenge = self.tChallengeWndCache[idChallenge]
	if wndChallenge ~= nil and wndChallenge:IsValid() then
		local clgChallenge = wndChallenge:GetData()
		self:BuildChallenge(clgChallenge)
		self.timerResizeDelay:Start()
	end
end

function ChallengeTracker:OnChallengeTimeUpdated(idChallenge)
	local wndChallenge = self.tChallengeWndCache[idChallenge]
	if wndChallenge ~= nil and wndChallenge:IsValid() then
		local clgChallenge = wndChallenge:GetData()
		self:BuildChallenge(clgChallenge)
		self.timerResizeDelay:Start()
	end
end

function ChallengeTracker:OnChallengeUpdated(idChallenge)
	local wndChallenge = self.tChallengeWndCache[idChallenge]
	if wndChallenge ~= nil and wndChallenge:IsValid() then
		local clgChallenge = wndChallenge:GetData()
		self:BuildChallenge(clgChallenge)
		self.timerResizeDelay:Start()
	end
end


-----------------------------------------------------------------------------------------------
-- Control Events
-----------------------------------------------------------------------------------------------

function ChallengeTracker:HelperSelectInteractHintArrowObject(oCur, wndBtn)
	local oInteractObject = GameLib.GetInteractHintArrowObject()
	if not oInteractObject or oInteractObject and (oInteractObject.eHintArrowType == GameLib.CodeEnumHintType.None) then
		return
	end

	local bIsInteractHintArrowObject = oInteractObject.objTarget and oInteractObject.objTarget == oCur
	if bIsInteractHintArrowObject and not wndBtn:IsChecked() then
		wndBtn:SetCheck(true)
	end
end

function ChallengeTracker:LootChallenge(clgChallenge)
	local nChallengeId = clgChallenge:GetId()
	
	if self.tLootChallenges[nChallengeId] then
		self.tLootChallenges[nChallengeId] = nil
	end
end

function ChallengeTracker:OnGearBtn(wndHandler, wndControl, eMouseButton)
	if not wndHandler or not wndHandler:GetData() then
		return
	end
	
	self:DrawContextMenu(wndHandler:GetData())
end

function ChallengeTracker:OnListItemMouseEnter(wndHandler, wndControl)
	local bHasMouse = wndHandler:ContainsMouse()
	wndHandler:GetParent():FindChild("ListItemGearBtn"):Show(bHasMouse)
	
	if bHasMouse then
		Apollo.RemoveEventHandler("ObjectiveTrackerUpdated", self)
	end
end

function ChallengeTracker:OnListItemMouseExit(wndHandler, wndControl)
	local bHasMouse = wndHandler:ContainsMouse()
	wndHandler:GetParent():FindChild("ListItemGearBtn"):Show(bHasMouse)
	
	if not bHasMouse then
		Apollo.RegisterEventHandler("ObjectiveTrackerUpdated",	"TrackChallenges", self)
	end
end

function ChallengeTracker:OnControlBackerMouseEnter(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:FindChild("MinimizeBtn"):Show(true)
	end
end

function ChallengeTracker:OnControlBackerMouseExit(wndHandler, wndControl)
	if wndHandler == wndControl then
		local wndBtn = wndHandler:FindChild("MinimizeBtn")
		wndBtn:Show(wndBtn:IsChecked())
	end
end

function ChallengeTracker:OnMinimizedBtnChecked(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		self:DrawContextMenuOptions()
		
		--This is a hack. Right clicking on a checkbox control still toggles the checked state, which I don't want here.
		wndHandler:SetCheck(not wndHandler:IsChecked())
	else
		self.tMinimized[wndHandler:GetData()] = wndHandler:IsChecked()
	
		self:ResizeAll()
	end
end

function ChallengeTracker:OnListItemHintArrow(wndHandler, wndControl, eMouseButton)
	if not wndHandler or not wndHandler:GetData() then
		return
	end

	local clgCurrent = wndHandler:GetData()
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		self:DrawContextMenu(clgCurrent)
	else
		ChallengesLib.ShowHintArrow(clgCurrent:GetId())
		GameLib.SetInteractHintArrowObject(clgCurrent) 
	end
end

function ChallengeTracker:OnGenerateSpellTooltip( wndHandler, wndControl, eType, splSource )
	if eType == Tooltip.TooltipGenerateType_Spell then
		Tooltip.GetSpellTooltipForm(self, wndControl, splSource)
	end
end


-----------------------------------------------------------------------------------------------
-- Right Click
-----------------------------------------------------------------------------------------------
function ChallengeTracker:CloseContextMenu() -- From a variety of source
	if self.wndContextMenu and self.wndContextMenu:IsValid() then
		self.wndContextMenu:Destroy()
		self.wndContextMenu = nil
		
		return true
	end
	
	return false
end

function ChallengeTracker:DrawContextMenu(clgCurrent)
	if self:CloseContextMenu() then return end

	self.wndContextMenu = Apollo.LoadForm(self.xmlDoc, "ContextMenu", nil, self)
	self.wndContextMenu:FindChild("RightClickOpenLogBtn"):SetData(clgCurrent)
	self.wndContextMenu:FindChild("RightClickRestartBtn"):SetData(clgCurrent)
	self.wndContextMenu:FindChild("RightClickRestartBtn"):SetText(clgCurrent:IsActivated() and Apollo.GetString("QuestLog_AbandonBtn") or Apollo.GetString("Options_RestartConfirm"))
	self.wndContextMenu:FindChild("RightClickLootRewardstBtn"):SetData(clgCurrent)
	self.wndContextMenu:FindChild("RightClickLootRewardstBtn"):Enable(false)
	self.wndContextMenu:FindChild("RightClickHideBtn"):SetData(clgCurrent)
	self.wndContextMenu:FindChild("RightClickHideBtn"):Enable(false)
	
	local tCursor = Apollo.GetMouse()
	local nWidth = self.wndContextMenu:GetWidth()
	self.wndContextMenu:Move(tCursor.x - nWidth + knXCursorOffset, tCursor.y - knYCursorOffset, nWidth, self.wndContextMenu:GetHeight())
end

function ChallengeTracker:HelperDrawContextMenuSubOptions(wndIgnore)
	if self.wndContextMenuOptions and self.wndContextMenuOptions:IsValid() then
		self.wndContextMenuOptionsContent = self.wndContextMenuOptions:FindChild("DynamicContent")
		self.wndContextMenuOptionsContent:DestroyChildren()
		
		local wndToggleOnChallenges = self.wndContextMenuOptions:FindChild("ToggleOnChallenges")
		local wndToggleFilterLimit = self.wndContextMenuOptions:FindChild("ToggleFilterLimit")
		local wndMissionLimitEditBox = self.wndContextMenuOptions:FindChild("MissionLimitEditBox")
		local wndToggleFilterDistance = self.wndContextMenuOptions:FindChild("ToggleFilterDistance")
		local wndMissionDistanceEditBox = self.wndContextMenuOptions:FindChild("MissionDistanceEditBox")
	
		wndToggleOnChallenges:SetCheck(self.bShowChallenges)		
		wndToggleFilterLimit:SetCheck(self.bFilterLimit)
		wndToggleFilterDistance:SetCheck(self.bFilterDistance)
		
		if not wndIgnore or wndIgnore and wndIgnore ~= wndMissionLimitEditBox then
			wndMissionLimitEditBox:SetText(self.bFilterLimit and self.nMaxMissionLimit or 0)
		end
		
		if not wndIgnore or wndIgnore and wndIgnore ~= wndMissionDistanceEditBox then
			wndMissionDistanceEditBox:SetText(self.bFilterDistance and self.nMaxMissionDistance or 0)
		end
			
		local nHeight = self.wndContextMenuOptions:GetHeight()
		for strKey, tData in pairs(self.tCategories) do
			if tData.bCanHide then
				local wndEntry = Apollo.LoadForm(self.xmlDoc, "ContextMenuButtonLarge", self.wndContextMenuOptionsContent, self)
				local wndBtn = wndEntry:FindChild("RightClickBtn")
				
				wndBtn:SetData(strKey)
				wndBtn:SetCheck(self.bShowChallenges and not self.tHidden[strKey])
				wndBtn:Enable(self.bShowChallenges)
				wndBtn:SetText(tData.strTitle)
				
				nHeight = nHeight + wndBtn:GetHeight()
			end
		end
		
		self.wndContextMenuOptionsContent:ArrangeChildrenVert()
		
		return nHeight
	end
	
	return 0
end

function ChallengeTracker:CloseContextMenuOptions() -- From a variety of source
	if self.wndContextMenuOptions and self.wndContextMenuOptions:IsValid() then
		self.wndContextMenuOptions:Destroy()
		self.wndContextMenuOptions = nil
		
		return true
	end
	
	return false
end

function ChallengeTracker:DrawContextMenuOptions()
	local nXCursorOffset = -36
	local nYCursorOffset = 5
	
	if self:CloseContextMenuOptions() then return end

	self.wndContextMenuOptions = Apollo.LoadForm(self.xmlDoc, "ContextMenuOptions", nil, self)
	
	local nWidth = self.wndContextMenuOptions:GetWidth()
	local nHeight = self:HelperDrawContextMenuSubOptions()
		
	local tCursor = Apollo.GetMouse()
	self.wndContextMenuOptions:Move(
		tCursor.x - nWidth - nXCursorOffset,
		tCursor.y - nHeight - nYCursorOffset,
		nWidth,
		nHeight
	)
end

function ChallengeTracker:OnToggleChallengeOptions()
	self:DrawContextMenuOptions()
end

function ChallengeTracker:OnToggleShowChallenges()
	self.bShowChallenges = not self.bShowChallenges
	
	self:HelperDrawContextMenuSubOptions()
	self:ResizeAll()
end

function ChallengeTracker:OnToggleFilterLimit()
	self.bFilterLimit = not self.bFilterLimit
	
	self:HelperDrawContextMenuSubOptions()
	self:ResizeAll()
end

function ChallengeTracker:OnToggleFilterDistance()
	self.bFilterDistance = not self.bFilterDistance
	
	self:HelperDrawContextMenuSubOptions()
	self:ResizeAll()
end

function ChallengeTracker:OnMissionLimitEditBoxChanged(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	
	self.nMaxMissionLimit = tonumber(wndControl:GetText()) or 0
	self.bFilterLimit = self.nMaxMissionLimit > 0
	
	self:HelperDrawContextMenuSubOptions(wndControl)
	self:ResizeAll()
end

function ChallengeTracker:OnMissionDistanceEditBoxChanged(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	
	self.nMaxMissionDistance = tonumber(wndControl:GetText()) or 0
	self.bFilterDistance = self.nMaxMissionDistance > 0
	
	self:HelperDrawContextMenuSubOptions(wndControl)
	self:ResizeAll()
end

function ChallengeTracker:OnRightClickOptionBtn(wndHandler, wndControl)
	strKey = wndHandler and wndHandler:IsValid() and wndHandler:GetData()
	
	if not strKey then
		return
	end
	
	self.tHidden[strKey] = not self.tHidden[strKey]
	self:ResizeAll()
end

function ChallengeTracker:OnRightClickBtn(wndHandler, wndControl)
	strKey = wndHandler and wndHandler:IsValid() and wndHandler:GetData()
	
	if not strKey then
		return
	end
	
	self.tHidden[strKey] = not self.tHidden[strKey]
	self:ResizeAll()
	self:CloseContextMenu(self.wndContextMenuOptions)
end

function ChallengeTracker:OnRightClickOpenLogBtn(wndHandler, wndControl, eMouseButton) -- wndHandler is "RightClickOpenLogBtn" and its data is tQuest
	Event_FireGenericEvent("ShowQuestLog", wndHandler:GetData()) -- Codex (todo: deprecate this)
	Event_FireGenericEvent("ChallengesShow_NoHide", wndHandler:GetData()) -- ChallengeLog
	
	self:CloseContextMenu()
end

function ChallengeTracker:OnRightClickLootRewardsBtn(wndHandler, wndControl)
	clgCurrent = wndHandler:GetData()
	self:LootChallenge(clgCurrent)
	
	self:CloseContextMenu()
end

function ChallengeTracker:OnRightClickRestartBtn(wndHandler, wndControl)
	clgCurrent = wndHandler:GetData()
	
	if clgCurrent:IsActivated() then
		ChallengesLib.AbandonChallenge(clgCurrent:GetId())
	else
		ChallengesLib.ShowHintArrow(clgCurrent:GetId())
		ChallengesLib.ActivateChallenge(clgCurrent:GetId())
	end
	
	self:CloseContextMenu()
end

local ChallengeTrackerInst = ChallengeTracker:new()
ChallengeTrackerInst:Init()
