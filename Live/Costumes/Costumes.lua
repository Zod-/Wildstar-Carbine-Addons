-----------------------------------------------------------------------------------------------
-- Client Lua Script for Costumes
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Apollo"
require "GameLib"
require "CostumesLib"
require "HousingLib"
require "Item"
require "Costume"
require "StorefrontLib"

local Costumes = {}

local knCostumeBtnHolderBuffer = 45
local knDisplayedItemCount = 8
local knResetDyeId = 0
local knEmptySlotId = -1
local knEquipmentCostumeIndex = 0
local knStaticAnimationValue = 5612

local kstrDyeSpriteBase = "CRB_DyeRampSprites:sprDyeRamp_"

local knXCursorOffset = 10
local knYCursorOffset = 25

local ktManneqinIds =
{
	[Unit.CodeEnumGender.Male] = 47305,
	[Unit.CodeEnumGender.Female] = 56135,
}

local knWeaponModelId = 70573

local keOverlayType =
{
	["None"] = 0,
	["UndoClose"] = 1,
	["UndoSwap"] = 2,
	["RemoveItem"] = 3,
	["Error"] = 4,
	["ServiceToken"] = 5,
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

local ktSlotToString =
{
	[GameLib.CodeEnumItemSlots.Weapon] 		= "CRB_Weapon",
	[GameLib.CodeEnumItemSlots.Head] 		= "InventorySlot_Head",
	[GameLib.CodeEnumItemSlots.Shoulder] 	= "InventorySlot_Shoulder",
	[GameLib.CodeEnumItemSlots.Chest] 		= "InventorySlot_Chest",
	[GameLib.CodeEnumItemSlots.Hands] 		= "InventorySlot_Hands",
	[GameLib.CodeEnumItemSlots.Legs] 		= "InventorySlot_Legs",
	[GameLib.CodeEnumItemSlots.Feet] 		= "InventorySlot_Feet",
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

local ktItemSlotToCamera =
{
	[GameLib.CodeEnumItemSlots.Chest] 		= "Armor_Chest",
	[GameLib.CodeEnumItemSlots.Legs] 		= "Armor_Pants",
	[GameLib.CodeEnumItemSlots.Head] 		= "Armor_Head",
	[GameLib.CodeEnumItemSlots.Shoulder] 	= "Armor_Shoulders",
	[GameLib.CodeEnumItemSlots.Feet] 		= "Armor_Boots",
	[GameLib.CodeEnumItemSlots.Hands] 		= "Armor_Gloves",
}

local ktItemCategoryToCamera =
{
	[8] = "Weapon_Sword2H",
	[12] = "Weapon_Resonator",
	[16] = "Weapon_Pistols1H",
	[22] = "Weapon_Psyblade",
	[24] = "Weapon_Claws",
	[108] = "Weapon_Launcher",
}

local ktClassToWeaponCamera =
{
	[GameLib.CodeEnumClass.Warrior] 		= "Weapon_Sword2H",
	[GameLib.CodeEnumClass.Spellslinger] 	= "Weapon_Pistols1H",
	[GameLib.CodeEnumClass.Stalker] 		= "Weapon_Claws",
	[GameLib.CodeEnumClass.Esper] 			= "Weapon_Psyblade",
	[GameLib.CodeEnumClass.Engineer] 		= "Weapon_Launcher",
	[GameLib.CodeEnumClass.Medic] 			= "Weapon_Resonator",
}

local ktUnlockFailureStrings =
{
	[CostumesLib.CostumeUnlockResult.AlreadyKnown] 			= Apollo.GetString("Costumes_AlreadyUnlocked"),
	[CostumesLib.CostumeUnlockResult.OutOfSpace] 			= Apollo.GetString("Costumes_TooManyItems"),
	[CostumesLib.CostumeUnlockResult.UnknownFailure] 		= Apollo.GetString("Costumes_UnknownError"),
	[CostumesLib.CostumeUnlockResult.ForgetItemFailed] 		= Apollo.GetString("Costumes_UnknownError"),
	[CostumesLib.CostumeUnlockResult.FailedPrerequisites] 	= Apollo.GetString("Costumes_InvalidItem"),
	[CostumesLib.CostumeUnlockResult.InsufficientCredits] 	= Apollo.GetString("Costumes_NeedMoreCredits"),
	[CostumesLib.CostumeUnlockResult.ItemInUse] 			= Apollo.GetString("Costumes_ItemInUse"),
	[CostumesLib.CostumeUnlockResult.ItemNotKnown] 			= Apollo.GetString("Costumes_ItemNotUnlocked"),
	[CostumesLib.CostumeUnlockResult.InvalidItem] 			= Apollo.GetString("Costumes_ItemNotUnlocked"),
}

local ktSaveFailureStrings =
{
	[CostumesLib.CostumeSaveResult.InvalidCostumeIndex] 	= Apollo.GetString("Costumes_InvalidCostume"),
	[CostumesLib.CostumeSaveResult.CostumeIndexNotUnlocked] = Apollo.GetString("Costumes_InvalidCostume"),
	[CostumesLib.CostumeSaveResult.UnknownMannequinError] 	= Apollo.GetString("Costumes_UnknownError"),
	[CostumesLib.CostumeSaveResult.ItemNotUnlocked] 		= Apollo.GetString("Costumes_SaveItemInvalid"),
	[CostumesLib.CostumeSaveResult.InvalidItem] 			= Apollo.GetString("Costumes_SaveItemInvalid"),
	[CostumesLib.CostumeSaveResult.UnusableItem] 			= Apollo.GetString("Costumes_SaveItemInvalid"),
	[CostumesLib.CostumeSaveResult.InvalidDye] 				= Apollo.GetString("Costumes_SaveDyeInvalid"),
	[CostumesLib.CostumeSaveResult.DyeNotUnlocked] 			= Apollo.GetString("Costumes_SaveDyeInvalid"),
	[CostumesLib.CostumeSaveResult.NotEnoughTokens] 		= Apollo.GetString("Costumes_CantAfford"),
	[CostumesLib.CostumeSaveResult.InsufficientFunds] 		= Apollo.GetString("Costumes_CantAfford"),
	[CostumesLib.CostumeSaveResult.UnknownError] 			= Apollo.GetString("Costumes_UnknownError"),
}

local ktItemQualityToColor =
{
	[Item.CodeEnumItemQuality.Average] 		= ApolloColor.new("ItemQuality_Average"),
	[Item.CodeEnumItemQuality.Good] 		= ApolloColor.new("ItemQuality_Good"),
	[Item.CodeEnumItemQuality.Excellent]	= ApolloColor.new("ItemQuality_Excellent"),
	[Item.CodeEnumItemQuality.Superb] 		= ApolloColor.new("ItemQuality_Superb"),
	[Item.CodeEnumItemQuality.Legendary] 	= ApolloColor.new("ItemQuality_Legendary"),
	[Item.CodeEnumItemQuality.Artifact] 	= ApolloColor.new("ItemQuality_Artifact"),
	[Item.CodeEnumItemQuality.Inferior] 	= ApolloColor.new("ItemQuality_Inferior"),
}

function Costumes:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Costumes:Init()
	Apollo.RegisterAddon(self)
end

function Costumes:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Costumes.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Costumes:OnDocumentReady()
	if not self.xmlDoc then
		return
	end

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 				"OnInterfaceMenuLoaded", self)
	self:OnInterfaceMenuLoaded()
	
	Apollo.RegisterEventHandler("ToggleHoloWardrobeWindow", 				"OnToggleHoloWardrobeWindow", self)
	Apollo.RegisterEventHandler("GenericEvent_OpenCostumes", 				"OnInit", self)
	Apollo.RegisterEventHandler("HousingMannequinOpen",						"OnMannequinInit", self)
	
	Apollo.RegisterEventHandler("CostumeForgetResult",						"OnForgetResult", self)
	Apollo.RegisterEventHandler("GenericEvent_CostumeUnlock",				"OnItemUnlock", self)
	Apollo.RegisterEventHandler("CostumeUnlockResult",						"OnUnlockResult", self)
	Apollo.RegisterEventHandler("AppearanceChanged", 						"RedrawCostume", self)
	
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate",				"EntitlementUpdated", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate",					"EntitlementUpdated", self)

	Apollo.RegisterEventHandler("CostumeSet", 								"OnCostumeChanged", self)
	
	Apollo.RegisterEventHandler("CostumeSaveResult",						"OnSaveResult", self)
	
	Apollo.RegisterEventHandler("CostumeCooldownComplete",					"OnThrottleEnd", self)
	
	Apollo.RegisterEventHandler("HousingMannequinClose",					"OnClose", self)
	Apollo.RegisterEventHandler("CloseVendorWindow",						"OnClose", self)
	Apollo.RegisterEventHandler("ChangeWorld",								"OnConfirmClose", self)
	Apollo.RegisterEventHandler("PlayerCurrencyChanged", 					"UpdateCost", self)
	Apollo.RegisterEventHandler("AccountCurrencyChanged", 					"UpdateCost", self)

	--ServiceTokenPrompt
	Apollo.RegisterEventHandler("ServiceTokenClosed_Costumes", "OnServiceTokenClosed_Costumes", self)
	
	--StoreEvents
	Apollo.RegisterEventHandler("StoreLinksRefresh",						"RefreshStoreLink", self)
	self.tStoreLinks = {}


	self.eSelectedSlot = nil
	self.costumeDisplayed = nil
	self.tEquipmentMap = {}
	self.tCostumeSlots = {}
	self.tKnownDyes = {}
	self.tSelectedDyeChannels = {}
	self.tUnlockedItems = {}
	self.nUnlockedCostumeCount = 0
	self.bAutoEquip = false
	self.bIsSheathed = false
	self.nDisplayedCostumeId = nil
	self.nSelectedCostumeId = nil
	self.strSelectedCostumeName = ""
	self.bShowUnusable = false
	
	self.unitPlayer = nil
	
	-- Saves Dye ids
	self.tCurrentDyes = 
	{
		[GameLib.CodeEnumItemSlots.Head] 		= {0,0,0},
		[GameLib.CodeEnumItemSlots.Shoulder] 	= {0,0,0},
		[GameLib.CodeEnumItemSlots.Chest]		= {0,0,0},
		[GameLib.CodeEnumItemSlots.Hands] 		= {0,0,0},
		[GameLib.CodeEnumItemSlots.Legs] 		= {0,0,0},
		[GameLib.CodeEnumItemSlots.Feet] 		= {0,0,0},
		[GameLib.CodeEnumItemSlots.Weapon]		= {0,0,0},
	}
end

function Costumes:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("Costumes_Title")})
end

function Costumes:OnInterfaceMenuLoaded()
	local tData = {"GenericEvent_OpenCostumes", "", "Icon_Windows32_UI_CRB_InterfaceMenu_HoloWardrobe"}
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("Costumes_Title"), tData)
end

----------------------
-- Setup
----------------------
function Costumes:OnToggleHoloWardrobeWindow()
	if self.wndMain ~= nil then
		self:OnConfirmClose()
	else
		self:OnInit()
	end
end

function Costumes:OnInit()
	Apollo.RegisterEventHandler("PlayerEquippedItemChanged", 	"MapEquipment", self)
	Apollo.RegisterEventHandler("DyeLearned",					"OnDyeLearned", self)
	
	if self.wndMain then
		self:OnConfirmClose()
	end
	
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "CharacterWindow", nil, self)
	self.wndMain:Invoke()
	
	self.wndPreview = self.wndMain:FindChild("Right:Costume")
	
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("Costumes_Title"), nSaveVersion = 2})
	
	-- Set up the costume controls
	self.nDisplayedCostumeId = CostumesLib.GetCostumeIndex()
	self.costumeDisplayed = CostumesLib.GetCostume(self.nDisplayedCostumeId)
	self.unitPlayer = GameLib.GetPlayerUnit()
	
	-- Setup the costume selection list
	local wndDropdownBtn = self.wndMain:FindChild("Left:SelectCostumeWindowToggle")
	local wndSelectionFrame = self.wndMain:FindChild("Left:CostumeBtnHolder")
	local wndCostumeSelectionList = wndSelectionFrame:FindChild("Framing")
	
	local wndDefaultCostumeBtn = Apollo.LoadForm(self.xmlDoc, "CostumeBtn", wndCostumeSelectionList, self)
	wndDefaultCostumeBtn:SetText(Apollo.GetString("Character_ClearBtn"))
	wndDefaultCostumeBtn:SetNormalTextColor(ApolloColor.new("Reddish"))
	wndDefaultCostumeBtn:ChangeArt("BK3:btnHolo_ListView_Top")
	wndDefaultCostumeBtn:SetData(knEquipmentCostumeIndex)
	
	self.nUnlockedCostumeCount = 0
	
	self:SharedInit()
	
	wndDropdownBtn:AttachWindow(wndSelectionFrame)
	
	self.wndUnlockItems = self.wndMain:FindChild("UnlockListBlocker:UnlockList")
	
	self:HelperToggleEquippedBtn()
	self:MapEquipment()
	self:RedrawCostume()
end

function Costumes:OnMannequinInit()
	Apollo.RegisterEventHandler("DyeLearned",	"OnDyeLearned", self)

	if self.wndMain then
		self:OnConfirmClose()
	end

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "CharacterWindow", nil, self)
	self.wndPreview = self.wndMain:FindChild("Right:Costume")

	self.wndMain:FindChild("Border:Title"):SetText(Apollo.GetString("Housing_MannequinTitle"))

	self.unitPlayer = GameLib.GetTargetUnit()
	self.costumeDisplayed = CostumesLib.GetActiveMannequinCostume()

	self:SharedInit()

	self:RedrawCostume()

	local wndLeftControls = self.wndMain:FindChild("Left")
	wndLeftControls:FindChild("NoCostumeBlocker"):Show(false)
	wndLeftControls:FindChild("SelectCostumeWindowToggle"):Show(false)
	wndLeftControls:FindChild("CostumeBtnHolder"):Show(false)

	local tPoseList = HousingLib.GetMannequinPoseList()
	local idCurrentPose = HousingLib.GetMannequinPose()

	self.wndPreview:SetModelSequence(tPoseList[idCurrentPose].nModelSequence)

	local wndRightControls = self.wndMain:FindChild("Right")
	local wndDropdownBtn = wndLeftControls:FindChild("SelectCostumeWindowToggle")
	local wndPoseContainer = wndLeftControls:FindChild("CostumeBtnHolder")
	local wndPoseSelectionList = wndPoseContainer:FindChild("Framing")

	wndDropdownBtn:Show(true)

	local wndPoseHeight = nil
	local nPoseCount = 0
	for idPose, tPoseInfo in pairs(tPoseList) do
		local wndPoseBtn = Apollo.LoadForm(self.xmlDoc, "MannequinPoseEntry", wndPoseSelectionList, self)
		local strLabel = tPoseInfo.strPoseName
		wndPoseBtn:SetText(strLabel)
		wndPoseBtn:SetData(tPoseInfo)

		if idPose == nUnlockedCostumeCount then
			wndPoseBtn:SetArt("BK3:btnHolo_ListView_Btm")
		end

		if idCurrentPose == idPose then
			wndPoseBtn:SetCheck(true)
			wndDropdownBtn:SetText(strLabel)
		end

		if not wndPoseHeight then
			wndPoseHeight = wndPoseBtn:GetHeight()
		end

		nPoseCount = nPoseCount + 1
	end
	
	wndPoseSelectionList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	local nLeft, nTop, nRight, nBottom = wndPoseContainer:GetAnchorOffsets()
	wndPoseContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + knCostumeBtnHolderBuffer + (wndPoseHeight * nPoseCount))

	nLeft, nTop, nRight, nBottom = wndDropdownBtn:GetAnchorOffsets()
	local nFLeft, nFTop, nFRight, nFBottom = wndLeftControls:GetAnchorOffsets()
	local nGap = nFLeft - nLeft

	local wndEquipBtn = wndLeftControls:FindChild("EquipBtn")
	local nBLeft, nBTop, nBRight, nBBottom = wndEquipBtn:GetAnchorOffsets()
	wndDropdownBtn:SetAnchorOffsets(nLeft, nTop, nBRight - nGap, nBottom)
	wndEquipBtn:Show(false)

	wndDropdownBtn:AttachWindow(wndPoseContainer)
end

-- This is part of both normal and mannequin init functions.
function Costumes:SharedInit()
	Event_FireGenericEvent("GenerciEvent_CostumesWindowOpened")
	self.wndMain:Invoke()
	local wndCostumeContainer = self.wndMain:FindChild("CostumeListContainer")
	local wndSpacer = Apollo.LoadForm(self.xmlDoc, "CostumeEntrySpacer", wndCostumeContainer, self)

	wndSpacer:FindChild("DyeColumn1"):SetData(1)
	wndSpacer:FindChild("DyeColumn2"):SetData(2)
	wndSpacer:FindChild("DyeColumn3"):SetData(3)

	local nUnlockedCount = CostumesLib.GetUnlockItemCount().nCurrent
	for idx = 1, #karCostumeSlots do
		local eSlotId = karCostumeSlots[idx]
		local wndCostumeEntry = Apollo.LoadForm(self.xmlDoc, "CostumeEntryForm", wndCostumeContainer, self)
		local wndEmptyCostumeSlot = wndCostumeEntry:FindChild("EmptySlotControls")
		wndEmptyCostumeSlot:FindChild("CostumePieceTitle"):SetText(Apollo.GetString(ktSlotToString[eSlotId]))

		if eSlotId == GameLib.CodeEnumItemSlots.Weapon then
			wndCostumeEntry:FindChild("VisibleBtn"):Show(false)
		end

		local tSlotData =
		{
			eSlot = eSlotId,
			wndCostumeItem = wndCostumeEntry,
		}

		wndCostumeEntry:FindChild("VisibleBtn"):SetData(eSlotId)
		wndCostumeEntry:FindChild("FilledSlotControls:CostumeSlot"):SetData(tSlotData)
		wndCostumeEntry:FindChild("EmptySlotControls:SlotEmptyBtn"):SetData(tSlotData)

		self.tUnlockedItems[eSlotId] = CostumesLib.GetUnlockedSlotItems(eSlotId, self.bShowUnusable)
		self.tCostumeSlots[eSlotId] = wndCostumeEntry
	end

	wndCostumeContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	local wndCostumeList = self.wndMain:FindChild("CostumeList")
	for idx = 1, knDisplayedItemCount do
		local wndDisplay = Apollo.LoadForm(self.xmlDoc, "CostumeListItem", wndCostumeList, self)
		wndDisplay:Show(false)
	end

	wndCostumeList:ArrangeChildrenTiles(Window.CodeEnumArrangeOrigin.LeftOrTop)

	self.wndMain:FindChild("Right:SetSheatheBtn"):SetCheck(self.bIsSheathed)
	self.wndPreview:SetSheathed(self.bIsSheathed)
	
	self.wndMain:FindChild("Center:ContentContainer:CostumeWindows:UnavailableControls:ShowUnavailableBtn"):SetCheck(self.bShowUnusable)

	self.wndMain:FindChild("CashBuyBtn"):Enable(false)

	self:HideContentContainer()

	if CostumesLib.GetUnlockItemCount().nCurrent > 0 then
		self:SetHelpString(Apollo.GetString("Costumes_DefaultHelper"))
	else
		self:SetHelpString(Apollo.GetString("Costumes_NoUnlockedItems"))
	end

	self:RefreshStoreLink()
end

----------------------
-- Costumes
----------------------
function Costumes:OnCostumeBtnChecked(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self.nSelectedCostumeId = wndHandler:GetData()
	self.strSelectedCostumeName = wndHandler:GetText()
	
	if self.costumeDisplayed and self.costumeDisplayed:HasChanges() then
		self:ActivateOverlay(keOverlayType.UndoSwap)
	else
		self:SwapCostume()
	end
end

function Costumes:SwapCostume()
	self.nDisplayedCostumeId = self.nSelectedCostumeId
	self.costumeDisplayed = CostumesLib.GetCostume(self.nDisplayedCostumeId)
	
	self.wndMain:FindChild("Left:CostumeBtnHolder"):Show(false)
	self.wndMain:FindChild("Left:SelectCostumeWindowToggle"):SetText(self.strSelectedCostumeName)

	self:HelperToggleEquippedBtn()
	
	self.tSelectedDyeChannels = {}
	
	self:ClearOverlay()
	self:ResetChannelControls()
	self:HideContentContainer()
	self:RedrawCostume()
	
	if CostumesLib.GetCostumeCooldownTimeRemaining() > 0 then
		self:OnEquipThrottled()
	else
		self:OnThrottleEnd()
	end	
end

function Costumes:RedrawCostume()
	if not self.wndMain then
		return
	end

	self.wndPreview:SetCostume(self.unitPlayer, self.bIsSheathed)
	
	if self.costumeDisplayed then
		for idx = 1, #karCostumeSlots do
			local eSlot = karCostumeSlots[idx]
			local itemEquipped = self.costumeDisplayed:GetSlotItem(eSlot) 
			local bIsVisible = self.costumeDisplayed:IsSlotVisible(eSlot)

			if itemEquipped then
				self:FillSlot(eSlot, bIsVisible, itemEquipped)
			else
				self:EmptySlot(eSlot, bIsVisible)
			end
			
			local wndVisibleBtn = self.tCostumeSlots[eSlot]:FindChild("VisibleBtn")
			wndVisibleBtn:Enable(self.nDisplayedCostumeId ~= knEquipmentCostumeIndex and (self.costumeDisplayed:GetSlotItem(eSlot) or self.tEquipmentMap[eSlot]))
			wndVisibleBtn:SetCheck(self.nDisplayedCostumeId ~= knEquipmentCostumeIndex and bIsVisible)
		end
		
		self.wndMain:FindChild("Left:NoCostumeBlocker"):Show(false)
		self.wndMain:FindChild("Left:CostumeListContainer"):Show(true)
	else
		self.wndMain:FindChild("Left:NoCostumeBlocker"):Show(true)
		self.wndMain:FindChild("Left:CostumeListContainer"):Show(false)
	end
	
	self:UpdateCost()
end

function Costumes:FillSlot(eSlot, bIsVisible, itemShown, bIsEquippedItem)
	local wndSlotFilled = self.tCostumeSlots[eSlot]:FindChild("FilledSlotControls")
	
	if itemShown then
		self.tCostumeSlots[eSlot]:FindChild("EmptySlotControls"):Show(false)
		wndSlotFilled:Show(true)
		
		local wndCostumeIcon = wndSlotFilled:FindChild("CostumeSlot:CostumeIcon")
		wndCostumeIcon:SetTooltipForm(nil)
		wndCostumeIcon:SetTooltipDoc(nil)
		wndCostumeIcon:SetBGColor(bIsEquippedItem and "UI_AlphaPercent25" or "UI_BtnBGDefault")
		
		local luaSubclass = wndCostumeIcon:GetWindowSubclass()
		luaSubclass:SetItem(itemShown)
		
		local tAvailableDyeChannels = itemShown:GetAvailableDyeChannel()
		if not tAvailableDyeChannels then
			tAvailableDyeChannels = {}
		end
		
		local arAvailableDyeChannels =
		{
			tAvailableDyeChannels.bDyeChannel1,
			tAvailableDyeChannels.bDyeChannel2,
			tAvailableDyeChannels.bDyeChannel3,
		}
		
		local tDyeContainers =
		{
			wndSlotFilled:FindChild("DyeColor1Container"),
			wndSlotFilled:FindChild("DyeColor2Container"),
			wndSlotFilled:FindChild("DyeColor3Container"),
		}
		
		local arDyes = self.costumeDisplayed:GetSlotDyes(eSlot)
		for idx = 1, #tDyeContainers do
			local tDyeInfo = arDyes[idx]
			local wndDyeColor = tDyeContainers[idx]:FindChild("DyeColor" .. idx)
			
			tDyeContainers[idx]:FindChild("DyeSwatch"):SetSprite(tDyeInfo.nId > 0 and kstrDyeSpriteBase .. tDyeInfo.nRampIndex or "")
			tDyeContainers[idx]:SetData({eSlot = eSlot, nDyeChannel = idx, tDyeInfo = tDyeInfo,})
			self.tCurrentDyes[eSlot][idx] = tDyeInfo.nId or 0
			
			wndDyeColor:Enable(bIsVisible and arAvailableDyeChannels[idx])
			wndDyeColor:SetCheck(false)
		end
		
		if bIsVisible then
			self.wndPreview:SetItem(itemShown)
			self.wndPreview:SetItemDye(itemShown, arDyes[1].nId, arDyes[2].nId, arDyes[3].nId)
		else
			self.wndPreview:RemoveItem(eSlot)
		end
		
		self.tCostumeSlots[eSlot]:FindChild("VisibleBtn"):Enable(true)
		
		local tItemCostumeInfo = itemShown:GetCostumeUnlockInfo()
		local wndInvalidItemOverlay = wndSlotFilled:FindChild("UnusableCostumeSlotItemOverlay")
		wndInvalidItemOverlay:Show(not (tItemCostumeInfo and tItemCostumeInfo.bCanUseInCostume))
		
		self:ClearSlotDyeSelection(eSlot)
		self:UpdateCost()
	end
end

function Costumes:EmptySlot(eSlot, bIsVisible)
	self.costumeDisplayed:SetSlotItem(eSlot, knEmptySlotId)
	
	if self.tEquipmentMap[eSlot] then
		self:FillSlot(eSlot, bIsVisible, self.tEquipmentMap[eSlot], true)
		return
	end
	self.wndPreview:RemoveItem(eSlot)
	
	local wndEmptySlotControls = self.tCostumeSlots[eSlot]:FindChild("EmptySlotControls")	
	self.tCostumeSlots[eSlot]:FindChild("FilledSlotControls"):Show(false)
	wndEmptySlotControls:Show(true)
	self.tCostumeSlots[eSlot]:FindChild("VisibleBtn"):Enable(false)
	
	self:ClearSlotDyeSelection(eSlot)
	
	self:UpdateCost()
end

function Costumes:OnSlotClick(wndHandler, wndControl, eMouseButton)
	if self.nDisplayedCostumeId == knEquipmentCostumeIndex then
		return
	end
	
	local eSlot = wndHandler:GetData().eSlot

	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		-- Remove the item
		self:SetHelpString(Apollo.GetString("Costumes_DefaultHelper"))
		self:HideContentContainer()
		
		local tSlotInfo = wndHandler:GetData()
		self:EmptySlot(eSlot, self.costumeDisplayed:IsSlotVisible(eSlot))
	else
		if self.eSelectedSlot ~= eSlot then
			self:ShowCostumeContent()
			self.itemSelected = self.costumeDisplayed:GetSlotItem(eSlot)
			
			self.eSelectedSlot = eSlot
			
			self.tUnlockedItems[eSlot] = CostumesLib.GetUnlockedSlotItems(eSlot, self.bShowUnusable)
			
			self:OnClearSearch()
			self:HelperUpdatePageItems(1)
		end
	end
end

-- This should only be called if the player has a costume
function Costumes:OnVisibleBtnCheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return false
	end

	local bVisible = wndHandler:IsChecked()
	local eSlot = wndHandler:GetData()
	local itemShown = nil
	
	-- Set the state
	self.costumeDisplayed:SetSlotVisible(eSlot, bVisible)
	
	-- Update the preview
	if not bVisible then
		self.wndPreview:RemoveItem(eSlot)
		self:ClearSlotDyeSelection(eSlot)
	else
		local itemShown = self.costumeDisplayed:GetSlotItem(eSlot) or self.tEquipmentMap[eSlot]
		local arDyes = self.costumeDisplayed:GetSlotDyes(eSlot)
		if itemShown and arDyes then
			self.wndPreview:SetItem(itemShown)
			self.wndPreview:SetItemDye(itemShown, arDyes[1].nId, arDyes[2].nId, arDyes[3].nId)
		end
	end

	-- Block the player from dying hidden slots
	local wndFilledSlot = wndHandler:GetParent():FindChild("FilledSlotControls")
	if itemShown and wndFilledSlot:IsShown() then
		local tAvailableDyeChannels = itemShown:GetAvailableDyeChannel()

		local strBGColor = "UI_AlphaPercent100"
		if not bVisible then
			strBGColor = "UI_AlphaPercent50"
		end

		wndFilledSlot:FindChild("DyeColor1Container:DyeColor1"):Enable(bVisible and tAvailableDyeChannels.bDyeChannel1)
		wndFilledSlot:FindChild("DyeColor2Container:DyeColor2"):Enable(bVisible and tAvailableDyeChannels.bDyeChannel2)
		wndFilledSlot:FindChild("DyeColor3Container:DyeColor3"):Enable(bVisible and tAvailableDyeChannels.bDyeChannel3)
		wndFilledSlot:FindChild("DyeColor1Container"):SetBGColor(strBGColor)
		wndFilledSlot:FindChild("DyeColor2Container"):SetBGColor(strBGColor)
		wndFilledSlot:FindChild("DyeColor3Container"):SetBGColor(strBGColor)
	end
	
	self:UpdateCost()
end

function Costumes:OnPreviewBtnChecked(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.itemSelected = wndHandler:GetData()
	
	self.wndPreview:SetItem(self.itemSelected)
	self.costumeDisplayed:SetSlotItem(self.eSelectedSlot, self.itemSelected:GetItemId())
	self:FillSlot(self.eSelectedSlot, true, self.itemSelected)

	local wndVisibleButton = self.tCostumeSlots[self.eSelectedSlot]:FindChild("VisibleBtn")
	if wndVisibleButton and not wndVisibleButton:IsChecked() then
		wndVisibleButton:SetCheck(true)
	end
end

function Costumes:OnPageUp(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:HelperUpdatePageItems(wndHandler:GetData())
end

function Costumes:OnPageDown(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:HelperUpdatePageItems(wndHandler:GetData())
end

function Costumes:OnSearchContent(wndHandler, wndControl, strText)
	local wndSearchContainer = wndHandler:GetParent()
	local bHasText = strText ~= ""
	wndSearchContainer:FindChild("ClearBtn"):Show(bHasText)
	wndSearchContainer:FindChild("SearchIcon"):Show(not bHasText)
	
	local wndDyeList = self.wndMain:FindChild("DyeList")
	
	if self.wndMain:FindChild("Center:ContentContainer:CostumeWindows"):IsShown() then
		self.arDisplayedItems = {}
		for idx, itemInfo in pairs(self.tUnlockedItems[self.eSelectedSlot]) do
			if string.find(string.lower(itemInfo:GetName()), string.lower(strText), 1, true) then
				table.insert(self.arDisplayedItems, itemInfo)
			end
		end
		
		self:SortDisplayedItems()
		
		self:HelperUpdatePageItems(1)
	elseif wndDyeList:IsShown() then
		for idx, wndDye in pairs(wndDyeList:GetChildren()) do
			wndDye:Show(string.find(string.lower(wndDye:FindChild("DyeSwatchTitle"):GetText()), string.lower(strText), 1, true))
		end
		local nListHeight = wndDyeList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:GetData().nId == knResetDyeId or 
			(a:GetData().nId ~= knResetDyeId and b:GetData().nId ~= knResetDyeId and a:GetData().nId < b:GetData().nId) end)

		self.wndMain:FindChild("NoResults"):FindChild("NoResults"):Show(nListHeight == 0)		
		wndDyeList:SetVScrollPos(0)
		wndDyeList:RecalculateContentExtents()
	end
end

function Costumes:OnClearSearch()
	local wndSearchBar = self.wndMain:FindChild("ContentSearch")
	wndSearchBar:SetText("")
	self:UpdateDisplayedItemList(self.eSelectedSlot)
end

function Costumes:ToggleShowUnavailable(wndHandler, wndControl)
	self.bShowUnusable = wndHandler:IsChecked()
	self.tUnlockedItems[self.eSelectedSlot] = CostumesLib.GetUnlockedSlotItems(self.eSelectedSlot, self.bShowUnusable)
	
	self:UpdateDisplayedItemList(self.eSelectedSlot)
end

-- Updates the items for the preview slots.
function Costumes:HelperUpdatePageItems(nPageNumber)	
	local wndContentContainer = self.wndMain:FindChild("Center:ContentContainer")
	local arPreviewWindows = wndContentContainer:FindChild("CostumeWindows:CostumeList"):GetChildren()
	
	-- If there are no items in the page we were given, go back to the highest page with items
	local nOffset = knDisplayedItemCount * (nPageNumber - 1)
	while nPageNumber > 0 and not self.arDisplayedItems[nOffset + 1] do
		nPageNumber = nPageNumber - 1
		nOffset = knDisplayedItemCount * (nPageNumber - 1)
	end
	
	for idx = 1, knDisplayedItemCount do
		local nItemIdx = nOffset + idx
		local wndItemPreview = arPreviewWindows[idx]
		local wndMannequin = wndItemPreview:FindChild("CostumeWindow")

		if self.arDisplayedItems[nItemIdx] then
			wndMannequin:SetData(self.arDisplayedItems[nItemIdx])
			wndItemPreview:SetData(self.arDisplayedItems[nItemIdx])
			
			local wndCostumeBtn = wndItemPreview:FindChild("CostumeListItemBtn")
			wndCostumeBtn:SetData(self.arDisplayedItems[nItemIdx])
			wndCostumeBtn:SetCheck(self.itemSelected and self.itemSelected:GetItemId() == self.arDisplayedItems[nItemIdx]:GetItemId())
			
			wndMannequin:SetTooltipForm(nil)
			wndMannequin:SetTooltipDoc(nil)
			
			wndItemPreview:Show(true)
			
			local tItemCostumeInfo = self.arDisplayedItems[nItemIdx]:GetCostumeUnlockInfo()
			
			local bCanUse = tItemCostumeInfo and tItemCostumeInfo.bCanUseInCostume
			local wndUnusableIcon = wndItemPreview:FindChild("UnusableIcon")

			wndUnusableIcon:Show(not bCanUse)
			wndCostumeBtn:Enable(bCanUse)
			wndItemPreview:FindChild("DeprecatedIcon"):Show(self.arDisplayedItems[nItemIdx]:IsDeprecated())

			self:SetItemToWindow(wndMannequin, self.arDisplayedItems[nItemIdx])
			
			wndMannequin:SetSheathed(false)
		else
			wndItemPreview:Show(false)
		end
	end
	
	wndContentContainer:FindChild("CostumeList"):ArrangeChildrenTiles(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	local wndPageUp = wndContentContainer:FindChild("PageUp")
	if self.arDisplayedItems[nOffset + knDisplayedItemCount + 1] then
		wndPageUp:SetData(nPageNumber + 1)
		wndPageUp:Enable(true)
	else
		wndPageUp:Enable(false)
	end
	
	local wndPageDown = wndContentContainer:FindChild("PageDown")
	wndPageDown:Enable(nPageNumber > 1 )
	wndPageDown:SetData(nPageNumber - 1)
	
	-- if we somehow got to page 0, exit since there's no items
	if nPageNumber <= 0 and #self.tUnlockedItems[self.eSelectedSlot] == 0 then
		self.wndMain:FindChild("Center:HelpContentContainer"):Show(true)
		wndContentContainer:Show(false)
		self:SetHelpString(Apollo.GetString("Costumes_NoneFound"))
	else
		wndContentContainer:Show(true)
		self.wndMain:FindChild("Center:HelpContentContainer"):Show(false)
		
		local strErrorText = ""
		if nPageNumber <= 0 then
			strErrorText = Apollo.GetString("Tradeskills_NoResults")
		end
		
		self.wndMain:FindChild("Center:HelpContentContainer"):SetText(strErrorText)
	end
end

function Costumes:MapEquipment()
	local arItems = GameLib:GetPlayerUnit():GetEquippedItems()
	self.tEquipmentMap = {}
	
	for idx = 1, #arItems do
		local eSlot = ktItemSlotToEquippedItems[arItems[idx]:GetSlot()]
		if eSlot then
			self.tEquipmentMap[eSlot] = arItems[idx]
		end
	end
end

function Costumes:OnCostumeChanged(idCostume)
	if self.unitPlayer and self.unitPlayer == GameLib.GetPlayerUnit() and self.wndMain then
		local wndCostumeBtn = self.wndMain:FindChild("Left:CostumeBtnHolder:Framing"):FindChildByUserData(idCostume)
		
		if wndCostumeBtn then
			self:OnCostumeBtnChecked(wndCostumeBtn, wndCostumeBtn)
		end
	end
end

----------------------
-- Dyes
----------------------
function Costumes:GetDyeList()
	local arDyes = GameLib.GetKnownDyes()
	local wndDyeList = self.wndMain:FindChild("DyeList")
	
	if not self.tKnownDyes[knResetDyeId] then
		local strName = Apollo.GetString("Costumes_RemoveDye")
		local wndRemoveDye = Apollo.LoadForm(self.xmlDoc, "DyeColorListItem", wndDyeList, self)
		local tInfo = {nId = knResetDyeId, nRampIndex = 0}
		
		wndRemoveDye:FindChild("DyeSwatchTitle"):SetText(strName)
		wndRemoveDye:FindChild("DyeSwatch"):Show(false)
		wndRemoveDye:SetData(tInfo)
		
		self.tKnownDyes[knResetDyeId] = true
	end
	
	for idx = 1, #arDyes do
		local tDyeInfo = arDyes[idx]
		
		if not self.tKnownDyes[tDyeInfo.nId] then
			local wndNewDye = Apollo.LoadForm(self.xmlDoc, "DyeColorListItem", wndDyeList, self)
			
			local strName = ""
			if tDyeInfo.strName and tDyeInfo.strName:len() > 0 then
				strName = tDyeInfo.strName
			else
				strName = String_GetWeaselString(Apollo.GetString("CRB_CurlyBrackets"), "", tDyeInfo.idDye)
			end
			
			wndNewDye:FindChild("DyeSwatch"):SetSprite(tDyeInfo.nId > 0 and kstrDyeSpriteBase .. tDyeInfo.nRampIndex or "")
			wndNewDye:FindChild("DyeSwatchTitle"):SetText(strName)
			wndNewDye:SetData(tDyeInfo)
			
			self.tKnownDyes[tDyeInfo.nId] = true
		end
	end
	
	-- Remove Dye is at the top of the list.  Everything after should be alphabetical.
	wndDyeList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:GetData().nId == knResetDyeId or 
		(a:GetData().nId ~= knResetDyeId and b:GetData().nId ~= knResetDyeId and a:GetData().nId < b:GetData().nId) end)
end

function Costumes:OnDyeChannelChecked(wndHandler, wndControl)
	self:GetDyeList()
	self:ShowDyeContent()
	
	local tSlotData = wndHandler:GetParent():GetData()
	local eSlot = tSlotData.eSlot
	
	if not self.tSelectedDyeChannels[eSlot] then
		self.tSelectedDyeChannels[eSlot] = {}
	end
	
	self.tSelectedDyeChannels[eSlot][tSlotData.nDyeChannel] = wndHandler:GetParent()
	
	local nFoundIndex = nil
	local nWindowHeight = nil
	
	local wndDyeList = self.wndMain:FindChild("DyeList")
	for idx, wndDye in pairs (wndDyeList:GetChildren()) do
		local bIsSelected = tSlotData.tDyeInfo.nId == wndDye:GetData().nId
		wndDye:FindChild("DyeColorBtn"):SetCheck(bIsSelected)
		
		if bIsSelected then
			nFoundIndex = idx
			nWindowHeight = wndDye:GetHeight()
		end
	end
	
	if nFoundIndex then
		wndDyeList:SetVScrollPos((nFoundIndex - 1) * nWindowHeight)
	end
end

function Costumes:OnDyeChannelDeselect(wndHandler, wndControl)
	local tSlotData = wndHandler:GetParent():GetData()
	wndHandler:SetCheck(false)
	
	self.tSelectedDyeChannels[tSlotData.eSlot][tSlotData.nDyeChannel] = nil
		
	local bIsEmpty = true
	
	for eSlot, tDyeChannels in pairs(self.tSelectedDyeChannels) do
		for nDyeChannel, idDye in pairs(tDyeChannels) do
			bIsEmpty = false
			break
		end
	end
	
	if bIsEmpty then
		self.tSelectedDyeChannels[tSlotData.eSlot] = nil
		self.wndMain:FindChild("Center:ContentContainer"):Show(false)
		self.wndMain:FindChild("Center:HelpContentContainer"):Show(true)
	end
	
end

function Costumes:OnSelectAllDyeChannel(wndHandler, wndControl)
	local nSlotChannel = wndHandler:GetData()
	
	for idx = 1, #karCostumeSlots do
		local wndFilledSlot = self.tCostumeSlots[karCostumeSlots[idx]]:FindChild("FilledSlotControls")
		local wndDyeColor = wndFilledSlot:FindChild("DyeColor" .. nSlotChannel .. "Container:DyeColor" .. nSlotChannel)
		
		if wndFilledSlot:IsShown() and wndDyeColor:IsEnabled() then
			wndDyeColor:SetCheck(true)
			self:OnDyeChannelChecked(wndDyeColor, wndDyeColor)
		end
	end
end

function Costumes:OnDeselectAllDyeChannel(wndHandler, wndControl)
	local nSlotChannel = wndHandler:GetData()
	
	for idx = 1, #karCostumeSlots do
		local wndFilledSlot = self.tCostumeSlots[karCostumeSlots[idx]]:FindChild("FilledSlotControls")
		local wndDyeColor = wndFilledSlot:FindChild("DyeColor" .. nSlotChannel .. "Container:DyeColor" .. nSlotChannel)
		
		if wndFilledSlot:IsShown() and wndDyeColor:IsEnabled() and wndDyeColor:IsChecked() then
			wndDyeColor:SetCheck(false)
			self:OnDyeChannelDeselect(wndDyeColor, wndDyeColor)
		end
	end
end

function Costumes:OnDyeColorChecked(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local tDyeInfo = wndHandler:GetParent():GetData()
	for eSlot, tDyeWindows in pairs(self.tSelectedDyeChannels) do
		local bSlotChanged = false
		for nDyeChannel, wndDye in pairs(tDyeWindows) do
			self:UpdateSlotDye(eSlot, nDyeChannel, tDyeInfo)
			
			bSlotChanged = true
		end
		
		if bSlotChanged then
			self:UpdateItemDye(eSlot)
		end
	end
	
	self:UpdateCost()
end

function Costumes:UpdateSlotDye(eSlot, nChannel, tDyeInfo)
	self.tCurrentDyes[eSlot][nChannel] = tDyeInfo.nId
	
	local wndDyeChannel = self.tCostumeSlots[eSlot]:FindChild("FilledSlotControls:DyeColor" .. nChannel .. "Container")
	wndDyeChannel:FindChild("DyeSwatchArtHack:DyeSwatch"):SetSprite(kstrDyeSpriteBase .. tDyeInfo.nRampIndex)
	wndDyeChannel:SetData({eSlot = eSlot, nDyeChannel = nChannel, tDyeInfo = tDyeInfo})
end

function Costumes:UpdateItemDye(eSlot)
	local itemDyed = self.costumeDisplayed:GetSlotItem(eSlot) or self.tEquipmentMap[eSlot]
	self.costumeDisplayed:SetSlotDyes(eSlot, self.tCurrentDyes[eSlot][1], self.tCurrentDyes[eSlot][2], self.tCurrentDyes[eSlot][3])
	self.wndPreview:SetItemDye(itemDyed, self.tCurrentDyes[eSlot][1], self.tCurrentDyes[eSlot][2], self.tCurrentDyes[eSlot][3])
end

function Costumes:ClearSlotDyeSelection(eSlot)
	if self.tSelectedDyeChannels[eSlot] then
		for nDyeChannel, wndDye in pairs(self.tSelectedDyeChannels[eSlot]) do
			local dyeButton = wndDye and wndDye:FindChild("DyeColor" .. nDyeChannel)
			if dyeButton then
				dyeButton:SetCheck(false)
			end
		end
		self.tSelectedDyeChannels[eSlot] = nil
	end
end

function Costumes:ResetChannelControls()
	local wndSpacer = self.wndMain:FindChild("CostumeEntrySpacer")
	
	wndSpacer:FindChild("DyeColumn1"):SetCheck(false)
	wndSpacer:FindChild("DyeColumn2"):SetCheck(false)
	wndSpacer:FindChild("DyeColumn3"):SetCheck(false)
end

----------------------
-- Mannequin
----------------------
function Costumes:OnPoseCheck(wndHandler, wndControl)
	local tPoseData = wndHandler:GetData()
	
	HousingLib.SetMannequinPose(tPoseData.nId)
end

----------------------
-- Window Controls
----------------------
function Costumes:OnReset(wndHandler, wndControl)
	if self.costumeDisplayed then
		self.eSelectedSlot = nil
		self.costumeDisplayed:DiscardChanges()
		self:HideContentContainer()
		self:ResetChannelControls()
	
		-- RedrawCostume updates the cost
		self:RedrawCostume()
	end
end

function Costumes:OnEquip(wndHandler, wndControl)
	CostumesLib.SetCostumeIndex(self.nDisplayedCostumeId)
	
	Event_FireGenericEvent("CostumeSet", self.nDisplayedCostumeId)
	
	if CostumesLib.GetCostumeCooldownTimeRemaining() > 0 then
		self:OnEquipThrottled()
	end	
end

function Costumes:OnUndoAccept(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local eUnlockType = wndHandler:GetData()
	
	if eUnlockType == keOverlayType.UndoClose then
		self:OnConfirmClose()
	elseif eUnlockType == keOverlayType.UndoSwap then
		self:SwapCostume()
	end
end

function Costumes:OnWindowClosed()
	if self.wndMain then
		Apollo.RemoveEventHandler("PlayerEquippedItemChanged", self)
		Apollo.RemoveEventHandler("DyeLearned", self)
		self.eSelectedSlot = nil
		self.costumeDisplayed = nil
		self.tCostumeSlots = {}
		self.tSelectedDyeChannels = {}
		self.tKnownDyes = {}
		self.tEquipmentMap = {}
		self.tUnlockedItems = {}
		self.unitPlayer = nil
		
		for eSlot, tChannels in pairs(self.tCurrentDyes) do
			self.tCurrentDyes[eSlot] = {0,0,0}
		end
	
		self.wndMain:Destroy()
		self.wndMain = nil
		self.wndPreview = nil
		self.wndUnlockItems = nil
		
		if self.timerError then
			self.timerError:Stop()
		end

		Event_FireGenericEvent("GenerciEvent_CostumesWindowClosed")
		Event_CancelHousingMannequin()
	end
end

function Costumes:OnClose()
	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end
	
	self:ClearOverlay()
	
	if self.costumeDisplayed and self.costumeDisplayed:HasChanges() then
		self:ActivateOverlay(keOverlayType.UndoClose)
	else
		self:OnConfirmClose()
	end
end

function Costumes:OnConfirmClose()
	self:OnContextMenuClose()
	if self.wndMain then
		self.wndMain:Close()
	end
end

function Costumes:OnCloseCancel()
	self:ClearOverlay()
	
	local wndFraming = self.wndMain:FindChild("Left:CostumeBtnHolder:Framing")
	
	if self.nSelectedCostumeId and self.nDisplayedCostumeId then
		wndFraming:FindChildByUserData(self.nDisplayedCostumeId):SetCheck(true)
		wndFraming:FindChildByUserData(self.nSelectedCostumeId):SetCheck(false)
	end
end

----------------------
-- DragDrop Handlers
----------------------
function Costumes:OnDragDropQuery(wndHandler, wndControl, nX, nY, wndSource, strType, nValue)
	if strType ~= "DDBagItem" then
		return
	end

	local itemDragged = Item.GetItemFromInventoryLoc(nValue)
	local eItemFamily = itemDragged:GetItemFamily()
	if eItemFamily ~= Item.CodeEnumItem2Family.Weapon and eItemFamily ~= Item.CodeEnumItem2Family.Armor and eItemFamily ~= Item.CodeEnumItem2Family.Costume then
		return Apollo.DragDropQueryResult.Invalid
	end

	return Apollo.DragDropQueryResult.Accept
end

function Costumes:OnDragDropEnd(wndHandler, wndControl, nX, nY, wndSource, strType, nValue)
	if strType ~= "DDBagItem" then
		return
	end

	local itemDragged = Item.GetItemFromInventoryLoc(nValue)
	
	self.bAutoEquip = true
	self:OnItemUnlock(itemDragged)
end


----------------------
-- Unlock Item Controls
----------------------
function Costumes:OnItemUnlock(itemUnlock)
	if not itemUnlock then
		return
	end
	
	if itemUnlock:GetInventoryId() == 0 then
		return
	end

	local eItemFamily = itemUnlock:GetItemFamily()
	if eItemFamily ~= Item.CodeEnumItem2Family.Weapon and eItemFamily ~= Item.CodeEnumItem2Family.Armor and eItemFamily ~= Item.CodeEnumItem2Family.Costume then
		return
	end

	if self.wndUnlock then
		self:OnCloseUnlock()
	end

	self.wndUnlock = Apollo.LoadForm(self.xmlDoc, "UnlockConfirmation", nil, self)
	local tUnlockInfo = itemUnlock:GetCostumeUnlockInfo()
	local tUnlockedItemsCount = CostumesLib.GetUnlockItemCount()
	local luaSubclass = self.wndUnlock:FindChild("ItemIcon"):GetWindowSubclass()
	
	luaSubclass:SetItem(itemUnlock)

	local wndItemName = self.wndUnlock:FindChild("ItemName")
	wndItemName:SetText(itemUnlock:GetName())
	self.wndUnlock:FindChild("ItemName"):SetTextColor(ktItemQualityToColor[itemUnlock:GetItemQuality()])
	
	self.wndUnlock:FindChild("CashWindow"):SetAmount(tUnlockInfo.monUnlockCost)
	
	local wndConfirmBtn = self.wndUnlock:FindChild("ConfirmBtn")
	wndConfirmBtn:SetActionData(GameLib.CodeEnumConfirmButtonType.UnlockCostumeItem, itemUnlock:GetInventoryId())
	
	local strMessage = Apollo.GetString("Costumes_UnlockNotice")
	local crText = nil
	local bCanAfford = tUnlockInfo.monUnlockCost and GameLib.GetPlayerCurrency():GetAmount() > tUnlockInfo.monUnlockCost:GetAmount()
	if tUnlockInfo.bUnlocked then
		strMessage = Apollo.GetString("Costumes_AlreadyUnlocked")
		crText = ApolloColor.new("Reddish")
		wndConfirmBtn:Enable(false)
	elseif not tUnlockInfo.bCanUnlock then
		strMessage = Apollo.GetString("Costumes_InvalidItem")
		crText = ApolloColor.new("Reddish")
		wndConfirmBtn:Enable(false)
	elseif tUnlockedItemsCount.nCurrent >= tUnlockedItemsCount.nMax then
		strMessage = Apollo.GetString("Costumes_TooManyItems")
		crText = ApolloColor.new("Reddish")
		wndConfirmBtn:Enable(false)
	elseif not bCanAfford then
		strMessage = Apollo.GetString("Costumes_NeedMoreCredits")
		crText = ApolloColor.new("Reddish")
		self.wndUnlock:FindChild("CashWindow"):SetTextColor(crText)
		wndConfirmBtn:Enable(false)
	end
	
	local wndMessageText = self.wndUnlock:FindChild("MessageText")
	if strMessage then
		wndMessageText:SetText(strMessage)
	end
	
	if crText then
		wndMessageText:SetTextColor(crText)
	end

	local wndConfirmPreview = self.wndUnlock:FindChild("CostumeWindow")
	self:SetItemToWindow(wndConfirmPreview, itemUnlock)
	
	self:UpdateItemCount()

	self.wndUnlock:Invoke()
end

function Costumes:OnCloseUnlock(wndHandler, wndControl)
	if self.wndUnlock then
		self.wndUnlock:Destroy()
		self.wndUnlock = nil
	end
end

function Costumes:OnUnlockResult(itemData, eResult)
	if self.wndMain then
		if eResult == CostumesLib.CostumeUnlockResult.UnlockSuccess then
			local eSlot = ktItemSlotToEquippedItems[itemData:GetSlot()]
			table.insert(self.tUnlockedItems[eSlot], itemData)

			if self.eSelectedSlot and self.eSelectedSlot == eSlot then
				local wndSearchBar = self.wndMain:FindChild("ContentSearch")
				self:OnSearchContent(wndSearchBar, wndSearchBar, wndSearchBar:GetText())
				self:HelperUpdatePageItems((self.wndMain:FindChild("PageDown"):GetData() or 0) + 1)

				self.wndMain:FindChild("UnlockConfirmFlash"):SetSprite("BK3:UI_BK3_Holo_RefreshReflectionSquare_anim")
			end

			if self.bAutoEquip then
				self.costumeDisplayed:SetSlotItem(eSlot, itemData:GetItemId())
				self:FillSlot(eSlot, self.costumeDisplayed:IsSlotVisible(eSlot), itemData)
			end
		end
		
		if eResult ~= CostumesLib.CostumeUnlockResult.UnlockRequested then
			self.bAutoEquip = false
		end
		
		self:UpdateItemCount()
	end

	if self.wndUnlock then
		local wndText = self.wndUnlock:FindChild("MessageText")

		if eResult == CostumesLib.CostumeUnlockResult.UnlockSuccess then
			self:OnCloseUnlock()
		elseif eResult == CostumesLib.CostumeUnlockResult.AlreadyKnown then
			wndText:SetText(Apollo.GetString("Costumes_AlreadyUnlocked"))
		elseif eResult == CostumesLib.CostumeUnlockResult.OutOfSpace then
			wndText:SetText(Apollo.GetString("Costumes_TooManyItems"))
		elseif eResult == CostumesLib.CostumeUnlockResult.InsufficientCredits then
			wndText:SetText(Apollo.GetString("Costumes_NeedMoreCredits"))
		end
	end

	if self.wndUnlockItems then
		if eResult == CostumesLib.CostumeUnlockResult.UnlockSuccess then
			self:BuildUnlockList()
			self.wndUnlockItems:FindChild("ConfirmFlash"):SetSprite("BK3:UI_BK3_Holo_RefreshReflectionSquare_anim")
		end
	end
end

----------------------
-- Unlock List Controls
----------------------

function Costumes:OpenItemUnlock(wndHandler, wndControl)
	self.wndMain:FindChild("UnlockListBlocker"):Show(true)
	self:BuildUnlockList()
end

function Costumes:BuildUnlockList()
	if not self.wndUnlockItems then
		return
	end

	local unitPlayer = GameLib.GetPlayerUnit()
	local arInventoryItems = unitPlayer:GetInventoryItems()
	local arItems = unitPlayer:GetEquippedItems()
	self:UpdateItemCount()

	if #arInventoryItems > 0 then
		for idx = 1, #arInventoryItems do
			table.insert(arItems, arInventoryItems[idx].itemInBag)
		end
	end

	local wndItemList = self.wndUnlockItems:FindChild("ItemContainer")
	wndItemList:DestroyChildren()

	self.wndUnlockItems:FindChild("NoItemText"):Show(false)
	for idx, itemCurr in pairs(arItems) do
		local tUnlockInfo = itemCurr:GetCostumeUnlockInfo()
		if tUnlockInfo.bCanUnlock and not tUnlockInfo.bUnlocked then
			local wndItem = Apollo.LoadForm(self.xmlDoc, "UnlockItem", wndItemList, self)
			wndItem:SetData(itemCurr)

			local luaSubclass = wndItem:FindChild("ItemIcon"):GetWindowSubclass()
			luaSubclass:SetItem(itemCurr)

			local wndItemName = wndItem:FindChild("ItemName")
			wndItemName:SetText(itemCurr:GetName())
			wndItemName:SetTextColor(ktItemQualityToColor[itemCurr:GetItemQuality()])
		end
	end

	wndItemList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return a:GetData():GetName() < b:GetData():GetName() end)
	wndItemList:RecalculateContentExtents()

	local wndFirstUnlockedItem = wndItemList:GetChildren()[1]
	if wndFirstUnlockedItem then
		wndFirstUnlockedItem:SetCheck(true)
		self:OnUnlockItemSelect(wndFirstUnlockedItem, wndFirstUnlockedItem)
	else
		self.wndUnlockItems:FindChild("NoItemText"):Show(true)
		self.wndUnlockItems:FindChild("ItemPreview"):SetCostumeToCreatureId(ktManneqinIds[self.unitPlayer:GetGender()])
		self.wndUnlockItems:FindChild("ItemPreview"):SetCamera("Paperdoll")
		local tUnlockInfo = CostumesLib.GetUnlockItemCount()
		local wndUnlockItemBtn = self.wndUnlockItems:FindChild("UnlockConfirmBtn")
		local strImportBtn = string.format('<P Font="CRB_Button" Align="Center"><T TextColor="UI_BtnTextBlueDisabled">%s</T></P>', String_GetWeaselString(Apollo.GetString("Costumes_UnlockLimitCount"), tostring(tUnlockInfo.nCurrent), tostring(tUnlockInfo.nMax)))
		wndUnlockItemBtn:FindChild("UnlockItemsCount"):SetAML(strImportBtn)
		wndUnlockItemBtn:Enable(false)

	end

	local nAmount = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.AdditionalCostumeUnlocks)
	local nMax = AccountItemLib.GetMaxEntitlementCount(AccountItemLib.CodeEnumEntitlement.AdditionalCostumeUnlocks)
	self.wndMain:FindChild("MTX_IncreaseLimit"):Show(nAmount < nMax and self.tStoreLinks[StorefrontLib.CodeEnumStoreLink.HoloWardrobeSlots])
end

function Costumes:OnUnlockItemSelect(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local wndConfirmBtn = self.wndUnlockItems:FindChild("UnlockConfirmBtn")
	local wndCost = self.wndUnlockItems:FindChild("UnlockCost")

	local itemUnlock = wndHandler:GetData()
	local monUnlockCost = itemUnlock:GetCostumeUnlockInfo().monUnlockCost
	wndConfirmBtn:SetActionData(GameLib.CodeEnumConfirmButtonType.UnlockCostumeItem, itemUnlock:GetInventoryId())
	wndCost:SetAmount(monUnlockCost)

	local tUnlockInfo = CostumesLib.GetUnlockItemCount()
	local bCanAfford = monUnlockCost:GetAmount() < GameLib.GetPlayerCurrency():GetAmount()
	local strTextColor = bCanAfford and "UI_TextHoloBodyHighlight" or "Reddish"
	wndCost:SetTextColor(ApolloColor.new(strTextColor))
	local wndUnlockItemBtn = self.wndUnlockItems:FindChild("UnlockConfirmBtn")
	local strUnlockItemCountDisabled = string.format('<P Font="CRB_Button" Align="Center"><T TextColor="UI_BtnTextBlueDisabled">%s</T></P>', String_GetWeaselString(Apollo.GetString("Costumes_UnlockLimitCount"), tostring(tUnlockInfo.nCurrent), tostring(tUnlockInfo.nMax)))
	local strUnlockItemCountEnabled= string.format('<P Font="CRB_Button" Align="Center"><T TextColor="UI_BtnTextBlueNormal">%s</T></P>', String_GetWeaselString(Apollo.GetString("Costumes_UnlockLimitCount"), tostring(tUnlockInfo.nCurrent), { strLiteral = string.format('<T TextColor="LightGold">%d</T>', tUnlockInfo.nMax) }))	
	
	if bCanAfford and tUnlockInfo.nCurrent < tUnlockInfo.nMax then
		wndConfirmBtn:Enable(true)
		local strImportBtn = string.format(strUnlockItemCountEnabled)	
		wndUnlockItemBtn:FindChild("UnlockItemsCount"):SetAML(strImportBtn)

	else
		local strImportBtn = string.format(strUnlockItemCountDisabled)	
		wndUnlockItemBtn:FindChild("UnlockItemsCount"):SetAML(strImportBtn)
	end

	local wndPreview = self.wndUnlockItems:FindChild("ItemPreview")	
	self:SetItemToWindow(wndPreview, itemUnlock)
end

function Costumes:CloseItemUnlock(wndHandler, wndControl)
	self.wndMain:FindChild("UnlockListBlocker"):Show(false)
end

----------------------
-- Wardrobe Item Context Menu Controls
----------------------

function Costumes:OnWardrobeContextShow(wndHandler, wndControl, eMouseBtn, bDoubleClick)
	if eMouseBtn ~= GameLib.CodeEnumInputMouse.Right then
		return
	end
	
	if self.wndContext == nil then 
		self.wndContext = Apollo.LoadForm(self.xmlDoc, "ContextMenu", "TooltipStratum", self)
	end
	
	local itemData = wndHandler:GetData()
	self.wndContext:FindChild("ContextEquipItem"):SetData(wndHandler:FindChild("CostumeListItemBtn"))
	self.wndContext:FindChild("ContextRemoveItem"):SetData(itemData)
	
	local tCursor = Apollo.GetMouse()
	local nWidth = self.wndContext:GetWidth()
	self.wndContext:Move(tCursor.x - nWidth + knXCursorOffset, tCursor.y - knYCursorOffset, nWidth, self.wndContext:GetHeight())
	
	self.wndContext:Invoke()
end

function Costumes:OnContextEquip(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndCostumeItemBtn = wndHandler:GetData()
	
	wndCostumeItemBtn:SetCheck(true)
	self:OnPreviewBtnChecked(wndCostumeItemBtn, wndCostumeItemBtn)
	
	self:OnContextMenuClose()
end

function Costumes:OnRemoveWardrobeItem(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local itemRemoved = wndHandler:GetData()
	
	local wndRemove = self.wndMain:FindChild("ConfirmationOverlay:RemoveItem")
	
	wndRemove:FindChild("AcceptOption"):SetActionData(GameLib.CodeEnumConfirmButtonType.ForgetCostumeItem, itemRemoved:GetItemId())
	wndRemove:FindChild("ItemIcon"):GetWindowSubclass():SetItem(itemRemoved)
	wndRemove:FindChild("ItemName"):SetText(itemRemoved:GetName())
	wndRemove:FindChild("ItemName"):SetTextColor(ktItemQualityToColor[itemRemoved:GetItemQuality()])
	
	local strConfirmText = Apollo.GetString("Costumes_RemoveItemConfirm")
	local strConfirmColor = "UI_TextHoloBody"
	if itemRemoved:IsDeprecated() then
		strConfirmText = Apollo.GetString("Costumes_DeprecatedRemoveConfirm")
		strConfirmColor = "UI_WindowTextRed"
	end
	
	wndRemove:FindChild("ConfirmText"):SetText(strConfirmText)
	wndRemove:FindChild("ConfirmText"):SetTextColor(strConfirmColor)
	
	self:ActivateOverlay(keOverlayType.RemoveItem)
	
	self:OnContextMenuClose()	
end

function Costumes:OnContextMenuClose(wndHandler, wndControl)
	if self.wndContext then
		self.wndContext:Destroy()
		self.wndContext = nil
	end
end

----------------------
-- Preview Window Controls
----------------------
function Costumes:OnSheatheCheck(wndHandler, wndControl)
	self.bIsSheathed = wndControl:IsChecked()
	self.wndPreview:SetSheathed(self.bIsSheathed)
end

function Costumes:OnRotateRight()
	self.wndPreview:ToggleLeftSpin(true)
end

function Costumes:OnRotateRightCancel()
	self.wndPreview:ToggleLeftSpin(false)
end

function Costumes:OnRotateLeft()
	self.wndPreview:ToggleRightSpin(true)
end

function Costumes:OnRotateLeftCancel()
	self.wndPreview:ToggleRightSpin(false)
end

function Costumes:OnGenerateTooltipEquipped(wndHandler, wndControl, eType, itemCurr, idx)
	if wndHandler ~= wndControl then
		return
	end

	local itemData = wndHandler:GetData()
	
	if not itemData then
		return
	end
	
	local strAppend = "<P>" .. Apollo.GetString("Costumes_ListItemsTooltip") .. "</P>"

	-- Checking if this item is actually on the costume.  Otherwise, it's an equipped item
	local eSlot = wndHandler:GetParent():GetData().eSlot

	if eSlot and itemData == self.costumeDisplayed:GetSlotItem(eSlot) then
		if self.nDisplayedCostumeId and self.nDisplayedCostumeId ~= 0 then
			strAppend = strAppend .. "<P>" .. Apollo.GetString("Costumes_RemoveTooltip") .. "</P>"
		else
			strAppend = nil
		end
	end

	if Tooltip and Tooltip.GetItemTooltipForm then
		Tooltip.GetItemTooltipForm(self, wndHandler, itemData, {bSimple = true, strAppend = strAppend})
	end
end

function Costumes:OnGenerateTooltipPreview(wndHandler, wndControl, eType, itemCurr, idx)
	if wndHandler ~= wndControl then
		return
	end
	
	local itemData = wndHandler:GetData()

	local strAppend = "<P>" .. Apollo.GetString("Costumes_CostumeItemTooltip") .. "</P>" .. "<P>" .. Apollo.GetString("Costumes_CostumeItemTooltipRightClick") .. "</P>"
	if itemData and Tooltip and Tooltip.GetItemTooltipForm then
		Tooltip.GetItemTooltipForm(self, wndHandler, itemData, {bSimple = true, strAppend = strAppend})
	end
end

function Costumes:OnGenerateTooltipPreviewDisabled(wndHandler, wndControl, eType, itemCurr, idx)
	if wndHandler ~= wndControl then
		return
	end
	
	local itemData = wndHandler:GetData()
	local tItemCostumeInfo = itemData:GetCostumeUnlockInfo()

	if itemData and Tooltip and Tooltip.GetItemTooltipForm then
		local strAppend = ""
		if tItemCostumeInfo and tItemCostumeInfo.strCanUseFailReason then
			strAppend = "<P TextColor=\"Reddish\">" .. tItemCostumeInfo.strCanUseFailReason .. "</P>" .. "<P>" .. Apollo.GetString("Costumes_CostumeItemTooltipRightClick") .. "</P>"
		end
		Tooltip.GetItemTooltipForm(self, wndHandler, itemData, {bSimple = true, strAppend = strAppend})
	end
end

----------------------
-- Helpers
----------------------
function Costumes:UpdateCost()
	if not self.wndMain then
		return
	end	
	
	local monCostServiceTokens = nil
	local monCost = nil
	if self.costumeDisplayed then
		monCostServiceTokens = self.costumeDisplayed:GetCostOfChanges(true)
		monCost = self.costumeDisplayed:GetCostOfChanges(false)
	else
		monCostServiceTokens = Money.new()
		monCostServiceTokens:SetAccountCurrencyType(AccountItemLib.CodeEnumAccountCurrency.ServiceToken)
		
		monCost = Money.new()
	end

	local wndFooter = self.wndMain:FindChild("Footer")
	local wndSubmit = wndFooter:FindChild("CashBuyBtn")
	wndSubmit:SetActionData(GameLib.CodeEnumConfirmButtonType.SaveCostumeChanges, self.costumeDisplayed, false)
	self:HelperDrawCostBtn(wndSubmit, monCost)
	
	local wndPurchaseServiceTokens = wndFooter:FindChild("PurchaseServiceTokens")
	wndPurchaseServiceTokens:SetData({tActionData = {GameLib.CodeEnumConfirmButtonType.SaveCostumeChanges, self.costumeDisplayed, true,}, monCost = monCostServiceTokens,})
	self:HelperDrawCostBtn(wndPurchaseServiceTokens, monCostServiceTokens)
	
	wndFooter:FindChild("ResetBtn"):Enable(self.costumeDisplayed and self.costumeDisplayed:HasChanges())
end

function Costumes:HelperDrawCostBtn(wndBtn, monCost)
	local wndCash = wndBtn:FindChild("TotalCost")
	wndCash:SetAmount(monCost)

	local bServiceToken = monCost:GetAccountCurrencyType() ~= 0
	local bNonZeroCost = monCost:GetAmount() > 0
	local bHasChanges = self.costumeDisplayed:HasChanges()
	local bCanBuy = self.costumeDisplayed and bHasChanges and 
		(monCost:GetMoneyType() == Money.CodeEnumCurrencyType.Credits and monCost:GetAmount() <= GameLib.GetPlayerCurrency():GetAmount() or monCost:GetAmount() <= AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.ServiceToken):GetAmount())
	
	local bShowServiceToken = bServiceToken and bNonZeroCost
	local bPurchaseEnable = bHasChanges and bCanBuy and (bShowServiceToken or not bServiceToken)
	
	local strColor = "UI_WindowTextDefault"
	if not bPurchaseEnable then
		strColor = "ConTrivial"
	elseif not bCanBuy then
		strColor = "UI_WindowTextRed"
	end
	wndCash:SetTextColor(strColor)

	wndBtn:Enable(bPurchaseEnable)
	return
end

function Costumes:OnPurchaseServiceTokens(wndHandler, wndControl)
	local tPurchaseData = wndControl:GetData()
	
	local tData = 
	{	
		wndParent = self.wndMain:FindChild("ConfirmationOverlay"),
		strEventName = "ServiceTokenClosed_Costumes",
		monCost = tPurchaseData.monCost,
		strConfirmation = String_GetWeaselString(Apollo.GetString("ServiceToken_Confirm"), Apollo.GetString("Dyeing_WindowTitle")),
		tActionData = tPurchaseData.tActionData,
	}
	
	self:ActivateOverlay(keOverlayType.ServiceToken)	
	Event_FireGenericEvent("GenericEvent_ServiceTokenPrompt", tData)
end

function Costumes:OnServiceTokenClosed_Costumes(strParent)
	self:ClearOverlay()
end

function Costumes:EntitlementUpdated(tEntitlementInfo)
	if self.wndMain and tEntitlementInfo.nEntitlementId == AccountItemLib.CodeEnumEntitlement.CostumeSlots then
		self:UpdateCostumeList()
	elseif (self.wndMain or self.wndUnlock) and tEntitlementInfo.nEntitlementId == AccountItemLib.CodeEnumEntitlement.AdditionalCostumeUnlocks then
		self:BuildUnlockList()
	end
end

function Costumes:UpdateCostumeList()
	-- We don't want this to run for mannequins
	if self.unitPlayer ~= GameLib.GetPlayerUnit() or not self.wndMain then
		return
	end

	if not self.wndMain then
		return
	end
	
	local nMaxCostumes = CostumesLib.GetCostumeMaxCount()
	local nCurrentCostumeCount = CostumesLib.GetCostumeCount()
	local wndCostumeList = self.wndMain:FindChild("Left:CostumeBtnHolder:Framing")
	
	if nCurrentCostumeCount < self.nUnlockedCostumeCount then
		-- shrink list
		for idx = nCurrentCostumeCount + 1, self.nUnlockedCostumeCount do
			wndCostumeList:FindChild("CostumeBtn"..(idx)):Destroy()
			-- selection was just destroyed so select 'no costume'
			if self.nDisplayedCostumeId == idx then
				local wndCostumeBtn = wndCostumeList:FindChild("CostumeBtn")
				wndCostumeBtn:SetCheck(true)
				self.nDisplayedCostumeId = wndCostumeBtn:GetData()
				self.costumeDisplayed = CostumesLib.GetCostume(self.nDisplayedCostumeId)
	
				local strCostumeName = wndCostumeBtn:GetText()
				self.wndMain:FindChild("Left:CostumeBtnHolder"):Show(false)
				self.wndMain:FindChild("Left:SelectCostumeWindowToggle"):SetText(strCostumeName)
	
				self.tSelectedDyeChannels = {}
	
				self:ResetChannelControls()
				self:HideContentContainer()
				self:RedrawCostume()
			end
		end
	elseif nCurrentCostumeCount > self.nUnlockedCostumeCount then
		-- grow list
		local wndCostumeBtn = self.wndMain:FindChild("CostumeBtn"..nCurrentCostumeCount)
		if wndCostumeBtn then
			wndCostumeBtn:ChangeArt("BK3:btnHolo_ListView_Mid")
		end
		for idx = self.nUnlockedCostumeCount + 1, nCurrentCostumeCount do
			local wndCostumeBtn = wndCostumeList:FindChild("CostumeBtn" .. (idx))
			if not wndCostumeBtn then
				wndCostumeBtn = Apollo.LoadForm(self.xmlDoc, "CostumeBtn", wndCostumeList, self)
				wndCostumeBtn:SetName("CostumeBtn" .. (idx))
			end
			local strLabel = String_GetWeaselString(Apollo.GetString("Character_CostumeNum"), idx)
			wndCostumeBtn:SetText(strLabel)
			wndCostumeBtn:SetData(idx)
			if idx == nCurrentCostumeCount and nCurrentCostumeCount == nMaxCostumes then
				wndCostumeBtn:ChangeArt("BK3:btnHolo_ListView_Btm") -- bottom button gets rounded bottom edges
			end
			if self.nDisplayedCostumeId == idx then
				wndCostumeBtn:SetCheck(true)
				self.wndMain:FindChild("Left:SelectCostumeWindowToggle"):SetText(strLabel)
			end
		end
	end
	local wndCostumeBtnMTX = wndCostumeList:FindChild("CostumeBtnMTX")
	self.nUnlockedCostumeCount = nCurrentCostumeCount
	if self.nUnlockedCostumeCount < nMaxCostumes and self.tStoreLinks[StorefrontLib.CodeEnumStoreLink.CostumeSlots] then
		if wndCostumeBtnMTX == nil then
			local wndCostumeBtnMTX = Apollo.LoadForm(self.xmlDoc, "CostumeBtnMTX", wndCostumeList, self)
			wndCostumeBtnMTX:ChangeArt("BK3:btnHolo_ListView_Btm") -- bottom button gets rounded bottom edges
			wndCostumeBtnMTX:SetData(nMaxCostumes)
		end
	elseif wndCostumeBtnMTX then
		wndCostumeBtnMTX:Destroy()
	end
		
	local nButtonListHeight = wndCostumeList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndFirst, wndSecond) return wndFirst:GetData() < wndSecond:GetData() end)

	local nLeft, nTop, nRight, nBottom = self.wndMain:FindChild("CostumeBtnHolder"):GetAnchorOffsets()
	self.wndMain:FindChild("CostumeBtnHolder"):SetAnchorOffsets(nLeft, nTop, nRight, nTop + nButtonListHeight + knCostumeBtnHolderBuffer)
end

function Costumes:UpdateItemCount()
	local tUnlockInfo = CostumesLib.GetUnlockItemCount()
	local bShowFlair = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.AdditionalCostumeUnlocks) > 0

	local strUnlockedCurrent = tostring(tUnlockInfo.nCurrent)
	local strUnlockedMax
	if bShowFlair then
		strUnlockedMax = string.format('<T TextColor="LightGold">%d</T>', tUnlockInfo.nMax)
	else
		strUnlockedMax = tostring(tUnlockInfo.nMax)
	end
	
	if self.wndMain then
		local wndImportBtn = self.wndMain:FindChild("Center:HelpContentContainer:UnlockItemsBtn")
		local strImportText = string.format('<P Font="CRB_Button" Align="Center"><T TextColor="UI_BtnTextBlueNormal">%s</T></P>', String_GetWeaselString(Apollo.GetString("Costumes_UnlockLimitCount"), strUnlockedCurrent, { strLiteral = strUnlockedMax }))
		wndImportBtn:FindChild("UnlockItemsCount"):SetAML(strImportText)

		local wndUnlockItemBtn = self.wndMain:FindChild("UnlockListBlocker:UnlockList:UnlockConfirmBtn")
		local strUnlockText = string.format('<P Font="CRB_Button" Align="Center"><T TextColor="UI_BtnTextBlueNormal">%s</T></P>', String_GetWeaselString(Apollo.GetString("Costumes_UnlockLimitCount"), strUnlockedCurrent, { strLiteral = strUnlockedMax }))
		wndUnlockItemBtn:FindChild("UnlockItemsCount"):SetAML(strUnlockText)
	end
	
	if self.wndUnlock then
		local wndContainer = self.wndUnlock:FindChild("Hologram")
		if tUnlockInfo.nCurrent < tUnlockInfo.nMax then
			local strUnlockItemCountEnabled = string.format('<P Font="CRB_Button" Align="Center"><T TextColor="UI_BtnTextBlueNormal">%s</T></P>', String_GetWeaselString(Apollo.GetString("Costumes_UnlockLimitCount"), tostring(tUnlockInfo.nCurrent), { strLiteral = string.format('<T TextColor="LightGold">%d</T>', tUnlockInfo.nMax) }))	
			wndContainer:FindChild("ConfirmBtn"):Enable(true)
			local strImportBtn = string.format(strUnlockItemCountEnabled)	
			wndContainer:FindChild("CostumeItemCount"):SetAML(strImportBtn)
		else
			local strUnlockItemCountDisabled = string.format('<P Font="CRB_Button" Align="Center"><T TextColor="UI_BtnTextBlueDisabled">%s</T></P>', String_GetWeaselString(Apollo.GetString("Costumes_UnlockLimitCount"), tostring(tUnlockInfo.nCurrent), tostring(tUnlockInfo.nMax)))
			wndContainer:FindChild("ConfirmBtn"):Enable(false)
			local strImportBtn = string.format(strUnlockItemCountDisabled)	
			wndContainer:FindChild("CostumeItemCount"):SetAML(strImportBtn)
		end
	end
end
		
function Costumes:RefreshStoreLink()
	self.tStoreLinks[StorefrontLib.CodeEnumStoreLink.CostumeSlots] = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.CostumeSlots)
	self.tStoreLinks[StorefrontLib.CodeEnumStoreLink.HoloWardrobeSlots] = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.HoloWardrobeSlots)
	self.tStoreLinks[StorefrontLib.CodeEnumStoreLink.Dyes] = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.Dyes)
	self:UpdateCostumeList()
	self:UpdateItemCount()

	if not self.wndMain then
		return
	end
end

function Costumes:UnlockMoreCostumes()
	self.wndMain:FindChild("Left:CostumeBtnHolder"):Show(false)
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.CostumeSlots)
end

function Costumes:UnlockItemSlots()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.HoloWardrobeSlots)
end

function Costumes:HideContentContainer()
	self.wndMain:FindChild("ContentContainer"):Show(false)
	self.wndMain:FindChild("HelpContentContainer"):Show(true)
end

function Costumes:HelperToggleEquippedBtn()
	local wndEquip = self.wndMain:FindChild("Left:EquipBtn")
	local bEquipped = self.nDisplayedCostumeId == CostumesLib.GetCostumeIndex()
	local strLabel = bEquipped and Apollo.GetString("EngravingStation_Equipped") or Apollo.GetString("CRB_Equip")
	
	wndEquip:Enable(not bEquipped)
	wndEquip:SetText(strLabel)
end

function Costumes:ShowDyeContent()
	local wndContainer = self.wndMain:FindChild("ContentContainer")
	self.wndMain:FindChild("HelpContentContainer"):Show(false)
	wndContainer:Show(true)
	
	self.wndMain:FindChild("ContentSearch"):SetText("")
	
	wndContainer:FindChild("CostumeWindows"):Show(false)
	wndContainer:FindChild("DyeList"):Show(true)
	self.wndMain:FindChild("MTX_Dyes"):Show(self.tStoreLinks[StorefrontLib.CodeEnumStoreLink.Dyes])
end

function Costumes:ShowCostumeContent()
	local wndContainer = self.wndMain:FindChild("ContentContainer")
	local tItemInfo = CostumesLib.GetUnlockItemCount()
	self.wndMain:FindChild("HelpContentContainer"):Show(false)
	wndContainer:Show(true)

	self.wndMain:FindChild("ContentSearch"):SetText("")
	
	wndContainer:FindChild("DyeList"):Show(false)
	self.wndMain:FindChild("MTX_Dyes"):Show(false)
	wndContainer:FindChild("CostumeWindows"):Show(true)
end

function Costumes:SetHelpString(strText)
	local wndContainer = self.wndMain:FindChild("TextBlock")
	local wndText = wndContainer:FindChild("HelpText")
	local nDiff = wndContainer:GetHeight() - wndText:GetHeight() 
	
	wndText:SetText(strText)
	local nTextWidth, nTextHeight = wndText:SetHeightToContentHeight()
	
	local nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	wndContainer:SetAnchorOffsets(nLeft, nBottom - nTextHeight - nDiff, nRight, nBottom)	
end

function Costumes:OnForgetResult(itemRemoved, eResult)
	if eResult == CostumesLib.CostumeUnlockResult.ForgetItemSuccess then
		self:ClearOverlay()

		-- Rebuild the current page
		local eSlot = ktItemSlotToEquippedItems[itemRemoved:GetSlot()]
		self.tUnlockedItems[eSlot] = CostumesLib.GetUnlockedSlotItems(eSlot, self.bShowUnusable)

		if self.eSelectedSlot and self.eSelectedSlot == eSlot then
			self.arDisplayedItems = self.tUnlockedItems[eSlot]
			self:SortDisplayedItems()
		
			self:HelperUpdatePageItems((self.wndMain:FindChild("PageDown"):GetData() or 0) + 1)
		end
		
		if self.tCostumeSlots[eSlot]:FindChild("CostumeIcon"):GetData() == itemRemoved then
			self:EmptySlot(eSlot, true)
		end
	elseif eResult ~= CostumesLib.CostumeUnlockResult.ForgetRequested then
		self.wndMain:FindChild("ConfirmationOverlay:ErrorPanel:ConfirmText"):SetText(ktUnlockFailureStrings[eResult] or ktUnlockFailureStrings[CostumesLib.CostumeUnlockResult.UnknownFailure])
		
		self:ActivateOverlay(keOverlayType.Error)
		
		self.timerError = ApolloTimer.Create(2.0, false, "OnHideError", self)
		self.timerError:Start()
	end
end

function Costumes:OnSaveResult(eCostumeType, nCostumeIdx, eResult)
	if not self.wndMain or eResult == CostumesLib.CostumeSaveResult.Saving then
		return
	end
	
	if eResult == CostumesLib.CostumeSaveResult.Saved then
		self.wndMain:FindChild("PurchaseConfirmFlash"):SetSprite("BK3:UI_BK3_Holo_RefreshReflectionSquare_anim")

		-- Need to get a new instance of the costume every time we save
		if self.unitPlayer == GameLib.GetPlayerUnit() then
			CostumesLib.SetCostumeIndex(self.nDisplayedCostumeId)
			self.costumeDisplayed = CostumesLib.GetCostume(self.nDisplayedCostumeId)
		else
			self.costumeDisplayed = CostumesLib.GetActiveMannequinCostume()
		end

		self:ResetChannelControls()
		self:RedrawCostume()
		self:HideContentContainer()
		self:UpdateCost()
	else
		self.wndMain:FindChild("ConfirmationOverlay:ErrorPanel:ConfirmText"):SetText(ktSaveFailureStrings[eResult] or ktSaveFailureStrings[CostumesLib.CostumeSaveResult.UnknownError])
		
		self:ActivateOverlay(keOverlayType.Error)
		
		self.timerError = ApolloTimer.Create(2.0, false, "OnHideError", self)
		self.timerError:Start()
	end
end

function Costumes:OnHideError()
	self:ClearOverlay()
end

function Costumes:ClearOverlay()
	local wndOverlay = self.wndMain:FindChild("ConfirmationOverlay")
	for idx, wndChild in pairs(wndOverlay:GetChildren()) do
		wndChild:Show(false)
	end
	wndOverlay:Show(false)
end

function Costumes:ActivateOverlay(eType)
	self:ClearOverlay()
	
	local wndOverlay = self.wndMain:FindChild("ConfirmationOverlay")
	
	if eType == keOverlayType.UndoClose then
		local wndUndoPanel = wndOverlay:FindChild("UndoPanel")
		wndUndoPanel:Show(true)
		wndUndoPanel:FindChild("AcceptOption"):SetData(eType)
		wndOverlay:Show(true)
	elseif eType == keOverlayType.UndoSwap then
		local wndUndoSwapPanel = wndOverlay:FindChild("UndoPanel")
		wndUndoSwapPanel:Show(true)
		wndUndoSwapPanel:FindChild("AcceptOption"):SetData(eType)
		wndOverlay:Show(true)
	elseif eType == keOverlayType.RemoveItem then
		wndOverlay:FindChild("RemoveItem"):Show(true)
		wndOverlay:Show(true)
	elseif eType == keOverlayType.ServiceToken then
		wndOverlay:Show(true)
	elseif eType == keOverlayType.Error then
		wndOverlay:FindChild("ErrorPanel"):Show(true)
		wndOverlay:Show(true)
	end
end

function Costumes:OnEquipThrottled()
	if self.wndMain then
		local wndEquipBtn = self.wndMain:FindChild("Left:EquipBtn")
		wndEquipBtn:Enable(false)
		wndEquipBtn:SetText(Apollo.GetString("Launcher_PlayButton_Waiting"))
	end
end

function Costumes:OnThrottleEnd()
	if self.wndMain then
		self:HelperToggleEquippedBtn()
	end
end

function Costumes:UpdateDisplayedItemList(eSlot)
	self.arDisplayedItems = self.tUnlockedItems[eSlot]
	
	local wndSearchBar = self.wndMain:FindChild("ContentSearch")
	-- OnSearchContent will also sort
	self:OnSearchContent(wndSearchBar, wndSearchBar, wndSearchBar:GetText())
end

function Costumes:SortDisplayedItems()
	local function SortItems(itemA, itemB)
		local tCostumeInfoA = itemA:GetCostumeUnlockInfo()
		local tCostumeInfoB = itemB:GetCostumeUnlockInfo()
		
		if tCostumeInfoA.bCanUseInCostume and not tCostumeInfoB.bCanUseInCostume then
			return true
		elseif tCostumeInfoA.bCanUseInCostume == tCostumeInfoB.bCanUseInCostume then
			if tCostumeInfoA.bCanUseInCostume then
				return itemA:GetName() < itemB:GetName()
			else
				local eCategoryA = itemA:GetItemCategory() 
				local eCategoryB = itemB:GetItemCategory()
				
				if eCategoryA == eCategoryB then
					return itemA:GetName() < itemB:GetName()
				else
					return eCategoryA < eCategoryB
				end
			end
		else
			return false
		end
	end
	
	table.sort(self.arDisplayedItems, SortItems)
end

function Costumes:SetItemToWindow(wndCostume, itemDisplay)
	local strCamera = nil
	local idModel = nil
	
	local eItemSlot = ktItemSlotToEquippedItems[itemDisplay:GetSlot()]
	if eItemSlot == GameLib.CodeEnumItemSlots.Weapon then
		strCamera = ktItemCategoryToCamera[itemDisplay:GetItemCategory()]
		idModel = knWeaponModelId
		
		if not strCamera then
			local arRequirementInfo = itemDisplay:GetRequiredClass()
			local eRequiredClass = nil
			if #arRequirementInfo > 1 or #arRequirementInfo == 0 then
				eRequiredClass = GameLib.GetPlayerUnit():GetClassId()
			else
				eRequiredClass = arRequirementInfo[1].idClassReq
			end
			
			strCamera = ktClassToWeaponCamera[eRequiredClass]
		end
	else
		strCamera = ktItemSlotToCamera[eItemSlot]
		idModel = ktManneqinIds[GameLib.GetPlayerUnit():GetGender()]
	end
	
	wndCostume:SetCostumeToCreatureId(idModel)
	wndCostume:SetCamera(strCamera)
	
	wndCostume:SetItem(itemDisplay)
end

-----------------------------------------------------------------------------------------------
-- Store / Upsell Management
-----------------------------------------------------------------------------------------------

function Costumes:OnPurchaseMoreDyes()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.Dyes)
end

----------------------
-- Instance
----------------------
local CostumesInstance = Costumes:new()
CostumesInstance:Init()
