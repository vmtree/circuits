pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "./merkle_proof_verifier.circom";

template CommitmentNullifierHasher() {
    signal input secret;
    signal input index;
    signal input offset;

    signal output commitment;
    signal output nullifier;

    // commitment = Poseidon([secret, 0])
    // nullifier = Poseidon([secret, 1 + offset + index])

    component commitmentHasher = Poseidon(2);
    commitmentHasher.inputs[0] <== secret;
    commitmentHasher.inputs[1] <== 0;
    commitment <== commitmentHasher.out;

    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== secret;
    nullifierHasher.inputs[1] <== 1 + offset + index;
    nullifier <== nullifierHasher.out;
}

/*
    This template name deviates from `withdraw` because it's more general than
    that. The `integrity` parameter is there to bind certain data to the proof,
    and it is constructed from the hash of relevant data in a smart contract.
*/
template AssociateData(levels) {
    signal input root;
    signal input offset;
    signal input nullifier;
    signal input integrity;

    signal input secret;
    signal input index;
    signal input pathElements[levels];

    /*
        Require index to be in range of indexes for a tree of depth `levels`.
        We need this constraint because otherwise a malicious depositor could
        repeatedly prepend extra bits beyond `levels`, producing new nullifier
        hashes for the same deposit.
    */
    component lessThan = LessThan(248);
    lessThan.in[0] <== index;
    lessThan.in[1] <== 2 ** levels;
    lessThan.out === 1;

    /*
        Offset should be hardcoded in the contract that uses this verifier. Care
        should be taken to choose appropriate offsets!
    */
    component hasher = CommitmentNullifierHasher();
    hasher.secret <== secret;
    hasher.index <== index;
    hasher.offset <== offset;
    hasher.nullifier === nullifier;

    component tree = MerkleProofVerifier(levels);
    tree.leaf <== hasher.commitment;
    tree.index <== index;
    for (var i = 0; i < levels; i++) {
        tree.pathElements[i] <== pathElements[i];
    }
    tree.root === root;

    // associates arbitrary data with the merkle proof
    signal integritySquare;
    integritySquare <== integrity * integrity;
}

component main {public [root, offset, nullifier, integrity]} = AssociateData(20);