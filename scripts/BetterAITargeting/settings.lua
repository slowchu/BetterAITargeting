local I = require('openmw.interfaces')

local Settings = I.Settings
if type(Settings) ~= 'table' or type(Settings.registerGroup) ~= 'function' then
    print('[BetterAITargeting][SETTINGS] Settings interface is unavailable in this context; skipping settings registration')
    return {}
end

local pageKey = 'BetterAITargeting'
if type(Settings.registerPage) == 'function' then
    Settings.registerPage {
        key = pageKey,
        l10n = 'BetterAITargeting',
        name = 'pageName',
        description = 'pageDescription',
    }
else
    print('[BetterAITargeting][SETTINGS] Settings.registerPage is unavailable; registering group without custom page')
    pageKey = nil
end

local group = {
    key = 'SettingsGlobalBetterAITargeting',
    l10n = 'BetterAITargeting',
    name = 'groupName',
    permanentStorage = false,
    settings = {
        {
            key = 'enabled',
            name = 'settingEnabled',
            default = true,
            renderer = 'checkbox',
        },
        {
            key = 'pulseSeconds',
            name = 'settingPulseSeconds',
            default = 0.35,
            renderer = 'number',
            argument = { min = 0.1, max = 2.0 },
        },
        {
            key = 'scanRadius',
            name = 'settingScanRadius',
            default = 2000,
            renderer = 'number',
            argument = { min = 300, max = 6000 },
        },
        {
            key = 'useLineOfSight',
            name = 'settingUseLineOfSight',
            default = false,
            renderer = 'checkbox',
        },
        {
            key = 'retargetCooldownSeconds',
            name = 'settingRetargetCooldownSeconds',
            default = 2.0,
            renderer = 'number',
            argument = { min = 0.1, max = 10.0 },
        },
        {
            key = 'debugLogging',
            name = 'settingDebugLogging',
            default = false,
            renderer = 'checkbox',
        },
    },
}

if pageKey then
    group.page = pageKey
end

Settings.registerGroup(group)

return {}
