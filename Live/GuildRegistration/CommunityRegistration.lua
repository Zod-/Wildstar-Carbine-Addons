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
	Apollo.RegisterEventHandler("CommunityRegistrarClose",		"OnClose", self)
	Apollo.RegisterEventHandler("StoreLinksRefresh",			"RefreshStoreLink", self)
	Apollo.RegisterEventHandler("GuildResultInterceptResponse", "OnGuildResultInterceptResponse", self)
	Apollo.RegisterTimerHandler("ErrorMessageTimer", 			"OnErrorMessageTimer", self)
	Apollo.RegisterTimerHandler("SuccessfulMessageTimer", 		"OnSuccessfulMessageTimer", self)
	Apollo.RegisterEventHandler("UpdateRewardProperties",		"UpdateButtons", self)
	Apollo.RegisterEventHandler("ServiceTokenClosed_Community",	"OnServiceTokenDialogClosed", self)
end

function CommunityRegistration:Initialize(wndParent)
	if self.wndMain then
		self.wndMain:Destroy()
	end

	self.wndMain 				= Apollo.LoadForm(self.xmlDoc, "CommunityRegistrationForm", wndParent, self)
	self.wndCommunityRegAlert 	= self.wndMain:FindChild("AlertMessage")
	self.wndCommunityRegName 	= self.wndMain:FindChild("CommunityRegistrationWnd"):FindChild("GuildNameString")
	self.wndRegisterCommunityBtn 	= self.wndMain:FindChild("CommunityRegistrationWnd"):FindChild("RegisterBtn")
	self.wndRegisterServiceTokenBtn = self.wndMain:FindChild("CommunityRegistrationWnd"):FindChild("RegisterServiceTokenBtn")
	self.wndUnlockCommunityBtn		= self.wndMain:FindChild("CommunityRegistrationWnd"):FindChild("UnlockBtn")

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
	if self.wndMain ~= nil and self.wndMain:IsValid() then
		self.wndMain:Close()
	end
end

function CommunityRegistration:OnWindowClosed(wndHandler, wndControl)
	if self.wndMain ~= nil and self.wndMain:IsValid() then
		Apollo.StopTimer("LeftCommunityMessageTimer")
		Apollo.StopTimer("SuccessfulMessageTimer")
		Apollo.StopTimer("ErrorMessageTimer")

		self.wndMain:Destroy()
		self.wndMain = nil
		self.wndCommunityRegAlert = nil
		self.wndCommunityRegName = nil
		self.wndRegisterCommunityBtn = nil
		self.wndRegisterServiceTokenBtn = nil
		self.tCreate = {}
			
		Event_CancelCommunityRegistration()
	end
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
	
	local monAlternateCost = GuildLib.GetAlternateCreateCost(GuildLib.GuildType_Community)
	if monAlternateCost then
		self.wndRegisterServiceTokenBtn:FindChild("ServiceTokenCost"):SetAmount(monAlternateCost)
	else
		self.wndRegisterServiceTokenBtn:Show(false)
	end
	
	self.wndRegisterCommunityBtn:FindChild("CreditCost"):SetAmount(GuildLib.GetCreateCost(GuildLib.GuildType_Community))
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
	local bCanCreate = bHasName and bNameValid and GuildLib.CanCreate(GuildLib.GuildType_Community)
	
	local bCanAfford = true
	if GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Credits):GetAmount() < GuildLib.GetCreateCost(GuildLib.GuildType_Community):GetAmount() then
		bCanAfford = false
	end
	
	self.wndRegisterCommunityBtn:Enable(bCanCreate and bCanAfford)
	
	local monAlternateCost = GuildLib.GetAlternateCreateCost(GuildLib.GuildType_Community)
	if monAlternateCost then
		local monAmountAvailable = AccountItemLib.GetAccountCurrency(monAlternateCost:GetAccountCurrencyType())
		if monAmountAvailable and monAmountAvailable:GetAmount() >= monAlternateCost:GetAmount() then
			bCanAfford = true
		else
			bCanAfford = false
		end
	end
	self.wndRegisterServiceTokenBtn:Enable(bCanCreate and bCanAfford)
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
	local arGuldResultsExpected = { GuildLib.GuildResult_Success,  GuildLib.GuildResult_AtMaxCommunityCount, GuildLib.GuildResult_InvalidGuildName, 
									 GuildLib.GuildResult_GuildNameUnavailable, GuildLib.GuildResult_NotEnoughRenown, GuildLib.GuildResult_NotEnoughCredits,
									 GuildLib.GuildResult_InsufficientInfluence, GuildLib.GuildResult_NotHighEnoughLevel, GuildLib.GuildResult_YouJoined,
									 GuildLib.GuildResult_YouCreated, GuildLib.GuildResult_MaxArenaTeamCount, GuildLib.GuildResult_MaxWarPartyCount,
									 GuildLib.GuildResult_AtMaxCircleCount, GuildLib.GuildResult_VendorOutOfRange }

	local bUseAlternateCost = wndControl == self.wndRegisterServiceTokenBtn
	
	Event_FireGenericEvent("GuildResultInterceptRequest", tGuildInfo.eGuildType, self.wndMain, arGuldResultsExpected )
	
	local monCreateCost = GuildLib.GetCreateCost(tGuildInfo.eGuildType)
	if bUseAlternateCost then
		monCreateCost = GuildLib.GetAlternateCreateCost(tGuildInfo.eGuildType)
	end
	
	local wndConfirmationOverlay = self.wndMain:FindChild("ConfirmationOverlay")
	
	local tConfirmationData =
	{
		monCost = monCreateCost,
		wndParent = wndConfirmationOverlay,
		strConfirmation = String_GetWeaselString(Apollo.GetString("Community_CreateConfirm"), tGuildInfo.strName),
		tActionData = { GameLib.CodeEnumConfirmButtonType.PurchaseCommunity, tGuildInfo.strName, bUseAlternateCost },
		strEventName = "ServiceTokenClosed_Community",
	}
	wndConfirmationOverlay:Show(true)
	Event_FireGenericEvent("GenericEvent_ServiceTokenPrompt", tConfirmationData)
	
	self:HelperClearCommunityRegFocus()
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
	
	local wndOverlay = self.wndMain:FindChild("ConfirmationOverlay")
	if wndOverlay then
		wndOverlay:Show(false)
	end
	
	self.wndCommunityRegAlert:Show(true)
	if eResult == GuildLib.GuildResult_YouCreated then
		self.wndCommunityRegAlert:FindChild("MessageBodyText"):SetText(String_GetWeaselString(Apollo.GetString("GuildResult_CommunityCreated")))
		self.wndCommunityRegAlert:FindChild("MessageAlertText"):SetTextColor(ApolloColor.new("UI_WindowTextTextPureGreen"))
		self.wndCommunityRegAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("GuildResult_Success"))
		Apollo.CreateTimer("SuccessfulMessageTimer", 10.00, false)
	elseif eResult == GuildLib.GuildResult_Success or eResult == GuildLib.GuildResult_YouJoined then
		self.wndCommunityRegAlert:FindChild("MessageBodyText"):SetText(strAlertMessage)
		self.wndCommunityRegAlert:FindChild("MessageAlertText"):SetTextColor(ApolloColor.new("UI_WindowTextTextPureGreen"))
		self.wndCommunityRegAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("GuildResult_Success"))
		Apollo.CreateTimer("SuccessfulMessageTimer", 5.00, false)
	else
		self.wndCommunityRegAlert:FindChild("MessageBodyText"):SetText(strAlertMessage)
		self.wndCommunityRegAlert:FindChild("MessageAlertText"):SetTextColor(ApolloColor.new("ConTough"))
		self.wndCommunityRegAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("Error"))
		Apollo.CreateTimer("ErrorMessageTimer", 5.00, false)
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, strAlertMessage, "")
	end
	
	local arGuldResultsExpected = { GuildLib.GuildResult_Success,  GuildLib.GuildResult_AtMaxCommunityCount, GuildLib.GuildResult_InvalidGuildName, 
									 GuildLib.GuildResult_GuildNameUnavailable, GuildLib.GuildResult_NotEnoughRenown, GuildLib.GuildResult_NotEnoughCredits,
									 GuildLib.GuildResult_InsufficientInfluence, GuildLib.GuildResult_NotHighEnoughLevel, GuildLib.GuildResult_YouJoined,
									 GuildLib.GuildResult_YouCreated, GuildLib.GuildResult_MaxArenaTeamCount, GuildLib.GuildResult_MaxWarPartyCount,
									 GuildLib.GuildResult_AtMaxCircleCount, GuildLib.GuildResult_VendorOutOfRange }
									
	Event_FireGenericEvent("GuildResultInterceptRequest", eGuildType, nil, arGuldResultsExpected )
end

function CommunityRegistration:OnServiceTokenDialogClosed(strParent)
	if not self.wndMain then
		return
	end
	
	local wndParent = self.wndMain:FindChild(strParent)
	if wndParent then
		wndParent:Show(false)
	end
end

function CommunityRegistration:OnSuccessfulMessageTimer()
	self:OnClose()
end

function CommunityRegistration:OnErrorMessageTimer()
	self:OnClose()
end

function CommunityRegistration:UpdateButtons()
	if not self.wndMain then
		return
	end
	
	local bCanCreate = GuildLib.CanCreate(GuildLib.GuildType_Community)
	
	self.wndUnlockCommunityBtn:Show(self.bStoreLinkValid and not bCanCreate)
	self.wndRegisterCommunityBtn:Show(bCanCreate or not self.bStoreLinkValid)
	self.wndRegisterServiceTokenBtn:Show(bCanCreate or not self.bStoreLinkValid)
	
	self.wndUnlockCommunityBtn:Enable(not bCanCreate)
	self.wndRegisterCommunityBtn:Enable(bCanCreate)
	self.wndRegisterServiceTokenBtn:Enable(bCanCreate)
end

function CommunityRegistration:RefreshStoreLink()
	self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.Signature)
	self:UpdateButtons()
end

function CommunityRegistration:OnUnlockCommunity()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

-----------------------------------------------------------------------------------------------
-- CommunityRegistration Instance
-----------------------------------------------------------------------------------------------
local CommunityRegistrationInst = CommunityRegistration:new()
CommunityRegistrationInst:Init()
