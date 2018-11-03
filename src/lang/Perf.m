classdef (Sealed) Perf
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

properties (Constant)
    ResidT = 'Residence Time'; % Response Time * Visits 
    RespT = 'Response Time'; % Response Time for one Visit
    DropRate = 'Drop Rate';
    QLen = 'Number of Customers';
    QueueT = 'Queue Time';
    FCRWeight = 'FCR Total Weight';
    FCRMemOcc = 'FCR Memory Occupation';
    FJQLen = 'Fork Join Response Time';
    FJRespT = 'Fork Join Response Time';
    RespTSink = 'Response Time per Sink';
    SysDropR = 'System Drop Rate';
    SysQLen = 'System Number of Customers';
    SysPower = 'System Power';
    SysRespT = 'System Response Time';
    SysTput = 'System Throughput';
    Tput = 'Throughput';
    TputSink = 'Throughput per Sink';
    Util = 'Utilization';
    TranQLen = 'Tran Number of Customers';
    TranUtil = 'Tran Utilization';
    TranTput = 'Tran Throughput';
end 

end