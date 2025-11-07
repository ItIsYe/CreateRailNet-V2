local transport = require and require("railnet.lib.transport") or dofile("/railnet/lib/transport.lua"); transport.init()
local Depot = require and require("railnet.panels.depot") or dofile("/railnet/panels/depot.lua")
local Cargo = require and require("railnet.panels.cargo") or dofile("/railnet/panels/cargo.lua")
local TrainControl = require and require("railnet.panels.train_control") or dofile("/railnet/panels/train_control.lua")
local tabs = {"Dashboard","Depot","Cargo","TrainControl"}; local current=1
local function draw_tabs() term.setBackgroundColor(colors.black); term.setTextColor(colors.white); term.clear(); term.setCursorPos(2,1); term.write("Tabs: "); local x=8
  for i,name in ipairs(tabs) do if i==current then term.setTextColor(colors.yellow) else term.setTextColor(colors.white) end term.setCursorPos(x,1); term.write(name.."  "); x=x+#name+2 end term.setTextColor(colors.white) end
local function render_panel() if tabs[current]=="Dashboard" then term.setCursorPos(2,3); term.write("Dashboard – LEFT/RIGHT wechseln, ENTER öffnet Panel.")
  elseif tabs[current]=="Depot" then Depot.render(term) elseif tabs[current]=="Cargo" then Cargo.render(term) elseif tabs[current]=="TrainControl" then TrainControl.render(term) end end
draw_tabs(); render_panel()
while true do local e,k=os.pullEvent("key")
  if k==keys.left then current=(current-2)%#tabs+1; draw_tabs(); render_panel()
  elseif k==keys.right then current=(current)%#tabs+1; draw_tabs(); render_panel()
  elseif k==keys.enter then if tabs[current]=="Depot" then Depot.loop() elseif tabs[current]=="Cargo" then Cargo.loop() elseif tabs[current]=="TrainControl" then TrainControl.loop() end; draw_tabs(); render_panel() end
end
