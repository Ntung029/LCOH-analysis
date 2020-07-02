function system_efficiency = system_efficiency(technology, install_power) % kWh/Nm3H2
    if (technology == 1) % alkaline
        power =      [0.025 0.1  10    1001];
        efficiency = [0.58  0.61 0.62 0.62];
        
    else %PEM
        power =      [0.025 0.1  10    1001];
        efficiency = [0.60  0.63 0.65 0.65];
    end
    
    system_efficiency = 3.54/interp1(power, efficiency,install_power); % kWh/Nm3H2
end