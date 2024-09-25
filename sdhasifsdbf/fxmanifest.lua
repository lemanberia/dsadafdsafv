fx_version 'cerulean'
game 'gta5'
lua54 'yes'
file 'config.lua'
shared_script '@ox_lib/init.lua'
client_script 'client.lua'
dependencies { 'ox_lib' }
server_scripts {
    '@oxmysql/lib/MySQL.lua',   
    'server.lua'
}
