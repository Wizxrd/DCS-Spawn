local addGroup = coalition.addGroup
local addStaticObject = coalition.addStaticObject
local scheduleFunction = timer.scheduleFunction
local getModelTime = timer.getTime
local logwrite = log.write
local format = string.format
local deepCopy
local inherit
local database = {
    ["groupsByName"] = {},
    ["unitsByName"] = {},
    ["staticsByName"] = {},
    ["zonesByName"] = {}
}

Spawn = {}

-- # ***Class***: Spawn
--
-- ***Author:*** Wizard
--
-- ***Created:*** June 7th, 2022
--
-- ***Version:*** 0.0.1
--
-- ***Description:***
-- A dynamic spawn class for groups, units, and statics in DCS World
--
-- ***Features:***
-- * Object Orientated
-- * Integrated Logging
-- * Spawn objects from late activated templates
-- * Spawn objects from custom templates
-- * Spawn objects from a variable amount of arguments
-- * Spawn with original group and unit names
-- * Spawn with a new nickname for the group and its units
-- * Spawn with a set schedule on repeat
-- * Spawn units with different payloads
-- * Spawn units with different liverys
-- * Spawn from a template
-- * Spawn from a zone
-- * Spawn from a zone on the nearest road
-- * Spawn from a random zone
-- * Spawn from a Vec3 position
-- * Spawn from a airbase runway
-- * Spawn from a airbase parking spot in a hot configuration
-- * Spawn from a airbase parking spot in a cold configuration
-- * Various `Set` methods to assign data for the templates to spawn with
-- * Various `Get` methods to acquire data from templates like payloads and liverys
-- * Get open airbase parking spots as well as get the first open spot with the option to filter terminal types
-- * Mark parking spots at an airbase to determine viable parking spot locations
-- * Add group, unit, and static Templates into the global `Database`
--
-- # ***Methods & Fields***
--
-- ## ***Fields***
--
-- @fields
-- @field Spawn.Version #string [semantic version]
Spawn.Version = "0.0.1"
-- @field Spawn.Source #string [script source for dcs.log prefix]
Spawn.Source = "Spawn.lua"
-- @field Spawn.DebugLevel #number [the max log level ]
Spawn.DebugLevel = 5
-- @field Spawn.DebugLevels #table [log level enumerators ]
Spawn.DebugLevels = {
    ["Alert"]   = 1,
    ["Error"]   = 2,
    ["Warning"] = 3,
    ["Info"]    = 4,
    ["Debug"]   = 5

}
-- @field Spawn.Category #table [enumerators for spawn group categories]
Spawn.Category = {
    ["Airplane"] = Group.Category.AIRPLANE,
    ["Helicopter"] = Group.Category.HELICOPTER,
    ["Vehicle"] = Group.Category.GROUND,
    ["Ship"] = Group.Category.SHIP,
}
-- @field Spawn.Takeoff #table [enumerators for taking off from an airbase]
Spawn.Takeoff = {
    ["FromRunway"] =      {name = "Takeoff from runway",      type = "TakeOff",           action = "From Runway"},
    ["FromParkingHot"] =  {name = "Takeoff from parking hot", type = "TakeOffParkingHot", action = "From Parking Area Hot"},
    ["FromParkingCold"] = {name = "Takeoff from parking",     type = "TakeOffParking",    action = "From Parking Area"}
}
-- @field Spawn.Skill #table [enumerators for skills]
Spawn.Skill = {
    ["Average"] = "Average",
    ["Good"] = "Good",
    ["High"] = "High",
    ["Excellent"] = "Excellent",
    ["Random"] = "Random"
}
-- @field Spawn.Waypoint #table [enumerators for waypoints]
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
--
-- ## ***Methods***
--
--- Create a new instance of a spawn object by name  
-- @param #Spawn self <*>  
-- @param #string templateName <*> [the group, unit, or static name of the ME Template]  
-- @param #string nickname [optional nickname the Spawn object will use instead of its template name]  
-- @return #Spawn self  
-- @usage  
-- local HornetSpawn = Spawn:New("Hornet Group")  
function Spawn:New(templateName, nickname)
    local self = inherit(self, Spawn)
    self.baseTemplate, self.staticTemplate = self:GetTemplate(templateName)
    if not self.baseTemplate then
        self:Error("Spawn:New() | couldn't find template %s in database", templateName)
        return self
    end
    self.templateName = templateName
    self.nickname = nickname

    self.spawnCount = 0

    self.countryId = self.baseTemplate.countryId
    self.categoryId = self.baseTemplate.categoryId

    self.spawnedGroups = {}
    self.spawnedStatics = {}

    self.aliveGroups = {}
    self.aliveUnits = {}
    self.aliveStatics = {}

    return self
end

--- Create a new instance of a Spawn object from a template  
-- @param #Spawn self <*>  
-- @param #table template <*> [the template table with required data for spawning]  
-- @param #string nickname [optional nickname the Spawn object will use instead of its template name]  
-- @param #boolean staticTemplate [optional boolean if the template is a static object]  
-- @return #Spawn self  
-- @usage  
-- local ViperGroupTemplate = Spawn:GetGroupTemplate("Viper Group")  
-- local ViperSpawn = Spawn:NewFromTemplate(ViperGroupTemplate)  
--  
-- local StaticDepotSpawn = Spawn:NewFromTemplate(Spawn:GetStaticTemplate("Static Depot"), nil, true)  
function Spawn:NewFromTemplate(template, nickname, staticTemplate)
    local self = inherit(self, Spawn)
    self.baseTemplate = deepCopy(template)
    self.staticTemplate = staticTemplate

    self.templateName = self.baseTemplate.name
    self.nickname = nickname

    self.spawnCount = 0

    self.countryId = self.baseTemplate.countryId
    self.categoryId = self.baseTemplate.categoryId

    self.spawnedGroups = {}
    self.spawnedStatics = {}

    self.aliveGroups = {}
    self.aliveUnits = {}
    self.aliveStatics = {}

    return self
end

--- Create a new instance of a Spawn object from a table of properties  
-- **Required Unit Properties:**  
-- * type
-- * countryId
-- * categoryId
--
-- **Required Static Properties:**
-- * category
-- * shapeName
-- * staticTemplate
--
-- **Optional Properties:**
-- * skill
-- * canDrive
-- * alt
-- * altType
-- * heading
-- * action
-- * name
-- * waypoint
--
-- @param #Spawn self <*>  
-- @param #table properties <*> [table of properties to give to the Spawn object]  
-- @return #Spawn self  
-- @usage  
-- -- Tank Unit  
-- local TankProperties = {}  
-- TankProperties.type = "T-90" -- type required  
-- TankProperties.countryId = country.id.RUSSIA -- countryId required  
-- TankProperties.categoryId = Spawn.Category.Vehicle -- categoryId required  
--  
-- -- Static Tank  
-- local StaticTankProperties = {}  
-- StaticTankProperties.type = "T-90" -- type required  
-- StaticTankProperties.countryId = country.id.RUSSIA -- countryId required  
-- StaticTankProperties.category = "" -- category required  
-- StaticTankProperties.shapeName = "" -- shapeName required  
function Spawn:NewFromTable(properties)
    local spawnTemplate
    if properties.staticTemplate then
        spawnTemplate = self:GetStaticSpawnTemplate()
        spawnTemplate.countryId = properties.countryId
        spawnTemplate.units[1].category = properties.category
        spawnTemplate.units[1].shape_name = properties.shapeName
        spawnTemplate.units[1].type = properties.type
        spawnTemplate.units[1].heading = properties.heading or 0
    else
        spawnTemplate = self:GetSpawnTemplate()
        spawnTemplate.countryId = properties.countryId
        spawnTemplate.categoryId = properties.categoryId
        spawnTemplate.name = properties.name or properties.type
        if properties.units then
            spawnTemplate.units = properties.units
        else
            spawnTemplate.units[1].type = properties.type
            spawnTemplate.units[1].skill = properties.skill or "Random"
            spawnTemplate.units[1].heading = properties.heading * math.pi / 180 or 0
            spawnTemplate.units[1].playerCanDrive = properties.canDrive or false
        end
        spawnTemplate.route.points[1].alt = properties.alt or 0
        spawnTemplate.route.points[1].alt_type = properties.altType or "BARO"
        if properties.waypoint then
            spawnTemplate.route.points[1].type = properties.waypoint.type or "Turning Point"
            spawnTemplate.route.points[1].action = properties.waypoint.action or "Turning Point"
        end
    end
    local self = Spawn:NewFromTemplate(spawnTemplate, properties.nickname, properties.staticTemplate)
    return self
end

--- Set the Spawn object to keep group or unit names  
-- @param #Spawn self <*>  
-- @param #boolean keepGroupName [true or false to keep the group name of the template]  
-- @param #boolean keepUnitNames [true or false to keep all the unit names for the group template]  
-- @return #Spawn self  
-- @usage  
-- local TankSpawn = Spawn:New("Tank Group")  
-- TankSpawn:SetKeepNames(true, true)  
function Spawn:SetKeepNames(keepGroupName, keepUnitNames)
    self.keepGroupName = keepGroupName
    self.keepUnitNames = keepUnitNames
    return self
end

--- Set the Spawn object to only allow a certain amount of groups and units to be alive  
-- @param #Spawn self <*>  
-- @param #number maxAliveGroups <*> [the max amount of groups that can be alive at a given time]  
-- @param #number maxAliveUnits <*> [the max amount of unit that can be alive at a given time]  
-- @return #Spawn self  
-- @usage  
-- local TankSpawn = Spawn:New("Tank Group")  
-- TankSpawn:SetMaxAlive(2, 2)  
function Spawn:SetMaxAlive(maxAliveGroups, maxAliveUnits)
    self.maxAliveGroups = maxAliveGroups
    self.maxAliveUnits = maxAliveUnits
    return self
end

--- Set the Spawn object to use a certain heading  
-- converts a degree heading into radians  
-- @param #Spawn self <*>  
-- @param #number heading <*> [the heading to give to the group or a unit at spawn time]  
-- @param #number unitId [optional unitId to provide for a specific unit within the group]  
-- @return #Spawn self  
-- @usage  
-- local TankSpawn = Spawn:New("Tank Group")  
-- TankSpawn:SetHeading(90, 2)  
function Spawn:SetHeading(heading, unitId)
    self.heading = heading * math.pi / 180
    self.headingId = unitId
    return self
end

--- Set the spawn object to spawn from a vec3  
-- @param #Spawn self <*>  
-- @param #table vec3 <*> [the vec3 point to spawn at]  
-- @param #number alt <*> [required for airplanes and helicopters only]  
-- @return #Spawn self  
-- @usage  
-- local TankSpawn = Spawn:New("Tank Group")  
-- TankSpawn:SetSpawnVec3(Spawn:GetZoneVec3("spawn zone"))  
function Spawn:SetSpawnVec3(vec3, alt)
    self.spawnVec3 = vec3
    self.spawnVec3Alt = alt
    return self
end

--- Set the Spawn object to spawn from a zone  
-- @param #Spawn self <*>  
-- @param #string zoneName <*> [the name of the trigger zone to spawn at]  
-- @param #number alt <*> [required for airplanes and helicopters only]  
-- @return #Spawn self  
-- @usage  
-- local TankSpawn = Spawn:New("Tank Group")  
-- TankSpawn:SetSpawnZone("spawn zone")  
function Spawn:SetSpawnZone(zoneName, alt)
    self.spawnZoneName = zoneName
    self.spawnZoneAlt = alt
    return self
end

--- Set the Spawn object to spawn from a airbase  
-- @param #Spawn self <*>  
-- @param #string airbaseName <*> [the airbase name as seen in DCS to spawn at]  
-- @param #enum takeoff <*> [use: `Spawn.Takeoff`]  
-- @param #array spots [optional parking spots to provide, otherwise they will be decided by DCS.]  
-- You can use `Spawn:GetFreeParkingSpots(airbaseName)` obtain useable spots.  
-- @return #Spawn self  
-- @usage  
-- local HornetSpawn = Spawn:New("Hornet Group")  
-- HornetSpawn:SetSpawnAirbase("Aleppo", Spawn.Takeoff.FromParkingHot)  
function Spawn:SetSpawnAirbase(airbaseName, takeoff, spots)
    self.spawnAirbaseName = airbaseName
    self.spawnAirbaseTakeoff = takeoff
    self.spawnAirbaseSpots = spots
    return self
end

--- Set the Spawn object to spawn from a random template  
-- @param #Spawn self <*>  
-- @param #array templateList <*> [a list of template names where one will be randomly selected each time it spawns]  
-- @return #Spawn self  
-- @usage  
-- local spawnList = {  
--     "Tank Group 1",  
--     "Tank Group 2",  
--     "Tank Group 3",  
--     "Tank Group 4",  
-- }  
-- local TankSpawn = Spawn:New("Tank Group")  
-- TankSpawn:SetRandomFromTemplate(spawnList)  
function Spawn:SetRandomFromTemplate(templateList)
    self.randomTemplate = true
    self.templateList = templateList
    return self
end

--- Set the Spawn objects nickname  
-- @param #Spawn self <*>  
-- @param #string nickname <*> [will be used over the template name, unit names will be followed by -Id]  
-- @return #Spawn self  
-- @usage  
-- local HornetSpawn = Spawn:New("Hornet Group")  
-- HornetSpawn:SetNickname("Hornet CAP")  
function Spawn:SetNickname(nickname)
    self.nickname = nickname
    return self
end

--- Set the Spawn object to use a new paylaod  
-- @param #Spawn self <*>  
-- @param #table payload <*> [payload to provide to the group or a specifc unit. airplanes and helicopters only.]  
-- the return of `Spawn:GetPayload(unitName)` can be used.  
-- @param #number unitId [optional unit Id to set the payload for a specifc unit within the group]  
-- @return #Spawn self  
-- @usage  
-- local HornetSpawn = Spawn:New("Hornet Group")  
-- HornetSpawn:SetPayload("Hornet CAP")  
function Spawn:SetPayload(payload, unitId)
    self.payload = payload
    self.payloadId = unitId
    return self
end

--- Set the Spawn object to use a new livery  
-- @param #Spawn self <*>  
-- @param #string livery <*> [livery name to provide to the group or specific unit.]  
-- the return of `Spawn:GetLivery(unitName)` can be used.  
-- @param #number unitId [optional unit Id to set the livery for a specifc unit within the group]  
-- @return #Spawn self  
-- @usage  
-- local HornetSpawn = Spawn:New("Hornet Group")  
-- HornetSpawn:SetLivery("Hornet CAP")  
function Spawn:SetLivery(liveryName, unitId)
    self.livery = liveryName
    self.liveryId = unitId
    return self
end

--- Set the Spawn object to use a new skill level  
-- @param #Spawn self <*>  
-- @param #string skill <*> [skill level than can be used, can also use `Spawn.Skill`]  
-- @param #number unitId [optional unit Id to set the skill for a specific unit]  
-- @return #Spawn self  
-- @usage  
-- local HornetSpawn = Spawn:New("Hornet Group")  
-- HornetSpawn:SetSkill(Spawn.Skill.Random)  
function Spawn:SetSkill(skill, unitId)
    self.skill = skill
    self.skillId = unitId
    return self
end

--- Set the Spawn object to use a certain debug level  
-- @param #Spawn self <*>  
-- @param #number level <*> [max debug level where only set level and below will be used. can use `Spawn.DebugLevel`]  
-- @return #Spawn self  
-- @usage  
-- local HornetSpawn = Spawn:New("Hornet Group")  
-- HornetSpawn:SetDebugLevel(Spawn.DebugLevel.Info)  
function Spawn:SetDebugLevel(level)
    if type(level) == "string" then
        self.DebugLevel = Spawn.DebugLevels[level]
    elseif type(level) == "number" then
        self.DebugLevel = level
    end
    return self
end

--- Set the Spawn object to use a specific method for spawning on a repeating schedule  
-- @param #Spawn self <*>  
-- @param #function method <*> [the spawn method that will be scheduled]  
-- @param #array params [the parameters to give to the method]
-- @param #number delay <*> the delay in seconds
-- @return #Spawn self
-- -- spawns the group from a zone every 300 seconds
-- local HornetSpawn = Spawn:New("Hornet Group")  
-- HornetSpawn:SetScheduler(Spawn.SpawnFromZone, {HornetSpawn, "spawn zone", 5000}, 300)
-- HornetSpawn:SpawnFromZone("spawn zone", 5000)
function Spawn:SetScheduler(method, params, delay)
    self.scheduledSpawn = true
    self.scheduledMethod = method
    self.scheduledParams = params
    self.scheduledDelay = delay
    return self
end

--- Set a spawn hook to capture the event of spawning  
-- @param #string spawnHook <*> [the name of the method to callback to upon spawning]  
-- @return #Spawn self  
-- @usage  
-- local HornetSpawn = Spawn:New("Hornet Group")  
-- HornetSpawn:SetSpawnHook("OnEventSpawn")  
-- function HornetSpawn:OnEventSpawn(spawnData)
--     self:Info("%s has spawned", spawnData.GroupName)
-- end
-- HornetSpawn:SpawnToWorld()
function Spawn:SetSpawnHook(spawnHook)
    self.spawnHook = spawnHook
    return self
end

--- Get the currently spawned DCS Class Group  
-- @param #Spawn self <*>  
-- @return #DCSGroup self  
-- @usage  
-- local HornetSpawn = Spawn:New("Hornet Group")  
-- HornetSpawn:SpawnToWorld()  
-- local SpawnedGroup = HornetSpawn:GetSpawnedGroup()  
function Spawn:GetSpawnedGroup()
    return self.spawnedGroup
end

--- Get the currently spawned DCS Class StaticObject  
-- @param #Spawn self <*>  
-- @return #DCSStaticObject self  
-- @usage  
-- local CrateSpawn = Spawn:New("Static Crate")  
-- CrateSpawn:SpawnToWorld()  
-- local SpawnedStatic = CrateSpawn:GetSpawnedStatic()  
function Spawn:GetSpawnedStatic()
    return self.spawnedStatic
end

--- Get a payload table from a unit by name  
-- @param #Spawn self <*>  
-- @param #string unitName <*> [the name of a unit in the database to get a payload table from]
-- @return #table payload
-- @usage
-- local CapPayload = Spawn:GetPayload("CAP Payload")
-- local HornetSpawn = Spawn:New("Hornet Group")  
-- HornetSpawn:SetPayload(CapPayload)
-- HornetSpawn:SpawnToWorld()  
function Spawn:GetPayload(unitName)
    if Database.unitsByName[unitName] then
        local payload = deepCopy(Database.unitsByName[unitName].payload)
        return payload
    end
end

--- Get a livery name from a unit by name
-- @param #Spawn self <*>
-- @param #string unitName
-- @return #string liveryName
function Spawn:GetLiveryName(unitName)
    if Database.unitsByName[unitName] then
        local liveryName = Database.unitsByName[unitName].livery_id
        return liveryName
    end
end

--- Get a group template by name
-- @param #Spawn self <*>
-- @param #string groupName
-- @return #table groupTemplate
function Spawn:GetGroupTemplate(groupName)
    if Database.groupsByName[groupName] then
        return deepCopy(Database.groupsByName[groupName])
    end
end

--- Get a unit template by name
-- @param #Spawn self <*>
-- @param #string unitName
-- @return #table unitTemplate
function Spawn:GetUnitTemplate(unitName)
    if Database.unitsByName[unitName] then
        return deepCopy(Database.unitsByName[unitName])
    end
end

--- Get a static template by name
-- @param #Spawn self <*>
-- @param #string staticName
-- @return #table staticTemplate
function Spawn:GetStaticTemplate(staticName)
    if Database.staticsByName[staticName] then
        return deepCopy(Database.staticsByName[staticName])
    end
end

--- Get a template by name
-- this function also returns a second boolean variable if the template is static
-- @param #Spawn self <*>
-- @param #string templateName
-- @return #table template
function Spawn:GetTemplate(templateName)
    if Database.groupsByName[templateName] then
        self:Info("Spawn:GetTemplate() | returning group template: "..templateName)
        return deepCopy(Database.groupsByName[templateName])
    elseif Database.unitsByName[templateName] then
        self:Info("Spawn:GetTemplate() | returning unit template: "..templateName)
        return deepCopy(Database.unitsByName[templateName])
    elseif Database.staticsByName[templateName] then
        self:Info("Spawn:GetTemplate() | returning static template: "..templateName)
        return deepCopy(Database.staticsByName[templateName]), true
    end
end

--- Get the Spawn objects base template
-- @param #Spawn self <*>
-- @return #table baseTemplate, #boolean staticTemplate
function Spawn:GetBaseTemplate()
    local baseTemplate, staticTemplate = self.baseTemplate, self.staticTemplate
    if self.randomTemplate then
        local randomKey = math.random(1, #self.templateList)
        local templateName = self.templateList[randomKey]
        baseTemplate, staticTemplate = self:GetTemplate(templateName)
    end
    return deepCopy(baseTemplate), staticTemplate
end

--- Get a empty spawn table for groups and units
-- @param #Spawn self <*>
-- @return #table spawnTemplate
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

--- Get a empty spawn table for statics
-- @param #Spawn self <*>
-- @return #table staticSpawnTemplate
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

--- Get a zone template by name
-- @param #Spawn self <*>
-- @param #string zoneName
-- @return #table zoneTemplate
function Spawn:GetZoneTemplate(zoneName)
    if Database.zonesByName[zoneName] then
        return deepCopy(Database.zonesByName[zoneName])
    end
end

--- Get a quad zones points by name
-- @param #Spawn self <*>
-- @param #string zoneName
-- @return #table points
function Spawn:GetQuadZonePoints(zoneName)
    local zoneTemplate = self:GetZoneTemplate(zoneName)
    if zoneTemplate then
        if zoneTemplate.type == 2 then
            local points = deepCopy(zoneTemplate.vertices)
            return points
        end
    end
end

--- Get a zones radius by name
-- @param #Spawn self <*>
-- @param #string zoneName
-- @return #number self radius
function Spawn:GetZoneRadius(zoneName)
    local zoneTemplate = self:GetZoneTemplate(zoneName)
    if zoneTemplate then
        if zoneTemplate.type == 0 then
            local radius = deepCopy(zoneTemplate.radius)
            return radius
        end
    end
end

--- Get a zones vec3 points by name
-- @param #Spawn self <*>
-- @param #string zoneName
-- @return #table vec3
function Spawn:GetZoneVec3(zoneName)
    local zone = self:GetZoneTemplate(zoneName)
    if zone then
        local vec3 = deepCopy(zone.vec3)
        return vec3
    end
end

--- Get all the open parking spots at an airbase by name
-- @param #Spawn self <*>
-- @param #string airbaseName
-- @param #number terminalType
-- @return #table openParkingSpots
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

--- Get the first open parking spot an airbase by name
-- @param #Spawn self <*>
-- @param #string airbaseName
-- @param #number terminalType
-- @return #table openSpot
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

--- Get the the terminal data from an airbase by name
-- @param #Spawn self <*>
-- @param #string airbaseName
-- @param #number spots
-- @return #table terminalData
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

--- Get a DCS Group object by its spawn index
-- @param #Spawn self <*>
-- @param #number spawnIndex
-- @return #DCSGroup self
function Spawn:GetGroupFromIndex(spawnIndex)
    self:Alert(spawnIndex)
    local groupName = self.spawnedGroups[spawnIndex]
    return Group.getByName(groupName)
end

--- Get a DCS StaticObject by its spawn index
-- @param #Spawn self <*>
-- @param #number spawnIndex
-- @return #DCSStaticObject self
function Spawn:GetStaticFromIndex(spawnIndex)
    local staticName = self.spawnedStatics[spawnIndex]
    return StaticObject.getByName(staticName)
end

--- Return true or false if the current Spawn obejct is alive
-- @param #Spawn self <*>
-- @return #boolean alive
function Spawn:IsAlive()
    if self.staticTemplate then
        return self:IsStaticAlive()
    end
    return self:IsGroupAlive()
end

--- Return true or false if the current Spawn group object is alive
-- @param #Spawn self <*>
-- @return #boolean isAlive
function Spawn:IsGroupAlive()
    local spawnedGroup = Group.getByName(self.spawnedGroupName)
    if spawnedGroup then
        local spawnedUnit = spawnedGroup:getUnit(1)
        if spawnedUnit:isExist() then
            if spawnedUnit:isActive() then
                if spawnedUnit:getLife() > 0 then
                    return true
                end
            end
        end
    end
    return false
end

--- Return true or false if the current Spawn static object is alive
-- @param #Spawn self <*>
-- @return #boolean isAlive
function Spawn:IsStaticAlive()
    local spawnedStatic = StaticObject.getByName(self.spawnedStaticName)
    if spawnedStatic then
        if spawnedStatic:isExist() then
            if spawnedStatic:getLife() > 0 then
                return true
            end
        end
    end
    return false
end

--- Mark the parking spots at an airbase by name
-- @param #Spawn self <*>
-- @param #string airbaseName
-- @return none
function Spawn:MarkParkingSpots(airbaseName)
    local airbase = Airbase.getByName(airbaseName)
    if airbase then
        for _, spot in pairs(airbase:getParking()) do
            trigger.action.markToAll(-1, "Terminal Type: "..spot.Term_Type.."\nTerminal Index: "..spot.Term_Index, spot.vTerminalPos)
        end
    end
end

--- Add a group template to the database
-- @param #Spawn self <*>
-- @param #table template
-- @return none
function Spawn:AddGroupTemplate(template)
    Database.groupsByName[template.name] = deepCopy(template)
    for _, unitTemplate in pairs(template.units) do
        self:AddUnitTemplate(unitTemplate)
    end
end

--- Add a unit template to the database
-- @param #Spawn self <*>
-- @param #table template
-- @return none
function Spawn:AddUnitTemplate(template)
    Database.unitsByName[template.name] = deepCopy(template)
end

--- Add a static template to the database
-- @param #Spawn self <*>
-- @param #table template
-- @return none
function Spawn:AddStaticTemplate(template)
    Database.staticsByName[template.units[1].name] = deepCopy(template)
end

--- Spawn the object to the world
-- @param #Spawn self <*>
-- @return #Spawn self
function Spawn:SpawnToWorld()
    self._spawnTemplate, self.staticTemplate = self:GetBaseTemplate()
    self:_InitializeTemplate()
    return self
end

--- Spawn an object with a spawn method to be scheduled
-- @param #Spawn self <*>
-- @param #function method
-- @param #array params
-- @param #number delay
-- @return none
function Spawn:SpawnScheduled(method, params, delay)
    method = self.scheduledMethod or method
    params = self.scheduledParams or params
    delay = self.scheduledDelay or delay
    scheduleFunction(function() method(unpack(params)) end, nil, getModelTime() + delay)
    return self
end

function Spawn:SpawnLateActivated()
    self._spawnTemplate, self.staticTemplate = self:GetBaseTemplate()
    self._spawnTemplate.lateActivation = true
    self:_InitializeTemplate()
    return self
end

--- Respawn the object
-- @param #Spawn self <*>
-- @return #Spawn self
function Spawn:Respawn()
    self:_AddToWorld()
    return self
end

--- Spawn an object from a template
-- @param #Spawn self <*>
-- @param #table template
-- @param #number countryId
-- @param #number categoryId
-- @param #boolean static
-- @return #Spawn self
function Spawn:SpawnFromTemplate(template, countryId, categoryId, static)
    if static then
        local spawnedStatic = addStaticObject(countryId, template)
        template.countryId = countryId
        self:AddStaticTemplate(template)
    else
        local spawnedGroup = addGroup(countryId, categoryId, template)
        template.countryId = countryId
        template.categoryId = categoryId
        self:AddGroupTemplate(template)
    end
    local self = Spawn:New(template.name)
    return self
end

--- Spawn an object from a zone by name
-- @param #Spawn self <*>
-- @param #string zoneName
-- @param #number alt
-- @return #Spawn self
function Spawn:SpawnFromZone(zoneName, alt)
    zoneName = zoneName or self.spawnZoneName
    alt = alt or self.spawnZoneAlt
    local spawnZoneVec3 = self:GetZoneVec3(zoneName)
    self:SpawnFromVec3(spawnZoneVec3, alt)
    return self
end

--- Spawn an object from a zone on the nearest road
-- @param #Spawn self <*>
-- @param #string zoneName
-- @return #Spawn self
function Spawn:SpawnFromZoneOnNearestRoad(zoneName)
    local spawnZoneVec3 = self:GetZoneVec3(zoneName)
    self:SpawnFromVec3OnNearestRoad(spawnZoneVec3)
    return self
end

--- Spawn an object from a random zone from a list
-- @param #Spawn self <*>
-- @param #array zoneList
-- @param #number alt
-- @return #Spawn self
function Spawn:SpawnFromRandomZone(zoneList, alt)
    local randomNum = math.random(1, #zoneList)
    local randomZone = zoneList[randomNum]
    self:SpawnFromZone(randomZone, alt)
    return self
end

--- Spawn an object from a random vec3 in a zone
-- @param #Spawn self <*>
-- @param #string zoneName
-- @param #number alt
-- @return #Spawn self
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

--- Spawn an object from a random vec3 within a random radius
-- @param #Spawn self <*>
-- @param #table vec3
-- @param #number minRadius
-- @param #number maxRadius
-- @param #number alt
-- @return #Spawn self
function Spawn:SpawnFromRandomVec3InRadius(vec3, minRadius, maxRadius, alt)
    local vec3 = deepCopy(vec3)
    local radius = math.random(minRadius, maxRadius)
    radius = radius * 0.75
    vec3.x = vec3.x + math.random(radius * -1, radius)
    vec3.z = vec3.z + math.random(radius * -1, radius)
    self:SpawnFromVec3(vec3, alt)
    return self
end

--- Spawn an object from a vec3 on the nearest road
-- @param #Spawn self <*>
-- @param #table vec3
-- @return #Spawn self
function Spawn:SpawnFromVec3OnNearestRoad(vec3)
    local x, z = land.getClosestPointOnRoads("roads", vec3.x, vec3.z)
    vec3.x = x
    vec3.z = z
    self:SpawnFromVec3(vec3)
    return self
end

--- Spawn an object from a vec3
-- @param #Spawn self <*>
-- @param #table vec3
-- @return #Spawn self
function Spawn:SpawnFromVec3(vec3, alt)
    self._spawnTemplate, self.staticTemplate = self:GetBaseTemplate()
    vec3 = vec3 or self.spawnVec3
    alt = alt or self.spawnVec3Alt
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

--- Spawn an object from a airbase on the runway
-- @param #Spawn self <*>
-- @param #string airbaseName
-- @param #array spots
-- @return #Spawn self
function Spawn:SpawnFromAirbaseRunway(airbaseName, spots)
    self:SpawnFromAirbase(airbaseName, Spawn.Takeoff.FromRunway, spots)
    return self
end

--- Spawn an object at an airbase in a parking spot hot
-- @param #Spawn self <*>
-- @param #string airbaseName
-- @param #array spots
-- @return #Spawn self
function Spawn:SpawnFromAirbaseParkingHot(airbaseName, spots)
    self:SpawnFromAirbase(airbaseName, Spawn.Takeoff.FromParkingHot, spots)
    return self
end

--- Spawn an object at an airbase in a parking spot cold
-- @param #Spawn self <*>
-- @param #string airbaseName
-- @param #array spots
-- @return #Spawn self
function Spawn:SpawnFromAirbaseParkingCold(airbaseName, spots)
    self:SpawnFromAirbase(airbaseName, Spawn.Takeoff.FromParkingCold, spots)
    return self
end

--- Spawn an object at an airbase with any takeoff type and any spots
-- @param #Spawn self <*>
-- @param #string airbaseName
-- @param #enum takeoff
-- @param #array spots
-- @return #Spawn self
function Spawn:SpawnFromAirbase(airbaseName, takeoff, spots)
    self._spawnTemplate, self.staticTemplate = self:GetBaseTemplate()
    airbaseName = airbaseName or self.spawnAirbaseName
    takeoff = takeoff or self.spawnAirbaseTakeoff
    spots = spots or self.spawnAirbaseSpots
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

--- Initializes the templates
-- @param #Spawn self <*>
-- @return #Spawn self
function Spawn:_InitializeTemplate()
    self:_InitializeNames()
    self:_AddToWorld()
    return self
end

--- Initialize the templates group and unit names
-- @param #Spawn self <*>
-- @return #Spawn self
function Spawn:_InitializeNames()
    if not self.keepGroupName then
        if self.nickname then
            self._spawnTemplate.name = self.nickname
        else
            self._spawnTemplate.name = self._spawnTemplate.name.." #"..self.spawnCount + 1
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
 
function Spawn:_WithinAliveLimit()
    if self.staticTemplate then
        if self.maxAliveGroups then
            self:_UpdateAliveStatics()
            if #self.activeStatics + 1 > self.maxAliveGroups then
                return false
            end
        end
    else
        if self.maxAliveGroups then
            self:_UpdateAliveGroups()
            if #self.aliveGroups + 1 > self.maxAliveGroups then
                return false
            end
        end
        if self.maxAliveUnits then
            self:_UpdateAliveUnits()
            if #self.aliveUnits + #self._spawnTemplate.units > self.maxAliveUnits then
                return false
            end
        end
    end
    return true
end

function Spawn:_SetPayload()
    if self.payload then
        if self.payloadId then
            self._spawnTemplate.units[self.payloadId].payload = self.payload
        else
            for i = 1, #self._spawnTemplate.units do
                self._spawnTemplate.units[i].payload = self.payload
            end
        end
    end
    return self
end

function Spawn:_SetSkill()
    if self.skill then
        if self.skillId then
            self._spawnTemplate.units[self.skillId].skill = self.skill
        else
            for i = 1, #self._spawnTemplate.units do
                self._spawnTemplate.units[i].skill = self.skill
            end
        end
    end
    return self
end

function Spawn:_SetLivery()
    if self.livery then
        if self.liveryId then
            self._spawnTemplate.units[self.liveryId].livery_id = self.livery
        else
            for i = 1, #self._spawnTemplate.units do
                self._spawnTemplate.units[i].livery_id = self.livery
            end
        end
    end
    return self
end

function Spawn:_SetHeading()
    if self.heading then
        if self.headingId then
            self._spawnTemplate.units[self.liveryId].heading = self.heading
        else
            for i = 1, #self._spawnTemplate.units do
                self._spawnTemplate.units[i].heading = self.heading
            end
        end
    end
    return self
end

function Spawn:_AddStaticToWorld()
    if self._spawnTemplate.units[1].category == "Heliports" then
        self.spawnedStatic = addGroup(self.countryId, -1, self._spawnTemplate)
    else
        self.spawnedStatic = addStaticObject(self.countryId, self._spawnTemplate.units[1])
    end
    self:AddStaticTemplate(self._spawnTemplate)
    self.spawnCount = self.spawnCount + 1
    self.spawnedStaticName = self._spawnTemplate.units[1].name
    self.spawnedGroups[self.spawnCount] = self._spawnTemplate.units[1].name
    return self
end

function Spawn:_AddGroupToWorld()
    self.spawnedGroup = addGroup(self.countryId, self.categoryId, self._spawnTemplate)
    self:AddGroupTemplate(self._spawnTemplate)
    self.spawnCount = self.spawnCount + 1
    self.spawnedGroupName = self._spawnTemplate.name
    self.spawnedGroups[self.spawnCount] = self._spawnTemplate.name
    return self
end

--- Add the spawn object into the world
-- @param #Spawn self <*>
-- @return #Spawn self
function Spawn:_AddToWorld()
    if self:_WithinAliveLimit() then
        if self.staticTemplate then
            self:_SetLivery()
            self:_SetHeading()
            self:_AddStaticToWorld()
        else
            self:_SetPayload()
            self:_SetLivery()
            self:_SetSkill()
            self:_SetHeading()
            self:_AddGroupToWorld()
        end
    end
    if self.spawnHook then
        self:_SpawnWithHook()
    end
    if self.scheduledSpawn then
        self:SpawnScheduled()
    end
    return self
end

function Spawn:_SpawnWithHook()
    local spawnEvent = {}
    spawnEvent.SpawnIndex = self.spawnCount
    if self.staticTemplate then
        spawnEvent.StaticObject = self.spawnedStatic
        spawnEvent.StaticObjectName = self._spawnTemplate.units[1].name
        spawnEvent.StaticObjectCountryId = self.countryId
        spawnEvent.StaticObjectCategoryId = self.spawnedStatic:getDesc().category
        spawnEvent.StaticObjectCoalitionId = self.spawnedStatic:getCoalition()
    else
        spawnEvent.Group = self.spawnedGroup
        spawnEvent.GroupName = self._spawnTemplate.name
        spawnEvent.GroupUnits = self.spawnedGroup:getUnits()
        spawnEvent.GroupCountryId = self.countryId
        spawnEvent.GroupCategoryId = self.categoryId
        spawnEvent.GroupCoalitionId = self.spawnedGroup:getCoalition()
    end
    self[self.spawnHook](self, spawnEvent)
    return self
end

function Spawn:_UpdateAliveGroups()
    self.aliveGroups = {}
    for _, groupName in pairs(self.spawnedGroups) do
        local group = Group.getByName(groupName)
        if group then
            local units = group:getUnits()
            for _, unit in pairs(units) do
                if unit:isExist() then
                    if unit:isActive() then
                        if unit:getLife() > 0 then
                            self.aliveGroups[#self.aliveGroups+1] = groupName
                            break
                        end
                    end
                end
            end
        end
    end
    return self
end

function Spawn:_UpdateAliveUnits()
    self.aliveUnits = {}
    self:_UpdateAliveGroups()
    for _, groupName in pairs(self.aliveGroups) do
        local group = Group.getByName(groupName)
        if group then
            local units = group:getUnits()
            for _, unit in pairs(units) do
                if unit:isExist() then
                    if unit:isActive() then
                        if unit:getLife() > 0 then
                            local unitName = unit:getName()
                            self.aliveUnits[#self.aliveUnits+1] = unitName
                        end
                    end
                end
            end
        end
    end
    return self
end

function Spawn:_UpdateAliveStatics()
    self.aliveStatics = {}
    for _, staticName in pairs(self.spawnedStatics) do
        local static = StaticObject.getByName(staticName)
        if static then
            if static:isExist() then
                if static:getLife() > 0 then
                    self.aliveStatics[#self.aliveStatics+1] = staticName
                end
            end
        end
    end
    return self
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

do
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
        setmetatable(Child, {__index = parent})
        return Child
    end

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
                                database.groupsByName[groupData.name] = deepCopy(groupData)
                                database.groupsByName[groupData.name].countryId = countryData.id
                                database.groupsByName[groupData.name].categoryId = categoryId[categoryName]
                                for unitId, unitData in pairs(groupData.units) do
                                    database.unitsByName[unitData.name] = deepCopy(groupData)
                                    database.unitsByName[unitData.name].name = unitData.name
                                    database.unitsByName[unitData.name].units = {}
                                    database.unitsByName[unitData.name].units[1] = deepCopy(unitData)
                                    database.unitsByName[unitData.name].countryId = countryData.id
                                    database.unitsByName[unitData.name].categoryId = categoryId[categoryName]
                                end
                            end
                        elseif categoryName == "static" then
                            for _, staticData in pairs(objectData.group) do
                                local staticName = staticData.units[1].name
                                database.staticsByName[staticName] = deepCopy(staticData)
                                database.staticsByName[staticName].countryId = countryData.id
                            end
                        end
                    end
                end
            end
        end
    end

    for _, zones in pairs(env.mission.triggers) do
        for _, zoneData in pairs(zones) do
            database.zonesByName[zoneData.name] = deepCopy(zoneData)
            database.zonesByName[zoneData.name].vec3 = {}
            database.zonesByName[zoneData.name].vec3.x = zoneData.x
            database.zonesByName[zoneData.name].vec3.y = land.getHeight({x = zoneData.x, y = zoneData.y})
            database.zonesByName[zoneData.name].vec3.z = zoneData.y
        end
    end
end

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

Database = deepCopy(database)
Spawn:Info("successfully loaded version %s", Spawn.Version)