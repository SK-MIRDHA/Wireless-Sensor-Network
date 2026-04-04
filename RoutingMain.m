clc; clear; close all;

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
Etransmit = 0.05;
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

%% ---------------- FFA ROUTING (BEFORE SCALABILITY) ----------------
K = 4;

Paths = cell(K,1);
Backups = cell(K,1);
fitness = zeros(K,1);

for i = 1:K
    
    Cij_rand = Cij + 0.05*rand(N);
    
    [P_temp, B_temp, ~] = routing(pos, E, C, Cij_rand, N, s, BS, R, ...
        Emax, Edead, Cmax, alpha, beta, theta, lambda, Etransmit, iterations);
    
    Paths{i} = P_temp;
    Backups{i} = B_temp;
    
    hops = length(P_temp) - 1;
    
    if P_temp(end) == BS
        delivery = 1;
    else
        delivery = 0;
    end
    
    % -------- FIXED FITNESS --------
    fitness(i) = 0.6*(1/(hops+1)) + 0.3*delivery + 0.1*mean(E(P_temp));
    
    % penalty for long paths
    if hops > 15
        fitness(i) = fitness(i) * 0.5;
    end
end

[~, idx] = sort(fitness,'descend');

PrimaryPath = Paths{idx(1)};
BackupPath  = Backups{idx(1)};

if length(BackupPath) < 2
    BackupPath = Backups{idx(2)};
end

%% -------- ENERGY UPDATE (FIXED) --------
for i = 1:length(PrimaryPath)-1
    E(PrimaryPath(i)) = max(E(PrimaryPath(i)) - Etransmit, 0);
end

%% ---------------- PERFORMANCE (BEFORE) ----------------
timePerHop = 1;
hops = length(PrimaryPath) - 1;

delay_before = hops * timePerHop;   % ✅ FIXED
throughput_before = 1 / max(delay_before,1);

figure;
visualize(pos, PrimaryPath, BackupPath, E, Edead, s, BS, 'Before Scalability');

%% ---------------- SCALABILITY ----------------
temp = input('Do you want scalability? (1/0): ','s');
choice = str2double(temp);

throughput_after = NaN;
delay_after = NaN;

if choice == 1
    
    addN = 20;
    
    pos = [pos; area * rand(addN,2)];
    E = [E; Emax*ones(addN,1)];
    C = [C; rand(addN,1)];
    
    N = length(E);
    Cij = rand(N);
    
    disp('Scalability applied');

    %% -------- FFA AFTER SCALABILITY --------
    Paths = cell(K,1);
    Backups = cell(K,1);
    fitness = zeros(K,1);
    
    for i = 1:K
        
        Cij_rand = Cij + 0.05*rand(N);
        
        [P_temp, B_temp, ~] = routing(pos, E, C, Cij_rand, N, s, BS, R, ...
            Emax, Edead, Cmax, alpha, beta, theta, lambda, Etransmit, iterations);
        
        Paths{i} = P_temp;
        Backups{i} = B_temp;
        
        hops2 = length(P_temp) - 1;
        
        if P_temp(end) == BS
            delivery2 = 1;
        else
            delivery2 = 0;
        end
        
        fitness(i) = 0.6*(1/(hops2+1)) + 0.3*delivery2 + 0.1*mean(E(P_temp));
        
        if hops2 > 15
            fitness(i) = fitness(i) * 0.5;
        end
    end
    
    [~, idx] = sort(fitness,'descend');
    
    PrimaryPath2 = Paths{idx(1)};
    BackupPath2  = Backups{idx(1)};
    
    if length(BackupPath2) < 2
        BackupPath2 = Backups{idx(2)};
    end

    %% -------- ENERGY UPDATE --------
    for i = 1:length(PrimaryPath2)-1
        E(PrimaryPath2(i)) = max(E(PrimaryPath2(i)) - Etransmit, 0);
    end

    %% ---- PERFORMANCE AFTER ----
    hops2 = length(PrimaryPath2) - 1;
    
    delay_after = hops2 * timePerHop;   % ✅ FIXED
    throughput_after = 1 / max(delay_after,1);

    if delay_after > delay_threshold
        disp('After Scalability: Delay is high → Additional Base Station REQUIRED');
    else
        disp('After Scalability: Delay is acceptable');
    end

    figure;
    visualize(pos, PrimaryPath2, BackupPath2, E, Edead, s, BS, 'After Scalability');
end

%% ---------------- ENERGY TABLE ----------------
disp('Final Energy Table:');
T = table((1:N)', E, 'VariableNames', {'Node','Energy'});
disp(T);

%% ---------------- RESULTS ----------------
fprintf('\n===== PERFORMANCE COMPARISON =====\n');

fprintf('Before Scalability:\n');
fprintf('Throughput = %.4f\n', throughput_before);
fprintf('Delay      = %.4f\n', delay_before);

fprintf('\nAfter Scalability:\n');

if choice == 1
    fprintf('Throughput = %.4f\n', throughput_after);
    fprintf('Delay      = %.4f\n', delay_after);
else
    fprintf('Not Applied\n');
end