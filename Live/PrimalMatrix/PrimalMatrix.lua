-----------------------------------------------------------------------------------------------
-- Client Lua Script for PrimalMatrix
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Item"
require "Unit"
require "AccountItemLib"
require "StorefrontLib"
require "GameLib"

local PrimalMatrix = {} 

local kcrInsufficentMoney = "Red"
local kcrSufficentMoney = "Gray"

local ktNodeTypeToName =
{
	[MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Red] = Apollo.GetString("Matrix_NodeRedName"),
	[MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Green] = Apollo.GetString("Matrix_NodeGreenName"),
	[MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Blue] = Apollo.GetString("Matrix_NodeBlueName"),
	[MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Purple] = Apollo.GetString("Matrix_NodePurpleName"),
	[MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Mixed] = Apollo.GetString("Matrix_NodeMixedName")
}

local ktRewardTypeRanking =
{
	[MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityUnlock] = 1,
	[MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityPoint] = 2,
	[MatrixWindow.CodeEnumPrimalMatrixRewardType.AMPPoint] = 3,
	[MatrixWindow.CodeEnumPrimalMatrixRewardType.RewardProperty] = 4,
	[MatrixWindow.CodeEnumPrimalMatrixRewardType.UnitProperty] = 5,
	[MatrixWindow.CodeEnumPrimalMatrixRewardType.None] = 99,
}

function PrimalMatrix:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.tWndRefs = {}
	o.bConfirmSave = true

    return o
end

function PrimalMatrix:Init()
    Apollo.RegisterAddon(self)
end

function PrimalMatrix:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("PrimalMatrix.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	self.timerErrorMessage = ApolloTimer.Create(2, false, "OnErrorMessageTimer", self)
	self.timerErrorMessage:Stop()
end

function PrimalMatrix:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	return
	{
		bConfirmSave = self.bConfirmSave
	}
end

function PrimalMatrix:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	
	if tSavedData.bConfirmSave ~= nil then
		self.bConfirmSave = tSavedData.bConfirmSave
	end
end

function PrimalMatrix:OnDocLoaded()
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
	self:OnInterfaceMenuListHasLoaded()
	
	Apollo.RegisterEventHandler("TogglePrimalMatrix", "OnTogglePrimalMatrix", self)
	
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitEnteredCombat", self)
	Apollo.RegisterEventHandler("PlayerCurrencyChanged", "OnPlayerCurrencyChanged", self)
	Apollo.RegisterEventHandler("StoreLinksRefresh", "OnRefreshStoreLink", self)
	Apollo.RegisterEventHandler("PersonaUpdateCharacterStats", "OnPersonaUpdateCharacterStats", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", "OnTutorial_RequestUIAnchor", self)
	Apollo.RegisterEventHandler("Tutorial_CalloutClosed", "OnTutorial_CalloutClosed", self)
	Apollo.RegisterEventHandler("PrimalMatrixUpdated", "OnPrimalMatrixUpdated", self)
end

function PrimalMatrix:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("InterfaceMenu_PrimalMatrix"), {"TogglePrimalMatrix", "PrimalMatrix", "Icon_Windows32_UI_CRB_InterfaceMenu_PrimalMatrix"})
end

function PrimalMatrix:OnTogglePrimalMatrix()
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() and self.tWndRefs.wndMain:IsShown() then
		self.tWndRefs.wndMain:Close()
	else
		self:OnPrimalMatrixOn()
	end
end

function PrimalMatrix:OnPrimalMatrixOn()
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		local wndMain = Apollo.LoadForm(self.xmlDoc, "MatrixForm", nil, self)
		
		self.tWndRefs.wndMain = wndMain
		self.tWndRefs.wndMatrix = wndMain:FindChild("Window")
		self.tWndRefs.wndHeader = wndMain:FindChild("Header")
		self.tWndRefs.wndHeaderHeroism = wndMain:FindChild("Header:HeroismContainer:Heroism")
		self.tWndRefs.wndHeaderCompletionProgressBar = wndMain:FindChild("Header:CompletionProgressBar")
		self.tWndRefs.wndHeaderCompletionPendingProgressBar = wndMain:FindChild("Header:CompletionPendingProgressBar")
		self.tWndRefs.wndHeaderCurrencies = wndMain:FindChild("Header:Currencies")
		self.tWndRefs.wndHeaderCurrenciesRed = wndMain:FindChild("Header:Currencies:Red")
		self.tWndRefs.wndHeaderCurrenciesGreen = wndMain:FindChild("Header:Currencies:Green")
		self.tWndRefs.wndHeaderCurrenciesBlue = wndMain:FindChild("Header:Currencies:Blue")
		self.tWndRefs.wndHeaderCurrenciesPurple = wndMain:FindChild("Header:Currencies:Purple")
		self.tWndRefs.wndHeaderRewardsBtn = wndMain:FindChild("Header:RewardsBtn")
		self.tWndRefs.wndHeaderRewardsFlyout = wndMain:FindChild("Header:RewardsBtn:Flyout")
		self.tWndRefs.wndHeaderRewardsFlyoutRewardContainer = wndMain:FindChild("Header:RewardsBtn:Flyout:RewardContainer")
		self.tWndRefs.wndHeaderExchangeBtn = wndMain:FindChild("Header:ExchangeBtn")
		self.tWndRefs.wndHeaderExchange = wndMain:FindChild("Exchange")
		self.tWndRefs.wndHeaderExchangeSource = wndMain:FindChild("Exchange:Window:Content:Source:Container")
		self.tWndRefs.wndHeaderExchangeCosts = wndMain:FindChild("Exchange:Window:Content:Costs:Container")
		self.tWndRefs.wndHeaderExchangeTransducer = wndMain:FindChild("Exchange:Window:Content:Converter:Transducer")
		self.tWndRefs.wndHeaderExchangeTransducerBtn = wndMain:FindChild("Exchange:Window:Content:Converter:Transducer:TransducerBtn")
		self.tWndRefs.wndHeaderExchangeTransducerCount = wndMain:FindChild("Exchange:Window:Content:Converter:Transducer:CountLabel")
		self.tWndRefs.wndHeaderExchangeTransducerSourceIcon = wndMain:FindChild("Exchange:Window:Content:Converter:Give:IconBacker:Icon")
		self.tWndRefs.wndHeaderExchangeTransducerSourceEditBox = wndMain:FindChild("Exchange:Window:Content:Converter:Give:NumberBoxBG:ConversionLeftEditBox")
		self.tWndRefs.wndHeaderExchangeTransducerSourceSliderBar = wndMain:FindChild("Exchange:Window:Content:Converter:SliderBar")
		self.tWndRefs.wndHeaderExchangeTransducerTargetIcon = wndMain:FindChild("Exchange:Window:Content:Converter:Receive:IconBacker:Icon")
		self.tWndRefs.wndHeaderExchangeTransducerTargetEditBox = wndMain:FindChild("Exchange:Window:Content:Converter:Receive:NumberBoxBG:ConversionLeftEditBox")
		self.tWndRefs.wndHeaderExchangeTransducerInventoryAmount = wndMain:FindChild("Exchange:Window:CurrentServiceTokens:ServiceTokens")
		self.tWndRefs.wndHeaderExchangeExchangeBtn = wndMain:FindChild("Exchange:Window:ExchangeBtn")
		self.tWndRefs.wndWelcome  = wndMain:FindChild("Welcome")
		self.tWndRefs.wndClosed  = wndMain:FindChild("Closed")
		self.tWndRefs.wndClosedMessage  = wndMain:FindChild("Closed:Dialog:Message")
		self.tWndRefs.wndErrorMessage  = wndMain:FindChild("ErrorMessage")
		self.tWndRefs.wndConfirmClose = wndMain:FindChild("ConfirmClose")
		self.tWndRefs.wndConfirmCloseMessage = wndMain:FindChild("ConfirmClose:Dialog:Message")
		self.tWndRefs.wndConfirmSave = wndMain:FindChild("ConfirmSave")
		self.tWndRefs.wndConfirmSaveSaveBtn = wndMain:FindChild("ConfirmSave:Dialog:SaveBtn")
		self.tWndRefs.wndConfirmSaveBypassBtn = wndMain:FindChild("ConfirmSave:Dialog:BypassBtn")
		self.tWndRefs.wndPending = self.tWndRefs.wndMain:FindChild("PendingState")
		self.tWndRefs.wndPendingSaveBtn = self.tWndRefs.wndMain:FindChild("PendingState:SaveChangesBtn")
		self.tWndRefs.wndPendingSaveConfirmBtn = self.tWndRefs.wndMain:FindChild("PendingState:SaveChangesConfirmBtn")
		
		self.tWndRefs.wndHeaderRewardsBtn:AttachWindow(self.tWndRefs.wndHeaderRewardsFlyout)
		self.tWndRefs.wndHeaderExchangeBtn:AttachWindow(self.tWndRefs.wndHeaderExchange)
		
		wndMain:SetTooltipType(Window.TPT_OnCursor)
		local wndTooltip = self.tWndRefs.wndMain:FindChild("Window"):LoadTooltipForm(self.xmlDoc, "Tooltip", luaCaller)
		
		self.tWndRefs.wndTooltip = wndTooltip
		self.tWndRefs.wndTooltipContent = wndTooltip:FindChild("Content")
		self.tWndRefs.wndTooltipNodeName = wndTooltip:FindChild("Content:NodeName")
		self.tWndRefs.wndTooltipErrorText = wndTooltip:FindChild("Content:ErrorText")
		self.tWndRefs.wndTooltipCurrentRank = wndTooltip:FindChild("Content:CurrentRank")
		self.tWndRefs.wndTooltipCurrentRankHeaderRank = wndTooltip:FindChild("Content:CurrentRank:Header:Rank")
		self.tWndRefs.wndTooltipNextRank = wndTooltip:FindChild("Content:NextRank")
		self.tWndRefs.wndTooltipNextRankHeaderRank = wndTooltip:FindChild("Content:NextRank:Header:Rank")
		self.tWndRefs.wndTooltipPrices = wndTooltip:FindChild("Content:Prices")
		self.tWndRefs.wndTooltipPricesRedCash = wndTooltip:FindChild("Content:Prices:RedCash")
		self.tWndRefs.wndTooltipPricesGreenCash = wndTooltip:FindChild("Content:Prices:GreenCash")
		self.tWndRefs.wndTooltipPricesBlueCash = wndTooltip:FindChild("Content:Prices:BlueCash")
		self.tWndRefs.wndTooltipPricesPurpleCash = wndTooltip:FindChild("Content:Prices:PurpleCash")
		self.tWndRefs.wndTooltipActions = wndTooltip:FindChild("Actions")
		self.tWndRefs.wndTooltipActionsPurchase = wndTooltip:FindChild("Actions:Purchase")
		self.tWndRefs.wndTooltipActionsDivider = wndTooltip:FindChild("Actions:Divider")
		self.tWndRefs.wndTooltipActionsRefund = wndTooltip:FindChild("Actions:Refund")
		self.tWndRefs.wndTooltipActionsPath = wndTooltip:FindChild("Actions:Path")

		
		self.tSources = {}
		
		local arConversions = self.tWndRefs.wndMatrix:GetResourceConversions()
		for idx, tConversion in pairs(arConversions) do
			if self.tSources[tConversion.idSource] == nil then
				self.tSources[tConversion.idSource] =
				{
					tTargets = {},
					wndSource = Apollo.LoadForm(self.xmlDoc, "ConvertSourceEntry", self.tWndRefs.wndHeaderExchangeSource, self)
				}
				
				self.tSources[tConversion.idSource].wndSource:SetData(tConversion.idSource)
				self.tSources[tConversion.idSource].wndSource:FindChild("SelectBtn"):SetData(tConversion.idSource)
				self.tSources[tConversion.idSource].wndSource:FindChild("SelectBtn:IconBacker:Icon"):SetSprite(tConversion.monSource:GetDenomInfo()[1].strSprite)
			end
			
			self.tSources[tConversion.idSource].tTargets[tConversion.idTarget] = tConversion
		end
		
		self.tWndRefs.wndHeaderExchangeSource:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		
		
		local wndRedCost = Apollo.LoadForm(self.xmlDoc, "ConvertCostEntry", self.tWndRefs.wndHeaderExchangeCosts, self)
		wndRedCost:SetData(Money.CodeEnumCurrencyType.RedEssence)
		wndRedCost:FindChild("SelectBtn:IconBacker:Icon"):SetSprite(Money.new(Money.CodeEnumCurrencyType.RedEssence):GetDenomInfo()[1].strSprite)
		
		local wndGreenCost = Apollo.LoadForm(self.xmlDoc, "ConvertCostEntry", self.tWndRefs.wndHeaderExchangeCosts, self)
		wndGreenCost:SetData(Money.CodeEnumCurrencyType.GreenEssence)
		wndGreenCost:FindChild("SelectBtn:IconBacker:Icon"):SetSprite(Money.new(Money.CodeEnumCurrencyType.GreenEssence):GetDenomInfo()[1].strSprite)
		
		local wndBlueCost = Apollo.LoadForm(self.xmlDoc, "ConvertCostEntry", self.tWndRefs.wndHeaderExchangeCosts, self)
		wndBlueCost:SetData(Money.CodeEnumCurrencyType.BlueEssence)
		wndBlueCost:FindChild("SelectBtn:IconBacker:Icon"):SetSprite(Money.new(Money.CodeEnumCurrencyType.BlueEssence):GetDenomInfo()[1].strSprite)
		
		local wndPurpleCost = Apollo.LoadForm(self.xmlDoc, "ConvertCostEntry", self.tWndRefs.wndHeaderExchangeCosts, self)
		wndPurpleCost:SetData(Money.CodeEnumCurrencyType.PurpleEssence)
		wndPurpleCost:FindChild("SelectBtn:IconBacker:Icon"):SetSprite(Money.new(Money.CodeEnumCurrencyType.PurpleEssence):GetDenomInfo()[1].strSprite)
		
		self.tWndRefs.wndHeaderExchangeCosts:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	end

	self.tWndRefs.wndMain:Invoke() -- show the window
	self.tWndRefs.wndMain:SetFocus()
	
	self.tWndRefs.wndConfirmClose:Show(false)
	
	self:UpdateCurrencyHeader(true)
	self:UpdateAllocationProgressHeader(true)
	self:UpdateHeaderHeroism()
	self:OnRefreshStoreLink()
	
	self.tWndRefs.wndHeaderRewardsBtn:SetCheck(false)
	self.tWndRefs.wndHeaderExchangeBtn:SetCheck(false)
	self.tWndRefs.wndConfirmSave:Show(false)
	self.tWndRefs.wndWelcome:Show(false)
	self.tWndRefs.wndClosed:Show(false)
	
	local wndMatrix = self.tWndRefs.wndMatrix
	wndMatrix:ResetZoom()
	
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Red, MatrixWindow.CodeEnumPrimalMatrixNodeState.Locked, "Node_Red_Locked")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Red, MatrixWindow.CodeEnumPrimalMatrixNodeState.Unlocked, "Node_Red_Unlocked")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Red, MatrixWindow.CodeEnumPrimalMatrixNodeState.Started, "Node_Red_Started")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Red, MatrixWindow.CodeEnumPrimalMatrixNodeState.Completed, "Node_Red_Completed")
	
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Green, MatrixWindow.CodeEnumPrimalMatrixNodeState.Locked, "Node_Green_Locked")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Green, MatrixWindow.CodeEnumPrimalMatrixNodeState.Unlocked, "Node_Green_Unlocked")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Green, MatrixWindow.CodeEnumPrimalMatrixNodeState.Started, "Node_Green_Started")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Green, MatrixWindow.CodeEnumPrimalMatrixNodeState.Completed, "Node_Green_Completed")
	
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Blue, MatrixWindow.CodeEnumPrimalMatrixNodeState.Locked, "Node_Blue_Locked")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Blue, MatrixWindow.CodeEnumPrimalMatrixNodeState.Unlocked, "Node_Blue_Unlocked")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Blue, MatrixWindow.CodeEnumPrimalMatrixNodeState.Started, "Node_Blue_Started")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Blue, MatrixWindow.CodeEnumPrimalMatrixNodeState.Completed, "Node_Blue_Completed")
	
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Purple, MatrixWindow.CodeEnumPrimalMatrixNodeState.Locked, "Node_Purple_Locked")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Purple, MatrixWindow.CodeEnumPrimalMatrixNodeState.Unlocked, "Node_Purple_Unlocked")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Purple, MatrixWindow.CodeEnumPrimalMatrixNodeState.Started, "Node_Purple_Unlocked")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Purple, MatrixWindow.CodeEnumPrimalMatrixNodeState.Completed, "Node_Purple_Completed")
	
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Mixed, MatrixWindow.CodeEnumPrimalMatrixNodeState.Locked, "Node_Green_Locked")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Mixed, MatrixWindow.CodeEnumPrimalMatrixNodeState.Unlocked, "Node_Green_Unlocked")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Mixed, MatrixWindow.CodeEnumPrimalMatrixNodeState.Started, "Node_Green_Started")
	wndMatrix:SetNodeButtonTemplate(MatrixWindow.CodeEnumPrimalMatrixNodeVisualType.Mixed, MatrixWindow.CodeEnumPrimalMatrixNodeState.Completed, "Node_Green_Completed")
	
	self:UpdateProgressLog()
	
	local tStarterNode = self.tWndRefs.wndMatrix:GetStarterNode()
	local nRed = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.RedEssence):GetAmount()
	local nBlue = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.BlueEssence):GetAmount()
	local nGreen = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.GreenEssence):GetAmount()
	local nPurple = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.PurpleEssence):GetAmount()
	
	if tStarterNode.nAllocations == 0 then
		if nRed < tStarterNode.tPrice.monRed:GetAmount() or nBlue < tStarterNode.tPrice.monBlue:GetAmount() or nGreen < tStarterNode.tPrice.monGreen:GetAmount() or nPurple < tStarterNode.tPrice.monPurple:GetAmount() then
			local unitPlayer = GameLib.GetPlayerUnit()
			if unitPlayer ~= nil and not unitPlayer:IsHeroismUnlocked() then
				self.tWndRefs.wndClosedMessage:SetText(Apollo.GetString("PrimalMatrix_ClosedLevel"))
				self.tWndRefs.wndClosed:Show(true)
			else
				self.tWndRefs.wndClosedMessage:SetText(Apollo.GetString("PrimalMatrix_ClosedCurrency"))
				self.tWndRefs.wndClosed:Show(not GameLib.IsTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixWelcome))
			end
		else
			self.tWndRefs.wndWelcome:Show(not GameLib.IsTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixWelcome))
		end
	else
		self.tWndRefs.wndWelcome:Show(not GameLib.IsTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixWelcome))
	end
	
	self:CheckExchangeBtnEnable()
end

-----------------------------------------------------------------------------------------------
-- PrimalMatrixForm Functions
-----------------------------------------------------------------------------------------------

function PrimalMatrix:OnConfirmSaveConfirmed(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:CheckPendingState()	
	self.tWndRefs.wndConfirmSave:Show(false)
	self.bConfirmSave = not self.tWndRefs.wndConfirmSaveBypassBtn:IsChecked()
	self.tWndRefs.wndPendingSaveBtn:Show(self.bConfirmSave)
	self.tWndRefs.wndPendingSaveConfirmBtn:Show(not self.bConfirmSave)
	
	self.idStarterNode = nil
	
	self:CheckExchangeBtnEnable()
end

function PrimalMatrix:OnConfirmSaveCancel(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndConfirmSave:Show(false)
	
	if self.idStarterNode ~= nil then
		GameLib.MarkTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixPending, false)
		Event_ShowTutorial(GameLib.CodeEnumTutorial.PrimalMatrixPending)
	end
end

function PrimalMatrix:OnSaveChanges(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	if self.bConfirmSave then
		Event_FireGenericEvent("Tutorial_HideCallout", GameLib.CodeEnumTutorialAnchor.PrimalMatrixPending)
		GameLib.MarkTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixPending, true)
		self.tWndRefs.wndConfirmSave:Show(true)
		
		self.tWndRefs.wndConfirmSaveSaveBtn:SetActionData(GameLib.CodeEnumConfirmButtonType.SavePrimalMatrix, self.tWndRefs.wndMatrix)
	end
end

function PrimalMatrix:OnRevertChanges(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self.tWndRefs.wndMatrix:Revert()
	self:CheckPendingState()
	self:UpdateCurrencyHeader(true)
	
	if self.idStarterNode ~= nil then
		GameLib.MarkTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixPending, false)
		GameLib.MarkTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixStartingNode, false)
		Event_FireGenericEvent("Tutorial_HideCallout", GameLib.CodeEnumTutorialAnchor.PrimalMatrixPending)
		Event_ShowTutorial(GameLib.CodeEnumTutorial.PrimalMatrixStartingNode)
	end
end

function PrimalMatrix:OnMouseMove(wndHandler, wndControl, x, y)
	self:OnGenerateTooltip(wndHandler, wndControl, Tooltip.TooltipGenerateType_Default, x, y)
end

function PrimalMatrix:GetRewardType(tRewards)
	local eDisplayRewardType = MatrixWindow.CodeEnumPrimalMatrixRewardType.None

	for idx, tReward in pairs(tRewards) do
		if ktRewardTypeRanking[tReward.eType] < ktRewardTypeRanking[eDisplayRewardType] then
			eDisplayRewardType = tReward.eType
		end
	end
	
	return eDisplayRewardType
end

function PrimalMatrix:SetupTooltipRankReward(wndRank, tRewards)
	local wndCurrentDetails = wndRank:FindChild("Details")
	wndCurrentDetails:DestroyChildren()
	
	local nHeroism = 0
	local nAbilityPoints = 0
	local nAMPPoints = 0
	for idx, tReward in pairs(tRewards) do
		if tReward.eType == MatrixWindow.CodeEnumPrimalMatrixRewardType.UnitProperty then
			if tReward.tUnitProperty.idProperty == Unit.CodeEnumProperties.Heroism then
				nHeroism = nHeroism + tReward.tUnitProperty.fValue
			else
				local wndDetail = Apollo.LoadForm(self.xmlDoc, "TooltipStat", wndCurrentDetails, self)
				wndDetail:FindChild("StatType"):SetText(Item.GetPropertyName(tReward.tUnitProperty.idProperty))
				wndDetail:FindChild("StatAmount"):SetText(Apollo.FormatNumber(tReward.tUnitProperty.fValue, 2, true))
			end
		elseif tReward.eType == MatrixWindow.CodeEnumPrimalMatrixRewardType.RewardProperty then
			local wndDetail = Apollo.LoadForm(self.xmlDoc, "TooltipStat", wndCurrentDetails, self)
			wndDetail:FindChild("StatType"):SetText(AccountItemLib.GetRewardPropertyName(tReward.tRewardProperty.idRewardProperty, tReward.tRewardProperty.idSubRewardProperty))
			wndDetail:FindChild("StatAmount"):SetText(tReward.tRewardProperty.fValue)
		elseif tReward.eType == MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityPoint then
			nAbilityPoints = nAbilityPoints + tReward.nAbilityPoints
		elseif tReward.eType == MatrixWindow.CodeEnumPrimalMatrixRewardType.AMPPoint then
			nAMPPoints = nAMPPoints + tReward.nAMPPoints
		elseif tReward.eType == MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityUnlock then
			local wndDetail = Apollo.LoadForm(self.xmlDoc, "TooltipAbility", wndCurrentDetails, self)
			
			local arDescParts = {}
			
			local tTooltips = tReward.splAbility:GetTooltips()
			if tTooltips ~= nil and tTooltips.strLASTooltip then
				table.insert(arDescParts, string.format('<P Font="CRB_InterfaceSmall" TextColor="UI_TextHoloTitle">%s</P>', tTooltips.strLASTooltip))
			end
			
			local tTierSpells = AbilityBook.GetAbilityInfo(tReward.splAbility:GetId(), 0)
			if tTierSpells ~= nil and tTierSpells.tTiers ~= nil and tTierSpells.tTiers[1] ~= nil and tTierSpells.tTiers[5] ~= nil and tTierSpells.tTiers[9] ~= nil then
				if tReward.nTierUnlocked >= 5 then
					table.insert(arDescParts, string.format('<P Font="CRB_InterfaceSmall" TextColor="xkcdTopaz">%s</P><P Font="CRB_InterfaceSmall" TextColor="UI_TextHoloTitle">%s</P>', String_GetWeaselString(Apollo.GetString("Tooltip_TitleReward"), Apollo.GetString("CRB_Next_Tier"), "4"), tTierSpells.tTiers[5].splObject:GetLasTierDesc()))
				end
				if tReward.nTierUnlocked >= 9 then
					table.insert(arDescParts, string.format('<P Font="CRB_InterfaceSmall" TextColor="xkcdTopaz">%s</P><P Font="CRB_InterfaceSmall" TextColor="UI_TextHoloTitle">%s</P>', String_GetWeaselString(Apollo.GetString("Tooltip_TitleReward"), Apollo.GetString("CRB_Next_Tier"), "8"), tTierSpells.tTiers[9].splObject:GetLasTierDesc()))
				end
			end
			
			wndDetail:FindChild("Text"):SetText(table.concat(arDescParts, '<P> </P>'))
			local nOldHeight = wndDetail:FindChild("Text"):GetHeight()
			wndDetail:FindChild("Text"):SetHeightToContentHeight()
			local nNewHeight = wndDetail:FindChild("Text"):GetHeight()
			
			local nLeft, nTop, nRight, nBottom = wndDetail:GetAnchorOffsets()
			wndDetail:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + (nNewHeight - nOldHeight))
		end
	end
	wndRank:FindChild("Header:Heroism:Amount"):SetText(nHeroism)
	if nAbilityPoints > 0 then
		local wndDetail = Apollo.LoadForm(self.xmlDoc, "TooltipStat", wndCurrentDetails, self)
		wndDetail:FindChild("StatType"):SetText(Apollo.GetString("Matrix_AbilityPointReward"))
		wndDetail:FindChild("StatAmount"):SetText(Apollo.FormatNumber(nAbilityPoints, 0, true))
	end
	if nAMPPoints > 0 then
		local wndDetail = Apollo.LoadForm(self.xmlDoc, "TooltipStat", wndCurrentDetails, self)
		wndDetail:FindChild("StatType"):SetText(Apollo.GetString("Matrix_AmpPointReward"))
		wndDetail:FindChild("StatAmount"):SetText(Apollo.FormatNumber(nAMPPoints, 0, true))
	end
	local nDetailHeightChange = wndCurrentDetails:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop) - wndCurrentDetails:GetHeight()
	local nLeft, nTop, nRight, nBottom = wndRank:GetAnchorOffsets()
	wndRank:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nDetailHeightChange)
end

function PrimalMatrix:OnGenerateTooltip(wndHandler, wndControl, eType, x, y)
	if wndHandler ~= wndControl then
		return
	end

	local wndMatrix = wndControl
	
	local tHexCoord = wndMatrix:GetMousePointToHexCoord(x, y)
	local tNode = wndMatrix:GetNodeAtHexCoord(tHexCoord.nX, tHexCoord.nY)
	if tNode then
		self.tWndRefs.wndTooltip:Show(true)
		
		-- Header
		local eDisplayRewardType = MatrixWindow.CodeEnumPrimalMatrixRewardType.None
		if tNode.arCurrentRewards ~= nil then
			eDisplayRewardType = self:GetRewardType(tNode.arCurrentRewards)
		elseif tNode.arNextRewards ~= nil then
			eDisplayRewardType = self:GetRewardType(tNode.arNextRewards)
		end
		
		local strName
		if eDisplayRewardType == MatrixWindow.CodeEnumPrimalMatrixRewardType.None
			or eDisplayRewardType == MatrixWindow.CodeEnumPrimalMatrixRewardType.UnitProperty
			or eDisplayRewardType == MatrixWindow.CodeEnumPrimalMatrixRewardType.RewardProperty then
			strName = String_GetWeaselString(Apollo.GetString("Matrix_NodeNameBasic"), ktNodeTypeToName[tNode.eVisualType])
		elseif eDisplayRewardType == MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityPoint then
			strName = Apollo.GetString("Matrix_NodeNameAbilityPoint")
		elseif eDisplayRewardType == MatrixWindow.CodeEnumPrimalMatrixRewardType.AMPPoint then
			strName = Apollo.GetString("Matrix_NodeNameAMPPoint")
		elseif eDisplayRewardType == MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityUnlock then
			strName = Apollo.GetString("Matrix_NodeNameAbilityUnlock")
			local tRewards
			if tNode.arCurrentRewards ~= nil then
				tRewards = tNode.arCurrentRewards
			elseif tNode.arNextRewards ~= nil then
				tRewards = tNode.arNextRewards
			end
			
			if tRewards then
				for idx, tReward in pairs(tRewards) do
					if tReward.eType == MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityUnlock then
						strName = tReward.splAbility:GetName()
						break
					end
				end
			end
		end
		
		self.tWndRefs.wndTooltipNodeName:SetText(strName)
		self.tWndRefs.wndTooltipErrorText:Show(tNode.eState == MatrixWindow.CodeEnumPrimalMatrixNodeState.Locked)
		
		-- Current Rank
		self.tWndRefs.wndTooltipCurrentRank:Show(tNode.nAllocations > 0 and tNode.arCurrentRewards ~= nil)
		if tNode.nAllocations > 0 and tNode.arCurrentRewards ~= nil then
			if eDisplayRewardType ~= MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityUnlock then
				self.tWndRefs.wndTooltipCurrentRankHeaderRank:SetText(String_GetWeaselString(Apollo.GetString("Matrix_NodeCurrentRank"), tNode.nAllocations, tNode.nMaxAllocations))
			elseif tNode.arCurrentRewards ~= nil then
				for idx, tReward in pairs(tNode.arCurrentRewards) do
					if tReward.eType == MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityUnlock then
						local tTierSpells = AbilityBook.GetAbilityInfo(tReward.splAbility:GetId(), 0)
						if tTierSpells ~= nil and tTierSpells.tTiers ~= nil and tTierSpells.tTiers[1] ~= nil and tTierSpells.tTiers[5] ~= nil and tTierSpells.tTiers[9] ~= nil then
							if tReward.nTierUnlocked > 1 then
								self.tWndRefs.wndTooltipCurrentRankHeaderRank:SetText(String_GetWeaselString(Apollo.GetString("Matrix_NodeCurrentSpellTier"), tReward.nTierUnlocked - 1))
							elseif tReward.nTierUnlocked == 1 then
								self.tWndRefs.wndTooltipCurrentRankHeaderRank:SetText(Apollo.GetString("Matrix_NodeCurrentSpellTierBase"))
							end
						end
					end
				end
			end
			self:SetupTooltipRankReward(self.tWndRefs.wndTooltipCurrentRank, tNode.arCurrentRewards)
		end
		
		-- Next Rank
		self.tWndRefs.wndTooltipNextRank:Show(tNode.nAllocations ~= tNode.nMaxAllocations and tNode.arNextRewards ~= nil)
		if tNode.nAllocations ~= tNode.nMaxAllocations and tNode.arNextRewards ~= nil then
			if eDisplayRewardType ~= MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityUnlock then
				self.tWndRefs.wndTooltipNextRankHeaderRank:SetText(String_GetWeaselString(Apollo.GetString("Matrix_NodeNextRank"), tNode.nAllocations + 1, tNode.nMaxAllocations))
			else
				for idx, tReward in pairs(tNode.arNextRewards) do
					if tReward.eType == MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityUnlock then
						local tTierSpells = AbilityBook.GetAbilityInfo(tReward.splAbility:GetId(), 0)
						if tTierSpells ~= nil and tTierSpells.tTiers ~= nil and tTierSpells.tTiers[1] ~= nil and tTierSpells.tTiers[5] ~= nil and tTierSpells.tTiers[9] ~= nil then
							if tReward.nTierUnlocked > 1 then
								self.tWndRefs.wndTooltipNextRankHeaderRank:SetText(String_GetWeaselString(Apollo.GetString("Matrix_NodeNextSpellTier"), tReward.nTierUnlocked - 1))
							elseif tReward.nTierUnlocked == 1 then
								self.tWndRefs.wndTooltipNextRankHeaderRank:SetText(Apollo.GetString("Matrix_NodeNextSpellTierBase"))
							end
						end
					end
				end
			end
			self:SetupTooltipRankReward(self.tWndRefs.wndTooltipNextRank, tNode.arNextRewards)
		end
		
		-- Price
		self.tWndRefs.wndTooltipPrices:Show(tNode.nAllocations ~= tNode.nMaxAllocations)
		
		local tPendingCosts = wndMatrix:GetTotalPendingCosts()
		
		local function SetCostWindow(wndCash, eCurrencyType, monCost, nPendingCosts)
			wndCash:SetAmount(monCost, true)
			local monCurrent = GameLib.GetPlayerCurrency(eCurrencyType)
			monCurrent:SetAmount(monCurrent:GetAmount() - nPendingCosts)
			if monCurrent:GetAmount() < monCost:GetAmount() then
				wndCash:SetTextColor(kcrInsufficentMoney)
			else
				wndCash:SetTextColor(kcrSufficentMoney)
			end
			local nLeft, nTop, nRight, nBottom = wndCash:GetAnchorOffsets()
			wndCash:SetAnchorOffsets(nLeft, nTop, nLeft + wndCash:GetDisplayWidth(), nBottom)
			wndCash:Show(monCost:GetAmount() > 0)
			
			return monCurrent:GetAmount() >= monCost:GetAmount()
		end
		
		local bAffordRed = SetCostWindow(self.tWndRefs.wndTooltipPricesRedCash, Money.CodeEnumCurrencyType.RedEssence, tNode.tPrice.monRed, tPendingCosts.nRed)
		local bAffordGreen = SetCostWindow(self.tWndRefs.wndTooltipPricesGreenCash, Money.CodeEnumCurrencyType.GreenEssence, tNode.tPrice.monGreen, tPendingCosts.nGreen)
		local bAffordBlue = SetCostWindow(self.tWndRefs.wndTooltipPricesBlueCash, Money.CodeEnumCurrencyType.BlueEssence, tNode.tPrice.monBlue, tPendingCosts.nBlue)
		local bAffordPurple = SetCostWindow(self.tWndRefs.wndTooltipPricesPurpleCash, Money.CodeEnumCurrencyType.PurpleEssence, tNode.tPrice.monPurple, tPendingCosts.nPurple)
		local bAfford = bAffordRed and bAffordGreen and bAffordBlue and bAffordPurple
		
		self.tWndRefs.wndTooltipPrices:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
		
		-- Sizing
		local nHeightChange = self.tWndRefs.wndTooltipContent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop) - self.tWndRefs.wndTooltipContent:GetHeight()
		
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndTooltip:GetAnchorOffsets()
		self.tWndRefs.wndTooltip:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeightChange)
		
		-- Actions		
		self.tWndRefs.wndTooltipActionsPurchase:Show(bAfford and tNode.eState ~= MatrixWindow.CodeEnumPrimalMatrixNodeState.Locked and tNode.nAllocations ~= tNode.nMaxAllocations)
		self.tWndRefs.wndTooltipActionsRefund:Show(tNode.eState ~= MatrixWindow.CodeEnumPrimalMatrixNodeState.Locked and tNode.nAllocations ~= tNode.nSavedAllocations)
		self.tWndRefs.wndTooltipActionsDivider:Show(self.tWndRefs.wndTooltipActionsPurchase:IsShown() and self.tWndRefs.wndTooltipActionsRefund:IsShown())
		self.tWndRefs.wndTooltipActionsPath:Show(tNode.eState == MatrixWindow.CodeEnumPrimalMatrixNodeState.Locked)
		
		self.tWndRefs.wndTooltipActions:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
		self.tWndRefs.wndTooltipActions:Show(self.tWndRefs.wndTooltipActionsPurchase:IsShown() or self.tWndRefs.wndTooltipActionsRefund:IsShown() or self.tWndRefs.wndTooltipActionsPath:IsShown())
		
		self:PositionActionText(self.tWndRefs.wndTooltipActionsRefund, Apollo.GetString("PrimalMatrix_Tooltip_RefundRank"))
		self:PositionActionText(self.tWndRefs.wndTooltipActionsPurchase, Apollo.GetString("PrimalMatrix_Tooltip_PurchaseRank"))
		self:PositionActionText(self.tWndRefs.wndTooltipActionsPath, Apollo.GetString("PrimalMatrix_Tooltip_MapPath"))
	else
		self.tWndRefs.wndTooltip:Show(false)
	end
end

function PrimalMatrix:PositionActionText(wndControl, strText)
	local wndContainer = wndControl:FindChild("Container")
	local wndText = wndContainer:FindChild("Text")
	wndText:SetAML("<T Font=\"CRB_Pixel\" TextColor=\"UI_BtnTextGreenNormal\" >"..strText.."</T>")
	
	local nContentWidth = wndText:GetContentSize() + wndContainer:FindChild("Icon"):GetWidth()
	local nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	wndContainer:SetAnchorOffsets(nLeft, nTop, nLeft + nContentWidth + 2, nBottom) -- 2 is padding on the text side to account for static space between the icon and text controls.
	wndControl:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
end

function PrimalMatrix:OnUnitEnteredCombat(unit, bInCombat)
	if unit == nil or not unit:IsThePlayer()
		or self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end
	
	self.tWndRefs.wndMain:Close()
end

function PrimalMatrix:OnPlayerCurrencyChanged()
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	self:UpdateCurrencyHeader(false)
	
	if self.tWndRefs.wndHeaderExchangeBtn:IsChecked() then
		self:OnExchangeCheck(self.tWndRefs.wndHeaderExchangeBtn, self.tWndRefs.wndHeaderExchangeBtn)
	end
end

function PrimalMatrix:OnRefreshStoreLink()
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	self.tWndRefs.wndHeaderExchangeTransducerBtn:Enable(StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.ServiceTokens))
end

function PrimalMatrix:OnPersonaUpdateCharacterStats()
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	self:UpdateHeaderHeroism()
end

function PrimalMatrix:UpdateHeaderHeroism()
	if self.tWndRefs.wndHeaderHeroism == nil or not self.tWndRefs.wndHeaderHeroism:IsValid() then
		return
	end
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then
		return
	end
	
	self.tWndRefs.wndHeaderHeroism:SetText(Apollo.FormatNumber(unitPlayer:GetHeroism(), 0, true))

	local wndContainer = self.tWndRefs.wndHeader:FindChild("HeroismContainer")
	local nIconWidth = wndContainer:FindChild("Icon"):GetWidth()
	local nContainerWidth = self.tWndRefs.wndHeaderHeroism:GetContentSize() + nIconWidth  + 10 -- 10 is padding on the text side to balance against space around the icon.
	
	local nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	wndContainer:SetAnchorOffsets(-nContainerWidth/2, nTop, nContainerWidth/2, nBottom)
end

function PrimalMatrix:UpdateAllocationProgressHeader(bInstant)
	local wndMatrix = self.tWndRefs.wndMatrix

	local nAllocations = wndMatrix:GetAllocationCount()
	local nPendingAllocations = wndMatrix:GetPendingAllocationCount()
	local nTotalAllocations = wndMatrix:GetTotalAllocationCount()
	
	self.tWndRefs.wndHeaderCompletionProgressBar:SetMax(nTotalAllocations)
	if bInstant then
		self.tWndRefs.wndHeaderCompletionProgressBar:SetProgress(nAllocations)
	else
		self.tWndRefs.wndHeaderCompletionProgressBar:SetProgress(nAllocations, nTotalAllocations * 4)
	end
	
	self.tWndRefs.wndHeaderCompletionPendingProgressBar:SetMax(nTotalAllocations)
	if bInstant then
		self.tWndRefs.wndHeaderCompletionPendingProgressBar:SetProgress(nAllocations + nPendingAllocations)
	else
		self.tWndRefs.wndHeaderCompletionPendingProgressBar:SetProgress(nAllocations + nPendingAllocations, nTotalAllocations * 4)
	end
	
end

function PrimalMatrix:UpdateCurrencyHeader(bInstant)
	local wndMatrix = self.tWndRefs.wndMatrix
	local tPendingCosts = wndMatrix:GetTotalPendingCosts()

	self.tWndRefs.wndHeaderCurrenciesRed:SetTooltip(AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.RedEssence):GetTypeString())
	local monRed = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.RedEssence)
	monRed:SetAmount(monRed:GetAmount() - tPendingCosts.nRed)
	self.tWndRefs.wndHeaderCurrenciesRed:SetAmount(monRed, bInstant)
	
	self.tWndRefs.wndHeaderCurrenciesBlue:SetTooltip(AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.BlueEssence):GetTypeString())
	local monBlue = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.BlueEssence)
	monBlue:SetAmount(monBlue:GetAmount() - tPendingCosts.nBlue)
	self.tWndRefs.wndHeaderCurrenciesBlue:SetAmount(monBlue, bInstant)
	
	self.tWndRefs.wndHeaderCurrenciesGreen:SetTooltip(AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.GreenEssence):GetTypeString())
	local monGreen = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.GreenEssence)
	monGreen:SetAmount(monGreen:GetAmount() - tPendingCosts.nGreen)
	self.tWndRefs.wndHeaderCurrenciesGreen:SetAmount(monGreen, bInstant)
	
	self.tWndRefs.wndHeaderCurrenciesPurple:SetTooltip(AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.PurpleEssence):GetTypeString())
	local monPurple = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.PurpleEssence)
	monPurple:SetAmount(monPurple:GetAmount() - tPendingCosts.nPurple)
	self.tWndRefs.wndHeaderCurrenciesPurple:SetAmount(monPurple, bInstant)
end

function PrimalMatrix:OnPrimalMatrixUpdated()
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end
	
	self.tWndRefs.wndMatrix:Revert()
	self:UpdateCurrencyHeader(true)
	self:UpdateAllocationProgressHeader(true)
	self:CheckPendingState()
	self:UpdateProgressLog()
end

function PrimalMatrix:OnNodeAllocationChanged(wndHandler, wndControl, idNode, nOld, nNew)
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	local tMouse = self.tWndRefs.wndMatrix:GetMouse()
	self:OnGenerateTooltip(self.tWndRefs.wndMatrix, self.tWndRefs.wndMatrix, Tooltip.TooltipGenerateType_Default, tMouse.x, tMouse.y)
	
	self:CheckPendingState()
	self:UpdateCurrencyHeader(false)
	self:UpdateAllocationProgressHeader(false)
	
	if not self.bConfirmSave then
		self.tWndRefs.wndPendingSaveConfirmBtn:SetActionData(GameLib.CodeEnumConfirmButtonType.SavePrimalMatrix, self.tWndRefs.wndMatrix)
	end
	
	if self.idStarterNode ~= nil and self.idStarterNode == idNode then
		if nNew < nOld then
			Event_FireGenericEvent("Tutorial_HideCallout", GameLib.CodeEnumTutorialAnchor.PrimalMatrixPending)
			GameLib.MarkTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixPending, false)
			GameLib.MarkTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixStartingNode, false)
			Event_ShowTutorial(GameLib.CodeEnumTutorial.PrimalMatrixStartingNode)
		else
			Event_FireGenericEvent("Tutorial_HideCallout", GameLib.CodeEnumTutorialAnchor.PrimalMatrixStartingNode)
			GameLib.MarkTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixStartingNode, true)
			
			self.tWndRefs.wndMatrix:DetachWindowFromNode(self.idStarterNode)
			if self.tWndRefs.wndTutorialStarterNode ~= nil and self.tWndRefs.wndTutorialStarterNode:IsValid() then
				self.tWndRefs.wndTutorialStarterNode:Destroy()
			end
			
			self.tWndRefs.wndTutorialStarterNode = nil
			
			Event_ShowTutorial(GameLib.CodeEnumTutorial.PrimalMatrixPending)
		end
	end
end

function PrimalMatrix:OnCantAffordNodeAllocation(wndHandler, wndControl, idNode)
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	self.tWndRefs.wndErrorMessage:SetText(Apollo.GetString("PrimalMatrix_NotEnoughResources"))
	self.tWndRefs.wndErrorMessage:Show(true)
	self.timerErrorMessage:Start()
end

function PrimalMatrix:OnNodeDeallocationPrevented(wndHandler, wndControl, idNode)
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	self.tWndRefs.wndErrorMessage:SetText(Apollo.GetString("PrimalMatrix_DeallocationBreaksTree"))
	self.tWndRefs.wndErrorMessage:Show(true)
	self.timerErrorMessage:Start()
end

function PrimalMatrix:OnErrorMessageTimer()
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	self.tWndRefs.wndErrorMessage:Show(false)
end

function PrimalMatrix:CheckPendingState()
	local bHasPendingChanges = self.tWndRefs.wndMatrix:HasPendingChanges()
	self.tWndRefs.wndPending:Show(bHasPendingChanges)
	self.tWndRefs.wndPendingSaveBtn:Show(self.bConfirmSave)
	self.tWndRefs.wndPendingSaveConfirmBtn:Show(not self.bConfirmSave)
end

function PrimalMatrix:OnClose(wndHandler, wndControl)
	self.tWndRefs.wndMain:Close()
end

function PrimalMatrix:OnWindowClosed(wndHandler, wndControl)
	if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() and self.tWndRefs.wndMatrix:HasPendingChanges() then
		self.tWndRefs.wndMain:Invoke()
		self.tWndRefs.wndConfirmClose:Show(true)
		
		local unitPlayer = GameLib.GetPlayerUnit()
		
		if unitPlayer and unitPlayer:IsInCombat() then
			self.tWndRefs.wndConfirmCloseMessage:SetText(Apollo.GetString("Matrix_CloseNoSaveCombatDialog"))
		else
			self.tWndRefs.wndConfirmCloseMessage:SetText(Apollo.GetString("Matrix_CloseNoSaveDialog"))
		end
	else
		if self.tWndRefs.wndWelcome:IsShown() then
			GameLib.MarkTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixWelcome, false)
		end
		
		self.tWndRefs.wndMain:Destroy()
		self.tWndRefs = {}
	end
end

function PrimalMatrix:OnCloseConfirmReturn(wndHandler, wndControl)
	self.tWndRefs.wndConfirmClose:Show(false)
end

function PrimalMatrix:OnCloseConfirmRevert(wndHandler, wndControl)
	self.tWndRefs.wndMatrix:Revert()
	self.tWndRefs.wndMain:Close()
end

function PrimalMatrix:UpdateProgressLog()
	local tRewards = self.tWndRefs.wndMatrix:GetAllRewards()
	local wndRewardMajor = self.tWndRefs.wndHeaderRewardsFlyoutRewardContainer:FindChild("RewardMajor")
	local wndRewardStats = self.tWndRefs.wndHeaderRewardsFlyoutRewardContainer:FindChild("RewardStatsContainer")
	
	wndRewardMajor:DestroyChildren()
	wndRewardStats:DestroyChildren()
	
	for idx, tAbility in pairs(tRewards[MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityUnlock]) do
		local wndRewardEntry = Apollo.LoadForm(self.xmlDoc, "RewardMajorEntry", wndRewardMajor, self)
		wndRewardEntry:SetData({ eType = MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityUnlock, idObject = tAbility.spellAbility:GetId() })
		local strAbilityName =  String_GetWeaselString(Apollo.GetString("PrimalMatrix_AbilityLabel"), tAbility.spellAbility:GetName())
		local strProgress = String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), tAbility.nCurrent, tAbility.nMax)
		wndRewardEntry:FindChild("Label"):SetText(strAbilityName)
		wndRewardEntry:FindChild("Count"):SetText(strProgress)
		if tAbility.nCurrent == tAbility.nMax then
			wndRewardEntry:FindChild("Label"):SetTextColor("UI_WindowTextTextPureGreen")
			wndRewardEntry:FindChild("Count"):SetTextColor("UI_WindowTextTextPureGreen")
		end		
	end

	local wndAMPEntry = Apollo.LoadForm(self.xmlDoc, "RewardMajorEntry", wndRewardMajor, self)
	wndAMPEntry:SetData({ eType = MatrixWindow.CodeEnumPrimalMatrixRewardType.AMPPoint, idObject = 0 })
	wndAMPEntry:FindChild("Label"):SetText(Apollo.GetString("Matrix_AmpPointReward"))
	wndAMPEntry:FindChild("Count"):SetText(String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), tRewards[MatrixWindow.CodeEnumPrimalMatrixRewardType.AMPPoint].nCurrent, tRewards[MatrixWindow.CodeEnumPrimalMatrixRewardType.AMPPoint].nMax))	
	if tRewards[MatrixWindow.CodeEnumPrimalMatrixRewardType.AMPPoint].nCurrent == tRewards[MatrixWindow.CodeEnumPrimalMatrixRewardType.AMPPoint].nMax then
		wndAMPEntry:FindChild("Label"):SetTextColor("UI_WindowTextTextPureGreen")
		wndAMPEntry:FindChild("Count"):SetTextColor("UI_WindowTextTextPureGreen")
	end
	
	local wndAPEntry = Apollo.LoadForm(self.xmlDoc, "RewardMajorEntry", wndRewardMajor, self)
	wndAPEntry:SetData({ eType = MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityPoint, idObject = 0 })
	wndAPEntry:FindChild("Label"):SetText(Apollo.GetString("Matrix_AbilityPointReward"))
	wndAPEntry:FindChild("Count"):SetText(String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), tRewards[MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityPoint].nCurrent, tRewards[MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityPoint].nMax))
	if tRewards[MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityPoint].nCurrent == tRewards[MatrixWindow.CodeEnumPrimalMatrixRewardType.AbilityPoint].nMax then
		wndAPEntry:FindChild("Label"):SetTextColor("UI_WindowTextTextPureGreen")
		wndAPEntry:FindChild("Count"):SetTextColor("UI_WindowTextTextPureGreen")
	end
	
	local nRewardMajorHeight = wndRewardMajor:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nRewardMajorLeft, nRewardMajorTop, nRewardMajorRight, nRewardMajorBottom = wndRewardMajor:GetAnchorOffsets()
	wndRewardMajor:SetAnchorOffsets(nRewardMajorLeft, nRewardMajorTop, nRewardMajorRight, nRewardMajorTop + nRewardMajorHeight)
			
	for idProperty, tUnitProperty in pairs(tRewards[MatrixWindow.CodeEnumPrimalMatrixRewardType.UnitProperty]) do
		if idProperty ~= Unit.CodeEnumProperties.Heroism then
			local wndRewardEntry = Apollo.LoadForm(self.xmlDoc, "RewardStatEntry", wndRewardStats, self)
			wndRewardEntry:SetData({ eType = MatrixWindow.CodeEnumPrimalMatrixRewardType.UnitProperty, idObject = idProperty })
			wndRewardEntry:SetTooltip(String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), tUnitProperty.fCurrent, tUnitProperty.fMax))		
			wndRewardEntry:FindChild("Label"):SetText(Item.GetPropertyName(idProperty))
			wndRewardEntry:FindChild("Count"):SetText(Apollo.FormatNumber(tUnitProperty.fCurrent, 0, true))
			if tUnitProperty.fCurrent == tUnitProperty.fMax then
				wndRewardEntry:FindChild("Label"):SetTextColor("UI_WindowTextTextPureGreen")
				wndRewardEntry:FindChild("Count"):SetTextColor("UI_WindowTextTextPureGreen")
			end
		end
	end

	for idRewardProperty, tRewardProperty in pairs(tRewards[MatrixWindow.CodeEnumPrimalMatrixRewardType.RewardProperty]) do
		local wndRewardEntry = Apollo.LoadForm(self.xmlDoc, "RewardStatEntry", wndRewardStats, self)
		wndRewardEntry:SetData({ eType = MatrixWindow.CodeEnumPrimalMatrixRewardType.RewardProperty, idObject = idRewardProperty })
		wndRewardEntry:SetTooltip(String_GetWeaselString(Apollo.GetString("CRB_NOutOfN"), Apollo.FormatNumber(tRewardProperty.fCurrent, 2, true), Apollo.FormatNumber(tRewardProperty.fMax, 2, true)))
		wndRewardEntry:FindChild("Label"):SetText(AccountItemLib.GetRewardPropertyName(idRewardProperty, 0))
		wndRewardEntry:FindChild("Count"):SetText(Apollo.FormatNumber(tRewardProperty.fCurrent, 0, true))
		if tRewardProperty.fCurrent == tRewardProperty.fMax then
			wndRewardEntry:FindChild("Label"):SetTextColor("UI_WindowTextTextPureGreen")
			wndRewardEntry:FindChild("Count"):SetTextColor("UI_WindowTextTextPureGreen")
		end			
	end	
		
	local nRewardStatsHeight = wndRewardStats:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nRewardStatsLeft, nRewardStatsTop, nRewardStatsRight, nRewardStatsBottom = self.tWndRefs.wndHeaderRewardsFlyoutRewardContainer:FindChild("RewardStats"):GetAnchorOffsets()
	self.tWndRefs.wndHeaderRewardsFlyoutRewardContainer:FindChild("RewardStats"):SetAnchorOffsets(nRewardStatsLeft, nRewardStatsTop, nRewardStatsRight, nRewardStatsTop + nRewardStatsHeight )
			
	local nRewardContainerHeight = self.tWndRefs.wndHeaderRewardsFlyoutRewardContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

end

function PrimalMatrix:OnRewardEntryMouseEnter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	self.tWndRefs.wndMatrix:HighlightRewardNodes(tData.eType, tData.idObject)
end

function PrimalMatrix:OnRewardEntryMouseExit(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndMatrix:UnhighlightRewardNodes()
end

function PrimalMatrix:ResetExchangeConverter()
	self.tWndRefs.wndHeaderExchangeTransducerCount:SetTextColor("UI_WindowTextDefault")
	self.tWndRefs.wndHeaderExchangeTransducerCount:SetText("")
	self.tWndRefs.wndHeaderExchangeTransducer:SetTooltip("")
	
	self.tWndRefs.wndHeaderExchangeTransducerSourceIcon:Show(false)
	self.tWndRefs.wndHeaderExchangeTransducerSourceEditBox:SetText("")
	self.tWndRefs.wndHeaderExchangeTransducerSourceEditBox:Enable(false)
	self.tWndRefs.wndHeaderExchangeTransducerTargetIcon:Show(false)
	self.tWndRefs.wndHeaderExchangeTransducerTargetEditBox:SetText("")
	self.tWndRefs.wndHeaderExchangeTransducerTargetEditBox:Enable(false)
	self.tWndRefs.wndHeaderExchangeTransducerSourceSliderBar:SetMinMax(0, 0)
	self.tWndRefs.wndHeaderExchangeTransducerSourceSliderBar:Enable(false)
	
	self.tWndRefs.wndHeaderExchangeExchangeBtn:Enable(false)
end

function PrimalMatrix:OnExchangeCheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	for idx, wndEntry in pairs(self.tWndRefs.wndHeaderExchangeSource:GetChildren()) do
		local idSource = wndEntry:GetData()
		local nAmount = GameLib.GetPlayerCurrency(idSource):GetAmount()
		local bCanAffordOne = false
		
		for idx, wndCost in pairs(self.tWndRefs.wndHeaderExchangeCosts:GetChildren()) do
			local tConversion = self.tSources[idSource].tTargets[wndCost:GetData()]
			if tConversion ~= nil and tConversion.nSourceCount <= nAmount then
				bCanAffordOne = true
			end
		end
		
		local wndSelectBtn = wndEntry:FindChild("SelectBtn")
		wndSelectBtn:Enable(bCanAffordOne)
		if bCanAffordOne then
			wndSelectBtn:SetTooltip("")
		else
			local mon = Money.new(1, idSource)
			wndSelectBtn:SetTooltip(String_GetWeaselString(Apollo.GetString("Matrix_ConvertNeedMoreSource"), mon:GetTypeString()))
		end
		
		wndSelectBtn:SetCheck(false)
		wndSelectBtn:SetText(Apollo.FormatNumber(nAmount, 0, true))
	end
	
	for idx, wndEntry in pairs(self.tWndRefs.wndHeaderExchangeCosts:GetChildren()) do
		local wndSelectBtn = wndEntry:FindChild("SelectBtn")
		wndSelectBtn:Enable(false)
		wndSelectBtn:SetCheck(false)
		wndSelectBtn:SetText("---")
	end
	
	local monServiceTokens = AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.ServiceToken)
	self.tWndRefs.wndHeaderExchangeTransducerInventoryAmount:SetMoneySystem(Money.CodeEnumCurrencyType.GroupCurrency, 0, 0, AccountItemLib.CodeEnumAccountCurrency.ServiceToken)
	self.tWndRefs.wndHeaderExchangeTransducerInventoryAmount:SetAmount(monServiceTokens:GetAmount())
		
	self:ResetExchangeConverter()
end

function PrimalMatrix:OnExchangeCancel(wndHandler, wndControl)
	self.tWndRefs.wndHeaderExchangeBtn:SetCheck(false)
end

function PrimalMatrix:OnConversionSourceCheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:ResetExchangeConverter()
	
	local idSource = wndControl:GetData()
	local mon = GameLib.GetPlayerCurrency(idSource)
	local nAmount = mon:GetAmount()
	
	for idx, wndEntry in pairs(self.tWndRefs.wndHeaderExchangeCosts:GetChildren()) do	
		local idTarget = wndEntry:GetData()
		local tConversion = self.tSources[idSource].tTargets[idTarget]
		
		local wndSelectBtn = wndEntry:FindChild("SelectBtn")
		wndSelectBtn:SetCheck(false)
		wndSelectBtn:Enable(idTarget ~= idSource and tConversion.nSourceCount <= nAmount)
		if idTarget == idSource then
			wndEntry:FindChild("SelectBtn"):SetText("---")
			wndSelectBtn:SetTooltip(Apollo.GetString("Matrix_CantConvertSameSourceAndTarget"))
		else
			wndEntry:FindChild("SelectBtn"):SetText(String_GetWeaselString(Apollo.GetString("Matrix_ConvertSourceForTarget"), Apollo.FormatNumber(tConversion.nSourceCount, 0, true), Apollo.FormatNumber(tConversion.nTargetCount, 0, true)))
			
			if tConversion.nSourceCount <= nAmount then
				wndSelectBtn:SetTooltip("")
			else
				wndSelectBtn:SetTooltip(String_GetWeaselString(Apollo.GetString("Matrix_ConvertNeedMoreSourceForTarget"), mon:GetTypeString()))
			end
			
			wndSelectBtn:SetData(tConversion)
		end
		
	end
end

function PrimalMatrix:OnConversionTargetCheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	local tConversion = wndControl:GetData()
	
	local monSource = GameLib.GetPlayerCurrency(tConversion.idSource)
	--self.tWndRefs.wndHeaderExchangeTransducerSourceEditBox:Enable(true)
	self.tWndRefs.wndHeaderExchangeTransducerSourceEditBox:SetText(Apollo.FormatNumber(tConversion.nSourceCount, 0, true))
	self.tWndRefs.wndHeaderExchangeTransducerSourceIcon:Show(true)
	self.tWndRefs.wndHeaderExchangeTransducerSourceIcon:SetSprite(monSource:GetDenomInfo()[1].strSprite)
	
	local monTarget = GameLib.GetPlayerCurrency(tConversion.idTarget)
	--self.tWndRefs.wndHeaderExchangeTransducerTargetEditBox:Enable(true)
	self.tWndRefs.wndHeaderExchangeTransducerTargetEditBox:SetText(Apollo.FormatNumber(tConversion.nTargetCount, 0, true))
	self.tWndRefs.wndHeaderExchangeTransducerTargetIcon:Show(true)
	self.tWndRefs.wndHeaderExchangeTransducerTargetIcon:SetSprite(monTarget:GetDenomInfo()[1].strSprite)
	
	self.tWndRefs.wndHeaderExchangeTransducerSourceSliderBar:Enable(true)
	self.tWndRefs.wndHeaderExchangeTransducerSourceSliderBar:SetMinMax(1, math.floor(monSource:GetAmount() / tConversion.nSourceCount))
	self.tWndRefs.wndHeaderExchangeTransducerSourceSliderBar:SetValue(1)
	self.tWndRefs.wndHeaderExchangeTransducerSourceSliderBar:SetData(tConversion)
	
	self.tWndRefs.wndHeaderExchangeTransducerCount:SetText(Apollo.FormatNumber(tConversion.monSurcharge:GetAmount(), 0, true))
	
	self.tWndRefs.wndHeaderExchangeExchangeBtn:Enable(true)
	self.tWndRefs.wndHeaderExchangeExchangeBtn:SetActionData(GameLib.CodeEnumConfirmButtonType.ResourceConversion, tConversion.idConversion, 1)
end

function PrimalMatrix:OnConverterSliderChanged(wndHandler, wndControl, nNew, nOld)
	if wndHandler ~= wndControl then
		return
	end
	
	local tConversion = wndControl:GetData()
	self.tWndRefs.wndHeaderExchangeTransducerSourceEditBox:SetText(Apollo.FormatNumber(tConversion.nSourceCount * nNew, 0, true))
	self.tWndRefs.wndHeaderExchangeTransducerTargetEditBox:SetText(Apollo.FormatNumber(tConversion.nTargetCount * nNew, 0, true))
	
	local nTokensRequired = tConversion.monSurcharge:GetAmount() * nNew
	self.tWndRefs.wndHeaderExchangeTransducerCount:SetText(Apollo.FormatNumber(nTokensRequired, 0, true))
	
	local monServiceTokens = AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.ServiceToken)
	if monServiceTokens:GetAmount() >= nTokensRequired then
		self.tWndRefs.wndHeaderExchangeTransducerCount:SetTextColor("UI_BtnTextGreenNormal")
		self.tWndRefs.wndHeaderExchangeTransducer:SetTooltip("")
		self.tWndRefs.wndHeaderExchangeExchangeBtn:Enable(true)
	else
		self.tWndRefs.wndHeaderExchangeTransducerCount:SetTextColor("Red")
		self.tWndRefs.wndHeaderExchangeTransducer:SetTooltip(String_GetWeaselString(Apollo.GetString("Matrix_ConvertRequiresMoreTokens"), nTokensRequired - monServiceTokens:GetAmount(), monServiceTokens:GetTypeString()))
		self.tWndRefs.wndHeaderExchangeExchangeBtn:Enable(false)
	end
	
	self.tWndRefs.wndHeaderExchangeExchangeBtn:SetActionData(GameLib.CodeEnumConfirmButtonType.ResourceConversion, tConversion.idConversion, nNew)
end

function PrimalMatrix:OnTransducerSignal(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	if StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.ServiceTokens) then
		StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.ServiceTokens)
	end
end

function PrimalMatrix:OnResourceConversioning(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:ResetExchangeConverter()
end

function PrimalMatrix:OnWelcomeContinue(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	GameLib.MarkTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixWelcome, true)
	self.tWndRefs.wndWelcome:Show(false)
	Event_ShowTutorial(GameLib.CodeEnumTutorial.PrimalMatrixCurrency)
end

function PrimalMatrix:CheckExchangeBtnEnable()
	self.tWndRefs.wndHeaderExchangeBtn:Enable(GameLib.IsTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixPending))
	if GameLib.IsTutorialViewed(GameLib.CodeEnumTutorial.PrimalMatrixPending) then
		self.tWndRefs.wndHeaderExchangeBtn:SetTooltip("")
	else
		self.tWndRefs.wndHeaderExchangeBtn:SetTooltip(Apollo.GetString("PrimalMatrix_ExchangeBtnDisabledTooltip"))
	end
end

function PrimalMatrix:OnTutorial_CalloutClosed(eAnchor)
	if eAnchor == GameLib.CodeEnumTutorialAnchor.PrimalMatrixCurrency then
		Event_ShowTutorial(GameLib.CodeEnumTutorial.PrimalMatrixExchange)
		
	elseif eAnchor == GameLib.CodeEnumTutorialAnchor.PrimalMatrixExchangeButton then
		Event_ShowTutorial(GameLib.CodeEnumTutorial.PrimalMatrixHeroism)
	
	elseif eAnchor == GameLib.CodeEnumTutorialAnchor.PrimalMatrixHeroism then
		Event_ShowTutorial(GameLib.CodeEnumTutorial.PrimalMatrixStartingNode)
		
	end
end

function PrimalMatrix:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors = 
	{
		[GameLib.CodeEnumTutorialAnchor.PrimalMatrixCurrency] = true,
		[GameLib.CodeEnumTutorialAnchor.PrimalMatrixExchangeButton] = true,
		[GameLib.CodeEnumTutorialAnchor.PrimalMatrixHeroism] = true,
		[GameLib.CodeEnumTutorialAnchor.PrimalMatrixStartingNode] = true,
		[GameLib.CodeEnumTutorialAnchor.PrimalMatrixPending] = true
	}
	
	if not tAnchors[eAnchor] or self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then 
		return
	end
	
	local tAnchorMapping =
	{
		[GameLib.CodeEnumTutorialAnchor.PrimalMatrixCurrency] = self.tWndRefs.wndHeaderCurrencies,
		[GameLib.CodeEnumTutorialAnchor.PrimalMatrixExchangeButton] = self.tWndRefs.wndHeaderExchangeBtn,
		[GameLib.CodeEnumTutorialAnchor.PrimalMatrixHeroism] = self.tWndRefs.wndHeaderHeroism,
		[GameLib.CodeEnumTutorialAnchor.PrimalMatrixStartingNode] = self.tWndRefs.wndTutorialStarterNode,
		[GameLib.CodeEnumTutorialAnchor.PrimalMatrixPending] = self.tWndRefs.wndPending
	}
	
	if (self.tWndRefs.wndTutorialStarterNode == nil or not self.tWndRefs.wndTutorialStarterNode:IsValid())
		and eAnchor == GameLib.CodeEnumTutorialAnchor.PrimalMatrixStartingNode then
		
		local wndTutorial = Apollo.LoadForm(self.xmlDoc, "StarterNodeTooltipAnchor", self.tWndRefs.wndMatrix, self)
		local tNode = self.tWndRefs.wndMatrix:GetStarterNode()
		
		self.idStarterNode = tNode.id
		self.tWndRefs.wndTutorialStarterNode = wndTutorial
		
		self.tWndRefs.wndMatrix:AttachWindowToNode(tNode.id, wndTutorial)
		tAnchorMapping[GameLib.CodeEnumTutorialAnchor.PrimalMatrixStartingNode] = wndTutorial
	end
	
	if tAnchorMapping[eAnchor] ~= nil then
		Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
	end
end

-----------------------------------------------------------------------------------------------
-- PrimalMatrix Instance
-----------------------------------------------------------------------------------------------
local PrimalMatrixInst = PrimalMatrix:new()
PrimalMatrixInst:Init()
