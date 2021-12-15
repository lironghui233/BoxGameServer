local skynet = require "skynet"
local s = require "service"

--开启服务器时从数据库读取
--关闭服务器时保存
local last_check_time = 1582935650

--每天第一次登录执行
function first_login_day()

end

--开启活动
function open_activity()

end

--os.time() 得到的是当前时间距离1970.1.1.08:00的秒数
function get_day(timestamp)
	local day = (timestamp + 3600*8)/(3600*24)
	return math.ceil(day)
end


--1970年01月01日是星期四。此处以周四20:40点为界
function get_week_by_thu2040(timestamp)
	local week = (timestamp + 3600*8 - 3600*20 - 40*60)/(3600*24*7)
	return math.ceil(week)
end


--每隔一小段时间执行
function is_active_timer()
	local last = get_week_by_thu2040(last_check_time)
	local now = get_week_by_thu2040(os.time())
	last_check_time = os.time()

	if now > last then
		open_activity() --开启活动
	end
end

function is_first_login_day()
	--获取和更新登陆时间
	local last_timestamp = s.data.baseinfo.last_login_time or os.time()
	local last_day = get_day(last_timestamp)
	local day = get_day(os.time())
	s.data.baseinfo.last_login_time = os.time()
	--判断每天第一次登录
	if day > last_day then
		first_login_day() --每天第一次登录执行
	end
end

function update()
	skynet.fork(function () --开启协程
		--包吃帧率执行
		local waittime = 1000
		while true do
			is_active_timer()
			skynet.sleep(waittime) 
		end	
	end)
end