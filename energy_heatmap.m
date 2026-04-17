function energy_heatmap(pos, E, titleStr)

figure;

scatter(pos(:,1),pos(:,2),60,E,'filled');

% Node numbering
for i = 1:size(pos,1)
    text(pos(i,1)+1,pos(i,2)+1,num2str(i), ...
        'FontSize',8,'Color','k','FontWeight','bold');
end

colorbar;
colormap jet;

title(titleStr);
xlabel('X Coordinate (m)');
ylabel('Y Coordinate (m)');

grid on;
axis equal;

end