close all;
addpath('../config/Bibliotecas/apstools/');
addpath('../config/Bibliotecas/MSR Identity Toolkit v1.0/code/');
addpath('../config/Bibliotecas/voicebox/');
% -------------------------------------------------------------------------
DATA_DIR = '../config/fivectorDATA/';
% -------------------------------------------------------------------------
load([DATA_DIR,'PARAMETROS.mat']);
% -------------------------------------------------------------------------
load([DATA_DIR,'DadosFuzzy.mat']);
load([DATA_DIR,'SNR_Classes.mat']);
% -------------------------------------------------------------------------
PARAMETROS.structFileName = [OUT_DIR,'fiVectorData.mat'];
% -------------------------------------------------------------------------
TimeStep    = PARAMETROS.TimeStep;
TimeWindow 	= PARAMETROS.TimeWindow;
% --- Lista arquivos contaminados por ruido -------------------------------
m = 'a';
pp.pr = 0.95; % default = 0.70
timeStep    = 0.01;
timeWin     = 0.025;
% -------------------------------------------------------------------------
S2NR = struct;
S2NR.NFFT   = 1024;    % fft window size 
S2NR.RTH    = 0.6;      % reliability threshold
S2NR.alpha  = 0.5;    % fft window overlap 
S2NR.sigma  = 0.1;    % image segmentation threshold
% -------------------------------------------------------------------------
limiar = 0.5;
% -------------------------------------------------------------------------
STRING_FILENAME = [OUT_DIR,'DataSpeakerCompare_fuzzy_iv.mat'];
PARAMETROS.nUBMS = 2;

if (exist(STRING_FILENAME,'file') && ~BOOL_RECOMPUTE_EXAM)
    load(STRING_FILENAME);
    fprintf('Arquivo %s já existe. Etapa já realizada.\nPara realizar novamente esta etapa remova-o\nou indique a variável BOOL_RECOMPUTE_EXAM para true.\n',STRING_FILENAME)
else
    fprintf('Calculado comparação fuzzy i-vector...\n')
    cellAudioFiles = lista_conteudo_pasta([],{'.wav'});
    str_Files = struct;
    for  i = 1:length(cellAudioFiles)
        boolPDR = ~isempty(strfind(cellAudioFiles{i}, 'PDR'));
        boolQST = ~isempty(strfind(cellAudioFiles{i}, 'QST'));
        boolGSM = ~isempty(strfind(cellAudioFiles{i}, 'GSM'));
        boolENC = ~isempty(strfind(cellAudioFiles{i}, 'ENC'));
        boolOTR = ~isempty(strfind(cellAudioFiles{i}, 'OTR'));
        str_Files(i).FileName = cellAudioFiles{i};
        if (boolPDR)
            str_Files(i).TagType = 'PDR';
        end
        if (boolQST)
            str_Files(i).TagType = 'QST';
        end
        if (boolGSM)
            str_Files(i).TagType = 'GSM';
        end
        if (boolENC)
            str_Files(i).TagType = 'ENC';
        end
        if (boolOTR)
            str_Files(i).TagType = 'OTR';
        end
    end
    % ---------------------------------------------------------------------
    for  i = 1:length(str_Files)
        fprintf('Início arquivo %d de %d... ',i,length(str_Files))
        [y, fs] = audioread(str_Files(i).FileName);

        str_Files(i).Fs = fs;
        str_Files(i).NumSamples = length(y);

        vecVAD = vadsohn(y,fs,m,pp);
        vecS2NR = s2nr_function(y , fs, timeWin, timeStep,...
                                S2NR.NFFT , S2NR.RTH, S2NR.sigma);
        mtxMFCC = paudio(y , fs, 0, 0);
        str_Files(i).vad          = vecVAD;
        str_Files(i).s2nr         = vecS2NR;
        str_Files(i).snr          = mean(filtraVADbyFrame(vecS2NR,...
            Sample2FrameFeature(vecVAD,fs,TimeStep,TimeWindow,limiar)));
        str_Files(i).mfcc         = mtxMFCC;

        fiVectorData = struct;
        for iUBM = 1:PARAMETROS.nUBMS
            if (iUBM == 1)
                load([DATA_DIR,'UBM_GSM_fuzzy.mat']);
                load([DATA_DIR,'Tmatrix_GSM_fuzzy.mat']);
                load([DATA_DIR,'GSM_IVs_fuzzy.mat']);
                UBM_CELL        = UBM_GSM_CELL;
                Tmatrix_CELL    = Tmatrix_GSM_CELL;
                IVs_WHITEN      = GSM_IVs_WHITEN;
                fiVectorData(iUBM).UBM = 'GSM';
                clear UBM_GSM_CELL Tmatrix_GSM_CELL GSM_IVs_WHITEN;
            else
                load([DATA_DIR,'UBM_PDR_fuzzy.mat']);
                load([DATA_DIR,'Tmatrix_PDR_fuzzy.mat']);
                load([DATA_DIR,'PDR_IVs_fuzzy.mat']);
                UBM_CELL        = UBM_PDR_CELL;
                Tmatrix_CELL    = Tmatrix_PDR_CELL;
                IVs_WHITEN      = PDR_IVs_WHITEN;
                fiVectorData(iUBM).UBM = 'PDR';
                clear UBM_PDR_CELL Tmatrix_PDR_CELL PDR_IVs_WHITEN;
            end
            % --- ETAPA fuzzy-S2NR ------------------------------------------------
            for iFc = 1:DadosFuzzy.Num_Class
                UBM = UBM_CELL{iFc};
                Tmtx = Tmatrix_CELL{iFc};                
                meanUBM 	= UBM.mUBM;
                stdUBM 		= UBM.sUBM;
                mfccUBM 	= UBM.mfcc;
                selMU 		= IVs_WHITEN{iFc}.mu;
                selMAT	= IVs_WHITEN{iFc}.mtx;
                
                [idxClass,mtxPert] = GetPertinence(vecS2NR,STC_CLASSES_S2NR_BG,DadosFuzzy.boolAllGauss);
                VAD = Sample2FrameFeature(vecVAD,fs,...
                    PARAMETROS.TimeStep,PARAMETROS.TimeWindow,limiar);
                lCls = length(idxClass);
                lVad = length(VAD);
                if ((lCls ~= lVad) && (abs(lCls-lVad) < 2))
                    mI = min(lCls,lVad);
                    idxClass    = idxClass(1:mI);
                    VAD         = VAD(1:mI);
                end
                idx = find((idxClass == iFc) & (VAD == 1) );
                tFEAT = (mtxMFCC(:,idx) - meanUBM)./stdUBM;
                [N,F] 	= compute_fuzzy_bw_stats(tFEAT, mtxPert(:,idx), iFc, mfccUBM);
                IVtemp 	= extract_ivector([N; F], UBM.mfcc, Tmtx);
                fiVectorData(iUBM).iVector{iFc} 		= MatrixWhiten(IVtemp',selMU,selMAT)';
            end
            str_Files(i).fiVectorData = fiVectorData;
        end
        fprintf('\tFinalizado.\n');
    end
    save(PARAMETROS.structFileName,'PARAMETROS','-v7.3');
    save(STRING_FILENAME,'str_Files','-v7.3');
    fprintf('Fim do cálculo dos vetores no método fuzzy i-vector...\n')
end
mFileName = split(mfilename('fullpath'),'/');
fprintf('Fim da etapa %s.\n',mFileName{end});