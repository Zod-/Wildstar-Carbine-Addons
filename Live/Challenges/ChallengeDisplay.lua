-----------------------------------------------------------------------------------------------
-- Client Lua Script for ChallengeDisplay
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "ChallengesLib"
require "Challenges"
require "PlayerPathLib"

local knChallengeViewTime = 15

local karTierIdxToWindowName =
{
	[0] = "",
	[1] = "Bronze",
	[2] = "Silver",
	[3] = "Gold",
}

local karTierIdxToString =
{
	[0] = "",
	[1] = Apollo.GetString("ChallengeTier1"),
	[2] = Apollo.GetString("ChallengeTier2"),
	[3] = Apollo.GetString("ChallengeTier3"),
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

local ChallengeDisplay = {}
function ChallengeDisplay:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	
	-- Window Management
	o.tChallengeWndCache = {}

    return o
end

function ChallengeDisplay:Init()
    Apollo.RegisterAddon(self)
end

function ChallengeDisplay:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ChallengeTracker.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	self.timerRealTimeUpdate = ApolloTimer.Create(1.0, true, "OnRealTimeUpdateTimer", self)
	self.timerRealTimeUpdate:Stop()
end

function ChallengeDisplay:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("ChallengeUpdated",				"OnChallengeUpdated", self)
	Apollo.RegisterEventHandler("ChallengeLeftArea",			"OnChallengeLeftArea", self)
	Apollo.RegisterEventHandler("ChallengeActivate",			"OnChallengeActivate", self)
	Apollo.RegisterEventHandler("ChallengeFailArea", 			"OnChallengeFail", self)
    Apollo.RegisterEventHandler("ChallengeFailTime", 			"OnChallengeFail", self)
	Apollo.RegisterEventHandler("ChallengeTierAchieved",		"OnChallengeTierAchieved", self)
	Apollo.RegisterEventHandler("ChallengeAbandon",				"OnChallengeAbandon", self)
	Apollo.RegisterEventHandler("ChallengeCompleted",			"OnChallengeCompleted", self)
	Apollo.RegisterEventHandler("SoldierHoldoutStatus",			"OnSoldierHoldoutStatus", self)
	
	Apollo.RegisterEventHandler("ChallengeAbandon",				"OnChallengeAbandonSound", self)
	Apollo.RegisterEventHandler("ChallengeActivate",			"OnChallengeActivateSound", self)
	Apollo.RegisterEventHandler("ChallengeFailSound",			"OnChallengeFailSound", self)
	Apollo.RegisterEventHandler("ChallengeCompletedSound",		"OnChallengeCompletedSound", self)
	Apollo.RegisterEventHandler("ChallengeTierAchieved",		"OnChallengeTierAchievedSound", self)
	
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 	"OnTutorial_RequestUIAnchor", self)
	
	self:BuildActiveListItems()
end

function ChallengeDisplay:OnRealTimeUpdateTimer(nTime)
	self:BuildActiveListItems()
end

function ChallengeDisplay:BuildActiveListItems()
	local arActiveChallenges = {}
	local tChallenges = ChallengesLib.GetActiveChallengeList()
	for idx, clgCurrent in pairs(tChallenges) do
		if clgCurrent:GetTimer() and clgCurrent:IsActivated() then
			table.insert(arActiveChallenges, clgCurrent)
		end
	end

	local bShowSuccededFailedChallenges = false
	if self.tCompletedChallenges or self.tFailedChallenges then
		bShowSuccededFailedChallenges = true
	end

	if #arActiveChallenges > 0 or bShowSuccededFailedChallenges then
		if self.wndActiveChallenges == nil or not self.wndActiveChallenges:IsValid() then
			self.wndActiveChallenges = Apollo.LoadForm(self.xmlDoc, "ActiveChallenges", "FixedHudStratumLow", self)
		end
		
		for idx, clgCurrent in pairs(arActiveChallenges) do
			self:UpdateActiveListItem(clgCurrent)
		end
		
		self.wndActiveChallenges:FindChild("Content"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
		
		local bShowActiveChallenges = true
		local pepEpisode = PlayerPathLib.GetCurrentEpisode()
		if pepEpisode then
			local tFullMissionList = pepEpisode:GetMissions()
			for idx, pmCurrMission in pairs(tFullMissionList) do
				if pmCurrMission:GetMissionState() == PathMission.PathMissionState_Started then
					local seHoldout = pmCurrMission:GetSoldierHoldout()
					if seHoldout then
						bShowActiveChallenges = false
						break
					end
				end
			end
		end
		
		self.wndActiveChallenges:Show(bShowActiveChallenges)
	elseif not bShowSuccededFailedChallenges then
		if self.wndActiveChallenges ~= nil and self.wndActiveChallenges:IsValid() then
			self.wndActiveChallenges:Destroy()
		end
		self.wndActiveChallenges = nil
		self.timerRealTimeUpdate:Stop()
	end
end

function ChallengeDisplay:UpdateActiveListItem(clgCurrent)
	local wndListItem = self.tChallengeWndCache[clgCurrent:GetId()]
	if not wndListItem or not wndListItem:IsValid() then
		wndListItem = Apollo.LoadForm(self.xmlDoc, "ActiveChallenge", self.wndActiveChallenges:FindChild("Content"), self)
		self.tChallengeWndCache[clgCurrent:GetId()] = wndListItem
		wndListItem:SetData(clgCurrent:GetId())
		wndListItem:FindChild("Description"):SetData(clgCurrent)
		wndListItem:FindChild("CloseBtn"):SetData(clgCurrent:GetId())
		
		self.timerRealTimeUpdate:Start()
	end
	
	local nTotal = clgCurrent:GetTotalCount()
	local nCurrent = clgCurrent:GetCurrentCount()
	local nCurrentTier = clgCurrent:GetCurrentTier() + 1
	local nTimeLimit = clgCurrent:GetDuration()
	local nCurrentTime = clgCurrent:GetTimer()
	local nTimeElappsed = math.abs(nCurrentTime - nTimeLimit)
	local nTimeLeftArea = ChallengesLib.GetTimeRemaining(clgCurrent:GetId(), ChallengesLib.ChallengeTimerFlags_LeftArea)
	
	if nTimeLeftArea > 0 and nTimeLeftArea < nCurrentTime then
		local strLeftArea = string.format("%s %s", Apollo.GetString("ChallengeLeftArea"), self:HelperConvertToTime(nTimeLeftArea)) or ""
		self.wndActiveChallenges:FindChild("TextBoundsAlert"):SetText(strLeftArea)
		self.wndActiveChallenges:FindChild("OutOfBoundsAlert"):Show(true)
	else
		self.wndActiveChallenges:FindChild("OutOfBoundsAlert"):Show(false)
	end
	
	local strDesc = clgCurrent:GetDescription()
	wndListItem:FindChild("Timer"):SetText(self:HelperConvertToTime(nCurrentTime))
	wndListItem:FindChild("Description"):SetText(strDesc)
	
	local wndTimeRemaining = wndListItem:FindChild("TimeRemaining")
	wndTimeRemaining:SetMax(nTimeLimit)
	
	if math.abs(nCurrentTime - wndTimeRemaining:GetProgress()) > 100 then
		wndTimeRemaining:SetProgress(nCurrentTime)
	else
		wndTimeRemaining:SetProgress(nCurrentTime, 1.5)
	end
	
	local bTieredChallenge = clgCurrent:GetAllTierCounts() and #clgCurrent:GetAllTierCounts() > 1
	local tTimerDeltas = {}
	for iTierIdx = #clgCurrent:GetAllTierCounts(), 0, -1 do
		local nCurrTier = clgCurrent:GetAllTierCounts()[iTierIdx+1] and clgCurrent:GetAllTierCounts()[iTierIdx+1]["nGoalCount"] or 0
		
		tTimerDeltas[iTierIdx] = nCurrTier
	end
	
	for iTierIdx, tCurrTier in pairs(clgCurrent:GetAllTierCounts()) do
		local bShowTimedTier = bTieredChallenge
		local wndCurrTier = wndListItem:FindChild(karTierIdxToWindowName[iTierIdx] or "")
		if not wndCurrTier then
			break
		end

		local nTierLimit = tCurrTier["nGoalCount"]
		local wndLimit = wndCurrTier:FindChild("Limit")
		local strText = ""
		if clgCurrent:IsTimeTiered() then
			local nTierTimeRemaining = math.max(0, nTimeLimit-nTierLimit-nTimeElappsed)
			bShowTimedTier = nTierTimeRemaining > 1
			strText = self:HelperConvertToTime(nTierTimeRemaining, true)
			
			nCurrentTier = nTimeElappsed < nTimeLimit - nTierLimit and iTierIdx or nCurrentTier
			if iTierIdx == nCurrentTier then
				nTotal = math.abs(nTimeLimit - tTimerDeltas[iTierIdx]  - nTierLimit)
				nCurrent = math.abs(nTimeLimit - nTierLimit - nTimeElappsed)
			end
		elseif iTierIdx == (nCurrentTier) then -- Active tier
			strText = nTierLimit == 100 and String_GetWeaselString(Apollo.GetString("CRB_Percent"), nTierLimit) or nTierLimit
		else -- Implict not active
			strText = nTierLimit == 100 and "" or nTierLimit
		end
		
		wndLimit:SetText(strText)
		wndCurrTier:Show(bShowTimedTier and bTieredChallenge and #clgCurrent:GetAllTierCounts() >= iTierIdx)
	end

	wndListItem:FindChild("CurrentMedal"):SetSprite(bTieredChallenge and karTierIdxToMedalSprite[nCurrentTier] or "")
	
	local wndCurrentStatus = wndListItem:FindChild("CurrentStatus")
	if nCurrent == 0 and nTotal == 1 then
		wndCurrentStatus:SetText("")
	elseif nCurrent == 0 and nTotal == 0 then
		wndCurrentStatus:SetText("")
	elseif nTotal == 100 then
		wndCurrentStatus:SetText(String_GetWeaselString(Apollo.GetString("CRB_Percent"), math.floor(nCurrent / nTotal * 100)))
	elseif clgCurrent:IsTimeTiered() then
		wndCurrentStatus:SetText(self:HelperConvertToTime(nCurrent))
	else
		wndCurrentStatus:SetText(string.format("%s / %s", nCurrent, nTotal))
	end
	
	wndCurrentStatus:SetTextColor(ApolloColor.new(karTierIdxToTextColor[nCurrentTier]))
	
	local wndMedalStanding = wndListItem:FindChild("MedalStanding")
	wndMedalStanding:SetEmptySprite(karTierIdxToStarSprite[nCurrentTier-1])
	wndMedalStanding:SetFillSprite(karTierIdxToStarSprite[nCurrentTier])
	wndMedalStanding:SetMax(nTotal)
	wndMedalStanding:SetProgress(nCurrent)
end

function ChallengeDisplay:HelperConvertToTime(nInSeconds, bReturnZero)
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

---------------------------------------------------------------------------------------------------
-- Game Events
---------------------------------------------------------------------------------------------------

function ChallengeDisplay:HelperAreChallengesActive()
	for idx, clgCurrent in pairs(ChallengesLib.GetActiveChallengeList()) do
		if clgCurrent:GetTimer() and clgCurrent:IsActivated() then
			return true
		end
	end
	return false
end

function ChallengeDisplay:HelperGetChallengeFromId(idChallenge)
	if not self.tChallengeWndCache then
		return
	end

	local wndListItem = self.tChallengeWndCache[idChallenge]
	if wndListItem ~= nil and wndListItem:IsValid() then
		return wndListItem:FindChild("Description"):GetData()
	end
end

function ChallengeDisplay:OnChallengeActivate(clgChallenge)
	Event_ShowTutorial(GameLib.CodeEnumTutorial.ChallengeUnlocked)

	if self.wndActiveChallenges then
		--self.wndActiveChallenges:FindChild("Success"):Show(false)
		if self.timerSuccess then
			self.timerSuccess:Stop()
		end

		if not self.tCompletedChallenges then
			self:HelperSetChallengeViewTimer()
		end
	end
	self:BuildActiveListItems()
end

function ChallengeDisplay:OnChallengeUpdated(idChallenge)
	local clgCurrent = self:HelperGetChallengeFromId(idChallenge)
	if clgCurrent then
		if not self.tCompletedChallenges or not self.tCompletedChallenges[idChallenge] then
			if self.nClosedChallenge == idChallenge then--Closed, so destroy list item.
				local wndListItem = self.tChallengeWndCache[idChallenge]
				if wndListItem ~= nil and wndListItem:IsValid() then
					wndListItem:Destroy()
					self.tChallengeWndCache[idChallenge] = nil
					self:BuildActiveListItems()
				end
				self.nClosedChallenge = nil

			elseif not clgCurrent:IsActivated() then--This challenge ended but wasn't Completed and has some tier.
				if clgCurrent:GetCurrentTier() > 0 then
					self:OnChallengeCompleted(idChallenge, nil, nil, nil)
				else
					self:OnChallengeFail(clgCurrent, nil, nil)
				end
			else
				self:UpdateActiveListItem(clgCurrent)
			end
			self:UpdateChallengeViewTimer(idChallenge)
		end
	end
end

function ChallengeDisplay:OnChallengeTierAchieved(idChallenge, nTier)
	local clgCurrent = self:HelperGetChallengeFromId(idChallenge)
	if clgCurrent then
		self:UpdateActiveListItem(clgCurrent)
	end
end

function ChallengeDisplay:OnChallengeLeftArea(idChallenge)
	self:BuildActiveListItems()
end

function ChallengeDisplay:OnChallengeAbandon(idChallenge, strDescription)
	self:BuildActiveListItems()
end

function ChallengeDisplay:OnChallengeCompleted(idChallenge, strHeader, strDescription, nDuration)
	if not self.tCompletedChallenges then
		self.tCompletedChallenges = {}
	end

	self.tCompletedChallenges[idChallenge] = true
	self:UpdateChallengeViewTimer(idChallenge)
	if self.wndActiveChallenges ~= nil and self.wndActiveChallenges:IsValid() then
		self.wndActiveChallenges:FindChild("Flash"):SetSprite("Warplots:spr_WarPlots_BaseGreenPulse")
		self.wndActiveChallenges:FindChild("Flash2"):SetSprite("LoginIncentives:sprLoginIncentives_Burst")
	end
	Sound.Play(Sound.PlayUIContractProgressComplete)
end

function ChallengeDisplay:OnChallengeFail(clgFailed, strHeader, strDesc)
	if not self.tFailedChallenges then
		self.tFailedChallenges = {}
	end

	local nChallengeId = clgFailed:GetId()
	self.tFailedChallenges[nChallengeId] = true
	self:UpdateChallengeViewTimer(nChallengeId)
end

function ChallengeDisplay:UpdateChallengeViewTimer(idChallenge)
	self:HelperSetChallengeViewTimer()
	local clgCurrent = self:HelperGetChallengeFromId(idChallenge)
	self:SetChallengeView(clgCurrent)
end

function ChallengeDisplay:HelperSetChallengeViewTimer()
	if not self:HelperAreChallengesActive() then
		if not self.timerSuccess then
			self.timerSuccess = ApolloTimer.Create(knChallengeViewTime, false, "OnCloseChallengeView", self)
		else
			self.timerSuccess:Set(knChallengeViewTime, false)
		end
	end
end

function ChallengeDisplay:OnCloseChallengeView()
	self.tCompletedChallenges = nil
	self.tFailedChallenges = nil
	if self.timerSuccess then
		self.timerSuccess:Stop()
		self.timerSuccess = nil
	end
	self:BuildActiveListItems()
end

function ChallengeDisplay:SetChallengeView(clgCurrent)
	if not clgCurrent then
		return
	end

	local wndSuccess = self.wndActiveChallenges:FindChild("Success")
	local wndFail = self.wndActiveChallenges:FindChild("Fail")

	local nChallengeId = clgCurrent:GetId()
	if self.tCompletedChallenges and self.tCompletedChallenges[nChallengeId] then--This was a completed challenge
		local wndTitle = wndSuccess:FindChild("Title")
		local nCurrentTier = clgCurrent:GetCurrentTier()
		wndTitle:SetTextColor(karTierIdxToTextColor[nCurrentTier])
		wndTitle:SetText(String_GetWeaselString(Apollo.GetString("Challenges_CompletedTitle"),karTierIdxToString[nCurrentTier], clgCurrent:GetName()))

		local nReward = 0
		local wndOpenChallengesBtn = wndSuccess:FindChild("OpenChallengesBtn")
		local tRewardTrackInfo = ChallengesLib.GetRewardTrackInfo()
		if nCurrentTier > 0 and tRewardTrackInfo and tRewardTrackInfo.tFinal then
			local tRewardMap = 
			{
				[1] = tRewardTrackInfo.tFinal.nBronze,
				[2] = tRewardTrackInfo.tFinal.nSilver,
				[3] = tRewardTrackInfo.tFinal.nGold,
			}
			nReward = tRewardMap[nCurrentTier]
		end
		wndOpenChallengesBtn:SetText(String_GetWeaselString(Apollo.GetString("Challenges_Points"), nReward))
		wndOpenChallengesBtn:SetData(clgCurrent)
		self:HelperStripActiveListItem(clgCurrent, true)
		wndSuccess:Show(true)
		wndFail:Show(false)
	elseif self.tFailedChallenges and self.tFailedChallenges[nChallengeId] then--This was a failed challenge
		wndFail:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("ChallengeFailedHeader"), clgCurrent:GetName()))

		local wndRetryChallengeBtn = wndFail:FindChild("RetryChallengeBtn")
		wndRetryChallengeBtn:SetData(clgCurrent)
		self:HelperStripActiveListItem(clgCurrent, false)
		wndSuccess:Show(false)
		wndFail:Show(true)
	end

end

function ChallengeDisplay:HelperStripActiveListItem(clgCurrent, bSuccess)
	local wndListItem = self.tChallengeWndCache[clgCurrent:GetId()]
	if wndListItem ~= nil and wndListItem:IsValid() then
		for idx, wndChild in pairs(wndListItem:GetChildren()) do
			wndChild:Show(false)
		end

		local strStarSprite = "Challenges:sprChallenges_starRed"
		if bSuccess then
			strStarSprite = karTierIdxToStarSprite[clgCurrent:GetCurrentTier()]
		end
		local wndMedalStanding = wndListItem:FindChild("MedalStanding")
		wndMedalStanding:SetEmptySprite(strStarSprite)
		wndMedalStanding:Show(true)

		local strText = Apollo.GetString("CRB_Failed")
		local strColor = "Reddish"
		if bSuccess then
			strColor = "AddonOk"
			strText = Apollo.GetString("QuestCompleted")
		end

		local wndStatus = wndListItem:FindChild("Status")
		wndStatus:SetText(strText)
		wndStatus:SetTextColor(strColor)
		wndStatus:Show(true)
	end
end

function ChallengeDisplay:OnSoldierHoldoutStatus()
	self:BuildActiveListItems()
end

---------------------------------------------------------------------------------------------------
-- Control Events
---------------------------------------------------------------------------------------------------
function ChallengeDisplay:OnOpenChallengesBtn(wndHandler, wndControl)
	local clgOpen = wndHandler:GetData()
	if clgOpen then
		Event_FireGenericEvent("ToggleChallengesWindow", clgOpen)

		local nChallengeId = clgOpen:GetId()
		local wndListItem = self.tChallengeWndCache[nChallengeId]
		if wndListItem ~= nil and wndListItem:IsValid() then
			wndListItem:Destroy()
			self.tChallengeWndCache[nChallengeId] = nil
		end

		if self.tCompletedChallenges then
			local bHaveCompletedChallenges = false
			self.tCompletedChallenges[nChallengeId] = nil
			for idx, bValue in pairs(self.tCompletedChallenges) do
				bHaveCompletedChallenges = true
				break
			end

			if not bHaveCompletedChallenges then
				self.tCompletedChallenges = nil
			end
		end
	end

	if self:HelperAreChallengesActive() then
		self:BuildActiveListItems()
	else
		self:OnCloseChallengeView()
	end
end

function ChallengeDisplay:OnRetyChallengeBtn(wndHandler, wndControl)
	local clgRetry = wndHandler:GetData()

	if clgRetry then
		local nChallengeId = clgRetry:GetId()
		local wndListItem = self.tChallengeWndCache[nChallengeId]
		if wndListItem ~= nil and wndListItem:IsValid() then
			wndListItem:Destroy()
			self.tChallengeWndCache[nChallengeId] = nil
		end

		self.tFailedChallenges[nChallengeId] = nil
		local bHaveFailedChallenges = false
		for idx, bValue in pairs(self.tFailedChallenges) do
			bHaveFailedChallenges = true
			break
		end

		if not bHaveFailedChallenges then
			self.tFailedChallenges = nil
		end

		ChallengesLib.ShowHintArrow(clgRetry:GetId())
		ChallengesLib.ActivateChallenge(clgRetry:GetId())
		self.wndActiveChallenges:FindChild("Fail"):Show(false)
		self:BuildActiveListItems()
	end
end

function ChallengeDisplay:OnActiveChallengeMouseEnter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local clgSelected = wndHandler:FindChild("Description"):GetData()
	if clgSelected:IsActivated() then
		 self.wndActiveChallenges:FindChild("Success"):Show(false)
	else
		self:SetChallengeView(clgSelected)
	end
end
	
function ChallengeDisplay:OnCloseBtnClick(wndHandler, wndControl)
	if not wndHandler or not wndHandler:IsValid() then
		return
	end
	
	local nChallengeId = wndHandler:GetData()
	if nChallengeId then
		ChallengesLib.AbandonChallenge(nChallengeId)
		self:UpdateChallengeViewTimer(nChallengeId)
		self.nClosedChallenge = nChallengeId
	end
end

function ChallengeDisplay:OnChallengeMouseEnter(wndHandler, wndControl)
	if not wndHandler or not wndHandler:IsValid() then
		return
	end
	
	wndHandler:FindChild("CloseBtn"):Show(wndHandler:ContainsMouse())
end

function ChallengeDisplay:OnChallengeMouseExit(wndHandler, wndControl)
	if not wndHandler or not wndHandler:IsValid() then
		return
	end
	
	wndHandler:FindChild("CloseBtn"):Show(wndHandler:ContainsMouse())
end

---------------------------------------------------------------------------------------------------
-- Sound FX
---------------------------------------------------------------------------------------------------

function ChallengeDisplay:OnChallengeActivateSound()
	Sound.Play(Sound.PlayUIChallengeStarted)
end

function ChallengeDisplay:OnChallengeAbandonSound(idChallenge, strDescription)
	Sound.Play(Sound.PlayChallengeQuestCancelled)
end

function ChallengeDisplay:OnChallengeFailSound(idChallenge)
	Sound.Play(Sound.PlayUIChallengeFailed)
end

function ChallengeDisplay:OnChallengeCompletedSound(idChallenge)
	Sound.Play(Sound.PlayUIChallengeComplete)
end

function ChallengeDisplay:OnChallengeTierAchievedSound(idChallenge, nTier)
	if nTier == 1 then
		Sound.Play(Sound.PlayUIChallengeBronze)
	elseif nTier == 2 then
		Sound.Play(Sound.PlayUIChallengeSilver)
	elseif nTier == 3 then
		Sound.Play(Sound.PlayUIChallengeGold)
	end
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------
function ChallengeDisplay:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors = 
	{
		[GameLib.CodeEnumTutorialAnchor.Challenge] = true,
	}
	
	if tAnchors[eAnchor] == nil or self.wndActiveChallenges == nil or not self.wndActiveChallenges:IsValid() then
		return
	end
	
	local tAnchorMapping = 
	{
		[GameLib.CodeEnumTutorialAnchor.Challenge] = self.wndActiveChallenges,
	}
	
	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

local ChallengeDisplayInst = ChallengeDisplay:new()
ChallengeDisplayInst:Init()

