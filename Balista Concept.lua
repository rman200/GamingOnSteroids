if myHero.charName ~= "Kalista" then return end

--Locals
local CastSpell     = Control.CastSpell
local CanUseSpell   = Game.CanUseSpell
local Hero          = Game.Hero
local HeroCount     = Game.HeroCount

-- Spell Data
local rRange    = 1100
local swornAlly = nil

-- Menu
local Menu = MenuElement({type = MENU, id = "BalistaConcept by RMAN", name = "BalistaConcept by RMAN"})
Menu:MenuElement({id = "Blitz", name = "Use R on Blitzcrank Grab", value = true})

-- Common
local function Ready(slot)
    return CanUseSpell(slot) == 0
end

local function GetDistanceSqr(p1, p2) 
    local dx, dz = p1.x - p2.x, p1.z - p2.z 
    return dx * dx + dz * dz
end

-- Ballista
local function GetSwornAlly()   
    for i = 1, HeroCount() do
        local hero = Hero(i)
        if hero and hero.isAlly and GotBuff(hero, "kalistacoopstrikeally") == 1 then            
            return hero.charName == "Blitzcrank" and hero or "Wrong Oath"
        end
    end 
end

local function ExecuteBalista()
    for i = 1, HeroCount() do
        local enemy = Hero(i)
        if enemy and enemy.isEnemy and GotBuff(enemy, "rocketgrab2") == 1 then          
            CastSpell(HK_R)
            return
        end
    end 
end

local function OnTick()
    if not swornAlly then
        swornAlly = GetSwornAlly()
    end
    --
    if swornAlly and Menu.Blitz:Value() and Ready(_R) and GetDistanceSqr(swornAlly.pos, myHero.pos) <= rRange * rRange then
        ExecuteBalista()
    end
end

Callback.Add("Tick", OnTick)