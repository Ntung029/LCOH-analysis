function Electrolyzer_cap2 = Electrolyzer_cap2(Electrolyzer_power,Electrolyzer_type)
PEM_capital_cost_table = [0.025 0.5 1 2.2 10 50 100 1001; 3719	3132 1957 1281 620 564 450 450];
Alkaline_capital_cost_table = [0.025 0.5 1 2.2 10 50 100 1001; 2280	1926	1141	775	627	570	513 513]; 


    if Electrolyzer_type == 1  
        % Alkaline electrolysis
        Electrolyzer_cap2 = interp1(Alkaline_capital_cost_table(1,:),Alkaline_capital_cost_table(2,:),Electrolyzer_power);
    else %PEM water electrolysis
        Electrolyzer_cap2 = interp1(PEM_capital_cost_table(1,:),PEM_capital_cost_table(2,:),Electrolyzer_power);
    end
end
