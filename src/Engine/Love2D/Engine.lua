local profile = require("Engine.Love2D.Profiler")
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
local mouseDownLookup = {
    LEFTBUTTON = 1,
    RIGHTBUTTON = 2,
    MIDDLEBUTTON = 3,
    MOUSE4 = 4,
    MOUSE5 = 5,
}
local keyboardDownLookup = {

}
function Engine:IsKeyDown(keyName)
    if keyName == "WHEELUP" then
        return self._currentMouseDown == "up"
    elseif keyName == "WHEELDOWN" then
        return self._currentMouseDown == "down"
    end

    local mouseLookup = mouseDownLookup[keyName]

    if mouseLookup then
        return love.mouse.isDown(mouseLookup)
    end
    return false
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

function Engine:RenderFrame()
    if self._mouseWheel > 0 then
        self._currentMouseDown = "up"
    elseif self._mouseWheel < 0 then
        self._currentMouseDown = "down"
    else
        self._currentMouseDown = nil
    end

    self._mouseWheel = 0

    if self._showDebugStats then
        local stats = love.graphics.getStats()
        local height = 24
        local font = "VAR"
        local statsText = string.format(
            "FPS: %.2f\n" ..
            "Draws: %i\n" ..
            "Canvas Switches: %i\n" ..
            "Texture Memory (MB): %i\n" ..
            "Images Loaded: %i\n" ..
            "Canvases: %i\n" ..
            "Fonts: %i\n" ..
            "Shader Switches: %i\n" ..
            "Draw Calls Batched: %i",
            love.timer.getFPS(),
            stats.drawcalls,
            stats.canvasswitches,
            stats.texturememory / 1024,
            stats.images,
            stats.canvases,
            stats.fonts,
            stats.shaderswitches,
            stats.drawcallsbatched
        )
        local width = graphics:DrawStringWidth(height, font, statsText)
        graphics:SetDrawColor(0, 0, 0, 0.5)
        graphics:DrawImage(nil, 0, 0, width + 10, (select(2, graphics:GetScreenSize())))
        graphics:SetDrawColor(1, 1, 1, 1)
        graphics:DrawString(5, 5, "LEFT", height, font, statsText)
    end
end

local keyLookups = {
    tab = "TAB",
    ["return"] = "RETURN",
    escape = "ESCAPE",
    lshift = "SHIFT",
    rshift = "SHIFT",
    lctrl = "CTRL",
    rctrl = "CTRL",
    lalt = "ALT",
    ralt = "ALT",
    pause = "PAUSE",
    pageup = "PAGEUP",
    pagedown = "PAGEDOWN",
    ["end"] = "END",
    home = "HOME",
    printscreen = "PRINTSCREEN",
    insert = "INSERT",
    f1 = "F1",
    f2 = "F2",
    f3 = "F3",
    f4 = "F4",
    f5 = "F5",
    f6 = "F6",
    f7 = "F7",
    f8 = "F8",
    f9 = "F9",
    f10 = "F10",
    f11 = "F11",
    f12 = "F12",
    f14 = "F14",
    f15 = "F15",
    numlock = "NUMLOCK",
    scrolllock = "SCROLLLOCK",
}

local mouseLookups = {
    "LEFTBUTTON",
    "RIGHTBUTTON",
    "MIDDLEBUTTON",
    "MOUSE4",
    "MOUSE5",
}

function Engine:Start()
    if self._hasStarted then
        error("already started")
    end

    function love.wheelmoved(x, y)
        self._mouseWheel = self._mouseWheel + y
        if y < 0 then
            callbacks:Run("OnKeyDown", "WHEELDOWN")
            callbacks:Run("OnKeyUp", "WHEELDOWN")
        elseif y > 0 then
            callbacks:Run("OnKeyDown", "WHEELUP")
            callbacks:Run("OnKeyUp", "WHEELUP")
        end
    end

    function love.keypressed(key, scanCode, isRepeat)
        if not isRepeat then
            if key == "f8" then
                self._showDebugStats = not self._showDebugStats
            elseif key == "f9" then
                profile.start()
            elseif key == "f10" then
                profile.stop()
            elseif key == "f11" then
                error(profile.report())
            end
        end
        if not isRepeat and keyLookups[key] then
            callbacks:Run("OnKeyDown", keyLookups[key])
        end
    end

    function love.keyreleased(key, scanCode)
        if not isRepeat and keyLookups[key] then
            callbacks:Run("OnKeyUp", keyLookups[key])
        end
    end

    function love.mousepressed(x, y, button, isTouch, presses)
        if mouseLookups[button] then
            callbacks:Run("OnKeyDown", mouseLookups[button], presses > 1)
        end
    end

    function love.mousereleased(x, y, button, isTouch, presses)
        if mouseLookups[button] then
            callbacks:Run("OnKeyUp", mouseLookups[button], presses > 1)
        end
    end

    self._hasStarted = true
    callbacks:Run("OnInit")
end

return {
    New = function()
        return setmetatable({
            _mouseWheel = 0,
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