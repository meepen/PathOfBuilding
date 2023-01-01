local Callbacks = {}
local CallbacksMt = { __index = Callbacks }

function Callbacks:Run(name, ...)
	if self.callbacks[name] then
		return self.callbacks[name][name](...)
	end
	if self.mainObject and self.mainObject[name] then
		return self.mainObject[name](self.mainObject, ...)
	end
end
function Callbacks:Set(name, func)
	self.callbacks[name] = func
end
function Callbacks:Get(name)
	return self.callbacks[name]
end
function Callbacks:SetMainObject(obj)
	self.mainObject = obj
end

return {
	New = function()
		return setmetatable({
			callbacks = {},
		}, CallbacksMt)
	end,
}