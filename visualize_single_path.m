function visualize_single_path(pos, s, BS, path, titleStr)

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
    text(pos(i,1)+1,pos(i,2)+1,num2str(i),'FontSize',8,'Color','k');
end

% Path
for i = 1:length(path)-1
    plot(pos(path(i:i+1),1),pos(path(i:i+1),2),'k','LineWidth',3);
end

title(titleStr);
grid on;
axis equal;

end