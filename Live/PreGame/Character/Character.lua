require "Apollo"
require "Window"
require "CharacterScreenLib"
require "PreGameLib"
require "Sound"
require "ApolloTimer"
require "AlienFxLib"


---------------------------------------------------------------------------------------------------
-- Character module definition

local Character = {}

LuaEnumState =
{
	Select 		= 1,
	Create 		= 2,
	Delete 		= 3,
	Buy 		= 4,
}

local knMaxCharacterNamePart = PreGameLib.GetTextTypeMaxLength(PreGameLib.CodeEnumUserText.CharacterNamePart)
local knMaxCharacterName = PreGameLib.GetTextTypeMaxLength(PreGameLib.CodeEnumUserText.CharacterName)
local knMinCharacterName = PreGameLib.GetTextTypeMinLength(PreGameLib.CodeEnumUserText.CharacterName)
local knDesignerPaddingBottom = 10
local k_idCassian = 100	-- Humans (Dominion - fabricated value)

local c_arRaceStrings =  --inserting values so we can use direct race numbering. Each holds a table with name, then description
{
	[PreGameLib.CodeEnumRace.Human] 		= {strName = "RaceHuman", 		strFaction="CRB_Exiles",		strDescription = "CRB_CC_Race_ExileHumans", 		strMaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_HuM_ExNormal", 	strFemaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_HuF_ExNormal", strFactionIcon="charactercreate:sprCharC_Ico_Exile_Lrg",},
	[PreGameLib.CodeEnumRace.Mordesh] 		= {strName = "CRB_Mordesh", 			strFaction="CRB_Exiles", 		strDescription = "CRB_CC_Race_Mordesh", 			strMaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_MoMNormal", 		strFemaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_MoFNormal", strFactionIcon="charactercreate:sprCharC_Ico_Exile_Lrg",},
	[PreGameLib.CodeEnumRace.Granok] 		= {strName = "RaceGranok", 	strFaction="CRB_Exiles",		strDescription = "CRB_CC_Race_Granok", 				strMaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_GrMNormal", 		strFemaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_GrFNormal", strFactionIcon="charactercreate:sprCharC_Ico_Exile_Lrg",},
	[PreGameLib.CodeEnumRace.Aurin] 		= {strName = "RaceAurin",	strFaction="CRB_Exiles",		strDescription = "CRB_CC_Race_Aurin", 				strMaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_AuMNormal", 		strFemaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_AuFNormal", strFactionIcon="charactercreate:sprCharC_Ico_Exile_Lrg",},
	[PreGameLib.CodeEnumRace.Draken] 		= {strName = "RaceDraken",				strFaction="CRB_Dominion",	strDescription = "CRB_CC_Race_Draken", 				strMaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_DrMNormal", 		strFemaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_DrFNormal", strFactionIcon="charactercreate:sprCharC_Ico_Dominion_Lrg",},
	[PreGameLib.CodeEnumRace.Mechari] 		= {strName = "RaceMechari",				strFaction="CRB_Dominion",	strDescription = "CRB_CC_Race_Mechari",				strMaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_MeMNormal", 		strFemaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_MeFNormal", strFactionIcon="charactercreate:sprCharC_Ico_Dominion_Lrg",},
	[PreGameLib.CodeEnumRace.Chua] 			= {strName = "RaceChua",					strFaction="CRB_Dominion",	strDescription = "CRB_CC_Race_Chua", 				strMaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_ChuaNormal",		strFemaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_ChuaNormal", strFactionIcon="charactercreate:sprCharC_Ico_Dominion_Lrg",},
	[k_idCassian] 										= {strName = "CRB_Cassian",				strFaction="CRB_Dominion",	strDescription = "CRB_CC_Race_DominionHumans",	strMaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_HuM_DomNormal", strFemaleIcon="CRB_CharacterCreateSprites:btnCharC_RG_HuF_DomNormal", strFactionIcon="charactercreate:sprCharC_Ico_Dominion_Lrg",},
}

local c_arClassStrings =  --inserting values so we can use direct class numbering. Each holds a table with name, then description
{
	[PreGameLib.CodeEnumClass.Warrior] 		= {strName = "ClassWarrior", 			strDescription = "CharacterCreation_Blurb_Warrior", strTextColor = "ChannelDebug"},
	[PreGameLib.CodeEnumClass.Engineer] 	= {strName = "ClassEngineer", 		strDescription = "CharacterCreation_Blurb_Engineer", strTextColor = "ChannelParty"},
	[PreGameLib.CodeEnumClass.Esper] 		= {strName = "ClassESPER", 			strDescription = "CharacterCreation_Blurb_Esper", strTextColor = "ChannelSay"},
	[PreGameLib.CodeEnumClass.Medic] 		= {strName = "ClassMedic", 			strDescription = "CharacterCreation_Blurb_Medic", strTextColor = "ChannelGuild"},
	[PreGameLib.CodeEnumClass.Stalker] 		= {strName = "ClassStalker", 			strDescription = "CharacterCreation_Blurb_Stalker", strTextColor = "ChannelAccountWisper"},
	[PreGameLib.CodeEnumClass.Spellslinger] = {strName = "ClassSpellslinger", 	strDescription = "CharacterCreation_Blurb_Spellslinger", strTextColor = "ChannelTrade"},
}

local c_arClassVideos =
{
	[PreGameLib.CodeEnumClass.Warrior] 		= {strName = "Art\\Cinematics\\Zones\\CHSelect\\CHSelect_class_warrior.bk2"},
	[PreGameLib.CodeEnumClass.Engineer] 	= {strName = "Art\\Cinematics\\Zones\\CHSelect\\CHSelect_class_eng.bk2"},
	[PreGameLib.CodeEnumClass.Esper] 		= {strName = "Art\\Cinematics\\Zones\\CHSelect\\CHSelect_class_esper.bk2"},
	[PreGameLib.CodeEnumClass.Medic] 		= {strName = "Art\\Cinematics\\Zones\\CHSelect\\CHSelect_class_medic.bk2"},
	[PreGameLib.CodeEnumClass.Stalker] 		= {strName = "Art\\Cinematics\\Zones\\CHSelect\\CHSelect_class_stalker.bk2"},
	[PreGameLib.CodeEnumClass.Spellslinger] = {strName = "Art\\Cinematics\\Zones\\CHSelect\\CHSelect_class_slinger.bk2"},
}

local c_arPathVideos =
{
	[PreGameLib.CodeEnumPlayerPathType.Soldier		] 		= {strName = "Art\\Cinematics\\Zones\\CHSelect\\CHSelect_Path_SOLIDER.bk2"},
	[PreGameLib.CodeEnumPlayerPathType.Settler		]		= {strName = "Art\\Cinematics\\Zones\\CHSelect\\CHSelect_Path_SETTLER.bk2"},
	[PreGameLib.CodeEnumPlayerPathType.Scientist	] 		= {strName = "Art\\Cinematics\\Zones\\CHSelect\\CHSelect_Path_SCIENTIST.bk2"},
	[PreGameLib.CodeEnumPlayerPathType.Explorer	] 		= {strName = "Art\\Cinematics\\Zones\\CHSelect\\CHSelect_Path_EXPLORER.bk2"},
}

local c_arRaceButtons =  --inserting values so we can use direct race numbering. Each holds a table with name, then description
{
	[PreGameLib.CodeEnumRace.Human] 		= {male = "CRB_CharacterCreateSprites:btnCharC_RG_HuM_Ex", 	female = "CRB_CharacterCreateSprites:btnCharC_RG_HuF_Ex"},
	[PreGameLib.CodeEnumRace.Mordesh] 		= {male = "CRB_CharacterCreateSprites:btnCharC_RG_MoM", 		female = "CRB_CharacterCreateSprites:btnCharC_RG_MoF"},
	[PreGameLib.CodeEnumRace.Granok] 		= {male = "CRB_CharacterCreateSprites:btnCharC_RG_GrM", 		female = "CRB_CharacterCreateSprites:btnCharC_RG_GrF"},
	[PreGameLib.CodeEnumRace.Aurin] 			= {male = "CRB_CharacterCreateSprites:btnCharC_RG_AuM", 		female = "CRB_CharacterCreateSprites:btnCharC_RG_AuF"},
	[PreGameLib.CodeEnumRace.Draken] 		= {male = "CRB_CharacterCreateSprites:btnCharC_RG_DrM", 		female = "CRB_CharacterCreateSprites:btnCharC_RG_DrF"},
	[PreGameLib.CodeEnumRace.Mechari] 		= {male = "CRB_CharacterCreateSprites:btnCharC_RG_MeM", 		female = "CRB_CharacterCreateSprites:btnCharC_RG_MeF"},
	[PreGameLib.CodeEnumRace.Chua] 			= {male = "CRB_CharacterCreateSprites:btnCharC_RG_Chua"}, -- Chua
	[k_idCassian]	 									= {male = "CRB_CharacterCreateSprites:btnCharC_RG_HuM_Dom", female = "CRB_CharacterCreateSprites:btnCharC_RG_HuF_Dom"},
}

local c_arFactionStrings =
{
	[PreGameLib.CodeEnumFaction.Exile] 		= "CRB_CC_Faction_Exiles",
	[PreGameLib.CodeEnumFaction.Dominion] 	= "CRB_CC_Faction_Dominion",
}

local c_arAllowedRace =
{
	[PreGameLib.CodeEnumRace.Human] 	= true,
	[PreGameLib.CodeEnumRace.Mordesh]	= true,
	[PreGameLib.CodeEnumRace.Granok]	= true,
	[PreGameLib.CodeEnumRace.Aurin] 	= true,
	[PreGameLib.CodeEnumRace.Draken] 	= true,
	[PreGameLib.CodeEnumRace.Mechari] 	= true,
	[PreGameLib.CodeEnumRace.Chua] 		= true,
}


local c_arAllowedClass =
{
	[PreGameLib.CodeEnumClass.Warrior] 		= true,
	[PreGameLib.CodeEnumClass.Engineer] 	= true,
	[PreGameLib.CodeEnumClass.Esper] 		= true,
	[PreGameLib.CodeEnumClass.Medic] 		= true,
	[PreGameLib.CodeEnumClass.Stalker] 		= true,
	[PreGameLib.CodeEnumClass.Spellslinger] = true,
}


local c_arPathStrings =  --paths are sequential but zero-indexed
{
	[PreGameLib.CodeEnumPlayerPathType.Soldier] 	= {strName = "CRB_Soldier", 	strDescription = "CharacterCreation_Blurb_Soldier",		strBackgroundImage = "charactercreate:sprCharC_PathContent_Soldier"},
	[PreGameLib.CodeEnumPlayerPathType.Settler] 	= {strName = "CRB_Settler", 	strDescription = "CharacterCreation_Blurb_Settler",		strBackgroundImage = "charactercreate:sprCharC_PathContent_Settler"},
	[PreGameLib.CodeEnumPlayerPathType.Scientist] 	= {strName = "CRB_Scientist", 	strDescription = "CharacterCreation_Blurb_Scientist",	strBackgroundImage = "charactercreate:sprCharC_PathContent_Scientist"},
	[PreGameLib.CodeEnumPlayerPathType.Explorer] 	= {strName = "CRB_Explorer", 	strDescription = "CharacterCreation_Blurb_Explorer",	strBackgroundImage = "charactercreate:sprCharC_PathContent_Explorer"},
}

local keArchTypes = 
{
	MeleeDamage = 1,
	RangeDamage = 2,
	Healer = 3,
	Tank = 4,
}

local ktArchTypes = 
{
	[PreGameLib.CodeEnumClass.Warrior] 		= {eFirstRole = keArchTypes.MeleeDamage, eSecondRole = keArchTypes.Tank},
	[PreGameLib.CodeEnumClass.Engineer] 	= {eFirstRole = keArchTypes.RangeDamage, eSecondRole = keArchTypes.Tank},
	[PreGameLib.CodeEnumClass.Esper] 		= {eFirstRole = keArchTypes.RangeDamage, eSecondRole = keArchTypes.Healer},
	[PreGameLib.CodeEnumClass.Medic] 		= {eFirstRole = keArchTypes.RangeDamage, eSecondRole = keArchTypes.Healer},
	[PreGameLib.CodeEnumClass.Stalker] 		= {eFirstRole = keArchTypes.MeleeDamage, eSecondRole = keArchTypes.Tank},
	[PreGameLib.CodeEnumClass.Spellslinger] = {eFirstRole = keArchTypes.RangeDamage, eSecondRole = keArchTypes.Healer},
}

local c_SceneTime = 6 * 60 * 60 -- seconds from midnight

local c_defaultRotation = 190 -- sets the initial customize angle
local c_defaultRotationModel = 190
local nOffset = 25 -- Offset of the path description window framing

local kiRotateIntervalModel = .05 -- How much does the model rotate when the player holds the arrow. Pulse is set in XML

local knAlienFxAllLightsLocation = 134217727

local kcrNormalBack = "CRB_Basekit:kitBase_HoloBlue_TinyNoGlow"
local kcrSelectedBack = "CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow"
local kcrNormalButton = "CRB_DEMO_WrapperSprites:btnDemo_CharInvisible"
local kcrSelectedButton = "PlayerPathContent_TEMP:btn_PathListBlueFlyby"
local kcrModelColor = ApolloColor.new("ModelHighlightBlue")

local kstrFinalizeNotSelected = "Crafting_CircuitSprites:sprCircuit_GreenPlus_Anim"
local kstrFinalizeSelected = "Crafting_CoordSprites:sprCoord_Checkmark"

local kstrRealmFullClosed = Apollo.GetString("Pregame_RealmFullClosed")
local kstrRealmFullOpen = Apollo.GetString("Pregame_RealmFullOpen")

local kvecPositionHide = Vector3.New(0, 50, 0)
local kvecPositionShowCenter = Vector3.Zero()
local kvecPositionShowRight = Vector3.New(2, 0, 0)
local kvecDefaultRotation = Vector3.Zero()
local knDefaultScale = 1

local c_classSelectAnimation =
{
	[PreGameLib.CodeEnumClass.Spellslinger] = {eStand = PreGameLib.CodeEnumModelSequence.PistolsStand,		eReady = PreGameLib.CodeEnumModelSequence.PistolsReady},
	[PreGameLib.CodeEnumClass.Stalker] 		= {eStand = PreGameLib.CodeEnumModelSequence.ClawsStand,		eReady = PreGameLib.CodeEnumModelSequence.ClawsReady},
	[PreGameLib.CodeEnumClass.Engineer] 	= {eStand = PreGameLib.CodeEnumModelSequence.TwoHGunStand,		eReady = PreGameLib.CodeEnumModelSequence.HeavyGunReady},
	[PreGameLib.CodeEnumClass.Warrior] 		= {eStand = PreGameLib.CodeEnumModelSequence.TwoHStand,			eReady = PreGameLib.CodeEnumModelSequence.TwoHReady},
	[PreGameLib.CodeEnumClass.Esper] 		= {eStand = PreGameLib.CodeEnumModelSequence.DefaultStand,		eReady = PreGameLib.CodeEnumModelSequence.EsperReady},
	[PreGameLib.CodeEnumClass.Medic] 		= {eStand = PreGameLib.CodeEnumModelSequence.ShockPaddlesStand,	eReady = PreGameLib.CodeEnumModelSequence.ShockPaddlesReady},
}

local c_factionPlayerAnimation =
{
	[PreGameLib.CodeEnumFaction.Exile] = PreGameLib.CodeEnumModelSequence.DefaultExileStartScreenLoop01,
	[PreGameLib.CodeEnumFaction.Dominion] = PreGameLib.CodeEnumModelSequence.DefaultDominionStartScreenLoop01,
}

local c_cameraZoomAnimation = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Human] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Human][PreGameLib.CodeEnumGender.Male] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Human][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Exile] = 7725
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Human][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Dominion] = 7738
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Human][PreGameLib.CodeEnumGender.Female] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Human][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Exile] = 7726
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Human][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Dominion] = 7739

c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Aurin] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Aurin][PreGameLib.CodeEnumGender.Male] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Aurin][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Exile] = 7727
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Aurin][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Dominion] = 7727
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Aurin][PreGameLib.CodeEnumGender.Female] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Aurin][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Exile] = 7728
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Aurin][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Dominion] = 7728

c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Chua] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Chua][PreGameLib.CodeEnumGender.Male] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Chua][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Exile] = 7729
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Chua][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Dominion] = 7729
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Chua][PreGameLib.CodeEnumGender.Female] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Chua][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Exile] = 7729
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Chua][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Dominion] = 7729

c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Draken] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Draken][PreGameLib.CodeEnumGender.Male] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Draken][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Exile] = 7730
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Draken][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Dominion] = 7730
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Draken][PreGameLib.CodeEnumGender.Female] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Draken][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Exile] = 7731
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Draken][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Dominion] = 7731

c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mordesh] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mordesh][PreGameLib.CodeEnumGender.Male] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mordesh][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Exile] = 7732
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mordesh][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Dominion] = 7732
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mordesh][PreGameLib.CodeEnumGender.Female] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mordesh][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Exile] = 7733
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mordesh][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Dominion] = 7733

c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mechari] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mechari][PreGameLib.CodeEnumGender.Male] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mechari][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Exile] = 7734
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mechari][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Dominion] = 7734
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mechari][PreGameLib.CodeEnumGender.Female] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mechari][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Exile] = 7735
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Mechari][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Dominion] = 7735

c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Granok] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Granok][PreGameLib.CodeEnumGender.Male] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Granok][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Exile] = 7736
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Granok][PreGameLib.CodeEnumGender.Male][PreGameLib.CodeEnumFaction.Dominion] = 7736
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Granok][PreGameLib.CodeEnumGender.Female] = {}
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Granok][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Exile] = 7737
c_cameraZoomAnimation[PreGameLib.CodeEnumRace.Granok][PreGameLib.CodeEnumGender.Female][PreGameLib.CodeEnumFaction.Dominion] = 7737

local keTutorialTab = {
	Experience = 1,
	Race = 2,
	Class = 3,
	Path = 4,
	Customize = 5,
	Finalize = 6,

}

local keArmorPreview = {
	Early = 0,
	Mid = 1,
	Late = 2,
}

local keCustomizationPreset = {
	First = 1,
	Second = 2,
}

local keModelRaceModelIds = 
{
	GranokM 	= 20001,
	GranokF		= 20002,
	HumanM 		= 20003,
	HumanF		= 20004,
	MordeshM	= 20005,
	MordeshF	= 20006,
	AurinM 		= 20007,
	AurinF 		= 20008,
	DrakenM 	= 20019,
	DrakenF		= 20020,
	ChuaM 		= 20021,
	MechariM 	= 20022,
	MechariF 	= 20023,
	CassianM 	= 20024,
	CassianF 	= 20025,
}

local ktCustomizeFaceOptions = 
{
	[1 ] = true,
	[21] = true,
	[22] = true,
}

local ktCustomizeOptionsZoomOut = 
{
	[2 ] = true,
	[25] = true,
}

--Need to take a polish pass on the icons displayed.
local kstrDefaultTabIcon = "charactercreate:sprCharC_HeaderStepIncomplete"
local kstrSelectedTabIcon = "charactercreate:sprCharC_HeaderStepComplete"

local ktFactionRaceDisplayInfo =
{
	[PreGameLib.CodeEnumFaction.Exile] =
	{
		[PreGameLib.CodeEnumGender.Male] =
		{
			[PreGameLib.CodeEnumRace.Granok]	= { nUnitId = keModelRaceModelIds.GranokM,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.Passenger01,		strForm = "RaceInformationLeft",	strDisplay = "RaceGranok", },
			[PreGameLib.CodeEnumRace.Human]		= { nUnitId = keModelRaceModelIds.HumanM,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.Passenger02,	strForm = "RaceInformationLeft",	strDisplay = "RaceHuman", },
			[PreGameLib.CodeEnumRace.Mordesh]	= { nUnitId = keModelRaceModelIds.MordeshM,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.Passenger03,	strForm = "RaceInformationLeft",	strDisplay = "CRB_Mordesh", },
			[PreGameLib.CodeEnumRace.Aurin]		= { nUnitId = keModelRaceModelIds.AurinM,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.Passenger04,	strForm = "RaceInformationLeft",	strDisplay = "RaceAurin", },
		},
		[PreGameLib.CodeEnumGender.Female] =
		{
			[PreGameLib.CodeEnumRace.Granok]	= { nUnitId = keModelRaceModelIds.GranokF,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.Passenger09,		strForm = "RaceInformationLeft",	strDisplay = "RaceGranok", },
			[PreGameLib.CodeEnumRace.Human]		= { nUnitId = keModelRaceModelIds.HumanF,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.Passenger10,	strForm = "RaceInformationLeft",	strDisplay = "RaceHuman", },
			[PreGameLib.CodeEnumRace.Mordesh]	= { nUnitId = keModelRaceModelIds.MordeshF,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.FXMisc02,	strForm = "RaceInformationLeft",	strDisplay = "CRB_Mordesh", },
			[PreGameLib.CodeEnumRace.Aurin]		= { nUnitId = keModelRaceModelIds.AurinF,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.FXMisc01,	strForm = "RaceInformationLeft",	strDisplay = "RaceAurin", },
		},
	},
	[PreGameLib.CodeEnumFaction.Dominion] =
	{
		[PreGameLib.CodeEnumGender.Male] =
		{
			[PreGameLib.CodeEnumRace.Draken]	= { nUnitId = keModelRaceModelIds.DrakenM,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.Passenger05,	strForm = "RaceInformationRight",	strDisplay = "RaceDraken", },
			[PreGameLib.CodeEnumRace.Chua]		= { nUnitId = keModelRaceModelIds.ChuaM,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.Passenger06,	strForm = "RaceInformationRight",	strDisplay = "RaceChua", },
			[PreGameLib.CodeEnumRace.Mechari]	= { nUnitId = keModelRaceModelIds.MechariM,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.Passenger07,	strForm = "RaceInformationRight",	strDisplay = "RaceMechari", },
			[k_idCassian]		= { nUnitId = keModelRaceModelIds.CassianM,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.Passenger08,	strForm = "RaceInformationRight",	strDisplay = "CRB_Cassian", },
		},
		[PreGameLib.CodeEnumGender.Female] =
		{
			[PreGameLib.CodeEnumRace.Draken]	= { nUnitId = keModelRaceModelIds.DrakenF,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.FXMisc05,	strForm = "RaceInformationRight",	strDisplay = "RaceDraken", },
			[PreGameLib.CodeEnumRace.Mechari]	= { nUnitId = keModelRaceModelIds.MechariF,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.FXMisc04,	strForm = "RaceInformationRight",	strDisplay = "RaceMechari", },
			[k_idCassian]		= { nUnitId = keModelRaceModelIds.CassianF,	eSceneAttachPoint = PreGameLib.CodeEnumModelAttachment.FXMisc03,	strForm = "RaceInformationRight",	strDisplay = "CRB_Cassian", },
		},
	},
}

local ktIcons = {
	[keTutorialTab.Experience] = {
		[PreGameLib.CodeEnumCharacterCreationStart.PreTutorial] = "charactercreate:sprCharC_Finalize_SkillLevel1",
		[PreGameLib.CodeEnumCharacterCreationStart.Nexus] = "charactercreate:sprCharC_Finalize_SkillLevel3",
		[PreGameLib.CodeEnumCharacterCreationStart.Level50] = "charactercreate:sprCharC_Finalize_SkillLevel3",
	},

	[keTutorialTab.Race] = {

		[PreGameLib.CodeEnumRace.Human] 	= {
																			[PreGameLib.CodeEnumGender.Male] = "charactercreate:sprCharC_Finalize_RaceExileM",
																			[PreGameLib.CodeEnumGender.Female] = "charactercreate:sprCharC_Finalize_RaceExileF",
																		},
																	 
		[PreGameLib.CodeEnumRace.Mordesh] = {
																			[PreGameLib.CodeEnumGender.Male] = "charactercreate:sprCharC_Finalize_RaceMordeshM",
																			[PreGameLib.CodeEnumGender.Female] = "charactercreate:sprCharC_Finalize_RaceMordeshF",
																		 },
																		
		[PreGameLib.CodeEnumRace.Granok] 	= {
																			[PreGameLib.CodeEnumGender.Male] = "charactercreate:sprCharC_Finalize_RaceGranokM",
																			[PreGameLib.CodeEnumGender.Female] = "charactercreate:sprCharC_Finalize_RaceGranokF",
																		 },

		[PreGameLib.CodeEnumRace.Aurin] 		= {
																			[PreGameLib.CodeEnumGender.Male] = "charactercreate:sprCharC_Finalize_RaceAurinM",
																			[PreGameLib.CodeEnumGender.Female] = "charactercreate:sprCharC_Finalize_RaceAurinF",
																		 },
																		 
		[PreGameLib.CodeEnumRace.Draken] 	= {
																			[PreGameLib.CodeEnumGender.Male] = "charactercreate:sprCharC_Finalize_RaceDrakenM",
																			[PreGameLib.CodeEnumGender.Female] = "charactercreate:sprCharC_Finalize_RaceDrakenF",
																		 },
																		 
		[PreGameLib.CodeEnumRace.Mechari] 	= {
																			[PreGameLib.CodeEnumGender.Male] = "charactercreate:sprCharC_Finalize_RaceMechariM",
																			[PreGameLib.CodeEnumGender.Female] = "charactercreate:sprCharC_Finalize_RaceMechariF",
																		 },
																		 
		[PreGameLib.CodeEnumRace.Chua] 		= {
																			[PreGameLib.CodeEnumGender.Male] = "charactercreate:sprCharC_Finalize_RaceChua",
																			[PreGameLib.CodeEnumGender.Female] = "charactercreate:sprCharC_Finalize_RaceChua",
																		 },
																		 
		[k_idCassian] 										= {
																			[PreGameLib.CodeEnumGender.Male] = "charactercreate:sprCharC_Finalize_RaceDomM",
																			[PreGameLib.CodeEnumGender.Female] = "charactercreate:sprCharC_Finalize_RaceDomF",
																		 },
	},

	[keTutorialTab.Class] = {
		[PreGameLib.CodeEnumClass.Spellslinger] = "BK3:UI_Icon_CharacterCreate_Class_Spellslinger",
		[PreGameLib.CodeEnumClass.Stalker] = "BK3:UI_Icon_CharacterCreate_Class_Stalker",
		[PreGameLib.CodeEnumClass.Engineer] = "BK3:UI_Icon_CharacterCreate_Class_Engineer",
		[PreGameLib.CodeEnumClass.Warrior] = "BK3:UI_Icon_CharacterCreate_Class_Warrior",
		[PreGameLib.CodeEnumClass.Esper] = "BK3:UI_Icon_CharacterCreate_Class_Esper",
		[PreGameLib.CodeEnumClass.Medic] = "BK3:UI_Icon_CharacterCreate_Class_Medic",
	},

	[keTutorialTab.Path] = {
		[PreGameLib.CodeEnumPlayerPathType.Explorer] = "BK3:UI_Icon_CharacterCreate_Path_Explorer",
		[PreGameLib.CodeEnumPlayerPathType.Soldier] = "BK3:UI_Icon_CharacterCreate_Path_Soldier",
		[PreGameLib.CodeEnumPlayerPathType.Scientist] = "BK3:UI_Icon_CharacterCreate_Path_Scientist",
		[PreGameLib.CodeEnumPlayerPathType.Settler] = "BK3:UI_Icon_CharacterCreate_Path_Settler",
	},
}

local knInstantAnimationSpeed = 0.0
local knZoomAnimationSpeed = 6.0

local ktRaceToSololightState =
{
	[PreGameLib.CodeEnumRace.Chua] 		= PreGameLib.CodeEnumModelSequence.APState0Idle,
	[PreGameLib.CodeEnumRace.Aurin] 	= PreGameLib.CodeEnumModelSequence.APState0Idle,
	[PreGameLib.CodeEnumRace.Human] 	= PreGameLib.CodeEnumModelSequence.APState1Idle,
	[PreGameLib.CodeEnumRace.Draken] 	= PreGameLib.CodeEnumModelSequence.APState1Idle,
	[PreGameLib.CodeEnumRace.Mordesh]	= PreGameLib.CodeEnumModelSequence.APState2Idle,
	[PreGameLib.CodeEnumRace.Granok]	= PreGameLib.CodeEnumModelSequence.APState2Idle,
	[PreGameLib.CodeEnumRace.Mechari] 	= PreGameLib.CodeEnumModelSequence.APState2Idle,
}

local kstrHoloTextColor = "UI_TextHoloBodyHighlight"
local kstrErrorTextColor = "Reddish"

function Character:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	return o
end

function Character:Init()
	Apollo.RegisterAddon(self)
end

function Character:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Character.xml")

	self.bHaveCharacters = false
	self.ePendingRace = nil
	self.ePendingClass = nil

	math.randomseed(PreGameLib.GetTimeBasedSeed())

	Apollo.RegisterEventHandler("AnimationFinished", "OnAnimationFinished", self)
	Apollo.RegisterEventHandler("ActorClicked", "OnActorClicked", self)
	Apollo.RegisterEventHandler("ActorMouseEnter", "OnActorMouseEnter", self)
	Apollo.RegisterEventHandler("ActorMouseExit", "OnActorMouseExit", self)

	Apollo.RegisterEventHandler("QueueStatus", "OnQueueStatus", self)
	Apollo.RegisterEventHandler("QueueFinished", "OnQueueFinished", self)
	Apollo.RegisterEventHandler("CharacterList", "OnCharacterList", self)
	Apollo.RegisterEventHandler("OpenCharacterCreateBtn", "OnOpenCharacterCreate", self)
	Apollo.RegisterEventHandler("OpenCharacterCreate50Btn", "OnOpenCharacterCreate50", self)
	Apollo.RegisterEventHandler("Select_SetModel", "OnConfigureModel", self)
	Apollo.RegisterEventHandler("CharacterCreateFailed", "OnCreateCharacterFailed", self)
	Apollo.RegisterEventHandler("RealmBroadcast", "OnRealmBroadcast", self)
	Apollo.RegisterEventHandler("CharacterBack", "OnBackBtn", self )
	Apollo.RegisterEventHandler("AccountEntitlementUpdate", "OnEntitlementUpdate", self)

	Apollo.RegisterTimerHandler("SubscriptionExpired", "OnSubscriptionExpired", self)
	Apollo.RegisterTimerHandler("CreateFailedTimer", "OnCreateFailedTimer", self)
	Apollo.RegisterTimerHandler("RealmBroadcastTimer", "OnRealmBroadcastTimer", self)
	
	Apollo.RegisterEventHandler("StoreCatalogReady", "OnStoreCatalogReady", self)


	Apollo.CreateTimer("RealmBroadcastTimer", 10.0, false)
	Apollo.StopTimer("RealmBroadcastTimer")

	--These refer to the global controls that live in this file
	g_controls = Apollo.LoadForm(self.xmlDoc, "PregameControls", "Navigation", self)
	g_controls:Show(false)

	g_controlCatcher = Apollo.LoadForm(self.xmlDoc, "PregameMouseCatcher", "TempBlocker", self)

	g_eState = LuaEnumState.Select
	g_arCharacters = {}
	g_arCharacterInWorld = nil

	-- This is the 3d scene used for both CC and CS
	g_scene = PreGameLib.uScene
	g_scene:SetMap( 1559 );
	g_scene:SetCameraFoVNearFar( 50, .1, 512 ) -- field of view, near plane and far plane settings for camera.  Can not set near plane to 0.  Setting a very small near plane causes graphic artifacts.
	g_scene:SetMapTimeOfDay(c_SceneTime) -- in seconds from midnight. New band now playing!

	g_arActors = {} -- our models

	g_arActors.mainScene = g_scene:AddActorByFile( 10000, "Art\\Prop\\Character_Creation\\MainScene\\CharacterCreation_MainScene.m3" )
	if g_arActors.mainScene then
		g_arActors.mainScene:SetPosition(knDefaultScale, kvecPositionShowCenter, kvecDefaultRotation)
		g_arActors.mainScene:AttachCamera(7) -- Cinematic_01
	end

	g_arActors.characterAttach = g_scene:AddActorByFile( 10001, "Art\\Prop\\Character_Creation\\MainScene\\CharacterCreation_MainScene_CharacterRotation.m3")
	g_arActors.pedestal = g_scene:AddActorByFile( 10002, "Art\\Prop\\Character_Creation\\Background\\PRP_CharacterCreation_BG_Pedistal_000.m3")

	g_arActors.warningLight1 = g_scene:AddActorByFile( 10013, "Art\\Prop\\Constructed\\Light\\Marauder\\PRP_AlarmLight_RMC_Red_000.m3" )
	if g_arActors.warningLight1 then
		g_arActors.warningLight1:AttachToActor( g_arActors.mainScene, 76 )
	end

	g_arActors.warningLight2 = g_scene:AddActorByFile( 10014, "Art\\Prop\\Constructed\\Light\\Marauder\\PRP_AlarmLight_RMC_Red_000.m3" )
	if g_arActors.warningLight2 then
		g_arActors.warningLight2:AttachToActor( g_arActors.mainScene, 77 )
	end

	g_arActors.dominionLight = g_scene:AddActorByFile( 10015, "Art\\Prop\\Character_Creation\\Light\\CC_LIT_FactionSelect_Dominion.m3" )
	if g_arActors.dominionLight then
		g_arActors.dominionLight:FollowActor( g_arActors.mainScene, PreGameLib.CodeEnumModelAttachment.PropMisc01)
		g_arActors.dominionLight:Animate(0, PreGameLib.CodeEnumModelSequence.APState0Idle, 0, true, false)
	end
	
	g_arActors.exileLight = g_scene:AddActorByFile( 10016, "Art\\Prop\\Character_Creation\\Light\\CC_LIT_FactionSelect_Exile.m3" )
	if g_arActors.exileLight then
		g_arActors.exileLight:FollowActor( g_arActors.mainScene, PreGameLib.CodeEnumModelAttachment.PropMisc01)
		g_arActors.exileLight:Animate(0, PreGameLib.CodeEnumModelSequence.APState0Idle, 0, true, false)
	end

	g_arActors.selectedRaceLight = g_scene:AddActorByFile( 10017, "Art\\Prop\\Character_Creation\\Light\\CC_LIT_CharacterSelected.m3" )
	if g_arActors.selectedRaceLight then
		g_arActors.selectedRaceLight:Animate(0, PreGameLib.CodeEnumModelSequence.APState0Idle, 0, true, false)
	end
	
	g_arActors.soloLight = g_scene:AddActorByFile( 10018, "Art\\Prop\\Character_Creation\\Light\\CC_LIT_CharacterSolo.m3" )
	if g_arActors.soloLight then
		g_arActors.soloLight:Animate(0, PreGameLib.CodeEnumModelSequence.APState0Idle, 0, true, false)
	end
	
	g_cameraAnimation = 150
	g_cameraSlider = 0

	self.wndCharacterListPrompt = Apollo.LoadForm(self.xmlDoc, "CharacterListPrompt", nil, self)
	self.wndCharacterListPrompt:Show(true)

	self.wndRealmName = Apollo.LoadForm(self.xmlDoc, "RealmNameForm", nil, self)
	self.wndInfoPane = Apollo.LoadForm(self.xmlDoc, "InfoPane_Overall", nil, self)

	self.wndCreateFrame = Apollo.LoadForm(self.xmlDoc, "CharacterCreationControls", nil, self)

	self.wndExperienceContent = self.wndCreateFrame:FindChild("ExperienceContent")
	self.wndRaceContent 			= self.wndCreateFrame:FindChild("RaceContent")
	self.wndClassContent 		= self.wndCreateFrame:FindChild("ClassContent")
	self.wndPathContent 			= self.wndCreateFrame:FindChild("PathContent")
	self.wndCustomizeContent = self.wndCreateFrame:FindChild("CustomizeContent")
	self.wndFinalizeContent 	= self.wndCreateFrame:FindChild("FinalizeContent")
	self.wndGlobal 					= self.wndCreateFrame:FindChild("Global")
	self.wndSubSection			= self.wndGlobal:FindChild("SubSection")
	
	--Attaching the Class Armor Preview contol to the pedestal.
	self.wndClassContent:FindChild("ClassArmorPreview"):SetUnit(g_arActors.pedestal, PreGameLib.CodeEnumModelAttachment.PropMisc01)

	self.wndAlerts = Apollo.LoadForm(self.xmlDoc, "Alerts", nil, self)
	self.wndCreationAlert			= self.wndAlerts:FindChild("CreationAlert")
	self.wndCustomizationAlert			= self.wndAlerts:FindChild("CustomizationAlert")
	self.wndCustomizationConfirmAlert = self.wndAlerts:FindChild("CustomizationConfirmAlert")
	self.wndSubscriptionExpiredAlert = self.wndAlerts:FindChild("SubscriptionExpiredAlert")
	self.wndCriticalStateAlert = self.wndAlerts:FindChild("CriticalStateAlert")
	self.wndPromotionTokenConfirmAlert = self.wndAlerts:FindChild("PromotionTokenConfirmAlert")
	self.wndFreeLevel50ConfirmAlert = self.wndAlerts:FindChild("Free50ConfirmAlert")


	self.wndCreateFrame:Show(false)
	self.wndExperiencePicker = self.wndCreateFrame:FindChild("ExperienceSelectFrame")
	self.wndRacePicker = self.wndCreateFrame:FindChild("RaceSelectFrame")
	self.wndClassPicker = self.wndCreateFrame:FindChild("ClassSelectFrame")
	self.wndPathPicker = self.wndCreateFrame:FindChild("PathSelectFrame")
	self.wndControlFrame = self.wndCreateFrame:FindChild("LeftControlFrame")

	local wndFactionFraming = self.wndRaceContent:FindChild("FactionFraming")
	wndFactionFraming:FindChild("DominionBtn"):AttachWindow(wndFactionFraming:FindChild("DominionFloater"))
	wndFactionFraming:FindChild("ExileBtn"):AttachWindow(wndFactionFraming:FindChild("ExileFloater"))

	local nLeftRace, nTopRace, nRightRace, nBottomRace = self.wndRaceContent:FindChild("RaceDetails"):GetAnchorOffsets()
	local nLeftClass, nTopClass, nRightClass, nBottomClass = self.wndRaceContent:FindChild("ClassDetails"):GetAnchorOffsets()
	self.nSeperatorPadding  = nBottomClass - nBottomRace

	local wndBtns = self.wndControlFrame:FindChild("OptionToggles")
	wndBtns:FindChild("ExperienceOptionToggle:Btn"):AttachWindow(self.wndExperiencePicker)
	wndBtns:FindChild("RaceOptionToggle:Btn"):AttachWindow(self.wndRacePicker)
	wndBtns:FindChild("ClassOptionToggle:Btn"):AttachWindow(self.wndClassPicker)
	wndBtns:FindChild("PathOptionToggle:Btn"):AttachWindow(self.wndPathPicker)
	--Customize Option will take player to customization page.

	self.wndFirstName = g_controls:FindChild("FirstNameEntryForm")
	self.wndFirstNameEntry = self.wndFirstName:FindChild("EnterNameEntry")
	self.wndFirstNameEntry:SetMaxTextLength(knMaxCharacterNamePart)
	self.wndFirstNameRandomBtn = self.wndFirstName:FindChild("btn_RenameRandom")
	
	self.wndLastName = g_controls:FindChild("LastNameEntryForm")
	self.wndLastNameEntry = self.wndLastName:FindChild("EnterNameEntry")
	self.wndLastNameEntry:SetMaxTextLength(knMaxCharacterNamePart)

	self.wndCreateCode = g_controls:FindChild("CodeEntryForm")
	self.wndCreateCodeEntry = self.wndCreateCode:FindChild("CreateCodeEditBox")
	self.wndCreateCode:Show(false)
	self.wndCreateCode:FindChild("FailMessage"):Show(false)
	
	self.wndCustPaginationList = self.wndCustomizeContent:FindChild("CustomizeControlFrame")
	self.wndCustOptionList = self.wndCustomizeContent:FindChild("CustomizeOptionPicker")
	self.wndCustOptionUndoBtn = self.wndCustOptionList:FindChild("ResetPickerOptionBtn")
	self.iCurrentPage = 0 -- used for paging through customize features
	self.wndCustAdvanced = self.wndCustomizeContent:FindChild("AdvancedEditingWindow")
	self.wndCustAdvancedResetPopup = self.wndCustAdvanced:FindChild("AdvancedEditingBG:ResetSlidersBtn:ConfirmResetWindow")
	self.wndCustAdvancedResetBtn = self.wndCustAdvanced:FindChild("AdvancedEditingBG:ResetSlidersBtn")	
	self.wndCustAdvanced:Show(false)
	self.wndCustAdvancedResetBtn:AttachWindow(self.wndCustAdvancedResetPopup)

	self.wndCreateFailed = Apollo.LoadForm(self.xmlDoc, "CreateErrorMessage", nil, self)
	self.wndCreateFailed:Show(false)

	self.wndRealmFull = Apollo.LoadForm(self.xmlDoc, "CapacityQueueForm", nil, self)
	self.wndRealmFull:Show(false)

	self.arServerMessages = PreGameLib.GetLastRealmMessages()
	self.wndServerMessagesContainer = Apollo.LoadForm(self.xmlDoc, "RealmMessagesContainer", nil, self)
	self.wndServerMessage = self.wndServerMessagesContainer:FindChild("RealmMessage")
	self:HelperServerMessages()

	self.wndRealmBroadcast = Apollo.LoadForm(self.xmlDoc, "RealmBroadcastMessage", nil, self)
	self.wndRealmBroadcast:Show(false)

	-- Character Creation objects
	self.arCustomizeLookOptions = {}
	self.arCustomizeBoneOptions = {}
	self.arWndCustomizeBoneOptions = {}
	self.arCustomizeOptionBtns = {}
	self.arPreviousCharacterOptions = {}
	self.arCustomizePaginationBtns = {}
	self.arPreviousSliderOptions = {}
	g_nCharCurrentRot = 0

	self.arCharacterCreateOptions = CharacterScreenLib.GetCharacterCreation(PreGameLib.CodeEnumCharacterCreationStart.PreTutorial) -- needs to be before set visible forms.
	self.iPreviousOption = nil -- used for setting undo's on customize

	self:SetAllOptionData()
	self:HelperLoadClassAndRaceRelations() --Must happen after setting all option data
	self:HideCharacterCreate()

	self.iPreviousOption = nil

	self.bBlockEscape = false
	
	if CharacterScreenLib.GetSubscriptionExpired() == true then
		self.wndSubscriptionExpiredAlert:Invoke()
	end
end

function Character:OnAnimationFinished(actor, slot, modelSequence)
	if not g_arActors or actor ~= g_arActors.mainScene then
		return
	end

	--Reverse Animation is the animation from the face to the body.
	--0: Move camera to the body and 1: Move camera to the face
	g_cameraSlider = self.bReverseAnimation and 0 or 1
	g_arActors.mainScene:SetPosition(knDefaultScale, kvecPositionShowCenter, kvecDefaultRotation)
	g_arActors.mainScene:Animate(0, g_cameraAnimation, 0, true, false, knInstantAnimationSpeed, g_cameraSlider)

	self.bZoomedIntoFace = g_cameraSlider > 0
	self.bZoomAnimating = false
end

function Character:OnActorClicked(actor, bDoubleClick)
	if self.wndRaceContent == nil or not self.wndRaceContent:IsValid() then
		return
	end

	for eFaction, tFactions in pairs(ktFactionRaceDisplayInfo) do
		for eGender, tGenderInfo in pairs(tFactions) do
			for eRace, tDisplayInfo in pairs(tGenderInfo) do

				if g_eFactionRestriction == nil or (g_eFactionRestriction ~= nil and eFaction == g_eFactionRestriction) then
				local actorRace = g_arActors[tDisplayInfo.strDisplay][eGender]
				
				local wndBtn
				if eFaction == PreGameLib.CodeEnumFaction.Exile then
					if eRace == PreGameLib.CodeEnumRace.Granok then wndBtn = self.wndRaceContent:FindChild("Buttons"):FindChild("GranokContent:Btn") end
					if eRace == PreGameLib.CodeEnumRace.Human then wndBtn = self.wndRaceContent:FindChild("Buttons"):FindChild("HumanContent:Btn") end
					if eRace == PreGameLib.CodeEnumRace.Mordesh then wndBtn = self.wndRaceContent:FindChild("Buttons"):FindChild("MordeshContent:Btn") end
					if eRace == PreGameLib.CodeEnumRace.Aurin then wndBtn = self.wndRaceContent:FindChild("Buttons"):FindChild("AurinContent:Btn") end
				end
				if eFaction == PreGameLib.CodeEnumFaction.Dominion then
					if eRace == PreGameLib.CodeEnumRace.Draken then wndBtn = self.wndRaceContent:FindChild("Buttons"):FindChild("DrakenContent:Btn") end
					if eRace == PreGameLib.CodeEnumRace.Chua then wndBtn = self.wndRaceContent:FindChild("Buttons"):FindChild("ChuaContent:Btn") end
					if eRace == PreGameLib.CodeEnumRace.Mechari then wndBtn = self.wndRaceContent:FindChild("Buttons"):FindChild("MechariContent:Btn") end
					if eRace == k_idCassian then wndBtn = self.wndRaceContent:FindChild("Buttons"):FindChild("CassianContent:Btn") end
				end

				local wndContainer = self.wndRaceContent:FindChild("Container")
				local wndDescription = wndContainer:FindChild(tDisplayInfo.strDisplay..eGender):FindChild("Description")
				wndDescription:Show(false)

				if actorRace == actor then
					self:OnRaceBtnCheck(wndBtn, wndBtn, bDoubleClick)
					
					if self.eFaction ~= nil then
						if AlienFxLib.IsReady() and AlienFxLib.CanUse() then
							local crFactionColor
							if self.eFaction == PreGameLib.CodeEnumFaction.Dominion then
								crFactionColor = ApolloColor.new("Red")
							elseif self.eFaction == PreGameLib.CodeEnumFaction.Exile then
								crFactionColor = ApolloColor.new("Blue")
							end
			
							if crFactionColor then
								AlienFxLib.SetLocationColor(knAlienFxAllLightsLocation, crFactionColor)
							end
						end
					end

					wndDescription:Show(true)
					self:HelperHandleLights()
					self:HelperHandlePointerOppacity()
				end
			end
		end
	end
end
end

function Character:GetActorRaceGender(actor)
	local eFaction = actor:GetFaction()
	local eRace = actor:GetRace()
	local eGender = actor:GetGender()
	
	local eSelectedFaction = nil
	local wndDominionBtn = self.wndRaceContent:FindChild("DominionBtn")
	if wndDominionBtn:IsChecked() then
		eSelectedFaction = PreGameLib.CodeEnumFaction.Dominion
	else
		local wndExileBtn = self.wndRaceContent:FindChild("ExileBtn")
		if wndExileBtn:IsChecked() then
			eSelectedFaction = PreGameLib.CodeEnumFaction.Exile
		end
	end
	
	if eSelectedFaction and eSelectedFaction ~= eFaction then
		return
	end
	
	if eRace == PreGameLib.CodeEnumRace.Human and eFaction == PreGameLib.CodeEnumFaction.Dominion then
		eRace = k_idCassian
	end
	
	if not c_arRaceStrings[eRace] then
		return
	end
	
	if eRace == PreGameLib.CodeEnumRace.Chua then
		eGender = PreGameLib.CodeEnumGender.Male
	end
	
	if not eGender then
		eGender = self.eGender
	end
	
	return { eRace = eRace, eGender = eGender }
end

function Character:OnActorMouseEnter(actor)
	if self.wndRaceContent == nil or not self.wndRaceContent:IsValid() then
		return
	end

	local tRaceGender = self:GetActorRaceGender(actor)
	if not tRaceGender or not tRaceGender.eRace or not tRaceGender.eGender then
		return
	end
	
	local strRace = c_arRaceStrings[tRaceGender.eRace].strName
	local wndDescription = self.wndRaceContent:FindChild(strRace..tRaceGender.eGender):FindChild("Description")

	if wndDescription then
		wndDescription:Show(true)
	end
end

function Character:OnActorMouseExit(actor)
	if self.wndRaceContent == nil or not self.wndRaceContent:IsValid() then
		return
	end
	
	local tRaceGender = self:GetActorRaceGender(actor)
	if not tRaceGender or not tRaceGender.eRace or not tRaceGender.eGender then
		return
	end
	
	local strRace = c_arRaceStrings[tRaceGender.eRace].strName
	local wndDescription = self.wndRaceContent:FindChild(strRace..tRaceGender.eGender):FindChild("Description")

	if wndDescription then
		wndDescription:Show(false)
	end
end

function Character:UpdateCharacterModelAndPosition()
	if self.bChangedDetailOrSwitchedTab then
		if self.eRace then
			--This is used to be able to reference Cassian's equivalent from the code given information.
			local eRaceExternal = self.eRace == k_idCassian and PreGameLib.CodeEnumRace.Human or self.eRace
			local eGenederExternal = self.eRace ~= PreGameLib.CodeEnumRace.Chua and self.eGender or PreGameLib.CodeEnumGender.Male
			local nPossibleCharacterCreateIndex = self:GetCharacterCreateId(self.eFaction, eRaceExternal, self.eClass, eGenederExternal)

			-- dont change if we dont find it
			if nPossibleCharacterCreateIndex ~= 0 then
				self:SetCharacterCreateIndex( nPossibleCharacterCreateIndex )
			end
			
				--Setting the character look.
			if g_arActors.primary and g_arActors.shadow then
				for i, option in pairs(self.arCustomizeLookOptions or {}) do
					g_arActors.primary:SetLook(option.sliderId, option.values[ option.valueIdx ] )
					g_arActors.shadow:SetLook(option.sliderId, option.values[ option.valueIdx ] )
				end
				
				for i, bone in ipairs(self.arCustomizeBoneOptions) do
					g_arActors.primary:SetBone(bone.sliderId, bone.value)
				end
			end
			
			if self.eClass then
				local wndLastSelectedPreview  = nil
				local eCurTab = self.wndTab:GetData()
				if eCurTab == keTutorialTab.Class and self.tLastCheckedGearPreviewBtns then --Only apply the last gear if still on the class tab.
					wndLastSelectedPreview = self.tLastCheckedGearPreviewBtns.wndClassContentBtn
				end

				self:OnGearPreview(wndLastSelectedPreview, wndLastSelectedPreview) --Use the last selected gear preview button.
			end
		end
	end

	self:ConfigureCreateModelSettings() --Will move character into kvecPositionShowCenter or kvecPositionShowRight based on the current tab.
	self.bChangedDetailOrSwitchedTab = false
	
	--Showing the character by default should be showing the body(Has to occur afer ConfigureCreateModelSettings).
	self:HelperZoomOutToCharacterBody()
end

	---------------------------------------------------------------------------------------------------
-- Entry Events
---------------------------------------------------------------------------------------------------
-- Receiving this event means the player has been queued due to capacity; direct to that screen
function Character:OnQueueStatus( nPositionInQueue, nEstimatedWaitInSeconds, bIsGuest )
	local tRealmInfo = CharacterScreenLib.GetRealmInfo()
	local strRealmType = tRealmInfo.nRealmPVPType == PreGameLib.CodeEnumRealmPVPType.PVP and Apollo.GetString("RealmSelect_PvP") or Apollo.GetString("RealmSelect_PvE")
	self.wndRealmFull:Show(true)
	self.wndRealmFull:FindChild("CapacityFormCenter"):FindChild("GuestOnlyMessage"):Show(bIsGuest)
	self.wndRealmFull:FindChild("CapacityFormCenter"):FindChild("Title"):SetText(Apollo.GetString("Pregame_RealmFull"))
	self.wndRealmFull:FindChild("CapacityFormCenter"):FindChild("Body"):SetText(kstrRealmFullClosed)
	self.wndRealmFull:FindChild("PositionInfoBacker"):Show(true)
	self.wndRealmFull:FindChild("PositionInQueueEntry"):SetText(Apollo.GetString("Pregame_RealmQueue_Position") .. " " .. tostring(nPositionInQueue))
	self.wndRealmFull:FindChild("WaitTimeEntry"):SetText(Apollo.GetString("Pregame_RealmQueue_WaitTimeLabel").. " " .. self:HelperConvertToTime(nEstimatedWaitInSeconds or 0))
	self.wndRealmFull:FindChild("QueuedRealm"):SetText(Apollo.GetString("Pregame_RealmQueue_RealmName").. " " .. tostring(tRealmInfo.strName).." (".. strRealmType ..")")

	self.wndCharacterListPrompt:Show(false)
end

function Character:OnQueueFinished()
	self.wndRealmFull:Show(false)
	self.wndRealmFull:FindChild("WaitTimeEntry"):SetText("")
	self.wndRealmFull:FindChild("PositionInQueueEntry"):SetText("")
	self.wndRealmFull:FindChild("PositionInfoBacker"):Show(false)
	self.wndRealmFull:FindChild("CapacityFormCenter"):FindChild("Title"):SetText(Apollo.GetString("Pregame_RealmAvailable"))
	self.wndRealmFull:FindChild("CapacityFormCenter"):FindChild("Body"):SetText(kstrRealmFullOpen)
	
	self:OpenCharacterSelect()
end

-- Receiving this event means the player's character list has come down. Note: can happen when on the queue screen.
function Character:OnCharacterList( nMaxNumCharacters, arCharacters, arCharacterInWorld, eFactionRestriction )
	g_arCharacters = arCharacters
	g_arCharacterInWorld = arCharacterInWorld
	g_nMaxNumCharacters = nMaxNumCharacters

	self.bHaveCharacters = true

	if CharacterScreenLib.GetSubscriptionExpired() == true then
		self.wndSubscriptionExpiredAlert:Invoke()
	end
	
	local tRealmInfo = CharacterScreenLib.GetRealmInfo()
	if tRealmInfo and tRealmInfo.bFactionRestricted and eFactionRestriction ~= 0 then
		g_eFactionRestriction = eFactionRestriction
	end

	if not self.wndRealmFull:IsShown() then
		self:OpenCharacterSelect()
	end
end

function Character:OnChangeRealmBtn(wndHandler, wndControl)
	self.wndRealmFull:Show(false)
	CharacterScreenLib.ExitToRealmSelect()
end

function Character:OnLeaveQueueBtn(wndHandler, wndControl)
	CharacterScreenLib.ExitToLogin()
end

---------------------------------------------------------------------------------------------------
-- State Machine
---------------------------------------------------------------------------------------------------
function Character:OpenCharacterSelect()
	local bControlsShown = g_controls:IsShown()
	
	self.wndCharacterListPrompt:Show(false)
	self:HideCharacterCreate()
	self.wndServerMessagesContainer:Show(true)
	g_controls:Show(true)
	g_controls:FindChild("CharacterNameText"):Show(false)
	
	self.wndCreateCode:Show(false)
	self.wndFirstName:Show(false)
	self.wndFirstNameEntry:SetText("")
	self.wndFirstName:FindChild("CheckMarkIcon"):SetSprite("")
	self.wndLastName:Show(false)
	self.wndLastNameEntry:SetText("")
	self.wndLastName:FindChild("CheckMarkIcon"):SetSprite("")
	
	g_controls:FindChild("EnterForm"):Show(true)

	g_eState = LuaEnumState.Select
	g_controlCatcher:SetFocus()

	PreGameLib.Event_FireGenericEvent("LoadFromCharacter")
	PreGameLib.SetMusic(PreGameLib.CodeEnumMusic.CharacterSelect)

	g_cameraSlider = 0
	g_arActors.mainScene:Animate(0, g_cameraAnimation, 0, true, false, knInstantAnimationSpeed, g_cameraSlider)
	self.bZoomedIntoFace = false
	
	if not bControlsShown then --When screen appears play sound
		Sound.Play(Sound.PlayUICharacterSelectScreen)
	end
end

function Character:OnOpenCharacterCreate()
	g_controls:Show(false)
	self.wndServerMessagesContainer:Show(false)
	self.characterCreateIndex = 0
	
	self.wndFirstNameRandomBtn:Show(PreGameLib.GetGameMode() ~= PreGameLib.CodeEnumGameMode.China)

	self:SetInitialCreateForms()
	PreGameLib.SetMusic(PreGameLib.CodeEnumMusic.CharacterCreate)

	g_cameraSlider = 0
	g_arActors.mainScene:Animate(0, g_cameraAnimation, 0, true, false, knInstantAnimationSpeed, g_cameraSlider)
	self.bZoomedIntoFace = false
end

function Character:OnOpenCharacterCreate50()
	self:OnOpenCharacterCreate()
	
	self.wndCreateFrame:FindChild("ExperienceContent:ExperienceSelectFrame:ButtonContainer:ExpertBtn"):Show(false)
	self.wndCreateFrame:FindChild("FinalizeContent:ExperienceSelectFrame:ExperienceSelectionAssets:ExperiencedEntry"):Show(false)
	self.wndCreateFrame:FindChild("ExperienceContent:ExperienceSelectFrame:ButtonContainer:NoviceBtn"):Show(false)
	self.wndCreateFrame:FindChild("FinalizeContent:ExperienceSelectFrame:ExperienceSelectionAssets:NoviceEntry"):Show(false)
	
	wndBtn = self.wndCreateFrame:FindChild("FinalizeContent:ExperienceSelectFrame:ExperienceSelectionAssets:Level50Entry"):Show(true)
	local wndBtn = self.wndCreateFrame:FindChild("ExperienceContent:ExperienceSelectFrame:ButtonContainer:Level50Btn")
	wndBtn:Show(true)
	self:OnExperienceBtnCheck(wndBtn, wndBtn, 0, true)
end

function Character:HelperHandleCustomized()
	local bWasCustomized = self.eRace ~= nil
	self.wndGlobal:FindChild("Header:CustomizeTab:Icon"):SetSprite(bWasCustomized and kstrSelectedTabIcon or kstrDefaultTabIcon)

	local wndCustomizeOptionToggle = self.wndFinalizeContent:FindChild("CustomizeOptionToggle")
	wndCustomizeOptionToggle:FindChild("Selection"):SetText(bWasCustomized and Apollo.GetString("QuestCompleted") or Apollo.GetString("Pregame_NotCompleted"))
	wndCustomizeOptionToggle:FindChild("Icon"):Show(not bWasCustomized)

	local wndSelectionIcon = wndCustomizeOptionToggle:FindChild("SelectionIcon")
	wndSelectionIcon:SetSprite(bWasCustomized and kstrFinalizeSelected or kstrFinalizeNotSelected)
	wndSelectionIcon:Show(bWasCustomized)
end

function Character:ShowErrorIndicators()
	-- If required selections haven't been made, highlight text in red.
	local wndParent = self.wndControlFrame:FindChild("OptionToggles")	
	local wndExperienceToggle = wndParent:FindChild("ExperienceOptionToggle")
	local wndRaceToggle = wndParent:FindChild("RaceOptionToggle")
	local wndClassToggle = wndParent:FindChild("ClassOptionToggle")
	local wndPathToggle = wndParent:FindChild("PathOptionToggle")

	wndExperienceToggle:FindChild("Selection"):SetTextColor(not wndExperienceToggle:GetData() and kstrErrorTextColor or kstrHoloTextColor)
	wndRaceToggle:FindChild("Selection"):SetTextColor(not wndRaceToggle:GetData() and kstrErrorTextColor or kstrHoloTextColor)
	wndClassToggle:FindChild("Selection"):SetTextColor(not wndClassToggle:GetData() and kstrErrorTextColor or kstrHoloTextColor)
	wndPathToggle:FindChild("Selection"):SetTextColor(not wndPathToggle:GetData() and kstrErrorTextColor or kstrHoloTextColor)
	
	-- If the player hasn't entered a valid name parts, highlight text entry boxes
	local strFirstName = self.wndFirstNameEntry:GetText()
	local strLastName = self.wndLastNameEntry:GetText()
	
	local bValidFirstName = CharacterScreenLib.IsCharacterNamePartValid(strFirstName)
	local bValidLastName = CharacterScreenLib.IsCharacterNamePartValid(strLastName)
	
	self.wndFirstName:FindChild("ErrorIndicator"):Show(not bValidFirstName)
	self.wndLastName:FindChild("ErrorIndicator"):Show(not bValidLastName)	
end

function Character:OnConfirmSubscriptionBtn(wndHandler, wndControl)
	self.wndSubscriptionExpiredAlert:Close()
end

function Character:OnEnterBtn(wndHandler, wndControl)
	if CharacterScreenLib.GetSubscriptionExpired() == true then
		self.wndSubscriptionExpiredAlert:Invoke()
		return
	end

	if g_eState == LuaEnumState.Create then
		local bValidCreate = self.eTutorialLevel ~= nil and self.eRace ~= nil and self.eClass ~= nil and self.ePath ~= nil and self.eFaction ~= nil and self.eGender ~= nil and self.strName ~= nil and CharacterScreenLib.IsCharacterNameValid(self.strName)
		
		if not bValidCreate then
			self:ShowErrorIndicators()
		else
			self.strName = string.format("%s %s", self.wndFirstNameEntry:GetText(), self.wndLastNameEntry:GetText())
	
			local tCreation = self.arCharacterCreateOptions[self.characterCreateIndex]
			if Apollo.StringLength(self.strName) > 0 and tCreation then
				local tCreationResults = CharacterScreenLib.GetCharacterCreationIdsByValues(self.eTutorialLevel, tCreation.factionId, tCreation.classId, tCreation.raceId, tCreation.genderId)
				if tCreationResults and tCreationResults.arEnabledIds and tCreationResults.arEnabledIds[1] then
					if self.eTutorialLevel == PreGameLib.CodeEnumCharacterCreationStart.Level50 then
						-- show confirmation alert
						if CharacterScreenLib.GetFreeLevel50sRemaining() > 0 then
							self:OnFreeLevel50ConfirmAlert()
						else
							self:OnPromotionTokenConfirmAlert()
						end
						return
					end
					
					local nCharacterCreateId = tCreationResults.arEnabledIds[1]
					CharacterScreenLib.CreateCharacter(self.strName, nCharacterCreateId, g_arActors.primary, self.ePath)
				else
					self:OnCriticalStateAlert()
				end
			end
		end
	elseif g_eState == LuaEnumState.Select and wndControl:GetData() ~= nil then
		PreGameLib.Event_FireGenericEvent("SelectCharacter", wndControl:GetData())
	else
		return -- unhandled; should never occur
	end
end

function Character:OnCriticalStateAlert()
	if not self.wndCriticalStateAlert then
		return
	end

	self.wndCriticalStateAlert:Invoke()
end

function Character:OnConfirmCriticalStateBtn()
	CharacterScreenLib.ExitToLogin()
end

function Character:OnBackBtn()
	if self.bBlockEscape then
		return
	end

	if g_eState == LuaEnumState.Create then
		self:ResetOptionButtons()
		self:OpenCharacterSelect()
		PreGameLib.Event_FireGenericEvent("Pregame_CreationToSelection")
	elseif g_eState == LuaEnumState.Select then
		CharacterScreenLib.ExitToLogin()
	elseif g_eState == LuaEnumState.Delete then
		self:ResetOptionButtons()
		g_arActors.deleteEffect = nil
		self:OpenCharacterSelect()
		PreGameLib.Event_FireGenericEvent("Pregame_CreationToSelection")
	elseif g_eState == LuaEnumState.Buy then
		PreGameLib.Event_FireGenericEvent("CloseStore")
		g_eState = LuaEnumState.Select
	else
		return -- unhandled; should never occur
	end
end

function Character:OnSubscriptionExpired()
	if not self.wndSubscriptionExpiredAlert then
		return
	end

	self.wndSubscriptionExpiredAlert:Invoke()
end

function Character:OnPromotionTokenConfirmAlert()
	if not self.wndPromotionTokenConfirmAlert then
		return
	end
	
	local tCreation = self.arCharacterCreateOptions[self.characterCreateIndex]
	local tCreationResults = CharacterScreenLib.GetCharacterCreationIdsByValues(self.eTutorialLevel, tCreation.factionId, tCreation.classId, tCreation.raceId, tCreation.genderId)
	tCreation = CharacterScreenLib.GetCharacterCreationById(tCreationResults.arEnabledIds[1])
	if not tCreation or not tCreation.monCost then
		return
	end

	local strBody = PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_PromotionTokenConfirm"), tCreation.monCost:GetMoneyString())
	self.wndPromotionTokenConfirmAlert:FindChild("Body"):SetText(strBody)
	local wndPrice = self.wndPromotionTokenConfirmAlert:FindChild("Price"):FindChild("CashWindow")
	wndPrice:SetAmount(tCreation.monCost)
	local wndBalance = self.wndPromotionTokenConfirmAlert:FindChild("Balance"):FindChild("CashWindow")
	wndBalance:SetAmount(AccountItemLib.GetAccountCurrency(tCreation.monCost:GetAccountCurrencyType()))
	
	self.wndPromotionTokenConfirmAlert:Invoke()
end

function Character:OnFreeLevel50ConfirmAlert()
	if not self.wndFreeLevel50ConfirmAlert then
		return
	end
	
	local strBody = PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_ConfirmFree50"), CharacterScreenLib.GetFreeLevel50sRemaining() - 1)
	self.wndFreeLevel50ConfirmAlert:FindChild("Body"):SetText(strBody)
	
	self.wndFreeLevel50ConfirmAlert:Invoke()
end

function Character:OnConfirmPromotionTokenCost()
	local tCreation = self.arCharacterCreateOptions[self.characterCreateIndex]
	local tCreationResults = CharacterScreenLib.GetCharacterCreationIdsByValues(self.eTutorialLevel, tCreation.factionId, tCreation.classId, tCreation.raceId, tCreation.genderId)
	local nCharacterCreateId = tCreationResults.arEnabledIds[1]
	CharacterScreenLib.CreateCharacter(self.strName, nCharacterCreateId, g_arActors.primary, self.ePath)
end

function Character:OnCancelPromotionTokenCost()
	self.wndPromotionTokenConfirmAlert:Close()
end

function Character:OnConfirmFreeLevel50( wndHandler, wndControl, eMouseButton )
	local tCreation = self.arCharacterCreateOptions[self.characterCreateIndex]
	local tCreationResults = CharacterScreenLib.GetCharacterCreationIdsByValues(self.eTutorialLevel, tCreation.factionId, tCreation.classId, tCreation.raceId, tCreation.genderId)
	local nCharacterCreateId = tCreationResults.arEnabledIds[1]
	CharacterScreenLib.CreateCharacter(self.strName, nCharacterCreateId, g_arActors.primary, self.ePath)
end

function Character:OnCancelFreeLevel50( wndHandler, wndControl, eMouseButton )
	self.wndFreeLevel50ConfirmAlert:Close()
end

---------------------------------------------------------------------------------------------------
-- Visiblity Settings
---------------------------------------------------------------------------------------------------
function Character:HideCharacterCreate()
	g_controls:Show(false)

	self.wndCreateFrame:Show(false)
	self.wndRacePicker:Show(false)
	self.wndClassPicker:Show(false)
	self.wndPathPicker:Show(false)

	self.wndFirstName:Show(false)
	self.wndFirstNameEntry:SetText("")
	self.wndFirstName:FindChild("ErrorIndicator"):Show(false)
	self.wndFirstName:FindChild("CheckMarkIcon"):SetSprite("")

	self.wndLastName:Show(false)
	self.wndLastNameEntry:SetText("")
	self.wndLastName:FindChild("ErrorIndicator"):Show(false)
	self.wndLastName:FindChild("CheckMarkIcon"):SetSprite("")

	-- Reset error indicator colors
	local tOptionToggles = self.wndControlFrame:FindChild("OptionToggles"):GetChildren()
	for idx, wndOption in pairs(tOptionToggles) do
		wndOption:FindChild("Selection"):SetTextColor(kstrHoloTextColor)
	end	
	
	self.wndInfoPane:Show(false)
	self.wndCustomizeContent:Show(false)
end

function Character:SetInitialCreateForms()
	-- TODO: Skip this once a faction has been selected on a realm

	g_controls:Show(false)
	g_eState = LuaEnumState.Create
	
	g_controls:FindChild("EnterForm"):FindChild("BGArt_BottomRunnerName"):Show(true)
	g_controls:FindChild("EnterForm"):FindChild("BGArt_BottomRunner"):Show(false)
	g_controls:FindChild("EnterBtn"):Enable(true)

	g_controls:FindChild("CameraControls"):Show(false)

	self.wndCreateFrame:Show(false)
	self.wndExperiencePicker:Show(false)
	self.wndRacePicker:Show(false)
	self.wndClassPicker:Show(false)
	self.wndPathPicker:Show(false)

	self.wndInfoPane:Show(false)
	self.wndCustomizeContent:Show(false)
	self.wndFirstNameEntry:SetText("")
	self.wndLastNameEntry:SetText("")
	
	--GOTCHA: Setting these to true actually means collapsed!
	local wndInfoPaneContainer		= self.wndInfoPane:FindChild("InfoPane_SortContainer")
	wndInfoPaneContainer:FindChild("Faction:Button"):SetCheck(true)
	wndInfoPaneContainer:FindChild("Race:Button"):SetCheck(true)
	wndInfoPaneContainer:FindChild("Class:Button"):SetCheck(true)
	wndInfoPaneContainer:FindChild("Path:Button"):SetCheck(true)

	self:SetCreateForms()
end

function Character:SetCreateForms()
	g_eState = LuaEnumState.Create
	g_controlCatcher:SetFocus()

	self.wndCreateFrame:Show(true)
	self.wndRacePicker:Show(false)
	self.wndClassPicker:Show(false)
	self.wndPathPicker:Show(false)
	self.wndCustOptionList:Show(false)
	self.wndCustAdvanced:Show(false)
	self.wndFirstNameEntry:SetFocus()
	self.wndFirstName:Show(true)
	self.wndLastName:Show(true)

	g_controls:FindChild("EnterForm"):Show(true)
	g_controls:FindChild("ExitForm"):Show(true)
	g_controls:FindChild("ExitForm"):FindChild("BackBtnLabel"):SetText(Apollo.GetString("CRB_Cancel"))
	g_controls:FindChild("OptionsContainer"):Show(true)

	self.wndCustomizeContent:Show(false)

	--These ids will not be set initially. After confirming or canceling customization options for looks we want to show correct page.
	if not self.eRace and not self.eFaction and not self.eClass and not self.eGender and not self.ePath then
		self:StartGuidedTour()
	else
		self:ShowCorrectTabPage()
	end
end

function Character:StartGuidedTour()
	self.wndTab 		= self.wndCreateFrame:FindChild("ExperienceTab")
	self:HelperSetInfoPane(true)
	
	--Hide all tab contents
	self.wndExperienceContent:Show(false)
	self.wndRaceContent:Show(false)
	self.wndClassContent:Show(false)
	self.wndPathContent:Show(false)
	self.wndCustomizeContent:Show(false)
	self.wndFinalizeContent:Show(false)

	self:ResetOptionButtons()
	self:HelperRandomizeGender()

	if not self.bLoadedActors then
		self:SetupAllRaceActors()
	end

	local wndDominionBtn = self.wndRaceContent:FindChild("DominionBtn")
	local wndExileBtn = self.wndRaceContent:FindChild("ExileBtn")
	if g_eFactionRestriction ~= nil then
		local wndDisableBtn = wndDominionBtn
		local wndCheckBtn = wndExileBtn
		if g_eFactionRestriction == PreGameLib.CodeEnumFaction.Dominion then
			wndDisableBtn = wndExileBtn
			wndCheckBtn = wndDominionBtn
		end
		wndDisableBtn:Enable(false)
		wndCheckBtn:SetCheck(true)

		local tFactions = 
		{
			[PreGameLib.CodeEnumFaction.Exile] 		= Apollo.GetString("Friends_ExilesFaction"),
			[PreGameLib.CodeEnumFaction.Dominion] 	= Apollo.GetString("Friends_DominionFaction"),
		}
		local strDisabled = PreGameLib.String_GetWeaselString(Apollo.GetString("PregameCharacter_FactionLockedTooltip"), tFactions[g_eFactionRestriction])
		wndDisableBtn:GetParent():SetTooltip(strDisabled)
		wndDisableBtn:FindChild("CN_FactionBlocker"):Show(true)

		local wndButtons = self.wndRacePicker:FindChild("Buttons")
		for idx, wndEntry in pairs(wndButtons:GetChildren()) do
			local wndBtn = wndEntry:FindChild("Btn")
			local tInfo = wndBtn:GetData()
			wndBtn:Enable(tInfo.eFaction == g_eFactionRestriction)
		end

		local wndDominionBlocker = self.wndFinalizeContent:FindChild("DominionBlocker")
		wndDominionBlocker:Show(g_eFactionRestriction ~= PreGameLib.CodeEnumFaction.Dominion)
		wndDominionBlocker:FindChild("DisabledText"):SetText(g_eFactionRestriction ~= PreGameLib.CodeEnumFaction.Dominion and strDisabled or "")

		local wndExilesBlocker = self.wndFinalizeContent:FindChild("ExilesBlocker")
		wndExilesBlocker:Show(g_eFactionRestriction ~= PreGameLib.CodeEnumFaction.Exile)
		wndExilesBlocker:FindChild("DisabledText"):SetText(g_eFactionRestriction ~= PreGameLib.CodeEnumFaction.Exile and strDisabled or "")
		
	end

	local bEnabled = CharacterScreenLib.IsCharacterCreationStartAllowed(PreGameLib.CodeEnumCharacterCreationStart.Nexus)

	local strTooltip = ""
	if not bEnabled then
		strTooltip = Apollo.GetString("Pregame_VeteranDisabled")
	end

	local wndBtn = self.wndCreateFrame:FindChild("ExperienceContent:ExperienceSelectFrame:ButtonContainer:ExpertBtn")
	wndBtn:Enable(bEnabled)
	wndBtn:FindChild("IconDisabled"):Show(not bEnabled)
	wndBtn:FindChild("Icon"):Show(bEnabled)
	wndBtn:SetTooltip(strTooltip)
	wndBtn:Show(true)

	wndBtn = self.wndCreateFrame:FindChild("FinalizeContent:ExperienceSelectFrame:ExperienceSelectionAssets:ExperiencedEntry:ExperienceBtn")
	wndBtn:Enable(bEnabled)
	wndBtn:FindChild("IconDisabled"):Show(not bEnabled)
	wndBtn:FindChild("Icon"):Show(bEnabled)
	wndBtn:SetTooltip(strTooltip)
	
	wndBtn = self.wndCreateFrame:FindChild("FinalizeContent:ExperienceSelectFrame:ExperienceSelectionAssets:ExperiencedEntry")
	wndBtn:Show(true)

	wndBtn = self.wndCreateFrame:FindChild("ExperienceContent:ExperienceSelectFrame:ButtonContainer:NoviceBtn")
	wndBtn:Show(true)
	
	wndBtn = self.wndCreateFrame:FindChild("FinalizeContent:ExperienceSelectFrame:ExperienceSelectionAssets:NoviceEntry")
	wndBtn:Show(true)
	
	wndBtn = self.wndCreateFrame:FindChild("ExperienceContent:ExperienceSelectFrame:ButtonContainer:Level50Btn")
	wndBtn:Show(false)
	
	wndBtn = self.wndCreateFrame:FindChild("FinalizeContent:ExperienceSelectFrame:ExperienceSelectionAssets:Level50Entry")
	wndBtn:Show(false)
	
	self:HelperHandlePointerOppacity(not wndDominionBtn:IsChecked() and not wndExileBtn:IsChecked())
	self.ePageToShow = keTutorialTab.Experience
	self:ShowCorrectTabPage()
end

function Character:HelperRandomizeGender()
	local wndMaleBtn = self.wndRaceContent:FindChild("MaleBtn")
	local wndFemaleBtn = self.wndRaceContent:FindChild("FemaleBtn")
	
	local eRandGender = math.random(PreGameLib.CodeEnumGender.Male, PreGameLib.CodeEnumGender.Female)
	wndMaleBtn:SetCheck(eRandGender == PreGameLib.CodeEnumGender.Male)
	wndFemaleBtn:SetCheck(eRandGender == PreGameLib.CodeEnumGender.Female)
	
	local wndGenderBtn = eRandGender == PreGameLib.CodeEnumGender.Male and wndMaleBtn or wndFemaleBtn
	self:OnToggleGender(wndGenderBtn, wndGenderBtn)
end

function Character:StepBackwardGuidedTour()
	self.ePageToShow = self.ePageToShow - 1
	
	-- skip experience screen if creating a level 50
	if self.eTutorialLevel == PreGameLib.CodeEnumCharacterCreationStart.Level50 and self.ePageToShow == keTutorialTab.Experience then
		self.ePageToShow = self.ePageToShow - 1
	end

	--Show the right tutorial page, or the character selection if not
	if self.ePageToShow >= keTutorialTab.Experience then
		self:ShowCorrectTabPage()
	else
		self:OnBackBtn()
	end
end

function Character:ResetOptionButtons()
	g_nCharCurrentRot = 0

	--Uncheck all btns.
	local wndBtns = self.wndRaceContent:FindChild("Buttons")
	for idx, wndRaceContent in pairs(wndBtns:GetChildren()) do
		local wndBtn = wndRaceContent:FindChild("Btn")
		wndBtn:SetCheck(false)
		self:OnExperienceBtnUncheck(wndBtn, wndBtn)
	end

	wndBtns = self.wndRacePicker:FindChild("Buttons")
	for idx, wndRace in pairs(wndBtns:GetChildren()) do
		local wndBtn = wndRace:FindChild("Btn")
		self:OnRaceBtnUncheck(wndBtn, wndBtn) --Automatically unchecks both tutorial and finalize buttons.
	end

	wndBtns = self.wndClassContent:FindChild("Buttons")
	for idx, wndBtn in pairs(wndBtns:GetChildren()) do
		wndBtn:FindChild("LineConnection"):SetOpacity(1)
		wndBtn:FindChild("LineConnection"):Show(false)
		self:OnClassBtnUncheck(wndBtn, wndBtn) --Automatically unchecks both tutorial and finalize buttons.
	end

	wndBtns = self.wndPathContent:FindChild("Buttons")
	for idx, wndBtn in pairs(wndBtns:GetChildren()) do
		wndBtn:FindChild("LineConnection"):Show(false)
		self:OnPathBtnUncheck(wndBtn, wndBtn) --Automatically unchecks both tutorial and finalize buttons.
	end
	
	wndBtns = self.wndExperienceContent:FindChild("ButtonContainer")
	for idx, wndBtn in pairs(wndBtns:GetChildren()) do
		self:OnExperienceBtnUncheck(wndBtn, wndBtn)
	end
	
	wndBtns = self.wndRaceContent:FindChild("GenderFraming")
	wndBtns:FindChild("MaleBtn"):SetCheck(false)
	wndBtns:FindChild("FemaleBtn"):SetCheck(false)
	
	wndBtns = self.wndFinalizeContent:FindChild("GenderContainer")
	wndBtns:FindChild("MaleBtn"):SetCheck(false)
	wndBtns:FindChild("FemaleBtn"):SetCheck(false)
	
	wndBtns = self.wndRaceContent:FindChild("FactionFraming")
	local wndDominionEntry = wndBtns:FindChild("DominionEntry")
	local wndExileEntry = wndBtns:FindChild("ExileEntry")

	wndDominionEntry:SetTooltip("")
	wndExileEntry:SetTooltip("")

	local wndDominionBtn = wndDominionEntry:FindChild("DominionBtn")
	local wndExileBtn = wndExileEntry:FindChild("ExileBtn")
	wndDominionBtn:Enable(true)
	wndExileBtn:Enable(true)
	wndDominionBtn:SetCheck(false)
	wndExileBtn:SetCheck(false)
	wndDominionBtn:FindChild("CN_FactionBlocker"):Show(false)
	wndExileBtn:FindChild("CN_FactionBlocker"):Show(false)
	
	self.wndCreationAlert:Show(false)
	self.wndCustomizationAlert:Show(false)
	self.wndCustomizationConfirmAlert:Show(false)
	self.wndSubscriptionExpiredAlert:Show(false)

	self.wndLastNameEntry:SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
	self.wndFirstNameEntry:SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
	
	self.bCustomizationChanged = false
	self.eRace = nil
	self.eClass = nil
	self.ePath = nil
	self.eGender = nil
	self.strName = nil
	self.tLastSelectedExperienceButtons = nil
	self.tLastSelectedRaceButtons = nil
	self.tLastSelectedClassButtons = nil
	self.tLastSelectedPathButtons = nil
	self.tLastCheckedGearPreviewBtns = nil
	self.ePageToShow = nil
	self.tSelectedAcorInfo = nil

	for idx, wndChild in pairs(self.wndGlobal:FindChild("Header"):GetChildren()) do 
		if wndChild:FindChild("Icon") then
			wndChild:FindChild("IndicatorBar"):SetSprite("charactercreate:sprCharC_HeaderStepFraming")
			wndChild:FindChild("Icon"):SetSprite("charactercreate:sprCharC_HeaderStepIncomplete")
		end
	end

	self.wndTab = nil

	self.wndInfoPane:FindChild("EarlyPreview"):SetCheck(true)
	self.wndClassContent:FindChild("EarlyPreview"):SetCheck(true)
	
	self:HelperHandleLights() --removes lights
	self:HelperUpdateRaceActors() -- removes actors
	self:HelperHandleCustomized() --removes completed customization on finalize tab
	self:SetConflictWarnings() --removes the warnings

	self:UpdateCharacterModelAndPosition()
end

function Character:StepForwardGuidedTour()
	if self.ePageToShow < keTutorialTab.Finalize then
		self.ePageToShow = self.ePageToShow + 1
		self:ShowCorrectTabPage()
	end
end

function Character:OnSelectTab(wndHandler, wndControl)
	self.bRotateEngaged = false
	if wndHandler ~= wndControl or wndHandler == self.wndTab then --If clicking the same tab that is already shown.
		return
	end
	self.ePageToShow = wndControl:GetData()
	self:ShowCorrectTabPage()
end

function Character:ShowCorrectTabPage()
	--Hide previously shown screen.
	if self.wndTutorial and self.wndTutorial:IsShown() then
		self.wndTutorial:Show(false)
	end

	--Clear tab sprite. Sprite will be set on correct page.
	if self.wndTab then
		local wndIndicatorBar = self.wndTab:FindChild("IndicatorBar")
		wndIndicatorBar:SetSprite("charactercreate:sprCharC_HeaderStepFraming")
	end

	--g_Controls will be shown in Finalize tab.
	if g_controls and g_controls:IsShown() then
		g_controls:Show(false)
	end
	
	--Info pane will be shown in the Finalize tab, if there is faction, race, class, or path selected.
	if self.wndInfoPane and self.wndInfoPane:IsShown() then
		self.wndInfoPane:Show(false)
	end
	
	--Was on the customization tab making changes, close down the customization windows.
	if self.wndLastCustomizationPageBtn then
		self:OnCustomizePaginationUncheck(self.wndLastCustomizationPageBtn, self.wndLastCustomizationPageBtn)
		self.wndLastCustomizationPageBtn = nil
	end

	--Close down the button containers on the finalize page	
	self.wndExperiencePicker:Show(false)
	self.wndRacePicker:Show(false)
	self.wndClassPicker:Show(false)
	self.wndPathPicker:Show(false)
	self.wndCustAdvanced:Show(false)

	--Must have a race to show customization tab.
	if not self.eRace and self.ePageToShow == keTutorialTab.Customize then
		self.wndCustomizationAlert:Invoke()
		return
	else
		self.wndCustomizationAlert:Close()
	end

	self.bChangedDetailOrSwitchedTab = true
	self.bZoomAnimating = false

	--The ForawardBtn will be shown for all except customize, hide in ShowCustomize.
	self.wndGlobal:FindChild("BackBtn"):Show(true)
	self.wndGlobal:FindChild("ForwardBtn"):Show(true)
	
	--The Class armor preview will be shown in the class tab.
	self.wndClassContent:FindChild("ClassArmorPreview"):Show(false)
	
	self:HelperStopMovie()

	--The mouse catcher swallows double clicks from the actors.
	--As long as player can't zoom on race page, this should be fine.
	g_controlCatcher:Show(self.ePageToShow ~= keTutorialTab.Race)
	
	local tButtons = nil
	local strSelectTitle = ""
	if self.ePageToShow == keTutorialTab.Experience then
		--ShowExperience
		self.wndExperienceContent:Show(true)
		self.wndTab 		= self.wndGlobal:FindChild("ExperienceTab")
		self.wndTutorial = self.wndExperienceContent
		tButtons = self.wndExperienceContent:FindChild("ButtonContainer"):GetChildren()
		strSelectTitle = Apollo.GetString("Pregame_Select_Exeperience")

	elseif self.ePageToShow == keTutorialTab.Race then
		--ShowRace
		self.wndRaceContent:Show(true)
		self.wndTab 		= self.wndGlobal:FindChild("RaceTab")
		self.wndTutorial = self.wndRaceContent
		tButtons = self.wndRaceContent:FindChild("Buttons"):GetChildren()
		strSelectTitle = Apollo.GetString("Pregame_Select_Race")

	elseif self.ePageToShow == keTutorialTab.Class then
		--ShowClass
		self.wndClassContent:Show(true)
		self.wndTab 		= self.wndGlobal:FindChild("ClassTab")
		self.wndTutorial = self.wndClassContent
		tButtons = self.wndClassContent:FindChild("Buttons"):GetChildren()
		strSelectTitle = Apollo.GetString("Pregame_Select_Class")
		self.wndClassContent:FindChild("ClassArmorPreview"):Show(self.eRace ~= nil and self.eClass ~= nil)
		if self.eClass then
			self:HelperPlayMovie()
		end

	elseif self.ePageToShow == keTutorialTab.Path then
		--ShowPath
		self.wndPathContent:Show(true)
		self.wndTab 		= self.wndGlobal:FindChild("PathTab")
		self.wndTutorial = self.wndPathContent
		tButtons = self.wndPathContent:FindChild("Buttons"):GetChildren()
		strSelectTitle = Apollo.GetString("Pregame_Select_Path")
		if self.ePath then
			self:HelperPlayMovie()
		end

	elseif self.ePageToShow == keTutorialTab.Customize then
		--ShowCustomize
		self.wndCustomizeContent:Show(true)
		tButtons = {}
		self.wndTab 		= self.wndGlobal:FindChild("CustomizeTab")
		self.wndTutorial = self.wndCustomizeContent
		strSelectTitle = Apollo.GetString("Pregame_Select_Customizations")
		if self.eRace then
			self:FillCustomizePagination()
		end

		--Special logic to check customiztion because it is optional.
		self:HelperHandleCustomized()
		g_nCharCurrentRot = 0

	elseif self.ePageToShow == keTutorialTab.Finalize then
		
		self.wndGlobal:FindChild("ForwardBtn"):Show(false)
		g_controls:Show(true)
		g_controls:FindChild("ExitForm"):Show(false)
		g_controls:FindChild("OptionsContainer"):Show(false)
		self.wndFinalizeContent:Show(true)
		g_controls:FindChild("EnterForm"):Show(true)
		g_controls:FindChild("CharacterNameText"):Show(self.strName ~= "" and self.strName ~= nil)
		self.wndFirstName:Show(true)
		self.wndLastName:Show(true)
		tButtons = {}
		self.wndTab 		= self.wndGlobal:FindChild("FinalizeTab")
		self.wndTutorial = self.wndFinalizeContent
		strSelectTitle = Apollo.GetString("Pregame_Select_Finalize")
		self:HelperSetInfoPane()

		g_nCharCurrentRot = 0
	end

	local bEnableForward  = false
	--Customizations are not necessary, so always enable forward btn.
	if self.ePageToShow == keTutorialTab.Customize then
		bEnableForward = true
	--Finalize page doesn't have a forward btn.
	elseif self.ePageToShow == keTutorialTab.Finalize then
		bEnableForward  = false
	else
		for idx, wndBtnEntry in pairs(tButtons) do
			local wndBtn = wndBtnEntry:FindChild("Btn") --Race Btns have another child called Btn
			if not wndBtn then
				wndBtn = wndBtnEntry
			end
			if wndBtn:IsChecked() then
				bEnableForward = true
				break
			end
		end
	end
	
	self:UpdateCharacterModelAndPosition()
	self:HelperUpdateRaceActors()
	self:HelperEnableForwardBtnWithFlash(bEnableForward)
	self:HelperHandleLights()

	self.wndTab:FindChild("IndicatorBar"):SetSprite("charactercreate:sprCharC_HeaderStepHighlight")
	self.wndSubSection:FindChild("Title"):SetText(strSelectTitle)
end

function Character:HelperEnableForwardBtnWithFlash(bEnable)
	local eCurTab = self.wndTab and self.wndTab:GetData()
	if eCurTab and eCurTab ~= keTutorialTab.Finalize then
		local strHintText = ""
		if eCurTab == keTutorialTab.Experience then
			strHintText = Apollo.GetString("CRB_CC_Info_Race_Information")
		elseif eCurTab == keTutorialTab.Race then
			strHintText = Apollo.GetString("CRB_CC_Info_Class_Information")
		elseif eCurTab == keTutorialTab.Class then
			strHintText = Apollo.GetString("CRB_CC_Info_Path_Information")
		elseif eCurTab == keTutorialTab.Path then
			strHintText = Apollo.GetString("CRB_Customize")
		elseif eCurTab == keTutorialTab.Customize then
			strHintText = Apollo.GetString("CRB_Finalize")
		end
		
		self.wndGlobal:FindChild("HintText"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_Hint"), strHintText))
		self.wndGlobal:FindChild("HintText"):Show(bEnable)
		self.wndGlobal:FindChild("ForwardBtn"):Enable(bEnable)
		self.wndGlobal:FindChild("ForwardBtnFlash"):Show(bEnable)
	else --Was finalize tab
		self.wndGlobal:FindChild("HintText"):Show(false)
		self.wndGlobal:FindChild("ForwardBtn"):Enable(false)
		self.wndGlobal:FindChild("ForwardBtnFlash"):Show(false)
	end
end

function Character:CheckForConflicts(eRace, eClass)
	if not eRace or not eClass then
		return
	end

	local bShowAlert = false

	local strRace  = Apollo.GetString(c_arRaceStrings[eRace].strName)
	local strClass = Apollo.GetString(c_arClassStrings[eClass].strName)

	local tClasses = self.tAvailableClassesForRace[eRace]
	if tClasses then
		if not tClasses[eClass] or not tClasses[eClass].bEnabled then --this race does not support this class
			bShowAlert = true
		end
	end

	if bShowAlert then
		local strMessage = ""
		local eCurTab = self.wndTab:GetData()
		local wndOptionToggles =  self.wndControlFrame:FindChild("OptionToggles")
		if eCurTab == keTutorialTab.Race or eCurTab == keTutorialTab.Finalize and wndOptionToggles:FindChild("RaceOptionToggle:Btn"):IsChecked() then
			strMessage = PreGameLib.String_GetWeaselString(Apollo.GetString("PreGame_ConflictClassDesc"), strRace, strClass)
		end

		self.wndCreationAlert:FindChild("Body"):SetText(strMessage)
		self.wndCreationAlert:Invoke()
	end

	return bShowAlert
end

function Character:OnConfirmClearChoice(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local tData = wndControl:GetData()
	
	--Should deselect currently Selected Class\Race Btn on other tab.
	local eCurTab = self.wndTab:GetData()
	local wndOptionToggles =  self.wndControlFrame:FindChild("OptionToggles")
	if eCurTab == keTutorialTab.Class or eCurTab == keTutorialTab.Finalize and wndOptionToggles:FindChild("ClassOptionToggle:Btn"):IsChecked() then
		local tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Race)
		if tLinkedButtons then
			self:OnRaceBtnUncheck(tLinkedButtons.wndTutorialBtn, tLinkedButtons.wndTutorialBtn) --Automatically unchecks both tutorial and finalize buttons.
		end

		--Finalize the selection of the class!
		local tLinkedButtonsClass = self:HelperGetLinkedBtns(keTutorialTab.Class, tData.idConflict)
		if tLinkedButtonsClass then
			self:OnClassBtnCheck(tLinkedButtonsClass.wndTutorialBtn, tLinkedButtonsClass.wndTutorialBtn) --Automatically checks both tutorial and finalize buttons.
			self.ePageToShow = keTutorialTab.Race --Show the race page because the race selection was cleared.
		end

	elseif eCurTab == keTutorialTab.Race or eCurTab == keTutorialTab.Finalize and wndOptionToggles:FindChild("RaceOptionToggle:Btn"):IsChecked() then
		local tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Class)
		if tLinkedButtons then
			self:OnClassBtnUncheck(tLinkedButtons.wndTutorialBtn, tLinkedButtons.wndTutorialBtn) --Automatically unchecks both tutorial and finalize buttons.
		end

		--Finalize the selection of the race!
		local tLinkedButtonsRace = self:HelperGetLinkedBtns(keTutorialTab.Race, tData.idConflict)
		if tLinkedButtonsRace then
			self:OnRaceBtnCheck(tLinkedButtonsRace.wndTutorialBtn, tLinkedButtonsRace.wndTutorialBtn) --Automatically checks both tutorial and finalize buttons.
			self.ePageToShow = keTutorialTab.Class --Show the class page because the class selection was cleared.
		end

	end

	--Make sure that if there is no longer a valid character to show to clear it.
	self:UpdateCharacterModelAndPosition()
	self:SetConflictWarnings()
	self.wndCreationAlert:Show(false)
	self:ShowCorrectTabPage() --Show the page belonging to the value we just confirmed clearing.
end

function Character:OnConfirmationClosed(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	--Used when cancelling class choice. If the warning window is closed because player is selecting another class button, don't auto select last previous valid class.
	self.bAutoSelectLastValidClass = false
	for idx, wndClassBtn in pairs(self.wndClassContent:FindChild("Buttons"):GetChildren()) do
		if wndClassBtn:ContainsMouse() then
			self.bAutoSelectLastValidClass = true
			break
		end
	end

	local wndCancel = self.wndCreationAlert:FindChild("CancelBtn")
	self:OnCancelChoice(wndCancel, wndCancel)
end

function Character:OnCancelChoice(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local tData = wndControl:GetData()
	if not tData then
		return
	end
	
	local eCurTab = self.wndTab:GetData()
	local wndOptionToggles =  self.wndControlFrame:FindChild("OptionToggles")
	if eCurTab == keTutorialTab.Race or eCurTab == keTutorialTab.Finalize and wndOptionToggles:FindChild("RaceOptionToggle:Btn"):IsChecked() then
		local tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Race, tData.idConflict)
		if tLinkedButtons then
			self:OnRaceBtnUncheck(tLinkedButtons.wndTutorialBtn, tLinkedButtons.wndTutorialBtn) --Automatically unchecks both tutorial and finalize buttons.
		end

		--Select the last valid race btn!
		self.bPreventRandomizeLook = true
		tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Race, tData.idPrevious)
		if tLinkedButtons then
			self:OnRaceBtnCheck(tLinkedButtons.wndTutorialBtn, tLinkedButtons.wndTutorialBtn)
		end
	elseif eCurTab == keTutorialTab.Class or eCurTab == keTutorialTab.Finalize and wndOptionToggles:FindChild("ClassOptionToggle:Btn"):IsChecked() then
		local tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Class, tData.idConflict)
		if tLinkedButtons then
			self:OnClassBtnUncheck(tLinkedButtons.wndTutorialBtn, tLinkedButtons.wndTutorialBtn) --Automatically unchecks both tutorial and finalize buttons.
		end

		--Select the last valid class btn!
		tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Class, tData.idPrevious)
		if not self.bAutoSelectLastValidClass then
			if tLinkedButtons then
				self:OnClassBtnCheck(tLinkedButtons.wndTutorialBtn, tLinkedButtons.wndTutorialBtn)
			end
		end
	end

	--Make sure that if there is no longer a valid character to show to clear it.
	self:UpdateCharacterModelAndPosition()
	self:SetConflictWarnings()
	self.wndCreationAlert:Show(false)
end

function Character:OnConfirmSelectRace(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self.wndCustomizationAlert:Show(false)
	self.ePageToShow = keTutorialTab.Race
	self:ShowCorrectTabPage()
end

function Character:OnExperienceBtnCheck(wndHandler, wndControl, eMouseButton, bDoubleClick)
	if wndHandler ~= wndControl then
		return
	end

	self.eTutorialLevel = wndControl:GetData()
	
	--Deselect the previous race buttons
	if self.tLastSelectedExperienceButtons then
		self.tLastSelectedExperienceButtons.wndTutorialBtn:SetCheck(false)
		self.tLastSelectedExperienceButtons.wndFinalizeBtn:SetCheck(false)
	end

	--Make sure both tutorial and customization race btns are selected.
	local tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Experience)
	if tLinkedButtons then
		tLinkedButtons.wndTutorialBtn:SetCheck(true)
		tLinkedButtons.wndFinalizeBtn:SetCheck(true)
		self.tLastSelectedExperienceButtons = tLinkedButtons
	end

	local strExperience = ""
	if self.eTutorialLevel == PreGameLib.CodeEnumCharacterCreationStart.PreTutorial then
		strExperience = Apollo.GetString("CRB_Tradeskill_Novice")
	elseif self.eTutorialLevel == PreGameLib.CodeEnumCharacterCreationStart.Nexus then
		strExperience = Apollo.GetString("CRB_Veteran")
	elseif self.eTutorialLevel == PreGameLib.CodeEnumCharacterCreationStart.Level50 then
		strExperience = Apollo.GetString("PreGame_Level50")
	end

	local wndExperienceTab = self.wndGlobal:FindChild("ExperienceTab")
	wndExperienceTab:FindChild("Title"):SetText(strExperience)
	wndExperienceTab:FindChild("Icon"):SetSprite(kstrSelectedTabIcon)
	self:HelperEnableForwardBtnWithFlash(true)
	
	local wndExperienceOptionToggle = self.wndControlFrame:FindChild("ExperienceOptionToggle")
	wndExperienceOptionToggle:FindChild("Icon"):Show(false)
	wndExperienceOptionToggle:FindChild("SelectionIcon"):Show(true)
	wndExperienceOptionToggle:FindChild("SelectionIcon"):SetSprite(ktIcons[keTutorialTab.Experience][self.eTutorialLevel])
	wndExperienceOptionToggle:FindChild("Selection"):SetText(strExperience)
	wndExperienceOptionToggle:FindChild("Selection"):SetTextColor(kstrHoloTextColor)
	wndExperienceOptionToggle:SetData(self.eTutorialLevel ~= nil)
	
	Sound.Play(Sound.PlayUIPlayerSelectButton)
	
	if bDoubleClick == true then
		self:StepForwardGuidedTour()
	end
end

function Character:OnExperienceBtnUncheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:HelperEnableForwardBtnWithFlash(false)

	local tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Experience)
	if tLinkedButtons then
		tLinkedButtons.wndTutorialBtn:SetCheck(false)
		tLinkedButtons.wndFinalizeBtn:SetCheck(false)
	end
	
	--Have to be set to nil after getting linked buttons.
	self.eTutorialLevel = nil
	self.bChangedDetailOrSwitchedTab  = true

	local wndExperienceTab = self.wndGlobal:FindChild("ExperienceTab")
	wndExperienceTab:FindChild("Title"):SetText(Apollo.GetString("CombatFloaterType_Experience"))
	wndExperienceTab:FindChild("Icon"):SetSprite(kstrDefaultTabIcon)

	local wndExperienceOptionToggle = self.wndControlFrame:FindChild("ExperienceOptionToggle")
	wndExperienceOptionToggle:FindChild("Icon"):Show(true)
	wndExperienceOptionToggle:FindChild("SelectionIcon"):Show(false)
	wndExperienceOptionToggle:FindChild("SelectionIcon"):SetSprite(kstrFinalizeNotSelected)
	wndExperienceOptionToggle:FindChild("Selection"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_NoSelected"), Apollo.GetString("CRB_Experience")))
	wndExperienceOptionToggle:SetData(self.eTutorialLevel ~= nil)
end

function Character:OnRaceBtnCheck(wndHandler, wndControl, bDoubleClick)
	if wndHandler ~= wndControl then
		return
	end

	--Record Data
	local tRaceData = wndControl:GetData()
	if g_eFactionRestriction ~= nil and g_eFactionRestriction ~= tRaceData.eFaction then
		return
	end
	
	local tComboCheckResult = self:CheckRaceClassCombo(tRaceData.eRace, self.eClass)
	if not tComboCheckResult.bEnabled then
		if tComboCheckResult.bRequiresPurchase and tComboCheckResult.tLinkInfo then
			wndControl:SetCheck(false)
			self.ePendingRace = tRaceData.eRace
			PreGameLib.Event_FireGenericEvent("OpenStoreLinkSingle", tComboCheckResult.tLinkInfo.nOfferGroupId, tComboCheckResult.tLinkInfo.nVariantIndex)
		end

		return
	end
	
	self.ePendingRace = nil

	--Enable the correct class buttons for this race.
	local bConflicts = self:CheckForConflicts(tRaceData.eRace, self.eClass)
	self:HelperEnableForwardBtnWithFlash(not bConflicts)
	if bConflicts == true then
		self.wndCreationAlert:FindChild("ConfirmBtn"):SetData({idConflict = tRaceData.eRace, idPrevious = self.idPreviousRace})
		self.wndCreationAlert:FindChild("CancelBtn"):SetData({idConflict = tRaceData.eRace, idPrevious = self.idPreviousRace})
		return
	end
	
	--This race didn't cause a conflict.
	self.eRace = tRaceData.eRace
	self.idPreviousRace = tRaceData.eRace
	self.eFaction = tRaceData.eFaction
	self.eGender = self.wndCreateFrame:FindChild("FemaleBtn"):IsChecked() and PreGameLib.CodeEnumGender.Female or PreGameLib.CodeEnumGender.Male
	
	local eGenderExternal = self.eGender
	if self.eRace == PreGameLib.CodeEnumRace.Chua then
		eGenderExternal = PreGameLib.CodeEnumGender.Male
	end

	--Record the selected choice's information.
	local strName = c_arRaceStrings[self.eRace].strName
	if g_arActors[strName] and g_arActors[strName][eGenderExternal] then
		local tSelectedActor = g_arActors[strName][eGenderExternal]
		local wndDescription = self.wndRaceContent:FindChild(strName..eGenderExternal):FindChild("Description")
		self.tSelectedAcorInfo = {actor = tSelectedActor, strDisplay = strName, eRace = self.eRace, eGender = eGenderExternal, wndDescription = wndDescription}
	end
	
	self.wndRaceContent:FindChild("DominionBtn"):SetCheck(self.eFaction == PreGameLib.CodeEnumFaction.Dominion)
	self.wndRaceContent:FindChild("ExileBtn"):SetCheck(self.eFaction == PreGameLib.CodeEnumFaction.Exile)

	self.bChangedDetailOrSwitchedTab  = true
	--Show the class conlicats for this race on the class btns.
	self:SetConflictWarnings()

	--Deselect the previous race buttons
	if self.tLastSelectedRaceButtons then
		self.tLastSelectedRaceButtons.wndTutorialBtn:SetCheck(false)
		self.tLastSelectedRaceButtons.wndFinalizeBtn:SetCheck(false)
	end

	--Make sure both tutorial and customization race btns are selected.
	local tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Race)
	if tLinkedButtons then
		tLinkedButtons.wndTutorialBtn:SetCheck(true)
		tLinkedButtons.wndFinalizeBtn:SetCheck(true)
		self.tLastSelectedRaceButtons = tLinkedButtons
	end

	self:UpdateCharacterModelAndPosition()

	--When canceling the selection of a race that causes conflict, keep the same looks.
	if not self.bPreventRandomizeLook then
		self:OnRandomizeCharacterLook()
	end
	self.bPreventRandomizeLook = false

	local strRace = Apollo.GetString(strName)
	local wndRaceOptionToggle = self.wndControlFrame:FindChild("RaceOptionToggle")
	wndRaceOptionToggle:FindChild("Icon"):Show(false)
	wndRaceOptionToggle:FindChild("SelectionIcon"):Show(true)
	wndRaceOptionToggle:FindChild("SelectionIcon"):SetSprite(ktIcons[keTutorialTab.Race][self.eRace][self.eGender])
	wndRaceOptionToggle:FindChild("Selection"):SetText(strRace)
	wndRaceOptionToggle:FindChild("Selection"):SetTextColor(kstrHoloTextColor)
	wndRaceOptionToggle:SetData(self.eRace ~= nil)

	self:HelperSetInfoPane()

	--Set the Race Tab Text to this race
	local wndRaceTab = self.wndGlobal:FindChild("RaceTab")
	wndRaceTab:FindChild("Title"):SetText(strRace)
	wndRaceTab:FindChild("Icon"):SetSprite(kstrSelectedTabIcon)

	self:HelperHandlePointerOppacity()

	--The random name functionality has a race and gender seed so enable.
	g_controls:FindChild("btn_RenameRandom"):Enable(true)
	--Open the correct section in info panel display container.
	self:InfoPanelDisplayContainer(self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Race"))
	Sound.Play(Sound.PlayUIPlayerSelectButton)
	
	if bDoubleClick == true then
		self:StepForwardGuidedTour()
	end
end

function Character:OnRaceBtnUncheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:HelperEnableForwardBtnWithFlash(false)

	--May be called from cancel/confirm choice, so need to get the currently selected button.
	--Make sure both tutorial and customization race btns are deselected.
	local tRaceData = wndControl:GetData()
	local tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Race, tRaceData.eRace)
	if tLinkedButtons then
		tLinkedButtons.wndTutorialBtn:SetCheck(false)
		tLinkedButtons.wndFinalizeBtn:SetCheck(false)
	end

	--Have to be set to nil after getting linked buttons.
	self.eRace = nil
	self.eGender = nil
	self.eFaction = nil
	self.bChangedDetailOrSwitchedTab  = true

	local wndRaceTab = self.wndGlobal:FindChild("RaceTab")
	wndRaceTab:FindChild("Title"):SetText(Apollo.GetString("CRB_Race"))
	wndRaceTab:FindChild("Icon"):SetSprite(kstrDefaultTabIcon)
	
	--Special Logic for customize tab because you can't "Customize" when there is no race.
	self.wndGlobal:FindChild("Header:CustomizeTab:Icon"):SetSprite(kstrDefaultTabIcon)

	g_controls:FindChild("btn_RenameRandom"):Enable(false)
	
	local wndRaceOptionToggle = self.wndControlFrame:FindChild("RaceOptionToggle")
	wndRaceOptionToggle:FindChild("Icon"):Show(true)
	wndRaceOptionToggle:FindChild("SelectionIcon"):Show(false)
	wndRaceOptionToggle:FindChild("SelectionIcon"):SetSprite(kstrFinalizeNotSelected)
	wndRaceOptionToggle:FindChild("Selection"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_NoSelected"), Apollo.GetString("CRB_Race")))
	wndRaceOptionToggle:SetData(self.eRace ~= nil)

	self:UpdateCharacterModelAndPosition()
end

function Character:CheckRaceClassCombo(eRace, eClass)
	local results = { bEnabled = true, bRequiresPurchase = false, tLinkInfo = nil }
	if not eRace or not eClass then
		return results
	end
	
	local tClasses = self.tAvailableClassesForRace[eRace]
	if tClasses then
		if tClasses[eClass] then
			if tClasses[eClass].bEnabled then
				results.bEnabled = true
			elseif tClasses[eClass].nRequiredEntitlementId then
				results.bEnabled = false
				results.bRequiresPurchase = true
				results.tLinkInfo = tClasses[eClass].tLinkInfo
			else
				results.bEnabled = false
			end
		end
	end
	
	return results
end

function Character:OnClassBtnCheck(wndHandler, wndControl, eMouseButton, bDoubleClick)
	if wndHandler ~= wndControl then
		return
	end

	--Record information
	local eClass = wndControl:GetData()
	
	local tComboCheckResult = self:CheckRaceClassCombo(self.eRace, eClass)
	if not tComboCheckResult.bEnabled then
		if tComboCheckResult.bRequiresPurchase and tComboCheckResult.tLinkInfo then
			wndControl:SetCheck(false)
			self.ePendingClass = eClass
			PreGameLib.Event_FireGenericEvent("OpenStoreLinkSingle", tComboCheckResult.tLinkInfo.nOfferGroupId, tComboCheckResult.tLinkInfo.nVariantIndex)
		end

		return
	end
	
	self.ePendingClass = nil

	--Deselect the previous class buttons
	if self.tLastSelectedClassButtons then
		self.tLastSelectedClassButtons.wndTutorialBtn:SetCheck(false)
		self.tLastSelectedClassButtons.wndTutorialBtn:FindChild("LineConnection"):Show(false)
		self.tLastSelectedClassButtons.wndFinalizeBtn:SetCheck(false)
	end
	
	--Make sure both tutorial and customization race btns are selected.
	local tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Class, eClass)
	if tLinkedButtons then
		tLinkedButtons.wndTutorialBtn:SetCheck(true)
		tLinkedButtons.wndTutorialBtn:FindChild("LineConnection"):Show(true)
		tLinkedButtons.wndFinalizeBtn:SetCheck(true)
		self.tLastSelectedClassButtons = tLinkedButtons
	end

	--Enable the correct class buttons for this class.
	local bConflicts = self:CheckForConflicts(self.eRace, eClass)
	self:HelperEnableForwardBtnWithFlash(not bConflicts)
	if bConflicts == true then
		self.wndCreationAlert:FindChild("ConfirmBtn"):SetData({idConflict = eClass, idPrevious = self.idPreviousClass})
		self.wndCreationAlert:FindChild("CancelBtn"):SetData({idConflict = eClass, idPrevious = self.idPreviousClass})
		return
	end

	--This class didn't cause a conflict
	self.eClass = eClass
	self.idPreviousClass = eClass --Used for selecting previous valid class when prompted for invalid class.

	self:HelperPlayMovie()
	
	local wndArchTypeContainer = self.wndClassContent:FindChild("ArchTypeContainer")
	for idx, wndArchType in pairs(wndArchTypeContainer:GetChildren()) do
		wndArchType:Show(false)
	end

	for idx, eArchType in pairs(ktArchTypes[self.eClass]) do
		if eArchType == keArchTypes.RangeDamage then
			wndArchTypeContainer:FindChild("ArchtypeDamage"):Show(true)
			wndArchTypeContainer:FindChild("Title"):SetText(Apollo.GetString("CharacterCreate_Ranged"))
			wndArchTypeContainer:FindChild("icon"):SetSprite("charactercreate:sprCharC_iconArchType_DPS")
		elseif eArchType == keArchTypes.MeleeDamage then
			wndArchTypeContainer:FindChild("ArchtypeDamage"):Show(true)
			wndArchTypeContainer:FindChild("Title"):SetText(Apollo.GetString("CharacterCreate_Melee"))
			wndArchTypeContainer:FindChild("icon"):SetSprite("charactercreate:sprCharC_iconArchType_Melee")
		elseif eArchType == keArchTypes.Healer then
			wndArchTypeContainer:FindChild("ArchtypeHealer"):Show(true)
		elseif eArchType == keArchTypes.Tank then
			wndArchTypeContainer:FindChild("ArchtypeTank"):Show(true)
		end
	end

	self.bChangedDetailOrSwitchedTab  = true
	--Show the race conflicts for this class on the race btns.
	self:SetConflictWarnings()

	local tClassInfo = c_arClassStrings[self.eClass]
	local wndCenterStack = self.wndClassContent:FindChild("CenterStack")
	local wndDescription = wndCenterStack:FindChild("Description")
	wndDescription:FindChild("DescriptionBody"):SetText(Apollo.GetString(tClassInfo.strDescription))
	wndDescription:Show(true)
	wndCenterStack:Show(true)

	local wndClassTab = self.wndGlobal:FindChild("ClassTab")
	wndClassTab:FindChild("Title"):FindChild("Title"):SetText(Apollo.GetString(tClassInfo.strName))
	wndClassTab:FindChild("Icon"):SetSprite(kstrSelectedTabIcon)

	self:StoreCurrentCharacterLook()
	self:UpdateCharacterModelAndPosition()

	--Set the info pane information
	local wndClassOptionToggle = self.wndControlFrame:FindChild("ClassOptionToggle")
	wndClassOptionToggle:FindChild("Icon"):Show(false)
	wndClassOptionToggle:FindChild("SelectionIcon"):Show(true)
	wndClassOptionToggle:FindChild("SelectionIcon"):SetSprite(ktIcons[keTutorialTab.Class][self.eClass])
	wndClassOptionToggle:FindChild("Selection"):SetText(Apollo.GetString(tClassInfo.strName))
	wndClassOptionToggle:FindChild("Selection"):SetTextColor(kstrHoloTextColor)
	wndClassOptionToggle:SetData(self.eClass ~= nil)
	self:HelperSetInfoPane()

	self:InfoPanelDisplayContainer(self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Class"))
	
	self.wndClassContent:FindChild("ClassArmorPreview"):Show(self.eRace ~= nil)
	
	Sound.Play(Sound.PlayUIPlayerSelectButton)

	if bDoubleClick == true then
		self:StepForwardGuidedTour()
	end
end
	
function Character:OnClassBtnUncheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	self:HelperEnableForwardBtnWithFlash(false)

	for idx, wndArchType in pairs(self.wndClassContent:FindChild("ArchTypeContainer"):GetChildren()) do
		wndArchType:Show(false)
	end
	
	--May be called from cancel/confirm choice, so need to get the currently selected button.
	--Make sure both tutorial and customization class btns are deselected.
	local eClass = wndHandler:GetData()
	local tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Class, eClass)
	if tLinkedButtons then
		tLinkedButtons.wndTutorialBtn:SetCheck(false)
		tLinkedButtons.wndTutorialBtn:FindChild("LineConnection"):Show(false)
		tLinkedButtons.wndFinalizeBtn:SetCheck(false)
	end

	self.eClass = nil --Must be set to nil after getting the linked buttons.
	self.bChangedDetailOrSwitchedTab  = true

	local wndClassTab = self.wndGlobal:FindChild("ClassTab")
	wndClassTab:FindChild("Title"):SetText(Apollo.GetString("CRB_Class"))
	wndClassTab:FindChild("Icon"):SetSprite(kstrDefaultTabIcon)

	local wndCenterStack = self.wndClassContent:FindChild("CenterStack")
	local wndDescription = wndCenterStack:FindChild("Description")
	wndDescription:FindChild("DescriptionBody"):SetText("")
	wndDescription:Show(false)
	wndCenterStack:Show(false)

	self.wndClassContent:FindChild("ClassArmorPreview"):Show(false)
	
	local wndClassOptionToggle = self.wndControlFrame:FindChild("ClassOptionToggle")
	wndClassOptionToggle:FindChild("Icon"):Show(true)
	wndClassOptionToggle:FindChild("SelectionIcon"):Show(false)
	wndClassOptionToggle:FindChild("SelectionIcon"):SetSprite(kstrFinalizeNotSelected)
	wndClassOptionToggle:FindChild("Selection"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_NoSelected"), Apollo.GetString("CRB_Class")))
	wndClassOptionToggle:SetData(self.eClass ~= nil)
end

function Character:OnPathBtnCheck(wndHandler, wndControl, eMouseButton, bDoubleClick)
	if wndHandler ~= wndControl then
		return
	end

	self:HelperEnableForwardBtnWithFlash(true)

	--Record information
	self.ePath = wndControl:GetData()
	self.bChangedDetailOrSwitchedTab  = true
			
	--Deselect the previous race buttons
	if self.tLastSelectedPathButtons then
		self.tLastSelectedPathButtons.wndTutorialBtn:SetCheck(false)
		self.tLastSelectedPathButtons.wndTutorialBtn:FindChild("LineConnection"):Show(false)
		self.tLastSelectedPathButtons.wndFinalizeBtn:SetCheck(false)
	end

	--Make sure both tutorial and customization race btns are selected.
	local tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Path)
	if tLinkedButtons then
		tLinkedButtons.wndTutorialBtn:SetCheck(true)
		tLinkedButtons.wndTutorialBtn:FindChild("LineConnection"):Show(true)
		tLinkedButtons.wndFinalizeBtn:SetCheck(true)
		self.tLastSelectedPathButtons = tLinkedButtons
	end

	self:HelperPlayMovie()

	local tPathInfo = c_arPathStrings[self.ePath]
	local wndCenterStack = self.wndPathContent:FindChild("CenterStack")
	local wndDescription = wndCenterStack:FindChild("Description")
	local wndDescriptionBody = wndDescription:FindChild("DescriptionBody")
	wndDescriptionBody:SetAML("<P TextColor=\"UI_TextHoloBodyHighlight\" Align=\"Center\" Font=\"CRB_InterfaceLarge\">" .. Apollo.GetString(tPathInfo.strDescription) .. "</P>")
	wndDescriptionBody:SetHeightToContentHeight()
	local nLeft, nTop, nRight, nBottom = wndDescriptionBody:GetAnchorOffsets()
	wndDescription:FindChild("DescriptionContainer"):SetAnchorOffsets(nLeft - nOffset, nTop - nOffset, nRight + nOffset, nBottom + nOffset)

	wndCenterStack:Show(true)
	wndDescription:Show(true)

	local wndPathTab = self.wndGlobal:FindChild("PathTab")
	wndPathTab:FindChild("Title"):SetText(Apollo.GetString(tPathInfo.strName))
	wndPathTab:FindChild("Icon"):SetSprite(kstrSelectedTabIcon)

	--Set the info pane information
	local wndPathOptionToggle = self.wndControlFrame:FindChild("PathOptionToggle")
	wndPathOptionToggle:FindChild("Icon"):Show(false)
	wndPathOptionToggle:FindChild("SelectionIcon"):Show(true)
	wndPathOptionToggle:FindChild("SelectionIcon"):SetSprite(ktIcons[keTutorialTab.Path][self.ePath])
	wndPathOptionToggle:FindChild("Selection"):SetText(Apollo.GetString(c_arPathStrings[self.ePath].strName))
	wndPathOptionToggle:FindChild("Selection"):SetTextColor(kstrHoloTextColor)
	wndPathOptionToggle:SetData(self.ePath ~= nil)
	self:HelperSetInfoPane()

	self:InfoPanelDisplayContainer(self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Path"))
	Sound.Play(Sound.PlayUIPlayerSelectButton)
	
	if bDoubleClick == true then
		self:StepForwardGuidedTour()
	end
end

function Character:OnPathBtnUncheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:HelperEnableForwardBtnWithFlash(false)

	--Deselect the previous race buttons
	if self.tLastSelectedPathButtons then
		self.tLastSelectedPathButtons.wndTutorialBtn:SetCheck(false)
		self.tLastSelectedPathButtons.wndTutorialBtn:FindChild("LineConnection"):Show(false)
		self.tLastSelectedPathButtons.wndFinalizeBtn:SetCheck(false)
		self.tLastSelectedPathButtons = nil
	end

	self.ePath = nil
	self.bChangedDetailOrSwitchedTab  = true

	local wndPathTab = self.wndGlobal:FindChild("PathTab")
	wndPathTab:FindChild("Title"):SetText(Apollo.GetString("CRB_Path"))
	wndPathTab:FindChild("Icon"):SetSprite(kstrDefaultTabIcon)

	local wndCenterStack = self.wndPathContent:FindChild("CenterStack")
	local wndDescription = wndCenterStack:FindChild("Description")
	wndDescription:FindChild("DescriptionBody"):SetText("")
	wndDescription:Show(false)
	wndCenterStack:Show(false)
	
	local wndPathOptionToggle = self.wndControlFrame:FindChild("PathOptionToggle")
	wndPathOptionToggle:FindChild("Icon"):Show(true)
	wndPathOptionToggle:FindChild("SelectionIcon"):Show(false)
	wndPathOptionToggle:FindChild("SelectionIcon"):SetSprite(kstrFinalizeNotSelected)
	wndPathOptionToggle:FindChild("Selection"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_NoSelected"), Apollo.GetString("CRB_Path")))
	wndPathOptionToggle:SetData(self.ePath ~= nil)
end

function Character:OnToggleGender(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local bMale = wndControl:GetData() == PreGameLib.CodeEnumGender.Male

	self.wndCreateFrame:FindChild("MaleBtn"):SetCheck(bMale)
	self.wndCreateFrame:FindChild("FemaleBtn"):SetCheck(not bMale)

	self.wndRacePicker:FindChild("MaleBtn"):SetCheck(bMale)
	self.wndRacePicker:FindChild("FemaleBtn"):SetCheck(not bMale)

	--Tutorial btns
	local wndButtons = self.wndCreateFrame:FindChild("Buttons")
	wndButtons:FindChild("GranokContent:Btn"):ChangeArt(bMale and "btnCharC_RaceSelection_MGranok" or "btnCharC_RaceSelection_FGranok")
	wndButtons:FindChild("MordeshContent:Btn"):ChangeArt(bMale and "btnCharC_RaceSelection_MMordesh" or "btnCharC_RaceSelection_FMordesh")
	wndButtons:FindChild("HumanContent:Btn"):ChangeArt(bMale and "btnCharC_RaceSelection_MExile" or "btnCharC_RaceSelection_FExile")
	wndButtons:FindChild("AurinContent:Btn"):ChangeArt(bMale and "btnCharC_RaceSelection_MAurin" or "btnCharC_RaceSelection_FAurin")
	wndButtons:FindChild("MechariContent:Btn"):ChangeArt(bMale and "btnCharC_RaceSelection_MMechari" or "btnCharC_RaceSelection_FMechari")
	wndButtons:FindChild("DrakenContent:Btn"):ChangeArt(bMale and "btnCharC_RaceSelection_MDraken" or "btnCharC_RaceSelection_FDraken")
	wndButtons:FindChild("CassianContent:Btn"):ChangeArt(bMale and "btnCharC_RaceSelection_MDom" or "btnCharC_RaceSelection_FDom")

	--Customization btns
	wndButtons = self.wndRacePicker:FindChild("Buttons")
	wndButtons:FindChild("Granok:Btn:RaceIcon"):SetSprite(bMale and "charactercreate:sprCharC_Finalize_RaceGranokM" or "charactercreate:sprCharC_Finalize_RaceGranokF")
	wndButtons:FindChild("Mordesh:Btn:RaceIcon"):SetSprite(bMale and "charactercreate:sprCharC_Finalize_RaceMordeshM" or "charactercreate:sprCharC_Finalize_RaceMordeshF")
	wndButtons:FindChild("Human:Btn:RaceIcon"):SetSprite(bMale and "charactercreate:sprCharC_Finalize_RaceExileM" or "charactercreate:sprCharC_Finalize_RaceExileF")
	wndButtons:FindChild("Aurin:Btn:RaceIcon"):SetSprite(bMale and "charactercreate:sprCharC_Finalize_RaceAurinM" or "charactercreate:sprCharC_Finalize_RaceAurinF")
	wndButtons:FindChild("Mechari:Btn:RaceIcon"):SetSprite(bMale and "charactercreate:sprCharC_Finalize_RaceMechariM" or "charactercreate:sprCharC_Finalize_RaceMechariF")
	wndButtons:FindChild("Draken:Btn:RaceIcon"):SetSprite(bMale and "charactercreate:sprCharC_Finalize_RaceDrakenM" or "charactercreate:sprCharC_Finalize_RaceDrakenF")
	wndButtons:FindChild("Cassian:Btn:RaceIcon"):SetSprite(bMale and "charactercreate:sprCharC_Finalize_RaceDomM" or "charactercreate:sprCharC_Finalize_RaceDomF")

	if self.ePageToShow == keTutorialTab.Race then
		self:ShowRaceActors()
	end
	
	if self.tSelectedAcorInfo then
		local eGenderExternal = bMale and PreGameLib.CodeEnumGender.Male or PreGameLib.CodeEnumGender.Female
		if self.tSelectedAcorInfo.eRace == PreGameLib.CodeEnumRace.Chua then
			eGenderExternal = PreGameLib.CodeEnumGender.Male
		end
				
		self:OnActorClicked(g_arActors[self.tSelectedAcorInfo.strDisplay][eGenderExternal])
	end
end

function Character:OnToggleFaction(wndHandler, wndControl)
	local tLinkedButtons = self:HelperGetLinkedBtns(keTutorialTab.Race)
	if tLinkedButtons then
		self:OnRaceBtnUncheck(tLinkedButtons.wndTutorialBtn, tLinkedButtons.wndTutorialBtn) --Automatically unchecks both tutorial and finalize buttons.
	end
	
	if self.tSelectedAcorInfo then
		self.tSelectedAcorInfo.wndDescription:Show(false)
	end
	self.tSelectedAcorInfo = nil
	self:HelperHandleLights()
	self:HelperHandlePointerOppacity()

	self:UpdateCharacterModelAndPosition()
end

function Character:HelperHandleLights()
	if self.ePageToShow == keTutorialTab.Race then
		local bDominionChecked = self.wndRaceContent:FindChild("DominionBtn"):IsChecked()
		local bExileChecked = self.wndRaceContent:FindChild("ExileBtn"):IsChecked()
		
		if not bDominionChecked and not bExileChecked then --Initially opening character create.
			g_arActors.dominionLight:Animate(0, PreGameLib.CodeEnumModelSequence.APState1Idle, 0, true, false)
			g_arActors.exileLight:Animate(0, PreGameLib.CodeEnumModelSequence.APState1Idle, 0, true, false)
		else --One of the Faction btns was selected.
			g_arActors.dominionLight:Animate(0, bDominionChecked and PreGameLib.CodeEnumModelSequence.APState1Idle or PreGameLib.CodeEnumModelSequence.APState0Idle, 0, true, false)
			g_arActors.exileLight:Animate(0, bExileChecked and PreGameLib.CodeEnumModelSequence.APState1Idle or PreGameLib.CodeEnumModelSequence.APState0Idle, 0, true, false)
		end
			g_arActors.selectedRaceLight:FollowActor(self.tSelectedAcorInfo and self.tSelectedAcorInfo.actor, PreGameLib.CodeEnumModelAttachment.Head) --If no actor the light isn't following anything.
			g_arActors.selectedRaceLight:Animate(0, (self.tSelectedAcorInfo and self.tSelectedAcorInfo.actor) and PreGameLib.CodeEnumModelSequence.APState0Idle or PreGameLib.CodeEnumModelSequence.APState1Idle, 0, true, false)
	else --Turn off all lights
		g_arActors.dominionLight:Animate(0, PreGameLib.CodeEnumModelSequence.APState0Idle, 0, true, false)
		g_arActors.exileLight:Animate(0, PreGameLib.CodeEnumModelSequence.APState0Idle, 0, true, false)
		g_arActors.selectedRaceLight:Animate(0, PreGameLib.CodeEnumModelSequence.APState0Idle, 0, true, false)
	end
	
end

function Character:HelperHandlePointerOppacity(bForceShow)
	local bDominionSelected = self.wndRaceContent:FindChild("DominionBtn"):IsChecked()
	for idx, wndPointer in pairs(self.tPointers.tDominionPointers) do
		wndPointer:SetOpacity((bForceShow or bDominionSelected) and 1 or 0.25, 5)
	end

	for idx, wndPointer in pairs(self.tPointers.tExilePointers) do
		wndPointer:SetOpacity((bForceShow or not bDominionSelected) and 1 or 0.25, 5)
	end
end

function Character:SetupAllRaceActors()
	self:CleanupAllRaceActors()

	
	self.tPointers = {
		tDominionPointers = {},
		tExilePointers = {},
	}

	for eFaction, tFactions in pairs(ktFactionRaceDisplayInfo) do
		for eGender, tGenderInfo in pairs(tFactions) do
			for eRace, tDisplayInfo in pairs(tGenderInfo) do
				local eGenderExternal = eGender
				if eRace == PreGameLib.CodeEnumRace.Chua then
					eGenderExternal = PreGameLib.CodeEnumGender.Male
				end

				local eRaceExternal = eRace == k_idCassian and PreGameLib.CodeEnumRace.Human or eRace
				local actorCur = g_scene:AddActorByRaceGenderClass(tDisplayInfo.nUnitId, eRaceExternal, eGenderExternal, 0)
				
				actorCur:SetFaction(eFaction)
				actorCur:FollowActor( g_arActors.mainScene, PreGameLib.CodeEnumModelAttachment.FXMisc07) --Hide the created actors
				self:HelperSetDefaultFactionCostume(eFaction, actorCur)
				actorCur:SetMouseInteraction(true)
				if not g_arActors[tDisplayInfo.strDisplay] then
					g_arActors[tDisplayInfo.strDisplay] = {}
				end
				actorCur:Animate(0, c_factionPlayerAnimation[eFaction], 0, true, false)
				actorCur:SetHighlightColor(kcrModelColor)
				g_arActors[tDisplayInfo.strDisplay][eGenderExternal] = actorCur
				
				local wndPointer = self:PlacePointer(eFaction, eGenderExternal, eRace, tDisplayInfo)
				table.insert(eFaction == PreGameLib.CodeEnumFaction.Dominion and self.tPointers.tDominionPointers or self.tPointers.tExilePointers, wndPointer)
			end
		end
	end
	
	self.bLoadedActors  = true
end

function Character:PlacePointer(eFaction, eGender, eRace, tDisplayInfo)
	local wndContainer = self.wndRaceContent:FindChild("Container")
	--Clear out old pointers if there were any.
	local wndPointer = wndContainer:FindChild(tDisplayInfo.strDisplay..eGender)
	if wndPointer then
		wndPointer:Destroy()
	end

	local wndPointer = Apollo.LoadForm(self.xmlDoc, tDisplayInfo.strForm, wndContainer, self)
	wndPointer:SetName(tDisplayInfo.strDisplay..eGender)
	
	--Attaching the pointer to the actor.
	wndPointer:SetUnit(g_arActors[tDisplayInfo.strDisplay][eGender], PreGameLib.CodeEnumModelAttachment.SpellMisc01)

	local tPixie = wndPointer:GetPixieInfo(2)
	tPixie.strText = Apollo.GetString(tDisplayInfo.strDisplay)
	wndPointer:UpdatePixie(2, tPixie)
	
	-- Description
	local wndDescription = wndPointer:FindChild("Description")
	local wndRaceDetails = wndPointer:FindChild("RaceDetails")
	local wndClassDetails = wndPointer:FindChild("ClassDetails")

	--Setting the Race Description
	
	local strTooltipFormat = "<P Font=\"CRB_Interface9\" TextColor=\"UI_TextHoloBodyCyan\">%s</P>"
	wndRaceDetails:SetAML(string.format(strTooltipFormat, Apollo.GetString(c_arRaceStrings[eRace].strDescription.."_Short")))

	--Need to show all Classes this Race can be. They need to appear alphabetically.
	local tClassesSorted = {}
	local tClasses = self.tAvailableClassesForRace[eRace]
	for eClass, tClassStatus in pairs(tClasses) do
		local strClassName = ""
		if tClassStatus.bEnabled then
			strClassName = Apollo.GetString(c_arClassStrings[eClass].strName)
		elseif tClassStatus.nRequiredEntitlementId then
			strClassName = PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_ClassAvailableForPurchase"), Apollo.GetString(c_arClassStrings[eClass].strName))
		end
		
		if strClassName then
			table.insert(tClassesSorted, {strClass = strClassName, strColor = c_arClassStrings[eClass].strTextColor})
		end
	end

	table.sort(tClassesSorted, function(a,b) return a.strClass < b.strClass end)

	local strAML = "<P Font=\"CRB_Interface9\" TextColor=\"UI_TextHoloBodyCyan\">"..Apollo.GetString("Pregame_Character_AvailableClasses").."</P>"
	for idx, tClass in pairs(tClassesSorted) do
		strAML = strAML .. string.format("<P Font=\"CRB_Interface9\" TextColor=\'%s'\>%s</P>", tClass.strColor, tClass.strClass)
	end

	wndClassDetails:SetAML(strAML)
	wndRaceDetails:SetHeightToContentHeight()
	wndClassDetails:SetHeightToContentHeight()

	local nLeft, nTop, nRight, nBottom = wndClassDetails:GetAnchorOffsets()
	local nClassBottom = wndRaceDetails:GetHeight() + wndClassDetails:GetHeight() + self.nSeperatorPadding + knDesignerPaddingBottom
	wndClassDetails:SetAnchorOffsets(nLeft, wndRaceDetails:GetHeight() + self.nSeperatorPadding, nRight, nClassBottom)

	local nLeft, nTop, nRight, nBottom = wndDescription:GetAnchorOffsets()
	wndDescription:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nClassBottom )
	
	return wndPointer
end

function Character:CleanupAllRaceActors()
	--Remove the buttons associated, then remove the actors.
	for eFaction, tFactions in pairs(ktFactionRaceDisplayInfo) do
		for eGender, tGenderInfo in pairs(tFactions) do
			for eRace, tDisplayInfo in pairs(tGenderInfo) do
				local wndDisplay = self.wndRaceContent:FindChild("Container"):FindChild(tDisplayInfo.strDisplay..eGender)
				if wndDisplay ~= nil then
					wndDisplay:Destroy()
				end
				
				local actorCur = g_arActors[tDisplayInfo.strDisplay] and g_arActors[tDisplayInfo.strDisplay][eGender] or nil
				if actorCur then
					actorCur:Remove()
				end
			end
		end
	end
	
	--Now delete the references
	for eFaction, tFactions in pairs(ktFactionRaceDisplayInfo) do
		for eGender, tGenderInfo in pairs(tFactions) do
			for eRace, tDisplayInfo in pairs(tGenderInfo) do
				if  g_arActors[tDisplayInfo.strDisplay] ~= nil then
					 g_arActors[tDisplayInfo.strDisplay] = nil
				end
			end
		end
	end
end

function Character:HideAllRaceActors()
	for eFaction, tFactions in pairs(ktFactionRaceDisplayInfo) do
		for eGender, tGenderInfo in pairs(tFactions) do
			for eRace, tDisplayInfo in pairs(tGenderInfo) do
				local actorCur = g_arActors[tDisplayInfo.strDisplay] and g_arActors[tDisplayInfo.strDisplay][eGender] or nil
				if actorCur then
					actorCur:FollowActor( g_arActors.mainScene, PreGameLib.CodeEnumModelAttachment.FXMisc07)
				end
			end
		end
	end
end

function Character:ShowRaceActors()
	local eGenderToShow = self.wndRacePicker:FindChild("MaleBtn"):IsChecked() and PreGameLib.CodeEnumGender.Male or PreGameLib.CodeEnumGender.Female
	for eFaction, tFactions in pairs(ktFactionRaceDisplayInfo) do
		for eGender, tGenderInfo in pairs(tFactions) do
			for eRace, tDisplayInfo in pairs(tGenderInfo) do

				local eGenderExternal = eGender
				if eRace == PreGameLib.CodeEnumRace.Chua then
					eGenderExternal = PreGameLib.CodeEnumGender.Male
				end

				local actorCur = g_arActors[tDisplayInfo.strDisplay] and g_arActors[tDisplayInfo.strDisplay][eGenderExternal] or nil
				if actorCur then
					if eGender == eGenderToShow or eRace == PreGameLib.CodeEnumRace.Chua then
						actorCur:FollowActor(g_arActors.mainScene, tDisplayInfo.eSceneAttachPoint) --This attaches to their base points.
					else
						actorCur:FollowActor( g_arActors.mainScene, PreGameLib.CodeEnumModelAttachment.FXMisc07) --Hide the race actors.
					end
				end
			end
		end
	end
end

--Initial Setup of Race Actors occurs when begining Character Creation.
function Character:HelperUpdateRaceActors()
	if self.ePageToShow == keTutorialTab.Race then
		self:ShowRaceActors()
	else
		self:HideAllRaceActors()
	end
end

function Character:OnRaceBtnEnter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	local tRaceData = wndControl:GetData()
	local wndRaceContent = wndControl
	local wndDescription = wndRaceContent:FindChild("Description")
	local wndRaceDetails = wndRaceContent:FindChild("RaceDetails")
	local wndClassDetails = wndRaceContent:FindChild("ClassDetails")

	--Setting the Race Description
	
	local strTooltipFormat = "<P Font=\"CRB_Interface9\" TextColor=\"UI_TextHoloBodyCyan\">%s</P>"
	wndRaceDetails:SetAML(
		string.format(strTooltipFormat, Apollo.GetString(c_arRaceStrings[tRaceData.eRace].strDescription.."_Short"))
		.. "<P TextColor=\"00ffffff\">.</P>" ..
		string.format(strTooltipFormat, Apollo.GetString(c_arFactionStrings[tRaceData.eFaction]))
	)

	--Need to show all Classes this Race can be. They need to appear alphabetically.
	local tClassesSorted = {}
	local tClasses = self.tAvailableClassesForRace[tRaceData.eRace]
	for eClass, tClassStatus in pairs(tClasses) do
		table.insert(tClassesSorted, {strClass = Apollo.GetString(c_arClassStrings[eClass].strName), strColor = c_arClassStrings[eClass].strTextColor})
	end

	table.sort(tClassesSorted, function(a,b) return a.strClass < b.strClass end)

	local strAML = "<P Font=\"CRB_Interface9\" TextColor=\"UI_TextHoloBodyCyan\">"..Apollo.GetString("Pregame_Character_Availableclasses").."</P>"
	for idx, tClass in pairs(tClassesSorted) do
		strAML = strAML .. string.format("<P Font=\"CRB_Interface9\" TextColor=\'%s'\>%s</P>", tClass.strColor, tClass.strClass)
	end

	wndClassDetails:SetAML(strAML)
	wndRaceDetails:SetHeightToContentHeight()
	wndClassDetails:SetHeightToContentHeight()

	local nLeft, nTop, nRight, nBottom = wndClassDetails:GetAnchorOffsets()
	local nClassBottom = wndRaceDetails:GetHeight() + wndClassDetails:GetHeight() + self.nSeperatorPadding + knDesignerPaddingBottom
	wndClassDetails:SetAnchorOffsets(nLeft, wndRaceDetails:GetHeight() + self.nSeperatorPadding, nRight, nClassBottom)

	local nLeft, nTop, nRight, nBottom = wndDescription:GetAnchorOffsets()
	wndDescription:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nClassBottom )
	wndDescription:Show(true)
end

function Character:OnRaceBtnExit(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	
	wndControl:GetParent():FindChild("Description"):Show(false)
end

function Character:HelperPlayMovie()
	local wndContent = self.ePageToShow == keTutorialTab.Class and self.wndClassContent or self.wndPathContent
	local tVideos = self.ePageToShow == keTutorialTab.Class and c_arClassVideos or c_arPathVideos
	local idMovie = nil
	for idx, wndClassBtn in pairs(wndContent:FindChild("Buttons"):GetChildren()) do
		if Window.is(wndClassBtn) then -- If it's actually a window then get the Btn
			wndClassBtn = wndClassBtn:FindChild("Btn")
		end
		if wndClassBtn:IsChecked() then
			idMovie = wndClassBtn:GetData()
			break
		end
	end

	if idMovie and tVideos[idMovie] ~= nil then
		local wndCenterStack = wndContent:FindChild("CenterStack")
		wndCenterStack:Show(true)
		
		local wndMovie = wndCenterStack:FindChild("Movie")
		wndMovie:SetMovie(tVideos[idMovie].strName)
		wndMovie:Play()
	end
end

function Character:HelperStopMovie()
	local wndContent = self.ePageToShow == keTutorialTab.Class and self.wndClassContent or self.wndPathContent
	if wndContent then
		local wndMovie = wndContent:FindChild("CenterStack:VideoContainer:Movie")
		wndMovie:Finish()
	end
end
---------------------------------------------------------------------------------------------------
-- Character Race/Class/Gender/Path Select
---------------------------------------------------------------------------------------------------
function Character:SetAllOptionData()
	--Setting Tab Data
	local wndTabs = self.wndCreateFrame:FindChild("Header")
	wndTabs:FindChild("ExperienceTab"):SetData(keTutorialTab.Experience)
	wndTabs:FindChild("RaceTab"):SetData(keTutorialTab.Race)
	wndTabs:FindChild("ClassTab"):SetData(keTutorialTab.Class)
	wndTabs:FindChild("PathTab"):SetData(keTutorialTab.Path)
	wndTabs:FindChild("CustomizeTab"):SetData(keTutorialTab.Customize)
	wndTabs:FindChild("FinalizeTab"):SetData(keTutorialTab.Finalize)

	--Setting Experience Data
	local wndBtns = self.wndCreateFrame:FindChild("ButtonContainer")
	wndBtns:FindChild("NoviceBtn"):SetData(PreGameLib.CodeEnumCharacterCreationStart.PreTutorial)
	wndBtns:FindChild("ExpertBtn"):SetData(PreGameLib.CodeEnumCharacterCreationStart.Nexus)
	wndBtns:FindChild("Level50Btn"):SetData(PreGameLib.CodeEnumCharacterCreationStart.Level50)
	
	for idx, wndTutorialExperienceBtn in pairs(wndBtns:GetChildren()) do
		self:HelperLinkTutorialWithCustomization(keTutorialTab.Experience, wndTutorialExperienceBtn:GetData(), wndTutorialExperienceBtn, nil)
	end
	
	local wndBtns = self.wndCreateFrame:FindChild("ExperienceSelectionAssets")
	wndBtns:FindChild("NoviceEntry:ExperienceBtn"):SetData(PreGameLib.CodeEnumCharacterCreationStart.PreTutorial)
	wndBtns:FindChild("ExperiencedEntry:ExperienceBtn"):SetData(PreGameLib.CodeEnumCharacterCreationStart.Nexus)
	wndBtns:FindChild("Level50Entry:ExperienceBtn"):SetData(PreGameLib.CodeEnumCharacterCreationStart.Level50)
	
	for idx, wndFinalizeExperienceEntry in pairs(wndBtns:GetChildren()) do
		local wndExperienceBtn = wndFinalizeExperienceEntry:FindChild("ExperienceBtn")
		self:HelperLinkTutorialWithCustomization(keTutorialTab.Experience, wndExperienceBtn:GetData(), nil, wndExperienceBtn)
	end

	--Setting Race Button Data
	--Tutorial Race Buttons
	wndBtns = self.wndRaceContent:FindChild("Buttons")
	wndBtns:FindChild("GranokContent:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Granok, eFaction = PreGameLib.CodeEnumFaction.Exile})
	wndBtns:FindChild("MordeshContent:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Mordesh, eFaction = PreGameLib.CodeEnumFaction.Exile})
	wndBtns:FindChild("HumanContent:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Human, eFaction = PreGameLib.CodeEnumFaction.Exile})
	wndBtns:FindChild("AurinContent:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Aurin, eFaction = PreGameLib.CodeEnumFaction.Exile})
	wndBtns:FindChild("MechariContent:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Mechari, eFaction = PreGameLib.CodeEnumFaction.Dominion})
	wndBtns:FindChild("DrakenContent:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Draken, eFaction = PreGameLib.CodeEnumFaction.Dominion})
	wndBtns:FindChild("CassianContent:Btn"):SetData({eRace = k_idCassian, eFaction = PreGameLib.CodeEnumFaction.Dominion})
	wndBtns:FindChild("ChuaContent:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Chua, eFaction = PreGameLib.CodeEnumFaction.Dominion})


	for idx, wndRaceContent in pairs(wndBtns:GetChildren()) do
		local wndTutorialRaceBtn = wndRaceContent:FindChild("Btn")
		self:HelperLinkTutorialWithCustomization(keTutorialTab.Race, wndTutorialRaceBtn:GetData().eRace, wndTutorialRaceBtn, nil)
	end

	--Customize Race Btns
	wndBtns = self.wndRacePicker:FindChild("Buttons")
	wndBtns:FindChild("Granok:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Granok, eFaction = PreGameLib.CodeEnumFaction.Exile})
	wndBtns:FindChild("Mordesh:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Mordesh, eFaction = PreGameLib.CodeEnumFaction.Exile})
	wndBtns:FindChild("Human:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Human, eFaction = PreGameLib.CodeEnumFaction.Exile})
	wndBtns:FindChild("Aurin:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Aurin, eFaction = PreGameLib.CodeEnumFaction.Exile})
	wndBtns:FindChild("Mechari:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Mechari, eFaction = PreGameLib.CodeEnumFaction.Dominion})
	wndBtns:FindChild("Draken:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Draken, eFaction = PreGameLib.CodeEnumFaction.Dominion})
	wndBtns:FindChild("Cassian:Btn"):SetData({eRace = k_idCassian, eFaction = PreGameLib.CodeEnumFaction.Dominion})
	wndBtns:FindChild("Chua:Btn"):SetData({eRace = PreGameLib.CodeEnumRace.Chua, eFaction = PreGameLib.CodeEnumFaction.Dominion})

	for idx, wndFinalizeRaceBtn in pairs(wndBtns:GetChildren()) do
		local wndRaceBtn = wndFinalizeRaceBtn:FindChild("Btn")
		self:HelperLinkTutorialWithCustomization(keTutorialTab.Race, wndRaceBtn:GetData().eRace, nil, wndRaceBtn)
	end

	--Setting Class Button Data
	wndBtns = self.wndClassContent:FindChild("Buttons")
	wndBtns:FindChild("EngineerContainer:Btn"):SetData(PreGameLib.CodeEnumClass.Engineer)
	wndBtns:FindChild("EsperContainer:Btn"):SetData(PreGameLib.CodeEnumClass.Esper)
	wndBtns:FindChild("MedicContainer:Btn"):SetData(PreGameLib.CodeEnumClass.Medic)
	wndBtns:FindChild("SpellslingerContainer:Btn"):SetData(PreGameLib.CodeEnumClass.Spellslinger)
	wndBtns:FindChild("StalkerContainer:Btn"):SetData(PreGameLib.CodeEnumClass.Stalker)
	wndBtns:FindChild("WarriorContainer:Btn"):SetData(PreGameLib.CodeEnumClass.Warrior)

	for idx, wndClassContainer in pairs(wndBtns:GetChildren()) do
		local wndClassBtn = wndClassContainer:FindChild("Btn")
		self:HelperLinkTutorialWithCustomization(keTutorialTab.Class, wndClassBtn:GetData(), wndClassBtn, nil)
	end

	wndBtns = self.wndClassPicker:FindChild("ClassSelectList")
	wndBtns:FindChild("Engineer:ClassBtn"):SetData(PreGameLib.CodeEnumClass.Engineer)
	wndBtns:FindChild("Esper:ClassBtn"):SetData(PreGameLib.CodeEnumClass.Esper)
	wndBtns:FindChild("Medic:ClassBtn"):SetData(PreGameLib.CodeEnumClass.Medic)
	wndBtns:FindChild("Spellslinger:ClassBtn"):SetData(PreGameLib.CodeEnumClass.Spellslinger)
	wndBtns:FindChild("Stalker:ClassBtn"):SetData(PreGameLib.CodeEnumClass.Stalker)
	wndBtns:FindChild("Warrior:ClassBtn"):SetData(PreGameLib.CodeEnumClass.Warrior)

	for idx, wndCustomizeClass in pairs(wndBtns:GetChildren()) do
		local wndClassBtn = wndCustomizeClass:FindChild("ClassBtn")
		self:HelperLinkTutorialWithCustomization(keTutorialTab.Class, wndClassBtn:GetData(), nil, wndClassBtn)
	end

	--Setting Path ButtonData
	wndBtns = self.wndPathContent:FindChild("Buttons")
	wndBtns:FindChild("btn_Explorer"):SetData(PreGameLib.CodeEnumPlayerPathType.Explorer)
	wndBtns:FindChild("btn_Scientist"):SetData(PreGameLib.CodeEnumPlayerPathType.Scientist)
	wndBtns:FindChild("btn_Settler"):SetData(PreGameLib.CodeEnumPlayerPathType.Settler)
	wndBtns:FindChild("btn_Soldier"):SetData(PreGameLib.CodeEnumPlayerPathType.Soldier)

	for idx, wndTutorialClassBtn in pairs(self.wndPathContent:FindChild("Buttons"):GetChildren()) do
		self:HelperLinkTutorialWithCustomization(keTutorialTab.Path, wndTutorialClassBtn:GetData(), wndTutorialClassBtn, nil)
	end

	local arPaths = CharacterScreenLib.GetPlayerPaths()
	for idx = 1,#arPaths do
		local wndCustomizationBtn = self.wndPathPicker:FindChild("PathBtn" .. idx)
		wndCustomizationBtn:SetData(arPaths[idx].path)
		self:HelperLinkTutorialWithCustomization(keTutorialTab.Path, arPaths[idx].path, nil, wndCustomizationBtn)
	end

	--Setting Gender Data
	self.wndRaceContent:FindChild("MaleBtn"):SetData(PreGameLib.CodeEnumGender.Male)
	self.wndRaceContent:FindChild("FemaleBtn"):SetData(PreGameLib.CodeEnumGender.Female)
	self.wndRacePicker:FindChild("MaleBtn"):SetData(PreGameLib.CodeEnumGender.Male)
	self.wndRacePicker:FindChild("FemaleBtn"):SetData(PreGameLib.CodeEnumGender.Female)
	
	--Setting Faction Data
	self.wndRaceContent:FindChild("DominionBtn"):SetData(PreGameLib.CodeEnumFaction.Dominion)
	self.wndRaceContent:FindChild("ExileBtn"):SetData(PreGameLib.CodeEnumFaction.Exile)

	wndBtns 	= self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Class")
	wndBtns:FindChild("EarlyPreview"):SetData(keArmorPreview.Early)
	wndBtns:FindChild("MidPreview"):SetData(keArmorPreview.Mid)
	wndBtns:FindChild("LatePreview"):SetData(keArmorPreview.Late)
	
	wndBtns 	= self.wndClassContent:FindChild("PreviewButtonContainer")
	wndBtns:FindChild("EarlyPreview"):SetData(keArmorPreview.Early)
	wndBtns:FindChild("MidPreview"):SetData(keArmorPreview.Mid)
	wndBtns:FindChild("LatePreview"):SetData(keArmorPreview.Late)
	
	--Setting customization presets.
	wndBtns 	= self.wndCustomizeContent:FindChild("CustomizeControlFrame")
	wndBtns:FindChild("FirstPreset"):SetData({strEvent = "OnPresetBtn", ePreset = keCustomizationPreset.First})
	wndBtns:FindChild("SecondPreset"):SetData({strEvent = "OnPresetBtn", ePreset = keCustomizationPreset.Second})
	wndBtns:FindChild("RandomizeBtn"):SetData({strEvent = "OnRandomizeCharacterLook"})
end

function Character:HelperLinkTutorialWithCustomization(eTabType, eEntryType, wndTutorialBtn, wndFinalizeBtn)
	if not self.tTutorialAndCustomizationLink then
		self.tTutorialAndCustomizationLink =
		{
			[keTutorialTab.Experience] = {},
			[keTutorialTab.Race] = {},
			[keTutorialTab.Class] = {},
			[keTutorialTab.Path] = {},
		}
	end

	local tEntryInfo = self.tTutorialAndCustomizationLink[eTabType][eEntryType]
	if not tEntryInfo then
		tEntryInfo = {}
		self.tTutorialAndCustomizationLink[eTabType][eEntryType] = tEntryInfo
	end

	--Linking the tutorial btn.
	if wndTutorialBtn then
		tEntryInfo.wndTutorialBtn = wndTutorialBtn
	end

	--Linking the customization btn.
	if wndFinalizeBtn then
		tEntryInfo.wndFinalizeBtn = wndFinalizeBtn
	end

end

--Get the customization and tutorial buttons for each tab type and race type.
--If no eEntryType, use a default.
function Character:HelperGetLinkedBtns(eTabType, eEntryType)
	if not eEntryType then
		if eTabType == keTutorialTab.Experience then
			eEntryType = self.eTutorialLevel
		elseif eTabType == keTutorialTab.Race then
			eEntryType = self.eRace
		elseif eTabType == keTutorialTab.Class then
			eEntryType = self.eClass
		elseif eTabType == keTutorialTab.Path then
			eEntryType = self.ePath
		end
	end
	
	--If couldn't determine the correct eTabType then just return nil
	return eEntryType and self.tTutorialAndCustomizationLink[eTabType][eEntryType] or nil
end
---------------------------------------------------------------------------------------------------
function Character:HelperLoadClassAndRaceRelations()
	self.tAvailableClassesForRace = {}
	self.tAvailableRacesForClass = {}

	for idx, tCreation in pairs(self.arCharacterCreateOptions) do
		local eRaceInteral = tCreation.raceId == PreGameLib.CodeEnumRace.Human and tCreation.factionId == PreGameLib.CodeEnumFaction.Dominion and k_idCassian or tCreation.raceId 

		--Record all available races.
		if not self.tAvailableClassesForRace[eRaceInteral] then
			self.tAvailableClassesForRace[eRaceInteral] = {}
		end
	
		--Record all available classes for the races.
		local tClassesForRace = self.tAvailableClassesForRace[eRaceInteral]
		if not tClassesForRace[tCreation.classId]  then
			self.tAvailableClassesForRace[eRaceInteral][tCreation.classId] = {}
			self.tAvailableClassesForRace[eRaceInteral][tCreation.classId].bEnabled = tCreation.bEnabled and tCreation.bHasEntitlement
			self.tAvailableClassesForRace[eRaceInteral][tCreation.classId].nRequiredEntitlementId = tCreation.nRequiredEntitlementId
			self.tAvailableClassesForRace[eRaceInteral][tCreation.classId].tLinkInfo = tCreation.tLinkInfo
		end

		--Record all available classes.
		if not self.tAvailableRacesForClass[tCreation.classId] then
			self.tAvailableRacesForClass[tCreation.classId] = {}
		end


		--Record all available races for the class.
		if not self.tAvailableRacesForClass[tCreation.classId][eRaceInteral] then
			self.tAvailableRacesForClass[tCreation.classId][eRaceInteral] = {}
			self.tAvailableRacesForClass[tCreation.classId][eRaceInteral].bEnabled = tCreation.bEnabled and tCreation.bHasEntitlement
			self.tAvailableRacesForClass[tCreation.classId][eRaceInteral].nRequiredEntitlementId = tCreation.nRequiredEntitlementId
			self.tAvailableRacesForClass[tCreation.classId][eRaceInteral].tLinkInfo = tCreation.tLinkInfo
		end
	end
end

function Character:SetConflictWarnings()
	--Setting the Class Prompts
	local wndPromptList = self.wndRacePicker:FindChild("ClassIconComplex")
	local tPrompts = {
		[PreGameLib.CodeEnumClass.Engineer] = wndPromptList:FindChild("EngineerPrompt"),
		[PreGameLib.CodeEnumClass.Esper] = wndPromptList:FindChild("EsperPrompt"),
		[PreGameLib.CodeEnumClass.Medic] = wndPromptList:FindChild("MedicPrompt"),
		[PreGameLib.CodeEnumClass.Spellslinger] = wndPromptList:FindChild("SpellslingerPrompt"),
		[PreGameLib.CodeEnumClass.Stalker] = wndPromptList:FindChild("StalkerPrompt"),
		[PreGameLib.CodeEnumClass.Warrior] = wndPromptList:FindChild("WarriorPrompt"),
	}

	--Set the warnings for the class buttons
	local tEnabledClasses = self.eRace and self.tAvailableClassesForRace[self.eRace] or {}
	for idx, tTutorialAndFinalizeBtns in pairs(self.tTutorialAndCustomizationLink[keTutorialTab.Class]) do
		local eClass = tTutorialAndFinalizeBtns.wndTutorialBtn:GetData()

		local bClassIsAvailable = true --If no race then enable all classes.
		local nEntitlementId = 0
		if self.eRace then
			if tEnabledClasses[eClass] then
				bClassIsAvailable = tEnabledClasses[eClass].bEnabled
				nEntitlementId = tEnabledClasses[eClass].nRequiredEntitlementId
			else
				bClassIsAvailable = false
			end
		end

		local wndTutorialIcon = tTutorialAndFinalizeBtns.wndTutorialBtn:FindChild("Icon")
		local wndTutorialConflict = tTutorialAndFinalizeBtns.wndTutorialBtn:GetParent():FindChild("Conflict")
		local wndFinalizeConflict = tTutorialAndFinalizeBtns.wndFinalizeBtn:GetParent():FindChild("Conflict")
		local wndTutorialUpsell = tTutorialAndFinalizeBtns.wndTutorialBtn:GetParent():FindChild("Upsell")
		local wndFinalizeUpsell = tTutorialAndFinalizeBtns.wndFinalizeBtn:FindChild("MTX_UnlockFlag")
		wndTutorialIcon:SetOpacity(bClassIsAvailable and 1 or 0.25)
		
		if not bClassIsAvailable then
			if nEntitlementId == 0 then
				wndTutorialConflict:Show(true)
				wndFinalizeConflict:Show(true)
				wndTutorialUpsell:Show(false)
				wndFinalizeUpsell:Show(false)
				tTutorialAndFinalizeBtns.wndTutorialBtn:Enable(false)
				tTutorialAndFinalizeBtns.wndFinalizeBtn:Enable(false)
			else
				wndTutorialConflict:Show(false)
				wndFinalizeConflict:Show(false)
				wndTutorialUpsell:Show(true)
				wndFinalizeUpsell:Show(true)
				tTutorialAndFinalizeBtns.wndTutorialBtn:Enable(true)
				tTutorialAndFinalizeBtns.wndFinalizeBtn:Enable(true)
			end
		else
			wndTutorialConflict:Show(false)
			wndFinalizeConflict:Show(false)
			wndTutorialUpsell:Show(false)
			wndFinalizeUpsell:Show(false)
			tTutorialAndFinalizeBtns.wndTutorialBtn:Enable(true)
			tTutorialAndFinalizeBtns.wndFinalizeBtn:Enable(true)
		end

		--On the Race button page, at the bottom, set the available class icons.
		tPrompts[eClass]:SetBGColor(not bClassIsAvailable and "UI_AlphaPercent35" or "UI_AlphaPercent100")

		if not bClassIsAvailable then
			if nEntitlementId == 0 then
				local strWarning = PreGameLib.String_GetWeaselString( Apollo.GetString("Pregame_Conflict"), Apollo.GetString(c_arRaceStrings[self.eRace].strName), Apollo.GetString(c_arClassStrings[eClass].strName))
				wndTutorialConflict:SetTooltip(strWarning)
				wndFinalizeConflict:SetTooltip(strWarning)
			else
				local strUpsell = PreGameLib.String_GetWeaselString( Apollo.GetString("Pregame_RaceClassRequiresPurchase"), Apollo.GetString(c_arRaceStrings[self.eRace].strName), Apollo.GetString(c_arClassStrings[eClass].strName))
				wndTutorialUpsell:SetTooltip(strUpsell)
				wndFinalizeUpsell:SetTooltip(strUpsell)
			end
		end
	end

	
	--Set the warnings for the race buttons
	local tEnabledRaces = self.eClass and self.tAvailableRacesForClass[self.eClass] or {}
	for idx, tTutorialAndFinalizeBtns in pairs(self.tTutorialAndCustomizationLink[keTutorialTab.Race]) do
		local tRaceData = tTutorialAndFinalizeBtns.wndTutorialBtn:GetData()

		local bRaceIsAvailable = true --If no class then enable all races.
		local nEntitlementId = 0
		if self.eClass then
			if tEnabledRaces[tRaceData.eRace] then
				bRaceIsAvailable = tEnabledRaces[tRaceData.eRace].bEnabled
				nEntitlementId = tEnabledRaces[tRaceData.eRace].nRequiredEntitlementId
			else
				bRaceIsAvailable = false
			end
		end
		
		local wndTutorialConflict = tTutorialAndFinalizeBtns.wndTutorialBtn:GetParent():FindChild("Conflict")
		local wndFinalizeConflict = tTutorialAndFinalizeBtns.wndFinalizeBtn:GetParent():FindChild("Conflict")
		local wndFinalizeUpsell = tTutorialAndFinalizeBtns.wndFinalizeBtn:FindChild("MTX_UnlockFlag")

		if not bRaceIsAvailable then
			if nEntitlementId == 0 then
				wndTutorialConflict:Show(true)
				wndFinalizeConflict:Show(true)
				wndFinalizeUpsell:Show(false)
			else
				wndTutorialConflict:Show(false)
				wndFinalizeConflict:Show(false)
				wndFinalizeUpsell:Show(true)
			end
		else
			wndTutorialConflict:Show(false)
			wndFinalizeConflict:Show(false)
			wndFinalizeUpsell:Show(false)
		end

		if not bRaceIsAvailable then
			if nEntitlementId == 0 then
				local strWarning = PreGameLib.String_GetWeaselString( Apollo.GetString("Pregame_Conflict"), Apollo.GetString(c_arRaceStrings[tRaceData.eRace].strName), Apollo.GetString(c_arClassStrings[self.eClass].strName))
				wndTutorialConflict:SetTooltip(strWarning)
				wndFinalizeConflict:SetTooltip(strWarning)
			else
				local strUpsell = PreGameLib.String_GetWeaselString( Apollo.GetString("Pregame_RaceClassRequiresPurchase"), Apollo.GetString(c_arRaceStrings[self.eRace].strName), Apollo.GetString(c_arClassStrings[self.eClass].strName))
				wndFinalizeUpsell:SetTooltip(strUpsell)
			end
		end
	end
end

---------------------------------------------------------------------------------------------------

function Character:FormatInfoPanel()
	local tSelected = self.arCharacterCreateOptions[self.characterCreateIndex]

	local bOnFinalizePage = false
	if self.wndTab and self.wndTab:GetData() == keTutorialTab.Finalize then
		bOnFinalizePage = self.wndTab:GetData() == keTutorialTab.Finalize
	end
	
	self.wndInfoPane:Show(bOnFinalizePage and (self.eFaction or self.eRace or self.eClass or self.ePath))
	if not bOnFinalizePage then
		return
	end
	
	local tRealmInfo = CharacterScreenLib.GetRealmInfo()
	self.wndInfoPane:FindChild("CN_HintWindow"):Show(tRealmInfo and tRealmInfo.bFactionRestricted and #g_arCharacters == 0)
	
	
	local nBufferHeight 		= 6
	local nContentHeight 	= 0
	local wndContainer		= self.wndInfoPane:FindChild("InfoPane_SortContainer")
	local wndFaction			= wndContainer:FindChild("Faction")
	local wndRace 			= wndContainer:FindChild("Race")
	local wndClass			= wndContainer:FindChild("Class")
	local wndPath				= wndContainer:FindChild("Path")

	wndFaction:Show(bOnFinalizePage and self.eFaction)
	wndRace:Show(bOnFinalizePage and self.eRace)
	wndClass:Show(bOnFinalizePage and self.eClass)
	wndClass:FindChild("Footer"):Show(bOnFinalizePage and self.eRace) --If there is no race, then don't show the gear preview options.
	wndPath:Show(bOnFinalizePage and self.ePath)

	wndFaction:FindChild("InfoField"):SetHeightToContentHeight()
	wndRace:FindChild("InfoField"):SetHeightToContentHeight()
	wndClass:FindChild("InfoField"):SetHeightToContentHeight()
	wndPath:FindChild("InfoField"):SetHeightToContentHeight()
	
	if tSelected then
		local eRaceInteral = tSelected.raceId == PreGameLib.CodeEnumRace.Human and tSelected.factionId == PreGameLib.CodeEnumFaction.Dominion and k_idCassian or tSelected.raceId 
		wndFaction:FindChild("Icon"):SetSprite(c_arRaceStrings[eRaceInteral].strFactionIcon)
		wndRace:FindChild("Icon"):SetSprite(ktIcons[keTutorialTab.Race][eRaceInteral][tSelected.genderId])
	end
	
	if self.eClass then
		wndClass:FindChild("Icon"):SetSprite(ktIcons[keTutorialTab.Class][self.eClass])
	end
	
	if self.ePath then
		wndPath:FindChild("Icon"):SetSprite(ktIcons[keTutorialTab.Path][self.ePath])
	end
	
	--Re-size Faction Container
	if self.eFaction then
		local nLeft, nTop, nRight, nBottom = wndFaction:GetAnchorOffsets()
		nBottom = wndFaction:FindChild("Button"):IsChecked() and wndFaction:FindChild("Header"):GetHeight() or wndFaction:FindChild("Header"):GetHeight() + wndFaction:FindChild("InfoField"):GetHeight() + wndFaction:FindChild("Footer"):GetHeight()
		wndFaction:SetAnchorOffsets(nLeft, nTop, nRight, nTop+nBottom+nBufferHeight)
		wndFaction:FindChild("InfoField"):Show(not wndFaction:FindChild("Button"):IsChecked())
	end
	
	--Re-size Race Container
	if self.eRace then
		local nLeft, nTop, nRight, nBottom = wndRace:GetAnchorOffsets()
		nBottom = wndRace:FindChild("Button"):IsChecked() and wndRace:FindChild("Header"):GetHeight() or wndRace:FindChild("Header"):GetHeight() + wndRace:FindChild("InfoField"):GetHeight() + wndRace:FindChild("Footer"):GetHeight()
		wndRace:SetAnchorOffsets(nLeft, nTop, nRight, nTop+nBottom+nBufferHeight)
		wndRace:FindChild("InfoField"):Show(not wndRace:FindChild("Button"):IsChecked())
	end
	
	--Re-size Class Container
	if self.eClass then
		local nPreviewHeight = self.eRace and wndClass:FindChild("Footer"):GetHeight() or 0
		local nLeft, nTop, nRight, nBottom = wndClass:GetAnchorOffsets()
		nBottom = wndClass:FindChild("Button"):IsChecked() and wndClass:FindChild("Header"):GetHeight() or wndClass:FindChild("Header"):GetHeight() + wndClass:FindChild("InfoField"):GetHeight() + nPreviewHeight
		wndClass:SetAnchorOffsets(nLeft, nTop, nRight, nTop+nBottom+nBufferHeight)
		wndClass:FindChild("InfoField"):Show(not wndClass:FindChild("Button"):IsChecked())
	end
	
	--Re-size Path Container
	if self.ePath then
		local nLeft, nTop, nRight, nBottom = wndPath:GetAnchorOffsets()
		nBottom = wndPath:FindChild("Button"):IsChecked() and wndPath:FindChild("Header"):GetHeight() or wndPath:FindChild("Header"):GetHeight() + wndPath:FindChild("InfoField"):GetHeight() + wndPath:FindChild("Footer"):GetHeight()
		wndPath:SetAnchorOffsets(nLeft, nTop, nRight, nTop+nBottom+nBufferHeight)
		wndPath:FindChild("InfoField"):Show(not wndPath:FindChild("Button"):IsChecked())
	end
	
	local nVscroll = wndContainer:GetVScrollPos()
	wndContainer:ArrangeChildrenVert()
	wndContainer:RecalculateContentExtents()
	wndContainer:SetVScrollPos(nVscroll)
end

function Character:InfoPanelDisplayContainer(wndContainer)
	local wndFaction	= self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Faction")
	local wndRace 	= self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Race")
	local wndClass	= self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Class")
	local wndPath		= self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Path")
	
	wndFaction:FindChild("Button"):SetCheck(true)
	wndRace:FindChild("Button"):SetCheck(true)
	wndClass:FindChild("Button"):SetCheck(true)
	wndPath:FindChild("Button"):SetCheck(true)
	wndContainer:FindChild("Button"):SetCheck(false)
	
	self:FormatInfoPanel()
end

function Character:OnGearPreview(wndHandler, wndControl) --Optional parameters, if not passed in there will not be a last checked gear btn.
	if wndHandler ~= wndControl or g_arActors.primary == nil then
		return
	end

	if self.tLastCheckedGearPreviewBtns then
		self.tLastCheckedGearPreviewBtns.wndClassContentBtn:SetCheck(false)
		self.tLastCheckedGearPreviewBtns.wndInfoPaneClassBtn:SetCheck(false)
	end

	self.eGearPreview = wndControl and wndControl:GetData() or keArmorPreview.Early
	
	local wndClassContentBtn = nil
	local wndInfoPaneClassBtn = nil
	if self.eGearPreview == keArmorPreview.Early then
		wndClassContentBtn = self.wndClassContent:FindChild("EarlyPreview")
		wndInfoPaneClassBtn = self.wndInfoPane:FindChild("EarlyPreview")
	elseif self.eGearPreview == keArmorPreview.Mid then
		wndClassContentBtn = self.wndClassContent:FindChild("MidPreview")
		wndInfoPaneClassBtn = self.wndInfoPane:FindChild("MidPreview")
	elseif self.eGearPreview == keArmorPreview.Late then
		wndClassContentBtn = self.wndClassContent:FindChild("LatePreview")
		wndInfoPaneClassBtn = self.wndInfoPane:FindChild("LatePreview")
	end

	if wndClassContentBtn and wndInfoPaneClassBtn then
		wndClassContentBtn:SetCheck(true)
		wndInfoPaneClassBtn:SetCheck(true)
		self.tLastCheckedGearPreviewBtns = {wndClassContentBtn = wndClassContentBtn, wndInfoPaneClassBtn = wndInfoPaneClassBtn}
	end
	
	if self.characterCreateIndex then
		local tSelected = self.arCharacterCreateOptions[self.characterCreateIndex]
		g_arActors.primary:SetItemsByCreationGearSet(self.eGearPreview, tSelected and tSelected.classId or nil)
	end
end

---------------------------------------------------------------------------------------------------
function Character:SetCharacterCreateIndex( characterCreateIndex )

	--Set the main and shadow character. The shadow is used to populate our option lists during customization and is discretely placed waaaaaaaay off into space.
	if g_arActors.primary == nil
		or g_bReplaceActor == true
		or self.characterCreateIndex == nil
		or self.arCharacterCreateOptions[self.characterCreateIndex] == nil
		or self.arCharacterCreateOptions[self.characterCreateIndex].raceId ~= self.arCharacterCreateOptions[characterCreateIndex].raceId
		or self.arCharacterCreateOptions[self.characterCreateIndex].factionId ~= self.arCharacterCreateOptions[characterCreateIndex].factionId
		or self.arCharacterCreateOptions[self.characterCreateIndex].genderId ~= self.arCharacterCreateOptions[characterCreateIndex].genderId
		or self.arCharacterCreateOptions[self.characterCreateIndex].classId ~= self.arCharacterCreateOptions[characterCreateIndex].classId then

		local tCreated = self.arCharacterCreateOptions[characterCreateIndex]
		if tCreated then
			g_arActors.primary = g_scene:AddActorByRaceGenderClass(1, tCreated.raceId, tCreated.genderId, tCreated.classId)
		end

		if g_arActors.primary then
			g_arActors.primary:SetFaction(self.arCharacterCreateOptions[characterCreateIndex].factionId)
		end

	end

	g_arActors.shadow = g_scene:AddActorByRaceGenderClass(25, self.arCharacterCreateOptions[characterCreateIndex].raceId, self.arCharacterCreateOptions[characterCreateIndex].genderId, self.arCharacterCreateOptions[characterCreateIndex].classId)
	if g_arActors.shadow then
		g_arActors.shadow:SetFaction(self.arCharacterCreateOptions[characterCreateIndex].factionId)
		g_arActors.shadow:SetPosition(knDefaultScale, kvecPositionHide, kvecDefaultRotation ) -- set the shadow character waaaaaaaaaaaay off in the stratosphere so he/she doesn't draw
	end

	if self.eClass then
		local eClassItem = self.arCharacterCreateOptions[characterCreateIndex].characterCreateId
		if g_arActors.primary then
			g_arActors.primary:SetItemsByCreationId(eClassItem)
		end

		if g_arActors.shadow then
			g_arActors.shadow:SetItemsByCreationId(eClassItem)
		end
	else
		local nSuit
		if eFaction == PreGameLib.CodeEnumFaction.Exile then
			nSuit = 530
		else
			nSuit = 531
		end
		
		if g_arActors.primary then
			g_arActors.primary:SetItemsByCreationId(nSuit)
		end

		if g_arActors.shadow then
			g_arActors.shadow:SetItemsByCreationId(nSuit)
		end
	end

	if g_arActors.characterAttach then
		g_arActors.characterAttach:Animate(0, PreGameLib.CodeEnumModelSequence.APState1Idle, 0, true, false, 0, g_nCharCurrentRot)
	end
	self.characterCreateIndex = characterCreateIndex
	self:ConfigureCreateModelSettings()
end

---------------------------------------------------------------------------------------------------
-- Our model settings go here
---------------------------------------------------------------------------------------------------
function Character:ConfigureCreateModelSettings() -- interem step that sets up the model for character create
	local eRaceExternal = self.eRace == k_idCassian and PreGameLib.CodeEnumRace.Human or self.eRace
	self:OnConfigureModel(eRaceExternal, self.eGender, self.eFaction, self.eClass, self.ePath)
	if g_arActors.characterAttach then
		g_arActors.characterAttach:Animate(0, PreGameLib.CodeEnumModelSequence.APState1Idle, 0, true, false, 0, g_nCharCurrentRot)
	end
end

function Character:OnConfigureModel(eRace, eGender, eFaction, eClass, ePath, nSelectIdx) -- position the model for both create and select
	if not g_arActors.pedestal or not g_arActors.characterAttach or not g_arActors.soloLight then
		return false 
	end

	local eAttachPoint = nil
	local eCurTab = self.wndTab and self.wndTab:GetData() or nil
	if eCurTab == keTutorialTab.Class or eCurTab == keTutorialTab.Path then
		eAttachPoint =PreGameLib.CodeEnumModelAttachment.FXMisc06
	elseif eCurTab == keTutorialTab.Experience or eCurTab == keTutorialTab.Race then
		eAttachPoint = PreGameLib.CodeEnumModelAttachment.FXMisc07
	else --On Customize, Finalize or Select Character
		eAttachPoint = PreGameLib.CodeEnumModelAttachment.PropMisc01
	end

	if eAttachPoint then
		g_arActors.pedestal:FollowActor(g_arActors.mainScene, eAttachPoint)
		g_arActors.characterAttach:FollowActor(g_arActors.pedestal, PreGameLib.CodeEnumModelAttachment.PropMisc01)

		if eRace then
			if g_arActors.rowsdower then
				g_arActors.rowsdower:FollowActor(g_arActors.mainScene, PreGameLib.CodeEnumModelAttachment.FXMisc07) --Hide rowsdower
			end
			if g_arActors.primary then
				g_arActors.primary:FollowActor(g_arActors.characterAttach, PreGameLib.CodeEnumModelAttachment.PropMisc01)
			end

			eLightState = ktRaceToSololightState[eRace]

			if not eClass then
				self:HelperSetDefaultFactionCostume(eFaction, g_arActors.primary)
			end
		else
			if g_arActors.primary then
				g_arActors.primary:FollowActor(g_arActors.mainScene, PreGameLib.CodeEnumModelAttachment.FXMisc07) --Hide primary
			end
			if g_arActors.rowsdower then
				if CharacterScreenLib.HasReceivedCharacterList() then
					g_arActors.rowsdower:FollowActor(g_arActors.characterAttach, PreGameLib.CodeEnumModelAttachment.PropMisc01)
				else
					g_arActors.rowsdower:FollowActor(g_arActors.mainScene, PreGameLib.CodeEnumModelAttachment.FXMisc07) --Hide rowsdower
				end
			end

			eLightState = PreGameLib.CodeEnumModelSequence.APState0Idle
		end

		if eCurTab ~= keTutorialTab.Race then
			g_arActors.soloLight:FollowActor(g_arActors.mainScene, eAttachPoint)
			g_arActors.soloLight:Animate(0, eLightState, 0, true, false)
		end
	end

	if eRace and eGender and eFaction then
		g_cameraAnimation = c_cameraZoomAnimation[eRace][eGender][eFaction]
	end

	if g_arActors.mainScene ~= nil and g_cameraAnimation ~= nil then
		g_arActors.mainScene:Animate(0, g_cameraAnimation, 0, true, false, knInstantAnimationSpeed, g_cameraSlider)
	end

	if g_arActors.primary then
		if nSelectIdx ~= nil then -- this will only be true when the call is coming from character select
			CharacterScreenLib.ApplyCharacterToActor( nSelectIdx, g_arActors.primary )
		end

		--Handle Sheathing for animations.
		local bSheathSetting = true
		if eClass == PreGameLib.CodeEnumClass.Esper or eCurTab ~= keTutorialTab.Class and eCurTab ~= keTutorialTab.Finalize then
			bSheathSetting = false
		end
		g_arActors.primary:SetWeaponSheath(bSheathSetting)

		--Set the animation of the main model.
		local eAnimation = c_factionPlayerAnimation[eFaction]
		if eCurTab == keTutorialTab.Class and eClass and c_classSelectAnimation[eClass] then
			eAnimation = c_classSelectAnimation[eClass].eReady
		elseif eCurTab == keTutorialTab.Finalize and eClass and c_classSelectAnimation[eClass] then
			eAnimation = c_classSelectAnimation[eClass].eStand
		elseif eCurTab == keTutorialTab.Customize then
			eAnimation = PreGameLib.CodeEnumModelSequence.DefaultStartScreenLoop01
		end
		g_arActors.primary:Animate(0, eAnimation, 0, true, false)
	end
end

function Character:HelperSetDefaultFactionCostume(eFaction, actorCur)
	if eFaction == PreGameLib.CodeEnumFaction.Exile then
		actorCur:SetItemsByCreationId(530)
	else
		actorCur:SetItemsByCreationId(531)
	end
end

---------------------------------------------------------------------------------------------------

function Character:HelperSetInfoPane(bClear)
	local strFormat = "<P Font=\"CRB_HeaderSmall\" TextColor=\"UI_TextHoloTitle\">%s%s<P TextColor=\"White\">%s</P></P>"
	local strFormatClear = "<P Font=\"CRB_HeaderSmall\" TextColor=\"White\">%s</P>"

	--Setting faction texts.
	local wndFactionInfoPane = self.wndInfoPane:FindChild("InfoPane_SortContainer:Faction")
	local strFactionTitle = ""
	local strFactionDetails = ""
	if self.eFaction and self.eRace and not bClear then
		strFactionTitle = string.format(strFormat, Apollo.GetString("Pregame_FactionInfo"), Apollo.GetString("Chat_ColonBreak"), Apollo.GetString(c_arRaceStrings[self.eRace].strFaction))
		strFactionDetails = Apollo.GetString(c_arFactionStrings[self.eFaction])
	else
		strFactionTitle = string.format(strFormatClear, Apollo.GetString("Pregame_FactionInfo"))
	end

	wndFactionInfoPane:FindChild("TitleField"):SetAML(strFactionTitle)
	wndFactionInfoPane:FindChild("InfoField"):SetText(strFactionDetails)
	wndFactionInfoPane:FindChild("InfoField"):SetHeightToContentHeight()

	--Setting race texts.
	local wndRaceInfoPane = self.wndInfoPane:FindChild("InfoPane_SortContainer:Race")
	local strRaceTitle = ""
	local strRaceInfo = ""
	if self.eRace and not bClear then
		strRaceTitle = string.format(strFormat, Apollo.GetString("CRB_Race"), Apollo.GetString("Chat_ColonBreak"), Apollo.GetString(c_arRaceStrings[self.eRace].strName))
		strRaceInfo = Apollo.GetString(c_arRaceStrings[self.eRace].strDescription)
	else
		strRaceTitle = string.format(strFormatClear, Apollo.GetString("CRB_Race"))
	end

	wndRaceInfoPane:FindChild("TitleField"):SetAML(strRaceTitle)
	wndRaceInfoPane:FindChild("InfoField"):SetText(strRaceInfo)
	wndRaceInfoPane:FindChild("InfoField"):SetHeightToContentHeight()

	--Setting class texts.
	local wndClassInfoPane = self.wndInfoPane:FindChild("InfoPane_SortContainer:Class")
	local strClassTitle = ""
	local strClassDescription = ""
	if self.eClass and not bClear then
		strClassTitle = string.format(strFormat, Apollo.GetString("CRB_Class"), Apollo.GetString("Chat_ColonBreak"),  Apollo.GetString(c_arClassStrings[self.eClass].strName))
		strClassDescription = Apollo.GetString(c_arClassStrings[self.eClass].strDescription)
	else
		strClassTitle = string.format(strFormatClear, Apollo.GetString("CRB_Class"))
	end

	wndClassInfoPane:FindChild("TitleField"):SetAML(strClassTitle)
	wndClassInfoPane:FindChild("InfoField"):SetText(strClassDescription)
	wndClassInfoPane:FindChild("InfoField"):SetHeightToContentHeight()

	--Setting path texts.
	local wndPathInfoPane = self.wndInfoPane:FindChild("InfoPane_SortContainer:Path")
	local strPathTitle = ""
	local strPathDescription = ""
	if self.ePath and not bClear then
		strPathTitle = string.format(strFormat, Apollo.GetString("CRB_Path"), Apollo.GetString("Chat_ColonBreak"), Apollo.GetString(c_arPathStrings[self.ePath].strName))
		strPathDescription = Apollo.GetString(c_arPathStrings[self.ePath].strDescription)
	else
		strPathTitle = string.format(strFormatClear, Apollo.GetString("CRB_Path"))
	end

	wndPathInfoPane:FindChild("TitleField"):SetAML(strPathTitle)
	wndPathInfoPane:FindChild("InfoField"):SetText(strPathDescription)
	wndPathInfoPane:FindChild("InfoField"):SetHeightToContentHeight()



	local lInfoFrame1, tInfoFrame1, rInfoFrame1, bInfoFrame1 = self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Faction"):FindChild("InfoField"):GetAnchorOffsets()
	self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Faction"):FindChild("InfoField"):SetAnchorOffsets(lInfoFrame1, tInfoFrame1, rInfoFrame1, bInfoFrame1 + 4)
	local lInfoFrame2, tInfoFrame2, rInfoFrame2, bInfoFrame2 = self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Race"):FindChild("InfoField"):GetAnchorOffsets()
	self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Race"):FindChild("InfoField"):SetAnchorOffsets(lInfoFrame2, tInfoFrame2, rInfoFrame2, bInfoFrame2 + 4)
	local lInfoFrame3, tInfoFrame3, rInfoFrame3, bInfoFrame3 = self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Class"):FindChild("InfoField"):GetAnchorOffsets()
	self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Class"):FindChild("InfoField"):SetAnchorOffsets(lInfoFrame3, tInfoFrame3, rInfoFrame3, bInfoFrame3 + 4)
	local lInfoFrame4, tInfoFrame4, rInfoFrame4, bInfoFrame4 = self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Path"):FindChild("InfoField"):GetAnchorOffsets()
	self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Path"):FindChild("InfoField"):SetAnchorOffsets(lInfoFrame4, tInfoFrame4, rInfoFrame4, bInfoFrame4 + 4)
	self:FormatInfoPanel()
end

---------------------------------------------------------------------------------------------------

function Character:OnRacePanelToggle(wndHandler, wndControl)
	local bIsChecked = wndControl:IsChecked()
	self.wndRacePicker:Show(bIsChecked)

	--Only open this once a race has been selected.
	if self.eRace then
		self:InfoPanelDisplayContainer(self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Race"))
	end
end

function Character:OnClassPanelToggle(wndHandler, wndControl)
	local bIsChecked = wndControl:IsChecked()
	self.wndClassPicker:Show(bIsChecked)
	
	--Only open this once a class has been selected.
	if self.eClass then
		self:InfoPanelDisplayContainer(self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Class"))
	end
end

function Character:OnPathPanelToggle(wndHandler, wndControl)
	local bIsChecked = wndControl:IsChecked()
	self.wndPathPicker:Show(bIsChecked)
	
	--Only open this once a path has been selected.
	if self.ePath then
		self:InfoPanelDisplayContainer(self.wndInfoPane:FindChild("InfoPane_SortContainer"):FindChild("Path"))
	end
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
function Character:OnRandomizeCharacterLook()

	local tOptionIdToCategoryIdx = {}
	local arCategoryHeaders = self.wndCustPaginationList:FindChild("Content"):GetChildren()
	
	for idx, entry in pairs(arCategoryHeaders) do
		if entry:FindChild("CustomizePaginationBtn") ~= nil then
			entry:FindChild("CustomizePaginationBtn"):SetCheck(false)
		end
		
		if entry:FindChild("AdvancedOptionsBtn") ~= nil then
			entry:FindChild("AdvancedOptionsBtn"):SetCheck(false)
		end
		
		tOptionIdToCategoryIdx[entry:GetData().sliderId] = idx
	end

	self.wndCustOptionList:Show(false)
	self.wndCustAdvanced:Show(false)
	self.wndCustOptionUndoBtn:Enable(false)

	if g_arActors.primary and g_arActors.shadow then
		self:StoreCurrentCharacterLook()
		for i, option in pairs(self.arCustomizeLookOptions) do
			option.valueIdx = math.random( 1, option.count );
			local wndHeader = arCategoryHeaders[tOptionIdToCategoryIdx[option.sliderId]]
			if wndHeader then
				wndHeader:SetData(option)
			end
			
			g_arActors.primary:SetLook(option.sliderId, option.values[ option.valueIdx ] )
			g_arActors.shadow:SetLook(option.sliderId, option.values[ option.valueIdx ] )
		end
	else
		self.arCustomizeLookOptions = {}
		self.arCustomizeBoneOptions = {}
	end
	self:FillCustomizePagination()
end

function Character:StoreCurrentCharacterLook()
	if g_arActors.primary then
		self.arCustomizeLookOptions = g_arActors.primary:GetLooks() or {} --Rowsdower doesn't have customize look options.
		self.arCustomizeBoneOptions = g_arActors.primary:GetBones()
	end
end

---------------------------------------------------------------------------------------------------

function Character:OnNameChanged(wndControl, wndHandler, strText)
	if not self.wndFirstNameEntry or not self.wndLastNameEntry then
		return
	end
	
	local bFirstChanged = false
	local bLastChanged = false
	if wndControl == self.wndFirstNameEntry then
		bFirstChanged = true
	elseif wndControl == self.wndLastNameEntry then
		bLastChanged = true
	end

	strFirstName = self.wndFirstNameEntry:GetText()
	strLastName = self.wndLastNameEntry:GetText()
	
	local nFirstLength = Apollo.StringLength(strFirstName)
	local nLastLength = Apollo.StringLength(strLastName)
	local nNameLength = nFirstLength + nLastLength
	self.strName = nNameLength > 0 and string.format("%s %s", strFirstName, strLastName) or ""

	local bIsFirstNameValid = CharacterScreenLib.IsCharacterNamePartValid(strFirstName)
	local bIsLastNameValid = CharacterScreenLib.IsCharacterNamePartValid(strLastName)
	local bIsFullNameValid = CharacterScreenLib.IsCharacterNameValid(self.strName)

	local crText = nil
	local strIcon = nil
	if bFirstChanged then
		if nFirstLength == 0 then
			strIcon = ""
		--Changing the first name, last name is valid but this change makes full name invalid.
		elseif not bIsFirstNameValid or bIsLastNameValid and not bIsFullNameValid then
			strIcon = "CRB_CharacterCreateSprites:sprCharC_NameCheckNo"
			crText = ApolloColor.new("AddonError")
		elseif bIsFirstNameValid then
			strIcon = "CRB_CharacterCreateSprites:sprCharC_NameCheckYes"
			crText = ApolloColor.new("UI_TextHoloTitle")
			self.wndFirstName:FindChild("ErrorIndicator"):Show(false)
		end

		self.wndFirstName:FindChild("CheckMarkIcon"):SetSprite(strIcon)
		self.wndFirstNameEntry:SetTextColor(crText)
		
	elseif bLastChanged then
		if nLastLength == 0 then
			strIcon = ""
		--Changing the last name, first name is valid but this change makes full name invalid.
		elseif not bIsLastNameValid or bIsFirstNameValid and not bIsFullNameValid then
			strIcon = "CRB_CharacterCreateSprites:sprCharC_NameCheckNo"
			crText = ApolloColor.new("AddonError")
		elseif bIsLastNameValid then
			strIcon = "CRB_CharacterCreateSprites:sprCharC_NameCheckYes"
			crText = ApolloColor.new("UI_TextHoloTitle")
			self.wndLastName:FindChild("ErrorIndicator"):Show(false)
		end

		self.wndLastName:FindChild("CheckMarkIcon"):SetSprite(strIcon)
		self.wndLastNameEntry:FindChild("EnterNameEntry"):SetTextColor(crText)
	end
	
	if bIsFullNameValid then
		self.wndFirstName:FindChild("CheckMarkIcon"):SetSprite("CRB_CharacterCreateSprites:sprCharC_NameCheckYes")
		self.wndLastName:FindChild("CheckMarkIcon"):SetSprite("CRB_CharacterCreateSprites:sprCharC_NameCheckYes")
		self.wndFirstNameEntry:SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
		self.wndLastNameEntry:SetTextColor(ApolloColor.new("UI_TextHoloTitle"))
	end
	
	local strColor = nNameLength > knMaxCharacterName and "UI_BtnTextRedNormal" or "UI_TextHoloBodyHighlight"
	local strHelpText = string.format(
		"%s [%s/%s]",
		PreGameLib.String_GetWeaselString(Apollo.GetString("CharacterCreate_NameRules"), knMinCharacterName, knMaxCharacterName),
		nNameLength,
		knMaxCharacterName
	)

	local wndNameText = g_controls:FindChild("CharacterNameText")
	wndNameText:Show(self.strName ~= "")
	wndNameText:SetTextColor(ApolloColor.new(strColor))
	wndNameText:SetText(strHelpText)
end

---------------------------------------------------------------------------------------------------

function Character:OnRotateCatcherDown(wndHandler, wndControl, iButton, x, y, bDouble)
	if wndHandler ~= wndControl then
		self.bRotateEngaged = false
		return 
	end

	self.nStartPoint = x
	self.bRotateEngaged = true
end

function Character:OnRotateCatcherUp(wndHandler, wndControl, iButton, x, y)
	if wndHandler ~= wndControl then
		self.bRotateEngaged = false
		return 
	end

	self.bRotateEngaged = false
end

function Character:OnRotateCatcherMove(wndHandler, wndControl, x, y)
	if wndHandler ~= wndControl then
		self.bRotateEngaged = false
		return 
	end

	if self.bRotateEngaged and g_arActors.primary ~= nil then
		if x > self.nStartPoint then
			g_nCharCurrentRot = g_nCharCurrentRot + (x - self.nStartPoint)/480
		else
			g_nCharCurrentRot = g_nCharCurrentRot - (self.nStartPoint - x)/480
		end

		while g_nCharCurrentRot < 0 do
			g_nCharCurrentRot = g_nCharCurrentRot + 1
		end

		while g_nCharCurrentRot > 1 do
			g_nCharCurrentRot = g_nCharCurrentRot - 1
		end

		if g_arActors.characterAttach then
			g_arActors.characterAttach:Animate(0, PreGameLib.CodeEnumModelSequence.APState1Idle, 0, true, false, 0, g_nCharCurrentRot)
		end

		self.nStartPoint = x
	end
end

function Character:OnRotateCatcherMouseWheel(wndHandler, wndControl, x, y, fAmount)
	if wndHandler ~= wndControl then
		return 
	end

	local eCurTab = self.wndTab and self.wndTab:GetData() 
	if eCurTab ~= nil and eCurTab ~= keTutorialTab.Customize and eCurTab ~= keTutorialTab.Finalize or self.bZoomAnimating then --If there is no eCurTab, then not in character creation.
		return
	end
	-- wndHandler and wndControl should be the catcher window
	-- x and y are the cursor position in window space
	-- fAmount is how far the wheel was moved (can be negative)

	g_cameraSlider = g_cameraSlider + fAmount * .05
	if g_cameraSlider < 0 then
		g_cameraSlider = 0
	end

	if g_cameraSlider > 1 then
		g_cameraSlider = 1
	end

	self.bZoomedIntoFace = g_cameraSlider > 0
	g_arActors.mainScene:Animate(0, g_cameraAnimation, 0, true, false, knInstantAnimationSpeed, g_cameraSlider)
end

function Character:OnSaveLoadBtn(wndHandler, wndControl)
	local strCode = g_arActors.primary:GetSliderCodes()

	if strCode ~= nil then
		self.wndCreateCodeEntry:SetText(strCode)
		self:UpdateCodeDisplay(strCode)
	end

	self:HelperHideMenus()
	self.wndCreateCode:SetData(strCode)
	
	--Show the controls and hide the exit and configure btns.
	self.wndCreateCode:Show(true)
	g_controls:Show(true)
	g_controls:FindChild("ExitForm"):Show(false)
	g_controls:FindChild("OptionsContainer"):Show(false)
	g_controls:FindChild("EnterForm"):Show(false)
	g_controls:FindChild("CharacterNameText"):Show(false)
	self.wndFirstName:Show(false)
	self.wndLastName:Show(false)
end

function Character:UpdateCodeDisplay(strCode)

	local crPass = "ff2f94ac"
	local crFail = "ffcc0000"
	local tFaction = {true, "CRB_Question", crPass}
	local tRace = {true, "CRB_Question", crPass}
	local tGender = {true, "CRB_Question", crPass}
	
	
	if strCode == nil then
		local strInvalid = string.format("<P Align=\"Center\" Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</P>", crFail, Apollo.GetString("Pregame_InvalidCode"))
		self.wndCreateCode:FindChild("RaceGenderText"):SetAML(strInvalid)
		self.wndCreateCode:FindChild("UpdateCharacterCodeBtn"):Enable(false)
		return
	else
		local tResults = g_arActors.shadow:SetBySliderCodes(strCode, self.eClass)
		if tResults == nil then
			local strInvalid = string.format("<P Align=\"Center\" Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</P>", crFail, Apollo.GetString("Pregame_InvalidCode"))
			self.wndCreateCode:FindChild("RaceGenderText"):SetAML(strInvalid)
			self.wndCreateCode:FindChild("UpdateCharacterCodeBtn"):Enable(false)
			return
		elseif tResults.bUnsupportedVersion then
			local strInvalid = string.format("<P Align=\"Center\" Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</P>", crFail, Apollo.GetString("Pregame_OutdatedCode"))
			self.wndCreateCode:FindChild("RaceGenderText"):SetAML(strInvalid)
			self.wndCreateCode:FindChild("UpdateCharacterCodeBtn"):Enable(false)
			return
		end

		if tResults.bFactionDoesntMatch then
			tFaction[1] = false
			tFaction[3] = crFail
		end

		if tResults.bGenderDoesntMatch then
			tGender[1] = false
			tGender[3] = crFail
		end

		if tResults.bRaceDoesntMatch then
			tRace[1] = false
			tRace[3] = crFail

			if tResults.nRace == 13 then
				tGender[3] = crFail
			end
		end

		-- Format strings

		if tResults.nFaction == PreGameLib.CodeEnumFaction.Dominion then
			tFaction[2] = "CRB_Dominion"
		else
			tFaction[2] = "CRB_Exile"
		end


		if tResults.nGender == PreGameLib.CodeEnumGender.Male then
			tGender[2] = "CRB_Male"
		else
			tGender[2] = "CRB_Female"
		end

		if c_arRaceStrings[tResults.nRace] ~= nil then
			if tResults.nRace == PreGameLib.CodeEnumRace.Human then
				tRace[2] = "RaceHuman"
			elseif tResults.nRace == PreGameLib.CodeEnumRace.Chua then
				tRace[2] = c_arRaceStrings[tResults.nRace].strName
				tGender[2] = ""
			else
				tRace[2] = c_arRaceStrings[tResults.nRace].strName	
			end
		end

		local strDisplay = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">(</T>", crPass)
		local strFaction = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</T>", tFaction[3], Apollo.GetString(tFaction[2]) .. " ")
		local strRace = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</T>", tRace[3], Apollo.GetString(tRace[2]) .. " ")
		local strGender = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</T>", tGender[3], Apollo.GetString(tGender[2]))
		local strEnd = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">)</T>", crPass)
		strDisplay = string.format("<P Align=\"Center\">%s</P>", PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_FactionRaceGender"), strDisplay, strFaction, strRace, strGender, strEnd))

		self.wndCreateCode:FindChild("RaceGenderText"):SetAML(strDisplay)
		self.wndCreateCode:FindChild("UpdateCharacterCodeBtn"):Enable(tRace[1] == true and tFaction[1] == true and tGender[1] == true)
		--strFailText =self.wndCreateCode:FindChild("FailMessage"):GetText()
		--self.wndCreateCode:FindChild("FailMessage"):SetText(strFailText .."race: "..tostring(tRace[1]).." faction: "..tostring(tFaction[1]).." gender: "..tostring(tGender[1]))
		self.wndCreateCode:FindChild("FailMessage"):Show(tRace[1] == false or tFaction[1] == false or tGender[1] == false)
	end
end

function Character:OnCloseCodeEntryBtn(wndHandler, wndControl)
	local strCode = self.wndCreateCode:GetData()
	if strCode ~= nil then
		g_arActors.shadow:SetBySliderCodes(strCode, self.eClass)
	end

	self.wndCreateCode:Show(false)
end

function Character:OnCharacterCodeEdit(wndHandler, wndControl, strNew, strOld)
	self:UpdateCodeDisplay(strNew)
end

function Character:OnUpdateCharacterCodeBtn(wndHandler, wndControl)
	g_arActors.primary:SetBySliderCodes(self.wndCreateCodeEntry:GetText(), self.eClass)
	g_arActors.shadow:SetBySliderCodes(self.wndCreateCodeEntry:GetText(), self.eClass)
	self.wndCreateCode:Show(false)
	self:FillCustomizePagination()
end

function Character:HelperCustomizationConfirmEvent(wndHandler)
	local strEvent = wndHandler:GetData().strEvent
	
	if strEvent == "OnPresetBtn" then
		self:OnPresetBtn(wndHandler, wndHandler)
	elseif strEvent == "OnRandomizeCharacterLook" then
		self:OnRandomizeCharacterLook()
	end
end

function Character:OnConfirmCustomizationChange(wndHandler, wndControl)
	if wndHandler ~= wndControl or not wndHandler:GetData() then
		return
	end
	
	local tData = wndHandler:GetData()
	if self.bCustomizationChanged then
		self.wndCustomizationConfirmAlert:Invoke()
		self.wndCustomizationConfirmAlert:FindChild("ConfirmBtn"):SetData(tData)
	else
		self:HelperCustomizationConfirmEvent(wndHandler)
	end
end

function Character:OnConfirmClearCustomization(wndHandler, wndControl)
	self.wndCustomizationConfirmAlert:Close()
	
	local tData = wndHandler:GetData()
	if wndHandler ~= wndControl or not tData then
		return
	end
	
	self.bCustomizationChanged = false
	self:HelperCustomizationConfirmEvent(wndHandler)
end

function Character:OnCancelClearCustomization(wndHandler, wndControl)
	self.wndCustomizationConfirmAlert:Close()
end

function Character:OnPresetBtn(wndHandler, wndControl)
	if wndHandler ~= wndControl or not wndHandler:GetData() then
		return
	end
	
	local ePreset = wndHandler:GetData().ePreset
	local tPresets = g_arActors.primary:GetPresetSliderCodes()
	if not tPresets then
		return
	end

	local strPreset = ePreset == keCustomizationPreset.First and tPresets[keCustomizationPreset.First] or tPresets[keCustomizationPreset.Second]
	if strPreset and strPreset ~= "" then
		g_arActors.primary:SetBySliderCodes(strPreset, self.eClass)
		g_arActors.shadow:SetBySliderCodes(strPreset, self.eClass)
	end

	self:FillCustomizePagination()
end

---------------------------------------------------------------------------------------------------
-- Character Customize Character
---------------------------------------------------------------------------------------------------
function Character:OnShowCustomizeToggle()
	self.ePageToShow = keTutorialTab.Customize
	self:ShowCorrectTabPage()
end

function Character:FillCustomizePagination()
	self:StoreCurrentCharacterLook()

	self.arPreviousCharacterOptions = {} -- build a table of defaults for the character. Allows us to undo.
	self.arCustomizePaginationBtns = {}
	self.wndCustPaginationList:FindChild("Content"):DestroyChildren()

	self:FillCustomizeBoneOptions() -- set up bone scaling

	for i, wnd in pairs(self.arCustomizePaginationBtns) do
		wnd:Destroy()
	end

	local arCurrentLooks = g_arActors.primary:GetLooks()

	if self.arCustomizeLookOptions == nil or #self.arCustomizeLookOptions < 1  then
		self.wndCustomizeContent:Show(false)
		return
	elseif self.arCustomizeLookOptions ~= arCurrentLooks then
		self.arCustomizeLookOptions = arCurrentLooks
	end

	--Want the options to appear in order of the nDisplayIndex.
	table.sort(self.arCustomizeLookOptions, function(a,b) return a.nDisplayIndex < b.nDisplayIndex end)

	local nListHeight = 0
	for idx, option in pairs(self.arCustomizeLookOptions) do
		local wndCustomizationEntry = Apollo.LoadForm(self.xmlDoc, ktCustomizeFaceOptions[option.sliderId] and "CustomizePaginationEntryBones" or "CustomizePaginationEntry", self.wndCustPaginationList:FindChild("Content"), self)
		wndCustomizationEntry:SetData(option)
		
		local wndCustomizePaginationBtn = wndCustomizationEntry:FindChild("CustomizePaginationBtn")
		wndCustomizePaginationBtn:SetData(option)
		wndCustomizePaginationBtn:SetText("   " .. option.name)

		table.insert(self.arCustomizePaginationBtns, wndCustomizationEntry)

		local t = {option, option.valueIdx} -- needs to be updated if the player modifies, then goes into create
		table.insert(self.arPreviousCharacterOptions, t)  -- build a table of defaults for the character. Allows us to completely undo.

		local nRecLeft, nRecTop, nRecRight, nRecBottom = wndCustomizationEntry:GetRect()
		local nHeight = nRecBottom - nRecTop
		nListHeight = nListHeight + nHeight
		if Apollo.GetConsoleVariable("ui.createScreenShowSliderValues") == true then
			wndCustomizationEntry:FindChild("DebugLabel"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_SliderOptions"), option.sliderId, option.valueIdx))
		end
	end

	-- the frame is v-anchored to .5 top and bottom
	-- the list is v-anchored to 0 and 1
	local wndList = self.wndCustPaginationList:FindChild("Content")
	local nLeft, nTop, nRight, nBottom = wndList:GetAnchorOffsets()
	local nLeftFrame, nTopFrame, nRightFrame, nBottomFrame = self.wndCustPaginationList:GetAnchorOffsets()
	local nTotalHeight = nListHeight + nTop - nBottom

	-- self.wndCustPaginationList:SetAnchorOffsets(nLeftFrame, -nTotalHeight/2, nRightFrame, nTotalHeight/2)

	self.wndCustPaginationList:FindChild("Content"):ArrangeChildrenVert()

	local wndFirstOption = self.arCustomizePaginationBtns[1]
	self.wndCustomizeContent:SetData(wndFirstOption:GetData())
	self.wndCustOptionUndoBtn:SetData(wndFirstOption:GetData().valueIdx) -- set the old option to undo--]]
	self.iCurrentPage = 1
	self.wndCustOptionUndoBtn:Enable(false) -- disable undo until the player makes a change
	self:FillCustomizeOptions(true)
end

---------------------------------------------------------------------------------------------------
function Character:FillCustomizeOptions(bNoShow)
	self.wndCustOptionList:FindChild("CustomizeContent"):DestroyChildren()
	self.wndCustOptionList:FindChild("CustomizeContent"):RecalculateContentExtents()
	local tOption = self.wndCustomizeContent:GetData() -- putting data on the frame so we know which option we're changing
	self.arCustomizeOptionBtns = {}

	local nEntryHeight = 0
	local nSelPos = 0
	local wndSel = nil
	for i = 1, tOption.count do  -- count is the number of choices for an option
		local wnd = Apollo.LoadForm(self.xmlDoc, "CustomizeOptionEntry", self.wndCustOptionList:FindChild("CustomizeContent"), self)
		g_arActors.shadow:SetLook(tOption.sliderId, tOption.values[ i ] ) -- set the shadow actor to each option

		local wndCustomizeEntryPreview = wnd:FindChild("CustomizeEntryPreview")
		wndCustomizeEntryPreview:SetCostumeToActor(g_arActors.shadow) -- set a portrait on each button
		wndCustomizeEntryPreview:SetItemsByCreationId( self.arCharacterCreateOptions[self.characterCreateIndex].characterCreateId )
		wndCustomizeEntryPreview:SetModelSequence(PreGameLib.CodeEnumModelSequence.DefaultStartScreenLoop01)
		wndCustomizeEntryPreview:SetCamera(ktCustomizeOptionsZoomOut[tOption.sliderId] and "Datachron" or "Portrait")

		wnd:SetData(i)
		table.insert(self.arCustomizeOptionBtns, wnd)
		if i == tOption.valueIdx then --value.Idx is the current setting for an option
			wndSel = wnd
			wnd:FindChild("CustomizeEntryBtn"):SetCheck(true)
			nSelPos = i
		end

		nEntryHeight = wnd:GetHeight()
	end

	if tOption.sliderId == 1 then -- faces
		self.wndCustOptionUndoBtn:Show(true)

		-- get current slider positions here for undo (clears on pagination)
		self.arPreviousSliderOptions = {}
		for i, sliderWnd in pairs(self.arWndCustomizeBoneOptions) do
			sliderWnd:FindChild("SliderUndoBtn"):Show(false)
			local t = {}
			t.type = sliderWnd:GetData()
			t.value = sliderWnd:FindChild("CustomizeBoneSliderBar"):GetValue() -- this info does exist on a separate table; using the slider to ensure the data matches the model
			sliderWnd:FindChild("Value"):SetText(string.format("%.2f", t.value))
			sliderWnd:FindChild("SliderProgBar"):SetProgress(t.value + 1)
			table.insert(self.arPreviousSliderOptions, t)
		end

	else
		self.wndCustOptionUndoBtn:Show(true)
		self.wndCustAdvanced:Show(false)
	end

	g_arActors.shadow:SetLook(tOption.sliderId, tOption.values[tOption.valueIdx] ) -- return to the initial model from opening this panel
	self.wndCustOptionList:FindChild("CustomizeContent"):ArrangeChildrenTiles()

	if wndSel then
		self.wndCustOptionList:FindChild("CustomizeContent"):EnsureChildVisible(wndSel)
	end

	if bNoShow then
		self.wndCustOptionList:Show(false)
	else
		self.wndCustOptionList:Show(true)
		self.wndCustOptionList:FindChild("CustomizeContent"):SetVScrollPos(((nSelPos / 2) * nEntryHeight) - nEntryHeight)
	end
end

function Character:HelperZoomIntoCharacterFace()
	if self.bZoomedIntoFace then
		return
	end

	g_arActors.mainScene:Animate(0, g_cameraAnimation, 0, false, true, knZoomAnimationSpeed, g_cameraSlider)
	self.bReverseAnimation = false
	self.bZoomedIntoFace = true
	self.bZoomAnimating = true
	g_cameraSlider = 1
end

function Character:HelperZoomOutToCharacterBody()
	if not self.bZoomedIntoFace then
		return
	end

	if self.ePageToShow == keTutorialTab.Customize or self.ePageToShow == keTutorialTab.Finalize then
		g_arActors.mainScene:Animate(0, g_cameraAnimation, 0, false, true, -knZoomAnimationSpeed, g_cameraSlider)
		g_cameraSlider = 0 --Setting after animation so that we start animation from the last camera slider position.
		self.bReverseAnimation = true
	else
		g_cameraSlider = 0 --Instantaneously set them zoomed out.
		g_arActors.mainScene:Animate(0, g_cameraAnimation, 0, true, false, knInstantAnimationSpeed, g_cameraSlider)
	end
	self.bZoomedIntoFace = false
	self.bZoomAnimating = true
end

---------------------------------------------------------------------------------------------------
function Character:OnCustomizePagination(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self.wndLastCustomizationPageBtn = wndControl
	local tOption = wndControl:GetData()
	if tOption and ktCustomizeOptionsZoomOut[tOption.sliderId] then
		self:HelperZoomOutToCharacterBody()
	else
		self:HelperZoomIntoCharacterFace()
	end

	for idx, window in pairs(self.arCustomizePaginationBtns) do -- reset the buttons; programatic radio sets won't do this by themselves
		local iValue = window:GetData()
		window:FindChild("CustomizePaginationBtn"):SetCheck(false)

		if tOption == iValue then
			window:FindChild("CustomizePaginationBtn"):SetCheck(true)
			self.iCurrentPage = idx
		end
	end

	self.wndCustomizeContent:SetData(tOption)
	self.wndCustOptionUndoBtn:SetData(tOption.valueIdx) -- set the old option to undo
	self.wndCustOptionUndoBtn:Enable(false) -- disable undo until the player makes a change

	self:FillCustomizeOptions()
end

---------------------------------------------------------------------------------------------------
function Character:OnCustomizePaginationUncheck(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self.wndCustOptionList:Show(false)
end

---------------------------------------------------------------------------------------------------
function Character:OnCustomizeOption(wndHandler, wndCtrl)
	local wndContainer = wndCtrl:GetParent()
	local iEntry = wndContainer:GetData()
	local tOption = self.wndCustomizeContent:GetData()
	local iPrevious = self.wndCustOptionUndoBtn:GetData() -- get the initial value

	for idx, window in pairs(self.arCustomizeOptionBtns) do -- reset the buttons; programatic radio sets won't do this by themselves
		window:FindChild("CustomizeEntryBtn"):SetCheck(false)
		--window:FindChild("CustomizeBack"):SetSprite(kcrNormalBack)
	end

	self.bCustomizationChanged = true
	wndCtrl:SetCheck(true) -- set the chosen one
	--wndContainer:FindChild("CustomizeBack"):SetSprite(kcrSelectedBack)

	tOption.valueIdx = iEntry
	g_arActors.primary:SetLook(tOption.sliderId, tOption.values[ tOption.valueIdx ] )	-- set new
	g_arActors.shadow:SetLook(tOption.sliderId, tOption.values[ tOption.valueIdx ] )	-- set new
	self.arCustomizeLookOptions = g_arActors.primary:GetLooks()
	self.wndCustOptionUndoBtn:Enable(iEntry ~= iPrevious)
	
	if Apollo.GetConsoleVariable("ui.createScreenShowSliderValues") == true then
		local wndBtn = self.wndCustPaginationList:FindChild("Content"):FindChildByUserData(tOption)
		wndBtn:FindChild("DebugLabel"):SetText(PreGameLib.String_GetWeaselString(Apollo.GetString("Pregame_SliderOptions"), tOption.sliderId, tOption.valueIdx))
	end

	self.bChangedDetailOrSwitchedTab = true
	
	--Selecting a new face should reset the bones.
	if tOption.sliderId == 1 then
		self:OnResetSlidersBtn()
	end
end

---------------------------------------------------------------------------------------------------
function Character:OnUndoBtn(wndHandler, wndCtrl)
	local iPrevious = wndCtrl:GetData() -- get the previous selection's number
	local option = self.wndCustomizeContent:GetData()	-- get the type we're viewing

	for idx, window in pairs(self.arCustomizeOptionBtns) do -- reset the buttons
		local wndValue = window:GetData()
		if iPrevious == wndValue then
			window:FindChild("CustomizeEntryBtn"):SetCheck(true)
			--window:FindChild("CustomizeBack"):SetSprite(kcrSelectedBack)
		else
			window:FindChild("CustomizeEntryBtn"):SetCheck(false)
			--window:FindChild("CustomizeBack"):SetSprite(kcrNormalBack)
		end
	end

	option.valueIdx = iPrevious
	g_arActors.primary:SetLook(option.sliderId, option.values[ option.valueIdx ] )	 -- set previous
	g_arActors.shadow:SetLook(option.sliderId, option.values[ option.valueIdx ] )	 -- set previous
	self.wndCustOptionUndoBtn:Enable(false)
end

---------------------------------------------------------------------------------------------------
function Character:FillCustomizeBoneOptions()
	for idx, wnd in ipairs(self.arWndCustomizeBoneOptions) do
		wnd:Destroy()
	end
	self.arWndCustomizeBoneOptions = {}

	local wndHolder = self.wndCustAdvanced:FindChild("SliderListWindow")

	for i, bone in ipairs(self.arCustomizeBoneOptions) do -- we want these to appear in order
		local wnd = Apollo.LoadForm(self.xmlDoc, "CustomizeBoneOption", wndHolder, self)
		wnd:FindChild("Label"):SetText(bone.name)
		wnd:SetData(bone.sliderId)
		wnd:FindChild("CustomizeBoneSliderBar"):SetValue(bone.value)
		wnd:FindChild("Value"):SetText(string.format("%.2f", bone.value))
		wnd:FindChild("SliderProgBar"):SetFloor(0)
		wnd:FindChild("SliderProgBar"):SetMax(2)
		wnd:FindChild("SliderProgBar"):SetProgress(bone.value + 1)
		table.insert(self.arWndCustomizeBoneOptions, wnd)
	end

	wndHolder:ArrangeChildrenVert()
end

---------------------------------------------------------------------------------------------------
function Character:OnToggleFaceSliderCheck(wndHandler, wndCtrl)

	for idx, entry in pairs(self.wndCustPaginationList:FindChild("Content"):GetChildren()) do
		if entry:FindChild("CustomizePaginationBtn") ~= nil then
			entry:FindChild("CustomizePaginationBtn"):SetCheck(false)
		end
	end

	self.wndCustPaginationList:FindChild("SideGlow"):Show(true)
	self.wndCustOptionList:Show(false)
	self.wndCustAdvanced:Show(true)
	self:HelperZoomIntoCharacterFace()
end

function Character:OnToggleFaceSliderUncheck(wndHandler, wndCtrl)
	self.wndCustAdvanced:Show(false)
	self.wndCustPaginationList:FindChild("SideGlow"):Show(false)
end

---------------------------------------------------------------------------------------------------
function Character:OnSliderBarChanging(wnd, wndHandler, value, oldvalue)
	local wndParent = wnd:GetParent()
	wndParent:FindChild("SliderProgBar"):SetProgress(value + 1)
	return true
end


---------------------------------------------------------------------------------------------------
function Character:OnSliderBarChanged(wnd, wndHandler, value, oldvalue)
	local wndParent = wnd:GetParent()
	local option = wndParent:GetData()

	if g_arActors.primary then
		g_arActors.primary:SetBone(option, value)
	end

	if g_arActors.shadow then
		g_arActors.shadow:SetBone(option, value)
	end

	local bHit = false
	for i, sliderEntry in pairs(self.arPreviousSliderOptions) do
		if option == sliderEntry.type then
			if value ~= sliderEntry.value then
				wndParent:FindChild("SliderUndoBtn"):SetData(sliderEntry.value)
				wndParent:FindChild("SliderUndoBtn"):Show(true)
			else
				wndParent:FindChild("SliderUndoBtn"):Show(false)
			end

			wndParent:FindChild("Value"):SetText(string.format("%.2f", value))
			bHit = true
		end
	end

	self.wndCustPaginationList:FindChild("BoneClearIcon"):Show(true)

	if not bHit then -- Error state, sometimes for the first pick
		self:OnResetSlidersBtn()
	end

	self.arCustomizeBoneOptions	= g_arActors.primary:GetBones() -- update the model
	self.bCustomizationChanged = true
end

---------------------------------------------------------------------------------------------------
function Character:OnSliderUndoBtn(wndHandler, wndCtrl)
	local wndParent = wndCtrl:GetParent()
	local option = wndParent:GetData()
	local value = wndCtrl:GetData()

	wndParent:FindChild("CustomizeBoneSliderBar"):SetValue(value)
	wndParent:FindChild("Value"):SetText(string.format("%.2f", value))
	wndParent:FindChild("SliderProgBar"):SetProgress(value + 1)

	if g_arActors.primary then
		g_arActors.primary:SetBone(option, value)
	end

	if g_arActors.shadow then
		g_arActors.shadow:SetBone(option, value)
	end

	wndCtrl:Show(false)

	self.arCustomizeBoneOptions	= g_arActors.primary:GetBones() -- update the model
end

---------------------------------------------------------------------------------------------------
function Character:OnResetSlidersBtn()
	self.arPreviousSliderOptions = {}
	for i, sliderWnd in pairs(self.arWndCustomizeBoneOptions) do
		sliderWnd:FindChild("CustomizeBoneSliderBar"):SetValue(0)
		sliderWnd:FindChild("Value"):SetText("0.00")
		sliderWnd:FindChild("SliderUndoBtn"):Show(false)
		sliderWnd:FindChild("SliderProgBar"):SetProgress(1)
		local t = {}
		t.type = sliderWnd:GetData()
		t.value = sliderWnd:FindChild("CustomizeBoneSliderBar"):GetValue() -- this info does exist on a separate table; using the slider to ensure the data matches the model
		table.insert(self.arPreviousSliderOptions, t)
	end

	self:ResetBones()
	self.arCustomizeBoneOptions	= g_arActors.primary:GetBones() -- this is a "permanent" change so we reset the table
	if self.wndCustAdvancedResetPopup:IsShown() then
		self.wndCustAdvancedResetPopup:Show(false)
	end
end

---------------------------------------------------------------------------------------------------
function Character:ResetBones() -- don't reset the table so the player can toggle back and forth
	for i, bone in ipairs(self.arCustomizeBoneOptions) do
		g_arActors.primary:SetBone(bone.sliderId, 0)
		g_arActors.shadow:SetBone(bone.sliderId, 0)
	end
	self:StoreCurrentCharacterLook()
	self.wndCustPaginationList:FindChild("BoneClearIcon"):Show(false)
end

function Character:OnConfirmResetBonesWindowClose(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	self.wndCustAdvancedResetPopup:Show(false)
end
	
---------------------------------------------------------------------------------------------------
function Character:OnOptionEnter(wndHandler, wndControl)
	--wndControl:ChangeArt("CRB_TalentSprites:btnTalentSelect")
end

function Character:OnOptionExit(wndHandler, wndControl)
	--wndControl:ChangeArt(kcrNormalButton)
end

---------------------------------------------------------------------------------------------------
-- Options Buttons
---------------------------------------------------------------------------------------------------
function Character:OnLoginOptions(wndHandler, wndControl)
	PreGameLib.InvokeOptions()
end

---------------------------------------------------------------------------------------------------
-- Credit Button
---------------------------------------------------------------------------------------------------
function Character:OnCredits(wndHandler, wndControl)
	PreGameLib.OnCredits()
end

---------------------------------------------------------------------------------------------------
-- EULA Button
---------------------------------------------------------------------------------------------------
function Character:OnEULA(wndHandler, wndControl)
	PreGameLib.OnEULA()
end

---------------------------------------------------------------------------------------------------
-- Create Fail Events and Handlers
---------------------------------------------------------------------------------------------------
function Character:OnCreateCharacterFailed(nReason)

	local strReason = Apollo.GetString("Pregame_DefaultError")


	if nReason == PreGameLib.CodeEnumCharacterModifyResults.CreateFailed_UniqueName then
		strReason = Apollo.GetString("Pregame_NameUnavailable")
		g_controls:FindChild("FirstNameEntryForm:EnterNameEntry"):SetFocus()
	elseif nReason == PreGameLib.CodeEnumCharacterModifyResults.CreateFailed_CharacterOnline then
		strReason = Apollo.GetString("PreGame_CreateErrorCharacterOnline")
	elseif nReason == PreGameLib.CodeEnumCharacterModifyResults.CreateFailed_AccountFull then
		strReason = Apollo.GetString("Pregame_AccountFull")
	elseif nReason == PreGameLib.CodeEnumCharacterModifyResults.CreateFailed_InvalidName then
		strReason = Apollo.GetString("Pregame_InvalidError")
		g_controls:FindChild("FirstNameEntryForm:EnterNameEntry"):SetFocus()
	elseif nReason == PreGameLib.CodeEnumCharacterModifyResults.CreateFailed_Faction then
		strReason = Apollo.GetString("Pregame_OpposingFaction")
	elseif nReason == PreGameLib.CodeEnumCharacterModifyResults.CreateFailed_Internal  then
		strReason = Apollo.GetString("Pregame_DefaultError")
	elseif nReason == PreGameLib.CodeEnumCharacterModifyResults.CreateFailed then
		strReason = Apollo.GetString("Pregame_DefaultError")
	end


	self.wndCreateFailed:FindChild("CreateError_Body"):SetText(strReason)
	Apollo.CreateTimer("CreateFailedTimer", 5.0, false)
	Apollo.StartTimer("CreateFailedTimer")
	self.wndCreateFailed:Show(true)
	
	return true
end

function Character:OnCreateFailedTimer()
	self.wndCreateFailed:Show(false)
end

function Character:OnCreateErrorClose(wndHandler, wndCtrl)
	Apollo.StopTimer("CreateFailedTimer")
	self.wndCreateFailed:Show(false)
end

function Character:OnRealmBroadcast(strRealmBroadcast, nTier)
	self:HelperServerMessages(strRealmBroadcast)
	if nTier < 2 then
		Apollo.StopTimer("RealmBroadcastTimer")
		Apollo.StartTimer("RealmBroadcastTimer")

		self.wndRealmBroadcast:FindChild("RealmMessage_Body"):SetText(strRealmBroadcast)
		self.wndRealmBroadcast:Show(true)
	end
end

function Character:OnRealmBroadcastTimer()
	self.wndRealmBroadcast:Show(false)
end

function Character:OnRealmBroadcastClose( wndHandler, wndControl, eMouseButton )
	Apollo.StopTimer("RealmBroadcastTimer")
	self.wndRealmBroadcast:Show(false)
end


---------------------------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------------------------
function Character:BuildOptionsMap()
	self.mapCharacterCreateOptions = {}
	for idx, tCharacterOption in pairs(self.arCharacterCreateOptions)do
		if not self.mapCharacterCreateOptions[tCharacterOption.factionId] then
			self.mapCharacterCreateOptions[tCharacterOption.factionId] = {}
		end
		if not self.mapCharacterCreateOptions[tCharacterOption.factionId][tCharacterOption.raceId] then
			self.mapCharacterCreateOptions[tCharacterOption.factionId][tCharacterOption.raceId] = {}
		end
		if not self.mapCharacterCreateOptions[tCharacterOption.factionId][tCharacterOption.raceId][tCharacterOption.classId] then
			self.mapCharacterCreateOptions[tCharacterOption.factionId][tCharacterOption.raceId][tCharacterOption.classId] = {}
		end

		self.mapCharacterCreateOptions[tCharacterOption.factionId][tCharacterOption.raceId][tCharacterOption.classId][tCharacterOption.genderId] = idx
	end
end

--[[
It is possible to attempt to find a character create Id when one or more of these pieces is invalid.
This can happen when a selection hasn't been made yet.
The Goal here is to replace invalid options with ones we know are valid until the user has selected
valid information. That way, the character model can still be drawn. The model uses the information
the user has selected, not these replacement values.
]]--
function Character:GetCharacterCreateId(eFaction, eRace, eClass, eGender)
	if not self.mapCharacterCreateOptions then
		self:BuildOptionsMap()
	end

	if eFaction == nil or eRace == nil or self.mapCharacterCreateOptions[eFaction][eRace] == nil then
		return 0
	end

    --We have an invalid Class, use the first entry that is valid temporarily.
	if eClass == nil or self.mapCharacterCreateOptions[eFaction][eRace][eClass] == nil then
		eClass = next(self.mapCharacterCreateOptions[eFaction][eRace])
	end

	--We have an invalid Gender, use the first entry that is valid temporarily.
	if eGender == nil or self.mapCharacterCreateOptions[eFaction][eRace][eClass][eGender] == nil then
		eGender = next(self.mapCharacterCreateOptions[eFaction][eRace][eClass])
	end

	return self.mapCharacterCreateOptions[eFaction][eRace][eClass][eGender]
end

function Character:HelperHideMenus()
	self.wndRacePicker:Show(false)
	self.wndClassPicker:Show(false)
	self.wndPathPicker:Show(false)
	self.wndCreateFailed:Show(false)

	self.wndCustOptionList:Show(false)
	self.wndCustAdvanced:Show(false)

	local wndOptionToggles = self.wndControlFrame:FindChild("OptionToggles")
	wndOptionToggles:FindChild("RaceOptionToggle:Btn"):SetCheck(false)
	wndOptionToggles:FindChild("ClassOptionToggle:Btn"):SetCheck(false)
	wndOptionToggles:FindChild("PathOptionToggle:Btn"):SetCheck(false)

	self.wndCustPaginationList:FindChild("SideGlow"):Show(false)

	for idx, entry in pairs(self.wndCustPaginationList:FindChild("Content"):GetChildren()) do
		if entry:FindChild("CustomizePaginationBtn") ~= nil then
			entry:FindChild("CustomizePaginationBtn"):SetCheck(false)
		end
	end
end

function Character:HelperConvertToTime(nArg)
	local nMinutes = nArg/60
	local nHours = nMinutes/60
	local strTime = ""

	if nMinutes > 1 then -- at least one minute
		if nHours > 1 then
			local nMinutesExcess = nMinutes - math.floor(nHours)*60
			strMinutes = PreGameLib.String_GetWeaselString(Apollo.GetString("BuildMap_Mins"), math.floor(nMinutesExcess))
			strTime = PreGameLib.String_GetWeaselString(Apollo.GetString("BuildMap_Hours"), math.floor(nHours)) .. ", " .. strMinutes
		else
			strTime = PreGameLib.String_GetWeaselString(Apollo.GetString("BuildMap_Mins"), math.floor(nMinutes))
		end
	else
		strTime = Apollo.GetString("GuildPerk_LessThanAMinute")
	end

	return strTime
end

function Character:HelperServerMessages(strExtra)
	local strAllMessage = ""
	local strColor = "BurntYellow"
	if CharacterScreenLib.WasDisconnectedForLag() then
		strColor = "Reddish"
		strAllMessage = Apollo.GetString("CharacterSelect_LagDisconnectExplain")
	else
		if self.arServerMessages then
			for idx, strMessage in ipairs(self.arServerMessages) do
				strAllMessage = strAllMessage .. strMessage .. "\n"
			end
		end
		if strExtra ~= nil then
			strAllMessage = strAllMessage .. strExtra .. "\n"
		end
	end

	self.wndServerMessage:SetAML(string.format("<T Font=\"CRB_Interface10_B\" TextColor=\"%s\">%s</T>", strColor, strAllMessage))
	self.wndServerMessagesContainer:Show(Apollo.StringLength(strAllMessage or "") > 0)

	local nWidth, nHeight = self.wndServerMessage:SetHeightToContentHeight()
	local nLeft, nTop, nRight, nBottom = self.wndServerMessagesContainer:GetAnchorOffsets()
	self.wndServerMessagesContainer:SetAnchorOffsets(nLeft, nTop, nRight, nTop + math.min(75, nHeight + 5))
end

function Character:OnRealmBtn(wndHandler, wndControl)
	CharacterScreenLib.ExitToRealmSelect()
end

function Character:OnRandomLastName(characterCreateIndex)

	local nRaceId = self.arCharacterCreateOptions[self.characterCreateIndex].raceId
	local nFactionId = self.arCharacterCreateOptions[self.characterCreateIndex].factionId
	local nGenderId = self.arCharacterCreateOptions[self.characterCreateIndex].genderId
			
	local tName = PreGameLib.GetRandomName(nRaceId, nGenderId, nFactionId)
	
	self.wndLastNameEntry:SetText(tName.strLastName)
	self.wndFirstNameEntry:SetText(tName.strFirstName)
	
	self:OnNameChanged()
end

function Character:OnEntitlementUpdate(tEntitlementInfo)
	self.arCharacterCreateOptions = CharacterScreenLib.GetCharacterCreation(PreGameLib.CodeEnumCharacterCreationStart.PreTutorial)
	self:HelperLoadClassAndRaceRelations()
	
	if self.ePendingClass then
		PreGameLib.Event_FireGenericEvent("CloseStore")
		g_eState = LuaEnumState.Create

		local wndBtns = self.wndClassContent:FindChild("Buttons")
		for idx, wndClassContainer in pairs(wndBtns:GetChildren()) do
			local wndClassBtn = wndClassContainer:FindChild("Btn")
			if wndClassBtn:GetData() == self.ePendingClass then
				self:OnClassBtnCheck(wndClassBtn, wndClassBtn, 0, false)
				return
			end
		end
	elseif self.ePendingRace then
		PreGameLib.Event_FireGenericEvent("CloseStore")
		g_eState = LuaEnumState.Create

		local wndBtns = self.wndRaceContent:FindChild("Buttons")
		for idx, wndRaceContainer in pairs(wndBtns:GetChildren()) do
			local wndRaceBtn = wndRaceContainer:FindChild("Btn")
			if wndRaceBtn:GetData() == self.ePendingRace then
				self:OnRaceBtnCheck(wndRaceBtn, wndRaceBtn, false)
				return
			end
		end
	end
end

function Character:OnStoreCatalogReady()
	self.arCharacterCreateOptions = CharacterScreenLib.GetCharacterCreation(PreGameLib.CodeEnumCharacterCreationStart.PreTutorial)
	self:HelperLoadClassAndRaceRelations()

	if g_eState == LuaEnumState.Create then
		self:SetCreateForms()
	end
end

---------------------------------------------------------------------------------------------------
-- Character instance
---------------------------------------------------------------------------------------------------
local CharacterInst = Character:new()
CharacterInst:Init()
