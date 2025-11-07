local cargo = require and require("railnet.lib.cargo") or dofile("/railnet/lib/cargo.lua")
local transport = require and require("railnet.lib.transport") or dofile("/railnet/lib/transport.lua"); transport.init()
local P = {}
function P.render(t) term.setBackgroundColor(colors.black); term.setTextColor(colors.white); term.clear()
  local L = (cargo.list_jobs and cargo.list_jobs()) or {queue={},active={}}
  term.setCursorPos(2,1); term.write("Cargo – [N]ew  [S]tart  [Q]uit"); term.setCursorPos(2,3)
  term.write("Queue: "..tostring(#L.queue).."  Active: "..tostring(#L.active))
end
function P.loop()
  while true do local e,k=os.pullEvent()
    if e=="key" then if k==keys.q then break
      elseif k==keys.s then cargo.scheduler_start()
      elseif k==keys.n then term.setCursorPos(2,6); term.clearLine(); write("Route: "); local r=read() or ""; if r~="" then cargo.enqueue({route=r}) end end
    end
  end
end
return P
