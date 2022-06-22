# ***DCS-Spawn***

**Authors:** Wizard  

**Created:** June 7th, 2022  

**Description:**  
A dynamic spawn module for groups, units, and statics in DCS World  

**Features:**  
- Object Orientated  
- Integrated Logging  
- Spawn objects from late activated templates  
- Spawn objects from custom templates  
- Spawn objects from a variable amount of arguments  
- Spawn with original group and unit names  
- Spawn with a new nickname for the group and its units  
- Spawn with a set schedule on repeat  
- Spawn units with different payloads  
- Spawn units with different liverys  
- Spawn from a template  
- Spawn from a zone  
- Spawn from a zone on the nearest road  
- Spawn from a random zone  
- Spawn from a Vec3 position  
- Spawn from a airbase runway  
- Spawn from a airbase parking spot in a hot configuration  
- Spawn from a airbase parking spot in a cold configuration  
- Various `Set` methods to assign data for the templates to spawn with  
- Various `Get` methods to acquire data from templates like payloads and liverys  
- Get open airbase parking spots as well as get the first open spot with the option to filter terminal types  
- Mark parking spots at an airbase to determine viable parking spot locations  
- Add group, unit, and static Templates into the global `Database`  

## ***Spawn:New(templateName, nickname)***
Create a new instance of a spawn object by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
templateName | string | **✓** | the group, unit, or static name of the ME Template
nickname | string | **X** | optional nickname the Spawn object will use instead of its template name

Return | Type
-|-
self | Spawn

```lua
local HornetSpawn = Spawn:New("Hornet Group")

local TankSpawn = Spawn:New("Tank Group")
```

## ***Spawn:NewFromTemplate(template, nickname, staticTemplate)***
Create a new instance of a Spawn object from a template  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
template | table | **✓** | the template table with required data for spawning
nickname | string | **X** | optional nickname the Spawn object will use instead of its template name
staticTemplate | boolean | **X** | optional boolean if the template is a static object

Return | Type
-|-
self | Spawn

```lua
local ViperGroupTemplate = Spawn:GetGroupTemplate("Viper Group")
local ViperSpawn = Spawn:NewFromTemplate(ViperGroupTemplate)

local StaticDepotSpawn = Spawn:NewFromTemplate(Spawn:GetStaticTemplate("Static Depot"), nil, true)
```

## ***Spawn:NewFromTable(properties)***
Create a new instance of a Spawn object from a table of properties  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
properties | table | **✓** | table of arugment properties to give to the Spawn object

Return | Type
-|-
self | Spawn

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

## ***Spawn:SetKeepNames(keepGroupName, keepUnitNames)***
Set the Spawn object to keep group or unit names  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
keepGroupName | boolean | **X** | true or false to keep the group name of the template
keepUnitNames | boolean | **X** | true or false to keep all the unit names for the group template

Return | Type
-|-
self | Spawn

```lua
local TankSpawn = Spawn:New("Tank Group")
TankSpawn:SetKeepNames(true, true)
```

## ***Spawn:SetMaxAlive(maxAliveGroups, maxAliveUnits)***
Set the Spawn object to only allow a certain amount of groups and units to be alive  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
maxAliveGroups | number | **X** | 
maxAliveUnits | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SetHeading(heading, unitId)***
Set the Spawn object to use a certain heading  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
heading | number | **X** | 
unitId | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SetSpawnVec3(vec3, alt)***
Set the spawn object to spawn from a vec3  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
vec | table | **X** | 
alt | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SetSpawnZone(zoneName, alt)***
Set the Spawn object to spawn from a zone  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
zoneName | string | **X** | 
alt | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SetSpawnAirbase(airbaseName, takeoff, spots)***
Set the Spawn object to spawn from a airbase  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
airbaseName | string | **X** | 
takeoff | enum | **X** | 
spots | array | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SetRandomFromTemplate(templateList)***
Set the Spawn object to spawn from a random template  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
templateList | array | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SetNickname(nickname)***
Set the Spawn objects nickname  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
nickname | string | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SetPayload(payload, unitId)***
Set the Spawn object to use a new paylaod  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
payload | table | **X** | 
unitId | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SetLivery(liveryName, unitId)***
Set the Spawn object to use a new livery  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
livery | string | **X** | 
unitId | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SetSkill(skill, unitId)***
Set the Spawn object to use a new skill level  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
skill | string | **X** | 
unitId | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SetRandomSkill(unitId)***
Set the Spawn object to use a random skill level  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
unitId | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SetDebugLevel(level)***
Set the Spawn object to use a certain debug level  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
level | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SetScheduler(method, params, delay)***
Set the Spawn object to use a specific method for spawning on a repeating schedule  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
method | function | **X** | 
params | array | **X** | 
delay | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:GetSpawnedGroup()***
Get the currently spawned DCS Class Group  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
self | Group

```lua
```

## ***Spawn:GetSpawnedStatic()***
Get the currently spawned DCS Class StaticObject  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
self | StaticObject

```lua
```

## ***Spawn:GetPayload(unitName)***
Get a payload table from a unit by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
unitName | string | **X** | 

Return | Type
-|-
payload | table

```lua
```

## ***Spawn:GetLiveryName(unitName)***
Get a livery name from a unit by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
unitName | string | **X** | 

Return | Type
-|-
liveryName | string

```lua
```

## ***Spawn:GetGroupTemplate(groupName)***
Get a group template by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
groupName | string | **X** | 

Return | Type
-|-
groupTemplate | table

```lua
```

## ***Spawn:GetUnitTemplate(unitName)***
Get a unit template by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
unitName | string | **X** | 

Return | Type
-|-
unitTemplate | table

```lua
```

## ***Spawn:GetStaticTemplate(staticName)***
Get a static template by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
staticName | string | **X** | 

Return | Type
-|-
staticTemplate | table

```lua
```

## ***Spawn:GetTemplate(templateName)***
Get a template by name  
this function also returns a second boolean variable if the template is static  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
templateName | string | **X** | 

Return | Type
-|-
template | table

```lua
```

## ***Spawn:GetBaseTemplate()***
Get the Spawn objects base template  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
baseTemplate | table

```lua
```

## ***Spawn:GetSpawnTemplate()***
Get a empty spawn table for groups and units  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
spawnTemplate | table

```lua
```

## ***Spawn:GetStaticSpawnTemplate()***
Get a empty spawn table for statics  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
staticSpawnTemplate | table

```lua
```

## ***Spawn:GetZoneTemplate(zoneName)***
Get a zone template by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
zoneName | string | **X** | 

Return | Type
-|-
zoneTemplate | table

```lua
```

## ***Spawn:GetQuadZonePoints(zoneName)***
Get a quad zones points by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
zoneName | string | **X** | 

Return | Type
-|-
points | table

```lua
```

## ***Spawn:GetZoneRadius(zoneName)***
Get a zones radius by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
zoneName | string | **X** | 

Return | Type
-|-
self | number

```lua
```

## ***Spawn:GetZoneVec3(zoneName)***
Get a zones vec3 points by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
zoneName | string | **X** | 

Return | Type
-|-
vec | table

```lua
```

## ***Spawn:GetOpenParkingSpots(airbaseName, terminalType)***
Get all the open parking spots at an airbase by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
airbaseName | string | **X** | 
terminalType | number | **X** | 

Return | Type
-|-
openParkingSpots | table

```lua
```

## ***Spawn:GetFirstOpenParkingSpot(airbaseName, terminalType)***
Get the first open parking spot an airbase by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
airbaseName | string | **X** | 
terminalType | number | **X** | 

Return | Type
-|-
openSpot | table

```lua
```

## ***Spawn:GetTerminalData(airbaseName, spots)***
Get the the terminal data from an airbase by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
airbaseName | string | **X** | 
spots | number | **X** | 

Return | Type
-|-
terminalData | table

```lua
```

## ***Spawn:GetGroupFromIndex(spawnIndex)***
Get a DCS Group object by its spawn index  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
spawnIndex | number | **X** | 

Return | Type
-|-
self | DCSGroup

```lua
```

## ***Spawn:GetStaticFromIndex(spawnIndex)***
Get a DCS StaticObject by its spawn index  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
spawnIndex | number | **X** | 

Return | Type
-|-
self | DCSStaticObject

```lua
```

## ***Spawn:IsAlive()***
Return true or false if the current Spawn obejct is alive  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
alive | boolean

```lua
```

## ***Spawn:IsGroupAlive()***
Return true or false if the current Spawn group object is alive  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
isAlive | boolean

```lua
```

## ***Spawn:IsStaticAlive()***
Return true or false if the current Spawn static object is alive  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
isAlive | boolean

```lua
```

## ***Spawn:MarkParkingSpots(airbaseName)***
Mark the parking spots at an airbase by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
airbaseName | string | **X** | 

Return | Type
-|-
none | 

```lua
```

## ***Spawn:AddGroupTemplate(template)***
Add a group template to the database  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
template | table | **X** | 

Return | Type
-|-
none | 

```lua
```

## ***Spawn:AddUnitTemplate(template)***
Add a unit template to the database  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
template | table | **X** | 

Return | Type
-|-
none | 

```lua
```

## ***Spawn:AddStaticTemplate(template)***
Add a static template to the database  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
template | table | **X** | 

Return | Type
-|-
none | 

```lua
```

## ***Spawn:SpawnToWorld()***
Spawn the object to the world  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnScheduled(method, params, delay)***
Spawn an object with a spawn method to be scheduled  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
method | function | **X** | 
params | array | **X** | 
delay | number | **X** | 

Return | Type
-|-
none | 

```lua
```

## ***Spawn:Respawn()***
Respawn the object  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnFromTemplate(template, countryId, categoryId, static)***
Spawn an object from a template  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
template | table | **X** | 
countryId | number | **X** | 
categoryId | number | **X** | 
static | boolean | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnFromZone(zoneName, alt)***
Spawn an object from a zone by name  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
zoneName | string | **X** | 
alt | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnFromZoneOnNearestRoad(zoneName)***
Spawn an object from a zone on the nearest road  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
zoneName | string | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnFromRandomZone(zoneList, alt)***
Spawn an object from a random zone from a list  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
zoneList | array | **X** | 
alt | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnFromRandomVec3InZone(zoneName, alt)***
Spawn an object from a random vec3 in a zone  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
zoneName | string | **X** | 
alt | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnFromRandomVec3InRadius(vec3, minRadius, maxRadius, alt)***
Spawn an object from a random vec3 within a random radius  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
vec | table | **X** | 
minRadius | number | **X** | 
maxRadius | number | **X** | 
alt | number | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnFromVec3OnNearestRoad(vec3)***
Spawn an object from a vec3 on the nearest road  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
vec | table | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnFromVec3(vec3, alt)***
Spawn an object from a vec3  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
vec | table | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnFromAirbaseRunway(airbaseName, spots)***
Spawn an object from a airbase on the runway  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
airbaseName | string | **X** | 
spots | array | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnFromAirbaseParkingHot(airbaseName, spots)***
Spawn an object at an airbase in a parking spot hot  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
airbaseName | string | **X** | 
spots | array | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnFromAirbaseParkingCold(airbaseName, spots)***
Spawn an object at an airbase in a parking spot cold  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
airbaseName | string | **X** | 
spots | array | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:SpawnFromAirbase(airbaseName, takeoff, spots)***
Spawn an object at an airbase with any takeoff type and any spots  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 
airbaseName | string | **X** | 
takeoff | enum | **X** | 
spots | array | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:_InitializeTemplate()***
Initializes the templates  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:_ResolveNames()***
Initialize the templates group and unit names  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

## ***Spawn:_AddToWorld()***
Add the spawn object into the world  
Parameter | Type | Required | Description
-|-|-|-
self | Spawn | **X** | 

Return | Type
-|-
self | Spawn

```lua
```

