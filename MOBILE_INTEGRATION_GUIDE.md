# FamilyBeacon — Guide d'intégration application mobile

Ce document décrit comment connecter l'application mobile au système FamilyBeacon pour :
1. **Recevoir les alertes d'anomalies** via MQTT
2. **Afficher les données** depuis la base de données TimescaleDB

---

## 📋 Vue d'ensemble de l'architecture

```
┌─────────────────────┐
│  Capteurs IoT       │
│  (simulés)          │
└──────────┬──────────┘
           │ Publish sur topic "events"
           ▼
┌─────────────────────┐
│  MQTT Broker        │
│  (Mosquitto)        │
│  Port: 1883         │
└──────────┬──────────┘
           │ Subscribe "events"
           ▼
┌─────────────────────┐        ┌─────────────────────┐
│  Backend Python     │───────►│  TimescaleDB        │
│  - ML inference     │ Store  │  (PostgreSQL 15)    │
│  - Détection        │        │  Port: 5432         │
│    d'anomalies      │        └─────────────────────┘
└──────────┬──────────┘                   ▲
           │ Publish "alerts"              │
           ▼                                │ SQL queries
┌─────────────────────┐                   │
│  Application        │───────────────────┘
│  Mobile             │ Subscribe "alerts"
│                     │
│  - Notifications    │
│  - Visualisation    │
└─────────────────────┘
```

---

## 🔌 1. Connexion MQTT (Notifications d'alertes)

### Configuration de connexion

```
Broker: <IP_DU_SERVEUR>
Port: 1883
Protocol: MQTT v3.1.1
QoS: 1 (recommandé pour les alertes)
```

**Important**: Remplacez `<IP_DU_SERVEUR>` par l'adresse IP de la machine hébergeant l'infrastructure Docker.

### Topic à écouter

```
Topic: alerts
```

### Format des messages d'alerte

Chaque alerte est publiée au format JSON avec la structure suivante :

```json
{
  "timestamp": "2023-11-15T14:32:45.123Z",
  "type": "missing" | "timing" | "duration_short" | "duration_long" | "toilet_timing" | "toilet_frequency_low" | "toilet_frequency_high" | "toilet_duration_long",
  "room": "petit_dejeuner" | "dejeuner" | "souper" | "toilette",
  "message": "Description lisible de l'anomalie"
}
```

### Types d'anomalies

| Type | Room | Description |
|------|------|-------------|
| `missing` | `petit_dejeuner`, `dejeuner`, `souper` | Repas absent (non détecté dans la fenêtre habituelle) |
| `timing` | `petit_dejeuner`, `dejeuner`, `souper` | Repas pris à une heure inhabituelle |
| `duration_short` | `petit_dejeuner`, `dejeuner`, `souper` | Repas trop court par rapport à la normale |
| `duration_long` | `petit_dejeuner`, `dejeuner`, `souper` | Repas trop long par rapport à la normale |
| `toilet_timing` | `toilette` | Passage aux toilettes en dehors des plages horaires habituelles |
| `toilet_frequency_low` | `toilette` | Trop peu de passages aux toilettes sur une plage horaire |
| `toilet_frequency_high` | `toilette` | Trop de passages aux toilettes sur une plage horaire |
| `toilet_duration_long` | `toilette` | Temps aux toilettes anormalement long |

### Exemple de messages

**Repas manquant :**
```json
{
  "timestamp": "2023-11-15T08:45:00.000Z",
  "type": "missing",
  "room": "petit_dejeuner",
  "message": "🍳 Anomalie petit_dejeuner : repas manquant (non détecté dans la fenêtre habituelle)."
}
```

**Repas à une heure inhabituelle :**
```json
{
  "timestamp": "2023-11-15T13:20:00.000Z",
  "type": "timing",
  "room": "dejeuner",
  "message": "🍽️ Anomalie dejeuner : heure inhabituelle (score de similarité temporelle: 0.12)"
}
```

**Durée anormale :**
```json
{
  "timestamp": "2023-11-15T19:05:00.000Z",
  "type": "duration_long",
  "room": "souper",
  "message": "🥗 Anomalie souper : durée trop longue (ratio: 2.3 vs normal: 1.0)"
}
```

**Anomalie toilettes - fréquence :**
```json
{
  "timestamp": "2023-11-15T22:15:00.000Z",
  "type": "toilet_frequency_high",
  "room": "toilette",
  "message": "🚽 Anomalie toilette [21h-0h] : fréquence élevée (8 passages vs 3±1 normalement)."
}
```

### Code d'exemple (conceptuel)

```javascript
// Exemple avec une bibliothèque MQTT (mqtt.js, paho-mqtt, etc.)
const client = mqtt.connect('mqtt://<IP_DU_SERVEUR>:1883');

client.on('connect', () => {
  console.log('Connecté au broker MQTT');
  client.subscribe('alerts', { qos: 1 });
});

client.on('message', (topic, message) => {
  if (topic === 'alerts') {
    const alert = JSON.parse(message.toString());
    // Afficher une notification push
    showPushNotification(alert);
    // Stocker en local pour historique
    storeAlertLocally(alert);
  }
});
```

---

## 🗄️ 2. Connexion à la base de données (Visualisation des données)

### Configuration de connexion

```
Type: PostgreSQL 15 (avec extension TimescaleDB)
Host: <IP_DU_SERVEUR>
Port: 5432
Database: familybeacon
User: postgres
Password: postgres
```

**Note de sécurité**: En production, il faudra créer un utilisateur avec des droits en lecture seule et utiliser un mot de passe sécurisé.

### Schéma des tables principales

#### Table `sensor_events` (Hypertable TimescaleDB)

Contient tous les événements capteurs horodatés.

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | BIGSERIAL | Identifiant unique |
| `timestamp` | TIMESTAMPTZ | Horodatage de l'événement |
| `room` | TEXT | Pièce du capteur (ex: "kitchen", "bathroom", "bedroom") |
| `sensor_type` | TEXT | Type de capteur (ex: "motion", "door", "temperature") |
| `value` | TEXT | Valeur du capteur (ex: "ON", "OFF", "23.5") |

**Exemple de requête** : Récupérer les 50 derniers événements

```sql
SELECT timestamp, room, sensor_type, value 
FROM sensor_events 
ORDER BY timestamp DESC 
LIMIT 50;
```

#### Table `daily_activities`

Contient les activités détectées par le modèle ML.

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | SERIAL | Identifiant unique |
| `date` | DATE | Date de l'activité |
| `activity` | TEXT | Nom de l'activité ("petit_dejeuner", "dejeuner", "souper") |
| `start_time` | TIME | Heure de début |
| `end_time` | TIME | Heure de fin (NULL si en cours) |
| `state` | TEXT | État de l'activité (voir ci-dessous) |

**États possibles** (colonne `state`) :

| État | Description |
|------|-------------|
| `normal` | Activité normale |
| `long_duration` | Durée anormalement longue |
| `short_duration` | Durée anormalement courte |
| `weird_time` | Heure inhabituelle |
| `missing_meal` | Repas manquant |
| `extra_meal` | Repas supplémentaire |

**Exemple de requête** : Récupérer les activités des 7 derniers jours

```sql
SELECT date, activity, start_time, end_time, state
FROM daily_activities
WHERE date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY date DESC, start_time DESC;
```

**Exemple de requête** : Activités du jour en cours

```sql
SELECT activity, start_time, end_time, state
FROM daily_activities
WHERE date = CURRENT_DATE
ORDER BY start_time;
```

#### Table `notifications`

Historique de toutes les alertes émises.

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | SERIAL | Identifiant unique |
| `timestamp` | TIMESTAMPTZ | Date/heure de l'alerte |
| `message` | TEXT | Message d'alerte (identique à celui publié sur MQTT) |

**Exemple de requête** : Récupérer les 100 dernières notifications

```sql
SELECT id, timestamp, message
FROM notifications
ORDER BY timestamp DESC
LIMIT 100;
```

**Exemple de requête** : Notifications du jour

```sql
SELECT timestamp, message
FROM notifications
WHERE timestamp >= CURRENT_DATE
ORDER BY timestamp DESC;
```

#### Table `routine_history`

Historique des profils de routine construits.

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | SERIAL | Identifiant unique |
| `state` | BOOLEAN | true = routine active, false = routine archivée |
| `start_date` | TIMESTAMPTZ | Date de début de validité |
| `end_date` | TIMESTAMPTZ | Date de fin (NULL si routine en cours) |

**Note**: Cette table sert principalement au backend pour reconstruire les profils.

---

## 📊 3. Requêtes SQL recommandées pour l'application mobile

### Vue d'ensemble du jour

```sql
-- Résumé des activités du jour
SELECT 
  activity,
  start_time,
  end_time,
  CASE 
    WHEN end_time IS NULL THEN 'En cours'
    ELSE EXTRACT(EPOCH FROM (end_time - start_time)) / 60 || ' min'
  END as duration,
  state
FROM daily_activities
WHERE date = CURRENT_DATE
ORDER BY start_time;
```

### Historique d'activité (graphique)

```sql
-- Activités des 30 derniers jours avec leur état
SELECT 
  date,
  activity,
  start_time,
  end_time,
  state,
  EXTRACT(EPOCH FROM (COALESCE(end_time, start_time) - start_time)) / 60 as duration_minutes
FROM daily_activities
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY date DESC, start_time;
```

### Compteur d'anomalies

```sql
-- Nombre d'anomalies par type pour les 7 derniers jours
SELECT 
  date,
  COUNT(*) FILTER (WHERE state != 'normal') as anomaly_count,
  COUNT(*) FILTER (WHERE state = 'missing_meal') as missing_meals,
  COUNT(*) FILTER (WHERE state = 'weird_time') as weird_times,
  COUNT(*) FILTER (WHERE state = 'long_duration') as long_durations,
  COUNT(*) FILTER (WHERE state = 'short_duration') as short_durations
FROM daily_activities
WHERE date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY date
ORDER BY date DESC;
```

### Dernières alertes non lues

```sql
-- Alertes des dernières 24h
SELECT 
  id,
  timestamp,
  message,
  EXTRACT(EPOCH FROM (NOW() - timestamp)) / 60 as minutes_ago
FROM notifications
WHERE timestamp >= NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC;
```

### Activité en temps réel (polling)

```sql
-- Pour un rafraîchissement régulier, récupérer les nouvelles activités
-- Stocker le dernier id vu côté client, puis :
SELECT id, date, activity, start_time, end_time, state
FROM daily_activities
WHERE id > :last_seen_id
ORDER BY id;
```

---

## 🔄 4. Stratégie de rafraîchissement des données

### Option A : Polling régulier (simple)

Interroger la base de données toutes les 2-5 secondes pour les nouvelles activités :

```javascript
let lastActivityId = 0;
let lastNotificationId = 0;

setInterval(async () => {
  // Récupérer nouvelles activités
  const newActivities = await db.query(
    'SELECT * FROM daily_activities WHERE id > $1 ORDER BY id',
    [lastActivityId]
  );
  
  if (newActivities.length > 0) {
    updateUI(newActivities);
    lastActivityId = newActivities[newActivities.length - 1].id;
  }
  
  // Récupérer nouvelles notifications
  const newNotifications = await db.query(
    'SELECT * FROM notifications WHERE id > $1 ORDER BY id',
    [lastNotificationId]
  );
  
  if (newNotifications.length > 0) {
    showNotifications(newNotifications);
    lastNotificationId = newNotifications[newNotifications.length - 1].id;
  }
}, 3000); // 3 secondes
```

### Option B : Server-Sent Events (streaming)

Le dashboard FastAPI expose déjà un endpoint SSE pour le streaming en temps réel :

```
GET http://<IP_DU_SERVEUR>:8080/stream
```

**Format du stream** :

```
data: {"activities": [...], "notifications": [...], "new_activity_ids": [123, 124], "new_notif_ids": [45]}

data: {"activities": [...], "notifications": [...], "new_activity_ids": [125], "new_notif_ids": [46]}
```

**Exemple d'intégration** :

```javascript
const eventSource = new EventSource('http://<IP_DU_SERVEUR>:8080/stream');

eventSource.onmessage = (event) => {
  const data = JSON.parse(event.data);
  
  // Mettre à jour l'interface avec les nouvelles données
  updateActivities(data.activities);
  updateNotifications(data.notifications);
  
  // Highlight des nouvelles entrées
  highlightNewItems(data.new_activity_ids);
};
```

### Option C : MQTT pour le temps réel + BDD pour l'historique

**Recommandé** : Combiner MQTT (alertes instantanées) + polling BDD (données complètes) :

1. **MQTT** → Subscribe `alerts` pour les notifications push immédiates
2. **BDD polling** → Interroger `daily_activities` toutes les 10-30 secondes pour mettre à jour l'affichage
3. **BDD on-demand** → Charger l'historique (30 jours) uniquement quand l'utilisateur ouvre la vue historique

---

## 🧪 5. Environnement de test

### Configuration TIME_SCALE

Le système utilise un facteur d'accélération temporelle (`TIME_SCALE=426`) pour les tests :

- **1 seconde réelle = 7.1 minutes simulées**
- **15 minutes réelles ≈ 1 journée complète simulée**

Cela permet de tester rapidement les détections d'anomalies et les alertes.

### Jeu de données

Le système précharge :
- **29 jours normaux** (seed) → données historiques chargées directement en BDD
- **Jours anormaux** (data-generator) → événements publiés via MQTT pour tester la détection

### Scénarios de test

Le système génère automatiquement des anomalies de type :
- Repas manquants
- Repas décalés dans le temps
- Repas trop courts ou trop longs
- Fréquence anormale aux toilettes

Vous pouvez surveiller les logs backend pour voir les détections en temps réel :

```bash
docker compose logs -f backend
```

---

## 🎨 6. Interface utilisateur recommandée

### Écran principal : Vue du jour

- **Ligne du temps** : Afficher les 3 repas de la journée (petit_dejeuner, dejeuner, souper)
- **Indicateurs visuels** :
  - ✅ Vert : activité normale
  - ⚠️ Orange : anomalie mineure (durée, heure)
  - 🔴 Rouge : anomalie majeure (repas manquant)
- **Badge** : Nombre d'alertes non lues
- **Rafraîchissement** : Pull-to-refresh manuel + auto-refresh toutes les 10s

### Écran notifications

- **Liste des alertes** : Ordre chronologique inversé (plus récentes en haut)
- **Icônes par type** :
  - 🍳 Petit-déjeuner
  - 🍽️ Déjeuner
  - 🥗 Souper
  - 🚽 Toilettes
- **Filtres** : Aujourd'hui / 7 derniers jours / 30 derniers jours
- **Badge de gravité** : Normal / Attention / Urgent

### Écran historique

- **Graphique calendrier** : Vue mensuelle avec des points colorés par jour
  - Vert : jour normal
  - Orange : 1-2 anomalies
  - Rouge : 3+ anomalies
- **Détail par jour** : Tap sur un jour pour voir les activités et alertes

### Écran événements capteurs (optionnel)

- **Liste en temps réel** : Flux des événements capteurs bruts
- **Filtres** : Par pièce, par type de capteur
- **Utile pour** : Debugging, compréhension du système

---

## 🔒 7. Considérations de sécurité

### Pour la production

1. **Base de données** :
   - Créer un utilisateur PostgreSQL en lecture seule
   - Utiliser SSL/TLS pour la connexion
   - Restreindre l'accès par IP

2. **MQTT** :
   - Activer l'authentification (username/password)
   - Configurer TLS/SSL (port 8883)
   - Restreindre les topics accessibles

3. **Réseau** :
   - Utiliser un VPN ou un tunnel sécurisé
   - Ne pas exposer directement les ports sur Internet
   - Envisager un reverse proxy avec authentification

### Exemple de configuration sécurisée

```javascript
// PostgreSQL avec SSL
const db = new Client({
  host: '<IP_DU_SERVEUR>',
  port: 5432,
  database: 'familybeacon',
  user: 'mobile_readonly',
  password: '<MOT_DE_PASSE_FORT>',
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync('ca-cert.pem').toString(),
  },
});

// MQTT avec authentification
const client = mqtt.connect('mqtts://<IP_DU_SERVEUR>:8883', {
  username: 'mobile_client',
  password: '<MOT_DE_PASSE_FORT>',
  ca: fs.readFileSync('ca-cert.pem'),
});
```

---

## 🚀 8. Checklist d'intégration

### Étape 1 : Configuration réseau
- [ ] Obtenir l'IP du serveur hébergeant l'infrastructure
- [ ] Vérifier que les ports 1883 (MQTT) et 5432 (PostgreSQL) sont accessibles
- [ ] Tester la connexion avec un client MQTT (ex: MQTT Explorer)
- [ ] Tester la connexion PostgreSQL (ex: DBeaver, psql)

### Étape 2 : Intégration MQTT
- [ ] Choisir une bibliothèque MQTT compatible avec votre stack mobile
- [ ] Implémenter la connexion au broker
- [ ] S'abonner au topic `alerts`
- [ ] Parser les messages JSON
- [ ] Afficher une notification push locale lors de la réception d'une alerte

### Étape 3 : Intégration BDD
- [ ] Choisir un driver PostgreSQL (ex: pg, node-postgres, psycopg2, etc.)
- [ ] Implémenter la connexion à la base
- [ ] Tester les requêtes SQL de base (daily_activities, notifications)
- [ ] Implémenter le polling ou le SSE pour le rafraîchissement

### Étape 4 : Interface utilisateur
- [ ] Créer l'écran principal avec les activités du jour
- [ ] Créer l'écran notifications
- [ ] Créer l'écran historique
- [ ] Ajouter les indicateurs visuels (couleurs, badges)

### Étape 5 : Tests
- [ ] Tester la réception des alertes MQTT en temps réel
- [ ] Tester le rafraîchissement des données depuis la BDD
- [ ] Vérifier le comportement en cas de perte de connexion
- [ ] Tester avec le jeu de données accéléré (TIME_SCALE=426)

---

## 📞 9. Support et ressources

### Endpoints utiles

| Ressource | URL | Description |
|-----------|-----|-------------|
| Dashboard web | http://\<IP\>:8080 | Interface de visualisation existante |
| API activities | http://\<IP\>:8080/api/activities | Snapshot JSON des activités |
| API notifications | http://\<IP\>:8080/api/notifications | Snapshot JSON des alertes |
| SSE stream | http://\<IP\>:8080/stream | Flux temps réel (Server-Sent Events) |
| Adminer | http://\<IP\>:8081 | Interface d'administration BDD |

### Fichiers de référence dans le repo

- `docker-compose.yml` : Configuration complète des services
- `db/init.sql` : Schéma de la base de données
- `backend/mqtt_consumer.py` : Exemple de consommation MQTT
- `backend/anomaly/alerter.py` : Logique d'émission des alertes
- `dashboard/main.py` : API REST et SSE existantes

### Commandes Docker utiles

```bash
# Démarrer l'infrastructure
docker compose up -d

# Voir les logs du backend (alertes)
docker compose logs -f backend

# Voir les logs MQTT
docker compose logs -f mosquitto

# Redémarrer un service
docker compose restart backend

# Arrêter tout
docker compose down
```

---

## 📄 Annexe : Exemples de réponses API

### GET /api/activities

```json
[
  {
    "id": 1234,
    "date": "2023-11-15",
    "activity": "petit_dejeuner",
    "start_time": "07:30:00",
    "end_time": "07:55:00",
    "state": "normal"
  },
  {
    "id": 1235,
    "date": "2023-11-15",
    "activity": "dejeuner",
    "start_time": "12:10:00",
    "end_time": "12:45:00",
    "state": "normal"
  },
  {
    "id": 1236,
    "date": "2023-11-15",
    "activity": "souper",
    "start_time": "19:05:00",
    "end_time": null,
    "state": "normal"
  }
]
```

### GET /api/notifications

```json
[
  {
    "id": 45,
    "timestamp": "2023-11-15T08:45:12.345Z",
    "message": "🍳 Anomalie petit_dejeuner : repas manquant (non détecté dans la fenêtre habituelle)."
  },
  {
    "id": 46,
    "timestamp": "2023-11-15T13:20:30.678Z",
    "message": "🍽️ Anomalie dejeuner : heure inhabituelle (score de similarité temporelle: 0.12)"
  }
]
```

### GET /stream (SSE)

```
data: {"activities": [...], "notifications": [...], "new_activity_ids": [1237], "new_notif_ids": [47]}

data: {"activities": [...], "notifications": [...], "new_activity_ids": [], "new_notif_ids": [48]}
```

---

## 🏁 Résumé rapide

**Ce dont vous avez besoin :**

1. **MQTT** :
   - Broker : `mqtt://<IP>:1883`
   - Topic : `alerts`
   - Format : JSON avec `timestamp`, `type`, `room`, `message`

2. **PostgreSQL** :
   - Host : `<IP>:5432`
   - Database : `familybeacon`
   - User : `postgres` / Password : `postgres`
   - Tables principales : `daily_activities`, `notifications`, `sensor_events`

3. **Stratégie recommandée** :
   - MQTT pour les notifications push instantanées
   - Polling BDD (10-30s) pour rafraîchir l'affichage des activités
   - API REST (`/api/activities`, `/api/notifications`) pour les snapshots

**Bon développement ! 🚀**
