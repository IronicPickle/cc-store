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