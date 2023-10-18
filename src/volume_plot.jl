using Statistics
using Plots
pyplot()
using DataFrames
using XLSX
using DelimitedFiles

function savePlots(InputParameters::InputParam, Result::Results)

    @unpack NSeg, NStage, NStates, MaxIt, conv, StepFranc, NHoursStep, NStep, LimitPump = InputParameters
    @unpack Salto, Coeffciente = Result

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
    concatenation_head = zeros(HY.NMod, NSimScen, NStage)
    Coeffciente = zeros(HY.NMod, NSimScen, NStage)
    
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
                concatenation_head[iMod, iScen, start:finish] = Result.Salto[iMod, iScen, :]
                concatenation_coeff[iMod, iScen, start:finish] = Result.Coefficiente[iMod, iScen, :]
            end
        end
    end

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
        Head = DataFrame()
        Coeff = DataFrame()

        for iStep = NStage * NStep
            for iMod = 1:HY.NMod
                Prod_Turbines[!, "Reservoir_$iMod"] = concatenation_production_turbines[iMod, i, :]
                Prod_Pump[!, "Reservoir_$iMod"] = concatenation_production_pump[iMod, i, :]
                Prices[!, "Reservoir_$iMod"] = concatenation_price[iMod, i, :]
                Inflow[!, "Reservoir_$iMod"] = concatenation_inflows[iMod, i, :]
                Reservoir_volume[!, "Reservoir_$iMod"] = concatenation_reservoir[iMod, i, :]
                Reservoir_level[!, "Reservoir_$iMod"] = concatenation_waterLevel[iMod, i, :]
                Variations_water[!, "Reservoir_$iMod"] = concatenation_waterLevel_variations[iMod, i, :]
                Head[!, "Salto_$iMod"] = concatenation_head[iMod, i, :]
                Coeff[!, "Salto_$iMod"] = concatenation_coeff[iMod, i, :]
            end
        end

        XLSX.writetable("Scenario $i.xlsx", overwrite = true,
            Prod_Turbines_MWh = (collect(DataFrames.eachcol(Prod_Turbines)), DataFrames.names(Prod_Turbines)),
            Prod_Pump_MWh = (collect(DataFrames.eachcol(Prod_Pump)), DataFrames.names(Prod_Pump)),
            Prices_€ = (collect(DataFrames.eachcol(Prices)), DataFrames.names(Prices)),
            Reservoir_volume = (collect(DataFrames.eachcol(Reservoir_volume)), DataFrames.names(Reservoir_volume)),
            Reservoir_level = (collect(DataFrames.eachcol(Reservoir_level)), DataFrames.names(Reservoir_level)),
            Variations_water = (collect(DataFrames.eachcol(Variations_water)), DataFrames.names(Variations_water)),
            Inflow = (collect(DataFrames.eachcol(Inflow)), DataFrames.names(Inflow)),
            Head = (collect(DataFrames.eachcol(Head)), DataFrames.names(Head)),
            Coeff = (collect(DataFrames.eachcol(Coeff)), DataFrames.names(Coeff))
        )
    end
end
