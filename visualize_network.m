function visualize_network(pos, E, Edead, s, BS, queue, titleStr, path)

figure; hold on;

alive = E > Edead;
dead = E <= Edead;

scatter(pos(alive,1), pos(alive,2),50,'b','filled');
scatter(pos(dead,1), pos(dead,2),50,'r','filled');

scatter(pos(s,1),pos(s,2),120,'g','filled');
scatter(pos(BS,1),pos(BS,2),120,'k','filled');

for i = 1:length(pos)
    label = sprintf('%d(%d)', i, length(queue{i}));
    text(pos(i,1)+1,pos(i,2)+1,label,'FontSize',7);
end

% DRAW PATH
if ~isempty(path) && length(path) > 1
    for i = 1:length(path)-1
        plot(pos(path(i:i+1),1), pos(path(i:i+1),2), 'k-','LineWidth',2);
    end
end

legend('Alive','Dead','Source','Base Station','Path');
title(titleStr);
grid on;
axis equal;

end