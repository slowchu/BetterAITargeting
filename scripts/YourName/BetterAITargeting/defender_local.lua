local self = require('openmw.self')
local nearby = require('openmw.nearby')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local shared = require('scripts.YourName.BetterAITargeting.shared')

local AI = I.AI

local settingsSection = storage.globalSection(shared.SETTINGS_SECTION)

local elapsed = 0
local isRegistered = false

local function isTargetingPlayer(pkg, player)
    return pkg and pkg.target and player and pkg.target == player
end

local function shouldClassifyAsDefender(player)
    local active = AI.getActivePackage()
    if active and (active.type == 'Follow' or active.type == 'Escort') and isTargetingPlayer(active, player) then
        return true, 'active ' .. active.type .. ' targeting player'
    end

    local found = false
    local why = ''
    AI.forEachPackage(function(pkg)
        if found then
            return
        end
        if pkg and pkg.sideWithTarget and isTargetingPlayer(pkg, player) then
            found = true
            why = ('package %s with sideWithTarget=true targeting player'):format(pkg.type)
        end
    end)

    if found then
        return true, why
    end

    return false, 'no conservative helper package signal'
end

local function sendRegistrationEvent(shouldRegister, debugLogging)
    if shouldRegister == isRegistered then
        return
    end

    local eventName = shouldRegister and shared.EVENTS.REGISTER_DEFENDER or shared.EVENTS.UNREGISTER_DEFENDER
    core.sendGlobalEvent(eventName, { id = self.id })

    isRegistered = shouldRegister
    shared.log(debugLogging, 'DEFENDER', ('%s %s'):format(shouldRegister and 'registered' or 'unregistered', self.id))
end

local function pulseClassification()
    local enabled = shared.readSetting(settingsSection, 'enabled')
    local debugLogging = shared.readSetting(settingsSection, 'debugLogging')

    if not enabled or not shared.isAliveActor(self) then
        sendRegistrationEvent(false, debugLogging)
        return
    end

    local player = nearby.players[1]
    if not player then
        sendRegistrationEvent(false, debugLogging)
        shared.log(debugLogging, 'DEFENDER', 'no nearby player object available')
        return
    end

    local shouldRegister, reason = shouldClassifyAsDefender(player)
    shared.log(debugLogging, 'DEFENDER', ('classification for %s: %s'):format(self.id, reason))
    sendRegistrationEvent(shouldRegister, debugLogging)
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            elapsed = elapsed + dt
            local pulseSeconds = shared.readSetting(settingsSection, 'pulseSeconds')
            if elapsed < pulseSeconds then
                return
            end
            elapsed = 0
            pulseClassification()
        end,
        onInactive = function()
            core.sendGlobalEvent(shared.EVENTS.UNREGISTER_DEFENDER, { id = self.id })
            isRegistered = false
        end,
    },
}
