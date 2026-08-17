# ShareMyBag

[![Essayer avec railsbox](https://pinfada.github.io/sharemybag/badge.svg)](https://pinfada.github.io/sharemybag/)
[![CI](https://github.com/pinfada/sharemybag/actions/workflows/ci.yml/badge.svg)](https://github.com/pinfada/sharemybag/actions/workflows/ci.yml)

Place de marché qui met en relation des voyageurs disposant de kilos libres
dans leurs bagages avec des expéditeurs de colis. Le fonctionnement est celui
d'une **enchère inversée** : l'expéditeur publie une demande de transport, les
voyageurs proposent leur prix, l'expéditeur retient une offre.

Application Ruby on Rails 7.0 sur PostgreSQL.

## Démonstration jouable

**→ [pinfada.github.io/sharemybag](https://pinfada.github.io/sharemybag/)**

La démonstration tourne **entièrement dans le navigateur** : Puma, PostgreSQL
et l'application s'exécutent dans une VM Linux émulée par
[railsbox](https://github.com/pinfada/railsbox), publiée sur GitHub Pages.
Comptez une vingtaine de secondes au premier chargement, le temps que
l'instantané mémoire soit restauré.

Chaque visiteur écrit dans sa propre copie, qui disparaît avec l'onglet — rien
n'est partagé, rien n'est conservé. La base est peuplée par `db/seeds.rb`
(24 utilisateurs, 200 vols, 30 demandes d'expédition, enchères, conversations).

Comptes de démonstration :

| Rôle | Identifiant | Mot de passe |
| --- | --- | --- |
| Administrateur | `admin@sharemybag.com` | `Admin123!` |
| Démonstration | `demo@sharemybag.com` | `Demo123!` |
| Expéditrice | `marie@example.com` | `Marie123!` |
| Voyageur | `pierre@example.com` | `Pierre123!` |

Ce sont des identifiants de démonstration, sur des données générées par Faker :
la VM n'a aucun réseau sortant et son image est publique.

La sandbox est reconstruite à chaque push sur `master` par
[`.github/workflows/sandbox.yml`](.github/workflows/sandbox.yml) ; sa
configuration tient dans [`railsbox.yml`](railsbox.yml).

## Démarrer en local

Prérequis : Ruby 3.3 (voir [`.ruby-version`](.ruby-version)), PostgreSQL 16,
`libpq-dev`.

```bash
bundle install
rails db:create db:schema:load db:seed
rails server
```

Les identifiants PostgreSQL se règlent par variables d'environnement —
`DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`, `DB_NAME_DEV`,
`DB_NAME_TEST` — avec le socket Unix local par défaut. Les clés de services
tiers (OAuth, Google Maps, Stripe, Twilio) passent par Figaro : copiez
`config/application.yml.example` en `config/application.yml`. Elles sont
toutes facultatives, l'application démarre sans.

## Tests

```bash
rails test
```

La suite Minitest tourne aussi en intégration continue sur PostgreSQL 16, avec
une vérification du chargement Zeitwerk et une précompilation des assets en
environnement de production :
[`.github/workflows/ci.yml`](.github/workflows/ci.yml).

## Documentation

- [`CLAUDE.md`](CLAUDE.md) — architecture, modèles métier, points d'entrée.
- [`PLAN_MISE_A_JOUR.md`](PLAN_MISE_A_JOUR.md) — plan de mise à jour.
- [`users-stories/`](users-stories/) — user stories.
