--$ARGS|Channel (40)|$ARGS

-- Libraries
local setup = require("/lua/lib/setupUtils")
local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local drawBox = monUtils.drawBox
local fillBackground = monUtils.fillBackground
local createButton = monUtils.createButton
local createModal = monUtils.createModal
local stateHandler = require("/lua/lib/stateHandler")
local network = require("/lua/lib/networkUtils")
local utils = require("/lua/lib/utils")
local trainUtils = require("/lua/lib/trains/trainUtils")

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
    if MODE == "stations" then drawStations() end
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
    stations = drawStations,
    trains = drawTrains,
    schedules = drawSchedules,
  }

  drawFunctions[MODE]()
  

  while true do
    os.sleep(1)
  end

end

function drawStations()
  fillBackground(winMain, colors.black)

  for i, station in pairs(STATIONS) do
    write(winMain, "<#> " .. station.stationName, 3, i * 2 + 1, "left", colors.white)
  end
end

function drawTrains()
  fillBackground(winMain, colors.black)
  write(winMain, "Trains", 0, 3, "center", colors.white)

  local buttons = {}

  for i, train in pairs(TRAINS) do
    local y = i * 2 + 6

    write(winMain, "<=> " .. train.name, 3, y, "left", colors.white)

    table.insert(buttons, function ()
      createButton(winMain, 1, y, 1, 0, "right", colors.white, colors.black, "-", function ()
        drawDeleteTrain(train.name)
        return true
      end)
    end)
  end

  function createCreateButton()
    createButton(winMain, 2, 2, 2, 1, "right", colors.white, colors.black, "+", function ()
      drawCreateTrain()
      return true
    end)
  end

  parallel.waitForAny(createCreateButton, unpack(buttons))

  drawTrains()
end

function createTrain(trainName)
  table.insert(TRAINS, {
    name = trainName,
    schedules = {}
  })
  stateHandler.updateState("trains", TRAINS)
end

function deleteTrain(trainName)
  local _, i = utils.findInTable(TRAINS, function (train)
    return train.name == trainName
  end)
  if i then table.remove(TRAINS, i) end
  stateHandler.updateState("trains", TRAINS)
end

function drawCreateTrain()

  local trainName = "Unnamed"
  local action = nil
  local checkIsValid = function ()
    return utils.findInTable(TRAINS, function (train)
      return train.name == trainName
    end) == nil
  end
  
  
  local modalBody, awaitButtonInput = createModal(winMain, "Create a Train", colors.black, colors.white, colors.lightGray, nil, "Create")

  function readTrainName()
    local isValid = checkIsValid()

    fillBackground(modalBody, colors.white)
    write(modalBody, "Type a name for the train into the terminal", 0, (modalBody.y / 2) - 3, "center", colors.black)
    write(modalBody, "Current Name:", 0, (modalBody.y / 2) + 1, "center", colors.black)
    write(modalBody, trainName, 0, (modalBody.y / 2) + 3, "center", colors.black)

    if not isValid then
      write(modalBody, "This name is already taken", 0, (modalBody.y / 2) + 5, "center", colors.red)
    end

    print("Train Name: ")
    trainName = read()
  end

  while true do
    parallel.waitForAny(readTrainName, function ()
      action = awaitButtonInput(not checkIsValid())
    end)
    if action then break end;
  end


  if action == "submit" then
    createTrain(trainName)
  end
end

function drawDeleteTrain(trainName)
  local modalBody, awaitButtonInput = createModal(winMain, "Delete a Train", colors.black, colors.white, colors.lightGray, nil, "Delete")

  fillBackground(modalBody, colors.white)
  write(modalBody, "Are you sure you want to delete:", 0, (modalBody.y / 2) - 1, "center", colors.black)
  write(modalBody, trainName, 0, (modalBody.y / 2) + 2, "center", colors.black)

  local action = awaitButtonInput()

  if action == "submit" then
    deleteTrain(trainName)
  end
end

function drawSchedules()
  fillBackground(winMain, colors.black)
end

setup.utilsWrapper(start, modem, channel)