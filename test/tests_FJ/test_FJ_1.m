% Getting started example from the LINE documentation
model = Network('fjTest1');

station{1} = Source(model, 'Source');
station{2} = Queue(model, 'Queue1', SchedStrategy.PS);
station{3} = ForkStation(model, 'Fork1');
station{4} = Queue(model, 'Queue2', SchedStrategy.PS);
station{5} = Sink(model, 'Sink');

jobclass{1} = OpenClass(model, 'Class1');

station{1}.setArrival(jobclass{1},Exp(0.5));
station{2}.setService(jobclass{1},Exp(1));

model.addLink(station{1},station{2});
model.addLink(station{2},station{3});
model.addLink(station{3},station{4});
model.addLink(station{3},station{5});
model.addLink(station{4},station{5});

station{1}.setProbRouting(jobclass{1}, station{2}, 1.0);
station{2}.setProbRouting(jobclass{1}, station{3}, 1.0);
station{3}.setProbRouting(jobclass{1}, station{4}, 1.0);
station{3}.setProbRouting(jobclass{1}, station{5}, 1.0);
station{4}.setProbRouting(jobclass{1}, station{5}, 1.0);

