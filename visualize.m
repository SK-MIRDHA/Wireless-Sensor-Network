function visualize(pos, PrimaryPath, BackupPath, E, Edead, s, BS, titleStr)

hold on;

alive = E > Edead;
dead  = E <= Edead;

% Alive nodes
h1 = scatter(pos(alive,1), pos(alive,2),50,'b','filled');

% Dead nodes
h2 = scatter(pos(dead,1), pos(dead,2),50,'r','filled');

% Node IDs
for i = 1:length(pos)
    text(pos(i,1)+1,pos(i,2)+1,num2str(i),'FontSize',7);
end

% Source
h3 = scatter(pos(s,1),pos(s,2),120,'g','filled');

% Base station
h4 = scatter(pos(BS,1),pos(BS,2),120,'k','filled');

%% ---- SAFE INITIALIZATION ----
h5 = plot(nan,nan,'k-','LineWidth',2);   % primary
h6 = plot(nan,nan,'k:','LineWidth',2);   % backup

%% ---- Primary Path ----
if length(PrimaryPath) > 1
    for i = 1:length(PrimaryPath)-1
        h5 = plot(pos(PrimaryPath(i:i+1),1), ...
                  pos(PrimaryPath(i:i+1),2), ...
                  'k-','LineWidth',2);
    end
end

%% ---- Backup Path ----
if length(BackupPath) > 1
    for i = 1:length(BackupPath)-1
        h6 = plot(pos(BackupPath(i:i+1),1), ...
                  pos(BackupPath(i:i+1),2), ...
                  'k:','LineWidth',2);
    end
end

%% ---- Legend ----
legend([h1 h2 h3 h4 h5 h6], ...
    {'Alive Nodes','Dead Nodes','Source','Base Station','Primary Path','Backup Path'});

title(titleStr);
grid on;
axis equal;

end
