# Vigia do site da Lumo Consórcios

Confere a cada 15 minutos se https://lumoconsorcios.com.br está de pé. Quando alguma conferência falha, o GitHub manda um e-mail para o dono da conta.

## O que ele confere
- As páginas inicial, de contato e do simulador respondem.
- O formulário de leads está vivo e o banco de dados responde (`/api/saude.php`).
- O arquivo com a senha do banco continua bloqueado.
- O certificado de segurança (o cadeado) vale por mais de 14 dias.

Ele só consulta endereços públicos. Não envia formulário, não lê nenhum lead e não guarda nenhuma senha. Por isso o repositório pode ser público, e repositório público tem minutos de execução ilimitados no GitHub.

## Como testar o aviso
Abra Actions → "Vigia do site da Lumo" → Run workflow e marque "Simular uma falha". A execução fica vermelha e o e-mail de aviso chega.

## Como pausar
Abra Actions → "Vigia do site da Lumo" → ⋯ → Disable workflow.
