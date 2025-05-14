-- Sea-Level Rise Impacts on Mangrove Ecosystem 
-- Case Study:  Maranhense retrances
-- Author: Denilson da Silva Bezerra
-- New version refactored by: H�lder Pereira Borges
-------uso e ocupa��o

import("gis")

require ("brmangueutils")

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
-------
-------tipo de solo
SOLO_MANGUE = 1
SOLO_MANGUE_MIGRADO = 3
CHANNEL_RIVER = 0
-------



recorte = Project{
	file = "recorte.qgs",
	cell_usos = "data/teste_uso/Recorte_Teste.shp",
    clean = true,

}


-------Database Conection
cs = CellularSpace{
	project = recorte,
	layer = "cell_usos",
    xy = { "Col", "Lin" },
	select= { "ClasseSolos", "Alt2", "Usos" }
}



cs:createNeighborhood { 
   strategy = "moore", 
   self = false 
}
cs:synchronize(); 

function calc_altitude_media (cs) 
    soma = 0
    n = 0
    forEachCell(cs, function(cell)
        if (cell.Usos == MAR) then
            soma = soma + cell.Alt2
            n = n + 1
        end
    end)
    media = soma / n
    --print (media)
    return media
end

function sleep (a) 
    local sec = tonumber(os.clock() + a); 
    while (os.clock() < sec) do 
    end 
end

BrMangue = Model {

	start = 1,
	finalTime = 5,
    altitude_media = calc_altitude_media(cs),

	alturaMare = 6,

	init = function (model) 

        

		model.map_alt = cria_map_alt()
		model.map = cria_map()

        model.chart = Chart{
			target = model,
			select = {"altitude_media"}
		}

		model.timer = Timer {

           

			Event{
				action = function (ev)
					print("ITERACAO : ", ev:getTime())
					forEachCell(cs, function(cell)

						
						if (isMarOrInundado(cell.past.Usos)) and cell.past.Alt2 >= 0 then				
							
							countNeigh = 1 -- no m�nimo ter� a pr�pria c�lula

							forEachNeighbor(cell, function(neigh)
							
								if (neigh.past.Alt2 < cell.past.Alt2) then -- --CONTA QTOS VIZINHOS São MAIS BAIXOS QUE A C�LULA CORRENTE
									countNeigh = countNeigh + 1
								end
							end)
						
							aumentoNivelMar = 0.05 -- so para poder testar o comportamento

							qtdAgua = aumentoNivelMar / countNeigh
					
							cell.Alt2 = cell.Alt2 + qtdAgua 
				
							forEachNeighbor(cell, function(neigh)
								if (neigh.past.Alt2 < cell.past.Alt2) then 
									neigh.Alt2 = neigh.Alt2 + qtdAgua
									if ( not isMarOrInundado(neigh.past.Usos)) then
										inundar (neigh) -- alteracao de valores para inundado
									end
								end
							end)


							deslocamentoHorizontalLama = model.alturaMare + aumentoNivelMar

						end
					end)
					cs:synchronize()
					--cs:save("result"..ev:getTime(), "Alt2")
                    model.altitude_media = calc_altitude_media(cs)
					sleep(0.5)
				end
			},

			Event {action = model.map_alt},
			Event {action = model.map},
            Event {action = model.chart}
		}
	end,
}


--BrMangue:configure() --segmentation fault
BrMangue:run()