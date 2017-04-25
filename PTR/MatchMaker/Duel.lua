-----------------------------------------------------------------------------------------------
-- Client Lua Script for MatchMaker
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "Unit"
require "ChatSystemLib"

local MatchMaker = {}

function MatchMaker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.tWndRefs = {}
	o.fDuelCountdown = 0
	o.fDuelWarning = 0

    return o
end

function MatchMaker:Init()
    Apollo.RegisterAddon(self)
end

function MatchMaker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Duel.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function MatchMaker:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("DuelStateChanged", "OnDuelStateChanged", self)
	Apollo.RegisterEventHandler("DuelAccepted", "OnDuelAccepted", self)
	Apollo.RegisterEventHandler("DuelLeftArea", "OnDuelLeftArea", self)
	Apollo.RegisterEventHandler("DuelCancelWarning", "OnDuelCancelWarning", self)

	self.timerDuelCountdown = ApolloTimer.Create(1.0, true, "OnDuelCountdownTimer", self)
	self.timerDuelCountdown:Stop()

	self.timerDuelRangeWarning = ApolloTimer.Create(1.0, true, "OnDuelWarningTimer", self)
	self.timerDuelRangeWarning:Stop()
end

function MatchMaker:OnAcceptDuel(wndHandler, wndControl)
	GameLib.AcceptDuel()
	if self.tWndRefs.wndDuelRequest then
		self.tWndRefs.wndDuelRequest:Destroy()
		self.tWndRefs.wndDuelRequest = nil
	end
end

function MatchMaker:OnDeclineDuel(wndHandler, wndControl)
	GameLib.DeclineDuel()
	if self.tWndRefs.wndDuelRequest then
		self.tWndRefs.wndDuelRequest:Destroy()
		self.tWndRefs.wndDuelRequest = nil
	end
end

function MatchMaker:OnDuelStateChanged(eNewState, unitOpponent)
	
	if self.tWndRefs.wndDuelWarning then
		self.tWndRefs.wndDuelWarning:Destroy()
		self.tWndRefs.wndDuelWarning = nil
	end
	
	if eNewState == GameLib.CodeEnumDuelState.WaitingToAccept then
		if not self.tWndRefs.wndDuelRequest then
			self.tWndRefs["wndDuelRequest"] = Apollo.LoadForm(self.xmlDoc, "DuelRequest", nil, self)
		end
		self.tWndRefs.wndDuelRequest:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("MatchMaker_DuelPrompt"), unitOpponent:GetName()))
		self.tWndRefs.wndDuelRequest:Show(true)
		self.tWndRefs.wndDuelRequest:ToFront()
	else
		if self.tWndRefs.wndDuelRequest then
			self.tWndRefs.wndDuelRequest:Destroy()
			self.tWndRefs.wndDuelRequest = nil
		end
	end
	
end

function MatchMaker:OnDuelAccepted(fCountdownTime)
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_ZonePvP, String_GetWeaselString(Apollo.GetString("MatchMaker_DuelStartingTimer"), fCountdownTime), "")
	self.fDuelCountdown = fCountdownTime - 1

	self.timerDuelCountdown:Start()
end

function MatchMaker:OnDuelCountdownTimer()
	if self.fDuelCountdown <= 0 then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_ZonePvP, Apollo.GetString("Matchmaker_DuelBegin"), "")
		self.timerDuelCountdown:Stop()
	else
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_ZonePvP, self.fDuelCountdown .. "...", "")
		self.fDuelCountdown = self.fDuelCountdown - 1
	end
end

function MatchMaker:OnDuelLeftArea(fTimeRemaining)
	if not self.tWndRefs.wndDuelWarning then
		self.tWndRefs["wndDuelWarning"] = Apollo.LoadForm(self.xmlDoc, "DuelWarning", nil, self)
	end
	self.tWndRefs.wndDuelWarning:FindChild("Timer"):SetText(fTimeRemaining)
	self.tWndRefs.wndDuelWarning:Show(true)
	self.tWndRefs.wndDuelWarning:ToFront()
	self.fDuelWarning = fTimeRemaining -1
	
	self.timerDuelRangeWarning:Start()
end

function MatchMaker:OnDuelWarningTimer()
	if self.fDuelWarning <= 0 then
		if self.tWndRefs.wndDuelWarning then
			self.tWndRefs.wndDuelWarning:Destroy()
			self.tWndRefs.wndDuelWarning = nil
			self.timerDuelRangeWarning:Stop()
		end
	else
		if not self.tWndRefs.wndDuelWarning then
			self.tWndRefs["wndDuelWarning"] = Apollo.LoadForm(self.xmlDoc, "DuelWarning", nil, self)
		end
		self.tWndRefs.wndDuelWarning:FindChild("Timer"):SetText(self.fDuelWarning)
		self.fDuelWarning = self.fDuelWarning - 1
	end
end

function MatchMaker:OnDuelCancelWarning()
	if self.tWndRefs.wndDuelWarning then
		self.tWndRefs.wndDuelWarning:Destroy()
		self.tWndRefs.wndDuelWarning = nil
	end
end

local MatchMakerInst = MatchMaker:new()
MatchMakerInst:Init()
