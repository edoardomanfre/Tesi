
#---------------------------------------------------------------------------------------------
# Description: Simulate operation for sampled scenarios of stochastic variables
#              Simulation results used to verify strategy obtained in SDP
#              Use water values generated by the SDP algorithm
#
# Developers: Linn Emelie Schäffer
#
# Assumptions: 
#  -
#---------------------------------------------------------------------------------------------

function update_future_value_constraint_sim(SP, AlphaTable, NSeg, t, iState, envState)

  if envState
    iState = iState + NStates
  end

  if HY.NMod == 2
    for iSegL = 1:NSeg[2]                                  # iSegL = 1:NSeg[2]
      for iSegU = 1:NSeg[1]                                # iSegU = 1:NSeg[1]
        JuMP.set_normalized_coefficient(
          SP.AlphaCon,
          SP.gamma[iSegU, iSegL],
          -AlphaTable[t+1, iState, (NSeg[1]*(iSegL-1)+iSegU)],       #NSeg[1]
        )
      end
    end
  elseif HY.NMod == 1
    for iSeg = 1:NSeg[1]                                           #NSeg[1]
      JuMP.set_normalized_coefficient(
        SP.AlphaCon,
        SP.gamma[iSeg],
        -AlphaTable[t+1, iState, iSeg],
      )
    end
  else
    error("Number of modules not supported.")
  end
  return SP
end


function sim(                                                                                                   # Ora conosco per ogni settimana i valori di inflow e prezzo (calcolati con il modello di Markov) - risolvo il problema come "DETERMINISTICO"
  InputParameters::InputParam,
  SolverParameters::SolverParam,
  ValueTableSDP::FutureValueSDP,
  SimScen::SimScenData,
  runMode,
)

  @unpack ResSeg, WVTable, AlphaTable = ValueTableSDP
  @unpack (scenarios, scenStates) = SimScen
  @unpack NStep, NStage, NSimScen, StepFranc, NHoursStep ,Big , LimitPump= InputParameters
  @unpack envConst, solveMIP, ramping_constraints = runMode


  println("Simulating, ", NSimScen, " scenarios...")

  Eprofit = zeros(NStage)
  
  pumping_costs_timestep=zeros(HY.NMod,NSimScen,NStage,NStep)                                                 # Cost for pumping at each time step
  weekly_pumping_costs=zeros(HY.NMod,NSimScen,NStage)                                                         # Cost of pumping each week
  annual_cost_each_reservoir_pump =zeros(HY.NMod,NSimScen)
  annual_total_cost_pump =zeros(NSimScen)
  turbine_profit_timestep = zeros(HY.NMod,NSimScen,NStage,NStep)                                                      # NET profit = turbine-pump
  weekly_turbine_profit = zeros(HY.NMod,NSimScen,NStage)
  annual_profit_each_reservoir_turbine = zeros(HY.NMod,NSimScen)
  annual_total_profit_turbine = zeros(NSimScen)
  
  Reservoir = zeros(HY.NMod, NSimScen, NStage, NStep)
  Reservoir_round =zeros(HY.NMod,NSimScen,NStage,NStep)
  Spillage = zeros(HY.NMod, NSimScen, NStage, NStep)
  Production = zeros(HY.NMod, NSimScen, NStage, NStep)                                                        # Produzione LORDA (senza considerare costi di pompaggio)
  Q_slack = zeros(HY.NMod, NSimScen, NStage, NStep)
  Min_slack =zeros(HY.NMod, NSimScen, NStage, NStep)
  Res_slack_pos =zeros(HY.NMod,NSimScen,NStage,NStep)
  Res_slack_neg = zeros(HY.NMod,NSimScen,NStage,NStep)

  totDischarge = zeros(HY.NMod, NSimScen, NStage, NStep)                                                      # Total amount of water discharged by turbines
  totPumped=zeros(NSimScen,NStage,NStep)                                                                      # Amount of water pumped from lower to upper
  
  resInit = zeros(HY.NMod, NSimScen, NStage)
  inflow = zeros(HY.NMod, NSimScen, NStage,NStep)
  price = zeros(HY.NMod, NSimScen, NStage, NStep)
  obj = zeros(NSimScen,NStage)
  alpha=zeros(NSimScen,NStage)
  disSeg = []                                                                                                 # inizializzo un vettore nullo disSeg che poi andro' a riempire
                                                                                                    

  disSegPump = zeros(NSimScen,NStage,NStep,HY.NDSegPump)                                                      # Ho una pompa sola
  Pumping = zeros(HY.NMod,NSimScen,NStage,NStep)                                                              # Potenza richiesta per pompaggio
 # Net_production=zeros(HY.NMod,NSimScen,NStage,NStep)                                                         # Produzione netta

  By_pass=zeros(HY.NMod,NSimScen,NStage,NStep)                                                                # By pass variable for minimum environmental flow

  if HY.NMod == 1
    gamma = zeros(NSimScen, NStage, NSeg[1])       #NSeg[1]                                                              # genero una matrice (100x52x5) per solo 1 reservoir dei valori di gamma per la cobinazione convessa
  elseif HY.NMod == 2
    gamma = zeros(NSimScen, NStage, NSeg[1], NSeg[2])    #NSeg[1], NSeg[2]                                                           # matrice nulla 100x52x5x5 quando ho due reservoir
  end
  for iMod = 1:HY.NMod
    append!(disSeg, [zeros(NSimScen, NStage, NStep, HY.NDSeg[iMod])])                                         # aggiungo al vettore disSeg , due matrici nulle - una per ogni reservoir, con i dati dei segment
  end

  MIP_counter = 0
  nProblems = 0
  for iScen = 1:NSimScen                                                                                      # Comincio a calcolare i valori per i 100 scenari , cominciando da iScen=1
    earlyActive_maxDischarge = false
    add_dischargeLimitPump = false
    SP = BuildProblem(InputParameters, HY, SolverParameters)                                                  # Function to build model in "stageprob"
    print("Scen:", iScen)
    for t = 1:NStage                                                                                          # Calcolo per ogni settimana  
     # println("t:", t)
      Price = scenarios[iScen][t, 2] .* PriceScale[t,1:NStep]                                                   # Prezzo in quei N periodi (di TOTh) per lo scenario iScen, della settimana t
                                                                                          
      for iMod = 1:HY.NMod  

        reservoir = 0
        for iStep = 1:NStep                                                                                   # per ogni step nella settimana (1:3) - aggiorno la funzione obiettivo con i relativi coefficienti
          
          set_objective_coefficient(
            SP.model,                                                                                         # SP e' il modello
            SP.prod[iMod, iStep],                                                                             # davanti alla variabile prod[iMod, iStep]= produzione(MW) nel bacino iMod allo step iStep(1:3)
            NHoursStep * Price[iStep],                                                                        # variabile che devo aggiungere (fattore_conversione*prezzo[iStep])
          )
          set_objective_coefficient(
            SP.model,                                                                                         # Stessa cosa per la pompa: aggiorno la vraiabile prezzo
            SP.pump[iMod, iStep],                                                                             
            -NHoursStep * Price[iStep],                                                                       # variabile che devo aggiungere (fattore_conversione*prezzo[iStep])
          )

          set_objective_coefficient(
            SP.model,                                                                                         # Stessa cosa per la pompa: aggiorno la vraiabile prezzo
            SP.spill[iMod, iStep],                                                                             
            -Big,                                                                       # variabile che devo aggiungere (fattore_conversione*prezzo[iStep])
          )
        
          if iStep > 1                                                                                        # Se siamo agli step 2 e 3
            JuMP.set_normalized_rhs(
              SP.resbalStep[iMod, iStep],                                                                     # Per reservoir balance constraint in "stageprob" linea 78
              StepFranc[t, iStep] .* scenarios[iScen][t, 1] * HY.Scale[iMod],                                 # StepFranc*inflow(allo scenario iScen,settimana t) * scala(n.bacino)
            )
          end
          #StepFranc[t,1:NStep]

          for n=1:(HY.N_min_flows[iMod]-1)                                                                    # Cambio il valore di qMin: per determinate settimane ho valori diversi da 0
            if t>=HY.Activation_weeks[iMod,n] && t<HY.Activation_weeks[iMod,n+1]
                HY.qMin[iMod]= HY.Min_flows[iMod,n]
                JuMP.set_normalized_rhs(SP.q_min[iMod, iStep], HY.qMin[iMod])
            elseif t>=HY.Activation_weeks[iMod,n+1]
                HY.qMin[iMod]= HY.Min_flows[iMod,n+1]
                JuMP.set_normalized_rhs(SP.q_min[iMod, iStep], HY.qMin[iMod])
            end
          end

          if iMod==1 && ramping_constraints  &&  iStep>1                                      #iMod==1 && 
            SP= intra_volume_changes(SP,iMod,iScen,t,iStep,HY,Reservoir,NStep)
          end
          
        end                                                                                              # Finisco l'update per tutti gli STEP

        if iScen == 1                                                                                         # Se siamo allo scenario 1
          if t == 1                                                                                           # alla settimana t=1  
            JuMP.set_normalized_rhs(
              SP.resbalInit[iMod],
              HY.ResInit0[iMod] + StepFranc[t,1] .* scenarios[iScen][t, 1] * HY.Scale[iMod],                  # Aggiorno in "stageprob" contraint resbalInit (linea 66 - valore iniziale del Reservoir considerando Inflow e scala)
            ) #StepFranc
          else                                                                                                # Per le settimane successive t>1
            JuMP.set_normalized_rhs(
              SP.resbalInit[iMod],
              Reservoir[iMod, iScen, t-1, end] + StepFranc[t,1] .* scenarios[iScen][t, 1] * HY.Scale[iMod],
            ) 
          end
        else 
          if t == 1                                                                                           # Per gli scenari successivi , se la settimana e' la prima e iStep=1
            JuMP.set_normalized_rhs(
              SP.resbalInit[iMod],
              Reservoir[iMod, iScen-1, end, end] +                                                            # Valore del Reservoir allo scenario precedente, ultimo Step dell'ultima settimana
              StepFranc[t,1] .* scenarios[iScen][t, 1] * HY.Scale[iMod],
            ) 
          else
            JuMP.set_normalized_rhs(
              SP.resbalInit[iMod],
              Reservoir[iMod, iScen, t-1, end] +
              StepFranc[t,1] .* scenarios[iScen][t, 1] * HY.Scale[iMod],
            ) 
          end 
        end                                                                                                  # Per tutti gli scenari e tutte le settimane, aggiorno le variabili
        
        if iMod==1 && ramping_constraints                                                      # iMod ==1 &&
          SP = initial_volume_changes(SP,iMod,iScen,t,HY,Reservoir)
        end
 
      end                                                                                                     # UPDATE FOR ALL RESERVOIRS
     
      if envConst && t >= envDataList[1].firstAct && t < envDataList[1].lastAct                               # se envConst sono attivi e se sono in dati periodi dell'anno (vedi settimane di attivazione limiti)
        EnvState = earlyActive_maxDischarge                                                                   # attivo "early_max_discharge"
      else
        EnvState = false                                                                                      # altrimenti non attivo
      end


      if envConst                                                                                             # Se vincoli attivi, attivo la funzione nel codice "activateMaxDiscahrgeConstraint"  
        for envData in envDataList
          SP, earlyActive_maxDischarge, add_dischargeLimitPump = activate_EnvConstraint_sim(                                          # Attivo la funzione "activate_EnvConstraint_sim" che si trova alla linea 48 in "activateMaxDischargeConstraint"
            SP,
            t,
            iScen,
            scenarios,
            HY,
            Reservoir,
            earlyActive_maxDischarge,
            envData,
            NStep,
            add_dischargeLimitPump,
          )
        end
      end

      # Pump limit constraint
      if HY.Station_with_pump==1 && !add_dischargeLimitPump    # if is false, there are no restric.pumping due to res constraints
        SP,reservoir = DeactivationPump_sim(SP,iScen,t,HY,Reservoir,LimitPump,NStep)
      elseif HY.Station_with_pump==1 && add_dischargeLimitPump # true - add the constraint
        SP = add_disLimitPump(SP,NStep)
      end
      #print("Reservoir previous stage $reservoir - ")
      #println("Constraint:", normalized_rhs(SP.maxReleasePump[1]))

      SP = update_future_value_constraint_sim(                                                          
        SP,
        AlphaTable,
        NSeg,
        t,
        scenStates[iScen][t],
        EnvState,
      )

      notConvex = isNotConvex(WVTable[t, scenStates[iScen][t], :, :])                                       # Controlla la WVTable perche' derivata di FV
      if notConvex                                            
        if solveMIP                                                                                        
          if HY.NMod == 2                                                                                   
            SOS2_test_upper = @constraint(SP.model,SP.beta_upper[:] in MOI.SOS2(collect(1:NSeg[1])))
            SOS2_test_lower = @constraint(SP.model,SP.beta_lower[:] in MOI.SOS2(collect(1:NSeg[2])))

          #  SOS2_diag = @constraint(SP.model, SP.χ[:] in MOI.SOS2(collect(1:(2*NSeg-1))))
          elseif HY.NMod == 1                                                                               # Nel caso di un bacino
            SOS2_test = @constraint(
              SP.model,
              SP.gamma[:] in MOI.SOS2(collect(1:NSeg[1]))
            )
          end
        end
        MIP_counter += 1
      end

      @timeit to "Solving optimisation" optimize!(SP.model)                                                 # Finalmente faccio girare il modello per trovare valore ottimo
      nProblems += 1
      if termination_status(SP.model) != MOI.OPTIMAL
        println("NOT OPTIMAL: ", termination_status(SP.model))                                              # Messaggio se non ho trovato OTTIMO
      end

      @timeit to "Collecting results" begin                                                                 # Raccolgo i risultati                                                      

        obj[iScen,t] = JuMP.objective_value(SP.model)                                                         # Per ogni scenario , calcolo la funzione obiettivo alpha
        alpha[iScen,t] = JuMP.value(SP.alpha)

        for iMod = 1:HY.NMod                                                                                # Per ogni reservoir
          price[iMod, iScen, t, :] = Price                                                                  # Per ogni modulo. scenario, settimana e step (da 1 a NStep) aggiorno vettore prezzo
          
          for iStep = 1:NStep                                                                               # Per ogni step della settimana , calcolo i seguenti valori:
            Reservoir[iMod, iScen, t, iStep] = JuMP.value(SP.res[iMod, iStep])
            Spillage[iMod, iScen, t, iStep] = JuMP.value(SP.spill[iMod, iStep])
            Production[iMod, iScen, t, iStep] = JuMP.value(SP.prod[iMod, iStep])
            Q_slack[iMod, iScen, t, iStep] = JuMP.value(SP.q_slack[iMod, iStep])
            Min_slack[iMod,iScen,t,iStep] = JuMP.value(SP.min_slack[iMod,iStep])
            Res_slack_pos[iMod,iScen,t,iStep] = JuMP.value(SP.res_slack_pos[iMod,iStep])
            Res_slack_neg[iMod,iScen,t,iStep] = JuMP.value(SP.res_slack_neg[iMod,iStep])

            for iSeg = 1:HY.NDSeg[iMod]
              disSeg[iMod][iScen, t, iStep, iSeg] = JuMP.value(SP.disSeg[iMod, iSeg, iStep])
            end
            totDischarge[iMod, iScen, t, iStep] = sum(disSeg[iMod][iScen, t, iStep, :])

            for tSeg=1:HY.NDSegPump
              disSegPump[iScen, t , iStep, tSeg] = JuMP.value(SP.disSegPump[tSeg,iStep])
            end
            totPumped[iScen,t,iStep]=sum(disSegPump[iScen,t,iStep,:])

            By_pass[iMod,iScen,t,iStep] =JuMP.value(SP.by_pass[iMod,iStep])                               # Variabile By_pass che tiene conto del deflusso minimo ambientale

            Pumping[iMod,iScen,t,iStep]= JuMP.value(SP.pump[iMod,iStep])
           # Net_production[iMod,iScen,t,iStep]=Production[iMod,iScen,t,iStep]-Pumping[iMod,iScen,t,iStep]

            pumping_costs_timestep[iMod,iScen,t,iStep]=price[iMod,iScen,t,iStep]*Pumping[iMod,iScen,t,iStep]*NHoursStep
            weekly_pumping_costs[iMod,iScen,t]=weekly_pumping_costs[iMod,iScen,t]+pumping_costs_timestep[iMod,iScen,t,iStep]
           
            turbine_profit_timestep[iMod,iScen,t,iStep] = price[iMod,iScen,t,iStep]*Production[iMod,iScen,t,iStep]*NHoursStep                     #  PROFITTO NETTO A OGNI TIME STEP
            weekly_turbine_profit[iMod,iScen,t] = weekly_turbine_profit[iMod,iScen,t]+turbine_profit_timestep[iMod,iScen,t,iStep]

            inflow[iMod,iScen,t,iStep]= StepFranc[t,iStep] .* scenarios[iScen][t, 1] * HY.Scale[iMod]
            
            Reservoir_round[iMod,iScen,t,iStep] = round(Reservoir[iMod,iScen,t,iStep],digits=2)

          end
        end

        for nU = 1:NSeg[1]
          if HY.NMod == 1
            gamma[iScen, t, nU] = JuMP.value(SP.gamma[nU])
          elseif HY.NMod == 2
            for nL = 1:NSeg[2]                 #nL=1:NSeg
              gamma[iScen, t, nU, nL] = JuMP.value(SP.gamma[nU, nL])
            end
          end
        end
        
      end #timer                                                                                          # Fine del problema di ottimizzazione
    end                                                                                                   # End of the stage
  end                                                                                                     # End of Scenarios

  for iMod = 1:HY.NMod
    for iScen = 1:NSimScen
      for t =1:NStage

      # PRODUCTION FROM TURBINE
      annual_profit_each_reservoir_turbine[iMod,iScen] = annual_profit_each_reservoir_turbine[iMod,iScen]+weekly_turbine_profit[iMod,iScen,t]
      annual_total_profit_turbine[iScen]= annual_profit_each_reservoir_turbine[1,iScen]+annual_profit_each_reservoir_turbine[2,iScen]
      
      # POWER AND COST FOR PUMP
      annual_cost_each_reservoir_pump[iMod,iScen] = annual_cost_each_reservoir_pump[iMod,iScen]+weekly_pumping_costs[iMod,iScen,t]
      annual_total_cost_pump[iScen]= annual_cost_each_reservoir_pump[1,iScen] +annual_cost_each_reservoir_pump[2,iScen]
   
    end    
    end
  end

  println("Sim finished")
  println(MIP_counter, " of ", nProblems, " number of solved problems solved as MIP")

  return Results(
    #Eprofit,
    pumping_costs_timestep,
    weekly_pumping_costs,
    annual_cost_each_reservoir_pump,
    annual_total_cost_pump,
    turbine_profit_timestep,
    weekly_turbine_profit,
    annual_profit_each_reservoir_turbine,
    annual_total_profit_turbine,
    Reservoir,
    Reservoir_round,
    Spillage,
    Production,
    Q_slack,
    Min_slack,
    Res_slack_pos,
    Res_slack_neg,
    disSeg,
    totDischarge,
    totPumped,
    resInit,
    inflow,
    price,
    obj,
    alpha,
    gamma,
    disSegPump,
    Pumping,
    #Net_production,
    By_pass,
  )
end
