using Statistics
using Plots
pyplot()
using DataFrames
using XLSX
using DelimitedFiles

function savePlots(InputParameters::InputParam, ResultsSim::Results)

    @unpack NSeg, NStage, NStates, MaxIt, conv, StepFranc, NHoursStep, NStep, LimitPump = InputParameters
#    @unpack Salto, Coefficiente = ResultsSim

    scenarios = collect(1:100)
    println("Plots for scenarios $scenarios")

    NStep = InputParameters.NStep
    concatenation_production_turbines = zeros(HY.NMod, NSimScen, NStep * NStage)
    concatenation_production_pump = zeros(HY.NMod, NSimScen, NStep * NStage)
    concatenation_inflows = zeros(HY.NMod, NSimScen, NStep * NStage)
    concatenation_reservoir = zeros(HY.NMod, NSimScen, NStep * NStage)
    concatenation_price = zeros(HY.NMod, NSimScen, NStep * NStage)
    concatenation_waterLevel_variations = zeros(HY.NMod, NSimScen, NStep * NStage)
    concatenation_waterLevel = zeros(HY.NMod, NSimScen, NStep * NStage)
    concatenation_by_pass = zeros(HY.NMod, NSimScen, NStep * NStage)
    concatenation_u_pump = zeros(HY.NMod, NSimScen, NStep * NStage)
    concatenation_u_turb = zeros(HY.NMod, NSimScen, NStep * NStage)
    concatenation_spillage = zeros(HY.NMod, NSimScen, NStep * NStage)
    concatenation_dischrge_turbine = zeros(HY.NMod, NSimScen, NStep * NStage)
    concatenation_discharge_pump = zeros(HY.NMod, NSimScen, NStep * NStage)
#    concatenation_head = zeros(HY.NMod, NSimScen, NStage)
#    concatenation_coeff = zeros(HY.NMod, NSimScen, NStage)
    
    for iMod = 1:HY.NMod
        for iScen = 1:NSimScen
            for iStage = 1:NStage
                start_idx = (NStep * (iStage - 1)) + 1
                end_idx = NStep * iStage
                concatenation_production_turbines[iMod, iScen, start_idx:end_idx] = ResultsSim.Production[iMod, iScen, iStage, :] * InputParameters.NHoursStep
                concatenation_production_pump[iMod, iScen, start_idx:end_idx] = ResultsSim.Pumping[iMod, iScen, iStage, :] * InputParameters.NHoursStep
                concatenation_inflows[iMod, iScen, start_idx:end_idx] = ResultsSim.inflow[iMod, iScen, iStage, :]
                concatenation_reservoir[iMod, iScen, start_idx:end_idx] = ResultsSim.Reservoir[iMod, iScen, iStage, :]
                concatenation_price[iMod, iScen, start_idx:end_idx] = ResultsSim.price[iMod, iScen, iStage, :]
                concatenation_waterLevel_variations[iMod, iScen, start_idx:end_idx] = Results_Water_levels.water_level_variations[iMod, iScen, iStage, :]
                concatenation_waterLevel[iMod, iScen, start_idx:end_idx] = Results_Water_levels.Water_levels_Simulation[iMod, iScen, iStage, :]
                concatenation_by_pass[iMod, iScen, start_idx:end_idx] = ResultsSim.By_pass[iMod, iScen, iStage, :]
                concatenation_u_pump[iMod, iScen, start_idx:end_idx] = ResultsSim.u_pump[iScen, iStage, :]
                concatenation_u_turb[iMod, iScen, start_idx:end_idx] = ResultsSim.u_turb[iMod, iScen, iStage, :]
                concatenation_spillage[iMod, iScen, start_idx:end_idx] = ResultsSim.Spillage[iMod, iScen, iStage, :]
                concatenation_dischrge_turbine[iMod, iScen, start_idx:end_idx] = ResultsSim.totDischarge[iMod, iScen, iStage, :]
                concatenation_discharge_pump[iMod, iScen, start_idx:end_idx] = ResultsSim.totPumped[iMod, iScen, iStage, :]
            end
        end
    end

#=    for iMod = 1:HY.NMod
        for iScen = 1:NSimScen
            for iStage = 1:NStage
                start = iStage
                finish = iStage
                concatenation_head[iMod, iScen, start:finish] .= ResultsSim.Salto[iMod, iScen, iStage]
                concatenation_coeff[iMod, iScen, start:finish] .= ResultsSim.Coefficiente[iMod, iScen, iStage]
            end
        end
    end=#


    folder = "Scenarios"
    mkdir(folder)
    cd(folder)

    for i in scenarios 
        Prod_Turbines = DataFrame()
        Prod_Pump = DataFrame()
        Prices = DataFrame()
        Inflow = DataFrame()
        Reservoir_volume = DataFrame()
        Reservoir_level = DataFrame()
        Variations_water = DataFrame()
        Bypass = DataFrame()
        U_pump = DataFrame()
        U_turb = DataFrame()
        Spillage = DataFrame()
        Discharge_turbine = DataFrame()
        Discharge_pump = DataFrame()
#        Head = DataFrame()
#        Coeff = DataFrame()

        for iStep = NStage * NStep
            for iMod = 1:HY.NMod
                Prod_Turbines[!, "Reservoir_$iMod"] = concatenation_production_turbines[iMod, i, :]
                Prod_Pump[!, "Reservoir_$iMod"] = concatenation_production_pump[iMod, i, :]
                Prices[!, "Reservoir_$iMod"] = concatenation_price[iMod, i, :]
                Inflow[!, "Reservoir_$iMod"] = concatenation_inflows[iMod, i, :]
                Reservoir_volume[!, "Reservoir_$iMod"] = concatenation_reservoir[iMod, i, :]
                Reservoir_level[!, "Reservoir_$iMod"] = concatenation_waterLevel[iMod, i, :]
                Variations_water[!, "Reservoir_$iMod"] = concatenation_waterLevel_variations[iMod, i, :]
                Bypass[!, "Reservoir_$iMod"] = concatenation_by_pass[iMod, i, :]
                U_pump[!, "Reservoir_$iMod"] = concatenation_u_pump[iMod, i, :]
                U_turb[!, "Reservoir_$iMod"] = concatenation_u_turb[iMod, i, :]
                Spillage[!, "Reservoir_$iMod"] = concatenation_spillage[iMod, i, :]
                Discharge_turbine[!, "Reservoir_$iMod"] = concatenation_dischrge_turbine[iMod, i, :]
                Discharge_pump[!, "Reservoir_$iMod"] = concatenation_discharge_pump[iMod, i, :]
#                Head[!, "Salto_$iMod"] = concatenation_head[iMod, i, :]
#                Coeff[!, "Salto_$iMod"] = concatenation_coeff[iMod, i, :]
            end
        end

        XLSX.writetable("Scenario $i.xlsx", overwrite = true,
            Prod_Turbines_MWh = (collect(DataFrames.eachcol(Prod_Turbines)), DataFrames.names(Prod_Turbines)),
            Prod_Pump_MWh = (collect(DataFrames.eachcol(Prod_Pump)), DataFrames.names(Prod_Pump)),
            Prices_€ = (collect(DataFrames.eachcol(Prices)), DataFrames.names(Prices)),
            Reservoir_volume_Mm3 = (collect(DataFrames.eachcol(Reservoir_volume)), DataFrames.names(Reservoir_volume)),
            Reservoir_level_Mm3 = (collect(DataFrames.eachcol(Reservoir_level)), DataFrames.names(Reservoir_level)),
            Variations_water = (collect(DataFrames.eachcol(Variations_water)), DataFrames.names(Variations_water)),
            Inflow_Mm3 = (collect(DataFrames.eachcol(Inflow)), DataFrames.names(Inflow)),
            Bypass_upper = (collect(DataFrames.eachcol(Bypass_upper)), DataFrames.names(Bypass_upper)),
            Bypass_lower = (collect(DataFrames.eachcol(Bypass_lower)), DataFrames.names(Bypass_lower)),
            U_pump = (collect(DataFrames.eachcol(U_pump)), DataFrames.names(U_pump)),
            U_turb = (collect(DataFrames.eachcol(U_turb)), DataFrames.names(U_turb)),
            Spillage = (collect(DataFrames.eachcol(Spillage)), DataFrames.names(Spillage)),
            Discharge_turbine_m3s = (collect(DataFrames.eachcol(Discharge_turbine)), DataFrames.names(Discharge_turbine)),
            Discharge_pump_m3s = (collect(DataFrames.eachcol(Discharge_pump)), DataFrames.names(Discharge_pump))
#            Head = (collect(DataFrames.eachcol(Head)), DataFrames.names(Head)),
#            Coeff = (collect(DataFrames.eachcol(Coeff)), DataFrames.names(Coeff))
        )
    end
end
