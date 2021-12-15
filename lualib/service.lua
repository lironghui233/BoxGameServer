local skynet = require "skynet"
local cluster = require "skynet.cluster"

require "extension/table"

--该模块（service模块）是对skynet服务的一种封装。
local M = {
	name = "", --服务的类型
	id = 0,	--服务编号
	--回调函数
	exit = nil, --服务退出时调用
	init = nil, --服务初始化调用
	--分发方法
	resp = {},	--存放消息处理方法
}

function trackback(err)
	skynet.error(tostring(err))
	skynet.error(debug.trackback())
end

local dispatch = function(session, address, cmd , ...)
	local fun = M.resp[cmd]
	if not fun then
		skynet.ret()
		return
	end

	local ret = table.pack(xpcall(fun, trackback, address, ...))
	local isok = ret[1]

	if not isok then
		skynet.ret()
		return
	end

	skynet.retpack(table.unpack(ret, 2)) --用table.unpack解出ret[2]、ret[3]……
end

function init()
	skynet.dispatch("lua", dispatch)
	if M.init then
		M.init()
	end
end

--对skynet.start的简易封装。
function M.start(name, id, ...)
	M.name = name
	M.id = tonumber(id)
	skynet.start(init)
end

--对skynet.call的简易封装。
--@@node 表示接收方所在的节点
--@@srv 表示接收方的服务名
function M.call(node, srv, ...)
	local mynode = skynet.getenv("node")
	if node == mynode then
		return skynet.call(srv, "lua", ...)
	else
		return cluster.call(node, srv, ...)
	end
end

--对skynet.send的简易封装。
--@@node 表示接收方所在的节点
--@@srv 表示接收方的服务名
function M.send(node, srv, ...)
	local mynode = skynet.getenv("node")
	if node == mynode then
		return skynet.send(srv, "lua", ...)
	else
		return cluster.send(node, srv, ...)
	end
end

return M