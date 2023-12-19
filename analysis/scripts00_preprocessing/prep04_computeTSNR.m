% 2022-12-02 Shuchen Liu
% compuete signal-to-noise ratio
% adapted from Moritz's script (MW_computeTSNR.m)

clear
subvec = [2 4:12 14 16:22 24:30];
% subvec = [16:22 24:30];
% path_scans = '../input.Preprocessed_Scans';
% folders_sub_scans = dir([path_scans '/PSUB*']);
path_scans = '../data_converted';
folders_sub_scans = dir([path_scans '/*SUB*']);


for isub = subvec
    subfolder_scans = [folders_sub_scans(isub).folder '/' folders_sub_scans(isub).name];
%     folders_run = dir([subfolder_scans '/*_WAR_run*']);
    folders_run = dir([subfolder_scans '/ep2d*']);
    nrun = length(folders_run);

    for irun=1:nrun
        
        subfolder_run = [folders_run(irun).folder '/' folders_run(irun).name];
        f_scans = spm_select('FPList', subfolder_run, '^waf.*.img$');

        for is =1:size(f_scans,2)
            MAPnii(:,:,:,is) = niftiread(f_scans(is,:));
        end
        
        dim = size(MAPnii);
        nTpts = dim(4);
        nSlices = dim(3);
        
        figure;
        for is = 1:nSlices
            subplot(8, 8, is);
            mat = mean(single(shiftdim(MAPnii(:,:,is,:),3))) ./ std(single(shiftdim(MAPnii(:,:,is,:),3)));
            mat = shiftdim(mat,1);
            mat = fliplr(mat);
            mat = rot90(mat);
            h = imagesc(mat);
            set(gca, 'xtick', [], 'ytick', []);
            hParent = get(h, 'Parent');
            set(hParent, 'CLim', [0 200]);
            title(sprintf('mean: %0.1f',nanmean(mat(:))),'Fontsize',7);
            
            % count spikes
            temp = single(shiftdim(MAPnii(:,:,is,:),3));
            count=0;
            for i1=1:size(temp,1)
                for i2=1:size(temp,2)
                    for i3=1:size(temp,3)
                        if temp(i1,i2,i3)> 800
                            count=count+1;
                        end
                    end
                end
            end
            %hist(temp);
            nTemp = size(temp,1)*size(temp,2)*size(temp,3);
            %disp(count/nTemp);
            
            %hcbar = colorbar;
        end

        subplot(8, 8, 64);
        title(sprintf('sub: %d, run %d',isub, irun));
        caxis([0 200]);
        hcbar = colorbar;
        set(gca, 'Visible', 'off');
        set(gca, 'fontsize', 6);
        
        set(gcf, 'PaperPosition', [0 0 9 8]); %x_width=10cm y_width=15cm
        savepath = sprintf('../reports/TSNR_waf/TSNR_S%0.2d_Run%0.2d', isub, irun);
        title(sprintf('all betas, sub%d',isub));
        print(savepath,'-djpeg','-r300');
        close all
        
    end
end