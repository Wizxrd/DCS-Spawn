# **Spawn:New(templateName, nickname)**
Create a new instance of a spawn object by name
Parameter | Type | Required | Description
----------|------|----------|------------
templateName | string | **✓** | the group, unit, or static name of the ME Template
nickname | string |  | optional nickname the Spawn object will use instead of its template name

**Return:** #Spawn  
**Usage:**
```lua
local HornetSpawn = Spawn:New("Hornet Group")

local TankSpawn = Spawn:New("Tank Group")
```
---
# **Spawn:NewFromTemplate(template, nickname, staticTemplate)**
Create a new instance of a Spawn object from a template
Parameter | Type | Required | Description
----------|------|----------|------------
template | table | **✓** | the template table with required data for spawning
nickname | string |  | optional nickname the Spawn object will use instead of its template name
staticTemplate | boolean |  | optional boolean if the template is a static object

**Return:** #Spawn  
**Usage:**
```lua
local ViperGroupTemplate = Spawn:GetGroupTemplate("Viper Group")
local ViperSpawn = Spawn:NewFromTemplate(ViperGroupTemplate)

local StaticDepotSpawn = Spawn:NewFromTemplate(Spawn:GetStaticTemplate("Static Depot"), nil, true)
```
---
# **Spawn:NewFromTable(properties)**
Create a new instance of a Spawn object from a table of properties
Parameter | Type | Required | Description
----------|------|----------|------------
properties | table | **✓** | table of arugment properties to give to the Spawn object

**Return:** #Spawn  
**Required Unit Properties**:  
- type  
- countryId  
- categoryId  
  
**Required Static Properties**:  
- category  
- shapeName  
- staticTemplate  
  
**Optional Properties**:  
- skill  
- canDrive  
- alt  
- altType  
- heading  
- action  
- name  
- waypoint  
  
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
---
# **Spawn:SetKeepNames(keepGroupName, keepUnitNames)**
Set the Spawn object to keep group or unit names
Parameter | Type | Required | Description
----------|------|----------|------------
keepGroupName | boolean |  | true or false to keep the group name of the template
keepUnitNames | boolean |  | true or false to keep all the unit names for the group template

**Return:** #Spawn  
**Usage:**
```lua
local TankSpawn = Spawn:New("Tank Group")
TankSpawn:SetKeepNames(true, true)
```
---
# **Spawn:SetMaxAlive(maxAliveGroups, maxAliveUnits)**
Set the Spawn object to only allow a certain amount of groups and units to be alive
Parameter | Type | Required | Description
----------|------|----------|------------
maxAliveGroups | number |  | 
maxAliveUnits | number |  | 

**Return:** #Spawn  
---
# **Spawn:SetHeading(heading, unitId)**
Set the Spawn object to use a certain heading
Parameter | Type | Required | Description
----------|------|----------|------------
heading | number |  | 
unitId | number |  | 

**Return:** #Spawn  
---
# **Spawn:SetSpawnVec3(vec3, alt)**
Set the spawn object to spawn from a vec3
Parameter | Type | Required | Description
----------|------|----------|------------
vec | table |  | 
alt | number |  | 

**Return:** #Spawn  
---
# **Spawn:SetSpawnZone(zoneName, alt)**
Set the Spawn object to spawn from a zone
Parameter | Type | Required | Description
----------|------|----------|------------
zoneName | string |  | 
alt | number |  | 

**Return:** #Spawn  
---
# **Spawn:SetSpawnAirbase(airbaseName, takeoff, spots)**
Set the Spawn object to spawn from a airbase
Parameter | Type | Required | Description
----------|------|----------|------------
airbaseName | string |  | 
takeoff | enum |  | 
spots | array |  | 

**Return:** #Spawn  
---
# **Spawn:SetRandomFromTemplate(templateList)**
Set the Spawn object to spawn from a random template
Parameter | Type | Required | Description
----------|------|----------|------------
templateList | array |  | 

**Return:** #Spawn]]  
---
# **Spawn:SetNickname(nickname)**
Set the Spawn objects nickname
Parameter | Type | Required | Description
----------|------|----------|------------
nickname | string |  | 

**Return:** #Spawn  
---
# **Spawn:SetPayload(payload, unitId)**
Set the Spawn object to use a new paylaod
Parameter | Type | Required | Description
----------|------|----------|------------
payload | table |  | 
unitId | number |  | 

**Return:** #Spawn  
---
# **Spawn:SetLivery(liveryName, unitId)**
Set the Spawn object to use a new livery
Parameter | Type | Required | Description
----------|------|----------|------------
livery | string |  | 
unitId | number |  | 

**Return:** #Spawn  
---
# **Spawn:SetSkill(skill, unitId)**
Set the Spawn object to use a new skill level
Parameter | Type | Required | Description
----------|------|----------|------------
skill | string |  | 
unitId | number |  | 

**Return:** #Spawn  
---
# **Spawn:SetRandomSkill(unitId)**
Set the Spawn object to use a random skill level
Parameter | Type | Required | Description
----------|------|----------|------------
unitId | number |  | 

**Return:** #Spawn  
---
# **Spawn:SetDebugLevel(level)**
Set the Spawn object to use a certain debug level
Parameter | Type | Required | Description
----------|------|----------|------------
level | number |  | 

**Return:** #Spawn  
---
# **Spawn:SetSpawnHook(spawnHook)**
Set the Spawn object to use a specific method for spawning on a repeating schedule
Parameter | Type | Required | Description
----------|------|----------|------------
params | array |  | 
delay | number |  | 

**Return:** #Spawn  
---
# **Spawn:GetSpawnedGroup()**
Get the currently spawned DCS Class Group
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #Group  
---
# **Spawn:GetSpawnedStatic()**
Get the currently spawned DCS Class StaticObject
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #StaticObject  
---
# **Spawn:GetPayload(unitName)**
Get a payload table from a unit by name
Parameter | Type | Required | Description
----------|------|----------|------------
unitName | string |  | 

**Return:** #table payload  
---
# **Spawn:GetLiveryName(unitName)**
Get a livery name from a unit by name
Parameter | Type | Required | Description
----------|------|----------|------------
unitName | string |  | 

**Return:** #string liveryName  
---
# **Spawn:GetGroupTemplate(groupName)**
Get a group template by name
Parameter | Type | Required | Description
----------|------|----------|------------
groupName | string |  | 

**Return:** #table  
---
# **Spawn:GetUnitTemplate(unitName)**
Get a unit template by name
Parameter | Type | Required | Description
----------|------|----------|------------
unitName | string |  | 

**Return:** #table  
---
# **Spawn:GetStaticTemplate(staticName)**
Get a static template by name
Parameter | Type | Required | Description
----------|------|----------|------------
staticName | string |  | 

**Return:** #table  
---
# **Spawn:GetTemplate(templateName)**
Get a template by name
Parameter | Type | Required | Description
----------|------|----------|------------
templateName | string |  | 

**Return:** #table, #boolean true if static  
---
# **Spawn:GetBaseTemplate()**
Get the Spawn objects base template
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #table baseTemplate, #boolean staticTemplate  
---
# **Spawn:GetSpawnTemplate()**
Get a empty spawn table for groups and units
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #table spawnTemplate  
---
# **Spawn:GetStaticSpawnTemplate()**
Get a empty spawn table for statics
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #table staticSpawnTemplate  
---
# **Spawn:GetZoneTemplate(zoneName)**
Get a zone template by name
Parameter | Type | Required | Description
----------|------|----------|------------
zoneName | string |  | 

**Return:** #table  
---
# **Spawn:GetQuadZonePoints(zoneName)**
Get a quad zones points by name
Parameter | Type | Required | Description
----------|------|----------|------------
zoneName | string |  | 

**Return:** #table points  
---
# **Spawn:GetZoneRadius(zoneName)**
Get a zones radius by name
Parameter | Type | Required | Description
----------|------|----------|------------
zoneName | string |  | 

**Return:** #number radius  
---
# **Spawn:GetZoneVec3(zoneName)**
Get a zones vec3 points by name
Parameter | Type | Required | Description
----------|------|----------|------------
zoneName | string |  | 

**Return:** #table vec3  
---
# **Spawn:GetOpenParkingSpots(airbaseName, terminalType)**
Get all the open parking spots at an airbase by name
Parameter | Type | Required | Description
----------|------|----------|------------
airbaseName | string |  | 
terminalType | number |  | 

**Return:** #table openParkingSpots  
---
# **Spawn:GetFirstOpenParkingSpot(airbaseName, terminalType)**
Get the first open parking spot an airbase by name
Parameter | Type | Required | Description
----------|------|----------|------------
airbaseName | string |  | 
terminalType | number |  | 

**Return:** #table openSpot  
---
# **Spawn:GetTerminalData(airbaseName, spots)**
Get the the terminal data from an airbase by name
Parameter | Type | Required | Description
----------|------|----------|------------
airbaseName | string |  | 
spots | number |  | 

**Return:** #table terminalData  
---
# **Spawn:GetGroupFromIndex(spawnIndex)**
Get a DCS Group object by its spawn index
Parameter | Type | Required | Description
----------|------|----------|------------
spawnIndex | number |  | 

**Return:** #DCSGroup self  
---
# **Spawn:GetStaticFromIndex(spawnIndex)**
Get a DCS StaticObject by its spawn index
Parameter | Type | Required | Description
----------|------|----------|------------
spawnIndex | number |  | 

**Return:** #DCSStaticObject self  
---
# **Spawn:IsAlive()**
Return true or false if the current Spawn obejct is alive
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #boolean  
---
# **Spawn:IsGroupAlive()**
Return true or false if the current Spawn group object is alive
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #boolean  
---
# **Spawn:IsStaticAlive()**
Return true or false if the current Spawn static object is alive
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #boolean  
---
# **Spawn:MarkParkingSpots(airbaseName)**
Mark the parking spots at an airbase by name
Parameter | Type | Required | Description
----------|------|----------|------------
airbaseName | string |  | 

**Return:** none  
---
# **Spawn:AddGroupTemplate(template)**
Add a group template to the database
Parameter | Type | Required | Description
----------|------|----------|------------
template | table |  | 

**Return:** none  
---
# **Spawn:AddUnitTemplate(template)**
Add a unit template to the database
Parameter | Type | Required | Description
----------|------|----------|------------
template | table |  | 

**Return:** none  
---
# **Spawn:AddStaticTemplate(template)**
Add a static template to the database
Parameter | Type | Required | Description
----------|------|----------|------------
template | table |  | 

**Return:** none  
---
# **Spawn:SpawnToWorld()**
Spawn the object to the world
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #Spawn  
---
# **Spawn:SpawnLateActivated()**
Spawn an object with a spawn method to be scheduled
Parameter | Type | Required | Description
----------|------|----------|------------
params | array |  | 
delay | number |  | 

**Return:** none  
---
# **Spawn:Respawn()**
Respawn the object
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #Spawn  
---
# **Spawn:SpawnFromTemplate(template, countryId, categoryId, static)**
Spawn an object from a template
Parameter | Type | Required | Description
----------|------|----------|------------
template | table |  | 
countryId | number |  | 
categoryId | number |  | 
static | boolean |  | 

**Return:** #Spawn  
---
# **Spawn:SpawnFromZone(zoneName, alt)**
Spawn an object from a zone by name
Parameter | Type | Required | Description
----------|------|----------|------------
zoneName | string |  | 
alt | number |  | 

**Return:** #Spawn  
---
# **Spawn:SpawnFromZoneOnNearestRoad(zoneName)**
Spawn an object from a zone on the nearest road
Parameter | Type | Required | Description
----------|------|----------|------------
zoneName | string |  | 

**Return:** #Spawn  
---
# **Spawn:SpawnFromRandomZone(zoneList, alt)**
Spawn an object from a random zone from a list
Parameter | Type | Required | Description
----------|------|----------|------------
zoneList | array |  | 
alt | number |  | 

**Return:** #Spawn  
---
# **Spawn:SpawnFromRandomVec3InZone(zoneName, alt)**
Spawn an object from a random vec3 in a zone
Parameter | Type | Required | Description
----------|------|----------|------------
zoneName | string |  | 
alt | number |  | 

**Return:** #Spawn  
---
# **Spawn:SpawnFromRandomVec3InRadius(vec3, minRadius, maxRadius, alt)**
Spawn an object from a random vec3 within a random radius
Parameter | Type | Required | Description
----------|------|----------|------------
vec | table |  | 
minRadius | number |  | 
maxRadius | number |  | 
alt | number |  | 

**Return:** #Spawn  
---
# **Spawn:SpawnFromVec3OnNearestRoad(vec3)**
Spawn an object from a vec3 on the nearest road
Parameter | Type | Required | Description
----------|------|----------|------------
vec | table |  | 

**Return:** #Spawn  
---
# **Spawn:SpawnFromVec3(vec3, alt)**
Spawn an object from a vec3
Parameter | Type | Required | Description
----------|------|----------|------------
vec | table |  | 

**Return:** #Spawn  
---
# **Spawn:SpawnFromAirbaseRunway(airbaseName, spots)**
Spawn an object from a airbase on the runway
Parameter | Type | Required | Description
----------|------|----------|------------
airbaseName | string |  | 
spots | array |  | 

**Return:** #Spawn  
---
# **Spawn:SpawnFromAirbaseParkingHot(airbaseName, spots)**
Spawn an object at an airbase in a parking spot hot
Parameter | Type | Required | Description
----------|------|----------|------------
airbaseName | string |  | 
spots | array |  | 

**Return:** #Spawn  
---
# **Spawn:SpawnFromAirbaseParkingCold(airbaseName, spots)**
Spawn an object at an airbase in a parking spot cold
Parameter | Type | Required | Description
----------|------|----------|------------
airbaseName | string |  | 
spots | array |  | 

**Return:** #Spawn  
---
# **Spawn:SpawnFromAirbase(airbaseName, takeoff, spots)**
Spawn an object at an airbase with any takeoff type and any spots
Parameter | Type | Required | Description
----------|------|----------|------------
airbaseName | string |  | 
takeoff | enum |  | 
spots | array |  | 

**Return:** #Spawn  
---
# **Spawn:_InitializeTemplate()**
Initializes the templates
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #Spawn  
---
# **Spawn:_AddGroupToWorld()**
Initialize the templates group and unit names
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #Spawn  
---
# **Spawn:_UpdateAliveStatics()**
Add the spawn object into the world
Parameter | Type | Required | Description
----------|------|----------|------------

**Return:** #Spawn  
---
