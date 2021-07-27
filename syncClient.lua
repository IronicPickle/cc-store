local ARGS = { ... };

local REPO_FULL = ARGS[1];
local GITHUB_ACCESS_TOKEN = ARGS[2];
local PROGRAM = ARGS[3];
local PROGRAM_ARGS = ARGS[4];
local DIR = ARGS[5];
local PORT = ARGS[6];

print(textutils.serialize(args))