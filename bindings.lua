local print = function(...)
    return ChatFrame1:AddMessage(
        string.format('|cff33ff99oBindings:|r %s', string.join(' ', unpack(arg))))
end

local printf = function(f, ...)
    return ChatFrame1:AddMessage(print(string.format(f, unpack(arg))))
end

local states = {
    'alt|[mod:alt]',
    'ctrl|[mod:ctrl]',
    'shift|[mod:shift]',

    -- No bar1 as that's our default anyway.
    'bar2|[bar:2]',
    'bar3|[bar:3]',
    'bar4|[bar:4]',
    'bar5|[bar:5]',
    'bar6|[bar:6]',

    'stealth|[bonusbar:1,stealth]',
    'shadowDance|[form:3]',

    'shadow|[bonusbar:1]',

    'bear|[form:1]',
    'cat|[form:3]',
    'moonkintree|[form:5]',

    'battle|[stance:1]',
    'defensive|[stance:2]',
    'berserker|[stance:3]',

    'demon|[form:2]',
}
-- it won't change anyway~
local numStates = select('#', unpack(states))

local hasState = function(st)
    for i = 1, numStates do
        local state, data = string.split('|', states[i], 2)
        if (state == st) then
            return data
        end
    end
end

local oBindings = oBindings
local _G = getfenv(0)

local _BINDINGS = {}
local _BUTTONS = {}

local _CALLBACKS = {}

local _STATE = CreateFrame('Frame', nil, UIParent)
_STATE:RegisterEvent('MODIFIER_STATE_CHANGED')
_STATE:RegisterEvent('ACTIONBAR_PAGE_CHANGED')
_STATE:RegisterEvent('PLAYER_AURAS_CHANGED')
local _BASE = 'base'

function _STATE:Callbacks(state)
    for _, func in next, _CALLBACKS do
        func(self, state)
    end
end

local function onState(frame, state_id, new_state)
    frame:ChildUpdate('state-changed', new_state)
    -- Callbacks(new_state)
end
_STATE:SetAttribute('_onstate-page', onState)

function oBindings:RegisterKeyBindings(name, ...)
    local bindings = {}

    for i = 1, select('#', unpack(arg)) do
        local tbl = select(i, unpack(arg))
        for key, action in next, tbl do
            if(type(action) == 'table') then
                for mod, modAction in next, action do
                    if(not bindings[key]) then
                        bindings[key] = {}
                    end

                    bindings[key][mod] = modAction
                end
            else
                bindings[key] = action
            end
        end
    end

    _BINDINGS[name] = bindings
end

function oBindings:RegisterCallback(func)
    table.insert(_CALLBACKS, func)
end

local button_id = 1
local createButton = function(key)
    if _BUTTONS[key] then
        return _BUTTONS[key]
    end

    local btn = CreateFrame('Button', 'oBindings' .. button_id, _STATE,
                            'ActionButtonTemplate')
    local function stateChanged(self, message)
        local type =
            message and self:GetAttribute('ob-' .. message .. '-type') or
            self:GetAttribute('ob-base-type')

        if type then
            local attribute =
                message and self:GetAttribute('ob-' .. message .. '-attribute') or
                self:GetAttribute('ob-base-attribute')
            local attr_state, attr_data = string.split(',', attribute, 2)

            self:SetAttribute('type', type)
            self:SetAttribute(attr_state, attr_data)
        end
    end
    btn:SetAttribute('_childupdate-state-changed', stateChanged)

    if tonumber(key) then
        btn:SetAttribute('ob-possess-type', 'action')
        btn:SetAttribute('ob-possess-attribute', 'action,' .. (key + 120))
    end

    button_id = button_id + 1

    _BUTTONS[key] = btn
    return btn
end

local clearButton = function(btn)
    for i = 1, numStates do
        local key = string.split('|', states[i], 2)
        if (key ~= 'possess') then
            btn:SetAttribute(string.format('ob-%s-type', key), nil)
            key = (key == 'macro' and 'macrotext') or key
            btn:SetAttribute(string.format('ob-%s-attribute', key), nil)
        end
    end
end

local typeTable = {
    a = 'assign',
    f = 'func',
    i = 'item',
    m = 'macro',
    p = 'pet',
    s = 'spell',
}

local bindKey = function(key, action, mod)
    local modKey
    if (mod and (mod == 'alt' or mod == 'ctrl' or mod == 'shift')) then
        modKey = string.upper(mod .. '-' .. key)
    end

    local ty, action = string.split('|', action)
    if (not action) then
        SetBinding(modKey or key, ty)
    else
        local btn = createButton(key)
        ty = typeTable[ty]

        btn:SetAttribute(string.format('ob-%s-type', mod or 'base'), ty)
        ty = (ty == 'macro' and 'macrotext') or ty
        btn:SetAttribute(string.format('ob-%s-attribute', mod or 'base'),
                         ty .. ',' .. action)
        SetBinding(modKey or key, string.upper(btn:GetName()))
    end
end

function oBindings:LoadBindings(name)
    local bindings = _BINDINGS[name]

    if bindings and self.activeBindings ~= name then
        print('Switching to set:', name)
        self.activeBindings = name
        for _, btn in next, _BUTTONS do
            clearButton(btn)
        end

        for key, action in next, bindings do
            if type(action) ~= 'table' then
                bindKey(key, action)
            elseif hasState(key) then
                for modKey, action in next, action do
                    bindKey(modKey, action, key)
                end
            end
        end

        local _states = ''
        for i = 1, numStates do
            local key, state = string.split('|', states[i], 2)
            if bindings[key] or key == 'possess' then
                _states = _states .. state .. key .. ';'
            end
        end

        RegisterStateDriver(_STATE, 'page', _states .. _BASE)
        local state = _STATE:GetAttribute('state-page')
        _STATE:ChildUpdate('state-changed', state)
        -- Callbacks(state)
    end
end

oBindings:SetScript('OnEvent', function(...)
                  return this[event](this, event, unpack(arg))
end)

local talentGroup
function oBindings:UPDATE_INSTANCE_INFO()
    local numTabs = GetNumTalentTabs()
    local talentString
    local mostPoints = -1
    local mostPointsName

    if numTabs == 0 then
        return
    end

    for i = 1, numTabs do
        local name, _, points = GetTalentTabInfo(i)
        talentString = (talentString and talentString .. '/' or '') .. points

        if points > mostPoints then
            mostPoints = points
            mostPointsName = name
        end
    end

    self:UnregisterEvent('UPDATE_INSTANCE_INFO')
    if _BINDINGS[talentString] then
        self:LoadBindings(talentString)
    elseif _BINDINGS[mostPointsName] then
        self:LoadBindings(mostPointsName)
    elseif next(_BINDINGS) then
        print('No talents found. Switching to default set.')
        self:LoadBindings(next(_BINDINGS))
    else
        print('Unable to find any bindings.')
    end
end
oBindings:RegisterEvent('UPDATE_INSTANCE_INFO')

function oBindings:ACTIVE_TALENT_GROUP_CHANGED()
    if talentGroup == GetActiveTalentGroup() then return end

    talentGroup = GetActiveTalentGroup()
    self:UPDATE_INSTANCE_INFO()
end
oBindings:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
