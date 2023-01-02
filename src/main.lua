package.path = package.path .. ";../runtime/lua/?.lua;../runtime/lua/?/init.lua"

function love.update(dt)
    local targetFps = 60
    if not love.window.hasFocus() then
        targetFps = 15
    end

    if dt < 1 / targetFps then
        love.timer.sleep(1 / targetFps - dt)
    end
end

dofile "Launch.lua"