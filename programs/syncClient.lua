--$ARGS|Sync Server Channel|$ARGS

-- Args
local ARGS = { ... }
local CHANNEL = tonumber(ARGS[1]) or 40100

local PROGRAMS = {"program.lua"}
local DEPS = {"dep.lua"}
local UPDATE_SERVER = false
local UPDATE_ALL = false

local MODES = { "Programs", "Deps", "All", "Server" }
local MODE = 1

local function readInput(prefix)
    if prefix == nil then prefix = " ->" end
    print(prefix)
    _, y = term.getCursorPos()
    term.setCursorPos(#prefix + 2, y - 1)
    local input = read()
    print("")
    return input
end

local function printSettings()
    print(" > Sync Client Settings\n")
    print(" - Programs")
    for _,program in ipairs(PROGRAMS) do
        print("   - "..program)
    end
    print("")
    print(" - Dependencies")
    for _,dep in ipairs(DEPS) do

        print("   - "..dep)
    end
    print("")
end

local function printBreak()
    local width = term.getSize()
    local breakStr = ""
    for i = 1, width - 2, 1 do
        breakStr = breakStr.."-"
    end
    print(" "..breakStr.." ")
end

local function printPrompt()
    print("\n > Controls - Tab: Switch | Up Arrow: Send")
    print("\n > Mode: "..MODES[MODE])
    printBreak()

end

local function printAll()
    term.clear()
    _, y = term.getSize()
    term.setCursorPos(1, y)
    printSettings()
    printBreak()
    printPrompt()
end

local function nextMode()
    MODE = MODE + 1
    if MODE > #MODES then MODE = 1 end
end

local function sendUpdate(modem)
    modem.transmit(CHANNEL, CHANNEL, {
        type = "update",
        {
            programs = PROGRAMS,
            deps = DEPS,
            server = UPDATE_SERVER,
            all = UPDATE_ALL
        }
    })
end


local function startInputReader()

    while true do
        printAll()

        readInput()
    end

end

local function startEventReader()
    local modem = peripheral.find("modem")
    if modem == nil then error("Could not start client, no modem present") end
    modem.open(CHANNEL)

    while true do
        printAll()

        local event, key = os.pullEvent()

        if event == "key_up" then
            if key == 258 then -- Tab
                nextMode()
            elseif key == 259 then -- Up Arrow
                sendUpdate(modem)
            end
        end

    end

end

local function startThreads()
    parallel.waitForAny(startInputReader, startEventReader)
end

local function start()

    print(" > Starting Sync Client")

    startThreads();
  
end

start()