-----------------------------------------------------------------------------------------------
-- Client Lua Script for MatchMaker
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "MatchMakingLib"
require "MatchingGameLib"
require "GameLib"
require "Unit"
require "GroupLib"
require "MatchMakingEntry"

local MatchMaker = {}

local knSaveVersion = 1

function MatchMaker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.tRoles = {}
	o.tWndRefs = {}

    return o
end

function MatchMaker:Init()
    Apollo.RegisterAddon(self)
end

function MatchMaker:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	
	local tSaved = 
	{
		nSaveVersion = knSaveVersion,
		tRoles = self.tRoles,
	}
	
	return tSaved
end

function MatchMaker:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	if tSavedData == nil or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end

	if tSavedData.tRoles ~= nil then
		self.tRoles = tSavedData.tRoles
	end
end

function MatchMaker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ConfirmRole.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function MatchMaker:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("MatchLookingForReplacements", "OnLookingForReplacements", self)
	Apollo.RegisterEventHandler("MatchStoppedLookingForReplacements", "OnStoppedLookingForReplacements", self)
	Apollo.RegisterEventHandler("MatchingRoleCheckStarted", "OnRoleCheck", self)
	Apollo.RegisterEventHandler("MatchingRoleCheckCanceled", "OnRoleCheckCanceled", self)
	Apollo.RegisterEventHandler("Generic_MatchMaker_ToggleCombatRole", "OnGeneric_MatchMaker_ToggleCombatRole", self)
end

function MatchMaker:OnLookingForReplacements()
	self:OnRoleCheckCanceled()
end

function MatchMaker:OnStoppedLookingForReplacements()
	self:OnRoleCheckCanceled()
end

function MatchMaker:HelperToggleRole(eRole, bShouldAdd)
	if bShouldAdd then
		self.tRoles[eRole] = eRole
	else
		self.tRoles[eRole] = nil
	end
end

function MatchMaker:OnRoleCheck(bRolesRequired)
	if self.tWndRefs.wndConfirmRole ~= nil and self.tWndRefs.wndConfirmRole:IsValid() then
		self.tWndRefs.wndConfirmRole:Close()
	end

	self.tWndRefs.wndConfirmRole = Apollo.LoadForm(self.xmlDoc, "RoleConfirm", nil, self)
	local wndConfirmRoleButtons = self.tWndRefs.wndConfirmRole:FindChild("InsetFrame")
	
	if bRolesRequired then
		local tRoleCheckButtons =
		{
			[MatchMakingLib.Roles.Tank] = wndConfirmRoleButtons:FindChild("TankBtn"),
			[MatchMakingLib.Roles.Healer] = wndConfirmRoleButtons:FindChild("HealerBtn"),
			[MatchMakingLib.Roles.DPS] = wndConfirmRoleButtons:FindChild("DPSBtn"),
		}
	
		for eRole, wndButton in pairs(tRoleCheckButtons) do
			wndButton:Enable(false)
			wndButton:SetData(eRole)
		end
	
		for idx, eRole in pairs(MatchMakingLib.GetEligibleRoles()) do
			tRoleCheckButtons[eRole]:Enable(true)
		end
	
		for idx, eRole in pairs(self.tRoles) do
			tRoleCheckButtons[eRole]:SetCheck(true)
		end

	else
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndConfirmRole:GetAnchorOffsets()
		self.tWndRefs.wndConfirmRole:SetAnchorOffsets(nLeft, nTop, nRight, nBottom - wndConfirmRoleButtons:GetHeight())
		wndConfirmRoleButtons:Show(false)
		self.tWndRefs.wndConfirmRole:FindChild("Header"):SetText(Apollo.GetString("MatchMaker_QueueConfirmTitle"))
	end
	
	self.tWndRefs.wndConfirmRole:FindChild("AcceptButton"):Enable(not bRolesRequired or next(self.tRoles) ~= nil)
end

function MatchMaker:OnRoleCheckCanceled()
	if self.tWndRefs.wndConfirmRole == nil or not self.tWndRefs.wndConfirmRole:IsValid() then
		return
	end

	self.tWndRefs.wndConfirmRole:Close()
end

function MatchMaker:OnRoleCheckClosed()
	self.tWndRefs.wndConfirmRole:Destroy()
	self.tWndRefs.wndConfirmRole = nil
end

function MatchMaker:OnAcceptRole(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	MatchingGameLib.ConfirmRole(self.tRoles)
	self.tWndRefs.wndConfirmRole:Close()
end

function MatchMaker:OnCancelRole(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	MatchingGameLib.DeclineRoleCheck()
	self.tWndRefs.wndConfirmRole:Close()
end

function MatchMaker:OnToggleRoleCheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:HelperToggleRole(wndHandler:GetData(), wndHandler:IsChecked())

	self.tWndRefs.wndConfirmRole:FindChild("AcceptButton"):Enable(self.tRoles ~= nil and next(self.tRoles) ~= nil)
end

function MatchMaker:OnGeneric_MatchMaker_ToggleCombatRole(tData)
	if tData.bSet then
		self.tRoles[tData.eRole] = tData.eRole
	else
		self.tRoles[tData.eRole] = nil
	end
end

-----------------------------------------------------------------------------------------------
-- MatchMaker Instance
-----------------------------------------------------------------------------------------------
local MatchMakerInst = MatchMaker:new()
MatchMakerInst:Init()
