-- ─────────────────────────────────────────────────────────────────────────────
--  NDM Body Camera — Database helpers  (server-side, requires oxmysql)
-- ─────────────────────────────────────────────────────────────────────────────

-- Returns the persisted serial for citizenId, or nil if not found.
function DB_GetSerial(citizenId)
    if not Config.UseDatabase then return nil end

    local result = MySQL.query.await(
        'SELECT serial FROM bodycam_serials WHERE citizen_id = ? LIMIT 1',
        { citizenId }
    )

    if result and #result > 0 then
        return result[1].serial
    end
    return nil
end

-- Persists a serial ↔ citizen_id mapping.  Ignored on duplicate.
function DB_SaveSerial(citizenId, serial)
    if not Config.UseDatabase then return end

    MySQL.insert.await(
        'INSERT IGNORE INTO bodycam_serials (citizen_id, serial) VALUES (?, ?)',
        { citizenId, serial }
    )
end

-- Inserts a new session log row and returns the inserted id.
function DB_StartSession(citizenId, officerName, callsign, serial, job)
    if not (Config.UseDatabase and Config.LogSessions) then return nil end

    local id = MySQL.insert.await(
        [[INSERT INTO bodycam_logs
            (citizen_id, officer_name, callsign, serial, job, start_time)
          VALUES (?, ?, ?, ?, ?, NOW())]],
        { citizenId, officerName, callsign, serial, job }
    )
    return id
end

-- Closes an open session by setting its end_time.
function DB_EndSession(logId)
    if not (Config.UseDatabase and Config.LogSessions) then return end
    if not logId then return end

    MySQL.update.await(
        'UPDATE bodycam_logs SET end_time = NOW() WHERE id = ?',
        { logId }
    )
end
