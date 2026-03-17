local QBCore = exports['qb-core']:GetCoreObject()
local hasSoldToPed = {} -- Cache to prevent selling to same ped multiple times

local lastDebugTime = 0
local function debugLog(msg)
    if not Config.Debug then return end
    local currentTime = GetGameTimer()
    if currentTime - lastDebugTime > 1000 then -- 1 second throttle
        print('^3[rs_drugsell] Debug: ' .. msg .. '^0')
        lastDebugTime = currentTime
    end
end

-- Function to check if ped is blacklisted or dead
local function canSellToPed(entity)
    if IsPedDeadOrDying(entity, true) then return false end
    if IsPedAPlayer(entity) then 
        debugLog("Target is a player (Sales disabled for players)")
        return false 
    end
    if IsPedInAnyVehicle(entity, true) then 
        debugLog("Target is in a vehicle")
        return false 
    end
    
    local model = GetEntityModel(entity)
    for _, blacklist in pairs(Config.BlacklistPeds) do
        if model == GetHashKey(blacklist) then 
            debugLog("Target is blacklisted model")
            return false 
        end
    end
    
    if hasSoldToPed[entity] then 
        debugLog("Already sold to this ped")
        return false 
    end

    return true
end

-- Function to get available drugs from inventory
-- Function to get available drugs from inventory using ox_inventory
local function getAvailableDrugs()
    local drugs = {}
    -- ox_inventory:Search(action, items)
    -- action can be 'count' or 'slots'. We just need to know if we have them.
    -- We'll just iterate our config list and check count.
    
    for k, v in pairs(Config.Drugs) do
        local count = exports.ox_inventory:Search('count', k)
        if count > 0 then
            drugs[#drugs+1] = {
                name = k,
                label = v.label,
                amount = count,
                data = v
            }
        end
    end
    return drugs
end

local stolenDrugs = {} -- Table to track { [entity] = { name = '...', amount = ... } }

-- Helper to handle police alerts
local function AlertPolice()
    if GetResourceState('ps-dispatch') == 'started' then
        exports['ps-dispatch']:DrugSale()
    else
        -- You can add other dispatch systems here
        -- e.g. cd_dispatch, core_dispatch, etc.
        TriggerServerEvent('rs_drugsell:server:policeAlert') -- Fallback generic alert if you implement it, otherwise just silent
    end
end

-- Function to perform sale
local function attemptSell(entity, drug)
    -- Check Police
    QBCore.Functions.TriggerCallback('rs_drugsell:server:checkPolice', function(canSell)
        if not canSell then
            lib.notify({
                title = 'Cannot Sell',
                description = 'Not enough police in town',
                type = 'error'
            })
            return
        end

        -- Process Ped Interaction (Turn, Stop, Freeze)
        -- 1. Get them to face us
        TaskTurnPedToFaceEntity(entity, PlayerPedId(), 1000)
        TaskTurnPedToFaceEntity(PlayerPedId(), entity, 1000)
        Wait(1000)
        
        -- 2. Stop them and freeze
        ClearPedTasksImmediately(entity)
        FreezeEntityPosition(entity, true)

        -- Play anim on Ped (Buyer) - Flag 1 (Upper Body) allows them to stand naturally while frozen
        -- If we use flag 0, they might snap to the anim start frame which can look jerky
        lib.requestAnimDict("mp_common")
        TaskPlayAnim(entity, "mp_common", "givetake2_b", 8.0, -8.0, -1, 1, 0, false, false, false)

        -- Determine Amount The Ped Wants to Buy (Moved before progress)
        local sellAmount = math.random(drug.data.minAmount, drug.data.maxAmount)
        if sellAmount > drug.amount then
            -- If you don't have enough, you can only sell what you have, 
            -- OR fail because you can't meet demand. 
            -- Usually better to just sell what you have.
            sellAmount = drug.amount 
        end
        local pricePerUnit = math.random(drug.data.minPrice, drug.data.maxPrice)

        if lib.progressCircle({
            duration = Config.SellTime,
            label = 'Selling '..sellAmount..'x '..drug.label,
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
            },
            anim = {
                dict = "mp_common",
                clip = "givetake2_a"
            },
            prop = {
                model = 'prop_drug_package_02',
                bone = 28422,
                pos = vec3(0.0, 0.0, 0.0),
                rot = vec3(0.0, 0.0, 0.0)
            },
        }) then
            StopAnimTask(entity, "mp_common", "givetake2_b", 1.0) -- Stop ped interaction anim
            FreezeEntityPosition(entity, false) -- Unfreeze

            -- ROBBERY LOGIC
            if math.random(1, 100) <= Config.RobberyChance then
                lib.notify({
                    title = 'It\'s a setup!',
                    description = 'The buyer is trying to rob you!',
                    type = 'error'
                })
                
                -- Ped takes the drugs
                TriggerServerEvent('rs_drugsell:server:robbed', drug.name, sellAmount)
                
                -- Store drugs on ped for retrieval
                stolenDrugs[entity] = { name = drug.name, amount = sellAmount }

                -- Make Ped Aggressive
                ClearPedTasks(entity)
                
                -- Set Combat Attributes to force fighting
                SetPedCombatAttributes(entity, 46, true) -- BF_AlwaysFight
                SetPedCombatAttributes(entity, 0, false) -- BF_CanUseCover (disable to make them rush)
                SetPedCombatAttributes(entity, 5, true) -- BF_CanFightArmedPeds
                SetPedFleeAttributes(entity, 0, 0) -- Disable fleeing
                
                -- Give weapon
                GiveWeaponToPed(entity, GetHashKey("WEAPON_BAT"), 0, false, true) 
                SetCurrentPedWeapon(entity, GetHashKey("WEAPON_BAT"), true)
                
                -- Force combat target
                TaskCombatPed(entity, PlayerPedId(), 0, 16)
                
                -- Police Alert for fight
                AlertPolice()
            else
                -- Normal Sell Logic
                local success = math.random(1, 100) <= Config.SellChance
                
                if success then
                    -- Process Sale on Server
                    TriggerServerEvent('rs_drugsell:server:sellDrug', drug.name, sellAmount, pricePerUnit)
                    
                    -- Ped reaction: Leave
                    ClearPedTasks(entity)
                    SetPedAsNoLongerNeeded(entity)
                    TaskWanderStandard(entity, 10.0, 10)
                    hasSoldToPed[entity] = true
                else
                    lib.notify({
                        title = 'Sale Failed',
                        description = 'They declined the offer',
                        type = 'error'
                    })
                    
                    -- Ped reaction: Flee or Fight or Call Cops
                    ClearPedTasks(entity)
                    TaskSmartFleePed(entity, PlayerPedId(), 100.0, -1, true, true)
                    hasSoldToPed[entity] = true

                    -- Call Police Chance
                    if math.random(1, 100) <= Config.CallPoliceChance then
                        lib.notify({
                            title = 'Police Alert',
                            description = 'Police have been notified!',
                            type = 'warning'
                        })
                        AlertPolice() 
                    end
                end
            end
        else
            StopAnimTask(entity, "mp_common", "givetake2_b", 1.0)
            FreezeEntityPosition(entity, false) -- Unfreeze
            lib.notify({ description = 'Cancelled', type = 'error' })
        end
    end)
end



-- Check inventory for drugs to determine target option visibility
local function hasDrugs()
    local drugs = getAvailableDrugs()
    return #drugs > 0
end

-- Register ox_target for SELLING
exports.ox_target:addGlobalPed({
    {
        name = 'rs_drugsell:sell',
        icon = 'fa-solid fa-cannabis',
        label = 'Offer Drugs',
        distance = 2.5,
        canInteract = function(entity, distance, coords, name, bone)
            if IsPedDeadOrDying(entity, true) then return false end -- Alive peds only
            if not canSellToPed(entity) then return false end
            if not hasDrugs() then 
                debugLog("You have no drugs in inventory")
                return false 
            end
            return true
        end,
        onSelect = function(data)
           Wait(0) -- Ensure target UI closes before we start logic/animations/menu
           local drugs = getAvailableDrugs()
           if #drugs == 0 then return end
           -- If multiple drugs -> Show Menu
           -- If single drug -> Auto Sell
           if #drugs > 1 then
               local options = {}
               for _, d in pairs(drugs) do
                   options[#options+1] = {
                       title = d.label,
                       description = 'Stock: '..d.amount,
                       icon = 'cannabis',
                       onSelect = function()
                           attemptSell(data.entity, d)
                       end
                   }
               end
               lib.registerContext({
                   id = 'drug_sell_menu',
                   title = 'Select Drug to Sell',
                   options = options
               })
               lib.showContext('drug_sell_menu')
           else
               -- Only 1 drug available, skip menu
               attemptSell(data.entity, drugs[1])
           end
        end
    }
})

-- Register ox_target for LOOTING BACK
exports.ox_target:addGlobalPed({
    {
        name = 'rs_drugsell:loot',
        icon = 'fa-solid fa-hand-holding-medical',
        label = 'Retrieve Stolen Drugs',
        distance = 2.5,
        canInteract = function(entity, distance, coords, name, bone)
            if not IsPedDeadOrDying(entity, true) then return false end -- Must be dead
            if not stolenDrugs[entity] then return false end -- Must be the thief
            return true
        end,
        onSelect = function(data)
            Wait(0)
            local loot = stolenDrugs[data.entity]
            if loot then
                if lib.progressCircle({
                    duration = 2000,
                    label = 'Searching Pockets...',
                    position = 'bottom',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                    anim = { dict = "random@domestic", clip = "pickup_low" },
                }) then
                    TriggerServerEvent('rs_drugsell:server:lootDrugs', loot.name, loot.amount)
                    stolenDrugs[data.entity] = nil -- Clear loot so can't loot twice
                end
            end
        end
    }
})
