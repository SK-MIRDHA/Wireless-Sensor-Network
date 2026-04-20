function path = routing_aodv(pos, E, s, BS, Edead)

Emax = max(E);
current = s;
path = current;

while current ~= BS

    Ni = find_neighbors(current, pos, E, Edead);

    if isempty(Ni)
        path = [];
        return;
    end

    scores = zeros(length(Ni),1);

    for k = 1:length(Ni)
        j = Ni(k);

        d = norm(pos(j,:) - pos(BS,:));
        energyTerm = E(j)/Emax;

        % Combined score (distance + energy)
        scores(k) = 0.7*(1/(d+1e-6)) + 0.3*energyTerm;
    end

    [~, idx] = max(scores);
    next = Ni(idx);

    if ismember(next, path)
        path = [];
        return;
    end

    path = [path next];
    current = next;
end

end