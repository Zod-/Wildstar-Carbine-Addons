-----------------------------------------------------------------------------------------------
-- Client Lua Script for OptionsInterface
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "PlayerPathLib"

-- Settings are saved in a g_InterfaceOptions table. This allows 3rd party add-ons to carry over settings instantly if they reimplement an add-on.

local OptionsInterface = {}

local knSaveVersion = 7

function OptionsInterface:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.tTrackedWindowsByName = {}
	o.tSavedWindowsByName = {}

    return o
end

function OptionsInterface:Init()
    Apollo.RegisterAddon(self, true, Apollo.GetString("CRB_Interface"))
end

function OptionsInterface:OnLoad() -- OnLoad then GetAsyncLoad then OnRestore
	self.tTrackedWindows = {}
	self.tTrackedWindowsByName = {}

	self.bUIScaleTimerActive = false
	self.nWindowConstraints  = 75

	self:HelperSetUpGlobalIfNil()

	-- Set up defaults
	g_InterfaceOptions.Carbine.bSpellErrorMessages 			= true
	g_InterfaceOptions.Carbine.bShowTutorials				= true
	g_InterfaceOptions.Carbine.bQuestTrackerByDistance		= true
	g_InterfaceOptions.Carbine.bInteractTextOnUnit			= false
	g_InterfaceOptions.Carbine.bAreQuestUnitCalloutsVisible	= true
	g_InterfaceOptions.Carbine.bAreSettlerStructureCalloutsVisible = true
	g_InterfaceOptions.Carbine.bIsIgnoringDuelRequests		= false
	g_InterfaceOptions.Carbine.eShareChallengePreference	= GameLib.SharedChallengePreference.AutoAccept
	g_InterfaceOptions.Carbine.bQuestZoneFilter				= true
	g_InterfaceOptions.Carbine.bMyUnitFrameFlipped 			= true
	g_InterfaceOptions.Carbine.bTargetFrameFlipped 			= false
	g_InterfaceOptions.Carbine.bFocusFrameFlipped 			= false

	self.xmlDoc = XmlDoc.CreateFromFile("OptionsInterface.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function OptionsInterface:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	if tSavedData then
		if tSavedData.tSavedInterfaceOptions.Carbine then
			for key, value in pairs(tSavedData.tSavedInterfaceOptions.Carbine) do
				g_InterfaceOptions.Carbine[key] = value
			end
		end

		if tSavedData.tTrackedWindowsByName then
			self.tSavedWindowsByName = tSavedData.tTrackedWindowsByName
		end

		if tSavedData.nWindowConstraints then
			self.nWindowConstraints = tSavedData.nWindowConstraints
		end
	end
	
	self:OnWindowManagementLoadComplete()
end

function OptionsInterface:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	self:HelperSetUpGlobalIfNil()

	local tSavedData =
	{
		nSaveVersion = knSaveVersion,
		tSavedInterfaceOptions = g_InterfaceOptions,
		tTrackedWindowsByName = self.tTrackedWindowsByName,
		nWindowConstraints = self.nWindowConstraints,
	}
	return tSavedData
end

function OptionsInterface:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	
	Apollo.RegisterEventHandler("ResolutionChanged",					"OnResolutionChanged", self)
	Apollo.RegisterEventHandler("ApplicationWindowSizeChanged",	"OnApplicationWindowSizeChanged", self)
	Apollo.RegisterEventHandler("TopLevelWindowMove",				"OnTopLevelWindowMove", self)
	Apollo.RegisterEventHandler("CharacterFlagsUpdated", 			"OnCharacterFlagsUpdated", self)

	Apollo.RegisterEventHandler("ChallengeLog_UpdateShareChallengePreference", 	"OnUpdateShareChallengePreference", self)
	Apollo.RegisterEventHandler("OptionsUpdated_HUDTriggerTutorial", 			"OnTriggerTutorial", self)
	Apollo.RegisterEventHandler("OptionsUpdated_HUDPreferences", 				"InitializeControls", self)
	Apollo.RegisterEventHandler("Dialog_ShowPvpFlagWarningChanged",			"OnDialog_ShowPvpFlagWarningChanged", self)

	Apollo.RegisterTimerHandler("OptionsInterface_UIScaleDelayTimer", 			"OnUIScaleDelayTimer", self)

	Apollo.CreateTimer("OptionsInterface_UIScaleDelayTimer", 1.3, false)
	Apollo.StopTimer("OptionsInterface_UIScaleDelayTimer")

	self.wndInterface = Apollo.LoadForm(self.xmlDoc, "OptionsInterfaceForm", nil, self)
	self.wndInterface:Show(false, true)
	self.wndInterface:FindChild("GeneralBtn"):SetCheck(true)

	self.bResizeTimerRunning = false
	Apollo.RegisterTimerHandler("WindowManagementResizeTimer", "OnWindowManagementResizeTimer", self)
	Apollo.CreateTimer("WindowManagementResizeTimer", 1.0, false)
	Apollo.StopTimer("WindowManagementResizeTimer")

	Apollo.RegisterTimerHandler("WindowManagementAddAllWindowsTimer", "ReDrawTrackedWindows", self)
	Apollo.CreateTimer("WindowManagementAddAllWindowsTimer", 0.5, false)
	Apollo.StopTimer("WindowManagementAddAllWindowsTimer")

	self.wndInterface:FindChild("ConstrainSlider"):SetValue(self.nWindowConstraints)
	self.wndInterface:FindChild("ConstrainEditBox"):SetText(string.format("%s%%", self.nWindowConstraints))

	if g_InterfaceOptions.Carbine.bAreQuestUnitCalloutsVisible ~= GameLib.AreQuestUnitCalloutsVisible() then
		GameLib.ToggleQuestUnitCallouts()
	end

	-- GOTCHA: This doesn't actually persist between sessions, so we have to set it each time
	GameLib.SetSharedChallengePreference(g_InterfaceOptions.Carbine.eShareChallengePreference or 0)

	GameLib.SetIgnoreDuelRequests(g_InterfaceOptions.Carbine.bIsIgnoringDuelRequests)

	if g_InterfaceOptions.Carbine.bAreQuestUnitCalloutsVisible ~= GameLib.AreQuestUnitCalloutsVisible() then
		GameLib.ToggleQuestUnitCallouts()
	end
	
	if g_InterfaceOptions.Carbine.bAreSettlerStructureCalloutsVisible ~= GameLib.AreSettlerStructureCalloutsVisible() then
		GameLib.ToggleSettlerStructureCallouts()
	end

	Event_FireGenericEvent("OptionsUpdated_QuestTracker")
	Event_FireGenericEvent("OptionsUpdated_HUDInteract")
	Event_FireGenericEvent("OptionsUpdated_Floaters")

	self.mapDDParents = {
		--hud options
		{
			wnd = self.wndInterface:FindChild("DropToggleMyUnitFrame"),
			nConsoleVar = "hud.myUnitFrameDisplay",
			strRadioGroup = "HUDMyUnitFrameGroup",
		},
		{
			wnd = self.wndInterface:FindChild("DropToggleFocusTargetFrame"),
			nConsoleVar = "hud.focusTargetFrameDisplay",
			strRadioGroup = "HUDFocusTargetFrameGroup"
		},
		{
			wnd = self.wndInterface:FindChild("DropToggleTargetOfTargetFrame"),
			nConsoleVar = "hud.targetOfTargetFrameDisplay",
			strRadioGroup = "HUDTargetOfTargetFrameGroup"
		},
		{
			wnd = self.wndInterface:FindChild("DropToggleSkillsBar"),
			nConsoleVar = "hud.skillsBarDisplay",
 			strRadioGroup = "HUDSkillsGroup",
		},
		{
			wnd = self.wndInterface:FindChild("DropToggleResource"),
			nConsoleVar = "hud.resourceBarDisplay",
 			strRadioGroup = "HUDResourceGroup"
		},
		{
			wnd = self.wndInterface:FindChild("DropToggleSecondaryLeft"),
			nConsoleVar = "hud.secondaryLeftBarDisplay",
			strRadioGroup = "HUDSecondaryLeftGroup"},
		{
			wnd = self.wndInterface:FindChild("DropToggleSecondaryRight"),
			nConsoleVar = "hud.secondaryRightBarDisplay",
			strRadioGroup = "HUDSecondaryRightGroup"},
		{
			wnd = self.wndInterface:FindChild("DropToggleXP"),
			nConsoleVar = "hud.xpBarDisplay",
 			strRadioGroup = "HUDXPGroup",
		},
		{
			wnd = self.wndInterface:FindChild("DropToggleMount"),
			nConsoleVar = "hud.mountButtonDisplay",
			strRadioGroup = "HUDMountGroup"
		},
		{
			wnd = self.wndInterface:FindChild("DropToggleTime"),
			nConsoleVar = "hud.timeDisplay",
			strRadioGroup = "HUDTimeGroup"
		},
		{
			wnd = self.wndInterface:FindChild("DropToggleHealthText"),
			nConsoleVar = "hud.healthTextDisplay",
			strRadioGroup = "HUDHealthTextGroup"
		},
	}

	for idx, wndDD in pairs(self.mapDDParents) do
		wndDD.wnd:AttachWindow(wndDD.wnd:FindChild("ChoiceContainer"))
		wndDD.wnd:FindChild("ChoiceContainer"):Show(false)
	end

	self:InitializeControls()
	Event_FireGenericEvent("RequestShowPvpFlagWarningState")
	
	self:OnWindowManagementLoadComplete()
end

function OptionsInterface:OnWindowManagementLoadComplete()
	if self.bLoadCalledOnce then
		Apollo.RegisterEventHandler("WindowManagementRegister", "OnWindowManagementRegister", self)
		Apollo.RegisterEventHandler("WindowManagementAdd", "OnWindowManagementAdd", self)
		Apollo.RegisterEventHandler("WindowManagementRemove", "OnWindowManagementRemove", self)
	
		Event_FireGenericEvent("WindowManagementReady")
	end
	self.bLoadCalledOnce = true
end

function OptionsInterface:OnWindowManagementResizeTimer()
	self.bResizeTimerRunning = false
	self:ReDrawTrackedWindows()
end

function OptionsInterface:OnGeneralOptionsCheck(wndHandler, wndControl)
	self.wndInterface:FindChild("Content:General"):Show(true)
	self.wndInterface:FindChild("Content:HUD"):Show(false)
	self.wndInterface:FindChild("Content:WindowContent"):Show(false)
end

function OptionsInterface:OnHUDOptionsCheck(wndHandler, wndControl)
	self.wndInterface:FindChild("Content:General"):Show(false)
	self.wndInterface:FindChild("Content:HUD"):Show(true)
	self.wndInterface:FindChild("Content:WindowContent"):Show(false)
end

function OptionsInterface:OnWindowOptionsCheck(wndHandler, wndControl)
	self.wndInterface:FindChild("Content:General"):Show(false)
	self.wndInterface:FindChild("Content:HUD"):Show(false)
	self.wndInterface:FindChild("Content:WindowContent"):Show(true)
end

function OptionsInterface:OnCloseWindow()
	self.wndInterface:Close()
end

function OptionsInterface:OnConfigure() -- From ESC -> Options
	self.wndInterface:MoveToLocation((self.wndInterface:GetOriginalLocation()))
	self.wndInterface:Invoke()

	local fTooltip = Apollo.GetConsoleVariable("ui.TooltipDelay") or 0
	self.wndInterface:FindChild("TooltipDelaySliderBar"):SetValue(fTooltip)
	self.wndInterface:FindChild("TooltipDelayLabel"):SetText(String_GetWeaselString(Apollo.GetString("InterfaceOptions_TooltipDelay"), fTooltip))

	local fUIScale = Apollo.GetConsoleVariable("ui.Scale") or 1
	self.wndInterface:FindChild("UIScaleSliderBar"):SetValue(fUIScale)
	self.wndInterface:FindChild("UIScaleLabel"):SetText(String_GetWeaselString(Apollo.GetString("InterfaceOptions_UIScale"), fUIScale))

	self.wndInterface:FindChild("IgnoreDuelRequests"):SetCheck(g_InterfaceOptions.Carbine.bIsIgnoringDuelRequests)
	self.wndInterface:FindChild("ToggleQuestMarkers"):SetCheck(g_InterfaceOptions.Carbine.bAreQuestUnitCalloutsVisible)
	self.wndInterface:FindChild("ToggleSettlerStructureMarkers"):Enable(self.wndInterface:FindChild("ToggleQuestMarkers"):IsChecked() and PlayerPathLib.GetPlayerPathType() == PlayerPathLib.PlayerPathType_Settler)
	self.wndInterface:FindChild("ToggleSettlerStructureMarkers"):SetCheck(g_InterfaceOptions.Carbine.bAreSettlerStructureCalloutsVisible)
	self.wndInterface:FindChild("SpellErrorMessages"):SetCheck(g_InterfaceOptions.Carbine.bSpellErrorMessages)
	self.wndInterface:FindChild("ChallengeSharePreference"):SetCheck(g_InterfaceOptions.Carbine.eShareChallengePreference == GameLib.SharedChallengePreference.Prompt)
	self.wndInterface:FindChild("InteractTextOnUnit"):SetCheck(g_InterfaceOptions.Carbine.bInteractTextOnUnit)
	self.wndInterface:FindChild("DropToggleTargetFrame"):Enable(false)
	self.wndInterface:FindChild("TargetUnitFrame"):SetRadioSel("TargetFrameFilpped", g_InterfaceOptions.Carbine.bTargetFrameFlipped and 1 or 2)
	self.wndInterface:FindChild("MyUnitFrame"):SetRadioSel("MyUnitFrameFlipped", g_InterfaceOptions.Carbine.bMyUnitFrameFlipped and 1 or 2)
	self.wndInterface:FindChild("FocusUnitFrame"):SetRadioSel("FocusFrameFlipped", g_InterfaceOptions.Carbine.bFocusFrameFlipped and 1 or 2)
end

function OptionsInterface:HelperSetUpGlobalIfNil()
	if not g_InterfaceOptions or g_InterfaceOptions == nil then
		g_InterfaceOptions = {}
		g_InterfaceOptions.Carbine = {}
	elseif g_InterfaceOptions.Carbine == nil then -- GOTCHA: Use nil specifically and don't check for false
		g_InterfaceOptions.Carbine = {}
	end
end

function OptionsInterface:InitializeControls()
	for idx, parent in pairs(self.mapDDParents) do
		if parent.wnd ~= nil and parent.nConsoleVar ~= nil and parent.strRadioGroup ~= nil then

			local arBtns = parent.wnd:FindChild("ChoiceContainer"):GetChildren()

			for idxBtn = 1, #arBtns do
				arBtns[idxBtn]:SetCheck(false)
			end

			self.wndInterface:SetRadioSel(parent.strRadioGroup, Apollo.GetConsoleVariable(parent.nConsoleVar))
			if arBtns[Apollo.GetConsoleVariable(parent.nConsoleVar)] ~= nil then
				arBtns[Apollo.GetConsoleVariable(parent.nConsoleVar)]:SetCheck(true)
			end

			local strLabel = Apollo.GetString("Options_Unspecified")
			for idxBtn = 1, #arBtns do
				if arBtns[idxBtn]:IsChecked() then
					strLabel = arBtns[idxBtn]:GetText()
				end
			end

			parent.wnd:SetText(strLabel)
		end
	end
end

function OptionsInterface:OnHUDRadio(wndHandler, wndControl)
	for idx, wndDD in pairs(self.mapDDParents) do
		if wndDD.wnd == wndControl:GetParent():GetParent() then
			Apollo.SetConsoleVariable(wndDD.nConsoleVar, wndControl:GetParent():GetRadioSel(wndDD.strRadioGroup))
			wndControl:GetParent():GetParent():SetText(wndControl:GetText())
			break
		end
	end

	Event_FireGenericEvent("OptionsUpdated_HUDPreferences")
	wndControl:GetParent():Show(false)
end

function OptionsInterface:OnTriggerTutorial(controlKey)
	Apollo.SetConsoleVariable("hud."..controlKey, 1)

	Event_FireGenericEvent("OptionsUpdated_HUDPreferences")
end

function OptionsInterface:OnUpdateShareChallengePreference(ePreference)
	GameLib.SetSharedChallengePreference(ePreference) -- This is not saved on the client or server
	g_InterfaceOptions.Carbine.eShareChallengePreference = ePreference
end

function OptionsInterface:OnTogglePromptAcceptingPvpQuests()
	local bShowPvpFlagWarning = self.wndInterface:FindChild("Content:General:OptionsFrame:PromptAcceptingPvpQuests"):IsChecked()
	Event_FireGenericEvent("OptionsInterface_ShowPvpFlagWarningChanged", bShowPvpFlagWarning)
end

function OptionsInterface:OnDialog_ShowPvpFlagWarningChanged(bShowPvpFlagWarning)
	if self.wndInterface == nil or not self.wndInterface:IsValid() then
		return
	end
	
	local wndOptionsFrame = self.wndInterface:FindChild("Content:General:OptionsFrame")
	local wndPromptAcceptingPvpQuests = wndOptionsFrame:FindChild("PromptAcceptingPvpQuests")
	
	if not wndPromptAcceptingPvpQuests:IsShown() then
		local wndSlidersContainer = wndOptionsFrame:FindChild("SlidersContainer")
		local nLeft, nTop, nRight, nBottom = wndSlidersContainer:GetAnchorOffsets()
		wndSlidersContainer:SetAnchorOffsets(nLeft, nTop + wndPromptAcceptingPvpQuests:GetHeight(), nRight, nBottom)
		wndPromptAcceptingPvpQuests:Show(true)
	end
	
	wndPromptAcceptingPvpQuests:SetCheck(bShowPvpFlagWarning)
end

-----------------------------------------------------------------------------------------------
-- Window Tracking
-----------------------------------------------------------------------------------------------

function OptionsInterface:OnWindowManagementRegister(tSettings)
	if tSettings == nil or tSettings.strName == nil or Apollo.StringLength(tSettings.strName) == 0 then
		return
	end
	
	tSettings.bHasMoved = false
	tSettings.bActiveEntry = false
	tSettings.nSaveVersion = tSettings.nSaveVersion or 1
	
	local tSavedWindow = self.tSavedWindowsByName[tSettings.strName]
	if tSavedWindow ~= nil and tSettings.nSaveVersion == tSavedWindow.nSaveVersion then
		tSettings.bDefaultMoveable = tSavedWindow.bMoveable
		tSettings.bMoveable = tSavedWindow.bMoveable
		tSettings.bDefaultRequireMetaKeyToMove = tSavedWindow.bRequireMetaKeyToMove
		tSettings.bRequireMetaKeyToMove = tSavedWindow.bRequireMetaKeyToMove
		tSettings.tCurrentLoc = tSavedWindow.tCurrentLoc
		tSettings.nPosX = tSavedWindow.nPosX
		tSettings.nPosY = tSavedWindow.nPosY
	end
	
	self.tTrackedWindowsByName[tSettings.strName] = tSettings
	
	Apollo.StopTimer("WindowManagementAddAllWindowsTimer")
	Apollo.StartTimer("WindowManagementAddAllWindowsTimer")
end

function OptionsInterface:OnWindowManagementAdd(tSettings)
	if tSettings == nil or tSettings.wnd == nil or not tSettings.wnd:IsValid() or tSettings.strName == nil or Apollo.StringLength(tSettings.strName) == 0 then
		return
	end
	
	local tTrackedWindow = self.tTrackedWindowsByName[tSettings.strName]
	if tTrackedWindow == nil then
		return
	end
	
	tTrackedWindow.tDefaultLoc = tSettings.wnd:GetLocation():ToTable()
	if tTrackedWindow.tCurrentLoc == nil then
		tTrackedWindow.tCurrentLoc = tTrackedWindow.tDefaultLoc
	end
	
	local tSavedWindow = self.tSavedWindowsByName[tSettings.strName]
	if tTrackedWindow.bActiveEntry or tSavedWindow == nil or tTrackedWindow.nSaveVersion ~= tSavedWindow.nSaveVersion then
		local bMetaKey = tSettings.wnd:IsStyleOn("RequireMetaKeyToMove")
		tTrackedWindow.bDefaultRequireMetaKeyToMove = bMetaKey
		tTrackedWindow.bRequireMetaKeyToMove = bMetaKey

		local bMoveable = tSettings.wnd:IsStyleOn("Moveable")
		if tSettings.bIsTabWindow then
			bMoveable = not tSettings.wnd:IsLocked()
		end
		tTrackedWindow.bMoveable = bMoveable
		tTrackedWindow.bDefaultMoveable = bMoveable
	end

	tSettings.wnd:SetStyle("Moveable", tTrackedWindow.bMoveable)
	
	local tDisplay = Apollo.GetDisplaySize()
	if tDisplay and tDisplay.nWidth and tDisplay.nHeight then
		local nMaxWidth, nMaxHeight = tSettings.wnd:GetSizingMaximum()
		
		nMaxWidth = nMaxWidth > 0 and math.min(nMaxWidth, tDisplay.nWidth) or tDisplay.nWidth
		nMaxHeight = nMaxHeight > 0 and math.min(nMaxHeight, tDisplay.nHeight) or tDisplay.nHeight
		
		tSettings.wnd:SetSizingMaximum(nMaxWidth, tDisplay.nHeight)

		if tTrackedWindow.bIsTabWindow then
			tSettings.wnd:Lock(not tTrackedWindow.bMoveable)
		end
		
		tSettings.wnd:SetStyle("RequireMetaKeyToMove", tTrackedWindow.bRequireMetaKeyToMove)
		tSettings.wnd:MoveToLocation(WindowLocation.new(tTrackedWindow.tCurrentLoc))
	end

	tTrackedWindow.bActiveEntry = true
	tTrackedWindow.wnd = tSettings.wnd
	self.tTrackedWindows[tSettings.wnd:GetId()] = tTrackedWindow

	Apollo.StopTimer("WindowManagementAddAllWindowsTimer")
	Apollo.StartTimer("WindowManagementAddAllWindowsTimer")
end

function OptionsInterface:OnWindowManagementRemove(tSettings)
	if tSettings == nil or tSettings.strName == nil or Apollo.StringLength(tSettings.strName) == 0 then
		return
	end
	
	local tTrackedWindow = self.tTrackedWindowsByName[tSettings.strName]
	if tTrackedWindow == nil then
		return
	end
	
	if tTrackedWindow.wnd ~= nil then
		self.tTrackedWindows[tTrackedWindow.wnd:GetId()] = nil
	end
	
	tTrackedWindow.wnd = nil
end

function OptionsInterface:ReDrawTrackedWindows()
	local wndContainer = self.wndInterface:FindChild("Content:WindowContent:List")

	if not wndContainer then return end

	wndContainer:DestroyChildren()

	for strName, tSettings in pairs(self.tTrackedWindowsByName) do
		if tSettings.bActiveEntry then
			if tSettings.wndForm then
				tSettings.wndForm:Destroy()
				tSettings.wndForm = nil
			end

			local wndSettings = Apollo.LoadForm(self.xmlDoc, "WindowEntry", wndContainer, self)
			tSettings.wndForm = wndSettings
			wndSettings:FindChild("WindowName"):SetText(tSettings.strName)
			wndSettings:FindChild("X:EditBox"):SetData(tSettings)
			wndSettings:FindChild("Y:EditBox"):SetData(tSettings)
			wndSettings:FindChild("ResetBtn"):SetData(tSettings)
			wndSettings:FindChild("Moveable"):SetData(tSettings)
			wndSettings:FindChild("MoveableKey"):SetData(tSettings)
		
			self:UpdateTrackedWindow(tSettings)
		end
	end

	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return (a:FindChild("WindowName"):GetText() < b:FindChild("WindowName"):GetText()) end)
end

function OptionsInterface:HasMoved(tSettings)
	local tCurrentOffsets = tSettings.tCurrentLoc.nOffsets
	local tDefaultOffsets = tSettings.tDefaultLoc.nOffsets

	return
		tCurrentOffsets[1] ~= tDefaultOffsets[1] or
		tCurrentOffsets[2] ~= tDefaultOffsets[2]
end

function OptionsInterface:UpdateTrackedWindow(tSettings)
	if tSettings == nil then
		return
	end
	
	local wndTracked = tSettings.wnd
	local strX= "-"
	local strXColor = ApolloColor.new("UI_TextHoloBody")
	local strY = "-"
	local strYColor = ApolloColor.new("UI_TextHoloBody")

	if tSettings.wnd ~= nil and tSettings.wnd:IsValid() then
		local nX, nY = wndTracked:GetPos()
		tSettings.tCurrentLoc = wndTracked:GetLocation():ToTable()
		local strConstrainLabelOutput = ""
		local tDisplay = Apollo.GetDisplaySize()
		if tDisplay and tDisplay.nWidth and tDisplay.nHeight then
			strConstrainLabelOutput = self.nWindowConstraints > 0 
				and String_GetWeaselString(Apollo.GetString("CRB_OptionsInterface_Constrain"), self.wndInterface:FindChild("ConstrainEditBox"):GetText(), tDisplay.nWidth, tDisplay.nHeight)
				or String_GetWeaselString(Apollo.GetString("CRB_OptionsInterface_ConstrainFull"))
			
			local tRect = {}
			tRect.l, tRect.t, tRect.r, tRect.b = wndTracked:GetRect()
			local nWidth = tRect.r - tRect.l
			local nHeight = tRect.b - tRect.t
			local nDeltaX = 0
			local nDeltaY = 0

			local nCurrentX, nCurrentY = wndTracked:GetPos()
			local nOffsetX = nWidth * self.nWindowConstraints / 100
			local nOffsetY = nHeight * self.nWindowConstraints / 100
			
			nDeltaX = (nCurrentX >= -1 * nOffsetX) and 0 or (-1 * nOffsetX - nCurrentX)
			nDeltaY = (nCurrentY >= -1 * nOffsetY) and 0 or (-1 * nOffsetY - nCurrentY)
			nDeltaX = (nCurrentX + nWidth > tDisplay.nWidth + nOffsetX) and -1 * (nCurrentX + nWidth - tDisplay.nWidth - nOffsetX) or nDeltaX
			nDeltaY = (nCurrentY + nHeight > tDisplay.nHeight + nOffsetY) and -1 * (nCurrentY + nHeight - tDisplay.nHeight - nOffsetY) or nDeltaY
			
			if nDeltaX ~= 0 then
				strXColor = ApolloColor.new("UI_WindowTextCraftingRedCapacitor")
			end
			if nDeltaY ~= 0 then
				strYColor = ApolloColor.new("UI_WindowTextCraftingRedCapacitor")
			end

			local tOffsets = tSettings.tCurrentLoc.nOffsets
			local tPoints = tSettings.tCurrentLoc.fPoints

			if self.nWindowConstraints < 100 then
				tSettings.tCurrentLoc.nOffsets = {
					tOffsets[1] + nDeltaX,
					tOffsets[2] + nDeltaY,
					tOffsets[3] + nDeltaX,
					tOffsets[4] + nDeltaY,
				}
			end
		end

		wndTracked:MoveToLocation(WindowLocation.new(tSettings.tCurrentLoc))

		tSettings.bHasMoved = self:HasMoved(tSettings)
		tSettings.nPosX = nX
		tSettings.nPosY = nY
		strX = nX
		strY = nY

		self.wndInterface:FindChild("Constrain"):SetTooltip(strConstrainLabelOutput)
	elseif tSettings.nPosX ~= nil and tSettings.nPosY ~= nil then
		strX = tostring(tSettings.nPosX)
		strY = tostring(tSettings.nPosY)
	end
	
	if tSettings.wndForm and tSettings.wndForm:IsValid() then
		local wndSettings = tSettings.wndForm
		wndSettings:FindChild("X:EditBox"):SetText(strX)
		wndSettings:FindChild("X:EditBox"):Enable(false)
		wndSettings:FindChild("X:EditBox"):SetTextColor(strXColor)
		wndSettings:FindChild("Y:EditBox"):SetText(strY)
		wndSettings:FindChild("Y:EditBox"):Enable(false)
		wndSettings:FindChild("Y:EditBox"):SetTextColor(strYColor)
		wndSettings:FindChild("ResetBtn"):Enable(tSettings.bHasMoved)
		wndSettings:FindChild("Moveable"):SetCheck(tSettings.bMoveable)
		wndSettings:FindChild("MoveableKey"):SetCheck(tSettings.bRequireMetaKeyToMove)
	end
	
	Event_FireGenericEvent("WindowManagementUpdate", tSettings)
end

function OptionsInterface:OnTopLevelWindowMove(wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom)
	if wndControl == nil or not wndControl:IsValid() then
		return
	end

	self:UpdateTrackedWindow(self.tTrackedWindows[wndControl:GetId()])
end

function OptionsInterface:OnApplicationWindowSizeChanged(tSize)
	if self.bResizeTimerRunning then
		Apollo.StopTimer("WindowManagementResizeTimer")
	end

	Apollo.StartTimer("WindowManagementResizeTimer")
	self.bResizeTimerRunning = true
end

function OptionsInterface:OnResolutionChanged(nScreenWidth, nScreenHeight)
	if self.bResizeTimerRunning then
		Apollo.StopTimer("WindowManagementResizeTimer")
	end

	Apollo.StartTimer("WindowManagementResizeTimer")
	self.bResizeTimerRunning = true
end

function OptionsInterface:RestoreWindow(tSettings)
	self.tTrackedWindowsByName[tSettings.strName].tCurrentLoc = tSettings.tDefaultLoc
	
	if tSettings.wnd ~= nil and tSettings.wnd:IsValid() then
		tSettings.wnd:MoveToLocation(WindowLocation.new(tSettings.tDefaultLoc))
		tSettings.bRequireMetaKeyToMove = tSettings.bDefaultRequireMetaKeyToMove
		tSettings.bMoveable = tSettings.bDefaultMoveable
		tSettings.wnd:SetStyle("Moveable", tSettings.bMoveable)
		tSettings.wnd:SetStyle("RequireMetaKeyToMove", tSettings.bRequireMetaKeyToMove)
	end
	self:UpdateTrackedWindow(tSettings)
end

function OptionsInterface:OnResetAllBtn(wndHandler, wndControl)
	for idx, tSettings in pairs(self.tTrackedWindows) do
		self:RestoreWindow(tSettings)
	end
end

function OptionsInterface:OnResetBtn(wndHandler, wndControl)
	self:RestoreWindow(wndControl:GetData())
end

function OptionsInterface:OnConstrainSliderChanged(wndHandler, wndControl, fValue)
	self.nWindowConstraints = fValue
	self.wndInterface:FindChild("ConstrainEditBox"):SetText(string.format("%s%%", fValue))
	
	local tDisplay = Apollo.GetDisplaySize()
	if tDisplay and tDisplay.nWidth and tDisplay.nHeight then
		self.wndInterface:FindChild("Constrain"):SetTooltip(fValue > 0 
			and String_GetWeaselString(Apollo.GetString("CRB_OptionsInterface_Constrain"), self.wndInterface:FindChild("ConstrainEditBox"):GetText(), tDisplay.nWidth, tDisplay.nHeight)
			or String_GetWeaselString(Apollo.GetString("CRB_OptionsInterface_ConstrainFull"))
		)
	end
end

function OptionsInterface:OnMoveableChecked(wndHandler, wndControl)
	local tSettings = wndControl:GetData()

	if tSettings then
		tSettings.bMoveable = not tSettings.bMoveable
		tSettings.bRequireMetaKeyToMove = tSettings.bRequireMetaKeyToMove and tSettings.bMoveable

		if tSettings.bIsTabWindow then
			tSettings.wnd:Lock(not tSettings.bMoveable)
		end

		if tSettings.wnd ~= nil and tSettings.wnd:IsValid() then
			tSettings.wnd:SetStyle("Moveable", tSettings.bMoveable)
			tSettings.wnd:SetStyle("RequireMetaKeyToMove", tSettings.bRequireMetaKeyToMove)
		end
		
		tSettings.wndForm:FindChild("MoveableKey"):SetCheck(tSettings.bRequireMetaKeyToMove)
		self:UpdateTrackedWindow(tSettings)
		
		local tTrackedWindow = self.tTrackedWindowsByName[tSettings.strName]
		if tTrackedWindow and tTrackedWindow.wndForm then
			tTrackedWindow.wndForm:FindChild("ResetBtn"):Enable(true)
		end
	end
end

function OptionsInterface:OnMoveableKeyChecked(wndHandler, wndControl)
	local tSettings = wndControl:GetData()

	if tSettings then
		tSettings.bRequireMetaKeyToMove = not tSettings.bRequireMetaKeyToMove
		tSettings.bMoveable = tSettings.bRequireMetaKeyToMove and true or tSettings.bMoveable
		
		if tSettings.wnd ~= nil and tSettings.wnd:IsValid() then
			tSettings.wnd:SetStyle("Moveable", tSettings.bMoveable)
			tSettings.wnd:SetStyle("RequireMetaKeyToMove", tSettings.bRequireMetaKeyToMove)
		end
		
		tSettings.wndForm:FindChild("Moveable"):SetCheck(tSettings.bMoveable)
		self:UpdateTrackedWindow(tSettings)
		local tTrackedWindow = self.tTrackedWindowsByName[tSettings.strName]
		if tTrackedWindow and tTrackedWindow.wndForm then
			tTrackedWindow.wndForm:FindChild("ResetBtn"):Enable(true)
		end
	end
end

-----------------------------------------------------------------------------------------------
-- Buttons
-----------------------------------------------------------------------------------------------

function OptionsInterface:OnCharacterFlagsUpdated()
	if self.wndInterface == nil or not self.wndInterface:IsShown() then
		return
	end
	self.wndInterface:FindChild("IgnoreDuelRequests"):SetCheck(GameLib.IsIgnoringDuelRequests())
end

function OptionsInterface:OnMappedOptionsQuestCallouts(wndHandler, wndControl)
	GameLib.ToggleQuestUnitCallouts()
	g_InterfaceOptions.Carbine.bAreQuestUnitCalloutsVisible = GameLib.AreQuestUnitCalloutsVisible()
	g_InterfaceOptions.Carbine.bAreSettlerStructureCalloutsVisible = g_InterfaceOptions.Carbine.bAreQuestUnitCalloutsVisible
	self.wndInterface:FindChild("ToggleSettlerStructureMarkers"):SetCheck(g_InterfaceOptions.Carbine.bAreSettlerStructureCalloutsVisible)
	Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("InterfaceOptions_QuestCalloutsToggle"), wndControl:IsChecked() and Apollo.GetString("Command_Chat_True") or Apollo.GetString("Command_Chat_False")))
	if g_InterfaceOptions.Carbine.bAreQuestUnitCalloutsVisible and PlayerPathLib.GetPlayerPathType() == PlayerPathLib.PlayerPathType_Settler then
		self.wndInterface:FindChild("ToggleSettlerStructureMarkers"):Enable(true)
	else
		self.wndInterface:FindChild("ToggleSettlerStructureMarkers"):Enable(false)
	end
end

function OptionsInterface:OnMappedOptionsSettlerStructureCallouts(wndHandler, wndControl)
	GameLib.ToggleSettlerStructureCallouts()
	g_InterfaceOptions.Carbine.bAreSettlerStructureCalloutsVisible = GameLib.AreSettlerStructureCalloutsVisible()
	Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("InterfaceOptions_SettlerStructureCalloutsToggle"), wndControl:IsChecked() and Apollo.GetString("Command_Chat_True") or Apollo.GetString("Command_Chat_False")))
end

function OptionsInterface:OnMappedOptionsSetIgnoreDuels(wndHandler, wndControl)
	GameLib.SetIgnoreDuelRequests(true)
	g_InterfaceOptions.Carbine.bIsIgnoringDuelRequests = GameLib.IsIgnoringDuelRequests()
	Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("InterfaceOptions_IgnoreDuelsToggle"), Apollo.GetString("Command_Chat_True")))
end

function OptionsInterface:OnMappedOptionsUnsetIgnoreDuels(wndHandler, wndControl)
	GameLib.SetIgnoreDuelRequests(false)
	g_InterfaceOptions.Carbine.bIsIgnoringDuelRequests = GameLib.IsIgnoringDuelRequests()
	Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("InterfaceOptions_IgnoreDuelsToggle"), Apollo.GetString("Command_Chat_False")))
end

function OptionsInterface:OnTargetOfTargetToggle(wndHandler, wndControl)
	Event_FireGenericEvent("GenericEvent_ToggleNameplate_bDrawToT", wndHandler:IsChecked())
end

function OptionsInterface:OnUIScaleSliderBarChanged(wndHandler, wndControl, fValue)
	self.wndInterface:FindChild("UIScaleLabel"):SetData(fValue)
	self.wndInterface:FindChild("UIScaleLabel"):SetText(String_GetWeaselString(Apollo.GetString("InterfaceOptions_UIScale"), fValue))
	if not self.bUIScaleTimerActive then
		self.bUIScaleTimerActive = true
		Apollo.StopTimer("OptionsInterface_UIScaleDelayTimer")
		Apollo.StartTimer("OptionsInterface_UIScaleDelayTimer", fValue)
	end
end

function OptionsInterface:OnUIScaleDelayTimer(fValue)
	if not fValue then
		fValue = self.wndInterface:FindChild("UIScaleLabel"):GetData() or 1
	end
	Apollo.SetConsoleVariable("ui.Scale", fValue)
	self.bUIScaleTimerActive = false
end

function OptionsInterface:OnTooltipDelaySliderBarChanged(wndHandler, wndControl, fValue)
	self.wndInterface:FindChild("TooltipDelayLabel"):SetText(String_GetWeaselString(Apollo.GetString("InterfaceOptions_TooltipDelay"), fValue))
	Apollo.SetConsoleVariable("ui.TooltipDelay", fValue)
end

function OptionsInterface:OnToggleSpellIconTooltip(wndHandler, wndControl)
	Apollo.SetConsoleVariable("ui.actionBarTooltipsOnCursor", wndControl:IsChecked())
	Event_FireGenericEvent("Options_UpdateActionBarTooltipLocation")
end

function OptionsInterface:OnToggleSpellErrorMessages(wndHandler, wndControl)
	g_InterfaceOptions.Carbine.bSpellErrorMessages = wndHandler:IsChecked()
	Event_FireGenericEvent("OptionsUpdated_Floaters")
	Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("InterfaceOptions_SpellErrorToggle"), wndControl:IsChecked() and Apollo.GetString("Command_Chat_True") or Apollo.GetString("Command_Chat_False")))
end

function OptionsInterface:OnToggleChallengeSharePreference(wndHandler, wndControl)	
	g_InterfaceOptions.Carbine.eShareChallengePreference = wndHandler:IsChecked() and GameLib.SharedChallengePreference.Prompt or GameLib.SharedChallengePreference.AutoAccept
	GameLib.SetSharedChallengePreference(g_InterfaceOptions.Carbine.eShareChallengePreference)
	Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("InterfaceOptions_ChallengeShareToggle"), wndControl:IsChecked() and Apollo.GetString("Command_Chat_True") or Apollo.GetString("Command_Chat_False")))
end

function OptionsInterface:OnUnitFrameRotateClicked(wndHandler, wndControl)
	g_InterfaceOptions.Carbine.bMyUnitFrameFlipped 	= self.wndInterface:FindChild("MyUnitFrame"):GetRadioSel("MyUnitFrameFlipped") == 1
	g_InterfaceOptions.Carbine.bTargetFrameFlipped 	= self.wndInterface:FindChild("TargetUnitFrame"):GetRadioSel("TargetFrameFilpped") == 1
	g_InterfaceOptions.Carbine.bFocusFrameFlipped 	= self.wndInterface:FindChild("FocusUnitFrame"):GetRadioSel("FocusFrameFlipped") == 1
	
	Event_FireGenericEvent("OptionsUpdated_UnitFramesUpdated")
end

function OptionsInterface:OnToggleInteractTextOnUnit(wndHandler, wndControl)
	g_InterfaceOptions.Carbine.bInteractTextOnUnit = wndHandler:IsChecked()
	Event_FireGenericEvent("OptionsUpdated_HUDInteract")
	Event_FireGenericEvent("GenericEvent_SystemChannelMessage", Apollo.GetString("HUDAlert_InteractTextVisibilityChanged"), wndHandler:IsChecked() and Apollo.GetString("Command_Chat_True") or Apollo.GetString("Command_Chat_False"))
end

local OptionsInterfaceInst = OptionsInterface:new()
OptionsInterfaceInst:Init()

