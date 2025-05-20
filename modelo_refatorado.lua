-- Sea-Level Rise Impacts on Mangrove Ecosystem
-- Case Study: Maranhense Reentrances
-- Author: Denilson da Silva Bezerra
-- Refactored by: Sergio Souza Costa

-- IMPORTS
import("gis")


-- CONSTANTES - CLASSES DE USO DA TERRA
MANGUE = 1
VEGETACAO_TERRESTRE = 2
MAR = 3
AREA_ANTROPIZADA = 4
SOLO_DESCOBERTO = 5
SOLO_DESCOBERTO_INUNDADO = 6
AREA_ANTROPIZADA_INUNDADO = 7
MANGUE_MIGRADO = 8
MANGUE_INUNDADO = 9
VEGETACAO_TERRESTRE_INUNDADO = 10

-- CONSTANTES - CLASSES DE SOLO
SOLO_MANGUE = 3
SOLO_MANGUE_MIGRADO = 9

CANAL_FLUVIAL = 0

-- FUNÇÃO UTILITÁRIA: VERIFICA SE É MAR OU INUNDADO
function isSeaOrFlooded(uso)
    return uso == MAR or
        uso == SOLO_DESCOBERTO_INUNDADO or
        uso == AREA_ANTROPIZADA_INUNDADO or
        uso == MANGUE_INUNDADO or
        uso == VEGETACAO_TERRESTRE_INUNDADO
end

-- FUNÇÃO DE INUNDAÇÃO
function applyFlooding(cell)
    local uso = cell.past.Usos

    if uso == MANGUE then
        cell.Usos = MANGUE_INUNDADO
    elseif uso == VEGETACAO_TERRESTRE then
        cell.Usos = VEGETACAO_TERRESTRE_INUNDADO
    elseif uso == AREA_ANTROPIZADA then
        cell.Usos = AREA_ANTROPIZADA_INUNDADO
    elseif uso == SOLO_DESCOBERTO then
        cell.Usos = SOLO_DESCOBERTO_INUNDADO
    end
end

-- MAPA DE USO DA TERRA
function cria_map(cs)
    return Map {
        target = cs,
        select = "Usos",
        value = {
            MANGUE,
            VEGETACAO_TERRESTRE,
            MAR,
            AREA_ANTROPIZADA,
            SOLO_DESCOBERTO,
            SOLO_DESCOBERTO_INUNDADO,
            AREA_ANTROPIZADA_INUNDADO,
            MANGUE_MIGRADO,
            MANGUE_INUNDADO,
            VEGETACAO_TERRESTRE_INUNDADO
        },
        color = {
            { 0,   100, 0 }, -- MANGUE
            { 128, 128, 0 }, -- VEGETACAO_TERRESTRE
            { 0,   0,   139 }, -- MAR
            { 255, 215, 0 }, -- AREA_ANTROPIZADA
            { 255, 222, 173 }, -- SOLO_DESCOBERTO
            { 0,   0,   0 }, -- SOLO_DESCOBERTO_INUNDADO
            { 0,   0,   0 }, -- AREA_ANTROPIZADA_INUNDADO
            { 0,   255, 0 }, -- MANGUE_MIGRADO
            { 255, 0,   0 }, -- MANGUE_INUNDADO
            { 0,   0,   0 }  -- VEGETACAO_TERRESTRE_INUNDADO
        },
        label = {
            "Mangue",
            "Vegetação Terrestre",
            "Mar",
            "Área Antropizada",
            "Solo Descoberto",
            "Solo Descoberto Inundado",
            "Área Antropizada Inundada",
            "Mangue Migrado",
            "Mangue Inundado",
            "Vegetação Terrestre Inundada"
        }
    }
end

-- MAPA DE ALTITUDE
function cria_map_alt(cellSpace)
    return Map {
        target = cellSpace,
        select = "Alt2",
        color  = "RdYlGn",
        slices = 5,
        size   = 1
    }
end

-- PROJETO E ESPAÇO CELULAR
local project = Project {
    file = "recorte.qgs",
    cell_usos = "data/anil/elevacao_pol.shp",
    ---cell_usos = "data/teste1/Recorte_Teste.shp",
    clean = true
}

local cellSpace = CellularSpace {
    project = project,
    layer = "cell_usos",
    xy = { "Col", "Lin" },
    select = { "ClasseSolos", "Alt2", "Usos" }
}

cellSpace:createNeighborhood { strategy = "moore", self = false }
cellSpace:synchronize()

-- CÁLCULO DE ALTURAS MÉDIAS
function calculateAverageAltitudes(cs)
    local totalAlt = 0
    local totalSeaAlt = 0
    local count = 0
    local seaCount = 0

    forEachCell(cs, function(cell)
        totalAlt = totalAlt + cell.Alt2
        count = count + 1
        if isSeaOrFlooded(cell.past.Usos) then
            totalSeaAlt = totalSeaAlt + cell.Alt2
            seaCount = seaCount + 1
        end
    end)

    return totalAlt / count, totalSeaAlt / seaCount
end

-- MODELO PRINCIPAL
BrMangue = Model {
    start = 1,
    finalTime = 100,

    tideHeight = 6, -- Altura da maré (Ferreira, 1988)
    --seaLevelRiseRate = 0.011,  -- Taxa de elevação do nível do mar (IPCC, 2013)
    seaLevelRiseRate = 0.5,

    init = function(model)
        model.avgAlt, model.avgSeaAlt = calculateAverageAltitudes(cellSpace)

        model.altMap = cria_map_alt(cellSpace)
        model.landUseMap = cria_map(cellSpace)

        --model.chartSea = Chart{ target = model, select = { "avgSeaAlt" } }
        --model.chartAlt = Chart{ target = model, select = { "avgAlt" } }

        model.timer = Timer {
            Event {
                action = function(event)
                    local time = event:getTime()
                    print("ITERAÇÃO:", time)

                    local celulas_modificadas = 0 -- apenas para verificar se nao esta perdendo agua
                    local soma_elevacao = 0

                    forEachCell(cellSpace, function(cell)
                        if isSeaOrFlooded(cell.past.Usos) and cell.past.Alt2 >= 0 then
                            local neighborCount = 1

                            forEachNeighbor(cell, function(neigh)
                                if neigh.past.Alt2 < cell.past.Alt2 then
                                    neighborCount = neighborCount + 1
                                end
                            end)

                            local flow = model.seaLevelRiseRate / neighborCount
                            cell.Alt2 = cell.Alt2 + flow

                            celulas_modificadas = celulas_modificadas + 1
                            soma_elevacao = soma_elevacao + flow

                            forEachNeighbor(cell, function(neigh)
                                if neigh.past.Alt2 < cell.past.Alt2 then
                                    neigh.Alt2 = neigh.Alt2 + flow

                                    soma_elevacao = soma_elevacao + flow  -- apenas para verificar se nao esta perdendo agua

                                    if not isSeaOrFlooded(neigh.past.Usos) then
                                        applyFlooding(neigh) -- quando adiciona-se novas celulas de uso agua, tera mais celulas aumentando o nivel
                                    end
                                end
                            end)
                        end

                        ---------------------------------------------
                        --- Dinâmica da lama (migração do mangue)
                        --- ----------------------------------------
                        
                        
                        local nmrm = time * model.seaLevelRiseRate
                        local nmrm_m = nmrm * 1000
                        local accretionRate_mm = 1.693 + (0.939 * nmrm_m)
                        local accretionRate_m = accretionRate_mm / 1000

                        local tidalInfluenceZone = model.tideHeight + nmrm

                        if cell.ClasseSolos == SOLO_MANGUE or cell.ClasseSolos == CANAL_FLUVIAL then
                            forEachNeighbor(cell, function(neigh)
                                if (neigh.Usos == VEGETACAO_TERRESTRE or neigh.Usos == SOLO_DESCOBERTO)
                                    and (neigh.ClasseSolos ~= SOLO_MANGUE)
                                    and (neigh.Alt2 <= tidalInfluenceZone) then
                                    neigh.ClasseSolos = SOLO_MANGUE_MIGRADO
                                end
                            end)
                        end

                        if cell.Usos == MANGUE then
                            forEachNeighbor(cell, function(neigh)
                                if (neigh.Usos == VEGETACAO_TERRESTRE or neigh.Usos == SOLO_DESCOBERTO)
                                    and neigh.Alt2 <= tidalInfluenceZone
                                    and (neigh.ClasseSolos == SOLO_MANGUE_MIGRADO or neigh.ClasseSolos == SOLO_MANGUE)
                                then
                                    neigh.Usos = MANGUE_MIGRADO
                                end
                            end)
                        end


                        --
                        -- rate of vertical accretion of mud in each cell
                        if (cell.ClasseSolos == MANGUE)
                            or (cell.ClassesSolos == MANGUE_MIGRADO)
                            and not isSeaOrFlooded(cell.Usos) then
                            cell.Alt2 = cell.Alt2 + accretionRate_m --- Alongi
                        end
                        --
                    end)
                    -- verificar se nao esta perdendo "agua"
                    print(celulas_modificadas, soma_elevacao, soma_elevacao / celulas_modificadas)

                    model.avgAlt, model.avgSeaAlt = calculateAverageAltitudes(cellSpace)
                    cellSpace:synchronize()
                end
            },
            Event { action = model.altMap },
            Event { action = model.landUseMap },
            --Event{ start = model.start + 2, action = model.chartAlt },
            --Event{ start = model.start + 2, action = model.chartSea }
        }
    end
}

BrMangue:run()
