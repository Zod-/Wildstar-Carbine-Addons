-----------------------------------------------------------------------------------------------
-- Client Lua Script for MatchTracker
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "MatchingGameLib"

local MatchTracker = {}

--Sprites
local strHTLMatchIndicator = "CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp"

--Colors
local kcrRed = ApolloColor.new("ffff3030")
local kcrBlue = ApolloColor.new("ff00deff")
local kcrNeutral = "UI_TextMetalBodyHighlight"

local LuaEnumTeam = 
{
	Red 	= 0,
	Blue 	= 1,
	Neutral = 2,
	RedStole 			= 3,
	RedStoleDropped 	= 4,
	BlueStole 			= 5,
	BlueStoleDropped 	= 6,
}

local ktRavelIdToCTFWindowName =
{
	[LuaEnumTeam.Neutral] 			= "CTFNeutralFlag",
	[LuaEnumTeam.Red] 		= "CTFRedHaveFlag",
	[LuaEnumTeam.RedStole] 			= "CTFRedStoleFlag",
	[LuaEnumTeam.RedStoleDropped] 	= "CTFRedStoleDropped",
	[LuaEnumTeam.Blue] 		= "CTFBlueHaveFlag",
	[LuaEnumTeam.BlueStole] 		= "CTFBlueStoleFlag",
	[LuaEnumTeam.BlueStoleDropped] 	= "CTFBlueStoleDropped",
}

local ktCTFMaskSprites =
{
	Red			= "CRB_InterfaceMenuList:spr_Walatiki_MaskRed_Flag",
	RedEmpty	= "CRB_InterfaceMenuList:spr_Walatiki_MaskRed__Flag_Empty",
	Blue 		= "CRB_InterfaceMenuList:spr_Walatiki_MaskBlue_Flag",
	BlueEmpty 	= "CRB_InterfaceMenuList:spr_Walatiki_MaskBlue__Flag_Empty",
}

local ktCTFMaskStatus = 
{
	[LuaEnumTeam.Neutral] 			= false,
	[LuaEnumTeam.Red] 				= false,
	[LuaEnumTeam.RedStole] 			= false,
	[LuaEnumTeam.RedStoleDropped] 	= false,
	[LuaEnumTeam.Blue] 				= false,
	[LuaEnumTeam.BlueStole] 		= false,
	[LuaEnumTeam.BlueStoleDropped] 	= false,
}

local ktHTLTeamInfo = 
{
	Red = {	eNum = 6, kcrColor = kcrRed, strWndIndicator = "RoundTracker:RedWin", bHasWon  = false, peoProgress = 5170 },
	Blue = { eNum = 7, kcrColor = kcrBlue, strWndIndicator = "RoundTracker:BlueWin", bHasWon  = false, peoProgress = 5171 },
}

local ktHTLRoundTracker =
{
	[1] = 5173,
	[2] = 5174,
	[3] = 5203,
}

local ktPvPEventTypes =
{
	[PublicEvent.PublicEventType_PVP_Warplot] 					= 1,
	[PublicEvent.PublicEventType_PVP_Battleground_Vortex] 		= 1,
	[PublicEvent.PublicEventType_PVP_Arena] 					= 1,
	[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine] 	= 1,
	[PublicEvent.PublicEventType_PVP_Battleground_Sabotage] 	= 1,
	[PublicEvent.PublicEventType_PVP_Battleground_Cannon] 		= 1,
}

local knSaveVersion = 1

function MatchTracker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.eSelectedType = nil
	o.eSelectedDesc = nil
	o.fTimeRemaining = 0
	o.fTimeInQueue = 0
	o.eMyTeam = 0
	
	o.tWndRefs = {}

    return o
end

function MatchTracker:Init()
    Apollo.RegisterAddon(self)
end

function MatchTracker:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	
	local bIsHoldTheLine = false
	local bIsCTF = false
	
	local tActiveEvents = PublicEvent.GetActiveEvents()
	
	for idx, peEvent in pairs(tActiveEvents) do
		if peEvent:GetEventType() == PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine then
			bIsHoldTheLine = true
		end
		
		if peEvent:GetEventType() == PublicEvent.PublicEventType_PVP_Battleground_Vortex then
			bIsCTF = true
		end
	end
	
	local tSaved = 
	{
		nSaveVersion = knSaveVersion,
		tSavedCTFFlags = 
		{
			[LuaEnumTeam.Neutral] = self.tWndRefs.wndMatchTracker and self.tWndRefs.wndMatchTracker:FindChild("CTFNeutralFlag"):IsVisible() or false,
			[LuaEnumTeam.Red] = self.tWndRefs.wndMatchTracker and self.tWndRefs.wndMatchTracker:FindChild("CTFRedHaveFlag"):IsVisible() or false,
			[LuaEnumTeam.RedStole] = self.tWndRefs.wndMatchTracker and self.tWndRefs.wndMatchTracker:FindChild("CTFRedStoleFlag"):IsVisible() or false,
			[LuaEnumTeam.RedStoleDropped] = self.tWndRefs.wndMatchTracker and self.tWndRefs.wndMatchTracker:FindChild("CTFRedStoleDropped"):IsVisible() or false,
			[LuaEnumTeam.Blue] = self.tWndRefs.wndMatchTracker and self.tWndRefs.wndMatchTracker:FindChild("CTFBlueHaveFlag"):IsVisible() or false,
			[LuaEnumTeam.BlueStole]= self.tWndRefs.wndMatchTracker and self.tWndRefs.wndMatchTracker:FindChild("CTFBlueStoleFlag"):IsVisible() or false,
			[LuaEnumTeam.BlueStoleDropped]= self.tWndRefs.wndMatchTracker and self.tWndRefs.wndMatchTracker:FindChild("CTFBlueStoleDropped"):IsVisible() or false,
		},
	}
	
	return tSaved
end

function MatchTracker:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	self.tSavedData = tSavedData
	if not tSavedData or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end

	local bIsHoldTheLine = false
	local bIsCTF = false

	local tActiveEvents = PublicEvent.GetActiveEvents()
	self.tActiveEvents = tActiveEvents

	for idx, peEvent in pairs(tActiveEvents) do
		if peEvent:GetEventType() == PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine then
			bIsHoldTheLine = true
		end

		if peEvent:GetEventType() == PublicEvent.PublicEventType_PVP_Battleground_Vortex then
			bIsCTF = true
		end
	end

	if bIsHoldTheLine and tSavedData.tHTLWindowLocation then
		self.locSavedWindowLoc = WindowLocation.new(tSavedData.tHTLWindowLocation)
	end

	if bIsCTF and tSavedData.tSavedCTFFlags then
		self.tSavedCTFFlags = tSavedData.tSavedCTFFlags
	end
end

-----------------------------------------------------------------------------------------------
-- MatchTracker OnLoad
-----------------------------------------------------------------------------------------------

function MatchTracker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("MatchTracker.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function MatchTracker:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("MatchEntered", 				"OnMatchEntered", self)
	Apollo.RegisterEventHandler("MatchExited", 					"OnMatchExited", self)
	Apollo.RegisterEventHandler("ChangeWorld", 					"OnMatchExited", self)
	Apollo.RegisterEventHandler("MatchingPvpInactivityAlert", 	"OnMatchPvpInactivityAlert", self)
	
	self.timerTeamAlert = ApolloTimer.Create(5.0, false, "OnHideTeamAlert", self)
	self.timerTeamAlert:Stop()
	
	self:ResetTracker()
end

function MatchTracker:ResetTracker()
	if self.tWndRefs.wndMatchTracker ~= nil and self.tWndRefs.wndMatchTracker:IsValid() then -- stops double-loading
		return
	end

	self.tWndRefs.wndMatchTracker 	= Apollo.LoadForm(self.xmlDoc, "MatchTracker", "FixedHudStratum", self)
	
	self.match 					= nil
	self.nHTLHintArrow 			= nil
	self.nHTLTimeToBeat 		= 0
	self.nHTLCaptureMod			= 0
	self.bHTLAttacking 			= false

	Apollo.CreateTimer("OneSecMatchTimer", 1.0, true)
	Apollo.StopTimer("OneSecMatchTimer")
	Apollo.RemoveEventHandler("OneSecMatchTimer", self)
	Apollo.RegisterTimerHandler("OneSecMatchTimer", 					"OnOneSecMatchTimer", self)
	
	Apollo.RegisterEventHandler("PVPMatchFinished", 					"OnPVPMatchFinished", self)
	Apollo.RegisterEventHandler("PVPMatchStateUpdated", 				"OnOneSecMatchTimer", self) -- For Immediate updating
	Apollo.RegisterEventHandler("PVPDeathmatchPoolUpdated", 			"OnOneSecMatchTimer", self) -- For Immediate updating
	
	Apollo.RegisterEventHandler("PublicEventEnd",						"OnPublicEventEnd", self)

	-- CTF Events	
	Apollo.RegisterEventHandler("PvP_CTF_FlagSpawned", 					"OnCTFFlagSpawned", self)
	Apollo.RegisterEventHandler("PvP_CTF_NeutralDespawned", 			"OnCTFFlagDespawned", self)
	Apollo.RegisterEventHandler("PvP_CTF_FlagDropped", 					"OnCTFFlagDropped", self)
	Apollo.RegisterEventHandler("PvP_CTF_FlagRecovered", 				"OnCTFFlagRecovered", self)
	Apollo.RegisterEventHandler("PvP_CTF_FlagCollected", 				"OnCTFFlagCollected", self)
	Apollo.RegisterEventHandler("PvP_CTF_FlagStolenDroppedCollected", 	"OnCTFFlagStolenDroppedCollected", self)
	Apollo.RegisterEventHandler("PvP_CTF_FlagStolen", 					"OnCTFFlagStollen", self)
	Apollo.RegisterEventHandler("PvP_CTF_FlagSocketed", 				"OnCTFFlagSocketed", self)

	-- Hold the Line
	Apollo.RegisterEventHandler("PvP_HTL_TimeToBeat", 					"OnHTLTimeToBeat", self)
	Apollo.RegisterEventHandler("PvP_HTL_Respawn", 						"OnHTLRespawn", self)
	Apollo.RegisterEventHandler("PvP_HTL_CaptureModifier", 				"OnHTLCaptureMod", self)
	Apollo.RegisterEventHandler("PvP_HTL_PrepPhase",					"OnHTLPrepPhase", self)
	Apollo.RegisterEventHandler("PVP_BG_HALLS_ROUND_WINNER", 			"UpdateHTLRound", self)
	
	-- Load window types
	self.tWndRefs.tMatchWnd = {
		[PublicEvent.PublicEventType_PVP_Arena] 					= self.tWndRefs.wndMatchTracker:FindChild("DeathMatchInfo"),
		[PublicEvent.PublicEventType_PVP_Battleground_Vortex] 		= self.tWndRefs.wndMatchTracker:FindChild("CTFMatchInfo"),
		[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine] 	= self.tWndRefs.wndMatchTracker:FindChild("HoldLineMatchInfo"),
	}
	
	--Transfer saved flags to active mask status
	if self.tSavedCTFFlags then
		for eState, bIsShown in pairs(self.tSavedCTFFlags) do
			ktCTFMaskStatus[eState] = bIsShown
		end
		self:ShowAppropriateMessages()
	end

	local uMatchMakingEntry = MatchingGameLib.GetQueueEntry()
	if uMatchMakingEntry and uMatchMakingEntry:IsPvpGame() then
		self:OnMatchEntered()
	end
end

function MatchTracker:OnMatchEntered()
	if MatchingGameLib.IsInPvpGame() then
		Apollo.StartTimer("OneSecMatchTimer")
	end
	
	if self.tSavedCTFFlags then -- Clear any saved flags
		for eState, bIsShown in pairs(self.tSavedCTFFlags) do
			self.tSavedCTFFlags[eState] = false
		end
	end	
end

function MatchTracker:OnMatchExited()
	Apollo.StopTimer("OneSecMatchTimer")
	if self.tWndRefs.wndMatchTracker ~= nil and self.tWndRefs.wndMatchTracker:IsValid() then
		self.tWndRefs.wndMatchTracker:Destroy()
		self.tWndRefs = {}
		self.timerTeamAlert:Stop()
	end
	self.nHTLTimeToBeat = 0
	if self.tLastResTeam then
		for idx = 1,2 do
			self.tLastResTeam[idx].nAmount = -1
			self.tLastResTeam[idx].nCount = 0
			self.tLastResTeam[idx].nTrend = 0
			self.tLastResTeam[idx].nTrendOverall = 0
		end
	end
	
	self.peMatch = nil
	self.tZombieEvent = nil
	
	if self.tSavedCTFFlags then
		for eState, bIsShown in pairs(self.tSavedCTFFlags) do
			self.tSavedCTFFlags[eState] = false
		end
	end

	Apollo.RemoveEventHandler("PVPMatchFinished",					self)
	Apollo.RemoveEventHandler("PVPMatchStateUpdated",				self)
	Apollo.RemoveEventHandler("PVPDeathmatchPoolUpdated",			self)
	Apollo.RemoveEventHandler("PvP_CTF_FlagSpawned",				self)
	Apollo.RemoveEventHandler("PvP_CTF_NeutralDespawned",			self)
	Apollo.RemoveEventHandler("PvP_CTF_FlagDropped",				self)
	Apollo.RemoveEventHandler("PvP_CTF_FlagRecovered",				self)
	Apollo.RemoveEventHandler("PvP_CTF_FlagCollected",				self)
	Apollo.RemoveEventHandler("PvP_CTF_FlagStolenDroppedCollected",	self)
	Apollo.RemoveEventHandler("PvP_CTF_FlagStolen",					self)
	Apollo.RemoveEventHandler("PvP_CTF_FlagSocketed",				self)
	Apollo.RemoveEventHandler("PvP_HTL_TimeToBeat", 				self)
	Apollo.RemoveEventHandler("PvP_HTL_Respawn", 					self)
	Apollo.RemoveEventHandler("PvP_HTL_CaptureModifier", 			self)
	Apollo.RemoveEventHandler("PvP_HTL_PrepPhase",					self)
	Apollo.RemoveEventHandler("PVP_BG_HALLS_ROUND_WINNER", 			self)
end

function MatchTracker:OnMatchPvpInactivityAlert(nRemainingTimeMs)
	local nSeconds = nRemainingTimeMs / 1000 
	local strMsg = String_GetWeaselString(Apollo.GetString("Matching_PvpInactivityAlert"), nSeconds)
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strMsg)
end

function MatchTracker:OnShowTeamAlert(peEvent)
	local wndMessage = self.tWndRefs.wndMatchTracker:FindChild("PrepPhase")
	local bIsBlueTeam = MatchingGameLib.GetPvpMatchState().eMyTeam == LuaEnumTeam.Blue
	wndMessage:SetText(bIsBlueTeam and Apollo.GetString("MatchTracker_AlertBlue") or Apollo.GetString("MatchTracker_AlertRed"))
	wndMessage:SetTextColor(bIsBlueTeam and "UI_TextHoloBodyHighlight" or "UI_WindowTextRed")
	wndMessage:Show(true)
	
	self.timerTeamAlert:Set(5.0, false)
	self.timerTeamAlert:Start()
end

function MatchTracker:OnHideTeamAlert()
	if not self.tWndRefs.wndMatchTracker then
		return
	end

	self.tWndRefs.wndMatchTracker:FindChild("PrepPhase"):Show(false)
end

-----------------------------------------------------------------------------------------------
-- Main Timer
-----------------------------------------------------------------------------------------------

function MatchTracker:OnOneSecMatchTimer()
	if not self.tWndRefs.wndMatchTracker or not self.tWndRefs.wndMatchTracker:IsValid() then
		self:ResetTracker()
	end

	local tMatchState = MatchingGameLib.GetPvpMatchState()
	if not tMatchState then
		return
	end
	
	self.tWndRefs.wndMatchTracker:Show(true)
	self.tWndRefs.wndMatchTracker:FindChild("TimerLabel"):SetText(self:HelperTimeString(tMatchState.fTimeRemaining))
	
	if not self.peMatch then
		local eMatchType = nil

		for key, peCurrent in pairs(PublicEvent.GetActiveEvents()) do
			local eType = peCurrent:GetEventType()
			
			if eType == PublicEvent.PublicEventType_SubEvent then
				self.peMatchSub = peCurrent
			else
				self.peMatch = peCurrent
				eMatchType = eType
			end
		end
		
		if eMatchType ~= nil then
			if eMatchType == PublicEvent.PublicEventType_PVP_Battleground_Vortex then
				self:SetupFlags(tMatchState)
				self:OnShowTeamAlert(self.peMatch)
			elseif eMatchType == PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine then
				self:SetupHTLScreen(self.peMatch)
			elseif eMatchType == PublicEvent.PublicEventType_PVP_Warplot or eMatchType == PublicEvent.PublicEventType_PVP_Battleground_Sabotage then
				self:OnShowTeamAlert(self.peMatch)
			end
		end
	end
	
	if tMatchState.eState == MatchingGameLib.PVPGameState.Preparation then
		self.tWndRefs.wndMatchTracker:FindChild("BGArt"):Show(false)
		return
	elseif tMatchState.eState == MatchingGameLib.PVPGameState.Finished then
		self.tWndRefs.wndMatchTracker:FindChild("BGArt"):Show(true)
	end

	-- Look through events. ASSUME: Only one PvP event at a time
	if self.peMatch then
		local eType = self.peMatch:GetEventType()
		
		if eType == PublicEvent.PublicEventType_PVP_Battleground_Vortex then
			self:DrawCTFScreen(self.peMatch)
		elseif eType == PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine then
			self:DrawHTLScreen(self.peMatch)
			-- TODO: Other types
		end
	end

	-- Special case for Deathmatch, it doesn't live in events
	if tMatchState.eRules == MatchingGameLib.Rules.DeathmatchPool then
		self:DrawDeathmatchScreen()
	end
end

-----------------------------------------------------------------------------------------------
-- Blocker Screen (Match Finished, Match Waiting To Start)
-----------------------------------------------------------------------------------------------

function MatchTracker:OnPVPMatchFinished(eWinner, eReason)
	if not self.tWndRefs.wndMatchTracker or not self.tWndRefs.wndMatchTracker:IsValid() then
		self:ResetTracker()
	end

	local tMatchState = MatchingGameLib.GetPvpMatchState()
	local nMyTeam = nil
	if tMatchState then
		eMyTeam = tMatchState.eMyTeam
	end

	local strMessage = Apollo.GetString("MatchTracker_MatchOver")
	if eMyTeam == eWinner and eReason == MatchingGameLib.MatchEndReason.Forfeit then
		strMessage = Apollo.GetString("MatchTracker_EnemyForfeit")
	elseif eMyTeam ~= eWinner and eReason == MatchingGameLib.MatchEndReason.Forfeit then
		strMessage = Apollo.GetString("MatchTracker_YouForfeit")
	elseif MatchingGameLib.Winner.Draw == eWinner then
		strMessage = Apollo.GetString("MatchTracker_Draw")
	elseif eMyTeam == eWinner then
		strMessage = Apollo.GetString("MatchTracker_Victory")
	elseif eMyTeam ~= eWinner then
		strMessage = Apollo.GetString("MatchTracker_Defeat")
	end

	self.tWndRefs.wndMatchTracker:FindChild("MessageBlockerFrame"):Invoke()
	self.tWndRefs.wndMatchTracker:FindChild("BGArt"):Show(true)
	self.tWndRefs.wndMatchTracker:FindChild("TimerLabel"):SetText("")
end

function MatchTracker:OnMatchLeaveBtn(wndHandler, wndControl)
	if MatchingGameLib.IsInGameInstance() then
		MatchingGameLib.LeaveGame()
	end
end

-----------------------------------------------------------------------------------------------
-- CTF Events
-----------------------------------------------------------------------------------------------
function MatchTracker:SetupFlags(tMatchState)
	local strLeftSprite = ktCTFMaskSprites.BlueEmpty
	local strRightSprite = ktCTFMaskSprites.RedEmpty
	
	if tMatchState.eMyTeam == LuaEnumTeam.Red then
		strLeftSprite = ktCTFMaskSprites.RedEmpty
		strRightSprite = ktCTFMaskSprites.BlueEmpty
	end
	
	local tLeftChildren = self.tWndRefs.tMatchWnd[PublicEvent.PublicEventType_PVP_Battleground_Vortex]:FindChild("CTFLeftFrame"):GetChildren()
	local tRightChildren = self.tWndRefs.tMatchWnd[PublicEvent.PublicEventType_PVP_Battleground_Vortex]:FindChild("CTFRightFrame"):GetChildren()
		
	for idx = 1, #tLeftChildren do
		tLeftChildren[idx]:SetSprite(strLeftSprite)
		tRightChildren[idx]:SetSprite(strRightSprite)
	end
	
	local wndInfo = self.tWndRefs.tMatchWnd[PublicEvent.PublicEventType_PVP_Battleground_Vortex]
	local eTeam = MatchingGameLib.GetPvpMatchState().eMyTeam
	local bIsBlue = eTeam == LuaEnumTeam.Blue
	local wndCTFYourTeam = self.tWndRefs.wndMatchTracker:FindChild("CTFYourTeam")
	local wndCTFEnemyTeam = self.tWndRefs.wndMatchTracker:FindChild("CTFEnemyTeam")
	local wndLeftFrame = wndInfo:FindChild("CTFLeftFrame")
	local wndRightFrame = wndInfo:FindChild("CTFRightFrame")
	
	if bIsBlue then
		wndCTFYourTeam:SetTextColor("BrightSkyBlue")
		wndCTFEnemyTeam:SetTextColor("UI_BtnTextGrayListNormal")
		wndLeftFrame:SetData(LuaEnumTeam.Blue)
		wndRightFrame:SetData(LuaEnumTeam.Red)
	else
		wndCTFYourTeam:SetTextColor("Orangered")
		wndCTFEnemyTeam:SetTextColor("UI_BtnTextGrayListNormal")
		wndLeftFrame:SetData(LuaEnumTeam.Red)
		wndRightFrame:SetData(LuaEnumTeam.Blue)
	end	
end

function MatchTracker:OnCTFFlagCollected(nArg) -- This is picking up a neutral flag
	self:HelperCTFMinusOneFlag(LuaEnumTeam.Neutral)		--neutral flag was grabbed
	self:HelperCTFPlusOneFlag(nArg == LuaEnumTeam.Blue and LuaEnumTeam.Blue or LuaEnumTeam.Red) --One side gains a flag
end

function MatchTracker:OnCTFFlagStolenDroppedCollected(nArg) -- This is someone picking up/relaying a stolen flag
	if nArg == 1 then
		self:HelperCTFPlusOneFlag(LuaEnumTeam.BlueStole)		-- Blue team picks up red mask that they're stealing.
		self:HelperCTFMinusOneFlag(LuaEnumTeam.BlueStoleDropped)	--Unclaimed red mask has been picked up again by Blue Team.
	elseif nArg == 2 then
		self:HelperCTFPlusOneFlag(LuaEnumTeam.RedStole)		-- Red team picks up blue mask that they're stealing.
		self:HelperCTFMinusOneFlag(LuaEnumTeam.RedStoleDropped)		--Unclaimed blue mask has been picked up again by Red Team.
	end
end

function MatchTracker:OnCTFFlagRecovered(nArg) -- This is a stolen flag despawning
	if nArg == 1 then -- Red team recovered their mask. Remove unclaimed red mask.
		self:HelperCTFMinusOneFlag(LuaEnumTeam.RedStoleDropped)
	elseif nArg == 2 then -- Blue team recovered their mask. Remove unclaimed blue mask.
		self:HelperCTFMinusOneFlag(LuaEnumTeam.BlueStoleDropped)
	end
end

function MatchTracker:OnCTFFlagSpawned(nArg)
	self:HelperCTFPlusOneFlag(LuaEnumTeam.Neutral)
end

function MatchTracker:OnCTFFlagDespawned()
	self:HelperCTFMinusOneFlag(LuaEnumTeam.Neutral)
end

function MatchTracker:OnCTFFlagDropped(nArg)
	if nArg == 1 then -- Red team stole blue mask
		self:HelperCTFMinusOneFlag(LuaEnumTeam.RedStole)	-- Remove indicator for red moving a blue mask.
		self:HelperCTFPlusOneFlag(LuaEnumTeam.RedStoleDropped)	-- Show indicator for an unclaimed blue mask.
	elseif nArg == 2 then--Blue Team stole red mask
		self:HelperCTFMinusOneFlag(LuaEnumTeam.BlueStole)	-- Remove indicator for blue team moving a red mask.
		self:HelperCTFPlusOneFlag(LuaEnumTeam.BlueStoleDropped)	-- Show indicator for an unclaimed red mask.
	elseif nArg == 3 then--Blue Team Dropped Neutral Flag
		self:HelperCTFMinusOneFlag(LuaEnumTeam.Blue)	--Red loses flag
		self:HelperCTFPlusOneFlag(LuaEnumTeam.Neutral)	--Flag is on the ground
	elseif nArg == 4 then--Red Team Dropped Neutral Flag
		self:HelperCTFMinusOneFlag(LuaEnumTeam.Red)	--Blue lose flag
		self:HelperCTFPlusOneFlag(LuaEnumTeam.Neutral)	--Flag is on the ground
	end
end

function MatchTracker:OnCTFFlagStollen(nArg)
	if nArg == 1 then
		self:HelperCTFPlusOneFlag(LuaEnumTeam.BlueStole) --One side steals a flag
	elseif nArg == 2 then
		self:HelperCTFPlusOneFlag(LuaEnumTeam.RedStole) --One side steals a flag	
	end
end

function MatchTracker:OnCTFFlagSocketed(nArg)
	--Need some extra logic to determine whether the capped flag was stolen or neutral.
	if nArg == 1 then 
		if ktCTFMaskStatus[LuaEnumTeam.BlueStole] then
			self:HelperCTFMinusOneFlag(LuaEnumTeam.BlueStole)
		else 
			self:HelperCTFMinusOneFlag(LuaEnumTeam.Blue)
		end
	elseif nArg == 2 then
		if ktCTFMaskStatus[LuaEnumTeam.RedStole] then	
			self:HelperCTFMinusOneFlag(LuaEnumTeam.RedStole)
		else 
			self:HelperCTFMinusOneFlag(LuaEnumTeam.Red)
		end	
	end	
end

function MatchTracker:HelperCTFPlusOneFlag(eState)
	local strWindowName = ktRavelIdToCTFWindowName[eState]
	local wndAlertAnimation = self.tWndRefs.wndMatchTracker:FindChild(strWindowName):FindChild("AlertAnimation")

	if strWindowName and self.tWndRefs.wndMatchTracker then
		ktCTFMaskStatus[eState] = true
		wndAlertAnimation:SetSprite("CRB_InterfaceMenuList:spr_anim_WalatikiAlertBurst")
	end
	self:ShowAppropriateMessages()
end

function MatchTracker:HelperCTFMinusOneFlag(eState)
	local strWindowName = ktRavelIdToCTFWindowName[eState]
	if strWindowName and self.tWndRefs.wndMatchTracker then
		ktCTFMaskStatus[eState] = false
	end
	self:ShowAppropriateMessages()
end

function MatchTracker:ShowAppropriateMessages()
	local wndAlertContainer = self.tWndRefs.wndMatchTracker:FindChild("CTFAlertContainer")
	local wndCTFNeutralFlag = self.tWndRefs.wndMatchTracker:FindChild("CTFNeutralFlag")
		
	for eState, bIsShown in pairs(ktCTFMaskStatus) do
		local strMaskName = ktRavelIdToCTFWindowName[eState]
		local wndMask = self.tWndRefs.wndMatchTracker:FindChild(strMaskName)
		
		if bIsShown then
			wndMask:Show(true)
		else
			wndMask:Show(false)
		end
	end	
	
	-- Adjust the width of the alert container based on how many icons are active
	local nIconWidth = wndCTFNeutralFlag:GetWidth()
	local nAlertContainerLeft, nAlertContainerTop, nAlertContainerRight, nAlertContainerBottom = wndAlertContainer:GetAnchorOffsets();
	local nAlertContainerHorizCenter = (nAlertContainerLeft + nAlertContainerRight)/2
	local nNewAlertContainerWidth = 0
	local nActiveIcons = 0
	
	for eState, bIsShown in pairs(ktCTFMaskStatus) do
		if bIsShown then 
			nActiveIcons = nActiveIcons + 1
		end  
	end
	
	if nActiveIcons > 0 then
		wndAlertContainer:Show(true)	
	else
		wndAlertContainer:Show(false)	
	end
	
	nNewAlertContainerHorizOffset = ((nIconWidth * nActiveIcons) + nIconWidth)/2
	wndAlertContainer:SetAnchorOffsets(-nNewAlertContainerHorizOffset + nAlertContainerHorizCenter, nAlertContainerTop, nNewAlertContainerHorizOffset + nAlertContainerHorizCenter, nAlertContainerBottom)
	wndAlertContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)	
end

-----------------------------------------------------------------------------------------------
-- Death Match
-----------------------------------------------------------------------------------------------

function MatchTracker:DrawDeathmatchScreen()
	local tMatchState = MatchingGameLib.GetPvpMatchState()
	if not tMatchState or tMatchState.eRules ~= MatchingGameLib.Rules.DeathmatchPool then
		return
	end

	self:HelperClearMatchesExcept(PublicEvent.PublicEventType_PVP_Arena)
	local wndInfo = self.tWndRefs.tMatchWnd[PublicEvent.PublicEventType_PVP_Arena]
	local eMyTeam = tMatchState.eMyTeam
	local nLivesTeam1 = tMatchState.tLivesRemaining[MatchingGameLib.Team.Team1]
	local nLivesTeam2 = tMatchState.tLivesRemaining[MatchingGameLib.Team.Team2]

	local strOldCount1 = wndInfo:FindChild("MyTeam"):GetText()
	local strOldCount2 = wndInfo:FindChild("OtherTeam"):GetText()

	if eMyTeam == MatchingGameLib.Team.Team1 then
		wndInfo:FindChild("MyTeam"):SetText(nLivesTeam1)
		wndInfo:FindChild("OtherTeam"):SetText(nLivesTeam2)
	else
		strOldCount2 = wndInfo:FindChild("MyTeam"):GetText()
		strOldCount1 = wndInfo:FindChild("OtherTeam"):GetText()
		wndInfo:FindChild("MyTeam"):SetText(nLivesTeam2)
		wndInfo:FindChild("OtherTeam"):SetText(nLivesTeam1)
	end
	
	if tonumber(strOldCount1) ~= nLivesTeam1 or tonumber(strOldCount2) ~= nLivesTeam2 then
		wndInfo:FindChild("AlertFlash"):SetSprite("CRB_Basekit:kitAccent_Glow_BlueFlash")
	end
end

-----------------------------------------------------------------------------------------------
-- CTF
-----------------------------------------------------------------------------------------------

function MatchTracker:DrawCTFScreen(peMatch)
	if not peMatch then
		return
	end

	self:HelperClearMatchesExcept(PublicEvent.PublicEventType_PVP_Battleground_Vortex)
	local wndInfo = self.tWndRefs.tMatchWnd[PublicEvent.PublicEventType_PVP_Battleground_Vortex]
	wndInfo:SetData(peMatch)
	
	local strBlueCappedSprite = ktCTFMaskSprites.Blue
	local strRedCappedSprite = ktCTFMaskSprites.Red
	local strBlueEmptySprite = ktCTFMaskSprites.BlueEmpty
	local strRedEmptySprite = ktCTFMaskSprites.RedEmpty


	for idObjective, peoCurrent in pairs(peMatch:GetObjectives()) do
		local wndToUse = wndInfo:FindChild("CTFLeftFrame")
		
		if peoCurrent:GetTeam() ~= peMatch:GetJoinedTeam() then
			wndToUse = wndInfo:FindChild("CTFRightFrame")
		end

		for idx = 1, peoCurrent:GetRequiredCount() do
			local wndFlag = wndToUse:FindChild("FlagIcon" .. idx)
			
			if wndFlag and idx > peoCurrent:GetCount() then
				if wndToUse:GetData() == LuaEnumTeam.Blue then
					wndFlag:SetSprite(strBlueEmptySprite)
				else
					wndFlag:SetSprite(strRedEmptySprite)
				end
			elseif wndFlag then
				if wndToUse:GetData() == LuaEnumTeam.Blue then
					wndFlag:SetSprite(strBlueCappedSprite)
				else
					wndFlag:SetSprite(strRedCappedSprite)
				end
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Hold The Line
-----------------------------------------------------------------------------------------------
function MatchTracker:SetupHTLScreen(peMatch)
	if not peMatch then return end
	self:HelperClearMatchesExcept(PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine)
	local wndDatachron = self.tWndRefs.tMatchWnd[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine]
	local wndParent = self.tWndRefs.tMatchWnd[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine]
	wndDatachron:SetData(peMatch)

	-- Reset round trackers
	local tRoundIndicators = wndParent:FindChild("RoundTracker"):GetChildren()
	for idx, wndName in pairs(tRoundIndicators) do
		local strWndName = wndName:GetName()
		wndParent:FindChild("RoundTracker:"..strWndName ..":Indicator"):SetBGColor(kcrNeutral)
	end
	
	-- Display labels to indicate team assignment
	local eTeam = peMatch:GetJoinedTeam()
	local wndBlueTeam = wndParent:FindChild("BlueTeam")
	local wndBlueTeamText = wndBlueTeam:FindChild("TeamText")
	local wndRedTeam = wndParent:FindChild("RedTeam")
	local wndRedTeamText = wndRedTeam:FindChild("TeamText")
			
	if eTeam == ktHTLTeamInfo["Blue"].eNum  then -- Your team is blue
		wndBlueTeam:FindChild("Highlight"):Show(true)
		wndRedTeam:FindChild("Highlight"):Show(false)
		wndBlueTeamText:SetText(Apollo.GetString("MatchTracker_YourTeam"))
		wndBlueTeamText:SetTextColor(kcrBlue)
		wndRedTeamText:SetText(Apollo.GetString("MatchTracker_EnemyTeam"))
		wndRedTeamText:SetTextColor(kcrNeutral)
	elseif eTeam == ktHTLTeamInfo["Red"].eNum then -- Your team is red
		wndRedTeam:FindChild("Highlight"):Show(true)
		wndBlueTeam:FindChild("Highlight"):Show(false)
		wndRedTeamText:SetText(Apollo.GetString("MatchTracker_YourTeam"))
		wndRedTeamText:SetTextColor(kcrRed)
		wndBlueTeamText:SetText(Apollo.GetString("MatchTracker_EnemyTeam"))
		wndBlueTeamText:SetTextColor(kcrNeutral)
	end
	
	-- Update round status
	self:UpdateHTLRound()
end

function MatchTracker:UpdateHTLRound(nRound, nWinner)
	local wndParent = self.tWndRefs.tMatchWnd[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine]
		
	ktHTLTeamInfo["Red"].bHasWon = false
	ktHTLTeamInfo["Blue"].bHasWon = false	
	
	if not self.peMatchSub then
		for key, peCurrent in pairs(PublicEvent.GetActiveEvents()) do
			local eType = peCurrent:GetEventType()
			if eType == PublicEvent.PublicEventType_SubEvent then
				self.peMatchSub = peCurrent
				break
			end		
		end
	end
	
	-- Update round indicators on reload
	if self.peMatchSub then
		Sound.Play(Sound.PlayUICraftingSuccess)	
		for idx, nObjectiveId in pairs(ktHTLRoundTracker) do
			local peoRoundWinner = self.peMatchSub:GetObjective(nObjectiveId)
			local nRoundWinner = peoRoundWinner:GetOwningTeam()
			for strTeam, tInfo in pairs(ktHTLTeamInfo) do
				-- If this is the team's second win, their own dot and Match Point will always be filled
				if nRoundWinner == ktHTLTeamInfo[strTeam].eNum and ktHTLTeamInfo[strTeam].bHasWon == true then 
					wndParent:FindChild("RoundTracker:MatchPoint:Indicator"):SetBGColor(ktHTLTeamInfo[strTeam].kcrColor)
					wndParent:FindChild("RoundTracker:MatchPoint:Flash"):SetSprite(strHTLMatchIndicator)
					wndParent:FindChild(ktHTLTeamInfo[strTeam].strWndIndicator..":Indicator"):SetBGColor(ktHTLTeamInfo[strTeam].kcrColor)
					wndParent:FindChild(ktHTLTeamInfo[strTeam].strWndIndicator..":Flash"):SetSprite(strHTLMatchIndicator)
				-- If this is the team's first win, only their own dot should be filled. 
				elseif nRoundWinner == ktHTLTeamInfo[strTeam].eNum then
					wndParent:FindChild(ktHTLTeamInfo[strTeam].strWndIndicator..":Indicator"):SetBGColor(ktHTLTeamInfo[strTeam].kcrColor)
					wndParent:FindChild(ktHTLTeamInfo[strTeam].strWndIndicator..":Flash"):SetSprite(strHTLMatchIndicator)
					end
					
				-- Assign a win to the appropriate team
				if nRoundWinner == ktHTLTeamInfo[strTeam].eNum then
					ktHTLTeamInfo[strTeam].bHasWon = true
				end
			end		
		end
	end
end

function MatchTracker:DrawHTLScreen(peMatch)
	local wndParent = self.tWndRefs.tMatchWnd[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine]
		
	-- Get objective information
	local peoRedProgress = peMatch:GetObjective(ktHTLTeamInfo["Red"].peoProgress)
	local peoBlueProgress = peMatch:GetObjective(ktHTLTeamInfo["Blue"].peoProgress)

	-- Update health
	local nRedProgress = peoRedProgress:GetCount()
	local nBlueProgress = peoBlueProgress:GetCount()
	
	wndParent:FindChild("RedTeam:ProgressBar"):SetProgress(nRedProgress)
	wndParent:FindChild("BlueTeam:ProgressBar"):SetProgress(nBlueProgress)
end

function MatchTracker:OnHoldLineMouseCatcherClick(wndHandler, wndControl)
	if wndHandler:GetData() then
		wndHandler:GetData():ShowHintArrow()
	end
end

function MatchTracker:OnHTLRespawn()
	if self.nHTLHintArrow then
		self.nHTLHintArrow:ShowHintArrow()
	end
end

function MatchTracker:OnHTLCaptureMod(nWhole, nDec)
	self.nHTLCaptureMod = nWhole + nDec / 100
end

function MatchTracker:OnHTLPrepPhase(bPreping)
	if self.peMatch ~= nil then
		self.nHTLCaptureMod = 0
		self:DrawHTLScreen(self.peMatch)
	end
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function MatchTracker:OnPublicEventEnd(peEvent, eReason, tStats)
	if (eReason == PublicEvent.PublicEventParticipantRemoveReason_CompleteSuccess or eReason == PublicEvent.PublicEventParticipantRemoveReason_CompleteFailure)
	and ktPvPEventTypes[peEvent:GetEventType()] then
		self.tZombieEvent =
		{
			["peEvent"] = peEvent, 
			["eReason"] = eReason, 
			["tStats"] = tStats
		}
	end
end

function MatchTracker:OnViewEventStatsBtn(wndHandler, wndControl) -- ViewEventStatsBtn
	local peDisplay = nil
	local tDisplayedStats = nil
	if self.tZombieEvent then
		if ktPvPEventTypes[self.tZombieEvent.peEvent:GetEventType()] then
			peDisplay = self.tZombieEvent.peEvent
			tDisplayedStats = self.tZombieEvent.tStats
		end
		
	else		
		for idx, peCurrent in pairs(PublicEvent.GetActiveEvents()) do
			if not peDisplay and peCurrent:HasLiveStats() then
				if ktPvPEventTypes[peCurrent:GetEventType()] then
					peDisplay = peCurrent
					tDisplayedStats = peCurrent:GetLiveStats()
				end
			end
		end
	end
	
	if peDisplay and tDisplayedStats then
		Event_FireGenericEvent("GenericEvent_OpenEventStats", peDisplay, peDisplay:GetMyStats(), tDisplayedStats.arTeamStats, tDisplayedStats.arParticipantStats)
	end
end

function MatchTracker:HelperClearMatchesExcept(nShow) -- hides all other window types
	for idx, wnd in pairs(self.tWndRefs.tMatchWnd) do
		wnd:Show(false)
	end
	
	if nShow ~= nil then
		self.tWndRefs.tMatchWnd[nShow]:Show(true)
	end
end

function MatchTracker:HelperTimeString(nTimeInSeconds)
	if nTimeInSeconds == nil or nTimeInSeconds <= 0 then
		return "--:--"
	end
	
	nTimeInSeconds = math.floor(nTimeInSeconds)
	local nMinutes = math.floor(nTimeInSeconds / 60)
	local nSeconds = math.floor(nTimeInSeconds % 60)
	if nSeconds < 10 then
		return nMinutes .. ":0" .. nSeconds
	end
	return nMinutes .. ":" .. nSeconds
end

-----------------------------------------------------------------------------------------------
-- MatchTracker Instance
-----------------------------------------------------------------------------------------------
local MatchTrackerInst = MatchTracker:new()
MatchTrackerInst:Init()