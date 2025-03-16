#!/bin/bash
# SO_HIDE_DEBUG=1                   ## Uncomment this line to hide all @DEBUG statements
# SO_HIDE_COLOURS=1                 ## Uncomment this line to disable all escape colouring
. so_utils.sh                       ## This is required to activate the macros so_success, so_error, and so_debug

#####################################################################################
## ISCTE-IUL: Trabalho prático de Sistemas Operativos 2024/2025, Enunciado Versão 1
##
## Aluno: Nº:       Nome:
## Nome do Módulo: S2. Script: manutencao.sh
## Descrição/Explicação do Módulo:
##
##
#####################################################################################

## Este script não recebe nenhum argumento, e permite realizar a manutenção dos registos de estacionamento. 

## S2.1. Validações do script:
## O script valida se, no ficheiro estacionamentos.txt:
## • Todos os registos referem códigos de países existentes no ficheiro paises.txt;
## • Todas as matrículas registadas correspondem à especificação de formato dos países correspondentes;
## • Todos os registos têm uma data de saída superior à data de entrada;
## • Em caso de qualquer erro das condições anteriores, dá so_error S2.1 <descrição do erro>, indicando o erro em questão, e termina. Caso contrário, dá so_success S2.1.

parque="estacionamentos.txt"
paises="paises.txt"

linha_n=0
while IFS= read -r linha; do
  ((linha_n++))
  
  [ -z "$linha" ] && continue
  
  matricula=$(echo "$linha" | cut -d: -f1)
  pais=$(echo "$linha" | cut -d: -f2)
  data_entrada=$(echo "$linha" | cut -d: -f5)
  data_saida=$(echo "$linha" | cut -d: -f6)

  if grep -q "^$pais:" "$paises"; then
    #so_error S2.1 "Código do pais não existe em paises.txt"
    #exit 1
    so_success S2.1
  fi
  
  # 2. Validar formato da matrícula baseado no código do país
  if [ "$pais" = "PT" ] && ! echo "$matricula" | grep -qE "^[A-Z]{2}[ -]{0,1}[0-9]{2}[ -]{0,1}[A-Z]{2}$"; then
    so_error S2.1 "Matrícula inválida para o cód país de PT"
    exit 1
  fi
 
  if [ "$pais" = "ES" ] && ! echo "$matricula" | grep -qE "^[0-9]{4}[ -]{0,1}[B-Z]{3}$"; then
    so_error S2.1 "Matrícula inválida para o cód país de ES"
    exit 1
  fi
  
  if [ "$pais" = "FR" ] && ! echo "$matricula" | grep -qE "^[A-Z]{2}[ -]{0,1}[0-9]{3}[ -]{0,1}[A-Z]{2}$"; then
    so_error S2.1 "Matrícula inválida para o cód país de FR"
    exit 1 
  fi

  if [ "$pais" = "UK" ] && ! echo "$matricula" | grep -qE "^[A-Z]{2}[0-9]{2}[ ]{0,1}[A-Z]{3}$"; then
    so_error S2.1 "Matrícula inválida para o cód país de UK"
    exit 1
  fi
  
  if [ -n "$data_saida" ]; then
    data_entrada_corte=$(echo "$data_entrada" | sed 's/[-Th]//g')
    data_saida_corte=$(echo "$data_saida" | sed 's/[-Th]//g')

    if [ "$data_entrada_corte" -gt "$data_saida_corte" ]; then
      so_error S2.1 "Data de saída anterior à de entrada"
      exit 1
    fi
  fi
    
done < "$parque"

so_success S2.1

## S2.2. Processamento:
## • O script move, do ficheiro estacionamentos.txt, todos os registos que estejam completos (com registo de entrada e registo de saída), mantendo o formato do ficheiro original, para ficheiros separados com o nome arquivo-<Ano>-<Mês>.park, com todos os registos agrupados pelo ano e mês indicados pelo nome do ficheiro. Ou seja, os registos são removidos do ficheiro estacionamentos.txt e acrescentados ao correspondente ficheiro arquivo-<Ano>-<Mês>.park, sendo que o ano e mês em questão são os do campo <DataSaída>. 
## • Quando acrescentar o registo ao ficheiro arquivo-<Ano>-<Mês>.park, este script acrescenta um campo <TempoParkMinutos> no final do registo, que corresponde ao tempo, em minutos, que durou esse registo de estacionamento (correspondente à diferença em minutos entre os dois campos anteriores).
## • Em caso de qualquer erro das condições anteriores, dá so_error S2.2 <descrição do erro>, indicando o erro em questão, e termina. Caso contrário, dá so_success S2.2.
## • O registo em cada ficheiro arquivo-<Ano>-<Mês>.park, tem então o formato:
## <Matrícula:string>:<Código País:string>:<Categoria:char>:<Nome do Condutor:string>: <DataEntrada:AAAA-MM-DDTHHhmm>:<DataSaída:AAAA-MM-DDTHHhmm>:<TempoParkMinutos:int>
## • Exemplo de um ficheiro arquivo-<Ano>-<Mês>.park, para janeiro de 2025:


linhas_para_remover=""
while IFS= read -r linha; do
  [ -z "$linha" ] && continue
  
  num_campos=$(echo "$linha" | awk -F: '{print NF}')
  
  if [ "$num_campos" -eq 6 ]; then
    matricula=$(echo "$linha" | cut -d: -f1)
    data_entrada=$(echo "$linha" | cut -d: -f5)
    data_saida=$(echo "$linha" | cut -d: -f6)
    ano=$(echo "$data_saida" | cut -d'-' -f1)
    mes=$(echo "$data_saida" | cut -d'-' -f2)
    entrada_ano=$(echo "$data_entrada" | cut -d'-' -f1)
    entrada_mes=$(echo "$data_entrada" | cut -d'-' -f2)
    entrada_dia=$(echo "$data_entrada" | cut -d'-' -f3 | cut -dT -f1)
    entrada_hora=$(echo "$data_entrada" | cut -dT -f2 | cut -dh -f1)
    entrada_min=$(echo "$data_entrada" | cut -dh -f2)
    saida_ano=$(echo "$data_saida" | cut -d'-' -f1)
    saida_mes=$(echo "$data_saida" | cut -d'-' -f2)
    saida_dia=$(echo "$data_saida" | cut -d'-' -f3 | cut -dT -f1)
    saida_hora=$(echo "$data_saida" | cut -dT -f2 | cut -dh -f1)
    saida_min=$(echo "$data_saida" | cut -dh -f2)
    
    entrada_formatada="$entrada_ano-$entrada_mes-$entrada_dia $entrada_hora:$entrada_min"
    saida_formatada="$saida_ano-$saida_mes-$saida_dia $saida_hora:$saida_min"
    
    entrada_segundos=$(date -d "$entrada_formatada" +%s) 
    saida_segundos=$(date -d "$saida_formatada" +%s)
    
    duracao=$(( (saida_segundos - entrada_segundos) / 60 ))
    
    if [ "$duracao" -le 0 ]; then
      so_error S2.2 "Data de saída anterior ou igual à data de entrada"
      exit 1
    fi
    
    arquivo="arquivo-$ano-$mes.park"
    
    echo "$linha:$duracao" >> "$arquivo"

    if [ -z "$linhas_para_remover" ]; then
      linhas_para_remover="^$matricula:"
    else
      linhas_para_remover="$linhas_para_remover\\|^$matricula:"
    fi
  fi
done < "$parque"

if [ -n "$linhas_para_remover" ]; then
  sed -i "/$linhas_para_remover/d" "$parque"
fi

so_success S2.2