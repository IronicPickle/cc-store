REPO_API = "https://api.github.com"
REPO_PATH = "/repos/IronicPickle/cc-store/contents"
GITHUB_ACCESS_TOKEN = "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"

REPO_FULL = REPO_API..REPO_PATH

PROGRAM = ""
ARGS = ""
DIR = ""
CHANNEL = ""

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
    local content = body.content
    res.close()
    if content == nil then
        return nil
    end
    return decode64(content)
end

local function createRootDir()
    print("  > Creating root directory "..DIR)

    fs.makeDir(DIR)
end

local function getSyncServer()
    print("  > Downloading sync client")

    local content = getFileFromRepo("/syncServer.lua")
    if content == nil then
        error("Critical error, could not download sync client!")
    end

    local f = fs.open(DIR.."/syncServer.lua", "w")
    f.write(content)
    f.close()

end

local function generateStartupScript()
    print("  > Generating startup script")

    local programPath = DIR.."/programs/"..PROGRAM

    local content = DIR..'/syncServer.lua "'..programPath..' '..ARGS..'"'

    local f = fs.open("/startup.lua", "w")
    f.write("")
    f.writeLine("CHANNEL = \""..CHANNEL.."\"")
    f.writeLine("REPO_FULL = \""..REPO_FULL.."\"")
    f.writeLine("GITHUB_ACCESS_TOKEN = \""..GITHUB_ACCESS_TOKEN.."\"")
    f.writeLine("DIR = \""..DIR.."\"")
    f.writeLine("PROGRAM = \""..PROGRAM.."\"")
    f.writeLine("ARGS = \""..ARGS.."\"")
    f.writeLine("")
    f.writeLine("shell.run(DIR..'/syncServer.lua '..CHANNEL..' '..REPO_FULL..' '..GITHUB_ACCESS_TOKEN..' '..DIR..' '..PROGRAM..' '..'\"'..ARGS..'\"')")
    f.close()
end

local function install()
    term.clear()
    print("\n> Running install")
    createRootDir()
    getSyncServer()
    generateStartupScript()
    print("\n> Install complete")

    print("\nRun /startup.lua to start")
end

local function checkRepoReachable()
    print("  > Checking repo is reachable")

    if not http.checkURL(REPO_API) then
        error("Repo URL not whitelisted")
    end

    if getFileFromRepo("/README.md") == nil then
        error("Repo doesn't exist")
    end

    print("  < Repo successfully reached")
end

local function checkRepoContainsSyncServer()
    print("  > Checking repo for syncServer.lua")

    if getFileFromRepo("/syncServer.lua") == nil then
        error("Sync Server doesn't exist on repo")
    end

    print("  < syncServer.lua found in repo")
end

local function splitArgs(content)
    local argsString = content:match("$ARGS(.-)$ARGS")
    if argsString == nil then return {} end
    local matches = string.gmatch(argsString, "([^|]+)")
    local args = {}
    for str in matches do
        table.insert(args, str)
    end
    return args
end

local function readInput(prefix)
    if prefix == nil then prefix = " ->" end
    print(prefix)
    _, height = term.getSize()
    term.setCursorPos(#prefix + 2, height - 1)
    local input = read()
    print("")
    return input
end

local function readArgs(args)
    local readArgsString = ""
    for _,str in pairs(args) do
        print("  | "..str)
        readArgsString = readArgsString.." "..readInput("  | ->")
    end
    return readArgsString
end

local function checkRepoContainsProgram()
    print("  > Checking repo for "..PROGRAM)

    local content = getFileFromRepo("/programs/"..PROGRAM)

    if content == nil then
        error("Program doesn't exist on repo")
    end

    print("  < Found "..PROGRAM.." in repo")

    return content
end


local function setup()
    term.clear()
    print("> Script Configuration")
    print("  - Repo API: "..REPO_API)
    print("  - Repo Path: "..REPO_PATH)
    checkRepoReachable()
    checkRepoContainsSyncServer()

    print("\n> Further Configuration Required")
    print("  - Program Name [name] (do not include .lua)")
    PROGRAM = readInput()..".lua"
    local argsTable = splitArgs(checkRepoContainsProgram())
    if #argsTable > 0 then
        print("  - Program Arguments\n")
        ARGS = readArgs(argsTable)
    else
        print("  - No program arguments found, skipping...\n")
    end
    print("  - Root Directory (/lua)")
    DIR = readInput()
    if #DIR == 0 then DIR = "/lua" end
    print("  - Sync Server Channel (40100)")
    CHANNEL = readInput()
    if #CHANNEL == 0 then  CHANNEL = "40100" end
    
    term.clear()

    print("\n> Configuration")
    print("  - Program: "..PROGRAM..ARGS)
    print("  - Root Directory: "..DIR)
    print("  - Sync Server Channel: "..CHANNEL)

    print("\nPress any key to run install")
    read()

    install()
end

setup()