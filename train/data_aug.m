clear; 
%% To do data augmentation
folder = 'DIV2K_train_HR/';
savepath = 'DIV2K-aug/';
filepaths = dir(fullfile(folder,'*.png'));

if ~exist(savepath,'file')
    mkdir(savepath);
end

for i = 1 : length(filepaths)
    filename = filepaths(i).name;
    [add, im_name, type] = fileparts(filepaths(i).name);  %add is path, im_name is filename, and type is extention name
    image = imread(fullfile(folder, filename));
    
    count = 0;
    
    for angle = 0: 90 :270
        
        im_rot = imrotate(image, angle);
        
        for scale = 1.0 : -0.1 : 0.6
            im_down = imresize(im_rot, scale, 'bicubic');

            for j = 3 : -2 : 1  % 3--> not flip, 1-->flip horizontally
                if j == 3
                    im_flip = im_down;
                else
                    im_flip = flip(im_down, j);
                end
                imwrite(im_flip, [savepath im_name, '_' num2str(count) '.png']);
                count = count + 1;
            end
        end
    end  
end
