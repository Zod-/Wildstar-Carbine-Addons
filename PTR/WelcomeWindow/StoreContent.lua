-----------------------------------------------------------------------------------------------
-- Client Lua Script for WelcomeWindow/StoreContent
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
local StoreContent = {} 
 
function StoreContent:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.kstrTitle = Apollo.GetString("StoreContent_Title")
	o.knRotationTime = 8
	o.kbRotationContinous = true
	o.keDirection = {Next = 0, Previous = 1}
    return o
end

function StoreContent:Init()
    Apollo.RegisterAddon(self, false, self.kstrTitle)
end
 
function StoreContent:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("StoreContent.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function StoreContent:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end

	self.timerBannerRotation = ApolloTimer.Create(self.knRotationTime, self.kbRotationContinous, "OnBannerRotationTimer", self)
	self.timerBannerRotation:Stop()

	--WelcomeWindow Events
	Apollo.RegisterEventHandler("WelcomeWindow_TabSelected",	"OnWelcomeWindowTabSelected", self)
	Apollo.RegisterEventHandler("WelcomeWindow_Closed",			"OnClose", self)

	Apollo.RegisterEventHandler("OverView_Loaded", 	"OnOverViewLoaded", self)
	Event_FireGenericEvent("OverView_RequestParent")

	--Store Events
	Apollo.RegisterEventHandler("StoreLinksRefresh",	"OnRefreshStoreLink", self)
	Apollo.RegisterEventHandler("StoreBannersReady",	"OnStoreBannersReady", self)
end

function StoreContent:OnOverViewLoaded(strOverViewTitle, wndParent)
	if not wndParent or not wndParent:IsValid() then
		return
	end

	Apollo.RemoveEventHandler("OverView_Loaded", self)

	self.strOverViewTitle = strOverViewTitle--Used to determine if the Overview Tab is selected.
	self.wndBannerContainer = wndParent:FindChild("StoreContent")

	if StorefrontLib.IsStoreReady() then
		self:InitializeContent()
		self:DrawBanner()
	end
end

function StoreContent:InitializeContent()
	self.arBanners = {}
	local tAllBanners = StorefrontLib.GetBanners()
	for idx, tCurBanner in pairs(tAllBanners) do
		if tCurBanner.eLocation == StorefrontLib.CodeEnumBannerLocation.RotatingBannerLocation then
			table.insert(self.arBanners, tCurBanner)
		end
	end

	self.nBannerIndex = 0
	self.nNumBanners = #self.arBanners
	self.wndBannerContainer:DestroyChildren()

	if self.nNumBanners > 0 then
		self.nBannerIndex = 1
		self.wndBanner = Apollo.LoadForm(self.xmlDoc, "Banner", self.wndBannerContainer, self)

		self.wndBanner:FindChild("NextBtn"):SetData(self.keDirection.Next)
		self.wndBanner:FindChild("PreviousBtn"):SetData(self.keDirection.Previous)
	end
end

function StoreContent:OnRefreshStoreLink()
	if not self.wndBannerContainer or not self.wndBannerContainer:IsShown() then
		return
	end

	self:InitializeContent()
	self:DrawBanner()
end

function StoreContent:OnStoreBannersReady()
	if not self.wndBannerContainer or not self.wndBannerContainer:IsShown() then
		return
	end

	self:InitializeContent()
	self:DrawBanner()
end

function StoreContent:DrawBanner()
	local tCurBanner = self.arBanners[self.nBannerIndex]
	if not tCurBanner then
		return
	end

	local strAsset = ""
	if tCurBanner.strBannerAsset ~= nil then
		strAsset = tCurBanner.strBannerAsset
	end
	self.wndBanner:FindChild("Image"):SetSprite(strAsset)

	local strTitle = ""
	if tCurBanner.strTitle ~= nil then
		strTitle = tCurBanner.strTitle
	end
	local wndTextContainer = self.wndBanner:FindChild("TextContainer")
	wndTextContainer:FindChild("ItemTitle"):SetText(strTitle)
	
	local strBody = ""
	if tCurBanner.strBody ~= nil then
		strBody = tCurBanner.strBody
	end
	local wndBody = wndTextContainer:FindChild("Body")
	wndBody:SetAML(string.format('<P Align="Bottom" Font="CRB_InterfaceSmall" TextColor="UI_TextHoloBody">%s</P>', strBody))
	wndBody:SetHeightToContentHeight()
	wndTextContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.RightOrBottom)
end

function StoreContent:OnWelcomeWindowTabSelected(strSelectedTab)
	if self.nNumBanners == nil or self.nNumBanners <= 0 then
		return
	end

	self.timerBannerRotation:Stop()
	if strSelectedTab == self.strOverViewTitle then
		self.timerBannerRotation:Start()
	end
end

--When Selecting an event btn, you are on the Main page, so only redraw Main section.
function StoreContent:OnBannerSignal(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local tCurBanner = self.arBanners[self.nBannerIndex]
	if not tCurBanner then
		return
	end

	self.timerBannerRotation:Stop()
	StorefrontLib.OpenStoreFromBannerLink(tCurBanner.nStoreBannerId)
end

function StoreContent:OnDirectionalArrow(wndHandler, wndControl)
	local eDirection = wndHandler:GetData()
	if eDirection == self.keDirection.Next then
		self:HelperIncrementCurrentIndex()
	elseif eDirection == self.keDirection.Previous then
		self:HelperDecrementCurrentIndex()
	end

	self.timerBannerRotation:Set(self.knRotationTime, self.kbRotationContinous)
	self:DrawBanner()
end

function StoreContent:HelperIncrementCurrentIndex()
	--Because LUA is 1 based, all results get + 1 to avoid an index of zero.
	self.nBannerIndex = (self.nBannerIndex % self.nNumBanners) + 1
end

function StoreContent:HelperDecrementCurrentIndex()
	--[[Because LUA is 1 based, all results get + 1 to avoid an index of zero.
		This messes up modulo logic, so we have to accomedate for that face.
		Subtract 2 because: 1 for decrementing, 1 to accomedate for adding 1 at the end of every result.]]--
	self.nBannerIndex = ((self.nBannerIndex + self.nNumBanners - 2) % self.nNumBanners) + 1
end

function StoreContent:OnBannerRotationTimer()
	if self.nNumBanners == 0 then
		self.timerBannerRotation:Stop()
		return
	end

	self:HelperIncrementCurrentIndex()
	self:DrawBanner()
end

function StoreContent:OnClose()
	self.timerBannerRotation:Stop()
end

-----------------------------------------------------------------------------------------------
-- StoreContent Instance
-----------------------------------------------------------------------------------------------
local StoreContentInst = StoreContent:new()
StoreContentInst:Init()
