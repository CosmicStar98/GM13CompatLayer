local ENTITY = FindMetaTable("Entity")

-- these are currently unused but exist for parody with gm13 scripts
rawset(_G, "CHAN_REPLACE",    -1) --Used when playing sounds through console commands.
rawset(_G, "CHAN_AUTO",        0) -- Automatic channel
rawset(_G, "CHAN_WEAPON",      1) -- Channel for weapon sounds
rawset(_G, "CHAN_VOICE",       2) -- Channel for NPC voices
rawset(_G, "CHAN_ITEM",        3) -- Channel for items (Health kits, etc.)
rawset(_G, "CHAN_BODY",        4) -- Clothing, ragdoll impacts, footsteps, knocking/pounding/punching etc.
rawset(_G, "CHAN_STREAM",      5) -- Stream channel from the static or dynamic area
rawset(_G, "CHAN_STATIC",      6) -- A constant/background sound that doesn't require any reaction. ---> This channel allows same sounds files to play multiple times without cutting out.
rawset(_G, "CHAN_VOICE2",      7) -- TF2s Announcer dialogue channel
rawset(_G, "CHAN_VOICE_BASE",  8) -- Channels 8-135 (128 channels) are allocated for player voice chat. ---> This channel allows same sounds files to play multiple times without cutting out.
rawset(_G, "CHAN_USER_BASE", 136) -- Channels from this and onwards are allocated to game code

local soundScripts = {}
local scriptNames = {}
local activePatches = {} -- CSoundPatch objects are garbage collected if no reference is held.

-- TODO: replace this jank with bass 2.4 https://www.un4seen.com/bass.html

sound = sound or {}

--- Ensure a sound-file value is always stored as a flat array of strings.
local function normaliseSounds( v )
    if type(v) == "string" then
        return v ~= "" and {v} or {}
    elseif type(v) == "table" then
        local out = {}
        for i = 1, #v do
            local s = v[i]
            if type(s) == "string" and s ~= "" then
                out[#out + 1] = s
            end
        end
        return out
    end
    return {}
end

local function deepcopy( v )
    if type(v) ~= "table" then return v end

    local out = {}
    for k, w in pairs(v) do
        out[k] = (type(w) == "table") and deepcopy(w) or w
    end

    return out
end

-- Sample a concrete number from a pitch / volume field.
local function sampleField( field, default )
    if type(field) == "number" then
        return field
    elseif type(field) == "table" then
        local lo = tonumber(field[1]) or (default or 0)
        local hi = tonumber(field[2]) or lo

        if lo == hi then return lo end
        -- Use integer math.random for pitch (integer range);
        -- fall back to float lerp for volume (float range).
        if math.floor(lo) == lo and math.floor(hi) == hi then
            return math.random(math.floor(lo), math.floor(hi))
        else
            return lo + math.random() * (hi - lo)
        end
    end

    return default or 0
end

local function prunePatches()
    for i = #activePatches, 1, -1 do
        if !activePatches[i]:IsPlaying() then
            table.remove(activePatches, i)
        end
    end
end


function sound.Add( soundData )
    if type(soundData) ~= "table" then
        error("bad argument #1 to 'sound.Add' (table expected, got " .. type(soundData) .. ")", 2)
    end

    local name = soundData.name
    if type(name) ~= "string" or name == "" then
        error("sound.Add: field 'name' must be a non-empty string", 2)
    end

    local entry = {
        name    = name,
        channel = soundData.channel ~= nil and soundData.channel or CHAN_AUTO,
        volume  = soundData.volume  ~= nil and soundData.volume  or 1.0,
        level   = tonumber(soundData.level) or 75,
        pitch   = soundData.pitch   ~= nil and soundData.pitch   or 100,
        sound   = normaliseSounds(soundData.sound),
        _rawSound = soundData.sound,
    }

    local key = string.lower(name)

    -- track name for GetTable (avoid duplicates on re-registration)
    if !soundScripts[key] then
        scriptNames[#scriptNames + 1] = name
    end

    soundScripts[key] = entry
end

function sound.GetTable()
    local out = {}
    for i = 1, #scriptNames do
        out[i] = scriptNames[i]
    end

    return out
end

function sound.GetProperties( name )
    if type(name) ~= "string" then return nil end

    local entry = soundScripts[string.lower(name)]
    if !entry then return nil end

    local out = {
        name    = entry.name,
        channel = entry.channel,
        level   = entry.level,
        volume  = deepcopy(entry.volume),
        pitch   = deepcopy(entry.pitch),
        -- Return sound in the same form the caller originally supplied.
        -- If _rawSound was a string, return a string; if a table, a copy.
        sound   = deepcopy(entry._rawSound ~= nil and entry._rawSound
                           or (#entry.sound == 1 and entry.sound[1]
                              or entry.sound)),
    }
    return out
end

-- Wraps EmitSound so that Lua-registered sound script names are resolved.
local entSnd = ENTITY.EmitSound
function ENTITY.EmitSound(self, soundName, soundLevel, pitchPercent, volume, channel, soundFlags, dsp, filter) -- channel, flags, dsp & filter are accepted but silently ignored
    local s = soundScripts[string.lower(soundName)]

    if s and type(s) == "table" and #s.sound > 0 then
        prunePatches()

        local sounds = s.sound
        local patch  = CreateSound(self, sounds[#sounds > 1 and math.random(#sounds) or 1])

        patch:SetSoundLevel(soundLevel or s.level)
        patch:PlayEx(
            sampleField(s.volume, 1.0),
            pitchPercent or sampleField(s.pitch, 100)
        )

        activePatches[#activePatches + 1] = patch
        return
    end

    return entSnd(self, soundName, soundLevel, pitchPercent) -- fallback to regular EmitSound when not inside a soundscript
end

local emitters = {
    [0] = function(sound, pos, ent, lvl, pitch) -- World
        return WorldSound(sound, pos or Entity(0):GetPos(), lvl, pitch)
    end,
    [-1] = function(sound, _, _, lvl, pitch) -- LocalPlayer()
        return LocalPlayer():EmitSound(sound, lvl, pitch)
    end,
    [-2] = function(sound) -- UI
        return surface.PlaySound(sound)
    end
}
function _G.EmitSound(soundName, position, entity, channel, volume, soundLevel, soundFlags, pitch, dsp, filter) -- channel, flags, dsp & filter are accepted but silently ignored
    local s = soundScripts[string.lower(soundName)]

    local etypes = {0, -1, -2}
    local entType = etypes[entity]
    local emitter = emitters[entType]

    if type(entity) ~= "number" then entity = nil end
    if SERVER and entType < 0 then entType = 0 end

    local snd = soundName
    local lvl = soundLevel
    local ptch = pitch

    if s and type(s) == "string" and #s.sound > 0 then
        local sounds = s.sound
        local snd = sounds[#sounds > 1 and math.random(#sounds) or 1]
        local lvl = soundLevel or s.level
        local ptch = pitch or sampleField(s.pitch, 100)
    end

    if emitter then
        return emitter(sound, position, entity, lvl, ptch)
    end

    return entity:EmitSound( snd, lvl, ptch )
end