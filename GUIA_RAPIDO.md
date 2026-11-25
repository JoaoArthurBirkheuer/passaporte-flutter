# Guia rápido do Passaporte

Roteiro simples para testar o aplicativo completo.

## Acessos

- **Web:** https://diario-viagens-tdm-jh.web.app
- **APK Android:** `dist/passaporte.apk`
- **Conta demo:** `demo@passaporte.app` / `Passaporte123!`
  - 4 lugares: 3 visitados e 1 planejado
  - 2 históricos de IA
- **Conta de teste:** `conta-teste@exemplo.com` / `123456`
  - 2 lugares: Cristo Redentor (visitado) e Chapada Diamantina (planejado)
  - Use esta conta para testar a recuperação de senha, pois o e-mail é real

## 1. Entrar ou criar conta

1. Abra a URL da web.
2. Entre com uma das contas acima ou toque em **Cadastre-se**.
3. O cadastro aceita e-mail/senha ou login com Google.

## 2. Criar um lugar visitado

1. Abra a aba **Diário**.
2. Toque em **Novo lugar**.
3. Em **Nome do lugar**, digite algo como `Praia do Forte`.
4. Deixe o status em **Já visitei**.
5. Escolha o **Tipo de lugar**. Se nenhum servir, escolha **Outro** e descreva.
6. Toque no mapa para escolher o ponto. O endereço será preenchido automaticamente.
   - Alternativa: toque em **Usar minha localização**.
7. Preencha as anotações se quiser e toque em **Salvar lugar**.
8. O lugar aparece na lista com as estrelas e o tipo.

## 3. Criar um lugar planejado

1. Repita os passos acima, mas escolha **Quero visitar**.
2. A data passa a ser **Data prevista** e a avaliação vira **Expectativa**.
3. O cartão mostra o selo **Planejado**.
4. No Perfil, a linha "visitados • planejados" é atualizada.

## 4. Editar e excluir

- Na lista, toque no cartão do lugar para abrir os detalhes.
- No topo dos detalhes, use o lápis para **editar** ou a lixeira para **excluir**.
- Na lista, a lixeira do cartão também exclui, com confirmação.
- Deslize um cartão para a esquerda para excluir. Depois da confirmação, o aviso
  mostra **Desfazer**, que recria o lugar no diário.
- Ao voltar de um formulário com dados não salvos, o app pergunta
  **Descartar alterações?**.

## 5. Buscar, filtrar e ordenar

1. Na aba **Diário**, use a busca por nome, categoria, endereço ou notas.
2. Toque nos chips **Todos**, **Já visitei** ou **Quero visitar**.
3. Toque no ícone de **Filtros** (ao lado dos chips) para:
   - filtrar por categoria;
   - ordenar por mais recentes, mais antigos, melhor nota ou nome;
   - limpar todos os filtros.

## 6. Mapa

1. Abra a aba **Mapa**.
2. Os lugares salvos aparecem como marcadores e o mapa se ajusta para mostrá-los.
3. Toque em um marcador para abrir os detalhes.
4. Toque em **Centralizar em mim** para ativar a localização atual.
5. Use o botão **Ver todos os lugares** (ícone de enquadrar) junto ao zoom para
   reenquadrar o mapa em todos os marcadores.
6. Toque no mapa para abrir o card **"Adicionar lugar aqui?"** com as coordenadas e o endereço. Confirme em **Adicionar lugar**.
7. Segure no mapa para criar um lugar diretamente naquele ponto.

O botão **Novo lugar** usa o centro atual do mapa, não a localização antiga do aparelho. Assim, se você estiver olhando Passo Fundo, o formulário abre em Passo Fundo.

A localização é pedida **somente quando você toca no botão**, não ao abrir o app.

## 7. IA

1. Abra a aba **IA**.
2. Escolha:
   - **Dicas** para um lugar específico;
   - **Roteiro** para um roteiro de um dia com todos os lugares;
   - **Resumo** para um resumo da viagem.
3. Toque em **Gerar com Gemini**.
4. A resposta aparece em streaming e é salva automaticamente no histórico.
5. Ao trocar a ação ou o lugar, a resposta atual é limpa; a anterior continua no histórico.
6. Toque em **Ver histórico da IA** para consultar ou excluir respostas antigas.

A IA recebe nome, status, tipo, endereço, coordenadas, data, notas, outros lugares e as distâncias entre eles. Ela adapta o foco ao tipo do lugar e só fala de alimentação quando faz sentido (restaurante/café ou menção nas suas anotações). As respostas também mostram o aviso de conteúdo gerado por IA.

## 8. Recuperar senha

1. Na tela de login, toque em **Esqueci minha senha**.
2. Informe o e-mail e toque em **Enviar link**.
3. Use a conta `conta-teste@exemplo.com` para receber o e-mail de verdade.
4. Verifique a caixa de entrada e o spam.

## 9. Perfil

- Mostra total de lugares, média das notas, pedidos de IA e quantos são visitados/planejados.
- **Editar nome** altera o nome exibido.
- **Sair da conta** encerra a sessão.

## 10. Web responsivo

- Reduza a janela do navegador para ver a barra inferior.
- Aumente para 900 px ou mais para ver a barra lateral (`NavigationRail`).
- O conteúdo fica centralizado e com largura máxima em telas grandes.

## 11. Testar offline (web)

1. Abra o **DevTools** do Chrome (`F12`).
2. Vá em **Network** e marque **Offline**.
3. A aba Diário mostra o aviso **Modo offline**.
4. Você ainda vê os lugares salvos em cache.
5. Crie ou edite um lugar: a escrita fica pendente e sincroniza quando voltar online.
6. Desmarque **Offline** para o aviso desaparecer.

Observação: os tiles do mapa não são armazenados offline nesta versão.

## 12. Testar no Android

1. Inicie o emulador `flutteravd` no Android Studio ou com:
   ```powershell
   flutter emulators --launch flutteravd
   ```
2. Instale o APK (se ainda não estiver instalado):
   ```powershell
   adb install -r dist/passaporte.apk
   ```
3. Abra o app **Passaporte**.
4. Para simular localização:
   - Android Studio: **Extended Controls (...) > Location**;
   - ou terminal:
     ```powershell
     adb emu geo fix -46.633308 -23.550520
     ```
5. Se a permissão de localização for negada, use o botão **Resolver** no card do mapa.

## Builds mais rápidos (Android)

O APK mais recente já está em `dist/passaporte.apk`. Você não precisa recompilar para testar.

Se precisar gerar outro APK:

- **Teste pelo navegador** para a maioria das funcionalidades; é mais rápido que o build Android.
- **Emulador:** use `build_apk.cmd x64`. Gera `dist/passaporte-x64.apk`.
- **Celular físico:** use `build_apk.cmd arm64`. Gera `dist/passaporte-arm64.apk`.
- **Durante o desenvolvimento:** prefira `flutter run -d emulator-5554` em debug. Depois do primeiro build, o hot reload é rápido.
- **Evite `flutter clean`** no dia a dia; ele apaga os caches e deixa o próximo build muito mais lento.
- **OneDrive:** a pasta do projeto está sincronizando. Para builds mais rápidos, mova o projeto para uma pasta local (ex.: `C:\\dev\\passaporte`) ou pause a sincronização do OneDrive durante o build.
- Já habilitei cache, paralelismo e daemon do Gradle em `android/gradle.properties`.

## 13. Tema, zoom e Markdown

### Tema claro/escuro

1. Abra **Perfil**.
2. Na seção **Aparência**, escolha **Sistema**, **Claro** ou **Escuro**.
3. O padrão é seguir o tema do sistema.
4. A escolha fica salva no dispositivo e é mantida ao recarregar.

### Zoom no mapa

- No mapa principal, use os botões **+** e **−** no canto inferior direito.
- No formulário, o seletor de local também tem os botões **+** e **−**.
- A roda do mouse e o gesto de pinça continuam funcionando.

### Respostas em Markdown

- As respostas do Gemini agora renderizam `**negrito**`, listas e títulos.
- O texto continua selecionável para copiar.

### Como usar

- Abra o menu lateral (☰) e toque em **Como usar**.
- O bottom sheet traz dicas rápidas de mapa, status, filtros, IA, tema e exclusão.
- O botão **Ver todos os lugares** fica junto aos controles de zoom do mapa.

## 14. Checklist rápido

- [ ] Login com a conta demo
- [ ] Criar um lugar visitado
- [ ] Criar um lugar planejado
- [ ] Filtrar por "Quero visitar"
- [ ] Ordenar por melhor nota
- [ ] Abrir um lugar e editar
- [ ] Excluir um lugar com a lixeira
- [ ] Deslizar um cartão para excluir e usar **Desfazer**
- [ ] Voltar de um formulário alterado e ver **Descartar alterações?**
- [ ] Ativar a localização no mapa
- [ ] Tocar no mapa e adicionar um lugar no ponto escolhido
- [ ] Usar **Ver todos os lugares** no mapa
- [ ] Abrir o menu lateral (☰), ver **Como usar** e navegar entre as seções
- [ ] Observar as animações de tema, cards, contadores e Hero
- [ ] Gerar dicas com o Gemini
- [ ] Trocar a ação/lugar e ver a resposta anterior ir para o histórico
- [ ] Ver o histórico da IA
- [ ] Testar "Esqueci minha senha" com a conta de teste
- [ ] Alternar entre tema claro/escuro/sistema
- [ ] Usar os botões de zoom + e − no mapa
- [ ] Conferir uma resposta do Gemini com negrito e listas
- [ ] Redimensionar a janela para ver o layout web
- [ ] Ativar o modo offline no DevTools
- [ ] Instalar e abrir o APK no Android

## 15. Limitações conhecidas

- O mapa usa OpenStreetMap e não armazena tiles offline.
- O APK de entrega usa assinatura de debug e App Check de debug, adequado para a avaliação acadêmica.
- A conta demo usa um e-mail fictício; para recuperação de senha, use a conta de teste ou uma conta real.
