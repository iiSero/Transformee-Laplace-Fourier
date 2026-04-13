function dep=V(p)
% Le Fluide
rho_F = 1000;         % Masse volumique de l'eau (kg/m^3)
c = 1400;             % Vitesse du son (m/s)

% La Structure de la coque (Acier)
rho_S = 7800;         % Masse volumique de l'acier (kg/m^3)
E = 1.9e11;           % Module d'Young de l'acier (Pa)
nu = 0.3;             % Coefficient de Poisson (sans dimension)
R = 5;              % Rayon du sous-marin (m)
h = 0.05;             % Épaisseur de la coque (5 cm)

% Onde de choc 
Pm = 7.94e6;             % Pression max de l'explosion
theta = 0.0001145;        % Constante de temps de décroissance 

n = 10;                % Mode d'étude
z = (p .* R) ./ c;

% Dérivée de Bessel
Kn = besselk(n, z);
if n == 2
    Kn_prime = -besselk(1, z);
else
    Kn_prime =-besselk(n-1, z) - (n./z) .* Kn;
end
    ratio_K = Kn ./ Kn_prime;

A1 = (p.^2 .* (1 - ((rho_F * c)./(rho_S * h * p)) .* ratio_K)) + (E)/((R^2) * (1-nu^2) * rho_S);
B1 = (E * n) / (rho_S * R^2 * (1-nu^2)) ;
B2 = (E * h * n) / (R^2 * (1-nu^2));
A2 = rho_S * h * p.^2 - ((E * h * n^2)/(R^2 * (1-nu^2)));
Lp = Pm ./ (p + (1/theta)); % Modèle de Cole
dP_dr = -(p ./ c) .* Lp;
P = -(1/(rho_S * h)) .* (Lp - (c./p) .* ratio_K .* dP_dr);
V = P ./ ((A1 +(B1 .* B2))./ A2);

dep=V;


end

