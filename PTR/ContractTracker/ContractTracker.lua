-----------------------------------------------------------------------------------------------
-- Client Lua Script for QuestTracker
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "ContractsLib"
require "Contract"
require "Quest"

local ContractTracker = {}

local kstrContractAddon = "002ContractAddon"

local ktConToColor =
{
	[0] 												= "ffffffff",
	[Unit.CodeEnumLevelDifferentialAttribute.Grey] 		= "ff9aaea3",
	[Unit.CodeEnumLevelDifferentialAttribute.Green] 	= "ff37ff00",
	[Unit.CodeEnumLevelDifferentialAttribute.Cyan] 		= "ff46ffff",
	[Unit.CodeEnumLevelDifferentialAttribute.Blue] 		= "ff309afc",
	[Unit.CodeEnumLevelDifferentialAttribute.White] 	= "ffffffff",
	[Unit.CodeEnumLevelDifferentialAttribute.Yellow] 	= "ffffd400", -- Yellow
	[Unit.CodeEnumLevelDifferentialAttribute.Orange] 	= "ffff6a00", -- Orange
	[Unit.CodeEnumLevelDifferentialAttribute.Red] 		= "ffff0000", -- Red
	[Unit.CodeEnumLevelDifferentialAttribute.Magenta] 	= "fffb00ff", -- Purp
}

local ktContractTypeArt =
{
	[0]		= { strActive = "Contracts:sprContracts_Type01",		strAvailable = "Contracts:sprContracts_Type01",		strOverview = Apollo.GetString("CombatLogOptions_General"), },
	[122]	= { strActive = "Contracts:sprContracts_Type01",		strAvailable = "Contracts:sprContracts_Type01",		strOverview = Apollo.GetString("CombatLogOptions_General"), },
	[123]	= { strActive = "Contracts:sprContracts_Type02",		strAvailable = "Contracts:sprContracts_Type02",		strOverview = Apollo.GetString("CRB_Kill"), },
	[124]	= { strActive = "Contracts:sprContracts_Type03",		strAvailable = "Contracts:sprContracts_Type03",		strOverview = Apollo.GetString("CRB_Collection"), },
	[125]	= { strActive = "Contracts:sprContracts_Type04",		strAvailable = "Contracts:sprContracts_Type04",		strOverview = Apollo.GetString("CRB_Completion"), },
}


local kstrRed 		= "ffff4c4c"
local kstrGreen 	= "ff2fdc02"
local kstrYellow 	= "fffffc00"
local kstrLightGrey = "ffb4b4b4"
local kstrHighlight = "ffffe153"

function ContractTracker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	
	-- Window Management
	o.tQuestWndCache = {}
	o.tObjectiveWndCache = {}

	-- Data
	o.tTimedQuests = {}
	o.tTimedObjectives = {}
	o.nTrackerCounting = -1 -- Start at -1 so that loading up with 0 quests will still trigger a resize
	o.nFlashThisQuest = nil
	o.tActiveProgBarQuests = {}
	o.bSetup = false
	
	-- Saved data
	o.bShowbShowContracts = true
	o.tMinimized =
	{
		bRoot = false,
		tQuests = {},
	}

    return o
end

function ContractTracker:Init()
    Apollo.RegisterAddon(self)
end

function ContractTracker:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ContractTracker.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	self.timerResizeDelay = ApolloTimer.Create(0.1, false, "OnResizeDelayTimer", self)
	self.timerResizeDelay:Stop()
	
	self.timerRealTimeUpdate = ApolloTimer.Create(1.0, true, "OnRealTimeUpdateTimer", self)
	self.timerRealTimeUpdate:Stop()
	
	self.timerArrowBlinker = ApolloTimer.Create(4.0, true, "OnArrowBlinkerTimer", self)
	self.timerArrowBlinker:Stop()
end

function ContractTracker:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	return
	{
		tMinimized = self.tMinimized,
		bShowContracts = self.bShowContracts,
	}
end

function ContractTracker:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	if tSavedData.tMinimized ~= nil then
		self.tMinimized = tSavedData.tMinimized
	end
	
	if tSavedData.bShowContracts ~= nil then
		self.bShowContracts = tSavedData.bShowContracts
	end
end

function ContractTracker:OnDocumentReady()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
		Apollo.AddAddonErrorText(self, "Could not load the main window document for some reason.")
		return
	end
	
	self:InitializeWindowMeasuring()
	
	Apollo.RegisterEventHandler("ObjectiveTrackerLoaded", "OnObjectiveTrackerLoaded", self)
	Event_FireGenericEvent("ObjectiveTracker_RequestParent")
end

function ContractTracker:InitializeWindowMeasuring()
	local wndMeasure = Apollo.LoadForm(self.xmlDoc, "ContractItem", nil, self)
	self.knMinHeighQuestItem = wndMeasure:GetHeight()
	self.knInitialQuestControlBackerHeight = wndMeasure:FindChild("ControlBackerBtn"):GetHeight()
	wndMeasure:Destroy()

	wndMeasure = Apollo.LoadForm(self.xmlDoc, "QuestObjectiveItem", nil, self)
	self.knInitialQuestObjectiveHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()

	wndMeasure = Apollo.LoadForm(self.xmlDoc, "SpellItem", nil, self)
	self.knInitialSpellItemHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()
end

function ContractTracker:OnObjectiveTrackerLoaded(wndForm)
	if not wndForm or not wndForm:IsValid() then
		return
	end
	
	Apollo.RemoveEventHandler("ObjectiveTrackerLoaded", self)
	
	Apollo.RegisterEventHandler("QuestInit", "OnQuestInit", self)
	Apollo.RegisterEventHandler("PlayerLevelChange", "OnPlayerLevelChange", self)
	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "ContentGroupItem", wndForm, self)
	self.wndQuestContainerContent = self.wndMain:FindChild("EpisodeGroupContainer")
	
	self:Setup()
end

function ContractTracker:Setup()

	if GameLib.GetPlayerUnit() == nil or GameLib.GetPlayerLevel(true) < 50 then
		self.wndMain:Show(false)
		return
	end
	
	if self.bSetup then
		return
	end
	Apollo.RegisterEventHandler("ToggleShowContracts", "OnToggleShowContracts", self)
	
	Apollo.RegisterEventHandler("ContractStateChanged", "OnContractStateChanged", self)
	Apollo.RegisterEventHandler("ContractObjectiveUpdated", "OnContractObjectiveUpdated", self)
	
	local tContractData =
	{
		["strAddon"] = Apollo.GetString("CRB_Contracts"),
		["strEventMouseLeft"] = "ToggleShowContracts", 
		["strEventMouseRight"] = "", 
		["strIcon"] = "spr_ObjectiveTracker_IconContract",
		["strDefaultSort"] = kstrContractAddon,
	}
	Event_FireGenericEvent("ObjectiveTracker_NewAddOn", tContractData)
	
	self:BuildAll()
	self:ResizeAll()
	
	self.bSetup = true
end

function ContractTracker:OnToggleShowContracts()
	self.bShowContracts = not self.bShowContracts
	
	self:ResizeAll()
end

---------------------------------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------------------------------

function ContractTracker:OnRealTimeUpdateTimer(nTime)
	for index, tQuestInfo in pairs(self.tTimedQuests) do
		if tQuestInfo.wndTitleFrame ~= nil then
			local strTitle = self:HelperBuildTimedQuestTitle(tQuestInfo.queQuest)
			tQuestInfo.wndTitleFrame:SetAML(strTitle)
		else
			self.tTimedQuests[index] = nil
		end
	end

	for index, tObjectiveInfo in pairs(self.tTimedObjectives) do
		local wndCurrObjective = tObjectiveInfo.wndObjective
		if wndCurrObjective ~= nil and wndCurrObjective:FindChild("QuestObjectiveBtn") ~= nil then
			wndCurrObjective:FindChild("QuestObjectiveBtn"):SetTooltip(self:BuildObjectiveTitleString(tObjectiveInfo.queQuest, tObjectiveInfo.tObjective, true))
			wndCurrObjective:FindChild("QuestObjectiveText"):SetAML(self:BuildObjectiveTitleString(tObjectiveInfo.queQuest, tObjectiveInfo.tObjective))
		else
			self.tTimedObjectives[index] = nil
		end
	end
	
	if (next(self.tTimedQuests) == nil and next(self.tTimedObjectives) == nil)
		or (not self.bShowContracts) then
		self.timerRealTimeUpdate:Stop()
	end
end

function ContractTracker:OnResizeDelayTimer(nTime)
	self:ResizeAll()
end

function ContractTracker:BuildAll()
	for eContractType, arContracts in pairs(ContractsLib.GetActiveContracts()) do
		for idx, contract in pairs(arContracts) do
			self:DrawContract(contract)
		end
	end
end

function ContractTracker:ResizeAll()
	self.timerResizeDelay:Stop()

	local nStartingHeight = self.wndMain:GetHeight()
	local bStartingShown = self.wndMain:IsShown()
	
	local nCount = 0
	for eContractType, arContracts in pairs(ContractsLib.GetActiveContracts()) do
		for idx, contract in pairs(arContracts) do
			self:DrawContract(contract)
			local tQuest = self.tQuestWndCache[contract:GetQuest():GetId()]
			if tQuest ~= nil and tQuest.wndQuest ~= nil and tQuest.wndQuest:IsValid() then
				local tData = tQuest.wndQuest:GetData()
				tData.nSort = nCount
			end
			nCount = nCount + 1
		end
	end

	if self.bShowContracts then
		if self.tMinimized.bRoot then
			self.wndQuestContainerContent:Show(false)
			
			local nLeft, nTop, nRight, nBottom = self.wndMain:GetOriginalLocation():GetOffsets()
			self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
		else
			-- Resize quests
			for idx, wndContract in pairs(self.wndQuestContainerContent:GetChildren()) do
				self:ResizeContract(wndContract)
			end
			
			local nChildHeight = self.wndQuestContainerContent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
				return wndLeft:GetData().nSort < wndRight:GetData().nSort
			end)
			
			local nHeightChange = nChildHeight - self.wndQuestContainerContent:GetHeight()
			self.wndQuestContainerContent:Show(true)
			
			local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
			self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeightChange)
		end
	end
	local bShow = self.bShowContracts and nCount > 0
	self.wndMain:Show(bShow)
	
	if nStartingHeight ~= self.wndMain:GetHeight() or self.nTrackerCounting ~= nQuestCounting or bShow ~= bStartingShown then
		local tData =
		{
			["strAddon"] = Apollo.GetString("CRB_Contracts"),
			["strText"] = nCount,
			["bChecked"] = self.bShowContracts,
		}
		Event_FireGenericEvent("ObjectiveTracker_UpdateAddOn", tData)
	end
	
	self.nTrackerCounting = nCount
end

function ContractTracker:DestroyContract(contract)
	local queContract = contract:GetQuest()

	local tQuest = self.tQuestWndCache[queContract:GetId()]
	local wndContract = nil
	if tQuest ~= nil then
		wndContract = tQuest.wndQuest
	end
	
	if wndContract ~= nil and wndContract:IsValid() then
		wndContract:Destroy()
	end
	
	self.tQuestWndCache[queContract:GetId()] = nil
	
	for index, tObjective in pairs(self.tObjectiveWndCache) do
		if tObjective.queQuest == queContract then
			if tObjective.wndObjective ~= nil and tObjective.wndObjective:IsValid() then
				tObjective.wndObjective:Destroy()
			end
			if tObjective.wndObjectiveProg ~= nil and tObjective.wndObjectiveProg:IsValid() then
				tObjective.wndObjectiveProg:Destroy()
			end
			if tObjective.wndSpellBtn ~= nil and tObjective.wndSpellBtn:IsValid() then
				tObjective.wndSpellBtn:Destroy()
			end
			
			self.tObjectiveWndCache[index] = nil
		end
	end
end

function ContractTracker:DrawContract(contract)
	local queQuest = contract:GetQuest()

	local tQuest = self.tQuestWndCache[queQuest:GetId()]
	local wndQuest = nil
	if tQuest ~= nil then
		wndQuest = tQuest.wndQuest
	end
	if wndQuest == nil or not wndQuest:IsValid() then
		wndQuest = Apollo.LoadForm(self.xmlDoc, "ContractItem", self.wndQuestContainerContent, self)
		wndQuest:SetData({ queQuest = queQuest, nSort = 99 })
		self.tQuestWndCache[queQuest:GetId()] = { wndQuest = wndQuest, queQuest = queQuest, epiEpisode = epiEpisode, contract = contract }
	end

	self:HelperSelectInteractHintArrowObject(queQuest, wndQuest:FindChild("ControlBackerBtn"))
	-- Quest Title
	local strTitle = queQuest:GetTitle()
	local eQuestState = queQuest:GetState()
	if eQuestState == Quest.QuestState_Botched then
		strTitle = string.format("<T Font=\"CRB_InterfaceMedium_B\" TextColor=\"%s\">%s</T>", kstrRed, String_GetWeaselString(Apollo.GetString("QuestTracker_Failed"), strTitle))
	elseif eQuestState == Quest.QuestState_Achieved then
		strTitle = string.format("<T Font=\"CRB_InterfaceMedium_B\" TextColor=\"%s\">%s</T>", kstrGreen,String_GetWeaselString(Apollo.GetString("QuestTracker_Complete"), strTitle))
	elseif (eQuestState == Quest.QuestState_Accepted or eQuestState == Quest.QuestState_Achieved) and queQuest:IsQuestTimed() then
		strTitle = self:HelperBuildTimedQuestTitle(queQuest)
		self.tTimedQuests[queQuest:GetId()] = { queQuest = queQuest, wndTitleFrame = wndQuest:FindChild("TitleText") }
		self.timerRealTimeUpdate:Start()
	else
		local strColor = self.tActiveProgBarQuests[queQuest:GetId()] and "ffffffff" or kstrLightGrey
		local crLevelConDiff = ktConToColor[queQuest:GetColoredDifficulty() or 0]
		strTitle = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s </T><T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">(%s)</T>", strColor, strTitle, crLevelConDiff, queQuest:GetConLevel())
	end

	wndQuest:FindChild("TitleText"):SetAML(strTitle)
	wndQuest:FindChild("TitleText"):SetHeightToContentHeight()
	wndQuest:FindChild("ContractIcon"):SetSprite(ktContractTypeArt[queQuest:GetSubType()].strAvailable)

	wndQuest:FindChild("ControlBackerBtn"):SetData(wndQuest)
	wndQuest:FindChild("ControlBackerBtn"):Enable(false)

	-- Flash if we are told to
	if self.nFlashThisQuest == queQuest then
		self.nFlashThisQuest = nil
		wndQuest:SetSprite("sprWinAnim_BirthSmallTemp")
	end

	local bMinimized = self.tMinimized.tQuests[queQuest:GetId()]
	local wndObjectiveContainer = wndQuest:FindChild("ObjectiveContainer")

	-- Conditional drawing
	wndObjectiveContainer:Show(not bMinimized)
	
	-- State depending drawing
	if eQuestState == Quest.QuestState_Achieved then
		for idx, tObjective in pairs(queQuest:GetVisibleObjectiveData()) do
			if tObjective.nCompleted >= tObjective.nNeeded then
				self:DestroyObjective(queQuest, tObjective.nIndex)
			end
		end
		self:DrawQuestSpell(queQuest, wndQuest)

		local wndObjective = wndObjectiveContainer:FindChild("ObjectiveCompleted")
		if wndObjective == nil or not wndObjective:IsValid() then
			wndObjective = Apollo.LoadForm(self.xmlDoc, "QuestObjectiveItem", wndQuest:FindChild("ObjectiveContainer"), self)
			wndObjective:SetName("ObjectiveCompleted")
		end
		
		wndObjective:FindChild("QuestObjectiveBtn"):SetTooltip(self:BuildObjectiveTitleString(queQuest, tObjective, true))
		wndObjective:FindChild("QuestObjectiveBtn"):SetData({["queOwner"] = queQuest, ["nObjectiveIdx"] = nil})
		wndObjective:FindChild("QuestObjectiveText"):SetAML(self:BuildObjectiveTitleString(queQuest))

	else
		self:DrawQuestSpell(queQuest, wndQuest)
		
		for idx, tObjective in pairs(queQuest:GetVisibleObjectiveData()) do
			if tObjective.nCompleted < tObjective.nNeeded then
				self:DrawObjective(queQuest, tObjective.nIndex)
			else
				self:DestroyObjective(queQuest, tObjective.nIndex)
			end
		end
	end
end

function ContractTracker:ResizeContract(wndQuest)
	local queQuest = wndQuest:GetData().queQuest

	local nQuestTextWidth, nQuestTextHeight = wndQuest:FindChild("TitleText"):SetHeightToContentHeight()
	local nResult = math.max(self.knInitialQuestControlBackerHeight, nQuestTextHeight + 4) -- for lower g height

	local wndControlBackerBtn = wndQuest:FindChild("ControlBackerBtn")
	if wndControlBackerBtn then
		local nLeft, nTop, nRight, nBottom = wndControlBackerBtn:GetAnchorOffsets()
		wndControlBackerBtn:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nResult)
	end

	-- If expanded and valid, make it bigger
	local nHeaderHeight = nResult
	local wndObjectiveContainer = wndQuest:FindChild("ObjectiveContainer")
	if wndObjectiveContainer then
		
		local bMinimized = self.tMinimized.tQuests[queQuest:GetId()]
		
		if not bMinimized then
			for idx, wndObj in pairs(wndObjectiveContainer:GetChildren()) do
				self:ResizeObjective(wndObj)
			end
			
			local nChildrenHeight = wndObjectiveContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
			local nLeft, nTop, nRight, nBottom = wndObjectiveContainer:GetAnchorOffsets()
			wndObjectiveContainer:SetAnchorOffsets(nLeft, nHeaderHeight, nRight, nHeaderHeight + nChildrenHeight)
			nResult = nHeaderHeight + nChildrenHeight
		end
		
		wndObjectiveContainer:Show(not bMinimized)
	end

	local nLeft, nTop, nRight, nBottom = wndQuest:GetAnchorOffsets()
	nResult = math.max(nResult, self.knMinHeighQuestItem)
	wndQuest:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nResult)
end

function ContractTracker:DrawQuestSpell(queQuest, wndQuest)
	if queQuest:GetSpell() then
		local wndSpellItem = wndQuest:FindChild("ObjectiveContainer"):FindChild("SpellItem")
		if wndSpellItem == nil or not wndSpellItem:IsValid() then
			wndSpellItem = Apollo.LoadForm(self.xmlDoc, "SpellItem", wndQuest:FindChild("ObjectiveContainer"), self)
		end
		
		wndSpellItem:FindChild("SpellItemBtn"):Show(true)
		wndSpellItem:FindChild("SpellItemBtn"):SetContentId(queQuest)
		wndSpellItem:FindChild("SpellItemText"):SetText(String_GetWeaselString(Apollo.GetString("QuestTracker_UseQuestAbility"), GameLib.GetKeyBinding("CastObjectiveAbility")))
	end
end

function ContractTracker:DestroyObjective(queQuest, nIndex)
	local strWindowCacheKey = tostring(queQuest:GetId()).."O"..nIndex
	local tObjective = self.tObjectiveWndCache[strWindowCacheKey]
	if tObjective ~= nil then
		local wndObjective = tObjective.wndObjective
		if wndObjective ~= nil and wndObjective:IsValid() then
			wndObjective:Destroy()
		end
	end
	self.tObjectiveWndCache[strWindowCacheKey] = nil
	
	local strProgressWindowCacheKey = strWindowCacheKey.."QuestProgressItem"
	local tObjectiveProg = self.tObjectiveWndCache[strProgressWindowCacheKey]
	if tObjectiveProg ~= nil then
		local wndObjectiveProg = tObjectiveProg.wndObjectiveProg
		if wndObjectiveProg ~= nil and wndObjectiveProg:IsValid() then
			wndObjectiveProg:Destroy()
		end
	end
	self.tObjectiveWndCache[strProgressWindowCacheKey] = nil
	
	local strSpellWindowCacheKey = strWindowCacheKey.."SpellItemObjectiveBtn"
	local tSpellBtn = self.tObjectiveWndCache[strSpellWindowCacheKey]
	if tSpellBtn ~= nil then
		local wndSpellBtn = tSpellBtn.wndSpellBtn
		if wndSpellBtn ~= nil and wndSpellBtn:IsValid() then
			wndSpellBtn:Destroy()
		end
	end
	self.tObjectiveWndCache[strSpellWindowCacheKey] = nil
end

function ContractTracker:DrawObjective(queQuest, nIndex)
	local strWindowCacheKey = tostring(queQuest:GetId()).."O"..nIndex
	local tWndObjective = self.tObjectiveWndCache[strWindowCacheKey]
	local wndQuest = nil
	local wndObjective = nil
	if tWndObjective ~= nil then
		wndObjective = tWndObjective.wndObjective
	end
	local tQuest = self.tQuestWndCache[queQuest:GetId()]
	if tQuest ~= nil then
		wndQuest = tQuest.wndQuest
	end
	if wndQuest == nil or not wndQuest:IsValid() then
		return
	end
	if wndObjective == nil or not wndObjective:IsValid() then
		wndObjective = Apollo.LoadForm(self.xmlDoc, "QuestObjectiveItem", wndQuest:FindChild("ObjectiveContainer"), self)
		self.tObjectiveWndCache[strWindowCacheKey] = { wndObjective = wndObjective, nIndex = nIndex, queQuest = queQuest, epiEpisode = epiEpisode }
	end
	
	local tObjective = nil
	for idx, tObjectiveToFind in pairs(queQuest:GetVisibleObjectiveData()) do
		if tObjectiveToFind.nIndex == nIndex then
			tObjective = tObjectiveToFind
			break
		end
	end
	
	if queQuest:IsObjectiveTimed(tObjective.nIndex) then
		self.tTimedObjectives[strWindowCacheKey] = { queQuest = queQuest, tObjective = tObjective, wndObjective = wndObjective }
		self.timerRealTimeUpdate:Start()
	end
	
	local wndQuestObjectiveBtn = wndObjective:FindChild("QuestObjectiveBtn")
	wndQuestObjectiveBtn:SetData({["queOwner"] = queQuest, ["nObjectiveIdx"] = tObjective.nIndex})
	wndQuestObjectiveBtn:SetTooltip(self:BuildObjectiveTitleString(queQuest, tObjective, true))
	wndObjective:FindChild("QuestObjectiveText"):SetAML(self:BuildObjectiveTitleString(queQuest, tObjective))

	-- Progress
	local strProgressWindowCacheKey = strWindowCacheKey.."QuestProgressItem"
	local tObjectiveProg = self.tObjectiveWndCache[strProgressWindowCacheKey]
	if self.tActiveProgBarQuests[queQuest:GetId()] and queQuest:DisplayObjectiveProgressBar(tObjective.nIndex) then
		local wndObjectiveProg = nil
		if tObjectiveProg ~= nil then
			wndObjectiveProg = tObjectiveProg.wndObjectiveProg
		end
		if wndObjectiveProg ~= nil and wndObjectiveProg:IsValid() then
			wndObjectiveProg = Apollo.LoadForm(self.xmlDoc, "QuestProgressItem", wndQuest:FindChild("ObjectiveContainer"), self)
			self.tObjectiveWndCache[strProgressWindowCacheKey] = { wndObjectiveProg = wndObjectiveProg, nIndex = nIndex, queQuest = queQuest, epiEpisode = epiEpisode }
		end
		
		local nCompleted = tObjective.nCompleted
		local nNeeded = tObjective.nNeeded

		local wndQuestProgressBar = wndObjectiveProg:FindChild("QuestProgressBar")
		wndQuestProgressBar:SetMax(nNeeded)
		wndQuestProgressBar:SetProgress(nCompleted)
		wndQuestProgressBar:EnableGlow(nCompleted > 0 and nCompleted ~= nNeeded)
	elseif tObjectiveProg ~= nil then
		local wndObjectiveProg = tObjectiveProg.wndObjectiveProg
		if wndObjectiveProg ~= nil and wndObjectiveProg:IsValid() then
			wndObjectiveProg:Destroy()
		end
		self.tObjectiveWndCache[strProgressWindowCacheKey] = nil
	end

	-- Objective Spell Item
	if queQuest:GetSpell(tObjective.nIndex) then
		local strSpellWindowCacheKey = strWindowCacheKey.."SpellItemObjectiveBtn"
		local tSpellBtn = self.tObjectiveWndCache[strSpellWindowCacheKey]
		local wndSpellBtn = nil
		if tSpellBtn ~= nil then
			wndSpellBtn = tSpellBtn.wndSpellBtn
		end
		if wndSpellBtn == nil or not wndSpellBtn:IsValid() then
			wndSpellBtn = Apollo.LoadForm(self.xmlDoc, "SpellItemObjectiveBtn", wndQuest:FindChild("ObjectiveContainer"), self)
			self.tObjectiveWndCache[strSpellWindowCacheKey] = { wndSpellBtn = wndSpellBtn, nIndex = nIndex, queQuest = queQuest, epiEpisode = epiEpisode }
		end
		
		wndSpellBtn:SetContentId(queQuest, tObjective.nIndex)
		wndSpellBtn:SetText(String_GetWeaselString(GameLib.GetKeyBinding("CastObjectiveAbility")))
	end
end

function ContractTracker:ResizeObjective(wndObj)
	local nObjTextHeight = self.knInitialQuestObjectiveHeight

	-- If there's the spell icon is bigger, use that instead
	if wndObj:FindChild("SpellItemObjectiveBtn") or wndObj:GetName() == "SpellItem" then
		nObjTextHeight = math.max(nObjTextHeight, self.knInitialSpellItemHeight)
	end

	-- If the text is bigger, use that instead
	local wndQuestObjectiveText = wndObj:FindChild("QuestObjectiveText")
	if wndQuestObjectiveText then
		local nLocalWidth, nLocalHeight = wndQuestObjectiveText:SetHeightToContentHeight()
		nObjTextHeight = math.max(nObjTextHeight, nLocalHeight + 8) -- for lower g height

		-- Fake V-Align to match the button if it's just one line of text
		if wndObj:FindChild("SpellItemObjectiveBtn") and nLocalHeight < 20 then
			local nLeft, nTop, nRight, nBottom = wndQuestObjectiveText:GetAnchorOffsets()
			wndQuestObjectiveText:SetAnchorOffsets(nLeft, 9, nRight, nBottom)
		end
	end

	-- Also add extra height for Progress Bars
	if wndObj:FindChild("QuestProgressItem") then
		nObjTextHeight = nObjTextHeight + wndObj:FindChild("QuestProgressItem"):GetHeight()
	end

	local nLeft, nTop, nRight, nBottom = wndObj:GetAnchorOffsets()
	wndObj:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nObjTextHeight)
end

function ContractTracker:BuildObjectiveTitleString(queQuest, tObjective, bIsTooltip)
	local strResult = ""

	-- Early exit for completed
	if queQuest:GetState() == Quest.QuestState_Achieved then
		strResult = queQuest:GetCompletionObjectiveShortText()
		if bIsTooltip or self.bShowLongQuestText or not strResult or string.len(strResult) <= 0 then
			strResult = queQuest:GetCompletionObjectiveText()
		end
		return string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", strResult)
	end

	-- Use short form or reward text if possible
	local strShortText = queQuest:GetObjectiveShortDescription(tObjective.nIndex)
	if self.bShowLongQuestText or bIsTooltip then
		strResult = string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", tObjective.strDescription)
	elseif strShortText and string.len(strShortText) > 0 then
		strResult = string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", strShortText)
	end
	
	-- Prefix Optional or Progress if it hasn't been finished yet
	if tObjective.nCompleted < tObjective.nNeeded then
		local strPrefix = ""
		if tObjective and not tObjective.bIsRequired then
			strPrefix = string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", Apollo.GetString("QuestLog_Optional"))
			strResult = String_GetWeaselString(Apollo.GetString("QuestTracker_BuildText"), strPrefix, strResult)
		end

		-- Use Percent if Progress Bar
		if tObjective.nNeeded > 1 and queQuest:DisplayObjectiveProgressBar(tObjective.nIndex) then
			local strColor = self.tActiveProgBarQuests[queQuest:GetId()] and kstrHighlight or "ffffffff"
			local strPercentComplete = String_GetWeaselString(Apollo.GetString("QuestTracker_PercentComplete"), tObjective.nCompleted)
			strPrefix = string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strColor, strPercentComplete)
			strResult = String_GetWeaselString(Apollo.GetString("QuestTracker_BuildText"), strPrefix, strResult)
		elseif tObjective.nNeeded > 1 then
			strPrefix = string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", String_GetWeaselString(Apollo.GetString("QuestTracker_ValueComplete"), Apollo.FormatNumber(tObjective.nCompleted, 0, true), Apollo.FormatNumber(tObjective.nNeeded, 0, true)))
			strResult = String_GetWeaselString(Apollo.GetString("QuestTracker_BuildText"), strPrefix, strResult)
		end
	end

	-- Prefix time for timed objectives
	if queQuest:IsObjectiveTimed(tObjective.nIndex) then
		strResult = self:HelperPrefixTimeString(math.max(0, math.floor(queQuest:GetObjectiveTimeRemaining(tObjective.nIndex) / 1000)), strResult)
	end
	
	return strResult
end

---------------------------------------------------------------------------------------------------
-- Game Events
---------------------------------------------------------------------------------------------------

function ContractTracker:OnQuestInit()
	self:Setup()

	if self.bSetup then
		self:BuildAll()
		self.timerResizeDelay:Start()
	end
end

function ContractTracker:OnContractStateChanged(contract, eState)
	local queQuest = contract:GetQuest()
	if eState == Quest.QuestState_Accepted
		or eState == Quest.QuestState_Achieved then
		
		if eState == Quest.QuestState_Accepted then
			--Add new quests to saved hint arrow.
			GameLib.SetInteractHintArrowObject(queQuest)
		end
	
		self:DrawContract(contract)
	else
		self:DestroyContract(contract)
		
		--Remove completed quests from saved hint arrow.
		local oInteractObject = GameLib.GetInteractHintArrowObject()
		if not oInteractObject or (oInteractObject and oInteractObject.eHintArrowType == GameLib.CodeEnumHintType.Quest and oInteractObject.objTarget:GetId() == queQuest:GetId()) then
			GameLib.SetInteractHintArrowObject(nil)
		end
	end
	
	self.timerResizeDelay:Start()
end

function ContractTracker:OnContractObjectiveUpdated(contract, nIndex)
	local queQuest = contract:GetQuest()
	local eState = queQuest:GetState()
	if eState == Quest.QuestState_Accepted
		or eState == Quest.QuestState_Achieved then
		self:DrawContract(contract)
	else
		self:DestroyContract(contract)
	end
	
	self.timerResizeDelay:Start()
end

function ContractTracker:OnPlayerLevelChange()
	self:Setup()
end

function ContractTracker:OnCharacterCreated()
	self:Setup()
end

---------------------------------------------------------------------------------------------------
-- Controls Events
---------------------------------------------------------------------------------------------------

function ContractTracker:OnEpisodeGroupControlBackerMouseEnter(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:FindChild("EpisodeGroupMinimizeBtn"):Show(true)
	end
end

function ContractTracker:OnEpisodeGroupControlBackerMouseExit(wndHandler, wndControl)
	if wndHandler == wndControl then
		local wndBtn = wndHandler:FindChild("EpisodeGroupMinimizeBtn")
		wndBtn:Show(wndBtn:IsChecked())
	end
end

function ContractTracker:OnContentGroupMinimizedBtnChecked(wndHandler, wndControl, eMouseButton)
	self.tMinimized.bRoot = true
	self:ResizeAll()
end

function ContractTracker:OnContentGroupMinimizedBtnUnChecked(wndHandler, wndControl, eMouseButton)
	self.tMinimized.bRoot = false
	self:ResizeAll()
end

function ContractTracker:OnQuestHintArrow(wndHandler, wndControl, eMouseButton)
	local tQuest = wndHandler:GetData()
	local wndQuest = tQuest.wndQuest
	local queCur = tQuest.queQuest
	
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and Apollo.IsShiftKeyDown() then
		Event_FireGenericEvent("GenericEvent_QuestLink", queCur)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Right or (wndQuest:FindChild("QuestGearBtn") and wndQuest:FindChild("QuestGearBtn"):ContainsMouse()) then
		self:ShowQuestRightClick(queCur)
	else
		queCur:ShowHintArrow()
		GameLib.SetInteractHintArrowObject(queCur) 
		if self.tClickBlinkingQuest then
			self.timerArrowBlinker:Stop()
			self.tClickBlinkingQuest:SetActiveQuest(false)
		elseif self.tHoverBlinkingQuest then
			self.tHoverBlinkingQuest:SetActiveQuest(false)
		end

		if Quest.is(wndQuest:GetData()) then
			self.tClickBlinkingQuest = queCur
			self.tClickBlinkingQuest:ToggleActiveQuest()
			self.timerArrowBlinker:Start()
		end
	end
end

function ContractTracker:OnQuestObjectiveHintArrow(wndHandler, wndControl, eMouseButton) -- "QuestObjectiveBtn" (can be from EventItem), data is { tQuest, tObjective.index }
	local tData = wndHandler:GetData()
	if tData and tData.queOwner then
		tData.queOwner:ShowHintArrow(tData.nObjectiveIdx)
		GameLib.SetInteractHintArrowObject(tData.queOwner, tData.nObjectiveIdx)
		if self.tClickBlinkingQuest then
			self.timerArrowBlinker:Stop()
			self.tClickBlinkingQuest:SetActiveQuest(false)
		elseif self.tHoverBlinkingQuest then
			self.tHoverBlinkingQuest:SetActiveQuest(false)
		end

		if Quest.is(tData.queOwner) then
			self.tClickBlinkingQuest = tData.queOwner
			self.tClickBlinkingQuest:ToggleActiveQuest()
			self.timerArrowBlinker:Start()
		end
	end

	return true -- Stop Propagation so the Quest Hint Arrow won't eat this call
end

function ContractTracker:OnArrowBlinkerTimer()
	if self.tClickBlinkingQuest ~= nil then
		self.tClickBlinkingQuest:SetActiveQuest(false)
		self.tClickBlinkingQuest = nil
	end

	if self.tHoverBlinkingQuest then
		self.tHoverBlinkingQuest:ToggleActiveQuest()
	end
end

function ContractTracker:OnGenerateTooltip(wndControl, wndHandler, eType, arg1, arg2)
	local xml = nil
	if eType == Tooltip.TooltipGenerateType_ItemInstance then -- Doesn't need to compare to item equipped
		if Tooltip ~= nil and Tooltip.GetItemTooltipForm~= nil then
			Tooltip.GetItemTooltipForm(self, wndControl, arg1, {})
		end
	elseif eType == Tooltip.TooltipGenerateType_ItemData then -- Doesn't need to compare to item equipped
		if Tooltip ~= nil and Tooltip.GetItemTooltipForm~= nil then
			Tooltip.GetItemTooltipForm(self, wndControl, arg1, {})
		end
	elseif eType == Tooltip.TooltipGenerateType_GameCommand then
		xml = XmlDoc.new()
		xml:AddLine(arg2)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Macro then
		xml = XmlDoc.new()
		xml:AddLine(arg1)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Spell then
		if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
			Tooltip.GetSpellTooltipForm(self, wndControl, arg1)
		end
	elseif eType == Tooltip.TooltipGenerateType_PetCommand then
		xml = XmlDoc.new()
		xml:AddLine(arg2)
		wndControl:SetTooltipDoc(xml)
	end
end

---------------------------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------------------------
function ContractTracker:HelperSelectInteractHintArrowObject(oCur, wndBtn)
	local oInteractObject = GameLib.GetInteractHintArrowObject()
	if not oInteractObject or (oInteractObject and oInteractObject.eHintArrowType == GameLib.CodeEnumHintType.None) then
		return
	end

	local bIsInteractHintArrowObject = oInteractObject.objTarget and oInteractObject.objTarget == oCur
	if bIsInteractHintArrowObject and not wndBtn:IsChecked() then
		wndBtn:SetCheck(true)
	end
end

function ContractTracker:HelperBuildTimedQuestTitle(queQuest)
	local strTitle = queQuest:GetTitle()
	strTitle = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</T>", kstrLightGrey, strTitle)
	strTitle = self:HelperPrefixTimeString(math.max(0, math.floor(queQuest:GetQuestTimeRemaining() / 1000)), strTitle)
	return strTitle
end

function ContractTracker:HelperPrefixTimeString(fTime, strAppend, strColorOverride)
	local fSeconds = fTime % 60
	local fMinutes = fTime / 60
	local strColor = kstrYellow
	if strColorOverride then
		strColor = strColorOverride
	elseif fMinutes < 1 and fSeconds <= 30 then
		strColor = kstrRed
	end
	local strPrefix = string.format("<T Font=\"CRB_InterfaceMedium_B\" TextColor=\"%s\">(%d:%.02d) </T>", strColor, fMinutes, fSeconds)
	return String_GetWeaselString(Apollo.GetString("QuestTracker_BuildText"), strPrefix, strAppend)
end


local ContractTrackerInst = ContractTracker:new()
ContractTrackerInst:Init()
