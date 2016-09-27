-----------------------------------------------------------------------------------------------
-- Client Lua Script for TutorialMenu
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
 
-----------------------------------------------------------------------------------------------
-- TutorialMenu Module Definition
-----------------------------------------------------------------------------------------------
local TutorialMenu = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local ktCategories =  -- key is the enum for the category, v is the number used for the "view" flag, the flag, and the prepend/title
{
-- DANGEROUS: the second entry MUST match te string in CPP for this to work
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

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function TutorialMenu:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    o.tWndRefs = {}
	self.tCategoryBtns = {} -- this will be the ordered category toggles
	self.tTutorialBtns = {} -- this will be the ordered category toggles
    self.tFilteredList = nil

    return o
end

function TutorialMenu:Init()
    Apollo.RegisterAddon(self, true, Apollo.GetString("CRB_Tutorials"))
end

-----------------------------------------------------------------------------------------------
-- TutorialMenu OnLoad
-----------------------------------------------------------------------------------------------
function TutorialMenu:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("TutorialMenu.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function TutorialMenu:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady",	self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("GenericEvent_OpenTutorialMenu",	"OnTutorialMenuOn",			self)
	
    Apollo.RegisterEventHandler("HideAllTutorials", "OnHideAllTutorials", self)
	Apollo.RegisterSlashCommand("Tutorials", "OnTutorialMenuOn", self)
    Apollo.RegisterSlashCommand("tutorials", "OnTutorialMenuOn", self)
end

function TutorialMenu:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("CRB_Tutorials")})
end

-----------------------------------------------------------------------------------------------
-- TutorialMenu Functions
-----------------------------------------------------------------------------------------------
function TutorialMenu:OnConfigure()
	self:OnTutorialMenuOn()
end

function TutorialMenu:OnTutorialMenuOn()
	self.tFullList = GameLib.GetAllTutorials() 

	local wndMain = Apollo.LoadForm(self.xmlDoc, "TutorialMenuForm", nil, self)
	self.tWndRefs.wndMain = wndMain
	self.tWndRefs.wndControls = wndMain:FindChild("ControlContainer")
	self.tWndRefs.wndEnableAllBtn = wndMain:FindChild("EnableAllBtn")
	self.tWndRefs.wndResetBlocker = wndMain:FindChild("ResetAllConfirmBlocker")
	self.tWndRefs.wndSearch = wndMain:FindChild("SearchTopLeftContainer")
	
	self.tWndRefs.wndSearch:FindChild("SearchTopLeftInputBox"):SetMaxTextLength(30)

	self:BuildFullList()
	
	self:UpdateVisibilityFlags()
	self.tWndRefs.wndResetBlocker:Show(false)
	self.tWndRefs.wndMain:FindChild("ShowTutorialsBtn"):SetCheck(g_InterfaceOptions.Carbine.bShowTutorials)
	self.tWndRefs.wndMain:Invoke()
	
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndMain, strName = Apollo.GetString("CRB_Tutorials")})
end

function TutorialMenu:BuildFullList()
	local tCategories = {} -- temp table until sorted
	for idx, entry in pairs(ktCategories) do
		local tEntry = {}
		tEntry.title = entry
		tEntry.nCatEnum = idx
		
		table.insert(tCategories, tEntry)
	end

	self:BuildCategoryWindows(self:HelperSortByName(tCategories))  
end

function TutorialMenu:BuildCategoryWindows(tCategories)
	self.tWndRefs.wndMain:FindChild("LeftSideScroll"):DestroyChildren()
	self.tWndRefs.wndMain:FindChild("LeftSideScroll"):RecalculateContentExtents()
	self.tCategoryBtns = {} -- resetting

	if tCategories ~= nil and #tCategories > 0 then
		self.tWndRefs.wndMain:FindChild("LeftSideScrollPrompt"):Show(false)
		local nDefault = 1 -- what button to check; default to 1 unless "general" is in the list
		for idx, entry in pairs(tCategories) do
			local wnd = Apollo.LoadForm(self.xmlDoc, "MiddleLevel", self.tWndRefs.wndMain:FindChild("LeftSideScroll"), self)
			wnd:FindChild("MiddleLevelBtnText"):SetText(entry.title)
			wnd:FindChild("MiddleLevelBtnText"):SetTextColor(ApolloColor.new("UI_TextMetalGoldHighlight"))
			wnd:FindChild("MiddleLevelBtn"):SetData(entry.nCatEnum)
			wnd:FindChild("MiddleLevelViewBtn"):SetData(entry.nCatEnum)
			entry.wnd = wnd
			table.insert(self.tCategoryBtns, entry)
			
			if entry.nCatEnum == GameLib.CodeEnumTutorialCategory.General then
				nDefault = idx
			end	
		end
	
		self.tWndRefs.wndMain:FindChild("LeftSideScroll"):ArrangeChildrenVert()
		self:UpdateVisibilityFlags()
		
		-- grab general or our our first one
		self.tCategoryBtns[nDefault].wnd:FindChild("MiddleLevelBtn"):SetCheck(true)
		self.tCategoryBtns[nDefault].wnd:FindChild("MiddleLevelBtnText"):SetTextColor(ApolloColor.new("white"))
		
		local tTutorialList = {}
		if self.tFilteredList ~= nil then -- we're searching
			-- loop, find all tutorials with the correct enum, add to list
			for idxTutorial, tutorial in pairs(self.tFilteredList) do
				if tutorial.tutorialCategoryEnum == self.tCategoryBtns[nDefault].nCatEnum then
					table.insert(tTutorialList, tutorial) 
				end
			end
		else
			tTutorialList = GameLib.GetTutorialsForCategory(self.tCategoryBtns[nDefault].nCatEnum)
		end

		self:BuildTutorialWindows(self:HelperSortByName(tTutorialList))
	else
		self.tWndRefs.wndMain:FindChild("LeftSideScrollPrompt"):Show(true)
		self.tWndRefs.wndMain:FindChild("RightSideScroll"):DestroyChildren()
		self.tWndRefs.wndMain:FindChild("RightSideScroll"):RecalculateContentExtents()
	end
end

function TutorialMenu:UpdateVisibilityFlags()
	local tFlags = GameLib.GetTutorialVisibilityFlags()
	local nEnabledCount = 0	
	local nTotalCount = 0
	for idx, entry in pairs(self.tCategoryBtns) do
		local bViewed = false
		if tFlags[entry.nCatEnum+1] then
			bViewed = true
			nEnabledCount = nEnabledCount+1
		end
		entry.wnd:FindChild("MiddleLevelViewBtn"):SetCheck(bViewed)
		nTotalCount = nTotalCount+1
	end
	self.tWndRefs.wndEnableAllBtn:Enable(nTotalCount ~= 0) 
	self.tWndRefs.wndEnableAllBtn:SetCheck(nEnabledCount == nTotalCount)
end

function TutorialMenu:BuildTutorialWindows(tTutorials)
	self.tWndRefs.wndMain:FindChild("RightSideScroll"):DestroyChildren()
	self.tWndRefs.wndMain:FindChild("RightSideScroll"):RecalculateContentExtents()
	self.tWndRefs.wndMain:FindChild("RightSideScrollPrompt"):Show(true)
	self.tTutorialBtns = {}
	
	if tTutorials ~= nil and #tTutorials > 0 then -- no tutorials
		self.tWndRefs.wndMain:FindChild("RightSideScrollPrompt"):Show(false)
		for idx, entry in pairs(tTutorials) do
			if entry.title ~= nil and entry.title ~= "" then -- no title means just a prompt
				local wnd = Apollo.LoadForm(self.xmlDoc, "TutorialItem", self.tWndRefs.wndMain:FindChild("RightSideScroll"), self)
				local wndText = wnd:FindChild("TutorialLabelNormal")
				if entry.viewed == true then
					wndText = wnd:FindChild("TutorialLabelRead")
				end

				wndText:SetText(entry.title)
				wnd:FindChild("TutorialItemBtn"):SetData(entry.id)
				wnd:FindChild("ReadTutorialCheck"):Show(entry.viewed == true)
				wnd:FindChild("ReadTutorialNew"):Show(entry.viewed ~= true)

				entry.wnd = wnd
				table.insert(self.tTutorialBtns, entry)
			end
		end
		
		self.tWndRefs.wndMain:FindChild("RightSideScroll"):ArrangeChildrenVert()
	end
	
	self:EnableControls()
end

function TutorialMenu:EnableControls(tEntry)
	if tEntry == nil then
		self.tWndRefs.wndControls:FindChild("ViewBtn"):Enable(false)
		self.tWndRefs.wndControls:FindChild("ResetBtn"):Enable(false)
		self.tWndRefs.wndControls:FindChild("ViewBtn"):SetData(nil)
		self.tWndRefs.wndControls:FindChild("ResetBtn"):SetData(nil)	
		self.tWndRefs.wndControls:FindChild("ResetBtn"):SetText(Apollo.GetString("Tutorials_MarkAsRead"))
	else
		self.tWndRefs.wndControls:FindChild("ViewBtn"):Enable(true)
		self.tWndRefs.wndControls:FindChild("ResetBtn"):Enable(true)
		self.tWndRefs.wndControls:FindChild("ViewBtn"):SetData(tEntry)
		self.tWndRefs.wndControls:FindChild("ResetBtn"):SetData(tEntry)	

		if tEntry.viewed == true then
			self.tWndRefs.wndControls:FindChild("ResetBtn"):SetText(Apollo.GetString("Tutorials_Reset"))	
		else
			self.tWndRefs.wndControls:FindChild("ResetBtn"):SetText(Apollo.GetString("Tutorials_MarkAsRead"))	
		end
	end
end

-----------------------------------------------------------------------------------------------
-- TutorialMenuForm Functions
-----------------------------------------------------------------------------------------------
function TutorialMenu:OnClose()
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
		local wndMain = self.tWndRefs.wndMain
		self.tWndRefs = {}
		self.tCategoryBtns = {}
		self.tTutorialBtns = {}
	    self.tFilteredList = nil
		
		wndMain:Close()
		wndMain:Destroy()
		Event_FireGenericEvent("WindowManagementRemove", {strName = Apollo.GetString("CRB_Tutorials")})
	end	
end

function TutorialMenu:OnCloseBtn()
	self.tWndRefs.wndMain:Close()
end

function TutorialMenu:OnCategoryBtn(wndHandler, wndControl)
	self.tWndRefs.wndSearch:FindChild("SearchTopLeftInputBox"):ClearFocus()
	if wndHandler ~= wndControl then return false end
	local nCategory = wndControl:GetData()
	
	if nCategory ~= nil then
		for idx, entry in pairs(self.tCategoryBtns) do
			if nCategory == entry.wnd:FindChild("MiddleLevelBtn"):GetData() then -- active btn
				entry.wnd:FindChild("MiddleLevelBtn"):SetCheck(true)
				entry.wnd:FindChild("MiddleLevelBtnText"):SetTextColor(ApolloColor.new("white"))
			else
				entry.wnd:FindChild("MiddleLevelBtn"):SetCheck(false)
				entry.wnd:FindChild("MiddleLevelBtnText"):SetTextColor(ApolloColor.new("UI_TextMetalGoldHighlight"))
			end
		end	
		
		local tTutorialList = {}
		if self.tFilteredList ~= nil then -- we're searching
			-- loop, find all tutorials with the correct enum, add to list
			for idxTutorial, tutorial in pairs(self.tFilteredList) do
				if tutorial.tutorialCategoryEnum == nCategory then
					table.insert(tTutorialList, tutorial) 
				end
			end
		else
			tTutorialList = GameLib.GetTutorialsForCategory(nCategory)
		end
		self:BuildTutorialWindows(self:HelperSortByName(tTutorialList))
	end
end

function TutorialMenu:OnTutorialItemBtn(wndHandler, wndControl)
	self.tWndRefs.wndSearch:FindChild("SearchTopLeftInputBox"):ClearFocus()
	if wndHandler ~= wndControl then return false end
	local nTutorialId = wndControl:GetData()
	local tChosen = nil
	wndHandler:GetParent()

	if nTutorialId ~= nil then
		for idx, entry in pairs(self.tTutorialBtns) do
			local wndBtn = entry.wnd:FindChild("TutorialItemBtn")
			wndBtn:SetCheck(wndBtn:GetData() == nTutorialId)
			
			if wndBtn:GetData() == nTutorialId then
				tChosen = entry
			end
		end	
	end
	
	self:EnableControls(tChosen)
end

function TutorialMenu:OnTutorialItemBtnUncheck(wndHandler, wndControl)
	self.tWndRefs.wndSearch:FindChild("SearchTopLeftInputBox"):ClearFocus()
	self:EnableControls()
end

function TutorialMenu:OnResetBtn(wndHandler, wndControl)
	local tEntry = wndControl:GetData()
	if tEntry == nil then return end
	
	if tEntry.viewed ~= true then -- marking as read
		tEntry.viewed = true -- artificial value for the sake of the UI. 
		GameLib.MarkTutorialViewed(tEntry.id, true) -- update it for real
		tEntry.wnd:FindChild("TutorialLabelRead"):SetText(tEntry.title)
		tEntry.wnd:FindChild("TutorialLabelNormal"):SetText("")
		tEntry.wnd:FindChild("ReadTutorialCheck"):Show(true)
		tEntry.wnd:FindChild("ReadTutorialNew"):Show(false)
	else -- resetting
		tEntry.viewed = false -- artificial value for the sake of the UI. 
		GameLib.MarkTutorialViewed(tEntry.id, false) -- update it for real
		tEntry.wnd:FindChild("TutorialLabelRead"):SetText("")
		tEntry.wnd:FindChild("TutorialLabelNormal"):SetText(tEntry.title)
		tEntry.wnd:FindChild("ReadTutorialCheck"):Show(false)	
		tEntry.wnd:FindChild("ReadTutorialNew"):Show(true)
	end
	
	self:EnableControls(tEntry)				
end

function TutorialMenu:OnViewBtn(wndHandler, wndControl)
	self.tWndRefs.wndSearch:FindChild("SearchTopLeftInputBox"):ClearFocus()
	local tEntry = wndControl:GetData()
	if tEntry == nil then return end
	tEntry.wnd:FindChild("ReadTutorialNew"):Show(false)
	tEntry.wnd:FindChild("ReadTutorialCheck"):Show(true)
	Event_FireGenericEvent("ForceTutorial", tEntry.id, true)
end

function TutorialMenu:OnMiddleLevelViewBtn(wndHandler, wndControl)
	self.tWndRefs.wndSearch:FindChild("SearchTopLeftInputBox"):ClearFocus()
	if wndHandler ~= wndControl then return false end
	local nFlagId = wndControl:GetData()
	
	if nFlagId ~= nil then
		GameLib.ToggleTutorialVisibilityFlags(nFlagId)
	end
	
	self:UpdateVisibilityFlags()
end

function TutorialMenu:OnEnableAllBtn(wndHandler, wndControl)
	local bSetting = wndControl:IsChecked()

	for idx, entry in pairs(self.tCategoryBtns) do
		local bCurrent = entry.wnd:FindChild("MiddleLevelViewBtn"):IsChecked()
		if bSetting ~= bCurrent then
			GameLib.ToggleTutorialVisibilityFlags(entry.wnd:FindChild("MiddleLevelViewBtn"):GetData())
			entry.wnd:FindChild("MiddleLevelViewBtn"):SetCheck(bSetting)
		end
	end
	--self:UpdateVisibilityFlags()
end

function TutorialMenu:OnToggleTutorials(wndHandler, wndControl)
	g_InterfaceOptions.Carbine.bShowTutorials = wndHandler:IsChecked()
	Event_FireGenericEvent("OptionsUpdated_ShowTutorials")
	Event_FireGenericEvent("GenericEvent_SystemChannelMessage", String_GetWeaselString(Apollo.GetString("InterfaceOptions_TutorialsToggle"), wndHandler:IsChecked() and Apollo.GetString("Command_Chat_True") or Apollo.GetString("Command_Chat_False")))
end

function TutorialMenu:OnHideAllTutorials()
	local bSetting = false
	for idx, entry in pairs(self.tCategoryBtns) do
		local bCurrent = entry.wnd:FindChild("MiddleLevelViewBtn"):IsChecked()
		if bSetting ~= bCurrent then
			GameLib.ToggleTutorialVisibilityFlags(entry.wnd:FindChild("MiddleLevelViewBtn"):GetData())
			entry.wnd:FindChild("MiddleLevelViewBtn"):SetCheck(bSetting)
		end
	end
	self.tWndRefs.wndMain:FindChild("EnableAllBtn"):SetCheck(false)
	--self:UpdateVisibilityFlags()
end

function TutorialMenu:OnResetAllBtn(wndHandler, wndControl)
	self.tWndRefs.wndSearch:FindChild("SearchTopLeftInputBox"):ClearFocus()
	self.tWndRefs.wndResetBlocker:Show(true)
end

function TutorialMenu:OnConfirmResetBtn(wndHandler, wndControl)
	-- do a full redraw, then show
	GameLib.ResetTutorials()
	self:BuildFullList()
	self.tWndRefs.wndResetBlocker:Show(false)
end

function TutorialMenu:OnCancelResetBtn(wndHandler, wndControl)
	self.tWndRefs.wndResetBlocker:Show(false)
end

function TutorialMenu:OnSearchTopLeftInputBoxChanged(wndHandler, wndControl)
	local strInput = Apollo.StringToLower(wndHandler:GetText())
	local bInputExists = Apollo.StringLength(strInput) > 0

	self.tWndRefs.wndSearch:FindChild("SearchTopLeftClearBtn"):Show(bInputExists)
	
	if not bInputExists then
		-- TODO: get current selection, reset the UI to that if it exists (probably store it on the right scroll container)
		self.tFilteredList = nil
		self:BuildFullList()
		return
	end	
	
	local tCategories = {}
	self.tFilteredList = {}
	for idx, entry in pairs(self.tFullList) do
		local strTitle = Apollo.StringToLower(entry.title)
		if string.find(strTitle, strInput) ~= nil then
			table.insert(self.tFilteredList, entry)

			-- build our category list
			local bHaveCategory = false -- see if we have it
			for idxCategory, entryCategory in pairs(tCategories) do
				if entryCategory.nCatEnum == entry.tutorialCategoryEnum then
					bHaveCategory = true
				end
			end
			
			if bHaveCategory == false and ktCategories[entry.tutorialCategoryEnum] ~=  nil then--there exists tutorials, that have a category id that isn't an official current category, dont insert them in results
				local tCat = {}
				tCat.title = ktCategories[entry.tutorialCategoryEnum]
				tCat.nCatEnum = entry.tutorialCategoryEnum
				table.insert(tCategories, tCat)
			end
		end
	end

	self:BuildCategoryWindows(self:HelperSortByName(tCategories))
end

function TutorialMenu:OnSearchClearBtn(wndHandler, wndControl)
	self.tWndRefs.wndSearch:FindChild("SearchTopLeftInputBox"):SetText("")
	self.tWndRefs.wndSearch:FindChild("SearchTopLeftInputBox"):ClearFocus()
	self.tFilteredList = nil
	self:OnSearchTopLeftInputBoxChanged(self.tWndRefs.wndSearch:FindChild("SearchTopLeftInputBox"), self.tWndRefs.wndSearch:FindChild("SearchTopLeftInputBox"))
end

---------------------------------------------------------------------------------------------------
-- Helper Functions
---------------------------------------------------------------------------------------------------
function TutorialMenu:HelperSortByName(tEntries)
	if not tEntries then return end
	local tResult = tEntries

	table.sort(tResult, function(a,b) return (a.title < b.title) end) -- "title" can come from CPP and can't be changed
		
	return tResult -- result is the sorted list; take this and draw the entry
end

-----------------------------------------------------------------------------------------------
-- TutorialMenu Instance
-----------------------------------------------------------------------------------------------
local TutorialMenuInst = TutorialMenu:new()
TutorialMenuInst:Init()
