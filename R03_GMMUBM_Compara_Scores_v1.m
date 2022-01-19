close all;
addpath('../config/Bibliotecas/apstools/');
series = [];
interval = [];
labels = {'UBM Padão-PDR x PDR','UBM Padão-PDR x QST','UBM Padão-GSM x QST',...
          'UBM Questionado-PDR x PDR','UBM Questionado-PDR x QST','UBM Questionado-GSM x QST',...
	  'UBM GSM-PDR x PDR','UBM GSM-PDR x QST', 'UBM GSM-GSM x QST'};

FigureFile_ALL = [OUT_DIR, 'F00_GMMUBM_Loglike_TodosCasos.jpg'];
FigureFile_UBMPDR = [OUT_DIR, 'F00_GMMUBM_Loglike_UBMPDR.jpg'];
FigureFile_UBMGSM = [OUT_DIR, 'F00_GMMUBM_Loglike_UBMGSM.jpg'];

% -------------------------------------------------------------------------
pwdData = split(pwd,'/');
fileResult = [OUT_DIR, sprintf('Resultado_%s_gmmubm.txt',pwdData{end})];
% -------------------------------------------------------------------------
if (exist(fileResult,'file')  && ~BOOL_RECOMPUTE_EXAM)
    fprintf('Arquivo %s já existe. Etapa já realizada.\nPara realizar novamente esta etapa remova-o\nou indique a variável BOOL_RECOMPUTE_EXAM para true.\n',fileResult)
    return,
end
fRes = fopen(fileResult,'w+');

if (exist(GMMUBM_ConfrontFile,'file'))
    load(GMMUBM_ConfrontFile)
else
    fprintf('Erro: Arquivo %s não encontrado. Execute a rotina R02_Computa_Scores_v0.m\n',GMMUBM_ConfrontFile)
end

if ( exist(FigureFile_ALL,'file') || ...
     exist(FigureFile_UBMPDR,'file') || ...
     exist(FigureFile_UBMGSM,'file'))
    fprintf('Os resultados desta etapa (ou parte deles) já foi calculado.\nPara realizar novamente esta etapa remova-os\nou indique a variável BOOL_RECOMPUTE_EXAM para true.\n')
else
    % --- IMPRIME NA TELA E ARQUIVO, PLOTS --------------------------------
    fprintf('RESULTADOS GMM-UBM: ...\n');
    fprintf(fRes,'RESULTADOS GMM-UBM: ...\n');
    % TODO: acertar este threshold
    thr = 0;
    % --- Todos resultados ----------------------------------------------------
    nResults = length(resultData);
    vecLL = zeros(1,nResults);
    vecLL_DW = zeros(1,nResults);
    vecLL_UP = zeros(1,nResults);
    labLL = cell(1,nResults);
    idxLabel = 1:nResults;
    figure,
    for i = 1:nResults
        FBST = resultData(i).FBST(1,:) - thr;
        PTS = resultData(i).PTS;
        vecLL(i) = PTS{2} - thr;
        vecLL_DW(i) = FBST(2)-FBST(1);
        vecLL_UP(i) = FBST(3)-FBST(2);
        labLL{i} = sprintf('UBM: %s - COMP: %s',resultData(i).UBM,resultData(i).TRIAL);
        varFaceColor = [149/255, 187/255, 188/255];
        tagString = 'Compatível';
        if (PTS{2} < thr)
            varFaceColor = [106/255, 68/255, 67/255];
            tagString = 'Incompatível';
        end
        if (thr < vecLL_UP(i)) && (thr > vecLL_DW(i))
            tagString = [tagString,' dentro do intervalo de incerteza'];
        end
        hold on, barh(i,PTS{2},'FaceColor',varFaceColor);
        fprintf('\t %s - Score: %+5.3e; Inf: %+5.3e; Sup: %+5.3e; TAG: %s\n',...
            labLL{i}, vecLL(i), vecLL_DW(i), vecLL_UP(i),tagString);
        fprintf(fRes,'\t %s - Score: %+5.3e; Inf: %+5.3e; Sup: %+5.3e; TAG: %s\n',...
            labLL{i}, vecLL(i), vecLL_DW(i), vecLL_UP(i),tagString);
    end
    % figure, barh(idxLabel,vecLL, 'FaceColor',[149/255, 187/255, 188/255]);
    hold on, errorbar(vecLL,idxLabel,vecLL_DW,vecLL_UP,'o','horizontal','LineWidth',2,'Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
    grid on;
    set(gca,'YTick',idxLabel);
    a = get(gca,'YTickLabel');
    set(gca,'YTickLabel',a,'fontsize',10)
    set(gca,'YTickLabel',labLL);
    xlabel('Log da razão de verossimilhança');
    titleSTRING = {'Comparação dos locutores com todos resultados',sprintf('Limiar de decisão em %5.3e',thr)};
    title(titleSTRING);
    legend(sprintf('Limiar de decisão em %5.3e',thr),'Location','Best')
    figure2jpeg(FigureFile_ALL,8);
    % -------------------------------------------------------------------------
    
    % --- UBM ÁUDIOS SEM CANAL GSM --------------------------------------------
    % TODO: acertar este threshold
    thr = 0;
    vecLL = [];
    vecLL_DW = [];
    vecLL_UP = [];
    labLL = [];
    idxLabel = [];
    k = 0;
    figure,
    for i = 1:nResults
        if (strcmp(resultData(i).UBM,'PDR') && strcmp(resultData(i).TRIAL(1:3),'PDR') )
            FBST = resultData(i).FBST(1,:) - thr;
            PTS = resultData(i).PTS;
            vecLL = [vecLL, PTS{2} - thr]; %#ok<*AGROW>
            vecLL_DW = [vecLL_DW, FBST(2)-FBST(1)];
            vecLL_UP = [vecLL_UP, FBST(3)-FBST(2)];
            labLL{end+1} = sprintf('UBM: %s - COMP: %s',resultData(i).UBM,resultData(i).TRIAL); %#ok<*SAGROW>
            k = k+1;
            idxLabel = [idxLabel, k];
            varFaceColor = [149/255, 187/255, 67/255];
            if (PTS{2} < thr)
                varFaceColor = [106/255, 68/255, 67/255];
            end
            hold on, barh(k,PTS{2},'FaceColor',varFaceColor);
        end
    end
    % figure, barValue = barh(idxLabel,vecLL,'FaceColor',[149/255, 187/255, 67/255]);
    hold on, errorbar(vecLL,idxLabel,vecLL_DW,vecLL_UP,'o','horizontal','LineWidth',2,'Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
    grid on;
    set(gca,'YTick',idxLabel);
    a = get(gca,'YTickLabel');
    set(gca,'YTickLabel',a,'fontsize',10)
    set(gca,'YTickLabel',labLL);
    xlabel('Log da razão de verossimilhança');
    titleSTRING = {'Comparação dos locutores com UBM sem contaminação GSM',sprintf('Limiar de decisão em %5.3e',thr)};
    title(titleSTRING);
    figure2jpeg(FigureFile_UBMPDR,6);
    % -------------------------------------------------------------------------
    
    % --- UBM ÁUDIOS COM CANAL GSM --------------------------------------------
    % nResults = length(resultData);
    % TODO: acertar este threshold
    thr = 0;
    vecLL = [];
    vecLL_DW = [];
    vecLL_UP = [];
    labLL = [];
    idxLabel = [];
    k = 0;
    figure,
    for i = 1:nResults
        if (strcmp(resultData(i).UBM,'GSM') && strcmp(resultData(i).TRIAL(1:3),'GSM') )
            FBST = resultData(i).FBST(1,:) - thr;
            PTS = resultData(i).PTS;
            vecLL = [vecLL, PTS{2} - thr]; %#ok<*AGROW>
            vecLL_DW = [vecLL_DW, FBST(2)-FBST(1)];%#ok<*AGROW>
            vecLL_UP = [vecLL_UP, FBST(3)-FBST(2)];
            labLL{end+1} = sprintf('UBM: %s - COMP: %s',resultData(i).UBM,resultData(i).TRIAL);
            k = k+1;
            idxLabel = [idxLabel, k];
            varFaceColor = [106/255, 68/255, 188/255];
            if (PTS{2} < thr)
                varFaceColor = [106/255, 68/255, 67/255];
            end
            hold on, barh(k,PTS{2},'FaceColor',varFaceColor);
        end
    end
    hold on, errorbar(vecLL,idxLabel,vecLL_DW,vecLL_UP,'o','horizontal','LineWidth',2,'Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
    grid on;
    set(gca,'YTick',idxLabel);
    a = get(gca,'YTickLabel');
    set(gca,'YTickLabel',a,'fontsize',10)
    set(gca,'YTickLabel',labLL);
    xlabel('Log da razão de verossimilhança');
    titleSTRING = {'Comparação dos locutores com UBM com contaminação GSM',sprintf('Limiar de decisão em %5.3e',thr)};
    title(titleSTRING);
    figure2jpeg(FigureFile_UBMGSM,6);
    % -------------------------------------------------------------------------
end
fclose(fRes);
mFileName = split(mfilename('fullpath'),'/');
fprintf('Fim da etapa %s.\n',mFileName{end});