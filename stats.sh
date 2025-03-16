#!/bin/bash
# SO_HIDE_DEBUG=1                   ## Uncomment this line to hide all @DEBUG statements
# SO_HIDE_COLOURS=1                 ## Uncomment this line to disable all escape colouring
. so_utils.sh                       ## This is required to activate the macros so_success, so_error, and so_debug

#####################################################################################
## ISCTE-IUL: Trabalho prático de Sistemas Operativos 2024/2025, Enunciado Versão 1
##
## Aluno: Nº:       Nome:
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
  echo "S3.1 Erro, não tem permissões de leitura do estacionamentos.txt"
  so_error S3.1 "Não tem permissões de leitura do estacionamentos.txt"
  exit 1
fi 

existe_arquivo=false 
for arquivo in arquivo-*-*.park; do 
  if [ -r "$arquivo" ]; then 
    existe_arquivo=true
    break
  else 
    so_error S3.1 "Não tem permissões"
    exit 1
  fi
done 

if [ "$existe_arquivo" = false ]; then
  echo "não tem ficheiro ou permissões"
  so_error S3.1 "Não existe ficheiro(s) arquivo-<ano>-<mes>.par"
  exit 1 
fi

for n_args in "$@"; do
  if ! [[ "$n_args" =~ ^[1-7]]$ ]; then
    so_error S3.1 "Número de args inválido"
    exit 1 
  fi 
done 

so_success S3.1 

########################################################################################################

data_sistema=$(date "+%Y-%m-%d %H:%M:%S")

echo "<html><head><meta charset=\"UTF-8\"><title>Park-IUL: Estatísticas de estacionamento</title></head>
<body><h1>Lista atualizada em $data_sistema</h1>
<!-- Início da área reservada às estatísticas -->" | tee "$stats_html"

gerar_stats=""
if [ $# -eq 0 ]; then 
  gerar_stats="1 2 3 4 5 6 7"
else 
  gerar_stats="$@"
fi

for stat_n in $gerar_stats; do 
  #S3.2.1
  if [ "$stat_n" = "1" ]; then
    echo -e "\n<h2>Stats1:</h2>" | tee -a "$stats_html"
    echo "<ul>" | tee -a "$stats_html"
    grep -v ":[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}h[0-9]\{2\}$" "$parque" | sort -t: -k4 |
    while IFS=: read -r matricula pais categoria nome data_entrada data_saida; do
      echo "<li><b>Matrícula:</b> $matricula <b>Condutor:</b> $nome</li>" | tee -a "$stats_html"
    done
    echo "</ul>" | tee -a "$stats_html"
  fi
  
  #S3.2.2
  if [ "$stat_n" = "2" ]; then
  echo -e "\n<h2>Stats2:</h2>" | tee -a "$stats_html"
  echo "<ul>" | tee -a "$stats_html"
    
  # Extrair matricula, tempo -> ordenar por tempo decrescente -> mostrar top 3
  cat arquivo-*-*.park 2>/dev/null | 
  cut -d: -f1,7 | 
  sort -t: -k2 -nr | 
  head -3 |
    while IFS=: read -r matricula tempo; do
      echo "<li><b>Matrícula:</b> $matricula <b>Tempo estacionado:</b> $tempo</li>" | tee -a "$stats_html"
    done
    
    echo "</ul>" | tee -a "$stats_html"
  fi

  # S3.2.3
  if [ "$stat_n" = "3" ]; then
    echo -e "\n<h2>Stats3:</h2>" | tee -a "$stats_html"
    echo "<ul>" | tee -a "$stats_html"
    
    # Ficheiro para guardar totais por país
    temp_totais_paises="temp_totais_paises.txt"
    > "$temp_totais_paises"
    
    # Processar cada arquivo
    for arquivo in arquivo-*-*.park; do
      if [ -r "$arquivo" ]; then
        while IFS=: read -r matricula pais categoria nome entrada saida tempo; do
          # Ignorar motociclos
          if [ "$categoria" != "M" ]; then
            # Adicionar pais se não existir
            if ! grep -q "^$pais:" "$temp_totais_paises"; then
              echo "$pais:0" >> "$temp_totais_paises"
            fi
            
            # Atualizar tempo
            tempo_atual=$(grep "^$pais:" "$temp_totais_paises" | cut -d: -f2)
            tempo_novo=$((tempo_atual + tempo))
            sed -i "s/^$pais:$tempo_atual/$pais:$tempo_novo/" "$temp_totais_paises"
          fi
        done < "$arquivo"
      fi
    done
    
    #resultados
    while IFS=: read -r pais_cod tempo_total; do
      # Obter nome do país
      pais_nome=$(grep "^$pais_cod:" "$paises" | cut -d: -f2)
      echo "<li><b>País:</b> $pais_nome <b>Total tempo estacionado:</b> $tempo_total</li>" | tee -a "$stats_html"
    done < "$temp_paises"
    
    # Limpar ficheiro temporário
    rm -f "$temp_totais_paises"
    
    echo "</ul>" | tee -a "$stats_html"
  fi

  # S3.2.4
  if [ "$stat_n" = "4" ]; then
    echo -e "\n<h2>Stats4:</h2>" | tee -a "$stats_html"
    echo "<ul>" | tee -a "$stats_html"
    
    # Extrair matricula, país e data de entrada de todos os registos, ordenar e pegar top 3
    (
      cut -d: -f1,2,5 "$parque"
      for arquivo in arquivo-*-*.park; do
        if [ -r "$arquivo" ]; then
          cut -d: -f1,2,5 "$arquivo"
        fi
      done
    ) | sort -t: -k3 -r | head -3 | sort -t: -k3 |
    while IFS=: read -r matricula pais data_entrada; do
      echo "<li><b>Matrícula:</b> $matricula <b>País:</b> $pais <b>Data Entrada:</b> $data_entrada</li>" | tee -a "$stats_html"
    done
    
    echo "</ul>" | tee -a "$stats_html"
  fi

  # S3.2.5
  if [ "$stat_n" = "5" ]; then
    echo -e "\n<h2>Stats5:</h2>" | tee -a "$stats_html"
    echo "<ul>" | tee -a "$stats_html"
    
    # Ficheiro para totais por condutor
    temp_condutores="temp_condutores.txt"
    > "$temp_condutores"
    
    # Processar cada arquivo
    for arquivo in arquivo-*-*.park; do
      if [ -r "$arquivo" ]; then
        while IFS=: read -r matricula pais categoria nome entrada saida tempo; do
          # Adicionar condutor se não existir
          if ! grep -q "^$nome:" "$temp_condutores"; then
            echo "$nome:0" >> "$temp_condutores"
          fi
          
          # Atualizar tempo
          tempo_atual=$(grep "^$nome:" "$temp_condutores" | cut -d: -f2)
          tempo_novo=$((tempo_atual + tempo))
          sed -i "s/^$nome:$tempo_atual/$nome:$tempo_novo/" "$temp_condutores"
        done < "$arquivo"
      fi
    done
    
    #resultados convertidos em dias, horas e minutos
    while IFS=: read -r condutor tempo_total; do
      dias=$((tempo_total / 1440))
      resto=$((tempo_total % 1440))
      horas=$((resto / 60))
      minutos=$((resto % 60))
      
      echo "<li><b>Condutor:</b> $condutor <b>Tempo total:</b> $dias dia(s), $horas hora(s) e $minutos minuto(s)</li>" | tee -a "$stats_html"
    done < "$temp_condutores"
    
    # Limpar ficheiro temporário
    rm -f "$temp_condutores"
    
    echo "</ul>" | tee -a "$stats_html"
  fi

  # S3.2.6
  if [ "$stat_n" = "6" ]; then
    echo -e "\n<h2>Stats6:</h2>" | tee -a "$stats_html"
    echo "<ul>" | tee -a "$stats_html"
    
    # Ficheiro para totais por país
    temp_totais_paises="temp_totais_paises.txt"
    > "$temp_totais_paises"
    
    # Ficheiro para totais por matrícula
    temp_matriculas="temp_matriculas.txt"
    > "$temp_matriculas"
    
    # Processar cada arquivo
    for arquivo in arquivo-*-*.park; do
      if [ -r "$arquivo" ]; then
        while IFS=: read -r matricula pais categoria nome entrada saida tempo; do
          # Adicionar país se não existir
          if ! grep -q "^$pais:" "$temp_totais_paises"; then
            nome_pais=$(grep "^$pais:" "$paises" | cut -d: -f2)
            echo "$pais:$nome_pais:0" >> "$temp_totais_paises"
          fi
          
          # Atualizar tempo do país
          linha_pais=$(grep "^$pais:" "$temp_totais_paises")
          nome_pais=$(echo "$linha_pais" | cut -d: -f2)
          tempo_pais=$(echo "$linha_pais" | cut -d: -f3)
          novo_tempo_pais=$((tempo_pais + tempo))
          sed -i "s/^$pais:$nome_pais:$tempo_pais/$pais:$nome_pais:$novo_tempo_pais/" "$temp_totais_paises"
          
          # Adicionar matrícula se não existir
          if ! grep -q "^$pais:$matricula:" "$temp_matriculas"; then
            echo "$pais:$matricula:0" >> "$temp_matriculas"
          fi
          
          # Atualizar tempo da matrícula
          tempo_matricula=$(grep "^$pais:$matricula:" "$temp_matriculas" | cut -d: -f3)
          novo_tempo_matricula=$((tempo_matricula + tempo))
          sed -i "s/^$pais:$matricula:$tempo_matricula/$pais:$matricula:$novo_tempo_matricula/" "$temp_matriculas"
        done < "$arquivo"
      fi
    done
    
    # resultados por país
    while IFS=: read -r codigo nome_pais tempo_pais; do
      echo "<li><b>País:</b> $nome_pais <b>Total tempo estacionado:</b> $tempo_pais</li>" | tee -a "$stats_html"
      
      # Abrir lista de matrículas
      echo "<ul>" | tee -a "$stats_html"
      
      # Mostrar matrículas deste país
      grep "^$codigo:" "$temp_matriculas" | sort -t: -k3 -nr |
      while IFS=: read -r pais_cod matricula tempo; do
        echo "<li><b>Matrícula:</b> $matricula <b>Total tempo estacionado:</b> $tempo</li>" | tee -a "$stats_html"
      done
      
      # Fechar lista de matrículas
      echo "</ul>" | tee -a "$stats_html"
    done < "$temp_totais_paises"
    
    # Limpar ficheiros temporários
    rm -f "$temp_totais_paises" "$temp_matriculas"
    
    echo "</ul>" | tee -a "$stats_html"
  fi

  #S3.2.7
  if [ "$stat_n" = "7" ]; then
    echo -e "\n<h2>Stats7:</h2>" | tee -a "$stats_html"
    echo "<ul>" | tee -a "$stats_html"
    
    # Extrair todos os nomes, remover duplicados, ordenar por comprimento e pegar top 3
    (
      cut -d: -f4 "$parque"
      for arquivo in arquivo-*-*.park; do
        if [ -r "$arquivo" ]; then
          cut -d: -f4 "$arquivo"
        fi
      done
    ) | sort | uniq | 
    while read -r nome; do
      echo "${#nome}:$nome"
    done | sort -t: -k1 -nr | head -3 | cut -d: -f2 |
    while read -r nome; do
      echo "<li><b>Condutor:</b> $nome</li>" | tee -a "$stats_html"
    done
    
    echo "</ul>" | tee -a "$stats_html"
  fi
done

echo -e "\n<!-- Fim da área reservada às estatísticas -->\n</body></html>" | tee -a "$stats_html"


data_sistema=$(date "+%Y-%m-%d %H:%M:%S")

echo "<html><head><meta charset=\"UTF-8\"><title>Park-IUL: Estatísticas de estacionamento</title></head>
<body><h1>Lista atualizada em $data_sistema</h1>
<!-- Início da área reservada às estatísticas -->" | tee "$stats_html"

gerar_stats=""
if [ $# -eq 0 ]; then 
  gerar_stats="1 2 3 4 5 6 7"
else 
  gerar_stats="$@"
fi

for stat_n in $gerar_stats; do 
  #S3.2.1
  if [ "$stat_n" = "1" ]; then
    echo -e "\n<h2>Stats1:</h2>" | tee -a "$stats_html"
    echo "<ul>" | tee -a "$stats_html"
    grep -v ":[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}h[0-9]\{2\}$" "$parque" | sort -t: -k4 |
    while IFS=: read -r matricula pais categoria nome data_entrada data_saida; do
      echo "<li><b>Matrícula:</b> $matricula <b>Condutor:</b> $nome</li>" | tee -a "$stats_html"
    done
    echo "</ul>" | tee -a "$stats_html"
  fi
  
  #S3.2.2
  if [ "$stat_n" = "2" ]; then
  echo -e "\n<h2>Stats2:</h2>" | tee -a "$stats_html"
  echo "<ul>" | tee -a "$stats_html"
    
  # Extrair matricula, tempo -> ordenar por tempo decrescente -> mostrar top 3
  cat arquivo-*-*.park 2>/dev/null | 
  cut -d: -f1,7 | 
  sort -t: -k2 -nr | 
  head -3 |
    while IFS=: read -r matricula tempo; do
      echo "<li><b>Matrícula:</b> $matricula <b>Tempo estacionado:</b> $tempo</li>" | tee -a "$stats_html"
    done
    
    echo "</ul>" | tee -a "$stats_html"
  fi

  # S3.2.3
  if [ "$stat_n" = "3" ]; then
    echo -e "\n<h2>Stats3:</h2>" | tee -a "$stats_html"
    echo "<ul>" | tee -a "$stats_html"
    
    # Ficheiro para guardar totais por país
    temp_totais_paises="temp_totais_paises.txt"
    > "$temp_totais_paises"
    
    # Processar cada arquivo
    for arquivo in arquivo-*-*.park; do
      if [ -r "$arquivo" ]; then
        while IFS=: read -r matricula pais categoria nome entrada saida tempo; do
          # Ignorar motociclos
          if [ "$categoria" != "M" ]; then
            # Adicionar pais se não existir
            if ! grep -q "^$pais:" "$temp_totais_paises"; then
              echo "$pais:0" >> "$temp_totais_paises"
            fi
            
            # Atualizar tempo
            tempo_atual=$(grep "^$pais:" "$temp_totais_paises" | cut -d: -f2)
            tempo_novo=$((tempo_atual + tempo))
            sed -i "s/^$pais:$tempo_atual/$pais:$tempo_novo/" "$temp_totais_paises"
          fi
        done < "$arquivo"
      fi
    done
    
    #resultados
    while IFS=: read -r pais_cod tempo_total; do
      # Obter nome do país
      pais_nome=$(grep "^$pais_cod:" "$paises" | cut -d: -f2)
      echo "<li><b>País:</b> $pais_nome <b>Total tempo estacionado:</b> $tempo_total</li>" | tee -a "$stats_html"
    done < "$temp_totais_paises"
    
    # Limpar ficheiro temporário
    rm -f "$temp_totais_paises"
    
    echo "</ul>" | tee -a "$stats_html"
  fi

  # S3.2.4
  if [ "$stat_n" = "4" ]; then
    echo -e "\n<h2>Stats4:</h2>" | tee -a "$stats_html"
    echo "<ul>" | tee -a "$stats_html"
    
    # Extrair matricula, país e data de entrada de todos os registos, ordenar e invocar top 3
    (
      cut -d: -f1,2,5 "$parque"
      for arquivo in arquivo-*-*.park; do
        if [ -r "$arquivo" ]; then
          cut -d: -f1,2,5 "$arquivo"
        fi
      done
    ) | sort -t: -k3 -r | head -3 | sort -t: -k3 |
    while IFS=: read -r matricula pais data_entrada; do
      echo "<li><b>Matrícula:</b> $matricula <b>País:</b> $pais <b>Data Entrada:</b> $data_entrada</li>" | tee -a "$stats_html"
    done
    
    echo "</ul>" | tee -a "$stats_html"
  fi

  # S3.2.5
  if [ "$stat_n" = "5" ]; then
    echo -e "\n<h2>Stats5:</h2>" | tee -a "$stats_html"
    echo "<ul>" | tee -a "$stats_html"
    
    # Ficheiro para totais por condutor
    temp_condutores="temp_condutores.txt"
    > "$temp_condutores"
    
    # Processar cada arquivo
    for arquivo in arquivo-*-*.park; do
      if [ -r "$arquivo" ]; then
        while IFS=: read -r matricula pais categoria nome entrada saida tempo; do
          # Adicionar condutor se não existir
          if ! grep -q "^$nome:" "$temp_condutores"; then
            echo "$nome:0" >> "$temp_condutores"
          fi
          
          # Atualizar tempo
          tempo_atual=$(grep "^$nome:" "$temp_condutores" | cut -d: -f2)
          tempo_novo=$((tempo_atual + tempo))
          sed -i "s/^$nome:$tempo_atual/$nome:$tempo_novo/" "$temp_condutores"
        done < "$arquivo"
      fi
    done
    
    #resultados convertidos em dias, horas e minutos
    while IFS=: read -r condutor tempo_total; do
      dias=$((tempo_total / 1440))
      resto=$((tempo_total % 1440))
      horas=$((resto / 60))
      minutos=$((resto % 60))
      
      echo "<li><b>Condutor:</b> $condutor <b>Tempo total:</b> $dias dia(s), $horas hora(s) e $minutos minuto(s)</li>" | tee -a "$stats_html"
    done < "$temp_condutores"
    
    # Limpar ficheiro temporário
    rm -f "$temp_condutores"
    
    echo "</ul>" | tee -a "$stats_html"
  fi

  # S3.2.6
  if [ "$stat_n" = "6" ]; then
    echo -e "\n<h2>Stats6:</h2>" | tee -a "$stats_html"
    echo "<ul>" | tee -a "$stats_html"
    
    # Ficheiro para totais por país
    temp_totais_paises="temp_totais_paises.txt"
    > "$temp_totais_paises"
    
    # Ficheiro para totais por matrícula
    temp_matriculas="temp_matriculas.txt"
    > "$temp_matriculas"
    
    # Processar cada arquivo
    for arquivo in arquivo-*-*.park; do
      if [ -r "$arquivo" ]; then
        while IFS=: read -r matricula pais categoria nome entrada saida tempo; do
          # Adicionar país se não existir
          if ! grep -q "^$pais:" "$temp_totais_paises"; then
            nome_pais=$(grep "^$pais:" "$paises" | cut -d: -f2)
            echo "$pais:$nome_pais:0" >> "$temp_totais_paises"
          fi
          
          # Atualizar tempo do país
          linha_pais=$(grep "^$pais:" "$temp_totais_paises")
          nome_pais=$(echo "$linha_pais" | cut -d: -f2)
          tempo_pais=$(echo "$linha_pais" | cut -d: -f3)
          novo_tempo_pais=$((tempo_pais + tempo))
          sed -i "s/^$pais:$nome_pais:$tempo_pais/$pais:$nome_pais:$novo_tempo_pais/" "$temp_totais_paises"
          
          # Adicionar matrícula se não existir
          if ! grep -q "^$pais:$matricula:" "$temp_matriculas"; then
            echo "$pais:$matricula:0" >> "$temp_matriculas"
          fi
          
          # Atualizar tempo da matrícula
          tempo_matricula=$(grep "^$pais:$matricula:" "$temp_matriculas" | cut -d: -f3)
          novo_tempo_matricula=$((tempo_matricula + tempo))
          sed -i "s/^$pais:$matricula:$tempo_matricula/$pais:$matricula:$novo_tempo_matricula/" "$temp_matriculas"
        done < "$arquivo"
      fi
    done
    
    # resultados por país
    while IFS=: read -r codigo nome_pais tempo_pais; do
      echo "<li><b>País:</b> $nome_pais <b>Total tempo estacionado:</b> $tempo_pais</li>" | tee -a "$stats_html"
      
      # Abrir lista de matrículas
      echo "<ul>" | tee -a "$stats_html"
      
      # Mostrar matrículas deste país
      grep "^$codigo:" "$temp_matriculas" | sort -t: -k3 -nr |
      while IFS=: read -r pais_cod matricula tempo; do
        echo "<li><b>Matrícula:</b> $matricula <b>Total tempo estacionado:</b> $tempo</li>" | tee -a "$stats_html"
      done
      
      # Fechar lista de matrículas
      echo "</ul>" | tee -a "$stats_html"
    done < "$temp_totais_paises"
    
    # Limpar ficheiros temporários
    rm -f "$temp_totais_paises" "$temp_matriculas"
    
    echo "</ul>" | tee -a "$stats_html"
  fi

  #S3.2.7
  if [ "$stat_n" = "7" ]; then
    echo -e "\n<h2>Stats7:</h2>" | tee -a "$stats_html"
    echo "<ul>" | tee -a "$stats_html"
    
    # Extrair todos os nomes, remover duplicados, ordenar por comprimento e pegar top 3
    (
      cut -d: -f4 "$parque"
      for arquivo in arquivo-*-*.park; do
        if [ -r "$arquivo" ]; then
          cut -d: -f4 "$arquivo"
        fi
      done
    ) | sort | uniq | 
    while read -r nome; do
      echo "${#nome}:$nome"
    done | sort -t: -k1 -nr | head -3 | cut -d: -f2 |
    while read -r nome; do
      echo "<li><b>Condutor:</b> $nome</li>" | tee -a "$stats_html"
    done
    
    echo "</ul>" | tee -a "$stats_html"
  fi
done

echo -e "\n<!-- Fim da área reservada às estatísticas -->\n</body></html>" | tee -a "$stats_html"





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

