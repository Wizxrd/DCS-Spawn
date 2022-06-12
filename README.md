# DCS-TemplateSpawn
## *Fields & Methods*
### *Global Fields*
Field       | Type   | Description
------------|--------|------------
DebugLevel  | number | the max level defined for logging
DebugLevels | enum   | enumerators for 5 levels of logging
Takeoff     | enum   | enumerators for 3 different types of takeoff methods

### *Instantiated Fields*
Field             | Type   | Description
------------------|--------|------------
baseTemplate      | table  | base template of the object
staticTemplate    | bool   | boolean for if the base template is a static
templateName      | string | name of the template
nickname          | string | nickname to use as the name when spawning
keepGroupName     | bool   | boolean to keep the group name of the template when spawning
keepUnitNames     | bool   | boolean to keep the unit names of the template when spawning
scheduledFunction | bool   | boolean when there is a spawn to be scheduled
scheduledCallback | func   | the function to call when it is scheduled
scheduledParams   | table  | table of params to unpack into the callback
scheduledTimer    | number | how frequently the spawn is scheduled to happen
payloadId         | number | the unit id to set the payload for
payload           | table  | the payload that will be set to a unit
spawnCount        | number | internal count that keeps track of how many times the template has spawned 
countryId         | number | the countryId of the template 
categoryID        | number | category of the template 
DCSGroup          | object | dcs group object returned upon spawn 
DCSStaticObject   | object | dcs static object returned upon spawn
_spawnTemplate    | table  | copied template of baseTemplate that is manipulated for each spawn

### *Methods*
Field                       | Description
----------------------------|------------
New                         | creates new instance of spawn object from a template name
NewFromTemplate             | creates a new instance of spawn object from a custom template
SetTemplateNames            |
SetNickname                 |
SetScheduler                |  
SetPayload                  |  
SetDebugLevel               |  
GetDCSGroup                 |  
GetDCSStaticObject          |  
GetPayload                  |  
GetGroupTemplate            |  
GetUnitTemplate             |  
GetStaticTemplate           |  
GetBaseTemplate             |  
GetSpawnTemplate            |  
GetStaticSpawnTemplate      |  
GetZoneTemplate             |  
GetQuadZonePoints           |  
GetZoneVec3                 |  
GetOpenParkingSpots         |  
GetFirstOpenParkingSpot     |  
GetTerminalData             |  
MarkParkingSpots            |  
ScheduleFunction            |  
GetQuadZonePoints           |  
GroupInQuadZone             |  
UnitInQuadZone              |  
StaticInQuadZone            |  
GroupInPolygon              |  
UnitInPolygon               |  
StaticInPolygon             |  
ObjectInPolygonZone         |  
SpawnToWorld                |  
SpawnFromTemplate           |  
SpawnFromZone               |  
SpawnFromRandomZone         |  
SpawnFromRandomVec3InZone   |  
SpawnFromRandomVec3InRadius |  
SpawnFromVec3               |  
SpawnFromAirbaseRunway      |  
SpawnFromAirbaseParkingHot  |  
SpawnFromAirbaseParkingCold |  
SpawnFromAirbase            |  
Alert                       |  
Error                       |  
Warning                     |  
Info                        |  
Debug                       |  
_InitializeTemplate         |  
_InitializeNames            |  
_AddToWorld                 |  