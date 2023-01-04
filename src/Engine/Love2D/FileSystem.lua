local SearchHandle = {}
local SearchHandleMt = {
    __index = SearchHandle,
}
--[[
static int l_NewFileSearch(lua_State* L)
static int l_searchHandleNextFile(lua_State* L)
static int l_searchHandleGetFileName(lua_State* L)
static int l_searchHandleGetFileSize(lua_State* L)
static int l_searchHandleGetFileModifiedTime(lua_State* L)
]]

function SearchHandle:NextFile() --> boolean
    self.resultIndex = self.resultIndex + 1
    local result = self.results[self.resultIndex]

    return result
end

function SearchHandle:GetFileName()
    local result = self.results[self.resultIndex]

    return result
end

function SearchHandle:GetFileSize()
    return love.filesystem.getInfo(self:GetFileName()).size
end

function SearchHandle:GetFileModifiedTime()
    return love.filesystem.getInfo(self:GetFileName()).modtime
end

function SearchHandle:MatchesSpec(file, spec)
    if not spec or spec == "*" then
        return true
    elseif spec:sub(1, 1) == "*" then
        return file:sub(-spec:len() + 1) == spec:sub(2)
    else
        return spec == file
    end
end

function SearchHandle:FilterResults()
    for i = #self.results, 1, -1 do
        local result = self.results[i]

        if not self:MatchesSpec(result, self.filter) 
            or not self.findDirectories and not love.filesystem.getInfo(self.folder .. result, "file") then

            table.remove(self.results, i)
        end
    end

    return self
end

local FileSystem = {}
local FileSystemMt = {
    __index = FileSystem
}

function FileSystem:NewSearchHandle(spec, findDirectories)
    local folder, searchingFor = (" " .. spec):match("^([^%*]+)(.*)$")
    folder = folder:sub(2) -- remove " "
    local result = setmetatable({
        folder = folder,
        results = love.filesystem.getDirectoryItems(folder),
        resultIndex = 0,
        filter = searchingFor and searchingFor:sub(2) or "*",
        findDirectories = findDirectories,
    }, SearchHandleMt):FilterResults()

    if #result.results == 0 then
        return
    end

    return result
end

return {
    New = function()
        return setmetatable({}, FileSystemMt)
    end,
}
