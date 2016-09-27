-----------------------------------------------------------------------------------------------
-- Client Lua Script for GuildRegistration
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Money"
require "ChallengesLib"
require "Unit"
require "GameLib"
require "GuildLib"
require "Apollo"
require "PathMission"
require "Quest"
require "Episode"
require "math"
require "string"
require "DialogSys"
require "PublicEvent"
require "PublicEventObjective"
require "CommunicatorLib"
require "Tooltip"
require "GroupLib"
require "PlayerPathLib"
require "StorefrontLib"

local GuildRegistration = {}

local kcrDefaultText = CColor.new(135/255, 135/255, 135/255, 1.0)
local kcrHighlightedText = CColor.new(0, 1.0, 1.0, 1.0)
local eProfanityFilter = GameLib.CodeEnumUserTextFilterClass.Strict

local ktstrGuildTypes =
{
	[GuildLib.GuildType_Guild]			= Apollo.GetString("Guild_GuildTypeGuild"),
	[GuildLib.GuildType_Circle]			= Apollo.GetString("Guild_GuildTypeCircle"),
	[GuildLib.GuildType_ArenaTeam_2v2]	= Apollo.GetString("Guild_GuildTypeArena"),
	[GuildLib.GuildType_ArenaTeam_3v3]	= Apollo.GetString("Guild_GuildTypeArena"),
	[GuildLib.GuildType_ArenaTeam_5v5]	= Apollo.GetString("Guild_GuildTypeArena"),
	[GuildLib.GuildType_WarParty]		= Apollo.GetString("Guild_GuildTypeWarparty"),
}

local kstrDefaultOption =
{
	Apollo.GetString("CRB_Guild_Master"),
	Apollo.GetString("CRB_Guild_Council"),
	Apollo.GetString("CRB_Guild_Member")
}

local kstrAlreadyInGuild = Apollo.GetString("GuildRegistration_AlreadyInAGuild")

function GuildRegistration:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.tWndRefs = {}

    return o
end

function GuildRegistration:Init()
    Apollo.RegisterAddon(self)
end

function GuildRegistration:OnLoad() -- TODO: Only load when needed
	self.xmlDoc = XmlDoc.CreateFromFile("GuildRegistration.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function GuildRegistration:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("GuildResultInterceptResponse",		"OnGuildResultInterceptResponse", self)
	Apollo.RegisterEventHandler("GuildRegistrarOpen",				"OnGuildRegistrationOn", self)
	Apollo.RegisterEventHandler("GuildRegistrarClose",				"OnCancel", self)
	Apollo.RegisterEventHandler("PremiumTierChanged",				"SetGuildAccess", self)
	Apollo.RegisterEventHandler("StoreLinksRefresh",				"RefreshStoreLink", self)
	
	self.timerErrorMessage = ApolloTimer.Create(3.00, false, "OnErrorMessageTimer", self)
	self.timerErrorMessage:Stop()

	self.timerSuccessMessage = ApolloTimer.Create(3.00, false, "OnSuccessfulMessageTimer", self)
	self.timerSuccessMessage:Stop()

	self.timerForcedRename = ApolloTimer.Create(5.50, false, "OnGuildRegistration_CheckForcedRename", self)
	self.timerForcedRename:Start() -- Check for Forced Renames
end

function GuildRegistration:Initialize()
	local wndMain = Apollo.LoadForm(self.xmlDoc, "GuildRegistrationForm", nil, self)
	wndMain:Invoke()
    self.tWndRefs.wndMain = wndMain
	self.tWndRefs.wndGuildName = wndMain:FindChild("GuildNameString")
	self.tWndRefs.wndRegisterBtn = wndMain:FindChild("RegisterBtn")
	self.tWndRefs.wndAlert = wndMain:FindChild("AlertMessage")
	self.tWndRefs.wndHolomarkCostume = wndMain:FindChild("HolomarkCostume")
	self.tWndRefs.wndSelectedBackground = nil
	self.tWndRefs.wndSelectedForeground = nil

	self.tCreate =
	{
		strName 		= "",
		eGuildType 		= GuildLib.GuildType_Guild,
		strMaster 		= kstrDefaultMaster,
		strCouncil 		= kstrDefaultCouncil,
		strMember 		= kstrDefaultMember,
		tHolomark		= {},
	}

	self.arGuildOptions = {} -- the various guild settings
	for idx = 1, 3 do
		self.arGuildOptions[idx] =
		{
			wndOption = self.tWndRefs.wndMain:FindChild("OptionString_" .. idx),
			wndButton = self.tWndRefs.wndMain:FindChild("LabelRevertBtn_" .. idx)
		}
		self.arGuildOptions[idx].wndOption:SetData(idx)
		self.arGuildOptions[idx].wndButton:SetData(idx)
	end
	
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndMain, strName = Apollo.GetString("GuildRegistration_RegisterGuild")})

	self.tWndRefs.wndMain:FindChild("CreditCost"):SetMoneySystem(Money.CodeEnumCurrencyType.Credits)

	local wndIcon = self.tWndRefs.wndRegisterBtn:FindChild("Icon")
	local wndTitle = self.tWndRefs.wndRegisterBtn:FindChild("Title")

	local bHybridSystem = AccountItemLib.GetPremiumSystem() == AccountItemLib.CodeEnumPremiumSystem.Hybrid
	wndIcon:Show(bHybridSystem)

	local nIconOffset = 0
	if not bHybridSystem then
		nIconOffset = wndIcon:GetWidth()
	end

	local nLeft, nTop, nRight, nBottom = wndTitle:GetAnchorOffsets()
	wndTitle:SetAnchorOffsets(nLeft, nTop, nRight + nIconOffset, nBottom)

	self:InitializeHolomarkParts()
	self:ResetOptions()
	self:RefreshStoreLink()
end

function GuildRegistration:SetGuildAccess()
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	self.bHasFullGuildAccess = GuildLib.CanCreate(GuildLib.GuildType_Guild)
	if self.tWndRefs and self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() then
		self:UpdateOptions()
	end

	self.tWndRefs.wndRegisterBtn:Show(self.bHasFullGuildAccess or not self.bStoreLinkValid)
	self.tWndRefs.wndMain:FindChild("UnlockGuildsBtn"):Show(not self.bHasFullGuildAccess and self.bStoreLinkValid)
end

function GuildRegistration:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("GuildRegistration_RegisterGuild")})
end

function GuildRegistration:OnGuildRegistrationOn()
	-- Check to see if the player has a guild. If so, route to the designer interface.
	local guildNew = nil

	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr:GetType() == GuildLib.GuildType_Guild then
			guildNew = guildCurr
		end
	end

	if guildNew ~= nil then -- todo: permissions
		local tMyRankData = guildNew:GetRanks()[guildNew:GetMyRank()]

		if tMyRankData and tMyRankData.bEmblemAndStandard then
			Event_FireGenericEvent("Event_GuildDesignerOn")
			return
		end
	end
	
	self:Initialize()
	
	if guildNew ~= nil then
		self.tWndRefs.wndMain:FindChild("GuildPermissionsAlert"):SetText(kstrAlreadyInGuild)
	end
	self.tWndRefs.wndMain:FindChild("CreditCost"):SetAmount(GuildLib.GetCreateCost(GuildLib.GuildType_Guild))
	
	self:ResetOptions()
	self.tWndRefs.wndMain:Invoke()
end

function GuildRegistration:ResetOptions()
	for idx = 1, 3 do
		self.arGuildOptions[idx].wndOption:SetText(kstrDefaultOption[idx])
	end

	self.tCreate.strName = ""
	self.tCreate.strMaster = kstrDefaultMaster
	self.tCreate.strCouncil = kstrDefaultCouncil
	self.tCreate.strMember = kstrDefaultMember

	self.tWndRefs.wndAlert:Show(false)
	self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetText("")
	self.tWndRefs.wndAlert:FindChild("MessageBodyText"):SetText("")
	self.tWndRefs.wndGuildName:SetText("")
	self:SetDefaultHolomark()
	self:HelperClearFocus()
	self:UpdateOptions()
end

function GuildRegistration:OnNameChanging(wndHandler, wndControl)
	self.tCreate.strName = self.tWndRefs.wndGuildName:GetText()
	self:UpdateOptions()
end

function GuildRegistration:OnOptionChanging(wndHandler, wndControl)
	local nRank = wndControl:GetData()

	if nRank == 1 then
		self.tCreate.strMaster = wndControl:GetText()
	elseif nRank == 2 then
		self.tCreate.strCouncil = wndControl:GetText()
	else
		self.tCreate.strMember = wndControl:GetText()
	end

	self:UpdateOptions()
end

function GuildRegistration:UpdateOptions()
	--see which fields need undo buttons
	local guildUpdated = nil
	local bNotInGuild = true

	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr:GetType() == GuildLib.GuildType_Guild then
			guildUpdated = guildCurr
		end
	end

	if guildUpdated ~= nil then -- in a guild
		self.tWndRefs.wndMain:FindChild("GuildPermissionsAlert"):SetText(kstrAlreadyInGuild)
		bNotInGuild = false
	else
		self.tWndRefs.wndMain:FindChild("GuildPermissionsAlert"):SetText("")
	end

	for idx = 1, 3 do
		if self.arGuildOptions[idx].wndOption:GetText() ~= kstrDefaultOption[idx] then
			self.arGuildOptions[idx].wndButton:Enable(true)
		else
			self.arGuildOptions[idx].wndButton:Enable(false)
		end
	end

	self.tWndRefs.wndMain:FindChild("CreditCost"):SetAmount(GuildLib.GetCreateCost(GuildLib.GuildType_Guild))

	--see if the Guild can be submitted
	local bHasName = self:HelperCheckForEmptyString(self.tWndRefs.wndGuildName:GetText())
	local bHasMaster = self:HelperCheckForEmptyString(self.arGuildOptions[1].wndOption:GetText())
	local bHasCouncil = self:HelperCheckForEmptyString(self.arGuildOptions[2].wndOption:GetText())
	local bHasMember = self:HelperCheckForEmptyString(self.arGuildOptions[3].wndOption:GetText())
	local bHasValidLevel = (GameLib.GetPlayerLevel() or 1) >= GuildLib.GetMinimumLevel(self.tCreate.eGuildType)

	local bNameValid = GameLib.IsTextValid(self.tWndRefs.wndGuildName:GetText(), GameLib.CodeEnumUserText.GuildName, eProfanityFilter)
	local bMasterValid = GameLib.IsTextValid(self.arGuildOptions[1].wndOption:GetText(), GameLib.CodeEnumUserText.GuildRankName, eProfanityFilter)
	local bCouncilValid = GameLib.IsTextValid(self.arGuildOptions[2].wndOption:GetText(), GameLib.CodeEnumUserText.GuildRankName, eProfanityFilter)
	local bMemberValid = GameLib.IsTextValid(self.arGuildOptions[3].wndOption:GetText(), GameLib.CodeEnumUserText.GuildRankName, eProfanityFilter)
	self.tWndRefs.wndMain:FindChild("NameValidAlert"):Show(bHasName and not bNameValid)
	self.tWndRefs.wndMain:FindChild("MasterRankValidAlert"):Show(bHasMaster and not bMasterValid)
	self.tWndRefs.wndMain:FindChild("CouncilRankValidAlert"):Show(bHasCouncil and not bCouncilValid)
	self.tWndRefs.wndMain:FindChild("MemberRankValidAlert"):Show(bHasMember and not bMemberValid)

	local wndTitle = self.tWndRefs.wndRegisterBtn:FindChild("Title")
	local wndIcon =self.tWndRefs.wndRegisterBtn:FindChild("Icon")

	local bCreateGuild = bNameValid and bMasterValid and bCouncilValid and bMemberValid and bHasName and bHasMaster and bHasCouncil and bHasMember and bNotInGuild and bHasValidLevel and self.bHasFullGuildAccess
	local strColor = "UI_BtnTextGreenDisabled"
	local nOpacity = .25
	if bCreateGuild then
		strColor = "UI_BtnTextGreenNormal"
		nOpacity = 1
	end

	self.tWndRefs.wndRegisterBtn:Enable(bCreateGuild)
	wndIcon:SetOpacity(nOpacity)
	wndTitle:SetTextColor(strColor)

	if not bHasValidLevel then
		self.tWndRefs.wndMain:FindChild("GuildPermissionsAlert"):SetText(Apollo.GetString("GuildRegistration_MustBeLvl12"))
	end
end

function GuildRegistration:HelperCheckForEmptyString(strText) -- make sure there's a valid string
	local strFirstChar
	local bHasText = false

	strFirstChar = string.find(strText, "%S")

	bHasText = strFirstChar ~= nil and Apollo.StringLength(strFirstChar) > 0
	return bHasText
end

function GuildRegistration:HelperClearFocus(wndHandler, wndControl)
	for idx = 1, 3 do
		self.arGuildOptions[idx].wndOption:ClearFocus()
	end

	self.tWndRefs.wndGuildName:ClearFocus()
end

-- Guild Holomark Functions Below
function GuildRegistration:SetDefaultHolomark()

	self.tCreate.tHolomark =
	{
		tBackgroundIcon =
		{
			idPart = 4,
			idColor1 = 0,
			idColor2 = 0,
			idColor3 = 0,
		},

		tForegroundIcon =
		{
			idPart = 5,
			idColor1 = 0,
			idColor2 = 0,
			idColor3 = 0,
		},

		tScanLines =
		{
			idPart = 6,
			idColor1 = 0,
			idColor2 = 0,
			idColor3 = 0,
		},
	}

	local tHolomarkPartNames = { "tBackgroundIcon", "tForegroundIcon", "tScanLines" }

	local wndHolomarkBackgroundBtn = self.tWndRefs.wndMain:FindChild("HolomarkContent:HolomarkBackgroundOption")
	local wndHolomarkForegroundBtn = self.tWndRefs.wndMain:FindChild("HolomarkContent:HolomarkForegroundOption")
	local wndHolomarkBackgroundList = wndHolomarkBackgroundBtn:FindChild("HolomarkBackgroundPartWindow:HolomarkPartList")
	local wndHolomarkForegroundList = wndHolomarkForegroundBtn:FindChild("HolomarkForegroundPartWindow:HolomarkPartList")

	wndHolomarkBackgroundBtn:SetText(self.tHolomarkParts.tBackgroundIcons[1].strName)
	wndHolomarkForegroundBtn:SetText(self.tHolomarkParts.tForegroundIcons[1].strName)

	self:FakeRadio(wndHolomarkBackgroundList:GetChildren()[1]:FindChild("HolomarkPartBtn"), self.tWndRefs.wndSelectedBackground)
	self:FakeRadio(wndHolomarkForegroundList:GetChildren()[1]:FindChild("HolomarkPartBtn"), self.tWndRefs.wndSelectedForeground)

	wndHolomarkBackgroundList:SetVScrollPos(0)
	wndHolomarkForegroundList:SetVScrollPos(0)

	self.tWndRefs.wndHolomarkCostume:SetCostumeToGuildStandard(self.tCreate.tHolomark)
end

-----------------------------------------------------------------------------------------------
-- GuildRegistrationForm Functions
-----------------------------------------------------------------------------------------------
function GuildRegistration:FakeRadio(wndNewOption, wndSavedOption)
	if wndSavedOption then
		wndSavedOption:SetCheck(false)
	end

	wndSavedOption = wndNewOption
	wndSavedOption:SetCheck(true)
end

function GuildRegistration:UseDefaultTitleBtn(wndHandler, wndControl) -- reset an option to its default
	local nRank = wndControl:GetData()
	self.arGuildOptions[nRank].wndOption:SetText(kstrDefaultOption[nRank])
	self:HelperClearFocus()
	self:UpdateOptions()
end

-- when the OK button is clicked
function GuildRegistration:OnRegisterBtn(wndHandler, wndControl)
	local tGuildInfo = self.tCreate

	local arGuldResultsExpected = { GuildLib.GuildResult_Success,  GuildLib.GuildResult_AtMaxGuildCount, GuildLib.GuildResult_InvalidGuildName,
									 GuildLib.GuildResult_GuildNameUnavailable, GuildLib.GuildResult_NotEnoughRenown, GuildLib.GuildResult_NotEnoughCredits,
									 GuildLib.GuildResult_InsufficientInfluence, GuildLib.GuildResult_NotHighEnoughLevel, GuildLib.GuildResult_YouJoined,
									 GuildLib.GuildResult_YouCreated, GuildLib.GuildResult_MaxArenaTeamCount, GuildLib.GuildResult_MaxWarPartyCount,
									 GuildLib.GuildResult_AtMaxCircleCount, GuildLib.GuildResult_VendorOutOfRange }

	Event_FireGenericEvent("GuildResultInterceptRequest", tGuildInfo.eGuildType, self.tWndRefs.wndMain, arGuldResultsExpected )

	GuildLib.Create(tGuildInfo.strName, tGuildInfo.eGuildType, tGuildInfo.strMaster, tGuildInfo.strCouncil, tGuildInfo.strMember, tGuildInfo.tHolomark)
	self:HelperClearFocus()
	self.tWndRefs.wndRegisterBtn:Enable(false)
	self.tWndRefs.wndRegisterBtn:FindChild("Title"):SetTextColor(ApolloColor.new("UI_BtnTextGreenDisabled"))
	self.tWndRefs.wndRegisterBtn:FindChild("Icon"):SetOpacity(0.25)
	--NOTE: Requires a server response to progress
end

-- when the Cancel button is clicked
function GuildRegistration:OnCancel(wndHandler, wndControl)
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain:Close()
	end
end

function GuildRegistration:OnWindowClosed(wndHandler, wndControl)
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
		
		self:HelperClearFocus()
		self:ResetOptions()
		self.tWndRefs.wndMain:Destroy()
		self.tWndRefs = {}
		self.arGuildOptions = {}
		
		Event_CancelGuildRegistration()
		Event_FireGenericEvent("WindowManagementRemove", {strName = Apollo.GetString("GuildRegistration_RegisterGuild")})
	end
end

function GuildRegistration:OnGuildResultInterceptResponse(guildCurr, eGuildType, eResult, wndRegistration, strAlertMessage)
	if eGuildType ~= GuildLib.GuildType_Guild or wndRegistration ~= self.tWndRefs.wndMain then
		return
	end

	if not self.tWndRefs.wndAlert or not self.tWndRefs.wndAlert:IsValid() then
		return
	end

	if eResult == GuildLib.GuildResult_Success or eResult == GuildLib.GuildResult_YouCreated or eResult == GuildLib.GuildResult_YouJoined then
		self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("GuildRegistration_Success"))
		self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetTextColor(ApolloColor.new("UI_TextHoloTitle"))

		self.timerSuccessMessage:Start()
	else
		self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("GuildRegistration_Whoops"))
		self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetTextColor(ApolloColor.new("LightOrange"))

		self.timerErrorMessage:Start()
	end
	self.tWndRefs.wndAlert:FindChild("MessageBodyText"):SetText(strAlertMessage)
	self.tWndRefs.wndAlert:Show(true)
end

function GuildRegistration:OnSuccessfulMessageTimer()
	self:OnCancel()
end


function GuildRegistration:OnErrorMessageTimer()
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndAlert:Show(false)

		if self.bHasFullGuildAccess then -- safe to assume since it was clicked once, except they need to have access
			self.tWndRefs.wndRegisterBtn:Enable(true) 
			self.tWndRefs.wndRegisterBtn:FindChild("Title"):SetTextColor(ApolloColor.new("UI_BtnTextGreenNormal"))
			self.tWndRefs.wndRegisterBtn:FindChild("Icon"):SetOpacity(1)
		else
			self.tWndRefs.wndRegisterBtn:FindChild("Title"):SetTextColor(ApolloColor.new("UI_BtnTextGreenDisabled"))
			self.tWndRefs.wndRegisterBtn:FindChild("Icon"):SetOpacity(0.25)
		end
	end
end

function GuildRegistration:OnPlayerCurrencyChanged()
end

-----------------------------------------------------------------------------------------------
-- Holomark Functions
-----------------------------------------------------------------------------------------------
function GuildRegistration:InitializeHolomarkParts()

	self.tHolomarkPartListItems = {}
	self.wndHolomarkOption = nil
	self.wndHolomarkOptionWindow = nil

	self.tHolomarkParts =
	{
		tBackgroundIcons = GuildLib.GetBannerBackgroundIcons(),
		tForegroundIcons = GuildLib.GetBannerForegroundIcons()
	}

	self.tWndRefs.wndMain:FindChild("HolomarkBackgroundOption"):SetText(self.tHolomarkParts.tBackgroundIcons[1].strName)
	self.tWndRefs.wndMain:FindChild("HolomarkForegroundOption"):SetText(self.tHolomarkParts.tForegroundIcons[1].strName)

	self:FillHolomarkPartList("Background")
	self:FillHolomarkPartList("Foreground")
end

function GuildRegistration:OnHolomarkPartCheck1( wndHandler, wndControl, eMouseButton )
	self.wndHolomarkOption = self.tWndRefs.wndMain:FindChild("HolomarkBackgroundOption")
	self.wndHolomarkOptionWindow = self.tWndRefs.wndMain:FindChild("HolomarkBackgroundPartWindow")
	self.wndHolomarkOptionWindow:SetData(1)
	self.wndHolomarkOptionWindow:Show(true)
end

function GuildRegistration:OnHolomarkPartUncheck1( wndHandler, wndControl, eMouseButton )
	self.tWndRefs.wndMain:FindChild("HolomarkBackgroundPartWindow"):Show(false)
end

function GuildRegistration:OnHolomarkPartCheck2( wndHandler, wndControl, eMouseButton )
	self.wndHolomarkOption = self.tWndRefs.wndMain:FindChild("HolomarkForegroundOption")
	self.wndHolomarkOptionWindow = self.tWndRefs.wndMain:FindChild("HolomarkForegroundPartWindow")
	self.wndHolomarkOptionWindow:SetData(2)
	self.wndHolomarkOptionWindow:Show(true)
end

function GuildRegistration:OnHolomarkPartUncheck2( wndHandler, wndControl, eMouseButton )
	self.tWndRefs.wndMain:FindChild("HolomarkForegroundPartWindow"):Show(false)
end

function GuildRegistration:FillHolomarkPartList( strPartType )
	local wndList = nil
	local tPartList = nil

	if strPartType == "Background" then
		wndList = self.tWndRefs.wndMain:FindChild("HolomarkContent:HolomarkBackgroundOption:HolomarkBackgroundPartWindow:HolomarkPartList")
		tPartList = self.tHolomarkParts.tBackgroundIcons
	elseif strPartType == "Foreground" then
		wndList = self.tWndRefs.wndMain:FindChild("HolomarkContent:HolomarkForegroundOption:HolomarkForegroundPartWindow:HolomarkPartList")
		tPartList = self.tHolomarkParts.tForegroundIcons
	end

	wndList:DestroyChildren()

	if tPartList == nil then
		return
	end

	for idx = 1, #tPartList do
		self:AddHolomarkPartItem(wndList, idx, tPartList[idx])
	end

	local wndDefault = wndList:GetChildren()[1]:FindChild("HolomarkPartBtn")
	if strPartType == "Background" and not self.tWndRefs.wndSelectedBackground then
		self:FakeRadio(wndDefault, self.tWndRefs.wndSelectedBackground)
	elseif strPartType == "Foreground" and not self.tWndRefs.wndSelectedForeground then
		self:FakeRadio(wndDefault, self.tWndRefs.wndSelectedForeground)
	end
end

function GuildRegistration:AddHolomarkPartItem(wndList, index, tPart)
	-- load the window item for the list item
	local wnd = Apollo.LoadForm(self.xmlDoc, "HolomarkPartListItem", wndList, self)

	self.tHolomarkPartListItems[index] = wnd

	local wndItemBtn = wnd:FindChild("HolomarkPartBtn")
	if wndItemBtn then -- make sure the text wnd exist
	    local strName = tPart.strName
		wndItemBtn:SetText(strName)
		wndItemBtn:SetData(tPart)
	end
	wndList:ArrangeChildrenVert()
end

function GuildRegistration:OnHolomarkPartSelectionClosed( wndHandler, wndControl )
	-- destroy all the wnd inside the list

	self.wndHolomarkOptionWindow:Show(false)
	self.wndHolomarkOptionWindow:GetParent():SetCheck(false)

	-- clear the list item array
	self.tHolomarkPartListItems = {}
	self.wndHolomarkOption = nil
	self.wndHolomarkOptionWindow = nil
end

function GuildRegistration:OnHolomarkPartItemSelected(wndHandler, wndControl)
	if not wndControl then
        return
    end

	local tPart = wndControl:GetData()
    if tPart ~= nil and self.wndHolomarkOption ~= nil then
		self.wndHolomarkOption:SetText(tPart.strName)

		local eType = self.wndHolomarkOptionWindow:GetData()
		if eType == 1 then
			self.tCreate.tHolomark.tBackgroundIcon.idPart = tPart.idBannerPart
			self:FakeRadio(wndHandler, self.tWndRefs.wndSelectedBackground)
		elseif eType == 2 then
			self.tCreate.tHolomark.tForegroundIcon.idPart = tPart.idBannerPart
			self:FakeRadio(wndHandler, self.tWndRefs.wndSelectedForeground)
		end

		self.tWndRefs.wndHolomarkCostume:SetCostumeToGuildStandard(self.tCreate.tHolomark)
	end

	self:UpdateOptions()

	self:OnHolomarkPartSelectionClosed(wndHandler, wndControl)
end

-----------------------------------------------------------------------------------------------
-- Forced Rename Code
-----------------------------------------------------------------------------------------------
function GuildRegistration:OnGuildRegistration_CheckForcedRename()
	for idx, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr and guildCurr:GetFlags() and guildCurr:GetFlags().bRename and guildCurr:GetMyRank() == 1 then
			local strGuildType = ktstrGuildTypes[guildCurr:GetType()]
			self.wndForcedRename = Apollo.LoadForm(self.xmlDoc, "RenameSocialAlert", nil, self)
			self.wndForcedRename:FindChild("TitleBlock"):SetText(String_GetWeaselString(Apollo.GetString("ForceRenameSocial_TitleBlock"), strGuildType, guildCurr:GetName()))
			self.wndForcedRename:FindChild("RenameEditBox"):SetMaxTextLength(GameLib.GetTextTypeMaxLength(GameLib.CodeEnumUserText.GuildName))
			self.wndForcedRename:FindChild("StatusValidAlert"):Show(true)
			self.wndForcedRename:FindChild("RenameSocialConfirm"):SetData(guildCurr)
			self.wndForcedRename:FindChild("RenameSocialConfirm"):Enable(false)
			self.wndForcedRename:Invoke()

			-- Resize
			local strRenameBodyText = String_GetWeaselString(Apollo.GetString("ForceRenameSocial_BodyBlock"), strGuildType)
			local nLeft, nTop, nRight, nBottom = self.wndForcedRename:GetAnchorOffsets()
			self.wndForcedRename:FindChild("BodyBlock"):SetAML(string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBody\">%s</T>", strRenameBodyText))
			self.wndForcedRename:FindChild("BodyBlock"):SetHeightToContentHeight()
			self.wndForcedRename:SetAnchorOffsets(nLeft, nTop, nRight, nTop + self.wndForcedRename:FindChild("BodyBlock"):GetHeight() + 310)

			-- Hack for descenders
			nLeft, nTop, nRight, nBottom = self.wndForcedRename:FindChild("BodyBlock"):GetAnchorOffsets()
			self.wndForcedRename:FindChild("BodyBlock"):SetAnchorOffsets(nLeft, nTop, nRight, nTop + self.wndForcedRename:FindChild("BodyBlock"):GetHeight() + 5)

			return -- Do them one at a time
		end
	end
end

function GuildRegistration:OnRenameSocialCancel()
	if self.wndForcedRename and self.wndForcedRename:IsValid() then
		self.wndForcedRename:Close()
		self.wndForcedRename:Destroy()
		self.wndForcedRename = nil
	end
end

function GuildRegistration:OnRenameEditBoxChanged(wndHandler, wndControl)
	local strInput = wndHandler:GetText()
	local bValid = strInput and GameLib.IsTextValid(strInput, GameLib.CodeEnumUserText.GuildName, eProfanityFilter)
	self.wndForcedRename:FindChild("RenameSocialConfirm"):Enable(bValid)
	self.wndForcedRename:FindChild("StatusValidAlert"):Show(not bValid)
end

function GuildRegistration:OnRenameSocialConfirm(wndHandler, wndControl)
	wndHandler:GetData():Rename(self.wndForcedRename:FindChild("RenameEditBox"):GetText())
	self:OnRenameSocialCancel()
	self.timerForcedRename:Start()
end

function GuildRegistration:RefreshStoreLink()
	self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.Signature)
	self:SetGuildAccess()
end

function GuildRegistration:OnUnlockGuilds()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

local GuildRegistrationInst = GuildRegistration:new()
GuildRegistrationInst:Init()
