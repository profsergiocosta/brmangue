-- IMPACTOS DA ELEVAÇÃO DO NÍVEL DO MAR EM ECOSSISTEMAS DE MANGUE
-- ESTUDO DE CASO: REENTRÂNCIAS MARANHENSES
-- AUTOR: Denilson da Silva Bezerra
-- REVISADO E REESTRUTURADO POR: Sergio Souza Costa

-- ===============================================================
-- IMPORTAÇÃO DE BIBLIOTECAS
-- ===============================================================
import("gis")

-- ===============================================================
-- CONSTANTES - CLASSES DE USO DA TERRA
-- ===============================================================
USO_MANGUE = 1
USO_VEGETACAO_TERRESTRE = 2
USO_MAR = 3
USO_AREA_ANTROPIZADA = 4
USO_SOLO_DESCOBERTO = 5
USO_SOLO_INUNDADO = 6
USO_AREA_ANTROPIZADA_INUNDADA = 7
USO_MANGUE_MIGRADO = 8
USO_MANGUE_INUNDADO = 9
USO_VEGETACAO_TERRESTRE_INUNDADA = 10

-- ===============================================================
-- CONSTANTES - CLASSES DE SOLO
-- ===============================================================
SOLO_MANGUE = 3
SOLO_MANGUE_MIGRADO = 9
SOLO_CANAL_FLUVIAL = 0

-- ===============================================================
-- MAPEAMENTO DE CLASSES DE USO PARA CAMPOS DO MODELO
-- ===============================================================
mapa_uso_campo = {
    [USO_MAR] = "areaMar",
    [USO_MANGUE] = "areaMangueRemanescente",
    [USO_MANGUE_INUNDADO] = "areaMangueInundado",
    [USO_MANGUE_MIGRADO] = "areaMangueMigrado",
    [USO_AREA_ANTROPIZADA] = "areaAntropizada",
    [USO_AREA_ANTROPIZADA_INUNDADA] = "areaAntropizadaInundada",
    [USO_SOLO_DESCOBERTO] = "areaSoloDescoberto",
    [USO_SOLO_INUNDADO] = "areaSoloInundado",
    [USO_VEGETACAO_TERRESTRE] = "areaVegetacao",
    [USO_VEGETACAO_TERRESTRE_INUNDADA] = "areaVegetacaoInundada"
}

-- ===============================================================
-- FUNÇÕES DE INICIALIZAÇÃO E CONTAGEM
-- ===============================================================
function inicializarAreas(modelo)
    for _, campo in pairs(mapa_uso_campo) do
        modelo[campo] = 0
    end
end

function contarUsoDaTerra(modelo, espacoCelular, areaCelula)
    inicializarAreas(modelo)

    forEachCell(espacoCelular, function(celula)
        local campo = mapa_uso_campo[celula.Usos]
        if campo then
            modelo[campo] = modelo[campo] + areaCelula
        end
    end)

    modelo.areaTotal = 0
    for _, campo in pairs(mapa_uso_campo) do
        modelo.areaTotal = modelo.areaTotal + (modelo[campo] or 0)
    end
end

-- ===============================================================
-- FUNÇÕES AUXILIARES
-- ===============================================================
function ehMarOuInundado(uso)
    return uso == USO_MAR
        or uso == USO_SOLO_INUNDADO
        or uso == USO_AREA_ANTROPIZADA_INUNDADA
        or uso == USO_MANGUE_INUNDADO
        or uso == USO_VEGETACAO_TERRESTRE_INUNDADA
end

function aplicarInundacao(celula)
    local usoAtual = celula.past.Usos
    if usoAtual == USO_MANGUE then
        celula.Usos = USO_MANGUE_INUNDADO
    elseif usoAtual == USO_VEGETACAO_TERRESTRE then
        celula.Usos = USO_VEGETACAO_TERRESTRE_INUNDADA
    elseif usoAtual == USO_AREA_ANTROPIZADA then
        celula.Usos = USO_AREA_ANTROPIZADA_INUNDADA
    elseif usoAtual == USO_SOLO_DESCOBERTO then
        celula.Usos = USO_SOLO_INUNDADO
    end
end

-- ===============================================================
-- FUNÇÃO DE VISUALIZAÇÃO DOS MAPAS
-- ===============================================================
function mapaUso(espacoCelular)
    return Map {
        target = espacoCelular,
        select = "Usos",
        value = {
            USO_MANGUE,
            USO_VEGETACAO_TERRESTRE,
            USO_MAR,
            USO_AREA_ANTROPIZADA,
            USO_SOLO_DESCOBERTO,
            USO_SOLO_INUNDADO,
            USO_AREA_ANTROPIZADA_INUNDADA,
            USO_MANGUE_MIGRADO,
            USO_MANGUE_INUNDADO,
            USO_VEGETACAO_TERRESTRE_INUNDADA
        },
        color = {
            { 0,   100, 0 },
            { 128, 128, 0 },
            { 0,   0,   139 },
            { 255, 215, 0 },
            { 255, 222, 173 },
            { 0,   0,   0 },
            { 0,   0,   0 },
            { 0,   255, 0 },
            { 255, 0,   0 },
            { 0,   0,   0 }
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

function mapaAltitude(espacoCelular)
    return Map {
        target = espacoCelular,
        select = "Alt2",
        color = "RdYlGn",
        slices = 5,
        size = 1
    }
end

-- ===============================================================
-- CARREGAMENTO DO PROJETO E ESPAÇO CELULAR
-- ===============================================================
local projeto = Project {
    file = "recorte.qgs",
    cell_usos = "data/anil/elevacao_pol.shp",
    clean = true
}

local espacoCelular = CellularSpace {
    project = projeto,
    layer = "cell_usos",
    xy = { "Col", "Lin" },
    select = { "ClaseSolos", "Alt2", "Usos" }
}

espacoCelular:createNeighborhood { strategy = "moore", self = false }
espacoCelular:synchronize()

-- ===============================================================
-- MODELO PRINCIPAL
-- ===============================================================
ModeloMangue = Model {
    start = 1,
    finalTime = 100,

    areaCelula = 0.09,
    alturaMare = 6, -- altura da maré (Ferreira, 1988)
    taxaElevacaoMar = 0.5,
    --taxaElevacaoMar = 0.011,  -- Taxa de elevação do nível do mar (IPCC, 2013)

    init = function(modelo)

        inicializarAreas(modelo)

        modelo.grafico = Chart{
            target = modelo,
            select = {
                "areaVegetacao",
                "areaVegetacaoInundada",
                "areaMangueMigrado"
            }
        }

        modelo.mapaAltitude = mapaAltitude(espacoCelular)
        modelo.mapaUso = mapaUso(espacoCelular)

        modelo.timer = Timer {
            Event {
                action = function(evento)
                    local tempo = evento:getTime()
                    print("ITERAÇÃO:", tempo)

                    forEachCell(espacoCelular, function(celula)
                        -- AUMENTO DE NÍVEL DO MAR
                        if ehMarOuInundado(celula.past.Usos) and celula.past.Alt2 >= 0 then
                            local vizinhosBaixos = 1

                            forEachNeighbor(celula, function(vizinho)
                                if vizinho.past.Alt2 < celula.past.Alt2 then
                                    vizinhosBaixos = vizinhosBaixos + 1
                                end
                            end)

                            local fluxo = modelo.taxaElevacaoMar / vizinhosBaixos
                            celula.Alt2 = celula.Alt2 + fluxo

                            forEachNeighbor(celula, function(vizinho)
                                if vizinho.past.Alt2 < celula.past.Alt2 then
                                    vizinho.Alt2 = vizinho.Alt2 + fluxo

                                    if not ehMarOuInundado(vizinho.past.Usos) then
                                        aplicarInundacao(vizinho)
                                    end
                                end
                            end)
                        end
                        ---------------------------------------------------------
                        -- DINÂMICA DO MANGUE
                        ----------------------------------
                        local nivelMar = tempo * modelo.taxaElevacaoMar
                        local nivelMar_mm = nivelMar * 1000
                        local taxaAcrecao_mm = 1.693 + (0.939 * nivelMar_mm)
                        local taxaAcrecao_m = taxaAcrecao_mm / 1000
                        local zonaInfluencia = modelo.alturaMare + nivelMar

                        if celula.ClaseSolos == SOLO_MANGUE or celula.ClaseSolos == SOLO_CANAL_FLUVIAL then
                            forEachNeighbor(celula, function(vizinho)
                                if (vizinho.Usos == USO_VEGETACAO_TERRESTRE or vizinho.Usos == USO_SOLO_DESCOBERTO)
                                    and vizinho.ClaseSolos ~= SOLO_MANGUE
                                    and vizinho.Alt2 <= zonaInfluencia then
                                    vizinho.ClaseSolos = SOLO_MANGUE_MIGRADO
                                end
                            end)
                        end

                        if celula.Usos == USO_MANGUE then
                            forEachNeighbor(celula, function(vizinho)
                                if (vizinho.Usos == USO_VEGETACAO_TERRESTRE or vizinho.Usos == USO_SOLO_DESCOBERTO)
                                    and vizinho.Alt2 <= zonaInfluencia
                                    and (vizinho.ClaseSolos == SOLO_MANGUE_MIGRADO or vizinho.ClaseSolos == SOLO_MANGUE) then
                                    vizinho.Usos = USO_MANGUE_MIGRADO
                                end
                            end)
                        end

                        -- ACRESÇÃO VERTICAL DA LAMA
                        if (celula.ClaseSolos == SOLO_MANGUE or celula.ClaseSolos == SOLO_MANGUE_MIGRADO)
                            and not ehMarOuInundado(celula.Usos) then
                            celula.Alt2 = celula.Alt2 + taxaAcrecao_m
                        end
                        
                    end)

                    espacoCelular:synchronize()
                end
            },

            Event { action = modelo.mapaAltitude },
            Event { action = modelo.mapaUso },

            Event {
                action = function(evento)
                    contarUsoDaTerra(modelo, espacoCelular, modelo.areaCelula)
                end
            },

            Event {
                start = modelo.start + 1,
                action = modelo.grafico
            }
        }
    end
}

ModeloMangue:run()
