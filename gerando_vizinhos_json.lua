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
    local id = cell.object_id0
    local list = {}

    forEachNeighbor(cell, function(neigh)
        table.insert(list, neigh.object_id0)
    end)

    neighbors[id] = list
end)


-- Função para gerar string JSON de uma lista de números
function list_to_json(lst)
    local s = "["
    for i = 1, #lst do
        s = s .. tostring(lst[i])
        if i < #lst then s = s .. ", " end
    end
    s = s .. "]"
    return s
end

-- Função para escrever lista com aspas duplas
function list_to_json_string(list)
    local s = "["
    for i = 1, #list do
        s = s .. '"' .. list[i] .. '"'
        if i < #list then s = s .. ", " end
    end
    s = s .. "]"
    return s
end

-- Escrever JSON manualmente
local file = io.open("neighbors.json", "w")
file:write("{\n")

local first = true
for id, list in pairs(neighbors) do
    if not first then
        file:write(",\n")
    else
        first = false
    end
    file:write('  "' .. id .. '": ' .. list_to_json_string(list))
end

file:write("\n}\n")
file:close()
print("Arquivo neighbors.json gerado corretamente com aspas.")