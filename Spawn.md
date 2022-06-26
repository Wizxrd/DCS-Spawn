# ***Class***: Spawn  
  
***Author:*** Wizard  
  
***Created:*** June 7th, 2022  
  
***Version:*** 0.0.1  
  
***Description:***  
A dynamic spawn class for groups, units, and statics in DCS World  
  
***Features:***  
* Object Orientated  
* Integrated Logging  
* Spawn objects from late activated templates  
* Spawn objects from custom templates  
* Spawn objects from a variable amount of arguments  
* Spawn with original group and unit names  
* Spawn with a new nickname for the group and its units  
* Spawn with a set schedule on repeat  
* Spawn units with different payloads  
* Spawn units with different liverys  
* Spawn from a template  
* Spawn from a zone  
* Spawn from a zone on the nearest road  
* Spawn from a random zone  
* Spawn from a Vec3 position  
* Spawn from a airbase runway  
* Spawn from a airbase parking spot in a hot configuration  
* Spawn from a airbase parking spot in a cold configuration  
* Various `Set` methods to assign data for the templates to spawn with  
* Various `Get` methods to acquire data from templates like payloads and liverys  
* Get open airbase parking spots as well as get the first open spot with the option to filter terminal types  
* Mark parking spots at an airbase to determine viable parking spot locations  
* Add group, unit, and static Templates into the global `Database`  
  
# ***Methods & Fields***  
  
## ***Fields***  
  
Field | Type | Description
-|-|-
Spawn.Version | string | semantic version
Spawn.Source | string | script source for dcs.log prefix
Spawn.DebugLevel | number | the max log level 
Spawn.DebugLevels | table | log level enumerators 
Spawn.Category | table | enumerators for spawn group categories
Spawn.Takeoff | table | enumerators for taking off from an airbase
Spawn.Skill | table | enumerators for skills
Spawn.Waypoint | table | enumerators for waypoints
  
## ***Methods***  
  
### ***Spawn:New(templateName, nickname)***
Create a new instance of a spawn object by name    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
templateName | string | **✓** | the group, unit, or static name of the ME Template
nickname | string |  | optional nickname the Spawn object will use instead of its template name

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local HornetSpawn = Spawn:New("Hornet Group")  
```

### ***Spawn:NewFromTemplate(template, nickname, staticTemplate)***
Create a new instance of a Spawn object from a template    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
template | table | **✓** | the template table with required data for spawning
nickname | string |  | optional nickname the Spawn object will use instead of its template name
staticTemplate | boolean |  | optional boolean if the template is a static object

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local ViperGroupTemplate = Spawn:GetGroupTemplate("Viper Group")  
local ViperSpawn = Spawn:NewFromTemplate(ViperGroupTemplate)  
 
local StaticDepotSpawn = Spawn:NewFromTemplate(Spawn:GetStaticTemplate("Static Depot"), nil, true)  
```

### ***Spawn:NewFromTable(properties)***
Create a new instance of a Spawn object from a table of properties    
**Required Unit Properties:**    
* type  
* countryId  
* categoryId  
  
**Required Static Properties:**  
* category  
* shapeName  
* staticTemplate  
  
**Optional Properties:**  
* skill  
* canDrive  
* alt  
* altType  
* heading  
* action  
* name  
* waypoint  
  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
properties | table | **✓** | table of properties to give to the Spawn object

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
-- Tank Unit  
local TankProperties = {}  
TankProperties.type = "T-90" -- type required  
TankProperties.countryId = country.id.RUSSIA -- countryId required  
TankProperties.categoryId = Spawn.Category.Vehicle -- categoryId required  
 
-- Static Tank  
local StaticTankProperties = {}  
StaticTankProperties.type = "T-90" -- type required  
StaticTankProperties.countryId = country.id.RUSSIA -- countryId required  
StaticTankProperties.category = "" -- category required  
StaticTankProperties.shapeName = "" -- shapeName required  
```

### ***Spawn:SetKeepNames(keepGroupName, keepUnitNames)***
Set the Spawn object to keep group or unit names    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
keepGroupName | boolean |  | true or false to keep the group name of the template
keepUnitNames | boolean |  | true or false to keep all the unit names for the group template

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local TankSpawn = Spawn:New("Tank Group")  
TankSpawn:SetKeepNames(true, true)  
```

### ***Spawn:SetMaxAlive(maxAliveGroups, maxAliveUnits)***
Set the Spawn object to only allow a certain amount of groups and units to be alive    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
maxAliveGroups | number | **✓** | the max amount of groups that can be alive at a given time
maxAliveUnits | number | **✓** | the max amount of unit that can be alive at a given time

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local TankSpawn = Spawn:New("Tank Group")  
TankSpawn:SetMaxAlive(2, 2)  
```

### ***Spawn:SetHeading(heading, unitId)***
Set the Spawn object to use a certain heading    
converts a degree heading into radians    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
heading | number | **✓** | the heading to give to the group or a unit at spawn time
unitId | number |  | optional unitId to provide for a specific unit within the group

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local TankSpawn = Spawn:New("Tank Group")  
TankSpawn:SetHeading(90, 2)  
```

### ***Spawn:SetSpawnVec3(vec3, alt)***
Set the spawn object to spawn from a vec3    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
vec | table | **✓** | the vec3 point to spawn at
alt | number | **✓** | required for airplanes and helicopters only

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local TankSpawn = Spawn:New("Tank Group")  
TankSpawn:SetSpawnVec3(Spawn:GetZoneVec3("spawn zone"))  
```

### ***Spawn:SetSpawnZone(zoneName, alt)***
Set the Spawn object to spawn from a zone    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
zoneName | string | **✓** | the name of the trigger zone to spawn at
alt | number | **✓** | required for airplanes and helicopters only

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local TankSpawn = Spawn:New("Tank Group")  
TankSpawn:SetSpawnZone("spawn zone")  
```

### ***Spawn:SetSpawnAirbase(airbaseName, takeoff, spots)***
Set the Spawn object to spawn from a airbase    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
airbaseName | string | **✓** | the airbase name as seen in DCS to spawn at
takeoff | enum | **✓** | use: `Spawn.Takeoff`
spots | array |  | optional parking spots to provide, otherwise they will be decided by DCS. You can use `Spawn:GetFreeParkingSpots(airbaseName)` obtain useable spots.  

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local HornetSpawn = Spawn:New("Hornet Group")  
HornetSpawn:SetSpawnAirbase("Aleppo", Spawn.Takeoff.FromParkingHot)  
```

### ***Spawn:SetRandomFromTemplate(templateList)***
Set the Spawn object to spawn from a random template    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
templateList | array | **✓** | a list of template names where one will be randomly selected each time it spawns

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local spawnList = {  
    "Tank Group 1",  
    "Tank Group 2",  
    "Tank Group 3",  
    "Tank Group 4",  
}  
local TankSpawn = Spawn:New("Tank Group")  
TankSpawn:SetRandomFromTemplate(spawnList)  
```

### ***Spawn:SetNickname(nickname)***
Set the Spawn objects nickname    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
nickname | string | **✓** | will be used over the template name, unit names will be followed by -Id

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local HornetSpawn = Spawn:New("Hornet Group")  
HornetSpawn:SetNickname("Hornet CAP")  
```

### ***Spawn:SetPayload(payload, unitId)***
Set the Spawn object to use a new paylaod    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
payload | table | **✓** | payload to provide to the group or a specifc unit. airplanes and helicopters only. the return of `Spawn:GetPayload(unitName)` can be used.  
unitId | number |  | optional unit Id to set the payload for a specifc unit within the group

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local HornetSpawn = Spawn:New("Hornet Group")  
HornetSpawn:SetPayload("Hornet CAP")  
```

### ***Spawn:SetLivery(liveryName, unitId)***
Set the Spawn object to use a new livery    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
livery | string | **✓** | livery name to provide to the group or specific unit. the return of `Spawn:GetLivery(unitName)` can be used.  
unitId | number |  | optional unit Id to set the livery for a specifc unit within the group

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local HornetSpawn = Spawn:New("Hornet Group")  
HornetSpawn:SetLivery("Hornet CAP")  
```

### ***Spawn:SetSkill(skill, unitId)***
Set the Spawn object to use a new skill level    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
skill | string | **✓** | skill level than can be used, can also use `Spawn.Skill`
unitId | number |  | optional unit Id to set the skill for a specific unit

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local HornetSpawn = Spawn:New("Hornet Group")  
HornetSpawn:SetSkill(Spawn.Skill.Random)  
```

### ***Spawn:SetDebugLevel(level)***
Set the Spawn object to use a certain debug level    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
level | number | **✓** | max debug level where only set level and below will be used. can use `Spawn.DebugLevel`

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local HornetSpawn = Spawn:New("Hornet Group")  
HornetSpawn:SetDebugLevel(Spawn.DebugLevel.Info)  
```

### ***Spawn:SetScheduler(method, params, delay)***
Set the Spawn object to use a specific method for spawning on a repeating schedule    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
method | function | **✓** | the spawn method that will be scheduled
params | array |  | the parameters to give to the method
delay | number | **✓** | 

Return | Type
-|-
self | Spawn |  -- spawns the group from a zone every 300 seconds local HornetSpawn = Spawn:New("Hornet Group")   HornetSpawn:SetScheduler(Spawn.SpawnFromZone, {HornetSpawn, "spawn zone", 5000}, 300) HornetSpawn:SpawnFromZone("spawn zone", 5000)

### ***Spawn:SetSpawnHook(spawnHook)***
Set a spawn hook to capture the event of spawning    
Parameter | Type | Required | Description
-|-|-|-
spawnHook | string | **✓** | the name of the method to callback to upon spawning

Return | Type
-|-
self | Spawn | 

**Usage:**  
```lua
local HornetSpawn = Spawn:New("Hornet Group")  
HornetSpawn:SetSpawnHook("OnEventSpawn")  
function HornetSpawn:OnEventSpawn(spawnData)
    self:Info("%s has spawned", spawnData.GroupName)
end
HornetSpawn:SpawnToWorld()
```

### ***Spawn:GetSpawnedGroup()***
Get the currently spawned DCS Class Group    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
self | DCSGroup | 

**Usage:**  
```lua
local HornetSpawn = Spawn:New("Hornet Group")  
HornetSpawn:SpawnToWorld()  
local SpawnedGroup = HornetSpawn:GetSpawnedGroup()  
```

### ***Spawn:GetSpawnedStatic()***
Get the currently spawned DCS Class StaticObject    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
self | DCSStaticObject | 

**Usage:**  
```lua
local CrateSpawn = Spawn:New("Static Crate")  
CrateSpawn:SpawnToWorld()  
local SpawnedStatic = CrateSpawn:GetSpawnedStatic()  
```

### ***Spawn:GetPayload(unitName)***
Get a payload table from a unit by name    
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
unitName | string | **✓** | the name of a unit in the database to get a payload table from

Return | Type
-|-
payload | table | 

**Usage:**  
```lua
local CapPayload = Spawn:GetPayload("CAP Payload")
local HornetSpawn = Spawn:New("Hornet Group")  
HornetSpawn:SetPayload(CapPayload)
HornetSpawn:SpawnToWorld()  
```

### ***Spawn:GetLiveryName(unitName)***
Get a livery name from a unit by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
unitName | string |  | 

Return | Type
-|-
liveryName | string | 

### ***Spawn:GetGroupTemplate(groupName)***
Get a group template by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
groupName | string |  | 

Return | Type
-|-
groupTemplate | table | 

### ***Spawn:GetUnitTemplate(unitName)***
Get a unit template by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
unitName | string |  | 

Return | Type
-|-
unitTemplate | table | 

### ***Spawn:GetStaticTemplate(staticName)***
Get a static template by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
staticName | string |  | 

Return | Type
-|-
staticTemplate | table | 

### ***Spawn:GetTemplate(templateName)***
Get a template by name  
this function also returns a second boolean variable if the template is static  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
templateName | string |  | 

Return | Type
-|-
template | table | 

### ***Spawn:GetBaseTemplate()***
Get the Spawn objects base template  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
baseTemplate | table | 

### ***Spawn:GetSpawnTemplate()***
Get a empty spawn table for groups and units  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
spawnTemplate | table | 

### ***Spawn:GetStaticSpawnTemplate()***
Get a empty spawn table for statics  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
staticSpawnTemplate | table | 

### ***Spawn:GetZoneTemplate(zoneName)***
Get a zone template by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
zoneName | string |  | 

Return | Type
-|-
zoneTemplate | table | 

### ***Spawn:GetQuadZonePoints(zoneName)***
Get a quad zones points by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
zoneName | string |  | 

Return | Type
-|-
points | table | 

### ***Spawn:GetZoneRadius(zoneName)***
Get a zones radius by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
zoneName | string |  | 

Return | Type
-|-
self | number | 

### ***Spawn:GetZoneVec3(zoneName)***
Get a zones vec3 points by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
zoneName | string |  | 

Return | Type
-|-
vec | table | 

### ***Spawn:GetOpenParkingSpots(airbaseName, terminalType)***
Get all the open parking spots at an airbase by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
airbaseName | string |  | 
terminalType | number |  | 

Return | Type
-|-
openParkingSpots | table | 

### ***Spawn:GetFirstOpenParkingSpot(airbaseName, terminalType)***
Get the first open parking spot an airbase by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
airbaseName | string |  | 
terminalType | number |  | 

Return | Type
-|-
openSpot | table | 

### ***Spawn:GetTerminalData(airbaseName, spots)***
Get the the terminal data from an airbase by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
airbaseName | string |  | 
spots | number |  | 

Return | Type
-|-
terminalData | table | 

### ***Spawn:GetGroupFromIndex(spawnIndex)***
Get a DCS Group object by its spawn index  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
spawnIndex | number |  | 

Return | Type
-|-
self | DCSGroup | 

### ***Spawn:GetStaticFromIndex(spawnIndex)***
Get a DCS StaticObject by its spawn index  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
spawnIndex | number |  | 

Return | Type
-|-
self | DCSStaticObject | 

### ***Spawn:IsAlive()***
Return true or false if the current Spawn obejct is alive  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
alive | boolean | 

### ***Spawn:IsGroupAlive()***
Return true or false if the current Spawn group object is alive  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
isAlive | boolean | 

### ***Spawn:IsStaticAlive()***
Return true or false if the current Spawn static object is alive  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
isAlive | boolean | 

### ***Spawn:MarkParkingSpots(airbaseName)***
Mark the parking spots at an airbase by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
airbaseName | string |  | 

Return | Type
-|-
none |  | 

### ***Spawn:AddGroupTemplate(template)***
Add a group template to the database  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
template | table |  | 

Return | Type
-|-
none |  | 

### ***Spawn:AddUnitTemplate(template)***
Add a unit template to the database  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
template | table |  | 

Return | Type
-|-
none |  | 

### ***Spawn:AddStaticTemplate(template)***
Add a static template to the database  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
template | table |  | 

Return | Type
-|-
none |  | 

### ***Spawn:SpawnToWorld()***
Spawn the object to the world  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnScheduled(method, params, delay)***
Spawn an object with a spawn method to be scheduled  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
method | function |  | 
params | array |  | 
delay | number |  | 

Return | Type
-|-
none |  | 

### ***Spawn:Respawn()***
Respawn the object  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnFromTemplate(template, countryId, categoryId, static)***
Spawn an object from a template  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
template | table |  | 
countryId | number |  | 
categoryId | number |  | 
static | boolean |  | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnFromZone(zoneName, alt)***
Spawn an object from a zone by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
zoneName | string |  | 
alt | number |  | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnFromZoneOnNearestRoad(zoneName)***
Spawn an object from a zone on the nearest road  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
zoneName | string |  | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnFromRandomZone(zoneList, alt)***
Spawn an object from a random zone from a list  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
zoneList | array |  | 
alt | number |  | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnFromRandomVec3InZone(zoneName, alt)***
Spawn an object from a random vec3 in a zone  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
zoneName | string |  | 
alt | number |  | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnFromRandomVec3InRadius(vec3, minRadius, maxRadius, alt)***
Spawn an object from a random vec3 within a random radius  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
vec | table |  | 
minRadius | number |  | 
maxRadius | number |  | 
alt | number |  | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnFromVec3OnNearestRoad(vec3)***
Spawn an object from a vec3 on the nearest road  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
vec | table |  | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnFromVec3(vec3, alt)***
Spawn an object from a vec3  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
vec | table |  | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnFromAirbaseRunway(airbaseName, spots)***
Spawn an object from a airbase on the runway  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
airbaseName | string |  | 
spots | array |  | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnFromAirbaseParkingHot(airbaseName, spots)***
Spawn an object at an airbase in a parking spot hot  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
airbaseName | string |  | 
spots | array |  | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnFromAirbaseParkingCold(airbaseName, spots)***
Spawn an object at an airbase in a parking spot cold  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
airbaseName | string |  | 
spots | array |  | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:SpawnFromAirbase(airbaseName, takeoff, spots)***
Spawn an object at an airbase with any takeoff type and any spots  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 
airbaseName | string |  | 
takeoff | enum |  | 
spots | array |  | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:_InitializeTemplate()***
Initializes the templates  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:_InitializeNames()***
Initialize the templates group and unit names  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
self | Spawn | 

### ***Spawn:_AddToWorld()***
Add the spawn object into the world  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **✓** | 

Return | Type
-|-
self | Spawn | 

