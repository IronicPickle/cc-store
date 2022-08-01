local utils = require("/lua/lib/utils")
local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local fillBackground = monUtils.fillBackground

local M = {}

function M.drawStations(output, stations, channel)
  fillBackground(output, colors.black)

  local noStations = utils.tableLength(stations) == 0
  if noStations then
    write(output, "No stations found on network, connect one to view it.", 0, 7, "center", colors.white, colors.black)
    if channel then write(output, "Listening on channel: " .. channel, 0, 9, "center", colors.white, colors.black) end
  else
    for i, station in pairs(stations) do
      write(output, "<#> " .. station.name, 3, i * 2 + 1, "left", colors.white)
    end
  end
end

return M