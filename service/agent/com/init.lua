local table_insert = table.insert

local s = require "service"
local gbag_com = require "com.bag"

local com_conf = {
	{name = "gbag_com", cls = gbag_com, uid = 1, group_name = "bag"},
}

-- 组件映射配置
local com_map_conf = {
}

-- 组映射配置
local group_map_conf = {}

for _, v in ipairs(com_conf) do
    com_map_conf[v.name] = v
    if v.group_name then
        local temp_conf = group_map_conf[v.group_name]
        if not temp_conf then
            temp_conf = {}
            group_map_conf[v.group_name] = temp_conf
        end
        table_insert(temp_conf, v.name)
    end
end

local com_init = {}

-- 获取组件配置
function com_init.get_com_conf(com_name)
    return com_map_conf[com_name]
end

-- 获取组件配置
function com_init.get_com_conf_by_uid(uid)
    for _, v in pairs(com_map_conf) do
        if v.uid and v.uid == uid then
            return v
        end
    end
end

--初始化com
function com_init.start()
    s.data = {}

    for _, v in pairs(com_map_conf) do
        v.cls.gen_data_impl()
    end
end

return com_init