function total_energy = compute_path_energy(path, pos, Etx, Efs)

if isempty(path) || length(path) < 2
    total_energy = Inf;
    return;
end

total_energy = 0;

for i = 1:length(path)-1
    d = norm(pos(path(i),:) - pos(path(i+1),:));
    total_energy = total_energy + (Etx + Efs*d^2);
end

end