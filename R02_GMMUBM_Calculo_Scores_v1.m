close all;
set(0, 'DefaultFigureVisible', 'off');
% Adicionando caminho para a Biblioteca VoiceBox
addpath('../config/Bibliotecas/voicebox/');
addpath('../config/Bibliotecas/MSR Identity Toolkit v1.0/code/');
addpath('../config/Bibliotecas/apstools/');

if (exist(UBM_Data_File,'file'))
    load(UBM_Data_File);
else
    fprintf('Erro: arquivo UBM não encotrado.\n')
    return,
end
if (exist(GMMUBM_FileData,'file'))
    load(GMMUBM_FileData);
else
    fprintf('Erro: arquivo de dados GMM dos locutores não encotrado. Execute a rotina R01_Computa_GMM_v0.m\n')
    return,
end

if (exist(GMMUBM_ConfrontFile,'file') && ~BOOL_RECOMPUTE_EXAM)
    fprintf('Arquivo %s já existe. Etapa já realizada.\nPara realizar novamente esta etapa remova-o\nou indique a variável BOOL_RECOMPUTE_EXAM para true.\n',GMMUBM_ConfrontFile)
else
    % Opening MATLAB pool
    nworkers = feature('numCores');
    isopen = isempty(gcp('nocreate'));
    if isopen, parpool('local',nworkers); end
    
    cellUBM = {ubmPDR, ubmQST, ubmGSM};
    labelUBM = {'PDR','QST','GSM'};
    cellGMM = {GMM_UBMPDR_PDR,...
        GMM_UBMPDR_QST,...
        GMM_UBMPDR_GSM,...
        GMM_UBMPDR_OTR,...
        GMM_UBMQST_PDR,...
        GMM_UBMQST_QST,...
        GMM_UBMQST_GSM,...
        GMM_UBMQST_OTR,...
        GMM_UBMGSM_PDR,...
        GMM_UBMGSM_QST,...
        GMM_UBMGSM_GSM,...
        GMM_UBMGSM_OTR};
    numCompControlVec = zeros(length(cellGMM),1);
    for i = 1:length(cellGMM)
        numCompControlVec(i) = (~isempty(fieldnames(cellGMM{i})))*length(cellGMM{i});
    end
    labelCompControlVec = {'UBMPDR_PDR',...
        'UBMPDR_QST',...
        'UBMPDR_GSM',...
        'UBMPDR_OTR',...
        'UBMQST_PDR',...
        'UBMQST_QST',...
        'UBMQST_GSM',...
        'UBMQST_OTR',...
        'UBMGSM_PDR',...
        'UBMGSM_QST',...
        'UBMGSM_GSM',...
        'UBMGSM_OTR'};
    
    cellMFCC = {BasePDR,BaseQST,BaseGSM, BaseOTR};
    numBasesControlVec = zeros(length(cellMFCC),1);
    for i = 1:length(cellMFCC)
        numBasesControlVec(i) = (~isempty(fieldnames(cellMFCC{i}))*length(cellMFCC{i}));
    end
    labelBasesControlVec = {'PDR', 'QST', 'GSM', 'OTR'};
    
    % --- Numero de pontos para integraçoa do FBST
    NpThr = 300;
    resultData = struct;
    indexComp = 0;
    for nUBM = 1:length(cellUBM)
        for nGMM = 1:length(cellGMM)
            currGMM = cellGMM{nGMM};
            for nBase = 1:length(cellMFCC)
                currBase = cellMFCC{nBase};
                trials = [];
                for i = 1:1:numCompControlVec(nGMM)
                    a = [ repmat(i,1,numBasesControlVec(nBase)); 1:1:numBasesControlVec(nBase) ]';
                    trials = [trials; a]; %#ok<*AGROW>
                end
                sameUBMrefUBMcomp = (strcmp(labelCompControlVec{nGMM}(4:6),labelUBM{nUBM}) == 1);
                gmmNOTQST = (strcmp(labelCompControlVec{nGMM}(8:10),'QST') ~= 1);
                cutAlmostRef = false;
                if ((numel(trials) > 0) && sameUBMrefUBMcomp && gmmNOTQST && ~cutAlmostRef)
                    indexComp = indexComp +1;
                    [scores_tr, LLRbyPoint, mv] = score_gmm_trials({currGMM.gmm_model}', {currBase.mfc}', trials, cellUBM{nUBM});
                    resultData(indexComp).TRIAL = [labelCompControlVec{nGMM}(8:10),' x ',labelBasesControlVec{nBase}];
                    resultData(indexComp).UBM = labelUBM{nUBM};
                    resultData(indexComp).PTS = [trials, scores_tr, mv];
                    resultData(indexComp).LLRbyPOINT = LLRbyPoint{1};
                    
                    med = mean(LLRbyPoint{1});
                    sd = std(LLRbyPoint{1});
                    np = length(LLRbyPoint{1});
                    minThr = med - 4.5*sd/sqrt(np);
                    maxThr = med + 4.5*sd/sqrt(np);
                    thr = linspace(minThr,maxThr,NpThr);
                    temp     = FBST_MVD_L(LLRbyPoint{1},thr);
                    [~, n] = min(temp);
                    idx1_950 = find(temp(1:n) > 0.95, 1,'last');
                    idx2_950 = n - 1 + find(temp(n:end) > 0.95, 1,'first');
                    idx1_975 = find(temp(1:n) > 0.975, 1,'last');
                    idx2_975 = n - 1 + find(temp(n:end) > 0.975, 1,'first');
                    mtxIntev = [thr(idx1_950) ,med, thr(idx2_950) ; thr(idx1_975) ,med, thr(idx2_975) ];
                    resultData(indexComp).FBST = mtxIntev;
                    fprintf('Numel trial : %i (%s,%s,%s) \n',size(trials,1),labelUBM{nUBM},labelCompControlVec{nGMM},labelBasesControlVec{nBase});
                else
                    continue
                end
            end
        end
    end
    save(GMMUBM_ConfrontFile, 'resultData','-v7.3');
end
mFileName = split(mfilename('fullpath'),'/');
fprintf('Fim da etapa %s.\n',mFileName{end});