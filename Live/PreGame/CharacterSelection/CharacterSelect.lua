-----------------------------------------------------------------------------------------------
-- Client Lua Script for CharacterSelect
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Apollo"
require "Window"
require "CharacterScreenLib"
require "PreGameLib"
require "AlienFxLib"
require "AccountItemLib"
require "StorefrontLib"

local CharacterSelection = {}

local kiCharacterMax = 6
local kiMaxClassCount = 20 -- highest class entry (1-20)
local kiMaxPathCount = 4 -- highest path count (0-3; adding 1 for Lua's ineptitude)
local knCheerAnimation = 1621
local knDeleteModelAttachmentId = 98
local kiCharacterScrollBarWidth = 16
local knMaxCharacterName = 29 --TODO replace with the max length of a character name from PreGameLib once the enum has been created in PreGameLib
local kidDominionFaction = 166
local knAlienFxAllLightsLocation = 134217727

function CharacterSelection:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	o.nCurrentPromotionTokens = 0
	
	return o
end

function CharacterSelection:Init()
	Apollo.RegisterAddon(self)
end

function CharacterSelection:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CharacterSelection.xml")

	Apollo.RegisterEventHandler("LoadFromCharacter",				"OnLoadFromCharacter", self)
	Apollo.RegisterEventHandler("ResolutionChanged",				"OnWindowResized", self)
	Apollo.RegisterEventHandler("ApplicationWindowSizeChanged", 	"OnWindowResized", self)
	Apollo.RegisterEventHandler("CharacterDisabled", 				"OnCharacterDisabled", self)
	Apollo.RegisterEventHandler("CharacterDelete", 					"OnCharacterDeleteResult", self)
	Apollo.RegisterTimerHandler("DeleteFailedTimer", 				"OnDeleteFailedTimer", self)
	Apollo.RegisterEventHandler("AnimationFinished", 				"OnAnimationFinished", self)
	Apollo.RegisterEventHandler("CharacterSelectFail", 				"OnCharacterSelectResult", self)
	Apollo.RegisterEventHandler("CharacterRename", 					"OnCharacterRenameResult", self)
	Apollo.RegisterEventHandler("SelectCharacter", 					"OnSelectCharacter", self)
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate",		"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate",			"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("StoreCatalogReady",				"OnStoreCatalogReady", self)
	Apollo.RegisterEventHandler("AccountCurrencyChanged",			"OnAccountCurrencyChanged", self)

	self.wndSelectList = Apollo.LoadForm(self.xmlDoc, "LeftControlPanel", "Navigation", self)
	self.wndTopPanel = Apollo.LoadForm(self.xmlDoc, "TopContainer", "Navigation", self)
	self.wndDelete = Apollo.LoadForm(self.xmlDoc, "DeleteControls", "Navigation", self)
	self.wndRename = Apollo.LoadForm(self.xmlDoc, "RenameControls", "Navigation", self)
	self.wndDeleteError = Apollo.LoadForm(self.xmlDoc, "DeleteErrorMessage", "Navigation", self)
	self.wndConfirmRealmPVP = Apollo.LoadForm(self.xmlDoc, "ConfirmRealmPVP", nil, self)

	self.wndSelectList:Show(false)
	self.wndTopPanel:Show(false)
	self.wndDelete:Show(false)
	self.wndRename:Show(false)
	self.wndDeleteError:Show(false)
	self.wndConfirmRealmPVP:Show(false)

	self.wndCharacterDeleteBtn = self.wndSelectList:FindChild("DeleteBtn")
	self.wndCharacterDeleteBtn:Enable(false) -- will get turned on by choosing a character through code or player input
	self.tSelectedCharacter = {} -- used to return after mouse-over

	self.nAttemptedDelete = nil
	self.nStartingCharacterRotation = 0
	
	self.timerCharacterInGame = ApolloTimer.Create(0.5, true, "OnRemoveCountdown", self)
	self.timerCharacterInGame:Stop()
end

function CharacterSelection:OnWindowResized()
	if self.wndSelectList and self.wndSelectList:IsValid() and self.wndSelectList:IsShown() then
		--INTENTIONALY SETTING TO "SAME" LOCCATION
		--The self.wndSelectList current window rec is based off old screen size. Need to invalidate the location so that it can recalculate its window rec.
		local tLoc = self.wndSelectList:GetLocation()
		self.wndSelectList:MoveToLocation(tLoc)
		self:HelperResizeCharacterList()
	end
end

function CharacterSelection:OnLoadFromCharacter()
	if not g_arActors.rowsdower then
		g_arActors.rowsdower = g_scene:AddActorByFile( 33, "Art\\Creature\\Rowsdower\\Rowsdower.m3" )
	end
	
	local nTier = AccountItemLib.GetPremiumTier()
	if nTier == nil or nTier < 0 then
		return
	end
	
	self.nCurrentPromotionTokens = AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.PromotionToken):GetAmount()
	local nFreeLevel50sRemaining = CharacterScreenLib.GetFreeLevel50sRemaining()
	
	self.wndSelectList:FindChild("ModelDialog_FullScreen"):Show(not CharacterScreenLib.HasReceivedCharacterList())
	
	self.bLoadFromCharacter = true
	local wndCharacterList = self.wndSelectList:FindChild("CharacterList")
	local wndItem2 = self.wndSelectList:FindChild("CharacterOption01")
	local nDefaultCharacterOptionHeight = 0
	if not wndItem2 then
		wndItem2 = Apollo.LoadForm(self.xmlDoc, "CharacterOption", wndCharacterList, self) --TODO This shouldn't be here
		nDefaultCharacterOptionHeight = wndItem2:GetHeight()
		wndItem2:Destroy()
	else
		nDefaultCharacterOptionHeight = wndItem2:GetHeight()
	end
	
	local btnSel = nil
	self.nAttemptedDelete = nil
	g_eState = LuaEnumState.Select

	self.arItems = {}

	self.wndTopPanel:FindChild("CharacterNameBacker"):Show(true)

	self.wndDelete:Show(false)
	self.wndRename:Show(false)
	self.wndDeleteError:Show(false)
	
	self.wndDelete:FindChild("Delete_CharacterNameEntry"):SetMaxTextLength(knMaxCharacterName+1) --They type the space in this.
	self.wndRename:FindChild("RenameCharacterFirstNameEntry"):SetMaxTextLength(knMaxCharacterName)
	self.wndRename:FindChild("RenameCharacterLastNameEntry"):SetMaxTextLength(knMaxCharacterName)

	self.wndCameraToggles = g_controls:FindChild("CameraControls")
	self.wndCameraToggles:FindChild("ToggleCameraBtnBody"):SetCheck(true)
	self.wndCameraToggles:FindChild("ToggleCameraBtnPortrait"):SetCheck(false)
	g_controls:FindChild("EnterForm"):FindChild("BGArt_BottomRunnerName"):Show(false)
	g_controls:FindChild("EnterForm"):FindChild("BGArt_BottomRunner"):Show(true)
	g_controls:FindChild("EnterForm"):Show(true)
	g_controls:FindChild("EnterBtn"):FindChild("EnterLabel"):SetText(Apollo.GetString("CharacterSelect_EnterGame"))
	g_controls:FindChild("EnterForm"):FindChild("EnterLabel"):SetTextColor(ApolloColor.new("ff3c524f"))
	g_controls:FindChild("EnterBtn"):SetData(nil)
	g_controls:FindChild("EnterBtn"):Enable(false)
	g_controls:FindChild("ExitForm"):Show(true)
	g_controls:FindChild("ExitForm"):Enable(true)
	g_controls:FindChild("ExitForm"):FindChild("BackBtnLabel"):SetText(Apollo.GetString("Command_Logout"))
	g_controls:FindChild("OptionsContainer"):Show(true)

	local wndSel = nil
	local wndForcedSel = nil
	local nCharCount = 0
	local nEntryHeight = 0
	local nNewHeight = 0
	local fLastLoggedOutDays = nil
	local bNeedScroll = false
	local nNumCharacterSlots = AccountItemLib.GetStaticRewardPropertyForTier(nTier, AccountItemLib.CodeEnumRewardProperty.CharacterSlots, 0, true).nValue
	local nMaxSlots = AccountItemLib.GetStaticRewardPropertyForTier(nTier, AccountItemLib.CodeEnumRewardProperty.CharacterSlots, 0, false).nValue
	local wndCharacterCountContainer = self.wndSelectList:FindChild("CharacterCountContainer")
	if g_eFactionRestriction ~= nil then
		wndCharacterCountContainer:Show(false)
		wndCharacterCountContainer = self.wndSelectList:FindChild("VIP_CharacterCountContainer")

		local tFactionSprites = 
		{
			[PreGameLib.CodeEnumFaction.Exile] 		= {strIcon = "CharacterCreate:sprCharC_Ico_Exile_Lrg", strText = Apollo.GetString("Friends_ExilesFaction")},
			[PreGameLib.CodeEnumFaction.Dominion] 	= {strIcon = "CharacterCreate:sprCharC_Ico_Dominion_Lrg", strText = Apollo.GetString("Friends_DominionFaction")},
		}

		local tInfo = tFactionSprites[g_eFactionRestriction]
		if tInfo then
			wndCharacterCountContainer:FindChild("FactionIcon"):SetSprite(tInfo.strIcon)
			wndCharacterCountContainer:FindChild("FactionCallout"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("CharacterSelection_RegionLockedReminder"), tInfo.strText))
		end
	else
		self.wndSelectList:FindChild("VIP_CharacterCountContainer"):Show(false)
	end
	wndCharacterCountContainer:Show(true)

	local wndCharacterCounter = wndCharacterCountContainer:FindChild("CharacterCount")
	
	if g_arCharacters then 
		bNeedScroll = ( #g_arCharacters >= nMaxSlots and #g_arCharacters > kiCharacterMax ) or
		( #g_arCharacters < nMaxSlots and #g_arCharacters + 1 > kiCharacterMax )
	end
	
	self.wndCharacterDeleteBtn:Enable(g_arCharacters and #g_arCharacters > 0 and not(g_arCharacterInWorld and g_arCharacterInWorld.nCharacterIndex ~= nil))
	for idx, tChar in ipairs(g_arCharacters or {}) do
		nCharCount = nCharCount + 1
		local wndItem = self.wndSelectList:FindChild("CharacterOption"..(idx < 10 and ("0"..tostring(idx)) or idx))
		if not wndItem then
			wndItem = Apollo.LoadForm(self.xmlDoc, "CharacterOption", wndCharacterList, self)
			wndItem:SetName("CharacterOption"..(idx < 10 and ("0"..tostring(idx)) or idx))
		end
		wndItem:SetData(tChar)
		local btnItem = wndItem:FindChild("CharacterOptionFrameBtn")
		local wndClassIconComplex = wndItem:FindChild("ClassIconComplex")
		local wndPathIconComplex = wndItem:FindChild("PathIconComplex")

		nEntryHeight = wndItem:GetHeight()

		-- Faction
		wndItem:FindChild("BGFactionFrame_Ex"):Show(tChar.idFaction ~= kidDominionFaction)
		wndItem:FindChild("BGFactionFrame_Dom"):Show(tChar.idFaction == kidDominionFaction)

		if tChar.fLastLoggedOutDays ~= nil and not tChar.bDisabled and ( fLastLoggedOutDays == nil or fLastLoggedOutDays < tChar.fLastLoggedOutDays ) then
			fLastLoggedOutDays = tChar.fLastLoggedOutDays
			wndSel = wndItem
		end

		wndItem:FindChild("Level"):SetText(tChar.nLevel)
		CharacterScreenLib.ApplyCharacterToCostumeWindow(idx, wndItem:FindChild("CharacterPortrait"))

		for iClassIcon = 1, kiMaxClassCount do
			wndClassIconComplex:FindChild("ClassIcon_" .. iClassIcon):Show(false) -- hides all
		end

		if tChar.idClass <= kiMaxClassCount then -- prevents breaking from a really bizarre class number
			wndClassIconComplex:FindChild("ClassIcon_" .. tChar.idClass):Show(true)
		end

		for iPathIcon = 1, kiMaxPathCount do
			wndPathIconComplex:FindChild("PathIcon_" .. iPathIcon):Show(false) -- hides all
		end

		local iAdjustedPath = tChar.idPath + 1 --CPP zero indexes paths
		if iAdjustedPath <= kiMaxPathCount then -- prevents breaking from a really bizarre path number
			wndPathIconComplex:FindChild("PathIcon_" .. iAdjustedPath):Show(true)
		end

		--Resize name and location and align center vertical
		wndItem:FindChild("CharacterName"):SetData(tChar.strName or "")
		wndItem:FindChild("Location"):SetData(tChar.strZone or "")
		local strCharName = wndItem:FindChild("CharacterName"):GetData()
		local strLocation = wndItem:FindChild("Location"):GetData()

		wndItem:FindChild("CharacterName"):SetAML(string.format("<P Font=\"CRB_HeaderTiny\" TextColor=\"UI_BtnTextBlueNormal\">%s</P>", strCharName))
		wndItem:FindChild("Location"):SetAML(string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBody\">%s</P>", strLocation))

		wndItem:FindChild("Location"):SetHeightToContentHeight()
		wndItem:FindChild("CharacterName"):SetHeightToContentHeight()

		local nLeftLoc, nTopLoc, nRightLoc, nBottomLoc = wndItem:FindChild("Location"):GetOriginalLocation():GetOffsets()
		local nLeftName, nTopName, nRightName, nBottomName = wndItem:FindChild("CharacterName"):GetOriginalLocation():GetOffsets()
		wndItem:FindChild("CharacterName"):SetAnchorOffsets(nLeftName, nBottomLoc, nRightName, nBottomLoc + wndItem:FindChild("CharacterName"):GetHeight())
		wndItem:FindChild("CharacterNameLocationFrame"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Middle)
		
		if tChar.bDisabled then
			wndItem:FindChild("CharacterOptionFrameBtn"):Show(false)
			wndItem:FindChild("BGFactionFrame_Ex"):SetBGColor(CColor.new(0.4, 0.4, 0.4, 1.0))
			wndItem:FindChild("BGFactionFrame_Dom"):SetBGColor(CColor.new(0.4, 0.4, 0.4, 1.0))
			wndItem:FindChild("Level"):SetTextColor(ApolloColor.new("UI_BtnTextBlueDisabled"))
			wndItem:FindChild("CharacterName"):SetAML(string.format("<P Font=\"CRB_HeaderTiny\" TextColor=\"UI_BtnTextBlueDisabled\">%s</P>", strCharName))
			wndItem:FindChild("Location"):SetAML(string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_BtnTextBlueDisabled\">%s</P>", Apollo.GetString("CharacterSelect_Locked")))

			wndItem:FindChild("LockIcon"):Show(true)

			for iClassIcon = 1, kiMaxClassCount do
				wndClassIconComplex:FindChild("ClassIcon_" .. iClassIcon):SetBGColor(CColor.new(0.4, 0.4, 0.4, 1.0))
			end

			for iPathIcon = 1, kiMaxPathCount do
				wndPathIconComplex:FindChild("PathIcon_" .. iPathIcon):SetBGColor(CColor.new(0.4, 0.4, 0.4, 1.0))
			end
		end

		if g_arCharacterInWorld ~= nil and g_arCharacterInWorld.nCharacterRemoveTime ~= nil and g_arCharacterInWorld.nCharacterRemoveTime > 0 then
			wndItem:FindChild("DisabledBlocker"):Show(g_arCharacterInWorld.nCharacterIndex ~= nCharCount)
			if g_arCharacterInWorld.nCharacterIndex == nCharCount then
				wndForcedSel = wndItem
			end
		end
		
		--resize the item to fit the text.
		local nAdjustedHeight = 16 + wndItem:FindChild("CharacterName"):GetHeight() + wndItem:FindChild("Location"):GetHeight()
		local nNewHeight = math.max(nDefaultCharacterOptionHeight, nAdjustedHeight)
		local nLeft, nTop, nRight, nBottom = wndItem:GetOriginalLocation():GetOffsets()
		wndItem:SetAnchorOffsets(nLeft, nTop, nRight, nTop+nNewHeight)

		btnItem:SetData(idx)
		self.arItems[idx] = wndItem
	end
	for idx = nCharCount + 1, nMaxSlots do
		local wndDestroy = self.wndSelectList:FindChild("CharacterOption"..(idx < 10 and ("0"..tostring(idx)) or idx))
		if wndDestroy then
			wndDestroy:Destroy()
		else
			break
		end
	end
	
	if wndForcedSel ~= nil then
		wndSel = wndForcedSel
	end

	local tRealmInfo = CharacterScreenLib.GetRealmInfo()
	local tRealm = {}
	local strRealm = ""

	local strRealmName = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBodyHighlight\">%s</T>", tostring(tRealmInfo.strName))
	local strRealmLabel = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloTitle\">%s</T>", Apollo.GetString("CharacterSelect_RealmLabel"))
	local strRealmType = tRealmInfo.nRealmPVPType == PreGameLib.CodeEnumRealmPVPType.PVP and Apollo.GetString("RealmSelect_PvP") or Apollo.GetString("RealmSelect_PvE")
	strRealmType = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBodyHighlight\">%s</T>", "("..strRealmType..")")

	strRealm = string.format("<P Align=\"Center\">%s %s</P>", strRealmLabel .. "    " .. strRealmName, strRealmType)
	self.wndTopPanel:FindChild("RealmLabel"):SetText(strRealm)
	self.wndTopPanel:FindChild("RealmNote"):SetText(tRealmInfo.strRealmNote)
	self.wndTopPanel:FindChild("RealmNote"):Show(Apollo.StringLength(tRealmInfo.strRealmNote or "") > 0 and nCharCount == 0)

	if g_arCharacterInWorld ~= nil and g_arCharacterInWorld.nCharacterRemoveTime ~= nil then
		self.timerCharacterInGame:Start()
	end
	
	local wndPrompt = self.wndSelectList:FindChild("CreateNewPrompt")
	if nCharCount == 0 then
		if not wndPrompt then
			wndPrompt = Apollo.LoadForm(self.xmlDoc, "CreateNewPrompt", wndCharacterList, self)
		else
			wndPrompt:Show(true)
		end
		nNewHeight = wndPrompt:GetHeight()
		nCharCount = 1
		wndPrompt:FindChild("DisabledBlocker"):Show(g_arCharacterInWorld ~= nil and g_arCharacterInWorld.nCharacterIndex ~= nil)

		local tRealmInfo = CharacterScreenLib.GetRealmInfo()
		local tRealm = {}
		local strRealm = ""
		local nLeft, nTop, nRight, nBottom = wndPrompt:FindChild("RealmLabelCharacter"):GetAnchorOffsets()
		local strRealmName = tRealmInfo.strName
		local strRealmType = tRealmInfo.nRealmPVPType == PreGameLib.CodeEnumRealmPVPType.PVP and Apollo.GetString("RealmSelect_PvP") or Apollo.GetString("RealmSelect_PvE")
		
		wndPrompt:FindChild("RealmLabelCharacter"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("CharacterSelection_RealmNotification"), strRealmName, strRealmType))
		wndPrompt:FindChild("RealmNoteCharacter"):SetText(tRealmInfo.strRealmNote)
		
		if Apollo.StringLength(tRealmInfo.strRealmNote or "") > 0 then
			wndPrompt:FindChild("RealmLabelCharacter"):SetAnchorOffsets(nLeft, 16, nRight, 39)
		else
			wndPrompt:FindChild("RealmLabelCharacter"):SetAnchorOffsets(nLeft, 26, nRight, 49)
		end
	elseif wndPrompt and wndPrompt:IsShown() then
		wndPrompt:Show(false)
	end

	local tCharSlotsEntitlement = AccountItemLib.GetAccountEntitlement(AccountItemLib.CodeEnumEntitlement.BaseCharacterSlots)
	if tCharSlotsEntitlement then
		nNumCharacterSlots = nNumCharacterSlots + tCharSlotsEntitlement.nCount
	else
		nNumCharacterSlots = math.max(nNumCharacterSlots, nCharCount)
	end

	local bCanCreateCharacter = nNumCharacterSlots > nCharCount
	local bCanCreate50Character = bCanCreateCharacter and (AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.PromotionToken):GetAmount() > 0 or nFreeLevel50sRemaining > 0)
	local bCanBuy50Character = bCanCreateCharacter and not bCanCreate50Character and AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.CanPurchasePromotionToken) > 0
	local bCanGetNewSlot = nMaxSlots > nNumCharacterSlots
	
	if bCanCreateCharacter then
		local strWindowName = "CreateNewOption90Create"
		local wndCreate = self.wndSelectList:FindChild(strWindowName)
		if wndCreate == nil or not wndCreate:IsValid() then
			wndCreate = Apollo.LoadForm(self.xmlDoc, "CreateNewOption", wndCharacterList, self)
			wndCreate:SetName(strWindowName)
		end
		wndCreate:Show(true)
		wndCreate:FindChild("Title"):Show(true)
		wndCreate:FindChild("DisabledBlocker"):Show(g_arCharacterInWorld ~= nil and g_arCharacterInWorld.nCharacterIndex ~= nil)
	else
		local wndCreate = self.wndSelectList:FindChild("CreateNewOption90Create")
		if wndCreate ~= nil and wndCreate:IsValid() then
			wndCreate:Show(false)
		end
	end
	
	if bCanCreate50Character then
		local strWindowName = "CreateNewOption92Create50"
		local wndCreate = self.wndSelectList:FindChild(strWindowName)
		if wndCreate == nil or not wndCreate:IsValid() then
			wndCreate = Apollo.LoadForm(self.xmlDoc, "CreateNewOption", wndCharacterList, self)
			wndCreate:SetName(strWindowName)
		end
		wndCreate:Show(true)
		wndCreate:FindChild("TitleLvl50"):Show(true)
		wndCreate:FindChild("DisabledBlocker"):Show(g_arCharacterInWorld ~= nil and g_arCharacterInWorld.nCharacterIndex ~= nil)
		local numAvailable = nFreeLevel50sRemaining
		if numAvailable == 0 then
			numAvailable = self.nCurrentPromotionTokens
		end
		wndCreate:FindChild("TokenCount"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("AccountServices_NumAvailable"), numAvailable))
	else
		local wndCreate = self.wndSelectList:FindChild("CreateNewOption92Create50")
		if wndCreate ~= nil and wndCreate:IsValid() then
			wndCreate:Show(false)
		end
	end
	
	if bCanBuy50Character then
		local strWindowName = "CreateNewOption95Buy50"
		local wndCreate50 = self.wndSelectList:FindChild(strWindowName)
		if wndCreate50 == nil or not wndCreate50:IsValid() then
			wndCreate50 = Apollo.LoadForm(self.xmlDoc, "CreateNewOption", wndCharacterList, self)
			wndCreate50:SetName(strWindowName)
		end
		wndCreate50:Show(true)
		wndCreate50:FindChild("TitleMTXLvl50"):Show(true)
		wndCreate50:FindChild("TitleMTXLvl50:PurchaseLvl50Btn"):SetData(StorefrontLib.CodeEnumStoreLink.PromotionToken)
		wndCreate50:FindChild("DisabledBlocker"):Show((g_arCharacterInWorld ~= nil and g_arCharacterInWorld.nCharacterIndex ~= nil) or not StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.PromotionToken))
	else
		local wndCreate50 = self.wndSelectList:FindChild("CreateNewOption95Buy50")
		if wndCreate50 ~= nil and wndCreate50:IsValid() then
			wndCreate50:Show(false)
		end
	end
	
	if bCanGetNewSlot then
		local strWindowName = "CreateNewOption99AddSlot"
		local wndAddSlot = self.wndSelectList:FindChild(strWindowName)
		if wndAddSlot == nil or not wndAddSlot:IsValid() then
			wndAddSlot = Apollo.LoadForm(self.xmlDoc, "CreateNewOption", wndCharacterList, self)
			wndAddSlot:SetName(strWindowName)
		end
		wndAddSlot:Show(true)
		wndAddSlot:FindChild("TitleMTX"):Show(true)
		wndAddSlot:FindChild("TitleMTX:PurchaseSlotBtn"):SetData(StorefrontLib.CodeEnumStoreLink.CharacterSlot)
		wndAddSlot:FindChild("DisabledBlocker"):Show(not StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.CharacterSlot))
	else
		local wndAddSlot = self.wndSelectList:FindChild("CreateNewOption99AddSlot")
		if wndAddSlot ~= nil and wndAddSlot:IsValid() then
			wndAddSlot:Show(false)
		end
	end

	self:HelperResizeCharacterList()
	local strColor = "UI_TextHoloBodyHighlight"
	if AccountItemLib.GetPremiumSystem() == AccountItemLib.CodeEnumPremiumSystem.Hybrid then
		if nNumCharacterSlots > CharacterScreenLib.GetBaseCharacterSlots() then
			strColor = "UI_WindowYellow"
		end
		wndCharacterCountContainer:SetTooltip(PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_CharacterSlotCountTooltip"), nNumCharacterSlots, nMaxSlots))
	end
	wndCharacterCounter:SetAML(string.format('<P Font="CRB_InterfaceMedium" Align="Center"><T TextColor="UI_TextHoloBodyHighlight">%s</T></P>', PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_CharacterCounter"), tostring(nCharCount),  string.format('<T TextColor="'..strColor..'">%d</T>', nNumCharacterSlots))))
	
	if wndSel ~= nil then
		local btnSel = wndSel:FindChild("CharacterOptionFrameBtn")
		self:OnCharacterSelectCheck(btnSel, btnSel)
	else -- no default
		if #self.arItems > 0 then
			local btnSel = self.arItems[1]:FindChild("CharacterOptionFrameBtn")
			self:OnCharacterSelectCheck(btnSel, btnSel)
		else
			self.wndTopPanel:FindChild("CharacterNameBacker"):SetText(Apollo.GetString("CharacterSelect_NoCharactersFound"))

			if not g_arActors.rowsdower then
				g_arActors.rowsdower = g_scene:AddActorByFile( 33, "Art\\Creature\\Rowsdower\\Rowsdower.m3" )
			end

			if g_arActors.characterAttach then
				g_arActors.characterAttach:FollowActor(g_arActors.pedestal, PreGameLib.CodeEnumModelAttachment.PropMisc01)
				g_arActors.characterAttach:Animate(0, 1120, 0, true, false, 0, g_nCharCurrentRot)
			end

			if g_arActors.primary then
				g_arActors.primary:FollowActor(g_arActors.characterAttach, PreGameLib.CodeEnumModelAttachment.PropMisc01)
				g_arActors.primary:Animate(0, 5612, 0, true, false)
			end

			if g_arActors.soloLight then
				g_arActors.soloLight:FollowActor( g_arActors.primary, PreGameLib.CodeEnumModelAttachment.Head)
			end

			g_nCharCurrentRot = 0

			g_bReplaceActor = true

			-- Disable the faction/race/class icons
			if g_arActors.factionIcon ~= nil then
				g_arActors.factionIcon:Animate(0, 6670, 0, true, false)
			end

			if g_arActors.weaponIcon ~= nil then
				g_arActors.weaponIcon:Animate(0, 6667, 0, true, false)
			end

			if g_arActors.pathIcon ~= nil then
				g_arActors.pathIcon:Animate(0, 1109, 0, true, false)
			end

			PreGameLib.Event_FireGenericEvent("Select_SetModel", nil, nil, nil, nil, nil, nil)--Tell character to reposition model
		end
	end

	self.wndSelectList:Show(true)
	self.wndTopPanel:Show(true)

	self.wndSelectList:SetFocus()

	PreGameLib.SetMusic(PreGameLib.CodeEnumMusic.CharacterSelect)

	if g_arActors.warningLight1 then
		g_arActors.warningLight1:Animate(0, 1122, 0, true, false)
	end

	if g_arActors.warningLight2 then
		g_arActors.warningLight2:Animate(0, 1122, 0, true, false)
	end
end

function CharacterSelection:HelperResizeCharacterList()
	if not self.wndSelectList or not self.wndSelectList:IsValid() then
		return
	end

	local wndCharacterList = self.wndSelectList:FindChild("CharacterList")
	local wndContainer = self.wndSelectList:FindChild("Container")

	local wndResizeAroundContainer = self.wndSelectList:FindChild("CharacterCountContainer")
	if g_eFactionRestriction ~= nil then
		wndResizeAroundContainer = self.wndSelectList:FindChild("VIP_CharacterCountContainer")
	end

	local nLeft, nTop, nRight, nBottom = wndResizeAroundContainer:GetAnchorOffsets()
	local nNewTop = nBottom + wndResizeAroundContainer:GetHeight() / 4--Adjusting the height of the character list conatiner to be just under faction restriction.

	local wndBGInset = self.wndSelectList:FindChild("BGInset")
	nLeft, nTop, nRight, nBottom = wndBGInset:GetAnchorOffsets()
	wndBGInset:SetAnchorOffsets(nLeft, nNewTop, nRight, nBottom)

	local nParentHeight = wndContainer:GetHeight()
	local nNeededHeight = wndCharacterList:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function (a, b) return a:GetName() < b:GetName() end)
	local nChange = nNeededHeight - wndCharacterList:GetHeight()
	local nNeededParentHeight = nParentHeight + nChange

	local nRootHeight = self.wndSelectList:GetHeight()
	local nHalfSpaceNeeded = math.min(nRootHeight / 2, nNeededParentHeight/2)

	local nLeft, nTop, nRight, nBottom = wndContainer:GetAnchorOffsets()
	wndContainer:SetAnchorOffsets(nLeft, -nHalfSpaceNeeded, nRight, nHalfSpaceNeeded)
	wndContainer:RecalculateContentExtents()
end

function CharacterSelection:OnRemoveCountdown()
	self.wndSelectList:FindChild("DisabledCountBG"):Show(true)
	self.wndCharacterDeleteBtn:Enable(false)
	g_arCharacterInWorld.nCharacterRemoveTime = g_arCharacterInWorld.nCharacterRemoveTime - 500
	local nTimeLeft = g_arCharacterInWorld.nCharacterRemoveTime / 1000

	local strName = ""
	if g_arCharacters and g_arCharacterInWorld.nCharacterIndex and g_arCharacters[g_arCharacterInWorld.nCharacterIndex] then
		strName = g_arCharacters[g_arCharacterInWorld.nCharacterIndex]["strName"] or ""
	end
	self.wndSelectList:FindChild("DisabledCountName"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("CharacterSelect_LogOffName"), strName))
	self.wndSelectList:FindChild("DisabledCountText"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("CharacterSelect_LogOffMessage"), nTimeLeft))

	if nTimeLeft < 0 then
		self.wndSelectList:FindChild("DisabledCountBG"):Show(false)
		for idx, wndCharacter in pairs(self.wndSelectList:FindChild("CharacterList"):GetChildren()) do
			local wndTitleMTX = wndCharacter:FindChild("TitleMTX")
			if not wndTitleMTX or not wndTitleMTX:IsShown() then
				wndCharacter:FindChild("DisabledBlocker"):Show(false)
			end
		end
		self.timerCharacterInGame:Stop()
		self.wndCharacterDeleteBtn:Enable(g_arCharacters and #g_arCharacters > 0)
		g_arCharacterInWorld = nil
	end
end

function CharacterSelection:OnCharacterSelectCheck(wndHandler, wndControl, iButton, bWasDoubleClick)
	if wndHandler ~= wndControl then
		return false
	end
	
	local wndCharacter = wndControl:GetParent()
	local nId = wndControl:GetData()

	-- Send event to Account Services (which may need it)
	PreGameLib.Event_FireGenericEvent("Pregame_CharacterSelected", { nId = nId, tSelected = g_arCharacters[nId]})

	-- Set check in case we're doing this from code and not an actual click
	if not wndControl:IsChecked() then
		wndControl:SetCheck(true)
	end
	
	self:SetCharacterDisplay(nId)
	self.wndRename:Show(false)

	for idx, wndItem in ipairs(self.arItems) do
		if wndItem == wndCharacter then
			self:HelperFormatEntrySelected(wndItem)-- Do stuff to the selected one
		else
			self:HelperFormatEntryDeselected(wndItem) -- Do stuff to the non-selected ones
		end
	end
	
	if bWasDoubleClick and iButton == 0 or iButton == 1 then
		self:OnSelectCharacter(nId)
		return
	end
end

function CharacterSelection:HelperFormatEntrySelected(wnd)
	-- this sets up the non-current character choices
	local strCharName = wnd:FindChild("CharacterName"):GetData()
	wnd:FindChild("CharacterName"):SetAML(string.format("<P Font=\"CRB_HeaderTiny\" TextColor=\"FFFFFFFF\">%s</P>", strCharName))
	wnd:FindChild("Level"):SetTextColor(ApolloColor.new("white"))
	local tChar = wnd:GetData()
	if tChar ~= nil and AlienFxLib.IsReady() and AlienFxLib.CanUse() then
		if tChar.idFaction == kidDominionFaction then
			AlienFxLib.SetLocationColor(knAlienFxAllLightsLocation, ApolloColor.new("Red"))
		else
			AlienFxLib.SetLocationColor(knAlienFxAllLightsLocation, ApolloColor.new("Blue"))
		end
	end
	wnd:FindChild("CharacterOptionFrameBtn"):SetCheck(true)
end

function CharacterSelection:HelperFormatEntryDeselected(wnd)
	-- this sets up the non-current character choices
	local wndBtn = wnd:FindChild("CharacterOptionFrameBtn")
	if wndBtn:IsShown() then
		local strCharName = wnd:FindChild("CharacterName"):GetData()
		wnd:FindChild("CharacterName"):SetAML(string.format("<P Font=\"CRB_HeaderTiny\" TextColor=\"UI_BtnTextBlueNormal\">%s</P>", strCharName))
		wnd:FindChild("Level"):SetTextColor(ApolloColor.new("UI_TextHoloBody"))
		wndBtn:SetCheck(false)
	end
end

-------------

function CharacterSelection:SetCharacterDisplay(tId)
	local tSetChar = g_arCharacters[tId]
	self.wndCharacterDeleteBtn:Enable((g_arCharacters and #g_arCharacters > 0) and not (g_arCharacterInWorld and g_arCharacterInWorld.nCharacterIndex ~= nil))
	if tSetChar == nil then
		g_controls:FindChild("EnterBtn"):SetData(nil)
		g_controls:FindChild("EnterBtn"):Enable(false)
		g_controls:FindChild("EnterForm"):FindChild("EnterLabel"):SetTextColor(ApolloColor.new("ff3c524f"))
		return
	end

	self:SetCharacterCreateModel(tId)

	self.tSelectedCharacter = tSetChar
	g_controls:FindChild("EnterBtn"):Enable(true)
	g_controls:FindChild("EnterForm"):FindChild("EnterLabel"):SetTextColor(ApolloColor.new("ff72f2a0"))
	g_controls:FindChild("EnterBtn"):SetData(tId)
	self.wndTopPanel:FindChild("CharacterNameBacker"):SetText(tSetChar.strName)
end

---------------------------------------------------------------------------------------------------
function CharacterSelection:SetCharacterCreateModel(nId)
	--Set the actor if we don't have one or update to match race/gender
	local tSelected = g_arCharacters[nId]
	g_arActors.primary = g_scene:AddActorByRaceGenderClass(1, tSelected.idRace, tSelected.idGender, tSelected.idClass)

	PreGameLib.Event_FireGenericEvent(
		"Select_SetModel",
		tSelected.idRace,
		tSelected.idGender,
		tSelected.idFaction,
		tSelected.idClass,
		tSelected.idPath,
		nId
	)
end

function CharacterSelection:OnSelectCharacter(tId)
	local tSetChar
	if tId ~= nil then
		tSetChar = g_arCharacters[tId]
	end

	if tSetChar == nil then
		return
	end
	
	if AlienFxLib.IsReady() and AlienFxLib.CanUse() then
		if tSetChar.idFaction == kidDominionFaction then
			AlienFxLib.SetLocationColor(knAlienFxAllLightsLocation, ApolloColor.new("Red"))
		else
			AlienFxLib.SetLocationColor(knAlienFxAllLightsLocation, ApolloColor.new("Blue"))
		end
	end

	if tSetChar.bRequiresRename then
		self.wndRename:FindChild("RenameCharacterFirstNameEntry"):SetFocus()
		self.wndRename:FindChild("RenameCharacterFirstNameEntry"):SetText("")
		self.wndRename:FindChild("RenameCharacterLastNameEntry"):SetText("")
		self.wndRename:FindChild("Rename_ConfirmRenameBtn"):Enable(false)
		self.wndRename:FindChild("StatusFirstValidAlert"):Show(false)
		self.wndRename:FindChild("StatusLastValidAlert"):Show(false)
		self.wndRename:FindChild("CharacterLimit"):SetText(string.format("[%s/%s]", 0, knMaxCharacterName))
		self.wndRename:Show(true)
	else
		CharacterScreenLib.SelectCharacter(tId)
	end
end

function CharacterSelection:PopupError(strResult, strTitle)
	Apollo.CreateTimer("DeleteFailedTimer", 10.0, false)
	Apollo.StartTimer("DeleteFailedTimer")
	self.wndDeleteError:FindChild("DeleteError_Body"):SetText(strResult)
	self.wndDeleteError:FindChild("DeleteError_Title"):SetText(strTitle)
	self.wndDeleteError:Show(true)
end

function CharacterSelection:OnCharacterDisabled(nCharacterIdx, bDisabled)
	if not self.wndSelectList or not self.wndSelectList:IsValid() or not self.wndSelectList:FindChild("CharacterList") then
		return
	end

	for idx, wndItem in ipairs(self.wndSelectList:FindChild("CharacterList"):GetChildren()) do
		local btnItem = wndItem:FindChild("CharacterOptionFrameBtn")
		local wndClassIconComplex = wndItem:FindChild("ClassIconComplex")
		local wndPathIconComplex = wndItem:FindChild("PathIconComplex")

		if btnItem:GetData() == nCharacterIdx and bDisabled then
			local strCharName = wnd:FindChild("CharacterName"):GetData()
			local strLocation = wnd:FindChild("Location"):GetData()
			wnd:FindChild("CharacterName"):SetAML(string.format("<P Font=\"CRB_HeaderTiny\" TextColor=\"UI_BtnTextBlueDisabled\">%s</P>", strCharName))
			wnd:FindChild("Location"):SetAML(string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_BtnTextBlueDisabled\">%s</P>", strLocation))
			wndItem:FindChild("CharacterOptionFrameBtn"):Show(false)
			wndItem:FindChild("BGFactionFrame_Ex"):SetBGColor(CColor.new(0.4, 0.4, 0.4, 1.0))
			wndItem:FindChild("BGFactionFrame_Dom"):SetBGColor(CColor.new(0.4, 0.4, 0.4, 1.0))
			wndItem:FindChild("Level"):SetTextColor(ApolloColor.new("UI_BtnTextBlueDisabled"))
			wndItem:FindChild("LockIcon"):Show(true)

			for iClassIcon = 1, kiMaxClassCount do
				wndClassIconComplex:FindChild("ClassIcon_" .. iClassIcon):SetBGColor(CColor.new(0.4, 0.4, 0.4, 1.0))
			end

			for iPathIcon = 1, kiMaxPathCount do
				wndPathIconComplex:FindChild("PathIcon_" .. iPathIcon):SetBGColor(CColor.new(0.4, 0.4, 0.4, 1.0))
			end

			break
		elseif btnItem:GetData() == nCharacterIdx then
				wndItem:FindChild("CharacterOptionFrameBtn"):Show(true)
			local strCharName = wnd:FindChild("CharacterName"):GetData()
			wnd:FindChild("CharacterName"):SetAML(string.format("<P Font=\"CRB_HeaderTiny\" TextColor=\"UI_BtnTextBlueNormal\">%s</P>", strCharName))
			wnd:FindChild("Location"):SetAML(string.format("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_BtnTextBlueNormal\">%s</P>", ""))
			wndItem:FindChild("BGFactionFrame_Ex"):SetBGColor("white")
			wndItem:FindChild("BGFactionFrame_Dom"):SetBGColor("white")
			wndItem:FindChild("Level"):SetTextColor(ApolloColor.new("UI_BtnTextBlueNormal"))
			wndItem:FindChild("LockIcon"):Show(false)

			for iClassIcon = 1, kiMaxClassCount do
				wndClassIconComplex:FindChild("ClassIcon_" .. iClassIcon):SetBGColor("white")
			end

			for iPathIcon = 1, kiMaxPathCount do
				wndPathIconComplex:FindChild("PathIcon_" .. iPathIcon):SetBGColor("white")
			end

			break
		end
	end
end

function CharacterSelection:OnCharacterDeleteResult(eDeleteResult, nData)

	if g_eState ~= LuaEnumState.Delete or self.nAttemptedDelete == nil then
		return
	end

	local nCharMax = #g_arCharacters

	if eDeleteResult == PreGameLib.CodeEnumCharacterModifyResults.DeleteOk then
		for idx = self.nAttemptedDelete, nCharMax do
			if g_arCharacters[idx+1] ~= nil then
				g_arCharacters[idx] = g_arCharacters[idx+1]
			end
		end
		table.remove(g_arCharacters, nCharMax)

		local tRealmInfo = CharacterScreenLib.GetRealmInfo()
		if tRealmInfo and tRealmInfo.bFactionRestricted then
			--May have just deleted last character on realm so no more faction restriction set.
			local nFactionRestriction = CharacterScreenLib.GetFactionRestriction()
			if nFactionRestriction ~= 0 then
				g_eFactionRestriction = nFactionRestriction
			else
				g_eFactionRestriction = nil
			end
		end

		-- special effect
		g_arActors.deleteEffect = g_scene:AddActorByFile(20000, "Art\\FX\\Model\\OT\\CharacterDelete_RED\\CharacterDelete_RED.m3")
		if g_arActors.deleteEffect then
			g_arActors.deleteEffect:AttachToActor( g_arActors.primary, knDeleteModelAttachmentId )
			g_arActors.deleteEffect:Animate(0, 150, 0, false, true)
			g_controls:FindChild("PregameControls:ExitForm:BackBtnLabel"):Enable(false)
		else
			self:OnLoadFromCharacter()
		end

	else -- couldn't delete
		local strResult = Apollo.GetString("CharacterSelect_DefaultDeleteError")
		if eDeleteResult == PreGameLib.CodeEnumCharacterModifyResults.DeleteFailed then -- failed for some reason
			strResult = Apollo.GetString("CharacterSelect_DefaultDeleteError")
		elseif eDeleteResult == PreGameLib.CodeEnumCharacterModifyResults.DeleteFailed_GuildMaster then -- failed for being a guild master

			strResult = PreGameLib.String_GetWeaselString(Apollo.GetString("CharacterSelect_DeleteGuildMaster"), {["count"] = nData, ["name"] = Apollo.GetString("CharacterSelect_DeleteGuildMaster2")})
		elseif eDeleteResult == PreGameLib.CodeEnumCharacterModifyResults.DeleteFailed_CharacterOnline then -- failed for character still online
			strResult = Apollo.GetString("CharacterSelect_DeleteErrorFailedCharacterOnline")
		end

		local strTitle = Apollo.GetString("CharacterSelect_DeleteErrorTitle")
		self:PopupError(strResult, strTitle)

		self.wndDelete:FindChild("Delete_CharacterNameEntry"):SetText("")
		self.wndDelete:FindChild("Delete_CharacterNameEntry"):SetFocus()

	--[[	if g_arActors.primary then
			g_arActors.primary:Animate(0, knCheerAnimation, 0, false, true)
		end

		self.bDeleteError = true--]]
	end
end

function CharacterSelection:OnDeleteFailedTimer()
	self.wndDeleteError:Show(false)
end


function CharacterSelection:OnAnimationFinished( actor, nLayer, nSequence )
	if g_arActors.deleteEffect and g_arActors.deleteEffect == actor then
		g_controls:FindChild("PregameControls:ExitForm:BackBtnLabel"):Enable(true)

		g_arActors.primary:FollowActor( g_arActors.mainScene, PreGameLib.CodeEnumModelAttachment.FXMisc07)
		g_arActors.primary = nil
		g_arActors.deleteEffect = nil
		self:OnLoadFromCharacter()
		g_cameraSlider = 0
		g_arActors.mainScene:Animate(0, g_cameraAnimation, 0, true, false, 0, g_cameraSlider)
	end
end

function CharacterSelection:OnCharacterSelectResult(nSelectResult)

	local strResult = Apollo.GetString("CharacterSelect_SelectErrorFailed")
	if nSelectResult == PreGameLib.CodeEnumCharacterSelectResults.FailedRename then -- failed because character needs rename
		strResult = Apollo.GetString("CharacterSelect_SelectErrorFailedRename")
	elseif nSelectResult == PreGameLib.CodeEnumCharacterSelectResults.FailedDisabled then -- failed because character is disabled
		strResult = Apollo.GetString("CharacterSelect_SelectErrorFailedDisabled")
	elseif nSelectResult == PreGameLib.CodeEnumCharacterSelectResults.FailedCharacterInWorld then -- failed because another character is still in the world.
		strResult = Apollo.GetString("CharacterSelect_SelectErrorFailedCharacterInWorld")
	end

	local strTitle = Apollo.GetString("CharacterSelect_SelectErrorTitle")
	self:PopupError(strResult, strTitle)
end

function CharacterSelection:OnCharacterRenameResult(nRenameResult, strName)

	if nRenameResult == PreGameLib.CodeEnumCharacterModifyResults.RenameOk then
		local tId = g_controls:FindChild("EnterBtn"):GetData()
		self.wndRename:FindChild("RenameCharacterFirstNameEntry"):SetText("")
		self.wndRename:FindChild("RenameCharacterLastNameEntry"):SetText("")
		if tId ~= nil then
			g_arCharacters[tId].bRequiresRename = false
			g_arCharacters[tId].strName = strName

			if self.arItems[tId] then
				self.arItems[tId]:FindChild("CharacterName"):SetData(strName)
				self.arItems[tId]:FindChild("CharacterName"):SetAML(string.format("<P Font=\"CRB_HeaderTiny\" TextColor=\"FFFFFFFF\">%s</P>", strName))
			end

			self.wndTopPanel:FindChild("CharacterNameBacker"):SetText(strName)
			self:OnLoadFromCharacter()
		end
		return
	end

	local strResult = Apollo.GetString("CharacterSelect_RenameErrorFailed")
	if nRenameResult == PreGameLib.CodeEnumCharacterModifyResults.RenameFailed_Internal then -- failed for some reason
		strResult = Apollo.GetString("CharacterSelect_RenameErrorFailedInternal")
	elseif nRenameResult == PreGameLib.CodeEnumCharacterModifyResults.RenameFailed_InvalidName then
		strResult = Apollo.GetString("CharacterSelect_RenameErrorFailedInvalidName")
	elseif nRenameResult == PreGameLib.CodeEnumCharacterModifyResults.RenameFailed_UniqueName then
		strResult = Apollo.GetString("CharacterSelect_RenameErrorFailedUniqueName")
	elseif nRenameResult == PreGameLib.CodeEnumCharacterModifyResults.RenameFailed_CharacterOnline then
		strResult = Apollo.GetString("CharacterSelect_RenameErrorFailedCharacterOnline")
	elseif nRenameResult == PreGameLib.CodeEnumCharacterModifyResults.RenameFailed_NoRename then
		strResult = Apollo.GetString("CharacterSelect_RenameErrorFailedNoRename")
	end

	local strTitle = Apollo.GetString("CharacterSelect_RenameErrorTitle")
	self:PopupError(strResult, strTitle)
end


---------------------------------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------------------------------

function CharacterSelection:OnMessageAck()
	self.CharacterSelectMsgDlg:Show(false)
end

function CharacterSelection:OnDeleteBtn()

	g_eState = LuaEnumState.Delete
	self.wndDelete:Show(true)
	self.wndTopPanel:FindChild("CharacterNameBacker"):Show(false)
	self.wndCameraToggles:Show(false)
	self.wndRename:Show(false)
	g_controls:FindChild("EnterForm"):Show(false)
	self.wndDelete:FindChild("Delete_CharacterNameEntry"):SetText("")
	self.wndDelete:FindChild("Delete_CharacterNameEntry"):SetPrompt(g_arCharacters[g_controls:FindChild("EnterBtn"):GetData()].strName)
	self.wndDelete:FindChild("DeleteBody"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("CharacterSelect_DeleteDesc"), g_arCharacters[g_controls:FindChild("EnterBtn"):GetData()].strName))

	self.wndDelete:FindChild("Delete_CharacterNameEntry"):Enable(true)
	self.wndDelete:FindChild("Delete_CharacterNameEntry"):SetFocus()
	self.wndDelete:FindChild("DeleteBody"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("CharacterSelect_DeleteDesc"), g_arCharacters[g_controls:FindChild("EnterBtn"):GetData()].strName))
	
	self.wndDelete:FindChild("Delete_ConfirmDeleteBtn"):Enable(false)
	self.wndDelete:FindChild("Delete_ConfirmDeleteBtn"):SetData(g_controls:FindChild("EnterBtn"):GetData())
	g_controls:FindChild("ExitForm"):FindChild("BackBtnLabel"):SetText(Apollo.GetString("CRB_Back"))
	self.wndSelectList:Show(false)
	
	
	PreGameLib.Event_FireGenericEvent("CloseAllOpenAccountWindows")
	PreGameLib.SetMusic(PreGameLib.CodeEnumMusic.CharacterDelete)

	if g_arActors.warningLight1 then
		g_arActors.warningLight1:Animate(0, 1071, 0, true, false)
	end

	if g_arActors.warningLight2 then
		g_arActors.warningLight2:Animate(0, 1071, 0, true, false)
	end

	if g_arActors.primary then
		g_arActors.primary:Animate(0, 5638, 0, true, false)
		g_arActors.primary:SetWeaponSheath(false)
	end
	
	PreGameLib.HideCredits() -- in case the credits is opened, hide it
end

function CharacterSelection:OnCreateBtn(wndHandler, wndControl)
	local tRealmInfo = CharacterScreenLib.GetRealmInfo()
	if tRealmInfo and tRealmInfo.nRealmPVPType == PreGameLib.CodeEnumRealmPVPType.PVP and CharacterScreenLib.GetGameMode() == CharacterScreenLib.CodeEnumGameMode.China then
		self.wndConfirmRealmPVP:Invoke()
	else
		self:HelperCreateCharacter()
	end
	
	PreGameLib.HideCredits()
end

function CharacterSelection:HelperCreateCharacter()
	self.wndRename:Show(false)
	self.wndSelectList:Show(false)
	self.wndTopPanel:Show(false)
	self.wndCameraToggles:Show(false)

	-- call this from the main Character file
	PreGameLib.Event_FireGenericEvent("OpenCharacterCreateBtn")
end

function CharacterSelection:OnCreate50Btn(wndHandler, wndControl)
	self:HelperCreate50Character()
	PreGameLib.HideCredits()
end

function CharacterSelection:HelperCreate50Character()
	self.wndRename:Show(false)
	self.wndSelectList:Show(false)
	self.wndTopPanel:Show(false)
	self.wndCameraToggles:Show(false)

	-- call this from the main Character file
	PreGameLib.Event_FireGenericEvent("OpenCharacterCreate50Btn")
end

function CharacterSelection:OnConfirmRealmPVPShown()
	g_controls:FindChild("EnterBtn"):Enable(false)
	if self.wndSelectList:FindChild("CreateNewPrompt") then
		self.wndSelectList:FindChild("HintWindow"):Show(false)
	end
end

function CharacterSelection:OnConfirmRealmPVPClosed()
	g_controls:FindChild("EnterBtn"):Enable(true)
	if self.wndSelectList:FindChild("CreateNewPrompt") then
		self.wndSelectList:FindChild("HintWindow"):Show(true)
	end
end

function CharacterSelection:OnConfirmPVPBtn()
	self:HelperCreateCharacter()
	self.wndConfirmRealmPVP:Show(false)
end

function CharacterSelection:OnCancelPVPBtn()
	self.wndConfirmRealmPVP:Show(false)
end

function CharacterSelection:OnEnterKey()
	if g_controls:FindChild("EnterBtn"):GetData() ~= nil and not self.wndConfirmRealmPVP:IsShown() then
		self:OnSelectCharacter(g_controls:FindChild("EnterBtn"):GetData())
	end
end

function CharacterSelection:OnDeleteNameEscape(wndHandler, wndControl, strNew)
	local strName = self.wndDelete:FindChild("Delete_CharacterNameEntry"):GetText()

	if strName == nil or strName == "" then
		self:OnLoadFromCharacter()
	else
		self.wndDelete:FindChild("Delete_CharacterNameEntry"):SetText("")
		self.wndDelete:FindChild("Delete_ConfirmDeleteBtn"):Enable(false)
		self.wndDelete:FindChild("Delete_CharacterNameEntry"):SetFocus()
	end
end

function CharacterSelection:OnDeleteNameChanged(wndHandler, wndControl, strNew)
	local strName = self.wndDelete:FindChild("Delete_CharacterNameEntry"):GetText()
	local nId = g_controls:FindChild("EnterBtn"):GetData()
	local tSelected = g_arCharacters[nId]
	local strDelete = tSelected.strName

	self.wndDelete:FindChild("Delete_ConfirmDeleteBtn"):Enable(Apollo.StringToLower(strName) == Apollo.StringToLower(strDelete))
end

function CharacterSelection:OnDeleteConfirm(wndHandler, wndControl)
	self.wndDelete:FindChild("Delete_ConfirmDeleteBtn"):Enable(false)
	self.wndDelete:FindChild("Delete_CharacterNameEntry"):Enable(false)
	self.nAttemptedDelete = g_controls:FindChild("EnterBtn"):GetData()
	CharacterScreenLib.DeleteCharacter(g_controls:FindChild("EnterBtn"):GetData())
	
end

function CharacterSelection:OnDeleteErrorClose(wndHandler, wndControl)
	Apollo.StopTimer("DeleteFailedTimer")
	self.wndDeleteError:Show(false)
end

function CharacterSelection:OnRenameConfirmRename()
	self.wndRename:FindChild("BlockerConfirm"):Show(true)

end

function CharacterSelection:OnRenameCancel()
	self.wndRename:FindChild("BlockerConfirm"):Show(false)
end

function CharacterSelection:OnRenameConfirm(wndHandler, wndControl)
	self.wndRename:Show(false)
	self.wndRename:FindChild("BlockerConfirm"):Show(false)
	if g_controls:FindChild("EnterBtn"):GetData() ~= nil then
		-- this can call CharacterRename result, so don't do anything to conflict with it
		local strFullName = string.format("%s %s", 
			self.wndRename:FindChild("RenameCharacterFirstNameEntry"):GetText(), 
			self.wndRename:FindChild("RenameCharacterLastNameEntry"):GetText()
		)
		
		CharacterScreenLib.RenameCharacter(g_controls:FindChild("EnterBtn"):GetData(), strFullName)
	end
end

function CharacterSelection:OnRenameNameChanged(wndHandler, wndControl)
	-- do something here to show number of characters / validation for name.
	local strFullName = string.format("%s %s", 
		self.wndRename:FindChild("RenameCharacterFirstNameEntry"):GetText(), 
		self.wndRename:FindChild("RenameCharacterLastNameEntry"):GetText()
	)
	
	local strFirstName = self.wndRename:FindChild("RenameCharacterFirstNameEntry"):GetText()
	local nFirstLength = Apollo.StringLength(strFirstName)
	
	local strLastName = self.wndRename:FindChild("RenameCharacterLastNameEntry"):GetText()
	local nLastLength = Apollo.StringLength(strLastName)
	
	local strCharacterLimit = string.format("[%s/%s]", nFirstLength+nLastLength, knMaxCharacterName)
	local strColor = nFirstLength+nLastLength > knMaxCharacterName and "Reddish" or "UI_TextHoloBodyCyan"
	self.wndRename:FindChild("CharacterLimit"):SetTextColor(ApolloColor.new(strColor))
	self.wndRename:FindChild("CharacterLimit"):SetText(strCharacterLimit)
	self.wndRename:FindChild("RenameBodyConfirm"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("CharacterSelection_RenameConfirmBody"), strFullName))
	
	local bFirstValid = CharacterScreenLib.IsCharacterNamePartValid(strFirstName)
	self.wndRename:FindChild("StatusFirstValidAlert"):Show(not bFirstValid and nFirstLength > 0)
	
	local bLastValid = CharacterScreenLib.IsCharacterNamePartValid(strLastName)
	self.wndRename:FindChild("StatusLastValidAlert"):Show(not bLastValid and nLastLength > 0)
	
	local bFullValid = CharacterScreenLib.IsCharacterNameValid(strFullName)
	self.wndRename:FindChild("Rename_ConfirmRenameBtn"):Enable(bFullValid)
	
end

function CharacterSelection:OnRenameNameEscape(wndHandler, wndControl)
	self.wndRename:FindChild("BlockerConfirm"):Show(false)
	self.wndRename:Show(false)
end


function CharacterSelection:OnRealmBtn(wndHandler, wndControl)
	CharacterScreenLib.ExitToRealmSelect()
end

function CharacterSelection:OnRandomLastName()
	local nId = g_controls:FindChild("EnterBtn"):GetData()
	local tSelected = g_arCharacters[nId]
	
	local nRaceId = tSelected.idRace
	local nFactionId = tSelected.idFaction
	local nGenderId = tSelected.idGender
	
	local tName = PreGameLib.GetRandomName(nRaceId, nGenderId, nFactionId)
	
	self.wndRename:FindChild("RenameCharacterLastNameEntry"):SetText(tName.strLastName)
	self.wndRename:FindChild("RenameCharacterFirstNameEntry"):SetText(tName.strFirstName)
	
	self:OnRenameNameChanged()
end

function CharacterSelection:OnEntitlementUpdate(tEntitlementInfo)
	if not self.wndSelectList or not self.bLoadFromCharacter then
		return
	end
	
	if tEntitlementInfo.nEntitlementId == AccountItemLib.CodeEnumEntitlement.BaseCharacterSlots then
		PreGameLib.Event_FireGenericEvent("CloseStore")
		self:OnLoadFromCharacter()
	end
end

function CharacterSelection:OnAccountCurrencyChanged()
	if not self.wndSelectList or not self.bLoadFromCharacter then
		return
	end
	
	if AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.PromotionToken):GetAmount() ~= self.nCurrentPromotionTokens then
		PreGameLib.Event_FireGenericEvent("CloseStore")
		self:OnLoadFromCharacter()
	end
end

function CharacterSelection:OnStoreCatalogReady()
	if not self.wndSelectList or not self.bLoadFromCharacter then
		return
	end
	
	if g_eState == LuaEnumState.Select then
		self:OnLoadFromCharacter()
	end
end

function CharacterSelection:OnStoreBtnSignal(wndHandler, wndControl)
	local tLinkInfo = StorefrontLib.GetLinkInfo(wndControl:GetData())
	if tLinkInfo == nil then
		return
	end
	
	PreGameLib.Event_FireGenericEvent("OpenStoreLinkSingle", tLinkInfo.nOfferGroupId, tLinkInfo.nVariantIndex)
end

---------------------------------------------------------------------------------------------------
-- CharacterSelection instance
---------------------------------------------------------------------------------------------------
local CharacterSelectionInst = CharacterSelection:new()
CharacterSelection:Init()
