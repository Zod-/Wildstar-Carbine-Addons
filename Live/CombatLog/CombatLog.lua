-----------------------------------------------------------------------------------------------
-- Client Lua Script for CombatLog
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Apollo"
require "Window"
require "Unit"
require "Spell"
require "GameLib"
require "ChatSystemLib"
require "ChatChannelLib"
require "CombatFloater"
require "GroupLib"

local CombatLog = {}
local kstrFontBold						= "CRB_InterfaceMedium_BB" -- TODO TEMP, allow customizing
local kstrLootColor						= "ffc0c0c0"
local kstrColorCombatLogOutgoing		= "ff2f94ac"
local kstrColorCombatLogIncomingGood	= "ff4bacc6"
local kstrColorCombatLogIncomingBad		= "ffff4200"
local kstrColorCombatLogPathXP			= "fffff533"
local kstrColorCombatLogRep				= "fffff533"
local kstrColorCombatLogXP				= "fffff533"
local kstrColorCombatLogUNKNOWN			= "ffffffff"
local kstrCurrencyColor					= "fffff533"
local kstrStateColor					= "ff9a8460"
local kstEquipColor						= "ffc0c0c0"

local knSaveVersion						= 1

function CombatLog:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function CombatLog:Init()
	Apollo.RegisterAddon(self, true, Apollo.GetString("CombatLogOptions_CombatLogBtn"))
end

function CombatLog:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("CombatLog.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function CombatLog:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("CombatLogAbsorption", 				"OnCombatLogAbsorption", self)
	Apollo.RegisterEventHandler("CombatLogCCState", 				"OnCombatLogCCState", self)
	Apollo.RegisterEventHandler("CombatLogCCStateBreak", 			"OnCombatLogCCStateBreak", self)
	Apollo.RegisterEventHandler("CombatLogDamage", 					"OnCombatLogDamage", self)
	Apollo.RegisterEventHandler("CombatLogDamageShields", 			"OnCombatLogDamageShields", self)
	Apollo.RegisterEventHandler("CombatLogReflect", 				"OnCombatLogReflect", self)
	Apollo.RegisterEventHandler("CombatLogMultiHit", 				"OnCombatLogMultiHit", self)
	Apollo.RegisterEventHandler("CombatLogMultiHitShields", 		"OnCombatLogMultiHitShields", self)
	Apollo.RegisterEventHandler("CombatLogFallingDamage", 			"OnCombatLogFallingDamage", self)
	Apollo.RegisterEventHandler("CombatLogDelayDeath", 				"OnCombatLogDelayDeath", self)
	Apollo.RegisterEventHandler("CombatLogDispel", 					"OnCombatLogDispel", self)
	Apollo.RegisterEventHandler("CombatLogHeal", 					"OnCombatLogHeal", self)
	Apollo.RegisterEventHandler("CombatLogMultiHeal", 				"OnCombatLogMultiHeal", self)
	Apollo.RegisterEventHandler("CombatLogModifyInterruptArmor", 	"OnCombatLogModifyInterruptArmor", self)
	Apollo.RegisterEventHandler("CombatLogTransference", 			"OnCombatLogTransference", self)
	Apollo.RegisterEventHandler("CombatLogVitalModifier", 			"OnCombatLogVitalModifier", self)
	Apollo.RegisterEventHandler("CombatLogDeflect", 				"OnCombatLogDeflect", self)
	Apollo.RegisterEventHandler("CombatLogImmunity", 				"OnCombatLogImmunity", self)
	Apollo.RegisterEventHandler("CombatLogInterrupted", 			"OnCombatLogInterrupted", self)
	Apollo.RegisterEventHandler("CombatLogKillStreak", 				"OnCombatLogKillStreak", self)
	Apollo.RegisterEventHandler("CombatLogKillPVP", 				"OnCombatLogKillPVP", self)
	Apollo.RegisterEventHandler("CombatLogDeath", 					"OnCombatLogDeath", self)
	Apollo.RegisterEventHandler("CombatLogResurrect", 				"OnCombatLogResurrect", self)
	Apollo.RegisterEventHandler("CombatLogStealth", 				"OnCombatLogStealth", self)
	Apollo.RegisterEventHandler("CombatLogMount", 					"OnCombatLogMount", self)
	Apollo.RegisterEventHandler("CombatLogPet", 					"OnCombatLogPet", self)
	Apollo.RegisterEventHandler("CombatLogExperience", 				"OnCombatLogExperience", self)
	Apollo.RegisterEventHandler("CombatLogElderPointsLimitReached", "OnCombatLogElderPointsLimitReached", self)
	Apollo.RegisterEventHandler("CombatLogDurabilityLoss", 			"OnCombatLogDurabilityLoss", self)
	Apollo.RegisterEventHandler("CombatLogModifying", 				"OnCombatLogModifying", self)
	Apollo.RegisterEventHandler("CombatLogLAS",						"OnCombatLogLAS", self)
	Apollo.RegisterEventHandler("CombatLogBuildSwitch",				"OnCombatLogBuildSwitch", self)
	Apollo.RegisterEventHandler("CombatLogHealingAbsorption", 		"OnCombatLogHealingAbsorption", self)

	Apollo.RegisterEventHandler("CombatLogString", 					"PostOnChannel", self)
	Apollo.RegisterEventHandler("UpdatePathXp", 					"OnPathExperienceGained", self)
	Apollo.RegisterEventHandler("FactionFloater", 					"OnFactionFloater", self)
	Apollo.RegisterEventHandler("CombatLogLifeSteal", 				"OnCombatLogLifeSteal", self)

	Apollo.RegisterEventHandler("ChangeWorld", 						"OnChangeWorld", self)
	Apollo.RegisterEventHandler("PetSpawned", 						"OnPetStatusUpdated", self)
	Apollo.RegisterEventHandler("PetDespawned", 					"OnPetStatusUpdated", self)
	Apollo.RegisterEventHandler("PlayerEquippedItemChanged", 			"OnPlayerEquippedItemChanged", self)
	
	self.tTypeMapping =
	{
		[GameLib.CodeEnumDamageType.Physical] 	= Apollo.GetString("DamageType_Physical"),
		[GameLib.CodeEnumDamageType.Tech] 		= Apollo.GetString("DamageType_Tech"),
		[GameLib.CodeEnumDamageType.Magic] 		= Apollo.GetString("DamageType_Magic"),
		[GameLib.CodeEnumDamageType.Fall] 		= Apollo.GetString("DamageType_Fall"),
		[GameLib.CodeEnumDamageType.Suffocate] 	= Apollo.GetString("DamageType_Suffocate"),
		["Unknown"] 							= Apollo.GetString("CombatLog_SpellUnknown"),
		["UnknownDamageType"] 					= Apollo.GetString("CombatLog_SpellUnknown"),
	}

	self.tTypeColor =
	{
		[GameLib.CodeEnumDamageType.Heal] 			= "ff00ff00",
		[GameLib.CodeEnumDamageType.HealShields] 	= "ff00ffae",
	}

	self.crVitalModifier = "ffffffff"
	self.unitPlayer = nil
	self.tPetUnits = {}
	
	self.tCache =
	{
		TargetKilled = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrStateColor, Apollo.GetString("CombatLog_TargetKilled")),
		CombatLogDamage = {},
		CombatLogDamageShields = {},
		CombatLogReflect = {},
		CombatLogMultiHit = {},
		CombatLogMultiHitShields = {},
		CombatLogFallingDamage = {},
		CombatLogDeflect = {},
		CombatLogImmunity = {},
		CombatLogDispel = {},
		CombatLogHeal = {},
		CombatLogMultiHeal = {},
		CombatLogModifyInterruptArmor = {},
		CombatLogAbsorption = {},
		CombatLogHealingAbsorption = {},
		CombatLogVitalModifier = {},
		CombatLogCCStateSelf = {},
		CombatLogCCState = {},
		CombatLogLifeSteal = {},
		CombatLogTransference = {},
		CombatLogInterrupted = {},
		CombatLogKillStreak = {},
		CombatLogKillPVP = {},
		CombatLogCCStateBreak = {},
		CombatLogDelayDeath = {},
		CombatLogDeath = {},
		CombatLogStealth = {},
		CombatLogMount = {},
		CombatLogPet = {},
		CombatLogResurrect = {},
		CombatLogLAS = {},
		CombatLogBuildSwitch = {},
		CombatLogExperience = {},
		CombatLogElderPointsLimitReached = {},
		CombatLogDurabilityLoss = {},
		PathExperienceGained = {},
		FactionFloater = {},
		PlayerEquippedItemChanged = {},
	}
	
end

-----------------------------------------------------------------------------------------------
-- Needs Beneficial vs Not Beneficial
-----------------------------------------------------------------------------------------------

function CombatLog:OnCombatLogDamage(tEventArgs)
	-- Example Combat Log Message: 17:18: Alvin uses Mind Stab on Space Pirate for 250 Magic damage (Critical).
	local strDamageColor = self:HelperDamageColor(tEventArgs.eDamageType)
	local tTextInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)	
	
	-- System treats environment damage as coming from the player, so set the caster name and color correctly
	local bEnvironmentDmg = tTextInfo.strCaster == tTextInfo.strTarget
	if bEnvironmentDmg then
		tTextInfo.strColor = kstrColorCombatLogIncomingBad
	end
	
	if tEventArgs.unitTarget and tEventArgs.unitTarget:IsMounted() then
		tTextInfo.strTarget = String_GetWeaselString(Apollo.GetString("CombatLog_MountedTarget"), tTextInfo.strTarget)
	end
	
	local strDamageType
	if tEventArgs.eDamageType ~= nil then
		strDamageType = self.tTypeMapping[tEventArgs.eDamageType]
	else
		strDamageType = Apollo.GetString("CombatLog_UnknownDamageType")
	end
	
	local idx = 0x0
	if bEnvironmentDmg then
		idx = 0x1
	end
	
	if tEventArgs.bPeriodic then
		idx = idx + 0x2
	elseif tEventArgs.eEffectType == Spell.CodeEnumSpellEffectType.DistanceDependentDamage then
		idx = idx + 0x4
	elseif tEventArgs.eEffectType == Spell.CodeEnumSpellEffectType.DistributedDamage then
		idx = idx + 0x8
	end
	
	if tEventArgs.nShield > 0 then
		idx = idx + 0x10
	end
	
	if tEventArgs.nAbsorption > 0 then
		idx = idx + 0x20
	end
	
	if tEventArgs.nGlanceAmount > 0 then
		idx = idx + 0x40
	end
	
	if tEventArgs.nOverkill > 0 then
		idx = idx + 0x80
	end
	
	if tEventArgs.bTargetVulnerable then
		idx = idx + 0x100
	end
	
	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		idx = idx + 0x200
	end
	
	local strResult = self.tCache.CombatLogDamage[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageType, strDamageColor, tEventArgs.nDamageAmount, tEventArgs.nShield, tEventArgs.nAbsorption, tostring(tEventArgs.nGlanceAmount), tostring(tEventArgs.nOverkill)))
		
		if tEventArgs.bTargetKilled then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(self.tCache.TargetKilled, tTextInfo.strCaster, tTextInfo.strTarget), "")
		end
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - damage type
	6 - damage color
	7 - damage amount
	8 - shield amount
	9 - absorb amount
	10 - glance amount
	11 - overkill amount
	]]--
	
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseSkillUse"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })
	
	if bEnvironmentDmg then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_EnvironmentDmg"), { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })
	end
	
	local strDamageMethod = nil
	if tEventArgs.bPeriodic then
		strDamageMethod = Apollo.GetString("CombatLog_PeriodicDamage")
	elseif tEventArgs.eEffectType == Spell.CodeEnumSpellEffectType.DistanceDependentDamage then
		strDamageMethod = Apollo.GetString("CombatLog_DistanceDependent")
	elseif tEventArgs.eEffectType == Spell.CodeEnumSpellEffectType.DistributedDamage then
		strDamageMethod = Apollo.GetString("CombatLog_DistributedDamage")
	else
		strDamageMethod = Apollo.GetString("CombatLog_BaseDamage")
	end

	if strDamageMethod then
		strResult = String_GetWeaselString(strDamageMethod, { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$7c</T>' }, { strLiteral = '$5n' })
	end

	if tEventArgs.nShield > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageShielded"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$8c</T>' })
	end

	if tEventArgs.nAbsorption > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageAbsorbed"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$9c</T>' })
	end
	
	if tEventArgs.nGlanceAmount > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageGlanced"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$(10)</T>' })
	end

	if tEventArgs.nOverkill > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageOverkill"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$(11)</T>' })
	end

	if tEventArgs.bTargetVulnerable then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageVulnerable"), { strLiteral = strResult })
	end

	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Critical"), { strLiteral = strResult })
	end

	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogDamage[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageType, strDamageColor, tEventArgs.nDamageAmount, tEventArgs.nShield, tEventArgs.nAbsorption, tostring(tEventArgs.nGlanceAmount), tostring(tEventArgs.nOverkill)))

	if tEventArgs.bTargetKilled then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(self.tCache.TargetKilled, tTextInfo.strCaster, tTextInfo.strTarget), "")
	end
end

function CombatLog:OnCombatLogDamageShields(tEventArgs)
	-- Example Combat Log Message: 17:18: Alvin uses Mind Stab on Space Pirate for 250 Magic damage to shields.
	local strDamageColor = self:HelperDamageColor(tEventArgs.eDamageType)
	local tTextInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)

	tTextInfo.strSpellName = string.format("<T Font=\"%s\">%s</T>", kstrFontBold, tTextInfo.strSpellName)
	local strDamage = string.format("<T TextColor=\"%s\">%s</T>", strDamageColor, tEventArgs.nDamageAmount)

	if tEventArgs.unitTarget and tEventArgs.unitTarget:IsMounted() then
		tTextInfo.strTarget = String_GetWeaselString(Apollo.GetString("CombatLog_MountedTarget"), tTextInfo.strTarget)
	end

	local strDamageType
	if tEventArgs.eDamageType ~= nil then
		strDamageType = self.tTypeMapping[tEventArgs.eDamageType]
	else
		strDamageType = Apollo.GetString("CombatLog_UnknownDamageType")
	end
	
	local idx = 0x0
	if tEventArgs.nShield > 0 then
		idx = 0x1
	end
	
	if tEventArgs.nAbsorption > 0 then
		idx = idx + 0x2
	end
	
	if tEventArgs.nGlanceAmount > 0 then
		idx = idx + 0x4
	end
	
	if tEventArgs.bTargetVulnerable then
		idx = idx + 0x8
	end
	
	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		idx = idx + 0x10
	end
	
	local strResult = self.tCache.CombatLogDamageShields[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageType, strDamageColor, tEventArgs.nDamageAmount, tEventArgs.nShield, tEventArgs.nAbsorption, tostring(tEventArgs.nGlanceAmount)))
		
		if tEventArgs.bTargetKilled then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(self.tCache.TargetKilled, tTextInfo.strCaster, tTextInfo.strTarget), "")
		end
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - damage type
	6 - damage color
	7 - damage amount
	8 - shield amount
	9 - absorb amount
	10 - glance amount
	]]--
	
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseShieldDamage"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' }, { strLiteral = '<T TextColor="$6n">$7c</T>' }, { strLiteral = '$5n' })
	
	if tEventArgs.nShield > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageShielded"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$8c</T>' })
	end

	if tEventArgs.nAbsorption > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageAbsorbed"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$9c</T>' })
	end
	
	if tEventArgs.nGlanceAmount > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageGlanced"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$(10)</T>' })
	end
	
	if tEventArgs.bTargetVulnerable then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageVulnerable"), { strLiteral = strResult })
	end

	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Critical"), { strLiteral = strResult })
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogDamageShields[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageType, strDamageColor, tEventArgs.nDamageAmount, tEventArgs.nShield, tEventArgs.nAbsorption, tostring(tEventArgs.nGlanceAmount)))

	if tEventArgs.bTargetKilled then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(self.tCache.TargetKilled, tTextInfo.strCaster, tTextInfo.strTarget), "")
	end
end

function CombatLog:OnCombatLogReflect(tEventArgs)
	-- Example Combat Log Message: 17:18: Alvin reflects Mind Stab back onto Space Pirate for 250 Magic damage.
	local strDamageColor = self:HelperDamageColor(tEventArgs.eDamageType)
	local tTextInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)

	if tEventArgs.unitTarget and tEventArgs.unitTarget:IsMounted() then
		tTextInfo.strTarget = String_GetWeaselString(Apollo.GetString("CombatLog_MountedTarget"), tTextInfo.strTarget)
	end

	local strDamageType
	if tEventArgs.eDamageType ~= nil then
		strDamageType = self.tTypeMapping[tEventArgs.eDamageType]
	else
		strDamageType = Apollo.GetString("CombatLog_UnknownDamageType")
	end
	
	local idx = 0x0
	if tEventArgs.nShield > 0 then
		idx = 0x1
	end
	
	if tEventArgs.nAbsorption > 0 then
		idx = idx + 0x2
	end
	
	if tEventArgs.nGlanceAmount > 0 then
		idx = idx + 0x4
	end
	
	local strResult = self.tCache.CombatLogReflect[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageType, strDamageColor, tEventArgs.nDamageAmount, tEventArgs.nShield, tEventArgs.nAbsorption, tostring(tEventArgs.nGlanceAmount)))
		
		if tEventArgs.bTargetKilled then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(self.tCache.TargetKilled , tTextInfo.strCaster, tTextInfo.strTarget), "")
		end
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - damage type
	6 - damage color
	7 - damage amount
	8 - shield amount
	9 - absorb amount
	10 - glance amount
	]]--
	
	
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseReflect"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseDamage"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$7c</T>' }, { strLiteral = '$5n' })

	if tEventArgs.nShield > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageShielded"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$8c</T>' })
	end

	if tEventArgs.nAbsorption > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageAbsorbed"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$9c</T>' })
	end
	
	if tEventArgs.nGlanceAmount > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageGlanced"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$(10)</T>' })
	end

	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogReflect[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageType, strDamageColor, tEventArgs.nDamageAmount, tEventArgs.nShield, tEventArgs.nAbsorption, tostring(tEventArgs.nGlanceAmount)))

	if tEventArgs.bTargetKilled then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(self.tCache.TargetKilled, tTextInfo.strCaster, tTextInfo.strTarget), "")
	end
end

function CombatLog:OnCombatLogMultiHit(tEventArgs)
	-- Example Combat Log Message: 17:18: Alvin multi-hits with Mind Stab on Space Pirate for 250 Magic damage.
	local strDamageColor = self:HelperDamageColor(tEventArgs.eDamageType)
	local tTextInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)

	if tEventArgs.unitTarget and tEventArgs.unitTarget:IsMounted() then
		tTextInfo.strTarget = String_GetWeaselString(Apollo.GetString("CombatLog_MountedTarget"), tTextInfo.strTarget)
	end
	
	local strDamageType
	if tEventArgs.eDamageType ~= nil then
		strDamageType = self.tTypeMapping[tEventArgs.eDamageType]
	else
		strDamageType = Apollo.GetString("CombatLog_UnknownDamageType")
	end
	
	local idx = 0x0
	if tEventArgs.nShield > 0 then
		idx = 0x1
	end
	
	if tEventArgs.nAbsorption > 0 then
		idx = idx + 0x2
	end
	
	if tEventArgs.nGlanceAmount > 0 then
		idx = idx + 0x4
	end
	
	if tEventArgs.bTargetVulnerable then
		idx = idx + 0x8
	end
	
	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		idx = idx + 0x10
	end
	
	local strResult = self.tCache.CombatLogMultiHit[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageType, strDamageColor, tEventArgs.nDamageAmount, tEventArgs.nShield, tEventArgs.nAbsorption, tostring(tEventArgs.nGlanceAmount)))
		
		if tEventArgs.bTargetKilled then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(self.tCache.TargetKilled , tTextInfo.strCaster, tTextInfo.strTarget), "")
		end
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - damage type
	6 - damage color
	7 - damage amount
	8 - shield amount
	9 - absorb amount
	10 - glance amount
	]]--

	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseMultiHit"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseDamage"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$7c</T>' }, { strLiteral = '$5n' })

	if tEventArgs.nShield > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageShielded"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$8c</T>' })
	end

	if tEventArgs.nAbsorption > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageAbsorbed"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$9c</T>' })
	end
	
	if tEventArgs.nGlanceAmount > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageGlanced"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$(10)</T>' })
	end

	if tEventArgs.bTargetVulnerable then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageVulnerable"), { strLiteral = strResult })
	end

	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Critical"), { strLiteral = strResult })
	end

	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogMultiHit[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageType, strDamageColor, tEventArgs.nDamageAmount, tEventArgs.nShield, tEventArgs.nAbsorption, tostring(tEventArgs.nGlanceAmount)))

	if tEventArgs.bTargetKilled then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(self.tCache.TargetKilled, tTextInfo.strCaster, tTextInfo.strTarget), "")
	end
end

function CombatLog:OnCombatLogMultiHitShields(tEventArgs)
	-- Example Combat Log Message: 17:18: Alvin multi-hits shields with Mind Stab on Space Pirate for 250 Magic damage.
	local strDamageColor = self:HelperDamageColor(tEventArgs.eDamageType)
	local tTextInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)

	if tEventArgs.unitTarget and tEventArgs.unitTarget:IsMounted() then
		tTextInfo.strTarget = String_GetWeaselString(Apollo.GetString("CombatLog_MountedTarget"), tTextInfo.strTarget)
	end
	
	local strDamageType
	if tEventArgs.eDamageType ~= nil then
		strDamageType = self.tTypeMapping[tEventArgs.eDamageType]
	else
		strDamageType = Apollo.GetString("CombatLog_UnknownDamageType")
	end
	
	local idx = 0x0
	if tEventArgs.nShield > 0 then
		idx = 0x1
	end
	
	if tEventArgs.nAbsorption > 0 then
		idx = idx + 0x2
	end
	
	if tEventArgs.nGlanceAmount > 0 then
		idx = idx + 0x4
	end
	
	if tEventArgs.bTargetVulnerable then
		idx = idx + 0x8
	end
	
	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		idx = idx + 0x10
	end
	
	local strResult = self.tCache.CombatLogMultiHitShields[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageType, strDamageColor, tEventArgs.nDamageAmount, tEventArgs.nShield, tEventArgs.nAbsorption, tostring(tEventArgs.nGlanceAmount)))
		
		if tEventArgs.bTargetKilled then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(self.tCache.TargetKilled , tTextInfo.strCaster, tTextInfo.strTarget), "")
		end
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - damage type
	6 - damage color
	7 - damage amount
	8 - shield amount
	9 - absorb amount
	10 - glance amount
	]]--

	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseMultiHitShields"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' }, { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$7c</T>' }, { strLiteral = '$5n' })

	if tEventArgs.nShield > 0 then
		local strAmountShielded = string.format("<T TextColor=\"%s\">%s</T>", strDamageColor, tEventArgs.nShield)
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageShielded"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$8c</T>' })
	end

	if tEventArgs.nAbsorption > 0 then
		local strAmountAbsorbed = string.format("<T TextColor=\"%s\">%s</T>", strDamageColor, tEventArgs.nAbsorption)
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageAbsorbed"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$9c</T>' })
	end
	
	if tEventArgs.nGlanceAmount > 0 then
		local strAmountGlanced = string.format("<T TextColor=\"%s\">%s</T>", strDamageColor, tEventArgs.nGlanceAmount)
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageGlanced"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$6n">$(10)</T>' })
	end

	if tEventArgs.bTargetVulnerable then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageVulnerable"), { strLiteral = strResult })
	end

	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Critical"), { strLiteral = strResult })
	end

	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogMultiHitShields[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageType, strDamageColor, tEventArgs.nDamageAmount, tEventArgs.nShield, tEventArgs.nAbsorption, tostring(tEventArgs.nGlanceAmount)))

	if tEventArgs.bTargetKilled then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(self.tCache.TargetKilled, tTextInfo.strCaster, tTextInfo.strTarget), "")
	end
end

function CombatLog:OnCombatLogFallingDamage(tEventArgs)
	-- Example Combat Log Message: 17:18: Alvin suffers 246 falling damage
	local strCaster = self:HelperGetNameElseUnknown(tEventArgs.unitCaster)
	local strDamageColor = self:HelperDamageColor(tEventArgs.eDamageType)
	
	local strResult = self.tCache.CombatLogFallingDamage[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strCaster, strDamageColor, tEventArgs.nDamageAmount))
		
		return
	end
	
	--[[
	1 - caster name
	2 - damage color
	3 - damage amount
	]]--
	
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_FallingDamage"), { strLiteral = '$1n' }, { strLiteral = '<T TextColor="$2n">$3c</T>' })
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrColorCombatLogIncomingBad, strResult)
	self.tCache.CombatLogFallingDamage[0] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strCaster, strDamageColor, tEventArgs.nDamageAmount))
end

function CombatLog:OnCombatLogDeflect(tEventArgs)
	local tCastInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)
	
	local idx = 0x0
	if tEventArgs.bMultiHit then
		idx = 0x1
	end
	
	local strResult = self.tCache.CombatLogDeflect[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, tCastInfo.strSpellName, tCastInfo.strTarget, tCastInfo.strColor))
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	]]--

	if tEventArgs.bMultiHit then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseMultiHit"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })
	else
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseSkillUse"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })
	end
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Deflect"), { strLiteral = strResult })
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogDeflect[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, tCastInfo.strSpellName, tCastInfo.strTarget, tCastInfo.strColor))
end

function CombatLog:OnCombatLogImmunity(tEventArgs)
	local tCastInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)
	
	local strResult = self.tCache.CombatLogImmunity[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, tCastInfo.strSpellName, tCastInfo.strTarget, tCastInfo.strColor))
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	]]--

	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseSkillUse"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Immune"), { strLiteral = strResult })

	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogImmunity[0] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, tCastInfo.strSpellName, tCastInfo.strTarget, tCastInfo.strColor))
end

function CombatLog:OnCombatLogDispel(tEventArgs)
	local tCastInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)
	
	local tSpellCount =
	{
		["count"] = tEventArgs.nInstancesRemoved
	}

	local strArgRemovedSpellName = tEventArgs.splRemovedSpell:GetName()
	if strArgRemovedSpellName and strArgRemovedSpellName ~= "" then
		tSpellCount["name"] = strArgRemovedSpellName
	else
		tSpellCount["name"] = Apollo.GetString("CombatLog_SpellUnknown")
	end
	
	local idx = 0x0
	if tEventArgs.bRemovesSingleInstance then
		idx = 0x1
	end
	
	local strResult = self.tCache.CombatLogDispel[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, tCastInfo.strSpellName, tCastInfo.strTarget, tCastInfo.strColor, tSpellCount))
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - tSpellCount
	]]--
	
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseSkillUse"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })

	if tEventArgs.bRemovesSingleInstance then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DispelMultiple"), { strLiteral = strResult }, { strLiteral = '$+(5)' })
	else
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DispelSingle"), { strLiteral = strResult }, { strLiteral = '$5n' })
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogDispel[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, tCastInfo.strSpellName, tCastInfo.strTarget, tCastInfo.strColor, tSpellCount))
end

function CombatLog:OnCombatLogHeal(tEventArgs)
	local strDamageColor = self:HelperDamageColor(tEventArgs.eDamageType)
	local tCastInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)

	local idx = 0x0
	if tEventArgs.eEffectType == Spell.CodeEnumSpellEffectType.HealShields then
		idx = 0x1
	end
	
	if tEventArgs.nOverheal > 0 then
		idx = idx + 0x2
	end
	
	if tEventArgs.nAbsorption > 0 then
		idx = idx + 0x4
	end
	
	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		idx = idx + 0x8
	end
	
	local strResult = self.tCache.CombatLogHeal[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, tCastInfo.strSpellName, tCastInfo.strTarget, tCastInfo.strColor, strDamageColor, tEventArgs.nHealAmount, tEventArgs.nOverheal, tEventArgs.nAbsorption))
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - damage color
	6 - heal amount
	7 - overheal amount
	8 - heal absorbed amount
	]]--
	
	local strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseSkillUse"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })

	local strHealType
	if tEventArgs.eEffectType == Spell.CodeEnumSpellEffectType.HealShields then
		strHealType = Apollo.GetString("CombatLog_HealShield")
	else
		strHealType = Apollo.GetString("CombatLog_HealHealth")
	end
	strResult = String_GetWeaselString(strHealType, { strLiteral = strResult }, { strLiteral = '<T TextColor="$5n">$6c</T>' })

	if tEventArgs.nOverheal > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Overheal"), { strLiteral = strResult }, { strLiteral = '<T TextColor="white">$7c</T>' })
	end
	
	if tEventArgs.nAbsorption > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageAbsorbed"), { strLiteral = strResult }, { strLiteral = '<T TextColor="white">$8c</T>' })
	end

	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Critical"), { strLiteral = strResult })
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogHeal[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, tCastInfo.strSpellName, tCastInfo.strTarget, tCastInfo.strColor, strDamageColor, tEventArgs.nHealAmount, tEventArgs.nOverheal, tEventArgs.nAbsorption))
end

function CombatLog:OnCombatLogMultiHeal(tEventArgs)
	-- -- Example Combat Log Message: 17:18: Alvin multi-hits with Mental Boon on Trevor for 250 health.
	local strDamageColor = self:HelperDamageColor(tEventArgs.eDamageType)
	local tTextInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)

	local idx = 0x0
	if tEventArgs.eEffectType == Spell.CodeEnumSpellEffectType.HealShields then
		idx = 0x1
	end
	
	if tEventArgs.nOverheal > 0 then
		idx = idx + 0x2
	end
	
	if tEventArgs.nAbsorption > 0 then
		idx = idx + 0x4
	end
	
	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		idx = idx + 0x8
	end
	
	local strResult = self.tCache.CombatLogMultiHeal[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageColor, tEventArgs.nHealAmount, tEventArgs.nOverheal, tEventArgs.nAbsorption))
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - damage color
	6 - heal amount
	7 - overheal amount
	8 - heal absorbed amount
	]]--
	
	local strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseMultiHit"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })

	local strHealType
	if tEventArgs.eEffectType == Spell.CodeEnumSpellEffectType.HealShields then
		strHealType = Apollo.GetString("CombatLog_HealShield")
	else
		strHealType = Apollo.GetString("CombatLog_HealHealth")
	end
	strResult = String_GetWeaselString(strHealType, { strLiteral = strResult }, { strLiteral = '<T TextColor="$5n">$6c</T>' })

	if tEventArgs.nOverheal > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Overheal"), { strLiteral = strResult }, { strLiteral = '<T TextColor="white">$7c</T>' })
	end
	
	if tEventArgs.nAbsorption > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageAbsorbed"), { strLiteral = strResult }, { strLiteral = '<T TextColor="white">$8c</T>' })
	end

	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Critical"), { strLiteral = strResult })
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogMultiHeal[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageColor, tEventArgs.nHealAmount, tEventArgs.nOverheal, tEventArgs.nAbsorption))
end

function CombatLog:OnCombatLogModifyInterruptArmor(tEventArgs)
	local tTextInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)

	local idx = 0x0
	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		idx = 0x1
	end
	
	local strResult = self.tCache.CombatLogModifyInterruptArmor[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, tEventArgs.nAmount))
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - amount
	]]--
	
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseSkillUse"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_InterruptArmor"), strResult, { strLiteral = '<T TextColor="white">$5c</T>' })
	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Critical"), { strLiteral = strResult })
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogModifyInterruptArmor[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, tEventArgs.nAmount))
end

function CombatLog:OnCombatLogAbsorption(tEventArgs)
	local tTextInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)
	local strDamageColor = self:HelperDamageColor(tEventArgs.eDamageType)
	
	local idx = 0x0
	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		idx = 0x1
	end
	
	local strResult = self.tCache.CombatLogAbsorption[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageColor, tEventArgs.nAmount))
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - damage color
	6 - amount
	]]--

	local strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseSkillUse"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_GrantAbsorption"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$5n">$6c</T>' })

	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Critical"), { strLiteral = strResult })
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogAbsorption[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageColor, tEventArgs.nAmount))
end

function CombatLog:OnCombatLogHealingAbsorption(tEventArgs)
	local tTextInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)
	local strDamageColor = self:HelperDamageColor(tEventArgs.eDamageType)

	local idx = 0x0
	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		idx = 0x1
	end
	
	local strResult = self.tCache.CombatLogHealingAbsorption[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageColor, tEventArgs.nAmount))
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - damage color
	6 - amount
	]]--
	
	local strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseSkillUse"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_GrantAbsorption"), { strLiteral = strResult }, { strLiteral = '<T TextColor="$5n">$6c</T>' })

	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Critical"), { strLiteral = strResult })
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogHealingAbsorption[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, strDamageColor, tEventArgs.nAmount))
end

function CombatLog:OnCombatLogVitalModifier(tEventArgs)
	-- NOTE: strTarget is usually first, but there is no strCaster here
	if not tEventArgs.bShowCombatLog then
		return
	end

	local tTextInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)
	local strVital
	if tEventArgs.eVitalType and tEventArgs.unitCaster then
		strVital = tEventArgs.unitCaster:GetResourceName(tEventArgs.eVitalType)
		if strVital == nil then
			strVital = Unit.GetVitalTable()[tEventArgs.eVitalType].strName
		end
	else
		strVital = Apollo.GetString("CombatLog_UnknownVital")
	end
	
	local idx = 0x0
	if tEventArgs.nAmount < 0 then
		idx = 0x1
	end
	
	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		idx = idx + 0x2
	end
	
	local strResult = self.tCache.CombatLogVitalModifier[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, self.crVitalModifier, tEventArgs.nAmount, strVital))
		
		return
	end
	
	--[[
	1 - spell name
	2 - target name
	3 - text color
	4 - vital color
	5 - amount
	6 - vital name
	]]--
	
	if tEventArgs.nAmount < 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_LoseVital"), { strLiteral = '$2n' }, { strLiteral = '<T TextColor="$4n">$5c</T>' }, { strLiteral = '$6n' }, { strLiteral = string.format('<T Font="%s">$1n</T>', kstrFontBold) })
	else
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_GainVital"), { strLiteral = '$2n' }, { strLiteral = '<T TextColor="$4n">$5c</T>' }, { strLiteral = '$6n' }, { strLiteral = string.format('<T Font="%s">$1n</T>', kstrFontBold) })
	end
	
	if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Critical"), { strLiteral = strResult })
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$3n">%s</P>', strResult)
	self.tCache.CombatLogVitalModifier[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, self.crVitalModifier, tEventArgs.nAmount, strVital))
end

function CombatLog:OnCombatLogCCState(tEventArgs)
	if not self.unitPlayer then
		self.unitPlayer = GameLib.GetControlledUnit()
	end
	
	if tEventArgs.unitTarget == self.unitPlayer then
		local idx = 0x0
		if not tEventArgs.bRemoved then
			idx = 0x1
		end
		
		local strResult = self.tCache.CombatLogCCStateSelf[idx]
		if strResult then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.strState))
		else
			if not tEventArgs.bRemoved then
				strResult = String_GetWeaselString(Apollo.GetString("CombatLog_CCState"), { strLiteral = string.format('<T TextColor="%s">$1n</T>', kstrStateColor) })
			else
				strResult = String_GetWeaselString(Apollo.GetString("CombatLog_CCFades"), { strLiteral = string.format('<T TextColor="%s">$1n</T>', kstrStateColor) })
			end
			
			strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$3n">%s</P>', strResult)
			self.tCache.CombatLogCCStateSelf[idx] = strResult
			
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.strState))
		end
	end

	-- aside from the above text, we only care if this was an add
	if tEventArgs.bRemoved then
		return
	end

	local tTextInfo = self:HelperCasterTargetSpell(tEventArgs, true, true, true)
	
	local idx = 0x0
	if tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Stacking_DoesNotStack then
		idx = 0x1
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_Immune then
		idx = idx + 0x2
	end
	
	if tEventArgs.nInterruptArmorHit > 0 and tEventArgs.unitTarget and tEventArgs.unitTarget:GetInterruptArmorValue() > 0 then
		idx = idx + 0x4
	end
	
	local nRemainingIA = tEventArgs.unitTarget and tEventArgs.unitTarget:GetInterruptArmorValue() - tEventArgs.nInterruptArmorHit or -1
	if nRemainingIA >= 0 then
		idx = idx + 0x8
	end
	
	local strResult = self.tCache.CombatLogCCState[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, tEventArgs.strState, tEventArgs.nInterruptArmorHit, nRemainingIA))
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - state
	6 - interrupt armor hit
	7 - remaining interrupt armor
	]]--
	
	-- display the effects of the cc state
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_BaseSkillUse"), { strLiteral = '$1n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) }, { strLiteral = '$3n' })

	if tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Stacking_DoesNotStack then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_CCDoesNotStack"), { strLiteral = strResult }, { strLiteral = '$5n' })
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_Immune then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_CCImmune"), { strLiteral = strResult })
	else
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_CCSideEffect"), { strLiteral = strResult }, { strLiteral = '<T TextColor="white">$5n</T>' })
	end

	if tEventArgs.nInterruptArmorHit > 0 and tEventArgs.unitTarget and tEventArgs.unitTarget:GetInterruptArmorValue() > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_InterruptArmorRemoved"), { strLiteral = strResult }, { strLiteral = '<T TextColor="white">-$6c</T>' })
	end
	
	if nRemainingIA >= 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_InterruptArmorLeft"), { strLiteral = strResult }, { strLiteral = '<T TextColor="white">-$7c</T>' })
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogCCState[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tTextInfo.strCaster, tTextInfo.strSpellName, tTextInfo.strTarget, tTextInfo.strColor, tEventArgs.strState, tEventArgs.nInterruptArmorHit, nRemainingIA))
end

-----------------------------------------------------------------------------------------------
-- Special
-----------------------------------------------------------------------------------------------
function CombatLog:OnCombatLogLifeSteal(tEventArgs)
	local strCasterName = tEventArgs.unitCaster:GetName()
	local strTextColor = self:HelperPickColor(tEventArgs)

	local idx = 0x0
	if tEventArgs.nAbsorption > 0 then
		idx = 0x1
	end
	
	local strResult = self.tCache.CombatLogLifeSteal[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strCasterName, tEventArgs.nHealthStolen, tEventArgs.nAbsorption, strTextColor))
		
		return
	end
	
	--[[
	1 - caster name
	2 - health stolen
	3 - absorb amount
	4 - text color
	]]--

	strResult = Apollo.GetString("CombatLogLifesteal")
	
	if tEventArgs.nAbsorption > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageAbsorbed"), { strLiteral = strResult }, { strLiteral = '<T TextColor="white">$3n</T>' })
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogLifeSteal[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strCasterName, tEventArgs.nHealthStolen, tEventArgs.nAbsorption, strTextColor))
end

function CombatLog:OnCombatLogTransference(tEventArgs)
	if not self.unitPlayer then
		self.unitPlayer = GameLib.GetControlledUnit()
	end

	local bDisableOtherPlayers = Apollo.GetConsoleVariable("cmbtlog.disableOtherPlayers")
	
	-- OnCombatLogDamage does exactly what we need so just pass along the tEventArgs
	self:OnCombatLogDamage(tEventArgs)
	
	local tVitals = Unit.GetVitalTable()
	
	local tCastInfo = self:HelperCasterTargetSpell(tEventArgs, true, false)
	-- healing data is stored in a table where each subtable contains a different vital that was healed
	for _, tHeal in ipairs(tEventArgs.tHealData) do
		if not bDisableOtherPlayers or self.unitPlayer == tHeal.unitHealed then
			local strVital
			if tHeal.eVitalType then
				strVital = tVitals[tHeal.eVitalType].strName
			else
				strVital = Apollo.GetString("CombatLog_UnknownVital")
			end
			
			-- units in caster's group can get healed
			if tHeal.unitHealed ~= tEventArgs.unitCaster then
				tCastInfo.strTarget = tCastInfo.strCaster
				tCastInfo.strCaster = self:HelperGetNameElseUnknown(tHeal.unitHealed)
			end
			
			local strColor = kstrColorCombatLogIncomingGood
			if tEventArgs.unitCaster ~= self.unitPlayer then
				strColor = kstrColorCombatLogOutgoing
			end
			
			local idx = 0x0
			if tHeal.nOverheal > 0 then
				idx = 0x1
				if tHeal.eVitalType == GameLib.CodeEnumVital.ShieldCapacity then
					idx = idx + 0x2
				end
			end
			
			if tHeal.nOverheal > 0 then
				idx = idx + 0x4
			end
			
			if tHeal.nAbsorption > 0 then
				idx = idx + 0x8
			end
			
			if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
				idx = idx + 0x10
			end
			
			--[[
			1 - caster name
			2 - vital
			3 - text color
			4 - target name
			5 - vital color
			6 - heal amount
			7 - overheal
			8 - absorb
			]]--
			
			local strResult = self.tCache.CombatLogTransference[idx]
			if strResult then
				ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, strVital, strColor, tCastInfo.strTarget, self.crVitalModifier, tHeal.nHealAmount, tHeal.nOverheal, tHeal.nAbsorption))
			else
				strResult = String_GetWeaselString(Apollo.GetString("CombatLog_GainVital"), { strLiteral = '$1n' }, { strLiteral = '<T TextColor="$5n">$6c</T>' }, { strLiteral = '$2n' }, { strLiteral = '$4n' })
				
				if tHeal.nOverheal > 0 then
					local strOverhealString
					if tHeal.eVitalType == GameLib.CodeEnumVital.ShieldCapacity then
						strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Overshield"), { strLiteral = strResult }, { strLiteral = '<T TextColor="white">$7c</T>' })
					else
						strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Overheal"), { strLiteral = strResult }, { strLiteral = '<T TextColor="white">$7c</T>' })
					end
				end
				
				if tHeal.nAbsorption > 0 then
					strResult = String_GetWeaselString(Apollo.GetString("CombatLog_DamageAbsorbed"), { strLiteral = strResult }, { strLiteral = '<T TextColor="white">$8c</T>' })
				end
				
				if tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical then
					strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Critical"), { strLiteral = strResult })
				end
				
				strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$3n">%s</P>', strResult)
				self.tCache.CombatLogTransference[idx] = strResult
				
				ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, strVital, strColor, tCastInfo.strTarget, self.crVitalModifier, tHeal.nHealAmount, tHeal.nOverheal, tHeal.nAbsorption))
			end
		end
	end
end

function CombatLog:OnCombatLogInterrupted(tEventArgs)
	if not tEventArgs or not tEventArgs.unitCaster then
		return
	end

	local tCastInfo = self:HelperCasterTargetSpell(tEventArgs, true, true)
	
	local strColor = kstrColorCombatLogIncomingGood
	if tEventArgs.unitCaster == self.unitPlayer then
		strColor = kstrColorCombatLogOutgoing
	end
	
	local idx = 0x0
	if tEventArgs.unitCaster ~= tEventArgs.unitTarget then
		if tEventArgs.splInterruptingSpell and tEventArgs.splInterruptingSpell:GetName() then
			idx = idx + 0x1
		else
			idx = idx + 0x2
		end
	end
	
	local strResult = self.tCache.CombatLogInterrupted[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strCasterName, tCastInfo.strSpellName, tCastInfo.strTarget, strColor, tEventArgs.splInterruptingSpell:GetName(), tEventArgs.strCastResult))
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	3 - target name
	4 - text color
	5 - interrupting spell name
	6 - cast result
	]]--
	
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_TargetInterrupted"), { strLiteral = '$3n' }, { strLiteral = string.format('<T Font="%s">$2n</T>', kstrFontBold) })
	
	if tEventArgs.unitCaster ~= tEventArgs.unitTarget then
		if tEventArgs.splInterruptingSpell and tEventArgs.splInterruptingSpell:GetName() then
			strResult = String_GetWeaselString(Apollo.GetString("CombatLog_InterruptSourceCaster"), { strLiteral = strResult }, { strLiteral = '$p(1)' }, { strLiteral = '$5n' })
		else
			strResult = String_GetWeaselString(Apollo.GetString("CombatLog_InterruptSource"), { strLiteral = strResult }, { strLiteral = '$1n' })
		end
	elseif tEventArgs.strCastResult and tEventArgs.strCastResult ~= "" then
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_InterruptSelf"), { strLiteral = strResult }, { strLiteral = '$6n' })
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="$4n">%s</P>', strResult)
	self.tCache.CombatLogInterrupted[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strCasterName, tCastInfo.strSpellName, tCastInfo.strTarget, strColor, tEventArgs.splInterruptingSpell:GetName(), tEventArgs.strCastResult))
end

function CombatLog:OnCombatLogKillStreak(tEventArgs)
	if tEventArgs.nStreakAmount <= 1 then
		return
	end

	local strCaster = self:HelperGetNameElseUnknown(tEventArgs.unitCaster)
	
	local idx = 0x0
	if tEventArgs.eStatType == CombatFloater.CodeEnumCombatMomentum.Impulse then
		idx = idx + 0x1
	else
		if tEventArgs.nStreakAmount == 2 then
			idx = idx + 0x2
		elseif tEventArgs.nStreakAmount == 3 then
			idx = idx + 0x4
		end
	end
	
	if tEventArgs.unitCaster == self.unitPlayer then
		idx = idx + 0x8
	end
	
	local strResult = self.tCache.CombatLogKillStreak[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strCaster, tEventArgs.nStreakAmount))
		
		return
	end
	
	--[[
	1 - caster name
	2 - streak amount
	]]--
	
	local strStreakType
	if tEventArgs.eStatType == CombatFloater.CodeEnumCombatMomentum.Impulse then
		strStreakType = String_GetWeaselString(Apollo.GetString("CombatLog_ImpulseStreak"), { strLiteral = '$2c' })
	else
		if tEventArgs.nStreakAmount == 2 then
			strStreakType = Apollo.GetString("CombatLog_DoubleKill")
		elseif tEventArgs.nStreakAmount == 3 then
			strStreakType = Apollo.GetString("CombatLog_TripleKill")
		else
			strStreakType = String_GetWeaselString(Apollo.GetString("CombatLog_MultiKill"), { strLiteral = '$2c' })
		end
	end
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Achieves"), { strLiteral = '$1n' }, { strLiteral = strStreakType })
	
	-- TODO: Analyze if we can refactor (this has no spell and uses default)
	if tEventArgs.unitCaster == self.unitPlayer then
		strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrColorCombatLogOutgoing, strResult)
	else
		strResult = string.format('<P Font="CRB_InterfaceMedium">%s</P>', strResult)
	end
	
	self.tCache.CombatLogKillStreak[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strCaster, tEventArgs.nStreakAmount))
end

function CombatLog:OnCombatLogKillPVP(tEventArgs)
	local tCastInfo = self:HelperCasterTargetSpell(tEventArgs, true, false)
	
	local strResult = self.tCache.CombatLogKillPVP[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, tCastInfo.strTarget))
		
		return
	end

	--[[
	1 - caster name
	2 - target name
	]]--
	
	strResult = string.format('<P Font="CRB_InterfaceMedium">%s</P>', Apollo.GetString("CombatLog_KillAssist"))
	self.tCache.CombatLogKillPVP[0] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, tCastInfo.strTarget))
end

-----------------------------------------------------------------------------------------------
-- State Changes (uses color kstrStateColor, dark orange)
-----------------------------------------------------------------------------------------------

function CombatLog:OnCombatLogCCStateBreak(tEventArgs)
	local strResult = self.tCache.CombatLogCCStateBreak[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.strState))
		
		return
	end
	
	--[[
	1 - state
	]]--
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrStateColor, Apollo.GetString("CombatLog_CCBroken"))
	self.tCache.CombatLogCCStateBreak[0] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.strState))
end

function CombatLog:OnCombatLogDelayDeath(tEventArgs)
	local tCastInfo = self:HelperCasterTargetSpell(tEventArgs, false, true)
	
	local strResult = self.tCache.CombatLogDelayDeath[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, tCastInfo.strSpellName))
		
		return
	end
	
	--[[
	1 - caster name
	2 - spell name
	]]--
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrStateColor, Apollo.GetString("CombatLog_NotDeadYet"))
	self.tCache.CombatLogDelayDeath[0] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tCastInfo.strCaster, tCastInfo.strSpellName))
end

function CombatLog:OnCombatLogDeath(tEventArgs)
	local strResult = self.tCache.CombatLogDeath[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, strResult)
		
		return
	end
	
	--[[
	]]--
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrStateColor, Apollo.GetString("CombatLog_Death"))
	self.tCache.CombatLogCCStateBreak[0] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, strResult)
end

function CombatLog:OnCombatLogStealth(tEventArgs)
	local idx = 0x0
	if tEventArgs.bExiting then
		idx = idx + 0x1
	end

	local strResult = self.tCache.CombatLogStealth[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, strResult)
		
		return
	end
	
	--[[
	]]--

	if tEventArgs.bExiting then
		strResult = Apollo.GetString("CombatLog_LeaveStealth")
	else
		strResult = Apollo.GetString("CombatLog_EnterStealth")
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrStateColor, strResult)
	self.tCache.CombatLogStealth[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, strResult)
end

function CombatLog:OnCombatLogMount(tEventArgs)
	local strTarget = self:HelperGetNameElseUnknown(tEventArgs.unitTarget)

	local idx = 0x0
	if tEventArgs.bDismounted then
		idx = idx + 0x1
	end
	
	local strResult = self.tCache.CombatLogMount[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strTarget))
		
		return
	end

	--[[
	1 - target name
	]]--
	
	if tEventArgs.bDismounted then
		strResult = Apollo.GetString("CombatLog_Dismount")
	else
		strResult = Apollo.GetString("CombatLog_Summon")
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrStateColor, strResult)
	self.tCache.CombatLogMount[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strTarget))
end

function CombatLog:OnCombatLogPet(tEventArgs)
	local strTarget = self:HelperGetNameElseUnknown(tEventArgs.unitTarget)

	local idx = 0x0
	if tEventArgs.bDismissed then
		idx = idx + 0x1
	elseif tEventArgs.bKilled then
		idx = idx + 0x2
	end
	
	local strResult = self.tCache.CombatLogPet[idx]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strTarget))
		
		return
	end
	
	--[[
	1 - target name
	]]--
	
	if tEventArgs.bDismissed then
		strResult = Apollo.GetString("CombatLog_DismissPet")
	elseif tEventArgs.bKilled then
		strResult = Apollo.GetString("CombatLog_TargetDies")
	else
		strResult = Apollo.GetString("CombatLog_Summon")
	end
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrStateColor, strResult)
	self.tCache.CombatLogPet[idx] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strTarget))
end

function CombatLog:OnCombatLogResurrect(tEventArgs)
	local strResult = self.tCache.CombatLogResurrect[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, strResult)
		
		return
	end
	
	--[[
	]]--
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrStateColor, Apollo.GetString("CombatLog_Resurrect"))
	self.tCache.CombatLogResurrect[0] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, strResult)
end

function CombatLog:OnCombatLogLAS(tEventArgs)
	local strResult = self.tCache.CombatLogLAS[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, strResult)
		
		return
	end
	
	--[[
	]]--
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrStateColor, Apollo.GetString("CombatLog_LAS"))
	self.tCache.CombatLogLAS[0] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, strResult)
end

function CombatLog:OnCombatLogBuildSwitch(tEventArgs)
	local strResult = self.tCache.CombatLogBuildSwitch[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.nNewSpecIndex))
		
		return
	end

	--[[
	1 - spec index
	]]--
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrStateColor, Apollo.GetString("CombatLog_BuildSwitch"))
	self.tCache.CombatLogBuildSwitch[0] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.nNewSpecIndex))
end

-----------------------------------------------------------------------------------------------
-- Loot Experience Colors (Bright Yellow)
-----------------------------------------------------------------------------------------------

function CombatLog:OnCombatLogExperience(tEventArgs)
	if tEventArgs.nXP > 0 then
		local strResult = self.tCache.CombatLogExperience[0]
		if strResult then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.nXP))
		else
			--[[
			1 - xp
			]]--
			
			strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrColorCombatLogXP, Apollo.GetString("CombatLog_XPGain"))
			self.tCache.CombatLogExperience[0] = strResult
			
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.nXP))
		end
	end

	if tEventArgs.nRestXP > 0 then
		local strResult = self.tCache.CombatLogExperience[1]
		if strResult then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.nRestXP))
		else
			--[[
			1 - rest xp
			]]--
			
			strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrColorCombatLogXP, Apollo.GetString("CombatLog_RestXPGain"))
			self.tCache.CombatLogExperience[1] = strResult
			
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.nRestXP))
		end
	end

	if tEventArgs.nElderPoints > 0 then
		local strResult = self.tCache.CombatLogExperience[2]
		if strResult then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.nElderPoints))
		else
			--[[
			1 - elder points
			]]--
			
			strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrColorCombatLogXP, Apollo.GetString("CombatLog_ElderPointsGained"))
			self.tCache.CombatLogExperience[2] = strResult
			
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.nElderPoints))
		end
	end

	if tEventArgs.nRestEP > 0 then
		local strResult = self.tCache.CombatLogExperience[3]
		if strResult then
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.nRestEP))
		else
			--[[
			1 - rest elder points
			]]--
			
			strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrColorCombatLogXP, Apollo.GetString("CombatLog_RestEPGain"))
			self.tCache.CombatLogExperience[3] = strResult
			
			ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, tEventArgs.nRestEP))
		end
	end
end

function CombatLog:OnCombatLogElderPointsLimitReached(tEventArgs)
	local strResult = self.tCache.CombatLogElderPointsLimitReached[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult))
		
		return
	end
	
	--[[
	]]--
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrColorCombatLogXP, Apollo.GetString("CombatLog_ElderPointLimitReached"))
	self.tCache.CombatLogExperience[0] = strResult

	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult))
end


function CombatLog:OnCombatLogDurabilityLoss(tEventArgs)
	if not self.unitPlayer then
		self.unitPlayer = GameLib.GetControlledUnit()
	end
	
	if tEventArgs.unitCaster ~= self.unitPlayer then
		return
	end
	
	local strResult = self.tCache.CombatLogDurabilityLoss[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult))
		
		return
	end
	
	--[[
	]]--
	
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrLootColor, Apollo.GetString("CombatLog_DurabilityLoss"))
	self.tCache.CombatLogDurabilityLoss[0] = strResult

	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult))
end

-----------------------------------------------------------------------------------------------
-- Old Events
-----------------------------------------------------------------------------------------------

function CombatLog:OnPathExperienceGained(nAmount, strText)
	if nAmount <= 0 then
		return
	end
	
	local strResult = self.tCache.PathExperienceGained[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, nAmount))
		
		return
	end
	
	--[[
	1 - amount
	]]--
	
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_PathXPGained"), { strLiteral = '<T TextColor="ffffffff">$1n</T>' })
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrColorCombatLogPathXP, strResult)
	self.tCache.PathExperienceGained[0] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, nAmount))
end

function CombatLog:OnFactionFloater(unitTarget, pstrMessage, nAmount, strFactionName, nFactionId) -- Reputation Floater
	if nAmount <= 0 then
		return
	end
	
	local strResult = self.tCache.FactionFloater[0]
	if strResult then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strFactionName, nAmount))
		
		return
	end
	
	--[[
	1 - faction name
	2 - amount
	]]--
	
	strResult = String_GetWeaselString(Apollo.GetString("CombatLog_RepGained"), { strLiteral = '<T TextColor="ffffffff">$1n</T>' }, { strLiteral = '<T TextColor="ffffffff">$2c</T>' })
	strResult = string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstrColorCombatLogRep, strResult)
	self.tCache.FactionFloater[0] = strResult
	
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, String_GetWeaselString(strResult, strFactionName, nAmount))
end

function CombatLog:OnPetStatusUpdated()
	self.tPetUnits = GameLib.GetPlayerPets()
end

function CombatLog:OnChangeWorld()
	self.unitPlayer = GameLib.GetControlledUnit()
end

function CombatLog:OnPlayerEquippedItemChanged(nEquippedSlot, itemNew, itemOld)
	local strResult = ""
	if not itemNew then --unequipping only
		local strOldItemName = itemOld:GetName()
		local strOldItemTypeName = itemOld:GetItemTypeName()
		strResult = String_GetWeaselString(Apollo.GetString("CombatLog_UnEquip"), strOldItemName, strOldItemTypeName)
	else
		local strNewItemName = itemNew:GetName()
		local strNewItemTypeName = itemNew:GetItemTypeName()
		if itemOld then --equipping an item and replacing
			local strPrevItemName = itemOld:GetName()
			strResult = String_GetWeaselString(Apollo.GetString("CombatLog_EquipReplace"), strNewItemName, strPrevItemName, strNewItemTypeName)
		else --just equipping an item
			strResult = String_GetWeaselString(Apollo.GetString("CombatLog_Equip"), strNewItemName, strNewItemTypeName)
		end
	end
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Combat, string.format('<P Font="CRB_InterfaceMedium" TextColor="%s">%s</P>', kstEquipColor, strResult))
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function CombatLog:HelperCasterTargetSpell(tEventArgs, bTarget, bSpell, bColor)
	local tInfo =
	{
		strCaster = nil,
		strTarget = nil,
		strSpellName = nil,
		strColor = nil
	}

	tInfo.strCaster = self:HelperGetNameElseUnknown(tEventArgs.unitCaster)
	if tEventArgs.unitCasterOwner ~= nil then
		local strOwnerName = tEventArgs.unitCasterOwner:GetName()
		if strOwnerName ~= nil then
			tInfo.strCaster = string.format("%s (%s)", tInfo.strCaster, strOwnerName)
		end
	end

	if bTarget then
		tInfo.strTarget = self:HelperGetNameElseUnknown(tEventArgs.unitTarget)
		if tEventArgs.unitTargetOwner ~= nil then
			local strOwnerName = tEventArgs.unitTargetOwner:GetName()
			if strOwnerName ~= nil then
				tInfo.strTarget = string.format("%s (%s)", tInfo.strTarget, strOwnerName)
			end
		end

		if bColor then
			tInfo.strColor = self:HelperPickColor(tEventArgs)
		end
	end

	if bSpell then
		tInfo.strSpellName = self:HelperGetNameElseUnknown(tEventArgs.splCallingSpell)
	end

	return tInfo
end

function CombatLog:HelperGetNameElseUnknown(nArg)
	if nArg ~= nil then
		local strName = nArg:GetName()
		if strName ~= nil then
			return strName
		end
	end
	return Apollo.GetString("CombatLog_SpellUnknown")
end

function CombatLog:HelperDamageColor(nArg)
	if nArg and self.tTypeColor[nArg] then
		return self.tTypeColor[nArg]
	end
	return kstrColorCombatLogUNKNOWN
end

function CombatLog:HelperPickColor(tEventArgs)
	if not self.unitPlayer or not self.unitPlayer:IsValid() then
		self.unitPlayer = GameLib.GetControlledUnit()
	end

	-- Try player matching first
	if tEventArgs.unitCaster == self.unitPlayer then
		return kstrColorCombatLogOutgoing
	elseif tEventArgs.unitTarget == self.unitPlayer and tEventArgs.splCallingSpell and tEventArgs.splCallingSpell:IsBeneficial() then
		return kstrColorCombatLogIncomingGood
	elseif tEventArgs.unitTarget == self.unitPlayer then
		return kstrColorCombatLogIncomingBad
	end

	-- Try pets second
	for idx, unitPet in pairs(self.tPetUnits) do
		if tEventArgs.unitCaster == unitPet then
			return kstrColorCombatLogOutgoing
		elseif tEventArgs.unitTarget == unitPet and tEventArgs.splCallingSpell and tEventArgs.splCallingSpell:IsBeneficial() then
			return kstrColorCombatLogIncomingGood
		elseif tEventArgs.unitTarget == unitPet then
			return kstrColorCombatLogIncomingBad
		end
	end

	return kstrColorCombatLogUNKNOWN
end

---------------------------------------------------------------------------------------------------
-- CombatLogOptions
---------------------------------------------------------------------------------------------------

function CombatLog:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	local locWindowLocation = self.wndOptions and self.wndOptions:GetLocation() or self.locSavedOptionsLoc

	local tSaved =
	{
		tWindowLocation = locWindowLocation and locWindowLocation:ToTable() or nil,
		nSavedVersion = knSaveVersion,
	}

	return tSaved
end

function CombatLog:OnRestore(eType, tSavedData)
	if tSavedData and tSavedData.nSavedVersion == knSaveVersion then
		if tSavedData.tWindowLocation then
			self.locSavedOptionsLoc = WindowLocation.new(tSavedData.tWindowLocation)
		end
	end
end

function CombatLog:OnConfigure()
	if self.wndOptions == nil or not self.wndOptions:IsValid() then
		self:InitOptions()
	end

	self.wndOptions:Invoke()

	for idx, tControlData in pairs(self.mapOptionsControls) do
		tControlData.wnd:SetData(tControlData)
		tControlData.wnd:SetCheck(not Apollo.GetConsoleVariable(tControlData.consoleVar))
	end
end

function CombatLog:InitOptions()
	self.wndOptions = Apollo.LoadForm(self.xmlDoc, "CombatLogForm", nil, self)
	Apollo.LoadForm(self.xmlDoc, "CombatLogOptionsControls", self.wndOptions:FindChild("ContentMain"), self)
	if self.locSavedOptionsLoc then
		self.wndOptions:MoveToLocation(self.locSavedOptionsLoc)
	end

	self.mapOptionsControls =
	{
		{
			wnd = self.wndOptions:FindChild("EnableOtherPlayers"),
			consoleVar = "cmbtlog.disableOtherPlayers",
		},
		{
			wnd = self.wndOptions:FindChild("EnableAbsorption"),
			consoleVar = "cmbtlog.disableAbsorption",
		},
		{
			wnd = self.wndOptions:FindChild("EnableCCState"),
			consoleVar = "cmbtlog.disableCCState",
		},
		{
			wnd = self.wndOptions:FindChild("EnableDamage"),
			consoleVar = "cmbtlog.disableDamage",
		},
		{
			wnd = self.wndOptions:FindChild("EnableDeflect"),
			consoleVar = "cmbtlog.disableDeflect",
		},
		{
			wnd = self.wndOptions:FindChild("EnableDelayDeath"),
			consoleVar = "cmbtlog.disableDelayDeath",
		},
		{
			wnd = self.wndOptions:FindChild("EnableDispel"),
			consoleVar = "cmbtlog.disableDispel",
		},
		{
			wnd = self.wndOptions:FindChild("EnableFallingDamage"),
			consoleVar = "cmbtlog.disableFallingDamage",
		},
		{
			wnd = self.wndOptions:FindChild("EnableHeal"),
			consoleVar = "cmbtlog.disableHeal",
		},
		{
			wnd = self.wndOptions:FindChild("EnableImmunity"),
			consoleVar = "cmbtlog.disableImmunity",
		},
		{
			wnd = self.wndOptions:FindChild("EnableInterrupted"),
			consoleVar = "cmbtlog.disableInterrupted",
		},
		{
			wnd = self.wndOptions:FindChild("EnableModifyInterruptArmor"),
			consoleVar = "cmbtlog.disableModifyInterruptArmor",
		},
		{
			wnd = self.wndOptions:FindChild("EnableTransference"),
			consoleVar = "cmbtlog.disableTransference",
		},
		{
			wnd = self.wndOptions:FindChild("EnableVitalModifier"),
			consoleVar = "cmbtlog.disableVitalModifier",
		},
		{
			wnd = self.wndOptions:FindChild("EnableDeath"),
			consoleVar = "cmbtlog.disableDeath",
		},
	}
end

function CombatLog:OnMappedOptionsCheckbox(wndHandler, wndControl, eMouseButton)
	local tData = wndControl:GetData()
	Apollo.SetConsoleVariable(tData.consoleVar, not wndControl:IsChecked())
end

function CombatLog:OnCancel(wndHandler, wndControl, eMouseButton)
	self.wndOptions:Close()
end

local CombatLogInstance = CombatLog:new()
CombatLog:Init()

