function [movStruct,smallSize,bigSize,cropHere]=cropMovies(movStruct,non_art_range,obj)

blank_default=obj.sabaMetadata.turnAroundBlank_side1; % in pixels
blank_default2=obj.sabaMetadata.turnAroundBlank_side2; % in pixels

mov=movStruct.slice.channel.mov;
smallSize=[size(mov,1) size(mov,2)];
bigSize=[size(mov,1) size(mov,2)];
cropHere.columns=zeros(1,size(mov,2)); % columns to crop
cropHere.rows=zeros(1,size(mov,1)); % rows to crop

% Try using non_art_range to infer which pixels to crop
testMov=reshape(mov(:,:,2),size(mov,1),size(mov,2));
% Z score
meds=median(testMov(1:end));
stds=std(testMov(1:end));
testMov=(testMov-meds)./stds;
nanscan=nanmean(testMov,1);
cropTheseColumns=nanscan<non_art_range(1);
figure();
subplot(1,2,1);
imagesc(reshape(mov(:,:,2),size(mov,1),size(mov,2)));
colormap(gray);
subplot(1,2,2);
movWCrop=testMov(:,cropTheseColumns==0);
imagesc(movWCrop);
button=questdlg('Use this cropping?','Crop movies for motion correction','Cancel');
switch button
    case 'Yes'
        % Crop
        cropHere.columns=cropTheseColumns; % columns to crop
        cropHere.rows=zeros(1,size(mov,1)); % rows to crop
        mov=mov(:,cropTheseColumns==0,:);
        smallSize=[size(mov,1) size(mov,2)];
        movStruct.slice.channel.mov=mov;
    case 'No'
        % Try default crop from initialization
        figure();
        subplot(1,2,1);
        imagesc(reshape(mov(:,:,2),size(mov,1),size(mov,2)));
        colormap(gray);
        subplot(1,2,2);
        tempMov=reshape(mov(:,:,2),size(mov,1),size(mov,2));
        imagesc(tempMov(:,blank_default+1:end-blank_default2-1));
        colormap(gray);
        button2=questdlg('Use this cropping? (2nd movie is cropped)','Crop movies for motion correction','Cancel');
        switch button2
            case 'Yes'
                cropHere.columns=zeros(1,size(mov,2)); 
                cropHere.columns(1:blank_default)=1; % columns to crop
                cropHere.columns(end-blank_default2:end)=1; % columns to crop
                cropHere.rows=zeros(1,size(mov,1)); % rows to crop
                mov=mov(:,cropHere.columns==0,:);
                smallSize=[size(mov,1) size(mov,2)]; 
                movStruct.slice.channel.mov=mov;
            case 'No'
                % Do not crop anything
                cropHere.columns=zeros(1,size(mov,2)); % columns to crop
                cropHere.rows=zeros(1,size(mov,1)); % rows to crop
            case 'Cancel'
                return
        end           
    case 'Cancel'
        return
end

end
