--[[
@script markdown-lua

@authors Wizard

@created June 19, 2022

@description
convert lua comment blocks and LuaDoc formatted function comments into markdown text.

@features
- easy to use
- easy to read markdown final text

]]

--- get a new person
-- you can add additional comments
-- to describe how the function works
-- @param #string name <*> [the name of the person]
-- @param #number agem [optional age of the person]
-- @return #table person
-- @usage
-- ``` local wizard = newPerson("wizard", 23)
-- ``` if wizard.age >= 26 then
-- ```     print("buy insurance!")
-- ``` end
-- function newPerson(name , age)

local sourceFilePath = "C:/_gitMaster/DCS-Spawn/Spawn.lua"
local readmeFilePath = "C:/_gitMaster/DCS-Spawn/README.md"

local function getLines()
    local lines = {}
    for line in io.lines(sourceFilePath) do
        lines[#lines+1] = line
    end
    return lines
end

local function getNextLine(lines, index)
    return lines[index + 1]
end

local function getDescription(lines, index)
    local description = {}
    local function recurse(newIndex)
        if newIndex then
            local line = getNextLine(lines, index)
            if line and line:match("%-%-%s") then
                if not line:match("%-%-%s@") then
                    description[#description+1] = line:match("%-%-%s(.*)")
                    index = index + 1
                    recurse(true)
                end
            end
        else
            local line = lines[index]
            description[#description+1] = line:match("%-%-%-%s(.*)")
            recurse(true)
        end
        return description, index
    end
    return recurse()
end

local function getParams(lines, index)
    local params = {}
    local function recurse(newIndex)
        if newIndex then
            index = index + 1
        end
        local line = getNextLine(lines, index)
        if line and line:match("%-%-%s@param") then
            local name = line:match("%s(%a+)")
            local type = line:match("%#(%a+)")
            local required = line:match("%<%*%>")
            local description = line:match("%[(.*)%]") or ""
            if required then
                required = "**✓**"
            else
                required = "**X**"
            end
            params[#params+1] = name.." | "..type.." | "..required.." | "..description
            recurse(true)
        end
        return params, index
    end
    return recurse()
end

local function getReturns(lines, index)
    local returns = {}
    local function recurse(newIndex)
        if newIndex then
            index = index + 1
        end
        local line = getNextLine(lines, index)
        if line and line:match("%-%-%s@return") then
            local name = line:match("%s(%a+)")
            local type = line:match("%#(%a+)")
            if name == "none" then type = "" end
            returns[#returns+1] = name.." | "..type
            recurse(true)
        end
        return returns, index
    end
    return recurse()
end

local function getUsage(lines, index)
    local usage = {}
    local function recurse(newIndex)
        if newIndex then
            index = index + 1
            local line = getNextLine(lines, index)
            if line and line:match("%-%-%s%`%`%`") then
                local luaComment = ""
                if line:match("%-%-%s%`%`%`%s") then
                    luaComment = line:match("%-%-%s%`%`%`%s(.*)")
                end
                usage[#usage+1] = luaComment
                recurse(true)
            end
        end
        local line = getNextLine(lines, index)
        if line and line:match("%-%-%s@usage") then
            recurse(true)
        end
        return usage, index
    end
    return recurse()
end

local function getFunction(lines, index)
    local line = getNextLine(lines, index)
    if line:match("function%s") then
        return line:match("function%s(.*)")
    end
end

local function getFuncDocs(lines, index)
    local docs = {}
    docs.desc, index = getDescription(lines, index)
    docs.params, index = getParams(lines, index)
    docs.returns, index = getReturns(lines, index)
    docs.usage, index = getUsage(lines, index)
    docs.func = getFunction(lines, index)
    return docs
end

local function writeHeader(file, header)
    file:write("## ***"..header.."***\n")
end

local function writeDescription(file, description)
    for _, desc in pairs(description) do
        file:write(desc.."  \n")
    end
end

local function writeParams(file, params)
    file:write("Parameter | Type | Required | Description\n")
    file:write("-|-|-|-\n")
    for _, param in pairs(params) do
        file:write(param.."\n")
    end
    file:write("\n")
end

local function writeReturns(file, returns)
    file:write("Return | Type\n")
    file:write("-|-\n")
    for _, _return in pairs(returns) do
        file:write(_return.."\n")
    end
    file:write("\n")
end

local function writeUsage(file, usage)
    file:write("```lua\n")
    for _, example in pairs(usage) do
        file:write(example.."\n")
    end
    file:write("```\n")
    file:write("\n")
end

local function writeFuncDocs(file, docs)
    if docs.func then
        writeHeader(file, docs.func)
        writeDescription(file, docs.desc)
        writeParams(file, docs.params)
        writeReturns(file, docs.returns)
        writeUsage(file, docs.usage)
    end
end

local function getBlock(lines, index)
    local block = {}
    local function recurse(newIndex)
        if newIndex then
            index = index + 1
        end
        local line = getNextLine(lines, index)
        if not line:match("%]%]") then
            if line:match("@script") or line:match("@class") then
                local header = line:match("@%a+%s(.*)")
                block[#block+1] = "# ***"..header.."***\n"
            elseif line:match("@authors") then
                local authors = line:match("@%a+%s(.*)")
                block[#block+1] = "\n**Authors:** "..authors.."  \n"
            elseif line:match("@created") then
                local created = line:match("@%a+%s(.*)")
                block[#block+1] = "\n**Created:** "..created.."  \n"
            elseif line:match("@github") then
                -- do nothing if github, why link to readme's
            elseif line:match("@version") then
                local version = line:match("@%a+%s(.*)")
                block[#block+1] = "\n**Version:** "..version.."  \n"
            elseif line:match("@description") then
                block[#block+1] = "\n**Description:**  \n"
            elseif line:match("@features") then
                block[#block+1] = "\n**Features:**  \n"
            elseif not line:match("@") and line:match("%a") then
                local text = line:match("(.*)")
                if line:sub(1) == "%*%s" or line:sub(1) == "%-%s" then
                    block[#block+1] = text.."\n"
                else
                    block[#block+1] = text.."  \n"
                end
            end
            recurse(true)
        else
            block[#block+1] = "\n"
        end
        return block
    end
    return recurse()
end

local function writeBlock(file, block)
    for _, line in pairs(block) do
        file:write(line)
    end
end

local function main()
    local lines = getLines()
    local file = io.open(readmeFilePath, "w+")
    for index, line in ipairs(lines) do
        if line:match("%-%-%-%s%a+") then
            -- collect function docs
            local docs = getFuncDocs(lines, index)
            writeFuncDocs(file, docs)
        elseif line:find("%-%-%[%[") then
            -- collect comment block info
            local block = getBlock(lines, index)
            writeBlock(file, block)
        end
    end
    file:close()
end

main()