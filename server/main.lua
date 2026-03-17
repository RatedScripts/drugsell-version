local QBCore = exports['qb-core']:GetCoreObject()

-- Callback to check if enough police are online
QBCore.Functions.CreateCallback('rs_drugsell:server:checkPolice', function(source, cb)
    local policeCount = 0
    for _, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player and Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
            policeCount = policeCount + 1
        end
    end
    cb(policeCount >= Config.MinimumPolice)
end)

-- Event to process drug sale
RegisterNetEvent('rs_drugsell:server:sellDrug', function(drugName, amount, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Verify amount
    local count = exports.ox_inventory:Search(src, 'count', drugName)
    local drugData = Config.Drugs[drugName]
    
    if count < amount then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You don\'t have enough '.. (drugData and drugData.label or drugName)})
        return
    end

    -- Remove Drug
    if exports.ox_inventory:RemoveItem(src, drugName, amount) then
        -- Add Money
        local totalPrice = price * amount
        if Config.BlackMoney then
            if Config.BlackMoneyType == 'count' then
                exports.ox_inventory:AddItem(src, Config.BlackMoneyItem, totalPrice)
            else
                local info = { worth = totalPrice }
                exports.ox_inventory:AddItem(src, Config.BlackMoneyItem, 1, info)
            end
        else
            Player.Functions.AddMoney('cash', totalPrice)
        end
        
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success', 
            description = 'You sold '..amount..'x '..(drugData and drugData.label or drugName)..' for $'..totalPrice
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Could not sell items'})
    end
end)

-- Event when player gets robbed (just remove drugs)
RegisterNetEvent('rs_drugsell:server:robbed', function(drugName, amount)
    local src = source
    if exports.ox_inventory:RemoveItem(src, drugName, amount) then
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'The ped took your '..amount..'x '..drugName})
    end
end)

-- Event to loot drugs back
RegisterNetEvent('rs_drugsell:server:lootDrugs', function(drugName, amount)
    local src = source
    if exports.ox_inventory:AddItem(src, drugName, amount) then
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'You retrieved '..amount..'x '..drugName})
    end
end)

-- Police notify logic moved to client side for ps-dispatch
-- Fallback police alert if ps-dispatch is missing
RegisterNetEvent('rs_drugsell:server:policeAlert', function()
    local src = source
    -- Notify police
    for _, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player and Player.PlayerData.job.name == 'police' and Player.PlayerData.job.onduty then
            TriggerClientEvent('ox_lib:notify', v, {
                title = '911 Reporting',
                description = 'Suspicious drug activity reported!',
                type = 'warning',
                icon = 'shield-halved'
            })
        end
    end
end)
