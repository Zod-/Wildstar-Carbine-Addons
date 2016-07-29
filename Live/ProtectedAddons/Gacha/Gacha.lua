-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gacha
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Item"
require "Apollo"
require "Window"
require "FortunesLib"
require "StorefrontLib"
require "AccountItemLib"
require "Tooltip"


local Gacha = {} 


function Gacha:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function Gacha:Init()
    Apollo.RegisterAddon(self)
end

function Gacha:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Gacha.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function Gacha:OnDocLoaded()
	if not self.xmlDoc then
		return
	end

	Apollo.RegisterEventHandler("ShowGachaUI", "OnShowGachaUI", self)
	Apollo.RegisterEventHandler("EscapeKeyPressed_Gacha", "OnHideGachaUI", self)
	Apollo.RegisterEventHandler("GameEnd", "OnGameEnd", self)
	Apollo.RegisterEventHandler("ApplicationWindowSizeChanged", "AttachControlsToScene", self)
	Apollo.RegisterEventHandler("FortuneCoinSpent", 				"OnFortuneCoinSpent", self)
	Apollo.RegisterEventHandler("TickClaimCount", 				"OnTickClaimCount", self)
	Apollo.RegisterEventHandler("CardFlipped", "OnCardFlipped", self)
	Apollo.RegisterEventHandler("FlippedCardMouseEnter", "OnFlippedCardMouseEnter", self)
	Apollo.RegisterEventHandler("FlippedCardMouseLeave", "OnFlippedCardMouseLeave", self)
	Apollo.RegisterEventHandler("RuneTooltip", "OnRuneTooltip", self)
	Apollo.RegisterEventHandler("ShinyTooltip", "OnShinyTooltip", self)
	Apollo.RegisterEventHandler("ShowPurchaseReminder", "OnShowPurchaseReminder", self)
	Apollo.RegisterEventHandler("ShowFraudReminder", "OnShowFraudReminder", self)

	self.twndTolltips = {
		[1] = Apollo.LoadForm(self.xmlDoc, "ItemTooltip", "GachaScene", self),
		[2] = Apollo.LoadForm(self.xmlDoc, "ItemTooltip", "GachaScene", self),
		[3] = Apollo.LoadForm(self.xmlDoc, "ItemTooltip", "GachaScene", self),
	}

	self.wndCloseBtn 					= Apollo.LoadForm(self.xmlDoc, "CloseBtn", "GachaScene", self)
	self.wndFortuneCoinFrame 			= Apollo.LoadForm(self.xmlDoc, "FortuneCoinFrame", "GachaScene", self)
	self.wndRewardsBtn 					= Apollo.LoadForm(self.xmlDoc, "RewardsBtn", "GachaScene", self)
	self.wndViewRewardsBtn 				= Apollo.LoadForm(self.xmlDoc, "ViewRewardsBtn", "GachaScene", self)
	self.wndRewardContainer 			= Apollo.LoadForm(self.xmlDoc, "RewardsContainer", nil, self)--Not an element of the screen so go to default stratum.
	self.wndFullScreenBlocker			= Apollo.LoadForm(self.xmlDoc, "FullScreenDialog", "GachaDialogs", self)

	self.wndSimpleTooltip = Apollo.LoadForm(self.xmlDoc, "SimpleTooltip", "GachaScene", self)
	local nLeftP, nTopP, nRightP, nBottomP = self.wndSimpleTooltip:GetAnchorOffsets()
	local nLeft, nTop, nRight, nBottom = self.wndSimpleTooltip:FindChild("Text"):GetAnchorOffsets()
	self.nTextHeightGap = nBottomP - nBottom
	self.nTextWidthGap = nRightP - nRight
	
	self.nRewardsEarned = 0
end

function Gacha:OnShowGachaUI()
	--StoreEvents
	Apollo.RegisterEventHandler("StoreLinksRefresh",								"RefreshStoreLink", self)

	self:AttachControlsToScene()
	
	self.wndCloseBtn:Show(true)
	self.wndFortuneCoinFrame:Show(true)
	self.wndRewardsBtn:Show(true)
	self.wndViewRewardsBtn:Show(true)
	self:OnFortuneCoinSpent()
	self.wndViewRewardsBtn:Enable(false)
	self.wndViewRewardsBtn:FindChild("RewardReminder"):Show(false)
	self.bHidden = false
	self.nRewardsEarned = 0
	self.wndViewRewardsBtn:SetText(String_GetWeaselString(Apollo.GetString("Fortunes_ViewRewards"), self.nRewardsEarned))

	self:HelperHideTooltips()
	self:SetUpRewardList()
	self:RefreshStoreLink()
end

function Gacha:OnHideGachaUI()
	self.wndCloseBtn:Show(false)
	self.wndFortuneCoinFrame:Show(false)
	self.wndRewardsBtn:Show(false)
	self.wndRewardContainer:Show(false)
	self.wndViewRewardsBtn:Show(false)
	self:HelperHideTooltips()
	self.wndRewardContainer:FindChild("RewardList"):DestroyChildren()--Make sure we get the newest items.
	self.bHidden = true
end

function Gacha:OnFortuneCoinSpent()
	local nAmount = AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.MysticShiny):GetAmount()
	if nAmount > 0 then
		self.wndFortuneCoinFrame:FindChild("FortuneCoinCount"):Show(true)
		self.wndFortuneCoinFrame:FindChild("FortuneCoinReminder"):Show(false)
		self.wndFortuneCoinFrame:FindChild("BuyReminder"):Show(false)
		self.wndFortuneCoinFrame:FindChild("FortuneCoinCount"):SetText(String_GetWeaselString(Apollo.GetString("Fortunes_Amount"), Apollo.FormatNumber(nAmount, 0, true)))
	else
		self.wndFortuneCoinFrame:FindChild("FortuneCoinCount"):Show(false)
		self.wndFortuneCoinFrame:FindChild("FortuneCoinReminder"):Show(true)
		self.wndFortuneCoinFrame:FindChild("BuyReminder"):Show(true)
	end
	
end

function Gacha:OnTickClaimCount()
	self.nRewardsEarned = self.nRewardsEarned + 1
	self.wndViewRewardsBtn:Enable(true)
	self.wndViewRewardsBtn:SetText(String_GetWeaselString(Apollo.GetString("Fortunes_ViewRewards"), self.nRewardsEarned))
	self.wndViewRewardsBtn:FindChild("RewardReminder"):Show(true)
end

function Gacha:OnCardFlipped(nCard)
	if not nCard or not self.twndTolltips[nCard] then
		return
	end
	AttachWindowToScene(self.twndTolltips[nCard], FortunesLib.CodeEnumModelAttachment.FXMisc01, FortunesLib.CodeEnumModelAttachment.FXMisc02, nCard)
end

function Gacha:OnFlippedCardMouseEnter(nCard, itemLooted)
	if not self.twndTolltips or self.bHidden then
		return
	end

	self:HelperHideTooltips()
	local itemEquipped = itemLooted:GetEquippedItemForItemType()
	local wndToltip = self.twndTolltips[nCard]
	
	wndToltip:Invoke()
	Tooltip.GetItemTooltipForm(self, wndToltip, itemLooted, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
end

function Gacha:OnFlippedCardMouseLeave (nCard)
	if not self.twndTolltips then
		return
	end

	local wndToltip = self.twndTolltips[nCard]
	wndToltip:SetTooltipDoc(nil)
	wndToltip:Show(false)
end

function Gacha:HelperHideTooltips()
	for idx, wndTooltip in pairs(self.twndTolltips) do
		wndTooltip:Show(false)
	end
end

function Gacha:OnRuneTooltip(bShow)
	if not self.bHidden and bShow then
		self:HelperUpdateTooltip(Apollo.GetString("Fortunes_TooltipRune"))
	else
		self.wndSimpleTooltip:Show(false, true)
	end
end

function Gacha:OnShinyTooltip(bShow)
	if not self.bHidden and bShow then
		self:HelperUpdateTooltip(Apollo.GetString("Fortunes_TooltipCoin"))
	else
		self.wndSimpleTooltip:Show(false, true)
	end
end

function Gacha:HelperUpdateTooltip(strText)
	local wndText = self.wndSimpleTooltip:FindChild("Text")
	wndText:SetAML(string.format("<T>%s</T>", strText))
	local nTextWidth, nTextHeight = wndText:SetHeightToContentHeight()
	local nLeft, nTop, nRight, nBottom = self.wndSimpleTooltip:GetAnchorOffsets()
	local nNewHeight = nTextHeight + self.nTextHeightGap
	local nNewWidth = nTextWidth + self.nTextWidthGap

	self.wndSimpleTooltip:SetAnchorOffsets(nLeft, nTop, nLeft + nNewWidth , nTop + nNewHeight)

	local tCursor = Apollo.GetMouse()
	local tDisplay = Apollo.GetDisplaySize()
	local nNewX = tCursor.x + 30
	local nNewY = tCursor.y
	if tCursor.x / tDisplay.nWidth > .80 then--If the mouse is ontop of meter
		nNewX = tCursor.x - nNewWidth - 10
	end
	self.wndSimpleTooltip:Move(nNewX, nNewY, nNewWidth, nNewHeight)

	self.wndSimpleTooltip:Show(true)	
end

function Gacha:OnShowPurchaseReminder()
	if not self.bHidden then
		self.wndFortuneCoinFrame:FindChild("PulseReminder"):SetSprite("PlayerPathContent_TEMP:spr_Crafting_TEMP_Stretch_QuestZoneRedNoLoop")
	end
end

function Gacha:OnShowFraudReminder()
	if self.bHidden then
		return
	end
	
	self.wndFullScreenBlocker:Invoke()
end

function Gacha:OnFullDialogPromptConfirmSignal(wndHandler, wndControl)
	self.wndFullScreenBlocker:Close()
end

function Gacha:OnGameEnd()
	self:HelperHideTooltips()
end

function Gacha:AttachControlsToScene()
	AttachWindowToScene(self.wndRewardsBtn, FortunesLib.CodeEnumModelAttachment.FXMisc01, FortunesLib.CodeEnumModelAttachment.FXMisc05)
	AttachWindowToScene(self.wndFortuneCoinFrame, FortunesLib.CodeEnumModelAttachment.FXMisc02, FortunesLib.CodeEnumModelAttachment.FXMisc06)
	AttachWindowToScene(self.wndRewardContainer, FortunesLib.CodeEnumModelAttachment.FXMisc03, FortunesLib.CodeEnumModelAttachment.FXMisc07)
	AttachWindowToScene(self.wndViewRewardsBtn, FortunesLib.CodeEnumModelAttachment.FXMisc04, FortunesLib.CodeEnumModelAttachment.FXMisc08)

	for idx, wndTooltip in pairs(self.twndTolltips) do
		AttachWindowToScene(wndTooltip, FortunesLib.CodeEnumModelAttachment.FXMisc01, FortunesLib.CodeEnumModelAttachment.FXMisc02, idx)
	end

	self.wndRewardsBtn:AttachWindow(self.wndRewardContainer)
end

function Gacha:SetUpRewardList()
	local tLootList = FortunesLib.GetFortunesLootList()
	if not tLootList then
		return
	end

	local tCurrenciesNames =
	{
		[AccountItemLib.CodeEnumAccountCurrency.CREDD] = "AccountInventory_NumCredd",
		[AccountItemLib.CodeEnumAccountCurrency.RealmTransfer] = "AccountInventory_RealmTransfer",
		[AccountItemLib.CodeEnumAccountCurrency.NameChange] = "AccountInventory_NameChange",
		[AccountItemLib.CodeEnumAccountCurrency.Essence] = "AccountInventory_Essence",
		[AccountItemLib.CodeEnumAccountCurrency.MysticShiny] = "AccountInventory_MysticShiny",
		[AccountItemLib.CodeEnumAccountCurrency.Omnibits] = "AccountInventory_OmniBits",
		[AccountItemLib.CodeEnumAccountCurrency.NCoins] = "AccountInventory_NCoins",
		[AccountItemLib.CodeEnumAccountCurrency.Loyalty] = "AccountInventory_Loyalty",
		[AccountItemLib.CodeEnumAccountCurrency.ServiceToken] = "AccountInventory_ServiceToken",
		[AccountItemLib.CodeEnumAccountCurrency.Protobucks] = "AccountInventory_ProtoBucks",
	}
	
	local tQualityColor =
	{
		[Item.CodeEnumItemQuality.Legendary] = "UI_WindowTextOrange",--Gold
		[Item.CodeEnumItemQuality.Superb] = "ChannelAccountWisper",--Purple
		[Item.CodeEnumItemQuality.Excellent] = "UI_TextHoloBody",
		[Item.CodeEnumItemQuality.Good] = "DispositionFriendly",
		--These bellow currently shouldn't be used but don't want UI to crash
		[Item.CodeEnumItemQuality.Average] = "AddonError",
		[Item.CodeEnumItemQuality.Inferior] = "AddonError",
	}

	local tRewardList = {}
	if tLootList.arItems ~= nil then
		for idx, itemInfo in pairs(tLootList.arItems) do
			table.insert(tRewardList, {strRewardName = itemInfo.itemReward:GetName(), eQuality = itemInfo.itemReward:GetItemQuality(), itemReward = itemInfo.itemReward, fProbability = itemInfo.fProbability})
		end
	end

	if tLootList.arAccountCurrencies ~= nil then
		for idx, monInfo in pairs(tLootList.arAccountCurrencies) do
			table.insert(tRewardList, {strRewardName = tCurrenciesNames[monInfo.monReward:GetMoneyType()].." : ".. monInfo.monReward:GetMoneyAmount(), eQuality = Item.CodeEnumItemQuality.Good, fProbability = monInfo.fProbability})--Currencies are hard coded to all be "Good" in gacha
		end
	end

	--Sort Items to Highest Quality First
	table.sort(tRewardList, function(a,b) return (a.eQuality > b.eQuality) end)

	local wndRewardList = self.wndRewardContainer:FindChild("RewardList")
	wndRewardList:DestroyChildren()
	for idx, tRewardInfo in pairs(tRewardList) do
		local wndListItem = Apollo.LoadForm(self.xmlDoc, "ListItem", wndRewardList, self)

		local wndTitle = wndListItem:FindChild("Title")
		wndTitle:SetTextColor(tQualityColor[tRewardInfo.eQuality])
		wndTitle:SetText(tRewardInfo.strRewardName)
		local wndItemIcon = wndListItem:FindChild("ItemIcon")
		if tRewardInfo.itemReward then
			wndItemIcon:GetWindowSubclass():SetItem(tRewardInfo.itemReward)
			wndListItem:SetData(tRewardInfo.itemReward)
		end

		local strProbability = ""
		if tRewardInfo.fProbability then
			strProbability = string.format("%03.2f", tRewardInfo.fProbability) .. "%"
		end
		wndListItem:FindChild("Probability"):SetText(strProbability)
	end
	wndRewardList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function Gacha:OnRewardListCloseBtn(wndHandler, wndControl)
	self.wndRewardContainer:Show(false)
end

function Gacha:OnGenerateListItemTooltip(wndHandler, wndControl)
	if wndHandler ~= wndControl or not wndControl:GetData() then
		return
	end
	
	Tooltip.GetItemTooltipForm(self, wndHandler, wndControl:GetData(), {bPrimary = true, bSelling = false})
end

function Gacha:OnBuyBtn()
	self:OnHideGachaUI()
	OpenLinkToStore(StorefrontLib.CodeEnumStoreLink.MysticShiny)
end

function Gacha:CloseGacha() 
	CloseGacha() 
	self:OnHideGachaUI() 
end

function Gacha:OnViewRewardsBtn()
	self:OnHideGachaUI()
	OpenInventory()
	self.wndCloseBtn:Show(false)
end

-----------------------------------------------------------------------------------------------
-- Store Events
-----------------------------------------------------------------------------------------------

function Gacha:RefreshStoreLink()
	if self.bHidden then--Make sure our UI has loaded.
		return
	end

	self.wndFortuneCoinFrame:FindChild("Button_Buy"):Enable(StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.MysticShiny))
end

-----------------------------------------------------------------------------------------------
-- Gacha Instance
-----------------------------------------------------------------------------------------------
local GachaInst = Gacha:new()
GachaInst:Init()
