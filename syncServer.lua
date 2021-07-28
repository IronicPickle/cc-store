local ARGS = { ... }

local CHANNEL = tonumber(ARGS[1]) or 40100
local REPO_FULL = ARGS[2]
local GITHUB_ACCESS_TOKEN = ARGS[3]
local DIR = ARGS[4]
local PROGRAM = ARGS[5]
local PROGRAM_ARGS = ARGS[6]

local DEPS = {}

local function printConfig()
    print(" > Configuration")
    print("    - Channel: "..CHANNEL)
    print("    - Full Repo URL: "..REPO_FULL)
    print("    - GitHub Access Token: "..GITHUB_ACCESS_TOKEN)
    print("    - Directory: "..DIR)
    print("    - Program: "..PROGRAM..PROGRAM_ARGS)
end

local function decode64(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
end

local function getFileFromRepo(file)
    local res = http.get(REPO_FULL..file, {
        ["Authorization"] = "token "..GITHUB_ACCESS_TOKEN,
    })
    if res == nil then return nil end
    local body = textutils.unserialiseJSON(res.readAll())
    local content = body["content"]
    res.close()
    
    if content == nil then
        error("Critical error, could not download "..PROGRAM.." from repo!")
    end
    return decode64(content)
end

local function saveFile(content, path)
    local f = fs.open(path, "w")
    f.write(content)
    f.close()
end

local function getAndSave(repo_path, save_path)
    local content = getFileFromRepo(repo_path)
    saveFile(content, save_path)
end

local function getAndSaveServer()
    print("\n > Downloading sync server")
    print("   - Downloading syncServer.lua from repo")
    getAndSave("/syncServer.lua", DIR.."/syncServer.lua")
    print(" - Sync server download successful")
end

local function getAndSaveProgram()
    print("\n > Downloading program")
    print("   - Downloading "..PROGRAM.." from repo")
    getAndSave("/programs/"..PROGRAM, DIR.."/programs/"..PROGRAM)
    print(" - Program download successful")
end

local function getAndSaveDeps()
    print("\n > Downloading dependencies ("..#DEPS..")")
    for _,dep in ipairs(DEPS) do
        print("   - Downloading "..dep.." from repo")
        getAndSave("/lib/"..dep, DIR.."/lib/"..dep)
    end
    print(" - Dependency download successful")
end

local function tableHasValue(tab, value)
    for _,v in ipairs(tab) do
        if v == value then return true end
    end
    return false
end

local function getDeps(path)
    local content = getFileFromRepo(path)

    local matches = content:gmatch('require%(.'..DIR..'/lib/(.-).%)')

    local function insertDep(dep)
        if not tableHasValue(DEPS, dep) then
            table.insert(DEPS, dep)
            return true
        end
        return false
    end

    for str in matches do
        local success = insertDep(str..".lua")
        if success then
            print("   - Found "..str..".lua")
            getDeps("/lib/"..str..".lua")
        else
            print("   - Already found "..str..".lua")
        end
    end
    
    return deps
end

local function getProgramDeps()
    print("\n > Gathering Dependencies")
    DEPS = {}
    getDeps("/programs/"..PROGRAM)
    print(" - Found "..#DEPS.." dependencies")
end

local function isFirstRun()
    return not fs.exists(DIR.."/programs/"..PROGRAM)
end

local function runFirstTimeSetup()
    print("\n > Running first time setup")
    getProgramDeps()
    getAndSaveProgram()
    getAndSaveDeps()
    print("\n > First time setup complete")
end

local function startProgram()
    print("\n <---> Starting Program")
    shell.run(DIR.."/programs/"..PROGRAM..PROGRAM_ARGS);
    print("\n <---> Program Exited")
end

local function startListener()
    print("\n <---> Starting Listener")
    local modem = peripheral.find("modem")
    if modem == nil then error("Could not start listener, no modem present") end
    modem.open(CHANNEL)

    while(true) do
        local event, _, _, _, body = os.pullEvent()

        if event == "modem_message" then
            if body.type == "update" then
                print("\n <---> Recieved update signal")
                local changedPrograms = body.programs
                local changedDeps = body.deps
                local serverChanged = body.server
                local updateAll = body.all;
                getProgramDeps()

                local changes = {}

                if (changedPrograms ~= nil and tableHasValue(changedPrograms, PROGRAM)) or updateAll then
                    getAndSaveProgram()
                    getAndSaveDeps()
                    table.insert(changes, PROGRAM)
                elseif changedDeps ~= nil or updateAll then
                    local relevantDeps = {}
                    for _,dep in ipairs(DEPS) do
                        if tableHasValue(changedDeps, dep) then
                            table.insert(relevantDeps, dep)
                            table.insert(changes, dep)
                        end
                    end

                    if #relevantDeps > 0 then
                        getAndSaveDeps()
                    end
                end

                if #changes > 0 then
                    print("\n <---> Updates downloaded")
                elseif not serverChanged then
                    print("\n <---> No updates required")
                end

                if serverChanged or updateAll then
                    getAndSaveServer()
                    print("\n <---> Server updated, rebooting in 5...")
                    os.sleep(5)
                    os.reboot()
                end
            end
        end
    end
    print("\n <---> Listener Exited")
end

local function startThreads()
    term.clear();
    parallel.waitForAny(startListener, startProgram)
end

local function start()

    print(" > Starting Sync Server")

    if isFirstRun() then
        runFirstTimeSetup()
    end

    startThreads();
    
end

start()