
local Graphics = {}
local GraphicsMt = { __index = Graphics, }

function GraphicsMt:__gc()
end

function Graphics:RenderInit()
    return RenderInit()
end

function Graphics:GetScreenSize()
    return self._GetScreenSize()
end
function Graphics:SetClearColor(r, g, b, a)
    return self._SetClearColor(r, g, b, a)
end
function Graphics:SetDrawLayer(layer, ...) -- layer, subLayer
    return self._SetDrawLayer(layer, ...)
end
function Graphics:SetViewport(...) -- (x, y, width, height)
    return self._SetViewport(...)
end
function Graphics:SetDrawColor(r, g, b, a)
    return self._SetDrawColor(r, g, b, a)
end
function Graphics:DrawImage(img, left, top, width, height, ...) -- ...tcLeft, tcTop, tcRight, tcBottom)
    return self._DrawImage(img and img.handle or nil, left, top, width, height, ...) -- tcLeft, tcTop, tcRight, tcBottom)
end
function Graphics:DrawImageQuad(img, x1, y1, x2, y2, x3, y3, x4, y4, ...) -- ...s1, t1, s2, t2, s3, t3, s4, t4)
    return self._DrawImageQuad(img and img.handle or nil, x1, y1, x2, y2, x3, y3, x4, y4, ...) -- s1, t1, s2, t2, s3, t3, s4, t4)
end
function Graphics:DrawString(left, top, align, height, font, text)
    return self._DrawString(left, top, align, height, font, text)
end
function Graphics:DrawStringWidth(height, font, text)
    return self._DrawStringWidth(height, font, text)
end
function Graphics:DrawStringCursorIndex(height, font, text, cursorX, cursorY)
	return self._DrawStringCursorIndex(height, font, text, cursorX, cursorY)
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
    local result = {}
    local resultLen = 0

    local bytes = {string.byte(text, 1, -1)}
    local textLen = #bytes

    local i = 1
    local lastSplit = i
    while i <= textLen do
        if bytes[i] == 0x5E then -- '^'
            local nextByte = bytes[i + 1]
            if nextByte == 0x58 or nextByte == 0x78 then -- 'X' or 'x'
                -- add last characters
                result[resultLen + 1], result[resultLen + 2], resultLen =
                    text:sub(lastSplit, i - 1), 
                    {
                        tonumber(text:sub(i + 2, i + 3), 16), -- r
                        tonumber(text:sub(i + 4, i + 5), 16), -- g
                        tonumber(text:sub(i + 6, i + 7), 16), -- b
                        1, -- a
                    },
                    resultLen + 2
                i = i + 8
            elseif nextByte - 0x30 < 10 then -- '0'
                -- add last characters
                result[resultLen + 1], result[resultLen + 2], resultLen = 
                    text:sub(lastSplit, i - 1),
                    self._ColorEscapes[nextByte - 0x30],
                    resultLen + 2
                i = i + 2
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
	return (text:gsub("%^%d",""):gsub("%^[xX]%x%x%x%x%x%x",""))
end

return {
    New = function()
        return setmetatable({
            _GetScreenSize   = GetScreenSize,
            _SetClearColor   = SetClearColor,
            _SetDrawLayer    = SetDrawLayer,
            _SetViewport     = SetViewport,
            _SetDrawColor    = SetDrawColor,
            _DrawImage       = DrawImage,
            _DrawImageQuad   = DrawImageQuad,
            _DrawString      = DrawString,
            _DrawStringWidth = DrawStringWidth,
        
            _DrawStringCursorIndex = DrawStringCursorIndex,
        }, GraphicsMt)
    end
}