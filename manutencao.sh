#!/bin/bash
# SO_HIDE_DEBUG=1                   ## Uncomment this line to hide all @DEBUG statements
# SO_HIDE_COLOURS=1                 ## Uncomment this line to disable all escape colouring
. so_utils.sh                       ## This is required to activate the macros so_success, so_error, and so_debug

#####################################################################################
## ISCTE-IUL: Trabalho prático de Sistemas Operativos 2024/2025, Enunciado Versão 1
##
## Aluno: Nº: aa000000   Nome: Luiz Silva
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

if [ ! -r "$paises" ]; then
  so_error S2.1 "Ficheiro não existe ou não tem permissões de leitura"
  exit 1
fi

# Se o ficheiro de estacionamentos não existir, crie-o vazio
if [ ! -r "$parque" ]; then
  > "$parque"
fi

linha_n=0
while IFS= read -r linha || [ -n "$linha" ]; do
  ((linha_n++))
  [ -z "$linha" ] && continue

  num_campos=$(echo "$linha" | awk -F: '{print NF}')

  # Extrai o código do país (campo 2) e remove espaços
  pais=$(echo "$linha" | cut -d: -f2)
  pais_s_esp=$(echo "$pais" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

  # Verifica se o país existe em paises.txt (formato: "PT###Portugal###<regex>")
  # Se não existir, emite erro e sai
  if ! grep -q "^${pais_s_esp}###" "$paises"; then
    so_error S2.1 "Código de país '$pais_s_esp' não existe em $paises"
    exit 1
  fi

  # Se o registro for incompleto (5 campos), só valida o país
  if [ "$num_campos" -eq 5 ]; then
    continue
  elif [ "$num_campos" -eq 6 ]; then
    # Registro completo: valida matrícula e ordem das datas.
    matricula=$(echo "$linha" | cut -d: -f1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    data_entrada=$(echo "$linha" | cut -d: -f5)
    data_saida=$(echo "$linha" | cut -d: -f6)

    # Extrai o regex correspondente ao país de paises.txt
    regex=$(grep "^${pais_s_esp}###" "$paises" | awk -F"###" '{print $3}')
    if [ -z "$regex" ]; then
      so_error S2.1 "Não foi possível obter o regex para o país '$pais_s_esp'"
      exit 1
    fi

    # Valida a matrícula usando o regex extraído
    if ! echo "$matricula" | grep -qE "$regex"; then
      so_error S2.1 "Matrícula inválida para o cód país de $pais_s_esp"
      exit 1
    fi

    # Valida que a data de saída seja maior que a data de entrada.
    data_entrada_corte=$(echo "$data_entrada" | sed 's/[-Th]//g')
    data_saida_corte=$(echo "$data_saida" | sed 's/[-Th]//g')
    if [ "$data_entrada_corte" -ge "$data_saida_corte" ]; then
      so_error S2.1 "Data de saída anterior ou igual à data de entrada"
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

while IFS= read -r linha || [ -n "$linha" ]; do
  [ -z "$linha" ] && continue
  
  num_campos=$(echo "$linha" | awk -F: '{print NF}')
  
  if [ "$num_campos" -eq 6 ]; then
    matricula=$(echo "$linha" | cut -d: -f1)
    pais=$(echo "$linha" | cut -d: -f2)
    catVeic=$(echo "$linha" | cut -d: -f3)
    nome=$(echo "$linha" | cut -d: -f4)
    data_entrada=$(echo "$linha" | cut -d: -f5)
    data_saida=$(echo "$linha" | cut -d: -f6)
    ano=$(echo "$data_saida" | cut -d'-' -f1)
    mes=$(echo "$data_saida" | cut -d'-' -f2)
    entrada_formatada=$(echo "$data_entrada" | sed 's/T/ /; s/h/:/')
    saida_formatada=$(echo "$data_saida" | sed 's/T/ /; s/h/:/')
    entrada_segundos=$(date -d "$entrada_formatada" +%s 2>/dev/null)
    saida_segundos=$(date -d "$saida_formatada" +%s 2>/dev/null)
    duracao=$(( (saida_segundos - entrada_segundos) / 60 ))
    
    if [ "$duracao" -le 0 ]; then
      so_error S2.2 "Data de saída anterior ou igual à data de entrada"
      exit 1
    fi
    
    arquivo="arquivo-$ano-$mes.park"
    if [ -e "$arquivo" ]; then
      if [ ! -w "$arquivo" ]; then
        so_error S2.2 "Diretoria local sem permissões para escrita"
        exit 1
      fi
    else
      dir=$(dirname "$arquivo")
      if [ ! -w "$dir" ]; then
        so_error S2.2 "Diretoria local sem permissões para escrita"
        exit 1
      fi
    fi
    echo "$linha:$duracao" >> "$arquivo"
  fi
done < "$parque"

if [ -r "$parque" ]; then
  awk -F: 'NF != 6' "$parque" > "$parque.tmp" && mv "$parque.tmp" "$parque"
fi

so_success S2.2

exit 0
