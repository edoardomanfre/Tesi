

# Input data
#-----------------------------------------------

# parameters 
@with_kw struct InputParam{F<:Float64,I<:Int}
  NSeg::Any                                     #Number of segments to divide the resevoir into to define states(5 5)
  NPrice::I                                     #Number of price scenarios (1)
  NStage::I                                     #Number of stages (52)
  NHoursStage::I                                #Number of hours in one stage (24x7=168)
  NHoursStep::I                                 #Number of hours in each time step within a stage (3)
  Big::F                                        #A big number (1E16)
  AlphaMax::F                                   #Bounds for expected future value, initial value (1E16)
  PenSpi::F                                     #Small penalty for spillage (0.001)
  PenQ::F                                       #Large penalty for tanking (1E5)
  NStep::I                                      #Number of steps within each stage (8x7=56)
  MM3Week::F                                    #Conversion factor week: da m3/s a Mm3 in una settimana
  MM3Step::F                                    #Conversion factor time step: da m3/s a Mm3 in uno step (3 ore)
  StepFranc::Any                                #Time Step fraction of week: matrice distribuzione inflow sulla settimana
  NStates::I                                    #Number of inflow scnearios (5)
  MaxIt::I                                      #Max number of iterations
  conv::F                                       #Convergence criterium
  NSamples::I                                   #Number of samples drawn when making scenario lattice (10000 scenari)
  NSimScen::I                                   #Number of scenarios simulated in sim (100 scenari)
  LimitPump::I                                  #Volume limite del bacino per il quale la pompa lavora (52)
end

# solver parameters
@with_kw struct SolverParam{F<:Float64,I<:Int}
  CPX_PARAM_SCRIND::I = 0
  CPX_PARAM_PREIND::I = 0
  CPXPARAM_MIP_Tolerances_MIPGap::F = 1e-10
  CPX_PARAM_TILIM::I = 120
  CPX_PARAM_THREADS ::I = 1
end

@with_kw struct caseData{S<:String}
  DataPath::S
  InputPath::S
  ResultPath::S
  InputCase::S
  PriceYear::S
  PriceVar::S
  CaseName::S
end

# case settings
struct HydroData
  NMod::Any               #Numero bacini
  NUp::Any                #Numero bacini a monte
  Eff::Any                #Efficienza turbina MW/m3/s
  NDSeg::Any        
  DisMaxSeg::Any          #m3/s
  MaxRes::Any             #Mm3/s
  Scale::Any              #1.000, 0.417
  ResInit0::Any           #Mm3
  qMin::Any               #Deflusso minimo vitale
  Station_with_pump::Any
  NDSegPump::Any
  DisMaxSegPump::Any
  EffPump::Any
  Pump_direction::Any
  N_min_flows::Any
  Activation_weeks::Any   #Settimane a cui si riferiscono i vari q_min
  Min_flows::Any          #q_min per le varie Activation weeks(0.0 0.5 0.2 0.0)
end

# run settings
@with_kw mutable struct runModeParam{B<:Bool}

  # Solver settings
  solveMIP::B = false     #If using SOS2

  # SDP settings
  solveSDP::B = true
  DebugSP::B = false      #Option to save results from each time decision problem is solved in SDP
  useWaterValues::B = false # option to start SDP using exist
  #readSDPResults::B = false

  # SIM settings
  simulate::B = true
  parallellSim::B = false

  # Environmental constraint settings 
  envConst::B = true
  #flowDependentqMin::B = false
  extendScenarioLattice::B = false #if using makow model made without early activation to solve SDP algorithm with early activation
  ramping_constraints::B = true

  #runMode default reading of input
  #solvePreviousCase::B = false
  #newCaseRun::B = true

  #runMode self defined reading of input 
  setInputParameters::B = true              #from .in file
  #readInputParameters::B = false           #from previous result files

  hydroSystemFromFile::B = true             #from input file

  #inflowFromFile::B = true                 #from input file
  #inflowFromDataStorage::B = false         #from previous result files

  #priceFromFile::B = true                  #from input file
  #priceFromDataStorage::B = false          #from previous result files

  createMarkovModel::B = true               #from input file
  #markovModelFromDataStorage::B = false    #from previous result files

  drawScenarios::B = true
  drawOutofSampleScen::B = false
  useScenariosFromDataStorage::B = false    #from previous result files
  useHistoricScen::B = false                #from input file

  #inputFromDatastorage::B = false          #if reading from resultfile

  #additional settings
  production_factors::B=false
  water_levels::B =true
  general_plots::B=false
  save_excel::B=false
  error_evaluation::B=true

end

# Enivronmental constraint: reservoir dependent max. discharge constraint
struct maxDishargeConstraint
envMod::Int                                 #module constrain it imposed on
  firstAct::Int                             #first week where constraint can be activated
  lastAct::Int                              #last week where constraint can be activated
  lastMaxDisch::Int                         #last week where max discharge can be activeted
  lastNoDecrease::Int                       #first week where no res level decrease can be activated
  actLevel::Float64                         #Inflow level that activates constraint
  deactLevel::Float64                       #reservoir level that deactivated constraint
  maxDischarge::Float64                     #max discharge limit
end

# Enivronmental constraint: inflow dependent min. flow constraint
struct qMinDependentnFlow
  qMin::Float64
  qMod::Int
  flowMin::Any
  flowScale::Any
end 

# stochastic input data 
#------------------------------------------------------

struct NormData
  data::Any
  mean::Any
  std::Any
end

struct samplingData
  trajectories::Any
  trajectories_normalized::Any
  dataI::Any
  dataP::Any
  KmeansClusters::Any
  transitions::Any
  startProbability::Any
  transitionProb::Any
  states::Any
  ScenarioLattice::Any
end

struct SimScenData
  scenarios::Any
  scenStates::Any
end

mutable struct lattice
  states::Any
  probability::Any
  envProbability::Any
end

struct SortedClusters
  centers::Any
  counts::Any
  assignments::Any
end

# Optimization problem
#-----------------------------------------------

struct StageProblemTwoRes
  model::Any
  res::Any
  spill::Any
  prod::Any
  pump::Any
  q_slack::Any
  min_slack::Any
  res_slack_pos::Any
  res_slack_neg::Any
  q_min::Any
  disSeg::Any
  disSegPump::Any
  by_pass::Any
  resbalInit::Any
  resbalStep::Any
  positive_var::Any
  negative_var::Any
  Initial_volumevar_positive::Any
  Initial_volumevar_negative::Any
  prodeff::Any
  #pumpdischarge::Any
  pumpeff_up::Any
  pumpeff_low::Any
  alpha::Any
  gamma::Any
  AlphaCon::Any
  beta_upper::Any # Per linearizzare in SDP
  beta_lower::Any
 # χ::Any
  maxRelease::Any
  maxReleasePump::Any 
  minReservoirEnd::Any
  minReservoir::Any
  noDecrease_week::Any
  minResPunish::Any
end
#q_min::Any

struct StageProblem
  model::Any
  res::Any
  spill::Any
  prod::Any
  q_slack::Any
  min_slack:: Any
# res_slack:: Any
  q_min::Any
  disSeg::Any
  by_pass::Any
  resbalInit::Any
  resbalStep::Any
  positive_var::Any
  negative_var::Any
  Initial_volumevar_positive::Any
  Initial_volumevar_negative::Any
  prodeff::Any
  alpha::Any
  gamma::Any
  AlphaCon::Any
  maxRelease::Any
  minReservoirEnd::Any
  minReservoir::Any
  noDecrease_week::Any
end
#  q_min::Any

# Results
#-----------------------------------------------

struct FutureValueSDP
  ResSeg::Any
  WVTable::Any
  AlphaTable::Any
end

struct Results
  #Eprofit::Any
  pumping_costs_timestep::Any
  weekly_pumping_costs::Any
  annual_cost_each_reservoir_pump::Any
  annual_total_cost_pump::Any
  turbine_profit_timestep::Any
  weekly_turbine_profit::Any
  annual_profit_each_reservoir_turbine::Any
  annual_total_profit_turbine::Any
  Reservoir::Any
  Reservoir_round::Any
  Spillage::Any
  Production::Any
  Q_slack::Any
  Min_slack::Any
  Res_slack_pos::Any
  Res_slack_neg::Any
  disSeg::Any
  totDischarge::Any
  totPumped::Any
  resInit::Any
  inflow::Any
  price::Any
  obj::Any
  alpha::Any
  gamma::Any
  disSegPump::Any
  Pumping::Any
 # Net_production::Any
  By_pass::Any
end


struct ProductionTime
  max_step_production_turbines::Any
  max_step_request_pump::Any
  step_production_factor_turbines::Any
  step_factor_pump::Any
  nsteps_turbines::Any
  nsteps_pumps::Any
  mean_nsteps_turbines::Any
  mean_nsteps_pumps::Any
 # best_scenarios_turbines::Any
  #worst_scenarios_turbines::Any
  #best_scenarios_pumps::Any
  #worst_scenarios_pumps::Any
  #count_scenarios::Any
  #profit::Any
  #plot_turbines::Any
  #plot_pumps::Any
end



struct Water_levels
  water_volumes_file::Any
  water_levels_file::Any
  NVolumes::Any
  Water_levels_Simulation::Any
  water_level_variations::Any
  volume_variations::Any
  max_min_median::Any
  weekly_water_variations::Any
  frequency::Any
end 

struct Head
  water_volumes_file::Any
  water_levels_file::Any
  NVolumes::Any
  Water_levels_Simulation::Any
  Head_Simulation::Any  
end
