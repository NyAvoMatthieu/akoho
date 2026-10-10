<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page import="affichage.PageRecherche"%>
<%@ page import="ferme.acheminement.ControlePoulet" %>

<% try{
    ControlePoulet o = new ControlePoulet();
    o.setNomTable("CONTROLE_POULET");
    String[] listeCrt = {"id", "typeAntecedent", "idAntecedent", "idPoulet"};
    String[] listeInt = {"daty"};
    String[] libEntete = {"id", "daty", "typeAntecedent", "idAntecedent", "idLigneAntecedent", "idPoulet",
            "idMagasin", "quantiteTheorique", "nbVivant", "nbMort", "nbPerdu"};
    PageRecherche pr = new PageRecherche(o, request, listeCrt, listeInt, 4, libEntete, libEntete.length);
    pr.setTitre("Liste des contr&ocirc;les de poulets");
    pr.setUtilisateur((user.UserEJB) session.getValue("u"));
    pr.setLien((String) session.getValue("lien"));
    pr.setApres("ferme/acheminement/controle-poulet-liste.jsp");
    pr.getFormu().getChamp("id").setLibelle("Id");
    pr.getFormu().getChamp("typeAntecedent").setLibelle("Type d'ant&eacute;c&eacute;dent");
    pr.getFormu().getChamp("idAntecedent").setLibelle("Ant&eacute;c&eacute;dent");
    pr.getFormu().getChamp("idPoulet").setLibelle("Poulet");
    pr.getFormu().getChamp("daty1").setLibelle("Date min");
    pr.getFormu().getChamp("daty2").setLibelle("Date max");

    String[] colSomme = {"quantiteTheorique", "nbVivant", "nbMort", "nbPerdu"};
    pr.creerObjetPage(libEntete, colSomme);
    pr.getTableauRecap().setLibeEntete(new String[]{"", "", "", "", "", "", "", "",
            "Th&eacute;orique", "Vivants", "Morts", "Perdus"});

    String[] lienTableau = {pr.getLien() + "?but=ferme/acheminement/controle-poulet-fiche.jsp"};
    String[] colonneLien = {"id"};
    String[] attributLien = {"id"};
    pr.getTableau().setLien(lienTableau);
    pr.getTableau().setColonneLien(colonneLien);
    pr.getTableau().setAttLien(attributLien);

    pr.getFormu().setAnotherButton("" +
        "<a class=\"btn btn-primary pull-right btn-small\" href=\"module.jsp?but=ferme/acheminement/controle-poulet-saisie.jsp\">\n" +
        "                    <i class=\"material-symbols-rounded\">add</i> Saisir un contr&ocirc;le</a>"
    );

    String[] libEnteteAffiche = {"Id", "Date", "Type d'ant&eacute;c&eacute;dent", "Ant&eacute;c&eacute;dent", "Ligne",
            "Poulet", "Lieu", "Quantit&eacute; th&eacute;orique", "Vivants", "Morts", "Perdus"};
    pr.getTableau().setLibelleAffiche(libEnteteAffiche);
%>

<div class="content-wrapper">
    <section class="content-header">
        <h1><%= pr.getTitre() %></h1>
    </section>
    <section class="content">
        <form action="<%=pr.getLien()%>?but=<%= pr.getApres() %>" method="post">
            <%
                out.println(pr.getFormu().getHtmlEnsemble());
            %>
        </form>
        <%
            out.println(pr.getTableauRecap().getHtml());
        %>
        <br>
        <%
            out.println(pr.getTableau().getHtml());
            out.println(pr.getBasPage());
        %>
    </section>
</div>

<% } catch (Exception e) {
  e.printStackTrace();
%>
<script language="JavaScript"> alert('<%=e.getMessage()%>');
    history.back();
</script>
<% }%>