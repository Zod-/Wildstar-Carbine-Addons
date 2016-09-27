-----------------------------------------------------------------------------------------------
-- Client Lua Script for RuneSets
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local RuneSets = {}

function RuneSets:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RuneSets:Init()
    Apollo.RegisterAddon(self)
end

function RuneSets:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("RuneSets.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function RuneSets:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("UpdateRuneSets", 				"RedrawSets", self)
	Apollo.RegisterEventHandler("PlayerEquippedItemChanged", 	"OnUpdateEvent", self)
	Apollo.RegisterEventHandler("ItemModified", 				"OnUpdateEvent", self)
	Apollo.RegisterEventHandler("ToggleCharacterWindow", 		"OnToggleCharacterWindow", self)
end

-----------------------------------------------------------------------------------------------
-- Sets
-----------------------------------------------------------------------------------------------

function RuneSets:RedrawSets(wndParent)
	if not self.wndMain or not self.wndMain:IsValid() then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "RuneSetsForm", wndParent, self)
		if self.locSavedWindowLoc then
			self.wndMain:MoveToLocation(self.locSavedWindowLoc)
		end
	end

	-- Sets from equipped items only
	local tListOfSets = Item.GetSetBonuses()

	-- Draw sets now
	local strFullText = ""
	local kstrLineBreak = "<P Font=\"CRB_InterfaceLarge_B\" TextColor=\"0\">.</P>" -- TODO TEMP HACK
	for idx, tSetInfo in pairs(tListOfSets) do
		local strLocalSetText = string.format("<P Font=\"CRB_InterfaceLarge\" TextColor=\"UI_TextHoloTitle\">%s</P>",
		String_GetWeaselString(Apollo.GetString("EngravingStation_RuneSetText"), tSetInfo.strName, tSetInfo.nPower, tSetInfo.nMaxPower))

		local tBonuses = tSetInfo.arBonuses
		table.sort(tBonuses, function(a,b) return a.nPower < b.nPower end)

		for idx3, tBonusInfo in pairs(tBonuses) do
			local strLocalColor = tBonusInfo.bIsActive and "ItemQuality_Good" or "UI_TextHoloBody"
			if tBonusInfo.splBonus then
				local strTooltip = ""
				local tTooltips = tBonusInfo.splBonus:GetTooltips()
				if tTooltips and tTooltips.strLASTooltip then
					strTooltip = tTooltips.strLASTooltip
				end
				
				strLocalSetText = string.format("%s<P Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</P><P TextColor=\"0\">.</P>", strLocalSetText, strLocalColor,
					String_GetWeaselString(Apollo.GetString("Tooltips_RuneDetails"), tBonusInfo.nPower, tBonusInfo.splBonus:GetName(), strTooltip))
			end
			
			if tBonusInfo.eProperty then
				local nValue = 0
				local nScalar = 0
				if tBonusInfo.nValue ~= nil then
					nValue = tBonusInfo.nValue * 100
				else
					nScalar = (tBonusInfo.nScalar - 1) * 100
				end
				strLocalSetText = string.format("%s<P Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</P>", strLocalSetText, strLocalColor,
					String_GetWeaselString(Apollo.GetString("RuneSets_PropertyInfo"), tBonusInfo.nPower, Apollo.FormatNumber(nValue + nScalar, 2, true), Item.GetPropertyName(tBonusInfo.eProperty)))
			else
				strLocalSetText = string.format("%s<P Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</P>", strLocalSetText, strLocalColor, 
					String_GetWeaselString(Apollo.GetString("RuneSets_Specials"), tBonusInfo.nPower, tBonusInfo.strName, tBonusInfo.strFlavor))
			end
		end

		strFullText = strFullText .. kstrLineBreak .. strLocalSetText
	end

	self.wndMain:FindChild("SetsListNormalText"):SetAML(strFullText)
	self.wndMain:FindChild("SetsListNormalText"):SetHeightToContentHeight()
	self.wndMain:FindChild("SetsListContainer"):RecalculateContentExtents()
	self.wndMain:FindChild("SetsListContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.wndMain:FindChild("SetsListEmptyText"):Show(strFullText == "")
end

function RuneSets:OnSetsClose(wndHandler, wndControl)
	if self.wndMain and self.wndMain:IsValid() then
		self.locSavedWindowLoc = self.wndMain:GetLocation()
		self.wndMain:Destroy()
	end
end

function RuneSets:OnUpdateEvent()
	if not self.wndMain or not self.wndMain:IsValid() or not self.wndMain:IsVisible() then -- Will consider parents as well
		return
	end
	self:RedrawSets()
end

function RuneSets:OnToggleCharacterWindow()
	if not self.wndMain or not self.wndMain:IsValid() then -- Doesn't care about visibility (as it's false while being opened)
		return
	end
	self:RedrawSets()
end

local RuneSetsInst = RuneSets:new()
RuneSetsInst:Init()
