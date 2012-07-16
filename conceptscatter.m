function [ax, height, extra_plots] = conceptscatter(x,nWholeConcepts, BigAx, parent_panel)
%GPLOTMATRIX  Scatter plot matrix with grouping variable.
%   GPLOTMATRIX(X,Y,G) creates a matrix of scatter plots of the columns of
%   X against the columns of Y, grouped by G.  If X is P-by-M and Y is
%   P-by-N, GPLOTMATRIX will produce a N-by-M matrix of axes.  If you omit
%   Y or specify it as [], the function graphs X vs. X.  G is a grouping
%   variable that determines the marker and color assigned to each point in
%   each matrix, and it can be a categorical variable, vector, string
%   matrix, or cell array of strings.  Alternatively G can be a cell array
%   of grouping variables (such as {G1 G2 G3}) to group the values in X by
%   each unique combination of grouping variable values.
%
%   Use the data cursor to read precise values from the plot, as well as
%   the observation number and the values of related variables.
%
%   GPLOTMATRIX(X,Y,G,CLR,SYM,SIZ) specifies the colors, markers, and size
%   to use.  CLR is a string of color specifications, and SYM is a string
%   of marker specifications.  Type "help plot" for more information.  For
%   example, if SYM='o+x', the first group will be plotted with a circle,
%   the second with plus, and the third with x. SIZ is a marker size to use
%   for all plots.  By default, the colors are 'bgrcmyk', the marker is
%   '.', and the marker size depends on the number of plots and the size of
%   the figure window.
%
%   GPLOTMATRIX(X,Y,G,CLR,SYM,SIZ,DOLEG) lets you control whether legends
%   are created.  Set DOLEG to 'on' (default) or 'off'.
%
%   GPLOTMATRIX(X,Y,G,CLR,SYM,SIZ,DOLEG,DISPOPT) lets you control how to
%   fill the diagonals in a plot of X vs. X.  Set DISPOPT to 'none' to
%   leave them blank, 'hist' (default) to plot histograms, or 'variable' to
%   write the variable names.
%
%   GPLOTMATRIX(X,Y,G,CLR,SYM,SIZ,DOLEG,DISPOPT,XNAM,YNAM) specifies XNAM
%   and YNAM as the names of the X and Y variables.  Each must be a
%   character array or cell array of strings of the appropriate dimension.
%
%   [H,AX,BigAx] = GPLOTMATRIX(...) returns an array of handles H to the
%   plotted points; a matrix AX of handles to the individual subaxes; and a
%   handle BIGAX to big (invisible) axes framing the subaxes.  The third
%   dimension of H corresponds to groups in G.  If DISPOPT is 'hist', AX
%   contains one extra row of handles to invisible axes in which the
%   histograms are plotted. BigAx is left as the CurrentAxes so that a
%   subsequent TITLE, XLABEL, or YLABEL will be centered with respect to
%   the matrix of axes.
%
%   Example:
%      load carsmall;
%      X = [MPG,Acceleration,Displacement,Weight,Horsepower];
%      varNames = {'MPG' 'Acceleration' 'Displacement' 'Weight' 'Horsepower'};
%      gplotmatrix(X,[],Cylinders,'bgrcm',[],[],'on','hist',varNames);
%
%   See also GRPSTATS, GSCATTER, PLOTMATRIX.

%   Copyright 1993-2010 The MathWorks, Inc.
%   $Revision: 1.1.8.4 $  $Date: 2010/10/08 17:24:10 $

% x = rand(size(in_data))
% assignin('base','x',x);

whole = rand(size(x(1:nWholeConcepts,:)));
part = rand(size(x(nWholeConcepts+1:end,:)));
dims = size(x,2);

assignin('base','whole',whole)
assignin('base','part',part)

% rows = size(x,2); cols = rows;
rows = 8; cols = rows;
extra_plots = rows - dims;
XvsX = true;


% [g,gn] = mgrp2idx(g,size(x,1),',');
% ng = max(g);

% ynam = xnam;

% Create/find BigAx and make it invisible
% clf; % will this clear the whole gui? YES!
% BigAx = handles.overview_axes;
hold_state = ishold;
set(BigAx,'Visible','off','color','none','Parent',parent_panel)

clr = 'bgrcmyk';
sym = '.';


siz = repmat(get(0,'defaultlinemarkersize'), size(sym));
if any(sym=='.'),
  units = get(BigAx,'units');
%   set(BigAx,'units','pixels');
  pos = get(BigAx,'Position');
%   set(BigAx,'units',units);
  siz(sym == '.') = max(1,min(15, ...
                   round(15*min(pos(3:4))/size(x,1)/max(rows,cols))));
end


% Store global data for datatips into BixAx
% ginds = cell(1,ng);
% for i=1:ng
%     ginds{i} = find(g==i);
% end

% setappdata(BigAx,'ginds',ginds);
% setappdata(BigAx,'xnam',xnam);
% setappdata(BigAx,'ynam',ynam);
setappdata(BigAx,'x',x);
setappdata(BigAx,'y',x);
setappdata(BigAx,'XvsX',XvsX);
% setappdata(BigAx,'gn',gn);

% TOOK OUT TO GET LINKING WORKING... NOT SURE IF IT MAKES A DIFF
% Make datatips show up in front of axes
% dcm_obj = datacursormode(ancestor(BigAx,'figure'));
% set(dcm_obj,'EnableAxesStacking',true);
% 
% dataCursorBehaviorObj = hgbehaviorfactory('DataCursor');
% set(dataCursorBehaviorObj,'UpdateFcn',@gplotmatrixDatatipCallback);

% Create and plot into axes
ax2filled = false(rows,1);
pos = get(BigAx,'Position');
width = pos(3)/cols;
% height = pos(4)/rows;
height = width;
space = .04; % 2 percent space between axes
pos(1:2) = pos(1:2) + space*[width height]; % shift starting point by spacing
[m,n,k] = size(x); %#ok<ASGLU>
xlim = repmat(cat(3,zeros(rows,1),ones(rows,1)),[rows 1 1]);
ylim = repmat(cat(3,zeros(rows,1)',ones(rows,1)'),[1 cols 1]);


x_bound = [0 1];
y_bound = [1 0];
% these are the loops that need to be changed to enable data linking

ax = cell(nchoosek(size(x,2),2)+1,1); % all pairs of dims plus the 3D plot
ax_index = 1;
for i=size(x,2):-1:1, % count down from rows to 1
   for j=i-1:-1:1, % count down from cols to 1
        axPos = [pos(1)+(j-1)*width pos(2)+(rows-i)*height ...
            width*(1-space) height*(1-space)];
        ax{ax_index} = axes('Position',axPos, 'visible', 'on', 'Box','on','Parent',parent_panel,'Clipping','On');
%         findax = findaxpos(paxes, axPos);
%         if isempty(findax),
%             ax(i,j) = axes('Position',axPos,'HandleVisibility',BigAxHV,'parent',BigAxParent);
%             set(ax(i,j),'visible','on');
%         else
%             ax(i,j) = findax(1);
%         end
        plot(whole(:,j),...
           whole(:,i),'.g','parent',ax{ax_index});
%        linkdata on
        hold on;
        plot(part(:,j), ...
            part(:,i),'.b','parent',ax{ax_index});
        hold on;

        plot(x_bound,y_bound,'parent',ax{ax_index});
        
%         linkdata on
%         set(hh(i,j,:),'markersize',markersize);
        set(ax{ax_index},'xlimmode','manual','ylimmode','manual','xgrid','off','ygrid','off',...
            'xlim',[-.25 1.25],'ylim',[-.25 1.25],'xticklabel','','yticklabel','')
        xlim(i,j,:) = get(ax{ax_index},'xlim');
        ylim(i,j,:) = get(ax{ax_index},'ylim');
        
        ax_index = ax_index + 1;

   end
end

j = rows/2;
axPos = [pos(1)+(j-1)*width pos(2)+(rows - j - .5)*height ...
            width*(1-space)*(j+2) height*(1-space)*(j+2)];
axes3D = axes('Position',axPos, 'visible', 'on', 'Box','on','Parent',parent_panel,'Clipping','on'); 
scatter3(whole(:,4),whole(:,5),whole(:,6),'MarkerFaceColor','g','Parent',axes3D)
hold on
scatter3(part(:,4),part(:,5),part(:,6),'MarkerFaceColor','b','Parent',axes3D)
set(axes3D,'xlimmode','manual','ylimmode','manual','xgrid','off','ygrid','off',...
            'xlim',[-.25 1.25],'ylim',[-.25 1.25],'zlim',[-.25 1.25],...
            'xticklabel','','yticklabel','','zticklabel','','CameraViewAngleMode','manual')

        
ax{ax_index} = axes3D;

x_bound = [0 0 1 0];
y_bound = [0 1 0 0];
z_bound = [0 0 0 1];
choices = nchoosek([1 2 3 4],2);

for i = 1:size(choices,1)
    
    hold on
    plot3(x_bound(choices(i,:)),y_bound(choices(i,:)),z_bound(choices(i,:)),'Parent',axes3D);
    
end


linkdata on
whole = x(1:nWholeConcepts,:);
part = x(nWholeConcepts+1:end,:);
assignin('base','whole',whole)
assignin('base','part',part)


% x(:) = in_data(:);
% assignin('base','x',x);


% ld = linkdata(gcf)
% fieldnames(ld)

% xlimmin = min(xlim(:,:,1),[],1); xlimmax = max(xlim(:,:,2),[],1);
% ylimmin = min(ylim(:,:,1),[],2); ylimmax = max(ylim(:,:,2),[],2);
% 
% % % Set all the limits of a row or column to be the same and leave 
% % % just a 5% gap between data and axes.
% inset = .05;
% for i=2:rows,
%   set(ax(i,1),'ylim',[ylimmin(i,1) ylimmax(i,1)])
%   dy = diff(get(ax(i,1),'ylim'))*inset;
%   set(ax(i,1:i-1),'ylim',[ylimmin(i,1)-dy ylimmax(i,1)+dy])
% end
% for j=1:cols-1,
%   set(ax(j+1,j),'xlim',[xlimmin(1,j) xlimmax(1,j)])
%   dx = diff(get(ax(1,j),'xlim'))*inset;
%   set(ax(j+1:rows,j),'xlim',[xlimmin(1,j)-dx xlimmax(1,j)+dx])
%   if ax2filled(j)
%      set(ax2(j),'xlim',[xlimmin(1,j)-dx xlimmax(1,j)+dx])
%   end
% end



% % Label plots one way or the other
% if (donames && ~isempty(xnam))
%    for j=1:cols
%       set(gcf,'CurrentAx',ax(j,j));
%       h = text((...
%           xlimmin(1,j)+xlimmax(1,j))/2, (ylimmin(j,1)+ylimmax(j,1))/2, -.1,...
%           xnam{j}, 'HorizontalAlignment','center',...
%           'VerticalAlignment','middle');
%    end
% else
%    if ~isempty(xnam)
%       for j=1:cols, xlabel(ax(rows,j),xnam{j}); end
%    end
%    if ~isempty(ynam)
%       for i=1:rows, ylabel(ax(i,1),ynam{i}); end
%    end
% end

% Ticks and labels on outer plots only
% set(ax(1:rows-1,:),'xticklabel','')
% set(ax(:,2:cols),'yticklabel','')
% set(BigAx,'XTick',get(ax(rows,1),'xtick'),'YTick',get(ax(rows,1),'ytick'), ...
%           'userdata',ax,'tag','PlotMatrixBigAx')

% Create legend if requested; base it on the top right plot
% if (doleg)
%    gn = gn(ismember(1:size(gn,1),g),:);
%    legend(ax(1,cols),gn);
% end

% Make BigAx the CurrentAxes
set(gcf,'CurrentAx',BigAx)
if ~hold_state,
   set(gcf,'NextPlot','replace')
end




% Also set Title and X/YLabel visibility to on and strings to empty
% set([get(BigAx,'Title'); get(BigAx,'XLabel'); get(BigAx,'YLabel')], ...
%  'String','','Visible','on')

% if nargout~=0,
%   h = hh;
%   if any(ax2filled)
%      ax = [ax; ax2(:)'];
%   end
% end

% -----------------------------
function datatipTxt = gplotmatrixDatatipCallback(obj,evt)

target = get(evt,'Target');
ind = get(evt,'DataIndex');
pos = get(evt,'Position');

dtcallbackdata = getappdata(target,'dtcallbackdata');
[BigAx,gnum,row,col] = dtcallbackdata{:};

ginds = getappdata(BigAx,'ginds');
xnam = getappdata(BigAx,'xnam');
ynam = getappdata(BigAx,'ynam');
xdat = getappdata(BigAx,'x');
ydat = getappdata(BigAx,'y');
XvsX = getappdata(BigAx,'XvsX');
gn = getappdata(BigAx,'gn');

gind = ginds{gnum};
obsind = gind(ind);

xvals = xdat(obsind,:);
yvals = ydat(obsind,:);

x = xvals(col);
y = yvals(row);

if x~=pos(1) || y~=pos(2)
    % Something is inconsistent, display default datatip.
    datatipTxt = {sprintf('X: %s',num2str(pos(1))),sprintf('Y: %s',num2str(pos(2)))};
else
    if isempty(xnam)
        xnam = cell(size(xdat,2),1);
        for i = 1:size(xdat,2)
            xnam{i} = sprintf('xvar%s',num2str(i));
        end
    end
    if isempty(ynam)
        ynam = cell(size(ydat,2),1);
        for i = 1:size(ydat,2)
            ynam{i} = sprintf('yvar%s',num2str(i));
        end
    end

    % Generate datatip text.
    datatipTxt = {
        [xnam{col},': ',num2str(x)],...
        [ynam{row},': ',num2str(y)],...
        '',...
        sprintf('Observation: %s',num2str(obsind)),...
        };

    if ~isempty(gn)
        datatipTxt{end+1} = ['Group: ',gn{gnum}];
    end
    datatipTxt{end+1} = '';

    xnamTxt = cell(length(xvals),1);
    for i=1:length(xvals)
        xnamTxt{i} = [xnam{i} ': ' num2str(xvals(i))];
    end
    datatipTxt = {datatipTxt{:}, xnamTxt{:}};
    
    if ~XvsX
        ynamTxt = cell(length(yvals),1);
        for i=1:length(yvals)
            ynamTxt{i} = [ynam{i} ': ' num2str(yvals(i))];
        end
        datatipTxt = {datatipTxt{:}, ynamTxt{:}};
    end

end

function [ogroup,glabel,gname,multigroup] = mgrp2idx(group,rows,sep); 
%MGRP2IDX Convert multiple grouping variables to index vector 
%   [OGROUP,GLABEL,GNAME,MULTIGROUP] = MGRP2IDX(GROUP,ROWS) takes 
%   the inputs GROUP, ROWS, and SEP.  GROUP is a grouping variable (numeric 
%   vector, string matrix, or cell array of strings) or a cell array 
%   of grouping variables.  ROWS is the number of observations. 
%   SEP is a separator for the grouping variable values. 
% 
%   The output OGROUP is a vector of group indices.  GLABEL is a cell 
%   array of group labels, each label consisting of the values of the 
%   various grouping variables separated by the characters in SEP. 
%   GNAME is a cell array containing one column per grouping variable 
%   and one row for each distinct combination of grouping variable 
%   values.  MULTIGROUP is 1 if there are multiple grouping variables 
%   or 0 if there are not. 
 
%   Tom Lane, 12-17-99 
%   Copyright 1993-2002 The MathWorks, Inc.  
%   $Revision: 1.4 $  $Date: 2002/02/04 19:25:44 $ 
 
multigroup = (iscell(group) & size(group,1)==1); 
if (~multigroup) 
   [ogroup,gname] = grp2idx(group); 
   glabel = gname; 
else 
   % Group according to each distinct combination of grouping variables 
   ngrps = size(group,2); 
   grpmat = zeros(rows,ngrps); 
   namemat = cell(1,ngrps); 
    
   % Get integer codes and names for each grouping variable 
   for j=1:ngrps 
      [g,gn] = grp2idx(group{1,j}); 
      grpmat(:,j) = g; 
      namemat{1,j} = gn; 
   end 
    
   % Find all unique combinations 
   [urows,ui,uj] = unique(grpmat,'rows'); 
    
   % Create a cell array, one col for each grouping variable value 
   % and one row for each observation 
   ogroup = uj; 
   gname = cell(size(urows)); 
   for j=1:ngrps 
      gn = namemat{1,j}; 
      gname(:,j) = gn(urows(:,j)); 
   end 
    
   % Create another cell array of multi-line texts to use as labels 
   glabel = cell(size(gname,1),1); 
   if (nargin > 2) 
      nl = sprintf(sep); 
   else 
      nl = sprintf('\n'); 
   end 
   fmt = sprintf('%%s%s',nl); 
   lnl = length(fmt)-3;        % one less than the length of nl 
   for j=1:length(glabel) 
      gn = sprintf(fmt, gname{j,:}); 
      gn(end-lnl:end) = []; 
      glabel{j,1} = gn; 
   end 
end 

