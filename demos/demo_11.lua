local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local videoutils = lovjRequire("lib/utils/video")
local screen_settings = lovjRequire("lib/cfg/cfg_screen")
local shaders = lovjRequire("lib/shaders")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("lib/cfg/cfg_timers")


-- import pico8 palette
local PALETTE

patch = Patch:new()

--- @public setCanvases (re)set canvases for this patch
function patch:setCanvases()
	Patch.setCanvases(patch)  -- call parent function
	-- patch-specific execution (video canvas)
	if screen_settings.UPSCALE_MODE == screen_settings.LOW_RES then
		patch.canvases.video = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	else
		patch.canvases.video = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	end
end

--- @private init_params initialize patch parameters
local function init_params()
	g = resources.graphics
	p = resources.parameters

    g:setName(1, "video")           g:set("video", "data/demo_11/evil_eyes.ogg")
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	p = resources.parameters

    -- insert here your patch controls
end


--- @public init init routine
function patch.init()
	PALETTE = palettes.PICO8

	patch.setCanvases()

	init_params()

    patch.video = {}
    patch.video.handle = love.graphics.newVideo(g:get("video"))
    patch.video.pos = 0
	patch.video.scaleX = screen.InternalRes.W / patch.video.handle:getWidth()
	patch.video.scaleY = screen.InternalRes.H / patch.video.handle:getHeight()
	patch.video.loopStart = 0
	patch.video.loopEnd = 2
	patch.video.playbackSpeed = 1
    patch.video.handle:play()

	patch:assignDefaultDraw()
end

--- @private draw_bg draw background graphics
local function draw_stuff()
	g = resources.graphics
	p = resources.parameters

end

--- @public patch.draw draw routine
function patch.draw()
	patch:drawSetup()

	local t = cfg_timers.globalTimer.T

	love.graphics.clear()

	-- set canvas
	love.graphics.setCanvas(patch.canvases.video)

	-- render graphics
	love.graphics.draw(patch.video.handle, 0, 0, 0, patch.video.scaleX, patch.video.scaleY)
	-- set main canvas
	love.graphics.setCanvas(patch.canvases.main)
	-- draw video w/ chroma keying
	if screen.isUpscalingHiRes() then
		love.graphics.draw(patch.canvases.video, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
	else
		love.graphics.draw(patch.canvases.video)
	end
	patch:drawExec()
end


function patch.update()
    patch:mainUpdate()
    -- handle loop
    videoutils.handleLoop(patch.video)
end


function patch.commands(s)

end

return patch