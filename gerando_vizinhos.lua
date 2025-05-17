import("gis")

local project = Project{
    file = "recorte.qgs",
    --cell_usos = "data/anil/elevacao_pol.shp",
    cell_usos = "data/teste1/Recorte_Teste.shp",
    clean = true
}

local cs = CellularSpace{
    project = project,
    layer = "cell_usos",
    xy = { "Col", "Lin" },
    select = { "object_id0","ClasseSolos", "Alt2", "Usos" }
}

cs:createNeighborhood{ strategy = "moore", self = false }


-- Função para imprimir a lista de vizinhos no estilo PySAL
neighbors = {}

forEachCell(cs, function(cell)
    local cell_id = cell.object_id0
    neighbors[cell_id] = {}

    forEachNeighbor(cell, function(neigh)
        table.insert(neighbors[cell_id], neigh.object_id0)
    end)
end)

-- Gera arquivo .gal
filename = "output.gal"
file = io.open(filename, "w")

-- Escreve o número total de regiões
file:write(tostring(#cs) .. "\n")

-- Escreve as vizinhanças no formato GAL
for id, neighs in pairs(neighbors) do
    file:write(tostring(id) .. " " .. tostring(#neighs))
    for _, n in ipairs(neighs) do
        file:write(" " .. tostring(n))
    end
    file:write("\n")
end

file:close()
print("Arquivo GAL gerado: " .. filename)