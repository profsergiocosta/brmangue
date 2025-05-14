

function cria_map_alt () 

	return 
		Map{
			target = cs,
			select = "Alt2",
			color  = "RdYlGn",
			min = 0,
			max = 6,
			slices = 10
		}

end

function cria_map () 

return 
	Map{
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
			"Área Antrópica Inundado",
			"Mangue Migrado",
			"Mangue Inundado",
			"Vegetação Terrestre Inundado"
		}
	}
end





-- funcoes temporarias, so para simplificar a leitura do codigo

function inundar(cell)
    if cell.Usos == AREA_ANTROPIZADA then
        cell.Usos = AREA_ANTROPIZADA_INUNDADO
    elseif cell.Usos == SOLO_DESCOBERTO then
        cell.Usos = SOLO_DESCOBERTO_INUNDADO
    elseif cell.Usos == VEGETACAO_TERRESTRE then
        cell.Usos = VEGETACAO_TERRESTRE_INUNDADO
    elseif cell.Usos == MANGUE or cell.Usos == MANGUE_MIGRADO then
        cell.Usos = MANGUE_INUNDADO
    end
end


function isMarOrInundado(uso)
    return 
		   uso == MAR or
           uso == MANGUE_INUNDADO or
           uso == AREA_ANTROPIZADA_INUNDADO or
           uso == SOLO_DESCOBERTO_INUNDADO or
           uso == VEGETACAO_TERRESTRE_INUNDADO
end


