-----------------------------------------------------------------------------------------------
-- Client Lua Script for CSI
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Unit"
require "GameLib"
require "CSIsLib"

local kstrPrecisionArrowRight = "CRB_Basekit:kitIProgBar_HoloFrame_CapArrowR"
local kstrPrecisionArrowLeft = "CRB_Basekit:kitIProgBar_HoloFrame_CapArrowL"
local kcrPrecisionBarReady = ApolloColor.new("ffffffff")
local kcrPrecisionBarHit = ApolloColor.new("green")

local knSaveVersion = 6

local CSI = {}

function CSI:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function CSI:Init()
    Apollo.RegisterAddon(self)
end

function CSI:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	
	local bIsYesNo = false
	local tActiveCSI = CSIsLib.GetActiveCSI()
	if tActiveCSI and tActiveCSI.eType == CSIsLib.ClientSideInteractionType_YesNo then
		bIsYesNo = true
	end
	
	local locMemory = self.wndMemory and self.wndMemory:GetLocation() or self.locMemoryLocation
	local locKeypad = self.wndKeypad and self.wndKeypad:GetLocation() or self.locKeypadLocation
	local locYesNo = (bIsYesNo and self.wndProgress) and self.wndProgress:GetLocation() or self.locYesNoLocation
	local tSave = 
	{
		tMemoryLocation = locMemory and locMemory:ToTable() or nil,
		tKeypadLocation = locKeypad and locKeypad:ToTable() or nil,
		tYesNoLocation = locYesNo and locYesNo:ToTable() or nil,
		nSaveVersion = knSaveVersion,
	}
	return tSave
end

function CSI:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	if tSavedData and tSavedData.nSaveVersion == knSaveVersion then
		
		if tSavedData.tMemoryLocation then
			self.locMemoryLocation = WindowLocation.new(tSavedData.tMemoryLocation)
		end
		
		if tSavedData.tKeypadLocation then
			self.locKeypadLocation = WindowLocation.new(tSavedData.tKeypadLocation)
		end
		
		if tSavedData.tYesNoLocation then
			self.locYesNoLocation = WindowLocation.new(tSavedData.tYesNoLocation)
		end
	end
end

function CSI:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CSI.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function CSI:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	Apollo.RegisterEventHandler("CSIKeyPressed", "OnCSIKeyPressed", self) -- Hitting the 'F' key
	Apollo.RegisterEventHandler("SetProgressClickTimes", "OnSetProgressClickTimes", self) -- Resizing the target rectangle
	Apollo.RegisterEventHandler("ProgressClickHighlightTime", "OnProgressClickHighlightTime", self) -- Flagging rectangle green
	Apollo.RegisterEventHandler("ProgressClickWindowDisplay", "OnProgressClickWindowDisplay", self)	-- Starting a CSI
	Apollo.RegisterEventHandler("ProgressClickWindowCompletionLevel", "OnProgressClickWindowCompletionLevel", self) -- Updates Progress Bar
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", "OnTutorial_RequestUIAnchor", self)

	self.nLocation1Left = 0
	self.nLocation1Right = 0
	self.nLocation2Left = 0
    self.nLocation2Right = 0
	self.nMetronomeMisses = 0
	self.bMetronomeLastDirection1 = true
	self.bMetronomeLastDirection2 = true
	self.bMetronomeLastDirectionAll = false

	self.wndProgress = nil
	
	self.wndKeypad = Apollo.LoadForm(self.xmlDoc, "CSI_Keypad", nil, self) -- TODO: Refactor so we don't load these until needed
	if self.locKeypadLocation then
		self.wndKeypad:MoveToLocation(self.locKeypadLocation)
	end
	
	self.wndMemory = Apollo.LoadForm(self.xmlDoc, "CSI_Memory", nil, self)
	if self.locMemoryLocation then
		self.wndMemory:MoveToLocation(self.locMemoryLocation)
	end		

	self.tMemoryOptions =
	{
		self.wndMemory:FindChild("OptionBtn1"),
		self.wndMemory:FindChild("OptionBtn2"),
		self.wndMemory:FindChild("OptionBtn3"),
		self.wndMemory:FindChild("OptionBtn4")
	}

	self.tMemoryOptions[1]:SetData({ strTextColor = "ffec9200", id = 1, sound = Sound.PlayUIMemoryButton1}) -- ffb62e
	self.tMemoryOptions[2]:SetData({ strTextColor = "ff37ff00", id = 2, sound = Sound.PlayUIMemoryButton2})
	self.tMemoryOptions[3]:SetData({ strTextColor = "ff31fcf6", id = 3, sound = Sound.PlayUIMemoryButton3})
	self.tMemoryOptions[4]:SetData({ strTextColor = "ffd000ff", id = 4, sound = Sound.PlayUIMemoryButton4})

	self.timerMemoryDisplay = ApolloTimer.Create(0.5, false, "OnMemoryDisplayTimer", self)
	Apollo.RegisterEventHandler("AcceptProgressInput", "OnAcceptProgressInput", self)
	Apollo.RegisterEventHandler("HighlightProgressOption", "OnHighlightProgressOption", self)

	for idx = 0, 9 do
		self.wndKeypad:FindChild("KeypadButtonContainer:Button"..idx):SetData(idx) -- Requires exactly named windows
	end

	-- Persistance through reloadui
	if CSIsLib.IsCSIRunning() then
		self:OnProgressClickWindowDisplay(true)
	end
end

function CSI:OnProgressClickWindowDisplay(bShow)
	local tActiveCSI = CSIsLib.GetActiveCSI()
	if not tActiveCSI then
		return
	end
	
	if self.wndProgress and self.wndProgress:IsValid() then
		self.wndProgress:Destroy()
		self.wndProgress = nil
	end
	
	if not bShow then
		self.wndMemory:Close()
		self.wndKeypad:Close()
		return
	end
	
	local eType = tActiveCSI.eType

	if eType == CSIsLib.ClientSideInteractionType_YesNo then
		self:BuildYesNo(tActiveCSI)
	elseif eType == CSIsLib.ClientSideInteractionType_Memory then
		self:BuildMemory(tActiveCSI)
	elseif eType == CSIsLib.ClientSideInteractionType_Keypad then
		self:BuildKeypad(tActiveCSI)
	elseif eType == CSIsLib.ClientSideInteractionType_PressAndHold then
		self:BuildPressAndHold(tActiveCSI, Apollo.GetString("ProgressClick_ClickAndHoldUnit"))
	elseif eType == CSIsLib.ClientSideInteractionType_RapidTapping or eType == CSIsLib.ClientSideInteractionType_RapidTappingInverse then
		self:BuildRapidTap(tActiveCSI, Apollo.GetString("ProgressClick_RapidClickUnit"))
	elseif eType == CSIsLib.ClientSideInteractionType_PrecisionTapping or eType == CSIsLib.ClientSideInteractionType_Metronome then
		self:BuildPrecisionTap(tActiveCSI, Apollo.GetString("ProgressClick_PrecisionClickUnit"))
	end

	self:OnCalculateTimeRemaining()
end

-----------------------------------------------------------------------------------------------
-- Yes No
-----------------------------------------------------------------------------------------------

function CSI:BuildYesNo(tActiveCSI)

	local wndCurr = Apollo.LoadForm(self.xmlDoc, "CSI_YesNo", nil, self)
	wndCurr:Invoke()

	wndCurr:FindChild("NoButton"):SetData(wndCurr)
	wndCurr:FindChild("YesButton"):SetData(wndCurr)
	wndCurr:FindChild("CloseButton"):SetData(wndCurr)
	if tActiveCSI.strContext then
		wndCurr:FindChild("BodyText"):SetText(tActiveCSI.strContext)
	end

	if self.locYesNoLocation then
		wndCurr:MoveToLocation(self.locYesNoLocation)
	end
	self.wndProgress = wndCurr
end

function CSI:OnYesNo_WindowClosed(wndHandler) -- wndHandler is "CSI_YesNo"
	self.locYesNoLocation = wndHandler:GetLocation()
	
	wndHandler:Close()
	wndHandler:Destroy()
end

function CSI:OnYesNo_NoPicked(wndHandler, wndControl) -- wndHandler are the "NoButton/CloseButton", and the data is the window "CSI_YesNo"
	if not wndHandler or not wndHandler:GetData() then 
		return 
	end 
	self.locYesNoLocation = wndHandler:GetData():GetLocation()
	wndHandler:GetData():Destroy()

	local tCSI = CSIsLib.GetActiveCSI()
	if tCSI and CSIsLib.IsCSIRunning() then
        CSIsLib.CSIProcessInteraction(false)
    end
end

function CSI:OnYesNo_YesPicked(wndHandler, wndControl) -- wndHandler is "YesButton", and the data is the window "CSI_YesNo"
	if not wndHandler or not wndHandler:GetData() then 
		return 
	end 
	self.locYesNoLocation = wndHandler:GetData():GetLocation()
	wndHandler:GetData():Destroy()

	local tCSI = CSIsLib.GetActiveCSI()
	if tCSI and CSIsLib.IsCSIRunning() then
        CSIsLib.CSIProcessInteraction(true)
    end
end

-----------------------------------------------------------------------------------------------
-- Press and Hold and Rapid Tap and Precision Tap and Memory and Keypad
-----------------------------------------------------------------------------------------------

function CSI:BuildPressAndHold(tActiveCSI, strBodyText)
	local wndCurr = Apollo.LoadForm(self.xmlDoc, "CSI_Progress_Hold", nil, self)
	wndCurr:Show(true) -- to get the animation
	wndCurr:FindChild("KeyText"):SetText(strBodyText)
	wndCurr:FindChild("ProgressButton:KeyText"):SetText(GameLib.GetKeyBinding("Interact"))
	wndCurr:FindChild("HoldButtonDecoration"):Show(true)
	
	if self.wndProgress and self.wndProgress:IsValid() then
		self.wndProgress:Destroy()
	end
	self.wndProgress = wndCurr
end

function CSI:BuildRapidTap(tActiveCSI)
	local wndCurr = Apollo.LoadForm(self.xmlDoc, "CSI_Progress_Tap", nil, self)
	wndCurr:Show(true) -- to get the animation
	wndCurr:FindChild("HandIndicatorInactive"):Show(true)
	wndCurr:FindChild("HandIndicatorActive"):Show(false)
	wndCurr:FindChild("ProgressButton:KeyText"):SetText(GameLib.GetKeyBinding("Interact"))
	
	if self.wndProgress and self.wndProgress:IsValid() then
		self.wndProgress:Destroy()
	end
	self.wndProgress = wndCurr
end

function CSI:BuildPrecisionTap(tActiveCSI, strBodyText)
	local wndCurr = Apollo.LoadForm(self.xmlDoc, "CSI_Precision", nil, self)
	wndCurr:SetData(tActiveCSI)
	wndCurr:FindChild("BodyText"):SetText(strBodyText)

	local strInteractKey = GameLib.GetKeyBinding("Interact") or ""
	local wndClickTimeFrame = wndCurr:FindChild("ClickTimeFrame")
	wndClickTimeFrame:FindChild("PreviewProgressButtonWindow"):Show(true)
	wndClickTimeFrame:FindChild("PreviewProgressButtonText"):SetText(strInteractKey)

	local wndClickTimeFrame2 = wndCurr:FindChild("ClickTimeFrame2")
	wndClickTimeFrame2:FindChild("PreviewProgressButtonWindow"):Show(true)
	wndClickTimeFrame2:FindChild("PreviewProgressButtonText"):SetText(strInteractKey)
	wndCurr:FindChild("ProgressBar"):SetGlowSprite(kstrPrecisionArrowRight)

	wndCurr:FindChild("MetronomeProgress"):Show(tActiveCSI.eType == CSIsLib.ClientSideInteractionType_Metronome)
	
	if self.wndProgress and self.wndProgress:IsValid() then
		self.wndProgress:Destroy()
	end

	self.wndProgress = wndCurr
	self.nMetronomeMisses = 0
	self.nMetronomeHits = 0
	self.bMetronomeLastDirection1 = true
	self.bMetronomeLastDirection2 = true
	self.bMetronomeLastDirectionAll = false
end

function CSI:BuildKeypad(tActiveCSI)
	if tActiveCSI then
		self.wndKeypad:Invoke()
	else
		self.wndKeypad:Close()
	    return
	end

	self.nKeypadCount = 0
	self.strKeypadDisplay = ""
	self.wndKeypad:FindChild("KeypadButtonContainer:Enter"):Enable(false)
	self.wndKeypad:FindChild("KeypadTopBG:KeypadText"):Show(true)
	self.wndKeypad:FindChild("KeypadTopBG:TextDisplay"):SetText("")

	if tActiveCSI.strContext and Apollo.StringLength(tActiveCSI.strContext) > 0 then
		self.wndKeypad:FindChild("KeypadTopBG:KeypadText"):SetText(tActiveCSI.strContext)
	else
		self.wndKeypad:FindChild("KeypadTopBG:KeypadText"):SetText(Apollo.GetString("CRB_Enter_the_code"))
	end

	self.wndKeypad:FindChild("TimeRemainingContainer"):Show(false)
end

function CSI:BuildMemory(tActiveCSI)
	-- TODO: Create a new one here (and later destroy)
	if tActiveCSI then
		self.wndMemory:Invoke()
	else
		self.wndMemory:Close()
	end
	
	self.wndMemory:FindChild("OptionBtn1"):Enable(false)
	self.wndMemory:FindChild("OptionBtn2"):Enable(false)
	self.wndMemory:FindChild("OptionBtn3"):Enable(false)
	self.wndMemory:FindChild("OptionBtn4"):Enable(false)
	self.wndMemory:FindChild("StartBtnBG"):Show(tActiveCSI)
	self.wndMemory:FindChild("BGArtCenterCircle:BGArtCenterCircleText"):SetAML("")
	self.wndMemory:FindChild("BGArtCenterCircle:BGArtCenterCircleReadyText"):Show(false)
end

-----------------------------------------------------------------------------------------------
-- Shared
-----------------------------------------------------------------------------------------------

function CSI:OnProgressClickWindowCompletionLevel(nPercentage, bIsReversed) -- Updates Progress Bar
	if not self.wndProgress or not self.wndProgress:IsValid() then
		return
	end

	if nPercentage > 100 then
		nPercentage = 100
	elseif nPercentage < 0 then
		nPercentage = 0
	end

	local wndClickTimeFrame = self.wndProgress:FindChild("ClickTimeFrame")
	local wndClickTimeFrame2 = self.wndProgress:FindChild("ClickTimeFrame2")
	
	-- Draw ClickTimeFrames
	if nPercentage > 0 and self.wndProgress:FindChild("ClickTimeFrame") then
		self.wndProgress:FindChild("BodyText"):SetText("")
		self.wndProgress:FindChild("ProgressButton"):Show(false)

		local wndProgressButton = wndClickTimeFrame:FindChild("ClickProgressButton")
		local wndProgressButton2 = wndClickTimeFrame2:FindChild("ClickProgressButton")
		
		if not bIsReversed then
			wndProgressButton:Show(true)
			wndProgressButton2:Show(self.nLocation2Left > 0 and nPercentage > self.nLocation1Right)
		else
			local bHasLeft = self.nLocation2Left > 0
			wndProgressButton:Show(not bHasLeft or (bHasLeft and nPercentage < self.nLocation2Left))
			wndProgressButton2:Show(bHasLeft)
		end

		-- Special glowing (only once) when they enter it
		local wndButtonGlow = wndClickTimeFrame:FindChild("ProgressButtonGlow")
		if nPercentage > self.nLocation1Left and nPercentage < self.nLocation1Right and not wndClickTimeFrame2:FindChild("ProgressButtonFail"):IsShown() then
			if not wndButtonGlow:GetData() then
				wndButtonGlow:Show(true)
				wndButtonGlow:SetData(true)
				wndButtonGlow:SetSprite("sprWinAnim_BirthSmallTempLoop")
			end
		else
			wndButtonGlow:Show(false)
		end

		local wndButtonGlow2 = wndClickTimeFrame2:FindChild("ProgressButtonGlow")
		if nPercentage > self.nLocation2Left and nPercentage < self.nLocation2Right and not wndClickTimeFrame2:FindChild("ProgressButtonFail"):IsShown() then
			if not wndButtonGlow2:GetData() then
				wndButtonGlow2:Show(true)
				wndButtonGlow2:SetData(true)
				wndButtonGlow2:SetSprite("sprWinAnim_BirthSmallTempLoop")
			end
		else
			wndButtonGlow2:Show(false)
		end

		-- Fail if they missed it
		local tCSI = CSIsLib.GetActiveCSI()
		
		local bFailed1 = nPercentage > self.nLocation1Right and wndProgressButton:IsVisible() and not wndClickTimeFrame:FindChild("ProgressButtonCheck"):IsShown() and not wndClickTimeFrame:FindChild("ProgressButtonFail"):IsShown()
		local bFailed2 = nPercentage > self.nLocation2Right and wndProgressButton2:IsVisible() and not wndClickTimeFrame2:FindChild("ProgressButtonCheck"):IsShown() and not wndClickTimeFrame2:FindChild("ProgressButtonFail"):IsShown()

		if tCSI.eType == CSIsLib.ClientSideInteractionType_Metronome then -- Special case for reversing Metronome (compare < instead of >)
			if bIsReversed then
				bFailed1 = nPercentage < self.nLocation1Left and nPercentage < self.nLocation1Right and wndProgressButton:IsVisible() and not wndClickTimeFrame:FindChild("ProgressButtonCheck"):IsShown() and not wndClickTimeFrame:FindChild("ProgressButtonFail"):IsShown()
				bFailed2 = nPercentage < self.nLocation2Left and nPercentage < self.nLocation2Right and wndProgressButton2:IsVisible() and not wndClickTimeFrame2:FindChild("ProgressButtonCheck"):IsShown() and not wndClickTimeFrame2:FindChild("ProgressButtonFail"):IsShown()
			end
			
			self.wndProgress:FindChild("ProgressBarFrame:ProgressBar"):SetData(nPercentage)

			-- Miss tracking
			if bFailed1 then
				if not wndClickTimeFrame:FindChild("ProgressButtonFail"):IsShown() then
					self.nMetronomeMisses = self.nMetronomeMisses + 1
				end
			end
			if bFailed2 then
				if not wndClickTimeFrame2:FindChild("ProgressButtonFail"):IsShown() then
					self.nMetronomeMisses = self.nMetronomeMisses + 1
				end
			end
			
			local wndMissThresholdText = self.wndProgress:FindChild("MetronomeMissThresholdText")
			if wndMissThresholdText and tCSI.nThreshold > 1 and self.nMetronomeMisses > 0 then
				wndMissThresholdText:SetText(String_GetWeaselString(Apollo.GetString("CSI_MissedCount"), self.nMetronomeMisses, (tCSI.nThreshold + 1)))
			elseif wndMissThresholdText then
				wndMissThresholdText:SetText("")
			end
		end

		if bFailed1 then			
			Sound.Play(Sound.PlayUIAlertPopUpMessageReceived)
			wndClickTimeFrame:FindChild("ProgressButtonFail"):Invoke()
			wndClickTimeFrame:FindChild("ProgressButtonText"):Show(false)
		end

		if bFailed2 then			
			Sound.Play(Sound.PlayUIAlertPopUpMessageReceived)
			wndClickTimeFrame2:FindChild("ProgressButtonFail"):Invoke()
			wndClickTimeFrame2:FindChild("ProgressButtonText"):Show(false)
		end
	end

	-- Draw Progress Bar
	--local wndProgressBar = 
	local wndProgressBar = self.wndProgress:FindChild("ProgressBarFrame:ProgressBar") or self.wndProgress:FindChild("ProgressBar")
	if wndProgressBar then
		wndProgressBar:SetMax(100)
		wndProgressBar:SetFloor(0)

		local tCSI = CSIsLib.GetActiveCSI()
		if tCSI and tCSI.eType == CSIsLib.ClientSideInteractionType_RapidTappingInverse then
			wndProgressBar:SetProgress(100 - nPercentage)
		else
			wndProgressBar:SetProgress(nPercentage)
		end

		-- Reset ClickTimeFrames for Metronome at the 0 and 100 point
		-- The upper bounds seems highly innaccurate.  
		if tCSI and tCSI.eType == CSIsLib.ClientSideInteractionType_Metronome and (nPercentage < 1 or nPercentage > 98) then
			wndClickTimeFrame:FindChild("ProgressButtonText"):Show(true)
			wndClickTimeFrame:FindChild("ProgressButtonFail"):Show(false)
			wndClickTimeFrame:FindChild("ProgressButtonCheck"):Show(false)
			wndClickTimeFrame2:FindChild("ProgressButtonText"):Show(true)
			wndClickTimeFrame2:FindChild("ProgressButtonFail"):Show(false)
			wndClickTimeFrame2:FindChild("ProgressButtonCheck"):Show(false)

			if nPercentage < 1 then
				wndProgressBar:SetGlowSprite(kstrPrecisionArrowRight)
			else
				wndProgressBar:SetGlowSprite(kstrPrecisionArrowLeft)
			end
		end
		-- Needs to be at very end (after reverse check in Metronome)
		wndProgressBar:SetData(nPercentage)
	end
end

function CSI:OnSetProgressClickTimes(nWidth, nLocation1, nLocation2, nSwingCount)
	if not self.wndProgress or not self.wndProgress:IsValid() then
		return
	end
	
	local wndProgressBar = self.wndProgress:FindChild("ProgressBarFrame:ProgressBar") or self.wndProgress:FindChild("ProgressBar")
	if not wndProgressBar then
		return
	end

	local nWidthOverTwo = nWidth / 2
	local nLeft, nTop, nRight, nBottom = wndProgressBar:GetRect()
	local nProgressWidth = nRight - nLeft
	local nTicks = nProgressWidth / 100

	self.nLocation1Left = nLocation1 - nWidthOverTwo
	self.nLocation1Right = nLocation1 + nWidthOverTwo
	self.nLocation2Left = nLocation2 - nWidthOverTwo
	self.nLocation2Right = nLocation2 + nWidthOverTwo

	nWidth = nWidth + nTicks
	nLocation1 = nLocation1 * nTicks
	nLocation2 = nLocation2 * nTicks
	nWidthOverTwo = nWidthOverTwo * nTicks

	local nLocationsPerSwing = 0

	if nLocation1 ~= 0 then
		local nLeftEdge = nLocation1 - nWidthOverTwo + nLeft
		local nRightEdge = nLocation1 + nWidthOverTwo + nLeft
		local nClickLeft, nClickTop, nClickRight, nClickBottom = self.wndProgress:FindChild("ClickTimeFrame"):GetRect()
		self.wndProgress:FindChild("ClickTimeFrame"):Move(nLeftEdge, nClickTop, nRightEdge - nLeftEdge, nClickBottom - nClickTop)
		self.wndProgress:FindChild("ClickTimeFrame"):Show(true)
		nLocationsPerSwing = nLocationsPerSwing + 1
	end

	if nLocation2 ~= 0 then
		local nLeftEdge = nLocation2 - nWidthOverTwo + nLeft
		local nRightEdge = nLocation2 + nWidthOverTwo + nLeft
		local nClickLeft, nClickTop, nClickRight, nClickBottom = self.wndProgress:FindChild("ClickTimeFrame2"):GetRect()
		self.wndProgress:FindChild("ClickTimeFrame2"):Move(nLeftEdge, nClickTop, nRightEdge - nLeftEdge, nClickBottom - nClickTop)
		self.wndProgress:FindChild("ClickTimeFrame2"):Show(true)
		nLocationsPerSwing = nLocationsPerSwing + 1
	end

	self.nProgressSwingCount = nSwingCount * nLocationsPerSwing

	local tActiveCSI = CSIsLib.GetActiveCSI()
	if tActiveCSI and tActiveCSI.eType == CSIsLib.ClientSideInteractionType_Metronome then
		self.wndProgress:FindChild("MetronomeProgress"):SetText(String_GetWeaselString(Apollo.GetString("CSI_MetronomeCountStart"), self.nProgressSwingCount))
	end

end

function CSI:OnProgressClickHighlightTime(idx, nPercentageHighlight)
	if not self.wndProgress or not self.wndProgress:IsValid() or not self.wndProgress:FindChild("ClickTimeFrame") then
		return
	end
	
	local wndClickTimeFrame = self.wndProgress:FindChild("ClickTimeFrame")
	local wndClickTimeFrame2 = self.wndProgress:FindChild("ClickTimeFrame2")

	local fRed = 1.0
	local fBlue = 1.0
	local fGreen = 1.0
	local crBarColor = kcrPrecisionBarReady

	if nPercentageHighlight > 0 and idx == 0 and not wndClickTimeFrame:FindChild("ProgressButtonFail"):IsShown() then
		fRed = 1 - nPercentageHighlight / 100
		fBlue = 1 - nPercentageHighlight / 100
		wndClickTimeFrame:FindChild("ProgressButtonCheck"):Show(true)
		wndClickTimeFrame:FindChild("ProgressButtonGlow"):Show(false)
		wndClickTimeFrame:FindChild("ProgressButtonText"):Show(false)
		crBarColor = kcrPrecisionBarHit
	elseif nPercentageHighlight > 0 and idx == 1 and not wndClickTimeFrame2:FindChild("ProgressButtonFail"):IsShown() then
		fRed = 1 - nPercentageHighlight / 100
		fBlue = 1 - nPercentageHighlight / 100
		wndClickTimeFrame2:FindChild("ProgressButtonCheck"):Show(true)
		wndClickTimeFrame2:FindChild("ProgressButtonGlow"):Show(false)
		wndClickTimeFrame2:FindChild("ProgressButtonText"):Show(false)
		crBarColor = kcrPrecisionBarHit
	end
end

function CSI:HelperComputeProgressFailOrWin()
	-- This is relying on the UI and Server to be in sync, and can result in false passes if there is lag
	if not self.wndProgress or not self.wndProgress:IsValid() or not self.wndProgress:FindChild("ClickTimeFrame") or self.wndProgress:FindChild("ProgressButton"):IsShown() then
		return
	end
	
	local wndClickTimeFrame = self.wndProgress:FindChild("ClickTimeFrame")
	local wndClickTimeFrame2 = self.wndProgress:FindChild("ClickTimeFrame2")

	local nPercentage = self.wndProgress:FindChild("ProgressBar"):GetData()
	-- If an extra click happens on the left
	if nPercentage < self.nLocation1Left then
		wndClickTimeFrame:FindChild("ProgressButtonFail"):Show(true)
		wndClickTimeFrame:FindChild("ProgressButtonText"):Show(false)
		wndClickTimeFrame:FindChild("ProgressButtonCheck"):Show(false)
		self:HelperFail()
	elseif nPercentage < self.nLocation1Right and wndClickTimeFrame:FindChild("ProgressButtonFail"):IsShown() then
		self:HelperFail()
	end

	if nPercentage < self.nLocation2Left and nPercentage > self.nLocation1Right then
		wndClickTimeFrame2:FindChild("ProgressButtonFail"):Show(true)
		wndClickTimeFrame2:FindChild("ProgressButtonText"):Show(false)
		wndClickTimeFrame2:FindChild("ProgressButtonCheck"):Show(false)
		self:HelperFail()
	elseif nPercentage < self.nLocation2Right and nPercentage > self.nLocation1Right and wndClickTimeFrame2:FindChild("ProgressButtonFail"):IsShown() then
		self:HelperFail()
	end

	-- If an extra click happens on the right
	if nPercentage > self.nLocation1Right and not wndClickTimeFrame2:IsShown() then
		if not wndClickTimeFrame:FindChild("ProgressButtonFail"):IsShown() then
			self:HelperFail()
		end
		wndClickTimeFrame:FindChild("ProgressButtonFail"):Show(true)
		wndClickTimeFrame:FindChild("ProgressButtonText"):Show(false)
		wndClickTimeFrame:FindChild("ProgressButtonCheck"):Show(false)
	end

	if nPercentage > self.nLocation2Right and wndClickTimeFrame2:IsShown() then
		if not wndClickTimeFrame2:FindChild("ProgressButtonFail"):IsShown() then
			self:HelperFail()
		end
		wndClickTimeFrame2:FindChild("ProgressButtonFail"):Show(true)
		wndClickTimeFrame2:FindChild("ProgressButtonText"):Show(false)
		wndClickTimeFrame2:FindChild("ProgressButtonCheck"):Show(false)
	end

	if nPercentage >= self.nLocation1Left and nPercentage <= self.nLocation1Right then
		self:HelperSuccess()
	end

	if nPercentage >= self.nLocation2Left and nPercentage <= self.nLocation2Right then
		self:HelperSuccess()
	end
end

function CSI:HelperSuccess()
	Sound.Play(Sound.PlayUIExplorerSignalDetection1)
	self.nMetronomeHits = self.nMetronomeHits + 1
	self.wndProgress:FindChild("MetronomeProgress"):SetText(String_GetWeaselString(Apollo.GetString("CSI_MetronomeCount"), self.nMetronomeHits, self.nProgressSwingCount))
end

function CSI:HelperFail()
	Sound.Play(Sound.PlayUIAlertPopUpMessageReceived)
	self.nMetronomeMisses = self.nMetronomeMisses + 1
end

-----------------------------------------------------------------------------------------------
-- UI and CSI Lib Events
-----------------------------------------------------------------------------------------------

function CSI:OnCancel(wndHandler, wndControl)
	if wndHandler == wndControl then
		if CSIsLib.GetActiveCSI() then
		    CSIsLib.CancelActiveCSI()
		end

		self.wndMemory:Close()
		self.wndKeypad:Close()
	end
end

function CSI:OnCSIKeyPressed(bKeyDown)
	if bKeyDown then
		self:OnButtonDown()
	else
		self:OnButtonUp()
	end

	if self.wndProgress and self.wndProgress:IsValid() then
		self.wndProgress:FindChild("ProgressButton"):SetCheck(bKeyDown)
    end

	Event_FireGenericEvent("GenericEvent_HideInteractPrompt")
end

function CSI:OnButtonDown()
	local tCSI = CSIsLib.GetActiveCSI()
	if not tCSI then
		return
	end

	if not CSIsLib.IsCSIRunning() and tCSI.eType ~= CSIsLib.ClientSideInteractionType_Metronome and tCSI.eType ~= CSIsLib.ClientSideInteractionType_PrecisionTapping then
		CSIsLib.StartActiveCSI()
		self:OnCalculateTimeRemaining()
	end

	if CSIsLib.IsCSIRunning() or tCSI.eType == CSIsLib.ClientSideInteractionType_PressAndHold or tCSI.eType == CSIsLib.ClientSideInteractionType_RapidTapping then
		CSIsLib.CSIProcessInteraction(true)
	end

	if not CSIsLib.IsCSIRunning() and (tCSI.eType == CSIsLib.ClientSideInteractionType_Metronome or tCSI.eType == CSIsLib.ClientSideInteractionType_PrecisionTapping) then
		CSIsLib.StartActiveCSI()
		
		if self.wndProgress and self.wndProgress:IsValid() then
			self.wndProgress:FindChild("MetronomeProgress"):SetText(String_GetWeaselString(Apollo.GetString("CSI_MetronomeCount"), self.nMetronomeHits, self.nProgressSwingCount))
		end
		
		self:OnCalculateTimeRemaining()
    end

	self:HelperComputeProgressFailOrWin()
end

function CSI:OnButtonUp()
	local tCSI = CSIsLib.GetActiveCSI()
	if not tCSI then
		return
	end

	if tCSI.eType == CSIsLib.ClientSideInteractionType_PressAndHold then
        CSIsLib.CSIProcessInteraction(false)
    end
end

function CSI:OnCalculateTimeRemaining()
	local tCSI = CSIsLib.GetActiveCSI()
	local fTimeRemaining = CSIsLib.GetTimeRemainingForActiveCSI()

	if not fTimeRemaining or fTimeRemaining == 0 or not CSIsLib.IsCSIRunning() then
		return
	end

	local wndToUpdate = nil -- TODO: Refactor
	if self.wndProgress and self.wndProgress:IsShown() and self.wndProgress:FindChild("TimeRemainingContainer") then
		wndToUpdate = self.wndProgress
	elseif self.wndKeypad and self.wndKeypad:IsShown() and self.wndKeypad:FindChild("TimeRemainingContainer") then
		wndToUpdate = self.wndKeypad
	end

	if wndToUpdate then
		wndToUpdate:FindChild("TimeRemainingContainer"):Show(true)

		local wndTimeRemainingBar = wndToUpdate:FindChild("TimeRemainingContainer:TimeRemainingBarBG:TimeRemainingBar")
		local nData = wndTimeRemainingBar:GetData()
		if not nData or fTimeRemaining > nData then
			wndTimeRemainingBar:SetMax(fTimeRemaining)
			wndTimeRemainingBar:SetData(fTimeRemaining)
		end
		wndTimeRemainingBar:SetProgress(fTimeRemaining)
	end

	if fTimeRemaining > 0 then
		--timers currently can't be started during their callbacks, because of a Code bug.
		self.timerCalculateRemaining = ApolloTimer.Create(0.05, false, "OnCalculateTimeRemaining", self)
	end
end

-----------------------------------------------------------------------------------------------
-- Keypad
-----------------------------------------------------------------------------------------------

function CSI:OnKeypadSignal(wndDisplayed, wndControl)
	local tCSI = CSIsLib.GetActiveCSI()
	if tCSI == nil or tCSI.eType ~= CSIsLib.ClientSideInteractionType_Keypad then
		return
    end

	if not CSIsLib.IsCSIRunning() then
		CSIsLib.StartActiveCSI()
	end

	if self.nKeypadCount > 10 then
		return
	end

	self.nKeypadCount = self.nKeypadCount + 1
	self.strKeypadDisplay = self.strKeypadDisplay .. tostring(wndDisplayed:GetData())
	self.wndKeypad:FindChild("KeypadButtonContainer:Enter"):Enable(true)
	self.wndKeypad:FindChild("KeypadTopBG:KeypadText"):Show(false)
	self.wndKeypad:FindChild("KeypadTopBG:TextDisplay"):SetText(self.strKeypadDisplay)

	self:OnCalculateTimeRemaining()
end

function CSI:OnKeypadEnter(wndHandler, wndControl)
	local tCSI = CSIsLib.GetActiveCSI()
	if tCSI == nil or tCSI.eType ~= CSIsLib.ClientSideInteractionType_Keypad or not CSIsLib.IsCSIRunning() then
		return
    end

	if Apollo.StringLength(self.strKeypadDisplay) == 0 then
		return
	end

	CSIsLib.SelectCSIOption(tonumber(self.strKeypadDisplay))
end

function CSI:OnKeypadClear(wndHandler, wndControl)
	local tCSI = CSIsLib.GetActiveCSI()
	if tCSI == nil or tCSI.eType ~= CSIsLib.ClientSideInteractionType_Keypad or not CSIsLib.IsCSIRunning() then
		return
    end

	self.nKeypadCount = 0
	self.strKeypadDisplay = ""
	self.wndKeypad:FindChild("KeypadButtonContainer:Enter"):Enable(false)
	self.wndKeypad:FindChild("KeypadTopBG:KeypadText"):Show(true)
	self.wndKeypad:FindChild("KeypadTopBG:TextDisplay"):SetText("")
end

-----------------------------------------------------------------------------------------------
-- Memory
-----------------------------------------------------------------------------------------------

function CSI:OnMemoryStart(wndHandler, wndControl)
	if not CSIsLib.IsCSIRunning() then
		self.wndMemory:SetData(nil)
		self.wndMemory:FindChild("StartBtnBG"):Show(false)
		self.wndMemory:FindChild("BGArtCenterCircle:BGArtCenterCircleText"):SetAML("")
		self.wndMemory:FindChild("BGArtCenterCircle:BGArtCenterCircleReadyText"):SetData(false)
        CSIsLib.StartActiveCSI()
		Sound.Play(Sound.PlayUIMemoryStart)
	end
end

function CSI:OnAcceptProgressInput(bShouldAccept)
	if bShouldAccept then
		self.wndMemory:FindChild("OptionBtn1"):Enable(true)
		self.wndMemory:FindChild("OptionBtn2"):Enable(true)
		self.wndMemory:FindChild("OptionBtn3"):Enable(true)
		self.wndMemory:FindChild("OptionBtn4"):Enable(true)
		self.wndMemory:FindChild("BGArtCenterCircle:BGArtCenterCircleReadyText"):Show(true, true)
	end

	self.wndMemory:SetData(nil)
	self.wndMemory:FindChild("BGArtCenterCircle:BGArtCenterCircleReadyText"):SetData(bShouldAccept)

	for key, wndCurr in pairs(self.tMemoryOptions) do
		wndCurr:FindChild("OptionBtnFlash"):Show(false)
	end
end

function CSI:OnHighlightProgressOption(nOption)
	if not self.wndMemory or not self.wndMemory:IsValid() then
		return
	end

	self.wndMemory:FindChild("OptionBtn1"):Enable(false)
	self.wndMemory:FindChild("OptionBtn2"):Enable(false)
	self.wndMemory:FindChild("OptionBtn3"):Enable(false)
	self.wndMemory:FindChild("OptionBtn4"):Enable(false)
	self.wndMemory:FindChild("BGArtCenterCircle:BGArtCenterCircleText"):SetAML("")
	self.wndMemory:FindChild("BGArtCenterCircle:BGArtCenterCircleReadyText"):Show(false)

	local wndCurrFlash = self.tMemoryOptions[nOption]
	if wndCurrFlash then
		self.wndMemory:SetData(wndCurrFlash)
		wndCurrFlash:FindChild("OptionBtnFlash"):Show(true)
		Sound.Play(wndCurrFlash:GetData().sound)
		self.timerMemoryDisplay:Start()
	end
end

function CSI:OnMemoryDisplayTimer() -- When we're done the flash
	if not self.wndMemory or not self.wndMemory:IsValid() then
		return
	end

	for key, wndCurr in pairs(self.tMemoryOptions) do
		wndCurr:FindChild("OptionBtnFlash"):Show(false)
	end
end

function CSI:OnMemoryBtn(wndHandler, wndControl)
	if not self:HelperVerifyCSIMemory() then
		return
	end

	-- Stomp on a flash if the player is super fast
	for key, wndCurr in pairs(self.tMemoryOptions) do
		wndCurr:FindChild("OptionBtnFlash"):Show(false)
	end

	local strTextColor = wndHandler:GetData().strTextColor
	local strRandomString = self:HelperBuildRandomString(5)
	self.wndMemory:FindChild("BGArtCenterCircle:BGArtCenterCircleText"):SetAML("<P Font=\"CRB_AlienLarge\" TextColor=\""..strTextColor.."\" Align=\"Center\">"..strRandomString.."</P>")
	self.wndMemory:FindChild("BGArtCenterCircle:BGArtCenterCircleText"):BeginDoogie(500)
	self.wndMemory:FindChild("BGArtCenterCircle:BGArtCenterCircleReadyText"):Show(false)
	Sound.Play(wndHandler:GetData().sound)
	CSIsLib.SelectCSIOption(wndHandler:GetData().id)
end

function CSI:HelperBuildRandomString(nArgLength)
    local strResult = ""
    for idx = 1, nArgLength do
        strResult = strResult .. string.char(math.random(97, 122)) -- Lower case a-z
    end
    return strResult
end

function CSI:HelperVerifyCSIMemory()
	if not self.wndMemory or not self.wndMemory:IsValid() or not self.wndMemory:FindChild("BGArtCenterCircle:BGArtCenterCircleReadyText"):GetData() then
		return false
	end

	local tCSI = CSIsLib.GetActiveCSI()
	if not tCSI or tCSI.eType ~= CSIsLib.ClientSideInteractionType_Memory or not CSIsLib.IsCSIRunning() then
		return false
    end

	return true
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------
function CSI:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors =
	{
		[GameLib.CodeEnumTutorialAnchor.PressAndHold] 		= true,
	    [GameLib.CodeEnumTutorialAnchor.RapidTapping] 		= true,
	    [GameLib.CodeEnumTutorialAnchor.PrecisionTapping] 	= true,
	    [GameLib.CodeEnumTutorialAnchor.Memory]				= true,
	    [GameLib.CodeEnumTutorialAnchor.Keypad] 			= true,
	    [GameLib.CodeEnumTutorialAnchor.Metronome] 			= true,
	}
	
	if not tAnchors[eAnchor] or not self.wndProgress then
		return
	end

	local tAnchorMapping =
	{
		[GameLib.CodeEnumTutorialAnchor.PressAndHold] 		= self.wndProgress:FindChild("HoldText"),
		[GameLib.CodeEnumTutorialAnchor.RapidTapping] 		= self.wndProgress:FindChild("ProgressButton"),
		[GameLib.CodeEnumTutorialAnchor.PrecisionTapping] 	= self.wndProgress:FindChild("ProgressButton:ProgressButtonHand"),
		[GameLib.CodeEnumTutorialAnchor.Memory]				= self.wndMemory,
		[GameLib.CodeEnumTutorialAnchor.Keypad] 			= self.wndKeypad,
		[GameLib.CodeEnumTutorialAnchor.Metronome] 			= self.wndProgress:FindChild("ProgressButton:ProgressButtonHand"),		
	}
	
	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

local CSIInst = CSI:new()
CSIInst:Init()
