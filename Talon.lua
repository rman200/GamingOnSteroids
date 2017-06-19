class "Talon"

require = 'DamageLib'

local function Ready(spell)
		return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end 
local function HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end


function Talon:__init()
	if myHero.charName ~= "Talon" then return end
	PrintChat("Welcome to the Noxian Way Of Life")
	self:LoadSpells()
	self:LoadMenu()																							--Init
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Talon:Tick()
	if myHero.dead then return end
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			self:Combo()
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then								--OnTick
			self:Harass()
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			self:Clear()
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			self:LastHit()
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
			self:Flee()	
		end
end

function Talon:Combo()
	if _G.SDK.TargetSelector:GetTarget(1000) == nil then return end
	self:DisableAtk()
	self:EnableAtk()
	local targ = _G.SDK.TargetSelector:GetTarget(550)
	if self.Menu.Combo.UseR:Value() and Ready(_R) and not self:HasBuff(myHero, "TalonRStealth") then
		if EnemiesAround(myHero.pos, 1000) >= self.Menu.Combo.MinR:Value() then
    		Control.CastSpell(HK_R)
    	end
    end
	if self.Menu.Combo.UseQ:Value() and Ready(_Q) and targ ~= nil then
		Control.CastSpell(HK_Q, targ)
	end	
	if self.Menu.Combo.UseW:Value() and Ready(_W) and targ ~= nil then														--Combo
    	local Cpred = targ:GetPrediction(W.speed, 0.25 + Game.Latency()/1000)
    	Control.CastSpell(HK_W, Cpred)
    end
    
end
function Talon:Harass()
	if _G.SDK.TargetSelector:GetTarget(W.range + 100) == nil then return end
	if self.Menu.Harass.UseW:Value() then
		local Wtarg = _G.SDK.TargetSelector:GetTarget(W.range + 100)												--Harass
		local Hpred = Wtarg:GetPrediction(W.speed, 0.25 + Game.Latency()/1000)
		Control.CastSpell(HK_W, Hpred)
	end
end
function Talon:LastHit()
	if Ready(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			if  minion.team == 200 then
				local Qdamage = (({60, 85, 110, 135, 160})[level] + myHero.bonusDamage)
				if myHero.pos:DistanceTo(minion.pos) < 550 and self.Menu.Lasthit.UseQ:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Lasthit.Mana:Value() / 100 ) and minion.isEnemy then
					if Qdamage >= minion.health then
						Control.CastSpell(HK_Q,minion)																																					--Last Hit
					end
				end
				local QMelee = (({60, 85, 110, 135, 160})[level] * 1.5 )
				if myHero.pos:DistanceTo(minion.pos) < 170 and self.Menu.Lasthit.UseQ:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Lasthit.Mana:Value() / 100 ) and minion.isEnemy then
					if QMelee >= minion.health then
						Control.CastSpell(HK_Q,minion)
					end
				end
      		end
		end
	end
end

function Talon:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal 
end

function Talon:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
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

function Talon:Clear()
	if self.Menu.Clear.Usage:Value() == false then return end
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
		if  minion.team == 200 then
			if self:IsValidTarget(minion,550) and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 550 and self.Menu.Clear.UseQ:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 ) and minion.isEnemy then
				Control.CastSpell(HK_Q,minion.pos)
			end
			if self:IsValidTarget(minion,650) and Ready(_W) and myHero.pos:DistanceTo(minion.pos) < 650 and self.Menu.Clear.UseW:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 ) and minion.isEnemy then
				if CountEnemyMinions(650) >= self.Menu.Clear.WHit:Value() then
					Control.CastSpell(HK_W,minion.pos)
				end
			end
		end
		if  minion.team == 300 then
			if self:IsValidTarget(minion,550) and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 550 and self.Menu.Clear.UseQ:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 ) and minion.isEnemy then
				Control.CastSpell(HK_Q,minion.pos)
			end
			if self:IsValidTarget(minion,650) and Ready(_W) and myHero.pos:DistanceTo(minion.pos) < 650 and self.Menu.Clear.UseW:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 ) and minion.isEnemy then
				Control.CastSpell(HK_W,minion.pos)
			end
		end
	end
end

function Talon:Flee()
	if Game.IsChatOpen() == false then
		Control.CastSpell(HK_E, cursorPos)
	end
	
end


local Icons = {
["TalonIcon"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/7/74/Blade%27s_End.png",
["Q"] = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/6/6b/Noxian_Diplomacy.png",
["W"] = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/b/bd/Rake.png",								--Icons
["E"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/d/de/Assassin%27s_Path.png",
["R"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/66/Shadow_Assault.png",
}

function Talon:LoadSpells()

	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }
end

function Talon:LoadMenu()											
	--MainMenu
	self.Menu = MenuElement({type = MENU, id = "Talon", name = "Noxian Way Of Life", leftIcon = Icons["TalonIcon"]})
	--ComboMenu
	self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "[Q] Noxian Diplomacy", value = true, leftIcon = Icons.Q})
	self.Menu.Combo:MenuElement({id = "UseW", name = "[W] Rake", value = true, leftIcon = Icons.W})
	self.Menu.Combo:MenuElement({id = "UseR", name = "[R] Shadow Assault", value = true, leftIcon = Icons.R})
	self.Menu.Combo:MenuElement({id = "MinR", name = "Min Enemies to use R", value = 2, min = 1, max = Game.HeroCount()})
	--HarassMenu
	self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
	self.Menu.Harass:MenuElement({id = "UseW", name = "[W] Rake", value = true, leftIcon = Icons.W})
	self.Menu.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass(%)", value = 65, min = 0, max = 100})
	--LaneClear Menu
	self.Menu:MenuElement({type = MENU, id = "Clear", name = "Lane Clear"})
	self.Menu.Clear:MenuElement({id = "Usage", name = "Spells Usage", key = string.byte("A"),toggle = true})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "[Q] Noxian Diplomacy", value = true, leftIcon = Icons.Q})					--Menus
	self.Menu.Clear:MenuElement({id = "UseW", name = "[W] Rake", value = true, leftIcon = Icons.W})
	self.Menu.Clear:MenuElement({id = "WHit", name = "[W] if x minions", value = 3, min = 1, max = 7})
	self.Menu.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear(%)", value = 50, min = 0, max = 100})
	--LastHit Menu
	self.Menu:MenuElement({type = MENU, id = "Lasthit", name = "Lasthit"})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "[Q] Noxian Diplomacy", value = true, leftIcon = Icons.Q})
	self.Menu.Lasthit:MenuElement({id = "Mana", name = "Min Mana to Lasthit (%)", value = 65, min = 0, max = 100})
	--Drawing Menu
	self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings"})
	self.Menu.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true, leftIcon = Icons.Q})
	self.Menu.Drawing:MenuElement({id = "DrawW", name = "Draw [W] Range", value = true, leftIcon = Icons.W})
end


function Talon:Draw()
	if myHero.dead then return end
	if(self.Menu.Drawing.DrawW:Value())then
		Draw.Circle(myHero, W.range + 100, 3, Draw.Color(255, 225, 255, 10))
	end 																								--OnDraw
	if(self.Menu.Drawing.DrawQ:Value())then
		Draw.Circle(myHero, 550, 3, Draw.Color(225, 225, 0, 10))
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
local atk = 1
function Talon:DisableAtk()
	if (self:HasBuff(myHero, "TalonRStealth")) and atk == 1 then
		_G.SDK.Orbwalker:SetAttack(false)
		atk = 0
	end
end

function Talon:EnableAtk()
	if not (self:HasBuff(myHero, "TalonRStealth")) and atk == 0 then
		_G.SDK.Orbwalker:SetAttack(true)
		atk = 1
	end
end



function OnLoad()
	Talon()
end
