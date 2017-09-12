-----------------------------------------------------------------------------------------------
-- Client Lua Script for HousingRemodel
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "HousingLib"
require "Residence"

-----------------------------------------------------------------------------------------------
-- HousingRemodel Module Definition
-----------------------------------------------------------------------------------------------
local HousingRemodel 		= {}
local RemodelPreviewControl = {}
local RemodelPreviewItem 	= {}

---------------------------------------------------------------------------------------------------
-- global
---------------------------------------------------------------------------------------------------
local gidZone 				= 0
local gtRemodelTrueValues = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local knExtRemodelTabs 		= 7
local knIntRemodelTabs 		= 6
local knCommunityRemodelTabs = 3
local kstrXML = "HousingRemodel.xml"

local kcrDarkBlue 	= CColor.new(47/255,148/255,172/255,1.0)
--local kBrightBlue = CColor.new(49/255,252/255,246/255,1.0)
local kcrWhite 		= CColor.new(1.0,1.0,1.0,1.0)
local kcrDisabled 	= CColor.new(0.13,0.33,0.37,1.0)

local ktTypeStrings =
{
	["Roof"]			= "HousingRemodel_Roof", 
	["Wallpaper"] 		= "Housing_Wallpaper", 
	["Entry"] 			= "HousingRemodel_Entry", 
	["Door"] 			= "HousingRemodel_Door", 
	["Sky"]				= "HousingRemodel_Sky",
	["Music"]           = "HousingRemodel_Music",
	["Ground"]          = "HousingRemodel_Ground",
    ["IntWallpaper"] 	= "Housing_Wallpaper", 
	["Floor"] 			= "HousingRemodel_Floor", 
	["Ceiling"]			= "CRB_CEILING", 
	["Trim"] 			= "HousingRemodel_Trim", 
	["Lighting"] 		= "HousingRemodel_Lighting",
	["IntMusic"]        = "HousingRemodel_Music",
	["CommunitySky"]	= "HousingRemodel_Sky",
	["CommunityMusic"]  = "HousingRemodel_Music",
	["CommunityGround"] = "HousingRemodel_Ground",
}
 ---------------------------------------------------------------------------------------------------
-- RemodelPreviewControl methods
---------------------------------------------------------------------------------------------------
function RemodelPreviewControl:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.eType 				= nil
	o.tRemodelPreviewItems 	= {}
	o.wndRemodelTotalCostML = nil
	o.wndRemodelTotalCostCash = nil
	o.wndAcceptBtn 			= nil
	o.wndCancelBtn 			= nil
	o.rResidence            = nil

	return o
end

function RemodelPreviewControl:OnLoad(strPreviewType, wndParentFrame, wndParent, tChildNamesList)
	self.strType = strPreviewType;
	
	self.rResidence = HousingLib.GetResidence()

	local tBakedList = {}
	if self.strType == "exterior" or self.strType == "community" then
	    if self.rResidence ~= nil then
		    tBakedList = self.rResidence:GetBakedDecorDetails()
		else
            tBakedList = {}
        end
	else
		-- "interior" items aren't on a baked list
		--  this loading process will set them up w/ default text/colors
	end

	-- loop through the names given, and create list entries with the name as the key
	for idx = 1, #tChildNamesList do
		self.tRemodelPreviewItems[idx] = RemodelPreviewItem:new()
		self.tRemodelPreviewItems[idx]:OnLoad(wndParentFrame, tBakedList[idx], tChildNamesList[idx])
	end

	self.wndRemodelTotalCostML 		= wndParent:FindChild("RemodelPreviewTotalCost")
	self.wndRemodelTotalCostCash 	= wndParent:FindChild("RemodelPreviewCashWindow")
	self.wndAcceptBtn 				= wndParent:FindChild("ReplaceBtn")
	self.wndCancelBtn 				= wndParent:FindChild("CancelBtn")
	self.wndPurchaseError			= wndParent:FindChild("PurchaseErrorText")
	self.wndCostContainer			= wndParent:FindChild("RemodelCostContainer")
end

function RemodelPreviewControl:OnResidenceChange(idZone)
    self.rResidence = HousingLib.GetResidence()
	if self.rResidence == nil then
		return
	end
	
	if self.strType == "exterior" then
	    local tRemodelValues = {}
		local tBakedList	= {}
		tBakedList = self.rResidence:GetBakedDecorDetails()
		for key, tData in pairs(tBakedList) do
		    if tData.eHookType ~= nil and tData.eHookType == HousingLib.CodeEnumDecorHookType.Roof then
		        tRemodelValues[HousingLib.RemodelOptionTypeExterior.Roof] = tData
		    elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Wallpaper then
		        tRemodelValues[HousingLib.RemodelOptionTypeExterior.Wallpaper] = tData
		    elseif tData.eHookType ~= nil and tData.eHookType == HousingLib.CodeEnumDecorHookType.Entryway then
                tRemodelValues[HousingLib.RemodelOptionTypeExterior.Entry] = tData 
            elseif tData.eHookType ~= nil and tData.eHookType == HousingLib.CodeEnumDecorHookType.Door then
                tRemodelValues[HousingLib.RemodelOptionTypeExterior.Door] = tData
            elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Sky then
		        tRemodelValues[HousingLib.RemodelOptionTypeExterior.Sky] = tData
		    elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Music then
		        tRemodelValues[HousingLib.RemodelOptionTypeExterior.Music] = tData
            elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Ground then
		        tRemodelValues[HousingLib.RemodelOptionTypeExterior.Ground] = tData
		    end
		end

		for eType = HousingLib.RemodelOptionTypeExterior.Roof, HousingLib.RemodelOptionTypeExterior.Ground do
		    local tData = tRemodelValues[eType]
			self.tRemodelPreviewItems[eType]:OnResidenceChange(tData)
		end
	elseif self.strType == "community" then	    
	    local tRemodelValues = {}
		local tBakedList	= {}
		tBakedList = self.rResidence:GetBakedDecorDetails()
		for key, tData in pairs(tBakedList) do
		    if tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeCommunity.Sky then
		        tRemodelValues[HousingLib.RemodelOptionTypeCommunity.Sky] = tData
		    elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeCommunity.Music then
		        tRemodelValues[HousingLib.RemodelOptionTypeCommunity.Music] = tData
            elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeCommunity.Ground then
		        tRemodelValues[HousingLib.RemodelOptionTypeCommunity.Ground] = tData
		    end
		end

		for eType = HousingLib.RemodelOptionTypeCommunity.Sky, HousingLib.RemodelOptionTypeCommunity.Ground do
		    local tData = tRemodelValues[eType]
			self.tRemodelPreviewItems[eType]:OnResidenceChange(tData)
		end
	else
	    gtRemodelTrueValues = {}
		local tSectorDecorList = self.rResidence:GetDecorDetailsBySector(idZone)
		for key, tData in pairs(tSectorDecorList) do
			--self.tRemodelPreviewItems[tData.eType]:OnResidenceChange(tData)
			gtRemodelTrueValues[tData.eType] = tData
		end
		
		for eType = HousingLib.RemodelOptionTypeInterior.Wallpaper, HousingLib.RemodelOptionTypeInterior.Music do
		    local tData = gtRemodelTrueValues[eType]
			self.tRemodelPreviewItems[eType]:OnResidenceChange(tData)
		end
	end
end

function RemodelPreviewControl:OnChoiceMade(nIndex, idItem, tList )
	self.tRemodelPreviewItems[nIndex]:OnChoiceMade(idItem, tList)

	self:SetTotalPrice()
end

function RemodelPreviewControl:OnAllChoicesCanceled(bPurchased)
	for idx, value in ipairs(self.tRemodelPreviewItems) do
		self.tRemodelPreviewItems[idx]:OnChoiceCanceled(idx)
	end

	if not bPurchased then
		self:ClearClientPreviewItems()
	end

	self:SetTotalPrice()
end

function RemodelPreviewControl:OnChoiceCanceled(nIndex)
	Sound.Play(Sound.PlayUIHousingItemCancelled)
	self.tRemodelPreviewItems[nIndex]:OnChoiceCanceled()
	self:ClearClientPreviewItems()

	self:SetTotalPrice()
end

function RemodelPreviewControl:OnPreviewCheck(nIndex)
	self:SetClientPreviewItems()
end

function RemodelPreviewControl:ThereArePreviewItems()
	for idx, value in ipairs(self.tRemodelPreviewItems) do
		if self.tRemodelPreviewItems[idx].idSelectedChoice ~= 0 then
			return true
		end
	end

	return false
end

function RemodelPreviewControl:SetClientPreviewItems()
    if self.rResidence == nil then
        return
    end

	if self.strType == "exterior" then

		local idRoof		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Roof]:GetPreviewValue()
		local idWallpaper	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Wallpaper]:GetPreviewValue()
		local idEntry		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Entry]:GetPreviewValue()
		local idDoor 		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Door]:GetPreviewValue()
		local idSky     	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Sky]:GetPreviewValue()
		local idMusic     	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Music]:GetPreviewValue()
		local idGround     	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Ground]:GetPreviewValue()

		if 	self:ThereArePreviewItems() then
			self.rResidence:PreviewResidenceBakedDecor(idRoof, idWallpaper, idEntry, idDoor, idSky, idMusic, idGround )
		end
	elseif self.strType == "community" then
	    local idSky     	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Sky]:GetPreviewValue()
		local idMusic     	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Music]:GetPreviewValue()
		local idGround     	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Ground]:GetPreviewValue()

		if 	self:ThereArePreviewItems() then
			self.rResidence:PreviewResidenceBakedDecor(0, 0, 0, 0, idSky, idMusic, idGround )
		end	
	else -- "interior"
		local idCeiling 	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Ceiling]:GetPreviewValue()
		local idTrim 		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Trim]:GetPreviewValue()
		local idWallpaper 	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Wallpaper]:GetPreviewValue()
		local idFloor 		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Floor]:GetPreviewValue()
		local idLighting 	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Lighting]:GetPreviewValue()
		local idMusic 	    = self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Music]:GetPreviewValue()

		if 	self:ThereArePreviewItems() then
			self.rResidence:PreviewResidenceSectorDecor(gidZone, idCeiling, idTrim, idWallpaper, idFloor, idLighting, idMusic)
		end
	end
end

function RemodelPreviewControl:ClearClientPreviewItems()
    if self.rResidence == nil then
        return
    end
       
	if self.strType == "exterior" then
		local idRoof		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Roof]:GetPreviewValue()
		local idWallpaper	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Wallpaper]:GetPreviewValue()
		local idEntry		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Entry]:GetPreviewValue()
		local idDoor 		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Door]:GetPreviewValue()
		local idSky     	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Sky]:GetPreviewValue()
		local idMusic     	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Music]:GetPreviewValue()
		local idGround      = self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Ground]:GetPreviewValue()
		
		self.rResidence:PreviewResidenceBakedDecor(idRoof, idWallpaper, idEntry, idDoor, idSky, idMusic, idGround)
	elseif self.strType == "community" then
		local idSky     	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Sky]:GetPreviewValue()
		local idMusic     	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Music]:GetPreviewValue()
		local idGround      = self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Ground]:GetPreviewValue()
		
		self.rResidence:PreviewResidenceBakedDecor(0, 0, 0, 0, idSky, idMusic, idGround)
	else
		local idCeiling 	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Ceiling]:GetPreviewValue()
		local idTrim 		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Trim]:GetPreviewValue()
		local idWallpaper 	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Wallpaper]:GetPreviewValue()
		local idFloor 		= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Floor]:GetPreviewValue()
		local idLighting 	= self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Lighting]:GetPreviewValue()
		local idMusic 	    = self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Music]:GetPreviewValue()

		self.rResidence:PreviewResidenceSectorDecor(gidZone, idCeiling, idTrim, idWallpaper, idFloor, idLighting, idMusic)
	end
end

function RemodelPreviewControl:SetTotalPrice()
	local tTotalCost = {}	
	local bItemsNotUnlocked = false
	local bHasPreview = self:ThereArePreviewItems()
	
	if bHasPreview then
        for key, value in pairs(self.tRemodelPreviewItems) do
			local monCost = self.tRemodelPreviewItems[key].wndCost:GetCurrency()
			local eCurrencyType = monCost:GetMoneyType()
			
			if not tTotalCost[eCurrencyType] then
				tTotalCost[eCurrencyType] = monCost:GetAmount()
			else
				tTotalCost[eCurrencyType] = tTotalCost[eCurrencyType] + monCost:GetAmount()
			end
			
			if self.tRemodelPreviewItems[key].idSelectedChoice ~= nil and self.tRemodelPreviewItems[key].idSelectedChoice > 0 and 
               self.tRemodelPreviewItems[key].idUpsellLink ~= nil and self.tRemodelPreviewItems[key].idUpsellLink > 0 then
				bItemsNotUnlocked = true
			end
        end
	end
	
	self.wndCostContainer:DestroyChildren()
	
	local bValid = bHasPreview
	if bItemsNotUnlocked then
		self.wndCostContainer:Show(false)
		self.wndPurchaseError:Show(true)
	else
		local strDoc = ""
		for eCurrencyType, nAmount in pairs(tTotalCost) do
			if nAmount > 0 then
				local wndCost = Apollo.LoadForm(kstrXML, "RemodelCost", self.wndCostContainer, self)
				wndCost:SetMoneySystem(eCurrencyType)
				wndCost:SetAmount(nAmount, true)
				
				if GameLib.GetPlayerCurrency(eCurrencyType):GetAmount() < nAmount then
					bValid = false
					wndCost:SetTextColor("UI_WindowTextRed")
				end
				
				local nLeft, nTop, nRight, nBottom = wndCost:GetAnchorOffsets()
				local nWidth = wndCost:GetDisplayWidth() + nLeft
				
				wndCost:SetAnchorOffsets(nLeft, nTop, nWidth, nBottom)
			end
		end
		
		self.wndCostContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
	
		self.wndCostContainer:Show(true)
		self.wndPurchaseError:Show(false)
	end

	-- adjust the accept & cancel buttons based on totalCost
	self.wndAcceptBtn:Enable(bValid and not bItemsNotUnlocked)
	self.wndCancelBtn:Enable(bHasPreview)
end

function RemodelPreviewControl:PurchaseRemodelChanges()
    if self.rResidence == nil then
        return
    end

	--print("purchaseRemodelChanges type: " .. self.type)
	if self.strType == "exterior" then
			self.rResidence:ModifyResidenceDecor(self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Roof].idSelectedChoice,
											self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Wallpaper].idSelectedChoice,
											self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Entry].idSelectedChoice,
                                            self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Door].idSelectedChoice,
                                            self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Sky].idSelectedChoice,
                                            self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Music].idSelectedChoice,
                                            self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Ground].idSelectedChoice)
    elseif self.strType == "community" then   
        self.rResidence:ModifyResidenceDecor(0,
											0,
											0,
                                            0,
                                            self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Sky].idSelectedChoice,
                                            self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Music].idSelectedChoice,
                                            self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Ground].idSelectedChoice)                                     
	else
		self.rResidence:PurchaseInteriorWallpaper(self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Wallpaper].idSelectedChoice,
											 self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Floor].idSelectedChoice,
											 self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Ceiling].idSelectedChoice,
											 self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Trim].idSelectedChoice,
                                             self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Lighting].idSelectedChoice,
                                             self.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Music].idSelectedChoice)
	end

	Sound.Play(Sound.PlayUI16BuyVirtual)

    if self.strType == "interior" then
		self:OnResidenceChange(gidZone)
	end
	self:OnAllChoicesCanceled(true)
end

---------------------------------------------------------------------------------------------------
-- RemodelPreviewItem methods
---------------------------------------------------------------------------------------------------

function RemodelPreviewItem:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.wndCost 				= nil
	o.wndDescription 		= nil
	o.wndCancelBtn 			= nil
	o.wndPreviewCheckbox 	= nil

	o.tCurrentItem 			= {}
	o.strType               = nil
	o.idSelectedChoice 		= 0
	o.idUpsellLink 			= 0

	return o
end

function RemodelPreviewItem:OnLoad(wndParent, tRemodelOption, strName)
	local wndPreview = wndParent:FindChild(strName .. "Window")
	self.wndRemodelPreviewParent = wndParent 

	self.wndCost = wndPreview:FindChild("Cost")
	self.wndPreviewContainer = wndPreview
	self.wndDescription = wndPreview:FindChild("Description")
	self.wndCancelBtn = wndPreview:FindChild("CanceBtn")
	self.wndPreviewCheckbox = wndPreview:FindChild(strName .. "PreviewBtn")
	self.wndUpsellBtn = wndPreview:FindChild("Upsell")

	self.idSelectedChoice = 0
	self.idUpsellLink = 0
	self.strType = strName
	self:OnResidenceChange(tRemodelOption)
end

-- set up the "grey'd" out default choices with the current residence values
function RemodelPreviewItem:OnResidenceChange(tCurrentItem)

	-- "interior" items aren't on a baked list
	--  this process will set them up w/ default text/colors
	-- name is actually type/slot ("Ceiling", "Trim", etc...)

	if tCurrentItem ~= nil then
		self.tCurrentItem = tCurrentItem
		--self.wndDescription:SetText(self.tCurrentItem.strName)
		self.wndDescription:SetAML(string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextMetalBodyAccent\">%s</P>", self.tCurrentItem.strName))
	else
		self.tCurrentItem = {}
		-- line below should change once all these things exist!
		self.wndDescription:SetAML(string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextMetalBodyAccent\">%s</P>", String_GetWeaselString(Apollo.GetString("CRB_Default_"), Apollo.GetString(ktTypeStrings[self.strType]))))
		--self.wndDescription:SetText(String_GetWeaselString(Apollo.GetString("CRB_Default_"), Apollo.GetString(ktTypeStrings[self.strType])))
	end  
	self.wndDescription:SetHeightToContentHeight()
	local nDescHeight = self.wndDescription:GetHeight()
	nLeft, nTop, nRight, nBottom = self.wndPreviewContainer:GetAnchorOffsets()
	self.wndPreviewContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nDescHeight + 70)
	self.wndRemodelPreviewParent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.wndPreviewCheckbox:Show(false)
	self.wndPreviewCheckbox:SetCheck(false)
	self.wndCancelBtn:Enable(false)
	if self.wndUpsellBtn ~= nil then
		self.wndUpsellBtn:Show(false)
	end
end

function RemodelPreviewItem:OnChoiceMade(idItem, tList )
	local tItemData = HousingRemodel:GetItem(idItem, tList)
	if tItemData ~= nil then
        self.wndCost:SetMoneySystem(tItemData.eCurrencyType)
        self.wndCost:SetAmount(tItemData.nCost)
		self.wndDescription:SetAML(string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"xkcdBlueyGreen\">%s</P>", tItemData.strName))
		self.wndDescription:SetHeightToContentHeight()
		local nDescHeight = self.wndDescription:GetHeight()
		nLeft, nTop, nRight, nBottom = self.wndPreviewContainer:GetAnchorOffsets()
		self.wndPreviewContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nDescHeight + 70)
		self.wndRemodelPreviewParent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		self.wndRemodelPreviewParent:SetVScrollPos(nTop)	
        self.wndPreviewCheckbox:Show(true)
        self.wndCancelBtn:Enable(true)
        self.wndPreviewCheckbox:SetCheck(true)
		if self.wndUpsellBtn ~= nil then
			self.wndUpsellBtn:Show(tItemData ~= nil and tItemData.kUpsellLink ~= 0 or false)
		end
        self.idSelectedChoice = tItemData.nId
		self.idUpsellLink = tItemData.kUpsellLink
	end
end

function RemodelPreviewItem:OnChoiceCanceled()
    self.wndCost:SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
	self.wndCost:SetAmount(0)
	-- line below should change once all these things exist!
	self.wndDescription:SetAML(string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextMetalBodyAccent\">%s</P>", self.tCurrentItem.strName or String_GetWeaselString(Apollo.GetString("CRB_Default_"), Apollo.GetString(ktTypeStrings[self.strType]))))
	self.wndDescription:SetHeightToContentHeight()
	local nDescHeight = self.wndDescription:GetHeight()
	nLeft, nTop, nRight, nBottom = self.wndPreviewContainer:GetAnchorOffsets()
	self.wndPreviewContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nDescHeight + 70)
	self.wndPreviewContainer:GetParent():ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.wndPreviewCheckbox:Show(false)
	self.wndPreviewCheckbox:SetCheck(false)
	self.wndCancelBtn:Enable(false)
	if self.wndUpsellBtn ~= nil then
		self.wndUpsellBtn:Show(false)
	end
	self.idSelectedChoice = 0
	self.idUpsellLink = 0
end

function RemodelPreviewItem:GetPreviewValue()
	if self.wndPreviewCheckbox:IsChecked() then
		return self.idSelectedChoice
	end

	return 0
end

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function HousingRemodel:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	-- initialize our variables
	o.wndRemodel = nil
	o.wndListView = nil
	o.wndOkButton = nil
	o.wndCashRemodel = nil

	o.bPlayerIsInside = false

	o.wndSortByList = nil
	o.tCategoryItems = {}

	o.tExtRemodelTabs = {}
	o.tIntRemodelTabs = {}
	o.tCommunityRemodelTabs = {}

	o.luaExtRemodelPreviewControl = RemodelPreviewControl:new()
	o.luaIntRemodelPreviewControl = RemodelPreviewControl:new()
	o.luaCommunityRemodelPreviewControl = RemodelPreviewControl:new()

    return o
end

function HousingRemodel:Init()
    Apollo.RegisterAddon(self)
end


-----------------------------------------------------------------------------------------------
-- HousingRemodel OnLoad
-----------------------------------------------------------------------------------------------
function HousingRemodel:OnLoad()	
	Apollo.RegisterEventHandler("HousingButtonRemodel", 			"OnHousingButtonRemodel", self)
	Apollo.RegisterEventHandler("HousingButtonLandscape", 			"OnHousingButtonLandscape", self)
	Apollo.RegisterEventHandler("HousingButtonCrate", 				"OnHousingButtonCrate", self)
	Apollo.RegisterEventHandler("HousingButtonVendor", 				"OnHousingButtonCrate", self)
	Apollo.RegisterEventHandler("HousingButtonList", 				"OnHousingButtonList", self)
	Apollo.RegisterEventHandler("HousingPanelControlOpen", 			"OnOpenPanelControl", self)
	Apollo.RegisterEventHandler("HousingPanelControlClose", 		"OnClosePanelControl", self)
	Apollo.RegisterEventHandler("HousingMyResidenceDecorChanged", 	"OnResidenceDecorChanged", self)
	Apollo.RegisterEventHandler("HousingResult", 					"OnHousingResult", self)
	Apollo.RegisterEventHandler("HousingNamePropertyOpen",          "OnHousingNameProperty", self)
	Apollo.RegisterEventHandler("PlayerCurrencyChanged", 			"OnPlayerCurrencyChanged", self)
	Apollo.RegisterEventHandler("HousingBuildStarted", 				"OnBuildStarted", self)
	Apollo.RegisterEventHandler("HousingRandomResidenceListRecieved", 	"OnRandomResidenceList", self)
	Apollo.RegisterEventHandler("HousingRandomCommunityListReceived",	"OnRandomCommunityList", self)
	Apollo.RegisterEventHandler("HousingCommunityPlacedResidencesListRecieved", 	"OnCommunityPlacedResidenceList", self)
	Apollo.RegisterEventHandler("HousingPropertiesRecieved", 		"OnHousingPropertiesReceived", self)

	Apollo.RegisterTimerHandler("HousingRemodelTimer", 				"OnRemodelTimer", self)
	Apollo.RegisterTimerHandler("HousingIntRemodelTimer", 			"OnIntRemodelTimer", self)
	Apollo.RegisterEventHandler("ChangeWorld", 						"OnChangeWorld", self)
	Apollo.RegisterEventHandler("UpdateInventory", 					"OnUpdateInventory", self)
	Apollo.RegisterEventHandler("StoreLinksRefresh",				"OnStoreLinksRefresh", self)
	
	Apollo.RegisterEventHandler("GuildRoster", 						"OnGuildRoster", self)
	Apollo.RegisterEventHandler("GuildChange", 						"OnGuildChange", self)  -- notification that a guild was added / removed.
	Apollo.RegisterEventHandler("GuildMemberChange",				"OnGuildMemberChange", self)
	Apollo.RegisterEventHandler("GuildRankChange",					"OnGuildRankChange", self)
	Apollo.RegisterEventHandler("GuildName",						"OnGuildNameChanged", self)
	
	Apollo.RegisterEventHandler("ServiceTokenClosed_RenameCommunity",	"OnServiceTokenDialogClosed", self)
	Apollo.RegisterEventHandler("CommunityRenameResult",				"OnCommunityRenameResult", self)
	Apollo.RegisterTimerHandler("CommunityRenameAlertTimer",			"OnCommunityRenameAlertTimer", self)

	Apollo.CreateTimer("HousingRemodelTimer", 0.200, false)
	Apollo.StopTimer("HousingRemodelTimer")

	Apollo.CreateTimer("HousingIntRemodelTimer", 0.200, false)
	Apollo.StopTimer("HousingIntRemodelTimer")
	
	Apollo.RegisterTimerHandler("RetryLoadingCommunity", 			"OnGuildChange", self)
	Apollo.CreateTimer("RetryLoadingCommunity", 1.0, false)
	Apollo.StopTimer("RetryLoadingCommunity")

    -- load our forms
    self.xmlDoc                     = XmlDoc.CreateFromFile(kstrXML)
	self.wndConfigure				= Apollo.LoadForm(self.xmlDoc, "HousingConfigureWindow", nil, self)
    self.wndRemodel 				= Apollo.LoadForm(self.xmlDoc, "HousingRemodelWindow", nil, self)
	self.wndListView 				= self.wndRemodel:FindChild("StructureList")
	self.wndReplaceButton 			= self.wndRemodel:FindChild("ReplaceBtn")
	self.wndCancelButton			= self.wndRemodel:FindChild("CancelBtn")
	self.wndCashRemodel 			= self.wndRemodel:FindChild("CashWindow")
	self.wndExtRemodelHeaderFrame 	= self.wndRemodel:FindChild("ExtHeaderWindow")
	self.wndIntRemodelHeaderFrame 	= self.wndRemodel:FindChild("IntHeaderWindow")
	self.wndCommunityRemodelHeaderFrame 	= self.wndRemodel:FindChild("CommunityHeaderWindow")
	self.wndRemodelHeaderFrameTitle	= self.wndRemodel:FindChild("BGArt:RoomConfigurationTitle")
	self.wndExtPreviewWindow 		= self.wndRemodel:FindChild("ExtPreviewWindow")
	self.wndIntPreviewWindow 		= self.wndRemodel:FindChild("IntPreviewWindow")
	self.wndCommunityPreviewWindow 		= self.wndRemodel:FindChild("CommunityPreviewWindow")
	self.wndIntRemodelRemoveBtn 	= self.wndRemodel:FindChild("RemoveIntOption")
	self.wndCurrentUpgradeLabel		= self.wndRemodel:FindChild("CurrentOptionDisplayString")
	self.wndSearchWindow 			= self.wndRemodel:FindChild("SearchBox")
	self.wndClearSearchBtn 			= self.wndRemodel:FindChild("ClearSearchBtn")

	self.wndPropertySettingsPopup	= Apollo.LoadForm(self.xmlDoc, "PropertySettingsPanel", nil, self)
	self.wndPropertyRenamePopup 	= Apollo.LoadForm(self.xmlDoc, "PropertyRenamePanel", nil, self)
	
	self.wndCommunitySettingsBtn    = self.wndConfigure:FindChild("CommunitySettingsBtn")
	self.wndCommunitySettingsBtn:Show(false)
	
	self.wndCommunitySettingsPopup  = Apollo.LoadForm(self.xmlDoc, "CommunitySettingsPanel", nil, self)
	self.wndCommunitySettingsPopup:Show(false)
	self.wndCommunitySettingsPopup:FindChild("ReservePlotBtn"):AttachWindow(self.wndCommunitySettingsPopup:FindChild("ReservePlotBtn"):FindChild("ConfirmWindow"))
	self.wndCommunitySettingsPopup:FindChild("EvictResidentBtn"):AttachWindow(self.wndCommunitySettingsPopup:FindChild("EvictResidentBtn"):FindChild("ConfirmWindow"))
	self.wndCommunitySettingsPopup:FindChild("PlaceBtn"):AttachWindow(self.wndCommunitySettingsPopup:FindChild("PlaceBtn"):FindChild("ConfirmWindow"))
	self.wndCommunitySettingsPopup:FindChild("RemoveBtn"):AttachWindow(self.wndCommunitySettingsPopup:FindChild("RemoveBtn"):FindChild("ConfirmWindow"))
	self.wndCommunitySettingsPopup:FindChild("VisitCommunityBtn"):AttachWindow(self.wndCommunitySettingsPopup:FindChild("VisitCommunityBtn"):FindChild("ConfirmWindow"))
	
	self.wndListView:SetColumnText(1, Apollo.GetString("HousingRemodel_UpgradeColumn"))
	self.wndListView:SetColumnText(2, Apollo.GetString("HousingRemodel_Cost"))
	
	self.wndRandomList = Apollo.LoadForm(self.xmlDoc, "RandomFriendsForm", nil, self)
	self.wndRandomList:Show(false)
	self.wndRandomList:FindChild("VisitRandomBtn"):AttachWindow(self.wndRandomList:FindChild("VisitRandomBtn"):FindChild("VisitWindow"))

	for idx = 1, knExtRemodelTabs do
		self.tExtRemodelTabs[idx] = self.wndExtRemodelHeaderFrame:FindChild("ExtRemodelTab" .. tostring(idx))
	end

	for idx = 1, knIntRemodelTabs do
		self.tIntRemodelTabs[idx] = self.wndIntRemodelHeaderFrame:FindChild("IntRemodelTab" .. tostring(idx))
	end
	
	for idx = 1, knCommunityRemodelTabs do
		self.tCommunityRemodelTabs[idx] = self.wndCommunityRemodelHeaderFrame:FindChild("CommunityRemodelTab" .. tostring(idx))
	end
	
	self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 1)
	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 1)
	self.wndCommunityRemodelHeaderFrame:SetRadioSel("CommunityRemodelTab", 1)
	self.luaExtRemodelPreviewControl:OnLoad("exterior", self.wndRemodel:FindChild("ExtPreviewWindow"), self.wndRemodel, {"Roof", "Wallpaper", "Entry", "Door", "Sky", "Music", "Ground"})
	self.luaIntRemodelPreviewControl:OnLoad("interior", self.wndRemodel:FindChild("IntPreviewWindow"), self.wndRemodel, {"IntWallpaper", "Floor", "Ceiling", "Trim", "Lighting", "IntMusic"})
	self.luaCommunityRemodelPreviewControl:OnLoad("community", self.wndRemodel:FindChild("CommunityPreviewWindow"), self.wndRemodel, {"CommunitySky", "CommunityMusic", "CommunityGround"})

	self.wndReplaceButton:Enable(false)
	self.wndReplaceButton:Show(true)
	self.wndCancelButton:Enable(false)
	self.wndClearSearchBtn:Show(false)
	
	self.rResidence = HousingLib.GetResidence()

	self.wndCashRemodel:SetAmount(GameLib.GetPlayerCurrency(), true)
	HousingLib.RefreshUI()
	
	local arGuilds = GuildLib.GetGuilds()
	for key, guildCurr in pairs(arGuilds) do
		if guildCurr:GetType() == GuildLib.GuildType_Community then
			self.wndCommunitySettingsPopup:SetData(guildCurr)
			self.wndCommunitySettingsBtn:Show(true)
		end
	end
	
	-- Retry, in case Guild Lib is still loading
	if self.wndCommunitySettingsPopup:GetData() ~= nil and GuildLib:IsLoading() then
		Apollo.StartTimer("RetryLoadingCommunity")
	end

	Apollo.RegisterEventHandler("WindowManagementReady", 	"OnWindowManagementReady", self)
	self:OnWindowManagementReady()
end

function HousingRemodel:OnWindowManagementReady()
	local strNameRemodel = String_GetWeaselString(Apollo.GetString("Tooltips_ItemSpellEffect"), Apollo.GetString("CRB_Housing"), Apollo.GetString("CRB_Remodel"))
	Event_FireGenericEvent("WindowManagementRegister", {strName = strNameRemodel, nSaveVersion=2})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndRemodel, strName = strNameRemodel, nSaveVersion=2})
	
	local strNameNeighbors = String_GetWeaselString(Apollo.GetString("Tooltips_ItemSpellEffect"), Apollo.GetString("CRB_Housing"), Apollo.GetString("InterfaceMenu_Neighbors"))
	Event_FireGenericEvent("WindowManagementRegister", {strName = strNameNeighbors, nSaveVersion=2})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndRandomList, strName = strNameNeighbors, nSaveVersion=2})
end

function HousingRemodel:OnChangeWorld()
	self.wndRandomList:Show(false)
	
	if self.wndCommunitySettingsPopup:IsShown() then
		self.wndCommunitySettingsPopup:Close()
	end
end

function HousingRemodel:OnUpdateInventory()
	if self.wndRemodel:IsVisible() then
        Apollo.StartTimer("HousingRemodelTimer")
	end
end

function HousingRemodel:OnStoreLinksRefresh()
	if self.wndRemodel:IsVisible() then
		self:OnCancelBtn()
	end
end

---------------------------------------------------------------------------------------------------
-- Random List Functions
---------------------------------------------------------------------------------------------------
function HousingRemodel:ShowRandomList()
	local nWidth = self.wndRandomList:GetWidth()
	local nHeight = self.wndRandomList:GetHeight()

	--populate
	HousingLib.RequestRandomResidenceList()
	self.wndRandomList:FindChild("VisitRandomBtn"):Enable(false)
	self.wndRandomList:FindChild("ListContainer"):DestroyChildren()
	self.wndRandomList:FindChild("ListIndividualsBtn"):SetCheck(true)
	self.wndRandomList:FindChild("ListCommunitiesBtn"):SetCheck(false)
	self.wndRandomList:Invoke()
end

function HousingRemodel:OnRandomResidenceList()
	if self.wndRandomList:FindChild("ListIndividualsBtn"):IsChecked() then
		self:FillRandomResidenceList(false)
	end
end

function HousingRemodel:OnRandomCommunityList()
	if self.wndRandomList:FindChild("ListCommunitiesBtn"):IsChecked() then
		self:FillRandomCommunityList(false)
	end
end

function HousingRemodel:FillRandomResidenceList(bRequestIfEmpty)
	self.wndRandomList:FindChild("ListContainer"):DestroyChildren()
	
	local arResidences = HousingLib.GetRandomResidenceList()
	if bRequestIfEmpty and #arResidences == 0 then
		HousingLib.RequestRandomResidenceList()
		return
	end

	for key, tHouse in pairs(arResidences) do
		local wnd = Apollo.LoadForm(self.xmlDoc, "RandomFriendForm", self.wndRandomList:FindChild("ListContainer"), self)
		wnd:SetData(tHouse.nId) -- set the full table since we have no direct lookup for neighbors
		wnd:FindChild("PlayerName"):SetText(String_GetWeaselString(Apollo.GetString("Neighbors_OwnerListing"), tHouse.strCharacterName))
		wnd:FindChild("PropertyName"):SetText(tHouse.strResidenceName)
	end
	
	self.wndRandomList:FindChild("ListContainer"):ArrangeChildrenVert()
	self.wndRandomList:FindChild("VisitRandomBtn"):Enable(false)
	self.wndRandomList:FindChild("ClearSearchBtn"):Show(false)
	self.wndRandomList:FindChild("VisitNameEntry"):SetText("")
	self.wndRandomList:FindChild("VisitPlayerLabel"):SetText(Apollo.GetString("Neighbors_VisitPlayerByName"))
end

function HousingRemodel:FillRandomCommunityList(bRequestIfEmpty)
	self.wndRandomList:FindChild("ListContainer"):DestroyChildren()
	
	local arCommunities = HousingLib.GetRandomCommunityList()
	if bRequestIfEmpty and #arCommunities == 0 then
		HousingLib.RequestRandomCommunityList()
		return
	end

	for key, tHouse in pairs(arCommunities) do
		local wnd = Apollo.LoadForm(self.xmlDoc, "RandomFriendForm", self.wndRandomList:FindChild("ListContainer"), self)
		wnd:SetData(tHouse.nId) -- set the full table since we have no direct lookup for neighbors
		wnd:FindChild("PropertyName"):SetText(tHouse.strResidenceName)
		wnd:FindChild("PlayerName"):SetText(String_GetWeaselString(Apollo.GetString("Neighbors_OwnerListing"), tHouse.strCommunityLeader))
	end
		
	self.wndRandomList:FindChild("ListContainer"):ArrangeChildrenVert()
	self.wndRandomList:FindChild("VisitRandomBtn"):Enable(false)
	self.wndRandomList:FindChild("ClearSearchBtn"):Show(false)
	self.wndRandomList:FindChild("VisitNameEntry"):SetText("")
	self.wndRandomList:FindChild("VisitPlayerLabel"):SetText(Apollo.GetString("Neighbors_VisitCommunityByName"))
end

function HousingRemodel:OnListIndividuals(wndHandler, wndControl)
	self:FillRandomResidenceList(true)
end

function HousingRemodel:OnListCommunities(wndHandler, wndControl)
	self:FillRandomCommunityList(true)
end

function HousingRemodel:OnRandomFriendClose()
	self.wndRandomList:Close()
end

function HousingRemodel:OnSubCloseBtn(wndHandler, wndControl)
	wndHandler:GetParent():Close()
end

function HousingRemodel:OnVisitRandomBtn(wndHandler, wndControl)
	wndControl:FindChild("VisitWindow"):Show(true)
	
	if self.wndRandomList:FindChild("ListIndividualsBtn"):IsChecked() then
		wndControl:FindChild("VisitWindow:Prompt"):SetText(Apollo.GetString("Neighbors_VisitPlayer"))
	elseif self.wndRandomList:FindChild("ListCommunitiesBtn"):IsChecked() then
		wndControl:FindChild("VisitWindow:Prompt"):SetText(Apollo.GetString("Neighbors_VisitCommunity"))
	end
end

function HousingRemodel:OnVisitRandomConfirmBtn(wndHandler, wndControl)
	local strName = self.wndRandomList:FindChild("VisitNameEntry"):GetText()
	if self.wndRandomList:FindChild("ListIndividualsBtn"):IsChecked() then
		if strName ~= nil and strName ~= "" then
			HousingLib.RequestVisitPlayer(strName)
		else
			HousingLib.RequestRandomVisit(wndControl:GetParent():GetData())
		end
	elseif self.wndRandomList:FindChild("ListCommunitiesBtn"):IsChecked() then
		if strName ~= nil and strName ~= "" then
			HousingLib.RequestVisitCommunityByName(strName)
		else
			HousingLib.RequestRandomCommunityVisit(wndControl:GetParent():GetData())
		end
	end
	wndControl:GetParent():Show(false)
end

function HousingRemodel:OnRandomFriendBtn(wndHandler, wndControl)
	local nId = wndControl:GetParent():GetData()

	for key, wndRandomNeighbor in pairs(self.wndRandomList:FindChild("ListContainer"):GetChildren()) do
		wndRandomNeighbor:FindChild("FriendBtn"):SetCheck(nId == wndRandomNeighbor:GetData())
	end

	self.wndRandomList:FindChild("VisitRandomBtn"):FindChild("VisitWindow"):SetData(nId)
	self.wndRandomList:FindChild("VisitRandomBtn"):Enable(true)
	
	self.wndRandomList:FindChild("VisitNameEntry"):SetText("")
    self.wndRandomList:FindChild("VisitNameEntry"):SetFocus(false)
	self.wndRandomList:FindChild("ClearSearchBtn"):Show(false)
end

function HousingRemodel:OnRandomFriendBtnUncheck(wndHandler, wndControl)
	self.wndRandomList:FindChild("VisitRandomBtn"):Enable(false)
end

function HousingRemodel:OnRandomVisitNameChanged()
	local strName = self.wndRandomList:FindChild("VisitNameEntry"):GetText()
	if strName ~= nil and strName ~= "" then
		self.wndRandomList:FindChild("VisitRandomBtn"):Enable(true)
		self.wndRandomList:FindChild("ClearSearchBtn"):Show(true)
		
		for key, wndRandomNeighbor in pairs(self.wndRandomList:FindChild("ListContainer"):GetChildren()) do
		    wndRandomNeighbor:FindChild("FriendBtn"):SetCheck(false)
	    end
	else
		local selectedNeighbor = self.wndRandomList:FindChild("VisitRandomBtn"):FindChild("VisitWindow"):GetData()
		if selectedNeighbor then
			self.wndRandomList:FindChild("VisitRandomBtn"):Enable(true)
		else
			self.wndRandomList:FindChild("VisitRandomBtn"):Enable(false)
		end
		self.wndRandomList:FindChild("ClearSearchBtn"):Show(false)
	end
end

function HousingRemodel:OnClearSearch()
    local selectedNeighbor = self.wndRandomList:FindChild("VisitRandomBtn"):FindChild("VisitWindow"):GetData()
    if selectedNeighbor then
        self.wndRandomList:FindChild("VisitRandomBtn"):Enable(true)
    else
        self.wndRandomList:FindChild("VisitRandomBtn"):Enable(false)
    end
    self.wndRandomList:FindChild("ClearSearchBtn"):Show(false)
    self.wndRandomList:FindChild("VisitNameEntry"):SetText("")
    self.wndRandomList:FindChild("VisitNameEntry"):SetFocus(false)
end

function HousingRemodel:OnRefreshRandomVisitList(wndHandler, wndControl)
	if self.wndRandomList:FindChild("ListIndividualsBtn"):IsChecked() then
		HousingLib.RequestRandomResidenceList()
	else
		HousingLib.RequestRandomCommunityList()
	end
end

-----------------------------------------------------------------------------------------------
-- HousingRemodel Functions
-----------------------------------------------------------------------------------------------

function HousingRemodel:ResetPopups()
	self.wndPropertyRenamePopup:Close()
	self.wndPropertySettingsPopup:Close()
end

function HousingRemodel:OnSortByUncheck()
	if self.bPlayerIsInside then
		self.wndRemodel:FindChild("IntSortByList"):Show(false)
	else
		self.wndRemodel:FindChild("ExtSortByList"):Show(false)
	end
end

function HousingRemodel:OnSortByCheck()
	if self.bPlayerplayerIsInside then
		self.wndRemodel:FindChild("IntSortByList"):Show(true)
	else
		self.wndRemodel:FindChild("ExtSortByList"):Show(true)
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnHousingButtonRemodel()
	if not self.wndRemodel:IsVisible() then
        self.wndRemodel:Invoke()
        self:ShowAppropriateRemodelTab()  
		self:DisableUnusableTabs()
	else
	    self:OnCloseHousingRemodelWindow()
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:DisableUnusableTabs()
	local tPlotHouse = HousingLib.GetPlot(1)--Get housing plot.
	if tPlotHouse then
		local nFirstEnabled = nil
		for idx = 1, knExtRemodelTabs do
			local wndBtn = self.tExtRemodelTabs[idx]
			local tData = nil
			if idx == 1 then
		        tData = HousingLib.GetRemodelRoofList()
		    elseif idx == 2 then
		        tData = HousingLib.GetRemodelWallpaperExteriorList()
		    elseif idx == 3 then
		        tData = HousingLib.GetRemodelEntryList()
		    elseif idx == 4 then
		        tData = HousingLib.GetRemodelDoorList()
		    elseif idx == 5 then
		        tData = HousingLib.GetRemodelSkyExteriorList()
		    elseif idx == 6 then
		        tData = HousingLib.GetRemodelMusicExteriorList()
		    else
		        tData = HousingLib.GetRemodelGroundList()
			end

			local bEnabled = tData ~= nil and next(tData) ~= nil
			wndBtn:Enable(bEnabled)
			if nFirstEnabled == nil and bEnabled then
				nFirstEnabled = idx
			end
		end

		if nFirstEnabled ~= nil then
			local wndEnabled = self.tExtRemodelTabs[nFirstEnabled]
			self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", nFirstEnabled)
			self:OnRemodelTabBtn(wndEnabled, wndEnabled)
		end
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnHousingButtonCrate()
	if self.wndRemodel:IsVisible() then
		self:OnCloseHousingRemodelWindow()
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnHousingButtonList()
	if self.wndRemodel:IsVisible() then
		self:OnCloseHousingRemodelWindow()
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnHousingButtonLandscape()
	if self.wndRemodel:IsVisible() then
		self:OnCloseHousingRemodelWindow()
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnOpenPanelControl(idPropertyInfo, idZone, bPlayerIsInside)
	if self.bPlayerIsInside ~= bPlayerIsInside then
		self:OnCloseHousingRemodelWindow()
	end

    if gidZone ~= idZone then
		self.luaIntRemodelPreviewControl:OnAllChoicesCanceled(false)
	end
	
	self.rResidence = HousingLib.GetResidence()

	gidZone = idZone
	self.idPropertyInfo = idPropertyInfo
	self.bPlayerIsInside = bPlayerIsInside == true --make sure we get true/false
	
	self:HelperShowHeader()

	if bPlayerIsInside then
		self.luaIntRemodelPreviewControl:OnResidenceChange(gidZone)
	    self:ShowAppropriateRemodelTab()
	else
	    self.luaExtRemodelPreviewControl:OnResidenceChange(gidZone)
	    self.luaCommunityRemodelPreviewControl:OnResidenceChange(gidZone)
	    self:ShowAppropriateRemodelTab()
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnClosePanelControl()
	self:OnCloseHousingRemodelWindow() -- you've left your property!
	
	self:HelperShowHeader()
end

function HousingRemodel:HelperShowHeader()
	local resCurrent = HousingLib.GetResidence()
	self.wndConfigure:Show(HousingLib.IsHousingWorld() and (resCurrent ~= nil and not resCurrent:IsWarplotResidence() or true))
	self.wndConfigure:FindChild("PropertyName"):SetText(resCurrent ~= nil and resCurrent:GetPropertyName() or "")
	self.wndConfigure:FindChild("PropertySettingsBtn"):Show(HousingLib.IsOnMyResidence())
	self.wndConfigure:FindChild("TeleportHomeBtn"):Show(not HousingLib.IsOnMyResidence())

	local bCanTeleport = not (HousingLib.IsOnMyCommunity() and HousingLib.IsMyResidenceOnCommunity())
	self.wndConfigure:FindChild("TeleportHomeBtn"):Enable(bCanTeleport)
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnReplaceBtn(wndControl, wndHandler)
    if self.rResidence == nil then
        return
    end

    if self.bPlayerIsInside then
	    self.luaIntRemodelPreviewControl:PurchaseRemodelChanges()
	    -- call this to refresh our windows
	    self:ShowAppropriateIntRemodelTab()
	else
	    if self.rResidence:IsCommunityResidence() then
	        self.luaCommunityRemodelPreviewControl:PurchaseRemodelChanges()
	    else
	        self.luaExtRemodelPreviewControl:PurchaseRemodelChanges()
	    end
	    
	    self.idUniqueItem = nil

	    -- give the server enough time to process the purchase request, then update the UI
		Apollo.StartTimer("HousingRemodelTimer")
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnCancelBtn(wndControl, wndHandler)
	Sound.Play(Sound.PlayUIHousingItemCancelled)
	if self.bPlayerIsInside then
	    self:ResetIntRemodelPreview(false)
	else
	    self:ResetExtRemodelPreview(false)
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnWindowClosed()
	-- called after the window is closed by:
	--	self.winMasterCustomizeFrame:Close() or
	--  hitting ESC or
	--  C++ calling Event_CloseHousingVendorWindow()

	-- popup windows reset
	self:ResetPopups()

	self:ResetExtRemodelPreview(true)
	self:ResetIntRemodelPreview(true)
	self.wndSearchWindow:SetText("")
	self.wndClearSearchBtn:Show(false)
	Sound.Play(Sound.PlayUIWindowClose)
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnCloseHousingRemodelWindow()
	-- close the window which will trigger OnWindowClosed
	self:ResetPopups()
	self.wndListView:SetCurrentRow(0)
	self.idUniqueItem = nil
	self.idIntPruneItem = nil
	self.wndRemodel:Close()
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:SwitchRemodelTab()
	self.wndSearchWindow:ClearFocus()

	for idx = 1, knExtRemodelTabs do
		self.tExtRemodelTabs[idx]:SetTextColor(kcrDarkBlue)
	end

	local nRemodelSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
	if nRemodelSel >= 1 and nRemodelSel <= knExtRemodelTabs then
		self.tExtRemodelTabs[nRemodelSel]:SetTextColor(kcrWhite)
	end

	for idx = 1, knIntRemodelTabs do
		self.tIntRemodelTabs[idx]:SetTextColor(kcrDarkBlue)
	end

	nRemodelSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nRemodelSel >= 1 and nRemodelSel <= knIntRemodelTabs then
		self.tIntRemodelTabs[nRemodelSel]:SetTextColor(kcrWhite)
	end
	
	for idx = 1, knCommunityRemodelTabs do
		self.tCommunityRemodelTabs[idx]:SetTextColor(kcrDarkBlue)
	end

	local nRemodelSel = self.wndCommunityRemodelHeaderFrame:GetRadioSel("CommunityRemodelTab")
	if nRemodelSel >= 1 and nRemodelSel <= knCommunityRemodelTabs then
		self.tCommunityRemodelTabs[nRemodelSel]:SetTextColor(kcrWhite)
	end

	self:ShowAppropriateRemodelTab()
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnRemodelTabBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	self:SwitchRemodelTab()
end

---------------------------------------------------------------------------------------------------
--Upper buttons:
function HousingRemodel:OnEntryOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 3)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnWallOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 2)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnRoofOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 1)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnDoorOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 4)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnSkyOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() or self.rResidence == nil then
		return
	end
	if self.rResidence:IsCommunityResidence() then
	    self.wndCommunityRemodelHeaderFrame:SetRadioSel("CommunityRemodelTab", 1)
	else
	    self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 5)
	end
	self:SwitchRemodelTab()
end

function HousingRemodel:OnMusicOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() or self.rResidence == nil then
		return
	end
	if self.rResidence:IsCommunityResidence() then
	    self.wndCommunityRemodelHeaderFrame:SetRadioSel("CommunityRemodelTab", 2)
	else
	    self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 6)
	end
	self:SwitchRemodelTab()
end

function HousingRemodel:OnGroundOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() or self.rResidence == nil then
		return
	end
	if self.rResidence:IsCommunityResidence() then
	    self.wndCommunityRemodelHeaderFrame:SetRadioSel("CommunityRemodelTab", 3)
	else
	    self.wndExtRemodelHeaderFrame:SetRadioSel("ExtRemodelTab", 7)
	end
	self:SwitchRemodelTab()
end

--Upper buttons (Interior):
function HousingRemodel:OnCeilingOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 1)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnTrimOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 2)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnIntWallpaperOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 3)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnFloorOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 4)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnLightingOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 5)
	self:SwitchRemodelTab()
end

function HousingRemodel:OnIntMusicOptionsBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	self.wndIntRemodelHeaderFrame:SetRadioSel("IntRemodelTab", 6)
	self:SwitchRemodelTab()
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnHousingNameProperty()
	self.wndPropertyRenamePopup:FindChild("CostWindow"):SetMoneySystem(Money.CodeEnumCurrencyType.Renown)
	self.wndPropertyRenamePopup:FindChild("CostWindow"):SetAmount(0)

	self.wndPropertyRenamePopup:FindChild("OldNameEntry"):SetText(self.rResidence ~= nil and self.rResidence:GetPropertyName() or "")
	self.wndPropertyRenamePopup:FindChild("NewNameEntry"):SetText("")
	self.wndPropertyRenamePopup:FindChild("ClearNameEntryBtn"):Show(false)

	self:CheckPropertyNameChange()

	self.wndRemodel:Close()
	self:ResetPopups()
	self.wndPropertyRenamePopup:Invoke()
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnPropertyNameBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	
	local nRenameCost = self.rResidence ~= nil and self.rResidence:GetPropertyName() ~= "" and HousingLib.PropertyRenameCost or 0

	self.wndPropertyRenamePopup:FindChild("CostWindow"):SetMoneySystem(Money.CodeEnumCurrencyType.Renown)
	self.wndPropertyRenamePopup:FindChild("CostWindow"):SetAmount(nRenameCost)

	self.wndPropertyRenamePopup:FindChild("OldNameEntry"):SetText(self.rResidence ~= nil and self.rResidence:GetPropertyName() or "")
	self.wndPropertyRenamePopup:FindChild("NewNameEntry"):SetText("")
	self.wndPropertyRenamePopup:FindChild("ClearNameEntryBtn"):Show(false)

	self:CheckPropertyNameChange()

	self.wndRemodel:Close()
	self:ResetPopups()
	self.wndPropertyRenamePopup:Invoke()
end

function HousingRemodel:CheckPropertyNameChange(wndHandler, wndControl)
	local strProposed = self.wndPropertyRenamePopup:FindChild("NewNameEntry"):GetText()
	local bCanAfford = false
	if self.rResidence ~= nil then
		bCanAfford = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Renown):GetAmount() >= HousingLib.PropertyRenameCost or self.rResidence:GetPropertyName() == ""
	end
	local bTextValid = GameLib.IsTextValid(strProposed, GameLib.CodeEnumUserText.HousingResidenceName, GameLib.CodeEnumUserTextFilterClass.Strict)
	
	
	self.wndPropertyRenamePopup:FindChild("RenameBtn"):Enable(bCanAfford and strProposed ~= "" and bTextValid)
	self.wndPropertyRenamePopup:FindChild("RenameValidAlert"):Show(strProposed ~= "" and not bTextValid)
	self.wndPropertyRenamePopup:FindChild("ClearNameEntryBtn"):Show(strProposed ~= "")
end

function HousingRemodel:OnClearNameEntryBtn(wndHandler, wndControl)
	self.wndPropertyRenamePopup:FindChild("NewNameEntry"):SetText("")
	self.wndPropertyRenamePopup:FindChild("NewNameEntry"):ClearFocus()
	self:CheckPropertyNameChange()
end

function HousingRemodel:OnRenameAccept(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() or self.rResidence == nil then
		return
	end

	self.rResidence:RenameProperty(self.wndPropertyRenamePopup:FindChild("NewNameEntry"):GetText())

	self.wndPropertyRenamePopup:Close()
	
	self:HelperShowHeader()
end

function HousingRemodel:OnRenameCancel(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
    
    self.wndPropertyRenamePopup:Close()
end

function HousingRemodel:CheckCommunityNameChange(wndHandler, wndControl)
	local strProposed = self.wndCommunityRenamePopup:FindChild("NewNameEntry"):GetText()
	local bCanAfford = false
	local bCanAffordAlt = false
	local tRenameCosts = HousingLib.GetCommunityRenameCosts()
	
	if tRenameCosts ~= nil then
		if tRenameCosts.monCreditCost ~= nil then
			bCanAfford = tRenameCosts.monCreditCost:CanAfford()
		end
		
		if tRenameCosts.monServiceTokenCost ~= nil then
			bCanAffordAlt = tRenameCosts.monServiceTokenCost:CanAfford()
		end
	end
	
	local bTextValid = GameLib.IsTextValid(strProposed, GameLib.CodeEnumUserText.GuildName, GameLib.CodeEnumUserTextFilterClass.Strict)
	
	self.wndCommunityRenamePopup:FindChild("RenameCreditsBtn"):Enable(bCanAfford and strProposed ~= "" and bTextValid)
	self.wndCommunityRenamePopup:FindChild("RenameTokensBtn"):Enable(bCanAffordAlt and strProposed ~= "" and bTextValid)
	self.wndCommunityRenamePopup:FindChild("RenameValidAlert"):Show(not bTextValid and strProposed ~= "")
end


---------------------------------------------------------------------------------------------------
function HousingRemodel:OnCommunityNameBtn(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	
	if not self.guildCommunity then
		return
	end
	
	if self.wndCommunityRenamePopup ~= nil then
		self.wndCommunityRenamePopup:Destroy()
		self.wndCommunityRenamePopup = nil
	end
	
	local tRenameCosts = HousingLib.GetCommunityRenameCosts()
	if not tRenameCosts then
		return
	end

	self.wndCommunityRenamePopup = Apollo.LoadForm(self.xmlDoc, "CommunityRenamePanel", nil, self)
	
	if tRenameCosts.monCreditCost ~= nil then
		self.wndCommunityRenamePopup:FindChild("RenameCreditsBtn:CashWindow"):SetAmount(tRenameCosts.monCreditCost)
	end
	
	if tRenameCosts.monServiceTokenCost ~= nil then
		self.wndCommunityRenamePopup:FindChild("RenameTokensBtn:CashWindow"):SetAmount(tRenameCosts.monServiceTokenCost)
	end
	
	self.wndCommunityRenamePopup:FindChild("OldNameEntry"):SetText(self.guildCommunity:GetName())
	self.wndCommunityRenamePopup:FindChild("NewNameEntry"):SetText("")

	self:CheckCommunityNameChange()
	self.wndCommunityRenamePopup:Invoke()
end

function HousingRemodel:OnCommunityRenameConfirm(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	local strProposed = self.wndCommunityRenamePopup:FindChild("NewNameEntry"):GetText()
	local bUseAlternateCost = wndControl == self.wndCommunityRenamePopup:FindChild("RenameTokensBtn")
	
	local tRenameCosts = HousingLib.GetCommunityRenameCosts()
	
	if not tRenameCosts then
		return
	end
		
	if not bUseAlternateCost and not tRenameCosts.monCreditCost then
		return
	end
	
	if bUseAlternateCost and not tRenameCosts.monServiceTokenCost then
		return
	end
		
	local monCost = tRenameCosts.monCreditCost
	if bUseAlternateCost then
		monCost = tRenameCosts.monServiceTokenCost
	end
	
	local tConfirmationData =
	{
		monCost = monCost,
		wndParent = self.wndCommunityRenamePopup,
		strConfirmation = String_GetWeaselString(Apollo.GetString("Community_RenameConfirm"), self.guildCommunity:GetName(), strProposed),
		tActionData = { GameLib.CodeEnumConfirmButtonType.RenameCommunity, strProposed, bUseAlternateCost },
		strEventName = "ServiceTokenClosed_RenameCommunity",
	}

	Event_FireGenericEvent("GenericEvent_ServiceTokenPrompt", tConfirmationData)
	
	self.wndCommunityRenamePopup:FindChild("NewNameEntry"):ClearFocus()
end

function HousingRemodel:OnCommunityRenameCancel(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
    
    self.wndCommunityRenamePopup:Destroy()
	self.wndCommunityRenamePopup = nil
end

function HousingRemodel:OnServiceTokenDialogClosed(strParent, tActionData, retCode)
	if retCode == true then
		self.wndCommunityRenamePopup:SetData(true)
	end
end

function HousingRemodel:OnCommunityRenameResult(nResult)
	if not self.wndCommunityRenamePopup then
		return
	end
	
	local strMessage = ""
	if nResult == HousingLib.HousingResult_Success then
		strMessage = String_GetWeaselString(Apollo.GetString("Community_NameChanged"), self.guildCommunity:GetName())
	elseif nResult == HousingLib.HousingResult_Failed then
		strMessage = Apollo.GetString("Community_RenameFailed")
	elseif nResult == HousingLib.HousingResult_InvalidPermissions then
		strMessage = Apollo.GetString("HousingRemodel_DoNotHavePermission")
	elseif nResult == HousingLib.HousingResult_InvalidResidenceName then
		strMessage = Apollo.GetString("GuildResult_NameUnavailable")
	elseif nResult == HousingLib.HousingResult_InsufficientFunds then
		strMessage = Apollo.GetString("HousingResult_InsufficientFunds")
	end
	
	if strMessage ~= "" then
		local wndAlert = self.wndCommunityRenamePopup:FindChild("AlertMessage")
		wndAlert:Show(true)
		wndAlert:FindChild("MessageBody"):SetText(strMessage)
		Apollo.CreateTimer("CommunityRenameAlertTimer", 3.0, false)
	end
end

function HousingRemodel:OnCommunityRenameAlertTimer()
	if not self.wndCommunityRenamePopup then
		return
	end
	
	if self.wndCommunityRenamePopup:GetData() == true then
		-- close rename window
		self.wndCommunityRenamePopup:Destroy()
		self.wndCommunityRenamePopup = nil
	else
		self.wndCommunityRenamePopup:FindChild("AlertMessage"):Show(false)
	end
end

function HousingRemodel:OnRemodelTimer()
	self.luaExtRemodelPreviewControl:OnResidenceChange(gidZone)
	self.luaCommunityRemodelPreviewControl:OnResidenceChange(gidZone)
    -- call this to refresh our windows
    self:ShowAppropriateExtRemodelTab()
end

function HousingRemodel:OnIntRemodelTimer()
	--update the player's money
	self.wndListView:SetCurrentRow(0)
end

-----------------------------------------------------------------------------------------------
-- DecorateItemList Functions
-----------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
function HousingRemodel:OnRemodelListItemChange(wndControl, wndHandler, nX, nY)
	self.wndSearchWindow:ClearFocus()

	if wndControl ~= wndHandler then
		return
	end

	-- find the item id of the thingie that's selected
    local nRow = wndControl:GetCurrentRow()
    local idItem = wndControl:GetCellData(nRow, 1 )
    self.idUniqueItem = idItem

	--Print("id is: " .. id)
	local wndCheckButton = nil
	local tItemList = nil
	Sound.Play(Sound.PlayUIButtonHoloSmall)

	if self.bPlayerIsInside then
		self.wndReplaceButton:Show(self.idUniqueItem ~= self.idIntPruneItem)
		self.wndIntRemodelRemoveBtn:Show(self.idUniqueItem == self.idIntPruneItem)
		
		if self.idUniqueItem == self.idIntPruneItem then
			local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
			if nSel == 1 then
				self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Ceiling)
				wndCheckButton = self.wndRemodel:FindChild("CeilingPreviewBtn")
			elseif nSel == 2 then
				self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Trim)
				wndCheckButton = self.wndRemodel:FindChild("TrimPreviewBtn")
			elseif nSel == 3 then
				self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Wallpaper)
				wndCheckButton = self.wndRemodel:FindChild("IntWallpaperPreviewBtn")
			elseif nSel == 4 then
				self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Floor)
				wndCheckButton = self.wndRemodel:FindChild("FloorPreviewBtn")
			elseif nSel == 5 then
                self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Lighting)
				wndCheckButton = self.wndRemodel:FindChild("LightingPreviewBtn")
			else
			    self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Music)
				wndCheckButton = self.wndRemodel:FindChild("IntMusicPreviewBtn")
			end
		else
			local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
			if nSel == 1 then
				self.luaIntRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeInterior.Ceiling, idItem, self.tRemodelVendorWallpaperList)
				wndCheckButton = self.wndRemodel:FindChild("CeilingPreviewBtn")
				tItemList = self.tRemodelVendorWallpaperList
			elseif nSel == 2 then
				self.luaIntRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeInterior.Trim, idItem, self.tRemodelVendorWallpaperList)
				wndCheckButton = self.wndRemodel:FindChild("TrimPreviewBtn")
				tItemList = self.tRemodelVendorWallpaperList
			elseif nSel == 3 then
				self.luaIntRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeInterior.Wallpaper, idItem, self.tRemodelVendorWallpaperList)
				wndCheckButton = self.wndRemodel:FindChild("IntWallpaperPreviewBtn")
				tItemList = self.tRemodelVendorWallpaperList
			elseif nSel == 4 then
				self.luaIntRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeInterior.Floor, idItem, self.tRemodelVendorWallpaperList)
				wndCheckButton = self.wndRemodel:FindChild("FloorPreviewBtn")
				tItemList = self.tRemodelVendorWallpaperList
			elseif nSel == 5 then
        	    self.luaIntRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeInterior.Lighting, idItem, self.tRemodelVendorWallpaperList)
				wndCheckButton = self.wndRemodel:FindChild("LightingPreviewBtn")
				tItemList = self.tRemodelVendorWallpaperList
			else
			    self.luaIntRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeInterior.Music, idItem, self.tRemodelVendorWallpaperList)
				wndCheckButton = self.wndRemodel:FindChild("IntMusicPreviewBtn")
				tItemList = self.tRemodelVendorWallpaperList
			end
		end
	else
	    if not self.rResidence or not self.rResidence:IsCommunityResidence() then
            local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
            if nSel == 1 then
                self.luaExtRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeExterior.Roof, idItem, self.tRemodelRoofList)
                wndCheckButton = self.wndRemodel:FindChild("RoofPreviewBtn")
                tItemList = self.tRemodelRoofList
            elseif nSel == 2 then
                self.luaExtRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeExterior.Wallpaper, idItem, self.tRemodelVendorWallpaperList)
                wndCheckButton = self.wndRemodel:FindChild("WallpaperPreviewBtn")
                tItemList = self.tRemodelVendorWallpaperList
            elseif nSel == 3 then
                self.luaExtRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeExterior.Entry, idItem, self.tRemodelEntryList)
                wndCheckButton = self.wndRemodel:FindChild("EntryPreviewBtn")
                tItemList = self.tRemodelEntryList
            elseif nSel == 4 then
                self.luaExtRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeExterior.Door, idItem, self.tRemodelDoorList)
                wndCheckButton = self.wndRemodel:FindChild("DoorPreviewBtn")
                tItemList =  self.tRemodelDoorList
            elseif nSel == 5 then
                self.luaExtRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeExterior.Sky, idItem, self.tRemodelVendorWallpaperList)
                wndCheckButton = self.wndRemodel:FindChild("SkyPreviewBtn")
                tItemList = self.tRemodelVendorWallpaperList
            elseif nSel == 6 then
                self.luaExtRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeExterior.Music, idItem, self.tRemodelVendorWallpaperList)
                wndCheckButton = self.wndRemodel:FindChild("MusicPreviewBtn")
                tItemList = self.tRemodelVendorWallpaperList
            else
                self.luaExtRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeExterior.Ground, idItem, self.tRemodelVendorWallpaperList)
                wndCheckButton = self.wndRemodel:FindChild("GroundPreviewBtn")
                tItemList = self.tRemodelVendorWallpaperList	
            end
		else
            local nSel = self.wndCommunityRemodelHeaderFrame:GetRadioSel("CommunityRemodelTab")
            if nSel == 1 then
                self.luaCommunityRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeCommunity.Sky, idItem, self.tRemodelVendorWallpaperList)
                wndCheckButton = self.wndRemodel:FindChild("CommunitySkyPreviewBtn")
                tItemList = self.tRemodelVendorWallpaperList
            elseif nSel == 2 then
                self.luaCommunityRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeCommunity.Music, idItem, self.tRemodelVendorWallpaperList)
                wndCheckButton = self.wndRemodel:FindChild("CommunityMusicPreviewBtn")
                tItemList = self.tRemodelVendorWallpaperList
            else
                self.luaCommunityRemodelPreviewControl:OnChoiceMade(HousingLib.RemodelOptionTypeCommunity.Ground, idItem, self.tRemodelVendorWallpaperList)
                wndCheckButton = self.wndRemodel:FindChild("CommunityGroundPreviewBtn")
                tItemList = self.tRemodelVendorWallpaperList	
            end
			
		end
	end

	if tItemList then
		local tItemData = self:GetItem(idItem, tItemList)
		--if tItemData then
			self.wndCashRemodel:SetMoneySystem(tItemData.eCurrencyType)
			self.wndCashRemodel:SetAmount(GameLib.GetPlayerCurrency(tItemData.eCurrencyType))
		--end
	end

	-- "check" the preview button automatically for the user
	wndCheckButton:SetCheck(true)
	self:OnComponentPreviewOnCheck(wndCheckButton)

end

function HousingRemodel:OnGridSort()	
	if self.wndListView:IsSortAscending() then
		table.sort(self.tItemList, function(a,b) return (a.eCurrencyType < b.eCurrencyType or (a.eCurrencyType == b.eCurrencyType and a.nCost < b.nCost)) end)
	else
		table.sort(self.tItemList, function(a,b) return (a.eCurrencyType > b.eCurrencyType or (a.eCurrencyType == b.eCurrencyType and a.nCost > b.nCost)) end)
	end
	
	self:ShowItems(self.wndListView, self.tItemList, 0)
end


---------------------------------------------------------------------------------------------------
function HousingRemodel:OnHousingPropertiesReceived()
	if self.wndIntPreviewWindow:IsShown() then
		self.luaIntRemodelPreviewControl:OnAllChoicesCanceled(false)
		self.luaIntRemodelPreviewControl:OnResidenceChange(gidZone)
		self:ShowAppropriateIntRemodelTab()
	elseif self.wndExtPreviewWindow:IsShown() then
		self.luaExtRemodelPreviewControl:OnAllChoicesCanceled(false)
		self.luaExtRemodelPreviewControl:OnResidenceChange(gidZone)
		self:ShowAppropriateExtRemodelTab()
	elseif self.wndCommunityPreviewWindow:IsShown() then
		self.luaCommunityRemodelPreviewControl:OnAllChoicesCanceled(false)
		self.luaCommunityRemodelPreviewControl:OnResidenceChange(gidZone)
		self:ShowAppropriateExtRemodelTab()
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:ShowAppropriateRemodelTab()
	if self.bPlayerIsInside then
		self:ShowAppropriateIntRemodelTab()
		self.wndExtPreviewWindow:Show(false)
		self.wndIntPreviewWindow:Show(true)
		self.wndCommunityPreviewWindow:Show(false)
		self.wndExtRemodelHeaderFrame:Show(false)
		self.wndIntRemodelHeaderFrame:Show(true)
		self.wndCommunityRemodelHeaderFrame:Show(false)
		self.wndRemodelHeaderFrameTitle:SetText(Apollo.GetString("HousingRemodel_RoomConfig"))
		self.wndReplaceButton:Show(true)
		self.wndIntRemodelRemoveBtn:Show(false)
		self.wndSortByList = self.wndRemodel:FindChild("IntSortByList")
	else
		self:ShowAppropriateExtRemodelTab()
		local bIsCommunity = self.rResidence and self.rResidence:IsCommunityResidence()
		self.wndExtPreviewWindow:Show(not bIsCommunity)
		self.wndIntPreviewWindow:Show(false)
		self.wndCommunityPreviewWindow:Show(bIsCommunity)
		self.wndExtRemodelHeaderFrame:Show(not bIsCommunity)
		self.wndIntRemodelHeaderFrame:Show(false)
		self.wndCommunityRemodelHeaderFrame:Show(bIsCommunity)
		self.wndRemodelHeaderFrameTitle:SetText(Apollo.GetString("HousingRemodel_HouseConfig"))
		self.wndSortByList = self.wndRemodel:FindChild("ExtSortByList")
	end

    self.wndCashRemodel:SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
	self.wndCashRemodel:SetAmount(GameLib.GetPlayerCurrency(), true)
	--self.winNameTextBox:SetText(HousingLib.GetPropertyName())

  -- self:PopulateCategoryList()
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:SetRemodelCurrentDetails(strText)
	if strText ~= nil then
		local strLabel = string.format("<T Font=\"%s\" TextColor=\"%s\">%s</T>", "CRB_InterfaceMedium", "ff2f94ac", Apollo.GetString("HousingRemodel_CurrentUpgrade"))
		local strTextFormatted = string.format("<T Font=\"%s\" TextColor=\"%s\">%s</T>", "CRB_InterfaceMedium", "ff31fcf6", strText)
		local strFull = string.format("<T Align=\"Center\">%s</T>", String_GetWeaselString(strLabel, strTextFormatted))

		self.wndCurrentUpgradeLabel:SetText(strFull)
	else
		self.wndCurrentUpgradeLabel:SetText("")
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:ShowAppropriateIntRemodelTab()
	local idPruneItem = 0
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel < 1 or nSel > knIntRemodelTabs then
		return
	end

	local eType
	local strSearchText = self.wndSearchWindow:GetText()
	if nSel == 1 then --ceiling
	    eType = HousingLib.RemodelOptionTypeInterior.Ceiling
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperInteriorList(eType, strSearchText)
	elseif nSel == 2 then -- trim
	    eType = HousingLib.RemodelOptionTypeInterior.Trim
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperInteriorList(eType, strSearchText)
	elseif nSel == 3 then -- walls
	    eType = HousingLib.RemodelOptionTypeInterior.Wallpaper
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperInteriorList(eType, strSearchText)
	elseif nSel == 4 then -- floor
	    eType = HousingLib.RemodelOptionTypeInterior.Floor
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperInteriorList(eType, strSearchText)
	elseif nSel == 5 then -- lighting
	    eType = HousingLib.RemodelOptionTypeInterior.Lighting
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperInteriorList(eType, strSearchText)
	elseif nSel == 6 then -- music
	    eType = HousingLib.RemodelOptionTypeInterior.Music
		self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperInteriorList(eType, strSearchText)
	end
	
	if not self.tRemodelVendorWallpaperList then
		return
	end

	if gtRemodelTrueValues[eType] ~= nil then
		idPruneItem = gtRemodelTrueValues[eType].nId
	else
	    self.idIntPruneItem = nil
	end
	
	self.wndListView:SetSortColumn(1, true)
	-- Here we have an example of a nameless function being declared within another function's parameter list!
	table.sort(self.tRemodelVendorWallpaperList, function(a,b)	return (a.strName < b.strName)	end)
	self:ShowItems(self.wndListView, self.tRemodelVendorWallpaperList, idPruneItem)
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:ShowAppropriateExtRemodelTab()
	if not self.rResidence then
		self:SetRemodelCurrentDetails(nil)
		return
	end

	local idPruneItem = 0
	local strSearchText = self.wndSearchWindow:GetText()
	if not self.rResidence:IsCommunityResidence() then
        local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
        if nSel < 1 or nSel > #self.tExtRemodelTabs then
            return
        end

		self.wndRemodel:FindChild("BGArt:PropertyNameDisplay"):SetText(Apollo.GetString("Housing_RemodelYourProperty"))
        self.tExtRemodelTabs[nSel]:SetTextColor(kcrWhite)
        self.wndListView:SetSortColumn(1, true)
        
        local wndHideClutterBtn = self.wndExtPreviewWindow:FindChild("HideGroundClutterBtn")
        wndHideClutterBtn:SetCheck(self.rResidence:IsGroundClutterHidden())
        
        local wndHideSkyplotsBtn = self.wndExtPreviewWindow:FindChild("HideSkyplotsBtn")
        wndHideSkyplotsBtn:SetCheck(self.rResidence:AreSkyplotsHidden())

        local strCurrentItemText
        if nSel == 1 then
            self.tRemodelRoofList = HousingLib.GetRemodelRoofList(strSearchText)
            if self.tRemodelRoofList ~= nil then
	            table.sort(self.tRemodelRoofList, function(a,b)	return (a.strName < b.strName)	end)
            
	            idPruneItem = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Roof].tCurrentItem.nId
	            strCurrentItemText = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Roof].tCurrentItem.strName
	            self:ShowItems(self.wndListView, self.tRemodelRoofList, idPruneItem)
	        end
        elseif nSel == 2 then
            self.tRemodelVendorWallpaperList = HousingLib.GetRemodelWallpaperExteriorList(strSearchText)
            if self.tRemodelVendorWallpaperList ~= nil then
	            table.sort(self.tRemodelVendorWallpaperList, function(a,b)	return (a.strName < b.strName)	end)
	            
	            idPruneItem = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Wallpaper].tCurrentItem.nId
	            strCurrentItemText = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Wallpaper].tCurrentItem.strName
	            self:ShowItems(self.wndListView, self.tRemodelVendorWallpaperList, idPruneItem)
      	  end
        elseif nSel == 3 then
            self.tRemodelEntryList = HousingLib.GetRemodelEntryList(strSearchText)
            if self.tRemodelEntryList ~= nil then
	            table.sort(self.tRemodelEntryList, function(a,b)	return (a.strName < b.strName)	end)
	            
	            idPruneItem = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Entry].tCurrentItem.nId
	            strCurrentItemText = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Entry].tCurrentItem.strName
	            self:ShowItems(self.wndListView, self.tRemodelEntryList, idPruneItem)
	        end
        elseif nSel == 4 then
            self.tRemodelDoorList = HousingLib.GetRemodelDoorList(strSearchText)
            if self.tRemodelDoorList ~= nil then
	            table.sort(self.tRemodelDoorList, function(a,b)	return (a.strName < b.strName)	end)
	            
	            idPruneItem = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Door].tCurrentItem.nId
	            strCurrentItemText = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Door].tCurrentItem.strName
	            self:ShowItems(self.wndListView, self.tRemodelDoorList, idPruneItem)
	        end
        elseif nSel == 5 then
            self.tRemodelVendorWallpaperList = HousingLib.GetRemodelSkyExteriorList(strSearchText)
            if self.tRemodelVendorWallpaperList ~= nil then
	            table.sort(self.tRemodelVendorWallpaperList, function(a,b)	return (a.strName < b.strName)	end)
	            
	            idPruneItem = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Sky].tCurrentItem.nId
	            strCurrentItemText = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Sky].tCurrentItem.strName
	            self:ShowItems(self.wndListView, self.tRemodelVendorWallpaperList, idPruneItem)
	        end
        elseif nSel == 6 then
            self.tRemodelVendorWallpaperList = HousingLib.GetRemodelMusicExteriorList(strSearchText)
            if self.tRemodelVendorWallpaperList then
	            table.sort(self.tRemodelVendorWallpaperList, function(a,b)	return (a.strName < b.strName)	end)
	            
	            idPruneItem = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Music].tCurrentItem.nId
	            strCurrentItemText = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Music].tCurrentItem.strName
	            self:ShowItems(self.wndListView, self.tRemodelVendorWallpaperList, idPruneItem)
	        end
        else
            self.tRemodelVendorWallpaperList = HousingLib.GetRemodelGroundList(strSearchText)
            if self.tRemodelVendorWallpaperList then
	            table.sort(self.tRemodelVendorWallpaperList, function(a,b)	return (a.strName < b.strName)	end)
	            
	            idPruneItem = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Ground].tCurrentItem.nId
	            strCurrentItemText = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Ground].tCurrentItem.strName
	            self:ShowItems(self.wndListView, self.tRemodelVendorWallpaperList, idPruneItem)	
	        end
        end
	else
        local nSel = self.wndCommunityRemodelHeaderFrame:GetRadioSel("CommunityRemodelTab")
        if nSel < 1 or nSel > #self.tCommunityRemodelTabs then
            return
        end

		self.wndRemodel:FindChild("BGArt:PropertyNameDisplay"):SetText(Apollo.GetString("HousingRemodel_RemodelCommunity"))
        self.tCommunityRemodelTabs[nSel]:SetTextColor(kcrWhite)
        self.wndListView:SetSortColumn(1, true)
        
        local wndHideClutterBtn = self.wndCommunityPreviewWindow:FindChild("HideGroundClutterBtn")
        wndHideClutterBtn:SetCheck(self.rResidence:IsGroundClutterHidden())

		local wndHideSkyplotsBtn = self.wndCommunityPreviewWindow:FindChild("HideSkyplotsBtn")
        wndHideSkyplotsBtn:SetCheck(self.rResidence:AreSkyplotsHidden())

        local strCurrentItemText
        if nSel == 1 then
            self.tRemodelVendorWallpaperList = HousingLib.GetRemodelSkyExteriorList(strSearchText)
            if  self.tRemodelVendorWallpaperList ~= nil then
	            table.sort(self.tRemodelVendorWallpaperList, function(a,b)	return (a.strName < b.strName)	end)
	            
	            idPruneItem = self.luaCommunityRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Sky].tCurrentItem.nId
	            strCurrentItemText = self.luaCommunityRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Sky].tCurrentItem.strName
	            self:ShowItems(self.wndListView, self.tRemodelVendorWallpaperList, idPruneItem)
	        end
        elseif nSel == 2 then
            self.tRemodelVendorWallpaperList = HousingLib.GetRemodelMusicExteriorList(strSearchText)
            if self.tRemodelVendorWallpaperList ~= nil then
	            table.sort(self.tRemodelVendorWallpaperList, function(a,b)	return (a.strName < b.strName)	end)
	            
	            idPruneItem = self.luaCommunityRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Music].tCurrentItem.nId
	            strCurrentItemText = self.luaCommunityRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Music].tCurrentItem.strName
	            self:ShowItems(self.wndListView, self.tRemodelVendorWallpaperList, idPruneItem)
	        end
        else
            self.tRemodelVendorWallpaperList = HousingLib.GetRemodelGroundList(strSearchText)
            if self.tRemodelVendorWallpaperList ~= nil then
	            table.sort(self.tRemodelVendorWallpaperList, function(a,b)	return (a.strName < b.strName)	end)
	            
	            idPruneItem = self.luaCommunityRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Ground].tCurrentItem.nId
	            strCurrentItemText = self.luaCommunityRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeCommunity.Ground].tCurrentItem.strName
	            self:ShowItems(self.wndListView, self.tRemodelVendorWallpaperList, idPruneItem)	
	        end
        end
	end

	if strCurrentItemText ~= nil then
		self:SetRemodelCurrentDetails(strCurrentItemText)
	else
		self:SetRemodelCurrentDetails(nil)
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnSearchChanged(wndControl, wndHandler)
    if self.wndSearchWindow:GetText() ~= "" then
        self.wndClearSearchBtn:Show(true)
	else
        self.wndClearSearchBtn:Show(false)
    end

    if self.bPlayerIsInside then
        self:ShowAppropriateIntRemodelTab()
    else
        self:ShowAppropriateExtRemodelTab()
    end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnClearSearchText(wndControl, wndHandler)
 	self.wndSearchWindow:SetText("")
	self.wndClearSearchBtn:Show(false)
	self.wndSearchWindow:ClearFocus()
    self:OnSearchChanged(wndControl, wndHandler)
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:ShowItems(wndListControl, tItemList, idPrune)
	if wndListControl ~= nil then
		wndListControl:DeleteAll()
	end

	if tItemList ~= nil then
		self.tItemList = tItemList
		-- determine where we start and end based on page size
		local crRed = CColor.new(1.0, 0, 0, 1.0)
		local crWhite = CColor.new(1.0, 1.0, 1.0, 1.0)
		local crGrey = CColor.new(0.2,0.2,0.2,1.0)

	    -- populate the buttons with the item data
		for idx = 1, #tItemList do
			local tItemData = tItemList[idx]
			-- AddRow implicitly works on column one.  Every column can have it's own hidden data associated with it!
			local bPruned = false
			local nRow
			if idPrune ~= tItemData.nId then
				nRow = wndListControl:AddRow("" .. tItemData.strName, "", tItemData.nId)
			else
				if self.bPlayerIsInside then
					nRow = wndListControl:AddRow("" .. String_GetWeaselString(Apollo.GetString("HousingRemodel_CurrentEffect"), tItemData.strName), "", tItemData.nId)
					bPruned = true
					self.idIntPruneItem	= tItemData.nId
				else
					nRow = wndListControl:AddRow("" .. String_GetWeaselString(Apollo.GetString("HousingRemodel_CurrentEffect"), tItemData.strName), "", tItemData.nId)
					bPruned = true
					wndListControl:EnableRow(nRow, false)
				end
			end

			local strDoc = Apollo.GetString("CRB_Free_pull")

			local eCurrencyType = tItemData["eCurrencyType"]
			local monCash = GameLib.GetPlayerCurrency(eCurrencyType):GetAmount()

			self.wndCashRemodel:SetMoneySystem(eCurrencyType)

			if tItemData.nCost > monCash then
				strDoc = self.wndCashRemodel:GetAMLDocForAmount(tItemData.nCost, true, crRed)
			elseif bPruned == true then
				strDoc = self.wndCashRemodel:GetAMLDocForAmount(0, true, crGrey)
			else
				strDoc = self.wndCashRemodel:GetAMLDocForAmount(tItemData.nCost, true, crWhite)
			end

			if tItemData.kUpsellLink ~= nil and tItemData.kUpsellLink ~= 0 then
				wndListControl:SetCellImage(idx, 2, "BK3:UI_BK3_PremiumCalloutBanner_05")
			else
				wndListControl:SetCellData(idx, 2, "", "", tItemData.nCost)
				wndListControl:SetCellDoc(idx, 2, strDoc)
			end
		end

        self.wndCashRemodel:SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
	    self.wndCashRemodel:SetAmount(GameLib.GetPlayerCurrency(), true)
		self:SelectItemByUniqueId(wndListControl, tItemList)
	end
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:SelectItemByUniqueId(wndListControl, tItemList)
	local nCount = wndListControl:GetRowCount()
	for idx = 1, nCount do
		local idx = wndListControl:GetCellData(idx, 1)
		if idx == self.idUniqueItem then
			wndListControl:SetCurrentRow(idx)
			wndListControl:EnsureCellVisible(idx, 1)

			local nAmount = wndListControl:GetCellData(idx, 2)
			if nAmount then
			    local tItemData = self:GetItem(idx, tItemList)
			    self.wndCashRemodel:SetMoneySystem(tItemData.eCurrencyType)
				self.wndCashRemodel:SetAmount(nAmount)
			end
			return
		end
	end

	self.idUniqueItem = nil
	--self.landscapeProposedControl:clear()
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:GetItem(idItem, tItemList)
	if tItemList then
		for idx = 1, #tItemList do
			tItemData = tItemList[idx]
			if tItemData.nId == idItem then
				return tItemData
			end
		end
	end
	return nil
end

---------------------------------------------------------------------------------------------------
function HousingRemodel:OnRemoveRoofUpgrade()
    self.luaExtRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeExterior.Roof)
    self.wndSearchWindow:ClearFocus()
    local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
    if nSel == 1 then
        self.wndListView:SetCurrentRow(0)
    end
end

function HousingRemodel:OnRemoveWallUpgrade()
	self.luaExtRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeExterior.Wallpaper)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
	if nSel == 2 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveEntryUpgrade()
	self.luaExtRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeExterior.Entry)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
	if nSel == 3 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveDoorUpgrade()
	self.luaExtRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeExterior.Door)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
	if nSel == 4 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveSkyUpgrade()
    if self.rResidence and self.rResidence:IsCommunityResidence() then
        self.luaCommunityRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeCommunity.Sky)
        self.wndSearchWindow:ClearFocus()
        local nSel =self.wndCommunityRemodelHeaderFrame:GetRadioSel("CommunityRemodelTab")
        if nSel == 1 then
            self.wndListView:SetCurrentRow(0)
        end
	else
        self.luaExtRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeExterior.Sky)
        self.wndSearchWindow:ClearFocus()
        local nSel =self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
        if nSel == 5 then
        self.wndListView:SetCurrentRow(0)
        end
	end
end

function HousingRemodel:OnRemoveExtMusicUpgrade()
    if self.rResidence and self.rResidence:IsCommunityResidence() then
        self.luaCommunityRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeCommunity.Music)
        self.wndSearchWindow:ClearFocus()
        local nSel =self.wndCommunityRemodelHeaderFrame:GetRadioSel("CommunityRemodelTab")
        if nSel == 2 then
            self.wndListView:SetCurrentRow(0)
        end
    else
        self.luaExtRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeExterior.Music)
        self.wndSearchWindow:ClearFocus()
        local nSel =self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
        if nSel == 6 then
            self.wndListView:SetCurrentRow(0)
        end
    end    
end

function HousingRemodel:OnRemoveGroundUpgrade()
    if self.rResidence and self.rResidence:IsCommunityResidence() then
        self.luaCommunityRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeCommunity.Ground)
        self.wndSearchWindow:ClearFocus()
        local nSel =self.wndCommunityRemodelHeaderFrame:GetRadioSel("CommunityRemodelTab")
        if nSel == 3 then
            self.wndListView:SetCurrentRow(0)
        end
    else
        self.luaExtRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeExterior.Ground)
        self.wndSearchWindow:ClearFocus()
        local nSel = self.wndExtRemodelHeaderFrame:GetRadioSel("ExtRemodelTab")
        if nSel == 7 then
            self.wndListView:SetCurrentRow(0)
        end
	end
end

function HousingRemodel:ResetExtRemodelPreview(bOmitSound)
	self.wndSearchWindow:ClearFocus()
	self.wndListView:SetCurrentRow(0)
	if bOmitSound ~= true then
		Sound.Play(Sound.PlayUIHousingItemCancelled)
	end

	self.luaExtRemodelPreviewControl:OnAllChoicesCanceled(false)
	self.luaCommunityRemodelPreviewControl:OnAllChoicesCanceled(false)
end

function HousingRemodel:OnHideClutterOnCheck(wndControl, wndHandler, iButton, nX, nY) 
    self.wndSearchWindow:ClearFocus()
	if self.rResidence then
		self.rResidence:SetGroundClutterHidden(wndControl:IsChecked())
	end
end

function HousingRemodel:OnHideSkyplotsOnCheck(wndControl, wndHandler, iButton, nX, nY)
    self.wndSearchWindow:ClearFocus()
	if self.rResidence then
		self.rResidence:SetSkyplotsHidden(wndControl:IsChecked())
	end
end

function HousingRemodel:OnComponentPreviewOnCheck(wndControl, wndHandler, iButton, nX, nY)
	self.wndSearchWindow:ClearFocus()

	if self.bPlayerIsInside then
        -- interior stuff
        if wndControl == self.wndRemodel:FindChild("CeilingPreviewBtn") then
            self.luaIntRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeInterior.Ceiling)
        elseif wndControl == self.wndRemodel:FindChild("IntWallpaperPreviewBtn") then
            self.luaIntRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeInterior.Wallpaper)
        elseif wndControl == self.wndRemodel:FindChild("FloorPreviewBtn") then
            self.luaIntRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeInterior.Floor)
        elseif wndControl == self.wndRemodel:FindChild("TrimPreviewBtn") then
            self.luaIntRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeInterior.Trim)
        elseif wndControl == self.wndRemodel:FindChild("LightingPreviewBtn") then
            self.luaIntRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeInterior.Lighting)
        elseif wndControl == self.wndRemodel:FindChild("IntMusicPreviewBtn") then
            self.luaIntRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeInterior.Music)
        end
	elseif self.rResidence ~= nil and not self.rResidence:IsCommunityResidence() then
        if wndControl == self.wndRemodel:FindChild("RoofPreviewBtn") then
            self.luaExtRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeExterior.Roof)
        elseif wndControl == self.wndRemodel:FindChild("WallpaperPreviewBtn") then
            self.luaExtRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeExterior.Wallpaper)
        elseif wndControl == self.wndRemodel:FindChild("EntryPreviewBtn") then
            self.luaExtRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeExterior.Entry)
        elseif wndControl == self.wndRemodel:FindChild("DoorPreviewBtn") then
            self.luaExtRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeExterior.Door)
        elseif wndControl == self.wndRemodel:FindChild("SkyPreviewBtn") then
            self.luaExtRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeExterior.Sky)
        elseif wndControl == self.wndRemodel:FindChild("MusicPreviewBtn") then
            self.luaExtRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeExterior.Music)
        elseif wndControl == self.wndRemodel:FindChild("GroundPreviewBtn") then  
            self.luaExtRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeExterior.Ground)  
        end
    else
        if wndControl == self.wndRemodel:FindChild("CommunitySkyPreviewBtn") then
            self.luaCommunityRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeCommunity.Sky)
        elseif wndControl == self.wndRemodel:FindChild("CommunityMusicPreviewBtn") then
            self.luaCommunityRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeCommunity.Music)
        elseif wndControl == self.wndRemodel:FindChild("CommunityGroundPreviewBtn") then  
            self.luaCommunityRemodelPreviewControl:OnPreviewCheck(HousingLib.RemodelOptionTypeCommunity.Ground)  
        end
	end

end

---------------------------------------------------------------------------------------------------

function HousingRemodel:OnRemoveCeilingUpgrade()
	self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Ceiling)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel == 1 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveTrimUpgrade()
	self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Trim)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel == 2 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveIntWallpaperUpgrade()
	self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Wallpaper)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel == 3 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveFloorUpgrade()
	self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Floor)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel == 4 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveLightingUpgrade()
	self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Lighting)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel == 5 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveMusicUpgrade()
	self.luaIntRemodelPreviewControl:OnChoiceCanceled(HousingLib.RemodelOptionTypeInterior.Music)
	self.wndSearchWindow:ClearFocus()
	local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
	if nSel == 6 then
	    self.wndListView:SetCurrentRow(0)
	end
end

function HousingRemodel:OnRemoveIntOption()
    self.wndSearchWindow:ClearFocus()
    local nSel = self.wndIntRemodelHeaderFrame:GetRadioSel("IntRemodelTab")
    local eType = 0

    if nSel == 1 then --ceiling
        eType = HousingLib.RemodelOptionTypeInterior.Ceiling
    elseif nSel == 2 then -- trim
        eType = HousingLib.RemodelOptionTypeInterior.Trim
    elseif nSel == 3 then -- walls
        eType = HousingLib.RemodelOptionTypeInterior.Wallpaper
    elseif nSel == 4 then -- floor
        eType = HousingLib.RemodelOptionTypeInterior.Floor
    elseif nSel == 5 then -- lighting
        eType = HousingLib.RemodelOptionTypeInterior.Lighting
    elseif nSel == 6 then -- music
        eType = HousingLib.RemodelOptionTypeInterior.Music
    end

	if self.rResidence then
		self.rResidence:RemoveInteriorWallpaper(eType)
	end
    self.luaIntRemodelPreviewControl:OnResidenceChange(gidZone)
end

function HousingRemodel:ResetIntRemodelPreview()
	self.wndListView:SetCurrentRow(0)
	self.luaIntRemodelPreviewControl:OnAllChoicesCanceled(false)
end

function HousingRemodel:PurchaseIntRemodelChanges()
	self.luaIntRemodelPreviewControl:PurchaseRemodelChanges()
end

function HousingRemodel:OnCeilingUpsellBtn()
	local idUpsellLink = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Ceiling].idUpsellLink
	StorefrontLib.OpenLink(idUpsellLink)
end

function HousingRemodel:OnTrimUpsellBtn()
	local idUpsellLink = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Trim].idUpsellLink
	StorefrontLib.OpenLink(idUpsellLink)
end

function HousingRemodel:OnIntWallpaperUpsellBtn()
	local idUpsellLink = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Wallpaper].idUpsellLink
	StorefrontLib.OpenLink(idUpsellLink)
end

function HousingRemodel:OnFloorUpsellBtn()
	local idUpsellLink = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Floor].idUpsellLink
	StorefrontLib.OpenLink(idUpsellLink)
end

function HousingRemodel:OnLightingUpsellBtn()
	local idUpsellLink = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Lighting].idUpsellLink
	StorefrontLib.OpenLink(idUpsellLink)
end

function HousingRemodel:OnIntMusicUpsellBtn()
	local idUpsellLink = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeInterior.Music].idUpsellLink
	StorefrontLib.OpenLink(idUpsellLink)
end

function HousingRemodel:OnWallpaperUpsellBtn()
	local idUpsellLink = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Wallpaper].idUpsellLink
	StorefrontLib.OpenLink(idUpsellLink)
end

function HousingRemodel:OnSkyUpsellBtn()
	local idUpsellLink = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Sky].idUpsellLink
	StorefrontLib.OpenLink(idUpsellLink)
end

function HousingRemodel:OnMusicUpsellBtn()
	local idUpsellLink = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Music].idUpsellLink
	StorefrontLib.OpenLink(idUpsellLink)
end

function HousingRemodel:OnGroundUpsellBtn()
	local idUpsellLink = self.luaExtRemodelPreviewControl.tRemodelPreviewItems[HousingLib.RemodelOptionTypeExterior.Ground].idUpsellLink
	StorefrontLib.OpenLink(idUpsellLink)
end

function HousingRemodel:OnResidenceDecorChanged()
    if self.bPlayerIsInside then
        self.luaIntRemodelPreviewControl:OnResidenceChange(gidZone)
        self:ShowAppropriateRemodelTab()

        -- give the server enough time to process the purchase request, then update the UI
        Apollo.StartTimer("HousingIntRemodelTimer")
    else
        self.luaExtRemodelPreviewControl:OnResidenceChange(gidZone)
    end
end

function HousingRemodel:OnHousingResult(strName, eResult)
	if self.wndRemodel:IsVisible() then
	    if self.playerIsInside then
            self:ResetIntRemodelPreview(false)
        else
            self:ResetExtRemodelPreview(false)
        end
    end
end

function HousingRemodel:OnPlayerCurrencyChanged()
	if self.wndRemodel then
		local eCurrencyType = self.wndCashRemodel:GetCurrency():GetMoneyType()
		local nCurrencyAmount = GameLib.GetPlayerCurrency(eCurrencyType)
		self.wndCashRemodel:SetAmount(nCurrencyAmount, false)
	end
end

function HousingRemodel:OnBuildStarted(plotIndex)
    if plotIndex == 1 and self.wndRemodel:IsVisible() then
        self:OnCloseHousingRemodelWindow()
    end
end

---------------------------------------------------------------------------------------------------
-- PropertySettingsPanel Functions
---------------------------------------------------------------------------------------------------

function HousingRemodel:OnPropertySettingsBtn(wndHandler, wndControl, eMouseButton)
	if wndHandler:GetId() ~= wndControl:GetId() or self.rResidence == nil then
		return
	end
	
	if self.wndPropertySettingsPopup:IsShown() then
		self.wndPropertySettingsPopup:Close()
	else
		self.wndPropertySettingsPopup:FindChild("ResidenceName"):SetText(self.rResidence:GetPropertyName())

		local split = self.rResidence:GetNeighborHarvestSplit()+1
		self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow"):SetRadioSel("NeighborHarvestBtn", split)

		local wndDropdown = self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow")
		self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownLabel"):SetText(wndDropdown:FindChild("NeighborHarvestBtn"..split):GetText())
		
		local kGardenSplit = self.rResidence:GetNeighborGardenSplit()+1
		self.wndPropertySettingsPopup:FindChild("GardenSharingDropdownWindow"):SetRadioSel("NeighborHarvestBtn", kGardenSplit)

		local wndDropdown = self.wndPropertySettingsPopup:FindChild("GardenSharingDropdownWindow")
		self.wndPropertySettingsPopup:FindChild("GardenSharingDropdownLabel"):SetText(wndDropdown:FindChild("NeighborHarvestBtn"..kGardenSplit):GetText())

		local kPrivacyLevel = self.rResidence:GetResidencePrivacyLevel()+1
		self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow"):SetRadioSel("PermissionsSettingsBtn", kPrivacyLevel)

		local wndDropdown = self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow")
		self.wndPropertySettingsPopup:FindChild("PermissionsDropdownLabel"):SetText(wndDropdown:FindChild("PermissionsSettingsBtn"..kPrivacyLevel):GetText())

		self.wndPropertySettingsPopup:Invoke()
	end
end

function HousingRemodel:OnTeleportHomeBtn(wndHandler, wndControl)
	HousingLib.RequestTakeMeHome()
end

function HousingRemodel:OnRandomBtn(wndHandler, wndControl)
	if self.wndRandomList:IsShown() then
		self.wndRandomList:Close()
	else
		self:ShowRandomList()
	end
end

function HousingRemodel:OnCommunitySettingsBtn(wndHandler, wndControl, eMouseButton)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	
	if self.wndCommunitySettingsPopup:IsShown() then
		self.wndCommunitySettingsPopup:Close()
	else
	    self.wndCommunitySettingsPopup:Invoke()
	
		self.wndCommunitySettingsPopup:FindChild("RenameBtn"):Show(HousingLib.CanRenameCommunity())
	
		local ePrivacyLevel = HousingLib.GetCommunityPrivacyLevel()
		local strPrivacyLevel = ""
		if ePrivacyLevel == HousingLib.ResidencePrivacyLevel.Private then
			strPrivacyLevel = Apollo.GetString("HousingRemodel_Private")
		else
			strPrivacyLevel = Apollo.GetString("HousingRemodel_Public")
		end
		
		if HousingLib.CanSetCommunityPrivacyLevel() then
			self.wndCommunitySettingsPopup:FindChild("PermissionsDropdownLabel"):SetText(strPrivacyLevel)
			self.wndCommunitySettingsPopup:FindChild("PermissionsDropdownBtn"):Show(true)
			self.wndCommunitySettingsPopup:FindChild("PermissionText"):Show(false)
		else
			self.wndCommunitySettingsPopup:FindChild("PermissionText"):SetText(strPrivacyLevel)
			self.wndCommunitySettingsPopup:FindChild("PermissionText"):Show(true)
			self.wndCommunitySettingsPopup:FindChild("PermissionsDropdownBtn"):Show(false)
		end
	
		self.wndCommunitySettingsPopup:FindChild("EvictResidentBtn"):Enable(false)
		self.wndCommunitySettingsPopup:FindChild("PropertyFrame"):SetRadioSel("PlotGroup", 0)
		self.wndCommunitySettingsPopup:FindChild("ReservePlotBtn"):FindChild("ConfirmWindow"):Show(false)
		self.wndCommunitySettingsPopup:FindChild("EvictResidentBtn"):FindChild("ConfirmWindow"):Show(false)
		self.wndCommunitySettingsPopup:FindChild("PlaceBtn"):FindChild("ConfirmWindow"):Show(false)
		self.wndCommunitySettingsPopup:FindChild("RemoveBtn"):FindChild("ConfirmWindow"):Show(false)
		self.wndCommunitySettingsPopup:FindChild("VisitCommunityBtn"):FindChild("ConfirmWindow"):Show(false)
		
		if HousingLib.IsOnMyCommunity() then
			self.wndCommunitySettingsPopup:FindChild("VisitCommunityBtn"):Enable(false)
			self.wndCommunitySettingsPopup:FindChild("VisitCommunityBtn"):SetTooltip(Apollo.GetString("Housing_AlreadyOnCommunity"))
		else
			self.wndCommunitySettingsPopup:FindChild("VisitCommunityBtn"):Enable(true)
			self.wndCommunitySettingsPopup:FindChild("VisitCommunityBtn"):SetTooltip(Apollo.GetString("Housing_VisitCommunityTooltip"))
		end
		
		for ix = 1, 5 do
			local wndPlotButton = self.wndCommunitySettingsPopup:FindChild("PropertyFrame"):FindChild("Plot"..ix)
			wndPlotButton:SetData(nil)
			wndPlotButton:FindChild("OccupiedSprite."..ix):Show(false)
			wndPlotButton:FindChild("ReservedSprite."..ix):Show(false)
			wndPlotButton:FindChild("OwnedOutline."..ix):Show(false)
		end
		local guildCurr = self.wndCommunitySettingsPopup:GetData()
		if guildCurr ~= nil then
			guildCurr:RequestMembers()
		end
		
		HousingLib.RequestCommunityPlacedResidencesList()
	end
end

function HousingRemodel:OnGuildChange()
	local arGuilds = GuildLib.GetGuilds()
	for key, guildCurr in pairs(arGuilds) do
		if guildCurr:GetType() == GuildLib.GuildType_Community then
			self.wndCommunitySettingsPopup:SetData(guildCurr)
			self.wndCommunitySettingsBtn:Show(true)
			guildCurr:RequestMembers()
			return
		end
	end
	
	self.wndCommunitySettingsBtn:Show(false)
	if self.wndCommunitySettingsPopup:IsShown() then
		self.wndCommunitySettingsPopup:Close()
	end
end

function HousingRemodel:OnGuildRoster(guildCurr, tRoster)
	if guildCurr and guildCurr:GetType() == GuildLib.GuildType_Community then
		self.guildCommunity = guildCurr
	else
		return
	end
	
	if self.wndCommunitySettingsPopup:IsShown() then
		self.wndCommunitySettingsPopup:FindChild("CommunityNameText"):SetText(guildCurr:GetName())
		local wndPropertyFrame = self.wndCommunitySettingsPopup:FindChild("PropertyFrame")

		for ix = 1, 5 do
			local wndPlotButton = wndPropertyFrame:FindChild("Plot"..ix)
			wndPlotButton:FindChild("ReservedSprite."..ix):Show(false)
			
			local tPlotInfo = wndPlotButton:GetData()
			if tPlotInfo then
				tPlotInfo.strReservedBy = nil
			end
		end
		
		for key, tCurr in pairs(tRoster) do
			if tCurr.nCommunityReservedPlotIndex >= 0 then
				local wndPlotBtn = wndPropertyFrame:FindChild("Plot"..(tCurr.nCommunityReservedPlotIndex + 1))
				if wndPlotBtn ~= nil then
					local tPlotInfo = wndPlotBtn:GetData()
					if not tPlotInfo then
						tPlotInfo = { strReservedBy = tCurr.strName }
						wndPlotBtn:SetData(tPlotInfo)
					else
						tPlotInfo.strReservedBy = tCurr.strName
					end

					wndPlotBtn:FindChild("OccupiedSprite."..(tCurr.nCommunityReservedPlotIndex + 1)):Show(true)
					wndPlotBtn:FindChild("ReservedSprite."..(tCurr.nCommunityReservedPlotIndex + 1)):Show(true)
					wndPlotBtn:SetTooltip(String_GetWeaselString(Apollo.GetString("Housing_PlotReservedByTooltip"), tCurr.strName))
					
					if tCurr ~= nil and tCurr.strName == GameLib.GetPlayerCharacterName() then
						wndPlotBtn:FindChild("OwnedOutline."..(tCurr.nCommunityReservedPlotIndex + 1)):Show(true)
					end
				end
			end
		end
		
		self:UpdateCommunityControls(wndPropertyFrame:GetRadioSelButton("PlotGroup"))
	end
	self.tRoster = tRoster
end

function HousingRemodel:OnGuildMemberChange(guildCurr, tMember)
	if guildCurr:GetType() ~= GuildLib.GuildType_Community then
		return
	end
	
	if not self.wndCommunitySettingsPopup:IsShown() then
		return
	end
	
	if not tMember then
		-- somebody left or was removed, refresh all plots
		guildCurr:RequestMembers()
		return
	end
	
	local wndPropertyFrame = self.wndCommunitySettingsPopup:FindChild("PropertyFrame")
	
	if tMember.nCommunityReservedPlotIndex >= 0 then
		local wndPlotBtn = wndPropertyFrame:FindChild("Plot"..(tMember.nCommunityReservedPlotIndex + 1))
		if wndPlotBtn ~= nil then
			local tPlotInfo = wndPlotBtn:GetData()
			if not tPlotInfo then
				tPlotInfo = { strReservedBy = tMember.strName }
				wndPlotBtn:SetData(tPlotInfo)
			else
				tPlotInfo.strReservedBy = tMember.strName
			end

			wndPlotBtn:FindChild("OccupiedSprite."..(tMember.nCommunityReservedPlotIndex + 1)):Show(true)
			wndPlotBtn:FindChild("ReservedSprite."..(tMember.nCommunityReservedPlotIndex + 1)):Show(true)
			wndPlotBtn:SetTooltip(String_GetWeaselString(Apollo.GetString("Housing_PlotReservedByTooltip"), tMember.strName))
			
			if tMember.strName == GameLib.GetPlayerCharacterName() then
				wndPlotBtn:FindChild("OwnedOutline."..(tMember.nCommunityReservedPlotIndex + 1)):Show(true)
			end
		end
	else
		for ix = 1, 5 do
			local wndPlotBtn = wndPropertyFrame:FindChild("Plot"..ix)
			
			local tPlotInfo = wndPlotBtn:GetData()
			if tPlotInfo and tPlotInfo.strReservedBy == tMember.strName then
				wndPlotBtn:FindChild("ReservedSprite."..ix):Show(false)
				wndPlotBtn:SetTooltip("")
				tPlotInfo.strReservedBy = nil
			end
		end
	end

	self:UpdateCommunityControls(wndPropertyFrame:GetRadioSelButton("PlotGroup"))
end

function HousingRemodel:OnGuildRankChange(guildCurr)
	if guildCurr:GetType() ~= GuildLib.GuildType_Community then
		return
	end
	
	if not self.wndCommunitySettingsPopup:IsShown() then
		return
	end
	
	guildCurr:RequestMembers()
end

function HousingRemodel:OnGuildNameChanged(guildCurr)
	if self.wndCommunitySettingsPopup:IsShown() then
		self.wndCommunitySettingsPopup:FindChild("CommunityNameText"):SetText(guildCurr:GetName())
	end
end

function HousingRemodel:OnCommunityPlacedResidenceList(tResidenceList)
	if not self.wndCommunitySettingsPopup:IsShown() then
		return
	end
	
	local wndPropertyFrame = self.wndCommunitySettingsPopup:FindChild("PropertyFrame")
	
	for ix = 1, 5 do
		local wndPlotButton = wndPropertyFrame:FindChild("Plot"..ix)
		wndPlotButton:FindChild("OccupiedSprite."..ix):Show(false)
		wndPlotButton:FindChild("OwnedOutline."..ix):Show(false)
		wndPlotButton:SetTooltip("")
		
		local tPlotInfo = wndPlotButton:GetData()
		if tPlotInfo then
			tPlotInfo.strOccupiedBy = nil
		end
	end
	
	for key, tCurr in pairs(tResidenceList) do
		local wndPlotBtn = wndPropertyFrame:FindChild("Plot"..(tCurr.nPropertyIndex + 1))
		if wndPlotBtn ~= nil then
			local tPlotInfo = wndPlotBtn:GetData()
			if not tPlotInfo then
				tPlotInfo = { strOccupiedBy = tCurr.strPlayerName }
				wndPlotBtn:SetData(tPlotInfo)
			else
				tPlotInfo.strOccupiedBy = tCurr.strPlayerName
			end

					
			wndPlotBtn:FindChild("OccupiedSprite."..(tCurr.nPropertyIndex + 1)):Show(true)
			wndPlotBtn:SetTooltip(String_GetWeaselString(Apollo.GetString("Housing_PlotOccupiedByTooltip"), tCurr.strPlayerName))
			
			if tCurr ~= nil and tCurr.strPlayerName == GameLib.GetPlayerCharacterName() then
				wndPlotBtn:FindChild("OwnedOutline."..(tCurr.nPropertyIndex + 1)):Show(true)
				
				if self.wndCommunitySettingsPopup:FindChild("PropertyFrame"):GetRadioSel("PlotGroup") == 0 then
					self.wndCommunitySettingsPopup:FindChild("PropertyFrame"):SetRadioSel("PlotGroup", tCurr.nPropertyIndex + 1)
				end
			end
		end
	end
	
	self:UpdateCommunityControls(wndPropertyFrame:GetRadioSelButton("PlotGroup"))
end

function HousingRemodel:OnHarvestSettingsDropdownBtnCheck( wndHandler, wndControl, eMouseButton )
    self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow"):Show(true)
end

function HousingRemodel:OnHarvestSettingsDropdownBtnUncheck( wndHandler, wndControl, eMouseButton )
    self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow"):Show(false)
end

function HousingRemodel:OnHarvestSettingsBtnChecked( wndHandler, wndControl, eMouseButton )
	if self.rResidence == nil then
		return
	end

	local split = self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow"):GetRadioSel("NeighborHarvestBtn")
	self.rResidence:SetNeighborHarvestSplit(split-1)

	local wndDropdown = self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow")
    self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownLabel"):SetText(wndDropdown:FindChild("NeighborHarvestBtn"..split):GetText())

	self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownBtn"):SetCheck(false)
	self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownWindow"):Show(false)
	return true
end

function HousingRemodel:OnGardenSettingsDropdownBtnCheck( wndHandler, wndControl, eMouseButton )
    self.wndPropertySettingsPopup:FindChild("GardenSharingDropdownWindow"):Show(true)
end

function HousingRemodel:OnGardenSettingsDropdownBtnUncheck( wndHandler, wndControl, eMouseButton )
    self.wndPropertySettingsPopup:FindChild("GardenSharingDropdownWindow"):Show(false)
end

function HousingRemodel:OnGardenSettingsBtnChecked( wndHandler, wndControl, eMouseButton )
	if self.rResidence == nil then
		return
	end

	local split = self.wndPropertySettingsPopup:FindChild("GardenSharingDropdownWindow"):GetRadioSel("NeighborHarvestBtn")
	self.rResidence:SetNeighborGardenSplit(split-1)

	local wndDropdown = self.wndPropertySettingsPopup:FindChild("GardenSharingDropdownWindow")
    self.wndPropertySettingsPopup:FindChild("GardenSharingDropdownLabel"):SetText(wndDropdown:FindChild("NeighborHarvestBtn"..split):GetText())

	self.wndPropertySettingsPopup:FindChild("GardenSharingDropdownBtn"):SetCheck(false)
	self.wndPropertySettingsPopup:FindChild("GardenSharingDropdownWindow"):Show(false)
	return true
end

function HousingRemodel:OnCategorySelectionClosed()
    self.wndPropertySettingsPopup:FindChild("HarvestSharingDropdownBtn"):SetCheck(false)
    self.wndPropertySettingsPopup:FindChild("GardenSharingDropdownBtn"):SetCheck(false)
    self.wndPropertySettingsPopup:FindChild("PermissionsDropdownBtn"):SetCheck(false)
end

function HousingRemodel:OnPermissionsDropdownBtnCheck( wndHandler, wndControl, eMouseButton )
    self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow"):Show(true)
end

function HousingRemodel:OnPermissionsDropdownBtnUncheck( wndHandler, wndControl, eMouseButton )
    self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow"):Show(false)
end

function HousingRemodel:OnCommunityPermissionsBtnCheck( wndHandler, wndControl, eMouseButton )
	self.wndCommunitySettingsPopup:FindChild("PermissionsDropdownWindow"):Show(true)
end

function HousingRemodel:OnCommunityPermissionsBtnUncheck( wndHandler, wndControl, eMouseButton )
	self.wndCommunitySettingsPopup:FindChild("PermissionsDropdownWindow"):Show(false)
end

function HousingRemodel:OnCommunityPermissionSelectionClosed( wndHandler, wndControl, eMouseButton )
	self.wndCommunitySettingsPopup:FindChild("PermissionsDropdownBtn"):SetCheck(false)
end

function HousingRemodel:OnCommunityPermissionsBtnChecked( wndHandler, wndControl, eMouseButton )
	local wndDropdown = self.wndCommunitySettingsPopup:FindChild("PermissionsDropdownWindow")
	local nPrivacyLevel = wndDropdown:GetRadioSel("PermissionsSettingsBtn")
	local strButtonLabel = ""
	if nPrivacyLevel == 2 then
		HousingLib.SetCommunityPrivacyLevel(HousingLib.ResidencePrivacyLevel.Private)
		strButtonLabel = wndDropdown:FindChild("PermissionsSettingsBtnPrivate"):GetText()
	else
		HousingLib.SetCommunityPrivacyLevel(HousingLib.ResidencePrivacyLevel.Public)
		strButtonLabel = wndDropdown:FindChild("PermissionsSettingsBtnPublic"):GetText()
	end

    self.wndCommunitySettingsPopup:FindChild("PermissionsDropdownLabel"):SetText(strButtonLabel)
	self.wndCommunitySettingsPopup:FindChild("PermissionsDropdownBtn"):SetCheck(false)
	wndDropdown:Show(false)
end

function HousingRemodel:OnPermissionsBtnChecked( wndHandler, wndControl, eMouseButton )
	if self.rResidence == nil then
		return
	end

	local kPrivacyLevel = self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow"):GetRadioSel("PermissionsSettingsBtn")
	self.rResidence:SetResidencePrivacyLevel(kPrivacyLevel-1)

	local wndDropdown = self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow")
    self.wndPropertySettingsPopup:FindChild("PermissionsDropdownLabel"):SetText(wndDropdown:FindChild("PermissionsSettingsBtn"..kPrivacyLevel):GetText())

	self.wndPropertySettingsPopup:FindChild("PermissionsDropdownBtn"):SetCheck(false)
	self.wndPropertySettingsPopup:FindChild("PermissionsDropdownWindow"):Show(false)
	
	return true
end

function HousingRemodel:OnSettingsCancel( wndHandler, wndControl, eMouseButton )
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	self.wndPropertySettingsPopup:Close()
end

function HousingRemodel:OnCommunitySettingsCancel(wndHandler, wndControl, eMouseButton )
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	self.wndCommunitySettingsPopup:Close()
end

function HousingRemodel:OnCommunityVisitConfirmBtn(wndHandler, wndControl, eMouseButton )
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

    HousingLib.RequestCommunityVisit()
	self.wndCommunitySettingsPopup:Close()
end

function HousingRemodel:OnCommunityVisitSelectedConfirmBtn(wndHandler, wndControl, eMouseButton )
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	
	local iPropertyIndex = tonumber(self.wndCommunitySettingsPopup:FindChild("PropertyFrame"):GetRadioSel("PlotGroup"))

    HousingLib.RequestCommunityPlacement(iPropertyIndex)
	self.wndCommunitySettingsPopup:FindChild("PlaceBtn"):FindChild("ConfirmWindow"):Show(false)
end

function HousingRemodel:OnPropertySelectionSettings(wndHandler, wndControl, eMouseButton )
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	
	self:UpdateCommunityControls(wndControl)
end

function HousingRemodel:UpdateCommunityControls(wndControl)
	if not self.wndCommunitySettingsPopup:IsShown() then
		return
	end
	
	local wndEvictBtn = self.wndCommunitySettingsPopup:FindChild("EvictResidentBtn")
	local wndReserveBtn = self.wndCommunitySettingsPopup:FindChild("ReservePlotBtn")
	local wndPlaceBtn = self.wndCommunitySettingsPopup:FindChild("PlaceBtn")
	local wndRemoveBtn = self.wndCommunitySettingsPopup:FindChild("RemoveBtn")
	
	local bIsReserved = false
	local bCanReserve = false
	local bCanRevoke = false
	local bCanPlace = true
	local bIsPlaced = false
	local tReservation = HousingLib.GetReservedCommunityPlotIndex()
	
	local tPlotInfo = wndControl and wndControl:GetData() or nil
	if tPlotInfo ~= nil then
		if tPlotInfo.strReservedBy ~= nil then
			bIsReserved = true
			bCanReserve = false
			bCanPlace = false
			
			if tPlotInfo.strReservedBy == GameLib.GetPlayerCharacterName() or HousingLib.CanRevokeCommunityPlotReservations() then
				bCanRevoke = true
				bIsPlaced = true
			end
		end
		
		if tPlotInfo.strOccupiedBy ~= nil then
			bCanPlace = false
			
			if tPlotInfo.strOccupiedBy == GameLib.GetPlayerCharacterName() then
				bCanReserve = not bIsReserved
				bIsPlaced = true
			end
		end
	else
		if tReservation and tReservation.bHasReservation then
			bCanReserve = false
			bCanPlace = false
		else
			bCanReserve = HousingLib.CanReserveCommunityPlot()
		end
	end
	
	wndEvictBtn:Show(bIsReserved)
	wndReserveBtn:Show(not bIsReserved)
	
	wndEvictBtn:Enable(bCanRevoke)
	wndReserveBtn:Enable(bCanReserve)
	
	wndPlaceBtn:Show(not bIsPlaced)
	wndRemoveBtn:Show(bIsPlaced)

	wndPlaceBtn:Enable(bCanPlace)
	wndRemoveBtn:Enable(bIsPlaced and not bIsReserved)
	
	if bIsReserved then
		if bCanRevoke then
			wndEvictBtn:SetTooltip(Apollo.GetString("Housing_CommunityRevokeTooltip"))
		else
			wndEvictBtn:SetTooltip(Apollo.GetString("Housing_CommunityCannotRevokeTooltip"))
		end
	else
		if bCanReserve then
			wndReserveBtn:SetTooltip(Apollo.GetString("Housing_CommunityReserveTooltip"))
		elseif tReservation and tReservation.bHasReservation then
			wndReserveBtn:SetTooltip(Apollo.GetString("Housing_CommunityAlreadyReserved"))
		else
			wndReserveBtn:SetTooltip(Apollo.GetString("Housing_CommunityCannotReserve"))
		end
	end
	
	if bCanPlace then
		wndPlaceBtn:SetTooltip(Apollo.GetString("Housing_CommunityPlaceTooltip"))
	elseif tPlotInfo and tPlotInfo.strOccupiedBy == GameLib.GetPlayerCharacterName() then
		wndPlaceBtn:SetTooltip(Apollo.GetString("Housing_CommunityAlreadyInPlot"))
	elseif tReservation and tReservation.bHasReservation then
		wndPlaceBtn:SetTooltip(Apollo.GetString("Housing_CommunityCannotPlace_Reserved"))
	else
		wndPlaceBtn:SetTooltip(Apollo.GetString("Housing_CommunityCannotPlace_Occupied"))
	end
end

function HousingRemodel:OnReservePlotConfirmBtn(wndHandler, wndControl, eMouseButton )
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	
	local iPropertyIndex = tonumber(self.wndCommunitySettingsPopup:FindChild("PropertyFrame"):GetRadioSel("PlotGroup"))
	
	HousingLib.ReserveCommunityPlot(iPropertyIndex-1)
	self.wndCommunitySettingsPopup:FindChild("ReservePlotBtn"):FindChild("ConfirmWindow"):Show(false)
end

function HousingRemodel:OnRevokePlotConfirmBtn(wndHandler, wndControl, eMouseButton )
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	
	local iPropertyIndex = tonumber(self.wndCommunitySettingsPopup:FindChild("PropertyFrame"):GetRadioSel("PlotGroup"))
	local wndButton = self.wndCommunitySettingsPopup:FindChild("PropertyFrame"):FindChild("Plot"..iPropertyIndex)
	if wndButton ~= nil then
		local tMember = wndButton:GetData()
		if tMember ~= nil and tMember.strReservedBy == GameLib.GetPlayerCharacterName() then
			HousingLib.ReserveCommunityPlot(-1)
		elseif tMember ~= nil then
			HousingLib.RemoveCommunityPlotReservation(tMember.strReservedBy)
		end
	end
	
	self.wndCommunitySettingsPopup:FindChild("EvictResidentBtn"):FindChild("ConfirmWindow"):Show(false)
end

function HousingRemodel:OnCommunityRemoveResidenceConfirmBtn(wndHandler, wndControl, eMouseButton)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	
	HousingLib.RequestCommunityRemoveResidence()
	self.wndCommunitySettingsPopup:Close()
end

-----------------------------------------------------------------------------------------------
-- HousingDecorate Category Dropdown functions
-----------------------------------------------------------------------------------------------
-- populate item list
--[[function HousingRemodel:PopulateCategoryList()
	-- make sure the item list is empty to start with
	self:DestroyCategoryList()

	sortl, sortt, sortr, sortb = self.winSortByList:GetAnchorOffsets()

    -- add 5 items
	for i = 1,5 do
       -- self:AddCategoryItem(i)
        itemHeight = self.tCategoryItems[i]:GetHeight()
	    self.winSortByList:SetAnchorOffsets(sortl, sortt, sortr, sortt+i*itemHeight)
	end

	-- now all the iteam are added, call ArrangeChildrenVert to list out the list items vertically
	self.winSortByList:ArrangeChildrenVert()
end--]]

-- clear the item list
--[[function HousingRemodel:DestroyCategoryList()
	-- destroy all the wnd inside the list
	for idx,wnd in ipairs(self.tCategoryItems) do
		wnd:Destroy()
	end

	-- clear the list item array
	self.tCategoryItems = {}
end--]]

-- add an item into the item list
--[[function HousingRemodel:AddCategoryItem(i)
	-- load the window item for the list item
	local wnd = Apollo.LoadForm("HousingRemodel.xml", "CategoryListItem", self.winSortByList, self)

	-- keep track of the window item created
	self.tCategoryItems[i] = wnd

	-- give it a piece of data to refer to
	local wndItemBtn = wnd:FindChild("CategoryBtn")
	if wndItemBtn then -- make sure the text wnd exist
		wndItemBtn:SetText("Type " .. i) -- set the item wnd's text to "item i"
	end
	wnd:SetData(i)
end

-- when a list item is selected
function HousingRemodel:OnCategoryListItemSelected(wndHandler, wndControl)
    -- make sure the wndControl is valid
    if wndHandler ~= wndControl then
        return
    end--]]

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

	Print( "item " ..  self.wndSelectedListItem:GetData() .. " is selected.")
end--]]

-----------------------------------------------------------------------------------------------
-- HousingRemodel Instance
-----------------------------------------------------------------------------------------------
local HousingRemodelInst = HousingRemodel:new()
HousingRemodelInst:Init()
