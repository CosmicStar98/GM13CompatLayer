if CLIENT then

    local bf_read = FindMetaTable( "bf_read" )

    if !bf_read then
        Msg( "Unable to get bf_read meta table.\n" )
        return
    end


    function bf_read:ReadColor()

        local r = self:ReadChar() + 128
        local g = self:ReadChar() + 128
        local b = self:ReadChar() + 128
        local a = self:ReadChar() + 128

        return Color( r, g, b, a )
    end

    function bf_read:ReadUInt()
        local value = self:ReadLong()
        local bits  = self:ReadChar()

        if bits < 1 or bits > 32 then
            error("Invalid bit count received")
        end

        local max = bit.lshift(1, bits) - 1
        return bit.band(value, max)
    end

    require("glon")

    local Receiving = {}

    function bf_read:ReadTable()

        local id = self:ReadShort()
        local index = self:ReadShort()
        local total = self:ReadShort()

        local chunk = self:ReadString()

        local data = Receiving[id]

        if !data then
            data = {
                total = total,
                chunks = {}
            }

            Receiving[id] = data
        end

        data.chunks[index] = chunk

        -- not finished yet
        for i = 1, total do
            if !data.chunks[i] then
                return nil
            end
        end

        local encoded = table.concat(data.chunks)

        Receiving[id] = nil

        return glon.decode(encoded)
    end
end

if SERVER then

    function umsg.Color( clr )

        if DEBUG then
            Msg( "umsg sending color.\n" )
            Msg( "pre-serialization: ( ", clr.r, ", ", clr.g, ", ", clr.b, ", ", clr.a, " )\n" )
        end

        local r = math.Clamp( math.floor( clr.r ), 0, 255 ) - 128
        local g = math.Clamp( math.floor( clr.g ), 0, 255 ) - 128
        local b = math.Clamp( math.floor( clr.b ), 0, 255 ) - 128
        local a = math.Clamp( math.floor( clr.a ), 0, 255 ) - 128

        if DEBUG then
            Msg( "post-serialization: ( ", r, ", ", g, ", ", b, ", ", a, " )\n" )
        end

        umsg.Char( r )
        umsg.Char( g )
        umsg.Char( b )
        umsg.Char( a )

    end

    function umsg.UInt(value, bits)
        if bits < 1 or bits > 32 then error("bits must be 1-32") end
        if value < 0 then error("UInt cannot be negative") end

        local max = bit.lshift(1, bits) - 1
        if value > max then error("value too large for bit count") end

        umsg.Long(value)
        umsg.Char(bits)
    end

    --[[
        Usage:

         Correct:
         umsg.Table("PlayerData", ply, tbl)

         Bad:
         umsg.Start("PlayerData", ply)
         umsg.Table(tbl)
         umsg.End()
        
        This is because in order to support large tables, the data must be split into several chunks and the only way to do that is if umsg.Table handles everything, including the actual sending of the umsg
    ]]
    require("glon")

    local MESSAGE_SIZE = 220
    local TransferID = 0

    function umsg.Table(name, recipient, tbl)
        TransferID = TransferID + 1

        local encoded = glon.encode(tbl)
        local total = math.ceil(#encoded / MESSAGE_SIZE)

        for i = 1, total do
            umsg.Start(name, recipient)

                umsg.Short(TransferID)
                umsg.Short(i)
                umsg.Short(total)

                umsg.String(encoded:sub(
                    (i - 1) * MESSAGE_SIZE + 1,
                    i * MESSAGE_SIZE
                ))

            umsg.End()
        end
    end

end