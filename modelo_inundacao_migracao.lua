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
	--cell_usos = "data/teste1/Recorte_Teste.shp",
	--cell_usos = "data/teste_uso/Recorte_Teste.shp",
	cell_usos = "data/anil/elevacao_pol.shp",
    clean = true,

}


-------Database Conection
cs = CellularSpace{
	project = recorte,
	layer = "cell_usos",
    xy = { "Col", "Lin" },
	select= { "ClaseSolos", "Alt2", "Usos" }
}



cs:createNeighborhood { 
   strategy = "moore", 
   self = false 
}
cs:synchronize(); 

function calc_altitude_media (cs) 
    soma = 0
	n = 0

	soma_mar = 0
	n_mar = 0
    forEachCell(cs, function(cell)
       -- if (cell.Usos == MAR) then
	   if (isMarOrInundado(cell.past.Usos)) then
            soma_mar = soma_mar + cell.Alt2
            n_mar = n_mar + 1
        end
		soma = soma + cell.Alt2
		n = n + 1
    end)

    return soma / n, soma_mar / n_mar
end

function sleep (a) 
    local sec = tonumber(os.clock() + a); 
    while (os.clock() < sec) do 
    end 
end

BrMangue = Model {

	start = 1,
	finalTime = 100,
   

	alturaMare = 6,
	Tx_elev = 0.011, -- Rate of sea-level rise (m) in a scenario of increase of approximately 0.81 m by 2100 (IPCC, 2013, p.17). 
	--Tx_elev = 0,
	init = function (model) 

		model.altitude_media, model.altitude_media_mar = calc_altitude_media(cs)

		model.map_alt = cria_map_alt()
		model.map = cria_map()
		--model.map_solo = cria_map_solo()

        model.chart_mar = Chart{
			target = model,
			select = {"altitude_media_mar"}
		}

		model.chart = Chart{
			target = model,
			select = {"altitude_media"}
		}

		model.timer = Timer {

           

			Event{
				action = function (ev)
					local time = ev:getTime()
					print("ITERACAO : ", time )
					forEachCell(cs, function(cell)

						
						if (isMarOrInundado(cell.past.Usos)) and cell.past.Alt2 >= 0 then				
							
							countNeigh = 1 -- no m�nimo ter� a pr�pria c�lula
							forEachNeighbor(cell, function(neigh)
								if (neigh.past.Alt2 < cell.past.Alt2) then -- --CONTA QTOS VIZINHOS São MAIS BAIXOS QUE A C�LULA CORRENTE
									countNeigh = countNeigh + 1
								end
							end)
						
						
							fluxo = model.Tx_elev / countNeigh
							cell.Alt2 = cell.Alt2 + fluxo 
				
							-- conferir a regra de inundação
							forEachNeighbor(cell, function(neigh)
								if (neigh.past.Alt2 < cell.past.Alt2) then 
									neigh.Alt2 = neigh.Alt2 + fluxo
									if ( not isMarOrInundado(neigh.past.Usos)) then
										inundar (neigh) -- alteracao de valores para inundado
									end
								end
							end)



						-- Sea-level rise in the cell reference
						Elev_m =  (time * model.Tx_elev)  -- cellreference.Alt2 + (time * Tx_elev)
						-- rate of vertical accretion of mud - Txa (in mm)
						Elev_mm = Elev_m * 1000 -- Sea-level rise in mm
						Txa = 1.693 + (0.939 * Elev_mm) -- Equation proposed by Alongi (2008) with R2 = 0,704 and p < 0,001
						Txa_m = Txa / 1000 -- Txa in metrs

						--[[
						adaptar a logica
						-- rate of vertical accretion of mud in each cell
						if (cell.past.ClasseSolos ~= MANGROVE_SOIL2 and cell.ClasseSolos == MANGROVE_SOIL2) or (cell.ClassesSolos == MANGROVE_SOIL) and 
								(cell.ClasseUsos2 ~= SEE) then												 	
								cell.Alt2 = cell.Alt2 + Txa_m
						end
						--]]

						end
					end)
					
					model.altitude_media, model.altitude_media_mar = calc_altitude_media(cs)

					cs:synchronize()
					--cs:save("result"..ev:getTime(), "Alt2")
                    
					--sleep(0.5)
				end
			},

			Event {action = model.map_alt},
			Event {action = model.map},
			--Event {action = model.map_solo},
            Event {start = model.start + 2, action = model.chart},
			Event {start = model.start + 2, action = model.chart_mar}
		}
	end,
}


--BrMangue:configure() --segmentation fault
BrMangue:run()