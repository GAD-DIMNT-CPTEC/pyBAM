# pyBAM - Python Interface to BAM

O pyBAM é uma interface projetada para acessar os arquivos espectrais (não pós-processados) do modelo BAM na sua coordenada vertical natural (sigma ou híbrida) diretamente no Python.

## Pré-requisitos

### Instalação da biblioteca sigioBAM

* Obtenção do pacote:

```bash
svn export https://svn.cptec.inpe.br/slib/trunk/sharedLibs/sigioBAM
```

* Compilação:

```bash
cd sigioBAM
./autogen.sh
./configure --prefix=/opt/sigioBAM
make
make install
```

* Configuração:

Adicione as seguintes linhas ao arquivo `$HOME/.bashrc`:

```bash
export SIGIOBAM=/opt/sigioBAM
export LD_LIBRARY_PATH=/${SIGIOBAM}/lib:${LD_LIBRARY_PATH}
```

### Criação de um ambiente Python para o pyBAM:

Considerando a distribuição Anaconda instalada, utilize o gerenciador de pacotes `conda` para criar o ambiente e instalar os seguintes pacotes:

```bash
conda create -n pyBAM python=3.7.6
```

```bash
conda activate pyBAM
conda install numpy
conda install -c conda-forge xarray dask netCDF4 bottleneck
conda install matplotlib
conda install -c conda-forge cartopy
```

Se preferir, ao invés de instalar os pacotes individualmente, utilize o arquivo `environment.yml`:

```bash
conda env create -f environment.yml
```

### Instalação do pyBAM

Realize esta etapa dentro do ambiente `pyBAM` criado na etapa anterior. Para ativar este ambiente, utilize o comando a seguir:

```bash
conda activate pyBAM
```

* Obtenção do pacote:

```bash
svn export https://svn.cptec.inpe.br/pybam/trunk/pyBAM
```

* Compilação e instalação:

```bash
cd pyBAM
python setup.py build
python setup.py install
```

## Instruções rápidas de uso

Dentro do ambiente `pyBAM`, abra uma instância do Python e importe as biblioteca do `pyBAM` e `matplotlib`:

```bash
$ python

Python 3.7.6 (default, Jan  8 2020, 19:59:22) 
[GCC 7.3.0] :: Anaconda, Inc. on linux
Type "help", "copyright", "credits" or "license" for more information.
>>>
>>> import pyBAM as pb
>>> from matplotlib import pyplot as plt
```

No exemplo, utiliza-se o arquivo `GFCTCPT20191115002019111500F.dic.TQ0299L064` que contém as definições do cabeçalho do arquivo de análise (icn) correspondente. Para abrí-lo com o `pyBAM`, utilize o comando a seguir:

```bash
>>> bFile = pb.openBAM('GFCTCPT20191115002019111500F.dic.TQ0299L064')
```

Para verificar quais são os métodos associados ao objeto `bFile` criado, digite `bFile.` e pressione a tecla `TAB`.

Para plotar a figura com o campo de temperatura virtual no primeiro nível do modelo, utilize os comandos a seguir:

```bash
>>> bFile.plotField('VIRTUAL TEMPERATURE', zlevel=1)
>>> plt.show()
```

Mais informações e exemplos podem ser encontradas na Wiki do projeto em https://projetos.cptec.inpe.br/projects/pybam/wiki
