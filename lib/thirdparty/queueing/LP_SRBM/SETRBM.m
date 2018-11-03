function spx = SETRBM(epx,d)
for k=1:d
    x = length(epx(:,k));
    spx(1,k) = (2/3)*epx(1,k) + (1/3)*epx(2,k);
    for i=2:x-1
        spx(i,k) = (1/3)*epx(i-1,k) + (1/3)*epx(i,k) + (1/3)*epx(i+1,k);  
    end
    spx(x,k) = (2/3)*epx(x,k) + (1/3)*epx(x-1,k);
end