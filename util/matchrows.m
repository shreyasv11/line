function I = matchrows(matrix, rows)
I = zeros(size(rows,1),1);
for i=1:size(rows,1)
	I(i) = matchrow(matrix,rows(i,:));
end
end
