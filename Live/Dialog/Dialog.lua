-----------------------------------------------------------------------------------------------
-- Client Lua Script for ChallengeLog
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "DialogSys"
require "Quest"
require "DialogResponse"
require "CommDialog"

local Dialog = {}

-- TODO Hardcoded Colors for Items
local karEvalColors =
{
	[Item.CodeEnumItemQuality.Inferior] 		= ApolloColor.new("ItemQuality_Inferior"),
	[Item.CodeEnumItemQuality.Average] 			= ApolloColor.new("ItemQuality_Average"),
	[Item.CodeEnumItemQuality.Good] 			= ApolloColor.new("ItemQuality_Good"),
	[Item.CodeEnumItemQuality.Excellent] 		= ApolloColor.new("ItemQuality_Excellent"),
	[Item.CodeEnumItemQuality.Superb] 			= ApolloColor.new("ItemQuality_Superb"),
	[Item.CodeEnumItemQuality.Legendary] 		= ApolloColor.new("ItemQuality_Legendary"),
	[Item.CodeEnumItemQuality.Artifact]		 	= ApolloColor.new("ItemQuality_Artifact"),
}

local kcrDefaultOptionColor = ApolloColor.new("UI_TextHoloBody")
local kcrHighlightOptionColor = ApolloColor.new("UI_TextHoloBodyHighlight")
local kstrRewardColor = "UI_TextHoloTitle "
local kstrVendorColor = "UI_BtnTextHoloListNormal"
local kstrGoodbyeColor = "UI_TextHoloBody"
local kcrMoreInfoColor = "UI_TextHoloBody"
local kcrDefaultColor = ApolloColor.new("UI_BtnTextHoloListNormal")

local knMaxRewardItemsShown = 4
function Dialog:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	o.bShowPvpFlagWarning = true

	return o
end

function Dialog:Init()
	Apollo.RegisterAddon(self)
end

function Dialog:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	if tSavedData and tSavedData.bShowPvpFlagWarning then
		self.bShowPvpFlagWarning = tSavedData.bShowPvpFlagWarning
		Event_FireGenericEvent("Dialog_ShowPvpFlagWarningChanged", self.bShowPvpFlagWarning)
	end
end

function Dialog:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	
	local tSavedData =
	{
		bShowPvpFlagWarning = self.bShowPvpFlagWarning
	}
	return tSavedData
end

---------------------------------------------------------------------------------------------------
-- Dialog EventHandlers
---------------------------------------------------------------------------------------------------
function Dialog:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Dialog.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Dialog:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	Apollo.LoadSprites("UI\\Dialog\\DialogSprites.xml") -- Old
	Apollo.RegisterEventHandler("Dialog_ShowState", 							"OnDialog_ShowState", self)
	Apollo.RegisterEventHandler("Dialog_Close", 								"OnDialog_Close", self)
	Apollo.RegisterEventHandler("RequestShowPvpFlagWarningState",				"OnRequestShowPvpFlagWarningState", self)
	Apollo.RegisterEventHandler("OptionsInterface_ShowPvpFlagWarningChanged",	"OnOptionsInterface_ShowPvpFlagWarningChanged", self)
	Apollo.RegisterEventHandler("KeyBindingKeyChanged",							"OnKeyBindingUpdated", self)
	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 					"OnTutorial_RequestUIAnchor", self)

	self.wndPlayer = Apollo.LoadForm(self.xmlDoc, "PlayerWindow", nil, self)
	self.wndPlayer:ToFront()
	self.nWndPlayerLeft, self.nWndPlayerTop, self.nWndPlayerRight, self.nWndPlayerBottom = self.wndPlayer:GetAnchorOffsets()
	self.wndPlayer:Show(false, true)

	self.wndNpc = Apollo.LoadForm(self.xmlDoc, "NpcWindow", nil, self)
	self.nWndNpcLeft, self.nWndNpcTop, self.nWndNpcRight, self.nWndNpcBottom = self.wndNpc:GetAnchorOffsets()
	self.wndNpc:Show(false, true)

	self.wndItem = Apollo.LoadForm(self.xmlDoc, "ItemWindow", nil, self)
	self.nWndItemLeft, self.nWndItemTop, self.nWndItemRight, self.nWndItemBottom = self.wndItem:GetAnchorOffsets()
	self.wndItem:Show(false, true)

	self.bRewardPicked = false
	
	Event_FireGenericEvent("Dialog_ShowPvpFlagWarningChanged", self.bShowPvpFlagWarning)

	self.timerUpdate = ApolloTimer.Create(0.050, true, "OnUpdateTimer", self)
	self.timerUpdate:Stop()
end

---------------------------------------------------------------------------------------------------
-- New Player Bubble Methods
---------------------------------------------------------------------------------------------------
function Dialog:OnDialog_Close()
	self.wndPlayer:Close()
	self.wndItem:Close()
	self.wndNpc:Close()
	self.timerUpdate:Stop()
end

function Dialog:OnDialog_ShowState(eState, queCurrent)
	local idQuest = 0
	if queCurrent and queCurrent:GetId() then
		idQuest = queCurrent:GetId()
	end

	self.bRewardPicked = false

	if eState == DialogSys.DialogState_Inactive or
		eState == DialogSys.DialogState_Vending or
		eState == DialogSys.DialogState_Training or
		eState == DialogSys.DialogState_TradeskillTraining or
		eState == DialogSys.DialogState_CraftingStation then

		self:OnDialog_Close() -- Close if they click vending/training, as we open another window
		return
	end

	-- Player Window
	local tResponseList = DialogSys.GetResponses(idQuest)
	if not tResponseList or #tResponseList == 0 then
		self:OnDialog_Close()
		return
	end

	self:DrawResponses(eState, idQuest, tResponseList)

	-- NPC Window or Item Window when it's not a comm call
	if DialogSys.GetNPC() and not DialogSys.IsItemQuestGiver() and DialogSys.GetCommCreatureId() == nil then
		self:DrawNpcBubble(self.wndNpc, eState, idQuest)
	elseif DialogSys.GetCommCreatureId() == nil then
		self:DrawItemBubble(self.wndItem, eState, idQuest)
	end
	self.timerUpdate:Start()
end

function Dialog:DrawResponses(eState, idQuest, tResponseList)
	self.wndPlayer:FindChild("ResponseItemContainer"):DestroyChildren()
	self.wndPlayer:FindChild("GoodbyeContainer"):Show(false)
	self.wndPlayer:FindChild("VendorContainer"):Show(false)
	self.wndPlayer:FindChild("TopSummaryText"):Show(false)
	self.wndPlayer:FindChild("QuestTaskText"):Show(false)
	local nOnGoingHeight = 0

	-- Top Summary Text (only shows up for quests and if there are rewards)
	local queCurr = DialogSys.GetViewableQuest(idQuest)
	local strTopResponseText = DialogSys.GetResponseText()
	if queCurr and queCurr:GetRewardData() and #queCurr:GetRewardData() > 0 and strTopResponseText and Apollo.StringLength(strTopResponseText) > 0 then
		self.wndPlayer:FindChild("TopSummaryText"):SetAML("<P Font=\"CRB_InterfaceMedium\" TextColor=\""..kstrRewardColor.."\">"..strTopResponseText.."</P>")
		self.wndPlayer:FindChild("TopSummaryText"):SetHeightToContentHeight()
		self.wndPlayer:FindChild("TopSummaryText"):Show(true)
		local nLeft, nTop, nRight, nBottom = self.wndPlayer:FindChild("TopSummaryText"):GetAnchorOffsets()
		self.wndPlayer:FindChild("TopSummaryText"):SetAnchorOffsets(nLeft, nTop, nRight, nBottom + 8) -- TODO: Hardcoded!  -- +8 is bottom padding
		nOnGoingHeight = nOnGoingHeight + (nBottom - nTop) + 8

	end

	-- Rest of Responses
	local nResponseHeight = 0
	for idx, drResponse in ipairs(tResponseList) do
		local eResponseType = drResponse:GetType()
		local wndCurr = nil
		if eResponseType == DialogResponse.DialogResponseType_ViewVending then

			wndCurr = self.wndPlayer:FindChild("VendorContainer")
			wndCurr:FindChild("VendorText"):SetAML("<P Font=\"CRB_InterfaceMedium\" TextColor=\""..kstrVendorColor.."\">"..drResponse:GetText().."</P>")
			wndCurr:FindChild("VendorIcon"):SetSprite(self:HelperComputeIconPath(eResponseType))
			wndCurr:FindChild("VendorBtn"):SetData(drResponse)
			wndCurr:Show(true)
			nOnGoingHeight = nOnGoingHeight + self.wndPlayer:FindChild("VendorContainer"):GetHeight()

		elseif eResponseType == DialogResponse.DialogResponseType_Goodbye then

			wndCurr = self.wndPlayer:FindChild("GoodbyeContainer")
			wndCurr:FindChild("GoodbyeText"):SetAML("<P Font=\"CRB_InterfaceMedium\" TextColor=\""..kstrGoodbyeColor.."\">"..drResponse:GetText().."</P>")
			wndCurr:FindChild("GoodbyeIcon"):SetSprite(self:HelperComputeIconPath(eResponseType))
			wndCurr:FindChild("GoodbyeBtn"):SetData(drResponse)
			wndCurr:Show(true)
			nOnGoingHeight = nOnGoingHeight + self.wndPlayer:FindChild("GoodbyeContainer"):GetHeight()

		elseif eResponseType == DialogResponse.DialogResponseType_QuestComplete then

			wndCurr = Apollo.LoadForm(self.xmlDoc, "ResponseItem", self.wndPlayer:FindChild("ResponseItemContainer"), self)
			self:HelperComputeRewardIcon(wndCurr, drResponse:GetRewardId(), queCurr:GetRewardData().arRewardChoices)
			wndCurr:FindChild("ResponseItemText"):SetData(drResponse:GetText())
			wndCurr:FindChild("ResponseItemText"):SetText(drResponse:GetText())
			wndCurr:FindChild("ResponseItemText"):SetFont("CRB_InterfaceMedium")
			wndCurr:FindChild("ResponseItemText"):SetTextColor(self:HelperComputeRewardTextColor(drResponse:GetRewardId(), DialogSys.GetViewableQuest(idQuest):GetRewardData()))
			wndCurr:FindChild("ResponseItemBtn"):SetData(drResponse)
			nResponseHeight = nResponseHeight + wndCurr:GetHeight()
		else
			
			local queResponse = DialogSys.GetViewableQuest(drResponse:GetQuestId())
			local nConLevel = queResponse and queResponse:GetTitle() == drResponse:GetText() and queResponse:GetConLevel() or 0
			local strText = nConLevel > 0 and string.format("%s (%s)", drResponse:GetText(), nConLevel) or drResponse:GetText()
			
			local crTextColor = eResponseType == DialogResponse.DialogResponseType_QuestMoreInfo and kcrMoreInfoColor or kcrDefaultColor
			wndCurr = Apollo.LoadForm(self.xmlDoc, "ResponseItem", self.wndPlayer:FindChild("ResponseItemContainer"), self)
			wndCurr:FindChild("ResponseItemIcon"):SetSprite(self:HelperComputeIconPath(eResponseType))
			wndCurr:FindChild("ResponseItemText"):SetText(strText)
			wndCurr:FindChild("ResponseItemText"):SetFont("CRB_InterfaceMedium")
			wndCurr:FindChild("ResponseItemText"):SetTextColor(crTextColor)
			wndCurr:FindChild("ResponseItemBtn"):SetData(drResponse)
			nResponseHeight = nResponseHeight + wndCurr:GetHeight()
		end
	end
	self.wndPlayer:FindChild("ResponseItemContainer"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return b:FindChild("ResponseItemCantUse"):IsShown() end)

	local nLeft, nTop, nRight, nBottom = self.wndPlayer:FindChild("ResponseItemContainer"):GetAnchorOffsets()
	self.wndPlayer:FindChild("ResponseItemContainer"):SetAnchorOffsets(nLeft, nTop, nRight, nTop + nResponseHeight)

	self.wndPlayer:FindChild("PlayerWindowContainer"):ArrangeChildrenVert()

	Event_FireGenericEvent("Test_MouseReturnSignal") -- TODO: possibly remove

	self.wndPlayer:SetAnchorOffsets(self.nWndPlayerLeft, self.nWndPlayerTop, self.nWndPlayerRight, self.nWndPlayerBottom + nOnGoingHeight + nResponseHeight)
	self.wndPlayer:Invoke()
	
	if self.tPendingTutorialData then		
		Event_FireGenericEvent("Tutorial_ShowCallout", self.tPendingTutorialData.eAnchor, self.tPendingTutorialData.idTutorial, self.tPendingTutorialData.strPopupText, self.wndPlayer:FindChild("ResponseItemBtn"))
		
		self.tPendingTutorialData = nil
	end
end

function Dialog:OnResponseBtnClick(wndHandler, wndControl, eMouseButton) -- ResponseItemBtn
	if not wndHandler or not wndHandler:GetData() then
		return
	end

	local drResponse = wndHandler:GetData()

	-- Early exit if context menu
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		-- OnLootItemMouseUp should be fired instead
		return
	end

	if drResponse:GetRewardId() and drResponse:GetRewardId() ~= 0 and drResponse:GetRewardId() ~= self.bRewardPicked then
		-- Reset text first
		for idx, wndCurr in pairs(self.wndPlayer:FindChild("ResponseItemContainer"):GetChildren()) do
			if wndCurr:FindChild("ResponseItemText") and wndCurr:FindChild("ResponseItemText"):GetData() then
				wndCurr:FindChild("ResponseItemText"):SetText(wndCurr:FindChild("ResponseItemText"):GetData())
				wndCurr:FindChild("ResponseItemText"):SetTextColor(kcrDefaultOptionColor)
			end
		end
		self.bRewardPicked = drResponse:GetRewardId()
		wndHandler:FindChild("ResponseItemText"):SetText(String_GetWeaselString(Apollo.GetString("Dialog_TakeItem"), wndHandler:FindChild("ResponseItemText"):GetData()))
		wndHandler:FindChild("ResponseItemText"):SetTextColor(kcrHighlightOptionColor)
	elseif self.bShowPvpFlagWarning and drResponse:GetType() == DialogResponse.DialogResponseType_QuestAccept then
		local queAccept = DialogSys.GetViewableQuest(drResponse:GetQuestId())
		if queAccept ~= nil and queAccept:IsPvPQuest() then
			self:OnActivatePvpFlagConfirm(drResponse)
		else
			drResponse:Select() -- All the work is done in DialogSys's Select Method
		end
	else
		drResponse:Select() -- All the work is done in DialogSys's Select Method
	end
end

function Dialog:OnLootItemMouseUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and wndHandler:GetData() then
		Event_FireGenericEvent("GenericEvent_ContextMenuItem", wndHandler:GetData())
	end
end

function Dialog:OnResponseItemMouseUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and wndHandler:GetData() then
		Event_FireGenericEvent("GenericEvent_ContextMenuItem", wndHandler:GetData())
	end
end

---------------------------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------------------------

function Dialog:HelperComputeIconPath(eResponseType)
	local strSprite = "CRB_DialogSprites:sprDialog_Icon_Decline"
	if eResponseType == DialogResponse.DialogResponseType_ViewVending then
		strSprite = "CRB_DialogSprites:sprDialog_Icon_Vendor"
	elseif eResponseType == DialogResponse.DialogResponseType_ViewTraining then
		strSprite = "CRB_DialogSprites:sprDialog_Icon_Trainer"
	elseif eResponseType == DialogResponse.DialogResponseType_ViewCraftingStation then
		strSprite = "CRB_DialogSprites:sprDialog_Icon_Vendor"
	elseif eResponseType == DialogResponse.DialogResponseType_ViewTradeskillTraining then
		strSprite = "CRB_DialogSprites:sprDialog_Icon_Tradeskill"
	elseif eResponseType == DialogResponse.DialogResponseType_ViewQuestAccept then
		strSprite = "CRB_DialogSprites:sprDialog_Icon_Exclamation"
	elseif eResponseType == DialogResponse.DialogResponseType_ViewQuestComplete then
		strSprite = "CRB_DialogSprites:sprDialog_Icon_Check"
	elseif eResponseType == DialogResponse.DialogResponseType_ViewQuestIncomplete then
		strSprite = "CRB_DialogSprites:sprDialog_Icon_DisabledCheck"
	elseif eResponseType == DialogResponse.DialogResponseType_Goodbye then
		strSprite = "CRB_DialogSprites:sprDialog_Icon_Decline"
	elseif eResponseType == DialogResponse.DialogResponseType_QuestAccept then
		strSprite = "CRB_DialogSprites:sprDialog_Icon_Exclamation"
	elseif eResponseType == DialogResponse.DialogResponseType_QuestMoreInfo then
		strSprite = "CRB_DialogSprites:sprDialog_Icon_More"
	elseif eResponseType == DialogResponse.DialogResponseType_QuestComplete then
		strSprite = "CRB_DialogSprites:sprDialog_Icon_Check"
	end
	return strSprite
end

function Dialog:HelperComputeRewardTextColor(idReward, tChoiceRewardData)
	if idReward == 0 then
		return kcrDefaultOptionColor
	end

	for idx, tCurrReward in ipairs(tChoiceRewardData) do
		if tCurrReward and tCurrReward.idReward == idReward then
			if tCurrReward.eType == Quest.Quest2RewardType_Item then
				return karEvalColors[tCurrReward.itemReward:GetItemQuality()]
			end
			break
		end
	end

	return kcrDefaultOptionColor
end

function Dialog:HelperComputeRewardIcon(wndCurr, idReward, tChoiceRewardData)
	if idReward == 0 then
		return
	end

	local tFoundRewardData = nil
	for idx, tCurrReward in ipairs(tChoiceRewardData) do
		if tCurrReward.idReward == idReward then
			tFoundRewardData = tCurrReward
			break
		end
	end

	if tFoundRewardData and wndCurr then
		local strIconSprite = ""
		if tFoundRewardData.eType == Quest.Quest2RewardType_Item then
			strIconSprite = tFoundRewardData.itemReward:GetIcon()
			wndCurr:SetData(tFoundRewardData.itemReward) -- For OnGenerateTooltip and Right Click
		elseif tFoundRewardData.eType == Quest.Quest2RewardType_Reputation then
			strIconSprite = "Icon_ItemMisc_UI_Item_Parchment"
			wndCurr:SetTooltip(String_GetWeaselString(Apollo.GetString("Dialog_FactionRepReward"), tFoundRewardData.nAmount, tFoundRewardData.strFactionName))
		elseif tFoundRewardData.eType == Quest.Quest2RewardType_TradeSkillXp then
			strIconSprite = "ClientSprites:Icon_ItemMisc_tool_0001"
			wndCurr:SetTooltip(String_GetWeaselString(Apollo.GetString("Dialog_TradeskillXPReward"), tFoundRewardData.nXP, tFoundRewardData.strTradeskill)) --hardcoded
		elseif tFoundRewardData.eType == Quest.Quest2RewardType_GrantTradeskill then
			strIconSprite = "ClientSprites:Icon_ItemMisc_tool_0001"
			wndCurr:SetTooltip("")
		elseif tFoundRewardData.eType == Quest.Quest2RewardType_Money then
			if tFoundRewardData.eCurrencyType == Money.CodeEnumCurrencyType.Credits then
				local monObj = Money.new()
				monObj:SetAmount(tFoundRewardData.nAmount)
				wndCurr:SetTooltip(monObj:GetMoneyString())
				strIconSprite = "ClientSprites:Icon_ItemMisc_bag_0001"
			else
				local monObj = Money.new()
				monObj:SetMoneyType(tFoundRewardData.eCurrencyType)
				monObj:SetAmount(tFoundRewardData.nAmount)
				local tDenomInfo = monObj:GetDenomInfo()
				if tDenomInfo ~= nil and tDenomInfo[1] ~= nil then
					strText = monObj:GetMoneyString()
					strIconSprite = "ClientSprites:Icon_ItemMisc_bag_0001"
					if tDenomInfo[1].strSprite and tDenomInfo[1].strSprite ~= "" then
						strIconSprite = tDenomInfo[1].strSprite
					end
					wndCurr:SetTooltip(strText)
				end
			end
		elseif tFoundRewardData.eType == Quest.Quest2RewardType_AccountCurrency then
			local monObj = Money.new()
			monObj:SetAccountCurrencyType(tFoundRewardData.eAccountCurrencyType)
			monObj:SetAmount(tFoundRewardData.nAmount)
			local tDenomInfo = monObj:GetDenomInfo()
			if tDenomInfo ~= nil and tDenomInfo[1] ~= nil then
				strText = monObj:GetMoneyString()
				strIconSprite = "ClientSprites:Icon_ItemMisc_bag_0001"
				if tDenomInfo[1].strSprite and tDenomInfo[1].strSprite ~= "" then
					strIconSprite = tDenomInfo[1].strSprite
				end				
				wndCurr:SetTooltip(strText)
			end
		elseif tFoundRewardData.eType == Quest.Quest2RewardType_GenericUnlockAccount then
			strIconSprite = tFoundRewardData.tUnlockInfo.strIconSprite
			local strText = String_GetWeaselString(Apollo.GetString("FormatQuestReward_GenericUnlockAccount"), tFoundRewardData.tUnlockInfo.strUnlockName)
			wndCurr:SetTooltip(strText)
		elseif tFoundRewardData.eType == Quest.Quest2RewardType_GenericUnlockCharacter then
			strIconSprite = tFoundRewardData.tUnlockInfo.strIconSprite
			local strText = String_GetWeaselString(Apollo.GetString("FormatQuestReward_GenericUnlockCharacter"), tFoundRewardData.tUnlockInfo.strUnlockName)
			wndCurr:SetTooltip(strText)
		end

		wndCurr:FindChild("ResponseItemIcon"):Show(false)
		wndCurr:FindChild("ResponseItemRewardBG"):Show(true)
		wndCurr:FindChild("ResponseItemRewardIcon"):SetSprite(strIconSprite)
		wndCurr:FindChild("ResponseItemCantUse"):Show(self:HelperPrereqFailed(tFoundRewardData.itemReward))
	end
end

function Dialog:HelperDrawLootItem(wndCurrReward, tCurrReward, bSimple)
	local strIconSprite = ""
	if tCurrReward then
		if tCurrReward.eType == Quest.Quest2RewardType_Item and tCurrReward.itemReward then
			strIconSprite = tCurrReward.itemReward:GetIcon()
			wndCurrReward:FindChild("LootDescription"):SetText(tCurrReward.itemReward:GetName())
			wndCurrReward:FindChild("LootDescription"):SetTextColor(karEvalColors[tCurrReward.itemReward:GetItemQuality()])
			wndCurrReward:FindChild("LootItemCantUse"):Show(self:HelperPrereqFailed(tCurrReward.itemReward))
			wndCurrReward:SetData(tCurrReward.itemReward) -- For OnGenerateTooltip and Right Click
		elseif tCurrReward.eType == Quest.Quest2RewardType_Reputation then
			-- Reputation has overloaded fields: objectId is factionId. objectAmount is rep amount.
			strIconSprite = "Icon_ItemMisc_UI_Item_Parchment"
			wndCurrReward:FindChild("LootDescription"):SetText(String_GetWeaselString(Apollo.GetString("Dialog_FactionRepReward"), tCurrReward.nAmount, tCurrReward.strFactionName))
			wndCurrReward:FindChild("LootDescription"):SetHeightToContentHeight()
			local nLeft, nTop, nRight, nBottom = wndCurrReward:FindChild("LootDescription"):GetAnchorOffsets()
			local nLeft2, nTop2, nRight2, nBottom2 = wndCurrReward:GetAnchorOffsets()
			wndCurrReward:FindChild("LootDescription"):SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
			wndCurrReward:SetAnchorOffsets(nLeft2, nTop2, nRight2, nBottom)
			wndCurrReward:SetTooltip(String_GetWeaselString(Apollo.GetString("Dialog_FactionRepReward"), tCurrReward.nAmount, tCurrReward.strFactionName))
		elseif tCurrReward.eType == Quest.Quest2RewardType_TradeSkillXp then
			-- Tradeskill XP has overloaded fields: objectId is factionId. objectAmount is rep amount.
			strIconSprite = "ClientSprites:Icon_ItemMisc_tool_0001"
			wndCurrReward:FindChild("LootDescription"):SetText(String_GetWeaselString(Apollo.GetString("Dialog_TradeskillXPReward"), tCurrReward.nXP, tCurrReward.strTradeskill))
			wndCurrReward:SetTooltip(String_GetWeaselString(Apollo.GetString("Dialog_TradeskillXPReward"), tCurrReward.nXP, tCurrReward.strTradeskill))
		elseif tCurrReward.eType == Quest.Quest2RewardType_GrantTradeskill then
			-- Tradeskill XP has overloaded fields: objectId is tradeskillId.
			strIconSprite = "ClientSprites:Icon_ItemMisc_tool_0001"
			wndCurrReward:FindChild("LootDescription"):SetText(tCurrReward.strTradeskill)
			wndCurrReward:SetTooltip("")
		elseif tCurrReward.eType == Quest.Quest2RewardType_Money then
			if tCurrReward.eCurrencyType == Money.CodeEnumCurrencyType.Credits then
				strIconSprite = "ClientSprites:Icon_ItemMisc_bag_0001"
				wndCurrReward:FindChild("LootDescription"):Show(false)
				wndCurrReward:FindChild("LootCashWindow"):Show(true)
				wndCurrReward:FindChild("LootCashWindow"):SetAmount(tCurrReward.nAmount, 0)
				local monObj = Money.new()
				monObj:SetAmount(tCurrReward.nAmount)
				wndCurrReward:SetTooltip(monObj:GetMoneyString())
			else
				local monObj = Money.new()
				monObj:SetMoneyType(tCurrReward.eCurrencyType)
				monObj:SetAmount(tCurrReward.nAmount)
				strText = monObj:GetMoneyString()
				strIconSprite = "ClientSprites:Icon_ItemMisc_bag_0001"
				
				local tDenomInfo = monObj:GetDenomInfo()
				if tDenomInfo ~= nil and tDenomInfo[1] ~= nil then
					if tDenomInfo[1].strSprite and tDenomInfo[1].strSprite ~= "" then
						strIconSprite = tDenomInfo[1].strSprite
					end
				end
				
				wndCurrReward:FindChild("LootDescription"):Show(false)
				wndCurrReward:FindChild("LootCashWindow"):Show(true)
				wndCurrReward:FindChild("LootCashWindow"):SetMoneySystem(tCurrReward.eCurrencyType or 0)
				wndCurrReward:FindChild("LootCashWindow"):SetAmount(tCurrReward.nAmount, 0)
				wndCurrReward:SetTooltip(strText)
			end
		elseif tCurrReward.eType == Quest.Quest2RewardType_AccountCurrency then
			local monObj = Money.new()
			monObj:SetAccountCurrencyType(tCurrReward.eAccountCurrencyType)
			monObj:SetAmount(tCurrReward.nAmount)
			strText = monObj:GetMoneyString()
			strIconSprite = "ClientSprites:Icon_ItemMisc_bag_0001"
			
			local tDenomInfo = monObj:GetDenomInfo()
			if tDenomInfo ~= nil and tDenomInfo[1] ~= nil then
				if tDenomInfo[1].strSprite and tDenomInfo[1].strSprite ~= "" then
					strIconSprite = tDenomInfo[1].strSprite
				end
			end
			
			wndCurrReward:FindChild("LootDescription"):Show(false)
			wndCurrReward:FindChild("LootCashWindow"):Show(true)
			wndCurrReward:FindChild("LootCashWindow"):SetMoneySystem(Money.CodeEnumCurrencyType.GroupCurrency, 0, 0, tCurrReward.eAccountCurrencyType or 0)
			wndCurrReward:FindChild("LootCashWindow"):SetAmount(tCurrReward.nAmount, 0)
			wndCurrReward:SetTooltip(strText)
		elseif tCurrReward.eType == Quest.Quest2RewardType_GenericUnlockAccount then
			strIconSprite = tCurrReward.tUnlockInfo.strIconSprite
			local strText = String_GetWeaselString(Apollo.GetString("FormatQuestReward_GenericUnlockAccount"), tCurrReward.tUnlockInfo.strUnlockName)
			wndCurrReward:FindChild("LootDescription"):SetText(strText)
			wndCurrReward:SetTooltip(strText)
		elseif tCurrReward.eType == Quest.Quest2RewardType_GenericUnlockCharacter then
			strIconSprite = tCurrReward.tUnlockInfo.strIconSprite
			local strText = String_GetWeaselString(Apollo.GetString("FormatQuestReward_GenericUnlockCharacter"), tCurrReward.tUnlockInfo.strUnlockName)
			wndCurrReward:FindChild("LootDescription"):SetText(strText)
			wndCurrReward:SetTooltip(strText)
		end
	end

	if bSimple then
		wndCurrReward:FindChild("LootDescription"):SetTextColor(kcrDefaultOptionColor)
	else
		wndCurrReward:FindChild("LootItemIcon"):SetSprite(strIconSprite)
		if tCurrReward.nAmount ~= nil then
			wndCurrReward:FindChild("LootItemIcon"):SetText(tCurrReward.nAmount > 1 and tCurrReward.nAmount or "")
		end
	end
end

function Dialog:OnResponseItemMouseUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and wndHandler:GetData() then
		Event_FireGenericEvent("GenericEvent_ContextMenuItem", wndHandler:GetData())
	end
end

---------------------------------------------------------------------------------------------------
-- New Item and NPC Bubble Methods
---------------------------------------------------------------------------------------------------

function Dialog:DrawItemBubble(wndArg, eState, idQuest)
	-- We are going to be sneaky and just use DrawNpcBubble to draw ItemBubble as they are set up the same
	self:DrawNpcBubble(wndArg, eState, idQuest)
	local nHeightWithText = self:HelperExpandForText(self.nWndItemTop, wndArg)
	self.wndItem:SetAnchorOffsets(self.nWndItemLeft, nHeightWithText, self.nWndItemRight, self.nWndItemBottom)
end

function Dialog:DrawNpcBubble(wndArg, eState, idQuest)
	-- Text
	local cdDialog = DialogSys.GetNPCText(idQuest)
	if cdDialog == nil then
		wndArg:Show(false)
		return
	end
	
	local strText = cdDialog:GetText()
	if not strText or Apollo.StringLength(strText) == 0 then
		wndArg:Show(false)
		return
	end
	wndArg:FindChild("BubbleText"):SetAML("<P Font=\"CRB_InterfaceMedium\" TextColor=\"ff7fffb9\">"..strText.."</P>")
	wndArg:FindChild("BubbleText"):SetHeightToContentHeight()

	if cdDialog:HasVO() then
		cdDialog:PlayVO()
	end
	
	-- Rewards
	wndArg:FindChild("GivenRewardsText"):Show(false)
	wndArg:FindChild("ChoiceRewardsText"):Show(false)
	local queCurr = DialogSys.GetViewableQuest(idQuest)
	local nGivenContainerHeight = 0
	local nChoiceContainerHeight = 0
	local nPadding = 5
	if queCurr then
		local tRewardInfo = queCurr:GetRewardData()
		local wndGivenRewardsItems = wndArg:FindChild("GivenRewardsItems")
		if tRewardInfo.arFixedRewards and #tRewardInfo.arFixedRewards > 0 then
			wndGivenRewardsItems:DestroyChildren()

			--add the xp given
			local nGivenXP = queCurr:CalcRewardXP()
			if nGivenXP > 0 then
				local wndCurrXPReward = Apollo.LoadForm(self.xmlDoc, "XPReward", wndGivenRewardsItems, self)
				wndCurrXPReward:SetText(String_GetWeaselString(Apollo.GetString("CombatFloaterMessage_Experience_Default"), tostring(nGivenXP)))
				nGivenContainerHeight = nGivenContainerHeight + wndCurrXPReward:GetHeight()
			end

			local tDoThisLast = {}
			for idx, tCurrReward in ipairs(tRewardInfo.arFixedRewards) do
				if tCurrReward and (tCurrReward.eType == Quest.Quest2RewardType_Money or tCurrReward.eType == Quest.Quest2RewardType_AccountCurrency) and tCurrReward.nAmount > 0 then
					tDoThisLast[tCurrReward.idReward] = tCurrReward
				elseif tCurrReward then
					local wndCurrReward = nil
					if tCurrReward.eType ~= Quest.Quest2RewardType_Reputation then
						wndCurrReward = Apollo.LoadForm(self.xmlDoc, "LootItem", wndGivenRewardsItems, self)
						self:HelperDrawLootItem(wndCurrReward, tCurrReward, false)
					else
						wndCurrReward = Apollo.LoadForm(self.xmlDoc, "GivenLootItemSimple", wndGivenRewardsItems, self)
						self:HelperDrawLootItem(wndCurrReward, tCurrReward, true)
					end

					nGivenContainerHeight = nGivenContainerHeight + wndCurrReward:GetHeight()
				end
			end

			 -- Given Rewards Only: Draw money at the bottom
			for idx, tLast in pairs(tDoThisLast) do
				local wndCurrReward = Apollo.LoadForm(self.xmlDoc, "GivenLootItemSimple", wndGivenRewardsItems, self)
				self:HelperDrawLootItem(wndCurrReward, tLast, true)
				nGivenContainerHeight = nGivenContainerHeight + wndCurrReward:GetHeight()
			end

			-- End draw money and xp
			nGivenContainerHeight = nGivenContainerHeight + (nPadding * 2)
			wndGivenRewardsItems:ArrangeChildrenVert()
			wndGivenRewardsItems:SetAnchorOffsets(0, 0, 0, nGivenContainerHeight)

			wndArg:FindChild("GivenRewardsText"):Show(true)
			nGivenContainerHeight = nGivenContainerHeight + 30 -- +30 for the text label after resizing
		end

		if tRewardInfo.arRewardChoices and #tRewardInfo.arRewardChoices > 0 and eState ~= DialogSys.DialogState_QuestComplete then -- GOTCHA: Choices are shown in Player, not NPC for QuestComplete
			local tSortedRewards = self:SortRewardItems(tRewardInfo.arRewardChoices)

			wndArg:FindChild("ChoiceRewardsItems"):DestroyChildren()
			for idx, tCurrReward in ipairs(tSortedRewards) do
				if tCurrReward then
					local wndCurrReward = Apollo.LoadForm(self.xmlDoc, "LootItem", wndArg:FindChild("ChoiceRewardsItems"), self)
					self:HelperDrawLootItem(wndCurrReward, tCurrReward, false)
					if nChoiceContainerHeight < (knMaxRewardItemsShown * wndCurrReward:GetHeight()) then
						nChoiceContainerHeight = nChoiceContainerHeight + wndCurrReward:GetHeight()
					end
				end
			end

			nChoiceContainerHeight = nChoiceContainerHeight + (2 * nPadding )
			wndArg:FindChild("ChoiceRewardsItems"):ArrangeChildrenVert()
			wndArg:FindChild("ChoiceRewardsItems"):SetAnchorOffsets(0, 0, 0, nChoiceContainerHeight)

			wndArg:FindChild("ChoiceRewardsText"):Show(#tRewardInfo.arRewardChoices > 1)
			if #tRewardInfo.arRewardChoices > 1 then
				nChoiceContainerHeight = nChoiceContainerHeight + 30
			end
		end
	end

	wndArg:FindChild("RewardsContainer"):ArrangeChildrenVert()
	wndArg:FindChild("RewardsContainer"):SetAnchorOffsets(0, 0, 0, nGivenContainerHeight + nChoiceContainerHeight)

	wndArg:FindChild("BubbleWindowContainer"):ArrangeChildrenVert()
	wndArg:Show(true)
	wndArg:ToFront()
end

function Dialog:SortRewardItems(tRewards)
	local tCanNotEquipItems = {}
	local tCanEquipItems = {}

	for idx, tCurrReward in ipairs(tRewards) do
		if tCurrReward.itemReward:CanEquip() then
			table.insert(tCanEquipItems, tCurrReward)
		else
			table.insert(tCanNotEquipItems, tCurrReward)
		end
	end

	table.sort(tCanEquipItems, function(a,b) return a.itemReward:GetItemCategoryName() < b.itemReward:GetItemCategoryName() end)
	table.sort(tCanNotEquipItems, function(a,b) return a.itemReward:GetItemCategoryName() < b.itemReward:GetItemCategoryName() end)

	local tSortedRewards = {}
	for idx, tCurrReward in pairs(tCanEquipItems 	or {}) do
		table.insert(tSortedRewards, tCurrReward)
	end

	for idx, tCurrReward in pairs(tCanNotEquipItems or {}) do
		table.insert(tSortedRewards, tCurrReward)
	end

	return tSortedRewards
end

---------------------------------------------------------------------------------------------------
-- Old NPC Bubble Methods
---------------------------------------------------------------------------------------------------

function Dialog:PositionNpcBubble(wndArg)
	local unitNpc = DialogSys.GetNPC()
	if not unitNpc then
		return
	end

	local tAnchor = unitNpc:GetOverheadAnchor()
	local nLeft, nTop, nRight, nBottom
	nLeft = tAnchor.x - (self.nWndNpcRight - self.nWndNpcLeft)
	nTop = tAnchor.y - (self.nWndNpcBottom - self.nWndNpcTop) + 40  --hardcoded
	nRight = tAnchor.x
	nBottom = tAnchor.y + 17  --hardcoded  -- The +40 is to get the dangling speech bubble *right* on the NPC


	-- Expand for text
	nTop = self:HelperExpandForText(nTop, wndArg)

	-- Ensure on screen
	local tMax = Apollo.GetDisplaySize()
	if nTop < 0 then -- Order matters
		nBottom = nBottom - nTop
		nTop = 0
	elseif nBottom > tMax.nHeight then
		nTop = nTop - (nBottom - tMax.nHeight)
		nBottom = tMax.nHeight
	end

	if nLeft < 0 then
		nRight = nRight - nLeft
		nLeft = 0
	elseif nRight > tMax.nWidth then
		nLeft = nLeft - (nRight - tMax.nWidth)
		nRight = tMax.nWidth
	end
	-- End Ensure on screen

	wndArg:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
end

function Dialog:HelperExpandForText(nNewTop, wndArg)
	local nLeft, nTop, nRight, nBottom = wndArg:FindChild("BubbleText"):GetAnchorOffsets()
	nNewTop = nNewTop - (nBottom - nTop)
	if wndArg:FindChild("RewardsContainer"):IsShown() then
		local nTempLeft, nTempTop, nTempRight, nTempBottom = wndArg:FindChild("RewardsContainer"):GetAnchorOffsets()
		nNewTop = nNewTop - (nTempBottom - nTempTop)
	end
	return nNewTop
end

function Dialog:OnDestroyTooltip(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:SetTooltipDoc(nil)
	end
end

function Dialog:OnGenerateTooltip(wndHandler, wndControl, eType, arg1, arg2)
	if wndHandler ~= wndControl	then
		return
	end

	if eType == Tooltip.TooltipGenerateType_ItemData then
		local itemCurr = arg1
		local itemEquipped = itemCurr:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, itemCurr, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})

	elseif eType == Tooltip.TooltipGenerateType_Reputation or eType == Tooltip.TooltipGenerateType_TradeSkill then
		local xml = nil
		xml = XmlDoc.new()
		xml:StartTooltip(Tooltip.TooltipWidth)
		xml:AddLine(arg1)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Money then
		local xml = nil
		xml = XmlDoc.new()
		xml:StartTooltip(Tooltip.TooltipWidth)
		xml:AddLine(arg1:GetMoneyString(), kcrDefaultColor, "CRB_InterfaceMedium")
		wndControl:SetTooltipDoc(xml)
	elseif wndHandler:GetData() then
		local itemCurr = wndHandler:GetData()
		local itemEquipped = itemCurr:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, itemCurr, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	else
		wndControl:SetTooltipDoc(nil)
	end
end

function Dialog:OnWindowClosed(wndHandler, wndControl) -- The 'esc' key from xml
	if wndHandler:GetId() ~= wndControl:GetId() then return end
	DialogSys.End()
end

function Dialog:OnUpdateTimer(strVarName, nCount)
	if self.wndNpc and self.wndNpc:IsShown() then
		self:PositionNpcBubble(self.wndNpc)
	end
end

function Dialog:OnRequestShowPvpFlagWarningState()
	Event_FireGenericEvent("Dialog_ShowPvpFlagWarningChanged", self.bShowPvpFlagWarning)
end

---------------------------------------------------------------------------------------------------
-- PvP Quest Confirmation
---------------------------------------------------------------------------------------------------

function Dialog:OnActivatePvpFlagConfirm(drResponse)
	if self.wndPvPQuestConfirmation ~= nil and self.wndPvPQuestConfirmation:IsValid() or drResponse == nil then
		return
	end
	
	self.wndPvPQuestConfirmation = Apollo.LoadForm(self.xmlDoc, "PvPQuestConfirmation", nil, self)
	if self.wndPvPQuestConfirmation == nil then
		return
	end
	
	self:HelperPvPKeyBindingUpdate()
	self.wndPvPQuestConfirmation:FindChild("IgnoreWarning"):SetCheck(not self.bShowPvpFlagWarning)
	self.wndPvPQuestConfirmation:FindChild("AcceptBtn"):SetData(drResponse)
	
	self.wndPvPQuestConfirmation:Invoke()
end

function Dialog:OnIgnoreWarning(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.bShowPvpFlagWarning = not self.wndPvPQuestConfirmation:FindChild("IgnoreWarning"):IsChecked()
	Event_FireGenericEvent("Dialog_ShowPvpFlagWarningChanged", self.bShowPvpFlagWarning)
end

function Dialog:OnAcceptBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	wndHandler:GetData():Select() -- All the work is done in DialogSys's Select Method
	self.wndPvPQuestConfirmation:Close()
end

function Dialog:OnDeclineBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.wndPvPQuestConfirmation:Close()
end

function Dialog:OnClose()
	if self.wndPvPQuestConfirmation ~= nil and self.wndPvPQuestConfirmation:IsValid() then
		self.wndPvPQuestConfirmation:Destroy()
	end
end

function Dialog:OnKeyBindingUpdated(strKeybind)
	if strKeybind ~= "Codex" then
		return
	end
	
	self:HelperPvPKeyBindingUpdate()
end

function Dialog:OnOptionsInterface_ShowPvpFlagWarningChanged(bShowPvpFlagWarning)
	self.bShowPvpFlagWarning = bShowPvpFlagWarning
	if self.wndPvPQuestConfirmation ~= nil and self.wndPvPQuestConfirmation:IsValid() then
		self.wndPvPQuestConfirmation:FindChild("IgnoreWarning"):SetCheck(not bShowPvpFlagWarning)
	end
end

function Dialog:HelperPrereqFailed(itemCurr)
	return itemCurr and itemCurr:IsEquippable() and not itemCurr:CanEquip()
end

function Dialog:HelperPvPKeyBindingUpdate()
	if self.wndPvPQuestConfirmation == nil or not self.wndPvPQuestConfirmation:IsValid() then
		return
	end
	
	local wndBody = self.wndPvPQuestConfirmation:FindChild("Body")
	wndBody:SetAML(string.format("<P Font='%s' TextColor='%s'>%s</P>", wndBody:GetFont(), wndBody:GetTextColor():GetColorString(), String_GetWeaselString(Apollo.GetString("Dialog_PvpFlagOnWhileQuestActiveInQuestLog"), GameLib.GetKeyBindingByEnum(GameLib.CodeEnumInputAction.Codex))))
	local nBodyWidth, nBodyHeight = wndBody:SetHeightToContentHeight()
	
	local nOrigLeft, nOrigTop, nOrigRight, nOrigBottom = self.wndPvPQuestConfirmation:GetOriginalLocation():GetOffsets()
	self.wndPvPQuestConfirmation:SetAnchorOffsets(nOrigLeft, nOrigTop - nBodyHeight, nOrigRight, nOrigBottom)
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------

function Dialog:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	local tAnchors =
	{
		[GameLib.CodeEnumTutorialAnchor.QuestIntroduction] 	= true,
		[GameLib.CodeEnumTutorialAnchor.QuestAccept] 		= true,
	}
	
	if not tAnchors[eAnchor] or not self.wndPlayer then
		return
	end
	
	if not self.wndPlayer:FindChild("ResponseItemBtn") then
		self.tPendingTutorialData = {eAnchor = eAnchor, idTutorial = idTutorial, strPopupText = strPopupText}
	else	
		local tAnchorMapping = 
		{
			[GameLib.CodeEnumTutorialAnchor.QuestIntroduction] 	= self.wndPlayer:FindChild("ResponseItemBtn"),
			[GameLib.CodeEnumTutorialAnchor.QuestAccept] 		= self.wndPlayer:FindChild("ResponseItemBtn"),
		}
		
		if tAnchorMapping[eAnchor] then
			Event_FireGenericEvent("Tutorial_ShowCallout", eAnchor, idTutorial, strPopupText, tAnchorMapping[eAnchor])
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Dialog instance
---------------------------------------------------------------------------------------------------
local DialogInst = Dialog:new()
DialogInst:Init()