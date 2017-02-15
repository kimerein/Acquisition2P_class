function movStruct = upsampleMovie(movStruct,Ntimes)

mov=movStruct.slice.channel.mov;
movsize=size(mov); % assumes mov is 3D
temp=mov(:,:,1);
x=1:size(mov,3);
step=(x(2)-x(1))/Ntimes;
newx=x(1):step:x(end);
newMov=interp1(x,reshape(mov,length(temp(1:end)),size(mov,3))',newx);
movStruct.slice.channel.mov=reshape(newMov',movsize(1),movsize(2),length(newx));