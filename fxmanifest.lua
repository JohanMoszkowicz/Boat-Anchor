fx_version 'cerulean'
game 'gta5'

author 'Johan Moszkowicz'
description 'Boot anker script '
version '1.0.0'

client_scripts {
    'config.lua',
    'client.lua',
}

server_scripts {
    'server.lua',
}

dependencies {
    'ox_target',
    'ox_lib' -- als je die gebruikt voor notificaties
}
