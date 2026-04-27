function d = get_delay(path)

if isempty(path)
    d = Inf;
else
    d = length(path);
end

end