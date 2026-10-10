# Guide APJ : impressions, exports et états

## Trois familles

```text
Etat écran       -> JSP + PageRecherche/PageConsulte + Tableau
Impression       -> JasperReports -> JasperPrint -> réponse HTTP
Export serveur   -> JasperPrint -> fichier PDF/XLSX -> téléchargement
Export spécifique-> servlet dédiée, par exemple Apache POI pour Excel
```

Un « état » est généralement une page de recherche, une vue SQL ou une classe métier de synthèse. Il n’existe pas un générateur unique pour tous les états.

## Impression PDF/XLSX avec Jasper

Le projet utilise `reporting.ReportingUtils` et `ReportingCdn` via `UtilitaireImpression`.

1. Construire les paramètres (`Map`) et les données (`List` ou `JRBeanCollectionDataSource`).
2. Remplir le rapport `.jrxml`/`.jasper` pour obtenir un `JasperPrint`.
3. Exporter avec `ReportingUtils.ReportType.PDF` ou `XLSX`.
4. Définir `Content-Disposition` et écrire dans `HttpServletResponse`.

Méthodes usuelles :

- `imprimer(...)` : remplit puis exporte directement dans la réponse ;
- `imprimerEnUn(...)` : exporte un `JasperPrint` déjà construit ;
- `imprimerServeur(...)` : génère d’abord sur le serveur/CDN puis télécharge ;
- `fillReport(...)` : utilise une source vide si la liste de données est vide.

```java
UtilitaireImpression.imprimer(
    request, response, "etat-stock", param, data,
    reportPath, ReportingUtils.ReportType.PDF
);
```

Pour Excel Jasper, utiliser `XLSX`; le code accepte aussi le type texte `xls`, qui est converti vers `XLSX` dans `imprimerEnUn`.

## Excel spécifique

Pour un format très personnalisé, une servlet comme `station.export.ExportExcel` construit directement un `Workbook` Apache POI, remplit feuilles, styles et totaux, puis écrit le classeur dans la réponse. Ce chemin doit :

- valider `action` et tous les filtres ;
- fermer le `Workbook`/flux ;
- définir le bon nom et le bon type MIME ;
- éviter de concaténer des filtres non contrôlés dans SQL.

## Etats et filtres

`PageRecherche` construit les critères, appelle la recherche paginée et rend `Tableau`, récapitulatif et pagination. Un état exporté doit réutiliser les mêmes filtres et règles d’accès que l’écran : ne pas exporter une requête plus large que la liste affichée.

Les paramètres typiques sont `daty1`, `daty2`, `annee`, identifiants métier, regroupement et ordre. Les pages d’état transmettent souvent ces paramètres par `but` ou à une servlet dédiée.

## Checklist

1. Identifier source, filtres, droits et volume.
2. Choisir Jasper pour un rapport stable, POI pour une feuille interactive/personnalisée.
3. Produire les données dans le service/objet métier, pas dans le HTML seul.
4. Contrôler les paramètres avant SQL et avant génération.
5. Tester PDF, XLSX, résultat vide, gros volume, accents et téléchargement.
