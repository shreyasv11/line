%clear;
for it=1:2
    model = CacheNetwork('model');
    
    n = 3;
    m = [2];
    N = [2,2]
    mainDelay = DelayStation(model, 'MainDelay');
    cacheNode = CacheRouter(model, 'Cache1', n, m, ReplacementPolicy.RAND);
    hitDelay = DelayStation(model, 'HitDelay');
    missDelay = DelayStation(model, 'MissDelay');
    
    initClass1 = ClosedClass(model, 'InitClass1', N(1), mainDelay, 0);
    hitClass1 = ClosedClass(model, 'HitClass1', 0, mainDelay, 0);
    missClass1 = ClosedClass(model, 'MissClass1', 0, mainDelay, 0);
    
    initClass2 = ClosedClass(model, 'InitClass2', N(2), mainDelay, 0);
    hitClass2 = ClosedClass(model, 'HitClass2', 0, mainDelay, 0);
    missClass2 = ClosedClass(model, 'MissClass2', 0, mainDelay, 0);
    
    if it == 1
        Zipf1 = Zipf(1.0,n);
        Zipf2 = Zipf(1.4,n);
        cacheNode.setRead(initClass1, Zipf1);
        cacheNode.setRead(initClass2, Zipf2);
    else
        X1 = AvgTable.Tput(1); X2 =  AvgTable.Tput(4);
        Emp = Empirical((X1/(X1+X2))*Zipf1.getPmf+(X2/(X1+X2))*Zipf2.getPmf);
        cacheNode.setRead(initClass1, Emp);
        cacheNode.setRead(initClass2, Emp);
    end
    mainDelay.setService(initClass1, Exp.fitMean(1));
    hitDelay.setService(hitClass1, Exp.fitMean(1));
    missDelay.setService(missClass1, Exp.fitMean(2));
    
    mainDelay.setService(initClass2, Exp.fitMean(1));
    hitDelay.setService(hitClass2, Exp.fitMean(1));
    missDelay.setService(missClass2, Exp.fitMean(1));
    
    
    cacheNode.setHitClass(initClass1, hitClass1);
    cacheNode.setMissClass(initClass1, missClass1);
    
    cacheNode.setHitClass(initClass2, hitClass2);
    cacheNode.setMissClass(initClass2, missClass2);
    
    P = cellzeros(6,6,4,4);
    P{initClass1.index, initClass1.index}(1,2)=1;
    P{hitClass1.index, hitClass1.index}(2,3)=1;
    P{hitClass1.index, initClass1.index}(3,1)=1;
    P{missClass1.index, missClass1.index}(2,4)=1;
    P{missClass1.index, initClass1.index}(4,1)=1;
    
    P{initClass2.index, initClass2.index}(1,2)=1;
    P{hitClass2.index, hitClass2.index}(2,3)=1;
    P{hitClass2.index, initClass2.index}(3,1)=1;
    P{missClass2.index, missClass2.index}(2,4)=1;
    P{missClass2.index, initClass2.index}(4,1)=1;
    
    model.linkNetwork(P);
    
    AvgTable = SolverCTMC(model,'keep',true).getAvgTable
    %SolverSSA(model).getAvgTable
end