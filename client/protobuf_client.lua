local skynet = require "skynet"
local socket = require "client.socket"
local pb = require "protobuf"

pb.register_file("../service/proto/all.bytes")

local proto_id_map = nil
local get_proto_name = function (msgid)
	if not proto_id_map then
		local file = assert(io.open("../service/proto/message_define.bytes", "rb")) 
		local source = file:read("*a")
		proto_id_map = load(source)()
		file:close()
		source = nil
	end
	return proto_id_map[msgid]
end

local get_proto_id = function (msg_name)
	if not proto_id_map then
		local file = assert(io.open("../service/proto/message_define.bytes", "rb")) 
		local source = file:read("*a")
		proto_id_map = load(source)()
		file:close()
		source = nil
	end
	for k,v in pairs(proto_id_map) do
		if v == tostring(msg_name) then
			return tonumber(k) 
		end
	end 
end

local encode_protobuf_msg = function(msgid, data)
	local msg_name = get_proto_name(msgid)						-- 根据协议id获取协议名
    local stringbuffer =  pb.encode(msg_name, data)         	-- 根据协议名和协议数据  protobuf序列化 返回lua_string
    local body = string.pack(">I2s2", msgid, stringbuffer)      -- 打包包体 协议id + 协议数据
    local head = string.pack(">I2", #body)                    	-- 打包包体长度
    return head .. body                                       	-- 包体长度 + 协议id + 协议数据
end

skynet.start(function ()
	--编码
	local msg = {
		id = 101,
		pw = "123",
	}
	local buff = encode_protobuf_msg(get_proto_id("login_req"), msg)
	print("len:" .. string.len(buff))

	local fd = assert(socket.connect("127.0.0.1", 8001))
	socket.send(fd, buff)
end)