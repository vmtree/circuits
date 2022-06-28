#!/bin/bash

if [ ! -f "./powers_of_tau/powersOfTau28_hez_final_08.ptau" ]
then
    echo "[SETUP] - Downloading powersOfTau28_hez_final_08.ptau file"
    echo "[SETUP] - See https://github.com/iden3/snarkjs for a list of ptau files."
    wget \
        https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_08.ptau \
        -O ./powers_of_tau/powersOfTau28_hez_final_08.ptau
else
    echo "[SETUP] - Powers of tau detected, skipping download"
fi

echo "[SETUP] - Compiling circuit"
circom -o ./poseidon/out --r1cs --wasm --sym ./poseidon/proof_of_secret.circom

echo "[SETUP] - Setting up phase 2 ceremony"
snarkjs g16s \
    ./poseidon/out/proof_of_secret.r1cs \
    ./powers_of_tau/powersOfTau28_hez_final_08.ptau \
    ./poseidon/out/proof_of_secret_0000.zkey

echo "[SETUP] - Contributing to the ceremony"
snarkjs zkc \
    ./poseidon/out/proof_of_secret_0000.zkey \
    ./poseidon/out/proof_of_secret.zkey \
    -e='unique new york'

echo "[SETUP] - Exporting verification key to json"
snarkjs zkev \
    ./poseidon/out/proof_of_secret.zkey \
    ./poseidon/out/proof_of_secret_verifier.json