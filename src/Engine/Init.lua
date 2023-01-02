
function LoadModule(fileName, ...)
	if not fileName:match("%.lua") then
		fileName = fileName .. ".lua"
	end
	local func, err = loadfile(fileName)
	if func then
		return func(...)
	else
		error("LoadModule() error loading '"..fileName.."': "..err)
	end
end
function PLoadModule(fileName, ...)
	if not fileName:match("%.lua") then
		fileName = fileName .. ".lua"
	end
	local func, err = loadfile(fileName)
	if func then
		return PCall(func, ...)
	else
		error("PLoadModule() error loading '"..fileName.."': "..err)
	end
end
function PCall(func, ...)
	local ret = { pcall(func, ...) }
	if ret[1] then
		table.remove(ret, 1)
		return nil, unpack(ret)
	else
		return ret[2]
	end	
end
function ConPrintf(fmt, ...)
	-- Optional
	print(string.format(fmt, ...))
end
function ConPrintTable(tbl, noRecurse) end
function ConExecute(cmd) end
function ConClear() end
function SetProfiling(isEnabled) end

local engineVar = (os.getenv("POB_ENGINE") or "SimpleGraphic")
if love then
	local EngineClass = require("Engine.Love2D.Engine")
	local GraphicsClass = require("Engine.Love2D.Graphics")
	local ImageClass = require("Engine.Love2D.Image")
	local CallbacksClass = require("Engine.Callbacks")

	engine = EngineClass.New()
	graphics = GraphicsClass.New()
	Image = ImageClass
	callbacks = CallbacksClass.New()
elseif engineVar == "SimpleGraphic" then
	local EngineClass = require("Engine.SimpleGraphic.Engine")
	local GraphicsClass = require("Engine.SimpleGraphic.Graphics")
	local ImageClass = require("Engine.SimpleGraphic.Image")
	local CallbacksClass = require("Engine.SimpleGraphic.Callbacks")

	engine = EngineClass.New()
	graphics = GraphicsClass.New()
	Image = ImageClass
	callbacks = CallbacksClass.New()
else
	error("Unknown engine: " .. engineVar)
end


--[[
dofile("Launch.lua")

-- Prevents loading of ModCache
-- Allows running mod parsing related tests without pushing ModCache
-- The CI env var will be true when run from github workflows but should be false for other tools using the headless wrapper 
mainObject.continuousIntegrationMode = os.getenv("CI") 

callbacks:Run("OnInit")
callbacks:Run("OnFrame") -- Need at least one frame for everything to initialise

if mainObject.promptMsg then
	-- Something went wrong during startup
	print(mainObject.promptMsg)
	io.read("*l")
	return
end

-- The build module; once a build is loaded, you can find all the good stuff in here
build = mainObject.main.modes["BUILD"]

-- Here's some helpful helper functions to help you get started
function newBuild()
	mainObject.main:SetMode("BUILD", false, "Help, I'm stuck in Path of Building!")
	callbacks:Run("OnFrame")
end
function loadBuildFromXML(xmlText, name)
	mainObject.main:SetMode("BUILD", false, name or "", xmlText)
	callbacks:Run("OnFrame")
end
function loadBuildFromJSON(getItemsJSON, getPassiveSkillsJSON)
	mainObject.main:SetMode("BUILD", false, "")
	callbacks:Run("OnFrame")
	local charData = build.importTab:ImportItemsAndSkills(getItemsJSON)
	build.importTab:ImportPassiveTreeAndJewels(getPassiveSkillsJSON, charData)
	-- You now have a build without a correct main skill selected, or any configuration options set
	-- Good luck!
end
]]