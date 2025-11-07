local A = {}
local function load_json(p) if fs.exists(p) then local h=fs.open(p,'r'); local s=h.readAll(); h.close(); local ok,t=pcall(textutils.unserializeJSON,s); if ok and type(t)=='table' then return t end end end
local cfg = load_json('/railnet/etc/create_adapter.json') or {}
local mode = cfg.mode or 'auto'
local per = {train=nil, signal=nil, switch=nil}
local function wrap(name) if name and peripheral.isPresent(name) then return peripheral.wrap(name) end end
per.train  = wrap(cfg.peripherals and cfg.peripherals.train)
per.signal = wrap(cfg.peripherals and cfg.peripherals.signal)
per.switch = wrap(cfg.peripherals and cfg.peripherals.switch)
if not per.train then for _,n in ipairs(peripheral.getNames()) do local ty=peripheral.getType(n); if ty and (ty=='create_train' or ty=='train_controller' or ty=='create:train') then per.train=peripheral.wrap(n); break end end end
local function is_periph(x) return x~=nil end
function A.train_start(speed) if mode~='redstone' and is_periph(per.train) and per.train.start then return pcall(per.train.start, speed or 1.0) end local s=(cfg.train and cfg.train.start_side) or 'back'; redstone.setOutput(s,true); os.sleep(0.2); redstone.setOutput(s,false); return true end
function A.train_stop() if mode~='redstone' and is_periph(per.train) and per.train.stop then return pcall(per.train.stop) end local s=(cfg.train and cfg.train.stop_side) or 'left'; redstone.setOutput(s,true); os.sleep(0.2); redstone.setOutput(s,false); return true end
function A.train_boost(ticks) if mode~='redstone' and is_periph(per.train) and per.train.boost then return pcall(per.train.boost, ticks or 20) end local s=(cfg.train and cfg.train.boost_side) or 'right'; redstone.setOutput(s,true); os.sleep((ticks or 20)/20); redstone.setOutput(s,false); return true end
function A.train_get_id() if is_periph(per.train) and per.train.getID then local ok,id=pcall(per.train.getID); if ok then return id end end return nil end
function A.train_get_pos() if is_periph(per.train) and per.train.getPosition then local ok,pos=pcall(per.train.getPosition); if ok then return pos end end return nil end
function A.switch_set(pos) if mode~='redstone' and is_periph(per.switch) and per.switch.set then return pcall(per.switch.set, pos) end local st=(cfg.switch and cfg.switch.straight_side) or 'right'; local dv=(cfg.switch and cfg.switch.diverge_side) or 'back'; if pos=='straight' then redstone.setOutput(st,true); redstone.setOutput(dv,false) else redstone.setOutput(st,false); redstone.setOutput(dv,true) end return true end
function A.signal_set(aspect) if mode~='redstone' and is_periph(per.signal) and per.signal.set then return pcall(per.signal.set, aspect) end local side=(cfg.signals and cfg.signals.default_side) or 'top'; local red=(aspect=='red'); redstone.setOutput(side, red); return true end
return A
