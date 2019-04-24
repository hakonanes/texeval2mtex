%% TexEval to MTEX
% Created on Jul 31 2018
% Updated on April 24 2019
%
% Create a MTEX PoleFigure object from four pole figures by using
% loadPoleFigure_generic,  and
%   1. calculate the ODF
%   2. plot intensities along fibres (beta, Cube-Goss)
%   3. calculate volume fractions
%
% E: hakon.w.anes@ntnu.no
% T: @hakonanes
% W: https://www.ntnu.edu/employees/hakon.w.anes
%
% Working with:
%   MATLAB > R2018a
%   MTEX 5.2.beta2

%% Import pole figure data and create PoleFigure object
cs = crystalSymmetry('m-3m', [4.04 4.04 4.04], 'mineral', 'Al');

path = ['path/to/files/'];
fnamesPrefix = '3000_1.9mm_330C_1_R';

fnames = {
    [path fnamesPrefix '_pf111_uncorr.dat'],...
    [path fnamesPrefix '_pf200_uncorr.dat'],...
    [path fnamesPrefix '_pf220_uncorr.dat'],...
    [path fnamesPrefix '_pf311_uncorr.dat']};

% Specimen symmetry
ss = specimenSymmetry('1'); % Triclinic
ssO = specimenSymmetry('orthorhombic');

% Plotting convention
setMTEXpref('xAxisDirection', 'north');
setMTEXpref('zAxisDirection', 'outOfPlane');

% Set annotations to highlight spatial reference frame
pfAnnotations = @(varargin) text([vector3d.X, vector3d.Y],...
    {'RD', 'TD'}, 'BackgroundColor', 'w', 'tag', 'axesLabels', varargin{:});
setMTEXpref('pfAnnotations', pfAnnotations);

h = {
    Miller(1, 1, 1, cs),...
    Miller(2, 0, 0, cs),...
    Miller(2, 2, 0, cs),...
    Miller(3, 1, 1, cs)};

% Load pole figures separately
columnNames = {'Polar Angle', 'Azimuth Angle', 'Intensity'};
pf1 = loadPoleFigure_generic(fnames{1}, 'ColumnNames', columnNames);
pf2 = loadPoleFigure_generic(fnames{2}, 'ColumnNames', columnNames);
pf3 = loadPoleFigure_generic(fnames{3}, 'ColumnNames', columnNames);
pf4 = loadPoleFigure_generic(fnames{4}, 'ColumnNames', columnNames);

% Construct pole figure object of the four pole figures
intensities = {
    pf1.intensities,...
    pf2.intensities,...
    pf3.intensities,...
    pf4.intensities};
pfs = PoleFigure(h, pf1.r, intensities, cs, ss);

%% Plot pole figures of raw, corrected data
figure
plot(pfs, 'upper', 'projection', 'eangle', 'minmax')
mtexColorbar('location', 'southOutside')

%% Calculate the ODF using default settings
odf = calcODF(pfs)

% Set correct specimen symmetry for calculation of texture strength
odf.SS = ssO;

% Calculate texture strength
textureIndex = odf.textureindex
entropy = odf.entropy
odfMax = odf.max

%% ODF in {111} PF with specified contour levels
levelsPF = [0, 1, 2, 3, 4, 5];

odf.SS = ss;
figure
plotPDF(odf, h, 'upper', 'projection', 'eangle', 'contourf', levelsPF)
mtexColorbar

%% Plot ODF in Euler space phi2 sections
levelsODF = [0, 1, 2, 3, 4, 8, 12];

odf.SS = ssO;
figure
plot(odf, 'phi2', [0 45 65]*degree, 'contourf', levelsODF, 'minmax')

figure
plot(odf, 'sections', 18, 'contourf', levelsODF)

%% Plot inverse pole figure
figure
plotIPDF(odf, [xvector, yvector, zvector], 'contourf', 'minmax') % contoured
%plotIPDF(odf, [xvector, yvector, zvector]) % continuous
mtexColorMap WhiteJet % or e.g. white2black
mtexColorbar

%% Define ideal texture components and spread acceptance angle
br = orientation.byEuler(35*degree, 45*degree, 90*degree, cs, ssO);
cu = orientation.byEuler(90*degree, 35*degree, 45*degree, cs, ssO);
cube = orientation.byMiller([1 0 0], [0 0 1], cs, ssO);
cubeND22 = orientation.byEuler(22*degree, 0, 0, cs, ssO);
cubeND45 = orientation.byMiller([1 0 0], [0 1 1], cs, ssO);
goss = orientation.byMiller([1 1 0], [0 0 1], cs, ssO);
p = orientation.byMiller([0 1 1], [1 2 2], cs, ssO);
q = orientation.byMiller([0 1 3], [2 3 1], cs, ssO);
s = orientation.byEuler(59*degree, 37*degree, 63*degree, cs, ssO);

spread = 10*degree;

%% Calculate volume fractions Mi
Mbr = volume(odf, br, spread)
Mcu = volume(odf, cu, spread)
Mcube = volume(odf, cube, spread)
McubeND22 = volume(odf, cubeND22, spread)
McubeND45 = volume(odf, cubeND45, spread)
Mgoss = volume(odf, goss, spread)
Mp = volume(odf, p, spread)
Mq = volume(odf, q, spread)
Ms = volume(odf, s, spread)

%% Plot intensity along beta fibre from Cu to Brass and write results to file
odf.SS = ssO;
f = fibre(cu, br, cs, ssO);

% generate list from fibres and evalute ODF at specific orientations
fibreOris = f.orientation;
evalOris = [];
evalIndex = [1 84 167 254 346 446 556 680 824 1000];
evalValues = zeros(1, 10);
for i=1:10
    ori = fibreOris(evalIndex(i));
    evalOris = [evalOris ori];
    evalValues(i) = eval(odf, ori);
end

figure
plot(evalOris.phi2/degree, evalValues, '-o')
xlabel('\phi_2 \rightarrow', 'interpreter', 'tex')
ylabel('Orientation density f(g)', 'interpreter', 'tex')
xlim([45 90])

% Write fibre data to a csv file for further analysis
datafname = [path 'data_fibre_beta.csv'];

% Write header to file
fid = fopen(datafname, 'w');
fprintf(fid, '%s\r\n', ['phi1, Phi, phi2, fibreValue']);
fclose(fid);

% Write Euler angles and intensities to file
dlmwrite(datafname, [(evalOris.phi1/degree)' (evalOris.Phi/degree)'...
    (evalOris.phi2/degree)' evalValues'], '-append')

%% Plot intensity along fibre from Cube to Goss and write results to file
cube = orientation.byEuler(0, 0, 0, cs, ssO);
goss = orientation.byEuler(0, 45*degree, 0, cs, ssO);
f = fibre(cube, goss, cs, ssO);

% Generate list from fibres and evalute ODF at specific orientations
fibreOris = f.orientation;
evalOris = [];
evalIndex = [1 111 222 333 444 555 666 777 888 1000];
evalValues = zeros(1, 10);
for i=1:10
    ori = fibreOris(evalIndex(i));
    evalOris = [evalOris ori];
    evalValues(i) = eval(odf, ori);
end

figure
plot(evalOris.Phi/degree, evalValues, '-o')
xlabel('\Phi \rightarrow', 'interpreter', 'tex')
ylabel('Orientation density f(g)', 'interpreter', 'tex')
xlim([0 45])

% Write fibre data to a csv file for further analysis
datafname = [path 'data_fibre_cube_goss.csv'];

% Write header to file
fid = fopen(datafname, 'w');
fprintf(fid, '%s\r\n', ['phi1, Phi, phi2, fibreValue']);
fclose(fid);

% Write Euler angles and intensities to file
dlmwrite(datafname, [(evalOris.phi1/degree)' (evalOris.Phi/degree)'...
    (evalOris.phi2/degree)' evalValues'], '-append')
