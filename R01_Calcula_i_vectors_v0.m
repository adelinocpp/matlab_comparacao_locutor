close all;
addpath('../config/Bibliotecas/apstools/');
addpath('../config/Bibliotecas/MSR Identity Toolkit v1.0/code/');
addpath('../config/Bibliotecas/voicebox/');
% -------------------------------------------------------------------------
pwdData = split(pwd,'/');
fileResult = [OUT_DIR, sprintf('Resultado_%s_ivector.txt',pwdData{end})];
% -------------------------------------------------------------------------
if (exist(fileResult,'file')  && ~BOOL_RECOMPUTE_EXAM)
    fprintf('Arquivo %s já existe. Etapa já realizada.\nPara realizar novamente esta etapa remova-o\nou indique a variável BOOL_RECOMPUTE_EXAM para true.\n',fileResult)
    return,
end
fRes = fopen(fileResult,'w+');
% -------------------------------------------------------------------------
DATA_DIR = '../ivectorDATA/';
% -------------------------------------------------------------------------
load([DATA_DIR,'PARAMETROS.mat']);
load([DATA_DIR,'Base_UBM_mfcc.mat']);
load([DATA_DIR,'Tmatrix_GSM.mat']);
load([DATA_DIR,'Tmatrix_PDR.mat']);
% -------------------------------------------------------------------------
PARAMETROS = struct;
PARAMETROS.bool_SNR = false;
PARAMETROS.bool_UBM_GSM = true;
PARAMETROS.structFileName = [OUT_DIR,'iVectorData.mat'];
% -------------------------------------------------------------------------
Fs = 8000;
TimeStep = 0.01;
TimeWindow = 0.025;
% --- Lista arquivos contaminados por ruido -------------------------------
m='a';
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
STRING_FILENAME = [OUT_DIR,'DataSpeakerCompare_iv.mat'];
PARAMETROS.nUBMS = 2;

if (exist(STRING_FILENAME,'file') && ~BOOL_RECOMPUTE_EXAM)
    load(STRING_FILENAME);
    fprintf('Arquivo %s já existe. Etapa já realizada.\nPara realizar novamente esta etapa remova-o\nou indique a variável BOOL_RECOMPUTE_EXAM para true.\n',STRING_FILENAME)
else
    fprintf('Calculado comparação i-vector...\n')
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
        [y, fs] = audioread(str_Files(i).FileName);
        
        str_Files(i).Fs = fs;
        str_Files(i).NumSamples = length(y);
        
        vecVAD = vadsohn(y,fs,m,pp);
        if (PARAMETROS.bool_SNR)
            vecS2NR = s2nr_function(y , fs, timeWin, timeStep,...
                S2NR.NFFT , S2NR.RTH, S2NR.sigma);
            str_Files(i).s2nr         = vecS2NR;
            str_Files(i).snr          = mean(filtraVADbyFrame(vecS2NR,...
                Sample2FrameFeature(vecVAD,fs,TimeStep,TimeWindow,limiar)));
        else
            vecS2NR = [];
            str_Files(i).s2nr         = [];
            str_Files(i).snr          = snrVAD(y,fs);
        end
        mtxMFCC = paudio(y , fs, 0, 0);
        str_Files(i).vad          = vecVAD;
        str_Files(i).mfcc         = mtxMFCC;
        
        iVectorData = struct;
        for iUBM = 1:PARAMETROS.nUBMS
            if (iUBM == 1)
                load([DATA_DIR,'GSM_IVs.mat']);
                selUBM  = UBM(2);
                selT    = Tgsm;
                selMU   = muGSM;
                selMAT  = whMatGSM;
                iVectorData(iUBM).UBM = 'GSM';
            else
                load([DATA_DIR,'PDR_IVs.mat']);
                selUBM  = UBM(1); %#ok<*UNRCH>
                selT    = Tpdr;
                selMU   = muPDR;
                selMAT  = whMatPDR;
                iVectorData(iUBM).UBM = 'PDR';
            end
            
            
            tFEAT = filtraVADbyFrame(mtxMFCC,...
                Sample2FrameFeature(vecVAD,fs,TimeStep,TimeWindow,limiar));
            tFEAT 	= (tFEAT - selUBM.mUBM)./selUBM.sUBM;
            [N,F] 	= compute_bw_stats(tFEAT, selUBM.mfcc);
            IVtemp 	= extract_ivector([N; F], selUBM.mfcc, selT);
            iVectorData(iUBM).iVector 		= MatrixWhiten(IVtemp',selMU,selMAT)';
        end
        str_Files(i).iVectorData = iVectorData;
    end
    % ---------------------------------------------------------------------
    load([DATA_DIR,'LDA_models.mat']);
    for i = 1:length(str_Files)
        iVectorData = str_Files(i).iVectorData;
        for iUBM = 1:PARAMETROS.nUBMS
            if (iUBM == 1)
                LDA_model = GSM_LDA_model;
            else
                LDA_model = PDR_LDA_model;
            end
            
            iVectorData(iUBM).LDA	= apply_lda_model(str_Files(i).iVectorData(iUBM).iVector ,LDA_model); %#ok<*SAGROW>
        end
        str_Files(i).iVectorData = iVectorData;
    end
    % ---------------------------------------------------------------------
    load([DATA_DIR,'PLDA_models.mat']);
    REF_LDA = zeros(length(GSM_PLDA_model.M),length(str_Files));
    CMP_LDA = zeros(length(GSM_PLDA_model.M),length(str_Files));
    ivScores = struct;
    for iUBM = 1:PARAMETROS.nUBMS
        for i = 1:length(str_Files)
            REF_LDA(:,i) = str_Files(i).iVectorData(iUBM).LDA;
            CMP_LDA(:,i) = str_Files(i).iVectorData(iUBM).LDA;
        end
        if (iUBM == 1)
            PLDA_model = GSM_PLDA_model;
            ivScores(iUBM).UBM = 'GSM';
        else
            PLDA_model = PDR_PLDA_model;
            ivScores(iUBM).UBM = 'PDR';
        end
        ivScores(iUBM).result = score_gplda_trials(PLDA_model, REF_LDA, CMP_LDA);
        
    end
    save(STRING_FILENAME,'str_Files','ivScores','-v7.3');
    fprintf('Fim do cálculo da comparação i-vector...\n')
end
% -------------------------------------------------------------------------
fprintf('RESUMO DADOS i-vector...:\n');
for i = 1:length(str_Files)
    fprintf('Arquivo %02i: %s\n',i,str_Files(i).FileName);
    fprintf('\tTag: %s\n',str_Files(i).TagType);
    fprintf('\tDuração: %6.3f s\n',str_Files(i).NumSamples/str_Files(i).Fs);
    fprintf('\tTempo Vozeamento: %6.3f s\n',sum(str_Files(i).vad==1)/str_Files(i).Fs);
    fprintf('\tSNR médio : %6.3f dB\n',(str_Files(i).snr-3.2));
end
% -------------------------------------------------------------------------
fprintf(fRes,'RESUMO DADOS i-vector...:\n');
for i = 1:length(str_Files)
    fprintf(fRes,'Arquivo %02i: %s\n',i,str_Files(i).FileName);
    fprintf(fRes,'\tTag: %s\n',str_Files(i).TagType);
    fprintf(fRes,'\tDuração: %6.3f s\n',str_Files(i).NumSamples/str_Files(i).Fs);
    fprintf(fRes,'\tTempo Vozeamento: %6.3f s\n',sum(str_Files(i).vad==1)/str_Files(i).Fs);
    fprintf(fRes,'\tSNR médio : %6.3f dB\n',(str_Files(i).snr-3.2));
end
% -------------------------------------------------------------------------
save(PARAMETROS.structFileName,'str_Files','PARAMETROS','ivScores','-v7.3');
for iUBM = 1:PARAMETROS.nUBMS
    % TODO: verificar o arquivo "DET_01_01.mat" e conferir os dados de
    % calibracao para os gráficos tippet e limiares de decisao.
    if (iUBM == 1)
        load([DATA_DIR,'DET_01_01.mat']);
        UBMType = 'GSM';
    else
        load([DATA_DIR,'DET_01_01.mat']);
        UBMType = 'PDR';
    end
    AffMtxFileName = [OUT_DIR,sprintf('iVector_MtxAfinidade_UBM_%s.pdf',UBMType)];
    affMtxTittle = sprintf('Matriz de afinidade entre os locutores - UBM: %s',UBMType);
  
    
    % ---------------------------------------------------------------------
    
    [xData{1},ia] = unique(cellTippet{1}(:,2));
    yData{1} = cellTippet{1}(ia,1);
    [xData{2},ia] = unique(cellTippet{2}(:,2));
    yData{2} = 1 - cellTippet{2}(ia,1);
    
    % --- TODO: encapsular ------------------------------------------------
    xlimin = min([xData{1}; xData{2}]);
    xlimax = max([xData{1}; xData{2}]);
    Npts = 10000;
    scoreDim = linspace(xlimin,xlimax,Npts);
    TPR = tippetinterp(xData{1},yData{1},scoreDim);
    TNR = tippetinterp(xData{2},yData{2},scoreDim);
    diffTAX = TPR-TNR;
    idx1 = find(diffTAX >= 0,1,'first');
    idx0 = find(diffTAX <= 0,1,'last');
    crossPoint = interp1([diffTAX(idx0),diffTAX(idx1)],[scoreDim(idx0),scoreDim(idx1)],0);
    
    % ---------------------------------------------------------------------
    afMatrix = (ivScores(iUBM).result - xThs);
    llrLimit = max(abs(afMatrix(:)));
    figure, imagesc(afMatrix);
    colormap(cmRed2Blue); caxis([-llrLimit, llrLimit]), colorbar;
    set(gca,'YTick',1:length(str_Files));
    set(gca,'YTickLabel',{str_Files.TagType});
    set(gca,'XTick',1:length(str_Files));
    set(gca,'XTickLabel',{str_Files.TagType});
    title(affMtxTittle)
    figure2jpeg(AffMtxFileName,1);
    % ---------------------------------------------------------------------
    
    % --- IMPRIME NA TELA E ARQUIVO, PLOTS --------------------------------
    fprintf('RESULTADOS i-vector UBM: %s...\n',UBMType);
    fprintf(fRes,'RESULTADOS i-vector UBM: %s...\n',UBMType);
    for i = 1:(size(afMatrix,1)-1)
        for j = i+1:size(afMatrix,2)
            scoreIJ = afMatrix(i,j);
            
            fprintf('----------------------------------- \n');
            fprintf('Score = %+5.4e (%+4.2e,%+4.2e) \n',scoreIJ,min(xData{2}),max(xData{1}));
            fprintf(fRes,'----------------------------------- \n');
            fprintf(fRes,'Score = %+5.4e (%+42e,%+4.2e) \n',scoreIJ,min(xData{2}),max(xData{1}));
            scrTaxDS = 100*tippetinterp(xData{2},yData{2},scoreIJ);
            scrTaxSS = 100*tippetinterp(xData{1},yData{1},scoreIJ);
            if ((scoreIJ <= 0) && (scoreIJ < crossPoint))
                fprintf('Score que desassocia locutores %s e %s. \n',str_Files(i).TagType,str_Files(j).TagType);
                fprintf('Taxa experimental de rejeição verdadeira de %4.1f%% (%5.3f) \n',...
                scrTaxDS,scrTaxDS/scrTaxSS);
                fprintf(fRes,'Score que desassocia locutores %s e %s. \n',str_Files(i).TagType,str_Files(j).TagType);
                fprintf(fRes,'Taxa experimental de rejeição verdadeira de %4.1f%% (%5.3f) \n',...
                scrTaxDS,scrTaxDS/scrTaxSS);
            elseif ((scoreIJ > 0) && (scoreIJ > crossPoint))
                fprintf('Score que associa locutores %s e %s. \n',str_Files(i).TagType,str_Files(j).TagType);
                fprintf('Taxa experimental de aceitação verdadeira de %4.1f%% (%5.3f)\n',...
                scrTaxSS,scrTaxSS/scrTaxDS);
                fprintf(fRes,'Score que associa locutores %s e %s. \n',str_Files(i).TagType,str_Files(j).TagType);
                fprintf(fRes,'Taxa experimental de aceitação verdadeira de %4.1f%% (%5.3f)\n',...
                scrTaxSS,scrTaxSS/scrTaxDS);
            else
                fprintf('Score entre limiar de decisão por %s e %s. \n',str_Files(i).TagType,str_Files(j).TagType);
                fprintf('Razão de experimental de aceitação verdadeira de %5.3f \n',...
                scrTaxSS/scrTaxDS);
                fprintf(fRes,'Score entre limiar de decisão por %s e %s. \n',str_Files(i).TagType,str_Files(j).TagType);
                fprintf(fRes,'Razão de experimental de aceitação verdadeira de %5.3f \n',...
                scrTaxSS/scrTaxDS);
            end 
            FileNameTippet = [OUT_DIR,sprintf('iVector_Tippet_plot_%s_x_%s_UBM_%s.pdf',...
                str_Files(i).TagType,str_Files(j).TagType,UBMType)];
            TippetTittle = sprintf('Curva tippet - %s x %s UBM: %s ',...
                str_Files(i).TagType,str_Files(j).TagType,UBMType);
            figure, grid on;
            hold on, plot(xData{1},yData{1},'b','LineWidth',2);
            hold on, plot(xData{2},yData{2},'r','LineWidth',2);
            hold on, plot([0,0],[0,1],'k--','LineWidth',2);
            hold on, plot([scoreIJ,scoreIJ],[0,1],'g','LineWidth',2);
            hold on, plot([crossPoint,crossPoint],[0,1],'m-.','LineWidth',2);
            legend('Taxa aceitação','Taxa rejeição','Limiar','Pontuação','Cross','Location','SouthWest');
            axis([xlimin,xlimax,0,1]);
            
            xlabel('Limiar normalizado','FontSize',14);
            ylabel('Taxa [0-1]','FontSize',14);
            title(TippetTittle)
            figure2jpeg(FileNameTippet,6);
        end
    end
    fprintf('----------------------------------- \n');    
    fprintf(fRes,'----------------------------------- \n');  
    
    % ---------------------------------------------------------------------
    
end
fclose(fRes);
mFileName = split(mfilename('fullpath'),'/');
fprintf('Fim da etapa %s.\n',mFileName{end});