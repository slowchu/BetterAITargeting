local storage = require('openmw.storage')
local shared = require('scripts.BetterAITargeting.shared')

local runtime = storage.globalSection(shared.RUNTIME_SECTION)
runtime:setLifeTime(storage.LIFE_TIME.Temporary)

local function ensureRegistry()
    if runtime:get('defenders') == nil then
        runtime:set('defenders', {})
    end
end

local function setDefenderFlag(defenderId, isRegistered)
    if type(defenderId) ~= 'string' or defenderId == '' then
        return
    end

    ensureRegistry()
    local copy = runtime:getCopy('defenders')
    copy[defenderId] = isRegistered or nil
    runtime:set('defenders', copy)
end

local function registerDefender(data)
    setDefenderFlag(data and data.id, true)
end

local function unregisterDefender(data)
    setDefenderFlag(data and data.id, false)
end

return {
    engineHandlers = {
        onInit = ensureRegistry,
    },
    eventHandlers = {
        [shared.EVENTS.REGISTER_DEFENDER] = registerDefender,
        [shared.EVENTS.UNREGISTER_DEFENDER] = unregisterDefender,
    },
}
