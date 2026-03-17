fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Kieran - RatedScripts'
description 'rs_drugsell: Advanced drug selling with ox_target, robbery system and police alerts'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
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
  'server/main.lua'
}
