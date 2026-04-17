function Population = build_population(pos, E, N, BS)

Emax = max(E);
dmax = max(vecnorm(pos - pos(BS,:),2,2));

Population = zeros(N,4);

for i = 1:N
    energyTerm = E(i)/Emax;

    d = norm(pos(i,:) - pos(BS,:));
    distanceTerm = 1 - (d / dmax);

    Population(i,:) = [energyTerm, 1, distanceTerm, 1];
end

end