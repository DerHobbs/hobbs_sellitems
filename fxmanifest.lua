fx_version 'cerulean'
game 'gta5'

author 'DerHobbs'
description 'Items sales script'

lua54 'yes'

ox_lib 'locale'

shared_scripts {
  'config.lua',
  '@ox_lib/init.lua'
}

client_scripts {
  '@qbx_core/modules/playerdata.lua',
  'client.lua'
}

server_scripts {
  'server.lua'
}

files {
  'locales/*.json'
}

dependencies {
  'qbx_core',
  'ox_lib',
  'ox_inventory'
}