# CRM operacional

O CRM operacional organiza a expansão do produto. Ele gerencia países,
igrejas locais, administradores e o progresso de configuração. Esta primeira
versão não armazena membros, presença ou dados pastorais.

## Papéis de acesso

### Superadministrador

O `superadmin` pode:

- Ver todos os países.
- Criar países.
- Cadastrar e editar igrejas locais.
- Convidar administradores por email e link.
- Acessar a administração de qualquer país.

Use esse papel apenas para uma quantidade pequena de responsáveis globais.

Documento: `users/{uid}`

```json
{
  "role": "superadmin",
  "enabled": true,
  "countryCodes": [],
  "email": "responsavel@example.com",
  "displayName": "Responsável global"
}
```

### Administrador de país

O `admin` continua limitado aos códigos exatos presentes em `countryCodes`.

```json
{
  "role": "admin",
  "enabled": true,
  "countryCodes": ["pt", "br"],
  "email": "admin@example.com",
  "displayName": "Administrador"
}
```

O código deve ser igual ao ID em `countries`. Para o Brasil, use `br`; o
idioma principal continua sendo `pt`.

## Preparar o primeiro superadministrador

1. Abra Firebase Authentication.
2. Localize a sua conta e copie o UID.
3. Abra `users/{uid}` no Firestore.
4. Troque `role` de `admin` para `superadmin`.
5. Mantenha `enabled` como booleano `true`.
6. Publique as regras mais recentes do Firestore.
7. Saia e entre novamente no admin.
8. Abra **CRM operacional**.

## Criar um país

1. Abra **Administração > CRM operacional**.
2. Clique em **Novo país**.
3. Informe código, nome, idioma principal e fuso horário.
4. Abra a ficha do país.
5. Complete os itens de prontidão.

## Cadastrar uma igreja local

1. Abra a ficha do país.
2. Em **Igrejas locais**, clique no botão de adicionar.
3. Informe nome, cidade, endereço, fuso horário e responsável.
4. Guarde a igreja.

As igrejas ficam em `countries/{countryCode}/churches/{churchId}` e não são
públicas nesta versão.

## Convidar um administrador

1. Abra o país no CRM.
2. Em **Administradores**, clique em convidar.
3. Informe nome e email.
4. Crie o convite.
5. Copie o link e envie por email, WhatsApp ou outro canal.
6. O convite expira após sete dias.

O convidado abre o link, cria uma conta ou entra em uma conta existente,
confirma o email e aceita o acesso. O UID e o documento `users/{uid}` são
resolvidos automaticamente.

Este fluxo usa apenas Firebase Authentication, Firestore e Hosting. Ele não
depende de Cloud Functions nem de um plano pago. O envio do link é manual; o
email de confirmação da conta é enviado pelo Firebase Authentication.

Editar um administrador preserva os outros países associados. **Remover deste
país** remove somente o código atual, sem apagar a conta nem os outros acessos.

## Segurança dos convites

- O email autenticado deve ser igual ao email convidado.
- O email precisa estar confirmado.
- O convite deve estar ativo e dentro da validade.
- Os países gravados são exatamente os países do convite mais os acessos que o
  administrador já possuía.
- Cada convite só pode ser aceito uma vez.
- As regras do Firestore validam essas condições na mesma transação que cria o
  perfil administrativo.

## Prontidão do país

O painel considera sete requisitos:

1. País ativo.
2. Pelo menos um administrador associado.
3. Pelo menos uma igreja local ativa.
4. Promessa nos idiomas necessários.
5. Catálogo remoto de músicas preparado.
6. Pagamentos configurados.
7. Vídeos semanais configurados.

O indicador é operacional. Ele ajuda a encontrar o que falta, mas não publica
conteúdo automaticamente.
