-----------------------------------------------------------------------------------------------
-- Client Lua Script for ServiceTokenConfirmation
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "StorefrontLib"
require "AccountItemLib"
require "GameLib"
require "Sound"


-----------------------------------------------------------------------------------------------
-- ServiceTokenConfirmation Module Definition
-----------------------------------------------------------------------------------------------
local ServiceTokenConfirmation = {} 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ServiceTokenConfirmation:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function ServiceTokenConfirmation:Init()
    Apollo.RegisterAddon(self)
end

function ServiceTokenConfirmation:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ServiceTokenConfirmation.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end
-----------------------------------------------------------------------------------------------
-- ServiceTokenConfirmation OnDocLoaded
-----------------------------------------------------------------------------------------------
function ServiceTokenConfirmation:OnDocLoaded()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("SpellCastWithServiceToken", "OnSpellCastWithServiceToken", self)
	Apollo.RegisterEventHandler("GenericEvent_ServiceTokenPrompt", "InvokeConfirmationWindow", self)
	Apollo.RegisterEventHandler("AccountCurrencyChanged", "OnCurrencyChanged", self)

	--StoreEvents
	Apollo.RegisterEventHandler("StoreLinksRefresh",								"RefreshStoreLink", self)

	--ActionConfirmEvents
	--Some action confirm events don't get handled through the button. Register for those here.
	Apollo.RegisterEventHandler("CostumeSaveResult", "OnClose", self)

	self.timer = nil
	self.spellId = nil
	self.retCode = false
end


function ServiceTokenConfirmation:OnSpellCastWithServiceToken(spellId)
	-- Skip if this spell is already displayed
	if self.spellId == spellId then
		return
	end
	
	self.spellId = spellId
	
	local tData = 
	{	
		monCost = GameLib.GetSpell(spellId):GetSpellServiceTokenCost(),
		strConfirmation = String_GetWeaselString(Apollo.GetString("ServiceToken_Confirm"), GameLib.GetSpell(spellId):GetName()),
		tActionData = 
		{
			GameLib.CodeEnumConfirmButtonType.CastSpellService,
			spellId,
		}
	}
	self:InvokeConfirmationWindow(tData)
	-- Setup spell cooldown timer
	if self.timer == nil then
		self.timer = ApolloTimer.Create(0.25, true, "OnSpellUpdate", self)
	else
		self.timer:Start()
	end
end

function ServiceTokenConfirmation:InvokeConfirmationWindow(tData)
	if type(tData) ~= "table" then
		return
	end

	self:OnClose(true)--Close current confirmation to make new confirmation.

	if tData.wndParent then
		local wndServiceTokenConfirmationForm = tData.wndParent:FindChild("ServiceTokenConfirmationForm")
		if wndServiceTokenConfirmationForm then
			wndServiceTokenConfirmationForm:Destroy()
		end
	end

	self.tConfirmationData = tData
	-- Display window
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ServiceTokenConfirmationForm", tData.wndParent, self)

	Sound.Play(Sound.PlayUI55ErrorVirtual)

	-- Setup window contents
	self.wndMain:FindChild("ConfirmationText"):SetText(tData.strConfirmation)
	self.wndMain:FindChild("Price"):SetAmount(tData.monCost)
	
	if tData.monCost:IsAccountCurrencyType() then
		self.wndMain:FindChild("Amount"):SetAmount(AccountItemLib.GetAccountCurrency(tData.monCost:GetAccountCurrencyType()))
	else
		self.wndMain:FindChild("Amount"):SetAmount(GameLib.GetPlayerCurrency(tData.monCost:GetMoneyType()))
	end
	
	self.wndMain:FindChild("ConfirmBtn"):SetActionData(unpack(tData.tActionData))
	
	self:OnCurrencyChanged()
	self:RefreshStoreLink()

	self.wndMain:Invoke()
end

function ServiceTokenConfirmation:OnCurrencyChanged()
	if self.wndMain == nil then
		return
	end

	-- Display Current Service Tokens
	local nCurrentAmount = 0
	if self.tConfirmationData.monCost:IsAccountCurrencyType() then
		nCurrentAmount = AccountItemLib.GetAccountCurrency(self.tConfirmationData.monCost:GetAccountCurrencyType()):GetAmount()
	else
		nCurrentAmount = GameLib.GetPlayerCurrency(self.tConfirmationData.monCost:GetMoneyType()):GetAmount()
	end

	-- Set color based on if you have enough currency
	if self.tConfirmationData.monCost:GetAmount() > nCurrentAmount then
		self.wndMain:FindChild("Price"):SetTextColor(ApolloColor.new("UI_WindowErrorText"))
		
		if self.tConfirmationData.monCost:GetAccountCurrencyType() == AccountItemLib.CodeEnumAccountCurrency.ServiceToken then
			self.wndMain:FindChild("ConfirmBtn"):Show(false)
			self.wndMain:FindChild("BuyBtn"):Show(true)
		else
			self.wndMain:FindChild("ConfirmBtn"):Show(true)
			self.wndMain:FindChild("ConfirmBtn"):Enable(false)
			self.wndMain:FindChild("BuyBtn"):Show(false)
		end
	else
		self.wndMain:FindChild("Price"):SetTextColor(ApolloColor.new("UI_TextHoloBodyCyan"))
		self.wndMain:FindChild("ConfirmBtn"):Show(true)
		self.wndMain:FindChild("ConfirmBtn"):Enable(true)
		self.wndMain:FindChild("BuyBtn"):Show(false)
	end
end

function ServiceTokenConfirmation:RefreshStoreLink()
	if not self.wndMain then
		return
	end

	self.wndMain:FindChild("BuyBtn"):Enable(StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.ServiceTokens))
end

function ServiceTokenConfirmation:OnBuyBtn(wndHandler, wndControl)
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.ServiceTokens)
	self:OnClose()
end

function ServiceTokenConfirmation:OnSpellUpdate()
	-- Check to see if spell is off cooldown to hide confirmation window
	if GameLib.GetSpell(self.spellId):GetCooldownRemaining() == 0 then
		self:OnClose()
	end
end

function ServiceTokenConfirmation:OnWindowClose()
	-- Reset the spell that is being tracked
	self.spellId = nil

	-- Kill the timer
	if self.timer ~= nil then
		self.timer:Stop()
		self.timer = nil
	end
	
	-- Close the window
	self.wndMain:Destroy()
	self.wndMain = nil
end

function ServiceTokenConfirmation:OnCloseSuccess()
	self.retCode = true
	self:OnClose()
end

function ServiceTokenConfirmation:OnClose(bInit)
	local strParent = ""
	local strEventName = ""
	if self.wndMain then
		local wndParent = self.wndMain:GetParent() 
		if wndParent then
			strParent = wndParent:GetName()
			strEventName = self.tConfirmationData.strEventName
		end

		self.wndMain:Close()
	end

	if bInit ~= true and self.tConfirmationData then
		Event_FireGenericEvent(strEventName, strParent, self.tConfirmationData.tActionData[1], self.retCode)
		-- Re-initialize return code to false
		self.retCode = false
	end
end
---------------------------------------------------------------------------------------------------
-- ServiceTokenConfirmationForm Functions
---------------------------------------------------------------------------------------------------
local ServiceTokenConfirmationInst = ServiceTokenConfirmation:new()
ServiceTokenConfirmationInst:Init()
