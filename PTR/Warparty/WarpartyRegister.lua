-----------------------------------------------------------------------------------------------
-- Client Lua Script for Warparty Registration
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "GuildLib"
require "Unit"

-----------------------------------------------------------------------------------------------
-- WarpartyRegister Module Definition
-----------------------------------------------------------------------------------------------
local WarpartyRegister = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local kcrDefaultText = CColor.new(135/255, 135/255, 135/255, 1.0)
local kcrHighlightedText = CColor.new(0, 1.0, 1.0, 1.0)

local ktResultString =
{
	[GuildLib.GuildResult_Success] 				= Apollo.GetString("Warparty_ResultSuccess"),
	[GuildLib.GuildResult_AtMaxGuildCount] 		= Apollo.GetString("Warparty_OnlyOneWarparty"),
	[GuildLib.GuildResult_InvalidGuildName] 	= Apollo.GetString("Warparty_InvalidName"),
	[GuildLib.GuildResult_GuildNameUnavailable] = Apollo.GetString("Warparty_NameUnavailable"),	-- Note - there are more reasons why it could be unavailble besides it being in use.
	[GuildLib.GuildResult_NotHighEnoughLevel] 	= Apollo.GetString("Warparty_InsufficientLevel"),
}

local crGuildNameLengthError = ApolloColor.new("AlertOrangeYellow")
local crGuildNameLengthGood = ApolloColor.new("UI_TextHoloBodyCyan")
local kstrAlreadyInGuild = Apollo.GetString("Warparty_AlreadyInWarparty")

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function WarpartyRegister:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.tWndRefs = {}

    return o
end

function WarpartyRegister:Init()
    Apollo.RegisterAddon(self)
end

-----------------------------------------------------------------------------------------------
-- WarpartyRegister OnLoad
-----------------------------------------------------------------------------------------------
function WarpartyRegister:OnLoad()
    self.xmlDoc = XmlDoc.CreateFromFile("WarpartyRegister.xml")
    self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function WarpartyRegister:OnDocumentReady()
    if self.xmlDoc == nil then
        return
    end

	Apollo.RegisterEventHandler("GuildResultInterceptResponse", 	"OnGuildResultInterceptResponse", self)
	Apollo.RegisterTimerHandler("ErrorMessageTimer", 				"OnErrorMessageTimer", self)
	Apollo.RegisterEventHandler("GenericEvent_RegisterWarparty", 	"OnWarpartyRegistration", self)
	Apollo.RegisterEventHandler("Event_ShowWarpartyInfo", 			"OnCancel", self)
	Apollo.RegisterEventHandler("LFGWindowHasBeenClosed", 			"OnCancel", self)
end

-----------------------------------------------------------------------------------------------
-- WarpartyRegister Functions
-----------------------------------------------------------------------------------------------
function WarpartyRegister:OnWarpartyRegistration(tPos)
		-- Check to see if the player is already on an warparty of this type
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr:GetType() == GuildLib.GuildType_WarParty then
			Event_FireGenericEvent("Event_ShowWarpartyInfo")
			return
		end
	end
	
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		local wndMain = Apollo.LoadForm(self.xmlDoc, "WarpartyRegistrationForm", nil, self)
	    self.tWndRefs.wndMain = wndMain
		self.tWndRefs.wndWarpartyName = wndMain:FindChild("WarpartyNameString")
		self.tWndRefs.wndWarpartyNameLimit = wndMain:FindChild("WarpartyNameLimit")
		self.tWndRefs.wndRegister = wndMain:FindChild("RegisterBtn")
		self.tWndRefs.wndAlert = wndMain:FindChild("AlertMessage")
	
		self.tCreate = {}
		self.tCreate.strName = ""
	
		self:ResetOptions()
	end

	self.tWndRefs.wndWarpartyName:SetFocus()
	
	self.tWndRefs.wndMain:FindChild("WarpartyNameLabel"):SetText(Apollo.GetString("Warparty_NameYourWarparty"))

	self.tWndRefs.wndRegister:Enable(true)
	self.tWndRefs.wndMain:Invoke()
	self:Validate()
end

function WarpartyRegister:ResetOptions()
	self.tCreate.strName = ""
	self.tWndRefs.wndAlert:Show(false)
	self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetText("")
	self.tWndRefs.wndAlert:FindChild("MessageBodyText"):SetText("")
	self.tWndRefs.wndWarpartyName:SetText("")
	self:HelperClearFocus()
	self:Validate()
end

function WarpartyRegister:OnNameChanging(wndHandler, wndControl)
	self.tCreate.strName = self.tWndRefs.wndWarpartyName:GetText()
	self:Validate()
end

function WarpartyRegister:Validate()
	local bIsTextValid = GameLib.IsTextValid(self.tCreate.strName, GameLib.CodeEnumUserText.GuildName, GameLib.CodeEnumUserTextFilterClass.Strict)
	local bValid = self:HelperCheckForEmptyString(self.tCreate.strName) and bIsTextValid

	self.tWndRefs.wndRegister:Enable(bValid)
	self.tWndRefs.wndMain:FindChild("ValidAlert"):Show(not bValid)
	

	local nNameLength = Apollo.StringLength(self.tCreate.strName or "")
	if nNameLength < 3 or nNameLength > GameLib.GetTextTypeMaxLength(GameLib.CodeEnumUserText.GuildName) then
		self.tWndRefs.wndWarpartyNameLimit:SetTextColor(crGuildNameLengthError)
	else
		self.tWndRefs.wndWarpartyNameLimit:SetTextColor(crGuildNameLengthGood)
	end

	self.tWndRefs.wndWarpartyNameLimit:SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), nNameLength, GameLib.GetTextTypeMaxLength(GameLib.CodeEnumUserText.GuildName)))
end

function WarpartyRegister:HelperCheckForEmptyString(strText) -- make sure there's a valid string
	local strFirstChar
	local bHasText = false

	strFirstChar = string.find(strText, "%S")

	bHasText = strFirstChar ~= nil and Apollo.StringLength(strFirstChar) > 0
	return bHasText
end

function WarpartyRegister:HelperClearFocus(wndHandler, wndControl)
	self.tWndRefs.wndWarpartyName:ClearFocus()
end

-----------------------------------------------------------------------------------------------
-- WarpartyRegistrationForm Functions
-----------------------------------------------------------------------------------------------
function WarpartyRegister:OnRegisterBtn(wndHandler, wndControl)
	local tGuildInfo = self.tCreate

	local arGuldResultsExpected = { GuildLib.GuildResult_Success,  GuildLib.GuildResult_AtMaxGuildCount, GuildLib.GuildResult_InvalidGuildName,
									 GuildLib.GuildResult_GuildNameUnavailable, GuildLib.GuildResult_NotEnoughRenown, GuildLib.GuildResult_NotEnoughCredits,
									 GuildLib.GuildResult_InsufficientInfluence, GuildLib.GuildResult_NotHighEnoughLevel, GuildLib.GuildResult_YouJoined,
									 GuildLib.GuildResult_YouCreated, GuildLib.GuildResult_MaxArenaTeamCount, GuildLib.GuildResult_MaxWarPartyCount,
									 GuildLib.GuildResult_AtMaxCircleCount, GuildLib.GuildResult_VendorOutOfRange, GuildLib.GuildResult_CannotCreateWhileInQueue }

	Event_FireGenericEvent("GuildResultInterceptRequest", GuildLib.GuildType_WarParty, self.tWndRefs.wndMain, arGuldResultsExpected )

	GuildLib.Create(tGuildInfo.strName, GuildLib.GuildType_WarParty)
	self:HelperClearFocus()
	self.tWndRefs.wndRegister:Enable(false)
	--NOTE: Requires a server response to progress
end

function WarpartyRegister:OnCancel(wndHandler, wndControl)
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain:Close()
		self:HelperClearFocus()
		self:ResetOptions()
		self.tWndRefs.wndMain:Destroy()
		self.tWndRefs = {}
	end
end

function WarpartyRegister:OnGuildResultInterceptResponse( guildCurr, eGuildType, eResult, wndRegistration, strAlertMessage )

	if eGuildType ~= GuildLib.GuildType_WarParty or wndRegistration ~= self.tWndRefs.wndMain or self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	if eResult == GuildLib.GuildResult_YouCreated or eResult == GuildLib.GuildResult_YouJoined then
		Event_FireGenericEvent("Event_ShowWarpartyInfo")
		self:OnCancel()
		return
	end

	self.tWndRefs.wndAlert:FindChild("MessageAlertText"):SetText(Apollo.GetString("Warparty_Whoops"))
	Apollo.CreateTimer("ErrorMessageTimer", 3.00, false)
	self.tWndRefs.wndAlert:FindChild("MessageBodyText"):SetText(strAlertMessage)
	self.tWndRefs.wndAlert:Show(true)
end

function WarpartyRegister:OnErrorMessageTimer()
	if self.tWndRefs.wndAlert ~= nil and self.tWndRefs.wndAlert:IsValid() then
		self.tWndRefs.wndAlert:Show(false)
	end

	if self.tWndRefs.wndRegister and self.tWndRefs.wndRegister:IsValid() then
		self.tWndRefs.wndRegister:Enable(true) -- safe to assume since it was clicked once
	end
end

-----------------------------------------------------------------------------------------------
-- WarpartyRegister Instance
-----------------------------------------------------------------------------------------------
local WarpartyRegisterInst = WarpartyRegister:new()
WarpartyRegisterInst:Init()
