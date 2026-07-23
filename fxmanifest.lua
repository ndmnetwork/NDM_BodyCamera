fx_version 'cerulean'
game 'gta5'

name        'NDM_BodyCamera'
description 'Standalone Body Camera System — gbcore compatible'
author      'NDMNetwork'
version     '1.0.0'
repository  'https://github.com/ndmnetwork/NDM_BodyCamera'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_database.lua',
    'server/main.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js'
}

lua54 'yes'
