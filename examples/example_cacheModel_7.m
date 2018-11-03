clear;
samples = 1e7;
rpcell = {ReplacementPolicy.RAND};
ERR  =[];
it = 0;
for r=1:length(rpcell)
    rp = rpcell{r};
    for n=[50,10,100]
        for nmr=[2,4,10]
            for a=[1.4,1,0.6]
                for N1=[1,4,16,32]
                    %for N2=[1,4,16,32]
                    it = it  + 1;
                    model = Network('model');
                    scale = it;
                    h = 2;
                    m = ceil(round(n/nmr)/h*ones(1,h));
                    alpha = [1.0,a];
                    N = [N1,N1];
                    S11 = 1; S12 = 2;
                    S21 = 0.01; S22 = 0.01;
                    S31 = 0.10; S32 = 0.50;
                    S = [S11,S12; S21,S22; S31,S32];
                    
                    mainDelay = Delay(model, 'MainDelay');
                    cacheNode = Cache(model, 'Cache1', n, m, rp);
                    postProc = Queue(model,'PostProc',SchedStrategy.FCFS);
                    postProc.setNumberOfServers(2);
                    
                    initClass1 = ClosedClass(model, 'InitClass1', N(1), mainDelay, 0);
                    hitClass1 = ClosedClass(model, 'HitClass1', 0, mainDelay, 0);
                    missClass1 = ClosedClass(model, 'MissClass1', 0, mainDelay, 0);
                    
                    initClass2 = ClosedClass(model, 'InitClass2', N(2), mainDelay, 0);
                    hitClass2 = ClosedClass(model, 'HitClass2', 0, mainDelay, 0);
                    missClass2 = ClosedClass(model, 'MissClass2', 0, mainDelay, 0);
                    
                    RM1 = Zipf(alpha(1),n);
                    RM2 = Zipf(alpha(2),n);
                    %z1 = (1/n)*ones(1,n); z1(1:floor(n/2)) = 0; z1 = z1/sum(z1);
                    %RM1 = DiscreteDistrib(z1); % uniform reference
                    %z2 = (1/n)*ones(1,n); z2(ceil(n/2):end) = 0; z2 = z2/sum(z2);
                    %RM2 = DiscreteDistrib(z2); % uniform reference
                    
                    cacheNode.setRead(initClass1, RM1);
                    cacheNode.setRead(initClass2, RM2);
                    
                    mainDelay.setService(initClass1, Exp.fitMean(S11));
                    mainDelay.setService(initClass2, Exp.fitMean(S12));
                    postProc.setService(hitClass1, Exp.fitMean(S21));
                    postProc.setService(hitClass2, Exp.fitMean(S22));
                    postProc.setService(missClass1, Exp.fitMean(S31));
                    postProc.setService(missClass2, Exp.fitMean(S32));
                    
                    cacheNode.setHitClass(initClass1, hitClass1);
                    cacheNode.setMissClass(initClass1, missClass1);
                    cacheNode.setHitClass(initClass2, hitClass2);
                    cacheNode.setMissClass(initClass2, missClass2);
                    
                    P = cellzeros(6,6,4,4);
                    P{initClass1, initClass1}(1,2)=1;
                    P{hitClass1, hitClass1}(2,3)=1;
                    P{hitClass1, initClass1}(3,1)=1;
                    
                    P{missClass1, missClass1}(2,3)=1;
                    P{missClass1, initClass1}(3,1)=1;
                    
                    P{initClass2, initClass2}(1,2)=1;
                    P{hitClass2, hitClass2}(2,3)=1;
                    P{hitClass2, initClass2}(3,1)=1;
                    
                    P{missClass2, missClass2}(2,3)=1;
                    P{missClass2, initClass2}(3,1)=1;
                    
                    model.link(P);
                    
                    %AvgTable = SolverCTMC(model,'keep',true).getAvgTable
                    AvgTable = SolverSSA(model,'samples',samples,'verbose',1,'seed',1,'method','parallel').getAvgTable
                    save(sprintf('misrv-%s-%d-%d-%d-%d-%d-%d-%0.2f-%0.2f.mat',rp,n,m(1),m(2),samples,N(1),N(2),alpha(1),alpha(2)));
                    %save(sprintf('listbased-%s-%d-%d-%d-%d-%d-%d-%0.2f-%0.2f.mat',rp,n,m(1),m(2),samples,N(1),N(2),alpha(1),alpha(2)));
                    %save(sprintf('single-%s-%d-%d-%d-%d-%d-%0.2f-%0.2f.mat',rp,n,m(1),samples,N(1),N(2),alpha(1),alpha(2)));
                    
                    ERR(end+1,:)=[n,m,a,N]
                end
            end
        end
    end
end
%end
