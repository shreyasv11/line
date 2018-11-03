eval(exampleName);
saved = load([exampleName,'.mat'],'AvgTable','solver');
AvgTableEx = saved.AvgTable;
solver = saved.solver;
fields = {'QLen','Util','Tput','RespT'};
for s=1:length(solver)
    for f=1:length(fields)
        assert(all(abs(AvgTable{s}.(fields{f})(:)-AvgTableEx{s}.(fields{f})(:))<1e-10),[solver{s}.getName,' failed on ',fields{f},' in ',exampleName,'.m']);
    end
end
