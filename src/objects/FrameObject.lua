local FrameObject = {}
FrameObject.__index = FrameObject

local constants = require("src/Constants")
local Utils = require("src/Utils")

local CollectorObject = require("src/objects/CollectorObject")
local ObjectType = require("src/objects/ObjectType")
local OrderType = require("src/management/OrderType")

local SPEED = 0.0002
local BASE_WEIGHT_TONS = 0.2

function FrameObject:init(name, x, y, orders)
    local this = {
        object_type = ObjectType.FRAME + ObjectType.DISPATCHABLE + ObjectType.CARGOABLE,
        speed = SPEED,
        ticks_advanced = SPEED,
        progress = 0,

        origin_x = x,
        origin_y = y,

        dest_x = dest_x,
        dest_y = dest_y,

        world_x = x,
        world_y = y,

        name = name,
        cargo_max = 2, -- Tons
        cargo = {},

        orders = {},
        current_order = nil,

        deployed = false,
    }
    setmetatable(this, self)

    return this
end

function FrameObject:get_object_type()
    return self.object_type
end

function FrameObject:get_x()
    return self.world_x
end

function FrameObject:set_x(val)
    --print("Setting X to " .. val)
    self.world_x = val
end

function FrameObject:get_y()
    return self.world_y
end

function FrameObject:set_y(val)
    --print("Setting Y to " .. val)
    self.world_y = val
end

function FrameObject:get_icon()
    return 178
end

function FrameObject:get_name()
    return self.name
end

function FrameObject:get_deployed()
    return self.deployed
end

function FrameObject:set_deployed(val)
    self.deployed = val
end

function FrameObject:add_order(game_state, new_order)
    table.insert(self.orders, new_order)
    local msg = self.name .. " is following new order."
    game_state.player_info.radio:add_message(msg)
end

function FrameObject:get_tonnage()
    local total_used = 0
    for i in pairs(self.cargo) do
        local cargo_item = self.cargo[i]
        total_used = total_used + cargo_item:get_tonnage()
    end

    return total_used + BASE_WEIGHT_TONS
end

function FrameObject:_start_movement_order(game_state, movement_order)
    self.origin_x = movement_order["data"]["start_x"]
    self.origin_y = movement_order["data"]["start_y"]
    self.world_x = movement_order["data"]["start_x"]
    self.world_y = movement_order["data"]["start_y"]
    self.dest_x = movement_order["data"]["dest_x"]
    self.dest_y = movement_order["data"]["dest_y"]

    local msg = self.name .. " begins to move."
    game_state.player_info.radio:add_message(msg)
end

function FrameObject:_handle_movement_order(game_state)
    local x_not_equal = self.world_x ~= self.dest_x
    local y_not_equal = self.world_y ~= self.dest_y
    if x_not_equal or y_not_equal then
        local distance = Utils.dist(self.origin_x, self.origin_y, self.dest_x, self.dest_y)
        self.progress = self.progress + (self.speed * 1/distance)

        if self.progress >= 1 then
            self.progress = 1
        end

        if x_not_equal then
            self:set_x(Utils.lerp(self.origin_x, self.dest_x, self.progress))
        end

        if y_not_equal then
            self:set_y(Utils.lerp(self.origin_y, self.dest_y, self.progress))
        end
    elseif self.progress == 1 then
        self.current_order = nil
        self.progress = 0
        self.origin_x = nil
        self.origin_y = nil
        self.dest_x = nil
        self.dest_y = nil

        local msg = self.name .. " has arrived at destination."
        game_state.player_info.radio:add_message(msg)
    end
end

function FrameObject:update(game_state, dt)
    if not self.current_order and #self.orders > 0 then
        --print("Number of current orders is " .. #self.orders)
        self.current_order = table.remove(self.orders)
        if self.current_order:get_type() == OrderType.MOVEMENT then
            self:_start_movement_order(game_state, self.current_order)
        end
    end

    if not self.deployed then
        return
    end

    if self.current_order and self.current_order:get_type() == OrderType.MOVEMENT then
        self:_handle_movement_order(game_state)
    end
end

return FrameObject
