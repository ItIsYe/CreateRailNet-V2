local transport = require and require("railnet.lib.transport") or dofile("/railnet/lib/transport.lua")
transport.init()
local cfg = (function() if fs.exists("/railnet/device_config.lua") then local f=loadfile("/railnet/device_config.lua"); local ok,res=pcall(f); if ok and type(res)=="table" then return res end end return {} end)()
local DID = cfg.depot_id or ("D:"..os.getComputerID()); local NAME=cfg.name or DID; local CAP=cfg.capacity or 0
local IO  = cfg.io or { dispatch="left", park="right", service="back" }
local TRAINS = {}
local function say(s) term.setTextColor(colors.white); term.setBackgroundColor(colors.black); print("[Depot] "..s) end
local function hello() transport.publish("depot/hello", { depot_id=DID, name=NAME, capacity=CAP }) end
local function add_train(train_id, ttype) if TRAINS[train_id] then return end TRAINS[train_id] = { type=ttype or "cargo", status="idle" }; transport.publish("depot/train_register", { depot_id=DID, train_id=train_id, type=ttype or "cargo" }); say("registered "..train_id) end
local function pulse(side, ms) redstone.setOutput(side, true); os.sleep((ms or 100)/1000); redstone.setOutput(side, false) end
transport.subscribe("depot/dispatch", function(ev) if not ev or ev.depot_id ~= DID then return end if not TRAINS[ev.train_id] then return end TRAINS[ev.train_id].status = "dispatch"; say("dispatch "..ev.train_id.." for job "..tostring(ev.job_id)); pulse(IO.dispatch, 300) end)
transport.subscribe("depot/service_route", function(ev) if not ev or ev.depot_id ~= DID then return end if not TRAINS[ev.train_id] then return end TRAINS[ev.train_id].status = "service"; say("service route for "..ev.train_id); pulse(IO.service, 300) end)
transport.subscribe("depot/park", function(ev) if not ev or ev.depot_id ~= DID then return end if not TRAINS[ev.train_id] then return end say("park "..ev.train_id); pulse(IO.park, 300) end)
local function repl() term.setBackgroundColor(colors.black); term.setTextColor(colors.white); term.clear(); hello(); say(NAME.." ready. Commands: add <T:ID> <cargo|pass>, idle <T:ID>")
  while true do write("> "); local ln = read() or ""; local cmd,a,b = ln:match("^(%S+)%s*(%S*)%s*(%S*)"); if cmd=="add" and a~="" then add_train(a,b) elseif cmd=="idle" and a~="" then transport.publish("depot/train_idle", { depot_id=DID, train_id=a }); say("idle "..a) end end end
parallel.waitForAny(repl, function() while true do os.sleep(10); hello() end end)
