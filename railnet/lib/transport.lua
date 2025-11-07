local T = { subs = {}, req_wait = {}, seq = 0 }
local modem = peripheral.find("modem"); if modem and not modem.isOpen(0) then modem.open(0) end
local function now() return os.epoch("utc") end
function T.init() end
function T.subscribe(topic, fn) T.subs[topic] = T.subs[topic] or {}; table.insert(T.subs[topic], fn) end
local function deliver(topic, payload) for _,fn in ipairs(T.subs[topic] or {}) do pcall(fn, payload) end end
function T.publish(topic, payload, opts)
  opts = opts or {}; T.seq=(T.seq+1)%1000000
  local pkt = { topic=topic, payload=payload, ts=now(), seq=T.seq }
  if modem then modem.transmit(0,0,pkt) end; deliver(topic, payload)
  if opts.ack then
    local key=tostring(pkt.seq)..":"..topic; T.req_wait[key]={t0=now(),timeout=opts.timeout_ms or 1000}
    local deadline=T.req_wait[key].t0+T.req_wait[key].timeout
    while now()<deadline do if T.req_wait[key].ack then T.req_wait[key]=nil; return true end os.sleep(0.05) end
    T.req_wait[key]=nil; return false,"timeout"
  end
  return true
end
function T.ack(seq, topic) if modem then modem.transmit(0,0,{topic="__ack__",payload={seq=seq,topic=topic},ts=now()}) end end
local function loop()
  while true do
    local e, side, ch, rch, msg = os.pullEvent()
    if e=="modem_message" and type(msg)=="table" and msg.topic then
      if msg.topic=="__ack__" and msg.payload and msg.payload.seq then
        local key=tostring(msg.payload.seq)..":"..(msg.payload.topic or ""); if T.req_wait[key] then T.req_wait[key].ack=true end
      else deliver(msg.topic, msg.payload); if msg.seq then T.ack(msg.seq, msg.topic) end end
    end
  end
end
parallel.waitForAny(loop,function() end)
return T
