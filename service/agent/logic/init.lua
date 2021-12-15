
local register = require "register"

local com_conf = {
    "bag",
}

register.register_model_by_conf("logic", "./service/agent/logic/", com_conf)