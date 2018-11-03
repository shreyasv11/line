
% Getting started example from the LINE documentation
model = Network('pf3');

station{1} = DelayStation(model, 'Delay');
station{2} = Queue(model, 'QueueRepairman3', SchedStrategy.DPS);

N1 = 2; jobclass{1} = ClosedClass(model, 'MachinesA', N1, station{1});
N2 = 2; jobclass{2} = ClosedClass(model, 'MachinesB', N2, station{1});

M = model.getNumberOfStations();
K = model.getNumberOfClasses();
rate = [10,10; 2,1; 1,2];
%rate = rand(size(rate));
weight = [2,1];
for i=1:M
    for r=1:K
        station{i}.setService(jobclass{r}, Exp(rate(i,r)), weight(i));
    end
end


r = rand;
RT{1} = circul(M)*r+circul(M)'*(1-r); % type-A
RT{2} = circul(M); % type-B
model.link(station, jobclass, RT);

options.verbose=1;
msolver=MetaSolverPF(model,@SolverCTMC,options);
msolver.getMargProb([N1,N2;0,0])