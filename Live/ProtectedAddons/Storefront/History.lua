-----------------------------------------------------------------------------------------------
-- Client Lua Script for Storefront/History.lua
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "StorefrontLib"
require "Money"
require "Tooltip"
require "WindowLocation"

local History = {} 

function History:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.tWndRefs = {}
	o.bUpdateHistory = true
	
    return o
end

function History:Init()
    Apollo.RegisterAddon(self)
end

function History:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("History.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function History:OnDocumentReady()
	Apollo.RegisterEventHandler("StorePurchaseHistoryReady", "OnHistoryReady", self)
	Apollo.RegisterEventHandler("StoreRealCurrencyPurchaseHistoryReady", "OnHistoryReady", self)
	Apollo.RegisterEventHandler("StoreCatalogReady", "OnStoreCatalogReady", self)
	Apollo.RegisterEventHandler("StorePurchaseOfferResult", "OnStorePurchaseOfferResult", self)
	Apollo.RegisterEventHandler("StorePurchaseVirtualCurrencyPackageResult", "OnStorePurchaseVirtualCurrencyPackageResult", self)
	Apollo.RegisterEventHandler("AccountCurrencyChanged", "OnAccountCurrencyChanged", self)
	Apollo.RegisterEventHandler("StoreError", "OnStoreError", self)

	-- Store UI Events
	Apollo.RegisterEventHandler("ShowDialog", "OnShowDialog", self)
	Apollo.RegisterEventHandler("CloseDialog", "OnCloseDialog", self)
end

function History:OnCloseDialog()
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain:Show(false)
	end
end

function History:OnShowDialog(strDialogName, wndParent)
	if strDialogName ~= "History" then
		if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
			self.tWndRefs.wndMain:Show(false)
		end
		return
	end
	
	self:OnOpenHistoryDialog(wndParent)
end

function History:OnOpenHistoryDialog(wndParent)
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		local wndMain = Apollo.LoadForm(self.xmlDoc, "HistoryDialog", wndParent, self)
		self.tWndRefs.wndMain = wndMain
		self.tWndRefs.wndParent = wndParent
		
		self.tWndRefs.wndGrid = wndMain:FindChild("Grid")
		self.tWndRefs.wndEmptyLabel = wndMain:FindChild("EmptyLabel")
	end
	
	if self.bUpdateHistory then
		StorefrontLib.RequestHistory()
	end
	
	self.tWndRefs.wndMain:Show(true)
end

function History:OnHistoryReady()
	if self.tWndRefs.wndMain:IsShown() then
		local nPos = self.tWndRefs.wndGrid:GetVScrollPos()
		self:BuildHistory()
		self.tWndRefs.wndGrid:SetVScrollPos(nPos)
	end
end

function History:OnStoreCatalogReady()	
	self.bUpdateHistory = true
end

function History:OnStorePurchaseOfferResult()
	self.bUpdateHistory = true
end

function History:OnStorePurchaseVirtualCurrencyPackageResult()
	self.bUpdateHistory = true
end

function History:OnAccountCurrencyChanged()
	self.bUpdateHistory = true
end

function History:OnStoreError()
	self.bUpdateHistory = true
end

function History:GetRealCurrencyNameFromEnum(eRealCurrency)
	if eRealCurrency == StorefrontLib.CodeEnumRealCurrency.USD then
		return Apollo.GetString("Storefront_ExternalCurrency_USD")
	elseif eRealCurrency == StorefrontLib.CodeEnumRealCurrency.GBP then
		return  Apollo.GetString("Storefront_ExternalCurrency_GBP")
	elseif eRealCurrency == StorefrontLib.CodeEnumRealCurrency.EUR then
		return  Apollo.GetString("Storefront_ExternalCurrency_EUR")
	end
	
	return "?"
end

function History:BuildHistory()
	local wndGrid = self.tWndRefs.wndGrid
	wndGrid:DeleteAll()
	
	local arHistory = StorefrontLib.GetPurchaseHistory()
	for idx, tPurchase in pairs(arHistory) do
		local iCurrRow = wndGrid:AddRow(tPurchase.strPurchaseId, nil, tPurchase)

		local strName = tPurchase.strName
		if tPurchase.bRefunded then
			strName = String_GetWeaselString(Apollo.GetString("Storefront_Refunded"), tPurchase.strName)
		end
		wndGrid:SetCellText(iCurrRow, 2, tPurchase.strName)
		wndGrid:SetCellText(iCurrRow, 3, tPurchase.strTimestamp)
		wndGrid:SetCellSortText(iCurrRow, 3, tPurchase.nTimestamp)
		
		if tPurchase.eRealCurrency == nil then
			local xml = XmlDoc.new()
			tPurchase.monPrice:AddToTooltip(xml, "", "UI_TextHoloBody", "Default", "Right")
			wndGrid:SetCellDoc(iCurrRow, 4, xml:ToString())
			wndGrid:SetCellSortText(iCurrRow, 4, tPurchase.monPrice:GetAmount())
		else
			local strCurrencyName = self:GetRealCurrencyNameFromEnum(tPurchase.eRealCurrency)
			wndGrid:SetCellText(iCurrRow, 4, String_GetWeaselString("$2n$1n", string.format("%.2f", tPurchase.nPrice), strCurrencyName))
			wndGrid:SetCellSortText(iCurrRow, 4, tPurchase.nPrice)
		end
	end

	wndGrid:SetSortColumn(3, false)
	
	self.tWndRefs.wndEmptyLabel:Show(#arHistory == 0)
end

function History:OnHistoryCancelSignal(wndHandler, wndControl, eMouseButton)	
	self.tWndRefs.wndMain:Show(false)
	self.tWndRefs.wndParent:Show(false)
	
	Event_FireGenericEvent("CloseDialog")
end

local HistoryInst = History:new()
HistoryInst:Init()
