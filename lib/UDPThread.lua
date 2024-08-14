-- UDPThread.lua
--
-- Implementation of thread handling UDP sockets

-- Parse arguments
local initParams = { ... }
local id = initParams[1]
local ip = initParams[2]["address"]
local ip_port = initParams[2]["port"]

-- include libs
local socket = require "socket"
local cfg = require "cfg/cfg_connections"

-- local variables
local rspMsgs = {} -- Response list
local listening = false -- not listening yet
local packetCount = 0

-- Function called at initialization
local function init()
	-- Create channel "info"
	reqChannel = love.thread.getChannel("reqChannel_" .. id)
	rspChannel = love.thread.getChannel("rspChannel_" .. id)

	-- Setup UDP listener
	udp = socket.udp()
	udp:settimeout(0.0001)
	assert(udp:setsockname(ip, ip_port))

	listening = true  -- set listening flag
end


-- Function to receive incoming packets
local function receivePacket()
	-- Receive packets
	local packet
	local msg_or_ip
	local port
	packet, msg_or_ip, port = udp:receivefrom()
	return packet
end


-- Function to parse packets and extract their contents
local function parsePacket(p)
	if p then
		packetCount = packetCount + 1  -- increase packet count
		table.insert(rspMsgs, p)  -- insert data in response queue
	end
end


-- Function to send back info obtained from extracted packets
local function parseRequest()
	local req = reqChannel:pop()  -- get requests

	if req == cfg.reqMsg then	-- if REQ present, send the rspMsgs queue back
		local msg = {}
		msg.info = packetCount
		msg.content = rspMsgs

		-- response contains packetCount as info,
		-- and the actual messages as content
		rspChannel:push(msg)

		local ack
		while ack ~= cfg.ackMsg do  -- wait for acknowledgement
		  ack = reqChannel:pop()
		end

		for k in pairs(rspMsgs) do
			rspMsgs[k] = nil  -- empty the queue
		end
    
	elseif req == cfg.quitMsg then	-- if QUIT request present
		udp:close()
		rspChannel:push(cfg.ackQuit)
		listening = false
	end

	req = nil  -- remove request
end


--
init()

while listening do
	packet = receivePacket()  -- listen to udp
	parsePacket(packet)  -- put packets in the queue
	parseRequest()  -- elaborate requests from main program
end