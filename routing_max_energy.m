
function path = routing_max_energy(pos, E, s, BS, Edead)

current = s;
path = current;

while current ~= BS

    Ni = find_neighbors(current,pos,E,Edead);
    
    if isempty(Ni)
        path = [];
        return;
    end
    
    [~, idx] = max(E(Ni));
    next = Ni(idx);
    
    if ismember(next, path)
        path = [];
        return;
    end
    
    path = [path next];
    current = next;
end

end