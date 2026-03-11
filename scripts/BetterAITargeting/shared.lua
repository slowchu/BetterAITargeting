local types = require('openmw.types')

local M = {}

M.MOD_ID = 'BetterAITargeting'
M.RUNTIME_SECTION = 'BetterAITargeting_Runtime'
M.SETTINGS_SECTION = 'SettingsGlobalBetterAITargeting'

M.EVENTS = {
    REGISTER_DEFENDER = 'BetterAITargeting_RegisterDefender',
    UNREGISTER_DEFENDER = 'BetterAITargeting_UnregisterDefender',
}

M.DEFAULTS = {
    enabled = true,
    pulseSeconds = 0.35,
    scanRadius = 2000,
    useLineOfSight = false,
    retargetCooldownSeconds = 2.0,
    debugLogging = false,
}

local function isActor(obj)
    return types.Actor.objectIsInstance(obj)
end

local function isAliveActor(obj)
    if not obj or not obj:isValid() or not isActor(obj) then
        return false
    end
    return not types.Actor.isDead(obj)
end

local function distanceSq(a, b)
    return (a.position - b.position):length2()
end

function M.readSetting(section, key)
    local value = section:get(key)
    if value == nil then
        return M.DEFAULTS[key]
    end
    return value
end

function M.log(enabled, tag, message)
    if not enabled then
        return
    end
    print(('[%s][%s] %s'):format(M.MOD_ID, tag, message))
end

M.isActor = isActor
M.isAliveActor = isAliveActor
M.distanceSq = distanceSq

return M
