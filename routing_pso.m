function path = routing_pso(pos, E, s, BS, Edead)

current = s;
path = current;

while current ~= BS

    Ni = find_neighbors(current,pos,E,Edead);
    
    if isempty(Ni)
        path = [];
        return;
    end
    
    scores = zeros(length(Ni),1);
    
    for k = 1:length(Ni)
        j = Ni(k);
        
        dist_term = 1 / (norm(pos(j,:) - pos(BS,:)) + 1e-6);
        energy_term = E(j) / max(E);
        
        % PSO-like combination
        scores(k) = 0.6*dist_term + 0.4*energy_term;
    end
    
    [~, idx] = max(scores);
    next = Ni(idx);
    
    if ismember(next,path)
        path = [];
        return;
    end
    
    path = [path next];
    current = next;
end

end