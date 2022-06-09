# sigioBAM

A seguir serão apresentados os passos para obtenção, instalação e uso do sigioBAM, um pré-requisito para o uso do pyBAM.

## Obtenção e Instalação

O pyBAM depende da biblioteca sigioBAM, que deve ser instalada no ambiente para que o Python possa acessá-la.

## Instação da biblioteca sigioBAM

Para obter e instalar o sigioBAM, siga os passos a seguir:

### Obtenção

=== "Comando"

    ```bash linenums="1"
    svn export https://svn.cptec.inpe.br/slib/trunk/sharedLibs/sigioBAM
    ```

### Compilação

=== "Comando"

    ```bash linenums="1"
    cd sigioBAM 
    ./autogen.sh 
    ./configure --prefix=/opt/sigioBAM make make install
    ```

**Obs.:** Caso não seja root do sistema, instale a biblioteca na pasta pessoal e prossiga para o próximo passo.

### Configuração

É necessário incluir o caminho de instalação do sigioBAM no path do sistema para que o Python possa acessar a biblioteca. Então é necessário criar uma váriável de ambiente e exportá-la. Se você tiver acesso root, edite o arquivo `/etc/bash.bashrc`, caso contrário edite o arquivo `$HOME/.bashrc`.

Em qualquer um dos arquivos `/etc/bash.bashrc` ou `$HOME/.bashrc`, inclua as seguintes linhas:

=== "Comando"

    ```bash linenums="1"
    export SIGIOBAM=/opt/sigioBAM
    export LD_LIBRARY_PATH=/${SIGIOBAM}/lib:${LD_LIBRARY_PATH}
    ```

**Obs.:** é importante a criação da variável `SIGIOBAM` pois a biblioteca pyBAM irá procurar por esta variável durante a instalação do pacote.
