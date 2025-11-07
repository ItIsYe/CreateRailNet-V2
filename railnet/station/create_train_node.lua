local transport = require and require('railnet.lib.transport') or dofile('/railnet/lib/transport.lua'); transport.init()
local adapter   = require and require('railnet.lib.create_adapter') or dofile('/railnet/lib/create_adapter.lua')
local cfg=(function() if fs.exists('/railnet/device_config.lua') then local f=loadfile('/railnet/device_config.lua'); local ok,t=pcall(f); if ok and type(t)=='table' then return t end end return {} end)()
local TRAIN_ID = cfg.train_id or ('T:'..os.getComputerID())
transport.subscribe('train/command', function(ev) if not ev or (ev.train_id and ev.train_id~=TRAIN_ID) then return end local c=ev.cmd
  if c=='start' then adapter.train_start(ev.speed) elseif c=='stop' then adapter.train_stop() elseif c=='boost' then adapter.train_boost(ev.ticks)
  elseif c=='signal' then adapter.signal_set(ev.aspect) elseif c=='switch' then adapter.switch_set(ev.pos) end end)
local function announcer() while true do local pos=adapter.train_get_pos(); transport.publish('train/status',{train_id=TRAIN_ID,pos=pos}); os.sleep(1.0) end end
print('CreateTrainNode ready: '..TRAIN_ID); parallel.waitForAny(announcer, function() while true do os.pullEvent() end end)
