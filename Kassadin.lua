class "Kassadin"

require 'DamageLib'

local function Ready(spell)
    return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end 

function CanMove()
  if _G.SDK then
    return _G.SDK.Orbwalker:CanMove()  
  end
end
function CanAttack()
  if _G.SDK then
    _G.SDK.Orbwalker:CanAttack()
  end
end 
function GetDistanceSqr(p1, p2)
  if not p1 then return math.huge end
  p2 = p2 or myHero
  local dx = p1.x - p2.x
  local dz = (p1.z or p1.y) - (p2.z or p2.y)
  return dx*dx + dz*dz
end

function GetDistance(p1, p2)
  p2 = p2 or myHero
  return math.sqrt(GetDistanceSqr(p1, p2))
end

local function IsValidCreep(unit, range)
  return unit and unit.team ~= TEAM_ALLY and unit.dead == false and GetDistanceSqr(myHero.pos, unit.pos) <= (range + myHero.boundingRadius + unit.boundingRadius)^2 and unit.isTargetable and unit.isTargetableToTeam and unit.isImmortal == false and unit.visible
end

local function GetMinionCount(range, pos)
    local pos = pos.pos
      local count = 0
      for i = 1,Game.MinionCount() do
          local hero = Game.Minion(i)
          local Range = range * range
          if hero.team ~= TEAM_ALLY and hero.dead == false and GetDistanceSqr(pos, hero.pos) < Range then
              count = count + 1
          end
      end
      return count
  end


--[[
function DrawDmgOnHpBar(hero)
  if not Config.Draws.DMG then return end
  if hero and hero.valid and not hero.dead and hero.visible and hero.bTargetable then
    local kdt = killDrawTable[hero.networkID]
    for _=1, #kdt do
      local vars = kdt[_]
       if vars and vars[1] then
         DrawRectangle(vars[1], vars[2], vars[3], vars[4], vars[5])
         Draw.Text(vars[6], vars[7], vars[8], vars[9], vars[10])
        end
     end
  end
end
function CalculateDamage()
  if not Config.Draws.DMG then return end
  for i, enemy in pairs(GetEnemyHeroes()) do
    if enemy and not enemy.dead and enemy.visible and enemy.bTargetable then
      local damageQ = myHero:CanUseSpell(_Q) ~= READY and 0 or getdmg("Q", myHero, enemy) or 0
      local damageW = myHero:CanUseSpell(_W) ~= READY and 0 or getdmg("W", myHero, enemy) or 0
      local damageE = myHero:CanUseSpell(_E) ~= READY and 0 or getdmg("E", myHero, enemy) or 0
      local damageR = myHero:CanUseSpell(_R) ~= READY and 0 or getdmg("R", myHero, enemy) or 0
      killTable[enemy.networkID] = {damageQ, damageW, damageE, damageR}
    end
  end
end
function CalculateDamageOffsets()
  if not Config.Draws.DMG then return end
  for i, enemy in pairs(GetEnemyHeroes()) do
    if enemy and enemy.valid then
      local nextOffset = 0
      pos = {x = enemy.hpBar.x, y = enemy.hpBar.y}
      local totalDmg = 0
      killDrawTable[enemy.networkID] = {}
      for _, dmg in pairs(killTable[enemy.networkID]) do
        if dmg > 0 then
          local perc1 = dmg / enemy.maxHealth
          local perc2 = totalDmg / enemy.maxHealth
          totalDmg = totalDmg + dmg
          local offs = 1-(enemy.maxHealth - enemy.health) / enemy.maxHealth
          killDrawTable[enemy.networkID][_] = {
          offs*105+pos.x-perc2*105, pos.y, -perc1*105, 9, colors[_],
          str[_-1], 15, offs*105+pos.x-perc1*105-perc2*105, pos.y-20, colors[_]
          }
        else
          killDrawTable[enemy.networkID][_] = {}
        end
      end
    end
  end
end
]]
function Kassadin:__init()
  self.passiveTracker = 0
  self.stacks = 0
  PrintChat("Time to Silence Your Mother")
  self:LoadSpells()
  self:LoadMenu()                                             --Init
  Callback.Add("Tick", function() self:Tick() end)
  Callback.Add("Draw", function() self:Draw() end)  
  --[[killTable = {}
  for i, enemy in pairs(GetEnemyHeroes()) do
    killTable[enemy.networkID] = {0, 0, 0, 0, 0, 0}
  end
  killDrawTable = {}
  for i, enemy in pairs(GetEnemyHeroes()) do
    killDrawTable[enemy.networkID] = {}
  end
  ]]
end

local Icons = {
["KassadinIcon"] = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/5/57/KassadinSquare.png",
["Q"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/9/97/Null_Sphere.png",
["W"] = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/d/df/Nether_Blade.png",                --Icons
["E"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/d/d7/Force_Pulse.png",
["R"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/4/4a/Riftwalk.png",
}

function Kassadin:LoadSpells()

  Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
  W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
  E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
  R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }
end

function Kassadin:LoadMenu()                     
  --MainMenu
  self.Menu = MenuElement({type = MENU, id = "Kassadin", name = "Silence Your Mother", leftIcon = Icons["KassadinIcon"]})
  --ComboMenu
  self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  self.Menu.Combo:MenuElement({id = "UseQ", name = "[Q] Null Sphere", value = true, leftIcon = Icons.Q})
  self.Menu.Combo:MenuElement({id = "UseW", name = "[W] Nether Blade", value = true, leftIcon = Icons.W})
  self.Menu.Combo:MenuElement({id = "UseE", name = "[E] Force Pulse", value = true, leftIcon = Icons.E})
  self.Menu.Combo:MenuElement({id = "UseR", name = "[R] Riftwalk", value = true, leftIcon = Icons.R})
  self.Menu.Combo:MenuElement({id = "MinR", name = "Min life % to use R", value = 60, min = 1, max = 100})
  --HarassMenu
  self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  self.Menu.Harass:MenuElement({id = "AutoQ", name = "Auto Q Harass", key = string.byte("H"),toggle = true})
  self.Menu.Harass:MenuElement({id = "UseQ", name = "[Q] Null Sphere", value = true, leftIcon = Icons.Q})
  self.Menu.Harass:MenuElement({id = "UseW", name = "[W] Nether Blade", value = true, leftIcon = Icons.W})
  self.Menu.Harass:MenuElement({id = "UseE", name = "[E] Force Pulse", value = true, leftIcon = Icons.E})
  self.Menu.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass(%)", value = 65, min = 0, max = 100})
  --LaneClear Menu
  self.Menu:MenuElement({type = MENU, id = "Clear", name = "Lane Clear"})
  self.Menu.Clear:MenuElement({id = "UseQ", name = "[Q] Null Sphere", value = true, leftIcon = Icons.Q})         --Menus
  self.Menu.Clear:MenuElement({id = "UseE", name = "[E] Force Pulse", value = true, leftIcon = Icons.E})
  self.Menu.Clear:MenuElement({id = "EHit", name = "[E] if x minions", value = 3, min = 1, max = 7})
  self.Menu.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear(%)", value = 50, min = 0, max = 100})
  --LastHit Menu
  self.Menu:MenuElement({type = MENU, id = "Lasthit", name = "Lasthit"})
  self.Menu.Lasthit:MenuElement({id = "AutoQ", name = "Auto Q Lasthit", key = string.byte("K"),toggle = true})
  self.Menu.Lasthit:MenuElement({id = "UseQ", name = "[Q] Null Sphere", value = true, leftIcon = Icons.Q})
  self.Menu.Lasthit:MenuElement({id = "Mana", name = "Min Mana to Lasthit (%)", value = 65, min = 0, max = 100})
  --Drawing Menu
  self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings"})
  self.Menu.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true, leftIcon = Icons.Q})
  self.Menu.Drawing:MenuElement({id = "DrawR", name = "Draw [R] Range", value = true, leftIcon = Icons.R})
  --Killsteal Menu
  self.Menu:MenuElement({type = MENU, id = "KS", name = "Kill Steal"})
  self.Menu.KS:MenuElement({id = "UseQ", name = "[Q] Null Sphere", value = true, leftIcon = Icons.Q})
  self.Menu.KS:MenuElement({id = "UseW", name = "[W] Nether Blade", value = true, leftIcon = Icons.W})
  self.Menu.KS:MenuElement({id = "UseE", name = "[E] Force Pulse", value = true, leftIcon = Icons.E})
  self.Menu.KS:MenuElement({id = "UseR", name = "[R] Riftwalk", value = true, leftIcon = Icons.R})
end



function Kassadin:Draw()
  if myHero.dead then return end
  if(self.Menu.Drawing.DrawR:Value())then
    Draw.Circle(myHero, R.range, 3, Draw.Color(255, 225, 255, 10))
  end                                                 --OnDraw
  if(self.Menu.Drawing.DrawQ:Value())then
    Draw.Circle(myHero, Q.range, 3, Draw.Color(225, 225, 0, 10))
  end
  --[[
  local pos = Vector:To2D(myHero.x, myHero.y, myHero.z)
  local str = self.passiveTracker < 6 and "E: "..self.passiveTracker or "E READY!"
  for i = -1, 1 do
    for j = -1, 1 do
      Draw.Text(str, 25, pos.x - 15 + i - GetTextArea(str, 25).x/2, pos.y + 35 + j, ARGB(255, 0, 0, 0)) 
    end
  end
  Draw.Text(str, 25, pos.x - 15 - GetTextArea(str, 25).x/2, pos.y + 35, self.passiveTracker < 6 and ARGB(255, 255, 0, 0) or ARGB(255, 55, 255, 55))
  local str = "R: "..(50*2^self.stacks)
  for i = -1, 1 do
    for j = -1, 1 do
      Draw.Text(str, 25, pos.x - 15 + i - GetTextArea(str, 25).x/2, pos.y + 55 + j, ARGB(255, 0, 0, 0)) 
    end
  end
  Draw.Text(str, 25, pos.x - 15 - GetTextArea(str, 25).x/2, pos.y + 55, ARGB(255, 55, 55, 255))
  ]] 
end

function Kassadin:ValidTarget(unit,range) 
  return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal 
end

function Kassadin:Tick()
  if myHero.dead then return end
    self:OnBuff(myHero)
    self:Killsteal()
    if self.Menu.Lasthit.AutoQ:Value() then
      self:LastHit()
    end
    if self.Menu.Harass.AutoQ:Value() then
      self:Harass()
    end
    if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
      self:Combo()
      self:CastW()
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then                --OnTick
      self:Harass()
      self:CastW()
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
      self:Clear()
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
      self:LastHit()
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
      self:Flee() 
    end
end
function Kassadin:CastW()
  if (myHero.attackData.state == STATE_WINDDOWN and self.Menu.Combo.UseW) or (myHero.attackData.state == STATE_WINDDOWN and self.Menu.Harass.UseW) then
    Control.CastSpell(HK_W)
    --Control.Attack(_G.SDK.Orbwalker:GetTarget())
  end
end
function Kassadin:OnBuff(unit)

  if unit.buffCount == nil then self.passiveTracker = 0 self.stacks = 0 return end
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    
    if buff.name == "forcepulsecancast" then
      self.passiveTracker = buff.count
    --if buff.name == "forcepulsecounter" then
     --self.passiveTracker = buff.count
    end
    if buff.name == "RiftWalk" then
      self.stacks = buff.count      
    end     
  end
end

function Kassadin:ClearLogic()
  local EPos = nil 
  local Most = 0 
    for i = 1, Game.MinionCount() do
    local Minion = Game.Minion(i)
      if IsValidCreep(Minion, 350) then
        local Count = GetMinionCount(400, Minion)
        --PrintChat(Count)
        if Count > Most then
          Most = Count
          EPos = Minion.pos
        end
      end
    end
    return EPos, Most
  end 

function Kassadin:Flee()
    --R through walls, maybe?
end

function Kassadin:Combo()
  local target = _G.SDK.TargetSelector:GetTarget(650, _G.SDK.DAMAGE_TYPE_MAGICAL)
  if target == nil then return end
  if self.Menu.Combo.UseE and myHero.pos:DistanceTo(target.pos) < 600 and self.passiveTracker >= 1 then
    local Cpred = target:GetPrediction(E.speed, 0.25 + Game.Latency()/1000)
    Control.CastSpell(HK_E, Cpred)
  end
  if self.Menu.Combo.UseR and Ready(_R) and 100*myHero.health/myHero.maxHealth >= self.Menu.Combo.MinR:Value() then
    Control.CastSpell(HK_R, target)
  elseif self.Menu.Combo.UseQ and Ready(_Q) and myHero.pos:DistanceTo(target.pos) > myHero.range then
    Control.CastSpell(HK_Q, target)
  end
  --[[
  if self.Menu.KS.UseR then
    for _, unit in pairs(_G.SDK.ObjectManager:GetEnemyHeroes(1050)) do
        local dmg = (Ready(_Q) and getdmg("Q", unit, myHero, 2) or 0) + (Ready(_W) and getdmg("W", unit, myHero, 2) or 0) + (Ready(_E) and getdmg("E", unit, myHero, 2) or 0)
        if unit.health < dmg then
          _G.SDK.Orbwalker.ForceTarget = unit
          Control.Control.CastSpell(HK_R, unit.x, unit.z)
        end
    end
  end]]
end
function Kassadin:Harass()
  local targ = _G.SDK.TargetSelector:GetTarget(650, _G.SDK.DAMAGE_TYPE_MAGICAL)
  if targ == nil then return end
  if self.Menu.Harass.UseE and self.passiveTracker >= 1 and (myHero.mana/myHero.maxMana >= self.Menu.Harass.Mana:Value() / 100 ) and myHero.pos:DistanceTo(targ.pos) < 550 then
    local Hpred = targ:GetPrediction(E.speed, 0.25 + Game.Latency()/1000)
    Control.CastSpell(HK_E, Hpred)
  end
  if self.Menu.Harass.UseQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= self.Menu.Harass.Mana:Value() / 100 ) and myHero.pos:DistanceTo(targ.pos) < 650 then
    Control.CastSpell(HK_Q, targ)
  end
end

function Kassadin:Clear()
  for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)
    local Qdamage = (({65, 95, 125, 155, 185})[level] + 0.7 * myHero.ap)
    if Qdamage >= minion.health then
      if self:ValidTarget(minion,550) and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 550 and self.Menu.Clear.UseQ:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 ) and minion.isEnemy and myHero.pos:DistanceTo(minion.pos) > myHero.range then
        Control.CastSpell(HK_Q,minion)
      end
    end
    if self:ValidTarget(minion,550) and self.passiveTracker >= 1 and myHero.pos:DistanceTo(minion.pos) < 550 and self.Menu.Clear.UseE:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 ) and minion.isEnemy and myHero.pos:DistanceTo(minion.pos) > myHero.range then
      local EPos, Count = self:ClearLogic()
      if EPos == nil then return end
      if Count >= self.Menu.Clear.EHit:Value() then
        Control.CastSpell(HK_E, EPos)
      end
    end  
  end
end

function Kassadin:LastHit()
  if Ready(_Q) then
    local level = myHero:GetSpellData(_Q).level 
    for i = 1, Game.MinionCount() do
      local minion = Game.Minion(i)
      local Qdamage = (({65, 95, 125, 155, 185})[level] + 0.7 * myHero.ap)
      if Qdamage >= minion.health then
        if myHero.pos:DistanceTo(minion.pos) < 600 and self.Menu.Lasthit.UseQ:Value() and minion.isEnemy and myHero.pos:DistanceTo(minion.pos) > myHero.range then
          Control.CastSpell(HK_Q,minion)
        end
      end         
    end
  end
end

function Kassadin:Killsteal()
  for _, enemy in pairs(_G.SDK.ObjectManager:GetEnemyHeroes(1000)) do
    if enemy ~= nil then
      local hp = enemy.health
      local dist = myHero.pos:DistanceTo(enemy.pos)
      if (Ready(_Q) and self.Menu.KS.UseQ:Value()) then qdmg = getdmg("Q", enemy) end
      --if (Ready(_W) and self.Menu.KS.UseW:Value()) then wdmg = getdmg("W", enemy) end
      if (Ready(_E) and self.Menu.KS.UseE:Value()) then edmg = getdmg("E", enemy) end
      if (Ready(_R) and self.Menu.KS.UseR:Value()) then rdmg = getdmg("R", enemy) end
      --PrintChat(qdmg)
      if dist < Q.range and qdmg > hp then
        Control.CastSpell(HK_Q, enemy)
        return
      end
      if dist < E.range and edmg > hp then
        Control.CastSpell(HK_E, enemy.pos)
        return
      end
      if dist < R.range and rdmg > hp then
        Control.CastSpell(HK_R, enemy.pos)
        return
      end
      if dist < E.range and qdmg+edmg > hp then
        Control.CastSpell(HK_E, enemy.pos)
        Control.CastSpell(HK_Q, enemy)
        return
      end
      if dist < R.range and qdmg+edmg+rdmg > hp then
        Control.CastSpell(HK_R, enemy.pos)
        Control.CastSpell(HK_E, enemy.pos)
        Control.CastSpell(HK_Q, enemy)
        return
      end
    end
  end
end

function OnLoad()
  Kassadin()
end
