# 🖥️ CJC System Monitor

Sistema integrado de monitoramento e telemetria de hardware e sistema operacional em tempo real, composto por um servidor daemon local de alto desempenho e um aplicativo cliente em Flutter & Dart projetado para operar como display contínuo de recursos em **tela única horizontal (Cockpit Landscape HUD)**, tela cheia imersiva e **launcher dedicado** no smartphone dedicado **LG Leon H342F** (Android 5.0.1 Lollipop).

---

## 🏛️ Arquitetura do Repositório

```
CjcSystemMonitor/
├── server/                 # Servidor Daemon Local (Node.js 22 + TypeScript)
│   ├── src/
│   │   ├── collector.ts    # Coletor de métricas nativas do sistema (systeminformation)
│   │   ├── websocket.ts    # Servidor WebSocket duplex (ws)
│   │   ├── types.ts        # Tipagens estritas de telemetria
│   │   └── index.ts        # Rotas Express REST e bootstrap (Porta TCP/UDP 4080)
│   ├── .env.example        # Modelo de variáveis de ambiente
│   └── package.json
│
└── mobile/                 # Aplicativo Mobile em Cockpit de Tela Única (Flutter & Dart)
    ├── android/            # Suporte ao Android 5.0.1+ (minSdk 21 / Desugaring / Home Launcher)
    ├── lib/
    │   ├── core/           # Auto-descoberta UDP IPv4, serviços de storage puro, tema Dark OLED
    │   ├── models/         # Modelos de dados fortemente tipados
    │   ├── providers/      # Gerenciamento de estado (MonitorProvider)
    │   ├── screens/        # HomeScreen (Cockpit Horizontal Panorâmico) e ConnectScreen
    │   └── widgets/        # Componentes reativos (gráficos fl_chart, matriz de núcleos)
    └── pubspec.yaml
```

---

## ⚡ Como Executar o Servidor (`server/`)

O servidor escuta por padrão na porta **`4080`** (conforme alocação livre do cofre `Servidor 192.168.3.177/Mapeamento de Portas`).

```powershell
cd server
npm install
npm run build
npm start
```
*Para desenvolvimento com recarregamento a quente:*
```powershell
npm run dev
```

### Endpoints Disponíveis:
- **`GET http://localhost:4080/api/status`**: Status do serviço e clientes conectados.
- **`GET http://localhost:4080/api/specs`**: Ficha técnica completa do hardware.
- **`GET http://localhost:4080/api/stats`**: Snapshot pontual da telemetria.
- **`WS ws://localhost:4080/ws`**: Canal de streaming contínuo a cada 1000ms.
- **`UDP 4080`**: Beacon de auto-descoberta IPv4 na rede local.

---

## 📱 Como Executar o Aplicativo Mobile (`mobile/`)

O aplicativo exibe **todas as estatísticas em uma única tela horizontal panorâmica sem rolagem**:
- **Coluna 1**: CPU (uso % neon, clock, temperatura) e matriz de 12 núcleos do Ryzen 5 3600.
- **Coluna 2**: Gráfico ao vivo deslizante (CPU/RAM), consumo de memória detalhado e unidades de disco (C:, D:, E:).
- **Coluna 3**: GPU Radeon RX 580 (8 GB), tráfego de rede Ethernet em tempo real, top processos e ficha do SO Windows 11.
- **Modo Kiosk**: Opera como Launcher padrão do dispositivo e auto-inicia no boot (`BOOT_COMPLETED`).

### Compilar e Instalar no LG Leon (Android 5.0.1 - Wi-Fi ADB `192.168.3.11:5555`):
```powershell
cd mobile
flutter build apk --release --android-skip-build-dependency-validation
adb -s 192.168.3.11:5555 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s 192.168.3.11:5555 shell am start -n com.cjcdev.systemmonitor/.MainActivity
```

---

## 🔒 Conformidade de Segurança e Mapeamento de Portas
- **Porta 4080**: Reservada na faixa de APIs e microsserviços Node.js sem conflito com portas existentes.
- **Auditoria de Segurança**: Em estrita conformidade com as diretrizes do Obsidian (`Auditoria de Segurança/JavaScript - TypeScript` e `Auditoria de Segurança/Flutter & Dart`).
- **Retrocompatibilidade Lollipop**: Core Library Desugaring habilitado para Java 8 em Android 5.0.1 (API 21) e interceptação nativa de eventos de hover para Scrcpy.
- **Documentação no Obsidian**: Consulte a pasta `CjcSystemMonitor/` no cofre para detalhes aprofundados.
