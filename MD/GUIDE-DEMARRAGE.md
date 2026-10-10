# Guide : démarrer, arrêter et manipuler les données en local

Ce guide décrit l'environnement local tel qu'il est installé sur cette machine :

| Élément | Où / quoi |
|---|---|
| Base de données | Oracle 11g XE dans Docker, conteneur `oracle-arbiochem`, port `1521`, SID `XE`, schéma `ARBIOCHEMSTANDARD` |
| Serveur d'application | WildFly 10.1 dans `~/Documents/harena/wildfly-10.1.0.Final` |
| Java | OpenJDK 8 (`/usr/lib/jvm/java-8-openjdk-amd64`) |
| Application | http://localhost:8080/arbiochem/ |

## 1. Démarrer le projet

À faire dans un terminal, dans cet ordre.

**a) Libérer le port 8080 et la mémoire.** Apache et Elasticsearch redémarrent avec le PC, prennent le port 8080 et environ 8 Go de RAM :
```bash
sudo systemctl stop elasticsearch apache2
```
Pour qu'ils ne redémarrent plus au démarrage du PC :
```bash
sudo systemctl disable elasticsearch apache2
```

**b) Démarrer la base Oracle :**
```bash
docker start oracle-arbiochem
```
La base met environ une minute à s'ouvrir. Elle est prête quand cette commande affiche `DATABASE IS READY TO USE!` :
```bash
docker logs oracle-arbiochem 2>&1 | grep "READY"
```

**c) Démarrer WildFly :**
```bash
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
~/Documents/harena/wildfly-10.1.0.Final/bin/standalone.sh -b 0.0.0.0
```
Laisse ce terminal ouvert : il affiche les journaux du serveur. Le serveur est prêt quand apparaît la ligne `WFLYSRV0025: WildFly Full 10.1.0.Final ... started`.

**d) Ouvrir l'application :** http://localhost:8080/arbiochem/

## 2. Arrêter le projet

**a) Arrêter WildFly :** `Ctrl+C` dans le terminal où il tourne, ou depuis un autre terminal :
```bash
~/Documents/harena/wildfly-10.1.0.Final/bin/jboss-cli.sh --connect command=:shutdown
```

**b) Arrêter la base Oracle :**
```bash
docker stop oracle-arbiochem
```
Les données sont conservées dans le conteneur : `docker start oracle-arbiochem` les retrouve.

## 3. Après une modification du code : recompiler et redéployer

WildFly doit tourner. Depuis le dossier du projet :
```bash
cd "~/Documents/harena/akoho/projet-standard - Copie"
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ant -f build-jenkins.xml -Ddeploy.dir=$HOME/Documents/harena/wildfly-10.1.0.Final/standalone/deployments
```
Le build doit finir par `BUILD SUCCESSFUL`. WildFly recharge ensuite l'application tout seul. C'est terminé quand le dossier `deployments` contient `arbiochem.war.deployed` (et pas `.failed`) :
```bash
ls ~/Documents/harena/wildfly-10.1.0.Final/standalone/deployments
```
Dans le navigateur, recharge avec **Ctrl+F5** pour ne pas garder l'ancienne page en cache.

## 4. Exécuter un script SQL

Les scripts se mettent dans le dossier `sql/`. Le nom doit commencer par la date et l'heure, au format `AAAA-MM-JJ-HH_MM-description.sql` : le hook git `control/pre-commit` refuse les autres noms.

Pour l'exécuter sur la base locale :
```bash
cd "~/Documents/harena/akoho/projet-standard - Copie"
(echo "alter session set current_schema=ARBIOCHEMSTANDARD;"; echo "whenever sqlerror exit failure"; cat sql/MON-SCRIPT.sql) \
  | docker exec -i oracle-arbiochem sqlplus -s system/oracle
```

**Important** : commence chaque script par `SET DEFINE OFF;`. Sans cette ligne, SQL*Plus prend les `&eacute;` (accents HTML utilisés partout dans le projet) pour des variables, et le script est abîmé.

## 5. Insérer ou modifier des données

**Méthode recommandée : passer par les écrans de l'application.** Ils génèrent les bons identifiants (par exemple `BL002686`), remplissent l'historique, respectent les contrôles et les états (créé, visé). Par exemple :
- un **bâtiment** et ses **parquets** : menu Gestion des infrastructures → Batiment → Saisie (champ « Ferme » = l'usine) ;
- un **taux de change** : écran de change ;
- un **produit** : fiche produit (type de stock FIFO ou CUMP, compte de stock).

**En SQL, seulement pour les tables de référence simples ou pour corriger une donnée.** Les identifiants viennent d'une fonction `GETSEQ...` propre à chaque table. Exemple : ajouter un lieu de réception.
```sql
SET DEFINE OFF;
INSERT INTO LIEURECEPTION (ID, VAL, DESCE)
VALUES ('LRC' || LPAD(GETSEQLIEURECEPTION, 6, '0'), 'A&eacute;roport Toamasina', 'A&eacute;roport de Toamasina');
COMMIT;
```
Règles à respecter en SQL :
- toujours finir par `COMMIT;`, sinon rien n'est enregistré ;
- ne pas insérer directement dans les tables qui ont une logique métier (bons, transferts, mouvements de stock, écritures). Le code fait des contrôles et des mises à jour liées que le SQL ne ferait pas ;
- les textes avec accents s'écrivent comme dans le reste de la base, avec les entités HTML (`&eacute;`, `&agrave;`…).

## 6. DBeaver : oui, c'est recommandé

DBeaver permet de voir les tables et les vues, de lancer des requêtes et de modifier une donnée sans passer par le terminal. C'est beaucoup plus confortable que `sqlplus` pour explorer la base.

**Installation :**
```bash
sudo snap install dbeaver-ce
```

**Connexion** : Nouvelle connexion → Oracle, puis :
| Champ | Valeur |
|---|---|
| Host | `localhost` |
| Port | `1521` |
| Database | `XE`, en choisissant le type **SID** (pas Service name) |
| Utilisateur | `arbiochemstandard` |
| Mot de passe | celui de `apj.connection.password` dans `arbiochem-ejb/src/java/apj.properties` |

Pour l'administration (créer un utilisateur, réimporter un dump), utilise `system` avec le mot de passe `oracle`. Ce mot de passe ne vaut que pour cette base locale.

Au premier lancement, DBeaver propose de télécharger le pilote Oracle : accepte.

**Précautions dans DBeaver :**
- DBeaver peut être en mode « auto-commit » ou non (icône dans la barre d'outils). En mode manuel, clique sur **Commit** après une modification ;
- n'utilise DBeaver que sur la base locale, jamais sur une base partagée ou de production sans accord.

## 7. Dépannage rapide

| Problème | Cause et solution |
|---|---|
| L'application ne répond pas sur le port 8080 | Apache ou Elasticsearch occupe le port : `sudo systemctl stop elasticsearch apache2`. Ou WildFly n'est pas démarré. |
| `permission denied ... docker.sock` | La session n'a pas encore le groupe `docker` : redémarre le PC (ou `newgrp docker` dans le terminal). |
| `ORA-01017: invalid username/password` au démarrage | Le mot de passe de `apj.properties` ne correspond pas à celui de la base. Attention : ce fichier a des fins de ligne Windows, donc un `\r` invisible peut se glisser à la fin du mot de passe. |
| « Mouvement source non trouvé » sur un transfert | Le produit est géré en CUMP (pas de suivi par arrivage). C'est corrigé dans le code : refais le transfert, ou vise-le à nouveau. |
| Accents abîmés (`Ã©`) dans un message d'erreur | Le build compile les fichiers Java en ISO-8859-1. Dans le Java, écris les accents avec des échappements (`\u00E9` pour é), pas avec de vrais caractères accentués. |
| Une page affiche une ancienne version | Ctrl+F5, puis vérifie que `arbiochem.war.deployed` est bien présent. |
