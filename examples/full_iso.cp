
e1 = unfold @(mu T. T -> Int) (fold @(mu T. T -> Int ) (\ (_: mu T. T -> Int)  -> 1 + 1));

e2 = unfold @(mu T. Int) (fold @(mu T. Int) (1 + 1));

interface T { eval : Int }; 
e3 = unfold @T (fold @T {eval = 1 + 1});

e3