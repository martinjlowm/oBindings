local Private = oBindings.Private

function Private.argcheck(value, num, ...)
    assert(type(num) == 'number', "Bad argument #2 to 'argcheck' (number expected, got "..type(num)..")")

    for i = 1, select('#', unpack(arg)) do
        if type(value) == select(i, unpack(arg)) then return end
    end

    local types = strjoin(', ', unpack(arg))
    local name = string.match(debugstack(2,2,0), ": in function [`<](.-)['>]")
    error(string.format("Bad argument #%d to '%s' (%s expected, got %s", num, name, types, type(value)), 3)
end

function Private.print(...)
    ChatFrame1:AddMessage(string.format("|cff33ff99oBindings:|r %s", unpack(arg)))
end

function Private.error(...)
    Private.print("|cffff0000Error:|r "..string.format(unpack(arg)))
end
