
local vpr_lib = require("viewport_renderer")
local vpr_inst = vpr_lib.new()
local plr_lib = require("player")
local plr_inst = plr_lib.new()
local mesh_lib = require("mesh")

local table = require("table")

local screen_buffer = {}

local width = 1152
local height = 648

local process_cycles  = 0

function love.load()

    love.window.setTitle("3D Rendering Demo")
    love.graphics.setBackgroundColor(0.4, 0.7, 1.0)
    
    love.window.setMode(width, height)
    plr_lib.Window_width_div_2 = width / 2
    plr_lib.Window_height_div_2 = height / 2


    Create_cube_mesh({1, 1, 1}, {0, 0, 0})
    Create_cube_mesh({1, 2, 1}, {2, 0, 0})

end


local delta_time = 0

function Render_frame() 
    vpr_inst.depth_field = vpr_lib.initializeDepthTable(vpr_inst, width * height, 1000)
    
    vpr_inst.width = width
    vpr_inst.height = height
    
    screen_buffer = vpr_lib.render_3d(vpr_inst)

end

function Game_process()
    delta_time = love.timer.getDelta()
    plr_lib.process(plr_inst, delta_time)
    
    vpr_inst.cam_position = plr_inst.position
    vpr_inst.cam_rotation = plr_inst.camera_rotation

    Render_frame()

    process_cycles = process_cycles + 1
end

function Create_cube_mesh(size, offset)
    local width = size[1] 
    local depth = size[2]
    local height = size[3]
    local new_mesh = mesh_lib.new()

    local verts = {
        {0 + offset[1], 0 + offset[2], 0 + offset[3]},
        {width + offset[1], 0 + offset[2], 0 + offset[3]},
        {0 + offset[1], depth + offset[2], 0 + offset[3]},
        {width + offset[1], depth + offset[2], 0 + offset[3]},
        {0 + offset[1], 0 + offset[2], height + offset[3]},
        {width + offset[1], 0 + offset[2], height + offset[3]},
        {0 + offset[1], depth + offset[2], height + offset[3]},
        {width + offset[1], depth + offset[2], height + offset[3]}
    }

    local faces = {
        {7, 8, 4, 3 },
        {2, 6, 5, 1},
        {3, 1, 5, 7},
        {8, 6, 2, 4},
        {7, 5, 6, 8},
        {4, 2, 1, 3}
    }
    for _, face in pairs(faces) do
        
        new_mesh = mesh_lib.create_tri(new_mesh, {verts[face[1]], verts[face[2]], verts[face[3]], verts[face[4]]} )
    
    end
    
    table.insert(vpr_inst.geometry, new_mesh)
end

function love.draw()
    
    Game_process()

    love.mouse.setVisible(not love.mouse.isGrabbed())
    local table_index = 1
    for i = 1, #screen_buffer - 3, 3 do
        local line_a = screen_buffer[i + 0]
        local line_b = screen_buffer[i + 1]
        local line_c = screen_buffer[i + 2]
        love.graphics.setColor(1, 1, 1)
        love.graphics.polygon("fill", {line_a[1], line_a[2], line_b[1], line_b[2], line_c[1], line_c[2]})
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.polygon("line", {line_a[1], line_a[2], line_b[1], line_b[2], line_c[1], line_c[2]})

    end
    love.graphics.setColor(1, 1, 1)
    love.window.setVSync(false)
    love.graphics.print(math.floor(1 / delta_time) .. "FPS")
    -- print(math.floor(1 / delta_time) .. "FPS")
end

