--[[

@script Spawn

@author Wizard

@description
A dynamic spawning script for DCS World

@features
- Object Orientated
- Logging
- New Spawn objects from late activated templates
- New Spawn objects from custom templates
- New Spawn objects from a variable amount of arguments
- Spawn with original group and unit names
- Spawn with a new nickname for group and units
- Spawn with a set schedule
- Spawn with a different unit payload
- Spawn with a different unit livery
- Spawn to world with an unchanged template
- Spawn from a template
- Spawn from a trigger zone center vec3
- Spawn from a trigger zone on the nearest road
- Spawn from a random zone
- Spawn from a random vec3 within a zone
- Spawn from a radnom vec3 within a random radius
- Spawn from a vec3 on the nearest road
- Spawm from vec3
- Spawm from a airbase runway
- Spawm from a airbase parking hot at any parking spot
- Spawn from a airbase parking cold at any parking spot
- Get the currently spawned DCSGroup
- Get the currently spawned DCSStaticObject
- Get a units payload by name
- Get a units livery by name
- Get a group template for spawning by name
- Get a unit template for spawning by name
- Get a static template for spawning by name
- Get a template (group, unit, static) by its name
- Get a empty spawn template
- Get a empty static spawn template
- Get a zone template by name
- Get a quad zones points by name
- Get a zones radius by name
- Get a zones center vec3 by name
- Get a airbases open parking spots by name with optional terminal type
- Get the first open parking spot at an airbase by name with optional terminal type
- Mark all the parking spots an airbase with terminal types and indexes used for spots when spawning at airbases
- Schedule a spawn by method
- Add a group template
- Add a unit template
- Add a static template

@created June 7th, 2022

@github https://github.com/Wizxrd/DCS-Spawn

]]

local addGroup = coalition.addGroup
local addStaticObject = coalition.addStaticObject
local scheduleFunction = timer.scheduleFunction
local getModelTime = timer.getTime
local logwrite = log.write
local format = string.format
local deepCopy
local inherit
local groupsByName = {}
local unitsByName = {}
local staticsByName = {}
local zonesByName = {}

-------------------------------------------

Spawn = {}
Spawn.Version = "0.0.1"
Spawn.Source = "Spawn.lua"
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

--[[ Create a new instance of a spawn object by name
- @param #Spawn self
- @param #string templateName
- @param #string nickname
- @return #Spawn self
]]
function Spawn:New(templateName, nickname)
    local self = inherit(self, Spawn)
    self.baseTemplate, self.staticTemplate = self:GetTemplate(templateName)
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
    self.scheduledTime = nil

    self.payloadId = nil
    self.payload = nil

    self.spawnCount = 0

    self.countryId = self.baseTemplate.countryId
    self.categoryId = self.baseTemplate.categoryId

    self.DCSGroup = nil
    self.DCSStaticObject = nil

    return self
end

--[[ Create a new instance of a spawn object from a template
- @param #Spawn self
- @param #table template
- @param #string nickname
- @param #boolean staticTemplate
- @return #Spawn self
]]
function Spawn:NewFromTemplate(template, nickname, staticTemplate)
    local self = inherit(self, Spawn)
    self.baseTemplate = deepCopy(template)
    self.staticTemplate = staticTemplate
    self.nickname = nickname

    self.templateName = self.baseTemplate.name
    self.keepGroupName = nil
    self.keepUnitNames = nil
    self.scheduledFunction = nil
    self.scheduledCallback = nil
    self.scheduledParams = nil
    self.scheduledTime = nil

    self.DCSGroup = nil
    self.DCSStaticObject = nil

    self.spawnCount = 0

    self.countryId = self.baseTemplate.countryId
    self.categoryId = self.baseTemplate.categoryId

    return self
end

--[[ Create a new instance of a spawn object from a variable amount of arguments
- @param #Spawn self
- @param #table template
- @param #string nickname
- @param #boolean staticTemplate
- @return #Spawn self
]]
function Spawn:NewFromVarargs(varargs)
    local spawnTemplate
    if varargs.staticTemplate then
        spawnTemplate = self:GetStaticSpawnTemplate()
        spawnTemplate.countryId = varargs.countryId
        spawnTemplate.units[1].category = varargs.category
        spawnTemplate.units[1].shape_name = varargs.shapeName
        spawnTemplate.units[1].type = varargs.type
        spawnTemplate.units[1].heading = varargs.heading or 0
    else
        spawnTemplate = self:GetSpawnTemplate()
        spawnTemplate.countryId = varargs.countryId
        spawnTemplate.categoryId = varargs.categoryId
        spawnTemplate.name = varargs.name or varargs.type
        if varargs.units then
            spawnTemplate.units = varargs.units
        else
            spawnTemplate.units[1].type = varargs.type
            spawnTemplate.units[1].skill = varargs.skill or "Random"
            spawnTemplate.units[1].heading = varargs.heading or 0
            spawnTemplate.units[1].playerCanDrive = varargs.canDrive or false
        end
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

--[[ Set the Spawn object to keep group or unit names
- @param #Spawn self
- @param #boolean keepGroupName
- @param #boolean keepUnitNames
- @return #Spawn self
]]
function Spawn:SetKeepNames(keepGroupName, keepUnitNames)
    self.keepGroupName = keepGroupName
    self.keepUnitNames = keepUnitNames
    return self
end

--[[ Set the Spawn objects nickname
- @param #Spawn self
- @param #string nickname
- @return #Spawn self
]]
function Spawn:SetNickname(nickname)
    self.nickname = nickname
    return self
end

--[[ Set the Spawn object to use a specific callback for spawning on a schedule
- @param #Spawn self
- @param #function callback
- @param #array params
- @param #number timer
- @return #Spawn self
]]
function Spawn:SetScheduler(callback, params, time)
    self.scheduledFunction = true
    self.scheduledCallback = callback
    self.scheduledParams = params
    self.scheduledTime = time
    return self
end

--[[ Set the Spawn object to have a unit use a different payload
- @param #Spawn self
- @param #number unitId
- @param #table payload
- @return #Spawn self
]]
function Spawn:SetPayload(unitId, payload)
    self.payloadId = unitId
    self.payload = payload
    return self
end

--[[ Set the Spawn object to have a unit use a different livery
- @param #Spawn self
- @param #number unitId
- @param #string livery
- @return #Spawn self
]]
function Spawn:SetLivery(unitId, liveryName)
    self.liveryId = unitId
    self.livery = liveryName
    return self
end

--[[ Set the Spawn object to use a certain debug level
- @param #Spawn self
- @param #number level
- @return #Spawn self
]]
function Spawn:SetDebugLevel(level)
    if type(level) == "string" then
        self.DebugLevel = Spawn.DebugLevels[level]
    elseif type(level) == "number" then
        self.DebugLevel = level
    end
    return self
end

-------------------------------------------

--[[ Get the currently alive DCS Class Group
- @param #Spawn self
- @return #DCSGroup
]]
function Spawn:GetDCSGroup()
    if self.DCSGroup:isExist() then
        return self.DCSGroup
    end
end

--[[ Get the currently alive DCS Class StaticObject
- @param #Spawn self
- @return #DCSStaticObject
]]
function Spawn:GetDCSStaticObject()
    if self.DCSStaticObject:isExist() then
        return self.DCSStaticObject
    end
end

--[[ Get a payload table from a unit by name
- @param #Spawn self
- @param #string unitName
- @return #table payload
]]
function Spawn:GetPayload(unitName)
    if unitsByName[unitName] then
        local payload = deepCopy(unitsByName[unitName].payload)
        return payload
    end
end

--[[ Get a livery name from a unit by name
- @param #Spawn self
- @param #string unitName
- @return #string liveryName
]]
function Spawn:GetLiveryName(unitName)
    if unitsByName[unitName] then
        local liveryName = unitsByName[unitName].livery_id
        return liveryName
    end
end

--[[ Get a group template by name
- @param #Spawn self
- @param #string groupName
- @return #table
]]
function Spawn:GetGroupTemplate(groupName)
    if groupsByName[groupName] then
        self:Info("Spawn:GetGroupTemplate() | returning group template: "..groupName)
        return deepCopy(groupsByName[groupName])
    end
end

--[[ Get a unit template by name
- @param #Spawn self
- @param #string unitName
- @return #table
]]
function Spawn:GetUnitTemplate(unitName)
    if unitsByName[unitName] then
        self:Info("Spawn:GetUnitTemplate() | returning unit template: "..unitName)
        return deepCopy(unitsByName[unitName])
    end
end

--[[ Get a static template by name
- @param #Spawn self
- @param #string staticName
- @return #table
]]
function Spawn:GetStaticTemplate(staticName)
    if staticsByName[staticName] then
        self:Info("Spawn:GetStaticTemplate() | returning static template: "..staticName)
        return deepCopy(staticsByName[staticName]), true
    end
end

--[[ Get a template by name
- @param #Spawn self
- @param #string templateName
- @return #table
]]
function Spawn:GetTemplate(templateName)
    if groupsByName[templateName] then
        self:Info("Spawn:GetTemplate() | returning group template: "..templateName)
        return deepCopy(groupsByName[templateName])
    elseif unitsByName[templateName] then
        self:Info("Spawn:GetTemplate() | returning unit template: "..templateName)
        return deepCopy(unitsByName[templateName])
    elseif staticsByName[templateName] then
        self:Info("Spawn:GetTemplate() | returning static template: "..templateName)
        return deepCopy(staticsByName[templateName]), true
    end
end

--[[ Get a empty spawn table for groups and units
- @param #Spawn self
- @return #table spawnTemplate
]]
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

--[[ Get a empty spawn table for statics
- @param #Spawn self
- @return #table staticSpawnTemplate
]]
function Spawn:GetStaticSpawnTemplate()
    local staticSpawnTemplate = {
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
    return staticSpawnTemplate
end

--[[ Get a zone template by name
- @param #Spawn self
- @param #string zoneName
- @return #table
]]
function Spawn:GetZoneTemplate(zoneName)
    if zonesByName[zoneName] then
        return deepCopy(zonesByName[zoneName])
    end
end

--[[ Get a quad zones points by name
- @param #Spawn self
- @param #string zoneName
- @return #table points
]]
function Spawn:GetQuadZonePoints(zoneName)
    local zoneTemplate = self:GetZoneTemplate(zoneName)
    if zoneTemplate then
        if zoneTemplate.type == 2 then
            local points = deepCopy(zoneTemplate.vertices)
            return points
        end
    end
end

--[[ Get a zones radius by name
- @param #Spawn self
- @param #string zoneName
- @return #number radius
]]
function Spawn:GetZoneRadius(zoneName)
    local zoneTemplate = self:GetZoneTemplate(zoneName)
    if zoneTemplate then
        if zoneTemplate.type == 0 then
            local radius = deepCopy(zoneTemplate.radius)
            return radius
        end
    end
end

--[[ Get a zones vec3 points by name
- @param #Spawn self
- @param #string zoneName
- @return #table vec3
]]
function Spawn:GetZoneVec3(zoneName)
    local zone = self:GetZoneTemplate(zoneName)
    if zone then
        local vec3 = deepCopy(zone.vec3)
        return vec3
    end
end

--[[ Get all the open parking spots at an airbase by name
- @param #Spawn self
- @param #string airbaseName
- @param #number terminalType
- @return #table openParkingSpots
]]
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

--[[ Get the first open parking spot an airbase by name
- @param #Spawn self
- @param #string airbaseName
- @param #number terminalType
- @return #table openSpot
]]
function Spawn:GetFirstOpenParkingSpot(airbaseName, terminalType)
    local airbase = Airbase.getByName(airbaseName)
    if airbase then
        for _, spot in pairs(airbase:getParking()) do
            if not spot.TO_AC then
                if terminalType then
                    if spot.Term_Type == terminalType then
                        local openSpot = {
                            termIndex = spot.Term_Index,
                            termVec3 = spot.vTerminalPos
                        }
                        return openSpot
                    end
                else
                    local openSpot = {
                        termIndex = spot.Term_Index,
                        termVec3 = spot.vTerminalPos
                    }
                    return openSpot
                end
            end
        end
    end
end

--[[ Get the the terminal data from an airbase by name
- @param #Spawn self
- @param #string airbaseName
- @param #number spots
- @return #table terminalData
]]
function Spawn:GetTerminalData(airbaseName, spots)
    local airbase = Airbase.getByName(airbaseName)
    if airbase then
        local terminalData = {}
        for _, spot in pairs(airbase:getParking()) do
            if not spot.TO_AC then
                for _, termIndex in pairs(spots) do
                    if spot.Term_Index == termIndex then
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

--[[ Mark the parking spots at an airbase by name
- @param #Spawn self
- @param #string airbaseName
- @return none
]]
function Spawn:MarkParkingSpots(airbaseName)
    local airbase = Airbase.getByName(airbaseName)
    if airbase then
        for _, spot in pairs(airbase:getParking()) do
            trigger.action.markToAll(-1, "Terminal Type: "..spot.Term_Type.."\nTerminal Index: "..spot.Term_Index, spot.vTerminalPos)
        end
    end
end

--[[ Spawn an object by a callback with a delay and any parameters
- @param #Spawn self
- @param #function callback
- @param #array params
- @param #number timer
- @return none
]]
function Spawn:SpawnScheduled(callback, params, timer)
    callback = self.scheduledCallback or callback
    params = self.scheduledParams or params
    timer = self.scheduledTime or timer
    scheduleFunction(function()
        callback(unpack(params))
        self:SpawnScheduled(callback, params, timer)
    end
    , nil, getModelTime() + timer)
end

function Spawn:AddGroupTemplate(template)
    groupsByName[template.name] = deepCopy(template)
    for _, unitTemplate in pairs(template.units) do
        self:AddUnitTemplate(unitTemplate)
    end
end

function Spawn:AddUnitTemplate(template)
    unitsByName[template.name] = deepCopy(template)
end

function Spawn:AddStaticTemplate(template)
    staticsByName[template.units[1].name] = deepCopy(template)
end

-------------------------------------------

function Spawn:SpawnToWorld()
    self._spawnTemplate = deepCopy(self.baseTemplate)
    self:_InitializeTemplate()
    return self
end

--[[ Respawn the object
- @param #Spawn self
- @return #Spawn self
]]
function Spawn:Respawn()
    self:_AddToWorld()
    return self
end

function Spawn:SpawnFromTemplate(template, country, category, static)
    if static then
        local staticObject = addStaticObject(country, template)
        template.countryId = country
        self:AddStaticTemplate(template)
        return staticObject
    else
        local group = addGroup(country, category, template)
        template.countryId = country
        template.categoryId = category
        self:AddGroupTemplate(template)
        return group
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
    local zone = self:GetZoneTemplate(zoneName)
    local spawnZoneVec3 = zone.vec3
    local spawnZoneRadius = zone.radius
    local radius = spawnZoneRadius * 0.75
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
    self:_InitializeTemplate()
    return self
end

function Spawn:SpawnFromAirbaseRunway(airbaseName, spots)
    self:SpawnFromAirbase(airbaseName, Spawn.Takeoff.FromRunway, spots)
    return self
end

function Spawn:SpawnFromAirbaseParkingHot(airbaseName, spots)
    self:SpawnFromAirbase(airbaseName, Spawn.Takeoff.FromParkingHot, spots)
    return self
end

function Spawn:SpawnFromAirbaseParkingCold(airbaseName, spots)
    self:SpawnFromAirbase(airbaseName, Spawn.Takeoff.FromParkingCold, spots)
    return self
end

function Spawn:SpawnFromAirbase(airbaseName, takeoff, spots)
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
        if spots then
            if type(spots) ~= "table" and type(spots) == "number" then
                spots = {spots}
            end
            local terminalData = self:GetTerminalData(airbaseName, spots)
            self._spawnTemplate.route.points[1].x = terminalData[1].termVec3.x
            self._spawnTemplate.route.points[1].y = terminalData[1].termVec3.z
            for unitId, unitData in ipairs(self._spawnTemplate.units) do
                unitData.parking = terminalData[unitId].termIndex
                unitData.x = terminalData[unitId].termVec3.x
                unitData.y = terminalData[unitId].termVec3.z
            end
        else
            self._spawnTemplate.route.points[1].x = spawnAirbaseVec3.x
            self._spawnTemplate.route.points[1].y = spawnAirbaseVec3.z
        end
        self:_InitializeTemplate()
        return self
    end
end

-------------------------------------------

function Spawn:_InitializeTemplate()
    self:_InitializeNames()
    self:_AddToWorld()
    return self
end

function Spawn:_InitializeNames()
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

function Spawn:_AddToWorld()
    if self.staticTemplate then
        self.DCSStaticObject = addStaticObject(self.countryId, self._spawnTemplate.units[1])
        self.spawnCount = self.spawnCount + 1
        self:Debug("Spawn:_AddToWorld() | %s has been added into the world", self._spawnTemplate.units[1].name)
        self:AddStaticTemplate(self._spawnTemplate)
    else
        if self.payload then
            self._spawnTemplate.units[self.payloadId].payload = self.payload
        end
        if self.livery then
            self._spawnTemplate.units[self.liveryId].livery_id = self.payload
        end
        self.DCSGroup = addGroup(self.countryId, self.categoryId, self._spawnTemplate)
        self.spawnCount = self.spawnCount + 1
        self:Debug("Spawn:_AddToWorld() | %s has been added into the world", self._spawnTemplate.name)
        self:AddGroupTemplate(self._spawnTemplate)
    end
    if self.scheduledFunction then
        self:SpawnScheduled()
    end
    return self
end

-------------------------------------------

do
-------------------------------------------

    function deepCopy(object)
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

    function inherit(child, parent)
        local Child = deepCopy(child)
        setmetatable(child, {__index = parent})
        return Child
    end

-------------------------------------------

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
            logwrite(self.Source, log[data.level], format(message, ...))
        end
    end

-------------------------------------------

    local categoryId = {
        ["plane"] = Group.Category.AIRPLANE,
        ["helicopter"] = Group.Category.HELICOPTER,
        ["vehicle"] = Group.Category.GROUND,
        ["ship"] = Group.Category.SHIP,
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
            zonesByName[zoneData.name].vec3 = {}
            zonesByName[zoneData.name].vec3.x = zoneData.x
            zonesByName[zoneData.name].vec3.y = land.getHeight({x = zoneData.x, y = zoneData.y})
            zonesByName[zoneData.name].vec3.z = zoneData.y
        end
    end
end

Spawn:Info("successfully loaded version %s", Spawn.Version)

-------------------------------------------
-- testing

--local spawnGroup = Spawn:NewFromTemplate(Spawn:GetGroupTemplate("hog"))
--spawnGroup:SpawnToWorld()

--Spawn:New("tank-1"):SpawnFromZoneOnNearestRoad("spawn zone") -- will spawn outside of the zone

--Spawn:New("tank-2"):SpawnFromZone("spawn zone")
--[[
local spawnUnit = Spawn:NewFromVarargs({
    staticTemplate = true,
    name = "Test Unit",
    type = "Workshop A",
    countryId = country.id.USA,
    category = "Fortifications",
    shapeName = "tec_A",
})
spawnUnit:SpawnFromZone("spawn zone")
]]
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
local spawn = Spawn:New("static unit")
spawn:SpawnScheduled(Spawn.SpawnFromRandomVec3InZone, {spawn, "static spawn"}, 5)
