# Rotina unificada para comparação de locutores.

Utiliza as técnicas GMM-UBM, i-vector e ~~~fuzzy i-vector~~~.

__autor:__ Adelino Pinheiro Silva\
__email:__ adelinocpp@yahoo.com

## Informações: 

1. Testado no MATLAB R2017 64-bits para linux.

2. Necessita da instalação do sox, que pode ser realizada via comando:

```console
$ sudo apt install sox
```
## Utilização:

Crie um diretório para comparação com o nome que desejar, por exemplo, "NOME_DIRETORIO". Efite utilizar espeços e caracteres especiais no nome dos arquivos e diretórios.

```
../NOME_DIRETORIO
    /- R00_Executa_Toda_CFL_v1.m
    /- R01_Calcula_fi_vectors_v0.m
    ...
    / - S00_Space_To_Underscore.sh
```

Para executar a comparação são necessários arquivos com funçẽos auxiliares (parete do MSToolkit e voicebox) e arquivos de dados, como modelo UBM, matrix de variabildaide de locutores, modelos fuzzy de SNR, etc...

Tais dados estão noa rquivo config.rar neste [link do Amazon Drive](https://www.amazon.com/clouddrive/share/lkD4eK8rLhY3vXXQX3Rg1LKLo6hQkuArhJM6zr0nDcc) e a senha para descompatar é "SPAV_ICMG_CFL#matlab@4743_adelinocpp".

Descompacte o arquivo config.zip no mesmo diretŕorio de NOME_DIRETORIO, ficando
```
../config
../NOME_DIRETORIO
    /- R00_Executa_Toda_CFL_v1.m
    /- R01_Calcula_fi_vectors_v0.m
    ...
    / - S00_Space_To_Underscore.sh
```

Prepare os arquivos para comparação, renomeando o arquivo com material padrão adicionando o sufixo _PDR (antes da extensão) e o do material questionado com o sufixo _QST. Por exemplo:

* "NOMEARQUIVO_PDR.wav" (arquivo com material padrão)
* "NOMEARQUIVO_QST.wav" (arquivo com material questionado)

Coloque os arquivos no diretório de trabalho NOME_DIRETORIO. 

__Nota:__ Não se preocupe com a codificação, número de canais, frequencia de amostragem ou qualquer outra configuração do arquivo de áudio, basta o arquivo ter a extensão de um tipo de áudio listado na [wikipedia](https://en.wikipedia.org/wiki/Audio_file_format)

Abra o matlab e execute o arquivo "R00_Executa_Toda_CFL_v1.m".

Aguarde o fim dos cálculos e confira os resultados no diretório "data_dir" criado no NOME_DIRETORIO.

## Interpretando resultados...
