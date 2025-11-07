local transport = require and require("railnet.lib.transport") or dofile("/railnet/lib/transport.lua")
transport.init()
local C = {}
local JOBS_PATH   = "/railnet/var/cargo_jobs.json"
local ROUTES_PATH = "/railnet/data/cargo_routes.json"
local STATS_PATH  = "/railnet/var/cargo_stats.json"
local function rjson(p) if not fs.exists(p) then return nil end local h=fs.open(p,"r"); local s=h.readAll(); h.close(); local ok,j=pcall(textutils.unserializeJSON,s); if ok then return j end end
local function wjson(p,t) fs.makeDir(fs.getDir(p)); local h=fs.open(p,"w"); h.write(textutils.serializeJSON(t,true)); h.close() end
local function now() return os.epoch("utc") end
local JOBS   = rjson(JOBS_PATH)   or { queue = {}, active = {}, done = {} }
local ROUTES = rjson(ROUTES_PATH) or {}
local STATS  = rjson(STATS_PATH)  or { started=0, finished=0, failed=0, canceled=0, p99_ms=0 }
local function save() wjson(JOBS_PATH,JOBS); wjson(STATS_PATH,STATS) end
function C.define_route(name, spec) ROUTES[name] = spec; wjson(ROUTES_PATH, ROUTES) end
function C.list_routes() local t={} for k,v in pairs(ROUTES) do t[#t+1]={name=k, stops=v.stops and #v.stops or 0} end table.sort(t,function(a,b) return a.name<b.name end) return t end
local function new_id() return "CJ:"..now()..":"..math.random(1000,9999) end
function C.enqueue(job)
  job.id = job.id or new_id(); job.created = job.created or now(); job.train_type = "cargo"; job.priority = job.priority or 50; job.state = job.state or "queued"
  table.insert(JOBS.queue, job)
  table.sort(JOBS.queue, function(a,b) if a.priority==b.priority then return a.created<b.created end return a.priority<b.priority end)
  save(); transport.publish("cargo/queue_changed", { ts=now() }); return job.id
end
local function activate(job) JOBS.active[job.id] = { job = job, started = now(), idx = 1, state = "assign", retries = 0, stop_started = 0 }; job.state = "active"; STATS.started = STATS.started + 1; save(); return JOBS.active[job.id] end
function C.pop_next() local j = table.remove(JOBS.queue, 1); if j then return activate(j) end end
function C.cancel(job_id)
  if JOBS.active[job_id] then JOBS.done[#JOBS.done+1] = { job=JOBS.active[job_id].job, finished=now(), state="canceled" }; JOBS.active[job_id] = nil
  else for i,j in ipairs(JOBS.queue) do if j.id==job_id then table.remove(JOBS.queue,i); break end end end
  STATS.canceled = STATS.canceled + 1; save(); transport.publish("cargo/job_canceled", { id=job_id }); return true
end
function C.pause(job_id) local st = JOBS.active[job_id]; if not st then return false end st.job.state = "paused"; st.state = "paused"; save(); return true end
function C.resume(job_id)
  local st = JOBS.active[job_id]; if st then st.job.state="active"; if st.state=="paused" then st.state="enroute" end; save(); return true end
  for i,j in ipairs(JOBS.queue) do if j.id==job_id then table.remove(JOBS.queue,i); activate(j); return true end end; return false
end
function C.mark_done(job_id) local a = JOBS.active[job_id]; if not a then return false end; a.finished = now(); JOBS.done[#JOBS.done+1] = a; JOBS.active[job_id]=nil; STATS.finished=STATS.finished+1; save(); transport.publish("cargo/job_done", { id=job_id }); return true end
function C.mark_failed(job_id, reason) local a = JOBS.active[job_id]; if not a then return false end; a.failed = now(); a.reason=reason; a.state="failed"; JOBS.done[#JOBS.done+1] = a; JOBS.active[job_id]=nil; STATS.failed=STATS.failed+1; save(); transport.publish("cargo/job_failed", { id=job_id, reason=reason, train_id=a.job.train_id }); return true end
function C.list_jobs() local q={} for _,j in ipairs(JOBS.queue) do q[#q+1]=j end; local a={} for id,st in pairs(JOBS.active) do a[#a+1]={ id=id, route=st.job.route, idx=st.idx, state=st.state, train_id=st.job.train_id, stop_started=st.stop_started, retries=st.retries or 0 } end; table.sort(a,function(x,y) return x.id<y.id end); return { queue=q, active=a, stats=STATS } end
local function current_stop(st) local route = ROUTES[st.job.route]; return route, route and route.stops and route.stops[st.idx] or nil end
local function publish_assign(st) local route, stop = current_stop(st); if not stop then return end transport.publish("cargo/assign", { job_id = st.job.id, station_id = stop.station_id, platform_id = stop.platform_id, expect = stop.action, filter = stop.filter, amount = stop.amount }) end
transport.subscribe("depot/train_dispatched", function(ev) if not ev or not ev.job_id or not ev.train_id then return end local st = JOBS.active[ev.job_id]; if not st then return end st.job.train_id = ev.train_id; st.state = "enroute"; st.stop_started = now(); save(); publish_assign(st) end)
transport.subscribe("cargo/station_ready", function(ev)
  if not ev or not ev.job_id then return end
  local st = JOBS.active[ev.job_id]; if not st or st.state=="paused" then return end
  local route, stop = current_stop(st); if not stop then return end
  if ev.station_id == stop.station_id and (not stop.platform_id or ev.platform_id == stop.platform_id) then
    transport.publish("cargo/perform", { job_id=ev.job_id, action=stop.action, station_id=ev.station_id, platform_id=ev.platform_id, filter=stop.filter, amount=stop.amount, timeout=stop.max_wait_s })
    st.state="processing"; st.stop_started = now(); save()
  end
end)
transport.subscribe("cargo/station_done", function(ev)
  if not ev or not ev.job_id then return end
  local st = JOBS.active[ev.job_id]; if not st then return end
  st.idx = st.idx + 1; st.state = "enroute"; st.stop_started = now(); save()
  local route,_ = current_stop(st)
  if not route or not route.stops or st.idx>#route.stops then C.mark_done(ev.job_id) else publish_assign(st) end
end)
local running=false; local MAX_RETRIES=2
local function step_active()
  for id,st in pairs(JOBS.active) do
    if st.state=="processing" then
      local route, stop = current_stop(st); if stop then
        local deadline = (stop.max_wait_s or 60)*1000
        if now() - (st.stop_started or now()) > deadline then
          st.retries = (st.retries or 0) + 1
          if st.retries<=MAX_RETRIES then
            transport.publish("cargo/perform", { job_id=st.job.id, action=stop.action, station_id=stop.station_id, platform_id=stop.platform_id, filter=stop.filter, amount=stop.amount, timeout=stop.max_wait_s })
            st.stop_started = now(); save()
          else C.mark_failed(st.job.id, "timeout:"..tostring(stop.action)) end
        end
      end
    end
  end
end
function C.scheduler_start()
  if running then return end; running=true
  parallel.waitForAny(function()
    while true do
      if JOBS.queue[1] then local st = C.pop_next(); if st then transport.publish("depot/request_train", { type=st.job.train_type, job_id=st.job.id, route=st.job.route }) end end
      step_active(); os.sleep(0.25)
    end
  end, function() while true do os.pullEvent() end end)
end
return C
