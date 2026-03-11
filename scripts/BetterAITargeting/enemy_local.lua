local self = require('openmw.self')
local nearby = require('openmw.nearby')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local shared = require('scripts.BetterAITargeting.shared')

local AI = I.AI

local settingsSection = storage.globalSection(shared.SETTINGS_SECTION)
local runtimeSection = storage.globalSection(shared.RUNTIME_SECTION)

local elapsed = 0
local cooldown = 0

local function clearCombatPackages(debugLogging)
    shared.log(debugLogging, 'TARGET', 'normalizing Combat packages via AI.removePackages("Combat")')
    AI.removePackages('Combat')
end

local function hasClearLineOfSight(candidate)
    local result = nearby.castRay(self.position, candidate.position, {
        ignore = self,
        radius = 0,
    })

    if not result.hit then
        return true
    end

    return result.hitObject == candidate
end

local function chooseBestDefender(defenderSet, scanRadius, useLineOfSight, debugLogging)
    local best = nil
    local bestDistanceSq = scanRadius * scanRadius
    local defenderCount = 0

    for _, actor in ipairs(nearby.actors) do
        if actor ~= self and shared.isAliveActor(actor) and defenderSet[actor.id] then
            defenderCount = defenderCount + 1
            local d2 = shared.distanceSq(self, actor)
            if d2 <= bestDistanceSq then
                local losOk = true
                if useLineOfSight then
                    losOk = hasClearLineOfSight(actor)
                    if not losOk then
                        shared.log(debugLogging, 'TARGET', ('LOS rejected %s'):format(actor.id))
                    end
                end

                if losOk then
                    best = actor
                    bestDistanceSq = d2
                end
            end
        end
    end

    return best, bestDistanceSq, defenderCount
end

local function pulseRetarget()
    local enabled = shared.readSetting(settingsSection, 'enabled')
    local debugLogging = shared.readSetting(settingsSection, 'debugLogging')

    if not enabled or not shared.isAliveActor(self) then
        return
    end

    local activeTarget = AI.getActiveTarget('Combat')
    if not activeTarget then
        shared.log(debugLogging, 'TARGET', 'skip: no active Combat target')
        return
    end

    local player = nearby.players[1]
    if not player then
        shared.log(debugLogging, 'TARGET', 'skip: no nearby player object')
        return
    end

    if activeTarget ~= player then
        shared.log(debugLogging, 'TARGET', ('skip: combat target is %s (not player)'):format(activeTarget.id))
        return
    end

    local defenderSet = runtimeSection:get('defenders') or {}
    local scanRadius = shared.readSetting(settingsSection, 'scanRadius')
    local useLineOfSight = shared.readSetting(settingsSection, 'useLineOfSight')

    local best, bestDistanceSq, defenderCount = chooseBestDefender(defenderSet, scanRadius, useLineOfSight, debugLogging)
    shared.log(debugLogging, 'TARGET', ('active target=player, nearby registered defenders=%d'):format(defenderCount))

    if not best then
        shared.log(debugLogging, 'TARGET', 'skip: no valid defender in range')
        return
    end

    if activeTarget == best then
        shared.log(debugLogging, 'TARGET', ('skip: already targeting selected defender %s'):format(best.id))
        return
    end

    shared.log(debugLogging, 'TARGET', ('retargeting to %s, distance2=%.2f'):format(best.id, bestDistanceSq))
    clearCombatPackages(debugLogging)
    AI.startPackage({ type = 'Combat', target = best, cancelOther = false })

    cooldown = shared.readSetting(settingsSection, 'retargetCooldownSeconds')
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            elapsed = elapsed + dt
            if cooldown > 0 then
                cooldown = math.max(0, cooldown - dt)
            end

            local pulseSeconds = shared.readSetting(settingsSection, 'pulseSeconds')
            if elapsed < pulseSeconds then
                return
            end
            elapsed = 0

            if cooldown > 0 then
                local debugLogging = shared.readSetting(settingsSection, 'debugLogging')
                shared.log(debugLogging, 'TARGET', ('skip: retarget cooldown active (%.2fs)'):format(cooldown))
                return
            end

            pulseRetarget()
        end,
    },
}
