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
    max_head=zeros(Float64,HY.NMod);
    NVolumes=zeros(NMod);
  
    for iMod=1:NMod
        line = readline(f)
        items = split(line, " ")
        NVolumes[iMod] = parse(Int, items[1])
        for n=1:Int(NVolumes[iMod])                                   
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
        for n=1:Int(NVolumes[iMod])                                  
        water_levels_file[iMod,n]=parse(Float64,items[n])            
        end
    end
    water_levels_file;

    for iLine = 1:2
        line = readline(f)
    end

    for iMod=1:NMod
        line = readline(f)                              
        max_head[iMod]=parse(Float64,1)            
    end
    max_head; 

    #EVALUATE THE WATER LEVELS, GIVEN THE WATER VOLUMES IN THE RESERVOIR
    Level = zeros(HY.NMod)
    Head_upper = 0
    Head_lower = 0
   
    # CALCULATES THE WATER LEVELS (m a.s.l) AND THE HEAD FROM THE VOLUME RESULTS
    
    for iMod=1:HY.NMod

        for n=1:Int(NVolumes[iMod])-1
            
            if iScen == 1
                if t == 1
                    if HY.ResInit0[iMod] == water_volumes_file[iMod,n]
                        Level[iMod] = water_levels_file[iMod,n]
                    elseif HY.ResInit0[iMod] > water_volumes_file[iMod,n] && HY.ResInit0[iMod] < water_volumes_file[iMod,n+1]
                        Level[iMod] =(water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(HY.ResInit0[iMod]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                    else 
                        Level[iMod] = water_volumes_file[iMod,Int(NVolumes[iMod])]
                    end
                else        
                    if Reservoir[iMod,iScen,t-1,NStep] == water_volumes_file[iMod,n]
                        Level[iMod] = water_levels_file[iMod,n] 
                    elseif Reservoir[iMod,iScen,t-1,NStep]> water_volumes_file[iMod,n] && Reservoir[iMod,iScen,t-1,NStep]< water_volumes_file[iMod,n+1]
                        Level[iMod] = (water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(Reservoir[iMod,iScen,t-1,NStep]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                    else
                        Level[iMod] = water_volumes_file[iMod,Int(NVolumes[iMod])]
                    end
                end
            else
                if t == 1
                    if Reservoir[iMod,iScen-1,end,NStep] == water_volumes_file[iMod,n]
                        Level[iMod] = water_levels_file[iMod,n]
                    elseif Reservoir[iMod,iScen-1,end,NStep]> water_volumes_file[iMod,n] && Reservoir[iMod,iScen-1,end,NStep]< water_volumes_file[iMod,n+1]
                        Level[iMod] = (water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(Reservoir[iMod,iScen-1,end,NStep]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                    else 
                        Level[iMod] = water_volumes_file[iMod,Int(NVolumes[iMod])] 
                    end
                else
                    if Reservoir[iMod,iScen,t-1,NStep] == water_volumes_file[iMod,n]
                        Level[iMod] = water_levels_file[iMod,n]
                    elseif Reservoir[iMod,iScen,t-1,NStep]> water_volumes_file[iMod,n] && Reservoir[iMod,iScen,t-1,NStep]< water_volumes_file[iMod,n+1]
                        Level[iMod] = (water_levels_file[iMod,n+1]-water_levels_file[iMod,n])/(water_volumes_file[iMod,n+1]-water_volumes_file[iMod,n])*(Reservoir[iMod,iScen,t-1,NStep]-water_volumes_file[iMod,n])+water_levels_file[iMod,n]
                    else
                        Level[iMod] = water_volumes_file[iMod,Int(NVolumes[iMod])]  
                    end
                end
            end
    
        end
    
    end

    Head_upper = Level[1] - Level[2]
    Head_lower = Level[2] - 460

    return Head_data(water_volumes_file,water_levels_file,NVolumes,Head_upper,Head_lower,max_head)

end


function efficiency_evaluation(HY::HydroData, Head::Head_data)

    @unpack (Head_upper,Head_lower,max_head) = Head

    S1_upper = 0
    S1_lower = 0

    if Head_upper == max_head[1] 
        S1_upper = HY.Eff[iMod,1] 
    else
        eta = HY.Eff[iMod,1] / (max_head[1] * 9810)
        S1_upper = eta * 9810 * Head_upper
    end

    if Head_lower == max_head[2] 
        S1_lower = HY.Eff[iMod,1]
    else 
        eta = HY.Eff[iMod,1] / (max_head[2] * 9810)
        S1_lower = eta * 9810 * Head_lower
    end 

    
    return S1_upper, S1_lower   

end 
