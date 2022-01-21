close all;
set(0, 'DefaultFigureVisible', 'off');
% --- Adicionando caminho para a Biblioteca VoiceBox ----------------------
addpath('../config/Bibliotecas/apstools/');
addpath('../config/Bibliotecas/voicebox/');
addpath('../config/Bibliotecas/MSR Identity Toolkit v1.0/code/');

if (exist(GMMUBM_FileData,'file') && ~BOOL_RECOMPUTE_EXAM)
    fprintf('Arquivo %s já existe. Etapa já realizada.\nPara realizar novamente esta etapa remova-o\nou indique a variável BOOL_RECOMPUTE_EXAM para true.\n',GMMUBM_FileData)
else
    % --- Carga dos dados -----------------------------------------------------
    if (~exist(UBM_Raw_File,'file'))
        fprintf('Arquivo %s não encontrado. Verifique se o diretório de origem.\n',UBM_Raw_File);
        return, 
    end
    if (~exist(UBM_Data_File,'file'))
        fprintf('Arquivo %s não encontrado. Verifique se o diretório de origem.\n',UBM_Data_File);
        return,
    end
    load(UBM_Raw_File);
    load(UBM_Data_File);
    
    % ---- Opening MATLAB pool ------------------------------------------------
    nworkers = feature('numCores');
    isopen = isempty(gcp('nocreate'));
    if isopen, parpool('local',nworkers); end
    
    % --- Leitura de arquivos de entrada --------------------------------------
    Files = lista_conteudo_pasta([],{'.wav'});
    str_PDR_Files_Name = [];
    str_QST_Files_Name = [];
    str_OTR_Files_Name = [];
    str_GSM_Files_Name = [];
    str_ENC_Files_Name = [];
    for  i = 1:length(Files)
        boolPDR = ~isempty(strfind(Files{i}, 'PDR'));
        boolQST = ~isempty(strfind(Files{i}, 'QST'));
        boolGSM = ~isempty(strfind(Files{i}, 'GSM'));
        boolENC = ~isempty(strfind(Files{i}, 'ENC'));
        if (boolPDR)
            str_PDR_Files_Name{end+1} = strcat(Files{i}); %#ok<*SAGROW>
        end
        if (boolQST)
            str_QST_Files_Name{end+1} = strcat(Files{i}); 
        end
        if (boolGSM)
            str_GSM_Files_Name{end+1} = strcat(Files{i}); 
        end
        if (boolENC)
            str_ENC_Files_Name{end+1} = strcat(Files{i}); 
        end
        if (~(boolPDR || boolQST || boolGSM || boolENC))
            str_OTR_Files_Name{end+1} = strcat(Files{i}); 
        end
        
    end
    
    % -------------------------------------------------------------------------
    BasePDR = struct;
    parfor i = 1:1:size(str_PDR_Files_Name,2)
        idPDR = sprintf('%06i',10*i+1);
        fprintf('Processamento arquivo %s.\n',idPDR);
        BasePDR(i).id = idPDR;
        BasePDR(i).file = str_PDR_Files_Name(i);
        BasePDR(i).mfc = paudio_filename( char(str_PDR_Files_Name(i)) );
    end
    
    BaseQST = struct;
    parfor i = 1:1:size(str_QST_Files_Name,2)
        idQST = sprintf('%06i',10*i+2);
        fprintf('Processamento arquivo %s.\n',idQST);
        BaseQST(i).id = idQST;
        BaseQST(i).file = str_QST_Files_Name(i);
        BaseQST(i).mfc = paudio_filename( char(str_QST_Files_Name(i)) );
    end
    
    BaseGSM = struct;
    parfor i = 1:1:size(str_GSM_Files_Name,2)
        idGSM = sprintf('%06i',10*i+3);
        fprintf('Processamento arquivo %s.\n',idGSM);
        BaseGSM(i).id = idGSM;
        BaseGSM(i).file = str_GSM_Files_Name(i);
        BaseGSM(i).mfc = paudio_filename( char(str_GSM_Files_Name(i)) );
    end
    
    BaseOTR = struct;
    parfor i = 1:1:size(str_OTR_Files_Name,2)
        idOTR = sprintf('%06i',10*i+4);
        fprintf('Processamento arquivo %s.\n',idOTR);
        BaseOTR(i).id = idOTR;
        BaseOTR(i).file = str_OTR_Files_Name(i);
        BaseOTR(i).mfc = paudio_filename( char(str_OTR_Files_Name(i)) );
    end
    
    BaseENC = struct;
    parfor i = 1:1:size(str_ENC_Files_Name,2)
        idENC = sprintf('%06i',10*i+5);
        fprintf('Processamento arquivo %s.\n',idENC);
        BaseENC(i).id = idENC;
        BaseENC(i).file = str_ENC_Files_Name(i);
        BaseENC(i).mfc = paudio_filename( char(str_ENC_Files_Name(i)) );
    end
    fprintf('Arquivos encontrados:\n');
    fprintf('\tPDR: %i arquivos\n',size(str_PDR_Files_Name,2));
    fprintf('\tQST: %i arquivos\n',size(str_QST_Files_Name,2));
    fprintf('\tGSM: %i arquivos\n',size(str_GSM_Files_Name,2));
    fprintf('\tENC: %i arquivos\n',size(str_ENC_Files_Name,2));
    fprintf('\tORT: %i arquivos\n',size(str_OTR_Files_Name,2));
    
    % Gerando Modelos GMM
    map_tau = 10.0;
    config = 'mwv';
    
    GMM_UBMPDR_PDR = struct;
    GMM_UBMPDR_QST = struct;
    GMM_UBMPDR_GSM = struct;
    GMM_UBMPDR_OTR = struct;
    GMM_UBMPDR_ENC = struct;
    
    GMM_UBMQST_PDR = struct;
    GMM_UBMQST_QST = struct;
    GMM_UBMQST_GSM = struct;
    GMM_UBMQST_OTR = struct;
    GMM_UBMQST_ENC = struct;
    
    GMM_UBMGSM_PDR = struct;
    GMM_UBMGSM_QST = struct;
    GMM_UBMGSM_GSM = struct;
    GMM_UBMGSM_OTR = struct;
    GMM_UBMGSM_ENC = struct;
    
    parfor i=1:(size(BasePDR,2)*~isempty(fieldnames(BasePDR)))
        GMM_UBMPDR_PDR(i).gmm_model = mapAdapt({BasePDR(i).mfc}, ubmPDR, map_tau, config);
    end
    parfor i=1:(size(BaseQST,2)*~isempty(fieldnames(BaseQST)))
        GMM_UBMPDR_QST(i).gmm_model = mapAdapt({BaseQST(i).mfc}, ubmPDR, map_tau, config);
    end
    parfor i=1:(size(BaseGSM,2)*~isempty(fieldnames(BaseGSM)))
        GMM_UBMPDR_GSM(i).gmm_model = mapAdapt({BaseGSM(i).mfc}, ubmPDR, map_tau, config);
    end
    parfor i=1:(size(BaseOTR,2)*~isempty(fieldnames(BaseOTR)))
        GMM_UBMPDR_OTR(i).gmm_model = mapAdapt({BaseOTR(i).mfc}, ubmPDR, map_tau, config);
    end
    parfor i=1:(size(BaseOTR,2)*~isempty(fieldnames(BaseOTR)))
        GMM_UBMPDR_ENC(i).gmm_model = mapAdapt({BaseENC(i).mfc}, ubmPDR, map_tau, config);
    end
    
    parfor i=1:(size(BasePDR,2)*~isempty(fieldnames(BasePDR)))
        GMM_UBMQST_PDR(i).gmm_model = mapAdapt({BasePDR(i).mfc}, ubmQST, map_tau, config);
    end
    parfor i=1:(size(BaseQST,2)*~isempty(fieldnames(BaseQST)))
        GMM_UBMQST_QST(i).gmm_model = mapAdapt({BaseQST(i).mfc}, ubmQST, map_tau, config);
    end
    parfor i=1:(size(BaseGSM,2)*~isempty(fieldnames(BaseGSM)))
        GMM_UBMQST_GSM(i).gmm_model = mapAdapt({BaseGSM(i).mfc}, ubmQST, map_tau, config);
    end
    parfor i=1:(size(BaseOTR,2)*~isempty(fieldnames(BaseOTR)))
        GMM_UBMQST_OTR(i).gmm_model = mapAdapt({BaseOTR(i).mfc}, ubmQST, map_tau, config);
    end
    parfor i=1:(size(BaseOTR,2)*~isempty(fieldnames(BaseOTR)))
        GMM_UBMQST_ENC(i).gmm_model = mapAdapt({BaseENC(i).mfc}, ubmQST, map_tau, config);
    end
    
    parfor i=1:(size(BasePDR,2)*~isempty(fieldnames(BasePDR)))
        GMM_UBMGSM_PDR(i).gmm_model = mapAdapt({BasePDR(i).mfc}, ubmGSM, map_tau, config);
    end
    parfor i=1:(size(BaseQST,2)*~isempty(fieldnames(BaseQST)))
        GMM_UBMGSM_QST(i).gmm_model = mapAdapt({BaseQST(i).mfc}, ubmGSM, map_tau, config);
    end
    parfor i=1:(size(BaseGSM,2)*~isempty(fieldnames(BaseGSM)))
        GMM_UBMGSM_GSM(i).gmm_model = mapAdapt({BaseGSM(i).mfc}, ubmGSM, map_tau, config);
    end
    parfor i=1:(size(BaseOTR,2)*~isempty(fieldnames(BaseOTR)))
        GMM_UBMGSM_OTR(i).gmm_model = mapAdapt({BaseOTR(i).mfc}, ubmGSM, map_tau, config);
    end
    parfor i=1:(size(BaseOTR,2)*~isempty(fieldnames(BaseOTR)))
        GMM_UBMGSM_ENC(i).gmm_model = mapAdapt({BaseENC(i).mfc}, ubmGSM, map_tau, config);
    end
    % Salva Base .mat
    save(GMMUBM_FileData, 'GMM*', 'Base*','-v7.3');
end
mFileName = split(mfilename('fullpath'),'/');
fprintf('Fim da etapa %s.\n',mFileName{end});
