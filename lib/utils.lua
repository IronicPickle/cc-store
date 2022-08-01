local M = {}

function M.tableLength(tab)
  local count = 0
  for _ in pairs(tab) do count = count + 1 end
  return count
end

function M.tableHasValue(tab, value)
  for _,v in ipairs(tab) do
      if v == value then return true end
  end
  return false
end

function M.concatTables(tab1, tab2)
  for i=1, #tab2 do
    tab1[#tab1+1] = tab2[i]
  end
  return tab1
end

function M.filterTable(tab, func)
  local newTab = {}
  for i=1, #tab do
    if func(tab[i], newTab) then
      newTab[#newTab+1] = tab[i]
    end
  end
  return newTab
end

function M.mapTable(tab, func)
  local newTab = {}
  for i=1, #tab do
    newTab[#newTab+1] = func(tab[i], newTab)
  end
  return newTab
end

function M.findInTable(tab, func)
  for i=1, #tab do
    if func(tab[i]) then
      return tab[i], i
    end
  end
  return nil
end


function M.urlEncode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w ])", function(char) return string.format("%%%02X", string.byte(char)) end)
  url = url:gsub(" ", "+")
  return url
end

function M.urlDecode(url)
  if url == nil then
    return
  end
  url = url:gsub("+", " ")
  url = url:gsub("%%(%x%x)", function(char) return string.char(tonumber(char, 16)) end)
  return url
end

function M.capitalize(text)
  return text:gsub("^%l", string.upper)
end

function M.tableInsertAndShift(tab, newEntry, insertIndex)
  local length = M.tableLength(tab)
  if insertIndex == length + 1 or length == 0 then
    table.insert(tab, newEntry)
  else
    local shiftedEntry

    for i in ipairs({table.unpack(tab)}) do
      if i == insertIndex then
        local entry = tab[i]
        tab[i] = newEntry
        shiftedEntry = entry
      elseif shiftedEntry then
        local entry = tab[i]
        tab[i] = shiftedEntry
        shiftedEntry = entry
      end
    end

    if shiftedEntry then table.insert(tab, shiftedEntry) end
  end

  return tab
end

return M