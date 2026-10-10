<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@page import="affichage.PageInsertMultiple"%>
<%@ page import="affichage.Liste"%>
<%@ page import="bean.TypeObjet"%>
<%@ page import="user.UserEJB"%>
<%@ page import="ferme.acheminement.Repartition"%>
<%@ page import="ferme.acheminement.RepartitionFille"%>
<%@ page import="ferme.acheminement.ControlePoulet"%>
<%@ page import="ferme.configuration.Compartiment"%>

<% try{
    UserEJB u = (UserEJB) session.getValue("u");

    Repartition mere = new Repartition();
    RepartitionFille fille = new RepartitionFille();
    int nombreLigne = 10;
    PageInsertMultiple pi = new PageInsertMultiple(mere, fille, request, nombreLigne, u);
    pi.setLien((String) session.getValue("lien"));

    // En insertion, PageInsertMultiple.makeFormulaire() exclut volontairement la
    // colonne identifiant du formulaire mere (PageInsertMultiple.java:129), et
    // Formulaire.getChamp() renvoie null pour un champ absent. L'identifiant
    // est produit par Repartition.construirePK() : il n'a pas a etre libelle ici.
    // Il n'existe qu'en mode update, via makeFormulaireUpt().
    pi.getFormu().getChamp("daty").setLibelle("Date de la r&eacute;partition");
    pi.getFormu().getChamp("idControlePoulailler").setLibelle("Contr&ocirc;le de poulailler");
    pi.getFormu().getChamp("idBL").setLibelle("Bon de livraison");
    pi.getFormu().getChamp("etat").setVisible(false);

    String idControle = request.getParameter("idControlePoulailler");
    if (idControle != null && !idControle.isEmpty()) {
        pi.getFormu().getChamp("idControlePoulailler").setDefaut(idControle);
        pi.getFormu().getChamp("idControlePoulailler").setAutre("readonly");
    }

    affichage.Liste[] listeMere = new Liste[1];
    ControlePoulet controle = new ControlePoulet();
    listeMere[0] = new Liste("idControlePoulailler", controle, "id", "id");
    pi.getFormu().changerEnChamp(listeMere);
    pi.getFormu().getChamp("idControlePoulailler").setLibelle("Contr&ocirc;le de poulailler");

    // Les champs de la fille sont numerotes "<nom>_<ligne>" par
    // PageInsertMultiple.makeFormulaire() (ligne 151). Les libelles se posent
    // sur la ligne 0, qui vaut pour toute la colonne : c'est la convention du
    // depot, cf. ristourne-saisie.jsp:59.
    // Seuls idCompartiment et sexe deviendront des listes deroulantes ; qtt et
    // sante restent des champs de saisie.
    pi.getFormufle().getChamp("idCompartiment_0").setLibelle("Compartiment");
    pi.getFormufle().getChamp("qtt_0").setLibelle("Quantit&eacute;");
    pi.getFormufle().getChamp("sexe_0").setLibelle("Sexe");
    pi.getFormufle().getChamp("sante_0").setLibelle("Sant&eacute;");
    // La fille conserve toutes ses colonnes, identifiant compris
    // (PageInsertMultiple.java:151), et elles doivent rester invisibles.
    // getChampMulitple regroupe les "<nom>_<ligne>" d'un meme champ, sans
    // tableau intermediaire ni case vide.
    // getChampFille n'est pas employe ici : hors mode update, le champ "id" de
    // la fille n'est pas present, et setVisible(Champ[], boolean) dereference
    // chaque case du tableau sans test (Champ.java:1598).
    pi.getFormufle().getChampMulitple("id").setVisible(false);
    pi.getFormufle().getChampMulitple("idRepartitionMere").setVisible(false);

    affichage.Liste[] listef = new Liste[2];
    Compartiment compartiment = new Compartiment();
    listef[0] = new Liste("idCompartiment", compartiment, "nom", "id");
    TypeObjet sexe = new TypeObjet();
    sexe.setNomTable("SEXE");
    listef[1] = new Liste("sexe", sexe, "val", "id");
    pi.getFormufle().changerEnChamp(listef);

    // setColOrdre attend les noms sans suffixe de ligne (ristourne-saisie.jsp:101).
    String[] colOrdre = {"idCompartiment", "sexe", "sante", "qtt"};
    pi.getFormufle().setColOrdre(colOrdre);

    String classeMere = "ferme.acheminement.Repartition";
    String classeFille = "ferme.acheminement.RepartitionFille";
    String butApresPost = "ferme/acheminement/repartition-fiche.jsp";
    String colonneMere = "idRepartitionMere";

    // PageInsertMultiple ne construit un formulaire contenant l'identifiant que
    // pour les actes "update" et "dupliquer" (PageInsertMultiple.java:24 et 43).
    // Le test doit donc reprendre exactement ces deux actes : un acte non vide
    // mais inconnu, tel que "insert", ne garantit pas la presence du champ, et
    // getChamp("id") renverrait null.
    String acte = request.getParameter("acte");
    boolean modification = "update".equalsIgnoreCase(acte)
            || "dupliquer".equalsIgnoreCase(acte);
    if (modification) {
        pi.setTitre("Modification d'une r&eacute;partition");
        pi.getFormu().getChamp("id").setLibelle("Identifiant");
    } else {
        pi.setTitre("Saisie d'une r&eacute;partition");
    }

    pi.preparerDataFormu();
    pi.getFormu().makeHtmlInsertTabIndex();
    pi.getFormufle().makeHtmlInsertTableauIndex();
%>

<div class="content-wrapper">
    <h1><%=pi.getTitre()%></h1>
    <form id="formId" class='container' action="<%=pi.getLien()%>?but=apresMultiple.jsp" method="post">
        <%
            out.println(pi.getFormu().getHtmlInsert());
        %>
        <div id="butfillejsp">
            <%
                out.println(pi.getFormufle().getHtmlTableauInsert());
            %>
        </div>
        <input name="acte" type="hidden" id="nature" value="insert">
        <input name="bute" type="hidden" id="bute" value="<%= butApresPost %>">
        <input name="classe" type="hidden" id="classe" value="<%= classeMere %>">
        <input name="classefille" type="hidden" id="classefille" value="<%= classeFille %>">
        <input name="nombreLigne" type="hidden" id="nombreLigne" value="<%= nombreLigne %>">
        <input name="colonneMere" type="hidden" id="colonneMere" value="<%= colonneMere %>">
    </form>
</div>

<% } catch (Exception e) {
  e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=e.getMessage()%>');
    history.back();
</script>
<% }%>