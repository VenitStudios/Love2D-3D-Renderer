local player = {}
local last_delta = 0
local isKeyPressed = {}

Window_width_div_2 = love.graphics.getWidth() / 2
Window_height_div_2 = love.graphics.getHeight() / 2

function player.new()
    local self = {}
    self.position = {0, 10, 1}
    self.velocity  = {0, 0 ,0}
    self.camera_rotation = {0, 0, 0}
    self.speed = 0.5
    setmetatable(self, { __index = player })
    return self
end

function player.process(player_instance, delta)
    player = player_instance
    last_delta = delta

    local rotation = player["camera_rotation"]

    local yaw = rotation[2] -- Rotation around the Y-axis (yaw)

    player_instance["velocity"][1], player_instance["velocity"][2] = 0, 0 -- Reset velocity

    local speed = 10 * delta

    if isKeyPressed["w"] then
        player_instance["velocity"][1] = player_instance["velocity"][1] + -math.sin(yaw) * speed
        player_instance["velocity"][2] = player_instance["velocity"][2] + -math.cos(yaw) * speed
    end

    if isKeyPressed["s"] then
        player_instance["velocity"][1] = player_instance["velocity"][1] + math.sin(yaw) * speed
        player_instance["velocity"][2] = player_instance["velocity"][2] + math.cos(yaw) * speed
    end

    if isKeyPressed["a"] then
        player_instance["velocity"][1] = player_instance["velocity"][1] + math.cos(yaw) * speed
        player_instance["velocity"][2] = player_instance["velocity"][2] + -math.sin(yaw) * speed
    end

    if isKeyPressed["d"] then
        player_instance["velocity"][1] = player_instance["velocity"][1] + -math.cos(yaw) * speed
        player_instance["velocity"][2] = player_instance["velocity"][2] + math.sin(yaw) * speed
    end

    player_instance["position"][1] = player_instance["position"][1] + player_instance["velocity"][1]
    player_instance["position"][2] = player_instance["position"][2] + player_instance["velocity"][2]
    player_instance["position"][3] = player_instance["position"][3] + player_instance["velocity"][3]

end

local lastMouseCenterTime = 0
local mouseCenterInterval = 1 / 60

function love.mousemoved(x, y, dx, dy)
    if player["camera_rotation"] ~= nil then
        local centerX, centerY = love.graphics.getDimensions()
        centerX = centerX / 2
        centerY = centerY / 2

        local relX = x - centerX
        local relY = y - centerY

        player["camera_rotation"][2] = player["camera_rotation"][2] + relX * last_delta * 0.05
        player["camera_rotation"][1] = player["camera_rotation"][1] + relY * last_delta * 0.05

        local currentTime = love.timer.getTime()
        if currentTime - lastMouseCenterTime >= mouseCenterInterval then
            love.mouse.setPosition(centerX, centerY)
            lastMouseCenterTime = currentTime
        end
    end
end

function love.keypressed(key)  
    isKeyPressed[key] = true
    
    if key == "escape" then 
        love.mouse.setGrabbed(not love.mouse.isGrabbed())
    end

end  

function love.keyreleased(key)  
    isKeyPressed[key] = false
end  

return player

