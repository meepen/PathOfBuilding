local type, tonumber = type, tonumber
local setmetatable = setmetatable

local Graphics = {}
local GraphicsMt = { __index = Graphics, }
local function memoizeLookupTable(...)
    local args = { n = select("#", ...) - 1, ... }
    local __index = args[args.n + 1]
    local argumentIndex = {fake = true}
    local indexIndex = {fake = true}
    local nilIndex = {}

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
            if k == nil then
                local v = rawget(self, nilIndex)
                if v ~= nil then
                    return v
                end
            end
            local memoizedArgs = copyAndAdd(
                self[argumentIndex],
                args[self[indexIndex]],
                k
            )
            if k == nil then
                k = nilIndex
            end
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
        end,
    }
    local memoized = setmetatable({
        [argumentIndex] = {},
        [indexIndex] = 1
    }, memoizeMt)

    return memoized
end

Graphics._meshLookup = memoizeLookupTable("img", function(args)
    local mesh = love.graphics.newMesh({
        { 0, 0, 0, 0 },
        { 1, 0, 1, 0 },
        { 1, 1, 1, 1 },
        { 0, 1, 0, 1 },
    }, "fan", "stream")

    if args.img then
        mesh:setTexture(args.img.handle)
    end
    return mesh
end)

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

    return love.graphics.setColor(r, g, b, a)
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
            love.graphics.draw(img.handle, self.translateX + left, self.translateY + top, 0, sx, sy)
        end
    else
        love.graphics.rectangle("fill", self.translateX + left, self.translateY + top, width, height)
    end
end


function Graphics:DrawImageQuad(img, x1, y1, x2, y2, x3, y3, x4, y4, s1, t1, s2, t2, s3, t3, s4, t4)
    local xOffset, yOffset = self.translateX, self.translateY
    if not s1 then
        s1, t1, s2, t2, s3, t3, s4, t4 = 
            0, 0,
            1, 0,
            1, 1,
            0, 1
    end

    local _mesh = self._meshLookup[img]
    
    _mesh:setVertex(1, xOffset + x1, yOffset + y1, s1, t1)
    _mesh:setVertex(2, xOffset + x2, yOffset + y2, s2, t2)
    _mesh:setVertex(3, xOffset + x3, yOffset + y3, s3, t3)
    _mesh:setVertex(4, xOffset + x4, yOffset + y4, s4, t4)

    love.graphics.draw(_mesh)
end

function Graphics:DrawString(left, top, align, height, font, text)
    text = tostring(text)
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
            love.graphics.print(data, self.translateX + left, self.translateY + top)
            left = left + fontObject:getWidth(data)
        end
    end
end

function Graphics:DrawStringWidth(height, font, text)
    text = tostring(text)
    local fontObject = love.graphics.getFont()
    return fontObject:getWidth(self:StripEscapes(text))
end

function Graphics:DrawStringCursorIndex(height, font, text, cursorX, cursorY)
    -- given font height, find which character inside given `text` would be the caret position
    -- when cursor is clicked at `cursorX` `cursorY`.

    local fontObject = love.graphics.getFont() -- TODO: get actual font

    local lineY = 0
    for currentIndex, line in text:gmatch("()([^\n]+)\n?") do
        lineY = lineY + fontObject:getLineHeight()

        if lineY <= cursorY then
            -- maybe we should support utf8 here? do we have support anywhere else in PoB?

            local split = self:SplitColoredText(line)

            local i = 0

            local currentLine = ""
            
            for _, text in ipairs(split) do
                if type(text) == "table" then
                    i = i + text.size
                else
                    for j = 1, text:len() do
                        currentLine = currentLine .. text:sub(j, j)
                        if cursorX <= fontObject:getWidth(currentLine) then
                            return currentIndex + i
                        end
                        i = i + 1
                    end
                end
            end

            return i + 1
        end
    end

    return text:len()
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
    [0] = {0, 0, 0, 1, size = 2}, -- black
    [1] = {1, 0, 0, 1, size = 2}, -- red
    [2] = {0, 1, 0, 1, size = 2}, -- green
    [3] = {0, 0, 1, 1, size = 2}, -- blue
    [4] = {1, 1, 0, 1, size = 2}, -- yellow
    [5] = {1, 0, 1, 1, size = 2}, -- purple
    [6] = {0, 1, 1, 1, size = 2}, -- aqua
    [7] = {1, 1, 1, 1, size = 2}, -- white
    [8] = {0.7, 0.7, 0.7, 1, size = 2}, -- gray
    [9] = {0.4, 0.4, 0.4, 1, size = 2}, -- dark gray
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
                        size = 8,
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
	return (tostring(text):gsub("%^%d",""):gsub("%^[xX]%x%x%x%x%x%x",""))
end

function Graphics:SetDrawLayer(layer, subLayer)
    if layer then
        self._layer = layer
    else
        layer = self._layer
    end
    if not subLayer then
        subLayer = 0
    end

    local activeLayer = self._layerLookup[layer + subLayer / 1000]

    if activeLayer == self._activeLayer then
        return
    end
    
    self._activeLayer = activeLayer
    love.graphics.setCanvas(activeLayer.canvas)
    if self._activeLayer._lastFrame ~= self.frame then
        self._activeLayer._lastFrame = self.frame
    end
end

function Graphics:SetViewport(x, y, width, height)
    if x then
        self.translateX, self.translateY = x, y
        love.graphics.setScissor(x, y, width, height)
    else
        self.translateX, self.translateY = 0, 0
        love.graphics.setScissor()
    end
end

function Graphics:RenderFrame()
    local lastWidth, lastHeight = self._lastWidth, self._lastHeight
    self._lastWidth, self._lastHeight = self:GetScreenSize()
    if lastWidth ~= self._lastWidth or lastHeight ~= self._lastHeight then
        for _, layer in pairs(self._layers) do
            layer.canvas:release()
            layer.canvas = love.graphics.newCanvas(self._lastWidth, self._lastHeight)
        end
    end

    love.graphics.setScissor()
    for _, layer in ipairs(self._layers) do
        if self.frame == layer._lastFrame then
            love.graphics.setCanvas(layer.canvas)
            love.graphics.clear()
        end
    end
    love.graphics.setCanvas()
    love.graphics.clear(1, 0, 0, 1)
    self._activeLayer = nil

    self.frame = self.frame + 1

    self:SetDrawLayer(0, 0)
    self:SetDrawColor(1, 1, 1, 1)
    callbacks:Run("OnFrame")
end

function Graphics:_Present()
    love.graphics.setCanvas()
    love.graphics.setScissor()
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1, 1)
    for _, layer in ipairs(self._layers) do
        if self.frame == layer._lastFrame then
            love.graphics.draw(layer.canvas, 0, 0)
        end
    end
end

local function canvasSorter(a, b)
    return a.layer < b.layer
end

return {
    New = function()
        local newObject
        newObject = setmetatable({
            frame = 0,
            translateX = 0,
            translateY = 0,
            _layers = {},
            _layerLookup = memoizeLookupTable("layer", function(args)
                local newLayer = {
                    layer = args.layer,
                    canvas = love.graphics.newCanvas(newObject:GetScreenSize()),
                }
                if not args.layer then
                    error "layer required"
                end
                table.insert(newObject._layers, newLayer)
                table.sort(newObject._layers, canvasSorter)

                return newLayer
            end),
            _screenState = {
                vsync = 1,
                resizable = true,
            },
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

            newObject:RenderFrame()
            newObject:_Present()

            engine:RenderFrame()
        end

        return newObject
    end
}