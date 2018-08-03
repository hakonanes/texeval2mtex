# TexEval to MTEX

Scripts enabling TexEval pole figure intensities to be analysed in MTEX.

## Contents

### texeval2mtex.py

Python script to write pole figure intensities from a TexEval RES-file into MTEX-ready DAT-files.

To use, install necessary libraries from `requirements.txt`, then enter e.g.

```bash
$ python texeval2mtex.py example_data/polefigure_intensities.res 4
```

The last argument, 4, specifies the number of pole figures in the RES-file.

### requirements.txt

Necessary Python libraries. Install into current Conda environment manually, or otherwise using

```bash
$ pip install -r requirements.txt
```

### texeval2mtex.m

Matlab script to create a MTEX PoleFigure object from four (or three, five, etc.) pole figures by using loadPoleFigure_generic, and then calculate the ODF, plot intensities along fibres (beta and Cube-Goss) and calculate volume fractions.

For writing of figures created by MTEX to disk, the function `export_fig`, created by Yair Altman available here [export_fig - File Exchange](https://se.mathworks.com/matlabcentral/fileexchange/23629-export_fig), is recommended. After the plotting lines for a specific figure, or in the command window when the specific figure is selected, enter e.g. (for 100 dpi resolution)

```matlab
export_fig([path 'odf_fibre_cube_goss.png'],'-r100')
```
