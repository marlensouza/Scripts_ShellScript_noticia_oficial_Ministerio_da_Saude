#!/bin/bash
#
# noticia_oficial_Ministerio_da_Saude.sh
#
# Autor: Marlen Souza
#
# Descrição: Selecionar links de fonte oficial do Ministério da Saúde.
#            
#
# Criado: 23/03/2020
#

# Função responsável por acessar site do Ministério da Saúde via CURL no Endereço www.saude.gov.br e filtrar conteúdo via expressão regular.
# Exbindo as 100 notícias mais recentes.

func_ministerio_da_saude(){

    curl -s https://www.saude.gov.br/noticias/agencia-saude?start=[0-9]{+} | egrep "\/noticias\/agencia-saude\/" | tr -d "\t" | sed "s/^ *//" | tac

}

var_func_ministerio_da_saude=$(func_ministerio_da_saude)

# Usa a saída da função func_sespa() para gerar uma lista/menu com título e timestamp da respectiva notícia.
func_titulo_materia(){

    echo "$var_func_ministerio_da_saude" | egrep -o ">.*<" | tr -d "[><]" | nl
}

var_func_titulo_materia=$(func_titulo_materia)


# Gera endpoint para o site do Ministério da Saúde
func_endpoint(){

    echo "$var_func_ministerio_da_saude" | egrep -o "\".*\"" | tr -d "\"" | tr -d " " | sed "s/^ *//" | nl | sed "s/^ *//" | tr "\t" "="

}

var_func_endpoint=$(func_endpoint)

# Acessa API para gerar dados sobre o corona virus(COVID-19) do ponto de vista mundial.
# jq é o responsável por tratar os dados de saída da API no formato JSON.
func_api_covid_19(){

   curl -s https://coronavirus-tracker-api.herokuapp.com/v2/locations

}

var_func_api_covid_19=$(func_api_covid_19)

# A função func_atualização_automatica_id_api() tem por finalidade atualizar de forma automatica o id do pais, caso haja alguma alteração na API.
func_atualização_automatica_id_api(){

   pais="brazil"
   echo "$var_func_api_covid_19" | jq . | egrep -B 1 -i "$pais" | tr -d "( |,$)" | head -n 1 | cut -d : -f 2

}

id_api=$(func_atualização_automatica_id_api)

# Dados mundiais COVID-19
func_dado_mundial(){

    echo "$var_func_api_covid_19" | jq '{"casos_confirmados": ."latest"."confirmed" , "mortes": ."latest"."deaths" , "recuperados": ."latest"."recovered"}' | egrep -v "(^\{|^\})" | tr -d "\"" | tr -d "\,"

}

var_func_dado_mundial=$(func_dado_mundial)

# Dados do Brasil COVID-19
func_dado_brasil(){

    echo "$var_func_api_covid_19" | jq --argjson id_api $id_api '{ "pais": ."locations"[$id_api]."country" , "atualizacao": ."locations"[28]."last_updated" , "confirmados": ."locations"[28]."latest"."confirmed" , "recuperados": ."locations"[28]."latest"."recovered" , "mortes": ."locations"[28]."latest"."deaths" }' | egrep -v "(^\{|^\})" | tr -d "\"" | tr -d "\," | tr -d "\"" | tr -d "\," | sed "s/T.*//"

}

var_func_dado_brasil=$(func_dado_brasil)

# Auxilia na contagem total de opções maxima do menu.
func_num_linhas(){

    echo "$var_func_endpoint" | tail -n 1 | cut -d = -f 1

}


func_main(){
echo "
   Ministério da Saúde (www.saude.gov.br)
   Horário de atendimento: Segunda a sexta-feira, das 8h às 18h, sem interrupção para almoço.
   Telefone: (61) 3315.6136
   E-mail  : sic@saude.gov.br
   Twitter : https://twitter.com/minsaude

           $(date +%d/%m/%Y)

Dados mundiais COVID-19:
$var_func_dado_mundial

Dados Brasil COVID-19:
$var_func_dado_brasil
"

# Título/menu
func_titulo_materia

echo -n "
 Quanto maior o valor de índice, 
 mais recente é a notícia.

Digite o número da notícia: "

# Recebe a opção/número e instância a variável número
read numero

# Gera link da notícia
link_noticia=$(echo "$var_func_endpoint" | egrep "^$numero=" | sed "s/^$numero=//")

# Executa navegador para acessar link contido na váriavel de ambiente "https://www.saude.gov.br$link_noticia". O navegador pode ser
# alterado por qualquer outro, bastando assim substituir a "google-chrome" por qualquer outro navegador.

linhas=$(func_num_linhas)

if test "$numero" -gt "$linhas" || test "$numero" -le 0
then
  echo "opção não existe!"
else
  google-chrome https://www.saude.gov.br$link_noticia
fi

}

while :
do
  echo -e '\033c'
  # Executa função func_main() suprimindo saídas de erro com o "2>&-"
  func_main 2>&-
  read -p "Deseja continuar (s/n)? "
  [[ ${REPLY^} == N ]] && exit
done
