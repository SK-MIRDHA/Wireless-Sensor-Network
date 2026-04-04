clc; clear; close all;

%% ---------------- NETWORK PARAMETERS ----------------
N = 100;        % number of nodes
area = 100;     % deployment area

Emax = 5;       % max energy
Edead = 0.2;    % dead node threshold
Cmax = 1;       % max congestion

alpha = 0.6;    % energy weight
beta  = 0.4;    % congestion weight
theta = 0.3;    % threshold (adaptive filtering)
lambda = 0.05;  % reserved parameter
Etransmit = 0.05; % energy per transmission
delay_threshold = 15;   % threshold value (you can tune this)

r = 5;          
cr = 2*r;       
R = max(cr,25); % communication range

%% ---------------- INPUT ----------------
temp = input('Enter number of transmissions: ','s');
iterations = str2double(temp);

if isnan(iterations) || iterations <= 0
    iterations = 1;   % default
end

%% ---------------- NODE DEPLOYMENT ----------------
pos = area * rand(N,2);   % node positions
E = Emax * ones(N,1);     % energy
C = rand(N,1);            % node congestion
Cij = rand(N);            % link congestion

s = 1;    % source node
BS = N;   % base station

%% ---------------- ROUTING ----------------
[PrimaryPath, BackupPath, E] = routing(pos, E, C, Cij, N, s, BS, R, ...
    Emax, Edead, Cmax, alpha, beta, theta, lambda, Etransmit, iterations);
%-----------------under testing------------------
% ---- PERFORMANCE (BEFORE SCALABILITY) ----
packetSize = 1;     % per transmission
timePerHop = 1;     % constant delay

hops = length(PrimaryPath) - 1;

if PrimaryPath(end) == BS
    packetsDelivered = iterations;
else
    packetsDelivered = 0;
end

totalTime = hops * timePerHop * iterations;

throughput_before = packetsDelivered / totalTime;
delay_before = totalTime / max(packetsDelivered,1);

% ---------------under testing-----------------

figure;
visualize(pos, PrimaryPath, BackupPath, E, Edead, s, BS, 'Before Scalability');



%throughput_after = 0;
%delay_after = 0;
%% ---------------- SCALABILITY ----------------
temp = input('Do you want scalability? (1/0): ','s');
choice = str2double(temp);

if isnan(choice)
    choice = 0;
end

if choice == 1
    addN = 20;   % new nodes

    pos = [pos; area * rand(addN,2)];
    E = [E; Emax*ones(addN,1)];
    C = [C; rand(addN,1)];

    N = length(E);   % update node count
    Cij = rand(N);   % update link matrix

    disp('Scalability applied');

    [PrimaryPath2, BackupPath2, E] = routing(pos, E, C, Cij, N, s, BS, R, ...
        Emax, Edead, Cmax, alpha, beta, theta, lambda, Etransmit, iterations);

    %---------------under testing---------------

    % ---- PERFORMANCE (AFTER SCALABILITY) ----
    hops2 = length(PrimaryPath2) - 1;
    
    if PrimaryPath2(end) == BS
        packetsDelivered2 = iterations;
    else
        packetsDelivered2 = 0;
    end
    
    totalTime2 = hops2 * timePerHop * iterations;
    
    throughput_after = packetsDelivered2 / totalTime2;
    delay_after = totalTime2 / max(packetsDelivered2,1);

    % ---- DELAY CHECK (AFTER SCALABILITY) ----
if delay_after > delay_threshold
    disp('After Scalability: Delay is high → Additional Base Station REQUIRED');
else
    disp('After Scalability: Delay is acceptable → No new Base Station needed');
end

    %---------------under testing---------------

    figure;
    visualize(pos, PrimaryPath2, BackupPath2, E, Edead, s, BS, 'After Scalability');
end

%% ---------------- ENERGY TABLE ----------------
disp('Final Energy Table:');
T = table((1:N)', E, 'VariableNames', {'Node','Energy'});
disp(T);


%------------testing-----------
fprintf('\n===== PERFORMANCE COMPARISON =====\n');

fprintf('Before Scalability:\n');
fprintf('Throughput = %.4f\n', throughput_before);
fprintf('Delay      = %.4f\n', delay_before);

fprintf('\nAfter Scalability:\n');
fprintf('Throughput = %.4f\n', throughput_after);
fprintf('Delay      = %.4f\n', delay_after);