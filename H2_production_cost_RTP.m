function [H2_production_cost H2_production_cost_CAPEX H2_production_cost_OPEX] = H2_production_cost_RTP(daily_demand,K,Electrolyzer_type,Ce_Cm,H_HighP_storage_max,storage_type,Electricity_price,Water_price,DF,time_window,Scenario)
% daily_demand:         kg/day
% K:                    kWh/Nm3
% Electrolyzer_type:    1 Alkaline, 0 PEM
% Ce_Cm : 1x1;          1/Capaity factor
% H_HighP_storage_max:  kgH2
% Electricity_price :   4 years data; year and prices (cents/kWh)
% Water_price: 1x1;     $/m3

%% Inputs defined of capital analysis

    % daily_demand: total demand of hydrogen in a day; assume to be constant: kg H2/day
    % K: efficiency of water electrolysis plant kWh/Nm3
    % Electrolyzer_type = 1: Alkaline, 0:PEM
    % Ce_Cm: ratio between electrolyzer vs medium hourly demand (= 1/Capacity factor)
    % H_HighP_storage_max: maximum storage limit : kg H2
    % Electricity prices: cents/kWh
    % Water_price:  $/m3


%% output
    % Determine the levelized cost of hydrogen production including
        %CAPEX: Electrolyzer, Main Compressor, High Pressure storage,
            %Electrical connection and other capital cost
        %OPEX: Electricity, Water, other OPEX
        

%% Input
H_HighP_storage_max_Nm3 = H_HighP_storage_max/0.08988; %Nm3

% asummption
Eff_isentropic = 0.5; % 
Motor_Comp_factor = 1.1; % design factor for compressor motor
max_comp_temp = 40; %degC maximum working temperature of compressor
P_comp_out = 180; % bar
P_comp_in  = 10;  % bar

%% constant
R = 8.3144; %kj/K.kg-mol;
k = 1.42; % Cp/Cv
N_stages = 2; %compression stages
H2_loss = 0.00;
Install_factor = 1.3; % including installation cost, transporation charge by vendors
WACC = 0.1;
%Electrolyer_capital_per_kW =625; %$/kW

%% Capital cost %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% compressor
Cp_Cm = Ce_Cm;
hourly_demand = daily_demand / 24; %kg/hour
Compressor_flow_rate = Cp_Cm*hourly_demand; %kg/hour Maximum working rate of Compressor equals to maximum working rate of Electrolyzer
Main_Mean_Compressibility_factor = (compressibility('hydrogen',max_comp_temp+273.15,P_comp_out)+...
                                    compressibility('hydrogen',max_comp_temp+273.15,P_comp_in))/2; 
% a correction factor from ideal gas to non-ideal gas at high pressure and high temperature
% The capital cost equals to installed capacity function, not operation capacity
% N_compressor time with Compressor_maximum_rate
Compressor_capacity_install = Compressor_flow_rate; % asssume compressor capacity avaiable at any size
P_isentropic_main = Main_Mean_Compressibility_factor*(Compressor_capacity_install/60/60/2.0158)*R*(max_comp_temp+273.15)*...
               N_stages*k/(k-1)*((P_comp_out/P_comp_in)^((k-1)/(N_stages*k))-1);      
P_shaft = P_isentropic_main/Eff_isentropic;
Eff_Motor = 8e-5*(log(P_shaft))^4-0.0015*((log(P_shaft))^3)+0.0061*(log(P_shaft))^2+0.0311*(log(P_shaft))+0.7617;
P_main_comp_motor_total = P_shaft/Eff_Motor* Motor_Comp_factor;
P_main_comp_motor = P_main_comp_motor_total; % Installed capacity of a compressor
%Cap_compressor = N_compressor*40635*P_main_comp_motor^0.6038*TB3_cost_factor*USD_2016/USD_2007; 
%Cap_compressor = (4.2058*Compressor_flow_rate+18.975)*1000; % $
Cap_compressor = P_main_comp_motor*2481; 

%% Electrolyzer 
Electrolyzer_capacity_kg_per_hr = Ce_Cm*hourly_demand; % kg/hr 
%conservation equation: currently assume a linear relationship: Ni=K*Pi
Electrolyzer_capacity_Nm3_per_hr = ceil (Electrolyzer_capacity_kg_per_hr /0.08988); %Nm3H2/hr

if Electrolyzer_type ==1 % Alkaline
    if Scenario ==1 % wrost case
            Electrolyer_capital_per_kW= 650; %$/kW
    elseif Scenario ==0 % best case
            Electrolyer_capital_per_kW = 510;%$/kW
    else %average value
            Electrolyer_capital_per_kW = 580;%$/kW
    end
else % PEM
    if Scenario ==1 % wrost case
            Electrolyer_capital_per_kW = 850;%$/kW
    elseif Scenario == 0% best case
            Electrolyer_capital_per_kW = 400;%$/kW
    else %average value
            Electrolyer_capital_per_kW = 625;%$/kW
    end
end




%Electrolyer_capital_per_kW = Electrolyzer_cap2(Electrolyzer_capacity_Nm3_per_hr*K/1000,Electrolyzer_type); % $/kW
Cap_electrolyzer = Electrolyzer_capacity_Nm3_per_hr*Electrolyer_capital_per_kW*K; % $

%% Electrical PENDING
Cap_Electrical = 200*(Electrolyzer_capacity_Nm3_per_hr*K+P_main_comp_motor); % $ Reference from extended service charge by BC Hydro, QC
%Cap_Electrical = 10000000; % assumption ???? 10M
%% Storage
if storage_type ==1 % aboveground
    Cap_Storage  = 720*0.08988*H_HighP_storage_max_Nm3; %$; pending discussion
else
    Cap_Storage  = 22.44*0.08988*H_HighP_storage_max_Nm3; %$; pending discussion
end

%% Land cost, page 61 for storage land required and capacity
Land_required = 800; % m2 assumption. increasing land beacause of adding electrolyzer and low pressure storage
Land_cost = 0; %$/m2
Cap_land  = Land_cost*Land_required;


%% Other capital cost
Cap_Total_Hardware = (Cap_electrolyzer+Cap_compressor+ Cap_Electrical+Cap_Storage); %$
Site_preparation = 0.05;
Engineering_design = 0.1;
Project_contingency = 0.05;
Licensing_fee = 0.01; % one-time 
Permitting_cost = 0.03;
Other_cap = 0; 
Cap_other_and_land = Cap_land+Cap_Total_Hardware*(Site_preparation+Engineering_design+Project_contingency+Licensing_fee+Permitting_cost+Other_cap);
Cap_Total = Install_factor*Cap_Total_Hardware+Cap_other_and_land; %$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Replacement cost
Pmax = Electrolyzer_capacity_Nm3_per_hr*K;
if Electrolyzer_type ==1
    %Alkaline
    Replacement_cost = 340; % $/kW
    Replacement_period =  80000*Ce_Cm/24/365; % years How many years does it take to replace the stack, depend on capacity factor
    Pmin = 0.1*Pmax;
else
    %PEM
    Replacement_cost = 420; % $/kW
    Replacement_period =  40000*Ce_Cm/24/365; % years How many years does it take to replace the stack, depend on capacity factor
    Pmin = 0.05*Pmax;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% O$M  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Labor_cost_factor = 0.05; % assumption
Cost_labor = Cap_Total_Hardware *Labor_cost_factor; % $/year

%% Calculate the yearly average electricity consumption

% Main compressor and electrolyzer
Electricity_cost_Electrolyzer = 0;
Electricity_cost_comp = 0;

for i = 2015:2018
    Prices_y_1 = Electricity_price(Electricity_price(:,1)==(i-1),2);
    Prices_y = Electricity_price(Electricity_price(:,1)==i,2);
    Electricity_price_yearly = [Prices_y_1;Prices_y];
    N_H2_out_Nm3_per_hr = ones(size(Prices_y,1),1)*daily_demand/24/0.08988; % Nm3
    starth = size(Prices_y_1,1)+1;
    time_window = min(time_window,starth-1); % due to the avaiability of the data set
    N_Electrolyzer_operation_Nm3_per_hr = Operating3(Electricity_price_yearly,N_H2_out_Nm3_per_hr,Pmin,Pmax,0,H_HighP_storage_max_Nm3,K,time_window,starth,1/Ce_Cm);
    Power_Electrolyzer_kW = N_Electrolyzer_operation_Nm3_per_hr*K; %kW/hr
    
    % Electrolyzer
    Electricity_cost_Electrolyzer = Electricity_cost_Electrolyzer +...
        (Prices_y' * Power_Electrolyzer_kW)/100; %$ present value of yearly electricity cost
    
    % compressor power consumption
    N_compressor_kg_per_hr = N_Electrolyzer_operation_Nm3_per_hr* 0.08988; %kg/h
    Average_compressor_energy = P_main_comp_motor /Compressor_capacity_install; % kWh/kg H2 -hr 
    Electricity_consumption_comp = N_compressor_kg_per_hr*Average_compressor_energy; %kWh/hr
    Electricity_cost_comp = Electricity_cost_comp+...
        (Electricity_consumption_comp'*Prices_y)/100; %$ present value of yearly electricity cost

end
N_year = 20;
i_prime = (WACC - DF)/(1+DF);
PVF_i_n = ((1+i_prime)^N_year -1) /i_prime/(1+i_prime)^N_year;
CRF_i_n = WACC*(1+WACC)^N_year /((1+WACC)^N_year-1);



% summation 
Annual_Cost_electricity  = (Electricity_cost_Electrolyzer+Electricity_cost_comp)*PVF_i_n*CRF_i_n/4; % $/year

%% Water consumption
Water_required = 1; %liter/Nm3
Water_consumption = daily_demand*365/0.08988*Water_required/1000; % m3/year
Cost_water =  Water_consumption * Water_price; 
%% Other O&M
Insurance = 0.01*Cap_Total;             % $/year CAP_TOTAL OR CAP_HARDWARE
Property_tax = 0.01*Cap_Total;          % $/year
Licensing_and_permit= 0.001*Cap_Total;  % $/year
Land_rental = 00000;                    % $/year assumption: Not take into account the cost of land rental, only evaluate how much land required
O_M_electrolyzer = 0.01;                % /year
O_M_comp = 0.04;                        % /year
O_M_storage = 0.01;                     % /year
O_M_Electrical = 0.01;                  % /year

Present_replacement_cost = Replacement_cost*Electrolyzer_capacity_Nm3_per_hr*PVFR(WACC,20,Replacement_period);
Annual_maintenance = O_M_electrolyzer*Cap_electrolyzer+O_M_comp*Cap_compressor...
            +O_M_storage*Cap_Storage+O_M_Electrical*Cap_Electrical;
Total_fixed_O_M = Insurance+Property_tax+Licensing_and_permit+Land_rental;
Cost_Total_O_M = Total_fixed_O_M+Annual_Cost_electricity+Cost_water+Cost_labor+Annual_maintenance; % $/year


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DCF calcualtion output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CRF = WACC*((1+WACC)^20)/((WACC+1)^20-1); % 20 years evaluation
Real_Fixed_charge_rate = CRF; % property tax, annual license and permit already included in O&M
H2_production_cost = (Cap_Total*Real_Fixed_charge_rate + Cost_Total_O_M+Present_replacement_cost*CRF)/...
    (daily_demand*365/(1-H2_loss));
H2_production_cost_CAPEX = Cap_Total*Real_Fixed_charge_rate/(daily_demand*365/(1-H2_loss));
H2_production_cost_OPEX = (Cost_Total_O_M+Present_replacement_cost*CRF)/(daily_demand*365/(1-H2_loss));

end