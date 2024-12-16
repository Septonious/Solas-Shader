if (heldItemId == 10002 || heldItemId2 == 10002) { //Iron
    smoothness = 0.8;
} else if (heldItemId == 10003 || heldItemId2 == 10003) { //Gold
    smoothness = pow24(lAlbedo);
} else if (heldItemId == 10004 || heldItemId2 == 10004) { //Diamond
    smoothness = pow16(lAlbedo);
}