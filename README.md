# Racha Casa

App web para dividir as contas da casa. Funciona no celular como app (PWA), sem loja de aplicativos.

## O que ele faz

- Sala da casa com os moradores, protegida por código de acesso
- Notinhas divididas entre quem participou, com o centavo que sobra distribuído
- Dívidas por pessoa, pagamento com confirmação de quem recebe
- Abatimento de dívidas cruzadas, só vale depois que a outra pessoa aceita
- Atualização em tempo real entre os moradores

## Como colocar no ar

1. No Supabase, abra SQL Editor, cole o conteúdo de `supabase.sql` e execute.
2. No Supabase, ative o login anônimo: Authentication > Sign In / Providers > Anonymous Sign-Ins.
3. Em `index.html`, preencha `SUPABASE_URL` e `SUPABASE_ANON_KEY` no começo do script
   (Project Settings > API: Project URL e a chave anon / publishable).
4. Suba os arquivos para o GitHub e ative o GitHub Pages: Settings > Pages > Deploy from a branch > main > / (root).
5. Abra o link no celular e use "Adicionar à tela inicial".

Sem as chaves preenchidas, o app abre em modo local (dados só no aparelho), útil para testar o visual.

## Arquivos

- `index.html`: o app inteiro (visual e lógica)
- `supabase.sql`: tabelas, regras de acesso e funções do banco
- `manifest.webmanifest`, `sw.js`, `icon*.png`, `icon.svg`: instalação como app e cache
