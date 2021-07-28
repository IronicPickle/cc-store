--$ARGS|Sync Server Channel|$ARGS

-- Args
local ARGS = { ... }
local CHANNEL = tonumber(ARGS[1]) or 40100

local PROGRAMS = {}
local DEPS = {}

local MODES = { "Programs", "Dependencies", "Update Servers", "Update All" }
local MODE = 1

local function printSettings()
    print(" > Sync Client Settings")
    if MODE == 1 then
        print(" - Programs")
        for _,program in ipairs(PROGRAMS) do
            print("   | "..program)
        end
        if #PROGRAMS == 0 then print("   | N/A") end
    elseif MODE == 2 then
        print(" - Dependencies")
        for _,dep in ipairs(DEPS) do

            print("   | "..dep)
        end
        if #DEPS == 0 then print("   | N/A") end
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

local function printInfo()
    print(" > Controls: Tab - Switch | Up - Send")
    print(" > Mode: "..MODES[MODE].."\n")
end

local function printPrompt()
    if MODE == 1 or MODE == 2 then
        print(" > Send to update "..MODES[MODE])
        print(" > Input list of "..MODES[MODE].." (comma seperated)")
    elseif MODE == 3 then
        print(" > Send to update all Sync Servers")
    elseif MODE == 4 then
        print(" > Send to perform a system wide update")
    end

    print("\n ->")
    _, y = term.getCursorPos()
    term.setCursorPos(4, y - 1)
end

local function printAll()
    term.clear()
    _, y = term.getSize()
    term.setCursorPos(1, y)
    printBreak()
    printSettings()
    printInfo()
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
    if MODE == 1 then
        data["programs"] = PROGRAMS
    elseif MODE == 2 then
        data["deps"] = DEPS
    end

    data["type"] = "update"

    modem.transmit(CHANNEL, CHANNEL, data)
    printAll()
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
        local input = read()

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
            if key == 258 then -- Tab
                nextMode()
            elseif key == 265 then -- Up Arrow
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