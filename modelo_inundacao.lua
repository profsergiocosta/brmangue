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
	cell_usos = "data/teste1/Recorte_Teste.shp",
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



BrMangue = Model {

	start = 1,
	finalTime = 10,

	init = function (model) 

		model.map_alt = cria_map_alt()
		model.map = cria_map()

		model.timer = Timer {

			Event{
				action = function (ev)
					print("ITERACAO : ", ev:getTime())
					forEachCell(cs, function(cell)

						-- inundação
						if (isMarOrInundado(cell.past.Usos)) and cell.Alt2 >= 0 then				
							
							countNeigh = 1 -- no m�nimo ter� a pr�pria c�lula

							forEachNeighbor(cell, function(neigh)
							
								if (neigh.past.Alt2 < cell.past.Alt2) then -- --CONTA QTOS VIZINHOS São MAIS BAIXOS QUE A C�LULA CORRENTE
									countNeigh = countNeigh + 1
								end
							end)
						
							aumentoNivelMar = 0.5 -- so para poder testar o comportamento

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
						end
					end)
					cs:synchronize()
					--cs:save("result"..ev:getTime(), "Alt2")
				end
			},

			Event {action = model.map_alt},
			Event {action = model.map},
		}
	end,
}


--BrMangue:configure() --segmentation fault
BrMangue:run()