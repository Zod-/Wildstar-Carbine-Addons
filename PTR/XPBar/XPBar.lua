-----------------------------------------------------------------------------------------------
-- Client Lua Script for XPBar
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Apollo"
require "GameLib"
require "GroupLib"
require "PlayerPathLib"
require "AccountItemLib"

local XPBar = {}
local knMaxLevel = 50 -- TODO: Replace with a variable from code
local knMaxPathLevel = 30 -- TODO: Replace this with a non hardcoded value
local knDefaultAltCurrency = 7

local karCurrency =  	
{						-- To add a new currency just add an entry to the table; the UI will do the rest. Idx == 1 will be the default one shown
	{eType = Money.CodeEnumCurrencyType.Renown, 					strTitle = Apollo.GetString("CRB_Renown"), 						strDescription = Apollo.GetString("CRB_Renown_Desc")},
	{eType = Money.CodeEnumCurrencyType.ElderGems, 					strTitle = Apollo.GetString("CRB_Elder_Gems"), 					strDescription = Apollo.GetString("CRB_Elder_Gems_Desc")},
	{eType = Money.CodeEnumCurrencyType.Glory, 						strTitle = Apollo.GetString("CRB_Glory"), 						strDescription = Apollo.GetString("CRB_Glory_Desc")},
	{eType = Money.CodeEnumCurrencyType.Triploons, 					strTitle = Apollo.GetString("CRB_Triploons"), 					strDescription = Apollo.GetString("CRB_Triploons_Desc")},
	{eType = Money.CodeEnumCurrencyType.Prestige, 					strTitle = Apollo.GetString("CRB_Prestige"), 					strDescription = Apollo.GetString("CRB_Prestige_Desc")},
	{eType = Money.CodeEnumCurrencyType.CraftingVouchers, 			strTitle = Apollo.GetString("CRB_Crafting_Vouchers"), 			strDescription = Apollo.GetString("CRB_Crafting_Voucher_Desc")},
	-- Will be alternative account currency for the sixth index
	{eType = AccountItemLib.CodeEnumAccountCurrency.ServiceToken, 	strTitle = Apollo.GetString("AccountInventory_ServiceToken"), 	strDescription = Apollo.GetString("AccountInventory_ServiceToken_Desc"), bAccountItem = true},
	{eType = AccountItemLib.CodeEnumAccountCurrency.MysticShiny, 	strTitle = Apollo.GetString("CRB_FortuneCoin"), 				strDescription = Apollo.GetString("CRB_FortuneCoin_Desc"), bAccountItem = true},
	{eType = AccountItemLib.CodeEnumAccountCurrency.PromissoryNote,	strTitle = Apollo.GetString("CRB_Protostar_Promissory_Note"), 	strDescription = Apollo.GetString("CRB_Protostar_Promissory_Note_Desc"), bAccountItem = true},
	{eType = AccountItemLib.CodeEnumAccountCurrency.PromotionToken, strTitle = Apollo.GetString("CRB_Protostar_Promotion_Token"),	strDescription = Apollo.GetString("CRB_Protostar_Promotion_Token_Desc"), bAccountItem = true},
}

local ktPathIcon = {
	[PlayerPathLib.PlayerPathType_Soldier] 		= "HUD_ClassIcons:spr_Icon_HUD_Path_Soldier",
	[PlayerPathLib.PlayerPathType_Settler] 		= "HUD_ClassIcons:spr_Icon_HUD_Path_Settler",
	[PlayerPathLib.PlayerPathType_Scientist] 	= "HUD_ClassIcons:spr_Icon_HUD_Path_Scientist",
	[PlayerPathLib.PlayerPathType_Explorer] 	= "HUD_ClassIcons:spr_Icon_HUD_Path_Explorer",
}

local c_arPathStrings = {
	[PlayerPathLib.PlayerPathType_Soldier] 		= "CRB_Soldier",
	[PlayerPathLib.PlayerPathType_Settler] 		= "CRB_Settler",
	[PlayerPathLib.PlayerPathType_Scientist] 	= "CRB_Scientist",
	[PlayerPathLib.PlayerPathType_Explorer] 	= "CRB_Explorer",
}

local kstrRed = "ffff4040"
local kstrOrange = "ffffd100"
local kstrBlue = "ff32fcf6"
local kstrDarkBlue = "ff209d99"

function XPBar:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function XPBar:Init()
    Apollo.RegisterAddon(self)
end

function XPBar:OnSave(eType)
	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		return {
			nAltCurrencySelected = self.nAltCurrencySelected
		}
	end
	return nil
end

function XPBar:OnRestore(eType, tSavedData)
	if eType == GameLib.CodeEnumAddonSaveLevel.Character  then
		self.nAltCurrencySelected = knDefaultAltCurrency
		if tSavedData.nAltCurrencySelected ~= nil then
			self.nAltCurrencySelected = tSavedData.nAltCurrencySelected
		end
	end
	if self.wndInvokeForm ~= nil then
		self:UpdateAltCashDisplay()
	end
end

function XPBar:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("XPBar.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
	
	if AccountItemLib.GetAlternativeCurrency() == AccountItemLib.CodeEnumAccountCurrency.Omnibits then
		table.insert(karCurrency, 6, {eType = AccountItemLib.CodeEnumAccountCurrency.Omnibits, strTitle = Apollo.GetString("CRB_OmniBits"), strDescription = Apollo.GetString("CRB_OmniBits_Desc"), bAccountItem = true})
	elseif AccountItemLib.GetAlternativeCurrency() == AccountItemLib.CodeEnumAccountCurrency.Loyalty then
		table.insert(karCurrency, 6, {eType = AccountItemLib.CodeEnumAccountCurrency.Loyalty, strTitle = Apollo.GetString("CRB_Loyalty"), strDescription = Apollo.GetString("CRB_Loyalty_Desc"), bAccountItem = true})
	end
	
	self.nAltCurrencySelected = knDefaultAltCurrency
end

function XPBar:OnDocumentReady()
	Apollo.RegisterEventHandler("ChangeWorld", 					"OnClearCombatFlag", self)
	Apollo.RegisterEventHandler("ShowResurrectDialog", 			"OnClearCombatFlag", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnEnteredCombat", self)
	Apollo.RegisterEventHandler("AccountCurrencyChanged", 		"OnAccountCurrencyChanged", self)
	Apollo.RegisterEventHandler("PlayerCurrencyChanged",		"OnPlayerCurrencyChanged", self)
	Apollo.RegisterEventHandler("Group_MentorRelationship", 	"RedrawAll", self)
	Apollo.RegisterEventHandler("CharacterCreated", 			"OnCharacterCreated", self)
	Apollo.RegisterEventHandler("UnitPvpFlagsChanged", 			"RedrawAll", self)
	Apollo.RegisterEventHandler("UnitNameChanged", 				"RedrawAll", self)
	Apollo.RegisterEventHandler("PersonaUpdateCharacterStats", 	"RedrawAll", self)
	Apollo.RegisterEventHandler("PlayerLevelChange", 			"RedrawAll", self)
	Apollo.RegisterEventHandler("UI_XPChanged", 				"OnXpChanged", self)
	Apollo.RegisterEventHandler("UpdatePathXp", 				"OnXpChanged", self)
	Apollo.RegisterEventHandler("ElderPointsGained", 			"OnXpChanged", self)
	Apollo.RegisterEventHandler("UpdateRewardProperties", 		"RedrawAll", self)
	Apollo.RegisterEventHandler("OptionsUpdated_HUDPreferences","RedrawAll", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 	"OnTutorial_RequestUIAnchor", self)
	Apollo.RegisterEventHandler("UpdateInventory", 				"OnUpdateInventory", self)
	Apollo.RegisterEventHandler("PersonaUpdateCharacterStats",	"OnUpdateInventory", self)
	Apollo.RegisterEventHandler("KeyBindingKeyChanged",			"OnKeyBindingKeyChanged", self)
	Apollo.RegisterEventHandler("PremiumTierChanged",			"OnPremiumTierChanged", self)


	self.wndArt = Apollo.LoadForm(self.xmlDoc, "BaseBarCornerArt", "FixedHudStratum", self)
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "BaseBarCornerForm", "FixedHudStratum", self)
	self.wndXPLevel = self.wndMain:FindChild("XPButton")
	self.wndPathLevel = self.wndMain:FindChild("PathButton")
	
	self.nLeftCapOrigWidth = self.wndArt:FindChild("BottomBarBaseRightCap"):GetWidth()
	
	self.wndInvokeForm = Apollo.LoadForm(self.xmlDoc, "InventoryInvokeForm", "FixedHudStratum", self)
	self.wndCurrencyDisplay = Apollo.LoadForm(self.xmlDoc, "OptionsConfigureCurrency", nil, self)
	self.wndQuestItemNotice = self.wndInvokeForm:FindChild("QuestItemNotice")
	self.wndInvokeButton = self.wndInvokeForm:FindChild("InvokeBtn")
	self.wndCurrencyDisplayList = self.wndCurrencyDisplay:FindChild("OptionsConfigureCurrencyList")
	self.wndInvokeForm:FindChild("OptionsBtn"):AttachWindow(self.wndCurrencyDisplay)
	self.bInCombat = false
	self.bOnRedrawCooldown = false
	
	Apollo.RegisterTimerHandler("BaseBarCorner_RedrawCooldown", "RedrawCooldown", self)
	Apollo.CreateTimer("BaseBarCorner_RedrawCooldown", 1, false)
	Apollo.StopTimer("BaseBarCorner_RedrawCooldown")

	if GameLib.GetPlayerUnit() ~= nil then
		self:RedrawAll()
	end

	--Alt Curency Display
	for idx = 1, #karCurrency do
		local tData = karCurrency[idx]
		local wnd = Apollo.LoadForm(self.xmlDoc, "PickerEntry", self.wndCurrencyDisplayList, self)
		tData.wnd = wnd
		
		if tData.bAccountItem then
			wnd:FindChild("EntryCash"):SetMoneySystem(Money.CodeEnumCurrencyType.GroupCurrency, 0, 0, tData.eType)
		else
			wnd:FindChild("EntryCash"):SetMoneySystem(tData.eType)
		end
		wnd:FindChild("PickerEntryBtn"):SetData(idx)
		wnd:FindChild("PickerEntryBtn"):SetCheck(idx == self.nAltCurrencySelected)
		wnd:FindChild("PickerEntryBtn"):SetText(tData.strTitle)
		
		if tData.eType == AccountItemLib.CodeEnumAccountCurrency.Omnibits then
			self:UpdateOmnibitTooltip()
		else
			wnd:FindChild("PickerEntryBtn"):SetTooltip(tData.strDescription)
		end
	end
	self.wndCurrencyDisplayList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self:UpdateAltCashDisplay()
	self.xmlDoc = nil
	
	self:OnPremiumTierChanged(AccountItemLib.GetPremiumSystem(), AccountItemLib.GetPremiumTier())
end

function XPBar:OnCurrencyPanelToggle(wndHandler, wndControl) -- OptionsBtn
	for key, wndCurr in pairs(self.wndCurrencyDisplayList:GetChildren()) do
		self:UpdateAltCash(wndCurr)
	end
end

function XPBar:OnCharacterCreated()
	self:RedrawAll()
	self:UpdateAltCashDisplay()
end

function XPBar:OnPlayerCurrencyChanged()
	self:UpdateAltCashDisplay()
end

function XPBar:OnAccountCurrencyChanged()
	self:UpdateAltCashDisplay()
	self:UpdateOmnibitTooltip()
end

-----------------------------------------------------------------------------------------------
-- Alt Currency Window Functions
-----------------------------------------------------------------------------------------------

function XPBar:UpdateAltCash(wndHandler, wndControl) -- Also from PickerEntryBtn
	local nSelected = wndHandler:FindChild("PickerEntryBtn"):GetData()
	local tData = karCurrency[nSelected]

	if wndHandler:FindChild("PickerEntryBtn"):IsChecked() then
		self.nAltCurrencySelected = nSelected
	end
	
	self:UpdateAltCashDisplay()

	tData.wnd:FindChild("EntryCash"):SetAmount(self:HelperGetCurrencyAmount(tData), true)
	if self.wndCurrencyDisplay:IsShown() then
		self.wndCurrencyDisplay:Show(false)
	end
end

function XPBar:UpdateAltCashDisplay()
	local tData = karCurrency[self.nAltCurrencySelected]
	self.wndInvokeForm:FindChild("AltCashWindow"):SetAmount(self:HelperGetCurrencyAmount(tData), true)
	self.wndInvokeForm:FindChild("MainCashWindow"):SetAmount(GameLib.GetPlayerCurrency(), true)
	
	-- Rescale Bottom Right Bar to Accomodate Alt Currency Width
	local nLeftCap, nTopCap, nRightCap, nBottomCap = self.wndArt:FindChild("BottomBarBaseRightCap"):GetAnchorOffsets()
	local nAltCurrencyWidth = self.wndInvokeForm:FindChild("AltCashWindow"):GetDisplayWidth()
	self.wndArt:FindChild("BottomBarBaseRightCap"):SetAnchorOffsets(nRightCap - self.nLeftCapOrigWidth - nAltCurrencyWidth, nTopCap, nRightCap, nBottomCap)
end

function XPBar:HelperGetCurrencyAmount(tData)
	local monAmount = 0
	if tData.bAccountItem then
		monAmount = AccountItemLib.GetAccountCurrency(tData.eType)
	else
		monAmount = GameLib.GetPlayerCurrency(tData.eType)
	end
	return monAmount
end

function XPBar:RedrawCooldown()
	Apollo.StopTimer("BaseBarCorner_RedrawCooldown")
	self.bOnRedrawCooldown = false
	self:RedrawAllPastCooldown()
end

function XPBar:RedrawAll()
	if not self.bOnRedrawCooldown then
		self.bOnRedrawCooldown = true
		self:RedrawAllPastCooldown()
	end

	Apollo.StartTimer("BaseBarCorner_RedrawCooldown")
end

function XPBar:RedrawAllPastCooldown()
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer then
		return
	end

	local strName = unitPlayer:GetName()
	local tStats = unitPlayer:GetBasicStats()
	local tMyGroupData = GroupLib.GetGroupMember(1)

	-- XP/EP Progress Bar and Tooltip
	local strXPorEP = ""
	local strTooltip = ""
	local strPathXP = ""
	local strPathTooltip = ""
	
	if tStats.nLevel == knMaxLevel then -- TODO: Hardcoded max level
		self:RedrawEP()
		strTooltip = self:ConfigureEPTooltip(unitPlayer)
		self.wndMain:FindChild("ElderGems"):Show(true)
	else
		strXPorEP = String_GetWeaselString(Apollo.GetString("BaseBar_XPBracket"), self:RedrawXP())
		strTooltip = self:ConfigureXPTooltip(unitPlayer)
		self.wndMain:FindChild("ElderGems"):Show(false)
	end
	
	--Path XP Progress Bar and Tooltip
	strPathXP = String_GetWeaselString(Apollo.GetString("BaseBar_PathBracket"), self:RedrawPathXP())
	strPathTooltip = self:ConfigurePathXPTooltip(unitPlayer)

	-- If grouped, Mentored by
	if tMyGroupData and #tMyGroupData.tMentoredBy ~= 0 then
		strName = String_GetWeaselString(Apollo.GetString("BaseBar_MenteeAppend"), strName)
		for idx, nMentorGroupIdx in pairs(tMyGroupData.tMentoredBy) do
			local tTargetGroupData = GroupLib.GetGroupMember(nMentorGroupIdx)
			if tTargetGroupData then
				strTooltip = "<P Font=\"CRB_InterfaceSmall\">"..String_GetWeaselString(Apollo.GetString("BaseBar_MenteeTooltip"), tTargetGroupData.strCharacterName).."</P>"..strTooltip
			end
		end
	end

	-- If grouped, Mentoring
	if tMyGroupData and tMyGroupData.bIsMentoring then -- unitPlayer:IsMentoring() -- tStats.effectiveLevel ~= 0 and tStats.effectiveLevel ~= tStats.level
		strName = String_GetWeaselString(Apollo.GetString("BaseBar_MentorAppend"), strName, tStats.nEffectiveLevel)
		local tTargetGroupData = GroupLib.GetGroupMember(tMyGroupData.nMenteeIdx)
		if tTargetGroupData then
			strTooltip = "<P Font=\"CRB_InterfaceSmall\">"..String_GetWeaselString(Apollo.GetString("BaseBar_MentorTooltip"), tTargetGroupData.strCharacterName).."</P>"..strTooltip
		end
	end

	-- If in an instance (or etc.) and Rallied
	if unitPlayer:IsRallied() and tStats.nEffectiveLevel ~= tStats.nLevel then
		strName = String_GetWeaselString(Apollo.GetString("BaseBar_RallyAppend"), strName, tStats.nEffectiveLevel)
		strTooltip = "<P Font=\"CRB_InterfaceSmall\">"..Apollo.GetString("BaseBar_YouAreRallyingTooltip").."</P>"..strTooltip
	end

	-- PvP
	local tPvPFlagInfo = GameLib.GetPvpFlagInfo()
	if tPvPFlagInfo and tPvPFlagInfo.bIsFlagged then
		strName = String_GetWeaselString(Apollo.GetString("BaseBar_PvPAppend"), strName)
	end

	self.wndXPLevel:SetText(String_GetWeaselString(strXPorEP))
	self.wndPathLevel:SetText(strPathXP)

	self.wndMain:FindChild("XPBarContainer"):SetBGColor(self.bInCombat and ApolloColor.new("66ffffff") or ApolloColor.new("white"))
	self.wndMain:FindChild("XPBarContainer"):SetTooltip(strTooltip)
	self.wndXPLevel:SetTooltip(strTooltip)
	
	self.wndMain:FindChild("PathBarContainer"):SetTooltip(strPathTooltip)
	self.wndPathLevel:SetTooltip(strPathTooltip)
	
	--Toggle Visibility based on ui preference
	local nVisibility = Apollo.GetConsoleVariable("hud.xpBarDisplay")
	
	if nVisibility == 1 then -- always on
		self.wndMain:Show(true)
	elseif nVisibility == 2 then --always off
		self.wndMain:Show(false)
	elseif nVisibility == 3 then --on in combat
		self.wndMain:Show(unitPlayer:IsInCombat())	
	elseif nVisibility == 4 then --on out of combat
		self.wndMain:Show(not unitPlayer:IsInCombat())
	else
		--If the player has any XP draw the bars and set the preference to 1 automatically.
		--else hide the bar until the player earns some XP, then trigger a tutorial prompt
		self.wndMain:Show(false)
	end
	
	self.wndMain:FindChild("MTX_BonusXP"):Show(self.wndMain:IsVisible() and GameLib.HasXPBonus())
	
	self.wndArt:Show(true)
	self:OnUpdateInventory()
end

function XPBar:UpdateOmnibitTooltip()
	local tOmnibitData = nil 
	for idx, tData in pairs(karCurrency) do
		if tData.eType == AccountItemLib.CodeEnumAccountCurrency.Omnibits then
			tOmnibitData = tData
			break
		end
	end
	
	local tBonusInfo = GameLib.GetOmnibitsBonusInfo()
	local nTotalWeeklyOmniBitBonus = tBonusInfo.nWeeklyBonusMax - tBonusInfo.nWeeklyBonusEarned;
	if nTotalWeeklyOmniBitBonus < 0 then
		nTotalWeeklyOmniBitBonus = 0
	end
	
	local strTooltip = tOmnibitData.strDescription.."\n"..String_GetWeaselString(Apollo.GetString("CRB_OmniBits_EarningsWeekly"), nTotalWeeklyOmniBitBonus)
	tOmnibitData.wnd:FindChild("PickerEntryBtn"):SetTooltip(strTooltip)
end

-----------------------------------------------------------------------------------------------
-- Path XP
-----------------------------------------------------------------------------------------------

function XPBar:RedrawPathXP()
	if not PlayerPathLib then
		return 0
	end
	
	local nCurrentLevel = PlayerPathLib.GetPathLevel()
	local nNextLevel = math.min(knMaxPathLevel, nCurrentLevel + 1)

	local nLastLevelXP = PlayerPathLib.GetPathXPAtLevel(nCurrentLevel)
	local nCurrentXP =  PlayerPathLib.GetPathXP() - nLastLevelXP
	local nNeededXP = PlayerPathLib.GetPathXPAtLevel(nNextLevel) - nLastLevelXP
	
	local wndPathBarFill = self.wndMain:FindChild("PathBarContainer:PathBarFill")
	wndPathBarFill:SetMax(nNeededXP)
	wndPathBarFill:SetProgress(nCurrentXP)
	
	local ePathId = PlayerPathLib.GetPlayerPathType()
	local wndPathIcon = self.wndMain:FindChild("PathIcon")
	wndPathIcon:SetSprite(ktPathIcon[ePathId])
	
	if nNeededXP == 0 then
		wndPathBarFill:SetMax(100)
		wndPathBarFill:SetProgress(100)
		return 100
	end
	
	return nCurrentXP / nNeededXP * 100
end

function XPBar:ConfigurePathXPTooltip(unitPlayer)
	if not PlayerPathLib then
		return ""
	end
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer then
		return
	end
	
	local strPathType = c_arPathStrings[unitPlayer:GetPlayerPathType()] or ""
	
	local nCurrentLevel = PlayerPathLib.GetPathLevel()
	local nNextLevel = math.min(knMaxPathLevel, nCurrentLevel + 1)

	local nLastLevelXP = PlayerPathLib.GetPathXPAtLevel(nCurrentLevel)
	local nCurrentXP =  PlayerPathLib.GetPathXP() - nLastLevelXP
	local nNeededXP = PlayerPathLib.GetPathXPAtLevel(nNextLevel) - nLastLevelXP
	
	local strTooltip = nNeededXP > 0 and string.format("<P Font=\"CRB_InterfaceSmall\">%s</P>", String_GetWeaselString(Apollo.GetString("Base_XPValue"), Apollo.FormatNumber(nCurrentXP, 0, true), Apollo.FormatNumber(nNeededXP, 0, true), nCurrentXP / nNeededXP * 100)) or ""
	
	return string.format("<P Font=\"CRB_InterfaceSmall\">%s %s%s</P>%s", Apollo.GetString(strPathType), Apollo.GetString("CRB_Level_"), nCurrentLevel, strTooltip)
end

-----------------------------------------------------------------------------------------------
-- Elder Points (When at max level)
-----------------------------------------------------------------------------------------------

function XPBar:RedrawEP()
	local nCurrentEP = GetPeriodicElderPoints()
	local nEPDailyMax = GameLib.ElderPointsDailyMax
	local nRestedEP = GetRestXp() 							-- amount of rested xp
	local nRestedEPPool = GetRestXpKillCreaturePool() 		-- amount of rested xp remaining from creature kills

	if not nCurrentEP or not nEPDailyMax or not nRestedEP then
		return
	end
	
	local wndXPBarFill = self.wndMain:FindChild("XPBarContainer:XPBarFill")
	local wndRestXPBarFill = self.wndMain:FindChild("XPBarContainer:RestXPBarFill")
	local wndRestXPBarGoal = self.wndMain:FindChild("XPBarContainer:RestXPBarGoal")

	wndXPBarFill:SetMax(nEPDailyMax)
	wndXPBarFill:SetProgress(nCurrentEP)

	-- Rest Bar and Goal (where it ends)
	wndRestXPBarFill:SetMax(nEPDailyMax)
	wndRestXPBarFill:Show(nRestedEP and nRestedEP > 0)
	if nRestedEP and nRestedEP > 0 then
		wndRestXPBarFill:SetProgress(math.min(nEPDailyMax, nCurrentEP + nRestedEP))
	end

	local bShowRestEPGoal = nRestedEP and nRestedEPPool and nRestedEP > 0 and nRestedEPPool > 0
	wndRestXPBarGoal:SetMax(nEPDailyMax)
	wndRestXPBarGoal:Show(bShowRestEPGoal)
	if bShowRestEPGoal then
		wndRestXPBarGoal:SetProgress(math.min(nEPDailyMax, nCurrentEP + nRestedEPPool))
	end

	return nCurrentEP / nEPDailyMax * 100
end

function XPBar:ConfigureEPTooltip(unitPlayer)
	local nCurrentEP = GetElderPoints()
	local nCurrentToDailyMax = GetPeriodicElderPoints()
	local nEPToAGem = GameLib.ElderPointsPerGem
	local nEPDailyMax = GameLib.ElderPointsDailyMax

	local nRestedEP = GetRestXp() 							-- amount of rested xp
	local nRestedEPPool = GetRestXpKillCreaturePool() 		-- amount of rested xp remaining from creature kills

	if not nCurrentEP or not nEPToAGem or not nEPDailyMax then
		return
	end

	-- Top String
	local strTooltip = String_GetWeaselString(Apollo.GetString("BaseBar_ElderPointsPercent"), Apollo.FormatNumber(nCurrentEP, 0, true), Apollo.FormatNumber(nEPToAGem, 0, true), nCurrentEP / nEPToAGem * 100)
	if nCurrentEP == nEPDailyMax then
		strTooltip = "<P Font=\"CRB_InterfaceSmall\">" .. strTooltip .. "</P><P Font=\"CRB_InterfaceSmall\">" .. Apollo.GetString("BaseBar_ElderPointsAtMax") .. "</P>"
	else
		local strDailyMax = String_GetWeaselString(Apollo.GetString("BaseBar_ElderPointsWeeklyMax"), Apollo.FormatNumber(nCurrentToDailyMax, 0, true), Apollo.FormatNumber(nEPDailyMax, 0, true), nCurrentToDailyMax / nEPDailyMax * 100)
		strTooltip = "<P Font=\"CRB_InterfaceSmall\">" .. strTooltip .. "</P><P Font=\"CRB_InterfaceSmall\">" .. strDailyMax .. "</P>"
	end

	-- Rested
	if nRestedEP > 0 then
		local strRestLineOne = String_GetWeaselString(Apollo.GetString("Base_EPRested"), Apollo.FormatNumber(nRestedEP, 0, true), nRestedEP / nEPDailyMax * 100)
		strTooltip = string.format("%s<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffda69ff\">%s</P>", strTooltip, strRestLineOne)

		if nCurrentEP + nRestedEPPool > nEPDailyMax then
			strTooltip = string.format("%s<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffda69ff\">%s</P>", strTooltip, Apollo.GetString("Base_EPRestedEndsAfterLevelTooltip"))
		else
			local strRestLineTwo = String_GetWeaselString(Apollo.GetString("Base_EPRestedPoolTooltip"), Apollo.FormatNumber(nRestedEPPool, 0, true), ((nRestedEPPool + nCurrentEP)  / nEPDailyMax) * 100)
			strTooltip = string.format("%s<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffda69ff\">%s</P>", strTooltip, strRestLineTwo)
		end
	end
	
	return string.format("<P Font=\"CRB_InterfaceSmall\">%s%s</P>%s", Apollo.GetString("CRB_Level_"), unitPlayer:GetLevel(), strTooltip)
end

-----------------------------------------------------------------------------------------------
-- XP (When less than level 50)
-----------------------------------------------------------------------------------------------

function XPBar:RedrawXP()
	local nCurrentXP = GetXp() - GetXpToCurrentLevel() 		-- current amount of xp into the current level
	local nNeededXP = GetXpToNextLevel() 					-- total amount needed to move through current level
	local nRestedXP = GetRestXp() 							-- amount of rested xp
	local nRestedXPPool = GetRestXpKillCreaturePool() 		-- amount of rested xp remaining from creature kills

	if not nCurrentXP or not nNeededXP or not nNeededXP or not nRestedXP then
		return
	end
	
	local wndXPBarFill = self.wndMain:FindChild("XPBarContainer:XPBarFill")
	local wndRestXPBarFill = self.wndMain:FindChild("XPBarContainer:RestXPBarFill")
	local wndRestXPBarGoal = self.wndMain:FindChild("XPBarContainer:RestXPBarGoal")

	wndXPBarFill:SetMax(nNeededXP)
	wndXPBarFill:SetProgress(nCurrentXP)

	wndRestXPBarFill:SetMax(nNeededXP)
	wndRestXPBarFill:Show(nRestedXP and nRestedXP > 0)
	if nRestedXP and nRestedXP > 0 then
		wndRestXPBarFill:SetProgress(math.min(nNeededXP, nCurrentXP + nRestedXP))
	end

	wndRestXPBarGoal:SetMax(nNeededXP)
	wndRestXPBarGoal:Show(nRestedXP and nRestedXPPool and nRestedXP > 0 and nRestedXPPool > 0)
	if nRestedXP and nRestedXPPool and nRestedXP > 0 and nRestedXPPool > 0 then
		wndRestXPBarGoal:SetProgress(math.min(nNeededXP, nCurrentXP + nRestedXPPool))
	end

	return nCurrentXP / nNeededXP * 100
end

function XPBar:ConfigureXPTooltip(unitPlayer)
	local nCurrentXP = GetXp() - GetXpToCurrentLevel() 		-- current amount of xp into the current level
	local nNeededXP = GetXpToNextLevel() 					-- total amount needed to move through current level
	local nRestedXP = GetRestXp() 							-- amount of rested xp
	local nRestedXPPool = GetRestXpKillCreaturePool() 		-- amount of rested xp remaining from creature kills

	if not nCurrentXP or not nNeededXP or not nNeededXP or not nRestedXP then
		return
	end

	local strTooltip = string.format("<P Font=\"CRB_InterfaceSmall\">%s</P>", String_GetWeaselString(Apollo.GetString("Base_XPValue"), Apollo.FormatNumber(nCurrentXP, 0, true), Apollo.FormatNumber(nNeededXP, 0, true), nCurrentXP / nNeededXP * 100))
	if nRestedXP > 0 then
		local strRestLineOne = String_GetWeaselString(Apollo.GetString("Base_XPRested"), Apollo.FormatNumber(nRestedXP, 0, true), nRestedXP / nNeededXP * 100)
		strTooltip = string.format("%s<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffda69ff\">%s</P>", strTooltip, strRestLineOne)

		if nCurrentXP + nRestedXPPool > nNeededXP then
			strTooltip = string.format("%s<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffda69ff\">%s</P>", strTooltip, Apollo.GetString("Base_XPRestedEndsAfterLevelTooltip"))
		else
			local strRestLineTwo = String_GetWeaselString(Apollo.GetString("Base_XPRestedPoolTooltip"), Apollo.FormatNumber(nRestedXPPool, 0, false), ((nRestedXPPool + nCurrentXP)  / nNeededXP) * 100)
			strTooltip = string.format("%s<P Font=\"CRB_InterfaceSmall\" TextColor=\"ffda69ff\">%s</P>", strTooltip, strRestLineTwo)
		end
	end
	
	return string.format("<P Font=\"CRB_InterfaceSmall\">%s%s</P>%s", Apollo.GetString("CRB_Level_"), unitPlayer:GetLevel(), strTooltip)
end

-----------------------------------------------------------------------------------------------
-- Events to Redraw All
-----------------------------------------------------------------------------------------------

function XPBar:OnEnteredCombat(unitArg, bInCombat)
	if unitArg == GameLib.GetPlayerUnit() then
		self.bInCombat = bInCombat
		self:RedrawAll()
	end
end

function XPBar:OnClearCombatFlag()
	self.bInCombat = false
	self:RedrawAll()
end

function XPBar:OnXpChanged()
	if GetXp() == 0 then
		return
	end
	
	local nVisibility = Apollo.GetConsoleVariable("hud.xpBarDisplay")
	
	--NEW Player Experience: Set the xp bars to Always Show once you've started earning experience.
	if nVisibility == nil or nVisibility < 1 then
		--Trigger a HUD Tutorial
		Event_FireGenericEvent("OptionsUpdated_HUDTriggerTutorial", "xpBarDisplay")
	end
	
	self:RedrawAll()
end

function XPBar:OnPathClicked()
	Event_FireGenericEvent("PlayerPathShow")
end

function XPBar:OnXpClicked()
	Event_FireGenericEvent("ToggleCharacterWindow")
end

function XPBar:OnUpdateInventory()
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer then
		return
	end
	
	self.wndMain:FindChild("ElderGems"):SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.ElderGems), true)

	local nOccupiedInventory = #unitPlayer:GetInventoryItems() or 0
	local nTotalInventory = GameLib.GetTotalInventorySlots() or 0
	local nAvailableInventory = nTotalInventory - nOccupiedInventory

	local strOpenColor = ""
	if nOccupiedInventory == nTotalInventory then
		strOpenColor = kstrRed
		self.wndInvokeButton:ChangeArt("HUD_BottomBar:btn_HUD_InventoryFull")
	elseif nOccupiedInventory >= nTotalInventory - 3 then
		strOpenColor = kstrOrange
		self.wndInvokeButton:ChangeArt("HUD_BottomBar:btn_HUD_Inventory")
	else
		strOpenColor = kstrBlue
		self.wndInvokeButton:ChangeArt("HUD_BottomBar:btn_HUD_Inventory")
	end

	local strPrefix = ""
	
	if nOccupiedInventory < 10 then strPrefix = "<T TextColor=\"00000000\">.</T>" end
	local strAMLCode = string.format("%s<T Font=\"CRB_Pixel\" Align=\"Right\" TextColor=\"%s\">%s<T TextColor=\"%s\">/%s</T></T>", strPrefix, strOpenColor, nOccupiedInventory, kstrDarkBlue, nTotalInventory)
	self.wndInvokeForm:FindChild("InvokeBtn"):SetText(tostring(nAvailableInventory))	
	self.wndInvokeForm:FindChild("InvokeBtn"):SetTooltip(strAMLCode)

	self.wndQuestItemNotice:Show(GameLib.DoAnyItemsBeginQuest())
end

function XPBar:OnToggleFromDatachronIcon()
	Event_FireGenericEvent("InterfaceMenu_ToggleInventory")
end

function XPBar:OnKeyBindingKeyChanged(strKeyBindingName)
	if strKeyBindingName == "Store" then
		self:HelperPremiumIndicatorTooltip()
	end
end

---------------------------------------------------------------------------------------------------
-- Premium System Updates
---------------------------------------------------------------------------------------------------

function XPBar:OnPremiumTierChanged(ePremiumSystem, nTier)
	self.ePremiumSystem = ePremiumSystem
	self.nPremiumTier = nTier
	
	local bIsHybrid = self.ePremiumSystem == AccountItemLib.CodeEnumPremiumSystem.Hybrid
	local bIsVIP = self.ePremiumSystem == AccountItemLib.CodeEnumPremiumSystem.VIP
	local strPremiumPlayerTooltip = nil
	local strPremiumPlayerTitle = nil
	
	if bIsHybrid then
		if self.nPremiumTier < AccountItemLib.GetPremiumTierMax() then
			self.wndMain:FindChild("PremiumIndicator"):SetSprite("HUD_BottomBar:spr_HUD_SignatureAlert_Off")
			strPremiumPlayerTitle = Apollo.GetString("CRB_Basic")
		else
			self.wndMain:FindChild("PremiumIndicator"):SetSprite("HUD_BottomBar:spr_HUD_SignatureAlert_On")
			strPremiumPlayerTitle = Apollo.GetString("Storefront_SignatureCaps")
		end
	elseif bIsVIP then
		if self.nPremiumTier < 1 then
			self.wndMain:FindChild("PremiumIndicator"):SetSprite("HUD_BottomBar:spr_HUD_SignatureAlert_Off")
			strPremiumPlayerTitle = Apollo.GetString("CRB_Basic")
		else
			self.wndMain:FindChild("PremiumIndicator"):SetSprite("HUD_BottomBar:spr_HUD_SignatureAlert_On")
			strPremiumPlayerTitle = Apollo.GetString("Storefront_VIPPlayer")
		end
	end
	
	self:HelperPremiumIndicatorTooltip()
	self.wndMain:FindChild("PremiumTitle"):SetText(strPremiumPlayerTitle)
end

function XPBar:HelperPremiumIndicatorTooltip()
	local bIsHybrid = self.ePremiumSystem == AccountItemLib.CodeEnumPremiumSystem.Hybrid
	local bIsVIP = self.ePremiumSystem == AccountItemLib.CodeEnumPremiumSystem.VIP
	local strPremiumPlayerTooltip = nil
	
	if bIsHybrid then
		if self.nPremiumTier < AccountItemLib.GetPremiumTierMax() then
			strPremiumPlayerTooltip = string.format("<P Font=\"CRB_HeaderTiny\"><T TextColor=\"UI_WindowTitleYellow\">%s</T><T TextColor=\"Reddish\"> %s</T></P><P Font=\"CRB_InterfaceSmall\" TextColor=\"ff39b5d4\">%s</P>", Apollo.GetString("CRB_SignatureStatusColon"), Apollo.GetString("SettlerMission_Inactive"), String_GetWeaselString(Apollo.GetString("HUD_SignatureStatusInactiveDesc")))
		else
			strPremiumPlayerTooltip = string.format("<P Font=\"CRB_HeaderTiny\"><T TextColor=\"UI_WindowTitleYellow\">%s</T><T TextColor=\"UI_BtnTextGreenNormal\"> %s</T></P><P Font=\"CRB_InterfaceSmall\" TextColor=\"UI_TextHoloBody\">%s</P>", Apollo.GetString("CRB_SignatureStatusColon"), Apollo.GetString("QuestLog_Active"), String_GetWeaselString(Apollo.GetString("HUD_SignatureStatusActiveDesc")))
		end
	elseif bIsVIP then
		if self.nPremiumTier < 1 then
			strPremiumPlayerTooltip = string.format("<P Font=\"CRB_HeaderTiny\"><T TextColor=\"UI_WindowTitleYellow\">%s</T><T TextColor=\"Reddish\"> %s</T></P><P Font=\"CRB_InterfaceSmall\" TextColor=\"ff39b5d4\">%s</P>", Apollo.GetString("CRB_VIPStatusColon"), Apollo.GetString("SettlerMission_Inactive"), String_GetWeaselString(Apollo.GetString("HUD_VIPStatusInactiveDesc")))
		else
			strPremiumPlayerTooltip = string.format("<P Font=\"CRB_HeaderTiny\"><T TextColor=\"UI_WindowTitleYellow\">%s</T><T TextColor=\"UI_BtnTextGreenNormal\"> %s</T></P><P Font=\"CRB_InterfaceSmall\" TextColor=\"UI_TextHoloBody\">%s</P>", Apollo.GetString("CRB_VIPStatusColon"), Apollo.GetString("QuestLog_Active"), String_GetWeaselString(Apollo.GetString("HUD_VIPStatusActiveDesc")))
		end
	end
	
	self.wndMain:FindChild("PremiumIndicator"):SetTooltip(strPremiumPlayerTooltip)
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------
function XPBar:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors =
	{
		[GameLib.CodeEnumTutorialAnchor.Inventory] 					= true,
		[GameLib.CodeEnumTutorialAnchor.InterfaceMenuListInventory] = true,
	}
	
	if not tAnchors[eAnchor] then 
		return
	end
	
	local tAnchorMapping = 
	{
		[GameLib.CodeEnumTutorialAnchor.Inventory] 					= self.wndInvokeForm,
		[GameLib.CodeEnumTutorialAnchor.InterfaceMenuListInventory] = self.wndInvokeButton,
	}
	
	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

local BaseBarCornerInst = XPBar:new()
BaseBarCornerInst:Init()