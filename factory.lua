local parent = 'oBindings'
local oBindings = oBindings
local Private = oBindings.Private

local argcheck = Private.argcheck

local _QUEUE = {}
local _FACTORY = CreateFrame('Frame')
_FACTORY:SetScript('OnEvent', function(...)
                       return this[event](this, event, unpack(arg))
end)

_FACTORY:RegisterEvent('PLAYER_LOGIN')
_FACTORY.active = true

function _FACTORY:PLAYER_LOGIN()
    if(not self.active) then return end

    for _, func in next, _QUEUE do
        func(oBindings)
    end

    -- Avoid creating dupes.
    wipe(_QUEUE)
end

function oBindings:Factory(func)
    argcheck(func, 2, 'function')

    -- Call the function directly if we're active and logged in.
    if IsLoggedIn() and _FACTORY.active then
        return func(self)
    else
        table.insert(_QUEUE, func)
    end
end

function oBindings:EnableFactory()
    _FACTORY.active = true
end

function oBindings:DisableFactory()
    _FACTORY.active = nil
end

function oBindings:RunFactoryQueue()
    _FACTORY:PLAYER_LOGIN()
end
