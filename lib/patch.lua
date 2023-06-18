-- patch.lua
--
-- Patch class including common elements shared among all patches
--

local screen_settings = lovjRequire("lib/cfg/cfg_screen")
local cfg_patches = lovjRequire("lib/cfg/cfg_patches")
local cfg_shaders = lovjRequire("lib/cfg/cfg_shaders")
local cmd = lovjRequire("lib/cmdmenu")

local Patch = {}

Patch.__index = Patch

-- Constructor
function Patch:new(p)
    local p = p or {}
    setmetatable(p, self)
	p.hang = false
    return p
end


--- @public setCanvases (re)set canvases for patch
function Patch:setCanvases()
	self.canvases = {}
	self.canvases.ShaderCanvases = {}

	local sizeX, sizeY
	-- Calculate appropriate size
	if screen_settings.UPSCALE_MODE == screen_settings.LOW_RES then
		sizeX, sizeY = screen.InternalRes.W, screen.InternalRes.H
	else
		sizeX, sizeY = screen.ExternalRes.W, screen.ExternalRes.H
	end
	-- Generate canvases with calculated size
	self.canvases.main = love.graphics.newCanvas(sizeX, sizeY)
	self.canvases.cmd = love.graphics.newCanvas(sizeX, sizeY)
	for i = 1, #cfg_shaders.PostProcessShaders do
		table.insert(self.canvases.ShaderCanvases, love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H))
	end

end


--- @public assignDefaultDraw assign patch.draw method to defaultDraw
function Patch:assignDefaultDraw()
    self.defaultDraw = self.draw
end


--- @public drawSetup Draw setup shared across all patches
function Patch:drawSetup()
	-- reset color
	love.graphics.setColor(1,1,1,1)
	-- clear background picture
	if not self.hang then
		self.canvases.main:renderTo(love.graphics.clear)
	end

	-- select shaders
	if cfg_shaders.enabled then
		for i = 1, #cfg_shaders.PostProcessShaders do
			cfg_shaders.PostProcessShaders[i] = cfg_shaders.selectShader(i)
		end
	end

	-- set canvas
	love.graphics.setCanvas(self.canvases.main)
	end


--- @public drawExec Draw procedure shared across all patches
function Patch:drawExec()
	-- cycle over shader canvases and apply shaders
	if cfg_shaders.enabled then
		for i = 1, #cfg_shaders.PostProcessShaders do
			local srcCanvas, dstCanvas
			if i == 1 then srcCanvas, dstCanvas = self.canvases.main, self.canvases.ShaderCanvases[1]
			else srcCanvas, dstCanvas = self.canvases.ShaderCanvases[i-1], self.canvases.ShaderCanvases[i] end
			-- Set canvas, apply shader, draw and then remove shader
			love.graphics.setCanvas(dstCanvas)
			cfg_shaders.applyShader(cfg_shaders.PostProcessShaders[i])
			love.graphics.draw(srcCanvas, 0, 0, 0, 1, 1)
			love.graphics.setCanvas(srcCanvas)
			love.graphics.clear(0,0,0,1)
		end
		-- Draw final layer on output (default) canvas
		love.graphics.setCanvas()
		cfg_shaders.applyShader()

		love.graphics.draw(self.canvases.ShaderCanvases[#cfg_shaders.PostProcessShaders], 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
	else
		-- Draw normally
		love.graphics.setCanvas()
		love.graphics.draw(self.canvases.main, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
	end
	-- draw cmd menu canvas on top
	love.graphics.draw(self.canvases.cmd, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
end

--- @public mainUpdate Update procedures shared across all patches
function Patch:mainUpdate()
	-- apply keyboard patch controls
	if not cmd.isOpen then self.patchControls() end
end

return Patch