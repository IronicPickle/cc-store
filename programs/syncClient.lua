--$ARGS|Sync Server Channel|$ARGS

-- Args
local ARGS = { ... }
local CHANNEL = tonumber(ARGS[1]) or 40100

local PROGRAMS = {"program.lua"}
local DEPS = {"dep.lua"}

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
    print(" > Controls")
end

local function printAll()
    term.clear()
    _, y = term.getSize()
    term.setCursorPos(0, y)
    printSettings()
    printBreak()
    printPrompt()
end

local function startInputReader()
    local modem = peripheral.find("modem")
    if modem == nil then error("Could not start client, no modem present") end
    modem.open(CHANNEL)

    while true do
        printAll()

        readInput()
    end

end

local function startEventReader()

    while true do
        printAll()

        local event, key = os.pullEvent()

        if event == "key_up" then
            print(key)
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