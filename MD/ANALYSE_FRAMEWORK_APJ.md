# 1. Identification du framework

Le projet utilise un framework interne appelé **APJ**, identifiable par :

- les packages `bean.*`, `affichage.*`, `historique.*`, `utilitaire.*` ;
- les bibliothèques `apj-core.jar` et `apj-core2.jar` ;
- les classes `ClassMAPTable`, `ClassEtat`, `ClassMere`, `TypeObjet` ;
- les composants de présentation `PageRecherche`, `PageInsert`, `PageConsulte` ;
- l’EJB transversal `user.UserEJB`.

Le noyau APJ n’est pas fourni en source. Il est livré sous forme compilée dans [apj-core.jar](build-file/lib/apj-core.jar) et [apj-core2.jar](build-file/lib/apj-core2.jar). L’analyse de son implémentation interne est donc impossible avec certitude, mais son contrat public est largement observable par les classes du projet et par `javap`.

Le projet n’est donc pas une application Spring, Laravel, Django ou Symfony. Son modèle repose principalement sur :

```text
JSP impératives
    |
    v
objets APJ Java
    |
    v
UserEJB / ClassMAPTable
    |
    v
SQL JDBC / Oracle
```

# 2. Architecture générale

## 2.1 Modules principaux

### `arbiochem-ejb`

C’est le module Java principal :

[arbiochem-ejb/src/java](arbiochem-ejb/src/java)

Il contient :

- les classes métier ou objets persistants ;
- les classes héritant des abstractions APJ ;
- `UserEJB` et `UserEJBBean` ;
- les constantes et utilitaires ;
- les propriétés de connexion ;
- les classes de génération de rapports et de traitements spécialisés.

Malgré son nom EJB, une grande partie du code est constituée de classes Java ordinaires manipulant directement des connexions JDBC.

### `arbiochem-war`

C’est le module web :

[arbiochem-war/web](arbiochem-war/web)

Il contient :

- les JSP ;
- les ressources statiques ;
- quelques servlets spécialisés ;
- `WEB-INF/web.xml` ;
- le fragment APJ `web-fragment.xml`.

Les JSP sont le centre du fonctionnement web. Elles instancient directement les objets APJ, construisent les formulaires et génèrent les liens de navigation.

### `build-file`

C’est l’espace de compilation généré :

[build-file](build-file)

Il contient :

- `arbiochem_jar`, classes compilées du module EJB ;
- `arbiochem_war`, WAR éclaté ;
- `lib`, bibliothèques d’exécution ;
- `ear`, emplacement prévu pour les archives EAR.

Ces fichiers ne sont pas nécessairement des sources maîtres. Ils sont produits ou alimentés par Ant.

### `codebar-generator`

Projet auxiliaire indépendant destiné à la génération de codes-barres.

### `google-adk`

Projet auxiliaire Python, sans rôle apparent dans le cycle Java EE principal.

# 3. Assemblage et déploiement

Le build principal se trouve dans [build.xml](build.xml).

Le cycle Ant observable est :

```text
clean
  -> init
  -> compile
  -> buildEjbJar
  -> compileWar
  -> copieProperties
  -> deploy
```

## `init`

Le build :

- crée les dossiers de sortie ;
- copie les JSP dans `build-file/arbiochem_war` ;
- copie les bibliothèques dans `WEB-INF/lib` ;
- copie `project.properties` et `apj.properties` dans l’artefact EJB ;
- copie les fichiers XML web.

## `compile`

Les classes de `arbiochem-ejb/src/java` sont compilées dans :

```text
build-file/arbiochem_jar
```

## `buildEjbJar`

Le dossier compilé devient :

```text
build-file/ear/arbiochem-ejb.jar
```

Ce JAR est ensuite copié dans le `WEB-INF/lib` du WAR.

## `compileWar`

Les classes de :

```text
arbiochem-war/src/java
```

sont compilées dans :

```text
build-file/arbiochem_war/WEB-INF/classes
```

## `deploy`

Le déploiement réellement utilisé est un **WAR éclaté**, copié vers :

```text
${deploy.dir}/async-standard.war
```

Le fichier `.dodeploy` déclenche le déploiement WildFly/JBoss.

Le projet contient aussi une variante Tomcat dans [build-tomcat.xml](build-tomcat.xml), mais la cible WildFly est le chemin le plus clairement configuré dans le build principal.

# 4. Structure typique d’un projet APJ

```text
projet/
├── build.xml
├── arbiochem-ejb/
│   └── src/
│       ├── java/
│       │   ├── apj.properties
│       │   ├── project.properties
│       │   ├── user/
│       │   ├── bean métier/
│       │   ├── affichage/
│       │   └── utilitaire/
│       └── ressources/
│           └── prompts/
├── arbiochem-war/
│   ├── src/java/
│   │   └── servlets spécialisées
│   └── web/
│       ├── index.jsp
│       ├── pages/
│       ├── assets/
│       └── WEB-INF/
│           ├── web.xml
│           └── META-INF/apj/web-fragment.xml
└── build-file/
    ├── lib/
    ├── arbiochem_jar/
    └── arbiochem_war/
```

## Fichiers obligatoires ou structurants

### Obligatoires pour la compilation

- `build.xml` ;
- les sources Java du module EJB ;
- les bibliothèques APJ ;
- `apj.properties` ;
- `project.properties`.

### Obligatoires pour une application web

- `index.jsp` ou une page équivalente ;
- les JSP de navigation ;
- `WEB-INF/web.xml` ;
- les bibliothèques dans `WEB-INF/lib`.

### Optionnels

- les servlets spécialisés ;
- les fragments web ;
- les rapports Jasper ;
- les générateurs de fichiers ;
- les classes métier particulières ;
- les prompts IA.

### Générés

- `build-file/arbiochem_jar` ;
- `build-file/arbiochem_war` ;
- les `.class` ;
- `dateBuild.txt` ;
- les archives JAR éventuelles.

# 5. Modèle objet APJ

## `ClassMAPTable`

C’est l’abstraction centrale de persistance.

Son API publique montre qu’elle sait notamment :

- connaître le nom de table ;
- générer une clé primaire ;
- lire un objet par identifiant ;
- construire des requêtes SQL ;
- insérer ;
- modifier ;
- supprimer ;
- gérer l’historisation ;
- rechercher avec pagination ;
- charger les champs par réflexion ;
- convertir un objet en JSON.

Le contrat impose généralement :

```java
public class Exemple extends ClassMAPTable {
    public Exemple() {
        setNomTable("EXEMPLE");
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        preparePk("EXP", "getSeqExemple");
        setId(makePK(c));
    }
}
```

Les noms sont spécifiques au framework :

- `TuppleID`, et non `TupleId` ;
- `construirePK`, et non `generateId` ;
- `setNomTable` ;
- `controler` ;
- `getAttributIDName`.

## `TypeObjet`

`TypeObjet` est une spécialisation ou une abstraction intermédiaire utilisée par plusieurs classes du projet.

La classe [Pompe.java](arbiochem-ejb/src/java/pompe/Pompe.java#L14) hérite de `TypeObjet`, et non directement de `ClassMAPTable`.

Cela montre qu’APJ possède plusieurs familles d’objets, probablement destinées à des usages génériques de configuration et d’affichage.

## `ClassEtat`

`ClassEtat` représente les objets ayant un état de workflow.

L’API exposée contient notamment des opérations telles que :

- viser ;
- valider ;
- rejeter ;
- clôturer ;
- modifier l’état.

La relation est observable dans le bytecode :

```text
ClassEtat extends ClassUser
ClassMere extends ClassEtat
```

## `ClassMere` et `ClassFille`

APJ modélise explicitement les relations parent/enfants :

```text
ClassMere
  └── ClassFille[]
```

`ClassMere` expose :

- `ajouterFille` ;
- `setFille` ;
- `createObjectFille` ;
- `validerObjectFille` ;
- `createObjectMultiple` ;
- `deleteFille`.

Il ne s’agit donc pas simplement d’un ORM objet-table. Le framework possède une abstraction native pour les structures maître/détail.

# 6. Présentation et génération HTML

La présentation repose sur des objets Java APJ utilisés directement dans les JSP.

Principales classes :

- `PageRecherche` : recherche et liste ;
- `PageRechercheChoix` : écran de sélection ;
- `PageInsert` : saisie ;
- `PageConsulte` : consultation ;
- `PageUpdate` : modification ;
- `Formulaire` : définition des champs ;
- `Liste` : champ lié à un autre objet ;
- `Tableau` : rendu tabulaire.

Exemple de liste :

[pompe-liste.jsp](arbiochem-war/web/pages/pompe/pompe-liste.jsp#L12)

```java
Pompe t = new Pompe();
t.setNomTable("POMPE");

PageRecherche pr = new PageRecherche(
    t,
    request,
    listeCrt,
    listeInt,
    3,
    libEntete,
    libEntete.length
);
```

Puis la JSP configure :

- l’utilisateur ;
- le lien courant ;
- la page suivante ;
- les libellés ;
- les colonnes ;
- les liens de ligne ;
- le HTML final.

Le framework génère ensuite le HTML via :

```java
pr.getFormu().getHtmlEnsemble()
pr.getTableau().getHtml()
pr.getBasPage()
```

C’est une approche de **génération HTML par objets Java**, et non une séparation moderne contrôleur/template.

# 7. Routage

Il existe deux routages différents.

## 7.1 Routage HTTP standard

Les servlets explicitement déclarées sont configurées dans :

[web-fragment.xml](arbiochem-war/web/WEB-INF/META-INF/apj/web-fragment.xml#L5)

Exemples :

```text
/Deroulante
/download
/ImportUtilServlet
```

Ces routes utilisent le mécanisme standard Servlet Java EE.

## 7.2 Routage applicatif APJ

Les JSP sont principalement atteintes avec des paramètres :

```text
?but=pompe/pompe-liste.jsp
?but=pompe/pompe-fiche.jsp
?but=apresTarif.jsp
```

Le paramètre `but` est une convention APJ très importante.

Le lien courant est stocké dans la session :

```java
(String) session.getValue("lien")
```

La navigation se fait donc par :

```text
JSP
  -> lien contenant ?but=...
  -> résolution de la JSP cible
  -> nouvelle JSP
```

La présence du mécanisme de résolution de `but` n’est pas visible dans les sources du projet. Elle est probablement fournie par une JSP commune, un composant APJ ou une configuration extérieure.

Ce point reste donc **déduit**, pas directement prouvé.

# 8. Contrôleurs et services

Le framework ne possède pas, dans les sources visibles, un contrôleur MVC central comparable à Spring MVC ou Symfony.

La logique est répartie ainsi :

```text
JSP
  ├── instancie PageRecherche/PageInsert/PageConsulte
  ├── lit request et session
  ├── prépare le rendu
  └── délègue aux objets APJ
```

Les traitements transversaux sont regroupés dans `UserEJB`.

[UserEJB.java](arbiochem-ejb/src/java/user/UserEJB.java#L30)

Son contrat expose notamment :

- `createObject` ;
- `updateObject` ;
- `deleteObject` ;
- `validerObject` ;
- `getDataPage` ;
- `getDataPageMax` ;
- `testRestriction` ;
- `finaliser` ;
- `createObjectMultiple` ;
- `updateObjectMultiple` ;
- `mapperMereFille`.

`UserEJBBean` implémente ce service transversal :

[UserEJBBean.java](arbiochem-ejb/src/java/user/UserEJBBean.java#L62)

Cependant, les annotations EJB principales sont commentées :

```java
//@Stateful
//@AccessTimeout(10000)
//@TransactionAttribute(...)
```

On peut donc affirmer que le code a été conçu autour d’un EJB de session, mais on ne peut pas affirmer que ces annotations sont actives dans l’état actuel du dépôt.

# 9. Injection de dépendances

Aucune utilisation significative de :

```java
@Inject
@EJB
@Named
@RequestScoped
```

n’est visible dans les chemins principaux.

La dépendance est généralement fournie manuellement :

```java
UserEJB u = (user.UserEJB) session.getValue("u");
```

Puis l’objet est passé explicitement :

```java
new PageInsert(pompe, request, u)
new PageConsulte(objet, request, u)
```

Le modèle APJ repose donc davantage sur :

- l’injection manuelle par constructeur ;
- la session HTTP ;
- les interfaces Java ;
- les conventions de nommage ;

que sur un conteneur de dépendances moderne.

# 10. Accès aux données

L’accès aux données combine :

- JDBC ;
- Oracle ;
- réflexion sur les champs Java ;
- génération de SQL par `ClassMAPTable` ;
- procédures ou séquences Oracle ;
- connexions explicitement passées aux méthodes.

La configuration est dans [apj.properties](arbiochem-ejb/src/java/apj.properties#L1) :

```properties
apj.connection.url=...
apj.connection.user=...
apj.connection.password=...
apj.debug=true
```

Les classes reçoivent fréquemment une `Connection` :

```java
construirePK(Connection c)
controler(Connection c)
validerObject(String u, Connection c)
```

Le framework permet donc deux styles :

```text
UserEJB sans Connection
    -> APJ ouvre ou gère la connexion

Méthode avec Connection
    -> l'appelant contrôle explicitement le contexte JDBC
```

L’API de `ClassMAPTable` montre des méthodes comme :

- `insertToTable` ;
- `updateToTable` ;
- `deleteToTable` ;
- `insertToTableWithHisto` ;
- `updateToTableWithHisto` ;
- `rechercherPage`.

# 11. Conventions imposées

Les conventions les plus fortes sont les suivantes.

## Objet persistant

Un objet doit généralement :

- hériter d’une base APJ ;
- définir son nom de table ;
- exposer un identifiant ;
- redéfinir `getTuppleID` ;
- redéfinir `getAttributIDName` ;
- définir `construirePK` ;
- respecter la correspondance champs Java/colonnes SQL.

## Clé primaire

La clé est générée par une convention APJ/Oracle :

[pompe/Pompe.java](arbiochem-ejb/src/java/pompe/Pompe.java#L23)

```java
preparePk("PMP", "getSeqPompe");
setId(makePK(c));
```

Le préfixe et le nom de séquence sont donc des éléments de convention framework/projet.

## Contrôle

La validation se fait dans des méthodes nommées précisément :

```java
controler(Connection c)
controlerUpdate(Connection c)
controlerDelete(Connection c)
```

Exemple :

[pompe/Pompe.java](arbiochem-ejb/src/java/pompe/Pompe.java#L44)

```java
public void controllerValMax() throws Exception
```

Puis :

[pompe/Pompe.java](arbiochem-ejb/src/java/pompe/Pompe.java#L52)

```java
public void controler(Connection c) throws Exception {
    super.controler(c);
    controllerValMax();
}
```

Le framework semble appeler ces méthodes avant insertion ou modification.

## Page de saisie

Une page de saisie suit un protocole standard :

```text
objet
 -> setNomTable
 -> PageInsert
 -> configuration Formulaire
 -> preparerDataFormu
 -> génération HTML
 -> champs cachés acte/classe/nomtable/bute
```

Ces paramètres sont visibles dans [pompe-saisie.jsp](arbiochem-war/web/pages/pompe/pompe-saisie.jsp#L42).

Les champs cachés sont particulièrement importants :

```text
acte
bute
classe
nomtable
```

Ils permettent au mécanisme APJ de savoir :

- quelle opération exécuter ;
- quelle classe charger ;
- quelle table cibler ;
- quelle page afficher ensuite.

# 12. Gestion des états et autorisations

Les opérations de workflow sont concentrées dans `UserEJB` :

```text
viserObject
validerObject
retournerObject
recuObject
cloturerObject
```

Les autorisations sont aussi centralisées :

```java
testRestriction(String user, String permission, String table, Connection con)
```

Le modèle semble basé sur :

```text
utilisateur
 -> rôle
 -> action
 -> restriction
 -> table ou fonctionnalité
```

Les classes `historique.*` et `utilisateur.*` des jars APJ confirment la présence de :

- rôles ;
- actions ;
- restrictions ;
- historiques ;
- utilisateurs ;
- menus ;
- pages d’accueil.

La logique exacte des règles d’autorisation n’est cependant pas reconstructible sans le code du jar.

# 13. Gestion des événements et middleware

Aucun middleware au sens moderne n’est clairement présent :

- pas de chaîne de middleware visible ;
- pas de filtre applicatif central identifiable ;
- pas de contrôleur frontal visible ;
- pas de système d’événements générique observable.

Les mécanismes équivalents sont plutôt :

- les méthodes `controler` ;
- les méthodes `validerObject` ;
- les méthodes `changeState` ;
- les hooks `createObject`, `payerObject`, `finaliser` ;
- l’historisation ;
- les opérations de notification.

Les événements sont donc principalement des **étapes de cycle de vie des objets APJ**, et non des événements découplés.

# 14. Exemple complet : fonctionnalité `Pompe`

Cet exemple est choisi uniquement parce qu’il expose clairement les conventions APJ.

## 14.1 Liste

Entrée :

```text
GET /application/?but=pompe/pompe-liste.jsp
```

La JSP :

1. crée `Pompe` ;
2. définit la table `POMPE` ;
3. crée un `PageRecherche` ;
4. transmet `request` ;
5. transmet l’utilisateur stocké en session ;
6. configure les colonnes ;
7. demande les données au composant APJ ;
8. génère le formulaire et le tableau HTML.

Source : [pompe-liste.jsp](arbiochem-war/web/pages/pompe/pompe-liste.jsp#L11)

Flux :

```text
paramètre but
  -> JSP pompe-liste.jsp
  -> Pompe
  -> PageRecherche
  -> ClassMAPTable/UserEJB
  -> requête Oracle
  -> ResultatEtSomme/Tableau
  -> HTML
```

## 14.2 Saisie

Entrée :

```text
GET /application/?but=pompe/pompe-saisie.jsp
```

La JSP :

1. récupère `UserEJB` depuis la session ;
2. instancie `Pompe` ;
3. associe `POMPE` ;
4. crée `PageInsert` ;
5. transforme `idMagasin` en champ `Liste` ;
6. prépare le formulaire ;
7. génère les champs HTML ;
8. ajoute les paramètres cachés.

Source : [pompe-saisie.jsp](arbiochem-war/web/pages/pompe/pompe-saisie.jsp#L18)

Soumission :

```text
POST /application/?but=apresTarif.jsp
acte=insert
classe=pompe.Pompe
nomtable=POMPE
bute=pompe/pompe-fiche.jsp
```

Le mécanisme APJ lit ensuite les métadonnées de la requête, crée l’objet, remplit ses propriétés, appelle vraisemblablement :

```text
construirePK
controler
insertToTable
```

Le premier appel est observable dans l’API APJ. L’ordre exact est déduit, car le dispatcher responsable n’est pas fourni.

## 14.3 Clé primaire et validation

Pour une insertion de `Pompe` :

```text
Pompe.construirePK
  -> preparePk("PMP", "getSeqPompe")
  -> makePK(connection)
  -> setId(...)
```

Puis :

```text
Pompe.controler
  -> ClassMAPTable.controler
  -> controllerValMax
  -> exception si max <= 0
```

Cette logique de validation est du code spécifique au projet, tandis que l’appel conventionnel à `controler` relève d’APJ.

## 14.4 Consultation

Entrée :

```text
GET /application/?but=pompe/pompe-fiche.jsp&id=...
```

La JSP :

1. crée `Pompe` ;
2. crée `PageConsulte` ;
3. appelle `pc.getBase()` ;
4. récupère l’objet par identifiant ;
5. demande `pc.getHtml()` ;
6. affiche les liens de modification et de suppression.

Source : [pompe-fiche.jsp](arbiochem-war/web/pages/pompe/pompe-fiche.jsp#L20)

Flux :

```text
id HTTP
  -> PageConsulte
  -> Pompe.getById / mécanisme APJ
  -> Oracle
  -> objet Pompe
  -> HTML
```

# 15. Distinction framework/projet/bibliothèques

| Élément | Nature |
|---|---|
| `ClassMAPTable` | Framework APJ compilé |
| `ClassEtat` | Framework APJ compilé |
| `ClassMere` / `ClassFille` | Framework APJ compilé |
| `PageRecherche` | Framework APJ compilé |
| `PageInsert` | Framework APJ compilé |
| `Formulaire`, `Tableau`, `Liste` | Framework APJ compilé |
| `UserEJB` | Contrat projet construit autour d’APJ |
| `UserEJBBean` | Code spécifique du projet |
| `Pompe` | Code spécifique du projet |
| `pompe-liste.jsp` | Code spécifique du projet utilisant APJ |
| `?but=...` | Convention APJ/projet |
| `acte`, `classe`, `bute`, `nomtable` | Convention APJ |
| `apj.properties` | Configuration APJ |
| JDBC/Oracle | Bibliothèque et infrastructure externes |
| Servlet API | Java EE externe |
| JasperReports | Bibliothèque externe |
| WildFly/JBoss | Serveur d’application externe |
| Ant | Outil de build externe |
| `web.xml` | Standard Servlet |
| `web-fragment.xml` | Standard Servlet, utilisé par APJ/projet |

# 16. Ce qui est certain, déduit ou inconnu

## Directement observable

- le projet compile avec `apj-core.jar` ;
- les objets héritent des classes APJ ;
- les JSP utilisent `PageRecherche`, `PageInsert` et `PageConsulte` ;
- les tables sont configurées par `setNomTable` ;
- les clés utilisent `preparePk` et `makePK` ;
- la session contient au moins `u` et `lien` ;
- `UserEJB` expose le CRUD, la pagination, les états et les restrictions ;
- le build produit un WAR éclaté ;
- les JSP utilisent le paramètre `but`.

## Déduit avec forte confiance

- APJ utilise la réflexion pour mapper les champs Java aux colonnes SQL ;
- le dispatcher lit les champs cachés `acte`, `classe`, `nomtable` et `bute` ;
- `PageRecherche` délègue les recherches à `UserEJB` ou à `ClassMAPTable` ;
- les méthodes `controler` sont des hooks de validation ;
- le framework gère nativement l’historique et les workflows d’état.

## Inconnu

- l’implémentation exacte du dispatcher de `but` ;
- l’ordre exact des appels lors d’une insertion ;
- la manière précise dont `UserEJB` est obtenu au démarrage ;
- la configuration réelle des transactions ;
- le rôle exact des annotations EJB commentées ;
- l’algorithme détaillé des restrictions ;
- le contenu du code source original du noyau APJ ;
- l’existence éventuelle de filtres dans des bibliothèques non inspectées.

# 17. Modèle mental du framework

APJ pense l’application comme un ensemble d’objets persistants pilotés par des métadonnées :

```text
Objet Java
  = représentation d’une table, d’une vue ou d’un processus
```

Chaque objet fournit :

- son nom de table ;
- son identifiant ;
- ses champs ;
- sa clé primaire ;
- ses contrôles ;
- ses relations ;
- éventuellement son état ;
- éventuellement ses enfants.

La construction d’une fonctionnalité suit alors ce modèle :

```text
1. Créer une classe Java APJ.
2. La rattacher à une table ou une vue.
3. Implémenter les méthodes d’identification.
4. Implémenter la génération de clé.
5. Ajouter les contrôles.
6. Créer une JSP de liste, saisie ou fiche.
7. Utiliser les classes Page* APJ.
8. Déclarer les paramètres de navigation attendus.
9. Laisser APJ charger, valider, persister et afficher l’objet.
```

Le développeur APJ ne construit pas principalement des contrôleurs indépendants et des services REST. Il assemble plutôt :

```text
classe APJ
 + table SQL
 + JSP conventionnelle
 + UserEJB
 + paramètres HTTP APJ
```

La structure paraît ainsi fortement couplée parce que la philosophie du framework privilégie :

- les conventions plutôt que la configuration déclarative ;
- les classes Java représentant directement les tables ;
- les JSP génératrices de HTML ;
- les workflows intégrés aux objets ;
- les opérations CRUD génériques ;
- les séquences Oracle ;
- l’historisation et les états ;
- la centralisation des opérations utilisateur dans `UserEJB`.

En résumé, APJ est un framework propriétaire de type **ORM procédural + générateur de formulaires JSP + gestionnaire de workflow**, construit sur Java EE/JDBC, avec une forte dépendance aux conventions de nommage, aux paramètres HTTP et aux classes de base compilées.

# 18. Complément après décompilation du noyau APJ

Le dossier `decompiled` contient désormais une version décompilée des deux bibliothèques APJ. Les conclusions ci-dessous sont donc plus précises que les hypothèses formulées à partir des seules signatures de classes.

Les fichiers décompilés restent une représentation reconstruite du bytecode : les noms de variables locales, certains types génériques et certains commentaires peuvent être approximatifs. En revanche, les appels, les conditions et les chaînes SQL visibles constituent des éléments directement observables.

## 18.1 Répartition réelle des responsabilités entre les deux JAR

### `apj-core.jar`

Le JAR contient le noyau historique :

- `bean.*` : mapping, persistance, objets d’état et objets maître/détail ;
- `affichage.*` : pages, formulaires, champs, tableaux et dashboards ;
- `historique.*` : historique et utilisateurs ;
- `utilitaire.*` : connexions, propriétés, dates, SQL et fonctions communes ;
- `chatbot.*` : intégration IA et génération de contenu ;
- `constante.*` : constantes d’affichage et d’état.

### `apj-core2.jar`

Le second JAR étend l’environnement avec des modules plus applicatifs :

- `web.servlet.*` ;
- `web.importController.*` ;
- `service.*` ;
- `notification.*` ;
- `evenement.*` ;
- `utilisateur.*` ;
- `configuration.*` ;
- `reporting.*` ;
- `menu.*` ;
- `mg.*` et `lc.*`.

La séparation n’est donc pas une séparation MVC. Elle ressemble plutôt à une séparation entre un noyau générique APJ et des extensions de plateforme ou de verticales applicatives.

## 18.2 Le mapping est hybride : réflexion Java et métadonnées Oracle

La classe `bean.ListeColonneTable` est un composant central du framework :

[ListeColonneTable.java](decompiled/apj-core/bean/ListeColonneTable.java#L10)

Elle fonctionne en deux temps :

```text
classe Java
  -> champs déclarés par réflexion
  -> intersection avec les colonnes Oracle
  -> liste de champs effectivement mappés
```

Les colonnes sont chargées avec une requête sur :

```sql
SELECT * FROM listeColonneTable
WHERE table_Name = upper(?)
ORDER BY column_id ASC
```

Le framework ne mappe donc pas aveuglément tous les champs Java. Il conserve les champs qui existent à la fois :

- dans la hiérarchie de la classe Java ;
- dans la description de la table fournie par `listeColonneTable`.

Cette information est mise en cache dans plusieurs tables statiques :

```java
listeColPTable
listeFieldHeritage
listeFieldHeritageClassMAPTable
listeMethodHeritage
classeEtPackage
```

Conséquence pratique : modifier une classe Java ou une table Oracle peut ne pas suffire. Les métadonnées de `listeColonneTable` doivent également être cohérentes.

## 18.3 La hiérarchie Java est parcourue par réflexion

`getFieldListeHeritage` parcourt les champs déclarés par la classe applicative puis remonte les superclasses jusqu’à `ClassMAPTable`.

Le mapping est donc fondé sur :

- le nom du champ Java ;
- le type Java ;
- la classe d’héritage ;
- le nom de la colonne Oracle ;
- le mode de l’objet (`select`, `modif`, `groupe`, etc.).

Les getters et setters ne sont pas l’unique contrat. Les champs eux-mêmes jouent un rôle direct dans la persistance et la lecture du `ResultSet`.

## 18.4 Cycle d’insertion réellement observé

L’implémentation de `ClassMAPTable.createObject` est explicite :

[ClassMAPTable.java](decompiled/apj-core/bean/ClassMAPTable.java#L620)

```text
createObject(user, connection)
  -> controler(connection)
  -> créer une notification si messageNotif est défini
  -> construire la clé si l’identifiant est vide
  -> insertToTableWithHisto(user, connection)
  -> traiter éventuellement le fichier uploadé
  -> retourner l’objet
```

Cela confirme que `controler` est un véritable hook d’insertion et non seulement une convention documentaire.

La génération de clé par défaut est également visible :

[ClassMAPTable.java](decompiled/apj-core/bean/ClassMAPTable.java#L695)

```text
max de séquence
  -> formatage sur la longueur configurée
  -> préfixe INDICE_PK
  -> ajout éventuel de l’heure si synchronisation activée
```

Par défaut, la classe initialise notamment :

```text
INDICE_PK = EX
nomProcedureSequence = GetSeqExecutions
longuerClePrimaire = 6
mode = modif
```

Les classes du projet remplacent généralement ces valeurs dans `construirePK` avec `preparePk`.

## 18.5 Historisation intégrée dans les opérations CRUD

L’insertion standard appelle `insertToTableWithHisto`. Les versions batch font également apparaître explicitement :

```text
création d’un MapHistorique
  -> insertion de l’objet
  -> insertion de l’historique
  -> insertion éventuelle dans HistoInsert
```

Le champ `estIndexable` active un traitement historique supplémentaire avec `HistoInsert`.

Le framework ne traite donc pas l’historique comme un observateur externe. L’historisation est incluse dans les opérations de persistance de l’objet.

## 18.6 SQL généré et stratégie de sécurité

Deux stratégies coexistent dans `ClassMAPTable`.

### Insertion avec `PreparedStatement`

`insertToTable(Connection)` construit les noms de colonnes et les placeholders, puis renseigne les valeurs selon le type Java :

```text
boolean
byte
short
int
long
float
double
String
Date
Timestamp
```

Les valeurs sont donc normalement transmises par paramètres JDBC dans cette méthode.

### Génération de chaînes SQL

D’autres méthodes comme `getComandeInsert`, `getCommandeDelete` ou `updateToTable` construisent directement des chaînes SQL avec concaténation.

Cela révèle une architecture historique mixte :

```text
API récente ou principale
  -> PreparedStatement

API historique et batch
  -> chaînes SQL et Statement
```

Cette distinction doit être conservée dans l’analyse de sécurité : toutes les opérations APJ ne bénéficient pas du même niveau de paramétrage JDBC.

## 18.7 Gestion des connexions et transactions

`UtilDB` choisit la source de connexion selon la configuration :

[UtilDB.java](decompiled/apj-core/utilitaire/UtilDB.java#L59)

```text
si apj.datasource est défini
  -> lookup JNDI java:/<datasource>
  -> DataSource.getConnection()

sinon
  -> chargement du driver
  -> DriverManager.getConnection(url, user, password)
  -> ALTER SESSION SET NLS_DATE_FORMAT = 'dd/mm/yyyy'
```

Le framework supporte donc une exécution dans un serveur d’application avec DataSource, mais peut aussi fonctionner en connexion JDBC directe.

Les méthodes de `ClassEtat` et `ClassMere` montrent une gestion manuelle des transactions :

```text
si la connexion n’est pas fournie
  -> ouvrir une connexion
  -> setAutoCommit(false)
  -> commit en cas de succès
  -> rollback en cas d’exception
  -> fermer la connexion
```

Le système n’est donc pas entièrement dépendant des transactions déclaratives EJB. Une partie importante du comportement transactionnel est écrite dans les classes APJ elles-mêmes.

## 18.8 Lecture d’un objet depuis Oracle

`getById` :

[ClassMAPTable.java](decompiled/apj-core/bean/ClassMAPTable.java#L650)

```text
définir éventuellement le nom de table
  -> positionner l’identifiant dans l’objet critère
  -> appeler CGenUtil.rechercher
  -> retourner le premier résultat
```

La lecture du `ResultSet` est faite par `getInfoFromCursor`. Cette méthode parcourt les champs par réflexion et appelle les méthodes `ResultSet` adaptées au type :

```text
getBoolean
getByte
getShort
getInt
getLong
getFloat
getDouble
getString
getDate
getTimestamp
```

Le framework réalise donc un mapping réflexif direct de la colonne Oracle vers le champ Java.

## 18.9 Cycle réel d’une liste `PageRecherche`

La méthode `PageRecherche.preparerData` effectue le cycle suivant :

[PageRecherche.java](decompiled/apj-core/affichage/PageRecherche.java#L378)

```text
ouvrir ou recevoir une connexion
  -> lire numPag dans la requête
  -> appliquer npp
  -> construire le critère
  -> construire les clauses de recherche
  -> appeler UserEJB.getData ou UserEJB.getDataPage
  -> charger les données des champs du formulaire
  -> stocker le critère en session sous "critere"
  -> fermer la connexion si elle a été ouverte localement
```

Le choix entre données complètes et pagination dépend de `colSomme` et de `npp` :

```text
colSomme == null et npp == 0
  -> UserEJB.getData

sinon
  -> UserEJB.getDataPage
```

La pagination est donc calculée par l’objet de page APJ et non par la JSP elle-même.

Les liens de pagination reprennent explicitement :

```text
but
recap
premier
numPag
npp
filtres
```

Cela confirme que `but` est un protocole de navigation transversal au framework.

## 18.10 Cycle réel d’une page `PageInsert`

Le constructeur de `PageInsert` inspecte directement le paramètre `acte` :

[PageInsert.java](decompiled/apj-core/affichage/PageInsert.java#L25)

```text
acte = update
  -> objet critère
  -> makeCritere
  -> getData
  -> formulaire de modification
  -> identifiant readonly

acte = dupliquer
  -> charger l’objet
  -> vider l’identifiant
  -> formulaire de modification utilisé comme base de duplication

autre acte
  -> formulaire d’insertion
```

Le framework déduit donc le mode de la page à partir du paramètre HTTP `acte`, et non à partir d’un contrôleur typé.

Lors de la construction du formulaire, `PageInsert.makeFormulaire` :

- interroge les colonnes via `ListeColonneTable` ;
- ignore la colonne identifiante en insertion ;
- crée un `ChampCalcul` pour les nombres ;
- crée un `ChampDate` pour `java.sql.Date` ;
- crée un `Champ` pour les autres types ;
- rattache l’utilisateur à chaque champ ;
- rattache le nom de classe au champ.

Lors de la soumission, `getObjectAvecValeur` parcourt les champs Java par réflexion et convertit les chaînes HTTP vers les types Java.

Le flux est donc :

```text
paramètres HTTP
  -> réflexion sur les champs
  -> conversion String vers type Java
  -> remplissage de l’objet APJ
  -> controler
  -> persistance
```

## 18.11 Maître/détail : propagation automatique de l’identifiant

`ClassMere.createObject` appelle d’abord l’insertion du parent, puis crée les enfants.

[ClassMere.java](decompiled/apj-core/bean/ClassMere.java#L80)

Pour chaque `ClassFille` :

```text
lire la valeur du champ de liaison
  -> si elle est vide ou différente de l’identifiant parent
  -> affecter l’identifiant du parent
  -> créer la fille
```

La relation parent/enfant n’est donc pas seulement une relation Java en mémoire. Elle commande effectivement l’ordre de persistance et la propagation de la clé étrangère.

La validation suit le même principe :

```text
valider le parent
  -> valider chaque fille
  -> valider le parent lui-même
```

Cette implémentation explique pourquoi les classes `ClassMere`/`ClassFille` sont une abstraction fondamentale du framework.

## 18.12 Workflow hiérarchique de `ClassEtat`

`ClassEtat` implémente réellement les états et non un simple champ décoratif.

Par défaut :

```text
etat = 1
isHierarchique = false
roleValidation = null
```

`validerObject` :

[ClassEtat.java](decompiled/apj-core/bean/ClassEtat.java#L113)

```text
mode = modif
  -> controlerUpdate
  -> notification éventuelle
  -> passage à l’état validé si aucune hiérarchie ne l’empêche
  -> actionValidation = "Validation"
  -> updateToTableWithHisto
```

La méthode `viser` consulte ensuite `RoleValidation` par le nom complet de la classe :

```text
RoleValidation.mapping = nom complet de la classe
  -> rechercher les règles de validation
  -> comparer le rôle de l’utilisateur
  -> vérifier la valeur d’état attendue
  -> valider ou refuser
```

Si plusieurs rôles sont nécessaires, le framework vérifie l’historique des validations précédentes avant d’autoriser le rôle suivant.

Cela confirme un workflow de validation séquentiel fondé sur :

- la classe Java ;
- le rôle utilisateur ;
- la valeur d’état ;
- l’historique des actions.

## 18.13 Le filtre d’encodage est un middleware réel

L’analyse initiale indiquait qu’aucun middleware n’était visible. La décompilation corrige ce point.

Le JAR déclare `EncodingFilter` sur `/*` :

[EncodingFilter.java](decompiled/apj-core2/web/servlet/EncodingFilter.java#L10)

Son comportement est simple :

```java
request.setCharacterEncoding("UTF-8");
response.setCharacterEncoding("UTF-8");
chain.doFilter(request, response);
```

Il existe donc bien une chaîne de filtres Servlet, mais elle est utilisée pour des préoccupations techniques transversales, principalement l’encodage, et non pour implémenter un pipeline MVC de contrôleurs.

## 18.14 Endpoints natifs ajoutés par APJ

Le fragment web présent dans le JAR déclare notamment :

```text
/Deroulante
/autocomplete
/download
/ImportUtilServlet
/upload_excel
/kanban/update
/kanban/duplique
/kanban/remove
/ai-evaluation
/calendrier-data
/calendrier
/DeletePj
```

Le framework fournit donc nativement des services HTTP pour :

- les listes déroulantes ;
- l’autocomplétion ;
- les exports ;
- les imports ;
- les uploads ;
- les vues Kanban ;
- l’évaluation IA ;
- les calendriers ;
- la suppression de pièces jointes.

Le projet peut ajouter ses propres servlets, mais plusieurs capacités transversales sont déjà livrées par APJ.

## 18.15 Exemple d’endpoint JSON : calendrier

`CalendrierDataServlet` montre un style différent des JSP :

[CalendrierDataServlet.java](decompiled/apj-core2/web/servlet/CalendrierDataServlet.java#L17)

```text
GET /calendrier-data
  -> vérifier periode
  -> récupérer UserEJB dans la session
  -> retourner 401 si la session est absente
  -> calculer les bornes de dates
  -> CGenUtil.rechercher(new Evenement(), ...)
  -> produire un JSON d’événements
```

Pour une modification :

```text
POST /calendrier-data
  -> vérifier la session
  -> retrouver Evenement par identifiant
  -> modifier les champs
  -> appeler UserEJB.updateObject
  -> produire un JSON de succès
```

Ce servlet illustre la coexistence de deux styles dans APJ :

```text
JSP + Page* + HTML généré
Servlet + CGenUtil/UserEJB + JSON
```

## 18.16 Export : session `critere` et objets APJ

`PageRecherche.preparerData` place le critère courant en session :

```java
session.setAttribute("critere", this.getCritere())
```

`ServletDownload` réutilise ensuite ce critère pour produire des exports PDF, CSV, XML ou Excel.

Le flux d’export est donc :

```text
PageRecherche
  -> critère APJ dans session
  -> requête /download
  -> récupération du critère
  -> CGenUtil.rechercher
  -> TableauRecherche
  -> PDF/CSV/XML/XLS
```

Ce mécanisme montre que la session sert aussi de contexte technique inter-page, et pas seulement de stockage utilisateur.

## 18.17 Nouvelles corrections à apporter à l’analyse initiale

Les affirmations suivantes doivent être nuancées :

### Middleware

Il existe bien un middleware Servlet sous la forme de `EncodingFilter`. Il ne s’agit toutefois pas d’un pipeline métier ou MVC.

### Servlets natives

Le noyau ne fournit pas seulement trois servlets. Le fragment du JAR en déclare une dizaine, notamment pour les imports, uploads, exports, calendriers, Kanban et IA.

### Transactions

Les transactions ne sont pas uniquement déléguées à Java EE. APJ ouvre, désactive l’autocommit, commit, rollback et ferme lui-même des connexions dans plusieurs opérations.

### Persistance

Le mapping n’est pas seulement une convention nom/champ. Il dépend aussi de la table Oracle `listeColonneTable`, qui décrit les colonnes et leur ordre.

### Historique

L’historisation n’est pas une capacité supposée de `UserEJB`. Elle est appelée directement par les méthodes de persistance de `ClassMAPTable` et de workflow de `ClassEtat`.

### Injection

L’injection moderne reste absente du chemin principal, mais `ClassMAPTable` possède des références explicites vers `UserEJB` et `UserEJBBean`. Il s’agit d’un lien de service manuel ou injecté par le code environnant, pas d’un usage démontré de CDI.

## 18.18 Modèle mental révisé

Après décompilation, APJ peut être compris comme une machine à métadonnées et à conventions :

```text
table Oracle
  + description listeColonneTable
  + classe Java réflexive
  + objet ClassMAPTable
  + Page/Formulaire/Tableau
  + UserEJB
  + historique et état
  + session HTTP
```

Le framework construit dynamiquement la plupart de ses comportements à partir de cette combinaison.

Le développeur ne déclare pas seulement une entité. Il doit aligner plusieurs contrats :

```text
nom des champs Java
  = noms des colonnes Oracle

nom de table Java
  = entrée de listeColonneTable

getTuppleID
  = attribut identifiant réel

construirePK
  = préfixe + séquence Oracle

acte/classe/nomtable/bute
  = protocole HTTP des JSP APJ

ClassEtat
  = cycle de validation et historique

ClassMere/ClassFille
  = ordre de persistance et liaison des identifiants
```

La philosophie du créateur apparaît ainsi plus clairement : centraliser les opérations génériques dans des classes réflexives, décrire les tables dans Oracle, laisser les objets porter leurs propres règles de cycle de vie, et utiliser les JSP comme façades configurables au-dessus de cette mécanique.
