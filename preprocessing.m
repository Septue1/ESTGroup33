% Pre-processing script for the EST Simulink model. This script is invoked
% before the Simulink model starts running (initFcn callback function).

%% Load the supply and demand data

timeUnit   = 's';
supplyFile = "Team33_supply.csv";
supplyUnit = "kW";

% load the supply data
Supply = loadSupplyData(supplyFile, timeUnit, supplyUnit);

demandFile = "Team33_demand.csv";
demandUnit = "kW";

% load the demand data
Demand = loadDemandData(demandFile, timeUnit, demandUnit);

%% Simulation settings

deltat = 5*unit("min");
stopt  = min([Supply.Timeinfo.End, Demand.Timeinfo.End]);

%% System parameters

% transport from supply and to demand
aSupplyTransport  = 0.97;      % Transformer efficiency (94% - 97%)
L      = 0.11 * 29; % Cable length from supply [km] (a bit more than 100 meters)
Rprime = 0.1181;    % Resistance per unit length [Ohm/km] (ACSR cable)
V      = 320e3;     % Transmission voltage [V] (320 - 800 kV)
L_demand = 10 ;     % Cable length [km] (10 to couple hundred km) to demand
aDemandTransport = aSupplyTransport;
% injection system
eta_converter = 0.97;                 % Converter efficiency
eta_pump = 0.80;                      % Francis pump efficiency
eta_inj = eta_converter * eta_pump;   % Overall injection efficiency
aInjection = eta_inj;

% storage system
EStorageMax     = 2*10e8;            % Maximum storage capacity [J]
EStorageMin     = EStorageMax/20;  % minimum energy = 5% of total cacpacity [J]
EStorageInitial = EStorageMax/2;   % Initial energy stored [J] (50% full)
bStorage        = 0;               % Storage dissipation coefficient [1/s]


%% Hydraulic storage system constants
rho = Simulink.Parameter(1000);
g = Simulink.Parameter(9.81);
Hturbine = Simulink.Parameter(10);
r_sph = 6.2;
N_sphere = 35;
dt = Simulink.Parameter(deltat);


% extraction system
eta_turbine    = 0.87;                          % Francis turbine efficiency
eta_generator  = 0.97;                          % Generator efficiency
eta_extr       = eta_turbine * eta_generator;   % Overall extraction efficiency
aExtraction    = eta_extr;                      % Extraction loss coefficient (ex: 16% losses, 84% efficiency)