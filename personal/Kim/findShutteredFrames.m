function [shutterData,times]=findShutteredFrames(obj,movieOrder)
% If using command to shutter PMTs, get data on when PMTs are shuttered

% Look for PMT shutter command in same path as selected movie files
movName=obj.Movies{1};
dirBreaks=regexp(movName,'\','start');
shutterPath=movName(1:dirBreaks(end));
listing=dir([shutterPath obj.sabaMetadata.nameShutterCommand '*.mat']);
listingnames=cell(1,length(listing));
for i=1:length(listing)
    listingnames{i}=listing(i).name;
end

% Sort files by number
% movNumbers=nan(1,length(listingnames));
% for i=1:length(listingnames)
%     currMovName=listingnames{i};
%     currMovName=fliplr(currMovName);
%     startInd=regexp(currMovName,'\.','once');
%     currMovName=currMovName(startInd+1:end);
%     isNumberInd=regexp(currMovName,'\d');
%     numberMovName=currMovName(isNumberInd);
%     numberMovName=fliplr(numberMovName);
%     movNumbers(i)=str2num(numberMovName);
% end
% [~,inds]=sort(movNumbers);
% listingnames=listingnames(inds);

shutterData=[];
if ~isempty(listing)
    % PMT shutter command saved during acquisition
    % For each movie file, get associated PMT shutter command
    
    for i=1:length(movieOrder)
        ci=movieOrder(i);
        s=obj.Movies{ci};
        parts=regexp(s,'\','split');
        movName=parts{end};
        fi=regexp(movName,'.tif');
        movName=movName(1:fi-1);
        movNumber=movName(end-2:end);
        % Check that expected file is in directory
        shutterFile=[obj.sabaMetadata.nameShutterCommand '_' num2str(str2num(movNumber)) '.mat'];
        if any(strcmp(listingnames,shutterFile))
            warning('off','MATLAB:unknownObjectNowStruct'); % import wave as struct
            % Load command to shutter
            w=load([shutterPath shutterFile]);
            warning('on','MATLAB:unknownObjectNowStruct'); 
            f=fieldnames(w);
            w=w.(f{1});
            if isempty(shutterData)
                shutterData=nan(length(movieOrder),length(w.data));
            end
            shutterData(i,:)=w.data;
%             if length(w.data)>length(shutterData(i,:))
%                 temp=shutterData;
%                 shutterData=[temp nan(length(movieOrder),length(w.data)-length(shutterData(i,:)))];
%             elseif length(w.data)<length(shutterData(i,:))
%                 shutterData(i,1:length(w.data))=w.data;
%             else
%                 shutterData(i,:)=w.data;
%             end
        else
            disp(['Missing ' obj.sabaMetadata.nameShutterCommand ' file from movie directory']);
        end
    end
end

if obj.sabaMetadata.optoShuttersImaging==true
    optoData=findPhysData(obj,movieOrder,obj.sabaMetadata.nameOptoStim);
    if ~isempty(optoData)
        if isequal(size(shutterData),size(optoData))
            % Command to opto laser less than state.optoCommandThresh does not give output
            optoData(optoData<obj.sabaMetadata.optoCommandThresh*obj.sabaMetadata.optoScaleFactor)=0;
            shutterData=shutterData+optoData;
        else
            error('Size of shutterData does not match size of optoData');
        end
    end
end

if isempty(shutterData)
    % No shutter data 
    disp('No shutter data found - using full movies');
    times=[];
    return
else
    samplingRate=obj.sabaMetadata.phys.settings.inputRate; % Get sampling rate of shutterData
    times=0:1/samplingRate:(1/samplingRate)*size(shutterData,2)-(1/samplingRate);
    [status,mess,messid]=mkdir([shutterPath obj.sabaMetadata.saveShutterDataFolder]);
    if strcmp(messid,'MATLAB:MKDIR:DirectoryExists')
        button=questdlg('Do you want to overwrite existing ShutterData directory?');
        switch button
            case 'Yes'
            case 'No'
                error('ShutterData directory already exists');
            case 'Cancel'
                error('ShutterData directory already exists');
        end
    end
    if status==1
        save([shutterPath obj.sabaMetadata.saveShutterDataFolder '\shutterData.mat'],'shutterData');
        save([shutterPath obj.sabaMetadata.saveShutterDataFolder '\shutterData_times.mat'],'times');
    else
        disp('Could not save shutter data');
    end
end
    
    
end

function physData=findPhysData(obj,movieOrder,nameCommand)

% Look for phys command in same path as selected movie files
movName=obj.Movies{1};
dirBreaks=regexp(movName,'\','start');
physPath=movName(1:dirBreaks(end));
listing=dir([physPath nameCommand '*.mat']);
listingnames=cell(1,length(listing));
for i=1:length(listing)
    listingnames{i}=listing(i).name;
end

physData=[];
if ~isempty(listing)
    % Phys command saved during acquisition
    % For each movie file, get associated phys command
    
    for i=1:length(movieOrder)
        ci=movieOrder(i);
        s=obj.Movies{ci};
        parts=regexp(s,'\','split');
        movName=parts{end};
        fi=regexp(movName,'.tif');
        movName=movName(1:fi-1);
        movNumber=movName(end-2:end);
        % Check that expected file is in directory
        physFile=[nameCommand '_' num2str(str2num(movNumber)) '.mat'];
        if any(strcmp(listingnames,physFile))
            warning('off','MATLAB:unknownObjectNowStruct'); % import wave as struct
            % Load phys command
            w=load([physPath physFile]);
            warning('on','MATLAB:unknownObjectNowStruct'); 
            f=fieldnames(w);
            w=w.(f{1});
            if isempty(physData)
                physData=nan(length(movieOrder),length(w.data));
            end
            physData(i,:)=w.data;
        else
            disp(['Missing ' nameCommand ' file from movie directory']);
        end
    end
end

if isempty(physData)
    % No phys data 
    disp('No phys data found');
    times=[];
end
   
end

    
    
        