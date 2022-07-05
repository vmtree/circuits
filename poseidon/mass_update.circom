pragma circom 2.0.0;

include "./merkle_tree_updater.circom";

template MassUpdate(levels, numUpdates) {
    signal input newRoot;
    signal input startIndex;
    signal input startSubtrees[levels];
    signal input endSubtrees[levels];
    signal input leaves[numUpdates];

    component trees[numUpdates];

    for (var i = 0; i < numUpdates; i++) {
        trees[i] = MerkleTreeUpdater(levels);
        trees[i].index <== startIndex + i;
        trees[i].leaf <== leaves[i];

        for (var j = 0; j < levels; j++) {
            trees[i].filledSubtrees[j] <== i == 0 ? startSubtrees[j] : trees[i - 1].newSubtrees[j];
        }
    }

    for (var k = 0; k < levels; k++) {
        endSubtrees[k] === trees[numUpdates - 1].newSubtrees[k];
    }

    newRoot === trees[numUpdates - 1].newRoot;
}

component main {public [newRoot, startIndex, startSubtrees, endSubtrees, leaves]} = MassUpdate(20, 16);