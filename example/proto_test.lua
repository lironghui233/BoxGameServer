local skynet = require "skynet"
local pb = require "protobuf"

--protobuf编码解码
function test()
	pb.register_file("../proto/login.pb")
	--编码
	local msg = {
		id = 101,
		pw = "123456",
	}
	local buff = pb.encode("login.Login", msg)
	print("len:" .. string.len(buff))
	--解码
	local umsg = pb.decode("login.Login", buff)
	if umsg then
		print("id:"..umsg.id)
		print("pw:"..umsg.pw)
	else
		print("error")
	end
end

skynet.start(function ()
	test()
end)