# Family Beacon

Application mobile Flutter de surveillance pour les aînés qui vivent seuls. 
Détecte les anomalies de routine (sommeil, repas, sorties) via capteurs IoT et envoie des alertes aux aidants via cette application.

## Stack

- **Flutter** (Dart) — mobile Android
- **Riverpod 2.x** — gestion d'état
- **MQTT + HTTP polling** — communication temps réel avec le backend
- **Firebase Cloud Messaging** — notifications push (désactivé en debug)

## Architecture

```
lib/
├── core/
│   ├── backend/          # Providers MQTT + HTTP (liveAlertsProvider, etc.)
│   ├── domain/           # Enums métier : AnomalyType, ActivityType
│   ├── services/         # SettingsService (settingsServiceProvider)
│   └── theme/            # AppTheme, AppPalette (ThemeExtension)
└── features/
    ├── home/             # Tableau de bord principal
    ├── journal/          # Timeline activités observées vs. journée type
    ├── anomalies/        # Liste et détail des anomalies
    ├── alertes/          # Alertes temps réel
    ├── analyse/          # Statistiques comportementales
    └── plan/             # Localisation (plan de l'habitat)
```

## Lancer en local

```bash
flutter pub get
flutter run
```

## Builder l'APK

```powershell
./build-apk -ApiHost <IP_SERVEUR> -ApkName FamilyBeacon.apk
```

> Nécessite `android/local.properties` avec `sdk.dir` configuré.
