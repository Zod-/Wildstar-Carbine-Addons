-----------------------------------------------------------------------------------------------
-- Client Lua Script for Storefront
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
require "PetFlair"
require "PetCustomization"
require "Unit"
require "Tooltip"
require "WindowLocation"
require "Sound"


local Storefront = {} 

function Storefront:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	o.tWndRefs = {}
	o.tNavCategoryWndRefs = {}
	o.tNavSubCategoryWndRefs = {}
	o.tRealTimeCountdownWndRefs = {}
	o.knEscapeKey = 27
	o.knNavigationTextPadding = 10
	o.knNavigationSubTextPadding = 3
	o.knItemVisibleTolerance = 5
	
	o.ktErrorMessages =
	{
		[StorefrontLib.CodeEnumStoreError.CatalogUnavailable] = Apollo.GetString("Storefront_ErrorCatalogUnavailable"),
		[StorefrontLib.CodeEnumStoreError.StoreDisabled] = Apollo.GetString("Storefront_ErrorStoreDisabled"),
		[StorefrontLib.CodeEnumStoreError.InvalidOffer] = Apollo.GetString("Storefront_ErrorInvalidOffer"),
		[StorefrontLib.CodeEnumStoreError.InvalidPrice] = Apollo.GetString("Storefront_ErrorInvalidPrice"),
		[StorefrontLib.CodeEnumStoreError.GenericFail] = Apollo.GetString("Storefront_ErrorGenericFail"),
		[StorefrontLib.CodeEnumStoreError.PurchasePending] = Apollo.GetString("Storefront_ErrorPurchasePending"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CartFraudFailure] = Apollo.GetString("Storefront_ErrorTransactionFailureContract"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CartPaymentFailure] = Apollo.GetString("Storefront_ErrorTransactionFailure"),
		[StorefrontLib.CodeEnumStoreError.PgWs_InvalidCCExpirationDate] = Apollo.GetString("Storefront_ErrorCardExpired"),
		[StorefrontLib.CodeEnumStoreError.PgWs_InvalidCreditCardNumber] = Apollo.GetString("Storefront_ErrorInvalidCard"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CreditCardExpired] = Apollo.GetString("Storefront_ErrorCardDeclinedExpired"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CreditCardDeclined] = Apollo.GetString("Storefront_ErrorCardDeclined"),
		[StorefrontLib.CodeEnumStoreError.PgWs_CreditFloorExceeded] = Apollo.GetString("Storefront_ErrorCardLimits"),
		[StorefrontLib.CodeEnumStoreError.PgWs_InventoryStatusFailure] = Apollo.GetString("Storefront_ErrorTransactionFailure"),
		[StorefrontLib.CodeEnumStoreError.PgWs_PaymentPostAuthFailure] = Apollo.GetString("Storefront_ErrorTransactionFailure"),
		[StorefrontLib.CodeEnumStoreError.PgWs_SubmitCartFailed] = Apollo.GetString("Storefront_ErrorTransactionFailure"),
		[StorefrontLib.CodeEnumStoreError.PurchaseVelocityLimit] = Apollo.GetString("Storefront_ErrorVelocityFailure"),
	}
	
	o.ktFlags =
	{
		[StorefrontLib.CodeEnumStoreDisplayFlag.New] = { sprCallout = "MTX:UI_BK3_MTX_Callout_ItemGreen", strTooltip = Apollo.GetString("Storefront_OfferFlagNewTooltip") },
		[StorefrontLib.CodeEnumStoreDisplayFlag.Recommended] = { sprCallout = "MTX:UI_BK3_MTX_Callout_ItemYellow", strTooltip = Apollo.GetString("Storefront_OfferFlagRecommendedTooltip") },
		[StorefrontLib.CodeEnumStoreDisplayFlag.Popular] = { sprCallout = "MTX:UI_BK3_MTX_Callout_ItemRed", strTooltip = Apollo.GetString("Storefront_OfferFlagPopularTooltip") },
		[StorefrontLib.CodeEnumStoreDisplayFlag.LimitedTime] = { sprCallout = "MTX:UI_BK3_MTX_Callout_ItemPurple", strTooltip = Apollo.GetString("Storefront_OfferFlagLimitedTimeTooltip") }
	}
	
	o.ktClassAnimation =
	{
		[GameLib.CodeEnumClass.Spellslinger] = { eStand = StorefrontLib.CodeEnumModelSequence.PistolsStand, eReady = StorefrontLib.CodeEnumModelSequence.PistolsReady },
		[GameLib.CodeEnumClass.Stalker] = { eStand = StorefrontLib.CodeEnumModelSequence.ClawsStand, eReady = StorefrontLib.CodeEnumModelSequence.ClawsReady },
		[GameLib.CodeEnumClass.Engineer] = { eStand = StorefrontLib.CodeEnumModelSequence.TwoHGunStand, eReady = StorefrontLib.CodeEnumModelSequence.HeavyGunReady },
		[GameLib.CodeEnumClass.Warrior] = { eStand = StorefrontLib.CodeEnumModelSequence.TwoHStand, eReady = StorefrontLib.CodeEnumModelSequence.TwoHReady },
		[GameLib.CodeEnumClass.Esper] = { eStand = StorefrontLib.CodeEnumModelSequence.DefaultStand, eReady = StorefrontLib.CodeEnumModelSequence.EsperReady },
		[GameLib.CodeEnumClass.Medic] = { eStand = StorefrontLib.CodeEnumModelSequence.ShockPaddlesStand, eReady = StorefrontLib.CodeEnumModelSequence.ShockPaddlesReady },
	}
	
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
	
    o.ktTutorialBtn =
	{
		["Basic"] = 0,
		["OpenInventory"] = 1,
		["ConfirmSelfBuyItem"] = 2,
		["BuyItem"] = 3,
		["Items"] = 4,
		["SubCategory"] = 5,
		["Category"] = 6,
	}
	
	o.ktTutorialCalloutNames =
	{
		"TutorialCallout_OpenInventory",
		"TutorialCallout_ConfirmSelfBuyItem",
		"TutorialCallout_BuyItem",
		"TutorialCallout_ChooseItems",
		"TutorialCallout_ChooseSubCategory",
		"TutorialCallout_ChooseCategory",
	}
	
    return o
end

function Storefront:Init()
    Apollo.RegisterAddon(self)
end

function Storefront:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Storefront.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	self.ktSlotMapping =
	{
		[Item.CodeEnumItemType.HoverboardFront] = PetCustomizationLib.HoverboardSlot.Front,
		[Item.CodeEnumItemType.HoverboardBack] = PetCustomizationLib.HoverboardSlot.Back,
		[Item.CodeEnumItemType.HoverboardSides] = PetCustomizationLib.HoverboardSlot.Sides,
		[Item.CodeEnumItemType.MountFront] = PetCustomizationLib.MountSlot.Front,
		[Item.CodeEnumItemType.MountBack] = PetCustomizationLib.MountSlot.Back,
		[Item.CodeEnumItemType.MountLeft] = PetCustomizationLib.MountSlot.Left,
		[Item.CodeEnumItemType.MountRight] = PetCustomizationLib.MountSlot.Right,
	}
end

function Storefront:OnDocumentReady()
	Apollo.RegisterEventHandler("SystemKeyDown", "OnSystemKeyDown", self)
	Apollo.RegisterEventHandler("OpenStore", "OnOpenStore", self)
	Apollo.RegisterEventHandler("OpenStoreLinkSingle", "OnOpenStoreLinkSingle", self)
	Apollo.RegisterEventHandler("OpenStoreLinkCategory", "OnOpenStoreLinkCategory", self)
	Apollo.RegisterEventHandler("OpenStoreFromBanner", "OnOpenStoreFromBanner", self)
	Apollo.RegisterEventHandler("OpenSignature", "OnOpenSignature", self)
	Apollo.RegisterEventHandler("StoreClosed", "OnStoreClosed", self)
	Apollo.RegisterEventHandler("AccountInventoryWindowShow", "OnAccountInventoryWindowShow", self)
	
	Apollo.RegisterEventHandler("StoreCatalogReady", "OnStoreCatalogReady", self)
	Apollo.RegisterEventHandler("StoreError", "OnStoreError", self)
	Apollo.RegisterEventHandler("StoreCatalogUpdated", "OnStoreCatalogUpdated", self)
	Apollo.RegisterEventHandler("StoreBannersReady", "OnStoreBannersReady", self)
	
	Apollo.RegisterEventHandler("AccountCurrencyChanged", "OnAccountCurrencyChanged", self)
	Apollo.RegisterEventHandler("AccountEntitlementUpdate", "OnEntitlementUpdate", self)
	Apollo.RegisterEventHandler("CharacterEntitlementUpdate", "OnEntitlementUpdate", self)
	
	Apollo.RegisterEventHandler("PurchaseConfirmed", "PurchaseConfirmed", self)
	
	Apollo.RegisterEventHandler("ShowDialog", "OnShowDialog", self)
	Apollo.RegisterEventHandler("RequestFullDialogPrompt", "OnRequestFullDialogPrompt", self)
	Apollo.RegisterEventHandler("RequestFullDialogSpinner", "OnRequestFullDialogSpinner", self)
	Apollo.RegisterEventHandler("HideFullDialog", "OnHideFullDialog", self)
	Apollo.RegisterEventHandler("RequestHeaderDisplay", "OnRequestHeaderDisplay", self)
	Apollo.RegisterEventHandler("RequestContinueShopping", "OnContinueShoppingSignal", self)
	Apollo.RegisterEventHandler("RequestContinueOffer", "OnRequestContinueOffer", self)
	Apollo.RegisterEventHandler("RequestTopupDialog", "OnAddFundsSignal", self)
	

	self.timerBannerRotation = ApolloTimer.Create(10, true, "OnBannerRotationTimer", self)
	self.timerBannerRotation:Stop()
	
	self.timerRealTimeUpdate = ApolloTimer.Create(1.0, true, "OnRealTimeUpdateTimer", self)
	self.timerRealTimeUpdate:Stop()
	
	self.timerSearch = ApolloTimer.Create(1.0, false, "OnSearchTimer", self)
	self.timerSearch:Stop()
	
	self.tSortingOptions = {}
	self.nFilterOptions = 0
	self.bPrefAltCurrency = false
	self.timerToMax = ApolloTimer.Create(1.0, false, "OnMaximumReached", self)
	self.timerToMax:Stop()

	local wndMain = Apollo.LoadForm(self.xmlDoc, "Layout", nil, self)
	self.tWndRefs.wndMain = wndMain
	
	-- Header
	self.wndHeader = wndMain:FindChild("Header")
	self.tWndRefs.wndWalletAlternative = wndMain:FindChild("Header:Wallet:CurrencyContainer:Currency:Alternative")
	self.tWndRefs.wndWalletPremium = wndMain:FindChild("Header:Wallet:CurrencyContainer:Currency:Premium")
	self.wndTopUpReminder = wndMain:FindChild("Header:Wallet:CurrencyContainer:TopUp:TopUpBtn:TopUpReminder")
	self.wndHistoryBtn = wndMain:FindChild("Header:Wallet:HistoryBtn")
	self.tWndRefs.wndWallet = wndMain:FindChild("Header:Wallet")
	self.tWndRefs.wndWalletCurrencyContainer = wndMain:FindChild("Header:Wallet:CurrencyContainer")
	self.tWndRefs.wndWalletTopUp = wndMain:FindChild("Header:Wallet:CurrencyContainer:TopUp")
	
	-- Categories
	self.tWndRefs.wndNavigation = wndMain:FindChild("Navigation")
	
	-- Dialog
	self.tWndRefs.wndModelDialog = wndMain:FindChild("ModelDialog")
	self.tWndRefs.wndModelDialogBlocker = wndMain:FindChild("ModelDialog:Blocker")
	Event_FireGenericEvent("AddHeaderDisplay", self.wndHeader, self.tWndRefs.wndModelDialog)
	
	-- Center
	self.tWndRefs.wndCenter = wndMain:FindChild("Center")
	
	-- Center Splash
	self.tWndRefs.wndSplash = wndMain:FindChild("Center:Splash")
	self.tWndRefs.wndSplashItems = wndMain:FindChild("Center:Splash:Items")
	self.tWndRefs.wndSplashHeaderContent = wndMain:FindChild("Center:Splash:HeaderContent")
	self.tWndRefs.wndSplashBannerRotationContainer = wndMain:FindChild("Center:Splash:HeaderContent:RotatingBanner:BannerRotationContainer")
	self.tWndRefs.wndSplashRightBanner = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner")
	self.tWndRefs.wndSplashRightTopBanner = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:TopBanner")
	self.tWndRefs.wndSplashRightTopBtn = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:TopBanner:TopBannerBtn")
	self.tWndRefs.wndSplashRightTopImage = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:TopBanner:ImageTop")
	self.tWndRefs.wndSplashRightTopLabel = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:TopBanner:LabelTop")
	self.tWndRefs.wndSplashRightBottomBanner = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:BottomBanner")
	self.tWndRefs.wndSplashRightBottomBtn = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:BottomBanner:BottomBannerBtn")
	self.tWndRefs.wndSplashRightBottomImage = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:BottomBanner:ImageBtm")
	self.tWndRefs.wndSplashRightBottomLabel = wndMain:FindChild("Center:Splash:HeaderContent:RightBanner:BottomBanner:LabelBtm")
	
	-- Center Offer List
	self.tWndRefs.wndCenterContent = wndMain:FindChild("Center:Content")
	self.tWndRefs.wndCenterFilters = wndMain:FindChild("Center:Content:Filters")
	self.tWndRefs.wndCenterFiltersSortBtn = wndMain:FindChild("Center:Content:Filters:SortBtn")
	self.tWndRefs.wndCenterFiltersSortBtn:AttachWindow(self.tWndRefs.wndCenterFiltersSortBtn:FindChild("Expander"))
	self.tWndRefs.wndCenterItemsContainer = wndMain:FindChild("Center:Content:Items")
	self.tWndRefs.wndCenterContentEmptyDisplay = wndMain:FindChild("Center:Content:EmptyDisplay")
	self.tWndRefs.wndCenterContentNoResultsDisplay = wndMain:FindChild("Center:Content:NoResultsDisplay")
	self.tWndRefs.wndFilterNewestBtn = self.tWndRefs.wndCenterFiltersSortBtn:FindChild("Expander:Container:NewestBtn")
	self.tWndRefs.wndFilterRecommendedBtn = self.tWndRefs.wndCenterFiltersSortBtn:FindChild("Expander:Container:RecommendedBtn")
	self.tWndRefs.wndFilterPopularBtn = self.tWndRefs.wndCenterFiltersSortBtn:FindChild("Expander:Container:PopularBtn")
	self.tWndRefs.wndFilterLimitedTimeBtn = self.tWndRefs.wndCenterFiltersSortBtn:FindChild("Expander:Container:LimitedTimeBtn")
	
	-- Purchase
	self.tWndRefs.wndCenterPurchase = wndMain:FindChild("Center:PurchaseDialog")
	self.tWndRefs.wndCenterPurchaseScrollContent = wndMain:FindChild("Center:PurchaseDialog:ScrollContent")
	self.tWndRefs.wndCenterPurchaseExclusiveBG = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:LeftFraming:ExclusiveBurst")
	self.tWndRefs.wndCenterPurchaseLeft = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Left")
	self.tWndRefs.wndCenterPurchaseRight = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right")
	self.tWndRefs.wndCenterPurchasePreview = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Left:Preview:PreviewFrame")
	self.tWndRefs.wndCenterPurchaseDecor = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Left:Preview:DecorFrame")
	self.tWndRefs.wndCenterPurchasePreviewOnMeBtn = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Left:Preview:PreviewOnMeBtn")
	self.tWndRefs.wndCenterPurchasePreviewSheathedBtn = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Left:Preview:PreviewSheathedBtn")
	self.tWndRefs.wndCenterPurchaseCancelBtn = wndMain:FindChild("Center:PurchaseDialog:CancelBtn")
	self.tWndRefs.wndCenterPurchaseBackBtn = wndMain:FindChild("Center:PurchaseDialog:BackBtn")
	
	-- Purchase Confirm
	self.tWndRefs.wndCenterPurchaseConfirm = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm")
	self.tWndRefs.wndCenterPurchaseConfirmItemName = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Left:ItemName")
	self.tWndRefs.wndCenterPurchaseConfirmBannerSection = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:BannerSection")
	self.tWndRefs.wndCenterPurchaseConfirmBannerContainer = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:BannerSection:Container")
	self.tWndRefs.wndCenterPurchaseConfirmDescription = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Left:Description")
	self.tWndRefs.wndCenterPurchaseConfirmQuantitySection = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:QuantitySection")
	self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdownBtn = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:QuantitySection:QuantityDropdownBtn")
	self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdown = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:QuantityDropdown")
	self.tWndRefs.wndCenterPurchaseConfirmQuantityCostContainer = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:QuantitySection:QuantityDropdownBtn:CostContainer")
	self.tWndRefs.wndCenterPurchaseConfirmQuantityPrice1 = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:QuantitySection:QuantityDropdownBtn:CostContainer:Price1")
	self.tWndRefs.wndCenterPurchaseConfirmQuantityPriceOr = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:QuantitySection:QuantityDropdownBtn:CostContainer:or")
	self.tWndRefs.wndCenterPurchaseConfirmQuantityPrice2 = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:QuantitySection:QuantityDropdownBtn:CostContainer:Price2")
	self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdownContainer = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:QuantityDropdown:DropDownContainer")
	self.tWndRefs.wndCenterPurchaseConfirmVariantSection = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:VariantSection")
	self.tWndRefs.wndCenterPurchaseConfirmVariantContainer = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:VariantSection:Container")
	self.tWndRefs.wndCenterPurchaseConfirmBundleSection = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:BundleSection")
	self.tWndRefs.wndCenterPurchaseConfirmBundleContainer = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:BundleSection:Container")
	self.tWndRefs.wndCenterPurchaseConfirmCurrencySection = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency1Container = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency1")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency1 = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency1:CurrencyBtn:Price")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency1:CurrencyBtn")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency2Container = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency2")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency2 = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency2:CurrencyBtn:Price")
	self.tWndRefs.wndCenterPurchaseConfirmCurrency2Btn = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:CurrencyChoiceSection:Currency2:CurrencyBtn")
	self.tWndRefs.wndCenterPurchaseConfirmValidationNotification = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:ValidationNotification")
	self.tWndRefs.wndCenterPurchaseConfirmValidationNotificationText = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:ValidationNotification:Text")
	self.tWndRefs.wndCenterPurchaseConfirmValidationNotificationAlertIcon = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:ValidationNotification:AlertIcon")
	self.tWndRefs.wndCenterPurchaseConfirmPremiumNotification = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:PremiumNotification")
	self.tWndRefs.wndCenterPurchaseConfirmSummaryContainer = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer")
	self.tWndRefs.wndCenterPurchaseConfirmSignatureExclusiveLabel = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer:SignatureExclusive")
	self.tWndRefs.wndCenterPurchaseConfirmAlertClaimTooltip = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer:PurchaseOptions:FinalizeBtn:AlertClaimTooltip")
	self.tWndRefs.wndCenterPurchaseConfirmAlertClaimTooltipBody = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer:PurchaseOptions:FinalizeBtn:AlertClaimTooltip:Body")
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterLabel = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer:FundsAfter:FundsAfterLabel")
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer:FundsAfter:FundsAfterValueNegative")
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer:FundsAfter:FundsAfterValue")
	self.tWndRefs.wndCenterPurchaseConfirmNotEnoughAlternativeCurrency = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:NotEnoughAlternativeCurrency")
	self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer:PurchaseOptions:FinalizeBtn")
	self.tWndRefs.wndCenterPurchaseConfirmGiftBtn = wndMain:FindChild("Center:PurchaseDialog:ScrollContent:Right:PurchaseConfirm:SummaryContainer:PurchaseOptions:GiftBtn")
	self.tWndRefs.wndCenterPurchaseConfirmDisclaimer = wndMain:FindChild("Center:PurchaseDialog:Disclaimer")
	
	-- Purchase Self
	self.tWndRefs.wndCenterPurchaseSelf = wndMain:FindChild("Center:PurchaseDialog:PurchaseSelf")
	self.tWndRefs.wndCenterPurchaseSelfItemName = wndMain:FindChild("Center:PurchaseDialog:PurchaseSelf:FramingContainer:ItemName")
	self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtn = wndMain:FindChild("Center:PurchaseDialog:PurchaseSelf:FramingContainer:AltDropdownBtn")
	self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtnDropdown = wndMain:FindChild("Center:PurchaseDialog:PurchaseSelf:AltDropdown")
	self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtnDropdownContainer = wndMain:FindChild("Center:PurchaseDialog:PurchaseSelf:AltDropdown:DropDownContainer")
	self.tWndRefs.wndCenterPurchaseSelfConfirmBtn = wndMain:FindChild("Center:PurchaseDialog:PurchaseSelf:FramingContainer:ConfirmBtn")
	
	-- Purchase Gifting
	self.tWndRefs.wndCenterPurchaseGifting = wndMain:FindChild("Center:PurchaseDialog:PurchaseGifting")
	self.tWndRefs.wndCenterPurchaseGiftingTitle = wndMain:FindChild("Center:PurchaseDialog:PurchaseGifting:GiftingContainer:Container:Title")
	self.tWndRefs.wndCenterPurchaseGiftingFriendGiftConfirmContainer = wndMain:FindChild("Center:PurchaseDialog:PurchaseGifting:GiftingContainer:Container:FriendGiftConfirmContainer")
	self.tWndRefs.wndCenterPurchaseGiftingCharacterNameEditBox = wndMain:FindChild("Center:PurchaseDialog:PurchaseGifting:GiftingContainer:Container:CharacterName:EditBox")
	self.tWndRefs.wndCenterPurchaseGiftingCharacterNameClearBtn = wndMain:FindChild("Center:PurchaseDialog:PurchaseGifting:GiftingContainer:Container:CharacterName:ClearBtn")
	self.tWndRefs.wndCenterPurchaseGiftingShowAltsBtn = wndMain:FindChild("Center:PurchaseDialog:PurchaseGifting:GiftingContainer:Container:ShowAltsBtn")
	self.tWndRefs.wndCenterPurchaseGiftingConfirmBtn = wndMain:FindChild("Center:PurchaseDialog:PurchaseGifting:GiftingContainer:Container:ConfirmBtn")
	self.tWndRefs.wndCenterPurchaseGiftingPriceValue = wndMain:FindChild("Center:PurchaseDialog:PurchaseGifting:GiftingContainer:Container:ConfirmBtn:FundsAfterValue")
	
	-- Purchase Confirmed
	self.tWndRefs.wndCenterPurchaseConfirmed = wndMain:FindChild("Center:PurchaseDialog:PurchaseConfirmed")
	self.tWndRefs.wndCenterPurchaseConfirmedFramingContainer = wndMain:FindChild("Center:PurchaseDialog:PurchaseConfirmed:FramingContainer")
	self.tWndRefs.wndCenterPurchaseConfirmedItemName = wndMain:FindChild("Center:PurchaseDialog:PurchaseConfirmed:FramingContainer:ItemName")
	self.tWndRefs.wndCenterPurchaseConfirmedClaimDetails = wndMain:FindChild("Center:PurchaseDialog:PurchaseConfirmed:FramingContainer:ClaimDetails")
	self.tWndRefs.wndCenterPurchaseConfirmedCostLabel = wndMain:FindChild("Center:PurchaseDialog:PurchaseConfirmed:FramingContainer:CostContainer:CostLabel")
	self.tWndRefs.wndCenterPurchaseConfirmedCostValue = wndMain:FindChild("Center:PurchaseDialog:PurchaseConfirmed:FramingContainer:CostContainer:CostValue")
	self.tWndRefs.wndCenterPurchaseConfirmedFundsAfterLabel = wndMain:FindChild("Center:PurchaseDialog:PurchaseConfirmed:FramingContainer:CostContainer:FundsAfterLabel")
	self.tWndRefs.wndCenterPurchaseConfirmedFundsAfterValue = wndMain:FindChild("Center:PurchaseDialog:PurchaseConfirmed:FramingContainer:CostContainer:FundsAfterValue")
	self.tWndRefs.wndCenterPurchaseConfirmedOpenInventoryBtn = wndMain:FindChild("Center:PurchaseDialog:PurchaseConfirmed:FramingContainer:OpenInventoryBtn")
	self.tWndRefs.wndCenterPurchaseConfirmedGotoFortunesBtn = wndMain:FindChild("Center:PurchaseDialog:PurchaseConfirmed:FramingContainer:GotoFortunesBtn")
	
	-- Purchase Confirmed Animation
	self.tWndRefs.wndCenterPurchaseConfirmedAnimation = wndMain:FindChild("Center:PurchaseDialog:PurchaseConfirmed:PurchaseConfirmAnimation")
	self.tWndRefs.wndCenterPurchaseConfirmedAnimationInner = wndMain:FindChild("Center:PurchaseDialog:PurchaseConfirmed:PurchaseConfirmAnimation:PurchaseConfirmAnimationInner")
	
	-- Full Blocker
	self.tWndRefs.wndFullBlocker = wndMain:FindChild("ModelDialog_FullScreen")
	self.tWndRefs.wndFullBlockerPrompt = wndMain:FindChild("ModelDialog_FullScreen:Prompt")
	self.tWndRefs.wndFullBlockerPromptHeader = wndMain:FindChild("ModelDialog_FullScreen:Prompt:Header")
	self.tWndRefs.wndFullBlockerPromptBody = wndMain:FindChild("ModelDialog_FullScreen:Prompt:Body")
	self.tWndRefs.wndFullBlockerPromptConfimBtn = wndMain:FindChild("ModelDialog_FullScreen:Prompt:ConfimBtn")
	self.tWndRefs.wndFullBlockerDelaySpinner = wndMain:FindChild("ModelDialog_FullScreen:DelaySpinner")
	self.tWndRefs.wndFullBlockerDelaySpinnerMessage = wndMain:FindChild("ModelDialog_FullScreen:DelaySpinner:BG:DelayMessage")
	
	-- Update Blocker
	self.tWndRefs.wndFullScreenUpdate = wndMain:FindChild("ModelDialog_FullScreenUpdate")
	
	-- Data Setup
	local arCurrencyActors =
	{
		{ key = "PremiumCurrency", name = self:GetCurrencyNameFromEnum(AccountItemLib.GetPremiumCurrency()) },
		{ key = "AlternativeCurrency", name = self:GetCurrencyNameFromEnum(AccountItemLib.GetAlternativeCurrency()) }
	}
		
	local wndContainer = self.tWndRefs.wndCenterFiltersSortBtn:FindChild("Container")
	wndContainer:FindChild("PremiumPrice"):SetText(String_GetWeaselString(Apollo.GetString("Storefront_PremiumCurrencyArrange"), unpack(arCurrencyActors)))
	wndContainer:FindChild("PremiumPrice:UpBtn"):SetTooltip(String_GetWeaselString(Apollo.GetString("Storefront_PremiumCurrencyHighToLow"), unpack(arCurrencyActors)))
	wndContainer:FindChild("PremiumPrice:DownBtn"):SetTooltip(String_GetWeaselString(Apollo.GetString("Storefront_PremiumCurrencyLowToHigh"), unpack(arCurrencyActors)))
	wndContainer:FindChild("PremiumPrice:UpBtn"):SetData({eCurrency = AccountItemLib.GetPremiumCurrency(), bIncreasingOrder = true})
	wndContainer:FindChild("PremiumPrice:DownBtn"):SetData({eCurrency = AccountItemLib.GetPremiumCurrency(), bIncreasingOrder = false})
			
	wndContainer:FindChild("AlternativePrice"):SetText(String_GetWeaselString(Apollo.GetString("Storefront_AlternativeCurrencyArrange"), unpack(arCurrencyActors)))
	wndContainer:FindChild("AlternativePrice:UpBtn"):SetTooltip(String_GetWeaselString(Apollo.GetString("Storefront_AlternativeCurrencyHighToLow"), unpack(arCurrencyActors)))
	wndContainer:FindChild("AlternativePrice:DownBtn"):SetTooltip(String_GetWeaselString(Apollo.GetString("Storefront_AlternativeCurrencyLowToHigh"), unpack(arCurrencyActors)))
	wndContainer:FindChild("AlternativePrice:UpBtn"):SetData({eCurrency = AccountItemLib.GetAlternativeCurrency(), bIncreasingOrder = true})
	wndContainer:FindChild("AlternativePrice:DownBtn"):SetData({eCurrency = AccountItemLib.GetAlternativeCurrency(), bIncreasingOrder = false})
			
	
	self.tWndRefs.wndFilterNewestBtn:SetData({eDisplayFlag = StorefrontLib.CodeEnumStoreDisplayFlag.New})
	self.tWndRefs.wndFilterRecommendedBtn:SetData({eDisplayFlag = StorefrontLib.CodeEnumStoreDisplayFlag.Recommended})
	self.tWndRefs.wndFilterPopularBtn:SetData({eDisplayFlag = StorefrontLib.CodeEnumStoreDisplayFlag.Popular})
	self.tWndRefs.wndFilterLimitedTimeBtn:SetData({eDisplayFlag = StorefrontLib.CodeEnumStoreDisplayFlag.LimitedTime})
	
	self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdownBtn:AttachWindow(self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdown)
	self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtn:AttachWindow(self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtnDropdown)
	
	if StorefrontLib.GetIsPTR() then
		self.tWndRefs.wndWalletPremium:SetTooltip(Apollo.GetString("Storefront_ProtoBucksCurrencyToolipPTR"))
		self.tWndRefs.wndWalletAlternative:SetTooltip(Apollo.GetString("Storefront_OmnibitsCurrencyToolipPTR"))
		self.tWndRefs.wndCenterPurchaseConfirmDisclaimer:SetText(Apollo.GetString("Storefront_PurchaseDisclaimerPTRProtoBucks"))
	else
		self.tWndRefs.wndCenterPurchaseConfirmDisclaimer:SetText(Apollo.GetString("Storefront_PurchaseDisclaimer"))
		
		self.tWndRefs.wndWalletPremium:SetTooltip(String_GetWeaselString(Apollo.GetString("Storefront_PremiumCurrencyToolip"), unpack(arCurrencyActors)))
		self.tWndRefs.wndWalletAlternative:SetTooltip(String_GetWeaselString(Apollo.GetString("Storefront_AlternativeCurrencyToolip"), unpack(arCurrencyActors)))
		self.tWndRefs.wndWalletTopUp:SetTooltip(String_GetWeaselString(Apollo.GetString("Storefront_PurchasePremiumCurrencyTooltip"), unpack(arCurrencyActors)))
	end

	self.tWndRefs.wndCenterPurchaseConfirmCurrency1:SetTooltip(String_GetWeaselString(Apollo.GetString("Storefront_PremiumCurrencyName"), unpack(arCurrencyActors)))
	
	self.tWndRefs.wndCenterPurchaseConfirmNotEnoughAlternativeCurrency:FindChild("Text"):SetText(String_GetWeaselString(Apollo.GetString("Storefront_PurchaseNotEnoughAlternativeCurrency"), unpack(arCurrencyActors)))
	
	self.tWndRefs.wndFullScreenUpdate:FindChild("Part1"):SetAML(string.format('<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBody\">%s</P>', String_GetWeaselString(Apollo.GetString("Storefront_UpdateNotice"))))
	self.tWndRefs.wndFullScreenUpdate:FindChild("Part2"):SetAML(string.format('<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBody\">%s</P>', String_GetWeaselString(Apollo.GetString("Storefront_UpdateNotice2"))))
	self.tWndRefs.wndFullScreenUpdate:FindChild("Part3"):SetAML(string.format('<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBody\">%s</P>', String_GetWeaselString(Apollo.GetString("Storefront_UpdateNotice3"))))
	
	self.tWndRefs.wndFullScreenUpdate:FindChild("Part1"):SetHeightToContentHeight()
	self.tWndRefs.wndFullScreenUpdate:FindChild("Part2"):SetHeightToContentHeight()
	self.tWndRefs.wndFullScreenUpdate:FindChild("Part3"):SetHeightToContentHeight()
	
	self.tWndRefs.wndFullScreenUpdate:FindChild("Body"):ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	for idx, strCharacterName in pairs(AccountItemLib.GetCharacterNames()) do
		local wndFriend = Apollo.LoadForm(self.xmlDoc, "AltEntry", self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtnDropdownContainer, self)
		
		local wndFriendButton = wndFriend:FindChild("AltBtn")
		wndFriendButton:SetText(strCharacterName)
		wndFriendButton:SetData(strCharacterName)
	end
	
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtnDropdown:GetAnchorOffsets()
	local nNewHeight = self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtnDropdownContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
		return wndLeft:FindChild("AltBtn"):GetData() < wndRight:FindChild("AltBtn"):GetData()
	end)
	local nOldHeight = self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtnDropdownContainer:GetHeight()
	local nNewTop = math.max(nTop, nTop - ((nNewHeight - nOldHeight) / 2))
	local nNewBottom = math.min(nBottom, nBottom + ((nNewHeight - nOldHeight) / 2))
	self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtnDropdown:SetAnchorOffsets(nLeft, nNewTop, nRight, nNewBottom)
	
	local wndMeasure = Apollo.LoadForm(self.xmlDoc, "NavPrimary", nil, self)
	self.knNavPrimaryDefaultHeight = wndMeasure:GetHeight()
	wndMeasure:Destroy()
end
	
function Storefront:OnRequestHeaderDisplay()
	Event_FireGenericEvent("AddHeaderDisplay", self.wndHeader, self.tWndRefs.wndModelDialog)
end

function Storefront:OnStoreClosed()
	Sound.Play(Sound.PlayUIMTXStoreClose)
end

function Storefront:OnOpenStore()
	self.idLastCategory = nil
	
	Event_FireGenericEvent("UpdateHeaderDisplay")
	self:UpdateCurrency()

	self.nFilterOptions = 0
	self.tWndRefs.wndFilterNewestBtn:SetCheck(false)
	self.tWndRefs.wndFilterRecommendedBtn:SetCheck(false)
	self.tWndRefs.wndFilterPopularBtn:SetCheck(false)
	self.tWndRefs.wndFilterLimitedTimeBtn:SetCheck(false)
	
	self.tWndRefs.wndFullBlocker:Show(false)
	self.tWndRefs.wndModelDialog:Show(false)
	self.tWndRefs.wndCenter:Show(true)
	
	if not StorefrontLib.IsStoreReady() or StorefrontLib.IsStoreCatalogDirty() then
		self.tWndRefs.wndFullBlocker:Show(true)
		self:FullBlockerHelper(self.tWndRefs.wndFullBlockerDelaySpinner)
		self.tWndRefs.wndFullBlockerDelaySpinnerMessage:SetText(Apollo.GetString("Storefront_CatalogUpdateInProgress"))
		
		StorefrontLib.RequestCatalog()
		
		return
	end
	
	StorefrontLib.RequestBanners()

	self:BuildNavigation()
	
	for idx, wndNav in pairs(self.tWndRefs.wndNavigation:GetChildren()) do
		local wndNavBtn = wndNav:FindChild("NavBtn")
		if wndNavBtn then
			wndNavBtn:SetCheck(self.tWndRefs.wndNavPrimaryHome == wndNavBtn)
		end
	end
	self:ShowFeatured()
	
	local nDesiredHeight = 550
	local nHeight = self.tWndRefs.wndCenterPurchase:GetHeight()
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchase:GetAnchorOffsets()
	
	
	self.tWndRefs.wndFullScreenUpdate:Show(StorefrontLib.ShouldShowStoreUiUpdateMessage())
	self:BuildStoreTutorial()
	self:UpdateTutorialHighlight(nil, nil, nil)
	
	Sound.Play(Sound.PlayUIMTXStoreOpen)
end

function Storefront:OnOpenStoreLinkSingle(nOfferGroupId, nVariant)
	if self.wndNavInUse ~= nil and self.wndNavInUse:IsValid() then
		self.wndNavInUse:SetCheck(false)
	end
	self.wndNavInUse = nil

	self:CenterShowHelper(self.tWndRefs.wndCenterPurchase)
	local tOffer = StorefrontLib.GetOfferGroupInfo(nOfferGroupId)
	self:SetupOffer(tOffer, nVariant, 0)
end

function Storefront:OnOpenStoreLinkCategory(nCategoryId)
	self:ShowCategoryPage(nCategoryId)
end

function Storefront:OnOpenStoreFromBanner(nBannerId)
	local tData = StorefrontLib.GetBannerById(nBannerId)
	if tData == nil then
		return
	end

	self:OpenBanner(tData)
end

function Storefront:OnOpenSignature()
	--It is possible the store catelog is not ready.
	--The signature page doesn't need store data, but the window references are setup when store data is set.
	local promise = Promise.NewFromGameEvent("StoreCatalogReady", self):Then(function()
		if not self.tWndRefs.wndNavPrimaryPremiumPage then
			self:BuildNavigation()
		end

		local wndNavBtn = self.tWndRefs.wndNavPrimaryPremiumPage:FindChild("NavBtn")
		self:OnPremiumPageCheck(wndNavBtn, wndNavBtn)
		wndNavBtn:SetCheck(true)
	end)

	if self.tWndRefs.wndNavPrimaryPremiumPage then
		promise:Resolve()
	end
end

function Storefront:OnSystemKeyDown(iKey)
	if iKey == self.knEscapeKey then
		if self.tWndRefs.wndFullBlocker:IsShown() then
			-- Do nothing
		elseif self.tWndRefs.wndModelDialog:IsShown() then
			self.tWndRefs.wndModelDialog:Show(false)
			Event_FireGenericEvent("CloseDialog")
		else
			CloseStore()
		end
	end
end

function Storefront:OnStoreBannersReady()
	if self.wndNavInUse ~= nil then
		if self.wndNavInUse == self.tWndRefs.wndNavPrimaryHome then
			self:ShowFeatured()
		end
	end
end

function Storefront:OnStoreCatalogUpdated()
	self.tWndRefs.wndFullBlocker:Show(true)
	self:FullBlockerHelper(self.tWndRefs.wndFullBlockerDelaySpinner)
	self.tWndRefs.wndFullBlockerDelaySpinnerMessage:SetText(Apollo.GetString("Storefront_CatalogUpdateInProgress"))
	
	if IsStoreOpen() then
		StorefrontLib.RequestCatalog()
	end
end

function Storefront:OnStoreCatalogReady()
	self.tWndRefs.wndFullBlocker:Show(false)

	-- Refresh navigation
	local strText = nil
	if self.tWndRefs.wndNavSearchEditBox ~= nil and self.tWndRefs.wndNavSearchEditBox:IsValid() then
		strText = self.tWndRefs.wndNavSearchEditBox:GetText()
	end
	
	if self.wndNavInUse ~= nil then
		if self.wndNavInUse == self.tWndRefs.wndNavPrimaryHome then
			self:BuildNavigation()
			self:ShowFeatured()
		elseif self.wndNavInUse == self.tWndRefs.wndNavPrimaryPremiumPage then
			self:BuildNavigation()
			local wndBtn = self.tWndRefs.wndNavPrimaryPremiumPage:FindChild("NavBtn")
			self:OnPremiumPageCheck(wndBtn, wndBtn)
			wndBtn:SetCheck(true)
		elseif self.wndNavInUse == self.tWndRefs.wndNavPremiumStore then
			self:BuildNavigation()
			local wndBtn = self.tWndRefs.wndNavPremiumStore:FindChild("SecondaryNavBtn")
			self:OnPremiumStoreCheck(wndBtn, wndBtn)
			wndBtn:SetCheck(true)
		else
			local tCategoryId = self.wndNavInUse:FindChild("NavBtn"):GetData().nId
			local nSubCategoryId = nil
			if self.idLastCategory ~= nil then
				nSubCategoryId = self.idLastCategory
			end
			
			self:BuildNavigation()
			
			if self.tNavCategoryWndRefs[tCategoryId] ~= nil then
				local wndPrimaryNavBtn = self.tNavCategoryWndRefs[tCategoryId]:FindChild("NavBtn")
				self:OnNavPrimaryCheck(wndPrimaryNavBtn, wndPrimaryNavBtn)
				wndPrimaryNavBtn:SetCheck(true)
			
				if nSubCategoryId ~= nil then
					if self.tNavSubCategoryWndRefs[nSubCategoryId] ~= nil then
						local wndSecondaryNavBtn = self.tNavSubCategoryWndRefs[nSubCategoryId]:FindChild("SecondaryNavBtn")
						self:OnNavSecondaryCheck(wndSecondaryNavBtn, wndSecondaryNavBtn)
						wndSecondaryNavBtn:SetCheck(true)
					else
						self.idLastCategory = nil
						self:OnStoreCatalogReadyFailedToRecover()
						return
					end
				end
			else
				self:OnStoreCatalogReadyFailedToRecover()
				return
			end
		end
	else
		self:BuildNavigation()
		
		if strText == nil or strText == "" then
			for idx, wndNav in pairs(self.tWndRefs.wndNavigation:GetChildren()) do
				local wndNavBtn = wndNav:FindChild("NavBtn")
				if wndNavBtn then
					wndNavBtn:SetCheck(self.tWndRefs.wndNavPrimaryHome == wndNavBtn)
				end
			end
			self:OnFeaturedCheck(self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn"), self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn"))
		end
	end
	
	-- Refresh search item grid
	if strText ~= nil and strText ~= "" and self.tWndRefs.wndCenterItemsContainer:IsShown() then
		self.tWndRefs.wndNavSearchEditBox:SetText(strText)
		self:SetupSearchItemPage()
		self.tWndRefs.wndCenterItemsContainer:SetVScrollPos(0)
	end
	
	self:UpdateCurrency()
end

function Storefront:OnStoreCatalogReadyFailedToRecover()
	self:OnOpenStore()
	
	self.tWndRefs.wndFullBlocker:Show(true)
	self:FullBlockerHelper(self.tWndRefs.wndFullBlockerPrompt)
	
	self.tWndRefs.wndFullBlockerPromptHeader:SetText(Apollo.GetString("Storefront_CatalogUpdatedDialogHeader"))	
	self.tWndRefs.wndFullBlockerPromptBody:SetText(Apollo.GetString("Storefront_CatalogUpdatedDialogBody"))
	self.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = nil })
	Sound.Play(Sound.PlayUIMTXStorePurchaseFailed)

end

function Storefront:OnStorePurchaseOfferFailureResultAccept()
	local tData = self.tWndRefs.wndCenterPurchaseConfirm:GetData()
	self.tWndRefs.wndCenterPurchaseScrollContent:SetVScrollPos(0)
	self:SetupOffer(tData.tOffer, tData.nVariant, tData.nCategoryId)
end

function Storefront:OnStoreError(eError)
	self.tWndRefs.wndFullBlocker:Show(true, false, 0.15)
	self:FullBlockerHelper(self.tWndRefs.wndFullBlockerPrompt)
	
	self.tWndRefs.wndFullBlockerPromptHeader:SetText(Apollo.GetString("Storefront_GenericError"))
	if self.ktErrorMessages[eError] == nil then
		eError = StorefrontLib.CodeEnumStoreError.CatalogUnavailable
	end
	Sound.Play(Sound.PlayUIMTXStorePurchaseFailed)
	self.tWndRefs.wndFullBlockerPromptBody:SetText(self.ktErrorMessages[eError])
	self.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = Storefront.OnStoreErrorAccept })
end

function Storefront:OnStoreErrorAccept()
	self:OnOpenStore()
end

function Storefront:OnAccountCurrencyChanged()
	self:UpdateCurrency()
end

function Storefront:OnEntitlementUpdate()
	if self.tWndRefs.wndCenterPurchase:IsShown()
		and not self.tWndRefs.wndCenterPurchaseSelf:IsShown()
		and not self.tWndRefs.wndCenterPurchaseGifting:IsShown()
		and not self.tWndRefs.wndCenterPurchaseConfirmed:IsShown() then
		
		local tData = self.tWndRefs.wndCenterPurchaseConfirm:GetData()
		self:SetupOffer(tData.tOffer, tData.nVariant, tData.nCategoryId)
	end
end

function Storefront:OnShowDialog(strDialogName, wndParent)
	self.tWndRefs.wndModelDialog:Show(strDialogName ~= nil and strDialogName ~= "")
end
	
function Storefront:OnRequestFullDialogPrompt(strTitle, strMessage, fnCallback)
	self.tWndRefs.wndFullBlocker:Show(true, false, 0.15)
	self:FullBlockerHelper(self.tWndRefs.wndFullBlockerPrompt)
	
	self.tWndRefs.wndFullBlockerPromptHeader:SetText(strTitle)
	self.tWndRefs.wndFullBlockerPromptBody:SetText(strMessage)
	self.tWndRefs.wndFullBlockerPromptConfimBtn:SetData({ fnCallback = fnCallback })
end
	
function Storefront:OnRequestFullDialogSpinner(strMessage)
	self.tWndRefs.wndFullBlocker:Show(true, false, 0.15)
	self:FullBlockerHelper(self.tWndRefs.wndFullBlockerDelaySpinner)
	self.tWndRefs.wndFullBlockerDelaySpinnerMessage:SetText(strMessage)
end

function Storefront:OnHideFullDialog()
	self.tWndRefs.wndFullBlocker:Show(false, false, 0.15)
end

function Storefront:HasDiscount(tOfferInfo)
	if tOfferInfo.tPrices == nil then
		return false
	end
	
	return (tOfferInfo.tPrices.tNCoins ~= nil and tOfferInfo.tPrices.tNCoins.nDiscountAmount ~= nil and tOfferInfo.tPrices.tNCoins.nDiscountAmount > 0)
				or (tOfferInfo.tPrices.tOmnibits ~= nil and tOfferInfo.tPrices.tOmnibits.nDiscountAmount ~= nil and tOfferInfo.tPrices.tOmnibits.nDiscountAmount > 0)
end

function Storefront:ConvertSecondsToTimeRemaining(fSeconds)
	local nDays = math.floor(fSeconds / 86400)
	local nHours = math.floor((fSeconds / 3600) - (nDays * 24))
	local nMins = math.floor((fSeconds / 60) - (nDays * 1440) - (nHours * 60))
	local nSecs = math.floor(fSeconds - (nDays * 86400) - (nHours * 3600) - (nMins * 60))
	
	local tFirstActor = nil
	local tSecondActor = nil
	
	if nDays > 0 then
		tFirstActor =
		{
			count = nDays,
			name = Apollo.GetString("CRB_Day")
		}
	end
	
	if nHours > 0 then
		local tHourActor =
		{
			count = nHours,
			name = Apollo.GetString("CRB_Hour")
		}
	
		if tFirstActor == nil then
			tFirstActor = tHourActor
		else
			tSecondActor = tHourActor
		end
	end
	
	if nMins > 0 then
		local tMinuteActor =
		{
			count = nMins,
			name = Apollo.GetString("CRB_Minute")
		}
		
		if tFirstActor == nil then
			tFirstActor = tMinuteActor
		elseif tSecondActor == nil then
			tSecondActor = tMinuteActor
		end
	end
	
	if nSecs > 0 or fSeconds == 0 then
		local tSecondsActor =
		{
			count = nSecs,
			name = Apollo.GetString("CRB_Second")
		}
		
		if tFirstActor == nil then
			tFirstActor = tSecondsActor
		elseif tSecondActor == nil then
			tSecondActor = tSecondsActor
		end
	end
	
	if tFirstActor ~= nil and tSecondActor ~= nil then
		return String_GetWeaselString(Apollo.GetString("Storefront_TimeRemainingPair"), tFirstActor, tSecondActor)
	end
	return String_GetWeaselString(Apollo.GetString("Storefront_TimeRemainingSingle"), tFirstActor)
end

function Storefront:OnRealTimeUpdateTimer(nTime)
	nTime = nTime / 1000 -- milliseconds to seconds
	
	for idx, tTimerData in pairs(self.tRealTimeCountdownWndRefs) do
		if tTimerData.wndText ~= nil and tTimerData.wndText:IsValid() then
			tTimerData.nTimeRemaining = math.max(0, tTimerData.nTimeRemaining - nTime)		
			tTimerData.wndText:SetText(String_GetWeaselString(tTimerData.strText, self:ConvertSecondsToTimeRemaining(tTimerData.nTimeRemaining)))
		else
			tTimerData.nTimeRemaining = 0
		end
		if tTimerData.nTimeRemaining == 0 then
			self.tRealTimeCountdownWndRefs[idx] = nil
		end
	end
	
	if next(self.tRealTimeCountdownWndRefs) == nil then
		self.timerRealTimeUpdate:Stop()
	end
end

function Storefront:BuildBannersForContainer(tOffer, tOfferInfo, wndBannerContainer)
	wndBannerContainer:DestroyChildren()

	if tOffer.tFlags.bLimitedTime then
		local nTimeRemaining = 0
		if tOfferInfo.tPrices.tPremium ~= nil and tOfferInfo.tPrices.tPremium.nDiscountTimeRemaining ~= nil then
			nTimeRemaining = math.max(nTimeRemaining, tOfferInfo.tPrices.tPremium.nDiscountTimeRemaining)
		end
		if tOfferInfo.tPrices.tAlternative ~= nil and tOfferInfo.tPrices.tAlternative.nDiscountTimeRemaining ~= nil then
			nTimeRemaining = math.max(nTimeRemaining, tOfferInfo.tPrices.tAlternative.nDiscountTimeRemaining)
		end
		local wndBannerEntry = Apollo.LoadForm(self.xmlDoc, "BannerEntry", wndBannerContainer, self)
		wndBannerEntry:FindChild("Label"):SetTextColor("BabyPurple")
		wndBannerEntry:FindChild("Frame"):SetSprite("MTX:UI_BK3_MTX_CalloutBanner_ItemPurple")
		wndBannerEntry:FindChild("Label"):SetText(String_GetWeaselString(Apollo.GetString("Storefront_LimitedTimeBanner"), self:ConvertSecondsToTimeRemaining(nTimeRemaining)))
		local tTimerData =
		{
			strText = Apollo.GetString("Storefront_LimitedTimeBanner"),
			wndText = wndBannerEntry:FindChild("Label"),
			nTimeRemaining = nTimeRemaining,
		}
		self.tRealTimeCountdownWndRefs[wndBannerEntry:GetId()] = tTimerData
		self.timerRealTimeUpdate:Start()
	end
	
	if tOffer.tFlags.bRecommended then
		local wndBannerEntry = Apollo.LoadForm(self.xmlDoc, "BannerEntry", wndBannerContainer, self)
		wndBannerEntry:FindChild("Label"):SetTextColor("DullYellow")
		wndBannerEntry:FindChild("Frame"):SetSprite("MTX:UI_BK3_MTX_CalloutBanner_ItemYellow")
		wndBannerEntry:FindChild("Label"):SetText(Apollo.GetString("Storefront_OfferFlagRecommendedTooltip"))
	end
	
	if tOffer.tFlags.bNew then
		local wndBannerEntry = Apollo.LoadForm(self.xmlDoc, "BannerEntry", wndBannerContainer, self)
		wndBannerEntry:FindChild("Label"):SetTextColor("AquaGreen")
		wndBannerEntry:FindChild("Frame"):SetSprite("MTX:UI_BK3_MTX_CalloutBanner_ItemGreen")
		wndBannerEntry:FindChild("Label"):SetText(Apollo.GetString("Storefront_OfferFlagNewTooltip"))
	end
	
	if tOffer.tFlags.bPopular then
		local wndBannerEntry = Apollo.LoadForm(self.xmlDoc, "BannerEntry", wndBannerContainer, self)
		wndBannerEntry:FindChild("Label"):SetTextColor("UI_BtnTextRedFlyby")
		wndBannerEntry:FindChild("Frame"):SetSprite("MTX:UI_BK3_MTX_CalloutBanner_ItemRed")
		wndBannerEntry:FindChild("Label"):SetText(Apollo.GetString("Storefront_OfferFlagPopularTooltip"))
	end
	
	-- Sale
	local nLargestDiscount = 0
	local bHasDiscount = false
	
	-- Price Premium
	if tOfferInfo.tPrices.tPremium ~= nil then
		if tOfferInfo.tPrices.tPremium.nDiscountAmount ~= nil then
			if tOfferInfo.tPrices.tPremium.eDiscountType == StorefrontLib.CodeEnumStoreDiscountType.Percentage then
				nLargestDiscount = math.max(nLargestDiscount, tOfferInfo.tPrices.tPremium.nDiscountAmount)
			end
			
			bHasDiscount = bHasDiscount or tOfferInfo.tPrices.tPremium.nDiscountAmount > 0
		end
	end
	
	-- Price Alternative
	if tOfferInfo.tPrices.tAlternative ~= nil then
		if tOfferInfo.tPrices.tAlternative.nDiscountAmount ~= nil then
			if tOfferInfo.tPrices.tAlternative.eDiscountType == StorefrontLib.CodeEnumStoreDiscountType.Percentage then
				nLargestDiscount = math.max(nLargestDiscount, tOfferInfo.tPrices.tAlternative.nDiscountAmount)
			end
			
			bHasDiscount = bHasDiscount or tOfferInfo.tPrices.tAlternative.nDiscountAmount > 0
		end
	end
	
	if bHasDiscount then
		local wndBannerEntry = Apollo.LoadForm(self.xmlDoc, "BannerEntry", wndBannerContainer, self)
		wndBannerEntry:FindChild("Label"):SetTextColor("EggshellBlue")
		wndBannerEntry:FindChild("Frame"):SetSprite("MTX:UI_BK3_MTX_CalloutBanner_ItemBlue")
		if nLargestDiscount > 0 then
			wndBannerEntry:FindChild("Label"):SetText(String_GetWeaselString(Apollo.GetString("Storefront_DiscountBannerPrecent"), nLargestDiscount))
		else
			wndBannerEntry:FindChild("Label"):SetText(Apollo.GetString("Storefront_DiscountBannerFlatAmount"))
		end
	end
end

function Storefront:SetupPriceContainer(wndPriceBG, tPrice)
	local nLargestDiscount = 0	

	local wndPrice = wndPriceBG:FindChild("Price")
	if tPrice ~= nil then
		wndPrice:SetAmount(tPrice.monPrice, true)
		
		local wndPriceBase = wndPriceBG:FindChild("PriceBase")
		local wndCrossOut = wndPriceBG:FindChild("CrossOut")
		
		if tPrice.nDiscountAmount ~= nil then
			if tPrice.eDiscountType == StorefrontLib.CodeEnumStoreDiscountType.Percentage then
				nLargestDiscount = tPrice.nDiscountAmount
			end
			
			wndPriceBase:SetAmount(tPrice.monBasePrice, true)
			
			if tPrice.nDiscountAmount > 0 then
				wndPriceBase:Show(true)
				wndCrossOut:Show(true)
				local nLeftPrice, nTopPrice, nRightPrice, nBottomPrice = wndPrice:GetAnchorOffsets()
				wndPrice:SetAnchorOffsets(nLeftPrice, 20, nRightPrice, nBottomPrice)
			end
			
			local nWidth = (wndPriceBase:GetDisplayWidth() / 2)
			local nLeft, nTop, nRight, nBottom = wndCrossOut:GetAnchorOffsets()
			wndCrossOut:SetAnchorOffsets(nWidth * (-1), nTop, nWidth, nBottom)
		else
			wndPriceBase:Show(false)
			wndCrossOut:Show(false)
		end
	end
	wndPriceBG:Show(tPrice ~= nil)
	
	return nLargestDiscount
end

function Storefront:BuildNavigation()
	self.tNavCategoryWndRefs = {}
	self.tWndRefs.wndNavigation:DestroyChildren()
	
	local wndSearch = Apollo.LoadForm(self.xmlDoc, "NavSearch", self.tWndRefs.wndNavigation, self)
	self.tWndRefs.wndNavSearch = wndSearch
	self.tWndRefs.wndNavSearchClearBtn = wndSearch:FindChild("ClearBtn")
	self.tWndRefs.wndNavSearchEditBox = wndSearch:FindChild("EditBox")
	
	local wndHome = Apollo.LoadForm(self.xmlDoc, "NavPrimarySingle", self.tWndRefs.wndNavigation, self)
	wndHome:FindChild("NavBtn"):SetText(Apollo.GetString("Storefront_NavFeatured"))
	wndHome:FindChild("NavBtn"):SetTooltip(Apollo.GetString("Storefront_NavFeatuedTooltip"))
	wndHome:FindChild("NavBtn"):RemoveEventHandler("ButtonCheck")
	wndHome:FindChild("NavBtn"):AddEventHandler("ButtonCheck", "OnFeaturedCheck")
	self.tWndRefs.wndNavPrimaryHome = wndHome:FindChild("NavBtn")
	
	local wndPremiumPage = Apollo.LoadForm(self.xmlDoc, "NavPrimarySingle", self.tWndRefs.wndNavigation, self)
	if AccountItemLib.GetPremiumSystem() == AccountItemLib.CodeEnumPremiumSystem.Hybrid then
		wndPremiumPage:FindChild("NavBtn"):SetText(Apollo.GetString("Storefront_NavSignature"))
		wndPremiumPage:FindChild("NavBtn"):SetTooltip(Apollo.GetString("Storefront_NavSignatureTooltip"))
	else
		wndPremiumPage:FindChild("NavBtn"):SetText(Apollo.GetString("Storefront_NavVip"))
		wndPremiumPage:FindChild("NavBtn"):SetTooltip(Apollo.GetString("Storefront_NavVipTooltip"))
	end
	
	wndPremiumPage:FindChild("NavBtn"):RemoveEventHandler("ButtonCheck")
	wndPremiumPage:FindChild("NavBtn"):AddEventHandler("ButtonCheck", "OnPremiumPageCheck")
	self.tWndRefs.wndNavPrimaryPremiumPage = wndPremiumPage:FindChild("NavBtn")
	
	local arPremiumStoreOffers = StorefrontLib.GetOfferGroupsForCategory(StorefrontLib.kSignatureGoodsCategoryId)
	if arPremiumStoreOffers and #arPremiumStoreOffers > 0 then
		local wndCategory = Apollo.LoadForm(self.xmlDoc, "NavSecondarySingle", self.tWndRefs.wndNavigation, self)
		local wndNavBtn = wndCategory:FindChild("SecondaryNavBtn")
		wndNavBtn:RemoveEventHandler("ButtonCheck")
		wndNavBtn:AddEventHandler("ButtonCheck", "OnPremiumStoreCheck")
		self.tWndRefs.wndNavPremiumStore = wndNavBtn
	end
	
	Apollo.LoadForm(self.xmlDoc, "NavPrimarySpacer", self.tWndRefs.wndNavigation, self)
	
	local arCategories = StorefrontLib.GetCategoryTree()	
	if #arCategories == 0 then
		-- No data yet
		self:OnStoreError(StorefrontLib.CodeEnumStoreError.CatalogUnavailable)
		return
	end
	
	self.tWndRefs.wndFullBlocker:Show(false)
	
	for idx, tCategory in pairs(arCategories) do
		if tCategory.bDisplayable then
			-- The Signature store category is special, it gets drawn under the Premium category
			if tCategory.nId == StorefrontLib.kSignatureGoodsCategoryId then
				if self.tWndRefs.wndNavPremiumStore then
					self.tWndRefs.wndNavPremiumStore:SetText(tCategory.strName)
					self.tWndRefs.wndNavPremiumStore:SetData(tCategory)
					self.tWndRefs.wndNavPremiumStore:SetTooltip(tCategory.strDescription)
				end
			else
				local wndPrimary = nil
	
				local bUseSingle = true
				if #tCategory.tGroups > 0 then
					for idx, tSubCategory in pairs(tCategory.tGroups) do
						bUseSingle = bUseSingle and not tSubCategory.bDisplayable
					end
				end
	
				if bUseSingle then
					wndPrimary = Apollo.LoadForm(self.xmlDoc, "NavPrimarySingle", self.tWndRefs.wndNavigation, self)
				else
					wndPrimary = Apollo.LoadForm(self.xmlDoc, "NavPrimary", self.tWndRefs.wndNavigation, self)
				end
				
				self.tNavCategoryWndRefs[tCategory.nId] = wndPrimary
				
				local wndNavBtn = wndPrimary:FindChild("NavBtn")
				wndNavBtn:SetText(tCategory.strName)
				wndNavBtn:SetData(tCategory)
				wndNavBtn:SetTooltip(tCategory.strDescription)
			end
		end
	end
	self.tWndRefs.wndNavigation:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
end

function Storefront:SetupPreviewWindowForMe(wndContainer, tDisplayInfo, tItems)
	if tDisplayInfo ~= nil
		and (tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin
			or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.CustomMannequin) then
		local wndPreviewFrame = wndContainer:FindChild("PreviewFrame")
		local unitPlayer = GameLib.GetPlayerUnit()
		
		wndPreviewFrame:SetCostume(unitPlayer)
		for _, tAccountItem in pairs(tItems) do
			if tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.GameItem then
				if tAccountItem.nStoreDisplayInfoId == tDisplayInfo.nId and tAccountItem.item ~= nil then
					local tCostumeUnlockInfo = tAccountItem.item:GetCostumeUnlockInfo()
					if tCostumeUnlockInfo ~= nil and tCostumeUnlockInfo.bCanUseInCostume then
						wndPreviewFrame:SetItem(tAccountItem.item)
					end
				end
			end
		end
		
		if unitPlayer ~= nil and unitPlayer:IsValid() then
			wndPreviewFrame:SetModelSequence(StorefrontLib.CodeEnumModelSequence.DefaultStand)
		end
	end
end

function Storefront:SetupPreviewWindow(wndContainer, tDisplayInfo, tItems)
	local wndPreviewFrame = wndContainer:FindChild("PreviewFrame")
	local wndDecorFrame = wndContainer:FindChild("DecorFrame")
	if tDisplayInfo ~= nil then
		local unitPlayer = GameLib.GetPlayerUnit()
	
		if tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin then
			local tMannequins = StorefrontLib.GetMannequins()
			tDisplayInfo.idCreature = tMannequins.nMaleMannequinCreatureId
			
			if unitPlayer ~= nil and unitPlayer:IsValid() then
				if unitPlayer:GetRaceId() == GameLib.CodeEnumRace.Chua then
					if tDisplayInfo.nId % 2 == 0 then
						tDisplayInfo.idCreature = tMannequins.nFemaleMannequinCreatureId
					end
				else
					local eGender = unitPlayer:GetGender()
					if eGender == Unit.CodeEnumGender.Female then
						tDisplayInfo.idCreature = tMannequins.nFemaleMannequinCreatureId
					end
				end
			end
		end
		
		if tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Creature
			or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin
			or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.CustomMannequin then
			wndPreviewFrame:SetCamera(tDisplayInfo.strModelCamera)
			wndPreviewFrame:SetCostumeToCreatureId(tDisplayInfo.idCreature)
			wndPreviewFrame:ResetSpin()
			wndPreviewFrame:SetSpin(30)
			
			for _, tAccountItem in pairs(tItems) do
				if tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.GameItem then
					if tAccountItem.nStoreDisplayInfoId == tDisplayInfo.nId and tAccountItem.item ~= nil then
						wndPreviewFrame:SetItem(tAccountItem.item)
						
						if tAccountItem.item:GetItemFamily() == Item.CodeEnumItem2Family.Tool then
							wndPreviewFrame:SetToolEquipped(true)
						end
					end
				end
			end
			
			if tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin
				or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.CustomMannequin then
				if unitPlayer ~= nil and unitPlayer:IsValid() then
					self.tWndRefs.wndCenterPurchasePreview:SetModelSequence(self.ktClassAnimation[unitPlayer:GetClassId()].eStand)
				end
			end
			
		elseif tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Decor then
			wndDecorFrame:SetCamera(tDisplayInfo.strModelCamera)
			wndDecorFrame:SetDecorInfo(tDisplayInfo.idDecor)
			wndDecorFrame:ResetSpin()
			wndDecorFrame:SetSpin(30)
			
		elseif tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mount then
			wndPreviewFrame:SetCamera(tDisplayInfo.strModelCamera)
			wndPreviewFrame:SetCostumeToCreatureId(tDisplayInfo.idCreature)
			
			if tDisplayInfo.bIsHoverboard then
				wndPreviewFrame:SetAttachment(PetCustomizationLib.HoverboardAttachmentPoint, tDisplayInfo.idPreviewHoverboardItemDisplay)
			end
			
			wndPreviewFrame:SetModelSequence(150)
			wndPreviewFrame:ResetSpin()
			wndPreviewFrame:SetSpin(30)
			
			for _, tAccountItem in pairs(tItems) do
				if tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.GameItem then
					if tAccountItem.nStoreDisplayInfoId == tDisplayInfo.nId and tAccountItem.item ~= nil then
						local eCurrSlot = self.ktSlotMapping[tAccountItem.item:GetItemType()]
						if eCurrSlot ~= nil then
							local custFlair = StorefrontLib.GetPetFlairUnlockedFromItem(tAccountItem.item)
							if custFlair ~= nil then
								wndPreviewFrame:SetAttachment(tDisplayInfo.custPetCustomization:GetPreviewAttachSlot(eCurrSlot), custFlair:GetItemDisplay(eCurrSlot))
							end
						end
					end
				end
			end
			
		end
	end
	
	local bShowPreview = wndPreviewFrame ~= nil and wndPreviewFrame:IsValid() and tDisplayInfo ~= nil
		and (tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Creature
			or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin
			or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.CustomMannequin
			or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mount)
	wndPreviewFrame:Show(bShowPreview)
	wndDecorFrame:Show(wndDecorFrame ~= nil and wndDecorFrame:IsValid() and tDisplayInfo ~= nil and tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Decor)
end

function Storefront:SetupCategoryItemPage(idCategory)
	self.idLastCategory = idCategory

	local arOffers = StorefrontLib.GetOfferGroupsForCategory(idCategory, self.tSortingOptions, self.nFilterOptions)
	self:SetupItemGrid(self.tWndRefs.wndCenterItemsContainer, arOffers, idCategory)
	
	self.tWndRefs.wndCenterContentEmptyDisplay:Show(#arOffers == 0)
	self.tWndRefs.wndCenterContentNoResultsDisplay:Show(false)
end

function Storefront:SetupSearchItemPage()
	self.idLastCategory = nil
	local strText = self.tWndRefs.wndNavSearchEditBox:GetText()

	local arOffers = StorefrontLib.GetOfferGroupsForSearchStr(strText, self.tSortingOptions, self.nFilterOptions)
	
	self:SetupItemGrid(self.tWndRefs.wndCenterItemsContainer, arOffers, 0)
	
	self.tWndRefs.wndCenterContentEmptyDisplay:Show(false)
	self.tWndRefs.wndCenterContentNoResultsDisplay:Show(#arOffers == 0)
end

function Storefront:SetupItemGrid(wndContainer, arOffers, nCategoryId)
	wndContainer:DestroyChildren()
	
	if arOffers == nil then
		return
	end
	
	for idx, idOffer in pairs(arOffers) do
		local wndOffer = Apollo.LoadForm(self.xmlDoc, "Item", wndContainer, self)
		
		local tOffer = StorefrontLib.GetOfferGroupInfo(idOffer)
		local tOfferInfo = StorefrontLib.GetOfferInfo(tOffer.nId, 1)
		
		wndOffer:FindChild("PreviewBtn"):SetData({ tOffer = tOffer, nCategoryId = nCategoryId })
		wndOffer:FindChild("BottomStack:ItemName"):SetText(tOffer.strName)
		
		local nDisplayInfoId = tOffer.nDisplayInfoOverride
		if nDisplayInfoId == 0 and tOfferInfo ~= nil and #tOfferInfo.tItems > 0 then
			for idx, tAccountItem in pairs(tOfferInfo.tItems) do
				if tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.GameItem then
					nDisplayInfoId = tOfferInfo.tItems[idx].nStoreDisplayInfoId
					break
				end
			end
		end
		
		local tDisplayInfo = StorefrontLib.GetStoreDisplayInfo(nDisplayInfoId)
		self:SetupPreviewWindow(wndOffer:FindChild("PreviewBtn:ItemImage"), tDisplayInfo, tOfferInfo.tItems)
		
		-- Callout
		local wndItemCallout = wndOffer:FindChild("ItemCallout")
		if tOffer.tFlags.bLimitedTime then
			wndItemCallout:Show(true)
			wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.LimitedTime].sprCallout)
			wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.LimitedTime].strTooltip)
			
		elseif tOffer.tFlags.bRecommended then
			wndItemCallout:Show(true)
			wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Recommended].sprCallout)
			wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Recommended].strTooltip)
			
		elseif tOffer.tFlags.bNew then
			wndItemCallout:Show(true)
			wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.New].sprCallout)
			wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.New].strTooltip)
			
		elseif tOffer.tFlags.bPopular then
			wndItemCallout:Show(true)
			wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Popular].sprCallout)
			wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Popular].strTooltip)
			
		else
			wndItemCallout:Show(false)
		end
		
		wndOffer:FindChild("SignatureCallout"):Show(tOfferInfo.nRequiredTier > 0)
		
		local wndBottomStack = wndOffer:FindChild("BottomStack")
		if tOfferInfo ~= nil then
			local wndPriceContainer = wndBottomStack:FindChild("PriceContainer")
			
			local nLargestDiscount = 0
			
			-- Price Premium
			nLargestDiscount = math.max(nLargestDiscount, self:SetupPriceContainer(wndPriceContainer:FindChild("Price1BG"), tOfferInfo.tPrices.tPremium))
			
			-- Price Alternative
			nLargestDiscount = math.max(nLargestDiscount, self:SetupPriceContainer(wndPriceContainer:FindChild("Price2BG"), tOfferInfo.tPrices.tAlternative))
			
			wndPriceContainer:FindChild("or"):Show(tOfferInfo.tPrices.tPremium ~= nil and tOfferInfo.tPrices.tAlternative ~= nil)
			
			local wndDiscountCallout = wndOffer:FindChild("DiscountCallout")
			if nLargestDiscount > 0 then
				wndDiscountCallout:Show(true)
				wndDiscountCallout:SetText(String_GetWeaselString(Apollo.GetString("Storefront_DiscountCallout"), nLargestDiscount))
			else
				wndDiscountCallout:Show(false)
				
				if not self:HasDiscount(tOfferInfo) then
					local nLeft, nTop, nRight, nBottom = wndPriceContainer:GetAnchorOffsets()
				wndPriceContainer:SetAnchorOffsets(nLeft, nTop + 15, nRight, nBottom)
				end
			end
			wndPriceContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
		end
		
		wndBottomStack:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.RightOrBottom)
		
		wndOffer:SetData({tOffer = tOffer, tOfferInfo = tOfferInfo, tDisplayInfo = tDisplayInfo, nCategoryId = nCategoryId})
	end
	
	wndContainer:ArrangeChildrenTiles()
end

function Storefront:CenterShowHelper(wndToShow)
	self.tWndRefs.wndSplash:Show(self.tWndRefs.wndSplash == wndToShow)
	self.tWndRefs.wndCenterContent:Show(self.tWndRefs.wndCenterContent == wndToShow)

	if self.tWndRefs.wndSplash ~= wndToShow then
		self.timerBannerRotation:Stop()
	end

	self.tWndRefs.wndCenterPurchase:Show(self.tWndRefs.wndCenterPurchase == wndToShow)
	Event_FireGenericEvent("HidePremiumPage")
end

function Storefront:PurchaseShowHelper(wndToShow)
	self.tWndRefs.wndCenterPurchaseConfirm:Show(self.tWndRefs.wndCenterPurchaseConfirm == wndToShow)
	Event_FireGenericEvent("CloseNeedsFunds")
end

function Storefront:PurchaseDialogShowHelper(wndToShow)
	self.tWndRefs.wndCenterPurchaseConfirmed:Show(self.tWndRefs.wndCenterPurchaseConfirmed == wndToShow)
	self.tWndRefs.wndCenterPurchaseGifting:Show(self.tWndRefs.wndCenterPurchaseGifting == wndToShow)
	self.tWndRefs.wndCenterPurchaseSelf:Show(self.tWndRefs.wndCenterPurchaseSelf == wndToShow)
end

function Storefront:FullBlockerHelper(wndToShow)
	self.tWndRefs.wndFullBlockerPrompt:Show(self.tWndRefs.wndFullBlockerPrompt == wndToShow, true)
	self.tWndRefs.wndFullBlockerDelaySpinner:Show(self.tWndRefs.wndFullBlockerDelaySpinner == wndToShow, true)
end

function Storefront:GetCurrencyNameFromEnum(eCurrencyType)
	if eCurrencyType == AccountItemLib.CodeEnumAccountCurrency.NCoins then
		if StorefrontLib.GetIsPTR() then
			return "PTR NCoin"
		end
	end
	
	local monTemp = Money.new()
	monTemp:SetAccountCurrencyType(eCurrencyType)
	return String_GetWeaselString(monTemp:GetDenomInfo()[1].strName)
end

function Storefront:GetRealCurrencyNameFromEnum(eRealCurrency)
	if eRealCurrency == StorefrontLib.CodeEnumRealCurrency.USD then
		return Apollo.GetString("Storefront_ExternalCurrency_USD")
	elseif eRealCurrency == StorefrontLib.CodeEnumRealCurrency.GBP then
		return  Apollo.GetString("Storefront_ExternalCurrency_GBP")
	elseif eRealCurrency == StorefrontLib.CodeEnumRealCurrency.EUR then
		return  Apollo.GetString("Storefront_ExternalCurrency_EUR")
	end
	
	return "?"
end

function Storefront:OnBannerRotationTimer()
	local arChildren = self.tWndRefs.wndSplashBannerRotationContainer:GetChildren()
	if #arChildren == 0 then
		return
	end

	self.nRotatingBannersIndex = self.nRotatingBannersIndex + 1
	if self.nRotatingBannersIndex > #arChildren then
		self.nRotatingBannersIndex = 1
	end

	local nWidth = arChildren[1]:GetWidth()
	self.tWndRefs.wndSplashBannerRotationContainer:SetHScrollPos(nWidth * (self.nRotatingBannersIndex - 1))
end

function Storefront:OpenBanner(tData)
	if tData.eBannerProductType == StorefrontLib.BannerPageType.Product
		or tData.eBannerProductType == StorefrontLib.CodeEnumBannerLocation.OfferGroupLocation then
		
		self:SetupOffer(StorefrontLib.GetOfferGroupInfo(tData.nBannerProduct), 1, 0)
	elseif tData.eBannerProductType == StorefrontLib.BannerPageType.SearchTerm then
		local wndEditBox = self.tWndRefs.wndCenterFilters:FindChild("EditBox")
		wndEditBox:SetText(tData.strBannerProduct)
		self:NavSearchTextChanged(wndEditBox, wndEditBox)
	elseif tData.eBannerProductType == StorefrontLib.BannerPageType.Category then
		self:ShowCategoryPage(tData.nBannerProduct)
	elseif tData.eBannerProductType == StorefrontLib.BannerPageType.BrowserLink then
		StorefrontLib.OpenBannerBrowserLink(tData.nStoreBannerId)
	elseif tData.eBannerProductType == StorefrontLib.BannerPageType.Signature then
		self:OnOpenSignature()
	end
end

function Storefront:ShowFeatured()
	self:CenterShowHelper(self.tWndRefs.wndSplash)
	self:SetupFeatured()
	
	if self.wndNavInUse ~= nil and self.wndNavInUse:IsValid() then
		self.wndNavInUse:SetCheck(false)
	end
	self.wndNavInUse = self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn")
	self.tWndRefs.wndNavSearchEditBox:SetText("")
	self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn"):SetFocus()
end

function Storefront:SetupFeatured()
	local tBanners = StorefrontLib.GetBanners()
	
	self.tWndRefs.wndSplashBannerRotationContainer:DestroyChildren()
	self.tWndRefs.wndSplashRightTopBtn:SetData(nil)
	self.tWndRefs.wndSplashRightBottomBtn:SetData(nil)
	self.tWndRefs.wndSplashHeaderContent:SetAnchorOffsets(self.tWndRefs.wndSplashHeaderContent:GetOriginalLocation():GetOffsets())
	self.tWndRefs.wndSplashItems:SetAnchorOffsets(self.tWndRefs.wndSplashItems:GetOriginalLocation():GetOffsets())
	
	local nRotatingBannerCount = 0
	
	for idx, tBanner in pairs(tBanners) do
		if tBanner.eLocation == StorefrontLib.CodeEnumBannerLocation.RotatingBannerLocation then
			local wndBanner = Apollo.LoadForm(self.xmlDoc, "Banner", self.tWndRefs.wndSplashBannerRotationContainer, self)
			local wndBtn = wndBanner:FindChild("Btn")
			wndBtn:SetData(tBanner)
			wndBanner:FindChild("Image"):SetSprite(tBanner.strBannerAsset)
			local wndTextContainer = wndBanner:FindChild("TextContainer")
			wndTextContainer:FindChild("ItemTitle"):SetText(tBanner.strTitle)
			local wndBody = wndTextContainer:FindChild("Body")
			wndBody:SetAML(string.format('<P Align="Bottom" Font="CRB_InterfaceMedium" TextColor="UI_TextHoloBody">%s</P>', tBanner.strBody))
			wndBody:SetHeightToContentHeight()
			wndTextContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.RightOrBottom)
			
			nRotatingBannerCount = nRotatingBannerCount + 1
			
		elseif tBanner.eLocation == StorefrontLib.CodeEnumBannerLocation.UpperRightBannerLocation then
			self.tWndRefs.wndSplashRightTopImage:SetSprite(tBanner.strBannerAsset)
			self.tWndRefs.wndSplashRightTopLabel:SetText(tBanner.strTitle)
			self.tWndRefs.wndSplashRightTopBtn:SetData(tBanner)
		elseif tBanner.eLocation == StorefrontLib.CodeEnumBannerLocation.LowerRightBannerLocation then
			self.tWndRefs.wndSplashRightBottomImage:SetSprite(tBanner.strBannerAsset)
			self.tWndRefs.wndSplashRightBottomLabel:SetText(tBanner.strTitle)
			self.tWndRefs.wndSplashRightBottomBtn:SetData(tBanner)
		end
	end
	
	if nRotatingBannerCount == 0 then
		local wndBanner = Apollo.LoadForm(self.xmlDoc, "Banner", self.tWndRefs.wndSplashBannerRotationContainer, self)
		wndBanner:FindChild("Btn"):Enable(false)
		local wndTextContainer = wndBanner:FindChild("TextContainer")
		wndTextContainer:FindChild("Body"):Show(false)
		wndTextContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.RightOrBottom)
	end
	
	-- Hide small banners when no data
	if self.tWndRefs.wndSplashRightTopBtn:GetData() == nil and self.tWndRefs.wndSplashRightBottomBtn:GetData() == nil then
		self.tWndRefs.wndSplashRightBanner:Show(false)
		local nHeight = self.tWndRefs.wndSplashRightBanner:GetHeight()
		local nOrigLeft, nOrigTop, nOrigRight, nOrigBottom = self.tWndRefs.wndSplashHeaderContent:GetOriginalLocation():GetOffsets()
		self.tWndRefs.wndSplashHeaderContent:SetAnchorOffsets(nOrigLeft, nOrigTop, nOrigRight, nOrigBottom - nHeight)
		local nOrigItemsLeft, nOrigItemsTop, nOrigItemsRight, nOrigItemsBottom = self.tWndRefs.wndSplashItems:GetOriginalLocation():GetOffsets()
		self.tWndRefs.wndSplashItems:SetAnchorOffsets(nOrigItemsLeft, nOrigItemsTop - nHeight, nOrigItemsRight, nOrigItemsBottom - nHeight)
	
	elseif self.tWndRefs.wndSplashRightTopBtn:GetData() == nil then
		self.tWndRefs.wndSplashRightBanner:Show(true)
		self.tWndRefs.wndSplashRightTopBanner:Show(false)
		self.tWndRefs.wndSplashRightBottomBanner:Show(true)
		self.tWndRefs.wndSplashRightBanner:ArrangeChildrenHorz()
	
	elseif self.tWndRefs.wndSplashRightBottomBtn:GetData() == nil then
		self.tWndRefs.wndSplashRightBanner:Show(true)
		self.tWndRefs.wndSplashRightTopBanner:Show(true)
		self.tWndRefs.wndSplashRightBottomBanner:Show(false)
		
	else
		self.tWndRefs.wndSplashRightBanner:Show(true)
		self.tWndRefs.wndSplashRightTopBanner:Show(true)
		self.tWndRefs.wndSplashRightBottomBanner:Show(true)
	end
	
	self.tWndRefs.wndSplashBannerRotationContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	if #self.tWndRefs.wndSplashBannerRotationContainer:GetChildren() > 1 then
		self.timerBannerRotation:Start()
	else
		self.timerBannerRotation:Stop()
	end
	
	self.nRotatingBannersIndex = 0
	self:OnBannerRotationTimer()
	
	local arOffers = StorefrontLib.GetOfferGroupsForCategory(StorefrontLib.GetFeaturedCategoryId(), {}, 0)
	self:SetupItemGrid(self.tWndRefs.wndSplashItems, arOffers, StorefrontLib.GetFeaturedCategoryId())
	
	local nHeight = self.tWndRefs.wndSplashItems:ArrangeChildrenTiles()
	
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndSplashItems:GetAnchorOffsets()
	self.tWndRefs.wndSplashItems:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
	self.tWndRefs.wndSplash:RecalculateContentExtents()
end

function Storefront:SetupOffer(tOffer, nVariant, nCategoryId)
	self.tWndRefs.wndCenterPurchase:Show(true)
	self:PurchaseShowHelper(self.tWndRefs.wndCenterPurchaseConfirm)
	self:PurchaseDialogShowHelper(nil)
	
	self.tWndRefs.wndCenterPurchaseConfirm:SetData({tOffer = tOffer, nVariant = nVariant, nCategoryId = nCategoryId})
	
	local tOfferInfo = StorefrontLib.GetOfferInfo(tOffer.nId, nVariant)
	
	local tOfferCache = {}
	tOfferCache[nVariant] = tOfferInfo
	
	local nVariantQuantityCount = 0
	if #tOfferInfo.tItems > 0 then
		nVariantQuantityCount = tOfferInfo.tItems[1].nCount
	end
	
	-- Preview
	local nDisplayInfoId = tOffer.nDisplayInfoOverride
	if nDisplayInfoId == 0 and #tOfferInfo.tItems >= 1 then
		for idx, tAccountItem in pairs(tOfferInfo.tItems) do
			if tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.GameItem then
				nDisplayInfoId = tOfferInfo.tItems[idx].nStoreDisplayInfoId
				break
			end
		end
	end
	
	local tDisplayInfo = StorefrontLib.GetStoreDisplayInfo(nDisplayInfoId)	
	self:SetupPreviewWindow(self.tWndRefs.wndCenterPurchaseLeft, tDisplayInfo, tOfferInfo.tItems)
	self.tWndRefs.wndCenterPurchaseExclusiveBG:Show(tOfferInfo.nRequiredTier > 0)

	self.tWndRefs.wndCenterPurchasePreviewOnMeBtn:Show(tDisplayInfo ~= nil and (tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.CustomMannequin))
	self.tWndRefs.wndCenterPurchasePreviewOnMeBtn:SetCheck(true)
	self.tWndRefs.wndCenterPurchasePreviewOnMeBtn:SetData({tDisplayInfo = tDisplayInfo, tItems = tOfferInfo.tItems})
	
	self.tWndRefs.wndCenterPurchasePreviewSheathedBtn:Show(tDisplayInfo ~= nil and (tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.CustomMannequin))
	self.tWndRefs.wndCenterPurchasePreviewSheathedBtn:SetCheck(true)
	
	self.tWndRefs.wndCenterPurchaseCancelBtn:SetData({tOffer = tOffer, nCategoryId = nCategoryId})
	self.tWndRefs.wndCenterPurchaseBackBtn:SetData({tOffer = tOffer, nCategoryId = nCategoryId})
	
	if tDisplayInfo ~= nil and (tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin or tDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.CustomMannequin) then		
		self:SetupPreviewWindowForMe(self.tWndRefs.wndCenterPurchaseLeft, tDisplayInfo, tOfferInfo.tItems)
		self.tWndRefs.wndCenterPurchasePreview:SetSheathed(true)
	end
	
	-- Name
	self.tWndRefs.wndCenterPurchaseConfirmItemName:SetText(tOfferInfo.strVariantName)
	
	-- Banners
	self:BuildBannersForContainer(tOffer, tOfferInfo, self.tWndRefs.wndCenterPurchaseConfirmBannerContainer)
	
	local nBannerContainerHeight = self.tWndRefs.wndCenterPurchaseConfirmBannerContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	self.tWndRefs.wndCenterPurchaseConfirmBannerSection:Show(nBannerContainerHeight > 0)
	if nBannerContainerHeight > 0 then
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseConfirmBannerSection:GetAnchorOffsets()
		nBottom = nBottom + nBannerContainerHeight - self.tWndRefs.wndCenterPurchaseConfirmBannerContainer:GetHeight()
		self.tWndRefs.wndCenterPurchaseConfirmBannerSection:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	end
	
	-- Description
	local nLargestDescriptionHeight = 0
	for idx=1, tOffer.nNumVariants do
		local tVariantOfferInfo = tOfferCache[idx]
		if tVariantOfferInfo == nil then
			tVariantOfferInfo = StorefrontLib.GetOfferInfo(tOffer.nId, idx)
			tOfferCache[idx] = tVariantOfferInfo
		end
		
		self.tWndRefs.wndCenterPurchaseConfirmDescription:SetAML("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBody\">"..tVariantOfferInfo.strVariantDescription.."</P>")
		local nWidth, nHeight = self.tWndRefs.wndCenterPurchaseConfirmDescription:SetHeightToContentHeight()
		nLargestDescriptionHeight = math.max(nLargestDescriptionHeight, nHeight)
	end
	self.tWndRefs.wndCenterPurchaseConfirmDescription:SetAML("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBody\">"..tOfferInfo.strVariantDescription.."</P>")
	local nDescriptionWidth, nDescriptionHeight = self.tWndRefs.wndCenterPurchaseConfirmDescription:SetHeightToContentHeight()
	
	if nDescriptionHeight < nLargestDescriptionHeight then
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseConfirmDescription:GetAnchorOffsets()
		self.tWndRefs.wndCenterPurchaseConfirmDescription:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nLargestDescriptionHeight)
	end

	self.tWndRefs.wndCenterPurchaseLeft:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

	-- Claim Notice
	local bCantClaimCharacter = false
	local bCantClaimAccount = false
	local bCantClaimAccountPending = false
	
	local bCantClaim = true
	local bCantPurchasePremium = tOfferInfo.nRequiredTier > AccountItemLib.GetPremiumTier()
	local bContainsFortuneCoins = false
	local bPassedCurrencyCheck = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.FraudCheck) == 0
	
	for _, tAccountItem in pairs(tOfferInfo.tItems) do
		if tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.GameItem then
			bCantClaimCharacter = bCantClaimCharacter or (tAccountItem.eClaimState ~= nil and tAccountItem.eClaimState == StorefrontLib.CodeEnumClaimItemState.CharacterMaxed)
			bCantClaimAccount = bCantClaimAccount or (tAccountItem.eClaimState ~= nil
				and (tAccountItem.eClaimState == StorefrontLib.CodeEnumClaimItemState.AccountMaxed or tAccountItem.eClaimState == StorefrontLib.CodeEnumClaimItemState.AccountMaxedWithPending))
				or tAccountItem.bAlreadyOwnBoundMultiRedeem
				or tAccountItem.bAccountUnlockAlreadyOwned
			bCantClaimAccountPending = bCantClaimAccountPending
				or (tAccountItem.eClaimState ~= nil and tAccountItem.eClaimState == StorefrontLib.CodeEnumClaimItemState.AccountMaxedWithPending)
				or tAccountItem.bAlreadyOwnPendingMultiRedeem
		
			bCantClaim = bCantClaim
				and (tAccountItem.eClaimState == nil or tAccountItem.eClaimState ~= StorefrontLib.CodeEnumClaimItemState.CanClaim)
				and (tAccountItem.bAlreadyOwnPendingMultiRedeem or tAccountItem.bAlreadyOwnBoundMultiRedeem or tAccountItem.bAccountUnlockAlreadyOwned)
			
			if tAccountItem.monCurrency ~= nil and tAccountItem.monCurrency:GetAccountCurrencyType() == AccountItemLib.CodeEnumAccountCurrency.MysticShiny then
				bContainsFortuneCoins = true
			end
		elseif tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.Subscription then
			bCantClaim = false
		end
	end
	
	-- Quantity
	self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdownBtn:SetCheck(false)
	self.tWndRefs.wndCenterPurchaseConfirmQuantitySection:Show(tOffer.nNumVariants > 1)
	if tOffer.nNumVariants > 1 then
		self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdownContainer:DestroyChildren()
		
		local tQuantities = {}
		local nDifferentQuantitiesCount = 0
		for idx=1, tOffer.nNumVariants do
			local tQuantityOfferInfo = tOfferCache[idx]
			if tQuantityOfferInfo == nil then
				tQuantityOfferInfo = StorefrontLib.GetOfferInfo(tOffer.nId, idx)
				tOfferCache[idx] = tQuantityOfferInfo
			end
			if tQuantityOfferInfo ~= nil and #tQuantityOfferInfo.tItems > 0 and #tOfferInfo.tItems > 0 and tQuantityOfferInfo.tItems[1].nId == tOfferInfo.tItems[1].nId then
				local nQuantityCount = tQuantityOfferInfo.tItems[1].nCount
				if tQuantities[nQuantityCount] == nil then
					tQuantities[nQuantityCount] = { tQuantityOfferInfo = tQuantityOfferInfo, nVariant = idx }
					 nDifferentQuantitiesCount = nDifferentQuantitiesCount + 1
				end
			end
		end
		
		if nDifferentQuantitiesCount > 1 then
			for nQuantityCount, tQuantity in pairs(tQuantities) do
				local tQuantityOfferInfo = tQuantity.tQuantityOfferInfo
				
				local wndQuantity = Apollo.LoadForm(self.xmlDoc, "QuantityDropdownItem", self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdownContainer, self)
				wndQuantity:SetData(nQuantityCount)
				
				local wndItemBtn = wndQuantity:FindChild("ItemBtn")
				wndItemBtn:SetData({ tOffer = tOffer, nVariant = tQuantity.nVariant, nCategoryId = nCategoryId })
				wndItemBtn:SetText(nQuantityCount)
				wndItemBtn:SetCheck(nVariant == tQuantity.nVariant)
				
				-- Price Premium
				local wndPrice1 = wndItemBtn:FindChild("CostContainer:Price1")
				if tQuantityOfferInfo.tPrices.tPremium ~= nil then
					wndPrice1:SetAmount(tQuantityOfferInfo.tPrices.tPremium.monPrice, true)
				end
				wndPrice1:Show(tQuantityOfferInfo.tPrices.tPremium ~= nil)
				
				-- Price Alternative
				local wndPrice2 = wndItemBtn:FindChild("CostContainer:Price2")
				if tQuantityOfferInfo.tPrices.tAlternative ~= nil then
					wndPrice2:SetAmount(tQuantityOfferInfo.tPrices.tAlternative.monPrice, true)
				end
				wndPrice2:Show(tQuantityOfferInfo.tPrices.tAlternative ~= nil)
				
				wndItemBtn:FindChild("CostContainer:or"):Show(tQuantityOfferInfo.tPrices.tPremium ~= nil and tQuantityOfferInfo.tPrices.tAlternative ~= nil)
			end
		end
		
		local nQuantityHeight = self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdownContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
			return wndLeft:GetData() < wndRight:GetData()
		end)
		if nQuantityHeight == 0 then
			self.tWndRefs.wndCenterPurchaseConfirmQuantitySection:Show(false)
		else
			local nQuantityHeightChange = nQuantityHeight - self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdownContainer:GetHeight()
			local nLeft, nTop, nRight, nButtom = self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdown:GetAnchorOffsets()
			self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdown:SetAnchorOffsets(nLeft, nTop, nRight, nButtom + nQuantityHeightChange)				
			self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdownBtn:SetText(nVariantQuantityCount)
			
			-- Price Premium
			if tOfferInfo.tPrices.tPremium ~= nil then
				self.tWndRefs.wndCenterPurchaseConfirmQuantityPrice1:SetAmount(tOfferInfo.tPrices.tPremium.monPrice, true)
			end
			self.tWndRefs.wndCenterPurchaseConfirmQuantityPrice1:Show(tOfferInfo.tPrices.tPremium ~= nil)
			
			-- Price Alternative
			if tOfferInfo.tPrices.tAlternative ~= nil then
				self.tWndRefs.wndCenterPurchaseConfirmQuantityPrice2:SetAmount(tOfferInfo.tPrices.tAlternative.monPrice, true)
			end
			self.tWndRefs.wndCenterPurchaseConfirmQuantityPrice2:Show(tOfferInfo.tPrices.tAlternative ~= nil)
			
			self.tWndRefs.wndCenterPurchaseConfirmQuantityPriceOr:Show(tOfferInfo.tPrices.tPremium ~= nil and tOfferInfo.tPrices.tAlternative ~= nil)
		end
	end
	
	-- Variants
	self.tWndRefs.wndCenterPurchaseConfirmVariantSection:Show(tOffer.nNumVariants > 1)
	self.tWndRefs.wndCenterPurchaseConfirmVariantContainer:DestroyChildren()
	if tOffer.nNumVariants > 1 then
		local arVariants = {}
		for idx=1, tOffer.nNumVariants do
			local tVariantOfferInfo = tOfferCache[idx]
			if tVariantOfferInfo == nil then
				tVariantOfferInfo = StorefrontLib.GetOfferInfo(tOffer.nId, idx)
				tOfferCache[idx] = tVariantOfferInfo
			end
			if tVariantOfferInfo ~= nil and #tVariantOfferInfo.tItems > 0 and tVariantOfferInfo.tItems[1].nCount == nVariantQuantityCount then
				table.insert(arVariants, { tVariantOfferInfo = tVariantOfferInfo, nVariant = idx })
			end
		end
	
		if #arVariants > 1 then
			for idx, tVariant in pairs(arVariants) do
				local tVariantOfferInfo = tVariant.tVariantOfferInfo
				local wndVariant = Apollo.LoadForm(self.xmlDoc, "VariantListItem", self.tWndRefs.wndCenterPurchaseConfirmVariantContainer, self)
				
				local tVariantDisplayInfo = nil
				if #tVariantOfferInfo.tItems >= 1 then
					tVariantDisplayInfo = StorefrontLib.GetStoreDisplayInfo(tVariantOfferInfo.tItems[1].nStoreDisplayInfoId)
				end
				self:SetupPreviewWindow(wndVariant, tVariantDisplayInfo, tVariantOfferInfo.tItems)
				
				local wndBtn = wndVariant:FindChild("Btn")
				wndBtn:SetData({ tOffer = tOffer, nVariant = tVariant.nVariant, nCategoryId = nCategoryId })
				wndBtn:SetCheck(tVariant.nVariant == nVariant)
				
				wndVariant:FindChild("Label"):SetText(tVariantOfferInfo.strVariantName)
				wndBtn:SetTooltip(tVariantOfferInfo.strVariantName)
			end
		end
		
		local nVariantHeight = self.tWndRefs.wndCenterPurchaseConfirmVariantContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
		if nVariantHeight == 0 then
			self.tWndRefs.wndCenterPurchaseConfirmVariantSection:Show(false)
		end
	end
	
	-- Bundles
	self:SetupOfferBundles(tOffer, tOfferInfo, self.tWndRefs.wndCenterPurchaseConfirmBundleSection, self.tWndRefs.wndCenterPurchaseConfirmBundleContainer)
	
	-- Purchase Confirm Reset
	self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:SetText(Apollo.GetString("Storefront_Purchase"))
	self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:Enable(false)
	self.tWndRefs.wndCenterPurchaseConfirmGiftBtn:Enable(false)
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterLabel:Show(false)
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:Show(false)
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative:Show(false)
	self.tWndRefs.wndCenterPurchaseConfirmNotEnoughAlternativeCurrency:Show(false)
	
	-- Validation
	local strAlertBody = ""
	if not tOfferInfo.bCanPurchase then
		local strCantPurchaseTooltip = ""
		for _, idEntitlement in pairs(tOfferInfo.arRequiredEntitlements) do
			local tEntitlementInfo = AccountItemLib.GetEntitlementInfo(idEntitlement)
			if tEntitlementInfo then
				strCantPurchaseTooltip = string.format('%s\n%s', strCantPurchaseTooltip, tEntitlementInfo.strName)
			end
		end
		strAlertBody = String_GetWeaselString(Apollo.GetString("Storefront_MissingEntitlementsWarning"), strCantPurchaseTooltip)
	elseif not bPassedCurrencyCheck then
		strAlertBody = Apollo.GetString("AccountInventory_UnableToClaimPaidOrGiftAnyItemsP")
	elseif bCantClaim then
		if bCantClaimAccountPending then
			strAlertBody = Apollo.GetString("Storefront_AccountClaimLimitWithPendingNotice")
		elseif bCantClaimAccount then
			strAlertBody = Apollo.GetString("Storefront_AccountClaimLimitNotice")
		elseif tOfferInfo.bAlreadyOwnBoundMultiRedeem then
			strAlertBody = Apollo.GetString("Storefront_AlreadyOwnMultiRedeemNotice")
		elseif bCantClaimCharacter then
			strAlertBody = Apollo.GetString("Storefront_CharacterClaimLimitNotice")
		end
	end
	
	if strAlertBody ~= "" then
		local _, nStartingValidationHeight = self.tWndRefs.wndCenterPurchaseConfirmValidationNotificationText:SetHeightToContentHeight()
		self.tWndRefs.wndCenterPurchaseConfirmValidationNotificationText:SetAML('<P Font="CRB_InterfaceSmall" TextColor="AlertOrangeYellow">'..strAlertBody..'</P>')
		local _, nNewValidationHeight = self.tWndRefs.wndCenterPurchaseConfirmValidationNotificationText:SetHeightToContentHeight()
		local nValidationHeight = self.tWndRefs.wndCenterPurchaseConfirmValidationNotification:GetHeight()
		
		local nHeight = math.max(nValidationHeight + (nNewValidationHeight - nStartingValidationHeight), self.tWndRefs.wndCenterPurchaseConfirmValidationNotificationAlertIcon:GetHeight())
		
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseConfirmValidationNotification:GetAnchorOffsets()
		self.tWndRefs.wndCenterPurchaseConfirmValidationNotification:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
	end
	
	self.tWndRefs.wndCenterPurchaseConfirmValidationNotification:Show(strAlertBody ~= "")
	self.tWndRefs.wndCenterPurchaseConfirmCurrencySection:Show(not bCantPurchasePremium)
	self.tWndRefs.wndCenterPurchaseConfirmSummaryContainer:Show(not bCantPurchasePremium)
	self.tWndRefs.wndCenterPurchaseConfirmPremiumNotification:Show(bCantPurchasePremium)
	self.tWndRefs.wndCenterPurchaseConfirmSignatureExclusiveLabel:Show(tOfferInfo.nRequiredTier > 0)
	self.tWndRefs.wndCenterPurchaseConfirmSummaryContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Top)
	
	-- Price Alternative
	if not bCantPurchasePremium and tOfferInfo.tPrices.tAlternative ~= nil then
		self.tWndRefs.wndCenterPurchaseConfirmCurrency2:SetAmount(tOfferInfo.tPrices.tAlternative.monPrice, true)
		self.tWndRefs.wndCenterPurchaseConfirmCurrency2Btn:SetCheck(tOfferInfo.tPrices.tPremium == nil or self.bPrefAltCurrency)
		self.tWndRefs.wndCenterPurchaseConfirmCurrency2Btn:SetData({ tOffer = tOffer, tOfferInfo = tOfferInfo, tPrice = tOfferInfo.tPrices.tAlternative, nVariant = nVariant, nCategoryId = nCategoryId })
		self.tWndRefs.wndCenterPurchaseConfirmCurrency2Btn:Enable(true)
		if self.tWndRefs.wndCenterPurchaseConfirmCurrency2Btn:IsChecked() then
			self:OnPurchaseWithCheck(self.tWndRefs.wndCenterPurchaseConfirmCurrency2Btn, self.tWndRefs.wndCenterPurchaseConfirmCurrency2Btn)
		end
	end
	self.tWndRefs.wndCenterPurchaseConfirmCurrency2Container:Show(tOfferInfo.tPrices.tAlternative ~= nil)
	
	-- Price Premium
	if not bCantPurchasePremium and tOfferInfo.tPrices.tPremium ~= nil then
		self.tWndRefs.wndCenterPurchaseConfirmCurrency1:SetAmount(tOfferInfo.tPrices.tPremium.monPrice, true)
		self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn:SetCheck(not self.bPrefAltCurrency or tOfferInfo.tPrices.tAlternative == nil)
		self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn:SetData({ tOffer = tOffer, tOfferInfo = tOfferInfo, tPrice = tOfferInfo.tPrices.tPremium, nVariant = nVariant, nCategoryId = nCategoryId })
		self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn:Enable(true)
		if self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn:IsChecked() then
			self:OnPurchaseWithCheck(self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn, self.tWndRefs.wndCenterPurchaseConfirmCurrency1Btn)
		end
	end
	self.tWndRefs.wndCenterPurchaseConfirmCurrency1Container:Show(tOfferInfo.tPrices.tPremium ~= nil)
	
	-- Sizing
	local nHeight = self.tWndRefs.wndCenterPurchaseConfirm:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Top)
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseRight:GetAnchorOffsets()
	self.tWndRefs.wndCenterPurchaseRight:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
	
	--Realign Quantity Dropdown to the Btn's new position
	local nLeftContainer, nTopContainer, nRightContainer, nBottomContainer = self.tWndRefs.wndCenterPurchaseConfirmQuantitySection:GetAnchorOffsets()
	local nYPosition = nTopContainer + 45
	local nLeftBtn, nTopBtn, nRightBtn, nBottomBtn = self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdownBtn:GetAnchorOffsets()
	local nCenterBtn = (nRightBtn + nLeftBtn)/2
	local nWidthDropdown = self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdown:GetWidth()
	local nHeightDropdown = self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdown:GetHeight()
	local nLeftDropdown, nTopDropdown, nRightDropdown, nButtomDropdown = self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdown:GetAnchorOffsets()
	self.tWndRefs.wndCenterPurchaseConfirmQuantityDropdown:SetAnchorOffsets(nCenterBtn - (nWidthDropdown/2), nYPosition, nCenterBtn + (nWidthDropdown/2), nYPosition + nHeightDropdown)	
end

function Storefront:SetupOfferBundles(tOffer, tOfferInfo, wndSection, wndContainer)
	local nDisplayInfosCount = 0
	local tDisplayInfos = {}
	for idx, nDisplayInfo in pairs(tOfferInfo.tDisplayInfos) do
		local tBundleDisplayInfo = StorefrontLib.GetStoreDisplayInfo(nDisplayInfo)
		
		tDisplayInfos[nDisplayInfo] =
		{
			nCount = 0,
			arItems = {},
			strName = tBundleDisplayInfo.strName,
			tBundleDisplayInfo = tBundleDisplayInfo,
			eClaimState = StorefrontLib.CodeEnumClaimItemState.CanClaim,
			bAlreadyOwnPendingMultiRedeem = false,
			bAlreadyOwnBoundMultiRedeem = false,
		}
		nDisplayInfosCount = nDisplayInfosCount + 1
	end
	for idx, tAccountItem in pairs(tOfferInfo.tItems) do
		if tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.GameItem then
			if tDisplayInfos[tAccountItem.nStoreDisplayInfoId] == nil then
				local tBundleDisplayInfo = StorefrontLib.GetStoreDisplayInfo(tAccountItem.nStoreDisplayInfoId)
			
				tDisplayInfos[tAccountItem.nStoreDisplayInfoId] =
				{
					nCount = 0,
					arItems = {},
					tBundleDisplayInfo = tBundleDisplayInfo,
					eClaimState = StorefrontLib.CodeEnumClaimItemState.CanClaim,
					bAlreadyOwnPendingMultiRedeem = false,
					bAlreadyOwnBoundMultiRedeem = false,
				}
				nDisplayInfosCount = nDisplayInfosCount + 1
				
				if tAccountItem.item ~= nil then
					tDisplayInfos[tAccountItem.nStoreDisplayInfoId].strName = tAccountItem.item:GetName()
				elseif tAccountItem.monCurrency ~= nil then
					tDisplayInfos[tAccountItem.nStoreDisplayInfoId].strName = tAccountItem.monCurrency:GetTypeString()
				elseif tAccountItem.entitlement ~= nil then
					tDisplayInfos[tAccountItem.nStoreDisplayInfoId].strName = tAccountItem.entitlement.name
				end
			end
			
			tDisplayInfos[tAccountItem.nStoreDisplayInfoId].bAlreadyOwnPendingMultiRedeem = tDisplayInfos[tAccountItem.nStoreDisplayInfoId].bAlreadyOwnPendingMultiRedeem or tAccountItem.bAlreadyOwnPendingMultiRedeem
			tDisplayInfos[tAccountItem.nStoreDisplayInfoId].bAlreadyOwnBoundMultiRedeem = tDisplayInfos[tAccountItem.nStoreDisplayInfoId].bAlreadyOwnBoundMultiRedeem or tAccountItem.bAlreadyOwnPendingMultiRedeem
			
			if tAccountItem.eClaimState ~= nil and tAccountItem.eClaimState ~= StorefrontLib.CodeEnumClaimItemState.CanClaim then
				tDisplayInfos[tAccountItem.nStoreDisplayInfoId].eClaimState = tAccountItem.eClaimState
			end
			
			local nCount = tAccountItem.nCount
			if tAccountItem.monCurrency ~= nil then
				nCount = nCount * tAccountItem.monCurrency:GetAmount()
			elseif tAccountItem.entitlement ~= nil then
				nCount = nCount * tAccountItem.entitlement.count
			end
			
			tDisplayInfos[tAccountItem.nStoreDisplayInfoId].nCount = nCount
			table.insert(tDisplayInfos[tAccountItem.nStoreDisplayInfoId].arItems, tAccountItem)
		end
	end
	
	wndSection:Show(nDisplayInfosCount > 1)
	wndContainer:DestroyChildren()
	if nDisplayInfosCount > 1 then
		for nDisplayInfo, tInfo in pairs(tDisplayInfos) do
			local wndBundle = Apollo.LoadForm(self.xmlDoc, "BundleListItem", wndContainer, self)
			
			self:SetupPreviewWindow(wndBundle, tInfo.tBundleDisplayInfo, tInfo.arItems)
			
			local wndBtn = wndBundle:FindChild("Btn")
			wndBtn:SetData({ tBundleDisplayInfo = tInfo.tBundleDisplayInfo, tItems = tInfo.arItems, nCategoryId = nCategoryId })
			wndBtn:SetCheck((tOffer.nDisplayInfoOverride == 0 or tOffer.nDisplayInfoOverride == nDisplayInfo) and idx == 1)
			
			local wndLabel = wndBundle:FindChild("Label")
			if tInfo.nCount > 1 then
				wndLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_BundleEntryNameWithMultiple"), { name = tInfo.strName, count = tInfo.nCount }))
			else
				wndLabel:SetText(String_GetWeaselString("$1n", tInfo.strName))
			end
			
			local wndAlertIcon = wndBundle:FindChild("AlertIcon")
			wndAlertIcon:Show(tInfo.eClaimState ~= StorefrontLib.CodeEnumClaimItemState.CanClaim or tInfo.bAlreadyOwnPendingMultiRedeem or tInfo.bAlreadyOwnBoundMultiRedeem)
			
			if wndAlertIcon:IsShown() then
				local nAlertLeft, nAlertTop, nAlertRight, nAlertBottom = wndAlertIcon:GetAnchorOffsets()
				local nLabelLeft, nLabelTop, nLabelRight, nLabelBottom = wndLabel:GetAnchorOffsets()
				
				wndLabel:SetAnchorOffsets(nLabelLeft, nLabelTop, nAlertLeft, nLabelBottom)
				
				local strAlertBody = ""
				if tInfo.bAlreadyOwnPendingMultiRedeem or tInfo.eClaimState == StorefrontLib.CodeEnumClaimItemState.AccountMaxedWithPending then
					strAlertBody = Apollo.GetString("Storefront_BundleItemPendingAccountMax")
				elseif tInfo.eClaimState == StorefrontLib.CodeEnumClaimItemState.AccountMaxed then
					strAlertBody = Apollo.GetString("Storefront_BundleItemAccountMax")
				elseif tInfo.bAlreadyOwnBoundMultiRedeem then
					strAlertBody = Apollo.GetString("Storefront_BundleItemOwnedMultiClaim")
				elseif tInfo.eClaimState == StorefrontLib.CodeEnumClaimItemState.CharacterMaxed then
					strAlertBody = Apollo.GetString("Storefront_BundleItemCharacterMax")
				end
				
				wndAlertIcon:SetTooltip(strAlertBody)
			end
		end
	
		local nTotalHeight = wndContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		local nPadding = wndSection:FindChild("Icon"):GetHeight()
		local nLeft, nTop, nRight, nBottom = wndSection:GetAnchorOffsets()
		wndSection:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTotalHeight + nPadding)
	end
end

function Storefront:PurchaseConfirmed(tData)
	self:PurchaseDialogShowHelper(self.tWndRefs.wndCenterPurchaseConfirmed)
	Sound.Play(Sound.PlayUIMTXStorePurchaseConfirmation)
	
	local tOffer = tData.tOffer
	local tOfferInfo = tData.tOfferInfo
	local tPrice = tData.tPrice
	
	local bShowInventory = (self.tTutorial ~= nil and tData.tOffer.nId == self.tTutorial.nOfferGroupId and tData.nCategoryId == self.tTutorial.nCategoryId)
	local bShowGotoFortunes = false
	
	for idx, tAccountItem in pairs(tOfferInfo.tItems) do
		if tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.GameItem then
			if tAccountItem.item ~= nil then
				bShowInventory = true
			end
			if tAccountItem.monCurrency ~= nil and tAccountItem.monCurrency:GetAccountCurrencyType() == AccountItemLib.CodeEnumAccountCurrency.MysticShiny then
				bShowGotoFortunes = true
			end
		end
	end
	
	local strClaimMessage = ""
	if tData.tFriend ~= nil then
		strClaimMessage = Apollo.GetString("Storefront_PurchaseGiftConfirmedClaimDetails")
	elseif tData.bAltChar then
		strClaimMessage = Apollo.GetString("Storefront_PurchaseAltConfirmedClaimDetails")
	elseif #tData.tOfferInfo.tItems > 1 then
		strClaimMessage = Apollo.GetString("Storefront_PurchaseConfirmedBundle")
	elseif #tData.tOfferInfo.tItems > 0 then
		local tAccountItem = tOfferInfo.tItems[1]
	
		if tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.GameItem then
			if tAccountItem.item ~= nil then
				if tAccountItem.multiRedeem then
					strClaimMessage = Apollo.GetString("Storefront_PurchaseConfirmedMultiRedeemItem")
				else
					strClaimMessage = Apollo.GetString("Storefront_PurchaseConfirmedItem")
				end
			elseif tAccountItem.monCurrency ~= nil then
				strClaimMessage = Apollo.GetString("Storefront_PurchaseConfirmedCurrency")
			elseif tAccountItem.entitlement ~= nil then
				if tAccountItem.entitlement.eScope == StorefrontLib.CodeEnumEntitlementScope.Account then
					strClaimMessage = Apollo.GetString("Storefront_PurchaseConfirmedAccountEntitlement")
				else
					strClaimMessage = Apollo.GetString("Storefront_PurchaseConfirmedCharacterEntitlement")
				end
			end
		elseif tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.Subscription then
			strClaimMessage = Apollo.GetString("Storefront_PurchaseConfirmedSubscriptionTime")
		end
	end
	
	self.tWndRefs.wndCenterPurchaseConfirmedOpenInventoryBtn:Show(tData.tFriend == nil and not tData.bAltChar and bShowInventory)
	self.tWndRefs.wndCenterPurchaseConfirmedGotoFortunesBtn:Show(tData.tFriend == nil and bShowGotoFortunes)
	
	local strPurchaseSuccessHeader = String_GetWeaselString(Apollo.GetString("Storefront_PurchaseSuccessItemname"), tOfferInfo.strVariantName)
	self.tWndRefs.wndCenterPurchaseConfirmedItemName:SetAML(string.format('<P Align="Center" Font="CRB_Header14" TextColor="UI_BtnTextGreenNormal">%s</P>', strPurchaseSuccessHeader))
	self.tWndRefs.wndCenterPurchaseConfirmedItemName:SetHeightToContentHeight()
	
	self.tWndRefs.wndCenterPurchaseConfirmedClaimDetails:SetAML(string.format('<P Align="Center" Font="CRB_InterfaceMedium" TextColor="UI_TextHoloBody">%s</P>', strClaimMessage))
	self.tWndRefs.wndCenterPurchaseConfirmedClaimDetails:SetHeightToContentHeight()
	
	local nHeight = self.tWndRefs.wndCenterPurchaseConfirmedFramingContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseConfirmedFramingContainer:GetAnchorOffsets()
	self.tWndRefs.wndCenterPurchaseConfirmedFramingContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
	self.tWndRefs.wndCenterPurchaseConfirmedAnimation:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
	
	local strCurrencyName = self:GetCurrencyNameFromEnum(tData.tPrice.eCurrencyType)
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	
	self.tWndRefs.wndCenterPurchaseConfirmedCostLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_TotalCost"), strCurrencyName))
	self.tWndRefs.wndCenterPurchaseConfirmedCostValue:SetAmount(tData.tPrice.monPrice)
	self.tWndRefs.wndCenterPurchaseConfirmedFundsAfterLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_Remaining"), strCurrencyName))
	self.tWndRefs.wndCenterPurchaseConfirmedFundsAfterValue:SetAmount(monBalance)
	self.tWndRefs.wndCenterPurchaseConfirmedAnimation:SetSprite("BK3:UI_BK3_OutlineShimmer_anim_nocycle")
	self.tWndRefs.wndCenterPurchaseConfirmedAnimationInner:SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthLargeTemp")
	
	self:UpdateTutorialHighlight(nil, tData.tOffer, tData.nCategoryId)

	-- Clear friend data out for repeat purchases
	tData.tFriend = nil
	tData.bAltChar = nil
end

function Storefront:PurchaseSelfConfirm(tData)
	local strCurrentCharacterName = GameLib.GetPlayerCharacterName()

	self.tWndRefs.wndCenterPurchaseSelfItemName:SetAML(string.format('<P Align="Center" Font="CRB_Header14" TextColor="UI_BtnTextGreenNormal">%s</P>', tData.tOfferInfo.strVariantName))
	self.tWndRefs.wndCenterPurchaseSelfItemName:SetHeightToContentHeight()
	
	self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtn:SetText(strCurrentCharacterName)
	
	for idx, wndAltEntry in pairs(self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtnDropdownContainer:GetChildren()) do
		local wndAltBtn = wndAltEntry:FindChild("AltBtn")
		wndAltBtn:SetCheck(wndAltBtn:GetData() == strCurrentCharacterName)
	end
	
	self.tWndRefs.wndCenterPurchaseSelfConfirmBtn:SetData({ tData = tData, strCharacterName = strCurrentCharacterName })
end

function Storefront:PurchaseForSelf(tData)
	Sound.Play(Sound.PlayUIMTXStorePurchase)
	
	local promisePurchaseResult = Promise.New()
	Promise.NewFromGameEvent("StorePurchaseOfferResult", self):Then(function(bSuccess)
		if bSuccess then
			promisePurchaseResult:Resolve()
		else
			promisePurchaseResult:Reject()
		end
	end)
	
	local this = self
	
	Promise.WhenAll(promisePurchaseResult, Promise.NewFromGameEvent("AccountCurrencyChanged", self))
	:Then(function()
		Event_FireGenericEvent("HideFullDialog")
		this:PurchaseConfirmed(tData)
	end)
	:Catch(function()
		Event_FireGenericEvent("RequestFullDialogPrompt", Apollo.GetString("Storefront_PurchaseFailedDialogHeader"), Apollo.GetString("Storefront_PurchaseFailedDialogBody"))
	end)
	
	Event_FireGenericEvent("RequestFullDialogSpinner", Apollo.GetString("Storefront_PurchaseInProgressThanks"))
	StorefrontLib.PurchaseOffer(tData.tOfferInfo.nId, tData.tPrice.monPrice, tData.nCategoryId)
end

function Storefront:PurchaseAsGift(tData, strGiftToCharacterName)
	Sound.Play(Sound.PlayUIMTXStorePurchase)

	local promisePurchaseResult = Promise.New()
	Promise.NewFromGameEvent("StorePurchaseOfferResult", self):Then(function(bSuccess, eReason)
		if bSuccess then
			promisePurchaseResult:Resolve()
		else
			promisePurchaseResult:Reject(eReason)
		end
	end)
	
	local this = self
	
	Promise.WhenAll(promisePurchaseResult, Promise.NewFromGameEvent("AccountCurrencyChanged", self))
	:Then(function()
		Event_FireGenericEvent("HideFullDialog")
		this:PurchaseConfirmed(tData)
	end)
	:Catch(function(eReason)
		if eReason == StorefrontLib.CodeEnumStoreError.IneligibleGiftRecipient then
			Event_FireGenericEvent("RequestFullDialogPrompt", Apollo.GetString("Storefront_PurchaseFailedDialogHeader"), Apollo.GetString("Storefront_PurchaseFailedIneligibleGiftRecipient"))
		else
			Event_FireGenericEvent("RequestFullDialogPrompt", Apollo.GetString("Storefront_PurchaseFailedDialogHeader"), Apollo.GetString("Storefront_PurchaseFailedDialogBody"))
		end
	end)
	
	Event_FireGenericEvent("RequestFullDialogSpinner", Apollo.GetString("Storefront_PurchaseInProgressThanks"))
	
	local nFriendId = 0
	if tData.tFriend ~= nil then
		nFriendId = tData.tFriend.nId
	end
	
	StorefrontLib.PurchaseOffer(tData.tOfferInfo.nId, tData.tPrice.monPrice, tData.nCategoryId, 1, nFriendId, strGiftToCharacterName)
end

---------------------------------------------------------------------------------------------------
-- Game Events
---------------------------------------------------------------------------------------------------

function Storefront:UpdateCurrency()
	local monPremium = StorefrontLib.GetBalance(AccountItemLib.GetPremiumCurrency())
	self.tWndRefs.wndWalletPremium:SetAmount(monPremium, true)
	self.tWndRefs.wndWalletAlternative:SetAmount(StorefrontLib.GetBalance(AccountItemLib.GetAlternativeCurrency()), true)
	self.wndTopUpReminder:Show(monPremium:GetAmount() == 0)
	
	local nNewWidth = self.tWndRefs.wndWalletCurrencyContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.LeftOrTop)
	
	local nRightCurrencyContainer = ({self.tWndRefs.wndWalletCurrencyContainer:GetAnchorOffsets()})[3]
	
	local nLeft, nTop, nRight, nButtom = self.tWndRefs.wndWallet:GetAnchorOffsets()
	self.tWndRefs.wndWallet:SetAnchorOffsets(nRightCurrencyContainer - nNewWidth, nTop, nRight, nButtom)
end

---------------------------------------------------------------------------------------------------
-- NavSearch Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnSearchTimer()
	self.timerSearch:Stop()
	
	self:CenterShowHelper(self.tWndRefs.wndCenterContent)
	self:SetupSearchItemPage()
	StorefrontLib.StoreSearched(self.tWndRefs.wndNavSearchEditBox:GetText())
end

function Storefront:NavSearchTextChanged(wndHandler, wndControl, strText)
	if wndHandler ~= wndControl then
		return
	end
	
	if strText == nil or strText == "" then		
		self.timerSearch:Stop()
		
		self.tWndRefs.wndNavSearchClearBtn:Show(false)
		
		local wndNavBtn = self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn")
		self:OnFeaturedCheck(wndNavBtn, wndNavBtn)
		wndNavBtn:SetCheck(true)
		wndControl:SetFocus()
	else
		if self.wndNavInUse ~= nil and self.wndNavInUse:IsValid() then
			for idx, wndNav in pairs(self.tWndRefs.wndNavigation:GetChildren()) do
				local wndNavBtn = wndNav:FindChild("NavBtn")
				if wndNavBtn ~= nil and wndNavBtn:IsValid() then
					wndNavBtn:SetCheck(false)
				end
				local wndChildren = wndNav:FindChild("Children")
				if wndChildren ~= nil and wndChildren:IsValid() then
					wndChildren:DestroyChildren()
					wndNav:MoveToLocation(wndNav:GetOriginalLocation())
				end
			end
			self.tWndRefs.wndNavigation:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		end
		self.wndNavInUse = nil
	
		self.tWndRefs.wndNavSearchClearBtn:Show(true)
		self.timerSearch:Set(0.25)--Reset timer because player is still typing.
	end
end

function Storefront:NavSearchTextClearSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.timerSearch:Stop()
	
	self.tWndRefs.wndNavSearchEditBox:SetText("")
	wndControl:Show(false)
	
	local wndNavBtn = self.tWndRefs.wndNavPrimaryHome:FindChild("NavBtn")
	self:OnFeaturedCheck(wndNavBtn, wndNavBtn)
	wndNavBtn:SetCheck(true)
	wndNavBtn:SetFocus()
end

---------------------------------------------------------------------------------------------------
-- NavPrimary Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnNavPrimaryCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local tCategory = tData
	
	local wndChildren = wndControl:GetParent():FindChild("Children")
	if wndChildren ~= nil then
		if next(wndChildren:GetChildren()) ~= nil then
			wndChildren:DestroyChildren()
		end
		
		for idx, tSubCategory in pairs(tCategory.tGroups) do
			if tSubCategory.bDisplayable then
				local wndCategory = Apollo.LoadForm(self.xmlDoc, "NavSecondary", wndChildren, self)
				self.tNavSubCategoryWndRefs[tSubCategory.nId] = wndCategory
				local wndNavBtn = wndCategory:FindChild("SecondaryNavBtn")
				wndNavBtn:SetText(tSubCategory.strName)
				wndNavBtn:SetData(tSubCategory)
				wndNavBtn:SetTooltip(tSubCategory.strDescription)
			end
		end
		
		local nHeight = wndChildren:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
		
		local nLeft, nTop, nRight, nBottom = wndControl:GetParent():GetAnchorOffsets()
		wndControl:GetParent():SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight + self.knNavPrimaryDefaultHeight + wndControl:GetParent():FindChild("Padding"):GetHeight())
		
		self.tWndRefs.wndNavigation:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	end
	self.wndNavInUse = wndControl
	
	self:CenterShowHelper(self.tWndRefs.wndCenterContent)
	self:SetupCategoryItemPage(tCategory.nId)
	self.tWndRefs.wndNavSearchEditBox:SetText("")
	wndControl:SetFocus()
	
	self:UpdateTutorialHighlight(wndControl, nil, nil)
	
	StorefrontLib.CategoryClicked(tCategory.nId)
end

function Storefront:OnNavPrimaryUncheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local wndChildren = wndControl:GetParent():FindChild("Children")
	
	if wndChildren ~= nil then
		wndChildren:DestroyChildren()
		self.tNavSubCategoryWndRefs = {}
		wndControl:GetParent():MoveToLocation(wndControl:GetParent():GetOriginalLocation())
		
		self.tWndRefs.wndNavigation:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	end
	
	self.wndNavInUse = nil
	
	self:UpdateTutorialHighlight(wndControl, nil, nil)
end

function Storefront:OnPremiumPageCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	self:CenterShowHelper(nil)
	Event_FireGenericEvent("ShowPremiumPage", self.tWndRefs.wndCenter)
	
	if self.wndNavInUse ~= nil and self.wndNavInUse:IsValid() then
		self.wndNavInUse:SetCheck(false)
	end
	self.wndNavInUse = wndControl
	self.tWndRefs.wndNavSearchEditBox:SetText("")
	wndControl:SetFocus()
	
	StorefrontLib.CategoryClicked(-2)
end

function Storefront:OnPremiumStoreCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	self:CenterShowHelper(self.tWndRefs.wndCenterContent)
	self:SetupCategoryItemPage(wndControl:GetData().nId)
	
	if self.wndNavInUse ~= nil and self.wndNavInUse:IsValid() then
		self.wndNavInUse:SetCheck(false)
	end
	self.wndNavInUse = wndControl
	self.tWndRefs.wndNavSearchEditBox:SetText("")
	wndControl:SetFocus()
	
	self:UpdateTutorialHighlight(wndControl, nil, nil)
	
	StorefrontLib.CategoryClicked(wndControl:GetData().nId)
end

function Storefront:OnFeaturedCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	self:ShowFeatured()
	StorefrontLib.CategoryClicked(0)
end

---------------------------------------------------------------------------------------------------
-- NavSecondary Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnNavSecondaryCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local tSubCategory = tData
	
	self:CenterShowHelper(self.tWndRefs.wndCenterContent)
	self:SetupCategoryItemPage(tSubCategory.nId)
	self.tWndRefs.wndNavSearchEditBox:SetText("")
	wndControl:SetFocus()
	
	self:UpdateTutorialHighlight(wndControl, nil, nil)
	
	StorefrontLib.CategoryClicked(tSubCategory.nId)
end

---------------------------------------------------------------------------------------------------
-- Item Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnOfferPreviewSignal(wndHandler, wndControl, eMouseButton)
	local tData = wndControl:GetData()
	self.tWndRefs.wndCenterPurchaseScrollContent:SetVScrollPos(0)
	self:SetupOffer(tData.tOffer, 1, tData.nCategoryId)
	
	self:UpdateTutorialHighlight(wndControl, tData.tOffer, tData.nCategoryId)
end

function Storefront:OnOfferItemGenerateTooltip(wndHandler, wndControl, eToolTipType, x, y)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local tOffer = tData.tOffer
	local tOfferInfo = tData.tOfferInfo
	local tDisplayInfo = tData.tDisplayInfo
	
	local wndTooltip = wndControl:LoadTooltipForm(self.xmlDoc, "ItemTooltip", self)
	
	wndTooltip:FindChild("Title"):SetAML("<P Font=\"CRB_HeaderSmall\" TextColor=\"UI_WindowTitleYellow\">"..tOffer.strName.."</P>")
	wndTooltip:FindChild("Title"):SetHeightToContentHeight()
	wndTooltip:FindChild("Description"):SetAML("<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBody\">"..tOffer.strDescription.."</P>")
	wndTooltip:FindChild("Description"):SetHeightToContentHeight()
	
	-- Callout
	wndTooltip:FindChild("ExclusiveLabel"):Show(tOfferInfo.nRequiredTier > 0)

	local wndItemCallout = wndTooltip:FindChild("ItemCallout")
	if tOffer.tFlags.bLimitedTime then
		wndItemCallout:Show(true)
		wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.LimitedTime].sprCallout)
		wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.LimitedTime].strTooltip)
		
	elseif tOffer.tFlags.bRecommended then
		wndItemCallout:Show(true)
		wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Recommended].sprCallout)
		wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Recommended].strTooltip)
		
	elseif tOffer.tFlags.bNew then
		wndItemCallout:Show(true)
		wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.New].sprCallout)
		wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.New].strTooltip)
		
	elseif tOffer.tFlags.bPopular then
		wndItemCallout:Show(true)
		wndItemCallout:SetSprite(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Popular].sprCallout)
		wndItemCallout:SetTooltip(self.ktFlags[StorefrontLib.CodeEnumStoreDisplayFlag.Popular].strTooltip)
		
	else
		wndItemCallout:Show(false)
	end
	
	-- Banners
	local wndBannerContainer = wndTooltip:FindChild("BannerContainer")
	self:BuildBannersForContainer(tOffer, tOfferInfo, wndBannerContainer)
	
	local nBannerContainerHeight = wndBannerContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	wndBannerContainer:Show(nBannerContainerHeight > 0)
	if nBannerContainerHeight > 0 then
		local nLeft, nTop, nRight, nBottom = wndBannerContainer:GetAnchorOffsets()
		wndBannerContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nBannerContainerHeight)
	end
	
	-- Price	
	local wndPriceContainer = wndTooltip:FindChild("PriceContainer")
	
	local nLargestDiscount = 0
	
	-- Price Premium
	nLargestDiscount = math.max(nLargestDiscount, self:SetupPriceContainer(wndPriceContainer:FindChild("Price1BG"), tOfferInfo.tPrices.tPremium))
	
	-- Price Alternative
	nLargestDiscount = math.max(nLargestDiscount, self:SetupPriceContainer(wndPriceContainer:FindChild("Price2BG"), tOfferInfo.tPrices.tAlternative))
	
	wndPriceContainer:FindChild("or"):Show(tOfferInfo.tPrices.tPremium ~= nil and tOfferInfo.tPrices.tAlternative ~= nil)
	
	if nLargestDiscount == 0 and not self:HasDiscount(tOfferInfo) then
		local nLeft, nTop, nRight, nBottom = wndPriceContainer:GetAnchorOffsets()
		wndPriceContainer:SetAnchorOffsets(nLeft, nTop + 15, nRight, nBottom)
	end
	
	-- Sizing
	local wndSectionStack = wndTooltip:FindChild("SectionStack")
	local nSectionStackHeight = wndSectionStack:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)
	local nSectionStackHeightChange = nSectionStackHeight - wndSectionStack:GetHeight()
	
	local nLeft, nTop, nRight, nBottom = wndTooltip:GetAnchorOffsets()
	wndTooltip:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nSectionStackHeightChange)
end

---------------------------------------------------------------------------------------------------
-- Layout Functions
---------------------------------------------------------------------------------------------------
-- Order History
function Storefront:OnPurchaseHistorySignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndModelDialog:Show(true)
	Event_FireGenericEvent("ShowDialog", "History", self.tWndRefs.wndModelDialog)
end

-- Account Inventory
function Storefront:OnAccountInventorySignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	self.tWndRefs.wndModelDialog:Show(true)
	Event_FireGenericEvent("ShowDialog", "AccountInventory", self.tWndRefs.wndModelDialog)
end

function Storefront:OnAccountInventoryWindowShow()
	self.tWndRefs.wndModelDialog:Show(true)
	Event_FireGenericEvent("ShowDialog", "AccountInventory", self.tWndRefs.wndModelDialog)
end

function Storefront:OnFullDialogPromptConfirmSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndFullBlocker:Show(false, false, 0.15)
	
	local tData = wndControl:GetData()
	if tData.fnCallback ~= nil then
		tData.fnCallback(self)
	end
end

function Storefront:OnAddFundsSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	if StorefrontLib.IsSteam() then
		StorefrontLib.RedirectToSteamNCoinPurchase()
	else
		self.tWndRefs.wndModelDialog:Show(true)
		Event_FireGenericEvent("ShowDialog", "Funds", self.tWndRefs.wndModelDialog)
	end
end

function Storefront:OnDialogCancelSignal(wndHandler, wndControl, eMouseButton)
	self.tWndRefs.wndCenterPurchase:Show(false)
	
	if self.tTutorial ~= nil then
		local wndTargetBtn = nil
		local tData = wndControl:GetData()
		-- if not in the right category or subcategory then it should remain nil
		if tData.nCategoryId == self.tTutorial.nCategoryId or tData.nCategoryId == self.tTutorial.nSubCategoryId then
			-- if there's a subcategory then target that otherwise use category
			if self.tTutorial.tItems[self.ktTutorialBtn.SubCategory] and self.tTutorial.tItems[self.ktTutorialBtn.SubCategory].wndTargetBtn ~= nil then
				wndTargetBtn = self.tTutorial.tItems[self.ktTutorialBtn.SubCategory].wndTargetBtn
			else
				wndTargetBtn = self.tTutorial.tItems[self.ktTutorialBtn.Category].wndTargetBtn
			end
		end
		self:UpdateTutorialHighlight(wndTargetBtn, nil, nil)
	end
end

function Storefront:OnContinueShoppingSignal(wndHandler, wndControl, eMouseButton)
	self:PurchaseDialogShowHelper(nil)
	
	local tData = self.tWndRefs.wndCenterPurchaseConfirm:GetData()
	self:SetupOffer(tData.tOffer, tData.nVariant, tData.nCategoryId)
end

function Storefront:OnBannerSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	if tData == nil then
		return
	end
	
	if tData.eBannerProductType == StorefrontLib.BannerPageType.Product
		or tData.eBannerProductType == StorefrontLib.CodeEnumBannerLocation.OfferGroupLocation then
		
		self:SetupOffer(StorefrontLib.GetOfferGroupInfo(tData.nBannerProduct), 1, 0)
	elseif tData.eBannerProductType == StorefrontLib.BannerPageType.SearchTerm then
		local wndEditBox = self.tWndRefs.wndCenterFilters:FindChild("EditBox")
		wndEditBox:SetText(tData.strBannerProduct)
		self:NavSearchTextChanged(wndEditBox, wndEditBox)
	elseif tData.eBannerProductType == StorefrontLib.BannerPageType.Category then
		self:ShowCategoryPage(tData.nBannerProduct)
	elseif tData.eBannerProductType == StorefrontLib.BannerPageType.BrowserLink then
		StorefrontLib.OpenBannerBrowserLink(tData.nStoreBannerId)
	elseif tData.eBannerProductType == StorefrontLib.BannerPageType.Signature then
		self:OnOpenSignature()
	end
	
	StorefrontLib.BannerClicked(tData.eLocation, tData.nOrder)
end

function Storefront:ShowCategoryPage(nCategoryId)
	for idx, tPrimaryCategory in pairs(StorefrontLib.GetCategoryTree()) do
		if tPrimaryCategory.nId == nCategoryId then
				
			if self.wndNavInUse ~= nil and self.wndNavInUse:IsValid() then
				self.wndNavInUse:SetCheck(false)
			end
			
			local wndPrimaryNav = self.tNavCategoryWndRefs[tPrimaryCategory.nId]
			if wndPrimaryNav ~= nil and wndPrimaryNav:IsValid() then
				local wndPrimaryNavBtn = wndPrimaryNav:FindChild("NavBtn")
				self:OnNavPrimaryCheck(wndPrimaryNavBtn, wndPrimaryNavBtn)
				wndPrimaryNavBtn:SetCheck(true)
			end
				
			return
		end
			
		for idx, tSubCategory in pairs(tPrimaryCategory.tGroups) do
			if tSubCategory.nId == nCategoryId then
				if self.wndNavInUse ~= nil and self.wndNavInUse:IsValid() then
					self.wndNavInUse:SetCheck(false)
				end
					
				local wndPrimaryNav = self.tNavCategoryWndRefs[tPrimaryCategory.nId]
				if wndPrimaryNav == nil or not wndPrimaryNav:IsValid() then
					break
				end
				
				local wndPrimaryNavBtn = wndPrimaryNav:FindChild("NavBtn")
				self:OnNavPrimaryCheck(wndPrimaryNavBtn, wndPrimaryNavBtn)
				wndPrimaryNavBtn:SetCheck(true)
				
				local wndSecondaryNav = self.tNavSubCategoryWndRefs[tSubCategory.nId]
				if wndSecondaryNav ~= nil and wndSecondaryNav:IsValid() then
					local wndSecondaryNavBtn = wndSecondaryNav:FindChild("SecondaryNavBtn")
					self:OnNavSecondaryCheck(wndSecondaryNavBtn, wndSecondaryNavBtn)
					wndSecondaryNavBtn:SetCheck(true)
				end
				
				return
			end
		end
	end
	
	self:CenterShowHelper(self.tWndRefs.wndCenterContent)
	self:SetupCategoryItemPage(nCategoryId)
	self.tWndRefs.wndNavSearchEditBox:SetText("")
	self.tWndRefs.wndCenterContent:SetFocus()
end

-- Sorting
function Storefront:ToggleSortCheckBox(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	self.tSortingOptions =  wndControl:IsChecked() and wndControl:GetData() or {}
	self.nFilterOptions = wndControl:IsChecked() and wndControl:GetData() and wndControl:GetData().eDisplayFlag or 0

	if self.idLastCategory then
		self:SetupCategoryItemPage(self.idLastCategory)
	else
		self:SetupSearchItemPage()
	end
end

-- Purchasing
function Storefront:OnPurchaseWithCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	local tData = wndControl:GetData()
	local tOfferInfo = tData.tOfferInfo

	local bCantClaim = true
	local bCantPurchasePremium = tOfferInfo.nRequiredTier > AccountItemLib.GetPremiumTier()
	local bContainsFortuneCoins = false
	local bPassedCurrencyCheck = AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.FraudCheck) == 0
	
	for _, tAccountItem in pairs(tOfferInfo.tItems) do
		if tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.GameItem then
			bCantClaimCharacter = bCantClaimCharacter or (tAccountItem.eClaimState ~= nil and tAccountItem.eClaimState == StorefrontLib.CodeEnumClaimItemState.CharacterMaxed)
			bCantClaimAccount = bCantClaimAccount or (tAccountItem.eClaimState ~= nil
				and (tAccountItem.eClaimState == StorefrontLib.CodeEnumClaimItemState.AccountMaxed or tAccountItem.eClaimState == StorefrontLib.CodeEnumClaimItemState.AccountMaxedWithPending))
				or tAccountItem.bAlreadyOwnBoundMultiRedeem
				or tAccountItem.bAccountUnlockAlreadyOwned
			bCantClaimAccountPending = bCantClaimAccountPending
				or (tAccountItem.eClaimState ~= nil and tAccountItem.eClaimState == StorefrontLib.CodeEnumClaimItemState.AccountMaxedWithPending)
				or tAccountItem.bAlreadyOwnPendingMultiRedeem
		
			bCantClaim = bCantClaim
				and ((tAccountItem.eClaimState ~= nil and tAccountItem.eClaimState ~= StorefrontLib.CodeEnumClaimItemState.CanClaim)
					or tAccountItem.bAlreadyOwnPendingMultiRedeem or tAccountItem.bAlreadyOwnBoundMultiRedeem or tAccountItem.bAccountUnlockAlreadyOwned)
		elseif tAccountItem.eItemType == StorefrontLib.CodeEnumStoreItemType.Subscription then
			bCantClaim = false
		end
	end
	
	local strCurrencyName = self:GetCurrencyNameFromEnum(tData.tPrice.eCurrencyType)	
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	
	self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:SetTooltip("")
	
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterLabel:SetText(String_GetWeaselString(Apollo.GetString("Storefront_CurrencyAfterPurchase"), strCurrencyName))
	if monBalance:GetAmount() - tData.tPrice.monPrice:GetAmount() >= 0 then
		local monAfter = Money.new()
		monAfter:SetAccountCurrencyType(tData.tPrice.eCurrencyType)
		monAfter:SetAmount(monBalance:GetAmount() - tData.tPrice.monPrice:GetAmount())
		
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:SetAmount(monAfter, true)
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:SetTextColor(ApolloColor.new("white"))
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterLabel:SetTextColor("ff56b381")
		
		self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:Enable(not bCantClaim)
		
		if bCantClaimAccount or bCantClaimAccountPending then
			self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:SetTooltip(Apollo.GetString("Storefront_PurchaseOmnibitsDisableTooltip"))
		end
		
		self.tWndRefs.wndCenterPurchaseConfirmNotEnoughAlternativeCurrency:Show(false)
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative:Show(false)
	else
		local monAfter = Money.new()
		monAfter:SetAccountCurrencyType(tData.tPrice.eCurrencyType)
		monAfter:SetAmount(tData.tPrice.monPrice:GetAmount() - monBalance:GetAmount())

		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:SetAmount(monAfter, true)
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:SetTextColor(ApolloColor.new("Reddish"))
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterLabel:SetTextColor(ApolloColor.new("Reddish"))
		
		self.tWndRefs.wndCenterPurchaseConfirmNotEnoughAlternativeCurrency:Show(tData.tPrice.eCurrencyType == AccountItemLib.GetAlternativeCurrency())
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative:Show(true)
		self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:Enable(tData.tPrice.eCurrencyType == AccountItemLib.GetPremiumCurrency() and not bCantClaim)
		
		local nWidth = self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:GetDisplayWidth()
		local nFundsValueRight = math.abs(({self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:GetAnchorOffsets()})[3]) --3 is the right offset
		local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative:GetAnchorOffsets()
		
		nRight = -nWidth - nFundsValueRight
		nLeft = nRight - self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative:GetWidth()
		
		self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValueNegative:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
	end
	if tData.tPrice.eCurrencyType ~= AccountItemLib.GetPremiumCurrency() then
		self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:SetText(String_GetWeaselString(Apollo.GetString("Storefront_PurchaseWithOmnibits")))
		self.tWndRefs.wndCenterPurchaseConfirmGiftBtn:SetTooltip(String_GetWeaselString(Apollo.GetString("Storefront_PurchaseWithOmnibitsTooltip")))
		self.tWndRefs.wndCenterPurchaseConfirmGiftBtn:Enable(false)
		self.bPrefAltCurrency = true
	else
		self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:SetText(String_GetWeaselString(Apollo.GetString("Storefront_PurchaseWithCurrency"), strCurrencyName))
		
		if AccountItemLib.GetEntitlementCount(AccountItemLib.CodeEnumEntitlement.TwoStepVerification) > 0 then
			self.tWndRefs.wndCenterPurchaseConfirmGiftBtn:SetTooltip("")
			self.tWndRefs.wndCenterPurchaseConfirmGiftBtn:Enable(bPassedCurrencyCheck)
		else
			self.tWndRefs.wndCenterPurchaseConfirmGiftBtn:SetTooltip(Apollo.GetString("Storefront_GiftingTwoFactorRequired"))
			self.tWndRefs.wndCenterPurchaseConfirmGiftBtn:Enable(false)
		end
		self.bPrefAltCurrency = false
	end

	if not tOfferInfo.bCanPurchase then
		self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:Enable(false)
		self.tWndRefs.wndCenterPurchaseConfirmGiftBtn:Enable(false)
	end
	
	self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn:SetData(tData)
	self.tWndRefs.wndCenterPurchaseConfirmGiftBtn:SetData(tData)
	
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterLabel:Show(true)
	self.tWndRefs.wndCenterPurchaseConfirmFundsAfterValue:Show(true)
	local nHeight = self.tWndRefs.wndCenterPurchaseConfirm:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.Top)
	local nLeft, nTop, nRight, nBottom = self.tWndRefs.wndCenterPurchaseRight:GetAnchorOffsets()
	self.tWndRefs.wndCenterPurchaseRight:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
	self.tWndRefs.wndCenterPurchaseScrollContent:RecalculateContentExtents()	
end

function Storefront:OnPurchaseConfirmSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	
	if monBalance:GetAmount() < tData.tPrice.monPrice:GetAmount() then
		if tData.tPrice.eCurrencyType == AccountItemLib.GetPremiumCurrency() then
			self:PurchaseShowHelper(nil)
			Event_FireGenericEvent("ShowNeedsFunds", self.tWndRefs.wndCenterPurchaseRight, tData)
			self.tWndRefs.wndCenterPurchaseScrollContent:RecalculateContentExtents()
			self.tWndRefs.wndCenterPurchaseScrollContent:SetVScrollPos(0)
			Sound.Play(Sound.PlayUIMTXStorePurchaseFailed)
		end
	else
		if not tData.tOfferInfo.bAccountLevelItemsOnly and #AccountItemLib.GetCharacterNames() > 1 then
			self:PurchaseDialogShowHelper(self.tWndRefs.wndCenterPurchaseSelf)
			self:PurchaseSelfConfirm(tData)
			self:UpdateTutorialHighlight(wndControl, nil, nil)
		else
			self:PurchaseForSelf(tData)
		end
	end
end

function Storefront:OnPurchaseGiftSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	
	if monBalance:GetAmount() < tData.tPrice.monPrice:GetAmount() then
		if tData.tPrice.eCurrencyType == AccountItemLib.GetPremiumCurrency() then
			self:PurchaseShowHelper(nil)
			Event_FireGenericEvent("ShowNeedsFunds", self.tWndRefs.wndCenterPurchaseRight, tData)
			self.tWndRefs.wndCenterPurchaseScrollContent:RecalculateContentExtents()
			self.tWndRefs.wndCenterPurchaseScrollContent:SetVScrollPos(0)
		end
	else
		local tOfferInfo = tData.tOfferInfo
		
		self.tWndRefs.wndCenterPurchaseConfirmed:Show(false)
		self.tWndRefs.wndCenterPurchaseGifting:Show(true)
		
		self.tWndRefs.wndCenterPurchaseGiftingConfirmBtn:SetData(tData)
		self.tWndRefs.wndCenterPurchaseGiftingConfirmBtn:Enable(false)
		self.tWndRefs.wndCenterPurchaseGiftingCharacterNameEditBox:SetText("")
		self.tWndRefs.wndCenterPurchaseGiftingCharacterNameClearBtn:Show(false)
		
		self.tWndRefs.wndCenterPurchaseGiftingTitle:SetText(String_GetWeaselString(Apollo.GetString("Storefront_GiftDialogTitle"), tOfferInfo.strVariantName))
		
		self:BuildGiftFriendAndAltList()
		
		self.tWndRefs.wndCenterPurchaseGiftingPriceValue:SetAmount(tData.tPrice.monPrice)
	end
end

function Storefront:OnPurchaseNeedsPremiumSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self:OnOpenSignature()
end

function Storefront:OnFriendCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tFriend = wndControl:GetData()
	local tData = self.tWndRefs.wndCenterPurchaseGiftingConfirmBtn:GetData()
	tData.tFriend = tFriend
	
	self.tWndRefs.wndCenterPurchaseGiftingConfirmBtn:Enable(true)
	if tData.tFriend.bIsFriend then
		self.tWndRefs.wndCenterPurchaseGiftingCharacterNameEditBox:SetText(tData.tFriend.tFriend.strCharacterName)
	elseif tData.tFriend.bIsAlt then
		self.tWndRefs.wndCenterPurchaseGiftingCharacterNameEditBox:SetText(tData.tFriend.strCharacterName)
	end
	self.tWndRefs.wndCenterPurchaseGiftingCharacterNameClearBtn:Show(true)
end

function Storefront:OnFriendUncheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = self.tWndRefs.wndCenterPurchaseGiftingConfirmBtn:GetData()
	tData.tFriend = nil
	
	self.tWndRefs.wndCenterPurchaseGiftingConfirmBtn:Enable(false)
end

function Storefront:GiftCharacterNameTextChanged(wndHandler, wndControl, strText)
	if wndHandler ~= wndControl then
		return
	end

	local tData = self.tWndRefs.wndCenterPurchaseGiftingConfirmBtn:GetData()
	tData.tFriend = nil
	
	self.tWndRefs.wndCenterPurchaseGiftingConfirmBtn:Enable(strText ~= nil and strText ~= "")
	self.tWndRefs.wndCenterPurchaseGiftingCharacterNameClearBtn:Show(strText ~= nil and strText ~= "")
	
	self:BuildGiftFriendAndAltList(strText)
end

function Storefront:GiftCharacterNameTextClearSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = self.tWndRefs.wndCenterPurchaseGiftingConfirmBtn:GetData()
	tData.tFriend = nil
	
	self.tWndRefs.wndCenterPurchaseGiftingFriendGiftConfirmContainer:SetGlobalRadioSel("StorePurchaseFriendEntry", -1)
	self.tWndRefs.wndCenterPurchaseGiftingConfirmBtn:Enable(false)
	self.tWndRefs.wndCenterPurchaseGiftingCharacterNameEditBox:SetText("")
	wndControl:Show(false)
	
	self:BuildGiftFriendAndAltList()
end

function Storefront:OnShowAltsCheck(wndHandler, wndControl, eMouseButton)
	self:BuildGiftFriendAndAltList(self.tWndRefs.wndCenterPurchaseGiftingCharacterNameEditBox:GetText())
end

function Storefront:OnShowAltsUncheck(wndHandler, wndControl, eMouseButton)
	self:BuildGiftFriendAndAltList(self.tWndRefs.wndCenterPurchaseGiftingCharacterNameEditBox:GetText())
end

function Storefront:BuildGiftFriendAndAltList(strFilter)
	local nFilterLength = 0
	if strFilter ~= nil then
		strFilter = string.lower(strFilter)
		nFilterLength = string.len(strFilter)
	end

	self.tWndRefs.wndCenterPurchaseGiftingFriendGiftConfirmContainer:DestroyChildren()
	for idx, tFriend in pairs(FriendshipLib.GetList()) do
		if tFriend.bFriend and (strFilter == nil or strFilter == "" or string.lower(string.sub(tFriend.strCharacterName, 0, nFilterLength)) == strFilter) then -- Not Ignore or Rival
			local wndFriend = Apollo.LoadForm(self.xmlDoc, "FriendEntry", self.tWndRefs.wndCenterPurchaseGiftingFriendGiftConfirmContainer, self)
			
			local wndFriendNote = wndFriend:FindChild("FriendNote")
			wndFriendNote:SetTooltip(tFriend.strNote or "")
			wndFriendNote:Show(Apollo.StringLength(tFriend.strNote or "") > 0)
			
			local wndFriendButton = wndFriend:FindChild("FriendButton")
			wndFriendButton:SetText(tFriend.strCharacterName)
			wndFriendButton:SetData({ bIsFriend = true, tFriend = tFriend })
		end
	end
	
	if self.tWndRefs.wndCenterPurchaseGiftingShowAltsBtn:IsChecked() then
		for idx, strCharacterName in pairs(AccountItemLib.GetCharacterNames()) do
			if strFilter == nil or strFilter == "" or string.lower(string.sub(strCharacterName, 0, nFilterLength)) == strFilter then
				local wndFriend = Apollo.LoadForm(self.xmlDoc, "FriendEntry", self.tWndRefs.wndCenterPurchaseGiftingFriendGiftConfirmContainer, self)
				wndFriend:FindChild("FriendNote"):Show(false)
				
				local wndFriendButton = wndFriend:FindChild("FriendButton")
				wndFriendButton:SetText(strCharacterName)
				wndFriendButton:SetData({ bIsAlt = true, strCharacterName = strCharacterName })
			end
		end
	end
	
	self.tWndRefs.wndCenterPurchaseGiftingFriendGiftConfirmContainer:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop, function(wndLeft, wndRight)
		return wndLeft:FindChild("FriendButton"):GetText() < wndRight:FindChild("FriendButton"):GetText()
	end)
end

function Storefront:OnAltCheck(wndHandler, wndControl, eMouseButton)
	local strCharacterName = wndControl:GetData()

	local tData = self.tWndRefs.wndCenterPurchaseSelfConfirmBtn:GetData()
	tData.strCharacterName = strCharacterName
	
	self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtn:SetText(strCharacterName)
	self.tWndRefs.wndCenterPurchaseSelfAltDropdownBtn:SetCheck(false)
end

function Storefront:OnPurchaseSelfConfirmSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local strCurrentCharacterName = GameLib.GetPlayerCharacterName()
	local tData = self.tWndRefs.wndCenterPurchaseSelfConfirmBtn:GetData()
	
	if tData.strCharacterName == strCurrentCharacterName then
		self:PurchaseForSelf(tData.tData)
	else
		tData.tData.bAltChar = true
		self:PurchaseAsGift(tData.tData, tData.strCharacterName)
	end
end

function Storefront:OnPurchaseSelfCancelSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end

	self:PurchaseDialogShowHelper(nil)
end

function Storefront:OnPurchaseGiftConfirmSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	local monBalance = StorefrontLib.GetBalance(tData.tPrice.eCurrencyType)
	
	if monBalance:GetAmount() < tData.tPrice.monPrice:GetAmount() then
		if tData.tPrice.eCurrencyType == AccountItemLib.GetPremiumCurrency() then
			self:PurchaseDialogShowHelper(nil)
			Event_FireGenericEvent("ShowNeedsFunds", self.tWndRefs.wndCenterPurchaseRight, tData)
			self.tWndRefs.wndCenterPurchaseScrollContent:RecalculateContentExtents()
			self.tWndRefs.wndCenterPurchaseScrollContent:SetVScrollPos(0)
		end
	else
		self:PurchaseAsGift(tData, self.tWndRefs.wndCenterPurchaseGiftingCharacterNameEditBox:GetText())
	end
end

function Storefront:OnPendingGiftConfirmCancelSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = self.tWndRefs.wndCenterPurchaseGiftingConfirmBtn:GetData()
	tData.tFriend = nil
	
	self:PurchaseDialogShowHelper(nil)
end

function Storefront:OnPurchaseConfirmedSignal(wndHandler, wndControl, eMouseButton)
	OpenAccountInventory()
end

function Storefront:OnOpenInventorySignal(wndHandler, wndControl, eMouseButton)
	self:UpdateTutorialHighlight(wndControl, nil, nil)
	self:PurchaseDialogShowHelper(nil)
	OpenInventory()
end

function Storefront:OnGotoFortunesSignal(wndHandler, wndControl, eMouseButton)
	self:PurchaseDialogShowHelper(nil)
	OpenFortunes()
end

-- Close Store
function Storefront:OnCloseStoreSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	self:PurchaseDialogShowHelper(nil)
	CloseStore()
end

-- Preview
function Storefront:OnPreviewOnMeCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	
	self:SetupPreviewWindowForMe(self.tWndRefs.wndCenterPurchaseLeft, tData.tDisplayInfo, tData.tItems)
	
	self.tWndRefs.wndCenterPurchasePreviewSheathedBtn:Show(true)
	self.tWndRefs.wndCenterPurchasePreviewSheathedBtn:SetCheck(true)
	self.tWndRefs.wndCenterPurchasePreview:SetSheathed(true)
end

function Storefront:OnPreviewOnMeUncheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	
	self:SetupPreviewWindow(self.tWndRefs.wndCenterPurchaseLeft, tData.tDisplayInfo, tData.tItems)
	self.tWndRefs.wndCenterPurchasePreviewSheathedBtn:Show(false)
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer ~= nil and unitPlayer:IsValid() then
		self.tWndRefs.wndCenterPurchasePreview:SetModelSequence(self.ktClassAnimation[unitPlayer:GetClassId()].eStand)
	end
end

function Storefront:OnPreviewSheathedCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndCenterPurchasePreview:SetSheathed(true)
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer ~= nil and unitPlayer:IsValid() then
		self.tWndRefs.wndCenterPurchasePreview:SetModelSequence(StorefrontLib.CodeEnumModelSequence.DefaultStand)
	end
end

function Storefront:OnPreviewSheathedUncheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	self.tWndRefs.wndCenterPurchasePreview:SetSheathed(false)
	
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer ~= nil and unitPlayer:IsValid() then
		self.tWndRefs.wndCenterPurchasePreview:SetModelSequence(self.ktClassAnimation[unitPlayer:GetClassId()].eReady)
	end
end

function Storefront:OnUpdateFullDialogPromptConfirmSignal(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	StorefrontLib.MarkStoreUiUpdateMessageSeen()
	self.tWndRefs.wndFullScreenUpdate:Show(false)
end

---------------------------------------------------------------------------------------------------
-- VariantListItem Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnVariantListItemCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	
	local nHorzScroll = self.tWndRefs.wndCenterPurchaseConfirmVariantContainer:GetHScrollPos()
	self:SetupOffer(tData.tOffer, tData.nVariant, tData.nCategoryId)
	self.tWndRefs.wndCenterPurchaseConfirmVariantContainer:SetHScrollPos(nHorzScroll)
end

---------------------------------------------------------------------------------------------------
-- QuantityDropdownItem Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnQuantityItemCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	
	local nHorzScroll = self.tWndRefs.wndCenterPurchaseConfirmVariantContainer:GetHScrollPos()
	self:SetupOffer(tData.tOffer, tData.nVariant, tData.nCategoryId)
	self.tWndRefs.wndCenterPurchaseConfirmVariantContainer:SetHScrollPos(nHorzScroll)
end

---------------------------------------------------------------------------------------------------
-- BundleListItem Functions
---------------------------------------------------------------------------------------------------

function Storefront:OnBundleListItemCheck(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	
	local tData = wndControl:GetData()
	
	self:SetupPreviewWindow(self.tWndRefs.wndCenterPurchaseLeft, tData.tBundleDisplayInfo, tData.tItems)
	
	if self.tWndRefs.wndCenterPurchasePreviewOnMeBtn:IsChecked()
		and tData.tBundleDisplayInfo ~= nil
		and (tData.tBundleDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin
			or tData.tBundleDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.CustomMannequin) then
		
		self:SetupPreviewWindowForMe(self.tWndRefs.wndCenterPurchaseLeft, tData.tBundleDisplayInfo, tData.tItems)
	end
	
	self.tWndRefs.wndCenterPurchasePreviewOnMeBtn:SetData({tDisplayInfo = tData.tBundleDisplayInfo, tItems = tData.tItems})
	self.tWndRefs.wndCenterPurchasePreviewOnMeBtn:Show(tData.tBundleDisplayInfo ~= nil and (tData.tBundleDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.Mannequin or tData.tBundleDisplayInfo.eDisplayType == StorefrontLib.CodeEnumStoreDisplayInfoDisplayType.CustomMannequin))
	self.tWndRefs.wndCenterPurchasePreviewSheathedBtn:Show(self.tWndRefs.wndCenterPurchasePreviewOnMeBtn:IsShown())
	self.tWndRefs.wndCenterPurchasePreviewSheathedBtn:SetCheck(true)
	self.tWndRefs.wndCenterPurchasePreview:SetSheathed(true)
end

---------------------------------------------------------------------------------------------------
-- Tutorial Functions
---------------------------------------------------------------------------------------------------

function Storefront:BuildStoreTutorial()
	if self.tTutorial ~= nil or self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() then
		return
	end
	
	local tTutorialData = StorefrontLib.GetStoreTutorialOffer()
	if tTutorialData ~= nil then
		self.tTutorial =
		{
			nCurrentPos = 6,
			nCategoryId = tTutorialData.nCategoryId,
			nSubCategoryId = tTutorialData.nSubCategoryId,
			nOfferGroupId = tTutorialData.nOfferGroupId,
			tItems = 
			{
				{ wndTargetBtn = self.tWndRefs.wndCenterPurchaseConfirmedOpenInventoryBtn,	strCalloutName = self.ktTutorialCalloutNames[self.ktTutorialBtn.OpenInventory] },
				{ wndTargetBtn = self.tWndRefs.wndCenterPurchaseSelfConfirmBtn,				strCalloutName = self.ktTutorialCalloutNames[self.ktTutorialBtn.ConfirmSelfBuyItem] },
				{ wndTargetBtn = self.tWndRefs.wndCenterPurchaseConfirmFinalizeBtn,			strCalloutName = self.ktTutorialCalloutNames[self.ktTutorialBtn.BuyItem] },
				-- The following items wndTargetBtn are not currently known but will be found later
				{ wndTargetBtn = nil,														strCalloutName = self.ktTutorialCalloutNames[self.ktTutorialBtn.Items] },
				{ wndTargetBtn = nil,														strCalloutName = self.ktTutorialCalloutNames[self.ktTutorialBtn.SubCategory] },
				{ wndTargetBtn = nil,														strCalloutName = self.ktTutorialCalloutNames[self.ktTutorialBtn.Category] },
			},
		}
	end
end

function Storefront:UpdateTutorialHighlight(wndControl, tOffer, nCategoryId)
	if self.tTutorial == nil or self.tTutorial.nCurrentPos <= 1 or self.tTutorial.nCurrentPos > #self.tTutorial.tItems then
		if self.tTutorial ~= nil and self.tTutorial.tItems[self.ktTutorialBtn.OpenInventory].wndTargetBtn ~= nil then
			-- Remove the last tutorial highlight because it was completed
			self.tTutorial.tItems[self.ktTutorialBtn.OpenInventory].wndTargetBtn:FindChild(self.tTutorial.tItems[self.ktTutorialBtn.OpenInventory].strCalloutName):Show(false)
		end
		return
	end
	
	-- We can have a nil wndControl and not be default if given other values
	local bNotDefault = wndControl == nil and tOffer ~= nil and nCategoryId ~= nil
	
	-- If we have an offer and category and the offer and category is not for our tutorial item then set tutorial to default btn
	if (tOffer ~= nil and tOffer.nId ~= self.tTutorial.nOfferGroupId) 
		or (nCategoryId ~= nil and ((nCategoryId ~= self.tTutorial.nCategoryId and self.tTutorial.nSubCategoryId == 0) 
			or (self.tTutorial.nSubCategoryId ~= 0 and (nCategoryId ~= self.tTutorial.nCategoryId and nCategoryId ~= self.tTutorial.nSubCategoryId)))) then
		self:UpdateTutorialHighlight(nil, nil, nil) -- Set default btn
		return
	end
	
	local wndHighlightedTutorialCallout = nil
	local nStartingPos = self.tTutorial.nCurrentPos
	for idx = 1, #self.tTutorial.tItems do
		-- Get tutorial and previous btn
		local tTargetWindows = nil
		local bIsItemBtn = false
		if self.tTutorial.tItems[idx].strCalloutName == self.ktTutorialCalloutNames[self.ktTutorialBtn.Category] then
			tTargetWindows = self:HelperFindTargets(idx, self.ktTutorialBtn.Category)
		elseif self.tTutorial.tItems[idx].strCalloutName == self.ktTutorialCalloutNames[self.ktTutorialBtn.SubCategory] then
			tTargetWindows = self:HelperFindTargets(idx, self.ktTutorialBtn.SubCategory)
		elseif self.tTutorial.tItems[idx].strCalloutName == self.ktTutorialCalloutNames[self.ktTutorialBtn.Items] then
			tTargetWindows = self:HelperFindTargets(idx, self.ktTutorialBtn.Items)
			bIsItemBtn = true
		else
			tTargetWindows = self:HelperFindTargets(idx, self.ktTutorialBtn.Basic)
		end
		local wndPreviousBtn = tTargetWindows.wndPreviousBtn
		local wndTutorialBtn = tTargetWindows.wndTutorialBtn
		
		-- Show/Hide tutorial highlight
		local bPrevTutorialClicked = wndControl == wndPreviousBtn and wndControl ~= nil
		local bAcceptableSources = (not bNotDefault and wndControl == nil) or wndControl ~= self.tTutorial.tItems[idx].wndTargetBtn
		local bTutorialBtnVisible = false
		if bIsItemBtn and wndTutorialBtn ~= nil then
			bTutorialBtnVisible = self:HelperIsItemVisible(wndTutorialBtn:GetParent())
			-- Even if we have a subcategory, if the item is visible then category is considered wndPrevious so check if it was clicked
			if self.tTutorial.nSubCategoryId ~= 0 and bTutorialBtnVisible and not bPrevTutorialClicked 
				and wndControl == self.tTutorial.tItems[self.ktTutorialBtn.Category].wndTargetBtn and wndControl ~= nil then
				bPrevTutorialClicked = true
			end
		else
			bTutorialBtnVisible = wndTutorialBtn ~= nil and wndTutorialBtn:IsVisible()
		end
		local bDefaultPosition = idx == self.ktTutorialBtn.Category or idx == self.ktTutorialBtn.SubCategory
		if wndHighlightedTutorialCallout == nil and (bPrevTutorialClicked or (bAcceptableSources and (bDefaultPosition or bNotDefault))) and bTutorialBtnVisible then
			local wndTutorialCallout = wndTutorialBtn:FindChild(self.tTutorial.tItems[idx].strCalloutName)
			if wndTutorialCallout ~= nil and wndTutorialCallout:IsValid() then
				wndTutorialCallout:Show(true)
				wndHighlightedTutorialCallout = wndTutorialBtn
				self.tTutorial.nCurrentPos = idx
			end
		elseif self.tTutorial.tItems[idx].wndTargetBtn ~= nil then
			local wndTutorialCallout = self.tTutorial.tItems[idx].wndTargetBtn:FindChild(self.tTutorial.tItems[idx].strCalloutName)
			if wndTutorialCallout ~= nil and wndTutorialCallout:IsValid() then -- The item window may not exist
				wndTutorialCallout:Show(false)
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Helper Functions
---------------------------------------------------------------------------------------------------

function Storefront:HelperFindTargets(nIndex, eTutorialBtn)
	local wndPreviousBtn = nil
	if eTutorialBtn == self.ktTutorialBtn.Category then
		local wndNavPrimary = self.tNavCategoryWndRefs[self.tTutorial.nCategoryId]
		if wndNavPrimary ~= nil then
			self.tTutorial.tItems[nIndex].wndTargetBtn = wndNavPrimary:FindChild("NavBtn")
		else
			self.tTutorial.tItems[nIndex].wndTargetBtn = nil
		end
	elseif eTutorialBtn == self.ktTutorialBtn.SubCategory and self.tTutorial.nSubCategoryId ~= 0 then
		local wndSecondaryNav = self.tNavSubCategoryWndRefs[self.tTutorial.nSubCategoryId]
		if wndSecondaryNav ~= nil then
			self.tTutorial.tItems[nIndex].wndTargetBtn = wndSecondaryNav:FindChild("SecondaryNavBtn")
		end
		
		wndPreviousBtn = self.tTutorial.tItems[self.ktTutorialBtn.Category].wndTargetBtn
	elseif eTutorialBtn == self.ktTutorialBtn.Items then
		local tChildren = self.tWndRefs.wndCenterItemsContainer:GetChildren()
		for nIdx, wndChild in pairs(tChildren) do
			local wndPreviewBtn = wndChild:FindChild("PreviewBtn")
			local tData = wndPreviewBtn:GetData()
			if tData.tOffer.nId == self.tTutorial.nOfferGroupId then
				self.tTutorial.tItems[nIndex].wndTargetBtn = wndPreviewBtn
				break
			end
		end
		
		if self.tTutorial.nSubCategoryId == 0 then
			wndPreviousBtn = self.tTutorial.tItems[self.ktTutorialBtn.Category].wndTargetBtn
		else
			wndPreviousBtn = self.tTutorial.tItems[self.ktTutorialBtn.SubCategory].wndTargetBtn
		end
	elseif self.tTutorial.tItems[nIndex + 1] ~= nil then -- Basic section
		wndPreviousBtn = self.tTutorial.tItems[nIndex + 1].wndTargetBtn
	end
	
	return { wndTutorialBtn = self.tTutorial.tItems[nIndex].wndTargetBtn, wndPreviousBtn = wndPreviousBtn }
end

function Storefront:HelperIsItemVisible(wndItem)
	if wndItem == nil or not wndItem:IsValid() or not wndItem:IsVisible() then
		return false
	end
	
	local nContainerHeight = self.tWndRefs.wndCenterItemsContainer:GetHeight() - self.knItemVisibleTolerance
	local nContainerVertScrollPos = self.tWndRefs.wndCenterItemsContainer:GetVScrollPos()
	local nLeft, nTop, nRight, nBottom = wndItem:GetAnchorOffsets()
	nTop = nTop - nContainerVertScrollPos
	nBottom = nBottom - nContainerVertScrollPos
	
	return nTop > self.knItemVisibleTolerance and nTop < nContainerHeight or nBottom > self.knItemVisibleTolerance and nBottom < nContainerHeight
end

local StorefrontInst = Storefront:new()
StorefrontInst:Init()

