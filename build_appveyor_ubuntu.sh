#!/bin/bash

JOBS=$JOBS

cd ~
cd scopy
mkdir build
cd build
cmake ../
make $JOBS

