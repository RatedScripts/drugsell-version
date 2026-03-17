local M = {}

local function isStarted(res)
    return GetResourceState(res) == 'started'
end

M.name = (function()
    if isStarted('qbx_core') then return 'qbx' end
    if isStarted('qb-core') then return 'qbcore' end
    return 'standalone'
end)()

if M.name == 'qbcore' then
    M.core = exports['qb-core']:GetCoreObject()
end

function M.getPlayers()
    if M.name == 'qbcore' then
        return M.core.Functions.GetPlayers()
    end

    if M.name == 'qbx' then
        local out = {}
        local qbPlayers = exports.qbx_core:GetQBPlayers() or {}
        for src in pairs(qbPlayers) do
            out[#out + 1] = src
        end
        return out
    end

    -- fallback (won't include offline players)
    return GetPlayers()
end

function M.getJob(src)
    if M.name == 'qbcore' then
        local Player = M.core.Functions.GetPlayer(src)
        return Player and Player.PlayerData and Player.PlayerData.job or nil
    end

    if M.name == 'qbx' then
        local ok, ply = pcall(function()
            return Player(src)
        end)
        if ok and ply and ply.state and ply.state.job then
            return ply.state.job
        end

        local PlayerObj = exports.qbx_core:GetPlayer(src)
        if PlayerObj and PlayerObj.PlayerData and PlayerObj.PlayerData.job then
            return PlayerObj.PlayerData.job
        end
    end

    return nil
end

function M.addMoney(src, moneyType, amount, reason)
    if M.name == 'qbcore' then
        local Player = M.core.Functions.GetPlayer(src)
        if not Player then return false end
        Player.Functions.AddMoney(moneyType, amount, reason)
        return true
    end

    if M.name == 'qbx' then
        return exports.qbx_core:AddMoney(src, moneyType, amount, reason)
    end

    return false
end

return M

