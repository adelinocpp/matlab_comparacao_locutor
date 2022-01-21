close all;
addpath('../config/Bibliotecas/apstools/');
addpath('../config/Bibliotecas/WBdnnfunctions/');
addpath('../config/Bibliotecas/MSR Identity Toolkit v1.0/code/');
addpath('../config/Bibliotecas/voicebox/');
% -------------------------------------------------------------------------
pwdData = split(pwd,'/');
fileResult = [OUT_DIR, sprintf('Resultado_%s_fivector.txt',pwdData{end})];
% -------------------------------------------------------------------------
if (exist(fileResult,'file')  && ~BOOL_RECOMPUTE_EXAM  && ~isempty(dir(fileResult)) )
    fprintf('Arquivo %s já existe. Etapa já realizada.\nPara realizar novamente esta etapa remova-o\nou indique a variável BOOL_RECOMPUTE_EXAM para true.\n',fileResult)
    return,
end
fRes = fopen(fileResult,'w+');
% -------------------------------------------------------------------------
DATA_DIR = '../config/fivectorDATA/';
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
load([DATA_DIR,'PARAMETROS.mat']);
PARAMETROS.structFileName = [OUT_DIR,'fiVectorData.mat'];
load(PARAMETROS.structFileName);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
load([DATA_DIR, 'LDA_models_fuzzy.mat']);
% if (PARAMETROS.bool_UBM_GSM)
%     LDA_model_CELL = GSM_LDA_model_CELL;
%     clear GSM_LDA_model_CELL;
% else
%     LDA_model_CELL = PDR_LDA_model_CELL;
%     clear GSM_LDA_model_CELL;
% end  
% -------------------------------------------------------------------------
load([DATA_DIR,'DadosFuzzy.mat']);
load([DATA_DIR,'SNR_Classes.mat']);
% -------------------------------------------------------------------------
for i = 1:length(str_Files)
    for iUBM = 1:PARAMETROS.nUBMS
        if (iUBM == 1)
            LDA_model_CELL = GSM_LDA_model_CELL;
            
        else
            LDA_model_CELL = PDR_LDA_model_CELL;
            
        end
        for iFc = 1:DadosFuzzy.Num_Class
            LDA_model = LDA_model_CELL{iFc};
            %             str_Files(i).FLDA{iFc}	= apply_lda_model(str_Files(i).iVector{iFc} ,LDA_model); %#ok<*SAGROW>
            str_Files(i).fiVectorData(iUBM).FLDA{iFc}	= apply_lda_model(str_Files(i).fiVectorData(iUBM).iVector{iFc} ,LDA_model); %#ok<*SAGROW>
        end
        
        
    end
end
clear PDR_LDA_model_CELL  GSM_LDA_model_CELL;

load([DATA_DIR,'PLDA_models_fuzzy.mat']);
load([DATA_DIR,'Opt_WB_v0.mat']);
aScore = cell(PARAMETROS.nUBMS,1);
for iUBM = 1:PARAMETROS.nUBMS
    if (iUBM == 1)
        PLDA_model_CELL = GSM_PLDA_model_CELL;
    else
        PLDA_model_CELL = PDR_PLDA_model_CELL;
    end
    
    cellScores = cell(DadosFuzzy.Num_Class,1);
    vecSamples = zeros(length(str_Files)*length(str_Files),DadosFuzzy.Num_Class);
    for iFc = 1:DadosFuzzy.Num_Class
        PLDA_model = PLDA_model_CELL{iFc};
        
        REF_LDA = zeros(length(str_Files(1).fiVectorData(iUBM).FLDA{1}),length(str_Files));
        CMP_LDA = zeros(length(str_Files(1).fiVectorData(iUBM).FLDA{1}),length(str_Files));
        
        for i = 1:length(str_Files)
            REF_LDA(:,i) = str_Files(i).fiVectorData(iUBM).FLDA{iFc};
            CMP_LDA(:,i) = str_Files(i).fiVectorData(iUBM).FLDA{iFc};
        end
        cellScores{iFc} = score_gplda_trials(PLDA_model, REF_LDA, CMP_LDA);
        A = cellScores{iFc};
        vecSamples(:,iFc) = A(:);
    end
    aScore{iUBM} = reshape(eval_dnn(vecSamples,DNN,true),length(str_Files),length(str_Files));
end
clear GSM_PLDA_model_CELL PDR_PLDA_model_CELL DNN;
% -------------------------------------------------------------------------
fprintf('RESUMO DADOS fuzzy i-vector...:\n');
for i = 1:length(str_Files)
    fprintf('Arquivo %02i: %s\n',i,str_Files(i).FileName);
    fprintf('\tTag: %s\n',str_Files(i).TagType);
    fprintf('\tDuração: %6.3f s\n',str_Files(i).NumSamples/str_Files(i).Fs);
    fprintf('\tTempo Vozeamento: %6.3f s\n',sum(str_Files(i).vad==1)/str_Files(i).Fs);
    fprintf('\tSNR médio : %6.3f dB\n',(str_Files(i).snr-3.2));
end
% -------------------------------------------------------------------------
fprintf(fRes,'RESUMO DADOS fuzzy i-vector...:\n');
for i = 1:length(str_Files)
    fprintf(fRes,'Arquivo %02i: %s\n',i,str_Files(i).FileName);
    fprintf(fRes,'\tTag: %s\n',str_Files(i).TagType);
    fprintf(fRes,'\tDuração: %6.3f s\n',str_Files(i).NumSamples/str_Files(i).Fs);
    fprintf(fRes,'\tTempo Vozeamento: %6.3f s\n',sum(str_Files(i).vad==1)/str_Files(i).Fs);
    fprintf(fRes,'\tSNR médio : %6.3f dB\n',(str_Files(i).snr-3.2));
end
% -------------------------------------------------------------------------
save(PARAMETROS.structFileName,'str_Files','PARAMETROS','cellScores','aScore','-v7.3');
for iUBM = 1:PARAMETROS.nUBMS
    % TODO: verificar o arquivo "DET_03_06.mat" e conferir os dados de
    % calibracao para os gráficos tippet e limiares de decisao.
    if (iUBM == 1)
        load([DATA_DIR,'DET_03_06.mat']);
        UBMType = 'GSM';
    else
        load([DATA_DIR,'DET_03_06.mat']);
        UBMType = 'PDR';
    end
    AffMtxFileName = [OUT_DIR,sprintf('fuzzy_iVector_MtxAfinidade_UBM_%s.pdf',UBMType)];
    affMtxTittle = sprintf('Matriz de afinidade entre os locutores - UBM: %s',UBMType);
    
    
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

    % -------------------------------------------------------------------------
    afMatrix = (aScore{iUBM} - xThs);
    llrLimit = max(abs([xlimin,xlimax]));
    figure, imagesc(afMatrix);
    colormap(cmRed2Blue); caxis([-llrLimit, llrLimit]), colorbar;
    set(gca,'YTick',1:length(str_Files));
    set(gca,'YTickLabel',{str_Files.TagType});
    set(gca,'XTick',1:length(str_Files));
    set(gca,'XTickLabel',{str_Files.TagType});
    title(affMtxTittle)
    figure2jpeg(AffMtxFileName,1);
   
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
            FileNameTippet = [OUT_DIR,sprintf('fuzzy_iVector_Tippet_plot_%s_x_%s_UBM_%s.pdf',...
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
    
    
end
fclose(fRes);
mFileName = split(mfilename('fullpath'),'/');
fprintf('Fim da etapa %s.\n',mFileName{end});
return,


DATA_DIR = '../DATA/';
% -------------------------------------------------------------------------
load([DATA_DIR,'PARAMETROS.mat']);
structFileName = 'iVectorData.mat';
load(structFileName);
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
load([DATA_DIR,'DadosFuzzy.mat']);
% -------------------------------------------------------------------------
load([DATA_DIR, 'LDA_models_fuzzy.mat']);
if (PARAMETROS.bool_UBM_GSM)
    LDA_model_CELL = GSM_LDA_model_CELL;
    clear GSM_LDA_model_CELL;
else
    LDA_model_CELL = PDR_LDA_model_CELL;
    clear GSM_LDA_model_CELL;
end  
% -------------------------------------------------------------------------
load([DATA_DIR,'DadosFuzzy.mat']);
load([DATA_DIR,'SNR_Classes.mat']);
% -------------------------------------------------------------------------
for i = 1:length(str_Files)
    for iFc = 1:DadosFuzzy.Num_Class
        LDA_model = LDA_model_CELL{iFc};
        str_Files(i).FLDA{iFc}	= apply_lda_model(str_Files(i).iVector{iFc} ,LDA_model); %#ok<*SAGROW>
    end
end

% -------------------------------------------------------------------------
load([DATA_DIR,'PLDA_models_fuzzy.mat']);
if (PARAMETROS.bool_UBM_GSM)
    PLDA_model_CELL = GSM_PLDA_model_CELL;
    clear GSM_PLDA_model_CELL;
else
    PLDA_model_CELL = PDR_PLDA_model_CELL;
    clear PDR_PLDA_model_CELL;
end
cellScores = cell(DadosFuzzy.Num_Class,1);

vecSamples = zeros(length(str_Files)*length(str_Files),DadosFuzzy.Num_Class);
for iFc = 1:DadosFuzzy.Num_Class
    PLDA_model = PLDA_model_CELL{iFc};
    
    REF_LDA = zeros(length(str_Files(1).FLDA{1}),length(str_Files));
    CMP_LDA = zeros(length(str_Files(1).FLDA{1}),length(str_Files));
    
    for i = 1:length(str_Files)
        REF_LDA(:,i) = str_Files(i).FLDA{iFc};
        CMP_LDA(:,i) = str_Files(i).FLDA{iFc};
    end
    cellScores{iFc} = score_gplda_trials(PLDA_model, REF_LDA, CMP_LDA);
    A = cellScores{iFc};
    vecSamples(:,iFc) = A(:);
end
load([DATA_DIR,'Opt_WB_v0.mat']);



% -------------------------------------------------------------------------
fprintf(fRes,'RESUMO DADOS...\n');
for i = 1:length(str_Files)
    fprintf(fRes,'Arquivo %02i: %s\n',i,str_Files(i).FileName);
    fprintf(fRes,'\tTag: %s\n',str_Files(i).TagType);
    fprintf(fRes,'\tDuração: %6.3f s\n',str_Files(i).NumSamples/str_Files(i).Fs);
    fprintf(fRes,'\tTempo Vozeamento: %6.3f s\n',sum(str_Files(i).vad==1)/str_Files(i).Fs);
    fprintf(fRes,'\tSNR médio : %6.3f dB\n',(str_Files(i).snr-3.2));
end
% -------------------------------------------------------------------------
load([DATA_DIR,'DET_03_06.mat']);
save(PARAMETROS.structFileName,'str_Files','PARAMETROS','cellScores','aScore','-v7.3');
[xData{1},ia] = unique(cellTippet{1}(:,2));
yData{1} = cellTippet{1}(ia,1);
[xData{2},ia] = unique(cellTippet{2}(:,2));
yData{2} = 1 - cellTippet{2}(ia,1);
xlimin = min([xData{1}; xData{2}]);
xlimax = max([xData{1}; xData{2}]);

% -------------------------------------------------------------------------
afMatrix = (aScore - xThs);
llrLimit = max(abs([xlimin,xlimax]));
figure, imagesc(afMatrix);
colormap(cmRed2Blue); caxis([-llrLimit, llrLimit]), colorbar; 
set(gca,'YTick',1:length(str_Files));
set(gca,'YTickLabel',{str_Files.TagType});
set(gca,'XTick',1:length(str_Files));
set(gca,'XTickLabel',{str_Files.TagType});
figure2pdf('MtxAfinidade.pdf',1);

fprintf(fRes,'RESULTADOS...\n');
if (afMatrix(1,2) <= 0)
    fprintf(fRes,'Score %6.4f desassocia locutores. \n',afMatrix(1,2)) ;
    fprintf(fRes,'Taxa experimental de rejeição verdadeira de %5.2f %% \n',... 
    100*interp1(xData{2},yData{2},afMatrix(1,2)));
else
    fprintf(fRes,'Score %6.4f associa locutores. \n',afMatrix(1,2)) ;
    fprintf(fRes,'Taxa experimental de aceitação verdadeira de %5.2f %% \n',... 
    100*interp1(xData{1},yData{1},afMatrix(1,2)));
end

figure, grid on;
hold on, plot(xData{1},yData{1},'b','LineWidth',2);
hold on, plot(xData{2},yData{2},'r','LineWidth',2);
legend('TAR','TRR','Location','SouthWest');
hold on, plot([0,0],[0,1],'k--','LineWidth',2);
hold on, plot([afMatrix(1,2),afMatrix(1,2)],[0,1],'g','LineWidth',2);
xlimin = min([xData{1}; xData{2}]);
xlimax = max([xData{1}; xData{2}]);
axis([xlimin,xlimax,0,1]);
xlabel('Normalized Raw Threshold','FontSize',14);
ylabel('Rate','FontSize',14);
FileName = sprintf('PART_Tippet_plot_TEST.pdf');
figure2pdf(FileName,6);
fclose(fRes)
