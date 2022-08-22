classdef QuPathUtils
    
    properties (Constant = true)
        
        sCurrentQuPathVersion = "0.3.2";
        
%         % QuPath V1        
%         sLabelmapCodeQuPath1 = "-labels";        
%         sLabelmapRegexpQuPath1 = "TCGA*)-labels.*";        
%         sImageRegexpQuPath1 = "TCGA*).*";
        
        % all regular expressions are based on the automatic filename from
        % QuPath
        
        % Regular expressions for search using "token"
        sResizeRegexpForToken = ".*d=(\d*),.*";
        sXLocationRegexpForToken = ".*x=(\d*),.*";
        sYLocationRegexpForToken = ".*y=(\d*),.*";
        sWidthRegepForToken = ".*w=(\d*),.*";
        sHeightRegexpForToken = ".*h=(\d*),.*";
        
        % Regular expressions for file search in directory
        sImageRegexp = "*].*";
        sLabelmapCode = "-labelled";
        sLabelmapRegexp = "*]-labelled.*";
    end
    methods
        function obj = QuPathUtils()
        end
    end
    methods (Static = true, Access = public)
        function [dXOrigin, dYOrigin, dWidth, dHeight, dResizeFactor] =...
                GetTileCoordinatesFromName(chTileFilename)
            
            % format: [downsampleFactor*, X, Y, width, height]
            % *downsample factor may or may not be there. d>1 = shrunk from
            % original, d>1, the original pixel side length is less than 0.2520
            c1chTileInfo = regexpi(chTileFilename , '\[.+\]','match');
            c1chTileInfo = split(c1chTileInfo{1}(2:end-1) , ',');
            vdTileInfoNum = str2double(cellfun(@(c) c(3:end), c1chTileInfo, 'UniformOutput',false));
            
            dXOrigin = vdTileInfoNum(contains(c1chTileInfo,'x'));
            dYOrigin = vdTileInfoNum(contains(c1chTileInfo,'y'));
            dWidth = vdTileInfoNum(contains(c1chTileInfo,'w'));
            dHeight = vdTileInfoNum(contains(c1chTileInfo,'h'));
            
            % if there is a downsample factor, get it
            if ~isempty(find(contains(c1chTileInfo,'d')))
                dResizeFactor = vdTileInfoNum(contains(c1chTileInfo,'d'));
            else
                dResizeFactor = 1; % ie no resizing was done
            end
            
        end
        
        function [chImageRegexp, chLabelMapRegexp, chLabellingCode, sCurrentQuPathVersion] =...
                ReturnCodeBasedOnQuPathVersion(bQuPath1)
            % Only QuPath1 is a problem now
            
            if bQuPath1
                chLabellingCode = QuPathUtils.chLabelmapCodeQuPath1;
                chImageRegexp = QuPathUtils.chImageRegexpQuPath1;
                chLabelMapRegexp = chLabelmapRegexpQuPath1;
            else
                chLabellingCode = QuPathUtils.chLabelmapCodeQuPath2and3;
                chLabelMapRegexp = QuPathUtils.chLabelmapRegexpQuPath2and3;
                chImageRegexp = QuPathUtils.chImageRegexpQuPath2and3;
            end
            sCurrentQuPathVersion = QuPathUtils.sCurrentQuPathVersion;
        end
        

        
        function VerifyThatWSIsHaveContours(c1chRequestedWSIs)
            % chRequestedFilePath = 'D:\Users\sdammak\Experiments\LUSCCancerCells\SlidesToContour\All The Slides That Should have Contours.txt';
            % fid = fopen(chRequestedFilePath);
            % data = textscan(fid,'%s');
            % fclose(fid);
            % c1chRequestedWSIs = data{:};
            
            chContourDir = 'D:\Users\sdammak\Data\LUSC\Original\Segmentations\CancerMC\Curated';
            stContourPaths = dir([chContourDir,'\TCGA-*.qpdata']);
            c1chContoured = {stContourPaths.name}';
            
            % Make vector finding the position of the contoured samples in the requested list
            dFoundIndices = nan(length(c1chContoured),1);
            
            for iContouredSample = 1:length(c1chContoured)
                
                c1chIndexInRequested = strfind(c1chRequestedWSIs, c1chContoured{iContouredSample});
                dIndexInRequested = find(not(cellfun('isempty',c1chIndexInRequested)));
                if isempty(dIndexInRequested)
                    error('A slide that was not requested was contoured!')
                end
                
                dFoundIndices(iContouredSample) = dIndexInRequested;
            end
            dCleanIndices = dFoundIndices(~isnan(dFoundIndices));
            c1chRequestedAndCompleted = c1chRequestedWSIs(dCleanIndices);
            c1chRequestedWSIs(dCleanIndices) = [];
            
            disp(['These slides were not in the Contoured folder:', newline, c1chRequestedWSIs{:}])
        end
    end
end

