-----------------------------------------------------------------------------------------------
-- Client Lua Script for HousingDecorate
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "HousingLib"
require "Residence"
require "Decor"
require "StorefrontLib"
 
-----------------------------------------------------------------------------------------------
-- HousingDecorate Module Definition
-----------------------------------------------------------------------------------------------
local HousingDecorate = {} 

-----------------------------------------------------------------------------------------------
-- global
-----------------------------------------------------------------------------------------------
local gidZone 		= 0
local gbOnProperty 	= 0
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
 local knItemTypeHousingInteriorFurniture 	= 155
 local knItemTypeHousingExteriorAccent 		= 163
 local knInteriorListTopOffset = -40
 local knHousingExteriorPlacementMinHeight = -60
 
 local kstrFrameVisible 	= "CRB_DatachronSprites:sprDC_GreenPulse"
 local kstrFrameNotVisible 	= "CRB_DatachronSprites:sprDC_RedPulse"
 local kstrFrameOffscreen 	= "CRB_DatachronSprites:sprDC_BlueFlashPlayRing"

 local kstrPlaceFromVendor 	= Apollo.GetString("HousingDecorate_PlaceFromVendor")
 local kstrPlaceFromCrate 	= Apollo.GetString("HousingDecorate_PlaceFromCrate")
 local kstrPreviewInWorld 	= Apollo.GetString("HousingDecorate_PreviewFreeform")
 local kstrPreviewOnHook 	= Apollo.GetString("HousingDecorate_PreviewHook")
 local kstrSelectNew 		= Apollo.GetString("HousingDecorate_SelectItem")
 local kstrPlaceAgain 		= Apollo.GetString("HousingDecorate_PlaceAgain")
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function HousingDecorate:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	-- initialize our variables
	o.wndDecorate = nil
	o.wndListView = nil
	o.wndOkButton = nil
	o.wndCashDecorate = nil
	o.wndSortByList = nil
	o.tCategoryItems = {}
	
	o.wndDestroyDecorFrame = nil
	o.wndDestroyCrateDecorFrame = nil
	o.wndFreePlaceFrame = nil
	o.wndDecorMsgFrame = nil
	o.wndMannequinMsgFrame = nil
	
	o.nSortType = 0
	
    return o
end

function HousingDecorate:Init()
    Apollo.RegisterAddon(self)
end
 

-----------------------------------------------------------------------------------------------
-- HousingDecorate OnLoad
-----------------------------------------------------------------------------------------------
function HousingDecorate:OnLoad()
	Apollo.RegisterEventHandler("HousingPanelControlOpen", 			"OnOpenPanelControl", self)
	Apollo.RegisterEventHandler("HousingPanelControlClose", 		"OnClosePanelControl", self)
	Apollo.RegisterEventHandler("WarPartyBattleOpen", 				"OnOpenBattle", self)
	Apollo.RegisterEventHandler("WarPartyBattleClose", 				"OnCloseBattle", self)
	Apollo.RegisterEventHandler("ChangeWorld", 						"OnChangeWorld", self)
	
	Apollo.RegisterEventHandler("HousingSelectHook", 				"OnHookSelect", self)
	Apollo.RegisterEventHandler("HousingHookDecorPlaced", 			"OnHookDecorPlaced", self)	
	Apollo.RegisterEventHandler("HousingSelectIvalidHook", 			"OnInvalidHookSelect", self)
	Apollo.RegisterEventHandler("HousingMyResidenceDecorChanged", 	"OnMyResidenceDecorChanged", self)
	Apollo.RegisterEventHandler("HousingExitEditMode", 				"OnExitEditMode", self)
	Apollo.RegisterEventHandler("PlayerCurrencyChanged", 			"OnPlayerCurrencyChanged", self)
	Apollo.RegisterEventHandler("HousingBuildStarted", 				"OnBuildStarted", self)
	
	Apollo.RegisterEventHandler("HousingButtonCrate", 				"OnHousingButtonCrate", self)
	Apollo.RegisterEventHandler("HousingButtonVendor", 				"OnHousingButtonVendor", self)
	Apollo.RegisterEventHandler("HousingButtonList", 				"OnHousingButtonList", self)
	Apollo.RegisterEventHandler("HousingButtonRemodel", 			"OnHousingButtonRemodel", self)
	Apollo.RegisterEventHandler("HousingButtonLandscape", 			"OnHousingButtonLandscape", self)
	
	Apollo.RegisterEventHandler("HousingFreePlaceDecorQuery", 		"OnFreePlaceDecorQuery", self)
	Apollo.RegisterEventHandler("HousingFreePlaceDecorSelected", 	"OnFreePlaceDecorSelected", self)
	Apollo.RegisterEventHandler("HousingFreePlaceDecorPlaced", 		"OnFreePlaceDecorPlaced", self)
	Apollo.RegisterEventHandler("HousingFreePlaceDecorCancelled", 	"OnFreePlaceDecorCancelled", self)
	Apollo.RegisterEventHandler("HousingFreePlaceDecorMoveBegin",   "OnFreePlaceDecorMoveBegin", self)
	Apollo.RegisterEventHandler("HousingFreePlaceDecorMoving",      "OnFreePlaceDecorMoving", self)
	Apollo.RegisterEventHandler("HousingFreePlaceDecorMoveEnd",     "OnFreePlaceDecorMoveEnd", self)
	Apollo.RegisterEventHandler("HousingFreePlaceControlClose", 	"OnCloseFreePlaceControl", self)
	Apollo.RegisterEventHandler("HousingDestroyDecorControlOpen", 	"OnOpenDestroyDecorControl", self)
	Apollo.RegisterEventHandler("HousingDestroyDecorControlOpen2", 	"OnOpenDestroyDecorControl", self)
	Apollo.RegisterEventHandler("HousingActivateDecorIcon", 		"OnActivateDecorIcon", self)
	Apollo.RegisterEventHandler("HousingDeactivateDecorIcon", 		"OnDeactivateDecorIcon", self)
	
	Apollo.RegisterEventHandler("HousingResult", 					"OnHousingResult", self)
	
	Apollo.RegisterEventHandler("UpdateRewardProperties",			"OnRewardPropertiesUpdate", self)
	Apollo.RegisterEventHandler("StoreLinksRefresh",				"RefreshStoreLink", self)
	
	Apollo.RegisterTimerHandler("HousingDecorIconTimer", 			"OnDecorIconUpdate", self)
	Apollo.RegisterTimerHandler("HousingDecorListRefreshTimer", 	"OnListRefresh", self)
	
	-- Drag-drop
	Apollo.RegisterEventHandler("DragDropSysBegin", "OnSystemBeginDragDrop", self)
	Apollo.RegisterEventHandler("DragDropSysEnd", 	"OnSystemEndDragDrop", self)
	
	Apollo.CreateTimer("HousingDecorListRefreshTimer", 0.200, false)
	Apollo.StopTimer("HousingDecorListRefreshTimer")
	
	Apollo.CreateTimer("HousingDecorIconTimer", 0.01, false)
	Apollo.StopTimer("HousingDecorIconTimer")

    -- load our forms
    self.xmlDoc = XmlDoc.CreateFromFile("HousingDecorate.xml")
    
    self.wndDecorate 				= Apollo.LoadForm(self.xmlDoc, "HousingDecorateWindow", nil, self)
	self.wndListView 				= self.wndDecorate:FindChild("StructureList")
	self.wndListFrame				= self.wndDecorate:FindChild("BGC_ListBacker")
	self.wndBuyButton 				= self.wndDecorate:FindChild("BuyBtn")
	self.wndBuyToCrateButton		= self.wndDecorate:FindChild("BuyToCrateBtn")
	self.wndDeleteButton 			= self.wndDecorate:FindChild("DeleteBtn")
	self.wndCancelButton 			= self.wndDecorate:FindChild("CancelBtn")
	self.wndCashDecorate 			= self.wndDecorate:FindChild("CashWindow")
	self.wndExtHeaderWindow 		= self.wndDecorate:FindChild("ExtHeaderWindow")
	self.wndIntHeaderWindow			= self.wndDecorate:FindChild("IntHeaderWindow")
	self.wndIntSearchWindow 		= self.wndIntHeaderWindow:FindChild("IntSearchBox")
	self.wndExtSearchWindow 		= self.wndExtHeaderWindow:FindChild("ExtSearchBox")
	self.wndExtClearSearchBtn 		= self.wndExtHeaderWindow:FindChild("ExtClearSearchBtn")
	self.wndIntClearSearchBtn 		= self.wndIntHeaderWindow:FindChild("IntClearSearchBtn")
	self.wndExtShowOnlyToggleBtn 	= self.wndExtHeaderWindow:FindChild("ShowExteriorOnlyBtn")
	self.wndIntShowOnlyToggleBtn 	= self.wndIntHeaderWindow:FindChild("ShowInteriorOnlyBtn")
	self.wndMessageDisplay 			= self.wndDecorate:FindChild("MessageContainer")
	self.bHidePreview 				= false
	self.bFilterCanUseOnly      	= false
    self.wndExtShowOnlyToggleBtn:SetCheck(false)
    self.wndIntShowOnlyToggleBtn:SetCheck(false)
	
    self.wndDecorate:FindChild("IntSortByBtn"):AttachWindow(self.wndDecorate:FindChild("IntSortByWindow"))
    self.wndDecorate:FindChild("ExtSortByBtn"):AttachWindow(self.wndDecorate:FindChild("ExtSortByWindow"))
	
	self.wndListView:SetColumnText(1, Apollo.GetString("HousingDecorate_Decor"))
	self.wndListView:SetColumnText(2, Apollo.GetString("HousingDecorate_Owned"))
	self.wndListView:SetColumnText(3, Apollo.GetString("CombatFloaterType_Beneficial"))
	
	self.wndVendorList = self.wndDecorate:FindChild("VendorList")
	self.wndVendorList:SetColumnText(1, Apollo.GetString("HousingDecorate_Upgrade"))
	self.wndVendorList:SetColumnText(2, Apollo.GetString("HousingDecorate_Cost"))
	self.wndVendorList:SetColumnText(3, Apollo.GetString("CombatFloaterType_Beneficial"))
	
	self.wndCrateFrame = self.wndDecorate:FindChild("BGC_ListWindow")
	self.wndVendorFrame = self.wndDecorate:FindChild("BGV_ListWindow")
	
	
	self.eDisplayedCurrencyType = Money.CodeEnumCurrencyType.Credits
	self.eDisplayedGroupCurrencyType = Money.CodeEnumGroupCurrencyType.None
	
	-- Save starting anchor top values so they can reset
	local nLeft, nTop, nRight, nBottom = self.wndCrateFrame:GetAnchorOffsets()
	self.nCrateTop = nTop
	nLeft, nTop, nRight, nBottom = self.wndVendorFrame:GetAnchorOffsets()
	self.nVendorTop = nTop
	
	self.wndBuyButton:Show(false)
	self.wndDeleteButton:Enable(false)
	self.wndCancelButton:Enable(false)
	self.wndIntClearSearchBtn:Show(false)
    self.wndExtClearSearchBtn:Show(false)
	self.wndBuyToCrateButton:Enable(false)
	self.wndBuyToCrateButton:Show(false)
	
	self.wndCashDecorate:SetMoneySystem(self.eDisplayedCurrencyType, self.eDisplayedGroupCurrencyType)
	self.wndCashDecorate:SetAmount(GameLib.GetPlayerCurrency(self.eDisplayedCurrencyType, self.eDisplayedGroupCurrencyType), true)
	
	-- free place
	self.wndFreePlaceFrame = Apollo.LoadForm(self.xmlDoc, "FreePlaceWindow", nil, self)
	self.wndFreePlaceFrame:FindChild("CopyTranslationBtn"):SetCheck(true)
	self.wndFreePlaceFrame:FindChild("CopyRotationBtn"):SetCheck(true)
	self.wndFreePlaceFrame:FindChild("CopyScaleBtn"):SetCheck(true)
	
	self.wndFreePlaceOKBtn = self.wndFreePlaceFrame:FindChild("FreePlaceBtn")
	self.wndFreePlaceOKBtn:Enable(false)
	
	self.wndFreePlaceCancelBtn = self.wndFreePlaceFrame:FindChild("CancelFreePlaceBtn")
	self.wndFreePlaceCancelBtn:Enable(true)
	
	self.wndFreePlaceToggleMoveControlBtn = self.wndFreePlaceFrame:FindChild("FreePlaceMoveBtn")
	self.wndFreePlaceToggleRotateControlBtn = self.wndFreePlaceFrame:FindChild("FreePlaceRotateBtn")
	self.wndFreePlaceToggleMoveControlBtn:SetCheck(true)
	self.wndFreePlaceToggleRotateControlBtn:SetCheck(true)
	
	self.wndFreePlaceLocalModeBtn = self.wndFreePlaceFrame:FindChild("FreePlaceLocalBtn")
	self.wndFreePlaceGlobalModeBtn = self.wndFreePlaceFrame:FindChild("FreePlaceGlobalBtn")
	if HousingLib.GetControlMode() == HousingLib.DecorControlMode.Local then
	    self.wndFreePlaceFrame:FindChild("ScrollContainer"):SetRadioSel("GizmoControlModeBtns", 1)
	else
        self.wndFreePlaceFrame:FindChild("ScrollContainer"):SetRadioSel("GizmoControlModeBtns", 2)
    end    
	
	self.wndFreePlaceCopyBtn = self.wndFreePlaceFrame:FindChild("FreePlaceCopyBtn")
	self.wndFreePlacePasteBtn = self.wndFreePlaceFrame:FindChild("FreePlacePasteBtn")
	self.wndFreePlacePasteBtn:Enable(false)
	self.tCopyDecorInfo = {}
	
	self.wndFreePlaceFrame:Show(false)

	-- decor icon/context menu
	self.wndDecorIconFrame 			= Apollo.LoadForm(self.xmlDoc, "DecorIcon", nil, self)
	self.wndToggleFrame 			= self.wndDecorIconFrame:FindChild("IconToggleFrame")
	self.wndDecorIconBacker 		= self.wndToggleFrame:FindChild("IconBacker")
	self.wndDecorIconOptionsWindow 	= self.wndDecorIconFrame:FindChild("DecorOptionsWindow")
	self.wndAdvToggle 				= self.wndDecorIconOptionsWindow:FindChild("ToggleAdvanced")
	self.wndDecorIconName           = self.wndToggleFrame:FindChild("DecorNameLabel")
	self.wndDecorBuffIcon           = self.wndToggleFrame:FindChild("BuffIcon")
	self.wndDecorChairIcon          = self.wndToggleFrame:FindChild("ChairIcon")
	self.wndDecorDisableIcon        = self.wndToggleFrame:FindChild("DisableIcon")
	self.wndToggleFrame:Show(false)
	
	local nWidth = self.wndDecorate:GetWidth()
	local nHeight = self.wndDecorate:GetHeight()
	self.wndDecorate:SetSizingMinimum(nWidth,350)
	self.wndDecorate:SetSizingMaximum(nWidth * 2,nHeight * 2)
	
	self.bIsVendor = false
	
	self.bCanPlaceHere = false
	
	--self:ShowDecorateWindow(true)
	--HousingLib.RefreshUI()
	
	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()
	
	self:RefreshStoreLink()
end

function HousingDecorate:OnWindowManagementReady()
	local strCrateName = String_GetWeaselString(Apollo.GetString("Tooltips_ItemSpellEffect"), Apollo.GetString("CRB_Housing"), Apollo.GetString("CRB_Crate"))

	
	Event_FireGenericEvent("WindowManagementRegister", {strName = strCrateName, nSaveVersion = 2})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndDecorate, strName = strCrateName})
	
	local strPlaceName = String_GetWeaselString(Apollo.GetString("Tooltips_ItemSpellEffect"), Apollo.GetString("CRB_Housing"), Apollo.GetString("Housing_AdvancedMode"))

	Event_FireGenericEvent("WindowManagementRegister", {strName = strPlaceName, nSaveVersion = 2})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndFreePlaceFrame, strName = strPlaceName})
end

-----------------------------------------------------------------------------------------------
-- HousingDecorate Functions
-----------------------------------------------------------------------------------------------
function HousingDecorate:OnPlayerCurrencyChanged()
	if not self.wndDecorate or not self.wndDecorate:IsShown() then 
		return 
	end
	self.wndCashDecorate:SetMoneySystem(self.eDisplayedCurrencyType, self.eDisplayedGroupCurrencyType)
	self.wndCashDecorate:SetAmount(GameLib.GetPlayerCurrency(self.eDisplayedCurrencyType, self.eDisplayedGroupCurrencyType), true) -- 2nd argument = IsInstant
end

function HousingDecorate:OnBuildStarted(plotIndex)
    if plotIndex == 1 then
        self:OnCloseHousingDecorateWindow()
    end
end

function HousingDecorate:OnCategorySelectionClosed()
   -- self.wndDecorate:FindChild("IntSortByBtn"):SetCheck(false)
   -- self.wndDecorate:FindChild("ExtSortByBtn"):SetCheck(false)
    self.wndListView:Enable(true)	
end


function HousingDecorate:ResetPopups()
    if self.wndDestroyDecorFrame ~= nil then
	    self.wndDestroyDecorFrame:Destroy()
	    self.wndDestroyDecorFrame = nil
    end
    
    --[[if self.wndFreePlaceFrame ~= nil then
	    self.wndFreePlaceFrame:Destroy()
	    self.wndFreePlaceFrame = nil
    end--]]
    self.wndFreePlaceFrame:Close()

    if self.wndDestroyCrateDecorFrame ~= nil then
	    self.wndDestroyCrateDecorFrame:Destroy()
	    self.wndDestroyCrateDecorFrame = nil
    end

    if self.wndDecorMsgFrame ~= nil then
	    self.wndDecorMsgFrame:Destroy()
	    self.wndDecorMsgFrame = nil
		self.bWaitingForLink = false
    end
end 

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnHousingButtonCrate()
	self:OnHousingButtonOpenCrate(false)
end

function HousingDecorate:OnHousingButtonVendor()
	self:OnHousingButtonOpenCrate(true)
end

function HousingDecorate:OnHousingButtonOpenCrate(bIsVendor)
    if not self.wndDecorate:IsVisible() or bIsVendor ~= self.bIsVendor then
        
		if self.wndDecorate:IsVisible() then -- already shown
			self.wndDecorate:FindChild("FlashContainer"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp") 
		end
		
		self.bIsVendor = bIsVendor
        self.wndDecorate:Invoke()
        self:ShowDecorateWindow(true)

	    self.wndDecorate:FindChild("IntSortByWindow"):Show(false)
	    self.wndDecorate:FindChild("ExtSortByWindow"):Show(false)
        self.wndDecorate:FindChild("IntSortByBtn"):SetCheck(false)
        self.wndDecorate:FindChild("ExtSortByBtn"):SetCheck(false)	
		self.wndBuyToCrateButton:Show(self.bIsVendor)

		self:ShowItems(self.wndListView, self.tDecorList, 0)
		self.wndListView:SetCurrentRow(0)
		self.wndBuyToCrateButton:Enable(false)
		self.idSelectedItem = nil
		self.eSelectedItemType = nil
		self.wndMessageDisplay:SetText(kstrSelectNew)
		
        Event_FireGenericEvent("HousingEnterEditMode")
		HousingLib.SetEditMode(true)
	else
	    self:OnCloseHousingDecorateWindow()
	end
end	

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnHousingButtonLandscape()
	if self.wndDecorate:IsVisible() then
		self:OnCloseHousingDecorateWindow()
	end
end	

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnHousingButtonList()
	if self.wndDecorate:IsVisible() then
		self:OnCloseHousingDecorateWindow()
	end
end	

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnHousingButtonRemodel()
	if self.wndDecorate:IsVisible() then
		self:OnCloseHousingDecorateWindow()
	end
end	

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnExitEditMode()
    -- popup windows reset
    self:ResetPopups()
    
    -- any preview decorItems reset
    self:CancelPreviewDecor(true)
    self:OnCancelFreePlace()
	self:OnCloseHousingDecorateWindow()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:PrepUi(idPropertyInfo, idZone, bPlayerIsInside)
	if self.bPlayerIsInside ~= bPlayerIsInside or self.bIsWarplot ~= HousingLib.GetResidence():IsWarplotResidence() then
	    -- popup windows reset
	    self:ResetPopups()

	    -- any preview decorItems reset
        self:CancelPreviewDecor(true)
        self:OnCancelFreePlace()
	    
	    -- close the decorate window (if its open)
		self:OnCloseHousingDecorateWindow()
		self:OnPlayerCurrencyChanged()
	end	

    gbOnProperty = true
	gidZone = idZone
	self.idPropertyInfo = idPropertyInfo
	self.bPlayerIsInside = bPlayerIsInside == true --make sure we get true/false
	self.bIsWarplot = HousingLib.GetResidence():IsWarplotResidence()
	
	if self.bIsWarplot then
		self.wndDecorate:FindChild("VendorAssets:TitleFrame:TitleFrame"):SetText(Apollo.GetString("HousingDecorate_WarplotVendorLabel"))
	else
		self.wndDecorate:FindChild("VendorAssets:TitleFrame:TitleFrame"):SetText(Apollo.GetString("HousingDecorate_VendorLabel"))
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnOpenPanelControl(idPropertyInfo, idZone, bPlayerIsInside)
	if HousingLib.IsHousingWorld() then
		self:PrepUi(idPropertyInfo, idZone, bPlayerIsInside)
	end	
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnOpenBattle(uGuild)
	self:PrepUi(0, 0, true)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnClosePanelControl()
	-- don't allow closing the panel during the battle map from this event.
	if HousingLib.GetResidence() and HousingLib.GetResidence():IsWarplotResidence() and not HousingLib.IsHousingWorld() then
		return
	end

	gbOnProperty = false -- you've left your property!
	self:OnCloseHousingDecorateWindow()
	self:OnCancelFreePlace()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnCloseBattle()
	gbOnProperty = false -- you've left your property!
	self:OnCloseHousingDecorateWindow()
	self:OnCancelFreePlace()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnCloseAdvanced(wndHandler, wndControl)
	self.wndFreePlaceFrame:Show(false)	
	self.wndAdvToggle:SetCheck(false)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnHookSelect()
	self:OnDecoratePreview()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnInvalidHookSelect()
	self.wndBuyButton:Show(false)
	self.wndDeleteButton:Enable(false)
	self.wndCancelButton:Enable(false)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnDecoratePreview(wndControl, wndHandler) -- attaching a prop to a hook 
	--split this one to match the crate/vendor strings
	local nRow = self.wndListView:GetCurrentRow()
    if nRow ~= nil then 
        local tItemData = self.wndListView:GetCellData( nRow, 1 )
        
        local idInfo = 0
        local idLow = 0
        local idHi = 0
        if self.bIsVendor then
            idInfo = tItemData.nId
			self.wndMessageDisplay:SetText(kstrPlaceFromVendor)
        else
            idLow = tItemData.tDecorItems[1].nDecorId
            idHi = tItemData.tDecorItems[1].nDecorIdHi
			self.wndMessageDisplay:SetText(kstrPlaceFromCrate)
        end

        -- remove any existing preview decor
        self:CancelPreviewDecor(true)

        local decorPreview = nil
        if self.bIsVendor then
            decorPreview = HousingLib.PreviewVendorDecor(idInfo)
        else
            decorPreview = HousingLib.PreviewCrateDecor(idLow, idHi)
        end
        --self:OnInvalidHookSelect()

        if decorPreview ~= nil then
            Sound.Play(Sound.PlayUIHousingHardwareAddition)
			self.decorPreview = decorPreview
            
            local bValidPlacement = self.decorPreview:ValidateDecorPlacement()
            local bThereIsRoom = not self.bPlayerIsInside and HousingLib.GetResidence():GetNumPlacedDecorExterior() <= HousingLib.GetResidence():GetCurrentMaxPlacedDecorExterior() or HousingLib.GetResidence():GetNumPlacedDecorInterior() <= HousingLib.GetResidence():GetCurrentMaxPlacedDecorInterior()
            local bCanAfford = true
            if self.bIsVendor then
                bCanAfford = GameLib.GetPlayerCurrency():GetAmount(self.eDisplayedCurrencyType, self.eDisplayedGroupCurrencyType) >= tItemData.nCost
            end
            self.bCanPlaceHere = bCanAfford and bThereIsRoom and bValidPlacement
            self.wndBuyButton:Show(self.bCanPlaceHere)
            self.wndCancelButton:Enable(true)
            self.wndDeleteButton:Enable(false)
            
            -- prune the list to remove any plug types that don't match this decor  
            local nCurrentSelection = self.wndListView:GetCurrentRow() 
            self:ShowItems(self.wndListView, self.tDecorList, 0)
            if nCurrentSelection ~= nil then
                self.wndListView:SetCurrentRow(nCurrentSelection)
				self.wndBuyToCrateButton:Enable(true)
                self.wndListView:EnsureCellVisible(nCurrentSelection, 1)
            end
        end
    end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:CancelPreviewDecor(bRemoveFromWorld)
	if bRemoveFromWorld and self.decorPreview ~= nil then
	    self.decorPreview:CancelTransform()
	end
	
	self.bCanPlaceHere = false
	self.decorPreview = nil
	self:OnInvalidHookSelect()
	self:ShowItems(self.wndListView, self.tDecorList, 0)
	self.wndFreePlaceFrame:Show(false)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnBuyBtn(wndControl, wndHandler)

   	self.wndIntSearchWindow:ClearFocus()
	self.wndExtSearchWindow:ClearFocus()
	if self.decorPreview ~= nil then
		self.decorPreview:Place()
	end
	Sound.Play(Sound.PlayUIHousingHardwareFinalized)
	Sound.Play(Sound.PlayUI16BuyVirtual)
	
	self.decorPreview = nil

	self:CancelPreviewDecor(false)
	self:ShowItems(self.wndListView, self.tDecorList, 0)
	
	-- Check indoors/outdoors to know what message should be shown
	
	if not self.bIsVendor then -- crate
        local nRow = self.wndListView:GetCurrentRow()
        local tItemData = self.wndListView:GetCellData( nRow, 1 )
        if tItemData.nCount == 1 then -- last of this tItemData
            self.wndMessageDisplay:SetText(kstrSelectNew)
			self.wndListView:SetCurrentRow(0)
			self.wndBuyToCrateButton:Enable(false)
            self.idSelectedItem = nil
            self.eSelectedItemType = nil
			self:HelperTogglePreview(false)
			self.wndTogglePreview:Enable(false)	
        else
			self.wndMessageDisplay:SetText(kstrPlaceAgain)
		end
	else -- vendor
		self.wndMessageDisplay:SetText(kstrPlaceAgain)
		self:HelperTogglePreview(not self.bHidePreview)
		self.wndTogglePreview:Enable(true)		
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnBuyToCrateBtn(wndControl, wndHandler)

    if self.bIsVendor then
		local nRow = self.wndListView:GetCurrentRow()
		if nRow ~= nil then
			local tItemData = self.wndListView:GetCellData( nRow, 1 )
			local idInfo = tItemData.nId
			HousingLib.PurchaseDecorIntoCrate(idInfo)
			Sound.Play(Sound.PlayUI16BuyVirtual)
		end
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnPlaceBtn(wndControl, wndHandler)

   	self.wndIntSearchWindow:ClearFocus()
	self.wndExtSearchWindow:ClearFocus()

	if self.decorPreview ~= nil then
		self.decorPreview:Place()
	end    
	Sound.Play(Sound.PlayUIHousingHardwareFinalized)
	Sound.Play(Sound.PlayUI16BuyVirtual)

	self:CancelPreviewDecor(false)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnCancelBtn(wndControl, wndHandler) -- cancel a preview item
	Sound.Play(Sound.PlayUIHousingItemCancelled)
	self:ClearCrateSelection()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:ClearCrateSelection()
   	self.wndIntSearchWindow:ClearFocus()
	self.wndExtSearchWindow:ClearFocus()

	self.wndMessageDisplay:SetText(kstrSelectNew)
	self:HelperTogglePreview(false)
	self.wndTogglePreview:Enable(false)
	self:CancelPreviewDecor(true)
	self.idSelectedItem = nil
    self.eSelectedItemType = nil
	self.wndListView:SetCurrentRow(0)
	self.wndBuyToCrateButton:Enable(false)
	self:OnCancelFreePlace()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnDecorateBuy(wndControl, wndHandler)
   	self.wndIntSearchWindow:ClearFocus()
	self.wndExtSearchWindow:ClearFocus()  

	if self.decorPreview ~= nil then
		self.decorPreview:Place()
	end
	
	Sound.Play(Sound.PlayUIHousingHardwareFinalized)
	Sound.Play(Sound.PlayUI16BuyVirtual)

	self:CancelPreviewDecor(false)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnDecoratePlace(wndControl, wndHandler)

	if self.decorPreview ~= nil then
		self.decorPreview:Place()
	end   
	
	Sound.Play(Sound.PlayUIHousingHardwareFinalized)
	Sound.Play(Sound.PlayUI16BuyVirtual)

	self:CancelPreviewDecor(false)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnDecoratePreviewCancel(wndControl, wndHandler)
	Sound.Play(Sound.PlayUIHousingItemCancelled)
	self:CancelPreviewDecor(true)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnSearchChanged(wndControl, wndHandler)
    if self.bIsWarplot and self.wndIntSearchWindow:GetText() ~= "" then
        self.wndIntClearSearchBtn:Show(true)
    elseif self.bPlayerIsInside and self.wndIntSearchWindow:GetText() ~= "" then
        self.wndIntClearSearchBtn:Show(true)
    elseif not self.bPlayerIsInside and self.wndExtSearchWindow:GetText() ~= "" then
        self.wndExtClearSearchBtn:Show(true)
    else
        self.wndIntClearSearchBtn:Show(false)
        self.wndExtClearSearchBtn:Show(false)    
    end	

    self:ShowDecorateWindow(true)
end
---------------------------------------------------------------------------------------------------
function HousingDecorate:OnClearSearchText(wndControl, wndHandler)
   	self.wndIntSearchWindow:ClearFocus()
	self.wndExtSearchWindow:ClearFocus()
	self.wndIntSearchWindow:SetText("")
    self.wndExtSearchWindow:SetText("")
    self.wndIntClearSearchBtn:Show(false)
    self.wndExtClearSearchBtn:Show(false)
    self:OnSearchChanged(wndControl, wndHandler)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnWindowClosed() -- might not be used?
	-- called after the window is closed by:
	--	self.winMasterCustomizeFrame:Close() or 
	--  hitting ESC or
	--  C++ calling Event_CloseHousingDecorateWindow()
	

	-- popup windows reset
	self:ResetPopups()
	
	self:DestroyCategoryList()
	
	-- any preview decorItems reset
	self:CancelPreviewDecor(true)
	self:OnCancelFreePlace()
	
	self.wndListView:DeleteAll()
	self.wndListView:SetCurrentRow(0)
	self.wndBuyToCrateButton:Enable(false)
	self.idSelectedItem = 0
	self.eSelectedItemType = 0
	self.tDecorList = nil
	self.wndIntSearchWindow:SetText("")
	self.wndExtSearchWindow:SetText("")
	self.wndIntClearSearchBtn:Show(false)
   	self.wndExtClearSearchBtn:Show(false)
	
	Sound.Play(Sound.PlayUIWindowClose)
end
---------------------------------------------------------------------------------------------------
function HousingDecorate:OnCloseHousingDecorateWindow()
	-- close the window which will trigger OnWindowClosed
	self.wndDecorate:Close()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnMannequinWarningCloseBtn()
    if self.wndMannequinMsgFrame ~= nil then
        self.wndMannequinMsgFrame:Show(false)
        self.wndMannequinMsgFrame:Destroy()
        self.wndMannequinMsgFrame = nil
    end    
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:ShowDecorateWindow(bClear)
    self.wndExtHeaderWindow:Show(not self.bPlayerIsInside and not self.bIsWarplot)
    self.wndIntHeaderWindow:Show(self.bPlayerIsInside or self.bIsWarplot)
    
    local strSearchText = nil
    if self.bPlayerIsInside or self.bIsWarplot then
    	strSearchText = self.wndIntSearchWindow:GetText()
        self.wndSortByList = self.wndDecorate:FindChild("IntSortByList")
		local resHousing  = HousingLib.GetResidence()
		self.wndDecorate:FindChild("btn_IncreaseLimits"):Show(resHousing:GetCurrentMaxPlacedDecorInterior() < resHousing:GetMaxPlacedDecorInterior() and self.bStoreLinkValid)
    else
    	strSearchText = self.wndExtSearchWindow:GetText()
        self.wndSortByList = self.wndDecorate:FindChild("ExtSortByList")
		local resHousing = HousingLib.GetResidence()
		self.wndDecorate:FindChild("btn_IncreaseLimits"):Show(resHousing:GetCurrentMaxPlacedDecorExterior() < resHousing:GetMaxPlacedDecorExterior() and self.bStoreLinkValid)
    end
    
    self.wndExtShowOnlyToggleBtn:Show(self.bIsVendor)
    self.wndIntShowOnlyToggleBtn:Show(self.bIsVendor)
	self.wndExtHeaderWindow:FindChild("ShowExteriorOnlyTxt"):Show(self.bIsVendor)
	self.wndIntHeaderWindow:FindChild("ShowInteriorOnlyTxt"):Show(self.bIsVendor)

    if self.bIsVendor then
		self.wndBuyButton:SetText(Apollo.GetString("HousingDecorate_Buy"))
		self.wndDeleteButton:Show(false)
        self.wndVendorList:Show(true)
        self.wndDecorate:FindChild("StructureList"):Show(false) 
        self.wndListView = self.wndDecorate:FindChild("VendorList")
		self.wndTogglePreview = self.wndDecorate:FindChild("PreviewVendorToggle")
		self.wndPreview = self.wndDecorate:FindChild("PreviewVendorFrame")
		self.wndDecorate:FindChild("VendorAssets"):Show(true)
		self.wndDecorate:FindChild("CrateAssets"):Show(false)
        self.tDecorList = HousingLib.GetDecorCatalogList(strSearchText)
    else
  		self.wndBuyButton:SetText(Apollo.GetString("HousingDecorate_Place"))
  		self.wndDeleteButton:Show(HousingLib.IsOnMyResidence())
		self.wndVendorList:Show(false)
        self.wndDecorate:FindChild("StructureList"):Show(true)
        self.wndListView = self.wndDecorate:FindChild("StructureList")
		self.wndTogglePreview = self.wndDecorate:FindChild("PreviewCrateToggle")
		self.wndPreview = self.wndDecorate:FindChild("PreviewCrateFrame")
		self.wndDecorate:FindChild("VendorAssets"):Show(false)
		self.wndDecorate:FindChild("CrateAssets"):Show(true)
        self.tDecorList = HousingLib.GetResidence():GetDecorCrateList(strSearchText)
    end
	
	table.sort(self.tDecorList, function(a,b)	return (a.strName < b.strName)	end)
	if bClear then
		self.wndMessageDisplay:SetText(kstrSelectNew)
		
		self:ShowItems(self.wndListView, self.tDecorList, 0)
		self.wndListView:SetCurrentRow(0)
		self.wndBuyToCrateButton:Enable(false)
		self.idSelectedItem = nil
		self.eSelectedItemType = nil	
		self:HelperTogglePreview(false)
		self.wndTogglePreview:Enable(false)
		
		-- remove any existing preview decor
	    self:CancelPreviewDecor(true)
	    
	    if self.decorPreview ~= nil then
            self.decorPreview:CancelTransform()
            self.decorPreview = nil
	    end
	else
		local nCurrentSelection = self.wndListView:GetCurrentRow() 
		local nVScrollPos = self.wndListView:GetVScrollPos()
		self:ShowItems(self.wndListView, self.tDecorList, 0)
		if nCurrentSelection ~= nil then
			self.wndListView:SetCurrentRow(nCurrentSelection)
			self.wndBuyToCrateButton:Enable(true)
			self.wndListView:EnsureCellVisible(nCurrentSelection, 1)
			self.wndTogglePreview:Enable(true)
			
			local tItemData = self.wndListView:GetCellData( nCurrentSelection, 1 )
			
			if tItemData then
				local idItem = tItemData.nId
				self.wndPreview:FindChild("ModelWindow"):SetDecorInfo(idItem)
			else
				self:ClearCrateSelection()
			end
		else
			self.wndListView:SetVScrollPos(nVScrollPos)
		end	
	end
	
	-- close any popups
	self:ResetPopups()
	
	self:UpdateDecorLimits()
	
	self.wndCashDecorate:SetMoneySystem(self.eDisplayedCurrencyType, self.eDisplayedGroupCurrencyType)
	self.wndCashDecorate:SetAmount(GameLib.GetPlayerCurrency(self.eDisplayedCurrencyType, self.eDisplayedGroupCurrencyType), true)
end

function HousingDecorate:UpdateDecorLimits()
	if not self.bPlayerIsInside then
        local nPlacedDecor = HousingLib.GetResidence():GetNumPlacedDecorExterior()
        local nMaxDecor = HousingLib.GetResidence():GetCurrentMaxPlacedDecorExterior()
        strCountDecorPlaced = String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), nPlacedDecor, nMaxDecor)
    else
        local nPlacedDecor = HousingLib.GetResidence():GetNumPlacedDecorInterior()
        local nMaxDecor = HousingLib.GetResidence():GetCurrentMaxPlacedDecorInterior()
        strCountDecorPlaced = String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), nPlacedDecor, nMaxDecor)
	end
	
	local nOwnedDecor = HousingLib.GetResidence():GetNumOwnedDecor()
    nMaxDecor = HousingLib.GetResidence():GetMaxOwnedDecor()
	local strCountDecorOwned = String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), nOwnedDecor, nMaxDecor)
	
	if self.bIsWarplot then
		self.wndDecorate:FindChild("text_MannequinTitle"):Show(false)
		self.wndDecorate:FindChild("text_LightsTitle"):Show(false)
		self.wndDecorate:FindChild("text_SpecialTitle"):Show(false)
		self.wndDecorate:FindChild("text_MannequinLimit"):Show(false)
		self.wndDecorate:FindChild("text_LightsLimit"):Show(false)
		self.wndDecorate:FindChild("text_SpecialLimit"):Show(false)
		self.wndDecorate:FindChild("text_LocalLimitsTitle"):Show(false)
		self.wndDecorate:FindChild("text_GlobalLimitsTitle"):Show(false)

		self.wndDecorate:FindChild("text_DecorPlacedLimit"):SetText(strCountDecorPlaced)
		self.wndDecorate:FindChild("text_DecorOwnedLimit"):SetText(strCountDecorOwned)
		
	else
		nPlacedDecor = HousingLib.GetResidence():GetNumPlacedDecorFromCategory(HousingLib.DecorCategoryLimit.Mannequin, self.bPlayerIsInside)
		nMaxDecor = HousingLib.GetResidence():GetMaxPlacedDecorFromCategory(HousingLib.DecorCategoryLimit.Mannequin)
		local strCountMannequin = String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), nPlacedDecor, nMaxDecor)
		
		nPlacedDecor = HousingLib.GetResidence():GetNumPlacedDecorFromCategory(HousingLib.DecorCategoryLimit.Light, self.bPlayerIsInside)
		nMaxDecor = HousingLib.GetResidence():GetMaxPlacedDecorFromCategory(HousingLib.DecorCategoryLimit.Light)
		local strCountLights = String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), nPlacedDecor, nMaxDecor)
		
		nPlacedDecor = HousingLib.GetResidence():GetNumPlacedDecorFromCategory(HousingLib.DecorCategoryLimit.Special, self.bPlayerIsInside)
		nMaxDecor = HousingLib.GetResidence():GetMaxPlacedDecorFromCategory(HousingLib.DecorCategoryLimit.Special)
		local strCountSpecial = String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), nPlacedDecor, nMaxDecor)
		
		self.wndDecorate:FindChild("text_DecorPlacedLimit"):SetText(strCountDecorPlaced)
		self.wndDecorate:FindChild("text_DecorOwnedLimit"):SetText(strCountDecorOwned)
		self.wndDecorate:FindChild("text_MannequinLimit"):SetText(strCountMannequin)
		self.wndDecorate:FindChild("text_LightsLimit"):SetText(strCountLights)
		self.wndDecorate:FindChild("text_SpecialLimit"):SetText(strCountSpecial)
		self.wndDecorate:FindChild("text_LocalLimitsTitle"):SetText(self.bPlayerIsInside and Apollo.GetString("HousingDecorate_InteriorLimits") or Apollo.GetString("HousingDecorate_ExteriorLimits"))
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:HelperTogglePreview(bShowWnd)
	self.wndTogglePreview:Show(not bShowWnd)
	self.wndPreview:Show(bShowWnd)
end


---------------------------------------------------------------------------------------------------
function HousingDecorate:OnPreviewWindowToggleOut(wndHandler, wndCtrl)
	self:HelperTogglePreview(true)
	self.bHidePreview = false
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnPreviewWindowToggleIn(wndHandler, wndCtrl)
	self:HelperTogglePreview(false)
	self.bHidePreview = true
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnMyResidenceDecorChanged(decorChanged)	
	-- refresh the UI
	if self.decorPreview ~= nil and decorChanged ~= nil and self.decorPreview == decorChanged then
		self:CancelPreviewDecor(false)
		if self.bWaitingForLink then
			self.bWaitingForLink = false
			self:ResetPopups()
		end
	end
	if self.wndDecorate:IsShown() then
	    self:ShowDecorateWindow(false)
	end    
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnHookDecorPlaced(decorPlaced)

	if not gbOnProperty then
        return
    end
    
    local validPlacement = decorPlaced ~= nil and decorPlaced:ValidatePlacement() or false
    local bCanAfford = true
    if self.bIsVendor then
       local nRow = self.wndListView:GetCurrentRow()
	    if nRow ~= nil then
		    local tItemData = self.wndListView:GetCellData( nRow, 1 )
            bCanAfford = GameLib.GetPlayerCurrency(self.eDisplayedCurrencyType, self.eDisplayedGroupCurrencyType):GetAmount() >= tItemData.nCost
        end    
    end
    
    self.bCanPlaceHere = bCanAfford and validPlacement
    self.wndBuyButton:Show(self.bCanPlaceHere)
    self.wndDeleteButton:Enable(false)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlaceDecorPlaced(decorPlaced)

	if not gbOnProperty then
        return
    end
    
    local bValidPlacement = decorPlaced ~= nil and decorPlaced:ValidatePlacement() or false
    local bThereIsRoom = not self.bPlayerIsInside and HousingLib.GetResidence():GetNumPlacedDecorExterior() <= HousingLib.GetResidence():GetCurrentMaxPlacedDecorExterior() or HousingLib.GetResidence():GetNumPlacedDecorInterior() <= HousingLib.GetResidence():GetCurrentMaxPlacedDecorInterior()
    local bCanAfford = true
    if self.bIsVendor then
       local nRow = self.wndListView:GetCurrentRow()
	    if nRow ~= nil then
		    local tItemData = self.wndListView:GetCellData( nRow, 1 )
            bCanAfford = GameLib.GetPlayerCurrency(self.eDisplayedCurrencyType, self.eDisplayedGroupCurrencyType):GetAmount() >= tItemData.nCost
        end    
    end
    
    self.bCanPlaceHere = bCanAfford and bThereIsRoom and bValidPlacement
    self.wndBuyButton:Show(self.bCanPlaceHere)
    self.wndDeleteButton:Enable(false)
end



---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlaceDecor_FromVendor() -- free placing from vendor
	self.wndMessageDisplay:SetText(kstrPlaceFromVendor)
	
	local nRow = self.wndListView:GetCurrentRow()
	if nRow ~= nil then
		local tItemData = self.wndListView:GetCellData( nRow, 1 )
        local idInfo = tItemData.nId
		
		local decorPreview = HousingLib.PreviewVendorDecor(idInfo)
    
		if decorPreview ~= nil then
			Sound.Play(Sound.PlayUIHousingHardwareAddition)
			self.decorPreview = decorPreview
			self:OnActivateDecorIcon(self.decorPreview)
            self.wndBuyButton:Show(self.bCanPlaceHere)
			self.wndCancelButton:Enable(true)
			self.wndDeleteButton:Enable(false)
			self:ShowItems(self.wndListView, self.tDecorList, 0)
		end
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlaceDecor_FromCrate()
	self.wndMessageDisplay:SetText(kstrPlaceFromCrate)
	local nRow = self.wndListView:GetCurrentRow()
	if nRow ~= nil then
		local tItemData = self.wndListView:GetCellData( nRow, 1 )
        local idLow = tItemData.tDecorItems[1].nDecorId
        local idHi = tItemData.tDecorItems[1].nDecorIdHi

		-- put this crate tItemData back in the world!
		local decorPreview = HousingLib.PreviewCrateDecor(idLow, idHi)
        
		if decorPreview ~= nil then
			Sound.Play(Sound.PlayUIHousingHardwareAddition)
			self.decorPreview = decorPreview
			self:OnActivateDecorIcon(self.decorPreview)
			self.wndBuyButton:Show(self.bCanPlaceHere)
			self.wndCancelButton:Enable(true)
			self.wndDeleteButton:Enable(false)
			self:ShowItems(self.wndListView, self.tDecorList, 0)
		end
	end
end

function HousingDecorate:OnCloseFreePlaceControl()
  self:OnCancelFreePlace()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlaceCrateBtn(wndHandler, wndControl)
	if self.decorPreview ~= nil then
		Sound.Play(Sound.PlayUIHousingCrateItem)
		self.decorPreview:Crate()
		self.wndFreePlaceFrame:FindChild("FreePlaceBtn"):Enable(false)
		self.wndFreePlaceFrame:FindChild("CancelFreePlaceBtn"):Enable(false)
		self.decorPreview = nil
	end
	self:ResetPopups()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnChangeWorld()
	if HousingLib.IsHousingWorld() then
		self.nSortType = 0
		self:HelperOnSortByUpdateDropdown(Apollo.GetString("HousingDecorate_AllTypes"))
		self:OnCancelFreePlace()
	end
end

function HousingDecorate:OnCancelFreePlace(wndHandler, wndControl) -- from UI buttons
			    	
	if self.decorPreview ~= nil then
		Sound.Play(Sound.PlayUIHousingItemCancelled)
		self.decorPreview:CancelTransform()
		self.wndFreePlaceFrame:FindChild("FreePlaceBtn"):Enable(false)
		self.wndFreePlaceFrame:FindChild("CancelFreePlaceBtn"):Enable(false)
		self.decorPreview = nil
		self.bCanPlaceHere = false
	end
	self.wndAdvToggle:SetCheck(false)
	self:ResetPopups()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlaceLinkBtn(wndHandler, wndControl)
    if self.decorPreview ~= nil then
		self.bWaitingForLink = true
        local wndOptionsBtn = self.wndToggleFrame:FindChild("OpenDecorOptionsBtn")
        wndOptionsBtn:SetCheck(false)
        self.wndDecorIconOptionsWindow:Show(false)
    end
    self:ResetPopups()

    if self.wndDecorMsgFrame == nil then
        self.wndDecorMsgFrame = Apollo.LoadForm(self.xmlDoc, "DecorateMessageWindow", nil, self)
    end
    self.wndDecorMsgFrame:Show(true)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlaceUnlinkBtn(wndHandler, wndControl)
    if self.decorPreview ~= nil then
        self.decorPreview:Unlink()
        local wndOptionsBtn = self.wndToggleFrame:FindChild("OpenDecorOptionsBtn")
        wndOptionsBtn:SetCheck(false)
        self.wndDecorIconOptionsWindow:Show(false)
		self.decorPreview = nil
    end
    self:ResetPopups()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlaceUnlinkAllBtn(wndHandler, wndControl)
    if self.decorPreview ~= nil then
        self.decorPreview:UnlinkAllChildren()
        local wndOptionsBtn = self.wndToggleFrame:FindChild("OpenDecorOptionsBtn")
        wndOptionsBtn:SetCheck(false)
        self.wndDecorIconOptionsWindow:Show(false)
		self.decorPreview = nil
    end
    self:ResetPopups()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnToggleAdvanced(wndHandler, wndControl)
	self.wndFreePlaceFrame:Show(wndControl:IsChecked())
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlaceConfirmBtn(wndHandler, wndControl)
	if self.decorPreview ~= nil then
		Sound.Play(Sound.PlayUIHousingHardwareFinalized)
		Sound.Play(Sound.PlayUI16BuyVirtual)
		self.decorPreview:Place()
		self.wndFreePlaceFrame:FindChild("FreePlaceBtn"):Enable(false)
		self.wndFreePlaceFrame:FindChild("CancelFreePlaceBtn"):Enable(false)
		self.decorPreview = nil
		self.wndFreePlaceFrame:Show(false)
	end
	self:ResetPopups()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlaceCopyBtn(wndHandler, wndControl)
    if self.decorPreview ~= nil then
        self.tCopyDecorInfo = self.decorPreview:GetDecorIconInfo()
        if self.tCopyDecorInfo ~= nil then
            self.wndFreePlacePasteBtn:Enable(true)
        end
    end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlacePasteBtn(wndHandler, wndControl)
    if self.decorPreview ~= nil and self.tCopyDecorInfo ~= nil and self.tCopyDecorInfo ~= {} then
        if self.wndFreePlaceFrame:FindChild("CopyTranslationBtn"):IsChecked() then
            self.decorPreview:SetPosition(self.tCopyDecorInfo.fWorldPosX, self.tCopyDecorInfo.fWorldPosY, self.tCopyDecorInfo.fWorldPosZ)
        end
        
        if self.wndFreePlaceFrame:FindChild("CopyRotationBtn"):IsChecked() then    
            self.decorPreview:SetRotation(self.tCopyDecorInfo.fPitch, self.tCopyDecorInfo.fRoll, self.tCopyDecorInfo.fYaw)
        end
        
        if self.wndFreePlaceFrame:FindChild("CopyScaleBtn"):IsChecked() then    
            self.decorPreview:SetScale(self.tCopyDecorInfo.fScaleCurrent)
        end
        
		-- To do: if we comment this line out we'll preserve our copy/paste data from one to the next... try this out!
        self.tCopyDecorInfo = nil
        self.wndFreePlacePasteBtn:Enable(false)
    end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlaceCheckBtn(wndHandler, wndControl)
	local bEnabled = self.wndFreePlaceFrame:FindChild("CopyTranslationBtn"):IsChecked()
		or self.wndFreePlaceFrame:FindChild("CopyRotationBtn"):IsChecked()
		or self.wndFreePlaceFrame:FindChild("CopyScaleBtn"):IsChecked()

	self.wndFreePlaceCopyBtn:Enable(bEnabled)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:UpdateFreePlaceControlVisibility()
    local bMove = self.wndFreePlaceToggleMoveControlBtn:IsChecked()
    local bRotate = self.wndFreePlaceToggleRotateControlBtn:IsChecked()
    
    HousingLib.ShowMoveControls(bMove)
    HousingLib.ShowRotateControls(bRotate)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:UpdateFreePlaceControlMode()
    local nControlModeBtnSel = self.wndFreePlaceFrame:FindChild("ScrollContainer"):GetRadioSel("GizmoControlModeBtns")
    if nControlModeBtnSel == 1 then
        HousingLib.SetControlMode(HousingLib.DecorControlMode.Local)
    else
        HousingLib.SetControlMode(HousingLib.DecorControlMode.Global)
    end    
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlace_Move(wndHandler, wndControl)
	if self.decorPreview == nil then
		return 
	end

	self.wndFreePlaceFrame:FindChild("FreePlaceBtn"):Enable(true)
	self.wndFreePlaceFrame:FindChild("CancelFreePlaceBtn"):Enable(true)
	
	local kfSmallMove = 0.05;
	local kfBigMove = 0.5
		
	if wndControl == self.wndFreePlaceFrame:FindChild("MoveForwardBtn") then
		self.decorPreview:Translate(0, 0, kfSmallMove)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("MoveBackBtn") then
		self.decorPreview:Translate(0, 0, -kfSmallMove)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("MoveUpBtn") then
		self.decorPreview:Translate(0, kfSmallMove, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("MoveDownBtn") then
		self.decorPreview:Translate(0, -kfSmallMove, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("MoveLeftBtn") then
		self.decorPreview:Translate(kfSmallMove, 0, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("MoveRightBtn") then
		self.decorPreview:Translate(-kfSmallMove, 0, 0)
	
	
	elseif wndControl == self.wndFreePlaceFrame:FindChild("MoveForwardLongBtn") then
		self.decorPreview:Translate(0, 0, kfBigMove)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("MoveBackLongBtn") then
		self.decorPreview:Translate(0, 0, -kfBigMove)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("MoveUpLongBtn") then
		self.decorPreview:Translate(0, kfBigMove, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("MoveDownLongBtn") then
		self.decorPreview:Translate(0, -kfBigMove, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("MoveLeftLongBtn") then
		self.decorPreview:Translate(kfBigMove, 0, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("MoveRightLongBtn") then
		self.decorPreview:Translate(-kfBigMove, 0, 0)
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnDecorScaleChanged(wndHandler, wndControl)
	if self.decorPreview == nil then
		return 
	end
	
    self.wndFreePlaceFrame:FindChild("FreePlaceBtn"):Enable(true)
	self.wndFreePlaceFrame:FindChild("CancelFreePlaceBtn"):Enable(true)
	
    local fScaleValue = wndHandler:GetValue()
    self.decorPreview:SetScale(fScaleValue/100.0)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnScaleEdited(wndHandler, wndControl)
	if self.decorPreview == nil then
		return 
	end
	
    local fScaleValue = tonumber(wndHandler:GetText())
    
	self.decorPreview:SetScale(fScaleValue)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlace_Rotate(wndHandler, wndControl)
	if self.decorPreview == nil then
		return 
	end
	
	self.wndFreePlaceFrame:FindChild("FreePlaceBtn"):Enable(true)
	self.wndFreePlaceFrame:FindChild("CancelFreePlaceBtn"):Enable(true)
	
	local kfSmallRotation = 0.785398163/8
	local kfBigRotation   = 0.785398163/2
	
	if wndControl == self.wndFreePlaceFrame:FindChild("RotateXPosBtn") then
		self.decorPreview:Rotate(kfSmallRotation, 0, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("RotateXNegBtn") then
		self.decorPreview:Rotate(-kfSmallRotation, 0, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("RotateYPosBtn") or wndControl == self.wndDecorIconOptionsWindow:FindChild("RotateYPosBtn") then
		self.decorPreview:Rotate(0, kfSmallRotation, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("RotateYNegBtn") or wndControl == self.wndDecorIconOptionsWindow:FindChild("RotateYNegBtn") then
		self.decorPreview:Rotate(0, -kfSmallRotation, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("RotateZPosBtn") then
		self.decorPreview:Rotate(0, 0, kfSmallRotation)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("RotateZNegBtn") then
		self.decorPreview:Rotate(0, 0, -kfSmallRotation)
	
	elseif wndControl == self.wndFreePlaceFrame:FindChild("RotateXPosLongBtn") then
		self.decorPreview:Rotate(kfBigRotation, 0, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("RotateXNegLongBtn") then
		self.decorPreview:Rotate(-kfBigRotation, 0, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("RotateYPosLongBtn") then
		self.decorPreview:Rotate(0, kfBigRotation, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("RotateYNegLongBtn") then
		self.decorPreview:Rotate(0, -kfBigRotation, 0)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("RotateZPosLongBtn") then
		self.decorPreview:Rotate(0, 0, kfBigRotation)
	elseif wndControl == self.wndFreePlaceFrame:FindChild("RotateZNegLongBtn") then
		self.decorPreview:Rotate(0, 0, -kfBigRotation)
	end
end

function HousingDecorate:OnFreePlace_ResetOrientation()
	if self.decorPreview ~= nil then
		self.decorPreview:ResetOrientation() 
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnCancelDestroyDecor(wndHandler, wndControl)
	if self.decorPreview ~= nil then
		Sound.Play(Sound.PlayUIHousingItemCancelled)
		self.decorPreview:CancelTransform()
		self.wndFreePlaceFrame:FindChild("FreePlaceBtn"):Enable(false)
		self.wndFreePlaceFrame:FindChild("CancelFreePlaceBtn"):Enable(false)
		self.decorPreview = nil
	end
	
	self:ResetPopups()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnDestroyDecorConfirmExit()
    if self.wndDestroyDecorFrame ~= nil then
        self.wndDestroyDecorFrame:Destroy()
        self.wndDestroyDecorFrame = nil
    end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnDestroyDecorExit()
    self:ResetPopups()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnDestroyDecorAccept(handler, control)
    if self.bFromCrate then
        local nRow = self.wndListView:GetCurrentRow()
        if nRow ~= nil then
            local tItemData = self.wndListView:GetCellData( nRow, 1 )
            if tItemData ~= nil then
                local nCount = 1
                for idx = 1, self.nDestroyCrateDecorCurrValue do 
                    local idLow = tItemData.tDecorItems[idx].nDecorId
                    local idHi = tItemData.tDecorItems[idx].nDecorIdHi
                    HousingLib.GetResidence():DestroyDecorFromCrate(idLow, idHi)
                end
            end
        end
    end    
	if self.decorToDelete ~= nil then
		self.decorToDelete:DestroyDecor()
		if self.decorToDelete == self.decorPreview then
			self.decorPreview = nil
		end
		self.decorToDelete = nil
    end    

    self.bFromCrate = false
	self:ResetPopups()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnOpenDestroyDecorControl(decorDelete, bFromCrate)
	self.bFromCrate = bFromCrate
	self.decorToDelete = decorDelete
	self.wndDestroyDecorFrame = Apollo.LoadForm(self.xmlDoc, "DestroyDecorWindow", nil, self)
	self.wndDestroyDecorFrame:Show(true)
	self.wndDestroyDecorFrame:ToFront()
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlaceDestroyBtn()
	if self.decorPreview ~= nil then
		self:OnOpenDestroyDecorControl(self.decorPreview, false)
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnDeleteBtn()
	local nRow = self.wndListView:GetCurrentRow()
	if nRow ~= nil then
		local nCount = self.wndListView:GetCellData( nRow, 2 )
		if nCount ~= nil and nCount > 0 then
		    if self.wndDestroyCrateDecorFrame == nil then
		        self.wndDestroyCrateDecorFrame = Apollo.LoadForm(self.xmlDoc, "PopupDestroyCrateDecor", nil, self)
		    end
		    self.wndDestroyCrateDecorFrame:Show(true)
	        self.wndDestroyCrateDecorFrame:ToFront()
	        self.nDestroyCrateDecorTotal = nCount
	        self.nDestroyCrateDecorCurrValue = 1
	        self.wndDestroyCrateDecorFrame:FindChild("DecorTotal"):SetText(String_GetWeaselString(Apollo.GetString("Achievements_ProgressBarProgress"), self.nDestroyCrateDecorCurrValue, self.nDestroyCrateDecorTotal))
	    end
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnOnlyShowToggle()
    if self.bPlayerIsInside then
        self.bFilterCanUseOnly = self.wndIntShowOnlyToggleBtn:IsChecked()
        self.wndExtShowOnlyToggleBtn:SetCheck(self.bFilterCanUseOnly)
    else
        self.bFilterCanUseOnly = self.wndExtShowOnlyToggleBtn:IsChecked()
        self.wndIntShowOnlyToggleBtn:SetCheck(self.bFilterCanUseOnly)
    end
    self:ShowItems(self.wndListView, self.tDecorList, 0)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnHousingAdvancedChecked()
	if not self.bIsWarplot then
		HousingLib.GetResidence():SetCustomizationMode(HousingLib.ResidenceCustomizationMode.Advanced)

        local bMove = self.wndFreePlaceToggleMoveControlBtn:IsChecked()
        local bRotate = self.wndFreePlaceToggleRotateControlBtn:IsChecked()

        HousingLib.ShowMoveControls(bMove)
        HousingLib.ShowRotateControls(bRotate)
		
		self.wndFreePlaceToggleMoveControlBtn:Enable(true)
		self.wndFreePlaceToggleRotateControlBtn:Enable(true)
		
        self.wndFreePlaceLocalModeBtn:Enable(true)
        self.wndFreePlaceGlobalModeBtn:Enable(true)
        if HousingLib.GetControlMode() == HousingLib.DecorControlMode.Local then
            self.wndFreePlaceFrame:FindChild("ScrollContainer"):SetRadioSel("GizmoControlModeBtns", 1)
        else
            self.wndFreePlaceFrame:FindChild("ScrollContainer"):SetRadioSel("GizmoControlModeBtns", 2)
        end    
		
		self:UpdateFreePlaceControlVisibility()
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnHousingAdvancedUnchecked()
	self.wndFreePlaceToggleMoveControlBtn:Enable(false)
	self.wndFreePlaceToggleRotateControlBtn:Enable(false)
	
    self.wndFreePlaceLocalModeBtn:Enable(false)
    self.wndFreePlaceGlobalModeBtn:Enable(false)
    self.wndFreePlaceFrame:FindChild("ScrollContainer"):SetRadioSel("GizmoControlModeBtns", 1)
		
	if not self.bIsWarplot then
		HousingLib.GetResidence():SetCustomizationMode(HousingLib.ResidenceCustomizationMode.Simple)
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnDestroyCrateDecor()
    self:OnOpenDestroyDecorControl(nil, true)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnDecDestroyDecorCount()
    self.nDestroyCrateDecorCurrValue = self.nDestroyCrateDecorCurrValue - 1
    if self.nDestroyCrateDecorCurrValue < 1 then
        self.nDestroyCrateDecorCurrValue = 1
    end
    
    if self.wndDestroyCrateDecorFrame ~= nil then
        self.wndDestroyCrateDecorFrame:FindChild("DecorTotal"):SetText(String_GetWeaselString(Apollo.GetString("Achievements_ProgressBarProgress"), self.nDestroyCrateDecorCurrValue, self.nDestroyCrateDecorTotal))
    end    
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnIncDestroyDecorCount()
    self.nDestroyCrateDecorCurrValue = self.nDestroyCrateDecorCurrValue + 1
    if self.nDestroyCrateDecorCurrValue > self.nDestroyCrateDecorTotal then
        self.nDestroyCrateDecorCurrValue = self.nDestroyCrateDecorTotal
    end
    
    if self.wndDestroyCrateDecorFrame ~= nil then       
	    self.wndDestroyCrateDecorFrame:FindChild("DecorTotal"):SetText(String_GetWeaselString(Apollo.GetString("Achievements_ProgressBarProgress"), self.nDestroyCrateDecorCurrValue, self.nDestroyCrateDecorTotal))
	end    
end

-----------------------------------------------------------------------------------------------
-- DecorateItemList Functions
-----------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function HousingDecorate:OnDecorateListItemChange(wndControl, wndHandler, nX, nY)
   	self.wndIntSearchWindow:ClearFocus()
	self.wndExtSearchWindow:ClearFocus()
 
	-- Show hooks that apply to this decor tItemData's hook type.
	local nRow = wndControl:GetCurrentRow()
	local bCanAfford = false
	local idItem = 0
	if nRow ~= nil then
		local tItemData = self.wndListView:GetCellData( nRow, 1 )
		idItem = tItemData.nId
		if tItemData.eCurrencyType then
			self.eDisplayedCurrencyType = tItemData.eCurrencyType
		end
		if tItemData.eGroupCurrencyType then
			self.eDisplayedGroupCurrencyType = tItemData.eGroupCurrencyType
		end
		bCanAfford = GameLib.GetPlayerCurrency(self.eDisplayedCurrencyType, self.eDisplayedGroupCurrencyType):GetAmount() >= tItemData.nCost
	end

	self.wndBuyToCrateButton:Enable(idItem ~= 0 and bCanAfford)

	self.wndTogglePreview:Enable(true)
	
	self.wndDeleteButton:Enable(HousingLib.IsOnMyResidence())
		
	if idItem ~= 0 then
		self.wndPreview:FindChild("ModelWindow"):SetAnimated(true)
		self.wndPreview:FindChild("ModelWindow"):SetDecorInfo(idItem)
		
		self.wndCashDecorate:SetMoneySystem(self.eDisplayedCurrencyType, self.eDisplayedGroupCurrencyType)
		self.wndCashDecorate:SetAmount(GameLib.GetPlayerCurrency(self.eDisplayedCurrencyType, self.eDisplayedGroupCurrencyType), true)
	end
	
	if self.decorPreview ~= nil then
	    self.decorPreview:CancelTransform()
		self.decorPreview = nil
	    if self.bIsVendor then
            self:OnFreePlaceDecor_FromVendor()
        else
            self:OnFreePlaceDecor_FromCrate()
        end   
	else
	    local tItemData = self.wndListView:GetCellData( nRow, 1 )
	    local tItemType = tItemData.eHookType
	    if tItemType == HousingLib.CodeEnumDecorHookType.DefaultHook then
	        self.wndMessageDisplay:SetText(kstrPreviewOnHook)
	    else
	        self.wndMessageDisplay:SetText(kstrPreviewInWorld)
	    end
		self:HelperTogglePreview(not self.bHidePreview)
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:ShowItems(wndControl, tItemList, idPrune)

   local eSelectedType = 0

    if wndControl ~= nil then
        local nCurrentSelection = wndControl:GetCurrentRow()
        if nCurrentSelection ~= nil then
            local tItemData = self.wndListView:GetCellData( nCurrentSelection, 1 )
            self.idSelectedItem = tItemData.nId
            local tSelectedItem = self:GetItem(self.idSelectedItem, tItemList)
            if tSelectedItem ~= nil then
                self.eSelectedItemType = tSelectedItem.eHookType
            end
        end
		wndControl:DeleteAll()
	end

	if tItemList ~= nil then
		-- determine where we start and end based on page size
		local crRed = CColor.new(1.0, 0, 0, 1.0)
		local crWhite = CColor.new(1.0, 1.0, 1.0, 1.0)
		--local crGrey = CColor.new(22/255, 71/255, 84/255, 1.0)
		local crGrey = CColor.new(0, 0, 0, 1.0)

        if #tItemList > 0 then
            if self.decorPreview and not self.decorPreview:IsPreview() and not self.bIsVendor then
                self.wndDeleteButton:Enable(HousingLib.IsOnMyResidence())
            end
        else
            self.wndDeleteButton:Enable(false)
            return
        end
		-- populate the buttons with the tItemData data
		for idx = 1, #tItemList do
	
			local tItemData = tItemList[idx]
			
			local bPruneByInteriorExterior = false
            if self.bFilterCanUseOnly and self.bIsVendor then
                local eCurrencyType = tItemData.eCurrencyType
                local eGroupCurrencyType = tItemData.eGroupCurrencyType
                local monCash = GameLib.GetPlayerCurrency(eCurrencyType, eGroupCurrencyType):GetAmount()
                if tItemData.nCost > monCash then
                    bPruneByInteriorExterior = true
                end
            end
			    
			if (self.nSortType == 0 or tItemData.eDecorType == self.nSortType) and not bPruneByInteriorExterior then
				-- AddRow implicitly works on column one.  Every column can have it's own hidden data associated with it!
				local i = wndControl:AddRow("" .. tItemData.strName, "", tItemData)
				local bPruned = false

				-- this idPrune means we've want to disallow this tItemData (let's show it as a disabled row) 
				if idPrune == tItemData.nId then
					bPruned = true
					wndControl:EnableRow(i, false)
				end
			
			    if self.bIsVendor then
                    local strDoc = Apollo.GetString("CRB_Free_pull")
                    
                    local eCurrencyType = tItemData.eCurrencyType
					local eGroupCurrencyType = tItemData.eGroupCurrencyType
		            local monCash = GameLib.GetPlayerCurrency(eCurrencyType, eGroupCurrencyType):GetAmount()
		
                    self.wndCashDecorate:SetMoneySystem(eCurrencyType, eGroupCurrencyType)
					self.wndCashDecorate:SetAmount(GameLib.GetPlayerCurrency(eCurrencyType, eGroupCurrencyType))

                    if tItemData.nCost > monCash then
                        strDoc = self.wndCashDecorate:GetAMLDocForAmount(tItemData.nCost, true, crRed)
                    elseif bPruned == true then
						strDoc = self.wndCashDecorate:GetAMLDocForAmount(0, true, crGrey)
                    else
                        strDoc = self.wndCashDecorate:GetAMLDocForAmount(tItemData.nCost, true, crWhite)
                    end
                        
                    wndControl:SetCellData(i, 2, "", "", tItemData.nCost)
                    wndControl:SetCellDoc(i, 2, strDoc)
                    
                    if tItemData.splBuff ~= nil and tItemData.splBuff ~= {} then
                        wndControl:SetCellImage(i, 3, tItemData.splBuff:GetIcon())
						wndControl:SetCellSortText(i, 3, tItemData.splBuff:GetName())
                    end
                    
				else
				    wndControl:SetCellData(i, 2, tItemData.nCount, "", tItemData.nCount)
				    
				    if tItemData.splBuff ~= nil and tItemData.splBuff ~= {} then
                        wndControl:SetCellImage(i, 3, tItemData.splBuff:GetIcon())
						wndControl:SetCellSortText(i, 3, tItemData.splBuff:GetName())
                    end
				end
	
			end
		end
		self:ReselectPreviousItemById(wndControl)
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:ReselectPreviousItemById(wndControl)
	local nCount = wndControl:GetRowCount()
	for idx = 1, nCount do
		local tItemData = self.wndListView:GetCellData( idx, 1 )
		if tItemData.nId == self.idSelectedItem then
			wndControl:SetCurrentRow(idx)
			self.wndBuyToCrateButton:Enable(true)
			wndControl:EnsureCellVisible(idx, 1)
			--If tItemData.eCurrencyType and tItemData.eGroupCurrencyType are both nil then it came from previewing a crated item, which doesn't show currencies.
			if tItemData.eCurrencyType and tItemData.eGroupCurrencyType then
				local eCurrencyType = tItemData.eCurrencyType
				local eGroupCurrencyType = tItemData.eGroupCurrencyType
				self.wndCashDecorate:SetMoneySystem(eCurrencyType, eGroupCurrencyType)
				self.wndCashDecorate:SetAmount(GameLib.GetPlayerCurrency(eCurrencyType, eGroupCurrencyType))
			end
			return
		end
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:GetItem(idItem, tItemList)
  for idx = 1, #tItemList do
    tItemData = tItemList[idx]
    if tItemData.nId == idItem then
      return tItemData
    end
  end
  return nil
end

-----------------------------------------------------------------------------------------------
-- HousingDecorate Category Dropdown functions
-----------------------------------------------------------------------------------------------

function HousingDecorate:OnDecorateTypeTabBtn(wndHandler, wndControl, eMouseButton)
	self:PopulateCategoryList()
	self:HelperSortByItemSelected({["nId"]=0, ["strName"] = Apollo.GetString("HousingDecorate_AllTypes")})
end

function HousingDecorate:OnSortByUncheck()
   	self.wndIntSearchWindow:ClearFocus()
	self.wndExtSearchWindow:ClearFocus()
	
	if self.bPlayerIsInside or self.bIsWarplot then
	    self.wndDecorate:FindChild("IntSortByWindow"):Show(false)
	else
	    self.wndDecorate:FindChild("ExtSortByWindow"):Show(false)
	end
	self.wndListView:Enable(true)
end

function HousingDecorate:OnSortByCheck()
   	self.wndIntSearchWindow:ClearFocus()
	self.wndExtSearchWindow:ClearFocus()
	
    self:PopulateCategoryList()

    if self.bPlayerIsInside or self.bIsWarplot then
	    self.wndDecorate:FindChild("IntSortByWindow"):Show(true)
	else
	    self.wndDecorate:FindChild("ExtSortByWindow"):Show(true)
	end
	
	-- disable the list and any buttons that might steal input from the list box
	self.wndListView:Enable(false)
end

function HousingDecorate:OnSortByItemSelected(wndHandler, wndControl)
	if not wndControl then 
        return 
    end
	
	self:HelperSortByItemSelected(wndControl:GetData())
end

function HousingDecorate:HelperSortByItemSelected(tItemData)
	-- cancal any current preview or free place
	self:CancelPreviewDecor(true)
	self:OnCancelFreePlace()

    if tItemData ~= nil then
        self.nSortType = tItemData.nId
        self:HelperOnSortByUpdateDropdown(tItemData.strName)
	end
	
    self.wndMessageDisplay:SetText(kstrSelectNew)
	self:HelperTogglePreview(false)
	self.wndTogglePreview:Enable(false)
	self.wndListView:SetCurrentRow(0)
	self.wndBuyToCrateButton:Enable(false)
    self.idSelectedItem = nil
    self.eSelectedItemType = nil
    self.wndListView:Enable(true)
end

function HousingDecorate:HelperOnSortByUpdateDropdown(strDropdownText)
    if self.bPlayerIsInside or self.bIsWarplot then
        self.wndDecorate:FindChild("IntSortByBtn"):SetText(strDropdownText)
		self.wndDecorate:FindChild("IntSortByBtn"):SetCheck(false)
        self.wndDecorate:FindChild("IntSortByWindow"):Show(false)
    else
        self.wndDecorate:FindChild("ExtSortByBtn"):SetText(strDropdownText)
		self.wndDecorate:FindChild("ExtSortByBtn"):SetCheck(false)
        self.wndDecorate:FindChild("ExtSortByWindow"):Show(false)
        
    end
    -- update the list
    self:ShowItems(self.wndListView, self.tDecorList, 0)
   -- self.wndListView:Enable(true)
end

-- populate item list
function HousingDecorate:PopulateCategoryList()
	local nScrollPosition = self.wndSortByList:GetVScrollPos()
	
	-- make sure the tItemData list is empty to start with
	self:DestroyCategoryList()
	self.wndSortByList:DestroyChildren()
	
	if self.tDecorList == nil or self.bPlayerIsInside == nil or self.bIsWarplot == nil then
	    return
	end

    -- grab the list of categories
    local tCategoryList = HousingLib.GetDecorTypeList()
	
	-- sort the list alphabetically
	table.sort(tCategoryList, function(a,b) return (a.strName < b.strName)	end)
	
	-- nCount the number of items in each category
	local nItemsByFilterType = 0
	self.nItemByType = {}
	for idx = 1, #self.tDecorList do
	    local tItemData = self.tDecorList[idx]
	    if tItemData ~= nil then		
	        local eDecorType = tItemData.eDecorType
	        if self.nItemByType[eDecorType] == nil then
	            self.nItemByType[eDecorType] = 0
	        end

            self.nItemByType[eDecorType] = self.nItemByType[eDecorType] + 1
            nItemsByFilterType = nItemsByFilterType + 1
	    end
	end
	
	-- populate the list
    if tCategoryList ~= nil then
        local tFirstItemData = {}
        tFirstItemData.strName = Apollo.GetString("HousingDecorate_AllTypes")
        tFirstItemData.nId= 0
        self:AddCategoryItem(1, tFirstItemData, nItemsByFilterType)
        for idx = 1, #tCategoryList do
            local eType = tCategoryList[idx].nId
            local nCount = self.nItemByType[eType] ~= nil and self.nItemByType[eType] or 0
            if nCount > 0 then
				self:AddCategoryItem(idx + 1, tCategoryList[idx], nCount)
			end
        end
    end
    
    self.tCategoryList = tCategoryList
	
	-- now all the iteam are added, call ArrangeChildrenVert to list out the list items vertically
	self.wndSortByList:ArrangeChildrenVert()
	self.wndSortByList:SetVScrollPos(nScrollPosition)
end

-- clear the item list
function HousingDecorate:DestroyCategoryList()
	-- destroy all the wnd inside the list
	for idx, wndListItem in ipairs(self.tCategoryItems) do
		wndListItem:Destroy()
	end

	-- clear the list item array
	self.tCategoryItems = {}
end

-- add an item into the item list
function HousingDecorate:AddCategoryItem(nIndex, tItemData, nCount)
	-- load the window tItemData for the list tItemData
	local wndListItem = Apollo.LoadForm(self.xmlDoc, "CategoryListItem", self.wndSortByList, self)
	
	-- keep track of the window tItemData created
	self.tCategoryItems[nIndex] = wndListItem
	
	-- Adjust the anchor offsets for the parent window
	--[[sortl, sortt, sortr, sortb = self.wndSortByList:GetAnchorOffsets()
	local itemHeight = self.tCategoryItems[nIndex]:GetHeight()
	self.wndSortByList:SetAnchorOffsets(sortl, sortt, sortr, sortt+nIndex*itemHeight)--]]

	-- give it a piece of data to refer to 
	local wndItemBtn = wndListItem:FindChild("CategoryBtn")
	if wndItemBtn then -- make sure the text wndListItem exist
	    local strName = tItemData.strName
		wndItemBtn:SetText(String_GetWeaselString(Apollo.GetString("HealthBar_HealthTextFullShield"), strName, nCount))
		wndItemBtn:SetData(tItemData)
	end
	--wndListItem:SetData(type)
end

-- when a list item is selected
function HousingDecorate:OnCategoryListItemSelected(wndHandler, wndControl)
    -- make sure the wndControl is valid
    if wndHandler ~= wndControl then
        return
    end
    
    -- change the old item's text color back to normal color
    --[[local wndItemText
    if self.wndSelectedListItem ~= nil then
        wndItemText = self.wndSelectedListItem:FindChild("Text")
        wndItemText:SetTextColor(kcrNormalText)
    end
    
	-- wndControl is the item selected - change its color to selected
	self.wndSelectedListItem = wndControl
	wndItemText = self.wndSelectedListItem:FindChild("Text")
    wndItemText:SetTextColor(kcrSelectedText)
    
	Print( "item " ..  self.wndSelectedListItem:GetData() .. " is selected.")--]]
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnRotateRightBegin()
	self.wndPreview:FindChild("ModelWindow"):ToggleLeftSpin(true)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnRotateRightEnd()
	self.wndPreview:FindChild("ModelWindow"):ToggleLeftSpin(false)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnRotateLeftBegin()
	self.wndPreview:FindChild("ModelWindow"):ToggleRightSpin(true)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnRotateLeftEnd()
	self.wndPreview:FindChild("ModelWindow"):ToggleRightSpin(false)
end


-----------------------------------------------------------------------------------------------
-- HousingDecorate Decor Icon Functions
-----------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function HousingDecorate:OnFreePlaceDecorQuery() -- This is first and fires once
	if not gbOnProperty then
        return
    end
    
	if self.wndDecorate:IsVisible() and self.wndListView:GetCurrentRow() ~= nil then
		self:CancelPreviewDecor(true)

        if self.bIsVendor then
            self:OnFreePlaceDecor_FromVendor()
        else
            self:OnFreePlaceDecor_FromCrate()
        end
        self.wndDecorIconOptionsWindow:FindChild("LinkBtn"):Show(false)
        self.wndDecorIconOptionsWindow:FindChild("UnlinkBtn"):Show(false)
        self.wndDecorIconOptionsWindow:FindChild("UnlinkAllBtn"):Show(false)
        self.wndDecorIconOptionsWindow:FindChild("RecallBtn"):Show(false)    
    else
		-- (!) NOTE TO SELF: This is where we could support "sticky targeting" - AC
		if not self.bWaitingForLink then
			if self.decorPreview ~= nil then
				self.decorPreview:CancelTransform()
				self:OnDeactivateDecorIcon()
				self.decorPreview = nil
			end
			self.wndFreePlaceFrame:Show(false)
		end
	end
end

function HousingDecorate:OnFreePlaceDecorSelected(decorSelection)
	if self.wndDecorate:IsVisible() and self.wndListView:GetCurrentRow() ~= nil then
		if decorSelection ~= nil then
			decorSelection:CancelTransform()
		end
		self:OnFreePlaceDecorQuery()
		return
	end
    if self.decorPreview ~= decorSelection then -- select a decor item to edit it
		-- shut down the vender UI
		self:OnCloseHousingDecorateWindow()
		
		if self.bWaitingForLink then
			if decorSelection ~= nil then
				self.decorPreview:Link(decorSelection)
				decorSelection:CancelTransform()
			end
			self:ResetPopups()
			self.bWaitingForLink = false
			return
		end
		self.decorPreview = decorSelection
		
		if self.decorPreview ~= nil then
		    -- Activate the decor icon
		    self:OnActivateDecorIcon(self.decorPreview)
		    self:UpdateFreePlaceControlVisibility()
		
			local eDecorTypeForEdit = self.decorPreview:GetHookType()
            local bCanScale = (eDecorTypeForEdit == HousingLib.CodeEnumDecorHookType.FreePlace or eDecorTypeForEdit == HousingLib.CodeEnumDecorHookType.Landscape) and true or false
            local bCanTranslateAndRotate = (bCanScale == true or eDecorTypeForEdit == HousingLib.CodeEnumDecorHookType.WarplotFreePlace or eDecorTypeForEdit == HousingLib.CodeEnumDecorHookType.Landscape or eDecorTypeForEdit == HousingLib.CodeEnumDecorHookType.Mannequin) and true or false

            self.wndDecorIconOptionsWindow:FindChild("ScaleControls"):Show(false)
            self.wndDecorIconOptionsWindow:FindChild("LinkBtn"):Show(false)
            self.wndDecorIconOptionsWindow:FindChild("UnlinkBtn"):Show(false)
            self.wndDecorIconOptionsWindow:FindChild("UnlinkAllBtn"):Show(false)
            self.wndDecorIconOptionsWindow:FindChild("RecallBtn"):Show(true)
            self.wndAdvToggle:Show(false)
            
            if not self.bIsWarplot then
                self.wndDecorIconOptionsWindow:FindChild("ScaleControls"):Show(true)
                self.wndDecorIconOptionsWindow:FindChild("LinkBtn"):Show(true)
                
                self.wndAdvToggle:Show(true)
                self.wndFreePlaceFrame:Show(self.wndAdvToggle:IsChecked()) -- TODO: outside check
                self.wndFreePlaceFrame:FindChild("FreePlaceBtn"):Enable(true)
                self.wndFreePlaceFrame:FindChild("CancelFreePlaceBtn"):Enable(true)	
                
                if self.decorPreview:IsChild() then
                    self.wndDecorIconOptionsWindow:FindChild("LinkBtn"):Show(false)
                    self.wndDecorIconOptionsWindow:FindChild("UnlinkBtn"):Show(true)
                end
                
                if self.decorPreview:IsParent() then
                    self.wndDecorIconOptionsWindow:FindChild("UnlinkAllBtn"):Show(true)
                end    
            end
            
            if not bCanScale and not bCanTranslateAndRotate then -- outside, unaffectable items
                self.wndDecorIconOptionsWindow:FindChild("ScaleControls"):Show(false)
                self.wndDecorIconOptionsWindow:FindChild("LinkBtn"):Show(false)
                self.wndDecorIconOptionsWindow:FindChild("UnlinkBtn"):Show(false)
                self.wndDecorIconOptionsWindow:FindChild("UnlinkAllBtn"):Show(false)
            end
            
            -- main options            
            self.wndFreePlaceFrame:FindChild("ScaleDownBtn"):Enable(bCanScale)
            self.wndFreePlaceFrame:FindChild("ScaleUpBtn"):Enable(bCanScale)

            self.wndFreePlaceFrame:FindChild("MoveUpLongBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("MoveUpBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("MoveDownBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("MoveDownLongBtn"):Enable(bCanTranslateAndRotate)

            self.wndFreePlaceFrame:FindChild("MoveLeftLongBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("MoveLeftBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("MoveRightBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("MoveRightLongBtn"):Enable(bCanTranslateAndRotate)

            self.wndFreePlaceFrame:FindChild("MoveBackLongBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("MoveBackBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("MoveForwardBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("MoveForwardLongBtn"):Enable(bCanTranslateAndRotate)

            self.wndFreePlaceFrame:FindChild("RotateXPosLongBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("RotateXPosBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("RotateXNegBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("RotateXNegLongBtn"):Enable(bCanTranslateAndRotate)

            self.wndFreePlaceFrame:FindChild("RotateZPosLongBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("RotateZPosBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("RotateZNegBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("RotateZNegLongBtn"):Enable(bCanTranslateAndRotate)

            -- secondary options            
            self.wndFreePlaceFrame:FindChild("RotateYPosLongBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("RotateYPosBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("RotateYNegBtn"):Enable(bCanTranslateAndRotate)
            self.wndFreePlaceFrame:FindChild("RotateYNegLongBtn"):Enable(bCanTranslateAndRotate)
            
             -- display the icon
            self.wndDecorIconFrame:Show(true)
            self.wndDecorIconOptionsWindow:Show(self.wndToggleFrame:FindChild("OpenDecorOptionsBtn"):IsChecked())
        else
            -- (!) NOTE TO SELF: This is where we could support "sticky targeting" - AC
            self.wndFreePlaceFrame:Show(false)    
        end
	end
end

function HousingDecorate:OnActivateDecorIcon(decorSelected) --this is second and fires once
	if decorSelected ~= nil then
		if self.decorPreview == nil then
			self.decorPreview = decorSelected
		elseif self.decorPreview ~= decorSelected then
			self.decorPreview:CancelTransform()
			self.decorPreview = decorSelected
		end
		self.wndDecorIconFrame:Show(true)
        local tScreenInfo = decorSelected:GetDecorIconInfo()
        if tScreenInfo ~= nil then
            -- update the icon position
            self:UpdateDecorIconPosition(decorSelected)
            local wndIconSliderBar = self.wndDecorIconOptionsWindow:FindChild("SliderBar")
            wndIconSliderBar:SetMinMax(tScreenInfo.fScaleMin * 100, tScreenInfo.fScaleMax * 100)
            wndIconSliderBar:SetValue(tScreenInfo.fScaleCurrent * 100)
            
            local wndFreePlaceSliderBar = self.wndFreePlaceFrame:FindChild("SliderBar")
            wndFreePlaceSliderBar:SetMinMax(tScreenInfo.fScaleMin * 100, tScreenInfo.fScaleMax * 100)
            wndFreePlaceSliderBar:SetValue(tScreenInfo.fScaleCurrent * 100)
            
            local wndFreePlacePosX = self.wndFreePlaceFrame:FindChild("PosXTextBox")
            local wndFreePlacePosY = self.wndFreePlaceFrame:FindChild("PosYTextBox")
            local wndFreePlacePosZ = self.wndFreePlaceFrame:FindChild("PosZTextBox")
            
            wndFreePlacePosX:SetText(string.format("%.2f", tScreenInfo.fWorldPosX))
            wndFreePlacePosY:SetText(string.format("%.2f", tScreenInfo.fWorldPosY))
            wndFreePlacePosZ:SetText(string.format("%.2f", tScreenInfo.fWorldPosZ))
            
            local wndFreePlacePitch = self.wndFreePlaceFrame:FindChild("PitchTextBox")
            local wndFreePlaceRoll = self.wndFreePlaceFrame:FindChild("RollTextBox")
            local wndFreePlaceYaw = self.wndFreePlaceFrame:FindChild("YawTextBox")
            
            wndFreePlacePitch:SetText(string.format("%.2f", tScreenInfo.fPitch))
            wndFreePlacePitch:SetText(string.format("%.2f", tScreenInfo.fPitch))
            wndFreePlaceRoll:SetText(string.format("%.2f", tScreenInfo.fRoll))
            wndFreePlaceYaw:SetText(string.format("%.2f", tScreenInfo.fYaw))
			
			self.wndFreePlaceFrame:FindChild("ScaleTextBox"):SetText(string.format("%.2f", tScreenInfo.fScaleCurrent))
            
            local eCustomizeMode = HousingLib.GetResidence():GetCustomizationMode()
			local bAdvancedChecked = eCustomizeMode == HousingLib.ResidenceCustomizationMode.Advanced
            self.wndFreePlaceFrame:FindChild("BtnHousingAdvancedMode"):Show(not self.bIsWarplot)
            self.wndFreePlaceFrame:FindChild("BtnHousingAdvancedMode"):SetCheck(bAdvancedChecked)
			self.wndFreePlaceToggleMoveControlBtn:Enable(bAdvancedChecked)
			self.wndFreePlaceToggleRotateControlBtn:Enable(bAdvancedChecked)
			
			self.wndFreePlaceLocalModeBtn:Enable(bAdvancedChecked)
	        self.wndFreePlaceGlobalModeBtn:Enable(bAdvancedChecked)
	        if bAdvancedChecked then
	        	if HousingLib.GetControlMode() == HousingLib.DecorControlMode.Local then
                    self.wndFreePlaceFrame:FindChild("ScrollContainer"):SetRadioSel("GizmoControlModeBtns", 1)
                else
                    self.wndFreePlaceFrame:FindChild("ScrollContainer"):SetRadioSel("GizmoControlModeBtns", 2)
                end    
	        else
	            self.wndFreePlaceFrame:FindChild("ScrollContainer"):SetRadioSel("GizmoControlModeBtns", 1)
	        end
        end
      
        -- start our update timer
        Apollo.StartTimer("HousingDecorIconTimer")
    end
end

function HousingDecorate:OnFreePlaceDecorCancelled(decorCancelled)
    if self.decorPreview == decorCancelled and not(self.wndDecorate:IsVisible() and self.wndListView:GetCurrentRow() ~= nil) then
		
		self.decorPreview = nil 
		
        -- shut down the vender UI
        self:OnCloseHousingDecorateWindow()

        -- Activate the decor icon
        self:OnDeactivateDecorIcon()
        
        -- Reset popups
        self:ResetPopups()
    end
end

function HousingDecorate:OnFreePlaceDecorMoveBegin(decorSelected)
    if decorSelected ~= nil and HousingLib.GetResidence():GetCustomizationMode() == HousingLib.ResidenceCustomizationMode.Simple then
        self:OnDeactivateDecorIcon()
    end
end

function HousingDecorate:OnFreePlaceDecorMoving(decorSelected)
    if decorSelected ~= nil then
        local tScreenInfo = decorSelected:GetDecorIconInfo()
        
        if tScreenInfo == nil then 
			return
		end
        
        local wndFreePlacePosX = self.wndFreePlaceFrame:FindChild("PosXTextBox")
        local wndFreePlacePosY = self.wndFreePlaceFrame:FindChild("PosYTextBox")
        local wndFreePlacePosZ = self.wndFreePlaceFrame:FindChild("PosZTextBox")

        wndFreePlacePosX:SetText(string.format("%.2f", tScreenInfo.fWorldPosX))
        wndFreePlacePosY:SetText(string.format("%.2f", tScreenInfo.fWorldPosY))
        wndFreePlacePosZ:SetText(string.format("%.2f", tScreenInfo.fWorldPosZ))

        local wndFreePlacePitch = self.wndFreePlaceFrame:FindChild("PitchTextBox")
        local wndFreePlaceRoll = self.wndFreePlaceFrame:FindChild("RollTextBox")
        local wndFreePlaceYaw = self.wndFreePlaceFrame:FindChild("YawTextBox")

        wndFreePlacePitch:SetText(string.format("%.2f", tScreenInfo.fPitch))
        wndFreePlaceRoll:SetText(string.format("%.2f", tScreenInfo.fRoll))
        wndFreePlaceYaw:SetText(string.format("%.2f", tScreenInfo.fYaw))
        
		local wndIconSliderBar = self.wndDecorIconOptionsWindow:FindChild("SliderBar")
		wndIconSliderBar:SetValue(tScreenInfo.fScaleCurrent * 100)
		
		local wndFreePlaceSliderBar = self.wndFreePlaceFrame:FindChild("SliderBar")
		wndFreePlaceSliderBar:SetValue(tScreenInfo.fScaleCurrent * 100)
		self.wndFreePlaceFrame:FindChild("ScaleTextBox"):SetText(string.format("%.2f", tScreenInfo.fScaleCurrent))
    end
end

function HousingDecorate:OnFreePlaceDecorMoveEnd(decorSelected)
    if decorSelected ~= nil and HousingLib.GetResidence():GetCustomizationMode() == HousingLib.ResidenceCustomizationMode.Simple then
        self:OnActivateDecorIcon(decorSelected)
    end
end

function HousingDecorate:UpdateDecorIconPosition(decorSelected) -- this is third and updates on a timer/frame
    if decorSelected ~= nil then
	  -- grab the decor icon info
        local tScreenInfo = decorSelected:GetDecorIconInfo()
		
		if tScreenInfo == nil then 
			self.wndDecorIconFrame:Show(false)
			return
		end
		
		if (self.bPlayerIsInside and tScreenInfo.fWorldPosY >= knHousingExteriorPlacementMinHeight) or (not self.bPlayerIsInside and tScreenInfo.fWorldPosY < knHousingExteriorPlacementMinHeight) then
            self.wndDecorIconFrame:Show(false)
			return    
		end
        
        -- update position
        local nIconLeft, nIconTop, nIconRight, nIconBottom = self.wndToggleFrame:GetRect()
        local nFrameLeft, nFrameTop, nFrameRight, nFrameBottom = self.wndDecorIconFrame:GetRect()
        local nNewLeft = tScreenInfo.nScreenPosX
        local nNewTop = tScreenInfo.nScreenPosY
        local nIconWidth = nIconRight - nIconLeft
        local nIconHeight = nIconBottom - nIconTop
        local nWidth = nFrameRight - nFrameLeft
        local nHeight = nFrameBottom - nFrameTop
        self.wndDecorIconFrame:Move(nNewLeft - (nIconWidth / 2), nNewTop - (nIconHeight / 2), nWidth, nHeight)
       
		self.wndToggleFrame:Show(true)
		
		self.wndDecorIconName:SetText(decorSelected:GetName())
		if decorSelected:GetBuffSpell() ~= nil then
		    self.wndDecorBuffIcon:SetSprite(decorSelected:GetBuffSpell():GetIcon())
		else
            self.wndDecorBuffIcon:SetSprite("")
		end    
		
		self.wndDecorChairIcon:Show(decorSelected:IsChair())
		self.wndDecorDisableIcon:Show(not decorSelected:IsUsable())
		
        -- update windows/buttons
        if tScreenInfo.bOnScreen and tScreenInfo.bWasDrawn then
            self.wndDecorIconBacker :SetSprite(kstrFrameVisible)
        elseif tScreenInfo.bOnScreen and not tScreenInfo.bWasDrawn then
            self.wndDecorIconBacker :SetSprite(kstrFrameNotVisible)
        elseif not tScreenInfo.bOnScreen then
            self.wndDecorIconBacker :SetSprite(kstrFrameOffscreen)
        end
    end
end

function HousingDecorate:OnDeactivateDecorIcon()
	Apollo.StopTimer("HousingDecorIconTimer")
	self.wndDecorIconFrame:Show(false, true)
end

function HousingDecorate:OnDecorIconUpdate()
    if self.decorPreview ~= nil then
       -- update position
        self:UpdateDecorIconPosition(self.decorPreview)

	    -- restart the update timer
        Apollo.StartTimer("HousingDecorIconTimer")
    else
        self.wndDecorIconFrame:Show(false, true)
		--self.wndToggleFrame:FindChild("OpenDecorOptionsBtn"):SetCheck(false)
    end
end

function HousingDecorate:OnDecorIconOpen(wndHandler, wndControl)
    self.wndDecorIconOptionsWindow:Show(true)
end

function HousingDecorate:OnDecorIconClose(wndHandler, wndControl)
    self.wndDecorIconOptionsWindow:Show(false)
end

function HousingDecorate:OnPositionEdited(wndHandler, wndControl)
    local wndFreePlacePosX = self.wndFreePlaceFrame:FindChild("PosXTextBox")
	local wndFreePlacePosY = self.wndFreePlaceFrame:FindChild("PosYTextBox")
	local wndFreePlacePosZ = self.wndFreePlaceFrame:FindChild("PosZTextBox")
	
	local fPosX = tonumber(wndFreePlacePosX:GetText())
	local fPosY = tonumber(wndFreePlacePosY:GetText())
	local fPosZ = tonumber(wndFreePlacePosZ:GetText())
	
	if fPosX == nil or fPosY == nil or fPosZ == nil then
	    -- entered invalid text
	    self:OnHousingResult('', HousingLib.HousingResult_Decor_InvalidPosition)
	    return
	end
	
	if self.decorPreview ~= nil then
		self.decorPreview:SetPosition(fPosX, fPosY, fPosZ)
	end
end

function HousingDecorate:OnOrientationEdited(wndHandler, wndControl)
    local wndFreePlacePitch = self.wndFreePlaceFrame:FindChild("PitchTextBox")
	local wndFreePlaceRoll = self.wndFreePlaceFrame:FindChild("RollTextBox")
	local wndFreePlaceYaw = self.wndFreePlaceFrame:FindChild("YawTextBox")
	
	local fPitch = tonumber(wndFreePlacePitch:GetText())
	local fRoll = tonumber(wndFreePlaceRoll:GetText())
	local fYaw = tonumber(wndFreePlaceYaw:GetText())
	
	if fPitch == nil or fRoll == nil or fYaw == nil then
	    -- entered invalid text
	    self:OnHousingResult('', HousingLib.HousingResult_Decor_InvalidPosition)
	    return
	end
	
	if self.decorPreview ~= nil then
		self.decorPreview:SetRotation(fPitch, fRoll, fYaw)
	end
end

-----------------------------------------------------------------------------------------------
-- HousingDecorate Drag-drop functions
-----------------------------------------------------------------------------------------------
function HousingDecorate:OnQueryDragDropDecorate(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if strType == "DDBagItem" and not self.bIsVendor then
		return Apollo.DragDropQueryResult.Accept
	end
	return Apollo.DragDropQueryResult.Ignore
end

function HousingDecorate:OnDragDropNotifyDecorate(wndHandler, wndControl, bMe)
    -- we've been notified of a drag-drop
end

function HousingDecorate:OnDragDropDecorate(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if strType == "DDBagItem" then
        local itemDecor = wndSource:GetItem(iData)
        local eItemType = itemDecor:GetItemType()
        if eItemType == knItemType_HousingInteriorFurniture or eItemType == knItemType_HousingExteriorAccent then
            -- Add the decor itemDecor
            HousingLib.AddItemToCrate(iData)
           
            -- Refresh the decorate window
            Apollo.StartTimer("HousingDecorListRefreshTimer")
        end
	end
	return false
end

function HousingDecorate:OnSendItemToInventory(wndHandler, wndControl)
	local nRow = self.wndListView:GetCurrentRow()
    if nRow ~= nil then 
        local tItemData = self.wndListView:GetCellData( nRow, 1 )
        local idLow = tItemData.tDecorItems[1].nDecorId
        local idHi = tItemData.tDecorItems[1].nDecorIdHi
        
        -- Don't allow for now
        --HousingLib.SendDecorToInventory(idLow, idHi)
    end
end

function HousingDecorate:OnListRefresh()
    local strSearchText = self.wndExtSearchWindow:GetText()
    if self.bPlayerIsInside or self.bIsWarplot then
    	strSearchText = self.wndIntSearchWindow:GetText()
    end

    if self.bIsVendor then
        self.tDecorList = HousingLib.GetDecorCatalogList(strSearchText)
    else
        self.tDecorList = HousingLib.GetDecorCrateList(strSearchText)
    end
    self:ShowItems(self.wndListView, self.tDecorList, 0)
end

function HousingDecorate:OnHousingResult(strName, eResult)
    -- cancel decor preview and refresh the UI
    if self.wndDecorate:IsVisible() then
        self:ShowDecorateWindow(true)
    end
    
    if eResult == HousingLib.HousingResult_Mannequin_NotEmpty then
        if self.wndMannequinMsgFrame == nil then
            self.wndMannequinMsgFrame = Apollo.LoadForm(self.xmlDoc, "MannequinWarningWindow", nil, self)
        end    
        self.wndMannequinMsgFrame:Show(true)
        return
    end
end

function HousingDecorate:OnRewardPropertiesUpdate(tUpdatedRewardProperties)
	if not self.wndDecorate or not self.wndDecorate:IsVisible() then
		return
	end

	for idx, tProperty in pairs(tUpdatedRewardProperties) do
		if tProperty.eRewardProperty == AccountItemLib.CodeEnumRewardProperty.ExtraDecorSlots then
			self:UpdateDecorLimits()
			return
		end
	end
end

function HousingDecorate:RefreshStoreLink()
	self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.ExtraDecor)
	self:OnRewardPropertiesUpdate( { { eRewardProperty = AccountItemLib.CodeEnumRewardProperty.ExtraDecorSlots, nObjectId = 0 } } )
end

function HousingDecorate:OnIncreaseLimits()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.ExtraDecor)
end

---------------------------------------------------------------------------------------------------
function HousingDecorate:OnGenerateTooltip(wndHandler, wndControl, eType, oArg1, oArg2)
	if eType == Tooltip.TooltipGenerateType_Grid and oArg2 == 2 then
        local tItemData = self.wndListView:GetCellData( oArg1+1, 1 )
        if tItemData ~= nil and tItemData.splBuff ~= nil and tItemData.splBuff ~= {} then
            Tooltip.GetHousingBuffTooltipForm(self, wndControl, tItemData.splBuff)
        else
            wndControl:SetTooltip("")
        end
    else
        if self.decorPreview ~= nil then
            tDecorIconInfo = self.decorPreview:GetDecorIconInfo()
            if tDecorIconInfo ~= nil and self.decorPreview:GetBuffSpell() ~= nil then
                Tooltip.GetHousingBuffTooltipForm(self, wndControl, self.decorPreview:GetBuffSpell())
            end
        else
            wndControl:SetTooltip("")
        end
	end
end

function HousingDecorate:OnGridSort()	
	if self.wndListView:IsSortAscending() then
		table.sort(self.tDecorList, function(a,b) return (a.eCurrencyType < b.eCurrencyType or (a.eCurrencyType == b.eCurrencyType and a.nCost < b.nCost)) end)
	else
		table.sort(self.tDecorList, function(a,b) return (a.eCurrencyType > b.eCurrencyType or (a.eCurrencyType == b.eCurrencyType and a.nCost > b.nCost)) end)
	end
	
	self:ShowItems(self.wndListView, self.tDecorList, 0)
end

-----------------------------------------------------------------------------------------------
-- HousingDecorate Instance
-----------------------------------------------------------------------------------------------
local HousingDecorateInst = HousingDecorate:new()
HousingDecorateInst:Init()
