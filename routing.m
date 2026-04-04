function [PrimaryPath, BackupPath, E] = routing( ...
    pos, E, C, Cij, N, s, BS, R, ...
    Emax, Edead, Cmax, alpha, beta, theta, lambda, Etransmit, iterations)

PrimaryPath = [];
BackupPath  = [];

for iter = 1:iterations
    
    %% ================= PRIMARY =================
    vi = s;
    tempPath = vi;
    visited = false(N,1);
    visited(vi) = true;

    while vi ~= BS
        
        %% ---- NEIGHBORS ----
        Ni = [];
        for j = 1:N
            if j ~= vi && E(j) > Edead && ~visited(j)
                if norm(pos(vi,:) - pos(j,:)) <= R
                    Ni = [Ni j];
                end
            end
        end
        
        if isempty(Ni)
            break;
        end
        
        %% ---- DEGREE ----
        degree = zeros(length(Ni),1);
        for k = 1:length(Ni)
            count = 0;
            for j = 1:N
                if j ~= Ni(k) && E(j) > Edead
                    if norm(pos(Ni(k),:) - pos(j,:)) <= R
                        count = count + 1;
                    end
                end
            end
            degree(k) = count;
        end
        
        %% ---- ADAPTATION ----
        Aj = alpha*(E(Ni)/Emax) + beta*(1 - C(Ni)/Cmax);
        theta_dynamic = 0.6 * max(Aj);
        
        valid = (Aj >= theta_dynamic) & (Cij(vi,Ni)' < Cmax);
        idx_valid = find(valid);
        
        if isempty(idx_valid)
            idx_valid = 1:length(Ni);
        end
        
        S2 = Ni(idx_valid);
        
        %% ---- SCORE (4 PARAMETERS) ----
        energyTerm = E(S2)/Emax;
        congestionTerm = 1 - Cij(vi,S2)'/Cmax;
        
        d = vecnorm(pos(S2,:) - pos(BS,:),2,2);
        distanceTerm = 1 ./ (d + 1e-6);
        distanceTerm = distanceTerm / (max(distanceTerm) + eps);
        
        deg = degree(idx_valid);
        degreeTerm = deg / (max(deg) + eps);
        
        Score = 0.35*energyTerm + 0.25*congestionTerm + ...
                0.25*distanceTerm + 0.15*degreeTerm;
        
        %% ---- SELECT BEST (FORWARD ONLY) ----
        [~, sortedIdx] = sort(Score,'descend');
        
        found = false;
        for k = 1:length(sortedIdx)
            candidate = S2(sortedIdx(k));
            
            if norm(pos(candidate,:) - pos(BS,:)) < norm(pos(vi,:) - pos(BS,:))
                v_next = candidate;
                found = true;
                break;
            end
        end
        
        if ~found
            break;
        end
        
        %% ---- MOVE ----
        vi = v_next;
        visited(vi) = true;
        tempPath = [tempPath vi];
        
        %% ---- ENERGY ----
        E(vi) = max(E(vi) - Etransmit,0);
    end
    
    PrimaryPath = tempPath;
    
    %% ================= BACKUP =================
    vi = s;
    tempBackup = vi;
    visited = false(N,1);
    visited(vi) = true;

    while vi ~= BS
        
        %% ---- NEIGHBORS ----
        Ni = [];
        for j = 1:N
            if j ~= vi && E(j) > Edead && ~visited(j)
                if norm(pos(vi,:) - pos(j,:)) <= R
                    Ni = [Ni j];
                end
            end
        end
        
        if isempty(Ni)
            break;
        end
        
        %% ---- DEGREE ----
        degree = zeros(length(Ni),1);
        for k = 1:length(Ni)
            count = 0;
            for j = 1:N
                if j ~= Ni(k) && E(j) > Edead
                    if norm(pos(Ni(k),:) - pos(j,:)) <= R
                        count = count + 1;
                    end
                end
            end
            degree(k) = count;
        end
        
        %% ---- ADAPTATION ----
        Aj = alpha*(E(Ni)/Emax) + beta*(1 - C(Ni)/Cmax);
        theta_dynamic = 0.6 * max(Aj);
        
        valid = (Aj >= theta_dynamic) & (Cij(vi,Ni)' < Cmax);
        idx_valid = find(valid);
        
        if isempty(idx_valid)
            idx_valid = 1:length(Ni);
        end
        
        S2 = Ni(idx_valid);
        
        %% ---- SCORE (SAME 4 PARAMETERS) ----
        energyTerm = E(S2)/Emax;
        congestionTerm = 1 - Cij(vi,S2)'/Cmax;
        
        d = vecnorm(pos(S2,:) - pos(BS,:),2,2);
        distanceTerm = 1 ./ (d + 1e-6);
        distanceTerm = distanceTerm / (max(distanceTerm) + eps);
        
        deg = degree(idx_valid);
        degreeTerm = deg / (max(deg) + eps);
        
        Score = 0.35*energyTerm + 0.25*congestionTerm + ...
                0.25*distanceTerm + 0.15*degreeTerm;
        
        %% ---- SELECT SECOND BEST WITH FALLBACK ----
        [~, sortedIdx] = sort(Score,'descend');
        
        found = false;
        
        % Try second-best onwards
        for k = 2:length(sortedIdx)
            candidate = S2(sortedIdx(k));
            
            if norm(pos(candidate,:) - pos(BS,:)) < norm(pos(vi,:) - pos(BS,:))
                v_next = candidate;
                found = true;
                break;
            end
        end
        
        % Fallback to best if needed
        if ~found
            for k = 1:length(sortedIdx)
                candidate = S2(sortedIdx(k));
                
                if norm(pos(candidate,:) - pos(BS,:)) < norm(pos(vi,:) - pos(BS,:))
                    v_next = candidate;
                    found = true;
                    break;
                end
            end
        end
        
        if ~found
            break;
        end
        
        %% ---- MOVE ----
        vi = v_next;
        visited(vi) = true;
        tempBackup = [tempBackup vi];
    end
    
    BackupPath = tempBackup;
end

end