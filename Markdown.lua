local SourceFilePath = "C:/_gitMaster/DCS-Spawn/Spawn.lua"
local ReadmeFilePath = "C:/_gitMaster/DCS-Spawn/Methods.md"

local ParamString = "@Param"
local ReturnString = "@Return"
local LuaCommentString = "```"
local MethodComment = "*"
local CommentBlockStartString = "--[["
local FunctionString = "function"
local Methods = {}
local CurrentMethodIndex = 0

local function AddMethodIndex()
    CurrentMethodIndex = CurrentMethodIndex + 1
    Methods[CurrentMethodIndex] = {}
    Methods[CurrentMethodIndex].Parameters = {}
    Methods[CurrentMethodIndex].MethodComments = {}
    Methods[CurrentMethodIndex].LuaComments = {}
    return CurrentMethodIndex
end

local function WriteMethodsToFile(FilePath)
    local ReadmeFile = io.open(FilePath, "w+")
    for _, Method in pairs(Methods) do
        local MethodTable = {}
        MethodTable[#MethodTable+1] = "# **"..Method.FunctionName.."**\n"
        MethodTable[#MethodTable+1] = Method.Description.."\n"
        MethodTable[#MethodTable+1] = "Parameter | Type | Required | Description\n"
        MethodTable[#MethodTable+1] = "----------|------|----------|------------\n"
        for _, Parameter in ipairs(Method.Parameters) do
            MethodTable[#MethodTable+1] = Parameter.Name.." | "..Parameter.Type.." | "..Parameter.Required.." | "..Parameter.Description.."\n"
        end
        MethodTable[#MethodTable+1] = "\n"
        MethodTable[#MethodTable+1] = "**Return:** "..Method.Return.."  \n"
        if #Method.MethodComments > 0 then
            local CommentTable = {}
            for _, Comment in ipairs(Method.MethodComments) do
                CommentTable[#CommentTable+1] = Comment.."  \n"
            end
            local CommentTableString = table.concat(CommentTable)
            MethodTable[#MethodTable+1] = CommentTableString
        end
        if #Method.LuaComments > 0 then
            local CommentTable = {}
            CommentTable[#CommentTable+1] = "**Usage:**\n"
            CommentTable[#CommentTable+1] = "```lua\n"
            for _, Comment in ipairs(Method.LuaComments) do
                CommentTable[#CommentTable+1] = Comment.."\n"
            end
            CommentTable[#CommentTable+1] = "```\n"
            local LuaUsageString = table.concat(CommentTable)
            MethodTable[#MethodTable+1] = LuaUsageString
        end
        MethodTable[#MethodTable+1] = "---"
        local MethodTableString = table.concat(MethodTable).."\n"
        ReadmeFile:write(MethodTableString)
        ReadmeFile:flush()
    end
    ReadmeFile:close()
end

local function ParseMethodsFromFile(FilePath)
    for line in io.lines(FilePath) do
        -- do comment block first
        if line:sub(1, CommentBlockStartString:len()) == CommentBlockStartString then
            local Description = line:sub(CommentBlockStartString:len() + 2)
            if Description:find("%s+") then
                CurrentMethod = Methods[AddMethodIndex()]
                CurrentMethod.Description = Description
            end
        end
        -- do parameters
        if line:sub(1, ParamString:len()) == ParamString then
            local ParamInfo = line:sub(ParamString:len() + 2)
            local Type = ParamInfo:match('.*#(%a+)')
            local Required = ParamInfo:match("%<%*%>")
            local Description = ParamInfo:match("%[(.*)%]")
            local Name = ParamInfo:match('%s+(%a+)')
            if not Description then Description = "" end
            if Required then
                Required = "**✓**"
            else
                Required = ""
            end
            CurrentMethod.Parameters[#CurrentMethod.Parameters+1] = {
                ["Name"] = Name,
                ["Type"] = Type,
                ["Required"] = Required,
                ["Description"] = Description
            }
        end
        -- do returns
        if line:sub(1, ReturnString:len()) == ReturnString then
            local Return = line:sub(ReturnString:len() + 2)
            CurrentMethod.Return = Return
        end

        -- do examples
        if line:sub(1, LuaCommentString:len()) == LuaCommentString then
            local LuaComment = line:sub(LuaCommentString:len() + 2)
            CurrentMethod.LuaComments[#CurrentMethod.LuaComments+1] = LuaComment
        end

        if line:sub(1, MethodComment:len()) == MethodComment then
            local Comment = line:sub(MethodComment:len() + 2)
            CurrentMethod.MethodComments[#CurrentMethod.MethodComments+1] = Comment
        end
        -- do functions
        if line:sub(1, FunctionString:len()) == FunctionString then
            if line:find(":") then
                table.remove(CurrentMethod.Parameters, 1)
            end
            local functionSyntax = line
            local functionName = line:sub(FunctionString:len() + 2)
            CurrentMethod.FunctionSyntax = functionSyntax
            CurrentMethod.FunctionName = functionName
        end
    end
end

ParseMethodsFromFile(SourceFilePath)
WriteMethodsToFile(ReadmeFilePath)