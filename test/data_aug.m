clear; 
for dataset=2:4
    switch dataset
        case{1}
            test_dataset='Set5';
        case{2}
            test_dataset='Set14';
        case{3}
            test_dataset='BSD100';
        case{4}
            test_dataset='Urban100'; 
    end
   
savepath=['test_data/',test_dataset,'_aug/'];
if ~exist(savepath,'file')
    mkdir(savepath);
end

testfolder=['test_data/' test_dataset '/'];
if strcmp(test_dataset,'Set5') || strcmp(test_dataset,'Set14')
    filepaths=dir(fullfile(testfolder,'*.bmp'));
else
    filepaths=dir(fullfile(testfolder,'*.jpg'));
end

for i = 1 : length(filepaths)
    filename = filepaths(i).name;
    [add, im_name, type] = fileparts(filepaths(i).name);  %add is path, im_name is filename, and type is extention name
    image = imread(fullfile(testfolder, filename));
    
    count = 0;
    
    for angle = 0: 90 :270        
        im_rot = imrotate(image, angle);
            for j = 3 : -2 : 1  % 3--> not flip, 1-->flip horizontally
                if j == 3
                    im_flip = im_rot;
                else
                    im_flip = flip(im_rot, j);
                end
                if strcmp(test_dataset,'Set5') || strcmp(test_dataset,'Set14')
                    imwrite(im_flip, [savepath im_name, '_' num2str(count) '.bmp']);
                else
                    imwrite(im_flip, [savepath im_name, '_' num2str(count) '.jpg']);
                end                
                count = count + 1;
            end
    end  
end
end