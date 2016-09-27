-----------------------------------------------------------------------------------------------
-- Client Lua Script for CommunityRegistration
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "StorefrontLib"

local CommunityRegistration = {}

local kcrDefaultText = CColor.new(47/255, 148/255, 172/255, 1.0)
local kcrHighlightedText = CColor.new(49/255, 252/255, 246/255, 1.0)
local eProfanityFilter = GameLib.CodeEnumUserTextFilterClass.Strict

local kstrDefaultOption =
{
	Apollo.GetString("CRB_Circle_Master"),
	Apollo.GetString("CRB_Circle_Council"),
	Apollo.GetString("Circle_SoloMember")
}

function CommunityRegistration:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function CommunityRegistration:Init()
    Apollo.RegisterAddon(self)
end

function CommunityRegistration:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CommunityRegistration.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function CommunityRegistration:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("CommunityRegistrarOpen", 		"OnCommunityRegistrarOpen", self)
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate",	"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate",		"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("StoreLinksRefresh",				"RefreshStoreLink", self)
end

function CommunityRegistration:Initialize(wndParent)
	Apollo.RegisterEventHandler("GuildResultInterceptResponse", "OnGuildResultInterceptResponse", self)
	Apollo.RegisterTimerHandler("ErrorMessageTimer", 		"OnErrorMessageTimer", self)
	Apollo.RegisterTimerHandler("SuccessfulMessageTimer", 	"OnSuccessfulMessageTimer", self)


	if self.wndMain then
		self.wndMain:Destroy()
	end

	self.wndMain 				= Apollo.LoadForm(self.xmlDoc, "CommunityRegistrationForm", wndParent, self)
	self.wndCommunityRegAlert 	= self.wndMain:FindChild("AlertMessage")
	self.wndCommunityRegName 	= self.wndMain:FindChild("CommunityRegistrationWnd"):FindChild("GuildNameString")
	self.wndRegisterCommunityBtn 	= self.wndMain:FindChild("CommunityRegistrationWnd"):FindChild("RegisterBtn")
	self.wndMain:FindChild("UnlockCommunityBtn"):SetTooltipForm(Apollo.LoadForm(self.xmlDoc, "UnlockCommunityTooltip", nil, self))

	-- TODO Refactor below, we can just look up the info when the create button is hit
	self.tCreate =
	{
		strName 		= "",
		eGuildType 		= GuildLib.GuildType_Community,
		strMaster 		= kstrDefaultMaster,
		strCouncil 		= kstrDefaultCouncil,
		strMember 		= kstrDefaultMember
	}
	
	self.wndMain:FindChild("CreditCost"):SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
	self.wndMain:FindChild("CreditCurrent"):SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
	self:RefreshStoreLink()
end

function CommunityRegistration:OnCommunityRegistrarOpen(wndParent)
	if not self.wndMain or not self.wndMain:IsValid() then
		self:Initialize(wndParent)
	end
	
	if not self.wndMain:IsShown() then
		self.wndMain:Invoke()
	end
	
	self:OnFullRedrawOfRegistration()
end

function CommunityRegistration:OnClose()
	Apollo.StopTimer("LeftCommunityMessageTimer")
	Apollo.StopTimer("SuccessfulMessageTimer")
	Apollo.StopTimer("ErrorMessageTimer")

	self.wndCommunityRegAlert:Show(false)

	self.wndMain:FindChild("CommunityRegistrationWnd"):Show(false)
end

-----------------------------------------------------------------------------------------------
-- Circle registration functions
-----------------------------------------------------------------------------------------------

function CommunityRegistration:OnFullRedrawOfRegistration()
	self.wndCommunityRegAlert:Show(false)
	self.wndCommunityRegAlert:FindChild("MessageAlertText"):SetText("")
	self.wndCommunityRegAlert:FindChild("MessageBodyText"):SetText("")
	self.wndCommunityRegName:SetText("")

	self:HelperClearCommunityRegFocus()
	self:UpdateCommunityRegOptions()
	
	self.wndMain:FindChild("CreditCost"):SetAmount(GuildLib.GetCreateCost(GuildLib.GuildType_Community))
	self.wndMain:FindChild("CreditCurrent"):SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Credits):GetAmount(), true)

	self.wndMain:FindChild("CommunityRegistrationWnd"):Show(true)
end

function CommunityRegistration:OnCommunityRegNameChanging(wndHandler, wndControl)
	local strInput = self.wndCommunityRegName:GetText() or ""
	local wndLimit = self.wndMain:FindChild("CommunityRegistrationWnd"):FindChild("RegistrationContent:Limit")
	local bIsValid = GameLib.IsTextValid(strInput, GameLib.CodeEnumUserText.GuildName, eProfanityFilter)
	self.tCreate.strName = strInput
	self:UpdateCommunityRegOptions()
		
	if wndLimit ~= nil then
		local nNameLength = Apollo.StringLength(strInput or "")

		wndLimit:SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), nNameLength, GameLib.GetTextTypeMaxLength(GameLib.CodeEnumUserText.GuildName)))

		if not bIsValid or nNameLength < 3 or nNameLength > GameLib.GetTextTypeMaxLength(GameLib.CodeEnumUserText.GuildName) then
			wndLimit:SetTextColor(ApolloColor.new("red"))
		else
			wndLimit:SetTextColor(ApolloColor.new("UI_TextHoloBodyCyan"))
		end
	end
end

function CommunityRegistration:UpdateCommunityRegOptions()
	--see if the Guild can be submitted
	local bHasName = self:HelperCheckForEmptyString(self.wndCommunityRegName:GetText())
	local bNameValid = GameLib.IsTextValid( self.wndCommunityRegName:GetText(), GameLib.CodeEnumUserText.GuildName, eProfanityFilter)
	self.wndRegisterCommunityBtn:Enable(bHasName and bNameValid and GuildLib.CanCreate(GuildLib.GuildType_Community))
end

function CommunityRegistration:HelperCheckForEmptyString(strText) -- make sure there's a valid string
	local strFirstChar = string.find(strText, "%S")
	return strFirstChar ~= nil and Apollo.StringLength(strFirstChar) > 0
end

function CommunityRegistration:HelperClearCommunityRegFocus(wndHandler, wndControl)
	self.wndCommunityRegName:ClearFocus()
end

function CommunityRegistration:OnCommunityRegBtn(wndHandler, wndControl)
	local tGuildInfo = self.tCreate -- TODO Refactor
	local arGuldResultsExpected = { GuildLib.GuildResult_Success,  GuildLib.GuildResult_AtMaxGuildCount, GuildLib.GuildResult_InvalidGuildName, 
									 GuildLib.GuildResult_GuildNameUnavailable, GuildLib.GuildResult_NotEnoughRenown, GuildLib.GuildResult_NotEnoughCredits,
									 GuildLib.GuildResult_InsufficientInfluence, GuildLib.GuildResult_NotHighEnoughLevel, GuildLib.GuildResult_YouJoined,
									 GuildLib.GuildResult_YouCreated, GuildLib.GuildResult_MaxArenaTeamCount, GuildLib.GuildResult_MaxWarPartyCount,
									 GuildLib.GuildResult_AtMaxCircleCount, GuildLib.GuildResult_VendorOutOfRange }

	Event_FireGenericEvent("GuildResultInterceptRequest", tGuildInfo.eGuildType, self.wndMain, arGuldResultsExpected )
	GuildLib.Create(tGuildInfo.strName, tGuildInfo.eGuildType, tGuildInfo.strMaster, tGuildInfo.strCouncil, tGuildInfo.strMember)

	self:HelperClearCommunityRegFocus()
	self.wndRegisterCommunityBtn:Enable(false)
	self.wndMain:FindChild("CommunityRegistrationWnd"):Show(false)
	self:OnClose()
	--need to reset info, because next time a circle is created, if the any field isn't updated, it will remain the same it was last circle
	self.tCreate =
	{
		strName 		= "",
		eGuildType 		= GuildLib.GuildType_Community,
		strMaster 		= kstrDefaultMaster,
		strCouncil 		= kstrDefaultCouncil,
		strMember 		= kstrDefaultMember
	}
end

function CommunityRegistration:OnGuildResultInterceptResponse( guildCurr, eGuildType, eResult, wndRegistration, strAlertMessage )
	if eGuildType ~= GuildLib.GuildType_Community or wndRegistration ~= self.wndMain then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strAlertMessage, "")
		return
	end

	if not self.wndCommunityRegAlert or not self.wndCommunityRegAlert:IsValid() then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strAlertMessage, "")
		return
	end

	self.wndCommunityRegAlert:FindChild("MessageBodyText"):SetText(strAlertMessage)
	self.wndCommunityRegAlert:Show(true)
	if eResult == GuildLib.GuildResult_Success or eResult == GuildLib.GuildResult_YouCreated or eResult == GuildLib.GuildResult_YouJoined then
		self.wndCommunityRegAlert:FindChild("MessageAlertText"):SetTextColor(ApolloColor.new("UI_WindowTextTextPureGreen"))
		self.wndCommunityRegAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("GuildResult_Success"))
		Apollo.CreateTimer("SuccessfulMessageTimer", 3.00, false)
	else
		self.wndCommunityRegAlert:FindChild("MessageAlertText"):SetTextColor(ApolloColor.new("ConTough"))
		self.wndCommunityRegAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("Error"))
		Apollo.CreateTimer("ErrorMessageTimer", 3.00, false)
	end
end

function CommunityRegistration:OnSuccessfulMessageTimer()
	self:OnClose()
end

function CommunityRegistration:OnErrorMessageTimer()
	self:OnClose()
end

function CommunityRegistration:OnEntitlementUpdate(tEntitlementInfo)
	if not self.wndMain then
		return
	end

	local bCanCreate = GuildLib.CanCreate(GuildLib.GuildType_Community)
	if tEntitlementInfo.nEntitlementId == AccountItemLib.CodeEnumEntitlement.Signature or tEntitlementInfo.nEntitlementId == AccountItemLib.CodeEnumEntitlement.Free or tEntitlementInfo.nEntitlementId == AccountItemLib.CodeEnumEntitlement.FullGuildsAccess then
		
		self.wndRegisterCommunityBtn:Show(bCanCreate or not self.bStoreLinkValid)
		self.wndRegisterCommunityBtn:Enable(bCanCreate)
		self.wndMain:FindChild("UnlockCommunityBtn"):Show(not bCanCreate and self.bStoreLinkValid)
	end
	local wndRegisterBtnTooltip = self.wndMain:FindChild("RegisterBtnTooltip")
	wndRegisterBtnTooltip:Show(not bCanCreate)
	if not bCanCreate then
		wndRegisterBtnTooltip:SetTooltipForm(Apollo.LoadForm(self.xmlDoc, "UnlockCommunityTooltip", nil, self))
	end
end

function CommunityRegistration:RefreshStoreLink()
	self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.Signature)
	self:OnEntitlementUpdate( { nEntitlementId = AccountItemLib.CodeEnumEntitlement.FullGuildsAccess } )
end

function CommunityRegistration:OnUnlockCommunity()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

-----------------------------------------------------------------------------------------------
-- CommunityRegistration Instance
-----------------------------------------------------------------------------------------------
local CommunityRegistrationInst = CommunityRegistration:new()
CommunityRegistrationInst:Init()
