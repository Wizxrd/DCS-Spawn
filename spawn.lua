local groupsByName = {}
local unitsByName = {}
local staticsByName = {}
local zonesByName = {}

local function deepCopy(object)
    local copies = {}
    local function recursiveCopy(object)
        if type(object) ~= "table" then return object end
        if copies[object] then return copies[object] end
        local copy = {}
        copies[object] = copy
        for key, value in pairs(object) do
            copy[recursiveCopy(key)] = recursiveCopy(value)
        end
        return setmetatable(copy, getmetatable(object))
    end
    return recursiveCopy(object)
end

do
    local categoryId = {
        ["plane"] = Unit.Category.AIRPLANE,
        ["helicopter"] = Unit.Category.HELICOPTER,
        ["vehicle"] = Unit.Category.GROUND_UNIT,
        ["ship"] = Unit.Category.SHIP,
    }
    for sideName, coalitionData in pairs(env.mission.coalition) do
        if sideName == "neutrals" then sideName = "neutral" end
        if type(coalitionData) == "table" then
            if coalitionData.country then
                for _, countryData in pairs(coalitionData.country) do
                    for categoryName, objectData in pairs(countryData) do
                        if categoryName == "plane" or categoryName == "helicopter" or categoryName == "vehicle" or categoryName == "ship" then
                            for _, groupData in pairs(objectData.group) do
                                if groupData.lateActivation then
                                    groupData.lateActivation = false
                                end
                                groupsByName[groupData.name] = deepCopy(groupData)
                                groupsByName[groupData.name].countryId = countryData.id
                                groupsByName[groupData.name].categoryId = categoryId[categoryName]
                                for unitId, unitData in pairs(groupData.units) do
                                    env.error(unitData.name.." added")
                                    unitsByName[unitData.name] = deepCopy(groupData)
                                    unitsByName[unitData.name].name = unitData.name
                                    unitsByName[unitData.name].units = {}
                                    unitsByName[unitData.name].units[1] = deepCopy(unitData)
                                    unitsByName[unitData.name].countryId = countryData.id
                                    unitsByName[unitData.name].categoryId = categoryId[categoryName]
                                end
                            end
                        elseif categoryName == "static" then
                            for _, staticData in pairs(objectData.group) do
                                local staticName = staticData.units[1].name
                                staticsByName[staticName] = deepCopy(staticData)
                                staticsByName[staticName].countryId = countryData.id
                            end
                        end
                    end
                end
            end
        end
    end

    for _, zones in pairs(env.mission.triggers) do
        for _, zoneData in pairs(zones) do
            zonesByName[zoneData.name] = deepCopy(zoneData)
            zonesByName[zoneData.name].x = zoneData.x
            zonesByName[zoneData.name].y = land.getHeight({x = zoneData.x, y = zoneData.y})
            zonesByName[zoneData.name].z = zoneData.y
        end
    end
end

local function getSpawnTemplate(objectName)
    if groupsByName[objectName] then
        env.info("getSpawnTemplate(): returning group "..objectName)
        return deepCopy(groupsByName[objectName])
    elseif unitsByName[objectName] then
        env.info("getSpawnTemplate(): returning unit "..objectName)
        return deepCopy(unitsByName[objectName])
    elseif staticsByName[objectName] then
        env.info("getSpawnTemplate(): returning static "..objectName)
        return deepCopy(staticsByName[objectName]), true
    end
end

local function getZone(zoneName)
    if zonesByName[zoneName] then
        return deepCopy(zonesByName[zoneName])
    end
end

local function getZoneVec3(zone)
    return {
        ["x"] = zone.x,
        ["y"] = zone.y,
        ["z"] = zone.z
    }
end

-------------------------------------------

spawn = {}

-------------------------------------------

function spawn:new(objectName, nickname)
    local self = deepCopy(setmetatable({}, {__index = spawn}))
    self.baseTemplate, self.static = getSpawnTemplate(objectName)
    if not self.baseTemplate then
        log.write("spawn.lua", log.ERROR, "spawn:new(): couldn't find %s in database", objectName)
        return self
    end
    self.objectName = objectName
    self.nickname = nickname
    self.countryId = self.baseTemplate.countryId
    self.categoryId = self.baseTemplate.categoryId

    self.keepGroupName = nil
    self.keepUnitNames = nil
    self.scheduledTime = nil
    self.dcsGroup = nil
    self.dcsStatic = nil

    self.spawnCount = 0

    return self
end

-------------------------------------------

function spawn:keepNames(keepGroupName, keepUnitNames)
    self.keepGroupName = keepGroupName
    self.keepUnitNames = keepUnitNames
    return self
end

function spawn:setNickname(nickname)
    self.nickname = nickname
    return self
end

function spawn:setSchedule(scheduledTime)
    self.scheduledTime = scheduledTime
    return self
end

-------------------------------------------

function spawn:getSpawnedGroup()
    return self.dcsGroup
end

function spawn:getSpawnedStatic()
    return self.dcsStatic
end

-------------------------------------------

function spawn:spawnToWorld()
    self._spawnTemplate = deepCopy(self.baseTemplate)
    self:_initObject()
    return self
end

function spawn:spawnFromZone(zoneName, alt)
    local spawnZone = getZone(zoneName)
    if spawnZone then
        local spawnZoneVec3 = getZoneVec3(spawnZone)
        self._spawnTemplate = deepCopy(self.baseTemplate)
        self:spawnFromVec3(spawnZoneVec3, alt)
    end
    return self
end

function spawn:spawnFromRandomZone(zoneList, alt)
    local randomNum = math.random(1, #zoneList)
    local randomZone = zoneList[randomNum]
    self:spawnFromZone(randomZone, alt)
    return self
end

function spawn:spawnFromRandomVec3InZone(zoneName, alt)
    local spawnZone = getZone(zoneName)
    if spawnZone then
        if spawnZone.type == 0 then
            local spawnZoneVec3 = getZoneVec3(spawnZone)
            local radius = spawnZone.radius * 0.75
            spawnZoneVec3.x = spawnZoneVec3.x + math.random(radius * -1, radius)
            spawnZoneVec3.z = spawnZoneVec3.z + math.random(radius * -1, radius)
            self:spawnFromVec3(spawnZoneVec3, alt)
        end
    end
    return self
end

function spawn:spawnFromRandomizedVec3(vec3, radius, alt)
    local _radius = radius * 0.75
    local _vec3 = deepCopy(vec3)
    _vec3.x = _vec3.x + math.random(_radius * -1, _radius)
    _vec3.z = _vec3.z + math.random(_radius * -1, _radius)
    self:spawnFromVec3(_vec3, alt)
    return self
end

function spawn:spawnFromVec3(vec3, alt)
    self._spawnTemplate = deepCopy(self.baseTemplate)
    if self.categoryId == Group.Category.GROUND or self.static then
        alt = land.getHeight({["x"] = vec3.x, ["y"] = vec3.z})
    elseif self.categoryId == Group.Category.SHIP then
        alt = 0
    elseif self.categoryId == Group.Category.AIRPLANE or self.categoryId == Group.Category.HELICOPTER then
        if not alt then
            self:error("spawn:spawnFromVec3(): %s requires an altitude to be born from a vec3", self.objectName)
            return self
        end
        alt = alt
    end
    for _, unitData in pairs(self._spawnTemplate.units) do
        local sX = unitData.x or 0
        local sY = unitData.y  or 0
        local bX = self._spawnTemplate.route.points[1].x or self._spawnTemplate.x
        local bY = self._spawnTemplate.route.points[1].y or self._spawnTemplate.y
        local tX = vec3.x + (sX - bX)
        local tY = vec3.z + (sY - bY)
        unitData.alt = alt
        unitData.x = tX
        unitData.y = tY
    end
    self._spawnTemplate.route.points[1].alt = alt
    self._spawnTemplate.route.points[1].x = vec3.x
    self._spawnTemplate.route.points[1].y = vec3.z
    self:_initObject()
    return self
end

function spawn:_initNames()
    if not self.keepGroupName then
        if self.nickname then
            self._spawnTemplate.name = self.nickname
        else
            if not self.static then
                self._spawnTemplate.name = self._spawnTemplate.name.." #"..self.spawnCount + 1
            end
        end
    end
    if not self.keepUnitNames then
        if self.static then
            self._spawnTemplate.units[1].name = self._spawnTemplate.units[1].name.." #"..self.spawnCount + 1
        else
            for unitId = 1, #self._spawnTemplate.units do
                self._spawnTemplate.units[unitId].name = self._spawnTemplate.name.."-"..unitId
            end
        end
    end
    return self
end

function spawn:_addObject()
    env.error("running")
    if self.static then
        self.dcsStatic = coalition.addStaticObject(self.countryId, self._spawnTemplate.units[1])
        self.spawnCount = self.spawnCount + 1
    else
        env.error("spawning group "..self._spawnTemplate.name)
        self.dcsGroup = coalition.addGroup(self.countryId, self.categoryId, self._spawnTemplate)
        self.spawnCount = self.spawnCount + 1
    end
    return self
end

function spawn:_initObject()
    self:_initNames()
    self:_addObject()
end

-------------------------------------------

local SpawnTest = spawn:new("tank")
SpawnTest:keepNames(true, true)
SpawnTest:spawnFromRandomizedVec3(trigger.misc.getZone("spawn zone").point, trigger.misc.getZone("spawn zone").radius)