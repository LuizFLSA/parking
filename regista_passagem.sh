#!/bin/bash
# SO_HIDE_DEBUG=1                   ## Uncomment this line to hide all @DEBUG statements
# SO_HIDE_COLOURS=1                 ## Uncomment this line to disable all escape colouring
. so_utils.sh                       ## This is required to activate the macros so_success, so_error, and so_debug

#####################################################################################
## ISCTE-IUL: Trabalho prático de Sistemas Operativos 2024/2025, Enunciado Versão 1
##
## Aluno: Nº:a000000     Nome: Luiz da Silva
## Nome do Módulo: S1. Script: regista_passagem.sh
## Descrição/Explicação do Módulo: script quer será invocado quando uma viatura entra/sai do estacionamento.
## Recebe todos os dados por argumento, na chamada da linha de comandos.
##
##
#####################################################################################

## Este script é invocado quando uma viatura entra/sai do estacionamento Park-IUL. Este script recebe todos os dados por argumento, na chamada da linha de comandos, incluindo os <Matrícula:string>, <Código País:string>, <Categoria:char> e <Nome do Condutor:string>.

## S1.1. Valida os argumentos passados e os seus formatos:
## • Valida se os argumentos passados são em número suficiente (para os dois casos exemplificados), assim como se a formatação de cada argumento corresponde à especificação indicada. O argumento <Categoria> pode ter valores: L (correspondente a Ligeiros), P (correspondente a Pesados) ou M (correspondente a Motociclos);
## • A partir da indicação do argumento <Código País>, valida se o argumento <Matrícula> passada cumpre a especificação da correspondente <Regra Validação Matrícula>;
## • Valida se o argumento <Nome do Condutor> é o “primeiro + último” nomes de um utilizador atual do Tigre;
## • Em caso de qualquer erro das condições anteriores, dá so_error S1.1 <descrição do erro>, indicando o erro em questão, e termina. Caso contrário, dá so_success S1.1.

if [ ! -r "estacionamentos.txt" ]; then
  touch estacionamentos.txt 2>/dev/null
  if [ $? -ne 0 ]; then 
    so_error S1.1 "Ficheiro estacionamentos.txt não existe ou não tem permissões de leitura"
    exit 1
  fi
fi

if [ ! -r "_etc_passwd" ]; then
  so_error S1.1 "Ficheiro _etc_passwd não existe ou não tem permissões de leitura"
  exit 1
fi

if [ ! -r "paises.txt" ]; then
  so_error S1.1 "Ficheiro paises.txt não existe ou não tem permissões de leitura"
  exit 1
fi

if [ "$#" -ne 4 ] && [ "$#" -ne 1 ]; then
  so_error S1.1 "Número de argumentos é inválido"
  exit 1
fi

if [ "$#" -eq 4 ]; then
  matricula="$1"
  codPais="$2"
  catVeic="$3"
  nome="$4"
elif [ "$#" -eq 1 ]; then
  if [[ "$1" != */* ]]; then
    so_error S1.1 "Formato de entrada para saída inválido"
    exit 1
  fi
  codPais=$(echo "$1" | cut -d'/' -f1)
  matricula=$(echo "$1" | cut -d'/' -f2 | tr -d '"')
fi

matricula_nova=$(echo "$matricula" | sed 's/[ -]//g')

if [ "$#" -eq 4 ]; then
  if [ "$catVeic" != "L" ] && [ "$catVeic" != "P" ] && [ "$catVeic" != "M" ]; then
    so_error S1.1 "Categoria de veículo errada"
    exit 1
  fi
  if ! echo "$nome" | grep -q " "; then 
    so_error S1.1 "1p e 2o nome iválido" 
    exit 1
  fi
  if ! awk -F: '{print $5}' _etc_passwd | awk '{print $1, $NF}' | grep -q "$nome"; then
    so_error S1.1 "Nome do condutor '$nome' não corresponde a um utilizador atual do Tigre."
    exit 1
  fi
fi

case "$codPais" in
  PT)
    if ! echo "$matricula" | grep -qE "^[A-Z]{2}[ -]{0,1}[0-9]{2}[ -]{0,1}[A-Z]{2}$"; then
      so_error S1.1 "Matricula inválida para o código do país inserido (PT)"
      exit 1
    fi
    ;;
  ES)
    if ! echo "$matricula" | grep -qE "^[0-9]{4}[ -]{0,1}[B-Z]{3}$"; then
      so_error S1.1 "Matrícula inváida para o código do país inserido (ES)"
      exit 1
    fi
    ;;
  FR)
    if ! echo "$matricula" | grep -qE "^[A-Z]{2}[ -]{0,1}[0-9]{3}[ -]{0,1}[A-Z]{2}$"; then
      so_error S1.1 "Matrícula inváida para o código do país inserido (FR)"
      exit 1
    fi
    ;;
  UK)
    if ! echo "$matricula" | grep -qE "^[A-Z]{2}[0-9]{2}[ ]{0,1}[A-Z]{3}$"; then
      so_error S1.1 "Matrícula inváida para o código do país inserido (UK)"
      exit 1
    fi
    ;;
  *)
    so_error S1.1 "Código do país é inválido"
    exit 1
    ;;
esac
so_success S1.1

## S1.2. Valida os dados passados por argumento para o script com o estado da base de dados de estacionamentos especificada no ficheiro estacionamentos.txt:
## • Valida se, no caso de a invocação do script corresponder a uma entrada no parque de estacionamento, se ainda não existe nenhum registo desta viatura na base de dados;
## • Valida se, no caso de a invocação do script corresponder a uma saída do parque de estacionamento, se existe um registo desta viatura na base de dados;
## • Em caso de qualquer erro das condições anteriores, dá so_error S1.2 <descrição do erro>, indicando o erro em questão, e termina. Caso contrário, dá so_success S1.2.

if [ "$#" -eq 4 ]; then
  if grep -q "^${matricula_nova}:[^:]*:[^:]*:[^:]*:[^:]*$" estacionamentos.txt; then
    so_error S1.2 "O veículo já existe no ficheiro <estacionamentos.txt>"
    exit 1
  else
    so_success S1.2
  fi
elif [ "$#" -eq 1 ]; then
  if grep -q "^${matricula_nova}:[^:]*:[^:]*:[^:]*:[^:]*$" estacionamentos.txt; then
    so_success S1.2
  else
    so_error S1.2 "O veículo não está dentro do estacionamento"
    exit 1
  fi
fi

## S1.3. Atualiza a base de dados de estacionamentos especificada no ficheiro estacionamentos.txt:
## • Remova do argumento <Matrícula> passado todos os separadores (todos os caracteres que não sejam letras ou números) eventualmente especificados;
## • Especifique como data registada (de entrada ou de saída, conforme o caso) a data e hora do sistema Tigre;
## • No caso de um registo de entrada, crie um novo registo desta viatura na base de dados;
## • No caso de um registo de saída, atualize o registo desta viatura na base de dados, registando a data de saída;
## • Em caso de qualquer erro das condições anteriores, dá so_error S1.3 <descrição do erro>, indicando o erro em questão, e termina. Caso contrário, dá so_success S1.3.

data=$(date +"%Y-%m-%dT%Hh%M")
echo "$data"

if [ "$#" -eq 4 ]; then
  # Entrada
  if grep -q "^${matricula_nova}:" estacionamentos.txt; then
    so_error S1.3 "veículo já existe no ficheiro <estacionamentos.txt>"
    exit 1
  else
    if [ ! -w "estacionamentos.txt" ]; then
      so_error S1.3 "Ficheiro estacionamentos.txt sem permissões para escrita"
      exit 1
    fi
    echo "${matricula_nova}:${codPais}:${catVeic}:${nome}:${data}" >> estacionamentos.txt
    so_success S1.3
  fi
else
  # Saída
  if grep -q "^${matricula_nova}:" estacionamentos.txt; then
    if [ ! -w "estacionamentos.txt" ]; then
      so_error S1.3 "Ficheiro estacionamentos.txt sem permissões para escrita"
      exit 1
    fi
    sed -i "/^${matricula_nova}:[^:]*:[^:]*:[^:]*:[^:]*$/s/$/:${data}/" estacionamentos.txt
    so_success S1.3
  else
    so_error S1.3 "O veículo não está dentro do estacionamento"
    exit 1
  fi
fi

## S1.4. Lista todos os estacionamentos registados, mas ordenados por saldo:
## • O script deve criar um ficheiro chamado estacionamentos-ordenados-hora.txt igual ao que está no ficheiro estacionamentos.txt, com a mesma formatação, mas com os registos ordenados por ordem crescente da hora (e não da data) de entrada das viaturas.
## • Em caso de qualquer erro das condições anteriores, dá so_error S1.4 <descrição do erro>, indicando o erro em questão, e termina. Caso contrário, dá so_success S1.4.

sort -t':' -k5.12,5.13n -k5.15,5.16n estacionamentos.txt > estacionamentos-ordenados-hora.txt
if [ $? -eq 0 ]; then
  so_success S1.4
else
  so_error S1.4 "Erro ao guardar e/ou ordenar no novo ficheiro"
  exit 1
fi

exit 0
