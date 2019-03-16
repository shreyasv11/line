function p_opt = example_manual_chap2_ex8()
model = Network('LoadBalCQN');
% Block 1: nodes
delay = Delay(model,'Think');
queue1 = Queue(model, 'Queue1', SchedStrategy.PS);
queue2 = Queue(model, 'Queue2', SchedStrategy.PS);
% Block 2: classes
cclass = ClosedClass(model, 'Job1', 16, delay);
delay.setService(cclass, Exp(1));
queue1.setService(cclass, Exp(0.75));
queue2.setService(cclass, Exp(0.50));
% Block 3: topology
P = zeros(3);
P(queue1, delay) = 1.0;
P(queue2, delay) = 1.0;

% Block 4: solution
    function R = objFun(p)
        P(delay, queue1) = p;
        P(delay, queue2) = 1-p;
        model.link(P);
        R = SolverMVA(model,'method','exact').getAvgSysRespT;
    end
p_opt = fminbnd(@(p) objFun(p), 0,1)

end