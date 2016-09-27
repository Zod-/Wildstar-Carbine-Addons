-----------------------------------------------------------------------------------------------
-- Client Lua Script for Storefront/Loyalty.lua
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "StorefrontLib"
require "AccountItemLib"
require "RewardTrackLib"
require "PetCustomizationLib"
require "GameLib"
require "Item"
require "Money"
require "RewardTrack"
require "Unit"
require "Tooltip"
require "WindowLocation"
require "Sound"

local Loyalty = {} 

function Loyalty:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.tWndRefs = {}
	o.knLoyaltyPointProgressUpdateRate = 0.05
	o.nCurRewardTrackId = nil
	
	o.ktSoundLoyaltyMTXCosmicRewardsUnlock =
	{
		[1] = Sound.PlayUIMTXCosmicRewardsUnlock01,
		[2] = Sound.PlayUIMTXCosmicRewardsUnlock02,
		[3] = Sound.PlayUIMTXCosmicRewardsUnlock03,
		[4] = Sound.PlayUIMTXCosmicRewardsUnlock04,
		[5] = Sound.PlayUIMTXCosmicRewardsUnlock05,
	}
	
	o.ktSoundLoyaltyMTXLoyaltyBarHover =
	{
		[false] = Sound.PlayUIMTXLoyaltyBarTierHover,
		[true] = Sound.PlayUIMTXLoyaltyBarTierHoverTopTier,
	}
	
    return o
end

function Loyalty:Init()
    Apollo.RegisterAddon(self)
end

function Loyalty:OnLoad()	
	self.timerToMax = ApolloTimer.Create(1.0, false, "OnMaximumReached", self)
	self.timerToMax:Stop()
	
	self.timerLoyaltyPointProgressUpdate = ApolloTimer.Create(self.knLoyaltyPointProgressUpdateRate, true, "UpdateLoyaltyPointProgress", self)
	self.timerLoyaltyPointProgressUpdate:Stop()
	
	self.timerLoyaltyPointHeaderProgressUpdate = ApolloTimer.Create(self.knLoyaltyPointProgressUpdateRate, true, "UpdateLoyaltyPointHeaderProgress", self)
	self.timerLoyaltyPointHeaderProgressUpdate:Stop()
	
	self.xmlDoc = XmlDoc.CreateFromFile("Loyalty.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Loyalty:OnDocumentReady()
	Apollo.RegisterEventHandler("RewardTrackActive", "OnRewardTrackActive", self)
	Apollo.RegisterEventHandler("RewardTrackUpdated", "OnRewardTrackUpdated", self)
	
	-- Store UI Events
	Apollo.RegisterEventHandler("AddHeaderDisplay", "OnAddHeaderDisplay", self)
	Apollo.RegisterEventHandler("UpdateHeaderDisplay", "OnUpdateHeaderDisplay", self)
	Apollo.RegisterEventHandler("ShowDialog", "OnShowDialog", self)
	
	Event_FireGenericEvent("RequestHeaderDisplay")
end

function Loyalty:OnAddHeaderDisplay(wndParent, wndParent2)
	if self.wndLoyalty == nil or not self.wndLoyalty:IsValid() then
		local wndMain = Apollo.LoadForm(self.xmlDoc, "HeaderDisplay", wndParent, self)
		self.wndLoyalty = wndMain
		
		self.wndLoyaltyPercent = wndMain:FindChild("Percent")
		self.wndLoyaltyProgress = wndMain:FindChild("LoyaltyProgress")
		self.wndLoyaltyExpandBtnIcon = wndMain:FindChild("Icon")
		self.wndLoyaltyExpandBtnAnimation = wndMain:FindChild("Animation")
	end
	
	self:AddLoyaltyDialog(wndParent2)
end

function Loyalty:OnShowDialog(strDialogName, wndParent)
	if strDialogName ~= "Loyalty" then
		if self.tWndRefs.wndMain ~= nil and self.tWndRefs.wndMain:IsValid() then
			self.tWndRefs.wndMain:Show(false)
			self:ResetLoyaltyPointProgress()
		end
		return
	end
	
	self:BuildLoyaltyPage(RewardTrackLib.GetActiveRewardTrackByType(RewardTrackLib.CodeEnumRewardTrackType.Loyalty))
	self.tWndRefs.wndMain:Show(true)
end

function Loyalty:AddLoyaltyDialog(wndParent)
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		local wndMain = Apollo.LoadForm(self.xmlDoc, "Loyalty", wndParent, self)
		self.tWndRefs.wndMain = wndMain
		self.tWndRefs.wndParent = wndParent
		
		-- Dialog
		self.tWndRefs.wndLoyaltyProgressBar = wndMain:FindChild("Right:ProgressBar:ProgressBar")
		self.tWndRefs.wndLoyaltyPointProgress = wndMain:FindChild("Right:ProgressBar:LoyaltyPointProgress")
		self.tWndRefs.wndTier = wndMain:FindChild("Left:Level:TierText")
		self.tWndRefs.wndTierPoints = wndMain:FindChild("Left:Level:TierPoints")
		self.tWndRefs.wndTierIcon = wndMain:FindChild("Left:Icon")
		self.tWndRefs.wndTierBody = wndMain:FindChild("Left:Intro:Body")
		self.tWndRefs.wndNextTierBtn = wndMain:FindChild("Left:Level:NextTierBtn")
		self.tWndRefs.wndPrevTierBtn = wndMain:FindChild("Left:Level:PrevTierBtn")
		self.tWndRefs.wndLoyaltyContentContainer = wndMain:FindChild("Right:ContentContainer")
		
		self.nCurRewardTrackId = nil
	end
end

function Loyalty:OnUpdateHeaderDisplay()
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	self.rtCurrent = RewardTrackLib.GetActiveRewardTrackByType(RewardTrackLib.CodeEnumRewardTrackType.Loyalty)
	self:UpdateRewardTrack(self.rtCurrent)
	self.wndLoyaltyProgress:SetProgress(0)
	self:BuildLoyaltyWindow(RewardTrackLib.GetActiveRewardTrackByType(RewardTrackLib.CodeEnumRewardTrackType.Loyalty))
end

function Loyalty:OnRewardTrackActive(eNewType, rtNew, rtOld)
	if not self.tWndRefs.wndMain or eNewType ~= RewardTrackLib.CodeEnumRewardTrackType.Loyalty then
		return
	end
	
	self:UpdateRewardTrack(rtNew)
end

function Loyalty:OnRewardTrackUpdated(rtUpdated)
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() or not self.tWndRefs.wndMain:IsShown() or rtUpdated:GetType() ~= RewardTrackLib.CodeEnumRewardTrackType.Loyalty then
		return
	end
	
	self:UpdateRewardTrack(rtUpdated)
end

function Loyalty:UpdateRewardTrack(rtUpdated)
	if rtUpdated:GetId() ~= self.wndLoyaltyExpandBtnIcon:GetData() then
		local nMaxProgress = self.wndLoyaltyProgress:GetMax()
		local nProgressTime = 0.5 * (nMaxProgress - self.wndLoyaltyProgress:GetProgress())
		self.wndLoyaltyProgress:SetProgress(nMaxProgress, nProgressTime)
		self.timerToMax:Set(nProgressTime, false, "OnMaximumReached")
	else
		local nCurProgress = rtUpdated:GetRewardPointsEarned()
		local nProgressTime = 2 * (nCurProgress - self.wndLoyaltyProgress:GetProgress())
		self.wndLoyaltyProgress:SetProgress(nCurProgress, math.abs(nProgressTime))
	end
	self:BuildLoyaltyWindow(rtUpdated)
	
	if self.tWndRefs.wndMain:IsShown() then
		self:SetLoyaltyPointProgress(self.nCurRewardPointsEarned)
		self:UpdateLoyaltyPointProgress()
	end
	self.timerLoyaltyPointHeaderProgressUpdate:Start()
end

function Loyalty:BuildLoyaltyWindow(rtUpdated)
	if rtUpdated == nil then
		return
	end

	local arRewards = rtUpdated:GetAllRewards()
	local nRewardMax = arRewards[#arRewards].nCost
	
	self.nCurRewardPointsEarned = rtUpdated:GetRewardPointsEarned()
	
	local wndLoyaltyNumberComplete = self.wndLoyalty:FindChild("NumberComplete")
	local strNumberComplete = String_GetWeaselString(Apollo.GetString("Storefront_Fraction"), Apollo.FormatNumber(self.nCurRewardPointsEarned, 0, true), Apollo.FormatNumber(nRewardMax, 0, true))
	local strLoyaltyPercent = String_GetWeaselString(Apollo.GetString("MarketplaceCommodity_AuctionhouseTax"), self.nCurRewardPointsEarned / nRewardMax * 100)
	
	wndLoyaltyNumberComplete:SetAML(string.format('<T Font=\"CRB_HeaderTiny\" TextColor=\"UI_TextMetalGoldHighlight\" >%s  </T><T Font=\"CRB_HeaderTiny\" TextColor=\"UI_TextMetalBodyHighlight\" >%s</T>', strNumberComplete, strLoyaltyPercent))

	self.wndLoyaltyProgress:SetMax(nRewardMax)
	if self.wndLoyaltyProgress:GetProgress() == 0 and self.nCurRewardPointsEarned ~= 0 then
		self.wndLoyaltyProgress:SetProgress(self.nCurRewardPointsEarned)
	end
	self.wndLoyaltyProgress:SetTooltip(String_GetWeaselString(Apollo.GetString("Storefront_LoyaltyBarTooltip"), self.nCurRewardPointsEarned, nRewardMax))
	
	self.wndLoyaltyExpandBtnIcon:SetData(rtUpdated:GetId())
	self.wndLoyaltyExpandBtnIcon:SetSprite(rtUpdated:GetImageAssetPath())
	
	if self.nCurRewardTrackId == rtUpdated:GetId() then -- don't update milestones if the reward track hasn't changed
		return
	end
	
	self.nCurRewardTrackId = rtUpdated:GetId()
	
	local wndMilestoneContainer = self.wndLoyalty:FindChild("LoyaltyMilestoneContainer")
	wndMilestoneContainer:DestroyChildren()
	
	self.tMilestones = { }
	
	local nPreviousCost = 0
	local wndRewardPoint = nil
	for idx, tReward in pairs(arRewards) do
		local wndDropdown = nil
		if tReward.nCost ~= nPreviousCost then
			wndRewardPoint = Apollo.LoadForm(self.xmlDoc, "LoyaltyMilestone", wndMilestoneContainer, self)
			
			local nLeft, nTop, nRight, nBottom = wndRewardPoint:GetOriginalLocation():GetOffsets()
			nRight = self.wndLoyaltyProgress:GetWidth() / nRewardMax * tReward.nCost
			local nHalfWidth = wndRewardPoint:GetWidth() / 2.0
			self.tMilestones[tReward.nCost] = { }
			if idx == #arRewards then
				wndRewardPoint:FindChild("LoyaltyMilestoneIcon"):Destroy()
			else
				wndRewardPoint:FindChild("LoyaltyMilestoneFinalIcon"):Destroy()
				self.tMilestones[tReward.nCost].wndIcon = wndRewardPoint:FindChild("LoyaltyMilestoneIcon")
				self.tMilestones[tReward.nCost].wndAnimation = wndRewardPoint:FindChild("LoyaltyMilestoneAnimation")
				self.tMilestones[tReward.nCost].wndAnimation2 = wndRewardPoint:FindChild("LoyaltyMilestoneAnimation2")
				self.tMilestones[tReward.nCost].bAlreadyCompleted = false
			end
			
			self.tMilestones[tReward.nCost].eSound = self.ktSoundLoyaltyMTXCosmicRewardsUnlock[idx]
			
			wndRewardPoint:SetAnchorOffsets( nRight - nHalfWidth, nTop, nRight + nHalfWidth, nBottom)
			
			wndDropdown = wndRewardPoint:FindChild("RewardPointTooltip")
			wndDropdown:SetData(nRewardMax == tReward.nCost)
		else
			wndDropdown = wndRewardPoint:FindChild("RewardPointTooltip")
		end
		
		local wndPointHeader = wndDropdown:FindChild("Header")
		local wndTooltipContainer = wndDropdown:FindChild("TooltipContainer")
		
		-- Used for resizing later
		local nHeightDelta = wndDropdown:GetHeight() - wndPointHeader:GetHeight() - wndTooltipContainer:GetHeight()
		
		local strRewardHeader = String_GetWeaselString(Apollo.GetString("Storefront_PointsToUnlock"), tReward.nCost)
		if bIsClaimed then
			strRewardHeader = Apollo.GetString("Storefront_RewardClaimed")
		end
		wndPointHeader:SetText(strRewardHeader)
		
		for idx = 1, tReward.nNumRewardChoices do
			local wndTooltip = Apollo.LoadForm(self.xmlDoc, "RewardObject", wndTooltipContainer, self)
			local wndHeader = wndTooltip:FindChild("Header")
			local wndLabel = wndHeader:FindChild("RewardLabel")
			local wndItem = wndHeader:FindChild("ItemReward")
			local wndIcon = wndItem:FindChild("ItemIcon")
			local wndIconPadding = wndItem:FindChild("ItemStackCount")
			local nPadding = 8
			
			if tReward.tRewardChoices[idx].accountItemReward then
				if tReward.tRewardChoices[idx].accountItemReward.item then
					wndLabel:SetText(tReward.tRewardChoices[idx].accountItemReward.item:GetName())
					
					if wndIcon:GetData() == nil then
						wndIcon:GetWindowSubclass():SetItem(tReward.tRewardChoices[idx].accountItemReward.item)
						wndItem:Show(true)
					end
					
					local nStackCount = tReward.tRewardChoices[idx].accountItemReward.item:GetStackCount()
					if nStackCount > 1 then
						wndItem:FindChild("ItemStackCount"):SetText(nStackCount)
					end
				elseif tReward.tRewardChoices[idx].accountItemReward.entitlement then
					wndLabel:SetText(tReward.tRewardChoices[idx].accountItemReward.entitlement.name)
					
					if wndIcon:GetSprite() == "" and tReward.tRewardChoices[idx].accountItemReward.icon ~= "" then
						wndIcon:GetWindowSubclass():SetItem(nil)
						wndIcon:SetSprite(tReward.tRewardChoices[idx].accountItemReward.icon)
						wndItem:Show(true)
					end
				end
				
				local nLabelWidth, nLabelHeight = wndLabel:SetHeightToContentHeight()
				local nHeight = nLabelHeight + nPadding
				if wndIcon:IsShown() and nHeight < wndIconPadding:GetHeight() then
					nHeight = wndIconPadding:GetHeight()
				end

				
				local nOriginalHeaderBottom = ({wndHeader:GetOriginalLocation():GetOffsets()})[4]
				nLeft, nTop, nRight, nBottom = wndHeader:GetAnchorOffsets()
				wndHeader:SetAnchorOffsets(nLeft, nTop, nRight, math.max(nTop + nHeight, nOriginalHeaderBottom))
				
				local nTooltipHeight = wndHeader:GetHeight()
				nLeft, nTop, nRight, nBottom = wndTooltip:GetAnchorOffsets()
				wndTooltip:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTooltipHeight)
			end
		end
		
		local nContainerHeight = wndTooltipContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		local nDropdownHeight = nContainerHeight + wndPointHeader:GetHeight() + nHeightDelta
		
		local nDropdownLeft, nDropdownTop, nDropdownRight, nDropdownBottom = wndDropdown:GetAnchorOffsets()
		wndDropdown:SetAnchorOffsets(nDropdownLeft, nDropdownTop, nDropdownRight, nDropdownTop + nDropdownHeight)
		
		nPreviousCost = tReward.nCost
	end
	
	self:UpdateLoyaltyPointHeaderProgress()
end

function Loyalty:OnMaximumReached()
	self:BuildLoyaltyWindow(RewardTrackLib.GetActiveRewardTrackByType(RewardTrackLib.CodeEnumRewardTrackType.Loyalty))
	self.wndLoyaltyProgress:SetSprite("BK3:UI_BK3_Holo_RefreshReflectionSquare_anim")
	self.wndLoyaltyExpandBtnAnimation:SetSprite("LoginIncentives:sprLoginIncentives_Burst")
end

function Loyalty:ShowMilestoneTooltip(wndHandler, wndControl)
	if wndHandler == wndControl then
		local wndTooltip = wndHandler:FindChild("RewardPointTooltip")
		if not wndTooltip:IsShown() then
			wndTooltip:Show(true)
			Sound.Play(self.ktSoundLoyaltyMTXLoyaltyBarHover[wndTooltip:GetData()])
		end
	end
end

function Loyalty:HideMilestoneTooltip(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:FindChild("RewardPointTooltip"):Show(false)
	end
end

function Loyalty:BuildLoyaltyPage(rtUpdated)
	if rtUpdated == nil then
		-- Display error
		self.tWndRefs.wndFullBlocker:Show(true)
		self:FullBlockerHelper(self.tWndRefs.wndFullBlockerPrompt)
		self.tWndRefs.wndFullBlockerPromptHeader:SetText(Apollo.GetString("Storefront_CosmicRewardsUpdatedDialogHeader"))
		self.tWndRefs.wndFullBlockerPromptBody:SetText(Apollo.GetString("Storefront_CosmicRewardsUpdatedDialogBody"))
		self.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = nil })
		return
	end
	
	local arRewards = rtUpdated:GetAllRewards()
	if arRewards == nil then
		-- Display error
		self.tWndRefs.wndFullBlocker:Show(true)
		self:FullBlockerHelper(self.tWndRefs.wndFullBlockerPrompt)
		self.tWndRefs.wndFullBlockerPromptHeader:SetText(Apollo.GetString("Storefront_CosmicRewardsUpdatedDialogHeader"))
		self.tWndRefs.wndFullBlockerPromptBody:SetText(Apollo.GetString("Storefront_CosmicRewardsUpdatedDialogBody"))
		self.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = nil })
		return
	end
	
	self.rtCurrent = rtUpdated
	
	self.tWndRefs.wndNextTierBtn:Enable(self.rtCurrent:GetChild() ~= nil)
	self.tWndRefs.wndPrevTierBtn:Enable(self.rtCurrent:GetParent() ~= nil)
	
	self.tWndRefs.wndTier:SetText(String_GetWeaselString(Apollo.GetString("Storefront_TierNum"), self.rtCurrent:GetName()))
	self.tWndRefs.wndTierPoints:SetText(String_GetWeaselString(Apollo.GetString("Storefront_LoyaltyPoints"), Apollo.FormatNumber(self.nCurRewardPointsEarned, 0, true)))
	
	self.tWndRefs.wndLoyaltyContentContainer:DestroyChildren()
	
	self.tLoyaltyExpandedItemWindows = { }
	self.tRewardStyles = 
	{ 
		tRewards = { },
		tDefault = 
		{
			strBackgroundSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneBlue", 
			strBackgroundColor = "UI_AlphaPercent25", 
			strTextColor = "UI_TextHoloBodyCyan", 
			strIndicatorSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneIcon_Upcoming",
			strIconSprite = "MTX:UI_BK3_MTX_LoyaltyItemRed",
		},
		tComplete = 
		{
			strBackgroundSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneGreen", 
			strBackgroundColor = "UI_WindowBGDefault", 
			strTextColor = "UI_WindowTitleYellow", 
			strIndicatorSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneIcon_Complete",
			strBurstSprite = "sprMM_QuestZonePulseNoCycle",
			strIconSprite = "MTX:UI_BK3_MTX_LoyaltyItemGreen",
		},
		tFinalRewardDefault = 
		{ 
			strBackgroundSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneBlueComplete", 
			strBackgroundColor = "UI_WindowBGDefault", 
			strTextColor = "UI_TextHoloBodyHighlight", 
			strIndicatorSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneIcon_Upcoming",
			strIconSprite = "MTX:UI_BK3_MTX_LoyaltyItemRed",
		},
		tFinalRewardCurrent = 
		{ 
			strBackgroundSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneGreenComplete", 
			strBackgroundColor = "UI_WindowBGDefault", 
			strTextColor = "UI_WindowTitleYellow", 
			strIndicatorSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneIcon_Complete",
			strIconSprite = "MTX:UI_BK3_MTX_LoyaltyItemGreen",
		},
		tFinalRewardComplete = 
		{ 
			strBackgroundSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneGreenComplete", 
			strBackgroundColor = "UI_WindowBGDefault", 
			strTextColor = "UI_WindowTitleYellow", 
			strIndicatorSprite = "MTX:UI_BK3_MTX_LoyaltyMilestoneIcon_Active",
			strIconSprite = "MTX:UI_BK3_MTX_LoyaltyItemYellow",
		},
	}
	
	local arIconWindows = { } -- needed to quickly get and reuse existing windows
	for idx, tReward in pairs(arRewards) do
		local wndLoyaltyExpandedItem = self.tLoyaltyExpandedItemWindows["LoyaltyExpandedItem" .. tReward.nCost] -- reuse windows if they exist
		if wndLoyaltyExpandedItem == nil then -- if not then add them
			wndLoyaltyExpandedItem = Apollo.LoadForm(self.xmlDoc, "LoyaltyExpandedItem", self.tWndRefs.wndLoyaltyContentContainer, self)
			self.tLoyaltyExpandedItemWindows["LoyaltyExpandedItem" .. tReward.nCost] = wndLoyaltyExpandedItem
		end
		
		local wndLoyaltyItemContainer = wndLoyaltyExpandedItem:FindChild("ItemContainer")
		
		if self.tRewardStyles.tRewards[tReward.nCost] == nil then -- don't overwrite existing windows
			arIconWindows = { }
		end
		local nIconWindowCount = #arIconWindows -- get count current count, if it has windows and it can
		for nIdx, tReward in pairs(tReward.tRewardChoices) do
			local wndLoyaltyExpandedIcons = Apollo.LoadForm(self.xmlDoc, "LoyaltyExpandedIcons", wndLoyaltyItemContainer, self)
			
			local wndItemIcon = wndLoyaltyExpandedIcons:FindChild("ItemIcon")
			
			if tReward.accountItemReward.item then
				wndItemIcon:GetWindowSubclass():SetItem(tReward.accountItemReward.item)
				if Tooltip ~= nil and Tooltip.GetItemTooltipForm ~= nil then
					Tooltip.GetItemTooltipForm(self, wndItemIcon, tReward.accountItemReward.item, {bPrimary = true, bSelling = false, itemCompare = nil})
				end
				
			elseif tReward.accountItemReward.entitlement then
				if tReward.accountItemReward.icon ~= "" then
					wndItemIcon:GetWindowSubclass():SetItem(nil)
					wndItemIcon:SetSprite(tReward.accountItemReward.icon)
					self:BuildEntitlementTooltip(wndItemIcon, tReward.accountItemReward.entitlement)
				end
				
			end
			
			arIconWindows[nIconWindowCount + nIdx] = { }
			arIconWindows[nIconWindowCount + nIdx].wndBackground = wndLoyaltyExpandedIcons:FindChild("Background")
			arIconWindows[nIconWindowCount + nIdx].wndIcon = wndItemIcon
		end
		
		local wndLoyaltyPts = wndLoyaltyExpandedItem:FindChild("LoyaltyPoints")
		wndLoyaltyPts:SetText(Apollo.FormatNumber(tReward.nCost, 0, true))
		
		self.tRewardStyles.tRewards[tReward.nCost] = 
		{ 
			wndLoyaltyExpandedItem = wndLoyaltyExpandedItem, 
			wndBackground = wndLoyaltyExpandedItem:FindChild("Background"),
			wndMilestoneRunner = wndLoyaltyExpandedItem:FindChild("MilestoneRunner"),
			wndIndicator = wndLoyaltyExpandedItem:FindChild("Indicator"),
			wndBurst = wndLoyaltyExpandedItem:FindChild("Burst"),
			wndLoyaltyPoints = wndLoyaltyExpandedItem:FindChild("LoyaltyPoints"),
			bLast = idx == #arRewards,
			arChildren = arIconWindows,
			bAlreadyCompleted = false,
			eSound = self.ktSoundLoyaltyMTXCosmicRewardsUnlock[idx]
		}
		
		wndLoyaltyItemContainer:ArrangeChildrenVert()
	end
	
	self:SetLoyaltyPointProgress(self.rtCurrent:GetRewardPointsEarned())
	
	-- Resize reward columns to match progress bar
	local tLoyaltyItemContainers = self.tWndRefs.wndLoyaltyContentContainer:GetChildren()
	local nLoyaltyItemContainers = #tLoyaltyItemContainers
	if nLoyaltyPtsEarned == nil then
		nLoyaltyPtsEarned = 0
		bShowProgressBar = false
	end
	for idx, wndLoyaltyExpandedItem in ipairs(tLoyaltyItemContainers) do
		local nLeft, nTop, nRight, nBottom = wndLoyaltyExpandedItem:GetAnchorOffsets()
		local nLoyaltyExpandedItemWidth = self.tWndRefs.wndLoyaltyProgressBar:GetWidth() /  nLoyaltyItemContainers
		wndLoyaltyExpandedItem:SetAnchorOffsets(nLeft, nTop, nLeft + nLoyaltyExpandedItemWidth, nBottom)
	end
	
	self:UpdateLoyaltyPointProgress()
	
	self.tWndRefs.wndLoyaltyContentContainer:ArrangeChildrenHorz()
end

function Loyalty:OnNextTier(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndLoyaltyProgressBar:SetProgress(0) -- Need to empty the progress bar
	self:BuildLoyaltyPage(self.rtCurrent:GetChild())
end

function Loyalty:OnPrevTier(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:BuildLoyaltyPage(self.rtCurrent:GetParent())
end

function Loyalty:BuildEntitlementTooltip(wndParent, tEntitlement)
	local wndEntitlementTooltip = wndParent:LoadTooltipForm(self.xmlDoc, "EntitlementTooltip", self)
	local wndEntitlementTooltipContainer = wndEntitlementTooltip:FindChild("Container")
	local wndEntitlementName = wndEntitlementTooltipContainer:FindChild("Name")
	local wndEntitlementDescription = wndEntitlementTooltipContainer:FindChild("Description")
	
	local nHeight = wndEntitlementTooltip:GetHeight()
	local nContainerHeight = wndEntitlementTooltipContainer:GetHeight()
	local nHeightPadding = nHeight - nContainerHeight
	
	wndEntitlementName:SetText(tEntitlement.name)
	wndEntitlementName:SetHeightToContentHeight()
	wndEntitlementDescription:SetText(tEntitlement.description)
	wndEntitlementDescription:SetHeightToContentHeight()
	
	local nLeft, nTop, nRight, nBottom = wndEntitlementTooltip:GetAnchorOffsets()
	
	nContainerHeight = wndEntitlementTooltipContainer:ArrangeChildrenVert()
	wndEntitlementTooltip:SetAnchorOffsets(nLeft, nTop, nRight, nHeightPadding + nContainerHeight)
end

function Loyalty:SetLoyaltyPointProgress(nPoints)
	local nCurrentProgress = self.tWndRefs.wndLoyaltyProgressBar:GetProgress()
	local nRewardTrackId = self.rtCurrent:GetId()
	local nActualPoints = nCurrentProgress
	
	local arRewards = self.rtCurrent:GetAllRewards()
	local nMaxPts = arRewards[#arRewards].nCost
	local bShowProgressBar = true
	if nPoints == nil then
		nPoints = 0
		bShowProgressBar = false
	elseif nPoints > nMaxPts then -- Cap the progress bar but allow the point count to exceed
		nActualPoints = nPoints
		nPoints = nMaxPts
	end
	
	-- Calculate the fill rate per second of the progress bar
	local tLoyaltyItemContainers = self.tWndRefs.wndLoyaltyContentContainer:GetChildren()
	local nLoyaltyItemContainers = #tLoyaltyItemContainers
	local nLoyaltyItemProgressBarConstant = 2.5
	if nLoyaltyItemContainers == 0 then	-- can't divide by zero
		nLoyaltyItemContainers = 1
	end
	local nProgressRate = (nMaxPts / nLoyaltyItemContainers) * nLoyaltyItemProgressBarConstant
	
	-- Initial values of progress bar for animated progress
	self.tWndRefs.wndLoyaltyProgressBar:SetMax(nMaxPts)
	self.tWndRefs.wndLoyaltyProgressBar:SetProgress(nCurrentProgress)
	
	local nPercentCompleted = nPoints / nMaxPts
	local nProgressBarWidth = self.tWndRefs.wndLoyaltyProgressBar:GetWidth()
	
	-- Reset progress bar points display
	local tLoyaltyPointProgressLoc = self.tWndRefs.wndLoyaltyPointProgress:GetOriginalLocation()
	local nLeft, nTop, nRight, nBottom = tLoyaltyPointProgressLoc:GetOffsets()
	local nPntLeft, nPntTop, nPntRight, nPntBottom = tLoyaltyPointProgressLoc:GetPoints()
	self.tWndRefs.wndLoyaltyPointProgress:SetText(Apollo.FormatNumber(nActualPoints, 0, true))
	self.tWndRefs.wndLoyaltyPointProgress:SetData({ nActualPoints = nActualPoints, nAdjustedPoints = nPoints })
	
	local nLoyaltyPointProgPos = nProgressBarWidth * nPercentCompleted
	
	self.tWndRefs.wndTierIcon:SetSprite(self.rtCurrent:GetImageAssetPath())
	
	if self.nCurRewardTrackId ~= nRewardTrackId then
		nProgressRate = nil
		nPercentCompleted = 1
		nLoyaltyPointProgPos = nProgressBarWidth * nPercentCompleted
		self.tWndRefs.wndLoyaltyPointProgress:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	else 
		self.tWndRefs.wndLoyaltyPointProgress:SetAnchorOffsets(self.tWndRefs.wndLoyaltyPointProgress:GetAnchorOffsets())
		local tLoc = WindowLocation.new({ fPoints = { nPntLeft, nPntTop, nPntRight, nPntBottom }, nOffsets = { nLeft + nLoyaltyPointProgPos, nTop, nRight + nLoyaltyPointProgPos, nBottom }})
		self.tWndRefs.wndLoyaltyPointProgress:TransitionMove(tLoc, math.abs(nPoints - nCurrentProgress) / nProgressRate)
		self.timerLoyaltyPointProgressUpdate:Start()
	end
	if not bShowProgressBar then --Progress bar isn't shown on future tiers
		self.tWndRefs.wndTierIcon:SetBGColor("UI_AlphaBlackPercent50")
		self.tWndRefs.wndTierIcon:FindChild("LockIcon"):Show(true)
		self.tWndRefs.wndTierBody:SetText(Apollo.GetString("Storefront_CosmicPointTierLocked"))
		self.tWndRefs.wndTierBody:SetTextColor("Reddish")
	else
		self.tWndRefs.wndTierIcon:SetBGColor("white")
		self.tWndRefs.wndTierIcon:FindChild("LockIcon"):Show(false)
		self.tWndRefs.wndTierBody:SetText(Apollo.GetString("Storefront_CosmicPointsDescriptionProtoBucks"))
		self.tWndRefs.wndTierBody:SetTextColor("UI_TextHoloBodyCyan")
	end
	self.tWndRefs.wndLoyaltyProgressBar:Show(bShowProgressBar)
	self.tWndRefs.wndLoyaltyProgressBar:EnableGlow(self.nCurRewardTrackId == nRewardTrackId)
	self.tWndRefs.wndLoyaltyProgressBar:SetProgress(nPoints, nProgressRate)
	self.tWndRefs.wndLoyaltyPointProgress:Show(self.nCurRewardTrackId == nRewardTrackId)
end

function Loyalty:ResetLoyaltyPointProgress()
	local rtCurrent = self.rtCurrent
	if rtCurrent == nil then
		rtCurrent = RewardTrackLib.GetActiveRewardTrackByType(RewardTrackLib.CodeEnumRewardTrackType.Loyalty)
	end
	local nRewardPointsEarned = self.nCurRewardPointsEarned
	if nRewardPointsEarned == nil then
		nRewardPointsEarned = rtCurrent:GetRewardPointsEarned()
	end
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndLoyaltyPointProgress:GetOriginalLocation():GetOffsets()
	self.tWndRefs.wndLoyaltyPointProgress:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	self.tWndRefs.wndLoyaltyPointProgress:SetText("0")
	self.tWndRefs.wndLoyaltyPointProgress:SetData({ nActualPoints = nRewardPointsEarned, nAdjustedPoints = nRewardPointsEarned })
	self.tWndRefs.wndLoyaltyProgressBar:SetProgress(0)
end

function Loyalty:UpdateLoyaltyPointProgress(nTimeMS)
	local nProgress = self.tWndRefs.wndLoyaltyProgressBar:GetProgress()
	self.tWndRefs.wndLoyaltyPointProgress:SetText(Apollo.FormatNumber(nProgress, 0, true))
	
	local tLoyaltyPtsEarned = self.tWndRefs.wndLoyaltyPointProgress:GetData()
	
	local tLoyaltyItemContainers = self.tRewardStyles.tRewards
	
	local bHasProgress = self.tWndRefs.wndLoyaltyProgressBar:IsShown()
	for nRewardCost, tLoyaltyExpandedItem in pairs(tLoyaltyItemContainers) do
		local bCurComplete = nProgress >= nRewardCost
		local bLastRewards = tLoyaltyExpandedItem.bLast

		if bCurComplete and bLastRewards then
			self.tWndRefs.wndLoyaltyPointProgress:SetText(Apollo.FormatNumber(tLoyaltyPtsEarned.nActualPoints, 0, true))
		end
		
		local wndLoyaltyExpandedItemBackground = tLoyaltyExpandedItem.wndBackground
		local bAlreadyCompleted = tLoyaltyExpandedItem.bAlreadyCompleted
		if bCurComplete and bHasProgress and not bAlreadyCompleted then -- Should update the background, icons, and text
			Sound.Play(tLoyaltyExpandedItem.eSound)
			if bLastRewards then -- Is on the final reward column
				tLoyaltyExpandedItem.wndIndicator:SetSprite(self.tRewardStyles.tFinalRewardComplete.strIndicatorSprite)
				wndLoyaltyExpandedItemBackground:SetSprite(self.tRewardStyles.tFinalRewardComplete.strBackgroundSprite)
			else
				tLoyaltyExpandedItem.wndIndicator:SetSprite(self.tRewardStyles.tComplete.strIndicatorSprite)
				tLoyaltyExpandedItem.wndBurst:SetSprite(self.tRewardStyles.tComplete.strBurstSprite)
				wndLoyaltyExpandedItemBackground:SetSprite(self.tRewardStyles.tComplete.strBackgroundSprite)
			end
			tLoyaltyExpandedItem.wndLoyaltyPoints:SetTextColor(self.tRewardStyles.tComplete.strTextColor)
			wndLoyaltyExpandedItemBackground:SetBGColor(self.tRewardStyles.tComplete.strBackgroundColor)
			
			for nIdx, tLoyaltyExpandedIcons in ipairs(tLoyaltyExpandedItem.arChildren) do
				local wndLoyaltyExpandedIconsBG = tLoyaltyExpandedIcons.wndBackground
				local wndLoyaltyExpandedIconsItemIcon = tLoyaltyExpandedIcons.wndIcon
				
				local strSprite = self.tRewardStyles.tComplete.strIconSprite
				if bLastRewards then
					strSprite = self.tRewardStyles.tFinalRewardComplete.strIconSprite
				end
				wndLoyaltyExpandedIconsBG:SetSprite(strSprite)
				wndLoyaltyExpandedIconsItemIcon:SetBGColor(self.tRewardStyles.tComplete.strBackgroundColor)
				wndLoyaltyExpandedIconsBG:SetBGColor(self.tRewardStyles.tComplete.strBackgroundColor)
			end
			tLoyaltyExpandedItem.bAlreadyCompleted = true
			
		elseif not bCurComplete and (bAlreadyCompleted or bLastRewards) then
			if bLastRewards then -- Is on the final reward column
				tLoyaltyExpandedItem.wndIndicator:SetSprite(self.tRewardStyles.tFinalRewardDefault.strIndicatorSprite)
				wndLoyaltyExpandedItemBackground:SetSprite(self.tRewardStyles.tFinalRewardDefault.strBackgroundSprite)
				tLoyaltyExpandedItem.wndMilestoneRunner:Show(true)
				
				tLoyaltyExpandedItem.wndLoyaltyPoints:SetTextColor(self.tRewardStyles.tFinalRewardDefault.strTextColor)
				wndLoyaltyExpandedItemBackground:SetBGColor(self.tRewardStyles.tFinalRewardDefault.strBackgroundColor)
			else
				tLoyaltyExpandedItem.wndIndicator:SetSprite(self.tRewardStyles.tDefault.strIndicatorSprite)
				wndLoyaltyExpandedItemBackground:SetSprite(self.tRewardStyles.tDefault.strBackgroundSprite)
				
				tLoyaltyExpandedItem.wndLoyaltyPoints:SetTextColor(self.tRewardStyles.tDefault.strTextColor)
				wndLoyaltyExpandedItemBackground:SetBGColor(self.tRewardStyles.tDefault.strBackgroundColor)
			end
			
			for nIdx, tLoyaltyExpandedIcons in ipairs(tLoyaltyExpandedItem.arChildren) do
				local wndLoyaltyExpandedIconsBG = tLoyaltyExpandedIcons.wndBackground
				local wndLoyaltyExpandedIconsItemIcon = tLoyaltyExpandedIcons.wndIcon
				
				wndLoyaltyExpandedIconsBG:SetSprite(self.tRewardStyles.tDefault.strIconSprite)
				wndLoyaltyExpandedIconsItemIcon:SetBGColor(self.tRewardStyles.tDefault.strBackgroundColor)
				wndLoyaltyExpandedIconsBG:SetBGColor(self.tRewardStyles.tDefault.strBackgroundColor)
			end
			tLoyaltyExpandedItem.bAlreadyCompleted = false
		end
	end
	
	if nProgress == tLoyaltyPtsEarned.nAdjustedPoints then
		self.timerLoyaltyPointProgressUpdate:Stop()
	end
end

function Loyalty:UpdateLoyaltyPointHeaderProgress(nTimeMS)
	local nProgress = self.wndLoyaltyProgress:GetProgress()
	
	for nCost, tMilestone in pairs(self.tMilestones) do
		if nProgress >= nCost and not tMilestone.bAlreadyCompleted then
			if tMilestone.wndIcon ~= nil then
				tMilestone.wndIcon:SetSprite("MTX:UI_BK3_MTX_LoyaltyBarMilestoneCompleted")
			end
			if nProgress >= self.nCurRewardPointsEarned then
				if tMilestone.wndAnimation ~= nil then
					tMilestone.wndAnimation:SetSprite("LoginIncentives:sprLoginIncentives_Burst")
					tMilestone.wndAnimation2:SetSprite("CRB_Anim_WindowBirth:Burst_Open")
				end
				Sound.Play(tMilestone.eSound)
			end
			tMilestone.bAlreadyCompleted = true
		elseif nProgress < nCost and tMilestone.bAlreadyCompleted then
			if tMilestone.wndIcon ~= nil then
				tMilestone.wndIcon:SetSprite("MTX:UI_BK3_MTX_LoyaltyBarMilestone")
			end
			tMilestone.bAlreadyCompleted = false
		end
	end
	
	if nProgress == self.nCurRewardPointsEarned then
		self.timerLoyaltyPointHeaderProgressUpdate:Stop()
	end
end

function Loyalty:OnToggleLoyalty(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	if self.tWndRefs.wndMain:IsShown() then
		Event_FireGenericEvent("ShowDialog", nil, nil)
	else
		Event_FireGenericEvent("ShowDialog", "Loyalty", self.tWndRefs.wndModelDialog)
	end
end


local LoyaltyInst = Loyalty:new()
LoyaltyInst:Init()
