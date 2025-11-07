local transport = require and require("railnet.lib.transport") or dofile("/railnet/lib/transport.lua"); transport.init()
local P = {}
local STATE = { trains = {}, order = {}, sel = 1, btns = {} }
transport.subscribe("depot/train_register", function(ev) if not ev or not ev.train_id then return end STATE.trains[ev.train_id] = STATE.trains[ev.train_id] or { id=ev.train_id, depot_id=ev.depot_id, type=ev.type or "cargo", pos=nil } end)
transport.subscribe("train/status", function(ev) if not ev or not ev.train_id then return end local t = STATE.trains[ev.train_id] or { id=ev.train_id } t.pos = ev.pos STATE.trains[ev.train_id] = t end)
local function btn(x,y,label,key) term.setCursorPos(x,y); term.setBackgroundColor(colors.blue); term.setTextColor(colors.white) term.write(" "..label.." "); return x + #label + 3, {x=x, y=y, w=#label+2, h=1, key=key} end
local function draw()
  term.setBackgroundColor(colors.black); term.setTextColor(colors.white); term.clear()
  term.setCursorPos(2,1); term.write("Train Control – [S]tart  s[T]op  [B]oost  [R]ed  [G]reen  [Q]uit")
  local y = 3; STATE.order = {}; for id,_ in pairs(STATE.trains) do STATE.order[#STATE.order+1]=id end; table.sort(STATE.order)
  for i,id in ipairs(STATE.order) do local t=STATE.trains[id]; term.setCursorPos(2,y+i-1); local mark=(i==STATE.sel) and ">" or " "; term.write(string.format("%s %s  depot:%s  type:%s", mark, id, tostring(t.depot_id or "-"), tostring(t.type or "-"))) end
  local _,h = term.getSize(); local yb = h-1; local x=2; STATE.btns={}; x,b1=btn(x,yb,"Start","start"); table.insert(STATE.btns,b1); x,b2=btn(x,yb,"Stop","stop"); table.insert(STATE.btns,b2); x,b3=btn(x,yb,"Boost","boost"); table.insert(STATE.btns,b3); x,b4=btn(x,yb,"Red","red"); table.insert(STATE.btns,b4); x,b5=btn(x,yb,"Green","green"); table.insert(STATE.btns,b5)
end
local function current_id() return STATE.order[STATE.sel] end
local function send(cmd, extra) local id=current_id(); if not id then return end local p={train_id=id, cmd=cmd}; if extra then for k,v in pairs(extra) do p[k]=v end end; transport.publish("train/command", p) end
function P.render(t) draw() end
function P.loop()
  draw()
  while true do local e,a,b,c=os.pullEvent()
    if e=="key" then if a==keys.q then break
      elseif a==keys.up then STATE.sel=math.max(1,STATE.sel-1); draw()
      elseif a==keys.down then STATE.sel=STATE.sel+1; draw()
      elseif a==keys.s then send("start",{speed=1.0}); draw()
      elseif a==keys.t then send("stop"); draw()
      elseif a==keys.b then send("boost",{ticks=40}); draw()
      elseif a==keys.r then send("signal",{aspect="red"}); draw()
      elseif a==keys.g then send("signal",{aspect="green"}); draw()
    end
    elseif e=="monitor_touch" or e=="mouse_click" then for _,bt in ipairs(STATE.btns) do if b>=bt.x and b<bt.x+bt.w and c==bt.y then if bt.key=="start" then send("start",{speed=1.0}) elseif bt.key=="stop" then send("stop") elseif bt.key=="boost" then send("boost",{ticks=40}) elseif bt.key=="red" then send("signal",{aspect="red"}) elseif bt.key=="green" then send("signal",{aspect="green"}) end draw(); break end end
    elseif e=="modem_message" then draw() end
  end
end
return P
