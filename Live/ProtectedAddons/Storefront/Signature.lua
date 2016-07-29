-----------------------------------------------------------------------------------------------
-- Client Lua Script for Storefront/Signature.lua
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "StorefrontLib"
require "AccountItemLib"

local Signature = {} 

function Signature:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.tWndRefs = {}
	
	o.karSignatureData =
	{
		{strFeature = Apollo.GetString("Storefront_SignatureAuctionHouse"), arFree = {Apollo.GetString("Storefront_SignatureAuctionHouseFreeA"), Apollo.GetString("Storefront_SignatureAuctionHouseFreeB")}, arSignature = {Apollo.GetString("Storefront_SignatureAuctionHouseSigA"), Apollo.GetString("Storefront_SignatureAuctionHouseSigB")}},
		{strFeature = Apollo.GetString("Storefront_SignatureChallenges"), arFree = {Apollo.GetString("Storefront_SignatureChallengesFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureChallengesSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureCircles"), arFree = {Apollo.GetString("Storefront_SignatureCirclesFreeA"), Apollo.GetString("Storefront_SignatureCirclesFreeB")}, arSignature = {Apollo.GetString("Storefront_SignatureCirclesSigA"), Apollo.GetString("Storefront_SignatureCirclesSigB")}},
		{strFeature = Apollo.GetString("Storefront_SignatureCircuitCrafting"), arFree = {Apollo.GetString("Storefront_SignatureCircuitCraftingFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureCircuitCraftingSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureCommodities"), arFree = {Apollo.GetString("Storefront_SignatureCommoditiesFreeA"), Apollo.GetString("Storefront_SignatureCommoditiesFreeB")}, arSignature = {Apollo.GetString("Storefront_SignatureCommoditiesSigA"), Apollo.GetString("Storefront_SignatureCommoditiesSigB")}},
		{strFeature = Apollo.GetString("Storefront_SignatureCoordCrafting"), arFree = {Apollo.GetString("Storefront_SignatureCoordCraftingFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureCoordCraftingSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureCurrency"), arFree = {Apollo.GetString("Storefront_SignatureCurrencyFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureCurrencySigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureGathering"), arFree = {Apollo.GetString("Storefront_SignatureGatheringFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureGatheringSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureGuilds"), arFree = {Apollo.GetString("Storefront_SignatureGuildsFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureGuildsSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureHoliday"), arFree = {Apollo.GetString("Storefront_SignatureHolidayFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureHolidaySigA")}},
		{strFeature = Apollo.GetString("CRB_OmniBits"), arFree = {Apollo.GetString("Storefront_SignatureOmnibitsFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureOmnibitsSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureLockboxKeys"), arFree = {Apollo.GetString("Storefront_SignatureLockboxKeysFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureLockboxKeysSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureQueue"), arFree = {Apollo.GetString("Storefront_SignatureQueueFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureQueueSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureArenaTeams"), arFree = {Apollo.GetString("Storefront_SignatureArenaTeamsFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureArenaTeamsSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureReputation"), arFree = {Apollo.GetString("Storefront_SignatureReputationFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureReputationSigA"), Apollo.GetString("Storefront_SignatureReputationSigB")}},
		{strFeature = Apollo.GetString("Storefront_SignatureRestXp"), arFree = {Apollo.GetString("Storefront_SignatureRestXpFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureRestXpSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureStation"), arFree = {Apollo.GetString("Storefront_SignatureStationFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureStationSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureWake"), arFree = {Apollo.GetString("Storefront_SignatureWakeFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureWakeSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureWarparties"), arFree = {Apollo.GetString("Storefront_SignatureWarpartiesFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureWarpartiesSigA")}},
		{strFeature = Apollo.GetString("Storefront_SignatureXp"), arFree = {Apollo.GetString("Storefront_SignatureXpFreeA")}, arSignature = {Apollo.GetString("Storefront_SignatureXpSigA")}},
	}
	
    return o
end

function Signature:Init()
    Apollo.RegisterAddon(self)
end

function Signature:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Signature.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Signature:OnDocumentReady()
	Apollo.RegisterEventHandler("PremiumTierChanged", "OnPremiumTierChanged", self)
	
	-- Store UI Events
	Apollo.RegisterEventHandler("ShowPremiumPage", "OnShowPremiumPage", self)
	Apollo.RegisterEventHandler("HidePremiumPage", "OnHidePremiumPage", self)
end

function Signature:OnHidePremiumPage()
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain:Show(false)
	end
end

function Signature:OnShowPremiumPage(wndParent)
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		local wndMain = Apollo.LoadForm(self.xmlDoc, "SignaturePage", wndParent, self)
		self.tWndRefs.wndMain = wndMain
		self.tWndRefs.wndParent = wndParent
		
		-- Center Signature
		self.tWndRefs.wndSignature = wndMain
		self.tWndRefs.wndSignatureContainer = wndMain:FindChild("Container")
		self.tWndRefs.wndSignatureHeader = wndMain:FindChild("Container:Header")
		self.tWndRefs.wndSignatureDescription = wndMain:FindChild("Container:Description")
		self.tWndRefs.wndSignatureSecondaryDescription = wndMain:FindChild("Container:SecondaryDescription")
		self.tWndRefs.wndSignatureBuyNowBtn = wndMain:FindChild("Container:BuyNowBtn")
		self.tWndRefs.wndSignatureBuyNowExternalIcon = wndMain:FindChild("Container:External")
		self.tWndRefs.wndSignatureTableContainer = wndMain:FindChild("Container:TableContainer")
		
		-- Data Setup
		local strSignatureDesc = String_GetWeaselString('<P TextColor="UI_TextHoloBody" Font="CRB_InterfaceLarge">$1n</P>', Apollo.GetString("Storefront_SignatureDescriptionA"))
		local strSecondarySignatureDesc = String_GetWeaselString('<P TextColor="UI_TextHoloBody" Font="CRB_InterfaceMedium">$1n</P>', Apollo.GetString("Storefront_SignatureDescriptionB"))
		self.tWndRefs.wndSignatureDescription:SetAML(strSignatureDesc)
		self.tWndRefs.wndSignatureSecondaryDescription:SetAML(strSecondarySignatureDesc)
		for idx, tEntry in pairs(self.karSignatureData) do
			local nLine = 1
			while tEntry.arFree[nLine] ~= nil or tEntry.arSignature[nLine] ~= nil do
				local wndEntry = Apollo.LoadForm(self.xmlDoc, "SignatureListItem", self.tWndRefs.wndSignatureTableContainer, self)
			
				if idx % 2 ~= 0 then
					wndEntry:FindChild("Column1BG"):SetSprite("SignaturePageSprites:sprSignaturePage_TableCell_DarkSolid")
					wndEntry:FindChild("Column2BG"):SetSprite("SignaturePageSprites:sprSignaturePage_TableCell_DarkSolid")
					wndEntry:FindChild("Column3BG"):SetSprite("SignaturePageSprites:sprSignaturePage_TableCell_DarkGradient")
				else
					wndEntry:FindChild("Column1BG"):SetSprite("SignaturePageSprites:sprSignaturePage_TableCell_LightSolid")
					wndEntry:FindChild("Column2BG"):SetSprite("SignaturePageSprites:sprSignaturePage_TableCell_LightSolid")
					wndEntry:FindChild("Column3BG"):SetSprite("SignaturePageSprites:sprSignaturePage_TableCell_LightGradient")
				end
				
				local wndColumn1Text = wndEntry:FindChild("Column1BG:Column1Text")
				if nLine == 1 then
					wndColumn1Text:SetAML(string.format('<P TextColor="UI_TextMetalBodyHighlight" Font="CRB_Interface10_B">%s</P>', tEntry.strFeature))
				end
				local nCol1Width, nCol1Height = wndColumn1Text:SetHeightToContentHeight()
				
				local wndColumn2Text = wndEntry:FindChild("Column2BG:Column2Text")
				if tEntry.arFree[nLine] ~= nil then
					local strAML = string.format('<P TextColor="UI_TextMetalBodyHighlight" Font="CRB_Interface10_B">%s</P>', tEntry.arFree[nLine])
					wndColumn2Text:SetAML(strAML)
				end
				local nCol2Width, nCol2Height = wndColumn2Text:SetHeightToContentHeight()
				
				local wndColumn3Text = wndEntry:FindChild("Column3BG:Column3Text")
				if tEntry.arSignature[nLine]  ~= nil then
					local strAML = string.format('<P TextColor="UI_TextHoloTitle" Font="CRB_Interface10_B">%s</P>', tEntry.arSignature[nLine])
					wndColumn3Text:SetAML(strAML)
				end
				local nCol3Width, nCol3Height = wndColumn3Text:SetHeightToContentHeight()
				
				local nHeight = math.ceil(math.max(wndEntry:GetHeight(), nCol1Height, nCol2Height, nCol3Height) / wndEntry:GetHeight()) * wndEntry:GetHeight()
				local nLeft, nTop, nRight, nBottom = wndEntry:GetAnchorOffsets()
				wndEntry:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
				
				nLine = nLine + 1
			end
		end
		
		local nHeight = self.tWndRefs.wndSignatureTableContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndSignatureContainer:GetAnchorOffsets()
		self.tWndRefs.wndSignatureContainer:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + (nHeight - self.tWndRefs.wndSignatureTableContainer:GetHeight()))
		self.tWndRefs.wndSignature:RecalculateContentExtents()
	end
	
	self.tWndRefs.wndMain:Show(true)
	Sound.Play(Sound.PlayUIMTXStoreSignatureScreen)
	self:BuildSignaturePage()
end

function Signature:OnPremiumTierChanged()
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end
	
	self:BuildSignaturePage()
end

function Signature:BuildSignaturePage()
	if AccountItemLib.GetPremiumTier() > 0 then
		self.tWndRefs.wndSignatureHeader:SetText(Apollo.GetString("Storefront_WelcomeSignaturePlayer"))
		self.tWndRefs.wndSignatureBuyNowBtn:Show(false)
		self.tWndRefs.wndSignatureBuyNowExternalIcon:Show(false)
	else
		self.tWndRefs.wndSignatureHeader:SetText(Apollo.GetString("Storefront_BecomeSignaturePlayer"))
		self.tWndRefs.wndSignatureBuyNowBtn:Show(true)
		self.tWndRefs.wndSignatureBuyNowExternalIcon:Show(true)

	end
end

function Signature:OnSignatureBuySignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	StorefrontLib.RedirectToSignatureOffer()
end

local SignatureInst = Signature:new()
SignatureInst:Init()
