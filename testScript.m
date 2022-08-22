sTileAndMaskDir = 'E:\Users\sdammak\Repos\DigiPathTools\SomeTiles\';
voTiles = BinaryMaskTarget.MakeTilesWithMaskTargetsFromDir(...
    sTileAndMaskDir,"Cancer coverage mask");
tTiles = TileWithTarget.ConvertToTableForPython(voTiles);

voPercentCoverageTiles = BinaryMaskTarget.ConvertTilesBinaryMaskTargetsToPercentCoverageTargets(voTiles);
voBinaryTiles = ScalarTarget.ConvertTilesScalarTargetsToBinaryScalarTargets(voPercentCoverageTiles, 'dPositiveIsMoreThanThreshold',0.03);