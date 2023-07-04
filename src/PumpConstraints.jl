# DEPENDENCE ON DOWNSTREAM WATER LEVEL

function DeactivationPump_sim(SP,iScen,t,HY,Reservoir,limit,NStep)
 
    reservoir = 0

    if t==1 
        if iScen==1
            if HY.ResInit0[2] <= limit  #52
                for iStep=1:NStep
                    #JuMP.set_normalized_rhs(SP.pumpdischarge[tSeg,iStep],0)     
                    JuMP.set_normalized_rhs(SP.maxReleasePump[iStep],0)
                    reservoir = HY.ResInit0[2]
                    #SP = add_disLimitPump(SP,NStep)
                end
            elseif HY.ResInit0[2] > limit
                for iStep=1:NStep
                    #JuMP.set_normalized_rhs(SP.pumpdischarge[tSeg,iStep],HY.DisMaxSegPump[tSeg]) 
                    JuMP.set_normalized_rhs(SP.maxReleasePump[iStep], sum(HY.DisMaxSegPump[tSeg] for tSeg = 1:HY.NDSegPump))
                    #SP= relax_disLimitPump(SP,NStep)
                    reservoir = HY.ResInit0[2]
                end
            end
        else    #iScen>1
            if Reservoir[2,iScen-1,end,end] <= limit
                for iStep=1:NStep
                    #JuMP.set_normalized_rhs(SP.pumpdischarge[tSeg,iStep],0)     
                    JuMP.set_normalized_rhs(SP.maxReleasePump[iStep],0)
                    reservoir = Reservoir[2,iScen-1,end,end]
                    #SP = add_disLimitPump(SP,NStep)
                end
            elseif Reservoir[2,iScen-1,end,end] > limit
                for iStep=1:NStep
                    #JuMP.set_normalized_rhs(SP.pumpdischarge[tSeg,iStep],HY.DisMaxSegPump[tSeg]) 
                    JuMP.set_normalized_rhs(SP.maxReleasePump[iStep], sum(HY.DisMaxSegPump[tSeg] for tSeg = 1:HY.NDSegPump))
                    reservoir = Reservoir[2,iScen-1,end,end]
                    #SP= relax_disLimitPump(SP,NStep)
                end
            end
        end
    else    #if t>1 50 scen4
        if Reservoir[2,iScen,t-1,end] <= limit
           for iStep=1:NStep
                #JuMP.set_normalized_rhs(SP.pumpdischarge[tSeg,iStep],0)
                JuMP.set_normalized_rhs(SP.maxReleasePump[iStep],0)
                reservoir = Reservoir[2,iScen,t-1,end]
                #SP = add_disLimitPump(SP,NStep)
            end
        elseif Reservoir[2,iScen,t-1,end] > limit
            for iStep=1:NStep
               # JuMP.set_normalized_rhs(SP.pumpdischarge[tSeg,iStep],HY.DisMaxSegPump[tSeg])
                JuMP.set_normalized_rhs(SP.maxReleasePump[iStep], sum(HY.DisMaxSegPump[tSeg] for tSeg = 1:HY.NDSegPump))
                reservoir = Reservoir[2,iScen,t-1,end]
                #SP= relax_disLimitPump(SP,NStep)
            end
        end
    end

    return SP,reservoir

end

function DeactivationPump_SDP(SP,HY,ResSeg,limit,nfrom,NStep)         # iMod=2 

        if ResSeg[nfrom][2] <= limit
            for iStep=1:NStep
             #   JuMP.set_normalized_rhs(SP.pumpdischarge[tSeg,iStep],0)
                JuMP.set_normalized_rhs(SP.maxReleasePump[iStep],0)
                #SP = add_disLimitPump(SP,NStep)
            end
        elseif ResSeg[nfrom][2] > limit
            for iStep=1:NStep
               #JuMP.set_normalized_rhs(SP.pumpdischarge[tSeg,iStep],HY.DisMaxSegPump[tSeg])
                JuMP.set_normalized_rhs(SP.maxReleasePump[iStep], sum(HY.DisMaxSegPump[tSeg] for tSeg = 1:HY.NDSegPump))
                #SP= relax_disLimitPump(SP,NStep)
            end
        end

    return SP

end

function add_disLimitPump(SP, NStep)                                    # attivo i vincoli sullo scarico                                                                         
    for iStep = 1:NStep
      set_normalized_rhs(SP.maxReleasePump[iStep], 0)
    end
    return SP
end

function relax_disLimitPump(SP,NStep)                                   # disattivo i vincoli sullo scarico
    for iStep = 1:NStep
      set_normalized_rhs(
        SP.maxReleasePump[iStep],
        sum(HY.DisMaxSegPump[tSeg] for tSeg = 1:HY.NDSegPump),
      )
    end
    return SP
end



# RAMPING CONSTRAINTS - 

function intra_volume_changes(SP,iMod,iScen,t,iStep,HY,Reservoir,NStep)

    Volume_changes= zeros(HY.NMod,4)
    Volume_changes[1,:]=[0.2364 0.4815 0.638 0.7734]                     # 30-50 cm per day    2.3640 4.82 6.3828 7.7347
    Volume_changes[2,:]=[0.132 0.1806 0.2106 0.255]                      # 30-50 cm per day    1.32 1.81 2.11 2.55

    water_volumes_file=zeros(HY.NMod,5)     # range
    water_volumes_file[1,:]= [0.00 78.00 239.00 452.60 684.30]           # 684.1      0.00 78.00 239.00 452.60 684.30
    water_volumes_file[2,:]= [0.00 21.90 52.00 87.10 104.30]             # 104.10     0.00 21.90 52.00 87.10 104.30


    for n=1:size(Volume_changes)[2]
        if t==1
            if HY.ResInit0[iMod]>= water_volumes_file[iMod,n] && HY.ResInit0[iMod]< water_volumes_file[iMod,n+1]
                JuMP.set_normalized_rhs(SP.positive_var[iMod,iStep],Volume_changes[iMod,n])
                JuMP.set_normalized_rhs(SP.negative_var[iMod,iStep],-Volume_changes[iMod,n])
            end
        else #t>1
            if Reservoir[iMod,iScen,t-1,NStep]>= water_volumes_file[iMod,n] && Reservoir[iMod,iScen,t-1,NStep] < water_volumes_file[iMod,n+1]
                JuMP.set_normalized_rhs(SP.positive_var[iMod,iStep],Volume_changes[iMod,n])
                JuMP.set_normalized_rhs(SP.negative_var[iMod,iStep],-Volume_changes[iMod,n])
            end
        end
   end

    return SP
end




function initial_volume_changes(SP,iMod,iScen,t,HY,Reservoir)
   
    Volume_changes= zeros(HY.NMod,4)
    Volume_changes[1,:]=[0.2364 0.4815 0.638 0.7734] 
    Volume_changes[2,:]=[0.132 0.1806 0.2106 0.255]  

    water_volumes_file=zeros(HY.NMod,5)
    water_volumes_file[1,:]= [0.00 78.00 239.00 452.60 684.30]
    water_volumes_file[2,:]= [0.00 21.90 52.00 87.10 104.30] 


    for n=1:size(Volume_changes)[2]         #fino a 4
        if iScen==1
            if t==1
                if HY.ResInit0[iMod]>= water_volumes_file[iMod,n] && HY.ResInit0[iMod] < water_volumes_file[iMod,n+1]
                JuMP.set_normalized_rhs(SP.Initial_volumevar_positive[iMod],HY.ResInit0[iMod]+Volume_changes[iMod,n])
                JuMP.set_normalized_rhs(SP.Initial_volumevar_negative[iMod],HY.ResInit0[iMod]-Volume_changes[iMod,n])
                end
            else # t>1
                if Reservoir[iMod,iScen,t-1,end]>= water_volumes_file[iMod,n] && Reservoir[iMod,iScen,t-1,end] < water_volumes_file[iMod,n+1]
                JuMP.set_normalized_rhs(SP.Initial_volumevar_positive[iMod],Reservoir[iMod,iScen,t-1,end]+Volume_changes[iMod,n] )       
                JuMP.set_normalized_rhs(SP.Initial_volumevar_negative[iMod],Reservoir[iMod,iScen,t-1,end]-Volume_changes[iMod,n] )       
                end
            end
        else            #iScen >1
            if t==1
                if Reservoir[iMod,iScen-1,end,end]>= water_volumes_file[iMod,n] && Reservoir[iMod,iScen-1,end,end] < water_volumes_file[iMod,n+1]
                    JuMP.set_normalized_rhs(SP.Initial_volumevar_positive[iMod],Reservoir[iMod,iScen-1,end,end]+Volume_changes[iMod,n] )       
                    JuMP.set_normalized_rhs(SP.Initial_volumevar_negative[iMod],Reservoir[iMod,iScen-1,end,end]-Volume_changes[iMod,n] )        
                end
            else        #t>1
                if Reservoir[iMod,iScen,t-1,end]>= water_volumes_file[iMod,n] && Reservoir[iMod,iScen,t-1,end] < water_volumes_file[iMod,n+1]
                    JuMP.set_normalized_rhs(SP.Initial_volumevar_positive[iMod],Reservoir[iMod,iScen,t-1,end]+Volume_changes[iMod,n] )          
                    JuMP.set_normalized_rhs(SP.Initial_volumevar_negative[iMod],Reservoir[iMod,iScen,t-1,end]-Volume_changes[iMod,n] )          
                end
            end
        end
    end

    return SP
end


function ramping_constraints_SDP(SP,iMod,t,nfrom,HY,ResSeg,iStep)

    Volume_changes= zeros(HY.NMod,4) #3cm variations
    Volume_changes[1,:]=[0.2364 0.4815 0.638 0.7734]                             # 30-50 cm per day    2.3640 4.82 6.3828 7.7347
    Volume_changes[2,:]=[0.132 0.1806 0.2106 0.255]                                 # 30-50 cm per day    1.32 1.81 2.11 2.55

    water_volumes_file=zeros(HY.NMod,5)
    water_volumes_file[1,:]= [0.00 78.00 239.00 452.60 684.30]                #684.1      0.00 78.00 239.00 452.60 684.30
    water_volumes_file[2,:]= [0.00 21.90 52.00 87.10 104.30]                    #104.10        0.00 21.90 52.00 87.10 104.30


    for n=1:size(Volume_changes)[2]             # iterating from 1 to 4
       
        if iStep==1
            if ResSeg[nfrom][iMod]>= water_volumes_file[iMod,n] && ResSeg[nfrom][iMod] < water_volumes_file[iMod,n+1]
                JuMP.set_normalized_rhs(SP.Initial_volumevar_positive[iMod],ResSeg[nfrom][iMod]+Volume_changes[iMod,n] )       
                JuMP.set_normalized_rhs(SP.Initial_volumevar_negative[iMod],ResSeg[nfrom][iMod]-Volume_changes[iMod,n] )       
            end   
        elseif iStep>1 
            if ResSeg[nfrom][iMod]>= water_volumes_file[iMod,n] && ResSeg[nfrom][iMod] < water_volumes_file[iMod,n+1]
                JuMP.set_normalized_rhs(SP.positive_var[iMod,iStep],Volume_changes[iMod,n])
                JuMP.set_normalized_rhs(SP.negative_var[iMod,iStep],-Volume_changes[iMod,n])
            end
        end

    end
   
    return SP
end