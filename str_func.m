function [ out ] = str_func( in )
% this function will test whether the input is a string or a double precision non-integer or integer and format the output accordingly. To 4 decimal places precision for non-integers.
in_datatype = class(in);
switch in_datatype
	case 'char'
		out = in;
	case 'double'		
		if rem(in, 1) ~= 0
			out = sprintf('%.4f',in);
		else
			out = sprintf('%d',in);
		end
end
