# pyBAM

A seguir serão apresentados os passos para obtenção, instalação e uso do pyBAM.

No passo anterior foi instalada a dependência para o uso da interface Python do modelo BAM, nesse passo serão apresentados os procedimentos de obtenção e instalação do pyBAM. Embora não seja um requerimento, é uma boa prática trabalhar com ambientes no Python. Para isso, considerando o uso da distribuição Anaconda, crie um ambiente para a instalação do pyBAM e das suas dependências (numpy, xarray, matplotlib e cartopy). Para criar um ambiente no Anaconda, siga os passos a seguir.

**Obs.:** Para evitar problemas relacionados com a versão dos pacotes a serem instalados, utilize exatamente as versões indicadas do Python.

=== "Comando"

    ```bash linenums="1"
    conda create -n pyBAM python=3.7.6
    ```

Ative o ambiente criado e instale as dependências do pyBAM:

=== "Comando"

    ```bash linenums="1"
    conda activate pyBAM
    conda install numpy
    conda install -c conda-forge xarray dask netCDF4 bottleneck
    conda install matplotlib
    conda install -c conda-forge cartopy
    ```

Para obter e instalar o pyBAM, siga os passos a seguir. Neste passo, você deve estar com o ambiente pyBAM ativado (caso contrário, o pyBAM será instalado fora do ambiente que contém as dependências necessárias). Escolha um local adequado (eg., `$HOME/Downloads`) e baixe o pacote do pyBAM a partir do repositório:

### Obtenção

=== "Comando"

    ```bash linenums="1"
    svn export https://svn.cptec.inpe.br/pybam/trunk/pyBAM
    ```

### Compilação e instalação

=== "Comando"

    ```bash linenums="1"
    cd pyBAM 
    python setup.py build 
    python setup.py install
    ```
