function PVFR = PVFR(i,n,m)
    number_of_replacement = floor (n/m);
    PVFR = 0;
    for k = 1:number_of_replacement
        PVFR = PVFR +1/(1+i)^(k*m);
    end
end
