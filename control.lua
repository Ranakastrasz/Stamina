
--[[
Crafting speed of 1 at 100% health, linear loss with health loss.
Lose <Crafting speed> health per second while crafting, same when mining.
At 1% health, snap to zero, and stop losing health.
If moving while crafting, slow regen/add decay.

]]--
local Ranamod = {}
Ranamod.settings = {}

	Ranamod.settings.minHealth    = settings.global["ranamod-stamina-a-min-health"]        .value
	Ranamod.settings.craftDrain   = settings.global["ranamod-stamina-b-crafting-drain"]    .value
	Ranamod.settings.mineDrain    = settings.global["ranamod-stamina-c-mining-drain"]      .value
	Ranamod.settings.walkDrain    = settings.global["ranamod-stamina-d-walk-drain"]        .value
	Ranamod.settings.minCraft     = settings.global["ranamod-stamina-e-min-crafting-speed"].value
	Ranamod.settings.minMine      = settings.global["ranamod-stamina-f-min-mining-speed"]  .value
	Ranamod.settings.minRun       = settings.global["ranamod-stamina-g-min-running-speed"] .value


    
local timer, Char, drain
local ontick = defines.events.on_tick
local stamstat = {}

local cutoff        = Ranamod.settings.minHealth  --*0.01
                                                  --
local craftDrain    = Ranamod.settings.craftDrain --* 0.001
local mineDrain     = Ranamod.settings.mineDrain  --* 0.001
local walkDrain     = Ranamod.settings.walkDrain  --* 0.001
                                                  --
local craftingBase  = Ranamod.settings.minCraft   --* 0.01 
local miningBase    = Ranamod.settings.minMine    --* 0.01 
local speedBase     = Ranamod.settings.minRun     --* 0.01

local ratioBase     = cutoff/(1-cutoff)


function init()
    timer = game.tick % 3
    for name,e in pairs(game.entity_prototypes) do
        if e.type == "player" then
            stamstat[name]= {
                ["critical"]     = e.max_health*cutoff,
                ["full"]           = e.max_health,
                ["basedrain"]   = e.max_health*0.05, -- 1/20, since runs once per 3 ticks, or 20 times a second. 1 * this is 100% health each second
                ["regenoffset"] = e.healing_per_tick * 3,
                --["walkdrain"]   = e.healing_per_tick * (walkRatio * 3),
            }
        end
    end
end

-- -1=logged out, 1 = logged in

-- drain 0.25 hp/tick, down to 1/8th health.
-- drain is proportional to current health.

-- 8/7
-- 1/8 -> 8/7
-- 1/x
-- 1-(x/(x-1))
-- 

function stamina(event)
    if timer < 2 then timer = timer + 1 return end
    timer = 0
    
    for _,p in pairs(game.players) do
        if p.connected then Char = p.character else Char = nil end
        if Char then
            local stat = stamstat[Char.name]
            local ratio = math.max(((ratioBase+1)*(Char.health/stat.full))-ratioBase,0)
            --[[p.print("cutoff        "..cutoff        )
            p.print("ratioBase     "..ratioBase     )
            p.print("craftDrain    "..craftDrain    )
            p.print("mineDrain     "..mineDrain     )
            p.print("walkDrain     "..walkDrain     )
            p.print("craftingBase  "..craftingBase  )
            p.print("miningBase    "..miningBase    )
            p.print("speedBase     "..speedBase     )
            p.print("critical      "..stat.critical  )
            p.print("full          "..stat.full     )
            p.print("basedrain     "..stat.basedrain  )
            p.print("regenoffset   "..stat.regenoffset)]]--
            --p.print(stat.basedrain)
            drain = 0
            if p.crafting_queue_size > 0 then drain = drain + craftDrain end
            if p.mining_state.mining then drain = drain + mineDrain end
            
            if drain > 0 then
                if p.walking_state.walking and Char.health <stat.full then drain = drain + mineDrain end
                --p.print(drain)
                drain = (drain*ratio*0.05) + stat.regenoffset
                --p.print(drain)
                if Char.health < stat.critical then
                    --Char.health = Char.health - stat.regenoffset
                    --if Char.health < drain then
                        --Char.die()
                    --else
                        --Char.health = Char.health - (drain-.001)
                        --Char.damage(.001,p.force)
                    --end
                else
                    Char.health = Char.health - drain
                end
            --elseif p.walking_state.walking and Char.health<stat.full then
                --Char.health = Char.health - stat.walkdrain
            end
            Char.character_crafting_speed_modifier = (ratio*(1-craftingBase)) -(1-craftingBase)
            Char.character_mining_speed_modifier   = (ratio*(1-miningBase)) -(1-miningBase)
            Char.character_running_speed_modifier  = (ratio*(1-speedBase)) -(1-speedBase)
        end
    end

end

script.on_event(ontick,function(event)
    init()
    stamina(event)
    script.on_event(ontick,stamina)
end)
