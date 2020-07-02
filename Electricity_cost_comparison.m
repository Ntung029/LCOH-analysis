%Electricity_cost_comparison.m
% This program evaluates the saving percentage of electricity cost of the
% water electrolysis plants participated in different wholesale markets when
% applying the proposed operation strategy. 

%% input
% location: CA,GE,ON
% demand: output hydrogen/day:          kgH2/day
% Pmin: minimum electrolyzer power 1x1  kW 
% Pmax: maximum electrolyzer power 1x1  kW
% Hmin: minimum storage limit 1x1       kgH2
% Hmax: maximum storage limit 1x1       kgH2
% CF: capacity factor 1x1: (0 1]

%%Output
% opex1: 4x1: yearly operation cost by the proposed algorithm
% opex2: 4x1: yearly operation cost with 1 year optimization: not using in
% the final paper
% opex3: 4x1: yearly operation cost when CF = 1, without flexibility of
% operating schedule

clc;
clear all;
close all;
daily_demand = 40000; % kgH2/day: Mid scale
%locations = ["CA" "GE" "ON"]; 
location = ["GE"];
Hmax = 2800000/0.08988; % Nm3 % variation of hydrogen storage 7 day capacity
Hmin = 0;
CF = 0.9; 
Electrolyzer_type = 1; % Alkaline
%Electrolyzer_type = 0; % PEM

%% calculation of system spec
E_eff = system_efficiency(Electrolyzer_type,100); %KWh/Nm3 assume constant after 100MW scale
installed_power = round(daily_demand/0.08988/24*E_eff)/CF; %KW     
Pmax = installed_power;
if Electrolyzer_type ==1
    %Alkaline
    Pmin = 0.1*Pmax;
else
    %PEM
    Pmin = 0.05*Pmax;
end

% read electricity price for each location
Prices_file = 'C:\Users\ntung029\Documents\Personal Content\T Carbon Engineer\Electricity price\Electricity_price.xlsx';
Raw_data  = readtable(Prices_file,'ReadVariableNames',true,'sheet',location); % add sheet name
disp('Loading raw data...');
All_data = Raw_data(Raw_data.Year > 2013,:); % Year moving 
N_data = round(size(All_data,1)); 
PriceDates = datenum(datetime(table2array(All_data(1:N_data,2)),  'InputFormat', 'MM/dd/yyyy HH'));   %for each electricity price
Prices = table2array(All_data(1:N_data,4));   %for each electricity price

% Plot electricity prices
figure;
plot(PriceDates, Prices);
datetick('x', 'mmm/yyyy');
title('Electricity Prices');
xlabel('Date');
ylabel('Price (cents/kWh)');
window_value = [8760]; %1 year, 180 days, 90 days, 30 days

% initiate result matrixes
opex1 = zeros(4,size(window_value,2));
opex2 = zeros(4,1);
opex3 = zeros(4,1);



for year = 2015:2018
    Prices_y_1 = Prices((All_data.Year ==year-1));
    Prices_y = Prices((All_data.Year ==year));
    N_H2_out_per_hr = ones(size(Prices_y,1),1)*daily_demand/24/0.08988; % Nm3
    E_price = [Prices_y_1;Prices_y];
    
    starth = size(Prices_y_1,1)+1;
    for i = 1:size(window_value,2)
        window = min(window_value(i),starth-1); % due to the avaiability of the data set
        N_in1 = Operating3(E_price,N_H2_out_per_hr,Pmin,Pmax,Hmin,Hmax,E_eff,window,starth,CF);
        opex1(year-2014,i)= E_price(starth:end)'*N_in1*E_eff; 
        N_in2 = Optimum_BC3(E_price(starth:end),N_H2_out_per_hr,Pmin,Pmax,Hmin,Hmax,E_eff); % benchmarch
        opex2(year-2014)  = E_price(starth:end)'*N_in2*E_eff;
        opex3(year-2014)  = E_price(starth:end)'*N_H2_out_per_hr*E_eff;
    end
end


