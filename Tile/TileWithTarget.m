classdef TileWithTarget < Tile
    
    % *********************************************************************
    % *                            PROPERTIES                             *
    % *********************************************************************
    
    properties
        oTarget
    end
    
    % *********************************************************************
    % *                        SCALAR TILE METHODS                        *
    % *********************************************************************
    
    % CONSTRUCTOR
    methods
        function obj = TileWithTarget(sTileFilepath, oTarget, NameValueArgs)
            arguments
                sTileFilepath
                oTarget
                NameValueArgs.bFromTCGA
            end
            c1xNameValueArgs = GeneralUtils.ConvertNameValueArgsStructToCell(NameValueArgs);
            obj = obj@Tile(sTileFilepath, c1xNameValueArgs{:});
            obj.oTarget = oTarget;
        end
        
    end
    

    
    % *********************************************************************
    % *                        TILE VECTOR METHODS                        *
    % *********************************************************************
    
    % CONSTRUCTOR
    methods (Static)
        %         function voTilesWithTargets = AddTargetsToTiles(voTiles, voTargets)
        %         end
        function tData = ConvertToTableForPython(voTiles)
            c1sPaths = cell(length(voTiles),1);
            c1xLabels = cell(length(voTiles),1);
            
            for iTile = 1:length(voTiles)
                c1sPaths{iTile} = voTiles(iTile).GetTileFilepath();
                c1xLabels{iTile} = voTiles(iTile).oTarget.GetTargetForPython();
            end           
                      
            tData = table(c1sPaths, c1xLabels);
        end
        
        function voTargets = GetTargetsForPython(voTiles)
            c1oTargets = cell(length(voTiles), 1); 
            for iTile = 1:length(voTiles)
                c1oTargets{iTile} = voTiles(iTile).oTarget.GetTargetForPython(); 
            end
            voTargets = CellArrayUtils.CellArrayOfObjects2MatrixOfObjects(c1oTargets);
        end        
        
    end
    
end

