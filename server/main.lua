-- ─────────────────────────────────────────────────────────────────────────────
--  NDM Body Camera — Server-side main
-- ─────────────────────────────────────────────────────────────────────────────

local Core = nil  -- framework core object (set during initialisation)

-- ── Active session tracking ───────────────────────────────────────────────────
-- Keyed by source (player server id).
-- { serial, logId, citizenId }
local Sessions = {}

-- ── Framework initialisation ──────────────────────────────────────────────────
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if Config.Framework == 'gbcore' then
        Core = exports['gbcore']:GetCoreObject()
    elseif Config.Framework == 'qb-core' then
        Core = exports['qb-core']:GetCoreObject()
    elseif Config.Framework == 'esx' then
        Core = exports['es_extended']:getSharedObject()
    end

    -- Register the usable item with the framework.
    RegisterUsableItem()

    print('[NDM_BodyCamera] Resource started — framework: ' .. Config.Framework)
end)

-- ── Usable item registration ──────────────────────────────────────────────────
function RegisterUsableItem()
    if Config.Framework == 'gbcore' then
        -- gbcore pattern: exports['gbcore']:CreateUseableItem(item, cb)
        -- Adjust to match your specific gbcore version's API if needed.
        if exports['gbcore'] and exports['gbcore'].CreateUseableItem then
            exports['gbcore']:CreateUseableItem(Config.ItemName, function(source)
                TriggerClientEvent('NDM_BodyCamera:client:ItemUsed', source)
            end)
        elseif Core and Core.Functions and Core.Functions.CreateUseableItem then
            Core.Functions.CreateUseableItem(Config.ItemName, function(source)
                TriggerClientEvent('NDM_BodyCamera:client:ItemUsed', source)
            end)
        end

    elseif Config.Framework == 'qb-core' then
        Core.Functions.CreateUseableItem(Config.ItemName, function(source)
            TriggerClientEvent('NDM_BodyCamera:client:ItemUsed', source)
        end)

    elseif Config.Framework == 'esx' then
        ESX.RegisterUsableItem(Config.ItemName, function(source)
            TriggerClientEvent('NDM_BodyCamera:client:ItemUsed', source)
        end)
    end
    -- For 'standalone': the item use event must be triggered externally
    -- (e.g. from your inventory resource's server-side handler) via:
    --   TriggerClientEvent('NDM_BodyCamera:client:ItemUsed', source)
end

-- ── Helper: fetch player data from framework ──────────────────────────────────
local function GetPlayerData(source)
    local data = {
        citizenId  = tostring(source),
        firstName  = 'Unknown',
        lastName   = '',
        callsign   = 'N/A',
        job        = 'civilian',
        jobLabel   = 'Civilian',
    }

    if Config.Framework == 'gbcore' or Config.Framework == 'qb-core' then
        local Player = Core and Core.Functions and Core.Functions.GetPlayer(source)
        if Player then
            local pd   = Player.PlayerData
            local ci   = pd.charinfo or {}
            local job  = pd.job      or {}
            data.citizenId = pd.citizenid or tostring(source)
            data.firstName = ci.firstname or 'Unknown'
            data.lastName  = ci.lastname  or ''
            data.job       = job.name     or 'civilian'
            data.jobLabel  = job.label    or data.job
            -- callsign stored in metadata (optional)
            if pd.metadata and pd.metadata.callsign then
                data.callsign = pd.metadata.callsign
            end
        end

    elseif Config.Framework == 'esx' then
        local xPlayer = Core and Core.GetPlayerFromId(source)
        if xPlayer then
            data.citizenId = xPlayer.identifier
            data.firstName = xPlayer.get('firstName') or 'Unknown'
            data.lastName  = xPlayer.get('lastName')  or ''
            data.job       = xPlayer.job.name
            data.jobLabel  = xPlayer.job.label
        end

    else
        -- standalone fallback: use player name only
        data.firstName = GetPlayerName(source) or 'Unknown'
    end

    return data
end

-- ── Helper: generate or retrieve a persistent serial number ──────────────────
local function GetOrCreateSerial(citizenId)
    -- 1. Try the database first
    local serial = Config.UseDatabase and DB_GetSerial(citizenId) or nil

    if not serial then
        -- 2. Generate a new one
        math.randomseed(os.time() + tonumber(citizenId:gsub('%D', '') or 0))
        local num = math.random(1, 10 ^ Config.SerialLength - 1)
        serial = Config.SerialPrefix .. '-' .. string.format('%0' .. Config.SerialLength .. 'd', num)

        -- 3. Persist it
        if Config.UseDatabase then
            DB_SaveSerial(citizenId, serial)
        end
    end

    return serial
end

-- ── Helper: job allowed check ─────────────────────────────────────────────────
local function IsJobAllowed(job)
    if not Config.AllowedJobs or #Config.AllowedJobs == 0 then return true end
    for _, allowed in ipairs(Config.AllowedJobs) do
        if allowed == job then return true end
    end
    return false
end

-- ── Event: client requests camera open ───────────────────────────────────────
RegisterNetEvent('NDM_BodyCamera:server:RequestOpen', function()
    local source = source
    local pd     = GetPlayerData(source)

    if not IsJobAllowed(pd.job) then
        TriggerClientEvent('NDM_BodyCamera:client:JobDenied', source)
        return
    end

    local serial = GetOrCreateSerial(pd.citizenId)
    local logId  = DB_StartSession(pd.citizenId, pd.firstName .. ' ' .. pd.lastName, pd.callsign, serial, pd.job)

    Sessions[source] = {
        serial    = serial,
        logId     = logId,
        citizenId = pd.citizenId,
    }

    TriggerClientEvent('NDM_BodyCamera:client:Open', source, {
        officerName = pd.firstName .. ' ' .. pd.lastName,
        callsign    = pd.callsign,
        department  = pd.jobLabel,
        serial      = serial,
    })
end)

-- ── Event: client reports camera closed ──────────────────────────────────────
RegisterNetEvent('NDM_BodyCamera:server:Closed', function()
    local source  = source
    local session = Sessions[source]
    if session then
        DB_EndSession(session.logId)
        Sessions[source] = nil
    end
end)

-- ── Cleanup on player drop ────────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    local source  = source
    local session = Sessions[source]
    if session then
        DB_EndSession(session.logId)
        Sessions[source] = nil
    end
end)
