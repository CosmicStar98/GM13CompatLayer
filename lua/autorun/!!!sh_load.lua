-- borrowed from gmod tower
module( "DirLoader", package.seeall )

DEBUG = true

local function ValidName( name )
    return name ~= "." and name ~= ".." and name ~= ".svn"
end

function Include( File, name )

    local filename = File
    if name then filename = name end

    local Suffix = string.sub( filename, 0, 3 )
    local Type = "server"

    if Suffix == "cl_" then
        if SERVER then
            AddCSLuaFile( File )
        else
            include( File )
        end

        Type = "client"
    elseif Suffix == "sh_" or File == "shared.lua" then

        if SERVER then
            AddCSLuaFile( File )
        end

        include( File )

        Type = "shared"
    elseif SERVER then
        include( File )
    end

    if DEBUG then
        Msg("\t " .. File .. " \t type: " .. Type .. "\n")
    end

end

function SelectiveInclude( dir, name )
    local File = dir .. name
    Include( File, name )
end

function LoadFolder( dir, order )

    local LoadDir = dir .. "/"
    local FileList = file.FindInLua( LoadDir .. "*" )

    if !FileList then return end

    if DEBUG then
        Msg("Loading " .. LoadDir .. " (" .. #FileList .. ")\n")
    end

    local loaded = {}

    if order then
        for _, name in ipairs(order) do
            SelectiveInclude(LoadDir, name)
            loaded[name] = true
        end
    end

    for _, name in pairs(FileList) do
        if ValidName(name) and !loaded[name] then
            SelectiveInclude(LoadDir, name)
        end
    end

end

local function LoadModules()
    LoadFolder("libs")
    LoadFolder( "ext", {"sh_misc.lua", "sh_typecheck.lua"} )
end

LoadModules()