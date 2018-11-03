% To objective of this tests is just to establish if any of the solver
% returns different results compared to the earlier versions
verbose = 3;
usePara = true;
runtests('allTestsExamples','Verbosity', verbose,'UseParallel',false);
runtests('allTestsOpenQN','Verbosity', verbose,'UseParallel',usePara);
runtests('allTestsM2M','Verbosity', verbose,'UseParallel',usePara);
runtests('allTestsClosedQN','Verbosity', verbose,'UseParallel',usePara);
runtests('allTestsCS','Verbosity', verbose,'UseParallel',usePara);
runtests('allTestsMixedQN','Verbosity', verbose,'UseParallel',false);
