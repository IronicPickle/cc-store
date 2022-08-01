local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local fillBackground = monUtils.fillBackground
local createButton = monUtils.createButton
local createModal = monUtils.createModal
local stateHandler = require("/lua/lib/stateHandler")
local utils = require("/lua/lib/utils")

local M = {}

function M.drawTrains(output, trains)
  while true do
    fillBackground(output, colors.black)
    write(output, "Trains", 0, 3, "center", colors.white)

    local buttons = {}

    local noTrains = utils.tableLength(trains) == 0
    if noTrains then
      write(output, "No trains found, click the plus to add one.", 0, 7, "center", colors.white, colors.black)
    else
      for i, train in pairs(trains) do
        local y = i * 2 + 6

        write(output, "<=> " .. train.name, 3, y, "left", colors.white)

        table.insert(buttons, function ()
          createButton(output, 1, y, 1, 0, "right", colors.white, colors.black, "-", function ()
            drawDeleteTrain(output, trains, i)
            return true
          end)
        end)

        table.insert(buttons, function ()
          createButton(output, 5, y, 1, 0, "right", colors.white, colors.black, "Edit", function ()
            drawEditTrain(output, trains, i)
            return true
          end)
        end)
      end
    end

    function createCreateButton()
      createButton(output, 2, 2, 2, 1, "right", colors.white, colors.black, "+", function ()
        drawCreateTrain(output, trains)
        return true
      end)
    end

    parallel.waitForAny(createCreateButton, unpack(buttons))
  end
end

-- Create Train

function createTrain(trainName, trains)
  table.insert(trains, {
    name = trainName,
    schedule = {}
  })
  stateHandler.updateState("trains", trains)
end

function drawCreateTrain(output, trains)
  local action, trainName = drawNameTrain(output, trains)

  if action == "submit" then
    createTrain(trainName, trains)
  end
end

-- Edit Train

function editTrain(trainName, trains, i)
  trains[i].name = trainName
  stateHandler.updateState("trains", trains)
end

function drawEditTrain(output, trains, i)
  local action, trainName = drawNameTrain(output, trains, trains[i].name)

  if action == "submit" then
    editTrain(trainName, trains, i)
  end
end

-- Delete Train

function deleteTrain(i, trains)
  if i then table.remove(trains, i) end
  stateHandler.updateState("trains", trains)
end

function drawDeleteTrain(output, trains, i)
  local modalBody, awaitButtonInput = createModal(output, "Delete a Train", colors.black, colors.white, colors.lightGray, nil, "Delete")

  fillBackground(modalBody, colors.white)
  write(modalBody, "Are you sure you want to delete:", 0, (modalBody.y / 2) - 1, "center", colors.black)
  write(modalBody, trains[i].name, 0, (modalBody.y / 2) + 2, "center", colors.black)

  local action = awaitButtonInput()

  if action == "submit" then
    deleteTrain(i, trains)
  end
end

-- Train Utils

function drawNameTrain(output, trains, prevTrainName)
  local trainName = prevTrainName or "Unnamed"
  local action = nil

  local checkIsValid = function ()
    return utils.findInTable(trains, function (train)
      return train.name == trainName and train.name ~= prevTrainName
    end) == nil
  end
  
  local modalBody, awaitButtonInput = createModal(output, prevTrainName and "Update "..prevTrainName or "Create a Train", colors.black, colors.white, colors.lightGray, nil, prevTrainName and "Update" or "Create")

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

  return action, trainName
end

return M