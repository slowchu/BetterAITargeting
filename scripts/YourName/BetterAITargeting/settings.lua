local I = require('openmw.interfaces')

I.Settings.registerPage {
    key = 'BetterAITargeting',
    l10n = 'BetterAITargeting',
    name = 'pageName',
    description = 'pageDescription',
}

I.Settings.registerGroup {
    key = 'BetterAITargetingMain',
    page = 'BetterAITargeting',
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

return {}
