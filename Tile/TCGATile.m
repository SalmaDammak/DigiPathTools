classdef TCGATile
    
    % *********************************************************************
    % *                            PROPERTIES                             *
    % *********************************************************************
    
    % IDENTIFIERS
    properties (SetAccess = immutable, GetAccess = public)
        sTileFilepath
        sFilename
        sTileID
        sSlideID
        sPatientID
        sCentreID
        %sCentreName
    end
    
    % IMAGE PROPERTIES
    properties
        sImageExtension
        sChannels = "RGB(default)"
        sStain = "H&E(default)"
    end
    
    % SIZE
    properties (SetAccess = immutable, GetAccess = public)
        %dSourceSlideResolution_MicronsPerPixel
        %dTileResolution_MicronsPerPixel
        dResizeFactor
    end
    
    % LOCATION
    properties (SetAccess = immutable, GetAccess = public)
        dTileUpperRightCornerLocationInSourceSlideX_Pixels
        dTileUpperRightCornerLocationInSourceSlideY_Pixels
    end
    
    properties (Constant)
        %sSlideResolutionListFilepath = '';
        %sCenterNameAndCodeFilepath = '';
    end
    % *********************************************************************
    % *                        SCALAR TILE METHODS                        *
    % *********************************************************************
    
    % CONSTRUCTOR
    methods
        function obj = Tile(sTileFilepath, NameValueArgs)
            arguments
                sTileFilepath
                NameValueArgs.bQuPath1 = false
                NameValueArgs.sStain
                NameValueArgs.sChannels
            end
            
            % IDENTIFIERS
            [obj.sCentreID, obj.sPatientID, obj.sSlideID, obj.sTileID, obj.sFilename] =...
                TCGAUtils.GetIDsFromTileFilepath(sTileFilepath);
            obj.sTileFilepath = sTileFilepath;
            
            % IMAGE PROPERTIES
            obj.sImageExtension = regexp(obj.sFilename, '.*\.([a-zA-Z]+)', 'tokens','once');
            if isfield(NameValueArgs,'sChannels') % default in properties
                obj.sChannels = NameValueArgs.sChannels;
            end
            if isfield(NameValueArgs,'sStain') % default in properties
                obj.sStain = NameValueArgs.sStain;
            end
            
            % SIZE
            %dSourceSlideResolution_MicronsPerPixel = tile.GetSourceSlideResolution(obj.sSlideID); % TO DO
            
            % Make a QuPath utils objects to access the right regular
            % expressions for extractin tiles with the latest version of QuPath
            oQuPathUtils = QuPathUtils();
            dResizeFactorValue = double(regexp(obj.sFilename, oQuPathUtils.sResizeRegexpForToken,'tokens','once'));
            
            % If a resize factor doesn't exist in the image name, it means
            % that the image was not resized
            if isempty(dResizeFactorValue)
                dResizeFactorValue = 1;
            end
            obj.dResizeFactor = dResizeFactorValue;
            %obj.dTileResolution_MicronsPerPixel = dSourceSlideResolution_MicronsPerPixel/dResizeFactor;
            
            % LOCATION
            obj.dTileUpperRightCornerLocationInSourceSlideX_Pixels = ...
                double(regexp(obj.sFilename, oQuPathUtils.sXLocationRegexpForToken,'tokens','once'));
            obj.dTileUpperRightCornerLocationInSourceSlideY_Pixels = ...
                double(regexp(obj.sFilename, oQuPathUtils.sYLocationRegexpForToken,'tokens','once'));
        end
    end
    
    % GETTERS
    methods
        function sFileTilepath = GetTileFilepath(obj)
            sFileTilepath = obj.sTileFilepath;
        end
        function sPatientID = GetPatientID(obj)
            sPatientID = obj.sPatientID;
        end
        function sCentreID = GetCentreID(obj)
            sCentreID = obj.sCentreID;
        end
    end
    
    methods (Static)
        %function dResolution_MicronsPerPixelSide = GetSourceSlideResolution(sSlideID)
        %load(obj.sSlideResolutionListFilepath)
        %end
    end
    
    
    %
    % *********************************************************************
    % *                        TILE VECTOR METHODS                        *
    % *********************************************************************
    
    % GETTERS
    methods (Static)
        function vsPatientIDs = GetPatientIDs(voTiles)
            vsPatientIDs = strings(length(voTiles), 1);
            for iTile = 1:length(voTiles)
                vsPatientIDs(iTile) = voTiles(iTile).GetPatientID();
            end
        end
        function vsCentreIDs = GetCentreIDs(voTiles)
            vsCentreIDs = strings(length(voTiles), 1);
            for iTile = 1:length(voTiles)
                vsCentreIDs(iTile) = voTiles(iTile).GetCentreID();
            end
        end
    end
    
    % SPECIAL FINDERS/SELCTORS
    methods (Static)
        function vbIndices = FindTilesWithTheseIDs(voTiles, vsIDs, NameValueArgs)
            arguments
                voTiles
                vsIDs
                NameValueArgs.bByPatientIDs (1,1) logical = false
                NameValueArgs.bByCentreIDs (1,1) logical = false
            end
            
             % Get group IDs based on what is used
            if NameValueArgs.bByPatientIDs
                vsGroupIDs = Tile.GetPatientIDs(voTiles);
            elseif NameValueArgs.bByCentreIDs
                vsGroupIDs = Tile.GetCentreIDs(voTiles);
            end
            
            % Loop through the IDs to see which elements match it
            vbIndices = false(length(vsGroupIDs),1);
            for iID = 1:length(vsIDs)
                sCurrentID = vsIDs(iID);
                vbCurrentIDIndices = vsGroupIDs == sCurrentID;
                
                % This operation turns the current ID indices to true in
                % the overall "selector" vector
                vbIndices = or(vbIndices, vbCurrentIDIndices);
            end
                        
        end
    end
    
    methods (Static)
           function [vbTrainTileIndices, vbTestTileIndices] = PerformRandomTwoWaySplit(voTiles,dFractionGroupsInTraining, NameValueArgs)
               arguments
                   voTiles
                   dFractionGroupsInTraining
                   NameValueArgs.bByPatientID (1,1) logical = false
                   NameValueArgs.bByCentreID (1,1) logical = false
               end
               %###################### TO DO ##############################
               % - check that there are enough groups for a split (e.g.
               %    more than one center or one patient given)
               %###########################################################
            
               % Get group IDs based on what is used for splitting
               if NameValueArgs.bByPatientID
                   vsGroupIDs = Tile.GetPatientIDs(voTiles);
                   chGroupName = 'bByPatientIDs';
               elseif NameValueArgs.bByCentreID
                   vsGroupIDs = Tile.GetCentreIDs(voTiles); 
                   chGroupName = 'bByCentreIDs';
               end
               
               [vbTrainSlideIndices, vbTestSlideIndices] = TCGAUtils.PerformRandomTwoWaySplit(vsSlideNames,dFractionGroupsInTraining, NameValueArgs);
               vsUniqueGroupIDs = unique(vsGroupIDs);
               dNumGroups = length(vsUniqueGroupIDs);
               
               % Get whole number of groups for training from fraction
               dNumTrainGroups = round(dNumGroups * dFractionGroupsInTraining);
               
               % Randomly select which groups will go in training.
               dMaxRandomNumber = dNumGroups;
               dNumRandomNumbers = dNumTrainGroups;
               vdTrainGroupIndices = randperm(dMaxRandomNumber, dNumRandomNumbers);
               vsTrainGroups = vsUniqueGroupIDs(vdTrainGroupIndices);
               
               % Find the corresponding tiles
               vbTrainTileIndices = Tile.FindTilesWithTheseIDs(voTiles, vsTrainGroups, chGroupName, true);
               vbTestTileIndices = ~vbTrainTileIndices;                
        end
        
    end
    
    
end

