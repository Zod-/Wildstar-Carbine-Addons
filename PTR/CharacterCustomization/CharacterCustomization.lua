-----------------------------------------------------------------------------------------------
-- Client Lua Script for CharacterCustomization
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
require "StorefrontLib"
 
-----------------------------------------------------------------------------------------------
-- CharacterCustomization Module Definition
-----------------------------------------------------------------------------------------------
local CharacterCustomization = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local knTokenItemId = 50763
local knStaticAnimationValue = 5612

local knRaceGenderSliderId = 27
local knBoneSliderId = -1

local ktOverlayTypes =
{
	Purchase = 1,
	Cancel = 2,
	Code = 3,
}

local ktExileMaleRaceIcons =
{
	-- Exile Male
	[GameLib.CodeEnumRace.Granok] = "charactercreate:sprCharC_Finalize_RaceGranokM",
	[GameLib.CodeEnumRace.Aurin] = "charactercreate:sprCharC_Finalize_RaceAurinM",
	[GameLib.CodeEnumRace.Human] = "charactercreate:sprCharC_Finalize_RaceExileM",
	[GameLib.CodeEnumRace.Mordesh] = "charactercreate:sprCharC_Finalize_RaceMordeshM",
}

local ktExileFemaleRaceIcons =
{
	-- Exile Female
	[GameLib.CodeEnumRace.Granok] = "charactercreate:sprCharC_Finalize_RaceGranokF",
	[GameLib.CodeEnumRace.Aurin] = "charactercreate:sprCharC_Finalize_RaceAurinF",
	[GameLib.CodeEnumRace.Human] = "charactercreate:sprCharC_Finalize_RaceExileF",
	[GameLib.CodeEnumRace.Mordesh] = "charactercreate:sprCharC_Finalize_RaceMordeshF",
}

local ktDominionMaleRaceIcons =
{
	-- Dominion Male
	[GameLib.CodeEnumRace.Human] = "charactercreate:sprCharC_Finalize_RaceDomM",
	[GameLib.CodeEnumRace.Draken] = "charactercreate:sprCharC_Finalize_RaceDrakenM",
	[GameLib.CodeEnumRace.Mechari] = "charactercreate:sprCharC_Finalize_RaceMechariM",
	[GameLib.CodeEnumRace.Chua] = "charactercreate:sprCharC_Finalize_RaceChua",
}

local ktDominionFemaleRaceIcons =
{	
	-- Dominion Female
	[GameLib.CodeEnumRace.Human] = "charactercreate:sprCharC_Finalize_RaceDomF",
	[GameLib.CodeEnumRace.Draken] = "charactercreate:sprCharC_Finalize_RaceDrakenF",
	[GameLib.CodeEnumRace.Mechari] = "charactercreate:sprCharC_Finalize_RaceMechariF",
}

local ktRaceStrings =
{
	[GameLib.CodeEnumRace.Human]	= Apollo.GetString("RaceHuman"),
	[GameLib.CodeEnumRace.Granok]	= Apollo.GetString("CRB_DemoCC_Granok"),
	[GameLib.CodeEnumRace.Aurin]	= Apollo.GetString("CRB_DemoCC_Aurin"),
	[GameLib.CodeEnumRace.Draken]	= Apollo.GetString("RaceDraken"),
	[GameLib.CodeEnumRace.Mechari]	= Apollo.GetString("RaceMechari"),
	[GameLib.CodeEnumRace.Mordesh]	= Apollo.GetString("CRB_Mordesh"),
	[GameLib.CodeEnumRace.Chua]		= Apollo.GetString("RaceChua"),
}

local ktGenderStrings =
{
	[Unit.CodeEnumGender.Male] 		= Apollo.GetString("CRB_Male"),
	[Unit.CodeEnumGender.Female] 	= Apollo.GetString("CRB_Female"),
}

local ktFactionStrings =
{
	[Unit.CodeEnumFaction.DominionPlayer] 	= Apollo.GetString("CRB_Dominion"),
	[Unit.CodeEnumFaction.ExilesPlayer] 	= Apollo.GetString("CRB_Exile"),
}

local ktEntitlementStoreEnums =
{
	[AccountItemLib.CodeEnumEntitlement.ChuaWarriorUnlock]		= StorefrontLib.CodeEnumStoreLink.ChuaWarrior,
	[AccountItemLib.CodeEnumEntitlement.AurinEngineerUnlock]	= StorefrontLib.CodeEnumStoreLink.AurinEngineer,
}

local ktFaceSliderIds =
{
	[1] 	= true,
	[21] 	= true,
	[22] 	= true,
}

local ktCustomizeBodyType = 
{
	[2] 	= true,
	[25] 	= true,
}
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function CharacterCustomization:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function CharacterCustomization:Init()
	local tDependencies = {}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- CharacterCustomization OnLoad
-----------------------------------------------------------------------------------------------
function CharacterCustomization:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("CharacterCustomization.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- CharacterCustomization OnDocLoaded
-----------------------------------------------------------------------------------------------
function CharacterCustomization:OnDocLoaded()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
		return
	end
	
	Apollo.RegisterEventHandler("ShowDye", "OnInit", self)
	Apollo.RegisterEventHandler("HideDye", "OnHideDye", self)
	Apollo.RegisterEventHandler("PlayerCurrencyChanged", "UpdateCost", self)
	Apollo.RegisterEventHandler("AccountCurrencyChanged", "UpdateCost", self)

	--ServiceTokenPrompt
	Apollo.RegisterEventHandler("ServiceTokenClosed_CharacterCustomization", "OnServiceTokenClosed_CharacterCustomization", self)
	
	--StoreEvents
	Apollo.RegisterEventHandler("StoreLinksRefresh", "RefreshStoreLink", self)
	
	self.bHideHelm = true
	self.bLinkAvailable = false
end

--Init
function CharacterCustomization:OnInit()
	if not GameLib.IsCharacterLoaded() or self.wndMain then
		return
	end

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "CharacterCustomization", nil, self)
	self.wndPreview = self.wndMain:FindChild("RightContent:Costume")
	
	local unitPlayer = GameLib.GetPlayerUnit()
	self.wndPreview:SetCostume(unitPlayer)
	self.wndPreview:SetModelSequence(knStaticAnimationValue)
	
	-- determines if the Hide Helm button should be active
	local costumeDisplayed = CostumesLib.GetCostume(CostumesLib.GetCostumeIndex())
	self.itemDisplayedHelm = nil
	
	if costumeDisplayed then
		self.bEnableHelmSwap = costumeDisplayed:IsSlotVisible(GameLib.CodeEnumItemSlots.Head)
		self.itemDisplayedHelm = costumeDisplayed:GetSlotItem(GameLib.CodeEnumItemSlots.Head)
	end
	
	if not self.itemDisplayedHelm or not costumeDisplayed then
		for idx, itemEquipment in pairs(unitPlayer:GetEquippedItems()) do
			if itemEquipment:GetSlot() == GameLib.CodeEnumEquippedItems.Head then
				self.itemDisplayedHelm = itemEquipment
			end
		end
		
		self.bEnableHelmSwap = self.itemDisplayedHelm ~= nil
	end
	
	local wndHideHelm = self.wndMain:FindChild("RightContent:HideHelmBtn")
	wndHideHelm:Enable(self.bEnableHelmSwap)
	wndHideHelm:SetCheck(self.bHideHelm)
	
	if self.bEnableHelmSwap and self.bHideHelm then
		self:OnHideHelm()
	end
	
	local nRaceGenderSliderId = self.wndPreview:GetRaceSliderId()
	if not nRaceGenderSliderId then
		self.wndMain:Close()
		return
	end
	knRaceGenderSliderId = nRaceGenderSliderId
	
	-- Load character options, build category buttons, refresh Cost
	self:LoadCategoryHeaders()
	self:UpdateCost()
	self.wndMain:Invoke()
	self:RefreshStoreLink()
end

function CharacterCustomization:LoadCategoryHeaders()
	local wndCustomizationContainer = self.wndMain:FindChild("LeftContainer:CategoryScrollContainer")
		
	-- Race/Gender change
	local wndRaceHeader = Apollo.LoadForm(self.xmlDoc, "RaceCategoryHeader", wndCustomizationContainer, self)
	local wndRaceCategorySelectBtn = wndRaceHeader:FindChild("CategorySelectBtn")
	wndRaceCategorySelectBtn:SetText(Apollo.GetString("CharacterCustomization_RaceGender"))
	local tData = 
	{
		idSlider = knRaceGenderSliderId,
		wndGroupContents = wndRaceHeader:FindChild("GroupContents"),
	}
	wndRaceCategorySelectBtn:SetData(tData)
	wndRaceHeader:SetData(knRaceGenderSliderId)
	
	-- Customization Options
	self:ReloadCustomizationHeaders()

	wndCustomizationContainer:ArrangeChildrenVert()
end

function CharacterCustomization:ReloadCustomizationHeaders()
	local wndCustomizationContainerChildren = self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"):GetChildren()
	if #wndCustomizationContainerChildren > 0 then
		for idx, wndChild in pairs(wndCustomizationContainerChildren) do
			childName = wndChild:GetName()
			if childName ~= "RaceCategoryHeader" then
				wndChild:Destroy()
			else
				local wndCategorySelectBtn = wndChild:FindChild("CategorySelectBtn")
				self:OnRaceCategoryCheck(wndCategorySelectBtn,wndCategorySelectBtn) 
			end
		end
	end
	
	local arCurrentCustomizationOptions = self.wndPreview:GetLooks()

	-- We want to make sure we're loading the Face and Face Customization first and together
	for idx, tCategory in pairs(arCurrentCustomizationOptions) do
		if ktFaceSliderIds[tCategory.sliderId] then
			self:LoadHeader(tCategory)
			self:LoadBonesHeader(tCategory)
		end
	end
	for idx, tCategory in pairs(arCurrentCustomizationOptions) do
		if not ktFaceSliderIds[tCategory.sliderId] then
			self:LoadHeader(tCategory)
		end
	end	
end

function CharacterCustomization:LoadBonesHeader()
	local wndBoneHeader = Apollo.LoadForm(self.xmlDoc, "BoneCategoryHeader", self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"), self)
	local wndBoneCategorySelectBtn = wndBoneHeader:FindChild("CategorySelectBtn")
	wndBoneCategorySelectBtn:SetText(Apollo.GetString("CharacterCustomize_CustomizeFace"))
	local tData = 
	{
		idSlider = knBoneSliderId,
		wndGroupContents = wndBoneHeader:FindChild("GroupContents"),
	}
		
	wndBoneCategorySelectBtn:SetData(tData)	
	wndBoneHeader:SetData(knBoneSliderId)
end

function CharacterCustomization:LoadHeader(tCategory)
	local wndHeader = Apollo.LoadForm(self.xmlDoc, "CategoryHeader", self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"), self)

	wndHeader:SetData(tCategory.sliderId)
	local wndCategorySelectBtn = wndHeader:FindChild("CategorySelectBtn")
	wndCategorySelectBtn:SetText(tCategory.name)
	local tData = 
	{
		idSlider = tCategory.sliderId,
		wndGroupContents = wndHeader:FindChild("GroupContents"),
	}
	wndCategorySelectBtn:SetData(tData)
	
	local tValues = self.wndPreview:GetAppearanceValues(tCategory.sliderId)
	wndHeader:FindChild("CategorySelectBtn:ElementChangedIcon"):Show(tValues.bChanged)
end

-----------------------------------------------------------------------------------------------
-- Race Options
-----------------------------------------------------------------------------------------------

function CharacterCustomization:OnRaceCategoryCheck(wndHandler, wndControl)
	-- Builds the list of options buttons
	local wndContainer = wndControl:GetData().wndGroupContents
	wndContainer:DestroyChildren()
	
	local unitPlayer = GameLib.GetPlayerUnit()
	local nUnitPlayerFaction =  unitPlayer:GetFaction()
	local nUnitPlayerRace = unitPlayer:GetRaceId()
	local nUnitPlayerSex = unitPlayer:GetGender()
	
	local tRaces = self.wndPreview:GetAvailableRaces()
	if tRaces ~= nil then
		for idx, tRaceGender in pairs(tRaces.arRaces) do
			local wndOption = Apollo.LoadForm(self.xmlDoc, "RaceOptionItem", wndContainer, self)
			wndOption:SetData(tRaceGender)

			local strGender = tRaceGender.idRace == GameLib.CodeEnumRace.Chua and "" or String_GetWeaselString(Apollo.GetString("CRB_Parenthese"), ktGenderStrings[tRaceGender.idGender])
			wndOption:SetTooltip(string.format("%s %s", ktRaceStrings[tRaceGender.idRace], strGender))

			local wndOptionPreview = wndOption:FindChild("RaceOptionBtn")
			wndOptionPreview:SetData(tRaceGender)
			local wndRaceWindow = wndOption:FindChild("RaceWindow")
			
			local spriteString = nil
			
			if nUnitPlayerFaction == Unit.CodeEnumFaction.DominionPlayer then
				if tRaceGender.idGender == Unit.CodeEnumGender.Male then
					spriteString = ktDominionMaleRaceIcons[tRaceGender.idRace]
				else
					spriteString = ktDominionFemaleRaceIcons[tRaceGender.idRace]
				end
			else
				if tRaceGender.idGender == Unit.CodeEnumGender.Male then
					spriteString = ktExileMaleRaceIcons[tRaceGender.idRace]
				else
					spriteString = ktExileFemaleRaceIcons[tRaceGender.idRace]
				end
			end
			
			if spriteString ~= nil then
				wndRaceWindow:SetSprite(spriteString)
			end
			
			wndOptionPreview:Enable(tRaceGender.bAvailable)
			
			if not tRaceGender.bAvailable then
				wndOption:FindChild("StoreBanner"):Show(true)
				wndRaceWindow:SetBGOpacity(0.25)
				wndOptionPreview:Enable(self.bLinkAvailable)
			end
			
			if tRaceGender.idRace == nUnitPlayerRace and tRaceGender.idGender == nUnitPlayerSex then
				local tPixieOverlay =
				{
					strSprite = "bk3:UI_BK3_Options_Telegraph_Outline",
					loc = {fPoints = {0, 0, 1, 1}, nOffsets = {-6, -6, 5, 6}}
				}
				wndRaceWindow:AddPixie(tPixieOverlay)
			end
			
			if tRaceGender.bCurrent then
				wndOptionPreview:SetCheck(true)
			end
		end
	end
	
	wndContainer:ArrangeChildrenTiles()
	wndContainer:Show(false)
	
	wndContainer:Invoke()
	self:UpdateHelper()
	self:ResizeTree()
	self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"):ArrangeChildrenVert()
end

function CharacterCustomization:OnRaceCategoryUncheck(wndHandler, wndControl)
	self.wndMain:SetGlobalRadioSel("CharacterCustomization_SelectedOption", -1)
	self.idSelectedCategory = nil
	
	wndControl:GetData().wndGroupContents:DestroyChildren()
	self:UpdateHelper()
	self:ResizeTree()
	
	self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"):ArrangeChildrenVert()
end


function CharacterCustomization:OnRaceOptionCheck(wndHandler, wndControl)
	local tRaceGender = wndControl:GetData()
	
	if tRaceGender.bAvailable ~= true then
		self:RaceUnavailable(tRaceGender)
		return
	end
	
	self.wndPreview:SetRaceAndGender(tRaceGender.idRace, tRaceGender.idGender)
	
	self:ReloadCustomizationHeaders()
	self:UpdateCost()
	self:ResizeTree()
	self:UpdateHelper()
end


-----------------------------------------------------------------------------------------------
-- Customization Options
-----------------------------------------------------------------------------------------------

function CharacterCustomization:LoadCustomizationOptions(tData)
	local wndContainer = tData.wndGroupContents
	wndContainer:DestroyChildren()

	local tCategoryInfo = self.wndPreview:GetAppearanceValues(tData.idSlider)
	if tCategoryInfo == nil then
		return
	end

	local arValues = tCategoryInfo.arValues
	for idx, nValue in pairs(arValues) do
		local wndOption = Apollo.LoadForm(self.xmlDoc, "OptionItem", wndContainer, self)
		
		local wndOptionPreview = wndOption:FindChild("CostumeWindow")
		if not wndOptionPreview:SetCostumeFromCostumeWindow(self.wndPreview) then
			return
		end
		
		wndOptionPreview:SetLook(tData.idSlider, nValue)
		if nValue == tCategoryInfo.nOriginalValue then
			local tPixieOverlay =
			{
				strSprite = "bk3:UI_BK3_Options_Telegraph_Outline",
				loc = {fPoints = {0, 0, 1, 1}, nOffsets = {-6, -6, 5, 6}}
			}
			wndOptionPreview:AddPixie(tPixieOverlay)
		end
		
		if nValue == tCategoryInfo.nCurrentValue then
			wndOption:FindChild("OptionBtn"):SetCheck(true)
		end
		
		wndOptionPreview:SetCamera(ktCustomizeBodyType[tData.idSlider] and "Paperdoll" or "Portrait")
		local tSliderValue =
		{
			idSlider = tData.idSlider,
			nValue = nValue,
		}
		wndOption:FindChild("OptionBtn"):SetData(tSliderValue)
		
		if self.bEnableHelmSwap and self.wndMain:FindChild("RightContent:HideHelmBtn"):IsChecked() then
			wndOptionPreview:RemoveItem(GameLib.CodeEnumItemSlots.Head)
		end
		
		wndOptionPreview:SetAnimated(false)
	end
	wndContainer:Invoke()
	wndContainer:ArrangeChildrenTiles()
end

function CharacterCustomization:OnCategoryCheck(wndHandler, wndControl)
	local tData = wndControl:GetData()
	
	self.wndPreview:SetCamera(ktCustomizeBodyType[tData.idSlider] and "Paperdoll" or "Portrait")
	self:LoadCustomizationOptions(tData)
	
	self:UpdateHelper()
	self:ResizeTree()
	self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"):ArrangeChildrenVert()
end

function CharacterCustomization:OnCategoryUncheck(wndHandler, wndControl)
	self.wndMain:SetGlobalRadioSel("CharacterCustomization_SelectedOption", -1)
	
	local tData = wndControl:GetData()
	tData.wndGroupContents:DestroyChildren()
	self:UpdateHelper()
	self:ResizeTree()
	
	self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"):ArrangeChildrenVert()
end

function CharacterCustomization:OnOptionCheck(wndHandler, wndControl)
	local tSliderValue = wndHandler:GetData()
	self.wndPreview:SetLook(tSliderValue.idSlider, tSliderValue.nValue)
	
	if ktFaceSliderIds[tSliderValue.idSlider] then
		local arBones = self.wndPreview:GetBones()
		for idx, tBone in pairs(arBones) do
			self.wndPreview:SetBone(tBone.sliderId, 0.0)
		end
	end
	
	self:UpdateCost()
	self:UpdateHelper()
end

function CharacterCustomization:OnOptionUndo(wndHandler, wndControl)
	local idSlider = wndControl:GetData()
	
	if idSlider == knBoneSliderId then
		self.wndPreview:ResetAllBones()
	else
		self.wndPreview:ResetLook(idSlider)
	end
	
	if idSlider == knRaceGenderSliderId then
		self:ReloadCustomizationHeaders()
		self:ResizeTree()
		self:ReloadOpenCategory()
	else
		self:ReloadOpenCategory()
	end
	
	if self.bEnableHelmSwap and self.bHideHelm then
		self:OnHideHelm()
	end
	
	self:UpdateCost()
	self:UpdateHelper()
end

-----------------------------------------------------------------------------------------------
-- Bones!
-----------------------------------------------------------------------------------------------

function CharacterCustomization:OnBoneCategoryCheck(wndHandler, wndControl)
	local wndContainer = wndControl:GetData().wndGroupContents
	wndContainer:DestroyChildren()
	tCharacterBones = self.wndPreview:GetBonesInfo()
	
	for idx, tBone in pairs(tCharacterBones.arBones) do
		local wndBoneOption = Apollo.LoadForm(self.xmlDoc, "BoneOptionItem", wndContainer, self)
		wndBoneOption:SetData(tBone)
		wndBoneOption:FindChild("SliderContainer:SliderTitle"):SetText(tBone.strName)
		
		local wndSlider = wndBoneOption:FindChild("SliderContainer:SliderBar")
		local wndUndoBoneBtn = wndBoneOption:FindChild("UndoBtn")
		local wndSliderValue = wndBoneOption:FindChild("SliderContainer:SliderValue")
		
		local tBoneSliderData = 
		{
			idBoneSlider = tBone.idSlider,
			wndValue = wndSliderValue,
			wndUndoBtn = wndUndoBoneBtn,
		}
		wndSlider:SetData(tBoneSliderData)
		wndSlider:SetValue(tBone.nCurrentValue)
		
		wndSliderValue:SetText(string.format("%.2f", tBone.nCurrentValue))
		wndUndoBoneBtn:Enable(tBone.bChanged)
		wndUndoBoneBtn:SetData(wndSlider)
	end
	
	wndContainer:ArrangeChildrenVert()
	
	self.wndPreview:SetCamera("Portrait")
	wndContainer:Invoke()
	self:UpdateHelper()
	self:ResizeTree()
	
	self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"):ArrangeChildrenVert()
end

function CharacterCustomization:OnBoneChanged(wndHandler, wndControl)
	local nValue = wndHandler:GetValue()
	local tBoneSliderData = wndHandler:GetData()
	local strCurrentValue = string.format("%.2f", nValue)
	
	tBoneSliderData.wndValue:SetText(strCurrentValue)
	self.wndPreview:SetBone(tBoneSliderData.idBoneSlider, nValue)
	tBoneSliderData.wndUndoBtn:Enable(true)
	
	self:UpdateCost()
	self:UpdateHelper()
end

function CharacterCustomization:OnUndoBone(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local wndSlider = wndHandler:GetData()
	local tBoneSliderData = wndSlider:GetData()
	
	local tCharacterBones = self.wndPreview:GetBonesInfo()
	for idx, tBone in pairs(tCharacterBones.arBones) do	
		if tBone.idSlider == tBoneSliderData.idBoneSlider then
			self.wndPreview:SetBone(tBone.idSlider, tBone.nOriginalValue)	
			wndSlider:SetValue(tBone.nOriginalValue)
			tBoneSliderData.wndValue:SetText(string.format("%.2f", tBone.nOriginalValue))
			wndHandler:Enable(false)
		end
	end
	
	self:UpdateCost()
	self:UpdateHelper()
end

-----------------------------------------------------------------------------------------------
-- CostPreview Window
-----------------------------------------------------------------------------------------------

function CharacterCustomization:SetCostPreview()
	local wndCostPreview = self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer")
	wndCostPreview:DestroyChildren()

	local tCustomizationCost = self.wndPreview:GetTotalCustomizationCost()

	if tCustomizationCost == nil then
		self:ResizePreview()
		return
	end

	local tRaces = self.wndPreview:GetAvailableRaces()
	if tRaces ~= nil and tRaces.bChanged then
		local wndRaceHeader = self.wndMain:FindChild("LeftContainer:CategoryScrollContainer:RaceCategoryHeader")
		local buttonName = wndRaceHeader:FindChild("CategorySelectBtn"):GetText()

		wndCostPreviewLine = Apollo.LoadForm(self.xmlDoc, "PreviewLineItem", wndCostPreview, self)
		wndCostPreviewLine:FindChild("ListItemName"):SetText(buttonName)
		wndCostPreviewLine:FindChild("UndoBtn"):SetData(wndRaceHeader:GetData())
		wndCostPreviewLine:FindChild("CashWindow"):SetAmount(tCustomizationCost.monTokenCost, true)
				
		self:ResizePreview()
		return
	end	

	local arItemizedCosts = self.wndPreview:GetItemizedCustomizationCost()
	for idx, tCost in pairs(arItemizedCosts.arCosts) do
		local wndCostPreviewLine = Apollo.LoadForm(self.xmlDoc, "PreviewLineItem", wndCostPreview , self)
		if tCost.strName ~= nil then
			wndCostPreviewLine:FindChild("ListItemName"):SetText(tCost.strName)
		end
		wndCostPreviewLine:FindChild("UndoBtn"):SetData(tCost.idSlider)
		wndCostPreviewLine:FindChild("CashWindow"):SetAmount(tCost.nCost, true)			
	end
	
	wndCostPreview:ArrangeChildrenVert()
	self:ResizePreview()
end
	
function CharacterCustomization:ResizePreview()
	local wndCostPreview = self.wndMain:FindChild("PreviewChangesFlyout")
	local arPreviewWindows = wndCostPreview:FindChild("CostPreviewContainer"):GetChildren()
	local bHasChanges = arPreviewWindows and #arPreviewWindows > 0
		
	wndCostPreview:FindChild("NoChangesLabel"):Show(not bHasChanges)
end

-----------------------------------------------------------------------------------------------
-- Buy Confirmation
-----------------------------------------------------------------------------------------------

function CharacterCustomization:OnPurchaseWithServiceTokens(wndHandler, wndControl)
	local wndConfirmationOverlay = self.wndMain:FindChild("ConfirmationOverlay")
	for idx, wndChild in pairs(wndConfirmationOverlay:GetChildren()) do
		wndChild:Show(false)
	end
	
	local tData = 
	{	
		wndParent = self.wndMain:FindChild("ConfirmationOverlay"),
		strEventName = "ServiceTokenClosed_CharacterCustomization",
		monCost = self.wndPreview:GetTotalCustomizationCost().monTokenCost,
		strConfirmation = String_GetWeaselString(Apollo.GetString("ServiceToken_Confirm"), Apollo.GetString("Costumes_CharacterChopShop")),
		tActionData =
		{
			GameLib.CodeEnumConfirmButtonType.CommitCustomizationChanges,
			self.wndPreview,
			true
		}
	}

	wndConfirmationOverlay:Show(true)
	Event_FireGenericEvent("GenericEvent_ServiceTokenPrompt", tData)
end

function CharacterCustomization:OnServiceTokenClosed_CharacterCustomization(strParent, eActionConfirmEvent, bSuccess)
	if not self.wndMain then
		return
	end

	local wndServiceTokenParent = self.wndMain:FindChild(strParent)
	if wndServiceTokenParent then
		wndServiceTokenParent:Show(false)
	end

	if eActionConfirmEvent == GameLib.CodeEnumConfirmButtonType.CommitCustomizationChanges and bSuccess then
		self:OnPurchaseConfirm()
	end
end

function CharacterCustomization:OnBuyBtn(wndHandler, wndControl)
	local wndPurchaseConfirm = self.wndMain:FindChild("ConfirmationOverlay:PurchaseConfirmation")
	local wndPriceContainer = wndPurchaseConfirm:FindChild("LineItemContainer")
	wndPriceContainer:DestroyChildren()
	
	local arItemizedCosts = self.wndPreview:GetItemizedCustomizationCost()
	for idx, tCost in pairs(arItemizedCosts.arCosts) do
		local wndCostItem = Apollo.LoadForm(self.xmlDoc, "ConfirmationLineItem", wndPriceContainer, self)
		if tCost.strName ~= nil then
			wndCostItem:FindChild("ListItemName"):SetText(tCost.strName)
		end
		wndCostItem:FindChild("CashWindow"):SetAmount(tCost.nCost, true)
	end

	wndPriceContainer:ArrangeChildrenVert()

	local arPreviewEntries = wndPriceContainer:GetChildren()
	
	if arPreviewEntries and #arPreviewEntries > 0 then -- make sure the table exists
		local nPreviewLineItemHeight = arPreviewEntries[1]:GetHeight() -- get height of first entry
		local nTotalLineItemHeight = #arPreviewEntries * nPreviewLineItemHeight -- height entries * single entry
		local tOffsets = wndPurchaseConfirm:GetOriginalLocation():ToTable().nOffsets
		
		wndPurchaseConfirm:SetAnchorOffsets(tOffsets[1], tOffsets[2] - (nTotalLineItemHeight / 2), tOffsets[3], tOffsets[4] + (nTotalLineItemHeight / 2))
	end
		
	local wndSubtotal = wndPurchaseConfirm:FindChild("TotalCost")
	wndSubtotal:SetAmount(self.wndPreview:GetTotalCustomizationCost().monCost , true)
	
	self:ToggleOverlay(ktOverlayTypes.Purchase, true)
end

function CharacterCustomization:OnPurchaseConfirm(wndHandler, wndControl)
	local tRaces = self.wndPreview:GetAvailableRaces()
	if tRaces and tRaces.bChanged then
		Sound.Play(Sound.PlayUIContractProgressComplete)
	end
	self.wndMain:Close()
end

function CharacterCustomization:OnPurchaseCancel(wndHandler, wndControl)
	self:ToggleOverlay(ktOverlayTypes.Purchase, false)
end

-----------------------------------------------------------------------------------------------
-- Close Confirmation
-----------------------------------------------------------------------------------------------
function CharacterCustomization:OnWindowClosed(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	if self.wndMain then
		self.wndMain:Destroy()
		self.wndMain = nil
		self.wndPreview = nil
	end
	
	Event_CancelDyeWindow()
end

function CharacterCustomization:OnCancel(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local bIsDirty = self.wndPreview:IsDirty()
	
	if self.wndMain and not self.wndMain:FindChild("ConfirmationOverlay"):IsShown() and bIsDirty then
		self:ToggleOverlay(ktOverlayTypes.Cancel, true)
	else
		self.wndMain:Close()
	end
end

function CharacterCustomization:OnCloseConfirm(wndHandler, wndControl)
	self:ToggleOverlay(ktOverlayTypes.Cancel, false)
	self.wndMain:Close()
end

function CharacterCustomization:OnCloseCancel(wndHandler, wndControl)
	self:ToggleOverlay(ktOverlayTypes.Cancel, false)
end

function CharacterCustomization:OnHideDye()
	if self.wndMain ~= nil then
		self.wndMain:Close()
	end
end

-----------------------------------------------------------------------------------------------
-- Costume Window Controls
-----------------------------------------------------------------------------------------------

function CharacterCustomization:OnSheatheCheck(wndHandler, wndControl)
	self.wndPreview:SetSheathed(wndHandler:IsChecked())
end

---------------------------------------------------------------------------------------------------
-- Save/Load Code window
---------------------------------------------------------------------------------------------------

function CharacterCustomization:OnSaveLoadBtn( wndHandler, wndControl)
	local wndSaveLoadForm = self.wndMain:FindChild("ConfirmationOverlay:CharacterCode")
	self:ToggleOverlay(ktOverlayTypes.Code, true)
	local strCodes = self.wndPreview:GetSliderCodes()
	wndSaveLoadForm:FindChild("EditBox"):SetText(strCodes)
	self:UpdateCodeDisplay(strCodes)
end

function CharacterCustomization:OnLoadCode(wndHandler, wndControl)
	local wndSaveLoadForm = self.wndMain:FindChild("ConfirmationOverlay:CharacterCode")
	local strCodes = wndSaveLoadForm:FindChild("CodeFraming:EditBox"):GetText()
	local bFailed = self:UpdateCodeDisplay(strCodes)

	if not bFailed then
		self:ToggleOverlay(ktOverlayTypes.Code, false)
		
		self:ReloadCustomizationHeaders()
		if self.bHideHelm then
			self:OnHideHelm()
		else
			self:OnRestoreHelm()
		end
		self.wndMain:FindChild("PreviewChangesFlyout:CostPreviewContainer"):ArrangeChildrenVert()
		self:UpdateCost()
		self:UpdateHelper()
		self:ResizeTree()
	end		
end

function CharacterCustomization:OnCharacterCodeEdit(wndHandler, wndControl, strNew, strOld)
	self:UpdateCodeDisplay(strNew)	
end

function CharacterCustomization:UpdateCodeDisplay(strCode)
	local crPass = "ff2f94ac"
	local crFail = "ffcc0000"
	
	local wndSaveLoadForm = self.wndMain:FindChild("ConfirmationOverlay:CharacterCode")
	local tResults = self.wndPreview:SetBySliderCodes(strCode)
	
	local strErrorText = ""
	local bFailed = false
	
	if not tResults then
		strErrorText = Apollo.GetString("Pregame_InvalidCode")
		wndSaveLoadForm:FindChild("CodeErrorText"):SetText(strErrorText)
		return true
	end
	
	if tResults.bUnsupportedVersion then
		strErrorText = Apollo.GetString("Pregame_OutdatedCode")
		wndSaveLoadForm:FindChild("CodeErrorText"):SetText(strErrorText)
		return true
	end
	
	if tResults.bFactionDoesntMatch then
		bFailed = true
	end
	
	if tResults.bRaceDoesntMatch then
		bFailed = true
	end
	
	if tResults.bGenderDoesntMatch then
		bFailed = true
	end
	
	local errorTextDisplay = wndSaveLoadForm:FindChild("CodeErrorText")
	local loadBtn = wndSaveLoadForm:FindChild("LoadBtn")
	local strDisplay = ""
	local strEnd = ""
	strDisplay = String_GetWeaselString(Apollo.GetString("Pregame_FactionRaceGender"), strDisplay, ktFactionStrings[tResults.nFaction], ktRaceStrings[tResults.nRace], ktGenderStrings[tResults.nGender], strEnd)
	errorTextDisplay:SetText(strDisplay)
		
	if bFailed then
		errorTextDisplay:SetTextColor(crFail)
		loadBtn:Enable(false)
		loadBtn:SetTooltip(Apollo.GetString("Pregame_CharacterCodeFail"))
	else
		errorTextDisplay:SetTextColor(crPass)
		loadBtn:Enable(true)
		loadBtn:SetTooltip("")
	end
	return bFailed
end

function CharacterCustomization:OnCancelLoad(wndHandler, wndControl)
	self:ToggleOverlay(ktOverlayTypes.Code, false)
end

-----------------------------------------------------------------------------------------------
-- Store
-----------------------------------------------------------------------------------------------

function CharacterCustomization:RefreshStoreLink()
	self.bLinkAvailable = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.ServiceTokens)
end

function CharacterCustomization:RaceUnavailable(tRaceGender)
	local storeEnum = ktEntitlementStoreEnums[tRaceGender.idEntitlementRequired]
	if storeEnum ~= nil then
		StorefrontLib.OpenLink(storeEnum)
		self.wndMain:Close()
	end
end

-----------------------------------------------------------------------------------------------
-- Helpers?
-----------------------------------------------------------------------------------------------

function CharacterCustomization:UpdateHelper()
	local arHeaders = self.wndMain:FindChild("LeftContainer:CategoryScrollContainer"):GetChildren()
	local tBones = self.wndPreview:GetBonesInfo()
	
	for idx, wndCategory in pairs(arHeaders) do
		if wndCategory:GetName() ~= "CodeCategoryHeader" then
			local idSlider = wndCategory:GetData()
			local tValues = self.wndPreview:GetAppearanceValues(idSlider)
			if wndCategory:GetName() == "RaceCategoryHeader" then
				local tRaces = self.wndPreview:GetAvailableRaces()
				wndCategory:FindChild("CategorySelectBtn:ElementChangedIcon"):Show(tRaces.bChanged)
				wndCategory:FindChild("BoneClearIcon"):Show(self.wndPreview:IsDirty())
			elseif idSlider == knBoneSliderId then
				local bChanged = false
				if tBones ~= nil then
					bChanged = tBones.bBonesChanged
				end
				wndCategory:FindChild("CategorySelectBtn:ElementChangedIcon"):Show(bChanged)
			elseif tValues ~= nil then
				wndCategory:FindChild("CategorySelectBtn:ElementChangedIcon"):Show(tValues.bChanged)
				if ktFaceSliderIds[idSlider] then
					local bChanged = false
					if tBones ~= nil then
						bChanged = tBones.bBonesChanged
					end
					wndCategory:FindChild("BoneClearIcon"):Show(bChanged)
				end
			end
		end
	end
	
	self:SetCostPreview()
end

function CharacterCustomization:ToggleOverlay(eConfirmationType, bShow)
	local wndOverlay = self.wndMain:FindChild("ConfirmationOverlay")
		
	wndOverlay:Show(bShow)
	wndOverlay:FindChild("PurchaseConfirmation"):Show(eConfirmationType == ktOverlayTypes.Purchase and bShow)
	wndOverlay:FindChild("CancelConfirmation"):Show(eConfirmationType == ktOverlayTypes.Cancel and bShow)
	wndOverlay:FindChild("CharacterCode"):Show(eConfirmationType == ktOverlayTypes.Code and bShow)
	
	local wndFooter = self.wndMain:FindChild("Footer")
	wndFooter:FindChild("CashBuyBtn"):Enable(not bShow)
	wndFooter:FindChild("PurchaseServiceTokens"):Enable(not bShow)
	
	wndFooter:FindChild("UndoAllBtn"):Enable(not bShow)
	
	if bShow and eConfirmationType == ktOverlayTypes.Purchase then
		wndOverlay:FindChild("ConfirmPurchaseBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.CommitCustomizationChanges, self.wndPreview, false)
	end
end

function CharacterCustomization:UpdateCost()
	if not self.wndMain or not self.wndMain:IsValid() then
		return
	end
	
	local tCustomizationCost = self.wndPreview:GetTotalCustomizationCost()
	local wndFooter = self.wndMain:FindChild("Footer")
	local wndPurchaseServiceTokens = wndFooter:FindChild("PurchaseServiceTokens")
	self:HelperDrawCostBtn(wndPurchaseServiceTokens, tCustomizationCost.monTokenCost)
	wndPurchaseServiceTokens:SetData(tCustomizationCost.monTokenCost)

	local wndSubmit = wndFooter:FindChild("CashBuyBtn")
	local monCost = tCustomizationCost.monCost
	self:HelperDrawCostBtn(wndSubmit, monCost)
	wndSubmit:SetData({monCost = monCost})
end

function CharacterCustomization:HelperDrawCostBtn(wndBtn, monCost)
	local wndCash = wndBtn:FindChild("TotalCost")
	local bServiceToken = false
	local bHasChanges = false
	local bCanBuy = false
	
	if monCost ~= nil then
		bServiceToken = monCost:GetAccountCurrencyType() ~= 0
		bHasChanges = monCost:GetAmount() > 0
		bCanBuy = bHasChanges and (monCost:GetMoneyType() == Money.CodeEnumCurrencyType.Credits and monCost:GetAmount() <= GameLib.GetPlayerCurrency():GetAmount() or monCost:GetAmount() <= AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.ServiceToken):GetAmount())
		wndCash:SetAmount(monCost)
	else
		wndCash:SetAmount(0)
	end
	
	local strColor = "UI_WindowTextDefault"
	if not bHasChanges then
		strColor = "ConTrivial"
	elseif not bCanBuy then
		strColor = "UI_WindowTextRed"
	end
	wndCash:SetTextColor(strColor)

	wndBtn:Enable(bHasChanges and (bCanBuy or bServiceToken))
end

function CharacterCustomization:ResizeTree()
	local wndLeftScroll = self.wndMain:FindChild("LeftContainer:CategoryScrollContainer")
	local arHeaders = wndLeftScroll:GetChildren()
	local nHeaderHeight = arHeaders[1]:GetHeight()
	local nOpenIndex = nil

	for idx, wndCategory in pairs(arHeaders) do
		if wndCategory:GetName() ~= "CodeCategoryHeader" then
			local wndOptionContainer = wndCategory:FindChild("GroupContents")
			local wndTopButton = wndCategory:FindChild("CategorySelectBtn")
			local nCurrentCategoryOffset = 0
			
			if wndTopButton:IsChecked() and wndOptionContainer:IsShown() then
				local arOptions = wndOptionContainer:GetChildren()
				
				--Customization options are treated differently than Bone options
				if #arOptions > 0 then
					if arOptions[1]:GetName() == "OptionItem" or  arOptions[1]:GetName() == "RaceOptionItem" then
						nCurrentCategoryOffset = arOptions[1]:GetHeight() * (math.ceil(#arOptions / 2))
					else
						nCurrentCategoryOffset = arOptions[1]:GetHeight() * #arOptions
					end

					if nCurrentCategoryOffset > 0 then
						nCurrentCategoryOffset = nCurrentCategoryOffset + 6
					end
					
					nOpenIndex = idx
				end
			end

			local nLeft, nTop, nRight, nBottom = wndOptionContainer:GetAnchorOffsets()
			wndOptionContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nCurrentCategoryOffset)
			wndOptionContainer:ArrangeChildrenTiles(Window.CodeEnumArrangeOrigin.LeftOrTop)
			
			local tOffset = wndCategory:GetOriginalLocation():ToTable().nOffsets
			wndCategory:SetAnchorOffsets(tOffset[1], tOffset[2], tOffset[3], tOffset[4] + nCurrentCategoryOffset)
		end
	end

	wndLeftScroll:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	if nOpenIndex then
		local nVScrollRange = wndLeftScroll:GetVScrollRange()
		local nHeaderTop = nHeaderHeight * (nOpenIndex - 1)
		wndLeftScroll:SetVScrollPos(nHeaderTop < nVScrollRange and nHeaderTop or nVScrollRange)
	end
end

function CharacterCustomization:ReloadOpenCategory()
	local wndLeftScroll = self.wndMain:FindChild("LeftContainer:CategoryScrollContainer")
	local arHeaders = wndLeftScroll:GetChildren()
	
	for idx, wndCategory in pairs(arHeaders) do
		if wndCategory:GetName() ~= "CodeCategoryHeader" then
			local wndTopButton = wndCategory:FindChild("CategorySelectBtn")
			local wndOptionContainer = wndCategory:FindChild("GroupContents")
			
			if wndTopButton:IsChecked() and wndOptionContainer:IsShown() then
				local idSlider = wndTopButton:GetData().idSlider
				if idSlider == knBoneSliderId then
					wndOptionContainer:DestroyChildren()
					tCharacterBones = self.wndPreview:GetBonesInfo()
					for idx, tBone in pairs(tCharacterBones.arBones) do
						local wndBoneOption = Apollo.LoadForm(self.xmlDoc, "BoneOptionItem", wndOptionContainer, self)
						wndBoneOption:SetData(tBone)
						wndBoneOption:FindChild("SliderContainer:SliderTitle"):SetText(tBone.strName)
						
						local wndSlider = wndBoneOption:FindChild("SliderContainer:SliderBar")
						local wndUndoBoneBtn = wndBoneOption:FindChild("UndoBtn")
						local wndSliderValue = wndBoneOption:FindChild("SliderContainer:SliderValue")
						
						tBoneSliderData = 
						{
							idBoneSlider = tBone.idSlider,
							wndValue = wndSliderValue,
							wndUndoBtn = wndUndoBoneBtn,
						}
						wndSlider:SetData(tBoneSliderData)
						wndSlider:SetValue(tBone.nCurrentValue)
						
						wndSliderValue:SetText(string.format("%.2f", tBone.nCurrentValue))
						wndUndoBoneBtn:Enable(tBone.bChanged)
						wndUndoBoneBtn:SetData(wndSlider)
					end
					wndOptionContainer:ArrangeChildrenVert()
				elseif idSlider == knRaceGenderSliderId then
					self:OnRaceCategoryCheck(wndTopButton, wndTopButton)
				else
					self:LoadCustomizationOptions(wndTopButton:GetData())
				end
			end
		end
	end
end

function CharacterCustomization:OnGenerateIconTooltip(wndHandler, wndControl)
	Tooltip.GetItemTooltipForm(self, wndControl, Item.GetDataFromId(knTokenItemId), {})
end

function CharacterCustomization:UndoAll()
	self.wndPreview:ResetAllLooks()
	self.wndPreview:ResetAllBones()
	self:ReloadCustomizationHeaders()
	self:ResizeTree()
	self:UpdateCost()
	self:UpdateHelper()
end

function CharacterCustomization:OnHideHelm()
	self.bHideHelm = true
	self:ReloadOpenCategory()
	self.wndPreview:RemoveItem(GameLib.CodeEnumItemSlots.Head)
end

function CharacterCustomization:OnRestoreHelm()
	self.bHideHelm = false
	self:ReloadOpenCategory()
	self.wndPreview:SetItem(self.itemDisplayedHelm)
end

-----------------------------------------------------------------------------------------------
-- CharacterCustomization Instance
-----------------------------------------------------------------------------------------------
local CharacterCustomizationInst = CharacterCustomization:new()
CharacterCustomizationInst:Init()
