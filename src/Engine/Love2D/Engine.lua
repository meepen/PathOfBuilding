local Engine = {}
local EngineMt = { __index = Engine }

function Engine:NewFileSearch(spec, includeFolders)
    return self._NewFileSearch(spec, includeFolders)
end

-- General Functions
function Engine:SetWindowTitle(title)
    return self._SetWindowTitle(title)
end
function Engine:GetCursorPos()
	return love.mouse.getPosition()
end
function Engine:ShowCursor(doShow)
    return self._ShowCursor(doShow)
end

--[[
    Must support at least:

	"LEFTBUTTON", "MIDDLEBUTTON", "RIGHTBUTTON", "MOUSE4", "MOUSE5", "WHEELUP",
    "WHEELDOWN", "BACK", "TAB", "RETURN", "ESCAPE", "SHIFT", "CTRL", "ALT",
    "PAUSE", "PAGEUP", "PAGEDOWN", "END", "HOME", "PRINTSCREEN", "INSERT",
    "DELETE", "UP", "DOWN", "LEFT", "RIGHT", "F1", "F2", "F3", "F4", "F5",
    "F6", "F7", "F8", "F9", "F10", "F11", "F12", "F13", "F14", "F15",
    "NUMLOCK", "SCROLLLOCK",
]]
function Engine:IsKeyDown(keyName)
    return false -- self._IsKeyDown(keyName)
end
function Engine:Copy(text)
    return self._Copy(text)
end
function Engine:Paste()
    return self._Paste()
end
function Engine:Deflate(data)
    return self._Deflate(data)
end
function Engine:Inflate(data)
    return self._Inflate(data)
end
function Engine:GetTime()
    return self._GetTime()
end
function Engine:GetScriptPath()
	return self._GetScriptPath()
end
function Engine:GetRuntimePath()
	return self._GetRuntimePath()
end
function Engine:GetUserPath()
	return self._GetUserPath()
end
function Engine:MakeDir(path) 
	return self._MakeDir(path)
end
function Engine:RemoveDir(path)
	return self._RemoveDir(path)
end
function Engine:GetWorkDir()
	return self._GetWorkDir()
end
function Engine:SpawnProcess(cmdName, args)
    return self._SpawnProcess(cmdName, args)
end
function Engine:OpenURL(url)
    return self._OpenURL(url)
end
function Engine:Restart()
    return self._Restart()
end
function Engine:Exit()
    return self._Exit()
end


function Engine:LaunchSubScript(scriptText, funcList, subList, ...)
    return self._LaunchSubScript(scriptText, funcList, subList, ...)
end
function Engine:AbortSubScript(ssID)
    return self._AbortSubScript(ssID)
end
function Engine:IsSubScriptRunning(ssID)
    return self._:IsSubScriptRunning(ssID)
end

function Engine:Start()
    if self._hasStarted then
        error("already started")
    end
    self._hasStarted = true
    callbacks:Run("OnInit")
end

return {
    New = function()
        return setmetatable({
            _NewFileSearch = NewFileSearch,
            _SetWindowTitle = love.window.setTitle,
            _ShowCursor = love.mouse.setVisible,
            _IsKeyDown = IsKeyDown,
            _Copy = love.system.getClipboardText,
            _Paste = love.system.setClipboardText,
            _Inflate = Inflate,
            _Deflate = Deflate,
            _GetTime = function() return math.floor(love.timer.getTime() * 1000) end,
            _GetScriptPath = love.filesystem.getWorkingDirectory,
            _GetRuntimePath = love.filesystem.getWorkingDirectory,
            _GetUserPath = love.filesystem.getUserDirectory,
            _MakeDir = love.filesystem.createDirectory,
            _RemoveDir = love.filesystem.remove,
            _GetWorkDir = love.filesystem.getWorkingDirectory,
            _SpawnProcess = SpawnProcess,
            _OpenURL = OpenURL,
            _Restart = function() love.event.quit("restart") end,
            _Exit = function() love.event.quit() end,
            _LaunchSubScript = LaunchSubScript,
        }, EngineMt)
    end,
}