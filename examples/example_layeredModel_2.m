model = LayeredNetwork('LQN1');

% definition of processors, tasks and entries
P1 = Processor(model, 'P1', 1, SchedStrategy.PS);
T1 = Task(model, 'T1', 1, SchedStrategy.REF).on(P1);
E1 = Entry(model, 'E1').on(T1);

P2 = Processor(model, 'P2', 1, SchedStrategy.PS);
T2 = Task(model, 'T2', 1, SchedStrategy.INF).on(P2);
E2 = Entry(model, 'E2').on(T2);

% definition of activities
T1.setThinkTime(Erlang.fitMeanAndOrder(10,2));

A1 = Activity(model, 'A1', Exp(1)).on(T1).boundTo(E1).synchCall(E2,3);
A2 = Activity(model, 'A2', Cox2.fitMoments(1,10)).on(T2).boundTo(E2).repliesTo(E2);

% instantiate solvers
options = SolverLQNS.defaultOptions;
options.keep = true;
options.verbose = 1;
%options.method = 'lqsim';
%options.samples = 1e4;
AvgTable = SolverLQNS(model, options).getAvgTable

lnoptions = SolverLN.defaultOptions;
lnoptions.verbose = 1;
AvgTable = SolverLN(model, @SolverNC, lnoptions).getAvgTable

AvgTableAdaptive = SolverLN(model, @(model) SolverAuto(model, SolverAuto.defaultOptions), lnoptions).getAvgTable

