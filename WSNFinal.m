clc; clear; close all;

%% ---------------- PARAMETERS ----------------
N = 100; 
area = 100;

Emax = 5;
Edead = 0.2;

Etx = 0.02;
Efs = 0.001;
Erx = 0.01;

epochs = 20;
packet_rate = [2 4];
buffer_size = 8;

BS = N;

%% TIME MODEL (WSN REALISTIC)
time_per_epoch = 0.025;   % 25 ms per epoch

%% ---------------- DEPLOY ----------------
pos = area * rand(N,2);
E = Emax * ones(N,1);

queue = cell(N,1);

queue_history_before = cell(epochs,1);
queue_history_after  = cell(epochs,1);

all_paths_before = {};
all_paths_after  = {};

%% SOURCE BEFORE
s_before = randi(N);

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
        pkt.current = s_before;
        pkt.path = s_before;
        queue{s_before}{end+1} = pkt;
    end
    
    Population = build_population(pos,E,N,BS);
    
    for i = 1:N
        
        for p = 1:min(1,length(queue{i}))   % congestion
            
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
                
                if length(queue{selected}) < buffer_size
                    queue{selected}{end+1} = pkt;
                end
                
                queue{i}(1) = [];
            end
        end
    end
    
    E(E < Edead) = 0;
    
    queue_history_before{t} = queue;
    
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

E = Emax * ones(N,1);
queue = cell(N,1);

%% SOURCE AFTER (ONLY FROM NEW AREA)
source_candidates = find(pos(:,1) >= 100 & pos(:,1) <= 150);
s_after = source_candidates(randi(length(source_candidates)));

%% ================= AFTER =================
PDR_after=zeros(epochs,1);
throughput_after=zeros(epochs,1);
energy_after_hist=zeros(epochs,1);
delay_after=zeros(epochs,1);

delivered=0; total_packets=0;

for t = 1:epochs
    
    newp = randi([2 4]);
    total_packets = total_packets + newp;
    
    for k = 1:newp
        pkt.current = s_after;
        pkt.path = s_after;
        queue{s_after}{end+1} = pkt;
    end
    
    Population = build_population(pos,E,N,BS);
    
    for i = 1:N
        
        for p = 1:min(1,length(queue{i}))
            
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
                
                if length(queue{selected}) < buffer_size
                    queue{selected}{end+1} = pkt;
                end
                
                queue{i}(1) = [];
            end
        end
    end
    
    E(E < Edead) = 0;
    
    queue_history_after{t} = queue;
    
    PDR_after(t)=delivered/max(total_packets,1);
    throughput_after(t)=delivered/t;
    energy_after_hist(t)=sum(E);
    delay_after(t)=mean(cellfun(@length,queue));
end

E_after_final = E;

%% CONVERT DELAY TO SECONDS
delay_before_sec = delay_before * time_per_epoch;
delay_after_sec  = delay_after  * time_per_epoch;

%% ================= VISUALIZATION =================
visualize_single_path(pos_old, s_before, BS, all_paths_before{end}, 'Best Path Before');
visualize_paths(pos_old, s_before, BS, all_paths_before, 'All Paths Before');

if ~isempty(all_paths_after)
    visualize_single_path(pos, s_after, BS, all_paths_after{end}, 'Best Path After');
    visualize_paths(pos, s_after, BS, all_paths_after, 'All Paths After');
end

%% ===== ANIMATION (BACKGROUND VIDEO) =====

% if ~isempty(all_paths_before)
%     animate_all_paths(pos_old, all_paths_before, s_before, BS, ...
%         'Packet Flow Before Scalability', 'before.avi');
% end
% 
% if ~isempty(all_paths_after)
%     animate_all_paths(pos_after, all_paths_after, s_after, BS, ...     
%         'Packet Flow After Scalability', 'after.avi');
% end
% 
% % Play videos in background (VERY IMPORTANT)
% if exist('before.avi','file')
%     winopen('before.avi');
% end
% 
% if exist('after.avi','file')
%     winopen('after.avi');
% end
%% ===========================================

energy_heatmap(pos_old, E_before_final, 'Energy Heatmap Before');
energy_heatmap(pos, E_after_final, 'Energy Heatmap After');

figure; plot(PDR_before);xlabel('Transmission Step (Epoch)');
ylabel('Packet Delivery Ratio (PDR)'); title('Packet Delivery Performance Over Time (Before Scalability)'); grid on;
figure; plot(PDR_after);xlabel('Transmission Step (Epoch)');
ylabel('Packet Delivery Ratio (PDR)'); title('Packet Delivery Performance Over Time (After Scalability)'); grid on;

figure; plot(throughput_before);xlabel('Transmission Step (Epoch)');ylabel('Successful Packet Flow Rate');
title(' Throughput Before Applying Scalability (Packets Successfully Reaching the Base Station Over Time)'); grid on;
figure; plot(throughput_after); xlabel('Transmission Step (Epoch)');ylabel('Successful Packet Flow Rate');
title(' Throughput After Applying Scalability (Packets Successfully Reaching the Base Station Over Time)'); grid on;

figure; plot(energy_before_hist); xlabel('Transmission Step (Epoch)');
ylabel('Total Residual Energy (Units)');
title('Residual Energy of Network Over Time (Before Scalability)'); grid on;
figure; plot(energy_after_hist); xlabel('Transmission Step (Epoch)');
ylabel('Total Residual Energy (Units)');
title('Residual Energy of Network Over Time (After Scalability)'); grid on;

figure; plot(delay_before); xlabel('Transmission Step (Epoch)');
ylabel('Average Packet Delay (Queue Length)');
title('Network Delay Over Time (Before Scalability)'); grid on;
figure; plot(delay_after); xlabel('Transmission Step (Epoch)');
ylabel('Average Packet Delay (Queue Length)');
title('Network Delay Over Time (After Scalability)'); grid on;

%% ENERGY LOSS
baseline_energy = energy_before_hist(1);

loss_before = (energy_before_hist(1)-energy_before_hist(end))/baseline_energy*100;
loss_after  = (energy_after_hist(1)-energy_after_hist(end))/baseline_energy*100;

%figure;
%bar([loss_before loss_after]);
%set(gca,'XTickLabel',{'Before','After'});
%title('Energy Loss Comparison');
%grid on;

figure;
bar([loss_before loss_after]);

set(gca,'XTickLabel',{'Before','After'});
ylabel('Energy Loss (%)');

title('Percentage Energy Loss Comparison');

% Add values on top
text(1, loss_before, sprintf('%.2f%%', loss_before), ...
    'HorizontalAlignment','center','VerticalAlignment','bottom');

text(2, loss_after, sprintf('%.2f%%', loss_after), ...
    'HorizontalAlignment','center','VerticalAlignment','bottom');

grid on;

figure;
plot(energy_before_hist,'LineWidth',2); hold on;
plot(energy_after_hist,'LineWidth',2);

legend('Before','After');
title('Energy Decay Over Time');
xlabel('Epoch');
ylabel('Residual Energy');
grid on;


%% Delay Output
%% ===== AVERAGE DELAY =====
avg_delay_before = mean(delay_before);
avg_delay_after  = mean(delay_after);

fprintf('\n===== AVERAGE DELAY =====\n');
fprintf('Before: %.4f\n', avg_delay_before);
fprintf('After : %.4f\n', avg_delay_after);

%% ===== AVERAGE DELAY (SECONDS) =====
avg_delay_before_sec = mean(delay_before_sec);
avg_delay_after_sec  = mean(delay_after_sec);

fprintf('\n===== AVERAGE DELAY (SECONDS) =====\n');
fprintf('Before: %.4f sec\n', avg_delay_before_sec);
fprintf('After : %.4f sec\n', avg_delay_after_sec);


figure;

yyaxis left
plot(delay_before,'-o','LineWidth',2); hold on;
plot(delay_after,'-s','LineWidth',2);
ylabel('Delay (Queue Length / Hops)');

yyaxis right
plot(delay_before_sec,'--o','LineWidth',2);
plot(delay_after_sec,'--s','LineWidth',2);
ylabel('Delay (Seconds)');

xlabel('Epoch');

title('Delay Comparison: Hops vs Time');

legend('Before (Hops)','After (Hops)', ...
       'Before (Sec)','After (Sec)', ...
       'Location','northwest');

grid on;

fprintf('\n===== PATH TRUST VALUES (BEFORE) =====\n');

for p = 1:length(all_paths_before)
    
    path = all_paths_before{p};
    trust_sum = 0;
    
    for k = 1:length(path)
        node = path(k);
        
        % recompute population for final state
        row = build_population(pos_old, E_before_final, length(pos_old), BS);
        
        trust_node = 0.35*row(node,1) + ...
                     0.25*row(node,2) + ...
                     0.25*row(node,3) + ...
                     0.15*row(node,4);
                 
        trust_sum = trust_sum + trust_node;
    end
    
    trust_path = trust_sum / length(path);
    
    fprintf('Path %d Trust = %.4f\n', p, trust_path);
end

fprintf('\n===== PATH TRUST VALUES (AFTER) =====\n');

for p = 1:length(all_paths_after)
    
    path = all_paths_after{p};
    trust_sum = 0;
    
    for k = 1:length(path)
        node = path(k);
        
        row = build_population(pos, E_after_final, length(pos), BS);
        
        trust_node = 0.35*row(node,1) + ...
                     0.25*row(node,2) + ...
                     0.25*row(node,3) + ...
                     0.15*row(node,4);
                 
        trust_sum = trust_sum + trust_node;
    end
    
    trust_path = trust_sum / length(path);
    
    fprintf('Path %d Trust = %.4f\n', p, trust_path);
end

% ================================
% COMPARISON WITH AODV + ACO + PSO
% ================================

disp('===== COMPARISON ROUTING =====');

% ---- ROUTING ----
path_aodv = routing_aodv(pos, E, s_after, BS, Edead);
path_aco  = routing_aco(pos, E, s_after, BS, Edead);
path_pso  = routing_pso(pos, E, s_after, BS, Edead);

% Your proposed path
best_path_after = all_paths_after{end};

% ---- VISUALIZATION ----
if ~isempty(path_aodv)
    visualize_single_path(pos,s_after,BS,path_aodv,'AODV Path');
end

if ~isempty(path_aco)
    visualize_single_path(pos,s_after,BS,path_aco,'ACO Path');
end

if ~isempty(path_pso)
    visualize_single_path(pos,s_after,BS,path_pso,'PSO Path');
end

visualize_single_path(pos,s_after,BS,best_path_after,'Proposed Path');

% ================================
% METRICS
% ================================

% ---- DELAY ----
delay_aodv = get_delay(path_aodv);
delay_aco  = get_delay(path_aco);
delay_pso  = get_delay(path_pso);
delay_prop = get_delay(best_path_after);

fprintf('\n===== DELAY (HOPS) =====\n');
fprintf('AODV: %d\n', delay_aodv);
fprintf('ACO: %d\n', delay_aco);
fprintf('PSO: %d\n', delay_pso);
fprintf('Proposed: %d\n', delay_prop);

% ---- PATHS ----
fprintf('\n===== PATHS =====\n');
disp('AODV:'); disp(path_aodv);
disp('ACO:'); disp(path_aco);
disp('PSO:'); disp(path_pso);
disp('Proposed:'); disp(best_path_after);

% ---- TRUST ----
Population_cmp = build_population(pos, E, length(pos), BS);

trust_aodv = compute_path_trust(path_aodv, Population_cmp);
trust_aco  = compute_path_trust(path_aco, Population_cmp);
trust_pso  = compute_path_trust(path_pso, Population_cmp);
trust_prop = compute_path_trust(best_path_after, Population_cmp);

% fprintf('\n===== TRUST =====\n');
% fprintf('AODV: %.4f\n', trust_aodv);
% fprintf('ACO: %.4f\n', trust_aco);
% fprintf('PSO: %.4f\n', trust_pso);
% fprintf('Proposed: %.4f\n', trust_prop);

% ---- ENERGY ----
energy_aodv = compute_path_energy(path_aodv, pos, Etx, Efs);
energy_aco  = compute_path_energy(path_aco, pos, Etx, Efs);
energy_pso  = compute_path_energy(path_pso, pos, Etx, Efs);
energy_prop = compute_path_energy(best_path_after, pos, Etx, Efs);

% fprintf('\n===== ENERGY =====\n');
% fprintf('AODV: %.4f\n', energy_aodv);
% fprintf('ACO: %.4f\n', energy_aco);
% fprintf('PSO: %.4f\n', energy_pso);
% fprintf('Proposed: %.4f\n', energy_prop);

% function d = get_delay(path)
% 
% if isempty(path)
%     d = Inf;
% else
%     d = length(path);
% end
% 
% end

% function trust = compute_path_trust(path, Population)
% 
% if isempty(path)
%     trust = 0;
%     return;
% end
% 
% trust_sum = 0;
% 
% for i = 1:length(path)
%     row = Population(path(i),:);
% 
%     trust_node = 0.35*row(1) + ...
%                  0.25*row(2) + ...
%                  0.25*row(3) + ...
%                  0.15*row(4);
% 
%     trust_sum = trust_sum + trust_node;
% end
% 
% trust = trust_sum / length(path);
% 
% end

% function total_energy = compute_path_energy(path, pos, Etx, Efs)
% 
% if isempty(path) || length(path) < 2
%     total_energy = Inf;
%     return;
% end
% 
% total_energy = 0;
% 
% for i = 1:length(path)-1
%     d = norm(pos(path(i),:) - pos(path(i+1),:));
%     total_energy = total_energy + (Etx + Efs*d^2);
% end
% 
% end


% ================================
% FAIR COMPARISON (MULTI-TRIAL)
% ================================

disp('===== FAIR COMPARISON =====');

num_trials = 20;
N = length(E);

% Storage
delay_aodv = zeros(num_trials,1);
delay_aco  = zeros(num_trials,1);
delay_pso  = zeros(num_trials,1);

energy_aodv = zeros(num_trials,1);
energy_aco  = zeros(num_trials,1);
energy_pso  = zeros(num_trials,1);

trust_aodv = zeros(num_trials,1);
trust_aco  = zeros(num_trials,1);
trust_pso  = zeros(num_trials,1);

% Population for trust
Population_cmp = build_population(pos, E, N, BS);

for t = 1:num_trials
    
    % random source to introduce variability
    s_rand = randi(N);
    
    % ---- ROUTES ----
    path_aodv = routing_aodv(pos, E, s_rand, BS, Edead);
    path_aco  = routing_aco(pos, E, s_rand, BS, Edead);
    path_pso  = routing_pso(pos, E, s_rand, BS, Edead);
    
    % ---- DELAY ----
    delay_aodv(t) = get_delay(path_aodv);
    delay_aco(t)  = get_delay(path_aco);
    delay_pso(t)  = get_delay(path_pso);
    
    % ---- ENERGY ----
    energy_aodv(t) = compute_path_energy(path_aodv, pos, Etx, Efs);
    energy_aco(t)  = compute_path_energy(path_aco, pos, Etx, Efs);
    energy_pso(t)  = compute_path_energy(path_pso, pos, Etx, Efs);
    
    % ---- TRUST ----
    trust_aodv(t) = compute_path_trust(path_aodv, Population_cmp);
    trust_aco(t)  = compute_path_trust(path_aco, Population_cmp);
    trust_pso(t)  = compute_path_trust(path_pso, Population_cmp);
    
end

% ================================
% PROPOSED (YOUR METHOD)
% ================================

delays_prop = cellfun(@get_delay, all_paths_after);
energy_prop = cellfun(@(p) compute_path_energy(p,pos,Etx,Efs), all_paths_after);
trust_prop  = cellfun(@(p) compute_path_trust(p,Population_cmp), all_paths_after);

% ================================
% FINAL AVERAGES
% ================================

fprintf('\n===== AVERAGE RESULTS =====\n');

fprintf('\n--- DELAY (HOPS) ---\n');
fprintf('AODV: %.2f\n', mean(delay_aodv));
fprintf('ACO : %.2f\n', mean(delay_aco));
fprintf('PSO : %.2f\n', mean(delay_pso));
fprintf('PROP: %.2f\n', mean(delays_prop));

fprintf('\n--- ENERGY ---\n');
fprintf('AODV: %.4f\n', mean(energy_aodv));
fprintf('ACO : %.4f\n', mean(energy_aco));
fprintf('PSO : %.4f\n', mean(energy_pso));
fprintf('PROP: %.4f\n', mean(energy_prop));

fprintf('\n--- TRUST ---\n');
fprintf('AODV: %.4f\n', mean(trust_aodv));
fprintf('ACO : %.4f\n', mean(trust_aco));
fprintf('PSO : %.4f\n', mean(trust_pso));
fprintf('PROP: %.4f\n', mean(trust_prop));