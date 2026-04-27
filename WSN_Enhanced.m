clc; clear; close all;

%% ---------------- LEVELS ----------------
area_levels = [100 120 130 150];
density_levels = [100 120 140 160];
range_levels = [0.2 0.25 0.3 0.35];
congestion_levels = [0.6 0.7 0.75 0.8];

% Default values
area = area_levels(1);
N = density_levels(1);

%% ---------------- USER SELECTION ----------------
disp('Choose Parameter:');
disp('1 Area | 2 Density | 3 Range | 4 Congestion');
param = input('Enter: ');

switch param
    
    case 1
        disp('Select Area Level:');
        for i = 1:length(area_levels)
            fprintf('%d -> %d\n', i, area_levels(i));
        end
        idx = input('Select option: ');
        area = area_levels(idx);
        
    case 2
        disp('Select Node Density:');
        for i = 1:length(density_levels)
            fprintf('%d -> %d nodes\n', i, density_levels(i));
        end
        idx = input('Select option: ');
        N = density_levels(idx);
end

fprintf('\nRunning with: Area=%d Nodes=%d\n',area,N);

%% ---------------- PARAMETERS ----------------
Emax = 5;
Edead = 0.2;

Etx = 0.02; Efs = 0.001; Erx = 0.01;

epochs = 20;
packet_rate = [1 2];
buffer_size = 8;

s = 1; 
BS = N;

%% ---------------- DEPLOY ----------------
pos = area * rand(N,2);
E = Emax * ones(N,1);
queue = cell(N,1);

all_paths_before = {};
all_paths_after  = {};

%% ================= BEFORE =================
delivered=0; total_packets=0;

for t=1:epochs
    
    newp=randi(packet_rate);
    total_packets=total_packets+newp;
    
    for k=1:newp
        pkt.current=s; pkt.path=s;
        queue{s}{end+1}=pkt;
    end
    
    Population = build_population(pos,E,N,BS);
    
    for i=1:N
        
        for p=1:min(2,length(queue{i}))
            
            if isempty(queue{i}), break; end
            pkt=queue{i}{1};
            
            if i==BS
                delivered=delivered+1;
                all_paths_before{end+1}=pkt.path;
                queue{i}(1)=[];
                continue;
            end
            
            Ni=find_neighbors(i,pos,E,Edead);
            if isempty(Ni), continue; end
            
            k_fire=min(4,length(Ni));
            fire_set=Ni(randperm(length(Ni),k_fire));
            
            best_score=-inf; selected=-1;
            
            for j=fire_set
                
                if norm(pos(j,:) - pos(BS,:)) > norm(pos(i,:) - pos(BS,:)) + 5
                    continue;
                end
                
                row=Population(j,:);
                score = 0.35*row(1)+0.25*rand()+0.25*row(3)+0.15*row(4);
                
                if score>best_score
                    best_score=score;
                    selected=j;
                end
            end
            
            if selected==-1
                [~,idx]=min(vecnorm(pos(Ni,:)-pos(BS,:),2,2));
                selected=Ni(idx);
            end
            
            d=norm(pos(i,:)-pos(selected,:));
            Ecost=Etx+Efs*d^2;
            
            if E(i)>=Ecost && E(selected)>=Erx
                E(i)=E(i)-Ecost;
                E(selected)=E(selected)-Erx;
                
                pkt.path=[pkt.path selected];
                queue{selected}{end+1}=pkt;
                queue{i}(1)=[];
            end
        end
    end
end

pos_old=pos;
E_before_final=E;

%% ---------------- BASELINE DISTANCE ----------------
d_baseline = norm(pos_old(s,:) - pos_old(BS,:));

%% ================= SCALABILITY =================
addN=40;

x_new=area+(area*0.5)*rand(addN,1);
y_new=area*rand(addN,1);

pos=[pos;[x_new y_new]];
N=size(pos,1);

E=[E_before_final; Emax*ones(addN,1)];
queue=cell(N,1);

%% ---------------- NEW SOURCE SELECTION (YOUR LOGIC) ----------------
theta = 40;   % 🔥 slightly relaxed for stability

new_nodes = (length(pos_old)+1):N;
valid_sources = [];

for i = new_nodes
    
    d_new = norm(pos(i,:) - pos(BS,:));
    
    if abs(d_new - d_baseline) < theta
        valid_sources = [valid_sources i];
    end
end

if ~isempty(valid_sources)
    s = valid_sources(randi(length(valid_sources)));
    fprintf('Selected NEW source node: %d\n', s);
else
    disp('No valid source found → fallback to original source');
    s = 1;
end

fprintf('Baseline Distance: %.2f\n', d_baseline);
fprintf('New Source Distance: %.2f\n', norm(pos(s,:) - pos(BS,:)));

%% ================= AFTER =================
delivered=0; total_packets=0;

for t=1:epochs
    
    newp=randi([2 3]);
    total_packets=total_packets+newp;
    
    for k=1:newp
        pkt.current=s; pkt.path=s;
        queue{s}{end+1}=pkt;
    end
    
    Population=build_population(pos,E,N,BS);
    
    for i=1:N
        
        for p=1:min(3,length(queue{i}))
            
            if isempty(queue{i}), break; end
            pkt=queue{i}{1};
            
            if i==BS
                delivered=delivered+1;
                all_paths_after{end+1}=pkt.path;
                queue{i}(1)=[];
                continue;
            end
            
            Ni=find_neighbors(i,pos,E,Edead);
            if isempty(Ni), continue; end
            
            k_fire=min(4,length(Ni));
            fire_set=Ni(randperm(length(Ni),k_fire));
            
            best_score=-inf; selected=-1;
            
            for j=fire_set
                
                if norm(pos(j,:) - pos(BS,:)) > norm(pos(i,:) - pos(BS,:)) + 5
                    continue;
                end
                
                row=Population(j,:);
                score=0.35*row(1)+0.25*rand()+0.25*row(3)+0.15*row(4);
                
                if score>best_score
                    best_score=score;
                    selected=j;
                end
            end
            
            if selected==-1
                [~,idx]=min(vecnorm(pos(Ni,:)-pos(BS,:),2,2));
                selected=Ni(idx);
            end
            
            d=norm(pos(i,:)-pos(selected,:));
            Ecost=Etx+Efs*d^2;
            
            if E(i)>=Ecost && E(selected)>=Erx
                E(i)=E(i)-Ecost;
                E(selected)=E(selected)-Erx;
                
                pkt.path=[pkt.path selected];
                queue{selected}{end+1}=pkt;
                queue{i}(1)=[];
            end
        end
    end
    
    PDR_after(t)=delivered/max(total_packets,1);
end

E_after_final=E;

%% ================= SAFE VISUALIZATION =================
visualize_single_path(pos_old,1,BS,all_paths_before{end},'Best Path Before');
visualize_paths(pos_old,1,BS,all_paths_before,'All Paths Before');

if ~isempty(all_paths_after)
    visualize_single_path(pos,s,BS,all_paths_after{end},'Best Path After');
    visualize_paths(pos,s,BS,all_paths_after,'All Paths After');
else
    disp('No paths in AFTER phase (network partially disconnected)');
end

energy_heatmap(pos_old,E_before_final,'Energy Before');
energy_heatmap(pos,E_after_final,'Energy After');