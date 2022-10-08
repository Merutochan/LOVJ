-- lick.lua
--
-- simple LIVECODING environment for Löve
-- overwrites love.run, pressing all errors to the terminal/console

-- added modification to close UDP thread if present

-- TODO:[livecoding] Restore livecoding feature, by checking for lists of files.
-- TODO:[reformat] Reformat and cleanup code

local log = require("lib/utils/logging")

local lick = {}

-- reset types
lick.HARD_RESET = "Hard reset"
lick.PATCH_RESET = "Patch reset"

lick.files = {"main.lua", "main.lua"}
-- list containing structures as:
-- { name: "filename",
--   modtime: "last modification time",
--   resetType: "type of reset to apply"
-- }
-- by default contains the main.lua
lick.resetList = {{name="main",
                   modtime=love.filesystem.getInfo("main.lua").modtime,
                   resetType=lick.HARD_RESET}}


lick.debug = false
lick.reset = false
lick.clearFlag = false
lick.sleepTime = love.graphics.newCanvas and 0.0001 or 1

connections = {}
connections.UDP_thread = nil


--- @private handle Handle error in lick
local function handle(err)
  return "ERROR: " .. err
end


--- @private checkReset Check list of components for modifications to trigger reset if necessary
local function checkReset()
    for k, v in pairs(lick.resetList) do
        -- Check if file has changed by looking at filesystem modification time
        local modtime = love.filesystem.getInfo(v.name .. ".lua").modtime
        if modtime ~= v.time then
            v.time = modtime
            return v.resetType
        end
    end
    return nil
end


local function update(dt)
    local typedReset = checkReset()
    local info_main = love.filesystem.getInfo("main.lua")
    if typedReset == lick.HARD_RESET then
		-- Close UDP socket and thread
		closeUDPThread()
        success, chunk = pcall(love.filesystem.load, "main.lua")  -- TODO:[refactor] shouldnt be a static name

        if not success then
            logError(tostring(chunk))
            lick.debugoutput = chunk .. "\n"
        end
        ok,err = xpcall(chunk, handle)

        if not ok then 
            logError(tostring(err))

            if lick.debugoutput then
                lick.debugoutput = (lick.debugoutput .."ERROR: ".. err .. "\n" )
            else 
                lick.debugoutput =  err .. "\n" 
            end 
        else
            logInfo("Reloaded")
            lick.debugoutput = nil
        end
        if lick.reset then
            loadok, err = xpcall(love.load, handle)
            if not loadok and not loadok_old then
                logError(tostring(err))
                if lick.debugoutput then
                    lick.debugoutput = (lick.debugoutput .."ERROR: ".. err .. "\n" ) 
                else
                    lick.debugoutput =  err .. "\n"
                end
                loadok_old = not loadok
            end
        end
    end

    updateok, err = pcall(love.update,dt)
    if not updateok and not updateok_old then 
        print("ERROR: "..tostring(err))
        if lick.debugoutput then
            lick.debugoutput = (lick.debugoutput .."ERROR: ".. err .. "\n" ) 
        else
            lick.debugoutput =  err .. "\n"
        end
  end
  
  updateok_old = not updateok
end

local function draw()
    drawok, err = xpcall(love.draw, handle)
    if not drawok and not drawok_old then 
        print(tostring(err))
        if lick.debugoutput then
            lick.debugoutput = (lick.debugoutput .. err .. "\n" ) 
        else
            lick.debugoutput =  err .. "\n"
        end 
    end

    if lick.debug and lick.debugoutput then 
        love.graphics.setColor(1,1,1,0.8)
        love.graphics.printf(lick.debugoutput, (love.graphics.getWidth()/2)+50, 0, 400, "right")
    end
    drawok_old = not drawok
end


function love.run()
    math.randomseed(os.time())
    math.random() math.random()

    local dt = 0

    -- Main loop time.
    while true do
        -- Process events.
        if love.event then
            love.event.pump()
            for e,a,b,c,d in love.event.poll() do
            if e == "quit" then
                if not love.quit or not love.quit() then
                    if love.audio then
                        love.audio.stop()
                    end
                return
                end
            end

            love.handlers[e](a,b,c,d)
        end
    end

    -- Update dt, as we'll be passing it to update
    if love.timer then
        love.timer.step()
        dt = love.timer.getDelta()
    end

    -- Call update and draw
    if update then update(dt) end -- will pass 0 if love.timer is disabled
    if love.graphics then
        love.graphics.origin()
        love.graphics.clear(love.graphics.getBackgroundColor())
        if draw then draw() end
    end

    if love.timer then love.timer.sleep(lick.sleepTime) end
    if love.graphics then love.graphics.present() end
  end
end

function closeUDPThread()
	-- If there is a "UDP_thread"
	if connections.UDP_thread then
		print("[LICK] - Closing UDP thread...")
		assert(love.thread.getChannel("UDP_REQUEST"):push("quit"))
		resp = love.thread.getChannel("UDP_SYSTEM_INFO"):demand()
		if resp == "clear" then
			connections.UDP_thread:release()
			print("[LICK] - UDP Thread released.")
		end
	end
end


return lick
