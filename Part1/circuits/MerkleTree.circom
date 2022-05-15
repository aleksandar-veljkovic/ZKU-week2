pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    // Referenced from appliedzkp incrementalMerkleTree library: https://github.com/appliedzkp/incrementalquintree/blob/master/circom/incrementalMerkleTree.circom
    
    var number_of_leaves = 2 ** n;
    var number_of_leaf_poseidons = number_of_leaves / 2; // Hash every two
    var number_of_internal_poseidons = number_of_leaf_poseidons - 1; // (2**(n-1)) - 1
    var total_number_of_poseidons = number_of_leaves - 1; // (2 ** n) - 1

    // Poseidons
    component poseidon_hashers[total_number_of_poseidons];
    var i;
    for (i=0; i < total_number_of_poseidons; i++) {
        poseidon_hashers[i] = Poseidon(2);
    }

    // Leaf poseidons
    for (i=0; i < number_of_leaf_poseidons; i++){
        poseidon_hashers[i].inputs[0] <== leaves[i * 2];
        poseidon_hashers[i].inputs[0] <== leaves[i * 2 + 1];
    }

    var j = 0;
    for (i = number_of_leaf_poseidons; i < number_of_leaf_poseidons + number_of_internal_poseidons; i++) {
        poseidon_hashers[i].inputs[0] <== poseidon_hashers[j * 2].out;
        poseidon_hashers[i].inputs[1] <== poseidon_hashers[j * 2 + 1].out;
        j++;
    }

    root <== poseidon_hashers[total_number_of_poseidons - 1].out;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path

    // Referenced from semaphore library: https://github.com/appliedzkp/semaphore/blob/main/circuits/tree.circom
    component poseidon_hashers[n];
    component mux[n];

    signal hashes[n + 1];
    hashes[0] <== leaf;

    for (var i = 0; i < n; i++) {
        path_index[i] * (1 - path_index[i]) === 0;

        poseidon_hashers[i] = Poseidon(2);
        mux[i] = MultiMux1(2);

        mux[i].c[0][0] <== hashes[i];
        mux[i].c[0][1] <== path_elements[i];
        mux[i].c[1][0] <== path_elements[i];
        mux[i].c[1][1] <== hashes[i];
        mux[i].s <== path_index[i];

        poseidon_hashers[i].inputs[0] <== mux[i].out[0];
        poseidon_hashers[i].inputs[1] <== mux[i].out[1];

        hashes[i + 1] <== poseidon_hashers[i].out;
    }

    root <== hashes[n];
}