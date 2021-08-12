function GUIchiploadcalc

clc
clear
warning('off','all')

%--------------------------------------------------------------------------
%GRAPHICAL INTERFACE
%--------------------------------------------------------------------------

%Size of the current window
width = 600;
height = 768;
%Centralize the current window at the center of the screen
[posX,posY,Width,Height]=centralizeWindow(width,height);
figposition = [posX,posY,Width,Height];

GUIchiploadcalc_ = figure('Menubar','none',...
    'Name','Chip Load Calculator',...
    'NumberTitle','off',...
    'NextPlot','add',...
    'units','pixel',...
    'position',figposition,...
    'Toolbar','figure',...
    'Visible','off',...
    'Resize','off');

%--------------------------------------------------------------------------
units = uicontrol(GUIchiploadcalc_,'Style','popup',...
    'Units','normalized',...
    'String',{'mm','inches'},...
    'fontUnits','normalized',...
    'tooltipstring','Units.',...
    'position',[0.03 0.915 0.944 0.036],...
    'Callback',@changeUnits_callback);

materialType = uicontrol(GUIchiploadcalc_,'Style','popup',...
    'Units','normalized',...
    'String',{'hardwood','plywood','MDF','soft plastic','hard plastic'},...
    'fontUnits','normalized',...
    'tooltipstring','Working material.',...
    'position',[0.03 0.865 0.46 0.036],...
    'Callback',@updateChipLoadRange_callback);

bitDiameter = uicontrol(GUIchiploadcalc_,'Style','popup',...
    'Units','normalized',...
    'String',{'1/8" or 3.175mm','1/4" or 6.350mm','3/8" or 9.525mm','1/2" or 12.7mm'},...
    'fontUnits','normalized',...
    'tooltipstring','Bit diameter.',...
    'position',[0.514 0.865 0.46 0.036],...
    'Callback',@updateChipLoadRange_callback);

chipLoadRange = uicontrol(GUIchiploadcalc_,'Style','edit',...
    'Units','normalized',...
    'String','',...
    'fontUnits','normalized',...
    'tooltipstring','Current chip load range [mm].',...
    'position',[0.03 0.815 0.944 0.036]);

numberOfFlutes = uicontrol(GUIchiploadcalc_,'Style','edit',...
    'Units','normalized',...
    'String','1',...
    'fontUnits','normalized',...
    'tooltipstring','Number of flutes or cutting edges.',...
    'position',[0.03 0.765 0.944 0.036]);

feedrate = uicontrol(GUIchiploadcalc_,'Style','edit',...
    'Units','normalized',...
    'String','500',...
    'fontUnits','normalized',...
    'tooltipstring','Feedrate [mm/min].',...
    'position',[0.03 0.715 0.46 0.036]);

spindleRotationSpeed = uicontrol(GUIchiploadcalc_,'Style','edit',...
    'Units','normalized',...
    'String','12000',...
    'fontUnits','normalized',...
    'tooltipstring','Spindle rotation [RPM].',...
    'position',[0.514 0.715 0.46 0.036]);

uicontrol(GUIchiploadcalc_,'Style','pushbutton',...
    'Units','normalized',...
    'String','Calculate Chip Load',...
    'fontUnits','normalized',...
    'position',[0.03 0.665 0.944 0.036],...
    'Callback',@calcChipLoad_callback);

chipLoad = uicontrol(GUIchiploadcalc_,'Style','edit',...
    'Units','normalized',...
    'String','',...
    'Enable','off',...
    'fontUnits','normalized',...
    'tooltipstring','Chip load [mm].',...
    'position',[0.03 0.615 0.944 0.036]);

graph = uipanel(GUIchiploadcalc_,...
    'Units','normalized',...
    'BackgroundColor','white',...
    'position',[0.03 0.065 0.944 0.48]);

imageFileFormat = uicontrol(GUIchiploadcalc_,'Style','popupmenu',...
    'units','normalized',...
    'Value',1,...
    'String',{'png','jpeg','jpg','tiff'},...
    'fontUnits','normalized',...
    'TooltipString','Image file format.',...
    'position',[0.03 0.015 0.22 0.036]);

DPI_=uicontrol(GUIchiploadcalc_,'Style','edit',...
    'units','normalized',...
    'String','300',...
    'fontUnits','normalized',...
    'TooltipString','DPI.',...
    'position',[0.27 0.015 0.22 0.036]);

uicontrol(GUIchiploadcalc_,'Style','pushbutton',...
    'Units','normalized',...
    'String','Save as image',...
    'fontUnits','normalized',...
    'position',[0.514 0.015 0.46 0.036],...
    'Callback',@export_callback);

%show chip load range for the current parameters
updateChipLoadRange()

alreadyCalculated = 0;
lastUnit = get(units,'value');
set(GUIchiploadcalc_,'Visible','on')
%--------------------------------------------------------------------------
%CALLBACK FUNCTIONS
%--------------------------------------------------------------------------

%CHANGE UNITS
function changeUnits_callback(hObject,callbackdata,handles)
%Retrieve the handle structure
handles = guidata(hObject);

if(get(units,'value')==1)
    set(feedrate,'tooltipstring','Feedrate [mm/min].');
    set(chipLoadRange,'tooltipstring','Current chip load range [mm].');
    if(alreadyCalculated==1)
        set(chipLoad,'tooltipstring','Chip load [mm]')
    end
else
    set(feedrate,'tooltipstring','Feedrate [inches/min].');
    set(chipLoadRange,'tooltipstring','Current chip load range [inches].');
    if(alreadyCalculated==1)
        set(chipLoad,'tooltipstring','Chip load [inches]')
    end
end

n = str2double(get(feedrate,'String'));
if(get(units,'value')~=lastUnit)
    if(get(units,'value')==2)
        n = n/25.4;
    else
        n = round(n*25.4);
    end
end

set(feedrate,'String',num2str(n))

updateChipLoadRange()

lastUnit = get(units,'value');
%Update de handle structure
guidata(hObject,handles);
end

%UPDATE CHIP LOAD RANGE
function updateChipLoadRange_callback(hObject,callbackdata,handles)
%Retrieve the handle structure
handles = guidata(hObject);

updateChipLoadRange()

%Update de handle structure
guidata(hObject,handles);
end

%CALCULATE CHIP LOAD
function calcChipLoad_callback(hObject,callbackdata,handles)
%Retrieve the handle structure
handles = guidata(hObject);

RPM = str2double(get(spindleRotationSpeed,'String'));
nf = str2double(get(numberOfFlutes,'String'));
n = str2double(get(feedrate,'String'));

n_perc = n*0.5;
N = linspace(n - n_perc, n + n_perc, 21);

chipLoad_range=findCurrentChipLoadRange();
chipLoad_min = chipLoad_range(1);
chipLoad_max = chipLoad_range(2);

CL_ = n/(RPM*nf);

CL__ = N./(RPM.*ones(size(N)).*nf);

set(chipLoad,'Enable','on','String',num2str(CL_))
bitD = get(bitDiameter,'string');
bitD = char(bitD(get(bitDiameter,'value')));
units_ = get(units,'String');
units_ = units_(get(units,'value'));
plotGraph(n,CL_,N,CL__,chipLoad_min,chipLoad_max,bitD,num2str(nf),units_)

alreadyCalculated = 1;
%Update de handle structure
guidata(hObject,handles);
end

%SAVE AS IMAGE
function export_callback(hObject,callbackdata,handles)
%Retrieve the handle structure
handles = guidata(hObject);

[FileName,PathName] = uiputfile({'*.jpg;*.tif;*.png;*.gif','All Image Files'},'Save Image...');
Fullpath = [PathName FileName];
if (sum(Fullpath)==0)
    return
end

msg=msgbox('Wait a moment!','Warn','warn');

format_=get(imageFileFormat,'String');
imageF = char(strcat('-d',format_(get(imageFileFormat,'Value'))));
dpi_ = strcat('-r',get(DPI_,'String'));
fName = strsplit(FileName,'.');
ImagePath = char(strcat(PathName,fName(1)));

print(GUIchiploadcalc_,ImagePath,imageF,dpi_)

delete(msg)
msgbox('Image Exported!','Warn','warn')

%Update de handle structure
guidata(hObject,handles);
end

%--------------------------------------------------------------------------
%LOCAL FUNCTIONS
%--------------------------------------------------------------------------

function updateChipLoadRange()
    chipLoad_range=findCurrentChipLoadRange();
    set(chipLoadRange,'String',num2str(chipLoad_range))
end

function chipLoad_range=findCurrentChipLoadRange()
    
    currentMaterialType = get(materialType,'value');
    currentBitDiameter = get(bitDiameter,'value');
    
    if(get(units,'value')==1)
        conversionFactor = 25.4;
    else
        conversionFactor = 1;
    end
    
    if(currentMaterialType==1)
        chipLoad_ = [0.003, 0.005; 0.009, 0.011; 0.015, 0.018; 0.019, 0.021].*conversionFactor;
    elseif(currentMaterialType==2)
        chipLoad_ = [0.004, 0.006; 0.011, 0.013; 0.018, 0.020; 0.021, 0.023].*conversionFactor;
    elseif(currentMaterialType==3)
        chipLoad_ = [0.004, 0.007; 0.013, 0.016; 0.020, 0.023; 0.025, 0.027].*conversionFactor;
    elseif(currentMaterialType==4)
        chipLoad_ = [0.003, 0.006; 0.007, 0.010; 0.010, 0.012; 0.012, 0.016].*conversionFactor;
    else
        chipLoad_ = [0.002, 0.004; 0.006, 0.009; 0.008, 0.010; 0.010, 0.012].*conversionFactor;
    end
    
    if(currentBitDiameter==1)
        chipLoad_range = chipLoad_(1,:);
    elseif(currentBitDiameter==2)
        chipLoad_range = chipLoad_(2,:);
    elseif(currentBitDiameter==3)
        chipLoad_range = chipLoad_(3,:);
    else
        chipLoad_range = chipLoad_(4,:);
    end
end

function plotGraph(fr,cl,feedrate_mm_per_min,chip_load_mm_per_rotation,...
        min_cheap_load,max_cheap_load,tool_diameter,flutes,unitsFlag)
    resetGraph()
    
    if(flutes=='1')
        flt = ' flute';
    else
        flt = ' flutes';
    end
    
    axes(graph)
    p1 = plot(feedrate_mm_per_min,chip_load_mm_per_rotation,'b--.');
    hold on
    plot(fr,cl,'ro')
    text(fr,cl,'\leftarrow you are here!')
    xl = xlim(); width_ = xl(2)-xl(1);
    xlim([xl(1)-0.05*width_,xl(2)+0.05*width_])
    xl = xlim();
    p2 = plot(xl,[min_cheap_load, min_cheap_load],'r--');
    p3 = plot(xl,[max_cheap_load, max_cheap_load],'k--');
    yl = ylim(); heigth_ = yl(2)-yl(1);
    ylim([yl(1)-0.05*heigth_,yl(2)+0.2*heigth_])
    if(strcmp(unitsFlag,'mm'))
        title({'CHIP LOAD VS FEEDRATE',['[cutting bit with ',flutes,flt,' and ',tool_diameter,' of diameter]']})
        xlabel('feedrate [mm/minute]')
        ylabel('chip load [mm/rotation]')
    else
        title({'CHIP LOAD VS FEEDRATE',['[fresa de 1 fio, diametro de ',tool_diameter,']']})
        xlabel('feedrate [inches/minute]')
        ylabel('chip load [inches/rotation]')
    end
    legend([p1 p2 p3],{'chip load for different feedrates','minimum chip load','maximum chip load'},'Location','northwest')
    grid on
    hold off
end

function resetGraph()
    graph = uipanel(GUIchiploadcalc_,...
        'Units','normalized',...
        'BackgroundColor','white',...
        'position',[0.03 0.065 0.944 0.5]);
end

function [posX,posY,Width,Height]=centralizeWindow(Width_,Height_)

%Size of the screen
screensize = get(0,'Screensize');
Width = screensize(3);
Height = screensize(4);

posX = (Width/2)-(Width_/2);
posY = (Height/2)-(Height_/2);
Width=Width_;
Height=Height_;

end

end