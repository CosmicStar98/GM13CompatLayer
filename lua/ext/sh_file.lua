local file = file
local type = type
local pairs = pairs
local ipairs = ipairs
local assert = assert
local string = string
local include = include
local tostring = tostring
local AddCSLuaFile = AddCSLuaFile

-- TODO: add fileio by discord/@cookie_cakes

function file.ExistsInLua( filepath )
    if !filepath or filepath == "" then
        return false
    end

    local name    = string.GetFileFromFilename( filepath )
    local results = file.FindInLua( filepath )

    if !results then return false end

    for _, found in pairs( results ) do
        if found == name then
            return true
        end
    end

    return false
end