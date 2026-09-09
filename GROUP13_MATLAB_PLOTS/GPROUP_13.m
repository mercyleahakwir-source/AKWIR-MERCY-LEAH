%% GROUP 13: MATLAB PLOTS
clear; 
close all; 
clc;

excelFile = 'C:\Users\DELL\Desktop\GROUP 13.xlsx';
outputFolder = fullfile(fileparts(mfilename('fullpath')), 'GROUP13_numbered_plots');
if ~isfile(excelFile), error('Workbook not found: %s', excelFile);
end
if ~isfolder(outputFolder), mkdir(outputFolder); 
end

T = readtable(excelFile, 'Sheet','Sheet1', 'VariableNamingRule','preserve');
age = double(T.("AGE"));
cgpa = double(T.("CGPA"));
tribe = fillmissing(string(T.("TRIBE")), 'constant', "Not recorded");
hostel = fillmissing(string(T.("HOSTELORHALL")), 'constant', "Not recorded");
gender = fillmissing(string(T.("GENDER")), 'constant', "Not recorded");
n = height(T); 
obs = (1:n)';

[tribeNames,~,tribeID] = unique(tribe,'stable'); 
tribeCount = accumarray(tribeID,1);
[hostelNames,~,hostelID] = unique(hostel,'stable'); 
hostelCount = accumarray(hostelID,1);
[genderNames,~,genderID] = unique(gender,'stable'); 
genderCount = accumarray(genderID,1);
[ageSorted,order] = sort(age); 
cgpaSorted = cgpa(order);

%% Line plot
f=figure('Color','w'); 
plot(obs,age,'-o','LineWidth',1.2); 
grid on;
xlabel('Students'); 
ylabel('Age (years)'); 
title('Age by student');
savePlot(f,outputFolder,'Line_plot');

%% Scatter plot
f=figure('Color','w'); 
gscatter(age,cgpa,gender); 
grid on;
xlabel('Age (years)'); 
ylabel('CGPA'); 
title('Age versus CGPA');
savePlot(f,outputFolder,'Scatter_plot');
%% Bar graph
f=figure('Color','w'); 
bar(categorical(tribeNames),tribeCount); 
grid on; 
xtickangle(35);
xlabel('Tribe'); 
ylabel('Students'); 
title('Students by tribe');
savePlot(f,outputFolder,'Bar_graph');

%% Horizontal bar graph
f=figure('Color','w'); 
barh(categorical(hostelNames),hostelCount); 
grid on;
xlabel('Students'); 
ylabel('Hostel/Hall'); 
title('Students by hostel/hall');
savePlot(f,outputFolder,'Horizontal_bar_graph');

%% Sankey diagram (tribe to hostel/hall)
pairText=tribe+"|"+hostel; 
[pairNames,~,pairID]=unique(pairText,'stable');
linkWeight=accumarray(pairID,1); 
linkTribe=extractBefore(pairNames,"|"); 
linkHostel=extractAfter(pairNames,"|");
f=figure('Color','w'); 
drawSankeyDiagram(linkTribe,linkHostel,linkWeight);
title('Student flow: tribe to hostel/hall'); 
savePlot(f,outputFolder,'Sankey_diagram');

%% Stem plot
f=figure('Color','w'); 
stem(obs,cgpa,'filled'); 
grid on;
xlabel('Students'); 
ylabel('CGPA'); 
title('Stem plot of CGPA');
savePlot(f,outputFolder,'Stem_plot');

%% Step plot
f=figure('Color','w'); 
stairs(obs,age,'LineWidth',1.4); 
grid on;
xlabel('Students'); 
ylabel('Age (years)'); 
title('Step plot of age');
savePlot(f,outputFolder,'Step_plot');

%% Error-bar plot
f=figure('Color','w'); 
errorbar(obs,cgpa,repmat(std(cgpa,'omitnan')/sqrt(n),n,1),'o-','LineWidth',1); 
grid on;
xlabel('Students'); 
ylabel('CGPA'); 
title('CGPA with one standard error');
savePlot(f,outputFolder,'Errorbar_plot');

%% Area plot
f=figure('Color','w'); 
area(obs,[age cgpa]); 
grid on;
xlabel('Students'); 
ylabel('Value'); 
title('Area plot: age and CGPA');
legend('Age','CGPA','Location','best'); 
savePlot(f,outputFolder,'Area_plot');

%% Histogram
f=figure('Color','w'); 
histogram(age,'BinMethod','integers'); 
grid on;
xlabel('Age (years)'); 
ylabel('Students'); 
title('Age distribution');
savePlot(f,outputFolder,'Histogram');

%% Pareto chart
f=figure('Color','w'); 
pareto(tribeCount,cellstr(tribeNames)); 
grid on;
title('Pareto chart of tribes'); 
savePlot(f,outputFolder,'Pareto_chart');

%% Box plot
f=figure('Color','w'); 
boxplot(cgpa,gender); grid on;
xlabel('Gender'); 
ylabel('CGPA'); 
title('CGPA by gender');
savePlot(f,outputFolder,'Box_plot');

%% Pie chart
f=figure('Color','w'); 
pie(genderCount); 
legend(genderNames,'Location','bestoutside');
title('Gender composition'); 
savePlot(f,outputFolder,'Pie_chart');

%% Pie chart with percent labels
f=figure('Color','w'); 
labels=genderNames+" ("+string(round(100*genderCount/sum(genderCount),1))+"%)";
pie(genderCount,labels); 
title('Gender composition with percentages');
savePlot(f,outputFolder,'Pie_percent_labels');

%% Logarithmic plots (semilogx, semilogy, and loglog)
f=figure('Color','w'); 
tl=tiledlayout(1,3,'Padding','compact');
nexttile; semilogx(obs,ageSorted,'-o'); 
grid on; 
title('semilogx'); 
xlabel('Students'); 
ylabel('Age');
nexttile; 
semilogy(obs,max(cgpaSorted,eps),'-o'); 
grid on; 
title('semilogy'); 
xlabel('Students'); 
ylabel('CGPA');
nexttile; loglog(obs,max(ageSorted,eps),'-o'); 
grid on; 
title('loglog'); 
xlabel('Students'); 
ylabel('Age');
title(tl,'Logarithmic plots'); 
savePlot(f,outputFolder,'Logarithmic_plots');

fprintf('Finished. Saved PNG files to:\n%s\n',outputFolder);

function savePlot(f,folder,name)
exportgraphics(f,fullfile(folder,name+".png"),'Resolution',300); close(f);
end

function drawSankeyDiagram(source,target,weight)
[src,~,srcID]=unique(source,'stable'); 
[dst,~,dstID]=unique(target,'stable');
usable=1-0.018*(max(numel(src),numel(dst))-1);
srcBox=sankeyBoxes(accumarray(srcID,weight),usable); 
dstBox=sankeyBoxes(accumarray(dstID,weight),usable);
srcCursor=srcBox(:,1); 
dstCursor=dstBox(:,1); 
colors=lines(numel(src)); 
hold on;
for i=1:numel(weight)
    h=weight(i)/sum(weight)*usable; 
    s=srcID(i); 
    d=dstID(i);
    y1=srcCursor(s); 
    y2=dstCursor(d);
    patch([.10 .90 .90 .10],[y1 y2 y2+h y1+h],colors(s,:),'FaceAlpha',.36,'EdgeColor','none');
    srcCursor(s)=y1+h; 
    dstCursor(d)=y2+h;
end
for i=1:numel(src)
    rectangle('Position',[.04 srcBox(i,1) .06 srcBox(i,2)],'FaceColor',colors(i,:),'EdgeColor','w');
    text(.035,srcBox(i,1)+srcBox(i,2)/2,src(i),'HorizontalAlignment','right','FontSize',8);
end
for i=1:numel(dst)
    rectangle('Position',[.90 dstBox(i,1) .06 dstBox(i,2)],'FaceColor',[.25 .25 .25],'EdgeColor','w');
    text(.965,dstBox(i,1)+dstBox(i,2)/2,dst(i),'HorizontalAlignment','left','FontSize',8);
end
axis([0 1 0 1]); 
axis off; 
hold off;
end

function boxes=sankeyBoxes(totals,usable)
gap=.018; heights=totals/sum(totals)*usable; 
bottom=zeros(numel(totals),1); 
y=0;
for i=1:numel(totals), bottom(i)=y; 
    y=y+heights(i)+gap; 
end
boxes=[bottom heights];
end
