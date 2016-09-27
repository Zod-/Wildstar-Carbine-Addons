-----------------------------------------------------------------------------------------------
-- Client Lua Script for Protogames
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Apollo"
require "Sound"
require "GameLib"
require "PublicEvent"

local DungeonMedals = {}

local kstrNoMedal		= "Protogames:spr_Protogames_Icon_MedalFailed"
local kstrBronzeMedal	= "Protogames:spr_Protogames_Icon_MedalBronze"
local kstrSilverMedal	= "Protogames:spr_Protogames_Icon_MedalSilver"
local kstrGoldMedal		= "Protogames:spr_Protogames_Icon_MedalGold"

function DungeonMedals:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function DungeonMedals:Init()
	Apollo.RegisterAddon(self)
end

function DungeonMedals:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("DungeonMedals.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	self:InitializeVars()
end

function DungeonMedals:InitializeVars()
	self.nTimeElapsed = 0
	self.nPointDelta = 0
	self.nPoints	= 0
	self.nBronze = 0
	self.nSilver = 0
	self.nGold = 0
	self.peMatch = nil
end

function DungeonMedals:OnDocumentReady()
	if not self.xmlDoc then
		return
	end
	
	Apollo.RegisterEventHandler("ChangeWorld", 						"Reset", self)
	Apollo.RegisterEventHandler("PublicEventStart",					"CheckForDungeon", self)
	Apollo.RegisterEventHandler("MatchEntered", 					"CheckForDungeon", self)
	Apollo.RegisterEventHandler("PublicEventStatsUpdate", 			"OnPublicEventStatsUpdate", self)
	
	self.timerMatchOneSec = ApolloTimer.Create(1.0, true, "OnOneSecTimer", self)
	self.timerPointsCleanup = ApolloTimer.Create(1.5, true, "OnPointsCleanUpTimer", self)
	self.timerPointsCleanup:Stop()
	
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "DungeonMedalsMain", "FixedHudStratum", self)
	
	if not self:CheckForDungeon() then
		self:Reset()
	end
end

function DungeonMedals:Reset()
	self.wndMain:Show(false)
	self.timerMatchOneSec:Stop()
	self.timerPointsCleanup:Stop()
	
	self:InitializeVars()
end

function DungeonMedals:UpdatePoints()
	if self.peMatch then
		self.nPoints			= self.peMatch:GetStat(PublicEvent.PublicEventStatType.MedalPoints)
	end
	
	local strVisible	= "ffffffff"
	local strDim		= "66ffffff"
	
	-- Bronze - Tier 1
	local wndBronze = self.wndMain:FindChild("Bronze")
	wndBronze:SetTooltip(Apollo.FormatNumber(self.nBronze, 0, true))
	wndBronze:SetBGColor(self.nPoints >= self.nBronze and strVisible or strDim)
	local wndTier1 = self.wndMain:FindChild("Tier1")
	wndTier1:FindChild("Active"):Show(self.nPoints < self.nBronze)
	local wndProgressBar = wndTier1:FindChild("ProgressBar")
	wndProgressBar:SetMax(self.nBronze)
	wndProgressBar:SetProgress(math.min(self.nBronze, self.nPoints))
	wndProgressBar:SetBarColor(self.nPoints >= self.nBronze and strDim or strVisible)
	
	-- Silver - Tier 2
	local wndSilver = self.wndMain:FindChild("Silver")
	wndSilver:SetTooltip(Apollo.FormatNumber(self.nSilver, 0, true))
	wndSilver:SetBGColor(self.nPoints >= self.nSilver and strVisible or strDim)
	local wndTier2 = self.wndMain:FindChild("Tier2")
	wndTier2:FindChild("Active"):Show(self.nPoints >= self.nBronze and self.nPoints < self.nSilver)
	wndProgressBar = wndTier2:FindChild("ProgressBar")
	wndProgressBar:SetMax(self.nSilver - self.nBronze)
	wndProgressBar:SetProgress(self.nPoints > self.nBronze and math.min(self.nSilver, self.nPoints - self.nBronze) or 0)
	wndProgressBar:SetBarColor(self.nPoints >= self.nSilver and strDim or strVisible)

	-- Gold - Tier 3
	local wndGold = self.wndMain:FindChild("Gold")
	wndGold:SetTooltip(Apollo.FormatNumber(self.nGold, 0, true))
	wndGold:SetBGColor(self.nPoints >= self.nGold and strVisible or strDim)
	local wndTier3 = self.wndMain:FindChild("Tier3")
	wndTier3:FindChild("Active"):Show(self.nPoints >= self.nSilver and self.nPoints < self.nGold)
	wndProgressBar = wndTier3:FindChild("ProgressBar")
	wndProgressBar:SetMax(self.nGold - self.nSilver)
	wndProgressBar:SetProgress(self.nPoints > self.nSilver and math.min(self.nGold, self.nPoints - self.nSilver) or 0)
	wndProgressBar:SetBarColor(self.nPoints >= self.nGold and strDim or strVisible)
end

function DungeonMedals:OnPointsCleanUpTimer()
	local nLeft, nTop, nRight, nBottom = self.wndPoints:GetAnchorOffsets()
	local tLoc = WindowLocation.new({ fPoints = { 0.5, 0, 0.5, 0 }, nOffsets = { nLeft-50, nTop-50, nRight-50, nTop-50 }})
	
	self.wndPoints:TransitionMove(tLoc, 1.0)
	self.wndPoints:Show(false, false, 1.0)
	self.nPointDelta = 0
	self.timerPointsCleanup:Stop()
end

function DungeonMedals:OnOneSecTimer()
	if self.peMatch then
		self.nTimeElapsed = self.peMatch:GetElapsedTime() > 0 and math.ceil(self.peMatch:GetElapsedTime() / 1000) or self.nTimeElapsed
	else
		self:CheckForDungeon()
		return
	end
	
	local nTime		= self.nTimeElapsed --+3600 (testing hour formatting)
	local nHours		= math.floor(nTime / 3600)
	local nMinutes	= math.floor((nTime - (nHours * 3600)) / 60)
	local nSeconds 	= nTime - (nHours * 3600) - (nMinutes * 60)
	
	local strTime 		= nHours > 0 
		and string.format("%02d:%02d:%02d", nHours, nMinutes, nSeconds) 
		or string.format("%02d:%02d", nMinutes, nSeconds)
	
	self.wndMain:FindChild("Time"):SetText(strTime)
	self.wndMain:FindChild("Points"):SetText(Apollo.FormatNumber(self.nPoints, 0, true))
	
	self.wndMain:Show(self.nTimeElapsed > 0)
end

function DungeonMedals:CheckForDungeon()
	if self.peMatch then
		return true
	end
	
	for key, peCurrent in pairs(PublicEvent.GetActiveEvents()) do
		if peCurrent:ShouldShowMedalsUI() then
			self.nPoints = peCurrent:GetRewardThreshold(PublicEvent.PublicEventRewardTier_None)
			self.nBronze = peCurrent:GetRewardThreshold(PublicEvent.PublicEventRewardTier_Bronze)
			self.nSilver = peCurrent:GetRewardThreshold(PublicEvent.PublicEventRewardTier_Silver)
			self.nGold = peCurrent:GetRewardThreshold(PublicEvent.PublicEventRewardTier_Gold)
				
			self.peMatch = peCurrent
				
			self.timerMatchOneSec:Start()
			self:UpdatePoints()
			return true
		end
	end
	return false
end

function DungeonMedals:OnPublicEventStatsUpdate(peUpdated)
	if peUpdated:GetEventType() ~= PublicEvent.PublicEventType_Dungeon then
		return
	end
	local nCurrentPoints = peUpdated:GetStat(PublicEvent.PublicEventStatType.MedalPoints)
	if self.nPoints == nCurrentPoints then
		return
	end
	
	self.timerPointsCleanup:Stop()
	self.timerPointsCleanup:Start()
	
	self.nPointDelta = self.nPointDelta + nCurrentPoints - self.nPoints
	if not self.wndPoints then
		self.wndPoints = Apollo.LoadForm(self.xmlDoc, "DungeonMedalsPlusPoints", "FixedHudStratumLow", self)
	else
		local tWndPointsOffsets = self.wndPoints:GetOriginalLocation():ToTable().nOffsets
		self.wndPoints:SetAnchorOffsets(tWndPointsOffsets[1], tWndPointsOffsets[2], tWndPointsOffsets[3], tWndPointsOffsets[4])
	end
	self.wndPoints:SetData(self.nPointDelta)
	self.wndPoints:SetText("+"..tostring(Apollo.FormatNumber(self.nPointDelta, 0, true)))
	self.wndPoints:Show(true, false, 1.0)
	
	self:UpdatePoints()
end

local DungeonMedalsInstance = DungeonMedals:new()
DungeonMedalsInstance:Init()