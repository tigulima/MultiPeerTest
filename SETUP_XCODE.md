# 🔧 Guia Rápido de Configuração do Xcode

## Passos para Configurar os Targets

### 1️⃣ Configurar o Target da Apple TV (já existente)

1. Abra o arquivo `MultiPeerTest.xcodeproj` no Xcode
2. Selecione o target existente da TV
3. Em **General** → **Deployment Info**:
   - Defina o Deployment Target como **tvOS 15.0**
4. Em **Build Phases** → **Compile Sources**, adicione:
   - `MultiPeerManager.swift`
   - `TV/ContentView.swift`
   - `TV/MultiPeerTestApp.swift`
5. Em **Build Phases** → **Copy Bundle Resources**, adicione:
   - `TV/Assets.xcassets`
   - `TV/Info.plist`
6. Em **Build Settings**:
   - Procure por "Info.plist File"
   - Defina como: `TV/Info.plist`
7. Em **Signing & Capabilities**:
   - Selecione seu Team
   - Deixe o Bundle Identifier como está ou ajuste se necessário

### 2️⃣ Criar o Target do iPhone

1. No Xcode, vá em **File** → **New** → **Target**
2. Selecione **iOS** → **App** → **Next**
3. Configure:
   - **Product Name**: `MultiPeerTest iPhone`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Bundle Identifier**: `com.seudominio.MultiPeerTest-iPhone`
   - Clique em **Finish**
   - Na janela que aparece, clique em **Activate** para ativar o scheme

4. **Remover arquivos padrão criados**:
   - Xcode criou arquivos padrão que não precisamos
   - Delete os arquivos criados automaticamente na pasta do novo target

5. **Adicionar arquivos corretos**:
   - Selecione o target "MultiPeerTest iPhone"
   - Em **Build Phases** → **Compile Sources**, adicione:
     - `MultiPeerManager.swift` (marque ambos os targets se perguntado)
     - `iPhone/PhoneContentView.swift`
     - `iPhone/iPhoneApp.swift`

6. Em **Build Phases** → **Copy Bundle Resources**, adicione:
   - `iPhone/Assets.xcassets`
   - `iPhone/Info.plist`

7. Em **Build Settings**:
   - Procure por "Info.plist File"
   - Defina como: `iPhone/Info.plist`

8. Em **General** → **Deployment Info**:
   - Defina o Deployment Target como **iOS 15.0**
   - Em **Supported Destinations**, selecione: iPhone

9. Em **Signing & Capabilities**:
   - Selecione seu Team
   - O Bundle Identifier já está configurado

### 3️⃣ Configurar Compartilhamento do MultiPeerManager

1. Selecione `MultiPeerManager.swift` no Project Navigator
2. No **File Inspector** (painel direito):
   - Em **Target Membership**, marque ambos os checkboxes:
     - ✅ MultiPeerTest (TV)
     - ✅ MultiPeerTest iPhone

### 4️⃣ Verificar Info.plist

Certifique-se de que ambos os Info.plist têm as permissões corretas:

**TV/Info.plist** e **iPhone/Info.plist** devem conter:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Este app precisa acessar a rede local para conectar dispositivos.</string>
<key>NSBonjourServices</key>
<array>
    <string>_rhythm-game._tcp</string>
    <string>_rhythm-game._udp</string>
</array>
```

### 5️⃣ Configurar Schemes

1. Clique no menu de schemes (próximo ao botão de Play/Stop)
2. Você deve ver dois schemes:
   - **MultiPeerTest** (para Apple TV)
   - **MultiPeerTest iPhone** (para iPhone)
3. Para cada scheme, verifique o destino:
   - Apple TV scheme → Selecione simulador ou dispositivo Apple TV
   - iPhone scheme → Selecione simulador ou dispositivo iPhone

## ▶️ Como Executar

### Testar com Simuladores:

**⚠️ IMPORTANTE**: MultipeerConnectivity **NÃO funciona em simuladores**. Você precisa usar dispositivos reais.

### Testar com Dispositivos Reais:

1. **Apple TV**:
   - Conecte sua Apple TV à mesma rede Wi-Fi
   - Em Settings → Remotes and Devices → Remote App and Devices
   - Conecte via Xcode (Window → Devices and Simulators)
   - Selecione o scheme "MultiPeerTest"
   - Selecione sua Apple TV como destino
   - Clique em Play (▶️)

2. **iPhone**:
   - Conecte seu iPhone via cabo ou Wi-Fi
   - Selecione o scheme "MultiPeerTest iPhone"
   - Selecione seu iPhone como destino
   - Clique em Play (▶️)

3. **Testar a conexão**:
   - Execute primeiro o app na Apple TV
   - Depois execute no iPhone
   - O iPhone deve conectar automaticamente à TV
   - Pressione o botão no iPhone
   - Veja a mensagem aparecer na TV! 🎉

## 🐛 Troubleshooting

### "Cannot find type 'MultiPeerManager' in scope"

**Solução**: Verifique se `MultiPeerManager.swift` está marcado para ambos os targets em Target Membership.

### "Info.plist not found"

**Solução**: Em Build Settings, verifique se o caminho do Info.plist está correto:
- TV: `TV/Info.plist`
- iPhone: `iPhone/Info.plist`

### "Failed to register bundle identifier"

**Solução**: Altere o Bundle Identifier em Signing & Capabilities para algo único (ex: adicione seu nome ou iniciais).

### Dispositivos não se conectam

**Soluções**:
1. Certifique-se de que ambos estão na mesma rede Wi-Fi
2. Verifique se o Info.plist tem as permissões corretas
3. Reinicie ambos os apps
4. Na primeira execução, aceite o alerta de permissão de rede local
5. Verifique se o firewall não está bloqueando a conexão

### App crasha ao iniciar

**Solução**: Verifique se todos os arquivos Swift estão sendo compilados corretamente em Build Phases → Compile Sources.

## 📱 Testar com Múltiplos iPhones

Para testar com até 4 iPhones:

1. Execute o app em cada iPhone separadamente
2. Cada iPhone selecionará seu número de jogador (1-4)
3. Todos conectarão automaticamente à Apple TV
4. Cada botão pressionado aparecerá na TV com o identificador correto

## ✅ Checklist de Configuração

- [ ] Target da TV configurado com deployment target tvOS 15.0
- [ ] Target do iPhone criado com deployment target iOS 15.0
- [ ] MultiPeerManager.swift está em ambos os targets
- [ ] Info.plist configurados com permissões corretas
- [ ] Schemes configurados corretamente
- [ ] Team de desenvolvimento selecionado
- [ ] Dispositivos reais disponíveis para teste (simuladores não funcionam!)
- [ ] Ambos os dispositivos na mesma rede Wi-Fi

## 🎯 Resultado Esperado

Quando tudo estiver funcionando:

✅ Apple TV mostra "Servidor Ativo"
✅ iPhone mostra "Conectado à TV"
✅ Ao pressionar o botão no iPhone, a mensagem aparece instantaneamente na TV
✅ Latência baixa (< 50ms)
✅ Feedback háptico no iPhone ao pressionar

---

**Dica**: Se você tiver problemas, comece testando com apenas 1 iPhone e 1 Apple TV. Depois de funcionar, adicione mais iPhones.

