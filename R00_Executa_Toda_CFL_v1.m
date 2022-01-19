clearvars; close all; clc;
addpath('../config/Bibliotecas/apstools');
addpath('../config/Bibliotecas/s2nr');
addpath('../config/Bibliotecas/voicebox');
addpath('../config/Bibliotecas/MSR Identity Toolkit v1.0/code');
set(0, 'DefaultFigureVisible', 'off');
breakLine = '-------------------------------------------------------------------';
% --- Paleta de cores -----------------------------------------------------
cmRed2Blue = [];
for i = 0:32
    cmRed2Blue = [cmRed2Blue; [1, (i/32)^(2) ,(i/32)^(2)]];
end
for i = 31:-1:0
    cmRed2Blue = [cmRed2Blue; [(i/32)^(2) ,(i/32)^(2), 1]]; %#ok<*AGROW>
end
% --- Lista os casos no diretorio -----------------------------------------
cellFolders = split(pwd,'/');
dirName = cellFolders{end};
dirName = regexprep(dirName,'[/\\?&%*:;|"<>-]''','_');
reportName = sprintf('REPORT_%s.txt',dirName);

fprintf('--- INICIO DA PRIMEIRA ETAPA --------------------------------------\n')
fprintf('%s\n',breakLine)
% --- Sanitariza diretorios e arquivos ------------------------------------
fprintf('1.1 - Sanitariza diretorios:');
res = system('./S00_Space_To_Underscore.sh'); %#ok<*NASGU>
fprintf('%s\n',breakLine)
% -------------------------------------------------------------------------
audioExt = {'.3gp','.aa','.aac','.aax','.act','.aiff','.amr','.ape','.au',...
            '.awb','.dct','.dss','.dvf','.flac','.gsm','.iklax','.ivs',...
            '.m4a','.m4b','.m4p','.mmf','.mp3','.mpc','.msv','.nmf','.nsf',...
            '.ogg','.oga','.mogg','.opus','.ra','.rm','.raw','.sln','.tta',...
            '.vox','.wav','.wma','.wv','.webm','.8svx'};
AudioFiles = lista_conteudo_pasta([],audioExt,[],[],'or');
for i = 1:length(AudioFiles)
    oriFile = AudioFiles{i};
    idxPoint = strfind(oriFile,'.');
    basename = oriFile(1:(idxPoint(end) -1));
    conv_01 = [basename,'_PCI_8k_16.wav'];
    conv_02 = [basename,'.wav'];
    convertComand = sprintf('sox %s -e signed-integer -b 16 -r 8000 -c 1 %s > /dev/null',oriFile,conv_01);
    removeComand = sprintf('rm %s',oriFile);
    renameComand = sprintf('mv %s %s',conv_01,conv_02);
    system(convertComand);
    pause(1.5);
    system(removeComand);
    pause(1.5);
    system(renameComand);
end
% res = system('./S01_Any_Audio_To_WAV_PCM_8kHz.sh');

% -------------------------------------------------------------------------
fprintf('%s\n',breakLine)
% --- Define arquivos e diretorios de saida -------------------------------
BOOL_RECOMPUTE_EXAM = false;
UBM_Raw_File = '../gmmubmDATA/Raw_Data_UBM.mat';
UBM_Data_File = '../gmmubmDATA/Base_UBM_PDR_QST.mat';

OUT_DIR = './data_dir/';
GMMUBM_FileData = [OUT_DIR,'Base_GMM.mat'];
GMMUBM_ConfrontFile = [OUT_DIR,'PTS_GMM_MULTI.mat'];
iVector_FileData = [OUT_DIR,'iVectorData.mat'];

if (~exist(OUT_DIR,'dir'))
    mkdir(OUT_DIR);
end

% --- Verifica arquivos de entrada ----------------------------------------
Files = lista_conteudo_pasta([],{'.wav'});
str_PDR_Files_Name = [];
str_QST_Files_Name = [];
str_GSM_Files_Name = [];
str_OTR_Files_Name = [];
str_ENC_Files_Name = [];
for  i = 1:length(Files)
    boolPDR = ~isempty(strfind(Files{i}, 'PDR'));
    boolQST = ~isempty(strfind(Files{i}, 'QST'));
    boolGSM = ~isempty(strfind(Files{i}, 'GSM'));
    boolOTR = ~isempty(strfind(Files{i}, 'OTR'));
    boolENC = ~isempty(strfind(Files{i}, 'ENC'));
    if (boolPDR)
        str_PDR_Files_Name{end+1} = strcat(Files{i}); %#ok<SAGROW>
    end
    if (boolQST)
        str_QST_Files_Name{end+1} = strcat(Files{i}); %#ok<SAGROW>
    end
    if (boolGSM)
        str_GSM_Files_Name{end+1} = strcat(Files{i}); %#ok<SAGROW>
    end
    if (boolOTR)
        str_OTR_Files_Name{end+1} = strcat(Files{i}); %#ok<SAGROW>
    end
    if (boolENC)
        str_ENC_Files_Name{end+1} = strcat(Files{i}); %#ok<SAGROW>
    end
end
% --- Gera GSM ------------------------------------------------------------
if (isempty(str_GSM_Files_Name))
    parfor i = 1:1:size(str_PDR_Files_Name,2)
        makegsmfile(str_PDR_Files_Name{i});
    end    
    Files = lista_conteudo_pasta([],{'.wav'});
    for  i = 1:length(Files)
        boolGSM = ~isempty(strfind(Files{i}, 'GSM'));
        if (boolGSM)
            str_GSM_Files_Name{end+1} = strcat(Files{i}); %#ok<SAGROW>
        end
    end
end
% --- Gera ENC ------------------------------------------------------------
if (isempty(str_ENC_Files_Name))
    parfor i = 1:1:size(str_QST_Files_Name,2)
        makegsmfile(str_QST_Files_Name{i},'ENC');
    end
    parfor i = 1:1:size(str_OTR_Files_Name,2)
        makegsmfile(str_OTR_Files_Name{i},'ENC');
    end
    Files = lista_conteudo_pasta([],{'.wav'});
    for  i = 1:length(Files)
        boolGSM = ~isempty(strfind(Files{i}, 'ENC'));
        if (boolGSM)
            str_ENC_Files_Name{end+1} = strcat(Files{i}); %#ok<SAGROW>
        end
    end
end

% -------------------------------------------------------------------------
fprintf('1.2 - Comparação por GMM-UBM:\n');
fprintf('%s\n',breakLine);
R01_GMMUBM_Modelos_GMM_v1,
fprintf('%s\n',breakLine);
R02_GMMUBM_Calculo_Scores_v1,
fprintf('%s\n',breakLine);
R03_GMMUBM_Compara_Scores_v1,
fprintf('%s\n',breakLine);
fprintf('Fim da comparação GMM-UBM.\n%s\n',breakLine);
fprintf('%s\n',breakLine);
% -------------------------------------------------------------------------
fprintf('1.2 - Comparação por i-vector:\n');
fprintf('%s\n',breakLine);
R01_Calcula_i_vectors_v0,
fprintf('%s\n',breakLine);
fprintf('Fim da comparação i-vector.\n%s\n',breakLine);
fprintf('%s\n',breakLine);
% -------------------------------------------------------------------------
fprintf('1.3 - Comparação por fuzzy i-vector:\n');
fprintf('%s\n',breakLine);
R01_Calcula_fi_vectors_v0,
fprintf('%s\n',breakLine);
R02_Calcula_FLDA_v0,
fprintf('%s\n',breakLine);
fprintf('Fim da comparação fuzzy i-vector.\n%s\n',breakLine);
fprintf('%s\n',breakLine);
fprintf('Comparacao terminada. Verifique o arquivo "%s".\n%s\n',reportName,breakLine);
