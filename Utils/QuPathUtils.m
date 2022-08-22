classdef QuPathUtils
    
    properties (Constant = true)
        sCurrentQuPathVersion = "0.3.2";
        
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
    
    methods (Static = true, Access = public)
        function [dXOrigin, dYOrigin, dWidth, dHeight, dResizeFactor] =...
                GetTileCoordinatesFromName(sTileFilepath)
            % Note that filepath or filename are both okay here
            
            % Get filename
            vsFileparts = split(sTileFilepath, filesep);
            sFilename = vsFileparts(end);
            
            % Get location and size information
            dXOrigin = regexp(sFilename, QuPathUtils.sXLocationRegexpForToken, 'tokens','once');
            dYOrigin = regexp(sFilename, QuPathUtils.sYLocationRegexpForToken, 'tokens','once');
            dWidth = regexp(sFilename, QuPathUtils.sWidthRegepForToken, 'tokens','once');
            dHeight = regexp(sFilename, QuPathUtils.sHeightRegexpForToken, 'tokens','once');
            
            % If there is a downsample factor, get it
            dResizeFactor = regexp(sFilename, QuPathUtils.sResizeRegexpForToken, 'tokens','once');
            if isempty(dResizeFactor)
                dResizeFactor = 1;
                % warning("No resize factor was found so a factor of 1 was assumed.")
            end
        end
        
        function VerifyThatWSIsHaveContours(c1chRequestedWSIs, chContourDir)
            % e.g., paths
            % c1chRequestedWSIs = 'D:\Users\sdammak\Experiments\LUSCCancerCells\SlidesToContour\All The Slides That Should have Contours.mat';
            % chContourDir = 'D:\Users\sdammak\Data\LUSC\Original\Segmentations\CancerMC\Curated';
            
            stContourPaths = dir([chContourDir,'\*.qpdata']);
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

