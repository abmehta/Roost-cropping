%%Get roost information
path = 'data/';
csvfile = fullfile(path,'get_labels_meters.csv');
fmt = '%d %s %d %s %d %d %d %d %d %d %d %f %f %f';
radardata = csv2struct(csvfile,fmt);

%%Loop to go over multiple lines in file
for counter=1:2030
    roost = radardata(counter);
    
    %%Get scan
    filename = roost.filename;
    station = roost.station;
    if roost.month<=9 
        month = strcat('0',int2str(roost.month));
    else
        month = int2str(roost.month);
    end
    if roost.day<=9
        day = strcat('0',int2str(roost.day));
    else
        day = int2str(roost.day);
    end 
    path = strcat('data/stations/',roost.station,'/',int2str(roost.year),'/',month,'/',day,'/');
    %path=roost.station+'/'+roost.filename;
    radar = rsl2mat(fullfile(path,filename),station);

    %%Read in Cartesian coordinates
    rmax = 150000;
    dim = 1800;
    [data,x,y] = sweep2cart(radar.dz.sweeps(1),rmax,dim);

    %Create grid
    lim = rmax*[-1 1];
    s = create_grid(lim,lim,dim,dim);

    %Roost info
    roost_x = roost.x;
    roost_y = roost.y;
    roost_r = roost.r;

    %Get coordinates
    [i, j] = xy2ij(roost_x,-roost_y,s);

    %%Get coordinates within 2*radius of roost center
    [di, dj] = dxy2dij(2*roost_r,2*roost_r,s);

    %Select relevant coodinates
    I = i-di : i+di;
    J = j-dj : j+dj;
    
    %Fix points that fall outsde grid
    I = I(I>0);
    J = J(J>0);
    I = I(I<1800);
    J = J(J<1800);
    
    %Crop data
    patch = data(I,J);
    
    %%Dealing with NaN values
    patch_min = min(min(patch));
    patch_max = max(max(patch));
    nans = isnan(patch);
    abs_min = patch_min-((patch_max-patch_min)/5);
    patch(nans) = abs_min;

    %%Resize image
    patch = imresize(patch, [200, 200]);

    %%Set custom color axis
    dzlim = [abs_min, patch_max];
    
    %Set colormap
    ddd=[0 0 0;jet(10)];
    cmap = colormap(ddd);
    
    % Save image as gif file
    %new_filename = strcat(regexprep(filename,'\.[^\.]*$',''),'_crop');
    scale_patch = mat2ind(patch,dzlim,cmap);
    imshow(scale_patch,cmap);
    imwrite_gif_nan(scale_patch,cmap,sprintf('data/cropped_images/%d.gif',counter));    
end