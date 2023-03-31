

# Input data
#-----------------------------------------------

# parameters 
@with_kw struct InputParam{F<:Float64,I<:Int}
  NSeg::Any                                       #Number of segments to divide the resevoir into to define states
  NPrice::I                                     #Number of price scenarios
  NStage::I                                     #Number of stages
  NHoursStage::I                                #Number of hours in one stage
  NHoursStep::I                                 #Number of hours in each time step within a stage
  Big::F                                        #A big number
  AlphaMax::F                                   #Bounds for expected future value, initial value
  PenSpi::F                                     #Small penalty for spillage
  PenQ::F                                       #Large penalty for tanking
  NStep::I                                      #Number of steps within each stage
  MM3Week::F                                    #Conversion factor week
  MM3Step::F                                    #Conversion factor time step
  StepFranc::Any                                #Time Step fraction of week
  NStates::I                                    #Number of inflow scnearios
  MaxIt::I                                      #Max number of iterations
  conv::F                                       #Convergence criterium
  NSamples::I                                   #Number of samples drawn when making scenario lattice
  NSimScen::I                                   #Number of scenarios simulated in sim
  LimitPump::I
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
  NMod::Any
  NUp::Any
  Eff::Any         # MW/m3/s
  NDSeg::Any
  DisMaxSeg::Any   # m3/s
  MaxRes::Any      #Mm3/s
  Scale::Any
  ResInit0::Any    #Mm3
  qMin::Any
  Station_with_pump::Any
  NDSegPump::Any
  DisMaxSegPump::Any
  EffPump::Any
  Pump_direction::Any
  N_min_flows::Any
  Activation_weeks::Any
  Min_flows::Any
end

# run settings
@with_kw mutable struct runModeParam{B<:Bool}

  # Solver settings
  solveMIP::B = false    #If using SOS2

  # SDP settings
  solveSDP::B = true
  DebugSP::B = false #Option to save results from each time decision problem is solved in SDP
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
  setInputParameters::B = true            #from .in file
  #readInputParameters::B = false           #from previous result files

  hydroSystemFromFile::B = true        #from input file

  #inflowFromFile::B = true                 #from input file
  #inflowFromDataStorage::B = false         #from previous result files

  #priceFromFile::B = true                  #from input file
  #priceFromDataStorage::B = false          #from previous result files

  createMarkovModel::B = true              #from input file
  #markovModelFromDataStorage::B = false    #from previous result files

  drawScenarios::B = true
  drawOutofSampleScen::B = false
  useScenariosFromDataStorage::B = false   #from previous result files
  useHistoricScen::B = false               #from input file

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
  envMod::Int #module constrrain it imposed on
  firstAct::Int #first week where constraint can be activated
  lastAct::Int #last week where ocnstraint can be activated
  lastMaxDisch::Int #last week where max discharge can be active
  lastNoDecrease::Int #first week where no res level decrease can be activate
  actLevel::Float64 #Inflow level that avtivates constraint
  deactLevel::Float64 #reservoir level that deactivated constraint
  maxDischarge::Float64 #max discharge limit
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
  beta_upper::Any
  beta_lower::Any
 # χ::Any
  maxRelease::Any
  maxReleasePump::Any 
  minReservoirEnd::Any
  minReservoir::Any
  noDecrease_week::Any
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
