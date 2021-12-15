
--[[
协议分析：长度信息法
skynet提供的C语言编写的netpack模块，它能高效解析2字节长度信息的协议
]]


local skynet = require "skynet"
local socketdriver = require "skynet.socketdriver"
local netpack = require "skynet.netpack"

--不能同时包含socketdriver和socket，因为socket里已经register_protocol了socket类型
-- local socket = require "skynet.socket"

local queue -- message queue

--解码底层传来的SOCKET类型消息
function socket_unpack(msg, size)
	return netpack.filter(queue, msg, size)
end

--处理底层传来的SOCKET类型消息
function socket_dispatch(_, _, q, type, ...)
	skynet.error("socket_dispatch type:" .. (type or "nil"))
	queue = q
	if type == "open" then
		process_connect(...)	
	elseif type == "data" then
		process_msg(...)	
	elseif type == "more" then
		process_more(...)
	elseif type == "close" then
		process_close(...)
	elseif type == "error" then
		process_error(...)
	elseif type == "warning" then
		process_warning(...)
	end	
end

--有新连接
function process_connect(fd, addr)
	skynet.error("new conn fd:" .. fd .. " addr:" .. addr)
	socketdriver.start(fd)	
end

--关闭连接
function process_close(fd)
	skynet.error("close fd:" .. fd)
end

--发送错误
function process_error(fd, error)
	skynet.error("error fd:" .. fd .. " error:" .. error)
end

--发送警告
function process_warning(fd, size)
	skynet.error("warning fd:" .. fd .. " size:" .. size)
end

--刚好收到一条完整消息
function process_msg(fd, msg, size)
	local str = netpack.tostring(msg, size)
	skynet.error("recv from fd:" .. fd .. " str:" .. str)
end

--收到多于1条消息时
function process_more()
	for fd, msg, size in netpack.pop, queue do
		skynet.fork(process_msg, fd, msg, size) --开启协程，协程保证了process_msg执行的时序性
	end
end


skynet.start(function ()
	--注册SOCKET类型信息
	skynet.register_protocol({
		name = "socket",
		id = skynet.PTYPE_SOCKET,
		unpack = socket_unpack,
		dispatch = socket_dispatch,
	})
	--注册Lua类型消息
	--开启监听
	local listenfd = socketdriver.listen("0.0.0.0", 9999)
	socketdriver.start(listenfd)
end)