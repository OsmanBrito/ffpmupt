# Importar músicas em um novo país

Este processo serve para a carga inicial das músicas locais de um país. Ele
aceita uma planilha `.xlsx` com várias músicas ou arquivos `.pptx`, com uma
música por apresentação.

O catálogo padrão de Worship não é removido. As músicas importadas são
adicionadas ao país selecionado e não alteram nenhum outro país.

## Antes de começar

- Entre no país correto no app.
- Faça login com um administrador autorizado para esse país.
- Confirme que as músicas ainda não passaram pela importação inicial.
- Não coloque MP3 na planilha ou no PowerPoint. Os áudios são adicionados
  depois, na edição individual da música.

O sistema permite confirmar e corrigir título, página, categoria e idioma
antes de salvar qualquer coisa no Firestore.

## Opção 1: importar uma planilha XLSX

### 1. Baixar o modelo

1. Abra **Administração**.
2. Entre em **Músicas**.
3. Clique em **Modelo XLSX**.
4. Abra o arquivo `modelo_importacao_musicas.xlsx` no Excel, LibreOffice ou
   Google Sheets.

### 2. Preencher a planilha

Use uma linha por música. Não altere os nomes da primeira linha.

| Coluna | Obrigatória | Como preencher |
| --- | --- | --- |
| `titulo` | sim | Nome da música |
| `pagina` | não | Número ou código mostrado no app |
| `categoria` | não | `holy`, `fellowship`, `english`, `worship` ou `international` |
| `idioma` | não | Código como `pt`, `en`, `ko`, `es`, `de`, `it` ou `fr` |
| `refrao` | não | Escreva o refrão apenas uma vez |
| `estrofe_1` até `estrofe_10` | uma delas | Uma estrofe por coluna |
| `ordem` | não | Ordem numérica no catálogo |
| `ativa` | não | `sim` ou `nao`; vazio significa ativa |

Quando existe refrão, o app intercala automaticamente o refrão entre as
estrofes. Deixe vazias as colunas de estrofes que não forem usadas.

### 3. Importar

1. Volte a **Administração > Músicas**.
2. Clique em **Importar XLSX/PPTX**.
3. Selecione a planilha.
4. Revise os avisos e a lista reconhecida.
5. Use o lápis para corrigir título, página, categoria ou idioma.
6. Remova da lista qualquer música que não deva ser importada.
7. Clique em **Confirmar importação**.

## Opção 2: importar arquivos PPTX

Use esta opção quando cada música já existe como uma apresentação de culto.
O arquivo `Unidade.pptx` é um exemplo compatível.

### Estrutura recomendada

- Um arquivo `.pptx` por música.
- O título da música repetido em todos os slides.
- Uma estrofe diferente em cada slide.
- O mesmo refrão repetido em todos os slides, quando existir.
- O número da estrofe pode começar o texto: `1.`, `2.`, `3.`.

O sistema identifica o texto repetido no topo como título e o texto repetido
nos slides como refrão. Cada slide vira uma estrofe. Cores e imagens não são
importadas.

### Importar vários PPTX de uma vez

1. Abra **Administração > Músicas**.
2. Clique em **Importar XLSX/PPTX**.
3. Selecione todos os arquivos `.pptx` desejados.
4. Revise os resultados.
5. Ajuste principalmente página, categoria e idioma.
6. Clique em **Confirmar importação**.

## Depois da importação

1. Abra uma música importada.
2. Confirme a ordem das estrofes e do refrão.
3. Adicione os áudios individualmente, quando existirem.
4. Teste a música na tela pública.
5. Aguarde o indicador offline confirmar que os áudios foram baixados.

## Limites desta primeira versão

- A importação é inicial e só pode ser confirmada uma vez por país.
- Um PPTX deve conter apenas uma música.
- O PPTX importa texto, não imagens, animações, fontes ou áudio.
- Arquivos antigos `.ppt` não são aceitos; salve-os como `.pptx` primeiro.
- Se uma apresentação não repetir claramente título ou refrão, revise o
  resultado antes de confirmar.

## Problemas comuns

### A planilha não é reconhecida

Confirme que o arquivo é `.xlsx`, que a primeira aba contém os dados e que a
primeira linha possui a coluna `titulo`.

### Uma estrofe ficou vazia

No XLSX, coloque cada estrofe na sua própria coluna. No PPTX, confirme que o
texto está em uma caixa de texto editável e não dentro de uma imagem.

### O refrão não foi identificado no PPTX

Use exatamente o mesmo texto de refrão em todos os slides. Diferenças de
pontuação ou palavras fazem o sistema tratá-lo como textos diferentes.

### A importação inicial já foi concluída

Continue adicionando ou editando músicas individualmente pelo admin. Uma nova
importação em massa exigirá uma futura função de atualização controlada para
evitar duplicações.
