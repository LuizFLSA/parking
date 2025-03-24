#!/bin/bash
# SO_HIDE_DEBUG=1                   ## Uncomment this line to hide all @DEBUG statements
# SO_HIDE_COLOURS=1                 ## Uncomment this line to disable all escape colouring
. so_utils.sh                       ## This is required to activate the macros so_success, so_error, and so_debug

#####################################################################################
## ISCTE-IUL: Trabalho prático de Sistemas Operativos 2024/2025, Enunciado Versão 1
##
## Aluno: Nº: a000000      Nome: Luiz Silva
## Nome do Módulo: S3. Script: stats.sh
## Descrição/Explicação do Módulo:
##
##
#####################################################################################

## Este script obtém informações sobre o sistema Park-IUL, afixando os resultados das estatísticas pedidas no formato standard HTML no Standard Output e no ficheiro stats.html. Cada invocação deste script apaga e cria de novo o ficheiro stats.html, e poderá resultar em uma ou várias estatísticas a serem produzidas, todas elas deverão ser guardadas no mesmo ficheiro stats.html, pela ordem que foram especificadas pelos argumentos do script.

## S3.1. Validações:
## O script valida se, na diretoria atual, existe algum ficheiro com o nome arquivo-<Ano>-<Mês>.park, gerado pelo Script: manutencao.sh. Se não existirem ou não puderem ser lidos, dá so_error S3.1 <descrição do erro>, indicando o erro em questão, e termina. Caso contrário, dá so_success S3.1.

paises="paises.txt"
parque="estacionamentos.txt"
stats_html="stats.html"

if [ ! -r "$paises" ]; then
  so_error S3.1 "Não tem permissões de leitura do paises.txt"
  exit 1
fi 

if [ ! -r "$parque" ]; then 
  so_error S3.1 "Não tem permissões de leitura do estacionamentos.txt"
  exit 1
fi 

existe_arquivo=false 
tem_permissao=true
for arquivo in arquivo-*-*.park; do
  if [ -e "$arquivo" ]; then
    if [ -r "$arquivo" ]; then 
      existe_arquivo=true
    else
      tem_permissao=false
      break
    fi
  fi
done 

if [ "$existe_arquivo" = false ]; then
  so_error S3.1 "Não existe ficheiro(s) arquivo-<ano>-<mes>.park"
  exit 1 
fi

if [ "$tem_permissao" = false ]; then
  so_error S3.1 "Não tem permissões"
  exit 1
fi

for n_args in "$@"; do
  if ! [[ "$n_args" =~ ^[1-7]$ ]]; then
    so_error S3.1 "Número de args inválido"
    exit 1 
  fi 
done 

so_success S3.1 

{
  data=$(date "+%Y-%m-%d")
  hora=$(date "+%H:%M:%S")

  # Initialize HTML file
  echo "<html><head><meta charset=\"UTF-8\"><title>Park-IUL: Estatísticas de estacionamento</title></head>"
  echo "<body><h1>Lista atualizada em $data $hora</h1>"

  gerar_stats=""
  if [ $# -eq 0 ]; then 
    gerar_stats="1 2 3 4 5 6 7"
  else 
    gerar_stats="$@"
  fi

  for stat_n in $gerar_stats; do 
    
    #S3.2.1 - veiculos no parque
    if [ "$stat_n" = "1" ]; then
      echo "<h2>Stats1:</h2>"
      echo "<ul>"
      
      # veiculos no parque
      if [ -r "$parque" ]; then
        grep -v ":[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}h[0-9]\{2\}$" "$parque" | sort -t: -k4 |
        while IFS=: read -r matricula pais categoria nome entrada saida; do
          echo "<li><b>Matrícula:</b> $matricula <b>Condutor:</b> $nome</li>"
        done
      fi
      
      echo "</ul>"
    fi
    
    #S3.2.2 - top 3 veiculos que estiveram estacionados + tempo
    if [ "$stat_n" = "2" ]; then
      echo "<h2>Stats2:</h2>"
      echo "<ul>"
      
      # ficheiro tmp para total de veiculos 
      temp_veiculos="temp_veiculos.txt"
      > "$temp_veiculos"
      
      # correr ficheiros arquivo
      for arquivo in arquivo-*-*.park; do
        if [ -r "$arquivo" ]; then
          while IFS=: read -r matricula pais categoria nome entrada saida tempo; do
            if [[ -n "$tempo" ]]; then
              # verificar se o veic existe no ficheiro tmp 
              if grep -q "^$matricula:" "$temp_veiculos" 2>/dev/null; then
                # Update time
                tempo_atual=$(grep "^$matricula:" "$temp_veiculos" | cut -d: -f2)
                tempo_novo=$((tempo_atual + tempo))
                sed -i "s/^$matricula:$tempo_atual/$matricula:$tempo_novo/" "$temp_veiculos"
              else
                # Add veic
                echo "$matricula:$tempo" >> "$temp_veiculos"
              fi
            fi
          done < "$arquivo"
        fi
      done
      
      # Sort and get top 3
      sort -t: -k2 -nr "$temp_veiculos" | head -3 |
      while IFS=: read -r matricula tempo; do
        echo "<li><b>Matrícula:</b> $matricula <b>Tempo estacionado:</b> $tempo</li>"
      done
      
      rm -f "$temp_veiculos"
      echo "</ul>"
    fi

    # S3.2.3
    if [ "$stat_n" = "3" ]; then
      echo "<h2>Stats3:</h2>"
      echo "<ul>"
      
      temp_paises="temp_paises.txt"
      > "$temp_paises"
      
      for arquivo in arquivo-*-*.park; do
        if [ -r "$arquivo" ]; then
          while IFS=: read -r matricula pais categoria nome entrada saida tempo; do
            # Skip motorcycles and only process if time is available
            if [[ "$categoria" != "M" && -n "$tempo" ]]; then
              # Get country name from paises.txt
              nome_pais=$(grep "^$pais:" "$paises" | cut -d: -f2)
              if [[ -z "$nome_pais" ]]; then
                nome_pais="$pais"  # Fallback if not found
              fi
              
        
              if grep -q "^$nome_pais:" "$temp_paises" 2>/dev/null; then
                # Update time
                tempo_atual=$(grep "^$nome_pais:" "$temp_paises" | cut -d: -f2)
                tempo_novo=$((tempo_atual + tempo))
                sed -i "s/^$nome_pais:$tempo_atual/$nome_pais:$tempo_novo/" "$temp_paises"
              else
                # Add novo pais 
                echo "$nome_pais:$tempo" >> "$temp_paises"
              fi
            fi
          done < "$arquivo"
        fi
      done
      
      # Sort e out
      sort -t: -k1 "$temp_paises" |
      while IFS=: read -r nome_pais tempo; do
        echo "<li><b>País:</b> $nome_pais <b>Total tempo estacionado:</b> $tempo</li>"
      done
      
      rm -f "$temp_paises"
      echo "</ul>"
    fi

    # S3.2.4
    if [ "$stat_n" = "4" ]; then
      echo "<h2>Stats4:</h2>"
      echo "<ul>"
      
      temp_entradas="temp_entradas.txt"
      > "$temp_entradas"
      
      # corre veiculos no parque
      if [ -r "$parque" ]; then
        while IFS=: read -r matricula pais categoria nome entrada saida; do
          if [[ -n "$entrada" ]]; then
            echo "$matricula:$pais:$entrada" >> "$temp_entradas"
          fi
        done < "$parque"
      fi
      
      for arquivo in arquivo-*-*.park; do
        if [ -r "$arquivo" ]; then
          while IFS=: read -r matricula pais categoria nome entrada saida tempo; do
            if [[ -n "$entrada" ]]; then
              echo "$matricula:$pais:$entrada" >> "$temp_entradas"
            fi
          done < "$arquivo"
        fi
      done
      
      # Sort descendente e top 3
      sort -t: -k3 "$temp_entradas" | head -3 |
      while IFS=: read -r matricula pais data_entrada; do
        echo "<li><b>Matrícula:</b> $matricula <b>País:</b> $pais <b>Data Entrada:</b> $data_entrada</li>"
      done
      
      rm -f "$temp_entradas"
      echo "</ul>"
    fi

    # S3.2.5
    if [ "$stat_n" = "5" ]; then
      echo "<h2>Stats5:</h2>"
      echo "<ul>"
      
      temp_condutores="temp_condutores.txt"
      > "$temp_condutores"

      for arquivo in arquivo-*-*.park; do
        if [ -r "$arquivo" ]; then
          while IFS=: read -r matricula pais categoria nome entrada saida tempo; do
        
            if [[ -n "$tempo" && -n "$nome" ]]; then
              # verificar se nome existe no ficheiro
              if grep -q "^$nome:" "$temp_condutores" 2>/dev/null; then
                # Update time
                tempo_atual=$(grep "^$nome:" "$temp_condutores" | cut -d: -f2)
                tempo_novo=$((tempo_atual + tempo))
                sed -i "s/^$nome:$tempo_atual/$nome:$tempo_novo/" "$temp_condutores"
              else
                # Add new driver
                echo "$nome:$tempo" >> "$temp_condutores"
              fi
            fi
          done < "$arquivo"
        fi
      done
      
      # out
      while IFS=: read -r condutor tempo_total; do
        # Calcular dias, horas e mins
        dias=$((tempo_total / 1440))
        resto=$((tempo_total % 1440))
        horas=$((resto / 60))
        minutos=$((resto % 60))
        
        echo "<li><b>Condutor:</b> $condutor <b>Tempo total:</b> $dias dia(s), $horas hora(s) e $minutos minuto(s)</li>"
      done < "$temp_condutores"
      
      rm -f "$temp_condutores"
      echo "</ul>"
    fi

    # S3.2.6
    if [ "$stat_n" = "6" ]; then
      echo "<h2>Stats6:</h2>"
      echo "<ul>"
      
      temp_paises="temp_paises.txt"
      temp_matriculas="temp_matriculas.txt"
      > "$temp_paises"
      > "$temp_matriculas"
      
      for arquivo in arquivo-*-*.park; do
        if [ -r "$arquivo" ]; then
          while IFS=: read -r matricula pais categoria nome entrada saida tempo; do
        
            if [[ -n "$tempo" ]]; then
            
              nome_pais=$(grep "^$pais:" "$paises" | cut -d: -f2)
              if [[ -z "$nome_pais" ]]; then
                nome_pais="$pais"  
              fi
              
              # Update entrada de pais 
              if grep -q "^$pais:$nome_pais:" "$temp_paises" 2>/dev/null; then
                tempo_atual=$(grep "^$pais:$nome_pais:" "$temp_paises" | cut -d: -f3)
                tempo_novo=$((tempo_atual + tempo))
                sed -i "s/^$pais:$nome_pais:$tempo_atual/$pais:$nome_pais:$tempo_novo/" "$temp_paises"
              else
                echo "$pais:$nome_pais:$tempo" >> "$temp_paises"
              fi
              
              # Update entrad de veic
              if grep -q "^$pais:$matricula:" "$temp_matriculas" 2>/dev/null; then
                tempo_atual=$(grep "^$pais:$matricula:" "$temp_matriculas" | cut -d: -f3)
                tempo_novo=$((tempo_atual + tempo))
                sed -i "s/^$pais:$matricula:$tempo_atual/$pais:$matricula:$tempo_novo/" "$temp_matriculas"
              else
                echo "$pais:$matricula:$tempo" >> "$temp_matriculas"
              fi
            fi
          done < "$arquivo"
        fi
      done
      
      sort -t: -k2 "$temp_paises" |
      while IFS=: read -r pais_cod nome_pais tempo_pais; do
        echo "<li><b>País:</b> $nome_pais <b>Total tempo estacionado:</b> $tempo_pais</li>"
        echo "<ul>"
        
      
        grep "^$pais_cod:" "$temp_matriculas" | sort -t: -k3 -nr |
        while IFS=: read -r codigo matricula tempo; do
          echo "<li><b>Matrícula:</b> $matricula <b> Total tempo estacionado:</b> $tempo</li>"
        done
        
        echo "</ul>"
      done
      
      rm -f "$temp_paises" "$temp_matriculas"
      echo "</ul>"
    fi

    # S3.2.7
    if [ "$stat_n" = "7" ]; then
      echo "<h2>Stats7:</h2>"
      echo "<ul>"
      
      temp_nomes="temp_nomes.txt"
      > "$temp_nomes"
      
      if [ -r "$parque" ]; then
        cut -d: -f4 "$parque" | sort | uniq > "$temp_nomes"
      fi
      

      for arquivo in arquivo-*-*.park; do
        if [ -r "$arquivo" ]; then
          cut -d: -f4 "$arquivo" >> "$temp_nomes"
        fi
      done
      
      sort "$temp_nomes" | uniq > "temp_nomes_sorted.txt"
      > "temp_nomes_len.txt"
      
      while read -r nome; do
        if [[ -n "$nome" ]]; then
          echo "${#nome}:$nome" >> "temp_nomes_len.txt"
        fi
      done < "temp_nomes_sorted.txt"
      
      # Get top 3 longest names
      sort -t: -k1 -nr "temp_nomes_len.txt" | head -3 | cut -d: -f2 |
      while read -r nome; do
        echo "<li><b> Condutor:</b> $nome</li>"
      done
      
      rm -f "$temp_nomes" "temp_nomes_sorted.txt" "temp_nomes_len.txt"
      echo "</ul>"
    fi
  done

  echo "</body></html>"
} > "$stats_html"

so_success S3.3


## S3.2. Estatísticas:
## Cada uma das estatísticas seguintes diz respeito à extração de informação dos ficheiros do sistema Park-IUL. Caso não haja informação suficiente para preencher a estatística, poderá apresentar uma lista vazia.
## S3.2.1.  Obter uma lista das matrículas e dos nomes de todos os condutores cujas viaturas estão ainda estacionadas no parque, ordenados alfabeticamente por nome de condutor:
## <h2>Stats1:</h2>
## <ul>
## <li><b>Matrícula:</b> <Matrícula> <b>Condutor:</b> <Nome do Condutor></li>
## <li><b>Matrícula:</b> <Matrícula> <b>Condutor:</b> <Nome do Condutor></li>
## ...
## </ul>


## S3.2.2. Obter uma lista do top3 das matrículas e do tempo estacionado das viaturas que já terminaram o estacionamento e passaram mais tempo estacionadas, ordenados decrescentemente pelo tempo de estacionamento (considere apenas os estacionamentos cujos tempos já foram calculados):
## <h2>Stats2:</h2>
## <ul>
## <li><b>Matrícula:</b> <Matrícula> <b>Tempo estacionado:</b> <TempoParkMinutos></li>
## <li><b>Matrícula:</b> <Matrícula> <b>Tempo estacionado:</b> <TempoParkMinutos></li>
## <li><b>Matrícula:</b> <Matrícula> <b>Tempo estacionado:</b> <TempoParkMinutos></li>
## </ul>


## S3.2.3. Obter as somas dos tempos de estacionamento das viaturas que não são motociclos, agrupadas pelo nome do país da matrícula (considere apenas os estacionamentos cujos tempos já foram calculados):
## <h2>Stats3:</h2>
## <ul>
## <li><b>País:</b> <Nome País> <b>Total tempo estacionado:</b> <ΣTempoParkMinutos></li>
## <li><b>País:</b> <Nome País> <b>Total tempo estacionado:</b> <ΣTempoParkMinutos></li>
## ...
## </ul>


## S3.2.4. Listar a matrícula, código de país e data de entrada dos 3 estacionamentos, já terminados ou não, que registaram uma entrada mais tarde (hora de entrada) no parque de estacionamento, ordenados crescentemente por hora de entrada:
## <h2>Stats4:</h2>
## <ul>
## <li><b>Matrícula:</b> <Matrícula> <b>País:</b> <Código País> <b>Data Entrada:</b> <DataEntrada></li>
## <li><b>Matrícula:</b> <Matrícula> <b>País:</b> <Código País> <b>Data Entrada:</b> <DataEntrada></li>
## <li><b>Matrícula:</b> <Matrícula> <b>País:</b> <Código País> <b>Data Entrada:</b> <DataEntrada></li>
## </ul>


## S3.2.5. Tendo em consideração que um utilizador poderá ter várias viaturas, determine o tempo total, medido em dias, horas e minutos gasto por cada utilizador da plataforma (ou seja, agrupe os minutos em dias e horas).
## <h2>Stats5:</h2>
## <ul>
## <li><b>Condutor:</b> <NomeCondutor> <b>Tempo  total:</b> <x> dia(s), <y> hora(s) e <z> minuto(s)</li>
## <li><b>Condutor:</b> <NomeCondutor> <b>Tempo  total:</b> <x> dia(s), <y> hora(s) e <z> minuto(s)</li>
## ...
## </ul>


## S3.2.6. Liste as matrículas das viaturas distintas e o tempo total de estacionamento de cada uma, agrupadas pelo nome do país com um totalizador de tempo de estacionamento por grupo, e totalizador de tempo global.
## <h2>Stats6:</h2>
## <ul>
## <li><b>País:</b> <Nome País></li>
## <ul>
## <li><b>Matrícula:</b> <Matrícula> <b> Total tempo estacionado:</b> <ΣTempoParkMinutos></li>
## <li><b>Matrícula:</b> <Matrícula> <b> Total tempo estacionado:</b> <ΣTempoParkMinutos></li>
## ...
## </ul>
## <li><b>País:</b> <Nome País></li>
## <ul>
## <li><b>Matrícula:</b> <Matrícula> <b> Total tempo estacionado:</b> <ΣTempoParkMinutos></li>
## <li><b>Matrícula:</b> <Matrícula> <b> Total tempo estacionado:</b> <ΣTempoParkMinutos></li>
## ...
## </ul>
## ...
## </ul>


## S3.2.7. Obter uma lista do top3 dos nomes mais compridos de condutores cujas viaturas já estiveram estacionadas no parque (ou que ainda estão estacionadas no parque), ordenados decrescentemente pelo tamanho do nome do condutor:
## <h2>Stats7:</h2>
## <ul>
## <li><b> Condutor:</b> <Nome do Condutor mais comprido></li>
## <li><b> Condutor:</b> <Nome do Condutor segundo mais comprido></li>
## <li><b> Condutor:</b> <Nome do Condutor terceiro mais comprido></li>
## </ul>


## S3.3. Processamento do script:
## S3.3.1. O script cria uma página em formato HTML, chamada stats.html, onde lista as várias estatísticas pedidas.
## O ficheiro stats.html tem o seguinte formato:
## <html><head><meta charset="UTF-8"><title>Park-IUL: Estatísticas de estacionamento</title></head>
## <body><h1>Lista atualizada em <Data Atual, formato AAAA-MM-DD> <Hora Atual, formato HH:MM:SS></h1>
## [html da estatística pedida]
## [html da estatística pedida]
## ...
## </body></html>
## Sempre que o script for chamado, deverá:
## • Criar o ficheiro stats.html.
## • Preencher, neste ficheiro, o cabeçalho, com as duas linhas HTML descritas acima, substituindo os campos pelos valores de data e hora pelos do sistema.
## • Ciclicamente, preencher cada uma das estatísticas pedidas, pela ordem pedida, com o HTML correspondente ao indicado na secção S3.2.
## • No final de todas as estatísticas preenchidas, terminar o ficheiro com a última linha “</body></html>”

