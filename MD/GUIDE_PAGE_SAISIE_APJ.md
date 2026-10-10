# Créer une page de saisie APJ avec liste déroulante

Pour créer une nouvelle page de saisie APJ avec une liste déroulante, il faut respecter ce flux :

```text
Table Oracle
  -> classe Java APJ
  -> JSP de saisie
  -> PageInsert
  -> Liste
  -> Formulaire
  -> paramètres acte/classe/nomtable/bute
```

## 1. Créer la table Oracle

Exemple :

```sql
CREATE TABLE EXEMPLE (
    ID VARCHAR2(20) PRIMARY KEY,
    LIBELLE VARCHAR2(100),
    IDMAGASIN VARCHAR2(20)
);
```

La table doit également être connue par la métadonnée APJ `listeColonneTable`, car le framework utilise cette table pour déterminer les colonnes disponibles.

Il faut vérifier que :

- `ID`, `LIBELLE` et `IDMAGASIN` existent dans `listeColonneTable` ;
- les noms correspondent aux champs Java ;
- l’ordre et les types sont corrects.

## 2. Créer la classe Java APJ

```java
package exemple;

import bean.ClassMAPTable;
import java.sql.Connection;

public class Exemple extends ClassMAPTable {
    private String id;
    private String libelle;
    private String idMagasin;

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

    @Override
    public void controler(Connection c) throws Exception {
        super.controler(c);

        if (libelle == null || libelle.trim().isEmpty()) {
            throw new Exception("Le libellé est obligatoire");
        }

        if (idMagasin == null || idMagasin.trim().isEmpty()) {
            throw new Exception("Le magasin est obligatoire");
        }
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getLibelle() { return libelle; }
    public void setLibelle(String libelle) { this.libelle = libelle; }

    public String getIdMagasin() { return idMagasin; }
    public void setIdMagasin(String idMagasin) { this.idMagasin = idMagasin; }
}
```

Les éléments importants sont :

- `setNomTable("EXEMPLE")` ;
- `getTuppleID()` ;
- `getAttributIDName()` ;
- `construirePK(Connection)` ;
- `controler(Connection)` ;
- les noms des champs identiques aux colonnes SQL.

## 3. Créer la JSP de saisie

Créer par exemple :

```text
arbiochem-war/web/pages/exemple/exemple-saisie.jsp
```

```jsp
<%@page import="exemple.Exemple"%>
<%@page import="magasin.Magasin"%>
<%@page import="affichage.PageInsert"%>
<%@page import="affichage.Liste"%>
<%@page import="user.UserEJB"%>

<%
    try {
        UserEJB u = (user.UserEJB) session.getValue("u");

        String mapping = "exemple.Exemple";
        String nomtable = "EXEMPLE";
        String apres = "exemple/exemple-fiche.jsp";
        String titre = "Nouvel exemple";

        Exemple exemple = new Exemple();
        exemple.setNomTable(nomtable);

        PageInsert pi = new PageInsert(exemple, request, u);
%>
```

`PageInsert` analyse les champs de `Exemple` et crée automatiquement un formulaire APJ.

## 4. Ajouter la liste déroulante liée à une table

```java
affichage.Champ[] liste = new affichage.Champ[1];

Magasin o = new Magasin();

liste[0] = new Liste(
    "idMagasin",
    o,
    "VAL",
    "id"
);

pi.getFormu().changerEnChamp(liste);
```

La signification est :

```text
"idMagasin"
    nom du champ dans Exemple

o
    objet APJ utilisé pour rechercher les options

"VAL"
    colonne affichée à l’utilisateur

"id"
    valeur réellement envoyée dans le formulaire
```

Le résultat est conceptuellement :

```html
<select name="idMagasin">
    <option value="MAG001">Magasin principal</option>
    <option value="MAG002">Magasin secondaire</option>
</select>
```

La valeur stockée dans `EXEMPLE.IDMAGASIN` sera `MAG001` ou `MAG002`, tandis que l’utilisateur verra le champ `VAL`.

## 5. Charger les options

La classe `affichage.Liste` utilise `CGenUtil.rechercher(...)` avec l’objet source fourni. Elle ajoute également un tri sur la colonne affichée.

Le chargement est déclenché par :

```java
pi.preparerDataFormu();
```

## 6. Ajouter un filtre

```java
Liste magasinListe = new Liste(
    "idMagasin",
    new Magasin(),
    "VAL",
    "id",
    " AND IDPOINT = 'P001'"
);
```

Le dernier argument est une clause SQL ajoutée à la recherche. Il ne faut pas y concaténer directement une valeur provenant de l’utilisateur.

## 7. Configurer les libellés

```java
pi.getFormu().getChamp("libelle").setLibelle("Libellé");
pi.getFormu().getChamp("idMagasin").setLibelle("Magasin");
pi.getFormu().getChamp("idMagasin").setDefaut("MAG001");
```

## 8. Générer le formulaire

```jsp
<%
        pi.setLien((String) session.getValue("lien"));
        pi.getFormu().getChamp("libelle").setLibelle("Libellé");
        pi.getFormu().getChamp("idMagasin").setLibelle("Magasin");
        pi.preparerDataFormu();
%>

<div class="content-wrapper">
    <h1><%= titre %></h1>

    <form action="<%= pi.getLien() %>?but=apresTarif.jsp"
          method="post"
          name="<%= nomtable %>"
          id="<%= nomtable %>">

        <%
            pi.getFormu().makeHtmlInsertTabIndex();
            out.println(pi.getFormu().getHtmlInsert());
        %>

        <input type="hidden" name="acte" value="insert">
        <input type="hidden" name="bute" value="<%= apres %>">
        <input type="hidden" name="classe" value="<%= mapping %>">
        <input type="hidden" name="nomtable" value="<%= nomtable %>">
    </form>
</div>

<%
    } catch (Exception e) {
        e.printStackTrace();
%>
<script>
    alert('<%= e.getMessage() %>');
    history.back();
</script>
<%
    }
%>
```

Les paramètres cachés sont indispensables :

| Paramètre | Rôle |
|---|---|
| `acte` | opération demandée, ici `insert` |
| `classe` | classe Java à instancier |
| `nomtable` | table cible |
| `bute` | page à afficher après le traitement |

## 9. Liste statique

```java
String[] affichage = { "Actif", "Inactif" };
String[] valeurs = { "1", "0" };

Liste listeEtat = new Liste("etat", affichage, valeurs);

pi.getFormu().changerEnChamp(
    new affichage.Champ[] { listeEtat }
);
```

Le framework fournit aussi `makeListeMois()`, `makeListeAnnee()` et `makeListeOuiNon()`.

## 10. Flux de soumission

```text
POST
  -> apresTarif.jsp
  -> lecture de acte=insert
  -> lecture de classe=exemple.Exemple
  -> création de l’objet
  -> remplissage depuis request
  -> conversion des types
  -> Exemple.controler(connection)
  -> Exemple.construirePK(connection)
  -> insertToTableWithHisto
  -> page bute
```

`PageInsert.getObjectAvecValeur()` convertit notamment les chaînes HTTP vers `String`, `java.sql.Date`, `double`, `int` et `float`.

## 11. Checklist

1. Créer ou vérifier la table Oracle.
2. Vérifier `listeColonneTable`.
3. Créer la classe Java APJ.
4. Définir `setNomTable`.
5. Implémenter l’identifiant.
6. Implémenter `construirePK`.
7. Ajouter `controler`.
8. Créer la JSP sous `web/pages`.
9. Instancier `PageInsert`.
10. Créer l’objet source de la liste.
11. Construire `new Liste(...)`.
12. Appeler `changerEnChamp`.
13. Configurer les libellés.
14. Appeler `preparerDataFormu`.
15. Générer le HTML avec `getHtmlInsert`.
16. Ajouter `acte`, `classe`, `nomtable` et `bute`.
17. Vérifier la page de traitement.
18. Tester insertion, modification, valeur vide et autorisations.

Le modèle de référence est [pompe-saisie.jsp](arbiochem-war/web/pages/pompe/pompe-saisie.jsp).

La règle essentielle est :

```text
Le champ Java stocke l’identifiant.
La Liste affiche un libellé.
La classe source fournit les options.
PageInsert construit le formulaire.
APJ convertit, valide et persiste.
```
