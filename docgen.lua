--[[
@Script Spawn

@Author Wizard

@Description
A dynamic spawn module for groups, units, and statics in DCS World

@Features

@Created June 7th, 2022

@Github https://github.com/Wizxrd/DCS-Spawn

]]

--[[ what function does
- @Param
- @Return
]]
function testLine()
end

local spawnFile = "C:/_gitMaster/DCS-Spawn/Spawn.lua"
local readme = "C:/_gitMaster/DCS-Spawn/Test.md"
local ReadmeFile = io.open(readme, "w+")

local ParamString = "- @Param"
local ReturnString = "- @Return"
local CommentBlockStartString = "--[["
local FunctionString = "function"

local Methods = {}

for line in io.lines(spawnFile) do
    -- do comment block first
    local NewMethod = #Methods + 1
    Methods[NewMethod] = {}
    local Method = Methods[NewMethod]
    if line:sub(1, CommentBlockStartString:len()) == CommentBlockStartString then
        local Description = line:sub(CommentBlockStartString:len() + 2)
        if Description:find("%s+") then
            Method.Description = Description
            --ReadmeFile:write("# "..Line.."  \n")
        end
    end
    -- do parameters
    if line:sub(1, ParamString:len()) == ParamString then
        local Parameters = line:sub(ParamString:len() + 2)
        Method.Parameters = Parameters
        --ReadmeFile:write(Line.."  \n")
    end
    -- do returns
    if line:sub(1, ReturnString:len()) == ReturnString then
        local Return = line:sub(ReturnString:len() + 2)
        Method.Returns = Return
        --ReadmeFile:write(Line.."  \n")
    end
    -- do functions
    if line:sub(1, FunctionString:len()) == FunctionString then
        Method.Description = Description
        --ReadmeFile:write(line.."  \n\n")
    end
end
ReadmeFile:close()

--[[ Create a new instance of a spawn object from a template
- @Param #Spawn self
- @Param #table template
- @Param #string nickname
- @Param #boolean staticTemplate
- @Return #Spawn self
]]
function Spawn:NewFromTemplate(template, nickname, staticTemplate)