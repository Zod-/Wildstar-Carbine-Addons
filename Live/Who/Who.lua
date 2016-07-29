-----------------------------------------------------------------------------------------------
-- Client Lua Script for Who
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "ChatSystemLib"
require "Apollo"
require "DialogSys"
require "GameLib"
require "PlayerPathLib"
require "Tooltip"
require "XmlDoc"

local Who = {}
local knSaveVersion = 1
local knRefreshRate = 5

local karSearchResultsColumns =
{
	Name			= 1,
	Location		= 2,
	Level			= 3,
	Class			= 4,
	Path			= 5,
}

local karNearbyColumns = 
{
	Name			= 1,
	Level			= 2,
	Class			= 3,
	Path			= 4,
}

local ktClassToIconPanel =
{
	[GameLib.CodeEnumClass.Warrior] 		= "CRB_Raid:sprRaid_Icon_Class_Warrior",
	[GameLib.CodeEnumClass.Engineer] 		= "CRB_Raid:sprRaid_Icon_Class_Engineer",
	[GameLib.CodeEnumClass.Esper] 			= "CRB_Raid:sprRaid_Icon_Class_Esper",
	[GameLib.CodeEnumClass.Medic] 			= "CRB_Raid:sprRaid_Icon_Class_Medic",
	[GameLib.CodeEnumClass.Stalker] 		= "CRB_Raid:sprRaid_Icon_Class_Stalker",
	[GameLib.CodeEnumClass.Spellslinger]	= "CRB_Raid:sprRaid_Icon_Class_Spellslinger",
}

local c_arClassStrings =
{
	[GameLib.CodeEnumClass.Warrior] 		= "ClassWarrior",
	[GameLib.CodeEnumClass.Engineer] 		= "ClassEngineer",
	[GameLib.CodeEnumClass.Esper] 			= "ClassESPER",
	[GameLib.CodeEnumClass.Medic] 			= "ClassMedic",
	[GameLib.CodeEnumClass.Stalker] 		= "ClassStalker",
	[GameLib.CodeEnumClass.Spellslinger] 	= "CRB_Spellslinger",
}

local ktPathToIconPanel = {
	[PlayerPathLib.PlayerPathType_Soldier] 		= "CRB_MinimapSprites:sprMM_SmallIconSoldier",
	[PlayerPathLib.PlayerPathType_Settler] 		= "CRB_MinimapSprites:sprMM_SmallIconSettler",
	[PlayerPathLib.PlayerPathType_Scientist] 	= "CRB_MinimapSprites:sprMM_SmallIconScientist",
	[PlayerPathLib.PlayerPathType_Explorer] 	= "CRB_MinimapSprites:sprMM_SmallIconExplorer",
}

local c_arPathStrings = {
	[PlayerPathLib.PlayerPathType_Soldier] 		= "CRB_Soldier",
	[PlayerPathLib.PlayerPathType_Settler] 		= "CRB_Settler",
	[PlayerPathLib.PlayerPathType_Scientist] 	= "CRB_Scientist",
	[PlayerPathLib.PlayerPathType_Explorer] 	= "CRB_Explorer",
}

function Who:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	
	o.tWndRefs = { }

	return o
end

function Who:Init()
    Apollo.RegisterAddon(self)
end

function Who:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Who.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 	"OnInterfaceMenuListHasLoaded", self)
	
	Apollo.RegisterEventHandler("PlayerCreated", 				"Initialize", self)
	Apollo.RegisterEventHandler("CharacterCreated", 			"Initialize", self)
	Apollo.RegisterEventHandler("UnitCreated", 					"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 				"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitLevelChanged", 			"OnUnitLevelChanged", self)
	Apollo.RegisterEventHandler("WhoResponse", 					"OnWhoResponse", self)
	
	Apollo.RegisterEventHandler("FriendshipUpdate", 			"DelayUpdateNearbyPlayers", self)
	Apollo.RegisterEventHandler("FriendshipRemove", 			"DelayUpdateNearbyPlayers", self)
	
	Apollo.RegisterEventHandler("Group_Join", 					"DelayUpdateNearbyPlayers", self)
	Apollo.RegisterEventHandler("Group_Left", 					"DelayUpdateNearbyPlayers", self)
	Apollo.RegisterEventHandler("Group_FlagsChanged", 			"DelayUpdateNearbyPlayers", self)
	
	if self.tSearchResultsSort == nil or self.tSearchResultsSort.nColumn == nil then
		self.tSearchResultsSort = { nColumn = karSearchResultsColumns.Name, bAscending = true }
	end
	if self.tNearbySort == nil or self.tNearbySort.Column == nil then
		self.tNearbySort = { nColumn = karNearbyColumns.Name, bAscending = true }
	end
	self.tRemoveNearbyPlayers = {}
	self.tNearbyPlayers = {}
	self.nNearbyPlayersCount = 0
	self.tSearchResultsPlayers = {}
	
	self.bTimerRunning = false
	self.timer = ApolloTimer.Create(knRefreshRate, false, "OnTimer", self)
	self.timer:Stop()
	self.bTimerRemovePlayerRunning = false
	self.timerRemovePlayer = ApolloTimer.Create(knRefreshRate, false, "OnRemovePlayers", self)
	self.timerRemovePlayer:Stop()
end

function Who:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	local tSave =
	{
		nSaveVersion = knSaveVersion,
		tSearchResultsSort = self.tSearchResultsSort,
		tNearbySort = self.tNearbySort,
	}

	return tSave
end

function Who:OnRestore(eType, tSavedData)
	if eType == GameLib.CodeEnumAddonSaveLevel.Character and tSavedData and tSavedData.nSaveVersion == knSaveVersion then
		self.tSearchResultsSort = tSavedData.tSearchResultsSort
		if self.tSearchResultsSort == nil or self.tSearchResultsSort.nColumn == nil then
			self.tSearchResultsSort = { nColumn = karSearchResultsColumns.Name, bAscending = true }
		end
		self.tNearbySort = tSavedData.tNearbySort
		if self.tNearbySort == nil or self.tNearbySort.nColumn == nil then
			self.tNearbySort = { nColumn = karNearbyColumns.Name, bAscending = true }
		end
	end
end

function Who:OnDocumentReady()
    if self.xmlDoc == nil then
        return
    end
	
	Apollo.RegisterEventHandler("ChangeWorld", 				"DelayUpdateNearbyPlayers", self)
	Apollo.RegisterEventHandler("SubZoneChanged",			"DelayUpdateNearbyPlayers", self)
	Apollo.RegisterEventHandler("ToggleWhoWindow", 			"OnWhoButtonClicked", self)
	
	self:Initialize()
	
	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
	self:OnInterfaceMenuListHasLoaded()
end

function Who:OnInterfaceMenuListHasLoaded()
	local tData = {
		"ToggleWhoWindow", 
		"", 
		"Icon_Windows32_UI_CRB_InterfaceMenu_Social"
	}
	
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("Who_WindowTitle"), tData)
end

function Who:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", 
		{
			wnd = self.tWndRefs.wndMain, 
			strName = Apollo.GetString("Who_WindowTitle"), 
			nSaveVersion = 1
		}
	)
	Event_FireGenericEvent("WindowManagementAdd", 
		{
			wnd = self.tWndRefs.wndMain, 
			strName = Apollo.GetString("Who_WindowTitle"), 
			nSaveVersion = 1
		}
	)
end

function Who:Initialize()
	if self.tWndRefs.wndMain ~= nil or GameLib:GetPlayerUnit() == nil then
		return
	end
	
	self.tWndRefs.wndMain 					= Apollo.LoadForm(self.xmlDoc, "WhoForm", nil, self)
	self.tWndRefs.wndNearbyPlayers			= self.tWndRefs.wndMain:FindChild("btnNearbyPlayers")
	self.tWndRefs.wndSearchResults			= self.tWndRefs.wndMain:FindChild("btnSearchResults")
	self.tWndRefs.wndSearchResultsContent	= self.tWndRefs.wndMain:FindChild("SearchResultsContent")
	self.tWndRefs.wndNearbyContent			= self.tWndRefs.wndMain:FindChild("NearbyContent")
	
	self.tWndRefs.wndMain:SetSizingMinimum(500, 500)
	self.tWndRefs.wndMain:Show(false)
	self.tWndRefs.wndSearchResultsContent:SetSortColumn(self.tSearchResultsSort.nColumn, self.tSearchResultsSort.bAscending)
	self.tWndRefs.wndNearbyContent:SetSortColumn(self.tNearbySort.nColumn, self.tNearbySort.bAscending)
end

-----------------------------------------------------------------------------------------------
-- UI Events/Buttons
-----------------------------------------------------------------------------------------------

function Who:OnUnitCreated(unit)
	if unit:GetType() == "Player" then
		self.tNearbyPlayers[unit:GetId()] = unit
		
		self:DelayUpdateNearbyPlayers()
	end
end

function Who:OnUnitDestroyed(unit)
	if unit:GetType() == "Player" then
		self.tNearbyPlayers[unit:GetId()] = nil
		
		-- Begin the row clean up process
		self.tRemoveNearbyPlayers[unit:GetId()] = true
		if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsShown() and not self.bTimerRemovePlayerRunning then
			self.bTimerRemovePlayerRunning = true
			self.timerRemovePlayer:Start()
		end
	end
end

function Who:OnUnitLevelChanged(unit)
	if self.tNearbyPlayers[unit:GetId()] ~= nil then
		local nRow = self:HelperFindRowPosition(self.tWndRefs.wndNearbyContent, unit:GetId())
		if nRow ~= nil then
			self.tWndRefs.wndNearbyContent:SetCellText(nRow, karNearbyColumns.Level, unit:GetLevel())
		end
	end
end

function Who:OnWhoResponse(arResponse, eWhoResult, strResponse)	
	if eWhoResult == GameLib.CodeEnumWhoResult.OK or eWhoResult == GameLib.CodeEnumWhoResult.Partial then
		self.tSearchResultsPlayers = arResponse
	end
	
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndSearchResults:FindChild("SplashBtnAlert"):Show(#self.tSearchResultsPlayers > 0)
		self.tWndRefs.wndSearchResults:FindChild("SplashBtnItemCount"):SetText(tostring(#self.tSearchResultsPlayers))
		
		self:UpdateSearchResults()
		self:UpdateTabs(true)
		self.tWndRefs.wndMain:Invoke()
	end
end

function Who:OnWhoButtonClicked(wndHandler, wndControl)
	if not self.tWndRefs.wndMain:IsShown() then
		self:UpdateTabs(false)
		self.tWndRefs.wndMain:Invoke()
	else
		self.tWndRefs.wndMain:Close()
	end
end

function Who:OnCancel(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndMain:Close()
end

function Who:OnClose(wndHandler, wndControl)
	self.tSearchResultsSort.nColumn = self.tWndRefs.wndSearchResultsContent:GetSortColumn()
	self.tSearchResultsSort.bAscending = self.tWndRefs.wndSearchResultsContent:IsSortAscending()
	self.tNearbySort.nColumn = self.tWndRefs.wndNearbyContent:GetSortColumn()
	self.tNearbySort.bAscending = self.tWndRefs.wndNearbyContent:IsSortAscending()
end

function Who:OnShow(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	-- There may need to be some maintenance so do that now
	self:OnRemovePlayers()
	self:UpdateNearbyPlayersResults()
end

function Who:OnSearchResultsContent(wndHandler, wndControl)
	self:UpdateTabs(true)
end

function Who:OnNearbyPlayersContent(wndHandler, wndControl)
	self:UpdateTabs(false)
end

function Who:OnListItemClicked(wndHandler, wndControl, eMouseButton, nX, nY, bDoubleClick)
	local nRow = self.tWndRefs.wndNearbyContent:GetCurrentRow()
	if nRow == nil then
		return
	end
	
	local unit = self.tWndRefs.wndNearbyContent:GetCellLuaData(nRow, karNearbyColumns.Level)
	if unit == nil then
		return
	end
	
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", nil, unit:GetName(), unit)
	else
		GameLib.SetTargetUnit(unit)
		unit:ShowHintArrow()
		GameLib.SetInteractHintArrowObject(unit) 
	end
end

function Who:OnTimer()
	self.bTimerRunning = false
	
	self:UpdateNearbyPlayersResults()
end

function Who:OnRemovePlayers()
	self.bTimerRemovePlayerRunning = false
	
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end
	
	local bWasRowDeleted = false
	for nUnitId, bDirty in pairs(self.tRemoveNearbyPlayers) do
		self.tRemoveNearbyPlayers[nUnitId] = nil
		if self.tNearbyPlayers[nUnitId] == nil then
			self.tWndRefs.wndNearbyContent:DeleteRowsByData(nUnitId)
			bWasRowDeleted = true
		end
	end
	
	if bWasRowDeleted then
		self:UpdateNearbyPlayersButton(self.tWndRefs.wndNearbyContent:GetRowCount())
	end
end

function Who:DelayUpdateNearbyPlayers()
	if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsShown() and not self.bTimerRunning then
		self.bTimerRunning = true
		self.timer:Start()
	end
end

function Who:UpdateSearchResults()
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end
	
	--Display /who results
	local bNewRow = false
	local tValidRows = { }
	for _, tResult in ipairs(self.tSearchResultsPlayers) do
		local nRow = self:HelperFindRowPosition(self.tWndRefs.wndSearchResultsContent, tResult.strName)
		
		local strSubZone = tResult.strSubZone
		if strSubZone and strSubZone ~= "" then
			tResult.strLocation = string.format("%s: %s", tResult.strZone, strSubZone)
		else
			tResult.strLocation = tResult.strZone
		end
		if nRow == nil then
			bNewRow = true
			
			local strClassIconSprite = ""
			local strClass = ""
			local strPathIconSprite = ""
			local strPathType = ""
			
			if ktClassToIconPanel[tResult.eClassId] then
				strClassIconSprite = ktClassToIconPanel[tResult.eClassId]
			end
			if c_arClassStrings[tResult.eClassId] then
				strClass = Apollo.GetString(c_arClassStrings[tResult.eClassId])
			end
			if ktPathToIconPanel[tResult.ePlayerPathType] then
				strPathIconSprite = ktPathToIconPanel[tResult.ePlayerPathType]
			end
			if c_arPathStrings[tResult.ePlayerPathType] then
				strPathType = Apollo.GetString(c_arPathStrings[tResult.ePlayerPathType])
			end
			
			nRow = self.tWndRefs.wndSearchResultsContent:AddRow(tResult.strName, "", tResult.strName)
			self.tWndRefs.wndSearchResultsContent:SetCellImage(nRow, karSearchResultsColumns.Class, strClassIconSprite)
			self.tWndRefs.wndSearchResultsContent:SetCellSortText(nRow, karSearchResultsColumns.Class, strClassIconSprite)
			self.tWndRefs.wndSearchResultsContent:SetCellImage(nRow, karSearchResultsColumns.Path, strPathIconSprite)
			self.tWndRefs.wndSearchResultsContent:SetCellSortText(nRow, karSearchResultsColumns.Path, strPathIconSprite)
		end
		self.tWndRefs.wndSearchResultsContent:SetCellText(nRow, karSearchResultsColumns.Location, tResult.strLocation)
		self.tWndRefs.wndSearchResultsContent:SetCellText(nRow, karSearchResultsColumns.Level, tResult.nLevel)
		tValidRows[nRow] = true
	end
	
	-- Remove extra rows in case players in results change
	local nRemovedRowCount = 0
	for nRow = 1, self.tWndRefs.wndSearchResultsContent:GetRowCount() do
		if not tValidRows[nRow] then
			local nTargetRow = nRow - nRemovedRowCount
			self.tWndRefs.wndSearchResultsContent:DeleteRow(nTargetRow)
			nRemovedRowCount = nRemovedRowCount + 1
		end
	end
	
	if bNewRow then
		self.tWndRefs.wndSearchResultsContent:SetSortColumn(self.tWndRefs.wndSearchResultsContent:GetSortColumn(), self.tWndRefs.wndSearchResultsContent:IsSortAscending())
	end
end

function Who:UpdateNearbyPlayersResults()
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end
	
	self.nNearbyPlayersCount = 0
	for unitId, unit in pairs(self.tNearbyPlayers) do
		if unit == nil or not unit:IsValid() or unit:IsInYourGroup() or unit:IsThePlayer() then
			self.tNearbyPlayers[unitId] = nil
		else
			self.nNearbyPlayersCount = self.nNearbyPlayersCount + 1
		end
	end
	self:UpdateNearbyPlayersButton(self.nNearbyPlayersCount)
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil then
		return
	end

	--Display nearby players
	local bNewRow = false
	for nUnitId, unit in pairs(self.tNearbyPlayers) do
		local nRow = self:HelperFindRowPosition(self.tWndRefs.wndNearbyContent, nUnitId)
		
		if nRow == nil then
			bNewRow = true
			
			local tUnitInfo = { strName = unit:GetName(), eClassId = unit:GetClassId(), ePlayerPathType = unit:GetPlayerPathType() }
			local strColor = nil
			local strClassIconSprite = ""
			local strClass = ""
			local nPathId = 0
			local strPathIconSprite = ""
			local strPathType = ""
			
			if unit:GetDispositionTo(unitPlayer) == Unit.CodeEnumDisposition.Hostile then
				strColor = ApolloColor.new("DispositionHostile")
			else
				strColor = ApolloColor.new("UI_BtnTextHoloNormal")
			end
			if ktClassToIconPanel[tUnitInfo.eClassId] then
				strClassIconSprite = ktClassToIconPanel[tUnitInfo.eClassId]
			end
			if c_arClassStrings[tUnitInfo.eClassId] then
				strClass = Apollo.GetString(c_arClassStrings[tUnitInfo.eClassId])
			end
			if unit and unit:IsValid() and tUnitInfo.ePlayerPathType > 0 then
				nPathId = tUnitInfo.ePlayerPathType
			end
			if ktPathToIconPanel[nPathId] then
				strPathIconSprite = ktPathToIconPanel[nPathId]
			end
			if c_arPathStrings[nPathId] then
				strPathType = Apollo.GetString(c_arPathStrings[nPathId])
			end
			
			nRow = self.tWndRefs.wndNearbyContent:AddRow(tUnitInfo.strName, "", nUnitId)
			self.tWndRefs.wndNearbyContent:SetCellText(nRow, karNearbyColumns.Level, unit:GetLevel())
			self.tWndRefs.wndNearbyContent:SetCellLuaData(nRow, karNearbyColumns.Level, unit)
			self.tWndRefs.wndNearbyContent:SetCellImage(nRow, karNearbyColumns.Class, strClassIconSprite)
			self.tWndRefs.wndNearbyContent:SetCellSortText(nRow, karNearbyColumns.Class, strClassIconSprite)
			self.tWndRefs.wndNearbyContent:SetCellImage(nRow, karNearbyColumns.Path, strPathIconSprite)
			self.tWndRefs.wndNearbyContent:SetCellSortText(nRow, karNearbyColumns.Path, strPathIconSprite)
		end
	end
	
	if bNewRow then
		self.tWndRefs.wndNearbyContent:SetSortColumn(self.tWndRefs.wndNearbyContent:GetSortColumn(), self.tWndRefs.wndNearbyContent:IsSortAscending())
	end
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function Who:UpdateTabs(bShowSearchResults)
	self.tWndRefs.wndSearchResultsContent:Show(bShowSearchResults)
	self.tWndRefs.wndNearbyContent:Show(not bShowSearchResults)
	
	self.tWndRefs.wndSearchResults:SetCheck(bShowSearchResults)
	self.tWndRefs.wndNearbyPlayers:SetCheck(not bShowSearchResults)
end

function Who:HelperFindRowPosition(wndGrid, tData)
	for i = 1, wndGrid:GetRowCount() do
		if wndGrid:GetCellLuaData(i, 1) == tData then
			return i
		end
	end
	return nil
end

function Who:UpdateNearbyPlayersButton(nCount)
	self.tWndRefs.wndNearbyPlayers:FindChild("SplashBtnAlert"):Show(nCount > 0)
	self.tWndRefs.wndNearbyPlayers:FindChild("SplashBtnItemCount"):SetText(tostring(nCount))
end

local WhoInst = Who:new()
WhoInst:Init()