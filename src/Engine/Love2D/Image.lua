local Image = {}
local ImageMt = {__index = Image}
function Image:Load(fileName, ...)
    local settings = {}
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        if arg == "MIPMAP" then
            settings.mipmaps = true
        end
    end
    local success
    success, self.handle = pcall(love.graphics.newImage, fileName, settings)
    if success and self.handle then
        self.handle:setWrap("repeat", "repeat")
    else
        self.handle = nil
    end
end
function Image:Unload()
	self.handle = nil
end
function Image:IsValid()
	return not not self.handle
end
function Image:SetLoadingPriority(pri)
end
function Image:ImageSize()
    if not self.handle then
        return 0, 0
    end
	return self.handle:getWidth(), self.handle:getHeight()
end

return {
    New = function()
        return setmetatable({}, ImageMt)
    end,
}