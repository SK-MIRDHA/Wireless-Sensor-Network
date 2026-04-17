function fitness = compute_fitness(Pop)

k = size(Pop,1);
fitness = zeros(k,1);

for i = 1:k
    row = Pop(i,:);
    fitness(i) = 0.35*row(1) + ...
                 0.25*row(2) + ...
                 0.25*row(3) + ...
                 0.15*row(4);
end

end