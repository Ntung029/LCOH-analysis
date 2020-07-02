% Calculate levelised cost of hydrogen with variation of wholesale
% electricity markets and capacity factors

%% input
    %Increasing_Rates: projection of annually increasing of electricity prices 
    %daily_demand:  daily output of water electrolysis plant
    %location: CA,GE,ON
    %H_HighP_storage_max: Storage capacity kgH2
    %Scenario: for variation of capital cost: 2: average; 1: worst; 0: best
    %Electrolyzer_type: 1: Alkaline, 0 PEM
    %storage_type: 1: compressed gas tank; 0: underground storage.
    %CF = [0.4:0.01:1]:    variation of capacity factor of water electrolysis plant
%% Output
    %result_summary: Levelised cost of hydrogen of provided locations


%clc;
%clear all;
%close all;

%% inputs data
Increasing_Rates = [0.027 0.036 0.036]; % Estimated elevation electricity rate
daily_demand = 40000; % kgH2/day: Mid scale
locations = ["CA" "GE" "ON"]; % three assessed locations
%locations = ["AB"];
Water_price_all = [1 1 1];

%% system configuration
Scenario = 2; %Average capital cost
%Scenario = 1; %Worst-case capital cost
%Scenario = 0; %Best-case capital cost
%Electrolyzer_type = 1; % Alkaline
Electrolyzer_type = 0; % PEM
storage_type = 1; % aboveground
%storage_type = 0; % underground

if storage_type ==1 % aboveground
    H_HighP_storage_max = daily_demand*1; % kg % variation of hydrogen storage
else % underground
    H_HighP_storage_max = daily_demand*7; % kg % variation of hydrogen storage
end

K = system_efficiency(Electrolyzer_type,100); %KWh/Nm3 assume constant after 100MW scale
CF =[0.4:0.01:1];


result_summary  = zeros(size(CF,2),size(locations,1),3);
result_all = zeros(size(CF,2),3);
time_window = 8760;

figure
hold on
for l_index = 1:size(locations,2) %per each location
    
    % read electricity price for each location
    location = locations(l_index);
%    Prices_file = 'C:\Users\ntung029\Documents\Personal Content\T Carbon Engineer\Electricity price\Electricity_price.xlsx';
    Prices_file = 'Electricity_price.xlsx';
    Raw_data  = readtable(Prices_file,'ReadVariableNames',true,'sheet',location); % add sheet name
    disp('Loading raw data...');
    All_data = Raw_data(Raw_data.Year > 2013,:); % Year moving 
    N_data = round(size(All_data,1)); 
    PriceDates = datenum(datetime(table2array(All_data(1:N_data,2)),  'InputFormat', 'MM/dd/yyyy HH'));   %for each electricity price
    Prices = table2array(All_data(1:N_data,4));   %for each electricity price  
    Years  = table2array(All_data(1:N_data,9));
    Electricity_price = [Years,Prices];
    rate = Increasing_Rates(l_index);
    Water_price = Water_price_all(l_index);
    for x = 1:size(CF,2) % variation of electrolyzer size
        installed_power = round(daily_demand/0.08988/24*K)/CF(x)/1000; %MW     
        % techno-economic analysis from previouse electricty prices
        [result1 result2 result3] = H2_production_cost_RTP(daily_demand,K,Electrolyzer_type,1/CF(x),H_HighP_storage_max,storage_type,Electricity_price,Water_price,rate,time_window,Scenario);
                                      % kg/day     kWh/Nm3  1/0         `      kg                   % cents/kWh
        %result_summary(x,l_index,:) = [result1 result2 result3];
        result_all(x,:) = [result1 result2 result3];
    end 
    plot(CF,result_summary(:,l_index));
end
title('Levelised of hydrogen production cost ($/kg)');
xlabel('Capacity factor');
ylabel('Hydrogen production cost - $/kg ');
legend(locations);
hold off


