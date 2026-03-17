local M = {}

local function isStarted(res)
    return GetResourceState(res) == 'started'
end

local function getJob()
    -- QBX: job in statebag
    local p = PlayerId()
    local ok, ply = pcall(function()
        return Player(p)
    end)
    if ok and ply and ply.state and ply.state.job then
        return ply.state.job
    end

    -- QBCore: via core object (optional)
    if isStarted('qb-core') then
        local ok2, QBCore = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok2 and QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
            local data = QBCore.Functions.GetPlayerData()
            if data and data.job then
                return data.job
            end
        end
    end

    return nil
end

local function isPoliceOnDuty()
    local job = getJob()
    if not job then return false end
    if job.name ~= 'police' then return false end
    return (job.onduty == true or job.onDuty == true)
end

local function createTempBlip(coords, label)
    if type(coords) ~= 'table' or coords.x == nil or coords.y == nil then return end

    local blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, (coords.z or 0.0) + 0.0)
    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 1.2)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label or 'Suspicious Activity')
    EndTextCommandSetBlipName(blip)

    CreateThread(function()
        Wait(60 * 1000)
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end

RegisterNetEvent('rs_drugsell:client:policeAlert', function(payload)
    if not isPoliceOnDuty() then return end

    payload = type(payload) == 'table' and payload or {}
    local coords = payload.coords
    local title = payload.title or '911 Reporting'
    local description = payload.description or 'Suspicious drug activity reported!'
    local code = payload.code
    local street = payload.street

    lib.notify({
        title = code and (code .. ' - ' .. title) or title,
        description = street and (description .. ' (Near ' .. street .. ')') or description,
        type = 'warning',
        icon = 'shield-halved'
    })

    if coords then
        createTempBlip(coords, title)
    end
end)

-- Override these functions to integrate any dispatch you want.
-- Keep the function signatures the same so `client/main.lua` doesn't need changes.

function M.drugSale()
    -- Default: ps-dispatch support
    if isStarted('ps-dispatch') then
        exports['ps-dispatch']:DrugSale()
        return true
    end

    -- Add your custom dispatch here.
    -- Example patterns you might use (uncomment + adapt):
    -- if isStarted('cd_dispatch') then
    --     exports['cd_dispatch']:AddNotification({ ... })
    --     return true
    -- end
    --
    -- if isStarted('qs-dispatch') then
    --     exports['qs-dispatch']:DrugSale()
    --     return true
    -- end

    -- Built-in default dispatch (no external dependency)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = streetHash and GetStreetNameFromHashKey(streetHash) or 'Unknown'

    TriggerServerEvent('rs_drugsell:server:policeAlert', {
        coords = { x = coords.x, y = coords.y, z = coords.z },
        street = street,
        code = '10-66',
        title = 'Suspicious Activity',
        description = 'Possible drug dealing reported'
    })
    return false
end

function M.robberyOrFight()
    -- Use same behaviour for now; customize if your dispatch has different calls.
    return M.drugSale()
end

return M

