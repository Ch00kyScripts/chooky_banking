fx_version 'cerulean'
game 'gta5'

author 'Ch00ky'
description 'Sistema de banking avanzado para ESX Legacy con gestión de cuentas y préstamos'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}
client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/script.js',
    'html/style.css',
    'html/img/*.png',
    'html/img/*.jpg'
}

dependencies {
    'es_extended',
    'ox_lib',
    'oxmysql'
}