Config = {}

-- ─────────────────────────────────────────────────────────────────────────────
--  NDM Body Camera — Configuration
--  Edit this file to customise the resource for your server.
-- ─────────────────────────────────────────────────────────────────────────────

-- Framework bridge
--   'gbcore'     → gbcore (primary target)
--   'qb-core'    → QBCore
--   'esx'        → ESX / es_extended
--   'standalone' → no framework (item use via direct export call)
Config.Framework = 'gbcore'

-- Name of the usable inventory item that activates the body camera.
-- Make sure this item is registered in your inventory system (ox_inventory,
-- gbcore items, qb-inventory, etc.).
Config.ItemName = 'bodycam'

-- Jobs that are permitted to use the body camera.
-- Leave the table empty ( {} ) to allow every job.
Config.AllowedJobs = {
    'police',
    'sheriff',
    'ems',
    'security',
}

-- ── Serial Number ─────────────────────────────────────────────────────────────
-- Format: <Prefix>-<zero-padded number>  e.g. CAM-004821
Config.SerialPrefix = 'CAM'
Config.SerialLength = 6  -- number of digits after the prefix

-- ── Database ──────────────────────────────────────────────────────────────────
-- Requires oxmysql. Set UseDatabase = false to run without a database
-- (serials will not persist between sessions).
Config.UseDatabase = true

-- Log the start and end time of every recording session.
Config.LogSessions = true

-- ── Notifications ────────────────────────────────────────────────────────────
-- How to display activation / deactivation notices to the player.
-- 'notification' → framework native notification
-- 'chat'         → chat message
-- 'none'         → silent
Config.NotifyStyle = 'notification'

-- How long notifications stay on screen (milliseconds).
Config.NotifyDuration = 4000

-- ── UI Labels ────────────────────────────────────────────────────────────────
-- Text displayed inside the HUD widget (change for non-English servers).
Config.Labels = {
    rec        = 'REC',
    officer    = 'OFFICER',
    badge      = 'BADGE',
    department = 'DEPT',
    serial     = 'SN',
}
