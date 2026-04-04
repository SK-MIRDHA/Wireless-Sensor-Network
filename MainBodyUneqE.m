clc; clear; close all;
%%FileName: MainBodyUneqE.m
%%Substitute for RoutingMain.m
%%This doesnot consider equal energy depletion for each hop
%%Uses distance for varibale energy usage

%% ---------------- NETWORK PARAMETERS ----------------
N = 100;
area = 100;

Emax = 5;
Edead = 0.2;
Cmax = 1;

alpha = 0.6;
beta  = 0.4;
theta = 0.3;
lambda = 0.05;

Etransmit = 0.02;     % base energy
epsilon = 0.001;      % distance factor (NEW)

delay_threshold = 15;

r = 5;
cr = 2*r;
R = max(cr,25);

%% ---------------- INPUT ----------------
temp = input('Enter number of transmissions: ','s');
iterations = str2double(temp);

if isnan(iterations) || iterations <= 0
    iterations = 1;
end

%% ---------------- NODE DEPLOYMENT ----------------
pos = area * rand(N,2);
E = Emax * ones(N,1);
C = rand(N,1);
Cij = rand(N);

s = 1;
BS = N;

%% ---------------- TRACKING ----------------
energy_history = zeros(iterations,1);
pdr_history = zeros(iterations,1);
delay_history = zeros(iterations,1);
packets_delivered = 0;

%% ================= BEFORE SCALABILITY =================
for t = 1:iterations

    K = 4;                           %% 1.FOREST (Multiple Trees)
    Paths = cell(K,1);
    Backups = cell(K,1);
    fitness = zeros(K,1);

    for i = 1:K                      
        Cij_rand = Cij + 0.05*rand(N);        %%2. FIRE SPREAD (Exploration)

        [P_temp, B_temp, ~] = routing(pos, E, C, Cij_rand, N, s, BS, R, ...     %% 3.TREE GENERATION
            Emax, Edead, Cmax, alpha, beta, theta, lambda, Etransmit, 1);

        Paths{i} = P_temp;
        Backups{i} = B_temp;

        hops = length(P_temp) - 1;

        if P_temp(end) == BS
            delivery = 1;
        else
            delivery = 0;
        end

        fitness(i) = 0.6*(1/(hops+1)) + 0.3*delivery + 0.1*mean(E(P_temp));     %% 4.FITNESS EVALUATION

        if hops > 15
            fitness(i) = fitness(i) * 0.5;
        end
    end

    [~, idx] = sort(fitness,'descend');                  %%5. BURNING (Selection)

    PrimaryPath = Paths{idx(1)};
    BackupPath  = Backups{idx(1)};

    if length(BackupPath) < 2
        BackupPath = Backups{idx(2)};
    end

    %% REALISTIC ENERGY UPDATE (KEY CHANGE)
    for i = 1:length(PrimaryPath)-1
        u = PrimaryPath(i);
        v = PrimaryPath(i+1);

        d = norm(pos(u,:) - pos(v,:));
        energy_loss = Etransmit + epsilon*(d^2);

        E(u) = max(E(u) - energy_loss, 0);
    end

    %% METRICS
    hops = length(PrimaryPath) - 1;
    delay_history(t) = hops;

    if PrimaryPath(end) == BS
        packets_delivered = packets_delivered + 1;
    end

    pdr_history(t) = packets_delivered / t;
    energy_history(t) = sum(E);
end

%% -------- SHOW BEFORE --------
figure;
visualize(pos, PrimaryPath, BackupPath, E, Edead, s, BS, 'Before Scalability');

%% ================= SCALABILITY =================
temp = input('Do you want scalability? (1/0): ','s');
choice = str2double(temp);

delay_after = NaN;

if choice == 1

    addN = 20;

    pos = [pos; area * rand(addN,2)];
    E = [E; Emax*ones(addN,1)];
    C = [C; rand(addN,1)];

    N = length(E);
    Cij = rand(N);

    disp('Scalability applied');

    [PrimaryPath2, BackupPath2, ~] = routing(pos, E, C, Cij, N, s, BS, R, ...
        Emax, Edead, Cmax, alpha, beta, theta, lambda, Etransmit, 1);

    hops2 = length(PrimaryPath2) - 1;
    delay_after = hops2;

    figure;
    visualize(pos, PrimaryPath2, BackupPath2, E, Edead, s, BS, 'After Scalability');
end

%% ================= GRAPHS =================

% Energy
figure;
plot(1:iterations, energy_history, '-o','LineWidth',2);
xlabel('Transmissions');
ylabel('Total Residual Energy');
title('Residual Energy vs Transmissions (Non-Linear)');
grid on;

% PDR
figure;
plot(1:iterations, pdr_history, '-s','LineWidth',2);
xlabel('Transmissions');
ylabel('Packet Delivery Ratio');
title('PDR vs Transmissions');
grid on;

% Delay
figure;
plot(1:iterations, delay_history, '-^','LineWidth',2);
xlabel('Transmissions');
ylabel('Delay (Hops)');
title('Delay vs Transmissions');
grid on;

% Comparison
if choice == 1
    figure;
    bar([delay_history(end), delay_after]);
    set(gca,'XTickLabel',{'Before','After'});
    ylabel('Delay');
    title('Before vs After Scalability');
end

%% ---------------- ENERGY TABLE ----------------
disp('Final Energy Table:');
T = table((1:N)', E, 'VariableNames', {'Node','Energy'});
disp(T);


%% ---------------- ENERGY HEATMAP WITH NODE IDs ----------------
figure;

scatter(pos(:,1), pos(:,2), 60, E, 'filled'); 
colorbar;

colormap(jet);
caxis([0 Emax]);   % fixed color scale (important)

title('Energy Distribution Heatmap with Node IDs');
xlabel('X Position');
ylabel('Y Position');

grid on;
axis equal;

%% ADD NODE LABELS
for i = 1:length(pos)
    text(pos(i,1)+1, pos(i,2)+1, num2str(i), ...
        'FontSize',7, 'Color','k');
end