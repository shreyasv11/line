function d = cellmerge(c)
d = c{1};
for i=2:length(c)
    d(end+1:end+length(c{i}))=c{i};
end
end