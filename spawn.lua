local groupsByName = {}
local unitsByName = {}
local staticsByName = {}
local zonesByName = {}
local addGroup = coalition.addGroup
local addStaticObject = coalition.addStaticObject
local scheduleFunction = timer.scheduleFunction
local getModelTime = timer.getTime
local logwrite = log.write
local format = string.format

local debugSource = "SimpleSpawn.lua"

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

-------------------------------------------

Spawn = {}
Spawn.DebugLevel = 5
Spawn.DebugLevels = {
    ["Alert"]   = 1,
    ["Error"]   = 2,
    ["Warning"] = 3,
    ["Info"]    = 4,
    ["Debug"]   = 5

}
Spawn.Takeoff = {
    ["FromRunway"] =      {name = "Takeoff from runway",      type = "TakeOff",           action = "From Runway"},
    ["FromParkingHot"] =  {name = "Takeoff from parking hot", type = "TakeOffParkingHot", action = "From Parking Area Hot"},
    ["FromParkingCold"] = {name = "Takeoff from parking",     type = "TakeOffParking",    action = "From Parking Area"}
}

-------------------------------------------

function Spawn:New(templateName, nickname)
    local self = deepCopy(setmetatable({}, {__index = Spawn}))
    self.baseTemplate, self._static = self:GetSpawnTemplate(templateName)
    if not self.baseTemplate then
        self:Error("Spawn:New() | couldn't find template %s in database", templateName)
        return self
    end

    self.templateName = templateName
    self.keepGroupName = nil
    self.keepUnitNames = nil
    self.nickname = nickname
    self.scheduledFunction = nil
    self.scheduledCallback = nil
    self.scheduledParams = nil
    self.scheduledTimer = nil

    self.DCSGroup = nil
    self.DCSStaticObject = nil

    self.spawnCount = 0

    self.countryId = self.baseTemplate.countryId
    self.categoryId = self.baseTemplate.categoryId

    return self
end

function Spawn:NewFromTemplate(template, nickname, staticTemplate)
    local self = deepCopy(setmetatable({}, {__index = Spawn}))
    self.baseTemplate = deepCopy(template)
    self._static = staticTemplate

    self.templateName = self.baseTemplate.name
    self.keepGroupName = nil
    self.keepUnitNames = nil
    self.nickname = nickname
    self.scheduledFunction = nil
    self.scheduledCallback = nil
    self.scheduledParams = nil
    self.scheduledTimer = nil

    self.DCSGroup = nil
    self.DCSStaticObject = nil

    self.spawnCount = 0

    self.countryId = self.baseTemplate.countryId
    self.categoryId = self.baseTemplate.categoryId

    return self
end

---------------------------------------------
-- setters

function Spawn:SetTemplateNames(keepGroupName, keepUnitNames)
    self.keepGroupName = keepGroupName
    self.keepUnitNames = keepUnitNames
    return self
end

function Spawn:SetNickname(nickname)
    self.nickname = nickname
    return self
end

function Spawn:SetScheduler(callback, params, timer)
    self.scheduledFunction = true
    self.scheduledCallback = callback
    self.scheduledParams = params
    self.scheduledTimer = timer
    return self
end

function Spawn:SetPayload(unitId, payload)
    self.payloadId = unitId
    self.payload = payload
    return self
end

function Spawn:SetDebugLevel(level)
    if type(level) == "string" then
        self.debugLevel = Spawn.DebugLevels[level]
    elseif type(level) == "number" then
        self.debugLevel = level
    end
    return self
end

-------------------------------------------
-- getters

function Spawn:GetDCSGroup()
    if self.DCSGroup then
        return self.DCSGroup
    end
end

function Spawn:GetDCSStaticObject()
    if self.DCSStaticObject then
        return self.DCSStaticObject
    end
end

function Spawn:GetPayload(unitName)
    if unitsByName[unitName] then
        local payload = deepCopy(unitsByName[unitName].payload)
        return payload
    end
end

function Spawn:GetGroupTemplate(groupName)
    if groupsByName[groupName] then
        self:Info("Spawn:GetGroupTemplate() | returning group template: "..groupName)
        return deepCopy(groupsByName[groupName])
    end
end

function Spawn:GetUnitTemplate(unitName)
    if unitsByName[unitName] then
        self:Info("Spawn:GetUnitTemplate() | returning unit template: "..unitName)
        return deepCopy(unitsByName[unitName])
    end
end

function Spawn:GetStaticTemplate(staticName)
    if staticsByName[staticName] then
        self:Info("Spawn:GetStaticTemplate() | returning static template: "..staticName)
        return deepCopy(staticsByName[staticName]), true
    end
end

function Spawn:GetSpawnTemplate(templateName)
    if groupsByName[templateName] then
        self:Info("Spawn:GetSpawnTemplate() | returning group template: "..templateName)
        return deepCopy(groupsByName[templateName])
    elseif unitsByName[templateName] then
        self:Info("Spawn:GetSpawnTemplate() | returning unit template: "..templateName)
        return deepCopy(unitsByName[templateName])
    elseif staticsByName[templateName] then
        self:Info("Spawn:GetSpawnTemplate() | returning static template: "..templateName)
        return deepCopy(staticsByName[templateName]), true
    end
end

function Spawn:GetSpawnZone(zoneName)
    if zonesByName[zoneName] then
        self:Info("GetSpawnZone() | returning zone template: "..zoneName)
        return deepCopy(zonesByName[zoneName])
    end
end

function Spawn:GetSpawnZoneVec3(zone)
    return {
        ["x"] = deepCopy(zone.x),
        ["y"] = land.getHeight({x = zone.x, y = zone.z}),
        ["z"] = deepCopy(zone.y),
    }
end

function Spawn:GetOpenParkingSpots(airbaseName, terminalType)
    local airbase = Airbase.getByName(airbaseName)
    if airbase then
        local openParkingSpots = {}
        for _, spot in pairs(airbase:getParking()) do
            if not spot.TO_AC then
                if terminalType then
                    if spot.Term_Type == terminalType then
                        openParkingSpots[#openParkingSpots+1] = {
                            termIndex = spot.Term_Index,
                            termVec3 = spot.vTerminalPos
                        }
                    end
                else
                    openParkingSpots[#openParkingSpots+1] = {
                        termIndex = spot.Term_Index,
                        termVec3 = spot.vTerminalPos
                    }
                end
            end
        end
        return openParkingSpots
    end
end

function Spawn:GetFirstOpenParkingSpot(airbaseName, terminalType)
    local airbase = Airbase.getByName(airbaseName)
    if airbase then
        for _, spot in pairs(airbase:getParking()) do
            if not spot.TO_AC then
                if terminalType then
                    if spot.Term_Type == terminalType then
                        return {
                            termIndex = spot.Term_Index,
                            termVec3 = spot.vTerminalPos
                        }
                    end
                else
                    return {
                        termIndex = spot.Term_Index,
                        termVec3 = spot.vTerminalPos
                    }
                end
            end
        end
    end
end

-------------------------------------------
-- useful

function Spawn:MarkParkingSpots(airbaseName)
    self:Debug("Spawn:MarkParkingSpots() | marking parking spots for airbase: %s", airbaseName)
    local airbase = Airbase.getByName(airbaseName)
    if airbase then
        for _, spot in pairs(airbase:getParking()) do
            trigger.action.markToAll(-1, "Terminal Type: "..spot.Term_Type.."\nTerminal Index: "..spot.Term_Index, spot.vTerminalPos)
        end
    end
end

-------------------------------------------
-- spawners

function Spawn:SpawnToWorld()
    self._spawnTemplate = deepCopy(self.baseTemplate)
    self:_initializeTemplate()
    return self
end

function Spawn:SpawnFromTemplate(template, country, category, static)
    if static then
        return addStaticObject(country, category, template)
    else
        return addGroup(country, category, template)
    end
end


function Spawn:SpawnFromZone(zoneName, alt)
    local spawnZone = self:GetSpawnZone(zoneName)
    if spawnZone then
        local spawnZoneVec3 = self:GetSpawnZoneVec3(spawnZone)
        self._spawnTemplate = deepCopy(self.baseTemplate)
        self:SpawnFromVec3(spawnZoneVec3, alt)
    end
    return self
end

function Spawn:SpawnFromRandomZone(zoneList, alt)
    local randomNum = math.random(1, #zoneList)
    local randomZone = zoneList[randomNum]
    self:SpawnFromZone(randomZone, alt)
    return self
end

function Spawn:SpawnFromRandomVec3InZone(zoneName, alt)
    local spawnZone = self:GetSpawnZone(zoneName)
    if spawnZone then
        if spawnZone.type == 0 then
            local spawnZoneVec3 = self:GetSpawnZoneVec3(spawnZone)
            local radius = spawnZone.radius * 0.75
            spawnZoneVec3.x = spawnZoneVec3.x + math.random(radius * -1, radius)
            spawnZoneVec3.z = spawnZoneVec3.z + math.random(radius * -1, radius)
            self:SpawnFromVec3(spawnZoneVec3, alt)
        end
    end
    return self
end

function Spawn:SpawnFromRandomVec3InRadius(vec3, minRadius, maxRadius, alt)
    local vec3 = deepCopy(vec3)
    local radius = math.random(minRadius, maxRadius)
    radius = radius * 0.75
    vec3.x = vec3.x + math.random(radius * -1, radius)
    vec3.z = vec3.z + math.random(radius * -1, radius)
    self:SpawnFromVec3(vec3, alt)
    return self
end

function Spawn:SpawnFromVec3(vec3, alt)
    self._spawnTemplate = deepCopy(self.baseTemplate)
    if self._static or self.categoryId == Group.Category.GROUND then
        alt = land.getHeight({["x"] = vec3.x, ["y"] = vec3.z})
    elseif self.categoryId == Group.Category.SHIP then
        alt = 0
    elseif self.categoryId == Group.Category.AIRPLANE or self.categoryId == Group.Category.HELICOPTER then
        if not alt then
            self:Error("spawn:SpawnFromVec3() | %s requires an altitude to be born from a vec3", self.templateName)
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
    self:_initializeTemplate()
    return self
end

function Spawn:SpawnFromAirbaseRunway(airbaseName, terminals)
    self:SpawnFromAirbase(airbaseName, Spawn.Takeoff.FromRunway, terminals)
    return self
end

function Spawn:SpawnFromAirbaseParkingHot(airbaseName, terminals)
    self:SpawnFromAirbase(airbaseName, Spawn.Takeoff.FromParkingHot, terminals)
    return self
end

function Spawn:SpawnFromAirbaseParkingCold(airbaseName, terminals)
    self:SpawnFromAirbase(airbaseName, Spawn.Takeoff.FromParkingCold, terminals)
    return self
end

function Spawn:SpawnFromAirbase(airbaseName, takeoff, terminals)
    self._spawnTemplate = deepCopy(self.baseTemplate)
    local spawnAirbase = Airbase.getByName(airbaseName)
    if spawnAirbase then
        local spawnAirbaseVec3 = spawnAirbase:getPoint()
        local spawnAirbaseId = spawnAirbase:getID()
        local spawnAirbaseCategory = spawnAirbase:getDesc().category
        self._spawnTemplate.route.points[1].type = takeoff.type
        self._spawnTemplate.route.points[1].action = takeoff.action
        if spawnAirbaseCategory == 0 then -- airbases
            self._spawnTemplate.route.points[1].airdromeId = spawnAirbaseId
        elseif spawnAirbaseCategory == 1 or spawnAirbaseCategory == 2 then -- ships and helipads
            self._spawnTemplate.route.points[1].helipadId = spawnAirbaseId
        end
        if terminals then
            if type(terminals) ~= "table" and type(terminals) == "number" then
                terminals = {terminals}
            end
            local terminalData = self:_getTerminalData(airbaseName, terminals)
            self._spawnTemplate.route.points[1].x = terminalData[1].termVec3.x
            self._spawnTemplate.route.points[1].y = terminalData[1].termVec3.z
            for unitId, unitData in ipairs(self._spawnTemplate.units) do
                self:Debug("setting unit %s to Term_Index %d", unitData.name, terminalData[unitId].termIndex)
                unitData.parking = terminalData[unitId].termIndex
                unitData.x = terminalData[unitId].termVec3.x
                unitData.y = terminalData[unitId].termVec3.z
            end
        else
            self._spawnTemplate.route.points[1].x = spawnAirbaseVec3.x
            self._spawnTemplate.route.points[1].y = spawnAirbaseVec3.z
        end
        self:_initializeTemplate()
        return self
    end
end

-------------------------------------------
-- initializers

function Spawn:_initializeNames()
    if not self.keepGroupName then
        if self.nickname then
            self._spawnTemplate.name = self.nickname
        else
            if not self._static then
                self._spawnTemplate.name = self._spawnTemplate.name.." #"..self.spawnCount + 1
            end
        end
    end
    if not self.keepUnitNames then
        if self._static then
            self._spawnTemplate.units[1].name = self._spawnTemplate.units[1].name.." #"..self.spawnCount + 1
        else
            for unitId = 1, #self._spawnTemplate.units do
                self._spawnTemplate.units[unitId].name = self._spawnTemplate.name.."-"..unitId
            end
        end
    end
    return self
end


function Spawn:_initializeTemplate()
    self:_initializeNames()
    self:_addToWorld()
    return self
end

-------------------------------------------
-- internals

function Spawn:_scheduleFunction(callback, params, timer)
    callback = self.scheduledCallback or callback
    params = self.scheduledParams or params
    timer = self.scheduledTimer or timer
    scheduleFunction(function() callback(unpack(params)) end, nil, getModelTime() + self.scheduledTimer)
end

function Spawn:_getTerminalData(airbaseName, terminals)
    local airbase = Airbase.getByName(airbaseName)
    if airbase then
        local terminalData = {}
        for _, spot in pairs(airbase:getParking()) do
            if not spot.TO_AC then
                for _, termIndex in pairs(terminals) do
                    if spot.Term_Index == termIndex then
                        self:Debug("Term_Index == %d", termIndex)
                        terminalData[#terminalData+1] = {
                            termIndex = spot.Term_Index,
                            termVec3 = spot.vTerminalPos
                        }
                    end
                end
            end
        end
        return terminalData
    end
    return self
end

function Spawn:_addToWorld()
    if self._static then
        self.DCSStaticObject = addStaticObject(self.countryId, self._spawnTemplate.units[1])
        self.spawnCount = self.spawnCount + 1
        self:Debug("Spawn:_addToWorld() | %s has been added into the world", self._spawnTemplate.units[1].name)
    else
        if self.payload then
            self._spawnTemplate.units[self.payloadId] = self.payload
        end
        self.DCSGroup = addGroup(self.countryId, self.categoryId, self._spawnTemplate)
        self.spawnCount = self.spawnCount + 1
        self:Debug("Spawn:_addToWorld() | %s has been added into the world", self._spawnTemplate.name)
    end
    if self.scheduledFunction then
        self:_scheduleFunction()
    end
    return self
end

-------------------------------------------
-- logging and database initialization

do
    local debugLevels = {
        {["method"] = "Alert", ["level"] = "ALERT"},
        {["method"] = "Error", ["level"] = "ERROR"},
        {["method"] = "Warning", ["level"] = "WARNING"},
        {["method"] = "Info", ["level"] = "INFO"},
        {["method"] = "Debug", ["level"] = "DEBUG"}
    }
    for level, data in pairs(debugLevels) do
        Spawn[data.method] = function(self, message, ...)
            if self.debugLevel and self.debugLevel < level then
                return
            end
            logwrite(debugSource, log[data.level], format(message, ...))
        end
    end

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

-------------------------------------------
-- testing

local spawnGroup = Spawn:NewFromTemplate(Spawn:GetGroupTemplate("hog"))
spawnGroup:SpawnToWorld()
--Spawn:New("hog"):SpawnFromAirbase("Incirlik", Spawn.Takeoff.FromParkingHot, {15, 17, 23})