-----------------------------------------------------------------------------------------------
-- Client Lua Script for ContextMenuPlayer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "GroupLib"
require "ChatSystemLib"
require "FriendshipLib"
require "MatchingGameLib"
require "HousingLib"
require "AccountItemLib"

local knXCursorOffset = 10
local knYCursorOffset = 25
local kstrPvPQuestLinkName = "Codex"
local kstrPvPQuestLocation = Apollo.GetString("CRB_Codex")

local ContextMenuPlayer = {}

-- Bottom to top
local ktSortOrder =
{
	["nil"] 				= 0,
	["BtnPvPFlag"]			= 1,
	["BtnJoin"] 			= 1,
	["BtnLeaveGroup"] 		= 2,
	["BtnInvite"] 			= 2,
	["BtnReportChat"] 		= 3,
	["BtnReportUnit"] 		= 3,
	["BtnTrade"] 			= 4,
	["BtnDuel"] 			= 5,
	["BtnForfeit"] 			= 5,
	["BtnInspect"]			= 6,
	["BtnKick"]				= 7,
	["BtnWhisper"] 			= 8,
	["BtnAccountWhisper"] 	= 8,
	["BtnGuildList"] 		= 9,
	-- Social List: BtnPromoteInGuild	 				
	-- Social List: BtnDemoteInGuild			
	-- Social List: BtnKickFromGuild	
	["BtnSocialList"] 		= 10,
		-- Social List: BtnAddFriend 				BtnUnfriend
		-- Social List: BtnAddRival					BtnUnrival
		-- Social List: BtnAddNeighbor				BtnUnneighbor
		-- Social List: BtnIgnore					BtnUnignore
		-- Social List: BtnVisitPlayer          
	["BtnGroupList"] 		= 11,
		-- Group List: BtnMentor,					BtnStopMentor
		-- Group List: BtnGroupTakeInvite, 			BtnGroupGiveInvite
		-- Group List: BtnGroupTakeKick, 			BtnGroupGiveKick
		-- Group List: BtnGroupTakeMark, 			BtnGroupGiveMark
		-- Group List: BtnVoteToKick
		-- Group List: BtnVoteToDisband
		-- Group List: BtnPromote
		-- Group List: BtnPromote
	["BtnClearFocus"] 		= 12,
	["BtnSetFocus"] 		= 12,
	["BtnLocate"]			= 13,
	--["BtnAssist"] 		= 13,
	["BtnMarkerList"]		= 14,
		-- 8 Markers
		-- BtnMarkClear
	["BtnMarkTarget"] 		= 15,
	
	
	
	
	["BtnPetDismiss"]				= 0 --For Pets
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

function ContextMenuPlayer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function ContextMenuPlayer:Init()
    Apollo.RegisterAddon(self)
end

function ContextMenuPlayer:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ContextMenuPlayer.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function ContextMenuPlayer:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	Apollo.RegisterEventHandler("GenericEvent_NewContextMenuPlayer", 			"Initialize", self) -- 2 args + 2 optional
	Apollo.RegisterEventHandler("GenericEvent_NewContextMenuPlayerDetailed", 	"Initialize", self) -- 3 args + 1 optional
	Apollo.RegisterEventHandler("GenericEvent_NewContextMenuFriend", 			"InitializeFriend", self) -- 2 args
	-- There is a GenericEvent_NewContextMenuPvPStats that's handled in PublicEventStats

	-- Just to recalculate sizing/arrangement (e.g. group button shows up)
	Apollo.RegisterEventHandler("Group_Join", 			"OnEventRequestResize", self)
	Apollo.RegisterEventHandler("Group_Left", 			"OnEventRequestResize", self)
	Apollo.RegisterEventHandler("FriendshipUpdate", 	"OnEventRequestResize", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", 	"OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("PremiumTierChanged", 	"OnPremiumTierOrPlayerLevelChanged", self)
	Apollo.RegisterEventHandler("PlayerLevelChange", 	"OnPremiumTierOrPlayerLevelChanged", self)
	Apollo.RegisterEventHandler("UnitPvpFlagsChanged",	"UpdatePvpFlagBtn", self)
end

function ContextMenuPlayer:SharedInitialize(wndParent)
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Destroy()
		self.wndMain = nil
	end

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "ContextMenuPlayerForm", "TooltipStratum", self)
	self.wndMain:Invoke()

	self.bSortedAndSized = false
	self.tPlayerFaction = GameLib.GetPlayerUnit():GetFaction()

	local tCursor = Apollo.GetMouse()
	self.wndMain:Move(tCursor.x - knXCursorOffset, tCursor.y - knYCursorOffset, self.wndMain:GetWidth(), self.wndMain:GetHeight())
	
	self:UpdatePlayerRewardProperties()
end

function ContextMenuPlayer:InitializeFriend(wndParent, nFriendId)
	self:SharedInitialize(wndParent)
	local unitPlayer = GameLib.GetPlayerUnit()
	local nPlayerFaction = unitPlayer:GetFaction()
	self.tFriend = FriendshipLib.GetById(nFriendId)
	
	if not self.tFriend then
		local tSuggested = FriendshipLib.GetSuggestedById(nFriendId)
		if tSuggested then
			self.tFriend = tSuggested
			self.tFriend.bSuggested = true
		end
	end

	if self.tFriend ~= nil then
		self.strTarget = self.tFriend.strCharacterName
		self.bCrossFaction = self.tFriend.nFactionId ~= nPlayerFaction
	end

	self.tAccountFriend = FriendshipLib.GetAccountById(nFriendId)
	if self.tAccountFriend ~= nil then
		if self.tAccountFriend.arCharacters and self.tAccountFriend.arCharacters[1] ~= nil then
			self.strTarget = self.tAccountFriend.arCharacters[1].strCharacterName
			self.bCrossFaction = self.tAccountFriend.arCharacters[1].nFactionId ~= nPlayerFaction
		end
	end

	self:RedrawAllFriend()
end

function ContextMenuPlayer:RedrawAllFriend()
	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	local strTarget = self.strTarget
	local unitTarget = self.unitTarget
	if unitTarget == nil and self.tFriend ~= nil then
		unitTarget = FriendshipLib.GetUnitById(self.tFriend.nId)
	end
	
	local bCrossFaction = self.bCrossFaction
	local tFriend = self.tFriend
	local tAccountFriend = self.tAccountFriend
	local wndButtonList = self.wndMain:FindChild("ButtonList")

	-- Repeated use booleans
	local unitPlayer = GameLib.GetPlayerUnit()
	local bInGroup = GroupLib.InGroup()
	local tCharacterData = GameLib.SearchRelationshipStatusByCharacterName(strTarget)

	local bCanWhisper = tFriend ~= nil and (tFriend.fLastOnline == 0 and not tFriend.bIgnore and tFriend.nFactionId == unitPlayer:GetFaction() or tFriend.bSuggested)
	local bCanAccountWisper = tAccountFriend ~= nil and tAccountFriend.arCharacters and tAccountFriend.arCharacters[1] ~= nil
	local bIsFriend = (tFriend ~= nil and tFriend.bFriend) or (tCharacterData ~= nil and tCharacterData.tFriend ~= nil and tCharacterData.tFriend.bFriend)
	local bIsRival = (tFriend ~= nil and tFriend.bRival) or (tCharacterData ~= nil and tCharacterData.tFriend ~= nil and tCharacterData.tFriend.bRival)
	local bIsNeighbor = (tFriend ~= nil and tFriend.bNeighbor) or (tCharacterData ~= nil and tCharacterData.tFriend ~= nil and tCharacterData.tNeighbor)
	--local bIsNeighbor = tCharacterData ~= nil and tCharacterData.tNeighbor and tCharacterData.tFriend
	local bIsAccountFriend = tAccountFriend ~= nil or (tCharacterData == nil or tCharacterData.tAccountFriend ~= nil)
	
	local btnSocialList = nil
	local wndSocialListItems = nil
		
	if tFriend and tFriend.bIgnore then
		--no button when player is ignored
	else
		btnSocialList = self:FactoryProduce(wndButtonList, "BtnSocialList", "BtnSocialList")
		wndSocialListItems = btnSocialList:FindChild("SocialListPopoutItems")
		btnSocialList:AttachWindow(btnSocialList:FindChild("SocialListPopoutFrame"))
	end
	
	if bCanAccountWisper then
		bCanWhisper = tAccountFriend.arCharacters[1] ~= nil
			and tAccountFriend.arCharacters[1].strRealm == GameLib.GetRealmName()
			and tAccountFriend.arCharacters[1].nFactionId == unitPlayer:GetFaction()
	end

	if bCanWhisper and not bCanAccountWisper then
		self:HelperBuildRegularButton(wndButtonList, "BtnWhisper", Apollo.GetString("ContextMenu_Whisper"))
	end

	if bCanAccountWisper then
		self:HelperBuildRegularButton(wndButtonList, "BtnAccountWhisper", Apollo.GetString("ContextMenu_AccountWhisper"))
	end

	if tFriend and tFriend.bIgnore then
		self:HelperBuildRegularButton(wndButtonList, "BtnUnignore", Apollo.GetString("ContextMenu_Unignore"))
		self:ResizeAndRedraw()
		return -- early exit if player is ignored
	elseif tAccountFriend == nil then
		self:HelperBuildRegularButton(wndSocialListItems, "BtnIgnore", Apollo.GetString("ContextMenu_Ignore"))
	end

	if bIsRival then
		self:HelperBuildRegularButton(wndSocialListItems, "BtnUnrival", Apollo.GetString("ContextMenu_RemoveRival"))
	elseif tFriend ~= nil or bCanAccountWisper then
		self:HelperBuildRegularButton(wndSocialListItems, "BtnAddRival", Apollo.GetString("ContextMenu_AddRival"))
	end
	
	local bAccountFriendOnline = tAccountFriend and tAccountFriend.fLastOnline == 0
	local bFriendOnline = tFriend and tFriend.fLastOnline == 0
	
	if (bAccountFriendOnline or bFriendOnline) and (not bInGroup or (GroupLib.GetGroupMember(1).bCanInvite and bCanWhisper)) and not bCrossFaction then
		--In SocialPanel, we don't care if they are part of a group, because we can't reliably test it.
		self:HelperBuildRegularButton(wndButtonList, "BtnInvite", Apollo.GetString("ContextMenu_InviteToGroup"))
	end
	
	if (bAccountFriendOnline or bFriendOnline) and (not bInGroup or bCanWhisper) and not bCrossFaction then
		--In SocialPanel, we don't care if they are part of a group, because we can't reliably test it.
		self:HelperBuildRegularButton(wndButtonList, "BtnJoin", Apollo.GetString("CRB_Join_Group"))
	end	

	if bIsFriend then
		if tAccountFriend == nil then
			self:HelperBuildRegularButton(wndSocialListItems, "BtnUnfriend", Apollo.GetString("ContextMenu_RemoveFriend"))
		end
	elseif (tFriend ~= nil and (tFriend.nFactionId == unitPlayer:GetFaction() or tFriend.bSuggested)) or (bCanAccountWisper and bCanWhisper) then
		self:HelperBuildRegularButton(wndSocialListItems, "BtnAddFriend", Apollo.GetString("ContextMenu_AddFriend"))
	end

	if bIsNeighbor then
		self:HelperBuildRegularButton(wndSocialListItems, "BtnUnneighbor", Apollo.GetString("ContextMenu_RemoveNeighbor"))
	elseif ((tFriend ~= nil or bCanAccountWisper) and not bCrossFaction and not bIsRival) or (tFriend and tFriend.bSuggested) then
		self:HelperBuildRegularButton(wndSocialListItems, "BtnAddNeighbor", Apollo.GetString("ContextMenu_AddNeighbor"))
	end	
	
	if HousingLib.IsHousingWorld() then
	    self:HelperBuildRegularButton(wndSocialListItems, "BtnVisitPlayer", Apollo.GetString("CRB_Visit"))
	end
	
	if bIsFriend and not bIsAccountFriend then
		self:HelperBuildRegularButton(wndSocialListItems, "BtnAccountFriend", Apollo.GetString("ContextMenu_PromoteFriend"))
	end

	if tAccountFriend ~= nil and bIsAccountFriend then
		self:HelperBuildRegularButton(wndSocialListItems, "BtnUnaccountFriend", Apollo.GetString("ContextMenu_UnaccountFriend"))
	end

	self:ResizeAndRedraw()
end

function ContextMenuPlayer:Initialize(wndParent, strTarget, unitTarget, tOptionalCharacterData) -- unitTarget may be nil
	self:SharedInitialize(wndParent)

	self.strTarget = strTarget or ""
	self.unitTarget = unitTarget or nil
	self.nReportId = tOptionalCharacterData and tOptionalCharacterData.nReportId or nil
	self.bCrossFaction = tOptionalCharacterData and tOptionalCharacterData.bCrossFaction or nil--turning string to a boolean
	self.guildCurr = tOptionalCharacterData and tOptionalCharacterData.guildCurr or nil
	self.tPlayerGuildData =  tOptionalCharacterData and tOptionalCharacterData.tPlayerGuildData or nil
	self:RedrawAll()
end

function ContextMenuPlayer:RedrawAll()
	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	local bCrossFaction = self.bCrossFaction
	local strTarget = self.strTarget
	local unitTarget = self.unitTarget
	local wndButtonList = self.wndMain:FindChild("ButtonList")

	-- Repeated use booleans
	local unitPlayer = GameLib.GetPlayerUnit()
	local bInGroup = GroupLib.InGroup()
	local bAmIGroupLeader = GroupLib.AmILeader()
	local bBaseCrossFaction =  unitTarget:GetBaseFaction() ~= unitPlayer:GetBaseFaction()
	local tMyGroupData = GroupLib.GetGroupMember(1)
	local tCharacterData = GameLib.SearchRelationshipStatusByCharacterName(strTarget)
	local tTargetGroupData = (tCharacterData and tCharacterData.nPartyIndex) and GroupLib.GetGroupMember(tCharacterData.nPartyIndex) or nil

	-----------------------------------------------------------------------------------------------
	-- Even if hostile/neutral
	-----------------------------------------------------------------------------------------------

	if unitTarget and unitTarget == unitPlayer:GetAlternateTarget()	 then
		self:HelperBuildRegularButton(wndButtonList, "BtnClearFocus", Apollo.GetString("ContextMenu_ClearFocus"))
	elseif unitTarget and unitTarget:GetHealth() ~= nil and unitTarget:GetType() ~= "Simple" then
		self:HelperBuildRegularButton(wndButtonList, "BtnSetFocus", Apollo.GetString("ContextMenu_SetFocus"))
	end
	
	if unitTarget and GameLib.GetPetDismissCommand(unitTarget) > 0 then
		self:HelperBuildPetDismissButton(wndButtonList, "BtnPetDismiss", Apollo.GetString("CRB_Dismiss"), unitTarget)
	end

	if unitTarget and bInGroup and tMyGroupData.bCanMark then
		self:HelperBuildRegularButton(wndButtonList, "BtnMarkTarget", Apollo.GetString("ContextMenu_MarkTarget"))

		local btnMarkerList = self:FactoryProduce(wndButtonList, "BtnMarkerList", "BtnMarkerList")
		local wndMarkerListItems = btnMarkerList:FindChild("MarkerListPopoutItems")
		btnMarkerList:AttachWindow(btnMarkerList:FindChild("MarkerListPopoutFrame"))

		for idx = 1, 8 do
			local wndCurr = self:FactoryProduce(wndMarkerListItems, "BtnMarkerIcon", "BtnMark"..idx)
			wndCurr:FindChild("BtnMarkerIconSprite"):SetSprite(kstrRaidMarkerToSprite[idx])
			wndCurr:FindChild("BtnMarkerMouseCatcher"):SetData("BtnMark"..idx)

			local nCurrentTargetMarker = unitTarget and unitTarget:GetTargetMarker() or ""
			if nCurrentTargetMarker == idx then
				wndCurr:SetCheck(true)
			end
		end

		local wndClear = self:FactoryProduce(wndMarkerListItems, "BtnMarkerIcon", "BtnMarkClear")
		wndClear:FindChild("BtnMarkerMouseCatcher"):SetData("BtnMarkClear")
		--wndClear:SetText("X")
	end

	if unitTarget and unitTarget:IsACharacter() and unitTarget ~= unitPlayer then
		self:HelperBuildRegularButton(wndButtonList, "BtnReportUnit", Apollo.GetString("ContextMenu_ReportPlayer"))
	elseif self.nReportId then -- No unit available
		self:HelperBuildRegularButton(wndButtonList, "BtnReportChat", Apollo.GetString("ContextMenu_ReportSpam"))
	end
	
	if unitTarget and (self.tPlayerFaction ~= unitTarget:GetFaction() or not unitTarget:IsACharacter()) then
		if unitTarget:IsACharacter() then
			if tCharacterData and tCharacterData.tFriend and tCharacterData.tFriend.bRival then
				self:HelperBuildRegularButton(wndButtonList, "BtnUnrival", Apollo.GetString("ContextMenu_RemoveRival"))
			else
				self:HelperBuildRegularButton(wndButtonList, "BtnAddRival", Apollo.GetString("ContextMenu_AddRival"))
			end
		end

		self:ResizeAndRedraw()
		return
	end

	-----------------------------------------------------------------------------------------------
	-- Early exit, else continue only if target is a character
	-----------------------------------------------------------------------------------------------

	if unitTarget and unitTarget:IsACharacter() then
		if unitTarget ~= unitPlayer then
			self:HelperBuildRegularButton(wndButtonList, "BtnInspect", Apollo.GetString("ContextMenu_Inspect"))
			
			-- Trade always visible, just enabled/disabled
			local eCanTradeResult = P2PTrading.CanInitiateTrade(unitTarget)
			local wndCurr = self:HelperBuildRegularButton(wndButtonList, "BtnTrade", Apollo.GetString("ContextMenu_Trade"))
			local bEnabled = eCanTradeResult == P2PTrading.P2PTradeError_Ok or eCanTradeResult == P2PTrading.P2PTradeError_TargetRangeMax
			local strTooltip = ""
			if not bEnabled then
				strTooltip = self.strTradeBtnTooltip
			end
			self:HelperEnableDisableRegularButton(wndCurr, bEnabled, strTooltip)
			
			-- Duel
			local eCurrentZonePvPRules = GameLib.GetCurrentZonePvpRules()
			if not eCurrentZonePvPRules or eCurrentZonePvPRules ~= GameLib.CodeEnumZonePvpRules.Sanctuary then
				if GameLib.GetDuelOpponent(unitPlayer) == unitTarget and GameLib.GetDuelState() == GameLib.CodeEnumDuelState.Dueling then
					self:HelperBuildRegularButton(wndButtonList, "BtnForfeit", Apollo.GetString("ContextMenu_ForfeitDuel"))
				else
					self:HelperBuildRegularButton(wndButtonList, "BtnDuel", Apollo.GetString("ContextMenu_Duel"))
				end
			end
		else
			-- PvP Flag
			self:UpdatePvpFlagBtn()
		end
	end

	if unitTarget == nil or unitTarget ~= unitPlayer then
		local bCanWhisper = not bBaseCrossFaction 
		local bCanAccountWisper = false
		if tCharacterData and tCharacterData.tAccountFriend then
			bCanAccountWisper = true
			bCanWhisper = tCharacterData.tAccountFriend.arCharacters[1] ~= nil
				and tCharacterData.tAccountFriend.arCharacters[1].strRealm == GameLib.GetRealmName()
				and tCharacterData.tAccountFriend.arCharacters[1].nFactionId == GameLib.GetPlayerUnit():GetFaction()
		end

		if bCanWhisper and not bCanAccountWisper then
			self:HelperBuildRegularButton(wndButtonList, "BtnWhisper", Apollo.GetString("ContextMenu_Whisper"))
		end

		if bCanAccountWisper then
			self:HelperBuildRegularButton(wndButtonList, "BtnAccountWhisper", Apollo.GetString("ContextMenu_AccountWhisper"))
		end

		if (not bInGroup or (tMyGroupData.bCanInvite and (unitTarget and not unitTarget:IsInYourGroup()))) and not bCrossFaction then
			self:HelperBuildRegularButton(wndButtonList, "BtnInvite", Apollo.GetString("ContextMenu_InviteToGroup"))
		end
		
		if (not bInGroup or (unitTarget and not unitTarget:IsInYourGroup())) and not bCrossFaction then
			self:HelperBuildRegularButton(wndButtonList, "BtnJoin", Apollo.GetString("CRB_Join_Group"))
		end		
	end

	-----------------------------------------------------------------------------------------------
	-- Social Lists
	-----------------------------------------------------------------------------------------------

	if unitTarget == nil or unitTarget ~= unitPlayer then
		local btnSocialList = self:FactoryProduce(wndButtonList, "BtnSocialList", "BtnSocialList")
		local wndSocialListItems = btnSocialList:FindChild("SocialListPopoutItems")
		btnSocialList:AttachWindow(btnSocialList:FindChild("SocialListPopoutFrame"))

		local bIsFriend = tCharacterData and tCharacterData.tFriend and tCharacterData.tFriend.bFriend
		local bIsRival = tCharacterData and tCharacterData.tFriend and tCharacterData.tFriend.bRival
		local bIsNeighbor = tCharacterData and tCharacterData.tNeighbor
		local bIsAccountFriend = tCharacterData and tCharacterData.tAccountFriend

		if bIsFriend then
			self:HelperBuildRegularButton(wndSocialListItems, "BtnUnfriend", Apollo.GetString("ContextMenu_RemoveFriend"))
		elseif not bBaseCrossFaction then
			self:HelperBuildRegularButton(wndSocialListItems, "BtnAddFriend", Apollo.GetString("ContextMenu_AddFriend"))
		end

		if bIsRival then
			self:HelperBuildRegularButton(wndSocialListItems, "BtnUnrival", Apollo.GetString("ContextMenu_RemoveRival"))
		else
			self:HelperBuildRegularButton(wndSocialListItems, "BtnAddRival", Apollo.GetString("ContextMenu_AddRival"))
		end

		if bIsNeighbor then
			self:HelperBuildRegularButton(wndSocialListItems, "BtnUnneighbor", Apollo.GetString("ContextMenu_RemoveNeighbor"))
		elseif not bBaseCrossFaction then
			self:HelperBuildRegularButton(wndSocialListItems, "BtnAddNeighbor", Apollo.GetString("ContextMenu_AddNeighbor"))
		end

		if bIsFriend and not bIsAccountFriend then
			self:HelperBuildRegularButton(wndSocialListItems, "BtnAccountFriend", Apollo.GetString("ContextMenu_PromoteFriend"))
		end

		if bIsAccountFriend then
			self:HelperBuildRegularButton(wndSocialListItems, "BtnUnaccountFriend", Apollo.GetString("ContextMenu_UnaccountFriend"))
			self.tAccountFriend = tCharacterData.tAccountFriend
		end
		
		if tCharacterData and tCharacterData.tFriend and tCharacterData.tFriend.bIgnore then
			self:HelperBuildRegularButton(wndSocialListItems, "BtnUnignore", Apollo.GetString("ContextMenu_Unignore"))
		else
			self:HelperBuildRegularButton(wndSocialListItems, "BtnIgnore", Apollo.GetString("ContextMenu_Ignore"))
		end

        if HousingLib.IsHousingWorld() then
	        self:HelperBuildRegularButton(wndSocialListItems, "BtnVisitPlayer", Apollo.GetString("CRB_Visit"))
	    end
	end

	-----------------------------------------------------------------------------------------------
	-- Group Lists
	-----------------------------------------------------------------------------------------------

	if bInGroup and unitTarget ~= unitPlayer then
		local btnGroupList = self:FactoryProduce(wndButtonList, "BtnGroupList", "BtnGroupList")
		local wndGroupListItems = btnGroupList:FindChild("GroupPopoutItems")
		btnGroupList:AttachWindow(btnGroupList:FindChild("GroupPopoutFrame"))

		-- see if tMygroupData is currently mentoring tTargetGroupData
		if tTargetGroupData then
			local bTargetingMentor = tTargetGroupData.nMenteeIdx == tMyGroupData.nMemberIdx
			local bTargetingMentee = tMyGroupData.nMenteeIdx == tTargetGroupData.nMemberIdx

			if tTargetGroupData.bIsOnline and not bTargetingMentee and tTargetGroupData.nLevel < tMyGroupData.nLevel then
				self:HelperBuildRegularButton(wndGroupListItems, "BtnMentor", Apollo.GetString("ContextMenu_Mentor"))
			end

			if (tMyGroupData.bIsMentoring and bTargetingMentee) or (tMyGroupData.bIsMentored and bTargetingMentor) then
				self:HelperBuildRegularButton(wndGroupListItems, "BtnStopMentor", Apollo.GetString("ContextMenu_StopMentor"))
			end
			
			if unitTarget then
				self:HelperBuildRegularButton(wndButtonList, "BtnLocate", Apollo.GetString("ContextMenu_Locate"))
			end 
			
			if bAmIGroupLeader then
				self:HelperBuildRegularButton(wndGroupListItems, "BtnPromote", Apollo.GetString("ContextMenu_Promote"))
			end

			if tMyGroupData.bCanKick then
				self:HelperBuildRegularButton(wndGroupListItems, "BtnKick", Apollo.GetString("ContextMenu_Kick"))
			end

			local bInMatchingGame = MatchingGameLib.IsInGameInstance()
			local bIsMatchingGameFinished = MatchingGameLib.IsFinished()

			if bInMatchingGame and not bIsMatchingGameFinished then
				local wndCurr = self:HelperBuildRegularButton(wndGroupListItems, "BtnVoteToKick", Apollo.GetString("ContextMenu_VoteToKick"))
				self:HelperEnableDisableRegularButton(wndCurr, not MatchingGameLib.IsVoteKickActive(), "")
			end

			if bInMatchingGame and not bIsMatchingGameFinished then
				local tMatchState = MatchingGameLib.GetPvpMatchState()
				if not tMatchState or tMatchState.eRules ~= MatchingGameLib.Rules.DeathmatchPool then
					local wndCurr = self:HelperBuildRegularButton(wndGroupListItems, "BtnVoteToDisband", Apollo.GetString("ContextMenu_VoteToDisband"))
					self:HelperEnableDisableRegularButton(wndCurr, not MatchingGameLib.IsVoteSurrenderActive(), "")
				end
			end

			if bAmIGroupLeader then
				if tTargetGroupData.bCanKick then
					self:HelperBuildRegularButton(wndGroupListItems, "BtnGroupTakeKick", Apollo.GetString("ContextMenu_DenyKicks"))
				else
					self:HelperBuildRegularButton(wndGroupListItems, "BtnGroupGiveKick", Apollo.GetString("ContextMenu_AllowKicks"))
				end

				if tTargetGroupData.bCanInvite then
					self:HelperBuildRegularButton(wndGroupListItems, "BtnGroupTakeInvite", Apollo.GetString("ContextMenu_DenyInvites"))
				else
					self:HelperBuildRegularButton(wndGroupListItems, "BtnGroupGiveInvite", Apollo.GetString("ContextMenu_AllowInvites"))
				end

				if tTargetGroupData.bCanMark then
					self:HelperBuildRegularButton(wndGroupListItems, "BtnGroupTakeMark", Apollo.GetString("ContextMenu_DenyMarking"))
				else
					self:HelperBuildRegularButton(wndGroupListItems, "BtnGroupGiveMark", Apollo.GetString("ContextMenu_AllowMarking"))
				end
			end
		end

		if not tTargetGroupData and tMyGroupData.bCanInvite and not bCrossFaction then
			self:HelperBuildRegularButton(wndGroupListItems, "BtnInvite", Apollo.GetString("ContextMenu_Invite"))
		end
		
		if not tTargetGroupData and not bCrossFaction then
			self:HelperBuildRegularButton(wndGroupListItems, "BtnJoin", Apollo.GetString("CRB_Join_Group"))
		end	

		if #btnGroupList:FindChild("GroupPopoutItems"):GetChildren() == 0 then
			btnGroupList:Destroy()
		end
	end

	if bInGroup and unitTarget == unitPlayer then
		self:HelperBuildRegularButton(wndButtonList, "BtnLeaveGroup", Apollo.GetString("ContextMenu_LeaveGroup"))
	end
	
	-----------------------------------------------------------------------------------------------
	-- Guild Options
	-----------------------------------------------------------------------------------------------
	local tMyRankPermissions = self.guildCurr and self.guildCurr:GetRanks()[self.guildCurr:GetMyRank()] or nil
	local bTargetIsUnderMyRank = self.guildCurr and self.guildCurr:GetMyRank() < self.tPlayerGuildData.nRank
	if self.tPlayerGuildData and self.guildCurr ~= nil and tMyRankPermissions.bChangeMemberRank and bTargetIsUnderMyRank then
		local btnGuildList = self:FactoryProduce(wndButtonList, "BtnGuildList", "BtnGuildList")
		local wndGuildListItems = btnGuildList:FindChild("GuildListPopoutItems")
		btnGuildList:AttachWindow(btnGuildList:FindChild("GuildListPopoutFrame"))
	
			if self.guildCurr then
				--[[if tMyRankPermissions.bKick then
				self:HelperBuildRegularButton(wndGuildListItems, "BtnKickFromGuild", Apollo.GetString("ContextMenu_KickFromGuild"))
				end]]--
				
				if bTargetIsUnderMyRank and self.tPlayerGuildData.nRank ~= 2 then
					self:HelperBuildRegularButton(wndGuildListItems, "BtnPromoteInGuild", Apollo.GetString("ContextMenu_Promote_Rank"))
				end
				
				if bTargetIsUnderMyRank and self.tPlayerGuildData.nRank ~= 10 then
					self:HelperBuildRegularButton(wndGuildListItems, "BtnDemoteInGuild", Apollo.GetString("ContextMenu_Demote_Rank"))
				end	
			end
			
			if bTargetIsUnderMyRank and self.tPlayerGuildData.nRank ~= 10 then
				self:HelperBuildRegularButton(wndGuildListItems, "BtnDemoteInGuild", Apollo.GetString("ContextMenu_Demote_Rank"))
			end	
		end
	
	
	self:ResizeAndRedraw()
end

function ContextMenuPlayer:ResizeAndRedraw()
	local wndButtonList = self.wndMain:FindChild("ButtonList")
	if next(wndButtonList:GetChildren()) == nil then
		self.wndMain:Destroy()
		self.wndMain = nil
		return
	end

	if not self.bSortedAndSized then
		self.bSortedAndSized = true
		local nHeight = wndButtonList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return (ktSortOrder[a:GetData()] or 0) > (ktSortOrder[b:GetData()] or 0) end)
		local nMainLeft, nMainTop, nMainRight, nMainBottom = self.wndMain:FindChild("ContextMenuPlayerContainer"):GetAnchorOffsets()
		
		self.wndMain:FindChild("ContextMenuPlayerContainer"):SetAnchorOffsets(nMainLeft, nMainTop, nMainRight, nMainTop + nHeight + 60)

		-- Other lists
		local nOtherLeft = 0
		local nOtherTop = 0
		local nOtherRight = 0
		local nOtherBottom = 0
		local nOtherHeight = 0
				
		if self.wndMain:FindChild("GroupPopoutItems") then
			nOtherHeight = self.wndMain:FindChild("GroupPopoutItems"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
			nOtherLeft, nOtherTop, nOtherRight, nOtherBottom = self.wndMain:FindChild("GroupPopoutFrame"):GetAnchorOffsets()
			self.wndMain:FindChild("GroupPopoutFrame"):SetAnchorOffsets(nOtherLeft, nOtherTop, nOtherRight, nOtherTop + nOtherHeight + 60)
		end
		if self.wndMain:FindChild("SocialListPopoutItems") then
			nOtherHeight = self.wndMain:FindChild("SocialListPopoutItems"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
			nOtherLeft, nOtherTop, nOtherRight, nOtherBottom = self.wndMain:FindChild("SocialListPopoutFrame"):GetAnchorOffsets()
			self.wndMain:FindChild("SocialListPopoutFrame"):SetAnchorOffsets(nOtherLeft, nOtherTop, nOtherRight, nOtherTop + nOtherHeight + 60)
		end
		if self.wndMain:FindChild("GuildListPopoutItems") then
			nOtherHeight = self.wndMain:FindChild("GuildListPopoutItems"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
			nOtherLeft, nOtherTop, nOtherRight, nOtherBottom = self.wndMain:FindChild("GuildListPopoutFrame"):GetAnchorOffsets()
			self.wndMain:FindChild("GuildListPopoutFrame"):SetAnchorOffsets(nOtherLeft, nOtherTop, nOtherRight, nOtherTop + nOtherHeight + 60)
		end
		if self.wndMain:FindChild("MarkerListPopoutItems") then
			self.wndMain:FindChild("MarkerListPopoutItems"):ArrangeChildrenTiles(Window.CodeEnumArrangeOrigin.LeftOrTop)
		end

		-- Set anchors on the container to include both windows
		local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()		
		self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight + nOtherRight, nTop + nHeight + nOtherHeight + 60)
		
	end

	self:CheckWindowBounds()
end

function ContextMenuPlayer:CheckWindowBounds()
	local tMouse = Apollo.GetMouse()

	local nWidth =  self.wndMain:GetWidth()
	local nHeight = self.wndMain:GetHeight()

	local tDisplay = Apollo.GetDisplaySize()
	local nNewX = nWidth + tMouse.x - knXCursorOffset
	local nNewY = nHeight + tMouse.y - knYCursorOffset

	local bSafeX = true
	local bSafeY = true
	if tDisplay and tDisplay.nWidth and tDisplay.nHeight then
		if nNewX > tDisplay.nWidth then
			bSafeX = false
		end

		if nNewY > tDisplay.nHeight then
			bSafeY = false
		end

		local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
		if bSafeX == false then
			local nRightOffset = nNewX - tDisplay.nWidth 
			nLeft = nLeft - nRightOffset
			nRight = nRight - nRightOffset
		end

		if bSafeY == false then
			nBottom = nTop
			nTop = nTop - self.wndMain:FindChild("ContextMenuPlayerContainer"):GetHeight()
		end

		if bSafeX == false or bSafeY == false then
			self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Interaction Events
-----------------------------------------------------------------------------------------------

function ContextMenuPlayer:ProcessContextClick(eButtonType)
	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	local unitPlayer = GameLib.GetPlayerUnit()
	local strTarget = self.strTarget ~= nil and self.strTarget or ""
	local unitTarget = self.unitTarget
	local tCharacterData = GameLib.SearchRelationshipStatusByCharacterName(strTarget)
	local nGroupMemberId = (tCharacterData and tCharacterData.nPartyIndex) or nil
	local bIsAccountFriend = tCharacterData.tAccountFriend ~= nil	and tCharacterData.tAccountFriend.arCharacters ~= nil and tCharacterData.tAccountFriend.arCharacters[1] ~= nil

	if unitTarget == nil and nGroupMemberId ~= nil then
		unitTarget = GroupLib.GetUnitForGroupMember(nGroupMemberId)
	end

	if eButtonType == "BtnWhisper" then
		Event_FireGenericEvent("GenericEvent_ChatLogWhisper", strTarget)
	elseif eButtonType == "BtnAccountWhisper" then
		if bIsAccountFriend then
			local strDisplayName = tCharacterData.tAccountFriend.strCharacterName
			local strRealmName = tCharacterData.tAccountFriend.arCharacters[1].strRealm
			Event_FireGenericEvent("Event_EngageAccountWhisper", strDisplayName, strTarget, strRealmName)
		end
	elseif eButtonType == "BtnInvite" then
		if bIsAccountFriend then
			local strDisplayName = tCharacterData.tAccountFriend.arCharacters[1].strCharacterName or ""
			local strRealmName = tCharacterData.tAccountFriend.arCharacters[1].strRealm or ""
			GroupLib.Invite(strDisplayName, strRealmName)
		else
			GroupLib.Invite(strTarget)
		end
	elseif eButtonType == "BtnJoin" then
		if bIsAccountFriend then
			local strDisplayName = tCharacterData.tAccountFriend.arCharacters[1].strCharacterName or ""
			local strRealmName = tCharacterData.tAccountFriend.arCharacters[1].strRealm or ""
			GroupLib.Join(strDisplayName, strRealmName)
		else
			GroupLib.Join(strTarget)
		end	
	elseif eButtonType == "BtnPetDismiss" and unitTarget then
		--Do nothing, action bar will dismiss pet!
	elseif eButtonType == "BtnSetFocus" and unitTarget then
		unitPlayer:SetAlternateTarget(unitTarget)
	elseif eButtonType == "BtnClearFocus" then
		unitPlayer:SetAlternateTarget(nil)
	elseif eButtonType == "BtnInspect" and unitTarget then
		unitTarget:Inspect()
	elseif eButtonType == "BtnAssist" and unitTarget then
		GameLib.SetTargetUnit(unitTarget:GetTarget())
	elseif eButtonType == "BtnDuel" and unitTarget then
		GameLib.InitiateDuel(unitTarget)
	elseif eButtonType == "BtnForfeit" and unitTarget then
		GameLib.ForfeitDuel(unitTarget)
	elseif eButtonType == "BtnLeaveGroup" then
		GroupLib.LeaveGroup()
	elseif eButtonType == "BtnKick" then
		GroupLib.Kick(nGroupMemberId)
	elseif eButtonType == "BtnPromote" then
		GroupLib.Promote(nGroupMemberId, "")
	elseif eButtonType == "BtnGroupGiveMark" then
		GroupLib.SetCanMark(nGroupMemberId, true)
	elseif eButtonType == "BtnGroupTakeMark" then
		GroupLib.SetCanMark(nGroupMemberId, false)
	elseif eButtonType == "BtnGroupGiveKick" then
		GroupLib.SetKickPermission(nGroupMemberId, true)
	elseif eButtonType == "BtnGroupTakeKick" then
		GroupLib.SetKickPermission(nGroupMemberId, false)
	elseif eButtonType == "BtnGroupGiveInvite" then
		GroupLib.SetInvitePermission(nGroupMemberId, true)
	elseif eButtonType == "BtnGroupTakeInvite" then
		GroupLib.SetInvitePermission(nGroupMemberId, false)
	elseif eButtonType == "BtnLocate" and unitTarget then
		unitTarget:ShowHintArrow()
	elseif eButtonType == "BtnAddRival" then
		FriendshipLib.AddByName(FriendshipLib.CharacterFriendshipType_Rival, strTarget)
		--Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("Social_AddedToRivals"), strTarget))
	elseif eButtonType == "BtnIgnore" then
		FriendshipLib.AddByName(FriendshipLib.CharacterFriendshipType_Ignore, strTarget)
	elseif eButtonType == "BtnAddFriend" then
		FriendshipLib.AddByName(FriendshipLib.CharacterFriendshipType_Friend, strTarget)
	elseif eButtonType == "BtnUnrival" then
		FriendshipLib.Remove(tCharacterData.tFriend.nId, FriendshipLib.CharacterFriendshipType_Rival)
	elseif eButtonType == "BtnPromoteInGuild" and strTarget ~= "" then
		self.guildCurr:Promote(strTarget) -- TODO: More error checking	
	elseif eButtonType == "BtnDemoteInGuild" and strTarget ~= "" then
		self.guildCurr:Demote(strTarget)
	elseif eButtonType == "BtnKickFromGuild" and strTarget ~= "" then
		self.guildCurr:Kick(strTarget)
	elseif eButtonType == "BtnUnfriend" then
		FriendshipLib.Remove(tCharacterData.tFriend.nId, FriendshipLib.CharacterFriendshipType_Friend)
		--Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("Social_RemovedFromFriends"), strTarget))
	elseif eButtonType == "BtnUnignore" then
		FriendshipLib.Remove(tCharacterData.tFriend.nId, FriendshipLib.CharacterFriendshipType_Ignore)
		--Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("Social_RemovedFromIgnore"), strTarget))
	elseif eButtonType == "BtnAddNeighbor" then
		HousingLib.NeighborInviteByName(strTarget)
		Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("Social_AddedToNeighbors"), strTarget))
	elseif eButtonType == "BtnUnneighbor" then
		HousingLib.NeighborEvict(tCharacterData.tNeighbor.nId)
		Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("ContextMenu_NeighborRemove")))
	elseif eButtonType == "BtnVisitPlayer" and strTarget ~= "" then
        HousingLib.RequestVisitPlayer(strTarget)
	elseif eButtonType == "BtnAccountFriend" then
		FriendshipLib.AccountAddByUpgrade(tCharacterData.tFriend.nId)
	elseif eButtonType == "BtnUnaccountFriend" then
		if self.tAccountFriend and self.tAccountFriend.nId then
			Event_FireGenericEvent("EventGeneric_ConfirmRemoveAccountFriend", self.tAccountFriend.nId)
		end
	elseif eButtonType == "BtnTrade" and unitTarget then
		local eCanTradeResult = P2PTrading.CanInitiateTrade(unitTarget)
		if eCanTradeResult == P2PTrading.P2PTradeError_Ok then
			Event_FireGenericEvent("P2PTradeWithTarget", unitTarget)
		elseif eCanTradeResult == P2PTrading.P2PTradeError_TargetRangeMax then
			Event_FireGenericEvent("GenericFloater", unitPlayer, Apollo.GetString("ContextMenu_PlayerOutOfRange"))
			unitTarget:ShowHintArrow()
		else
			Event_FireGenericEvent("GenericFloater", unitPlayer, Apollo.GetString("ContextMenu_TradeFailed"))
		end
	elseif eButtonType == "BtnMarkTarget" and unitTarget then
		local nResult = 8
		local nCurrent = unitTarget:GetTargetMarker() or 0
		local tAvailableMarkers = GameLib.GetAvailableTargetMarkers()
		for idx = nCurrent, 8 do
			if tAvailableMarkers[idx] then
				nResult = idx
				break
			end
		end
		unitTarget:SetTargetMarker(nResult)
	elseif eButtonType == "BtnMarkClear" and unitTarget then
		unitTarget:ClearTargetMarker()
	elseif eButtonType == "BtnVoteToDisband" then
		MatchingGameLib.InitiateVoteToSurrender()
	elseif eButtonType == "BtnVoteToKick" then
		MatchingGameLib.InitiateVoteToKick(nGroupMemberId)
	elseif eButtonType == "BtnMentor" then
		GroupLib.AcceptMentoring(unitTarget)
	elseif eButtonType == "BtnStopMentor" then
		GroupLib.CancelMentoring()
	elseif eButtonType == "BtnReportUnit" and unitTarget then
		Event_FireGenericEvent("GenericEvent_ReportPlayerUnit", unitTarget)
	elseif eButtonType == "BtnReportChat" and self.nReportId then
		Event_FireGenericEvent("GenericEvent_ReportPlayerChat", self.nReportId)
	elseif eButtonType == "BtnPvPFlag" then
		self:TogglePvpFlags()
	elseif eButtonType and string.find(eButtonType, "BtnMark") ~= 0 and unitTarget then
		unitTarget:SetTargetMarker(tonumber(string.sub(eButtonType, Apollo.StringLength("BtnMark_"))))
	end
end

function ContextMenuPlayer:OnTargetUnitChanged(unitNewTarget)
	if not unitNewTarget or not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	if not self.unitTarget or unitNewTarget ~= self.unitTarget then
		self:OnMainWindowClosed()
	end
end

function ContextMenuPlayer:OnMainWindowClosed(wndHandler, wndControl)
	if self.wndMain and self.wndMain:IsValid() then
		local wndMain = self.wndMain
		self.wndMain = nil
		wndMain:Close()
		wndMain:Destroy()
	end
end

function ContextMenuPlayer:OnRegularBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:ProcessContextClick(wndHandler:GetData())
	self:OnMainWindowClosed()
end

function ContextMenuPlayer:OnRegularBtnParent(wndHandler, wndControl)
	self:OnRegularBtn(wndHandler:GetParent(), wndControl:GetParent())
end

function ContextMenuPlayer:OnBtnCheckboxMouseDown(wndHandler, wndControl)
	for idx, wndCurr in pairs(self.wndMain:FindChild("ButtonList"):GetChildren()) do
		local wndCurrBtn = wndCurr:FindChild("BtnRegular")
		if wndCurrBtn == nil then
			wndCurrBtn = wndCurr
		end
		wndCurrBtn:SetCheck(wndHandler == wndCurr:FindChild("BtnCheckboxMouseCatcher") and not wndCurr:IsChecked())
	end
	return true
end

function ContextMenuPlayer:OnCancel(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.wndPvPQuestConfirmation:Close()
end

function ContextMenuPlayer:OnRemovePvP(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	QuestLib.AbandonAllPvPQuests()
	GameLib.TogglePvpFlags()
	self.wndPvPQuestConfirmation:Close()
end

function ContextMenuPlayer:OnClose()
	if self.wndPvPQuestConfirmation == nil or not self.wndPvPQuestConfirmation:IsValid() then
		return
	end
	
	self.wndPvPQuestConfirmation:Destroy()
	self.wndPvPQuestConfirmation = nil
end

function ContextMenuPlayer:OnNodeClick(wndHandler, wndControl, strNode, tAttributes, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	if tAttributes ~= nil and tAttributes.strLink ~= nil and tAttributes.strLink == kstrPvPQuestLinkName then
		Event_FireGenericEvent("ToggleQuestLog")
	end
end

function ContextMenuPlayer:OnBtnRegularMouseEnter(wndHandler, wndControl)
	wndHandler:GetParent():FindChild("BtnText"):SetTextColor("UI_BtnTextBlueFlyBy")
end

function ContextMenuPlayer:OnBtnRegularMouseExit(wndHandler, wndControl)
	wndHandler:GetParent():FindChild("BtnText"):SetTextColor("UI_BtnTextBlueNormal")
end

function ContextMenuPlayer:OnEventRequestResize()
	if self.wndMain and self.wndMain:IsValid() and self.wndMain:FindChild("ButtonList") then
		self.wndMain:FindChild("ButtonList"):DestroyChildren()
	end
	self.bSortedAndSized = false
	self:RedrawAll()
end

function ContextMenuPlayer:OnPremiumTierOrPlayerLevelChanged()
	local bCanTrade = self.bCanTrade
	self:UpdatePlayerRewardProperties()
	if bCanTrade ~= self.bCanTrade then
		self:RedrawAll()
	end
end

function ContextMenuPlayer:UpdatePlayerRewardProperties()
	if AccountItemLib.GetPremiumSystem() == AccountItemLib.CodeEnumPremiumSystem.VIP then
		self.bCanTrade = AccountItemLib.GetPlayerRewardProperty(AccountItemLib.CodeEnumRewardProperty.Trading).nValue ~= 0
		
		if self.bCanTrade then
			self.strTradeBtnTooltip = ""
		else
			self.strTradeBtnTooltip = String_GetWeaselString(Apollo.GetString("ContextMenuPlayer_TradeRequirements"), P2PTrading.GetMinimumTradeLevel())
		end
	else
		self.strTradeBtnTooltip = ""
	end
end

function ContextMenuPlayer:TogglePvpFlags()
	local nPvPQuestCount = QuestLib.GetActivePvPQuestCount()
	
	if nPvPQuestCount > 0 and GameLib.IsPvpFlagged() then
		if self.wndPvPQuestConfirmation == nil or not self.wndPvPQuestConfirmation:IsValid() then
			self.wndPvPQuestConfirmation = Apollo.LoadForm(self.xmlDoc, "PvPQuestConfirmation", nil, self)
			
			self.wndPvPQuestConfirmation:FindChild("RemovePvP"):SetText(String_GetWeaselString(Apollo.GetString("ContextMenuPlayer_AbandonPvPQuests"), nPvPQuestCount))
			local wndBody = self.wndPvPQuestConfirmation:FindChild("Body")
			wndBody:SetAML(string.format('<P Font="'..wndBody:GetFont()..'" TextColor="'..wndBody:GetTextColor():GetColorString()..'">%s</P>', String_GetWeaselString(Apollo.GetString("ContextMenuPlayer_YouHaveActivePvPQuests"), { strLiteral = string.format('<T TextColor="BabyPurple" strLink="%s">%s</T>', kstrPvPQuestLinkName, kstrPvPQuestLocation) })))
			
			local nBodyWidth, nBodyHeight = wndBody:SetHeightToContentHeight()
			local nOrigLeft, nOrigTop, nOrigRight, nOrigBottom = self.wndPvPQuestConfirmation:GetOriginalLocation():GetOffsets()
			self.wndPvPQuestConfirmation:SetAnchorOffsets(nOrigLeft, nOrigTop - (nBodyHeight / 2), nOrigRight, nOrigBottom + (nBodyHeight / 2))
		end
		self.wndPvPQuestConfirmation:Invoke()
	else
		GameLib.TogglePvpFlags()
	end
end

function ContextMenuPlayer:UpdatePvpFlagBtn()
	if self.wndMain == nil or not self.wndMain:IsValid() then
		return
	end
	
	local wndBtnPvPFlag = nil
	local tFlagInfo = GameLib.GetPvpFlagInfo()
	if tFlagInfo.bIsFlagged and tFlagInfo.nCooldown == 0 then
		wndBtnPvPFlag = self:HelperBuildRegularButton(self.wndMain:FindChild("ButtonList"), "BtnPvPFlag", Apollo.GetString("MatchMaker_TurnPvPOff"))
	else
		wndBtnPvPFlag = self:HelperBuildRegularButton(self.wndMain:FindChild("ButtonList"), "BtnPvPFlag", Apollo.GetString("MatchMaker_TurnPvPOn")) 
	end
	wndBtnPvPFlag:Enable(not tFlagInfo.bIsForced)
	local strColor = "UI_BtnTextBlueNormal"
	if tFlagInfo.bIsForced then
		strColor = "UI_BtnTextBlueDisabled"
	end
	wndBtnPvPFlag:FindChild("BtnText"):SetTextColor(strColor)			
end

function ContextMenuPlayer:HelperBuildPetDismissButton(wndButtonList, eButtonType, strButtonText, unitTarget)
	-- TODO 2nd argument probably shouldn't be a string, and doesn't need to be localized
	local wndCurr = self:FactoryProduce(wndButtonList, "BtnPetDismiss", eButtonType)
	wndCurr:FindChild("BtnText"):SetText(strButtonText)
	wndCurr:SetContentId(GameLib.GetPetDismissCommand(unitTarget))
	
	return wndCurr
end

function ContextMenuPlayer:HelperBuildRegularButton(wndButtonList, eButtonType, strButtonText)
	-- TODO 2nd argument probably shouldn't be a string, and doesn't need to be localized
	local wndCurr = self:FactoryProduce(wndButtonList, "BtnRegularContainer", eButtonType)
	wndCurr:FindChild("BtnText"):SetText(strButtonText)
	return wndCurr
end

function ContextMenuPlayer:HelperEnableDisableRegularButton(wndCurr, bEnable, strTooltip)
	local wndCurrBtn = wndCurr:FindChild("BtnRegular")
	if bEnable and wndCurrBtn:ContainsMouse() then
		wndCurrBtn:FindChild("BtnText"):SetTextColor("UI_BtnTextBlueFlyBy")
	elseif bEnable then
		wndCurrBtn:FindChild("BtnText"):SetTextColor("UI_BtnTextBlueNormal")
	else
		wndCurrBtn:FindChild("BtnText"):SetTextColor("UI_BtnTextBlueDisabled")
	end
	wndCurr:SetTooltip(strTooltip)
	wndCurrBtn:Enable(bEnable)
end

function ContextMenuPlayer:FactoryProduce(wndParent, strFormName, tObject)
	local wndNew = wndParent:FindChildByUserData(tObject)
	if not wndNew then
		wndNew = Apollo.LoadForm(self.xmlDoc, strFormName, wndParent, self)
		wndNew:SetData(tObject)
	end
	return wndNew
end

local ContextMenuPlayerInst = ContextMenuPlayer:new()
ContextMenuPlayerInst:Init()
