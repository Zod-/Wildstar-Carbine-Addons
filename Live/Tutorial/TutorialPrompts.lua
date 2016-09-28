-----------------------------------------------------------------------------------------------
-- Client Lua Script for TutorialPrompts
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "Sound"

local TutorialPrompts = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local kstrDefaultLabel = Apollo.GetString("Tutorials_DefaultLabel")
local knInAnimationTime = 0.4
local knOutAnimationTime = 0.4

local knAnimationOffset = 20

local ktCategories =  
{
	[GameLib.CodeEnumTutorialCategory.General] 					= Apollo.GetString("Tutorials_General"),
	[GameLib.CodeEnumTutorialCategory.Beginner] 				= Apollo.GetString("Tutorials_Beginner"),
	[GameLib.CodeEnumTutorialCategory.Combat] 					= Apollo.GetString("Tutorials_Combat"),
	[GameLib.CodeEnumTutorialCategory.PVP] 						= Apollo.GetString("Tutorials_PvP"),
	[GameLib.CodeEnumTutorialCategory.Housing] 					= Apollo.GetString("Tutorials_Housing"),
	[GameLib.CodeEnumTutorialCategory.Challenges] 				= Apollo.GetString("Tutorials_Challenges"),
	[GameLib.CodeEnumTutorialCategory.PublicEvents] 			= Apollo.GetString("Tutorials_PublicEvents"),
	[GameLib.CodeEnumTutorialCategory.Adventures] 				= Apollo.GetString("Tutorials_Adventures"),
	[GameLib.CodeEnumTutorialCategory.Path_Soldier] 			= Apollo.GetString("Tutorials_Soldier"),
	[GameLib.CodeEnumTutorialCategory.Path_Settler] 			= Apollo.GetString("Tutorials_Settler"),
	[GameLib.CodeEnumTutorialCategory.Path_Scientist] 			= Apollo.GetString("Tutorials_Scientist"),
	[GameLib.CodeEnumTutorialCategory.Path_Explorer] 			= Apollo.GetString("Tutorials_Explorer"),
	[GameLib.CodeEnumTutorialCategory.Tradeskills]				= Apollo.GetString("Tutorials_Tradeskills"),
	[GameLib.CodeEnumTutorialCategory.Zones]					= Apollo.GetString("Tutorials_Zones"),
	[GameLib.CodeEnumTutorialCategory.Classes]					= Apollo.GetString("Tutorials_Classes"),
}

local ktHOrientation =
{
	tEast =
	{
		[GameLib.CodeEnumTutorialAnchorOrientation.East] = true,
		[GameLib.CodeEnumTutorialAnchorOrientation.Northeast] = true,
		[GameLib.CodeEnumTutorialAnchorOrientation.Southeast] = true,
	},
	tWest =
	{
		[GameLib.CodeEnumTutorialAnchorOrientation.West] = true,
		[GameLib.CodeEnumTutorialAnchorOrientation.Northwest] = true,
		[GameLib.CodeEnumTutorialAnchorOrientation.Southwest] = true,
	},
	tCenter =
	{
		[GameLib.CodeEnumTutorialAnchorOrientation.North] = true,
		[GameLib.CodeEnumTutorialAnchorOrientation.South] = true,
	},
}

local ktVOrientation =
{
	tNorth =
	{
		[GameLib.CodeEnumTutorialAnchorOrientation.North] = true,
		[GameLib.CodeEnumTutorialAnchorOrientation.Northeast] = true,
		[GameLib.CodeEnumTutorialAnchorOrientation.Northwest] = true,
	},
	tSouth = 
	{
		[GameLib.CodeEnumTutorialAnchorOrientation.South] = true,
		[GameLib.CodeEnumTutorialAnchorOrientation.Southeast] = true,
		[GameLib.CodeEnumTutorialAnchorOrientation.Southwest] = true,
	},
	tCenter =
	{
		[GameLib.CodeEnumTutorialAnchorOrientation.East] = true,
		[GameLib.CodeEnumTutorialAnchorOrientation.West] = true,
	},
}

function TutorialPrompts:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
end

function TutorialPrompts:Init()
    Apollo.RegisterAddon(self)
end


-----------------------------------------------------------------------------------------------
-- TutorialPrompts OnLoad
-----------------------------------------------------------------------------------------------
function TutorialPrompts:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("TutorialPrompts.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function TutorialPrompts:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("ShowTutorial", 					"OnShowTutorial", self)
	Apollo.RegisterEventHandler("ForceTutorial", 					"OnForceTutorial", self)
	Apollo.RegisterEventHandler("TutorialPlaybackEnded", 			"OnTutorialPlaybackEnded", self)
	Apollo.RegisterEventHandler("OptionsUpdated_ShowTutorials", 	"OnShowTutorialsUpdated", self)
	Apollo.RegisterEventHandler("Tutorial_ShowCallout",				"ShowTutorialCallout", self)
	Apollo.RegisterEventHandler("Tutorial_HideCallout",				"HideTutorialCallout", self)

	-- Stun Events
	Apollo.RegisterEventHandler("ActivateCCStateStun", "OnActivateCCStateStun", self)
	Apollo.RegisterEventHandler("RemoveCCStateStun", "OnRemoveCCStateStun", self)

	self.wndAlertContainer = Apollo.LoadForm(self.xmlDoc, "AlertContainer", "FixedHudStratum", self)

	self.bAllViewSetting = g_InterfaceOptions and not g_InterfaceOptions.Carbine.bShowTutorials or false
	self.bTypeViewSetting = false
	
	-- The values returned in GetTutorialLayouts require very specific window names.  Changing the name of these forms in XML will cause lua errors.
	self.wndForms = {}
	for idx, tCurrLayout in ipairs(GameLib.GetTutorialLayouts()) do
		local wndCurr = Apollo.LoadForm(self.xmlDoc, tCurrLayout.strForm, nil, self)
		if wndCurr ~= nil then
			local nLeft, nTop, nRight, nBottom = wndCurr:GetAnchorOffsets()
			local tData = 
			{
				nLeft = nLeft, 
				nTop = nTop, 
				nWidth = nRight - nLeft, 
				nHeight = nBottom - nTop
			}
			wndCurr:SetData(tData)
			self.wndForms[tCurrLayout.nId] = wndCurr
		end
	end
	
	self.tAutoCloseTutorials = {}
	self.timerAutoClose = ApolloTimer.Create(1.0, true, "OnAutoCloseTutorialInterval", self)
	self.timerAutoClose:Stop()
	
	self.wndTransparentTutorial = nil
	self.tDisplayedPrompts = {}
	self.tPendingTutorials = {}
	self.tVisibleCallouts = {}

	self:UpdatePending()
end

function TutorialPrompts:OnActivateCCStateStun()
	self.wndAlertContainer:Show(false)
end

function TutorialPrompts:OnRemoveCCStateStun()
	self.wndAlertContainer:Show(true)
end

function TutorialPrompts:UpdatePending()
	local tPending = GameLib.GetPendingTutorials()
	if tPending then
		for idx, tTutorial in pairs(tPending) do
			self:OnShowTutorial(tTutorial.nTutorialId)
		end
	end
end

function TutorialPrompts:OnTutorialPlaybackEnded()
	-- audio playback ended; if the transparent type is shown, destroy it
	if self.wndTransparentTutorial ~= nil then
		self.wndTransparentTutorial:Close()
	end
end

-----------------------------------------------------------------------------------------------
-- TutorialPromptsForm Functions
-----------------------------------------------------------------------------------------------

function TutorialPrompts:OnShowTutorial(nTutorialId, bInstantPopUp, strPopupText, eAnchor, bForce)
	if not bForce and g_InterfaceOptions and not g_InterfaceOptions.Carbine.bShowTutorials then
		return
	end
	
	self:OnForceTutorial(nTutorialId, bInstantPopUp, strPopupText, eAnchor)
end

function TutorialPrompts:OnForceTutorial(nTutorialId, bInstantPopUp, strPopupText, eAnchor)
	if nTutorialId == nil then
		return 
	end

	if GameLib.IsTutorialNoPageAlert(nTutorialId) == true then -- is it a no-page alert?
		if eAnchor ~= nil and eAnchor ~= GameLib.CodeEnumTutorialAnchor.None then  -- Hint Window check; it will draw on the return event
			Event_FireGenericEvent("Tutorial_RequestUIAnchor", eAnchor, nTutorialId, strPopupText)
		end
		return
	else
		if eAnchor ~= nil and eAnchor ~= GameLib.CodeEnumTutorialAnchor.None and strPopupText ~= nil then
			Event_FireGenericEvent("Tutorial_RequestUIAnchor", eAnchor, nTutorialId, strPopupText)
		end
	end

	local tTutorial = GameLib.GetTutorial(nTutorialId)  -- tTutorial is an array of tutorial tables. Whee!
	if tTutorial == nil then
		return
	end

	-- Instant, don't queue
	if bInstantPopUp == true or tTutorial[1].nLayoutId == 8 then
		GameLib.MarkTutorialViewed(nTutorialId, true)
		self:DrawTutorialPage(nTutorialId)
		return
	end

	table.insert(self.tPendingTutorials, nTutorialId)

	self:UpdateAlerts()
end

function TutorialPrompts:OnShowTutorialTest(nTutorialId, bInstantPopUp, strPopupText, eAnchor)

	if strPopupText ~= nil and strPopupText ~= "" and eAnchor ~= nil and eAnchor ~= GameLib.CodeEnumTutorialAnchor.None then  -- Hint Window check; it will draw on the return event
		Event_FireGenericEvent("Tutorial_RequestUIAnchor", eAnchor, nTutorialId, strPopupText)
		return
	end

	local tTutorial = GameLib.GetTutorial(nTutorialId)  -- tTutorial is an array of tutorial tables. Whee!
	if tTutorial == nil then
		return
	end

	-- Instant, don't queue
	if bInstantPopUp == true or tTutorial[1].nLayoutId == 8 then
		GameLib.MarkTutorialViewed(nTutorialId, true)
		self:DrawTutorialPage(nTutorialId)
		return
	end

	table.insert(self.tPendingTutorials, nTutorialId)

	self:UpdateAlerts()
end

function TutorialPrompts:OnAutoCloseTutorialInterval()
	for idx,wndTutorial in ipairs(self.tAutoCloseTutorials) do
		if wndTutorial:IsValid() then
			local wndTimer = wndTutorial:FindChild("Timer")
			if wndTimer:GetData() == 0 then --1 second left
				wndTutorial:Close()
				table.remove(self.tAutoCloseTutorials, idx)
			else
				local nTimeLeft = wndTimer:GetData() - 1
				 wndTimer:SetData(nTimeLeft)
				 
				 if nTimeLeft <= 10 then --display a timer when auto closing will complete
					wndTimer:SetText(nTimeLeft)
				end
			end
		else
			table.remove(self.tAutoCloseTutorials, idx)
		end
	end
	
	if #self.tAutoCloseTutorials == 0 then
		self.timerAutoClose:Stop()
		self.wndAlertContainer:DestroyChildren()
	end
end

function TutorialPrompts:AddAutoCloseTutorial(wndTutorial)
	wndTutorial:FindChild("Timer"):SetData(30) --#of seconds to count down from.
	
	--timer stops if the count is 0. We're about to add one so restart it.
	if #self.tAutoCloseTutorials == 0 then
		self.timerAutoClose:Start()
	end
	
	table.insert(self.tAutoCloseTutorials, wndTutorial)
end

function TutorialPrompts:UpdateAlerts()
	self.wndAlertContainer:DestroyChildren()

	if not g_InterfaceOptions or g_InterfaceOptions.Carbine.bShowTutorials then
		if #self.tPendingTutorials > 5 then
			local wndMore = Apollo.LoadForm(self.xmlDoc, "TutorialAlertMore", self.wndAlertContainer, self)
			wndMore:Show(true)
			--wndMore:FindChild("TransitionSprite"):SetSprite("sprWinAnim_BirthSmallTemp")
		end

		for i = 1, 5 do
			if self.tPendingTutorials[i] ~= nil then
				local tTutorial = GameLib.GetTutorial(self.tPendingTutorials[i])
				local wnd = Apollo.LoadForm(self.xmlDoc, "TutorialAlert", self.wndAlertContainer, self)
				wnd:SetData(self.tPendingTutorials[i])
				wnd:FindChild("TutorialAlertBtn"):SetData(self.tPendingTutorials[i])
				wnd:SetTooltip(String_GetWeaselString(Apollo.GetString("Tutorials_ClickToLearn"), tTutorial[1].strTitle))
				wnd:Show(true)
				wnd:FindChild("IconHoverGlow"):Show(false, true)
				
				self:AddAutoCloseTutorial(wnd)
			end
		end

		self.wndAlertContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)
	end
end

---------------------------------------------------------------------------------------------------
-- Alert Functions
---------------------------------------------------------------------------------------------------
function TutorialPrompts:OnTutorialMoreBtn(wndHandler, wndControl)
	Event_FireGenericEvent("GenericEvent_OpenTutorialMenu")
end

function TutorialPrompts:OnTutorialAlertBtn(wndHandler, wndControl)
	-- on click, advance the table by one, remove the last, redraw alerts, remove any prompts
	local nId = wndControl:GetData()

	if nId == nil or wndHandler ~= wndControl then
		return
	end

	self:DrawTutorialPage(nId)
	GameLib.MarkTutorialViewed(nId, true)

	for idx, wnd in pairs(self.tDisplayedPrompts) do
		if wnd:FindChild("HintAlertBtn"):GetData() == nId then
			wnd:Destroy()
			self.tDisplayedPrompts[idx] = nil
		end
	end

	for _, wndAlert in pairs(self.wndAlertContainer:GetChildren()) do
		if wndAlert:GetData() == nId then
			wndAlert:Destroy()
		end
	end

	local nEntryToPull = nil
	for idx, nEntry in pairs(self.tPendingTutorials) do 
		if nEntry == nId then
			self:RemoveAlert(idx)
		end
	end
end

function TutorialPrompts:RemoveAlert(nStartIdx)
	if nStartIdx == nil then
		return
	end

	for idx = nStartIdx, #self.tPendingTutorials do
		if self.tPendingTutorials[idx + 1] ~= nil then
			self.tPendingTutorials[idx] = self.tPendingTutorials[idx + 1]
		end
	end

	self.tPendingTutorials[#self.tPendingTutorials] = nil

	self:UpdateAlerts()
end

---------------------------------------------------------------------------------------------------
-- HintWindow Functions
---------------------------------------------------------------------------------------------------
function TutorialPrompts:OnHintMouseEnter(wndHandler, wndControl)
	if wndHandler ~= wndControl then return false end
	wndControl:FindChild("HintAlertBtn"):Show(true)
end

function TutorialPrompts:OnHintMouseExit(wndHandler, wndControl)
	if wndHandler ~= wndControl then return false end
	wndControl:FindChild("HintAlertBtn"):Show(false)
end

---------------------------------------------------------------------------------------------------
-- Tutorial Panel Functions
---------------------------------------------------------------------------------------------------
function TutorialPrompts:DrawTutorialPage(nTutorialId, nPassedPage) --(wndArg, nCurrPage, tTutorial, nTutorialId)

	GameLib.StopTutorialSound() -- Stops any sounds currently being played by the Tutorial system

	for idx, wnd in pairs(self.wndForms) do
		wnd:Close()
	end

	self.wndTransparentTutorial = nil

	local tTutorial = GameLib.GetTutorial(nTutorialId)
	local nCurrPage = nPassedPage or 1

	if tTutorial == nil then return false end

	local wnd = self.wndForms[tTutorial[nCurrPage].nLayoutId]

	if wnd == nil then return false end

	if tTutorial[nCurrPage].nLayoutId == 8 then -- TODO: REALLY DICEY; we're hardcoding the value for "transparent"
		self:DrawTransparentTutorialPage(nTutorialId, nPassedPage)
		return
	end

	-- Reset before updating
	wnd:FindChild("Body"):Show(false)
	wnd:FindChild("BodyFrameBG"):Show(false)
	if wnd:FindChild("BodyLeft") and wnd:FindChild("BodyRight") then
		wnd:FindChild("BodyLeft"):Show(false)
		wnd:FindChild("BodyRight"):Show(false)
	end

	wnd:FindChild("SpriteContainer"):Show(false)
	if wnd:FindChild("SpriteContainerLeft") and wnd:FindChild("SpriteContainerRight") then
		wnd:FindChild("SpriteContainerLeft"):Show(false)
		wnd:FindChild("SpriteContainerRight"):Show(false)
	end

	-- Set the "view" toggle for the tutorial's category (carrying the option for additional pages)
	if wnd:FindChild("HideCategoryBtn") ~= nil then
		local nType = tTutorial.eTutorialCategory
		local strHideCategory = String_GetWeaselString(Apollo.GetString("Tutorials_DontShowVar"), String_GetWeaselString(Apollo.GetString("CRB_Quotes"),ktCategories[nType]))
		if nCurrPage == 1 then -- get the setting from page 1
			self.bTypeViewSetting = not GameLib.IsTutorialCategoryVisible(nType) and not self.bAllViewSetting
		end

		wnd:FindChild("HideCategoryBtn"):SetData(nType)
		wnd:FindChild("HideCategoryBtn"):SetCheck(self.bTypeViewSetting and not self.bAllViewSetting)
		wnd:FindChild("HideCategoryBtn"):SetText(strHideCategory)
		wnd:FindChild("HideCategoryBtn"):Show(not self.bAllViewSetting)
	end
	
	if wnd:FindChild("HideAllBtn") ~= nil then
		wnd:FindChild("HideAllBtn"):SetCheck(self.bAllViewSetting)
		wnd:FindChild("HideAllBtn"):Show(not self.bAllViewSetting)
	end

	-- Figure out to show just the body/sprite or if we need to show bodyleft and bodyright
	local nOnGoingHeight = 0
	for idx, strCurrText in ipairs(tTutorial[nCurrPage].tBody) do
		local wndToDo = nil
		local nTextPadding = 12
		local nWindowPadding = 0
		local bStrCurrTextExists = strCurrText and Apollo.StringLength(strCurrText) > 0
		local strAsAML = "<P Font=\"CRB_InterfaceMedium\" TextColor=\"BabyPurple\" Align=\"Left\">"..strCurrText.."</P>"
		Sound.Play(Sound.PlayUIMiniMapPing)
		wnd:FindChild("BGArt_Refresh"):SetSprite("BK3:UI_BK3_Holo_RefreshReflectionSquare_anim")

		if idx == 1 and bStrCurrTextExists then
			wnd:FindChild("Body"):Show(true)
			wnd:FindChild("BodyFrameBG"):Show(true)
			wnd:FindChild("Body"):SetAML(strAsAML)
			if wnd:GetName() ~= "TutorialForm_ExtraLarge" then
				local nTextWidth, nTextHeight = wnd:FindChild("Body"):SetHeightToContentHeight()
				local nBGLeft, nBGTop, nBGRight, nBGBottom = wnd:FindChild("BodyFrameBG"):GetOriginalLocation():GetOffsets()
				if (nTextHeight + nTextPadding) > (nBGTop - nBGBottom) then
					nOnGoingHeight = nTextHeight - (nBGTop - nBGBottom)
				end
			end
		elseif idx == 2 and wnd:FindChild("BodyLeft") and bStrCurrTextExists then
			wnd:FindChild("BodyLeft"):Show(true)
			wnd:FindChild("BodyLeftText"):SetAML(strAsAML)
			local nLeft, nTop, nRight, nBottom = wnd:FindChild("BodyLeft"):GetOriginalLocation():GetOffsets()
			local nTextWidth, nTextHeight = wnd:FindChild("BodyLeftText"):SetHeightToContentHeight()
			local nHeight = wnd:FindChild("BodyLeft"):GetHeight()
			if nTextHeight + nTextPadding > nHeight  then
				wnd:FindChild("BodyLeft"):SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTextHeight + nTextPadding)
				nOnGoingHeight = nTextHeight + nTextPadding - nHeight  
			else
				wnd:FindChild("BodyLeft"):SetAnchorOffsets(nLeft, nTop, nRight, nBottom )			
			end
		elseif idx == 3 and wnd:FindChild("BodyRight") and bStrCurrTextExists then
			wnd:FindChild("BodyRight"):Show(true)
			wnd:FindChild("BodyRightText"):SetAML(strAsAML)
			local nLeft, nTop, nRight, nBottom = wnd:FindChild("BodyRight"):GetOriginalLocation():GetOffsets()
			local nTextWidth, nTextHeight = wnd:FindChild("BodyRightText"):SetHeightToContentHeight()
			local nHeight = wnd:FindChild("BodyRight"):GetHeight()
			if nTextHeight + nTextPadding > nHeight  then
				wnd:FindChild("BodyRight"):SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTextHeight + nTextPadding)
				nOnGoingHeight = nOnGoingHeight + nTextHeight + nTextPadding - nHeight
			else
				wnd:FindChild("BodyRight"):SetAnchorOffsets(nLeft, nTop, nRight, nBottom )			
			end
		end
	end

	for idx, strCurrSprite in ipairs(tTutorial[nCurrPage].tSprites) do
		local bStrCurrSpriteExists = strCurrSprite and Apollo.StringLength(strCurrSprite) > 0
		if idx == 1 and bStrCurrSpriteExists then
			wnd:FindChild("SpriteContainer"):Show(true)
			wnd:FindChild("Sprite"):SetSprite(strCurrSprite)
		elseif idx == 2 and wnd:FindChild("SpriteContainerLeft") and bStrCurrSpriteExists then
			wnd:FindChild("SpriteContainerLeft"):Show(true)
			wnd:FindChild("SpriteLeft"):SetSprite(strCurrSprite)
		elseif idx == 3 and wnd:FindChild("SpriteContainerRight") and bStrCurrSpriteExists then
			wnd:FindChild("SpriteContainerRight"):Show(true)
			wnd:FindChild("SpriteRight"):SetSprite(strCurrSprite)
		end
	end

	wnd:FindChild("Title"):SetText(tTutorial[nCurrPage].strTitle)

	-- Configure buttons
	if #tTutorial > 1 then -- multipage
		wnd:FindChild("btnNext"):Show(true)
		wnd:FindChild("btnPrevious"):Show(true)
		wnd:FindChild("btnPrevious"):Enable(nCurrPage ~= 1)
		wnd:FindChild("btnCloseBig"):Show(false)
		wnd:FindChild("btnNext"):SetData({ nCurrPage, tTutorial, nTutorialId } )
		wnd:FindChild("btnPrevious"):SetData({ nCurrPage, tTutorial, nTutorialId } )
		if nCurrPage >= #tTutorial then
			wnd:FindChild("btnNext"):SetText(Apollo.GetString("Tutorials_Finish"))
		else
			wnd:FindChild("btnNext"):SetText(Apollo.GetString("Tutorials_NextPage"))
		end
	else
		wnd:FindChild("btnNext"):Show(false)
		wnd:FindChild("btnPrevious"):Show(false)
		wnd:FindChild("btnCloseBig"):Show(true)
	end
	
	self.btnNextIsShown = wnd:FindChild("btnNext"):IsShown()

	-- TODO: Refactor this resize code. Also verify if it even works.
	if tTutorial[nCurrPage].wndRel then
		local nRelX, nRelY = TutorialLib.GetPos(tTutorial[nCurrPage].wndRel, tTutorial[nCurrPage].relPos)
		local nOffsetX, nOffsetY = tTutorial[nCurrPage].spacing, tTutorial[nCurrPage].spacing

		local nCompH = TutorialLib.PosCompareHoriz(tTutorial[nCurrPage].tutorialPos, tTutorial[nCurrPage].relPos)
		if nCompH < 0 then
			nOffsetX = -nOffsetX
		elseif nCompH == 0 then
			nOffsetX = 0
		end

		local nCompV = TutorialLib.PosCompareVert(tTutorial[nCurrPage].tutorialPos, tTutorial[nCurrPage].relPos)
		if nCompV < 0 then
			nOffsetY = -nOffsetY
		elseif nCompV == 0 then
			nOffsetY = 0
		end

		local nNewX, nNewY = TutorialLib.AlignPos(wnd, tTutorial[nCurrPage].tutorialPos, nRelX, nRelY, nOffsetX, nOffsetY)
		wnd:Move(nNewX, nNewY, wnd:GetWidth(), wnd:GetHeight())
	end

	-- Resize
	local tDefaultDimensions = wnd:GetData()
	local nLeft = tDefaultDimensions.nLeft
	local nTop = tDefaultDimensions.nTop
	local nWidth = tDefaultDimensions.nWidth +  nLeft
	local nHeight = tDefaultDimensions.nHeight +  nTop + nOnGoingHeight
	wnd:SetAnchorOffsets(nLeft, nTop,  nWidth, nHeight)

	-- Play Sound
	if GameLib.HasTutorialSound(nTutorialId, nPassedPage) == true then
		GameLib.PlayTutorialSound(nTutorialId, nPassedPage)
		-- set data
	end

	wnd:Invoke()
end

function TutorialPrompts:OnWindowMove(wndHandler, wndControl)
	local tWndData = wndHandler:GetData()
	local nLeft, nTop = wndHandler:GetAnchorOffsets()
	tWndData.nLeft = nLeft
	tWndData.nTop = nTop
	wndHandler:SetData(tWndData)--saving left and top, windows width and height doesn't change while moving
end
--------------------------------------------------------------------------------------------
-- Custom function for transparent tutorials; these only have 1 page and should have a sound
function TutorialPrompts:DrawTransparentTutorialPage(nTutorialId, nPassedPage)

	local tTutorial = GameLib.GetTutorial(nTutorialId)
	local nCurrPage = nPassedPage or 1
	self.wndTransparentTutorial = self.wndForms[tTutorial[nCurrPage].nLayoutId]

	-- should only ever have 1 sprite
	for idx, strCurrSprite in ipairs(tTutorial[nCurrPage].tSprites) do
		local bStrCurrSpriteExists = strCurrSprite and Apollo.StringLength(strCurrSprite) > 0
		if idx == 1 and bStrCurrSpriteExists then
			self.wndTransparentTutorial:FindChild("Sprite"):SetSprite(strCurrSprite)
		end
	end

	-- Play Sound
	if GameLib.HasTutorialSound(nTutorialId, nPassedPage) == true then
		GameLib.PlayTutorialSound(nTutorialId, nPassedPage)
	end

	self.wndTransparentTutorial:Invoke()
end


--------------------------------------------------------------------------------------------
function TutorialPrompts:OnClose(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end -- wndHandler is 'btnClose'
	
	wndControl:GetParent():Close()
	GameLib.StopTutorialSound()
end

function TutorialPrompts:OnTransparentWindowClose(wndHandler, wndControl)
	if self.wndTransparentTutorial ~= nil then
		self.wndTransparentTutorial = nil
	end
	GameLib.StopTutorialSound()
end

function TutorialPrompts:OnTutorialWindowClosed(wndHandler, wndControl)
	GameLib.StopTutorialSound()

	if wndControl:FindChild("HideCategoryBtn") == nil then return end

	-- check the current setting for hiding the category and adjust if needed
	local nType = wndControl:FindChild("HideCategoryBtn"):GetData()
	if nType ~= nil and (GameLib.IsTutorialCategoryVisible(nType) == wndControl:FindChild("HideCategoryBtn"):IsChecked() or wndControl:FindChild("HideAllBtn"):IsChecked()) then
		GameLib.ToggleTutorialVisibilityFlags(nType)
	end
end

function TutorialPrompts:ShowNext(wndHandler, wndControl)
	if not wndHandler or not wndHandler:GetData() then return end -- wndHandler is 'btnNext' and its data is { nCurrPage, tTutorial, nTutorialId }
	
	if self.bAllViewSetting then
		self:OnClose(wndHandler, wndControl)
	end

	local nCurrPage = wndHandler:GetData()[1]
	local tTutorial = wndHandler:GetData()[2]
	local nTutorialId = wndHandler:GetData()[3]

	if nCurrPage < #tTutorial then
		self:DrawTutorialPage(nTutorialId, nCurrPage + 1)
	else
		wndHandler:GetParent():Close()
	end
end

function TutorialPrompts:ShowPrevious(wndHandler, wndControl)
	if not wndHandler or not wndHandler:GetData() then return end -- wndHandler is 'btnNext' and its data is { nCurrPage, tTutorial, nTutorialId }
	
	if self.bAllViewSetting then
		wndHandler:GetParent():Close()
	end
	
	local nCurrPage = wndHandler:GetData()[1]
	local tTutorial = wndHandler:GetData()[2]
	local nTutorialId = wndHandler:GetData()[3]

	if nCurrPage > 1 then
		self:DrawTutorialPage(nTutorialId, nCurrPage - 1)
	end
end

function TutorialPrompts:OnTypeViewToggle(wndHandler, wndControl)
	self.bTypeViewSetting = wndControl:IsChecked()
	self.bAllViewSetting = not wndControl:IsChecked()
end

function TutorialPrompts:OnAllViewToggle(wndHandler, wndControl)
	self.bTypeViewSetting = not wndControl:IsChecked()
	
	g_InterfaceOptions.Carbine.bShowTutorials = not wndControl:IsChecked()
	Event_FireGenericEvent("OptionsUpdated_ShowTutorials")
end

function TutorialPrompts:OnShowTutorialsUpdated()
	self.bAllViewSetting = not g_InterfaceOptions.Carbine.bShowTutorials
end

function TutorialPrompts:OnPreviewTutorialBtn(wndHandler, wndControl)
	local tTutorial = wndControl:GetData()

	-- Send the signal for the tutorial
	if tTutorial ~= nil then
		self:OnShowTutorialTest(tTutorial.id, false, tTutorial.strPopupText, tTutorial.eAnchor)
	end
end


---------------------------------
-- Tutorial Callouts
---------------------------------
function TutorialPrompts:ShowTutorialCallout(eAnchor, idTutorial, strPopupText, wndAnchor, eOrientationOverride)
	if self.tVisibleCallouts[eAnchor] then
		return
	end
	
	local wndTutorial = Apollo.LoadForm("TutorialPrompts.xml", "HintWindow", wndAnchor, self)
	wndTutorial:SetData(eAnchor)
	wndTutorial:FindChild("btnClose"):SetData(eAnchor)
	
	local tTutorial	 = GameLib.GetTutorial(idTutorial)

	if tTutorial then
		wndTutorial:FindChild("PanelToggleContainer"):Show(true)
		wndTutorial:FindChild("BGArt_Prompt"):Show(true)
		local wndHint = wndTutorial:FindChild("PanelToggleContainer:HintAlertBtn")
		wndHint:Show(false, true)
		wndHint:SetData(idTutorial)
	else
		wndTutorial:FindChild("PanelToggleContainer"):Show(false)
		wndTutorial:FindChild("BGArt_NoPrompt"):Show(true)
		GameLib.MarkTutorialViewed(idTutorial, true)
		Sound.Play(Sound.PlayUIMiniMapPing)
	end
	
	-- Setting text and resizing
	local wndText = wndTutorial:FindChild("HintTextWnd")
	wndText:SetText(strPopupText)	
	wndText:SetHeightToContentHeight()
	
	local nTextLeft, nTextTop, nTextRight, nTextBottom = wndText:GetAnchorOffsets()
	local nTextOldLeft, nTextOldTop, nTextOldRight, nTextOldBottom = wndText:GetOriginalLocation():GetOffsets()
	local nTutorialLeft, nTutorialTop, nTutorialRight, nTutorialBottom = wndTutorial:GetAnchorOffsets()
	local nTextHeight = nTextBottom - nTextTop

	if nTextHeight < (nTextOldBottom - nTextOldTop) then -- smaller than default box size;don't resize the frame, just center the text
		local nWndHeight = wndTutorial:GetHeight()
		wndText:SetAnchorOffsets(nTextLeft, (nWndHeight / 2) - (nTextHeight / 2), nTextRight, (nWndHeight / 2) + (nTextHeight / 2))
	else
		wndTutorial:SetAnchorOffsets(nTutorialLeft, nTutorialTop, nTutorialRight, nTextBottom + (nTutorialBottom - nTextOldBottom))
	end
	
	-- Moving the window and setting up the arrow animation
	local tAnchorInfo = GameLib.GetTutorialAnchorInfo(eAnchor)

	if tAnchorInfo == nil then 
		return
	end
	
	local eOrientation = tAnchorInfo.eTutorialAnchorOrientation
	if eOrientationOverride then
		eOrientation = eOrientationOverride
	end

	local tWindowLocation = {}
	local wndConnector = wndTutorial:FindChild("ConnectorContainer:Connector" .. eOrientation)
	local tData = 
	{
		locStart = wndConnector:GetLocation(),
		locEnd = nil,
		nCount = 1,
	}

	local tLocEnd = tData.locStart:ToTable()
	local nArrowEndLocLeft, nArrowEndLocTop, nArrowEndLocRight, nArrowEndLocBottom = tData.locStart:GetOffsets()
	
	local nNewWidth = wndTutorial:GetWidth()
	local nNewHeight = wndTutorial:GetHeight()
	
	local nArrowWidth = wndConnector:GetWidth()
	local nArrowHeight = wndConnector:GetHeight()
	
	local nAnchorWidth = wndAnchor:GetWidth()
	local nAnchorHeight = wndAnchor:GetHeight()

	-- Calculating the window's horizontal position and the arrow's horizontal animation
	if ktHOrientation.tEast[eOrientation] then
		tWindowLocation.Left = tAnchorInfo.nHorizOffset - nArrowWidth - nNewWidth
		
		nArrowEndLocLeft = nArrowEndLocLeft + knAnimationOffset
		nArrowEndLocRight = nArrowEndLocRight + knAnimationOffset
	elseif ktHOrientation.tWest[eOrientation] then
		tWindowLocation.Left = tAnchorInfo.nHorizOffset + nArrowWidth + nAnchorWidth
		
		nArrowEndLocLeft = nArrowEndLocLeft - knAnimationOffset
		nArrowEndLocRight = nArrowEndLocRight - knAnimationOffset
	elseif ktHOrientation.tCenter[eOrientation] then
		tWindowLocation.Left = tAnchorInfo.nHorizOffset - (nNewWidth / 2) + (nAnchorWidth / 2)
	end
	
	-- Calculating the window's vertical position and the arrow's vertical animation
	if ktVOrientation.tNorth[eOrientation] then
		tWindowLocation.Top = tAnchorInfo.nVertOffset + nArrowHeight + nAnchorHeight
		
		nArrowEndLocTop = nArrowEndLocTop - knAnimationOffset
		nArrowEndLocBottom = nArrowEndLocBottom - knAnimationOffset
	elseif ktVOrientation.tSouth[eOrientation] then
		tWindowLocation.Top = tAnchorInfo.nVertOffset - nArrowHeight - nNewHeight
		
		nArrowEndLocTop = nArrowEndLocTop + knAnimationOffset
		nArrowEndLocBottom = nArrowEndLocBottom + knAnimationOffset
	elseif ktVOrientation.tCenter[eOrientation] then
		tWindowLocation.Top = tAnchorInfo.nVertOffset - (nNewHeight / 2) + (nAnchorHeight / 2)
	end
	
	wndTutorial:Move(tWindowLocation.Left, tWindowLocation.Top, nNewWidth, nNewHeight)

	tLocEnd.nOffsets = {nArrowEndLocLeft, nArrowEndLocTop, nArrowEndLocRight, nArrowEndLocBottom}
	tData.locEnd = WindowLocation.new(tLocEnd)
	wndConnector:SetData(tData)
	wndConnector:TransitionMove(tData.locEnd, knOutAnimationTime, Window.MoveMethod.EaseInQuart)
	
	wndConnector:Show(true)
	wndTutorial:Show(true)
	
	self.tVisibleCallouts[eAnchor] = wndTutorial
	self:AddAutoCloseTutorial(wndTutorial)
end

function TutorialPrompts:HideTutorialCallout(eAnchor)
	if self.tVisibleCallouts[eAnchor] and self.tVisibleCallouts[eAnchor]:IsValid() then
		self.tVisibleCallouts[eAnchor]:Close()
	end
end

function TutorialPrompts:OnCloseCalloutBtn(wndHandler, wndControl)
	if wndHandler == wndControl then
		local eAnchor = wndHandler:GetData()
		if self.tVisibleCallouts[eAnchor] then
			self.tVisibleCallouts[eAnchor]:Close()
			self.tVisibleCallouts[eAnchor] = nil
		end
	end
end

function TutorialPrompts:OnWindowTransitionComplete(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local tAnimationData = wndHandler:GetData()
	tAnimationData.nCount = tAnimationData.nCount + 1

	if tAnimationData.nCount % 2 == 0 then
		wndHandler:TransitionMove(tAnimationData.locStart, knInAnimationTime, Window.MoveMethod.EaseOutQuad)
	else
		wndHandler:TransitionMove(tAnimationData.locEnd, knOutAnimationTime, Window.MoveMethod.EaseInQuart)
	end
	
	wndHandler:SetData(tAnimationData)
end

-----------------------------------------------------------------------------------------------
-- TutorialPrompts Instance
-----------------------------------------------------------------------------------------------
local TutorialPromptsInst = TutorialPrompts:new()
TutorialPromptsInst:Init()