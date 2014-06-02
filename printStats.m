function stats = printStats(functionHandles, varin, fid)
output=cellfun(@(x)x(varin), functionHandles, 'UniformOutput', false); %cellfun example using a generic function  @x applied to the function cell array so that varin can be passed to each function
appendCellArray2file(varin.datafilename, output, fid)
