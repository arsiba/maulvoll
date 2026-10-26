# Maulvoll

Interaktive Blindverkostungen mit Host-Pult, TV-Dashboard und Smartphone-Controllern. Rails 8.1, Hotwire, Solid Cable, Bootstrap 5 und SQLite.

## 1. Gems und Einrichtung

Die Abhängigkeiten stehen im [Gemfile](Gemfile). Ruby und Node richten sich nach `.ruby-version` und `.node-version`; Yarn 1.22 wird benötigt.

Für Bash:

```bash
bundle install
yarn install --frozen-lockfile
bin/rails db:prepare
export ADMIN_EMAIL="host@maulvoll.local"
read -rsp "Admin-Passwort mit mindestens 14 Zeichen: " ADMIN_PASSWORD
export ADMIN_PASSWORD
bin/rails db:seed
unset ADMIN_PASSWORD
yarn build:css
bin/dev
```


Für Fish ersetzt du die Admin-Anlage durch diese Befehle. Das Passwort wird verdeckt abgefragt und anschließend aus der Shell-Umgebung entfernt:

```fish
set -gx ADMIN_EMAIL "host@maulvoll.local"
read --silent --export --prompt-str "Admin-Passwort mit mindestens 14 Zeichen: " ADMIN_PASSWORD
bin/rails db:seed
set -e ADMIN_PASSWORD
```

`http://localhost:3000/session/new` öffnet den Host-Login. Ohne Admin-Variablen legt `db:prepare` nur die drei Produktvorlagen an. Mit `ADMIN_EMAIL` und `ADMIN_PASSWORD` erzeugt `db:seed` zusätzlich das Host-Konto und die spielfertige Maultaschen-Verkostung mit sechs Runden. Es gibt kein Standardpasswort. Seeds sind wiederholbar; bestehende Passwörter und Verkostungen werden dabei nicht zurückgesetzt. Die Beispielmarken lassen sich vor dem Start im Host-Pult bearbeiten.

Ein weiteres Host-Konto kann in `bin/rails console` mit `User.create!(email_address: ..., password: ...)` angelegt werden. Passwortänderungen erfolgen ebenfalls über die Console; anschließend mit `user.sessions.destroy_all` bestehende Logins widerrufen. Es gibt keine öffentliche Registrierung oder Passwort-Reset-Route.

## 2. Sicherheit und Betrieb

[Rack Attack](config/initializers/rack_attack.rb) begrenzt POSTs auf Login auf 5, Join auf 10 und Bewertungen auf 20 pro Minute und IP, jeweils über alle Verkostungen hinweg. Produktiv ist ein eigener Redis-Dienst erforderlich. Ausfälle dieses Zählers führen zu einem Fehler statt zu unlimitiert durchgereichten Anfragen. Geräte hinter derselben NAT-Adresse teilen diese Limits.

[CSP](config/initializers/content_security_policy.rb), CSRF-Prüfung, verschlüsselte Teilnehmer-Cookies, signierte Host-Cookies, HTTPS, HSTS, Host-Allowlist, WebSocket-Origin-Prüfung, `no-store`, `no-referrer` und `noindex` sind eingerichtet. Google Fonts sind die einzigen externen Ressourcen. Namen und Notizen werden in ERB escaped und serverseitig auf 25 beziehungsweise 280 Zeichen beschränkt. CSV-Texte werden gegen Formel-Injektion abgesichert.

Invite-, TV- und Teilnehmer-Tokens bestehen aus 44 Base58-Zeichen mit mehr als 256 Bit Entropie. 36 Base58-Zeichen würden die geforderten 32 Bytes Entropie nicht erreichen. Öffentliche URLs und Host-Verkostungslinks verwenden keine fortlaufenden Datenbank-IDs.

Die native Rails-Authentifizierung wird in [Authentication](app/controllers/concerns/authentication.rb) verwendet. [ResolveTastingAccess](app/actors/resolve_tasting_access.rb) kapselt die Capability-Prüfung. Der [Cable-Verbindungsaufbau](app/channels/application_cable/connection.rb) prüft zusätzlich zum signierten Stream-Namen die passenden Cookies. Host-Streams sind ausschließlich dem Besitzer zugänglich. Öffentliche Streams senden nur Refresh-Signale, niemals Produktdaten, Stimmen oder Notizen. Jede Ansicht prüft den Zugriff beim Nachladen erneut. Blockierte Teilnehmer können keine Stimmen, Exporte oder neuen Stream-Abonnements abrufen.

Für den Produktivbetrieb müssen die folgenden Variablen über den Secret-/Environment-Mechanismus des Betreibers gesetzt sein:

| Variable | Bedeutung |
| --- | --- |
| `RAILS_ENV` | `production` |
| `SECRET_KEY_BASE` oder `RAILS_MASTER_KEY` | Persistentes Rails-Secret, sicher sichern und nicht im Repository speichern |
| `APP_HOST` | Öffentlicher Hostname ohne Protokoll |
| `CABLE_ORIGINS` | Exakte erlaubte HTTPS-Origins, durch Kommas getrennt |
| `RATE_LIMIT_REDIS_URL` | Erreichbarer privater Redis-Dienst mit eigenem Zähler-Namespace |
| `ASSUME_SSL` | Nur bei vertrauenswürdigem TLS-terminierendem Reverse Proxy auf `true` setzen |

```bash
RAILS_ENV=production bin/rails db:prepare
RAILS_ENV=production bin/rails assets:precompile
RAILS_ENV=production bin/rails server
```

Der vorhandene Docker-Build kann mit `docker build -t maulvoll .` verwendet werden. Die Laufzeitvariablen werden beim Containerstart benötigt; `/rails/storage` muss persistent eingebunden sein. Solid Cable verwendet die separate Cable-Datenbank aus `config/database.yml`, Solid Queue und Solid Cache ebenfalls ihre eigenen Datenbanken. Der Build verwendet ausschließlich temporäre Dummy-Werte zur Asset-Kompilierung.

Der Reverse Proxy muss TLS, WebSocket-Upgrades für `/cable`, Request-Größenlimits und zusätzliche Verbindungs-/Request-Limits bereitstellen. Nur der Proxy darf den App-Port erreichen; er muss eingehende Forwarded-Header bereinigen und die echte Client-IP korrekt weitergeben. Proxy-, APM- und Infrastruktur-Logs dürfen Capability-URLs und Cookies nicht aufzeichnen. Rack Attack ersetzt keinen Schutz gegen volumetrische DDoS-Angriffe am Netzwerkrand.

SQLite und Solid Cable sind für eine Instanz mit mehreren Rails-Prozessen auf gemeinsamem lokalem persistentem Storage eingerichtet. Die unterstützte Gästezahl hängt von Hardware, WebSocket-Verbindungen und Abfragerate ab; unbegrenzte Kapazität wird nicht zugesichert. Für mehrere Maschinen müssen Datenbank, Pub/Sub und Storage entsprechend umgestellt und Lasttests durchgeführt werden. Regelmäßige konsistente Datenbank-Backups und ein Wiederherstellungstest gehören zum Betrieb. Die öffentliche Bereitstellung und ein externer Penetrationstest wurden durch diese Implementierung nicht vorgenommen.

## 3. Migrationen, Models und Presets

[Migrationen](db/migrate) erzeugen `User`, `Session`, `TastingTemplate`, `TastingSession`, `Round`, `Participant` und `Rating` mit Fremdschlüsseln, eindeutigen Token- und Bewertungsindizes sowie Datenbank-Checks. [Models](app/models) prüfen Schema, Wertebereiche und Zusammengehörigkeit der Daten. Ein Schema enthält 1–12 eindeutige Kriterien, die Skala reicht konfigurierbar bis maximal 10.

[TastingPresets](app/actors/tasting_presets.rb) definiert Maultaschen mit Optik, Teig, Füllung, Saftigkeit, Würzung und Geschmack, Craft-Bier sowie Kaffee-Cupping. Vorlagen werden beim Erstellen in die Verkostung kopiert; spätere Änderungen an Vorlagen verändern laufende Abende nicht.

## 4. Geschäftslogik

Alle Abläufe und Auswertungen liegen in [app/actors](app/actors):

- `CreateTastingFromTemplate`, `JoinTastingSession`, `AdvanceSessionState` und `SubmitRating` erstellen und steuern den Abend.
- `CalculateRoundVibe` berechnet ausschließlich anonyme Rundenergebnisse, Top-/Flop-Kriterium und bis zu fünf zufällige Zitate.
- `CalculateFinalAwards` gibt Marken ausschließlich nach `final_reveal` frei und berücksichtigt beide Tie-Breaker sowie den Weirdness-Index. Die Standardabweichung ist die Populationsstandardabweichung; vollständige Gleichstände entscheidet die kleinere Rundennummer. Runden ohne Stimmen erhalten keinen Award und stehen am Ende des Rankings.
- `ManageTasting` sperrt die Lobby, blockiert Gäste und bearbeitet Runden ausschließlich in der Lobby.
- `BuildTastingView`, `ExportTasting`, `PublishTastingUpdate`, Authentifizierungs- und Seed-Actors ergänzen die Abläufe.

Abstimmung, Sperren und Phasenwechsel werden unter derselben Transaktionssperre serialisiert. Ein Phasenwechsel benötigt zusätzlich den erwarteten Versionszeitpunkt, damit ein Doppelklick keine Phase überspringt. Wiederholte Bewertungen aktualisieren genau einen Zettel je Teilnehmer und Runde. Wer blockiert wird, bleibt gespeichert, wird aber aus Fortschritt und Auswertung ausgeschlossen.

Die Phasen sind `lobby → voting → round_vibe → voting … → final_reveal`. Eine manuelle Lobby-Sperre verhindert neue Gäste, lässt vorhandene Gäste aber wieder hinein. Ein gültiger Late-Join führt direkt zum aktuellen Zustand. Nach der Auflösung können keine neuen Teilnehmer mehr beitreten.

## 5. Routen und Controller

Die vollständigen [Routen](config/routes.rb) und [Controller](app/controllers) bilden diese Oberflächen ab:

| Route | Zugriff |
| --- | --- |
| `/` | Neutrale Startseite |
| `/session/new`, POST `/session` | Host-Login |
| `/host/tasting_sessions` | Eigene Verkostungen und neue Konfiguration |
| `/host/tasting_sessions/:invite_token` | Host-Pult, Runden, Sperre, Blockieren und Phasenwechsel |
| `/tv/:tv_token` | TV-Capability, ausschließlich lesend |
| `/join/:invite_token` | Formular und geschützter Beitritt |
| `/tasting/:invite_token` | Passendes aktives Teilnehmer-Cookie erforderlich |
| `/tasting/:invite_token/ratings` | Bewertungen der aktuellen Runde |
| `/tasting/:invite_token/export` | Persönlicher Druckbogen nach der Auflösung |
| `/tasting/:invite_token/export.csv` | Persönlicher CSV-Download nach der Auflösung |

## 6. Interaktion und Gestaltung

[application.bootstrap.scss](app/assets/stylesheets/application.bootstrap.scss) enthält Bootstrap 5 und den rustikalen Klemmbrett-Look: kariertes Papier, Kalam, Space Mono, harte Schatten, Stempel und große antippbare Bewertungen. Tastaturfokus, Formularbeschriftungen, reduzierte Bewegung und Druckstyles sind berücksichtigt.

[score_sheet_controller.js](app/javascript/controllers/score_sheet_controller.js) aktualisiert die Gesamtsumme. Der Template-Editor erlaubt Kriterien hinzuzufügen und zu entfernen sowie Awards, Skalen und Sprüche frei zu bearbeiten. `live_connection_controller.js` synchronisiert nach dem WebSocket-Verbindungsaufbau und bei Wiederverbindung. Dauerhafte Stream-Elemente verhindern Abonnementlücken bei Morph-Updates. Treffen während einer Aktualisierung weitere Änderungen ein, wird anschließend erneut der aktuelle Stand geladen, damit gleichzeitige Beitritte und Bewertungen nicht verloren gehen. Ein Bewertungsformular bleibt während derselben Runde erhalten, damit Live-Updates keine ungespeicherten Eingaben verwerfen.

## 7. Views, Echtzeit und Export

[ERB-Views](app/views) enthalten Host-Pult, TV, Smartphone-Controller und gemeinsame Zustands-/Ergebnis-Partials. TV und Smartphones abonnieren `turbo_stream_from [tasting_session, :public]`; Hosts erhalten einen separaten Stream. Beim Rundenende bleibt die Marke verborgen. Die Auflösung zeigt Rangliste, drei Auszeichnungen und den persönlichen Vergleich.

Der [Druckbogen](app/views/tasting_sessions/export.html.erb) zeigt Titel, Name, Datum, Awards und die vollständige Vergleichstabelle mit dynamischen Kriterien, eigenem Score, Gruppenschnitt und Notizen. „Drucken / Als PDF speichern“ öffnet den Browser-Druckdialog; es gibt keinen serverseitigen PDF-Generator. Der CSV-Download ist ein echter Attachment-Download.

## 8. Seeds und Tests

[db/seeds.rb](db/seeds.rb) verwendet die Seed-Actors für die drei Vorlagen und optional Admin samt sechs Maultaschen-Runden.

```bash
RAILS_ENV=test bin/rails db:prepare
bundle exec rspec
bin/rails zeitwerk:check
bin/rubocop
bundle exec brakeman --no-pager
yarn build:css
```

[Actor-Tests](spec/actors), [Request-Tests](spec/requests) und [Cable-Tests](spec/channels) prüfen Zustandsfolge, dynamische Wertungen, Tie-Breaker, Weirdness, fehlende Stimmen, Cross-Session-Zugriffe, Blockierung, Honeypot, Rate-Limits, Escaping, Exporte und Stream-Berechtigungen. Die GitHub-Actions-Pipeline führt die Tests zusätzlich zu den bestehenden Sicherheits- und Stilprüfungen aus.

Die Multiplayer-Browsertests laufen mit Playwright und Chromium:

```bash
yarn playwright install --with-deps chromium
yarn test:browser
```

Sie starten einen eigenen Rails-Testserver auf Port 3101, erzeugen temporäre Test-Verkostungen und entfernen diese anschließend. Getestet werden überlappende Beitritte auf getrennten Browsern mit absichtlich verzögerten Updates an Host und TV sowie unabhängige Stimmen, erhaltene Bewertungsentwürfe und stabile Scrollpositionen. Die Tests laufen auch in CI. Die Ruby- und Browsertests sollten nacheinander ausgeführt werden, da sie dieselbe Testdatenbank verwenden. Für einen bereits installierten Chromium kann `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH` gesetzt werden.

## 9. Produktionsbetrieb mit Docker Compose und GHCR

[compose.yml](compose.yml) enthält die Anwendung und den benötigten Redis-Dienst. Er verwendet standardmäßig `ghcr.io/arsiba/maulvoll:latest` und veröffentlicht HTTP auf `127.0.0.1:3000` für deinen vorhandenen Reverse Proxy. Es werden kein Proxy und keine Zertifikate eingerichtet. Redis ist intern bereits vollständig angebunden und veröffentlicht keinen Host-Port. Hintergrundjobs laufen über Solid Queue im selben Container. Alle SQLite-Datenbanken und Uploads liegen im persistenten `storage`-Volume.

### Einrichtung

```bash
cp .env.example .env
chmod 600 .env
openssl rand -hex 64
```

Trage in `.env` folgende Anwendungswerte ein:

| Variable | Wert |
| --- | --- |
| `APP_HOST` | Der bereits konfigurierte öffentliche Hostname ohne Protokoll oder Pfad; wird für die Rails-Host-Allowlist benötigt |
| `CABLE_ORIGINS` | Erlaubte Browser-Origins, falls abweichend von `https://APP_HOST` |
| `SECRET_KEY_BASE` | Der generierte Schlüssel; über Updates hinweg beibehalten |
| `MAULVOLL_IMAGE` | Standard: `ghcr.io/arsiba/maulvoll:latest`; alternativ ein veröffentlichter Versions-Tag oder Digest |
| `APP_PORT` | Lokaler HTTP-Port, standardmäßig `3000` |

`BIND_ADDRESS` kann bei Bedarf ebenfalls gesetzt werden; standardmäßig bindet der veröffentlichte Port nur an Loopback. `ASSUME_SSL` ist standardmäßig `true`, passend zum Betrieb hinter deinem vertrauenswürdigen TLS-terminierenden Proxy. Die Proxy-, Netzwerk-, Domain- und TLS-Konfiguration bleibt vollständig bei deinem bestehenden Server-Setup.

Das Image steht nach dem ersten erfolgreichen Release-Workflow zur Verfügung. Stelle das GHCR-Paket auf öffentlich, wenn es ohne Anmeldung abrufbar sein soll. Für private Pakete benötigst du auf dem Server `docker login ghcr.io` mit einem Token mit `read:packages`. Die CI selbst verwendet den automatisch bereitgestellten `GITHUB_TOKEN`.

```bash
docker compose pull
docker compose up -d --wait
docker compose ps
```

Der Anwendungscontainer läuft als UID 1000 mit schreibgeschütztem Root-Dateisystem, Healthcheck, Ressourcenlimits und rotierenden Logs. Redis verwendet ein eigenes persistentes Volume und muss vor dem Start der Anwendung gesund sein. Datenbanken werden beim Start automatisch vorbereitet beziehungsweise migriert. Anwendungs-Secrets werden ausschließlich zur Laufzeit übergeben.

Den ersten Host kannst du interaktiv mit verdeckter Passwortabfrage anlegen. Der Befehl funktioniert auch aus Fish:

```bash
docker compose exec web bin/rails runner 'require "io/console"; print "E-Mail: "; email = STDIN.gets.strip; print "Passwort mit mindestens 14 Zeichen: "; password = STDIN.noecho(&:gets).strip; puts; SeedTastings.call(email: email, password: password)'
```

### Updates und Sicherungen

Sichere vor Updates die Daten bei gestopptem Anwendungscontainer, damit keine Datenbankzugriffe während der Sicherung oder Migration stattfinden:

```bash
docker compose stop web
docker compose run --rm --no-deps -T web tar -C /rails/storage -czf - . > maulvoll-storage.tar.gz
docker compose pull
docker compose up -d --wait
```

Sichere `.env` separat. `docker compose down` behält die Volumes, `docker compose down -v` löscht sie. Laufende Container aktualisieren sich nicht automatisch; `pull_policy: always` lädt die konfigurierte Image-Version beim nächsten Start. Der Rückwechsel zu älteren Images benötigt ein kompatibles Datenbankschema beziehungsweise ein passendes Backup.

### Release-Workflow

[release.yml](.github/workflows/release.yml) startet bei einem gepushten `v*`-Tag und bei Veröffentlichung eines GitHub-Releases. Verwende semantische Versionen wie `v1.2.3`. Zuerst läuft die bestehende CI mit Ruby-, Sicherheits- und Multiplayer-Browsertests. Erst danach baut Buildx das Image für `linux/amd64` und `linux/arm64` und veröffentlicht es in GHCR. Die Docker-Actions sind auf Commit-SHAs fixiert; Build-Provenance und SBOM werden mit erzeugt. Anwendungs-Secrets werden nicht an den Build übergeben.

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

Ein stabiler Tag `v1.2.3` veröffentlicht die Tags `v1.2.3`, `1.2.3`, `1.2` und `latest`. Vorabversionen wie `v1.3.0-rc.1` und als Prerelease markierte GitHub-Releases verändern `latest` nicht. Wird nach einem Tag-Push auch ein GitHub-Release veröffentlicht, kann derselbe Tag erneut gebaut werden; Läufe desselben Tags sind serialisiert. `latest` bezeichnet den zuletzt erfolgreich veröffentlichten stabilen Build, nicht automatisch die numerisch höchste Version. Das Deployment auf deinem Server bleibt ein separater Compose-Aufruf.

Referenzen: [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry), [Docker Compose Services](https://docs.docker.com/reference/compose-file/services/).

Technische Referenzen: [Rails Security Guide](https://guides.rubyonrails.org/security.html), [ServiceActor](https://github.com/sunny/actor), [Rack Attack](https://github.com/rack/rack-attack), [Invisible Captcha](https://github.com/markets/invisible_captcha).
