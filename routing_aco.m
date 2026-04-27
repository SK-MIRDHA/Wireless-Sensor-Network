function path = routing_aco(pos, E, s, BS, Edead)

N = size(pos,1);
pheromone = ones(N,1); % initial pheromone

alpha = 1;  % pheromone importance
beta  = 2;  % distance importance

current = s;
path = current;

while current ~= BS

    Ni = find_neighbors(current,pos,E,Edead);
    
    if isempty(Ni)
        path = [];
        return;
    end
    
    probs = zeros(length(Ni),1);
    
    for k = 1:length(Ni)
        j = Ni(k);
        
        tau = pheromone(j)^alpha;
        eta = (1 / (norm(pos(j,:) - pos(BS,:)) + 1e-6))^beta;
        
        probs(k) = tau * eta;
    end
    
    probs = probs / sum(probs);
    
    % roulette wheel selection
    r = rand;
    cum = cumsum(probs);
    idx = find(cum >= r,1);
    
    next = Ni(idx);
    
    if ismember(next,path)
        path = [];
        return;
    end
    
    path = [path next];
    current = next;
end

end