local table = require("table")

local viewport_renderer = {}

local window_width_div_2 = love.graphics.getWidth() / 2
local window_height_div_2 = love.graphics.getHeight() / 2

local depth_quality = 4

function viewport_renderer.render_3d(renderer)
    
    local sin_cos = renderer.sin_cos_vector(renderer)
    
    local sin_vec = sin_cos[1]
    local cos_vec = sin_cos[2]
    local line_points = {}
    for mesh_index, mesh in pairs(renderer.geometry) do
        -- print("drawing mesh", mesh_index, #mesh)
        local faces = mesh.faces
        for _, face in pairs(faces) do
            local inds = {}
            local face_verts = face 
            if #face_verts >= 3 then  -- split ngons into tris
                for i = 2, #face_verts - 1 do
                    table.insert(inds, face_verts[1])
                    table.insert(inds, face_verts[i])
                    table.insert(inds, face_verts[i + 1])
                end
            end
            for i = 1, #inds, 3 do 
                local vert_index1 = inds[i]
                local vert_index2 = inds[i + 1]
                local vert_index3 = inds[i + 2]
                local behind_camera = false 
                if vert_index1 and vert_index2 and vert_index3 then
                    local vert1 = mesh.vertex[vert_index1]
                    local vert2 = mesh.vertex[vert_index2]
                    local vert3 = mesh.vertex[vert_index3]
                    
                    local verts = {vert1, vert2, vert3}
                    local pixels = {}
                    for i, vert in ipairs(verts) do
                        -- translate by camera
                        local world_x = vert[1] - renderer["cam_position"][1]
                        local world_y = vert[2] - renderer["cam_position"][2]
                        local world_z = vert[3] - renderer["cam_position"][3] + renderer["cam_rotation"][1]
                        -- translate to rotated types
                        
                        local cos = cos_vec[2]
                        local sin = sin_vec[2]

                        local rotated_x = (world_x * cos) - (world_y * sin)
                        local rotated_y = (world_y * cos) + (world_x * sin)
                        
                        verts[i] = {rotated_x, rotated_y, world_z}

                        if rotated_y >= -1 then
                            behind_camera = true
                            break 
                        end

                        local screen_x = rotated_x * window_width_div_2 / (rotated_y + 1) + window_height_div_2
                        local screen_y = world_z * window_width_div_2 / (rotated_y + 1) + window_height_div_2
                        
                        table.insert(pixels, {screen_x, screen_y})
                        
                    end
                    if not behind_camera then
                        renderer.rasterize_tri(renderer, verts, pixels)
                    end

                end
            end
        end
    end

    return line_points

end


function viewport_renderer.rasterize_tri(renderer, verts, pixels)
    -- print(#verts)
    local va = verts[1]
    local vb = verts[2]
    local vc = verts[3]

    local center_x = (va[1] + vb[1] + vc[1]) / 3
    local center_y = (va[2] + vb[2] + vc[2]) / 3
    local center_z = (va[3] + vb[3] + vc[3]) / 3

-- Calculate normal vector
    local v1 = {vb[1] - va[1], vb[2] - va[2], vb[3] - va[3]}
    local v2 = {vc[1] - va[1], vc[2] - va[2], vc[3] - va[3]}
    local normal = {
        v1[2] * v2[3] - v1[3] * v2[2],
        v1[3] * v2[1] - v1[1] * v2[3],
        v1[1] * v2[2] - v1[2] * v2[1]
    }

    -- Calculate camera to triangle vector
    local camera_to_center = {
        center_x - renderer["cam_position"][1],
        center_y - renderer["cam_position"][2],
        center_z - renderer["cam_position"][3]
    }

    -- Calculate dot product, might be useful for something
    local dot_product = normal[1] * camera_to_center[1] + normal[2] * camera_to_center[2] + normal[3] * camera_to_center[3]

    local pa = pixels[1]
    local pb = pixels[2]
    local pc = pixels[3]

    local x_min = math.floor( math.max(0, math.min(pa[1], pb[1], pc[1])))
    local y_min = math.floor( math.max(0, math.min(pa[2], pb[2], pc[2])) )

    local x_max = math.floor( math.min( window_width_div_2 * 2, math.max(pa[1], pb[1], pc[1])))
    local y_max = math.floor( math.min( window_height_div_2 * 2, math.max(pa[2], pb[2], pc[2])))
    -- print(x_min, x_max, y_min, y_max, x_max - x_min, y_max - y_min, dot_product)

    for x = x_min, x_max do
        
        for y = y_min, y_max  do
            local pixel = {math.floor(x), math.floor(y)}
            
            local e = { Determine(pb, pc, pixel), Determine(pc, pa, pixel), Determine(pa, pb, pixel) }
            if e[1] >= 0 and e[2] >= 0 and e[3] >= 0 then
                
                local vert_depth = Calculate_depth(renderer, {center_x, center_y, center_z})
                
                if vert_depth > 100 then
                    return     
                end

                local depth_index = math.floor((pixel[1] * (window_width_div_2 * 2) + pixel[2]) / depth_quality)
                if depth_index > 1 then
                    local depth_in_table = renderer["depth_field"][depth_index]
                    if depth_in_table ~= nil then
                        if vert_depth <= depth_in_table then
                            renderer["depth_field"][depth_index] = vert_depth
                            love.graphics.setPointSize(depth_quality - 2)
                            
                            -- love.graphics.setColor(dot_product, dot_product, dot_product)

                            if pixel[1] % depth_quality * 2 == 0 and pixel[2] % depth_quality * 2 == 0 then
                                love.graphics.points({pixel[1], pixel[2] })
                            end

                        end

                    end

                end

            end 
        end
    end
end


function Determine(a, b, c)
    local ab = {b[1] - a[1], b[2] - a[2]}
    local ac = {c[1] - a[1], c[2] - a[2]}
    return ab[2] * ac[1] - ab[1] * ac[2];
end


function Calculate_depth(renderer, vertex) 
    local cam_pos = renderer["cam_position"]
    return math.sqrt( (cam_pos[1] - vertex[1]) ^ 2 + (cam_pos[2] - vertex[2]) ^ 2 + (cam_pos[3] - vertex[3]) ^ 2 )
end

function viewport_renderer.sin_cos_vector(renderer)
    return {
        {
            math.sin(renderer["cam_rotation"][1]),
            math.sin(renderer["cam_rotation"][2]),
            math.sin(renderer["cam_rotation"][3]),
        },
        {
            math.cos(renderer["cam_rotation"][1]),
            math.cos(renderer["cam_rotation"][2]),
            math.cos(renderer["cam_rotation"][3]),
        },
    }

end

function viewport_renderer.initializeDepthTable(renderer, size, value)
    local tbl = {}
    for i = 1, size / depth_quality do
      tbl[i] = value
    end
    return tbl
  end


function viewport_renderer.new()
    local self = {}
    self.cam_position = {0, 0, 0}
    self.cam_rotation = {0, 0, 0}
    self.depth_field = {}

    self.geometry = {}
    -- print("loaded")
    setmetatable(self, { __index = viewport_renderer })
    return self
end


return viewport_renderer