#!/usr/bin/env bash
# Confere se o site da Lumo Consorcios esta de pe. Sai com erro se algo falhar,
# e o GitHub manda e-mail para o dono quando a execucao falha.
#
# So consulta enderecos publicos. Nao envia formulario e nao le nenhum dado.
set -u

SITE="https://lumoconsorcios.com.br"
falhas=()

# Um soluco de rede nao e site fora: cada conferencia tenta 3 vezes, com 20 s
# de intervalo, antes de contar como falha.
pega() { # url -> imprime "status corpo"
  local url="$1" tentativa codigo corpo
  for tentativa in 1 2 3; do
    corpo=$(curl -sS --max-time 25 -w $'\n%{http_code}' "$url" 2>/dev/null) || corpo=$'\n000'
    codigo="${corpo##*$'\n'}"
    corpo="${corpo%$'\n'*}"
    if [[ "$codigo" != "000" && "$codigo" != 5* ]]; then break; fi
    [[ $tentativa -lt 3 ]] && sleep 20
  done
  printf '%s\n%s' "$codigo" "$corpo"
}

confere() { # rotulo url status_esperado [texto_que_precisa_aparecer]
  local rotulo="$1" url="$2" esperado="$3" texto="${4:-}" saida codigo corpo
  saida=$(pega "$url")
  codigo="${saida%%$'\n'*}"
  corpo="${saida#*$'\n'}"
  if [[ "$codigo" != "$esperado" ]]; then
    falhas+=("$rotulo: esperava $esperado, veio $codigo")
  elif [[ -n "$texto" && "$corpo" != *"$texto"* ]]; then
    falhas+=("$rotulo: respondeu $codigo mas sem o texto esperado")
  else
    echo "ok  $rotulo"
  fi
}

confere "pagina inicial"          "$SITE/"                       200 "Lumo"
confere "pagina de contato"       "$SITE/contato"                200 "Lumo"
confere "simulador"               "$SITE/simulador"              200 "Lumo"
confere "banco do formulario"     "$SITE/api/saude.php"          200 '"ok":true'
confere "formulario (PHP vivo)"   "$SITE/api/lead.php"           405
confere "senha do banco protegida" "$SITE/api/config.php"        403

# Cadeado: avisa com 14 dias de antecedencia se o certificado nao renovar.
fim=$(echo | openssl s_client -servername lumoconsorcios.com.br -connect lumoconsorcios.com.br:443 2>/dev/null \
  | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
if [[ -z "$fim" ]]; then
  falhas+=("cadeado: nao consegui ler o certificado")
else
  dias=$(( ($(date -d "$fim" +%s) - $(date +%s)) / 86400 ))
  if (( dias < 14 )); then falhas+=("cadeado: certificado vence em $dias dias ($fim)"); else echo "ok  cadeado valido por mais $dias dias"; fi
fi

if [[ "${SIMULAR_FALHA:-false}" == "true" ]]; then
  falhas+=("TESTE: falha simulada de proposito para conferir se o aviso chega")
fi

if (( ${#falhas[@]} > 0 )); then
  echo
  echo "SITE COM PROBLEMA (${#falhas[@]}):"
  for f in "${falhas[@]}"; do echo "  - $f"; echo "::error::$f"; done
  exit 1
fi
echo
echo "Tudo certo."
