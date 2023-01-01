local Image = {}
local ImageMt = {__index = Image}
function Image:Load(fileName, ...)
	return self.handle:Load(fileName, ...)
end
function Image:Unload()
	return self.handle:Unload()
end
function Image:IsValid()
	return self.handle:IsValid()
end
function Image:SetLoadingPriority(pri)
	return self.handle:Unload(pri)
end
function Image:ImageSize()
	return self.handle:ImageSize()
end

return {
    New = function()
        return setmetatable({
            handle = NewImageHandle()
        }, ImageMt)
    end,
}