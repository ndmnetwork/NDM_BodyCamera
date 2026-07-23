-- ─────────────────────────────────────────────────────────────────────────────
--  NDM Body Camera — Client-side main
-- ─────────────────────────────────────────────────────────────────────────────

local isOpen    = false
local Framework = nil

-- ── Framework bridge initialisation ──────────────────────────────────────────
CreateThread(function()
    if Config.Framework == 'gbcore' then
        Framework = exports['gbcore']:GetCoreObject()
    elseif Config.Framework == 'qb-core' then
        Framework = exports['qb-core']:GetCoreObject()
    elseif Config.Framework == 'esx' then
        Framework = exports['es_extended']:getSharedObject()
    end
end)

-- ── Notification helper ───────────────────────────────────────────────────────
local function Notify(message, notifType)
    notifType = notifType or 'primary'

    if Config.NotifyStyle == 'none' then return end

    if Config.NotifyStyle == 'chat' then
        TriggerEvent('chat:addMessage', {
            color = { 0, 150, 255 },
            args  = { '[BodyCam]', message },
        })
        return
    end

    -- 'notification' — try framework, fall back to chat
    if Framework then
        if Config.Framework == 'gbcore' or Config.Framework == 'qb-core' then
            if Framework.Functions and Framework.Functions.Notify then
                Framework.Functions.Notify(message, notifType, Config.NotifyDuration)
                return
            end
        elseif Config.Framework == 'esx' then
            if Framework.ShowNotification then
                Framework.ShowNotification(message)
                return
            end
        end
    end

    TriggerEvent('chat:addMessage', {
        color = { 0, 150, 255 },
        args  = { '[BodyCam]', message },
    })
end

-- ── Open body camera ──────────────────────────────────────────────────────────
local function OpenBodyCam(data)
    isOpen = true

    SendNUIMessage({
        type        = 'openCamera',
        officerName = data.officerName,
        callsign    = data.callsign,
        department  = data.department,
        serial      = data.serial,
        labels      = Config.Labels,
    })

    Notify('Body camera activated — ' .. data.serial, 'success')
end

-- ── Close body camera ─────────────────────────────────────────────────────────
local function CloseBodyCam()
    if not isOpen then return end
    isOpen = false

    SendNUIMessage({ type = 'closeCamera' })
    TriggerServerEvent('NDM_BodyCamera:server:Closed')

    Notify('Body camera deactivated', 'error')
end

-- ── Item use event (triggered by server after framework item callback) ─────────
RegisterNetEvent('NDM_BodyCamera:client:ItemUsed', function()
    if isOpen then
        CloseBodyCam()
    else
        TriggerServerEvent('NDM_BodyCamera:server:RequestOpen')
    end
end)

-- ── Server response: approved open ───────────────────────────────────────────
RegisterNetEvent('NDM_BodyCamera:client:Open', function(data)
    OpenBodyCam(data)
end)

-- ── Server response: job not allowed ─────────────────────────────────────────
RegisterNetEvent('NDM_BodyCamera:client:JobDenied', function()
    Notify('Your current job is not authorised to use a body camera.', 'error')
end)

-- ── NUI callback: UI requested close (e.g. dragged off-screen or ESC) ────────
RegisterNUICallback('closeCamera', function(_, cb)
    CloseBodyCam()
    cb('ok')
end)

-- ── ESC key closes camera while it is active ──────────────────────────────────
CreateThread(function()
    while true do
        Wait(isOpen and 0 or 500)
        if isOpen and IsControlJustReleased(0, 200) then  -- INPUT_FRONTEND_CANCEL (ESC)
            CloseBodyCam()
        end
    end
end)
