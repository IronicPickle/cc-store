local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local fillBackground = monUtils.fillBackground
local createButton = monUtils.createButton
local createModal = monUtils.createModal
local stateHandler = require("/lua/lib/stateHandler")
local utils = require("/lua/lib/utils")

local M = {}

function M.drawSchedules(output, schedules, trains, stations)
  while true do
    fillBackground(output, colors.black)
    write(output, "Schedules", 0, 3, "center", colors.white)

    local buttons = {}

    for i, schedule in pairs(schedules) do
      local y = i * 2 + 6

      write(output, "<=> " .. schedule.name.." ("..schedule.trainName..")", 3, y, "left", colors.white)

      table.insert(buttons, function ()
        createButton(output, 1, y, 1, 0, "right", colors.white, colors.black, "-", function ()
          drawDeleteSchedule(output, schedule.name, schedules)
          return true
        end)
      end)

      table.insert(buttons, function ()
        createButton(output, 5, y, 1, 0, "right", colors.white, colors.black, "Edit", function ()
          drawCreateSchedule(output, schedules, trains, stations, schedule)
          return true
        end)
      end)
    end

    function createCreateButton()
      createButton(output, 2, 2, 2, 1, "right", colors.white, colors.black, "+", function ()
        drawCreateSchedule(output, schedules, trains, stations)
        return true
      end)
    end

    parallel.waitForAny(createCreateButton, unpack(buttons))
  end
end

function createSchedule(scheduleName, trainName, route, schedules)
  table.insert(schedules, {
    name = scheduleName,
    trainName = trainName,
    route = route
  })
  stateHandler.updateState("schedules", schedules)
end

function drawCreateSchedule(output, schedules, trains, stations, schedule)

  local action = nil
  local scheduleName = schedule and schedule.name or nil
  local trainName = schedule and schedule.trainName or nil
  local route = schedule and schedule.route or nil
  
  if not scheduleName then
    action, scheduleName = drawNameSchedule(output, schedules)
    if action == "cancel" then return end
  end

  if not trainName then
    action, trainName = drawSelectTrain(output, trains)
    if action == "cancel" then return end
  end

  action, route = drawRouteTrain(output, stations, scheduleName, trainName, route)
  if action == "cancel" then return end

  createSchedule(scheduleName, trainName, route, schedules)
end

function drawNameSchedule(output, schedules)
  local scheduleName = "Unnamed"
  local action = nil
  local checkIsValid = function ()
    return utils.findInTable(schedules, function (schedule)
      return schedule.name == scheduleName
    end) == nil
  end
  
  local modalBody, awaitButtonInput = createModal(output, "Create a Schedule", colors.black, colors.white, colors.lightGray, nil, "Create")

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
  
  local checkIsValid = function ()
    return trainName ~= nil
  end

  while action == nil do
    fillBackground(modalBody, colors.white)

    local buttons = {}

    for i, train in ipairs(trains) do
      table.insert(buttons, function ()
        createButton(modalBody, 0, i * 2, 1, 0, "center", trainName == train.name and colors.green or colors.black, colors.white, train.name, function ()
          trainName = train.name
          return true
        end)
      end)
    end
  
    parallel.waitForAny(function ()
      action = awaitButtonInput(not checkIsValid())
    end, unpack(buttons))
  end

  return action, trainName
end

function drawRouteTrain(output, stations, scheduleName, trainName, route)
  local action = nil
  local route = route or {}

  while true do
    local nestedAction
    local stationName
    local delay

    action = drawSchedule(output, scheduleName, trainName, route)
    if action == "cancel" then break end

    if action == "add" then
      nestedAction, stationName = drawSelectStation(output, stations)

      if nestedAction ~= "cancel" then
        nestedAction, delay = drawSelectDelay(output, stationName)

        if nestedAction ~= "cancel" then
          table.insert(route, {
            stationName = stationName,
            delay = delay
          })
        end
      end
    end

    if action == "save" then break end
  end

  return action, route
end

function drawSchedule(output, scheduleName, trainName, route)
  local modalBody = createModal(output, "Schedule: "..scheduleName.." for "..trainName, colors.black, colors.white, colors.lightGray, nil, "Continue")

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
    fillBackground(modalBody, colors.white)

    local length = utils.tableLength(route)
    if length == 0 then
      write(modalBody, "No stops configured, click add stop to do so", 0, 2, "center", colors.black, colors.white)
    else
      for i, entry in ipairs(route) do
        write(modalBody, "Stops at "..entry.stationName.." for "..entry.delay.." secs", 0, ((i - 1) * 4) + 2, "center", colors.black, colors.white)
        write(modalBody, "\\/", 0, ((i - 1) * 4) + 4, "center", colors.black, colors.white)

        if i == length then
          write(modalBody, "# Train Terminates #", 0, ((i - 1) * 4) + 6, "center", colors.black, colors.white)
        end
      end
    end
  
    action = awaitButtonInput(length == 0)
  end

  return action
end

function drawSelectStation(output, stations)
  local modalBody, awaitButtonInput = createModal(output, "Select a station", colors.black, colors.white, colors.lightGray, nil, "Continue")

  local action = nil
  local stationName = nil
  
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

function drawSelectDelay(output, stationName)
  local delay = 10
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

function deleteSchedule(scheduleName, schedules)
  local _, i = utils.findInTable(schedules, function (schedule)
    return schedule.name == scheduleName
  end)
  if i then table.remove(schedules, i) end
  stateHandler.updateState("schedules", schedules)
end

function drawDeleteSchedule(output, scheduleName, schedules)
  local modalBody, awaitButtonInput = createModal(output, "Delete a Schedule", colors.black, colors.white, colors.lightGray, nil, "Delete")

  fillBackground(modalBody, colors.white)
  write(modalBody, "Are you sure you want to delete:", 0, (modalBody.y / 2) - 1, "center", colors.black)
  write(modalBody, scheduleName, 0, (modalBody.y / 2) + 2, "center", colors.black)

  local action = awaitButtonInput()

  if action == "submit" then
    deleteSchedule(scheduleName, schedules)
  end
end

return M