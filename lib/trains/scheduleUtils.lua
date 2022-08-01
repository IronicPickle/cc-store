local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local fillBackground = monUtils.fillBackground
local createButton = monUtils.createButton
local createModal = monUtils.createModal
local stateHandler = require("/lua/lib/stateHandler")
local utils = require("/lua/lib/utils")

local M = {}

function M.drawSchedules(output, trains, stations)
  while true do
    fillBackground(output, colors.black)
    write(output, "Schedules", 0, 3, "center", colors.white)

    local buttons = {}

    local filteredTrains = utils.filterTable(trains, function (train)
      return train.schedule and utils.tableLength(train.schedule) > 0
    end)

    local noStations = utils.tableLength(stations) == 0
    local noTrains = utils.tableLength(trains) == 0
    local noSchedules = utils.tableLength(filteredTrains) == 0
    if noStations then
      write(output, "No stations found, connect one to create a schedule.", 0, 7, "center", colors.white, colors.black)
    elseif noTrains then
      write(output, "No trains found, add one to create a schedule.", 0, 7, "center", colors.white, colors.black)
    elseif noSchedules then
      write(output, "No schedules found, click the plus to add one.", 0, 7, "center", colors.white, colors.black)
    else
      for i, train in pairs(filteredTrains) do
        local y = i * 2 + 6

        write(output, "<=> " .. train.schedule.name.." ("..train.name..")", 3, y, "left", colors.white)

        table.insert(buttons, function ()
          createButton(output, 1, y, 1, 0, "right", colors.white, colors.black, "-", function ()
            drawDeleteSchedule(output, trains, i)
            return true
          end)
        end)

        table.insert(buttons, function ()
          createButton(output, 5, y, 1, 0, "right", colors.white, colors.black, "Edit", function ()
            drawEditSchedule(output, stations, trains, i)
            return true
          end)
        end)
      end
    end

    function createCreateButton()
      createButton(output, 2, 2, 2, 1, "right", noTrains and colors.lightGray or colors.white, colors.black, "+", function ()
        if noTrains then return false end
        drawCreateSchedule(output, stations, trains)
        return true
      end)
    end

    parallel.waitForAny(createCreateButton, unpack(buttons))
  end
end

-- Create/Edit Schedule

function updateSchedule(scheduleName, route, trains, i)
  trains[i].schedule.name = scheduleName
  trains[i].schedule.route = route
  stateHandler.updateState("trains", trains)
end

function drawCreateSchedule(output, stations, trains, i)
  local action = nil
  local scheduleName = nil
  local trainName = nil
  local route = nil

  action, scheduleName = drawNameSchedule(output, trains)
  if action == "cancel" then return end

  action, trainName, i = drawSelectTrain(output, trains)
  if action == "cancel" then return end

  action, route, scheduleName = drawRouteTrain(output, stations, scheduleName, trainName, trains, i)
  if action == "cancel" then return end

  updateSchedule(scheduleName, route, trains, i)
end

function drawEditSchedule(output, stations, trains, i)
  local action = nil

  local schedule = trains[i].schedule

  local scheduleName = schedule.name
  local trainName = trains[i].name
  local route = schedule.route

  action, route, scheduleName = drawRouteTrain(output, stations, scheduleName, trainName, trains, i)
  if action == "cancel" then return end

  updateSchedule(scheduleName, route, trains, i)
end

-- Delete Schedule

function deleteSchedule(trains, i)
  trains[i].schedule = {}
  stateHandler.updateState("trains", trains)
end

function drawDeleteSchedule(output, trains, i)
  local modalBody, awaitButtonInput = createModal(output, "Delete a Schedule", colors.black, colors.white, colors.lightGray, nil, "Delete")

  fillBackground(modalBody, colors.white)
  write(modalBody, "Are you sure you want to delete:", 0, (modalBody.y / 2) - 1, "center", colors.black)
  write(modalBody, trains[i].schedule.name, 0, (modalBody.y / 2) + 2, "center", colors.black)

  local action = awaitButtonInput()

  if action == "submit" then
    deleteSchedule(trains, i)
  end
end

-- Schedule Config

function drawNameSchedule(output, trains, prevScheduleName)
  local scheduleName = prevScheduleName or "Unnamed"
  local action = nil
  local checkIsValid = function ()
    return utils.findInTable(trains, function (train)
      return train.schedule and train.schedule.name == scheduleName and train.schedule.name ~= prevScheduleName
    end) == nil
  end
  
  local modalBody, awaitButtonInput = createModal(output, prevScheduleName and "Update " .. prevScheduleName or "Create a Schedule", colors.black, colors.white, colors.lightGray, nil, prevScheduleName and "Update" or "Create")

  function readScheduleName()
    local isValid = checkIsValid()

    fillBackground(modalBody, colors.white)
    write(modalBody, "Type a name for the schedule into the terminal", 0, (modalBody.y / 2) - 3, "center", colors.black)
    write(modalBody, "Current Name:", 0, (modalBody.y / 2) + 1, "center", colors.black)
    write(modalBody, scheduleName, 0, (modalBody.y / 2) + 3, "center", colors.black)

    if not isValid then
      write(modalBody, "This name is already taken", 0, (modalBody.y / 2) + 5, "center", colors.red)
    end

    print("Schedule Name: ")
    scheduleName = read()
  end

  while true do
    parallel.waitForAny(readScheduleName, function ()
      action = awaitButtonInput(not checkIsValid())
    end)
    if action then break end;
  end

  return action, scheduleName
end

function drawSelectTrain(output, trains)
  local modalBody, awaitButtonInput = createModal(output, "Which train is this schedule for?", colors.black, colors.white, colors.lightGray, nil, "Continue")

  local action = nil
  local trainName = nil
  local trainIndex = nil
  
  local checkIsValid = function ()
    return trainName ~= nil
  end

  while action == nil do
    fillBackground(modalBody, colors.white)

    local buttons = {}

    for i, train in ipairs(trains) do
      if not train.schedule or utils.tableLength(train.schedule) == 0 then
        table.insert(buttons, function ()
          createButton(modalBody, 0, i * 2, 1, 0, "center", trainName == train.name and colors.green or colors.black, colors.white, train.name, function ()
            trainName = train.name
            trainIndex = i
            return true
          end)
        end)
      end
    end
  
    parallel.waitForAny(function ()
      action = awaitButtonInput(not checkIsValid())
    end, unpack(buttons))
  end

  return action, trainName, trainIndex
end

-- Schedule Utils

function drawRouteTrain(output, stations, scheduleName, trainName, trains, i)
  local route = trains[i].schedule.route or {}
  local action = nil

  while true do
    local entryIndex

    action, entryIndex = drawRoute(output, scheduleName, trainName, route)
    if action == "cancel" then break end

    if action == "add" then
      drawAddRouteEntry(output, stations, route, entryIndex)
    elseif action == "edit" then
      drawEditRouteEntry(output, stations, route, entryIndex)
    elseif action == "delete" then
      drawDeleteRouteEntry(output, route, entryIndex)
    elseif action == "edit-name" then
      scheduleName = drawEditScheduleName(output, trains, scheduleName)
    elseif action == "save" then break end
  end

  return action, route, scheduleName
end

function drawRoute(output, scheduleName, trainName, route)
  local entryIndex = nil
  local action = nil

  function awaitButtonInput(disabled)
    function createCancelButton()
      createButton(output, -10, output.y - 3, 2, 1, "center", colors.black, colors.white, "Cancel", function ()
        action = "cancel"
        return true
      end)
    end
    function createSaveButton()
      createButton(output, 0, output.y - 3, 2, 1, "center", disabled and colors.lightGray or colors.white, colors.black, "Save", function ()
        if disabled then return false end
        action = "save"
        return true
      end)
    end
    function createAddButton()
      createButton(output, 12, output.y - 3, 2, 1, "center", colors.white, colors.black, "Add Stop", function ()
        action = "add"
        return true
      end)
    end
    
    parallel.waitForAny(createCancelButton, createSaveButton, createAddButton)

    return action
  end

  while action == nil do
    local modalBody = createModal(output, "Schedule: "..scheduleName.." for "..trainName, colors.black, colors.white, colors.lightGray, nil, "Continue")

    fillBackground(modalBody, colors.white)

    local buttons = {}

    local length = utils.tableLength(route)
    local noStops = length == 0
    if noStops then
      write(modalBody, "No stops configured, click add stop to do so.", 0, 4, "center", colors.black, colors.white)
    else
      for i, entry in ipairs(route) do
        local y = ((i - 1) * 4) + 2
        local entryDesc = "Stops at "..entry.stationName.." for "..entry.delay.." secs"
        
        table.insert(buttons, function ()
          createButton(modalBody, 0, y, 1, 0, "center", colors.black, colors.white, " + ", function ()
            action = "add"
            entryIndex = i
            return true
          end)
        end)

        write(modalBody, entryDesc, 0, y + 2, "center", colors.black, colors.white)

        table.insert(buttons, function ()
          createButton(modalBody, 1, y + 2, 1, 0, "right", colors.black, colors.white, "-", function ()
            action = "delete"
            entryIndex = i
            return true
          end)
        end)

        table.insert(buttons, function ()
          createButton(modalBody, 5, y + 2, 1, 0, "right", colors.black, colors.white, "Edit", function ()
            action = "edit"
            entryIndex = i
            return true
          end)
        end)

        if i == length then
          write(modalBody, "# Train Terminates #", 0, y + 5, "center", colors.black, colors.white)
        end
      end
    end
    
    table.insert(buttons, function ()
      createButton(modalBody, 2, 2, 1, 0, "left", colors.black, colors.white, "Edit Name", function ()
        action = "edit-name"
        return true
      end)
    end)
  
    parallel.waitForAny(function ()
      entryIndex = nil
      action = awaitButtonInput(length == 0)
    end, unpack(buttons))
  end

  return action, entryIndex
end

-- Edit Schedule Name

function drawEditScheduleName(output, trains, scheduleName)
  local action, scheduleName = drawNameSchedule(output, trains, scheduleName)

  if action == "submit" then
    return scheduleName
  end

  return scheduleName or "Unnamed"
end

-- Add Route Entry

function addRouteEntry(route, stationName, delay, i)
  utils.tableInsertAndShift(route, {
    stationName = stationName,
    delay = delay
  }, i or utils.tableLength(route) + 1)
end

function drawAddRouteEntry(output, stations, route, i)
  local action
  local stationName
  local delay

  action, stationName = drawSelectStation(output, stations)

  if action == "cancel" then return end

  action, delay = drawSelectDelay(output, stationName)

  addRouteEntry(route, stationName, delay, i)
end

-- Edit Route Entry

function editRouteEntry(route, stationName, delay, i)
  route[i] = {
    stationName = stationName,
    delay = delay
  }
end

function drawEditRouteEntry(output, stations, route, i)
  local action
  local stationName
  local delay

  action, stationName = drawSelectStation(output, stations, route[i].stationName)

  if action == "cancel" then return end

  action, delay = drawSelectDelay(output, stationName, route[i].delay)

  editRouteEntry(route, stationName, delay, i)
end

-- Delete Route Entry

function deleteRouteEntry(route, i)
  table.remove(route, i)
end

function drawDeleteRouteEntry(output, route, i)
  local entry = route[i]

  local modalBody, awaitButtonInput = createModal(output, "Delete a Route Entry", colors.black, colors.white, colors.lightGray, nil, "Delete")

  fillBackground(modalBody, colors.white)
  write(modalBody, "Are you sure you want to delete:", 0, (modalBody.y / 2) - 1, "center", colors.black)
  write(modalBody, entry.stationName, 0, (modalBody.y / 2) + 2, "center", colors.black)

  local action = awaitButtonInput()

  if action == "submit" then
    deleteRouteEntry(route, i)
  end
end

-- Route Utils

function drawSelectStation(output, stations, prevStationName)
  local modalBody, awaitButtonInput = createModal(output, "Select a station", colors.black, colors.white, colors.lightGray, nil, "Continue")

  local action = nil
  local stationName = prevStationName or nil
  
  local checkIsValid = function ()
    return stationName ~= nil
  end

  while action == nil do
    fillBackground(modalBody, colors.white)

    local buttons = {}

    for i, station in ipairs(stations) do
      table.insert(buttons, function ()
        createButton(modalBody, 0, i * 2, 1, 0, "center", stationName == station.name and colors.green or colors.black, colors.white, station.name, function ()
          stationName = station.name
          return true
        end)
      end)
    end
  
    parallel.waitForAny(function ()
      action = awaitButtonInput(not checkIsValid())
    end, unpack(buttons))
  end

  return action, stationName
end

function drawSelectDelay(output, stationName, prevDelay)
  local delay = prevDelay or 10
  local action = nil
  local checkIsValid = function ()
    return delay ~= nil
  end
  
  local modalBody, awaitButtonInput = createModal(output, "How long should it stop at "..stationName.."?", colors.black, colors.white, colors.lightGray, nil, "Continue")

  function readDelay()
    local isValid = checkIsValid()

    fillBackground(modalBody, colors.white)
    write(modalBody, "Type a delay in seconds into the terminal", 0, (modalBody.y / 2) - 3, "center", colors.black)
    write(modalBody, "Current Delay:", 0, (modalBody.y / 2) + 1, "center", colors.black)
    write(modalBody, tostring(delay).." seconds", 0, (modalBody.y / 2) + 3, "center", colors.black)

    if not isValid then
      write(modalBody, "You must enter a number", 0, (modalBody.y / 2) + 5, "center", colors.red)
    end

    print("Delay: ")
    delay = tonumber(read())
  end

  while true do
    parallel.waitForAny(readDelay, function ()
      action = awaitButtonInput(not checkIsValid())
    end)
    if action then break end;
  end

  return action, delay
end

return M