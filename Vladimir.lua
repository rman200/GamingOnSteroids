class "Vladimir"

require = 'DamageLib'

local function Ready(spell)
		return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 
end 
local function HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end


function Vladimir:__init()
	if myHero.charName ~= "Vladimir" then return end
	PrintChat("Count Vladimir is ready")
	self:LoadSpells()
	self:LoadMenu()	
	self.chargeE = false
	self.eTick = GetTickCount()																							--Init
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Vladimir:Tick()
	if myHero.dead then return end
		self:castingE()
		if self.Menu.Lasthit.AutoQ:Value() then
			self:LastHit()
		end
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			self:Combo()
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then								--OnTick
			self:Harass()
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			self:Clear()
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			self:LastHit()
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
			--self:Flee()	
		end
end

function Vladimir:Combo()
	if _G.SDK.TargetSelector:GetTarget(600) == nil then return end
	local target = _G.SDK.TargetSelector:GetTarget(600)
	if self.chargeE == true and Ready(_W) and self.Menu.Combo.UseW:Value() then
		Control.CastSpell(HK_W)
	end
	if self.Menu.Combo.UseR:Value() and Ready(_R) and self.chargeE == false then
		if EnemiesAround(target.pos, 400) >= self.Menu.Combo.MinR:Value() then
			Control.CastSpell(HK_R, target.pos)
    	end
    end
    if self.Menu.Combo.UseE:Value() and Ready(_E) and target ~= nil and self.chargeE == false then														--Combo
    	self:useE()

    end
	if self.Menu.Combo.UseQ:Value() and Ready(_Q) and target ~= nil and self.chargeE == false then
		Control.CastSpell(HK_Q, target)
	end		
end

function Vladimir:Harass()
	if _G.SDK.TargetSelector:GetTarget(Q.range) == nil then return end
	if self.Menu.Harass.UseQ:Value() and Ready(_Q) then
		local Qtarg = _G.SDK.TargetSelector:GetTarget(Q.range)												--Harass
		Control.CastSpell(HK_Q, Qtarg)
	end
end
function Vladimir:LastHit()
	if Ready(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			if  minion.team == 200 then
				local Qbuffed = (({148, 185, 222, 259, 296})[level] + 1.11 * myHero.ap)
				local Qdamage = (({80, 100, 120, 140, 160})[level] + 0.6 * myHero.ap)
				if myHero.pos:DistanceTo(minion.pos) < 600 and self.Menu.Lasthit.UseQ:Value() and minion.isEnemy and self.HasBuff(myHero,"vladimirqfrenzy") then
					if Qbuffed >= minion.health then
						Control.CastSpell(HK_Q,minion)
					end					
				elseif myHero.pos:DistanceTo(minion.pos) < 600 and self.Menu.Lasthit.UseQ:Value() and minion.isEnemy then
					if Qdamage >= minion.health then
						Control.CastSpell(HK_Q,minion)																																					--Last Hit
					end
				end				
      		end
		end
	end
end

function Vladimir:Clear()
	if self.Menu.Clear.Usage:Value() == false or self.chargeE == true then return end
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
		if  minion.team == 200 or minion.team == 300 then
			if self:IsValidTarget(minion,600) and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 600 and self.Menu.Clear.UseQ:Value() and minion.isEnemy then
				Control.CastSpell(HK_Q,minion.pos)
			end
			if self:IsValidTarget(minion,600) and Ready(_E) and myHero.pos:DistanceTo(minion.pos) < 600 and self.Menu.Clear.UseE:Value() and minion.isEnemy then
				if CountEnemyMinions(600) >= self.Menu.Clear.EHit:Value() then
					Control.CastSpell(HK_E)
				end
			end
		end
	end
end

function Vladimir:useE()
	local target = _G.SDK.TargetSelector:GetTarget(600)
	local ePred = target:GetPrediction(math.huge,0.35 + Game.Latency()/1000)
	local ePred2 = target:GetPrediction(math.huge,1)
	if ePred and ePred2 then
		if myHero.pos:DistanceTo(ePred2.pos) < 600 then
			Control.CastSpell(HK_E)
			
		end
	end	
end

function Vladimir:castingE()
	local eBuff = GetBuffData(myHero,"VladimirE")
	if self.chargeE == false and eBuff.count > 0 then
		self.chargeE = true
	end
	if self.chargeE == true and eBuff.count == 0 then
		self.chargeE = false
		
	end
	
end

function EnemiesAround(pos, range)
    local Count = 0
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)      
        if not Hero.dead and Hero.isEnemy and Hero.pos:DistanceTo(pos, Hero.pos) < range then
            Count = Count + 1
        end
    end
    return Count
end

function Vladimir:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal 
end

function Vladimir:HasBuff(unit, buffname)
	if unit.buffCount ~= nil then
		for i = 0, unit.buffCount do
			local buff = unit:GetBuff(i)
			if buff.name == buffname and buff.count > 0 then 
				return true
			end
		end
	end
	return false
end

function CountEnemyMinions(range)
	local minionsCount = 0
    for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
            minionsCount = minionsCount + 1
        end
    end
    return minionsCount
end

local Icons = {
["VladimirIcon"] = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/5/50/Crimson_Pact.png",
["Q"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/66/Transfusion.png",
["W"] = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/8/86/Sanguine_Pool.png",								--Icons
["E"] = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/6/65/Tides_of_Blood.png",
["R"] = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/8/84/Hemoplague.png",
}

function Vladimir:LoadSpells()

	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }
end

function Vladimir:LoadMenu()											
	--MainMenu
	self.Menu = MenuElement({type = MENU, id = "Vladimir", name = "Count Vladimir", leftIcon = Icons["VladimirIcon"]})
	--ComboMenu
	self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "[Q] Transfusion", value = true, leftIcon = Icons.Q})
	self.Menu.Combo:MenuElement({id = "UseW", name = "[W] Sanguine Pool", value = true, leftIcon = Icons.Q})
	self.Menu.Combo:MenuElement({id = "UseE", name = "[E] Tides of Blood", value = true, leftIcon = Icons.E})
	self.Menu.Combo:MenuElement({id = "UseR", name = "[R] Hemoplague", value = true, leftIcon = Icons.R})
	self.Menu.Combo:MenuElement({id = "MinR", name = "Min Enemies to use R", value = 2, min = 1, max = 5})
	--HarassMenu
	self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
	self.Menu.Harass:MenuElement({id = "UseQ", name = "[Q] Transfusion", value = true, leftIcon = Icons.Q})
	--LaneClear Menu
	self.Menu:MenuElement({type = MENU, id = "Clear", name = "Lane Clear"})
	self.Menu.Clear:MenuElement({id = "Usage", name = "Spells Usage", key = string.byte("A"),toggle = true})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "[Q] Transfusion", value = true, leftIcon = Icons.Q})					--Menus
	self.Menu.Clear:MenuElement({id = "UseE", name = "[E] Tides of Blood", value = true, leftIcon = Icons.E})
	self.Menu.Clear:MenuElement({id = "EHit", name = "[E] if x minions", value = 3, min = 1, max = 7})
	--LastHit Menu
	self.Menu:MenuElement({type = MENU, id = "Lasthit", name = "Lasthit"})
	self.Menu.Lasthit:MenuElement({id = "AutoQ", name = "Auto Q Lasthit", key = string.byte("K"),toggle = true})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "[Q] Transfusion", value = true, leftIcon = Icons.Q})
	--Drawing Menu
	self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings"})
	self.Menu.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true, leftIcon = Icons.Q})
	self.Menu.Drawing:MenuElement({id = "DrawE", name = "Draw [E] Range", value = true, leftIcon = Icons.E})
end


function Vladimir:Draw()
	if myHero.dead then return end
	if(self.Menu.Drawing.DrawE:Value())then
		Draw.Circle(myHero, E.range + 100, 3, Draw.Color(255, 225, 255, 10))
	end 																								--OnDraw
	if(self.Menu.Drawing.DrawQ:Value())then
		Draw.Circle(myHero, 550, 3, Draw.Color(225, 225, 0, 10))
	end
end




function OnLoad()
	Vladimir()
end




