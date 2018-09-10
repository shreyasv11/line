model = Network('model');

source = Source(model, 'Source');
lb = LoadBalancer(model, 'LB');
queue1 = Queue(model, 'Queue1', SchedStrategy.PS);
queue2 = Queue(model, 'Queue2', SchedStrategy.PS);
sink  = Sink(model, 'Sink');

oclass = OpenClass(model, 'Class1');
source.setArrival(oclass, Exp(1));
queue1.setService(oclass, Exp(2));
queue2.setService(oclass, Exp(2));

model.addLinks([source, lb; 
                lb,     queue1; 
                lb,     queue2; 
                queue1, sink; 
                queue2, sink]);
            
lb.setRouting(oclass, RoutingStrategy.RAND);
SolverJMT(model).getAvgTable

lb.setRouting(oclass, RoutingStrategy.RR);
model.reset();
SolverJMT(model).getAvgTable