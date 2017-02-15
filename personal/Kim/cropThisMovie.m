function movStruct=cropThisMovie(movStruct,cropHere)

% Crop
mov=movStruct.slice.channel.mov;
mov=mov(:,cropHere.columns==0,:);
mov=mov(cropHere.rows==0,:,:);
movStruct.slice.channel.mov=mov;