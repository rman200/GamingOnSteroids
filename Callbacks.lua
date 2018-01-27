--[[Buff Type]]

_G.BUFF_NONE = 0
_G.BUFF_GLOBAL = 1
_G.BUFF_BASIC = 2
_G.BUFF_DEBUFF = 3
_G.BUFF_STUN = 5
_G.BUFF_STEALTH = 6
_G.BUFF_SILENCE = 7
_G.BUFF_TAUNT = 8
_G.BUFF_SLOW = 10
_G.BUFF_ROOT = 11
_G.BUFF_DOT = 12
_G.BUFF_REGENERATION = 13
_G.BUFF_SPEED = 14
_G.BUFF_MAGIC_IMMUNE = 15
_G.BUFF_PHYSICAL_IMMUNE = 16
_G.BUFF_IMMUNE = 17
_G.BUFF_Vision_Reduce = 19
_G.BUFF_FEAR = 21
_G.BUFF_CHARM = 22
_G.BUFF_POISON = 23
_G.BUFF_SUPPRESS = 24
_G.BUFF_BLIND = 25
_G.BUFF_STATS_INCREASE = 26
_G.BUFF_STATS_DECREASE = 27
_G.BUFF_FLEE = 28
_G.BUFF_KNOCKUP = 29
_G.BUFF_KNOCKBACK = 30
_G.BUFF_DISARM = 31

--[[Global Tables]]
_G._SPELL_TABLE_PROCESS = {}
_G._ANIMATION_TABLE = {}
_G._VISION_TABLE = {}
_G._LEVEL_UP_TABLE = {}
_G._ITEM_TABLE = {}
_G._PATH_TABLE = {}

local function GetDistanceSqr(p1, p2)    	--Works with both vectors and objects
	p2 = p2 or myHero
	p1 = p1.pos or p1
 		p2 = p2.pos or p2
    local dx, dz = p1.x - p2.x, p1.z - p2.z 
    return dx * dx + dz * dz
end
local function GetDistance(p1, p2)
	return math.sqrt(GetDistanceSqr(p1, p2))
end

  class 'BuffExplorer'
	
	function BuffExplorer:__init()
		__BuffExplorer = true
		self.Heroes = {}
		self.Buffs  = {}
		self.RemoveBuffCallback = {}
		self.UpdateBuffCallback = {}
		for i = 1, Game.HeroCount() do
        	local hero = Game.Hero(i)
       		table.insert(self.Heroes, hero)
        	self.Buffs[hero.networkID] = {}
    	end
     	Callback.Add("Tick", function () self:Tick() end)
     	Callback.Add("GameEnd", function() Callback.Del("Tick", function () self:Tick() end) end)
	end

	function BuffExplorer:RemoveBuff(unit,buff)
		for i, cb in pairs(self.RemoveBuffCallback) do
			cb(unit,buff)
		end
	end
	
	function BuffExplorer:UpdateBuff(unit,buff)
		for i, cb in pairs(self.UpdateBuffCallback) do
			cb(unit,buff)
		end
	end
	
	function BuffExplorer:Tick()
		if self.UpdateBuffCallback ~= {} then
			for _, hero in pairs(self.Heroes) do
				for i = 0, hero.buffCount do
					local buff = hero:GetBuff(i)
					if self:Valid(buff) then
						if not self.Buffs[hero.networkID][buff.name] or (self.Buffs[hero.networkID][buff.name] and self.Buffs[hero.networkID][buff.name].expireTime ~= buff.expireTime) then
							self.Buffs[hero.networkID][buff.name] = {expireTime = buff.expireTime, sent = true, networkID = buff.sourcenID, buff = buff}
							self:UpdateBuff(hero,buff)
						end
					end
				end
			end
		end
		if self.RemoveBuffCallback ~= {} then
			for _, hero in pairs(self.Heroes) do
				for buffname,buffinfo in pairs(self.Buffs[hero.networkID]) do
					if buffinfo.expireTime < Game.Timer() then
						self:RemoveBuff(hero,buffinfo.buff)
						self.Buffs[hero.networkID][buffname] = nil
						
					end
				end
			end
		end
	end
	
	function BuffExplorer:Valid(buff)
		return buff and buff.name and #buff.name > 0 and buff.startTime <= Game.Timer() and buff.expireTime > Game.Timer()
	end


class("Animation")

function Animation:__init()
	_G._ANIMATION_STARTED = true
	self.OnAnimationCallback = {}
	for _ = 0, Game.HeroCount() do
		local obj = Game.Hero(_)
		if obj then
			if obj.charName ~= "" then
				_ANIMATION_TABLE[obj.networkID] = {animation = ""}
			end
		end
	end
	Callback.Add("Tick", function () self:Tick() end)
	Callback.Add("GameEnd", function() Callback.Del("Tick", function () self:Tick() end) end)
end

function Animation:Tick()
	if self.OnAnimationCallback ~= {} then
		for i = 0, Game.HeroCount() do
			local hero = Game.Hero(i)
			local netID = hero.networkID
			if hero.activeSpellSlot then
				local _animation = hero.attackData.animationTime
				if _ANIMATION_TABLE[netID] and _ANIMATION_TABLE[netID].animation ~= _animation then
					self:Animating(hero, hero.attackData.animationTime)
					_ANIMATION_TABLE[netID].animation = _animation
				end
			end
		end
	end
end

function Animation:Animating(unit, animation)
	for _, Emit in pairs(self.OnAnimationCallback) do
		Emit(unit, animation)
	end
end



class("Vision")

function Vision:__init()
	self.GainVisionCallback = {}
	self.LoseVisionCallback = {}
	_G._VISION_STARTED = true
	for _ = 0, Game.HeroCount() do
		local obj = Game.Hero(_)
		if obj then
			_VISION_TABLE[obj.networkID] = {visible = obj.visible}
		end
	end
	Callback.Add("Tick", function () self:Tick() end)
	Callback.Add("GameEnd", function() Callback.Del("Tick", function () self:Tick() end) end)
end

function Vision:Tick()
	for i = 0, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero then
			local netID = hero.networkID
			if self.LoseVisionCallback ~= {} then
				if hero.visible == false and _VISION_TABLE[netID] and _VISION_TABLE[netID].visible == true then
					_VISION_TABLE[netID] = {visible = hero.visible}
					self:LoseVision(hero)
				end
			end
			if self.GainVisionCallback ~= {} then
				if hero.visible == true and _VISION_TABLE[netID] and _VISION_TABLE[netID].visible == false then
					_VISION_TABLE[netID] = {visible = hero.visible}
					self:GainVision(hero)
				end
			end
		end
	end
end

function Vision:LoseVision(unit)
	for _, Emit in pairs(self.LoseVisionCallback) do
		Emit(unit)
	end
end
	
function Vision:GainVision(unit)
	for _, Emit in pairs(self.GainVisionCallback) do
		Emit(unit)
	end
end

class "Path"

function Path:__init()
	self.OnNewPathCallback = {}
	self.OnDashCallback = {}
	_G._PATH_STARTED = true
	for _ = 0, Game.HeroCount() do
		local obj = Game.Hero(_)
		if obj then
			_PATH_TABLE[obj.networkID] = {
			pos = obj.posTo,
			speed = obj.ms,
			time = Game.Timer()
			}
		end
	end
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("UnLoad", function() Callback.Del("Tick", function () self:Tick() end) end)
end

function Path:Tick()
	if #self.OnNewPathCallback ~= 0 or #self.OnDashCallback ~= 0 then
		for i = 0, Game.HeroCount() do
			local hero = Game.Hero(i)
			self:OnPath(hero)			
		end
	end
end

function Path:OnPath(unit)
	if unit and Game and not _PATH_TABLE[unit.networkID] then
		_PATH_TABLE[unit.networkID] = {
			pos = unit.posTo,
			speed = unit.ms,
			time = Game.Timer()			
		}
	end
 	
	if unit and Game and _PATH_TABLE[unit.networkID] and _PATH_TABLE[unit.networkID].pos ~= unit.posTo then
		local path = unit.pathing
		if not path then return end
        local isDash = path.isDashing
        local dashSpeed = path.dashSpeed or 0
        local dashGravity = path.dashGravity or 0
        local dashDistance = GetDistance(unit.pos, unit.posTo)
        --
        _PATH_TABLE[unit.networkID] = {
        	startPos = unit.pos,
        	pos = unit.posTo ,
           	speed = unit.ms,
           	time = Game.Timer()
        }
            --
        for k, cb in pairs(self.OnNewPathCallback) do
        	cb(unit, unit.pos, unit.posTo, isDash, dashSpeed, dashGravity, dashDistance)
        end
        --
        if isDash then
        	for k, cb in pairs(self.OnDashCallback) do
        		cb(unit, unit.pos, unit.posTo, dashSpeed, dashGravity, dashDistance)
        	end
        end
	end
end

class("LevelUp")

function LevelUp:__init()
	_G._LEVEL_UP_START = true
	self.OnLevelUpCallback = {}
	for _ = 0, Game.HeroCount() do
		local obj = Game.Hero(_)
		if obj then
			_LEVEL_UP_TABLE[obj.networkID] = {level = 0}
		end
	end
	Callback.Add("Tick", function () self:Tick() end)
	Callback.Add("GameEnd", function() Callback.Del("Tick", function () self:Tick() end) end)
end

function LevelUp:Tick()
	if self.OnLevelUpCallback ~= {} then
		for i = 0, Game.HeroCount() do
			local hero = Game.Hero(i)
			local level = hero.levelData.lvl
			local netID = hero.networkID
			if _LEVEL_UP_TABLE[netID] and level and _LEVEL_UP_TABLE[netID].level ~= level then
				self:LevelUpCallback(hero, hero.levelData)
				_LEVEL_UP_TABLE[netID].level = level
			end
		end
	end
end

function LevelUp:LevelUpCallback(unit, level)
	for _, Emit in pairs(self.OnLevelUpCallback) do
		Emit(unit, level)
	end
end

class("ItemEvents")

function ItemEvents:__init()
	self.BuyItemCallback = {}
	self.SellItemCallback = {}
	_G._ITEM_CHECKER_STARTED = true
	for i = ITEM_1, ITEM_7 do
		if myHero:GetItemData(i).itemID ~= 0 then
			_ITEM_TABLE[i] = {has = true, data = myHero:GetItemData(i)}
		else
			_ITEM_TABLE[i] = {has = false, data = nil}
		end
	end

	Callback.Add("Tick", function () self:Tick() end)
	Callback.Add("GameEnd", function() Callback.Del("Tick", function () self:Tick() end) end)
end

function ItemEvents:Tick()
	for i = ITEM_1, ITEM_7 do
		if myHero:GetItemData(i).itemID ~= 0 then
			if _ITEM_TABLE[i].has == false then
				_ITEM_TABLE[i].has = true
				_ITEM_TABLE[i].data = myHero:GetItemData(i)
				self:BuyItem(myHero:GetItemData(i), i)
			end
		else
			if _ITEM_TABLE[i].has == true then
				self:SellItem(_ITEM_TABLE[i].data, i)
				_ITEM_TABLE[i].has = false
				_ITEM_TABLE[i].data = nil
			end
		end
	end
end


function ItemEvents:BuyItem(item, slot)
	for _, Emit in pairs(self.BuyItemCallback) do
		Emit(item, slot)
	end
end

function ItemEvents:SellItem(item, slot)
	for _, Emit in pairs(self.SellItemCallback) do
		Emit(item, slot)
	end
end

function OnLevelUp(fn)
    table.insert(LevelUp.OnLevelUpCallback, fn)
end

function OnNewPath(fn)
    table.insert(Path.OnNewPathCallback, fn)
end

function OnDash(fn)
    table.insert(Path.OnDashCallback, fn)
end

function OnGainVision(fn)
    table.insert(Vision.GainVisionCallback, fn)
end

function OnLoseVision(fn)
    table.insert(Vision.LoseVisionCallback, fn)
end

function OnAnimation(fn)
    table.insert(Animation.OnAnimationCallback, fn)
end

function OnUpdateBuff(cb)
    table.insert(BuffExplorer.UpdateBuffCallback,cb)
end

function OnRemoveBuff(cb)
    table.insert(BuffExplorer.RemoveBuffCallback,cb)
end

function OnBuyItem(fn)
    table.insert(ItemEvents.BuyItemCallback, fn)
end

function OnSellItem(fn)
    table.insert(ItemEvents.SellItemCallback, fn)
end

function Unload()
	_G._SPELL_TABLE_PROCESS = {}
	_G._ANIMATION_TABLE = {}
	_G._VISION_TABLE = {}
	_G._LEVEL_UP_TABLE = {}
	_G._ITEM_TABLE = {}
	_G._PATH_TABLE = {}
	--
	if _ITEM_CHECKER_STARTED then  
		ItemEvents.SellItemCallback = {}
		ItemEvents.BuyItemCallback = {}
	end
	if _PATH_STARTED then  
		Path.OnNewPathCallback = {}
		Path.OnDashCallback = {}
	end
	if _VISION_STARTED then  
		Vision.GainVisionCallback = {}
		Vision.LoseVisionCallback = {}
	end
	if _ANIMATION_STARTED then  
		Animation.OnAnimationCallback = {}
	end
	if __BuffExplorer_Loaded then	
		BuffExplorer.UpdateBuffCallback = {}
		BuffExplorer.RemoveBuffCallback = {}
	end
	if _LEVEL_UP_START then  
		LevelUp.OnLevelUpCallback = {}
	end
end

--Callback.Add("GameEnd", function() Unload() end)


local curCallbacks = {
	["levelup"] = function()
		if not _LEVEL_UP_START then  
			_G.LevelUp = LevelUp()
		end
	end,
	["buffexplorer"] = function()
		if not __BuffExplorer_Loaded then	
			_G.BuffExplorer = BuffExplorer() 
		end	
	end,
	["animation"] = function()
		if not _ANIMATION_STARTED then  
			_G.Animation = Animation()
		end
	end,
	["vision"] = function()
		if not _VISION_STARTED then  
			_G.Vision = Vision()
		end
	end,
	["path"] = function()
		if not _PATH_STARTED then  
			_G.Path = Path()
		end
	end,
	["item"] = function()
		if not _ITEM_CHECKER_STARTED then  
			_G.ItemEvents = ItemEvents()
		end
	end
}

return {
	["Load"] = function(tbl)
		for index, event in pairs(tbl) do
			if curCallbacks[event:lower()] then
				curCallbacks[event:lower()]()
				print("*** Callbacks | " ..event .. " | Loaded.")				
			end
		end
	end
}

-- PARA EL SHIELD HACER UNIT.BUFF DE SOLO ESE Y HACER CHECK DEL NOMBRE, MIRAR SIVIR E
