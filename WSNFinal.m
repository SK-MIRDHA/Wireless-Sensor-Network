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