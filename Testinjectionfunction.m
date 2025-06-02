% Test script for computeInjectionSimulink

% --- Parameters ---
PtoInjection = 100000;     % Input electrical power [W]
h_in_s = 6.2;            % Initial water height [m]
dt = 300;                  % Time step [s]
r_sph_s = 6.2;
N_sphere_s = 35;
h_in_b = 10.0;
r_sph_b = 10.0;  % Sphere radius [m]
N_sph_b = 9;     % Number of tanks

% --- Call function ---
[PfromInjection, DInjection, h_out] = computeInjectionSimulink(PtoInjection, h_in_s, dt, r_sph_s, N_sphere_s);
[PfromInjectionb, DInjectionb, h_outb] = computeInjectionSimulink(PtoInjection, h_in_b, dt, r_sph_b, N_sph_b);
% --- Display results ---
fprintf('Input Power (PtoInjection): %.2f W\n', PtoInjection);
fprintf('Initial Height (h_in): %.2f m\n', h_in_s);
fprintf('Time Step (dt): %.2f s\n', dt);
fprintf('Output Power (PfromInjection): %.2f W\n', PfromInjection);
fprintf('Injection Loss (DInjection): %.2f W\n', DInjection);
fprintf('New Tank Height (h_out): %.2f m\n', h_out);



fprintf('Input Power (PtoInjection): %.2f W\n', PtoInjection);
fprintf('Initial Height (h_in): %.2f m\n', h_in_b);
fprintf('Time Step (dt): %.2f s\n', dt);
fprintf('Output Power (PfromInjection): %.2f W\n', PfromInjectionb);
fprintf('Injection Loss (DInjection): %.2f W\n', DInjectionb);
fprintf('New Tank Height (h_out): %.2f m\n', h_outb);





function [PfromInjection, DInjection, h_out] = computeInjectionSimulink(PtoInjection, h_in, dt,r,N)
% Calculates stored power, loss, and new tank height from pump input

 % Physical constants
    rho = 1000;          % Water density [kg/m^3]
    g = 9.81;            % Gravity [m/s^2]
    r_sph_small  = r;
    N_small = N;
    depth = 100;
% Pump and converter efficiency
eta_pump = 0.80;
eta_inj = eta_pump;

H_eff = depth - h_in;

% Pumped mass (kg): m = (eta * P * dt) / (g * H_eff)
m_pumped = eta_inj * PtoInjection * dt / (g * H_eff);
V_pumped = m_pumped / rho;   % [m^3]

% Total tank cross-sectional volume at this height
% For inverse spherical cap: use differential volume approximation
% Instead, solve new height numerically (simplified here)

% Add volume to tank (assuming uniform distribution)
V_total = (pi * h_in^2 * (3*r_sph_small - h_in)) / 3 + V_pumped / N_small;


% Solve for new height from volume
% Use Newton-Raphson or brute-force (we’ll use simple loop approx here)
h_out = h_in;
for i = 1:10000
    V_guess = (pi * h_out^2 * (3*r_sph_small - h_out)) / 3;
    error = V_guess - V_total;
    dVdh = pi * h_out * (3*r_sph_small - h_out); % derivative dV/dh
    h_out = h_out - error / dVdh;
    h_out = max(0, min(h_out, 2 * r_sph_small));
end

% Potential energy added
E_added = m_pumped * g * H_eff;
PfromInjection = E_added / dt;
DInjection = PtoInjection - PfromInjection;
end