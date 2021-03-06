-----------------------------------------------------------------------------------------------
-- Client Lua Script for Keybind
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "GameLib"
require "Apollo"

local Keybind = {}

local LuaEnumKeybindingState =
{
    Idle 					= 0,
    AcceptingInput 			= 1,
    SelectingSet 			= 2,
    ConfirmUnbindDuplicate 	= 3,
    SelectCopySet 			= 4,
	AcceptingModfierInput 	= 5,
}

local knKeybindColumnCount = 3

function Keybind:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	o.tWndRefs = {}
	o.tItems = {}
	o.tCollapsedCategories = {}
	o.nCollapsedCount = 0
	o.bCollapseAll = false
	
	return o
end

function Keybind:Init()
	Apollo.RegisterAddon(self, true, Apollo.GetString("CRB_Keybindings"))
end

function Keybind:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("KeybindingForms.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Keybind:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("WindowManagementReady", 	"OnWindowManagementReady", self)
	self:OnWindowManagementReady()

	Apollo.RegisterEventHandler("InterfaceMenu_Keybindings", 	"OnShow", self)
	Apollo.RegisterEventHandler("MouseWheel", 					"OnMouseWheel", self)
	Apollo.RegisterEventHandler("MouseButtonUp", 				"OnMouseButtonUp", self)
	Apollo.RegisterEventHandler("KeyBindingUpdated", 			"RefreshKeybindList", self) -- reload keybind list
	Apollo.RegisterSlashCommand("keybind", 						"OnShow", self)
	
	-- if without the delay: while dropdown list is visible (and dropdown button is disabled), click on the dropdown button -> 
	-- exit modifier dropdown (close on external click) would close the dropdown and enable dropdown button, 
	-- dropdown button would send a "button up" message, which would trigger the dropdown list to open again
	-- solution: add a delay to exiting modifier to delay the re-enabling of the dropdown button until after the click is done
	self.timerModifierSelectionDelay = ApolloTimer.Create( 0.010, false, "OnExitModifierTimer", self )
	self.timerModifierSelectionDelay:Stop()
end

function Keybind:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("CRB_Keybindings")})
end

function Keybind:OnConfigure()
	self:OnShow()
end



---------------------------------------------------------------------------------------------------
-- Interface
---------------------------------------------------------------------------------------------------

function Keybind:OnShow()
	if self.tWndRefs.wndKeybindList == nil or not self.tWndRefs.wndKeybindList:IsValid() then
	-- Setting up the main keybind interface forms
		self.tWndRefs.wndKeybindForm = Apollo.LoadForm(self.xmlDoc, "KeybindForm", nil, self)

		self.tWndRefs.wndKeybindList = self.tWndRefs.wndKeybindForm:FindChild("KeybindList") --this is the empty list keybinds load into
		self.tWndRefs.wndFeedback = self.tWndRefs.wndKeybindForm:FindChild("FeedbackText")
		self.tWndRefs.wndDuplicateMsg = self.tWndRefs.wndKeybindForm:FindChild("DuplicateMsg")

		self.tWndRefs.wndSetSelectionBtn = self.tWndRefs.wndKeybindForm:FindChild("SetSelection")
		self.tWndRefs.wndSetSave = self.tWndRefs.wndKeybindForm:FindChild("SaveSetButton")
		self.tWndRefs.wndSetCancel = self.tWndRefs.wndKeybindForm:FindChild("CancelSetButton")
		self.tWndRefs.wndBindUnbind = self.tWndRefs.wndKeybindForm:FindChild("UnbindButton")
		self.tWndRefs.wndBindCancel = self.tWndRefs.wndKeybindForm:FindChild("CancelButton")
		self.tWndRefs.wndUndoUnbind = self.tWndRefs.wndKeybindForm:FindChild("UndoBindButton")
		self.tWndRefs.wndRestoreDefaultsBtn = self.tWndRefs.wndKeybindForm:FindChild("RestoreDefaults")
		self.tWndRefs.wndDefaultBtn		= self.tWndRefs.wndKeybindForm:FindChild("DefaultButton")

		self.tWndRefs.wndCollapseAllBtn = self.tWndRefs.wndKeybindForm:FindChild("ToggleCategory")
	
		self.tWndRefs.wndOkForm = self.tWndRefs.wndKeybindForm:FindChild("OkForm")	--this form is for displaying message
		self.tWndRefs.wndOkForm:Show(false)

		Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndKeybindForm, strName = Apollo.GetString("CRB_Keybindings")})

	self.tItems = {}
	self.tWindowCache = {}

	-- keeping track of messages
	self.tMessageQueue = Queue:new()

	-- setting up modifier selection stuffs for sprint
		self.tWndRefs.wndModifierSelection = self.tWndRefs.wndKeybindForm:FindChild("SelectModifier")
	self.nReservedModifier 		= 0 -- for preventing user binding other keys with the chosen modifier for sprint
	self.wndModifierDropdown 	= nil -- for getting the position of the selection window

	-- Setting up the Set Selection interface form
	    self.tWndRefs.wndSetSelection = self.tWndRefs.wndKeybindForm:FindChild("SetSelectionWindow") --shortcut sets are selected from this list
	self.arKeySetBtns =
	{
			[GameLib.CodeEnumInputSets.Account] 	= self.tWndRefs.wndSetSelection:FindChild("AccountCustom"),
			[GameLib.CodeEnumInputSets.Character] 	= self.tWndRefs.wndSetSelection:FindChild("CharacterCustom")
	}
    self.arKeySetNames =
	{
		[GameLib.CodeEnumInputSets.Account] 	= self.arKeySetBtns[GameLib.CodeEnumInputSets.Account]:GetText(),
		[GameLib.CodeEnumInputSets.Character] 	= self.arKeySetBtns[GameLib.CodeEnumInputSets.Character]:GetText()
	}

    self.arKeySetBtns[GameLib.CodeEnumInputSets.Account]:SetData(GameLib.CodeEnumInputSets.Account)
    self.arKeySetBtns[GameLib.CodeEnumInputSets.Character]:SetData(GameLib.CodeEnumInputSets.Character)
	    self.tWndRefs.wndSetSelection:Show(false)

	-- Setting up the Copy Set Confirmation interface form
		self.tWndRefs.wndYesNoForm = self.tWndRefs.wndKeybindForm:FindChild("YesNoForm")	--this form is used to confirm duplicating a set
		self.tWndRefs.wndYesNoForm:Show(false)
		self.tWndRefs.wndYesNoFormYesBtn = self.tWndRefs.wndYesNoForm:FindChild("YesButton")
		self.tWndRefs.wndYesNoFormSaveBtn = self.tWndRefs.wndYesNoForm:FindChild("SaveButton")
end

    GameLib.PauseGameActionInput(true)

	self.tWndRefs.wndKeybindForm:Invoke() -- Order matters, needs to be infront of blocker

    -- get current key set
    self.eCurrKeySet = GameLib.GetCurrInputKeySet()
    self.eOriginalKeySet = self.eCurrKeySet

	for idx, wndButton in pairs(self.arKeySetBtns) do
		wndButton:SetCheck(false)
	end

    self.arKeySetBtns[self.eCurrKeySet]:SetCheck(true)
    self.tWndRefs.wndSetSelectionBtn:SetText(self.arKeySetNames[self.eCurrKeySet])

    self.tWndRefs.wndSetSelection:Show(false)
    self.tWndRefs.wndYesNoForm:Show(false)

    self:InitializeVariables()
	self.arKeyBindings = GameLib.GetKeyBindings()
	self:SetActionDataToSaveConfirmButtons()
	self:PopulateKeybindList()

	self:ShowUndoUnbindMessage(false)
end

function Keybind:SetActionDataToSaveConfirmButtons()
	self.tWndRefs.wndSetSave:SetActionData( GameLib.CodeEnumConfirmButtonType.SaveKeyBinding, self.arKeyBindings )
	self.tWndRefs.wndYesNoFormSaveBtn:SetActionData( GameLib.CodeEnumConfirmButtonType.SaveKeyBinding, self.arKeyBindings )
end


function Keybind:InitializeVariables()
    self:SetState(LuaEnumKeybindingState.Idle)

	-- for keeping track of the current selections before confirming binding
    self.wndCurrBind = nil
	self.wndCurrModifierBind = nil

    -- keep track if there's any unsaved data
    self.bNeedSave = false
    self.bNeedSaveSet = false
    self.bShowingYesNoDialog = false
end

function Keybind:RefreshKeybindList()
	if self.tWndRefs.wndKeybindForm == nil or not self.tWndRefs.wndKeybindForm:IsValid() then
		return
	end

    self.arKeyBindings = GameLib.GetKeyBindings()
	self:SetActionDataToSaveConfirmButtons()
    self:PopulateKeybindList()
end

function Keybind:AddCategory(tCategory)
    -- add new binding into the form
    local wndBindingItem = self:FactoryCacheProduce(self.tWndRefs.wndKeybindList, "KeybindCategoryItem", "C"..tCategory.nCategoryId)
	wndBindingItem:SetText(tCategory.strName)
	wndBindingItem:SetData(tCategory.nCategoryId)
end

function Keybind:IsSprintAction( tBinding )
	if tBinding.strAction == "SprintModifier" then return true end
	return false
end

function Keybind:IsModifierKey( nScanCode )
	local tScancodes = 
	{ 
		[GameLib.CodeEnumInputModifierScancode.LeftCtrl] = true,
		[GameLib.CodeEnumInputModifierScancode.LeftShift] = true,
		[GameLib.CodeEnumInputModifierScancode.LeftAlt] = true,
		[GameLib.CodeEnumInputModifierScancode.RightCtrl] = true,
		[GameLib.CodeEnumInputModifierScancode.RightShift] = true,
		[GameLib.CodeEnumInputModifierScancode.RightAlt] = true,
	}
		
	return tScancodes[nScanCode]
end

function Keybind:ClearSprintIfModifier( iKeyBinding )
	if self.arKeyBindings[iKeyBinding].strAction == "SprintModifier" then
		if self:IsModifierKey(self.arKeyBindings[iKeyBinding].arInputs[1].nCode) or self:IsModifierKey(self.arKeyBindings[iKeyBinding].arInputs[2].nCode) then
	        local tCurrInput = {}
			tCurrInput.eDevice = GameLib.CodeEnumInputDevice.None
	        tCurrInput.nCode = 0
	        tCurrInput.eModifier = 0

		    self.arKeyBindings[iKeyBinding].arInputs[1] = TableUtil:Copy(tCurrInput)
		    self.arKeyBindings[iKeyBinding].arInputs[2] = TableUtil:Copy(tCurrInput)

			self.nReservedModifier = 0

			if self.wndModifierDropdown then
				self.wndModifierDropdown:SetText("") --Apollo.GetString("Keybinding_Unbound"))
			end
			
			self:SetActionDataToSaveConfirmButtons()
		end
	end
end

function Keybind:AddKeyBinding(iKeyBinding, tBinding)
    -- add new binding into the form
	local wndBindingItem
	if self:IsSprintAction(tBinding) then
		wndBindingItem = self:FactoryCacheProduce(self.tWndRefs.wndKeybindList, "KeybindModifierOptKeyItem", "B"..tBinding.idAction)
		wndBindingItem:FindChild("KbList_Text"):SetText(tBinding.strActionLocalized)

		if self:IsModifierKey(tBinding.arInputs[1].nCode) then
			wndBindingItem:FindChild("DropdownButton"):SetText(self:HelperFormatKeybind(GameLib.GetInputKeyNameText(tBinding.arInputs[1])))
			wndBindingItem:FindChild("BindButton1"):SetText("")
		else
			wndBindingItem:FindChild("DropdownButton"):SetText("")
			wndBindingItem:FindChild("BindButton1"):SetText(self:HelperFormatKeybind(GameLib.GetInputKeyNameText(tBinding.arInputs[1])))
		end
		wndBindingItem:FindChild("BindButton1"):SetData(1)
		self.wndModifierDropdown = wndBindingItem:FindChild("DropdownButton")
		self.nReservedModifier = tBinding.arInputs[1].nCode
	else
		wndBindingItem = self:FactoryCacheProduce(self.tWndRefs.wndKeybindList, "KeybindListItem", "B"..tBinding.idAction)
		wndBindingItem:FindChild("KbList_Text"):SetText(tBinding.strActionLocalized)
		wndBindingItem:FindChild("Bindings:BindButton1"):SetText(self:HelperFormatKeybind(GameLib.GetInputKeyNameText(tBinding.arInputs[1])))
		wndBindingItem:FindChild("Bindings:BindButton2"):SetText(self:HelperFormatKeybind(GameLib.GetInputKeyNameText(tBinding.arInputs[2])))
		wndBindingItem:FindChild("Bindings:BindButton3"):SetText(self:HelperFormatKeybind(GameLib.GetInputKeyNameText(tBinding.arInputs[3])))
		wndBindingItem:FindChild("Bindings:BindButton1"):SetData(1)
		wndBindingItem:FindChild("Bindings:BindButton2"):SetData(2)
		wndBindingItem:FindChild("Bindings:BindButton3"):SetData(3)

		wndBindingItem:FindChild("Bindings"):SetData(iKeyBinding)

		if tBinding.iInputKeyLookupGroup == GameLib.CodeEnumInputKeyLookupGroup.StunBreakoutGameplay and not wndBindingItem:FindChild("MultiBindIcon") then
			Apollo.LoadForm(self.xmlDoc, "MultiBindIcon", wndBindingItem, self)
		end
	end
	self.tItems[tBinding.idAction] = wndBindingItem
	wndBindingItem:SetData(iKeyBinding)
	wndBindingItem:Show(not self.tCollapsedCategories[tBinding.idCategory])
end

function Keybind:HelperFormatKeybind(strArg)
	return strArg == Apollo.GetString("Keybinding_Unbound") and "" or strArg
end

function Keybind:PopulateKeybindList()
    -- go thru all the key bindings and display the key binding items in the keybind list
	self.tItems = {}

	self:SetState(LuaEnumKeybindingState.Idle)

	local arActionCategories = GameLib.GetInputActionCategories()
	table.sort(arActionCategories, function(a,b)
		if a.nCategoryId == 3 then -- Movement forced to the top
			return true
		elseif b.nCategoryId == 3 then
			return false
		end
		return a.strName < b.strName
	end)
	self.nCategoryCount = #arActionCategories

	table.sort(self.arKeyBindings, function(a,b)
		if a.nDisplayIndex == b.nDisplayIndex then
			return a.idAction < b.idAction
		end
		return a.nDisplayIndex < b.nDisplayIndex
	end)

	for iCategory = 1, self.nCategoryCount do
		self:AddCategory(arActionCategories[iCategory])
		for idx = 1,#self.arKeyBindings do
			if self.arKeyBindings[idx].idCategory == arActionCategories[iCategory].nCategoryId then
					self:AddKeyBinding(idx, self.arKeyBindings[idx])
				end
			end
		end

	-- align the items vertically
	self.tWndRefs.wndKeybindList:ArrangeChildrenVert()
end

---------------------------------------------------------------------------------------------------
-- message dialog
---------------------------------------------------------------------------------------------------
function Keybind:ShowMessage(strMessage)
	self:EnableBindingButtons(false)
	self:EnableSetButtons(false)

	if self.tWndRefs.wndOkForm:IsShown() then
		self.tMessageQueue:Push( strMessage )
	else
		self.tWndRefs.wndOkForm:FindChild("MessageText"):SetText(strMessage)
		self.tWndRefs.wndOkForm:Show(true)
	end
end

function Keybind:OnOkFormOk(wndHandler, wndControl, eMouseButton)
	if self.tMessageQueue:GetSize() == 0 then -- no more messages
		self:EnableBindingButtons(true)
		self:EnableSetButtons(true)
		self.tWndRefs.wndOkForm:Show(false)
	else
		local strMessage = self.tMessageQueue:Pop()
		self.tWndRefs.wndOkForm:FindChild("MessageText"):SetText(strMessage)
	end
end

---------------------------------------------------------------------------------------------------
-- Yes no dialog
---------------------------------------------------------------------------------------------------
function Keybind:ShowYesNoDialog(strMsg, fnContinue, oContinue, fnYes, oYes, fnNo, oNo)
    self.oContinue = oContinue
    self.fnContinue = fnContinue
    self.oContinue = oContinue
    self.fnYes = fnYes
    self.oYes = oYes
    self.fnNo = fnNo
    self.oNo = oNo
    self.bShowingYesNoDialog = true
    self.tWndRefs.wndYesNoForm:Show(true)
	self.tWndRefs.wndYesNoFormYesBtn:Show(true)
	self.tWndRefs.wndYesNoFormSaveBtn:Show(false)
    self.tWndRefs.wndYesNoForm:FindChild("QuestionText"):SetText(strMsg)
	self:ShowBindingInterface(false)
    self:EnableBindingButtons(false)
    self:EnableSetButtons(false)
    self.tWndRefs.wndSetSave:Enable(false)
	self.tWndRefs.wndSetCancel:Enable(false)
	self:ShowUndoUnbindMessage(false)
end
function Keybind:ExitYesNoDialog(bYesNo)
    self.bShowingYesNoDialog = false
    self:SetState(self.eState) -- update enable/disable windows
    self.tWndRefs.wndYesNoForm:Show(false)
    self.tWndRefs.wndSetSave:Enable(true)
	self.tWndRefs.wndSetCancel:Enable(true)
    if bYesNo == true then
        if self.fnYes ~= nil then
            self:fnYes(self.oYes)
        end
    else
        if self.fnNo ~= nil then
            self:fcnNo(self.oNo)
        end
    end
    if self.fnContinue ~= nil then
        self:fnContinue(self.oContinue)
    end
    self.wndBeforeYesNoDialog = nil
    self.fnContinue = nil
    self.fnYes = nil
    self.fnNo = nil
end
function Keybind:OnEscapeYesNoDialog()
    self:ExitYesNoDialog(false)
end
function Keybind:OnYesNoFormYes()
    if self.bShowingYesNoDialog then
        self:ExitYesNoDialog(true)
        return
    end
end
function Keybind:OnYesNoFormNo()
    if self.bShowingYesNoDialog then
        self:ExitYesNoDialog(false)
        return
    end
    self.tWndRefs.wndYesNoForm:Show(false)
end

---------------------------------------------------------------------------------------------------
-- Confirm save dialog
---------------------------------------------------------------------------------------------------
function Keybind:ShowConfirmSaveDialog(fnContinue, oContinue)
	self:ShowYesNoDialog(Apollo.GetString("CRB_Would_you_like_to_save_the_current_s"), fnContinue, oContinue, self.SetSaved)
	self.tWndRefs.wndYesNoFormSaveBtn:Show(true)
	self.tWndRefs.wndYesNoFormYesBtn:Show(false)
end
---------------------------------------------------------------------------------------------------
-- Select set
---------------------------------------------------------------------------------------------------

function Keybind:OnToggleSetSelect() --this opens the set-selection dialog
	self:ShowUndoUnbindMessage(false)
	if self.tWndRefs.wndSetSelection:IsVisible() then
		self:SetState(LuaEnumKeybindingState.Idle)
		self.tWndRefs.wndSetSelection:Show(false)
	else
	    self:SetState(LuaEnumKeybindingState.SelectingSet)
	    self.tWndRefs.wndSetSelection:Show(true)
	    self.tWndRefs.wndSetSelectionBtn:Enable(true)
	end
end

function Keybind:OnSetSelected(wndHandler, wndControl) --this function covers the buttons used in picking a set(ShortcutSet radio group)

    if wndHandler ~= wndControl then
        return
    end

	self:ShowUndoUnbindMessage(false)

    self:OnToggleSetSelect()

    if self.bNeedSave then
        self:ShowConfirmSaveDialog(self.ContinueSetSelected, wndControl)
    else
        self:ContinueSetSelected(wndControl)
    end
end

function Keybind:ContinueSetSelected(wndControl)

    local eCurrKeySet = wndControl:GetData()

    if self.eCurrKeySet ~= eCurrKeySet then
        self.eCurrKeySet = eCurrKeySet
        local bCompleted = GameLib.SetCurrInputKeySet(self.eCurrKeySet) -- SetCurrInputKeySet return FALSE if still need to wait for server to send client the keybindings
                                                                          -- when client received the keybinding from server, it will trigger the KeyBindingUpdated event
        self.tWndRefs.wndSetSelectionBtn:SetText(self.arKeySetNames[self.eCurrKeySet])

        self:InitializeVariables()
        self.bNeedSaveSet = true
	    if bCompleted then -- if not completed, then delay refresh until receiving a KeyBindingUpdated event
	        self.arKeyBindings = GameLib.GetKeyBindings()
			self:SetActionDataToSaveConfirmButtons()
            self:PopulateKeybindList() -- refresh list
        end
    end
end

function Keybind:OnEscapeSetSelect()
    self:SetState(LuaEnumKeybindingState.Idle)
end

function Keybind:OnEscapeSelectModifier( wndHandler, wndControl )
	self.timerModifierSelectionDelay:Start()
end

function Keybind:OnExitModifierTimer()
	self:SetState(LuaEnumKeybindingState.Idle)
end

---------------------------------------------------------------------------------------------------
-- Helper functions
---------------------------------------------------------------------------------------------------

-- enable all set select/save/cancel/copy buttons
function Keybind:EnableSetButtons(bEnable)
	self.tWndRefs.wndSetSelectionBtn:Enable(bEnable)
	self.tWndRefs.wndRestoreDefaultsBtn:Enable(bEnable)
end

-- enable binding buttons
function Keybind:EnableBindingButtons(bEnable)
    self.tWndRefs.wndKeybindList:Enable(bEnable)
	self.tWndRefs.wndCollapseAllBtn:Enable(bEnable) 
end

function Keybind:IsBindingEnabled()
	return self.tWndRefs.wndKeybindList:IsEnabled()
end

-- enable save/cancel buttons
function Keybind:EnableSaveCancelButtons(bEnable)
   self.tWndRefs.wndSetSave:Enable(bEnable)
   self.tWndRefs.wndSetCancel:Enable(bEnable)
end

-- set state and show/hide buttons according to the state
function Keybind:SetState(eState)

    self.eState = eState

    if eState ~= LuaEnumKeybindingState.AcceptingInput and self.wndCurrBind ~= nil then
        -- make sure the selected key button is unchecked
        self.wndCurrBind:SetCheck(false)
		self.wndCurrBind = nil
    end

	if eState ~= LuaEnumKeybindingState.AcceptingModifierInput and self.wndCurrModifierBind ~= nil then
        -- make sure the select modifier dropdown is unchecked
        self.wndCurrModifierBind:SetCheck(false)
		self.wndCurrModifierBind = nil
    end

	if eState == LuaEnumKeybindingState.Idle then
        self:ShowBindingInterface(false)
        self:EnableBindingButtons(true)
        self:EnableSetButtons(true)
		self:EnableSaveCancelButtons(true)
    elseif eState == LuaEnumKeybindingState.AcceptingInput or eState == LuaEnumKeybindingState.AcceptingModifierInput then
		self:EnableBindingButtons(true)
        self:ShowBindingInterface(true)
        self:EnableSetButtons(true)
		self:EnableSaveCancelButtons(true)
    elseif eState == LuaEnumKeybindingState.SelectingSet then
        self:ShowBindingInterface(false)
        self:EnableBindingButtons(false)
		self:EnableSaveCancelButtons(true)
	else
        Print( Apollo.GetString("CRB_ERROR_KeybindSetState__unhandled_sta") )
    end

end

---------------------------------------------------------------------------------------------------
-- Binding Interface
---------------------------------------------------------------------------------------------------

function Keybind:IsBindingModifierKey(iBinding)
	return self.wndCurrBind ~= nil and self.arKeyBindings[iBinding].strAction == "SprintModifier"
end

function Keybind:IsCurrBindingModifierKey()
	return self.eState == LuaEnumKeybindingState.AcceptingModifierInput
end

-- show binding interface - buttons to unbind/cancel
function Keybind:ShowBindingInterface(bShow)
	local bShowSelectModifier = bShow
	local bShowSelectBinding = bShow

	if bShow then
		bShowSelectModifier = self:IsCurrBindingModifierKey()
		bShowSelectBinding = not bShowSelectModifier
		self:ShowUndoUnbindMessage(false)
	end

	if bShowSelectModifier then
		-- reset the buttons to be unchecked for the select modifier window
		self.tWndRefs.wndModifierSelection:FindChild("Shift"):SetCheck(false)
		self.tWndRefs.wndModifierSelection:FindChild("Ctrl"):SetCheck(false)
		self.tWndRefs.wndModifierSelection:FindChild("Alt"):SetCheck(false)

		-- set the position of the modifier selection window to be below the modifier dropdown button
		local nLeft, nTop, nRight, nBottom = self.wndModifierDropdown:GetRect()
		local nLeftP1, nTopP1, nRightP1, nBottomP1 = self.wndModifierDropdown:GetParent():GetRect()
		local nLeftP2, nTopP2, nRightP2, nBottomP2 = self.wndModifierDropdown:GetParent():GetParent():GetRect()
		local nLeftSelect, nTopSelect, nRightSelect, nBottomSelect = self.tWndRefs.wndModifierSelection:GetRect()
		local nWidthSelect = nRightSelect - nLeftSelect
		local nHeightSelect = nBottomSelect - nTopSelect

		-- get the rect of dropdown button relative to the parent of the select window
		nLeft = nLeft + nLeftP1 + nLeftP2
		nTop = nTop + nTopP1 + nTopP2
		nRight = nRight + nLeftP1 + nLeftP2
		nBottom = nBottom + nTopP1 + nTopP2

		-- move the selection window to be right below the dropdown button
		self.tWndRefs.wndModifierSelection:Move( nLeft + ((nRight - nLeft-nWidthSelect) / 2), nBottom + 2, nWidthSelect, nHeightSelect )


	end
	
	if self.tWndRefs.wndModifierSelection then
		self.tWndRefs.wndModifierSelection:Show(bShowSelectModifier)
		self:EnableBindingButtons(not bShowSelectModifier) -- disable keybind list if picking modifier
		self.tWndRefs.wndBindUnbind:Show(bShowSelectBinding)
		self.tWndRefs.wndBindCancel:Show(bShowSelectBinding)
		self.tWndRefs.wndDefaultBtn:Show(bShowSelectBinding)
		if bShowSelectBinding then
		    self.tWndRefs.wndFeedback:SetText(String_GetWeaselString(Apollo.GetString("Keybinding_PickKey"), self.arKeyBindings[self.wndCurrBind:GetParent():GetData()].strActionLocalized ))
		else
		    self.tWndRefs.wndFeedback:SetText("")
		end
	end
end

function Keybind:OnRestoreDefaults( wndHandler, wndControl, eMouseButton )
	self:ShowYesNoDialog(Apollo.GetString("CRB_This_will_replace_all_keybinds"), nil, nil, self.RestoreDefaults, nil, nil)
end

function Keybind:RestoreDefaults()
	self:ShowUndoUnbindMessage(false)

	-- overwrite the key set
	self.arKeyBindings = GameLib.GetInputKeySet(GameLib.CodeEnumInputSets.Default1)
	self:SetActionDataToSaveConfirmButtons()

	self:PopulateKeybindList() -- refresh list
   	self:InitializeVariables()
	self.bNeedSave = true

end

---------------------------------------------------------------------------------------------------
-- Keybinding Functions
---------------------------------------------------------------------------------------------------
function Keybind:ShowUndoUnbindMessage(bShow, strOptionalMessage, bAppendMsg)
-- show a message at the bottom of the dialog for undoing the unbind action just done
-- if strOptionalMessageis nil, then display the default message
-- else show strMessage
-- unless bAppendMsg is true. both default message and strOptionalMessagewill be shown in this case

	if not bShow or self.iUndoUnbindKeybind == nil or self.iUndoKeybind == nil then
		self.tWndRefs.wndDuplicateMsg:Show(false)
		self.tWndRefs.wndUndoUnbind:Show(false)
		self.iUndoUnbindKeybind = nil
		self.iUndoKeybind = nil
		return
	end

	local strTextToBeShown
	if strOptionalMessage== nil or bAppendMsg then
	 	strTextToBeShown = String_GetWeaselString(Apollo.GetString("Keybinding_UnmappedDuplicate"), self.arKeyBindings[self.iUndoUnbindKeybind].strActionLocalized )
	else
		strTextToBeShown = strOptionalMessage
	end

	if bAppendMsg then
		strTextToBeShown = strTextToBeShown .. "\n" .. strOptionalMessage
	end

	self.tWndRefs.wndDuplicateMsg:SetText(strTextToBeShown)
	self.tWndRefs.wndDuplicateMsg:Show(true)
	self.tWndRefs.wndUndoUnbind:Show(true)
end

function Keybind:OnUndoUnbind( wndHandler, wndControl, eMouseButton )

	-- undo the keybind
	-- assign the key back to the unmapped key
	self.arKeyBindings[self.iUndoUnbindKeybind].arInputs[self.iUndoUnbindSlot] = TableUtil:Copy( self.arKeyBindings[self.iUndoKeybind].arInputs[self.iUndoSlot] )
	local wndUpdate = self.tItems[ self.arKeyBindings[self.iUndoUnbindKeybind].idAction ]
	local tNewInput = self.arKeyBindings[self.iUndoUnbindKeybind].arInputs[self.iUndoUnbindSlot]
	if wndUpdate then
		local wndBindButton = wndUpdate:FindChild("BindButton".. self.iUndoUnbindSlot)
		wndBindButton:SetText(self:HelperFormatKeybind(GameLib.GetInputKeyNameText(tNewInput)))
	end

	-- assign the old key back to the newly mapped key
	self.arKeyBindings[self.iUndoKeybind].arInputs[self.iUndoSlot] = TableUtil:Copy( self.tUndoInput )
	wndUpdate  = self.tItems[ self.arKeyBindings[self.iUndoKeybind].idAction ]
	tNewInput = self.tUndoInput
	if wndUpdate then
		local wndBindButton = wndUpdate:FindChild("BindButton".. self.iUndoSlot)
		wndBindButton:SetText(self:HelperFormatKeybind(GameLib.GetInputKeyNameText(tNewInput)))
	end
	
	self:SetActionDataToSaveConfirmButtons()
	self:ShowUndoUnbindMessage(false)

end

function Keybind:OverwriteDuplicates(iKeybind, tInput)
	self.iUndoUnbindKeybind = nil -- the keybind that's being overwritten/unbound
	self.iUndoUnbindSlot = nil -- the slot of the keybind that being unbound
	
	local tBindingIndexes = self:GetSiblingIndexs(self.iUndoSlot)
	
    for idx = 1,#self.arKeyBindings do
		if self.arKeyBindings[iKeybind].iInputKeyLookupGroup == self.arKeyBindings[idx].iInputKeyLookupGroup then
			for _, iBinding in pairs(tBindingIndexes) do
                if self.arKeyBindings[idx].arInputs[iBinding].eDevice ~= GameLib.CodeEnumInputDevice.None and
				   self.arKeyBindings[idx].arInputs[iBinding].nCode == tInput.nCode and
				   self.arKeyBindings[idx].arInputs[iBinding].eDevice == tInput.eDevice and
				   self.arKeyBindings[idx].arInputs[iBinding].eModifier == tInput.eModifier
                then
					-- keep track of what is unmapped so that user can undo
					self.iUndoUnbindKeybind = idx
					self.iUndoUnbindSlot = iBinding

					-- unmap the duplicate
					local wndDuplicate = self.tItems[self.arKeyBindings[idx].idAction]
					if wndDuplicate then
						local wndBindButton = wndDuplicate:FindChild("BindButton"..iBinding)
						if wndBindButton then
							wndBindButton:SetText(self:HelperFormatKeybind(GameLib.GetInputKeyNameText({eDevice = GameLib.CodeEnumInputDevice.None})))
						end
					end
					self.arKeyBindings[idx].arInputs[iBinding] = {eDevice = GameLib.CodeEnumInputDevice.None}

					if self:DoesUnbindKeyBreakBreakoutGameplay(idx, iBinding) then
						-- "You've unmapped blah blah blah. Warning: This key is used in breakout gameplay" [undo]
						self:ShowUndoUnbindMessage(true, Apollo.GetString("Keybinding_UnbindStrafeWarning"), true )
					else
						-- "You've unmapped blah blah blah" [undo]
						self:ShowUndoUnbindMessage(true)
					end
                end
            end
		end
    end
end

function Keybind:DoesUnbindKeyBreakBreakoutGameplay(iKeyBind, iSlot)
	return
		-- StunBreakout up down left or right
		(self.arKeyBindings[iKeyBind].idAction == GameLib.CodeEnumInputAction.StunBreakoutUp or
	   	self.arKeyBindings[iKeyBind].idAction == GameLib.CodeEnumInputAction.StunBreakoutDown or
	   	self.arKeyBindings[iKeyBind].idAction == GameLib.CodeEnumInputAction.StunBreakoutLeft or
	   	self.arKeyBindings[iKeyBind].idAction == GameLib.CodeEnumInputAction.StunBreakoutRight)
			and
		-- and both binding slots are going to be unbound
		(( iSlot== 2 and self.arKeyBindings[iKeyBind].arInputs[1].eDevice == GameLib.CodeEnumInputDevice.None ) or
		  (iSlot== 1 and self.arKeyBindings[iKeyBind].arInputs[2].eDevice == GameLib.CodeEnumInputDevice.None ) )
end

function Keybind:OnCancelBind()
    -- back to idle state
	self:SetState(LuaEnumKeybindingState.Idle)
	return true
end

function Keybind:GetModifierFlag(nModifierScancode)
	if nModifierScancode == GameLib.CodeEnumInputModifierScancode.LeftShift then
		return GameLib.CodeEnumInputModifier.Shift
	elseif nModifierScancode == GameLib.CodeEnumInputModifierScancode.LeftCtrl then
		return GameLib.CodeEnumInputModifier.Control
	elseif nModifierScancode == GameLib.CodeEnumInputModifierScancode.LeftAlt then
		return GameLib.CodeEnumInputModifier.Alt
	else
		return 0
	end
end

function Keybind:GetModifierString(nModifierScancode)
	if nModifierScancode == GameLib.CodeEnumInputModifierScancode.LeftShift then
		return Apollo.GetString("Keybinding_ShiftMod")
	elseif nModifierScancode == GameLib.CodeEnumInputModifierScancode.LeftCtrl then
		return Apollo.GetString("Keybinding_CtrlMod")
	elseif nModifierScancode == GameLib.CodeEnumInputModifierScancode.LeftAlt then
		return Apollo.GetString("Keybinding_AltMod")
	else
		return ""
	end
end

function Keybind:GetSiblingIndexs(iCurrentInput)
	if iCurrentInput == 1 then
		return { 1, 2, 3 }
	elseif iCurrentInput == 2 then
		return { 1, 2 }
	elseif iCurrentInput == 3 then
		return { 1, 3 }
	end
end

function Keybind:OnKeyDown(wndHandler, wndControl, strKeyName, nCode, eModifier)

    if wndHandler ~= wndControl then
		return false
	end

	-- ignore shift ctrl and alt because they are used as modifiers
	if not GameLib.IsKeyBindable(nCode, eModifier) then
		return false
	end

	if not self.wndCurrBind or not self:IsBindingEnabled() then
		return false
	end

	local iKeybind = self.wndCurrBind:GetParent():GetData()
	local iCurrentInput = self.wndCurrBind:GetData()
	-- ignore if it's the same as its sibling input

    if self.eState == LuaEnumKeybindingState.AcceptingInput then
		
		-- error out if using the modifier that is assigned to sprint
		local nModifierFlag = self:GetModifierFlag(self.nReservedModifier)
		if bit32.band(eModifier, nModifierFlag) > 0 then -- player is trying to bind a key with the reserved modifier flag
			self:ShowMessage(String_GetWeaselString(Apollo.GetString("Keybinding_ReservedForSprint"), self:GetModifierString(self.nReservedModifier)))
			return false
		end

		local tBindingIndexes = self:GetSiblingIndexs(iCurrentInput)
		for idx, iSiblingInput in pairs(tBindingIndexes) do
			if iCurrentInput ~= iSiblingInput then
				self:ClearSprintIfModifier(iKeybind, iCurrentInput, iSiblingInput)
			end
		end

        -- set the currently selected input binding
        local tCurrInput = {}
		tCurrInput.eDevice = GameLib.CodeEnumInputDevice.Keyboard
        tCurrInput.nCode = nCode
		if not self:IsSprintAction(self.arKeyBindings[iKeybind]) then
	        tCurrInput.eModifier = eModifier
		else
			tCurrInput.eModifier = 0
		end

	    -- set the binding
	    self:AcceptCurrInput(iKeybind, tCurrInput)

	    self:SetState(LuaEnumKeybindingState.Idle)

		return true;
    end
end

function Keybind:OnWindowMouseWheel(wndHandler, wndControl, nX, nY, nDelta, eModifier)
	self:OnMouseWheel(nX, nY, nDelta, eModifier)
end

function Keybind:OnMouseWheel(nX, nY, nDelta, eModifier)
    -- only process the wheel signal when accepting input
    if self.eState == LuaEnumKeybindingState.AcceptingInput then

		if not self:IsBindingEnabled() then
			return false
		end
		
        local nCode = GameLib.CodeEnumInputMouse.WheelUp
        if  nDelta < 0 then
            nCode = GameLib.CodeEnumInputMouse.WheelDown
        end

		-- error out if using the modifier that is assigned to sprint
		local nModifierFlag = self:GetModifierFlag(self.nReservedModifier)
		if bit32.band(eModifier, nModifierFlag) > 0 then -- player is trying to bind a key with the reserved modifier flag
			self:ShowMessage(String_GetWeaselString(Apollo.GetString("Keybinding_ReservedForSprint"), self:GetModifierString(self.nReservedModifier)))
			return false
		end

		local iKeybind = self.wndCurrBind:GetParent():GetData()
		local iCurrentInput = self.wndCurrBind:GetData()

        -- assign the new binding
		local tCurrInput = {}
        tCurrInput.eDevice = GameLib.CodeEnumInputDevice.Mouse
        tCurrInput.nCode = nCode
        tCurrInput.eModifier = eModifier

		self:ClearSprintIfModifier(iKeybind)

	    -- set the binding
	    self:AcceptCurrInput(iKeybind, tCurrInput)

	    self:SetState(LuaEnumKeybindingState.Idle)

		return true;
    end

    return false
end

function Keybind:OnWindowMouseButtonUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	self:OnMouseButtonUp( eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
end

function Keybind:OnMouseButtonUp( eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	-- capturing mouse input change
	if self.eState == LuaEnumKeybindingState.AcceptingInput then
		if Apollo.GetMouseTargetWindow() ~= self.wndCurrBind or not self:IsBindingEnabled()then
             return false
        end

		-- error out if using the modifier that is assigned to sprint
		local nModifierFlag = self:GetModifierFlag(self.nReservedModifier)
		local eModifier = Apollo.GetMetaKeysDown()
		if bit32.band(eModifier, nModifierFlag) > 0 then -- player is trying to bind a key with the reserved modifier flag
			self:ShowMessage(String_GetWeaselString(Apollo.GetString("Keybinding_ReservedForSprint"), self:GetModifierString(self.nReservedModifier)))
			return false
		end

		local iKeybind = self.wndCurrBind:GetParent():GetData()
		local iCurrentInput = self.wndCurrBind:GetData()
		if iCurrentInput ~= 3 and (eMouseButton == GameLib.CodeEnumInputMouse.Left or eMouseButton == GameLib.CodeEnumInputMouse.Right) then
			return false
		end

		self:ClearSprintIfModifier(iKeybind, self.wndCurrBind:GetData(), iSiblingInput)

        -- this button is already selected -- accepting mouse input
        -- set the currently selected input binding
        local tCurrInput = {}
		tCurrInput.eDevice = GameLib.CodeEnumInputDevice.Mouse
        tCurrInput.nCode = eMouseButton
        tCurrInput.eModifier = eModifier
	    -- set the binding
	    self:AcceptCurrInput(iKeybind, tCurrInput)
	    self:SetState(LuaEnumKeybindingState.Idle)
		return true;
	end

end

function Keybind:AcceptCurrInput(iKeybind, tCurrInput)

	self.iUndoKeybind = iKeybind -- keep track of the keybind just got changed (in case of undoing unmapping due to duplicate)
	self.tUndoInput = TableUtil:Copy(self.arKeyBindings[iKeybind].arInputs[self.wndCurrBind:GetData()]) -- undo input = input before changes
	self.iUndoSlot = self.wndCurrBind:GetData() -- the slot being changed

	if self.tUndoInput.eDevice ~= GameLib.CodeEnumInputDevice.None and tCurrInput.eDevice == GameLib.CodeEnumInputDevice.None then
		self.iUndoUnbindKeybind = iKeybind
		self.iUndoUnbindSlot = self.wndCurrBind:GetData()

		if self:DoesUnbindKeyBreakBreakoutGameplay(iKeybind, self.iUndoSlot) then
			self:ShowUndoUnbindMessage(true, Apollo.GetString("Keybinding_UnbindStrafeWarning") )
		end
	else
		-- if there are any duplicates, save over them
		self:OverwriteDuplicates(iKeybind, tCurrInput)
	end

	self.bNeedSave = true
    self.wndCurrBind:SetCheck(false)
    self.arKeyBindings[iKeybind].arInputs[self.wndCurrBind:GetData()] = TableUtil:Copy(tCurrInput)
    self.wndCurrBind:SetText(self:HelperFormatKeybind(GameLib.GetInputKeyNameText(tCurrInput)))

	self:SetActionDataToSaveConfirmButtons()
end

function Keybind:OnClick( wndHandler, wndControl )
    if self.bShowingYesNoDialog then
        return -- ignore everything
    end
    if self.eState == LuaEnumKeybindingState.AcceptingInput or self.eState == LuaEnumKeybindingState.AcceptingModifierInput then
		self:SetState(LuaEnumKeybindingState.Idle)
    elseif self.eState == LuaEnumKeybindingState.SelectingSet then
        self:OnToggleSetSelect() --cancel set select
    end
end

function Keybind:OnBindButton(wndHandler, wndControl, eMouseButton)

	if wndHandler ~= wndControl then
		return false
	end

	if self.wndCurrBind == wndControl then
		self.wndCurrBind:SetCheck(true)
		return true
	end

	-- if current key set is the preset default set, then disable editing
    if not GameLib.CanEditKeySet(self.eCurrKeySet) then
        self.tWndRefs.wndFeedback:SetText(Apollo.GetString("CRB_Default_key_sets_cannot_be_edited"))
        return false
    end

	if self.eState == LuaEnumKeybindingState.Idle and eMouseButton ~= GameLib.CodeEnumInputMouse.Left then
	    -- selecting mode - only accept left mouse click
        return false
	end

	-- capturing mouse input change
	if self.eState == LuaEnumKeybindingState.AcceptingInput and self.wndCurrBind == wndControl then
		return false
	end

	-- set up for binding for the selected
	if self.wndCurrBind ~= nil then
		self.wndCurrBind:SetCheck(false)
	end

	self.wndCurrBind = wndControl
	self.wndCurrBind:SetCheck(true)

	self:SetState(LuaEnumKeybindingState.AcceptingInput)

	wndControl:SetFocus()

end

function Keybind:OnUnbindButton()
    if self.eState == LuaEnumKeybindingState.AcceptingInput then
        -- set the currently selected input binding
        local tCurrInput = {}
		tCurrInput.eDevice = GameLib.CodeEnumInputDevice.None
        tCurrInput.nCode = 0
        tCurrInput.eModifier = 0

	    -- set the binding
	    self:AcceptCurrInput(self.wndCurrBind:GetParent():GetData(), tCurrInput)

	    self:SetState(LuaEnumKeybindingState.Idle)
	end
end

function Keybind:OnDefaultButton(wndHandler, wndControl, eMouseButton)
	if self.eState == LuaEnumKeybindingState.AcceptingInput then
		local arDefaultKeyBindings = GameLib.GetInputKeySet(GameLib.CodeEnumInputSets.Default1)
		local nCurrentBindingIdx = self.wndCurrBind:GetParent():GetData()
		
		-- map current index to default index
		local nNewBindingIdx = nil
		for idx, tBinding in pairs(arDefaultKeyBindings) do
			if tBinding.idAction == self.arKeyBindings[nCurrentBindingIdx].idAction then
				nNewBindingIdx = idx
				break
			end
		end

	    -- set the binding
		if nNewBindingIdx ~= nil then
		    self:AcceptCurrInput(nCurrentBindingIdx, arDefaultKeyBindings[nNewBindingIdx].arInputs[self.wndCurrBind:GetData()])
		    self:SetState(LuaEnumKeybindingState.Idle)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Applying Changes
---------------------------------------------------------------------------------------------------
function Keybind:SetSaved()
	self.eOriginalKeySet = self.eCurrKeySet
	self.bNeedSaveSet = false
	self.bNeedSave = false
end

function Keybind:OnSaveBtn() --the bottom "Save" button (ActionConfirmButton)
	self:SetSaved()
	self.tWndRefs.wndKeybindForm:Close()
end

function Keybind:OnCancelBtn() --the bottom "Cancel" button

    if self.bShowingYesNoDialog then
        return
    end

    if self.bNeedSave or self.bNeedSaveSet then
       self:ShowConfirmSaveDialog(self.OnClose, nil)
    else
       self.tWndRefs.wndKeybindForm:Close()
    end

end

function Keybind:OnClose()
	if self.tWndRefs.wndKeybindForm ~= nil and self.tWndRefs.wndKeybindForm:IsValid() then
    GameLib.PauseGameActionInput(false)
    self.wndCurrBind = nil
	self.wndCurrModifierBind = nil
    self.eState = LuaEnumKeybindingState.Idle

	    self.arKeyBindings = {}
		self.arKeySetBtns = {}
		self.arKeySetNames = {}
	self.tItems = {}
		self.tWindowCache = {}
		self.tCollapsedCategories = {}

		self.tWndRefs.wndKeybindForm:Close()
		if self.tWndRefs.wndKeybindForm ~= nil then
			self.tWndRefs.wndKeybindForm:Destroy()
		end
		self.tWndRefs = {}

    if self.eOriginalKeySet ~= self.eCurrKeySet then
        GameLib.SetCurrInputKeySet(self.eOriginalKeySet) -- revert back to original key set
    end

	Event_FireGenericEvent("KeybindInterfaceClosed") --The Options UI should listen for this and re-enable.
		Event_FireGenericEvent("WindowManagementRemove", {strName = Apollo.GetString("CRB_Keybindings")})
	end
end

---------------------------------------------------------------------------------------------------
-- KeybindModifierKeyItem Functions
---------------------------------------------------------------------------------------------------

function Keybind:OnModifierSelected(wndHandler, wndControl, eMouseButton)

	if wndHandler ~= wndControl then
		return false
	end

	if eMouseButton ~= GameLib.CodeEnumInputMouse.Left then
		return true
	end

	-- if nothing changed, then just return
	local nOldCode = self.nReservedModifier
	local nNewCode = wndControl:GetContentId()
	if nOldCode == nNewCode then
		self:SetState(LuaEnumKeybindingState.Idle)
		self.wndCurrModifierBind = nil
		return true
	end

	local tCurrInput = {}
	tCurrInput.eDevice = GameLib.CodeEnumInputDevice.Keyboard
    tCurrInput.nCode = nNewCode
    tCurrInput.eModifier = 0

	local tModifierSelectedState = {}
	tModifierSelectedState.tCurrInput = tCurrInput
	tModifierSelectedState.nOldCode = nOldCode
	tModifierSelectedState.nNewCode = nNewCode

	if self:IsModifierInUse(nNewCode) then
		if self:GetModifierFlag(nOldCode) == 0 then
			local strYesNoMsg = String_GetWeaselString(Apollo.GetString("Keybinding_ModifierCleared"), self:GetModifierString(nNewCode))
			self:ShowYesNoDialog(strYesNoMsg, nil, nil, self.FinalizeModifierSelected, tModifierSelectedState, nil, nil)
		else
			self:ShowMessage(String_GetWeaselString(Apollo.GetString("Keybinding_ModifierUpdated"), self:GetModifierString(nNewCode), self:GetModifierString(nOldCode)))
			self:FinalizeModifierSelected(tModifierSelectedState)
		end
	else
		self:FinalizeModifierSelected(tModifierSelectedState)
		self:SetState(LuaEnumKeybindingState.Idle)
	end
end

function Keybind:FinalizeModifierSelected(tModifierSelectedState)
	local tCurrInput = tModifierSelectedState.tCurrInput

	self.nReservedModifier = tModifierSelectedState.nNewCode

    self.bNeedSave = true

	-- update keybinding
	self.arKeyBindings[self.wndCurrModifierBind:GetParent():GetData()].arInputs[1] = TableUtil:Copy(tCurrInput)
	-- update keybinding2 to right shift/ctrl/alt
	if tCurrInput.nCode == GameLib.CodeEnumInputModifierScancode.LeftShift then
		tCurrInput.nCode = GameLib.CodeEnumInputModifierScancode.RightShift
	elseif tCurrInput.nCode == GameLib.CodeEnumInputModifierScancode.LeftCtrl then
		tCurrInput.nCode = GameLib.CodeEnumInputModifierScancode.RightCtrl
	elseif tCurrInput.nCode == GameLib.CodeEnumInputModifierScancode.LeftAlt then
		tCurrInput.nCode = GameLib.CodeEnumInputModifierScancode.RightAlt
	else -- error - unknown modifier chosen
		tCurrInput = {eDevice = GameLib.CodeEnumInputDevice.None}
	end
	self.arKeyBindings[self.wndCurrModifierBind:GetParent():GetData()].arInputs[2] = TableUtil:Copy(tCurrInput)

	self.wndCurrModifierBind:GetParent():FindChild("BindButton1"):SetText("") -- Apollo.GetString("Keybinding_Unbound"))

    -- update display
    self.wndCurrModifierBind:SetText(self:HelperFormatKeybind(GameLib.GetInputKeyNameText(tCurrInput)))

	-- go thru all the keybinds and convert any keybinding that use the new modifier as a modifier key to use the old modifier instead
	local nOldModifierFlag = self:GetModifierFlag(tModifierSelectedState.nOldCode)
	local nNewModifierFlag = self:GetModifierFlag(tModifierSelectedState.nNewCode)
	for idx = 1,#self.arKeyBindings do
    	for iBinding = 1, knKeybindColumnCount do
    		if self.arKeyBindings[idx].arInputs[iBinding].eDevice ~= GameLib.CodeEnumInputDevice.None and -- if new modifer is used
    			bit32.band(self.arKeyBindings[idx].arInputs[iBinding].eModifier, nNewModifierFlag) > 0
   			then -- change it to use old modifer instead
				local eModifier = self.arKeyBindings[idx].arInputs[iBinding].eModifier
	            -- remove the new modifier
				eModifier = bit32.band( eModifier, bit32.bnot(nNewModifierFlag))
			   	-- add the old modifier
				eModifier = bit32.bor(eModifier, nOldModifierFlag)

				-- make sure the new key is valid
				if not GameLib.IsKeyBindable( self.arKeyBindings[idx].arInputs[iBinding].nCode, eModifier ) then
					local tInvalidInput = TableUtil:Copy(self.arKeyBindings[idx].arInputs[iBinding])
					tInvalidInput.eModifier = eModifier
					self:ShowMessage(String_GetWeaselString(Apollo.GetString("Keybinding_UnbindInvalid"),self.arKeyBindings[idx].strActionLocalized, GameLib.GetInputKeyNameText(tInvalidInput)))
					eModifier = 0
				end

				-- assign & update the UI
				if eModifier == 0 then
					self.arKeyBindings[idx].arInputs[iBinding].eDevice = GameLib.CodeEnumInputDevice.None
					self.arKeyBindings[idx].arInputs[iBinding].nCode = 0
					self.arKeyBindings[idx].arInputs[iBinding].eModifier = 0
				else
					self.arKeyBindings[idx].arInputs[iBinding].eModifier = eModifier
				end

				local wndCurrBinding = self.tItems[self.arKeyBindings[idx].idAction]
				if wndCurrBinding then
					wndCurrBinding:FindChild("BindButton" .. iBinding):SetText(self:HelperFormatKeybind(GameLib.GetInputKeyNameText(self.arKeyBindings[idx].arInputs[iBinding])))
				end
			end
		end
	end
	
	self:SetActionDataToSaveConfirmButtons()
	self.tWndRefs.wndModifierSelection:Show(false)
	self:SetState(LuaEnumKeybindingState.Idle)
	return true
end

function Keybind:IsModifierInUse(newCode)

	local nNewModifierFlag = self:GetModifierFlag(newCode)

	for idx = 1,#self.arKeyBindings do
    	for iBinding = 1, knKeybindColumnCount do
    		if self.arKeyBindings[idx].arInputs[iBinding].eDevice ~= GameLib.CodeEnumInputDevice.None and
    			bit32.band(self.arKeyBindings[idx].arInputs[iBinding].eModifier, nNewModifierFlag) > 0
   			then
				return true
			end
		end
	end

	return false
end

function Keybind:OnModifierDropdownCheck(wndHandler, wndControl, eMouseButton)

	if wndHandler ~= wndControl or eMouseButton ~= GameLib.CodeEnumInputMouse.Left then
		return false
	end

	self.wndCurrModifierBind = wndControl
	self.wndCurrModifierBind:SetCheck(true)

	self:SetState(LuaEnumKeybindingState.AcceptingModifierInput)

	wndControl:SetFocus()
	return true

end

---------------------------------------------------------------------------------------------------
-- KeyboardCategoryItem Functions
---------------------------------------------------------------------------------------------------

function Keybind:OnCategoryClick(wndHandler, wndControl)
	if self.bCollapseAll then
		self.tWndRefs.wndCollapseAllBtn:SetText(Apollo.GetString("CRB_Collapse_All"))
		self.bCollapseAll = false
	end

	local id = wndHandler:GetData()
	if self.tCollapsedCategories[id] then
		self.tCollapsedCategories[id] = nil
		self.nCollapsedCount = self.nCollapsedCount - 1
	else
		self.tCollapsedCategories[id] = true
		self.nCollapsedCount = self.nCollapsedCount + 1
	end

	if self.nCollapsedCount == self.nCategoryCount then
		self.tWndRefs.wndCollapseAllBtn:SetText(Apollo.GetString("CRB_Expand_All"))
		self.bCollapseAll = true
	end

	self:PopulateKeybindList()

	self.tWndRefs.wndKeybindForm:EnsureChildVisible(wndControl)
end

function Keybind:OnToggleCategories(wndHandler, wndControl)
	if self.bCollapseAll then
		self.tWndRefs.wndCollapseAllBtn:SetText(Apollo.GetString("CRB_Collapse_All"))
		self.tCollapsedCategories = {}
		self.nCollapsedCount = 0
	else
		self.tWndRefs.wndCollapseAllBtn:SetText(Apollo.GetString("CRB_Expand_All"))

		local arActionCategories = GameLib.GetInputActionCategories()
		for iCategory = 1, self.nCategoryCount do
			self.tCollapsedCategories[arActionCategories[iCategory].nCategoryId] = true
		end

		self.nCollapsedCount = self.nCategoryCount
	end

	self.bCollapseAll = not self.bCollapseAll
	self:PopulateKeybindList()
end

---------------------------------------------------------------------------------------------------
-- Factory
---------------------------------------------------------------------------------------------------

function Keybind:FactoryCacheProduce(wndParent, strFormName, strKey)
	local wnd = self.tWindowCache[strKey]
	if not wnd or not wnd:IsValid() then
		wnd = Apollo.LoadForm(self.xmlDoc, strFormName, wndParent, self)
		self.tWindowCache[strKey] = wnd

		for strKey, wndCached in pairs(self.tWindowCache) do
		if not self.tWindowCache[strKey]:IsValid() then
				self.tWindowCache[strKey] = nil
			end
		end
	end

	return wnd
end

local KeybindInst = Keybind:new()
KeybindInst:Init()
