--$ARGS|Channel (40)|$ARGS

-- Libraries
local setup = require("/lua/lib/setupUtils")
local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local drawBox = monUtils.drawBox
local fillBackground = monUtils.fillBackground
local createButton = monUtils.createButton
local stateHandler = require("/lua/lib/stateHandler")
local network = require("/lua/lib/networkUtils")
local utils = require("/lua/lib/utils")
local trainUtils = require("/lua/lib/trains/trainUtils")
local stationUtils = require("/lua/lib/trains/stationUtils")
local scheduleUtils = require("/lua/lib/trains/scheduleUtils")

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
local TRAINS = stateHandler.getState("trains") or {}
local MODE = "stations"

function start()
  parallel.waitForAny(joinNetwork, await)
end

function joinNetwork()
  network.joinOrCreate(channel, true, nil, function (devices)
    STATIONS = devices;
    if MODE == "stations" then stationUtils.drawStations(winMain, STATIONS) end
  end)
end

function await()
  parallel.waitForAny(drawAll, awaitNetwork)
end

function awaitNetwork()
  while true do
    local body = network.await()
  
    if(body.type == "/trains/get/train") then
      local trainName = body.trainName
      local train = utils.findInTable(TRAINS, function (train)
        return train.name == trainName
      end)

      modem.transmit(channel, channel, {
        type = "/trains/get/train-res",
        train = train
      })
    end
  end
end

function drawAll()
  while true do
    drawHeader()
    parallel.waitForAny(drawFooter, drawMain)
  end
end

function drawHeader()
  winHeader.bg = colors.green
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
  winFooter.bg = colors.green
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
    createButton(winFooter, 3, 3, 2, 1, "left", colors.white, colors.green, "Stations", function ()
      MODE = "stations"
      return true
    end)
  end
  
  local createViewTrainsButton = function()
    createButton(winFooter, 0, 3, 2, 1, "center", colors.white, colors.green, "Trains", function ()
      MODE = "trains"
      return true
    end)
  end
  
  local createSchedulesButton = function()
    createButton(winFooter, 3, 3, 2, 1, "right", colors.white, colors.green, "Schedules", function ()
      MODE = "schedules"
      return true
    end)
  end

  parallel.waitForAny(createViewStationsButton, createViewTrainsButton, createSchedulesButton)
end

function drawMain()

  local drawFunctions = {
    stations = function ()
      stationUtils.drawStations(winMain, STATIONS, channel)
    end,
    trains = function ()
      trainUtils.drawTrains(winMain, TRAINS)
    end,
    schedules = function ()
      scheduleUtils.drawSchedules(winMain, TRAINS, STATIONS)
    end,
  }

  drawFunctions[MODE]()


  while true do
    os.sleep(1)
  end

end

function drawSchedules()
  fillBackground(winMain, colors.black)
end

setup.utilsWrapper(start, modem, channel)