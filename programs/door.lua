-- Args
local args = { ... }
local delay = tonumber(args[1]) or 15
local openDelay = tonumber(args[2]) or 3
local closeDelay = tonumber(args[3]) or 3
local redstoneOutput = args[4] or "right"
local name = args[5] or "Unnamed"
local channel = tonumber(args[6]) or 20

-- Libraries
local setup = require("/lua/lib/setupUtils")
local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local drawBox = monUtils.drawBox
local stateHandler = require("/lua/lib/stateHandler")

-- Peripherals
local wrappedPers = setup.getPers({
    "monitor", "modem"
})
local monitor = setup.setupMonitor(
    wrappedPers.monitor[1], 0.5
)
local modem = wrappedPers.modem[1]
local speaker = peripheral.find("speaker")

-- Setup
local stateData = stateHandler.getState("door")
local defaultData = "closed"
local state = stateData or defaultData

-- Windows
local winHeader = setup.setupWindow(
    monitor, 1, 1, monitor.x, 4
)
local winFooter = setup.setupWindow(
    monitor, 1, (monitor.y - 3), monitor.x, 4
)
local winMain = setup.setupWindow(
    monitor, 1, 5, monitor.x, (monitor.y - (4 + 4))
)

-- Main
function start()
    print("# Program Started")
    modem.open(channel)
    
    parallel.waitForAll(close, await)
end

function await()
    while(true) do
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        local isTouch = (event == "monitor_touch")
        
        local isModemMessage = (event == "modem_message")
        
        if(isTouch) then
            modem.transmit(channel, channel,
                { type = state }
            )
            if(state == "open") then
                break
            elseif(state == "closed") then
                open()
            end
        elseif(isModemMessage) then
            local body = p4
            if(body.type == "open") then
                break
            elseif(body.type == "closed") then
                open()
            end
        end
    end
end

function open()
    parallel.waitForAny(await,
        function()
            rs.setAnalogOutput(redstoneOutput, 15)
            if(speaker) then
                speaker.playSound(
                    "minecraft:entity.experience_orb.pickup",
                    1, 0.5
                )
            end
            state = "opening"
            updateState()
            drawHeader()
            drawFooter()
            for i = openDelay, 0, -0.1 do
                drawMain(i, openDelay)
                sleep(0.1)
            end
            state = "open"
            updateState()
            drawFooter()
            for i = delay, 0, -0.1 do
                drawHeader(math.floor(i))
                drawMain(i, delay)
                sleep(0.1)
            end
        end
    )
    close()
end

function close()
    rs.setAnalogOutput(redstoneOutput, 0)
    if(speaker) then
        speaker.playSound(
            "minecraft:entity.experience_orb.pickup",
            1, 0.5
        )
    end
    state = "closing"
    updateState()
    drawHeader()
    drawFooter()
    for i = openDelay, 0, -0.1 do
        drawMain(i, openDelay)
        sleep(0.1)
    end
    state = "closed"
    updateState()
    drawHeader()
    drawFooter()
    drawMain()
end

function updateState()
    stateHandler.updateState("door", state)
end

function drawHeader(timeLeft)
    local bgColors = {
        open = colors.green,
        opening = colors.red,
        closed = colors.red,
        closing = colors.green
    }
    winHeader.bg = bgColors[state]
    winHeader.setBackgroundColor(winHeader.bg)
    
    drawBox(winHeader,
        1, 1, winHeader.x, winHeader.y,
        true
    )
    drawBox(winHeader,
        1, winHeader.y, winHeader.x, winHeader.y,
        true, colors.white
    )
    timeLeft = timeLeft or 10
    local msgs = {
        open = "Sealing in: " .. timeLeft,
        opening = "Opening",
        closed = name,
        closing = "Sealing"
    }
    
    write(winHeader, msgs[state], 0, 2, "centre")
end

function drawFooter()
    local bgColors = {
        open = colors.green,
        opening = colors.red,
        closed = colors.red,
        closing = colors.green
    }
    winFooter.bg = bgColors[state]
    winFooter.setBackgroundColor(winFooter.bg)
    
    drawBox(winFooter,
        1, 1, winFooter.x, winFooter.y,
        true
    )
    drawBox(winFooter,
        1, 1, winFooter.x, 1,
        true, colors.white
    )
    
    local msgs = {
        open = "Click to Seal",
        opening = "Please Wait",
        closed = "Click to Open",
        closing = "Please Wait"
    }
    
    write(winFooter,
        msgs[state],
        0, 3, "centre"
    )
end

function drawMain(timeLeft, timeMax)
    local bgColors = {
        open = {colors.green, colors.red},
        opening = {colors.green, colors.red},
        closed = {colors.red, colors.green},
        closing = {colors.red, colors.green}
    }
    winMain.bg = bgColors[state][1]
    winMain.setBackgroundColor(winMain.bg)
    
    drawBox(winMain,
        1, 1, winMain.x, winMain.y,
        true
    )
    
    if(state ~= "closed") then
        local single = monitor.x / timeMax
        local width = timeLeft * single
        
        drawBox(winMain,
            1, 1, width, winMain.y,
            true, bgColors[state][2]
        )
    end
end

setup.utilsWrapper(start, modem, channel)