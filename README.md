# 🎮 MultiPeer Rhythm Game Controller

MVP de um sistema de controle para jogo de ritmo usando iPhones conectados à Apple TV via MultipeerConnectivity.

## 📋 Descrição

Este projeto demonstra a capacidade de conectar até 4 iPhones à Apple TV usando conexão local de baixa latência através do framework MultipeerConnectivity. Os iPhones funcionam como controles wireless para um jogo de ritmo.

## ✨ Funcionalidades

- **Conexão local de baixa latência** entre iPhones e Apple TV
- **Suporte para até 4 jogadores** simultâneos
- **Botão de controle responsivo** com feedback visual e háptico
- **Mensagens em tempo real** exibidas na TV quando os botões são pressionados
- **Seleção de número do jogador** (Player 1-4)
- **Interface moderna** com gradientes e animações
- **Compatível com Apple TV HD 4ª geração (2015)**

## 🏗️ Estrutura do Projeto

```
MultiPeerTest/
├── MultiPeerManager.swift      # Gerenciador de conexões MultipeerConnectivity
├── TV/                          # Target da Apple TV
│   ├── ContentView.swift        # Interface principal da TV
│   ├── MultiPeerTestApp.swift   # Entry point da TV
│   └── Info.plist              # Configurações da TV
└── iPhone/                      # Target do iPhone
    ├── PhoneContentView.swift   # Interface do controle
    ├── iPhoneApp.swift          # Entry point do iPhone
    └── Info.plist              # Configurações do iPhone
```

## 🚀 Como Configurar no Xcode

### 1. Configurar Target da Apple TV

1. Abra `MultiPeerTest.xcodeproj` no Xcode
2. Selecione o target "MultiPeerTest" (se já existir para TV) ou crie um novo:
   - File → New → Target → tvOS → App
   - Nome: "MultiPeerTest TV"
3. Adicione os arquivos à pasta TV:
   - `MultiPeerManager.swift` (compartilhado)
   - `TV/ContentView.swift`
   - `TV/MultiPeerTestApp.swift`
   - `TV/Info.plist`
4. Em Build Settings:
   - Deployment Target: tvOS 15.0 (compatível com Apple TV HD 2015)
5. Em Signing & Capabilities:
   - Adicione "Wireless Accessory Configuration" (se necessário)

### 2. Criar Target do iPhone

1. File → New → Target → iOS → App
2. Nome: "MultiPeerTest iPhone"
3. Adicione os arquivos:
   - `MultiPeerManager.swift` (compartilhado entre ambos os targets)
   - `iPhone/PhoneContentView.swift`
   - `iPhone/iPhoneApp.swift`
   - `iPhone/Info.plist`
4. Em Build Settings:
   - Deployment Target: iOS 15.0 ou superior
5. Em Signing & Capabilities:
   - Configure seu Team
   - Adicione "Wireless Accessory Configuration" (se necessário)

### 3. Verificar Permissões

Certifique-se de que ambos os Info.plist contêm:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Este app precisa acessar a rede local para conectar dispositivos.</string>
<key>NSBonjourServices</key>
<array>
    <string>_rhythm-game._tcp</string>
    <string>_rhythm-game._udp</string>
</array>
```

## 🎯 Como Usar

### Na Apple TV:

1. Execute o app "MultiPeerTest TV" na Apple TV
2. O servidor iniciará automaticamente
3. A tela mostrará "Servidor Ativo" e "0/4 Jogadores"
4. Aguarde os iPhones se conectarem

### No iPhone:

1. Execute o app "MultiPeerTest iPhone" no iPhone
2. O app automaticamente começará a procurar a Apple TV
3. Quando conectar, o status mudará para "Conectado à TV"
4. Selecione seu número de jogador (1-4) tocando no botão "Player X"
5. Pressione e segure o botão grande no centro
6. A mensagem aparecerá na TV: "Player_X pressionou o botão!"

## 🔧 Tecnologias Utilizadas

- **Swift & SwiftUI** - Interface moderna e declarativa
- **MultipeerConnectivity** - Conexão peer-to-peer de baixa latência
- **Combine** - Gerenciamento reativo de estados
- **UIKit** (parcial) - Feedback háptico

## 📊 Características Técnicas

- **Latência**: < 50ms (típica em rede local)
- **Número máximo de peers**: 8 (limitado pelo MultipeerConnectivity)
- **Modo de criptografia**: None (para menor latência)
- **Modo de entrega**: Reliable (garante entrega das mensagens)
- **Auto-descoberta**: Sim (via Bonjour)
- **Auto-conexão**: Sim (aceita automaticamente convites)

## ⚠️ Requisitos

- Xcode 14.0 ou superior
- iOS 15.0+ para iPhone
- tvOS 15.0+ para Apple TV (compatível com Apple TV HD 2015)
- Apple TV e iPhones na mesma rede Wi-Fi

## 🎨 Interface

### Apple TV:
- Tela grande com gradiente roxo-azul
- Contador de jogadores conectados
- Lista de mensagens em tempo real
- Botões para controlar o servidor

### iPhone:
- Botão circular grande e responsivo
- Efeitos visuais ao pressionar (escala, cor, sombra)
- Feedback háptico ao tocar
- Seletor de número do jogador
- Indicador de status de conexão

## 🔮 Próximos Passos (Além do MVP)

- [ ] Adicionar autenticação de jogadores
- [ ] Implementar sincronização de tempo para o jogo de ritmo
- [ ] Adicionar diferentes tipos de controles/botões
- [ ] Implementar sistema de pontuação
- [ ] Adicionar sons e música
- [ ] Criar gameplay do jogo de ritmo
- [ ] Otimizar ainda mais a latência
- [ ] Adicionar modo de calibração de latência

## 📝 Notas

Este é um **MVP (Minimum Viable Product)** criado para demonstrar a viabilidade técnica de usar MultipeerConnectivity para controles wireless em jogos de ritmo na Apple TV. O foco está na conexão de baixa latência e na comunicação básica entre dispositivos.

## 👨‍💻 Autor

Criado para o projeto Mini4 - Usos Atípicos

