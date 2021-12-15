package.cpath = "../skynet/luaclib/?.so;" .. "../luaclib/?.so"
package.path = "../skynet/lualib/?.lua;examples/?.lua"

local a = package.loadlib("pb.dll", "luaopen_pb")

local cjson = require "cjson"
local pb = require "protobuf"

if _VERSION ~= "Lua 5.4" then
	error "Use lua 5.4"
end

local socket = require "client.socket"

local fd = assert(socket.connect("127.0.0.1", 8001))


local function send_tail_msg()
	-- input = io.read()
	-- print("input:", input)
	-- local msg = input .. "\r\n"

	local msg = {"login_req", 101, 123}
	socket.send(fd, msg)
end

local function send_json_msg()
	local function json_pack(cmd, msg)
		msg._cmd = cmd
		local body = cjson.encode(msg) --协议体字节流
		local namelen = string.len(cmd) --协议名长度
		local bodylen = string.len(body) --协议体长度
		local len = namelen + bodylen + 2 --协议总长度
		local format = string.format("> i2 i2 c%d c%d", namelen, bodylen)
		local buff = string.pack(format, len, namelen, cmd, body)
		return buff
	end

	local msg = {
		_msg = "balllist",
		balls = {
			[1] = {id=102, x=10, y=20, size=1},
			[2] = {id=103, x=10, y=30, size=2},
		}
	}
	local buff = json_pack("balllist", msg)
	-- socket.send(fd, buff)

	socket.send(fd, json_pack("login", {"login",1001,123}))
end

-- while true do
-- 	send_tail_msg()
-- end

send_json_msg()
