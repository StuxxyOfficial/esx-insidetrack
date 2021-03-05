fx_version 'cerulean'
game 'gta5'

version '1.0'

description 'Insidetrack casino game for qbus framework'

client_scripts {
    'client/utils.lua',
    'client/client.lua',
    
    'client/screens/*.lua',
}

server_script 'server/server.lua'