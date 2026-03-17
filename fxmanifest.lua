fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Kieran - RatedScripts'
description 'rs_drugsell: Advanced drug selling with ox_target, robbery system and police alerts'
version '1.0.0'
version_url 'https://raw.githubusercontent.com/RatedScripts/rs_drugsell-2.0/main/version.txt'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/framework.lua'
}

client_scripts {
    'client/editable-dispatch.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_target',
    'ox_lib',
    'ox_inventory'
}

escrow_ignore {
  'client/main.lua',
  'client/editable-dispatch.lua',
  'server/main.lua'
}
