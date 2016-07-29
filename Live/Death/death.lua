-----------------------------------------------------------------------------------------------
-- Client Lua Script for Death
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "Tooltip"
require "XmlDoc"
require "GameLib"
require "AccountItemLib"
require "MatchingGameLib"

---------------------------------------------------------------------------------------------------
-- Death module definition
---------------------------------------------------------------------------------------------------
local Death = {}

---------------------------------------------------------------------------------------------------
-- local constants
---------------------------------------------------------------------------------------------------
local kcrCanResurrectButtonColor = CColor.new(1, 1, 1, 1)
local kcrCannotResurrectButtonColor = CColor.new(.6, .6, .6, 1)
local kcrCanResurrectTextColor = ApolloColor.new("UI_BtnTextBlueNormal")
local kcrCannotResurrectTextColor = CColor.new(.3, .3, .3, 1)

local knSaveVersion = 3

---------------------------------------------------------------------------------------------------
-- Death functions
---------------------------------------------------------------------------------------------------
function Death:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.tWndRefs = {}
	o.tDeathState = {}
	o.nGoldPenalty = 0
	o.bEnableRezHere = true
	o.bEnableCasterRez = false
	o.bHasCasterRezRequest = false
	o.nRezCost = 0
	o.fTimeBeforeRezable = 0
	o.fTimeBeforeWakeHere = 0

	return o
end

function Death:Init()
	Apollo.RegisterAddon(self)
end

---------------------------------------------------------------------------------------------------
-- EventHandlers
---------------------------------------------------------------------------------------------------
function Death:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Death.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end


function Death:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	
		Apollo.RegisterEventHandler("ShowResurrectDialog", 		"OnShowResurrectDialog", self)
		Apollo.RegisterEventHandler("UpdateResurrectDialog", 	"OnUpdateResurrectDialog", self)
		Apollo.RegisterEventHandler("ShowIncapacitationBar", 	"ShowIncapacitationBar", self)
		Apollo.RegisterEventHandler("HideIncapacitationBar", 	"HideIncapacitationBar", self)
		Apollo.RegisterEventHandler("CasterResurrectedPlayer", 	"CasterResurrectedPlayer", self)
		Apollo.RegisterEventHandler("ForceResurrect", 			"OnForcedResurrection", self)
		Apollo.RegisterEventHandler("ScriptResurrect", 			"OnScriptResurrection", self)
		Apollo.RegisterEventHandler("MatchExited", 				"OnForcedResurrection", self)
		Apollo.RegisterEventHandler("PVPDeathmatchPoolUpdated", "OnPVPDeathmatchPoolUpdated", self)
		Apollo.RegisterEventHandler("CharacterCreated", 		"OnCharacterCreated", self)

		--StoreEvents
		Apollo.RegisterEventHandler("StoreLinksRefresh",		"RefreshStoreLink", self)

		local wndResurrect = Apollo.LoadForm(self.xmlDoc, "ResurrectDialog", nil, self)
		self.tWndRefs.wndResurrect = wndResurrect
		self.tWndRefs.wndResurrectDialogTimer = wndResurrect:FindChild("ResurrectDialog.Timer")
		self.tWndRefs.wndResurrectDialogHereFrame = wndResurrect:FindChild("ResurrectDialog.HereFrame")
		self.tWndRefs.wndResurrectDialogHereToken = wndResurrect:FindChild("ResurrectDialog.HereToken")
		self.tWndRefs.wndResurrectDialogHere = wndResurrect:FindChild("ResurrectDialog.Here")
		self.tWndRefs.wndResurrectDialogHereTokenFrame = wndResurrect:FindChild("ResurrectDialog.HereTokenFrame")
		self.tWndRefs.wndResurrectDialogPurchaseTokenFrame = wndResurrect:FindChild("ResurrectDialog.MTX_PurchaseServiceToken")
		self.tWndRefs.wndResurrectDialogEldanFrame = wndResurrect:FindChild("ResurrectDialog.EldanFrame")
		self.tWndRefs.wndResurrectDialogExitFrame = wndResurrect:FindChild("ResurrectDialog.ExitFrame")
		self.tWndRefs.wndResurrectDialogCasterFrame = wndResurrect:FindChild("ResurrectDialog.CasterFrame")	
		self.tWndRefs.wndArtTimeToRezHere = wndResurrect:FindChild("ArtTimeToRezHere")
		self.tWndRefs.wndForceRezText = wndResurrect:FindChild("ForceRezText")
		self.tWndRefs.wndResurrectDialogButtons = wndResurrect:FindChild("ResurrectDialogButtons")		
		
		local wndExitConfirm = Apollo.LoadForm(self.xmlDoc, "ExitInstanceDialog", nil, self)
		self.tWndRefs.wndExitConfirm = wndExitConfirm
		
		
		wndResurrect:FindChild("ResurrectDialog.HereToken"):SetActionData(GameLib.CodeEnumConfirmButtonType.WakeHereService)
		
		self.bLinkAvailable = false
		self.xmlDoc = nil
		
		self.nTimerProgress = nil
		self.bDead = false
		
		self.timerTenthSec = ApolloTimer.Create(0.12, true, "OnTenthSecTimer", self)
		self.timerTenthSec:Stop()

		if GameLib.GetPlayerUnit() then
			self:OnCharacterCreated()
		end
		
		Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
		self:OnWindowManagementReady()
	end
end

function Death:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	
	local tSaveData = 
	{
		bCasterRezzed = self.tDeathState.bHasCasterRezRequest,
		nSaveVersion = knSaveVersion,
	}
	return tSaveData
end

function Death:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	if tSavedData == nil or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end
	
	if tSavedData.bCasterRezzed ~= nil then
		self.tDeathState.bHasCasterRezRequest = tSavedData.bCasterRezzed
	end
end

function Death:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("InterfaceMenu_Death"), nSaveVersion = 1})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndResurrect, strName = Apollo.GetString("InterfaceMenu_Death")})
	
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("InterfaceMenu_ExitInstance"), nSaveVersion = 1})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndExitConfirm, strName = Apollo.GetString("InterfaceMenu_ExitInstance")})
end

---------------------------------------------------------------------------------------------------
-- Interface
---------------------------------------------------------------------------------------------------
function Death:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	
	if unitPlayer:IsDead() == false then
		return
	end
	
	self.tDeathState = GameLib.GetPlayerDeathState()
	
	self:OnShowResurrectDialog(self.tDeathState)
end

function Death:RefreshStoreLink()
	if not self.tWndRefs.wndResurrect then
		return
	end

	self.bLinkAvailable = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.ServiceTokens)
end

function Death:OnShowResurrectDialog(tDeathState)
	self.timerTenthSec:Start()
	
	self:OnUpdateResurrectDialog(tDeathState)
	self:RefreshStoreLink()
end

function Death:OnUpdateResurrectDialog(tDeathState)
	self.tDeathState = tDeathState
	
	if not self.tDeathState.bIsDead then
		self.tWndRefs.wndExitConfirm:Close()	
		self.tWndRefs.wndResurrect:Close()
		self.nTimerProgress = nil
		return
	end
	
	--hide and format everything
	self.tWndRefs.wndExitConfirm:Close()	
	self.tWndRefs.wndResurrectDialogHereFrame:Show(false)
	self.tWndRefs.wndResurrectDialogHereTokenFrame:Show(false)
	self.tWndRefs.wndResurrectDialogPurchaseTokenFrame:Show(false)
	self.tWndRefs.wndResurrectDialogEldanFrame:Show(false)
	self.tWndRefs.wndResurrectDialogExitFrame:Show(false)
	self.tWndRefs.wndResurrectDialogCasterFrame:Show(false)	
	self.tWndRefs.wndArtTimeToRezHere:SetText(Apollo.GetString("CRB_Time_Remaining_2"))
	self.tWndRefs.wndArtTimeToRezHere:Show(true)
	self.tWndRefs.wndForceRezText:Show(false)
	
	if self.tDeathState.bIsDead and not self.tWndRefs.wndResurrect:IsShown() then
		self.tWndRefs.wndResurrect:Invoke()
	end
end


------------------------------------//------------------------------
function Death:OnTenthSecTimer(nTime)
	if self.tDeathState.bIsDead ~= true then
		return
	end

	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndResurrect:GetAnchorOffsets()
	local nStartingWidth = self.tWndRefs.wndResurrect:GetWidth()

	self.tDeathState = GameLib.GetPlayerDeathState()

	if self.tDeathState.fDeathPenalty > 0 then -- this timer takes precendence over everything. if it has a count, the player can't do anything
		local strTimeBeforeRezableFormatted = self:HelperToStringTime(self.tDeathState.fDeathPenalty)
		self.tWndRefs.wndResurrectDialogTimer:SetText(strTimeBeforeRezableFormatted .. Apollo.GetString("CRB__seconds"))
		self.tWndRefs.wndResurrectDialogTimer:Show(true)
		
		local nDiff = 400 - nStartingWidth
		local nHalfDiff = nDiff / 2
		
		if nDiff ~= 0 then
			self.tWndRefs.wndResurrect:SetAnchorOffsets(nLeft - nHalfDiff, nTop, nRight + nHalfDiff, nBottom)
		end
	else
		local tMatchInfo = MatchingGameLib.GetPvpMatchState()
		if tMatchInfo ~= nil then
			if tMatchInfo.eRules == MatchingGameLib.Rules.DeathmatchPool then
				if tMatchInfo.tLivesRemaining[tMatchInfo.eMyTeam] == 0 then
					self.tWndRefs.wndResurrectDialogTimer:SetText(Apollo.GetString("Death_NoLives"))
					self.tWndRefs.wndResurrectDialogTimer:Show(true)	
					self.tWndRefs.wndForceRezText:Show(false)
					self.tWndRefs.wndResurrectDialogHereFrame:Show(false)
					self.tWndRefs.wndResurrectDialogHereTokenFrame:Show(false)
					self.tWndRefs.wndResurrectDialogPurchaseTokenFrame:Show(false)
					self.tWndRefs.wndResurrectDialogEldanFrame:Show(false)
					self.tWndRefs.wndResurrectDialogExitFrame:Show(false)
					self.tWndRefs.wndResurrectDialogCasterFrame:Show(false)
					
					local nDiff = 400 - nStartingWidth
					local nHalfDiff = nDiff / 2
					
					if nDiff ~= 0 then
						self.tWndRefs.wndResurrect:SetAnchorOffsets(nLeft - nHalfDiff, nTop, nRight + nHalfDiff, nBottom)
					end
					return
				end
			elseif tMatchInfo.eRules == MatchingGameLib.Rules.WaveRespawn then
				self.tWndRefs.wndResurrect:Close()
				return
			end
		end

		self.tWndRefs.wndArtTimeToRezHere:Show(false)
		self.tWndRefs.wndResurrectDialogTimer:Show(false)
		self.tWndRefs.wndForceRezText:Show(self.tDeathState.fForceRezTimer > 0)
		self.tWndRefs.wndResurrectDialogHereFrame:Show(self.tDeathState.bWakeHere)
		self.tWndRefs.wndResurrectDialogHereTokenFrame:Show(self.tDeathState.bWakeHereServiceToken and self.tDeathState.fWakeHereCooldown > 0)
		self.tWndRefs.wndResurrectDialogPurchaseTokenFrame:Show(self.bLinkAvailable and self.tDeathState.bWakeHereServiceToken and self.tDeathState.fWakeHereCooldown > 0)
		self.tWndRefs.wndResurrectDialogEldanFrame:Show(self.tDeathState.bHolocrypt or self.tDeathState.bExitInstance)
		self.tWndRefs.wndResurrect:FindChild("ResurrectDialog.Eldan"):Enable(self.tDeathState.bHolocrypt)
		self.tWndRefs.wndResurrectDialogExitFrame:Show(self.tDeathState.bExitInstance)
		self.tWndRefs.wndResurrectDialogCasterFrame:Show(self.tDeathState.bAcceptCasterRez and self.tDeathState.bHasCasterRezRequest)	
		
		local nWidth = self.tWndRefs.wndResurrectDialogButtons:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle) + 100
		local nDiff = nWidth - nStartingWidth
		local nHalfDiff = nDiff / 2
		local nHeight = self.tWndRefs.wndResurrectDialogButtons:GetHeight()
		
		local nResHeight = 295
		if self.tWndRefs.wndResurrectDialogExitFrame:IsShown() or self.tWndRefs.wndResurrect:FindChild("ResurrectDialog.MTX_Death"):IsShown() or self.tWndRefs.wndResurrectDialogPurchaseTokenFrame:IsShown() then 
			nResHeight = nResHeight + self.tWndRefs.wndResurrectDialogPurchaseTokenFrame:GetHeight()
		end
		
		if nStartingWidth ~= nWidth or nHeight ~= nResHeight then
			self.tWndRefs.wndResurrect:SetAnchorOffsets(nLeft - nHalfDiff, nTop, nRight + nHalfDiff, nTop + nResHeight)
			self.tWndRefs.wndResurrectDialogButtons:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
		end

		-- set up rez here
		if self.tWndRefs.wndResurrectDialogHereFrame:IsShown() then
			local wndBtn = self.tWndRefs.wndResurrectDialogHere
			wndBtn:FindChild("ResurrectDialog.Cash"):SetAmount(self.tDeathState.monRezCost)

			if self.tDeathState.fWakeHereCooldown <= 0 then  -- ready to go
				local bCanAfford = self.tDeathState.monRezCost:GetAmount() <= GameLib.GetPlayerCurrency():GetAmount()
				wndBtn:Enable(bCanAfford)
				wndBtn:FindChild("WakeHereText"):SetText(Apollo.GetString("Death_WakeHere"))
				wndBtn:FindChild("WakeHereCooldownText"):SetText("")
				wndBtn:FindChild("ResurrectDialog.Cash"):Show(true)
				wndBtn:FindChild("CostLabel"):Show(true)
				if bCanAfford then
					self.tWndRefs.wndResurrectDialogHere:SetBGColor(kcrCanResurrectButtonColor)
					wndBtn:FindChild("WakeHereText"):SetTextColor(kcrCanResurrectTextColor)
					wndBtn:FindChild("ResurrectDialog.Cash"):SetTextColor(ApolloColor.new("UI_BtnTextBlueNormal"))
				else -- not enough money
					self.tWndRefs.wndResurrectDialogHere:SetBGColor(kcrCannotResurrectButtonColor)
					wndBtn:FindChild("WakeHereText"):SetTextColor(kcrCannotResurrectTextColor)	
					wndBtn:FindChild("ResurrectDialog.Cash"):SetTextColor(ApolloColor.new("Reddish"))						
				end	
			else -- still cooling down
				wndBtn:Enable(false)
				local strCooldownFormatted = self:HelperToStringTimeWithMills(self.tDeathState.fWakeHereCooldown)
				wndBtn:FindChild("WakeHereCooldownText"):SetText(String_GetWeaselString(Apollo.GetString("Death_CooldownTimer"), strCooldownFormatted))
				wndBtn:FindChild("ResurrectDialog.Cash"):Show(false)
				wndBtn:FindChild("CostLabel"):Show(false)
				self.tWndRefs.wndResurrectDialogHere:SetBGColor(kcrCannotResurrectButtonColor)
				wndBtn:FindChild("WakeHereText"):SetTextColor(kcrCannotResurrectTextColor)					
			end
		end	
		--set up rez here - for service tokens
		if self.tWndRefs.wndResurrectDialogHereTokenFrame:IsShown() then
			local wndBtn = self.tWndRefs.wndResurrectDialogHereToken
			wndBtn:FindChild("ResurrectDialog.Token"):SetAmount(self.tDeathState.monRezServiceTokenCost)
						
			local bCanAfford = self.tDeathState.monRezServiceTokenCost:GetAmount() <= AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.ServiceToken):GetAmount()
			wndBtn:Enable(bCanAfford)
			wndBtn:FindChild("WakeHereTokenText"):SetText(Apollo.GetString("Death_WakeHere"))
			wndBtn:FindChild("ResurrectDialog.Token"):Show(true)
			wndBtn:FindChild("CostTokenLabel"):Show(true)
			if bCanAfford then
				self.tWndRefs.wndResurrectDialogHereToken:SetBGColor(kcrCanResurrectButtonColor)
				wndBtn:FindChild("WakeHereTokenText"):SetTextColor(kcrCanResurrectTextColor)
				wndBtn:FindChild("ResurrectDialog.Token"):SetTextColor(ApolloColor.new("UI_BtnTextBlueNormal"))
			else -- not enough tokens
				self.tWndRefs.wndResurrectDialogHereToken:SetBGColor(kcrCannotResurrectButtonColor)
				wndBtn:FindChild("WakeHereTokenText"):SetTextColor(kcrCannotResurrectTextColor)
				wndBtn:FindChild("ResurrectDialog.Token"):SetTextColor(ApolloColor.new("Reddish"))
			end	
		end	
	end
		
	if self.tDeathState.fForceRezTimer > 0 then
		local strTimeFormatted = self:HelperToStringTimeWithMills(self.tDeathState.fForceRezTimer)
		self.tWndRefs.wndForceRezText:SetText(String_GetWeaselString(Apollo.GetString("Death_AutoRelease"), strTimeFormatted))
	end

end

------------------------------------//------------------------------

function Death:CasterResurrectedPlayer(strCasterName)
	self.tDeathState.bHasCasterRezRequest = true;
end

function Death:OnResurrectHere()
	if GameLib.GetPlayerUnit() ~= nil then
		GameLib.GetPlayerUnit():Resurrect(GameLib.RezType.WakeHere, 0)
	end
	
	self.tWndRefs.wndResurrect:Close()
	self.tDeathState.bIsDead = false
	
	self.timerTenthSec:Stop()
	Event_FireGenericEvent("PlayerResurrected")
end

------------------------------------//------------------------------
function Death:OnHereTokenCompleted()
	self.tWndRefs.wndResurrect:Close()
	self.tDeathState.bIsDead = false
	
	self.timerTenthSec:Stop()
	Event_FireGenericEvent("PlayerResurrected")
end
------------------------------------//------------------------------
function Death:OnResurrectCaster()
	if GameLib.GetPlayerUnit() ~= nil then
		GameLib.GetPlayerUnit():Resurrect(GameLib.RezType.SpellCasterLocation, 0) -- WIP, this should send in the UnitId of the caster
	end
	
	self.tWndRefs.wndResurrect:Close()
	self.tDeathState.bIsDead = false
	
	self.timerTenthSec:Stop()
	Event_FireGenericEvent("PlayerResurrected")
end

------------------------------------//------------------------------
function Death:OnBuyBtn()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.ServiceTokens)
end

------------------------------------//------------------------------
function Death:OnResurrectEldan()
	if GameLib.GetPlayerUnit() ~= nil then
		GameLib.GetPlayerUnit():Resurrect(GameLib.RezType.Holocrypt, 0)
	end

	self.tWndRefs.wndResurrect:Close()
	self.tDeathState.bIsDead = false
	
	self.timerTenthSec:Stop()
	Event_FireGenericEvent("PlayerResurrected")
	
	if GameLib.GetPvpFlagInfo().nCooldown then
		ChatSystemLib.PostOnChannel( ChatSystemLib.ChatChannel_System, Apollo.GetString("Death_PvPFlagReset"), "" )
	end
end
------------------------------------//------------------------------
function Death:OnExitInstance()
	self.tWndRefs.wndExitConfirm:Invoke()
	self.tWndRefs.wndResurrect:Close()
end

function Death:OnConfirmExit()
	if GameLib.GetPlayerUnit() ~= nil then
		GameLib.GetPlayerUnit():Resurrect(GameLib.RezType.ExitInstance, 0)
	end

	self.tWndRefs.wndExitConfirm:Close()	
	self.tWndRefs.wndResurrect:Close()
	self.tDeathState.bIsDead = false
	
	self.timerTenthSec:Stop()
	Event_FireGenericEvent("PlayerResurrected")
end

function Death:OnCancelExit()
	self.tWndRefs.wndExitConfirm:Close()	
	self.tWndRefs.wndResurrect:Invoke()
end

------------------------------------//------------------------------
function Death:OnForcedResurrection()
	self.tWndRefs.wndExitConfirm:Close()	
	self.tWndRefs.wndResurrect:Close()
	self.tDeathState.bIsDead = false

	self.timerTenthSec:Stop()
	Event_FireGenericEvent("PlayerResurrected")
end

------------------------------------//------------------------------
function Death:OnScriptResurrection()
	self.tWndRefs.wndExitConfirm:Close()	
	self.tWndRefs.wndResurrect:Close()
	self.tDeathState.bIsDead = false

	self.timerTenthSec:Stop()
	Event_FireGenericEvent("PlayerResurrected")
end

------------------------------------//------------------------------

function Death:HideIncapacitationBar()
	self.tWndRefs.wndExitConfirm:Close()	
	self.tWndRefs.wndResurrect:Close()
end

function Death:HelperToStringTime(fTime)
	local fSeconds = math.floor(fTime)
	local fTenths = math.floor(fTime * 10) % 10
	return string.format("%d.%d", fSeconds, fTenths)
end

function Death:HelperToStringTimeWithMills(fTime)
	local fSeconds = math.floor(fTime)
	local fMillis = math.floor(fTime * 1000) % 1000

	local strOutputSeconds = "00"
	if math.floor(fSeconds % 60) >= 10 then
		strOutputSeconds = tostring(math.floor(fSeconds % 60))
	else
		strOutputSeconds = "0" .. math.floor(fSeconds % 60)
	end
	
	return String_GetWeaselString(Apollo.GetString("CRB_TimeMinsToMS"), math.floor(fSeconds / 60), strOutputSeconds, math.floor(fMillis / 100))
end

---------------------------------------------------------------------------------------------------
-- Death instance
---------------------------------------------------------------------------------------------------
local DeathInst = Death:new()
DeathInst:Init()
