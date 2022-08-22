classdef BinaryMaskTarget < Target
    % *********************************************************************
    % *                            PROPERTIES                             *
    % *********************************************************************
    
    properties (SetAccess = immutable, GetAccess = public)
        sTrueClassName
        sFalseClassName
    end
    
    % *********************************************************************
    % *                       SCALAR TARGET METHODS                       *
    % *********************************************************************
    methods
        function obj = BinaryMaskTarget(sMaskFilepath, sTargetName, NameValueArgs)
            %obj = BinaryMaskTarget(sMaskPath, 'sTargetName', 'CancerNoCancerMasks')
           arguments
               sMaskFilepath
               sTargetName
               NameValueArgs.sCentreID
               NameValueArgs.sPatientID
               NameValueArgs.sSlideID
               NameValueArgs.sTileID
               NameValueArgs.bFromTCGA
               NameValueArgs.sTargetDescription
           end
            
           % Use the mask path as the target source
           sTargetSource = sMaskFilepath;
           
           % If this is from the TCGA, use TCGA tools to automatically
           % assign IDs
           if isfield(NameValueArgs,'bFromTCGA') && NameValueArgs.bFromTCGA
               
               % Deconstruct the filename for the IDs
               sTileFilepath = strrep(sMaskFilepath, TileImagesUtils.sMaskCode, "");
               [NameValueArgs.sCentreID, NameValueArgs.sPatientID, NameValueArgs.sSlideID, NameValueArgs.sTileID] =...
                   TCGAUtils.GetIDsFromTileFilepaths(sTileFilepath);
           end
           
           c1xNameValueArgs = GeneralUtils.ConvertNameValueArgsStructToCell(NameValueArgs,'vsFieldsToIgnore','bFromTCGA');
           obj = obj@Target(sTargetName, sTargetSource, c1xNameValueArgs{:});
           
        end
        
        function oPercentCoverageTarget = ConvertToPercentCoverageTarget(obj)

            m3bMask = imread(obj.GetMaskPath());
            dPercentCoverage = (sum(m3bMask(:)))/numel(m3bMask);

            c1xObjInfo = GeneralUtils.ConvertObjToCellArray(obj, 'vsPropertiesToIgnore',...
                ["sTargetName", "sTargetSource","sTrueClassName","sFalseClassName"]);
            oPercentCoverageTarget = ScalarTarget(dPercentCoverage, obj.sTargetName, obj.sTargetSource, c1xObjInfo{:});                        
        end

    end
    
    % GETTERS
    methods
        function chMaskPath = GetMaskPath(obj)
            chMaskPath = obj.sTargetSource();
        end
        function chTarget = GetTargetForPython(obj)
            chTarget = obj.GetMaskPath();
        end
    end
    
    % *********************************************************************
    % *                       TARGET VECTOR METHODS                       *
    % *********************************************************************
    
    % *********************************************************************
    % *                   TARGET-SPECIFIC TILE METHODS                    *
    % *********************************************************************
    
   methods (Static)
       function voTiles = MakeTilesWithMaskTargetsFromDir(sTileAndMaskDir, sTargetName,NameValueArgs)
           arguments
               sTileAndMaskDir string
               sTargetName
               NameValueArgs.bFromTCGA
               NameValueArgs.sTargetDescription
               NameValueArgs.sTargetSource
               NameValueArgs.sPartialFileDirectory
           end
            
           % Get list of masks in dir
           stMasksInDir = dir(sTileAndMaskDir + "*" + TileImagesUtils.sMaskCode + "*");
           
           % Maks vector of tiles
           c1oTiles = cell(length(stMasksInDir), 1);
           
           dtStartTime = datetime('now');
           dtNextAllowableTime = dtStartTime;
           
           for iMask = 1:length(stMasksInDir)
               
               % Make target
               chMaskFilepath = sTileAndMaskDir + stMasksInDir(iMask).name;
               c1xNameValueArgs = GeneralUtils.ConvertNameValueArgsStructToCell(NameValueArgs, 'vsFieldsToIgnore',"sPartialFileDirectory");
               oMask = BinaryMaskTarget(chMaskFilepath, sTargetName, c1xNameValueArgs{:});

               % Make TileWithTarget object, passing in target
               chTileFilepath = strrep(chMaskFilepath, TileImagesUtils.sMaskCode, '');
               if isfield(NameValueArgs,'bFromTCGA') && NameValueArgs.bFromTCGA
               c1oTiles{iMask} = TileWithTarget(chTileFilepath, oMask, 'bFromTCGA', NameValueArgs.bFromTCGA);
               else
                   c1oTiles{iMask} = TileWithTarget(chTileFilepath, oMask);
               end
                   
               % Estimate remaining time and report ite every 10min
               dtCurrentTime = datetime('now');
               
               % Adding "next alloable time" avoids the message being
               % output for every loop run in a minute
               if (rem(dtCurrentTime.Minute, 10) == 0) && (dtCurrentTime >= dtNextAllowableTime)
                   dtAverageTimePerMask = (dtCurrentTime - dtStartTime)/iMask;
                   dtRemainingTime = dtAverageTimePerMask*(length(stMasksInDir)-iMask);
                   disp("Time left is: " + string(dtRemainingTime) + " (HH:MM:SS)")
                   if ~isempty(NameValueArgs.sPartialFileDirectory)
                       save(NameValueArgs.sPartialFileDirectory + "\Workspace_PartialTiles.mat")
                   end
                   dtNextAllowableTime = dtCurrentTime + minutes(1);
               end
           end
           
           voTiles = CellArrayUtils.CellArrayOfObjects2MatrixOfObjects(c1oTiles);
       end
       
       function voTiles = ConvertTilesBinaryMaskTargetsToPercentCoverageTargets(voTiles)

           for iTile = 1:length(voTiles)
               voTiles(iTile).oTarget = voTiles(iTile).oTarget.ConvertToPercentCoverageTarget();
           end
       end
   end
end

