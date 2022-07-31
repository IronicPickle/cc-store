
--$ARGS|Channel (10)|Station Name (Unnamed)|$ARGS

-- Args
local args = { ... }
local channel = tonumber(args[1]) or 10
local stationName = args[3] or "Unnamed"

local chest = peripheral.find("minecraft:chest")

-- Libraries
local setup = require("/lua/lib/setupUtils")
local stateHandler = require("/lua/lib/stateHandler")
local network = require("/lua/lib/networkUtils")
local utils = require("/lua/lib/utils")

function main()
  local size = chest.size()

  local stations = {}

  print("Stations:")


  for i = 1, size, 1 do
    local data = chest.getItemDetail(i)

    if(data ~= nil) then
      table.insert(stations, {
        name = data.displayName,
        slot = i
      })
    end;

  end

  for k, station in ipairs(stations) do
    print(station.slot .. " - " .. station.name)
  end

  print("\n# Select a station")
  local selectedSlot = tonumber(read())

  chest.pushItems("bottom", selectedSlot, 1, 1)

  local serialized = textutils.serializeJSON(stations)

  local file = fs.open("./data.json", "w")
  file.write(serialized)
  file.close()


  
end

main()