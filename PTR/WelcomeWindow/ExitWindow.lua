-----------------------------------------------------------------------------------------------
-- Client Lua Script for ExitWindow
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
 
local ExitWindow = {} 

local keSortPosition = 
{
	Right = 1,
	Middle = 2,
	Left = 3,
}

local knUnanswered = -1

function ExitWindow:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    o.kstrTitle = Apollo.GetString("Overview_Title")

    return o
end

function ExitWindow:Init()
    Apollo.RegisterAddon(self, false, self.kstrTitle)
end
 
function ExitWindow:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ExitWindow.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function ExitWindow:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	--Other Addons
	Apollo.RegisterEventHandler("ExitWindow_RequestParent",	"OnExitWindowRequestParent", self)

	--Exit
	Apollo.RegisterSlashCommand("camp",							"OnCampSlashCommand", self)
	Apollo.RegisterEventHandler("PlayerCampStart",				"OnPlayerCampStart", self)
	Apollo.RegisterEventHandler("PlayerCampCancel",				"OnPlayerCampCancel", self)

	--Customer Survey
	Apollo.RegisterEventHandler("NewCustomerSurveyRequest", "DrawSurvey", self)

	--Measuring
	local wndMeasure = Apollo.LoadForm(self.xmlDoc, "SurveyRating", wndQuestions, self)
	local nLeft, nTop, nRight, nBottom = wndMeasure:FindChild("Title"):GetAnchorOffsets()
	self.knTitlePadding = nTop - nBottom --(nBottom is anchored to bottom, so subtract negative value)
	wndMeasure:Destroy()

	local tExitInfo = GameLib.GetGameExitInfo()
	if tExitInfo.ePendingEvent == GameLib.CodeEnumExitEvent.Quit or tExitInfo.ePendingEvent == GameLib.CodeEnumExitEvent.Camp then
		self:OnPlayerCampStart()
	end
end

function ExitWindow:OnCampSlashCommand()
	Camp()
	self:OnPlayerCampStart()--Trying to camp when there is a pending camp will NOT fire the event PlayerCampStart.
end

function ExitWindow:OnExitWindowRequestParent()
	if not self.wndTeaser then
		return
	end

	Event_FireGenericEvent("ExitWindow_RequestContent", self.wndTeaser)
end

function ExitWindow:OnPlayerCampStart()
	if self.wndMain then
		self.wndMain:Destroy()
		self.wndMain = nil
	end
	
	local tExitInfo = GameLib.GetGameExitInfo()
	if not tExitInfo then
		return
	end
	
	if tExitInfo.ePendingEvent == GameLib.CodeEnumExitEvent.Camp and tExitInfo.fTimeRemaining <= 0 then
		return
	end

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "ExitWindowOverview", nil, self)
	self:DrawTeaser()
	self:DrawSurvey()

	self.timerGameExit = ApolloTimer.Create(0.5, true, "OnTimer", self)
	self.wndMain:Invoke()
end

function ExitWindow:DrawTeaser()
	local tExitInfo = GameLib.GetGameExitInfo()
	if not tExitInfo then
		return
	end

	local wndContent = self.wndMain:FindChild("Content")
	self.wndTeaser = Apollo.LoadForm(self.xmlDoc, "Teaser", wndContent, self)
	self.wndTeaser:SetData(keSortPosition.Right)
	self.wndMain:FindChild("ExitContent"):Show(false)

	local strMessage = ""
	if tExitInfo.ePendingEvent == GameLib.CodeEnumExitEvent.Quit then
		strMessage = Apollo.GetString("GameExit_TimeTillQuit")
	elseif tExitInfo.ePendingEvent == GameLib.CodeEnumExitEvent.Camp then
		strMessage = Apollo.GetString("GameExit_TimeTillCamp")
	end
	self.wndMain:FindChild("Message"):SetText(strMessage)

	Event_FireGenericEvent("ExitWindow_RequestContent", self.wndTeaser)
end

function ExitWindow:DrawSurvey()
	if not self.wndMain then
		return
	end

	self.csActiveSurvey = nil
	for idx, csActiveSurvey in pairs(CustomerSurveyLib.GetPending()) do
		if csActiveSurvey:GetSurveyId() == CustomerSurveyLib.CodeEnumCustomerSurvey.LogOff then
			self.csActiveSurvey = csActiveSurvey
			break
		end
	end

	if not self.csActiveSurvey then
		return
	end

	self.arAnswers = {}

	local wndExitWindow = self.wndMain:FindChild("ExitWindow")
	local wndContent = wndExitWindow:FindChild("Content")

	local wndBreak = Apollo.LoadForm(self.xmlDoc, "Break", wndContent, self)
	wndBreak:SetData(keSortPosition.Middle)

	self.wndExitSurvey = Apollo.LoadForm(self.xmlDoc, "ExitSurvey", wndContent, self)
	self.wndExitSurvey:SetData(keSortPosition.Left)

	local wndQuestions = self.wndExitSurvey:FindChild("Questions")
	for idx, strQuestion in pairs(self.csActiveSurvey:GetQuestions()) do
		local wndSurveyRating = Apollo.LoadForm(self.xmlDoc, "SurveyRating", wndQuestions, self)
		local wndTitle = wndSurveyRating:FindChild("Title")
		wndTitle:SetText(strQuestion)
		local nWidth, nHeight = wndTitle:SetHeightToContentHeight()
		local wndTitleFraming = wndSurveyRating:FindChild("TitleFraming")
		local nLeft, nTop, nRight, nBottom = wndTitleFraming:GetAnchorOffsets()
		local nNewBottom = nTop + nHeight + self.knTitlePadding

		wndTitleFraming:SetAnchorOffsets(nLeft, nTop, nRight, nNewBottom)

		local wndBodyFraming = wndSurveyRating:FindChild("BodyFraming")
		nLeft, nTop, nRight, nBottom = wndBodyFraming:GetAnchorOffsets()
		wndBodyFraming:SetAnchorOffsets(nLeft, nNewBottom, nRight, nBottom + nNewBottom)

		nLeft, nTop, nRight, nBottom = wndSurveyRating:GetAnchorOffsets()
		wndSurveyRating:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeight - self.knTitlePadding)

		self.arAnswers[idx] = knUnanswered--Marking this question hasn't been answered.
		wndBodyFraming:FindChild("RatingScale"):SetData(idx)
	end

	local wndSurveyInput = Apollo.LoadForm(self.xmlDoc, "SurveyInput", wndQuestions, self)
	wndQuestions:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	wndQuestions:RecalculateContentExtents()

	wndContent:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:GetData() > b:GetData() end)

	local nHalfNewWidth = self.wndExitSurvey:GetWidth() / 2
	local nLeft, nTop, nRight, nBottom = wndExitWindow:GetOriginalLocation():GetOffsets()
	nLeft = nLeft - nHalfNewWidth
	nRight = nRight + nHalfNewWidth

	--Ensure Content appears in order: survey, line, and teaser.
	wndExitWindow:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
end

function ExitWindow:OnTimer(nTime)
	local tExitInfo = GameLib.GetGameExitInfo()
	if not tExitInfo or not self.wndMain then--make sure the timer is not running when no main
		return
	end

	local bCountDown = tExitInfo.fTimeRemaining > 0
	local wndExitContent = self.wndMain:FindChild("ExitContent")
	wndExitContent:Show(bCountDown)
	self.wndMain:FindChild("btnExitGame"):Enable(not bCountDown or tExitInfo.ePendingEvent == GameLib.CodeEnumExitEvent.Quit)
	if bCountDown then
		local nSeconds = math.floor(tExitInfo.fTimeRemaining)
		local strOutput = Apollo.GetString("GameExit_NumTimer")
		if nSeconds < 10 then
			strOutput = Apollo.GetString("GameExit_ShortTimer")
		end
		wndExitContent:FindChild("Timer"):SetText(String_GetWeaselString(strOutput, nSeconds))
	end
end

function ExitWindow:OnSubmitSurveyResponse(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self.csActiveSurvey:SetResults(self.arAnswers)
	self.csActiveSurvey:SetComment(self.wndExitSurvey:FindChild("SurveyInput"):FindChild("Input"):GetText())
	self.csActiveSurvey:SendResult()

	self.wndExitSurvey:Destroy()
	self.wndExitSurvey = nil
	self.csActiveSurvey = nil

	local wndContent = self.wndMain:FindChild("Content")
	local wndBlockerMessage = Apollo.LoadForm(self.xmlDoc, "BlockerMessage", wndContent, self)
	wndBlockerMessage:SetData(keSortPosition.Left)
	wndContent:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:GetData() > b:GetData() end)
end

function ExitWindow:OnQuestionAnswered(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local wndBodyFraming = wndHandler:GetParent()
	self.arAnswers[wndBodyFraming:GetData()] = wndBodyFraming:GetRadioSel("SurveyResult")--This question is now answered.

	local bComplete = true
	for idx, nValue in pairs(self.arAnswers) do
		if nValue == knUnanswered then
			bComplete = false
			break
		end
	end

	self.wndExitSurvey:FindChild("btnSubmitSurvey"):Enable(bComplete)
end

function ExitWindow:OnExitGameBtn()
	ConfirmCamp()
	self:CleanUp()
end

function ExitWindow:OnPlayerCampCancel()
	self:OnCancel()
end

function ExitWindow:OnCancel()
	CancelExit()
	self:CleanUp()
end

function ExitWindow:CleanUp()
	if self.timerGameExit then
		self.timerGameExit:Stop()
		self.timerGameExit = nil
	end

	if self.wndMain then
		self.wndMain:Destroy()
		self.wndMain = nil
		self.wndExitSurvey = nil
		self.wndTeaser = nil
	end
end

-----------------------------------------------------------------------------------------------
-- ExitWindow Instance
-----------------------------------------------------------------------------------------------
local ExitWindowInst = ExitWindow:new()
ExitWindowInst:Init()
