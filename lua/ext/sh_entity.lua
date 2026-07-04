local ENTITY = FindMetaTable("Entity")

-- Returns the center of the entity according to its collision model.
function ENTITY:WorldSpaceCenter()
    local mins = self:OBBMins()
    local maxs = self:OBBMaxs()

    local center = (mins + maxs) * 0.5

    return self:LocalToWorld(center)
end

-- Sets the SpawnFlags to set of an Entity
function ENTITY:SetSpawnFlags( flags )
    self:SetKeyValue( "spawnflags", flags )
end

-- Adds onto the current SpawnFlags of an Entity.
function ENTITY:AddSpawnFlags( flags )
    self:SetKeyValue( "spawnflags", bit.bor( self:GetSpawnFlags(), flags ) )
end

-- Removes a SpawnFlag from the current SpawnFlags of an Entity.
function ENTITY:RemoveSpawnFlags( flags )
    self:SetKeyValue( "spawnflags", bit.band( self:GetSpawnFlags(), bit.bnot( flags ) ) )
end

-- Checks if the entity plays a sound when picked up by a player.
function ENTITY:GetShouldPlayPickupSound()
    return self.m_bPlayPickupSound or false
end

-- Sets whether or not the entity should make a physics contact sound when it's been picked up by a player.
function ENTITY:SetShouldPlayPickupSound( bPlaySound )
    self.m_bPlayPickupSound = tobool( bPlaySound ) or false
end

-- Returns ids of child bones of given bone.
function ENTITY:GetChildBones( bone )

    local bonecount = self:GetBoneCount()
    if ( bonecount == 0 or bonecount < bone ) then return end

    local bones = {}

    for k = 0, bonecount - 1 do
        if ( self:GetBoneParent( k ) ~= bone ) then continue end
        table.insert( bones, k )
    end

    return bones

end

if ( SERVER ) then
    -- Sets the creator of this entity.
    function ENTITY:SetCreator( ply )
        if ( ply == nil ) then
            ply = NULL
        elseif ( !IsEntity( ply ) ) then
            error( "bad argument #1 to 'SetCreator' (Entity expected, got " .. type( ply ) .. ")", 2 )
        end

        self.m_PlayerCreator = ply
    end

    -- Gets the creator of the SENT.
    function ENTITY:GetCreator()
        return self.m_PlayerCreator or NULL
    end

end