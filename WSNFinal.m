clc; clear; close all;

%% ---------------- PARAMETERS ----------------
N = 100; 
area = 100;

Emax = 5;
Edead = 0.2;

Etx = 0.02;       % Transmission energy
Efs = 0.001;      % Free space amplification factor(Distance-Based Amplification)
Erx = 0.01;       % Reception energy

epochs = 20;
packet_rate = [1 2];
buffer_size = 8;

s = 1; 
BS = N;   % FIXED BASE STATION

%% ---------------- DEPLOY ----------------
pos = area * rand(N,2);
E = Emax * ones(N,1);

queue = cell(N,1);

all_paths_before = {};
all_paths_after  = {};

%% METRICS
PDR_before = zeros(epochs,1);
throughput_before = zeros(epochs,1);
energy_before_hist = zeros(epochs,1);
delay_before = zeros(epochs,1);

delivered = 0; total_packets = 0;

%% ================= BEFORE =================
for t = 1:epochs
    
    newp = randi(packet_rate);
    total_packets = total_packets + newp;
    
    for k = 1:newp
        pkt.current = s; pkt.path = s;
        queue{s}{end+1} = pkt;
    end
    
    Population = build_population(pos,E,N,BS);
    
    for i = 1:N
        
        for p = 1:min(2,length(queue{i}))
            
            if isempty(queue{i}), break; end
            pkt = queue{i}{1};
            
            if i == BS
                delivered = delivered + 1;
                all_paths_before{end+1} = pkt.path;
                queue{i}(1) = [];
                continue;
            end
            
            Ni = find_neighbors(i,pos,E,Edead);
            if isempty(Ni), continue; end
            
            %  Forest Fire Selection
            k_fire = min(4,length(Ni));
            fire_set = Ni(randperm(length(Ni),k_fire));
            
            best_score = -inf;
            selected = -1;
            
            for j = fire_set
                
                if norm(pos(j,:) - pos(BS,:)) > norm(pos(i,:) - pos(BS,:)) + 5
                    continue;
                end
                
                row = Population(j,:);
                
                score = 0.35*row(1) + ...
                        0.25*rand() + ...
                        0.25*row(3) + ...
                        0.15*row(4);
                    
                if score > best_score
                    best_score = score;
                    selected = j;
                end
            end
            
            if selected == -1
                [~,idx] = min(vecnorm(pos(Ni,:) - pos(BS,:),2,2));
                selected = Ni(idx);
            end
            
            d = norm(pos(i,:) - pos(selected,:));
            Ecost = Etx + Efs*d^2;
            
            if E(i)>=Ecost && E(selected)>=Erx
                E(i)=E(i)-Ecost;
                E(selected)=E(selected)-Erx;
                
                pkt.current = selected;
                pkt.path = [pkt.path selected];
                
                queue{selected}{end+1} = pkt;
                queue{i}(1) = [];
            end
        end
    end
    
    E(E < Edead) = 0;
    
    PDR_before(t)=delivered/max(total_packets,1);
    throughput_before(t)=delivered/t;
    energy_before_hist(t)=sum(E);
    delay_before(t)=mean(cellfun(@length,queue));
end

pos_old = pos;
E_before_final = E;

%% ================= LATERAL SCALABILITY =================
addN = 40;

x_new = area + (area*0.5)*rand(addN,1);
y_new = area * rand(addN,1);

pos = [pos; [x_new y_new]];
N = size(pos,1);

%  BS DOES NOT CHANGE
% BS = 100 (same as before)

E = Emax * ones(N,1);
queue = cell(N,1);

PDR_after=zeros(epochs,1);
throughput_after=zeros(epochs,1);
energy_after_hist=zeros(epochs,1);
delay_after=zeros(epochs,1);

delivered=0; total_packets=0;

%% ================= AFTER =================
for t = 1:epochs
    
    newp = randi([2 3]);
    total_packets = total_packets + newp;
    
    for k = 1:newp
        pkt.current = s; pkt.path = s;
        queue{s}{end+1} = pkt;
    end
    
    Population = build_population(pos,E,N,BS);
    
    for i = 1:N
        
        for p = 1:min(3,length(queue{i}))
            
            if isempty(queue{i}), break; end
            pkt = queue{i}{1};
            
            if i == BS
                delivered = delivered + 1;
                all_paths_after{end+1} = pkt.path;
                queue{i}(1) = [];
                continue;
            end
            
            Ni = find_neighbors(i,pos,E,Edead);
            if isempty(Ni), continue; end
            
            k_fire = min(4,length(Ni));
            fire_set = Ni(randperm(length(Ni),k_fire));
            
            best_score = -inf;
            selected = -1;
            
            for j = fire_set
                
                if norm(pos(j,:) - pos(BS,:)) > norm(pos(i,:) - pos(BS,:)) + 5
                    continue;
                end
                
                row = Population(j,:);
                
                score = 0.35*row(1) + ...
                        0.25*rand() + ...
                        0.25*row(3) + ...
                        0.15*row(4);
                    
                if score > best_score
                    best_score = score;
                    selected = j;
                end
            end
            
            if selected == -1
                [~,idx] = min(vecnorm(pos(Ni,:) - pos(BS,:),2,2));
                selected = Ni(idx);
            end
            
            d = norm(pos(i,:) - pos(selected,:));
            Ecost = Etx + Efs*d^2;
            
            if E(i)>=Ecost && E(selected)>=Erx
                E(i)=E(i)-Ecost;
                E(selected)=E(selected)-Erx;
                
                pkt.current = selected;
                pkt.path = [pkt.path selected];
                
                queue{selected}{end+1} = pkt;
                queue{i}(1) = [];
            end
        end
    end
    
    E(E < Edead) = 0;
    
    PDR_after(t)=delivered/max(total_packets,1);
    throughput_after(t)=delivered/t;
    energy_after_hist(t)=sum(E);
    delay_after(t)=mean(cellfun(@length,queue));
end

E_after_final = E;

%% ================= VISUALIZATION =================
visualize_single_path(pos_old, s, BS, all_paths_before{end}, 'Best Path Before');
visualize_single_path(pos, s, BS, all_paths_after{end}, 'Best Path After');

visualize_paths(pos_old, s, BS, all_paths_before, 'All Paths Before');
visualize_paths(pos, s, BS, all_paths_after, 'All Paths After');

energy_heatmap(pos_old, E_before_final, 'Energy Heatmap Before');
energy_heatmap(pos, E_after_final, 'Energy Heatmap After');

figure; plot(PDR_before); title('PDR Before'); grid on;
figure; plot(PDR_after); title('PDR After'); grid on;

figure; plot(throughput_before); title('Throughput Before'); grid on;
figure; plot(throughput_after); title('Throughput After'); grid on;

figure; plot(energy_before_hist); title('Energy Before'); grid on;
figure; plot(energy_after_hist); title('Energy After'); grid on;

figure; plot(delay_before); title('Delay Before'); grid on;
figure; plot(delay_after); title('Delay After'); grid on;

%% ENERGY LOSS
baseline_energy = energy_before_hist(1);

loss_before = (energy_before_hist(1)-energy_before_hist(end))/baseline_energy*100;
loss_after  = (energy_after_hist(1)-energy_after_hist(end))/baseline_energy*100;

figure;
bar([loss_before loss_after]);
set(gca,'XTickLabel',{'Before','After'});
title('Energy Loss Comparison');
grid on;