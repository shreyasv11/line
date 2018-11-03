function [ez epx] = ETRBM(P,pd,d,n)
for k=1:d
    aux1 = P(:,k);
    [aux2 aux3]= sort(aux1);
    j=1;
    ez(j,k) =aux2(j);
    epx(j,k) =pd(aux3(j));
    for i=2:length(aux2);
        if aux2(i) == aux2(i-1);
           epx(j,k) = epx(j,k) + pd(aux3(i));
        else
           epx(j,k) = epx(j,k)/(aux2(i)-aux2(i-1)); %normalizing marginal
           j=j+1;
           epx(j,k) = pd(aux3(i));
           ez(j,k) =aux2(i);
        end
    end
    epx(length(epx(:,k)),k) = 0;   %normalizing marginal
end
