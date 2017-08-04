local function GetDistanceSqr(p1, p2)
    local dx, dz = p1.x - p2.x, p1.z - p2.z 
    return dx * dx + dz * dz
end
    
local sqrt = math.sqrt
local function GetDistance(p1, p2)
    return sqrt(GetDistanceSqr(p1, p2))
end

local function GetDistance2D(p1,p2)
	return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2))
end

function GetDistanceSqr(Pos1, Pos2)
	local Pos2 = Pos2 or myHero.pos
	local dx = Pos1.x - Pos2.x
	local dz = (Pos1.z or Pos1.y) - (Pos2.z or Pos2.y)
	return dx * dx + dz * dz

end

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

local Orb = 3
local TEAM_ALLY = myHero.team
local TEAM_JUNGLE = 300
local TEAM_ENEMY = 300 - TEAM_ALLY


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

local function GetBuffIndexByName(unit,name)
	for i=1, unit.buffCount do
		local buff=unit:GetBuff(i)
		if buff.name == name and buff.duration>=0 then
			return i
		end
	end
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

function IsCollisionable(vector3)	
	--local targetPos = vector3:Unpack()
	return MapPosition:inWall(vector3)
end


local function IsImmobile(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
end

local function IsUnderEnemyTurret(pos)
	local turrets={}
	for i=1,Game.TurretCount() do
		local turret=Game.Turret(i)
		if turret.team~=myHero.team then
			if not turret.dead then
				table.insert(turrets,turret)
			end
		end 
	end
	for k,v in pairs(turrets) do
		if pos:DistanceTo(Vector(v.pos))<=915 then
			return true
		end
	end
	return false
end

local function IsUnderAllyTurret(pos)
	local turrets={}
	for i=1,Game.TurretCount() do
		local turret=Game.Turret(i)
		if turret.team==myHero.team then
			if not turret.dead then
				table.insert(turrets,turret)
			end
		end 
	end
	for k,v in pairs(turrets) do
		if pos:DistanceTo(Vector(v.pos))<=915 then
			return true
		end
	end
	return false
end


class "Vayne"

require "2DGeometry"
require "MapPositionGOS"
local EndLineDraw
local _OnWaypoint = {}




function Vayne:__init()
	if myHero.charName ~= "Vayne" then return end
	self:LoadSpells()
  	self:LoadMenu()
  	self.CanCast = false
	if _G.EOWLoaded then
			Orb = 1
	elseif _G.SDK and _G.SDK.Orbwalker then
			Orb = 2
	end	
 	PrintChat("Prestigious Vayne Loaded.Good Look!")
  	GetEnemyHeroes()                                             --Init
  	Callback.Add("Tick", function() self:Tick() end)
  	Callback.Add("Draw", function() self:Draw() end)
  	

end

local Icons = {
["VayneIcon"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/9/95/VayneSquare.png",
["Q"] = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/8/8d/Tumble.png",
["W"] = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/1/12/Silver_Bolts.png",                --Icons
["E"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/66/Condemn.png",
["R"] = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/b/b4/Final_Hour.png",
["BOTRK"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/2f/Blade_of_the_Ruined_King_item.png"
}

function Vayne:LoadSpells()
  Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
  W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
  E = { range = myHero:GetSpellData(_E).range, delay = 0.5, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
  R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }
end

function Vayne:LoadMenu()                     
--MainMenu
	self.Menu = MenuElement({type = MENU, id = "Vayne", name = "Prestigious Vayne", leftIcon = Icons["VayneIcon"]})
--ComboMenu
	self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "[Q] Tumble", value = true, leftIcon = Icons.Q})	
	self.Menu.Combo:MenuElement({id = "UseE", name = "[E] Condemn", value = true, leftIcon = Icons.E})
	self.Menu.Combo:MenuElement({id = "UseR", name = "[R] Final Hour", value = false, leftIcon = Icons.R})
	self.Menu.Combo:MenuElement({id = "MinR", name = "Min Enemies to Use Ult", value = 2, min = 1, max = 5}) 
	self.Menu.Combo:MenuElement({id = "BOTRK", name = "Blade of the Ruined King", value = 80, min = 1, max = 100, leftIcon = Icons.BOTRK})
--HarassMenu
	--self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
	self.Menu:MenuElement({id = "Mode", name = "Harass", value = 1,drop = {"None", "AA -> AA -> Q", "AA -> AA -> E", "AA -> Q -> E"}, leftIcon = Icons.Q})
	--self.Menu.Harass:MenuElement({id = "UseQ", name = "[Q] To Proc 3rd hit", value = true, leftIcon = Icons.Q})	
	--self.Menu.Harass:MenuElement({id = "UseE", name = "[E] To Proc 3rd Hit", value = true, leftIcon = Icons.E})
	--self.Menu.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass(%)", value = 65, min = 0, max = 100})
--Drawing Menu
	self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings"})
	--self.Menu.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true, leftIcon = Icons.Q})
	self.Menu.Drawing:MenuElement({id = "DrawR", name = "Draw [R] Range", value = true, leftIcon = Icons.R})
--Logic Menu
	self.Menu:MenuElement({type = MENU, id = "Logic", name = "Logic Menu"})
	self.Menu.Logic:MenuElement({id = "Q", name = "[Q] Logic", value = 1,drop = {"Prestigious Smart", "Agressive", "Kite[To Mouse]"}, leftIcon = Icons.Q})
	self.Menu.Logic:MenuElement({id = "W", name = "[W] Logic", value = true, leftIcon = Icons.W})
	self.Menu.Logic:MenuElement({id = "E", name = "[E] Logic", value = 1,drop = {"Prestigious", "PRADA SMART", "PRADA PERFECT", "OLD PRADA", "MARKSMAN", "SHARPSHOOTER", "GOSU", "VHR", "FASTEST"}, leftIcon = Icons.E})
	self.Menu.Logic:MenuElement({id = "Chance", name = "Condemn Hitchance", value = 50, min = 0, max = 100})
	self.Menu.Logic:MenuElement({id = "Push", name = "Condemn Distance", value = 450, min = 400, max = 475, step = 25})
	self.Menu.Logic:MenuElement({id = "InvTime", name = "Min Invisible Time Before Autos", value = 0.6, min = 0.1, max = 0.9, step = 0.1})
	self.Menu:MenuElement({id = "AutoE", name = "Auto Condemn", value = true, leftIcon = Icons.E})
	self.Menu:MenuElement({id = "Interrupt", name = "Use [E] to Interrupt *BETA*", value = true})
	self.Menu:MenuElement({id = "Peel", name = "Prestigious SelfPeel", value = true})
	self.Menu:MenuElement({name = "#----------------------Script Information----------------------#", drop = {" "}})
	self.Menu:MenuElement({name = "Script Version", drop = {"v1.0"}})
	self.Menu:MenuElement({name = "League Version", drop = {"7.15"}})
	self.Menu:MenuElement({name = "Author", drop = {"RMAN"}})
end

function Vayne:SelfPeel()	
	if not self.Menu.Peel:Value() then return end
	if not Ready(_E) then return end
	--[[
	for i = 1, Game.HeroCount() do	
		local target = Game.Hero(i)
		if target.dead == false and target.team == TEAM_ENEMY and target.visible and GetDistanceSqr(target.pos, myHero.pos) < 122500 then
		--myHero.pos:DistanceTo(path.endPos) < myHero.pos:DistanceTo(path.startPos)	
			local path = target.pathing
    		if path.hasMovePath then 
    			for i = path.pathIndex, path.pathCount do 
    				if path.isDashing then 
    					self.CanCast = true
    					break
    				end
    			end
    		end
		end
	end
	--PrintChat(self.CanCast)
	if self.CanCast then		 
		Control.CastSpell(HK_E,target)		
		self.CanCast = false
	end]]
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if not Hero.dead and Hero.isEnemy and GetDistanceSqr(Hero.pos, myHero.pos) < 122500 then			
			Control.CastSpell(HK_E,Hero)				
		end
	end
	
end

function Vayne:Interrupt()
	if not self.Menu.Interrupt:Value() then return end
	if not Ready(_E) then return end
	for i = 1, Game.HeroCount() do
		local target = Game.Hero(i)
		if not target.dead and target.isEnemy and GetDistanceSqr(target.pos, myHero.pos) < 302500 then
			if target.isChanneling then
				DelayAction(function()
					if target.isChanneling then
						Control.CastSpell(HK_E,target)
					end	
				end,1)
			end
		end
	end
end

function Vayne:EnemiesAround(range)
	local Count = 0
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)      
        if not Hero.dead and Hero.isEnemy and Hero.pos:DistanceTo() < range then
            Count = Count + 1
            
        end
    end
    return Count
end

function GetEnemyHeroes()
	if _EnemyHeroes then return _EnemyHeroes end
	_EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.team == TEAM_ENEMY then
			table.insert(_EnemyHeroes, unit)
		end
	end
	return _EnemyHeroes
end

function Vayne:WStacks(target)
    for i=1, target.buffCount do
        local Buff = target:GetBuff(i)
		if Buff.name:lower() == "vaynesilvereddebuff" and Game.Timer() < Buff.expireTime then
			return Buff.count
		end
	end
end       

function Vayne:AutoCondemn()


	local activeSpell = myHero.activeSpell
	local target = GetTarget(710)
	if not self.Menu.AutoE:Value() then return end
	if activeSpell.valid and activeSpell.spellWasCast == false then return end
	if not Ready(_E) then return end         
    if target == nil then return end    
    for i = 1, Game.HeroCount() do
        Hero = Game.Hero(i)      
        if IsValidTarget(Hero, 550) then
        	if self:IsCondemnable(Hero) then
        		Control.CastSpell(HK_E, Hero)
         		break						
			end
        end
    end
end


function Vayne:IsCondemnable(target)		--Sheet ton of logics
	local pP = myHero.pos
	local eP = target.pos
	local pD = self.Menu.Logic.Push:Value()	+ 25
	local mode = self.Menu.Logic.E:Value() 

	if mode == 1 then
		local heroPos = myHero.pos
		local targetPos = target.pos
		local distance = GetDistance(heroPos, targetPos)
		if distance < E.range then
			local EndPoint = heroPos + (targetPos - heroPos):Normalized() * (distance + self.Menu.Logic.Push:Value() + target.boundingRadius*0.5)
			local EndLine = LineSegment(Point(targetPos), Point(EndPoint))
			EndLineDraw = EndLine
			local Check = MapPosition:intersectsWall(EndLine)
			if Check then 
				return true
			end			
		end
		return false
	elseif mode == 2 and (IsCollisionable(eP:Extended(pP, -pD)) or IsCollisionable(eP:Extended(pP, -pD/2)) or IsCollisionable(eP:Extended(pP, -pD/3))) then
		if IsImmobile(target) or target.activeSpell.valid then
			return true
		end
		local enemiesCount = self:EnemiesAround(1200)
		if enemiesCount > 1 and enemiesCount <= 3 then
			for i=15, pD, 75 do
				vector3 = eP:Extended(pP, -i)
								
				if IsCollisionable(vector3) then
					return true
				end				
			end
		else
			local hitchance = self.Menu.Logic.Chance:Value()
			local angle = 0.2 * hitchance
			local travelDistance = 0.5
			local alpha = Vector((eP.x + travelDistance * math.cos(math.pi/180 * angle)), (eP.y + travelDistance * math.sin(math.pi/180 * angle)), 475)		
			local beta = Vector((eP.x - travelDistance * math.cos(math.pi/180 * angle)), (eP.y - travelDistance * math.sin(math.pi/180 * angle)), 475)
			for i=15, pD, 100 do
				local col1 = pP:Extended(alpha, i)
				local col2 = pP:Extended(beta, i)
				if i>pD then return false end
				if IsCollisionable(col1) and IsCollisionable(col2) then return true end
			end
			return false		
		end	
	elseif mode == 3 and (IsCollisionable(eP:Extended(pP, -pD)) or IsCollisionable(eP:Extended(pP, -pD/2)) or IsCollisionable(eP:Extended(pP, -pD/3))) then
		if IsImmobile(target) or target.activeSpell.valid then
			return true
		end
		local hitchance = self.Menu.Logic.Chance:Value()
		local angle = 0.2 * hitchance
		local travelDistance = 0.5
		local alpha = Vector((eP.x + travelDistance * math.cos(math.pi/180 * angle)), (eP.y + travelDistance * math.sin(math.pi/180 * angle)), 475)		
		local beta = Vector((eP.x - travelDistance * math.cos(math.pi/180 * angle)), (eP.y - travelDistance * math.sin(math.pi/180 * angle)), 475)
		for i=15, pD, 100 do
			local col1 = alpha:Extended(pP, -i)
			local col2 = beta:Extended(pP, -i)
			if IsCollisionable(col1) and IsCollisionable(col2) then return true end
			if i>pD then 
				return IsCollisionable(alpha:Extended(pP, -pD)) and IsCollisionable(beta:Extended(pP, -pD))
			end
			
		end
		return false		
	elseif mode == 4 then
		if IsImmobile(target) or target.activeSpell.valid then
			return true
		end
		local hitchance = self.Menu.Logic.Chance:Value()
		local angle = 0.2 * hitchance
		local travelDistance = 0.5
		local alpha = Vector((eP.x + travelDistance * math.cos(math.pi/180 * angle)), (eP.y + travelDistance * math.sin(math.pi/180 * angle)), 475)		
		local beta = Vector((eP.x - travelDistance * math.cos(math.pi/180 * angle)), (eP.y - travelDistance * math.sin(math.pi/180 * angle)), 475)
		for i=15, pD, 100 do
			local col1 = alpha:Extended(pP, -i)
			local col2 = beta:Extended(pP, -i)
			if IsCollisionable(col1) or IsCollisionable(col2) then return true end
		end
		return false		
	elseif mode == 5 then
		local prediction = target:GetPrediction(E.speed, E.delay)
		return IsCollisionable(prediction:Extended(pP, -pD)) or IsCollisionable(prediction:Extended(pP, -pD/2))
	elseif mode == 6 then
		local prediction = target:GetPrediction(E.speed, E.delay)
		for i=15, pD, 100 do
			if i > pD then return false end
			local posCF = prediction:Extended(pP, -i)
			if IsCollisionable(posCF) then return true end
		end
		return false
	elseif mode == 7 then
		local prediction = target:GetPrediction(E.speed, E.delay)
		for i=15, pD, 75 do
			if i > pD then return false end
			local posCF = prediction:Extended(pP, -i)
			if IsCollisionable(posCF) then return true end
		end
		return false
	elseif mode == 8 then
		local prediction = target:GetPrediction(E.speed, E.delay)
		for i=15, pD, target.boundingRadius do
			if i > pD then return false end
			local posCF = prediction:Extended(pP, -i)
			if IsCollisionable(posCF) then return true end
		end
		return false
	elseif mode == 9 and (IsCollisionable(eP:Extended(pP, -pD)) or IsCollisionable(eP:Extended(pP, -pD/2)) or IsCollisionable(eP:Extended(pP, -pD/3))) then
		return true 	
	else 
		return false 
	end
end

function Vayne:Tick()
	
	if myHero.dead or Game.IsChatOpen() then return end
	self:SelfPeel()
  	self:Interrupt()
	self:StayInvisible()
	self:AutoCondemn()
		
	local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
	elseif Mode == "Harass" then 
		self:Harass()
	--elseif Mode == "Clear" then
		--self:Clear()
	end
end

local function GetInvTime()
	return myHero:GetBuff(GetBuffIndexByName(myHero,"vaynetumblefade")).duration
end

function Vayne:StayInvisible()
	if GetInvTime()~=0 and GetInvTime()>=(1-self.Menu.Logic.InvTime:Value()) and GetInvTime() <= 1 then
		self:DisableAtk()
		--PrintChat("Disabled")
	else
		self:EnableAtk()
		--PrintChat("Enabled")
	end
end

function Vayne:DisableAtk()
	if Orb == 1 then
		EOW:SetAttacks(false)
	elseif Orb == 2 then
		_G.SDK.Orbwalker:SetAttack(false)
	elseif Orb == 3 then 
		GOS:BlockAttack(true)
	end		
end

function Vayne:EnableAtk()
	if Orb == 1 then
		EOW:SetAttacks(true)
	elseif Orb == 2 then
		_G.SDK.Orbwalker:SetAttack(true)
	elseif Orb == 3 then 
		GOS:BlockAttack(false)
	end		
end		

function Vayne:ForceTarget(target)
	if Orb == 1 then
		EOW:ForceTarget(target)
	elseif Orb == 2 then
		_G.SDK.Orbwalker.ForceTarget = target	
	elseif Orb == 3 then 
		GOS:ForceTarget(target)
	end		
end

function Vayne:Combo()
	self:ForceTarget(nil)	
	local activeSpell = myHero.activeSpell
	local target = GetTarget(550)
    if activeSpell.valid and activeSpell.spellWasCast == false then return end
    if target == nil then return end

    if self.Menu.Logic.W:Value() and Ready(_W) then
    	for i=1, Game.HeroCount() do
    		local Hero = Game.Hero(i)      
    	    if not Hero.dead and Hero.isEnemy and Hero.pos:DistanceTo(myHero.pos) < 550 then
    	        if self:WStacks(Hero) == 2 then
    	        	self:ForceTarget(Hero)
    	        end
    	    end
    	end
    end

    if self.Menu.Combo.UseE:Value() and not self.Menu.AutoE:Value() and IsValidTarget(target,550) and Ready(_E) then
    	if self:IsCondemnable(target) then
        	Control.CastSpell(HK_E, target)
		end
    end

    if self.Menu.Combo.UseR:Value() and self:EnemiesAround(800) >= self.Menu.Combo.MinR:Value() and Ready(_R) then
    	Control.CastSpell(HK_R)
    end

    if self.Menu.Combo.UseQ:Value() and Ready(_Q) and GetInvTime() == 0 and myHero.attackData.state == STATE_WINDDOWN then
    	local tpos
    	local mode1 = self.Menu.Logic.Q:Value()
    	if mode1 == 2 then
			tpos = self:GetAggressiveTumblePos(target)
		elseif mode1 == 3 then
			tpos = self:GetKitingTumblePos(target)
		elseif mode1 == 1 then
			tpos = self:GetSmartTumblePos(target)
		end
		if tpos ~= nil then Control.CastSpell(HK_Q,tpos) end
    end  
   
	if self.Menu.Combo.BOTRK:Value() then
    	local BOTRK = GetItemSlot(myHero, 3153)
    	local Cutlass = GetItemSlot(myHero, 3144)
    	if Cutlass >= 1 and Ready(Cutlass) and target.health/target.maxHealth <= self.Menu.Combo.BOTRK:Value()/100 then
			Control.CastSpell(ItemHotKey[Cutlass], target)
		elseif BOTRK >= 1 and Ready(BOTRK) and target.health/target.maxHealth < self.Menu.Combo.BOTRK:Value()/100 then
    		Control.CastSpell(ItemHotKey[BOTRK], target)
    	end
    end
end

function Vayne:Harass()
	self:ForceTarget(nil)
	local activeSpell = myHero.activeSpell
	local target = GetTarget(850)
	local mode1 = self.Menu.Mode:Value()
    if activeSpell.valid and activeSpell.spellWasCast == false then return end
    if target == nil then return end
    if self.Menu.Logic.W:Value() then
    	for i=1, Game.HeroCount() do
    		local Hero = Game.Hero(i)      
    	    if not Hero.dead and Hero.isEnemy and Hero.pos:DistanceTo() < 550 then
    	        if self:WStacks(Hero) == 2 then
    	        	self:ForceTarget(Hero)
    	        end
    	    end
    	end
    end 
    if mode1 == 2 and Ready(_Q) and GetInvTime() == 0 and myHero.attackData.state == STATE_WINDDOWN then
    	if self:WStacks(target) == 2 then
    		local tpos = self:GetSmartTumblePos(target)
			Control.CastSpell(HK_Q,tpos) 
		end
    end
    if mode1 == 3 and Ready(_E) and myHero.attackData.state == STATE_WINDDOWN then
    	if self:WStacks(target) == 2 then
    		Control.CastSpell(HK_E,target) 
		end
    end
    if mode1 == 4 and Ready(_Q) and Ready(_E) and GetInvTime() == 0 and myHero.attackData.state == STATE_WINDDOWN then
    	if self:WStacks(target) == 1 then
    		local tpos = self:GetSmartTumblePos(target)
			Control.CastSpell(HK_Q,tpos) 
			for t=1,1000 do
				if self:WStacks(target) == 2 then
    				Control.CastSpell(HK_E,target)
    				break 
				end
			end 
		end
	end	    
end

function Vayne:IsDangerousPosition(pos)
	if IsUnderEnemyTurret(pos) then return true end
	for i=1, Game.HeroCount() do
    	local Hero = Game.Hero(i)      
    	if not Hero.dead and Hero.isEnemy and Hero.pos:DistanceTo(pos) < 350 then return true end      
    end
   	return false
end
function Vayne:GetAggressiveTumblePos(target)
	if mousePos:DistanceTo(target.pos) < target.pos:DistanceTo() then return mousePos end
	--if not self:IsDangerousPosition(mousePos) then return mousePos end
end

function Vayne:GetKitingTumblePos(target)
	if not self:IsDangerousPosition(mousePos) then return mousePos end
end

function Vayne:GetSmartTumblePos(target)
	if not self:IsDangerousPosition(mousePos) then return mousePos end
	local p0 = myHero.pos
	local points= {	 
	[1] = p0 + 300*Vector(1,0,0), 
	[2] = p0 + 212*Vector(1,0,1), 
	[3] = p0 + 300*Vector(0,0,1), 
	[4] = p0 + 212*Vector(-1,0,1), 
	[5] = p0 + 300*Vector(-1,0,0),
	[6] = p0 + 212*Vector(-1,0,-1),
	[7] = p0 + 300*Vector(0,0,-1),
	[8] = p0 + 212*Vector(1,0,-1)}
	for i=1,#points do
		if not self:IsDangerousPosition(points[i]) and target.pos:DistanceTo(points[i]) < 500 then return points[i] end
	end
end

--[[function Vayne:GetTumblePos(tg, lg)
	
	if self.Menu.Logic.Q:Value() == 2 then
		return self.GetAggressiveTumblePos(target)
	elseif self.Menu.Logic.Q:Value() == 2 then
		return self.GetKitingTumblePos(target)
	elseif self.Menu.Logic.Q:Value() == 1 then
		return self.GetSmartTumblePos(target)
	end
end]]





function Vayne:Draw() --debug only
	--if Ready(_E) and EndLineDraw ~= nil then EndLineDraw:__draw(30, Draw.Color(255, 50, 000, 205)) end
	--PrintChat(self.Menu.Logic.Q:Value())
	--PrintChat(GetInvTime())
		
end



function OnLoad()
  Vayne()
end
