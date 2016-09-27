-----------------------------------------------------------------------------------------------
-- Client Lua Script for RecallFrame
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
require "HousingLib"
require "HousingLib"
require "Unit"
 
-----------------------------------------------------------------------------------------------
-- RecallFrame Module Definition
-----------------------------------------------------------------------------------------------
local RecallFrame = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local knBottomPadding = 30
local knTopPadding = 42
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function RecallFrame:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function RecallFrame:Init()
    Apollo.RegisterAddon(self, nil, nil, {"ActionBarFrame"})
end
 

-----------------------------------------------------------------------------------------------
-- RecallFrame OnLoad
-----------------------------------------------------------------------------------------------
function RecallFrame:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("RecallFrame.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	self.bActionBarReady = false
	
	Apollo.RegisterEventHandler("ActionBarReady", "OnActionBarReady", self)
end

function RecallFrame:OnActionBarReady()
	self.bActionBarReady = true
	self:OnDocumentReady()
end

function RecallFrame:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	if not self.bActionBarReady or self.wndMain then
		return
	end

	Apollo.RegisterEventHandler("ChangeWorld", 					"OnChangeWorld", self)
	Apollo.RegisterEventHandler("HousingNeighborhoodRecieved", 	"OnNeighborhoodsUpdated", self)
	Apollo.RegisterEventHandler("GuildResult", 					"OnGuildResult", self)
	Apollo.RegisterEventHandler("AbilityBookChange", 			"OnAbilityBookChange", self)
	
	Apollo.RegisterEventHandler("CharacterCreated", 			"RefreshDefaultCommand", self)
	Apollo.RegisterEventHandler("PersonaUpdateCharacterStats", 	"RefreshDefaultCommand", self)
	Apollo.RegisterEventHandler("OptionsUpdated_HUDPreferences","RefreshDefaultCommand", self)

	Apollo.RegisterEventHandler("AccountCurrencyChanged", 		"GenerateBindList", self)

	Apollo.RegisterTimerHandler("RefreshRecallTimer", 			"RefreshDefaultCommand", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 	"OnTutorial_RequestUIAnchor", self)
	
	-- load our forms
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "RecallFrameForm", "FixedHudStratum", self)
	self.wndMenu = Apollo.LoadForm(self.xmlDoc, "RecallSelectionMenu", nil, self)
	self.wndMain:FindChild("RecallOptionToggle"):AttachWindow(self.wndMenu)
    
    self.tCoolDowns = {}
	self:RefreshDefaultCommand()
end

-----------------------------------------------------------------------------------------------
-- RecallFrame Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

	
function RecallFrame:RefreshDefaultCommand()
	if GameLib.GetDefaultRecallCommand() == nil then
		self:ResetDefaultCommand()
	elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.BindPoint then
		if GameLib.HasBindPoint() == false then 	
			self:ResetDefaultCommand()
		end
	elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.House then
		if HousingLib.IsResidenceOwner() == false then 	
			self:ResetDefaultCommand()
		end
	elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.Warplot then
		local bNeedsReset = true
		-- Determine if this player is in a WarParty
		for key, guildCurr in pairs(GuildLib.GetGuilds()) do
			if guildCurr:GetType() == GuildLib.GuildType_WarParty then
				bNeedsReset = false
				break
			end
		end
		if bNeedsReset then
			self:ResetDefaultCommand()
		end
	elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.Illium then
		local bNeedsReset = false
		for idx, tSpell in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Misc) or {}) do
			if not tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportIlliumSpell():GetBaseSpellId() then
				bNeedsReset = true
			end
		end
		if bNeedsReset then
			self:ResetDefaultCommand()
		end
	elseif GameLib.GetDefaultRecallCommand() == GameLib.CodeEnumRecallCommand.Thayd then
		local bNeedsReset = false
		for idx, tSpell in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Misc) or {}) do
			if not tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportThaydSpell():GetBaseSpellId() then
				bNeedsReset = true
			end
		end
		if bNeedsReset then
			self:ResetDefaultCommand()
		end
	end

	local wndRecallActionBtn = self.wndMain:FindChild("RecallActionBtn")
	local eDefaultCommand = GameLib.GetDefaultRecallCommand()

	--Can use all content ids, but if it was a bind point, make sure the player has bind point.	
	if eDefaultCommand ~= nil and 
		(eDefaultCommand == GameLib.CodeEnumRecallCommand.BindPoint and GameLib.HasBindPoint() or eDefaultCommand ~= GameLib.CodeEnumRecallCommand.BindPoint) then
		local tContent = wndRecallActionBtn:GetContent()
		if tContent and tContent.spell then
			local tData = {eContentId = eDefaultCommand, spell = tContent.spell}
			wndRecallActionBtn:SetData(tData)
		end

		wndRecallActionBtn:SetContentId(eDefaultCommand)

		--Toggle Visibility based on ui preference
		local unitPlayer = GameLib.GetPlayerUnit()
		local nVisibility = Apollo.GetConsoleVariable("hud.SkillsBarDisplay")
		
		if nVisibility == 2 then --always off
			self.wndMain:Show(false)
		elseif nVisibility == 3 then --on in combat
			self.wndMain:Show(unitPlayer:IsInCombat())	
		elseif nVisibility == 4 then --on out of combat
			self.wndMain:Show(not unitPlayer:IsInCombat())
		else
			self.wndMain:Show(true)
		end
	else
		self.wndMain:Show(false)--Hide unless valid command.
	end
end

function RecallFrame:ResetDefaultCommand()
	local bHasWarplot = false
	-- Determine if this player is in a WarParty
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr:GetType() == GuildLib.GuildType_WarParty then
			bHasWarplot = true
			break
		end
	end
	
	local bHasIllium = false
	local bHasThyad = false
	for idx, tSpell in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Misc) or {}) do
		if tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportThaydSpell():GetBaseSpellId() then
			bHasThyad = true
		end
		if tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportIlliumSpell():GetBaseSpellId() then
			bHasIllium = true
		end
	end

	if GameLib.HasBindPoint() then 	
		GameLib.SetDefaultRecallCommand(GameLib.CodeEnumRecallCommand.BindPoint)
	elseif HousingLib.IsResidenceOwner() == true then
		GameLib.SetDefaultRecallCommand(GameLib.CodeEnumRecallCommand.House)	
	elseif bHasWarplot then
		GameLib.SetDefaultRecallCommand(GameLib.CodeEnumRecallCommand.Warplot)
	elseif bHasIllium then
		GameLib.SetDefaultRecallCommand(GameLib.CodeEnumRecallCommand.Illium)
	elseif bHasThyad then
		GameLib.SetDefaultRecallCommand(GameLib.CodeEnumRecallCommand.Thayd)
	else
		GameLib.SetDefaultRecallCommand(GameLib.CodeEnumRecallCommand.BindPoint)
	end
end

function RecallFrame:OnGenerateTooltip(wndControl, wndHandler, eType, spell)
	if wndControl ~= wndHandler then
		return
	end

	if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
		Tooltip.GetSpellTooltipForm(self, wndControl, spell)
	end
end

-----------------------------------------------------------------------------------------------
-- RecallFrameForm Functions
-----------------------------------------------------------------------------------------------

function RecallFrame:OnRecallOptionToggle(wndHandler, wndControl, eMouseButton)
	if wndControl:IsChecked() then
		self:GenerateBindList()
		self.wndMenu:Invoke()
	else
		self:CloseMenu()
	end
end

function RecallFrame:GenerateBindList()
	local tRecallPoints = {}
	self.wndMenu:FindChild("Content"):DestroyChildren()

	if GameLib.HasBindPoint() then
		table.insert(tRecallPoints, GameLib.CodeEnumRecallCommand.BindPoint)
	end
	
	if HousingLib.IsResidenceOwner() then
		table.insert(tRecallPoints, GameLib.CodeEnumRecallCommand.House)
	end

	-- Determine if this player is in a WarParty
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr:GetType() == GuildLib.GuildType_WarParty then
			table.insert(tRecallPoints, GameLib.CodeEnumRecallCommand.Warplot)
			break
		end
	end

	for idx, tSpell in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Misc) or {}) do
		if tSpell.bIsActive then
			if tSpell.nId == GameLib.GetTeleportIlliumSpell():GetBaseSpellId() then
				table.insert(tRecallPoints, GameLib.CodeEnumRecallCommand.Illium)
			end

			if tSpell.nId == GameLib.GetTeleportThaydSpell():GetBaseSpellId() then
				table.insert(tRecallPoints, GameLib.CodeEnumRecallCommand.Thayd)
			end
		end
	end

	
	for idx, eRecallData in pairs(tRecallPoints) do
		self:BuildRecallEntry(eRecallData)
	end

	local nNewHeight = self.wndMenu:FindChild("Content"):ArrangeChildrenVert()
	local nLeft, nTop, nRight, nBottom = self.wndMenu:GetAnchorOffsets()
	self.wndMenu:SetAnchorOffsets(nLeft, nBottom -(nNewHeight + knBottomPadding + knTopPadding), nRight, nBottom)
end

function RecallFrame:CloseMenu()
	self.wndMenu:FindChild("Content"):DestroyChildren()
	for idx, tCoolDownInfo in pairs(self.tCoolDowns) do
		tCoolDownInfo.timer:Stop()
	end

	self.tCoolDowns = {}
	self.wndMenu:Close()
end
function RecallFrame:BuildRecallEntry(eContent)
	local wndRecallEntry = Apollo.LoadForm(self.xmlDoc, "RecallEntry", self.wndMenu:FindChild("Content"), self)
	local wndRecallActionBtn = wndRecallEntry:FindChild("RecallActionBtn")
	local wndCooldownBtn = wndRecallEntry:FindChild("CooldownCastBtn")
	wndRecallActionBtn:SetContentId(eContent)
	wndCooldownBtn:SetContentId(eContent)

	local tContent = wndRecallActionBtn:GetContent()
	if tContent and tContent.spell then
		local tData = {eContentId = eContent, spell = tContent.spell}
		wndRecallEntry:SetData(tData)
		wndCooldownBtn:SetData(tData)
		wndRecallActionBtn:SetData(tData)

		local monCost = tContent.spell:GetSpellServiceTokenCost()
		local nCoolDown = tContent.spell:GetCooldownRemaining()--In Seconds
		if nCoolDown > 0 then
			self.tCoolDowns[eContent] = { spell = tContent.spell, wndRecallEntry = wndRecallEntry, timer = ApolloTimer.Create(nCoolDown, false, "OnCooldownTimer", self)}
		end

		wndRecallEntry:FindChild("CostContainer"):Show(nCoolDown > 0)
		wndRecallEntry:FindChild("FreeContainer"):Show(nCoolDown <= 0)

		local wndCost = wndRecallEntry:FindChild("Cost")
		wndCost:SetAmount(monCost or 0, true)

		local colorCostText = ApolloColor.new("UI_TextMetalBodyHighlight")
		local nPlayerAmount = AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.ServiceToken):GetAmount()
		if monCost and monCost:GetAmount() > nPlayerAmount then
			colorCostText = ApolloColor.new("AddonError")
		end
		wndCost:SetTextColor(colorCostText)
	end
end

function RecallFrame:OnCooldownTimer()
	for eContent, tCoolDownInfo in pairs(self.tCoolDowns) do
		if tCoolDownInfo.wndRecallEntry:IsValid() then
			local nCoolDown = tCoolDownInfo.spell:GetCooldownRemaining()
			tCoolDownInfo.wndRecallEntry:FindChild("CostContainer"):Show(nCoolDown > 0)
			tCoolDownInfo.wndRecallEntry:FindChild("FreeContainer"):Show(nCoolDown <= 0)
		end
	end
end

function RecallFrame:OnRecallBtn(wndControl, wndHandler)
	local tData = wndControl:GetData()
	if not tData or (tData and not tData.eContentId) then
		return
	end

	GameLib.SetDefaultRecallCommand(tData.eContentId)
	wndControl:SetContentId(tData.eContentId)
	self.wndMain:FindChild("RecallActionBtn"):SetContentId(tData.eContentId)
	self:CloseMenu()
end

function RecallFrame:OnCloseBtn()
	self:CloseMenu()
end

function RecallFrame:OnChangeWorld()
	self.bHaveNeighborhoods = false
	self:CloseMenu()
end

function RecallFrame:OnGuildResult(guildCurr, strName, nRank, eResult) -- guild object, name string, Rank, result enum
	local bRefresh = false

	if eResult == GuildLib.GuildResult_GuildDisbanded then
		bRefresh = true
	elseif eResult == GuildLib.GuildResult_KickedYou then
		bRefresh = true
	elseif eResult == GuildLib.GuildResult_YouQuit then
		bRefresh = true
	elseif eResult == GuildLib.GuildResult_YouJoined then
		bRefresh = true
	elseif eResult == GuildLib.GuildResult_YouCreated then
		bRefresh = true
	end
				
	if bRefresh then
		self:CloseMenu()
		-- Process on the next frame.
		Apollo.CreateTimer("RefreshRecallTimer", 0.001, false)
	end
end

function RecallFrame:OnAbilityBookChange()
	self:CloseMenu()
	-- Process on the next frame.
	Apollo.CreateTimer("RefreshRecallTimer", 0.001, false)
end

function RecallFrame:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors = 
	{
		[GameLib.CodeEnumTutorialAnchor.Recall] = true,
	}
	
	if not tAnchors[eAnchor] then
		return
	end
	
	local tAnchorMapping = 
	{
		[GameLib.CodeEnumTutorialAnchor.Recall] = self.wndMain,
	}
	
	if tAnchorMapping[eAnchor] then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

-----------------------------------------------------------------------------------------------
-- RecallFrame Instance
-----------------------------------------------------------------------------------------------
local RecallFrameInst = RecallFrame:new()
RecallFrameInst:Init()