function Wn = coque_W(p)
    % On doit redéfinir les paramètres nécessaires au calcul
    rho_S = 7800; E = 2.1e11; nu = 0.3; R = 5.0; h = 0.05;
    n = 10; % Mode
    
    % On récupère Vn en appelant discrètement notre première fonction !
    Vn = coque(p); 
    
    % Couplage et calcul de Wn
    Inertie =(rho_S * h) .* (p.^2);
    Couplage_nW = (E * h * n) / (R^2 * (1 - nu^2));
    Bloc_Tangentiel = Inertie + ((E * h * n^2) / (R^2 * (1 - nu^2)));
    A2 = rho_S * h * p.^2 - ((E * h * n^2)/(R^2 * (1-nu^2)));
    
    Wn = (Couplage_nW ./ A2) .* Vn;
    disp(Vn)
end