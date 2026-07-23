# NDM Body Camera

A **standalone** FiveM body-camera resource — gbcore compatible, with optional support for QBCore, ESX, or a frameworkless setup.

---

## ✅ Features

| Feature | Details |
|---|---|
| 🎒 Inventory item | Usable `bodycam` item via gbcore, QBCore, ESX, or any custom system |
| 🖥️ Draggable HUD | Compact on-screen widget; drag it anywhere — position persists across sessions |
| 👮 Officer data | Officer name, callsign / badge, and department pulled from your framework at runtime |
| 🕐 Live date & time | Real-time clock updated every second inside the widget |
| 🔢 Unique serial | Persistent `CAM-XXXXXX` serial per officer, stored in the database |
| 📷 Camera frame | Subtle corner-bracket overlay and vignette for a genuine body-cam look |
| 💾 Session logging | Start / end timestamps recorded per recording session |
| ⚙️ Configurable | Jobs whitelist, label language, notification style, and more |

---

## 📦 Installation

### 1 — Copy the resource
```
resources/
└── [ndm]/
    └── NDM_BodyCamera/   ← place the folder here
```

### 2 — Import the SQL schema
Run [`sql/bodycam.sql`](sql/bodycam.sql) against your database once:
```sql
-- creates `bodycam_serials` and `bodycam_logs` tables
```

### 3 — Add the item to your inventory

#### ox_inventory (`items.lua` / `data/items.lua`)
```lua
['bodycam'] = {
    label  = 'Body Camera',
    weight = 500,
    stack  = false,
    close  = true,
    image  = 'bodycam.png',   -- add icon to your ox_inventory images folder
},
```

#### gbcore / QBCore items file
```lua
['bodycam'] = {
    name        = 'bodycam',
    label       = 'Body Camera',
    weight      = 500,
    type        = 'item',
    image       = 'bodycam.png',
    unique      = true,
    useable     = true,
    shouldClose = true,
    description = 'An officer-grade body-worn camera.',
},
```

### 4 — Add to `server.cfg`
```
ensure NDM_BodyCamera
```

### 5 — Configure
Open [`config.lua`](config.lua) and set:
- `Config.Framework` — your framework (`'gbcore'`, `'qb-core'`, `'esx'`, `'standalone'`)
- `Config.AllowedJobs` — which jobs can activate the camera
- Any label / notification preferences

---

## ⚙️ Configuration reference

| Key | Default | Description |
|---|---|---|
| `Config.Framework` | `'gbcore'` | Framework bridge to use |
| `Config.ItemName` | `'bodycam'` | Inventory item name |
| `Config.AllowedJobs` | `{'police', 'sheriff', 'ems', 'security'}` | Permitted jobs (empty = all) |
| `Config.SerialPrefix` | `'CAM'` | Prefix for serial numbers |
| `Config.SerialLength` | `6` | Digits after the prefix |
| `Config.UseDatabase` | `true` | Persist serials & logs in MySQL |
| `Config.LogSessions` | `true` | Write start/end timestamps to DB |
| `Config.NotifyStyle` | `'notification'` | `'notification'`, `'chat'`, or `'none'` |
| `Config.NotifyDuration` | `4000` | ms for framework notifications |
| `Config.Labels` | see file | UI strings (translate for non-English servers) |

---

## 🗃️ Database tables

### `bodycam_serials`
| Column | Type | Description |
|---|---|---|
| `citizen_id` | VARCHAR(60) | Unique per officer |
| `serial` | VARCHAR(20) | e.g. `CAM-004821` |
| `issued_at` | TIMESTAMP | When the serial was first generated |

### `bodycam_logs`
| Column | Type | Description |
|---|---|---|
| `citizen_id` | VARCHAR(60) | Officer identifier |
| `officer_name` | VARCHAR(100) | Full name at recording time |
| `callsign` | VARCHAR(20) | Badge / callsign |
| `serial` | VARCHAR(20) | Camera serial used |
| `job` | VARCHAR(50) | Job name at recording time |
| `start_time` | DATETIME | When camera was activated |
| `end_time` | DATETIME | When camera was deactivated (NULL if still open) |

---

## 🧩 Architecture overview

```
NDM_BodyCamera/
├── fxmanifest.lua          — resource manifest
├── config.lua              — shared configuration
├── sql/
│   └── bodycam.sql         — database schema
├── client/
│   └── main.lua            — framework bridge, NUI control, ESC handler
├── server/
│   ├── main.lua            — item registration, serial logic, event handlers
│   └── sv_database.lua     — oxmysql helper functions
└── nui/
    ├── index.html          — HUD widget + corner frame markup
    ├── style.css           — camera-style UI, blinking REC dot, drag cursor
    └── script.js           — live clock, drag-to-move, NUI message router
```

### Event flow
```
Player uses item
    └─▶ [server] framework item callback
            └─▶ TriggerClientEvent NDM_BodyCamera:client:ItemUsed
                    └─▶ [client] TriggerServerEvent NDM_BodyCamera:server:RequestOpen
                            └─▶ [server] fetch officer data, get/create serial, log session
                                    └─▶ TriggerClientEvent NDM_BodyCamera:client:Open
                                            └─▶ [client] SendNUIMessage openCamera
                                                    └─▶ [nui] render widget + start clock

Player uses item again (or presses ESC)
    └─▶ [client] CloseBodyCam
            ├─▶ SendNUIMessage closeCamera
            └─▶ TriggerServerEvent NDM_BodyCamera:server:Closed
                    └─▶ [server] DB_EndSession (writes end_time)
```

---

## 🔧 Standalone / custom framework usage

If you set `Config.Framework = 'standalone'`, the item-use event must be fired from your own inventory resource:

```lua
-- In your inventory resource server-side:
TriggerClientEvent('NDM_BodyCamera:client:ItemUsed', source)
```

---

## 📋 Dependencies

| Dependency | Required | Notes |
|---|---|---|
| [oxmysql](https://github.com/overextended/oxmysql) | ✅ (when `Config.UseDatabase = true`) | Async MySQL wrapper |
| gbcore / QBCore / ESX | ✅ (unless `standalone`) | Your server framework |

---

## 📄 License

MIT — free to use, modify, and distribute.