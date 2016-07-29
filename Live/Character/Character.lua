-----------------------------------------------------------------------------------------------
-- Client Lua Script for Character
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Apollo"
require "Sound"
require "Spell"
require "Item"
require "Unit"
require "CharacterTitle"
require "GameLib"
require "CostumesLib"
require "AccountItemLib"
require "GuildLib"
require "PlayerPathLib"

local Character = {}

local knSaveVersion = 3
local knAttributeContainerPadding = 11
local knGearScoreDecimalThreshold = 10

local ktSlotWindowNameToTooltip =
{
	["HeadSlot"] 				= Apollo.GetString("Character_HeadEmpty"),
	["ShoulderSlot"] 			= Apollo.GetString("Character_ShoulderEmpty"),
	["ChestSlot"] 				= Apollo.GetString("Character_ChestEmpty"),
	["HandsSlot"] 				= Apollo.GetString("Character_HandsEmpty"),
	["LegsSlot"] 				= Apollo.GetString("Character_LegsEmpty"),
	["FeetSlot"]				= Apollo.GetString("Character_FeetEmpty"),
	["ToolSlot"] 				= Apollo.GetString("Character_ToolEmpty"),
	["WeaponAttachmentSlot"] 	= Apollo.GetString("Character_AttachmentEmpty"),
	["SupportSystemSlot"] 		= Apollo.GetString("Character_SupportEmpty"),
	["GadgetSlot"] 				= Apollo.GetString("Character_GadgetEmpty"),
	["AugmentSlot"] 			= Apollo.GetString("Character_KeyEmpty"),
	["ImplantSlot"] 			= Apollo.GetString("Character_ImplantEmpty"),
	["ShieldSlot"] 				= Apollo.GetString("Character_ShieldEmpty"),
	["WeaponSlot"] 				= Apollo.GetString("Character_WeaponEmpty"),
}

local karClassToString =
{
	[GameLib.CodeEnumClass.Warrior] 		= Apollo.GetString("ClassWarrior"),
	[GameLib.CodeEnumClass.Engineer] 		= Apollo.GetString("ClassEngineer"),
	[GameLib.CodeEnumClass.Esper] 			= Apollo.GetString("ClassESPER"),
	[GameLib.CodeEnumClass.Medic] 			= Apollo.GetString("ClassMedic"),
	[GameLib.CodeEnumClass.Stalker] 		= Apollo.GetString("ClassStalker"),
	[GameLib.CodeEnumClass.Spellslinger] 	= Apollo.GetString("ClassSpellslinger"),
}

local karClassToIcon =
{
	[GameLib.CodeEnumClass.Warrior] 		= "BK3:UI_Icon_CharacterCreate_Class_Warrior",
	[GameLib.CodeEnumClass.Engineer] 		= "BK3:UI_Icon_CharacterCreate_Class_Engineer",
	[GameLib.CodeEnumClass.Esper] 			= "BK3:UI_Icon_CharacterCreate_Class_Esper",
	[GameLib.CodeEnumClass.Medic] 			= "BK3:UI_Icon_CharacterCreate_Class_Medic",
	[GameLib.CodeEnumClass.Stalker] 		= "BK3:UI_Icon_CharacterCreate_Class_Stalker",
	[GameLib.CodeEnumClass.Spellslinger] 	= "BK3:UI_Icon_CharacterCreate_Class_Spellslinger",
}

local ktPathToString =
{
  [PlayerPathLib.PlayerPathType_Soldier]    = Apollo.GetString("PlayerPathSoldier"),
  [PlayerPathLib.PlayerPathType_Settler]    = Apollo.GetString("PlayerPathSettler"),
  [PlayerPathLib.PlayerPathType_Scientist]  = Apollo.GetString("PlayerPathScientist"),
  [PlayerPathLib.PlayerPathType_Explorer]   = Apollo.GetString("PlayerPathExplorer"),
}

local ktPathToIcon =
{
  [PlayerPathLib.PlayerPathType_Soldier]    = "BK3:UI_Icon_CharacterCreate_Path_Soldier",
  [PlayerPathLib.PlayerPathType_Settler]    = "BK3:UI_Icon_CharacterCreate_Path_Settler",
  [PlayerPathLib.PlayerPathType_Scientist]  = "BK3:UI_Icon_CharacterCreate_Path_Scientist",
  [PlayerPathLib.PlayerPathType_Explorer]   = "BK3:UI_Icon_CharacterCreate_Path_Explorer",
}

local karFactionToString =
{
	[Unit.CodeEnumFaction.ExilesPlayer] 	= Apollo.GetString("CRB_Exile"),
	[Unit.CodeEnumFaction.DominionPlayer] 	= Apollo.GetString("CRB_Dominion"),
}

local karFactionToIcon =
{
	[Unit.CodeEnumFaction.ExilesPlayer] 	= "charactercreate:sprCharC_Ico_Exile_Lrg",
	[Unit.CodeEnumFaction.DominionPlayer] 	= "charactercreate:sprCharC_Ico_Dominion_Lrg",
}

local karRaceToString =
{
	[GameLib.CodeEnumRace.Human] 	= Apollo.GetString("RaceHuman"),
	[GameLib.CodeEnumRace.Granok] 	= Apollo.GetString("RaceGranok"),
	[GameLib.CodeEnumRace.Aurin] 	= Apollo.GetString("RaceAurin"),
	[GameLib.CodeEnumRace.Draken] 	= Apollo.GetString("RaceDraken"),
	[GameLib.CodeEnumRace.Mechari] 	= Apollo.GetString("RaceMechari"),
	[GameLib.CodeEnumRace.Chua] 	= Apollo.GetString("RaceChua"),
	[GameLib.CodeEnumRace.Mordesh] 	= Apollo.GetString("CRB_Mordesh"),
}

local ktRaceToIcon =
{
	[Unit.CodeEnumFaction.DominionPlayer] = 
	{
		[Unit.CodeEnumGender.Male] =
		{
			[GameLib.CodeEnumRace.Human] 	= "charactercreate:sprCharC_Finalize_RaceDomM",
			[GameLib.CodeEnumRace.Granok] 	= "charactercreate:sprCharC_Finalize_RaceGranokM",
			[GameLib.CodeEnumRace.Aurin] 	= "charactercreate:sprCharC_Finalize_RaceAurinM",
			[GameLib.CodeEnumRace.Draken] 	= "charactercreate:sprCharC_Finalize_RaceDrakenM",
			[GameLib.CodeEnumRace.Mechari] 	= "charactercreate:sprCharC_Finalize_RaceMechariM",
			[GameLib.CodeEnumRace.Mordesh] 	= "charactercreate:sprCharC_Finalize_RaceMordeshM",
			[GameLib.CodeEnumRace.Chua] 	= "charactercreate:sprCharC_Finalize_RaceChua",
		},
		[Unit.CodeEnumGender.Female] =
		{
			[GameLib.CodeEnumRace.Human] 	= "charactercreate:sprCharC_Finalize_RaceDomF",
			[GameLib.CodeEnumRace.Granok] 	= "charactercreate:sprCharC_Finalize_RaceGranokF",
			[GameLib.CodeEnumRace.Aurin] 	= "charactercreate:sprCharC_Finalize_RaceAurinF",
			[GameLib.CodeEnumRace.Draken] 	= "charactercreate:sprCharC_Finalize_RaceDrakenF",
			[GameLib.CodeEnumRace.Mechari] 	= "charactercreate:sprCharC_Finalize_RaceMechariF",
			[GameLib.CodeEnumRace.Mordesh] 	= "charactercreate:sprCharC_Finalize_RaceMordeshF",
			[GameLib.CodeEnumRace.Chua] 	= "charactercreate:sprCharC_Finalize_RaceChua",
		}
	},
	[Unit.CodeEnumFaction.ExilesPlayer] = 
	{
		[Unit.CodeEnumGender.Male] =
		{
			[GameLib.CodeEnumRace.Human] 	= "charactercreate:sprCharC_Finalize_RaceExileM",
			[GameLib.CodeEnumRace.Granok] 	= "charactercreate:sprCharC_Finalize_RaceGranokM",
			[GameLib.CodeEnumRace.Aurin] 	= "charactercreate:sprCharC_Finalize_RaceAurinM",
			[GameLib.CodeEnumRace.Draken] 	= "charactercreate:sprCharC_Finalize_RaceDrakenM",
			[GameLib.CodeEnumRace.Mechari] 	= "charactercreate:sprCharC_Finalize_RaceMechariM",
			[GameLib.CodeEnumRace.Mordesh] 	= "charactercreate:sprCharC_Finalize_RaceMordeshM",
		},
		[Unit.CodeEnumGender.Female] =
		{
			[GameLib.CodeEnumRace.Human] 	= "charactercreate:sprCharC_Finalize_RaceExileF",
			[GameLib.CodeEnumRace.Granok] 	= "charactercreate:sprCharC_Finalize_RaceGranokF",
			[GameLib.CodeEnumRace.Aurin] 	= "charactercreate:sprCharC_Finalize_RaceAurinF",
			[GameLib.CodeEnumRace.Draken] 	= "charactercreate:sprCharC_Finalize_RaceDrakenF",
			[GameLib.CodeEnumRace.Mechari] 	= "charactercreate:sprCharC_Finalize_RaceMechariF",
			[GameLib.CodeEnumRace.Mordesh] 	= "charactercreate:sprCharC_Finalize_RaceMordeshF",
		}
	},
}

local kstrInspectAffiliation =
{
	[GuildLib.GuildType_Guild]			= Apollo.GetString("Inspect_GuildDisplay"),
	[GuildLib.GuildType_Circle]			= Apollo.GetString("Inspect_CircleDisplay"),
	[GuildLib.GuildType_ArenaTeam_2v2]	= Apollo.GetString("Inspect_2v2ArenaDisplay"),
	[GuildLib.GuildType_ArenaTeam_3v3]	= Apollo.GetString("Inspect_3v3ArenaDisplay"),
	[GuildLib.GuildType_ArenaTeam_5v5]	= Apollo.GetString("Inspect_5v5ArenaDisplay"),
	[GuildLib.GuildType_WarParty]		= Apollo.GetString("Inspect_WarpartyDisplay")
}

local karCostumeSlots =
{
	GameLib.CodeEnumItemSlots.Weapon,
	GameLib.CodeEnumItemSlots.Head,
	GameLib.CodeEnumItemSlots.Shoulder,
	GameLib.CodeEnumItemSlots.Chest,
	GameLib.CodeEnumItemSlots.Hands,
	GameLib.CodeEnumItemSlots.Legs,
	GameLib.CodeEnumItemSlots.Feet,
}

local ktItemSlotToEquippedItems =
{
	[GameLib.CodeEnumEquippedItems.Chest] = 		GameLib.CodeEnumItemSlots.Chest, 
	[GameLib.CodeEnumEquippedItems.Legs] = 			GameLib.CodeEnumItemSlots.Legs,
	[GameLib.CodeEnumEquippedItems.Head] = 			GameLib.CodeEnumItemSlots.Head,
	[GameLib.CodeEnumEquippedItems.Shoulder] = 		GameLib.CodeEnumItemSlots.Shoulder,
	[GameLib.CodeEnumEquippedItems.Feet] = 			GameLib.CodeEnumItemSlots.Feet,
	[GameLib.CodeEnumEquippedItems.Hands] = 		GameLib.CodeEnumItemSlots.Hands,
	[GameLib.CodeEnumEquippedItems.WeaponPrimary] = GameLib.CodeEnumItemSlots.Weapon,
}

local ktVIPIcons = 
{
	[1] = "CRB_CN:CRB_CN_VIP1_C",
	[2] = "CRB_CN:CRB_CN_VIP2_C",
	[3] = "CRB_CN:CRB_CN_VIP3_C",
	[4] = "CRB_CN:CRB_CN_VIP4_C",
	[5] = "CRB_CN:CRB_CN_VIP5_C",
	[6] = "CRB_CN:CRB_CN_VIP6_C",
	[7] = "CRB_CN:CRB_CN_VIP7_C",
	[8] = "CRB_CN:CRB_CN_VIP8_C",
	[9] = "CRB_CN:CRB_CN_VIP9_C",
	[10] = "CRB_CN:CRB_CN_VIP10_C",
}
function Character:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Character:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {}

    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function Character:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Character.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

-- TODO: Refactor, if costumes is enough code it can be separated into another add-on. Also it'll give it more modability anyways.
function Character:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded",						"OnInterfaceMenuListHasLoaded", self)
	self:OnInterfaceMenuListHasLoaded()

	self.timerTitleChange = ApolloTimer.Create(1.0, false, "OnDrawEditNamePopout", self)
	self.timerTitleChange:Stop()
	Apollo.RegisterEventHandler("PersonaUpdateCharacterStats", 						"OnPersonaUpdateCharacterStats", self)
	Apollo.RegisterEventHandler("ToggleCharacterWindow", 							"OnToggleCharacterWindow", self)
	Apollo.RegisterEventHandler("PlayerTitleChange", 								"DrawNames", self)
	Apollo.RegisterEventHandler("UI_EffectiveLevelChanged", 						"OnEffectiveLevelChange", self)
	Apollo.RegisterEventHandler("PlayerTitleUpdate", 								"OnDrawEditNamePopout", self)
	Apollo.RegisterEventHandler("Death", 											"DrawAttributes", self)
	Apollo.RegisterEventHandler("GuildChange", 										"OnGuildChange", self)
	Apollo.RegisterEventHandler("ItemConfirmSoulboundOnEquip",						"OnItemConfirmSoulboundOnEquip", self)
	Apollo.RegisterEventHandler("ItemConfirmClearRestockOnEquip",					"OnItemConfirmClearRestockOnEquip", self)
	Apollo.RegisterEventHandler("ItemDurabilityUpdate",								"OnItemDurabilityUpdate", self)
	Apollo.RegisterEventHandler("CostumeSet",										"OnCostumeSet", self)
	Apollo.RegisterEventHandler("CostumeCooldownComplete",							"OnThrottleEnd", self)
	Apollo.RegisterEventHandler("ChangeWorld",										"OnClose", self)
	Apollo.RegisterEventHandler("PlayerLevelChange",					 			"OnPlayerLevelChange", self)

	-- Open Tab UIs
	Apollo.RegisterEventHandler("GenericEvent_ToggleReputation", 					"OnToggleReputation", self)
	Apollo.RegisterEventHandler("ToggleReputationInterface", 						"OnToggleReputation", self)

	-- TODO: There is capability to differentiate between the events later
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_CostumeSystem",			"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_CostumeSlot2", 			"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_CostumeSlot3", 			"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_CostumeSlot4", 			"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_CostumeSlot5", 			"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_CostumeSlot6", 			"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_GearSlot_Gadgets",			"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_GearSlot_Gloves",			"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_GearSlot_Helm",			"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_GearSlot_Implants",		"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_GearSlot_RaidKey",			"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_GearSlot_Shield",			"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_GearSlot_Shoulders",		"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_GearSlot_SupportSystem",	"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Character_GearSlot_WeaponAttachment","OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Class_Attribute",					"OnLevelUpUnlock_Character_Generic", self)
	Apollo.RegisterEventHandler("LevelUpUnlock_Path_Title",							"OnLevelUpUnlock_Character_Generic", self)
	
	Apollo.RegisterEventHandler("PlayerEquippedItemChanged",						"MapEquipment", self)

	Apollo.RegisterEventHandler("PremiumTierChanged", 								"OnPremiumTierChanged", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate", 						"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate",						"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("StoreLinksRefresh",								"RefreshStoreLink", self)

	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 						"OnTutorial_RequestUIAnchor", self)

	Apollo.RegisterEventHandler("Inspect",											"OnInspect", self)

	self.wndAttributeTooltip		= nil
	self.wndCharacter 				= Apollo.LoadForm(self.xmlDoc, "CharacterWindow", nil, self)
	self.wndCostume 				= self.wndCharacter:FindChild("CharFrame_BGArt:Costume")

	self.wndCharacterEverything		= self.wndCharacter:FindChild("CharacterEverything")
	self.wndCharacterStats			= self.wndCharacterEverything:FindChild("CharacterStats")
	self.wndCharacterBonus			= self.wndCharacterEverything:FindChild("CharacterBonus")
	self.wndCharacterTitles			= self.wndCharacter:FindChild("CharacterInformation")
	self.wndCharacterCostumes		= self.wndCharacterEverything:FindChild("CharacterCostumes")
	self.wndCostumeSelectionList 	= self.wndCharacterEverything:FindChild("CharacterCostumes:CostumeBtnHolder")
	self.wndCostumeList				= self.wndCostumeSelectionList:FindChild("CostumeList")
	self.wndCostumeListBlocker		= self.wndCostumeSelectionList:FindChild("CostumeListBlocker")
	self.wndEntitlements			= self.wndCharacter:FindChild("Entitlements")
	self.wndGridContainer 			= self.wndEntitlements:FindChild("GridContainer")
	self.wndCharacterReputation		= self.wndCharacterEverything:FindChild("CharacterReputation")
	self.wndDropdownContents		= self.wndCharacterEverything:FindChild("DropdownContents")

	self.wndCharacter:FindChild("DropdownBtn"):AttachWindow(self.wndDropdownContents)
	self.wndCharacter:FindChild("TitleSelectionBtn"):AttachWindow(self.wndCharacter:FindChild("NameEditTitleContainer"))
	self.wndCharacter:FindChild("ClassTitleGuild"):AttachWindow(self.wndCharacter:FindChild("NameEditGuildTagContainer"))
	self.wndCharacter:FindChild("CharacterTitleDropdown"):AttachWindow(self.wndCharacter:FindChild("CharacterTitleContainer"))

	self.wndCharacter:Show(false)

	self.wndBindConfirm	= Apollo.LoadForm(self.xmlDoc, "BindConfirm", nil, self)

	self.bStatsValid 		= false
	self.listAttributes 	= {}
	self.tOffensiveStats 	= {}
	self.tDefensiveStats 	= {}

	local wndVisibleSlots = self.wndCharacter:FindChild("VisibleSlots")
	self.arSlotsWindowsByName = -- each one has the slot name and then the corresponding UI window
	{
		[Apollo.GetString("InventorySlot_Head")] 			= wndVisibleSlots:FindChild("HeadSlot"), -- TODO: No enum to compare to code
		[Apollo.GetString("InventorySlot_Shoulder")] 		= wndVisibleSlots:FindChild("ShoulderSlot"),
		[Apollo.GetString("InventorySlot_Chest")] 			= wndVisibleSlots:FindChild("ChestSlot"),
		[Apollo.GetString("InventorySlot_Hands")] 			= wndVisibleSlots:FindChild("HandsSlot"),
		[Apollo.GetString("InventorySlot_Legs")] 			= wndVisibleSlots:FindChild("LegsSlot"),
		[Apollo.GetString("InventorySlot_Feet")] 			= wndVisibleSlots:FindChild("FeetSlot"),
		[Apollo.GetString("InventorySlot_WeaponPrimary")] 	= wndVisibleSlots:FindChild("WeaponSlot")
	}
	
	-- Titles
	self.wndSelectedTitle = nil;

	-- Costumes
	self.nCostumeCount = 0
	self:RefreshStoreLink()

	self.wndCostumeSelectionList:FindChild("ClearCostumeBtn"):SetData(0)

	self.wndCharacter:FindChild("DropdownBtn"):SetText(String_GetWeaselString(Apollo.GetString("Character_Display"), Apollo.GetString("Character_Stats")))
	
	-- Guild Holo
	local wndHolomarkContainer = self.wndCharacterTitles:FindChild("NameEditGuildHolomarkContainer")
	wndHolomarkContainer:FindChild("GuildHolomarkLeftBtn"):SetCheck(GameLib.GetGuildHolomarkVisible(GameLib.GuildHolomark.Left))
    wndHolomarkContainer:FindChild("GuildHolomarkRightBtn"):SetCheck(GameLib.GetGuildHolomarkVisible(GameLib.GuildHolomark.Right))
    wndHolomarkContainer:FindChild("GuildHolomarkBackBtn"):SetCheck(GameLib.GetGuildHolomarkVisible(GameLib.GuildHolomark.Back))
	local bDisplayNear = GameLib.GetGuildHolomarkDistance()
	if bDisplayNear then
	    wndHolomarkContainer:SetRadioSel("GuildHolomarkDistance", 1)
	else
	    wndHolomarkContainer:SetRadioSel("GuildHolomarkDistance", 2)
    end

    Apollo.RegisterEventHandler("WindowManagementReady",							"OnWindowManagementReady", self)
	self:OnWindowManagementReady()
end

function Character:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_Character"), {"ToggleCharacterWindow", "CharacterPanel", "Icon_Windows32_UI_CRB_InterfaceMenu_Character"})
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_Reputation"), {"GenericEvent_ToggleReputation", "Reputation", "Icon_Windows32_UI_CRB_InterfaceMenu_Character"})
end

function Character:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("InterfaceMenu_Character"), nSaveVersion = knSaveVersion})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndCharacter, strName = Apollo.GetString("InterfaceMenu_Character")})
end

-----------------------------------------------------------------------------------------------
-- Opening / Closing / Tab Visibility Checks
-----------------------------------------------------------------------------------------------

function Character:OnToggleCharacterWindow()
	if not self.wndCharacter:IsVisible() then
		self:ShowCharacterWindow()
	else
		self.wndCharacter:Close()
		Event_FireGenericEvent("CharacterWindowHasBeenClosed")
		Sound.Play(Sound.PlayUI01ClosePhysical)
	end
end

function Character:OnToggleReputation()
	if self.wndCharacterReputation:IsVisible() then
		self.wndCharacter:Close()
	else
		self:OpenReputation()
	end
end

function Character:OpenReputation()
	self:ShowCharacterWindow()
	if not self.wndCharacterReputation:IsShown() then
		Event_FireGenericEvent("GenericEvent_InitializeReputation", self.wndCharacterReputation)
	end
	self.wndCharacterCostumes:Show(false)
	self.wndCharacterStats:Show(false)
	self.wndCharacterBonus:Show(false)
	self.wndCharacterReputation:Show(true)
	self.wndCharacter:FindChild("DropdownBtn"):SetText(String_GetWeaselString(Apollo.GetString("Character_Display"), Apollo.GetString("Character_Reputation")))
	self.wndDropdownContents:Show(false)
	self.wndEntitlements:Show(false)
end

function Character:CloseReputation()
	self.wndCharacterReputation:Show(false)
	Event_FireGenericEvent("GenericEvent_DestroyReputation")
end

-----------------------------------------------------------------------------------------------
-- Other UI Visibility
-----------------------------------------------------------------------------------------------

function Character:OnNameEditClearTitleBtn()
	CharacterTitle.SetTitle(nil)
	self.strTitle = ""
	self.wndCharacterTitles:FindChild("NameEditClearTitleBtn"):Enable(false)
	self.wndCharacter:FindChild("CharacterTitleDropdown"):SetText(Apollo.GetString("Character_ChooseTitle"))
	
	-- Uncheck the previously selected title in the list
	if self.wndSelectedTitle ~= nil then
		self.wndSelectedTitle:SetCheck(false)
		self.wndSelectedTitle = nil
	end
end

function Character:ShowCharacterWindow()
	local unitPlayer = GameLib.GetPlayerUnit()
	self.wndCharacter:SetData(unitPlayer)

	self.wndCharacter:Invoke()
	self:MapEquipment()
	self:OnDrawEditNamePopout()

	self.wndCharacter:FindChild("DropdownBtn"):SetText(String_GetWeaselString(Apollo.GetString("Character_Display"), Apollo.GetString("Character_Stats")))
	self.wndCharacterEverything:Show(true)
	self.wndCharacterStats:Show(true)
	self.wndCharacterCostumes:Show(false)
	self.wndCharacterBonus:Show(false)
	self.wndCharacterReputation:Show(false)
	self.wndEntitlements:Show(false)
	self.wndCharacter:ToFront()
	self:DrawAttributes(self.wndCharacter)
	self:DrawNames(self.wndCharacter)

	self.wndCostume:SetCostume(unitPlayer)
	self.wndCostume:SetSheathed(self.wndCharacter:FindChild("SetSheatheBtn"):IsChecked())
	
	self:UpdateCostumeList()

	Event_FireGenericEvent("CharacterWindowHasBeenToggled")
	Sound.Play(Sound.PlayUI68OpenPanelFromKeystrokeVirtual)
	Event_ShowTutorial(GameLib.CodeEnumTutorial.CharacterPanel)
end

function Character:OnPremiumTierChanged(ePremiumSystem, nTier)
	if self.wndCharacter == nil then
		return
	end

	self:UpdateGuildHolomarks()
end

--Entitlements
function Character:OnEntitlementUpdate(tEntitlementInfo)
	self:RefreshEntitlements()
	if tEntitlementInfo.nEntitlementId == AccountItemLib.CodeEnumEntitlement.CostumeSlots then
		self:UpdateCostumeList()
	end
end

function Character:UpdateGuildHolomarks()
	if not self.wndCharacter or not self.wndCharacter:IsValid() then
		return
	end

	local wndHolomarkContainer = self.wndCharacterTitles:FindChild("NameEditGuildHolomarkContainer")
	local tHoloMarkInfo = 
	{
		[GameLib.CodeEnumHoloMark.Left] = wndHolomarkContainer:FindChild("GuildHolomarkLeftBtn"),
		[GameLib.CodeEnumHoloMark.Right] = wndHolomarkContainer:FindChild("GuildHolomarkRightBtn"),
		[GameLib.CodeEnumHoloMark.Back] = wndHolomarkContainer:FindChild("GuildHolomarkBackBtn"),
	}

	for eHoloMark, wndHoloBtn in pairs(tHoloMarkInfo) do
		wndHoloBtn:Enable(GameLib.CanShowGuildHolomark(eHoloMark))
	end
	

	local bShow = true
	local tHoloRewardProperty = AccountItemLib.GetPlayerRewardProperty(AccountItemLib.CodeEnumRewardProperty.GuildHolomarkUnlimited)
	if tHoloRewardProperty.nValue ~= nil then
		bShow = tHoloRewardProperty.nValue == 0--0 is the value returned when the player does not reward property
	end

	wndHolomarkContainer:FindChild("VIPRestriction"):Show(bShow)
end

function Character:RefreshEntitlements()
	if not self.wndCharacter or not self.wndCharacter:IsValid() then
		return
	end

	local tEntitlements = {}
	for idx, tEntitlement in pairs(AccountItemLib.GetAccountEntitlements()) do
		if tEntitlement.nId ~= nil then
			tEntitlement.bAccount = true
			tEntitlements[tEntitlement.nId] = tEntitlement
		end
	end
	
	for idx, tEntitlement in pairs(AccountItemLib.GetCharacterEntitlements()) do
		if tEntitlements[tEntitlement.nId] then--This entitlement is for both characters and accounts.
			tEntitlements[tEntitlement.nId].bCharacter = true
			tEntitlements[tEntitlement.nId].nCount = tEntitlements[tEntitlement.nId].nCount + tEntitlement.nCount
		else
			tEntitlement.bCharacter = true
			tEntitlements[tEntitlement.nId] = tEntitlement
		end
	end

	self.wndGridContainer:DestroyChildren()
	local nCount = 0
	for idx, tEntitlement in pairs(tEntitlements) do
		nCount = nCount + 1
		local wndObject = Apollo.LoadForm(self.xmlDoc, "EntitlementsForm", self.wndGridContainer, self)
		local wndEntitlementName = wndObject:FindChild("EntitlementName")
		local wndGivenIcon = wndObject:FindChild("GivenIcon")
		if tEntitlement.icon ~= "" then
			wndGivenIcon:FindChild("Icon"):SetSprite(tEntitlement.icon)
			wndGivenIcon:Show(true)
		else
			local nGivenIconWidth = wndGivenIcon:GetWidth()
			local nLeft, nTop, nRight, nBottom = wndEntitlementName:GetAnchorOffsets()
			wndEntitlementName:SetAnchorOffsets(nLeft - nGivenIconWidth, nTop, nRight + nGivenIconWidth, nBottom)
		end

		wndObject:FindChild("AccountIcon"):Show(tEntitlement.bAccount)
		wndObject:FindChild("CharacterIcon"):Show(tEntitlement.bCharacter)

		wndObject:SetTooltip(tEntitlement.strDescription)
		wndEntitlementName:SetText(tEntitlement.nMaxCount > 1 and String_GetWeaselString(Apollo.GetString("CRB_EntitlementCount"), tEntitlement.strName, tEntitlement.nCount) or tEntitlement.strName)
		wndObject:FindChild("EntitlementCount"):SetText(String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), AccountItemLib.GetEntitlementCount(tEntitlement.nId), tEntitlement.nMaxCount))
		
		wndObject:FindChild("IconContainer"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)
	end
	
	self.wndEntitlements:FindChild("NoEntitlements"):Show(nCount == 0)
	self.wndGridContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function Character:UpdateCostumeList()
	self.nCurrentCostume = CostumesLib.GetCostumeIndex()
	local nCurrentCostumeCount = CostumesLib.GetCostumeCount()
	if nCurrentCostumeCount < self.nCostumeCount then
		-- shrink list
		for idx = nCurrentCostumeCount + 1, self.nCostumeCount do
			self.wndCostumeList:FindChild("CostumeBtn"..idx):Destroy()
		end
		self.wndCostumeList:FindChild("CostumeBtn"..self.nCurrentCostume):SetCheck(true)
	else
		-- grow list
		for idx = self.nCostumeCount + 1, nCurrentCostumeCount do
			local wndCostumeBtn = Apollo.LoadForm(self.xmlDoc, "CostumeBtn", self.wndCostumeList, self)
			wndCostumeBtn:SetData(idx)
			wndCostumeBtn:SetText(String_GetWeaselString(Apollo.GetString("Character_CostumeNum"), idx))
			wndCostumeBtn:SetName("CostumeBtn" .. idx)
			wndCostumeBtn:SetCheck(idx == self.nCurrentCostume)
		end
	end
	
	local wndCostumeBtnMTX = self.wndCostumeList:FindChild("CostumeBtnMTX")
	self.nCostumeCount = nCurrentCostumeCount
	local nMTXBtnHeight = 0
	local nCostumeMaxCount = CostumesLib.GetCostumeMaxCount()
	if self.nCostumeCount < nCostumeMaxCount and self.tStoreLinkValid[StorefrontLib.CodeEnumStoreLink.CostumeSlots] then
		if wndCostumeBtnMTX == nil then
			wndCostumeBtnMTX = Apollo.LoadForm(self.xmlDoc, "CostumeBtnMTX", self.wndCostumeList, self)
			wndCostumeBtnMTX:SetData(nCostumeMaxCount)
		end
		nMTXBtnHeight = wndCostumeBtnMTX:GetHeight()
	elseif wndCostumeBtnMTX ~= nil then
		wndCostumeBtnMTX:Destroy()
	end
	
	self.wndCostumeSelectionList:FindChild("ClearCostumeBtn"):Enable(self.nCurrentCostume ~= 0)
	self.wndCostumeSelectionList:FindChild("EquipBtn"):Enable(false)
	local nButtonListHeight = self.wndCostumeList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndFirst, wndSecond) return wndFirst:GetData() < wndSecond:GetData() end)
	local nLeft, nTop, nRight, nBottom = self.wndCostumeList:GetAnchorOffsets()
	self.wndCostumeList:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nButtonListHeight)
	self.wndCostumeListBlocker:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nButtonListHeight - nMTXBtnHeight)
end

function Character:RefreshStoreLink()
	self.tStoreLinkValid = {}
	self.tStoreLinkValid[StorefrontLib.CodeEnumStoreLink.CostumeSlots] = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.CostumeSlots)
	self.tStoreLinkValid[StorefrontLib.CodeEnumStoreLink.Signature] = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.Signature)
	self:UpdateCostumeList()
end

function Character:UnlockMoreCostumes()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.CostumeSlots)
end


function Character:OnJoinVIPBtn()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Signature)
end

function Character:OnCostumeBtnToggle(wndHandler, wndCtrl)
	if wndHandler ~= wndCtrl then
		return false
	end

	--self.nCurrentCostume = CostumesLib.GetCostumeIndex()

	local idCostume = wndHandler:GetData()

	local costumePreview = CostumesLib.GetCostume(idCostume)
	for idx = 1, #karCostumeSlots do
		local eSlot = karCostumeSlots[idx]
		local bIsVisible = costumePreview:IsSlotVisible(eSlot)
		local itemEquipped = costumePreview:GetSlotItem(eSlot)--Get Item from costume.
		if not itemEquipped then--If the item was not in this costume, show the item currently equipped.
			itemEquipped = self.tEquipmentMap[eSlot]
		end

		local arDyes = costumePreview:GetSlotDyes(eSlot)
		if bIsVisible and itemEquipped then
			self.wndCostume:SetItem(itemEquipped)
			self.wndCostume:SetItemDye(itemEquipped, arDyes[1].nId, arDyes[2].nId, arDyes[3].nId)
		else
			self.wndCostume:RemoveItem(eSlot)
		end
	end

	local wndEquipBtn = self.wndCostumeSelectionList:FindChild("EquipBtn")
	wndEquipBtn:SetData(idCostume)
	wndEquipBtn:Enable(self.nCurrentCostume ~= idCostume)
end

function Character:OnEquipBtn(wndHandler, wndControl)
	local idCostume = wndHandler:GetData()
	if self.nCurrentCostume == idCostume then
		return
	end

	CostumesLib.SetCostumeIndex(idCostume)
	self.nCurrentCostume = idCostume
	Event_FireGenericEvent("CostumeSet", idCostume)
end

function Character:OnNoCostumeBtn()
	if self.nCurrentCostume == 0 then
		return
	end
	
	self.nCurrentCostume = 0
	self:OnCostumeSet(self.nCurrentCostume)
	
	CostumesLib.SetCostumeIndex(0)
end

function Character:OnOpenCostumes()
	Event_FireGenericEvent("GenericEvent_OpenCostumes")
	self:OnClose()
end

function Character:OnThrottleEnd()
	for nIdx, wndCostumeBtn in ipairs(self.wndCostumeList:GetChildren()) do
		wndCostumeBtn:Enable(true)
	end
	self.wndCostumeListBlocker:Show(false)
	self.wndCostumeSelectionList:FindChild("ClearCostumeBtn"):Enable(self.nCurrentCostume ~= 0)

	local wndEquipBtn = self.wndCostumeSelectionList:FindChild("EquipBtn")
	local idEquipCostume = wndEquipBtn:GetData()
	wndEquipBtn:Enable(self.nCurrentCostume ~= idEquipCostume)
end

function Character:OnItemDurabilityUpdate(itemUpdated, nPreviousDurability)
	local wndUpdate = self.arSlotsWindowsByName[itemUpdated:GetSlotName()]
	wndUpdate:FindChild("DurabilityMeter"):SetProgress(itemUpdated:GetDurability())
end

function Character:OnPersonaUpdateCharacterStats()
	if self.wndCharacter:IsShown() then
		self:DrawAttributes(self.wndCharacter)
	end
end

function Character:MapEquipment()
	local unitPlayer = GameLib:GetPlayerUnit()
	if not unitPlayer then
		return
	end

	local arItems = unitPlayer:GetEquippedItems()
	self.tEquipmentMap = {}
	
	for idx = 1, #arItems do
		local eSlot = ktItemSlotToEquippedItems[arItems[idx]:GetSlot()]
		if eSlot then
			self.tEquipmentMap[eSlot] = arItems[idx]
		end
	end
end

function Character:OnCostumeSet(idCostume)
	for nIdx, wndCostumeBtn in ipairs(self.wndCostumeList:GetChildren()) do
		wndCostumeBtn:SetCheck(idCostume == wndCostumeBtn:GetData())
		wndCostumeBtn:Enable(wndCostumeBtn:GetName() == "CostumeBtnMTX")
	end
	self.wndCostumeListBlocker:Show(true)
	self.wndCostumeSelectionList:FindChild("ClearCostumeBtn"):Enable(false)
	self.wndCostumeSelectionList:FindChild("EquipBtn"):Enable(false)
end

function Character:OnClose(wndHandler, wndControl)
	if wndHandler ~= wndControl then 
		return
	end
	
	self.wndCharacter:Close()
	Event_FireGenericEvent("CharacterWindowHasBeenClosed")
	self.wndCharacter:FindChild("NameEditTitleContainer"):Show(false)
end

function Character:OnPlayerLevelChange()
	if self.wndCharacter:IsShown() and self.wndCharacterTitles:IsShown() then
		self:DrawNames(self.wndCharacter)	
	end
end

function Character:OnStatsBtn(wndHandler, wndControl)
	local wndContainer = wndControl:GetParent():GetParent() -- Dropdown contents -> CharacterEverything
	local wndCharacterStats = wndContainer:FindChild("CharacterStats")
	local wndCharacterCostumes = wndContainer:FindChild("CharacterCostumes")
	local wndCharacterBonus = wndContainer:FindChild("CharacterBonus")
	local wndDropdownContents = wndContainer:FindChild("DropdownContents")
	local wndEntitlements = wndContainer:FindChild("Entitlements")
	wndCharacterStats:Show(true)
	if wndCharacterBonus then
		wndCharacterCostumes:Show(false)
		self.wndCharacterBonus:Show(false)
		wndEntitlements:Show(false)
		self:CloseReputation()
	end
	wndContainer:FindChild("DropdownBtn"):SetText(String_GetWeaselString(Apollo.GetString("Character_Display"), Apollo.GetString("Character_Stats")))
	wndDropdownContents:Show(false)
end

function Character:OnBonusBtn(wndHandler, wndControl)
	self.wndCharacterCostumes:Show(false)
	self.wndCharacterStats:Show(false)
	self.wndEntitlements:Show(false)
	self.wndCharacterBonus:Show(true)
	Event_FireGenericEvent("UpdateRuneSets", self.wndCharacterBonus)
	self:CloseReputation()
	self.wndCharacter:FindChild("DropdownBtn"):SetText(String_GetWeaselString(Apollo.GetString("Character_Display"), Apollo.GetString("Character_SetBonuses")))
	self.wndDropdownContents:Show(false)
end

function Character:DrawAttributes(wndUpdate)
	local unitPlayer = wndUpdate and wndUpdate:GetData() or nil

	if unitPlayer == nil or not wndUpdate:IsShown() then
		return
	end

	local arCategories =
	{
		{
			strTitle		= Apollo.GetString("Character_Offensive"),
			arAttributes	=
			{
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseAvoidReduceChance),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetStrikethroughChance().nAmount, 2, true)),
					eState		= unitPlayer:GetStrikethroughChance().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_StrikethroughTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.Rating_AvoidReduce).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetStrikethroughChance().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseAvoidReduceChance).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseAvoidReduceChance).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseCritChance),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetCritChance().nAmount, 2, true)),
					eState		= unitPlayer:GetCritChance().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_CritTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.Rating_CritChanceIncrease).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetCritChance().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseCritChance).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseCritChance).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.CriticalHitSeverityMultiplier),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetCritSeverity().nAmount, 2, true)),
					eState		= unitPlayer:GetCritSeverity().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_CritSevTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingCritSeverityIncrease).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetCritSeverity().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.CriticalHitSeverityMultiplier).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.CriticalHitSeverityMultiplier).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseMultiHitChance),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetMultiHitChance().nAmount, 2, true)),
					eState		= unitPlayer:GetMultiHitChance().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_MultiHitChanceTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingMultiHitChance).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetMultiHitChance().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseMultiHitChance).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseMultiHitChance).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseMultiHitAmount),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetMultiHitAmount().nAmount, 2, true)),
					eState		= unitPlayer:GetMultiHitAmount().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_MultiHitSeverityTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingMultiHitAmount).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetMultiHitAmount().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseMultiHitAmount).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseMultiHitAmount).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseVigor),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetVigor().nAmount, 2, true)),
					eState		= unitPlayer:GetVigor().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_VigorTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingVigor).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetVigor().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseVigor).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseVigor).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.IgnoreArmorBase),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetArmorPierce().nAmount, 2, true)),
					eState		= unitPlayer:GetArmorPierce().eDRState,
					strTooltip 	=  String_GetWeaselString(Apollo.GetString("Character_ArmorPenTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingArmorPierce).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetArmorPierce().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.IgnoreArmorBase).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.IgnoreArmorBase).fValue * 100, 2, true))
				},
			},
		},
		{
			strTitle		= Apollo.GetString("Character_Defensive"),
			arAttributes 	=
			{
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.DamageMitigationPctOffsetPhysical),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetPhysicalMitigation().nAmount, 2, true)),
					eState		= unitPlayer:GetPhysicalMitigation().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_PhysMitTooltip"), Apollo.FormatNumber(unitPlayer:GetPhysicalMitigationRating() + unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.Armor).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetPhysicalMitigation().nAmount - ((unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.DamageMitigationPctOffsetPhysical).fValue + unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.DamageMitigationPctOffset).fValue) * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.ResistPhysical).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.Armor).fValue, 2, true), Apollo.FormatNumber((unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.DamageMitigationPctOffsetPhysical).fValue + unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.DamageMitigationPctOffset).fValue) * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.DamageMitigationPctOffsetTech),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetTechMitigation().nAmount, 2, true)),
					eState		= unitPlayer:GetTechMitigation().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_TechMitTooltip"), Apollo.FormatNumber(unitPlayer:GetTechMitigationRating() + unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.Armor).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetTechMitigation().nAmount - ((unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.DamageMitigationPctOffsetTech).fValue + unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.DamageMitigationPctOffset).fValue) * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.ResistTech).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.Armor).fValue, 2, true), Apollo.FormatNumber((unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.DamageMitigationPctOffsetTech).fValue + unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.DamageMitigationPctOffset).fValue) * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.DamageMitigationPctOffsetMagic),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetMagicMitigation().nAmount, 2, true)),
					eState		= unitPlayer:GetMagicMitigation().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_MagicMitTooltip"), Apollo.FormatNumber(unitPlayer:GetMagicMitigationRating() + unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.Armor).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetMagicMitigation().nAmount - ((unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.DamageMitigationPctOffsetMagic).fValue + unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.DamageMitigationPctOffset).fValue) * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.ResistMagic).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.Armor).fValue, 2, true), Apollo.FormatNumber((unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.DamageMitigationPctOffsetMagic).fValue + unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.DamageMitigationPctOffset).fValue) * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseGlanceAmount),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetGlanceAmount().nAmount, 2, true)),
					eState		= unitPlayer:GetGlanceAmount().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_GlanceSeverityTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingGlanceAmount).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetGlanceAmount().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseGlanceAmount).fValue  * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseGlanceAmount).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseGlanceChance),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetGlanceChance().nAmount, 2, true)),
					eState		= unitPlayer:GetGlanceChance().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_GlanceChanceTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingGlanceChance).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetGlanceChance().nAmount -(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseGlanceChance).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseGlanceChance).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseCriticalMitigation),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetCriticalMitigation().nAmount, 2, true)),
					eState		= unitPlayer:GetCriticalMitigation().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_CritMitigationTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingCriticalMitigation).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetCriticalMitigation().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseCriticalMitigation).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseCriticalMitigation).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseAvoidChance),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetDeflectChance().nAmount, 2, true)),
					eState		= unitPlayer:GetDeflectChance().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_DeflectTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.Rating_AvoidIncrease).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetDeflectChance().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseAvoidChance).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseAvoidChance).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseAvoidCritChance),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetDeflectCritChance().nAmount, 2, true)),
					eState		= unitPlayer:GetDeflectCritChance().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_CritDeflectTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.Rating_CritChanceDecrease).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetDeflectCritChance().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseAvoidCritChance).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseAvoidCritChance).fValue * 100, 2, true))
				},
			},
		},
		{
			strTitle		= Apollo.GetString("Character_Life"),
			arAttributes 	=
			{
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.ShieldMitigationMax),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetShieldMitigationPct(), 2, true)),
					strTooltip 	= Apollo.GetString("Character_ShieldMitigation_Tooltip")      
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.ShieldRegenPct),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetShieldRegenPct(), 2, true)),
					strTooltip 	= Apollo.GetString("Character_ShieldRegenPercentTooltip")
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.ShieldRebootTime),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_SecondsLabel"), Apollo.FormatNumber(unitPlayer:GetShieldRebootTime(), 2, true)),
					strTooltip 	= Apollo.GetString("Character_ShieldRebootTooltip")
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.ShieldTickTime),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_SecondsLabel"), Apollo.FormatNumber(unitPlayer:GetShieldTickTime(), 2, true)),
					strTooltip 	= Apollo.GetString("Character_ShieldTickTime_Tooltip")      
				}
			},
		},
		{
			strTitle		= Apollo.GetString("Character_Utility"),
			arAttributes 	=
			{
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.CooldownReductionModifier),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetCooldownReductionModifier(), 2, true)),
					strTooltip 	= Apollo.GetString("Character_HasteTooltip")
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.CCDurationModifier),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetCCDurationModifier().nAmount, 2, true)),
					eState		= unitPlayer:GetCCDurationModifier().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_CCDurationTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingCCResilience).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetCCDurationModifier().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.CCDurationModifier).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.CCDurationModifier).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseLifesteal),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetLifesteal().nAmount, 2, true)),
					eState		= unitPlayer:GetLifesteal().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_LifestealTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingLifesteal).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetLifesteal().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseLifesteal).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseLifesteal).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseFocusPool),
					strValue 	= Apollo.FormatNumber(unitPlayer:GetMaxFocus(), 0, true),
					strTooltip 	= Apollo.GetString("Character_FocusPool")
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseFocusRecoveryInCombat),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetFocusRegenInCombat().nAmount, 2, true)),
					eState		= unitPlayer:GetFocusRegenInCombat().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_ManaRecoveryTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingFocusRecovery).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetFocusRegenInCombat().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseFocusRecoveryInCombat).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseFocusRecoveryInCombat).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.FocusCostModifier),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.FocusCostModifier).fValue * 100, 2, true)),
					strTooltip 	= Apollo.GetString("Character_ManaCostRedTooltip")
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseDamageReflectChance),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetDamageReflectChance().nAmount, 2, true)),
					eState		= unitPlayer:GetDamageReflectChance().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_ReflectChanceTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingDamageReflectChance).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetDamageReflectChance().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseDamageReflectChance).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseDamageReflectChance).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseDamageReflectAmount),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetDamageReflectAmount().nAmount, 2, true)),
					eState		= unitPlayer:GetDamageReflectAmount().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_ReflectSeverityTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingDamageReflectAmount).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetDamageReflectAmount().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseDamageReflectAmount).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseDamageReflectAmount).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.BaseIntensity),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetIntensity().nAmount, 2, true)),
					eState		= unitPlayer:GetIntensity().eDRState,
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_IntensityTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.RatingIntensity).fValue, 2, true), Apollo.FormatNumber(unitPlayer:GetIntensity().nAmount - (unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseIntensity).fValue * 100), 2, true), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.BaseIntensity).fValue * 100, 2, true))
				},
			},
		},
		{
			
			strTitle		= Apollo.GetString("Character_PvP"),
			arAttributes 	= 
			{
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.PvPOffensePctOffset),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetPvPDamageI(), 2, true)),
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_PvPOffenseTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.PvPOffensiveRating).fValue, 2, true),
								  Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.PvPOffensePctOffset).fValue * 100, 2, true), Apollo.FormatNumber(unitPlayer:GetPvPDamageO(), 2, true), Apollo.FormatNumber(unitPlayer:GetPvPDamageI() - unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.PvPOffensePctOffset).fValue * 100, 2, true))
				},
				{	-- GOTCHA: Healing actually uses PvPOffenseRating, which is called PvP Power to the player
					strName 	= Apollo.GetString("Character_PvPHealLabel"),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetPvPHealingI(), 2, true)),
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_PvPHealingTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.PvPOffensiveRating).fValue, 2, true),
								  Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.PvPOffensePctOffset).fValue * 100, 2, true), Apollo.FormatNumber(unitPlayer:GetPvPHealingO(), 2, true), Apollo.FormatNumber(unitPlayer:GetPvPHealingI() - unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.PvPOffensePctOffset).fValue * 100, 2, true))
				},
				{
					strName 	= Item.GetPropertyName(Unit.CodeEnumProperties.PvPDefensePctOffset),
					strValue 	= String_GetWeaselString(Apollo.GetString("Character_PercentAppendLabel"), Apollo.FormatNumber(unitPlayer:GetPvPDefenseI(), 2, true)),
					strTooltip 	= String_GetWeaselString(Apollo.GetString("Character_PvPDefenseTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.PvPDefensiveRating).fValue, 2, true),
								  Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.PvPDefensePctOffset).fValue * 100, 2, true), Apollo.FormatNumber(unitPlayer:GetPvPDefenseO(), 2, true), Apollo.FormatNumber(unitPlayer:GetPvPDefenseI() - unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.PvPDefensePctOffset).fValue * 100, 2, true))
				}
			},
		}
	}

	local wndParent = wndUpdate:FindChild("CharacterStats")
	for idx, tCur in pairs (arCategories) do
		local wndItemContainer = wndParent:FindChild("AttributeContainer"..idx)
		local wndItemHolder = nil
		if wndItemContainer == nil then
			wndItemContainer = Apollo.LoadForm(self.xmlDoc, "AttributeContainer", wndParent, self)
			wndItemContainer:SetName("AttributeContainer"..idx)
			wndItemHolder = Apollo.LoadForm(self.xmlDoc, "AttributeContHolder", wndItemContainer , self)
		else
			wndItemHolder = wndItemContainer:FindChild("AttributeContHolder")
		end
		local wndAttributeExpanderBtn = wndItemContainer:FindChild("AttributeExpanderBtn")
		local nContainerLeft, nContainerTop, nContainerRight, nContainerBottom = wndItemHolder:GetOriginalLocation():GetOffsets()
		local nExpandBtnHeight = wndAttributeExpanderBtn:GetHeight()
		wndAttributeExpanderBtn:SetCheck(true)

		wndAttributeExpanderBtn:SetText(tCur.strTitle)
		
		local strIcon = ""
		for idxInner, tCurInner in pairs (tCur.arAttributes) do
			wndItemHolder:SetData(idxInner)
			self:StatsDrawHelper(wndItemHolder, tCurInner.strName, tCurInner.strValue, strIcon, "UI_TextHoloBody", tCurInner.eState, tCurInner.strTooltip)
		end

		local nNewBottom = wndItemHolder:ArrangeChildrenVert()
		wndItemHolder:SetAnchorOffsets(nContainerLeft, nContainerTop + nExpandBtnHeight, nContainerRight, nNewBottom + nExpandBtnHeight )
		wndItemContainer:SetAnchorOffsets(nContainerLeft, nContainerTop, nContainerRight, nNewBottom + knAttributeContainerPadding + nExpandBtnHeight)
	end
	wndParent:ArrangeChildrenVert()

	---------- Durability ------------
	for iSlot, wndSlot in pairs(self.arSlotsWindowsByName) do
		wndSlot:FindChild("DurabilityMeter"):SetProgress(0)
		wndSlot:FindChild("DurabilityBlocker"):Show(false)
		if wndSlot:FindChild("DurabilityAlert") then
			wndSlot:FindChild("DurabilityAlert"):Show(false)
		end
	end

	if unitPlayer ~= nil then
		local tItems = unitPlayer:GetEquippedItems()
		if unitPlayer ~= GameLib.GetPlayerUnit() then
			tItems = self.arInspectItems
		end

		local wndVisibleSlots = wndUpdate:FindChild("VisibleSlots")

		for idx, itemCurr in ipairs(tItems) do
			local wndSlot = nil
			for iSlot, wndValue in pairs(self.arSlotsWindowsByName) do
				if itemCurr:GetSlotName() == iSlot then
					wndSlot = wndValue
				end
			end

			if wndSlot ~= nil then
				local wndDurabilityBlocker = wndSlot:FindChild("DurabilityBlocker")
				if wndDurabilityBlocker ~= nil then
					local wndDurabilityMeter = wndSlot:FindChild("DurabilityMeter")
					local nDurabilityMax = itemCurr:GetMaxDurability()
					local nDurabilityCurrent = itemCurr:GetDurability()
					local nDurabilityRation = (nDurabilityCurrent / nDurabilityMax)
					local bHasDurability = nDurabilityMax > 0
	
					local bShowDurabilityBlocker = not bHasDurability
					wndDurabilityMeter:Show(bHasDurability)
					wndDurabilityMeter:SetMax(nDurabilityMax)
					wndDurabilityMeter:SetProgress(nDurabilityCurrent)
					if itemCurr:GetItemFamily() == Item.CodeEnumItem2Family.Costume then
						bShowDurabilityBlocker = false
					else
					if nDurabilityRation <= .100 then
						wndDurabilityMeter:SetBarColor("ffaf1212")
						local wndDurabilityAlert = wndSlot:FindChild("DurabilityAlert")
						if wndDurabilityAlert then
							wndDurabilityAlert:Show(true)
						end
					elseif nDurabilityRation <= .250 then
						wndDurabilityMeter:SetBarColor("ffffba00")
					elseif nDurabilityRation <= .500 then
						wndDurabilityMeter:SetBarColor("ffd7d017")
					else 
						wndDurabilityMeter:SetBarColor("ff129faf")
					end
				end
					wndDurabilityBlocker:Show(bShowDurabilityBlocker)
				end
			end
		end
		
		local wndPermAttFrame = wndUpdate:FindChild("PermAttributeFrame")
		wndPermAttFrame:SetData(unitPlayer)
		self:UpdateAttributes(wndPermAttFrame)
	end
end

function Character:OnToggleAttribute(wndHandler, wndControl)
	local wndParent = wndControl:GetParent()
	local wndAttributeContHolder = wndParent:FindChild("AttributeContHolder")
	local nLeft, nTop, nRight, nBottom = wndParent:GetOriginalLocation():GetOffsets()
	if wndControl:IsChecked() then
		wndAttributeContHolder:Show(true)
		nBottom = nBottom + wndAttributeContHolder:GetHeight()
	else
		wndAttributeContHolder:Show(false)
	end
	wndParent:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + (knAttributeContainerPadding / 2))
	wndParent:GetParent():ArrangeChildrenVert()
end

function Character:UpdateAttributes(wndUpdate)
	local unitPlayer = wndUpdate:GetData()
	local wndAssaultPowerRating = wndUpdate:FindChild("AssaultPowerRating")
	local wndAssaultPowerRatingIcon = wndUpdate:FindChild("icoAssaultPower")
	local wndDefensePowerRating = wndUpdate:FindChild("SupportPowerRating")
	local wndDefensePowerRatingIcon = wndUpdate:FindChild("icoDefensePower")
	local wndMaxHealth = wndUpdate:FindChild("MaxHealth")
	local wndMaxShields = wndUpdate:FindChild("MaxShields")
	local wndCurScore = wndUpdate:FindChild("CurrentScore")

	wndAssaultPowerRating:SetText(Apollo.FormatNumber(unitPlayer:GetAssaultPower(), 0, true))
	wndDefensePowerRating:SetText(Apollo.FormatNumber(unitPlayer:GetSupportPower(), 0, true))
	wndMaxHealth:SetText(Apollo.FormatNumber(unitPlayer:GetMaxHealth(), 0, true))
	wndMaxShields:SetText(Apollo.FormatNumber(unitPlayer:GetShieldCapacityMax(), 0, true))
	wndCurScore:SetText(Apollo.FormatNumber(unitPlayer and unitPlayer:GetEffectiveItemLevel() or 0, 0, true))
	wndAssaultPowerRatingIcon:SetTooltip(String_GetWeaselString(Apollo.GetString("Character_AssaultTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.AssaultRating).fValue, 2, true)))
	wndDefensePowerRatingIcon:SetTooltip(String_GetWeaselString(Apollo.GetString("Character_SupportTooltip"), Apollo.FormatNumber(unitPlayer:GetUnitProperty(Unit.CodeEnumProperties.SupportRating).fValue, 2, true)))
end

function Character:StatsDrawHelper(wndContainer, strName, strValue, strIcon, crTextColor, eState, strTooltip)
	local nIndex = wndContainer:GetData()
	local wndItem = wndContainer:FindChild("AttributeItem"..nIndex)
	if wndItem == nil then
		wndItem = Apollo.LoadForm(self.xmlDoc, "AttributeItem", wndContainer, self)
		wndItem:SetName("AttributeItem"..nIndex)
	end
	wndItem:FindChild("StatLabel"):SetAML(string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", crTextColor, strName))
	local crTextValueColor = "UI_TextHoloBodyCyan"
	if eState then
		if eState == Unit.CodeEnumDiminishingReturnState.SoftCap then
			crTextValueColor = "UI_WindowYellow"
		elseif eState == Unit.CodeEnumDiminishingReturnState.HardCap then
			crTextValueColor = "UI_WindowTextRed"
		end
	end
	wndItem:FindChild("StatValue"):SetAML(string.format("<T Font=\"CRB_Header9\" TextColor=\"%s\">%s</T>", crTextValueColor, strValue))
	wndItem:SetTooltip(strTooltip)
	local bBackgroundColor = nIndex % 2 == 1
	if bBackgroundColor then
		local wndBackground = wndItem:FindChild("Background")
		wndBackground:Show(true)
	end
	
	local wndParent = wndContainer:GetParent()
	local wndAttributeExpanderBtn = wndParent:FindChild("AttributeExpanderBtn")
	self:OnToggleAttribute(wndAttributeExpanderBtn, wndAttributeExpanderBtn)
end

function Character:OnAttributeIconMouseExit(wndHandler, wndControl)
	if self.wndAttributeTooltip and self.wndAttributeTooltip:IsValid() then
		self.wndAttributeTooltip:Destroy()
		self.wndAttributeTooltip = nil
	end
end

function Character:OnGenerateTooltip(wndHandler, wndControl, eType, itemCurr, idx)
	if eType ~= Tooltip.TooltipGenerateType_ItemInstance then
		return
	end

	if itemCurr then
		Tooltip.GetItemTooltipForm(self, wndControl, itemCurr, {bPrimary = true, bSelling = self.bVendorOpen, itemCompare = false})
	else
		wndControl:SetTooltip(wndControl:GetName() and ("<P Font=\"CRB_InterfaceSmall_O\">" .. ktSlotWindowNameToTooltip[wndControl:GetName()] .. "</P>") or "")
	end
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------

function Character:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors = 
	{
		[GameLib.CodeEnumTutorialAnchor.Character] 	= true,
	}
	
	if not tAnchors[eAnchor] then 
		return
	end
	
	local tAnchorMapping = 
	{
		[GameLib.CodeEnumTutorialAnchor.Character] 	= self.wndCharacter,
	}
	
	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

-----------------------------------------------------------------------------------------------
-- Name Editing
-----------------------------------------------------------------------------------------------

function Character:OnGuildHolomarkToggle(wndHandler, wndControl, eMouseButton)
	local bVisibleLeft = self.wndCharacter:FindChild("GuildHolomarkLeftBtn"):IsChecked()
	local bVisibleRight = self.wndCharacter:FindChild("GuildHolomarkRightBtn"):IsChecked()
	local bVisibleBack = self.wndCharacter:FindChild("GuildHolomarkBackBtn"):IsChecked()
	local bDisplayNear = self.wndCharacter:FindChild("NameEditGuildHolomarkContainer"):GetRadioSel("GuildHolomarkDistance") == 1
	GameLib.ShowGuildHolomark(bVisibleLeft, bVisibleRight, bVisibleBack, bDisplayNear)
end

function Character:OnTitleSelected(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.wndSelectedTitle = wndHandler

	if wndHandler:IsChecked() then
		local ttlSelected = wndHandler:GetData()
		if CharacterTitle.CanUseTitle(ttlSelected) then
			CharacterTitle.SetTitle(ttlSelected)
			self.strTitle = ttlSelected:GetTitle()
		end
	else
		CharacterTitle.SetTitle(nil)
		self.strTitle = ""
	end

	self:OnDrawEditNamePopout()
	self.timerTitleChange:Start()
	self.wndCharacter:FindChild("CharacterTitleContainer"):Close()
end

function Character:OnPickGuildTag(wndHandler, wndControl) -- GuildTagBtn
	wndHandler:GetData():SetAsNameplate()
	self.wndCharacter:FindChild("NameEditGuildTagContainer"):Close()

	self:OnDrawEditNamePopout()
	self.wndCharacter:FindChild("ClassTitleGuild"):SetText(wndHandler:GetText())
	self.timerTitleChange:Start()
end

function Character:OpenEntitlements(wndHandler, wndControl)
	local wndContainer = wndControl:GetParent():GetParent() -- Dropdown contents -> CharacterEverything
	local wndDropdownContents = wndContainer:FindChild("DropdownContents")
	self.wndCharacterEverything:Show(true)
	self.wndCharacterStats:Show(false)
	self.wndCharacterCostumes:Show(false)
	self.wndCharacterBonus:Show(false)
	self.wndCharacterReputation:Show(false)
	self.wndEntitlements:Show(true)
	self:RefreshEntitlements()
	wndContainer:FindChild("DropdownBtn"):SetText(String_GetWeaselString(Apollo.GetString("Character_Display"), Apollo.GetString("AccountInv_Entitlements")))
	wndDropdownContents:Show(false)
end

function Character:OnCostumesBtn(wndHandler, wndControl)
	local wndContainer = wndControl:GetParent():GetParent() -- Dropdown contents -> CharacterEverything
	local wndCharacterStats = wndContainer:FindChild("CharacterStats")
	local wndCharacterCostumes = wndContainer:FindChild("CharacterCostumes")
	local wndCharacterBonus = wndContainer:FindChild("CharacterBonus")
	local wndDropdownContents = wndContainer:FindChild("DropdownContents")
	local wndEntitlements = wndContainer:FindChild("Entitlements")
	self.wndCostumeSelectionList:Show(true)
	wndCharacterStats:Show(false)
	wndCharacterCostumes:Show(true)
	if wndCharacterBonus ~= nil then
		wndEntitlements:Show(false)
		self.wndCharacterBonus:Show(false)
		self:CloseReputation()
	end
	wndContainer:FindChild("DropdownBtn"):SetText(String_GetWeaselString(Apollo.GetString("Character_Display"), Apollo.GetString("Character_Costumes")))
	wndDropdownContents:Show(false)
end

function Character:OnEffectiveLevelChange()
	self.timerDelayedUpdate = ApolloTimer.Create(0.01, false, "DrawNames", self)
end

function Character:DrawNames(wndUpdate)
	if not wndUpdate or not Window.is(wndUpdate) then
		wndUpdate = self.wndCharacter
	end

	local unitPlayer = wndUpdate:GetData()

	if not unitPlayer or not wndUpdate:IsShown() then
		return
	end

	local tStats = unitPlayer:GetBasicStats()
	local strGuildName = unitPlayer:GetGuildName() or ""
	local strTitleName = unitPlayer:GetTitleOrName() or ""

	if not self.strTitle and unitPlayer == GameLib.GetPlayerUnit() then
		if unitPlayer == GameLib.GetPlayerUnit() then
			self.strTitle = ""
			local tTitles = CharacterTitle.GetAvailableTitles()
			table.sort(tTitles, function(a,b) return a:GetCategory() < b:GetCategory() end)
			for idx, titleCurr in pairs(tTitles) do
				if CharacterTitle.IsActiveTitle(titleCurr) then
					self.strTitle = titleCurr:GetTitle()
				end
			end
		end
	end

	-- Special coloring if mentored
	local nDisplayedLevel = 0
	local strEffectiveLevelStatus
	local wndAlert = wndUpdate:FindChild("Alert")
	if tStats then
		if not tStats.nEffectiveLevel or tStats.nEffectiveLevel == 0 or tStats.nEffectiveLevel == tStats.nLevel then
			nDisplayedLevel = tStats.nLevel
		else
			local bMentoring = unitPlayer:IsMentoring()

			nDisplayedLevel = tStats.nEffectiveLevel
			strEffectiveLevelStatus = bMentoring and Apollo.GetString("CRB_Mentoring") or Apollo.GetString("MiniMap_Rallied")
		end

		wndUpdate:FindChild("CharDataLevelBig"):SetText(nDisplayedLevel)

		wndAlert:Show(strEffectiveLevelStatus)

		if wndAlert:IsShown() then
			wndAlert:SetTooltip(strEffectiveLevelStatus)
		end

		local wndPlayerName = wndUpdate:FindChild("BGArt_OverallFrame:PlayerName")
		wndPlayerName:SetText(strTitleName)

		if wndUpdate:FindChild("ClassTitleGuild") then
			wndUpdate:FindChild("ClassTitleGuild"):SetText((Apollo.StringLength(strGuildName) > 0) and strGuildName or "")
		end

		if wndUpdate:FindChild("InspectAffiliation") and unitPlayer:GetGuildType() and kstrInspectAffiliation[unitPlayer:GetGuildType()] then
			local strCombined = String_GetWeaselString(kstrInspectAffiliation[unitPlayer:GetGuildType()], strGuildName)
			wndUpdate:FindChild("InspectAffiliation"):SetText((Apollo.StringLength(strGuildName) > 0) and strCombined or "")
		end
	end

	local eFaction = unitPlayer:GetBaseFaction()
	local eGender = unitPlayer:GetGender()
	local eClass = unitPlayer:GetClassId()
	local ePath = unitPlayer:GetPlayerPathType()
	local eRace = unitPlayer:GetRaceId()
	
	wndUpdate:FindChild("CharDataClassIcon"):SetTooltip(karClassToString[eClass] or "")
	wndUpdate:FindChild("CharDataClassIcon"):SetSprite(karClassToIcon[eClass] or "")
	wndUpdate:FindChild("CharDataPathIcon"):SetTooltip(ktPathToString[ePath] or "")
	wndUpdate:FindChild("CharDataPathIcon"):SetSprite(ktPathToIcon[ePath] or "")
	wndUpdate:FindChild("CharTitlePath"):SetText(String_GetWeaselString(Apollo.GetString("Character_PathLevel"), PlayerPathLib.GetPathLevel()))
	wndUpdate:FindChild("CharDataRaceIcon"):SetTooltip(karRaceToString[eRace] or "")
	wndUpdate:FindChild("CharDataRaceIcon"):SetSprite(ktRaceToIcon[eFaction][eGender][eRace] or "")
	wndUpdate:FindChild("CharDataFactionIcon"):SetTooltip(karFactionToString[eFaction] or "")
	wndUpdate:FindChild("CharDataFactionIcon"):SetSprite(karFactionToIcon[eFaction] or "")
end

function Character:OnGuildChange()
	self:OnDrawEditNamePopout()
end

function Character:OnDrawEditNamePopout()
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer then
		return
	end
	
	local strLastCat = nil
	local wndEnsureVisible = nil
	local tTitles = CharacterTitle.GetAvailableTitles()
	local strTitleName = unitPlayer:GetTitle() or ""
	table.sort(tTitles, function(a,b) return a:GetCategory() < b:GetCategory() end)

	self.wndCharacterTitles:FindChild("NameEditClearTitleBtn"):Enable(#tTitles > 0 and strTitleName ~= "")
	self.wndCharacterTitles:FindChild("NameEditTitleList"):DestroyChildren()
	for idx, titleCurr in pairs(tTitles) do
		local strCategory = titleCurr:GetCategory()
		if strCategory ~= strLastCat then
			local wndHeader = Apollo.LoadForm(self.xmlDoc, "NameEditTitleCategory", self.wndCharacterTitles:FindChild("NameEditTitleList"), self)
			wndHeader:FindChild("TitleCategoryText"):SetText(strCategory)
			strLastCat = strCategory
		end

		local wndTitle = Apollo.LoadForm(self.xmlDoc, "NameEditTitleButton", self.wndCharacterTitles:FindChild("NameEditTitleList"), self)
		wndTitle:SetText(titleCurr:GetTitle())
		wndTitle:SetData(titleCurr)

		if not CharacterTitle.CanUseTitle(titleCurr) then
			wndTitle:Enable(false)
		end

		if CharacterTitle.IsActiveTitle(titleCurr) then
			wndEnsureVisible = wndTitle
			wndTitle:SetCheck(true)
			self.wndSelectedTitle = wndTitle
			self.wndCharacter:FindChild("CharacterTitleDropdown"):SetText(titleCurr:GetTitle())
		end
	end

	self.wndCharacterTitles:FindChild("NameEditTitleList"):ArrangeChildrenVert()
	self.wndCharacterTitles:FindChild("NameEditTitleList"):EnsureChildVisible(wndEnsureVisible)

	-- Guild Tags
	local bInAGuild = false
	local bInATeam = false
	local strGuildNameCompare = unitPlayer:GetGuildName() or ""
	self.wndCharacter:FindChild("NameEditGuildTagList"):DestroyChildren()
	local guildSelected
	for idx, guildCurr in pairs(GuildLib.GetGuilds()) do
		local strGuildName = guildCurr:GetName()
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "GuildTagBtn", self.wndCharacter:FindChild("NameEditGuildTagList"), self)
		wndCurr:Enable(true)
		wndCurr:SetData(guildCurr)
		wndCurr:SetCheck(strGuildName == strGuildNameCompare)
		if strGuildName == strGuildNameCompare then
			guildSelected = guildCurr
		end

		wndCurr:SetText(strGuildName)

		if guildCurr:GetType() == GuildLib.GuildType_Guild then
			bInAGuild = true
		end

		bInATeam = true
	end

	self.wndCharacter:FindChild("NameEditGuildTagList"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.wndCharacter:FindChild("FrameGuild"):Show(bInAGuild or bInATeam)
	self.wndCharacter:FindChild("NameEditGuildHolomarkContainer"):Show(bInAGuild and guildSelected and guildSelected:GetType() == GuildLib.GuildType_Guild)
	local nHeight = self.wndCharacter:FindChild("ArrangedWindows"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nLeftOrig, nTopOrig, nRightOrig, nBottomOrig = self.wndCharacter:FindChild("NameEditTitleContainer"):GetOriginalLocation():GetOffsets()
	self.wndCharacter:FindChild("NameEditTitleContainer"):SetAnchorOffsets(nLeftOrig, nTopOrig, nRightOrig, nTopOrig + nHeight)

	self:UpdateGuildHolomarks()
	self:DrawNames(self.wndCharacter)
end

function Character:OnRotateRight(wndHandler, wndControl)
	local wndCostume = wndHandler:GetParent():FindChild("Costume")
	wndCostume:ToggleLeftSpin(true)
end

function Character:OnRotateRightCancel(wndHandler, wndControl)
	local wndCostume = wndHandler:GetParent():FindChild("Costume")
	wndCostume:ToggleLeftSpin(false)
end

function Character:OnRotateLeft(wndHandler, wndControl)
	local wndCostume = wndHandler:GetParent():FindChild("Costume")
	wndCostume:ToggleRightSpin(true)
end

function Character:OnRotateLeftCancel(wndHandler, wndControl)
	local wndCostume = wndHandler:GetParent():FindChild("Costume")
	wndCostume:ToggleRightSpin(false)
end

function Character:OnSheatheCheck(wndHandler, wndControl)
	local wndCostume = wndHandler:GetParent():FindChild("Costume")
	wndCostume:SetSheathed(wndControl:IsChecked())
end

function Character:OnLevelUpUnlock_Character_Generic(nExtraData, eValue)
	self:ShowCharacterWindow()
	if eValue and eValue == GameLib.LevelUpUnlockType.Path_Title then
		self:OnTitlesBtn(nil, self.wndDropdownContents)
	end
end

---------------------------------------------------------------------------------------------------
-- SoulbindConfirm Functions
---------------------------------------------------------------------------------------------------

function Character:OnItemConfirmSoulboundOnEquip(eEquipmentSlot, nItemEquip, nItemDestination)
	self:ShowEquipConfirmation(Apollo.GetString("Character_SoulbindConfirmText"), nItemEquip, nItemDestination)
end

function Character:OnItemConfirmClearRestockOnEquip(eEquipmentSlot, nItemEquip, nItemDestination)
	self:ShowEquipConfirmation(Apollo.GetString("Character_SoulbindConfirmText_NoRefund"), nItemEquip, nItemDestination)
end

function Character:ShowEquipConfirmation(strConfirmText, nItemEquip, nItemDestination)
	self.wndBindConfirm:FindChild("ConfirmText"):SetText(strConfirmText)
	self.wndBindConfirm:FindChild("ConfirmBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.EquipItem, nItemEquip, nItemDestination)
	self.wndBindConfirm:Invoke()
end

function Character:OnBindConfirm()
	self.wndBindConfirm:Close()
end

function Character:OnCancelBindBtn( wndHandler, wndControl, eMouseButton )
	self.wndBindConfirm:Close()
end

---------------------------------------------------------------------------------------------------
-- Inspect Functions
---------------------------------------------------------------------------------------------------

function Character:OnInspect(unitTarget, arItems)
	if unitTarget == GameLib.GetPlayerUnit() or unitTarget:GetDispositionTo(GameLib.GetPlayerUnit()) ~= Unit.CodeEnumDisposition.Friendly then
		return
	end

	self:OnInspectClose()

	if not self.wndInspect then
		self.wndInspect = Apollo.LoadForm(self.xmlDoc, "InspectWindow", nil, self)
		local wndCharacterEverything	= self.wndInspect:FindChild("CharacterEverything")
	end
	self.wndInspect:SetData(unitTarget)

	self.arInspectItems = arItems

	local wndVisibleSlots = self.wndInspect:FindChild("Left:VisibleSlots")
	local wndSlotInset = self.wndInspect:FindChild("Left:SlotInset")

	local arSlotsWindowsById = -- each one has the slot name and then the corresponding UI window
	{
		[GameLib.CodeEnumEquippedItems.Head] 				= wndVisibleSlots:FindChild("HeadSlot"), -- TODO: No enum to compare to code
		[GameLib.CodeEnumEquippedItems.Shoulder] 			= wndVisibleSlots:FindChild("ShoulderSlot"),
		[GameLib.CodeEnumEquippedItems.Chest] 				= wndVisibleSlots:FindChild("ChestSlot"),
		[GameLib.CodeEnumEquippedItems.Hands] 				= wndVisibleSlots:FindChild("HandsSlot"),
		[GameLib.CodeEnumEquippedItems.Legs] 				= wndVisibleSlots:FindChild("LegsSlot"),
		[GameLib.CodeEnumEquippedItems.Feet] 				= wndVisibleSlots:FindChild("FeetSlot"),
		[GameLib.CodeEnumEquippedItems.WeaponPrimary] 		= wndVisibleSlots:FindChild("WeaponSlot"),
		[GameLib.CodeEnumEquippedItems.Shields]				= wndVisibleSlots:FindChild("ShieldSlot"),
		[GameLib.CodeEnumEquippedItems.WeaponTool]			= wndSlotInset:FindChild("ToolSlot"),
		[GameLib.CodeEnumEquippedItems.WeaponAttachment]	= wndSlotInset:FindChild("WeaponAttachmentSlot"),
		[GameLib.CodeEnumEquippedItems.System]				= wndSlotInset:FindChild("SupportSystemSlot"),
		[GameLib.CodeEnumEquippedItems.Gadget]				= wndSlotInset:FindChild("GadgetSlot"),
		[GameLib.CodeEnumEquippedItems.Augment]				= wndSlotInset:FindChild("AugmentSlot"),
		[GameLib.CodeEnumEquippedItems.Implant]				= wndSlotInset:FindChild("ImplantSlot"),
	}

	for idx, itemInspected in pairs(arItems) do
		local wndItemSlot = arSlotsWindowsById[itemInspected:GetSlot()]
		if wndItemSlot then
			wndItemSlot:GetWindowSubclass():SetItem(itemInspected)
			wndItemSlot:SetData(itemInspected)
		end
	end

	self:DrawAttributes(self.wndInspect)
	self:DrawNames(self.wndInspect)

	local wndInspectCostume = self.wndInspect:FindChild("CharFrame_BGArt:Costume")
	wndInspectCostume:SetCostume(unitTarget)
	wndInspectCostume:SetSheathed(self.wndInspect:FindChild("SetSheatheBtn"):IsChecked())

	Sound.Play(Sound.PlayUI68OpenPanelFromKeystrokeVirtual)

	self.wndInspect:Invoke()
end

function Character:OnGenerateInspectTooltip(wndHandler, wndControl)
	local itemSource = wndHandler:GetData()
	local strWindowName = wndHandler:GetName()
	
	if itemSource then
		Tooltip.GetItemTooltipForm(self, wndControl, itemSource, {bPrimary = true, bSelling = false, itemCompare = false})
	elseif strWindowName and ktSlotWindowNameToTooltip[strWindowName] then
		wndControl:SetTooltip(strWindowName and ("<P Font=\"CRB_InterfaceSmall_O\">" .. ktSlotWindowNameToTooltip[strWindowName] .. "</P>") or "")
	end
end

function Character:OnInspectClose()
	if self.wndInspect then
		self.wndInspect:Destroy()
	end

	self.wndInspect = nil
end

local CharacterInstance = Character:new()
CharacterInstance:Init()
