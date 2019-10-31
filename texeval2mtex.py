#!/usr/bin/env python
#-*- coding: utf-8 -*-
"""
Created on Jul 7 2018

Converts intensities in a RES file from TexEval to a DAT file to be read by
MTEX.

The script assumes:
  * cubic crystal symmetry, i.e. pole figures starting with 111, 200, 220,
  311 etc.
  * that Chi up to 75 degrees (polar_max = 80 degrees) have been used for the
  uncorrected pole figure data

NB! It will write files to the same directory as the input file, with the same
file name and appended '_pf<index of plane>_corr.dat' for the corrected
intensities (similar for the uncorrected intensities). With four pole figures
eight DAT files will be created.

@author: Håkon Wiik Ånes (hakon.w.anes@ntnu.no)
"""
import numpy as np
import sys
import os
import argparse
import pandas as pd


# Get input from user
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('infile', help='Name of input file (RES file)')
parser.add_argument('n_pfs', default=4, help='Number of pole figures')
arguments = parser.parse_args()
infile = arguments.infile
n_pfs = int(arguments.n_pfs)


def get_meta_data(n_pfs, pfs_df, content, step_polar_str, step_azimuthal_str,
                  corr_data=True):
    """Get the line numbers for the start of the intensity values in the RES
    file for either the uncorrected or corrected intensities.

    Parameters
    ----------
    n_pfs : number of pole figures in data
    pfs_df : empty pandas data frame
    content : content of RES file
    step_polar_str : string of step in polar angle in degrees
    step_azimuthal_str : string of step in azimuthal angle in degrees
    corr_data : if meta data either for the uncorrected or corrected
    intensities are to be made

    Returns
    -------
    pfs_df : updated pandas dataframe with intensity headers for each pole
    figure and the position of the intensity data
    the line number for start of intensity values
    """

    if corr_data:
        pos = 2
        polar_max = 90
    else:
        pos = 0
        polar_max = 80

    for i in range(n_pfs):
        plane_str = pfs_df.iloc[i].name
        pfs_df.iloc[i, pos] = ''.ljust(1) + plane_str + ''.ljust(7) \
            + step_azimuthal_str + ''.ljust(3) + str(int(360/step_azimuthal)) \
            + ''.ljust(4) + str(0) + ''.ljust(1) + step_polar_str \
            + ''.ljust(3) + str(int(polar_max/step_polar)) + ''.ljust(4) \
            + str(0)

    lineCount = 0
    for line in content:
        lineCount += 1
        for i in range(len(pfs_df.index)):
            if pfs_df.iloc[i, pos] == line.rstrip():
                pfs_df.iloc[i, pos + 1] = lineCount - 1
                break

    return pfs_df


def get_intensities(n_pfs, pfs_df, step_polar, step_azimuthal, step=8,
                    corr_data=True):
    """Get values for either the uncorrected or corrected intensities.

    Parameters
    ----------
    n_pfs : number of pole figures
    pfs_df : pandas data frame of pole figure headers and itensity positions
    step_polar : step in polar angle in degrees
    step_azimuthal : step in azimuthal angle in degrees
    step : number of lines for the intensity values for each polar angle
    corr_data : if intensities either for the uncorrected or corrected
    intensities are desired

    Returns
    -------
    pfs_ints : numpy array of pole figure intensities
    """

    if corr_data:
        pos = 3
        polar_max = 90
    else:
        pos = 1
        polar_max = 80

    stop_increment = int(step*polar_max/step_polar)
    pfs_ints = np.zeros((n_pfs, int(polar_max/step_polar),
                         int(360/step_azimuthal)))

    for i in range(n_pfs):
        i_pa = 0  # Polar angle increment (from 0 to 16 or 18)
        start = pfs_df.iloc[i, pos] + 1
        stop = start + stop_increment
        for j in range(start, stop, step):
            i_pf = 0  # Increment for index to fill intensities into pfs_ints
            for k in range(step):
                i_content = j + k  # Line increment in RES file
                ints = [round(float(x), 3) for x in content[i_content].split()]
                pfs_ints[i, i_pa, i_pf:(i_pf + len(ints))] = ints
                i_pf += len(ints)
            i_pa += 1

    return pfs_ints


def write_intensities_to_file(pfs_ints, pfs_df, infile, step_polar,
                              step_azimuthal, corr_data=True):
    """Write the values of either the uncorrected or corrected intensities to
    file.

    Parameters
    ----------
    pfs_ints : numpy array of pole figure intensities
    pfs_df : pandas data frame of pole figure headers and intensity positions
    infile : infile string
    step_polar : step in polar angle in degrees
    step_azimuthal : step in azimuthal angle in degrees
    corr_data : if uncorrected or corrected intensities are to be written to
    file

    """

    # Create arrays for polar and azimuthal angles to use for all pole figures
    polar_max = pfs_ints.shape[1]
    azimuthal_max = pfs_ints.shape[2]

    polar = np.zeros([polar_max, azimuthal_max])
    azimuthal = np.copy(polar)

    for j in range(polar_max):
        polar[j] = j * step_polar
        k = 0
        for l in range(azimuthal_max):
            azimuthal[j, l] = k
            k += step_azimuthal
    polar_flat = polar.flatten()
    azimuthal_flat = azimuthal.flatten()

    for i in range(pfs_ints.shape[0]):
        pf_ints_flat = pfs_ints[i].flatten()
        data = np.array([polar_flat, azimuthal_flat, pf_ints_flat]).transpose()
        outfile = infile[:-4] + '_pf' + pfs_df.iloc[i].name
        if corr_data:
            outfile += '_corr.dat'
        else:
            outfile += '_uncorr.dat'
        np.savetxt(outfile, data, fmt=['%i', '%i', '%.3f'])


# Check if correct file extension, otherwise exit script
if (infile.endswith('.RES') == False) and (infile.endswith('.res') == False):
    print('Error: The input file must be a RES file.\n')
    sys.exit()

# Read file
with open(infile) as f:
    content = f.readlines()

# Check if a defocusing correction has been performed or not
if content[2].split()[0][:4] == 'LMAX':
    corr = True
else:
    corr = False

# Get polar and azimuthal angle step in degrees
step_polar = float(content[3].split()[1])
step_azimuthal = float(content[3].split()[2])
step_polar_str = '%.2f' % step_polar
step_azimuthal_str = '%.2f' % step_azimuthal

# Create pandas data frame for meta data
planes = ['111', '200', '220', '311', '222', '400']
columns = ['uncorr_head', 'uncorr_head_pos']
if corr:
    columns += ['corr_head', 'corr_head_pos']
pfs_df = pd.DataFrame(index=pd.Series(planes[:n_pfs]), columns=columns)

# Uncorrected intensities
pfs_df = get_meta_data(n_pfs, pfs_df, content, step_polar_str,
                       step_azimuthal_str, corr_data=False)
uncorr_ints = get_intensities(n_pfs, pfs_df, step_polar, step_azimuthal,
                              corr_data=False)
write_intensities_to_file(uncorr_ints, pfs_df, infile, step_polar,
                          step_azimuthal, corr_data=False)

# Corrected intensities if they are in the RES file
if corr:
    pfs_df = get_meta_data(n_pfs, pfs_df, content,
                           step_polar_str, step_azimuthal_str)
    corr_ints = get_intensities(n_pfs, pfs_df, step_polar, step_azimuthal)
    write_intensities_to_file(corr_ints, pfs_df, infile, step_polar,
                              step_azimuthal)
