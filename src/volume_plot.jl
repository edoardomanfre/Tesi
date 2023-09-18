using Statistics
using Plots
pyplot()
using DataFrames
using XLSX
using DelimitedFiles

function savePlots(InputParameters::InputParam)

    scenarios = [1 100];
    scenario_max_inflow = 1;
    scenario_min_inflow = 100;
    println("Plots for scenarios $scenario_max_inflow, and $scenario_min_inflow")

    NStep = InputParameters.NStep;
    concatenation_waterLevel = zeros(HY.NMod,NSimScen,NStep*NStage);

    for iMod = 1:HY.NMod
        for iScen = 1:NSimScen
            for iStage = 1:NStage
                concatenation_waterLevel[iMod,iScen,(NStep*(iStage-1))+1:1:(NStep*iStage)] = Results_Water_levels.Water_levels_Simulation[iMod,iScen,iStage,:]
            end
        end
    end

    for i in scenarios 
        Reservoir_level = DataFrame();

        for iStep = NStage*NStep
            for iMod = 1:HY.NMod
                Reservoir_level[!,"Module_$iMod"]  = concatenation_waterLevel[iMod,i,:]
            end
        end

        XLSX.writetable("Scenario $i.xlsx",overwrite=true,
        Reservoir_level = (collect(DataFrames.eachcol(Reservoir_level)),DataFrames.names(Reservoir_level))

    )

end

    x=1:1:Nstep*NStage;

    # Water level
    w = plot(x,concatenation_waterLevel[1,scenario_max_inflow,:],size(1200,700),xlabel="N steps",ylabel="Reservoir_level [Mm3]", title ="Volume level upper reservoir")
    plot!(w,x,concatenation_waterLevel[2,scenario_max_inflow,:], label = "Lower Reservoir")

    savefig(w,"WaterLevel_$scenario_min_inflow.png")  
    
    return("Saved_plots")

end

