clear;clc;
caffe.set_mode_cpu();
% caffe.set_mode_gpu();
caffe.set_device(0);
caffe.reset_all();

addpath('./evaluation_func/');
addpath('./evaluation_func/matlabPyrTools-master/');

up_scale=2; % 2 | 3 | 4

for ver_num = 1 : 1
    switch ver_num
        case {1}
            version = 'D4C6R0';
        case {2}
            version = 'D4C7R0';
        case {3}
            version = 'D4C8R0';
        case {4}
            version = 'D5C8R0';
        case {5}
            version = 'D6C8R0';
        case {6}
            version = 'D5C8R1';
        case {7}
            version = 'D6C8R1';           
    end    
    for dataset=1:4
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
%psnr_DERI=zeros(200,1);
for iter=500000:500000:500000
% model = 'DERI_x2_D5C8R0_deploy.prototxt';  
model = ['DERI_x',num2str(up_scale),'_',version,'_deploy.prototxt'];
weights = ['../train/caffemodel_x',num2str(up_scale),'_',version,'/DERI_iter_',num2str(iter),'.caffemodel'];
% weights = '../train/caffemodel_x2_D5C8R0/DERI_iter_300000.caffemodel';
% weights = ['caffemodel_x2_'.version,'/DERI_iter_',num2str(iter),'.caffemodel'];

net=caffe.Net(model,weights,'test');
% test_dataset='Set14'; % Set5 | Set14 | BSD100 | Urban100

testfolder=['test_data/' test_dataset '/'];         


savepath = 'results/';
folderResultCur = fullfile(savepath,[test_dataset,'_x',num2str(up_scale)]);
if ~exist(folderResultCur,'file')
    mkdir(folderResultCur);
end

if strcmp(test_dataset,'Set5') || strcmp(test_dataset,'Set14')|| strcmp(test_dataset,'Set14_1')|| strcmp(test_dataset,'Set14_2')|| strcmp(test_dataset,'Set14_3')|| strcmp(test_dataset,'Set14_4')|| strcmp(test_dataset,'Set14_5')
    filepaths=dir(fullfile(testfolder,'*.bmp'));
else
    filepaths=dir(fullfile(testfolder,'*.jpg'));
end

psnr_bic=zeros(length(filepaths),1);
psnr_idn=zeros(length(filepaths),1);

ssim_bic=zeros(length(filepaths),1);
ssim_idn=zeros(length(filepaths),1);
% 
% ifc_bic=zeros(length(filepaths),1);
% ifc_idn=zeros(length(filepaths),1);
% 
% time_idn=zeros(length(filepaths),1);

for i=1:length(filepaths)
    %% read groud truth image
    [add,imname,type]=fileparts(filepaths(i).name);
    im=imread([testfolder imname type]);
    dimension=size(im,3);
    %% work on illuminance only
    if size(im,3)>1
        im_ycbcr=rgb2ycbcr(im);
        im=im_ycbcr(:,:,1);
        im_cb=im_ycbcr(:,:,2);
        im_cr=im_ycbcr(:,:,3);
        im_cb=modcrop(im_cb,up_scale);
        im_cr=modcrop(im_cr,up_scale);
        im_cb_=shave(imresize(imresize(im_cb,1/up_scale,'bicubic'),up_scale,'bicubic'),[up_scale,up_scale]);
        im_cr_=shave(imresize(imresize(im_cr,1/up_scale,'bicubic'),up_scale,'bicubic'),[up_scale,up_scale]);
    end
    im_gnd=modcrop(im,up_scale);
    im_gnd=single(im_gnd)/255;
    im_l=imresize(im_gnd,1/up_scale,'bicubic');
    
    
    %% bicubic interpolation
    im_b=imresize(im_l,up_scale,'bicubic');
      

    im_input1=permute(im_l,[2,1,3]);
    net.blobs('data').reshape([size(im_input1),1,1]);
    im_input2=mycrop(im_b,up_scale);
    im_input2=permute(im_input2,[2,1,3]);
    net.blobs('bic').reshape([size(im_input2),1,1]);
    net.reshape();
    net.blobs('data').set_data(im_input1);
    net.blobs('bic').set_data(im_input2);
    net.forward_prefilled();
    im_result=net.blobs('sum').get_data();
    im_h = im_result';
%     time_idn(i)=toc;


    %% remove border
    im_h=myshave(uint8(im_h*255),up_scale);
    im_gnd=shave(uint8(im_gnd*255),[up_scale,up_scale]);
    im_b=shave(uint8(im_b*255),[up_scale,up_scale]);
    
    %% compute PSNR
     psnr_bic(i)=compute_psnr(im_gnd,im_b);
     psnr_idn(i)=compute_psnr(im_gnd,im_h);
    
    %% compute SSIM
     ssim_bic(i)=ssim_index(im_gnd,im_b);
     ssim_idn(i)=ssim_index(im_gnd,im_h);
    
    %% compute IFC
    
%     ifc_idn(i) = ifcvec(double(im_gnd),double(im_h));
%     ifc_bic(i)=ifcvec(double(im_gnd),double(im_b));
    
     %% save results
     if dimension>1
         imwrite(ycbcr2rgb(cat(3,im_h,im_cb_,im_cr_)),fullfile(folderResultCur,[imname,'_x',num2str(up_scale),'.png']));
     else
         imwrite(im_h,fullfile(folderResultCur,[imname,'_x',num2str(up_scale),'.png']));
     end
     save(fullfile(folderResultCur,['PSNR_',test_dataset,'_x',num2str(up_scale),'.mat']),'psnr_idn');
     save(fullfile(folderResultCur,['SSIM_',test_dataset,'_x',num2str(up_scale),'.mat']),'ssim_idn');
%     save(fullfile(folderResultCur,['IFC_', test_dataset,'_x',num2str(up_scale),'.mat']),'ifc_idn');
end

 fprintf('Mean PSNR for Bicubic: %f dB\n', mean(psnr_bic));
 fprintf('Mean PSNR for IDN: %f dB\n', mean(psnr_idn)); 

%psnr_DERI(iter/5000)=mean(psnr_idn);

end

%save(fullfile(folderResultCur,['PSNR_',test_dataset,'_x',num2str(up_scale),'_',version,'.mat']),'psnr_DERI');
% fprintf('Mean SSIM for Bicubic: %f \n', mean(ssim_bic));
% fprintf('Mean SSIM for IDN: %f \n', mean(ssim_idn)); 

% fprintf('Mean IFC for Bicubic: %f \n', mean(ifc_bic));
% fprintf('Mean IFC for IDN: %f \n', mean(ifc_idn)); 

% fprintf('Mean Time for IDN: %f \n', mean(time_idn));
    end
end