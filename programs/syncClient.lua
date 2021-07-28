--$ARGS|Sync Server Channel|$ARGS

-- Args
local ARGS = { ... }
local CHANNEL = tonumber(ARGS[1]) or 40100

local PROGRAMS = {"program.lua"}
local DEPS = {"dep.lua"}

local function printSettings()
    print(" > Settings")
    print(" - Programs")
    for _,program in ipairs(PROGRAMS) do
        print("  - "..program)
    end
    print(" - Dependencies")
    for _,dep in ipairs(DEPS) do
        print("  - "..dep)
    end
end

local function startInterface()
    local modem = peripheral.find("modem")
    if modem == nil then error("Could not start client, no modem present") end
    modem.open(CHANNEL)

    printSettings()

    read()

end

local function start()

    print(" > Starting Sync Client")

    startInterface();
  
end

start()