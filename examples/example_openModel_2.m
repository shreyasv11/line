fprintf(1,'This example shows a 1-line solution of a tandem open queueing network.\n');
D = [10,5; 5,9]; % S(i,r) - mean service time of class r at station i
A = [1,2]/20; % A(r) - arrival rate of class r
Z = [1,2;3,4]; % Z(r)  mean service time of class r at delay station i
SolverMVA(Network.tandemPsInf(A,D,Z)).getAvgTable
