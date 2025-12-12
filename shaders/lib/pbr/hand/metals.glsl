if (heldItemId == 1002 || heldItemId2 == 1002) { //Iron
    smoothness = 0.8;
} else if (heldItemId == 1003 || heldItemId2 == 1003) { //Gold
    smoothness = pow24(lAlbedo);
} else if (heldItemId == 1004 || heldItemId2 == 1004) { //Diamond
    smoothness = pow16(lAlbedo);
}