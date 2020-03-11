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

function c = colorgrad(varargin)

n = 16;
t = 'blue_down';

switch length(varargin)
    case 1
        n = varargin{1};
    case 2
        n = varargin{1};
        t = varargin{2};
end

switch lower(t)
    case 'blue_up'
        c = cat(2,linspace(0,0.6,n)',linspace(0.2,0.8,n)',linspace(0.6,1,n)');
    case 'blue_down'
        c = cat(2,linspace(0.7,0.35,n)',linspace(0.8,0.35,n)',linspace(1,0.65,n)');
    case 'orange_up'
        c = cat(2,linspace(1,248/255,n)',linspace(0.6,224/255,n)',linspace(0,124/255,n)');
    case 'orange_down'
        c = cat(2,linspace(248/255,1,n)',linspace(224/255,0.4,n)',linspace(124/255,0,n)');
    case 'green_up'
        c = cat(2,linspace(0.2,0.6,n)',linspace(0.6,1,n)',linspace(0.2,0.6,n)');
    case 'green_down'
        c = cat(2,linspace(0.6,0.2,n)',linspace(1,0.6,n)',linspace(0.6,0.2,n)');
    case 'red_up'
        c = cat(2,linspace(.8,1,n)',linspace(.2,.6,n)',linspace(.2,.6,n)');
    case 'red_down'
        c = cat(2,linspace(1,.8,n)',linspace(.6,.2,n)',linspace(.6,.2,n)');
    case 'vpiit'
        c = cat(2,linspace(1,0,n)',linspace(.6,.2,n)',linspace(.6,.2,n)');
    case 'a'%160
        %c = cat(2,linspace(160/255,200/255,n)',linspace(37/255,37/255,n)',linspace(52/255,52/255,n)');
        if(n ==4)
           c = [200 200 200;
               255 60 84;
               180 50 65;
               180 65 65]./255;
        else
          c = [200 200 200;
               230 45 64;
               170 40 45;
               120 23 33]./255;
        end
%           c = [184 170 160;
%                219 203 191;
%                255 236 222]./255;

    case 'b'%160
        %c = cat(2,linspace(50/255,50/255,n)',linspace(61/255,80/255,n)',linspace(79/255,79/255,n)');
        if(n==4)
           c =  [200 200 200;127 156 255; 100 122 202; 60 73 148]./255;
        else
            c = [200 200 200;127 156 201; 100 122 158; 60 73 94]./255;
        end
    case 'c'%160
        if(n==4)
            c = [200 200 200; 250 215 171; 201 174 138;148 128 101]./255;
        else
            c = [200 200 200; 250 215 171; 201 174 138;148 128 101]./255;
        end
        %c = cat(2,linspace(196/255,196/255,n)',linspace(169/255,169/255,n)',linspace(134/255,134/255,n)');
    case 'd'
        c =     [200 200 200; 128 128 128;   230 45 64; 120 23 33]./255;
    otherwise
        error('No such color gradient.');
end

end