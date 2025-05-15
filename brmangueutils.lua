-- Verifica se o uso do solo é mar ou algum tipo de área inundada
function isMarOuInundado(uso)
    return uso == MAR or
           uso == SOLO_DESCOBERTO_INUNDADO or
           uso == AREA_ANTROPIZADA_INUNDADO or
           uso == MANGUE_INUNDADO or
           uso == VEGETACAO_TERRESTRE_INUNDADO
end

-- Aplica transformação de inundação a uma célula com base no uso anterior
function inundar(celula)
    local uso = celula.past.Usos

    if uso == MANGUE then
        celula.Usos = MANGUE_INUNDADO
    elseif uso == VEGETACAO_TERRESTRE then
        celula.Usos = VEGETACAO_TERRESTRE_INUNDADO
    elseif uso == AREA_ANTROPIZADA then
        celula.Usos = AREA_ANTROPIZADA_INUNDADO
    elseif uso == SOLO_DESCOBERTO then
        celula.Usos = SOLO_DESCOBERTO_INUNDADO
    end
end

-- Cria mapa principal com legenda de usos do solo
function cria_map(cs)
	return Map{
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
			{0, 100, 0},       -- MANGUE
			{128, 128, 0},     -- VEGETACAO_TERRESTRE
			{0, 0, 139},       -- MAR
			{255, 215, 0},     -- AREA_ANTROPIZADA
			{255, 222, 173},   -- SOLO_DESCOBERTO
			{0, 0, 0},         -- SOLO_DESCOBERTO_INUNDADO
			{0, 0, 0},         -- AREA_ANTROPIZADA_INUNDADO
			{0, 255, 0},       -- MANGUE_MIGRADO
			{255, 0, 0},       -- MANGUE_INUNDADO
			{0, 0, 0}          -- VEGETACAO_TERRESTRE_INUNDADO
		},
		label = {
			"Mangue",
			"Vegetação Terrestre",
			"Mar",
			"Área Antropizada",
			"Solo Descoberto",
			"Solo Descoberto Inundado",
			"Área Antrópica Inundada",
			"Mangue Migrado",
			"Mangue Inundado",
			"Vegetação Terrestre Inundada"
		}
	}
end

-- Cria mapa de elevação
function cria_map_alt(cellSpace)
    return Map{
        target = cellSpace,
        select = "Alt2",
		color  = "RdYlGn",
        slices = 10,
        size = 1
    }
end
