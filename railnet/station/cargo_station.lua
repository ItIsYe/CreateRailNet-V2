local transport = require and require("railnet.lib.transport") or dofile("/railnet/lib/transport.lua")
transport.init()
local cfg=(function() if fs.exists("/railnet/device_config.lua") then local f=loadfile("/railnet/device_config.lua"); local ok,res=pcall(f); if ok and type(res)=="table" then return res end end return {} end)()
local SID=cfg.station_id or "S:UNKNOWN"; local PID=cfg.platform_id or nil
local IO=cfg.io or { loader="back", unloader="front" }; local SENS=cfg.sensors or { arrive="left", depart="right" }
local TIMEOUT=cfg.timeout_s or 60; local MODE=cfg.mode or "redstone"; local INV=cfg.inv and peripheral.wrap(cfg.inv.name or "") or nil
local active_job; local expected={action=nil,filter=nil,amount=nil}
local function say(msg) term.setTextColor(colors.white); term.setBackgroundColor(colors.black); print("[CargoStation] "..msg) end
local function wait_high(side) while not redstone.getInput(side) do os.sleep(0.05) end end
local function wait_depart(side) while not redstone.getInput(side) do os.sleep(0.05) end end
transport.subscribe("cargo/assign", function(ev) if not ev or ev.station_id ~= SID then return end active_job=ev.job_id; expected.action=ev.expect; expected.filter=ev.filter; expected.amount=ev.amount; say("assigned job="..tostring(active_job).." action="..tostring(expected.action)) end)
local function arrival_loop() while true do wait_high(SENS.arrive or "left"); if active_job then transport.publish("cargo/station_ready", { station_id=SID, platform_id=PID, job_id=active_job }); say("ready → job "..active_job) end; wait_depart(SENS.depart or "right"); os.sleep(0.5) end end
local function inv_do(action, filter, amount, timeout) if not INV then return false,"no_inventory" end local t_end=os.epoch("utc")+(math.floor(timeout or TIMEOUT)*1000) while os.epoch("utc")<t_end do os.sleep(0.05) end return true end
local function rs_do(action, amount, timeout) local side=(action=="load" and IO.loader) or (action=="unload" and IO.unloader) or IO.loader; local t_end=os.epoch("utc")+(math.floor(timeout or TIMEOUT)*1000); redstone.setOutput(side,true); while os.epoch("utc")<t_end do os.sleep(0.05) end; redstone.setOutput(side,false); return true end
transport.subscribe("cargo/perform", function(ev) if not ev or ev.station_id ~= SID then return end say("perform "..tostring(ev.action).." amt="..tostring(ev.amount)); local ok,err; if MODE=="inventory" then ok,err=inv_do(ev.action,ev.filter,ev.amount,ev.timeout) else ok,err=rs_do(ev.action,ev.amount,ev.timeout) end; if ok then transport.publish("cargo/station_done", { job_id=ev.job_id, station_id=SID, platform_id=PID, action=ev.action }); say("done job="..tostring(ev.job_id)) else say("failed: "..tostring(err)) end end)
print("CargoStation v2 @ "..SID..(PID and (" / "..PID) or "").." mode="..MODE); parallel.waitForAny(arrival_loop, function() while true do os.pullEvent() end end)
