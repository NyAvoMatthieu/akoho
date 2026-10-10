<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="affichage.PageInsert"%>
<%@ page import="affichage.Liste"%>
<%@ page import="user.UserEJB" %>
<%@ page import="ferme.acheminement.ControlePoulet" %>
<%@ page import="ferme.poulet.Poulet" %>
<%@ page import="ferme.configuration.MagasinElevage" %>

<% try{
    UserEJB u = (UserEJB) session.getValue("u");
    String mapping = "ferme.acheminement.ControlePoulet";
    String nomTable = "CONTROLE_POULET";
    String apres = "ferme/acheminement/controle-poulet-fiche.jsp";

    ControlePoulet o = new ControlePoulet();
    o.setNomTable(nomTable);
    PageInsert pi = new PageInsert(o, request, u);
    pi.setLien((String) session.getValue("lien"));
    pi.setTitre("Saisie contr&ocirc;le de poulet");

    // En insertion, PageInsert.makeFormulaire() exclut volontairement la colonne
    // identifiant du formulaire (PageInsert.java:88), et Formulaire.getChamp()
    // renvoie null pour un champ absent. L'identifiant est produit par
    // ControlePoulet.construirePK() : il n'a pas a etre libelle ici. Il
    // n'existe qu'en mode update, ou makeFormulaireUpt() le garde en lecture seule.
    pi.getFormu().getChamp("daty").setLibelle("Date du contr&ocirc;le");
    pi.getFormu().getChamp("typeAntecedent").setLibelle("Type d'ant&eacute;c&eacute;dent (BC/BL/CONTROLE)");
    pi.getFormu().getChamp("idAntecedent").setLibelle("Ant&eacute;c&eacute;dent");
    pi.getFormu().getChamp("idLigneAntecedent").setLibelle("Ligne de l'ant&eacute;c&eacute;dent");
    pi.getFormu().getChamp("idPoulet").setLibelle("Poulet");
    pi.getFormu().getChamp("idMagasin").setLibelle("Lieu");
    pi.getFormu().getChamp("nbVivant").setLibelle("Nombre de vivants");
    pi.getFormu().getChamp("nbMort").setLibelle("Nombre de morts");
    pi.getFormu().getChamp("quantiteTheorique").setLibelle("Quantit&eacute; th&eacute;orique (calcul&eacute;e)");
    pi.getFormu().getChamp("nbPerdu").setLibelle("Nombre de perdus (calcul&eacute;)");
    pi.getFormu().getChamp("quantiteTheorique").setVisible(false);
    pi.getFormu().getChamp("nbPerdu").setVisible(false);
    pi.getFormu().getChamp("etat").setVisible(false);

    affichage.Liste[] listef = new Liste[2];
    Poulet poulet = new Poulet();
    listef[0] = new Liste("idPoulet", poulet, "nom", "id");
    MagasinElevage lieu = new MagasinElevage();
    listef[1] = new Liste("idMagasin", lieu, "nom", "id");
    pi.getFormu().changerEnChamp(listef);
    pi.getFormu().getChamp("idPoulet").setLibelle("Poulet");
    pi.getFormu().getChamp("idMagasin").setLibelle("Lieu");

    String[] ordre = {"daty", "typeAntecedent", "idAntecedent", "idLigneAntecedent", "idPoulet", "idMagasin", "nbVivant", "nbMort"};
    pi.getFormu().setOrdre(ordre);

    String acte = request.getParameter("acte");
    if (acte != null && acte.equalsIgnoreCase("update")) {
        pi.setTitre("Modification contr&ocirc;le de poulet");
        pi.getFormu().getChamp("id").setLibelle("Identifiant");
    }

    pi.preparerDataFormu();
    pi.getFormu().makeHtmlInsertTabIndex();
%>

<div class="content-wrapper">
    <h1><%=pi.getTitre()%></h1>
    <form action="<%=pi.getLien()%>?but=apresTarif.jsp" method="post" name="<%=nomTable%>" id="<%=nomTable%>">
        <%
            out.println(pi.getFormu().getHtmlInsert());
        %>
        <input name="acte" type="hidden" id="nature" value="insert">
        <input name="bute" type="hidden" id="bute" value="<%=apres%>">
        <input name="classe" type="hidden" id="classe" value="<%=mapping%>">
        <input name="nomtable" type="hidden" id="nomtable" value="<%=nomTable%>">
    </form>
</div>

<% } catch (Exception e) {
  e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=e.getMessage()%>');
    history.back();
</script>
<% }%>