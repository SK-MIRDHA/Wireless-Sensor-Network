function trust = compute_path_trust(path, Population)

if isempty(path)
    trust = 0;
    return;
end

trust_sum = 0;

for i = 1:length(path)
    row = Population(path(i),:);
    
    trust_node = 0.35*row(1) + ...
                 0.25*row(2) + ...
                 0.25*row(3) + ...
                 0.15*row(4);
             
    trust_sum = trust_sum + trust_node;
end

trust = trust_sum / length(path);

end