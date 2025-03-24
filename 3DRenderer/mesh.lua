local mesh = {}

local table = require("table")

function mesh.new() 
    local self = {}
    self.faces = { {1, 1, 1} }
    self.uv = { {0, 1} }
    self.vertex = { {0, 0, 0} }

    self.renderer  = {}

    setmetatable(self, { __index = mesh })
    
    return self
end

function mesh.create_tri(mesh_instance, vertex_table)
    if mesh_instance == nil then
       print("MESH IS NIL") 
    end    
    local face = {}
    local size = #mesh_instance["vertex"]
    if mesh_instance ~= nil then
        for i, vertex in pairs(vertex_table) do 
            table.insert(mesh_instance["vertex"], vertex)
            table.insert(face, size + i)
        end
    end
    table.insert(mesh_instance["faces"], face)
    
    return mesh_instance
end


return mesh