local ARGS = { ... };

local CHANNEL = ARGS[1];
local REPO_FULL = ARGS[2];
local GITHUB_ACCESS_TOKEN = ARGS[3];
local DIR = ARGS[4];
local PROGRAM = ARGS[5];
local PROGRAM_ARGS = ARGS[6];

print(CHANNEL)
print(REPO_FULL)
print(GITHUB_ACCESS_TOKEN)
print(DIR)
print(PROGRAM)
print(PROGRAM_ARGS)

local function printConfig()
    print(" > Configuration");
    print("    - Channel: "..CHANNEL);
    print("    - Full Repo URL: "..REPO_FULL);
    print("    - GitHub Access Token: "..GITHUB_ACCESS_TOKEN);
    print("    - Directory: "..DIR);
    print("    - Program: "..PROGRAM..PROGRAM_ARGS);
    print("");
end;

local function start()

    print(" > Starting Sync Client...\n");
    printConfig();
    
end;

start();