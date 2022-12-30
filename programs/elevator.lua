--$ARGS|Channel (10)|Floor Number (1)|Floor Name (Unnamed)|Destination Redstone Output (right)|Direction Redstone Output (left)|Moving Redstone Output (front)|Is Host (false)|$ARGS


-- Libraries
local setup = require("/lua/lib/setupUtils")
local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local drawBox = monUtils.drawBox
local stateHandler = require("/lua/lib/stateHandler")
local network = require("/lua/lib/networkUtils")
local utils = require("/lua/lib/utils")

-- Args
local args = { ... }
local channel = tonumber(args[1]) or 10
local floorNum = tonumber(args[2]) or 1
local floorName = utils.urlDecode(args[3] or "Unnamed")
local destinationRedstoneOutput = args[4] or "right"
local directionRedstoneOutput = args[5] or "left"
local movingRedstoneOutput = args[6] or "front"
local isHost = args[7] == "true"

-- Peripherals
local wrappedPers = setup.getPers({
    "monitor",
    "modem"
})
local monitor = setup.setupMonitor(
    wrappedPers.monitor[1], 0.5
)
local modem = wrappedPers.modem[1]
local speaker = peripheral.find("speaker")

-- Setup
local floors = {}
local moving = false
local direction = 0

local stateData = stateHandler.getState("elevator")
local defaultData = 1
local currentFloorIndex = stateData or defaultData

-- Windows
local winHeader = setup.setupWindow(
    monitor, 1, 1, monitor.x, 6
)
local winFooter = setup.setupWindow(
    monitor, 1, (monitor.y - 3), monitor.x, 4
)
local winMain = setup.setupWindow(
    monitor, 1, 7, monitor.x, (monitor.y - (6 + 4)) 
)

-- Main
function start()
    print("# Program Started")
    
    local deviceData = {
        floorNum = floorNum,
        floorName = floorName
    }

    floor = { deviceData }

    local joinOrCreate = function()
        network.joinOrCreate(channel, isHost, deviceData,
            function(devices)
                floors = utils.filterTable(devices, function(device, newDevices)
                    for _,newDevice in ipairs(newDevices) do
                        if newDevice.floorNum == device.floorNum then return false end
                    end
                    return true
                end)
                table.sort(floors,
                    function(a, b) return a.floorNum > b.floorNum end
                )
                drawHeader()
                drawFooter()
                drawMain()
            end
        )
    end

    parallel.waitForAny(joinOrCreate, await)
end

function await()
    while(true) do
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        local isTouch = (event == "monitor_touch")
        
        local isModemMessage = (event == "modem_message")
        
        if(isTouch) then
            local x = p2
            local y = p3 - winHeader.y
            
            local floorIndex = y - 4
            local floor = floors[floorIndex]
            if(floor and (floorIndex) ~= currentFloorIndex) then
                modem.transmit(channel, channel,
                    {
                         type = "floorChange",
                         floorIndex = floorIndex   
                    }
                )
                moveTo(floorIndex)
                break
            end
        elseif(isModemMessage) then
            local body = p4
            if(body.type == "floorChange") then
                moveTo(body.floorIndex)
                break
            end
        end
    end
end

function moveTo(floorIndex)
    local floor = floors[floorIndex]
    direction = currentFloorIndex - floorIndex 
    currentFloorIndex = floorIndex
    moving = true
    updateState()
    
    if(speaker) then
        speaker.playSound(
            "minecraft:entity.experience_orb.pickup",
            1, 0.5
        )
    end
    
    sendSignal(floor.floorNum)
    
    drawMain()
    
    sendSignal(floor.floorNum)
    
    if(speaker) then
        speaker.playSound(
            "minecraft:entity.player.levelup",
            1, 0.5
        )
    end
    
    await()
end

function sendSignal(targetFloorNum)
    redstone.setOutput(
        destinationRedstoneOutput, floorNum ~= targetFloorNum
    )
    redstone.setOutput(
        directionRedstoneOutput, direction < 0
    )
    redstone.setOutput(
        movingRedstoneOutput, moving
    )
    
end

function updateState()
    stateHandler.updateState("elevator", currentFloorIndex)
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
    
    write(winHeader, "Elevator", 0, 2, "center")
    write(winHeader, "This Floor: " .. floorName, 0, 4, "center")
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
    
    write(winFooter, "Select a floor", 2, 3, "left")
    write(winFooter, "Channel: " .. channel, 2, 3, "right" )
end

function drawMain()
    winMain.bg = colors.cyan
    winMain.setBackgroundColor(winMain.bg)
    
    drawBox(winMain,
        1, 1, winMain.x, winMain.y,
        true
    )
    
    if(moving) then
        parallel.waitForAny(
            drawMoving, awaitFinish,
            function() sleep(120) end
        )
        moving = false
        drawMain()
    else
        drawFloors()
    end
end

function drawMoving()
    local i = 1
    local max = winMain.y - 4
    while(true) do
        i = i + 1
        if(i > max) then i = 1 end
        
        local dirStr = "\\/"
        if(direction > 0) then
            dirStr = "/\\"
        end
        
        winMain.clear()
        local floor = floors[currentFloorIndex]
        
        write(winMain,
            "Moving to: " .. floor.floorName,
            0, 2, "center"
        )
        
        for ii = 1, 5, 1 do
            local y = i + ii - 1
            if(y > max) then y = y % max end
            if(direction > 0) then
                y = (y - max - 1) * -1
            end
            
            write(winMain,
                dirStr,
                0, (y + 3), "center"
            )
        end
        
        os.sleep(0.1)
    end
end

function awaitFinish()
    sleep(1)
    while(true) do
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        local isRedstone = (event == "redstone")
        
        local isModemMessage = (event == "modem_message")
        
        if(isRedstone) then
            modem.transmit(channel, channel,
                {
                    type = "floorChanged"
                }
            )
            return
        elseif(isModemMessage) then
            local body = p4
            if(body.type == "floorChanged") then
                return
            end
        end
        
    end
end
    
function drawFloors()
    if(currentFloorIndex > #floors) then 
        currentFloorIndex = 1
    end
    write(winMain,
        "Floor: " .. floors[currentFloorIndex].floorName,
        2, 2, "right"
    )
    write(winMain,
        "# Floors",
        2, 2, "left"
    )
    
    for i, floor in ipairs(floors) do
        local y = 4 + i
        if(i == currentFloorIndex) then
            drawBox(winMain,
                1, y, winMain.x, y,
                true, colors.blue
            )
            winMain.setBackgroundColor(colors.blue)
        end
        write(winMain,
            " > " .. floor.floorName .. " ",
            2, y, "left"
        )
        winMain.setBackgroundColor(winMain.bg)
    end
end

setup.utilsWrapper(start, modem, channel)