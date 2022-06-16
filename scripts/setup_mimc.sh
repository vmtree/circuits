#!/bin/bash

if [ ! -f "./powers_of_tau/powersOfTau28_hez_final_19.ptau" ]
then
    echo "[SETUP] - Downloading powersOfTau28_hez_final_19.ptau file"
    echo "[SETUP] - See https://github.com/iden3/snarkjs for a list of ptau files."
    wget \
        https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_19.ptau \
        -O ./powers_of_tau/powersOfTau28_hez_final_19.ptau
else
    echo "[SETUP] - Powers of tau detected, skipping download"
fi

echo "[SETUP] - Compiling circuit"
circom -o ./mimc/out --r1cs --wasm --sym ./mimc/mass_update.circom

echo "[SETUP] - Setting up phase 2 ceremony"
snarkjs g16s \
    ./mimc/out/mass_update.r1cs \
    ./powers_of_tau/powersOfTau28_hez_final_19.ptau \
    ./mimc/out/mass_update_0000.zkey

echo "[SETUP] - Contributing to the ceremony"
snarkjs zkc \
    ./mimc/out/mass_update_0000.zkey \
    ./mimc/out/mass_update.zkey \
    -e='unique new york'

echo "[SETUP] - Exporting verification key to json"
snarkjs zkev \
    ./mimc/out/mass_update.zkey \
    ./mimc/out/mass_update_verifier.json