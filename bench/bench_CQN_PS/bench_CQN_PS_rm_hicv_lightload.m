%clear
simFileName = [mfilename('fullpath'),'.mat']; try load(simFileName); needSim = 0; catch needSim = 1; end
iters = 1:10;
for it=iters
    % Getting started example from the LINE documentation
    model = Network('model');
    
    station{1} = DelayStation(model, 'Delay');
    station{2} = Queue(model, 'Queue1', SchedStrategy.PS);
    
    N1 = 5; jobclass{1} = ClosedClass(model, 'ClassA', N1, station{1});
    N2 = 5; jobclass{2} = ClosedClass(model, 'ClassB', N2, station{1});
    
    rate = randgallery(2,2,it);
    for i=1:2
        for r=1:2
            station{i}.setService(jobclass{r}, HyperExp.fitMeanAndSCV(1/rate(i,r),10));
        end
        if i>1
            station{i}.setNumServers(1);
        end
    end
    
    P{1} = circul(2);
    P{2} = circul(2);
    model.link(P);
    
    options = Solver.defaultOptions;
    options.seed = 23000;
    options.verbose = 0; optionsnc = options; optionsnc.samples = 1e6;
    jmtoptions = options;
    jmtoptions.samples = 1e6;
    %    options.keep = 1
    if needSim
        simsolver = SolverJMT(model,jmtoptions);     
        [QNsim{it},UNsim{it},RNsim{it},TNsim{it}] = simsolver.getAvg();
        if it==iters(end)
            save(simFileName, 'QNsim','UNsim','RNsim','TNsim');
        end
    end
    
    solver = {};
    results = {};
    runtime = {};
    solver{1} = SolverFluid(model,options);
    solver{2} = SolverMVA(model,options);
    solver{3} = SolverNC(model,optionsnc);
    for s=1:length(solver)        
        [QN{it,s},UN{it,s},RN{it,s},TN{it,s}] = solver{s}.getAvg();
        ERRQ(it,s) = maxerronsum(QN{it,s},QNsim{it});
        ERRU(it,s) = max(max(abs(UN{it,s}(2,:)-UNsim{it}(2,:))));
        ERRR(it,s) = mape(RN{it,s},RNsim{it});
        ERRX(it,s) = mape(TN{it,s},TNsim{it});
    end
 %   disp([ERRQ(end,:),ERRX(end,:)])
end

