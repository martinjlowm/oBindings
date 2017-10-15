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

local _G = getfenv(0)
local _NAME = 'oBindings'
local _NS = CreateFrame('Frame')
_G[_NAME] = _NS

local _BINDINGS = {}
local _BUTTONS = {}

local _CALLBACKS = {}

local _STATE = CreateFrame('Frame', nil, UIParent)
_STATE:RegisterEvent('MODIFIER_STATE_CHANGED')
_STATE:RegisterEvent('ACTIONBAR_PAGE_CHANGED')
_STATE:RegisterEvent('PLAYER_AURAS_CHANGED')
local _BASE = 'base'

_G.IsStealthed = function()
    local buff, name = 1
    repeat
        name = UnitAura('player', buff, 'HELPFUL')

        if name == 'Stealth' or name == 'Prowl' then
            return true
        end

        buff = buff + 1
    until not name

    return false
end

local state
local function UpdateState(self, event, arg1)
    if IsStealthed() then
        state = 'stealth'
    end

    if event == 'MODIFIER_STATE_CHANGED' then
        state = arg1 and string.lower(arg1)
    elseif event == 'ACTIONBAR_PAGE_CHANGED' then
        state = 'bar' .. CURRENT_ACTIONBAR_PAGE
    end

    state = state or 'base'

    for _, btn in next, _BUTTONS do
        btn:StateChanged(state)
    end
end

do
    local shift, control, alt
    local propagate
    local modifier
    local function OnUpdate()
        if not shift and IsShiftKeyDown() then
            shift = true
            modifier = 'SHIFT'
            propagate = true
        elseif shift and not IsShiftKeyDown() then
            shift = false
            propagate = true
        elseif not control and IsControlKeyDown() then
            control = true
            modifier = 'CTRL'
            propagate = true
        elseif control and not IsControlKeyDown() then
            control = false
            propagate = true
        elseif not alt and IsAltKeyDown() then
            alt = true
            modifier = 'ALT'
            propagate = true
        elseif alt and not IsAltKeyDown() then
            alt = false
            propagate = true
        else
            modifier = nil
        end

        if propagate then
            propagate = false
            UpdateState(this, 'MODIFIER_STATE_CHANGED', modifier)
        end
    end

    _STATE:SetScript('OnEvent', function(...) UpdateState(this, event, arg1) end)
    _STATE:SetScript('OnUpdate', OnUpdate)
end

local function StateChanged(self, state)
    local state_type = state and self['ob-' .. state .. '-type'] or self['ob-base-type']

    if state_type then
        local attr, attrData = string.split(
            ',',
            state and self['ob-' .. state .. '-attribute'] or self['ob-base-attribute'], 2)

        self.type = state_type
        self.attr = attrData
    end
end


function _NS:RegisterKeyBindings(name, ...)
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

function _NS:RegisterCallback(func)
    table.insert(_CALLBACKS, func)
end

local function OnClick()
    if this.type == 'spell' then
        CastSpellByName(this.attr)
    elseif this.type == 'macro' then
        local command = string.match(this.attr, "/([^%s]+)")
        local msg = strsub(this.attr, strlen(command) + 3)
        if command == 'petattack' then
            PetAttack()
        elseif command == 'petfollow' then
            PetFollow()
        else
            gxMacroConditions:ParseCommand(command, msg)
        end
    end
end

local button_id = 1
local createButton = function(key)
    if _BUTTONS[key] then
        return _BUTTONS[key]
    end

    local btn = CreateFrame('Button', 'oBindings' .. button_id, _STATE,
                            'ActionButtonTemplate')
    btn.StateChanged = StateChanged
    btn:SetScript('OnClick', OnClick)

    button_id = button_id + 1

    _BUTTONS[key] = btn
    return btn
end

local clearButton = function(btn)
    for i = 1, numStates do
        local key = string.split('|', states[i], 2)
        if (key ~= 'possess') then
            btn[string.format('ob-%s-type', key)] = nil
            key = (key == 'macro' and 'macrotext') or key
            btn[string.format('ob-%s-attribute', key)] = nil
        end
    end
end

local typeTable = {
    s = 'spell',
    i = 'item',
    m = 'macro',
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

        btn[string.format('ob-%s-type', mod or 'base')] = ty
        ty = (ty == 'macro' and 'macrotext') or ty
        btn[string.format('ob-%s-attribute', mod or 'base')] = ty .. ',' .. action
        SetBinding(modKey or key, string.upper(btn:GetName()))
    end
end

function _NS:LoadBindings(name)
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
    end

    UpdateState(_STATE)
end

_NS:SetScript('OnEvent', function(...)
                  return this[event](this, event, unpack(arg))
end)

local talentGroup
function _NS:UPDATE_INSTANCE_INFO()
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
_NS:RegisterEvent('UPDATE_INSTANCE_INFO')

function _NS:ACTIVE_TALENT_GROUP_CHANGED()
    if talentGroup == GetActiveTalentGroup() then return end

    talentGroup = GetActiveTalentGroup()
    self:UPDATE_INSTANCE_INFO()
end
_NS:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
