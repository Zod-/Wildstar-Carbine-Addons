-----------------------------------------------------------------------------------------------
-- Client Lua Script for Runecrafting
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "CraftingLib"
require "GameLib"
require "Item"

local karElementsToRuneSprite =
{
	[Item.CodeEnumRuneType.Air]		= { strBright = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Air_Used",		strFade = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Air_Empty" },
	[Item.CodeEnumRuneType.Fire]	= { strBright = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Fire_Used",		strFade = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Fire_Empty" },
	[Item.CodeEnumRuneType.Water]	= { strBright = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Water_Used",	strFade = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Water_Empty" },
	[Item.CodeEnumRuneType.Earth]	= { strBright = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Earth_Used",	strFade = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Earth_Empty" },
	[Item.CodeEnumRuneType.Logic]	= { strBright = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Logic_Used",	strFade = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Logic_Empty" },
	[Item.CodeEnumRuneType.Life]	= { strBright = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Life_Used",		strFade = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Life_Empty" },
	[Item.CodeEnumRuneType.Fusion]	= { strBright = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Fusion_Used",	strFade = "IconSprites:Icon_RuneSocket_Icon_Windows_UI_RuneSocket_Fusion_Empty" },
}

local karElementsToCategorySprite =
{
	[Item.CodeEnumRuneType.Air]		= { strBright = "Runecrafting:sprRunecrafting_Air",			strFade = "Runecrafting:sprRunecrafting_AirFade" },
	[Item.CodeEnumRuneType.Fire]	= { strBright = "Runecrafting:sprRunecrafting_Fire",		strFade = "Runecrafting:sprRunecrafting_FireFade" },
	[Item.CodeEnumRuneType.Water]	= { strBright = "Runecrafting:sprRunecrafting_Water",		strFade = "Runecrafting:sprRunecrafting_WaterFade" },
	[Item.CodeEnumRuneType.Earth]	= { strBright = "Runecrafting:sprRunecrafting_Earth",		strFade = "Runecrafting:sprRunecrafting_EarthFade" },
	[Item.CodeEnumRuneType.Logic]	= { strBright = "Runecrafting:sprRunecrafting_Logic",		strFade = "Runecrafting:sprRunecrafting_LogicFade" },
	[Item.CodeEnumRuneType.Life]	= { strBright = "Runecrafting:sprRunecrafting_Life",		strFade = "Runecrafting:sprRunecrafting_LifeFade" },
	[Item.CodeEnumRuneType.Fusion]	= { strBright = "Runecrafting:sprRunecrafting_Fusion",		strFade = "Runecrafting:sprRunecrafting_FusionFade" },
}

local karElementsToName =
{
	[Item.CodeEnumRuneType.Air]		= Apollo.GetString("CRB_Air"),
	[Item.CodeEnumRuneType.Fire]	= Apollo.GetString("CRB_Fire"),
	[Item.CodeEnumRuneType.Water]	= Apollo.GetString("CRB_Water"),
	[Item.CodeEnumRuneType.Earth]	= Apollo.GetString("CRB_Earth"),
	[Item.CodeEnumRuneType.Logic]	= Apollo.GetString("CRB_Logic"),
	[Item.CodeEnumRuneType.Life]	= Apollo.GetString("CRB_Life"),
	[Item.CodeEnumRuneType.Fusion]	= Apollo.GetString("CRB_Fusion"),
}

local karElementsToSounds =
{
	[Item.CodeEnumRuneType.Air]		= {eNonSet = Sound.PlayUIEquipAirRune,		eSet = Sound.PlayUIEquipAirSetRune},
	[Item.CodeEnumRuneType.Fire]	= {eNonSet = Sound.PlayUIEquipFireRune,		eSet = Sound.PlayUIEquipFireSetRune},
	[Item.CodeEnumRuneType.Water]	= {eNonSet = Sound.PlayUIEquipWaterRune,	eSet = Sound.PlayUIEquipWaterSetRune},
	[Item.CodeEnumRuneType.Earth]	= {eNonSet = Sound.PlayUIEquipEarthRune,	eSet = Sound.PlayUIEquipEarthSetRune},
	[Item.CodeEnumRuneType.Logic]	= {eNonSet = Sound.PlayUIEquipLogicRune,	eSet = Sound.PlayUIEquipLogicSetRune},
	[Item.CodeEnumRuneType.Life]	= {eNonSet = Sound.PlayUIEquipLifeRune,		eSet = Sound.PlayUIEquipLifeSetRune},
	[Item.CodeEnumRuneType.Fusion]	= {eNonSet = Sound.PlayUIEquipFusionRune},
}

local karQualityColors =
{
	[Item.CodeEnumItemQuality.Inferior] 		= "ItemQuality_Inferior",
	[Item.CodeEnumItemQuality.Average] 			= "ItemQuality_Average",
	[Item.CodeEnumItemQuality.Good] 			= "ItemQuality_Good",
	[Item.CodeEnumItemQuality.Excellent] 		= "ItemQuality_Excellent",
	[Item.CodeEnumItemQuality.Superb] 			= "ItemQuality_Superb",
	[Item.CodeEnumItemQuality.Legendary] 		= "ItemQuality_Legendary",
	[Item.CodeEnumItemQuality.Artifact]		 	= "ItemQuality_Artifact",
}

local ktSlotNames =
{
	[GameLib.CodeEnumItemSlots.Weapon] 	= Apollo.GetString("CRB_Weapon"),
	[GameLib.CodeEnumItemSlots.Head] 	= Apollo.GetString("CRB_Head"),
	[GameLib.CodeEnumItemSlots.Chest] 	= Apollo.GetString("CRB_Chest"),
	[GameLib.CodeEnumItemSlots.Legs] 	= Apollo.GetString("CRB_Legs"),
	[GameLib.CodeEnumItemSlots.Feet] 	= Apollo.GetString("CRB_Feet"),
	[GameLib.CodeEnumItemSlots.Hands] 	= Apollo.GetString("CRB_Hands"),
}

local crRed = ApolloColor.new("Reddish")

local keFilterType =
{
	Level = 1,
	Slot = 2,
}

local knAllRunesId = 0


local knFilterDividerData = 51

local Runecrafting = {}

function Runecrafting:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Runecrafting:Init()
    Apollo.RegisterAddon(self)
end

function Runecrafting:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Runecrafting.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Runecrafting:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 					"OnInterfaceMenuListHasLoaded", self)
	self:OnInterfaceMenuListHasLoaded()

	Apollo.RegisterEventHandler("GenericEvent_CraftingResume_CloseEngraving", 	"OnGenericEvent_CraftingResume_CloseEngraving", self)
	Apollo.RegisterEventHandler("TradeskillEngravingStationClose", 				"OnTradeskillEngravingStationClose", self)

	Apollo.RegisterEventHandler("GenericEvent_RightClick_OpenEngraving", 		"InitEditWindow", self)
	Apollo.RegisterEventHandler("GenericEvent_InterfaceMenu_ToggleEngraving", 	"OnToggleEngraving", self)
	Apollo.RegisterEventHandler("ItemModified",									"OnItemModified", self)
	Apollo.RegisterEventHandler("DragDropSysBegin",								"OnDragDropSystemBegin", self)
	Apollo.RegisterEventHandler("DragDropSysEnd", 								"OnDragDropSystemEnd", self)
	
	Apollo.RegisterEventHandler("GenericEvent_CraftingResume_OpenEngraving", 	"InitCraftingWindow", self)
	Apollo.RegisterEventHandler("GenericEvent_CraftingSummary_Closed", 			"OnCloseSummary", self)
	Apollo.RegisterEventHandler("UpdateInventory", 								"HelperRefreshBottomMaterials", self)

	--ServiceTokenPrompt
	Apollo.RegisterEventHandler("ServiceTokenClosed_RuneCrafting", "OnServiceTokenClosed_RuneCrafting", self)

	self.tFilters = {}
	self.nDefaultLevel = 1
	self.wndCurrentConfirmPopup = nil
	self.wndSelectedElement = nil
	self.wndSelection = nil
end

function Runecrafting:OnInterfaceMenuListHasLoaded()
	local tData = { "GenericEvent_InterfaceMenu_ToggleEngraving", "", "Icon_Windows32_UI_CRB_InterfaceMenu_Runecrafting" }
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("EngravingStation_RunecraftingTitle"), tData)
end

function Runecrafting:OnToggleEngraving()
	if self.wndMain and self.wndMain:IsShown() then
		self:OnCloseFromUI()
		return
	end

	self:InitEditWindow()
end

function Runecrafting:Initialize()
	if self.wndMain and self.wndMain:IsValid() then
		return
	end

    self.wndMain = Apollo.LoadForm(self.xmlDoc, "RunecraftingForm", nil, self)
	
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("EngravingStation_RunecraftingTitle")})
	
	self.wndMain:Invoke()
	
	self.bPlayerCanCraft = GameLib.GetPlayerLevel() >= GameLib.GetLevelUpUnlock(GameLib.LevelUpUnlock.Runecrafting).nLevel
	
	if not CraftingLib.IsAtEngravingStation() then
		local wndTabs = self.wndMain:FindChild("BGFrame:RuneCreationTypes")
		wndTabs:FindChild("ToggleElementCreation"):Enable(false)
		wndTabs:FindChild("ToggleSetCreation"):Enable(false)
	else
		self:InitFilters()
	end
	
	Sound.Play(Sound.PlayUIWindowCraftingOpen)
end

function Runecrafting:OnCloseFromUI(wndHandler, wndControl)
	if wndHandler == wndControl then
		self.wndMain:Close()
	end
end

function Runecrafting:OnGenericEvent_CraftingResume_CloseEngraving()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Close()
	end
end
	
function Runecrafting:OnTradeskillEngravingStationClose()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Close()
	end
end

function Runecrafting:OnClose()
	if self.wndMain then
		self.wndMain:Destroy()
		self.wndMain = nil
		
		self.tFilters = {}
		self.wndCurrentConfirmPopup = nil
		self.wndSelectedElement = nil
		self.wndSelection = nil
		
		Sound.Play(Sound.PlayUIWindowMetalClose)
		Event_CancelEngravingStation()
	end
end

---------------------------------------------------------------------------------------
-- Crafting
---------------------------------------------------------------------------------------
	---------------------------------------------------
	-- Initialization
	---------------------------------------------------
function Runecrafting:InitCraftingWindow()
	if not self.wndMain then
		self:Initialize()
	end
	
	self.wndMain:FindChild("RuneCreationContainer"):Show(true)
	

	local wndItemList = self.wndMain:FindChild("RuneCreationItemList")
	if not self.bPlayerCanCraft then
		wndItemList:SetTextColor(crRed)
		wndItemList:SetText(String_GetWeaselString(Apollo.GetString("Runecrafting_LevelRequirementNotMet"), GameLib.GetLevelUpUnlock(GameLib.LevelUpUnlock.Runecrafting).nLevel))
	else
		wndItemList:SetTextColor(ApolloColor.new("UI_TextHoloBodyHighlight"))
		wndItemList:SetText(Apollo.GetString("Runecrafting_StartingHelperTip"))
	end
	
	local wndTabs = self.wndMain:FindChild("BGFrame:RuneCreationTypes")
	wndTabs:FindChild("ToggleElementCreation"):SetCheck(true)
	wndTabs:FindChild("ToggleSetCreation"):SetCheck(false)
	wndTabs:FindChild("ToggleEquipRunes"):SetCheck(false)
	
	self:OnElementalCreation()
end

function Runecrafting:OnElementalCreation(wndHandler, wndControl)
	self.wndSelectedElement = nil
	self.tSelectedSchematic = nil

	-- Initialize Elements
	local wndParent = self.wndMain:FindChild("RuneCreationElementList")
	wndParent:DestroyChildren()
	
	self.wndMain:FindChild("RuneCreationItemList"):DestroyChildren()
	
	local wndStatSeperator = Apollo.LoadForm(self.xmlDoc, "RuneCreationSeperator", wndParent, self)
	wndStatSeperator:SetText(Apollo.GetString("Character_Stats"))
	
	for idx, eElement in pairs(Item.CodeEnumRuneType) do
		if eElement ~= Item.CodeEnumRuneType.Fusion then
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "RuneCreationElementBtn", wndParent, self)
			wndCurr:SetData(eElement)
			wndCurr:Enable(self.bPlayerCanCraft)
			wndCurr:FindChild("RuneCreationElementIcon"):SetSprite(karElementsToCategorySprite[eElement].strFade)
			wndCurr:FindChild("RuneCreationElementIconBright"):SetSprite(karElementsToCategorySprite[eElement].strBright)
			wndCurr:FindChild("RuneCreationElementName"):SetText(karElementsToName[eElement])
		end
	end
	
	-- Set up the seperator
	local wndSpecialSeperator = Apollo.LoadForm(self.xmlDoc, "RuneCreationSeperator", wndParent, self)
	wndSpecialSeperator:SetText(Apollo.GetString("Runecrafting_Specials"))
	
	-- Set up the Fusion rune entry
	local wndFusion = Apollo.LoadForm(self.xmlDoc, "RuneCreationSpecialBtn", wndParent, self)
	wndFusion:SetData(Item.CodeEnumRuneType.Fusion)
	wndFusion:Enable(self.bPlayerCanCraft)
	
	self.wndMain:FindChild("RuneCreationItemList"):SetText(Apollo.GetString("Runecrafting_StartingHelperTip"))
	
	wndParent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	wndParent:RecalculateContentExtents()
	wndParent:SetVScrollPos(0)
	
	self.wndMain:FindChild("RuneCreationContainer:RuneCreationBottom:RuneCreationCraftBtn"):Enable(false)
	self:HelperRefreshBottomMaterials()
	
	self.wndMain:FindChild("EquipRunesContainer"):Show(false)
	self.wndMain:FindChild("RuneCreationContainer"):Show(true)
	
	local wndHeader = self.wndMain:FindChild("FilterHeader")
	local wndElements = self.wndMain:FindChild("RuneCreationElementList")
	local nLeft, nTop, nRight, nBottom = wndHeader:GetOriginalLocation():GetOffsets()
	local nElementLeft, nElementTop, nElementRight, nElementBottom = wndElements:GetOriginalLocation():GetOffsets()
	
	wndHeader:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	wndElements:SetAnchorOffsets(nElementLeft, nElementTop, nElementRight, nElementBottom)
	
	self.tFilters.nLevel = self.nDefaultLevel
	self:SelectElementOrSet(nil, nil, true)
end

function Runecrafting:OnSetCreation(wndHandler, wndControl)	
	-- Initialize Sets
	self.tSelectedSchematic = nil
	
	local wndParent = self.wndMain:FindChild("RuneCreationElementList")
	wndParent:DestroyChildren()
	
	self.wndMain:FindChild("RuneCreationItemList"):DestroyChildren()
	
	local tSets = CraftingLib.GetRuneSets(self.tFilters.eClass)
	for idx = 1, #tSets do
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "RuneCreationSetBtn", wndParent, self)
		wndCurr:SetData(tSets[idx].nSetId)
		wndCurr:Enable(self.bPlayerCanCraft)
		wndCurr:FindChild("RuneCreationSetName"):SetText(tSets[idx].strName)
	end
	
	self.wndMain:FindChild("RuneCreationItemList"):SetText(Apollo.GetString("Runecrafting_SelectSet"))
	
	wndParent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:FindChild("RuneCreationSetName"):GetText() < b:FindChild("RuneCreationSetName"):GetText() end)
	wndParent:RecalculateContentExtents()
	wndParent:SetVScrollPos(0)
	
	self.wndMain:FindChild("RuneCreationContainer:RuneCreationBottom:RuneCreationCraftBtn"):Enable(false)
	self:HelperRefreshBottomMaterials()
	self.wndMain:FindChild("EquipRunesContainer"):Show(false)
	self.wndMain:FindChild("RuneCreationContainer"):Show(true)
	
	local wndHeader = self.wndMain:FindChild("FilterHeader")
	local wndElements = self.wndMain:FindChild("RuneCreationElementList")
	local nLeft, nTop, nRight, nBottom = wndHeader:GetOriginalLocation():GetOffsets()
	local nElementLeft, nElementTop, nElementRight, nElementBottom = wndElements:GetOriginalLocation():GetOffsets()
	
	wndHeader:SetAnchorOffsets(nElementLeft, nTop, nRight, nBottom)
	wndElements:SetAnchorOffsets(nElementLeft, nBottom, nElementRight, nElementBottom)
	
	self.tFilters.nLevel = self.nDefaultLevel
	self:SelectElementOrSet(nil, nil, true)
end

	
function Runecrafting:InitFilters()	
	local wndFilters = self.wndMain:FindChild("RuneCreationContainer:FilterHeader:FilterButtons")
	local wndLevelFilter = wndFilters:FindChild("LevelFilter")
	wndFilters:FindChild("ShowCraftable"):Enable(true)
	
	local wndDropdown = wndLevelFilter:FindChild("Dropdown")
	local wndContainer = wndDropdown:FindChild("Container")
	local nPadding = wndDropdown:GetHeight() - wndContainer:GetHeight()
	
	wndContainer:DestroyChildren()

	local arLevels = CraftingLib.GetRunecraftingLevels()

	local nPlayerLevel = GameLib.GetPlayerLevel()
	for idx = 1, #arLevels do
		if arLevels[idx + 1] and nPlayerLevel < arLevels[idx + 1] then
			self.nDefaultLevel = arLevels[idx]
			break
		end
	end
	
	wndLevelFilter:SetText(String_GetWeaselString(Apollo.GetString("LevelUpUnlocks_LevelNum"), self.nDefaultLevel))

	for idx = 1, #arLevels do
		local wndEntry = Apollo.LoadForm(self.xmlDoc, "LevelFilterOption", wndContainer, self)
		wndEntry:SetText(String_GetWeaselString(Apollo.GetString("LevelUpUnlocks_LevelNum"), arLevels[idx]))
		wndEntry:SetData(arLevels[idx])
		
		if arLevels[idx] == self.nDefaultLevel then
			wndEntry:SetCheck(true)
		end
	end
	wndContainer:SetData(keFilterType.Level)
	
	-- Header for leveling runes.  Data of 0 means it'll be at the top
	local wndDivider = Apollo.LoadForm(self.xmlDoc, "FilterDropdownDivider", wndContainer, self)
	wndDivider:SetText(Apollo.GetString("Runecrafting_LevelingRunes"))
	wndDivider:SetData(0)
	
	wndDivider = Apollo.LoadForm(self.xmlDoc, "FilterDropdownDivider", wndContainer, self)
	wndDivider:SetText(Apollo.GetString("Runecrafting_ElderGameRunes"))
	
	-- Just need a value over 50  and less than the next step up for the sort function
	wndDivider:SetData(knFilterDividerData)
	
	local nHeight = wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:GetData() < b:GetData() end)
	
	local nLeft, nTop, nRight, nBottom = wndDropdown:GetAnchorOffsets()
	wndDropdown:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + nPadding)
	
	-- Slot Filter
	local wndSlotDropdown = wndFilters:FindChild("SlotFilter:Dropdown")
	local wndSlotContainer = wndSlotDropdown:FindChild("Container")
	
	nPadding = wndSlotDropdown:GetHeight() - wndSlotContainer:GetHeight()
	
	wndSlotContainer:DestroyChildren()
	
	local wndAllSlots = Apollo.LoadForm(self.xmlDoc, "SlotFilterOption", wndSlotContainer, self)
	wndAllSlots:SetText(String_GetWeaselString(Apollo.GetString("Runecrafting_FitsIn"), Apollo.GetString("Runecrafting_AnySlot")))
	wndAllSlots:SetData(knAllRunesId)
	wndAllSlots:SetCheck(true)
	
	local arSlots = CraftingLib.GetRunecraftingSchematicFilters(Item.CodeEnumRuneType.Fusion).arSlots

	for idx = 1, #arSlots do
		local wndSlot = Apollo.LoadForm(self.xmlDoc, "SlotFilterOption", wndSlotContainer, self)
		wndSlot:SetText(String_GetWeaselString(Apollo.GetString("Runecrafting_FitsIn"), ktSlotNames[arSlots[idx].eSlotId]))
		wndSlot:SetData(arSlots[idx].eSlotId)
	end
	wndSlotContainer:SetData(keFilterType.Slot)
	nHeight = wndSlotContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	wndSlotDropdown:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + nPadding)
	
	local wndClassFilter = wndFilters:FindChild("ClassFilter")
	local wndClassDropdown = wndClassFilter:FindChild("Dropdown")
	local wndClassContainer = wndClassDropdown:FindChild("Container")
	
	nPadding = wndClassDropdown:GetHeight() - wndClassContainer:GetHeight()
	
	wndClassContainer:DestroyChildren()
	
	local wndEveryClass = Apollo.LoadForm(self.xmlDoc, "ClassFilterOption", wndClassContainer, self)
	wndEveryClass:SetText(Apollo.GetString("Runecrafting_AllSets"))
	wndEveryClass:SetData(knAllRunesId)
	
	local ePlayerClass = GameLib.GetPlayerUnit():GetClassId()
	for strName, eClass in pairs(GameLib.CodeEnumClass) do
		local wndClass = Apollo.LoadForm(self.xmlDoc, "ClassFilterOption", wndClassContainer, self)
		wndClass:SetText(GameLib.GetClassName(eClass))
		wndClass:SetData(eClass)
		wndClass:SetCheck(eClass == ePlayerClass)
	end

	nHeight = wndClassContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:GetData() == knAllRunesId or a:GetText() < b:GetText() end)
	
	wndClassDropdown:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + nPadding)
	wndClassFilter:SetText(GameLib.GetClassName(ePlayerClass))
	
	self.tFilters =
	{
		idElementOrSet = 0,
		nLevel = self.nDefaultLevel,
		eSlot = 0,
		eClass = ePlayerClass,
	}	
	
	self:SelectElementOrSet(nil, nil, true)
end

	---------------------------------------------------
	-- Elements
	---------------------------------------------------

function Runecrafting:OnRuneCreationElementCheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	if self.wndSelectedElement then
		self.wndSelectedElement:FindChild("RuneCreationElementIconBright"):Show(false)
	end
	
	wndHandler:FindChild("RuneCreationElementIconBright"):Show(true)
	self.wndSelectedElement = wndHandler
	
	local wndSchematicContainer = self.wndMain:FindChild("RuneCreationItemList")
	wndSchematicContainer:DestroyChildren()
	wndSchematicContainer:SetText(Apollo.GetString("Runecrafting_SearchHelperFilter"))
	
	local eElement = wndHandler:GetData()
	local tValidFilters = CraftingLib.GetRunecraftingSchematicFilters(eElement)
	
	self:SelectElementOrSet(eElement, tValidFilters)
end

	---------------------------------------------------
	-- Rune Sets
	---------------------------------------------------

function Runecrafting:OnRuneSetCheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndContainer = self.wndMain:FindChild("RuneCreationItemList")	
	wndContainer:DestroyChildren()
	wndContainer:SetText(Apollo.GetString("Runecrafting_SearchHelperFilter"))
	
	local idSet = wndHandler:GetData()
	local tValidFilters = CraftingLib.GetRuneSetSchematicFilters(idSet)
	
	self:SelectElementOrSet(idSet, tValidFilters)
end

	---------------------------------------------------
	-- General Rune Creation Functions
	---------------------------------------------------
function Runecrafting:SelectElementOrSet(idElementOrSet, tValidFilters, bForLoad)
	local wndContainer = self.wndMain:FindChild("RuneCreationContainer:FilterHeader:FilterButtons")
	
	if idElementOrSet then
		self.tFilters.idElementOrSet = idElementOrSet
		
		local wndLevelFilter = wndContainer:FindChild("LevelFilter")
		local tValidLevels = {}

		local bFoundCurrentLevel = false
		for idx, tLevel in pairs(tValidFilters.arLevels) do
			tValidLevels[tLevel.nLevel] = tLevel.nCount
			if tLevel.nLevel == self.tFilters.nLevel then
				bFoundCurrentLevel = true
			end
		end

		for idx, wndLevel in pairs(wndLevelFilter:FindChild("Dropdown:Container"):GetChildren()) do
			local nLevel = wndLevel:GetData()		
			local bEnable = tValidLevels[nLevel] and tValidLevels[nLevel] > 0
			wndLevel:Enable(bEnable)

			if bEnable and not bFoundCurrentLevel then
				self.tFilters.nLevel = nLevel
				bFoundCurrentLevel = true
			end
			
			if nLevel > 0 and nLevel ~= knFilterDividerData then
				local bCheck = nLevel == self.tFilters.nLevel
				wndLevel:SetCheck(bCheck)
				if bCheck then
					wndLevelFilter:SetText(wndLevel:GetText())
				end
			end
		end
		
		local wndSlotFilter = wndContainer:FindChild("SlotFilter")
		local bUseSlots = self.wndMain:FindChild("BGFrame:RuneCreationTypes:ToggleElementCreation"):IsChecked() and idElementOrSet == Item.CodeEnumRuneType.Fusion
		
		if bUseSlots then
			-- "All Slots" is always valid
			local tValidSlots = {[knAllRunesId] = 1,}
			for idx, tSlot in pairs(tValidFilters.arSlots) do
				tValidSlots[tSlot.eSlotId] = tSlot.nCount
			end
			
			for idx, wndSlot in pairs(wndSlotFilter:FindChild("Dropdown:Container"):GetChildren()) do
				wndSlot:Enable(tValidSlots[wndSlot:GetData()] > 0)
			end
		end
		
		wndLevelFilter:Enable(true)
		wndSlotFilter:Enable(bUseSlots)
		wndContainer:FindChild("ShowCraftable"):Enable(true)
	else
		self.tFilters.idElementOrSet = 0
		wndContainer:FindChild("LevelFilter"):Enable(false)
		wndContainer:FindChild("SlotFilter"):Enable(false)
		wndContainer:FindChild("ShowCraftable"):Enable(false)
	end
	
	self.tFilters.eSlot = knAllRunesId
	local wndFilter = self.wndMain:FindChild("RuneCreationContainer:FilterHeader:FilterButtons:SlotFilter")
	
	for idx, wndSlot in pairs(wndFilter:FindChild("Dropdown:Container"):GetChildren()) do
		local bCorrectSlot = wndSlot:GetData() == self.tFilters.eSlot
		wndSlot:SetCheck(bCorrectSlot)
		
		if bCorrectSlot then
			wndFilter:SetText(wndSlot:GetText())
		end
	end
	
	self.tSelectedSchematic = nil
	self:ResetRuneCreationBottom()

	if not bForLoad then
		self:GetSchematics()
	end
end

function Runecrafting:ResetRuneCreationBottom()
	local wndBottom = self.wndMain:FindChild("RuneCreationContainer:RuneCreationBottom")
	wndBottom:FindChild("RuneCreationMaterialsList"):DestroyChildren()
	wndBottom:FindChild("RuneCreationMaterialsContainer"):Show(false)
	wndBottom:FindChild("RuneCreationCraftBtn"):Enable(false)
	wndBottom:FindChild("RuneCreationName"):SetText("")
end

function Runecrafting:HelperRefreshBottomMaterials()
	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end

	local wndParent = self.wndMain:FindChild("RuneCreationContainer:RuneCreationBottom")

	if not self.tSelectedSchematic then
		self:ResetRuneCreationBottom()
		return
	end
	
	self.tSelectedSchematic = CraftingLib.GetSchematicInfo(self.tSelectedSchematic.nSchematicId)

	local wndMaterialList = wndParent:FindChild("RuneCreationMaterialsList")
	wndMaterialList:DestroyChildren()
	
	local bCanMake = true
	for idx, tData in pairs(self.tSelectedSchematic.arMaterials) do
		bCanMake = bCanMake and tData.nOwned >= tData.nNeeded
		local wndMaterial = Apollo.LoadForm(self.xmlDoc, "RawMaterialsItem", wndMaterialList, self)
		wndMaterial:FindChild("RawMaterialsIcon"):SetSprite(tData.itemMaterial:GetIcon())
		wndMaterial:FindChild("RawMaterialsIcon"):SetText(String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), tData.nOwned, tData.nNeeded))
		wndMaterial:FindChild("RawMaterialsNotEnough"):Show(bNotEnough)
		Tooltip.GetItemTooltipForm(self, wndMaterial, tData.itemMaterial, {bSelling = false})
	end
	
	wndParent:FindChild("RuneCost"):SetAmount(self.tSelectedSchematic.monMaxCraftingCost)
	bCanMake = bCanMake and GameLib.GetPlayerCurrency():GetAmount() >= self.tSelectedSchematic.monMaxCraftingCost:GetAmount() and GameLib.GetEmptyInventorySlots() > 0
	
	wndParent:FindChild("RuneCreationCraftBtn"):Enable(bCanMake)
	wndMaterialList:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)
	wndMaterialList:Show(true)
	wndParent:FindChild("RefreshAnim"):SetSprite("BK3:UI_BK3_Holo_RefreshReflectionSquare_anim")

end

function Runecrafting:OnRuneSchematicCheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self.tSelectedSchematic = wndHandler:GetData()
	local wndBottom = self.wndMain:FindChild("RuneCreationContainer:RuneCreationBottom")
	wndBottom:FindChild("RuneCreationMaterialsList"):DestroyChildren()
	wndBottom:FindChild("RuneCreationCraftBtn"):SetData(self.tSelectedSchematic)
	wndBottom:FindChild("RuneCreationName"):SetText(self.tSelectedSchematic.strName)
	wndBottom:FindChild("RuneCreationMaterialsContainer"):Show(true)

	self:HelperRefreshBottomMaterials()
end

function Runecrafting:OnRuneCreationCraftBtn(wndHandler, wndControl)
	local tSchematicInfo = wndHandler:GetData()

	-- Order is important, must clear first
	Event_FireGenericEvent("GenericEvent_ClearCraftSummary")

	-- Build summary screen list
	local strSummaryMsg = Apollo.GetString("CoordCrafting_LastCraftTooltip")
	for idx, tData in pairs(tSchematicInfo.arMaterials) do
		local itemCurr = tData.itemMaterial
		if itemCurr then
			strSummaryMsg = strSummaryMsg .. "\n" .. String_GetWeaselString(Apollo.GetString("CraftingGrid_CatalystCountAndName"), itemCurr:GetName(), tData.nNeeded)
		end
	end
	Event_FireGenericEvent("GenericEvent_CraftSummaryMsg", strSummaryMsg)

	-- Craft
	CraftingLib.CraftItem(tSchematicInfo.nSchematicId)

	-- Post Craft Effects
	local wndPostCraftBlocker = self.wndMain:FindChild("RuneCreationContainer:PostCraftBlocker")
	Event_FireGenericEvent("GenericEvent_StartCraftCastBar", wndPostCraftBlocker:FindChild("CraftingSummaryContainer"), tSchematicInfo.itemOutput)
	wndPostCraftBlocker:Show(true)
end

function Runecrafting:OnCloseSummary()
	if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:FindChild("RuneCreationContainer:PostCraftBlocker"):Show(false)
	end
end


function Runecrafting:ShowFilter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	wndHandler:FindChild("Dropdown"):Show(true)
end

function Runecrafting:OnFilterClose(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndParent = wndHandler:GetParent()
	if not wndParent:ContainsMouse() then
		wndParent:SetCheck(false)
	end	
end

function Runecrafting:FilterOptionSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndContainer = wndHandler:GetParent()
	local wndDropdown = wndContainer:GetParent()
	
	local eFilterType = wndContainer:GetData()
	local strDisplay = ""
	
	if eFilterType == keFilterType.Level then
		self.tFilters.nLevel = wndHandler:GetData()
	elseif eFilterType == keFilterType.Slot then
		self.tFilters.eSlot = wndHandler:GetData()
	end
	
	wndDropdown:GetParent():SetText(wndHandler:GetText())
	
	wndDropdown:Close()
	self:GetSchematics()
end

function Runecrafting:FilterByClass(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tFilters.eClass = wndHandler:GetData()
	
	local wndDropdown = wndHandler:GetParent():GetParent()
	
	wndDropdown:GetParent():SetText(wndHandler:GetText())
	wndDropdown:Close()
	
	self:OnSetCreation()
end

function Runecrafting:ShowCraftableChecked(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:GetSchematics()
end

function Runecrafting:GetSchematics(wndHandler, wndControl)
	local wndContainer = self.wndMain:FindChild("RuneCreationContainer:RuneCreationItemList")
	
	local arSchematics = nil
	if self.wndMain:FindChild("BGFrame:RuneCreationTypes:ToggleElementCreation"):IsChecked() then
		arSchematics = CraftingLib.GetRunecraftingSchematicList(self.tFilters.idElementOrSet, self.tFilters.nLevel, self.wndMain:FindChild("ShowCraftable"):IsChecked(), self.tFilters.eSlot)
	else
		arSchematics = CraftingLib.GetRuneSetSchematicList(self.tFilters.idElementOrSet, self.tFilters.nLevel, self.wndMain:FindChild("ShowCraftable"):IsChecked(), self.tFilters.eSlot)
	end	
	
	wndContainer:DestroyChildren()

	if not arSchematics or #arSchematics == 0 then
		wndContainer:SetText(Apollo.GetString("Tradeskills_NoResults"))
		return
	end
	
	wndContainer:SetText("")
	
	for idx = 1, #arSchematics do
		local wndSchematic = Apollo.LoadForm(self.xmlDoc, "RuneSchematic", wndContainer, self)
		local wndButton = wndSchematic:FindChild("RuneSchematicBtn")
		
		local tSchematicInfo = CraftingLib.GetSchematicInfo(arSchematics[idx].nSchematicId)
		
		wndButton:SetText(arSchematics[idx].strName)
		wndButton:FindChild("RuneIcon"):SetSprite(tSchematicInfo.itemOutput:GetIcon())
		wndButton:SetData(tSchematicInfo)
		self:HelperBuildItemTooltip(wndButton, tSchematicInfo.itemOutput)
	end
	
	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

-----------------------------------------------------------------------------------------------
-- Equip Runes
-----------------------------------------------------------------------------------------------
function Runecrafting:EquipTabChecked(wndHandler, wndControl)
	self:InitEditWindow()
end

function Runecrafting:InitEditWindow(itemToDisplay)
	if not self.wndMain then
		self:Initialize()
	end
	
	local wndItemEditor = self.wndMain:FindChild("EquipRunesContainer:EquipRuneSingleItem")
	
	local wndItemDisplay = wndItemEditor:FindChild("ItemDisplay")
	
	if itemToDisplay then
		local wndItemEditor = self.wndMain:FindChild("EquipRunesContainer:EquipRuneSingleItem")
		
		-- Show the item
		local luaSubclass = wndItemDisplay:FindChild("EquipmentItem"):GetWindowSubclass()
		luaSubclass:SetItem(itemToDisplay)
		
		local strQualityColor = karQualityColors[itemToDisplay:GetItemQuality()]
		wndItemDisplay:FindChild("ItemName"):SetText(itemToDisplay:GetName())
		wndItemDisplay:FindChild("ItemName"):SetTextColor(strQualityColor)
		
		wndItemDisplay:FindChild("ItemType"):SetText(itemToDisplay:GetItemTypeName())
		wndItemDisplay:FindChild("ItemType"):SetTextColor(strQualityColor)
		
		wndItemDisplay:FindChild("ItemLevel"):SetText(String_GetWeaselString(Apollo.GetString("Tooltips_ItemLevel"), itemToDisplay:GetPowerLevel()))
		wndItemDisplay:FindChild("ItemLevel"):SetTextColor(strQualityColor)
		
		wndItemEditor:FindChild("RuneContainer"):Show(true)
		wndItemEditor:FindChild("RuneSets"):Show(true)
		
		-- Set up runes
		self:BuildRunes(itemToDisplay)
	else
		wndItemDisplay:FindChild("ItemName"):SetText(Apollo.GetString("Runecrafting_NoItem"))
		wndItemDisplay:FindChild("ItemType"):SetText("")
		wndItemDisplay:FindChild("ItemLevel"):SetText("")
		wndItemDisplay:FindChild("ItemContainer:EquipmentItem"):SetSprite("")
		wndItemEditor:FindChild("RuneContainer"):Show(false)
		wndItemEditor:FindChild("RuneSets"):Show(false)
	end
		
	local wndTabs = self.wndMain:FindChild("BGFrame:RuneCreationTypes")
	wndTabs:FindChild("ToggleElementCreation"):SetCheck(false)
	wndTabs:FindChild("ToggleSetCreation"):SetCheck(false)
	wndTabs:FindChild("ToggleEquipRunes"):SetCheck(true)
	
	self.wndMain:FindChild("EquipRunesContainer"):Show(true)
	self.wndMain:FindChild("RuneCreationContainer"):Show(false)
end

function Runecrafting:OnItemModified(itemUpdated)
	if self.wndMain and itemUpdated == self.wndMain:FindChild("EquipRunesContainer:EquipRuneSingleItem:ItemDisplay:ItemContainer:EquipmentItem"):GetData() then
		self:BuildRunes(itemUpdated)
	end
end

function Runecrafting:BuildRunes(itemUpdated)
	local wndRuneContainer = self.wndMain:FindChild("EquipRunesContainer:EquipRuneSingleItem:RuneContainer")
	if self.wndSelection then
		self:OnSelectionDestroy()
	end

	wndRuneContainer:DestroyChildren()
	
	local bIsFirstEmpty = true
	local arRuneInfo = itemUpdated:GetRuneSlots()
	if not arRuneInfo.arRuneSlots then
		return
	end

	for idx = 1, arRuneInfo.nMaximum do
		local tSlotInfo = arRuneInfo.arRuneSlots[idx]
		if tSlotInfo then
			local tData = 
			{ 
				itemSource = itemUpdated, 
				nSlotIndex = idx, 
				itemRune = tSlotInfo.itemRune, 
				eElement = tSlotInfo.eElement,
			}
			
			local wndSlot = Apollo.LoadForm(self.xmlDoc, "RuneSlotItemSingleItem", wndRuneContainer, self)
			wndSlot:FindChild("RuneSlotType"):SetSprite(tSlotInfo.itemRune and karElementsToRuneSprite[tSlotInfo.eElement].strBright or karElementsToRuneSprite[tSlotInfo.eElement].strFade)
			wndSlot:FindChild("RuneSlotBtn"):SetData(tData)
			wndSlot:FindChild("RerollBtn"):Show(not tSlotInfo.itemRune)
			wndSlot:FindChild("RerollBtn"):SetData(tData)
			
			if tSlotInfo.itemRune then
				self:HelperBuildItemTooltip(wndSlot, tSlotInfo.itemRune)
			else
				wndSlot:SetTooltip(Apollo.GetString("Runecrafting_EmptyRuneTooltip"))
			end
		else
			local wndSlot = Apollo.LoadForm(self.xmlDoc, "RuneSlotAddSingleItem", wndRuneContainer, self)
			wndSlot:FindChild("RuneSlotAppendBtn"):SetData({itemSource = itemUpdated, nSlotIndex = idx})
			wndSlot:FindChild("RuneSlotAppendBtn"):Enable(bIsFirstEmpty)
			
			wndSlot:SetTooltip(String_GetWeaselString(Apollo.GetString("EngravingStation_AddSlotTooltip"), arRuneInfo.nMaximum))
			
			bIsFirstEmpty = false
		end
	end
	
	wndRuneContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
	
	local arSetBonuses = itemUpdated:GetSetBonuses()
	
	local wndSetList = self.wndMain:FindChild("EquipRunesContainer:EquipRuneSingleItem:RuneSets:RuneSetList")
	wndSetList:DestroyChildren()

	for idx = 1, #arSetBonuses do
		local wndSetBonus = Apollo.LoadForm(self.xmlDoc, "RuneSetEntry", wndSetList, self)
		wndSetBonus:SetText(arSetBonuses[idx].strName .. " (" .. arSetBonuses[idx].nPower .. "/" .. arSetBonuses[idx].nMaxPower .. ")")
	end
	
	wndSetList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin)
end

function Runecrafting:OnRuneSlotBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	Sound.Play(Sound.PlayUIWindowMetalOpen)
	
	local tData = wndHandler:GetData()
	
	if tData.itemRune then
		self:BuildRemoveOptions(tData, wndHandler)
	else
		self:BuildRuneSelection(tData, wndHandler)
	end
end

function Runecrafting:BuildRemoveOptions(tRuneData, wndHandler)
	if self.wndSelection then
		self:OnSelectionDestroy()
	end
	
	local tRemoveInfo = CraftingLib.GetEngravingInfo(tRuneData.itemSource).tClearInfo.arSlot[tRuneData.nSlotIndex]

	self.wndSelection = Apollo.LoadForm(self.xmlDoc, "SelectionDropdown", wndHandler, self)
	self.wndSelection:FindChild("HeaderText"):SetText(Apollo.GetString("Runecrafting_RemoveRuneHeader"))
	
	local wndContainer = self.wndSelection:FindChild("SelectionContainer")
	
	local wndDestroy = Apollo.LoadForm(self.xmlDoc, "ActionConfirmSelection", wndContainer, self)
	wndDestroy:SetActionData(GameLib.CodeEnumConfirmButtonType.RuneSlotClear, tRuneData.itemSource, tRuneData.nSlotIndex, false, false)
	wndDestroy:FindChild("Text"):SetText(Apollo.GetString("Runecrafting_DestroyRune"))

	local wndCost = wndDestroy:FindChild("CostAmount")
	wndCost:Show(tRemoveInfo.monCost)
	
	if tRemoveInfo.monCost then
		wndCost:SetAmount(tRemoveInfo.monCost, true)
		
		if GameLib.GetPlayerCurrency():GetAmount() < tRemoveInfo.monCost:GetAmount() then
			wndDestroy:Enable(false)
			wndCost:SetTextColor(crRed)
		end		
	end
	
	local wndExtract = Apollo.LoadForm(self.xmlDoc, "ActionConfirmSelection", wndContainer, self)
	wndExtract:SetActionData(GameLib.CodeEnumConfirmButtonType.RuneSlotClear, tRuneData.itemSource, tRuneData.nSlotIndex, true, false)
	wndExtract:FindChild("Text"):SetText(Apollo.GetString("Runecrafting_RecoverRune"))
	
	local wndExtractCost = wndExtract:FindChild("CostAmount")
	wndExtractCost:Show(tRemoveInfo.monExtractGoldCost)
	
	if tRemoveInfo.monExtractGoldCost then
		wndExtractCost:SetAmount(tRemoveInfo.monExtractGoldCost, true)
		
		if GameLib.GetPlayerCurrency():GetAmount() < tRemoveInfo.monExtractGoldCost:GetAmount() then
			wndExtract:Enable(false)
			wndExtractCost:SetTextColor(crRed)
		end		
	end
	
	local wndRecover = Apollo.LoadForm(self.xmlDoc, "ConfirmSelection", wndContainer, self)
	local strRuneText = Apollo.GetString("Runecrafting_RecoverRune")
	local tData = 
	{	
		wndParent = self.wndMain:FindChild("ConfirmationOverlay"),
		strEventName = "ServiceTokenClosed_RuneCrafting",
		monCost = tRemoveInfo.monServiceTokenCost,
		strConfirmation = String_GetWeaselString(Apollo.GetString("ServiceToken_Confirm"), strRuneText),
		tActionData =
		{
			GameLib.CodeEnumConfirmButtonType.RuneSlotClear,
			tRuneData.itemSource,
			tRuneData.nSlotIndex,
			true,
			true
		}
	}
	
	wndRecover:SetData(tData)
	wndRecover:SetText(strRuneText)
	
	local wndRecoverCost = wndRecover:FindChild("CostAmount")
	wndRecoverCost:Show(true)
	wndRecoverCost:SetAmount(tRemoveInfo.monServiceTokenCost, true)
	
	if AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.ServiceToken):GetAmount() < tRemoveInfo.monServiceTokenCost:GetAmount() then
		wndRecover:Enable(false)
		wndRecoverCost:SetTextColor(crRed)
	end
	
	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function Runecrafting:BuildRuneSelection(tRuneData, wndHandler)
	if self.wndSelection then
		self:OnSelectionDestroy()
	end
	
	self.wndSelection = Apollo.LoadForm(self.xmlDoc, "SelectionDropdown", wndHandler, self)
	
	local arRunes = CraftingLib.GetValidRuneItems(tRuneData.itemSource, tRuneData.nSlotIndex)
	local wndRuneContainer = self.wndSelection:FindChild("SelectionContainer")
	if arRunes and #arRunes > 0 then
		for idx = 1, #arRunes do
			local wndRune = Apollo.LoadForm(self.xmlDoc, "RunePickerItem", wndRuneContainer, self)
			local wndRuneBtn = wndRune:FindChild("RunePickerItemBtn")
			wndRuneBtn:SetData({nSlotIndex = tRuneData.nSlotIndex, itemRune = arRunes[idx], itemSource = tRuneData.itemSource})
			wndRuneBtn:SetText(arRunes[idx]:GetName())
			
			local luaSubclass = wndRune:FindChild("RunePickerItemIcon"):GetWindowSubclass()
			luaSubclass:SetItem(arRunes[idx])
			self:HelperBuildItemTooltip(wndRune:FindChild("RunePickerItemIcon"), arRunes[idx])
			
			wndRuneBtn:Enable(true)
		end
	else
		self.wndSelection:FindChild("SelectionContainer"):SetText(Apollo.GetString("EngravingStation_AddPickerNone"))
	end	
	
	wndRuneContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function Runecrafting:BuildRerollOptions(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	if self.wndSelection then
		self:OnSelectionDestroy()
	end
	
	local tRerollData = wndHandler:GetData()
	
	local tRerollInfo = CraftingLib.GetEngravingInfo(tRerollData.itemSource).tRerollInfo
	
	self.wndSelection = Apollo.LoadForm(self.xmlDoc, "SelectionDropdown", wndHandler, self)
	self.wndSelection:FindChild("HeaderText"):SetText(Apollo.GetString("Runecrafting_RerollHeader"))
	
	local wndContainer = self.wndSelection:FindChild("SelectionContainer")
	
	local wndRandom = Apollo.LoadForm(self.xmlDoc, "ActionConfirmSelection", wndContainer, self)
	wndRandom:SetActionData(GameLib.CodeEnumConfirmButtonType.RuneSlotReroll, tRerollData.itemSource, tRerollData.nSlotIndex)
	wndRandom:FindChild("Text"):SetText(Apollo.GetString("Runecrafting_RerollRandom"))
	
	local wndRandomCost = wndRandom:FindChild("CostAmount")
	wndRandomCost:Show(true)
	wndRandomCost:SetAmount(tRerollInfo.monCost, true)

	if GameLib.GetPlayerCurrency():GetAmount() < tRerollInfo.monCost:GetAmount() then
		wndRandom:Enable(false)
		wndRandomCost:SetTextColor(crRed)
	end
	
	local monServiceTokens = AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.ServiceToken)
	for strName, eRuneType in pairs(Item.CodeEnumRuneType) do
		if eRuneType ~= Item.CodeEnumRuneType.Fusion and eRuneType ~= tRerollData.eElement then
			local wndReroll = Apollo.LoadForm(self.xmlDoc, "ConfirmSelection", wndContainer, self)
			local strRuneText = karElementsToName[eRuneType]
			local tData = 
			{	
				wndParent = self.wndMain:FindChild("ConfirmationOverlay"),
				strEventName = "ServiceTokenClosed_RuneCrafting",
				monCost = tRerollInfo.monServiceTokenCost,
				strConfirmation = String_GetWeaselString(Apollo.GetString("ServiceToken_Confirm"), strRuneText),
				tActionData =
				{
					GameLib.CodeEnumConfirmButtonType.RuneSlotReroll,
					tRerollData.itemSource,
					tRerollData.nSlotIndex,
					eRuneType
				}
			}
			wndReroll:SetData(tData)
			wndReroll:SetText(String_GetWeaselString(Apollo.GetString("Runecrafting_ElementSlot"), strRuneText))
			
			local wndCost = wndReroll:FindChild("CostAmount")
			wndCost:Show(true)
			wndCost:SetAmount(tRerollInfo.monServiceTokenCost, true)
			
			if tRerollInfo.monServiceTokenCost:GetAmount() > monServiceTokens:GetAmount() then
				wndCost:SetTextColor(crRed)
			end
		end
	end
	
	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	Sound.Play(Sound.PlayUIWindowHoloOpen)
end

function Runecrafting:BuildAddSlotOptions(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	if self.wndSelection then
		self:OnSelectionDestroy()
	end
	
	self.wndSelection = Apollo.LoadForm(self.xmlDoc, "SelectionDropdown", wndHandler, self)
	self.wndSelection:FindChild("HeaderText"):SetText(Apollo.GetString("Runecrafting_AddSlot"))
	
	local tAddData = wndHandler:GetData()
	local tAddInfo = CraftingLib.GetEngravingInfo(tAddData.itemSource).tAddInfo
	
	local wndContainer = self.wndSelection:FindChild("SelectionContainer")
	
	local wndRandom = Apollo.LoadForm(self.xmlDoc, "ActionConfirmSelection", wndContainer, self)
	wndRandom:SetActionData(GameLib.CodeEnumConfirmButtonType.RuneSlotAdd, tAddData.itemSource, tAddData.nSlotIndex)
	wndRandom:FindChild("Text"):SetText(Apollo.GetString("Runecrafting_RerollRandom"))

	local wndRandomCost = wndRandom:FindChild("CostAmount")
	wndRandomCost:Show(true)
	wndRandomCost:SetAmount(tAddInfo.monCost, true)

	if GameLib.GetPlayerCurrency():GetAmount() < tAddInfo.monCost:GetAmount() then
		wndRandom:Enable(false)
		wndRandomCost:SetTextColor(crRed)
	end
	
	local monServiceTokens = AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.ServiceToken)
	for strName, eRuneType in pairs(Item.CodeEnumRuneType) do
		if eRuneType ~= Item.CodeEnumRuneType.Fusion and eRuneType ~= tAddData.eElement then
			local wndAdd = Apollo.LoadForm(self.xmlDoc, "ConfirmSelection", wndContainer, self)
			local strRuneText = String_GetWeaselString(Apollo.GetString("Runecrafting_ElementSlot"), karElementsToName[eRuneType])
			local tData = 
			{
				wndParent = self.wndMain:FindChild("ConfirmationOverlay"),
				strEventName = "ServiceTokenClosed_RuneCrafting",	
				monCost = tAddInfo.monServiceTokenCost,
				strConfirmation = String_GetWeaselString(Apollo.GetString("ServiceToken_Confirm"), strRuneText),
				tActionData =
				{
					GameLib.CodeEnumConfirmButtonType.RuneSlotAdd,
					tAddData.itemSource,
					eRuneType
				}
			}
			wndAdd:SetData(tData)
			wndAdd:SetText(strRuneText)
			
			local wndCost = wndAdd:FindChild("CostAmount")
			wndCost:Show(true)
			wndCost:SetAmount(tAddInfo.monServiceTokenCost)
			
			if tAddInfo.monServiceTokenCost:GetAmount() > monServiceTokens:GetAmount() then
				wndCost:SetTextColor(crRed)
			end
		end
	end
	
	wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	Sound.Play(Sound.PlayUIButtonWindowOpen)
end

function Runecrafting:OnPurchaseWithServiceTokens(wndHandler, wndControl)
	local tData = wndControl:GetData()

	self.wndSelection:Close()

	local wndServiceTokenParent = self.wndMain:FindChild("ConfirmationOverlay")
	wndServiceTokenParent:Show(true)
	
	Event_FireGenericEvent("GenericEvent_ServiceTokenPrompt", tData)
end

function Runecrafting:OnRuneSlotAdded()
	Sound.Play(Sound.PlayUIAddRuneSlot)
end

function Runecrafting:OnOptionSelected()
	Sound.Play(Sound.PlayUIButtonHoloSmall)
end

function Runecrafting:OnServiceTokenClosed_RuneCrafting(strParent, eActionConfirmEvent, bSuccess)
	if not self.wndMain then
		return
	end

	local wndServiceTokenParent = self.wndMain:FindChild(strParent)
	if wndServiceTokenParent then
		wndServiceTokenParent:Show(false)
	end

	if eActionConfirmEvent == GameLib.CodeEnumConfirmButtonType.RuneSlotAdd and bSuccess then
		self:OnRuneSlotAdded()
	end
end


function Runecrafting:OnRunePickerItemBtn(wndHandler, wndControl)
	local tData = wndHandler:GetData()

	self:DrawAddRuneConfirm(self.wndSelection:GetParent(), tData.itemSource, tData.nSlotIndex, tData.itemRune)
		
	if self.wndSelection then
		self:OnSelectionDestroy()
	end
end

function Runecrafting:DrawAddRuneConfirm(wndHandler, itemSource, nSlotIndex, itemRune)
	-- Draw Window
	self.wndCurrentConfirmPopup = Apollo.LoadForm(self.xmlDoc, "AddConfirm", wndHandler, self)
	self.wndCurrentConfirmPopup:FindChild("AddConfirmYes"):SetData({ nSlotIndex = nSlotIndex, itemRune = itemRune, itemSource = itemSource })
	self.wndCurrentConfirmPopup:FindChild("AddConfirmIcon"):SetSprite(itemRune:GetIcon())
	self.wndCurrentConfirmPopup:FindChild("AddConfirmItemName"):SetText(itemRune:GetName())
	self.wndCurrentConfirmPopup:FindChild("SoulboundWarning"):Show(not itemSource:IsSoulbound())
	self:HelperBuildItemTooltip(self.wndCurrentConfirmPopup:FindChild("AddConfirmIcon"), itemRune)
end

function Runecrafting:OnCurrentConfirmPopupClose(wndHandler, wndControl)
	if self.wndCurrentConfirmPopup and self.wndCurrentConfirmPopup:IsValid() then
		self.wndCurrentConfirmPopup:Destroy()
		self.wndCurrentConfirmPopup = nil
	end
end

function Runecrafting:OnSelectionDestroy()
	if self.wndSelection then
		self.wndSelection:Close()
	end
end

function Runecrafting:OnSelectionClose()
	if not self.wndSelection then
		return
	end
	
	if not self.wndSelection:GetParent():ContainsMouse() then
		self.wndSelection:GetParent():SetCheck(false)
	end
	
	self.wndSelection:Destroy()
	self.wndSelection = nil

end

-----------------------------------------------------------------------------------------------
-- Drag Drop Events
-----------------------------------------------------------------------------------------------
function Runecrafting:OnDragDropQueryItem(wndHandler, wndControl, x, y, wndSource, strType, nItemSourceLoc)
	if strType ~= "DDBagItem" or wndHandler ~= wndControl then
		return
	end
	local itemSource = Item.GetItemFromInventoryLoc(nItemSourceLoc)
	if not itemSource then
		return
	end
	
	local tRuneInfo = itemSource:GetRuneSlots()
	if not tRuneInfo.nMaximum or tRuneInfo.nMaximum <= 0 then
		return Apollo.DragDropQueryResult.Invalid
	end
	
	return Apollo.DragDropQueryResult.Accept
end

function Runecrafting:OnDragDropItem(wndHandler, wndControl, x, y, wndSource, strType, nItemSourceLoc)
	if strType ~= "DDBagItem" or wndHandler ~= wndControl then
		return
	end
	
	local itemDropped = Item.GetItemFromInventoryLoc(nItemSourceLoc)
	
	if not itemDropped:GetRuneSlots().nMaximum then
		return
	end
	
	self:InitEditWindow(itemDropped)
end

function Runecrafting:OnDragDropSystemBegin(wndSource, strType, nItemSourceLoc)
	if self.wndMain then
		local itemDragged = Item.GetItemFromInventoryLoc(nItemSourceLoc)

		if itemDragged and itemDragged:IsEquippable() then
			local tRuneInfo = itemDragged:GetRuneSlots()

			if tRuneInfo and tRuneInfo.nMaximum and tRuneInfo.nMaximum > 0 then
				self.wndMain:FindChild("WindowHighlight"):Show(true)
			end
		end
	end
end

function Runecrafting:OnDragDropSystemEnd(strType, nItemSourceLoc)
	if self.wndMain then
		self.wndMain:FindChild("WindowHighlight"):Show(false)
	end
end
	
function Runecrafting:OnAddConfirmYes(wndHandler, wndControl) -- Potentially from drag drop or from picker
	local tConfirmData = wndHandler:GetData()
	if not tConfirmData then
		return
	end

	local tRuneData = tConfirmData.itemSource:GetRuneSlots()
	if tRuneData then
		local tListOfRunes = {}

		for idx = 1, #tRuneData.arRuneSlots do
			tListOfRunes[idx] = (tRuneData.arRuneSlots[idx] and tRuneData.arRuneSlots[idx].itemRune) and tRuneData.arRuneSlots[idx].itemRune:GetItemId() or 0
		end

		tListOfRunes[tConfirmData.nSlotIndex] = tConfirmData.itemRune:GetItemId() -- Replace with the desired

		--Play a sound based on the rune element and if it applies a set bonus.

		local eElement = nil
		local tRuneInfo = tConfirmData.itemRune:GetDetailedInfo( nil, Item.CodeEnumItemDetailedTooltip.Specifics )
		if tRuneInfo and tRuneInfo.tPrimary and tRuneInfo.tPrimary.arRuneTypes then
			if #tRuneInfo.tPrimary.arRuneTypes > 1 then--Assuming that if there is multiple elements this rune can fufil, it is fusion.
				eElement = Item.CodeEnumRuneType.Fusion
			else
				eElement = tRuneInfo.tPrimary.arRuneTypes[1]
			end
		end

		if eElement then
			local tSounds = karElementsToSounds[eElement]
			local arSetBonuses = tConfirmData.itemSource:GetSetBonuses()
			if tSounds then
				if #arSetBonuses > 0 and tSounds.eSet ~= nil then
					Sound.Play(tSounds.eSet)--Set Bonus Sound.
				else
					Sound.Play(tSounds.eNonSet)--Normal element sound.
				end
			end
		end

		CraftingLib.InstallRuneIntoSlot(tConfirmData.itemSource, tListOfRunes)
	end
	self:OnCurrentConfirmPopupClose()
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function Runecrafting:HelperBuildItemTooltip(wndArg, itemCurr)
	Tooltip.GetItemTooltipForm(self, wndArg, itemCurr, { bPrimary = true, bSelling = false, itemCompare = itemCurr:GetEquippedItemForItemType() })
end

local RunecraftingInst = Runecrafting:new()
RunecraftingInst:Init()
