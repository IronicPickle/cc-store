--$ARGS|Sync Server Channel|$ARGS

-- Args
local ARGS = { ... }
local CHANNEL = tonumber(ARGS[1]) or 40100

local PROGRAMS = {}
local DEPS = {}

local MODES = { "Programs", "Deps", "Update Servers", "Update All" }
local MODE = 1

local function printBreak()
    local width = term.getSize()
    local breakStr = ""
    for i = 1, width - 2, 1 do
        breakStr = breakStr.."-"
    end
    print(" "..breakStr.." ")
end

local function printInfo()
    term.setCursorPos(1, 1)
    printBreak()
    term.setCursorPos(1, 2)
    print(" > Tab: Switch | Up: Send")
    term.setCursorPos(1, 3)
    print(" > Mode: "..MODES[MODE].."\n")
end

local function printSettings()
    print(" > Sync Client Settings")

    local _,height = term.getSize()
    local remainingHeight = height - 15
    print(height, remainingHeight)

    local function printFiles(files)
        for i,file in ipairs(files) do
            if i > remainingHeight - 1 and #files > remainingHeight then break end
            print("   | "..file)
        end
        if #files > remainingHeight then 
            print("   | ... ("..tonumber(#files - remainingHeight - 1)..")")
        end
        if #files == 0 then print("   | N/A") end
    end

    if MODE == 1 then
        print(" - Programs")
        printFiles(PROGRAMS)
    elseif MODE == 2 then
        print(" - Dependencies")
        printFiles(DEPS)
    else
        print(" - N/A")
    end
    print("")
end

local function printPrompt()
    if MODE == 1 or MODE == 2 then
        print(" > Updates "..MODES[MODE])
        print(" > Input list of "..MODES[MODE])
    elseif MODE == 3 then
        print(" > Updates all servers")
    elseif MODE == 4 then
        print(" > System-wide update")
    end

    print("\n ->")
    _, y = term.getCursorPos()
    term.setCursorPos(4, y - 1)
end

local function printAll()
    term.clear()
    _, height = term.getSize()
    term.setCursorPos(1, height)
    printBreak()
    printSettings()
    printBreak()
    printPrompt()
    printInfo()
    term.setCursorPos(5, height - 1)
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