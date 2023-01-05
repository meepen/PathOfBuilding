local SearchHandle = {}
local SearchHandleMt = {
    __index = SearchHandle,
}

function SearchHandle:NextFile() --> boolean
    self.resultIndex = self.resultIndex + 1

    return self.resultIndex <= #self.results
end

function SearchHandle:GetFileName()
    local result = self.results[self.resultIndex]

    return result
end

function SearchHandle:GetFileSize()
    return love.filesystem.getInfo(self.folder .. self:GetFileName()).size
end

function SearchHandle:GetFileModifiedTime()
    return love.filesystem.getInfo(self.folder .. self:GetFileName()).modtime
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
            or not love.filesystem.getInfo(self.folder .. result, self.onlyDirectories and "directory" or "file") then

            table.remove(self.results, i)
        end
    end

    return self
end

local FileSystem = {}
local FileSystemMt = {
    __index = FileSystem
}

function FileSystem:NewSearchHandle(spec, onlyDirectories)
    local folder, searchingFor = (" " .. spec):match("^([^%*]+)(.*)$")
    folder = folder:sub(2) -- remove " "

    local allowedStarts = {
        love.filesystem.getSaveDirectory(),
        love.filesystem.getSource(),
    }

    local allowed = false
    for _, potentialStart in ipairs(allowedStarts) do
        if folder:sub(1, potentialStart:len()) == potentialStart then
            folder = folder:sub(potentialStart:len() + 1)
            allowed = true
            break
        end
    end

    if not allowed then
        print("Not allowed directory: ", folder)
        return
    end
    if folder:sub(-1) == "/" or folder:sub(-1) == "\\" then
        folder = folder:sub(1, -2)
    end
    if folder:sub(1, 1) == "/" or folder:sub(1, 1) == "\\" then
        folder = folder:sub(2)
    end

    local result = setmetatable({
        folder = folder == "" and folder or folder .. "/",
        results = love.filesystem.getDirectoryItems(folder),
        resultIndex = 1,
        filter = searchingFor or "*",
        onlyDirectories = onlyDirectories,
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
