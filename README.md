Rotina unificada para comparação de locutores.

Utiliza as técnicas GMM-UBM, i-vefor e fuzzy i-vector.

autor: Adelino Pinheiro Silva
email: adelinocpp@yahoo.com

Informações: 
Testado no MATLAB R2017 64-bits para linux.

Necessita da instalação do sox, que pode ser realizada via comando:

$ sudo apt install sox

Utilização:

Crie um diretório para comparação com o nome que desejar, por exemplo, "NOME_DIRETORIO". Efite utilizar espeços e caracteres especiais no nome dos arquivos e diretórios.

../NOME_DIRETORIO
    /- R00_Executa_Toda_CFL_v1.m
    /- R01_Calcula_fi_vectors_v0.m
    ...
    / - S00_Space_To_Underscore.sh

descompacte o arquivo config.zip no mesmo diretŕorio de NOME_DIRETORIO, ficando
../config
../NOME_DIRETORIO
    /- R00_Executa_Toda_CFL_v1.m
    /- R01_Calcula_fi_vectors_v0.m
    ...
    / - S00_Space_To_Underscore.sh

Prepare os arquivos para comparação, renomeando o arquivo com material padrão adicionando o sufixo _PDR (antes da extensão) e o do material questionado com o sufixo _QST. Por exemplo:

"NOMEARQUIVO_PDR.wav" (arquivo com material padrão)
"NOMEARQUIVO_QST.wav" (arquivo com material questionado)

Coloque os arquivos no diretório de trabalho NOME_DIRETORIO. Não se preocupe com a codificação, numero de canais, frequencia de amostragem ou qualquer outra configuração do arquivo de áudio, basta o arquivo ter a extensão de um tipo de áudio.

Abra o matlab e execute o arquivo "R00_Executa_Toda_CFL_v1.m".

Aguarde o fim dos cálculos e confira os resultados no diretório "data_dir" criado no NOME_DIRETORIO.

Interpretando resultados...
