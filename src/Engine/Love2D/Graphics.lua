local type, tonumber = type, tonumber
local setmetatable = setmetatable

local Graphics = {}
local GraphicsMt = { __index = Graphics, }

function GraphicsMt:__gc()
end

function Graphics:RenderInit()
    return self:_UpdateMode()
end

function Graphics:_UpdateMode()
    local width, height = self:GetScreenSize()
    return love.window.setMode(width, height, self._screenState)
end

function Graphics:GetScreenSize()
    return self._GetScreenSize()
end
function Graphics:SetClearColor(r, g, b, a)
    self._clearColor = { r, g, b, a or 1 }
end

local memoizedColors = setmetatable({}, {
    __index = function(self, str)
        local bytes = {string.byte(str, 1, -1)}
        local col
        if bytes[1] == 0x5E then -- '^'
            local nextByte = bytes[2]
            if (nextByte == 0x58 or nextByte == 0x78) and str:len() == 8 then
                col = {
                    tonumber(str:sub(3, 4), 16) / 255, -- r
                    tonumber(str:sub(5, 6), 16) / 255, -- g
                    tonumber(str:sub(7, 8), 16) / 255, -- b
                    1, -- a
                }
            elseif nextByte - 0x30 < 10 and str:len() == 2 then -- '0'
                col = Graphics._ColorEscapes[nextByte - 0x30]
            end
        end

        if not col then
            error((str:gsub(".", function(a) return string.format("%02x", a:byte()) end)))
        end

        self[str] = col

        return col
    end,
    __mode = "k",
})

function Graphics:SetDrawColor(r, g, b, a)
    if type(r) == "string" then
        r = memoizedColors[r]
        r, g, b, a = r[1], r[2], r[3], r[4]
    end

    return self._SetDrawColor(r, g, b, a)
end
function Graphics:DrawImage(img, left, top, width, height, tcLeft, tcTop, tcRight, tcBottom)
    if img then
        local sx, sy = 1, 1
        local realWidth, realHeight = img:ImageSize()
        if width and height and width ~= 0 then
            if realWidth ~= 0 then
                sx = width / realWidth
                sy = height / realHeight
            end
        end

        if tcLeft then
            self:DrawImageQuad(
                img, 
                left, top, 
                left + width, top, 
                left + width, top + height, 
                left, top + height,
                tcLeft, tcTop,
                tcRight, tcTop,
                tcRight, tcBottom,
                tcLeft, tcBottom
            )
        else
            love.graphics.draw(img.handle, left, top, 0, sx, sy)
        end
    else
        love.graphics.rectangle("fill", left, top, width, height)
    end
end

local function memoizeLookupTable(...)
    local args = { n = select("#", ...) - 1, ... }
    local __index = args[args.n + 1]
    local argumentIndex = {}
    local indexIndex = {}

    local function copyAndAdd(t, k, v)
        local result = {}
        for k, v in pairs(t) do
            result[k] = v
        end
        result[k] = v
        return result
    end

    local memoizeMt 
    memoizeMt = {
        __index = function(self, k)
            local memoizedArgs = copyAndAdd(self[argumentIndex], args[self[indexIndex]], k)
            local value
            if (self[indexIndex] == args.n) then
                value = __index(memoizedArgs)
            else
                value = setmetatable({
                    [argumentIndex] = memoizedArgs,
                    [indexIndex] = self[indexIndex] + 1
                }, memoizeMt)
            end
            self[k] = value
            return value
        end
    }
    local memoized = setmetatable({
        [argumentIndex] = {},
        [indexIndex] = 1
    }, memoizeMt)

    return memoized
end

Graphics._mesh = love.graphics.newMesh({
    { 0, 0, 0, 0 },
    { 1, 0, 1, 0 },
    { 1, 1, 1, 1 },
    { 0, 1, 0, 1 },
}, "fan", "stream")

function Graphics:DrawImageQuad(img, x1, y1, x2, y2, x3, y3, x4, y4, s1, t1, s2, t2, s3, t3, s4, t4)
    if not s1 then
        s1, t1, s2, t2, s3, t3, s4, t4 = 
            0, 0,
            1, 0,
            1, 1,
            0, 1
    end

    local _mesh = self._mesh
    
    _mesh:setVertex(1, x1, y1, s1, t1)
    _mesh:setVertex(2, x2, y2, s2, t2)
    _mesh:setVertex(3, x3, y3, s3, t3)
    _mesh:setVertex(4, x4, y4, s4, t4)

    if img then
        _mesh:setTexture(img.handle)
    end

    love.graphics.draw(_mesh)
end
function Graphics:DrawString(left, top, align, height, font, text)
    text = tostring(text)
    local r, g, b, a = love.graphics.getColor()
    local fontObject = love.graphics.getFont()

    if align == "CENTER" then
        local screenWidth = self:GetScreenSize()
        left = math.floor((screenWidth - fontObject:getWidth(self:StripEscapes(text))) / 2 + left)
    elseif align == "RIGHT" then
        local screenWidth = self:GetScreenSize()
        left = math.floor(screenWidth - fontObject:getWidth(self:StripEscapes(text)) - left)
    elseif align == "CENTER_X" then
        local totalWidth = fontObject:getWidth(self:StripEscapes(text))
        left = math.floor(left - totalWidth / 2)
    elseif align == "RIGHT_X" then
        local totalWidth = fontObject:getWidth(self:StripEscapes(text))
        left = math.floor(left - totalWidth)
    elseif align and align ~= "LEFT" and align ~= "LEFT_X" then
        error("unsupported alignment: " .. align)
    end

    for _, data in ipairs(self:SplitColoredText(text)) do
        if type(data) == "table" then -- color
            love.graphics.setColor(data[1], data[2], data[3], data[4])
        else
            love.graphics.print(data, left, top)
            left = left + fontObject:getWidth(data)
        end
    end

    love.graphics.setColor(r, g, b, a)
end
function Graphics:DrawStringWidth(height, font, text)
    text = tostring(text)
    local fontObject = love.graphics.getFont()
    return fontObject:getWidth(self:StripEscapes(text))
end
function Graphics:DrawStringCursorIndex(height, font, text, cursorX, cursorY)
	--return self._DrawStringCursorIndex(height, font, text, cursorX, cursorY)
end

--[[
     * Color escapes can be one of:
       * /\^[0-9]/
       * /\^x[0-9a-fA-F]{6}/
]]


Graphics._HexaLookup  = {}
for i = 0, 255 do
    Graphics._HexaLookup[i] = false
end

for i = string.byte("0"), string.byte("9") do
    Graphics._HexaLookup[i] = true
end
for i = string.byte("a"), string.byte("f") do
    Graphics._HexaLookup[i] = true
end
for i = string.byte("A"), string.byte("F") do
    Graphics._HexaLookup[i] = true
end

-- Represents colors with '^' [0-9]
Graphics._ColorEscapes = {
    [0] = {0, 0, 0, 1}, -- black
    [1] = {1, 0, 0, 1}, -- red
    [2] = {0, 1, 0, 1}, -- green
    [3] = {0, 0, 1, 1}, -- blue
    [4] = {1, 1, 0, 1}, -- yellow
    [5] = {1, 0, 1, 1}, -- purple
    [6] = {0, 1, 1, 1}, -- aqua
    [7] = {1, 1, 1, 1}, -- white
    [8] = {0.7, 0.7, 0.7, 1}, -- gray
    [9] = {0.4, 0.4, 0.4, 1}, -- dark gray
}

function Graphics:SplitColoredText(text)
    text = tostring(text)
    local result = {}
    local resultLen = 0

    local bytes = {string.byte(text, 1, -1)}
    local textLen = #bytes

    local i = 1
    local lastSplit = i
    while i <= textLen do
        if bytes[i] == 0x5E then -- '^'
            local nextByte = bytes[i + 1]
            if (nextByte == 0x58 or nextByte == 0x78) and -- 'X' or 'x'
                string.len(text:sub(i + 2, i + 7):match("^[a-fA-F0-9]+$") or "") == 6 then 
                -- add last characters
                result[resultLen + 1], result[resultLen + 2], resultLen =
                    text:sub(lastSplit, i - 1), 
                    {
                        tonumber(text:sub(i + 2, i + 3), 16) / 255, -- r
                        tonumber(text:sub(i + 4, i + 5), 16) / 255, -- g
                        tonumber(text:sub(i + 6, i + 7), 16) / 255, -- b
                        1, -- a
                    },
                    resultLen + 2
                i = i + 8
                lastSplit = i
            elseif nextByte - 0x30 < 10 then -- '0'
                -- add last characters
                result[resultLen + 1], result[resultLen + 2], resultLen = 
                    text:sub(lastSplit, i - 1),
                    self._ColorEscapes[nextByte - 0x30],
                    resultLen + 2
                i = i + 2
                lastSplit = i
            else
                i = i + 1
            end
        else
            i = i + 1
        end
    end

    if lastSplit <= textLen then
        result[resultLen + 1], resultLen = text:sub(lastSplit), resultLen + 1
    end

    result.n = resultLen

    return result
end

function Graphics:StripEscapes(text)
	return (tostring(text):gsub("^%d",""):gsub("^x%x%x%x%x%x%x",""))
end

function Graphics:SetDrawLayer(layer, subLayer)
    if layer then
        self.curLayer = layer
    else
        layer = self.curLayer
    end
    if not subLayer then
        subLayer = 0
    end
    local layer = self._layerLookup[layer][subLayer]
    love.graphics.setCanvas(layer.canvas)
    if layer._lastFrame ~= self.frame then
        layer._lastFrame = self.frame
        love.graphics.clear(0, 0, 0, 0)
        self:SetViewport()
    end
end
function Graphics:SetViewport(x, y, width, height)
    for i = 1, love.graphics.getStackDepth() do
        love.graphics.pop()
    end
    if x then
        love.graphics.push()
            love.graphics.translate(x, y)
    end
end

function Graphics:RenderFrame()
    local width, height = self:GetScreenSize()
    if self._lastWidth ~= width or self._lastHeight ~= height then
        self._lastWidth, self._lastHeight = width, height

        self._layers = {}
        for k in pairs(self._layerLookup) do
            self._layerLookup[k] = nil
        end
    end

    self.frame = self.frame + 1
    local clearColor = self._clearColor
    love.graphics.clear(clearColor[1], clearColor[2], clearColor[3], clearColor[4])

    self:SetDrawLayer(0, 0)
    callbacks:Run("OnFrame")

    love.graphics.setCanvas()

    for _, layer in ipairs(self._layers) do
        if layer._lastFrame == self.frame then
            love.graphics.draw(layer.canvas)
        end
    end
end

local function canvasSorter(a, b)
    if a.layer < b.layer then
        return true
    elseif a.layer > b.layer then
        return false
    elseif a.subLayer < b.subLayer then
        return true
    else
        return false
    end
end

return {
    New = function()
        local newObject
        local subLayerMetatable = {
            __index = function(self, subLayer)
                local newLayer = {
                    canvas = love.graphics.newCanvas(),
                    layer = self.layer,
                    subLayer = subLayer
                }
                self[subLayer] = newLayer
                table.insert(newObject._layers, newLayer)
                table.sort(newObject._layers, canvasSorter)
                return newLayer
            end
        }
        newObject = setmetatable({
            frame = 0,
            _screenState = {
                vsync = 1,
                stencil = false,
                resizable = true,
            },
            _layers = {},
            _layerLookup = setmetatable({}, {
                __index = function(self, layer)
                    local sublayerLookup = setmetatable({layer = layer}, subLayerMetatable)
                    self[layer] = sublayerLookup
                    return sublayerLookup
                end
            }),
            _clearColor = {1, 0, 0, 1},
            _GetScreenSize   = love.graphics.getDimensions,
            _SetDrawColor    = love.graphics.setColor,
        }, GraphicsMt)

        
        function love.draw()
            love.graphics.setMeshCullMode("none")
            love.graphics.setDepthMode()
            if not engine._hasStarted then
                return
            end

            engine:RenderFrame()
            newObject:RenderFrame()
        end

        return newObject
    end
}