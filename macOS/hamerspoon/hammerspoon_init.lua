local hyper = { "cmd", "alt", "ctrl" }
local hypershift = { "cmd", "alt", "ctrl", "shift" }
local bluetooth = require("hs._asm.undocumented.bluetooth")

function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end
homeWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/configs/hammerspoon/", reloadConfig):start()
hs.notify.new({title="Hammerspoon", informativeText="Config loaded"}):send()

local applicationHotkeys = {
  q = 'Visual Studio Code',
  w = 'IntelliJ IDEA CE',
  e = 'PyCharm CE',
  
  a = 'Sequel Pro',
  s = 'Google Chrome',
  d = 'iTerm',

  z = 'Spotify',
  x = 'Station',
  c = 'Quiver',
}
for key, app in pairs(applicationHotkeys) do
  hs.hotkey.bind(hyper, key, function()
    hs.application.launchOrFocus(app)
  end)
end


hs.hotkey.bind(hyper, "f6", function()
  hs.spotify.displayCurrentTrack()
end)

-- hs.hotkey.bind(hyper, "c", function()
--   hs.eventtap.keyStroke({"alt"}, "space")
--   hs.eventtap.keyStrokes("cb")
--   hs.eventtap.keyStroke({},"return",hs.eventtap.keyRepeatInterval())
-- end)

hs.hotkey.bind(hyper, "f", function()
  hs.eventtap.keyStroke({"cmd"}, "c")
  local search = "https://www.google.com/search?q=" .. hs.pasteboard.getContents():gsub(" ", "%%20")
  hs.urlevent.openURLWithBundle(search, 'com.google.Chrome')
end)

hs.hotkey.bind(hyper, "v", function()
  hs.eventtap.keyStroke({"cmd"}, "c", hs.eventtap.keyRepeatInterval())
  hs.eventtap.keyStroke({"cmd"}, "f")
  hs.eventtap.keyStroke({"cmd"}, "v", hs.eventtap.keyRepeatInterval())
end)

hs.hotkey.bind(hyper, "`", function()
  hs.eventtap.keyStroke({"alt"}, "right")
  hs.eventtap.keyStroke({"alt", "shift"}, "left")
end)

hs.hotkey.bind(hyper, "space", function()
  hs.eventtap.keyStroke({"cmd"}, "c", hs.eventtap.keyRepeatInterval())
  hs.eventtap.keyStroke({"alt"}, "space")
  hs.eventtap.keyStrokes("opengrok \"")
  hs.eventtap.keyStroke({"cmd"}, "v", hs.eventtap.keyRepeatInterval())
  hs.eventtap.keyStrokes("\"")
  hs.eventtap.keyStroke({}, "return", hs.eventtap.keyRepeatInterval())
end)

-- Copy my PROD / QA portals to clipboard
hs.hotkey.bind(hyper, "=", function ()
  hs.execute("portalcp", true)
end)

hs.hotkey.bind(hypershift, "=", function()
  hs.execute("portalcp qa", true)
end)

mouseCircle = nil
mouseCircleTimer = nil

function mouseHighlight()
    -- Delete an existing highlight if it exists
    if mouseCircle then
        mouseCircle:delete()
        if mouseCircleTimer then
            mouseCircleTimer:stop()
        end
    end
    -- Get the current co-ordinates of the mouse pointer
    mousepoint = hs.mouse.getAbsolutePosition()
    -- Prepare a big red circle around the mouse pointer
    mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x-40, mousepoint.y-40, 80, 80))
    mouseCircle:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1})
    mouseCircle:setFill(false)
    mouseCircle:setStrokeWidth(5)
    mouseCircle:show()

    -- Set a timer to delete the circle after 3 seconds
    mouseCircleTimer = hs.timer.doAfter(2, function() mouseCircle:delete() end)
end
hs.hotkey.bind(hyper, "4", mouseHighlight)


local workWifi = 'HS-Corp'
local outputDeviceName = 'Built-in Output'
hs.wifi.watcher.new(function()
    local currentWifi = hs.wifi.currentNetwork()
    local currentOutput = hs.audiodevice.current(false)
    if not currentWifi then return end
    if (currentWifi == workWifi and currentOutput.name == outputDeviceName) then
        hs.audiodevice.findDeviceByName(outputDeviceName):setOutputMuted(true)
        -- bluetooth.power(true)
    end
end):start()


bluetoothName = "WH-1000XM3"
function toggleConnection(value)
  command = "blueutil --" .. value .. " " .. bluetoothName
  print("Bluetooth callback: " .. command)
  
  result = hs.execute(command, true)

  if result.status ~= nil then
    -- print("Error setting bluetooth to " .. value)
    -- print(result)
      print("Unexpected result executing  blueutil: ")
  end
end

function sleepBluetoothWatcher(event)
  if event == hs.caffeinate.watcher.systemWillSleep then
      toggleConnection("disconnect")
  elseif event == hs.caffeinate.watcher.screensDidWake then
      toggleConnection("connect")
  end
end

watcher = hs.caffeinate.watcher.new(sleepBluetoothWatcher)
watcher:start()


hs.hotkey.bind(hyper, "-", function ()
  toggleConnection("connect")
end)

hs.hotkey.bind(hypershift, "-", function ()
  toggleConnection("disconnect")
end)


function applicationWatcher(appName, eventType, appObject)
    if (eventType == hs.application.watcher.activated) then
        if (appName == "Finder") then
            -- Bring all Finder windows forward when one gets activated
            appObject:selectMenuItem({"Window", "Bring All to Front"})
        end
    end
end
appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

hs.loadSpoon("WifiNotifier")
spoon.WifiNotifier:start()

