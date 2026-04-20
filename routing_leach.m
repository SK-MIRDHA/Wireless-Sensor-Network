function path = routing_leach(pos, E, s, BS, Edead)

N = length(E);
Emax = max(E);

% ---- Step 1: Select Cluster Heads ----
p = 0.2; % probability
CH = [];

for i = 1:N
    if rand < p*(E(i)/Emax)
        CH = [CH i];
    end
end

% fallback
if isempty(CH)
    [~, idx] = max(E);
    CH = idx;
end

% ---- Step 2: Source → nearest CH ----
d = vecnorm(pos(CH,:) - pos(s,:),2,2);
[~, i] = min(d);
current = CH(i);

path = [s current];

% ---- Step 3: CH → BS (multi-hop via CH) ----
while current ~= BS

    Ni = intersect(CH, find_neighbors(current,pos,E,Edead));

    if isempty(Ni)
        path = [];
        return;
    end

    dists = vecnorm(pos(Ni,:) - pos(BS,:),2,2);
    [~, i] = min(dists);
    next = Ni(i);

    if ismember(next, path)
        path = [];
        return;
    end

    path = [path next];
    current = next;
end

end