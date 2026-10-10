# Guide APJ : dispatcher `but` et transactions

## Dispatcher `but`

Le routage applicatif principal est porté par les JSP conteneurs :

```text
/pages/module.jsp?but=vente/vente-fiche.jsp&id=V...
  -> contrôle de session
  -> but = paramètre request
  -> <jsp:include page="<%=but%>"/>
  -> JSP métier
```

`moduleLeger.jsp` applique le même routage sans le menu, l’en-tête et le pied de page complets. Le lien courant est conservé dans `session.lien`; `idmenu` et `langue` modifient aussi la session.

## Conventions de paramètres

- `but` : JSP à afficher ou étape suivante ;
- `id` : identifiant de l’objet ;
- `acte` : opération (`insert`, `update`, `delete`, `valider`, etc.) ;
- `classe` : classe Java à charger ;
- `nomtable` : table APJ ;
- `bute` : page après traitement.

Les formulaires de saisie envoient souvent vers `apresTarif.jsp`; les opérations maître/détail vers `apresMultiple.jsp`. Ces pages appellent ensuite `UserEJB`, puis redirigent vers `bute`.

Les servlets HTTP sont un autre routage : leurs URL sont déclarées par annotation ou `web-fragment.xml` (`/download`, `/Deroulante`, `/ExportDispatcher`, etc.). Un servlet peut faire un `forward` vers un autre servlet avec `RequestDispatcher`.

## Transactions observables

Le code suit deux modèles :

```text
Connexion fournie
  -> l'appelant possède la transaction

Connexion absente
  -> UtilDB.GetConn()
  -> setAutoCommit(false)
  -> plusieurs opérations
  -> commit ou rollback
  -> close
```

`UserEJBBean` utilise ce modèle pour plusieurs opérations, notamment parent/détails. `CreateObject` montre le chemin création explicite : initialisation de `etat`/`iduser`, `controler`, `construirePK`, insertion avec historique, puis commit si la méthode possède la connexion. `ClassMAPTable.deleteToTableWithHisto` contrôle, supprime, écrit l’historique et rollback en cas d’erreur.

## Règle de possession de connexion

- Si une méthode reçoit `Connection c`, elle ne doit normalement pas la fermer.
- Si elle l’ouvre elle-même, elle doit gérer commit/rollback et fermeture.
- Une opération composée doit transmettre la même connexion à toutes les écritures.
- Une exception doit remonter après rollback ; ne jamais continuer une transaction partiellement échouée.

Les annotations EJB (`@Stateful`, `@TransactionAttribute`) sont commentées dans `UserEJBBean`. Il ne faut donc pas supposer qu’un conteneur EJB fournit automatiquement la transaction : le comportement observable est principalement JDBC manuel.

## Points de vigilance

- `but` est une inclusion JSP dynamique : n’y placer que des chemins internes validés par l’application.
- Vérifier authentification et autorisation avant d’exécuter une JSP ou une action, pas seulement avant d’afficher le menu.
- Ne pas mélanger redirection HTTP et écriture après avoir commencé à écrire le fichier d’un export.
- Tester commit, rollback, exception métier, connexion fournie et connexion créée localement.
