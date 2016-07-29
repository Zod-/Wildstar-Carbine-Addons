-- Client lua script
require "CommunicatorLib"
require "Window"
require "Apollo"
require "DialogSys"
require "Quest"
require "MailSystemLib"
require "Sound"
require "GameLib"
require "Tooltip"
require "XmlDoc"
require "PlayerPathLib"
require "CommunicatorLib"
require "Unit"
require "CommDialog"

---------------------------------------------------------------------------------------------------
-- CommDisplay
---------------------------------------------------------------------------------------------------
local CommDisplay = {}
local knDefaultWidth = 500
local knDefaultHeight = 173

-- TODO Hardcoded Colors for Items
local arEvalColors =
{
	[Item.CodeEnumItemQuality.Average] 		= ApolloColor.new("ItemQuality_Average"),
	[Item.CodeEnumItemQuality.Good] 		= ApolloColor.new("ItemQuality_Good"),
	[Item.CodeEnumItemQuality.Excellent]	= ApolloColor.new("ItemQuality_Excellent"),
	[Item.CodeEnumItemQuality.Superb] 		= ApolloColor.new("ItemQuality_Superb"),
	[Item.CodeEnumItemQuality.Legendary] 	= ApolloColor.new("ItemQuality_Legendary"),
	[Item.CodeEnumItemQuality.Artifact] 	= ApolloColor.new("ItemQuality_Artifact"),
	[Item.CodeEnumItemQuality.Inferior] 	= ApolloColor.new("ItemQuality_Inferior"),
}

local knSaveVersion = 5

---------------------------------------------------------------------------------------------------
-- CommDisplay initialization
---------------------------------------------------------------------------------------------------
function CommDisplay:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function CommDisplay:Init()
    Apollo.RegisterAddon(self)
end

function CommDisplay:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CommDisplay.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function CommDisplay:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end

	if self.wndMain == nil then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "CommDisplayForm", nil, self) -- Do not rename. Datachron.lua references this.
		self.wndMain:Show(false, true)

		local tOffsets = {self.wndMain:GetAnchorOffsets()}
		self.tDefaultOffsets = {tOffsets[1], tOffsets[2], tOffsets[1] + knDefaultWidth, tOffsets[2] + knDefaultHeight}
		self.nRewardLeft, self.nRewardTop, self.nRewardRight, self.nRewardBottom = self.wndMain:FindChild("RewardsContainer"):GetAnchorOffsets()
		self.nDialogLeft, self.nDialogTop, self.nDialogRight, self.nDialogBottom = self.wndMain:FindChild("DialogFraming"):GetAnchorOffsets()
	end

	Apollo.RegisterEventHandler("HideCommDisplay",				"OnHideCommDisplay", self)
	Apollo.RegisterEventHandler("CloseCommDisplay",				"OnHideCommDisplay", self)
	Apollo.RegisterEventHandler("StopTalkingCommDisplay",		"OnStopTalkingCommDisplay", self)
	Apollo.RegisterEventHandler("CommDisplayQuestText",			"OnCommDisplayQuestText", self)
	Apollo.RegisterEventHandler("CommDisplayRegularText",		"OnCommDisplayRegularText", self)
	Apollo.RegisterEventHandler("Communicator_ShowQueuedMsg",	"OnCommunicator_ShowQueuedMsg", self)

	self.tGivenRewardData = {}
	self.tGivenRewardIcons = {}

	self.tChoiceRewardData = {}
	self.tChoiceRewardIcons = {}

	self.wndCommPortraitLeft = self.wndMain:FindChild("CommPortraitLeft")
	self.wndCommPortraitRight = self.wndMain:FindChild("CommPortraitRight")

	Apollo.RegisterEventHandler("WindowManagementReady", 	"OnWindowManagementReady", self)
	self:OnWindowManagementReady()
end

function CommDisplay:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("InputAction_Communicator"), nSaveVersion=2})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("InputAction_Communicator"), nSaveVersion=2})
end

function CommDisplay:OnCloseBtn()
	Event_FireGenericEvent("CommDisplay_Closed") -- Let the datachron know we exited early
end

---------------------------------------------------------------------------------------------------
-- CommDisplay Events
---------------------------------------------------------------------------------------------------

function CommDisplay:OnShowCommDisplay()
	self.wndMain:Show(true)
	self.wndCommPortraitLeft:Show(true)
	self.wndCommPortraitRight:Show(true)
end

function CommDisplay:OnHideCommDisplay()
	self.wndMain:Show(false)
	self.wndCommPortraitLeft:Show(false)
	self.wndCommPortraitLeft:StopTalkSequence()
	self.wndCommPortraitRight:Show(false)
	self.wndCommPortraitRight:StopTalkSequence()
	self:OnCloseCommDisplay()
end

function CommDisplay:OnStopTalkingCommDisplay()
	self.wndMain:UnpauseAnim()
	self.wndCommPortraitLeft:StopTalkSequence()
	self.wndCommPortraitRight:StopTalkSequence()
end

function CommDisplay:OnCloseCommDisplay()
	local tOffsets = {self.wndMain:GetAnchorOffsets()}
	self.tDefaultOffsets = {tOffsets[1], tOffsets[2], tOffsets[1] + knDefaultWidth, tOffsets[2] + knDefaultHeight}
	self.tChoiceRewardData = {}
	self.tGivenRewardData = {}
	self.nCurTextHeight = 0

	if self.wndMain ~= nil then
		self.wndMain:Show(false)
	end
end

function CommDisplay:OnCommDisplayRegularText(idMsg, idCreature, strMessageText, tLayout)
	local pmMission = CommunicatorLib.GetPathMissionDelivered(idMsg)
	if pmMission then
		return
	end

	local tCommToQueue =
	{
		strType = "Spam",
		idMsg = idMsg,
		idCreature = idCreature,
		strMessageText = strMessageText,
		tLayout = tLayout,
	}
	
	CommunicatorLib.QueueMessage(tCommToQueue)
end

function CommDisplay:OnCommDisplayQuestText(idState, idQuest, bIsCommCall, tLayout)	
	local tCommToQueue =
	{
		strType = "Quest",
		idState = idState,
		idQuest = idQuest,
		bIsCommCall = bIsCommCall,
		tLayout = tLayout,
		cdDialog = DialogSys.GetNPCText(idQuest),
		idCreature = DialogSys.GetCommCreatureId()
	}
	
	CommunicatorLib.QueueMessage(tCommToQueue)
end

function CommDisplay:OnCommunicator_ShowQueuedMsg(tMessage)
	if tMessage == nil then
		return
	end
	
	if tMessage.strType == "Quest" then
		-- From Datachron
		self.wndMain:DetachAnim()
	
		self:OnShowCommDisplay()
	
		self.wndCommPortraitLeft:PlayTalkSequence()
		self.wndCommPortraitRight:PlayTalkSequence()
		self.wndMain:FindChild("DialogText"):SetAML("")
		self.wndMain:FindChild("CloseBtn"):Show(false)
	
		self.tChoiceRewardData = {}
		self.tGivenRewardData = {}
		local strMessageText = ""
		
		if tMessage.cdDialog ~= nil then
			strMessageText = tMessage.cdDialog:GetText()
			
			if tMessage.cdDialog:HasVO() then
				tMessage.cdDialog:PlayVO()
			end
		end
		
		if strMessageText == nil or Apollo.StringLength(strMessageText) == 0 then
			strMessageText = ""
		end
	
		local tOffsets = {self.wndMain:GetAnchorOffsets()}
		self.tDefaultOffsets = {tOffsets[1], tOffsets[2], tOffsets[1] + knDefaultWidth, tOffsets[2] + knDefaultHeight}
	
		self:DrawText(strMessageText, "", tMessage.bIsCommCall, tMessage.tLayout, tMessage.idCreature, tMessage.idState, tMessage.idQuest)
		
	elseif tMessage.strType == "Spam" then
		self:OnShowCommDisplay()
	
		if CommunicatorLib.PlaySpamVO(tMessage.idMsg) then
			-- if we can play a real VO, then wait for the signal that that VO ended
			self.wndMain:SetAnimElapsedTime(9.0)
			self.wndMain:PauseAnim()
			Sound.Play(Sound.PlayUIDatachronSpam)
		else
			self.wndMain:PlayAnim(0)
			Sound.Play(Sound.PlayUIDatachronSpamNoVO)
		end
	
		self.wndCommPortraitLeft:PlayTalkSequence()
		self.wndCommPortraitRight:PlayTalkSequence()
	
		local tOffsets = {self.wndMain:GetAnchorOffsets()}
		self.tDefaultOffsets = {tOffsets[1], tOffsets[2], tOffsets[1] + knDefaultWidth, tOffsets[2] + knDefaultHeight}
	
		self.wndMain:FindChild("CloseBtn"):Show(true)
		self:DrawText(tMessage.strMessageText, "", true, tMessage.tLayout, tMessage.idCreature, nil, nil) -- 2nd argument: bIsCommCall
	end
end

---------------------------------------------------------------------------------------------------
-- CommDisplay private methods
---------------------------------------------------------------------------------------------------

function CommDisplay:DrawText(strMessageText, strSubTitleText, bIsCommCall, tLayout, idCreature, idState, idQuest)
	-- TODO Lots of format hardcoding
	--[[ Possible options on tLayout
		duration
		portraitPlacement: 0 left, 1 Right
		overlay: 0 default, 1 lightstatic, 2 heavystatic
		background: 0 default, 1 exiles, 2 dominion
	]]--
	self.wndMain:FindChild("PortraitContainerLeft"):Show(not tLayout or tLayout.ePortraitPlacement == CommunicatorLib.CommunicatorPortraitPlacement_Left)
	self.wndMain:FindChild("PortraitContainerRight"):Show(tLayout and tLayout.ePortraitPlacement == CommunicatorLib.CommunicatorPortraitPlacement_Right)
	self.wndMain:FindChild("HorizontalTopContainer"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
	if tLayout then
		local wndFramingOrigin = self.wndMain:FindChild("Framing:SpecificFraming")
		local wndIconOrigin = self.wndMain:FindChild("SpecificIcon")
		if tLayout.eBackground == CommunicatorLib.CommunicatorBackground_Exiles then
			wndFramingOrigin:SetSprite("bk3:sprHolo_Alert_COMMAttachment_Exile")
			wndIconOrigin:SetSprite("bk3:sprHolo_Alert_COMMAttachment_ExileIcon")
		elseif tLayout.eBackground == CommunicatorLib.CommunicatorBackground_Dominion then
			wndFramingOrigin:SetSprite("bk3:sprHolo_Alert_COMMAttachment_Dominion")
			wndIconOrigin:SetSprite("bk3:sprHolo_Alert_COMMAttachment_DominionIcon")
		elseif tLayout.eBackground == CommunicatorLib.CommunicatorBackground_Drusera then
			wndFramingOrigin:SetSprite("bk3:sprHolo_Alert_COMMAttachment_Drusera")
			wndIconOrigin:SetSprite("bk3:sprHolo_Alert_COMMAttachment_DruseraIcon")
		elseif tLayout.eBackground == CommunicatorLib.CommunicatorBackground_TheEntity then
			wndFramingOrigin:SetSprite("bk3:sprHolo_Alert_COMMAttachment_Strain")
			wndIconOrigin:SetSprite("bk3:sprHolo_Alert_COMMAttachment_StrainIcon")
		else
			wndFramingOrigin:SetSprite("")
			wndIconOrigin:SetSprite("")
		end

		if tLayout.ePortraitPlacement == CommunicatorLib.CommunicatorPortraitPlacement_Right then
			self.wndMain:FindChild("HorizontalTopContainer"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.RightOrBottom)
		else
			self.wndMain:FindChild("HorizontalTopContainer"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
		end
	end

	if not tLayout or tLayout.eOverlay == CommunicatorLib.CommunicatorOverlay_Default then
		self.wndMain:FindChild("StaticContainerL"):SetSprite("")
		self.wndMain:FindChild("StaticContainerR"):SetSprite("")
	elseif tLayout.eOverlay == CommunicatorLib.CommunicatorOverlay_LightStatic then
		self.wndMain:FindChild("StaticContainerL"):SetSprite("sprComm_StaticComposite")
		self.wndMain:FindChild("StaticContainerR"):SetSprite("sprComm_StaticComposite")
	elseif tLayout.eOverlay == CommunicatorLib.CommunicatorOverlay_HeavyStatic then
		self.wndMain:FindChild("StaticContainerL"):SetSprite("sprComm_StaticComposite")
		self.wndMain:FindChild("StaticContainerR"):SetSprite("sprComm_StaticComposite")
	end

	-- format the given text to display
	local strLeftOrRight = "Left"
	local strCreatureName = ""

	if tLayout and tLayout.ePortraitPlacement == CommunicatorLib.CommunicatorPortraitPlacement_Right then
		strLeftOrRight = "Right"
	end

	if idCreature and idCreature ~= 0 then
		self.wndCommPortraitLeft:SetCostumeToCreatureId(idCreature)
		self.wndCommPortraitRight:SetCostumeToCreatureId(idCreature)

		if Creature_GetName(idCreature) then
			strCreatureName = Creature_GetName(idCreature)
		end
	end

	local strSubtitleAppend = ""
	local strTextColor = "ff8096a8"

	if bIsCommCall then
		strTextColor = "ff62b383"
	end

	if strSubTitleText and strSubTitleText ~= "" then
		strSubtitleAppend = string.format("<P Font=\"CRB_InterfaceLarge_B\" TextColor=\"%s\" Align=\"%s\">%s</P>", strTextColor, strLeftOrRight, strSubTitleText)
	end

	self.wndMain:FindChild("DialogName"):SetAML(string.format("<P Font=\"CRB_HeaderMedium\" TextColor=\"%s\" Align=\"%s\">%s</P>", "UI_TextHoloTitle", strLeftOrRight, strCreatureName))
	self.wndMain:FindChild("DialogName"):SetHeightToContentHeight()
	self.wndMain:FindChild("DialogText"):SetAML(string.format("%s<P Font=\"CRB_InterfaceMedium\" TextColor=\"%s\" Align=\"%s\">%s</P>", strSubtitleAppend, strTextColor, strLeftOrRight, strMessageText))

	-- Draw Rewards
	local nRewardHeight = 0

	if idState ~= DialogSys.DialogState_TopicChoice then
		nRewardHeight = self:DrawRewards(self.wndMain, idState, idQuest)
	end

	self.wndMain:FindChild("RewardsContainer"):Show(nRewardHeight > 0)

	-- Resize for text over four lines (four lines is equal to 68 pixels at the moment) -- TODO Hardcoded formatting
	self.wndMain:FindChild("DialogText"):SetHeightToContentHeight()
	local nLeft, nTop, nRight, nBottom = self.wndMain:FindChild("DialogText"):GetAnchorOffsets()
	local nContentX, nContentY = self.wndMain:FindChild("DialogName"):GetContentSize()
	local nOffsetY = 0
	self.wndMain:FindChild("DialogFraming"):SetAnchorOffsets(self.nDialogLeft, self.nDialogTop, self.nDialogRight, self.nDialogBottom)

	if (nTop + nBottom) > 68 and nContentY < 30 then -- 30 = 2 lines of text. Let's make everything 20px taller when the Title wraps
		nOffsetY = (nTop + nBottom) - 73
		self.wndMain:FindChild("DialogFraming"):SetAnchorOffsets(self.nDialogLeft, self.nDialogTop, self.nDialogRight, self.nDialogBottom + (nTop + nBottom) - 70)
	elseif (nTop + nBottom) > 68 and nContentY > 30 then
		nOffsetY = (nTop + nBottom) - 53
		self.wndMain:FindChild("DialogFraming"):SetAnchorOffsets(self.nDialogLeft, self.nDialogTop, self.nDialogRight, self.nDialogBottom + (nTop + nBottom) - 50)
	end

	-- Excess text expands down, & Rewards expand down
	self.wndMain:SetAnchorOffsets(self.tDefaultOffsets[1], self.tDefaultOffsets[2], self.tDefaultOffsets[3], self.tDefaultOffsets[4] + nRewardHeight + nOffsetY)
	self.wndMain:FindChild("RewardsContainer"):SetAnchorOffsets(self.nRewardLeft, self.nRewardTop + nOffsetY, self.nRewardRight, self.nRewardBottom)
end

function CommDisplay:DrawRewards(wndArg, idState, idQuest)
	-- Reset everything, especially if we don't even have rewards
	self.wndMain:FindChild("GivenContainer"):Show(false)
	self.wndMain:FindChild("ChoiceContainer"):Show(false)
	self.wndMain:FindChild("GivenRewardsText"):Show(false)
	self.wndMain:FindChild("ChoiceRewardsText"):Show(false)
	self.wndMain:FindChild("GivenRewardsItems"):DestroyChildren()
	self.wndMain:FindChild("ChoiceRewardsItems"):DestroyChildren()

	if not idQuest or idQuest == 0 then
		return 0
	end

	local queView = DialogSys.GetViewableQuest(idQuest)

	if not queView then
		return 0
	end

	local tRewardInfo = queView:GetRewardData()

	local nGivenContainerHeight = 0
	if tRewardInfo.arFixedRewards and #tRewardInfo.arFixedRewards > 0 then
		local nGivenXP = queView:CalcRewardXP()
		if nGivenXP > 0 then
			local wndCurrXPReward = Apollo.LoadForm(self.xmlDoc, "XPReward", wndArg:FindChild("GivenRewardsItems"), self)
			wndCurrXPReward:SetText(String_GetWeaselString(Apollo.GetString("CombatFloaterMessage_Experience_Default"), tostring(nGivenXP)))
		end
	
		local tDoThisLast = {}
		for key, tCurrReward in ipairs(tRewardInfo.arFixedRewards) do
			if tCurrReward and (tCurrReward.eType == Quest.Quest2RewardType_Money or tCurrReward.eType == Quest.Quest2RewardType_AccountCurrency) and tCurrReward.nAmount > 0 then
				tDoThisLast[tCurrReward.idReward] = tCurrReward
			elseif tCurrReward then
				self:DrawLootItem(tCurrReward, wndArg:FindChild("GivenRewardsItems"))
			end
		end
		
		-- Given Rewards Only: Draw money at the bottom
		for idx, tLast in pairs(tDoThisLast) do
			self:DrawLootItem(tLast, wndArg:FindChild("GivenRewardsItems"))
		end

		nGivenContainerHeight = wndArg:FindChild("GivenRewardsItems"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		wndArg:FindChild("GivenContainer"):SetAnchorOffsets(0, 0, 0, nGivenContainerHeight)
		wndArg:FindChild("GivenContainer"):Show(true)
		
		wndArg:FindChild("GivenRewardsText"):Show(true)
		nGivenContainerHeight = nGivenContainerHeight + wndArg:FindChild("GivenRewardsText"):GetHeight()
	end

	local nChoiceContainerHeight = 0
	if tRewardInfo.arRewardChoices and #tRewardInfo.arRewardChoices > 0 and idState ~= DialogSys.DialogState_QuestComplete then -- GOTCHA: Choices are shown in Player, not NPC for QuestComplete
		for key, tCurrReward in ipairs(tRewardInfo.arRewardChoices) do
			self:DrawLootItem(tCurrReward, wndArg:FindChild("ChoiceRewardsItems"))
		end

		nChoiceContainerHeight = wndArg:FindChild("ChoiceRewardsItems"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(a,b) return b:FindChild("LootIconCantUse"):IsShown() end)
		wndArg:FindChild("ChoiceContainer"):SetAnchorOffsets(0, 0, 0, nChoiceContainerHeight)
		wndArg:FindChild("ChoiceContainer"):Show(true)
		wndArg:FindChild("ChoiceRewardsText"):Show(#tRewardInfo.arRewardChoices > 1)

		if #tRewardInfo.arRewardChoices > 1 then
			nChoiceContainerHeight = nChoiceContainerHeight + wndArg:FindChild("ChoiceRewardsText"):GetHeight()
		end -- Do text padding after SetAnchorOffsets so the box doesn't expand
	end

	wndArg:FindChild("RewardsArrangeVert"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	if nGivenContainerHeight + nChoiceContainerHeight == 0 then
		return 0
	end
	return nGivenContainerHeight + nChoiceContainerHeight + 30 -- TODO hardcoded formatting
end

function CommDisplay:DrawLootItem(tCurrReward, wndParentArg)
	if tCurrReward and tCurrReward.eType == Quest.Quest2RewardType_Money then
		local wndLootItem = Apollo.LoadForm(self.xmlDoc, "LootItemSimple", wndParentArg, self)
		local wndLootCashWindow = wndLootItem:FindChild("LootCashWindow")
		wndLootCashWindow:Show(true)
		wndLootCashWindow:SetMoneySystem(tCurrReward.eCurrencyType or 0)
		wndLootCashWindow:SetAmount(tCurrReward.nAmount, 0)
		wndLootCashWindow:SetTooltip(wndLootCashWindow:GetCurrency():GetMoneyString())
	elseif tCurrReward and tCurrReward.eType == Quest.Quest2RewardType_AccountCurrency then
		local wndLootItem = Apollo.LoadForm(self.xmlDoc, "LootItemSimple", wndParentArg, self)
		local wndLootCashWindow = wndLootItem:FindChild("LootCashWindow")
		wndLootCashWindow:Show(true)
		wndLootCashWindow:SetMoneySystem(Money.CodeEnumCurrencyType.GroupCurrency, 0, 0, tCurrReward.eAccountCurrencyType or 0)
		wndLootCashWindow:SetAmount(tCurrReward.nAmount, 0)
		wndLootCashWindow:SetTooltip(wndLootCashWindow:GetCurrency():GetMoneyString())
	end

	local strIconSprite = ""
	local wndCurrReward = nil
	if tCurrReward and tCurrReward.eType == Quest.Quest2RewardType_Item then
		local itemReward = tCurrReward.itemReward
		wndCurrReward = Apollo.LoadForm(self.xmlDoc, "LootItem", wndParentArg, self)
		wndCurrReward:FindChild("LootIconCantUse"):Show(self:HelperPrereqFailed(itemReward))
		wndCurrReward:FindChild("LootDescription"):SetText(itemReward:GetName())
		wndCurrReward:FindChild("LootDescription"):SetTextColor(arEvalColors[itemReward:GetItemQuality()])
		wndCurrReward:SetData(tCurrReward.itemReward)
		Tooltip.GetItemTooltipForm(self, wndCurrReward, tCurrReward.itemReward, {bPrimary = true, bSelling = false, itemCompare = itemReward:GetEquippedItemForItemType()})
		strIconSprite = itemReward:GetIcon()

	elseif tCurrReward and tCurrReward.eType == Quest.Quest2RewardType_TradeSkillXp then
		-- Tradeskill has overloaded fields: objectId is factionId. objectAmount is rep amount.
		wndCurrReward = Apollo.LoadForm(self.xmlDoc, "LootItem", wndParentArg, self)

		local strText = String_GetWeaselString(Apollo.GetString("CommDisp_TradeXPReward"), tCurrReward.nXP, tCurrReward.strTradeskill)
		wndCurrReward:FindChild("LootDescription"):SetText(strText)
		wndCurrReward:SetTooltip(strText)
		strIconSprite = "ClientSprites:Icon_ItemMisc_tool_0001"

	elseif tCurrReward and tCurrReward.eType == Quest.Quest2RewardType_GrantTradeskill then
		-- Tradeskill has overloaded fields: objectId is tradeskillId.
		wndCurrReward = Apollo.LoadForm(self.xmlDoc, "LootItem", wndParentArg, self)
		wndCurrReward:FindChild("LootDescription"):SetText(tCurrReward.strTradeskill)
		wndCurrReward:SetTooltip("")
		strIconSprite = "ClientSprites:Icon_ItemMisc_tool_0001"

	elseif tCurrReward and tCurrReward.eType == Quest.Quest2RewardType_Reputation then
		wndCurrReward = Apollo.LoadForm(self.xmlDoc, "LootItem", wndParentArg, self)
		strIconSprite = "Icon_ItemMisc_UI_Item_Parchment"
		wndCurrReward:FindChild("LootDescription"):SetText(String_GetWeaselString(Apollo.GetString("Dialog_FactionRepReward"), tCurrReward.nAmount, tCurrReward.strFactionName))
		wndCurrReward:SetTooltip(String_GetWeaselString(Apollo.GetString("Dialog_FactionRepReward"), tCurrReward.nAmount, tCurrReward.strFactionName))
	end

	if wndCurrReward then
		local wndLootIcon = wndCurrReward:FindChild("LootIcon")
		wndLootIcon:SetSprite(strIconSprite)
		if tCurrReward.nAmount ~= nil then
			wndLootIcon:SetText(tCurrReward.nAmount > 1 and tCurrReward.nAmount or "")
		end
	end
end

function CommDisplay:OnLootItemMouseUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and wndHandler:GetData() then
		Event_FireGenericEvent("GenericEvent_ContextMenuItem", wndHandler:GetData())
	end
end

function CommDisplay:OnGenerateTooltip(wndHandler, wndControl, eType, arg1, arg2)
	-- For reward icon events from XML
	local xml = nil
	if eType == Tooltip.TooltipGenerateType_ItemData then
		local itemCurr = arg1
		local itemEquipped = itemCurr:GetEquippedItemForItemType()

		Tooltip.GetItemTooltipForm(self, wndControl, itemCurr, {bPrimary = true, bSelling = self.bVendorOpen, itemCompare = itemEquipped})

	elseif eType == Tooltip.TooltipGenerateType_Reputation or tType == Tooltip.TooltipGenerateType_TradeSkill then
		xml = XmlDoc.new()
		xml:StartTooltip(Tooltip.TooltipWidth)
		xml:AddLine(arg1)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Money then
		xml = XmlDoc.new()
		xml:StartTooltip(Tooltip.TooltipWidth)
		xml:AddLine(arg1:GetMoneyString(), CColor.new(1, 1, 1, 1), "CRB_InterfaceMedium")
		wndControl:SetTooltipDoc(xml)
	else
		wndControl:SetTooltipDoc(nil)
	end
end

function CommDisplay:HelperPrereqFailed(tCurrItem)
	return tCurrItem and tCurrItem:IsEquippable() and not tCurrItem:CanEquip()
end

local CommDisplayInst = CommDisplay:new()
CommDisplayInst:Init()
