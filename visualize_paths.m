function visualize_paths(pos, s, BS, paths, titleStr)

figure; hold on;

scatter(pos(:,1),pos(:,2),40,'b','filled');

% Source
scatter(pos(s,1),pos(s,2),150,'g','filled');
text(pos(s,1)+2,pos(s,2)+2,'SOURCE','Color','g','FontWeight','bold');

% Base Station
scatter(pos(BS,1),pos(BS,2),150,'k','filled');
text(pos(BS,1)+2,pos(BS,2)+2,'BS','Color','k','FontWeight','bold');

% Node numbering
for i = 1:size(pos,1)
    text(pos(i,1)+1,pos(i,2)+1,num2str(i),'FontSize',8);
end

% Paths
for k = 1:length(paths)
    p = paths{k};
    for i = 1:length(p)-1
        plot(pos(p(i:i+1),1),pos(p(i:i+1),2),'LineWidth',2);
    end
end

title(titleStr);
grid on;
axis equal;

end