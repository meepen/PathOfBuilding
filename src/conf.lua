function love.conf(t)
    t.identity = "PathOfBuilding"
    t.appendidentity = true
    t.version = "11.3"
    t.console = true
    t.accelerometerjoystick = false
    t.audio.mixwithsystem = true

    t.window.title = "Path of Building"
    -- t.window.icon = 
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.window.vsync = 1
    t.window.stencil = 8
    t.window.highdpi = false
    t.window.usedpiscale = true         -- Enable automatic DPI scaling when highdpi is set to true as well (boolean)

    t.modules.audio = false
    t.modules.data = true               -- Enable the data module (boolean)
    t.modules.event = true              -- Enable the event module (boolean)
    t.modules.font = true               -- Enable the font module (boolean)
    t.modules.graphics = true           -- Enable the graphics module (boolean)
    t.modules.image = true              -- Enable the image module (boolean)
    t.modules.joystick = true           -- Enable the joystick module (boolean)
    t.modules.keyboard = true           -- Enable the keyboard module (boolean)
    t.modules.math = true               -- Enable the math module (boolean)
    t.modules.mouse = true              -- Enable the mouse module (boolean)
    t.modules.physics = false
    t.modules.sound = false
    t.modules.system = true             -- Enable the system module (boolean)
    t.modules.thread = true             -- Enable the thread module (boolean)
    t.modules.timer = true              -- Enable the timer module (boolean), Disabling it will result 0 delta time in love.update
    t.modules.touch = true              -- Enable the touch module (boolean)
    t.modules.video = false
    t.modules.window = true             -- Enable the window module (boolean)
end