# Arquivos descritores para uso com o pyBAM

Os arquivos listados neste branch são exemplos de arquivos do tipo .dir. para as análises e previsões espectrais do modelo BAM. Estes arquivos são escritos pelo modelo no diretório dataout e acompanham as previsões espectrais do modelo. Estes arquivos são necessários para uso com o pyBAM, a fim de que seja possível ler os arquivos espectrais.

## Arquivos

* `GANL.dun.TQ0299L064`: para uso com a análise espctral do modelo (contém apenas as variáveis de análise escritas pelo GSI em coordenada vertical híbrida); 
* `BAM.dir.06`: para uso com as previsões espectrais do modelo (contém as variáveis diagnósticas e prognósticas do modelo, espectrais e em ponto de grade escritas pelo modelo em coordenada vertical híbrida);
* `GFCTCPT20150501062015050112F.dir.TQ0299L064`: o mesmo que `BAM.dir.06`, mas com nome diferente.

*Obs.:* o pyBAM espera que os respectivos arquivos espectrais possuam os nomes correspondentes aos seus descritores. 

*Exemplo:* 

* `GANL.dun.TQ0299L064` e `GANL.unf.TQ0299L064` (quando o arquivo de ańalise for o arquivo escrito pelo GSI, ie., BAM.anl;
* `GFCTCPT20150501062015050112F.dir.TQ0299L064` e `GFCTCPT20150501062015050112F.fct.TQ0299L064`.
