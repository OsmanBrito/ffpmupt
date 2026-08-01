# P0: operação de domingo e prontidão do país

Este ciclo transforma a aplicação num fluxo operacional que pode ser validado
em serviços reais antes da expansão para novos países.

## Página inicial

- **Serviço de Domingo** contém apenas os módulos litúrgicos.
- **Outros recursos** contém diretórios e consultas, como Holy Grounds.
- A página inteira rola; não existe uma segunda rolagem dentro dos cartões.
- O idioma da interface pode ser alterado no ícone de tradução.

## Modo Domingo

1. Na página inicial, clique em **Iniciar Modo Domingo**.
2. Ative somente os módulos usados naquele serviço.
3. Arraste os módulos para definir a ordem local daquele país/dispositivo.
4. Confira o estado dos áudios offline.
5. Use o botão de tela cheia para projeção.
6. Abra cada módulo. Ao voltar, ele será marcado como concluído.
7. Clique em **Concluir serviço** e registre o resultado.

O plano e os relatórios ficam no armazenamento local do dispositivo. Nenhum
serviço pago ou rastreamento externo é usado.

## Validação de três domingos

Ao concluir cada serviço, registre:

- se o serviço terminou sem papel;
- se o app funcionou sem interrupções;
- uma avaliação de 1 a 5;
- notas opcionais.

O Modo Domingo mostra o progresso de `0/3` até `3/3` e as métricas agregadas.
Use as notas para transformar problemas observados em backlog.

## Checklist do país

No admin, abra **País > Prontidão do país**. O checklist verifica:

- país ativo e acesso administrativo;
- músicas publicadas e estruturalmente válidas;
- Promessa da Família nos idiomas obrigatórios;
- pagamentos ativos com dados utilizáveis;
- links válidos de YouTube e Vimeo;
- pelo menos um Holy Ground publicado com fotografia;
- preparação dos áudios offline.

O checklist valida estrutura e formato dos links. A disponibilidade externa de
um vídeo, áudio ou imagem ainda deve ser confirmada durante a preparação.

## Offline

- Firestore mantém os dados previamente sincronizados.
- Músicas, Promessa, pagamentos e Holy Grounds possuem cache local.
- Áudios são preparados pelo service worker e podem ser tentados novamente.
- Imagens visitadas são guardadas no cache web.
- Vídeos continuam a exigir internet.

## Validações de publicação

- Página `0` não é aceita em novas edições de música; deixe a página vazia se
  ela não existir.
- Áudio ativo exige nome e URL HTTPS ou caminho de asset válido.
- Método de pagamento ativo exige dados, link ou conteúdo de QR Code.
- Holy Ground visível exige fotografia e coordenadas dentro dos limites.
- Coordenadas com vírgula, símbolos e direções `N`, `S`, `E`, `W` são aceitas.
