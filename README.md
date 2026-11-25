# Passaporte

Aplicativo Flutter para registrar lugares visitados ou desejados, visualizar tudo em um mapa e receber sugestões de viagem geradas pelo Gemini.

Projeto final da disciplina de Tópicos de Desenvolvimento Web.

## Links da entrega

- **Aplicação web:** https://diario-viagens-tdm-jh.web.app
- **APK Android:** `dist/passaporte.apk`
- **Console do Firebase:** https://console.firebase.google.com/project/diario-viagens-tdm-jh/overview

## Guia rápido

Veja [GUIA_RAPIDO.md](GUIA_RAPIDO.md) para um roteiro passo a passo de teste do aplicativo.

## Funcionalidades

- **Autenticação com Firebase Auth**
  - Cadastro e login com e-mail/senha
  - Login com Google
  - Recuperação de senha por e-mail
  - Perfil do usuário em `users/{uid}`
- **CRUD completo no Cloud Firestore**
  - Criar, listar, consultar, editar e excluir lugares
  - Status "Já visitei" / "Quero visitar"
  - Busca por nome, categoria, endereço ou notas
  - Filtros por status e categoria, com ordenação por data, nota ou nome
  - Tipo de lugar com opção "Outro" e descrição personalizada
  - Dados isolados por usuário
- **Mapa e geolocalização**
  - Mapa OpenStreetMap com `flutter_map`
  - Marcadores dos lugares salvos
  - Localização atual sob demanda
  - Toque no mapa para abrir "Adicionar lugar aqui?" com coordenadas e endereço
  - Segure no mapa para criar um lugar diretamente no ponto
  - Controles de zoom (+/−) no mapa e no seletor de local
  - Botão "Ver todos os lugares" que reenquadra o mapa nos marcadores salvos
  - O botão "Novo lugar" usa o centro atual do mapa
  - Seleção de local no formulário tocando no mapa
  - Preenchimento automático do endereço com Nominatim/OpenStreetMap
- **IA generativa com Gemini**
  - Dicas sobre um lugar específico
  - Roteiro de um dia com os lugares do diário
  - Resumo afetivo da viagem
  - Resposta em streaming
  - Respostas renderizadas em Markdown (negrito, listas e títulos)
  - Respostas adaptadas ao tipo de lugar (transporte, residência, restaurante etc.)
  - A resposta é limpa ao trocar de ação ou lugar; a anterior fica no histórico
  - Aviso de conteúdo gerado por IA
  - Contexto com endereço, coordenadas, data, notas e distâncias entre lugares
  - Instrução de sistema para evitar respostas genéricas e fatos inventados
  - Histórico de solicitações e respostas salvo no Firestore
- **Experiência web e mobile**
  - Layout responsivo com `NavigationRail` em telas largas
  - Conteúdo centralizado com largura máxima no web
  - Menu lateral com Mapa, Diário, IA, Perfil, Como usar e Sair
  - Bottom sheet "Como usar" com dicas rápidas de mapa, status, filtros, IA e tema
  - Modo offline com cache do Firestore e banner de conectividade
  - Swipe-to-delete da direita para a esquerda com confirmação e "Desfazer"
  - Confirmação "Descartar alterações?" ao voltar de um formulário com dados não salvos
- **Polimento visual e movimento**
  - Tipografia Fraunces nos títulos e Inter nos textos, botões, chips e navegação
  - Transição suave de tema (280 ms)
  - Título do AppBar com fade + slide ao trocar de aba
  - Hero no ícone da categoria entre a lista e os detalhes
  - Entrada animada dos cards e contadores animados no Perfil
  - Fade da resposta da IA sem reanimar a cada trecho do streaming
  - Revelação suave do campo personalizado de "Outro"
  - Vibração leve em troca de aba/tema e ao salvar/excluir
  - Animações respeitam a preferência de redução de movimento do sistema
- **Aparência**
  - Tema claro, escuro ou do sistema
  - Preferência salva no dispositivo
- **App Check**
  - Debug tokens registrados para Android e Web
  - Preparado para evoluir para Play Integrity/reCAPTCHA em produção

## Conta de demonstração

Para facilitar a avaliação, já existe uma conta com quatro lugares cadastrados (três visitados e um planejado) e dois históricos de IA:

- **E-mail:** `demo@passaporte.app`
- **Senha:** `Passaporte123!`

Também é possível criar uma conta nova pela tela de cadastro ou entrar com Google.

## Screenshots

| Login | Mapa |
| --- | --- |
| ![Login](docs/screenshots/login.png) | ![Mapa](docs/screenshots/mapa.png) |

| Diário | Status no formulário |
| --- | --- |
| ![Diário](docs/screenshots/diario.png) | ![Status](docs/screenshots/status.png) |

| Assistente de IA | Histórico da IA |
| --- | --- |
| ![IA](docs/screenshots/ia.png) | ![Histórico](docs/screenshots/historico.png) |

| Perfil | Layout web responsivo |
| --- | --- |
| ![Perfil](docs/screenshots/perfil.png) | ![Web](docs/screenshots/web.png) |

| Filtros e ordenação | Recuperação de senha |
| --- | --- |
| ![Filtros](docs/screenshots/filtros.png) | ![Recuperar senha](docs/screenshots/recuperar_senha.png) |

| Menu lateral | Adicionar no ponto do mapa |
| --- | --- |
| ![Menu](docs/screenshots/menu.png) | ![Ponto no mapa](docs/screenshots/ponto_mapa.png) |

| Como usar | Ver todos os lugares |
| --- | --- |
| ![Como usar](docs/screenshots/como_usar.png) | ![Ver todos](docs/screenshots/ver_todos.png) |

| Tema claro | Tema escuro |
| --- | --- |
| ![Tema claro](docs/screenshots/tema_claro.png) | ![Tema escuro](docs/screenshots/tema_escuro.png) |

| Zoom no mapa | Resposta em Markdown |
| --- | --- |
| ![Zoom](docs/screenshots/zoom.png) | ![Markdown](docs/screenshots/markdown.png) |

| Endereço preenchido automaticamente | IA adaptada ao tipo de lugar |
| --- | --- |
| ![Geocoding](docs/screenshots/geocoding.png) | ![IA detalhada](docs/screenshots/ia_detalhada.png) |

| Troca de ação limpa a resposta |
| --- |
| ![IA limpa](docs/screenshots/ia_limpeza.png) |

## Tecnologias

- Flutter 3.44 / Dart 3.12
- Firebase Auth, Cloud Firestore, Firebase AI Logic (Gemini) e Firebase App Check
- `flutter_map` + OpenStreetMap, `geolocator`, `latlong2`
- `http` + Nominatim (OpenStreetMap) para reverse geocoding
- `connectivity_plus` para o estado de conexão
- `shared_preferences` para a preferência de tema
- `flutter_markdown_plus` para renderizar as respostas da IA
- `google_fonts` (Fraunces e Inter), `intl`, `google_sign_in`
- APIs nativas de animação do Flutter (sem pacotes extras): `AnimatedSwitcher`,
  `AnimatedSize`, `TweenAnimationBuilder`, `Hero`, `Dismissible` e `PopScope`

## Estrutura do projeto

```text
lib/
  core/         tema, configurações de App Check/IA, categorias, formatadores
  models/       UserModel, Lugar, HistoricoIa
  services/     AuthService, LugarService, HistoricoIaService,
                IaService, LocalizacaoService, GeocodingService,
                ConectividadeService
  screens/      AuthGate, Login, Register, HomeShell, Mapa, Diário,
                Formulário, Detalhe, IA, Histórico da IA, Perfil
  components/   campos, cartão de lugar, estado vazio, seletor no mapa,
                entrada animada, contador animado
```

## Modelo de dados

```text
users/{uid}
  uid, displayName, email, photoUrl

users/{uid}/lugares/{lugarId}
  nome, descricao, categoria, avaliacao,
  dataVisita, latitude, longitude, endereco,
  status ("visitado" | "planejado"), criadoEm, atualizadoEm

users/{uid}/ia_historico/{historicoId}
  tipo ("dicas" | "roteiro" | "resumo"),
  lugarId (opcional), prompt, resposta, criadoEm
```

As regras do Firestore estão em `firestore.rules` e garantem que cada usuário só acessa os próprios documentos.

## Configuração do Firebase

Projeto utilizado:

- Project ID: `diario-viagens-tdm-jh`
- Android applicationId: `com.joaobirkheuer.diarioviagens`
- Web app registrado no Firebase

O arquivo `lib/firebase_options.dart` e o `android/app/google-services.json` já foram gerados com o FlutterFire CLI.

### App Check (importante)

Os tokens de debug do App Check são **segredos** e ficam no arquivo `dart_defines.json`, que não é versionado. Use o exemplo para recriar o seu:

```powershell
Copy-Item dart_defines.example.json dart_defines.json
```

Depois registre os tokens no Firebase:

```powershell
firebase appcheck:debugtokens:create --app <android-app-id> --display-name "Android debug" <token>
firebase appcheck:debugtokens:create --app <web-app-id> --display-name "Web debug" <token>
```

Sem os tokens, o Gemini não funciona porque o AI Logic exige App Check.

## Como executar

```powershell
flutter pub get

# Web
flutter run -d chrome --dart-define-from-file=dart_defines.json

# Android (com emulador ou dispositivo conectado)
flutter run -d <device-id> --dart-define-from-file=dart_defines.json
```

## Localização no emulador Android

1. Abra o emulador no Android Studio.
2. Clique nos três pontos `(...)` ao lado do emulador.
3. Abra a aba **Location**.
4. Informe a latitude e a longitude e clique em **Set Location**.

Exemplo para São Paulo: latitude `-23.550520`, longitude `-46.633308`.

Também é possível usar o terminal:

```powershell
adb emu geo fix -46.633308 -23.550520
```

No aplicativo, toque no botão **Centralizar em mim** no mapa. Se a permissão tiver sido negada, use o botão **Resolver** no card do mapa para abrir as configurações.

## Build e deploy

```powershell
flutter analyze
flutter test

flutter build web --release --dart-define-from-file=dart_defines.json
flutter build apk --release --dart-define-from-file=dart_defines.json

firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only hosting
```

## Observações

- O mapa usa OpenStreetMap, sem chave de API e sem cobrança. A atribuição ao OpenStreetMap é exibida no mapa.
- O reverse geocoding usa o Nominatim com cache em memória, debounce e User-Agent próprio. Use com moderação.
- O Gemini usa o **Gemini Developer API** pelo Firebase AI Logic. O tier gratuito é suficiente para o projeto acadêmico.
- Em produção, substitua os debug providers do App Check por Play Integrity (Android) e reCAPTCHA (Web), use uma assinatura de release própria e remova a conta demo.
- O APK em `dist/passaporte.apk` foi gerado em modo release, mas com assinatura de debug e App Check de debug para fins acadêmicos.
- A localização no Android usa `ACCESS_FINE_LOCATION` e `ACCESS_COARSE_LOCATION`, já declaradas no manifesto.
- O modo offline mantém os dados do Firestore em cache e enfileira escritas; os tiles do mapa não são armazenados offline nesta versão.
- A conectividade é monitorada com `connectivity_plus`, e o banner de offline aparece quando o dispositivo perde a rede.
- O tema padrão segue o sistema; a escolha do usuário fica salva em `shared_preferences`.
- As animações de tema, título, cards, contadores e resposta da IA usam apenas APIs
  nativas do Flutter e são desativadas quando o sistema pede redução de movimento
  (`MediaQuery.disableAnimations`).
- As respostas do Gemini são renderizadas como Markdown, então `**negrito**`, listas e títulos aparecem formatados.
- O `flutter_map` funciona em Android e Web; o histórico e o CRUD funcionam nas duas plataformas.
