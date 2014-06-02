function appendCellArray2file(filename, output, fid)
%---Generic output function-------------
tmp=cellfun(@str_func,output,'UniformOutput', false);
tmp2=tmp';
fprintf(fid,[repmat('%s\t',1,size(tmp2,1)-1),'%s\n'],tmp2{:});  %tab delimited
%fprintf(fid,[repmat('%s ',1,size(tmp2,1)-1),'%s\n'],tmp2{:});  %space delimited
