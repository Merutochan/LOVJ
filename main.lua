print()

lick = require "lib/lick"
res = require "resources"
screen = require "lib/screen"
timer = require "lib/timer"
resources = require "lib/resources"
controls = require "lib/controls"
comm = require "lib/comm"

patch = require "demos/demo_1"
lick.updateCurrentlyLoadedPatch("demos/demo_1.lua")

-- lick reset enable
lick.reset = true

--  hot reload
function love.load()
	-- Init screen
	screen.init()
	-- Init timer
	timer.init()
	-- Init resources
	resources.init()
	-- Init Patch
	patch.init()
	-- Init socket
	comm.init()
end


-- Main draw cycle, called once every frame (depends on vsync)
function love.draw()
	-- set scaling
	love.graphics.scale(screen.Scale.X, screen.Scale.Y)
	-- draw patch
	patch.draw()
	-- calculate fps
	local fps = 1/(love.timer.getAverageDelta())
end


-- Main update cycle, executed as fast as possible
function love.update()
	timer.update()  -- update timer
	-- Console management
	if timer.consoleTimer() then
		print("FPS:", fps)
		print("Packets received:", sockets[1].info)
	end

	controls.HandleGeneralControls()  -- evaluate general controls

	local response_data = comm.SendRequests()  -- request data from UDP connections
	dispatcher.update(response_data)  -- TODO implement this
end