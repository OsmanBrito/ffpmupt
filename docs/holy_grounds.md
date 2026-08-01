# Holy Grounds MVP

O diretório reúne os Holy Grounds dos países disponíveis no app. A tela
pública permite pesquisar por nome ou cidade, filtrar por país e consultar os
detalhes de cada local.

## O que o MVP inclui

- Diretório europeu único.
- País atual exibido primeiro.
- Pesquisa por nome, cidade e resumo.
- Filtro por país.
- Upload de fotografia pelo administrador.
- História e instruções de visita.
- Responsável e email de contato.
- Endereço e coordenadas opcionais.
- Abertura no Google Maps.
- Cópia offline da última lista sincronizada.

O app usa URLs universais do Google Maps. Esse formato abre o site ou
aplicativo de mapas e não exige chave de API.

## Cadastrar um Holy Ground

1. Selecione o país correto.
2. Abra **Administração**.
3. Entre em **Holy Grounds**.
4. Clique em **Novo local**.
5. Informe nome, cidade, endereço e resumo.
6. Selecione uma fotografia JPG, PNG ou WebP de até 5 MB.
7. Adicione latitude e longitude juntas para maior precisão.
8. Preencha história, instruções e contato.
9. Marque o local como visível.
10. Guarde.

O administrador só pode editar locais armazenados dentro dos países aos quais
tem acesso.

## Fotografias

O app envia as fotografias para o Cloudinary e guarda apenas a URL HTTPS no
documento do Holy Ground no Firestore. O MVP usa o plano gratuito, sem cartão,
com estas configurações públicas:

- Cloud name: `ddqs0j1t`.
- Upload preset unsigned: `holy_grounds`.
- Formatos aceitos: JPG, PNG e WebP.
- Tamanho máximo no app: 5 MB.

O preset deve manter limites equivalentes no painel do Cloudinary. Como o
upload é feito diretamente pelo navegador, o nome do preset é público; não
adicione API Secret ao aplicativo. Ao trocar uma fotografia, o arquivo antigo
deve ser removido manualmente no Cloudinary caso não seja mais necessário.

## Publicação

Desativar **Local visível no diretório** remove o local da tela pública sem
apagar os dados e impede a leitura pública direta do documento. A alteração é
sincronizada automaticamente quando o app está online.

Holy Grounds são conteúdo opcional na prontidão operacional: aparecem na
checklist do país, mas a ausência de um local não bloqueia o lançamento.

## Limites do MVP

- Não há mapa embutido.
- A remoção de fotografias antigas no Cloudinary ainda é manual.
- O conteúdo do local não é traduzido automaticamente.
- Não há avaliações, comentários ou check-ins.
- Holy Grounds não são requisito obrigatório para um país estar pronto.
