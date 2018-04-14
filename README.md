# Multi-unit activity extraction pipeline (MUA)
This pipeline extracts multi-unit activity in the form of spikeband power, checks for stimulus artifact and removes it from the extracted MUA using ICA. It is implemented in Matlab and uses a memory and computationally efficient approach to extract MUA.

## Dependency
[Fast ICA](https://research.ics.aalto.fi/ica/fastica/)

## Functions
`mua_pipe.m`: Main script for running pipeline

