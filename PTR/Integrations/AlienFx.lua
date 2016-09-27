-----------------------------------------------------------------------------------------------
-- Client Lua Script for AlienFx
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "AlienFxLib"

local AlienFx = {}

local knAllLocations = 134217727

function AlienFx:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function AlienFx:Init()
    Apollo.RegisterAddon(self)
end

function AlienFx:OnLoad()
	self.timerAlienFx = ApolloTimer.Create(0.5, true, "OnAlienFxTimer", self)
end

function AlienFx:OnAlienFxTimer()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer ~= nil and AlienFxLib.CanUse() and AlienFxLib.IsReady() then
		local nHealthPrecent = unitPlayer:GetHealth() / unitPlayer:GetMaxHealth() * 255.0
		if GameLib.GetPlayerBaseFaction() == Unit.CodeEnumFaction.DominionPlayer then
			AlienFxLib.SetLocationColor(knAllLocations, ApolloColor.new(string.format('%02XFF0000', nHealthPrecent)))
		else
			AlienFxLib.SetLocationColor(knAllLocations, ApolloColor.new(string.format('%02X0000FF', nHealthPrecent)))
		end
	end
end

local AlienFxInst = AlienFx:new()
AlienFxInst:Init()
