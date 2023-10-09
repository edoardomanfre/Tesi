# Function used to calculate the head

function head_evaluation(
    case::caseData, 
    Reservoir,
    HY::HydroData,
    iScen,
    t,
    NStep
    )

    path=case.DataPath
    cd(path)
    f=open("Water_volumes_levels.dat")
    line=readline(f)

    line = readline(f)
    items = split(line, " ")
    NMod = parse(Int, items[1]) #set number of modules
    println("NMod = ", NMod)
    water_volumes_file=zeros(Float64,HY.NMod,21);
    water_levels_file=zeros(Float64,HY.NMod,21);
    NVolumes=zeros(NMod);
  
    for iMod=1:NMod
        line = readline(f)
        items = split(line, " ")
        NVolumes[iMod] = parse(Int, items[1])
        for n=1:21 #NVolumes[iMod]                                   
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
        for n=1:21 #NVolumes[iMod]                                  
        water_levels_file[iMod,n]=parse(Float64,items[n])            
        end
    end
    water_levels_file;

    #EVALUATE THE WATER LEVELS, GIVEN THE WATER VOLUMES IN THE RESERVOIR
    Water_levels_Simulation=zeros(HY.NMod);
    Initial_water_levels=zeros(HY.NMod)
    Head_Simulation_upper = 0
    Head_Simulation_lower = 0
    Max_Head_upper = 0
    Max_Head_lower = 0

    # CALCULATES THE WATER LEVELS (m a.s.l) AND THE HEAD FROM THE VOLUME RESULTS
    
    for iMod=1:HY.NMod

        for n=1:20 #NVolumes[iMod]-1
            
            if iScen == 1
                if t == 1
                    Reservoir[iMod,iScen,t,NStep] == HY.ResInit0[iMod] # Controllo su ResInit0 = water volume file
                    if HY.ResInit0[iMod] == water_volumes_file[iMod,n] 
                        Initial_water_levels[iMod] = water_levels_file[iMod,n] 
                        Head_Simulation_upper = Initial_water_levels[1] - Initial_water_levels[2]
                        Head_Simulation_lower = Initial_water_levels[2] - 460
                    elseif HY.ResInit0[iMod] > water_volumes_file[iMod,n] && HY.ResInit0[iMod]< water_volumes_file[iMod,n+1]
                        Initial_water_levels[iMod] =(water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(HY.ResInit0[iMod]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                        Head_Simulation_upper = Initial_water_levels[1] - Initial_water_levels[2]
                        Head_Simulation_lower = Initial_water_levels[2] - 460
                    elseif HY.ResInit0[1] == HY.MaxRes[1] && HY.ResInit0[2] == HY.MaxRes[2] * 0.2
                        Water_level_Max_upper[1,iScen,t,NStep] = 1750
                        Water_level_Max_lower[2,iScen,t,NStep] = 900
                        Water_level_Min_lower[2,iScen,t,NStep] = 878.125
                        Max_Head_upper = Water_level_Max[1,iScen,t,NStep] - Water_level_Min[2,iScen,t,NStep] 
                        Max_Head_lower = Water_level_Max_lower[2,iScen,t,NStep] - 460
                    end
                else        
                    if Reservoir[iMod,iScen,t-1,NStep] == water_volumes_file[iMod,n]
                        Water_levels_Simulation[iMod,iScen,t-1,NStep] = water_levels_file[iMod,n] 
                        Head_Simulation_upper = Water_levels_Simulation[1,iScen,t-1,NStep] - Water_levels_Simulation[2,iScen,t-1,NStep]
                        Head_Simulation_lower = Water_levels_Simulation[2,iScen,t-1,NStep] - 460
                    elseif Reservoir[iMod,iScen,t-1,NStep]> water_volumes_file[iMod,n] && Reservoir[iMod,iScen,t-1,NStep]< water_volumes_file[iMod,n+1]
                        Water_levels_Simulation[iMod,iScen,t-1,NStep] = (water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(Reservoir[iMod,iScen,t-1,NStep]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                        Head_Simulation_upper = Water_levels_Simulation[1,iScen,t-1,NStep] - Water_levels_Simulation[2,iScen,t-1,NStep]
                        Head_Simulation_lower = Water_levels_Simulation[2,iScen,t-1,NStep] - 460
                    elseif Reservoir[1,iScen,t-1,NStep] == HY.MaxRes[1] && Reservoir[2,iScen,t-1,NStep] == HY.MaxRes[2] * 0.2
                        Water_level_Max_upper[1,iScen,t-1,NStep] = 1750
                        Water_level_Max_lower[2,iScen,t-1,NStep] = 900
                        Water_level_Min_lower[2,iScen,t-1,NStep] = 878.125
                        Max_Head_upper = Water_level_Max[1,iScen,t-1,NStep] - Water_level_Min[2,iScen,t-1,NStep] 
                        Max_Head_lower = Water_level_Max_lower[2,iScen,t-1,NStep] - 460
                    end
                end
            else
                if t == 1
                    if Reservoir[iMod,iScen-1,end,NStep] == water_volumes_file[iMod,n]
                        Water_levels_Simulation[iMod,iScen-1,end,NStep] = water_levels_file[iMod,n] 
                        Head_Simulation_upper = Water_levels_Simulation[1,iScen-1,end,NStep] - Water_levels_Simulation[2,iScen-1,end,NStep]
                        Head_Simulation_lower = Water_levels_Simulation[2,iScen-1,end,NStep] - 460
                    elseif Reservoir[iMod,iScen-1,end,NStep]> water_volumes_file[iMod,n] && Reservoir[iMod,iScen-1,end,NStep]< water_volumes_file[iMod,n+1]
                        Water_levels_Simulation[iMod,iScen-1,end,NStep] = (water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(Reservoir[iMod,iScen-1,end,NStep]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                        Head_Simulation_upper = Water_levels_Simulation[1,iScen-1,end,NStep] - Water_levels_Simulation[2,iScen-1,end,NStep]
                        Head_Simulation_lower = Water_levels_Simulation[2,iScen-1,end,NStep] - 460
                    elseif Reservoir[1,iScen-1,end,NStep] == HY.MaxRes[1] && Reservoir[2,iScen-1,end,NStep] == HY.MaxRes[2] * 0.2
                        Water_level_Max_upper[1,iScen-1,end,NStep] = 1750
                        Water_level_Max_lower[2,iScen-1,end,NStep] = 900
                        Water_level_Min_lower[2,iScen-1,end,NStep] = 878.125
                        Max_Head_upper = Water_level_Max[1,iScen-1,end,NStep] - Water_level_Min[2,iScen-1,end,NStep] 
                        Max_Head_lower = Water_level_Max_lower[2,iScen-1,end,NStep] - 460
                    end
                else
                    if Reservoir[iMod,iScen,t-1,NStep] == water_volumes_file[iMod,n]
                        Water_levels_Simulation[iMod,iScen,t-1,NStep] = water_levels_file[iMod,n] 
                        Head_Simulation_upper = Water_levels_Simulation[1,iScen,t-1,NStep] - Water_levels_Simulation[2,iScen,t-1,NStep]
                        Head_Simulation_lower = Water_levels_Simulation[2,iScen,t-1,NStep] - 460
                    elseif Reservoir[iMod,iScen,t-1,NStep]> water_volumes_file[iMod,n] && Reservoir[iMod,iScen,t-1,NStep]< water_volumes_file[iMod,n+1]
                        Water_levels_Simulation[iMod,iScen,t-1,NStep] = (water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(Reservoir[iMod,iScen,t-1,NStep]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                        Head_Simulation_upper = Water_levels_Simulation[1,iScen,t-1,NStep] - Water_levels_Simulation[2,iScen,t-1,NStep]
                        Head_Simulation_lower = Water_levels_Simulation[2,iScen,t-1,NStep] - 460
                    elseif Reservoir[1,iScen,t-1,NStep] == HY.MaxRes[1] && Reservoir[2,iScen,t-1,NStep] == HY.MaxRes[2] * 0.2
                        Water_level_Max_upper[1,iScen,t-1,NStep] = 1750
                        Water_level_Max_lower[2,iScen,t-1,NStep] = 900
                        Water_level_Min_lower[2,iScen,t-1,NStep] = 878.125
                        Max_Head_upper = Water_level_Max[1,iScen,t-1,NStep] - Water_level_Min[2,iScen,t-1,NStep] 
                        Max_Head_lower = Water_level_Max_lower[2,iScen,t-1,NStep] - 460
                    end
                end
            end
    
        end
    
    
        if iScen == 1
            if t == 1
                Reservoir[1,iScen,t,NStep] == HY.ResInit0[iMod]
                if HY.ResInit0[iMod] == water_volumes_file[1,21]           
                    Water_levels_Simulation[1,iScen,t,NStep] = water_levels_file[1,21]
                    Head_Simulation_upper = Water_levels_Simulation[1,iScen,t,NStep] - Water_levels_Simulation[2,iScen,t,NStep] 
                elseif HY.ResInit0[iMod] == water_volumes_file[2,21] 
                    Water_levels_Simulation[2,iScen,t,NStep] = water_levels_file[2,21]
                    Head_Simulation_lower = Water_levels_Simulation[2,iScen,t,NStep] - 460 
                elseif HY.ResInit0[iMod] == water_volumes_file[1,21] && HY.ResInit0[iMod] == water_volumes_file[2,21]
                    Water_levels_Simulation[1,iScen,t,NStep] = water_levels_file[1,21]
                    Water_levels_Simulation[2,iScen,t,NStep] = water_levels_file[2,21]
                    Head_Simulation_upper = Water_levels_Simulation[1,iScen,t,NStep] - Water_levels_Simulation[2,iScen,t,NStep] 
                    Head_Simulation_lower = Water_levels_Simulation[2,iScen,t,NStep] - 460
                end     
            else
                if Reservoir[iMod,iScen,t-1,NStep] == water_volumes_file[1,21]
                    Water_levels_Simulation[iMod,iScen,t-1,NStep] = water_levels_file[1,21] 
                    Head_Simulation_upper = Water_levels_Simulation[1,iScen,t-1,NStep] - Water_levels_Simulation[2,iScen,t-1,NStep]
                elseif Reservoir[iMod,iScen,t-1,NStep] == water_volumes_file[2,21] 
                    Water_levels_Simulation[2,iScen,t-1,NStep] = water_levels_file[2,21]
                    Head_Simulation_lower = Water_levels_Simulation[2,iScen,t-1,NStep] - 460 
                elseif HY.ResInit0[iMod] == water_volumes_file[1,21] && HY.ResInit0[iMod] == water_volumes_file[2,21]
                    Water_levels_Simulation[1,iScen,t-1,NStep] = water_levels_file[1,21]
                    Water_levels_Simulation[2,iScen,t-1,NStep] = water_levels_file[2,21]
                    Head_Simulation_upper = Water_levels_Simulation[1,iScen,t-1,NStep] - Water_levels_Simulation[2,iScen,t-1,NStep] 
                    Head_Simulation_lower = Water_levels_Simulation[2,iScen,t-1,NStep] - 460
                end  
            end
        else
            if t == 1
                if Reservoir[iMod,iScen-1,end,NStep] == water_volumes_file[1,21]
                    Water_levels_Simulation[iMod,iScen-1,end,NStep] = water_levels_file[1,21] 
                    Head_Simulation_upper = Water_levels_Simulation[1,iScen-1,end,NStep] - Water_levels_Simulation[2,iScen-1,end,NStep]
                elseif Reservoir[iMod,iScen-1,end,NStep] == water_volumes_file[2,21] 
                    Water_levels_Simulation[2,iScen-1,end,NStep] = water_levels_file[2,21]
                    Head_Simulation_lower = Water_levels_Simulation[2,iScen-1,end,NStep] - 460 
                elseif HY.ResInit0[iMod] == water_volumes_file[1,21] && HY.ResInit0[iMod] == water_volumes_file[2,21]
                    Water_levels_Simulation[1,iScen-1,end,NStep] = water_levels_file[1,21]
                    Water_levels_Simulation[2,iScen-1,end,NStep] = water_levels_file[2,21]
                    Head_Simulation_upper = Water_levels_Simulation[1,iScen-1,end,NStep] - Water_levels_Simulation[2,iScen-1,end,NStep] 
                    Head_Simulation_lower = Water_levels_Simulation[2,iScen-1,end,NStep] - 460
                end    
            else
                if Reservoir[iMod,iScen,t-1,NStep] == water_volumes_file[1,21]
                    Water_levels_Simulation[iMod,iScen,t-1,NStep] = water_levels_file[1,21] 
                    Head_Simulation_upper = Water_levels_Simulation[1,iScen,t-1,NStep] - Water_levels_Simulation[2,iScen,t-1,NStep]
                elseif Reservoir[iMod,iScen,t-1,NStep] == water_volumes_file[2,21] 
                    Water_levels_Simulation[2,iScen,t-1,NStep] = water_levels_file[2,21]
                    Head_Simulation_lower = Water_levels_Simulation[2,iScen,t-1,NStep] - 460 
                elseif HY.ResInit0[iMod] == water_volumes_file[1,21] && HY.ResInit0[iMod] == water_volumes_file[2,21]
                    Water_levels_Simulation[1,iScen,t-1,NStep] = water_levels_file[1,21]
                    Water_levels_Simulation[2,iScen,t-1,NStep] = water_levels_file[2,21]
                    Head_Simulation_upper = Water_levels_Simulation[1,iScen,t-1,NStep] - Water_levels_Simulation[2,iScen,t-1,NStep] 
                    Head_Simulation_lower = Water_levels_Simulation[2,iScen,t-1,NStep] - 460
                end  
            end
        end
    end

    return Head_data(water_volumes_file,water_levels_file,NVolumes,Water_levels_Simulation,Head_Simulation_upper,Head_Simulation_lower,Max_Head_upper,Max_Head_lower)

end


function efficiency_evaluation(HY::HydroData, Head::Head_data)

    @unpack (Head_Simulation_upper, Head_Simulation_lower, Max_Head_upper, Max_Head_lower) = Head
#Devo mettere su Head_Simulation_upper iMod = 1 a Head_simulation_lower iMod = 2?
    S1 = 0
    for iMod = 1:HY.NMod
        if Head_Simulation_upper == Max_Head_upper 
            S1 = HY.Eff[iMod,1] 
        elseif Head_Simulation_upper != Max_Head_upper
            eta = HY.Eff[iMod,1] / (Max_Head_upper * 9810)
            S1 = eta * 9810 * Head_Simulation_upper
        end

        if Head_Simulation_lower == Max_Head_lower
            S1 = HY.Eff[iMod,1]
        elseif Head_Simulation_lower != Max_Head_lower    
            eta = HY.Eff[iMod,1] / (Max_Head_lower * 9810)
            S1 = eta * 9810 * Head_Simulation_lower
        end 
    end
    
    return S1   

end 
