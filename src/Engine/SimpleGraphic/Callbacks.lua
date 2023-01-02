local Callbacks = {}
local CallbacksMt = { __index = Callbacks }

function Callbacks:Run(name, ...)
    return self._runCallback(name, ...)
end
function Callbacks:Set(name, func)
    return self._setCallback(name, func)
end
function Callbacks:Get(name)
    return self._getCallback(name)
end
function Callbacks:SetMainObject(obj)
    return self._setMainObject(obj)
end

return {
	New = function()
		return setmetatable({
            _runCallback = runCallback,
            _setCallback = SetCallback,
            _getCallback = GetCallback,
            _setMainObject = SetMainObject,
		}, CallbacksMt)
	end,
}