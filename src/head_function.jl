# Function used to calculate the head

function head_evaluation(case::caseData, InputParameters::InputParam)
    path=case.DataPath
    cd(path)
    f=open("Water_volumes_levels.dat")
    line=readline(f)

    line = readline(f)
    items = split(line, " ")
    NMod = parse(Int, items[1]) #set number of modules
    println("NMod = ", NMod)
    water_volumes_file=zeros(Float64,HY.NMod,10);
    water_levels_file=zeros(Float64,HY.NMod,10);
    NVolumes=zeros(NMod);
  
    for iMod=1:NMod
        line = readline(f)
        items = split(line, " ")
        NVolumes[iMod] = parse(Float64, items[1])
        for n=1:NVolumes[iMod]                                      # n = 1:5
        water_volumes_file[iMod,n]=parse(Float64,items[1+n])
        end
    end
    water_volumes_file;

    for iLine = 1:2
        line = readline(f)
    end

    for iMod=1:NMod
        line = readline(f)
        items = split(line, " ")
        for n=1:NVolumes[iMod]                                      # n = 1:5
        water_levels_file[iMod,n]=parse(Float64,items[n])
        end
    end
    water_levels_file;

    #EVALUATE THE WATER LEVELS, GIVEN THE WATER VOLUMES IN THE RESERVOIR
    Water_levels_Simulation=zeros(HY.NMod,NSimScen,NStage,InputParameters.NStep);
    Initial_water_levels=zeros(HY.NMod)
    Head_Simulation = zeros(HY.NMod)

    # CALCULATES THE WATER LEVELS (m a.s.l) AND THE HEAD FROM THE VOLUME RESULTS
    for iMod=1:HY.NMod
        for iScen=1:NSimScen
            for iStage=1:NStage
                for iStep=1:InputParameters.NStep

                    for n=1:NVolumes[iMod]-1                    #n=1:4 in questo ciclo for non considera i punti ma i segmenti
                        
                        if ResultsSim.Reservoir_round[iMod,iScen,iStage,iStep] == water_volumes_file[iMod,n]
                            Water_levels_Simulation[iMod,iScen,iStage,iStep] = water_levels_file[iMod,n]
                            Head_Simulation[iMod,n] = Water_levels_Simulation[1,iScen,iStage,iStep] - Water_levels_Simulation[2,iScen,iStage,iStep]
                        elseif ResultsSim.Reservoir_round[iMod,iScen,iStage,iStep]> water_volumes_file[iMod,n] && ResultsSim.Reservoir_round[iMod,iScen,iStage,iStep]< water_volumes_file[iMod,n+1]
                            Water_levels_Simulation[iMod,iScen,iStage,iStep] = (water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(ResultsSim.Reservoir_round[iMod,iScen,iStage,iStep]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                            Head_Simulation[iMod,n] = Water_levels_Simulation[1,iScen,iStage,iStep] - Water_levels_Simulation[2,iScen,iStage,iStep]
                        end

                        if HY.ResInit0[iMod] > water_volumes_file[iMod,n] && HY.ResInit0[iMod]< water_volumes_file[iMod,n+1]
                            Initial_water_levels[iMod] =(water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(HY.ResInit0[iMod]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                            Head_simulation[iMod,n] = Initial_water_levels[1] - Initial_water_levels[2]
                        end

                        if ResultsSim.Reservoir_round[iMod,iScen,iStage,iStep] == HY.MaxRes[1] && HY.MaxRes[2] * 0.2
                            Water_level_Max[1,iScen,iStage,iStep] = # Devo capire come associare i volumi massimi e minimi con i livelli
                            Water_level_Min[2,iScen,iStage,iStep] = # Da capire
                            Max_Head[iMod,n] = Water_level_Max[1,iScen,iStage,iStep] - Water_level_Min[2,iScen,iStage,iStep] 
                    end
                    
                    if ResultsSim.Reservoir_round[1,iScen,iStage,iStep] == water_volumes_file[1,21]            #water_volumes_file[iMod,5] 
                        Water_levels_Simulation[1,iScen,iStage,iStep] = water_levels_file[1,21]                #water_levels_file[iMod,5]
                    end

                    if ResultsSim.Reservoir_round[2,iScen,iStage,iStep] == water_volumes_file[2,13]            #water_volumes_file[iMod,5] 
                        Water_levels_Simulation[2,iScen,iStage,iStep] = water_levels_file[2,13]                #water_levels_file[iMod,5]
                    end
                    Head_Simulation[iMod,n] = Water_levels_Simulation[1,iScen,iStage,iStep] - Water_levels_Simulation[2,iScen,iStage,iStep]                  
                end
            end
        end
    end

    return Head(water_volumes_file,water_levels_file,NVolumes,Water_levels_Simulation,Head_Simulation) # Max_Head è compreso nel return? Da capire se anche Initial_water_levels è compreso

end

# In questo ciclo si calcola i livelli d'acqua rispetto al livello del mare, dunque per trovare l'head devo andare per il bacino sopra a fare la differenza tra le quote. Per il bacino sotto devo fare la differenza con l'altezza della penstock

function efficiency_evaluation(HY::HydroData, Head)
    for iMod = 1:NMod
        for iSeg = 1:NDSeg[iMod]
            if (iSeg == 1) && Head_simulation[1,n] - Head_simulation[2,n] == Max_Head[iMod,n] # Non so se sia giusto scrivere così
                S1 = HY.Eff[iMod,1]
                eta = S1 / (Max_Head[iMod,n] * 9810)
            elseif (iSeg == 1)
                S1 = eta * 9810 * Head_simulation[iMod,n] # Il codice capisce che eta è la variabile che ho dichiarato sopra?
            end
        end
    end

    return S1

end 


  # Set maximum discharge per segment (DisMaxSeg) and efficiency per segment (Eff), for each hydro module
#=  NDSeg = zeros(Int, NMod)
  MaxSeg = 10
  DisMaxSeg = zeros(Float64, NMod, MaxSeg)
  Eff = zeros(Float64, NMod, MaxSeg)
  for iMod = 1:NMod
    line = readline(f)
    items = split(line, " ")
    NDSeg[iMod] = parse(Int, items[1])
    for iSeg = 1:NDSeg[iMod]
      if (iSeg == 1)
        DisMaxSeg[iMod, iSeg] = parse(Float64, items[1+iSeg*2])
        Eff[iMod, iSeg] = parse(Float64, items[2]) / parse(Float64, items[3])
      else
        DisMaxSeg[iMod, iSeg] =
          parse(Float64, items[1+iSeg*2]) - parse(Float64, items[1+(iSeg-1)*2])
        Eff[iMod, iSeg] =
          (parse(Float64, items[1+iSeg*2-1]) - parse(Float64, items[1+(iSeg-1)*2-1])) /
          DisMaxSeg[iMod, iSeg]
      end
    end
  end =#

