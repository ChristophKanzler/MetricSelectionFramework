%
% Copyright (C) 2011-2012 Alex Bikfalvi
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or (at
% your option) any later version.

% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% General Public License for more details.

% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
%

%modified 

function [q1 q2 q3 fu fl ou ol] = quartile(x)

[prt] = prctile(x,[25 50 75]);
q1 = prt(1); q2 = prt(2); q3 = prt(3);
% rank the data
y = sort(x);
% compute Interquartile Range (IQR)
IQR = q3-q1;

if(IQR ~= iqr(x))
    error('Error in IQR calculation!');
end

fl = min(y(y>=q1-1.5*IQR));
fu = max(y(y<=q3+1.5*IQR));

ol = y(y<q1-1.5*IQR);
ou = y(y>q3+1.5*IQR);

end