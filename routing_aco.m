% function path = routing_aco(pos, E, s, BS, Edead)
% 
% N = size(pos,1);
% pheromone = ones(N,1); % initial pheromone
% 
% alpha = 1;  % pheromone importance
% beta  = 2;  % distance importance
% 
% current = s;
% path = current;
% 
% while current ~= BS
% 
%     Ni = find_neighbors(current,pos,E,Edead);
% 
%     if isempty(Ni)
%         path = [];
%         return;
%     end
% 
%     probs = zeros(length(Ni),1);
% 
%     for k = 1:length(Ni)
%         j = Ni(k);
% 
%         tau = pheromone(j)^alpha;
%         eta = (1 / (norm(pos(j,:) - pos(BS,:)) + 1e-6))^beta;
% 
%         probs(k) = tau * eta;
%     end
% 
%     probs = probs / sum(probs);
% 
%     % roulette wheel selection
%     r = rand;
%     cum = cumsum(probs);
%     idx = find(cum >= r,1);
% 
%     next = Ni(idx);
% 
%     if ismember(next,path)
%         path = [];
%         return;
%     end
% 
%     path = [path next];
%     current = next;
% end
% 
% end

function path = routing_aco(pos, E, s, BS, Edead)

N = size(pos,1);
pheromone = ones(N,1);

alpha = 1;
beta = 3; % stronger distance influence

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
        
        d = norm(pos(j,:) - pos(BS,:));
        
        tau = pheromone(j)^alpha;
        eta = (1/(d + 1e-6))^beta;
        
        probs(k) = tau * eta;
    end
    
    % Normalize
    probs = probs / sum(probs);
    
    % Roulette selection
    r = rand;
    cum = cumsum(probs);
    idx = find(cum >= r,1);
    
    next = Ni(idx);
    
    % FIX 1: Prevent loops safely
    if ismember(next, path)
        Ni(idx) = [];   % remove that node
        
        if isempty(Ni)
            path = [];
            return;
        end
        
        next = Ni(randi(length(Ni))); % fallback random
    end
    
    % FIX 2: Force forward movement (important)
    if norm(pos(next,:) - pos(BS,:)) >= norm(pos(current,:) - pos(BS,:))
        % choose best forward node
        dists = vecnorm(pos(Ni,:) - pos(BS,:),2,2);
        [~, idx2] = min(dists);
        next = Ni(idx2);
    end
    
    path = [path next];
    current = next;
end

end