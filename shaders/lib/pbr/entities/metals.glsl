if (currentRenderedItemId == 10002) { //Iron
    smoothness = pow32(lAlbedo);
} else if (currentRenderedItemId == 10003) { //Gold
    smoothness = pow24(lAlbedo);
} else if (currentRenderedItemId == 10004) { //Diamond
    smoothness = pow16(lAlbedo);
}