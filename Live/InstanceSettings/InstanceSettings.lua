-----------------------------------------------------------------------------------------------
-- Client Lua Script for InstanceSettings
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local LuaCodeEnumDifficultyTypes =
{
	Normal = 1,
	Prime = 2,
	Veteran = 3,
}

local InstanceSettings = {}

--local knSaveVersion = 1

function InstanceSettings:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	
	self.bHidingInterface = false
	self.bNormalIsAllowed = false
	self.bVeteranIsAllowed = false

	self.bScalingIsAllowed = false
	
    return o
end

function InstanceSettings:Init()
    Apollo.RegisterAddon(self)
end

function InstanceSettings:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	
	local locMainWindowLoc = self.wndMain and self.wndMain:GetLocation() or self.locSavedMainLoc
	local locRestrictedWindowLoc = self.wndWaiting and self.wndWaiting:GetLocation() or self.locSavedRestrictedLoc
	
	local tSaved = 
	{
		tMainLocation = locMainWindowLoc and locMainWindowLoc:ToTable() or nil,
		tWaitingLocation = locRestrictedWindowLoc and locRestrictedWindowLoc:ToTable() or nil,
		nSavedVersion = knSaveVersion
	}
	
	return tSaved
end

function InstanceSettings:OnRestore(eType, tSavedData)
	if not tSavedData or tSavedData.nSavedVersion ~= knSaveVersion then
		return
	end
	if tSavedData.tMainLocation then
		self.locSavedMainLoc = WindowLocation.new(tSavedData.tMainLocation)
	end
	
	if tSavedData.tWaitingLocation then
		self.locSavedRestrictedLoc = WindowLocation.new(tSavedData.tWaitingLocation)
	end
end

function InstanceSettings:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("InstanceSettings.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function InstanceSettings:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	Apollo.RegisterEventHandler("ShowInstanceGameModeDialog", "OnShowDialog", self)
	Apollo.RegisterEventHandler("ShowInstanceRestrictedDialog", "OnShowRestricted", self)
	Apollo.RegisterEventHandler("HideInstanceGameModeDialog", "OnHideDialog", self)
	Apollo.RegisterEventHandler("OnInstanceResetResult", "OnInstanceResetResult", self)
	Apollo.RegisterEventHandler("PendingWorldRemovalWarning", "OnPendingWorldRemovalWarning", self)
	Apollo.RegisterEventHandler("PendingWorldRemovalCancel", "OnPendingWorldRemovalCancel", self)
	Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)
	
	Apollo.RegisterTimerHandler("InstanceSettings_MessageDisplayTimer", "OnMessageDisplayTimer", self)
	Apollo.RegisterTimerHandler("InstanceSettings_PendingRemovalTimer", "OnPendingRemovalTimer", self)
	
	self:OnPendingWorldRemovalWarning()
end

function InstanceSettings:OnShowRestricted()
	self:CloseForms()
	self.wndWaiting = Apollo.LoadForm(self.xmlDoc , "InstanceSettingsRestrictedForm", nil, self)
	self.wndWaiting:Invoke()
	if self.locSavedRestrictedLoc then
		self.wndWaiting:MoveToLocation(self.locSavedRestrictedLoc)
	end
end

function InstanceSettings:OnShowDialog(tData)
	self:CloseForms()
	
	self.nSelectedPrimeLevel = 0
	self.bNormalIsAllowed = tData.bDifficultyNormal
	self.bVeteranIsAllowed = tData.bDifficultyVeteran
	self.bScalingIsAllowed = tData.bFlagsScaling
	self.bHasPrimeLevels = tData.bHasPrimeLevels
	self.nMaxPrimeLevelWorld = tData.nMaxPrimeLevelWorld
	self.nMaxPrimeLevelGroup = tData.nMaxPrimeLevelGroup
	self.wndMain = Apollo.LoadForm(self.xmlDoc , "InstanceSettingsForm", nil, self)
	self.wndMain:Invoke()
	self.bHidingInterface = false
	self.wndMain:FindChild("LevelScalingButton"):Enable(true)
	self.wndMain:FindChild("LevelScalingButton"):Show(true)
	self.wndMain:FindChild("ScalingIsForced"):Show(false)
	-- we never want to show this "error" initially
	self.wndMain:FindChild("ErrorWindow"):Show(false)
	self.wndMain:FindChild("PrimeLevelBtn"):AttachWindow(self.wndMain:FindChild("PrimeLevelList"))

	if self.locSavedMainLoc then
		self.wndMain:MoveToLocation(self.locSavedMainLoc)
	end

	if tData.nExistingDifficulty == GroupLib.Difficulty.Count then
		-- there is no existing instance
		self:OnNoExistingInstance()

	else
		-- an existing instance
		-- set the options above to the settings of that instance (and disable the ability to change them)
		if tData.nExistingDifficulty == GroupLib.Difficulty.Normal then
			self.wndMain:SetRadioSel("InstanceSettings_LocalRadioGroup_Difficulty", LuaCodeEnumDifficultyTypes.Normal)
		elseif tData.bHasPrimeLevels then			
			self.wndMain:SetRadioSel("InstanceSettings_LocalRadioGroup_Difficulty", LuaCodeEnumDifficultyTypes.Prime)
		else
			self.wndMain:SetRadioSel("InstanceSettings_LocalRadioGroup_Difficulty", LuaCodeEnumDifficultyTypes.Veteran)
		end

		if tData.bExistingScaling == false then
			self.wndMain:FindChild("SubOptions"):SetRadioSel("InstanceSettings_LocalRadioGroup_Rallying", 0)
		else
			self.wndMain:FindChild("SubOptions"):SetRadioSel("InstanceSettings_LocalRadioGroup_Rallying", 1)
		end

		self.wndMain:FindChild("NewInstanceSettings"):Show(false)
		self.wndMain:FindChild("ExistingInstanceSettings"):Show(true)
		
		local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
		self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nTop + 330)
	
		if tData.nExistingDifficulty == GroupLib.Difficulty.Normal then
			self.wndMain:FindChild("DifficultyNormalCallout"):SetText(Apollo.GetString("CRB_Difficulty") .. " " .. Apollo.GetString("Tooltips_Normal"))
		elseif tData.bHasPrimeLevels then
			self.wndMain:FindChild("DifficultyNormalCallout"):SetText(Apollo.GetString("CRB_Difficulty") .. " " .. String_GetWeaselString(Apollo.GetString("InstanceSettings_ExistingPrimeLevel"), tData.nExistingPrimeLevel))
		else
			self.wndMain:FindChild("DifficultyNormalCallout"):SetText(Apollo.GetString("CRB_Difficulty") .. " " .. Apollo.GetString("CRB_Veteran"))
		end
			
		if tData.bExistingScaling then
			self.wndMain:FindChild("Rally"):SetText(Apollo.GetString("InstanceSettings_Level149_Title") .. " " .. Apollo.GetString("CRB_Yes"))
		else
			self.wndMain:FindChild("Rally"):SetText(Apollo.GetString("InstanceSettings_Level149_Title") .. " " .. Apollo.GetString("CRB_No"))
		end

	end

end

function InstanceSettings:OnInstanceResetResult(bResetWasSuccessful)

	if self.wndMain:IsShown() then
		Apollo.StopTimer("InstanceSettings_MessageDisplayTimer")
		
		-- dialog may have been destroyed ... so we have to check windows here
		local errorWindow = self.wndMain:FindChild("ErrorWindow")
		if errorWindow then
			if bResetWasSuccessful == true then
				self:OnNoExistingInstance()
			else
				errorWindow:Show(true)
				Apollo.CreateTimer("InstanceSettings_MessageDisplayTimer", 4, false)
			end
		end
	end
end

function InstanceSettings:OnExitInstance()
	GameLib.LeavePendingRemovalInstance()
end

function InstanceSettings:OnPendingWorldRemovalWarning()
	local nRemaining = GameLib.GetPendingRemovalWarningRemaining()
	if nRemaining > 0 then
		self:CloseForms()
		self.wndPendingRemoval = Apollo.LoadForm(self.xmlDoc , "InstanceSettingsPendingRemoval", nil, self)
		self.wndPendingRemoval:Invoke()
		self.wndPendingRemoval:FindChild("RemovalCountdownLabel"):SetText(nRemaining)
		self.wndPendingRemoval:SetData(nRemaining)
		Apollo.CreateTimer("InstanceSettings_PendingRemovalTimer", 1, true)
	end	
end

function InstanceSettings:OnPendingWorldRemovalCancel()
	if self.wndPendingRemoval then
		self.wndPendingRemoval:Close()
		self.wndPendingRemoval:Destroy()
	end
	Apollo.StopTimer("InstanceSettings_PendingRemovalTimer")
end

function InstanceSettings:OnMessageDisplayTimer()
	if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsShown() then
		-- dialog may have been destroyed ... so we have to check windows here
		local errorWindow = self.wndMain:FindChild("ErrorWindow")
		if errorWindow then
			errorWindow:Show(false)
			self.wndMain:FindChild("ResetInstanceButton"):Enable(true)
			self.wndMain:FindChild("EnterButton"):Enable(true)
		end
	
	end
end

function InstanceSettings:OnPendingRemovalTimer()
	if self.wndPendingRemoval then
		local nRemaining = self.wndPendingRemoval:GetData()
		nRemaining = nRemaining - 1
		self.wndPendingRemoval:FindChild("RemovalCountdownLabel"):SetText(nRemaining)
		self.wndPendingRemoval:SetData(nRemaining)
	end
end

function InstanceSettings:OnNoExistingInstance()

	-- difficulty settings
	self.wndMain:FindChild("NormalDifficultyBtn"):Enable(self.bNormalIsAllowed)
	
	self.wndMain:FindChild("VeteranDifficultyBtn"):Show(not self.bHasPrimeLevels)
	self.wndMain:FindChild("VeteranDifficultyBtn"):Enable(not self.bHasPrimeLevels and self.bVeteranIsAllowed)
	
	self.wndMain:FindChild("PrimeDifficultyBtn"):Show(self.bHasPrimeLevels)
	self.wndMain:FindChild("PrimeDifficultyBtn"):Enable(self.bHasPrimeLevels and self.bVeteranIsAllowed)
	
	if self.bVeteranIsAllowed and self.bHasPrimeLevels then
		self.wndMain:FindChild("DifficultyOptions"):SetRadioSel("InstanceSettings_LocalRadioGroup_Difficulty", LuaCodeEnumDifficultyTypes.Prime)
		self:SetPrimeDifficultyControls()
	elseif self.bVeteranIsAllowed then
		self.wndMain:FindChild("DifficultyOptions"):SetRadioSel("InstanceSettings_LocalRadioGroup_Difficulty", LuaCodeEnumDifficultyTypes.Veteran)
		self:SetVeteranDifficultyControls()
	else
		self.wndMain:FindChild("DifficultyOptions"):SetRadioSel("InstanceSettings_LocalRadioGroup_Difficulty", LuaCodeEnumDifficultyTypes.Normal)
		self:SetNormalDifficultyControls()
	end
	
	self.wndMain:FindChild("EnterButton"):Enable(self.bNormalIsAllowed or self.bVeteranIsAllowed)
	self.wndMain:FindChild("NewInstanceSettings"):Show(true)
	self.wndMain:FindChild("ExistingInstanceSettings"):Show(false)
end

function InstanceSettings:OnOK()
	local eDifficulty = self.wndMain:FindChild("DifficultyOptions"):GetRadioSel("InstanceSettings_LocalRadioGroup_Difficulty")
	local nRally = self.wndMain:FindChild("SubOptions"):GetRadioSel("InstanceSettings_LocalRadioGroup_Rallying")
	if LuaCodeEnumDifficultyTypes.Prime == eDifficulty then
		eDifficulty = GroupLib.Difficulty.Veteran
		nRally = 0
	elseif LuaCodeEnumDifficultyTypes.Veteran == eDifficulty then
		eDifficulty = GroupLib.Difficulty.Veteran
		nRally = 0
		self.nSelectedPrimeLevel = 0
	else
		eDifficulty = GroupLib.Difficulty.Normal
		self.nSelectedPrimeLevel = 0
	end

	GameLib.SetInstanceSettings(eDifficulty, nRally, self.nSelectedPrimeLevel)
	self:CloseForms()
end

function InstanceSettings:OnReset()
	self.wndMain:FindChild("ResetInstanceButton"):Enable(false)
	self.wndMain:FindChild("EnterButton"):Enable(false)
	GameLib.ResetSingleInstance()
end

function InstanceSettings:OnHideDialog(bNeedToNotifyServer)
	if self.bHidingInterface == false then
		self.bHidingInterface = true
		GameLib.OnClosedInstanceSettings(bNeedToNotifyServer)
		self:DestroyAll()
	end
end

function InstanceSettings:OnWindowClosed(wndHandler, wndControl)
	if self.wndMain and wndControl == self.wndMain:FindChild("PrimeLevelList") then
		return
	end
	
	self:OnHideDialog(true) -- we must tell the server about this 
end

function InstanceSettings:CloseForms()
	if self.wndMain then
		self.wndMain:Close()
	elseif self.wndWaiting then
		self.wndWaiting:Close()
	end
end

function InstanceSettings:OnChangeWorld()
	self:OnPendingWorldRemovalWarning()
end

function InstanceSettings:DestroyAll()
	if self.wndMain and self.wndMain:IsValid() then
		self.locSavedMainLoc = self.wndMain:GetLocation()
		self.wndMain:Destroy()
		self.wndMain = nil
	end

	if self.wndWaiting and self.wndWaiting:IsValid() then
		self.locSavedWatingLoc = self.wndWaiting:GetLocation()
		self.wndWaiting:Destroy()
		self.wndWaiting = nil
	end
end

---------------------------------------------------------------------------------------------------
-- PrimeLevelEntry Functions
---------------------------------------------------------------------------------------------------

function InstanceSettings:OnPrimeLevelSelected( wndHandler, wndControl, eMouseButton )
	self.nSelectedPrimeLevel = wndControl:GetParent():GetData()
	
	local strText = String_GetWeaselString(Apollo.GetString("MatchMaker_PrimeLevel"), self.nSelectedPrimeLevel)
	local wndPrimeBtn = self.wndMain:FindChild("PrimeLevelBtn")
	wndPrimeBtn:SetText(strText)
	wndPrimeBtn:SetCheck(false)
end

---------------------------------------------------------------------------------------------------
-- InstanceSettingsForm Functions
---------------------------------------------------------------------------------------------------

function InstanceSettings:SetNormalDifficultyControls()
	self.wndMain:FindChild("PrimeLevelContainer"):Show(false)
	self.wndMain:FindChild("ScalingIsForced"):Show(false)

	if self.bScalingIsAllowed then
		self.wndMain:FindChild("LevelScalingButton"):Enable(true)
		self.wndMain:FindChild("LevelScalingButton"):Show(true)
		
		local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
		self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nTop + 343)
	end
end

function InstanceSettings:SetVeteranDifficultyControls()
	self.wndMain:FindChild("PrimeLevelContainer"):Show(false)
	self.wndMain:FindChild("ScalingIsForced"):Show(true)
	self.wndMain:FindChild("LevelScalingButton"):Enable(false)
	self.wndMain:FindChild("LevelScalingButton"):Show(false)
	
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nTop + 343)
end

function InstanceSettings:SetPrimeDifficultyControls()
	self.wndMain:FindChild("PrimeLevelContainer"):Show(true)
	self.wndMain:FindChild("ScalingIsForced"):Show(false)
	self.wndMain:FindChild("LevelScalingButton"):Enable(false)
	self.wndMain:FindChild("LevelScalingButton"):Show(false)
	
	if not self.nSelectedPrimeLevel or self.nSelectedPrimeLevel == 0 then
		self.nSelectedPrimeLevel = self.nMaxPrimeLevelGroup
	end
	
	local wndPrimeBtn = self.wndMain:FindChild("PrimeLevelBtn")
	local strBtnText = String_GetWeaselString(Apollo.GetString("MatchMaker_PrimeLevel"), self.nSelectedPrimeLevel)
	wndPrimeBtn:SetText(strBtnText)
	wndPrimeBtn:SetCheck(false)

	local wndTierSel = self.wndMain:FindChild("PrimeLevelList")
	wndTierSel:DestroyChildren()

	self.wndMain:BringDescendantToTop(wndTierSel)
	self.wndMain:BringDescendantToTop(wndPrimeBtn)	
	
	for nPrimeLevel=0, self.nMaxPrimeLevelWorld do
		local wndPrimeLevel = Apollo.LoadForm(self.xmlDoc, "PrimeLevelEntry", wndTierSel, self)
		wndPrimeLevel:SetData(nPrimeLevel)
		
		local label = String_GetWeaselString(Apollo.GetString("MatchMaker_PrimeLevel"), nPrimeLevel)
		if self.nMaxPrimeLevelGroup < nPrimeLevel then
			wndPrimeLevel:Enable(false)
			wndPrimeLevel:FindChild("Label"):SetTextColor("UI_BtnTextHoloListDisabled")
		end
			
		if nPrimeLevel == self.nSelectedPrimeLevel then
			wndPrimeLevel:FindChild("Button"):SetCheck(true)
		end

		wndPrimeLevel:FindChild("Label"):SetText(label)
	end
		
	wndTierSel:ArrangeChildrenVert()

	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nTop + 343)
end

function InstanceSettings:OnDifficultyChecked( wndHandler, wndControl, eMouseButton )
	if wndControl == self.wndMain:FindChild("NormalDifficultyBtn") then
		self:SetNormalDifficultyControls()
	elseif wndControl == self.wndMain:FindChild("PrimeDifficultyBtn") then
		self:SetPrimeDifficultyControls()
	elseif wndControl == self.wndMain:FindChild("VeteranDifficultyBtn") then
		self:SetVeteranDifficultyControls()
	end
end

local InstanceSettingsInst = InstanceSettings:new()
InstanceSettingsInst:Init()

