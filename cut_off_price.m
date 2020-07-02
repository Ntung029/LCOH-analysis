    function cut_off_price = cut_off_price(Prices,CF)
        Prices = sort(Prices);
        cut_off_price = Prices(floor(CF*size(Prices,1))); 
    end