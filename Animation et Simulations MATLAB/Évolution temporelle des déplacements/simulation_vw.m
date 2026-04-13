% Script de simulation couplée V_n et W_n
clear; clc; close all;

t_max_secondes = 0.025; 

[Vn_temporel, temps] = nilt('coque', t_max_secondes);

[Wn_temporel, ~] = nilt('coque_W', t_max_secondes);

% V_n
subplot(2, 1, 1);
plot(temps, Vn_temporel, 'b-', 'LineWidth', 1.5);
title('Déplacements de la coque pour le mode n=10');
ylabel('Déplacement radial v_n (m)');
grid on;

% W_n
subplot(2, 1, 2);
plot(temps, Wn_temporel, 'r-', 'LineWidth', 1.5);
xlabel('Temps (secondes)');
ylabel('Déplacement tangentiel w_n (m)');
grid on;

% Tracé

grid on;
box on;
hold off;