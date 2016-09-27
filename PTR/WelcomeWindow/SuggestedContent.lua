-----------------------------------------------------------------------------------------------
-- Client Lua Script for WelcomeWindow/SuggesteContent
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "ContentFinderLib"
require "MatchMakingLib"
require "MatchMakingEntry"
require "QuestHub"
 
local SuggesteContent = {} 
 
function SuggesteContent:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
    o.kstrTitle = Apollo.GetString("SuggestedContent_Title")
    o.knSortOrder = 4

    o.ktTypeNames = 
	{
		[MatchMakingLib.MatchType.Shiphand] 			= Apollo.GetString("MatchMaker_Shiphands"),
		[MatchMakingLib.MatchType.Adventure] 			= Apollo.GetString("MatchMaker_Adventures"),
		[MatchMakingLib.MatchType.Dungeon] 			= Apollo.GetString("CRB_Dungeons"),
		[MatchMakingLib.MatchType.Battleground]		= Apollo.GetString("MatchMaker_Battlegrounds"),
		[MatchMakingLib.MatchType.RatedBattleground] 	= Apollo.GetString("MatchMaker_Battlegrounds"),
		[MatchMakingLib.MatchType.Warplot] 			= Apollo.GetString("MatchMaker_Warplots"),
		[MatchMakingLib.MatchType.OpenArena] 			= Apollo.GetString("MatchMaker_Arenas"),
		[MatchMakingLib.MatchType.Arena] 				= Apollo.GetString("MatchMaker_Arenas"),
	}

	o.ktSuggestedTypes = 
	{
		PvE = 1, 
		PvP = 2, 
		Quest = 3, 
	}

	o.ktMatchImages = 
	{
		[MatchMakingLib.MatchType.Shiphand] 			= "WelcomeWindow:WelcomeWindow_SuggestedContent_Expedition",
		[MatchMakingLib.MatchType.Adventure] 			= "WelcomeWindow:WelcomeWindow_SuggestedContent_Adventure",
		[MatchMakingLib.MatchType.Dungeon] 			= "WelcomeWindow:WelcomeWindow_SuggestedContent_Dungeon",
		[MatchMakingLib.MatchType.Battleground]		= "WelcomeWindow:WelcomeWindow_SuggestedContent_Battleground",
		[MatchMakingLib.MatchType.RatedBattleground] 	= "WelcomeWindow:WelcomeWindow_SuggestedContent_Battleground",
		[MatchMakingLib.MatchType.Warplot] 			= "WelcomeWindow:WelcomeWindow_SuggestedContent_Warplot",
		[MatchMakingLib.MatchType.OpenArena] 			= "WelcomeWindow:WelcomeWindow_SuggestedContent_Arena",
		[MatchMakingLib.MatchType.Arena] 				= "WelcomeWindow:WelcomeWindow_SuggestedContent_Arena",
	}

	o.ktQuestTypes = 
	{
		Hub = 	  "WelcomeWindow:WelcomeWindow_SuggestedContent_Quest", 
		Episode = "WelcomeWindow:WelcomeWindow_SuggestedContent_Quest", 
		Quest =   "WelcomeWindow:WelcomeWindow_SuggestedContent_Quest", 
	}

	o.tSuggestedListItems = {}
    return o
end

function SuggesteContent:Init()
    Apollo.RegisterAddon(self, false, self.kstrTitle)
end
 
function SuggesteContent:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("SuggestedContent.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function SuggesteContent:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	--WelcomeWindow Events
	Apollo.RegisterEventHandler("WelcomeWindow_Loaded", 		"OnWelcomeWindowLoaded", self)
	Apollo.RegisterEventHandler("WelcomeWindow_TabSelected",	"OnWelcomeWindowTabSelected", self)
	Apollo.RegisterEventHandler("WelcomeWindow_Closed",			"OnClose", self)
	Event_FireGenericEvent("WelcomeWindow_RequestParent")

	--Updates
	Apollo.RegisterEventHandler("PlayerLevelChange",			"HelperLoadNewContent", self)
	Apollo.RegisterEventHandler("PlayerEnteredWorld", 			"OnPlayerEnteredWorld", self)

	--ExitWindow
	Apollo.RegisterEventHandler("ExitWindow_RequestContent",	"OnExitWindowRequestContent", self)
	Event_FireGenericEvent("ExitWindow_RequestParent")
end

function SuggesteContent:OnWelcomeWindowLoaded(wndParent)
	if not wndParent or not wndParent:IsValid() then
		return
	end

	Apollo.RemoveEventHandler("WelcomeWindow_Loaded", self)

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "SuggestedContentBig", wndParent, self)
	Event_FireGenericEvent("WelcomeWindow_TabContent", self.kstrTitle, self.wndMain, self.knSortOrder)

	Apollo.RegisterEventHandler("OverView_Loaded", 	"OnOverViewLoaded", self)
	Event_FireGenericEvent("OverView_RequestParent")
end

function SuggesteContent:OnOverViewLoaded(strOverViewTitle, wndParent)
	if not wndParent or not wndParent:IsValid() then
		return
	end

	Apollo.RemoveEventHandler("OverView_Loaded", self)
	self.strOverViewTitle = strOverViewTitle--Used to determine if the Overview Tab is selected.
	self.wndSuggestedContentOverview = Apollo.LoadForm(self.xmlDoc, "SuggestedContentOverview", wndParent:FindChild("SuggestedContent"), self)

	self:InitializeContent()
end

function SuggesteContent:OnPlayerEnteredWorld()
	self:InitializeContent()
	self:Redraw()
end

function SuggesteContent:InitializeContent()
	self.tSuggestedInfo = ContentFinderLib.GetSuggestedContent()

	local nCount = 0
	for idx, oSuggestedContent in pairs(self.tSuggestedInfo) do
		nCount = nCount + 1
	end

	local bHaveContent = nCount > 0
	local strTooltip = ""
	if not bHaveContent then
		strTooltip = Apollo.GetString("Matching_NoContentFound")
	end
	Event_FireGenericEvent("WelcomeWindow_EnableTab", self.kstrTitle, bHaveContent, strTooltip)
end

function SuggesteContent:OnWelcomeWindowTabSelected(strSelectedTab)
	if strSelectedTab == self.strOverViewTitle then
		self:RedrawOverViewSection()
	elseif strSelectedTab == self.kstrTitle then
		self:RedrawMainSection()
	end
end

function SuggesteContent:RedrawOverViewSection()
	local nCount = 0
	local arRandContentContainer = {}
	for idx, oSuggestedContent in pairs(self.tSuggestedInfo) do
		table.insert(arRandContentContainer, oSuggestedContent)
		nCount = nCount + 1
	end

	if nCount > 0 then
		self.wndSuggestedContentOverview:FindChild("SuggestedContentDetails"):Show(true)
		self.wndSuggestedContentOverview:FindChild("NoContent"):Show(false)
		local oSuggestedContent = arRandContentContainer[math.random(1, nCount)]
		if MatchMakingEntry.is(oSuggestedContent) then
			self:DrawSuggestedMatch(oSuggestedContent, self.wndSuggestedContentOverview)
		else
			self:DrawSuggestedQuest(oSuggestedContent, self.wndSuggestedContentOverview)
		end
	else
		self.wndSuggestedContentOverview:FindChild("SuggestedContentDetails"):Show(false)
		self.wndSuggestedContentOverview:FindChild("NoContent"):Show(true)
	end

end
function SuggesteContent:RedrawMainSection()
	local wndContentContainer = self.wndMain:FindChild("ContentContainer")

	--There are cached suggested list items, so that they don't need to be destroyed and loaded everytime.
	--Just load them when needed and update the details on them.

	local bLoadedNewListItem = false
	if self.tSuggestedInfo.matchPvE then
		if not self.tSuggestedListItems[self.ktSuggestedTypes.PvE] then
			self.tSuggestedListItems[self.ktSuggestedTypes.PvE]  = Apollo.LoadForm(self.xmlDoc, "SuggestedListItem", wndContentContainer, self)
			bLoadedNewListItem = true
		end
		self:DrawSuggestedMatch(self.tSuggestedInfo.matchPvE, self.tSuggestedListItems[self.ktSuggestedTypes.PvE])
	end

	if self.tSuggestedInfo.matchPvP then
		if not self.tSuggestedListItems[self.ktSuggestedTypes.PvP] then
			self.tSuggestedListItems[self.ktSuggestedTypes.PvP]  = Apollo.LoadForm(self.xmlDoc, "SuggestedListItem", wndContentContainer, self)
			bLoadedNewListItem = true
		end
		self:DrawSuggestedMatch(self.tSuggestedInfo.matchPvP, self.tSuggestedListItems[self.ktSuggestedTypes.PvP])
	end
	
	if self.tSuggestedInfo.tQuestInfo then
		if not self.tSuggestedListItems[self.ktSuggestedTypes.Quest] then
			self.tSuggestedListItems[self.ktSuggestedTypes.Quest]  = Apollo.LoadForm(self.xmlDoc, "SuggestedListItem", wndContentContainer, self)
			bLoadedNewListItem = true
		end
		self:DrawSuggestedQuest(self.tSuggestedInfo.tQuestInfo, self.tSuggestedListItems[self.ktSuggestedTypes.Quest])
	end

	--No need to contiously arrange children when there were no new list items added.
	if bLoadedNewListItem then
		wndContentContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
	end
	
	local strText = ""
	local nCount = #wndContentContainer:GetChildren()
	if nCount <= 0 then
		strText = Apollo.GetString("Matching_NoContentFound")
	end
	self.wndMain:FindChild("RefreshContentBtn"):Show(nCount > 0)
	wndContentContainer:SetText(strText)
	self.wndSuggestedContentOverview:FindChild("FrameTitle"):SetText(Apollo.GetString("SuggestedContent_Title"))
end

--Responsible for Drawing both the overview section and the main section.
function SuggesteContent:Redraw()
	--Overview Section
	self:RedrawOverViewSection()

	--Big Section
	self:RedrawMainSection()
end

function SuggesteContent:DrawSuggestedMatch(matchSuggested, wndMatch)
	local wndInteractBtn = wndMatch:FindChild("InteractBtn")
	if wndInteractBtn then--ExitWindow form doesn't have btns.
		wndInteractBtn:SetText(Apollo.GetString("Nameplates_ComponentsLabel"))
		wndInteractBtn:SetData(matchSuggested)
	end
	wndMatch:FindChild("Title"):SetText(String_GetWeaselString('<P TextColor="UI_TextHoloTitle" Font="CRB_HeaderMedium">$1n</P>', matchSuggested:GetInfo().strName))
	wndMatch:FindChild("Title"):SetHeightToContentHeight()
	
	local wndDescription = wndMatch:FindChild("Description")
	wndDescription:SetText(String_GetWeaselString('<P TextColor="UI_TextHoloBody" Font="CRB_InterfaceSmall">$1n</P>', matchSuggested:GetInfo().strDescription))
	wndDescription:SetHeightToContentHeight()
	if wndMatch:FindChild("TextContainerTop") then
		wndMatch:FindChild("TextContainerTop"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	else
		local nHeight = wndMatch:FindChild("TextContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		local nLeft, nTop, nRight, nBottom = wndMatch:FindChild("TextContainer"):GetAnchorOffsets()
		local nPadding = 0
		if wndInteractBtn then
			nPadding = wndInteractBtn:GetHeight()
		end
		wndMatch:FindChild("TextContainer"):SetAnchorOffsets(nLeft, -nPadding - nHeight, nRight, -nPadding)
	end
	
	local eMatchType = matchSuggested:GetInfo().eMatchType
	wndMatch:FindChild("Image"):SetSprite(self.ktMatchImages[eMatchType])

	--Overview Section does NOT have content type.
	local wndContentType = wndMatch:FindChild("ContentType")
	local wndContentTypeTitle = wndMatch:FindChild("FrameTitle")
	local strContentType = ""
	if self.ktTypeNames[eMatchType] then
		strContentType = self.ktTypeNames[eMatchType]
	end
	
	if wndContentType then
		wndContentType:SetText(strContentType)
	elseif wndContentTypeTitle then
		wndContentTypeTitle:SetText(String_GetWeaselString(Apollo.GetString("WelcomeWindow_SuggestedContentTitle"), strContentType))
	end
end

function SuggesteContent:DrawSuggestedQuest(tQuestInfo, wndQuest)
	local wndTitle = wndQuest:FindChild("Title")
	local wndDescription = wndQuest:FindChild("Description")
	local wndInteractBtn = wndQuest:FindChild("InteractBtn")
	local wndImage = wndQuest:FindChild("Image")
	local strContentType = ""
	local strTitle = ""
	local strDescription = ""
	local strImage = ""
	local oData = nil

	if self.tSuggestedInfo.tQuestInfo.hubSuggested then
		strContentType = Apollo.GetString("MatchMaker_QuestHub")
		strTitle = String_GetWeaselString(Apollo.GetString("CRB_ColonLabelValue"), tQuestInfo.hubSuggested:GetWorldZoneName(),tQuestInfo.hubSuggested:GetName())
		strDescription = "" -- hubSuggested:GetDescription() should replace this when it exists
		oData = tQuestInfo.hubSuggested
		strImage = self.ktQuestTypes.Hub
	elseif self.tSuggestedInfo.tQuestInfo.epiSuggested then
		strContentType = Apollo.GetString("MatchMaker_Episode")
		strTitle = tQuestInfo.epiSuggested:GetTitle()
		strDescription = tQuestInfo.epiSuggested:GetSummary()
		oData = tQuestInfo.epiSuggested
		strImage = self.ktQuestTypes.Episode
	elseif self.tSuggestedInfo.tQuestInfo.queSuggested then
		strContentType = Apollo.GetString("Tooltips_Quest")
		strTitle = tQuestInfo.queSuggested:GetTitle()
		strDescription = tQuestInfo.queSuggested:GetSummary()
		oData = tQuestInfo.queSuggested
		strImage = self.ktQuestTypes.Quest
	end

	if wndInteractBtn then--ExitWindow form doesn't have btns.
		wndInteractBtn:SetText(Apollo.GetString("QuestLog_Track"))
		wndInteractBtn:SetData(oData)
	end

	wndTitle:SetText(string.format('<P TextColor="UI_TextHoloTitle" Font="CRB_HeaderMedium">%s</P>', strTitle))
	wndDescription:SetText(string.format('<P TextColor="UI_TextHoloBody" Font="CRB_InterfaceSmall">%s</P>', strDescription))
	wndTitle:SetHeightToContentHeight()
	wndImage:SetSprite(strImage)
	wndDescription:SetHeightToContentHeight()

	if wndQuest:FindChild("TextContainerTop") then -- ContentOverview page only
		wndQuest:FindChild("TextContainerTop"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	else
		local nHeight = wndQuest:FindChild("TextContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		local nLeft, nTop, nRight, nBottom = wndQuest:FindChild("TextContainer"):GetAnchorOffsets()
		local nPadding = 0
		if wndInteractBtn then
			nPadding = wndInteractBtn:GetHeight()
		end
		wndQuest:FindChild("TextContainer"):SetAnchorOffsets(nLeft, -nPadding - nHeight, nRight, -nPadding)
	end

	--Overview Section does NOT have content type.
	local wndContentType = wndQuest:FindChild("ContentType")
	local wndContentTypeTitle = wndQuest:FindChild("FrameTitle")
	if wndContentType then
		wndContentType:SetText(strContentType)
	elseif wndContentTypeTitle then
		wndContentTypeTitle:SetText(String_GetWeaselString(Apollo.GetString("WelcomeWindow_SuggestedContentTitle"), strContentType))
	end
	
end

function SuggesteContent:OnExitWindowRequestContent(wndParent)
	if not wndParent or not wndParent:IsValid() then
		return
	end

	if not self.tSuggestedInfo then
		self:InitializeContent()
	end

	self.wndSuggestedContentExitWindow = Apollo.LoadForm(self.xmlDoc, "SuggestedContentExitWindow", wndParent:FindChild("SuggestedContentContainer"), self)

	local nCount = 0
	local arRandContentContainer = {}
	for idx, oSuggestedContent in pairs(self.tSuggestedInfo) do
		table.insert(arRandContentContainer, oSuggestedContent)
		nCount = nCount + 1
	end

	if nCount > 0 then
		self.wndSuggestedContentExitWindow:FindChild("SuggestedContentDetails"):Show(true)
		self.wndSuggestedContentExitWindow:FindChild("NoContent"):Show(false)
		local oSuggestedContent = arRandContentContainer[math.random(1, nCount)]
		if MatchMakingEntry.is(oSuggestedContent) then
			self:DrawSuggestedMatch(oSuggestedContent, self.wndSuggestedContentExitWindow)
		else
			self:DrawSuggestedQuest(oSuggestedContent, self.wndSuggestedContentExitWindow)
		end
	else
		self.wndSuggestedContentExitWindow:FindChild("SuggestedContentDetails"):Show(false)
		self.wndSuggestedContentExitWindow:FindChild("NoContent"):Show(true)
	end
end

function SuggesteContent:OnMoreSuggestionsBtn(wndHandler, wndControl)
	Event_FireGenericEvent("WelcomeWindow_RequestTabChange", self.kstrTitle)
end

function SuggesteContent:OnSuggestedInteract(wndControl, wndHandler)
	if wndControl ~= wndHandler then
		return
	end
	
	local oData = wndHandler:GetData()
	if MatchMakingEntry.is(oData) then
		Event_FireGenericEvent("SuggestedContent_ShowMatch", oData)
	elseif QuestHub.is(oData) then
		local tLocation = oData:GetLocation()
		if tLocation then
			self:HelperSetNavPoint(tLocation, oData)
		end
	elseif Episode.is(oData) then
		local hubArea = oData:GetHub()
		if hubArea then
			local tLocation = hubArea:GetLocation()
			if tLocation then
				self:HelperSetNavPoint(tLocation, hubArea)
			end
		end
	end
end

function SuggesteContent:HelperSetNavPoint(tLocation, hubArea)
	GameLib.SetNavPoint(tLocation, hubArea:GetSubZoneId())
	GameLib.ShowNavPointHintArrow()

	local tNavPoint = GameLib.GetNavPoint()
	if tNavPoint then
		Event_FireGenericEvent("ContentFinder_OpenMapToNavPoint", tNavPoint.nMapZoneId)
	end
end

--Used for level up, and when player hits refresh btn.
function SuggesteContent:HelperLoadNewContent()
	if self.wndSuggestedContentOverview and self.wndSuggestedContentOverview:IsValid() and self.wndMain and self.wndMain:IsValid() then
		self:InitializeContent()
		local wndRefreshFlash = self.wndMain:FindChild("RefreshFlash")
		wndRefreshFlash:SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")
		self:Redraw()
	end
end

function SuggesteContent:OnClose()
	self.wndMain:Close() 
end


-----------------------------------------------------------------------------------------------
-- SuggesteContent Instance
-----------------------------------------------------------------------------------------------
local SuggesteContentInst = SuggesteContent:new()
SuggesteContentInst:Init()
