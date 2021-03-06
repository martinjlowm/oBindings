/**
 * @noSelfInFile
 */

const [, , , interfaceVersion] = GetBuildInfo();

function isClassic(v: number) {
  return 11300 <= v;
}

function isWOTLK(v: number) {
  return 30000 <= v;
}

function isBfA(v: number) {
  return 80000 <= v;
}

const _print = (...args: string[]) => {
  return print('|cff33ff99oBindings:|r', ...args);
};

const printf = (f: string, ...parts: string[]) => {
  return print(f.format(...parts));
}

const states = [
  'alt|[mod:alt]',
  'ctrl|[mod:ctrl]',
  'shift|[mod:shift]',

  'possess|[bonusbar:5]',

  // No bar1 as that's our default anyway.
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
];

// it won't change anyway
const numStates = states.length;

const hasState = (st: string | number) => {
  for (const s of states) {
    const [state, data] = string.split('|', s);
    if (state === st) {
      return data;
    }
  }
}

const [_NAME] = [...FILE_ARGUMENTS];
const _NS = CreateFrame('Frame');
_G[_NAME] = _NS

interface IBindingsSet {
  [keyOrModifier: string]: string | { [key: string]: string }
}

interface IBindings {
  [setName: string]: IBindingsSet;
}
const _BINDINGS: IBindings = {};
const _BUTTONS: any = {};

const _CALLBACKS = [];

const _STATE = CreateFrame('Frame', null, UIParent, 'SecureHandlerStateTemplate');
const _BASE = 'base';

_STATE.Callbacks = (self: any, state: string) => {
  for (const func of _CALLBACKS) {
    func(self, state);
  }
};

_STATE.SetAttribute('_onstate-page', `
  control:ChildUpdate('state-changed', newstate)
  control:CallMethod('Callbacks', newstate)
`)

_NS.RegisterKeyBindings = (_self: typeof _NS, name: string, ...args: Vararg<IBindingsSet>) => {
  const bindings = {}

  for (const i of forRange(1, select('#', ...args))) {
    const [tbl] = select(i, ...args);

    for (const [key, action] of pairs(tbl)) {
      if (typeof action === 'object') {
        for (const [mod, modAction] of pairs(action)) {
          if (!bindings[key]) {
            bindings[key] = {}
          }
          bindings[key][mod] = modAction
        }
      } else {
        bindings[key] = action
      }
    }
  }

  _BINDINGS[name] = bindings
}

_NS.RegisterCallback = (_self: typeof _NS, func: (...args: any[]) => any) => {
  table.insert(_CALLBACKS, func)
}

const createButton = (key: string | number) => {
  if (_BUTTONS[key]) {
    return _BUTTONS[key];
  }

  const btn = CreateFrame("Button", `oBindings${key}`, _STATE, "SecureActionButtonTemplate");

  btn.SetAttribute('_childupdate-state-changed', `
    local type = message and self:GetAttribute('ob-' .. message .. '-type') or self:GetAttribute('ob-base-type')

    -- It's possible to have buttons without a default state.
    if (type) then
      local attr, attrData = strsplit(',', (
        message and self:GetAttribute('ob-' .. message .. '-attribute') or
	self:GetAttribute('ob-base-attribute')
      ), 2)
      self:SetAttribute('type',type)
      self:SetAttribute(attr, attrData)
    end
  `);

  if (typeof key === 'number') {
    btn.SetAttribute('ob-possess-type', 'action');
    btn.SetAttribute('ob-possess-attribute', `action,${(key + 120)}`);
  }

  _BUTTONS[key] = btn;
  return btn;
}

const clearButton = (btn: WoWAPI.Frame) => {
  for (const i of forRange(1, numStates)) {
    let [key] = string.split('|', states[i - 1], 2);
    if (key !== 'possess') {
      btn.SetAttribute('ob-%s-type'.format(key), null);
      key = key == 'macro' ? 'macrotext' : key;
      btn.SetAttribute('ob-%s-attribute'.format(key), null);
    }
  }
}

const typeTable = {
  s: 'spell',
  i: 'item',
  m: 'macro',
};

const bindKey = (key: string | number, action: string, mod?: string | number) => {
  let modKey: string;
  if (mod && (mod === 'alt' || mod === 'ctrl' || mod === 'shift')) {
    modKey = `${mod.toUpperCase()}-${key}`;
  }

  let [ty, act] = string.split('|', action);
  if (!act) {
    SetBinding(modKey || key, ty)
  } else {
    const btn = createButton(key)
    ty = typeTable[ty]

    btn.SetAttribute('ob-%s-type'.format(mod || 'base'), ty)
    ty = ty == 'macro' ? 'macrotext' : ty;

    btn.SetAttribute('ob-%s-attribute'.format(mod || 'base'), `${ty},${act.gsub('\n', '').trim()}`);

    SetBindingClick(modKey || key, btn.GetName())
  }
};

_NS.LoadBindings = (self: typeof _NS, name: string) => {
  const bindings = _BINDINGS[name]

  if (bindings && self.activeBindings !== name) {
    print("Switching to set:", name)
    self.activeBindings = name

    for (const [, btn] of pairs(_BUTTONS)) {
      clearButton(btn);
    }

    for (const [key, action] of pairs(bindings)) {
      if (typeof action !== 'object') {
        bindKey(key, action);
      } else if (hasState(key)) {
        for (const [modKey, nestedAction] of pairs(action)) {
          bindKey(modKey, nestedAction, key);
        }
      }
    }

    let _states = '';
    for (const i of forRange(1, numStates)) {
      const [key, state] = string.split('|', states[i - 1], 2);
      if (bindings[key] || key == 'possess') {
        _states += `${state}${key};`;
      }
    }

    RegisterStateDriver(_STATE, 'page', `${_states}${_BASE}`);

    _STATE.Execute(`
      local state = '%s'
      control:ChildUpdate('state-changed', state)
      control:CallMethod('Callbacks', state)
    `.format(_STATE.GetAttribute('state-page')))
  }
};



_NS.SetScript('OnEvent', function(event: string, ...args: Vararg<any>) {
  return this[event](event, ...args);
});

_NS.ADDON_LOADED = (self: typeof _NS, _event: string, addon: string) => {
  // For the possess madness.
  if (addon === _NAME) {
    for (const i of forRange(0, 9)) {
      createButton(i)
    }

    self.UnregisterEvent('ADDON_LOADED');
    self.ADDON_LOADED = null;
  }
}
_NS.RegisterEvent('ADDON_LOADED');


if (isWOTLK(interfaceVersion) && !isBfA(interfaceVersion)) {
  let talentGroup: string;
  _NS.ACTIVE_TALENT_GROUP_CHANGED = (self: typeof _NS) => {
    if (talentGroup == GetActiveTalentGroup()) {
      return;
    }
    talentGroup = GetActiveTalentGroup();
    self.UPDATE_INSTANCE_INFO();
  }
  _NS.RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
}

if (isBfA(interfaceVersion)) {
  _NS.PLAYER_TALENT_UPDATE = (self: typeof _NS) => {
    const activeSpecialization = GetSpecialization(null, false);
    const numSpecializations = GetNumSpecializations(false, false);

    if (numSpecializations === 0) {
      return;
    }

    const [, name] = GetSpecializationInfo(activeSpecialization);

    self.UnregisterEvent('PLAYER_TALENT_UPDATE');
    if (_BINDINGS[name]) {
      self.LoadBindings(name)
    } else {
      print('Unable to find any bindings.');
    }
  }
  _NS.RegisterEvent('PLAYER_TALENT_UPDATE');
} else if ((isClassic(interfaceVersion) || isWOTLK(interfaceVersion))) {
  _NS.PLAYER_ENTERING_WORLD = (self: typeof _NS) => {
    const numTabs = GetNumTalentTabs();
    let talentString: string;
    let mostPoints = -1;
    let mostPointsName: string;

    if (!numTabs) {
      return
    }

    for (let i = 1; i <= numTabs; i++) {
      const [name, , points] = GetTalentTabInfo(i);
      talentString = `${(talentString && `${talentString}/` || '')}${points}`;

      if (points > mostPoints) {
        mostPoints = points;
        mostPointsName = name;
      }
    }

    self.UnregisterEvent('PLAYER_ENTERING_WORLD');
    if (_BINDINGS[talentString]) {
      self.LoadBindings(talentString);
    } else if (_BINDINGS[mostPointsName]) {
      self.LoadBindings(mostPointsName);
    } else if (next(_BINDINGS)) {
      print('No talents found. Switching to default set.');
      self.LoadBindings(next(_BINDINGS)[0]);
    } else {
      print('Unable to find any bindings.');
    }
  }
  _NS.RegisterEvent('PLAYER_ENTERING_WORLD');
}
