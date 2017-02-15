function [minMode maxMode]=findShutterInMovies(obj,movieOrder)

randMovs=randi([1 length(movieOrder)],1,4);
randMovs=movieOrder(randMovs);

% Display distribution of average line fluorescence values across trials
% for 4 example movies (show Z-score)
figure();
for i=1:length(randMovs)
    [mov,scanImageMetadata]=obj.readRaw(randMovs(i),'single');
    subplot(4,1,i);
    hists_n=nan(size(mov,3),100);
    hists_x=nan(size(mov,3),100);
    meds=median(double(mov(1:end)));
    stds=std(double(mov(1:end)));
    for j=1:size(mov,3)
        temp=mov(:,:,j);
        [n,x]=hist((double(nanmean(temp,2))-meds)/stds,100);
        hists_n(j,:)=n;
        hists_x(j,:)=x;
    end
    for j=1:size(mov,3)
        plot(hists_x(j,:),hists_n(j,:));
        hold on;
    end
end

% Let user specify cut-offs for defining imaging frames without artifacts
% The frames without artifacts should have all average line fluorescence
% Z-scores between minMode and maxMode
minMode=input('High threshold cut-off for min mode (no data):');
maxMode=input('Low threshold cut-off for max mode (shuttered data during stim):');

disp('Using high threshold cut-off for min mode (no data):');
disp(minMode);
disp('Low threshold cut-off for max mode (shuttered data during stim):');
disp(maxMode);

% Consider any trial with an average line Z-score below minMode or above
% maxMode an imaging trial with an artifact (due to shutter/opto stim)