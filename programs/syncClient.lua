--$ARGS|Sync Server Channel|$ARGS

-- Args
local ARGS = { ... }
local CHANNEL = tonumber(ARGS[1]) or 40100

local PROGRAMS = { "program.lua" }
local DEPS = { "dep.lua" }

local MODES = { "Programs", "Deps", "Server", "All" }
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
    if MODE == 1 or MODE == 2 then
        print(" - Programs")
        for _,program in ipairs(PROGRAMS) do
            print("   - "..program)
        end
        print("")
        print(" - Dependencies")
        for _,dep in ipairs(DEPS) do

            print("   - "..dep)
        end
    else
        print(" - N/A")
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
    print("\n > Mode: "..MODES[MODE].."\n")
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
    printAll()
end

local function sendUpdate(modem)
    local data = {
        server = MODE == 3,
        all = MODE == 4,
    }
    if MODE == 1 or MODE == 2 then
        data["programs"] = PROGRAMS
        data["deps"] = DEPS
    end

    data["type"] = "update"

    print(data)

    modem.transmit(CHANNEL, CHANNEL, data)
    --printAll()
end

local function startInputReader()

    local function parseFileNames(inputStr)
        local tab = {}
        for str in string.gmatch(inputStr, "([^,]+)") do
            table.insert(tab, str..".lua")
        end
        return tab
    end

    while true do
        printAll()
        local input = readInput()

        if MODE == 1 then
            PROGRAMS = parseFileNames(input)
        elseif MODE == 2 then
            DEPS = parseFileNames(input)
        end
    end

end

local function startEventReader()
    local modem = peripheral.find("modem")
    if modem == nil then error("Could not start client, no modem present") end
    modem.open(CHANNEL)

    while true do
        local event, key = os.pullEvent()

        if event == "key_up" then
            print(key)
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