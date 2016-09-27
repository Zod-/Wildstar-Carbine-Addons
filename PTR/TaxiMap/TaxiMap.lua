-----------------------------------------------------------------------------------------------
-- Client Lua Script for TaxiMap
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Unit"
require "GameLib"
require "Tooltip"
require "XmlDoc"
require "PlayerPathLib"
require "HexGroups"
 
-----------------------------------------------------------------------------------------------
-- TaxiMap Module Definition
-----------------------------------------------------------------------------------------------
local TaxiMap = {}
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function TaxiMap:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    o.tWndRefs = {}
	o.unitTaxi = nil
	o.nTaxiUnderCursor = 0
	o.tTaxiObjects = {}
	o.tTaxiNodes = {}
	o.tTaxiRoutes = {}

    return o
end

function TaxiMap:Init()
    Apollo.RegisterAddon(self)
end

-----------------------------------------------------------------------------------------------
-- TaxiMap OnLoad
-----------------------------------------------------------------------------------------------
function TaxiMap:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("TaxiMap.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function TaxiMap:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	Apollo.RegisterEventHandler("WindowManagementReady", 	"OnWindowManagementReady", self)
	self:OnWindowManagementReady()
	
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 		"OnInterfaceMenuListHasLoaded", self)
	self:OnInterfaceMenuListHasLoaded()
	
	Apollo.RegisterEventHandler("FlightPathUpdate", 				"OnFlightPathUpdate", self)
	Apollo.RegisterEventHandler("InvokeTaxiWindow", 				"OnInvokeTaxiWindow", self)
	Apollo.RegisterEventHandler("InvokeShuttlePrompt", 				"OnInvokeShuttlePrompt", self)		
	Apollo.RegisterEventHandler("CloseVendorWindow", 				"OnCloseVendorWindow", self)
	Apollo.RegisterEventHandler("TaxiWindowClose",					"OnCloseVendorWindow", self)
	Apollo.RegisterTimerHandler("Taxi_MessageDisplayTimer",			"OnMessageDisplayTimer", self)
	Apollo.RegisterEventHandler("ZoneMapWindowModeChange",			"OnMouseScroll", self)
	Apollo.RegisterEventHandler("InterfaceMenu_InvokeTaxiWindow", 	"OnInvokeTaxiWindow", self)
	Apollo.RegisterEventHandler("SubZoneChanged",					"OnZoneChanged", self)
	Apollo.RegisterEventHandler("ChangeWorld",						"OnZoneChanged", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat",				"OnUnitEnteredCombat", self)
	
	Apollo.RegisterEventHandler("ShowNearestRapidTransportNode",	"OnShowNearestRapidTransportNode", self)

	--StoreEvents
	Apollo.RegisterEventHandler("StoreLinksRefresh",								"RefreshStoreLink", self)
    
	self.tZoneInfo = nil
	self.bLinkAvailable = false
end

function TaxiMap:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = Apollo.GetString("CRB_Taxi_Vendor"), nSaveVersion = 3})
end

function TaxiMap:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", Apollo.GetString("CRB_RapidTransport"), { "InterfaceMenu_InvokeTaxiWindow", "", "IconSprites:Icon_Windows32_UI_CRB_InterfaceMenu_RapidTransport"})
end

function TaxiMap:OnZoneChanged()
	local tZoneInfo = GameLib.GetCurrentZoneMap()
	if not tZoneInfo then
		return
	end

	self.eOldZoomLevel = nil
	self.bFarside = false
	self.bZoomSetView = false
	self.tZoneInfo = tZoneInfo
	self.tLastSelectedSubzone = nil
	if tZoneInfo.parentZoneId > 0 then
		self.bFarside = true
		self.tLastSelectedSubzone = tZoneInfo
	elseif tZoneInfo.id == 28 then
		self.bFarside = true
	end


	if self.tWndRefs.wndMain then
		self:PopulateTaxiMap()
		self.tWndRefs.wndMain:FindChild("ReturnBtn"):SetData({tHomeZone = self.tZoneInfo, eHomeView = self.eOldZoomLevel})
	end
	self:OnInterfaceMenuListHasLoaded()
end

-----------------------------------------------------------------------------------------------
-- TaxiMap Functions
-----------------------------------------------------------------------------------------------

function TaxiMap:OnInvokeTaxiWindow(unitTaxi, bSettlerTaxi)--If unitTaxi is nil, that means we are teleporting
	if self.tWndRefs.wndMain ~= nil then
		self.tWndRefs.wndMain:Close()
		return
	end

	self.unitTaxi = unitTaxi
	self.bSettlerTaxi = bSettlerTaxi

	if not GameLib.GetCurrentZoneMap() then
		return
	end

	self.tWndRefs.wndMain = Apollo.LoadForm(self.xmlDoc, "TaxiMapForm", nil, self)
	self.tWndRefs.wndTaxiMap = self.tWndRefs.wndMain:FindChild("WorldMap")
	self.tWndRefs.wndMessage = self.tWndRefs.wndMain:FindChild("UpdateMessage")
	self.tWndRefs.wndMessage:Show(false, true)
	self.tWndRefs.wndWorldView = self.tWndRefs.wndMain:FindChild("WorldMapView")
	self.tWndRefs.wndRapidTransportPrompt = Apollo.LoadForm(self.xmlDoc, "RapidTransportPrompt", nil, self)
	self.tWndRefs.wndTooltip = Apollo.LoadForm(self.xmlDoc, "NodeTooltip", nil, self)

	self.ktZoneNames = 
	{
		[22] = Apollo.GetString("CRB_Western"),
		[51] = Apollo.GetString("CRB_Eastern"),
		[1061] = Apollo.GetString("CRB_Central"),
		[3335] = Apollo.GetString("CRB_Arcterra"),
		[1421] = Apollo.GetString("Lore_Farside"),
	}

	self.bZoomSetView = false

	if not self.eOverlayType and not self.ePingOverlayType then
		self.eOverlayType = self.tWndRefs.wndTaxiMap:CreateOverlayType()
		self.ePingOverlayType = self.tWndRefs.wndTaxiMap:CreateOverlayType()
	end

	self:OnZoneChanged()
	self:PopulateTaxiMap()

	if self.tZoneInfo then
		self.tWndRefs.wndMain:FindChild("ReturnBtn"):SetData({tHomeZone = self.tZoneInfo, eHomeView = self.eOldZoomLevel})
	end

	self.tWndRefs.wndMain:FindChild("TitleText"):SetText(Apollo.GetString(self.unitTaxi ~= nil and "CRB_Taxi_Vendor" or "CRB_RapidTransport"))
	self.tWndRefs.wndMain:FindChild("ZoneToggle"):AttachWindow(self.tWndRefs.wndMain:FindChild("ZoneList"))
	self.tWndRefs.wndMain:FindChild("SubzoneToggle"):AttachWindow(self.tWndRefs.wndMain:FindChild("SubzoneList"))
	self.tWndRefs.wndMain:FindChild("ZoneToggle"):Show(not self.unitTaxi)
	self.tWndRefs.wndMain:FindChild("ZoomInBtn"):Show(not self.unitTaxi)
	self.tWndRefs.wndMain:FindChild("ReturnBtn"):Show(not self.unitTaxi)
	self.tWndRefs.wndMain:FindChild("ZoomOutBtn"):Show(not self.unitTaxi)
	self.tWndRefs.wndMain:FindChild("SubzoneToggle"):Show(self.bFarside and not self.unitTax)

	self.tWndRefs.wndWorldView:FindChild("ContWesternBtn"):SetData({nMapContinentId = 8, nWorldId = 22, strName = Apollo.GetString("CRB_Western")})
	self.tWndRefs.wndWorldView:FindChild("ContEasternBtn"):SetData({nMapContinentId = 6, nWorldId = 51, strName = Apollo.GetString("CRB_Easetern")})
	self.tWndRefs.wndWorldView:FindChild("ContCentralBtn"):SetData({nMapContinentId = 33, nWorldId = 1061, strName = Apollo.GetString("CRB_Central")})
	self.tWndRefs.wndWorldView:FindChild("ContArcterraBtn"):SetData({nMapContinentId = 92, nWorldId = 3335, strName = Apollo.GetString("CRB_Arcterra")})
	self.tWndRefs.wndWorldView:FindChild("ContFarsideBtn"):SetData({nMapContinentId = 28, nWorldId = 1421, strName = Apollo.GetString("Lore_Farside"), bFarside = true})
	
	self.tWndRefs.wndMain:FindChild("OlyssiaBtn"):SetData({nMapContinentId = 8, nWorldId = 22, strName = Apollo.GetString("CRB_Western")})
	self.tWndRefs.wndMain:FindChild("AlizarBtn"):SetData({nMapContinentId = 6, nWorldId = 51, strName = Apollo.GetString("CRB_Eastern")})
	self.tWndRefs.wndMain:FindChild("IsigrolBtn"):SetData({nMapContinentId = 33, nWorldId = 1061, strName = Apollo.GetString("CRB_Central")})
	self.tWndRefs.wndMain:FindChild("ArcterraBtn"):SetData({nMapContinentId = 92, nWorldId = 3335, strName = Apollo.GetString("CRB_Arcterra")})
	self.tWndRefs.wndMain:FindChild("FarsideBtn"):SetData({nMapContinentId = 28, nWorldId = 1421, strName = Apollo.GetString("Lore_Farside"), bFarside = true})

	self.tWndRefs.wndMain:FindChild("DerelictSiloBtn"):SetData({nMapContinentId = 19, nWorldId = 46, strName = Apollo.GetString("Taximap_DerelictSilo"), bFarside = true, bSubZone = true})
	self.tWndRefs.wndMain:FindChild("BioDome3Btn"):SetData({nMapContinentId = 19, nWorldId = 74, strName = Apollo.GetString("Taximap_BioDome3"), bFarside = true, bSubZone = true})
	self.tWndRefs.wndMain:FindChild("BioDome4Btn"):SetData({nMapContinentId = 19, nWorldId = 75, strName = Apollo.GetString("Taximap_BioDome4"), bFarside = true, bSubZone = true})
	self.tWndRefs.wndMain:FindChild("ClearFarsideSubzoneBtn"):SetData({nMapContinentId = 28, nWorldId = 1421, strName = Apollo.GetString("Lore_Farside"), bFarside = true})

	self.tWndRefs.wndMain:Invoke()
	self:RefreshStoreLink()
	
	if self.unitTaxi == nil then
		self.timerCooldown = ApolloTimer.Create(1.0, true, "UpdateTimeString", self)
		local nCoolDown = GameLib.GetRapidTransportCooldown()
		if nCoolDown > 0 then
			self:UpdateTimeString()--Show the cool down instnatly.
			self.timerCooldown:Start()
		else
			self.timerCooldown:Stop()
		end
	end
	
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.tWndRefs.wndMain, strName = Apollo.GetString("CRB_Taxi_Vendor")})
end

-----------------------------------------------------------------------------------------------

function TaxiMap:IsTutorialZone()
	local tZone = GameLib.GetCurrentZoneMap()
	local nZoneId = 0
	if tZone ~= nil then
		nZoneId = tZone.id
	end
	return tZone == nil or GameLib.IsTutorialZone(nZoneId)
end

-----------------------------------------------------------------------------------------------

function TaxiMap:OnInvokeShuttlePrompt(unitTaxi)
	if self.wndPrompt ~= nil then
		return
	end

	self.unitTaxi = unitTaxi
	
	self.wndPrompt = Apollo.LoadForm(self.xmlDoc, "ShuttlePrompt", nil, self)
	self.wndPrompt:FindChild("Title"):SetText(String_GetWeaselString(Apollo.GetString("TaxiMap_ShuttleConfirmation"), unitTaxi:GetTransferDestination()))
	self.wndPrompt:Invoke()
end

-----------------------------------------------------------------------------------------------
function TaxiMap:OnFlightPathUpdate()
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	if self.unitTaxi == nil then
		return
	end

	self:PopulateTaxiMap()
end

-----------------------------------------------------------------------------------------------
function TaxiMap:PopulateTaxiMap()
	self.tWndRefs.wndTaxiMap:RemoveAllLines()
	self.tWndRefs.wndTaxiMap:RemoveAllObjects()
	
	self.tTaxiObjects = {}
	self.tTaxiRoutes = {}
	self.tTaxiNodes = {}
	self.nTaxiUnderCursor = 0

	self.tWndRefs.wndTaxiMap:SetZone(self.tZoneInfo.id)
	self:HelperSetMapViews()

	if self.unitTaxi then
		local tFlightPaths = self.unitTaxi:GetFlightPaths()
		if tFlightPaths then
			self:HelperPlaceTaxiNodes(tFlightPaths)
		end
	elseif self.tZoneInfo then
		local tNearestNode = nil
		if self.tNearestNodeRequest then
			tNearestNode = GameLib.GetNearestRapidTransportNodeForWorldLocation(self.tNearestNodeRequest.nWorldId, self.tNearestNodeRequest.tPosition)
		end

		local tRapidTransportNodes = GameLib.GetRapidTransportDestinationsForWorld(self.tZoneInfo.nWorldId)
		if tRapidTransportNodes then
			self:HelperPlaceTaxiNodes(tRapidTransportNodes, tNearestNode)
		end
		
		self.tWndRefs.wndTaxiMap:TogglePOIs(false)
		self.bFarside = self.tZoneInfo.id == 28
	end

	--Set control views and text

	local nSubZoneId = self.tZoneInfo.id
	if self.tZoneInfo.parentZoneId > 0 then
		nSubZoneId = self.tZoneInfo.parentZoneId
	end

	local strSubZone = Apollo.GetString("ZoneMap_Subzones")
	local arSubZones = self.tWndRefs.wndTaxiMap:GetAllSubZoneInfo(nSubZoneId)
	if arSubZones and #arSubZones > 0 then
		self.bFarside = true
		for idx, tSubZoneInfo in pairs(arSubZones) do
			if tSubZoneInfo.id == self.tZoneInfo.id then
				strSubZone = tSubZoneInfo.strName
				break
			end
		end
	end

	local bShowWorldMap = false
	local strText = self.ktZoneNames[self.tZoneInfo.nWorldId]
	if self.ktZoneNames[self.tZoneInfo.nWorldId] then
		if self.bFarside then --Farside must have special handling.
			bShowWorldMap = self.eOldZoomLevel >= ZoneMapWindow.CodeEnumDisplayMode.Continent
			strText = bShowWorldMap and Apollo.GetString("ZoneCompletion_WorldCompletion") or self.ktZoneNames[self.tZoneInfo.nWorldId]
		else
			bShowWorldMap = self.eOldZoomLevel > ZoneMapWindow.CodeEnumDisplayMode.Continent
			strText = bShowWorldMap and Apollo.GetString("ZoneCompletion_WorldCompletion") or self.ktZoneNames[self.tZoneInfo.nWorldId]
		end
	else --Not a valid zone, always show the world view.
		bShowWorldMap = true
		strText = Apollo.GetString("ZoneCompletion_WorldCompletion")
	end
	self.tWndRefs.wndWorldView:Show(bShowWorldMap)

	local wndSubzoneToggle = self.tWndRefs.wndMain:FindChild("SubzoneToggle")
	wndSubzoneToggle:SetText(strSubZone)
	wndSubzoneToggle:Show(not bShowWorldMap and self.bFarside)

	self.tWndRefs.wndMain:FindChild("ZoneToggle"):SetText(strText)
	self:HandleDisabledBlocker()
end

function TaxiMap:OnUnitEnteredCombat(unit)
	if unit ~= GameLib.GetPlayerUnit() or self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end

	self:HandleDisabledBlocker()
end

function TaxiMap:OnShowNearestRapidTransportNode(tNearestNodeRequest)
	if not tNearestNodeRequest then
		return
	end

	self:OnInvokeTaxiWindow()

	local tZoneInfo = self.tWndRefs.wndTaxiMap:GetZoneInfo(tNearestNodeRequest.nMapZoneId)
	if tZoneInfo then
		tNearestNodeRequest.nWorldId = tZoneInfo.nWorldId
	end

	self.tNearestNodeRequest = tNearestNodeRequest
	self:PopulateTaxiMap()
end

function TaxiMap:HandleDisabledBlocker()
	local bDisabled = false
	local strDisabled = ""
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer and unitPlayer:IsInCombat() then
		strDisabled = Apollo.GetString("RapidTransport_Combat")
		bDisabled = true
	end

	if self:IsTutorialZone() then
		strDisabled = Apollo.GetString("RapidTransport_Disabled")
		bDisabled = true
	end

	local wndDisabledBlocker = self.tWndRefs.wndMain:FindChild("DisabledBlocker")
	wndDisabledBlocker:Show(bDisabled)
	wndDisabledBlocker:SetText(strDisabled)
	self.tWndRefs.wndMain:FindChild("ZoneToggle"):Enable(not bDisabled)
	self.tWndRefs.wndMain:FindChild("SubzoneToggle"):Enable(not bDisabled)
	local wndZoomControls = self.tWndRefs.wndMain:FindChild("ZoomControls")
	for idx, wndChild in pairs (wndZoomControls:GetChildren()) do
		wndChild:Enable(not bDisabled)
	end
end

function TaxiMap:HelperSetMapViews()
	local eMinView = nil
	local eMaxView = nil
	local eSetView = nil
	local tCurrentContinent = self.tWndRefs.wndTaxiMap:GetContinentInfo(self.tZoneInfo.continentId)
	if self.unitTaxi and self.bSettlerTaxi == false then
		eMinView = ZoneMapWindow.CodeEnumDisplayMode.Continent
		eMaxView = ZoneMapWindow.CodeEnumDisplayMode.Continent
		eSetView = ZoneMapWindow.CodeEnumDisplayMode.Continent
	elseif self.bSettlerTaxi == true then
		eMinView = ZoneMapWindow.CodeEnumDisplayMode.Scaled
		eMaxView = ZoneMapWindow.CodeEnumDisplayMode.Scaled
		eSetView = ZoneMapWindow.CodeEnumDisplayMode.Scaled
	else
		if self.bFarside then
			eMinView = ZoneMapWindow.CodeEnumDisplayMode.Panning
			eMaxView = ZoneMapWindow.CodeEnumDisplayMode.Continent

			if self.bZoomSetView and self.eOldZoomLevel ~= nil then
				eSetView = self.eOldZoomLevel
			else
				eSetView = ZoneMapWindow.CodeEnumDisplayMode.Scaled
			end
		else
			eMinView = ZoneMapWindow.CodeEnumDisplayMode.Continent
			eMaxView = ZoneMapWindow.CodeEnumDisplayMode.World

			if self.bZoomSetView and self.eOldZoomLevel ~= nil then
				eSetView = self.eOldZoomLevel
			else
				eSetView = ZoneMapWindow.CodeEnumDisplayMode.Continent
			end

		end
	end

	self.tWndRefs.wndTaxiMap:SetMinDisplayMode(eMinView)
	self.tWndRefs.wndTaxiMap:SetMaxDisplayMode(eMaxView)
	self.tWndRefs.wndTaxiMap:SetDisplayMode(eSetView)
	self.eOldZoomLevel = eSetView
	self.bZoomSetView = false
end

function TaxiMap:HelperPlaceTaxiNodes(tNodes, tNearestNode)
	if not tNodes then
		return
	end

	local nLockedNodeOpacity = 0.76
	local nUnlockedNodeOpacity = 1
	local nNearestNodeOpacity = 1

	local bShowingNearestNode = tNearestNode ~= nil
	if bShowingNearestNode then--When there is a nearest node, we want to fade out the other nodes. 
		nUnlockedNodeOpacity = .2
		nLockedNodeOpacity = .2
	end

	local tUnlockedInfo =
	{
		strIcon = self.unitTaxi and "IconSprites:Icon_MapNode_Map_Taxi" or "IconSprites:Icon_MapNode_Map_RapidTransport",
		crObject = CColor.new(1, 1, 1, nUnlockedNodeOpacity),
		strIconEdge = strIcon,
		crEdge = CColor.new(1, 1, 1, nUnlockedNodeOpacity),
	}
	
	local tLockedInfo =
	{
		strIcon = self.unitTaxi and "IconSprites:Icon_MapNode_Map_Taxi_Undiscovered" or "IconSprites:Icon_MapNode_Map_RapidTransport_Disabled",
		crObject = CColor.new(1, 1, 1, nLockedNodeOpacity),
		strIconEdge = strIcon,
		crEdge = CColor.new(1, 1, 1, nLockedNodeOpacity),
	}
	
	local tBlockedInfo =
	{
		strIcon = self.unitTaxi and "IconSprites:Icon_MapNode_Map_Taxi_Blocked" or "IconSprites:Icon_MapNode_Map_RapidTransport_Blocked",
		crObject = CColor.new(1, 1, 1, nLockedNodeOpacity),
		strIconEdge = strIcon,
		crEdge = CColor.new(1, 1, 1, nLockedNodeOpacity),
	}

	local tNearestInfo =
	{
		strIcon = self.unitTaxi and "IconSprites:Icon_MapNode_Map_Taxi_Blocked" or "CRB_MinimapSprites:sprMM_ActiveQuestArrow",
		crObject = CColor.new(1, 1, 1, nNearestNodeOpacity),
		strIconEdge = strIcon,
		crEdge = CColor.new(1, 1, 1, nNearestNodeOpacity),
	}

	for idx, tTaxi in ipairs(tNodes) do
		if tTaxi.eType == Unit.CodeEnumFlightPathType.Local then
			local tObject = tUnlockedInfo
			
			if not tTaxi.bUnlocked then
				tObject = tLockedInfo
			elseif (not self.unitTaxi and not tTaxi.bTransportAllowed) or (self.unitTaxi and tTaxi.bOrigin) then 
				tObject = tBlockedInfo
			elseif bShowingNearestNode and tTaxi.idNode == tNearestNode.idNode then
				tObject = tNearestInfo

				local strNearest = Apollo.GetString("RapidTransport_NearestNode")
				local tInfo =
				{
					strIconEdge = "",
					strIcon 	= "sprMM_QuestZonePulse",
					crObject 	= CColor.new(1, 1, 1, 1),
					crEdge 		= CColor.new(1, 1, 1, 1),
				}
				self.tWndRefs.wndTaxiMap:RemoveObjectsByUserData(self.ePingOverlayType, strNearest)
				local idObject = self.tWndRefs.wndTaxiMap:AddObject(self.ePingOverlayType, self.tNearestNodeRequest.tPosition, strNearest, tInfo, {bFixedSizeSmall = false}, false, strNearest)
				self.tTaxiObjects[idObject] = tTaxi
				self.tNearestNodeRequest = nil
			end

			local idObject = self.tWndRefs.wndTaxiMap:AddObject(self.eOverlayType, tTaxi.tLocation, tTaxi.strName, tObject, {bNeverShowOnEdge = true, bFixedSizeLarge = true})
			self.tTaxiObjects[idObject] = tTaxi
			self.tTaxiNodes[tTaxi.idNode] = tTaxi
		end
	end
end

-----------------------------------------------------------------------------------------------
-- TaxiMapForm Functions
-----------------------------------------------------------------------------------------------

function TaxiMap:OnCloseRapidTransportPrompt()
	self.tWndRefs.wndRapidTransportPrompt:Close()
end

function TaxiMap:OnRapidTransportResult()
	self:OnCloseRapidTransportPrompt()
	self.tWndRefs.wndMain:Close()
end

function TaxiMap:OnWindowClosed(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	if self.timerCooldown then
		self.timerCooldown:Stop()
		self.timerCooldown = nil
	end
	self.tTaxiObjects = {}
	self.tTaxiNodes = {}
	self.tTaxiRoutes = {}
	self.nTaxiUnderCursor = 0
	Event_CancelTaxiVendor()
	
	if self.tWndRefs.wndMain ~= nil then
		self:OnCloseRapidTransportPrompt()
		self.tWndRefs.wndMain:Destroy()
		self.tWndRefs = {}
		
		Event_FireGenericEvent("WindowManagementRemove", {strName = Apollo.GetString("CRB_Taxi_Vendor")})
	end
end

-----------------------------------------------------------------------------------------------
function TaxiMap:OnPromptWindowClosed()
	Event_CancelTaxiVendor()
	
	if self.wndPrompt ~= nil then
		self.wndPrompt:Destroy()
		self.wndPrompt = nil
	end
end

-----------------------------------------------------------------------------------------------
-- when the Cancel button is clicked
function TaxiMap:OnCancel(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	-- just close the window which will trigger OnWindowClosed
	self.tWndRefs.wndMain:Close()
end

-----------------------------------------------------------------------------------------------
-- when the No button is clicked
function TaxiMap:OnNo(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end

	-- just close the window which will trigger OnWindowClosed
	self.wndPrompt:Close()
end

-----------------------------------------------------------------------------------------------
-- when the Yes button is clicked
function TaxiMap:OnYes(wndHandler, wndControl)
	if wndHandler:GetId() ~= wndControl:GetId() then
		return
	end
	
	self.unitTaxi:TakeShuttle()

	-- just close the window which will trigger OnWindowClosed
	self.wndPrompt:Close()
end

-----------------------------------------------------------------------------------------------
function TaxiMap:OnCloseVendorWindow()
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end	

	if self.tWndRefs.wndMain:IsShown() then
		self.tWndRefs.wndMain:Close()
	end
	
	if self.wndPrompt and self.wndPrompt:IsShown() then
		self.wndPrompt:Close()
	end
end

-----------------------------------------------------------------------------------------------
function TaxiMap:RefreshStoreLink()
	if not self.tWndRefs.wndRapidTransportPrompt then
		return
	end

	self.bLinkAvailable = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.ServiceTokens)
end

function TaxiMap:OnBuyBtn(wndHandler, wndControl)
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.ServiceTokens)
	self.tWndRefs.wndRapidTransportPrompt:Close()
end

function TaxiMap:OnTaxiMapButtonDown(wndHandler, wndControl, eButton, nX, nY, bDoubleClick)
	local tPos = self.tWndRefs.wndTaxiMap:WindowPointToClientPoint(nX, nY)
	
	local tObjects = self.tWndRefs.wndTaxiMap:GetObjectsAt(tPos.x, tPos.y)
	for key, tObject in pairs(tObjects) do
		local tTaxiNode = self.tTaxiObjects[tObject.id]
		if not self.unitTaxi and not tTaxiNode.bTransportAllowed then
			break
		elseif tTaxiNode.bUnlocked and self.tPrices then
			if not self.unitTaxi then--not through a taxi vendor
				local nCooldown = GameLib.GetRapidTransportCooldown()
				if nCooldown > 0 or not self.bCantAfford then
					local wndRapidTransportConfirm = self.tWndRefs.wndRapidTransportPrompt:FindChild("RapidTransportConfirm")
					local wndBuyBtn = self.tWndRefs.wndRapidTransportPrompt:FindChild("BuyBtn")
					wndRapidTransportConfirm:SetActionData(GameLib.CodeEnumConfirmButtonType.RapidTransport, tTaxiNode.idNode)
					wndRapidTransportConfirm:Enable(not self.bCantAfford)
					wndRapidTransportConfirm:Show(not self.bCantAfford or not self.bLinkAvailable)
					wndBuyBtn:Show(self.bLinkAvailable and self.bCantAfford)
					self.tWndRefs.wndRapidTransportPrompt:FindChild("Description"):SetText(String_GetWeaselString(Apollo.GetString("TaxiMap_Description"), tTaxiNode.strName))

					local wndPrice = self.tWndRefs.wndRapidTransportPrompt:FindChild("Price")
					wndPrice:SetAmount(self.tPrices.monPrice, true)
					self.tWndRefs.wndRapidTransportPrompt:Invoke()
				end
			elseif self.unitTaxi:GetFlightPathToPoint(tTaxiNode.idNode) then
				self.unitTaxi:PurchaseFlightPath(tTaxiNode.idNode)
			elseif not tTaxiNode.bOrigin then
				self.tWndRefs.wndMessage:FindChild("MessageText"):SetText(Apollo.GetString("TaxiMap_CantRoute"))
				self.tWndRefs.wndMessage:Show(true)
				Apollo.StopTimer("Taxi_MessageDisplayTimer")
				Apollo.CreateTimer("Taxi_MessageDisplayTimer", 4.000, false)
			end
		elseif not tTaxiNode.bOrigin then
			self.tWndRefs.wndMessage:FindChild("MessageText"):SetText(Apollo.GetString("TaxiMap_NotUnlocked"))
			self.tWndRefs.wndMessage:Show(true)
			Apollo.StopTimer("Taxi_MessageDisplayTimer")
			Apollo.CreateTimer("Taxi_MessageDisplayTimer", 4.000, false)
		end
	end
	self.tWndRefs.wndTooltip:Close()
	return true
end

function TaxiMap:OnContinentBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local tSelected = wndControl:GetData()
	self.bFarside = tSelected.bFarside == true
	self.tLastSelectedSubzone = nil--Reset subzone every continent press

	if self.bFarside then
		local wndClearBtn = self.tWndRefs.wndMain:FindChild("ClearFarsideSubzoneBtn")
		if tSelected.bSubZone then
			local nSubZoneId = self.tZoneInfo.id
			if self.tZoneInfo.parentZoneId > 0 then
				nSubZoneId = self.tZoneInfo.parentZoneId
			end

			for idx, tSubZoneInfo in pairs(self.tWndRefs.wndTaxiMap:GetAllSubZoneInfo(nSubZoneId)) do
				if tSubZoneInfo.id == tSelected.nWorldId then
					self.tZoneInfo = tSubZoneInfo
					self.tLastSelectedSubzone = tSubZoneInfo
					break
				end
			end
			wndClearBtn:Enable(true)
		else
			self.tZoneInfo = self.tWndRefs.wndTaxiMap:GetZoneInfo(tSelected.nMapContinentId)
			wndClearBtn:Enable(false)
		end
	else
		for idx, tZone in pairs(self.tWndRefs.wndTaxiMap:GetContinentZoneInfo(tSelected.nMapContinentId)) do
			if tZone.nWorldId == tSelected.nWorldId  then
				self.tZoneInfo = tZone
				break
			end
		end
	end

	self.tWndRefs.wndMain:FindChild("ZoneList"):Show(false)
	self.tWndRefs.wndMain:FindChild("SubzoneList"):Show(false)
	
	self:PopulateTaxiMap()
end

function TaxiMap:OnReturnBtn(wndHandler, wndControl)
	local tHomeInfo = wndControl:GetData()
	if not tHomeInfo or (not self.tWndRefs.wndWorldView:IsShown() and self.tZoneInfo.id == tHomeInfo.tHomeZone.id) then
		return
	end

	local eSetView = nil
	if HousingLib.IsHousingWorld() then
		eSetView = ZoneMapWindow.CodeEnumDisplayMode.World
		self.tWndRefs.wndWorldView:Show(true)
		self.tWndRefs.wndMain:FindChild("ZoneToggle"):SetText(Apollo.GetString("ZoneCompletion_WorldCompletion"))
		self.tWndRefs.wndMain:FindChild("SubzoneToggle"):Show(false)

		--For the case we hit return from a subzone, make sure we reset the view to parent first.
		if self.tZoneInfo.parentZoneId > 0 then
			self.tZoneInfo = self.tWndRefs.wndTaxiMap:GetZoneInfo(self.tZoneInfo.parentZoneId)
		end
	else
		self.tZoneInfo = tHomeInfo.tHomeZone
		self:PopulateTaxiMap()
		self.tWndRefs.wndTaxiMap:SetZone(self.tZoneInfo.id)
		eSetView = tHomeInfo.eHomeView
		self.tWndRefs.wndTaxiMap:SetDisplayMode(tHomeInfo.eHomeView)
		self.tWndRefs.wndWorldView:Show(false)
	end

	if eSetView then
		self.tWndRefs.wndTaxiMap:SetDisplayMode(eSetView)
		self.eOldZoomLevel = eSetView
	end 
end

function TaxiMap:OnZoomInBtn()
	if not self.eOldZoomLevel then
		return
	end

	self:OnMouseScroll(self.eOldZoomLevel - 1)
end

function TaxiMap:OnZoomOutBtn()
	if not self.eOldZoomLevel or self.tWndRefs.wndWorldView:IsShown() then
		return
	end

	self:OnMouseScroll(self.eOldZoomLevel + 1)
end

function TaxiMap:OnMouseScroll(eDisplayMode)
	if self.unitTaxi or not self.tWndRefs.wndTaxiMap or not self.tWndRefs.wndTaxiMap:IsShown() then
		return
	end

	if eDisplayMode < self.eOldZoomLevel then--Zooming in
		if self.bFarside then
			eDisplayMode = ZoneMapWindow.CodeEnumDisplayMode.Scaled
			self.tWndRefs.wndTaxiMap:SetDisplayMode(eDisplayMode)
			if not self.tWndRefs.wndWorldView:IsShown() and self.tLastSelectedSubzone then
				self.tZoneInfo = self.tLastSelectedSubzone
			end
		else
			eDisplayMode = ZoneMapWindow.CodeEnumDisplayMode.Continent
		end
	elseif eDisplayMode >= self.eOldZoomLevel then--Zooming out
		if self.bFarside and self.tZoneInfo.parentZoneId > 0 then
			self.tZoneInfo = self.tWndRefs.wndTaxiMap:GetZoneInfo(self.tZoneInfo.parentZoneId)
			eDisplayMode = ZoneMapWindow.CodeEnumDisplayMode.Scaled
		end
		self.tWndRefs.wndTaxiMap:SetDisplayMode(eDisplayMode)
	end

	self.bZoomSetView = true
	self.eOldZoomLevel = eDisplayMode
	self:PopulateTaxiMap()
end

-----------------------------------------------------------------------------------------------
function TaxiMap:OnMouseMove(wndHandler, wndControl, nX, nY)
	self.tWndRefs.wndTooltip:Close()

	local tPos = self.tWndRefs.wndTaxiMap:WindowPointToClientPoint(nX, nY)

	local tObjects = self.tWndRefs.wndTaxiMap:GetObjectsAt(tPos.x, tPos.y)
	if not tObjects then
		return
	end

	for key, tObject in pairs(tObjects) do
		local tTaxi = self.tTaxiObjects[tObject.id]
		local tPrices = {}
		if tTaxi then
			if tTaxi.bUnlocked then
				if self.unitTaxi then
					local tPath = self.tTaxiRoutes[tTaxi.idNode]
					if tPath == nil then
						tPath = self.unitTaxi:GetFlightPathToPoint(tTaxi.idNode)
						if tPath ~= nil then
							self.tTaxiRoutes[tTaxi.idNode] = tPath
						end
					end
							
					if tPath ~= nil then
						if tPath and self.nTaxiUnderCursor ~= tTaxi.idNode then
							self.nTaxiUnderCursor = tTaxi.idNode
							self.tWndRefs.wndTaxiMap:RemoveAllLines()
							local nPrev = 0
							for idx, idNode in ipairs(tPath.tRoute) do
								if nPrev ~= 0 then
									self.tWndRefs.wndTaxiMap:AddLine(self.tTaxiNodes[nPrev].tLocation, self.tTaxiNodes[idNode].tLocation, 5.0, CColor.new(1, 1, 1, 1), "", "")
								end
								nPrev = idNode
							end
						end
						tPrices.monPrice = tPath.tPriceInfo.monPrice1
					end
				else--Rapid Transport
					tPrices.monPrice = tTaxi.monCostRapidTransport
					if tTaxi.monAltCostRapidTransport then
						tPrices.monAltPrice = tTaxi.monAltCostRapidTransport
					end
				end
			end
			self:OnGenerateTooltip(tTaxi, tPrices)
		end
	end
end

function TaxiMap:OnGenerateTooltip(tTooltipObject, tPrices)
	local strName = tTooltipObject.strName
	if tTooltipObject.nRecommendedMinLevel and tTooltipObject.nRecommendedMaxLevel then
		strName = String_GetWeaselString(Apollo.GetString("TaxiMap_LocationNameTooltip"), tTooltipObject.strName, tTooltipObject.nRecommendedMinLevel, tTooltipObject.nRecommendedMaxLevel)
	end

	local wndPrice = nil
	local bWasError = false
	local strError = ""
	local bRapidTransport = self.unitTaxi == nil
	if bRapidTransport then
		wndPrice = self.tWndRefs.wndTooltip:FindChild("RTPrice")

		if tTooltipObject.nAutoUnlockLevel > GameLib.GetPlayerLevel(true) then--Passing true will get actual level, not mentored level.
			strError = String_GetWeaselString(Apollo.GetString("TaxiMap_RapidTransportLevelTooLow"), tTooltipObject.nAutoUnlockLevel)
			bWasError = true
		elseif tTooltipObject.bTransportAllowed == false or tTooltipObject.bUnlocked == false then
			strError = Apollo.GetString("TaxiMap_RapidTransportBlocked")
			bWasError = true
		end

	else--TaxiNode
		wndPrice = self.tWndRefs.wndTooltip:FindChild("Price")
		if self.tTaxiRoutes[tTooltipObject.idNode] == nil then
			strError = Apollo.GetString("TaxiMap_CantRoute")
			bWasError = true
		elseif not tTooltipObject.bUnlocked then
			strError = Apollo.GetString("TaxiMap_NotUnlocked")
			bWasError = true
		elseif tPrices and not tPrices.monPrice then
			strError = Apollo.GetString("TaxiMap_RapidTransportBlocked")
			bWasError = true
		end
	end

	local eCurrency = nil
	local nPlayerAmount = nil
	local wndAvailableAmount = self.tWndRefs.wndTooltip:FindChild("AvailableAmount")
	local wndAvailableText = self.tWndRefs.wndTooltip:FindChild("Available")
	
	self.tWndRefs.wndTooltip:FindChild("Available"):Show(false)

	if tPrices and tPrices.monPrice then--Nodes that are locked will not have a monPrice!
		if tPrices.monPrice:GetAccountCurrencyType() ~= 0 then
			eCurrency = tPrices.monPrice:GetAccountCurrencyType()
			local monAccount = AccountItemLib.GetAccountCurrency(eCurrency)
			nPlayerAmount = monAccount:GetAmount()
			wndAvailableAmount:SetAmount(monAccount, true)
			wndAvailableAmount:Show(true)
			wndAvailableText:Show(true)
		else
			eCurrency = tPrices.monPrice:GetMoneyType()
			nPlayerAmount =  GameLib.GetPlayerCurrency(eCurrency):GetAmount()
			wndAvailableAmount:Show(false)
			wndAvailableText:Show(false)
		end

		local nPrice = tPrices.monPrice:GetAmount()
		self.bCantAfford = nPlayerAmount < nPrice
		local strTextColor = "ffffffff"
		if self.bCantAfford == true then
			strTextColor = "Reddish"
		end
		wndPrice:SetAmount(tPrices.monPrice, true)
		wndPrice:SetTextColor(strTextColor)
		wndPrice:GetParent():FindChild("CostText"):SetTextColor(strTextColor)
		self.tPrices = tPrices
	end
	local wndDetails = self.tWndRefs.wndTooltip:FindChild("Details")
	wndDetails:SetAML("<P Font=\"CRB_HeaderTiny\" TextColor=\"UI_TextHoloTitle\">"..strName.."</P>")
	wndDetails:SetHeightToContentHeight()
	self.tWndRefs.wndTooltip:FindChild("ErrorText"):SetText(strError)
	self.tWndRefs.wndTooltip:FindChild("TaxiContent"):Show(not bWasError and not bRapidTransport)
	self.tWndRefs.wndTooltip:FindChild("RapidTransportContent"):Show(not bWasError and bRapidTransport)
	self.tWndRefs.wndTooltip:FindChild("Error"):Show(bWasError)
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndTooltip:GetAnchorOffsets()
	local nContentHeight = self.tWndRefs.wndTooltip:FindChild("Error"):GetHeight() + wndDetails:GetHeight()
	self.tWndRefs.wndTooltip:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nContentHeight)
	self.tWndRefs.wndTooltip:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	self.tWndRefs.wndTaxiMap:SetTooltipForm(self.tWndRefs.wndTooltip)
	self.tWndRefs.wndTooltip:Invoke()
end

function TaxiMap:UpdateTimeString()
	local nCooldown = GameLib.GetRapidTransportCooldown()
	local bOnCoolDown = nCooldown >= 0
	local strCoolDown = String_GetWeaselString(Apollo.GetString("TaxiMap_Cooldown"), ConvertSecondsToTimer(nCooldown))
	local wndCooldown = self.tWndRefs.wndMain:FindChild("Cooldown")
	wndCooldown:SetText(strCoolDown)
	wndCooldown:Show(bOnCoolDown)
	
	if self.tWndRefs.wndRapidTransportPrompt and self.tWndRefs.wndRapidTransportPrompt:IsValid() then
		local wndPromptCooldown = self.tWndRefs.wndRapidTransportPrompt:FindChild("Cooldown")
		wndPromptCooldown:SetText(strCoolDown)
		wndPromptCooldown:Show(bOnCoolDown)

		if not bOnCoolDown and self.tPrices and self.tPrices.monAltPrice then
			local wndPrice = self.tWndRefs.wndRapidTransportPrompt:FindChild("Price")
			wndPrice:SetAmount(self.tPrices.monAltPrice, true)

			local nPrice = self.tPrices.monAltPrice:GetAmount()
			local nPlayerAmount =  GameLib.GetPlayerCurrency(self.tPrices.monAltPrice:GetMoneyType()):GetAmount()
			self.bCantAfford = nPlayerAmount < nPrice
			local strTextColor = "ffffffff"
			if self.bCantAfford == true then
				strTextColor = "Reddish"
			end
			wndPrice:SetTextColor(strTextColor)

			local wndRapidTransportConfirm = self.tWndRefs.wndRapidTransportPrompt:FindChild("RapidTransportConfirm")
			wndRapidTransportConfirm:Enable(not self.bCantAfford)
			wndRapidTransportConfirm:Show(true)
			self.tWndRefs.wndRapidTransportPrompt:FindChild("BuyBtn"):Show(false)--Hide service token buy button
		end
	end

	if not bOnCoolDown then
		self.timerCooldown:Stop()
	end
end

-----------------------------------------------------------------------------------------------
function TaxiMap:OnMessageDisplayTimer()
	if self.tWndRefs.wndMessage then
		self.tWndRefs.wndMessage:Show(false)
	end
end

-----------------------------------------------------------------------------------------------
-- TaxiMap Instance
-----------------------------------------------------------------------------------------------
local TaxiMapInst = TaxiMap:new()
TaxiMapInst:Init()
