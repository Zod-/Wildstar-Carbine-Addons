-----------------------------------------------------------------------------------------------
-- Client Lua Script for Communities
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Apollo"
require "ChatSystemLib"
require "GuildLib"
require "GuildTypeLib"
require "ChatChannelLib"

local Communities = {}
local knMaxNumberOfCommunities = 5
local crGuildNameLengthError = ApolloColor.new("red")
local crGuildNameLengthGood = ApolloColor.new("UI_TextHoloBodyCyan")

function Communities:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	o.tWndRefs = {}

    return o
end

function Communities:Init()
    Apollo.RegisterAddon(self)
end

function Communities:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CommunitiesMain.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Communities:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	if tSavedData.bShowOffline then
		self.bShowOffline = tSavedData.bShowOffline
	end
end

function Communities:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("GenericEvent_InitializeCommunities",	"OnGenericEvent_InitializeCommunities", self)
	Apollo.RegisterEventHandler("GenericEvent_DestroyCommunities", 		"OnGenericEvent_DestroyCommunities", self)
	Apollo.RegisterEventHandler("GuildRoster", 						"OnGuildRoster", self)
	Apollo.RegisterEventHandler("GuildResult", 						"OnGuildResult", self)
	Apollo.RegisterEventHandler("GuildInfluenceAndMoney", 			"UpdateInfluenceAndMoney", self)
	Apollo.RegisterEventHandler("GuildMemberChange", 				"OnGuildMemberChange", self)  -- General purpose update method
	Apollo.RegisterEventHandler("GuildRankChange",					"OnGuildRankChange", self)
	Apollo.RegisterEventHandler("GuildInvite",						"OnCommunityInvite", self)
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate",		"OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate",			"OnEntitlementUpdate", self)

	Apollo.RegisterTimerHandler("CommunityAlertDisplayTimer", "OnCommunityAlertDisplayTimer", self)
	Apollo.RegisterTimerHandler("OfflineTimeUpdate", "OnOfflineTimeUpdate", self)
	
	Apollo.CreateTimer("OfflineTimeUpdate", 30.000, true)
	Apollo.StopTimer("OfflineTimeUpdate")
	
	Apollo.CreateTimer("CommunityAlertDisplayTimer", 3.0, false)
	Apollo.StopTimer("CommunityAlertDisplayTimer")
end

function Communities:OnGenericEvent_InitializeCommunities(wndParent, guildCurr)
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain = Apollo.LoadForm(self.xmlDoc, "CommunitiesMainForm", wndParent, self)
	end

	local wndRosterScreen = self.tWndRefs.wndMain:FindChild("RosterScreen")
	local wndRosterBottom = wndRosterScreen:FindChild("RosterBottom")
	wndRosterBottom:ArrangeChildrenHorz(2)
	wndRosterBottom:FindChild("RosterOptionBtnAdd"):AttachWindow(wndRosterBottom:FindChild("RosterOptionBtnAdd:AddMemberContainer"))
	wndRosterBottom:FindChild("RosterOptionBtnRemove"):AttachWindow(wndRosterBottom:FindChild("RosterOptionBtnRemove:RemoveMemberContainer"))
	
	local wndBtnEditNotes = self.tWndRefs.wndMain:FindChild("RosterOptionBtnEditNotes")
	wndBtnEditNotes:AttachWindow(wndBtnEditNotes:FindChild("EditNotesContainer"))
	
	local wndAdvancedOptions = self.tWndRefs.wndMain:FindChild("AdvancedOptionsContainer")
	self.tWndRefs.wndMain:FindChild("OptionsBtn"):AttachWindow(wndAdvancedOptions)
	wndAdvancedOptions:FindChild("ShowOffline"):SetCheck(self.bShowOffline)
	wndAdvancedOptions:FindChild("RosterOptionBtnLeave"):AttachWindow(wndAdvancedOptions:FindChild("RosterOptionBtnLeave:LeaveBtnContainer"))
	
	wndRosterScreen:FindChild("RankPopout:RankSettingsEntry:Name:OptionString"):SetMaxTextLength(GameLib.GetTextTypeMaxLength(GameLib.CodeEnumUserText.GuildRankName))
	
	self.bViewingRemovedGuild = false

	local wndPermissionContainer = wndRosterScreen:FindChild("RankPopout:RankSettingsEntry:Permissions:PermissionContainer")
	local arPermissionWindows = wndPermissionContainer:GetChildren()
	if not arPermissionWindows or #arPermissionWindows <= 0 then
		for idx, tPermission in pairs(GuildLib.GetPermissions(GuildLib.GuildType_Community)) do
			local wndPermission = Apollo.LoadForm(self.xmlDoc, "PermissionEntry", wndPermissionContainer, self)
			local wndPermissionBtn = wndPermission:FindChild("PermissionBtn")
			wndPermissionBtn:SetText(tPermission.strName)
			wndPermission:SetData(tPermission)
			
			if tPermission.strDescription ~= nil and tPermission.strDescription ~= "" then
				wndPermission:SetTooltip(tPermission.strDescription)
			end
		end
	end
	
	wndPermissionContainer:ArrangeChildrenVert()

	self.tWndRefs.wndRankPopout = wndRosterScreen:FindChild("RankPopout")

	local tEntitlementInfo = { nEntitlementId = AccountItemLib.CodeEnumEntitlement.Free }
	self:OnEntitlementUpdate(tEntitlementInfo)
	Apollo.StartTimer("OfflineTimeUpdate")
	self.tWndRefs.wndMain:SetData(guildCurr)
	self.tWndRefs.wndMain:Show(true)
	self:FullRedrawOfRoster()
end

function Communities:OnGenericEvent_DestroyCommunities()
	if self.tWndRefs.wndMain and self.tWndRefs.wndMain:IsValid() then
		self.tWndRefs.wndMain:Destroy()
		self.tWndRefs = {}
	end
end

function Communities:OnClose()
	Apollo.StopTimer("CommunityAlertDisplayTimer")
	Apollo.StopTimer("OfflineTimeUpdate")
	self.tWndRefs.wndMain:FindChild("AlertMessage"):Show(false)
end

-----------------------------------------------------------------------------------------------
-- Roster Methods
-----------------------------------------------------------------------------------------------

function Communities:FullRedrawOfRoster()
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() or not self.tWndRefs.wndMain:GetData() then
		return
	end

	local guildCurr = self.tWndRefs.wndMain:GetData()
	local eMyRank = guildCurr:GetMyRank()
	local wndRosterScreen = self.tWndRefs.wndMain:FindChild("RosterScreen")

	wndRosterScreen:Show(true)

	if wndRosterScreen and wndRosterScreen:FindChild("RosterBottom:RosterOptionBtnPromote:PromoteMemberContainer"):IsShown() then
		self:OnRosterPromoteMemberCloseBtn()
	end
	
	local wndRankPopout = wndRosterScreen:FindChild("RankPopout")
	local wndRankContainer = wndRankPopout:FindChild("RankContainer")
	wndRankContainer:DestroyChildren()

	local nCurrentRankCount = 1
	local arRanks = guildCurr:GetRanks()
	if arRanks then
		for idx, tRankInfo in ipairs(arRanks) do
			if tRankInfo.bValid then
				local wndRank = Apollo.LoadForm(self.xmlDoc, "RankEntry", wndRankContainer, self)
				wndRank:SetData({ nRankIdx = idx, tRankData = tRankInfo, bNew = false })
				wndRank:FindChild("Name:OptionString"):SetText(tRankInfo.strName)
				wndRank:FindChild("ModifyRankBtn"):Show(arRanks[eMyRank].bChangeRankPermissions)

				nCurrentRankCount = nCurrentRankCount + 1
			end

			if next(arRanks, idx) == nil and nCurrentRankCount < #arRanks and arRanks[eMyRank].bRankCreate then
				local wndRank = Apollo.LoadForm(self.xmlDoc, "AddRankEntry", wndRankContainer, self)
			end
		end
	end

	wndRankContainer:ArrangeChildrenVert()
	
	guildCurr:RequestMembers() -- This will send back an event "GuildRoster"
end

function Communities:OnGuildRoster(guildCurr, tRoster) -- Event from CPP
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() or not self.tWndRefs.wndMain:GetData() then
		return
	end
	
	if guildCurr == self.tWndRefs.wndMain:GetData() then -- Since Communities and Guild can be up at the same time
		self.tWndRefs.wndMain:FindChild("RosterScreen:RosterGrid"):DeleteAll()
		self:BuildRosterList(guildCurr, self:SortRoster(tRoster, "RosterSortBtnName")) -- "RosterSortBtnName" is the default sort method to use
	end

	self.tRoster = tRoster
end

function Communities:FillMemberRow(wndGrid, nRow, tRanks, tMember)
	local strIcon = "CRB_DEMO_WrapperSprites:btnDemo_CharInvisibleNormal"
	if tMember.nRank == 1 then -- Special icons for guild leader and council (TEMP Placeholder)
		strIcon = "CRB_Basekit:kitIcon_Holo_Profile"
	elseif tMember.nRank == 2 then
		strIcon = "CRB_Basekit:kitIcon_Holo_Actions"
	end

	local strRank = Apollo.GetString("Communities_UnknownRank")
	if tRanks[tMember.nRank] and tRanks[tMember.nRank].strName then
		strRank = tRanks[tMember.nRank].strName
	end

	local strTextColor = "UI_TextHoloBodyHighlight"
	if tMember.fLastOnline ~= 0 then -- offline
		strTextColor = "UI_BtnTextGrayNormal"
	end
			
	if not self.strPlayerName then
		self.strPlayerName = GameLib.GetPlayerUnit():GetName()
	end

	local wndNoteEditBox = self.tWndRefs.wndMain:FindChild("EditNotesEditbox")
	if self.strPlayerName == tMember.strName and not wndNoteEditBox:IsShown() then
		wndNoteEditBox:SetText(tMember.strNote)
	end
	
	wndGrid:SetCellImage(nRow, 1, strIcon)
	wndGrid:SetCellDoc(nRow, 2, string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strTextColor, tMember.strName))
	wndGrid:SetCellDoc(nRow, 3, string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strTextColor, strRank))
	wndGrid:SetCellDoc(nRow, 4, string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strTextColor, tMember.nLevel))
	wndGrid:SetCellDoc(nRow, 5, string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strTextColor, tMember.strClass))
	wndGrid:SetCellDoc(nRow, 6, string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strTextColor, self:HelperConvertToTime(tMember.fLastOnline)))
			
	wndGrid:SetCellDoc(nRow, 7, "<T Font=\"CRB_InterfaceSmall\" TextColor=\""..strTextColor.."\">".. FixXMLString(tMember.strNote) .."</T>")
	wndGrid:SetCellLuaData(nRow, 7, String_GetWeaselString(Apollo.GetString("GuildRoster_ActiveNoteTooltip"), tMember.strName, Apollo.StringLength(tMember.strNote) > 0 and tMember.strNote or "N/A")) -- For tooltip
	
	local tSelectedData = wndGrid:GetData()
	if tSelectedData ~= nil and tMember.strName == tSelectedData.strName then
		wndGrid:SetData(tMember)
	end
end

function Communities:BuildRosterList(guildCurr, tRoster)
	if not guildCurr or #tRoster == 0 then
		return
	end

	local tRanks = guildCurr:GetRanks()
	local wndGrid = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterGrid")
	wndGrid:DeleteAll() -- TODO remove this for better performance eventually

	for key, tCurr in pairs(tRoster) do
		if self.bShowOffline or tCurr.fLastOnline == 0 then
			local iCurrRow = wndGrid:AddRow("")
			wndGrid:SetCellLuaData(iCurrRow, 1, tCurr)
			self:FillMemberRow(wndGrid, iCurrRow, tRanks, tCurr)
		end
	end
	
	local wndAddContainer = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterBottom:RosterOptionBtnAdd:AddMemberContainer")
	local wndAddMemberEditBox = wndAddContainer:FindChild("AddMemberEditBox")
	wndAddContainer:FindChild("AddMemberYesBtn"):SetData(wndAddMemberEditBox)
	wndAddMemberEditBox:SetData(wndAddMemberEditBox) -- Since they have the same event handler
	self.tWndRefs.wndMain:FindChild("RosterScreen:RosterHeaderContainer"):SetData(tRoster)

	self:ResetRosterMemberButtons()
end

function Communities:OnRosterGridItemClick(wndControl, wndHandler, iRow, iCol, eMouseButton)
	local wndRosterGrid = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterGrid")
	local wndData = wndRosterGrid:GetCellData(iRow, 1)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and wndData and wndData.strName and wndData.strName ~= GameLib.GetPlayerUnit():GetName() then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayer", self.tWndRefs.wndMain, wndData.strName)
		return
	end

	if wndRosterGrid:GetData() == wndData then
		wndRosterGrid:SetData(nil)
		wndRosterGrid:SetCurrentRow(0) -- Deselect grid
	else
		wndRosterGrid:SetData(wndData)
	end

	self:ResetRosterMemberButtons()
end

-----------------------------------------------------------------------------------------------
-- Rank Methods
-----------------------------------------------------------------------------------------------

function Communities:OnRanksButtonSignal()
	local wndRankPopout = self.tWndRefs.wndMain:FindChild("RosterScreen:RankPopout")
	local wndRankContainer = wndRankPopout:FindChild("RankContainer")
	local wndRankSettings = wndRankPopout:FindChild("RankSettingsEntry")

	local bShow = not wndRankPopout:IsShown()

	wndRankPopout:Show(bShow)
	wndRankContainer:Show(bShow)
	wndRankSettings:Show(false)
	self.tWndRefs.wndMain:FindChild("AdvancedOptionsContainer"):Show(false)
end

function Communities:OnAddRankBtnSignal(wndControl, wndHandler)
	local wndRankPopout = self.tWndRefs.wndMain:FindChild("RosterScreen:RankPopout")
	local wndRankContainer = wndRankPopout:FindChild("RankContainer")
	local wndSettings = wndRankPopout:FindChild("RankSettingsEntry")
	local guildCurr = self.tWndRefs.wndMain:GetData()
	local arRanks = guildCurr:GetRanks()

	local tFirstInactiveRank = nil
	for idx, tRank in ipairs(arRanks) do
		if not tRank.bValid then
			tFirstInactiveRank = { nRankIdx = idx, tRankData = tRank, bNew = true }
			break
		end
	end

	if tFirstInactiveRank == nil then
		return
	end

	wndRankContainer:Show(false)
	wndSettings:Show(true)
	wndSettings:SetData(tFirstInactiveRank)

	--Default to nothing
	wndSettings:FindChild("Name:OptionString"):SetText("")
	local wndPermissionContainer = self.tWndRefs.wndMain:FindChild("RosterScreen:RankPopout:RankSettingsEntry:Permissions:PermissionContainer")
	for key, wndPermission in pairs(wndPermissionContainer:GetChildren()) do
		wndPermission:FindChild("PermissionBtn"):SetCheck(false)
	end

	--won't have members when creating
	wndSettings:FindChild("Delete"):Show(false)
	wndSettings:FindChild("MemberCount"):Show(false)
	
	self:HelperValidateAndRefreshRankSettingsWindow(wndSettings)
end

function Communities:OnViewRankBtnSignal(wndControl, wndHandler)
	local wndRankContainer = self.tWndRefs.wndRankPopout:FindChild("RankContainer")
	local wndSettings = self.tWndRefs.wndRankPopout:FindChild("RankSettingsEntry")
	local nRankIdx = wndControl:GetParent():GetData().nRankIdx
	local tRank = wndControl:GetParent():GetData().tRankData
	local guildCurr = self.tWndRefs.wndMain:GetData()
	local arRanks = guildCurr:GetRanks()
	local eMyRank = guildCurr:GetMyRank()

	wndRankContainer:Show(false)
	wndSettings:SetData(wndControl:GetParent():GetData())
	wndSettings:Show(true)

	wndSettings:FindChild("Name:OptionString"):SetText(tRank.strName)
	local wndPermissionContainer = wndSettings:FindChild("Permissions:PermissionContainer")
	for key, wndPermission in pairs(wndPermissionContainer:GetChildren()) do
		wndPermission:FindChild("PermissionBtn"):SetCheck(tRank[wndPermission:GetData().strLuaVariable])
	end

	local nRankMemberCount = 0
	local nRankMemberOnlineCount = 0
	for idx, tMember in ipairs(self.tRoster) do
		if tMember.nRank == nRankIdx then
			nRankMemberCount = nRankMemberCount + 1

			if tMember.fLastOnline == 0 then
				nRankMemberOnlineCount = nRankMemberOnlineCount + 1
			end
		end
	end

	local bCanDelete = arRanks[eMyRank].bRankCreate and nRankIdx ~= 1 and nRankIdx ~= 2 and nRankIdx ~= 10 and nRankMemberCount == 0
	wndSettings:FindChild("Permissions:PermissionContainerBlocker"):Show(nRankIdx == 1)

	wndSettings:FindChild("Delete"):Show(bCanDelete)
	wndSettings:FindChild("MemberCount"):Show(true)
	wndSettings:FindChild("MemberCount"):SetText(String_GetWeaselString(Apollo.GetString("Guild_MemberCount"), nRankMemberCount, nRankMemberOnlineCount))

	self:HelperValidateAndRefreshRankSettingsWindow(wndSettings)
end

function Communities:OnRankSettingsSaveBtn(wndControl, wndHandler)
	local wndRankPopout = self.tWndRefs.wndMain:FindChild("RosterScreen:RankPopout")
	local wndRankContainer = wndRankPopout:FindChild("RankContainer")
	local wndSettings = wndRankPopout:FindChild("RankSettingsEntry")
	local bNew = wndControl:GetParent():GetData().bNew
	local tRank = wndControl:GetParent():GetData().tRankData
	local nRankIdx = wndControl:GetParent():GetData().nRankIdx
	local guildCurr = self.tWndRefs.wndMain:GetData()

	wndRankPopout:FindChild("RankContainer"):Show(true)
	wndSettings:Show(false)

	local strName = wndSettings:FindChild("Name:OptionString"):GetText()
	if strName ~= tRank.strName then
		if bNew then
			guildCurr:AddRank(nRankIdx, strName)
		else
			guildCurr:RenameRank(nRankIdx, strName)
		end
		tRank.strName = strName
	end

	local bDirtyRank = false
	for key, wndPermission in pairs(wndSettings:FindChild("Permissions:PermissionContainer"):GetChildren()) do
		local bPermissionChecked = wndPermission:FindChild("PermissionBtn"):IsChecked()
		if tRank[wndPermission:GetData().strLuaVariable] ~= bPermissionChecked then
			bDirtyRank = true
		end

		tRank[wndPermission:GetData().strLuaVariable] = wndPermission:FindChild("PermissionBtn"):IsChecked()
	end

	if bDirtyRank then
		guildCurr:ModifyRank(nRankIdx, tRank)
	end

	wndControl:GetParent():SetData(tRank)
	--TODO update list display name for rank name
end

function Communities:OnRankSettingsDeleteBtn(wndControl, wndHandler)
	local wndRankPopout = self.tWndRefs.wndMain:FindChild("RosterScreen:RankPopout")
	local wndRankContainer = wndRankPopout:FindChild("RankContainer")
	local wndSettings = wndRankPopout:FindChild("RankSettingsEntry")

	local nRankIdx = wndSettings:GetData().nRankIdx
	local guildCurr = self.tWndRefs.wndMain:GetData()

	guildCurr:RemoveRank(nRankIdx)

	wndRankContainer:Show(true)
	wndSettings:Show(false)
end

function Communities:OnRankSettingsNameChanging(wndControl, wndHandler, strText)
	self:HelperValidateAndRefreshRankSettingsWindow(self.tWndRefs.wndRankPopout:FindChild("RankSettingsEntry"))
end

function Communities:OnRankSettingsPermissionBtn(wndControl, wndHandler)
	self:HelperValidateAndRefreshRankSettingsWindow(self.tWndRefs.wndRankPopout:FindChild("RankSettingsEntry"))
end

function Communities:HelperValidateAndRefreshRankSettingsWindow(wndSettings)
	local wndLimit = wndSettings:FindChild("Name:Limit")
	local tRank = wndSettings:GetData()
	local strName = wndSettings:FindChild("Name:OptionString"):GetText()

	if wndLimit ~= nil then
		local nNameLength = Apollo.StringLength(strName or "")

		wndLimit:SetText(String_GetWeaselString(Apollo.GetString("CRB_Progress"), nNameLength, GameLib.GetTextTypeMaxLength(GameLib.CodeEnumUserText.GuildRankName)))
		wndLimit:SetTextColor(nNameLength < 1 and crGuildNameLengthError or crGuildNameLengthGood)
	end

	local bNameValid = strName ~= nil and strName ~= "" and GameLib.IsTextValid(strName, GameLib.CodeEnumUserText.GuildRankName, GameLib.CodeEnumUserTextFilterClass.Strict)
	local bNameChanged = strName ~= tRank.strName

	local bPermissionChanged = false
	for key, wndPermission in pairs(wndSettings:FindChild("Permissions:PermissionContainer"):GetChildren()) do
		local bPermissionChecked = wndPermission:FindChild("PermissionBtn"):IsChecked()
		if tRank.tRankData[wndPermission:GetData().strLuaVariable] ~= bPermissionChecked then
			bPermissionChanged = true
			break
		end
	end

	wndSettings:FindChild("RankPopoutOkBtn"):Enable((bNew and bNameValid) or (not bNew and bNameValid and (bNameChanged or bPermissionChanged)))
	wndSettings:FindChild("StatusValidAlert"):Show(not bNameValid)
end

function Communities:OnRankSettingsCloseBtn(wndControl, wndHandler)
	local wndRankPopout = self.tWndRefs.wndMain:FindChild("RosterScreen:RankPopout")
	local wndRankContainer = wndRankPopout:FindChild("RankContainer")
	local wndSettings = wndRankPopout:FindChild("RankSettingsEntry")

	wndRankPopout:FindChild("RankContainer"):Show(true)
	wndSettings:Show(false)
end

function Communities:OnGuildRankChange(guildCurr)
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() then
		return
	end
	
	if guildCurr ~= self.tWndRefs.wndMain:GetData() then
		return
	end
	self:FullRedrawOfRoster()
end

function Communities:OnRankPopoutCloseBtn(wndControl, wndHandler)
	local wndParent = wndControl:GetParent()
	wndParent:Show(false)
end

-----------------------------------------------------------------------------------------------
-- Bottom Panel Roster Actions
-----------------------------------------------------------------------------------------------

function Communities:OnOfflineBtn(wndHandler, wndControl)
	self.bShowOffline = wndControl:IsChecked()
	
	self:FullRedrawOfRoster()
end

function Communities:ResetRosterMemberButtons()
	-- Defaults
	local wndRosterBottom = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterBottom")
	local wndAddBtn = wndRosterBottom:FindChild("RosterOptionBtnAdd")
	local wndRemoveBtn = wndRosterBottom:FindChild("RosterOptionBtnRemove")
	local wndPromoteBtn = wndRosterBottom:FindChild("RosterOptionBtnPromote")
	local wndDemoteBtn = wndRosterBottom:FindChild("RosterOptionBtnDemote")
	local wndLeaveBtn = self.tWndRefs.wndMain:FindChild("RosterScreen:AdvancedOptionsContainer:RosterOptionBtnLeave")

	wndAddBtn:Show(false)
	wndRemoveBtn:Show(false)
	wndPromoteBtn:Show(false)
	wndDemoteBtn:Show(false)
	wndAddBtn:SetCheck(false)
	wndRemoveBtn:SetCheck(false)
	wndPromoteBtn:SetCheck(false)
	wndLeaveBtn:SetCheck(false)

	-- Enable member options based on Permissions (note Code will also guard against this) -- TODO
	local guildCurr = self.tWndRefs.wndMain:GetData()
	local eMyRank = guildCurr:GetMyRank()

	if guildCurr and eMyRank then
		local wndRosterGrid = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterGrid")
		local tMyRankPermissions = guildCurr:GetRanks()[eMyRank]
		local bSomeRowIsPicked = wndRosterGrid:GetCurrentRow()
		local bTargetIsUnderMyRank = bSomeRowIsPicked and eMyRank < wndRosterGrid:GetData().nRank

		wndRemoveBtn:Enable(bSomeRowIsPicked and bTargetIsUnderMyRank)
		wndPromoteBtn:Enable(bSomeRowIsPicked and bTargetIsUnderMyRank)
		wndDemoteBtn:Enable(bSomeRowIsPicked and bTargetIsUnderMyRank and wndRosterGrid:GetData().nRank ~= 10)
		
		wndAddBtn:Show(tMyRankPermissions and tMyRankPermissions.bInvite and GuildLib.CanInvite(GuildLib.GuildType_Community))
		wndRemoveBtn:Show(tMyRankPermissions and tMyRankPermissions.bKick)
		wndPromoteBtn:Show(tMyRankPermissions and tMyRankPermissions.bChangeMemberRank)
		wndDemoteBtn:Show(tMyRankPermissions and tMyRankPermissions.bChangeMemberRank)

		if eMyRank == 1 then
			wndLeaveBtn:SetText(Apollo.GetString("Communities_Disband"))
		else
			wndLeaveBtn:SetText(Apollo.GetString("Communities_Leave"))
		end
	end

	wndRosterBottom:ArrangeChildrenHorz(0)
end

-----------------------------------------------------------------------------------------------
-- Member permissions updating buttons
-----------------------------------------------------------------------------------------------

function Communities:OnRosterAddMemberClick(wndHandler, wndControl)
	self.tWndRefs.wndMain:FindChild("RosterScreen:RosterBottom:RosterOptionBtnAdd:AddMemberContainer:AddMemberEditBox"):SetFocus()
end

function Communities:OnRosterRemoveMemberClick(wndHandler, wndControl)
	self.tWndRefs.wndMain:FindChild("RosterScreen:RosterBottom:RosterOptionBtnRemove:RemoveMemberContainer:RemoveMemberLabel"):SetText(String_GetWeaselString(Apollo.GetString("Communities_KickConfirmation"), self.tWndRefs.wndMain:FindChild("RosterScreen:RosterGrid"):GetData().strName))
end

function Communities:OnRosterPromoteMemberClick(wndHandler, wndControl) -- wndHandler is "RosterOptionBtnPromote"
	-- This one is different, it'll fire right away unless promoting to leader
	local guildCurr = self.tWndRefs.wndMain:GetData()
	local tMember = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterGrid"):GetData()
	local wndPromoteBtn = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterBottom:RosterOptionBtnPromote")
	if tMember.nRank == 2 then
		wndPromoteBtn:FindChild("PromoteMemberContainer"):Show(true)
		wndPromoteBtn:SetCheck(true)
	else
		guildCurr:Promote(tMember.strName) -- TODO: More error checking
		wndPromoteBtn:FindChild("PromoteMemberContainer"):Show(false)
		wndPromoteBtn:SetCheck(false)
	end
end

function Communities:OnRosterDemoteMemberClick(wndHandler, wndControl) -- wndHandler is "RosterOptionBtnPromote"
	local guildCurr = self.tWndRefs.wndMain:GetData()
	local tMember = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterGrid"):GetData()
	guildCurr:Demote(tMember.strName)
	wndControl:SetCheck(false)
end

function Communities:OnRosterEditNoteSave(wndHandler, wndControl)
	wndHandler:SetFocus()
	self:OnRosterEditNotesCloseBtn()

	local guildCurr = self.tWndRefs.wndMain:GetData()
	guildCurr:SetMemberNoteSelf(self.tWndRefs.wndMain:FindChild("EditNotesEditbox"):GetText())
end

-- Closing the Pop Up Bubbles
function Communities:OnRosterAddMemberCloseBtn()
	local wndAddMemberContainer = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterBottom:RosterOptionBtnAdd:AddMemberContainer")
	wndAddMemberContainer:FindChild("AddMemberEditBox"):SetText("")
	wndAddMemberContainer:Show(false)
end

function Communities:OnRosterPromoteMemberCloseBtn()
	local wndPromoteBtn = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterBottom:RosterOptionBtnPromote")
	wndPromoteBtn:FindChild("PromoteMemberContainer"):Show(false)
	wndPromoteBtn:SetCheck(false) -- Since we aren't using AttachWindow
end

function Communities:OnRosterRemoveMemberCloseBtn()
	self.tWndRefs.wndMain:FindChild("RosterScreen:RosterBottom:RosterOptionBtnRemove:RemoveMemberContainer"):Show(false)
end

function Communities:OnRosterLeaveCloseBtn()
	self.tWndRefs.wndMain:FindChild("RosterScreen:AdvancedOptionsContainer:RosterOptionBtnLeave:LeaveBtnContainer"):Show(false)
end

function Communities:OnRosterEditNotesCloseBtn()
	self.tWndRefs.wndMain:FindChild("EditNotesContainer"):Show(false)
end

-- Saying Yes to the Pop Up Bubbles
function Communities:OnAddMemberYesClick(wndHandler, wndControl) -- wndHandler is 'AddMemberEditBox' or 'AddMemberYesBtn', and its data is 'AddMemberEditBox'
	local guildCurr = self.tWndRefs.wndMain:GetData()
	local wndEditBox = wndHandler:GetData()

	if wndEditBox and wndEditBox:GetData() and Apollo.StringLength(wndEditBox:GetText()) > 0 then -- TODO: Additional string validation
		guildCurr:Invite(wndEditBox:GetText())
	end
	self:OnRosterAddMemberCloseBtn()
end

function Communities:OnRosterPromoteMemberYesClick(wndHandler, wndControl) -- wndHandler is 'PromoteMemberYesBtn'
	local guildCurr = self.tWndRefs.wndMain:GetData()
	local tMember = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterGrid"):GetData()

	guildCurr:PromoteMaster(tMember.strName)
	self:OnRosterPromoteMemberCloseBtn()
end

function Communities:OnRosterRemoveMemberYesClick(wndHandler, wndControl) -- wndHandler is 'RemoveMemberYesBtn'
	local guildCurr = self.tWndRefs.wndMain:GetData()
	local tMember = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterGrid"):GetData()
	guildCurr:Kick(tMember.strName)
	self:OnRosterRemoveMemberCloseBtn()
end

function Communities:OnRosterLeaveYesClick(wndHandler, wndControl) -- wndHandler is "LeaveBtnYesBtn"
	local guildCurr = self.tWndRefs.wndMain:GetData()
	if guildCurr and guildCurr:GetMyRank() == 1 then
		guildCurr:Disband()
	elseif guildCurr then
		guildCurr:Leave()
	end
	wndHandler:GetParent():Close()
	self.tWndRefs.wndMain:Close()
end

-----------------------------------------------------------------------------------------------
-- OnGuildMemberChange
-----------------------------------------------------------------------------------------------

function Communities:OnGuildMemberChange( guildCurr, tMember )
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() or not self.tWndRefs.wndMain:GetData() then
		return
	end
	
	if guildCurr and guildCurr:GetType() == GuildLib.GuildType_Community then
		if not tMember then
			self:FullRedrawOfRoster()
		else
			local wndGrid = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterGrid")

			local nRowCount = wndGrid:GetRowCount()
			local nMemberRow = 0
			for nRow=1,nRowCount do
				local tRowData = wndGrid:GetCellLuaData(nRow, 1)
				if tRowData and tRowData.strName == tMember.strName then
					nMemberRow = nRow
					break
				end
			end
			
			if nMemberRow == 0 then
				nMemberRow = wndGrid:AddRow("")
				wndGrid:SetCellLuaData(nMemberRow, 1, tMember)
			end
			
			if nMemberRow > 0 then
				local tRanks = guildCurr:GetRanks()
				self:FillMemberRow(wndGrid, nMemberRow, tRanks, tMember)
			end
			
			self:ResetRosterMemberButtons()
		end
	end
end

function Communities:OnOfflineTimeUpdate()
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() or not self.tWndRefs.wndMain:GetData() then
		return
	end
	
	local wndGrid = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterGrid")
	local nSelectedRow = wndGrid:GetCurrentRow()
	
	local wndRosterBottom = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterBottom")
	local wndAddBtn = wndRosterBottom:FindChild("RosterOptionBtnAdd")
	local wndLeaveBtn = self.tWndRefs.wndMain:FindChild("RosterScreen:AdvancedOptionsContainer:RosterOptionBtnLeave")
	local wndRemoveBtn = wndRosterBottom:FindChild("RosterOptionBtnRemove")

	local bAddSelected = wndAddBtn:IsChecked()
	local bLeaveSelected = wndLeaveBtn:IsChecked()
	local bRemoveSelected = wndRemoveBtn:IsChecked()
	
	-- Calling RequestMembers will fire the GuildRoster event, which tends to reset a lot of the things we have selected.
	self.tWndRefs.wndMain:GetData():RequestMembers()
	
	wndGrid:SetCurrentRow(nSelectedRow or 0)
	self:ResetRosterMemberButtons()
	
	wndAddBtn:SetCheck(bAddSelected)
	wndLeaveBtn:SetCheck(bLeaveSelected)
	wndRemoveBtn:SetCheck(bRemoveSelected)
end

-----------------------------------------------------------------------------------------------
-- OnGuildResult
-----------------------------------------------------------------------------------------------

function Communities:OnGuildResult(guildCurr, strName, nRank, eResult)
	if not self.tWndRefs.wndMain or not self.tWndRefs.wndMain:IsValid() or not self.tWndRefs.wndMain:IsShown() then
		return
	end
	-- Reload UI when a Community is made
	if guildCurr and guildCurr:GetType() == GuildLib.GuildType_Community then
		local guildViewed = self.tWndRefs.wndMain:GetData()
		self.bViewingRemovedGuild = false -- is the affected guild shown?

		if guildViewed ~= nil and self.tWndRefs.wndMain:IsShown() and self.tWndRefs.wndMain:FindChild("RosterScreen"):IsShown() and guildViewed:GetName() == strName then
			self.bViewingRemovedGuild = true -- we need to redraw in these instances
		end

		-- if you've been kicked, left, or disbanded a Community and you're viewing it
		if eResult == GuildLib.GuildResult_KickedYou and self.tWndRefs.wndMain:IsShown() then
			self.tWndRefs.wndMain:FindChild("AlertMessage"):FindChild("MessageAlertText"):SetText(Apollo.GetString("Communities_KickedAlertTitle"))
			self.tWndRefs.wndMain:FindChild("AlertMessage"):FindChild("MessageBodyText"):SetText(String_GetWeaselString(Apollo.GetString("Communities_Kicked"), strName))
			self.tWndRefs.wndMain:FindChild("AlertMessage"):Invoke()
			Apollo.StartTimer("CommunityAlertDisplayTimer")
		elseif eResult == GuildLib.GuildResult_YouQuit and self.tWndRefs.wndMain:IsShown() then
			self.tWndRefs.wndMain:FindChild("AlertMessage"):FindChild("MessageAlertText"):SetText(Apollo.GetString("Communities_Bye"))
			self.tWndRefs.wndMain:FindChild("AlertMessage"):FindChild("MessageBodyText"):SetText(String_GetWeaselString(Apollo.GetString("Communities_LeftCommunity"), strName))
			self.tWndRefs.wndMain:FindChild("AlertMessage"):Invoke()
			Apollo.StartTimer("CommunityAlertDisplayTimer")
		elseif eResult == GuildLib.GuildResult_GuildDisbanded and self.tWndRefs.wndMain:IsShown() then
			self.tWndRefs.wndMain:FindChild("AlertMessage"):FindChild("MessageAlertText"):SetText(Apollo.GetString("Communities_CommunityDisbanded"))
			self.tWndRefs.wndMain:FindChild("AlertMessage"):FindChild("MessageBodyText"):SetText(String_GetWeaselString(Apollo.GetString("Communities_YouDisbanded"), strName))
			self.tWndRefs.wndMain:FindChild("AlertMessage"):Invoke()
			Apollo.StartTimer("CommunityAlertDisplayTimer")
		end
	end
end

function Communities:OnCommunityAlertDisplayTimer()
	self.tWndRefs.wndMain:FindChild("AlertMessage"):Show(false)
	self.tWndRefs.wndMain:Close()
end

-----------------------------------------------------------------------------------------------
-- Community Invite Window
-----------------------------------------------------------------------------------------------

function Communities:OnCommunityInvite( strGuildName, strInvitorName, guildType )
	if guildType ~= GuildLib.GuildType_Community then
		return
	end

	if self.wndCommunityInvite ~= nil then
		self.wndCommunityInvite:Destroy()
	end

	self.wndCommunityInvite = Apollo.LoadForm(self.xmlDoc, "CommunityInviteConfirmation", nil, self)
	self.wndCommunityInvite:FindChild("CommunityInviteLabel"):SetText(String_GetWeaselString(Apollo.GetString("Guild_IncomingCommunityInvite"), strGuildName, strInvitorName))
	self.wndCommunityInvite:ToFront()
end

function Communities:OnCommunityInviteAccept(wndHandler, wndControl)
	GuildLib.Accept()
	if self.wndCommunityInvite then
		self.wndCommunityInvite:Destroy()
	end
end

function Communities:OnCommunityInviteDecline() -- This can come from a variety of sources
	GuildLib.Decline()
	if self.wndCommunityInvite then
		self.wndCommunityInvite:Destroy()
	end
end

function Communities:OnReportCommunityInviteSpamBtn()
	Event_FireGenericEvent("GenericEvent_ReportPlayerCommunityInvite") -- Order is important
	self:OnCommunityInviteDecline()
end


-----------------------------------------------------------------------------------------------
-- Roster Sorting
-----------------------------------------------------------------------------------------------

function Communities:OnRosterSortToggle(wndHandler, wndControl)
	self:BuildRosterList(self.tWndRefs.wndMain:GetData(), self:SortRoster(self.tWndRefs.wndMain:FindChild("RosterScreen:RosterHeaderContainer"):GetData(), wndHandler:GetName()))
end

function Communities:SortRoster(tArg, strLastClicked)
	-- TODO: Two tiers of sorting. E.g. Clicking Name then Path will give Paths sorted first, then Names sorted second
	if not tArg then return end
	local tResult = tArg

	if self.tWndRefs.wndMain:FindChild("RosterSortBtnName"):IsChecked() then
		table.sort(tResult, function(a,b) return (a.strName > b.strName) end)
	elseif self.tWndRefs.wndMain:FindChild("RosterSortBtnRank"):IsChecked() then
		table.sort(tResult, function(a,b) return (a.nRank > b.nRank) end)
	elseif self.tWndRefs.wndMain:FindChild("RosterSortBtnLevel"):IsChecked() then
		table.sort(tResult, function(a,b) return (a.nLevel < b.nLevel) end) -- Level we want highest to lowest
	elseif self.tWndRefs.wndMain:FindChild("RosterSortBtnClass"):IsChecked() then
		table.sort(tResult, function(a,b) return (a.strClass > b.strClass) end)
	elseif self.tWndRefs.wndMain:FindChild("RosterSortBtnOnline"):IsChecked() then
		table.sort(tResult, function(a,b) return (a.fLastOnline < b.fLastOnline) end)
	elseif self.tWndRefs.wndMain:FindChild("RosterSortBtnNote"):IsChecked() then
		table.sort(tResult, function(a,b) return (a.strNote < b.strNote) end)
	else
		-- Determine the last clicked with the second argument
		if strLastClicked == "RosterSortBtnName" then
			table.sort(tResult, function(a,b) return (a.strName < b.strName) end)
		elseif strLastClicked == "RosterSortBtnRank" then
			table.sort(tResult, function(a,b) return (a.nRank < b.nRank) end)
		elseif strLastClicked == "RosterSortBtnLevel" then
			table.sort(tResult, function(a,b) return (a.nLevel > b.nLevel) end)
		elseif strLastClicked == "RosterSortBtnClass" then
			table.sort(tResult, function(a,b) return (a.strClass < b.strClass) end)
		elseif strLastClicked == "RosterSortBtnOnline" then
			table.sort(tResult, function(a,b) return (a.fLastOnline > b.fLastOnline) end)
		elseif strLastClicked == "RosterSortBtnNote" then
			table.sort(tResult, function(a,b) return (a.strNote > b.strNote) end)
		end
	end

	return tResult
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function Communities:OnGenerateGridTooltip(wndHandler, wndControl, eType, iRow, iColumn)
	-- If the note column 7, draw a special tooltip
	wndHandler:SetTooltip(self.tWndRefs.wndMain:FindChild("RosterGrid"):GetCellData(iRow + 1, 8) or "") -- TODO: Remove this hardcoded
end

function Communities:HelperConvertToTime(nDays)
	if nDays == 0 then
		return Apollo.GetString("ArenaRoster_Online")
	end

	if nDays == nil then
		return ""
	end

	local tTimeInfo = {["name"] = "", ["count"] = nil}

	if nDays >= 365 then -- Years
		tTimeInfo["name"] = Apollo.GetString("CRB_Year")
		tTimeInfo["count"] = math.floor(nDays / 365)
	elseif nDays >= 30 then -- Months
		tTimeInfo["name"] = Apollo.GetString("CRB_Month")
		tTimeInfo["count"] = math.floor(nDays / 30)
	elseif nDays >= 7 then
		tTimeInfo["name"] = Apollo.GetString("CRB_Week")
		tTimeInfo["count"] = math.floor(nDays / 7)
	elseif nDays >= 1 then -- Days
		tTimeInfo["name"] = Apollo.GetString("CRB_Day")
		tTimeInfo["count"] = math.floor(nDays)
	else
		local fHours = nDays * 24
		local nHoursRounded = math.floor(fHours)
		local nMin = math.floor(fHours*60)

		if nHoursRounded > 0 then
			tTimeInfo["name"] = Apollo.GetString("CRB_Hour")
			tTimeInfo["count"] = nHoursRounded
		elseif nMin > 0 then
			tTimeInfo["name"] = Apollo.GetString("CRB_Min")
			tTimeInfo["count"] = nMin
		else
			tTimeInfo["name"] = Apollo.GetString("CRB_Min")
			tTimeInfo["count"] = 1
		end
	end

	return String_GetWeaselString(Apollo.GetString("CRB_TimeOffline"), tTimeInfo)
end

function Communities:OnEntitlementUpdate(tEntitlementInfo)
	if not self.tWndRefs.wndMain then
		return
	end
	if tEntitlementInfo.nEntitlementId == AccountItemLib.CodeEnumEntitlement.Signature or tEntitlementInfo.nEntitlementId == AccountItemLib.CodeEnumEntitlement.Free or tEntitlementInfo.nEntitlementId == AccountItemLib.CodeEnumEntitlement.FullGuildsAccess then
		self.tWndRefs.wndMain:FindChild("RosterOptionBtnAdd"):Show(GuildLib.CanInvite(GuildLib.GuildType_Community))
	end
end

local CommunitiesInst = Communities:new()
CommunitiesInst:Init()
