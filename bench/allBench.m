w=warning;
warning off
verbose = 1;

runtests('allBenchCQN_PS','Verbosity', verbose); % evaluate multiclass product-form models
runtests('allBenchCQN_FCFS','Verbosity', verbose); % evaluate multiclass FCFS approximations

warning(w);