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
	return self._GetCursorPos()
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
    return self._IsKeyDown(keyName)
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

return {
    New = function()
        return setmetatable({
            _NewFileSearch = NewFileSearch,
            _SetWindowTitle = SetWindowTitle,
            _GetCursorPos = GetCursorPos,
            _ShowCursor = ShowCursor,
            _IsKeyDown = IsKeyDown,
            _Copy = Copy,
            _Paste = Paste,
            _Inflate = Inflate,
            _Deflate = Deflate,
            _GetTime = GetTime,
            _GetScriptPath = GetScriptPath,
            _GetRuntimePath = GetRuntimePath,
            _GetUserPath = GetUserPath,
            _MakeDir = MakeDir,
            _RemoveDir = RemoveDir,
            _GetWorkDir = GetWorkDir,
            _SpawnProcess = SpawnProcess,
            _OpenURL = OpenURL,
            _Restart = Restart,
            _Exit = Exit,
            _LaunchSubScript = LaunchSubScript,
        }, EngineMt)
    end,
}