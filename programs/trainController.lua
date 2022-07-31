--$ARGS|Channel (40)|$ARGS

-- Libraries
local setup = require("/lua/lib/setupUtils")
local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local drawBox = monUtils.drawBox
local createButton = monUtils.createButton
local stateHandler = require("/lua/lib/stateHandler")
local network = require("/lua/lib/networkUtils")
local utils = require("/lua/lib/utils")

-- Args
local args = { ... }
local channel = tonumber(args[1]) or 40

-- Peripherals
local wrappedPers = setup.getPers({
  "modem",
  "monitor"
})
local modem = wrappedPers.modem[1]
local monitor = setup.setupMonitor(
    wrappedPers.monitor[1], 0.5
)

-- Windows
local winHeader = setup.setupWindow(
    monitor, 1, 1, monitor.x, 6
)
local winFooter = setup.setupWindow(
    monitor, 1, (monitor.y - 5), monitor.x, 6
)
local winMain = setup.setupWindow(
    monitor, 1, 7, monitor.x, (monitor.y - (6 + 6)) 
)

-- Setup
local STATIONS = {}
local MODE = "stations"

function start()
  parallel.waitForAny(joinNetwork, await)
end

function joinNetwork()
  network.joinOrCreate(channel, true, nil, function (devices)
    STATIONS = devices;
    print(textutils.serializeJSON(devices))
  end)
end

function await()
  drawAll()
  while true do
    os.sleep(1)
  end
end

function drawAll()
  while true do
    drawHeader()
    parallel.waitForAny(drawFooter, drawMain)
  end
end

function drawHeader()
  winHeader.bg = colors.blue
  winHeader.setBackgroundColor(winHeader.bg)
  
  drawBox(winHeader,
      1, 1, winHeader.x, winHeader.y,
      true
  )
  drawBox(winHeader,
      1, winHeader.y, winHeader.x, winHeader.y,
      true, colors.white
  )
  
  write(winHeader, "Train Controller", 0, 2, "center")
  write(winHeader, "Mode: " .. utils.capitalize(MODE), 0, 4, "center")
end

function drawFooter()
  winFooter.bg = colors.blue
  winFooter.setBackgroundColor(winFooter.bg)
  
  drawBox(winFooter,
    1, 1, winFooter.x, winFooter.y,
    true
  )
  drawBox(winFooter,
    1, 1, winFooter.x, 1,
    true, colors.white
  )
  
  local createViewStationsButton = function()
    createButton(winFooter, 3, 3, 2, 1, "left", colors.white, colors.blue, "Stations", function ()
      MODE = "stations"
      return true
    end)
  end
  
  local createViewTrainsButton = function()
    createButton(winFooter, 0, 3, 2, 1, "center", colors.white, colors.blue, "Trains", function ()
      MODE = "trains"
      return true
    end)
  end
  
  local createSchedulesButton = function()
    createButton(winFooter, 3, 3, 2, 1, "right", colors.white, colors.blue, "Schedules", function ()
      MODE = "schedules"
      return true
    end)
  end

  parallel.waitForAny(createViewStationsButton, createViewTrainsButton, createSchedulesButton)
end

function drawMain()
  winMain.bg = colors.cyan
  winMain.setBackgroundColor(winMain.bg)
  
  drawBox(winMain,
      1, 1, winMain.x, winMain.y,
      true
  )


  if MODE == "stations" then
    drawStations()
  end

  while true do
    sleep(1)
  end
end

function drawStations()
  for i, station in pairs(STATIONS) do
    print()
    write(winMain, station.stationName, 3, i + 1, "left", colors.white)
  end
  
end

setup.utilsWrapper(start, modem, channel)