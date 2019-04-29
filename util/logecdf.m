function logecdf(S)
[F,X]=ecdf(S);
semilogx(X,F);
xlabel('x');
ylabel('F(x)');
end