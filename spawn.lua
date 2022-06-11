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

Spawn.Waypoint = {
    ["TurningPoint"]          = {name = "Turning point",            type = "Turning Point",     action = "Turning Point" },
    ["FlyOverPoint"]          = {name = "Fly over point",           type = "Turning Point",     action = "Fly Over Point"},
    ["FinPoint"]              = {name = "Fin point N/A",            type = "Fin Point",         action = "Fin Point"},
    ["TakeoffFromRunway"]     = {name = "Takeoff from runway",      type = "TakeOff",           action = "From Runway"},
    ["TakeoffFromParking"]	  = {name = "Takeoff from parking",     type = "TakeOffParking",    action = "From Parking Area"},
    ["TakeoffFromParkingHot"] = {name = "Takeoff from parking hot", type = "TakeOffParkingHot", action = "From Parking Area Hot"},
    ["LandingReFuAr"] 	      = {name = "LandingReFuAr",            type = "LandingReFuAr",     action = "LandingReFuAr"},
    ["Landing"] 		      = {name = "Landing",                  type = "Land",              action = "Landing"},
    ["OffRoad"] 		      = {name = "Offroad",                  type = "Turning Point",     action = "Off Road"},
    ["OnRoad"] 		          = {name = "On road",              	type = "Turning Point",     action = "On Road"},
    ["Rank"] 			      = {name = "Rank",                     type = "Turning Point",     action = "Rank"},
    ["Cone"] 		    	  = {name = "Cone",                     type = "Turning Point",     action = "Cone"},
    ["Vee"] 	    		  = {name = "Vee",                      type = "Turning Point",     action = "Vee"},
    ["Diamond"] 	    	  = {name = "Diamond",                  type = "Turning Point",     action = "Diamond"},
    ["EchelonL"]     		  = {name = "Echelon Left",             type = "Turning Point",     action = "EchelonL"},
    ["EchelonR"] 	    	  = {name = "Echelon Right",            type = "Turning Point",     action = "EchelonR"},
    ["CustomForm"] 	          = {name = "Custom",                   type = "Turning Point",     action = "Custom"},
}

-------------------------------------------

function Spawn:New(templateName, nickname)
    local self = deepCopy(setmetatable({}, {__index = Spawn}))
    self.baseTemplate, self.staticTemplate = self:GetBaseTemplate(templateName)
    if not self.baseTemplate then
        self:Error("Spawn:New() | couldn't find template %s in database", templateName)
        return self
    end

    self.templateName = templateName
    self.nickname = nickname

    self.keepGroupName = nil
    self.keepUnitNames = nil

    self.scheduledFunction = nil
    self.scheduledCallback = nil
    self.scheduledParams = nil
    self.scheduledTimer = nil

    self.payloadId = nil
    self.payload = nil

    self.spawnCount = 0

    self.countryId = self.baseTemplate.countryId
    self.categoryId = self.baseTemplate.categoryId

    self.DCSGroup = nil
    self.DCSStaticObject = nil

    return self
end

function Spawn:NewFromTemplate(template, nickname, staticTemplate)
    local self = deepCopy(setmetatable({}, {__index = Spawn}))
    self.baseTemplate = deepCopy(template)
    self.staticTemplate = staticTemplate
    self.nickname = nickname

    self.templateName = self.baseTemplate.name
    self.keepGroupName = nil
    self.keepUnitNames = nil
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
--[[
{
    type -- required both static and unit

    countryId -- required unit
    categoryId -- required unit

    category -- required static
    shapeName -- required static

    -- optional
    skill
    canDrive
    alt
    altType
    heading
    type
    action
    name
    staticTemplate
    waypoint
]]
function Spawn:NewFromVars(varargs)
    local spawnTemplate
    if varargs.staticTemplate then
        spawnTemplate = self:GetStaticSpawnTemplate()
        spawnTemplate.countryId = varargs.countryId
        spawnTemplate.units[1].category = varargs.category
        spawnTemplate.units[1].shape_name = varargs.shapeName
        spawnTemplate.units[1].type = varargs.type
    else
        spawnTemplate = self:GetSpawnTemplate()
        spawnTemplate.countryId = varargs.countryId
        spawnTemplate.categoryId = varargs.categoryId
        spawnTemplate.name = varargs.name or varargs.type
        spawnTemplate.units[1].type = varargs.type
        spawnTemplate.units[1].skill = varargs.skill or "Random"
        spawnTemplate.units[1].heading = varargs.heading or 0
        spawnTemplate.units[1].playerCanDrive = varargs.canDrive or false
        spawnTemplate.route.points[1].alt = varargs.alt or 0
        spawnTemplate.route.points[1].alt_type = varargs.altType or "BARO"
        if varargs.waypoint then
            spawnTemplate.route.points[1].type = varargs.waypoint.type or "Turning Point"
            spawnTemplate.route.points[1].action = varargs.waypoint.action or "Turning Point"
        end
    end
    local self = Spawn:NewFromTemplate(spawnTemplate, varargs.nickname, varargs.staticTemplate)
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

function Spawn:SetLivery(unitId, livery)
    self.liveryId = unitId
    self.livery = livery
end

function Spawn:SetDebugLevel(level)
    if type(level) == "string" then
        self.DebugLevel = Spawn.DebugLevels[level]
    elseif type(level) == "number" then
        self.DebugLevel = level
    end
    return self
end

-------------------------------------------
-- getters

function Spawn:GetDCSGroup()
    if self.DCSGroup:isExist() then
        return self.DCSGroup
    end
end

function Spawn:GetDCSStaticObject()
    if self.DCSStaticObject:isExist() then
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

function Spawn:GetBaseTemplate(templateName)
    if groupsByName[templateName] then
        self:Info("Spawn:GetBaseTemplate() | returning group template: "..templateName)
        return deepCopy(groupsByName[templateName])
    elseif unitsByName[templateName] then
        self:Info("Spawn:GetBaseTemplate() | returning unit template: "..templateName)
        return deepCopy(unitsByName[templateName])
    elseif staticsByName[templateName] then
        self:Info("Spawn:GetBaseTemplate() | returning static template: "..templateName)
        return deepCopy(staticsByName[templateName]), true
    end
end

function Spawn:GetSpawnTemplate()
    local spawnTemplate = {
        ["visible"] = true,
        ["lateActivation"] = false,
        ["tasks"] = {},
        ["uncontrollable"] = false,
        ["task"] = "",
        ["taskSelected"] = true,
        ["route"] = {
            ["points"] = {
                [1] = {
                    ["alt"] = 0,
                    ["type"] = "Turning Point",
                    ["ETA"] = 0,
                    ["alt_type"] = "",
                    ["formation_template"] = "",
                    ["y"] = 0,
                    ["x"] = 0,
                    ["ETA_locked"] = true,
                    ["speed"] = 0,
                    ["action"] = "Turning Point",
                    ["task"] = {
                        ["id"] = "ComboTask",
                        ["params"] = {
                            ["tasks"] = {},
                        },
                    },
                    ["speed_locked"] = true,
                },
            },
        },
        ["hidden"] = false,
        ["units"] = {
            [1] = {
                ["type"] = "",
                ["skill"] = "",
                ["y"] = 0,
                ["x"] = 0,
                ["name"] = "",
                ["heading"] = 0,
                ["playerCanDrive"] = true,
            }
        },
        ["y"] = 0,
        ["x"] = 0,
        ["name"] = "",
        ["start_time"] = 0,
    }
    return spawnTemplate
end

function Spawn:GetStaticSpawnTemplate()
    local staticTemplate = {
        ["heading"] = 0,
        ["route"] = {
            ["points"] = {
                [1] = {
                    ["alt"] = 0,
                    ["type"] = "",
                    ["name"] = "",
                    ["y"] = 0,
                    ["speed"] = 0,
                    ["x"] = 0,
                    ["formation_template"] = "",
                    ["action"] = "",
                },
            },
        },
        ["units"] = {
            [1] = {
                ["category"] = "",
                ["shape_name"] = "",
                ["type"] = "",
                ["rate"] = 0,
                ["y"] = 0,
                ["x"] = 0,
                ["name"] = "",
                ["heading"] = 0,
            },
        },
        ["y"] = 0,
        ["x"] = 0,
        ["name"] = "",
        ["dead"] = false,
    }
    return staticTemplate
end

function Spawn:GetZoneTemplate(zoneName)
    if zonesByName[zoneName] then
        self:Info("GetZoneTemplate() | returning zone template: "..zoneName)
        return deepCopy(zonesByName[zoneName])
    end
end

function Spawn:GetQuadZonePoints(vararg)
    if vararg == "string" then
        if zonesByName[vararg] then
            local zone = zonesByName[vararg]
            if zone.type == 2 and zone.vertices then
                return deepCopy(zonesByName[vararg].vertices)
            end
        end
    elseif vararg == "table" and vararg.vertices then
        return deepCopy(vararg.vertices)
    end
end

function Spawn:GetZoneVec3(vararg)
    if type(vararg) == "string" then
        local zone = self:GetZoneTemplate(vararg)
        if zone then
            return {
                ["x"] = deepCopy(zone.x),
                ["y"] = deepCopy(zone.y),
                ["z"] = deepCopy(zone.z),
            }
        end
    elseif type(vararg) == "table" then
        return {
            ["x"] = deepCopy(vararg.x),
            ["y"] = deepCopy(vararg.y),
            ["z"] = deepCopy(vararg.z),
        }
    end
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

function Spawn:GetTerminalData(airbaseName, terminals)
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

function Spawn:ScheduleFunction(callback, params, timer)
    callback = self.scheduledCallback or callback
    params = self.scheduledParams or params
    timer = self.scheduledTimer or timer
    scheduleFunction(function() callback(unpack(params)) end, nil, getModelTime() + timer)
end

-------------------------------------------
-- zone stuff

function Spawn:GroupInZone(groupName, zoneName)
    local group = Group.getByName(groupName)
    if group then
        local unit = group:getUnit(1)
        local unitName = unit:getName()
        return self:UnitInZone(unitName, zoneName)
    end
    return false
end

function Spawn:UnitInZone(unitName, zoneName)
    local unit = Unit.getByName(unitName)
    if unit then
        local zoneVec3 = self:GetZoneVec3(zoneName)
        local unitVec3 = unit:getPoint()
        return self:ObjectInZone(unitVec3, zoneVec3)
    end
    return false
end

function Spawn:StaticInZone(staticName, zoneName)
    local static = StaticObject.getByName(staticName)
    if static then
        local zoneVec3 = self:GetZoneVec3(zoneName)
        local staticVec3 = static:getPoint()
        return self:ObjectInZone(staticVec3, zoneVec3)
    end
    return false
end

function Spawn:ObjectInZone(objectVec3, zoneVec3)
    if ((objectVec3.x - zoneVec3.x)^2 + (objectVec3.z - zoneVec3.z)^2)^0.5 <= zone.radius then
        return true
    end
    return false
end

function Spawn:GroupInQuadZone(groupName, zoneName)
    local group = Group.getByName(groupName)
    if group then
        local unit = group:getUnit(1)
        local unitName = unit:getName()
        return self:UnitInQuadZone(unitName, zoneName)
    end
    return false
end

function Spawn:UnitInQuadZone(unitName, zoneName)
    local unit = Unit.getByName(unitName)
    if unit then
        local zonePoints = self:GetQuadZonePoints(zoneName)
        local unitVec3 = unit:getPoint()
        return self:ObjectInPolygon(unitVec3, zonePoints)
    end
    return false
end

function Spawn:StaticInQuadZone(staticName, zoneName)
    local static = StaticObject.getByName(staticName)
    if static then
        local zonePoints = self:GetQuadZonePoints(zoneName)
        local staticVec3 = static:getPoint()
        return self:ObjectInPolygon(staticVec3, zonePoints)
    end
    return false
end

function Spawn:GroupInPolygon(groupName, points)
    local group = Group.getByName(groupName)
    if group then
        local unit = group:getUnit(1)
        local unitName = unit:getName()
        return self:UnitInPolygon(unitName, points)
    end
    return false
end

function Spawn:UnitInPolygon(unitName, points)
    local unit = Unit.getByName(unitName)
    if unit then
        local unitVec3 = unit:getPoint()
        return self:ObjectInPolygon(unitVec3, points)
    end
    return false
end

function Spawn:StaticInPolygon(staticName, points)
    local static = StaticObject.getByName(staticName)
    if static then
        local staticVec3 = static:getPoint()
        return self:ObjectInPolygonZone(staticVec3, points)
    end
    return false
end

function Spawn:ObjectInPolygon(objectVec3, points)
    local vx = objectVec3.x
    local vz = objectVec3.z
    local count = 0
    local polygon = deepCopy(points)
    polygon[#polygon+1] = polygon[1]
    for i = 1, #polygon do
        if (polygon[i].z <= vz and polygon[i+1].z > vz) or (polygon[i].z > vz and polygon[i+1] <= vz) then
            local vt = (vz - polygon[i].z) / (polygon[i+1].z - polygon[i].z)
            if (vx < polygon[i].x + vt*(polygon[i+1].x - polygon[i].x)) then
                count = count + 1
            end
        end
    end
    return count%2 == 1
end

-------------------------------------------
-- spawners

function Spawn:SpawnToWorld()
    self._spawnTemplate = deepCopy(self.baseTemplate)
    self:_prepareTemplate()
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
    local spawnZoneVec3 = self:GetZoneVec3(zoneName)
    self:SpawnFromVec3(spawnZoneVec3, alt)
    return self
end

function Spawn:SpawnFromZoneOnNearestRoad(zoneName)
    local spawnZoneVec3 = self:GetZoneVec3(zoneName)
    self:SpawnFromVec3OnNearestRoad(spawnZoneVec3)
    return self
end

function Spawn:SpawnFromRandomZone(zoneList, alt)
    local randomNum = math.random(1, #zoneList)
    local randomZone = zoneList[randomNum]
    self:SpawnFromZone(randomZone, alt)
    return self
end

function Spawn:SpawnFromRandomVec3InZone(zoneName, alt)
    local spawnZone = self:GetZoneTemplate(zoneName)
    local spawnZoneVec3 = self:GetZoneVec3(spawnZone)
    local radius = spawnZone.radius * 0.75
    spawnZoneVec3.x = spawnZoneVec3.x + math.random(radius * -1, radius)
    spawnZoneVec3.z = spawnZoneVec3.z + math.random(radius * -1, radius)
    self:SpawnFromVec3(spawnZoneVec3, alt)
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

function Spawn:SpawnFromVec3OnNearestRoad(vec3)
    local x, z = land.getClosestPointOnRoads("roads", vec3.x, vec3.z)
    vec3.x = x
    vec3.z = z
    self:SpawnFromVec3(vec3)
    return self
end

function Spawn:SpawnFromVec3(vec3, alt)
    self._spawnTemplate = deepCopy(self.baseTemplate)
    if self.staticTemplate or self.categoryId == Group.Category.GROUND then
        alt = land.getHeight({["x"] = vec3.x, ["y"] = vec3.z})
    elseif self.categoryId == Group.Category.SHIP then
        alt = 0
    elseif self.categoryId == Group.Category.AIRPLANE or self.categoryId == Group.Category.HELICOPTER then
        if alt then
            alt = alt
        else
            self:Error("spawn:SpawnFromVec3() | %s requires an altitude to be born from a vec3", self.templateName)
            return self
        end
    end
    for _, unitData in pairs(self._spawnTemplate.units) do
        self:Error("OLD VEC's: X = %.5f | Y = %.5f", unitData.x, unitData.y)
        local sX = unitData.x or 0
        local sY = unitData.y  or 0
        local bX = self._spawnTemplate.route.points[1].x or self._spawnTemplate.x
        local bY = self._spawnTemplate.route.points[1].y or self._spawnTemplate.y
        local tX = vec3.x + (sX - bX)
        local tY = vec3.z + (sY - bY)
        unitData.alt = alt
        unitData.x = tX
        unitData.y = tY
        self:Error("OLD VEC's: X = %.5f | Y = %.5f", unitData.x, unitData.y)
    end
    self._spawnTemplate.route.points[1].alt = alt
    self._spawnTemplate.route.points[1].x = vec3.x
    self._spawnTemplate.route.points[1].y = vec3.z
    self:_prepareTemplate()
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
        self:_prepareTemplate()
        return self
    end
end

-------------------------------------------
-- template preperation

function Spawn:_prepareTemplate()
    self:_prepareNames()
    self:_addToWorld()
    return self
end

function Spawn:_prepareNames()
    if not self.keepGroupName then
        if self.nickname then
            self._spawnTemplate.name = self.nickname
        else
            if not self.staticTemplate then
                self._spawnTemplate.name = self._spawnTemplate.name.." #"..self.spawnCount + 1
            end
        end
    end
    if not self.keepUnitNames then
        if self.staticTemplate then
            self._spawnTemplate.units[1].name = self._spawnTemplate.units[1].name.." #"..self.spawnCount + 1
        else
            for unitId = 1, #self._spawnTemplate.units do
                self._spawnTemplate.units[unitId].name = self._spawnTemplate.name.."-"..unitId
            end
        end
    end
    return self
end

-------------------------------------------
-- add template to world

function Spawn:_addToWorld()
    if self.staticTemplate then
        self.DCSStaticObject = addStaticObject(self.countryId, self._spawnTemplate.units[1])
        self.spawnCount = self.spawnCount + 1
        self:Debug("Spawn:_addToWorld() | %s has been added into the world", self._spawnTemplate.units[1].name)
    else
        if self.payload then
            self._spawnTemplate.units[self.payloadId] = self.payload
        end
        if self.livery then
            self._spawnTemplate.units[self.payloadId] = self.payload
        end
        self.DCSGroup = addGroup(self.countryId, self.categoryId, self._spawnTemplate)
        self.spawnCount = self.spawnCount + 1
        self:Debug("Spawn:_addToWorld() | %s has been added into the world", self._spawnTemplate.name)
    end
    if self.scheduledFunction then
        self:ScheduleFunction()
    end
    return self
end

-------------------------------------------
-- internals

-------------------------------------------
-- logging and database initialization

do
    local DebugLevels = {
        {["method"] = "Alert", ["level"] = "ALERT"},
        {["method"] = "Error", ["level"] = "ERROR"},
        {["method"] = "Warning", ["level"] = "WARNING"},
        {["method"] = "Info", ["level"] = "INFO"},
        {["method"] = "Debug", ["level"] = "DEBUG"}
    }
    for level, data in pairs(DebugLevels) do
        Spawn[data.method] = function(self, message, ...)
            if self.DebugLevel and self.DebugLevel < level then
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

--local spawnGroup = Spawn:NewFromTemplate(Spawn:GetGroupTemplate("hog"))
--spawnGroup:SpawnToWorld()

--Spawn:New("tank-1"):SpawnFromZoneOnNearestRoad("spawn zone") -- will spawn outside of the zone

--local spawnZone = Spawn:GetZoneTemplate("spawn zone")
--local spawnZoneVec3 = Spawn:GetZoneVec3(spawnZone)
--Spawn:New("tank-2"):SpawnFromZone("spawn zone")
--[[
local spawnUnit = Spawn:NewUnitFromType({
    staticTemplate = true,
    name = "Test Unit",
    type = "Workshop A",
    countryId = country.id.USA,
    category = "Fortifications",
    shapeName = "tec_A",
})
spawnUnit:SpawnFromZone("spawn zone")
]]
--Spawn:New("hog"):SpawnFromAirbase("Incirlik", Spawn.Takeoff.FromParkingHot, {15, 17, 23})
