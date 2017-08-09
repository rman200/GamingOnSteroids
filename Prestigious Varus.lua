local function GetDistance(p1,p2)
return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2) + math.pow((p2.z - p1.z),2))
end

local function GetDistance2D(p1,p2)
return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2))
end

local function GetDistanceSqr(p1, p2)
    local dx, dz = p1.x - p2.x, p1.z - p2.z 
    return dx * dx + dz * dz
end

local _EnemyHeroes
local function GetEnemyHeroes()
	if _EnemyHeroes then return _EnemyHeroes end
	_EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isEnemy then
			table.insert(_EnemyHeroes, unit)
		end
	end
	return _EnemyHeroes
end

function IsImmobileTarget(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
end


local _OnVision = {}
function OnVision(unit)
	if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.visible , tick = GetTickCount(), pos = unit.pos} end
	if _OnVision[unit.networkID].state == true and not unit.visible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = GetTickCount() end
	if _OnVision[unit.networkID].state == false and unit.visible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = GetTickCount() end
	return _OnVision[unit.networkID]
end
Callback.Add("Tick", function() OnVisionF() end)
local visionTick = GetTickCount()
function OnVisionF()
	if GetTickCount() - visionTick > 100 then
		for i,v in pairs(GetEnemyHeroes()) do
			OnVision(v)
		end
	end
end

local _OnWaypoint = {}
function OnWaypoint(unit)
	if _OnWaypoint[unit.networkID] == nil then _OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
	if _OnWaypoint[unit.networkID].pos ~= unit.posTo then 
		-- print("OnWayPoint:"..unit.charName.." | "..math.floor(Game.Timer()))
		_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
			DelayAction(function()
				local time = (Game.Timer() - _OnWaypoint[unit.networkID].time)
				local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
				if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
					_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
					-- print("OnDash: "..unit.charName)
				end
			end,0.05)
	end
	return _OnWaypoint[unit.networkID]
end

local function GetPred(unit,speed,delay)
	local speed = speed or math.huge
	local delay = delay or 0.25
	local unitSpeed = unit.ms
	if OnWaypoint(unit).speed > unitSpeed then unitSpeed = OnWaypoint(unit).speed end
	if OnVision(unit).state == false then
		local unitPos = unit.pos + Vector(unit.pos,unit.posTo):Normalized() * ((GetTickCount() - OnVision(unit).tick)/1000 * unitSpeed)
		local predPos = unitPos + Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unitPos)/speed)))
		if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
		return predPos
	else
		if unitSpeed > unit.ms then
			local predPos = unit.pos + Vector(OnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unit.pos)/speed)))
			if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
			return predPos
		elseif IsImmobileTarget(unit) then
			return unit.pos
		else
			return unit:GetPrediction(speed,delay)
		end
	end
end

local function GetBuffs(unit)
  local t = {}
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff.count > 0 then
      table.insert(t, buff)
    end
  end
  return t
end

function HasBuff(unit, buffname)
  for i, buff in pairs(GetBuffs(unit)) do
    if buff.name == buffname then --and buff.duration > 0
      return true
    end
  end
  return false
end

function WStacks(target)
    for i, buff in pairs(GetBuffs(target)) do
 		if buff.name == "VarusWDebuff" then 
 	   		return buff.count
 	    end 	    
 	end
 	return 0
end

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

local Orb = 3
local TEAM_ALLY = myHero.team
local TEAM_JUNGLE = 300
local TEAM_ENEMY = 300 - TEAM_ALLY
local QData = {casting = false, start = Game.Timer()}
local counter = Game.Timer()


local function GetTarget(range) --temp version
	local target = nil 
		if Orb == 1 then
			target = EOW:GetTarget(range, EOW.easykill_acd)
		elseif Orb == 2 then 
			target = _G.SDK.TargetSelector:GetTarget(range)
		elseif Orb == 3 then
			target = GOS:GetTarget(range)
		end
		return target 
end


local intToMode = {
  	[0] = "",
  	[1] = "Combo",
  	[2] = "Harass",
  	[3] = "LastHit",
  	[4] = "Clear"
}
function GetMode()
	if Orb == 1 then
		return intToMode[EOW.CurrentMode]
	elseif Orb == 2 then
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			return "Combo"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
			return "Harass"	
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			return "Clear"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			return "LastHit"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
			return "Flee"
		end
	else
		return GOS.GetMode()
	end
end

local ItemHotKey = {
    [ITEM_1] = HK_ITEM_1,
    [ITEM_2] = HK_ITEM_2,
    [ITEM_3] = HK_ITEM_3,
    [ITEM_4] = HK_ITEM_4,
    [ITEM_5] = HK_ITEM_5,
    [ITEM_6] = HK_ITEM_6,
}

local function GetItemSlot(unit, id)
  for i = ITEM_1, ITEM_7 do
    if unit:GetItemData(i).itemID == id then
      return i
    end
  end
  return 0 
end



local function IsValidTarget(unit, range)
   	return unit and unit.team == TEAM_ENEMY and unit.dead == false and GetDistanceSqr(myHero.pos, unit.pos) <= (range + myHero.boundingRadius + unit.boundingRadius)^2 and unit.isTargetable and unit.isTargetableToTeam and unit.isImmortal == false and unit.visible
end

local menu = 1

class "Varus"

require 'DamageLib'

function Varus:__init()
	if menu ~= 1 then return end
	menu = 2
	if myHero.charName ~= "Varus" then return end
	self:LoadSpells()
  	self:LoadMenu()

  	if _G.EOWLoaded then
			Orb = 1
	elseif _G.SDK and _G.SDK.Orbwalker then
			Orb = 2
	end	
 	PrintChat("Prestigious Varus Loaded.Good Look!") 	                                            --Init
  	Callback.Add("Tick", function() self:Tick() end)
  	Callback.Add("Draw", function() self:Draw() end)
end

local Icons = {
["VarusIcon"] = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/c/c2/VarusSquare.png",
["Q"] = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/a/ac/Piercing_Arrow.png",
["W"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/0/0c/Blighted_Quiver.png",                --Icons
["E"] = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/8/86/Hail_of_Arrows.png",
["R"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/63/Chain_of_Corruption.png"
}

function Varus:LoadSpells()
  Q = { minRange = 925, maxRange = 1625, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
  W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
  E = { range = myHero:GetSpellData(_E).range, delay = 0.5, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
  R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }
end
--[[
function Varus:LoadMenu()                     
  --MainMenu
  self.Menu = MenuElement({type = MENU, id = "Varus", name = "Prestigious Varus", leftIcon = Icons["VarusIcon"]})
  --ComboMenu
  self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  self.Menu.Combo:MenuElement({id = "UseQ", name = "[Q] Piercing Arrow", value = true, leftIcon = Icons.Q})
  self.Menu.Combo:MenuElement({id = "UseW", name = "In AA Range, Only [Q] to proc [W]", value = true})
  self.Menu.Combo:MenuElement({id = "MinW", name = "[W] Min Stacks", value = 3, min = 1, max = 3, leftIcon = Icons.W})
  self.Menu.Combo:MenuElement({id = "UseE", name = "[E] Hail of Arrows", value = true, leftIcon = Icons.E})
  self.Menu.Combo:MenuElement({id = "UseR", name = "[R] Chain of Corruption", value = true, leftIcon = Icons.R})
  self.Menu.Combo:MenuElement({id = "MinR", name = "Min Enemies to use R", value = 1, min = 1, max = 5})
  --HarassMenu
  self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  --self.Menu.Harass:MenuElement({id = "AutoQ", name = "Auto Q Harass", key = string.byte("H"),toggle = true})
  self.Menu.Harass:MenuElement({id = "UseQ", name = "[Q] Piercing Arrow", value = true, leftIcon = Icons.Q})
  self.Menu.Harass:MenuElement({id = "UseW", name = "Only [Q] to proc [W]", value = false})
  self.Menu.Harass:MenuElement({id = "MinW", name = "[W] Min Stacks", value = 3, min = 1, max = 3, leftIcon = Icons.W})            --SandBox Blocks Icons? lol
  self.Menu.Harass:MenuElement({id = "UseE", name = "[E] Hail of Arrows", value = true, leftIcon = Icons.E})
  self.Menu.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass(%)", value = 65, min = 0, max = 100})
  --Drawing Menu
  self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings"})
  self.Menu.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true, leftIcon = Icons.Q})
  self.Menu.Drawing:MenuElement({id = "DrawR", name = "Draw [R] Range", value = true, leftIcon = Icons.R})
  --Killsteal Menu
  --self.Menu:MenuElement({type = MENU, id = "KS", name = "Kill Steal"})
  --self.Menu.KS:MenuElement({id = "UseQ", name = "[Q] Piercing Arrow", value = true, leftIcon = Icons.Q})
  --self.Menu.KS:MenuElement({id = "UseW", name = "[W] Blighted Quiver", value = true, leftIcon = Icons.W})
  --self.Menu.KS:MenuElement({id = "UseE", name = "[E] Hail of Arrows", value = true, leftIcon = Icons.E})
  --self.Menu.KS:MenuElement({id = "UseR", name = "[R] Chain of Corruption", value = true, leftIcon = Icons.R})
end]]
function Varus:LoadMenu()                     
  --MainMenu
  self.Menu = MenuElement({type = MENU, id = "Varus", name = "Prestigious Varus"})
  --ComboMenu
  self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  self.Menu.Combo:MenuElement({id = "UseQ", name = "[Q] Piercing Arrow", value = true})
  self.Menu.Combo:MenuElement({id = "UseW", name = "In AA Range, Only [Q] to proc [W]", value = true})
  self.Menu.Combo:MenuElement({id = "MinW", name = "[W] Min Stacks", value = 3, min = 1, max = 3})
  self.Menu.Combo:MenuElement({id = "UseE", name = "[E] Hail of Arrows", value = true})
  self.Menu.Combo:MenuElement({id = "UseR", name = "[R] Chain of Corruption", value = true})
  self.Menu.Combo:MenuElement({id = "MinR", name = "Min Enemies to use R", value = 2, min = 1, max = 5})
  --HarassMenu
  self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  --self.Menu.Harass:MenuElement({id = "AutoQ", name = "Auto Q Harass", key = string.byte("H"),toggle = true})
  self.Menu.Harass:MenuElement({id = "UseQ", name = "[Q] Piercing Arrow", value = true})
  self.Menu.Harass:MenuElement({id = "UseW", name = "Only [Q] to proc [W]", value = false})
  self.Menu.Harass:MenuElement({id = "MinW", name = "[W] Min Stacks", value = 3, min = 1, max = 3})
  self.Menu.Harass:MenuElement({id = "UseE", name = "[E] Hail of Arrows", value = false})
  self.Menu.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass(%)", value = 30, min = 0, max = 100})
  --Drawing Menu
  self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings"})
  self.Menu.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true})
  self.Menu.Drawing:MenuElement({id = "DrawR", name = "Draw [R] Range", value = true})
  self.Menu:MenuElement({id = "RKey", name = "Semi-Manual [R] Key [?]", key = string.byte("T"), tooltip = "Select manually your target before pressing the key"})
  --Killsteal Menu
  --self.Menu:MenuElement({type = MENU, id = "KS", name = "Kill Steal"})
  --self.Menu.KS:MenuElement({id = "UseQ", name = "[Q] Piercing Arrow", value = true, leftIcon = Icons.Q})
  --self.Menu.KS:MenuElement({id = "UseW", name = "[W] Blighted Quiver", value = true, leftIcon = Icons.W})
  --self.Menu.KS:MenuElement({id = "UseE", name = "[E] Hail of Arrows", value = true, leftIcon = Icons.E})
  --self.Menu.KS:MenuElement({id = "UseR", name = "[R] Chain of Corruption", value = true, leftIcon = Icons.R})
end

function Varus:Tick()
	self:CheckQ()
	if myHero.dead or Game.IsChatOpen() then return end
	--self:KS()		
	local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
	elseif Mode == "Harass" then 
		self:Harass()
	--elseif Mode == "Clear" then
		--self:Clear()
	end
end

function Varus:EnemiesAround(unit, range)
	local Count = 0
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)      
        if not Hero.dead and Hero.isEnemy and Hero.pos:DistanceTo(unit.pos) < range then
            Count = Count + 1            
        end
    end
    return Count
end

function Varus:SemiAutoR()
	local target = GetTarget(1625)
    if target == nil then return end
	if self.Menu.RKey:Value() and Ready(_R) then
		if not myHero.activeSpell.isCharging and IsValidTarget(target,1075) then
		local pos = GetPred(target, 1850, 0.25)
		if not pos:ToScreen().onScreen then
			pos = myHero.pos + Vector(myHero.pos,pos):Normalized() * math.random(530,760)
			Control.CastSpell(HK_R, pos)				
		else			
			Control.CastSpell(HK_R, pos)
		end     	
    end
	end
end


function Varus:StartCharging()
	if QData.casting == false and Control.IsKeyDown(HK_Q) == true and not myHero.activeSpell.isCharging then
	 	Control.KeyUp(HK_Q) 
	 	--PrintChat("gatilho")
	 	return
	end	
	Control.KeyDown(HK_Q)	
	--QData.casting = true
end

function Varus:CastQ(target)
	self:CheckQ()
	if not Ready(_Q) then return end
	--PrintChat(Game.Timer() - counter)
	if Game.Timer() - counter <= 0.5 then return end
	if QData.casting then
		local timer = Game.Timer() - QData.start
		local range = self:CalcQRange(timer)
		local pos = GetPred(target, Q.speed, Q.delay)
		if GetDistance(myHero.pos, pos) + 100 > range  then return end
		local mouse = mousePos
		
		if not pos:ToScreen().onScreen then
			pos = myHero.pos + Vector(myHero.pos,pos):Normalized() * math.random(530,760)
			Control.CastSpell(HK_Q, pos)
			--[[Control.SetCursorPos(pos)
			Control.KeyUp(HK_Q)
			DelayAction(function()
				if QData.casting then
					Control.SetCursorPos(mousePos)					
					QData.casting = false
				end
			end,0.05)]]				
		else
			--[[Control.SetCursorPos(pos)
			Control.KeyUp(HK_Q)
			DelayAction(function()
				if QData.casting then
					Control.SetCursorPos(mousePos)					
					QData.casting = false
				end
			end,0.05)]]
			Control.CastSpell(HK_Q, pos)
		end 
	else
		self:StartCharging()
	end
	counter = Game.Timer()

end

function Varus:Combo()
	--local activeSpell = myHero.activeSpell
	local target = GetTarget(1625)
    --if activeSpell.valid and activeSpell.spellWasCast == false then return end
    if target == nil then return end

	if Ready(_E) and self.Menu.Combo.UseE:Value() and IsValidTarget(target,875) and not myHero.activeSpell.isCharging then
		local pos = GetPred(target, E.speed, E.delay)
		if pos:ToScreen().onScreen then
			Control.CastSpell(HK_E, pos)		
		end   
	end
	if self.Menu.Combo.UseR:Value() and self:EnemiesAround(target, 600) >= self.Menu.Combo.MinR:Value() and Ready(_R) and not myHero.activeSpell.isCharging and IsValidTarget(target,1075) then
		local pos = GetPred(target, 1850, 0.25)
		if not pos:ToScreen().onScreen then
			pos = myHero.pos + Vector(myHero.pos,pos):Normalized() * math.random(530,760)
			Control.CastSpell(HK_R, pos)				
		else			
			Control.CastSpell(HK_R, pos)
		end     	
    end
	if self.Menu.Combo.UseQ:Value() and Ready(_Q) then	
		--PrintChat("ok")
		if self.Menu.Combo.UseW:Value() and IsValidTarget(target, 575) then
			if WStacks(target) >= self.Menu.Combo.MinW:Value() then
				self:CastQ(target)
			end
		else
			self:CastQ(target)	
		end
	end
end

function Varus:Harass()
	if (myHero.mana/myHero.maxMana < self.Menu.Harass.Mana:Value() / 100 ) then return end
	--local activeSpell = myHero.activeSpell
	local target = GetTarget(1625)
    --if activeSpell.valid and activeSpell.spellWasCast == false then return end
    if target == nil then return end

	if Ready(_E) and self.Menu.Harass.UseE:Value() and IsValidTarget(target,875) and not myHero.activeSpell.isCharging then
		local pos = GetPred(target, E.speed, E.delay)
		if pos:ToScreen().onScreen then
			Control.CastSpell(HK_E, pos)		
		end
	end	
	if self.Menu.Harass.UseQ:Value() and Ready(_Q) then	
		if self.Menu.Harass.UseW:Value() then
			if Wstacks(target) >= self.Menu.Harass.MinW:Value() then
				self:CastQ(target)
			end
		else
			self:CastQ(target)	
		end
	end
end

function Varus:KS()
	local target = GetTarget(1625)
    --if activeSpell.valid and activeSpell.spellWasCast == false then return end
    if target == nil then return end
	if Ready(_E) and self.Menu.KS.UseE:Value() and IsValidTarget(target,925) then
		local pos = GetPred(target, E.speed, E.delay)
		Control.CastSpell(HK_E, pos)
	end	
	if self.Menu.KS.UseQ:Value() and Ready(_Q) then	
		self:CastQ(target)	
	end
end
--[[function Varus:KS()
	for i,target in pairs(GetEnemyHeroes()) do
	if not target.dead and target.isTargetable and target.valid and (OnVision(target).state == true or (OnVision(target).state == false and GetTickCount() - OnVision(target).tick < 500)) then
		if self.Menu.KS.useE:Value() then
			if Ready(_E) and GetDistance(myHero.pos,target.pos) < 925 then
				local hp = target.health + target.shieldAP + target.shieldAD
				local dmg = getdmg("E", target)
				if hp < dmg then
					local pos = GetPred(target, E.speed, E.delay)
					Control.CastSpell(HK_E, pos)
					return
				end
			end
		end
		if self.Menu.KS.useQ:Value() then
			if Ready(_Q) and GetDistance(myHero.pos,target.pos) < 1500 then
				local hp = target.health + target.shieldAP + target.shieldAD
				local dmg = getdmg("Q", target)
				if hp < dmg then
					self:CastQ(target)
				end
			end
		end
		
	end
end]]

function Varus:CalcQRange(timer)
	local delta = Q.maxRange - Q.minRange
	local min = Q.minRange
	local total = delta / 1.4 * timer + min
	if total > Q.maxRange then total = Q.maxRange end

	return total
end

function Varus:DrawQRange()
	--PrintChat(QData.start)
	
	if QData.casting then
		
		local timecasting = Game.Timer() - QData.start
		local range = self:CalcQRange(timecasting)
		Draw.Circle(myHero, range, 3, Draw.Color(255, 225, 255, 10))
	else
		Draw.Circle(myHero, Q.maxRange, 1, Draw.Color(255, 225, 255, 10))
	end
end

function Varus:CheckQ()
	if HasBuff(myHero, "VarusQ") then
		QData.casting = true
		QData.start = myHero.activeSpell.startTime
		--PrintChat("sembug")
	else
		--PrintChat("bug")
		QData.casting = false
	end
	
end

function Varus:Draw()

    if myHero.dead then return end
    --PrintChat(QData.casting)
    if(self.Menu.Drawing.DrawR:Value())then
        Draw.Circle(myHero, 1075, 3, Draw.Color(255, 225, 255, 10))
    end                                                 --OnDraw
    if(self.Menu.Drawing.DrawQ:Value())then
        self:DrawQRange()
    end    
end

function OnLoad()
 	Varus()
end

