local menu = 1
class "Teemo"

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

function Teemo:__init()
	if menu ~= 1 then return end
	menu = 2
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	PrintChat("One Two Three Fuck")
end

function Teemo:LoadSpells()
	Q = {range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width}
	W = {range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width}
	--E = {range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width}
	R = {range = 400, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width}
	R.Range = 400
	LastR = 1000
end
local Icons = {
["TeemoIcon"] = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/e/eb/Element_of_Surprise.png",
["Q"] = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/c/c7/Blinding_Dart.png",
["W"] = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/f/fa/Move_Quick.png",                --Icons
--["E"] = "",
["R"] = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/2/21/Noxious_Trap.png",
}

function Teemo:LoadMenu()

	--Menu
	self.Menu = MenuElement({type = MENU, id = "Menu", name = "Teemo", leftIcon = Icons["TeemoIcon"]})	
	--Combo
	self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "Use [Q] Blinding Dart", value = true, leftIcon = Icons.Q})
	self.Menu.Combo:MenuElement({id = "UseW", name = "Use [W] Move Quick", value = true, leftIcon = Icons.W})
	self.Menu.Combo:MenuElement({id = "UseR", name = "Use [R] Noxious Trap", value = true, leftIcon = Icons.R})
	--LaneClear
	self.Menu:MenuElement({type = MENU, id = "LaneClear", name = "Lane Clear"})
	self.Menu.LaneClear:MenuElement({id = "UseR", name = "Use [R] Noxious Trap", value = true, leftIcon = Icons.R})
	self.Menu.LaneClear:MenuElement({id = "RMin", name = "Use [R] when X minions", value = 3,min = 0, max = 7, step = 1})
	self.Menu.LaneClear:MenuElement({id = "Ammo", name = "Min. [R] charges to keep", value = 2, min = 0, max = 3, step = 1})
	--HarassMenu
  	self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  	self.Menu.Harass:MenuElement({id = "AutoQ", name = "Auto Q Harass", key = string.byte("H"),toggle = true})
  	self.Menu.Harass:MenuElement({id = "UseQ", name = "[Q] Blinding Dart", value = true, leftIcon = Icons.Q})
	
	--Drawing
	self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings"})
	self.Menu.Drawing:MenuElement({id = "Q", name = "Draw [Q] Range", value = true, leftIcon = Icons.Q})
	self.Menu.Drawing:MenuElement({id = "R", name = "Draw [R] Range", value = true, leftIcon = Icons.R})

end

function Teemo:Tick()
	if myHero.dead then return end
	if self.Menu.Harass.AutoQ:Value() then
      self:Harass()
    end
	if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
      self:Combo()
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then                --OnTick
      self:Harass()
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
      self:Clear()
    --elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
    --  self:LastHit()
    elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
      self:Flee() 
    end
	Rlvl = myHero:GetSpellData(_R).level
	if Rlvl ~= nil and Rlvl ~= 0 then
		R.Range = ({400, 650, 900})[Rlvl]
	end
end

local function IsValidCreep(unit, range)
  return unit and unit.isEnemy and unit.dead == false and GetDistanceSqr(myHero.pos, unit.pos) <= (range + myHero.boundingRadius + unit.boundingRadius)^2 and unit.isTargetable and unit.isTargetableToTeam and unit.isImmortal == false and unit.visible
end

local function GetMinionCount(range, pos)
    local pos = pos.pos
      local count = 0
      for i = 1,Game.MinionCount() do
          local hero = Game.Minion(i)
          local Range = range * range
          if hero.isEnemy and hero.dead == false and GetDistanceSqr(pos, hero.pos) < Range then
              count = count + 1
          end
      end
      return count
end
function Teemo:ClearLogic()
  local RPos = nil 
  local Most = 0 
    for i = 1, Game.MinionCount() do
    local Minion = Game.Minion(i)
      if IsValidCreep(Minion, 350) then
        local Count = GetMinionCount(250, Minion)
        --PrintChat(Count)
        if Count > Most then
          Most = Count
          RPos = Minion.pos
        end
      end
    end
    return RPos, Most
  end

local function Ready(spell)
    return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end 

function Teemo:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal 
end

function Teemo:Draw()
	if myHero.dead then return end
	if self.Menu.Drawing.Q:Value() then Draw.Circle(myHero.pos, Q.range, 3, Draw.Color(255, 0, 0, 220)) end			
	if self.Menu.Drawing.R:Value() then Draw.Circle(myHero.pos, R.Range, 3, Draw.Color(220,255,0,0)) end
	local textPos = myHero.pos:To2D()
	if self.Menu.Harass.AutoQ:Value() then
		Draw.Text("Auto Harass: On", 20, textPos.x - 40, textPos.y + 80, Draw.Color(255, 000, 255, 000)) 
	else
		Draw.Text("Auto Harass: Off", 20, textPos.x - 40, textPos.y + 80, Draw.Color(255, 255, 000, 000)) 
	end
end

function Teemo:Combo()
	
	if myHero.isChanneling then return end
	local target = _G.SDK.TargetSelector:GetTarget(650, _G.SDK.DAMAGE_TYPE_MAGICAL)
 	if target == nil then return end
		
	if self:IsValidTarget(target,Q.range) and self.Menu.Combo.UseQ:Value() and Ready(_Q) then
		Control.CastSpell(HK_Q,target)
	end 
			
	if self:IsValidTarget(target,700) and self.Menu.Combo.UseW:Value() and Ready(_W) then
		Control.CastSpell(HK_W)
	end
	
	if self:IsValidTarget(target,R.Range) and self.Menu.Combo.UseR:Value() and Ready(_R) and LastR + 3000 < GetTickCount() then
		local Cpred = target:GetPrediction(R.speed, 0.5 + Game.Latency()/1000)
		Control.CastSpell(HK_R,Cpred)		
		LastR = GetTickCount()
	end
end

function Teemo:Harass()
	local target = _G.SDK.TargetSelector:GetTarget(680, _G.SDK.DAMAGE_TYPE_MAGICAL)
 	if target == nil then return end
	if self:IsValidTarget(target,Q.range) and self.Menu.Combo.UseQ:Value() and Ready(_Q) then
		Control.CastSpell(HK_Q,target)
	end 
end

function Teemo:Clear()
	if myHero.isChanneling then return end
	if _G.SDK.ObjectManager:GetEnemyMinions(R.Range) == nil then return end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if self:IsValidTarget(minion,550) and myHero:GetSpellData(_R).ammo > self.Menu.LaneClear.Ammo:Value() and myHero.pos:DistanceTo(minion.pos) < R.Range and self.Menu.LaneClear.UseR:Value() and minion.isEnemy and LastR + 3000 < GetTickCount()then
      		local RPos, Count = self:ClearLogic()
      		if RPos == nil then return end
      		if Count >= self.Menu.LaneClear.RMin:Value() then
        		Control.CastSpell(HK_R, RPos)
        		LastR = GetTickCount()
      		end
    	end  
	end
end	

function Teemo:Flee()
	local target = _G.SDK.TargetSelector:GetTarget(1000)
 	if target == nil or not Ready(_W) then return end
 	Control.CastSpell(HK_W)
 end


function OnLoad()
	if myHero.charName ~= "Teemo" then return end
	Teemo()
end
