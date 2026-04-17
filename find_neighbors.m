function Ni = find_neighbors(i, pos, E, Edead)

x_range = max(pos(:,1)) - min(pos(:,1));
y_range = max(pos(:,2)) - min(pos(:,2));

R = 0.25 * max(x_range, y_range);

N = length(E);
Ni = [];

for j = 1:N
    if j ~= i && E(j) > Edead
        if norm(pos(i,:) - pos(j,:)) <= R
            Ni = [Ni j];
        end
    end
end

end