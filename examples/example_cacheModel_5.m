clear;
samples = 1e7;
rpcell = {ReplacementPolicy.FIFO,ReplacementPolicy.RAND};
ERR  =[];
it = 0;
for r=1:length(rpcell)
    rp = rpcell{r};
    for n=[100,50,10]
        for nmr=[10,4,2]
            for a=[1.4,1,0.6]
                it = it  + 1;
                model = Network('model');
                scale = it;
                m = round(n/nmr);
                m = ceil(m);
                h = length(m);
                N = [1,1];
                alpha = [a,1.0];
                S11 = 1; S12 = 2;
                S21 = 0.01; S22 = 0.01;
                S31 = 0.10; S32 = 0.10;
                S = [S11,S12; S21,S22; S31,S32];
                
                mainDelay = Delay(model, 'MainDelay');
                cacheNode = Cache(model, 'Cache1', n, m, rp);
                hitDelay = Queue(model,'HitQ',SchedStrategy.INF);
                missDelay = Queue(model,'MissQ',SchedStrategy.INF);
                
                initClass1 = ClosedClass(model, 'InitClass1', N(1), mainDelay, 0);
                hitClass1 = ClosedClass(model, 'HitClass1', 0, mainDelay, 0);
                missClass1 = ClosedClass(model, 'MissClass1', 0, mainDelay, 0);
                
                initClass2 = ClosedClass(model, 'InitClass2', N(2), mainDelay, 0);
                hitClass2 = ClosedClass(model, 'HitClass2', 0, mainDelay, 0);
                missClass2 = ClosedClass(model, 'MissClass2', 0, mainDelay, 0);
                
                RM1 = Zipf(alpha(1),n);
                RM2 = Zipf(alpha(2),n);
                cacheNode.setRead(initClass1, RM1);
                cacheNode.setRead(initClass2, RM2);
                
                mainDelay.setService(initClass1, Exp.fitMean(S11));
                hitDelay.setService(hitClass1, Exp.fitMean(S21));
                missDelay.setService(missClass1, Exp.fitMean(S31));
                
                mainDelay.setService(initClass2, Exp.fitMean(S12));
                hitDelay.setService(hitClass2, Exp.fitMean(S22));
                missDelay.setService(missClass2, Exp.fitMean(S32));
                
                cacheNode.setHitClass(initClass1, hitClass1);
                cacheNode.setMissClass(initClass1, missClass1);
                
                cacheNode.setHitClass(initClass2, hitClass2);
                cacheNode.setMissClass(initClass2, missClass2);
                
                P = cellzeros(6,6,4,4);
                P{initClass1, initClass1}(1,2)=1;
                P{hitClass1, hitClass1}(2,3)=1;
                P{hitClass1, initClass1}(3,1)=1;
                P{missClass1, missClass1}(2,4)=1;
                P{missClass1, initClass1}(4,1)=1;
                
                P{initClass2, initClass2}(1,2)=1;
                P{hitClass2, hitClass2}(2,3)=1;
                P{hitClass2, initClass2}(3,1)=1;
                P{missClass2, missClass2}(2,4)=1;
                P{missClass2, initClass2}(4,1)=1;
                
                model.link(P);
                
                %AvgTable = SolverCTMC(model,'keep',true).getAvgTable
                AvgTable = SolverSSA(model,'samples',samples,'verbose',1,'seed',1,'method','parallel').getAvgTable
                %save(sprintf('listbased-%s-%d-%d-%d-%d-%d-%d-%0.2f-%0.2f.mat',rp,n,m(1),m(2),samples,N(1),N(2),alpha(1),alpha(2)));
                %save(sprintf('single-%s-%d-%d-%d-%d-%d-%0.2f-%0.2f.mat',rp,n,m(1),samples,N(1),N(2),alpha(1),alpha(2)));
                
                %%
                u = 2;
                kset=1:n;
                R={};
                r=ones(u,n,h);
                for k=1:n
                    for v=1:u
                        R{v,k}=zeros(h);
                        for l=2:(h+1)
                            R{v,k}(l-1,l)=r(v,k,l-1);
                            R{v,k}(l-1,l-1)=1-r(v,k,l-1);
                            R{v,k}(h,h)=1;
                        end
                    end
                end
                %%
                T11 = AvgTable.Tput(3); T21 =  AvgTable.Tput(5);
                T12 = AvgTable.Tput(4); T22 =  AvgTable.Tput(6);
                T = [T11,T12; T21,T22];
                X = ones(size(T));
                Emp{1} = RM1;
                Emp{2} = RM2;
                X_1 = X*1e3;
                goon=true;
                while goon
                    for v=1:u
                        Xtot(v) = sum(X(:,v));
                        for k=kset
                            for j=1:(h+1)
                                lambda(v,k,j)=Emp{v}.getPmf(k)*Xtot(v);
                            end
                        end
                    end
                    [gamma,u,n,h] = mucache_gamma(lambda,R);
                    [~,MU] = mucache_miss_asy(gamma,m,lambda);
                    %%
                    pHit = 1-MU./Xtot';
                    AvgTableNet = example_cacheModel_5_sub1(S,N,pHit);
                    X(1,1) = AvgTableNet.Tput(3);
                    X(1,2) = AvgTableNet.Tput(4);
                    X(2,1) = AvgTableNet.Tput(5);
                    X(2,2) = AvgTableNet.Tput(6);
                    if norm(X-X_1)<1e-3
                        goon=false;
                    end
                    X_1 = X;
                end
                X
                T
                ERR(end+1,:)=[n,m,mean(abs(1-X(:)./T(:))), max(abs(1-X(:)./T(:)))]
                
                %%
                u = 2;
                kset=1:n;
                R={};
                r=ones(u,n,h);
                for k=1:n
                    for v=1:u
                        R{v,k}=zeros(h);
                        for l=2:(h+1)
                            R{v,k}(l-1,l)=r(v,k,l-1);
                            R{v,k}(l-1,l-1)=1-r(v,k,l-1);
                            R{v,k}(h,h)=1;
                        end
                    end
                end
                %%
                T11 = AvgTable.Tput(3); T21 =  AvgTable.Tput(5);
                T12 = AvgTable.Tput(4); T22 =  AvgTable.Tput(6);
                T = [T11,T12; T21,T22];
                X = ones(size(T));
                Emp{1} = RM1;
                Emp{2} = RM2;
                X_1 = X*1e3;
                goon=true;
                while goon
                    for v=1:u
                        Xtot(v) = sum(X(:,v));
                        for k=kset
                            for j=1:(h+1)
                                lambda(v,k,j)=Emp{v}.getPmf(k)*Xtot(v);
                            end
                        end
                    end
                    [gamma,u,n,h] = mucache_gamma(lambda,R);
                    [~,MU] = mucache_miss_rayint(gamma,m,lambda);
                    %%
                    pHit = 1-MU./Xtot';
                    AvgTableNet = example_cacheModel_5_sub1(S,N,pHit);
                    X(1,1) = AvgTableNet.Tput(3);
                    X(1,2) = AvgTableNet.Tput(4);
                    X(2,1) = AvgTableNet.Tput(5);
                    X(2,2) = AvgTableNet.Tput(6);
                    if norm(X-X_1)<1e-3
                        goon=false;
                    end
                    X_1 = X;
                end
                X
                T
                ERR(end+1,:)=[n,m,mean(abs(1-X(:)./T(:))), max(abs(1-X(:)./T(:)))]
            end
        end
    end
end