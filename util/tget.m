function ret = tget(AvgTable,station,class)
if nargin==2
    if isa(station,'JobClass')
        class = station;
        station=[];
    else
        class=[];
    end
end
if isempty(station)
    ret = AvgTable(AvgTable.JobClass == class.name,:);
elseif isempty(class)
    ret = AvgTable(AvgTable.Station == station.name,:);
else
    ret = AvgTable(AvgTable.Station == station.name & AvgTable.JobClass == class.name,:);    
end
end