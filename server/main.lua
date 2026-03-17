local Framework = lib.require('shared.framework')

lib.callback.register('rs_drugsell:checkPolice', function(source)
    local policeCount = 0
    for _, v in pairs(Framework.getPlayers()) do
        local job = Framework.getJob(v)
        if job and job.name == "police" and (job.onduty == true or job.onDuty == true) then
            policeCount = policeCount + 1
        end
    end

    return policeCount >= Config.MinimumPolice
end)

-- Event to process drug sale
RegisterNetEvent('rs_drugsell:server:sellDrug', function(drugName, amount, price)
    local src = source
    -- Framework player object is only needed for qb-core money;
    -- qbx uses exports for money.

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
            Framework.addMoney(src, 'cash', totalPrice, 'rs_drugsell:sale')
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
RegisterNetEvent('rs_drugsell:server:policeAlert', function(payload)
    -- Broadcast to all clients; clients decide if they're on-duty police.
    TriggerClientEvent('rs_drugsell:client:policeAlert', -1, payload)
end)

-- Version check moved to bottom for clarity
local function readBoolMeta(key, default)
    local val = GetResourceMetadata(GetCurrentResourceName(), key, 0)
    if not val then return default end
    val = tostring(val):lower()
    return (val == 'true' or val == '1' or val == 'yes' or val == 'on')
end

local SUPPRESS_UPDATES = readBoolMeta('suppress_updates', false)

if not SUPPRESS_UPDATES then
    local function parseVersion(version)
        local parts = {}
        for num in version:gmatch("%d+") do
            table.insert(parts, tonumber(num))
        end
        return parts
    end

    local function compareVersions(current, newest)
        local currentParts = parseVersion(current or "0.0.0")
        local newestParts = parseVersion(newest or "0.0.0")
        for i = 1, math.max(#currentParts, #newestParts) do
            local c = currentParts[i] or 0
            local n = newestParts[i] or 0
            if c < n then return -1
            elseif c > n then return 1 end
        end
        return 0 -- equal
    end

    function CheckDrugSellVersion()
        if IsDuplicityVersion() then
            CreateThread(function()
                Wait(4000)
                local resName = GetCurrentResourceName()
                local currentVersionRaw = GetResourceMetadata(resName, 'version', 0) or "0.0.0"
                local versionUrl = GetResourceMetadata(resName, 'version_url', 0)

                if not versionUrl or versionUrl == '' then
                    print("^3[rs_drugsell]^0 No 'version_url' metadata set; skipping GitHub version check.")
                    return
                end

                PerformHttpRequest(versionUrl, function(err, body, headers)
                    if not body or err ~= 200 then
                        print("^1Unable to run version check for ^7'^3rs_drugsell^7' (^3"..currentVersionRaw.."^7)")
                        return
                    end

                    local lines = {}
                    for line in body:gmatch("[^\r\n]+") do
                        table.insert(lines, line)
                    end

                    local newestVersionRaw = lines[1] or "0.0.0"
                    local changelog = {}
                    for i = 2, #lines do
                        table.insert(changelog, lines[i])
                    end

                    local compareResult = compareVersions(currentVersionRaw, newestVersionRaw)

                    if compareResult == 0 then
                        print("^7'^3rs_drugsell^7' - ^2You are running the latest version^7. ^7(^3"..currentVersionRaw.."^7)")
                    elseif compareResult < 0 then
                        print("^1----------------------------------------------------------------------^7")
                        print("^7'^3rs_drugsell^7' - ^1You are running an outdated version^7! ^7(^3"..currentVersionRaw.."^7 → ^3"..newestVersionRaw.."^7)")
                        for _, line in ipairs(changelog) do
                            print((line:find("http") and "^7" or "^5")..line)
                        end
                        print("^1----------------------------------------------------------------------^7")
                        SetTimeout(3600000, function()
                            CheckDrugSellVersion()
                        end)
                    else
                        print("^7'^3rs_drugsell^7' - ^5You are running a newer version ^7(^3"..currentVersionRaw.."^7 ← ^3"..newestVersionRaw.."^7) (^1Expect Errors^7)")
                    end
                end)
            end)
        end
    end

    CheckDrugSellVersion()
end
