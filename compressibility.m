function[Z_calc] = compressibility(gas,T_Kelvin,P_bar)
% Approximates compressibility factor (commonly denoted Z) of gas at a 
% given temperature and absolute pressure.  Calculated by Van der Waals
% equation of state.  
% Chad Greene 2009, updated Nov. 2012. 
% 
% Z = PV/(RT)
%
% Note: The Van der Waals equation is an improvement of the ideal gas law, 
% above the critical temperature, and is also qualitatively reasonable below
% the critical temperature, but it is almost never appropriate for rigorous 
% quantitative calculations. (Paraphrased from T.L. Hill, Statistical Thermo-
% dynamics, Addison-Wesley, Reading (1960))
% 
% 
% *********************************************************************** %
% Example 1: Find the compressibility factor of methane at 280 K and 20 bar:
% 
% Z = compressibility('methane',280,20)
% Z = 0.951
%
% The above example shows that methane at 280 K and 20 bar deviates from
% the ideal gas law by approximately 4.9%.
% 
%
% *********************************************************************** %
% Example 2: Calculate Z for a range of pressures with constant temp:
% 
% T = 195; % [°K]
% P = 1:100; % [bar]
% 
% Z = compressibility('sf6',T,P); 
% 
% plot(P,Z)
% box off
% xlabel('hydrostatic pressure (bar)')
% ylabel('compressibility factor {\it Z}')
% title(['SF_6 at ',num2str(T),' K'])
%
% *********************************************************************** %
% Example 3: Calculate Z for arrays of simultaneously-varying pressure and
% temperature values.  
% 
% compressibility('methane',[280 300 350],[1 10 20])
% 
% ans =
%     0.9976
%     0.9802
%     0.9755
% 
% *********************************************************************** %
% I don't know about you, but my lab sure doesn't have any instruments that
% give pressures in bar or temperatures in kelvin.  Yet, thermodynamicists 
% seem to fancy these units.  The simplest solution I've found is to use 
% the unit converters found here: 
% http://http://www.mathworks.com/matlabcentral/fileexchange/35258
% 
% Syntax for using the unit converters with this function would then be:
% 
% compressibility('methane',C2K([5 10 30]),psi2bar(14.7))
% 
% *********************************************************************** %


T = T_Kelvin;
P = P_bar;

switch gas 
% critical properties from http://encyclopedia.airliquide.com/Encyclopedia.asp
    case {'air','AIR','Air'}
        Tc = 132.6; % [K] critical temperature
        Pc = 37.71; % [bar] critical pressure
    
    case {'ammonia','Ammonia','AMMONIA','NH3','nh3','NH_3'}
        Tc = 405.5; % [K] critical temperature
        Pc = 112.8; % [bar] critical pressure
    
    case {'argon','Ar','Argon','ARGON'}
        Tc = 150.8; % [K] critical temperature
        Pc = 48.98; % [bar] critical pressure

    case {'butane','BUTANE','Butane'}
        Tc = 425.1; % [K] critical temperature
        Pc = 37.96; % [bar] critical pressure
        
    case {'CO','co','carbon monoxide'} 
        Tc = 132.9; % [K] critical temperature
        Pc = 34.987; % [bar] critical pressure
       
    case {'CO2','co2','CO_2','carbon dioxide'}
        Tc = 304.2; % [K] critical temperature
        Pc = 73.825; % [bar] critical pressure
    
    case {'CH4','ch4','methane','Methane','METHANE'}
        Tc = 190.5; % [K] critical temperature
        Pc = 45.96; % [bar] critical pressure
       
    case {'ethane','Ethane','ETHANE'}
        Tc = 305.4; % [K] critical temperature
        Pc = 48.839; % [bar] critical pressure
    
    case {'nitrogen','Nitrogen','NITROGEN','N2','n2','N_2'}
        Tc = 126.2; % [K] critical temperature
        Pc = 33.999; % [bar] critical pressure
    
    case {'oxygen','Oxygen','OXYGEN','O2','o2','O_2'}
        Tc = 154.5; % [K] critical temperature
        Pc = 50.43; % [bar] critical pressure
    
    case {'propane','Propane','PROPANE','C3H8','c3h8'}
        Tc = 369.8; % [K] critical temperature
        Pc = 42.5; % [bar] critical pressure
    
    case {'sulfur dioxide','SO2','so2','SO_2'}
        Tc = 430.8; % [K] critical temperature
        Pc = 78.84; % [bar] critical pressure
    
    case {'SF6','sulfur hexafluoride','sf6','SF_6'}
        Tc = 318.6; % [K] critical temperature
        Pc = 37.59; % [bar] critical pressure
    
    % Quantum gases (require Newton's correction): 
    case {'helium','He','HELIUM','Helium'}
        Tc = 5.1; % [K] critical temperature
        Pc = 2.275; % [bar] critical pressure

        Tc = Tc+8; % [K] adjusted critical temperature
        Pc = Pc+8.106; % [bar] adjusted critical pressure
    
    case {'hydrogen','Hydrogen','HYDROGEN','H2','h2','H_2'}
        Tc = 33.2; % [K] critical temperature
        Pc = 12.98; % [bar] critical pressure

        Tc = Tc+8; % [K] adjusted critical temperature
        Pc = Pc+8.106; % [bar] adjusted critical pressure
    
    case {'neon','Ne','ne'}
        Tc = 44.3; % [K] critical temperature
        Pc = 27.56; % [bar] critical pressure

        Tc = Tc+8; % [K] adjusted critical temperature
        Pc = Pc+8.106; % [bar] adjusted critical pressure
    
end

Tr = T/Tc; % reduced temperature
Pr = P/Pc; % reduced pressure 
Z = .01:.0001:5; % range of reasonable Z values 

nm = max([length(Tr) length(Pr)]);

% Produce a warning if input argument lengths mismatch:
if length(Tr)~=length(Pr) && min([length(Tr) length(Pr)])~= 1
    warning('Temperature and pressure array lengths must match if neither is a scalar.')
end

% Brute-force fix to Tr if necessary: 
if length(Tr)==1
    Tr = Tr*ones(size(Pr)); 
end

% Brute-force fix to Pr if necessary: 
if length(Pr)==1
    Pr = Pr*ones(size(Tr)); 
end

% Preallocate Z_calc before the loop begins: 
Z_calc = NaN(nm,1);

for n = 1:nm
    VanDerWaal = (Z + 27*Pr(n)./(64*((Tr(n))^2).*Z)).*(1 - Pr(n)./(8.*Tr(n).*Z)); 
    Z_calc(n) = interp1q(VanDerWaal,Z',1);
end
